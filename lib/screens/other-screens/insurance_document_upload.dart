import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:insurevis/utils/document_upload_validation_utils.dart';
import 'package:insurevis/utils/document_upload_handler_utils.dart';
import 'package:insurevis/utils/document_upload_pricing_utils.dart';
import 'package:insurevis/utils/document_upload_submission_utils.dart';
import 'package:insurevis/utils/document_upload_ui_utils.dart';

class InsuranceDocumentUpload extends StatefulWidget {
  final List<String> imagePaths;
  final Map<String, Map<String, dynamic>> apiResponses;
  final Map<String, String> assessmentIds;
  final Map<int, String>? selectedRepairOptions;
  final Map<int, Map<String, dynamic>>? repairPricingData;
  final Map<int, Map<String, dynamic>>? replacePricingData;
  final List<Map<String, String>>? manualDamages;
  final double? estimatedDamageCost;
  final Map<String, String>? vehicleData;
  final String? tempJobEstimatePdfPath;

  const InsuranceDocumentUpload({
    super.key,
    required this.imagePaths,
    required this.apiResponses,
    required this.assessmentIds,
    this.selectedRepairOptions,
    this.repairPricingData,
    this.replacePricingData,
    this.manualDamages,
    this.estimatedDamageCost,
    this.vehicleData,
    this.tempJobEstimatePdfPath,
  });

  @override
  State<InsuranceDocumentUpload> createState() =>
      _InsuranceDocumentUploadState();
}

class _InsuranceDocumentUploadState extends State<InsuranceDocumentUpload> {
  final ImagePicker _picker = ImagePicker();

  // Incident information controllers
  final TextEditingController _incidentLocationController =
      TextEditingController();
  final TextEditingController _incidentDateController = TextEditingController();

  // Estimated damage cost
  double _estimatedDamageCost = 0.0;

  // Pricing data for repair/replace options
  final Map<int, Map<String, dynamic>?> _repairPricingData = {};
  final Map<int, Map<String, dynamic>?> _replacePricingData = {};
  final Map<int, bool> _isLoadingPricing = {};

  // Repair/Replace options for each damage
  Map<int, String> _selectedRepairOptions =
      {}; // Track repair/replace selection for each damage

  // Manual damages added by user via "Add Damage" UI
  final List<Map<String, String>> _manualDamages = [];

  // Track which document categories are expanded
  final Map<String, bool> _expandedCategories = {};

  // Note: Manual entry does not capture a specific damage type at this time.

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

  // Currency formatter for display with commas
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );

  // Helper getter to check for severe damage
  bool get _isDamageSevere {
    return DocumentUploadPricingUtils.isDamageSevere(widget.apiResponses);
  }

  @override
  void initState() {
    super.initState();
    // Initialize from passed parameters if available
    if (widget.selectedRepairOptions != null) {
      _selectedRepairOptions = Map<int, String>.from(
        widget.selectedRepairOptions!,
      );
    }
    if (widget.repairPricingData != null) {
      _repairPricingData.addAll(widget.repairPricingData!);
    }
    if (widget.replacePricingData != null) {
      _replacePricingData.addAll(widget.replacePricingData!);
    }
    if (widget.manualDamages != null) {
      _manualDamages.addAll(widget.manualDamages!);
    }
    if (widget.estimatedDamageCost != null) {
      _estimatedDamageCost = widget.estimatedDamageCost!;
    } else {
      _calculateEstimatedDamageCost();
    }
    DocumentUploadHandlerUtils.loadDamageAssessmentImages(
      imagePaths: widget.imagePaths,
      uploadedDocuments: uploadedDocuments,
    );
    // Only fetch pricing if not already provided
    if (widget.selectedRepairOptions == null) {
      _fetchAllPricingData();
    }
    DocumentUploadHandlerUtils.addTempJobEstimatePdf(
      tempJobEstimatePdfPath: widget.tempJobEstimatePdfPath,
      uploadedDocuments: uploadedDocuments,
    );
  }

  /// Fetches pricing data for all detected damages when the screen opens
  Future<void> _fetchAllPricingData() async {
    final damagesList =
        DocumentUploadPricingUtils.extractDamagesFromApiResponses(
          widget.apiResponses,
        );

    if (damagesList.isEmpty) return;

    // Initialize selected repair options to 'repair' by default
    for (int i = 0; i < damagesList.length; i++) {
      if (!_selectedRepairOptions.containsKey(i)) {
        _selectedRepairOptions[i] = 'repair';
      }
    }

    // Fetch pricing data for each damage
    for (int i = 0; i < damagesList.length; i++) {
      final damage = damagesList[i];
      String damagedPart = 'Unknown Part';

      // Extract damaged part
      if (damage.containsKey('damaged_part')) {
        damagedPart = damage['damaged_part']?.toString() ?? 'Unknown Part';
      }

      if (damagedPart != 'Unknown Part') {
        // Fetch pricing data in the background for both repair and replace options
        _fetchPricingForDamage(
          i,
          damagedPart,
          _selectedRepairOptions[i] ?? 'repair',
        );
      }
    }
  }

  void _calculateEstimatedDamageCost() {
    // First, try to get cost from API responses
    double totalCost = DocumentUploadPricingUtils.calculateEstimatedCostFromApi(
      widget.apiResponses,
    );

    // If no API cost available, calculate from pricing data
    if (totalCost == 0.0) {
      totalCost = DocumentUploadPricingUtils.calculateTotalFromPricingData(
        selectedRepairOptions: _selectedRepairOptions,
        repairPricingData: _repairPricingData,
        replacePricingData: _replacePricingData,
      );
    }

    setState(() {
      _estimatedDamageCost = totalCost;
    });
  }

  // Method to fetch pricing data for a damaged part
  Future<void> _fetchPricingForDamage(
    int damageIndex,
    String damagedPart,
    String selectedOption,
  ) async {
    setState(() {
      _isLoadingPricing[damageIndex] = true;
    });

    try {
      final pricingData =
          await DocumentUploadPricingUtils.fetchPricingForDamage(damagedPart);

      if (mounted) {
        setState(() {
          _repairPricingData[damageIndex] = pricingData['repair'];
          _replacePricingData[damageIndex] = pricingData['replace'];
          _isLoadingPricing[damageIndex] = false;
          _calculateEstimatedDamageCost();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _repairPricingData[damageIndex] = null;
          _replacePricingData[damageIndex] = null;
          _isLoadingPricing[damageIndex] = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _incidentLocationController.dispose();
    _incidentDateController.dispose();

    // Clean up temporary PDF if user exits without submitting
    if (widget.tempJobEstimatePdfPath != null) {
      try {
        final tempPdfFile = File(widget.tempJobEstimatePdfPath!);
        if (tempPdfFile.existsSync()) {
          tempPdfFile
              .delete()
              .then((_) {
                debugPrint('Cleaned up temporary job estimate PDF on dispose');
              })
              .catchError((e) {
                debugPrint('Error cleaning up temporary PDF on dispose: $e');
              });
        }
      } catch (e) {
        debugPrint('Error in dispose cleanup: $e');
      }
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        final hasChanges = _hasUserMadeChanges();
        if (hasChanges) {
          final shouldPop = await _showExitConfirmationDialog();
          if (shouldPop == true && context.mounted) {
            Navigator.of(context).pop();
          }
        } else {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: GlobalStyles.backgroundMain,
        appBar: AppBar(
          backgroundColor: GlobalStyles.surfaceMain,
          elevation: 0,
          shadowColor: GlobalStyles.shadowSm.color,
          leading: IconButton(
            icon: Icon(
              LucideIcons.arrowLeft,
              color: GlobalStyles.textPrimary,
              size: GlobalStyles.iconSizeMd,
            ),
            onPressed: () async {
              final hasChanges = _hasUserMadeChanges();
              if (hasChanges) {
                final shouldPop = await _showExitConfirmationDialog();
                if (shouldPop == true && context.mounted) {
                  Navigator.of(context).pop();
                }
              } else {
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
          ),
          title: Text(
            'Insurance Claim',
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyHeading,
              fontSize: GlobalStyles.fontSizeH5,
              fontWeight: GlobalStyles.fontWeightSemiBold,
              color: GlobalStyles.textPrimary,
              letterSpacing: GlobalStyles.letterSpacingH4,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: GlobalStyles.paddingNormal,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: GlobalStyles.spacingMd),
                        // Vehicle Info Section
                        if (widget.vehicleData != null)
                          _buildVehicleInfoSection(),
                        if (widget.vehicleData != null)
                          SizedBox(height: GlobalStyles.spacingMd),
                        // Instructions
                        _buildInstructions(),
                        SizedBox(height: GlobalStyles.spacingMd),
                        // Incident Information
                        _buildIncidentInformationSection(),
                        SizedBox(height: GlobalStyles.spacingMd),
                        // Damage Assessment Images
                        _buildDamageAssessmentImagesSection(),
                        if (widget.imagePaths.isNotEmpty)
                          SizedBox(height: GlobalStyles.spacingMd),
                        // Repair Options
                        if (!_isDamageSevere &&
                            _selectedRepairOptions.isNotEmpty)
                          _buildRepairOptionsSection(),
                        if (!_isDamageSevere &&
                            _selectedRepairOptions.isNotEmpty)
                          SizedBox(height: GlobalStyles.spacingMd),
                        // Estimated Cost
                        _buildEstimatedCostSection(),
                        SizedBox(height: GlobalStyles.spacingMd),
                        // Document Upload Header
                        _buildDocumentUploadHeader(),
                        SizedBox(height: GlobalStyles.spacingMd),
                        // Document Categories
                        _buildDocumentCategories(),
                        SizedBox(height: GlobalStyles.spacingXl),
                      ],
                    ),
                  ),
                ),
              ),
              _buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  /// Checks if the user has made any changes to the form
  bool _hasUserMadeChanges() {
    return DocumentUploadValidationUtils.hasUserMadeChanges(
      locationController: _incidentLocationController,
      dateController: _incidentDateController,
      uploadedDocuments: uploadedDocuments,
      originalImagePaths: widget.imagePaths,
      tempJobEstimatePdfPath: widget.tempJobEstimatePdfPath,
    );
  }

  /// Builds the document upload section header
  Widget _buildDocumentUploadHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Document Upload',
          style: TextStyle(
            fontFamily: GlobalStyles.fontFamilyHeading,
            fontSize: GlobalStyles.fontSizeH5,
            fontWeight: GlobalStyles.fontWeightSemiBold,
            color: GlobalStyles.textPrimary,
            letterSpacing: GlobalStyles.letterSpacingH4,
          ),
        ),
        SizedBox(height: GlobalStyles.spacingSm),
        Text(
          'Upload all required documents marked with *',
          style: TextStyle(
            fontFamily: GlobalStyles.fontFamilyBody,
            fontSize: GlobalStyles.fontSizeCaption,
            color: GlobalStyles.textTertiary,
            height:
                GlobalStyles.lineHeightCaption / GlobalStyles.fontSizeCaption,
          ),
        ),
      ],
    );
  }

  /// Shows a confirmation dialog when user tries to exit with unsaved changes
  Future<bool?> _showExitConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      barrierColor: GlobalStyles.dialogOverlay,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: GlobalStyles.surfaceMain,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              GlobalStyles.dialogBorderRadius,
            ),
          ),
          contentPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon and Title Section
              Container(
                width: double.infinity,
                padding: GlobalStyles.cardPadding,
                decoration: BoxDecoration(
                  color: GlobalStyles.primaryMain.withOpacity(0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(GlobalStyles.dialogBorderRadius),
                    topRight: Radius.circular(GlobalStyles.dialogBorderRadius),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(GlobalStyles.spacingMd),
                      decoration: BoxDecoration(
                        color: GlobalStyles.warningMain.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.triangleAlert,
                        color: GlobalStyles.warningMain,
                        size: GlobalStyles.iconSizeLg,
                      ),
                    ),
                    SizedBox(height: GlobalStyles.spacingMd),
                    Text(
                      'Unsaved Changes',
                      style: TextStyle(
                        fontFamily: GlobalStyles.fontFamilyHeading,
                        fontSize: GlobalStyles.fontSizeH4,
                        fontWeight: GlobalStyles.fontWeightSemiBold,
                        color: GlobalStyles.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Message Section
              Padding(
                padding: GlobalStyles.cardPadding,
                child: Column(
                  children: [
                    Text(
                      'You have unsaved changes. Are you sure you want to exit?',
                      style: TextStyle(
                        fontFamily: GlobalStyles.fontFamilyBody,
                        fontSize: GlobalStyles.fontSizeBody1,
                        color: GlobalStyles.textPrimary,
                        height:
                            GlobalStyles.lineHeightBody1 /
                            GlobalStyles.fontSizeBody1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: GlobalStyles.spacingSm),
                    Text(
                      'All your progress will be lost.',
                      style: TextStyle(
                        fontFamily: GlobalStyles.fontFamilyBody,
                        fontSize: GlobalStyles.fontSizeBody2,
                        color: GlobalStyles.textTertiary,
                        fontWeight: GlobalStyles.fontWeightMedium,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Buttons Section
              Padding(
                padding: EdgeInsets.fromLTRB(
                  GlobalStyles.spacingMd,
                  0,
                  GlobalStyles.spacingMd,
                  GlobalStyles.spacingMd,
                ),
                child: Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: GlobalStyles.spacingMd,
                          ),
                          side: BorderSide(
                            color: GlobalStyles.primaryMain,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              GlobalStyles.radiusMd,
                            ),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: GlobalStyles.fontFamilyBody,
                            fontSize: GlobalStyles.fontSizeBody2,
                            fontWeight: GlobalStyles.fontWeightSemiBold,
                            color: GlobalStyles.primaryMain,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: GlobalStyles.spacingMd),
                    // Exit Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GlobalStyles.errorMain,
                          padding: EdgeInsets.symmetric(
                            vertical: GlobalStyles.spacingMd,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              GlobalStyles.radiusMd,
                            ),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Exit',
                          style: TextStyle(
                            fontFamily: GlobalStyles.fontFamilyBody,
                            fontSize: GlobalStyles.fontSizeBody2,
                            fontWeight: GlobalStyles.fontWeightSemiBold,
                            color: GlobalStyles.surfaceMain,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVehicleInfoSection() {
    if (widget.vehicleData == null) return const SizedBox.shrink();

    final make = widget.vehicleData!['make'] ?? 'N/A';
    final model = widget.vehicleData!['model'] ?? 'N/A';
    final year = widget.vehicleData!['year'] ?? 'N/A';
    final plateNumber = widget.vehicleData!['plate_number'] ?? 'N/A';

    return Container(
      decoration: BoxDecoration(
        color: GlobalStyles.surfaceMain,
        borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
        border: Border.all(
          color: GlobalStyles.primaryMain.withAlpha(25),
          width: 1,
        ),
        boxShadow: [GlobalStyles.shadowSm],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Container(
            padding: EdgeInsets.all(GlobalStyles.spacingMd),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(GlobalStyles.radiusMd),
                topRight: Radius.circular(GlobalStyles.radiusMd),
              ),
              color: GlobalStyles.primaryMain.withAlpha(8),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.car,
                  color: GlobalStyles.primaryMain,
                  size: GlobalStyles.iconSizeMd,
                ),
                SizedBox(width: GlobalStyles.spacingMd),
                Text(
                  'Vehicle Information',
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyHeading,
                    fontSize: GlobalStyles.fontSizeH5,
                    fontWeight: GlobalStyles.fontWeightSemiBold,
                    color: GlobalStyles.textPrimary,
                    letterSpacing: GlobalStyles.letterSpacingH4,
                  ),
                ),
              ],
            ),
          ),
          // Vehicle details
          Container(
            padding: EdgeInsets.all(GlobalStyles.spacingMd),
            child: Column(
              children: [
                _buildVehicleInfoRow('Make', make),
                Container(
                  margin: EdgeInsets.symmetric(
                    vertical: GlobalStyles.spacingMd,
                  ),
                  height: 1,
                  color: GlobalStyles.textSecondary.withAlpha(25),
                ),
                _buildVehicleInfoRow('Model', model),
                Container(
                  margin: EdgeInsets.symmetric(
                    vertical: GlobalStyles.spacingMd,
                  ),
                  height: 1,
                  color: GlobalStyles.textSecondary.withAlpha(25),
                ),
                _buildVehicleInfoRow('Year', year),
                Container(
                  margin: EdgeInsets.symmetric(
                    vertical: GlobalStyles.spacingMd,
                  ),
                  height: 1,
                  color: GlobalStyles.textSecondary.withAlpha(25),
                ),
                _buildVehicleInfoRow('Plate Number', plateNumber),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: GlobalStyles.fontFamilyBody,
            fontSize: GlobalStyles.fontSizeBody2,
            fontWeight: GlobalStyles.fontWeightRegular,
            color: GlobalStyles.textTertiary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: GlobalStyles.fontFamilyBody,
            fontSize: GlobalStyles.fontSizeBody2,
            fontWeight: GlobalStyles.fontWeightSemiBold,
            color: GlobalStyles.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Container(
      decoration: BoxDecoration(
        color: GlobalStyles.infoMain.withAlpha(10),
        borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
        border: Border.all(
          color: GlobalStyles.infoMain.withAlpha(40),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Container(
            padding: EdgeInsets.all(GlobalStyles.spacingMd),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(GlobalStyles.radiusMd),
                topRight: Radius.circular(GlobalStyles.radiusMd),
              ),
              color: GlobalStyles.infoMain.withAlpha(15),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.info,
                  color: GlobalStyles.infoMain,
                  size: GlobalStyles.iconSizeMd,
                ),
                SizedBox(width: GlobalStyles.spacingMd),
                Expanded(
                  child: Text(
                    'Required Documents',
                    style: TextStyle(
                      fontFamily: GlobalStyles.fontFamilyHeading,
                      fontSize: GlobalStyles.fontSizeH5,
                      fontWeight: GlobalStyles.fontWeightSemiBold,
                      color: GlobalStyles.textPrimary,
                      letterSpacing: GlobalStyles.letterSpacingH4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Instructions content
          Padding(
            padding: EdgeInsets.all(GlobalStyles.spacingMd),
            child: Text(
              'Please upload all required documents marked with *. Ensure documents are clear, '
              'readable, and in PDF or image format.',
              style: TextStyle(
                fontFamily: GlobalStyles.fontFamilyBody,
                fontSize: GlobalStyles.fontSizeBody2,
                color: GlobalStyles.textSecondary,
                height:
                    GlobalStyles.lineHeightBody2 / GlobalStyles.fontSizeBody2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentInformationSection() {
    return Container(
      decoration: BoxDecoration(
        color: GlobalStyles.surfaceMain,
        borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
        border: Border.all(
          color: GlobalStyles.primaryMain.withAlpha(25),
          width: 1,
        ),
        boxShadow: [GlobalStyles.shadowSm],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(GlobalStyles.spacingMd),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(GlobalStyles.radiusMd),
                topRight: Radius.circular(GlobalStyles.radiusMd),
              ),
              color: GlobalStyles.primaryMain.withAlpha(8),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.mapPin,
                  color: GlobalStyles.primaryMain,
                  size: GlobalStyles.iconSizeMd,
                ),
                SizedBox(width: GlobalStyles.spacingMd),
                Text(
                  'Incident Information',
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyHeading,
                    fontSize: GlobalStyles.fontSizeH5,
                    fontWeight: GlobalStyles.fontWeightSemiBold,
                    color: GlobalStyles.textPrimary,
                    letterSpacing: GlobalStyles.letterSpacingH4,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(GlobalStyles.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location field
                _buildIncidentInputField(
                  controller: _incidentLocationController,
                  label: 'Incident Location',
                  hint: 'e.g., EDSA Quezon City, Makati Avenue',
                  icon: LucideIcons.mapPin,
                ),
                SizedBox(height: GlobalStyles.spacingMd),

                // Date field
                _buildIncidentDateField(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: GlobalStyles.primaryMain,
              size: GlobalStyles.iconSizeSm,
            ),
            SizedBox(width: GlobalStyles.spacingSm),
            Text(
              label,
              style: TextStyle(
                fontFamily: GlobalStyles.fontFamilyBody,
                fontSize: GlobalStyles.fontSizeBody2,
                fontWeight: GlobalStyles.fontWeightSemiBold,
                color: GlobalStyles.textTertiary,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(
                fontFamily: GlobalStyles.fontFamilyBody,
                fontSize: GlobalStyles.fontSizeBody2,
                color: GlobalStyles.errorMain,
                fontWeight: GlobalStyles.fontWeightBold,
              ),
            ),
          ],
        ),
        SizedBox(height: GlobalStyles.spacingSm),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(
            fontFamily: GlobalStyles.fontFamilyBody,
            color: GlobalStyles.textPrimary,
            fontSize: GlobalStyles.fontSizeBody2,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: GlobalStyles.fontFamilyBody,
              color: GlobalStyles.textTertiary,
              fontSize: GlobalStyles.fontSizeBody2,
            ),
            filled: true,
            fillColor: GlobalStyles.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                GlobalStyles.inputBorderRadius,
              ),
              borderSide: BorderSide(color: GlobalStyles.inputBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                GlobalStyles.inputBorderRadius,
              ),
              borderSide: BorderSide(color: GlobalStyles.inputBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                GlobalStyles.inputBorderRadius,
              ),
              borderSide: BorderSide(
                color: GlobalStyles.primaryMain.withAlpha(153),
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: GlobalStyles.paddingNormal,
              vertical: GlobalStyles.paddingNormal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIncidentDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              LucideIcons.calendar,
              color: GlobalStyles.primaryMain,
              size: GlobalStyles.fontSizeBody2,
            ),
            SizedBox(width: GlobalStyles.spacingMd),
            Text(
              'Incident Date',
              style: TextStyle(
                fontFamily: GlobalStyles.fontFamilyBody,
                fontSize: GlobalStyles.fontSizeBody2,
                fontWeight: GlobalStyles.fontWeightSemiBold,
                color: GlobalStyles.textTertiary,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(
                fontFamily: GlobalStyles.fontFamilyBody,
                fontSize: GlobalStyles.fontSizeBody2,
                color: GlobalStyles.errorMain,
                fontWeight: GlobalStyles.fontWeightBold,
              ),
            ),
          ],
        ),
        SizedBox(height: GlobalStyles.spacingMd),
        TextFormField(
          controller: _incidentDateController,
          readOnly: true,
          style: TextStyle(
            fontFamily: GlobalStyles.fontFamilyBody,
            color: GlobalStyles.textPrimary,
            fontSize: GlobalStyles.fontSizeBody2,
          ),
          decoration: InputDecoration(
            hintText: 'Select incident date',
            hintStyle: TextStyle(
              fontFamily: GlobalStyles.fontFamilyBody,
              color: GlobalStyles.textTertiary,
              fontSize: GlobalStyles.fontSizeBody2,
            ),
            filled: true,
            fillColor: GlobalStyles.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
              borderSide: BorderSide(color: GlobalStyles.inputBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
              borderSide: BorderSide(color: GlobalStyles.inputBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
              borderSide: BorderSide(
                color: GlobalStyles.primaryMain.withAlpha(153),
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: GlobalStyles.spacingMd,
              vertical: GlobalStyles.spacingMd,
            ),
            suffixIcon: Icon(
              LucideIcons.calendar,
              color: GlobalStyles.textTertiary,
              size: GlobalStyles.fontSizeBody2,
            ),
          ),
          onTap: () async {
            final dateString = await DocumentUploadUIUtils.pickIncidentDate(
              context,
              _incidentDateController.text,
            );
            if (dateString != null) {
              setState(() {
                _incidentDateController.text = dateString;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildEstimatedCostSection() {
    return Container(
      decoration: BoxDecoration(
        color: GlobalStyles.surfaceMain,
        borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
        border: Border.all(
          color: GlobalStyles.primaryMain.withAlpha(25),
          width: 1,
        ),
        boxShadow: [GlobalStyles.shadowSm],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(GlobalStyles.spacingMd),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(GlobalStyles.radiusMd),
                topRight: Radius.circular(GlobalStyles.radiusMd),
              ),
              color: GlobalStyles.primaryMain.withAlpha(8),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.chartBar,
                  color: GlobalStyles.primaryMain,
                  size: GlobalStyles.iconSizeMd,
                ),
                SizedBox(width: GlobalStyles.spacingMd),
                Expanded(
                  child: Text(
                    'Estimated Damage Cost',
                    style: TextStyle(
                      fontFamily: GlobalStyles.fontFamilyHeading,
                      fontSize: GlobalStyles.fontSizeH5,
                      fontWeight: GlobalStyles.fontWeightSemiBold,
                      color: GlobalStyles.textPrimary,
                      letterSpacing: GlobalStyles.letterSpacingH4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Cost display
          Padding(
            padding: EdgeInsets.all(GlobalStyles.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Based on your selected repair options',
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyBody,
                    fontSize: GlobalStyles.fontSizeCaption,
                    color: GlobalStyles.textTertiary,
                  ),
                ),
                SizedBox(height: GlobalStyles.spacingMd),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(GlobalStyles.spacingMd),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
                    color: GlobalStyles.successMain.withAlpha(15),
                    border: Border.all(
                      color: GlobalStyles.successMain.withAlpha(50),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _currencyFormat.format(_estimatedDamageCost),
                        style: TextStyle(
                          fontFamily: GlobalStyles.fontFamilyHeading,
                          fontSize: GlobalStyles.fontSizeH4,
                          fontWeight: GlobalStyles.fontWeightBold,
                          color: GlobalStyles.successMain,
                          letterSpacing: GlobalStyles.letterSpacingH3,
                        ),
                      ),
                      SizedBox(height: GlobalStyles.spacingXs),
                      Text(
                        'estimated total',
                        style: TextStyle(
                          fontFamily: GlobalStyles.fontFamilyBody,
                          fontSize: GlobalStyles.fontSizeCaption,
                          color: GlobalStyles.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDamageAssessmentImagesSection() {
    if (widget.imagePaths.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(GlobalStyles.spacingMd),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
        color: GlobalStyles.surfaceMain,
        border: Border.all(
          color: GlobalStyles.textSecondary.withAlpha(25),
          width: 1,
        ),
        boxShadow: [GlobalStyles.shadowSm],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Damage Assessment',
                      style: TextStyle(
                        fontFamily: GlobalStyles.fontFamilyHeading,
                        fontSize: GlobalStyles.fontSizeH5,
                        fontWeight: GlobalStyles.fontWeightSemiBold,
                        color: GlobalStyles.textPrimary,
                        letterSpacing: GlobalStyles.letterSpacingH4,
                      ),
                    ),
                    SizedBox(height: GlobalStyles.spacingXs),
                    Text(
                      '${widget.imagePaths.length} photo${widget.imagePaths.length > 1 ? 's' : ''} taken',
                      style: TextStyle(
                        fontFamily: GlobalStyles.fontFamilyBody,
                        fontSize: GlobalStyles.fontSizeCaption,
                        color: GlobalStyles.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: GlobalStyles.spacingMd),
              AnimatedScale(
                scale: 1.0,
                duration: GlobalStyles.durationNormal,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: GlobalStyles.spacingSm,
                    vertical: GlobalStyles.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: GlobalStyles.successMain,
                    borderRadius: BorderRadius.circular(GlobalStyles.radiusSm),
                  ),
                  child: Text(
                    '${widget.imagePaths.length}',
                    style: TextStyle(
                      fontFamily: GlobalStyles.fontFamilyHeading,
                      fontSize: GlobalStyles.fontSizeCaption,
                      color: GlobalStyles.surfaceMain,
                      fontWeight: GlobalStyles.fontWeightBold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: GlobalStyles.spacingMd),

          // Display assessment images in a grid
          _buildAssessmentImagesGrid(),
        ],
      ),
    );
  }

  Widget _buildAssessmentImagesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: GlobalStyles.spacingMd,
        mainAxisSpacing: GlobalStyles.spacingMd,
        childAspectRatio: 1.0,
      ),
      itemCount: widget.imagePaths.length,
      itemBuilder: (context, index) {
        final imagePath = widget.imagePaths[index];
        return _buildAssessmentImageItem(imagePath, index);
      },
    );
  }

  Widget _buildAssessmentImageItem(String imagePath, int index) {
    return AnimatedContainer(
      duration: GlobalStyles.durationNormal,
      curve: GlobalStyles.easingDefault,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
        border: Border.all(
          color: GlobalStyles.successMain.withAlpha(76),
          width: 2,
        ),
        boxShadow: [GlobalStyles.shadowMd],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
        child: Stack(
          children: [
            // Image with fade-in
            AnimatedOpacity(
              opacity: 1.0,
              duration: GlobalStyles.durationNormal,
              child: Image.file(
                File(imagePath),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: GlobalStyles.backgroundMain,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.imageOff,
                            color: GlobalStyles.textTertiary,
                            size: GlobalStyles.iconSizeLg,
                          ),
                          SizedBox(height: GlobalStyles.spacingMd),
                          Text(
                            'Image Error',
                            style: TextStyle(
                              fontFamily: GlobalStyles.fontFamilyBody,
                              color: GlobalStyles.textTertiary,
                              fontSize: GlobalStyles.fontSizeCaption,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Top-right assessment badge with slide-in animation
            Positioned(
              top: GlobalStyles.spacingMd,
              right: GlobalStyles.spacingMd,
              child: AnimatedSlide(
                offset: Offset.zero,
                duration: GlobalStyles.durationNormal,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: GlobalStyles.spacingSm,
                    vertical: GlobalStyles.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: GlobalStyles.successMain,
                    borderRadius: BorderRadius.circular(GlobalStyles.radiusSm),
                    boxShadow: [GlobalStyles.shadowMd],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.check,
                        color: GlobalStyles.surfaceMain,
                        size: GlobalStyles.iconSizeXs,
                      ),
                      SizedBox(width: GlobalStyles.spacingXs),
                      Text(
                        'ASSESSED',
                        style: TextStyle(
                          fontFamily: GlobalStyles.fontFamilyBody,
                          color: GlobalStyles.surfaceMain,
                          fontSize: GlobalStyles.fontSizeCaption,
                          fontWeight: GlobalStyles.fontWeightBold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom-left image counter with fade-in animation
            Positioned(
              bottom: GlobalStyles.spacingMd,
              left: GlobalStyles.spacingMd,
              child: AnimatedOpacity(
                opacity: 1.0,
                duration: GlobalStyles.durationNormal,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: GlobalStyles.spacingSm,
                    vertical: GlobalStyles.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: GlobalStyles.primaryMain,
                    borderRadius: BorderRadius.circular(GlobalStyles.radiusSm),
                    boxShadow: [GlobalStyles.shadowMd],
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontFamily: GlobalStyles.fontFamilyHeading,
                      color: GlobalStyles.surfaceMain,
                      fontSize: GlobalStyles.fontSizeCaption,
                      fontWeight: GlobalStyles.fontWeightBold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepairOptionsSection() {
    // If damage is severe, hide this entire section.
    if (_isDamageSevere) {
      return const SizedBox.shrink();
    }

    // Check if we have repair options data from PDF Assessment
    final hasRepairData = _selectedRepairOptions.isNotEmpty;

    // If no repair data, show button to go to PDF Assessment
    if (!hasRepairData) {
      return Container(
        padding: EdgeInsets.all(GlobalStyles.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Damage Assessment',
              style: TextStyle(
                fontFamily: GlobalStyles.fontFamilyBody,
                fontSize: GlobalStyles.fontSizeBody2,
                fontWeight: GlobalStyles.fontWeightBold,
                color: GlobalStyles.textPrimary,
              ),
            ),
            SizedBox(height: GlobalStyles.spacingMd),
            Container(
              padding: EdgeInsets.all(GlobalStyles.spacingMd),
              decoration: BoxDecoration(
                color: GlobalStyles.warningMain.withAlpha(38),
                borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
                border: Border.all(
                  color: GlobalStyles.warningMain.withAlpha(76),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    LucideIcons.circleAlert,
                    color: GlobalStyles.warningMain,
                    size: GlobalStyles.fontSizeBody2,
                  ),
                  SizedBox(height: GlobalStyles.spacingMd),
                  Text(
                    'Complete Your Assessment',
                    style: TextStyle(
                      fontFamily: GlobalStyles.fontFamilyBody,
                      fontSize: GlobalStyles.fontSizeBody2,
                      fontWeight: GlobalStyles.fontWeightBold,
                      color: GlobalStyles.textPrimary,
                    ),
                  ),
                  SizedBox(height: GlobalStyles.spacingMd),
                  Text(
                    'Please review your damage assessment and select repair options before proceeding with your claim.',
                    style: TextStyle(
                      fontFamily: GlobalStyles.fontFamilyBody,
                      fontSize: GlobalStyles.fontSizeBody2,
                      color: GlobalStyles.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: GlobalStyles.spacingMd),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Go back to PDF Assessment
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GlobalStyles.warningMain,
                        padding: EdgeInsets.symmetric(
                          vertical: GlobalStyles.spacingMd,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            GlobalStyles.radiusMd,
                          ),
                        ),
                      ),
                      child: Text(
                        'Go to Assessment Report',
                        style: TextStyle(
                          fontFamily: GlobalStyles.fontFamilyBody,
                          fontSize: GlobalStyles.fontSizeBody2,
                          fontWeight: GlobalStyles.fontWeightSemiBold,
                          color: GlobalStyles.surfaceMain,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Extract damage information from API responses
    List<Map<String, dynamic>> damagesList = [];

    if (widget.apiResponses.isNotEmpty) {
      for (var response in widget.apiResponses.values) {
        if (response['damages'] is List) {
          damagesList.addAll(
            (response['damages'] as List).cast<Map<String, dynamic>>(),
          );
        } else if (response['prediction'] is List) {
          damagesList.addAll(
            (response['prediction'] as List).cast<Map<String, dynamic>>(),
          );
        }
      }
    }

    // Show summary of selected repair options
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Damage Assessment',
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyHeading,
              fontSize: GlobalStyles.fontSizeH5,
              fontWeight: GlobalStyles.fontWeightSemiBold,
              color: GlobalStyles.textPrimary,
              letterSpacing: GlobalStyles.letterSpacingH4,
            ),
          ),
          SizedBox(height: GlobalStyles.spacingSm),
          Text(
            '${damagesList.length + _manualDamages.length} damage${(damagesList.length + _manualDamages.length) > 1 ? 's' : ''} detected',
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyBody,
              fontSize: GlobalStyles.fontSizeCaption,
              color: GlobalStyles.textTertiary,
            ),
          ),
          SizedBox(height: GlobalStyles.spacingMd),

          // Display summary of damages and selected options
          ...(() {
            final List<Widget> widgets = [];

            // API-detected damages
            for (int i = 0; i < damagesList.length; i++) {
              final damage = damagesList[i];
              final selectedOption = _selectedRepairOptions[i];

              if (selectedOption != null) {
                widgets.add(_buildDamageSummaryCard(i, damage, selectedOption));
                widgets.add(SizedBox(height: GlobalStyles.spacingMd));
              }
            }

            // Manual damages
            for (int i = 0; i < _manualDamages.length; i++) {
              final damage = _manualDamages[i];
              final globalIndex = -(i + 1);
              final selectedOption = _selectedRepairOptions[globalIndex];

              if (selectedOption != null) {
                widgets.add(
                  _buildManualDamageSummaryCard(
                    globalIndex,
                    damage,
                    selectedOption,
                  ),
                );
                widgets.add(SizedBox(height: GlobalStyles.spacingMd));
              }
            }

            return widgets;
          })(),
        ],
      ),
    );
  }

  Widget _buildDamageSummaryCard(
    int index,
    Map<String, dynamic> damage,
    String selectedOption,
  ) {
    String damagedPart = 'Unknown Part';
    String damageType = 'Unknown Damage';

    if (damage.containsKey('damaged_part')) {
      damagedPart = damage['damaged_part']?.toString() ?? 'Unknown Part';
    }
    if (damage.containsKey('damage_type')) {
      final damageTypeValue = damage['damage_type'];
      if (damageTypeValue is Map && damageTypeValue.containsKey('class_name')) {
        damageType =
            damageTypeValue['class_name']?.toString() ?? 'Unknown Damage';
      } else {
        damageType = damageTypeValue?.toString() ?? 'Unknown Damage';
      }
    }

    final repairPricing = _repairPricingData[index];
    final replacePricing = _replacePricingData[index];

    return AnimatedContainer(
      duration: GlobalStyles.durationNormal,
      curve: GlobalStyles.easingDefault,
      padding: EdgeInsets.symmetric(
        horizontal: GlobalStyles.spacingMd,
        vertical: GlobalStyles.spacingSm,
      ),
      margin: EdgeInsets.only(bottom: GlobalStyles.spacingSm),
      decoration: BoxDecoration(
        color: GlobalStyles.surfaceMain,
        borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
        border: Border.all(
          color: GlobalStyles.primaryMain.withAlpha(40),
          width: 1,
        ),
        boxShadow: [GlobalStyles.shadowSm],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact header with option badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      damagedPart,
                      style: TextStyle(
                        fontFamily: GlobalStyles.fontFamilyBody,
                        fontSize: GlobalStyles.fontSizeBody2,
                        fontWeight: GlobalStyles.fontWeightSemiBold,
                        color: GlobalStyles.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (damageType.isNotEmpty)
                      Text(
                        damageType,
                        style: TextStyle(
                          fontFamily: GlobalStyles.fontFamilyBody,
                          fontSize: GlobalStyles.fontSizeCaption,
                          color: GlobalStyles.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              SizedBox(width: GlobalStyles.spacingMd),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: GlobalStyles.spacingSm,
                  vertical: GlobalStyles.spacingXs,
                ),
                decoration: BoxDecoration(
                  color:
                      selectedOption == 'repair'
                          ? GlobalStyles.infoMain
                          : GlobalStyles.warningMain,
                  borderRadius: BorderRadius.circular(GlobalStyles.radiusSm),
                ),
                child: Text(
                  selectedOption.toUpperCase(),
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyBody,
                    color: GlobalStyles.surfaceMain,
                    fontSize: GlobalStyles.fontSizeCaption,
                    fontWeight: GlobalStyles.fontWeightBold,
                  ),
                ),
              ),
            ],
          ),
          if (repairPricing != null || replacePricing != null) ...[
            SizedBox(height: GlobalStyles.spacingSm),
            _buildCompactPricingSummary(
              selectedOption,
              repairPricing,
              replacePricing,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildManualDamageSummaryCard(
    int globalIndex,
    Map<String, String> damage,
    String selectedOption,
  ) {
    final damagedPart = damage['damaged_part'] ?? 'Unknown Part';
    final damageType = damage['damage_type'] ?? 'Unknown Damage';

    final repairPricing = _repairPricingData[globalIndex];
    final replacePricing = _replacePricingData[globalIndex];

    return AnimatedContainer(
      duration: GlobalStyles.durationNormal,
      curve: GlobalStyles.easingDefault,
      padding: EdgeInsets.symmetric(
        horizontal: GlobalStyles.spacingMd,
        vertical: GlobalStyles.spacingSm,
      ),
      margin: EdgeInsets.only(bottom: GlobalStyles.spacingSm),
      decoration: BoxDecoration(
        color: GlobalStyles.surfaceMain,
        borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
        border: Border.all(
          color: GlobalStyles.purpleMain.withAlpha(40),
          width: 1,
        ),
        boxShadow: [GlobalStyles.shadowSm],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with manual badge and option
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: GlobalStyles.spacingSm,
                            vertical: GlobalStyles.spacingXs,
                          ),
                          decoration: BoxDecoration(
                            color: GlobalStyles.purpleMain.withAlpha(20),
                            borderRadius: BorderRadius.circular(
                              GlobalStyles.radiusSm,
                            ),
                            border: Border.all(
                              color: GlobalStyles.purpleMain.withAlpha(50),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'MANUAL',
                            style: TextStyle(
                              fontFamily: GlobalStyles.fontFamilyBody,
                              color: GlobalStyles.purpleMain,
                              fontSize: GlobalStyles.fontSizeCaption,
                              fontWeight: GlobalStyles.fontWeightBold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: GlobalStyles.spacingSm),
                    Text(
                      damagedPart,
                      style: TextStyle(
                        fontFamily: GlobalStyles.fontFamilyBody,
                        fontSize: GlobalStyles.fontSizeBody2,
                        fontWeight: GlobalStyles.fontWeightSemiBold,
                        color: GlobalStyles.textPrimary,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 1,
                    ),
                    if (damageType.isNotEmpty) ...[
                      SizedBox(height: GlobalStyles.spacingXs),
                      Text(
                        damageType,
                        style: TextStyle(
                          fontFamily: GlobalStyles.fontFamilyBody,
                          fontSize: GlobalStyles.fontSizeCaption,
                          color: GlobalStyles.textTertiary,
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: GlobalStyles.spacingMd),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: GlobalStyles.spacingSm,
                  vertical: GlobalStyles.spacingXs,
                ),
                decoration: BoxDecoration(
                  color:
                      selectedOption == 'repair'
                          ? GlobalStyles.infoMain
                          : GlobalStyles.warningMain,
                  borderRadius: BorderRadius.circular(GlobalStyles.radiusSm),
                ),
                child: Text(
                  selectedOption.toUpperCase(),
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyBody,
                    color: GlobalStyles.surfaceMain,
                    fontSize: GlobalStyles.fontSizeCaption,
                    fontWeight: GlobalStyles.fontWeightBold,
                  ),
                ),
              ),
            ],
          ),
          if (repairPricing != null || replacePricing != null) ...[
            SizedBox(height: GlobalStyles.spacingSm),
            _buildCompactPricingSummary(
              selectedOption,
              repairPricing,
              replacePricing,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactPricingSummary(
    String option,
    Map<String, dynamic>? repairPricing,
    Map<String, dynamic>? replacePricing,
  ) {
    double finalPrice = 0.0;

    if (option == 'replace') {
      final thinsmithPrice =
          (replacePricing?['insurance'] as num?)?.toDouble() ?? 0.0;
      final bodyPaintPrice =
          repairPricing != null
              ? (repairPricing['srp_insurance'] as num?)?.toDouble() ?? 0.0
              : 0.0;
      finalPrice = thinsmithPrice + bodyPaintPrice;
    } else {
      finalPrice = (repairPricing?['srp_insurance'] as num?)?.toDouble() ?? 0.0;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Total:',
          style: TextStyle(
            fontFamily: GlobalStyles.fontFamilyBody,
            color: GlobalStyles.textPrimary,
            fontSize: GlobalStyles.fontSizeBody2,
            fontWeight: GlobalStyles.fontWeightSemiBold,
          ),
        ),
        Text(
          _currencyFormat.format(finalPrice),
          style: TextStyle(
            fontFamily: GlobalStyles.fontFamilyBody,
            color: GlobalStyles.primaryMain,
            fontSize: GlobalStyles.fontSizeBody2,
            fontWeight: GlobalStyles.fontWeightBold,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentCategories() {
    final documentCategories = [
      {
        'title': 'LTO O.R (Official Receipt)',
        'key': 'lto_or',
        'description':
            'Upload photocopy/PDF of LTO Official Receipt with number',
        'required': true,
      },
      {
        'title': 'LTO C.R (Certificate of Registration)',
        'key': 'lto_cr',
        'description':
            'Upload photocopy/PDF of LTO Certificate of Registration with number',
        'required': true,
      },
      {
        'title': 'Driver\'s License',
        'key': 'drivers_license',
        'description': 'Upload photocopy/PDF of driver\'s license',
        'required': true,
      },
      {
        'title': 'Valid ID of Owner',
        'key': 'owner_valid_id',
        'description': 'Upload photocopy/PDF of owner\'s valid government ID',
        'required': true,
      },
      {
        'title': 'Police Report/Affidavit',
        'key': 'police_report',
        'description': 'Upload original police report or affidavit',
        'required': true,
      },
      {
        'title': 'Insurance Policy',
        'key': 'insurance_policy',
        'description': 'Upload photocopy/PDF of your insurance policy',
        'required': true,
      },
      {
        'title': 'Job Estimate',
        'key': 'job_estimate',
        'description': 'Upload repair/job estimate from service provider',
        'required': true,
      },
      {
        'title': 'Pictures of Damage',
        'key': 'damage_photos',
        'description':
            'Assessment photos are already included. You can add more damage photos or PDF documents if needed.',
        'required': true,
      },
      {
        'title': 'Stencil Strips',
        'key': 'stencil_strips',
        'description': 'Upload stencil strips documentation',
        'required': true,
      },
      {
        'title': 'Additional Documents',
        'key': 'additional_documents',
        'description': 'Upload any other relevant documents (Optional)',
        'required': false,
      },
    ];

    int totalUploaded = uploadedDocuments.values.fold(
      0,
      (sum, files) => sum + files.length,
    );
    int requiredCount =
        documentCategories.where((cat) => cat['required'] as bool).length;
    int uploadedRequired = 0;
    for (final cat in documentCategories.where((c) => c['required'] as bool)) {
      if ((uploadedDocuments[cat['key']] ?? []).isNotEmpty) {
        uploadedRequired++;
      }
    }

    return Column(
      children: [
        // Document upload progress header
        Container(
          padding: EdgeInsets.all(GlobalStyles.spacingMd),
          decoration: BoxDecoration(
            color: GlobalStyles.primaryMain.withAlpha(8),
            borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
            border: Border.all(
              color: GlobalStyles.primaryMain.withAlpha(25),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Documents Uploaded',
                          style: TextStyle(
                            fontFamily: GlobalStyles.fontFamilyHeading,
                            fontSize: GlobalStyles.fontSizeBody2,
                            fontWeight: GlobalStyles.fontWeightSemiBold,
                            color: GlobalStyles.textPrimary,
                          ),
                        ),
                        SizedBox(height: GlobalStyles.spacingXs),
                        Text(
                          '$uploadedRequired of $requiredCount required documents',
                          style: TextStyle(
                            fontFamily: GlobalStyles.fontFamilyBody,
                            fontSize: GlobalStyles.fontSizeCaption,
                            color: GlobalStyles.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: GlobalStyles.spacingMd),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: GlobalStyles.spacingSm,
                      vertical: GlobalStyles.spacingXs,
                    ),
                    decoration: BoxDecoration(
                      color:
                          uploadedRequired == requiredCount
                              ? GlobalStyles.successMain
                              : GlobalStyles.warningMain,
                      borderRadius: BorderRadius.circular(
                        GlobalStyles.radiusSm,
                      ),
                    ),
                    child: Text(
                      '$totalUploaded',
                      style: TextStyle(
                        fontFamily: GlobalStyles.fontFamilyHeading,
                        fontSize: GlobalStyles.fontSizeCaption,
                        color: GlobalStyles.surfaceMain,
                        fontWeight: GlobalStyles.fontWeightBold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: GlobalStyles.spacingMd),
              ClipRRect(
                borderRadius: BorderRadius.circular(GlobalStyles.radiusSm),
                child: LinearProgressIndicator(
                  value:
                      requiredCount > 0 ? uploadedRequired / requiredCount : 0,
                  minHeight: 4,
                  backgroundColor: GlobalStyles.textSecondary.withAlpha(25),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    uploadedRequired == requiredCount
                        ? GlobalStyles.successMain
                        : GlobalStyles.primaryMain,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: GlobalStyles.spacingMd),

        // Collapsible document categories
        ...documentCategories.map((cat) {
          final key = cat['key'] as String;
          final isExpanded = _expandedCategories[key] ?? false;
          final files = uploadedDocuments[key] ?? [];
          final hasFiles = files.isNotEmpty;

          return Padding(
            padding: EdgeInsets.only(bottom: GlobalStyles.spacingMd),
            child: Column(
              children: [
                // Category header (clickable to expand/collapse)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _expandedCategories[key] = !isExpanded;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(GlobalStyles.spacingMd),
                      decoration: BoxDecoration(
                        color:
                            hasFiles
                                ? GlobalStyles.successMain.withAlpha(8)
                                : GlobalStyles.surfaceMain,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(GlobalStyles.radiusMd),
                          topRight: Radius.circular(GlobalStyles.radiusMd),
                        ),
                        border: Border.all(
                          color:
                              hasFiles
                                  ? GlobalStyles.successMain.withAlpha(50)
                                  : GlobalStyles.textSecondary.withAlpha(25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        cat['title'] as String,
                                        style: TextStyle(
                                          fontFamily:
                                              GlobalStyles.fontFamilyBody,
                                          fontSize: GlobalStyles.fontSizeBody2,
                                          fontWeight:
                                              GlobalStyles.fontWeightSemiBold,
                                          color: GlobalStyles.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (cat['required'] as bool)
                                      Padding(
                                        padding: EdgeInsets.only(
                                          left: GlobalStyles.spacingSm,
                                        ),
                                        child: Text(
                                          '*',
                                          style: TextStyle(
                                            fontFamily:
                                                GlobalStyles.fontFamilyBody,
                                            fontSize:
                                                GlobalStyles.fontSizeBody2,
                                            color: GlobalStyles.errorMain,
                                            fontWeight:
                                                GlobalStyles.fontWeightBold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: GlobalStyles.spacingMd),
                          if (hasFiles)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: GlobalStyles.spacingSm,
                                vertical: GlobalStyles.spacingXs,
                              ),
                              decoration: BoxDecoration(
                                color: GlobalStyles.successMain,
                                borderRadius: BorderRadius.circular(
                                  GlobalStyles.radiusSm,
                                ),
                              ),
                              child: Text(
                                '${files.length}',
                                style: TextStyle(
                                  fontFamily: GlobalStyles.fontFamilyBody,
                                  fontSize: GlobalStyles.fontSizeCaption,
                                  color: GlobalStyles.surfaceMain,
                                  fontWeight: GlobalStyles.fontWeightBold,
                                ),
                              ),
                            ),
                          SizedBox(width: GlobalStyles.spacingMd),
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: GlobalStyles.durationNormal,
                            child: Icon(
                              LucideIcons.chevronDown,
                              size: GlobalStyles.iconSizeMd,
                              color: GlobalStyles.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Expanded content
                if (isExpanded)
                  Container(
                    padding: EdgeInsets.all(GlobalStyles.spacingMd),
                    decoration: BoxDecoration(
                      color: GlobalStyles.surfaceMain,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(GlobalStyles.radiusMd),
                        bottomRight: Radius.circular(GlobalStyles.radiusMd),
                      ),
                      border: Border(
                        left: BorderSide(
                          color:
                              hasFiles
                                  ? GlobalStyles.successMain.withAlpha(50)
                                  : GlobalStyles.textSecondary.withAlpha(25),
                          width: 1,
                        ),
                        right: BorderSide(
                          color:
                              hasFiles
                                  ? GlobalStyles.successMain.withAlpha(50)
                                  : GlobalStyles.textSecondary.withAlpha(25),
                          width: 1,
                        ),
                        bottom: BorderSide(
                          color:
                              hasFiles
                                  ? GlobalStyles.successMain.withAlpha(50)
                                  : GlobalStyles.textSecondary.withAlpha(25),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat['description'] as String,
                          style: TextStyle(
                            fontFamily: GlobalStyles.fontFamilyBody,
                            fontSize: GlobalStyles.fontSizeCaption,
                            color: GlobalStyles.textTertiary,
                            height:
                                GlobalStyles.lineHeightCaption /
                                GlobalStyles.fontSizeCaption,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: GlobalStyles.spacingMd),

                        // Uploaded files
                        if (hasFiles) ...[
                          _buildUploadedFilesList(key, files),
                          SizedBox(height: GlobalStyles.spacingMd),
                        ],

                        // Upload buttons
                        Row(
                          children: [
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _pickDocument(key),
                                  borderRadius: BorderRadius.circular(
                                    GlobalStyles.radiusMd,
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: GlobalStyles.spacingSm,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        GlobalStyles.radiusMd,
                                      ),
                                      border: Border.all(
                                        color: GlobalStyles.primaryMain,
                                        width: 1,
                                      ),
                                      color: GlobalStyles.primaryMain.withAlpha(
                                        8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          LucideIcons.upload,
                                          size: GlobalStyles.iconSizeSm,
                                          color: GlobalStyles.primaryMain,
                                        ),
                                        SizedBox(width: GlobalStyles.spacingXs),
                                        Text(
                                          'File',
                                          style: TextStyle(
                                            fontFamily:
                                                GlobalStyles.fontFamilyBody,
                                            fontSize:
                                                GlobalStyles.fontSizeCaption,
                                            fontWeight:
                                                GlobalStyles.fontWeightSemiBold,
                                            color: GlobalStyles.primaryMain,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: GlobalStyles.spacingMd),
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _takePhoto(key),
                                  borderRadius: BorderRadius.circular(
                                    GlobalStyles.radiusMd,
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: GlobalStyles.spacingSm,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        GlobalStyles.radiusMd,
                                      ),
                                      color: GlobalStyles.successMain,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          LucideIcons.camera,
                                          size: GlobalStyles.iconSizeSm,
                                          color: GlobalStyles.surfaceMain,
                                        ),
                                        SizedBox(width: GlobalStyles.spacingXs),
                                        Text(
                                          'Photo',
                                          style: TextStyle(
                                            fontFamily:
                                                GlobalStyles.fontFamilyBody,
                                            fontSize:
                                                GlobalStyles.fontSizeCaption,
                                            fontWeight:
                                                GlobalStyles.fontWeightSemiBold,
                                            color: GlobalStyles.surfaceMain,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildDocumentCategory(
    String title,
    String category,
    String description,
  ) {
    final isRequired = requiredDocuments[category] ?? false;
    final uploadedFiles = uploadedDocuments[category] ?? [];
    final hasFiles = uploadedFiles.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
        color: GlobalStyles.surfaceMain,
        border: Border.all(
          color: GlobalStyles.textSecondary.withAlpha(25),
          width: 1,
        ),
        boxShadow: [GlobalStyles.shadowSm],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and file count
          Container(
            padding: EdgeInsets.all(GlobalStyles.spacingMd),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(GlobalStyles.radiusMd),
                topRight: Radius.circular(GlobalStyles.radiusMd),
              ),
              color:
                  isRequired
                      ? GlobalStyles.errorMain.withAlpha(10)
                      : GlobalStyles.primaryMain.withAlpha(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontFamily: GlobalStyles.fontFamilyBody,
                                fontSize: GlobalStyles.fontSizeBody2,
                                fontWeight: GlobalStyles.fontWeightSemiBold,
                                color: GlobalStyles.textPrimary,
                              ),
                            ),
                          ),
                          if (isRequired)
                            Padding(
                              padding: EdgeInsets.only(
                                left: GlobalStyles.spacingSm,
                              ),
                              child: Text(
                                '*',
                                style: TextStyle(
                                  fontFamily: GlobalStyles.fontFamilyBody,
                                  fontSize: GlobalStyles.fontSizeBody2,
                                  color: GlobalStyles.errorMain,
                                  fontWeight: GlobalStyles.fontWeightBold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: GlobalStyles.spacingSm),
                      Text(
                        description,
                        style: TextStyle(
                          fontFamily: GlobalStyles.fontFamilyBody,
                          fontSize: GlobalStyles.fontSizeCaption,
                          color: GlobalStyles.textTertiary,
                          height:
                              GlobalStyles.lineHeightCaption /
                              GlobalStyles.fontSizeCaption,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (hasFiles) ...[
                  SizedBox(width: GlobalStyles.spacingMd),
                  AnimatedScale(
                    scale: hasFiles ? 1.0 : 0.8,
                    duration: GlobalStyles.durationNormal,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: GlobalStyles.spacingSm,
                        vertical: GlobalStyles.spacingXs,
                      ),
                      decoration: BoxDecoration(
                        color: GlobalStyles.successMain,
                        borderRadius: BorderRadius.circular(
                          GlobalStyles.radiusSm,
                        ),
                      ),
                      child: Text(
                        '${uploadedFiles.length}',
                        style: TextStyle(
                          fontFamily: GlobalStyles.fontFamilyBody,
                          fontSize: GlobalStyles.fontSizeCaption,
                          color: GlobalStyles.surfaceMain,
                          fontWeight: GlobalStyles.fontWeightBold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Uploaded files list
          if (hasFiles) ...[
            Container(
              padding: EdgeInsets.all(GlobalStyles.spacingMd),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: GlobalStyles.textSecondary.withAlpha(25),
                    width: 1,
                  ),
                ),
              ),
              child: _buildUploadedFilesList(category, uploadedFiles),
            ),
          ],

          // Upload buttons
          Padding(
            padding: EdgeInsets.all(GlobalStyles.spacingMd),
            child: Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _pickDocument(category),
                      borderRadius: BorderRadius.circular(
                        GlobalStyles.radiusMd,
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: GlobalStyles.spacingMd,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            GlobalStyles.radiusMd,
                          ),
                          border: Border.all(
                            color: GlobalStyles.primaryMain,
                            width: 1.5,
                          ),
                          color: GlobalStyles.primaryMain.withAlpha(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.upload,
                              size: GlobalStyles.iconSizeSm,
                              color: GlobalStyles.primaryMain,
                            ),
                            SizedBox(width: GlobalStyles.spacingXs),
                            Text(
                              'File',
                              style: TextStyle(
                                fontFamily: GlobalStyles.fontFamilyBody,
                                fontSize: GlobalStyles.fontSizeCaption,
                                fontWeight: GlobalStyles.fontWeightSemiBold,
                                color: GlobalStyles.primaryMain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: GlobalStyles.spacingMd),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _takePhoto(category),
                      borderRadius: BorderRadius.circular(
                        GlobalStyles.radiusMd,
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: GlobalStyles.spacingMd,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            GlobalStyles.radiusMd,
                          ),
                          color: GlobalStyles.successMain,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.camera,
                              size: GlobalStyles.iconSizeSm,
                              color: GlobalStyles.surfaceMain,
                            ),
                            SizedBox(width: GlobalStyles.spacingXs),
                            Text(
                              'Photo',
                              style: TextStyle(
                                fontFamily: GlobalStyles.fontFamilyBody,
                                fontSize: GlobalStyles.fontSizeCaption,
                                fontWeight: GlobalStyles.fontWeightSemiBold,
                                color: GlobalStyles.surfaceMain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadedFilesList(String category, List<File> files) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Uploaded Files:',
          style: TextStyle(
            fontFamily: GlobalStyles.fontFamilyBody,
            fontSize: GlobalStyles.fontSizeCaption,
            fontWeight: GlobalStyles.fontWeightSemiBold,
            color: GlobalStyles.primaryMain,
          ),
        ),
        SizedBox(height: GlobalStyles.spacingSm),
        ...files.map((file) => _buildFileItem(category, file)),
      ],
    );
  }

  Widget _buildFileItem(String category, File file) {
    final fileName = file.path.split('/').last;
    final isImage =
        fileName.toLowerCase().endsWith('.jpg') ||
        fileName.toLowerCase().endsWith('.jpeg') ||
        fileName.toLowerCase().endsWith('.png');
    final isPdf = fileName.toLowerCase().endsWith('.pdf');

    // Check if this is an assessment image
    final isAssessmentImage =
        category == 'damage_photos' && widget.imagePaths.contains(file.path);

    // Check if this is the auto-generated job estimate PDF
    final isAutoGeneratedJobEstimate =
        category == 'job_estimate' &&
        widget.tempJobEstimatePdfPath != null &&
        file.path == widget.tempJobEstimatePdfPath;

    return AnimatedSlide(
      offset: Offset.zero,
      duration: GlobalStyles.durationNormal,
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: EdgeInsets.only(bottom: GlobalStyles.spacingSm),
          padding: EdgeInsets.symmetric(
            horizontal: GlobalStyles.spacingMd,
            vertical: GlobalStyles.spacingSm,
          ),
          decoration: BoxDecoration(
            color: GlobalStyles.surfaceMain,
            borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
            border: Border.all(
              color:
                  isAssessmentImage
                      ? GlobalStyles.successMain.withAlpha(50)
                      : GlobalStyles.textSecondary.withAlpha(25),
              width: 1,
            ),
            boxShadow: [GlobalStyles.shadowSm],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // File icon and name
              Expanded(
                child: Row(
                  children: [
                    // File icon
                    Container(
                      padding: EdgeInsets.all(GlobalStyles.spacingXs),
                      decoration: BoxDecoration(
                        color:
                            isImage
                                ? GlobalStyles.infoMain.withAlpha(15)
                                : GlobalStyles.primaryMain.withAlpha(15),
                        borderRadius: BorderRadius.circular(
                          GlobalStyles.radiusSm,
                        ),
                      ),
                      child: Icon(
                        isImage ? LucideIcons.image : LucideIcons.fileText,
                        color:
                            isImage
                                ? GlobalStyles.infoMain
                                : GlobalStyles.primaryMain,
                        size: GlobalStyles.iconSizeSm,
                      ),
                    ),
                    SizedBox(width: GlobalStyles.spacingMd),
                    // File name and metadata
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            style: TextStyle(
                              fontFamily: GlobalStyles.fontFamilyBody,
                              fontSize: GlobalStyles.fontSizeCaption,
                              color: GlobalStyles.textPrimary,
                              fontWeight: GlobalStyles.fontWeightSemiBold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          if (isAssessmentImage) ...[
                            SizedBox(height: GlobalStyles.spacingXs),
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.check,
                                  size: GlobalStyles.iconSizeXs,
                                  color: GlobalStyles.successMain,
                                ),
                                SizedBox(width: GlobalStyles.spacingXs),
                                Text(
                                  'Assessment Image',
                                  style: TextStyle(
                                    fontFamily: GlobalStyles.fontFamilyBody,
                                    fontSize: GlobalStyles.fontSizeCaption,
                                    color: GlobalStyles.successMain,
                                    fontWeight: GlobalStyles.fontWeightMedium,
                                  ),
                                ),
                              ],
                            ),
                          ] else if (isAutoGeneratedJobEstimate) ...[
                            SizedBox(height: GlobalStyles.spacingXs),
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.sparkles,
                                  size: GlobalStyles.iconSizeXs,
                                  color: GlobalStyles.warningMain,
                                ),
                                SizedBox(width: GlobalStyles.spacingXs),
                                Text(
                                  'Auto-generated',
                                  style: TextStyle(
                                    fontFamily: GlobalStyles.fontFamilyBody,
                                    fontSize: GlobalStyles.fontSizeCaption,
                                    color: GlobalStyles.warningMain,
                                    fontWeight: GlobalStyles.fontWeightMedium,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: GlobalStyles.spacingMd),
              // Action buttons
              if (isAssessmentImage)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: GlobalStyles.spacingSm,
                    vertical: GlobalStyles.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: GlobalStyles.successMain.withAlpha(15),
                    borderRadius: BorderRadius.circular(GlobalStyles.radiusSm),
                    border: Border.all(
                      color: GlobalStyles.successMain.withAlpha(50),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'PROOF',
                    style: TextStyle(
                      fontFamily: GlobalStyles.fontFamilyBody,
                      color: GlobalStyles.successMain,
                      fontSize: GlobalStyles.fontSizeCaption,
                      fontWeight: GlobalStyles.fontWeightBold,
                    ),
                  ),
                )
              else if (isAutoGeneratedJobEstimate && isPdf)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // View button with ripple effect
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _viewPdf(file.path),
                        borderRadius: BorderRadius.circular(
                          GlobalStyles.radiusSm,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(GlobalStyles.spacingXs),
                          child: Icon(
                            LucideIcons.eye,
                            color: GlobalStyles.infoMain,
                            size: GlobalStyles.iconSizeSm,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: GlobalStyles.spacingSm),
                    // Download button with ripple effect
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _downloadPdf(file.path),
                        borderRadius: BorderRadius.circular(
                          GlobalStyles.radiusSm,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(GlobalStyles.spacingXs),
                          child: Icon(
                            LucideIcons.download,
                            color: GlobalStyles.successMain,
                            size: GlobalStyles.iconSizeSm,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                // Remove button with ripple effect
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _removeFile(category, file),
                    borderRadius: BorderRadius.circular(GlobalStyles.radiusSm),
                    child: Padding(
                      padding: EdgeInsets.all(GlobalStyles.spacingXs),
                      child: Icon(
                        LucideIcons.trash2,
                        color: GlobalStyles.errorMain,
                        size: GlobalStyles.iconSizeSm,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.all(GlobalStyles.spacingMd),
      decoration: BoxDecoration(
        color: GlobalStyles.surfaceMain,
        border: Border(
          top: BorderSide(
            color: GlobalStyles.textSecondary.withAlpha(25),
            width: 1,
          ),
        ),
        boxShadow: [GlobalStyles.shadowMd],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Primary Submit Button
            SizedBox(
              width: double.infinity,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _onSubmitPressed,
                  borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
                  child: AnimatedContainer(
                    duration: GlobalStyles.durationNormal,
                    curve: GlobalStyles.easingDefault,
                    padding: EdgeInsets.symmetric(
                      vertical: GlobalStyles.spacingMd,
                    ),
                    decoration: BoxDecoration(
                      color: GlobalStyles.primaryMain,
                      borderRadius: BorderRadius.circular(
                        GlobalStyles.radiusMd,
                      ),
                      boxShadow: [GlobalStyles.shadowMd],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.send,
                          color: GlobalStyles.surfaceMain,
                          size: GlobalStyles.iconSizeSm,
                        ),
                        SizedBox(width: GlobalStyles.spacingMd),
                        Text(
                          'Submit Insurance Claim',
                          style: TextStyle(
                            fontFamily: GlobalStyles.fontFamilyBody,
                            fontSize: GlobalStyles.fontSizeBody2,
                            fontWeight: GlobalStyles.fontWeightSemiBold,
                            color: GlobalStyles.surfaceMain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadProgressModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: GlobalStyles.textPrimary.withAlpha(178),
      builder:
          (context) => PopScope(
            canPop: false,
            child: Dialog(
              backgroundColor: GlobalStyles.surfaceMain,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
              ),
              child: Padding(
                padding: EdgeInsets.all(GlobalStyles.spacingMd),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress indicator
                    SizedBox(
                      width: GlobalStyles.spacingMd,
                      height: GlobalStyles.spacingMd,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        color: GlobalStyles.primaryMain,
                      ),
                    ),
                    SizedBox(height: GlobalStyles.spacingMd),

                    // Title
                    Text(
                      'Uploading Documents',
                      style: TextStyle(
                        fontFamily: GlobalStyles.fontFamilyBody,
                        fontSize: GlobalStyles.fontSizeBody2,
                        fontWeight: GlobalStyles.fontWeightBold,
                        color: GlobalStyles.textPrimary,
                      ),
                    ),
                    SizedBox(height: GlobalStyles.spacingMd),

                    // Description
                    Text(
                      'Please wait while we upload your documents and process your insurance claim.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: GlobalStyles.fontFamilyBody,
                        fontSize: GlobalStyles.fontSizeBody2,
                        color: GlobalStyles.textTertiary,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: GlobalStyles.spacingMd),

                    // Info message
                    Container(
                      padding: EdgeInsets.all(GlobalStyles.spacingMd),
                      decoration: BoxDecoration(
                        color: GlobalStyles.primaryMain.withAlpha(15),
                        borderRadius: BorderRadius.circular(
                          GlobalStyles.radiusMd,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.info,
                            color: GlobalStyles.primaryMain,
                            size: GlobalStyles.fontSizeBody2,
                          ),
                          SizedBox(width: GlobalStyles.spacingMd),
                          Expanded(
                            child: Text(
                              'This may take a few moments',
                              style: TextStyle(
                                fontFamily: GlobalStyles.fontFamilyBody,
                                fontSize: GlobalStyles.fontSizeBody2,
                                color: GlobalStyles.primaryMain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  void _onSubmitPressed() {
    final requiredDocsUploaded = _checkRequiredDocuments();
    final incidentInfoFilled = _checkIncidentInformation();
    final isFormValid = requiredDocsUploaded && incidentInfoFilled;

    if (isFormValid) {
      _submitClaim();
      return;
    }

    List<String> messages = [];
    if (!requiredDocsUploaded) {
      final missing = DocumentUploadUIUtils.getMissingRequiredDocumentsList(
        requiredDocuments,
        uploadedDocuments,
      );
      if (missing.isNotEmpty) {
        messages.add('Missing required documents: ${missing.join(', ')}');
      } else {
        messages.add('Some required documents are missing');
      }
    }

    if (!incidentInfoFilled) {
      messages.add('Please provide incident date and location');
    }

    final snackText = messages.join('\n');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(snackText),
          backgroundColor: GlobalStyles.errorMain,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _pickDocument(String category) async {
    try {
      // Ensure we have storage permission before launching file picker.
      final hasPerm =
          await DocumentUploadHandlerUtils.ensureStoragePermission();
      if (!hasPerm) {
        _showErrorMessage('Storage permission is required to upload documents');
        return;
      }

      final files = await DocumentUploadHandlerUtils.pickDocuments();

      if (files != null && files.isNotEmpty) {
        setState(() {
          uploadedDocuments[category]!.addAll(files);
        });
        _showSuccessMessage('Documents uploaded successfully');
      }
    } catch (e) {
      _showErrorMessage('Error picking document: $e');
    }
  }

  Future<void> _takePhoto(String category) async {
    try {
      final hasPermission =
          await DocumentUploadHandlerUtils.ensureCameraPermission();
      if (!hasPermission) {
        _showErrorMessage('Camera permission is required to take photos');
        return;
      }

      final file = await DocumentUploadHandlerUtils.takePhoto(_picker);

      if (file != null) {
        setState(() {
          uploadedDocuments[category]!.add(file);
        });
        _showSuccessMessage('Photo captured successfully');
      }
    } catch (e) {
      _showErrorMessage('Error taking photo: $e');
    }
  }

  void _removeFile(String category, File file) {
    final canRemove = DocumentUploadValidationUtils.canRemoveFile(
      category: category,
      file: file,
      originalImagePaths: widget.imagePaths,
      tempJobEstimatePdfPath: widget.tempJobEstimatePdfPath,
    );

    if (!canRemove) {
      final errorMessage = DocumentUploadValidationUtils.getRemovalErrorMessage(
        category: category,
        file: file,
        originalImagePaths: widget.imagePaths,
        tempJobEstimatePdfPath: widget.tempJobEstimatePdfPath,
      );
      _showErrorMessage(errorMessage);
      return;
    }

    setState(() {
      uploadedDocuments[category]!.remove(file);
    });
    _showSuccessMessage('File removed');
  }

  Future<void> _viewPdf(String pdfPath) async {
    try {
      final exists = await DocumentUploadUIUtils.validatePdfExists(pdfPath);
      if (!exists) {
        _showErrorMessage('PDF file not found');
        return;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _PDFViewerScreen(pdfPath: pdfPath),
          ),
        );
      }
    } catch (e) {
      _showErrorMessage('Error viewing PDF: $e');
    }
  }

  Future<void> _downloadPdf(String sourcePath) async {
    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: GlobalStyles.spacingMd,
                height: GlobalStyles.spacingMd,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: GlobalStyles.surfaceMain,
                ),
              ),
              SizedBox(width: GlobalStyles.spacingMd),
              const Text('Downloading PDF...'),
            ],
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: GlobalStyles.primaryMain,
        ),
      );
    }

    final result = await DocumentUploadUIUtils.downloadPdf(sourcePath);

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      if (result.success) {
        _showSuccessMessage(result.message);
      } else if (!result.cancelled) {
        _showErrorMessage(result.message);
      }
    }
  }

  bool _checkRequiredDocuments() {
    return DocumentUploadValidationUtils.checkRequiredDocuments(
      requiredDocuments,
      uploadedDocuments,
    );
  }

  bool _checkIncidentInformation() {
    return DocumentUploadValidationUtils.checkIncidentInformation(
      _incidentLocationController,
      _incidentDateController,
    );
  }

  Future<void> _submitClaim() async {
    // Show upload progress modal
    _showUploadProgressModal();

    try {
      // Build incident description using utility
      final incidentDescription =
          DocumentUploadSubmissionUtils.buildIncidentDescription(
            apiResponses: widget.apiResponses,
            manualDamages: _manualDamages,
            selectedRepairOptions: _selectedRepairOptions,
          );

      // Build damages payload using utility
      final damagesPayload = DocumentUploadSubmissionUtils.buildDamagesPayload(
        apiResponses: widget.apiResponses,
        manualDamages: _manualDamages,
        selectedRepairOptions: _selectedRepairOptions,
        repairPricingData: _repairPricingData,
        replacePricingData: _replacePricingData,
      );

      debugPrint('=== DAMAGES PAYLOAD ===');
      debugPrint(damagesPayload.toString());
      debugPrint('=======================');

      debugPrint('=== VEHICLE DATA DEBUG ===');
      debugPrint('Vehicle Make: "${widget.vehicleData?['make'] ?? ''}"');
      debugPrint('Vehicle Model: "${widget.vehicleData?['model'] ?? ''}"');
      debugPrint('Vehicle Year: "${widget.vehicleData?['year'] ?? ''}"');
      debugPrint(
        'Plate Number: "${widget.vehicleData?['plate_number'] ?? ''}"',
      );
      debugPrint('========================');

      // Submit claim with documents using utility
      final result =
          await DocumentUploadSubmissionUtils.submitClaimWithDocuments(
            incidentLocation: _incidentLocationController.text,
            incidentDate: _incidentDateController.text,
            incidentDescription: incidentDescription,
            vehicleData: widget.vehicleData,
            estimatedDamageCost:
                _estimatedDamageCost > 0
                    ? _estimatedDamageCost
                    : DocumentUploadPricingUtils.calculateEstimatedCostFromApi(
                      widget.apiResponses,
                    ),
            damagesPayload: damagesPayload,
            uploadedDocuments: uploadedDocuments,
          );

      final claim = result['claim'];
      final uploadSuccess = result['uploadSuccess'] as bool;
      final totalUploaded = result['totalUploaded'] as int;
      final totalFiles = result['totalFiles'] as int;

      debugPrint('Total files uploaded: $totalUploaded out of $totalFiles');

      // Close upload modal
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Handle upload results
      if (!uploadSuccess && totalUploaded == 0) {
        _showErrorMessage(
          'Failed to upload documents. Claim has been cancelled. Please try again.',
        );
        return;
      } else if (!uploadSuccess && totalUploaded > 0) {
        if (mounted) {
          _showSuccessDialog(
            claimNumber: claim.claimNumber,
            documentUploadWarning: true,
            partialUpload: true,
          );
        }
        return;
      }

      // Success - clean up temporary PDF
      await DocumentUploadHandlerUtils.cleanupTempPdf(
        widget.tempJobEstimatePdfPath,
      );

      // Show success dialog
      if (mounted) {
        _showSuccessDialog(claimNumber: claim.claimNumber);
      }
    } catch (e) {
      debugPrint('Error submitting claim: $e');
      _showErrorMessage('Error submitting claim: ${e.toString()}');

      // Close upload modal on error
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  void _showSuccessDialog({
    String? claimNumber,
    bool documentUploadWarning = false,
    bool partialUpload = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: GlobalStyles.surfaceMain,
            title: Row(
              children: [
                Icon(
                  LucideIcons.circleCheck,
                  color: GlobalStyles.successMain,
                  size: GlobalStyles.fontSizeBody2,
                ),
                SizedBox(width: GlobalStyles.spacingMd),
                Text(
                  'Claim Submitted',
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyBody,
                    color: GlobalStyles.textPrimary,
                    fontSize: GlobalStyles.fontSizeBody2,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  documentUploadWarning
                      ? 'Your insurance claim has been submitted successfully.'
                      : 'Your insurance claim has been submitted successfully.',
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyBody,
                    color: GlobalStyles.textTertiary,
                    fontSize: GlobalStyles.fontSizeBody2,
                  ),
                ),
                if (documentUploadWarning) ...[
                  SizedBox(height: GlobalStyles.spacingMd),
                  Container(
                    padding: EdgeInsets.all(GlobalStyles.spacingMd),
                    decoration: BoxDecoration(
                      color: GlobalStyles.warningMain.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        GlobalStyles.radiusMd,
                      ),
                      border: Border.all(
                        color: GlobalStyles.warningMain.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          LucideIcons.triangleAlert,
                          color: GlobalStyles.warningMain,
                          size: GlobalStyles.fontSizeBody2,
                        ),
                        SizedBox(width: GlobalStyles.spacingMd),
                        Expanded(
                          child: Text(
                            partialUpload
                                ? 'Some documents could not be uploaded. Please upload the missing documents from your claims page.'
                                : 'Documents could not be uploaded. Please upload them from your claims page.',
                            style: TextStyle(
                              fontFamily: GlobalStyles.fontFamilyBody,
                              color: GlobalStyles.warningMain,
                              fontSize: GlobalStyles.fontSizeBody2,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (claimNumber != null) ...[
                  SizedBox(height: GlobalStyles.spacingMd),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: GlobalStyles.spacingMd,
                      vertical: GlobalStyles.spacingMd,
                    ),
                    decoration: BoxDecoration(
                      color: GlobalStyles.successMain,
                      borderRadius: BorderRadius.all(
                        Radius.circular(GlobalStyles.radiusMd),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.hash,
                          color: GlobalStyles.surfaceMain,
                          size: GlobalStyles.fontSizeBody2,
                        ),
                        SizedBox(width: GlobalStyles.spacingMd),
                        Text(
                          'Claim #: $claimNumber',
                          style: TextStyle(
                            fontFamily: GlobalStyles.fontFamilyBody,
                            color: GlobalStyles.surfaceMain,
                            fontSize: GlobalStyles.fontSizeBody2,
                            fontWeight: GlobalStyles.fontWeightSemiBold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: GlobalStyles.spacingMd),
                Text(
                  'Please be patient when waiting for approval.',
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyBody,
                    color: GlobalStyles.textTertiary,
                    fontSize: GlobalStyles.fontSizeBody2,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  // Navigate back to home by popping all screens
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text(
                  'OK',
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyBody,
                    color: GlobalStyles.primaryMain,
                  ),
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
          backgroundColor: GlobalStyles.successMain,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: GlobalStyles.errorMain,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

// PDF Viewer Screen Widget
class _PDFViewerScreen extends StatelessWidget {
  final String pdfPath;

  const _PDFViewerScreen({required this.pdfPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalStyles.surfaceMain,
      appBar: AppBar(
        backgroundColor: GlobalStyles.surfaceMain,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.arrowLeft,
            color: GlobalStyles.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Job Estimate Preview',
          style: TextStyle(
            fontFamily: GlobalStyles.fontFamilyBody,
            fontSize: GlobalStyles.fontSizeBody2,
            fontWeight: GlobalStyles.fontWeightBold,
            color: GlobalStyles.textPrimary,
          ),
        ),
      ),
      body: PDFView(
        filePath: pdfPath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        pageSnap: true,
        defaultPage: 0,
        fitPolicy: FitPolicy.WIDTH,
        preventLinkNavigation: false,
        onError: (error) {
          debugPrint('Error loading PDF: $error');
        },
        onPageError: (page, error) {
          debugPrint('Error on page $page: $error');
        },
      ),
    );
  }
}
