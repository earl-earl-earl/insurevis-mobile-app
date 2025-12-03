import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Utility class for document upload file handling operations
class DocumentUploadHandlerUtils {
  /// Picks documents from device storage
  static Future<List<File>?> pickDocuments() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        allowMultiple: true,
      );

      if (result != null) {
        return result.files
            .where((file) => file.path != null)
            .map((file) => File(file.path!))
            .toList();
      }
      return null;
    } catch (e) {
      debugPrint('Error picking documents: $e');
      rethrow;
    }
  }

  /// Takes a photo using device camera
  static Future<File?> takePhoto(ImagePicker picker) async {
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error taking photo: $e');
      rethrow;
    }
  }

  /// Ensures storage permission is granted
  /// Returns true if permission is available, false otherwise
  static Future<bool> ensureStoragePermission() async {
    try {
      // On Android, newer versions may require MANAGE_EXTERNAL_STORAGE for broad access.
      if (Platform.isAndroid) {
        // First try the normal storage permission
        final status = await Permission.storage.status;
        if (status.isGranted) return true;

        // If Android 11+ and storage not granted, try manage external storage
        final manageStatus = await Permission.manageExternalStorage.status;
        if (manageStatus.isGranted) return true;

        // Request storage first
        final requested = await Permission.storage.request();
        if (requested.isGranted) return true;

        // If still not granted, request manage external storage permission
        final manageRequested =
            await Permission.manageExternalStorage.request();
        if (manageRequested.isGranted) return true;

        // If permanently denied or restricted, return false
        if (requested.isPermanentlyDenied ||
            manageRequested.isPermanentlyDenied) {
          return false;
        }

        return false;
      } else {
        // On non-Android platforms, storage permission is not required the same way.
        return true;
      }
    } catch (e) {
      // On error, be conservative and return false
      debugPrint('Error checking storage permission: $e');
      return false;
    }
  }

  /// Ensures camera permission is granted
  static Future<bool> ensureCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('Error checking camera permission: $e');
      return false;
    }
  }

  /// Loads damage assessment images into uploaded documents
  static void loadDamageAssessmentImages({
    required List<String> imagePaths,
    required Map<String, List<File>> uploadedDocuments,
  }) {
    for (String imagePath in imagePaths) {
      final file = File(imagePath);
      if (file.existsSync()) {
        uploadedDocuments['damage_photos']!.add(file);
      }
    }
  }

  /// Adds temporary job estimate PDF to documents if available
  static void addTempJobEstimatePdf({
    required String? tempJobEstimatePdfPath,
    required Map<String, List<File>> uploadedDocuments,
  }) {
    if (tempJobEstimatePdfPath != null) {
      final tempPdfFile = File(tempJobEstimatePdfPath);
      if (tempPdfFile.existsSync()) {
        uploadedDocuments['job_estimate']!.add(tempPdfFile);
        debugPrint('Added temporary job estimate PDF to documents');
      }
    }
  }

  /// Cleans up temporary PDF file
  static Future<void> cleanupTempPdf(String? tempJobEstimatePdfPath) async {
    if (tempJobEstimatePdfPath != null) {
      try {
        final tempPdfFile = File(tempJobEstimatePdfPath);
        if (tempPdfFile.existsSync()) {
          await tempPdfFile.delete();
          debugPrint('Cleaned up temporary job estimate PDF');
        }
      } catch (e) {
        debugPrint('Error cleaning up temporary PDF: $e');
      }
    }
  }

  /// Checks if a file is an image
  static bool isImageFile(String fileName) {
    final lowerFileName = fileName.toLowerCase();
    return lowerFileName.endsWith('.jpg') ||
        lowerFileName.endsWith('.jpeg') ||
        lowerFileName.endsWith('.png');
  }

  /// Checks if a file is a PDF
  static bool isPdfFile(String fileName) {
    return fileName.toLowerCase().endsWith('.pdf');
  }

  /// Gets file name from path
  static String getFileName(String filePath) {
    return filePath.split('/').last;
  }

  /// Checks if a file is an assessment image
  static bool isAssessmentImage({
    required String category,
    required String filePath,
    required List<String> originalImagePaths,
  }) {
    return category == 'damage_photos' && originalImagePaths.contains(filePath);
  }

  /// Checks if a file is the auto-generated job estimate
  static bool isAutoGeneratedJobEstimate({
    required String category,
    required String filePath,
    String? tempJobEstimatePdfPath,
  }) {
    return category == 'job_estimate' &&
        tempJobEstimatePdfPath != null &&
        filePath == tempJobEstimatePdfPath;
  }
}
