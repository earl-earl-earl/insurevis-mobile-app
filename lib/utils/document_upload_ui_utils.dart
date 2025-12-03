import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:insurevis/services/local_storage_service.dart';

/// Utility class for UI-related operations in document upload
class DocumentUploadUIUtils {
  /// Shows a date picker dialog and returns formatted date string (dd/MM/yyyy)
  static Future<String?> pickIncidentDate(
    BuildContext context,
    String currentDateText,
  ) async {
    DateTime initialDate = DateTime.now().subtract(const Duration(days: 1));

    // Parse current date if exists
    if (currentDateText.trim().isNotEmpty) {
      try {
        final dateParts = currentDateText.split('/');
        if (dateParts.length == 3) {
          initialDate = DateTime(
            int.parse(dateParts[2]), // year
            int.parse(dateParts[1]), // month
            int.parse(dateParts[0]), // day
          );
        }
      } catch (e) {
        // If parsing fails, use default date
        debugPrint('Error parsing current date: $e');
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      return DateFormat('dd/MM/yyyy').format(picked);
    }

    return null;
  }

  /// Downloads a PDF file with user-friendly UI feedback
  static Future<DownloadResult> downloadPdf(String sourcePath) async {
    try {
      // Check if source file exists
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        return DownloadResult(success: false, message: 'PDF file not found');
      }

      // Read the PDF bytes
      final pdfBytes = await sourceFile.readAsBytes();

      // Generate a unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'Job_Estimate_$timestamp.pdf';

      // Save to user-selected location or default documents folder
      String? savedPath;
      try {
        savedPath = await LocalStorageService.saveFileToDocuments(
          pdfBytes,
          fileName,
          allowPicker: true,
        );
      } catch (e) {
        debugPrint('Error using LocalStorageService: $e');
        // Fallback to file picker
        savedPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Job Estimate PDF',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          bytes: pdfBytes,
        );
      }

      if (savedPath != null) {
        return DownloadResult(
          success: true,
          message: 'PDF downloaded successfully!',
          savedPath: savedPath,
        );
      } else {
        return DownloadResult(
          success: false,
          message: 'Download cancelled',
          cancelled: true,
        );
      }
    } catch (e) {
      debugPrint('Error downloading PDF: $e');
      return DownloadResult(
        success: false,
        message: 'Error downloading PDF: $e',
      );
    }
  }

  /// Validates if PDF file exists before viewing
  static Future<bool> validatePdfExists(String pdfPath) async {
    try {
      final file = File(pdfPath);
      return await file.exists();
    } catch (e) {
      debugPrint('Error checking PDF existence: $e');
      return false;
    }
  }

  /// Gets missing required documents list for error messages
  static List<String> getMissingRequiredDocumentsList(
    Map<String, bool> requiredDocuments,
    Map<String, List<File>> uploadedDocuments,
  ) {
    return requiredDocuments.keys
        .where(
          (k) => requiredDocuments[k]! && (uploadedDocuments[k] ?? []).isEmpty,
        )
        .map((k) => _documentTitleFromKey(k))
        .toList();
  }

  /// Converts document key to human-readable title
  static String _documentTitleFromKey(String key) {
    switch (key) {
      case 'lto_or':
        return 'LTO Official Receipt';
      case 'lto_cr':
        return 'LTO Certificate of Registration';
      case 'drivers_license':
        return "Driver's License";
      case 'owner_valid_id':
        return "Owner's Valid ID";
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
      case 'additional_documents':
        return 'Additional Documents';
      default:
        return key
            .split('_')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }
}

/// Result object for download operations
class DownloadResult {
  final bool success;
  final String message;
  final String? savedPath;
  final bool cancelled;

  DownloadResult({
    required this.success,
    required this.message,
    this.savedPath,
    this.cancelled = false,
  });
}
