import 'dart:io';
import 'package:flutter/material.dart';
import 'package:insurevis/services/image_upload_service.dart';
import 'package:insurevis/providers/assessment_provider.dart';

class MultipleResultsUtils {
  /// Upload a single image to the API and return the response
  static Future<Map<String, dynamic>?> uploadImage(String imagePath) async {
    try {
      return await ImageUploadService().uploadImageFile(
        imagePath: imagePath,
        fileFieldName: 'image_file',
      );
    } catch (e) {
      return null;
    }
  }

  /// Process an image upload and create assessment
  static Future<ProcessedImageResult> processImage(
    String imagePath,
    AssessmentProvider assessmentProvider,
  ) async {
    try {
      // Upload to API
      final apiResponse = await uploadImage(imagePath);

      if (apiResponse != null) {
        // Create assessment
        final assessment = await assessmentProvider.addAssessment(imagePath);

        return ProcessedImageResult(
          status: 'success',
          assessmentId: assessment.id,
          apiResponse: apiResponse,
        );
      } else {
        return ProcessedImageResult(status: 'error');
      }
    } catch (e) {
      return ProcessedImageResult(status: 'error');
    }
  }

  /// Process multiple images sequentially
  static Future<Map<String, ProcessedImageResult>> processMultipleImages(
    List<String> imagePaths,
    AssessmentProvider assessmentProvider,
    Function(String, String) onStatusUpdate,
  ) async {
    final results = <String, ProcessedImageResult>{};

    for (final imagePath in imagePaths) {
      onStatusUpdate(imagePath, 'uploading');

      final result = await processImage(imagePath, assessmentProvider);
      results[imagePath] = result;

      onStatusUpdate(imagePath, result.status);
    }

    return results;
  }

  /// Check if any uploads are in progress
  static bool hasUploadsInProgress(Map<String, String> uploadResults) {
    return uploadResults.values.any((status) => status == 'uploading');
  }

  /// Extract severity from API response
  static String extractSeverity(Map<String, dynamic>? apiResponse) {
    if (apiResponse == null) return 'Unknown';
    if (apiResponse.containsKey('overall_severity')) {
      return capitalizeFirst(apiResponse['overall_severity'].toString());
    }
    return 'Unknown';
  }

  /// Extract cost estimate from API response
  static String extractCostEstimate(Map<String, dynamic>? apiResponse) {
    if (apiResponse == null) return 'Not available';
    if (apiResponse.containsKey('total_cost')) {
      try {
        double cost = double.parse(apiResponse['total_cost'].toString());
        return '₱${cost.toStringAsFixed(2)}';
      } catch (e) {
        return '₱${apiResponse['total_cost']}';
      }
    }
    return 'Not available';
  }

  /// Extract damages list from API response
  static List<dynamic> extractDamages(Map<String, dynamic>? apiResponse) {
    if (apiResponse == null) return [];

    if (apiResponse.containsKey('damages') && apiResponse['damages'] is List) {
      return apiResponse['damages'];
    } else if (apiResponse.containsKey('prediction') &&
        apiResponse['prediction'] is List) {
      return apiResponse['prediction'];
    }

    return [];
  }

  /// Get color based on severity level
  static Color getSeverityColor(String severity) {
    final lowerSeverity = severity.toLowerCase();
    if (lowerSeverity.contains('high') || lowerSeverity.contains('severe')) {
      return const Color(0xFFEF4444); // Red
    } else if (lowerSeverity.contains('medium') ||
        lowerSeverity.contains('moderate')) {
      return const Color(0xFFF97316); // Orange
    } else if (lowerSeverity.contains('low') ||
        lowerSeverity.contains('minor')) {
      return const Color(0xFF22C55E); // Green
    } else {
      return const Color(0xFF3B82F6); // Blue
    }
  }

  /// Get icon based on severity
  static IconData getSeverityIcon(String severity) {
    final lowerSeverity = severity.toLowerCase();
    if (lowerSeverity.contains('high') || lowerSeverity.contains('severe')) {
      return Icons.error;
    } else if (lowerSeverity.contains('medium') ||
        lowerSeverity.contains('moderate')) {
      return Icons.warning;
    } else if (lowerSeverity.contains('low') ||
        lowerSeverity.contains('minor')) {
      return Icons.info;
    } else {
      return Icons.help;
    }
  }

  /// Extract damage type from damage object
  static String extractDamageType(dynamic damage) {
    if (damage is Map<String, dynamic>) {
      return damage['type']?.toString() ??
          damage['damage_type']?.toString() ??
          'Unknown';
    } else if (damage is String) {
      return damage;
    }
    return 'Unknown';
  }

  /// Extract damage severity from damage object
  static String extractDamageSeverity(dynamic damage) {
    if (damage is Map<String, dynamic>) {
      return damage['severity']?.toString() ?? '';
    }
    return '';
  }

  /// Capitalize first letter of a string
  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Preload image file as widget for caching
  static Widget createCachedImage(String imagePath, double size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          cacheWidth: size.toInt(),
          cacheHeight: size.toInt(),
        ),
      ),
    );
  }

  /// Create a map of cached image widgets
  static Map<String, Widget> preloadImages(
    List<String> imagePaths,
    double size,
  ) {
    final cachedImages = <String, Widget>{};
    for (final imagePath in imagePaths) {
      cachedImages[imagePath] = createCachedImage(imagePath, size);
    }
    return cachedImages;
  }
}

/// Result of processing a single image
class ProcessedImageResult {
  final String status;
  final String? assessmentId;
  final Map<String, dynamic>? apiResponse;

  ProcessedImageResult({
    required this.status,
    this.assessmentId,
    this.apiResponse,
  });
}
