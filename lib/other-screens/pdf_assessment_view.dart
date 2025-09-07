import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/utils/pdf_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

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
          'Assessment Report',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon:
                _isSaving
                    ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : Icon(Icons.save, color: Colors.white),
            onPressed: _isSaving ? null : _savePDF,
          ),
        ],
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
        if (severity.toLowerCase().contains('high'))
          severityCount['High'] = (severityCount['High'] ?? 0) + 1;
        else if (severity.toLowerCase().contains('medium'))
          severityCount['Medium'] = (severityCount['Medium'] ?? 0) + 1;
        else
          severityCount['Low'] = (severityCount['Low'] ?? 0) + 1;
      }
    });

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
                  '₱${totalCost.toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.green,
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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
                          'Cost: ₱${response['total_cost']}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.green,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (response != null && response.containsKey('damages')) ...[
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
        color: GlobalStyles.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: GlobalStyles.primaryColor.withValues(alpha: 0.3),
        ),
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

      // Generate PDF
      final filePath = await PDFService.generateMultipleResultsPDF(
        imagePaths: widget.imagePaths,
        apiResponses: widget.apiResponses,
      );

      if (filePath != null) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Assessment report saved successfully!'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'Share',
                textColor: Colors.white,
                onPressed: () => _sharePDF(filePath),
              ),
            ),
          );
        }
      } else {
        throw Exception('Failed to generate PDF');
      }
    } catch (e) {
      if (mounted) {
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
