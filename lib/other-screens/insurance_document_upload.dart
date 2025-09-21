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
import 'package:insurevis/services/pricing_service.dart';

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

  // Vehicle information controllers
  final TextEditingController _vehicleMakeController = TextEditingController();
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _vehicleYearController = TextEditingController();
  final TextEditingController _plateNumberController = TextEditingController();

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
  bool _showAddDamageForm = false;
  String? _newDamagePart;
  String? _newDamageType;
  String _newSelectedOption = 'repair';

  // Car parts and damage types for dropdowns
  final List<String> _carParts = [
    "Back-bumper",
    "Back-door",
    "Back-wheel",
    "Back-window",
    "Back-windshield",
    "Fender",
    "Front-bumper",
    "Front-door",
    "Front-wheel",
    "Front-window",
    "Grille",
    "Headlight",
    "Hood",
    "License-plate",
    "Mirror",
    "Quarter-panel",
    "Rocker-panel",
    "Roof",
    "Tail-light",
    "Trunk",
    "Windshield",
  ];

  final List<String> _carDamageTypes = [
    "Crack",
    "Dent",
    "Shattered Glass",
    "Broken Lamp",
    "Scratch / Paint Wear",
    "Flat Tire",
  ];

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
    _calculateEstimatedDamageCost();
    _loadDamageAssessmentImages();
    _fetchAllPricingData();
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
      if (selectedOption == 'repair' &&
          _repairPricingData[damageIndex] != null) {
        final repairData = _repairPricingData[damageIndex]!;
        final replacePricingForRepair = _replacePricingData[damageIndex];

        // For repair: thinsmith + body paint
        double repairCost =
            (repairData['insurance'] as num?)?.toDouble() ?? 0.0;
        if (replacePricingForRepair != null) {
          repairCost +=
              (replacePricingForRepair['srp_insurance'] as num?)?.toDouble() ??
              0.0;
        }
        total += repairCost;
      } else if (selectedOption == 'replace' &&
          _replacePricingData[damageIndex] != null) {
        final replaceData = _replacePricingData[damageIndex]!;

        // For replace: body-paint data only
        double replaceCost =
            (replaceData['srp_insurance'] as num?)?.toDouble() ?? 0.0;
        total += replaceCost;
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

  // Helper to format labels for UI dropdowns (nicer display)
  String _formatLabel(String raw) {
    if (raw.isEmpty) return raw;
    String formatted = raw.replaceAll('-', ' ').replaceAll('_', ' ').trim();
    final words = formatted.split(' ');
    return words
        .map(
          (w) =>
              w.isEmpty
                  ? w
                  : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
        )
        .join(' ');
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
      final bothPricingData =
          await PricingService.getBothRepairAndReplacePricing(
            formattedPartName,
          );

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
    _vehicleMakeController.dispose();
    _vehicleModelController.dispose();
    _vehicleYearController.dispose();
    _plateNumberController.dispose();
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
                    _buildVehicleInformationSection(),
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

  Widget _buildVehicleInformationSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Vehicle Information',
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
            'Please provide your vehicle details for the insurance claim.',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: const Color(0x992A2A2A),
            ),
          ),
          SizedBox(height: 30.h),

          // Vehicle Make
          _buildVehicleInputField(
            controller: _vehicleMakeController,
            label: 'Vehicle Make',
            hint: 'e.g., Toyota, Honda, Ford',
            icon: Icons.business,
          ),
          SizedBox(height: 16.h),

          // Vehicle Model
          _buildVehicleInputField(
            controller: _vehicleModelController,
            label: 'Vehicle Model',
            hint: 'e.g., Camry, Civic, Mustang',
            icon: Icons.directions_car_filled,
          ),
          SizedBox(height: 16.h),

          // Vehicle Year
          _buildVehicleInputField(
            controller: _vehicleYearController,
            label: 'Vehicle Year',
            hint: 'e.g., 2020, 2018, 2022',
            icon: Icons.calendar_today,
            keyboardType: TextInputType.number,
            maxLength: 4,
          ),
          SizedBox(height: 16.h),

          // Plate Number
          _buildVehicleInputField(
            controller: _plateNumberController,
            label: 'Plate Number',
            hint: 'e.g., ABC-1234, NCR-123-A',
            icon: Icons.confirmation_number,
            maxLength: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLength,
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
          maxLength: maxLength,
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
            counterText: '', // Hide character counter
          ),
        ),
      ],
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
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.dark(
                      primary: GlobalStyles.primaryColor,
                      onPrimary: Colors.white,
                      surface: Colors.grey[800]!,
                      onSurface: Colors.white,
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
                'Estimated Damage Cost',
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
            'This is the estimated cost based on the damage assessment from your photos.',
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
                      _currencyFormat.format(_estimatedDamageCost),
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

    // Do not return early when there are no API-detected damages.
    // We still want to allow users to add manual damages.

    return Container(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Repair Options',
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
            'Please select your preferred option for each damaged part.',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: const Color(0x992A2A2A),
            ),
          ),
          SizedBox(height: 30.h),

          // Display damage options from API
          if (damagesList.isEmpty) ...[
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: GlobalStyles.primaryColor.withAlpha(38),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_rounded,
                    color: GlobalStyles.primaryColor,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'No damages were automatically detected. You can add damages manually.',
                      style: GoogleFonts.inter(
                        color: const Color(0x992A2A2A),
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
          ] else ...[
            for (int index = 0; index < damagesList.length; index++)
              _buildDamageRepairOption(index, damagesList[index]),
          ],

          // Display manual damages added by user
          for (int i = 0; i < _manualDamages.length; i++)
            _buildManualDamageRepairOption(-(i + 1), _manualDamages[i]),

          SizedBox(height: 12.h),

          // Add Damage form toggle and button
          if (_showAddDamageForm) ...[
            _buildAddDamageForm(),
            SizedBox(height: 8.h),
          ],

          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  side: BorderSide.none,
                ),
                backgroundColor:
                    _showAddDamageForm
                        ? GlobalStyles.primaryColor.withAlpha(76)
                        : GlobalStyles.primaryColor,
              ),
              onPressed: () {
                setState(() {
                  _showAddDamageForm = !_showAddDamageForm;
                });
              },
              child: Text(
                _showAddDamageForm ? 'Cancel' : 'Add Damage',
                style: GoogleFonts.inter(
                  color:
                      _showAddDamageForm
                          ? GlobalStyles.primaryColor
                          : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddDamageForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Part dropdown
        Text(
          'Detected Damage (Car Part)',
          style: GoogleFonts.inter(
            color: const Color(0x992A2A2A),
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: Colors.black12.withAlpha((0.04 * 255).toInt()),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: DropdownButton<String>(
            value: _newDamagePart,
            hint: Text(
              'Select part',
              style: GoogleFonts.inter(
                color: const Color(0x992A2A2A),
                fontSize: 12.sp,
              ),
            ),
            style: GoogleFonts.inter(
              color: const Color(0xFF2A2A2A),
              fontSize: 14.sp,
            ),
            isExpanded: true,
            dropdownColor: Colors.white,
            underline: const SizedBox.shrink(),
            items:
                _carParts
                    .map(
                      (p) => DropdownMenuItem<String>(
                        value: p,
                        child: Text(
                          _formatLabel(p),
                          style: GoogleFonts.inter(
                            color: const Color(0xFF2A2A2A),
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    )
                    .toList(),
            onChanged: (val) => setState(() => _newDamagePart = val),
          ),
        ),
        SizedBox(height: 12.h),

        // Damage type dropdown
        Text(
          'Damage Type',
          style: GoogleFonts.inter(
            color: const Color(0x992A2A2A),
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: Colors.black12.withAlpha((0.04 * 255).toInt()),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: DropdownButton<String>(
            value: _newDamageType,
            hint: Text(
              'Select damage type',
              style: GoogleFonts.inter(color: const Color(0x992A2A2A)),
            ),
            isExpanded: true,
            style: GoogleFonts.inter(
              color: const Color(0xFF2A2A2A),
              fontSize: 14.sp,
            ),
            dropdownColor: Colors.white,
            underline: const SizedBox.shrink(),
            items:
                _carDamageTypes
                    .map(
                      (d) => DropdownMenuItem<String>(
                        value: d,
                        child: Text(
                          _formatLabel(d),
                          style: GoogleFonts.inter(
                            color: const Color(0xFF2A2A2A),
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    )
                    .toList(),
            onChanged: (val) => setState(() => _newDamageType = val),
          ),
        ),
        SizedBox(height: 12.h),

        // Repair/Replace buttons for new damage
        Row(
          children: [
            Expanded(
              child: _buildOptionButton(
                'Repair',
                Icons.build,
                _newSelectedOption == 'repair',
                () => setState(() => _newSelectedOption = 'repair'),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildOptionButton(
                'Replace',
                Icons.autorenew,
                _newSelectedOption == 'replace',
                () => setState(() => _newSelectedOption = 'replace'),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),

        // Add button
        SizedBox(
          width: double.infinity,
          height: 50.h,
          child: ElevatedButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return Colors.grey; // Disabled background
                }
                return GlobalStyles.primaryColor; // Enabled background
              }),
              foregroundColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return Colors.white70; // Disabled text color
                }
                return Colors.white; // Enabled text color
              }),
              side: WidgetStateBorderSide.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return const BorderSide(
                    color: Colors.grey,
                  ); // Disabled border
                }
                return BorderSide(
                  color: GlobalStyles.primaryColor,
                ); // Enabled border
              }),
              shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
            onPressed:
                (_newDamagePart != null && _newDamageType != null)
                    ? () {
                      // Add to manual damages list
                      setState(() {
                        // compute index for manual damage as negative index to avoid colliding with API indices
                        final int newGlobalIndex = -(_manualDamages.length + 1);

                        _manualDamages.add({
                          'damaged_part': _newDamagePart!,
                          'damage_type': _newDamageType!,
                        });

                        // Set selected option for this new damage
                        _selectedRepairOptions[newGlobalIndex] =
                            _newSelectedOption;

                        // Attempt to fetch pricing for new damage
                        _fetchPricingForDamage(
                          newGlobalIndex,
                          _newDamagePart!,
                          _newSelectedOption,
                        );

                        // reset form
                        _newDamagePart = null;
                        _newDamageType = null;
                        _newSelectedOption = 'repair';
                        _showAddDamageForm = false;
                      });
                    }
                    : null,
            child: Text(
              'Add Damage',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualDamageRepairOption(
    int globalIndex,
    Map<String, String> damage,
  ) {
    final damagedPart = damage['damaged_part'] ?? 'Unknown Part';
    final damageType = damage['damage_type'] ?? 'Unknown Damage';

    String selectedOption = _selectedRepairOptions[globalIndex] ?? 'repair';

    final displayIndex = globalIndex < 0 ? (-globalIndex) - 1 : globalIndex;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 8.h, bottom: 16.h),
      decoration: BoxDecoration(
        color: GlobalStyles.primaryColor.withAlpha(25),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Manual Damage ${displayIndex + 1}",
                style: GoogleFonts.inter(
                  color: GlobalStyles.secondaryColor,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    // convert globalIndex back to manual list index
                    final manualIdx =
                        globalIndex < 0 ? -globalIndex - 1 : globalIndex;
                    if (manualIdx >= 0 && manualIdx < _manualDamages.length) {
                      _manualDamages.removeAt(manualIdx);
                    }
                  });
                },
                icon: Icon(
                  Icons.remove_circle_rounded,
                  color: Colors.red,
                  size: 20.sp,
                ),
              ),
            ],
          ),
          _buildDamageInfo(damagedPart, damageType),
          SizedBox(height: 7.h),
          Row(
            children: [
              Expanded(
                child: _buildOptionButton(
                  'Repair',
                  Icons.build,
                  selectedOption == 'repair',
                  () {
                    setState(() {
                      _selectedRepairOptions[globalIndex] = 'repair';
                    });
                    _fetchPricingForDamage(globalIndex, damagedPart, 'repair');
                  },
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildOptionButton(
                  'Replace',
                  Icons.autorenew,
                  selectedOption == 'replace',
                  () {
                    setState(() {
                      _selectedRepairOptions[globalIndex] = 'replace';
                    });
                    _fetchPricingForDamage(globalIndex, damagedPart, 'replace');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDamageRepairOption(int index, Map<String, dynamic> damage) {
    String damagedPart = 'Unknown Part';
    String damageType = 'Unknown Damage';

    // Extract damaged part
    if (damage.containsKey('damaged_part')) {
      damagedPart = damage['damaged_part']?.toString() ?? 'Unknown Part';
    }

    // Extract damage type
    if (damage.containsKey('damage_type')) {
      final damageTypeValue = damage['damage_type'];
      if (damageTypeValue is Map && damageTypeValue.containsKey('class_name')) {
        damageType =
            damageTypeValue['class_name']?.toString() ?? 'Unknown Damage';
      } else {
        damageType = damageTypeValue?.toString() ?? 'Unknown Damage';
      }
    }

    String selectedOption = _selectedRepairOptions[index] ?? 'repair';

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: GlobalStyles.primaryColor.withAlpha(25),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Damage info
          Row(
            children: [
              Text(
                "Damage ${index + 1}",
                style: GoogleFonts.inter(
                  color: GlobalStyles.secondaryColor,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Part and damage type info
          _buildDamageInfo(damagedPart, damageType),
          SizedBox(height: 7.h),

          // Repair/Replace options
          Row(
            children: [
              Expanded(
                child: _buildOptionButton(
                  'Repair',
                  Icons.build,
                  selectedOption == 'repair',
                  () {
                    setState(() {
                      _selectedRepairOptions[index] = 'repair';
                    });
                    // Always fetch pricing when user explicitly chooses the option
                    if (damagedPart != 'Unknown Part') {
                      _fetchPricingForDamage(index, damagedPart, 'repair');
                    } else {
                      _calculateEstimatedDamageCost();
                    }
                  },
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildOptionButton(
                  'Replace',
                  Icons.autorenew,
                  selectedOption == 'replace',
                  () {
                    setState(() {
                      _selectedRepairOptions[index] = 'replace';
                    });
                    // Always fetch pricing when user explicitly chooses the option
                    if (damagedPart != 'Unknown Part') {
                      _fetchPricingForDamage(index, damagedPart, 'replace');
                    } else {
                      _calculateEstimatedDamageCost();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDamageInfo(String damagedPart, String damageType) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.directions_car_filled_rounded,
                color: Colors.blue,
                size: 16.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Damaged Part: ',
                style: GoogleFonts.inter(
                  color: const Color(0x992A2A2A),
                  fontSize: 14.sp,
                ),
              ),
              Expanded(
                child: Text(
                  _formatLabel(damagedPart),
                  style: GoogleFonts.inter(
                    color: const Color(0xFF2A2A2A),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(
                Icons.build_circle_rounded,
                color: Colors.orange,
                size: 16.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Damage Type: ',
                style: GoogleFonts.inter(
                  color: const Color(0x992A2A2A),
                  fontSize: 14.sp,
                ),
              ),
              Expanded(
                child: Text(
                  _formatLabel(damageType),
                  style: GoogleFonts.inter(
                    color: const Color(0xFF2A2A2A),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.green.withAlpha(38),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.green, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.green,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              title,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.green,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
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
          'Assessment photos are already included. You can add more damage photos if needed.',
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
              child:
                  _isUploading
                      ? SizedBox(
                        height: 20.h,
                        width: 20.w,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Text(
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

  void _onSubmitPressed() {
    final requiredDocsUploaded = _checkRequiredDocuments();
    final vehicleInfoFilled = _checkVehicleInformation();
    final incidentInfoFilled = _checkIncidentInformation();
    final isFormValid =
        requiredDocsUploaded && vehicleInfoFilled && incidentInfoFilled;

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

    if (!vehicleInfoFilled) {
      messages.add(
        'Please complete vehicle information (make, model, year, plate)',
      );
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

  bool _checkVehicleInformation() {
    return _vehicleMakeController.text.trim().isNotEmpty &&
        _vehicleModelController.text.trim().isNotEmpty &&
        _vehicleYearController.text.trim().isNotEmpty &&
        _plateNumberController.text.trim().isNotEmpty;
  }

  bool _checkIncidentInformation() {
    return _incidentLocationController.text.trim().isNotEmpty &&
        _incidentDateController.text.trim().isNotEmpty;
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

      // Build enhanced incident description with vehicle info and repair options
      List<String> descriptionParts = [];

      // Add vehicle information
      descriptionParts.add(
        'Vehicle: ${_vehicleMakeController.text.trim()} ${_vehicleModelController.text.trim()} (${_vehicleYearController.text.trim()}) - Plate: ${_plateNumberController.text.trim()}',
      );

      // Try to extract meaningful data from API responses
      if (widget.apiResponses.isNotEmpty) {
        final firstResponse = widget.apiResponses.values.first;

        // Extract damage information for incident description
        if (firstResponse['damaged_areas'] != null) {
          final damagedAreas = firstResponse['damaged_areas'] as List;
          descriptionParts.add(
            'Detected damage areas: ${damagedAreas.map((area) => area['name'] ?? area.toString()).join(', ')}',
          );
        }

        // Add repair options if available
        if (_selectedRepairOptions.isNotEmpty) {
          List<String> repairChoices = [];
          _selectedRepairOptions.forEach((index, option) {
            repairChoices.add('Damage ${index + 1}: $option');
          });
          descriptionParts.add(
            'Repair preferences: ${repairChoices.join(', ')}',
          );
        }

        // Extract cost estimation
        if (firstResponse['total_cost'] != null) {
          estimatedCost = (firstResponse['total_cost'] as num).toDouble();
        }
      }

      incidentDescription = descriptionParts.join('. ');

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
            final repairData = _repairPricingData[i];
            final replaceData = _replacePricingData[i];

            double? repairInsurance =
                repairData != null
                    ? (repairData['insurance'] as num?)?.toDouble()
                    : null;
            double? replaceInsurance =
                replaceData != null
                    ? (replaceData['srp_insurance'] as num?)?.toDouble()
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

        final repairData = _repairPricingData[globalIndex];
        final replaceData = _replacePricingData[globalIndex];

        double? repairInsurance =
            repairData != null
                ? (repairData['insurance'] as num?)?.toDouble()
                : null;
        double? replaceInsurance =
            replaceData != null
                ? (replaceData['srp_insurance'] as num?)?.toDouble()
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
      debugPrint('Vehicle Make: "${_vehicleMakeController.text.trim()}"');
      debugPrint('Vehicle Model: "${_vehicleModelController.text.trim()}"');
      debugPrint('Vehicle Year: "${_vehicleYearController.text.trim()}"');
      debugPrint('Plate Number: "${_plateNumberController.text.trim()}"');
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
        vehicleMake:
            _vehicleMakeController.text.trim().isNotEmpty
                ? _vehicleMakeController.text.trim()
                : null,
        vehicleModel:
            _vehicleModelController.text.trim().isNotEmpty
                ? _vehicleModelController.text.trim()
                : null,
        vehicleYear:
            _vehicleYearController.text.trim().isNotEmpty
                ? int.tryParse(_vehicleYearController.text.trim())
                : null,
        vehiclePlateNumber:
            _plateNumberController.text.trim().isNotEmpty
                ? _plateNumberController.text.trim()
                : null,
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
        _showErrorMessage('Failed to create claim. Please try again.');
        return;
      }

      debugPrint('Starting document upload for claim: ${claim.id}');
      bool allUploadsSuccessful = true;
      int totalUploaded = 0;

      for (String docTypeKey in uploadedDocuments.keys) {
        final files = uploadedDocuments[docTypeKey] ?? [];
        if (files.isNotEmpty) {
          debugPrint(
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
                claimId: claim.id, // Using claim ID for documents table
                description:
                    'Document uploaded for insurance claim ${claim.claimNumber}',
                isRequired: docType.isRequired,
              );

              if (uploadedDocument != null) {
                debugPrint(
                  'Successfully uploaded: ${uploadedDocument.fileName}',
                );
                totalUploaded++;
              } else {
                debugPrint('Failed to upload file: ${file.path}');
                allUploadsSuccessful = false;
              }
            } catch (e) {
              debugPrint('Error uploading file ${file.path}: $e');
              allUploadsSuccessful = false;
            }
          }
        }
      }

      debugPrint('Total files uploaded: $totalUploaded');

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
      debugPrint('Error submitting claim: $e');
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
                  style: GoogleFonts.inter(
                    color: Colors.white,
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
                    color: Colors.white70,
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
                          style: GoogleFonts.inter(
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
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 12.sp,
                  ),
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
