import 'package:insurevis/services/supabase_service.dart';

/// Utility class for password management operations
class PasswordUtils {
  /// Validates a password change request
  /// Returns error message if validation fails, null otherwise
  static String? validatePasswordChange({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) {
    if (currentPassword.isEmpty) {
      return 'Please enter your current password';
    }

    if (newPassword.isEmpty) {
      return 'Please enter a new password';
    }

    if (newPassword != confirmPassword) {
      return 'Passwords do not match';
    }

    if (currentPassword == newPassword) {
      return 'New password must be different from current password';
    }

    // Validate password strength
    final passErr = SupabaseService.validatePassword(newPassword);
    if (passErr != null) {
      return passErr;
    }

    return null;
  }

  /// Handles password change operation
  /// Returns a map with 'success' boolean and 'message' string
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return await SupabaseService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
