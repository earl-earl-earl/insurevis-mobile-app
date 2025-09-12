import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/document_model.dart';
import 'storage_service.dart';

/// Service class for managing documents in the InsureVis app
class DocumentService {
  static const Uuid _uuid = Uuid();
  final SupabaseClient _supabase = Supabase.instance.client;
  final StorageService _storageService = StorageService();

  /// Upload document with storage integration
  Future<DocumentModel?> uploadDocument({
    required File file,
    required DocumentType type,
    required String userId,
    String? claimId, // Changed from assessmentId to claimId
    String? description,
    bool isRequired = false,
  }) async {
    try {
      // 1. Validate file first
      final validation = validateDocument(file, type);
      if (!validation.isValid) {
        throw Exception(
          'File validation failed: ${validation.errors.join(', ')}',
        );
      }

      // 2. Upload file to storage
      final storagePath = await _storageService.uploadDocument(
        file: file,
        documentType: type.key,
        userId: userId,
        assessmentId:
            claimId, // Pass claimId as assessmentId to storage service
      );

      if (storagePath == null) {
        throw Exception('Failed to upload file to storage');
      }

      // 3. Create document record in database
      final fileStats = await file.stat();

      // Generate a signed URL for the uploaded file
      final signedUrl = await _storageService.getSignedUrl(
        storagePath,
        expiresIn: 3600 * 24 * 30, // 30 days
      );

      final document = DocumentModel(
        id: _uuid.v4(),
        userId: userId,
        assessmentId: claimId, // This maps to claim_id in the database
        type: type,
        fileName: file.path.split('/').last,
        filePath: file.path, // Local path
        remoteUrl: signedUrl, // Set the remote URL for viewing
        storagePath: storagePath, // Supabase storage path
        bucketName: 'insurevis-documents',
        format: DocumentFormat.fromFilePath(file.path),
        status: DocumentStatus.uploaded,
        fileSizeBytes: fileStats.size,
        description:
            description ??
            'Document uploaded for insurance claim ${claimId ?? 'general'} - ${type.displayName}',
        isRequired: isRequired,
        reviewStatus: ReviewStatus.pending,
        isApproved: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 4. Save to database
      final response =
          await _supabase
              .from('documents')
              .insert(document.toJson())
              .select()
              .single();

      return DocumentModel.fromJson(response);
    } catch (e) {
      print('Upload document error: $e');
      return null;
    }
  }

  /// Get document with signed URL
  Future<DocumentModel?> getDocumentWithUrl(String documentId) async {
    try {
      final response =
          await _supabase
              .from('documents')
              .select()
              .eq('id', documentId)
              .single();

      final document = DocumentModel.fromJson(response);

      // Get signed URL for viewing
      if (document.storagePath != null) {
        final signedUrl = await _storageService.getSignedUrl(
          document.storagePath!,
          expiresIn: 3600, // 1 hour
        );

        // Update document with signed URL
        return document.copyWith(remoteUrl: signedUrl);
      }

      return document;
    } catch (e) {
      print('Get document error: $e');
      return null;
    }
  }

  /// Approve or reject document
  Future<bool> reviewDocument({
    required String documentId,
    required String reviewerId,
    required bool isApproved,
    String? reviewNotes,
    List<String>? rejectionReasons,
  }) async {
    try {
      // Call the stored procedure
      await _supabase.rpc(
        'approve_document',
        params: {
          'doc_id': documentId,
          'reviewer_id': reviewerId,
          'approval_status': isApproved,
          'review_notes': reviewNotes,
          'rejection_reasons': rejectionReasons,
        },
      );

      return true;
    } catch (e) {
      print('Review document error: $e');
      return false;
    }
  }

  /// Get user documents with approval status
  Future<List<DocumentModel>> getUserDocuments(String userId) async {
    try {
      final response = await _supabase
          .from('document_summary')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response
          .map<DocumentModel>((json) => DocumentModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Get user documents error: $e');
      return [];
    }
  }

  /// Get documents by claim ID
  Future<List<DocumentModel>> getDocumentsByClaim(String claimId) async {
    try {
      final response = await _supabase
          .from('documents')
          .select()
          .eq('claim_id', claimId)
          .order('created_at', ascending: false);

      return response
          .map<DocumentModel>((json) => DocumentModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Get claim documents error: $e');
      return [];
    }
  }

  /// Delete document (removes from storage and database)
  Future<bool> deleteDocument(String documentId) async {
    try {
      // 1. Get document info
      final document = await getDocumentWithUrl(documentId);
      if (document == null) return false;

      // 2. Delete from storage
      if (document.storagePath != null) {
        await _storageService.deleteFile(document.storagePath!);
      }

      // 3. Delete from database
      await _supabase.from('documents').delete().eq('id', documentId);

      return true;
    } catch (e) {
      print('Delete document error: $e');
      return false;
    }
  }

  /// Update document status
  Future<DocumentModel?> updateDocumentStatus(
    String documentId,
    DocumentStatus newStatus, {
    String? errorMessage,
    String? uploadProgress,
  }) async {
    try {
      final response =
          await _supabase
              .from('documents')
              .update({
                'status': newStatus.key,
                'error_message': errorMessage,
                'upload_progress': uploadProgress,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', documentId)
              .select()
              .single();

      return DocumentModel.fromJson(response);
    } catch (e) {
      print('Update document status error: $e');
      return null;
    }
  }

  /// Create a new document from a file
  static DocumentModel createDocumentFromFile({
    required File file,
    required DocumentType type,
    String? userId,
    String? claimId,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return DocumentModel.fromFile(
      id: _uuid.v4(),
      userId: userId,
      assessmentId: claimId, // Maps to claimId in database
      type: type,
      file: file,
      description: description,
      metadata: metadata,
    );
  }

  /// Update document status (static version)
  static DocumentModel updateDocumentStatusLocal(
    DocumentModel document,
    DocumentStatus newStatus, {
    String? errorMessage,
    String? uploadProgress,
  }) {
    return document.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
      errorMessage: errorMessage,
      uploadProgress: uploadProgress,
    );
  }

  /// Update document with remote URL after upload
  static DocumentModel updateDocumentWithRemoteUrl(
    DocumentModel document,
    String remoteUrl,
  ) {
    return document.copyWith(
      remoteUrl: remoteUrl,
      status: DocumentStatus.uploaded,
      updatedAt: DateTime.now(),
    );
  }

  /// Get required document types for insurance claims
  static List<DocumentType> getRequiredDocumentTypes() {
    return DocumentType.values.where((type) => type.isRequired).toList();
  }

  /// Get optional document types for insurance claims
  static List<DocumentType> getOptionalDocumentTypes() {
    return DocumentType.values.where((type) => !type.isRequired).toList();
  }

  /// Validate document file (static method)
  static DocumentValidationResult validateDocument(
    File file,
    DocumentType type,
  ) {
    final errors = <String>[];
    final warnings = <String>[];

    // Check if file exists
    if (!file.existsSync()) {
      errors.add('File does not exist');
      return DocumentValidationResult(
        isValid: false,
        errors: errors,
        warnings: warnings,
      );
    }

    // Check file size (max 10MB)
    const maxSizeBytes = 10 * 1024 * 1024; // 10MB
    final fileSize = file.lengthSync();
    if (fileSize > maxSizeBytes) {
      errors.add('File size exceeds 10MB limit');
    }

    // Check file format
    final format = DocumentFormat.fromFilePath(file.path);
    if (format == DocumentFormat.unknown) {
      errors.add('Unsupported file format');
    }

    // Specific validations per document type
    switch (type) {
      case DocumentType.driversLicense:
      case DocumentType.ownerValidId:
        if (!format.isImage && format != DocumentFormat.pdf) {
          warnings.add(
            'ID documents should preferably be PDF or image files for better processing',
          );
        }
        break;
      case DocumentType.damagePhotos:
        if (!format.isImage) {
          errors.add('Damage photos must be image files');
        }
        break;
      case DocumentType.ltoOR:
      case DocumentType.ltoCR:
      case DocumentType.insurancePolicy:
      case DocumentType.jobEstimate:
        if (format != DocumentFormat.pdf && !format.isImage) {
          warnings.add('Document should preferably be PDF or image format');
        }
        break;
      case DocumentType.policeReport:
        if (format != DocumentFormat.pdf && !format.isImage) {
          warnings.add('Police report should preferably be PDF format');
        }
        break;
      case DocumentType.stencilStrips:
        // Accept any format for stencil strips
        break;
      default:
        break;
    }

    // Warn about large files
    if (fileSize > 5 * 1024 * 1024) {
      // 5MB
      warnings.add('Large file size may result in slower upload');
    }

    return DocumentValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      fileSize: fileSize,
    );
  }

  /// Check if all required documents are present in a collection
  static bool areAllRequiredDocumentsPresent(DocumentCollection collection) {
    final requiredTypes = getRequiredDocumentTypes();

    for (final type in requiredTypes) {
      final documents = collection.getDocumentsByType(type);
      if (documents.isEmpty || !documents.any((doc) => doc.isUploaded)) {
        return false;
      }
    }

    return true;
  }

  /// Get missing required documents from a collection
  static List<DocumentType> getMissingRequiredDocuments(
    DocumentCollection collection,
  ) {
    final requiredTypes = getRequiredDocumentTypes();
    final missing = <DocumentType>[];

    for (final type in requiredTypes) {
      final documents = collection.getDocumentsByType(type);
      if (documents.isEmpty || !documents.any((doc) => doc.isUploaded)) {
        missing.add(type);
      }
    }

    return missing;
  }

  /// Create a document collection from a list of files organized by type
  static DocumentCollection createDocumentCollection(
    Map<String, List<File>> filesByType, {
    String? userId,
    String? claimId,
  }) {
    final collection = DocumentCollection();

    for (final entry in filesByType.entries) {
      final type = DocumentType.fromKey(entry.key);
      for (final file in entry.value) {
        final document = createDocumentFromFile(
          file: file,
          type: type,
          userId: userId,
          claimId: claimId,
        );
        collection.addDocument(document);
      }
    }

    return collection;
  }

  /// Get document upload progress summary for a collection
  static DocumentUploadSummary getUploadSummary(DocumentCollection collection) {
    final allDocs = collection.allDocuments;
    final totalCount = allDocs.length;
    final uploadedCount = allDocs.where((doc) => doc.isUploaded).length;
    final failedCount = allDocs.where((doc) => doc.hasFailed).length;
    final processingCount = allDocs.where((doc) => doc.isProcessing).length;

    final requiredDocs = collection.requiredDocuments;
    final requiredUploadedCount =
        requiredDocs.where((doc) => doc.isUploaded).length;

    return DocumentUploadSummary(
      totalCount: totalCount,
      uploadedCount: uploadedCount,
      failedCount: failedCount,
      processingCount: processingCount,
      requiredCount: requiredDocs.length,
      requiredUploadedCount: requiredUploadedCount,
      isComplete: collection.allRequiredDocumentsUploaded,
    );
  }

  /// Generate thumbnail path for image documents
  static String generateThumbnailPath(String originalPath) {
    final pathParts = originalPath.split('.');
    final extension = pathParts.last;
    final basePath = pathParts.sublist(0, pathParts.length - 1).join('.');
    return '${basePath}_thumb.$extension';
  }

  /// Extract metadata from file
  static Map<String, dynamic> extractFileMetadata(File file) {
    final stat = file.statSync();
    return {
      'created': stat.modified.toIso8601String(),
      'size': stat.size,
      'path': file.path,
      'name': file.path.split('/').last,
    };
  }
}

/// Result of document validation
class DocumentValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final int? fileSize;

  DocumentValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    this.fileSize,
  });

  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;
}

/// Summary of document upload progress
class DocumentUploadSummary {
  final int totalCount;
  final int uploadedCount;
  final int failedCount;
  final int processingCount;
  final int requiredCount;
  final int requiredUploadedCount;
  final bool isComplete;

  DocumentUploadSummary({
    required this.totalCount,
    required this.uploadedCount,
    required this.failedCount,
    required this.processingCount,
    required this.requiredCount,
    required this.requiredUploadedCount,
    required this.isComplete,
  });

  double get uploadProgress {
    if (totalCount == 0) return 0.0;
    return uploadedCount / totalCount;
  }

  double get requiredProgress {
    if (requiredCount == 0) return 1.0;
    return requiredUploadedCount / requiredCount;
  }

  int get pendingCount =>
      totalCount - uploadedCount - failedCount - processingCount;
}
