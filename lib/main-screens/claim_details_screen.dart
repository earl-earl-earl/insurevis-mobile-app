import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:insurevis/services/supabase_service.dart';
import 'package:insurevis/helpers/appeal_helper.dart';
import 'package:insurevis/services/storage_service.dart';
import 'package:insurevis/models/insurevis_models.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/services/download_service.dart';
import 'package:insurevis/widgets/image_viewer_page.dart';
import 'package:insurevis/widgets/pdf_viewer_page.dart';
import 'package:insurevis/widgets/vehicle_form.dart';

class ClaimDetailsScreen extends StatefulWidget {
  static const routeName = '/claim_details';

  final ClaimModel claim;
  final Widget Function(String status, Color color)? buildClaimIcon;
  final Color Function(String status)? statusColor;
  final String Function(String status)? formatStatus;
  final String Function(double? amount)? formatCurrency;

  const ClaimDetailsScreen({
    super.key,
    required this.claim,
    this.buildClaimIcon,
    this.statusColor,
    this.formatStatus,
    this.formatCurrency,
  });

  @override
  State<ClaimDetailsScreen> createState() => _ClaimDetailsScreenState();
}

class _ClaimDetailsScreenState extends State<ClaimDetailsScreen> {
  final StorageService _storage = StorageService();
  final DownloadService _downloader = DownloadService();
  final ImagePicker _picker = ImagePicker();

  List<DocumentModel> _documents = [];
  bool _loadingDocs = false;
  String? _docError;
  final Map<String, String?> _signedUrls = {}; // docId -> url
  final Map<String, double> _progress = {}; // docId -> 0..1

  // Categorized documents for editing
  final Map<String, List<DocumentModel>> _categorizedDocuments = {};
  final Map<String, List<File>> _newCategorizedDocuments = {};
  final Set<String> _deletedDocumentIds = {}; // Track deleted document IDs

  // Required documents checker
  final Map<String, bool> _requiredDocuments = {
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

  // Editing state
  bool _isEditing = false;
  bool _isAppeal = false;
  bool _isSaving = false;

  // Vehicle form controllers
  late TextEditingController _vehicleMakeController;
  late TextEditingController _vehicleModelController;
  late TextEditingController _vehicleYearController;
  late TextEditingController _vehiclePlateNumberController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeCategories();
    _loadDocuments();
  }

  void _initializeControllers() {
    _vehicleMakeController = TextEditingController(
      text: widget.claim.vehicleMake,
    );
    _vehicleModelController = TextEditingController(
      text: widget.claim.vehicleModel,
    );
    _vehicleYearController = TextEditingController(
      text: widget.claim.vehicleYear?.toString(),
    );
    _vehiclePlateNumberController = TextEditingController(
      text: widget.claim.vehiclePlateNumber,
    );
  }

  void _initializeCategories() {
    for (var key in _requiredDocuments.keys) {
      _categorizedDocuments[key] = [];
      _newCategorizedDocuments[key] = [];
    }
  }

  @override
  void dispose() {
    _vehicleMakeController.dispose();
    _vehicleModelController.dispose();
    _vehicleYearController.dispose();
    _vehiclePlateNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _loadingDocs = true;
      _docError = null;
    });
    try {
      final data = await SupabaseService.client
          .from('documents')
          .select('*')
          .eq('claim_id', widget.claim.id)
          .order('created_at', ascending: false);

      final docs =
          (data as List)
              .map((j) => DocumentModel.fromJson(j as Map<String, dynamic>))
              .toList();

      // Sort documents by type name ascending
      docs.sort((a, b) => a.type.displayName.compareTo(b.type.displayName));

      // Preload signed URLs for display/download
      for (final d in docs) {
        if (d.storagePath != null && d.storagePath!.isNotEmpty) {
          final url = await _storage.getSignedUrl(
            d.storagePath!,
            expiresIn: 3600,
          );
          _signedUrls[d.id] = url;
        } else if (d.remoteUrl != null) {
          _signedUrls[d.id] = d.remoteUrl;
        } else {
          _signedUrls[d.id] = null;
        }
      }

      // Categorize documents
      _initializeCategories();
      for (final doc in docs) {
        final type = doc.type.value;
        if (_categorizedDocuments.containsKey(type)) {
          _categorizedDocuments[type]!.add(doc);
        } else {
          _categorizedDocuments['additional_documents']!.add(doc);
        }
      }

      setState(() {
        _documents = docs;
        _loadingDocs = false;
      });
    } catch (e) {
      setState(() {
        _docError = 'Failed to load documents';
        _loadingDocs = false;
      });
      if (kDebugMode) print('Error loading documents: $e');
    }
  }

  /// Return status info for a document: status text and color based on verified/rejection flags
  Map<String, dynamic> _documentStatusInfo(DocumentModel doc) {
    // Approved only when BOTH car company and insurance have verified the document
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

    // priority: rejected -> appealed -> approved -> pending
    if (isRejected) {
      return {'text': 'Rejected', 'color': Colors.red};
    }
    if (isAppealed) {
      return {'text': 'Appealed', 'color': Colors.purple};
    }
    if (isApproved) {
      return {'text': 'Approved', 'color': Colors.green};
    }

    // Default to pending (orange) if not yet verified by either party
    return {'text': 'Pending', 'color': Colors.orange};
  }

  // Kept per-party chip widgets instead of a single status pill.

  Map<String, dynamic> _partyStatusInfo(DocumentModel doc, bool isCar) {
    if (isCar) {
      final rejected =
          doc.carCompanyVerificationNotes != null &&
          doc.carCompanyVerificationNotes!.trim().isNotEmpty;
      if (rejected) {
        return {
          'text': 'Rejected',
          'color': Colors.red,
          'note': doc.carCompanyVerificationNotes,
        };
      }
      if (doc.verifiedByCarCompany) {
        return {'text': 'Approved', 'color': Colors.green, 'note': null};
      }
      if (doc.status.toLowerCase() == 'appealed') {
        return {'text': 'Appealed', 'color': Colors.purple, 'note': null};
      }
      return {'text': 'Pending', 'color': Colors.orange, 'note': null};
    } else {
      final rejected =
          doc.insuranceVerificationNotes != null &&
          doc.insuranceVerificationNotes!.trim().isNotEmpty;
      if (rejected) {
        return {
          'text': 'Rejected',
          'color': Colors.red,
          'note': doc.insuranceVerificationNotes,
        };
      }
      if (doc.verifiedByInsuranceCompany) {
        return {'text': 'Approved', 'color': Colors.green, 'note': null};
      }
      if (doc.status.toLowerCase() == 'appealed') {
        return {'text': 'Appealed', 'color': Colors.purple, 'note': null};
      }
      return {'text': 'Pending', 'color': Colors.orange, 'note': null};
    }
  }

  Widget _buildPartyStatusChip(
    DocumentModel doc, {
    required bool isCarCompany,
  }) {
    final info = _partyStatusInfo(doc, isCarCompany);
    final color = info['color'] as Color;
    final text = info['text'] as String;
    final note = info['note'] as String?;

    return GestureDetector(
      onTap: () {
        if (note != null && note.trim().isNotEmpty) {
          final date =
              isCarCompany
                  ? doc.carCompanyVerificationDate
                  : doc.insuranceVerificationDate;
          showDialog<void>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text(
                    isCarCompany
                        ? 'Car Company Rejection'
                        : 'Insurance Rejection',
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (date != null) ...[
                        Text(
                          'Rejected on: ${DateFormat.yMMMd().format(date)}',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 8.h),
                      ],
                      Text(
                        'Reason:',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _formatRejectionNote(note),
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Close'),
                    ),
                  ],
                ),
          );
          return;
        }
        // Show a short info dialog when tapped and no rejection notes present
        showDialog<void>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(
                  isCarCompany ? 'Car Company Status' : 'Insurance Status',
                ),
                content: Text(
                  text == 'Pending' ? 'No verification yet.' : 'Status: $text',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Close'),
                  ),
                ],
              ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color.withAlpha(120)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${isCarCompany ? 'Car Company' : 'Insurance Company'}: $text',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            if (note != null && note.trim().isNotEmpty) ...[
              SizedBox(width: 3.w),
              Icon(
                Icons.info_outline,
                size: 10.sp,
                color: color.withAlpha(180),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Map of rejection reason codes to friendly descriptions
  static const Map<String, String> _rejectionReasonMap = {
    'document_illegible': 'Document is illegible or unclear',
    'document_expired': 'Document is expired',
    'document_incomplete': 'Document is incomplete',
    'document_forged': 'Document appears to be forged',
    'document_wrong_type': 'Wrong document type submitted',
    'document_mismatch': 'Document information doesn\'t match claim',
  };

  String _formatRejectionNote(String? note) {
    if (note == null || note.trim().isEmpty) return '';
    // Some systems store a single code or a comma/delimited list of codes.
    final parts =
        note
            .split(RegExp(r'[;,|\n]'))
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)
            .toList();
    final mapped = parts.map((p) => _rejectionReasonMap[p] ?? p).toList();
    return mapped.join(', ');
  }

  List<Widget> _buildStatusChips(DocumentModel doc) {
    List<Widget> chips = [];
    chips.add(_buildPartyStatusChip(doc, isCarCompany: true));
    chips.add(_buildPartyStatusChip(doc, isCarCompany: false));
    // Add spacing between chips
    List<Widget> spaced = [];
    for (int i = 0; i < chips.length; i++) {
      spaced.add(chips[i]);
      if (i < chips.length - 1) {
        spaced.add(SizedBox(width: 6.w));
      }
    }
    return spaced;
  }

  bool _isPdf(DocumentModel doc) {
    final name = doc.fileName.toLowerCase();
    if (name.endsWith('.pdf')) return true;
    final fmt = doc.format?.toLowerCase();
    return fmt == 'pdf';
  }

  bool _isImage(DocumentModel doc) {
    final name = doc.fileName.toLowerCase();
    return name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png');
  }

  Future<void> _download(DocumentModel doc) async {
    final url = _signedUrls[doc.id];
    if (url == null || url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No download URL available for ${doc.fileName}'),
          ),
        );
      }
      return;
    }

    setState(() {
      _progress[doc.id] = 0.0;
    });

    try {
      await _downloader.ensurePermissions();
      final savedPath = await _downloader.downloadForViewing(
        url: url,
        fileName: doc.fileName,
        onProgress: (received, total) {
          if (total > 0) {
            final value = received / total;
            if (mounted) setState(() => _progress[doc.id] = value);
          }
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Saved to $savedPath')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _progress.remove(doc.id));
    }
  }

  Future<void> _openPdf(DocumentModel doc) async {
    final url = _signedUrls[doc.id];
    if (url == null || url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No URL available to open ${doc.fileName}')),
        );
      }
      return;
    }

    setState(() {
      _progress[doc.id] = 0.0;
    });

    try {
      await _downloader.ensurePermissions();
      final fileName =
          doc.fileName.toLowerCase().endsWith('.pdf')
              ? doc.fileName
              : '${doc.fileName}.pdf';
      final savedPath = await _downloader.downloadForViewing(
        url: url,
        fileName: fileName,
        onProgress: (received, total) {
          if (total > 0) {
            final value = received / total;
            if (mounted) setState(() => _progress[doc.id] = value);
          }
        },
      );

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (_) => PdfViewerPage(
                filePath: savedPath,
                title: doc.type.displayName,
              ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _progress.remove(doc.id));
    }
  }

  Future<void> _pickDocument(String category) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          _newCategorizedDocuments[category]!.addAll(
            result.paths.map((path) => File(path!)).toList(),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
      }
    }
  }

  Future<void> _takePhoto(String category) async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _newCategorizedDocuments[category]!.add(File(photo.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error taking photo: $e')));
      }
    }
  }

  void _removeFile(String category, File file) {
    setState(() {
      _newCategorizedDocuments[category]!.remove(file);
    });
  }

  bool _hasUnsavedChanges() {
    // Check if vehicle info has changed
    if (_vehicleMakeController.text != (widget.claim.vehicleMake ?? ''))
      return true;
    if (_vehicleModelController.text != (widget.claim.vehicleModel ?? ''))
      return true;
    if (_vehicleYearController.text !=
        (widget.claim.vehicleYear?.toString() ?? ''))
      return true;
    if (_vehiclePlateNumberController.text !=
        (widget.claim.vehiclePlateNumber ?? ''))
      return true;

    // Check if any new documents have been added
    for (var docs in _newCategorizedDocuments.values) {
      if (docs.isNotEmpty) return true;
    }

    // Check if any existing documents have been deleted
    if (_deletedDocumentIds.isNotEmpty) return true;

    return false;
  }

  Future<bool> _showDiscardChangesDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Discard Changes?'),
            content: Text(
              'You have unsaved changes. Are you sure you want to discard them?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('Discard'),
              ),
            ],
          ),
    );
    return result ?? false;
  }

  Future<void> _deleteExistingDocument(DocumentModel doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Document?'),
            content: Text('Are you sure you want to delete ${doc.fileName}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      // Delete from storage first
      bool storageDeleted = true;
      if (doc.storagePath != null) {
        try {
          await SupabaseService.client.storage
              .from('insurevis-documents')
              .remove([doc.storagePath!]);
        } catch (storageError) {
          storageDeleted = false;
          print('Failed to delete from storage: $storageError');
          // Don't proceed with database deletion if storage deletion failed
          throw Exception(
            'Failed to delete file from storage. Database record preserved.',
          );
        }
      }

      // Only delete from database if storage deletion succeeded
      if (storageDeleted) {
        await SupabaseService.client
            .from('documents')
            .delete()
            .eq('id', doc.id);
      }

      setState(() {
        _deletedDocumentIds.add(doc.id); // Track the deletion
        _documents.removeWhere((d) => d.id == doc.id);
        // Also remove from categorized list
        final type = doc.type.value;
        if (_categorizedDocuments.containsKey(type)) {
          _categorizedDocuments[type]!.removeWhere((d) => d.id == doc.id);
        } else {
          _categorizedDocuments['additional_documents']?.removeWhere(
            (d) => d.id == doc.id,
          );
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Document deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting document: $e')));
      }
    }
  }

  Future<void> _saveClaim() async {
    if (_isSaving) return;

    // Check if there are any changes
    if (!_hasUnsavedChanges()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isAppeal
                  ? 'Please make changes to your documents before appealing'
                  : 'No changes to save',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Validate required documents
    final missingDocuments = <String>[];

    for (var entry in _requiredDocuments.entries) {
      if (entry.value) {
        // If document is required
        final category = entry.key;
        final existingDocs = _categorizedDocuments[category] ?? [];
        final newDocs = _newCategorizedDocuments[category] ?? [];

        if (existingDocs.isEmpty && newDocs.isEmpty) {
          // Get display name for the category
          String displayName = category
              .replaceAll('_', ' ')
              .split(' ')
              .map((word) => word[0].toUpperCase() + word.substring(1))
              .join(' ');
          missingDocuments.add(displayName);
        }
      }
    }

    if (missingDocuments.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please upload all required documents:\n${missingDocuments.join(', ')}',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception('User not logged in');

      // 1. Update Claim Details (including vehicle info)
      final updates = {
        'vehicle_make': _vehicleMakeController.text,
        'vehicle_model': _vehicleModelController.text,
        'vehicle_year': int.tryParse(_vehicleYearController.text),
        'vehicle_plate_number': _vehiclePlateNumberController.text,
      };

      if (_isAppeal) {
        final appealUpdates = buildAppealUpdates(widget.claim);
        updates.addAll(appealUpdates);
      }

      await SupabaseService.client
          .from('claims')
          .update(updates)
          .eq('id', widget.claim.id);

      // 2. Upload New Documents
      for (var entry in _newCategorizedDocuments.entries) {
        final category = entry.key;
        final files = entry.value;

        for (var i = 0; i < files.length; i++) {
          final file = files[i];
          final bytes = await file.readAsBytes();
          final fileName = file.path.split(Platform.pathSeparator).last;
          final fileExt = fileName.split('.').last;
          // Add index to ensure unique file paths when uploading multiple files of same type
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final uniqueId = '${timestamp}_${i}';
          final filePath =
              '${user.id}/${widget.claim.id}/${uniqueId}_$fileName';

          // Upload to Storage
          await SupabaseService.client.storage
              .from('insurevis-documents')
              .uploadBinary(filePath, bytes);

          // Generate signed URL for the uploaded file
          final signedUrl = await SupabaseService.client.storage
              .from('insurevis-documents')
              .createSignedUrl(filePath, 3600 * 24 * 30); // 30 days

          // Determine is_primary based on local map
          final isPrimary = _requiredDocuments[category] ?? false;

          // Create description
          final description =
              'Document uploaded for insurance claim ${widget.claim.claimNumber} - ${_documentTitleFromKey(category)}';

          // Create Document Record
          await SupabaseService.client.from('documents').insert({
            'claim_id': widget.claim.id,
            'user_id': user.id,
            'type': category,
            'file_name': fileName,
            'file_size_bytes': await file.length(),
            'format': fileExt,
            'storage_path': filePath,
            'remote_url': signedUrl,
            'status': 'uploaded',
            'is_primary': isPrimary, // Added
            'description': description, // Added
          });
        }
      }

      // 3. Fetch the updated claim data from the server
      final updatedClaimData =
          await SupabaseService.client
              .from('claims')
              .select('*')
              .eq('id', widget.claim.id)
              .single();

      final updatedClaim = ClaimModel.fromJson(updatedClaimData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isAppeal
                  ? 'Appeal submitted successfully'
                  : 'Claim updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // If this was an appeal, reset verification flags on the document records
        // for the rejecting party so they can be re-verified.
        if (_isAppeal) {
          try {
            final carRejected =
                widget.claim.carCompanyStatus.toLowerCase() == 'rejected';
            final insuranceRejected =
                widget.claim.status.toLowerCase() == 'rejected';
            if (carRejected || insuranceRejected) {
              for (final d in _documents) {
                final updates = <String, dynamic>{};
                var needsUpdate = false;
                if (carRejected) {
                  updates['verified_by_car_company'] = false;
                  // Clear rejection notes related to car company
                  if (d.carCompanyVerificationNotes != null &&
                      d.carCompanyVerificationNotes!.trim().isNotEmpty) {
                    updates['car_company_verification_notes'] = null;
                  }
                  needsUpdate = true;
                }
                if (insuranceRejected) {
                  updates['verified_by_insurance_company'] = false;
                  // Clear rejection notes related to insurance
                  if (d.insuranceVerificationNotes != null &&
                      d.insuranceVerificationNotes!.trim().isNotEmpty) {
                    updates['insurance_verification_notes'] = null;
                  }
                  needsUpdate = true;
                }
                if (needsUpdate) {
                  await SupabaseService.client
                      .from('documents')
                      .update(updates)
                      .eq('id', d.id);
                }
              }
            }
          } catch (e) {
            if (kDebugMode)
              print('Failed to reset document verification flags: $e');
          }
        }

        // Exit edit mode and refresh the UI with updated data
        setState(() {
          _isEditing = false;
          _isAppeal = false;
          // Clear new documents and deleted document tracking
          _newCategorizedDocuments.clear();
          _deletedDocumentIds.clear();
          // Update controllers with fresh data
          _vehicleMakeController.text = updatedClaim.vehicleMake ?? '';
          _vehicleModelController.text = updatedClaim.vehicleModel ?? '';
          _vehicleYearController.text =
              updatedClaim.vehicleYear?.toString() ?? '';
          _vehiclePlateNumberController.text =
              updatedClaim.vehiclePlateNumber ?? '';
        });

        // Reload documents to show newly uploaded ones
        await _loadDocuments();

        // Return updated claim to trigger refresh in parent screens
        Navigator.pop(context, updatedClaim);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving claim: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // Default helper functions
  Color _defaultStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Colors.orange;
      case 'under review':
        return Colors.blue;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'appealed':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Icons.upload_rounded;
      case 'under review':
        return Icons.search_rounded;
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'appealed':
        return Icons.replay_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _defaultFormatStatus(String status) {
    if (status.trim().isEmpty) return '';
    final parts = status.replaceAll('_', ' ').split(' ');
    final capitalized = parts
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join(' ');
    return capitalized;
  }

  String _defaultFormatCurrency(double? amount) {
    if (amount == null) return '-';
    try {
      final f = NumberFormat.currency(
        locale: 'en_PH',
        symbol: '₱',
        decimalDigits: 2,
      );
      return f.format(amount);
    } catch (_) {
      return '₱${amount.toStringAsFixed(2)}';
    }
  }

  Widget _defaultBuildClaimIcon(String status, Color color) {
    return Container(
      height: 50.sp,
      width: 50.sp,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(_statusIcon(status), color: color, size: 25.sp),
    );
  }

  @override
  Widget build(BuildContext context) {
    final claim = widget.claim;
    final buildClaimIcon = widget.buildClaimIcon ?? _defaultBuildClaimIcon;
    final statusColor = widget.statusColor ?? _defaultStatusColor;
    final formatStatus = widget.formatStatus ?? _defaultFormatStatus;
    final formatCurrency = widget.formatCurrency ?? _defaultFormatCurrency;

    // Allow editing if draft, pending docs, appealed, or rejected (appeal)
    final canEdit =
        claim.status == 'draft' ||
        claim.status == 'pending_documents' ||
        claim.status == 'submitted' ||
        claim.status == 'under_review' ||
        claim.status == 'appealed';
    // Consider a claim rejected when either the main insurance status is 'rejected'
    // or the car company has rejected the claim via 'car_company_status'.
    final isRejected =
        claim.status == 'rejected' || claim.carCompanyStatus == 'rejected';

    return WillPopScope(
      onWillPop: () async {
        if (_isEditing && _hasUnsavedChanges()) {
          return await _showDiscardChangesDialog();
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading:
              _isEditing
                  ? IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () async {
                      if (_hasUnsavedChanges()) {
                        final discard = await _showDiscardChangesDialog();
                        if (discard && mounted) {
                          setState(() {
                            _isEditing = false;
                            _isAppeal = false;
                            _newCategorizedDocuments.clear();
                            _deletedDocumentIds.clear();
                            _initializeControllers();
                          });
                        }
                      } else {
                        setState(() {
                          _isEditing = false;
                          _isAppeal = false;
                        });
                      }
                    },
                  )
                  : null,
          title: Text(
            _isEditing
                ? (_isAppeal ? 'Appeal Claim' : 'Edit Claim')
                : 'Claim Details',
            style: GoogleFonts.inter(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            if (!_isEditing && (canEdit || isRejected))
              isRejected
                  ? Padding(
                    padding: EdgeInsets.only(right: 16.w),
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                          _isAppeal = isRejected;
                        });
                      },
                      icon: Icon(
                        Icons.replay_rounded,
                        size: 18.sp,
                        color: GlobalStyles.primaryColor,
                      ),
                      label: Text(
                        'Appeal',
                        style: GoogleFonts.inter(
                          color: GlobalStyles.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: GlobalStyles.primaryColor.withOpacity(
                          0.1,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                  )
                  : IconButton(
                    icon: Icon(Icons.edit_rounded),
                    tooltip: 'Edit',
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                        _isAppeal = isRejected;
                      });
                    },
                  ),
            if (_isEditing)
              IconButton(
                icon:
                    _isSaving
                        ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                        : Icon(Icons.check_rounded),
                tooltip: 'Save',
                onPressed: _isSaving ? null : _saveClaim,
              ),
          ],
        ),
        bottomNavigationBar:
            !_isEditing
                ? SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GlobalStyles.primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Close',
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                : null,
        body:
            _isEditing
                ? _buildEditForm()
                : _buildViewLayout(
                  claim: claim,
                  buildClaimIcon: buildClaimIcon,
                  statusColor: statusColor,
                  formatStatus: formatStatus,
                  formatCurrency: formatCurrency,
                ),
      ),
    );
  }

  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isAppeal)
            Container(
              padding: EdgeInsets.all(12.w),
              margin: EdgeInsets.only(bottom: 16.h),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[800]),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'You are appealing a rejected claim. Please update the documents as needed.',
                      style: GoogleFonts.inter(
                        color: Colors.orange[900],
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          _buildVehicleInfoSection(),
          SizedBox(height: 40.h),
          _buildEstimatedCostSection(),
          SizedBox(height: 20.h),
          Padding(
            padding: EdgeInsets.all(20.sp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Document Upload Section",
                  style: GoogleFonts.inter(
                    color: const Color(0xFF2A2A2A),
                    fontWeight: FontWeight.w700,
                    fontSize: 24.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Please upload all required documents listed below.',
                  style: GoogleFonts.inter(
                    color: const Color(0x992A2A2A),
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
          _buildDocumentCategories(),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  Widget _buildVehicleInfoSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle Information',
            style: GoogleFonts.inter(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2A2A2A),
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: VehicleForm(
              makeController: _vehicleMakeController,
              modelController: _vehicleModelController,
              yearController: _vehicleYearController,
              plateNumberController: _vehiclePlateNumberController,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimatedCostSection() {
    final formatCurrency = widget.formatCurrency ?? _defaultFormatCurrency;
    final cost = widget.claim.estimatedDamageCost;

    return Container(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Estimated Cost',
                style: GoogleFonts.inter(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2A2A2A),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'This is the estimated cost based on your repair options.',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: const Color(0x992A2A2A),
            ),
          ),
          SizedBox(height: 30.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              color: GlobalStyles.primaryColor.withAlpha(38),
            ),
            child: Column(
              children: [
                Text(
                  'Total Estimated Cost',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    color: const Color(0x992A2A2A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  formatCurrency(cost),
                  style: GoogleFonts.inter(
                    fontSize: 28.sp,
                    color: GlobalStyles.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
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
        ),
        SizedBox(
          height: 16.h,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: const Divider(color: Color(0x442A2A2A)),
          ),
        ),
        _buildDocumentCategory(
          'LTO C.R (Certificate of Registration)',
          'lto_cr',
          'Upload photocopy/PDF of LTO Certificate of Registration with number',
        ),
        SizedBox(
          height: 16.h,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: const Divider(color: Color(0x442A2A2A)),
          ),
        ),
        _buildDocumentCategory(
          'Driver\'s License',
          'drivers_license',
          'Upload photocopy/PDF of driver\'s license',
        ),
        SizedBox(
          height: 16.h,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: const Divider(color: Color(0x442A2A2A)),
          ),
        ),
        _buildDocumentCategory(
          'Valid ID of Owner',
          'owner_valid_id',
          'Upload photocopy/PDF of owner\'s valid government ID',
        ),
        SizedBox(
          height: 16.h,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: const Divider(color: Color(0x442A2A2A)),
          ),
        ),
        _buildDocumentCategory(
          'Police Report/Affidavit',
          'police_report',
          'Upload original police report or affidavit',
        ),
        SizedBox(
          height: 16.h,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: const Divider(color: Color(0x442A2A2A)),
          ),
        ),
        _buildDocumentCategory(
          'Insurance Policy',
          'insurance_policy',
          'Upload photocopy/PDF of your insurance policy',
        ),
        SizedBox(
          height: 16.h,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: const Divider(color: Color(0x442A2A2A)),
          ),
        ),
        _buildDocumentCategory(
          'Job Estimate',
          'job_estimate',
          'Upload repair/job estimate from service provider',
        ),
        SizedBox(
          height: 16.h,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: const Divider(color: Color(0x442A2A2A)),
          ),
        ),
        _buildDocumentCategory(
          'Pictures of Damage',
          'damage_photos',
          'Assessment photos are already included. You can add more damage photos or PDF documents if needed.',
        ),
        SizedBox(
          height: 16.h,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: const Divider(color: Color(0x442A2A2A)),
          ),
        ),
        _buildDocumentCategory(
          'Stencil Strips',
          'stencil_strips',
          'Upload stencil strips documentation',
        ),
        SizedBox(
          height: 16.h,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: const Divider(color: Color(0x442A2A2A)),
          ),
        ),
        _buildDocumentCategory(
          'Additional Documents',
          'additional_documents',
          'Upload any other relevant documents (Optional)',
        ),
      ],
    );
  }

  Widget _buildDocumentCategory(
    String title,
    String category,
    String description,
  ) {
    final isRequired = _requiredDocuments[category] ?? false;
    final existingDocs = _categorizedDocuments[category] ?? [];
    final newDocs = _newCategorizedDocuments[category] ?? [];
    final hasFiles = existingDocs.isNotEmpty || newDocs.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(20.sp),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2A2A2A),
                          ),
                        ),
                        if (isRequired) ...[
                          SizedBox(width: 4.w),
                          Text(
                            '*',
                            style: GoogleFonts.inter(
                              fontSize: 18.sp,
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
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: const Color(0x992A2A2A),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasFiles)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: GlobalStyles.primaryColor.withAlpha(51),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    '${existingDocs.length + newDocs.length}',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: GlobalStyles.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),

          // Show uploaded files
          if (hasFiles) ...[
            _buildUploadedFilesList(category, existingDocs, newDocs),
            SizedBox(height: 12.h),
          ],

          // Upload buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickDocument(category),
                  icon: Icon(Icons.upload_file_rounded, size: 16.sp),
                  label: Text(
                    'Upload File',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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
                  label: Text(
                    'Take Photo',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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

  Widget _buildUploadedFilesList(
    String category,
    List<DocumentModel> existingDocs,
    List<File> newDocs,
  ) {
    return SizedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Uploaded Files:',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: GlobalStyles.primaryColor,
            ),
          ),
          SizedBox(height: 8.h),
          ...existingDocs.map((doc) => _buildFileItem(category, doc: doc)),
          ...newDocs.map((file) => _buildFileItem(category, file: file)),
        ],
      ),
    );
  }

  Widget _buildFileItem(String category, {DocumentModel? doc, File? file}) {
    final fileName =
        doc?.fileName ?? file!.path.split(Platform.pathSeparator).last;
    final isImage =
        fileName.toLowerCase().endsWith('.jpg') ||
        fileName.toLowerCase().endsWith('.jpeg') ||
        fileName.toLowerCase().endsWith('.png');

    final statusInfo = doc != null ? _documentStatusInfo(doc) : null;
    final borderColor =
        statusInfo != null
            ? (statusInfo['color'] as Color)
            : Colors.transparent;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: GlobalStyles.primaryColor.withAlpha(51),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: borderColor.withAlpha(80)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isImage ? Icons.image_rounded : Icons.description_rounded,
                color: GlobalStyles.primaryColor,
                size: 16.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: GlobalStyles.primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (doc != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        'Existing Document',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: GlobalStyles.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ] else ...[
                      SizedBox(height: 2.h),
                      Text(
                        'New Upload',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                height: 30.h,
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {
                    if (doc != null) {
                      _deleteExistingDocument(doc);
                    } else if (file != null) {
                      _removeFile(category, file);
                    }
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.red,
                    size: 16.sp,
                  ),
                ),
              ),
            ],
          ),
          if (doc != null) ...[
            SizedBox(height: 6.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: _buildStatusChips(doc),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildViewLayout({
    required ClaimModel claim,
    required Widget Function(String status, Color color) buildClaimIcon,
    required Color Function(String status) statusColor,
    required String Function(String status) formatStatus,
    required String Function(double? amount) formatCurrency,
  }) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fixed header card with claim id, status and estimated cost
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildClaimIcon(claim.status, statusColor(claim.status)),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              claim.claimNumber,
                              style: GoogleFonts.inter(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 6.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor(
                                  claim.status,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                formatStatus(claim.status),
                                style: GoogleFonts.inter(
                                  color: statusColor(claim.status),
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // Approval Status Cards
                if (claim.status != 'draft') ...[
                  _buildApprovalStatusCard(
                    title: 'Car Company Review',
                    status: claim.carCompanyStatus,
                    isApproved: claim.isApprovedByCarCompany,
                    approvalDate: claim.carCompanyApprovalDate,
                    rejectedDate: claim.rejectedAt,
                    notes: claim.carCompanyApprovalNotes,
                  ),
                  // Only show insurance review if car company hasn't rejected
                  if (claim.carCompanyStatus != 'rejected') ...[
                    SizedBox(height: 12.h),
                    _buildApprovalStatusCard(
                      title: 'Insurance Company Review',
                      status: claim.status,
                      isApproved: claim.isApprovedByInsuranceCompany,
                      approvalDate: claim.insuranceCompanyApprovalDate,
                      rejectedDate: claim.rejectedAt,
                      notes: claim.insuranceCompanyApprovalNotes,
                    ),
                  ],
                  SizedBox(height: 16.h),
                ],

                // Estimated Cost section
                Text(
                  'Estimated Cost',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: GlobalStyles.primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: GlobalStyles.primaryColor.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    formatCurrency(claim.estimatedDamageCost),
                    style: GoogleFonts.inter(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                      color: GlobalStyles.primaryColor,
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                // Details
                _buildDetailRow(
                  'Incident Date',
                  DateFormat.yMMMd().format(claim.incidentDate),
                ),
                _buildDetailRow('Location', claim.incidentLocation),
                _buildDetailRow(
                  'Vehicle',
                  '${claim.vehicleMake} ${claim.vehicleModel} (${claim.vehicleYear})',
                ),
                _buildDetailRow(
                  'Plate Number',
                  claim.vehiclePlateNumber ?? 'N/A',
                ),
                _buildDetailRow(
                  'Created Date',
                  DateFormat.yMMMd().add_jm().format(
                    claim.createdAt.add(Duration(hours: 8)),
                  ),
                ),

                SizedBox(height: 12.h),
                Text(
                  'Description',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    claim.incidentDescription,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                // Documents header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Documents',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_loadingDocs)
                      SizedBox(
                        height: 18.sp,
                        width: 18.sp,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: GlobalStyles.primaryColor,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 8.h),

                if (_docError != null)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      _docError!,
                      style: GoogleFonts.inter(
                        color: Colors.red[700],
                        fontSize: 13.sp,
                      ),
                    ),
                  )
                else if (_documents.isEmpty && !_loadingDocs)
                  Text(
                    'No documents uploaded for this claim yet.',
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontSize: 14.sp,
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Documents list
        if (_documents.isNotEmpty)
          SliverList.builder(
            itemCount: _documents.length,
            itemBuilder: (context, index) {
              final doc = _documents[index];
              return _buildDocumentTile(doc);
            },
          ),
      ],
    );
  }

  Widget _buildDocumentTile(DocumentModel doc) {
    final url = _signedUrls[doc.id];
    final statusInfo = _documentStatusInfo(doc);
    final borderColor = statusInfo['color'] as Color;

    if (_isPdf(doc)) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: borderColor.withAlpha(80)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // First row: icon, title, filename, buttons
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                child: Row(
                  children: [
                    Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Colors.red[600],
                      size: 22.sp,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.type.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            doc.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_progress[doc.id] != null)
                      SizedBox(
                        width: 24.sp,
                        height: 24.sp,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: (_progress[doc.id] ?? 0),
                          color: GlobalStyles.primaryColor,
                        ),
                      )
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Open',
                            onPressed: url == null ? null : () => _openPdf(doc),
                            icon: Icon(
                              Icons.open_in_new_rounded,
                              color: Colors.blueGrey,
                              size: 22.sp,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Download',
                            onPressed:
                                url == null ? null : () => _download(doc),
                            icon: Icon(
                              Icons.download_rounded,
                              color: GlobalStyles.primaryColor,
                              size: 22.sp,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              // Second row: status chips
              Padding(
                padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 10.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: _buildStatusChips(doc),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (_isImage(doc) && url != null) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor.withAlpha(80)),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image preview
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (_) => ImageViewerPage(
                            imageUrl: url,
                            title: doc.type.displayName,
                          ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(12.r),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: Icon(
                                Icons.image_not_supported_rounded,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                    ),
                  ),
                ),
              ),
              // Top row: title, filename, download button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.type.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            doc.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_progress[doc.id] != null)
                      SizedBox(
                        width: 24.sp,
                        height: 24.sp,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: (_progress[doc.id] ?? 0),
                          color: GlobalStyles.primaryColor,
                        ),
                      )
                    else
                      IconButton(
                        tooltip: 'Download',
                        onPressed: () => _download(doc),
                        icon: Icon(
                          Icons.download_rounded,
                          color: GlobalStyles.primaryColor,
                          size: 22.sp,
                        ),
                      ),
                  ],
                ),
              ),
              // Bottom row: status chips
              Padding(
                padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 10.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: _buildStatusChips(doc),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Padding(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: borderColor.withAlpha(80)),
          ),
          child: Column(
            children: [
              // Top row: icon, title, filename, download button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                child: Row(
                  children: [
                    Icon(
                      Icons.insert_drive_file_rounded,
                      color: Colors.grey[700],
                      size: 22.sp,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.type.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            doc.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Download',
                      onPressed:
                          _signedUrls[doc.id] == null
                              ? null
                              : () => _download(doc),
                      icon: Icon(
                        Icons.download_rounded,
                        color: GlobalStyles.primaryColor,
                        size: 22.sp,
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom row: status chips
              Padding(
                padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 10.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: _buildStatusChips(doc),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _documentTitleFromKey(String key) {
    switch (key) {
      case 'lto_or':
        return 'LTO O.R.';
      case 'lto_cr':
        return 'LTO C.R.';
      case 'drivers_license':
        return "Driver's License";
      case 'owner_valid_id':
        return 'Owner Valid ID';
      case 'police_report':
        return 'Police Report';
      case 'insurance_policy':
        return 'Insurance Policy';
      case 'job_estimate':
        return 'Job Estimate';
      case 'damage_photos':
        return 'Damage Photos';
      case 'stencil_strips':
        return 'Stencil Strips';
      case 'additional_documents':
        return 'Additional Documents';
      default:
        return key
            .split('_')
            .map(
              (word) =>
                  word.isNotEmpty
                      ? '${word[0].toUpperCase()}${word.substring(1)}'
                      : '',
            )
            .join(' ');
    }
  }

  Widget _buildApprovalStatusCard({
    required String title,
    required String status,
    required bool isApproved,
    DateTime? approvalDate,
    DateTime? rejectedDate,
    String? notes,
  }) {
    // Determine status
    String statusText;
    Color statusColor;
    IconData statusIcon;

    // Use the status field to determine display
    switch (status.toLowerCase()) {
      case 'approved':
        statusText = 'Approved';
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        statusText = 'Rejected';
        statusColor = Colors.red;
        statusIcon = Icons.cancel_rounded;
        break;
      case 'under_review':
      case 'under review':
        statusText = 'Under Review';
        statusColor = Colors.blue;
        statusIcon = Icons.rate_review_rounded;
        break;
      case 'pending':
      default:
        statusText = 'Pending';
        statusColor = Colors.orange;
        statusIcon = Icons.pending_rounded;
        break;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (statusText == 'Rejected' && rejectedDate != null) ...[
            SizedBox(height: 8.h),
            Text(
              'Rejected on: ${DateFormat.yMMMd().add_jm().format(rejectedDate)}',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
          ] else if (approvalDate != null) ...[
            SizedBox(height: 8.h),
            Text(
              'Date: ${DateFormat.yMMMd().add_jm().format(approvalDate)}',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
          if (notes != null && notes.trim().isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              'Notes:',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              _formatRejectionNote(notes),
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
