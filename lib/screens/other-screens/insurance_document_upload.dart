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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: GlobalStyles.spacingMd),
                      if (widget.vehicleData != null)
                        _buildVehicleInfoSection(),
                      if (widget.vehicleData != null)
                        SizedBox(height: GlobalStyles.spacingLg),
                      _buildInstructions(),
                      SizedBox(height: GlobalStyles.spacingLg),
                      _buildIncidentInformationSection(),
                      SizedBox(height: GlobalStyles.spacingMd),
                      _buildDamageAssessmentImagesSection(),
                      SizedBox(height: GlobalStyles.spacingLg),
                      _buildRepairOptionsSection(),
                      SizedBox(height: GlobalStyles.spacingLg),
                      _buildEstimatedCostSection(),
                      SizedBox(height: GlobalStyles.spacingLg),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: GlobalStyles.paddingNormal,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Document Upload',
                              style: TextStyle(
                                fontFamily: GlobalStyles.fontFamilyHeading,
                                fontSize: GlobalStyles.fontSizeH4,
                                fontWeight: GlobalStyles.fontWeightSemiBold,
                                color: GlobalStyles.textPrimary,
                                letterSpacing: GlobalStyles.letterSpacingH4,
                              ),
                            ),
                            SizedBox(height: GlobalStyles.spacingSm),
                            Text(
                              'Please upload all required documents listed below.',
                              style: TextStyle(
                                fontFamily: GlobalStyles.fontFamilyBody,
                                fontSize: GlobalStyles.fontSizeBody2,
                                color: GlobalStyles.textTertiary,
                                height:
                                    GlobalStyles.lineHeightBody2 /
                                    GlobalStyles.fontSizeBody2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: GlobalStyles.spacingMd),
                      _buildDocumentCategories(),
                      SizedBox(height: GlobalStyles.spacingXl),
                    ],
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
      margin: EdgeInsets.symmetric(horizontal: GlobalStyles.paddingNormal),
      padding: GlobalStyles.cardPadding,
      decoration: BoxDecoration(
        color: GlobalStyles.surfaceMain,
        borderRadius: BorderRadius.circular(GlobalStyles.cardBorderRadius),
        boxShadow: [GlobalStyles.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.car,
                color: GlobalStyles.primaryMain,
                size: GlobalStyles.iconSizeMd,
              ),
              SizedBox(width: GlobalStyles.spacingSm),
              Text(
                'Vehicle Information',
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyHeading,
                  fontSize: GlobalStyles.fontSizeH6,
                  fontWeight: GlobalStyles.fontWeightSemiBold,
                  color: GlobalStyles.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: GlobalStyles.spacingMd),
          _buildVehicleInfoRow('Make', make),
          Divider(
            height: GlobalStyles.spacingLg,
            color: GlobalStyles.inputBorderColor,
          ),
          _buildVehicleInfoRow('Model', model),
          Divider(
            height: GlobalStyles.spacingLg,
            color: GlobalStyles.inputBorderColor,
          ),
          _buildVehicleInfoRow('Year', year),
          Divider(
            height: GlobalStyles.spacingLg,
            color: GlobalStyles.inputBorderColor,
          ),
          _buildVehicleInfoRow('Plate Number', plateNumber),
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
      margin: EdgeInsets.symmetric(horizontal: GlobalStyles.paddingNormal),
      padding: GlobalStyles.cardPadding,
      decoration: BoxDecoration(
        color: GlobalStyles.infoMain.withOpacity(0.1),
        borderRadius: BorderRadius.circular(GlobalStyles.cardBorderRadius),
        border: Border.all(
          color: GlobalStyles.infoMain.withOpacity(0.3),
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
                color: GlobalStyles.infoMain,
                size: GlobalStyles.iconSizeMd,
              ),
              SizedBox(width: GlobalStyles.spacingSm),
              Text(
                'Required Documents',
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyHeading,
                  fontSize: GlobalStyles.fontSizeH6,
                  fontWeight: GlobalStyles.fontWeightSemiBold,
                  color: GlobalStyles.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: GlobalStyles.spacingMd),
          Text(
            'Please upload the following documents to process your insurance claim. '
            'All documents marked with * are required. Ensure documents are clear, readable, '
            'and in PDF format when possible (photocopies should be scanned as PDF).',
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyBody,
              fontSize: GlobalStyles.fontSizeBody2,
              color: GlobalStyles.textSecondary,
              height: GlobalStyles.lineHeightBody2 / GlobalStyles.fontSizeBody2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentInformationSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: GlobalStyles.paddingNormal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.mapPin,
                color: GlobalStyles.primaryMain,
                size: GlobalStyles.iconSizeMd,
              ),
              SizedBox(width: GlobalStyles.spacingSm),
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
          SizedBox(height: GlobalStyles.spacingSm),
          Text(
            'Please provide details about when and where the incident occurred.',
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyBody,
              fontSize: GlobalStyles.fontSizeBody2,
              color: GlobalStyles.textTertiary,
              height: GlobalStyles.lineHeightBody2 / GlobalStyles.fontSizeBody2,
            ),
          ),
          SizedBox(height: GlobalStyles.spacingLg),

          // Incident Location
          _buildIncidentInputField(
            controller: _incidentLocationController,
            label: 'Incident Location',
            hint: 'e.g., EDSA Quezon City, Makati Avenue',
            icon: LucideIcons.mapPin,
          ),
          SizedBox(height: GlobalStyles.spacingMd),

          // Incident Date
          _buildIncidentDateField(),
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
      padding: EdgeInsets.all(GlobalStyles.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Estimated Cost',
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyBody,
                  fontSize: GlobalStyles.fontSizeBody2,
                  fontWeight: GlobalStyles.fontWeightBold,
                  color: GlobalStyles.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: GlobalStyles.spacingMd),
          Text(
            'This is the estimated cost based on your repair options.',
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyBody,
              fontSize: GlobalStyles.fontSizeBody2,
              color: GlobalStyles.textTertiary,
            ),
          ),
          SizedBox(height: GlobalStyles.spacingMd),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(GlobalStyles.spacingMd),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
              color: GlobalStyles.primaryMain.withAlpha(38),
            ),
            child: Column(
              children: [
                Text(
                  'Total Estimated Cost',
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyBody,
                    fontSize: GlobalStyles.fontSizeBody2,
                    color: GlobalStyles.textTertiary,
                    fontWeight: GlobalStyles.fontWeightMedium,
                  ),
                ),
                SizedBox(height: GlobalStyles.spacingMd),
                if (_isDamageSevere) ...[
                  Text(
                    'Severe damage. Final cost will be provided by the mechanic.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: GlobalStyles.fontFamilyBody,
                      fontSize: GlobalStyles.fontSizeBody2,
                      color: GlobalStyles.errorMain,
                      fontWeight: GlobalStyles.fontWeightSemiBold,
                    ),
                  ),
                ] else ...[
                  if (_isLoadingPricing.values.any((loading) => loading)) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: GlobalStyles.spacingMd,
                          height: GlobalStyles.spacingMd,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: GlobalStyles.primaryMain,
                          ),
                        ),
                        SizedBox(width: GlobalStyles.spacingMd),
                        Text(
                          'Calculating pricing...',
                          style: TextStyle(
                            fontFamily: GlobalStyles.fontFamilyBody,
                            fontSize: GlobalStyles.fontSizeBody2,
                            color: GlobalStyles.primaryMain,
                            fontWeight: GlobalStyles.fontWeightMedium,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      _estimatedDamageCost == 0.0
                          ? 'N/A'
                          : _currencyFormat.format(_estimatedDamageCost),
                      style: TextStyle(
                        fontFamily: GlobalStyles.fontFamilyBody,
                        fontSize: GlobalStyles.fontSizeBody2,
                        color: GlobalStyles.primaryMain,
                        fontWeight: GlobalStyles.fontWeightBold,
                      ),
                    ),
                  ],
                  if (_estimatedDamageCost == 0 &&
                      !_isLoadingPricing.values.any((loading) => loading)) ...[
                    SizedBox(height: GlobalStyles.spacingMd),
                    Text(
                      _selectedRepairOptions.isEmpty
                          ? 'Select repair/replace options to calculate cost'
                          : 'Cost will be calculated based on repair options',
                      style: TextStyle(
                        fontFamily: GlobalStyles.fontFamilyBody,
                        fontSize: GlobalStyles.fontSizeBody2,
                        color: GlobalStyles.textTertiary,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDamageAssessmentImagesSection() {
    if (widget.imagePaths.isEmpty) {
      return Container(); // Don't show section if no images
    }

    return Container(
      padding: EdgeInsets.all(GlobalStyles.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Damage Assessment\nImages',
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyBody,
                  fontSize: GlobalStyles.fontSizeBody2,
                  fontWeight: GlobalStyles.fontWeightBold,
                  color: GlobalStyles.textPrimary,
                ),
              ),
              SizedBox(width: GlobalStyles.spacingMd),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: GlobalStyles.spacingMd,
                  vertical: GlobalStyles.spacingMd,
                ),
                decoration: BoxDecoration(
                  color: GlobalStyles.primaryMain.withAlpha(51),
                  borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
                ),
                child: Text(
                  '${widget.imagePaths.length}',
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyBody,
                    fontSize: GlobalStyles.fontSizeBody2,
                    color: GlobalStyles.primaryMain,
                    fontWeight: GlobalStyles.fontWeightBold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: GlobalStyles.spacingMd),
          Text(
            'These are the images you took for damage assessment. They have been automatically included as damage proof for your claim.',
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyBody,
              fontSize: GlobalStyles.fontSizeBody2,
              color: GlobalStyles.textTertiary,
              height: 1.5,
            ),
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
        childAspectRatio: 1.2,
      ),
      itemCount: widget.imagePaths.length,
      itemBuilder: (context, index) {
        final imagePath = widget.imagePaths[index];
        return _buildAssessmentImageItem(imagePath, index);
      },
    );
  }

  Widget _buildAssessmentImageItem(String imagePath, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
        border: Border.all(
          color: GlobalStyles.successMain.withAlpha(76),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
        child: Stack(
          children: [
            // Image
            Image.file(
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
                          size: GlobalStyles.fontSizeBody2,
                        ),
                        SizedBox(height: GlobalStyles.spacingMd),
                        Text(
                          'Image Error',
                          style: TextStyle(
                            fontFamily: GlobalStyles.fontFamilyBody,
                            color: GlobalStyles.textTertiary,
                            fontSize: GlobalStyles.fontSizeBody2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Overlay with assessment indicator
            Positioned(
              top: GlobalStyles.spacingMd,
              right: GlobalStyles.spacingMd,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: GlobalStyles.spacingMd,
                  vertical: GlobalStyles.spacingMd,
                ),
                decoration: BoxDecoration(
                  color: GlobalStyles.successMain,
                  borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
                ),
                child: Text(
                  'ASSESSED',
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyBody,
                    color: GlobalStyles.surfaceMain,
                    fontSize: GlobalStyles.fontSizeBody2,
                    fontWeight: GlobalStyles.fontWeightBold,
                  ),
                ),
              ),
            ),

            // Image number
            Positioned(
              bottom: GlobalStyles.spacingMd,
              left: GlobalStyles.spacingMd,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: GlobalStyles.spacingMd,
                  vertical: GlobalStyles.spacingMd,
                ),
                decoration: BoxDecoration(
                  color: GlobalStyles.primaryMain.withAlpha(178),
                  borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyBody,
                    color: GlobalStyles.surfaceMain,
                    fontSize: GlobalStyles.fontSizeBody2,
                    fontWeight: GlobalStyles.fontWeightBold,
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
      padding: EdgeInsets.all(GlobalStyles.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Damage Assessment Summary',
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyBody,
              fontSize: GlobalStyles.fontSizeBody2,
              fontWeight: GlobalStyles.fontWeightBold,
              color: GlobalStyles.textPrimary,
            ),
          ),
          SizedBox(height: GlobalStyles.spacingMd),
          Text(
            'Review your selected repair options and pricing below.',
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyBody,
              fontSize: GlobalStyles.fontSizeBody2,
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

    return Container(
      padding: EdgeInsets.all(GlobalStyles.spacingMd),
      decoration: BoxDecoration(
        color: GlobalStyles.primaryMain.withAlpha(15),
        borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
        border: Border.all(color: GlobalStyles.primaryMain.withAlpha(76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: GlobalStyles.spacingMd,
                  vertical: GlobalStyles.spacingMd,
                ),
                decoration: BoxDecoration(
                  color: GlobalStyles.successMain.withAlpha(51),
                  borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
                ),
                child: Text(
                  selectedOption.toUpperCase(),
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyBody,
                    color: GlobalStyles.successMain,
                    fontSize: GlobalStyles.fontSizeBody2,
                    fontWeight: GlobalStyles.fontWeightBold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: GlobalStyles.spacingMd),
          Text(
            damagedPart,
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyBody,
              fontSize: GlobalStyles.fontSizeBody2,
              fontWeight: GlobalStyles.fontWeightBold,
              color: GlobalStyles.textPrimary,
            ),
          ),
          SizedBox(height: GlobalStyles.spacingMd),
          Text(
            damageType,
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyBody,
              fontSize: GlobalStyles.fontSizeBody2,
              color: GlobalStyles.textTertiary,
            ),
          ),
          SizedBox(height: GlobalStyles.spacingMd),
          Divider(color: GlobalStyles.textSecondary.withAlpha(76)),
          SizedBox(height: GlobalStyles.spacingMd),
          _buildPricingSummary(selectedOption, repairPricing, replacePricing),
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

    return Container(
      padding: EdgeInsets.all(GlobalStyles.spacingMd),
      decoration: BoxDecoration(
        color: GlobalStyles.primaryMain.withAlpha(15),
        borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
        border: Border.all(color: GlobalStyles.primaryMain.withAlpha(76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: GlobalStyles.spacingMd,
                  vertical: GlobalStyles.spacingMd,
                ),
                decoration: BoxDecoration(
                  color: GlobalStyles.successMain.withAlpha(51),
                  borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
                ),
                child: Text(
                  selectedOption.toUpperCase(),
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyBody,
                    color: GlobalStyles.successMain,
                    fontSize: GlobalStyles.fontSizeBody2,
                    fontWeight: GlobalStyles.fontWeightBold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: GlobalStyles.spacingMd),
          Text(
            damagedPart,
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyBody,
              fontSize: GlobalStyles.fontSizeBody2,
              fontWeight: GlobalStyles.fontWeightBold,
              color: GlobalStyles.textPrimary,
            ),
          ),
          SizedBox(height: GlobalStyles.spacingMd),
          Text(
            damageType,
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyBody,
              fontSize: GlobalStyles.fontSizeBody2,
              color: GlobalStyles.textTertiary,
            ),
          ),
          SizedBox(height: GlobalStyles.spacingMd),
          Divider(color: GlobalStyles.textSecondary.withAlpha(76)),
          SizedBox(height: GlobalStyles.spacingMd),
          _buildPricingSummary(selectedOption, repairPricing, replacePricing),
        ],
      ),
    );
  }

  Widget _buildPricingSummary(
    String option,
    Map<String, dynamic>? repairPricing,
    Map<String, dynamic>? replacePricing,
  ) {
    double laborFee = 0.0;
    double finalPrice = 0.0;
    double bodyPaintPrice = 0.0;
    double thinsmithPrice = 0.0;

    if (option == 'replace') {
      thinsmithPrice =
          (replacePricing?['insurance'] as num?)?.toDouble() ?? 0.0;
      laborFee =
          (replacePricing?['cost_installation_personal'] as num?)?.toDouble() ??
          (repairPricing?['cost_installation_personal'] as num?)?.toDouble() ??
          0.0;
      if (repairPricing != null) {
        bodyPaintPrice =
            (repairPricing['srp_insurance'] as num?)?.toDouble() ?? 0.0;
      }
      finalPrice = thinsmithPrice + bodyPaintPrice;
    } else {
      laborFee =
          (repairPricing?['cost_installation_personal'] as num?)?.toDouble() ??
          0.0;
      bodyPaintPrice =
          (repairPricing?['srp_insurance'] as num?)?.toDouble() ?? 0.0;
      finalPrice = bodyPaintPrice;
    }

    return Column(
      children: [
        _buildCostItem('Labor Fee', laborFee),
        if (option == 'repair') ...[
          SizedBox(height: GlobalStyles.spacingMd),
          _buildCostItem('Paint Price', bodyPaintPrice),
        ] else if (option == 'replace') ...[
          SizedBox(height: GlobalStyles.spacingMd),
          _buildCostItem('Part Price', thinsmithPrice),
          _buildCostItem('Paint Price', bodyPaintPrice),
        ],
        SizedBox(height: GlobalStyles.spacingMd),
        Divider(color: GlobalStyles.textSecondary.withAlpha(76)),
        SizedBox(height: GlobalStyles.spacingMd),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TOTAL',
              style: TextStyle(
                fontFamily: GlobalStyles.fontFamilyBody,
                color: GlobalStyles.textPrimary,
                fontSize: GlobalStyles.fontSizeBody2,
                fontWeight: GlobalStyles.fontWeightBold,
              ),
            ),
            Text(
              _currencyFormat.format(finalPrice + laborFee),
              style: TextStyle(
                fontFamily: GlobalStyles.fontFamilyBody,
                color: GlobalStyles.primaryMain,
                fontSize: GlobalStyles.fontSizeBody2,
                fontWeight: GlobalStyles.fontWeightBold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCostItem(String label, double amount) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: GlobalStyles.spacingMd),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyBody,
              color: GlobalStyles.textPrimary.withAlpha(178),
              fontSize: GlobalStyles.fontSizeBody2,
            ),
          ),
          Text(
            _currencyFormat.format(amount),
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyBody,
              color: GlobalStyles.textPrimary,
              fontSize: GlobalStyles.fontSizeBody2,
              fontWeight: GlobalStyles.fontWeightMedium,
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
          height: GlobalStyles.spacingMd,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: GlobalStyles.spacingMd),
            child: Divider(color: GlobalStyles.textTertiary.withAlpha(68)),
          ),
        ),
        _buildDocumentCategory(
          'LTO C.R (Certificate of Registration)',
          'lto_cr',
          'Upload photocopy/PDF of LTO Certificate of Registration with number',
        ),
        SizedBox(
          height: GlobalStyles.spacingMd,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: GlobalStyles.spacingMd),
            child: Divider(color: GlobalStyles.textTertiary.withAlpha(68)),
          ),
        ),
        _buildDocumentCategory(
          'Driver\'s License',
          'drivers_license',
          'Upload photocopy/PDF of driver\'s license',
        ),
        SizedBox(
          height: GlobalStyles.spacingMd,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: GlobalStyles.spacingMd),
            child: Divider(color: GlobalStyles.textTertiary.withAlpha(68)),
          ),
        ),
        _buildDocumentCategory(
          'Valid ID of Owner',
          'owner_valid_id',
          'Upload photocopy/PDF of owner\'s valid government ID',
        ),
        SizedBox(
          height: GlobalStyles.spacingMd,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: GlobalStyles.spacingMd),
            child: Divider(color: GlobalStyles.textTertiary.withAlpha(68)),
          ),
        ),
        _buildDocumentCategory(
          'Police Report/Affidavit',
          'police_report',
          'Upload original police report or affidavit',
        ),
        SizedBox(
          height: GlobalStyles.spacingMd,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: GlobalStyles.spacingMd),
            child: Divider(color: GlobalStyles.textTertiary.withAlpha(68)),
          ),
        ),
        _buildDocumentCategory(
          'Insurance Policy',
          'insurance_policy',
          'Upload photocopy/PDF of your insurance policy',
        ),
        SizedBox(
          height: GlobalStyles.spacingMd,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: GlobalStyles.spacingMd),
            child: Divider(color: GlobalStyles.textTertiary.withAlpha(68)),
          ),
        ),
        _buildDocumentCategory(
          'Job Estimate',
          'job_estimate',
          'Upload repair/job estimate from service provider',
        ),
        SizedBox(
          height: GlobalStyles.spacingMd,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: GlobalStyles.spacingMd),
            child: Divider(color: GlobalStyles.textTertiary.withAlpha(68)),
          ),
        ),
        _buildDocumentCategory(
          'Pictures of Damage',
          'damage_photos',
          'Assessment photos are already included. You can add more damage photos or PDF documents if needed.',
        ),
        SizedBox(
          height: GlobalStyles.spacingMd,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: GlobalStyles.spacingMd),
            child: Divider(color: GlobalStyles.textTertiary.withAlpha(68)),
          ),
        ),
        _buildDocumentCategory(
          'Stencil Strips',
          'stencil_strips',
          'Upload stencil strips documentation',
        ),
        SizedBox(
          height: GlobalStyles.spacingMd,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: GlobalStyles.spacingMd),
            child: Divider(color: GlobalStyles.textTertiary.withAlpha(68)),
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
    final isRequired = requiredDocuments[category] ?? false;
    final uploadedFiles = uploadedDocuments[category] ?? [];
    final hasFiles = uploadedFiles.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(GlobalStyles.fontSizeBody2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
        color: GlobalStyles.textSecondary.withAlpha(25),
      ),
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
                            fontFamily: GlobalStyles.fontFamilyBody,
                            fontSize: GlobalStyles.fontSizeBody2,
                            fontWeight: GlobalStyles.fontWeightBold,
                            color: GlobalStyles.textPrimary,
                          ),
                        ),
                        if (isRequired) ...[
                          SizedBox(width: GlobalStyles.spacingMd),
                          Text(
                            '*',
                            style: TextStyle(
                              fontFamily: GlobalStyles.fontFamilyBody,
                              fontSize: GlobalStyles.fontSizeBody2,
                              color: GlobalStyles.errorMain,
                              fontWeight: GlobalStyles.fontWeightBold,
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: GlobalStyles.spacingMd),
                    Text(
                      description,
                      style: TextStyle(
                        fontFamily: GlobalStyles.fontFamilyBody,
                        fontSize: GlobalStyles.fontSizeBody2,
                        color: GlobalStyles.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasFiles)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: GlobalStyles.spacingMd,
                    vertical: GlobalStyles.spacingMd,
                  ),
                  decoration: BoxDecoration(
                    color: GlobalStyles.primaryMain.withAlpha(51),
                    borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
                  ),
                  child: Text(
                    '${uploadedFiles.length}',
                    style: TextStyle(
                      fontFamily: GlobalStyles.fontFamilyBody,
                      fontSize: GlobalStyles.fontSizeBody2,
                      color: GlobalStyles.primaryMain,
                      fontWeight: GlobalStyles.fontWeightBold,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: GlobalStyles.spacingMd),

          // Show uploaded files
          if (hasFiles) ...[
            _buildUploadedFilesList(category, uploadedFiles),
            SizedBox(height: GlobalStyles.spacingMd),
          ],

          // Upload buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickDocument(category),
                  icon: Icon(
                    LucideIcons.upload,
                    size: GlobalStyles.fontSizeBody2,
                  ),
                  label: Text(
                    'Upload File',
                    style: TextStyle(
                      fontFamily: GlobalStyles.fontFamilyBody,
                      fontSize: GlobalStyles.fontSizeBody2,
                      fontWeight: GlobalStyles.fontWeightSemiBold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlobalStyles.successMain,
                    foregroundColor: GlobalStyles.surfaceMain,
                    padding: EdgeInsets.symmetric(
                      vertical: GlobalStyles.spacingMd,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        GlobalStyles.radiusMd,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: GlobalStyles.spacingMd),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _takePhoto(category),
                  icon: Icon(
                    LucideIcons.camera,
                    size: GlobalStyles.fontSizeBody2,
                  ),
                  label: Text(
                    'Take Photo',
                    style: TextStyle(
                      fontFamily: GlobalStyles.fontFamilyBody,
                      fontSize: GlobalStyles.fontSizeBody2,
                      fontWeight: GlobalStyles.fontWeightSemiBold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlobalStyles.successMain,
                    foregroundColor: GlobalStyles.surfaceMain,
                    padding: EdgeInsets.symmetric(
                      vertical: GlobalStyles.spacingMd,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        GlobalStyles.radiusMd,
                      ),
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
    return SizedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Uploaded Files:',
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyBody,
              fontSize: GlobalStyles.fontSizeBody2,
              fontWeight: GlobalStyles.fontWeightSemiBold,
              color: GlobalStyles.primaryMain,
            ),
          ),
          SizedBox(height: GlobalStyles.spacingMd),
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
    final isPdf = fileName.toLowerCase().endsWith('.pdf');

    // Check if this is an assessment image
    final isAssessmentImage =
        category == 'damage_photos' && widget.imagePaths.contains(file.path);

    // Check if this is the auto-generated job estimate PDF
    final isAutoGeneratedJobEstimate =
        category == 'job_estimate' &&
        widget.tempJobEstimatePdfPath != null &&
        file.path == widget.tempJobEstimatePdfPath;

    return Container(
      margin: EdgeInsets.only(bottom: GlobalStyles.spacingMd),
      padding: EdgeInsets.all(GlobalStyles.spacingMd),
      decoration: BoxDecoration(
        color: GlobalStyles.primaryMain.withAlpha(15),
        borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            isImage ? LucideIcons.image : LucideIcons.fileText,
            color: GlobalStyles.primaryMain,
            size: GlobalStyles.fontSizeBody2,
          ),
          SizedBox(width: GlobalStyles.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyBody,
                    fontSize: GlobalStyles.fontSizeBody2,
                    color: GlobalStyles.primaryMain,
                    fontWeight: GlobalStyles.fontWeightBold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (isAssessmentImage) ...[
                  SizedBox(height: GlobalStyles.spacingMd),
                  Text(
                    'Assessment Image',
                    style: TextStyle(
                      fontFamily: GlobalStyles.fontFamilyBody,
                      fontSize: GlobalStyles.fontSizeBody2,
                      color: GlobalStyles.primaryMain,
                      fontWeight: GlobalStyles.fontWeightMedium,
                    ),
                  ),
                ],
                if (isAutoGeneratedJobEstimate) ...[
                  SizedBox(height: GlobalStyles.spacingMd),
                  Text(
                    'Auto-generated',
                    style: TextStyle(
                      fontFamily: GlobalStyles.fontFamilyBody,
                      fontSize: GlobalStyles.fontSizeBody2,
                      color: GlobalStyles.primaryMain,
                      fontWeight: GlobalStyles.fontWeightMedium,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isAssessmentImage)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: GlobalStyles.spacingMd,
                vertical: GlobalStyles.spacingMd,
              ),
              decoration: BoxDecoration(
                color: GlobalStyles.primaryMain,
                borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
              ),
              child: Text(
                'PROOF',
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyBody,
                  color: GlobalStyles.surfaceMain,
                  fontSize: GlobalStyles.fontSizeBody2,
                  fontWeight: GlobalStyles.fontWeightBold,
                ),
              ),
            )
          else if (isAutoGeneratedJobEstimate && isPdf)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // View button
                Container(
                  height: GlobalStyles.spacingMd,
                  width: GlobalStyles.spacingMd,
                  decoration: BoxDecoration(
                    color: GlobalStyles.infoMain.withAlpha(51),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _viewPdf(file.path),
                    icon: Icon(
                      LucideIcons.eye,
                      color: GlobalStyles.infoMain,
                      size: GlobalStyles.fontSizeBody2,
                    ),
                    tooltip: 'View PDF',
                  ),
                ),
                SizedBox(width: GlobalStyles.spacingMd),
                // Download button
                Container(
                  height: GlobalStyles.spacingMd,
                  width: GlobalStyles.spacingMd,
                  decoration: BoxDecoration(
                    color: GlobalStyles.successMain.withAlpha(51),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _downloadPdf(file.path),
                    icon: Icon(
                      LucideIcons.download,
                      color: GlobalStyles.successMain,
                      size: GlobalStyles.fontSizeBody2,
                    ),
                    tooltip: 'Download PDF',
                  ),
                ),
              ],
            )
          else
            Container(
              height: GlobalStyles.spacingMd,
              decoration: BoxDecoration(
                color: GlobalStyles.errorMain.withAlpha(51),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => _removeFile(category, file),
                icon: Icon(
                  LucideIcons.x,
                  color: GlobalStyles.errorMain,
                  size: GlobalStyles.fontSizeBody2,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.all(GlobalStyles.spacingMd),
      child: Column(
        children: [
          // Validation errors are shown via SnackBar when the Submit button is tapped
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              // Always allow tap; validation happens in _onSubmitPressed
              onPressed: _onSubmitPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: GlobalStyles.primaryMain,
                padding: EdgeInsets.symmetric(vertical: GlobalStyles.spacingMd),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
                ),
              ),
              child: Text(
                'Submit Insurance Claim',
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyBody,
                  fontSize: GlobalStyles.fontSizeBody2,
                  fontWeight: GlobalStyles.fontWeightBold,
                  color: GlobalStyles.surfaceMain,
                ),
              ),
            ),
          ),
        ],
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
