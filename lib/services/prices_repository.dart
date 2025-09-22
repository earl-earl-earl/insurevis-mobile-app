import 'package:insurevis/services/pricing_service.dart';

/// Singleton repository that fetches pricing lists once and keeps them in memory.
class PricesRepository {
  PricesRepository._privateConstructor();

  static final PricesRepository instance =
      PricesRepository._privateConstructor();

  List<Map<String, dynamic>> _thinsmithParts = [];
  List<Map<String, dynamic>> _bodyPaintParts = [];

  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Initialize the repository by fetching both parts lists. Safe to call multiple times.
  Future<void> init() async {
    if (_initialized) return;

    try {
      final thins = await PricingService.getThinsmithParts();
      _thinsmithParts = List<Map<String, dynamic>>.from(thins);
    } catch (e) {
      // keep empty list on error
      _thinsmithParts = [];
    }

    try {
      final body = await PricingService.getBodyPaintParts();
      _bodyPaintParts = List<Map<String, dynamic>>.from(body);
    } catch (e) {
      _bodyPaintParts = [];
    }

    _initialized = true;
  }

  /// Force refresh both lists from the API.
  Future<void> refresh() async {
    _initialized = false;
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

      return {
        'part_name': damagedPart,
        'repair_data':
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
                  'message': 'Repair pricing available from thinsmith database',
                }
                : {
                  'success': false,
                  'source': 'thinsmith',
                  'part_name': damagedPart,
                  'cost_installation_personal': null,
                  'insurance': null,
                  'srp': null,
                  'id': null,
                  'message': 'Repair pricing not found in thinsmith database',
                },
        'replace_data':
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
                  'message':
                      'Replace pricing available from body-paint database',
                }
                : {
                  'success': false,
                  'source': 'body_paint',
                  'part_name': damagedPart,
                  'cost_installation_personal': null,
                  'srp_insurance': null,
                  'srp_personal': null,
                  'id': null,
                  'message': 'Replace pricing not found in body-paint database',
                },
        'has_repair_data': repairData != null,
        'has_replace_data': replaceData != null,
        'overall_success': repairData != null || replaceData != null,
      };
    } catch (e) {
      return {
        'part_name': damagedPart,
        'repair_data': {
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
        'replace_data': {
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
        'has_repair_data': false,
        'has_replace_data': false,
        'overall_success': false,
        'error': e.toString(),
      };
    }
  }
}
