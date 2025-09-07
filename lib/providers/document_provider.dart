import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/document_model.dart';
import '../services/document_service.dart';
import '../services/document_repository.dart';
import '../services/document_upload_service.dart';

/// Provider class for managing document state in the app
class DocumentProvider extends ChangeNotifier {
  final DocumentRepository _repository = DocumentRepository();
  final DocumentUploadService _uploadService = DocumentUploadService();

  DocumentCollection _documents = DocumentCollection();
  bool _isLoading = false;
  String? _error;

  // Getters
  DocumentCollection get documents => _documents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get documents by type
  List<DocumentModel> getDocumentsByType(DocumentType type) {
    return _documents.getDocumentsByType(type);
  }

  /// Get upload summary
  DocumentUploadSummary get uploadSummary {
    return DocumentService.getUploadSummary(_documents);
  }

  /// Check if all required documents are uploaded
  bool get allRequiredDocumentsUploaded {
    return _documents.allRequiredDocumentsUploaded;
  }

  /// Load documents for a user
  Future<void> loadDocuments(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      final documentsList = await _repository.getDocumentsByUserId(userId);
      _documents.clear();

      for (final doc in documentsList) {
        _documents.addDocument(doc);
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to load documents: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Add a document from file
  Future<DocumentModel?> addDocumentFromFile({
    required File file,
    required DocumentType type,
    String? userId,
    String? assessmentId,
    String? description,
  }) async {
    _clearError();

    try {
      // Validate the document
      final validation = DocumentService.validateDocument(file, type);
      if (!validation.isValid) {
        _setError(
          'Document validation failed: ${validation.errors.join(', ')}',
        );
        return null;
      }

      // Create document model
      final document = DocumentService.createDocumentFromFile(
        file: file,
        type: type,
        userId: userId,
        assessmentId: assessmentId,
        description: description,
        metadata: DocumentService.extractFileMetadata(file),
      );

      // Insert into database
      final insertedDocument = await _repository.insertDocument(document);
      if (insertedDocument != null) {
        _documents.addDocument(insertedDocument);
        notifyListeners();
        return insertedDocument;
      } else {
        _setError('Failed to save document to database');
        return null;
      }
    } catch (e) {
      _setError('Failed to add document: $e');
      return null;
    }
  }

  /// Upload a document to cloud storage
  Future<bool> uploadDocument(DocumentModel document) async {
    _clearError();

    try {
      // Update document status to uploading
      await updateDocumentStatus(document.id, DocumentStatus.uploading);

      // Upload to storage
      final result = await _uploadService.uploadDocument(document);

      if (result.success) {
        // Reload the document to get updated status
        await _refreshDocument(document.id);
        return true;
      } else {
        _setError('Upload failed: ${result.errorMessage}');
        return false;
      }
    } catch (e) {
      _setError('Upload error: $e');
      return false;
    }
  }

  /// Upload multiple documents
  Future<void> uploadMultipleDocuments(
    List<DocumentModel> documentsToUpload, {
    Function(int completed, int total)? onProgress,
  }) async {
    _clearError();

    try {
      final results = await _uploadService.uploadMultipleDocuments(
        documentsToUpload,
        onProgress: onProgress,
      );

      // Refresh all uploaded documents
      for (int i = 0; i < documentsToUpload.length; i++) {
        if (results[i].success) {
          await _refreshDocument(documentsToUpload[i].id);
        }
      }
    } catch (e) {
      _setError('Bulk upload error: $e');
    }
  }

  /// Remove a document
  Future<bool> removeDocument(DocumentModel document) async {
    _clearError();

    try {
      // Delete from storage if it has a remote URL
      if (document.remoteUrl != null) {
        // Extract storage path from remote URL and delete
        // This is simplified - in practice you'd store the storage path
      }

      // Delete from database
      final success = await _repository.deleteDocument(document.id);
      if (success) {
        _documents.removeDocument(document);
        notifyListeners();
        return true;
      } else {
        _setError('Failed to delete document from database');
        return false;
      }
    } catch (e) {
      _setError('Failed to remove document: $e');
      return false;
    }
  }

  /// Update document status
  Future<void> updateDocumentStatus(
    String documentId,
    DocumentStatus status,
  ) async {
    try {
      await _repository.updateDocumentStatus(documentId, status);
      await _refreshDocument(documentId);
    } catch (e) {
      _setError('Failed to update document status: $e');
    }
  }

  /// Get missing required documents
  List<DocumentType> getMissingRequiredDocuments() {
    return DocumentService.getMissingRequiredDocuments(_documents);
  }

  /// Add documents from file map (for compatibility with existing upload screen)
  Future<void> addDocumentsFromFileMap(
    Map<String, List<File>> filesByType, {
    String? userId,
    String? assessmentId,
  }) async {
    _clearError();

    try {
      for (final entry in filesByType.entries) {
        final type = DocumentType.fromKey(entry.key);
        for (final file in entry.value) {
          await addDocumentFromFile(
            file: file,
            type: type,
            userId: userId,
            assessmentId: assessmentId,
          );
        }
      }
    } catch (e) {
      _setError('Failed to add documents from file map: $e');
    }
  }

  /// Convert current documents to file map (for compatibility)
  Map<String, List<File>> toFileMap() {
    final Map<String, List<File>> fileMap = {};

    for (final document in _documents.allDocuments) {
      if (document.file != null) {
        fileMap.putIfAbsent(document.type.key, () => []);
        fileMap[document.type.key]!.add(document.file!);
      }
    }

    return fileMap;
  }

  /// Clear all documents
  void clearDocuments() {
    _documents.clear();
    notifyListeners();
  }

  /// Refresh a specific document from database
  Future<void> _refreshDocument(String documentId) async {
    try {
      final updatedDocument = await _repository.getDocumentById(documentId);
      if (updatedDocument != null) {
        // Remove old version and add updated version
        final oldDocument =
            _documents.allDocuments
                .where((doc) => doc.id == documentId)
                .firstOrNull;

        if (oldDocument != null) {
          _documents.removeDocument(oldDocument);
        }

        _documents.addDocument(updatedDocument);
        notifyListeners();
      }
    } catch (e) {
      print('Error refreshing document: $e');
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _error = null;
  }
}
