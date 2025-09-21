import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/other-screens/result_screen.dart';
import 'package:insurevis/other-screens/pdf_assessment_view.dart';
import 'package:insurevis/other-screens/insurance_document_upload.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/providers/assessment_provider.dart';
import 'package:insurevis/utils/network_helper.dart';

class MultipleResultsScreen extends StatefulWidget {
  final List<String> imagePaths;

  const MultipleResultsScreen({super.key, required this.imagePaths});

  @override
  State<MultipleResultsScreen> createState() => _MultipleResultsScreenState();
}

class _MultipleResultsScreenState extends State<MultipleResultsScreen> {
  final Map<String, String> _uploadResults =
      {}; // Track upload status for each image
  final Map<String, String> _assessmentIds = {}; // Track assessment IDs
  final Map<String, Map<String, dynamic>> _apiResponses =
      {}; // Store API responses
  final Map<String, bool> _expandedCards =
      {}; // Track expanded state for each card
  final Map<String, Widget> _cachedImages = {}; // Cache for image widgets
  bool _isUploading = false;
  @override
  void initState() {
    super.initState();
    _preloadImages();
    _uploadAllImages();
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
          'Results',
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2A2A2A),
          ),
        ),
      ),
      // Download PDF button removed
      bottomNavigationBar: null,
      body: SizedBox(
        height: double.infinity,
        child: SafeArea(
          child:
              _isUploading
                  ? _buildLoadingView()
                  : _buildResultsViewWithFixedButtons(),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    final completedCount =
        _uploadResults.values.where((r) => r != 'uploading').length;
    final totalCount = widget.imagePaths.length;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: GlobalStyles.primaryColor,
            strokeWidth: 3,
          ),
          SizedBox(height: 20.h),
          Text(
            'Analyzing images...',
            style: GoogleFonts.inter(
              color: const Color(0xFF2A2A2A),
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            '$completedCount of $totalCount completed',
            style: GoogleFonts.inter(
              color: const Color(0x992A2A2A),
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsViewWithFixedButtons() {
    return Column(
      children: [
        // Scrollable content takes up available space
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analysis Complete',
                  style: GoogleFonts.inter(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2A2A2A),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '${widget.imagePaths.length} images analyzed',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: const Color(0x992A2A2A),
                  ),
                ),
                SizedBox(height: 24.h),

                // Results list
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.imagePaths.length,
                  itemBuilder: (context, index) {
                    final imagePath = widget.imagePaths[index];
                    final status = _uploadResults[imagePath];
                    final assessmentId = _assessmentIds[imagePath];
                    return _buildResultCard(
                      imagePath,
                      index + 1,
                      status,
                      assessmentId,
                      _apiResponses[imagePath],
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // Fixed buttons at the bottom
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white.withAlpha(25), width: 1),
            ),
          ),
          child: _buildActionButtons(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // View Assessment Button (top)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => PDFAssessmentView(
                        imagePaths: widget.imagePaths,
                        apiResponses: _apiResponses,
                        assessmentIds: _assessmentIds,
                      ),
                ),
              );
            },
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.grey.shade700),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              ),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            child: Text(
              "View Assessment",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        SizedBox(height: 12.h), // Space between buttons
        // Proceed to Claim Insurance Button (bottom, accent)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => InsuranceDocumentUpload(
                        imagePaths: widget.imagePaths,
                        apiResponses: _apiResponses,
                        assessmentIds: _assessmentIds,
                      ),
                ),
              );
            },
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(
                GlobalStyles.primaryColor,
              ),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              ),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            child: Text(
              "Proceed to Claim Insurance",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(
    String imagePath,
    int imageNumber,
    String? status,
    String? assessmentId,
    Map<String, dynamic>? apiResponse,
  ) {
    Color borderColor = Colors.white.withAlpha(76);
    Widget statusWidget = Container();
    bool canTap = false;
    bool isExpanded = _expandedCards[imagePath] ?? false;

    if (status == 'success' && assessmentId != null) {
      borderColor = GlobalStyles.primaryColor.withAlpha(127);
      canTap = true;
      statusWidget = Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: GlobalStyles.primaryColor.withAlpha(51),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: GlobalStyles.primaryColor.withAlpha(76)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: GlobalStyles.primaryColor,
              size: 14.sp,
            ),
            SizedBox(width: 4.w),
            Text(
              'Analysis Complete',
              style: GoogleFonts.inter(
                color: GlobalStyles.primaryColor,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else if (status == 'error') {
      borderColor = Colors.red;
      statusWidget = Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: Colors.red.withAlpha(51),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.red.withAlpha(76)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error, color: Colors.red, size: 14.sp),
            SizedBox(width: 4.w),
            Text(
              'Analysis Failed',
              style: GoogleFonts.inter(
                color: Colors.red,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color:
            status == 'error'
                ? Colors.red.withAlpha(25)
                : GlobalStyles.primaryColor.withAlpha(25),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        children: [
          // Main card content - tappable for navigation
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap:
                  canTap
                      ? () => _viewResult(imagePath, assessmentId!, apiResponse)
                      : null,
              borderRadius: BorderRadius.circular(16.r),
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Row(
                  children: [
                    // Image thumbnail - using cached image
                    _cachedImages[imagePath] ??
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: SizedBox(
                            width: 80.w,
                            height: 80.w,
                            child: Image.file(
                              File(imagePath),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                    SizedBox(width: 12.w),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Image $imageNumber',
                                style: GoogleFonts.inter(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      status == 'error'
                                          ? Colors.red
                                          : GlobalStyles.primaryColor,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 8.h),

                          statusWidget,

                          if (canTap) ...[
                            SizedBox(height: 8.h),
                            Text(
                              'Tap to view full report',
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                color: const Color(0xFF2A2A2A),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Expanded details section
          if (isExpanded && canTap && apiResponse != null)
            _buildExpandedDetails(apiResponse), // "Show Details" section
          if (canTap)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withAlpha(25)),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _expandedCards[imagePath] = !isExpanded;
                    });
                  },
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16.r),
                    bottomRight: Radius.circular(16.r),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 12.h,
                      horizontal: 16.w,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isExpanded ? 'Hide Details' : 'Show Details',
                          style: GoogleFonts.inter(
                            color: GlobalStyles.primaryColor,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: GlobalStyles.primaryColor,
                          size: 16.sp,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpandedDetails(Map<String, dynamic> apiResponse) {
    // Extract key information from API response
    String overallSeverity = 'Unknown';
    String costEstimate = 'Not available';
    List<dynamic> damages = [];

    if (apiResponse.containsKey('overall_severity')) {
      overallSeverity = _capitalizeFirst(
        apiResponse['overall_severity'].toString(),
      );
    }

    if (apiResponse.containsKey('total_cost')) {
      try {
        double cost = double.parse(apiResponse['total_cost'].toString());
        costEstimate = '₱${cost.toStringAsFixed(2)}';
      } catch (e) {
        costEstimate = '₱${apiResponse['total_cost']}';
      }
    }

    if (apiResponse.containsKey('damages') && apiResponse['damages'] is List) {
      damages = apiResponse['damages'];
    } else if (apiResponse.containsKey('prediction') &&
        apiResponse['prediction'] is List) {
      damages = apiResponse['prediction'];
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withAlpha(25))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Summary
          Row(
            children: [
              Expanded(
                child: _buildQuickInfoCard(
                  'Severity',
                  overallSeverity,
                  _getSeverityColor(overallSeverity),
                ),
              ),
              // Only show estimate if available
              if (costEstimate != 'Not available') ...[
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildQuickInfoCard(
                    'Estimate',
                    costEstimate,
                    Colors.blue,
                  ),
                ),
              ],
            ],
          ),

          if (damages.isNotEmpty &&
              overallSeverity.toLowerCase() != 'severe') ...[
            SizedBox(height: 16.h),
            Text(
              'Detected Damages (${damages.length})',
              style: GoogleFonts.inter(
                color: const Color(0xFF2A2A2A),
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            ...damages.take(3).map((damage) => _buildDamageItem(damage)),
            if (damages.length > 3)
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Text(
                  '+ ${damages.length - 3} more damages',
                  style: GoogleFonts.inter(
                    color: const Color(0x992A2A2A),
                    fontSize: 12.sp,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickInfoCard(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFF2A2A2A),
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDamageItem(dynamic damage) {
    String damageType = 'Unknown';
    String severity = '';

    if (damage is Map<String, dynamic>) {
      damageType =
          damage['type']?.toString() ??
          damage['damage_type']?.toString() ??
          'Unknown';
      severity = damage['severity']?.toString() ?? '';
    } else if (damage is String) {
      damageType = damage;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.r)),
      child: Row(
        children: [
          Icon(Icons.report_problem_rounded, color: Colors.orange, size: 16.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              _capitalizeFirst(damageType),
              style: GoogleFonts.inter(
                color: const Color(0xFF2A2A2A),
                fontSize: 13.sp,
              ),
            ),
          ),
          if (severity.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: _getSeverityColor(severity).withAlpha(51),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                _capitalizeFirst(severity),
                style: GoogleFonts.inter(
                  color: _getSeverityColor(severity),
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
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

  Future<void> _uploadAllImages() async {
    setState(() {
      _isUploading = true;
    });

    final assessmentProvider = Provider.of<AssessmentProvider>(
      context,
      listen: false,
    );

    for (final imagePath in widget.imagePaths) {
      setState(() {
        _uploadResults[imagePath] = 'uploading';
      });

      try {
        final apiResponse = await _sendImageToAPI(imagePath);

        if (apiResponse != null) {
          // Store the API response
          setState(() {
            _apiResponses[imagePath] = apiResponse;
          });

          // Add to assessment provider
          final assessment = await assessmentProvider.addAssessment(imagePath);

          setState(() {
            _uploadResults[imagePath] = 'success';
            _assessmentIds[imagePath] = assessment.id;
          });
        } else {
          setState(() {
            _uploadResults[imagePath] = 'error';
          });
        }
      } catch (e) {
        setState(() {
          _uploadResults[imagePath] = 'error';
        });
      }
    }

    setState(() {
      _isUploading = false;
    });
  }

  Future<Map<String, dynamic>?> _sendImageToAPI(String imagePath) async {
    const url = 'https://rooster-faithful-terminally.ngrok-free.app/predict';

    try {
      // DEBUG: print("Uploading image: $imagePath");

      // Use NetworkHelper for sending multipart request
      final streamedResponse = await NetworkHelper.sendMultipartRequest(
        url: url,
        filePath: imagePath,
        fileFieldName: 'image_file',
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // DEBUG: print("API Error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      // DEBUG: print("Error uploading image: $e");
      return null;
    }
  }

  void _viewResult(
    String imagePath,
    String assessmentId,
    Map<String, dynamic>? apiResponse,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ResultsScreen(
              imagePath: imagePath,
              assessmentId: assessmentId,
              apiResponseData: apiResponse, // Pass the API response data
            ),
      ),
    );
  }

  void _preloadImages() {
    // Preload and cache all images to prevent refresh on state changes
    for (final imagePath in widget.imagePaths) {
      _cachedImages[imagePath] = ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: SizedBox(
          width: 80.w,
          height: 80.w,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.cover,
            cacheWidth:
                80, // Cache at display resolution for better performance
            cacheHeight: 80,
          ),
        ),
      );
    }
  }
}
