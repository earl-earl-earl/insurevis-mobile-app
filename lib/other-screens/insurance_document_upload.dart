import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:insurevis/services/supabase_service.dart';
import 'package:insurevis/services/claims_service.dart';
import 'package:insurevis/services/documents_service.dart';
import 'package:insurevis/models/document_model.dart';
import 'package:insurevis/services/prices_repository.dart';

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
  });

  @override
  State<InsuranceDocumentUpload> createState() =>
      _InsuranceDocumentUploadState();
}

class _InsuranceDocumentUploadState extends State<InsuranceDocumentUpload> {
  final ImagePicker _picker = ImagePicker();
  final DocumentService _documentService = DocumentService();

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
    // Check if any of the API responses indicate severe damage.
    return widget.apiResponses.values.any((response) {
      final severity = response['overall_severity']?.toString().toLowerCase();
      return severity == 'severe';
    });
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
    _loadDamageAssessmentImages();
    // Only fetch pricing if not already provided
    if (widget.selectedRepairOptions == null) {
      _fetchAllPricingData();
    }
  }

  /// Fetches pricing data for all detected damages when the screen opens
  Future<void> _fetchAllPricingData() async {
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
    double totalCost = 0.0;

    // First, try to get cost from API responses
    for (var response in widget.apiResponses.values) {
      if (response['total_cost'] != null) {
        totalCost += (response['total_cost'] as num).toDouble();
      } else if (response['cost_estimate'] != null) {
        totalCost += (response['cost_estimate'] as num).toDouble();
      }
    }

    // If no API cost available, calculate from pricing data
    if (totalCost == 0.0) {
      totalCost = _calculateTotalFromPricingData();
    }

    setState(() {
      _estimatedDamageCost = totalCost;
    });
  }

  double _calculateTotalFromPricingData() {
    double total = 0.0;

    _selectedRepairOptions.forEach((damageIndex, selectedOption) {
      if (selectedOption == 'repair') {
        final repairData = _repairPricingData[damageIndex];
        if (repairData == null) return;

        // Prefer comprehensive total
        final repoTotal = (repairData['total_with_labor'] as num?)?.toDouble();

        if (repoTotal != null) {
          total += repoTotal;
        } else {
          // For repair: body-paint only + labor
          double bodyPaint =
              (repairData['srp_insurance'] as num?)?.toDouble() ?? 0.0;
          double labor =
              (repairData['cost_installation_personal'] as num?)?.toDouble() ??
              0.0;
          total += bodyPaint + labor;
        }
      } else if (selectedOption == 'replace') {
        final replacePricing = _replacePricingData[damageIndex];
        final repairData = _repairPricingData[damageIndex];
        if (replacePricing == null && repairData == null) return;

        // Prefer comprehensive total
        final repoTotalReplace =
            (replacePricing?['total_with_labor'] as num?)?.toDouble() ??
            (repairData?['total_with_labor'] as num?)?.toDouble();
        if (repoTotalReplace != null) {
          total += repoTotalReplace;
        } else {
          // For replace: thinsmith + body-paint + labor
          double thinsmith =
              (replacePricing?['insurance'] as num?)?.toDouble() ?? 0.0;
          double bodyPaint =
              (repairData?['srp_insurance'] as num?)?.toDouble() ?? 0.0;
          double labor =
              (replacePricing?['cost_installation_personal'] as num?)
                  ?.toDouble() ??
              (repairData?['cost_installation_personal'] as num?)?.toDouble() ??
              0.0;
          total += thinsmith + bodyPaint + labor;
        }
      }
    });

    return total;
  }

  // Helper method to format damaged part name to match API
  String _formatDamagedPartForApi(String partName) {
    if (partName.isEmpty) return partName;

    // Replace hyphens with spaces and handle common variations
    String formatted =
        partName.replaceAll('-', ' ').replaceAll('_', ' ').trim();

    // Convert to title case (first letter of each word capitalized)
    List<String> words = formatted.split(' ');
    List<String> capitalizedWords =
        words.map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).toList();

    return capitalizedWords.join(' ');
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
      // Format the part name to match API format
      final formattedPartName = _formatDamagedPartForApi(damagedPart);

      // Get both repair and replace data at once
      final bothPricingData = await PricesRepository.instance
          .getBothRepairAndReplacePricing(formattedPartName);

      if (mounted) {
        setState(() {
          // Store repair data separately
          _repairPricingData[damageIndex] = bothPricingData['repair_data'];

          // Store replace data separately
          _replacePricingData[damageIndex] = bothPricingData['replace_data'];

          _isLoadingPricing[damageIndex] = false;

          // Recalculate total cost
          _calculateEstimatedDamageCost();
        });
      }
    } catch (e) {
      // Error handling: silently fail and show estimated costs instead
      if (mounted) {
        setState(() {
          _repairPricingData[damageIndex] = null;
          _replacePricingData[damageIndex] = null;
          _isLoadingPricing[damageIndex] = false;
        });
      }
    }
  }

  void _loadDamageAssessmentImages() {
    // Add the damage assessment images from the previous screen as damage photos
    for (String imagePath in widget.imagePaths) {
      final file = File(imagePath);
      if (file.existsSync()) {
        uploadedDocuments['damage_photos']!.add(file);
      }
    }

    // Update UI to reflect the loaded images
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _incidentLocationController.dispose();
    _incidentDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2A2A2A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Upload Documents',
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2A2A2A),
          ),
        ),
      ),
      body: Container(
        height: double.infinity,
        color: Colors.white,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInstructions(),
                    SizedBox(height: 40.h),
                    _buildVehicleInfoSection(),
                    SizedBox(height: 40.h),
                    _buildIncidentInformationSection(),
                    _buildDamageAssessmentImagesSection(),
                    SizedBox(height: 40.h),
                    _buildRepairOptionsSection(),
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
                    // Removed duplicate vehicle info section from bottom of the form
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

  Widget _buildVehicleInfoSection() {
    if (widget.vehicleData == null) return const SizedBox.shrink();

    final make = widget.vehicleData!['make'] ?? 'N/A';
    final model = widget.vehicleData!['model'] ?? 'N/A';
    final year = widget.vehicleData!['year'] ?? 'N/A';
    final plateNumber = widget.vehicleData!['plate_number'] ?? 'N/A';

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
            child: Column(
              children: [
                _buildVehicleInfoRow('Make', make),
                Divider(height: 24.h, color: Colors.grey.shade100),
                _buildVehicleInfoRow('Model', model),
                Divider(height: 24.h, color: Colors.grey.shade100),
                _buildVehicleInfoRow('Year', year),
                Divider(height: 24.h, color: Colors.grey.shade100),
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
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: const Color(0x992A2A2A),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: const Color(0xFF2A2A2A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: EdgeInsets.all(20.sp),
      decoration: BoxDecoration(
        color: GlobalStyles.primaryColor.withAlpha(25),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_rounded,
                color: GlobalStyles.primaryColor,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Required Documents',
                style: GoogleFonts.inter(
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
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: const Color(0xFF2A2A2A),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentInformationSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Incident Information',
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
            'Please provide details about when and where the incident occurred.',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: const Color(0x992A2A2A),
            ),
          ),
          SizedBox(height: 30.h),

          // Incident Location
          _buildIncidentInputField(
            controller: _incidentLocationController,
            label: 'Incident Location',
            hint: 'e.g., EDSA Quezon City, Makati Avenue',
            icon: Icons.place,
          ),
          SizedBox(height: 16.h),

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
            Icon(icon, color: GlobalStyles.primaryColor, size: 16.sp),
            SizedBox(width: 8.w),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0x992A2A2A),
              ),
            ),
            Text(
              ' *',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(
            color: const Color(0xFF2A2A2A),
            fontSize: 14.sp,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: const Color(0x992A2A2A),
              fontSize: 14.sp,
            ),
            filled: true,
            fillColor: Colors.black12.withAlpha((0.04 * 255).toInt()),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.white.withAlpha(76)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.white.withAlpha(76)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(
                color: GlobalStyles.primaryColor.withAlpha(153),
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 12.h,
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
              Icons.calendar_today,
              color: GlobalStyles.primaryColor,
              size: 16.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              'Incident Date',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0x992A2A2A),
              ),
            ),
            Text(
              ' *',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: _incidentDateController,
          readOnly: true,
          style: GoogleFonts.inter(
            color: const Color(0xFF2A2A2A),
            fontSize: 14.sp,
          ),
          decoration: InputDecoration(
            hintText: 'Select incident date',
            hintStyle: GoogleFonts.inter(
              color: const Color(0x992A2A2A),
              fontSize: 14.sp,
            ),
            filled: true,
            fillColor: Colors.black12.withAlpha((0.04 * 255).toInt()),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.white.withAlpha(76)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.white.withAlpha(76)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(
                color: GlobalStyles.primaryColor.withAlpha(153),
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 12.h,
            ),
            suffixIcon: Icon(
              Icons.calendar_today_rounded,
              color: const Color(0x992A2A2A),
              size: 16.sp,
            ),
          ),
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now(),
              builder: (context, child) {
                // Use a light themed date picker for a brighter calendar design
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: GlobalStyles.primaryColor,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: const Color(0xFF2A2A2A),
                    ),
                    dialogBackgroundColor: Colors.white,
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: GlobalStyles.primaryColor,
                      ),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() {
                _incidentDateController.text =
                    "${picked.day}/${picked.month}/${picked.year}";
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildEstimatedCostSection() {
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
                if (_isDamageSevere) ...[
                  Text(
                    'Severe damage. Final cost will be provided by the mechanic.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else ...[
                  if (_isLoadingPricing.values.any((loading) => loading)) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16.w,
                          height: 16.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: GlobalStyles.primaryColor,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Calculating pricing...',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: GlobalStyles.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      _estimatedDamageCost == 0.0
                          ? 'N/A'
                          : _currencyFormat.format(_estimatedDamageCost),
                      style: GoogleFonts.inter(
                        fontSize: 28.sp,
                        color: GlobalStyles.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  if (_estimatedDamageCost == 0 &&
                      !_isLoadingPricing.values.any((loading) => loading)) ...[
                    SizedBox(height: 8.h),
                    Text(
                      _selectedRepairOptions.isEmpty
                          ? 'Select repair/replace options to calculate cost'
                          : 'Cost will be calculated based on repair options',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: const Color(0x992A2A2A),
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
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Damage Assessment\nImages',
                style: GoogleFonts.inter(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2A2A2A),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: GlobalStyles.primaryColor.withAlpha(51),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  '${widget.imagePaths.length}',
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
          Text(
            'These are the images you took for damage assessment. They have been automatically included as damage proof for your claim.',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: const Color(0x992A2A2A),
              height: 1.5,
            ),
          ),
          SizedBox(height: 20.h),

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
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
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
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.green.withAlpha(76), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6.r),
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
                  color: Colors.grey[800],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                          size: 24.sp,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Image Error',
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 10.sp,
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
              top: 4.h,
              right: 4.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  'ASSESSED',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 8.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Image number
            Positioned(
              bottom: 4.h,
              left: 4.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: GlobalStyles.primaryColor.withAlpha(178),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
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
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Damage Assessment',
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
                color: Colors.orange.withAlpha(38),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.orange.withAlpha(76)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 48.sp,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Complete Your Assessment',
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2A2A2A),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Please review your damage assessment and select repair options before proceeding with your claim.',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: const Color(0x992A2A2A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Go back to PDF Assessment
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        'Go to Assessment Report',
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Damage Assessment Summary',
            style: GoogleFonts.inter(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2A2A2A),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Review your selected repair options and pricing below.',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: const Color(0x992A2A2A),
            ),
          ),
          SizedBox(height: 24.h),

          // Display summary of damages and selected options
          ...(() {
            final List<Widget> widgets = [];

            // API-detected damages
            for (int i = 0; i < damagesList.length; i++) {
              final damage = damagesList[i];
              final selectedOption = _selectedRepairOptions[i];

              if (selectedOption != null) {
                widgets.add(_buildDamageSummaryCard(i, damage, selectedOption));
                widgets.add(SizedBox(height: 12.h));
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
                widgets.add(SizedBox(height: 12.h));
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
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: GlobalStyles.primaryColor.withAlpha(25),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: GlobalStyles.primaryColor.withAlpha(76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(51),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  selectedOption.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: Colors.green,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            damagedPart,
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2A2A2A),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            damageType,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: const Color(0x992A2A2A),
            ),
          ),
          SizedBox(height: 12.h),
          Divider(color: Colors.grey.withAlpha(76)),
          SizedBox(height: 12.h),
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
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: GlobalStyles.primaryColor.withAlpha(25),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: GlobalStyles.primaryColor.withAlpha(76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(51),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  selectedOption.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: Colors.green,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            damagedPart,
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2A2A2A),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            damageType,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: const Color(0x992A2A2A),
            ),
          ),
          SizedBox(height: 12.h),
          Divider(color: Colors.grey.withAlpha(76)),
          SizedBox(height: 12.h),
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
          SizedBox(height: 8.h),
          _buildCostItem('Paint Price', bodyPaintPrice),
        ] else if (option == 'replace') ...[
          SizedBox(height: 8.h),
          _buildCostItem('Part Price', thinsmithPrice),
          _buildCostItem('Paint Price', bodyPaintPrice),
        ],
        SizedBox(height: 8.h),
        Divider(color: Colors.grey.withAlpha(76)),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TOTAL',
              style: GoogleFonts.inter(
                color: const Color(0xFF2A2A2A),
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _currencyFormat.format(finalPrice + laborFee),
              style: GoogleFonts.inter(
                color: GlobalStyles.primaryColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCostItem(String label, double amount) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.black.withAlpha(178),
              fontSize: 13.sp,
            ),
          ),
          Text(
            _currencyFormat.format(amount),
            style: GoogleFonts.inter(
              color: Colors.black,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
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
    final isRequired = requiredDocuments[category] ?? false;
    final uploadedFiles = uploadedDocuments[category] ?? [];
    final hasFiles = uploadedFiles.isNotEmpty;

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
                    '${uploadedFiles.length}',
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
            _buildUploadedFilesList(category, uploadedFiles),
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

  Widget _buildUploadedFilesList(String category, List<File> files) {
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

    // Check if this is an assessment image
    final isAssessmentImage =
        category == 'damage_photos' && widget.imagePaths.contains(file.path);

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: GlobalStyles.primaryColor.withAlpha(51),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                if (isAssessmentImage) ...[
                  SizedBox(height: 2.h),
                  Text(
                    'Assessment Image',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: GlobalStyles.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isAssessmentImage)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: GlobalStyles.primaryColor,
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                'PROOF',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 8.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Container(
              height: 30.h,
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(51),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => _removeFile(category, file),
                icon: Icon(Icons.close_rounded, color: Colors.red, size: 16.sp),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          // Validation errors are shown via SnackBar when the Submit button is tapped
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              // Always allow tap; validation happens in _onSubmitPressed
              onPressed: _onSubmitPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: GlobalStyles.primaryColor,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'Submit Insurance Claim',
                style: GoogleFonts.inter(
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

  void _showUploadProgressModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(178),
      builder:
          (context) => PopScope(
            canPop: false,
            child: Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress indicator
                    SizedBox(
                      width: 60.w,
                      height: 60.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        color: GlobalStyles.primaryColor,
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Title
                    Text(
                      'Uploading Documents',
                      style: GoogleFonts.inter(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2A2A2A),
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Description
                    Text(
                      'Please wait while we upload your documents and process your insurance claim.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: const Color(0x992A2A2A),
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Info message
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: GlobalStyles.primaryColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: GlobalStyles.primaryColor,
                            size: 16.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'This may take a few moments',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: GlobalStyles.primaryColor,
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
      final missing =
          requiredDocuments.keys
              .where(
                (k) =>
                    requiredDocuments[k]! &&
                    (uploadedDocuments[k] ?? []).isEmpty,
              )
              .map((k) => _documentTitleFromKey(k))
              .toList();
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
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  String _documentTitleFromKey(String key) {
    switch (key) {
      case 'lto_or':
        return 'LTO O.R.';
      case 'lto_cr':
        return 'LTO C.R.';
      case 'drivers_license':
        return 'Driver\'s License';
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
      default:
        return key;
    }
  }

  Future<void> _pickDocument(String category) async {
    try {
      // Ensure we have storage permission before launching file picker.
      final hasPerm = await _ensureStoragePermission();
      if (!hasPerm) {
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

  /// Ensures storage permission is granted. Handles Android's MANAGE_EXTERNAL_STORAGE
  /// where applicable. Returns true if permission is available, false otherwise.
  Future<bool> _ensureStoragePermission() async {
    try {
      // On Android, newer versions may require MANAGE_EXTERNAL_STORAGE for broad access.
      if (Platform.isAndroid) {
        // First try the normal storage permission
        final status = await Permission.storage.status;
        if (status.isGranted) return true;

        // If Android 11+ and storage not granted, try manage external storage
        final manageStatus = await Permission.manageExternalStorage.status;
        if (manageStatus.isGranted) return true;

        // Request storage first
        final requested = await Permission.storage.request();
        if (requested.isGranted) return true;

        // If still not granted, request manage external storage permission
        final manageRequested =
            await Permission.manageExternalStorage.request();
        if (manageRequested.isGranted) return true;

        // If permanently denied or restricted, prompt user to open app settings
        if (requested.isPermanentlyDenied ||
            manageRequested.isPermanentlyDenied) {
          final open = await showDialog<bool?>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Storage permission required'),
                  content: const Text(
                    'Storage permission is required to upload documents. Open app settings to allow it.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Open settings'),
                    ),
                  ],
                ),
          );
          if (open == true) await openAppSettings();
          return false;
        }

        return false;
      } else {
        // On non-Android platforms, storage permission is not required the same way.
        return true;
      }
    } catch (e) {
      // On error, be conservative and return false so callers can show message.
      return false;
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
    // Prevent removal of assessment images from damage_photos category
    if (category == 'damage_photos' && widget.imagePaths.contains(file.path)) {
      _showErrorMessage(
        'Assessment images cannot be removed. They are required as damage proof.',
      );
      return;
    }

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

  bool _checkIncidentInformation() {
    return _incidentLocationController.text.trim().isNotEmpty &&
        _incidentDateController.text.trim().isNotEmpty;
  }

  Future<void> _submitClaim() async {
    // Show upload progress modal
    _showUploadProgressModal();

    try {
      // Get current user
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        // Close upload modal
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        _showErrorMessage('Please sign in to submit a claim');
        return;
      }

      // Extract assessment data from widget parameters
      String? incidentDescription;
      double? estimatedCost;

      // Build incident description with damage details and repair options
      List<String> descriptionLines = [];

      // Try to extract damage data from API responses
      if (widget.apiResponses.isNotEmpty) {
        final firstResponse = widget.apiResponses.values.first;

        // Extract damaged areas information
        List<String> damageDetails = [];
        if (firstResponse['damaged_areas'] != null) {
          final damagedAreas = firstResponse['damaged_areas'] as List;

          for (int i = 0; i < damagedAreas.length; i++) {
            final area = damagedAreas[i];
            final areaName = area['name'] ?? area.toString();
            final repairOption = _selectedRepairOptions[i] ?? 'Not specified';
            damageDetails.add(
              'Damage ${i + 1}: $areaName, Option: $repairOption',
            );
          }
        }

        if (damageDetails.isNotEmpty) {
          descriptionLines.add('Damages: ${damageDetails.length}');
          descriptionLines.addAll(damageDetails);
        }

        // Extract cost estimation
        if (firstResponse['total_cost'] != null) {
          estimatedCost = (firstResponse['total_cost'] as num).toDouble();
        }
      }

      incidentDescription = descriptionLines.join('\n');

      // Parse incident date from the form
      DateTime incidentDate = DateTime.now().subtract(const Duration(days: 1));
      try {
        if (_incidentDateController.text.trim().isNotEmpty) {
          final dateParts = _incidentDateController.text.split('/');
          if (dateParts.length == 3) {
            incidentDate = DateTime(
              int.parse(dateParts[2]), // year
              int.parse(dateParts[1]), // month
              int.parse(dateParts[0]), // day
            );
          }
        }
      } catch (e) {
        // If parsing fails, use default date
        debugPrint('Error parsing incident date: $e');
      }

      // Use estimated damage cost from calculation, or from API if available
      double finalEstimatedCost =
          _estimatedDamageCost > 0
              ? _estimatedDamageCost
              : (estimatedCost ?? 0.0);

      // Build damages payload combining API-detected damages and manual damages
      List<Map<String, dynamic>> damagesPayload = [];

      // Extract API-detected damages first
      if (widget.apiResponses.isNotEmpty) {
        for (var response in widget.apiResponses.values) {
          List<Map<String, dynamic>> damagesList = [];
          if (response['damages'] is List) {
            damagesList.addAll(
              (response['damages'] as List).cast<Map<String, dynamic>>(),
            );
          } else if (response['prediction'] is List) {
            damagesList.addAll(
              (response['prediction'] as List).cast<Map<String, dynamic>>(),
            );
          }

          for (int i = 0; i < damagesList.length; i++) {
            final damage = damagesList[i];
            String damagedPart =
                damage.containsKey('damaged_part')
                    ? damage['damaged_part']?.toString() ?? 'Unknown Part'
                    : 'Unknown Part';

            String damageType = 'Unknown Damage';
            if (damage.containsKey('damage_type')) {
              final dt = damage['damage_type'];
              if (dt is Map && dt.containsKey('class_name')) {
                damageType = dt['class_name']?.toString() ?? 'Unknown Damage';
              } else {
                damageType = dt?.toString() ?? 'Unknown Damage';
              }
            }

            final selectedOption = _selectedRepairOptions[i] ?? 'repair';

            // pricing info (may be null)
            final bodyPaintPricing = _repairPricingData[i];
            final thinsmithPricing = _replacePricingData[i];

            double? repairInsurance =
                thinsmithPricing != null
                    ? (thinsmithPricing['insurance'] as num?)?.toDouble()
                    : null;
            double? replaceInsurance =
                bodyPaintPricing != null
                    ? (bodyPaintPricing['srp_insurance'] as num?)?.toDouble()
                    : null;

            damagesPayload.add({
              'damaged_part': _formatDamagedPartForApi(damagedPart),
              'damage_type': damageType,
              'selected_option': selectedOption,
              'pricing': {
                'repair_insurance': repairInsurance,
                'replace_insurance': replaceInsurance,
              },
            });
          }
        }
      }

      // Add manual damages (we used negative global indices for these)
      for (int mi = 0; mi < _manualDamages.length; mi++) {
        final manual = _manualDamages[mi];
        final globalIndex = -(mi + 1);
        final damagedPart = manual['damaged_part'] ?? 'Unknown Part';
        final damageType = manual['damage_type'] ?? 'Unknown Damage';
        final selectedOption = _selectedRepairOptions[globalIndex] ?? 'repair';

        final bodyPaintPricing = _repairPricingData[globalIndex];
        final thinsmithPricing = _replacePricingData[globalIndex];

        double? repairInsurance =
            thinsmithPricing != null
                ? (thinsmithPricing['insurance'] as num?)?.toDouble()
                : null;
        double? replaceInsurance =
            bodyPaintPricing != null
                ? (bodyPaintPricing['srp_insurance'] as num?)?.toDouble()
                : null;

        damagesPayload.add({
          'damaged_part': _formatDamagedPartForApi(damagedPart),
          'damage_type': damageType,
          'selected_option': selectedOption,
          'pricing': {
            'repair_insurance': repairInsurance,
            'replace_insurance': replaceInsurance,
          },
        });
      }

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

      // Create claim using ClaimsService
      final claim = await ClaimsService.createClaim(
        userId: currentUser.id,
        incidentDate: incidentDate,
        incidentLocation:
            _incidentLocationController.text.trim().isNotEmpty
                ? _incidentLocationController.text.trim()
                : 'Location to be specified by user',
        incidentDescription:
            incidentDescription.isNotEmpty
                ? incidentDescription
                : 'Vehicle damage assessment submitted via InsureVis app',
        vehicleMake: widget.vehicleData?['make'],
        vehicleModel: widget.vehicleData?['model'],
        vehicleYear:
            widget.vehicleData?['year'] != null
                ? int.tryParse(widget.vehicleData!['year']!)
                : null,
        vehiclePlateNumber: widget.vehicleData?['plate_number'],
        estimatedDamageCost: finalEstimatedCost,
        damages: damagesPayload,
      );

      if (claim != null) {
        debugPrint('=== CLAIM CREATED ===');
        debugPrint('Claim ID: ${claim.id}');
        debugPrint('Vehicle Make in claim: ${claim.vehicleMake}');
        debugPrint('Vehicle Model in claim: ${claim.vehicleModel}');
        debugPrint('Vehicle Year in claim: ${claim.vehicleYear}');
        debugPrint('Plate Number in claim: ${claim.vehiclePlateNumber}');
        debugPrint('==================');
      }

      if (claim == null) {
        // Close upload modal
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        _showErrorMessage('Failed to create claim. Please try again.');
        return;
      }

      debugPrint('Starting document upload for claim: ${claim.id}');
      bool allUploadsSuccessful = true;
      int totalUploaded = 0;

      // Collect all files to upload in parallel
      final List<File> allFiles = [];
      final List<DocumentType> allTypes = [];
      final List<String> allDescriptions = [];
      final List<bool> allIsRequired = [];

      for (String docTypeKey in uploadedDocuments.keys) {
        final files = uploadedDocuments[docTypeKey] ?? [];
        if (files.isNotEmpty) {
          debugPrint(
            'Preparing ${files.length} files for document type: $docTypeKey',
          );

          // Convert string key to DocumentType enum
          final DocumentType docType = DocumentType.fromKey(docTypeKey);

          // Add files to batch lists
          for (File file in files) {
            allFiles.add(file);
            allTypes.add(docType);
            allDescriptions.add(
              'Document uploaded for insurance claim ${claim.claimNumber}',
            );
            allIsRequired.add(docType.isRequired);
          }
        }
      }

      // Upload all files in parallel for faster processing
      if (allFiles.isNotEmpty) {
        debugPrint('Uploading ${allFiles.length} files in parallel...');
        try {
          final uploadResults = await _documentService.uploadMultipleDocuments(
            files: allFiles,
            types: allTypes,
            userId: currentUser.id,
            claimId: claim.id,
            descriptions: allDescriptions,
            isRequiredList: allIsRequired,
          );

          // Check results
          for (int i = 0; i < uploadResults.length; i++) {
            if (uploadResults[i] != null) {
              debugPrint(
                'Successfully uploaded: ${uploadResults[i]!.fileName}',
              );
              totalUploaded++;
            } else {
              debugPrint('Failed to upload file: ${allFiles[i].path}');
              allUploadsSuccessful = false;
            }
          }
        } catch (e) {
          debugPrint('Error during parallel upload: $e');
          allUploadsSuccessful = false;
        }
      }

      debugPrint('Total files uploaded: $totalUploaded');

      if (!allUploadsSuccessful) {
        // Close upload modal
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        _showErrorMessage('Some documents failed to upload. Please try again.');
        return;
      }

      // Submit the claim (change status from draft to submitted)
      final submitSuccess = await ClaimsService.submitClaim(claim.id);

      if (!submitSuccess) {
        // Close upload modal
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        _showErrorMessage(
          'Claim created but submission failed. Please try again.',
        );
        return;
      }

      if (mounted) {
        // Close upload modal
        Navigator.of(context, rootNavigator: true).pop();
        // Show success dialog
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

  void _showSuccessDialog({String? claimNumber}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 24.sp),
                SizedBox(width: 12.w),
                Text(
                  'Claim Submitted',
                  style: GoogleFonts.inter(
                    color: Color(0xFF2A2A2A),
                    fontSize: 18.sp,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your insurance claim has been submitted successfully.',
                  style: GoogleFonts.inter(
                    color: Color(0x992A2A2A),
                    fontSize: 14.sp,
                  ),
                ),
                if (claimNumber != null) ...[
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.all(Radius.circular(5.r)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.confirmation_number,
                          color: Colors.white,
                          size: 16.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Claim #: $claimNumber',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 12.h),
                Text(
                  'Please be patient when waiting for approval.',
                  style: GoogleFonts.inter(
                    color: Color(0x992A2A2A),
                    fontSize: 12.sp,
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
                  style: GoogleFonts.inter(color: GlobalStyles.primaryColor),
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
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
