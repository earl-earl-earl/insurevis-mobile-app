import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';

class GalleryUtils {
  /// Maximum file size in bytes (50 MB)
  static const int maxFileSizeBytes = 50 * 1024 * 1024;

  /// Supported image formats
  static const List<String> supportedFormats = ['jpg', 'jpeg', 'png', 'webp'];

  /// Pick multiple images from device gallery
  static Future<List<File>> pickImages() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: false,
        withReadStream: false,
      );

      if (result != null && result.files.isNotEmpty) {
        List<File> imageFiles = [];

        for (var file in result.files) {
          if (file.path != null) {
            final imageFile = File(file.path!);

            // Validate file size and format
            if (await _isValidImageFile(imageFile)) {
              imageFiles.add(imageFile);
            }
          }
        }

        return imageFiles;
      }

      return [];
    } catch (e) {
      throw Exception('Error selecting images: ${e.toString()}');
    }
  }

  /// Validate if file is a valid image
  static Future<bool> _isValidImageFile(File file) async {
    try {
      // Check file size
      final fileSizeBytes = await file.length();
      if (fileSizeBytes > maxFileSizeBytes) {
        return false;
      }

      // Check file extension
      final extension = file.path.split('.').last.toLowerCase();
      if (!supportedFormats.contains(extension)) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Remove image from list at specified index
  static List<File> removeImage(List<File> images, int index) {
    final updatedList = List<File>.from(images);
    if (index >= 0 && index < updatedList.length) {
      updatedList.removeAt(index);
    }
    return updatedList;
  }

  /// Clear all images
  static List<File> clearAllImages() {
    return [];
  }

  /// Convert list of File objects to list of paths
  static List<String> convertFilesToPaths(List<File> files) {
    return files.map((file) => file.path).toList();
  }

  /// Validate if images list is not empty
  static bool hasImages(List<File> images) {
    return images.isNotEmpty;
  }

  /// Get count of selected images
  static int getImageCount(List<File> images) {
    return images.length;
  }

  /// Get total size of all images in MB
  static Future<double> getTotalImagesSizeMB(List<File> images) async {
    try {
      double totalSize = 0;
      for (var image in images) {
        totalSize += await image.length();
      }
      return totalSize / (1024 * 1024); // Convert to MB
    } catch (e) {
      return 0.0;
    }
  }

  /// Get formatted size string for display
  static String getFormattedSize(double bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = (log(bytes) / log(1024)).floor();
    return (bytes / pow(1024, i)).toStringAsFixed(2) + " " + suffixes[i];
  }

  /// Validate image quality and properties
  static Future<bool> validateImageQuality(File image) async {
    try {
      // Check if file exists
      if (!await image.exists()) {
        return false;
      }

      // Check file size
      final fileSizeBytes = await image.length();
      if (fileSizeBytes == 0 || fileSizeBytes > maxFileSizeBytes) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get file name from path
  static String getFileName(String filePath) {
    return filePath.split('/').last;
  }

  /// Get file extension
  static String getFileExtension(String filePath) {
    return filePath.split('.').last.toUpperCase();
  }
}
