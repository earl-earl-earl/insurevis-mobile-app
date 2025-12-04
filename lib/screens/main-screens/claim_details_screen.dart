import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:insurevis/utils/claim_details_handler_utils.dart';
import 'package:insurevis/utils/claim_details_widget_utils.dart';

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

class _ClaimDetailsScreenState extends State<ClaimDetailsScreen>
    with TickerProviderStateMixin {
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

  // Editing state
  bool _isEditing = false;
  bool _isAppeal = false;
  bool _isSaving = false;

  // Document section expansion state
  final Map<String, bool> _expandedSections = {};
  int _currentDocumentIndex = 0;

  // Real-time subscription tracking
  late RealtimeChannel _claimSubscription;
  late RealtimeChannel _documentSubscription;
  ClaimModel? _currentClaim;

  // Vehicle form controllers
  late TextEditingController _vehicleMakeController;
  late TextEditingController _vehicleModelController;
  late TextEditingController _vehicleYearController;
  late TextEditingController _vehiclePlateNumberController;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _editModeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _editModeAnimation;

  @override
  void initState() {
    super.initState();
    _currentClaim = widget.claim;

    // Initialize animations
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _editModeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _editModeAnimation = CurvedAnimation(
      parent: _editModeController,
      curve: Curves.easeInOut,
    );

    _initializeControllers();
    _initializeCategories();
    _loadDocuments();
    _setupRealtimeSubscriptions();

    // Start entry animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
    });
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
    for (var key in ClaimDetailsHandlerUtils.requiredDocuments.keys) {
      _categorizedDocuments[key] = [];
      _newCategorizedDocuments[key] = [];
    }
  }

  void _setupRealtimeSubscriptions() {
    // Subscribe to claim updates
    _claimSubscription =
        SupabaseService.client
            .channel('public:claims:id=eq.${widget.claim.id}')
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'claims',
              callback: (payload) {
                if (mounted) {
                  _handleClaimUpdate(payload);
                }
              },
            )
            .subscribe();

    // Subscribe to document changes for this claim (insert, update, delete)
    _documentSubscription =
        SupabaseService.client
            .channel('public:documents:claim_id=eq.${widget.claim.id}')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'documents',
              callback: (payload) {
                if (mounted) {
                  _handleDocumentUpdate(payload);
                }
              },
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'documents',
              callback: (payload) {
                if (mounted) {
                  _handleDocumentUpdate(payload);
                }
              },
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.delete,
              schema: 'public',
              table: 'documents',
              callback: (payload) {
                if (mounted) {
                  _handleDocumentUpdate(payload);
                }
              },
            )
            .subscribe();
  }

  void _handleClaimUpdate(PostgresChangePayload payload) {
    try {
      final updatedData = payload.newRecord;
      final updatedClaim = ClaimModel.fromJson(updatedData);

      setState(() {
        _currentClaim = updatedClaim;
      });

      if (kDebugMode) {
        print('Claim updated in real-time: ${updatedClaim.id}');
      }
    } catch (e) {
      if (kDebugMode) print('Error handling claim update: $e');
    }
  }

  void _handleDocumentUpdate(PostgresChangePayload payload) {
    try {
      if (payload.eventType == PostgresChangeEvent.delete) {
        final deletedData = payload.oldRecord;
        final deletedId = deletedData['id'] as String?;
        if (deletedId != null) {
          setState(() {
            _documents.removeWhere((d) => d.id == deletedId);
            // Also remove from categorized list
            _categorizedDocuments.forEach((category, docs) {
              docs.removeWhere((d) => d.id == deletedId);
            });
          });
          if (kDebugMode) print('Document deleted in real-time: $deletedId');
        }
      } else {
        final documentData =
            (payload.eventType == PostgresChangeEvent.insert
                ? payload.newRecord
                : payload.newRecord);
        final document = DocumentModel.fromJson(documentData);

        setState(() {
          // Find and update existing document or add new one
          final index = _documents.indexWhere((d) => d.id == document.id);
          if (index >= 0) {
            _documents[index] = document;
            // Update in categorized list too
            final type = document.type.value;
            if (_categorizedDocuments.containsKey(type)) {
              final docIndex = _categorizedDocuments[type]!.indexWhere(
                (d) => d.id == document.id,
              );
              if (docIndex >= 0) {
                _categorizedDocuments[type]![docIndex] = document;
              }
            }
          } else {
            // New document
            _documents.add(document);
            final type = document.type.value;
            if (_categorizedDocuments.containsKey(type)) {
              _categorizedDocuments[type]!.add(document);
            } else {
              _categorizedDocuments['additional_documents']!.add(document);
            }
          }
          // Preload signed URL for new/updated document
          if (document.storagePath != null &&
              document.storagePath!.isNotEmpty) {
            _preloadSignedUrl(document.id, document.storagePath!);
          } else if (document.remoteUrl != null) {
            _signedUrls[document.id] = document.remoteUrl;
          }
        });

        if (kDebugMode) {
          print(
            'Document ${payload.eventType == PostgresChangeEvent.insert ? 'created' : 'updated'} in real-time: ${document.id}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error handling document update: $e');
    }
  }

  void _preloadSignedUrl(String docId, String storagePath) async {
    try {
      final url = await _storage.getSignedUrl(storagePath, expiresIn: 3600);
      if (mounted) {
        setState(() {
          _signedUrls[docId] = url;
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error preloading signed URL: $e');
    }
  }

  @override
  void dispose() {
    _vehicleMakeController.dispose();
    _vehicleModelController.dispose();
    _vehicleYearController.dispose();
    _vehiclePlateNumberController.dispose();
    _fadeController.dispose();
    _editModeController.dispose();
    // Clean up subscriptions
    SupabaseService.client.removeChannel(_claimSubscription);
    SupabaseService.client.removeChannel(_documentSubscription);
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
    final missingDocuments = ClaimDetailsHandlerUtils.getMissingDocuments(
      _categorizedDocuments,
      _newCategorizedDocuments,
    );

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
          final isPrimary =
              ClaimDetailsHandlerUtils.requiredDocuments[category] ?? false;

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
        await _editModeController.reverse();
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
        return GlobalStyles.warningMain;
      case 'under review':
        return GlobalStyles.infoMain;
      case 'approved':
        return GlobalStyles.successMain;
      case 'rejected':
        return GlobalStyles.errorMain;
      case 'appealed':
        return GlobalStyles.purpleMain;
      default:
        return GlobalStyles.textSecondary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return LucideIcons.upload;
      case 'under review':
        return LucideIcons.search;
      case 'approved':
        return LucideIcons.check;
      case 'rejected':
        return LucideIcons.x;
      case 'appealed':
        return LucideIcons.refreshCw;
      default:
        return LucideIcons.info;
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
      child: Icon(
        _statusIcon(status),
        color: color,
        size: GlobalStyles.iconSizeMd,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final claim = _currentClaim ?? widget.claim;
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
          backgroundColor: GlobalStyles.surfaceMain,
          elevation: 0,
          leading:
              _isEditing
                  ? IconButton(
                    icon: Icon(
                      LucideIcons.arrowLeft,
                      color: GlobalStyles.textPrimary,
                    ),
                    onPressed: () async {
                      if (_hasUnsavedChanges()) {
                        final discard = await _showDiscardChangesDialog();
                        if (discard && mounted) {
                          await _editModeController.reverse();
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
            style: TextStyle(
              fontSize: GlobalStyles.fontSizeH3,
              fontWeight: FontWeight.w700,
              color: GlobalStyles.textPrimary,
              fontFamily: GlobalStyles.fontFamilyHeading,
            ),
          ),
          actions: [
            if (!_isEditing && (canEdit || isRejected))
              isRejected
                  ? Padding(
                    padding: EdgeInsets.only(right: 12.w),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            GlobalStyles.warningMain,
                            GlobalStyles.warningMain.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _isEditing = true;
                            _isAppeal = true;
                            _editModeController.forward();
                          });
                        },
                        icon: Icon(
                          LucideIcons.fileText,
                          color: Colors.white,
                          size: 18.sp,
                        ),
                        label: Text(
                          'Appeal',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                            fontFamily: GlobalStyles.fontFamilyBody,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 10.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ),
                    ),
                  )
                  : IconButton(
                    icon: Icon(
                      LucideIcons.pencil,
                      color: GlobalStyles.primaryMain,
                    ),
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
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child:
                      _isSaving
                          ? SizedBox(
                            key: const ValueKey('loading'),
                            width: 20.w,
                            height: 20.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: GlobalStyles.successMain,
                            ),
                          )
                          : Icon(
                            LucideIcons.check,
                            key: const ValueKey('check'),
                            color: GlobalStyles.successMain,
                          ),
                ),
                tooltip: 'Save',
                onPressed: _isSaving ? null : _saveClaim,
              ),
          ],
        ),
        bottomNavigationBar:
            !_isEditing
                ? SafeArea(
                  child: Container(
                    decoration: BoxDecoration(
                      color: GlobalStyles.surfaceMain,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GlobalStyles.primaryMain,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            elevation: 2,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.x, size: 18.sp),
                              SizedBox(width: 8.w),
                              Text(
                                'Close',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: GlobalStyles.fontFamilyBody,
                                ),
                              ),
                            ],
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
    return FadeTransition(
      opacity: _editModeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(_editModeAnimation),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
                      Icon(LucideIcons.info, color: Colors.orange[800]),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'You are appealing a rejected claim. Please update the documents as needed.',
                          style: TextStyle(
                            color: Colors.orange[900],
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              _buildVehicleInfoSection(),
              SizedBox(height: 24.h),
              _buildEstimatedCostSection(),
              SizedBox(height: 20.h),
              Padding(
                padding: EdgeInsets.all(20.sp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Document Upload Section",
                      style: TextStyle(
                        color: const Color(0xFF2A2A2A),
                        fontWeight: FontWeight.w700,
                        fontSize: 24.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Please upload all required documents listed below.',
                      style: TextStyle(
                        color: const Color(0x992A2A2A),
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
              _buildDocumentCategories(),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleInfoSection() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 20),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedSectionHeader('Vehicle Information'),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: GlobalStyles.surfaceElevated,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: GlobalStyles.primaryMain.withValues(alpha: 0.1),
                  width: 1.0,
                ),
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
      ),
    );
  }

  Widget _buildEstimatedCostSection() {
    final formatCurrency = widget.formatCurrency ?? _defaultFormatCurrency;
    final cost = widget.claim.estimatedDamageCost;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 20),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedSectionHeader('Estimated Cost'),
            SizedBox(height: 12.h),
            Text(
              'This is the estimated cost based on your repair options.',
              style: TextStyle(
                fontSize: GlobalStyles.fontSizeBody2,
                color: GlobalStyles.textSecondary,
                fontFamily: GlobalStyles.fontFamilyBody,
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                color: GlobalStyles.primaryMain.withValues(alpha: 0.06),
                border: Border.all(
                  color: GlobalStyles.primaryMain.withValues(alpha: 0.15),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimated Cost',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: GlobalStyles.textSecondary,
                          fontWeight: GlobalStyles.fontWeightMedium,
                          fontFamily: GlobalStyles.fontFamilyBody,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        formatCurrency(cost),
                        style: TextStyle(
                          fontSize: 24.sp,
                          color: GlobalStyles.primaryMain,
                          fontWeight: FontWeight.bold,
                          fontFamily: GlobalStyles.fontFamilyHeading,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    LucideIcons.dollarSign,
                    color: GlobalStyles.primaryMain.withValues(alpha: 0.3),
                    size: 32.sp,
                  ),
                ],
              ),
            ),
          ],
        ),
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
        SizedBox(height: 12.h),
        _buildDocumentCategory(
          'LTO C.R (Certificate of Registration)',
          'lto_cr',
          'Upload photocopy/PDF of LTO Certificate of Registration with number',
        ),
        SizedBox(height: 12.h),
        _buildDocumentCategory(
          'Driver\'s License',
          'drivers_license',
          'Upload photocopy/PDF of driver\'s license',
        ),
        SizedBox(height: 12.h),
        _buildDocumentCategory(
          'Valid ID of Owner',
          'owner_valid_id',
          'Upload photocopy/PDF of owner\'s valid government ID',
        ),
        SizedBox(height: 12.h),
        _buildDocumentCategory(
          'Police Report/Affidavit',
          'police_report',
          'Upload original police report or affidavit',
        ),
        SizedBox(height: 12.h),
        _buildDocumentCategory(
          'Insurance Policy',
          'insurance_policy',
          'Upload photocopy/PDF of your insurance policy',
        ),
        SizedBox(height: 12.h),
        _buildDocumentCategory(
          'Job Estimate',
          'job_estimate',
          'Upload repair/job estimate from service provider',
        ),
        SizedBox(height: 12.h),
        _buildDocumentCategory(
          'Pictures of Damage',
          'damage_photos',
          'Assessment photos are already included. You can add more damage photos or PDF documents if needed.',
        ),
        SizedBox(height: 12.h),
        _buildDocumentCategory(
          'Stencil Strips',
          'stencil_strips',
          'Upload stencil strips documentation',
        ),
        SizedBox(height: 12.h),
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
    final isRequired =
        ClaimDetailsHandlerUtils.requiredDocuments[category] ?? false;
    final existingDocs = _categorizedDocuments[category] ?? [];
    final newDocs = _newCategorizedDocuments[category] ?? [];
    final hasFiles = existingDocs.isNotEmpty || newDocs.isNotEmpty;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
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
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2A2A2A),
                          ),
                        ),
                        if (isRequired) ...[
                          SizedBox(width: 4.w),
                          Text(
                            '*',
                            style: TextStyle(
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
                      style: TextStyle(
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
                    color: GlobalStyles.primaryMain.withAlpha(51),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    '${existingDocs.length + newDocs.length}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: GlobalStyles.primaryMain,
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
                  icon: Icon(LucideIcons.upload, size: 16.sp),
                  label: Text(
                    'Upload File',
                    style: TextStyle(
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
                  icon: Icon(LucideIcons.camera, size: 16.sp),
                  label: Text(
                    'Take Photo',
                    style: TextStyle(
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
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: GlobalStyles.primaryMain,
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

    final statusInfo =
        doc != null
            ? ClaimDetailsHandlerUtils.getDocumentStatusInfo(doc)
            : null;
    final borderColor =
        statusInfo != null
            ? (statusInfo['color'] as Color)
            : Colors.transparent;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: GlobalStyles.primaryMain.withAlpha(51),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: borderColor.withAlpha(80)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isImage ? LucideIcons.image : LucideIcons.fileText,
                color: GlobalStyles.primaryMain,
                size: 16.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: GlobalStyles.primaryMain,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (doc != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        'Existing Document',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: GlobalStyles.primaryMain,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ] else ...[
                      SizedBox(height: 2.h),
                      Text(
                        'New Upload',
                        style: TextStyle(
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
                  icon: Icon(LucideIcons.x, color: Colors.red, size: 16.sp),
                ),
              ),
            ],
          ),
          if (doc != null) ...[
            SizedBox(height: 6.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: ClaimDetailsWidgetUtils.buildStatusChips(context, doc),
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fixed header card with claim id and status
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor(claim.status).withValues(alpha: 0.08),
                          statusColor(claim.status).withValues(alpha: 0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: statusColor(claim.status).withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: statusColor(
                              claim.status,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            _statusIcon(claim.status),
                            color: statusColor(claim.status),
                            size: 28.sp,
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Claim #${claim.claimNumber}',
                                style: TextStyle(
                                  fontSize: 17.sp,
                                  fontWeight: FontWeight.bold,
                                  color: GlobalStyles.textPrimary,
                                  fontFamily: GlobalStyles.fontFamilyHeading,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 6.h),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor(claim.status),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(
                                  formatStatus(claim.status),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // Approval Status Cards - Side by Side
                  if (claim.status != 'draft') ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildApprovalStatusCard(
                            title: 'Car Company',
                            status: claim.carCompanyStatus,
                            isApproved: claim.isApprovedByCarCompany,
                            approvalDate: claim.carCompanyApprovalDate,
                            rejectedDate: claim.rejectedAt,
                            notes: claim.carCompanyApprovalNotes,
                            compact: true,
                          ),
                        ),
                        // Only show insurance review if car company hasn't rejected
                        if (claim.carCompanyStatus != 'rejected') ...[
                          SizedBox(width: 10.w),
                          Expanded(
                            child: _buildApprovalStatusCard(
                              title: 'Insurance Co.',
                              status: claim.status,
                              isApproved: claim.isApprovedByInsuranceCompany,
                              approvalDate: claim.insuranceCompanyApprovalDate,
                              rejectedDate: claim.rejectedAt,
                              notes: claim.insuranceCompanyApprovalNotes,
                              compact: true,
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 16.h),
                  ],

                  // Estimated Cost with Icon
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          GlobalStyles.successMain.withValues(alpha: 0.1),
                          GlobalStyles.successMain.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: GlobalStyles.successMain.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: GlobalStyles.successMain.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(
                            LucideIcons.dollarSign,
                            color: GlobalStyles.successMain,
                            size: 24.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estimated Cost',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: GlobalStyles.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              formatCurrency(claim.estimatedDamageCost),
                              style: TextStyle(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.bold,
                                color: GlobalStyles.successMain,
                                fontFamily: GlobalStyles.fontFamilyHeading,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Claim Details Card
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: GlobalStyles.surfaceElevated,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: GlobalStyles.primaryMain.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.info,
                              size: 16.sp,
                              color: GlobalStyles.primaryMain,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'Claim Details',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: GlobalStyles.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
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
                          isLast: true,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Description Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: GlobalStyles.surfaceElevated,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: GlobalStyles.primaryMain.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.fileText,
                              size: 16.sp,
                              color: GlobalStyles.primaryMain,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'Incident Description',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: GlobalStyles.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          claim.incidentDescription,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: GlobalStyles.textSecondary,
                            height: 1.6,
                            fontFamily: GlobalStyles.fontFamilyBody,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Documents header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Documents',
                        style: TextStyle(
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
                            color: GlobalStyles.primaryMain,
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
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 13.sp,
                        ),
                      ),
                    )
                  else if (_documents.isEmpty && !_loadingDocs)
                    Text(
                      'No documents uploaded for this claim yet.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14.sp,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Documents sections with carousel
          if (_documents.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.files,
                          size: 18.sp,
                          color: GlobalStyles.primaryMain,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Documents',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: GlobalStyles.textPrimary,
                            fontFamily: GlobalStyles.fontFamilyHeading,
                          ),
                        ),
                        Spacer(),
                        Text(
                          '${_documents.length} file${_documents.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: GlobalStyles.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    ..._buildDocumentCarouselSections(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: GlobalStyles.textSecondary,
                fontWeight: GlobalStyles.fontWeightMedium,
                fontFamily: GlobalStyles.fontFamilyBody,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: GlobalStyles.textPrimary,
                fontFamily: GlobalStyles.fontFamilyBody,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSectionHeader(
    String title, {
    bool showUnderline = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: GlobalStyles.textPrimary,
            fontFamily: GlobalStyles.fontFamilyHeading,
          ),
        ),
        if (showUnderline) ...[
          SizedBox(height: 8.h),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Container(
                height: 3.h,
                width: 50.w * value,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      GlobalStyles.primaryMain,
                      GlobalStyles.primaryMain.withValues(alpha: 0.4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  List<Widget> _buildDocumentCarouselSections() {
    // Group documents by category
    final Map<String, List<DocumentModel>> groupedDocs = {};
    for (final doc in _documents) {
      final category = doc.type.value;
      if (!groupedDocs.containsKey(category)) {
        groupedDocs[category] = [];
      }
      groupedDocs[category]!.add(doc);
    }

    // Build collapsible sections
    List<Widget> sections = [];
    groupedDocs.forEach((category, docs) {
      if (docs.isEmpty) return;

      final isExpanded = _expandedSections[category] ?? false;
      final displayName = _documentTitleFromKey(category);

      sections.add(
        Container(
          margin: EdgeInsets.only(bottom: 8.h),
          decoration: BoxDecoration(
            color: GlobalStyles.surfaceElevated,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: GlobalStyles.primaryMain.withValues(alpha: 0.1),
              width: 1.0,
            ),
          ),
          child: Column(
            children: [
              // Header
              InkWell(
                onTap: () {
                  setState(() {
                    _expandedSections[category] = !isExpanded;
                    if (!isExpanded) {
                      _currentDocumentIndex = 0;
                    }
                  });
                },
                borderRadius: BorderRadius.circular(10.r),
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.folder,
                        size: 18.sp,
                        color: GlobalStyles.primaryMain,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: GlobalStyles.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: GlobalStyles.primaryMain.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          '${docs.length}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: GlobalStyles.primaryMain,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          LucideIcons.chevronDown,
                          size: 18.sp,
                          color: GlobalStyles.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Expandable Content - Carousel
              if (isExpanded) ...[
                Divider(
                  height: 1,
                  color: GlobalStyles.primaryMain.withValues(alpha: 0.1),
                ),
                Padding(
                  padding: EdgeInsets.all(12.w),
                  child: _buildDocumentCarousel(docs, category),
                ),
              ],
            ],
          ),
        ),
      );
    });

    return sections;
  }

  Widget _buildDocumentCarousel(List<DocumentModel> docs, String category) {
    if (docs.isEmpty) {
      return Center(
        child: Text(
          'No documents',
          style: TextStyle(fontSize: 12.sp, color: GlobalStyles.textTertiary),
        ),
      );
    }

    final currentIndex = _currentDocumentIndex.clamp(0, docs.length - 1);
    final doc = docs[currentIndex];

    return Column(
      children: [
        // Document preview
        _buildCompactDocumentTile(doc),

        // Carousel controls
        if (docs.length > 1) ...[
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed:
                    currentIndex > 0
                        ? () {
                          setState(() {
                            _currentDocumentIndex--;
                          });
                        }
                        : null,
                icon: Icon(LucideIcons.chevronLeft),
                iconSize: 20.sp,
                color:
                    currentIndex > 0
                        ? GlobalStyles.primaryMain
                        : GlobalStyles.textDisabled,
              ),
              Text(
                '${currentIndex + 1} of ${docs.length}',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: GlobalStyles.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                onPressed:
                    currentIndex < docs.length - 1
                        ? () {
                          setState(() {
                            _currentDocumentIndex++;
                          });
                        }
                        : null,
                icon: Icon(LucideIcons.chevronRight),
                iconSize: 20.sp,
                color:
                    currentIndex < docs.length - 1
                        ? GlobalStyles.primaryMain
                        : GlobalStyles.textDisabled,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCompactDocumentTile(DocumentModel doc) {
    final url = _signedUrls[doc.id];
    final statusInfo = ClaimDetailsHandlerUtils.getDocumentStatusInfo(doc);
    final borderColor = statusInfo['color'] as Color;
    final isImage = ClaimDetailsHandlerUtils.isImage(doc);
    final isPdf = ClaimDetailsHandlerUtils.isPdf(doc);

    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: borderColor.withValues(alpha: 0.2),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview if available
          if (isImage && url != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: GestureDetector(
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ImageViewerPage(
                              imageUrl: url,
                              title: doc.fileName,
                            ),
                      ),
                    ),
                child: Container(
                  height: 150.h,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value:
                              loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                          color: GlobalStyles.primaryMain,
                        ),
                      );
                    },
                    errorBuilder:
                        (context, error, stackTrace) => Icon(
                          LucideIcons.imageMinus,
                          color: Colors.grey[500],
                          size: 32.sp,
                        ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
          ],
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: GlobalStyles.primaryMain.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Icon(
                  isImage ? LucideIcons.image : LucideIcons.fileText,
                  color: GlobalStyles.primaryMain,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.type.displayName,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: GlobalStyles.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      doc.fileName,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: GlobalStyles.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isImage && url != null)
                IconButton(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ImageViewerPage(
                                imageUrl: url,
                                title: doc.fileName,
                              ),
                        ),
                      ),
                  icon: Icon(LucideIcons.eye, size: 18.sp),
                  color: GlobalStyles.primaryMain,
                  padding: EdgeInsets.all(4.w),
                  constraints: BoxConstraints(),
                )
              else if (isPdf)
                IconButton(
                  onPressed: () => _openPdf(doc),
                  icon: Icon(LucideIcons.eye, size: 18.sp),
                  color: GlobalStyles.primaryMain,
                  padding: EdgeInsets.all(4.w),
                  constraints: BoxConstraints(),
                ),
              IconButton(
                onPressed: () => _download(doc),
                icon: Icon(LucideIcons.download, size: 18.sp),
                color: GlobalStyles.primaryMain,
                padding: EdgeInsets.all(4.w),
                constraints: BoxConstraints(),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: ClaimDetailsWidgetUtils.buildStatusChips(context, doc),
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
    bool compact = false,
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
        statusIcon = LucideIcons.check;
        break;
      case 'rejected':
        statusText = 'Rejected';
        statusColor = Colors.red;
        statusIcon = LucideIcons.x;
        break;
      case 'under_review':
      case 'under review':
        statusText = 'Under Review';
        statusColor = Colors.blue;
        statusIcon = LucideIcons.search;
        break;
      case 'pending':
      default:
        statusText = 'Pending';
        statusColor = Colors.orange;
        statusIcon = LucideIcons.clock;
        break;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10.w : 14.w,
        vertical: compact ? 10.h : 12.h,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.15),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: [
          if (compact) ...[
            // Compact mode: Icon and title stacked, status badge below
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 18.sp),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Full mode: Original layout
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
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
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
              ),
            ] else if (approvalDate != null) ...[
              SizedBox(height: 8.h),
              Text(
                'Date: ${DateFormat.yMMMd().add_jm().format(approvalDate)}',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
              ),
            ],
            if (notes != null && notes.trim().isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                'Notes:',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                ClaimDetailsHandlerUtils.formatRejectionNote(notes),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// Animated document card with scale effect on press
class _AnimatedDocumentCard extends StatefulWidget {
  final Color borderColor;
  final Widget child;

  const _AnimatedDocumentCard({required this.borderColor, required this.child});

  @override
  State<_AnimatedDocumentCard> createState() => _AnimatedDocumentCardState();
}

class _AnimatedDocumentCardState extends State<_AnimatedDocumentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
