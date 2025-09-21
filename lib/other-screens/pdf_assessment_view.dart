import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/utils/pdf_service.dart';
import 'package:insurevis/services/pricing_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:insurevis/utils/file_writer.dart';

class PDFAssessmentView extends StatefulWidget {
  final List<String> imagePaths;
  final Map<String, Map<String, dynamic>> apiResponses;
  final Map<String, String> assessmentIds;

  const PDFAssessmentView({
    super.key,
    required this.imagePaths,
    required this.apiResponses,
    required this.assessmentIds,
  });

  @override
  State<PDFAssessmentView> createState() => _PDFAssessmentViewState();
}

class _PDFAssessmentViewState extends State<PDFAssessmentView> {
  bool _isSaving = false;

  // Repair/Replace options for each damage
  final Map<int, String> _selectedRepairOptions = {};

  // Pricing data for repair/replace options
  final Map<int, Map<String, dynamic>?> _repairPricingData = {};
  final Map<int, Map<String, dynamic>?> _replacePricingData = {};
  final Map<int, bool> _isLoadingPricing = {};

  // Estimated damage cost
  double _estimatedDamageCost = 0.0;

  // Helper getter to check for severe damage
  bool get _isDamageSevere {
    return widget.apiResponses.values.any((response) {
      final severity = response['overall_severity']?.toString().toLowerCase();
      return severity == 'severe';
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeRepairOptions();
  }

  /// Initialize repair options for all detected damages
  void _initializeRepairOptions() {
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

    // Initialize selected repair options to 'repair' by default
    for (int i = 0; i < damagesList.length; i++) {
      if (!_selectedRepairOptions.containsKey(i)) {
        setState(() {
          _selectedRepairOptions[i] = 'repair';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalStyles.backgroundColorStart,
      appBar: AppBar(
        backgroundColor: GlobalStyles.backgroundColorStart,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Assessment Report',
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
        child: _buildAssessmentContent(),
      ),
    );
  }

  Widget _buildAssessmentContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeaderSection(),
          SizedBox(height: 24.h),

          // Summary
          _buildSummarySection(),
          SizedBox(height: 24.h),

          // Individual Results
          _buildIndividualResults(),
          SizedBox(height: 24.h),

          // Conditionally build the entire repair options section
          if (!_isDamageSevere) ...[
            _buildRepairOptionsSection(),
            SizedBox(height: 24.h),
          ],

          // Save PDF Button
          _buildSavePDFButton(),
          SizedBox(height: 24.h),

          // Overall Assessment
          _buildOverallAssessment(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(51),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.assignment,
                color: GlobalStyles.primaryColor,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Vehicle Damage Assessment Report',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Generated on: ${DateTime.now().toString().substring(0, 19)}',
            style: TextStyle(fontSize: 14.sp, color: Colors.white70),
          ),
          Text(
            'Total Images Analyzed: ${widget.imagePaths.length}',
            style: TextStyle(fontSize: 14.sp, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    // Calculate summary data
    int totalDamages = 0;
    double totalCost = 0.0;
    Map<String, int> severityCount = {'High': 0, 'Medium': 0, 'Low': 0};

    widget.apiResponses.forEach((imagePath, response) {
      if (response.containsKey('damages') && response['damages'] is List) {
        totalDamages += (response['damages'] as List).length;
      }
      if (response.containsKey('total_cost')) {
        try {
          totalCost += double.parse(response['total_cost'].toString());
        } catch (e) {
          // Handle parsing error
        }
      }
      if (response.containsKey('overall_severity')) {
        String severity = response['overall_severity'].toString();
        if (severity.toLowerCase().contains('high') ||
            severity.toLowerCase().contains('severe')) {
          severityCount['High'] = (severityCount['High'] ?? 0) + 1;
        } else if (severity.toLowerCase().contains('medium')) {
          severityCount['Medium'] = (severityCount['Medium'] ?? 0) + 1;
        } else {
          severityCount['Low'] = (severityCount['Low'] ?? 0) + 1;
        }
      }
    });

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(51),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: GlobalStyles.primaryColor,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Damages',
                  totalDamages.toString(),
                  Icons.warning,
                  Colors.red,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildSummaryCard(
                  'Estimated Cost',
                  _isDamageSevere
                      ? 'To be given by the mechanic'
                      : '₱${totalCost.toStringAsFixed(2)}',
                  Icons.attach_money,
                  _isDamageSevere ? Colors.orange : Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'High Severity',
                  severityCount['High'].toString(),
                  Icons.priority_high,
                  Colors.red,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildSummaryCard(
                  'Images Analyzed',
                  widget.imagePaths.length.toString(),
                  Icons.image,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Individual Image Results',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: GlobalStyles.primaryColor,
          ),
        ),
        SizedBox(height: 16.h),
        ...widget.imagePaths.asMap().entries.map((entry) {
          final index = entry.key;
          final imagePath = entry.value;
          final response = widget.apiResponses[imagePath];
          return _buildImageResultCard(index + 1, imagePath, response);
        }).toList(),
      ],
    );
  }

  Widget _buildImageResultCard(
    int imageNumber,
    String imagePath,
    Map<String, dynamic>? response,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(51),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Image thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: SizedBox(
                  width: 60.w,
                  height: 60.w,
                  child: Image.file(File(imagePath), fit: BoxFit.cover),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Image $imageNumber',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (response != null) ...[
                      SizedBox(height: 4.h),
                      if (response.containsKey('overall_severity'))
                        Text(
                          'Severity: ${response['overall_severity']}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: _getSeverityColor(
                              response['overall_severity'].toString(),
                            ),
                          ),
                        ),
                      if (response.containsKey('total_cost'))
                        Text(
                          _isDamageSevere
                              ? 'Cost: To be given by the mechanic'
                              : 'Cost: ₱${response['total_cost']}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color:
                                _isDamageSevere ? Colors.orange : Colors.green,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (!_isDamageSevere &&
              response != null &&
              response.containsKey('damages')) ...[
            SizedBox(height: 12.h),
            Text(
              'Detected Damages:',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8.h),
            ..._buildDamagesList(response['damages']),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildDamagesList(dynamic damages) {
    if (damages is! List) return [];

    return damages.take(3).map<Widget>((damage) {
      String damageText = '';
      if (damage is Map) {
        String part =
            damage['damaged_part']?.toString() ??
            damage['part_name']?.toString() ??
            'Unknown part';
        String type = '';
        if (damage['damage_type'] is Map) {
          type =
              damage['damage_type']['class_name']?.toString() ?? 'Unknown type';
        } else {
          type = damage['damage_type']?.toString() ?? 'Unknown type';
        }
        damageText = '$part - $type';
      } else {
        damageText = damage.toString();
      }

      return Padding(
        padding: EdgeInsets.only(bottom: 4.h),
        child: Row(
          children: [
            Icon(Icons.fiber_manual_record, color: Colors.orange, size: 8.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                damageText,
                style: TextStyle(fontSize: 12.sp, color: Colors.white70),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildOverallAssessment() {
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
          Text(
            'Overall Assessment',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: GlobalStyles.primaryColor,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'This assessment report contains the analysis of ${widget.imagePaths.length} vehicle images. '
            'The damage detection was performed using AI-powered analysis to identify potential '
            'vehicle damages and provide cost estimates for repair or replacement.',
            style: TextStyle(fontSize: 14.sp, color: Colors.white, height: 1.5),
          ),
          SizedBox(height: 12.h),
          Text(
            'Note: This assessment is for estimation purposes only. Professional inspection '
            'is recommended for final insurance claims and repair decisions.',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
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
        color: Colors.black.withAlpha(51),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withAlpha(51)),
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
            'Select your preferred option for each damaged part to calculate accurate cost estimates.',
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
        color: Colors.black.withAlpha(76),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withAlpha(51)),
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
                  color: Colors.green.withAlpha(51),
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
        color: Colors.black.withAlpha(51),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.white.withAlpha(51)),
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
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? GlobalStyles.primaryColor.withAlpha(51)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color:
                isSelected
                    ? GlobalStyles.primaryColor
                    : Colors.white.withAlpha(76),
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

  Widget _buildSavePDFButton() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: GlobalStyles.primaryColor.withAlpha(25),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: GlobalStyles.primaryColor.withAlpha(76)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.picture_as_pdf,
                color: GlobalStyles.primaryColor,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Save Assessment Report',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Generate a comprehensive PDF report with your selected repair options and cost estimates.',
            style: TextStyle(fontSize: 14.sp, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _savePDF,
              style: ElevatedButton.styleFrom(
                backgroundColor: GlobalStyles.primaryColor,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              icon:
                  _isSaving
                      ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Icon(Icons.save, color: Colors.white),
              label: Text(
                _isSaving ? 'Generating PDF...' : 'Save PDF Report',
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

  Color _getSeverityColor(String severity) {
    final lowerSeverity = severity.toLowerCase();
    if (lowerSeverity.contains('high') || lowerSeverity.contains('severe')) {
      return Colors.red;
    } else if (lowerSeverity.contains('medium') ||
        lowerSeverity.contains('moderate')) {
      return Colors.orange;
    } else if (lowerSeverity.contains('low') ||
        lowerSeverity.contains('minor')) {
      return Colors.green;
    } else {
      return Colors.blue;
    }
  }

  Future<void> _savePDF() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Request storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Storage permission not granted');
      }

      // Prepare responses for PDF generation, modifying cost if severe
      final Map<String, Map<String, dynamic>> pdfResponses = {};
      widget.apiResponses.forEach((key, value) {
        pdfResponses[key] = Map<String, dynamic>.from(value);
      });

      if (_isDamageSevere) {
        pdfResponses.forEach((key, value) {
          value['total_cost'] = 'To be given by the mechanic';
        });
      }

      // Ask user whether to auto-save to InsureVis/documents or choose folder
      final choice = await showDialog<String?>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Save Assessment Report'),
              content: const Text(
                'Where do you want to save the generated PDF?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop('auto'),
                  child: const Text('Save to InsureVis/documents'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop('choose'),
                  child: const Text('Choose folder'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Cancel'),
                ),
              ],
            ),
      );

      if (choice == null) {
        setState(() => _isSaving = false);
        return;
      }

      String? savedPath;

      if (choice == 'auto') {
        // Auto-save via existing helper which creates InsureVis/documents
        savedPath = await PDFService.generateMultipleResultsPDF(
          imagePaths: widget.imagePaths,
          apiResponses: pdfResponses,
        );
      } else if (choice == 'choose') {
        // Generate PDF bytes and ask user for a folder or filepath
        final bytes = await PDFService.generateMultipleResultsPDFBytes(
          imagePaths: widget.imagePaths,
          apiResponses: pdfResponses,
        );

        if (bytes == null) throw Exception('Failed to generate PDF bytes');

        // Try SAF directory picker first (native)
        String? treeUri;
        try {
          treeUri = await FileWriter.pickDirectory();
        } catch (e) {
          treeUri = null;
        }

        if (treeUri != null) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final defaultFileName = 'InsureVis_Assessment_Report_$timestamp.pdf';
          try {
            final newFileUri = await FileWriter.saveFileToTree(
              treeUri,
              defaultFileName,
              bytes,
            );
            savedPath = newFileUri; // content:// URI
          } catch (e) {
            // If tree save failed, fall back to saveFile picker
            savedPath = await PDFService.savePdfBytesWithPicker(
              bytes,
              'InsureVis_Assessment_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
            );
          }
        } else {
          // Fall back to FilePicker.saveFile which may return content:// URI
          savedPath = await PDFService.savePdfBytesWithPicker(
            bytes,
            'InsureVis_Assessment_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
          );
        }
      }

      if (savedPath != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Assessment report saved to: $savedPath'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'Share',
                textColor: Colors.white,
                onPressed: () {
                  _sharePDF(savedPath!);
                },
              ),
            ),
          );
        }
        return;
      } else {
        throw Exception('Failed to generate and save PDF');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _sharePDF(String filePath) async {
    try {
      await Share.shareXFiles([
        XFile(filePath),
      ], text: 'Vehicle Assessment Report');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
