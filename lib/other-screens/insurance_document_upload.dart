import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:insurevis/services/supabase_service.dart';
import 'package:insurevis/services/claims_service.dart';
import 'package:insurevis/services/documents_service.dart';
import 'package:insurevis/models/document_model.dart';

class InsuranceDocumentUpload extends StatefulWidget {
  final List<String> imagePaths;
  final Map<String, Map<String, dynamic>> apiResponses;
  final Map<String, String> assessmentIds;

  const InsuranceDocumentUpload({
    super.key,
    required this.imagePaths,
    required this.apiResponses,
    required this.assessmentIds,
  });

  @override
  State<InsuranceDocumentUpload> createState() =>
      _InsuranceDocumentUploadState();
}

class _InsuranceDocumentUploadState extends State<InsuranceDocumentUpload> {
  final ImagePicker _picker = ImagePicker();
  final DocumentService _documentService = DocumentService();
  bool _isUploading = false;

  // Document categories and their uploaded files
  Map<String, List<File>> uploadedDocuments = {
    'lto_or': [],
    'lto_cr': [],
    'drivers_license': [],
    'owner_valid_id': [],
    'police_report': [],
    'insurance_policy': [],
    'job_estimate': [],
    'damage_photos': [],
    'stencil_strips': [],
    'additional_documents': [],
  };

  // Required documents checker
  Map<String, bool> requiredDocuments = {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalStyles.backgroundColorStart,
      appBar: AppBar(
        backgroundColor: GlobalStyles.backgroundColorStart,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Upload Documents',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              GlobalStyles.backgroundColorStart,
              GlobalStyles.backgroundColorEnd,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInstructions(),
                    SizedBox(height: 24.h),
                    _buildDocumentCategories(),
                  ],
                ),
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: GlobalStyles.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: GlobalStyles.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: GlobalStyles.primaryColor,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Required Documents',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: GlobalStyles.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Please upload the following documents to process your insurance claim. '
            'All documents marked with * are required. Ensure documents are clear, readable, '
            'and in PDF format when possible (photocopies should be scanned as PDF).',
            style: TextStyle(fontSize: 14.sp, color: Colors.white, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCategories() {
    return Column(
      children: [
        _buildDocumentCategory(
          'LTO O.R (Official Receipt)',
          'lto_or',
          'Upload photocopy/PDF of LTO Official Receipt with number',
          Icons.receipt_long,
          Colors.blue,
        ),
        SizedBox(height: 16.h),
        _buildDocumentCategory(
          'LTO C.R (Certificate of Registration)',
          'lto_cr',
          'Upload photocopy/PDF of LTO Certificate of Registration with number',
          Icons.assignment,
          Colors.green,
        ),
        SizedBox(height: 16.h),
        _buildDocumentCategory(
          'Driver\'s License',
          'drivers_license',
          'Upload photocopy/PDF of driver\'s license',
          Icons.badge,
          Colors.orange,
        ),
        SizedBox(height: 16.h),
        _buildDocumentCategory(
          'Valid ID of Owner',
          'owner_valid_id',
          'Upload photocopy/PDF of owner\'s valid government ID',
          Icons.perm_identity,
          Colors.purple,
        ),
        SizedBox(height: 16.h),
        _buildDocumentCategory(
          'Police Report/Affidavit',
          'police_report',
          'Upload original police report or affidavit',
          Icons.local_police,
          Colors.red,
        ),
        SizedBox(height: 16.h),
        _buildDocumentCategory(
          'Insurance Policy',
          'insurance_policy',
          'Upload photocopy/PDF of your insurance policy',
          Icons.policy,
          Colors.indigo,
        ),
        SizedBox(height: 16.h),
        _buildDocumentCategory(
          'Job Estimate',
          'job_estimate',
          'Upload repair/job estimate from service provider',
          Icons.engineering,
          Colors.brown,
        ),
        SizedBox(height: 16.h),
        _buildDocumentCategory(
          'Pictures of Damage',
          'damage_photos',
          'Upload clear photos showing the damage to your vehicle',
          Icons.photo_camera,
          Colors.teal,
        ),
        SizedBox(height: 16.h),
        _buildDocumentCategory(
          'Stencil Strips',
          'stencil_strips',
          'Upload stencil strips documentation',
          Icons.straighten,
          Colors.cyan,
        ),
        SizedBox(height: 16.h),
        _buildDocumentCategory(
          'Additional Documents',
          'additional_documents',
          'Upload any other relevant documents (Optional)',
          Icons.folder,
          Colors.grey,
        ),
      ],
    );
  }

  Widget _buildDocumentCategory(
    String title,
    String category,
    String description,
    IconData icon,
    Color color,
  ) {
    final isRequired = requiredDocuments[category] ?? false;
    final uploadedFiles = uploadedDocuments[category] ?? [];
    final hasFiles = uploadedFiles.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color:
              hasFiles
                  ? Colors.green.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: color, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (isRequired) ...[
                          SizedBox(width: 4.w),
                          Text(
                            '*',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      description,
                      style: TextStyle(fontSize: 12.sp, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              if (hasFiles)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '${uploadedFiles.length}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),

          // Show uploaded files
          if (hasFiles) ...[
            _buildUploadedFilesList(category, uploadedFiles),
            SizedBox(height: 12.h),
          ],

          // Upload buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickDocument(category),
                  icon: Icon(Icons.upload_file, size: 16.sp),
                  label: Text('Upload File', style: TextStyle(fontSize: 12.sp)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color.withValues(alpha: 0.8),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _takePhoto(category),
                  icon: Icon(Icons.camera_alt, size: 16.sp),
                  label: Text('Take Photo', style: TextStyle(fontSize: 12.sp)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color.withValues(alpha: 0.6),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadedFilesList(String category, List<File> files) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Uploaded Files:',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
          SizedBox(height: 8.h),
          ...files.map((file) => _buildFileItem(category, file)),
        ],
      ),
    );
  }

  Widget _buildFileItem(String category, File file) {
    final fileName = file.path.split('/').last;
    final isImage =
        fileName.toLowerCase().endsWith('.jpg') ||
        fileName.toLowerCase().endsWith('.jpeg') ||
        fileName.toLowerCase().endsWith('.png');

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        children: [
          Icon(
            isImage ? Icons.image : Icons.description,
            color: Colors.white70,
            size: 16.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              fileName,
              style: TextStyle(fontSize: 12.sp, color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () => _removeFile(category, file),
            icon: Icon(Icons.close, color: Colors.red, size: 16.sp),
            constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.h),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    final requiredDocsUploaded = _checkRequiredDocuments();
    final totalUploaded = uploadedDocuments.values.fold<int>(
      0,
      (sum, files) => sum + files.length,
    );

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Documents uploaded: $totalUploaded',
                style: TextStyle(fontSize: 14.sp, color: Colors.white70),
              ),
              Text(
                requiredDocsUploaded
                    ? 'Ready to submit'
                    : 'Missing required docs',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: requiredDocsUploaded ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: requiredDocsUploaded ? _submitClaim : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    requiredDocsUploaded
                        ? GlobalStyles.primaryColor
                        : Colors.grey,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child:
                  _isUploading
                      ? SizedBox(
                        height: 20.h,
                        width: 20.w,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Text(
                        'Submit Insurance Claim',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDocument(String category) async {
    try {
      // Request storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        _showErrorMessage('Storage permission is required to upload documents');
        return;
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          for (var file in result.files) {
            if (file.path != null) {
              uploadedDocuments[category]!.add(File(file.path!));
            }
          }
        });
        _showSuccessMessage('Documents uploaded successfully');
      }
    } catch (e) {
      _showErrorMessage('Error picking document: $e');
    }
  }

  Future<void> _takePhoto(String category) async {
    try {
      // Request camera permission
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        _showErrorMessage('Camera permission is required to take photos');
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          uploadedDocuments[category]!.add(File(image.path));
        });
        _showSuccessMessage('Photo captured successfully');
      }
    } catch (e) {
      _showErrorMessage('Error taking photo: $e');
    }
  }

  void _removeFile(String category, File file) {
    setState(() {
      uploadedDocuments[category]!.remove(file);
    });
    _showSuccessMessage('File removed');
  }

  bool _checkRequiredDocuments() {
    for (String category in requiredDocuments.keys) {
      if (requiredDocuments[category]! &&
          uploadedDocuments[category]!.isEmpty) {
        return false;
      }
    }
    return true;
  }

  Future<void> _submitClaim() async {
    setState(() {
      _isUploading = true;
    });

    try {
      // Get current user
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        _showErrorMessage('Please sign in to submit a claim');
        return;
      }

      // Extract assessment data from widget parameters
      String? incidentDescription;
      double? estimatedCost;

      // Try to extract meaningful data from API responses
      if (widget.apiResponses.isNotEmpty) {
        final firstResponse = widget.apiResponses.values.first;

        // Extract damage information for incident description
        if (firstResponse['damaged_areas'] != null) {
          final damagedAreas = firstResponse['damaged_areas'] as List;
          incidentDescription =
              'Detected damage areas: ${damagedAreas.map((area) => area['name'] ?? area.toString()).join(', ')}';
        }

        // Extract cost estimation
        if (firstResponse['total_cost'] != null) {
          estimatedCost = (firstResponse['total_cost'] as num).toDouble();
        }
      }

      // Create claim using ClaimsService
      final claim = await ClaimsService.createClaim(
        userId: currentUser.id,
        incidentDate: DateTime.now().subtract(
          Duration(days: 1),
        ), // Assume incident was yesterday
        incidentLocation:
            'Location to be specified by user', // Default location
        incidentDescription:
            incidentDescription ??
            'Vehicle damage assessment submitted via InsureVis app',
        estimatedDamageCost: estimatedCost,
      );

      if (claim == null) {
        _showErrorMessage('Failed to create claim. Please try again.');
        return;
      }

      // Upload documents to storage and link to claim
      print('Starting document upload for claim: ${claim.id}');
      bool allUploadsSuccessful = true;
      int totalUploaded = 0;

      for (String docTypeKey in uploadedDocuments.keys) {
        final files = uploadedDocuments[docTypeKey] ?? [];
        if (files.isNotEmpty) {
          print(
            'Uploading ${files.length} files for document type: $docTypeKey',
          );

          // Convert string key to DocumentType enum
          final DocumentType docType = DocumentType.fromKey(docTypeKey);

          // Upload each file individually using the new DocumentService API
          for (File file in files) {
            try {
              final uploadedDocument = await _documentService.uploadDocument(
                file: file,
                type: docType,
                userId: currentUser.id,
                claimId: claim.id, // Using claim ID
                description:
                    'Document uploaded for insurance claim ${claim.claimNumber}',
                isRequired: docType.isRequired,
              );

              if (uploadedDocument != null) {
                print('Successfully uploaded: ${uploadedDocument.fileName}');
                totalUploaded++;
              } else {
                print('Failed to upload file: ${file.path}');
                allUploadsSuccessful = false;
              }
            } catch (e) {
              print('Error uploading file ${file.path}: $e');
              allUploadsSuccessful = false;
            }
          }
        }
      }

      print('Total files uploaded: $totalUploaded');

      if (!allUploadsSuccessful) {
        _showErrorMessage('Some documents failed to upload. Please try again.');
        return;
      }

      // Submit the claim (change status from draft to submitted)
      final submitSuccess = await ClaimsService.submitClaim(claim.id);

      if (!submitSuccess) {
        _showErrorMessage(
          'Claim created but submission failed. Please try again.',
        );
        return;
      }

      if (mounted) {
        _showSuccessDialog(claimNumber: claim.claimNumber);
      }
    } catch (e) {
      print('Error submitting claim: $e');
      _showErrorMessage('Error submitting claim: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showSuccessDialog({String? claimNumber}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 24.sp),
                SizedBox(width: 12.w),
                Text(
                  'Claim Submitted',
                  style: TextStyle(color: Colors.white, fontSize: 18.sp),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your insurance claim has been submitted successfully.',
                  style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                ),
                if (claimNumber != null) ...[
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.confirmation_number,
                          color: Colors.green,
                          size: 16.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Claim #: $claimNumber',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 12.h),
                Text(
                  'You will receive a confirmation email shortly.',
                  style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to previous screen
                },
                child: Text(
                  'OK',
                  style: TextStyle(color: GlobalStyles.primaryColor),
                ),
              ),
            ],
          ),
    );
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
