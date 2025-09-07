import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/document_model.dart';

/// Repository class for document database operations
class DocumentRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Insert a new document into the database
  Future<DocumentModel?> insertDocument(DocumentModel document) async {
    try {
      final response =
          await _supabase
              .from('documents')
              .insert(document.toJson())
              .select()
              .single();

      return DocumentModel.fromJson(response);
    } catch (e) {
      print('Error inserting document: $e');
      return null;
    }
  }

  /// Update an existing document
  Future<DocumentModel?> updateDocument(DocumentModel document) async {
    try {
      final response =
          await _supabase
              .from('documents')
              .update(document.toJson())
              .eq('id', document.id)
              .select()
              .single();

      return DocumentModel.fromJson(response);
    } catch (e) {
      print('Error updating document: $e');
      return null;
    }
  }

  /// Delete a document
  Future<bool> deleteDocument(String documentId) async {
    try {
      await _supabase.from('documents').delete().eq('id', documentId);

      return true;
    } catch (e) {
      print('Error deleting document: $e');
      return false;
    }
  }

  /// Get documents by user ID
  Future<List<DocumentModel>> getDocumentsByUserId(String userId) async {
    try {
      final response = await _supabase
          .from('documents')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response
          .map<DocumentModel>((json) => DocumentModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching user documents: $e');
      return [];
    }
  }

  /// Get documents by assessment ID
  Future<List<DocumentModel>> getDocumentsByAssessmentId(
    String assessmentId,
  ) async {
    try {
      final response = await _supabase
          .from('documents')
          .select()
          .eq('assessment_id', assessmentId)
          .order('created_at', ascending: false);

      return response
          .map<DocumentModel>((json) => DocumentModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching assessment documents: $e');
      return [];
    }
  }

  /// Get documents by type for a user
  Future<List<DocumentModel>> getDocumentsByType(
    String userId,
    DocumentType type,
  ) async {
    try {
      final response = await _supabase
          .from('documents')
          .select()
          .eq('user_id', userId)
          .eq('type', type.key)
          .order('created_at', ascending: false);

      return response
          .map<DocumentModel>((json) => DocumentModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching documents by type: $e');
      return [];
    }
  }

  /// Get document by ID
  Future<DocumentModel?> getDocumentById(String documentId) async {
    try {
      final response =
          await _supabase
              .from('documents')
              .select()
              .eq('id', documentId)
              .single();

      return DocumentModel.fromJson(response);
    } catch (e) {
      print('Error fetching document by ID: $e');
      return null;
    }
  }

  /// Update document status
  Future<bool> updateDocumentStatus(
    String documentId,
    DocumentStatus status, {
    String? errorMessage,
  }) async {
    try {
      final updateData = {
        'status': status.key,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (errorMessage != null) {
        updateData['error_message'] = errorMessage;
      }

      await _supabase.from('documents').update(updateData).eq('id', documentId);

      return true;
    } catch (e) {
      print('Error updating document status: $e');
      return false;
    }
  }

  /// Update document with remote URL after upload
  Future<bool> updateDocumentRemoteUrl(
    String documentId,
    String remoteUrl,
  ) async {
    try {
      await _supabase
          .from('documents')
          .update({
            'remote_url': remoteUrl,
            'status': DocumentStatus.uploaded.key,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', documentId);

      return true;
    } catch (e) {
      print('Error updating document remote URL: $e');
      return false;
    }
  }

  /// Get documents by status
  Future<List<DocumentModel>> getDocumentsByStatus(
    String userId,
    DocumentStatus status,
  ) async {
    try {
      final response = await _supabase
          .from('documents')
          .select()
          .eq('user_id', userId)
          .eq('status', status.key)
          .order('created_at', ascending: false);

      return response
          .map<DocumentModel>((json) => DocumentModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching documents by status: $e');
      return [];
    }
  }

  /// Get document processing history
  Future<List<Map<String, dynamic>>> getDocumentHistory(
    String documentId,
  ) async {
    try {
      final response = await _supabase
          .from('document_processing_history')
          .select()
          .eq('document_id', documentId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching document history: $e');
      return [];
    }
  }

  /// Add document processing history entry
  Future<bool> addDocumentHistory(
    String documentId,
    String status, {
    String? notes,
  }) async {
    try {
      await _supabase.from('document_processing_history').insert({
        'document_id': documentId,
        'status': status,
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error adding document history: $e');
      return false;
    }
  }

  /// Get document verification data
  Future<Map<String, dynamic>?> getDocumentVerification(
    String documentId,
  ) async {
    try {
      final response =
          await _supabase
              .from('document_verification')
              .select()
              .eq('document_id', documentId)
              .maybeSingle();

      return response;
    } catch (e) {
      print('Error fetching document verification: $e');
      return null;
    }
  }

  /// Update document verification
  Future<bool> updateDocumentVerification({
    required String documentId,
    required bool isVerified,
    String? verificationMethod,
    double? confidenceScore,
    Map<String, dynamic>? extractedData,
    String? verificationNotes,
  }) async {
    try {
      final data = {
        'document_id': documentId,
        'is_verified': isVerified,
        'verification_method': verificationMethod,
        'confidence_score': confidenceScore,
        'extracted_data': extractedData,
        'verification_notes': verificationNotes,
        'verified_at': isVerified ? DateTime.now().toIso8601String() : null,
      };

      // Try to update first, if no rows affected, insert
      final updateResponse = await _supabase
          .from('document_verification')
          .update(data)
          .eq('document_id', documentId);

      // If update didn't affect any rows, insert new record
      if (updateResponse.data?.isEmpty ?? true) {
        await _supabase.from('document_verification').insert(data);
      }

      return true;
    } catch (e) {
      print('Error updating document verification: $e');
      return false;
    }
  }

  /// Get documents grouped by type for a user
  Future<Map<DocumentType, List<DocumentModel>>> getDocumentsGroupedByType(
    String userId,
  ) async {
    try {
      final documents = await getDocumentsByUserId(userId);
      final Map<DocumentType, List<DocumentModel>> grouped = {};

      for (final document in documents) {
        grouped.putIfAbsent(document.type, () => []);
        grouped[document.type]!.add(document);
      }

      return grouped;
    } catch (e) {
      print('Error grouping documents by type: $e');
      return {};
    }
  }

  /// Count documents by status for a user
  Future<Map<DocumentStatus, int>> countDocumentsByStatus(String userId) async {
    try {
      final documents = await getDocumentsByUserId(userId);
      final Map<DocumentStatus, int> counts = {};

      for (final status in DocumentStatus.values) {
        counts[status] = 0;
      }

      for (final document in documents) {
        counts[document.status] = (counts[document.status] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      print('Error counting documents by status: $e');
      return {};
    }
  }

  /// Check if user has all required documents uploaded
  Future<bool> hasAllRequiredDocuments(String userId) async {
    try {
      final requiredTypes = DocumentType.values.where(
        (type) => type.isRequired,
      );

      for (final type in requiredTypes) {
        final docs = await getDocumentsByType(userId, type);
        if (docs.isEmpty || !docs.any((doc) => doc.isUploaded)) {
          return false;
        }
      }

      return true;
    } catch (e) {
      print('Error checking required documents: $e');
      return false;
    }
  }

  /// Get missing required document types for a user
  Future<List<DocumentType>> getMissingRequiredDocuments(String userId) async {
    try {
      final requiredTypes = DocumentType.values.where(
        (type) => type.isRequired,
      );
      final missing = <DocumentType>[];

      for (final type in requiredTypes) {
        final docs = await getDocumentsByType(userId, type);
        if (docs.isEmpty || !docs.any((doc) => doc.isUploaded)) {
          missing.add(type);
        }
      }

      return missing;
    } catch (e) {
      print('Error getting missing required documents: $e');
      return [];
    }
  }
}
