import 'dart:io';

/// Enum representing different types of documents that can be uploaded
enum DocumentType {
  // Required documents for insurance claims
  ltoOR('lto_or', 'LTO O.R (Official Receipt)', true),
  ltoCR('lto_cr', 'LTO C.R (Certificate of Registration)', true),
  driversLicense('drivers_license', 'Driver\'s License', true),
  ownerValidId('owner_valid_id', 'Valid ID of Owner', true),
  policeReport('police_report', 'Police Report/Affidavit', true),
  insurancePolicy('insurance_policy', 'Insurance Policy', true),
  jobEstimate('job_estimate', 'Job Estimate', true),
  damagePhotos('damage_photos', 'Pictures of Damage', true),
  stencilStrips('stencil_strips', 'Stencil Strips', true),

  // Optional additional documents
  additionalDocuments('additional_documents', 'Additional Documents', false);

  const DocumentType(this.key, this.displayName, this.isRequired);

  final String key;
  final String displayName;
  final bool isRequired;

  static DocumentType fromKey(String key) {
    return DocumentType.values.firstWhere(
      (type) => type.key == key,
      orElse: () => DocumentType.additionalDocuments,
    );
  }
}

/// Enum representing the current status of a document
enum DocumentStatus {
  pending('pending', 'Pending Upload'),
  uploading('uploading', 'Uploading'),
  uploaded('uploaded', 'Uploaded'),
  processing('processing', 'Processing'),
  verified('verified', 'Verified'),
  rejected('rejected', 'Rejected'),
  failed('failed', 'Upload Failed'),
  approved('approved', 'Approved');

  const DocumentStatus(this.key, this.displayName);

  final String key;
  final String displayName;

  static DocumentStatus fromKey(String key) {
    return DocumentStatus.values.firstWhere(
      (type) => type.key == key,
      orElse: () => DocumentStatus.pending,
    );
  }
}

/// Enum representing the review status of a document
enum ReviewStatus {
  pending('pending', 'Pending Review'),
  underReview('under_review', 'Under Review'),
  approved('approved', 'Approved'),
  rejected('rejected', 'Rejected'),
  requiresResubmission('requires_resubmission', 'Requires Resubmission');

  const ReviewStatus(this.key, this.displayName);

  final String key;
  final String displayName;

  static ReviewStatus fromKey(String key) {
    return ReviewStatus.values.firstWhere(
      (status) => status.key == key,
      orElse: () => ReviewStatus.pending,
    );
  }
}

/// Enum representing the file format of the document
enum DocumentFormat {
  pdf('pdf', 'PDF Document'),
  jpeg('jpeg', 'JPEG Image'),
  jpg('jpg', 'JPG Image'),
  png('png', 'PNG Image'),
  doc('doc', 'Word Document'),
  docx('docx', 'Word Document'),
  unknown('unknown', 'Unknown Format');

  const DocumentFormat(this.extension, this.displayName);

  final String extension;
  final String displayName;

  static DocumentFormat fromExtension(String extension) {
    final ext = extension.toLowerCase().replaceAll('.', '');
    return DocumentFormat.values.firstWhere(
      (format) => format.extension == ext,
      orElse: () => DocumentFormat.unknown,
    );
  }

  static DocumentFormat fromFilePath(String filePath) {
    final extension = filePath.split('.').last;
    return fromExtension(extension);
  }

  bool get isImage =>
      this == DocumentFormat.jpeg ||
      this == DocumentFormat.jpg ||
      this == DocumentFormat.png;
}

/// Main document model representing an uploaded or to-be-uploaded document
class DocumentModel {
  final String id;
  final String? userId;
  final String? assessmentId;
  final DocumentType type;
  final String fileName;
  final String? filePath;
  final String? remoteUrl;
  final DocumentFormat format;
  final DocumentStatus status;
  final int? fileSizeBytes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;
  final Map<String, dynamic>? metadata;
  final String? uploadProgress;
  final String? errorMessage;
  final String? thumbnailPath;
  final bool isRequired;

  // New fields for Supabase storage and approval
  final String? bucketName;
  final String? storagePath;
  final String? publicUrl;
  final bool isApproved;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final ReviewStatus reviewStatus;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewNotes;

  DocumentModel({
    required this.id,
    this.userId,
    this.assessmentId,
    required this.type,
    required this.fileName,
    this.filePath,
    this.remoteUrl,
    required this.format,
    required this.status,
    this.fileSizeBytes,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.metadata,
    this.uploadProgress,
    this.errorMessage,
    this.thumbnailPath,
    required this.isRequired,
    this.bucketName,
    this.storagePath,
    this.publicUrl,
    this.isApproved = false,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.reviewStatus = ReviewStatus.pending,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewNotes,
  });

  /// Create a document model from a local file
  factory DocumentModel.fromFile({
    required String id,
    String? userId,
    String? assessmentId,
    required DocumentType type,
    required File file,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    final fileName = file.path.split('/').last;
    final format = DocumentFormat.fromFilePath(file.path);
    final now = DateTime.now();

    return DocumentModel(
      id: id,
      userId: userId,
      assessmentId: assessmentId,
      type: type,
      fileName: fileName,
      filePath: file.path,
      format: format,
      status: DocumentStatus.pending,
      fileSizeBytes: file.lengthSync(),
      createdAt: now,
      updatedAt: now,
      description: description,
      metadata: metadata,
      isRequired: type.isRequired,
      bucketName: 'insurevis-documents',
      reviewStatus: ReviewStatus.pending,
      isApproved: false,
    );
  }

  /// Create a document model from JSON (for database/API operations)
  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      assessmentId:
          json['claim_id'] as String?, // Note: claim_id maps to assessmentId
      type: DocumentType.fromKey(json['type'] as String),
      fileName: json['file_name'] as String,
      filePath: null, // Not stored in database
      remoteUrl: json['remote_url'] as String?,
      format: DocumentFormat.fromExtension(json['format'] as String? ?? ''),
      status: DocumentStatus.fromKey(json['status'] as String? ?? 'uploaded'),
      fileSizeBytes: json['file_size_bytes'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      description: json['description'] as String?,
      metadata: null, // Not in current schema
      uploadProgress: null, // Not in current schema
      errorMessage: null, // Not in current schema
      thumbnailPath: null, // Not in current schema
      isRequired: false, // Determined by DocumentType
      bucketName: 'insurevis-documents', // Hardcoded
      storagePath: json['storage_path'] as String?,
      publicUrl: null, // Not in current schema
      isApproved:
          json['verified_by_car_company'] as bool? ??
          false, // Map to car company verification
      approvedBy: json['car_company_verified_by'] as String?,
      approvedAt:
          json['car_company_verification_date'] != null
              ? DateTime.parse(json['car_company_verification_date'] as String)
              : null,
      rejectionReason: null, // Not in current schema
      reviewStatus:
          (json['verified_by_car_company'] as bool? ?? false)
              ? ReviewStatus.approved
              : ReviewStatus.pending,
      reviewedBy: json['car_company_verified_by'] as String?,
      reviewedAt:
          json['car_company_verification_date'] != null
              ? DateTime.parse(json['car_company_verification_date'] as String)
              : null,
      reviewNotes: json['car_company_verification_notes'] as String?,
    );
  }

  /// Convert document model to JSON (for database/API operations)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'claim_id': assessmentId, // Note: assessment_id maps to claim_id in DB
      'type': type.key,
      'file_name': fileName,
      'file_size_bytes': fileSizeBytes,
      'format': format.extension,
      'storage_path': storagePath,
      'remote_url': remoteUrl, // Use the actual remote URL field
      'is_primary':
          type.isRequired, // Required documents are primary, additional ones are not
      'description':
          description ??
          'Document uploaded for insurance claim ${assessmentId ?? 'general'}',
      'status': status.key,
      'verified_by_car_company': isApproved, // Use the isApproved field
      'car_company_verification_date': approvedAt?.toIso8601String(),
      'car_company_verification_notes': reviewNotes,
      'car_company_verified_by': approvedBy,
      'verified_by_insurance_company':
          false, // Default to false for new uploads
      'insurance_verification_date': null,
      'insurance_verification_notes': null,
      'insurance_verified_by': null,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of the document with updated properties
  DocumentModel copyWith({
    String? id,
    String? userId,
    String? assessmentId,
    DocumentType? type,
    String? fileName,
    String? filePath,
    String? remoteUrl,
    DocumentFormat? format,
    DocumentStatus? status,
    int? fileSizeBytes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    Map<String, dynamic>? metadata,
    String? uploadProgress,
    String? errorMessage,
    String? thumbnailPath,
    bool? isRequired,
    String? bucketName,
    String? storagePath,
    String? publicUrl,
    bool? isApproved,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    ReviewStatus? reviewStatus,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? reviewNotes,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      assessmentId: assessmentId ?? this.assessmentId,
      type: type ?? this.type,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      format: format ?? this.format,
      status: status ?? this.status,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      errorMessage: errorMessage ?? this.errorMessage,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      isRequired: isRequired ?? this.isRequired,
      bucketName: bucketName ?? this.bucketName,
      storagePath: storagePath ?? this.storagePath,
      publicUrl: publicUrl ?? this.publicUrl,
      isApproved: isApproved ?? this.isApproved,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewNotes: reviewNotes ?? this.reviewNotes,
    );
  }

  /// Get formatted file size as a human-readable string
  String get formattedFileSize {
    if (fileSizeBytes == null) return 'Unknown size';

    const int kb = 1024;
    const int mb = kb * 1024;
    const int gb = mb * 1024;

    if (fileSizeBytes! >= gb) {
      return '${(fileSizeBytes! / gb).toStringAsFixed(2)} GB';
    } else if (fileSizeBytes! >= mb) {
      return '${(fileSizeBytes! / mb).toStringAsFixed(2)} MB';
    } else if (fileSizeBytes! >= kb) {
      return '${(fileSizeBytes! / kb).toStringAsFixed(2)} KB';
    } else {
      return '$fileSizeBytes bytes';
    }
  }

  /// Check if the document is uploaded successfully
  bool get isUploaded =>
      status == DocumentStatus.uploaded ||
      status == DocumentStatus.processing ||
      status == DocumentStatus.verified;

  /// Check if the document upload failed
  bool get hasFailed =>
      status == DocumentStatus.failed || status == DocumentStatus.rejected;

  /// Check if the document is currently being processed
  bool get isProcessing =>
      status == DocumentStatus.uploading || status == DocumentStatus.processing;

  /// Check if the document is a local file
  bool get isLocal => filePath != null && remoteUrl == null;

  /// Check if the document is stored remotely
  bool get isRemote => remoteUrl != null;

  /// Get the file object if it's a local file
  File? get file => filePath != null ? File(filePath!) : null;

  /// For debugging/logging
  @override
  String toString() {
    return 'DocumentModel{id: $id, type: ${type.displayName}, fileName: $fileName, status: ${status.displayName}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DocumentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Collection model for managing multiple documents
class DocumentCollection {
  final Map<DocumentType, List<DocumentModel>> _documents;

  DocumentCollection() : _documents = {};

  /// Get documents by type
  List<DocumentModel> getDocumentsByType(DocumentType type) {
    return _documents[type] ?? [];
  }

  /// Add a document to the collection
  void addDocument(DocumentModel document) {
    _documents.putIfAbsent(document.type, () => []);
    _documents[document.type]!.add(document);
  }

  /// Remove a document from the collection
  void removeDocument(DocumentModel document) {
    _documents[document.type]?.remove(document);
  }

  /// Get all documents as a flat list
  List<DocumentModel> get allDocuments {
    return _documents.values.expand((docs) => docs).toList();
  }

  /// Get all required documents
  List<DocumentModel> get requiredDocuments {
    return allDocuments.where((doc) => doc.isRequired).toList();
  }

  /// Check if all required documents are uploaded
  bool get allRequiredDocumentsUploaded {
    final requiredTypes = DocumentType.values.where((type) => type.isRequired);
    for (final type in requiredTypes) {
      final docs = getDocumentsByType(type);
      if (docs.isEmpty || !docs.any((doc) => doc.isUploaded)) {
        return false;
      }
    }
    return true;
  }

  /// Get total count of all documents
  int get totalCount => allDocuments.length;

  /// Get count of uploaded documents
  int get uploadedCount => allDocuments.where((doc) => doc.isUploaded).length;

  /// Clear all documents
  void clear() {
    _documents.clear();
  }

  /// Convert to JSON for storage/transmission
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    for (final entry in _documents.entries) {
      json[entry.key.key] = entry.value.map((doc) => doc.toJson()).toList();
    }
    return json;
  }

  /// Create from JSON
  factory DocumentCollection.fromJson(Map<String, dynamic> json) {
    final collection = DocumentCollection();
    for (final entry in json.entries) {
      final docsList = entry.value as List;
      for (final docJson in docsList) {
        collection.addDocument(DocumentModel.fromJson(docJson));
      }
    }
    return collection;
  }
}
