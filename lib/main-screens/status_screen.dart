import 'dart:io';
import 'package:insurevis/other-screens/result_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/providers/assessment_provider.dart';
import 'package:insurevis/models/assessment_model.dart';
import 'package:insurevis/components/analytics_dashboard_simple.dart';
import 'package:insurevis/services/enhanced_pdf_service_simple.dart';
import 'package:insurevis/services/export_service_simple.dart';
import 'package:intl/intl.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TabBar(
              controller: _tabController,
              indicatorColor: GlobalStyles.primaryColor,
              indicatorWeight: 3,
              tabs: [
                Tab(text: 'Active'),
                Tab(text: 'Completed'),
                Tab(text: 'Analytics'),
              ],
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildActiveTab(),
                  _buildCompletedTab(),
                  _buildAnalyticsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTab() {
    return Consumer<AssessmentProvider>(
      builder: (context, provider, child) {
        final activeAssessments = provider.activeAssessments;

        if (activeAssessments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 150.w,
                  height: 150.w,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.hourglass_empty,
                    size: 60.sp,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'No assessments in progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'When you submit a photo for analysis,\nits status will show up here',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: activeAssessments.length,
          itemBuilder: (context, index) {
            final assessment = activeAssessments[index];
            return _buildActiveAssessmentCard(assessment);
          },
        );
      },
    );
  }

  Widget _buildActiveAssessmentCard(Assessment assessment) {
    final formattedTime = DateFormat('hh:mm a').format(assessment.timestamp);

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: GlobalStyles.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
            child: SizedBox(
              width: double.infinity,
              height: 180.h,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // The image
                  Image.file(File(assessment.imagePath), fit: BoxFit.cover),

                  // Processing overlay
                  Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              GlobalStyles.primaryColor,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Processing...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Assessment info
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Assessment in Progress',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      formattedTime,
                      style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  'Your image is being analyzed. This usually takes about 30 seconds.',
                  style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedTab() {
    return Consumer<AssessmentProvider>(
      builder: (context, provider, child) {
        final completedAssessments = provider.completedAssessments;

        if (completedAssessments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 150.w,
                  height: 150.w,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    size: 60.sp,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'No completed assessments',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Completed assessments will appear here',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: completedAssessments.length,
          itemBuilder: (context, index) {
            final assessment = completedAssessments[index];
            return _buildCompletedAssessmentCard(
              assessment,
              onTap: () {
                // Navigate to view assessment details
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ResultsScreen(
                          imagePath: assessment.imagePath,
                          assessmentId: assessment.id,
                        ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCompletedAssessmentCard(
    Assessment assessment, {
    required VoidCallback onTap,
  }) {
    final formattedDate = DateFormat(
      'MMM d, yyyy • h:mm a',
    ).format(assessment.timestamp);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image preview
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
              child: SizedBox(
                width: double.infinity,
                height: 160.h,
                child: Image.file(
                  File(assessment.imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Assessment info
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 18.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Assessment Complete',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white54,
                        size: 16.sp,
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    formattedDate,
                    style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                  ),
                  SizedBox(height: 8.h),
                  if (assessment.results != null)
                    ..._buildResultSummary(assessment.results!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildResultSummary(Map<String, dynamic> results) {
    final priorityFields = ['damage_type', 'severity'];
    final displayFields = <Widget>[];

    // Add priority fields first if they exist
    for (final field in priorityFields) {
      if (results.containsKey(field)) {
        final value = results[field];
        displayFields.add(
          Row(
            children: [
              _getFieldIcon(field),
              SizedBox(width: 8.w),
              Text(
                '$field: ',
                style: TextStyle(color: Colors.white70, fontSize: 14.sp),
              ),
              Text(
                value.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }
    }

    return displayFields;
  }

  Widget _getFieldIcon(String fieldName) {
    final lowerField = fieldName.toLowerCase();
    if (lowerField.contains('damage_type')) {
      return const Icon(Icons.build, color: Colors.orange, size: 16);
    } else if (lowerField.contains('severity')) {
      return const Icon(Icons.warning, color: Colors.amber, size: 16);
    } else if (lowerField.contains('cost')) {
      return const Icon(Icons.monetization_on, color: Colors.green, size: 16);
    } else {
      return const Icon(Icons.info_outline, color: Colors.blue, size: 16);
    }
  }

  Widget _buildAnalyticsTab() {
    return Consumer<AssessmentProvider>(
      builder: (context, provider, child) {
        final allAssessments = provider.assessments;

        return AnalyticsDashboard(
          assessments: allAssessments,
          onExportData: () async {
            try {
              final exportService = ExportService();

              // Show export options dialog
              final result = await showDialog<String>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Export Options'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.table_chart),
                            title: const Text('Export as CSV'),
                            onTap: () => Navigator.pop(context, 'csv'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.description),
                            title: const Text('Export as Excel'),
                            onTap: () => Navigator.pop(context, 'excel'),
                          ),
                        ],
                      ),
                    ),
              );

              if (result != null) {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                String filePath;

                if (result == 'csv') {
                  filePath = await exportService.exportToCSV(allAssessments);
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('CSV exported to: $filePath')),
                  );
                } else {
                  filePath = await exportService.exportToExcel(allAssessments);
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Excel exported to: $filePath')),
                  );
                }

                // Offer to share the file
                await exportService.shareFile(filePath);
              }
            } catch (e) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
            }
          },
          onGenerateReport: () async {
            try {
              final pdfService = EnhancedPDFService();

              // Show report type options
              final reportType = await showDialog<String>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Report Type'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.summarize),
                            title: const Text('Summary Report'),
                            onTap: () => Navigator.pop(context, 'summary'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.business),
                            title: const Text('Insurance Report'),
                            onTap: () => Navigator.pop(context, 'insurance'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.engineering),
                            title: const Text('Technical Report'),
                            onTap: () => Navigator.pop(context, 'technical'),
                          ),
                        ],
                      ),
                    ),
              );

              if (reportType != null) {
                final filePath = await pdfService.generateReport(
                  allAssessments,
                  reportType: reportType,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('PDF report generated: $filePath')),
                );

                // Offer to share the PDF
                await pdfService.sharePDF(filePath);
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Report generation failed: $e')),
              );
            }
          },
        );
      },
    );
  }
}
