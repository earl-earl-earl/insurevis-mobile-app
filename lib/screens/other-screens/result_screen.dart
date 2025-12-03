import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/providers/assessment_provider.dart';
import 'package:insurevis/services/image_upload_service.dart';
import 'package:insurevis/utils/result_screen_utils.dart';

class ResultsScreen extends StatefulWidget {
  final String imagePath;
  final String? assessmentId;
  final Map<String, dynamic>?
  apiResponseData; // Add this for passing API response

  const ResultsScreen({
    super.key,
    required this.imagePath,
    this.assessmentId,
    this.apiResponseData, // Add this for passing API response
  });

  @override
  ResultsScreenState createState() => ResultsScreenState();
}

class ResultsScreenState extends State<ResultsScreen> {
  String? _apiResponse;
  bool _isLoading = true;

  // Add these cached values to prevent reprocessing
  Map<String, dynamic>? _cachedResultData;
  String? _cachedOverallSeverity;
  dynamic _cachedDamageInfo;
  String? _cachedCostEstimate;
  bool? _cachedHasCost;
  late final File _imageFile;

  // Add this to track expanded state for damage cards
  final Map<int, bool> _expandedCards = {};

  @override
  void initState() {
    super.initState();
    _imageFile = File(widget.imagePath); // Pre-load file reference

    if (widget.apiResponseData != null) {
      // If we have API response data, use it directly
      _processApiResponseData(widget.apiResponseData!);
    } else if (widget.assessmentId != null) {
      // If we have an assessment ID, load data from that instead of making a new API call
      _loadDataFromAssessment();
    } else {
      // Otherwise proceed with the usual API call
      _uploadImage();
    }
  }

  void _processApiResponseData(Map<String, dynamic> responseData) {
    // Process the response data immediately without any API calls
    _processApiResponse(jsonEncode(responseData));
    setState(() {
      _apiResponse = jsonEncode(responseData);
      _cachedResultData = responseData;
      _isLoading = false;
    });
  }

  Future<void> _uploadImage() async {
    try {
      // Verify if image exists
      if (!_imageFile.existsSync()) {
        // DEBUG: print("ERROR: Image file doesn't exist!");
        setState(() {
          _apiResponse = 'Error: Image file not found';
          _isLoading = false;
        });
        return;
      }

      // DEBUG: print("Uploading image from: ${_imageFile.path}");

      // Use ImageUploadService for uploading
      final responseData = await ImageUploadService().uploadImageFile(
        imagePath: _imageFile.path,
        fileFieldName: 'image_file',
      );

      if (responseData != null) {
        // Process data outside of setState to avoid UI jank
        // DEBUG: print("Success! Processing response...");
        await _processApiResponse(jsonEncode(responseData));

        if (mounted) {
          setState(() {
            _apiResponse = jsonEncode(responseData);
            _isLoading = false;
          });
        }
      } else {
        // DEBUG: print("Error: Upload failed");
        if (mounted) {
          setState(() {
            _apiResponse = 'Error: Upload failed';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // DEBUG: print("Exception: $e");
      if (mounted) {
        setState(() {
          _apiResponse = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Add this method after initState()
  Future<void> _loadDataFromAssessment() async {
    // DEBUG: print("Loading data from assessment ID: ${widget.assessmentId}");

    try {
      // Create a proper assessment provider and load real data
      final assessmentProvider = Provider.of<AssessmentProvider>(
        context,
        listen: false,
      );

      // Get assessment data from ID
      final assessment = await assessmentProvider.getAssessmentById(
        widget.assessmentId!,
      );

      if (assessment == null) {
        setState(() {
          _apiResponse = 'Error: Assessment not found';
          _isLoading = false;
        });
        return;
      }

      // If assessment has stored API response, use it
      if (assessment.apiResponse != null &&
          assessment.apiResponse!.isNotEmpty) {
        await _processApiResponse(assessment.apiResponse!);
        if (mounted) {
          setState(() {
            _apiResponse =
                assessment.apiResponse!; // Add ! to use non-null assertion
            _isLoading = false;
          });
        }
      } else {
        // Otherwise, make a new API call using the saved image
        _uploadImage();
      }
    } catch (e) {
      // DEBUG: print("Error loading assessment: $e");
      setState(() {
        _apiResponse = 'Error loading assessment: $e';
        _isLoading = false;
      });
    }
  }

  // Helper method to determine which fields should be displayed
  bool _shouldShowField(String fieldName) {
    final lowerField = fieldName.toLowerCase();
    // Only show damage_type and damaged_part
    return lowerField == 'damage_type' || lowerField == 'damaged_part';
  }

  // Helper method to capitalize the first letter of a string
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // Helper method to get appropriate color based on severity level
  Color _getSeverityColor(String severity) {
    final lowerSeverity = severity.toLowerCase();
    if (lowerSeverity.contains('high') || lowerSeverity.contains('severe')) {
      return GlobalStyles.errorMain;
    } else if (lowerSeverity.contains('medium') ||
        lowerSeverity.contains('moderate')) {
      return GlobalStyles.warningMain;
    } else if (lowerSeverity.contains('low') ||
        lowerSeverity.contains('minor')) {
      return GlobalStyles.successMain;
    } else {
      return GlobalStyles.infoMain; // Default color for unknown severity
    }
  }

  Future<void> _processApiResponse(String response) async {
    try {
      final processedData = ResultScreenUtils.processApiResponse(response);

      _cachedResultData = processedData.resultData;
      _cachedDamageInfo = processedData.damageInfo;
      _cachedCostEstimate = processedData.costEstimate;
      _cachedHasCost = processedData.hasCost;
      _cachedOverallSeverity = processedData.overallSeverity;
    } catch (e) {
      // DEBUG: print("Error processing API response: $e");
      _cachedResultData = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: GlobalStyles.textPrimary,
            size: GlobalStyles.iconSizeMd,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: GlobalStyles.surfaceMain,
        elevation: 0,
        shadowColor: GlobalStyles.shadowSm.color,
        title: Text(
          'Assessment Result',
          style: TextStyle(
            fontFamily: GlobalStyles.fontFamilyHeading,
            color: GlobalStyles.textPrimary,
            fontWeight: GlobalStyles.fontWeightSemiBold,
            fontSize: GlobalStyles.fontSizeH4,
            letterSpacing: GlobalStyles.letterSpacingH4,
          ),
        ),
      ),
      // Download PDF button removed
      bottomNavigationBar: null,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child:
            _isLoading
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: GlobalStyles.primaryMain,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Analyzing damage...',
                        style: TextStyle(
                          fontFamily: GlobalStyles.fontFamilyBody,
                          color: GlobalStyles.textPrimary,
                          fontSize: GlobalStyles.fontSizeBody1,
                        ),
                      ),
                    ],
                  ),
                )
                : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _imageFile,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            cacheHeight:
                                400, // Reduced from 600 to reduce memory usage
                            filterQuality:
                                FilterQuality.low, // Reduced from medium to low
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: 200,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(
                                    LucideIcons.circleAlert,
                                    color: Colors.black,
                                    size: 50,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildResultsContent(),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildResultCard({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(GlobalStyles.paddingNormal),
      decoration: BoxDecoration(
        color: GlobalStyles.surfaceMain,
        borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyHeading,
                  color: GlobalStyles.textPrimary,
                  fontSize: GlobalStyles.fontSizeH3,
                  fontWeight: GlobalStyles.fontWeightBold,
                ),
              ),
            ],
          ),
          SizedBox(height: GlobalStyles.spacingMd),
          content,
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(GlobalStyles.paddingNormal),
      decoration: BoxDecoration(
        color: GlobalStyles.errorMain.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
        border: Border.all(
          color: GlobalStyles.errorMain.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.circleAlert,
                color: GlobalStyles.errorMain,
                size: GlobalStyles.iconSizeMd,
              ),
              SizedBox(width: 8.w),
              Text(
                'Error',
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyHeading,
                  color: Colors.red,
                  fontSize: GlobalStyles.fontSizeH5,
                  fontWeight: GlobalStyles.fontWeightBold,
                ),
              ),
            ],
          ),
          SizedBox(height: GlobalStyles.spacingSm),
          Text(
            message,
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyBody,
              color: GlobalStyles.textPrimary,
              fontSize: GlobalStyles.fontSizeBody2,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build simple damage item display (single string)
  Widget _buildDamageItem(String displayValue) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(GlobalStyles.paddingTight),
      decoration: BoxDecoration(
        color: GlobalStyles.primaryMain.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(GlobalStyles.radiusSm),
      ),
      child: Text(
        displayValue,
        style: TextStyle(
          fontFamily: GlobalStyles.fontFamilyBody,
          color: GlobalStyles.textPrimary,
          fontSize: GlobalStyles.fontSizeBody2,
          fontWeight: GlobalStyles.fontWeightSemiBold,
        ),
      ),
    );
  }

  // Helper method for rendering formatted damage item (key-value with special handling)
  Widget _buildFormattedDamageItem(String fieldName, String displayValue) {
    if (fieldName.toLowerCase().contains('severity')) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 6.h),
        decoration: BoxDecoration(
          color: _getSeverityColor(displayValue).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: _getSeverityColor(displayValue).withValues(alpha: 0.3),
            width: 1.w,
          ),
        ),
        child: Text(
          _capitalizeFirst(displayValue),
          style: TextStyle(
            fontFamily: GlobalStyles.fontFamilyBody,
            color: _getSeverityColor(displayValue),
            fontWeight: GlobalStyles.fontWeightBold,
            fontSize: GlobalStyles.fontSizeBody2,
          ),
        ),
      );
    }

    // Standard rendering for non-severity fields
    return _buildDamageItem(displayValue);
  }

  // Format the value based on field name and content
  String _formatValue(String fieldName, dynamic value) {
    if (value == null) return "N/A";
    if (value is bool) return value ? "Yes" : "No";

    // Special handling for damage_type - only show class_name
    final lowerField = fieldName.toLowerCase();
    if (lowerField.contains('damage_type') && value is Map) {
      final mapValue = value as Map<String, dynamic>;
      return mapValue.containsKey('class_name')
          ? mapValue['class_name']?.toString() ?? "Unknown"
          : "Unknown";
    }

    // Format cost values with peso sign and 2 decimal places
    if (lowerField.contains('cost')) {
      if (value is num) {
        return ResultScreenUtils.formatCurrency(value.toDouble());
      } else {
        try {
          final numValue = double.parse(value.toString());
          return ResultScreenUtils.formatCurrency(numValue);
        } catch (e) {
          return '₱${value.toString()}';
        }
      }
    }

    // General number formatting for non-cost values
    if (value is num) {
      return value % 1 == 0
          ? value.toInt().toString()
          : value.toStringAsFixed(2);
    }

    return value.toString();
  }

  // Helper method to get appropriate icon for field
  Widget _getFieldIcon(String fieldName) {
    final lowerField = fieldName.toLowerCase();

    if (lowerField.contains('part')) {
      return Icon(
        LucideIcons.car,
        color: GlobalStyles.infoMain,
        size: GlobalStyles.iconSizeSm,
      );
    } else if (lowerField.contains('damage_type')) {
      return Icon(
        LucideIcons.wrench,
        color: GlobalStyles.warningMain,
        size: GlobalStyles.iconSizeSm,
      );
    } else if (lowerField.contains('severity')) {
      return Icon(
        LucideIcons.triangleAlert,
        color: GlobalStyles.warningMain,
        size: GlobalStyles.iconSizeSm,
      );
    } else if (lowerField.contains('cost')) {
      return Icon(
        LucideIcons.dollarSign,
        color: GlobalStyles.successMain,
        size: GlobalStyles.iconSizeSm,
      );
    } else if (lowerField.contains('multiplier')) {
      return Icon(
        LucideIcons.percent,
        color: GlobalStyles.purpleMain,
        size: GlobalStyles.iconSizeSm,
      );
    } else {
      return Icon(
        LucideIcons.info,
        color: GlobalStyles.textDisabled,
        size: GlobalStyles.iconSizeSm,
      );
    }
  }

  // Helper method to format field names for display
  String _formatFieldName(String fieldName) {
    final words = fieldName.split('_');
    final formattedWords =
        words
            .map(
              (word) =>
                  word.isNotEmpty
                      ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                      : '',
            )
            .toList();
    return formattedWords.join(' ');
  }

  // Helper method to build a damage card (generic wrapper)
  Widget _buildDamageCard({
    required String title,
    required Widget content,
    int? index, // Used for collapsibility if needed
  }) {
    bool isExpanded = true;
    if (index != null) {
      isExpanded = _expandedCards[index] ?? true; // Default to expanded
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: GlobalStyles.spacingMd),
      padding: EdgeInsets.all(GlobalStyles.paddingTight),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GlobalStyles.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (index != null)
            GestureDetector(
              onTap: () {
                setState(() {
                  _expandedCards[index] = !isExpanded;
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: GlobalStyles.fontFamilyBody,
                      color: GlobalStyles.textSecondary,
                      fontSize: GlobalStyles.fontSizeBody2,
                      fontWeight: GlobalStyles.fontWeightBold,
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Color(0x992A2A2A),
                    size: 18.sp,
                  ),
                ],
              ),
            )
          else
            Text(
              title,
              style: TextStyle(
                fontFamily: GlobalStyles.fontFamilyBody,
                color: GlobalStyles.textSecondary,
                fontSize: GlobalStyles.fontSizeBody2,
                fontWeight: GlobalStyles.fontWeightBold,
              ),
            ),
          const SizedBox(height: 8),
          if (index == null || isExpanded) content,
        ],
      ),
    );
  }

  // *** MODIFICATION START ***
  // New helper method for the severe damage case
  Widget _buildSevereDamageWarning() {
    return _buildResultCard(
      title: "Severe Damage Detected",
      icon: LucideIcons.triangleAlert,
      content: Column(
        children: [
          Icon(
            LucideIcons.octagonAlert,
            color: GlobalStyles.errorMain,
            size: GlobalStyles.iconSizeXl,
          ),
          const SizedBox(height: 16),
          Text(
            "Please bring your car to car company for manual inspection.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyBody,
              color: GlobalStyles.textPrimary,
              fontSize: GlobalStyles.fontSizeBody1,
              fontWeight: GlobalStyles.fontWeightMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsContent() {
    if (_apiResponse == null) {
      return _buildErrorCard('No data received');
    }

    try {
      final resultData = _cachedResultData;
      if (resultData == null) {
        return _buildErrorCard('Failed to parse response: Invalid data');
      }

      final overallSeverity = _cachedOverallSeverity;

      // Check for severe damage and show the specific UI
      if (overallSeverity != null &&
          overallSeverity.toLowerCase() == 'severe') {
        return _buildSevereDamageWarning();
      }

      // If not severe, proceed with the original detailed view
      final damageInfo = _cachedDamageInfo;
      final costEstimate = _cachedCostEstimate;
      final hasCost = _cachedHasCost;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultCard(
            title: 'Overall Assessment',
            icon: LucideIcons.trendingUp,
            content: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.sp),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getSeverityColor(overallSeverity!).withValues(alpha: 0.15),
                    Colors.grey.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12.sp),
                border: Border.all(
                  color: _getSeverityColor(
                    overallSeverity,
                  ).withValues(alpha: 0.3),
                  width: 1.w,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Overall Severity",
                            style: TextStyle(
                              fontFamily: GlobalStyles.fontFamilyBody,
                              color: GlobalStyles.textPrimary,
                              fontSize: GlobalStyles.fontSizeBody2,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.sp,
                                  vertical: 5.sp,
                                ),
                                decoration: BoxDecoration(
                                  color: _getSeverityColor(
                                    overallSeverity,
                                  ).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20.r),
                                  border: Border.all(
                                    color: _getSeverityColor(
                                      overallSeverity,
                                    ).withValues(alpha: 0.5),
                                    width: 1.w,
                                  ),
                                ),
                                child: Text(
                                  overallSeverity,
                                  style: TextStyle(
                                    fontFamily: GlobalStyles.fontFamilyBody,
                                    color: _getSeverityColor(overallSeverity),
                                    fontSize: GlobalStyles.fontSizeBody2,
                                    fontWeight: GlobalStyles.fontWeightBold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "Total Damages",
                            style: TextStyle(
                              fontFamily: GlobalStyles.fontFamilyBody,
                              color: GlobalStyles.textPrimary,
                              fontSize: GlobalStyles.fontSizeBody2,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            () {
                              if (resultData.containsKey('damages')) {
                                final damages = resultData['damages'];
                                if (damages is List) {
                                  return "${damages.length}";
                                } else if (damages is Map) {
                                  return "${damages.length}";
                                }
                              }
                              return "0";
                            }(),
                            style: TextStyle(
                              fontFamily: GlobalStyles.fontFamilyBody,
                              color: GlobalStyles.textPrimary,
                              fontSize: GlobalStyles.fontSizeH4,
                              fontWeight: GlobalStyles.fontWeightBold,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          if (hasCost! &&
                              costEstimate != 'Estimate not available')
                            Text(
                              costEstimate!,
                              style: TextStyle(
                                fontFamily: GlobalStyles.fontFamilyBody,
                                color: GlobalStyles.textPrimary,
                                fontSize: GlobalStyles.fontSizeBody1,
                                fontWeight: GlobalStyles.fontWeightBold,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),
          _buildResultCard(
            title: 'Damage Detection',
            icon: LucideIcons.carFront,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: GlobalStyles.primaryMain.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        'Analysis Complete',
                        style: TextStyle(
                          fontFamily: GlobalStyles.fontFamilyBody,
                          color: GlobalStyles.primaryMain,
                          fontSize: GlobalStyles.fontSizeCaption,
                          fontWeight: GlobalStyles.fontWeightMedium,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                _buildDamageInfoDisplay(damageInfo),
              ],
            ),
          ),
        ],
      );
    } catch (e) {
      return _buildErrorCard('Error displaying results: $e');
    }
  }

  // *** MODIFICATION END ***

  // Build the damage information display based on type
  Widget _buildDamageInfoDisplay(dynamic damageInfo) {
    if (damageInfo is String &&
        damageInfo == 'No damage information available') {
      return Row(
        children: [
          Icon(
            LucideIcons.info,
            color: GlobalStyles.textTertiary,
            size: GlobalStyles.iconSizeSm,
          ),
          SizedBox(width: GlobalStyles.spacingSm),
          Expanded(
            child: Text(
              'No damage information available',
              style: TextStyle(
                fontFamily: GlobalStyles.fontFamilyBody,
                color: GlobalStyles.textTertiary,
                fontSize: GlobalStyles.fontSizeBody1,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      );
    }

    if (damageInfo is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < damageInfo.length; i++)
            _buildDamageListItem(i, damageInfo[i]),
        ],
      );
    }

    if (damageInfo is Map<String, dynamic>) {
      return _buildDamageCard(
        // Using generic card for single map
        title: "DAMAGE DETECTED",
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final entry in damageInfo.entries)
              // Only show damage_type and damaged_part fields
              if (_shouldShowField(entry.key.toString()))
                Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _getFieldIcon(entry.key.toString()),
                          SizedBox(width: 8.w),
                          Text(
                            "${_formatFieldName(entry.key.toString())}:",
                            style: TextStyle(
                              fontFamily: GlobalStyles.fontFamilyBody,
                              color: GlobalStyles.textTertiary,
                              fontSize: GlobalStyles.fontSizeBody2,
                              fontWeight: GlobalStyles.fontWeightSemiBold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      _buildFormattedDamageItem(
                        // Use formatted item for key-value
                        entry.key.toString(),
                        _formatValue(entry.key.toString(), entry.value),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      );
    }

    if (damageInfo is String) {
      // Try parsing if it's a JSON string
      try {
        if (damageInfo.startsWith('[') && damageInfo.endsWith(']')) {
          List<dynamic> damageList = json.decode(damageInfo);
          return _buildDamageInfoDisplay(damageList);
        } else if (damageInfo.startsWith('{') && damageInfo.endsWith('}')) {
          Map<String, dynamic> damageMap = json.decode(damageInfo);
          return _buildDamageInfoDisplay(damageMap);
        }
      } catch (e) {
        // Fall through to default display if parsing fails
      }
    }

    // Default case for unhandled or simple string damageInfo
    return _buildDamageCard(
      title: "DAMAGE DETECTED",
      content: _buildDamageItem(damageInfo.toString()),
    );
  }

  // Optimized list item builder
  Widget _buildDamageListItem(int index, dynamic damage) {
    bool isExpanded = _expandedCards[index] ?? true; // Default to expanded

    if (damage is Map<String, dynamic>) {
      return Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.sp),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.r)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _expandedCards[index] = !isExpanded;
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        "Damage ${index + 1}",
                        style: TextStyle(
                          fontFamily: GlobalStyles.fontFamilyBody,
                          color: GlobalStyles.textSecondary,
                          fontSize: GlobalStyles.fontSizeBody2,
                          fontWeight: GlobalStyles.fontWeightBold,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF2A2A2A),
                    size: 18.sp,
                  ),
                ],
              ),
            ),
            Divider(
              color: Colors.grey.withValues(alpha: 0.3),
              height: 16,
              thickness: 1,
            ),
            if (isExpanded)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final subEntry in damage.entries)
                    if (_shouldShowField(subEntry.key.toString()))
                      Padding(
                        padding: EdgeInsets.only(bottom: 10.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "${_formatFieldName(subEntry.key.toString())}:",
                                  style: TextStyle(
                                    fontFamily: GlobalStyles.fontFamilyBody,
                                    color: GlobalStyles.textTertiary,
                                    fontSize: GlobalStyles.fontSizeBody2,
                                    fontWeight: GlobalStyles.fontWeightSemiBold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            _buildFormattedDamageItem(
                              subEntry.key.toString(),
                              _formatValue(
                                subEntry.key.toString(),
                                subEntry.value,
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
          ],
        ),
      );
    } else {
      return _buildDamageCard(
        title: "Damage ${index + 1}",
        content: _buildDamageItem(damage.toString()),
        index: index,
      );
    }
  }
}
