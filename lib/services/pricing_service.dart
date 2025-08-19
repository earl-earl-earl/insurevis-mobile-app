import 'dart:convert';
import 'package:http/http.dart' as http;

class PricingService {
  static const String _baseUrl = 'https://insurevis-price-api.onrender.com';

  // Fetch thinsmith parts pricing data
  static Future<List<Map<String, dynamic>>> getThinsmithParts() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/thinsmith'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception(
          'Failed to load thinsmith parts: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching thinsmith parts: $e');
    }
  }

  // Fetch body paint parts pricing data
  static Future<List<Map<String, dynamic>>> getBodyPaintParts() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/body-paint'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception(
          'Failed to load body paint parts: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching body paint parts: $e');
    }
  }

  // Find a specific part in thinsmith data by name
  static Future<Map<String, dynamic>?> findThinsmithPart(
    String partName,
  ) async {
    try {
      final parts = await getThinsmithParts();

      // Clean the part name for comparison
      final cleanPartName = partName.toLowerCase().trim();

      // Try exact match first
      for (final part in parts) {
        final apiPartName =
            part['part_name']?.toString().toLowerCase().trim() ?? '';
        if (apiPartName == cleanPartName) {
          return part;
        }
      }

      // Try partial match if exact match fails
      for (final part in parts) {
        final apiPartName =
            part['part_name']?.toString().toLowerCase().trim() ?? '';
        if (apiPartName.contains(cleanPartName) ||
            cleanPartName.contains(apiPartName)) {
          return part;
        }
      }

      return null;
    } catch (e) {
      print('Error finding thinsmith part: $e');
      return null;
    }
  }

  // Find a specific part in body paint data by name
  static Future<Map<String, dynamic>?> findBodyPaintPart(
    String partName,
  ) async {
    try {
      final parts = await getBodyPaintParts();

      // Clean the part name for comparison
      final cleanPartName = partName.toLowerCase().trim();

      // Try exact match first
      for (final part in parts) {
        final apiPartName =
            part['part_name']?.toString().toLowerCase().trim() ?? '';
        if (apiPartName == cleanPartName) {
          return part;
        }
      }

      // Try partial match if exact match fails
      for (final part in parts) {
        final apiPartName =
            part['part_name']?.toString().toLowerCase().trim() ?? '';
        if (apiPartName.contains(cleanPartName) ||
            cleanPartName.contains(apiPartName)) {
          return part;
        }
      }

      return null;
    } catch (e) {
      print('Error finding body paint part: $e');
      return null;
    }
  }

  // Get both repair and replace pricing data separately for a damaged part
  static Future<Map<String, dynamic>> getBothRepairAndReplacePricing(
    String damagedPart,
  ) async {
    try {
      // Get repair data from thinsmith
      Map<String, dynamic>? repairData = await findThinsmithPart(damagedPart);

      // Get replace data from body-paint
      Map<String, dynamic>? replaceData = await findBodyPaintPart(damagedPart);

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

  // Get pricing for a damaged part with detailed error information (legacy method)
  static Future<Map<String, dynamic>> getPricingForDamagedPartWithDetails(
    String damagedPart,
  ) async {
    try {
      // First try thinsmith parts
      Map<String, dynamic>? pricing = await findThinsmithPart(damagedPart);

      if (pricing != null) {
        return {
          'success': true,
          'source': 'thinsmith',
          'part_name': pricing['part_name'],
          'cost_installation_personal': pricing['cost_installation_personal'],
          'insurance': pricing['insurance'],
          'srp': pricing['srp'],
          'id': pricing['id'],
          'message': 'Part found in thinsmith database',
        };
      }

      // If not found in thinsmith, try body paint
      pricing = await findBodyPaintPart(damagedPart);

      if (pricing != null) {
        return {
          'success': true,
          'source': 'body_paint',
          'part_name': pricing['part_name'],
          'cost_installation_personal': pricing['cost_installation_personal'],
          'srp_insurance': pricing['srp_insurance'],
          'srp_personal': pricing['srp_personal'],
          'id': pricing['id'],
          'message': 'Part found in body paint database',
        };
      }

      // Not found in either database
      return {
        'success': false,
        'source': null,
        'part_name': damagedPart,
        'cost_installation_personal': null,
        'insurance': null,
        'srp_insurance': null,
        'srp_personal': null,
        'id': null,
        'message': 'Part not found in either thinsmith or body paint database',
        'searched_in': ['thinsmith', 'body_paint'],
      };
    } catch (e) {
      return {
        'success': false,
        'source': null,
        'part_name': damagedPart,
        'cost_installation_personal': null,
        'insurance': null,
        'srp_insurance': null,
        'srp_personal': null,
        'id': null,
        'message': 'Error occurred while searching for part: $e',
        'error': e.toString(),
      };
    }
  }

  // Get only repair pricing data (from thinsmith)
  static Future<Map<String, dynamic>> getRepairPricingOnly(
    String damagedPart,
  ) async {
    try {
      Map<String, dynamic>? repairData = await findThinsmithPart(damagedPart);

      if (repairData != null) {
        return {
          'success': true,
          'source': 'thinsmith',
          'part_name': repairData['part_name'],
          'cost_installation_personal':
              repairData['cost_installation_personal'],
          'insurance': repairData['insurance'],
          'srp': repairData['srp'],
          'id': repairData['id'],
          'message': 'Repair pricing available from thinsmith database',
        };
      } else {
        return {
          'success': false,
          'source': 'thinsmith',
          'part_name': damagedPart,
          'cost_installation_personal': null,
          'insurance': null,
          'srp': null,
          'id': null,
          'message': 'Repair pricing not found in thinsmith database',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'source': 'thinsmith',
        'part_name': damagedPart,
        'cost_installation_personal': null,
        'insurance': null,
        'srp': null,
        'id': null,
        'message': 'Error occurred while searching thinsmith: $e',
        'error': e.toString(),
      };
    }
  }

  // Get only replace pricing data (from body-paint)
  static Future<Map<String, dynamic>> getReplacePricingOnly(
    String damagedPart,
  ) async {
    try {
      Map<String, dynamic>? replaceData = await findBodyPaintPart(damagedPart);

      if (replaceData != null) {
        return {
          'success': true,
          'source': 'body_paint',
          'part_name': replaceData['part_name'],
          'cost_installation_personal':
              replaceData['cost_installation_personal'],
          'srp_insurance': replaceData['srp_insurance'],
          'srp_personal': replaceData['srp_personal'],
          'id': replaceData['id'],
          'message': 'Replace pricing available from body-paint database',
        };
      } else {
        return {
          'success': false,
          'source': 'body_paint',
          'part_name': damagedPart,
          'cost_installation_personal': null,
          'srp_insurance': null,
          'srp_personal': null,
          'id': null,
          'message': 'Replace pricing not found in body-paint database',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'source': 'body_paint',
        'part_name': damagedPart,
        'cost_installation_personal': null,
        'srp_insurance': null,
        'srp_personal': null,
        'id': null,
        'message': 'Error occurred while searching body-paint: $e',
        'error': e.toString(),
      };
    }
  }

  // Get pricing for a damaged part (checks both thinsmith and body paint)
  static Future<Map<String, dynamic>?> getPricingForDamagedPart(
    String damagedPart,
  ) async {
    final result = await getPricingForDamagedPartWithDetails(damagedPart);
    return result['success'] == true ? result : null;
  }

  // Check if part exists in specific database for replace option
  static Future<Map<String, dynamic>> checkPartAvailabilityForReplace(
    String damagedPart,
  ) async {
    try {
      // For replace option, we need body paint data (for painting the new part)
      final bodyPaintPart = await findBodyPaintPart(damagedPart);
      final thinsmithPart = await findThinsmithPart(damagedPart);

      return {
        'has_body_paint': bodyPaintPart != null,
        'has_thinsmith': thinsmithPart != null,
        'body_paint_data': bodyPaintPart,
        'thinsmith_data': thinsmithPart,
        'replace_recommendation': _getReplaceRecommendation(
          bodyPaintPart,
          thinsmithPart,
          damagedPart,
        ),
      };
    } catch (e) {
      return {
        'has_body_paint': false,
        'has_thinsmith': false,
        'body_paint_data': null,
        'thinsmith_data': null,
        'replace_recommendation': 'Error checking part availability: $e',
        'error': e.toString(),
      };
    }
  }

  // Helper method to provide replace recommendations
  static String _getReplaceRecommendation(
    Map<String, dynamic>? bodyPaintPart,
    Map<String, dynamic>? thinsmithPart,
    String partName,
  ) {
    if (bodyPaintPart != null && thinsmithPart != null) {
      return 'Complete replacement pricing available (part + paint)';
    } else if (thinsmithPart != null && bodyPaintPart == null) {
      return 'Part replacement available, but paint pricing not found. Using estimated paint costs.';
    } else if (bodyPaintPart != null && thinsmithPart == null) {
      return 'Paint pricing available, but part pricing not found. Using estimated part costs.';
    } else {
      return 'Neither part nor paint pricing found for "$partName". Using estimated costs for replacement.';
    }
  }

  // Get pricing for multiple damaged parts
  static Future<List<Map<String, dynamic>>> getPricingForMultipleParts(
    List<String> damagedParts,
  ) async {
    List<Map<String, dynamic>> pricingResults = [];

    for (String part in damagedParts) {
      final pricing = await getPricingForDamagedPart(part);
      if (pricing != null) {
        pricingResults.add(pricing);
      }
    }

    return pricingResults;
  }

  // Get total estimated cost for all damaged parts
  static Future<Map<String, dynamic>> getTotalEstimatedCost(
    List<String> damagedParts,
  ) async {
    final pricingResults = await getPricingForMultipleParts(damagedParts);

    double totalLaborFee = 0.0;
    double totalInsurance = 0.0;
    double totalSrpInsurance = 0.0;
    double totalSrpPersonal = 0.0;

    for (final pricing in pricingResults) {
      totalLaborFee +=
          (pricing['cost_installation_personal'] as num?)?.toDouble() ?? 0.0;
      totalInsurance += (pricing['insurance'] as num?)?.toDouble() ?? 0.0;
      totalSrpInsurance +=
          (pricing['srp_insurance'] as num?)?.toDouble() ?? 0.0;
      totalSrpPersonal += (pricing['srp_personal'] as num?)?.toDouble() ?? 0.0;
    }

    return {
      'total_labor_fee': totalLaborFee,
      'total_insurance': totalInsurance,
      'total_srp_insurance': totalSrpInsurance,
      'total_srp_personal': totalSrpPersonal,
      'parts_found': pricingResults.length,
      'parts_requested': damagedParts.length,
      'detailed_pricing': pricingResults,
    };
  }

  // Check API health
  static Future<bool> checkApiHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
