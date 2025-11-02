import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Singleton repository that fetches car brands once and keeps them in memory.
/// Similar to PricesRepository but for car brands/models data.
class CarBrandsRepository {
  CarBrandsRepository._privateConstructor();

  static final CarBrandsRepository instance =
      CarBrandsRepository._privateConstructor();

  List<Map<String, dynamic>> _brandsData = [];
  bool _initialized = false;

  static const String _apiUrl =
      'https://insurevis-car-database-api.onrender.com/api/brands';

  bool get isInitialized => _initialized;
  List<Map<String, dynamic>> get brands => _brandsData;

  /// Initialize the repository by fetching car brands data.
  /// Safe to call multiple times - will skip if already initialized.
  Future<void> init() async {
    if (_initialized) return;

    try {
      debugPrint('CarBrandsRepository: Fetching car brands from API...');
      final response = await http
          .get(
            Uri.parse(_apiUrl),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['brands'] != null) {
          _brandsData = List<Map<String, dynamic>>.from(data['brands']);
          debugPrint(
            'CarBrandsRepository: Successfully loaded ${_brandsData.length} car brands',
          );
        }
      } else {
        debugPrint(
          'CarBrandsRepository: Failed to load car brands: ${response.statusCode}',
        );
        // Keep empty list on error
        _brandsData = [];
      }
    } catch (e, st) {
      debugPrint('CarBrandsRepository: Error fetching car brands: $e');
      debugPrint('Stack trace: $st');
      // Keep empty list on error
      _brandsData = [];
    }

    _initialized = true;
  }

  /// Force refresh the brands data from the API.
  Future<void> refresh() async {
    _initialized = false;
    await init();
  }

  /// Find a brand by name (case-insensitive).
  Map<String, dynamic>? findBrandByName(String brandName) {
    if (!_initialized || _brandsData.isEmpty) return null;

    final cleanName = brandName.toLowerCase().trim();

    for (final brand in _brandsData) {
      final name = brand['name']?.toString().toLowerCase().trim() ?? '';
      if (name == cleanName) {
        return brand;
      }
    }

    return null;
  }

  /// Get all models for a specific brand.
  List<Map<String, dynamic>> getModelsForBrand(String brandName) {
    final brand = findBrandByName(brandName);
    if (brand == null || brand['models'] == null) return [];

    return List<Map<String, dynamic>>.from(brand['models']);
  }

  /// Find a specific model within a brand.
  Map<String, dynamic>? findModel(String brandName, String modelName) {
    final models = getModelsForBrand(brandName);
    if (models.isEmpty) return null;

    final cleanModelName = modelName.toLowerCase().trim();

    for (final model in models) {
      final name = model['model_name']?.toString().toLowerCase().trim() ?? '';
      if (name == cleanModelName) {
        return model;
      }
    }

    return null;
  }

  /// Get the year for a specific brand and model combination.
  int? getYearForModel(String brandName, String modelName) {
    final model = findModel(brandName, modelName);
    return model?['year'] as int?;
  }
}
