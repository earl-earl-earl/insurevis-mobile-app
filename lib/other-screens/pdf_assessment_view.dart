import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/utils/pdf_service.dart';
import 'package:insurevis/services/prices_repository.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:insurevis/utils/file_writer.dart';

class PDFAssessmentView extends StatefulWidget {
  final List<String>? imagePaths;
  final Map<String, Map<String, dynamic>>? apiResponses;
  final Map<String, String>? assessmentIds;

  const PDFAssessmentView({
    super.key,
    this.imagePaths,
    this.apiResponses,
    this.assessmentIds,
  });

  @override
  State<PDFAssessmentView> createState() => _PDFAssessmentViewState();
}

class _PDFAssessmentViewState extends State<PDFAssessmentView> {
  bool _isSaving = false;
  final Map<int, String?> _selectedRepairOptions = {};
  final Map<int, Map<String, dynamic>?> _repairPricingData = {};
  final Map<int, Map<String, dynamic>?> _replacePricingData = {};
  final Map<int, bool> _isLoadingPricing = {};
  double _estimatedDamageCost = 0.0;
  final List<Map<String, String>> _manualDamages = [];
  bool _showAddDamageForm = false;
  String? _newDamagePart;
  String? _newDamageType;

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

  bool get _isDamageSevere {
    final responses = widget.apiResponses ?? <String, Map<String, dynamic>>{};
    return responses.values.any((response) {
      final severity = response['overall_severity']?.toString().toLowerCase();
      return severity == 'severe';
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeRepairOptions();
    _calculateEstimatedDamageCost();
  }

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
  );

  String _formatCurrency(double amount) {
    try {
      if (amount == 0.0) return 'N/A';
      return _currencyFormatter.format(amount);
    } catch (e) {
      if (amount == 0.0) return 'N/A';
      return '₱${amount.toStringAsFixed(2)}';
    }
  }

  void _initializeRepairOptions() {
    List<Map<String, dynamic>> damagesList = [];
    final apiResponses =
        widget.apiResponses ?? <String, Map<String, dynamic>>{};
    if (apiResponses.isNotEmpty) {
      for (var response in apiResponses.values) {
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
    // If there are API-detected damages, default each to 'repair' and
    // start fetching pricing so totals reflect user choices on load.
    for (var entry in damagesList.asMap().entries) {
      final idx = entry.key;
      final dmg = entry.value;
      String damagedPart = 'Unknown Part';
      if (dmg.containsKey('damaged_part')) {
        damagedPart = dmg['damaged_part']?.toString() ?? 'Unknown Part';
      } else if (dmg.containsKey('part_name')) {
        damagedPart = dmg['part_name']?.toString() ?? 'Unknown Part';
      } else if (dmg.containsKey('label')) {
        damagedPart = dmg['label']?.toString() ?? 'Unknown Part';
      }

      // mark selected option as 'repair' (use API damage index)
      _selectedRepairOptions[idx] = 'repair';

      // trigger pricing fetch (async) for this damage; don't await here
      _fetchPricingForDamage(idx, damagedPart, 'repair');
    }
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
          'Assessment Report',
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2A2A2A),
          ),
        ),
      ),
      body: SizedBox(height: double.infinity, child: _buildAssessmentContent()),
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.all(12.w),
        child: SizedBox(
          height: 60.h,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _savePDF,
            style: ElevatedButton.styleFrom(
              backgroundColor: GlobalStyles.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              padding: EdgeInsets.symmetric(vertical: 12.h),
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
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssessmentContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderSection(),
          SizedBox(height: 24.h),
          _buildSummarySection(),
          SizedBox(height: 24.h),
          _buildIndividualResults(),
          SizedBox(height: 24.h),
          if (!_isDamageSevere) ...[
            _buildRepairOptionsSection(),
            SizedBox(height: 24.h),
          ],
          _buildOverallAssessment(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Vehicle Damage Assessment Report',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2A2A2A),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Generated on: ${DateTime.now().toString().substring(0, 19)}',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: Color(0x992A2A2A),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Total Images Analyzed: ${(widget.imagePaths ?? const <String>[]).length}',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: Color(0x992A2A2A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    int totalDamages = 0;
    double totalCost = 0.0;
    Map<String, int> severityCount = {'High': 0, 'Medium': 0, 'Low': 0};
    final apiResponsesForSummary =
        widget.apiResponses ?? <String, Map<String, dynamic>>{};
    apiResponsesForSummary.forEach((imagePath, response) {
      if (response.containsKey('damages') && response['damages'] is List) {
        totalDamages += (response['damages'] as List).length;
      }
      if (response.containsKey('total_cost')) {
        try {
          totalCost += double.parse(response['total_cost'].toString());
        } catch (e) {}
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
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: GoogleFonts.inter(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2A2A2A),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Estimated Cost',
                  _isDamageSevere
                      ? 'To be given by the mechanic'
                      : (_estimatedDamageCost > 0
                          ? _formatCurrency(_estimatedDamageCost)
                          : _formatCurrency(totalCost)),
                  Icons.money_rounded,
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
                  'Total Damages',
                  totalDamages.toString(),
                  Icons.warning,
                  Colors.red,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildSummaryCard(
                  'Images Analyzed',
                  (widget.imagePaths ?? const <String>[]).length.toString(),
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
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: color.withValues(alpha: 0.5),
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualResults() {
    final images = widget.imagePaths ?? const <String>[];
    if (images.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Individual Image Results',
          style: GoogleFonts.inter(
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2A2A2A),
          ),
        ),
        SizedBox(height: 16.h),
        ...images.asMap().entries.map((entry) {
          final index = entry.key;
          final imagePath = entry.value;
          final response =
              (widget.apiResponses ??
                  <String, Map<String, dynamic>>{})[imagePath];
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
        borderRadius: BorderRadius.circular(12.r),
        color: GlobalStyles.primaryColor.withValues(alpha: 0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2A2A2A),
                      ),
                    ),
                    if (response != null) ...[
                      SizedBox(height: 4.h),
                      if (response.containsKey('overall_severity'))
                        Text(
                          'Severity: ${response['overall_severity']}',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: _getSeverityColor(
                              response['overall_severity'].toString(),
                            ),
                          ),
                        ),
                      if (response.containsKey('total_cost'))
                        Text(
                          _isDamageSevere
                              ? 'Cost: To be given by the mechanic'
                              : 'Cost: ${_formatCurrency(_parseToDouble(response['total_cost']))}',
                          style: GoogleFonts.inter(
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
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2A2A2A),
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
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Color(0x992A2A2A),
                ),
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
        color: GlobalStyles.primaryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: GlobalStyles.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overall Assessment',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: GlobalStyles.primaryColor,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'This assessment report contains the analysis of ${(widget.imagePaths ?? const <String>[]).length} vehicle images. '
            'The damage detection was performed using AI-powered analysis to identify potential '
            'vehicle damages and provide cost estimates for repair or replacement.',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: Color(0xFF2A2A2A),
              height: 1.5,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Note: This assessment is for estimation purposes only. Professional inspection '
            'is recommended for final insurance claims and repair decisions.',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: Color(0x992A2A2A),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepairOptionsSection() {
    List<Map<String, dynamic>> damagesList = [];
    final apiResponses =
        widget.apiResponses ?? <String, Map<String, dynamic>>{};
    if (apiResponses.isNotEmpty) {
      for (var response in apiResponses.values) {
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
      return Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.r)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Repair Options (Manual)',
                  style: GoogleFonts.inter(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A2A2A),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              'No AI-detected damages found. Add manual damages below to estimate costs.',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: Color(0x992A2A2A),
              ),
            ),
            SizedBox(height: 12.h),
            if (!_showAddDamageForm)
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _showAddDamageForm = true),
                  icon: Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                  label: Text(
                    'Add Damage',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlobalStyles.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
            if (_showAddDamageForm) _buildAddDamageForm(),
            // Render manual damages (use negative global indices so they don't clash
            // with API damage indices which are >= 0)
            ..._manualDamages.asMap().entries.map((e) {
              final displayedIndex = e.key;
              final globalIndex = -(displayedIndex + 1);
              return _buildManualDamageRepairOption(globalIndex, e.value);
            }).toList(),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Repair Options',
                style: GoogleFonts.inter(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2A2A2A),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'Select your preferred option for each damaged part to calculate accurate cost estimates.',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: Color(0x992A2A2A),
              height: 1.5,
            ),
          ),
          SizedBox(height: 20.h),
          for (int index = 0; index < damagesList.length; index++)
            _buildDamageRepairOption(index, damagesList[index]),
          SizedBox(height: 16.h),
          // Always show manual repair options below detected damages so users can
          // add or remove manual damages in addition to AI-detected ones.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Manual Damages',
                style: GoogleFonts.inter(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2A2A2A),
                ),
              ),
              SizedBox(height: 20.h),

              if (!_showAddDamageForm)
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _showAddDamageForm = true),
                    icon: Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                    label: Text(
                      'Add',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlobalStyles.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          if (_showAddDamageForm) _buildAddDamageForm(),
          // Render manual damages with negative indices
          ..._manualDamages.asMap().entries.map((e) {
            final displayedIndex = e.key;
            final globalIndex = -(displayedIndex + 1);
            return _buildManualDamageRepairOption(globalIndex, e.value);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDamageRepairOption(int index, Map<String, dynamic> damage) {
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
    String? selectedOption = _selectedRepairOptions[index];

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          SizedBox(height: 12.h),
          _buildDamageInfo(damagedPart, damageType),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildOptionButton(
                  'Repair',
                  Icons.build,
                  selectedOption == 'repair',
                  () {
                    setState(() => _selectedRepairOptions[index] = 'repair');
                    if (!_repairPricingData.containsKey(index) &&
                        damagedPart != 'Unknown Part') {
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
                    setState(() => _selectedRepairOptions[index] = 'replace');
                    if (!_replacePricingData.containsKey(index) &&
                        damagedPart != 'Unknown Part') {
                      _fetchPricingForDamage(index, damagedPart, 'replace');
                    } else {
                      _calculateEstimatedDamageCost();
                    }
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            margin: EdgeInsets.only(bottom: 20.h),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.r)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Estimated Total',
                  style: GoogleFonts.inter(
                    color: Color(0x992A2A2A),
                    fontSize: 14.sp,
                  ),
                ),
                Builder(
                  builder: (context) {
                    final isLoading = _isLoadingPricing[index] ?? false;
                    final repairData = _repairPricingData[index];
                    final replaceData = _replacePricingData[index];
                    if (isLoading) {
                      return Row(
                        children: [
                          SizedBox(
                            width: 16.w,
                            height: 16.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: GlobalStyles.primaryColor,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Loading...',
                            style: GoogleFonts.inter(color: Color(0x992A2A2A)),
                          ),
                        ],
                      );
                    }
                    if (selectedOption == 'repair') {
                      double thinsmith =
                          (repairData?['insurance'] as num?)?.toDouble() ?? 0.0;
                      double bodyPaint =
                          (replaceData?['srp_insurance'] as num?)?.toDouble() ??
                          0.0;
                      if (thinsmith == 0.0 && bodyPaint == 0.0) {
                        return Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.orange,
                              size: 18,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Price unavailable',
                              style: GoogleFonts.inter(
                                color: Colors.orange,
                                fontSize: 13.sp,
                              ),
                            ),
                          ],
                        );
                      }
                      final total = thinsmith + bodyPaint;
                      return Text(
                        _formatCurrency(total),
                        style: GoogleFonts.inter(
                          color: Color(0xFF2A2A2A),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                    if (selectedOption == 'replace') {
                      double replacePrice =
                          (replaceData?['srp_insurance'] as num?)?.toDouble() ??
                          0.0;
                      if (replacePrice == 0.0) {
                        return Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.orange,
                              size: 18,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Price unavailable',
                              style: GoogleFonts.inter(
                                color: Colors.orange,
                                fontSize: 13.sp,
                              ),
                            ),
                          ],
                        );
                      }
                      return Text(
                        _formatCurrency(replacePrice),
                        style: GoogleFonts.inter(
                          color: Color(0xFF2A2A2A),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                    return Text(
                      '—',
                      style: GoogleFonts.inter(color: Color(0x992A2A2A)),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDamageInfo(String damagedPart, String damageType) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: GlobalStyles.primaryColor.withValues(alpha: 0.15),
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
                style: GoogleFonts.inter(
                  color: Color(0x992A2A2A),
                  fontSize: 14.sp,
                ),
              ),
              Expanded(
                child: Text(
                  damagedPart,
                  style: GoogleFonts.inter(
                    color: Color(0xFF2A2A2A),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (damageType.trim().isNotEmpty) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.build, color: Colors.orange, size: 16.sp),
                SizedBox(width: 8.w),
                Text(
                  'Damage Type: ',
                  style: GoogleFonts.inter(
                    color: Color(0x992A2A2A),
                    fontSize: 14.sp,
                  ),
                ),
                Expanded(
                  child: Text(
                    damageType,
                    style: GoogleFonts.inter(
                      color: Color(0xFF2A2A2A),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddDamageForm() {
    return Container(
      margin: EdgeInsets.only(top: 12.h, bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Damage',
            style: GoogleFonts.inter(
              color: Color(0xFF2A2A2A),
              fontWeight: FontWeight.bold,
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
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      (_newDamagePart == null)
                          ? null
                          : () {
                            final map = {
                              'damaged_part': _newDamagePart!,
                              'damage_type': '',
                            };
                            setState(() {
                              _manualDamages.add(map);
                              final newIndex = _manualDamages.length - 1;
                              final globalIndex = -(newIndex + 1);
                              // default manual damage to 'repair' so it contributes to totals
                              _selectedRepairOptions[globalIndex] = 'repair';
                              _fetchPricingForDamage(
                                globalIndex,
                                _newDamagePart!,
                                'repair',
                              );
                              _showAddDamageForm = false;
                              _newDamagePart = null;
                              _newDamageType = null;
                            });
                          },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateColor.resolveWith((states) {
                      if (states.contains(WidgetState.disabled)) {
                        return Colors.grey;
                      }
                      return GlobalStyles.primaryColor;
                    }),
                    foregroundColor: WidgetStateProperty.all<Color>(
                      Colors.white,
                    ),
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                  child: Text(
                    'Add',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      () => setState(() {
                        _showAddDamageForm = false;
                        _newDamagePart = null;
                        _newDamageType = null;
                      }),
                  style: ButtonStyle(
                    shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    side: WidgetStatePropertyAll<BorderSide>(BorderSide.none),
                    backgroundColor: WidgetStatePropertyAll<Color>(
                      GlobalStyles.primaryColor.withValues(alpha: 0.15),
                    ),
                    foregroundColor: WidgetStatePropertyAll<Color>(
                      GlobalStyles.primaryColor,
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      color: GlobalStyles.primaryColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
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

  Widget _buildManualDamageRepairOption(
    int globalIndex,
    Map<String, String> damage,
  ) {
    final damagedPart = damage['damaged_part'] ?? 'Unknown Part';
    final damageType = damage['damage_type'] ?? 'Unknown Damage';
    String? selectedOption = _selectedRepairOptions[globalIndex];

    return Container(
      margin: EdgeInsets.symmetric(vertical: 16.h),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Manual Damage',
                style: GoogleFonts.inter(
                  color: GlobalStyles.secondaryColor,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              // Remove (minus) icon for manual damage
              IconButton(
                onPressed: () {
                  // Convert negative globalIndex back to displayed index in _manualDamages
                  final displayedIndex = -(globalIndex) - 1;
                  if (displayedIndex >= 0 &&
                      displayedIndex < _manualDamages.length) {
                    setState(() {
                      // remove manual damage
                      _manualDamages.removeAt(displayedIndex);

                      // Clear any existing manual-related state (negative keys)
                      _selectedRepairOptions.keys
                          .where((k) => k < 0)
                          .toList()
                          .forEach(_selectedRepairOptions.remove);
                      _repairPricingData.keys
                          .where((k) => k < 0)
                          .toList()
                          .forEach(_repairPricingData.remove);
                      _replacePricingData.keys
                          .where((k) => k < 0)
                          .toList()
                          .forEach(_replacePricingData.remove);
                      _isLoadingPricing.keys
                          .where((k) => k < 0)
                          .toList()
                          .forEach(_isLoadingPricing.remove);

                      // Re-initialize remaining manual damages: default to 'repair' and fetch pricing
                      for (var entry in _manualDamages.asMap().entries) {
                        final newDisplayed = entry.key;
                        final newGlobal = -(newDisplayed + 1);
                        // set default selection if not present
                        _selectedRepairOptions[newGlobal] =
                            _selectedRepairOptions[newGlobal] ?? 'repair';
                        // fetch pricing for remaining manual damages
                        _fetchPricingForDamage(
                          newGlobal,
                          entry.value['damaged_part'] ?? '',
                          'repair',
                        );
                      }

                      // ensure totals update (will also be updated when async pricing returns)
                      _calculateEstimatedDamageCost();
                    });
                  }
                },
                icon: Icon(
                  Icons.remove_circle_outline,
                  color: Colors.red,
                  size: 20.sp,
                ),
                tooltip: 'Remove manual damage',
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildDamageInfo(damagedPart, damageType),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.r)),
            child: Builder(
              builder: (context) {
                final isLoading = _isLoadingPricing[globalIndex] ?? false;
                final repairData = _repairPricingData[globalIndex];
                final replaceData = _replacePricingData[globalIndex];
                if (isLoading) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Estimated Total',
                        style: GoogleFonts.inter(
                          color: Color(0x992A2A2A),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
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
                            'Loading...',
                            style: GoogleFonts.inter(color: Color(0x992A2A2A)),
                          ),
                        ],
                      ),
                    ],
                  );
                }
                double repairCost =
                    (repairData?['insurance'] as num?)?.toDouble() ?? 0.0;
                double repairAdd =
                    (replaceData?['srp_insurance'] as num?)?.toDouble() ?? 0.0;
                double totalRepair = repairCost + repairAdd;
                double replacePrice =
                    (replaceData?['srp_insurance'] as num?)?.toDouble() ?? 0.0;
                if (selectedOption == 'repair') {
                  if (totalRepair == 0.0) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Estimated Total',
                          style: GoogleFonts.inter(color: Color(0x992A2A2A)),
                        ),
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange),
                            SizedBox(width: 8.w),
                            Text(
                              'Price unavailable',
                              style: GoogleFonts.inter(
                                color: Colors.orange,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Estimated Total',
                        style: GoogleFonts.inter(color: Color(0x992A2A2A)),
                      ),
                      Text(
                        _formatCurrency(totalRepair),
                        style: GoogleFonts.inter(
                          color: Color(0xFF2A2A2A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                }
                if (selectedOption == 'replace') {
                  if (replacePrice == 0.0) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Estimated Total',
                          style: GoogleFonts.inter(color: Color(0x992A2A2A)),
                        ),
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange),
                            SizedBox(width: 8.w),
                            Text(
                              'Price unavailable',
                              style: GoogleFonts.inter(
                                color: Colors.orange,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Estimated Total',
                        style: GoogleFonts.inter(color: Color(0x992A2A2A)),
                      ),
                      Text(
                        _formatCurrency(replacePrice),
                        style: GoogleFonts.inter(
                          color: Color(0xFF2A2A2A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Estimated Total',
                      style: GoogleFonts.inter(
                        color: Color(0x992A2A2A),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '—',
                      style: GoogleFonts.inter(color: Color(0x992A2A2A)),
                    ),
                  ],
                );
              },
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildOptionButton(
                  'Repair',
                  Icons.build,
                  selectedOption == 'repair',
                  () {
                    setState(
                      () => _selectedRepairOptions[globalIndex] = 'repair',
                    );
                    if (!_repairPricingData.containsKey(globalIndex) &&
                        damagedPart != 'Unknown Part') {
                      _fetchPricingForDamage(
                        globalIndex,
                        damagedPart,
                        'repair',
                      );
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
                    setState(
                      () => _selectedRepairOptions[globalIndex] = 'replace',
                    );
                    if (!_replacePricingData.containsKey(globalIndex) &&
                        damagedPart != 'Unknown Part') {
                      _fetchPricingForDamage(
                        globalIndex,
                        damagedPart,
                        'replace',
                      );
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
              isSelected ? Colors.green : Colors.green.withValues(alpha: 0.15),
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

  String _formatDamagedPartForApi(String partName) {
    if (partName.isEmpty) return partName;
    String formatted =
        partName.replaceAll('-', ' ').replaceAll('_', ' ').trim();
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

  Future<void> _fetchPricingForDamage(
    int damageIndex,
    String damagedPart,
    String selectedOption,
  ) async {
    setState(() => _isLoadingPricing[damageIndex] = true);
    try {
      final formattedPartName = _formatDamagedPartForApi(damagedPart);
      final bothPricingData = await PricesRepository.instance
          .getBothRepairAndReplacePricing(formattedPartName);
      if (mounted) {
        setState(() {
          _repairPricingData[damageIndex] = bothPricingData['repair_data'];
          _replacePricingData[damageIndex] = bothPricingData['replace_data'];
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

  void _calculateEstimatedDamageCost() {
    double apiTotal = 0.0;
    final apiResponses =
        widget.apiResponses ?? <String, Map<String, dynamic>>{};
    for (var response in apiResponses.values) {
      if (response['total_cost'] != null) {
        apiTotal += _parseToDouble(response['total_cost']);
      } else if (response['cost_estimate'] != null) {
        apiTotal += _parseToDouble(response['cost_estimate']);
      }
    }

    // Pricing total is derived from user-selected options (both API and manual damages)
    final pricingTotal = _calculateTotalFromPricingData();

    // If the user has selected repair/replace options (pricingTotal > 0)
    // prefer the pricing total so the estimate reflects user choices and manual edits.
    final totalCost = (pricingTotal > 0.0) ? pricingTotal : apiTotal;
    setState(() => _estimatedDamageCost = totalCost);
  }

  double _parseToDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) {
      final sanitized = val.replaceAll(RegExp(r"[^0-9.\-]"), '');
      try {
        return double.parse(sanitized);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  double _calculateTotalFromPricingData() {
    double total = 0.0;
    _selectedRepairOptions.forEach((damageIndex, selectedOption) {
      if (selectedOption == null) return;
      if (selectedOption == 'repair' &&
          _repairPricingData[damageIndex] != null) {
        final repairData = _repairPricingData[damageIndex]!;
        final replacePricingForRepair = _replacePricingData[damageIndex];
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
        double replaceCost =
            (replaceData['srp_insurance'] as num?)?.toDouble() ?? 0.0;
        total += replaceCost;
      }
    });
    return total;
  }

  Color _getSeverityColor(String severity) {
    final lowerSeverity = severity.toLowerCase();
    if (lowerSeverity.contains('high') || lowerSeverity.contains('severe'))
      return Colors.red;
    if (lowerSeverity.contains('medium') || lowerSeverity.contains('moderate'))
      return Colors.orange;
    if (lowerSeverity.contains('low') || lowerSeverity.contains('minor'))
      return Colors.green;
    return Colors.blue;
  }

  Future<void> _savePDF() async {
    setState(() => _isSaving = true);
    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) throw Exception('Storage permission not granted');

      final Map<String, Map<String, dynamic>> pdfResponses = {};
      final apiResponsesForPdf =
          widget.apiResponses ?? <String, Map<String, dynamic>>{};
      apiResponsesForPdf.forEach((key, value) {
        pdfResponses[key] = Map<String, dynamic>.from(value);
      });

      // --- FIX: Correctly structure manual damages for the PDF service ---
      if (apiResponsesForPdf.isEmpty && _manualDamages.isNotEmpty) {
        // Since there's no single API response to hold all manual damages,
        // we create one synthetic entry for the whole report.
        List<Map<String, dynamic>> manualDamagesForPdf = [];
        for (final m in _manualDamages) {
          manualDamagesForPdf.add({
            'type': m['damaged_part'], // Key 'type' is read by the PDF service
            'severity': '', // No severity for manual damages
          });
        }

        pdfResponses['manual_report_1'] = {
          'overall_severity': 'Manual Assessment',
          'damages': manualDamagesForPdf,
          'total_cost': _formatCurrency(_calculateTotalFromPricingData()),
        };
      }

      if (_isDamageSevere) {
        pdfResponses.forEach((key, value) {
          value['total_cost'] = 'To be given by the mechanic';
        });
      }

      final choice = await showDialog<String?>(
        context: context,
        builder:
            (context) => AlertDialog(
              backgroundColor: Colors.white,
              title: Text(
                'Save Assessment Report',
                style: GoogleFonts.inter(
                  color: Color(0xFF2A2A2A),
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                'Where do you want to save the generated PDF?',
                style: GoogleFonts.inter(
                  color: Color(0xFF2A2A2A),
                  fontSize: 14.sp,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop('auto'),
                  child: Text(
                    'Save to InsureVis/documents',
                    style: GoogleFonts.inter(
                      color: GlobalStyles.primaryColor,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop('choose'),
                  child: Text(
                    'Choose folder',
                    style: GoogleFonts.inter(
                      color: GlobalStyles.primaryColor,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      color: GlobalStyles.primaryColor,
                      fontSize: 14.sp,
                    ),
                  ),
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
        savedPath = await PDFService.generateMultipleResultsPDF(
          imagePaths: widget.imagePaths ?? const <String>[],
          apiResponses: pdfResponses,
        );
      } else if (choice == 'choose') {
        final bytes = await PDFService.generateMultipleResultsPDFBytes(
          imagePaths: widget.imagePaths ?? const <String>[],
          apiResponses: pdfResponses,
        );
        if (bytes == null) throw Exception('Failed to generate PDF bytes');
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
            savedPath = newFileUri;
          } catch (e) {
            savedPath = await PDFService.savePdfBytesWithPicker(
              bytes,
              'InsureVis_Assessment_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
            );
          }
        } else {
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
                onPressed: () => _sharePDF(savedPath!),
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
        setState(() => _isSaving = false);
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
