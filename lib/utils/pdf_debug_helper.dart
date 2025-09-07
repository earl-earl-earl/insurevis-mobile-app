import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class PDFDebugHelper {
  /// Check system capabilities for PDF generation
  static Future<Map<String, dynamic>> checkPDFCapabilities() async {
    final capabilities = <String, dynamic>{};

    // Check platform
    capabilities['platform'] = Platform.operatingSystem;
    capabilities['is_android'] = Platform.isAndroid;
    capabilities['is_ios'] = Platform.isIOS;
    capabilities['is_debug'] = kDebugMode;

    // Check directory access
    try {
      final appDir = await getApplicationDocumentsDirectory();
      capabilities['app_documents_dir'] = appDir.path;
      capabilities['app_documents_accessible'] = await appDir.exists();
    } catch (e) {
      capabilities['app_documents_error'] = e.toString();
      capabilities['app_documents_accessible'] = false;
    }

    // Check external storage (Android)
    if (Platform.isAndroid) {
      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          capabilities['external_storage_dir'] = externalDir.path;
          capabilities['external_storage_accessible'] =
              await externalDir.exists();
        } else {
          capabilities['external_storage_accessible'] = false;
          capabilities['external_storage_error'] =
              'External storage directory is null';
        }
      } catch (e) {
        capabilities['external_storage_error'] = e.toString();
        capabilities['external_storage_accessible'] = false;
      }

      // Check Downloads directory
      try {
        final downloadsDir = Directory('/storage/emulated/0/Download');
        capabilities['downloads_dir_exists'] = await downloadsDir.exists();

        if (await downloadsDir.exists()) {
          // Test write access
          final testFile = File(
            '${downloadsDir.path}/.pdf_test_${DateTime.now().millisecondsSinceEpoch}',
          );
          await testFile.writeAsString('test');
          capabilities['downloads_dir_writable'] = await testFile.exists();
          if (await testFile.exists()) {
            await testFile.delete();
          }
        } else {
          capabilities['downloads_dir_writable'] = false;
        }
      } catch (e) {
        capabilities['downloads_dir_error'] = e.toString();
        capabilities['downloads_dir_writable'] = false;
      }
    }

    // Check temp directory
    try {
      final tempDir = Directory.systemTemp;
      capabilities['temp_dir'] = tempDir.path;
      capabilities['temp_dir_accessible'] = await tempDir.exists();

      // Test temp directory write
      final testTempFile = File(
        '${tempDir.path}/.pdf_test_${DateTime.now().millisecondsSinceEpoch}',
      );
      await testTempFile.writeAsString('test');
      capabilities['temp_dir_writable'] = await testTempFile.exists();
      if (await testTempFile.exists()) {
        await testTempFile.delete();
      }
    } catch (e) {
      capabilities['temp_dir_error'] = e.toString();
      capabilities['temp_dir_accessible'] = false;
    }

    // Check project PDF directory
    try {
      final currentDir = Directory.current;
      final projectPDFDir = Directory('${currentDir.path}/generated_pdfs');
      capabilities['project_pdf_dir'] = projectPDFDir.path;
      capabilities['project_pdf_dir_accessible'] = await currentDir.exists();

      // Test creating the PDF directory
      if (!await projectPDFDir.exists()) {
        await projectPDFDir.create(recursive: true);
        capabilities['project_pdf_dir_created'] = true;
      }
      capabilities['project_pdf_dir_writable'] = await projectPDFDir.exists();

      // Test write access
      if (await projectPDFDir.exists()) {
        final testFile = File(
          '${projectPDFDir.path}/.pdf_test_${DateTime.now().millisecondsSinceEpoch}',
        );
        await testFile.writeAsString('test');
        capabilities['project_pdf_dir_write_test'] = await testFile.exists();
        if (await testFile.exists()) {
          await testFile.delete();
        }
      }
    } catch (e) {
      capabilities['project_pdf_dir_error'] = e.toString();
      capabilities['project_pdf_dir_accessible'] = false;
    }

    return capabilities;
  }

  /// Print debug information about PDF capabilities
  static Future<void> printPDFDebugInfo() async {
    final capabilities = await checkPDFCapabilities();

    print('=== PDF Debug Information ===');
    print('Platform: ${capabilities['platform']}');
    print('Is Android: ${capabilities['is_android']}');
    print('Is iOS: ${capabilities['is_ios']}');
    print('Is Debug: ${capabilities['is_debug']}');

    print('\n--- Directory Access ---');
    print('App Documents Dir: ${capabilities['app_documents_dir'] ?? 'N/A'}');
    print(
      'App Documents Accessible: ${capabilities['app_documents_accessible']}',
    );
    if (capabilities['app_documents_error'] != null) {
      print('App Documents Error: ${capabilities['app_documents_error']}');
    }

    if (capabilities['is_android'] == true) {
      print(
        'External Storage Dir: ${capabilities['external_storage_dir'] ?? 'N/A'}',
      );
      print(
        'External Storage Accessible: ${capabilities['external_storage_accessible']}',
      );
      if (capabilities['external_storage_error'] != null) {
        print(
          'External Storage Error: ${capabilities['external_storage_error']}',
        );
      }

      print('Downloads Dir Exists: ${capabilities['downloads_dir_exists']}');
      print(
        'Downloads Dir Writable: ${capabilities['downloads_dir_writable']}',
      );
      if (capabilities['downloads_dir_error'] != null) {
        print('Downloads Dir Error: ${capabilities['downloads_dir_error']}');
      }
    }

    print('Temp Dir: ${capabilities['temp_dir']}');
    print('Temp Dir Accessible: ${capabilities['temp_dir_accessible']}');
    print('Temp Dir Writable: ${capabilities['temp_dir_writable']}');
    if (capabilities['temp_dir_error'] != null) {
      print('Temp Dir Error: ${capabilities['temp_dir_error']}');
    }

    print('\n--- Project PDF Directory ---');
    print('Project PDF Dir: ${capabilities['project_pdf_dir']}');
    print(
      'Project PDF Dir Accessible: ${capabilities['project_pdf_dir_accessible']}',
    );
    print(
      'Project PDF Dir Writable: ${capabilities['project_pdf_dir_writable']}',
    );
    if (capabilities['project_pdf_dir_created'] == true) {
      print(
        'Project PDF Dir Created: ${capabilities['project_pdf_dir_created']}',
      );
    }
    print(
      'Project PDF Dir Write Test: ${capabilities['project_pdf_dir_write_test'] ?? 'N/A'}',
    );
    if (capabilities['project_pdf_dir_error'] != null) {
      print('Project PDF Dir Error: ${capabilities['project_pdf_dir_error']}');
    }

    print('=== End PDF Debug Info ===\n');
  }

  /// Get recommended PDF save directory based on capabilities
  static Future<Directory> getRecommendedPDFDirectory() async {
    try {
      // Use project directory structure for PDF storage
      final currentDir = Directory.current;
      final pdfDir = Directory('${currentDir.path}/generated_pdfs');

      // Ensure directory exists
      if (!await pdfDir.exists()) {
        await pdfDir.create(recursive: true);
      }

      return pdfDir;
    } catch (e) {
      debugPrint('Project PDF directory not available: $e');
      // Fall back to system temp directory
      return Directory.systemTemp;
    }
  }

  /// Clean up old PDF files (for testing/debugging)
  static Future<void> cleanupTestPDFs() async {
    try {
      final capabilities = await checkPDFCapabilities();
      final directories = <Directory>[];

      // Add app documents directory if available
      if (capabilities['app_documents_accessible'] == true) {
        directories.add(Directory(capabilities['app_documents_dir']));
      }

      // Add temp directory
      directories.add(Directory.systemTemp);

      for (final dir in directories) {
        final files =
            await dir.list().where((entity) {
              return entity is File &&
                  (entity.path.contains('test') ||
                      entity.path.contains('assessment')) &&
                  entity.path.endsWith('.pdf');
            }).toList();

        for (final file in files) {
          try {
            await file.delete();
            print('Deleted test PDF: ${file.path}');
          } catch (e) {
            print('Failed to delete ${file.path}: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error during PDF cleanup: $e');
    }
  }
}
