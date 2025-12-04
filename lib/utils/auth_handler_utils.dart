import 'package:flutter/material.dart';
import 'package:insurevis/providers/auth_provider.dart';
import 'package:insurevis/services/supabase_service.dart';

/// Utility class for handling authentication operations
class AuthHandlerUtils {
  /// Default timeout for authentication operations
  static const Duration _defaultTimeout = Duration(seconds: 30);

  /// Handles user sign in with timeout and detailed error handling
  /// Returns a map with 'success' boolean, optional 'error' message, and 'errorType'
  static Future<Map<String, dynamic>> handleSignIn({
    required BuildContext context,
    required AuthProvider authProvider,
    required String email,
    required String password,
    Duration? timeout,
  }) async {
    authProvider.clearError();

    try {
      final success = await authProvider
          .signIn(email: email.trim().toLowerCase(), password: password)
          .timeout(
            timeout ?? _defaultTimeout,
            onTimeout: () {
              return false;
            },
          );

      if (success) {
        return {'success': true};
      } else {
        final errorMessage =
            authProvider.error ?? 'Sign-in failed. Please try again.';
        return {
          'success': false,
          'error': errorMessage,
          'errorType': _categorizeError(errorMessage),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error. Please check your internet connection.',
        'errorType': 'network',
      };
    }
  }

  /// Handles user sign up with timeout and detailed error handling
  /// Returns a map with 'success' boolean, 'autoSignedIn' boolean, optional 'error' message, and 'errorType'
  static Future<Map<String, dynamic>> handleSignUp({
    required BuildContext context,
    required AuthProvider authProvider,
    required String name,
    required String email,
    required String password,
    String? phone,
    Duration? timeout,
  }) async {
    authProvider.clearError();

    try {
      final success = await authProvider
          .signUp(
            name: name.trim(),
            email: email.trim().toLowerCase(),
            password: password,
            phone: phone?.trim().isNotEmpty == true ? phone!.trim() : null,
          )
          .timeout(
            timeout ?? _defaultTimeout,
            onTimeout: () {
              return false;
            },
          );

      if (success) {
        // Check if auto sign-in succeeded
        final autoSignedIn = authProvider.isLoggedIn;
        return {'success': true, 'autoSignedIn': autoSignedIn};
      } else {
        final errorMessage =
            authProvider.error ?? 'Sign-up failed. Please try again.';
        return {
          'success': false,
          'error': errorMessage,
          'errorType': _categorizeError(errorMessage),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error. Please check your internet connection.',
        'errorType': 'network',
      };
    }
  }

  /// Handles password reset email with timeout
  /// Returns a map with 'success' boolean, optional 'error' message, and 'errorType'
  static Future<Map<String, dynamic>> handlePasswordResetEmail({
    required BuildContext context,
    required AuthProvider authProvider,
    required String email,
    Duration? timeout,
  }) async {
    authProvider.clearError();

    try {
      final success = await authProvider
          .resetPassword(email: email)
          .timeout(
            timeout ?? _defaultTimeout,
            onTimeout: () {
              return false;
            },
          );

      if (success) {
        return {'success': true};
      } else {
        final errorMessage =
            authProvider.error ?? 'Failed to send reset email.';
        return {
          'success': false,
          'error': errorMessage,
          'errorType': _categorizeError(errorMessage),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error. Please check your internet connection.',
        'errorType': 'network',
      };
    }
  }

  /// Checks if user account exists with timeout
  /// Returns true if account exists, false otherwise
  static Future<bool> checkAccountExists(
    String email, {
    Duration? timeout,
  }) async {
    try {
      return await SupabaseService.userExists(
        email.trim().toLowerCase(),
      ).timeout(timeout ?? _defaultTimeout, onTimeout: () => false);
    } catch (e) {
      return false;
    }
  }

  /// Handles manual password reset (for forgot password flow) with timeout
  /// Returns a map with 'success' boolean and 'message' string
  static Future<Map<String, dynamic>> handleManualPasswordReset({
    required String email,
    required String newPassword,
    Duration? timeout,
  }) async {
    try {
      return await SupabaseService.manualResetPassword(
        email: email.trim().toLowerCase(),
        newPassword: newPassword,
      ).timeout(
        timeout ?? _defaultTimeout,
        onTimeout:
            () => {
              'success': false,
              'message': 'Request timed out. Please try again.',
            },
      );
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred. Please try again later.',
      };
    }
  }

  /// Categorizes error messages for better handling
  static String _categorizeError(String errorMessage) {
    final lowerError = errorMessage.toLowerCase();

    if (lowerError.contains('email') || lowerError.contains('user not found')) {
      return 'email';
    }
    if (lowerError.contains('password') ||
        lowerError.contains('invalid credentials')) {
      return 'password';
    }
    if (lowerError.contains('network') ||
        lowerError.contains('connection') ||
        lowerError.contains('timeout')) {
      return 'network';
    }
    if (lowerError.contains('already exists') ||
        lowerError.contains('duplicate')) {
      return 'duplicate';
    }

    return 'general';
  }

  /// Gets user-friendly error message based on error type
  static String getUserFriendlyError(String errorMessage, String errorType) {
    switch (errorType) {
      case 'email':
        return 'Please check your email address and try again.';
      case 'password':
        return 'Incorrect password. Please try again.';
      case 'network':
        return 'Connection issue. Please check your internet and try again.';
      case 'duplicate':
        return 'An account with this email already exists.';
      default:
        return errorMessage;
    }
  }
}
