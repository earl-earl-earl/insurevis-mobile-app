import 'package:insurevis/services/supabase_service.dart';

/// Utility class for authentication form validations
class AuthValidationUtils {
  /// Validates a name field
  static String? validateName(String? value) {
    return SupabaseService.validateName(value ?? '');
  }

  /// Validates an email field
  static String? validateEmail(String? value) {
    return SupabaseService.validateEmail(value ?? '');
  }

  /// Validates a phone field
  static String? validatePhone(String? value) {
    return SupabaseService.validatePhone(value);
  }

  /// Validates a password field
  static String? validatePassword(String? value) {
    return SupabaseService.validatePassword(value ?? '');
  }

  /// Validates password confirmation
  static String? validateConfirmPassword(
    String? value,
    String passwordToMatch,
  ) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordToMatch) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Checks if password has minimum length (8 characters)
  static bool hasMinLength(String password) => password.length >= 8;

  /// Checks if password has at least one uppercase letter
  static bool hasUppercase(String password) =>
      password.contains(RegExp(r'[A-Z]'));

  /// Checks if password has at least one lowercase letter
  static bool hasLowercase(String password) =>
      password.contains(RegExp(r'[a-z]'));

  /// Checks if password has at least one number
  static bool hasNumber(String password) => password.contains(RegExp(r'[0-9]'));

  /// Checks if password has at least one special character
  static bool hasSpecialChar(String password) =>
      password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
}
