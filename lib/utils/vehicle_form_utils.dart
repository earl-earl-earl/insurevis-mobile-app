class VehicleFormUtils {
  /// Validate vehicle make
  static String? validateMake(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vehicle make is required';
    }
    if (value.trim().length < 2) {
      return 'Vehicle make must be at least 2 characters';
    }
    return null;
  }

  /// Validate vehicle model
  static String? validateModel(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vehicle model is required';
    }
    if (value.trim().length < 2) {
      return 'Vehicle model must be at least 2 characters';
    }
    return null;
  }

  /// Validate vehicle year
  static String? validateYear(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vehicle year is required';
    }

    final year = int.tryParse(value.trim());
    if (year == null) {
      return 'Year must be a valid number';
    }

    final currentYear = DateTime.now().year;
    if (year < 1900 || year > currentYear + 1) {
      return 'Year must be between 1900 and ${currentYear + 1}';
    }

    return null;
  }

  /// Validate plate number
  static String? validatePlateNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Plate number is required';
    }
    if (value.trim().length < 3) {
      return 'Plate number must be at least 3 characters';
    }
    return null;
  }

  /// Check if all fields are filled
  static bool isFormComplete({
    required String make,
    required String model,
    required String year,
    required String plateNumber,
  }) {
    return make.trim().isNotEmpty &&
        model.trim().isNotEmpty &&
        year.trim().isNotEmpty &&
        plateNumber.trim().isNotEmpty;
  }

  /// Prepare vehicle data for submission
  static Map<String, String> prepareVehicleData({
    required String make,
    required String model,
    required String year,
    required String plateNumber,
  }) {
    return {
      'make': make.trim(),
      'model': model.trim(),
      'year': year.trim(),
      'plate_number': plateNumber.trim(),
    };
  }

  /// Validate all fields at once
  static Map<String, String?> validateAllFields({
    required String make,
    required String model,
    required String year,
    required String plateNumber,
  }) {
    return {
      'make': validateMake(make),
      'model': validateModel(model),
      'year': validateYear(year),
      'plate_number': validatePlateNumber(plateNumber),
    };
  }

  /// Check if validation passed
  static bool hasValidationErrors(Map<String, String?> validationResults) {
    return validationResults.values.any((error) => error != null);
  }
}
