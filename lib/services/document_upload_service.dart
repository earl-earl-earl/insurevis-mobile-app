import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/document_model.dart';
import 'document_repository.dart';

/// Service for uploading documents to Supabase Storage
class DocumentUploadService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final DocumentRepository _repository = DocumentRepository();

  static const String _bucketName = 'insurevis-documents';

  /// Upload a document to Supabase Storage
  Future<DocumentUploadResult> uploadDocument(
    DocumentModel document, {
    Function(double)? onProgress,
  }) async {
    try {
      final file = document.file;
      if (file == null) {
        return DocumentUploadResult(
          success: false,
          errorMessage: 'No file found for document',
        );
      }

      // Update document status to uploading
      await _repository.updateDocumentStatus(
        document.id,
        DocumentStatus.uploading,
      );

      // Generate storage path: userId/assessmentId/documentType/filename
      final storagePath = _generateStoragePath(document);

      // Upload file to Supabase Storage
      final bytes = await file.readAsBytes();
      await _supabase.storage
          .from(_bucketName)
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              contentType: _getContentType(document.format),
              upsert: false,
            ),
          );

      // Get public URL for the uploaded file
      final publicUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(storagePath);

      // Update document with remote URL
      final success = await _repository.updateDocumentRemoteUrl(
        document.id,
        publicUrl,
      );

      if (success) {
        // Add history entry
        await _repository.addDocumentHistory(
          document.id,
          DocumentStatus.uploaded.key,
          notes: 'File uploaded successfully to storage',
        );

        return DocumentUploadResult(
          success: true,
          remoteUrl: publicUrl,
          storagePath: storagePath,
        );
      } else {
        return DocumentUploadResult(
          success: false,
          errorMessage: 'Failed to update document with remote URL',
        );
      }
    } catch (e) {
      // Update document status to failed
      await _repository.updateDocumentStatus(
        document.id,
        DocumentStatus.failed,
        errorMessage: e.toString(),
      );

      return DocumentUploadResult(
        success: false,
        errorMessage: 'Upload failed: $e',
      );
    }
  }

  /// Upload multiple documents concurrently
  Future<List<DocumentUploadResult>> uploadMultipleDocuments(
    List<DocumentModel> documents, {
    Function(int completed, int total)? onProgress,
  }) async {
    final results = <DocumentUploadResult>[];
    int completed = 0;

    for (final document in documents) {
      final result = await uploadDocument(document);
      results.add(result);
      completed++;

      if (onProgress != null) {
        onProgress(completed, documents.length);
      }
    }

    return results;
  }

  /// Download a document from Supabase Storage
  Future<Uint8List?> downloadDocument(String storagePath) async {
    try {
      final bytes = await _supabase.storage
          .from(_bucketName)
          .download(storagePath);

      return bytes;
    } catch (e) {
      print('Error downloading document: $e');
      return null;
    }
  }

  /// Delete a document from Supabase Storage
  Future<bool> deleteDocument(String storagePath) async {
    try {
      await _supabase.storage.from(_bucketName).remove([storagePath]);

      return true;
    } catch (e) {
      print('Error deleting document from storage: $e');
      return false;
    }
  }

  /// Generate a unique storage path for the document
  String _generateStoragePath(DocumentModel document) {
    final userId = document.userId ?? 'anonymous';
    final assessmentId = document.assessmentId ?? 'general';
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Clean filename to avoid special characters
    final cleanFileName = document.fileName
        .replaceAll(RegExp(r'[^\w\s\-\.]'), '')
        .replaceAll(RegExp(r'\s+'), '_');

    return '$userId/$assessmentId/${document.type.key}/${timestamp}_$cleanFileName';
  }

  /// Get MIME content type for document format
  String _getContentType(DocumentFormat format) {
    switch (format) {
      case DocumentFormat.pdf:
        return 'application/pdf';
      case DocumentFormat.jpeg:
      case DocumentFormat.jpg:
        return 'image/jpeg';
      case DocumentFormat.png:
        return 'image/png';
      case DocumentFormat.doc:
        return 'application/msword';
      case DocumentFormat.docx:
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  /// Create thumbnail for image documents
  Future<String?> createThumbnail(DocumentModel document) async {
    if (!document.format.isImage || document.file == null) {
      return null;
    }

    try {
      // This is a simplified version - you might want to use image package
      // for more sophisticated thumbnail generation
      final file = document.file!;
      final bytes = await file.readAsBytes();

      // Generate thumbnail path
      final thumbnailPath = _generateThumbnailPath(document);

      // Upload thumbnail (in a real implementation, you'd resize the image first)
      await _supabase.storage
          .from(_bucketName)
          .uploadBinary(
            thumbnailPath,
            bytes,
            fileOptions: FileOptions(
              contentType: _getContentType(document.format),
              upsert: false,
            ),
          );

      return _supabase.storage.from(_bucketName).getPublicUrl(thumbnailPath);
    } catch (e) {
      print('Error creating thumbnail: $e');
      return null;
    }
  }

  /// Generate thumbnail storage path
  String _generateThumbnailPath(DocumentModel document) {
    final originalPath = _generateStoragePath(document);
    final pathParts = originalPath.split('.');
    final extension = pathParts.last;
    final basePath = pathParts.sublist(0, pathParts.length - 1).join('.');
    return '${basePath}_thumb.$extension';
  }

  /// Get storage usage statistics for a user
  Future<StorageUsageStats> getStorageUsage(String userId) async {
    try {
      final documents = await _repository.getDocumentsByUserId(userId);

      int totalFiles = 0;
      int totalSizeBytes = 0;
      final Map<DocumentType, int> countByType = {};
      final Map<DocumentFormat, int> countByFormat = {};

      for (final doc in documents) {
        if (doc.remoteUrl != null) {
          totalFiles++;
          totalSizeBytes += doc.fileSizeBytes ?? 0;

          countByType[doc.type] = (countByType[doc.type] ?? 0) + 1;
          countByFormat[doc.format] = (countByFormat[doc.format] ?? 0) + 1;
        }
      }

      return StorageUsageStats(
        totalFiles: totalFiles,
        totalSizeBytes: totalSizeBytes,
        countByType: countByType,
        countByFormat: countByFormat,
      );
    } catch (e) {
      print('Error getting storage usage: $e');
      return StorageUsageStats(
        totalFiles: 0,
        totalSizeBytes: 0,
        countByType: {},
        countByFormat: {},
      );
    }
  }

  /// Check if storage bucket exists and create if necessary
  Future<bool> ensureStorageBucketExists() async {
    try {
      // Try to get bucket info
      await _supabase.storage.getBucket(_bucketName);
      return true;
    } catch (e) {
      // Bucket doesn't exist, try to create it
      try {
        await _supabase.storage.createBucket(
          _bucketName,
          BucketOptions(
            public: false,
            allowedMimeTypes: [
              'application/pdf',
              'image/jpeg',
              'image/jpg',
              'image/png',
              'application/msword',
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            ],
            fileSizeLimit: '10MB',
          ),
        );
        return true;
      } catch (createError) {
        print('Error creating storage bucket: $createError');
        return false;
      }
    }
  }
}

/// Result of document upload operation
class DocumentUploadResult {
  final bool success;
  final String? remoteUrl;
  final String? storagePath;
  final String? errorMessage;

  DocumentUploadResult({
    required this.success,
    this.remoteUrl,
    this.storagePath,
    this.errorMessage,
  });
}

/// Storage usage statistics
class StorageUsageStats {
  final int totalFiles;
  final int totalSizeBytes;
  final Map<DocumentType, int> countByType;
  final Map<DocumentFormat, int> countByFormat;

  StorageUsageStats({
    required this.totalFiles,
    required this.totalSizeBytes,
    required this.countByType,
    required this.countByFormat,
  });

  /// Get formatted total size
  String get formattedTotalSize {
    const int kb = 1024;
    const int mb = kb * 1024;
    const int gb = mb * 1024;

    if (totalSizeBytes >= gb) {
      return '${(totalSizeBytes / gb).toStringAsFixed(2)} GB';
    } else if (totalSizeBytes >= mb) {
      return '${(totalSizeBytes / mb).toStringAsFixed(2)} MB';
    } else if (totalSizeBytes >= kb) {
      return '${(totalSizeBytes / kb).toStringAsFixed(2)} KB';
    } else {
      return '$totalSizeBytes bytes';
    }
  }
}
