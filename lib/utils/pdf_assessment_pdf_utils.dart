import 'package:insurevis/utils/pdf_service.dart';
import 'package:insurevis/utils/pdf_assessment_handler_utils.dart';

/// Handles PDF generation logic for assessment reports
class PDFAssessmentPDFUtils {
  /// Build PDF responses map with damage costs
  static Map<String, Map<String, dynamic>> buildPDFResponses({
    required Map<String, Map<String, dynamic>>? apiResponses,
    required PDFAssessmentHandler handler,
    required bool isDamageSevere,
  }) {
    final Map<String, Map<String, dynamic>> pdfResponses = {};
    final responses = apiResponses ?? <String, Map<String, dynamic>>{};

    // Process API responses
    responses.forEach((imagePath, response) {
      final copiedResponse = Map<String, dynamic>.from(response);
      final damageIndices = handler.imageToDamageIndices[imagePath] ?? [];

      if (copiedResponse['damages'] is List) {
        final damages = copiedResponse['damages'] as List;
        final updatedDamages = <Map<String, dynamic>>[];

        for (int i = 0; i < damages.length; i++) {
          final damage =
              damages[i] is Map<String, dynamic>
                  ? Map<String, dynamic>.from(damages[i])
                  : {'type': damages[i].toString()};

          final globalDamageIndex =
              i < damageIndices.length ? damageIndices[i] : -1;

          if (globalDamageIndex >= 0) {
            final selectedOption =
                handler.selectedRepairOptions[globalDamageIndex];
            double damageCost = PDFAssessmentPDFUtils._calculateDamageCost(
              handler,
              globalDamageIndex,
              selectedOption,
            );

            if (damageCost > 0.0) {
              damage['cost'] = handler.formatCurrency(damageCost);
            }

            if (selectedOption != null) {
              damage['action'] = handler.capitalizeOption(selectedOption);
              damage['recommended_action'] = handler.capitalizeOption(
                selectedOption,
              );
            }
          }

          updatedDamages.add(damage);
        }

        copiedResponse['damages'] = updatedDamages;
      }

      pdfResponses[imagePath] = copiedResponse;
    });

    // Add manual damages
    if (handler.manualDamages.isNotEmpty) {
      final manualDamagesForPdf =
          PDFAssessmentPDFUtils._buildManualDamagesForPDF(handler);
      final manualTotalCost =
          PDFAssessmentPDFUtils._calculateManualDamagesTotalCost(handler);

      pdfResponses['manual_report_1'] = {
        'overall_severity': 'Manual Assessment',
        'damages': manualDamagesForPdf,
        'total_cost': handler.formatCurrency(manualTotalCost),
      };
    }

    // Fill missing costs
    PDFAssessmentPDFUtils._fillMissingCosts(
      pdfResponses,
      handler,
      isDamageSevere,
    );

    return pdfResponses;
  }

  static double _calculateDamageCost(
    PDFAssessmentHandler handler,
    int globalDamageIndex,
    String? selectedOption,
  ) {
    double damageCost = 0.0;

    if (selectedOption == 'repair') {
      final repairData = handler.repairPricingData[globalDamageIndex];
      if (repairData != null) {
        final repoTotal = (repairData['total_with_labor'] as num?)?.toDouble();
        if (repoTotal != null) {
          damageCost = repoTotal;
        } else {
          final double bodyPaint =
              (repairData['srp_insurance'] as num?)?.toDouble() ?? 0.0;
          final double labor =
              (repairData['cost_installation_personal'] as num?)?.toDouble() ??
              0.0;
          damageCost = bodyPaint + labor;
        }
      }
    } else if (selectedOption == 'replace') {
      final replacePricing = handler.replacePricingData[globalDamageIndex];
      final repairData = handler.repairPricingData[globalDamageIndex];
      if (replacePricing != null || repairData != null) {
        final repoTotal =
            (replacePricing?['total_with_labor'] as num?)?.toDouble() ??
            (repairData?['total_with_labor'] as num?)?.toDouble();
        if (repoTotal != null) {
          damageCost = repoTotal;
        } else {
          final double thinsmith =
              (replacePricing?['insurance'] as num?)?.toDouble() ?? 0.0;
          final double bodyPaint =
              (repairData?['srp_insurance'] as num?)?.toDouble() ?? 0.0;
          final double labor =
              (replacePricing?['cost_installation_personal'] as num?)
                  ?.toDouble() ??
              (repairData?['cost_installation_personal'] as num?)?.toDouble() ??
              0.0;
          damageCost = thinsmith + bodyPaint + labor;
        }
      }
    }

    return damageCost;
  }

  static List<Map<String, dynamic>> _buildManualDamagesForPDF(
    PDFAssessmentHandler handler,
  ) {
    List<Map<String, dynamic>> manualDamagesForPdf = [];

    for (int i = 0; i < handler.manualDamages.length; i++) {
      final m = handler.manualDamages[i];
      final globalIndex = -(i + 1);
      final selectedOption = handler.selectedRepairOptions[globalIndex];

      double damageCost = PDFAssessmentPDFUtils._calculateDamageCost(
        handler,
        globalIndex,
        selectedOption,
      );

      final damageMap = <String, dynamic>{
        'type': m['damaged_part'],
        'damaged_part': m['damaged_part'],
        'severity': '',
      };

      if (damageCost > 0.0) {
        damageMap['cost'] = handler.formatCurrency(damageCost);
      }

      if (selectedOption != null) {
        damageMap['action'] = handler.capitalizeOption(selectedOption);
        damageMap['recommended_action'] = handler.capitalizeOption(
          selectedOption,
        );
      }

      manualDamagesForPdf.add(damageMap);
    }

    return manualDamagesForPdf;
  }

  static double _calculateManualDamagesTotalCost(PDFAssessmentHandler handler) {
    double manualDamagesTotalCost = 0.0;

    for (int i = 0; i < handler.manualDamages.length; i++) {
      final globalIndex = -(i + 1);
      final selectedOption = handler.selectedRepairOptions[globalIndex];
      manualDamagesTotalCost += PDFAssessmentPDFUtils._calculateDamageCost(
        handler,
        globalIndex,
        selectedOption,
      );
    }

    return manualDamagesTotalCost;
  }

  static void _fillMissingCosts(
    Map<String, Map<String, dynamic>> pdfResponses,
    PDFAssessmentHandler handler,
    bool isDamageSevere,
  ) {
    if (!isDamageSevere && pdfResponses.isNotEmpty) {
      double totalToUse =
          handler.estimatedDamageCost > 0
              ? handler.estimatedDamageCost
              : handler.calculateTotalFromPricingData();

      if (totalToUse <= 0) {
        double existingSum = 0.0;
        pdfResponses.forEach((k, v) {
          existingSum += handler.parseToDouble(v['total_cost']);
        });
        if (existingSum > 0) totalToUse = existingSum;
      }

      final missingKeys =
          pdfResponses.keys.where((k) {
            final val = pdfResponses[k]?['total_cost'];
            if (val == null) return true;
            final s = val.toString().toLowerCase();
            if (s.isEmpty) return true;
            if (s.contains('n/a')) return true;
            if (handler.parseToDouble(val) == 0.0) return true;
            return false;
          }).toList();

      if (missingKeys.isNotEmpty) {
        for (final k in missingKeys) {
          double costForThisEntry = 0.0;

          if (handler.imageToDamageIndices.containsKey(k)) {
            costForThisEntry = handler.calculateCostForImage(k);
          } else if (k == 'manual_report_1') {
            costForThisEntry = handler.calculateTotalFromPricingData();
          }

          final formatted =
              costForThisEntry > 0
                  ? handler.formatCurrency(costForThisEntry)
                  : 'N/A';
          pdfResponses[k]!['total_cost'] = formatted;
        }
      }
    }

    if (isDamageSevere) {
      pdfResponses.forEach((key, value) {
        value['total_cost'] = 'To be given by the mechanic';
      });
    }
  }

  /// Generate temporary PDF for job estimate
  static Future<String?> generateTemporaryPDF({
    required List<String>? imagePaths,
    required Map<String, Map<String, dynamic>>? apiResponses,
    required PDFAssessmentHandler handler,
    required bool isDamageSevere,
  }) async {
    try {
      final pdfResponses = buildPDFResponses(
        apiResponses: apiResponses,
        handler: handler,
        isDamageSevere: isDamageSevere,
      );

      return await PDFService.generateTemporaryPDF(
        imagePaths: imagePaths ?? [],
        apiResponses: pdfResponses,
      );
    } catch (e) {
      print('Error generating temporary PDF: $e');
      return null;
    }
  }
}
