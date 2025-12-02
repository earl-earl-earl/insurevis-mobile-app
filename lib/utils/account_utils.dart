import 'package:flutter/material.dart';
import 'package:insurevis/providers/auth_provider.dart';

/// Utility class for account management operations
class AccountUtils {
  /// Validates account deletion request
  /// Returns error message if validation fails, null otherwise
  static String? validateAccountDeletion({
    required String confirmText,
    required String password,
  }) {
    if (confirmText.toUpperCase() != 'CONFIRM') {
      return 'Please type CONFIRM to proceed.';
    }

    if (password.isEmpty) {
      return 'Password is required.';
    }

    return null;
  }

  /// Handles account deletion operation
  /// Returns true if successful, false otherwise
  static Future<bool> deleteAccount({
    required BuildContext context,
    required AuthProvider authProvider,
    required String password,
  }) async {
    return await authProvider.deleteAccount(password: password);
  }

  /// Navigates to sign-in screen after account deletion
  static void navigateToSignIn(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
  }
}
