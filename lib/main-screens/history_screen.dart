import 'dart:io';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/models/assessment_model.dart';
import 'package:insurevis/other-screens/result_screen.dart';
import 'package:insurevis/providers/assessment_provider.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
              tabs: [Tab(text: 'Recent'), Tab(text: 'Old')],
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildRecentTab(), _buildOldTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHistoryView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150.w,
            height: 150.w,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(51), // 0.2 * 255
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history,
              size: 60.sp,
              color: Colors.white.withAlpha(179), // 0.7 * 255
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            message,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'When an image analysis is finished, the\nassessment report will appear in this list',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTab() {
    return Consumer<AssessmentProvider>(
      builder: (context, provider, child) {
        final recentAssessments = provider.completedAssessments;

        if (recentAssessments.isEmpty) {
          return _buildEmptyHistoryView("Assessment History is empty");
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: recentAssessments.length,
          itemBuilder: (context, index) {
            final assessment = recentAssessments[index];
            return _buildHistoryAssessmentCard(
              assessment,
              onTap: () {
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

  Widget _buildHistoryAssessmentCard(
    Assessment assessment, {
    required VoidCallback onTap,
  }) {
    final formattedDate = DateFormat(
      'MMM d, yyyy',
    ).format(assessment.timestamp);
    final formattedTime = DateFormat('h:mm a').format(assessment.timestamp);

    // Determine card border color based on damage severity
    Color borderColor = GlobalStyles.primaryColor.withAlpha(77); // 0.3 * 255
    if (assessment.results != null &&
        assessment.results!.containsKey('severity')) {
      final severity = assessment.results!['severity'].toString().toLowerCase();
      if (severity.contains('high') || severity.contains('severe')) {
        borderColor = Colors.red.withAlpha(128); // 0.5 * 255
      } else if (severity.contains('medium')) {
        borderColor = Colors.orange.withAlpha(128); // 0.5 * 255
      } else {
        borderColor = Colors.green.withAlpha(128); // 0.5 * 255
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(77), // 0.3 * 255
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image and date row
            Row(
              children: [
                // Image thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    bottomLeft: Radius.circular(16.r),
                  ),
                  child: SizedBox(
                    width: 100.w,
                    height: 100.w,
                    child: Image.file(
                      File(assessment.imagePath),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Date and details
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formattedDate,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              formattedTime,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),

                        // Display damage type and severity if available
                        if (assessment.results != null &&
                            assessment.results!.containsKey('damage_type'))
                          Text(
                            'Type: ${assessment.results!['damage_type']}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),

                        if (assessment.results != null &&
                            assessment.results!.containsKey('severity'))
                          Text(
                            'Severity: ${assessment.results!['severity']}',
                            style: TextStyle(
                              color: _getSeverityColor(
                                assessment.results!['severity'].toString(),
                              ),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),

                        SizedBox(height: 8.h),

                        // View details button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'View Details',
                              style: TextStyle(
                                color: GlobalStyles.primaryColor,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: GlobalStyles.primaryColor,
                              size: 12.sp,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    severity = severity.toLowerCase();
    if (severity.contains('high') || severity.contains('severe')) {
      return Colors.red;
    } else if (severity.contains('medium')) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  Widget _buildOldTab() {
    // For now, just show empty view - later you could filter by date
    return _buildEmptyHistoryView("No old assessments found");
  }
}
