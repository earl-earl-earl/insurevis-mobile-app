// Models for InsureVis Claims and Documents
// Aligned with the complete database schema

/// Claim model matching the claims table schema
class ClaimModel {
  final String id;
  final String userId;
  final String claimNumber;
  final DateTime incidentDate;
  final String incidentLocation;
  final String incidentDescription;
  final String? vehicleMake;
  final String? vehicleModel;
  final int? vehicleYear;
  final String? vehiclePlateNumber;
  final double? estimatedDamageCost;
  final String status;
  final bool isApprovedByCarCompany;
  final DateTime? carCompanyApprovalDate;
  final String? carCompanyApprovalNotes;
  final bool isApprovedByInsuranceCompany;
  final DateTime? insuranceCompanyApprovalDate;
  final String? insuranceCompanyApprovalNotes;
  final bool isSuccessful;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;

  ClaimModel({
    required this.id,
    required this.userId,
    required this.claimNumber,
    required this.incidentDate,
    required this.incidentLocation,
    required this.incidentDescription,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleYear,
    this.vehiclePlateNumber,
    this.estimatedDamageCost,
    this.status = 'draft',
    this.isApprovedByCarCompany = false,
    this.carCompanyApprovalDate,
    this.carCompanyApprovalNotes,
    this.isApprovedByInsuranceCompany = false,
    this.insuranceCompanyApprovalDate,
    this.insuranceCompanyApprovalNotes,
    this.isSuccessful = false,
    required this.createdAt,
    required this.updatedAt,
    this.submittedAt,
    this.approvedAt,
    this.rejectedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'claim_number': claimNumber,
      'incident_date':
          incidentDate.toIso8601String().split('T')[0], // Date only
      'incident_location': incidentLocation,
      'incident_description': incidentDescription,
      'vehicle_make': vehicleMake,
      'vehicle_model': vehicleModel,
      'vehicle_year': vehicleYear,
      'vehicle_plate_number': vehiclePlateNumber,
      'estimated_damage_cost': estimatedDamageCost,
      'status': status,
      'is_approved_by_car_company': isApprovedByCarCompany,
      'car_company_approval_date': carCompanyApprovalDate?.toIso8601String(),
      'car_company_approval_notes': carCompanyApprovalNotes,
      'is_approved_by_insurance_company': isApprovedByInsuranceCompany,
      'insurance_company_approval_date':
          insuranceCompanyApprovalDate?.toIso8601String(),
      'insurance_company_approval_notes': insuranceCompanyApprovalNotes,
      'is_successful': isSuccessful,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'submitted_at': submittedAt?.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
      'rejected_at': rejectedAt?.toIso8601String(),
    };
  }

  factory ClaimModel.fromJson(Map<String, dynamic> json) {
    return ClaimModel(
      id: json['id'],
      userId: json['user_id'],
      claimNumber: json['claim_number'],
      incidentDate: DateTime.parse(json['incident_date']),
      incidentLocation: json['incident_location'],
      incidentDescription: json['incident_description'],
      vehicleMake: json['vehicle_make'],
      vehicleModel: json['vehicle_model'],
      vehicleYear: json['vehicle_year'],
      vehiclePlateNumber: json['vehicle_plate_number'],
      estimatedDamageCost: json['estimated_damage_cost']?.toDouble(),
      status: json['status'] ?? 'draft',
      isApprovedByCarCompany: json['is_approved_by_car_company'] ?? false,
      carCompanyApprovalDate:
          json['car_company_approval_date'] != null
              ? DateTime.parse(json['car_company_approval_date'])
              : null,
      carCompanyApprovalNotes: json['car_company_approval_notes'],
      isApprovedByInsuranceCompany:
          json['is_approved_by_insurance_company'] ?? false,
      insuranceCompanyApprovalDate:
          json['insurance_company_approval_date'] != null
              ? DateTime.parse(json['insurance_company_approval_date'])
              : null,
      insuranceCompanyApprovalNotes: json['insurance_company_approval_notes'],
      isSuccessful: json['is_successful'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      submittedAt:
          json['submitted_at'] != null
              ? DateTime.parse(json['submitted_at'])
              : null,
      approvedAt:
          json['approved_at'] != null
              ? DateTime.parse(json['approved_at'])
              : null,
      rejectedAt:
          json['rejected_at'] != null
              ? DateTime.parse(json['rejected_at'])
              : null,
    );
  }

  ClaimModel copyWith({
    String? id,
    String? userId,
    String? claimNumber,
    DateTime? incidentDate,
    String? incidentLocation,
    String? incidentDescription,
    String? vehicleMake,
    String? vehicleModel,
    int? vehicleYear,
    String? vehiclePlateNumber,
    double? estimatedDamageCost,
    String? status,
    bool? isApprovedByCarCompany,
    DateTime? carCompanyApprovalDate,
    String? carCompanyApprovalNotes,
    bool? isApprovedByInsuranceCompany,
    DateTime? insuranceCompanyApprovalDate,
    String? insuranceCompanyApprovalNotes,
    bool? isSuccessful,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? submittedAt,
    DateTime? approvedAt,
    DateTime? rejectedAt,
  }) {
    return ClaimModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      claimNumber: claimNumber ?? this.claimNumber,
      incidentDate: incidentDate ?? this.incidentDate,
      incidentLocation: incidentLocation ?? this.incidentLocation,
      incidentDescription: incidentDescription ?? this.incidentDescription,
      vehicleMake: vehicleMake ?? this.vehicleMake,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      vehiclePlateNumber: vehiclePlateNumber ?? this.vehiclePlateNumber,
      estimatedDamageCost: estimatedDamageCost ?? this.estimatedDamageCost,
      status: status ?? this.status,
      isApprovedByCarCompany:
          isApprovedByCarCompany ?? this.isApprovedByCarCompany,
      carCompanyApprovalDate:
          carCompanyApprovalDate ?? this.carCompanyApprovalDate,
      carCompanyApprovalNotes:
          carCompanyApprovalNotes ?? this.carCompanyApprovalNotes,
      isApprovedByInsuranceCompany:
          isApprovedByInsuranceCompany ?? this.isApprovedByInsuranceCompany,
      insuranceCompanyApprovalDate:
          insuranceCompanyApprovalDate ?? this.insuranceCompanyApprovalDate,
      insuranceCompanyApprovalNotes:
          insuranceCompanyApprovalNotes ?? this.insuranceCompanyApprovalNotes,
      isSuccessful: isSuccessful ?? this.isSuccessful,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
    );
  }
}

/// Document model matching the documents table schema
class DocumentModel {
  final String id;
  final String claimId; // MANDATORY claim reference
  final String userId;
  final DocumentType type;
  final String fileName;
  final int? fileSizeBytes;
  final String? format;
  final String? storagePath;
  final String? remoteUrl;
  final bool isPrimary;
  final String? description;
  final String status;
  final bool verifiedByCarCompany;
  final DateTime? carCompanyVerificationDate;
  final String? carCompanyVerificationNotes;
  final String? carCompanyVerifiedBy;
  final bool verifiedByInsuranceCompany;
  final DateTime? insuranceVerificationDate;
  final String? insuranceVerificationNotes;
  final String? insuranceVerifiedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  DocumentModel({
    required this.id,
    required this.claimId,
    required this.userId,
    required this.type,
    required this.fileName,
    this.fileSizeBytes,
    this.format,
    this.storagePath,
    this.remoteUrl,
    this.isPrimary = false,
    this.description,
    this.status = 'uploaded',
    this.verifiedByCarCompany = false,
    this.carCompanyVerificationDate,
    this.carCompanyVerificationNotes,
    this.carCompanyVerifiedBy,
    this.verifiedByInsuranceCompany = false,
    this.insuranceVerificationDate,
    this.insuranceVerificationNotes,
    this.insuranceVerifiedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'claim_id': claimId,
      'user_id': userId,
      'type': type.value,
      'file_name': fileName,
      'file_size_bytes': fileSizeBytes,
      'format': format,
      'storage_path': storagePath,
      'remote_url': remoteUrl,
      'is_primary': isPrimary,
      'description': description,
      'status': status,
      'verified_by_car_company': verifiedByCarCompany,
      'car_company_verification_date':
          carCompanyVerificationDate?.toIso8601String(),
      'car_company_verification_notes': carCompanyVerificationNotes,
      'car_company_verified_by': carCompanyVerifiedBy,
      'verified_by_insurance_company': verifiedByInsuranceCompany,
      'insurance_verification_date':
          insuranceVerificationDate?.toIso8601String(),
      'insurance_verification_notes': insuranceVerificationNotes,
      'insurance_verified_by': insuranceVerifiedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'],
      claimId: json['claim_id'],
      userId: json['user_id'],
      type: DocumentType.fromString(json['type']),
      fileName: json['file_name'],
      fileSizeBytes: json['file_size_bytes'],
      format: json['format'],
      storagePath: json['storage_path'],
      remoteUrl: json['remote_url'],
      isPrimary: json['is_primary'] ?? false,
      description: json['description'],
      status: json['status'] ?? 'uploaded',
      verifiedByCarCompany: json['verified_by_car_company'] ?? false,
      carCompanyVerificationDate:
          json['car_company_verification_date'] != null
              ? DateTime.parse(json['car_company_verification_date'])
              : null,
      carCompanyVerificationNotes: json['car_company_verification_notes'],
      carCompanyVerifiedBy: json['car_company_verified_by'],
      verifiedByInsuranceCompany:
          json['verified_by_insurance_company'] ?? false,
      insuranceVerificationDate:
          json['insurance_verification_date'] != null
              ? DateTime.parse(json['insurance_verification_date'])
              : null,
      insuranceVerificationNotes: json['insurance_verification_notes'],
      insuranceVerifiedBy: json['insurance_verified_by'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

/// Document types enum matching database schema
enum DocumentType {
  ltoOr('lto_or'),
  ltoCr('lto_cr'),
  driversLicense('drivers_license'),
  ownerValidId('owner_valid_id'),
  policeReport('police_report'),
  insurancePolicy('insurance_policy'),
  jobEstimate('job_estimate'),
  damagePhotos('damage_photos'),
  stencilStrips('stencil_strips'),
  additionalDocuments('additional_documents');

  const DocumentType(this.value);
  final String value;

  static DocumentType fromString(String value) {
    return DocumentType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => DocumentType.additionalDocuments,
    );
  }

  String get displayName {
    switch (this) {
      case DocumentType.ltoOr:
        return 'LTO Official Receipt';
      case DocumentType.ltoCr:
        return 'LTO Certificate of Registration';
      case DocumentType.driversLicense:
        return "Driver's License";
      case DocumentType.ownerValidId:
        return 'Owner Valid ID';
      case DocumentType.policeReport:
        return 'Police Report';
      case DocumentType.insurancePolicy:
        return 'Insurance Policy';
      case DocumentType.jobEstimate:
        return 'Job Estimate';
      case DocumentType.damagePhotos:
        return 'Damage Photos';
      case DocumentType.stencilStrips:
        return 'Stencil Strips';
      case DocumentType.additionalDocuments:
        return 'Additional Documents';
    }
  }

  /// Document types that car companies can verify
  static const Set<DocumentType> carCompanyVerifiable = {
    DocumentType.ltoOr,
    DocumentType.ltoCr,
    DocumentType.driversLicense,
    DocumentType.ownerValidId,
    DocumentType.stencilStrips,
    DocumentType.damagePhotos,
    DocumentType.jobEstimate,
  };

  /// Document types that insurance companies can verify
  static const Set<DocumentType> insuranceVerifiable = {
    DocumentType.policeReport,
    DocumentType.insurancePolicy,
    DocumentType.driversLicense,
    DocumentType.ownerValidId,
    DocumentType.jobEstimate,
    DocumentType.damagePhotos,
    DocumentType.ltoOr,
    DocumentType.ltoCr,
    DocumentType.additionalDocuments,
  };

  /// Check if this document type can be verified by car company
  bool get isCarCompanyVerifiable => carCompanyVerifiable.contains(this);

  /// Check if this document type can be verified by insurance company
  bool get isInsuranceVerifiable => insuranceVerifiable.contains(this);
}

/// Claim status enum
enum ClaimStatus {
  draft('draft'),
  submitted('submitted'),
  underReview('under_review'),
  pendingDocuments('pending_documents'),
  approved('approved'),
  rejected('rejected');

  const ClaimStatus(this.value);
  final String value;

  static ClaimStatus fromString(String value) {
    return ClaimStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ClaimStatus.draft,
    );
  }

  String get displayName {
    switch (this) {
      case ClaimStatus.draft:
        return 'Draft';
      case ClaimStatus.submitted:
        return 'Submitted';
      case ClaimStatus.underReview:
        return 'Under Review';
      case ClaimStatus.pendingDocuments:
        return 'Pending Documents';
      case ClaimStatus.approved:
        return 'Approved';
      case ClaimStatus.rejected:
        return 'Rejected';
    }
  }
}

/// Document status enum
enum DocumentStatus {
  uploaded('uploaded'),
  processing('processing'),
  verified('verified'),
  rejected('rejected');

  const DocumentStatus(this.value);
  final String value;

  static DocumentStatus fromString(String value) {
    return DocumentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => DocumentStatus.uploaded,
    );
  }

  String get displayName {
    switch (this) {
      case DocumentStatus.uploaded:
        return 'Uploaded';
      case DocumentStatus.processing:
        return 'Processing';
      case DocumentStatus.verified:
        return 'Verified';
      case DocumentStatus.rejected:
        return 'Rejected';
    }
  }
}
