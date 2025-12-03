import 'dart:io';
import 'package:insurevis/services/prices_repository.dart';
import 'package:intl/intl.dart';

/// Handles business logic for PDF assessment view
class PDFAssessmentHandler {
  // Map to track which damage indices belong to which image path
  final Map<String, List<int>> imageToDamageIndices = {};

  // Repair options and pricing data
  final Map<int, String?> selectedRepairOptions = {};
  final Map<int, Map<String, dynamic>?> repairPricingData = {};
  final Map<int, Map<String, dynamic>?> replacePricingData = {};
  final Map<int, bool> isLoadingPricing = {};

  // Manual damages
  final List<Map<String, String>> manualDamages = [];

  double estimatedDamageCost = 0.0;

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
  );

  String formatCurrency(double amount) {
    try {
      if (amount == 0.0) return 'N/A';
      return _currencyFormatter.format(amount);
    } catch (e) {
      if (amount == 0.0) return 'N/A';
      return '₱${amount.toStringAsFixed(2)}';
    }
  }

  String capitalizeOption(String option) {
    if (option.isEmpty) return option;
    return option[0].toUpperCase() + option.substring(1);
  }

  String formatDamagedPartForApi(String partName) {
    if (partName.isEmpty) return partName;
    String formatted =
        partName.replaceAll('-', ' ').replaceAll('_', ' ').trim();
    List<String> words = formatted.split(' ');
    List<String> capitalizedWords =
        words.map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).toList();
    return capitalizedWords.join(' ');
  }

  String formatLabel(String raw) {
    if (raw.isEmpty) return raw;
    String formatted = raw.replaceAll('-', ' ').replaceAll('_', ' ').trim();
    final words = formatted.split(' ');
    return words
        .map(
          (w) =>
              w.isEmpty
                  ? w
                  : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  double parseToDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) {
      final sanitized = val.replaceAll(RegExp(r"[^0-9.\-]"), '');
      return double.tryParse(sanitized) ?? 0.0;
    }
    return 0.0;
  }

  bool isDamageSevere(Map<String, Map<String, dynamic>>? apiResponses) {
    final responses = apiResponses ?? <String, Map<String, dynamic>>{};
    return responses.values.any((response) {
      final severity = response['overall_severity']?.toString().toLowerCase();
      return severity == 'severe';
    });
  }

  void initializeRepairOptions(
    Map<String, Map<String, dynamic>>? apiResponses,
  ) {
    List<Map<String, dynamic>> damagesList = [];
    final responses = apiResponses ?? <String, Map<String, dynamic>>{};

    if (responses.isNotEmpty) {
      int globalDamageIndex = 0;
      for (var entry in responses.entries) {
        final imagePath = entry.key;
        final response = entry.value;

        List<Map<String, dynamic>> imageDamages = [];
        if (response['damages'] is List) {
          imageDamages =
              (response['damages'] as List).cast<Map<String, dynamic>>();
        } else if (response['prediction'] is List) {
          imageDamages =
              (response['prediction'] as List).cast<Map<String, dynamic>>();
        }

        List<int> damageIndicesForImage = [];
        for (var damage in imageDamages) {
          damageIndicesForImage.add(globalDamageIndex);
          damagesList.add(damage);
          globalDamageIndex++;
        }
        imageToDamageIndices[imagePath] = damageIndicesForImage;
      }
    }

    for (var entry in damagesList.asMap().entries) {
      final idx = entry.key;
      selectedRepairOptions[idx] = 'repair';
    }
  }

  Future<void> fetchPricingForDamage(
    int damageIndex,
    String damagedPart,
    String selectedOption,
  ) async {
    isLoadingPricing[damageIndex] = true;
    try {
      final formattedPartName = formatDamagedPartForApi(damagedPart);
      final bothPricingData = await PricesRepository.instance
          .getBothRepairAndReplacePricing(formattedPartName);

      repairPricingData[damageIndex] = bothPricingData['repair_data'];
      replacePricingData[damageIndex] = bothPricingData['replace_data'];
      isLoadingPricing[damageIndex] = false;
    } catch (e) {
      repairPricingData[damageIndex] = null;
      replacePricingData[damageIndex] = null;
      isLoadingPricing[damageIndex] = false;
    }
  }

  void calculateEstimatedDamageCost(
    Map<String, Map<String, dynamic>>? apiResponses,
  ) {
    double apiTotal = 0.0;
    final responses = apiResponses ?? <String, Map<String, dynamic>>{};

    for (var response in responses.values) {
      if (response['total_cost'] != null) {
        apiTotal += parseToDouble(response['total_cost']);
      } else if (response['cost_estimate'] != null) {
        apiTotal += parseToDouble(response['cost_estimate']);
      }
    }

    final pricingTotal = calculateTotalFromPricingData();
    final totalCost = (pricingTotal > 0.0) ? pricingTotal : apiTotal;
    estimatedDamageCost = totalCost;
  }

  double calculateTotalFromPricingData() {
    double total = 0.0;
    for (final entry in selectedRepairOptions.entries) {
      final int damageIndex = entry.key;
      final String? selectedOption = entry.value;
      if (selectedOption == null) continue;

      if (selectedOption == 'repair') {
        final repairData = repairPricingData[damageIndex];
        if (repairData == null) continue;

        final repoTotal = (repairData['total_with_labor'] as num?)?.toDouble();
        if (repoTotal != null) {
          total += repoTotal;
          continue;
        }

        final double bodyPaint =
            (repairData['srp_insurance'] as num?)?.toDouble() ?? 0.0;
        final double labor =
            (repairData['cost_installation_personal'] as num?)?.toDouble() ??
            0.0;
        total += (bodyPaint + labor);
      } else if (selectedOption == 'replace') {
        final replacePricing = replacePricingData[damageIndex];
        final repairData = repairPricingData[damageIndex];
        if (replacePricing == null && repairData == null) continue;

        final repoTotal =
            (replacePricing?['total_with_labor'] as num?)?.toDouble() ??
            (repairData?['total_with_labor'] as num?)?.toDouble();
        if (repoTotal != null) {
          total += repoTotal;
          continue;
        }

        final double thinsmith =
            (replacePricing?['insurance'] as num?)?.toDouble() ?? 0.0;
        final double bodyPaint =
            (repairData?['srp_insurance'] as num?)?.toDouble() ?? 0.0;
        final double labor =
            (replacePricing?['cost_installation_personal'] as num?)
                ?.toDouble() ??
            (repairData?['cost_installation_personal'] as num?)?.toDouble() ??
            0.0;
        total += (thinsmith + bodyPaint + labor);
      }
    }
    return total;
  }

  double calculateCostForImage(String imagePath) {
    double total = 0.0;
    final damageIndices = imageToDamageIndices[imagePath] ?? [];

    for (final damageIndex in damageIndices) {
      final selectedOption = selectedRepairOptions[damageIndex];
      if (selectedOption == null) continue;

      if (selectedOption == 'repair') {
        final repairData = repairPricingData[damageIndex];
        if (repairData == null) continue;

        final repoTotal = (repairData['total_with_labor'] as num?)?.toDouble();
        if (repoTotal != null) {
          total += repoTotal;
          continue;
        }

        final double bodyPaint =
            (repairData['srp_insurance'] as num?)?.toDouble() ?? 0.0;
        final double labor =
            (repairData['cost_installation_personal'] as num?)?.toDouble() ??
            0.0;
        total += (bodyPaint + labor);
      } else if (selectedOption == 'replace') {
        final replacePricing = replacePricingData[damageIndex];
        final repairData = repairPricingData[damageIndex];
        if (replacePricing == null && repairData == null) continue;

        final repoTotal =
            (replacePricing?['total_with_labor'] as num?)?.toDouble() ??
            (repairData?['total_with_labor'] as num?)?.toDouble();
        if (repoTotal != null) {
          total += repoTotal;
          continue;
        }

        final double thinsmith =
            (replacePricing?['insurance'] as num?)?.toDouble() ?? 0.0;
        final double bodyPaint =
            (repairData?['srp_insurance'] as num?)?.toDouble() ?? 0.0;
        final double labor =
            (replacePricing?['cost_installation_personal'] as num?)
                ?.toDouble() ??
            (repairData?['cost_installation_personal'] as num?)?.toDouble() ??
            0.0;
        total += (thinsmith + bodyPaint + labor);
      }
    }
    return total;
  }

  bool hasValidPricingData(Map<String, dynamic> pricingData, String option) {
    if (option == 'repair') {
      final bodyPaintPrice = pricingData['srp_insurance'];
      return bodyPaintPrice != null && bodyPaintPrice != 0;
    } else if (option == 'replace') {
      final thinsmithPrice = pricingData['insurance'];
      return thinsmithPrice != null && thinsmithPrice != 0;
    }
    return false;
  }

  void addManualDamage(String part, String type) {
    manualDamages.add({'damaged_part': part, 'damage_type': type});
  }

  void removeManualDamage(int displayedIndex) {
    if (displayedIndex >= 0 && displayedIndex < manualDamages.length) {
      manualDamages.removeAt(displayedIndex);
    }
  }

  int getTotalDamagesCount(Map<String, Map<String, dynamic>>? apiResponses) {
    int totalDamages = 0;
    final responses = apiResponses ?? <String, Map<String, dynamic>>{};

    for (var response in responses.values) {
      if (response['damages'] is List) {
        totalDamages += (response['damages'] as List).length;
      } else if (response['prediction'] is List) {
        totalDamages += (response['prediction'] as List).length;
      }
    }

    totalDamages += manualDamages.length;
    return totalDamages;
  }

  Map<String, int> getSeverityCounts(
    Map<String, Map<String, dynamic>>? apiResponses,
  ) {
    Map<String, int> severityCount = {'High': 0, 'Medium': 0, 'Low': 0};
    final responses = apiResponses ?? <String, Map<String, dynamic>>{};

    responses.forEach((imagePath, response) {
      if (response.containsKey('overall_severity')) {
        String severity = response['overall_severity'].toString();
        if (severity.toLowerCase().contains('high') ||
            severity.toLowerCase().contains('severe')) {
          severityCount['High'] = (severityCount['High'] ?? 0) + 1;
        } else if (severity.toLowerCase().contains('medium')) {
          severityCount['Medium'] = (severityCount['Medium'] ?? 0) + 1;
        } else {
          severityCount['Low'] = (severityCount['Low'] ?? 0) + 1;
        }
      }
    });

    return severityCount;
  }

  String extractDamagedPart(Map<String, dynamic> damage) {
    if (damage.containsKey('damaged_part')) {
      return damage['damaged_part']?.toString() ?? 'Unknown Part';
    } else if (damage.containsKey('part_name')) {
      return damage['part_name']?.toString() ?? 'Unknown Part';
    } else if (damage.containsKey('label')) {
      return damage['label']?.toString() ?? 'Unknown Part';
    }
    return 'Unknown Part';
  }

  String extractDamageType(Map<String, dynamic> damage) {
    if (damage.containsKey('damage_type')) {
      final damageTypeValue = damage['damage_type'];
      if (damageTypeValue is Map && damageTypeValue.containsKey('class_name')) {
        return damageTypeValue['class_name']?.toString() ?? 'Unknown Damage';
      } else {
        return damageTypeValue?.toString() ?? 'Unknown Damage';
      }
    }
    return 'Unknown Damage';
  }
}
