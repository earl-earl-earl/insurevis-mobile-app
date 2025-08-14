import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class SupabaseService {
  // Initialize Supabase client
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Track active sessions to prevent multiple concurrent operations
  static bool _isSigningIn = false;
  static bool _isSigningUp = false;
  static bool _isSigningOut = false;

  // Session timeout configuration
  static const Duration _sessionTimeout = Duration(seconds: 30);

  // User cache for quick access
  static Map<String, dynamic>? _cachedUserProfile;

  /// Validation helper methods
  static String? validateEmail(String email) {
    if (email.isEmpty) return 'Email is required';

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  static String? validatePassword(String password) {
    if (password.isEmpty) return 'Password is required';
    if (password.length < 8)
      return 'Password must be at least 8 characters long';

    // Check for at least one uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for at least one lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must contain at least one lowercase letter';
    }

    // Check for at least one digit
    if (!RegExp(r'\d').hasMatch(password)) {
      return 'Password must contain at least one number';
    }

    // Check for at least one special character
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return 'Password must contain at least one special character';
    }

    return null;
  }

  static String? validateName(String name) {
    if (name.trim().isEmpty) return 'Name is required';
    if (name.trim().length < 2)
      return 'Name must be at least 2 characters long';

    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(name.trim())) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  static String? validatePhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) return null; // Phone is optional

    // Remove formatting characters
    String cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');

    // Check for valid phone number (10-15 digits, optionally starting with country code)
    if (!RegExp(r'^\d{10,15}$').hasMatch(cleanPhone)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  /// Sign up a new user with email and password
  /// Fields match the users table schema in supabase_setup.md
  static Future<Map<String, dynamic>> signUp({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    // Prevent multiple concurrent sign-up operations
    if (_isSigningUp) {
      return {
        'success': false,
        'message': 'Sign-up already in progress. Please wait.',
      };
    }

    _isSigningUp = true;

    try {
      // Validate inputs
      final nameError = validateName(name);
      if (nameError != null) {
        return {'success': false, 'message': nameError};
      }

      final emailError = validateEmail(email.trim().toLowerCase());
      if (emailError != null) {
        return {'success': false, 'message': emailError};
      }

      final passwordError = validatePassword(password);
      if (passwordError != null) {
        return {'success': false, 'message': passwordError};
      }

      final phoneError = validatePhone(phone);
      if (phoneError != null) {
        return {'success': false, 'message': phoneError};
      }

      // Check if user already exists
      try {
        final existingUser =
            await _supabase
                .from('users')
                .select('email')
                .eq('email', email.trim().toLowerCase())
                .maybeSingle();

        if (existingUser != null) {
          return {
            'success': false,
            'message':
                'An account with this email already exists. Please sign in instead.',
          };
        }
      } catch (e) {
        // Continue if check fails - let Supabase handle duplicate email error
        if (kDebugMode) {
          print('Existing user check failed: $e');
        }
      }

      // Set timeout for the operation
      final signUpFuture = _performSignUp(
        name: name.trim(),
        email: email.trim().toLowerCase(),
        password: password,
        phone: phone?.trim(),
      );

      final result = await signUpFuture.timeout(
        _sessionTimeout,
        onTimeout:
            () => {
              'success': false,
              'message':
                  'Sign-up timed out. Please check your connection and try again.',
            },
      );

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Supabase signup error: $e');
      }

      return {
        'success': false,
        'message': _mapErrorMessage(e.toString(), 'signup'),
      };
    } finally {
      _isSigningUp = false;
    }
  }

  /// Internal method to perform the actual sign-up
  static Future<Map<String, dynamic>> _performSignUp({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      // Implement actual Supabase signup
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone,
          'email': email, // Include email in metadata for easier access
        },
      );

      if (response.user != null) {
        // Create a complete transaction - if any step fails, we should handle cleanup
        try {
          // Insert additional user data into users table
          await _supabase.from('users').insert({
            'id': response.user!.id,
            'name': name,
            'email': email,
            'phone': phone,
            'join_date': DateTime.now().toIso8601String(),
            'is_email_verified': response.user!.emailConfirmedAt != null,
            'preferences': {
              'notifications': true,
              'darkMode': false,
              'language': 'en',
              'autoSync': true,
              'biometricLogin': false,
            },
          });

          // Create initial user stats
          await _supabase.from('user_stats').insert({
            'user_id': response.user!.id,
            'total_assessments': 0,
            'completed_assessments': 0,
            'documents_submitted': 0,
            'total_saved': 0.0,
            'last_active_date': DateTime.now().toIso8601String(),
          });

          // Clear any cached profile data
          _cachedUserProfile = null;

          return {
            'success': true,
            'user': response.user,
            'message':
                response.user!.emailConfirmedAt != null
                    ? 'Account created successfully!'
                    : 'Account created successfully. Please check your email for verification.',
            'requiresEmailVerification':
                response.user!.emailConfirmedAt == null,
          };
        } catch (dbError) {
          // If database operations fail, we should sign out the user
          try {
            await _supabase.auth.signOut();
          } catch (signOutError) {
            if (kDebugMode) {
              print('Failed to sign out after database error: $signOutError');
            }
          }

          throw Exception(
            'Failed to create user profile: ${dbError.toString()}',
          );
        }
      } else {
        throw Exception('Failed to create user account - no user returned');
      }
    } catch (e) {
      throw e; // Re-throw to be handled by the parent method
    }
  }

  /// Sign in an existing user
  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    // Prevent multiple concurrent sign-in operations
    if (_isSigningIn) {
      return {
        'success': false,
        'message': 'Sign-in already in progress. Please wait.',
      };
    }

    _isSigningIn = true;

    try {
      // Validate inputs
      final emailError = validateEmail(email.trim().toLowerCase());
      if (emailError != null) {
        return {'success': false, 'message': emailError};
      }

      if (password.isEmpty) {
        return {'success': false, 'message': 'Password is required'};
      }

      // Set timeout for the operation
      final signInFuture = _performSignIn(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final result = await signInFuture.timeout(
        _sessionTimeout,
        onTimeout:
            () => {
              'success': false,
              'message':
                  'Sign-in timed out. Please check your connection and try again.',
            },
      );

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Supabase signin error: $e');
      }

      return {
        'success': false,
        'message': _mapErrorMessage(e.toString(), 'signin'),
      };
    } finally {
      _isSigningIn = false;
    }
  }

  /// Internal method to perform the actual sign-in
  static Future<Map<String, dynamic>> _performSignIn({
    required String email,
    required String password,
  }) async {
    try {
      // Check if user exists first (optional check for better UX)
      try {
        final userExists =
            await _supabase
                .from('users')
                .select('email, is_email_verified')
                .eq('email', email)
                .maybeSingle();

        if (userExists == null) {
          return {
            'success': false,
            'message':
                'No account found with this email address. Please sign up first.',
          };
        }
      } catch (e) {
        // Continue if check fails - let Supabase auth handle it
        if (kDebugMode) {
          print('User existence check failed: $e');
        }
      }

      // Implement actual Supabase signin
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Check if email is verified
        if (response.user!.emailConfirmedAt == null) {
          // Sign out the unverified user
          await _supabase.auth.signOut();
          return {
            'success': false,
            'message':
                'Please verify your email address before signing in. Check your inbox for a verification link.',
            'requiresEmailVerification': true,
          };
        }

        // Update last active date
        try {
          await _supabase
              .from('user_stats')
              .update({'last_active_date': DateTime.now().toIso8601String()})
              .eq('user_id', response.user!.id);
        } catch (e) {
          // Don't fail sign-in if stats update fails
          if (kDebugMode) {
            print('Failed to update last active date: $e');
          }
        }

        // Clear cached profile to force refresh
        _cachedUserProfile = null;

        return {
          'success': true,
          'user': response.user,
          'message': 'Signed in successfully',
        };
      } else {
        throw Exception('Sign-in failed - no user returned');
      }
    } catch (e) {
      throw e; // Re-throw to be handled by the parent method
    }
  }

  /// Map Supabase errors to user-friendly messages
  static String _mapErrorMessage(String error, String operation) {
    final errorLower = error.toLowerCase();

    // Common authentication errors
    if (errorLower.contains('invalid_credentials') ||
        errorLower.contains('invalid login') ||
        errorLower.contains('wrong password') ||
        errorLower.contains('incorrect password')) {
      return operation == 'signin'
          ? 'Invalid email or password. Please check your credentials and try again.'
          : 'Invalid credentials';
    }

    // Email-related errors
    if (errorLower.contains('email already registered') ||
        errorLower.contains('email_already_exists') ||
        errorLower.contains('duplicate') && errorLower.contains('email')) {
      return 'An account with this email already exists. Please sign in instead or use a different email.';
    }

    if (errorLower.contains('email not confirmed') ||
        errorLower.contains('email_not_confirmed')) {
      return 'Please verify your email address before signing in. Check your inbox for a verification link.';
    }

    if (errorLower.contains('invalid email') ||
        errorLower.contains('email') && errorLower.contains('invalid')) {
      return 'Please enter a valid email address.';
    }

    // Password-related errors
    if (errorLower.contains('password') && errorLower.contains('weak')) {
      return 'Password is too weak. Please choose a stronger password with at least 8 characters, including uppercase, lowercase, numbers, and special characters.';
    }

    if (errorLower.contains('password') && errorLower.contains('short')) {
      return 'Password must be at least 8 characters long.';
    }

    // Rate limiting errors
    if (errorLower.contains('rate limit') ||
        errorLower.contains('too many requests') ||
        errorLower.contains('rate_limit_exceeded')) {
      return 'Too many attempts. Please wait a few minutes before trying again.';
    }

    // Network errors
    if (errorLower.contains('network') ||
        errorLower.contains('connection') ||
        errorLower.contains('timeout') ||
        errorLower.contains('socket')) {
      return 'Network error. Please check your internet connection and try again.';
    }

    // Server errors
    if (errorLower.contains('server error') ||
        errorLower.contains('internal server error') ||
        errorLower.contains('502') ||
        errorLower.contains('503') ||
        errorLower.contains('500')) {
      return 'Server temporarily unavailable. Please try again in a few moments.';
    }

    // Database errors
    if (errorLower.contains('database') || errorLower.contains('db')) {
      return 'Database error occurred. Please try again later.';
    }

    // Timeout errors
    if (errorLower.contains('timeout')) {
      return 'Operation timed out. Please check your connection and try again.';
    }

    // Default messages based on operation
    switch (operation) {
      case 'signup':
        return 'Failed to create account. Please try again or contact support if the problem persists.';
      case 'signin':
        return 'Failed to sign in. Please check your credentials and try again.';
      case 'signout':
        return 'Failed to sign out. Please try again.';
      case 'reset':
        return 'Failed to send password reset email. Please try again.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Sign out the current user
  static Future<Map<String, dynamic>> signOut() async {
    // Prevent multiple concurrent sign-out operations
    if (_isSigningOut) {
      return {
        'success': false,
        'message': 'Sign-out already in progress. Please wait.',
      };
    }

    _isSigningOut = true;

    try {
      // Clear cached data first
      _cachedUserProfile = null;

      // Set timeout for the operation
      await _supabase.auth.signOut().timeout(
        _sessionTimeout,
        onTimeout: () => throw TimeoutException('Sign-out timed out'),
      );

      if (kDebugMode) {
        print('User signed out successfully');
      }

      return {'success': true, 'message': 'Signed out successfully'};
    } catch (e) {
      if (kDebugMode) {
        print('Supabase signout error: $e');
      }

      return {
        'success': false,
        'message': _mapErrorMessage(e.toString(), 'signout'),
      };
    } finally {
      _isSigningOut = false;
    }
  }

  /// Get current user profile with caching
  static Future<Map<String, dynamic>?> getCurrentUserProfile({
    bool forceRefresh = false,
  }) async {
    try {
      final User? user = _supabase.auth.currentUser;

      if (user == null) {
        _cachedUserProfile = null;
        return null;
      }

      // Return cached profile if available and not forcing refresh
      if (!forceRefresh && _cachedUserProfile != null) {
        return _cachedUserProfile;
      }

      // Fetch fresh profile data
      final response = await _supabase
          .from('users')
          .select('*, user_stats(*)')
          .eq('id', user.id)
          .single()
          .timeout(_sessionTimeout);

      // Cache the profile
      _cachedUserProfile = response;

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user profile: $e');
      }

      // Clear cache if there was an error
      _cachedUserProfile = null;
      return null;
    }
  }

  /// Update user profile
  static Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    String? name,
    String? phone,
    String? profileImageUrl,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      // Validate inputs
      if (name != null) {
        final nameError = validateName(name);
        if (nameError != null) {
          return {'success': false, 'message': nameError};
        }
      }

      if (phone != null) {
        final phoneError = validatePhone(phone);
        if (phoneError != null) {
          return {'success': false, 'message': phoneError};
        }
      }

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updates['name'] = name.trim();
      if (phone != null)
        updates['phone'] = phone.trim().isNotEmpty ? phone.trim() : null;
      if (profileImageUrl != null)
        updates['profile_image_url'] = profileImageUrl;
      if (preferences != null) updates['preferences'] = preferences;

      await _supabase
          .from('users')
          .update(updates)
          .eq('id', userId)
          .timeout(_sessionTimeout);

      // Clear cached profile to force refresh
      _cachedUserProfile = null;

      return {'success': true, 'message': 'Profile updated successfully'};
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user profile: $e');
      }

      return {
        'success': false,
        'message': _mapErrorMessage(e.toString(), 'update'),
      };
    }
  }

  /// Reset password
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
  }) async {
    try {
      // Validate email
      final emailError = validateEmail(email.trim().toLowerCase());
      if (emailError != null) {
        return {'success': false, 'message': emailError};
      }

      // Check if user exists (optional for better UX)
      try {
        final userExists =
            await _supabase
                .from('users')
                .select('email')
                .eq('email', email.trim().toLowerCase())
                .maybeSingle();

        if (userExists == null) {
          return {
            'success': false,
            'message': 'No account found with this email address.',
          };
        }
      } catch (e) {
        // Continue if check fails - let Supabase handle it
        if (kDebugMode) {
          print('User existence check for reset failed: $e');
        }
      }

      await _supabase.auth
          .resetPasswordForEmail(email.trim().toLowerCase())
          .timeout(_sessionTimeout);

      if (kDebugMode) {
        print('Password reset email sent to: ${email.trim().toLowerCase()}');
      }

      return {
        'success': true,
        'message':
            'Password reset email sent. Please check your inbox and follow the instructions.',
      };
    } catch (e) {
      if (kDebugMode) {
        print('Password reset error: $e');
      }

      return {
        'success': false,
        'message': _mapErrorMessage(e.toString(), 'reset'),
      };
    }
  }

  /// Resend email verification
  static Future<Map<String, dynamic>> resendEmailVerification() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'No user signed in'};
      }

      if (user.emailConfirmedAt != null) {
        return {'success': false, 'message': 'Email is already verified'};
      }

      await _supabase.auth
          .resend(type: OtpType.signup, email: user.email)
          .timeout(_sessionTimeout);

      return {
        'success': true,
        'message': 'Verification email sent. Please check your inbox.',
      };
    } catch (e) {
      if (kDebugMode) {
        print('Resend verification error: $e');
      }

      return {
        'success': false,
        'message': _mapErrorMessage(e.toString(), 'resend'),
      };
    }
  }

  /// Check connection status
  static Future<bool> checkConnection() async {
    try {
      // Simple query to test connection
      await _supabase
          .from('users')
          .select('count')
          .limit(1)
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Connection check failed: $e');
      }
      return false;
    }
  }

  /// Clear cached data
  static void clearCache() {
    _cachedUserProfile = null;
  }

  /// Get authentication state
  static Map<String, dynamic> getAuthState() {
    final user = _supabase.auth.currentUser;
    return {
      'isSignedIn': user != null,
      'user': user,
      'isEmailVerified': user?.emailConfirmedAt != null,
      'email': user?.email,
      'userId': user?.id,
    };
  }

  /// Get current authenticated user
  static User? get currentUser => _supabase.auth.currentUser;

  /// Listen to authentication state changes
  static Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;

  /// Check if user is signed in
  static bool get isSignedIn => _supabase.auth.currentUser != null;

  /// Check if user email is verified
  static bool get isEmailVerified =>
      _supabase.auth.currentUser?.emailConfirmedAt != null;
}
