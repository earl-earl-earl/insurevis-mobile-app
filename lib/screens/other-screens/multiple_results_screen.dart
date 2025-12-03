import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/screens/other-screens/result_screen.dart';
import 'package:insurevis/screens/other-screens/vehicle_information_form.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:insurevis/providers/assessment_provider.dart';
import 'package:insurevis/utils/multiple_results_utils.dart';

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

  @override
  void initState() {
    super.initState();
    _cachedImages.addAll(
      MultipleResultsUtils.preloadImages(widget.imagePaths, 80),
    );
    _uploadAllImages();
  }

  @override
  Widget build(BuildContext context) {
    final bool anyUploading = MultipleResultsUtils.hasUploadsInProgress(
      _uploadResults,
    );
    return Scaffold(
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Results',
          style: TextStyle(
            fontFamily: GlobalStyles.fontFamilyHeading,
            fontSize: GlobalStyles.fontSizeH4,
            fontWeight: GlobalStyles.fontWeightSemiBold,
            color: GlobalStyles.textPrimary,
            letterSpacing: GlobalStyles.letterSpacingH4,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Add image',
            icon: Icon(
              LucideIcons.imagePlus,
              color: GlobalStyles.textPrimary,
              size: GlobalStyles.iconSizeSm,
            ),
            onPressed: _addImage,
          ),
        ],
      ),
      // Download PDF button removed
      bottomNavigationBar: null,
      body: SizedBox(
        height: double.infinity,
        child: SafeArea(child: _buildResultsViewWithFixedButtons(anyUploading)),
      ),
    );
  }

  Widget _buildResultsViewWithFixedButtons(bool anyUploading) {
    return Column(
      children: [
        // Scrollable content takes up available space
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(GlobalStyles.paddingNormal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  anyUploading ? 'Analyzing Images...' : 'Analysis Complete',
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyHeading,
                    fontSize: GlobalStyles.fontSizeH3,
                    fontWeight: GlobalStyles.fontWeightBold,
                    color: GlobalStyles.textPrimary,
                  ),
                ),
                SizedBox(height: GlobalStyles.spacingSm),
                Text(
                  anyUploading
                      ? '${_uploadResults.values.where((s) => s == 'success').length} of ${widget.imagePaths.length} images analyzed'
                      : '${widget.imagePaths.length} images analyzed',
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyBody,
                    fontSize: GlobalStyles.fontSizeBody2,
                    color: GlobalStyles.textTertiary,
                  ),
                ),
                SizedBox(height: GlobalStyles.spacingSm),

                // Disclaimer: AI can make mistakes (orange)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons.circleAlert,
                      color: GlobalStyles.warningMain,
                      size: GlobalStyles.iconSizeSm,
                    ),
                    SizedBox(width: GlobalStyles.spacingSm),
                    Expanded(
                      child: Text(
                        'Note: AI analysis can make mistakes. Please review the results carefully.',
                        style: TextStyle(
                          fontFamily: GlobalStyles.fontFamilyBody,
                          fontSize: GlobalStyles.fontSizeCaption,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: GlobalStyles.spacingLg),

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
          padding: EdgeInsets.all(GlobalStyles.paddingNormal),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: GlobalStyles.surfaceMain.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: _buildActionButtons(anyUploading),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool anyUploading) {
    return Row(
      children: [
        Tooltip(
          message: 'Home',
          child: IconButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            icon: Icon(
              LucideIcons.house,
              color: GlobalStyles.primaryMain,
              size: GlobalStyles.iconSizeMd,
            ),
            iconSize: GlobalStyles.iconSizeMd,
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(
                GlobalStyles.primaryMain.withValues(alpha: 0.06),
              ),
              padding: WidgetStatePropertyAll(
                EdgeInsets.all(GlobalStyles.paddingNormal),
              ),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: ElevatedButton(
            onPressed:
                anyUploading
                    ? null
                    : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => VehicleInformationForm(
                                imagePaths: widget.imagePaths,
                                apiResponses: _apiResponses,
                                assessmentIds: _assessmentIds,
                              ),
                        ),
                      );
                    },
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(
                anyUploading ? Colors.grey : GlobalStyles.primaryMain,
              ),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              ),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            child: Text(
              "View Assessment Report",
              style: TextStyle(
                fontFamily: GlobalStyles.fontFamilyBody,
                color: GlobalStyles.surfaceMain,
                fontSize: GlobalStyles.fontSizeBody1,
                fontWeight: GlobalStyles.fontWeightSemiBold,
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
    final bool isUploading = status == 'uploading';
    final bool isQueued = status == null; // Queued images have no status yet
    final bool showLoader = isUploading || isQueued;
    Color borderColor = GlobalStyles.surfaceMain.withValues(alpha: 0.3);
    Widget statusWidget = Container();
    bool canTap = false;
    bool isExpanded = _expandedCards[imagePath] ?? false;

    if (status == 'success' && assessmentId != null) {
      borderColor = GlobalStyles.primaryMain.withAlpha(127);
      canTap = true;
      statusWidget = Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: GlobalStyles.primaryMain.withAlpha(51),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: GlobalStyles.primaryMain.withAlpha(76)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.circleCheck,
              color: GlobalStyles.successMain,
              size: GlobalStyles.iconSizeSm,
            ),
            SizedBox(width: 4.w),
            Text(
              'Analysis Complete',
              style: TextStyle(
                fontFamily: GlobalStyles.fontFamilyBody,
                color: GlobalStyles.primaryMain,
                fontSize: GlobalStyles.fontSizeCaption,
                fontWeight: GlobalStyles.fontWeightMedium,
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
            Icon(
              LucideIcons.circleX,
              color: GlobalStyles.errorMain,
              size: GlobalStyles.iconSizeSm,
            ),
            SizedBox(width: 4.w),
            Text(
              'Analysis Failed',
              style: TextStyle(
                fontFamily: GlobalStyles.fontFamilyBody,
                color: Colors.red,
                fontSize: GlobalStyles.fontSizeCaption,
                fontWeight: GlobalStyles.fontWeightMedium,
              ),
            ),
          ],
        ),
      );
    }

    final cardContent = Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color:
            status == 'error'
                ? Colors.red.withAlpha(25)
                : GlobalStyles.primaryMain.withAlpha(25),
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
                                style: TextStyle(
                                  fontFamily: GlobalStyles.fontFamilyBody,
                                  fontSize: GlobalStyles.fontSizeBody1,
                                  fontWeight: GlobalStyles.fontWeightSemiBold,
                                  color:
                                      status == 'error'
                                          ? Colors.red
                                          : GlobalStyles.primaryMain,
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
                              style: TextStyle(
                                fontFamily: GlobalStyles.fontFamilyBody,
                                fontSize: GlobalStyles.fontSizeCaption,
                                color: GlobalStyles.textSecondary,
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
                  top: BorderSide(
                    color: GlobalStyles.surfaceMain.withValues(alpha: 0.1),
                  ),
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
                          style: TextStyle(
                            fontFamily: GlobalStyles.fontFamilyBody,
                            color: GlobalStyles.primaryMain,
                            fontSize: GlobalStyles.fontSizeBody2,
                            fontWeight: GlobalStyles.fontWeightSemiBold,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Icon(
                          isExpanded
                              ? LucideIcons.chevronUp
                              : LucideIcons.chevronDown,
                          color: GlobalStyles.primaryMain,
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

    return Stack(
      children: [
        Opacity(opacity: showLoader ? 0.5 : 1.0, child: cardContent),
        if (showLoader)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: SizedBox(
                  width: 32.w,
                  height: 32.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 3,
                    color: GlobalStyles.primaryMain,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExpandedDetails(Map<String, dynamic> apiResponse) {
    // Extract key information from API response using utils
    final overallSeverity = MultipleResultsUtils.extractSeverity(apiResponse);
    final costEstimate = MultipleResultsUtils.extractCostEstimate(apiResponse);
    final damages = MultipleResultsUtils.extractDamages(apiResponse);

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
                  MultipleResultsUtils.getSeverityColor(overallSeverity),
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
              style: TextStyle(
                fontFamily: GlobalStyles.fontFamilyBody,
                color: GlobalStyles.textPrimary,
                fontSize: GlobalStyles.fontSizeBody2,
                fontWeight: GlobalStyles.fontWeightSemiBold,
              ),
            ),
            SizedBox(height: 8.h),
            ...damages.take(3).map((damage) => _buildDamageItem(damage)),
            if (damages.length > 3)
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Text(
                  '+ ${damages.length - 3} more damages',
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyBody,
                    color: GlobalStyles.textTertiary,
                    fontSize: GlobalStyles.fontSizeCaption,
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
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyBody,
              color: GlobalStyles.textPrimary,
              fontSize: GlobalStyles.fontSizeCaption,
              fontWeight: GlobalStyles.fontWeightSemiBold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyBody,
              color: color,
              fontSize: GlobalStyles.fontSizeBody2,
              fontWeight: GlobalStyles.fontWeightSemiBold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDamageItem(dynamic damage) {
    final damageType = MultipleResultsUtils.extractDamageType(damage);
    final severity = MultipleResultsUtils.extractDamageSeverity(damage);

    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.r)),
      child: Row(
        children: [
          Icon(
            LucideIcons.triangleAlert,
            color: GlobalStyles.warningMain,
            size: GlobalStyles.iconSizeSm,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              MultipleResultsUtils.capitalizeFirst(damageType),
              style: TextStyle(
                fontFamily: GlobalStyles.fontFamilyBody,
                color: GlobalStyles.textPrimary,
                fontSize: GlobalStyles.fontSizeBody2,
              ),
            ),
          ),
          if (severity.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: MultipleResultsUtils.getSeverityColor(
                  severity,
                ).withAlpha(51),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                MultipleResultsUtils.capitalizeFirst(severity),
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyBody,
                  color: MultipleResultsUtils.getSeverityColor(severity),
                  fontSize: GlobalStyles.fontSizeCaption,
                  fontWeight: GlobalStyles.fontWeightMedium,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _uploadAllImages() async {
    final assessmentProvider = Provider.of<AssessmentProvider>(
      context,
      listen: false,
    );

    for (final imagePath in widget.imagePaths) {
      setState(() {
        _uploadResults[imagePath] = 'uploading';
      });

      try {
        final result = await MultipleResultsUtils.processImage(
          imagePath,
          assessmentProvider,
        );

        setState(() {
          _uploadResults[imagePath] = result.status;
          if (result.apiResponse != null) {
            _apiResponses[imagePath] = result.apiResponse!;
          }
          if (result.assessmentId != null) {
            _assessmentIds[imagePath] = result.assessmentId!;
          }
        });
      } catch (e) {
        setState(() {
          _uploadResults[imagePath] = 'error';
        });
      }
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

  Future<void> _addImage() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      final imagePath = picked.path;

      setState(() {
        // Add to the list displayed
        widget.imagePaths.add(imagePath);
        // Mark as uploading
        _uploadResults[imagePath] = 'uploading';
        _expandedCards[imagePath] = false;
        // Cache thumbnail
        _cachedImages[imagePath] = ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: SizedBox(
            width: 80.w,
            height: 80.w,
            child: Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              cacheWidth: 80,
              cacheHeight: 80,
            ),
          ),
        );
      });

      // Trigger upload/analysis but do not block the whole screen
      final assessmentProvider = Provider.of<AssessmentProvider>(
        context,
        listen: false,
      );
      try {
        final result = await MultipleResultsUtils.processImage(
          imagePath,
          assessmentProvider,
        );

        setState(() {
          _uploadResults[imagePath] = result.status;
          if (result.apiResponse != null) {
            _apiResponses[imagePath] = result.apiResponse!;
          }
          if (result.assessmentId != null) {
            _assessmentIds[imagePath] = result.assessmentId!;
          }
        });
      } catch (e) {
        setState(() {
          _uploadResults[imagePath] = 'error';
        });
      }
    } catch (_) {}
  }
}
