import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';

class SupabaseService {
  // Initialize Supabase client
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Track active sessions to prevent multiple concurrent operations
  static bool _isSigningIn = false;
  static bool _isSigningUp = false;
  static bool _isSigningOut = false;

  // Session timeout configuration
  static const Duration _sessionTimeout = Duration(seconds: 45);

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

      // Note: Supabase Auth will automatically handle duplicate emails
      // No need to manually check - let Auth service handle it properly

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
          'email': email, // Include email in metadata for trigger function
        },
      );

      if (response.user != null) {
        // The user profile is automatically created by the trigger function
        // No need to manually insert into users table anymore!

        if (kDebugMode) {
          print('User account created successfully: ${response.user!.id}');
          print('User profile will be created automatically by trigger');
        }

        // Clear any cached profile data
        _cachedUserProfile = null;

        return {
          'success': true,
          'user': response.user,
          'message': 'Account created successfully!',
          'requiresEmailVerification': false,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to create user account - no user returned',
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Sign-up error: $e');
      }

      // Handle specific error cases
      String errorMessage = e.toString().toLowerCase();

      if (errorMessage.contains('user already registered')) {
        return {
          'success': false,
          'message':
              'An account with this email already exists. Please sign in instead.',
        };
      } else if (errorMessage.contains('signup is disabled')) {
        return {
          'success': false,
          'message':
              'Account creation is currently disabled. Please contact support.',
        };
      } else if (errorMessage.contains('invalid email')) {
        return {
          'success': false,
          'message': 'Please enter a valid email address.',
        };
      } else if (errorMessage.contains('password')) {
        return {
          'success': false,
          'message':
              'Password does not meet requirements. Please try a stronger password.',
        };
      }

      return {
        'success': false,
        'message':
            'Failed to create account. Please try again or contact support.',
      };
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
      if (kDebugMode) {
        print('Attempting Supabase sign-in for email: $email');
      }

      // Direct sign-in with Supabase Auth - no need to check users table first
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (kDebugMode) {
        print(
          'Auth response received: ${response.user?.id != null ? 'User found' : 'No user'}',
        );
        print(
          'Session: ${response.session?.accessToken != null ? 'Valid session' : 'No session'}',
        );
      }

      if (response.user != null) {
        // Skip email verification check if disabled in Supabase settings
        // Email verification is likely disabled based on your setup

        // Update last active date in user_stats (if table exists)
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
      if (kDebugMode) {
        print('Detailed sign-in error: $e');
        print('Error type: ${e.runtimeType}');
      }
      throw e; // Re-throw to be handled by the parent method
    }
  }

  /// Map Supabase errors to user-friendly messages
  static String _mapErrorMessage(String error, String operation) {
    final errorLower = error.toLowerCase();

    // Log the actual error for debugging
    if (kDebugMode) {
      print('Raw error: $error');
    }

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
        errorLower.contains('email') && errorLower.contains('invalid') ||
        errorLower.contains('email_address_invalid')) {
      return 'Please enter a valid email address. Some email providers may not be supported.';
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

    // Email sending errors (check before server errors)
    if (errorLower.contains('error sending confirmation email') ||
        errorLower.contains('confirmation email') ||
        errorLower.contains('email delivery failed') ||
        errorLower.contains('smtp') && errorLower.contains('error')) {
      return 'Account created, but email verification failed. Please contact support or try signing in directly.';
    }

    // Server errors
    if (errorLower.contains('server error') ||
        errorLower.contains('internal server error') ||
        errorLower.contains('502') ||
        errorLower.contains('503') ||
        errorLower.contains('500') ||
        errorLower.contains('bad gateway') ||
        errorLower.contains('service unavailable') ||
        errorLower.contains('gateway timeout')) {
      return 'Server temporarily unavailable. Please try again in a few moments.';
    }

    // JWT/Auth token errors
    if (errorLower.contains('jwt') ||
        errorLower.contains('token') ||
        (errorLower.contains('session') && errorLower.contains('expired'))) {
      return 'Your session has expired. Please sign in again.';
    }

    // API errors
    if (errorLower.contains('api') && errorLower.contains('key')) {
      return 'Configuration error. Please contact support.';
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

      // Fetch fresh profile data from our users table
      final response = await _supabase
          .from('users')
          .select('*')
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
    String? address,
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
      if (address != null) updates['address'] = address.trim();

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
      // Test basic connectivity first with a simple health check
      final response = await _supabase
          .from('users')
          .select('count')
          .limit(1)
          .timeout(const Duration(seconds: 15));

      if (kDebugMode) {
        print('Connection check successful: $response');
      }
      return true;
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        print('Connection check timed out: $e');
        print('This may indicate network issues or slow server response');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Connection check failed with error: $e');
        print('Error type: ${e.runtimeType}');
      }

      // Check for specific error types
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socket') ||
          errorString.contains('network') ||
          errorString.contains('timeout') ||
          errorString.contains('connection')) {
        if (kDebugMode) {
          print('Network connectivity issue detected');
        }
      } else if (errorString.contains('infinite recursion') ||
          errorString.contains('recursion detected')) {
        if (kDebugMode) {
          print('Database RLS policy recursion issue detected');
          print('Please fix the RLS policies in your Supabase dashboard');
        }
      } else if (errorString.contains('404') ||
          errorString.contains('not found')) {
        if (kDebugMode) {
          print('Supabase project may be inactive or URL incorrect');
        }
      } else if (errorString.contains('unauthorized') ||
          errorString.contains('401')) {
        if (kDebugMode) {
          print(
            'Authentication issue - this might be normal for connection check',
          );
        }
        // 401 on connection check might actually mean server is up but we need auth
        return true;
      }

      return false;
    }
  }

  /// Clear cached data
  static void clearCache() {
    _cachedUserProfile = null;
  }

  /// Test Supabase configuration and connectivity
  static Future<Map<String, dynamic>> testConfiguration() async {
    final results = <String, dynamic>{
      'supabaseUrl': SupabaseConfig.supabaseUrl,
      'hasValidAnonKey': SupabaseConfig.supabaseAnonKey.isNotEmpty,
      'clientInitialized':
          true, // Client is always initialized when this is called
    };

    try {
      // Test basic API connectivity
      final stopwatch = Stopwatch()..start();

      // Try a simple health check
      await _supabase
          .from('users')
          .select('count')
          .limit(1)
          .timeout(const Duration(seconds: 10));

      stopwatch.stop();

      results['connectionTest'] = 'success';
      results['responseTime'] = '${stopwatch.elapsedMilliseconds}ms';
    } catch (e) {
      results['connectionTest'] = 'failed';
      results['connectionError'] = e.toString();

      // Analyze the error
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('404')) {
        results['diagnosis'] =
            'Supabase project may be paused or URL incorrect';
      } else if (errorString.contains('401') ||
          errorString.contains('unauthorized')) {
        results['diagnosis'] =
            'API key may be invalid or project settings issue';
      } else if (errorString.contains('timeout') ||
          errorString.contains('socket')) {
        results['diagnosis'] = 'Network connectivity issue';
      } else {
        results['diagnosis'] = 'Unknown error - check Supabase project status';
      }
    }

    return results;
  }

  /// Get authentication state
  static Map<String, dynamic> getAuthState() {
    final user = _supabase.auth.currentUser;
    return {
      'isSignedIn': user != null,
      'user': user,
      'email': user?.email,
      'userId': user?.id,
    };
  }

  /// Get current authenticated user
  static User? get currentUser => _supabase.auth.currentUser;

  /// Public accessor for the underlying Supabase client.
  ///
  /// Some callers need to perform direct DB operations or subscribe to
  /// realtime channels. The internal client is private (`_supabase`) so
  /// expose a read-only getter here instead of referencing the private
  /// field from other files.
  static SupabaseClient get client => _supabase;

  /// Listen to authentication state changes
  static Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;

  /// Check if user is signed in
  static bool get isSignedIn => _supabase.auth.currentUser != null;

  /// Check if a user with the given email exists in the users table
  /// Returns true if found, false otherwise. Non-fatal on errors.
  static Future<bool> userExists(String email) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id')
          .eq('email', email.trim().toLowerCase())
          .maybeSingle()
          .timeout(const Duration(seconds: 10));

      return response != null;
    } catch (e) {
      if (kDebugMode) {
        print('userExists check failed: $e');
      }
      // If there's an issue checking, return false so caller can decide
      return false;
    }
  }

  /// Attempt a manual password reset for a user identified by email.
  ///
  /// IMPORTANT: Changing a user's password server-side requires an admin
  /// privileged call (service_role key or a server-side RPC/function). This
  /// method attempts to call an RPC named 'admin_reset_user_password' which
  /// should be implemented on your Supabase/Postgres side and must perform the
  /// password update using the Admin API. If that RPC does not exist or the
  /// project is not configured to allow this, this method will return a
  /// helpful failure message. Do NOT embed service_role keys in the client.
  static Future<Map<String, dynamic>> manualResetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      // Validate inputs
      final emailError = validateEmail(email.trim().toLowerCase());
      if (emailError != null) {
        return {'success': false, 'message': emailError};
      }

      final passwordError = validatePassword(newPassword);
      if (passwordError != null) {
        return {'success': false, 'message': passwordError};
      }

      // Call the deployed serverless edge function which performs the admin reset.
      // The function should be deployed securely (service_role key kept server-side).
      final uri = Uri.parse(
        '${SupabaseConfig.supabaseUrl}/functions/v1/rapid-service',
      );
      final resp = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${SupabaseConfig.supabaseAnonKey}',
            },
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'newPassword': newPassword,
            }),
          )
          .timeout(_sessionTimeout);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        // Try parse JSON
        try {
          final body = jsonDecode(resp.body);
          final success = body['success'] == true;
          final message = body['message'] ?? 'Password updated';
          return {'success': success, 'message': message};
        } catch (_) {
          return {
            'success': true,
            'message': 'Password updated (no JSON body)',
          };
        }
      } else {
        String message = 'Server returned ${resp.statusCode}';
        try {
          final body = jsonDecode(resp.body);
          if (body is Map && body['message'] != null) message = body['message'];
        } catch (_) {}
        return {'success': false, 'message': message};
      }
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('manualResetPassword PostgrestException: $e');
      }
      return {
        'success': false,
        'message': e.message, // PostgrestException.message is non-null
      };
    } catch (e) {
      if (kDebugMode) {
        print('manualResetPassword error: $e');
      }

      // If RPC not available or other error, return a clear message
      return {
        'success': false,
        'message':
            'Manual password reset is not configured on the server. Please implement a server-side RPC named "admin_reset_user_password" or configure email sending.',
      };
    }
  }
}
