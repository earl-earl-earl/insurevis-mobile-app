import 'dart:io';
import 'package:flutter/material.dart';
import 'package:insurevis/services/supabase_service.dart';
import 'package:insurevis/services/claims_service.dart';
import 'package:insurevis/services/documents_service.dart';
import 'package:insurevis/models/document_model.dart';
import 'package:insurevis/utils/document_upload_pricing_utils.dart';

/// Utility class for claim submission logic
class DocumentUploadSubmissionUtils {
  /// Builds incident description from damages
  static String buildIncidentDescription({
    required Map<String, Map<String, dynamic>> apiResponses,
    required List<Map<String, String>> manualDamages,
    required Map<int, String> selectedRepairOptions,
  }) {
    List<String> descriptionLines = [];
    List<Map<String, dynamic>> allDamages = [];

    // Extract API-detected damages
    if (apiResponses.isNotEmpty) {
      for (var response in apiResponses.values) {
        List<Map<String, dynamic>> damagesList = [];
        if (response['damages'] is List) {
          damagesList.addAll(
            (response['damages'] as List).cast<Map<String, dynamic>>(),
          );
        } else if (response['prediction'] is List) {
          damagesList.addAll(
            (response['prediction'] as List).cast<Map<String, dynamic>>(),
          );
        }

        for (int i = 0; i < damagesList.length; i++) {
          final damage = damagesList[i];
          String damagedPart = 'Unknown Part';
          String damageType = 'Unknown Damage';

          if (damage.containsKey('damaged_part')) {
            damagedPart = damage['damaged_part']?.toString() ?? 'Unknown Part';
          }
          if (damage.containsKey('damage_type')) {
            final damageTypeValue = damage['damage_type'];
            if (damageTypeValue is Map &&
                damageTypeValue.containsKey('class_name')) {
              damageType =
                  damageTypeValue['class_name']?.toString() ?? 'Unknown Damage';
            } else {
              damageType = damageTypeValue?.toString() ?? 'Unknown Damage';
            }
          }

          final selectedOption = selectedRepairOptions[i] ?? 'repair';
          allDamages.add({
            'part': damagedPart,
            'type': damageType,
            'option': selectedOption,
          });
        }
      }
    }

    // Add manual damages
    for (int mi = 0; mi < manualDamages.length; mi++) {
      final manual = manualDamages[mi];
      final globalIndex = -(mi + 1);
      final damagedPart = manual['damaged_part'] ?? 'Unknown Part';
      final damageType = manual['damage_type'] ?? 'Unknown Damage';
      final selectedOption = selectedRepairOptions[globalIndex] ?? 'repair';

      allDamages.add({
        'part': damagedPart,
        'type': damageType,
        'option': selectedOption,
      });
    }

    // Build description
    if (allDamages.isNotEmpty) {
      descriptionLines.add('Total Damages: ${allDamages.length}');
      for (int i = 0; i < allDamages.length; i++) {
        final dmg = allDamages[i];
        final part = dmg['part'];
        final type = dmg['type'];
        String option = dmg['option'];
        option = option[0].toUpperCase() + option.substring(1);
        descriptionLines.add('${i + 1}. $part - $type ($option)');
      }
    }

    return descriptionLines.isNotEmpty
        ? descriptionLines.join('\n')
        : 'Vehicle damage assessment';
  }

  /// Builds damages payload for claim submission
  static List<Map<String, dynamic>> buildDamagesPayload({
    required Map<String, Map<String, dynamic>> apiResponses,
    required List<Map<String, String>> manualDamages,
    required Map<int, String> selectedRepairOptions,
    required Map<int, Map<String, dynamic>?> repairPricingData,
    required Map<int, Map<String, dynamic>?> replacePricingData,
  }) {
    List<Map<String, dynamic>> damagesPayload = [];

    // Extract API-detected damages first
    if (apiResponses.isNotEmpty) {
      for (var response in apiResponses.values) {
        List<Map<String, dynamic>> damagesList = [];
        if (response['damages'] is List) {
          damagesList.addAll(
            (response['damages'] as List).cast<Map<String, dynamic>>(),
          );
        } else if (response['prediction'] is List) {
          damagesList.addAll(
            (response['prediction'] as List).cast<Map<String, dynamic>>(),
          );
        }

        for (int i = 0; i < damagesList.length; i++) {
          final damage = damagesList[i];
          String damagedPart = 'Unknown Part';
          String damageType = 'Unknown Damage';

          if (damage.containsKey('damaged_part')) {
            damagedPart = damage['damaged_part']?.toString() ?? 'Unknown Part';
          }
          if (damage.containsKey('damage_type')) {
            final damageTypeValue = damage['damage_type'];
            if (damageTypeValue is Map &&
                damageTypeValue.containsKey('class_name')) {
              damageType =
                  damageTypeValue['class_name']?.toString() ?? 'Unknown Damage';
            } else {
              damageType = damageTypeValue?.toString() ?? 'Unknown Damage';
            }
          }

          final selectedOption = selectedRepairOptions[i] ?? 'repair';
          final bodyPaintPricing = repairPricingData[i];
          final thinsmithPricing = replacePricingData[i];

          double? repairInsurance =
              bodyPaintPricing != null
                  ? (bodyPaintPricing['srp_insurance'] as num?)?.toDouble()
                  : null;
          double? replaceInsurance =
              thinsmithPricing != null
                  ? (thinsmithPricing['insurance'] as num?)?.toDouble()
                  : null;

          damagesPayload.add({
            'damaged_part': DocumentUploadPricingUtils.formatDamagedPartForApi(
              damagedPart,
            ),
            'damage_type': damageType,
            'selected_option': selectedOption,
            'pricing': {
              'repair_insurance': repairInsurance,
              'replace_insurance': replaceInsurance,
            },
          });
        }
      }
    }

    // Add manual damages
    for (int mi = 0; mi < manualDamages.length; mi++) {
      final manual = manualDamages[mi];
      final globalIndex = -(mi + 1);
      final damagedPart = manual['damaged_part'] ?? 'Unknown Part';
      final damageType = manual['damage_type'] ?? 'Unknown Damage';
      final selectedOption = selectedRepairOptions[globalIndex] ?? 'repair';

      final bodyPaintPricing = repairPricingData[globalIndex];
      final thinsmithPricing = replacePricingData[globalIndex];

      double? repairInsurance =
          thinsmithPricing != null
              ? (thinsmithPricing['insurance'] as num?)?.toDouble()
              : null;
      double? replaceInsurance =
          bodyPaintPricing != null
              ? (bodyPaintPricing['srp_insurance'] as num?)?.toDouble()
              : null;

      damagesPayload.add({
        'damaged_part': DocumentUploadPricingUtils.formatDamagedPartForApi(
          damagedPart,
        ),
        'damage_type': damageType,
        'selected_option': selectedOption,
        'pricing': {
          'repair_insurance': repairInsurance,
          'replace_insurance': replaceInsurance,
        },
      });
    }

    return damagesPayload;
  }

  /// Parses incident date from text input
  static DateTime parseIncidentDate(String dateText) {
    try {
      if (dateText.trim().isNotEmpty) {
        final dateParts = dateText.split('/');
        if (dateParts.length == 3) {
          final month = int.parse(dateParts[0]);
          final day = int.parse(dateParts[1]);
          final year = int.parse(dateParts[2]);
          return DateTime(year, month, day);
        }
      }
    } catch (e) {
      debugPrint('Error parsing incident date: $e');
    }
    // Default to yesterday if parsing fails
    return DateTime.now().subtract(const Duration(days: 1));
  }

  /// Submits claim with documents
  static Future<Map<String, dynamic>> submitClaimWithDocuments({
    required String incidentLocation,
    required String incidentDate,
    required String incidentDescription,
    required Map<String, String>? vehicleData,
    required double estimatedDamageCost,
    required List<Map<String, dynamic>> damagesPayload,
    required Map<String, List<File>> uploadedDocuments,
  }) async {
    // Get current user
    final currentUser = SupabaseService.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    // Parse incident date
    final parsedIncidentDate = parseIncidentDate(incidentDate);

    // Create claim using ClaimsService
    final claim = await ClaimsService.createClaim(
      userId: currentUser.id,
      incidentDate: parsedIncidentDate,
      incidentLocation:
          incidentLocation.trim().isNotEmpty
              ? incidentLocation.trim()
              : 'Location to be specified by user',
      incidentDescription:
          incidentDescription.isNotEmpty
              ? incidentDescription
              : 'Vehicle damage assessment submitted via InsureVis app',
      vehicleMake: vehicleData?['make'],
      vehicleModel: vehicleData?['model'],
      vehicleYear:
          vehicleData?['year'] != null
              ? int.tryParse(vehicleData!['year']!)
              : null,
      vehiclePlateNumber: vehicleData?['plate_number'],
      estimatedDamageCost: estimatedDamageCost,
      damages: damagesPayload,
    );

    if (claim == null) {
      throw Exception('Failed to create claim');
    }

    debugPrint('=== CLAIM CREATED ===');
    debugPrint('Claim ID: ${claim.id}');
    debugPrint('Vehicle Make in claim: ${claim.vehicleMake}');
    debugPrint('Vehicle Model in claim: ${claim.vehicleModel}');
    debugPrint('Vehicle Year in claim: ${claim.vehicleYear}');
    debugPrint('Plate Number in claim: ${claim.vehiclePlateNumber}');
    debugPrint('==================');

    // Submit the claim FIRST before uploading documents
    debugPrint('Submitting claim ${claim.id} before document upload...');
    final submitSuccess = await ClaimsService.submitClaim(claim.id);

    if (!submitSuccess) {
      // Submission failed - clean up the draft claim
      debugPrint('Claim submission failed. Cleaning up draft claim...');
      try {
        await ClaimsService.deleteClaim(claim.id);
        debugPrint('Successfully deleted draft claim ${claim.id}');
      } catch (e) {
        debugPrint('Error deleting draft claim: $e');
      }
      throw Exception('Failed to submit claim');
    }

    debugPrint(
      'Claim submitted successfully. Starting document upload for claim: ${claim.id}',
    );

    // Upload documents
    final uploadResult = await _uploadDocuments(
      claimId: claim.id,
      uploadedDocuments: uploadedDocuments,
    );

    return {
      'claim': claim,
      'uploadSuccess': uploadResult['success'],
      'totalUploaded': uploadResult['totalUploaded'],
      'totalFiles': uploadResult['totalFiles'],
    };
  }

  /// Uploads all documents for a claim
  static Future<Map<String, dynamic>> _uploadDocuments({
    required String claimId,
    required Map<String, List<File>> uploadedDocuments,
  }) async {
    final documentService = DocumentService();
    bool allUploadsSuccessful = true;
    int totalUploaded = 0;

    // Collect all files to upload in parallel
    final List<File> allFiles = [];
    final List<DocumentType> allTypes = [];
    final List<String> allDescriptions = [];
    final List<bool> allIsRequired = [];

    for (String docTypeKey in uploadedDocuments.keys) {
      final files = uploadedDocuments[docTypeKey] ?? [];
      if (files.isNotEmpty) {
        debugPrint('Preparing ${files.length} files for category: $docTypeKey');

        final DocumentType docType = DocumentType.fromKey(docTypeKey);

        for (File file in files) {
          allFiles.add(file);
          allTypes.add(docType);
          allDescriptions.add(
            '${docType.displayName} - ${file.path.split('/').last}',
          );
          allIsRequired.add(docType.isRequired);
        }
      }
    }

    // Upload all files in parallel
    if (allFiles.isNotEmpty) {
      debugPrint('Uploading ${allFiles.length} files in parallel...');
      try {
        // Get current user ID
        final currentUser = SupabaseService.currentUser;
        if (currentUser == null) {
          throw Exception('User not authenticated');
        }

        final uploadResults = await documentService.uploadMultipleDocuments(
          claimId: claimId,
          files: allFiles,
          types: allTypes,
          userId: currentUser.id,
          descriptions: allDescriptions,
          isRequiredList: allIsRequired,
        );

        // Check results
        for (int i = 0; i < uploadResults.length; i++) {
          if (uploadResults[i] != null) {
            totalUploaded++;
          } else {
            allUploadsSuccessful = false;
          }
        }
      } catch (e) {
        debugPrint('Error during parallel upload: $e');
        allUploadsSuccessful = false;
      }
    }

    debugPrint(
      'Total files uploaded: $totalUploaded out of ${allFiles.length}',
    );

    return {
      'success': allUploadsSuccessful,
      'totalUploaded': totalUploaded,
      'totalFiles': allFiles.length,
    };
  }

  /// Cleans up claim if submission fails
  static Future<void> cleanupFailedClaim(dynamic claim) async {
    if (claim != null) {
      debugPrint('Cleaning up draft claim due to error...');
      try {
        await ClaimsService.deleteClaim(claim.id);
        debugPrint('Successfully deleted draft claim ${claim.id}');
      } catch (deleteError) {
        debugPrint('Error deleting draft claim: $deleteError');
      }
    }
  }
}
