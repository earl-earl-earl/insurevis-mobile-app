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

  /// Calculates password strength score (0-5)
  /// Returns an integer representing password strength:
  /// 0 = Very Weak, 1 = Weak, 2 = Fair, 3 = Good, 4 = Strong, 5 = Very Strong
  static int getPasswordStrength(String password) {
    if (password.isEmpty) return 0;

    int score = 0;

    // Length check
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;

    // Character variety checks
    if (hasUppercase(password)) score++;
    if (hasLowercase(password)) score++;
    if (hasNumber(password)) score++;
    if (hasSpecialChar(password)) score++;

    // Cap at 5
    return score > 5 ? 5 : score;
  }

  /// Gets a human-readable password strength label
  static String getPasswordStrengthLabel(int strength) {
    switch (strength) {
      case 0:
        return 'Very Weak';
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      case 5:
        return 'Very Strong';
      default:
        return 'Unknown';
    }
  }

  /// Gets password strength color for visual feedback
  static int getPasswordStrengthColor(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return 0xFFE57373; // errorMain
      case 2:
        return 0xFFFFB74D; // warningMain
      case 3:
        return 0xFF64B5F6; // infoMain
      case 4:
      case 5:
        return 0xFF81C784; // successMain
      default:
        return 0xFF666666; // textTertiary
    }
  }

  /// Validates email format more strictly
  static bool isValidEmailFormat(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validates phone number format (basic international format)
  static bool isValidPhoneFormat(String? phone) {
    if (phone == null || phone.isEmpty) return true; // Optional field
    final phoneRegex = RegExp(r'^[\d\s\-\(\)\+]{10,}$');
    return phoneRegex.hasMatch(phone);
  }

  /// Checks if name contains only valid characters
  static bool hasValidNameCharacters(String name) {
    final nameRegex = RegExp(r"^[a-zA-Z\s'-]+$");
    return nameRegex.hasMatch(name);
  }

  /// Gets detailed validation message for better UX
  static String getDetailedPasswordError(String password) {
    final errors = <String>[];

    if (!hasMinLength(password)) {
      errors.add('at least 8 characters');
    }
    if (!hasUppercase(password)) {
      errors.add('one uppercase letter');
    }
    if (!hasLowercase(password)) {
      errors.add('one lowercase letter');
    }
    if (!hasNumber(password)) {
      errors.add('one number');
    }
    if (!hasSpecialChar(password)) {
      errors.add('one special character');
    }

    if (errors.isEmpty) return '';
    if (errors.length == 1) return 'Password needs ${errors[0]}';
    if (errors.length == 2) {
      return 'Password needs ${errors[0]} and ${errors[1]}';
    }

    return 'Password needs ${errors.sublist(0, errors.length - 1).join(", ")} and ${errors.last}';
  }
}
