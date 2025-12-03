import 'dart:io';
import 'package:flutter/material.dart';

/// Utility class for document upload validation logic
class DocumentUploadValidationUtils {
  /// Checks if all required documents have been uploaded
  static bool checkRequiredDocuments(
    Map<String, bool> requiredDocuments,
    Map<String, List<File>> uploadedDocuments,
  ) {
    for (String category in requiredDocuments.keys) {
      if (requiredDocuments[category]! &&
          uploadedDocuments[category]!.isEmpty) {
        return false;
      }
    }
    return true;
  }

  /// Checks if incident information fields are filled
  static bool checkIncidentInformation(
    TextEditingController locationController,
    TextEditingController dateController,
  ) {
    return locationController.text.trim().isNotEmpty &&
        dateController.text.trim().isNotEmpty;
  }

  /// Checks if the user has made any changes to the form
  static bool hasUserMadeChanges({
    required TextEditingController locationController,
    required TextEditingController dateController,
    required Map<String, List<File>> uploadedDocuments,
    required List<String> originalImagePaths,
    String? tempJobEstimatePdfPath,
  }) {
    // Check if incident information fields have values
    final hasIncidentInfo =
        locationController.text.trim().isNotEmpty ||
        dateController.text.trim().isNotEmpty;

    // Check if any additional documents were uploaded (excluding pre-loaded ones)
    bool hasUploadedNewDocuments = false;

    for (String category in uploadedDocuments.keys) {
      final files = uploadedDocuments[category] ?? [];

      if (category == 'damage_photos') {
        // Check if there are more photos than the original assessment images
        final additionalPhotos =
            files
                .where((file) => !originalImagePaths.contains(file.path))
                .toList();
        if (additionalPhotos.isNotEmpty) {
          hasUploadedNewDocuments = true;
          break;
        }
      } else if (category == 'job_estimate') {
        // Check if there are files other than the auto-generated PDF
        final additionalEstimates =
            files
                .where(
                  (file) =>
                      tempJobEstimatePdfPath == null ||
                      file.path != tempJobEstimatePdfPath,
                )
                .toList();
        if (additionalEstimates.isNotEmpty) {
          hasUploadedNewDocuments = true;
          break;
        }
      } else {
        // For other categories, check if any files were uploaded
        if (files.isNotEmpty) {
          hasUploadedNewDocuments = true;
          break;
        }
      }
    }

    return hasIncidentInfo || hasUploadedNewDocuments;
  }

  /// Gets missing required documents list
  static List<String> getMissingRequiredDocuments(
    Map<String, bool> requiredDocuments,
    Map<String, List<File>> uploadedDocuments,
  ) {
    return requiredDocuments.keys
        .where(
          (k) =>
              requiredDocuments[k]! && (uploadedDocuments[k]?.isEmpty ?? true),
        )
        .map((k) => documentTitleFromKey(k))
        .toList();
  }

  /// Converts document key to human-readable title
  static String documentTitleFromKey(String key) {
    switch (key) {
      case 'lto_or':
        return 'LTO O.R.';
      case 'lto_cr':
        return 'LTO C.R.';
      case 'drivers_license':
        return 'Driver\'s License';
      case 'owner_valid_id':
        return 'Owner Valid ID';
      case 'police_report':
        return 'Police Report';
      case 'insurance_policy':
        return 'Insurance Policy';
      case 'job_estimate':
        return 'Job Estimate';
      case 'damage_photos':
        return 'Damage Photos';
      case 'stencil_strips':
        return 'Stencil Strips';
      default:
        return key;
    }
  }

  /// Validates if a file can be removed
  static bool canRemoveFile({
    required String category,
    required File file,
    required List<String> originalImagePaths,
    String? tempJobEstimatePdfPath,
  }) {
    // Prevent removal of assessment images from damage_photos category
    if (category == 'damage_photos' && originalImagePaths.contains(file.path)) {
      return false;
    }

    // Prevent removal of auto-generated job estimate PDF
    if (category == 'job_estimate' &&
        tempJobEstimatePdfPath != null &&
        file.path == tempJobEstimatePdfPath) {
      return false;
    }

    return true;
  }

  /// Gets error message for why a file cannot be removed
  static String getRemovalErrorMessage({
    required String category,
    required File file,
    required List<String> originalImagePaths,
    String? tempJobEstimatePdfPath,
  }) {
    if (category == 'damage_photos' && originalImagePaths.contains(file.path)) {
      return 'Assessment images cannot be removed. They are required as damage proof.';
    }

    if (category == 'job_estimate' &&
        tempJobEstimatePdfPath != null &&
        file.path == tempJobEstimatePdfPath) {
      return 'Auto-generated job estimate cannot be removed. Please upload an additional estimate if needed.';
    }

    return 'This file cannot be removed.';
  }
}
