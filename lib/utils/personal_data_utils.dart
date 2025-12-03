import 'package:insurevis/services/supabase_service.dart';

class PersonalDataUtils {
  /// Validate name field
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    return SupabaseService.validateName(value.trim());
  }

  /// Validate email field
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    return SupabaseService.validateEmail(value.trim());
  }

  /// Validate phone field (optional)
  static String? validatePhone(String? value) {
    return SupabaseService.validatePhone(value);
  }

  /// Check if form data has changed
  static bool hasChanges({
    required String originalName,
    required String originalEmail,
    required String originalPhone,
    required String newName,
    required String newEmail,
    required String newPhone,
  }) {
    return originalName.trim() != newName.trim() ||
        originalEmail.trim() != newEmail.trim() ||
        originalPhone.trim() != newPhone.trim();
  }

  /// Prepare profile data for update
  static Map<String, String?> prepareProfileData({
    required String name,
    required String email,
    required String phone,
  }) {
    return {
      'name': name.trim().isEmpty ? null : name.trim(),
      'email': email.trim().isEmpty ? null : email.trim(),
      'phone': phone.trim().isEmpty ? null : phone.trim(),
    };
  }
}
