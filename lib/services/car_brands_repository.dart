import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton repository that fetches car brands once and keeps them in memory.
/// Similar to PricesRepository but for car brands/models data.
/// Now with background threading and local caching support.
class CarBrandsRepository {
  CarBrandsRepository._privateConstructor();

  static final CarBrandsRepository instance =
      CarBrandsRepository._privateConstructor();

  List<Map<String, dynamic>> _brandsData = [];
  bool _initialized = false;

  static const String _apiUrl =
      'https://vvnsludqdidnqpbzzgeb.supabase.co/functions/v1/car-database/api/brands';
  static const String _cacheKey = 'car_brands_cache';
  static const String _cacheTimestampKey = 'car_brands_cache_timestamp';
  static const Duration _cacheValidity = Duration(days: 7); // Cache for 7 days

  bool get isInitialized => _initialized;
  List<Map<String, dynamic>> get brands => _brandsData;

  /// Initialize the repository by fetching car brands data.
  /// Safe to call multiple times - will skip if already initialized.
  /// First tries to load from cache, then fetches from API if cache is invalid/missing.
  Future<void> init() async {
    if (_initialized) return;

    try {
      // Try to load from cache first
      final cachedData = await _loadFromCache();
      if (cachedData != null) {
        _brandsData = cachedData;
        debugPrint(
          'CarBrandsRepository: Loaded ${_brandsData.length} car brands from cache',
        );
        _initialized = true;
        return;
      }

      // Cache miss or expired - fetch from API
      await _fetchFromApi();
    } catch (e, st) {
      debugPrint('CarBrandsRepository: Error during initialization: $e');
      debugPrint('Stack trace: $st');
      // Keep empty list on error
      _brandsData = [];
    }

    _initialized = true;
  }

  /// Load brands data from shared preferences cache.
  /// Returns null if cache is invalid, expired, or doesn't exist.
  Future<List<Map<String, dynamic>>?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);
      final timestamp = prefs.getInt(_cacheTimestampKey);

      if (cachedJson == null || timestamp == null) {
        debugPrint('CarBrandsRepository: No cache found');
        return null;
      }

      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (cacheAge > _cacheValidity.inMilliseconds) {
        debugPrint('CarBrandsRepository: Cache expired');
        return null;
      }

      // Decode in background thread using compute
      final data = await compute(_decodeJsonInBackground, cachedJson);
      return data;
    } catch (e) {
      debugPrint('CarBrandsRepository: Error loading from cache: $e');
      return null;
    }
  }

  /// Save brands data to shared preferences cache.
  Future<void> _saveToCache(List<Map<String, dynamic>> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Encode in background thread using compute
      final jsonString = await compute(_encodeJsonInBackground, data);

      await prefs.setString(_cacheKey, jsonString);
      await prefs.setInt(
        _cacheTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      debugPrint('CarBrandsRepository: Saved ${data.length} brands to cache');
    } catch (e) {
      debugPrint('CarBrandsRepository: Error saving to cache: $e');
      // Non-fatal - continue without caching
    }
  }

  /// Fetch brands data from the API and save to cache.
  Future<void> _fetchFromApi() async {
    try {
      debugPrint('CarBrandsRepository: Fetching car brands from API...');
      debugPrint('CarBrandsRepository: API URL: $_apiUrl');

      // Get access token for authentication
      String? accessToken;
      try {
        final session = Supabase.instance.client.auth.currentSession;
        accessToken = session?.accessToken;
        debugPrint(
          'CarBrandsRepository: Auth token ${accessToken != null ? "present" : "missing"}',
        );
      } catch (_) {
        accessToken = null;
        debugPrint('CarBrandsRepository: Could not get auth token');
      }

      // Build headers with authentication
      final headers = {
        'Content-Type': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };

      debugPrint(
        'CarBrandsRepository: Request headers: ${headers.keys.toList()}',
      );

      final response = await http
          .get(Uri.parse(_apiUrl), headers: headers)
          .timeout(const Duration(seconds: 15));

      debugPrint(
        'CarBrandsRepository: Response status: ${response.statusCode}',
      );
      debugPrint(
        'CarBrandsRepository: Response body length: ${response.body.length}',
      );

      if (response.statusCode == 200) {
        // Decode in background thread using compute
        final data = await compute(_parseApiResponse, response.body);

        if (data != null && data.isNotEmpty) {
          _brandsData = data;
          debugPrint(
            'CarBrandsRepository: Successfully loaded ${_brandsData.length} car brands from API',
          );

          // Save to cache for future use
          await _saveToCache(_brandsData);
        } else {
          debugPrint(
            'CarBrandsRepository: API returned empty data or parsing failed',
          );
          _brandsData = [];
        }
      } else {
        debugPrint(
          'CarBrandsRepository: Failed to load car brands: ${response.statusCode} ${response.body}',
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
  }

  /// Force refresh the brands data from the API.
  /// Clears cache and fetches fresh data.
  Future<void> refresh() async {
    _initialized = false;

    // Clear cache
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
      debugPrint('CarBrandsRepository: Cache cleared');
    } catch (e) {
      debugPrint('CarBrandsRepository: Error clearing cache: $e');
    }

    await init();
  }

  /// Static helper function to parse API response in background isolate.
  static List<Map<String, dynamic>>? _parseApiResponse(String responseBody) {
    try {
      debugPrint('CarBrandsRepository: Raw response body: $responseBody');
      final data = json.decode(responseBody);
      debugPrint('CarBrandsRepository: Decoded data type: ${data.runtimeType}');
      debugPrint(
        'CarBrandsRepository: Decoded data keys: ${data is Map ? data.keys.toList() : "not a map"}',
      );

      // Handle different response formats
      // Try 'brands' key first (old Flask format)
      if (data is Map && data['brands'] != null) {
        debugPrint(
          'CarBrandsRepository: Found brands key with ${data['brands'].length} items',
        );
        return List<Map<String, dynamic>>.from(data['brands']);
      }

      // Try direct array response (Deno might return array directly)
      if (data is List) {
        debugPrint(
          'CarBrandsRepository: Response is direct array with ${data.length} items',
        );
        return List<Map<String, dynamic>>.from(data);
      }

      // Try 'data' key (common alternative)
      if (data is Map && data['data'] != null) {
        debugPrint(
          'CarBrandsRepository: Found data key with ${data['data'].length} items',
        );
        return List<Map<String, dynamic>>.from(data['data']);
      }

      debugPrint('CarBrandsRepository: No recognized data format found');
      return null;
    } catch (e, st) {
      debugPrint('Error parsing API response in background: $e');
      debugPrint('Stack trace: $st');
      return null;
    }
  }

  /// Static helper function to decode JSON string in background isolate.
  static List<Map<String, dynamic>>? _decodeJsonInBackground(
    String jsonString,
  ) {
    try {
      final decoded = json.decode(jsonString);
      return List<Map<String, dynamic>>.from(decoded);
    } catch (e) {
      debugPrint('Error decoding JSON in background: $e');
      return null;
    }
  }

  /// Static helper function to encode data to JSON string in background isolate.
  static String _encodeJsonInBackground(List<Map<String, dynamic>> data) {
    return json.encode(data);
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
