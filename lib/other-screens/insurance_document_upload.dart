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
                    _buildVehicleInformationSection(),
                    SizedBox(height: 24.h),
                    _buildIncidentInformationSection(),
                    SizedBox(height: 24.h),
                    _buildDamageAssessmentImagesSection(),
                    SizedBox(height: 24.h),
                    _buildRepairOptionsSection(),
                    SizedBox(height: 24.h),
                    _buildEstimatedCostSection(),
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

  Widget _buildVehicleInformationSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.directions_car,
                color: GlobalStyles.primaryColor,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Vehicle Information',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                ' *',
                style: TextStyle(
                  fontSize: 18.sp,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'Please provide your vehicle details for the insurance claim.',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          SizedBox(height: 20.h),

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
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(
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
          style: TextStyle(color: Colors.white, fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white54, fontSize: 14.sp),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(
                color: GlobalStyles.primaryColor,
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
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: GlobalStyles.primaryColor,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Incident Information',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                ' *',
                style: TextStyle(
                  fontSize: 18.sp,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'Please provide details about when and where the incident occurred.',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          SizedBox(height: 20.h),

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
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(
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
          style: TextStyle(color: Colors.white, fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white54, fontSize: 14.sp),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(
                color: GlobalStyles.primaryColor,
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
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(
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
          style: TextStyle(color: Colors.white, fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: 'Select incident date',
            hintStyle: TextStyle(color: Colors.white54, fontSize: 14.sp),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(
                color: GlobalStyles.primaryColor,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 12.h,
            ),
            suffixIcon: Icon(Icons.calendar_today, color: Colors.white54),
          ),
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now().subtract(Duration(days: 365)),
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
                Icons.monetization_on,
                color: GlobalStyles.primaryColor,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Estimated Damage Cost',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'This is the estimated cost based on the damage assessment from your photos.',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          SizedBox(height: 20.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  GlobalStyles.primaryColor.withValues(alpha: 0.2),
                  GlobalStyles.secondaryColor.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: GlobalStyles.primaryColor.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Total Estimated Cost',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8.h),
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
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: GlobalStyles.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    _estimatedDamageCost > 0
                        ? '₱${_estimatedDamageCost.toStringAsFixed(2)}'
                        : '₱0.00',
                    style: TextStyle(
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
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white54,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
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
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.assessment,
                color: GlobalStyles.primaryColor,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Damage Assessment Images',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '${widget.imagePaths.length}',
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
          Text(
            'These are the images you took for damage assessment. They have been automatically included as damage proof for your claim.',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white70,
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
      physics: NeverScrollableScrollPhysics(),
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
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
          width: 2,
        ),
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
                          style: TextStyle(
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
                  style: TextStyle(
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
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
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

    if (damagesList.isEmpty) {
      return Container();
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.build, color: GlobalStyles.primaryColor, size: 24.sp),
              SizedBox(width: 12.w),
              Text(
                'Repair Options',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'Please select your preferred option for each damaged part.',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          SizedBox(height: 20.h),

          // Display damage options
          for (int index = 0; index < damagesList.length; index++)
            _buildDamageRepairOption(index, damagesList[index]),
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
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Damage info
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: Colors.green, size: 12.sp),
              ),
              SizedBox(width: 8.w),
              Text(
                "DAMAGE ${index + 1}",
                style: TextStyle(
                  color: GlobalStyles.secondaryColor,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Part and damage type info
          _buildDamageInfo(damagedPart, damageType),
          SizedBox(height: 16.h),

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
                    // Fetch pricing data if not already loaded
                    if (!_repairPricingData.containsKey(index) &&
                        damagedPart != 'Unknown Part') {
                      _fetchPricingForDamage(index, damagedPart, 'repair');
                    } else {
                      // Recalculate cost with existing data
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
                    // Fetch pricing data if not already loaded
                    if (!_replacePricingData.containsKey(index) &&
                        damagedPart != 'Unknown Part') {
                      _fetchPricingForDamage(index, damagedPart, 'replace');
                    } else {
                      // Recalculate cost with existing data
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
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_car, color: Colors.blue, size: 16.sp),
              SizedBox(width: 8.w),
              Text(
                'Damaged Part: ',
                style: TextStyle(color: Colors.white70, fontSize: 14.sp),
              ),
              Expanded(
                child: Text(
                  damagedPart,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.build, color: Colors.orange, size: 16.sp),
              SizedBox(width: 8.w),
              Text(
                'Damage Type: ',
                style: TextStyle(color: Colors.white70, fontSize: 14.sp),
              ),
              Expanded(
                child: Text(
                  damageType,
                  style: TextStyle(
                    color: Colors.white,
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
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? GlobalStyles.primaryColor.withValues(alpha: 0.2)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color:
                isSelected
                    ? GlobalStyles.primaryColor
                    : Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? GlobalStyles.primaryColor : Colors.white70,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? GlobalStyles.primaryColor : Colors.white70,
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
          'Assessment photos are already included. You can add more damage photos if needed.',
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

    // Check if this is an assessment image
    final isAssessmentImage =
        category == 'damage_photos' && widget.imagePaths.contains(file.path);

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color:
            isAssessmentImage
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6.r),
        border:
            isAssessmentImage
                ? Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                  width: 1,
                )
                : null,
      ),
      child: Row(
        children: [
          Icon(
            isImage ? Icons.image : Icons.description,
            color: isAssessmentImage ? Colors.green : Colors.white70,
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
                    color: isAssessmentImage ? Colors.green : Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (isAssessmentImage) ...[
                  SizedBox(height: 2.h),
                  Text(
                    'Assessment Image',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.green.withValues(alpha: 0.8),
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
                color: Colors.green,
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                'PROOF',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
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
    final vehicleInfoFilled = _checkVehicleInformation();
    final incidentInfoFilled = _checkIncidentInformation();
    final isFormValid =
        requiredDocsUploaded && vehicleInfoFilled && incidentInfoFilled;
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
                isFormValid
                    ? 'Ready to submit'
                    : !requiredDocsUploaded
                    ? 'Missing required docs'
                    : !vehicleInfoFilled
                    ? 'Missing vehicle info'
                    : !incidentInfoFilled
                    ? 'Missing incident info'
                    : 'Form incomplete',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isFormValid ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isFormValid ? _submitClaim : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isFormValid ? GlobalStyles.primaryColor : Colors.grey,
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
      DateTime incidentDate = DateTime.now().subtract(Duration(days: 1));
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
        print('Error parsing incident date: $e');
      }

      // Use estimated damage cost from calculation, or from API if available
      double finalEstimatedCost =
          _estimatedDamageCost > 0
              ? _estimatedDamageCost
              : (estimatedCost ?? 0.0);

      // Debug: Print vehicle information being sent
      print('=== VEHICLE DATA DEBUG ===');
      print('Vehicle Make: "${_vehicleMakeController.text.trim()}"');
      print('Vehicle Model: "${_vehicleModelController.text.trim()}"');
      print('Vehicle Year: "${_vehicleYearController.text.trim()}"');
      print('Plate Number: "${_plateNumberController.text.trim()}"');
      print('========================');

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
      );

      // Debug: Print claim result
      if (claim != null) {
        print('=== CLAIM CREATED ===');
        print('Claim ID: ${claim.id}');
        print('Vehicle Make in claim: ${claim.vehicleMake}');
        print('Vehicle Model in claim: ${claim.vehicleModel}');
        print('Vehicle Year in claim: ${claim.vehicleYear}');
        print('Plate Number in claim: ${claim.vehiclePlateNumber}');
        print('==================');
      }

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
                claimId: claim.id, // Using claim ID for documents table
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
