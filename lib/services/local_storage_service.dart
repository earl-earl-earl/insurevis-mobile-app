import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class LocalStorageService {
  static const String APP_FOLDER_NAME = 'InsureVis';
  static const String DOCUMENTS_FOLDER_NAME = 'documents';

  /// Initialize the app folder structure on first launch
  static Future<bool> initializeAppFolders() async {
    try {
      // Request necessary permissions first
      await _requestStoragePermissions();

      // Create the main InsureVis folder and documents subfolder
      final appDir = await _createAppDirectory();
      final documentsDir = await _createDocumentsDirectory(appDir);

      if (appDir != null && documentsDir != null) {
        print('App folders initialized successfully:');
        print('Main folder: ${appDir.path}');
        print('Documents folder: ${documentsDir.path}');
        return true;
      }

      return false;
    } catch (e) {
      print('Error initializing app folders: $e');
      return false;
    }
  }

  /// Get the InsureVis main folder directory
  static Future<Directory?> getAppDirectory() async {
    try {
      if (Platform.isAndroid) {
        // Try to get external storage directory first
        Directory? externalDir;
        try {
          externalDir = await getExternalStorageDirectory();
        } catch (e) {
          print('Could not get external storage: $e');
        }

        if (externalDir != null) {
          // Create InsureVis in external storage root
          final appDir = Directory(
            '${externalDir.path}/../../$APP_FOLDER_NAME',
          );
          if (!await appDir.exists()) {
            await appDir.create(recursive: true);
          }
          return appDir;
        } else {
          // Fallback to app documents directory
          final appDir = await getApplicationDocumentsDirectory();
          final insureVisDir = Directory('${appDir.path}/$APP_FOLDER_NAME');
          if (!await insureVisDir.exists()) {
            await insureVisDir.create(recursive: true);
          }
          return insureVisDir;
        }
      } else if (Platform.isIOS) {
        // For iOS, use app documents directory
        final appDir = await getApplicationDocumentsDirectory();
        final insureVisDir = Directory('${appDir.path}/$APP_FOLDER_NAME');
        if (!await insureVisDir.exists()) {
          await insureVisDir.create(recursive: true);
        }
        return insureVisDir;
      } else {
        // For desktop platforms, use current directory
        final currentDir = Directory.current;
        final appDir = Directory('${currentDir.path}/$APP_FOLDER_NAME');
        if (!await appDir.exists()) {
          await appDir.create(recursive: true);
        }
        return appDir;
      }
    } catch (e) {
      print('Error getting app directory: $e');
      return null;
    }
  }

  /// Get the InsureVis documents folder directory
  static Future<Directory?> getDocumentsDirectory() async {
    try {
      final appDir = await getAppDirectory();
      if (appDir != null) {
        final documentsDir = Directory('${appDir.path}/$DOCUMENTS_FOLDER_NAME');
        if (!await documentsDir.exists()) {
          await documentsDir.create(recursive: true);
        }
        return documentsDir;
      }
      return null;
    } catch (e) {
      print('Error getting documents directory: $e');
      return null;
    }
  }

  /// Save a file to the InsureVis documents folder
  static Future<String?> saveFileToDocuments(
    List<int> fileBytes,
    String fileName,
  ) async {
    try {
      final documentsDir = await getDocumentsDirectory();
      if (documentsDir != null) {
        // Generate unique filename if file already exists
        String finalFileName = fileName;
        int counter = 1;
        while (await File('${documentsDir.path}/$finalFileName').exists()) {
          final nameWithoutExtension = fileName.replaceAll(
            RegExp(r'\.[^.]+$'),
            '',
          );
          final extension = fileName.split('.').last;
          finalFileName = '${nameWithoutExtension}_$counter.$extension';
          counter++;
        }

        final file = File('${documentsDir.path}/$finalFileName');
        await file.writeAsBytes(fileBytes);

        if (await file.exists() && await file.length() > 0) {
          print('File saved successfully: ${file.path}');
          return file.path;
        }
      }
      return null;
    } catch (e) {
      print('Error saving file to documents: $e');
      return null;
    }
  }

  /// List all files in the documents folder
  static Future<List<File>> getDocumentFiles() async {
    try {
      final documentsDir = await getDocumentsDirectory();
      if (documentsDir != null && await documentsDir.exists()) {
        final entities = await documentsDir.list().toList();
        return entities.where((entity) => entity is File).cast<File>().toList();
      }
      return [];
    } catch (e) {
      print('Error getting document files: $e');
      return [];
    }
  }

  /// Check if storage permissions are granted
  static Future<bool> hasStoragePermissions() async {
    try {
      if (Platform.isAndroid) {
        final storageStatus = await Permission.storage.status;
        final manageStorageStatus =
            await Permission.manageExternalStorage.status;
        final photosStatus = await Permission.photos.status;

        return storageStatus.isGranted ||
            manageStorageStatus.isGranted ||
            photosStatus.isGranted;
      } else if (Platform.isIOS) {
        final photosStatus = await Permission.photos.status;
        return photosStatus.isGranted;
      }
      return true; // Desktop platforms don't need permissions
    } catch (e) {
      print('Error checking storage permissions: $e');
      return false;
    }
  }

  /// Request storage permissions
  static Future<bool> _requestStoragePermissions() async {
    try {
      if (Platform.isAndroid) {
        bool hasPermission = false;

        // Try storage permission first
        var status = await Permission.storage.request();
        hasPermission = status.isGranted;

        // For Android 11+ (API 30+), try manage external storage
        if (!hasPermission) {
          status = await Permission.manageExternalStorage.request();
          hasPermission = status.isGranted;
        }

        // Also request media permissions for modern Android
        if (!hasPermission) {
          final mediaStatus = await Permission.photos.request();
          hasPermission = mediaStatus.isGranted;
        }

        return hasPermission;
      } else if (Platform.isIOS) {
        // For iOS, request photo library permissions
        var status = await Permission.photos.request();
        return status.isGranted;
      }
      return true; // Desktop platforms don't need permissions
    } catch (e) {
      print('Error requesting storage permissions: $e');
      return false;
    }
  }

  /// Create the main app directory
  static Future<Directory?> _createAppDirectory() async {
    return await getAppDirectory();
  }

  /// Create the documents subdirectory
  static Future<Directory?> _createDocumentsDirectory(Directory? appDir) async {
    if (appDir != null) {
      try {
        final documentsDir = Directory('${appDir.path}/$DOCUMENTS_FOLDER_NAME');
        if (!await documentsDir.exists()) {
          await documentsDir.create(recursive: true);
        }
        return documentsDir;
      } catch (e) {
        print('Error creating documents directory: $e');
        return null;
      }
    }
    return null;
  }

  /// Clean up old files (optional maintenance)
  static Future<void> cleanupOldFiles({int daysOld = 30}) async {
    try {
      final documentsDir = await getDocumentsDirectory();
      if (documentsDir != null && await documentsDir.exists()) {
        final entities = await documentsDir.list().toList();
        final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

        for (final entity in entities) {
          if (entity is File) {
            final stat = await entity.stat();
            if (stat.modified.isBefore(cutoffDate)) {
              await entity.delete();
              print('Deleted old file: ${entity.path}');
            }
          }
        }
      }
    } catch (e) {
      print('Error cleaning up old files: $e');
    }
  }
}
