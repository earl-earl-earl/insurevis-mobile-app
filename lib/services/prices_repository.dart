import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:insurevis/services/pricing_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton repository that fetches pricing lists once and keeps them in memory.
/// Now with SharedPreferences caching support similar to CarBrandsRepository.
class PricesRepository {
  PricesRepository._privateConstructor();

  static final PricesRepository instance =
      PricesRepository._privateConstructor();

  List<Map<String, dynamic>> _thinsmithParts = [];
  List<Map<String, dynamic>> _bodyPaintParts = [];

  bool _initialized = false;

  static const String _thinsmithCacheKey = 'thinsmith_parts_cache';
  static const String _bodyPaintCacheKey = 'body_paint_parts_cache';
  static const String _cacheTimestampKey = 'prices_cache_timestamp';
  static const Duration _cacheValidity = Duration(days: 7); // Cache for 7 days

  bool get isInitialized => _initialized;

  /// Initialize the repository by fetching both parts lists. Safe to call multiple times.
  /// First tries to load from cache, then fetches from API if cache is invalid/missing.
  Future<void> init() async {
    if (_initialized &&
        _thinsmithParts.isNotEmpty &&
        _bodyPaintParts.isNotEmpty)
      return;

    try {
      // Try to load from cache first
      final cachedData = await _loadFromCache();
      if (cachedData != null) {
        _thinsmithParts = cachedData['thinsmith'] ?? [];
        _bodyPaintParts = cachedData['bodyPaint'] ?? [];

        if (_thinsmithParts.isNotEmpty || _bodyPaintParts.isNotEmpty) {
          debugPrint(
            'PricesRepository: Loaded ${_thinsmithParts.length} thinsmith parts and ${_bodyPaintParts.length} body paint parts from cache',
          );
          _initialized = true;
          return;
        }
      }

      // Cache miss or expired - fetch from API
      await _fetchFromApi();

      // Only mark as initialized if we successfully got data
      if (_thinsmithParts.isNotEmpty || _bodyPaintParts.isNotEmpty) {
        _initialized = true;
        debugPrint(
          'PricesRepository: Successfully initialized with ${_thinsmithParts.length} thinsmith parts and ${_bodyPaintParts.length} body paint parts',
        );
      } else {
        debugPrint(
          'PricesRepository: Initialization completed but no data available',
        );
      }
    } catch (e, st) {
      debugPrint('PricesRepository: Error during initialization: $e');
      debugPrint('Stack trace: $st');
      // Keep empty lists on error
      _thinsmithParts = [];
      _bodyPaintParts = [];
      // Don't mark as initialized if we failed
    }
  }

  /// Load pricing data from shared preferences cache.
  /// Returns null if cache is invalid, expired, or doesn't exist.
  Future<Map<String, List<Map<String, dynamic>>>?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final thinsmithJson = prefs.getString(_thinsmithCacheKey);
      final bodyPaintJson = prefs.getString(_bodyPaintCacheKey);
      final timestamp = prefs.getInt(_cacheTimestampKey);

      if ((thinsmithJson == null && bodyPaintJson == null) ||
          timestamp == null) {
        debugPrint('PricesRepository: No cache found');
        return null;
      }

      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (cacheAge > _cacheValidity.inMilliseconds) {
        debugPrint('PricesRepository: Cache expired');
        return null;
      }

      // Decode in background thread using compute
      final thinsmithData =
          thinsmithJson != null
              ? await compute(_decodeJsonInBackground, thinsmithJson)
              : <Map<String, dynamic>>[];
      final bodyPaintData =
          bodyPaintJson != null
              ? await compute(_decodeJsonInBackground, bodyPaintJson)
              : <Map<String, dynamic>>[];

      return {
        'thinsmith': thinsmithData ?? [],
        'bodyPaint': bodyPaintData ?? [],
      };
    } catch (e) {
      debugPrint('PricesRepository: Error loading from cache: $e');
      return null;
    }
  }

  /// Save pricing data to shared preferences cache.
  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Encode in background thread using compute
      if (_thinsmithParts.isNotEmpty) {
        final thinsmithJson = await compute(
          _encodeJsonInBackground,
          _thinsmithParts,
        );
        await prefs.setString(_thinsmithCacheKey, thinsmithJson);
      }

      if (_bodyPaintParts.isNotEmpty) {
        final bodyPaintJson = await compute(
          _encodeJsonInBackground,
          _bodyPaintParts,
        );
        await prefs.setString(_bodyPaintCacheKey, bodyPaintJson);
      }

      await prefs.setInt(
        _cacheTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      debugPrint(
        'PricesRepository: Saved ${_thinsmithParts.length} thinsmith parts and ${_bodyPaintParts.length} body paint parts to cache',
      );
    } catch (e) {
      debugPrint('PricesRepository: Error saving to cache: $e');
      // Non-fatal - continue without caching
    }
  }

  /// Fetch pricing data from the API and save to cache.
  Future<void> _fetchFromApi() async {
    try {
      debugPrint('PricesRepository: Fetching pricing data from API...');

      final thins = await PricingService.getThinsmithParts();
      _thinsmithParts = List<Map<String, dynamic>>.from(thins);
    } catch (e) {
      debugPrint('PricesRepository: Error fetching thinsmith parts: $e');
      // keep empty list on error
      _thinsmithParts = [];
    }

    try {
      final body = await PricingService.getBodyPaintParts();
      _bodyPaintParts = List<Map<String, dynamic>>.from(body);
    } catch (e) {
      debugPrint('PricesRepository: Error fetching body paint parts: $e');
      _bodyPaintParts = [];
    }

    // Save to cache for future use
    if (_thinsmithParts.isNotEmpty || _bodyPaintParts.isNotEmpty) {
      await _saveToCache();
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

  /// Force refresh both lists from the API.
  /// Clears cache and fetches fresh data.
  Future<void> refresh() async {
    _initialized = false;

    // Clear cache
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_thinsmithCacheKey);
      await prefs.remove(_bodyPaintCacheKey);
      await prefs.remove(_cacheTimestampKey);
      debugPrint('PricesRepository: Cache cleared');
    } catch (e) {
      debugPrint('PricesRepository: Error clearing cache: $e');
    }

    await init();
  }

  List<Map<String, dynamic>> get thinsmithParts => _thinsmithParts;
  List<Map<String, dynamic>> get bodyPaintParts => _bodyPaintParts;

  Map<String, dynamic>? _findInList(
    List<Map<String, dynamic>> list,
    String partName,
  ) {
    final cleanPartName = partName.toLowerCase().trim();

    for (final part in list) {
      final apiPartName =
          part['part_name']?.toString().toLowerCase().trim() ?? '';
      if (apiPartName == cleanPartName) return part;
    }

    for (final part in list) {
      final apiPartName =
          part['part_name']?.toString().toLowerCase().trim() ?? '';
      if (apiPartName.contains(cleanPartName) ||
          cleanPartName.contains(apiPartName))
        return part;
    }

    return null;
  }

  /// Find part in cached thinsmith list. Returns null if not found.
  Future<Map<String, dynamic>?> findThinsmithPart(String partName) async {
    if (!_initialized) await init();
    final found = _findInList(_thinsmithParts, partName);
    if (found != null) return found;

    // Fallback to live API search if not found in cache
    try {
      return await PricingService.findThinsmithPart(partName);
    } catch (_) {
      return null;
    }
  }

  /// Find part in cached body-paint list. Returns null if not found.
  Future<Map<String, dynamic>?> findBodyPaintPart(String partName) async {
    if (!_initialized) await init();
    final found = _findInList(_bodyPaintParts, partName);
    if (found != null) return found;

    // Fallback to live API search if not found in cache
    try {
      return await PricingService.findBodyPaintPart(partName);
    } catch (_) {
      return null;
    }
  }

  /// Return both repair and replace structures similar to PricingService.getBothRepairAndReplacePricing
  Future<Map<String, dynamic>> getBothRepairAndReplacePricing(
    String damagedPart,
  ) async {
    try {
      final repairData = await findThinsmithPart(damagedPart);
      final replaceData = await findBodyPaintPart(damagedPart);

      // compute totals that include installation labor when available
      double repairInsurance =
          (repairData?['insurance'] as num?)?.toDouble() ?? 0.0;
      double replaceSrpInsurance =
          (replaceData?['srp_insurance'] as num?)?.toDouble() ?? 0.0;
      double repairLabor =
          (repairData?['cost_installation_personal'] as num?)?.toDouble() ??
          0.0;
      double replaceLabor =
          (replaceData?['cost_installation_personal'] as num?)?.toDouble() ??
          0.0;

      final repairTotalWithLabor =
          (repairInsurance + replaceSrpInsurance + repairLabor) > 0
              ? (repairInsurance + replaceSrpInsurance + repairLabor)
              : null;

      final replaceTotalWithLabor =
          (replaceSrpInsurance + replaceLabor) > 0
              ? (replaceSrpInsurance + replaceLabor)
              : null;

      final combinedTotalWithLabor =
          (repairTotalWithLabor ?? 0.0) + (replaceTotalWithLabor ?? 0.0) > 0
              ? ((repairTotalWithLabor ?? 0.0) + (replaceTotalWithLabor ?? 0.0))
              : null;

      return {
        'part_name': damagedPart,
        // Swapped: repair_data now reports from body-paint (replaceData)
        'repair_data':
            replaceData != null
                ? {
                  'success': true,
                  'source': 'body_paint',
                  'part_name': replaceData['part_name'],
                  'cost_installation_personal':
                      replaceData['cost_installation_personal'],
                  'srp_insurance': replaceData['srp_insurance'],
                  'srp_personal': replaceData['srp_personal'],
                  'id': replaceData['id'],
                  // total including part/paint srp + labor (previously replace total)
                  'total_with_labor': replaceTotalWithLabor,
                  'message':
                      'Repair pricing available from body-paint database',
                }
                : {
                  'success': false,
                  'source': 'body_paint',
                  'part_name': damagedPart,
                  'cost_installation_personal': null,
                  'srp_insurance': null,
                  'srp_personal': null,
                  'id': null,
                  'total_with_labor': null,
                  'message': 'Repair pricing not found in body-paint database',
                },
        // Swapped: replace_data now reports from thinsmith (repairData)
        'replace_data':
            repairData != null
                ? {
                  'success': true,
                  'source': 'thinsmith',
                  'part_name': repairData['part_name'],
                  'cost_installation_personal':
                      repairData['cost_installation_personal'],
                  'insurance': repairData['insurance'],
                  'srp': repairData['srp'],
                  'id': repairData['id'],
                  // total including repair insurance + (possible) body-paint srp + labor (previously repair total)
                  'total_with_labor': repairTotalWithLabor,
                  'message':
                      'Replace pricing available from thinsmith database',
                }
                : {
                  'success': false,
                  'source': 'thinsmith',
                  'part_name': damagedPart,
                  'cost_installation_personal': null,
                  'insurance': null,
                  'srp': null,
                  'id': null,
                  'total_with_labor': null,
                  'message': 'Replace pricing not found in thinsmith database',
                },
        'has_repair_data': replaceData != null,
        'has_replace_data': repairData != null,
        'overall_success': repairData != null || replaceData != null,
        'combined_total_with_labor': combinedTotalWithLabor,
      };
    } catch (e) {
      return {
        'part_name': damagedPart,
        // Swapped error sources/messages to match the new mapping
        'repair_data': {
          'success': false,
          'source': 'body_paint',
          'part_name': damagedPart,
          'cost_installation_personal': null,
          'srp_insurance': null,
          'srp_personal': null,
          'id': null,
          'message': 'Error occurred while searching body-paint: $e',
          'error': e.toString(),
        },
        'replace_data': {
          'success': false,
          'source': 'thinsmith',
          'part_name': damagedPart,
          'cost_installation_personal': null,
          'insurance': null,
          'srp': null,
          'id': null,
          'message': 'Error occurred while searching thinsmith: $e',
          'error': e.toString(),
        },
        'has_repair_data': false,
        'has_replace_data': false,
        'overall_success': false,
        'error': e.toString(),
      };
    }
  }
}
