import 'dart:io';
import 'package:file_picker/file_picker.dart';

class GalleryUtils {
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
            imageFiles.add(File(file.path!));
          }
        }

        return imageFiles;
      }

      return [];
    } catch (e) {
      throw Exception('Error selecting images: ${e.toString()}');
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
}
