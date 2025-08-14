import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../services/supabase_service.dart';
import 'user_provider.dart';

/// Enhanced authentication provider with comprehensive error handling,
/// validation, and multiple instance protection
class AuthProvider with ChangeNotifier {
  // User state
  UserProfile? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Authentication state tracking
  bool _isSigningIn = false;
  bool _isSigningUp = false;
  bool _isSigningOut = false;

  // Session management
  DateTime? _lastActivity;
  static const Duration _sessionTimeout = Duration(minutes: 30);

  // Getters
  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null && SupabaseService.isSignedIn;
  bool get isEmailVerified => SupabaseService.isEmailVerified;
  bool get isInitialized => _isInitialized;
  bool get isSigningIn => _isSigningIn;
  bool get isSigningUp => _isSigningUp;
  bool get isSigningOut => _isSigningOut;

  // Session management getters
  bool get isSessionActive =>
      _lastActivity != null &&
      DateTime.now().difference(_lastActivity!) < _sessionTimeout;
  Duration? get timeUntilSessionExpiry =>
      _lastActivity != null
          ? _sessionTimeout - DateTime.now().difference(_lastActivity!)
          : null;

  /// Initialize the auth provider
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check if there's an existing session
      final authState = SupabaseService.getAuthState();

      if (authState['isSignedIn'] == true) {
        // Load user profile
        await _loadUserProfile(forceRefresh: true);
        _updateLastActivity();
      }

      // Listen to auth state changes
      SupabaseService.authStateChanges.listen(_handleAuthStateChange);

      _isInitialized = true;
    } catch (e) {
      _error = 'Failed to initialize authentication: $e';
      if (kDebugMode) {
        print('Auth initialization error: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Handle authentication state changes
  void _handleAuthStateChange(AuthState state) async {
    if (kDebugMode) {
      print('Auth state changed: ${state.event}');
    }

    switch (state.event) {
      case AuthChangeEvent.signedIn:
        if (state.session?.user != null) {
          await _loadUserProfile();
          _updateLastActivity();
        }
        break;
      case AuthChangeEvent.signedOut:
        _clearUserData();
        break;
      case AuthChangeEvent.userUpdated:
        if (state.session?.user != null) {
          await _loadUserProfile(forceRefresh: true);
        }
        break;
      default:
        break;
    }
  }

  /// Sign up a new user
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    // Prevent multiple concurrent sign-up operations
    if (_isSigningUp) {
      _error = 'Sign-up already in progress. Please wait.';
      notifyListeners();
      return false;
    }

    _isSigningUp = true;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await SupabaseService.signUp(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );

      if (result['success'] == true) {
        // Load user profile if sign-up was successful
        if (result['user'] != null) {
          await _loadUserProfile();
          _updateLastActivity();
        }

        if (kDebugMode) {
          print('Sign-up successful: ${result['message']}');
        }

        return true;
      } else {
        _error = result['message'] ?? 'Sign-up failed';
        return false;
      }
    } catch (e) {
      _error = 'An unexpected error occurred during sign-up: $e';
      if (kDebugMode) {
        print('Sign-up error in provider: $e');
      }
      return false;
    } finally {
      _isSigningUp = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in an existing user
  Future<bool> signIn({required String email, required String password}) async {
    // Prevent multiple concurrent sign-in operations
    if (_isSigningIn) {
      _error = 'Sign-in already in progress. Please wait.';
      notifyListeners();
      return false;
    }

    _isSigningIn = true;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await SupabaseService.signIn(
        email: email,
        password: password,
      );

      if (result['success'] == true) {
        // Load user profile if sign-in was successful
        if (result['user'] != null) {
          await _loadUserProfile();
          _updateLastActivity();
        }

        if (kDebugMode) {
          print('Sign-in successful: ${result['message']}');
        }

        return true;
      } else {
        _error = result['message'] ?? 'Sign-in failed';
        return false;
      }
    } catch (e) {
      _error = 'An unexpected error occurred during sign-in: $e';
      if (kDebugMode) {
        print('Sign-in error in provider: $e');
      }
      return false;
    } finally {
      _isSigningIn = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign out the current user
  Future<bool> signOut() async {
    // Prevent multiple concurrent sign-out operations
    if (_isSigningOut) {
      _error = 'Sign-out already in progress. Please wait.';
      notifyListeners();
      return false;
    }

    _isSigningOut = true;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await SupabaseService.signOut();

      if (result['success'] == true) {
        _clearUserData();

        if (kDebugMode) {
          print('Sign-out successful: ${result['message']}');
        }

        return true;
      } else {
        _error = result['message'] ?? 'Sign-out failed';
        return false;
      }
    } catch (e) {
      _error = 'An unexpected error occurred during sign-out: $e';
      if (kDebugMode) {
        print('Sign-out error in provider: $e');
      }
      return false;
    } finally {
      _isSigningOut = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reset password for a user
  Future<bool> resetPassword({required String email}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await SupabaseService.resetPassword(email: email);

      if (result['success'] == true) {
        if (kDebugMode) {
          print('Password reset successful: ${result['message']}');
        }
        return true;
      } else {
        _error = result['message'] ?? 'Password reset failed';
        return false;
      }
    } catch (e) {
      _error = 'An unexpected error occurred during password reset: $e';
      if (kDebugMode) {
        print('Password reset error in provider: $e');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Resend email verification
  Future<bool> resendEmailVerification() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await SupabaseService.resendEmailVerification();

      if (result['success'] == true) {
        if (kDebugMode) {
          print('Email verification resent: ${result['message']}');
        }
        return true;
      } else {
        _error = result['message'] ?? 'Failed to resend verification email';
        return false;
      }
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
      if (kDebugMode) {
        print('Resend verification error in provider: $e');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? profileImageUrl,
    Map<String, dynamic>? preferences,
  }) async {
    if (_currentUser == null) {
      _error = 'No user signed in';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await SupabaseService.updateUserProfile(
        userId: _currentUser!.id,
        name: name,
        phone: phone,
        profileImageUrl: profileImageUrl,
        preferences: preferences,
      );

      if (result['success'] == true) {
        // Reload user profile to reflect changes
        await _loadUserProfile(forceRefresh: true);

        if (kDebugMode) {
          print('Profile update successful: ${result['message']}');
        }

        return true;
      } else {
        _error = result['message'] ?? 'Profile update failed';
        return false;
      }
    } catch (e) {
      _error = 'An unexpected error occurred during profile update: $e';
      if (kDebugMode) {
        print('Profile update error in provider: $e');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if session is still valid and refresh if needed
  Future<bool> validateSession() async {
    if (!isLoggedIn) return false;

    try {
      // Check connection
      final isConnected = await SupabaseService.checkConnection();
      if (!isConnected) {
        _error = 'No internet connection';
        notifyListeners();
        return false;
      }

      // Refresh user profile to validate session
      await _loadUserProfile(forceRefresh: true);
      _updateLastActivity();

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Session validation error: $e');
      }

      // If session validation fails, sign out the user
      _clearUserData();
      return false;
    }
  }

  /// Load user profile from Supabase
  Future<void> _loadUserProfile({bool forceRefresh = false}) async {
    try {
      final profileData = await SupabaseService.getCurrentUserProfile(
        forceRefresh: forceRefresh,
      );

      if (profileData != null) {
        _currentUser = UserProfile.fromJson(profileData);
      } else {
        _currentUser = null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user profile: $e');
      }
      _error = 'Failed to load user profile';
      _currentUser = null;
    }
  }

  /// Clear user data
  void _clearUserData() {
    _currentUser = null;
    _lastActivity = null;
    SupabaseService.clearCache();
  }

  /// Update last activity timestamp
  void _updateLastActivity() {
    _lastActivity = DateTime.now();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh user profile
  Future<void> refreshProfile() async {
    if (!isLoggedIn) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _loadUserProfile(forceRefresh: true);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check connection status
  Future<bool> checkConnection() async {
    return await SupabaseService.checkConnection();
  }

  /// Get current auth state
  Map<String, dynamic> getAuthState() {
    return {
      ...SupabaseService.getAuthState(),
      'currentUser': _currentUser,
      'isLoading': _isLoading,
      'error': _error,
      'isSessionActive': isSessionActive,
      'lastActivity': _lastActivity,
    };
  }

  /// Extend session on user activity
  void extendSession() {
    _updateLastActivity();
  }

  @override
  void dispose() {
    _clearUserData();
    super.dispose();
  }
}
