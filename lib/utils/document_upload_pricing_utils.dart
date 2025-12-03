import 'package:flutter/material.dart';
import 'package:insurevis/services/prices_repository.dart';

/// Utility class for pricing calculations and data fetching
class DocumentUploadPricingUtils {
  /// Formats damaged part name to match API requirements
  static String formatDamagedPartForApi(String partName) {
    if (partName.isEmpty) return partName;

    // Replace hyphens with spaces and handle common variations
    String formatted =
        partName.replaceAll('-', ' ').replaceAll('_', ' ').trim();

    // Convert to title case (first letter of each word capitalized)
    List<String> words = formatted.split(' ');
    List<String> capitalizedWords =
        words.map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).toList();

    return capitalizedWords.join(' ');
  }

  /// Fetches pricing data for a damaged part
  static Future<Map<String, Map<String, dynamic>?>> fetchPricingForDamage(
    String damagedPart,
  ) async {
    try {
      final formattedPartName = formatDamagedPartForApi(damagedPart);

      final bothPricingData = await PricesRepository.instance
          .getBothRepairAndReplacePricing(formattedPartName);

      return {
        'repair': bothPricingData['repair_data'],
        'replace': bothPricingData['replace_data'],
      };
    } catch (e) {
      debugPrint('Error fetching pricing for $damagedPart: $e');
      return {'repair': null, 'replace': null};
    }
  }

  /// Calculates estimated damage cost from API responses
  static double calculateEstimatedCostFromApi(
    Map<String, Map<String, dynamic>> apiResponses,
  ) {
    double totalCost = 0.0;

    for (var response in apiResponses.values) {
      if (response['total_cost'] != null) {
        totalCost += (response['total_cost'] as num).toDouble();
      } else if (response['cost_estimate'] != null) {
        totalCost += (response['cost_estimate'] as num).toDouble();
      }
    }

    return totalCost;
  }

  /// Calculates total cost from pricing data and selected options
  static double calculateTotalFromPricingData({
    required Map<int, String> selectedRepairOptions,
    required Map<int, Map<String, dynamic>?> repairPricingData,
    required Map<int, Map<String, dynamic>?> replacePricingData,
  }) {
    double total = 0.0;

    selectedRepairOptions.forEach((damageIndex, selectedOption) {
      if (selectedOption == 'repair') {
        final repairData = repairPricingData[damageIndex];
        if (repairData == null) return;

        // Prefer comprehensive total
        final repoTotal = (repairData['total_with_labor'] as num?)?.toDouble();

        if (repoTotal != null) {
          total += repoTotal;
        } else {
          // For repair: body-paint only + labor
          double bodyPaint =
              (repairData['srp_insurance'] as num?)?.toDouble() ?? 0.0;
          double labor =
              (repairData['cost_installation_personal'] as num?)?.toDouble() ??
              0.0;
          total += bodyPaint + labor;
        }
      } else if (selectedOption == 'replace') {
        final replacePricing = replacePricingData[damageIndex];
        final repairData = repairPricingData[damageIndex];
        if (replacePricing == null && repairData == null) return;

        // Prefer comprehensive total
        final repoTotalReplace =
            (replacePricing?['total_with_labor'] as num?)?.toDouble() ??
            (repairData?['total_with_labor'] as num?)?.toDouble();
        if (repoTotalReplace != null) {
          total += repoTotalReplace;
        } else {
          // For replace: thinsmith + body-paint + labor
          double thinsmith =
              (replacePricing?['insurance'] as num?)?.toDouble() ?? 0.0;
          double bodyPaint =
              (repairData?['srp_insurance'] as num?)?.toDouble() ?? 0.0;
          double labor =
              (replacePricing?['cost_installation_personal'] as num?)
                  ?.toDouble() ??
              (repairData?['cost_installation_personal'] as num?)?.toDouble() ??
              0.0;
          total += thinsmith + bodyPaint + labor;
        }
      }
    });

    return total;
  }

  /// Extracts damages list from API responses
  static List<Map<String, dynamic>> extractDamagesFromApiResponses(
    Map<String, Map<String, dynamic>> apiResponses,
  ) {
    List<Map<String, dynamic>> damagesList = [];

    if (apiResponses.isNotEmpty) {
      for (var response in apiResponses.values) {
        if (response['damages'] is List) {
          damagesList.addAll(
            (response['damages'] as List).cast<Map<String, dynamic>>(),
          );
        } else if (response['prediction'] is List) {
          damagesList.addAll(
            (response['prediction'] as List).cast<Map<String, dynamic>>(),
          );
        }
      }
    }

    return damagesList;
  }

  /// Gets pricing summary for a specific option
  static Map<String, double> getPricingSummary({
    required String option,
    required Map<String, dynamic>? repairPricing,
    required Map<String, dynamic>? replacePricing,
  }) {
    double laborFee = 0.0;
    double finalPrice = 0.0;
    double bodyPaintPrice = 0.0;
    double thinsmithPrice = 0.0;

    if (option == 'replace') {
      thinsmithPrice =
          (replacePricing?['insurance'] as num?)?.toDouble() ?? 0.0;
      laborFee =
          (replacePricing?['cost_installation_personal'] as num?)?.toDouble() ??
          (repairPricing?['cost_installation_personal'] as num?)?.toDouble() ??
          0.0;
      if (repairPricing != null) {
        bodyPaintPrice =
            (repairPricing['srp_insurance'] as num?)?.toDouble() ?? 0.0;
      }
      finalPrice = thinsmithPrice + bodyPaintPrice;
    } else {
      laborFee =
          (repairPricing?['cost_installation_personal'] as num?)?.toDouble() ??
          0.0;
      bodyPaintPrice =
          (repairPricing?['srp_insurance'] as num?)?.toDouble() ?? 0.0;
      finalPrice = bodyPaintPrice;
    }

    return {
      'laborFee': laborFee,
      'bodyPaintPrice': bodyPaintPrice,
      'thinsmithPrice': thinsmithPrice,
      'finalPrice': finalPrice,
      'totalWithLabor': finalPrice + laborFee,
    };
  }

  /// Checks if any damage is severe
  static bool isDamageSevere(Map<String, Map<String, dynamic>> apiResponses) {
    return apiResponses.values.any((response) {
      final severity = response['overall_severity']?.toString().toLowerCase();
      return severity == 'severe';
    });
  }
}
