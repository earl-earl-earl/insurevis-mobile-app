import 'package:insurevis/models/insurevis_models.dart';
import 'package:insurevis/global_ui_variables.dart';

/// Utilities for handling claim details operations
class ClaimDetailsHandlerUtils {
  /// Required documents configuration
  static const Map<String, bool> requiredDocuments = {
    'lto_or': true,
    'lto_cr': true,
    'drivers_license': true,
    'owner_valid_id': true,
    'police_report': true,
    'insurance_policy': true,
    'job_estimate': true,
    'damage_photos': true,
    'stencil_strips': true,
    'additional_documents': false,
  };

  /// Map of rejection reason codes to friendly descriptions
  static const Map<String, String> rejectionReasonMap = {
    'document_illegible': 'Document is illegible or unclear',
    'document_expired': 'Document is expired',
    'document_incomplete': 'Document is incomplete',
    'document_forged': 'Document appears to be forged',
    'document_wrong_type': 'Wrong document type submitted',
    'document_mismatch': 'Document information doesn\'t match claim',
  };

  /// Check if a document is PDF
  static bool isPdf(DocumentModel doc) {
    final name = doc.fileName.toLowerCase();
    if (name.endsWith('.pdf')) return true;
    final fmt = doc.format?.toLowerCase();
    return fmt == 'pdf';
  }

  /// Check if a document is an image
  static bool isImage(DocumentModel doc) {
    final name = doc.fileName.toLowerCase();
    return name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png');
  }

  /// Format rejection note
  static String formatRejectionNote(String? note) {
    if (note == null || note.trim().isEmpty) return '';
    final parts =
        note
            .split(RegExp(r'[;,|\n]'))
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)
            .toList();
    final mapped = parts.map((p) => rejectionReasonMap[p] ?? p).toList();
    return mapped.join(', ');
  }

  /// Get document status info
  static Map<String, dynamic> getDocumentStatusInfo(DocumentModel doc) {
    final isApproved =
        doc.verifiedByCarCompany && doc.verifiedByInsuranceCompany;
    final carRejected =
        (doc.carCompanyVerificationNotes != null &&
            doc.carCompanyVerificationNotes!.trim().isNotEmpty);
    final insRejected =
        (doc.insuranceVerificationNotes != null &&
            doc.insuranceVerificationNotes!.trim().isNotEmpty);
    final isRejected = carRejected || insRejected;
    final isAppealed = doc.status.toLowerCase() == 'appealed';

    if (isRejected) {
      return {'text': 'Rejected', 'color': GlobalStyles.errorMain};
    }
    if (isAppealed) {
      return {'text': 'Appealed', 'color': GlobalStyles.purpleMain};
    }
    if (isApproved) {
      return {'text': 'Approved', 'color': GlobalStyles.successMain};
    }

    return {'text': 'Pending', 'color': GlobalStyles.warningMain};
  }

  /// Get party status info (car company or insurance)
  static Map<String, dynamic> getPartyStatusInfo(
    DocumentModel doc,
    bool isCarCompany,
  ) {
    if (isCarCompany) {
      final rejected =
          doc.carCompanyVerificationNotes != null &&
          doc.carCompanyVerificationNotes!.trim().isNotEmpty;
      if (rejected) {
        return {
          'text': 'Rejected',
          'color': GlobalStyles.errorMain,
          'note': doc.carCompanyVerificationNotes,
        };
      }
      if (doc.verifiedByCarCompany) {
        return {
          'text': 'Approved',
          'color': GlobalStyles.successMain,
          'note': null,
        };
      }
      if (doc.status.toLowerCase() == 'appealed') {
        return {
          'text': 'Appealed',
          'color': GlobalStyles.purpleMain,
          'note': null,
        };
      }
      return {
        'text': 'Pending',
        'color': GlobalStyles.warningMain,
        'note': null,
      };
    } else {
      final rejected =
          doc.insuranceVerificationNotes != null &&
          doc.insuranceVerificationNotes!.trim().isNotEmpty;
      if (rejected) {
        return {
          'text': 'Rejected',
          'color': GlobalStyles.errorMain,
          'note': doc.insuranceVerificationNotes,
        };
      }
      if (doc.verifiedByInsuranceCompany) {
        return {
          'text': 'Approved',
          'color': GlobalStyles.successMain,
          'note': null,
        };
      }
      if (doc.status.toLowerCase() == 'appealed') {
        return {
          'text': 'Appealed',
          'color': GlobalStyles.purpleMain,
          'note': null,
        };
      }
      return {
        'text': 'Pending',
        'color': GlobalStyles.warningMain,
        'note': null,
      };
    }
  }

  /// Validate if there are missing required documents
  static List<String> getMissingDocuments(
    Map<String, List<DocumentModel>> categorizedDocuments,
    Map<String, List<dynamic>> newCategorizedDocuments,
  ) {
    final missingDocuments = <String>[];

    for (var entry in requiredDocuments.entries) {
      if (entry.value) {
        final category = entry.key;
        final existingDocs = categorizedDocuments[category] ?? [];
        final newDocs = newCategorizedDocuments[category] ?? [];

        if (existingDocs.isEmpty && newDocs.isEmpty) {
          String displayName = category
              .replaceAll('_', ' ')
              .split(' ')
              .map((word) => word[0].toUpperCase() + word.substring(1))
              .join(' ');
          missingDocuments.add(displayName);
        }
      }
    }

    return missingDocuments;
  }

  /// Check if there are unsaved changes
  static bool hasUnsavedChanges({
    required String currentMake,
    required String originalMake,
    required String currentModel,
    required String originalModel,
    required String currentYear,
    required String originalYear,
    required String currentPlateNumber,
    required String originalPlateNumber,
    required Map<String, List<dynamic>> newDocuments,
    required Set<String> deletedDocumentIds,
  }) {
    if (currentMake != originalMake) return true;
    if (currentModel != originalModel) return true;
    if (currentYear != originalYear) return true;
    if (currentPlateNumber != originalPlateNumber) return true;

    for (var docs in newDocuments.values) {
      if (docs.isNotEmpty) return true;
    }

    if (deletedDocumentIds.isNotEmpty) return true;

    return false;
  }

  /// Get display name for document category
  static String getDocumentCategoryDisplayName(String category) {
    return category
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
