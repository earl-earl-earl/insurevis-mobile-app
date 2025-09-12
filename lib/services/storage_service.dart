import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String bucketName = 'insurevis-documents';

  /// Upload a file to Supabase storage
  Future<String?> uploadDocument({
    required File file,
    required String documentType,
    required String userId,
    String? assessmentId,
  }) async {
    try {
      // Generate simplified storage path
      final fileName = path.basename(file.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sanitizedFileName = _sanitizeFileName(fileName);

      // Simplified path structure: userId/timestamp_filename
      String storagePath = '$userId/${timestamp}_$sanitizedFileName';

      // Upload file
      final response = await _supabase.storage
          .from(bucketName)
          .upload(storagePath, file);

      if (response.isNotEmpty) {
        return storagePath;
      }
      return null;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  /// Upload from bytes (useful for web)
  Future<String?> uploadDocumentFromBytes({
    required Uint8List bytes,
    required String fileName,
    required String documentType,
    required String userId,
    String? assessmentId,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sanitizedFileName = _sanitizeFileName(fileName);

      // Simplified path structure: userId/timestamp_filename
      String storagePath = '$userId/${timestamp}_$sanitizedFileName';

      final response = await _supabase.storage
          .from(bucketName)
          .uploadBinary(storagePath, bytes);

      if (response.isNotEmpty) {
        return storagePath;
      }
      return null;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  /// Get signed URL for private access
  Future<String?> getSignedUrl(
    String storagePath, {
    int expiresIn = 3600,
  }) async {
    try {
      final response = await _supabase.storage
          .from(bucketName)
          .createSignedUrl(storagePath, expiresIn);
      return response;
    } catch (e) {
      print('Signed URL error: $e');
      return null;
    }
  }

  /// Get public URL (only if bucket/file is public)
  String getPublicUrl(String storagePath) {
    return _supabase.storage.from(bucketName).getPublicUrl(storagePath);
  }

  /// Download file
  Future<Uint8List?> downloadFile(String storagePath) async {
    try {
      final response = await _supabase.storage
          .from(bucketName)
          .download(storagePath);
      return response;
    } catch (e) {
      print('Download error: $e');
      return null;
    }
  }

  /// Delete file
  Future<bool> deleteFile(String storagePath) async {
    try {
      await _supabase.storage.from(bucketName).remove([storagePath]);
      return true;
    } catch (e) {
      print('Delete error: $e');
      return false;
    }
  }

  /// Move file to different path
  Future<String?> moveFile(String fromPath, String toPath) async {
    try {
      await _supabase.storage.from(bucketName).move(fromPath, toPath);
      return toPath;
    } catch (e) {
      print('Move error: $e');
      return null;
    }
  }

  /// List files in a directory
  Future<List<FileObject>> listFiles(String prefix) async {
    try {
      final response = await _supabase.storage
          .from(bucketName)
          .list(path: prefix);
      return response;
    } catch (e) {
      print('List error: $e');
      return [];
    }
  }

  /// Sanitize filename for storage
  String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  /// Get file info
  Future<FileObject?> getFileInfo(String storagePath) async {
    try {
      // Extract directory and filename
      final parts = storagePath.split('/');
      final fileName = parts.last;
      final directory = parts.sublist(0, parts.length - 1).join('/');

      final files = await listFiles(directory);
      return files.firstWhere(
        (file) => file.name == fileName,
        orElse: () => throw Exception('File not found'),
      );
    } catch (e) {
      print('File info error: $e');
      return null;
    }
  }

  /// Upload multiple files at once
  Future<List<String?>> uploadMultipleDocuments({
    required List<File> files,
    required List<String> documentTypes,
    required String userId,
    String? assessmentId,
  }) async {
    if (files.length != documentTypes.length) {
      throw ArgumentError(
        'Files and document types lists must have the same length',
      );
    }

    final List<Future<String?>> uploadFutures = [];

    for (int i = 0; i < files.length; i++) {
      uploadFutures.add(
        uploadDocument(
          file: files[i],
          documentType: documentTypes[i],
          userId: userId,
          assessmentId: assessmentId,
        ),
      );
    }

    return await Future.wait(uploadFutures);
  }

  /// Check if bucket exists and create if not
  Future<bool> ensureBucketExists() async {
    try {
      // Try to list files in bucket to check if it exists
      await _supabase.storage.from(bucketName).list();
      return true;
    } catch (e) {
      print('Bucket check error: $e');
      // If bucket doesn't exist, we can't create it via client
      // This needs to be done via Supabase dashboard or admin API
      return false;
    }
  }

  /// Get storage usage for a user
  Future<int> getUserStorageUsage(String userId) async {
    try {
      final files = await listFiles(userId);
      int totalSize = 0;

      for (final file in files) {
        totalSize += file.metadata?['size'] as int? ?? 0;
      }

      return totalSize;
    } catch (e) {
      print('Storage usage error: $e');
      return 0;
    }
  }

  /// Clean up orphaned files (files not referenced in database)
  Future<List<String>> cleanupOrphanedFiles(
    String userId,
    List<String> validStoragePaths,
  ) async {
    try {
      final allFiles = await listFiles(userId);
      final List<String> orphanedFiles = [];

      for (final file in allFiles) {
        final fullPath = '$userId/${file.name}';
        if (!validStoragePaths.contains(fullPath)) {
          orphanedFiles.add(fullPath);
          await deleteFile(fullPath);
        }
      }

      return orphanedFiles;
    } catch (e) {
      print('Cleanup error: $e');
      return [];
    }
  }

  /// Generate storage path for a document
  static String generateStoragePath({
    required String userId,
    required String documentType,
    required String fileName,
    String? assessmentId,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitizedFileName = fileName.replaceAll(
      RegExp(r'[^a-zA-Z0-9._-]'),
      '_',
    );

    // Simplified path structure: userId/timestamp_filename
    return '$userId/${timestamp}_$sanitizedFileName';
  }

  /// Validate file before upload
  static bool validateFile(File file, {int maxSizeBytes = 50 * 1024 * 1024}) {
    // Check if file exists
    if (!file.existsSync()) {
      return false;
    }

    // Check file size
    final fileSize = file.lengthSync();
    if (fileSize > maxSizeBytes) {
      return false;
    }

    // Check file extension
    final allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'];
    final extension = path.extension(file.path).toLowerCase().substring(1);

    return allowedExtensions.contains(extension);
  }

  /// Get file extension from path
  static String getFileExtension(String filePath) {
    return path.extension(filePath).toLowerCase().substring(1);
  }

  /// Check if file is an image
  static bool isImageFile(String filePath) {
    final extension = getFileExtension(filePath);
    return ['jpg', 'jpeg', 'png'].contains(extension);
  }

  /// Check if file is a PDF
  static bool isPdfFile(String filePath) {
    return getFileExtension(filePath) == 'pdf';
  }

  /// Get MIME type from file extension
  static String getMimeType(String filePath) {
    final extension = getFileExtension(filePath);

    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }
}
