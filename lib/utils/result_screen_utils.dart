import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:insurevis/global_ui_variables.dart';

class ResultScreenUtils {
  // Currency formatter using Philippine peso
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
  );

  /// Format amount as currency
  static String formatCurrency(double amount) {
    try {
      return _currencyFormatter.format(amount);
    } catch (e) {
      return '₱${amount.toStringAsFixed(2)}';
    }
  }

  /// Capitalize first letter of a string
  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Get color based on severity level
  static Color getSeverityColor(String severity) {
    final lowerSeverity = severity.toLowerCase();
    if (lowerSeverity.contains('high') || lowerSeverity.contains('severe')) {
      return GlobalStyles.errorMain;
    } else if (lowerSeverity.contains('medium') ||
        lowerSeverity.contains('moderate')) {
      return GlobalStyles.warningMain;
    } else if (lowerSeverity.contains('low') ||
        lowerSeverity.contains('minor')) {
      return GlobalStyles.successMain;
    } else {
      return GlobalStyles.infoMain; // Default color for unknown severity
    }
  }

  /// Check if field should be displayed
  static bool shouldShowField(String fieldName) {
    final lowerField = fieldName.toLowerCase();
    // Only show damage_type and damaged_part
    return lowerField == 'damage_type' || lowerField == 'damaged_part';
  }

  /// Format field name for display
  static String formatFieldName(String fieldName) {
    final words = fieldName.split('_');
    final formattedWords =
        words
            .map(
              (word) =>
                  word.isNotEmpty
                      ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                      : '',
            )
            .toList();
    return formattedWords.join(' ');
  }

  /// Format value based on field name and content
  static String formatValue(String fieldName, dynamic value) {
    if (value == null) return "N/A";
    if (value is bool) return value ? "Yes" : "No";

    // Special handling for damage_type - only show class_name
    final lowerField = fieldName.toLowerCase();
    if (lowerField.contains('damage_type') && value is Map) {
      final mapValue = value as Map<String, dynamic>;
      return mapValue.containsKey('class_name')
          ? mapValue['class_name'].toString()
          : value.toString();
    }

    // Format cost values with peso sign and 2 decimal places
    if (lowerField.contains('cost')) {
      if (value is num) {
        return formatCurrency(value.toDouble());
      } else {
        try {
          final numValue = double.parse(value.toString());
          return formatCurrency(numValue);
        } catch (e) {
          return value.toString();
        }
      }
    }

    // General number formatting for non-cost values
    if (value is num) {
      return value % 1 == 0
          ? value.toInt().toString()
          : value.toStringAsFixed(2);
    }

    return value.toString();
  }

  /// Extract damage information from API response
  static ProcessedDamageData extractDamageInfo(
    Map<String, dynamic> resultData,
  ) {
    dynamic damageInfo = 'No damage information available';

    if (resultData.containsKey('prediction')) {
      damageInfo = resultData['prediction'];
    } else if (resultData.containsKey('damages')) {
      damageInfo = resultData['damages'];
    } else if (resultData.containsKey('damage')) {
      damageInfo = resultData['damage'];
    } else if (resultData.containsKey('result')) {
      damageInfo = resultData['result'];
    }

    return ProcessedDamageData(damageInfo: damageInfo);
  }

  /// Extract cost estimate from API response
  static ProcessedCostData extractCostEstimate(
    Map<String, dynamic> resultData,
  ) {
    String costEstimate = 'Estimate not available';
    bool hasCost = false;

    if (resultData.containsKey('cost_estimate')) {
      costEstimate = formatCurrency(
        double.parse(resultData['cost_estimate'].toString()),
      );
      hasCost = true;
    } else if (resultData.containsKey('total_cost')) {
      costEstimate = formatCurrency(
        double.parse(resultData['total_cost'].toString()),
      );
      hasCost = true;
    } else if (resultData.containsKey('estimate')) {
      costEstimate = formatCurrency(
        double.parse(resultData['estimate'].toString()),
      );
      hasCost = true;
    }

    // Format cost to have proper peso sign and commas
    if (hasCost) {
      try {
        final costValue = double.parse(
          costEstimate.replaceAll('₱', '').replaceAll(',', ''),
        );
        costEstimate = formatCurrency(costValue);
      } catch (e) {
        // Keep original format if parsing fails
      }
    }

    return ProcessedCostData(costEstimate: costEstimate, hasCost: hasCost);
  }

  /// Extract overall severity from API response
  static String extractOverallSeverity(Map<String, dynamic> resultData) {
    if (resultData.containsKey('overall_severity')) {
      return capitalizeFirst(resultData['overall_severity'].toString());
    }
    return "Unknown";
  }

  /// Process API response and extract all data
  static ProcessedApiData processApiResponse(String response) {
    try {
      final resultData = json.decode(response);

      final damageData = extractDamageInfo(resultData);
      final costData = extractCostEstimate(resultData);
      final overallSeverity = extractOverallSeverity(resultData);

      return ProcessedApiData(
        resultData: resultData,
        damageInfo: damageData.damageInfo,
        costEstimate: costData.costEstimate,
        hasCost: costData.hasCost,
        overallSeverity: overallSeverity,
      );
    } catch (e) {
      return ProcessedApiData(
        resultData: null,
        damageInfo: 'Error processing response',
        costEstimate: 'Estimate not available',
        hasCost: false,
        overallSeverity: 'Unknown',
      );
    }
  }
}

/// Data class for processed damage information
class ProcessedDamageData {
  final dynamic damageInfo;

  ProcessedDamageData({required this.damageInfo});
}

/// Data class for processed cost information
class ProcessedCostData {
  final String costEstimate;
  final bool hasCost;

  ProcessedCostData({required this.costEstimate, required this.hasCost});
}

/// Data class for processed API response
class ProcessedApiData {
  final Map<String, dynamic>? resultData;
  final dynamic damageInfo;
  final String costEstimate;
  final bool hasCost;
  final String overallSeverity;

  ProcessedApiData({
    required this.resultData,
    required this.damageInfo,
    required this.costEstimate,
    required this.hasCost,
    required this.overallSeverity,
  });
}
