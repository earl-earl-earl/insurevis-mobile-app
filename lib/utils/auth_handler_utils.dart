import 'package:flutter/material.dart';
import 'package:insurevis/providers/auth_provider.dart';
import 'package:insurevis/services/supabase_service.dart';

/// Utility class for handling authentication operations
class AuthHandlerUtils {
  /// Handles user sign in
  /// Returns a map with 'success' boolean and optional 'error' message
  static Future<Map<String, dynamic>> handleSignIn({
    required BuildContext context,
    required AuthProvider authProvider,
    required String email,
    required String password,
  }) async {
    authProvider.clearError();

    final success = await authProvider.signIn(
      email: email.trim().toLowerCase(),
      password: password,
    );

    if (success) {
      return {'success': true};
    } else {
      final errorMessage =
          authProvider.error ?? 'Sign-in failed. Please try again.';
      return {'success': false, 'error': errorMessage};
    }
  }

  /// Handles user sign up
  /// Returns a map with 'success' boolean, 'autoSignedIn' boolean, and optional 'error' message
  static Future<Map<String, dynamic>> handleSignUp({
    required BuildContext context,
    required AuthProvider authProvider,
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    authProvider.clearError();

    final success = await authProvider.signUp(
      name: name.trim(),
      email: email.trim().toLowerCase(),
      password: password,
      phone: phone?.trim().isNotEmpty == true ? phone!.trim() : null,
    );

    if (success) {
      // Check if auto sign-in succeeded
      final autoSignedIn = authProvider.isLoggedIn;
      return {'success': true, 'autoSignedIn': autoSignedIn};
    } else {
      final errorMessage =
          authProvider.error ?? 'Sign-up failed. Please try again.';
      return {'success': false, 'error': errorMessage};
    }
  }

  /// Handles password reset email
  /// Returns a map with 'success' boolean and optional 'error' message
  static Future<Map<String, dynamic>> handlePasswordResetEmail({
    required BuildContext context,
    required AuthProvider authProvider,
    required String email,
  }) async {
    authProvider.clearError();

    final success = await authProvider.resetPassword(email: email);

    if (success) {
      return {'success': true};
    } else {
      final errorMessage = authProvider.error ?? 'Failed to send reset email.';
      return {'success': false, 'error': errorMessage};
    }
  }

  /// Checks if user account exists
  /// Returns true if account exists, false otherwise
  static Future<bool> checkAccountExists(String email) async {
    return await SupabaseService.userExists(email.trim().toLowerCase());
  }

  /// Handles manual password reset (for forgot password flow)
  /// Returns a map with 'success' boolean and 'message' string
  static Future<Map<String, dynamic>> handleManualPasswordReset({
    required String email,
    required String newPassword,
  }) async {
    return await SupabaseService.manualResetPassword(
      email: email.trim().toLowerCase(),
      newPassword: newPassword,
    );
  }
}
