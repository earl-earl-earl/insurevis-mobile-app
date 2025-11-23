import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/providers/assessment_provider.dart';
import 'package:insurevis/services/image_upload_service.dart';
import 'package:intl/intl.dart';

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

  // Currency formatter using Philippine peso
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
  );

  String _formatCurrency(double amount) {
    try {
      return _currencyFormatter.format(amount);
    } catch (e) {
      return '₱${amount.toStringAsFixed(2)}';
    }
  }

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
      return Colors.red;
    } else if (lowerSeverity.contains('medium') ||
        lowerSeverity.contains('moderate')) {
      return Colors.orange;
    } else if (lowerSeverity.contains('low') ||
        lowerSeverity.contains('minor')) {
      return Colors.green;
    } else {
      return Colors.blue; // Default color for unknown severity
    }
  }

  Future<void> _processApiResponse(String response) async {
    try {
      final resultData = json.decode(response);
      _cachedResultData = resultData;

      // Debug print to see what's in the response
      // DEBUG: print("API Response Keys: ${resultData.keys.toList()}");
      // DEBUG: print("Total Cost: ${resultData['total_cost']}");

      // Extract damage information
      _cachedDamageInfo = 'No damage information available';
      if (resultData.containsKey('prediction')) {
        _cachedDamageInfo = resultData['prediction'];
      } else if (resultData.containsKey('damages')) {
        _cachedDamageInfo = resultData['damages'];
      } else if (resultData.containsKey('damage')) {
        _cachedDamageInfo = resultData['damage'];
      } else if (resultData.containsKey('result')) {
        _cachedDamageInfo = resultData['result'];
      }

      // Extract cost estimate
      _cachedCostEstimate = 'Estimate not available';
      _cachedHasCost = false;
      if (resultData.containsKey('cost_estimate')) {
        _cachedCostEstimate = resultData['cost_estimate'].toString();
        _cachedHasCost = true;
      } else if (resultData.containsKey('total_cost')) {
        _cachedCostEstimate = resultData['total_cost'].toString();
        _cachedHasCost = true;
      } else if (resultData.containsKey('estimate')) {
        _cachedCostEstimate = resultData['estimate'].toString();
        _cachedHasCost = true;
      }

      // Format cost to have proper dollar sign and commas
      if (_cachedHasCost == true) {
        try {
          if (_cachedCostEstimate is num) {
            _cachedCostEstimate = _formatCurrency(
              (_cachedCostEstimate as num).toDouble(),
            );
          } else {
            double cost = double.parse(_cachedCostEstimate.toString());
            _cachedCostEstimate = _formatCurrency(cost);
          }
        } catch (e) {
          // If parsing fails, prepend a peso sign only if missing
          if (_cachedCostEstimate != null &&
              !_cachedCostEstimate!.startsWith('₱')) {
            _cachedCostEstimate = '₱$_cachedCostEstimate';
          }
        }
      }

      // Extract overall information
      _cachedOverallSeverity = "Unknown";
      if (resultData.containsKey('overall_severity')) {
        _cachedOverallSeverity = _capitalizeFirst(
          resultData['overall_severity'].toString(),
        );
      }
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
          icon: Icon(Icons.arrow_back_rounded, color: const Color(0xFF2A2A2A)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: Colors.white,
        title: Text(
          'Assessment Result',
          style: GoogleFonts.inter(
            color: const Color(0xFF2A2A2A),
            fontWeight: FontWeight.w700,
            fontSize: 20,
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
                        color: GlobalStyles.primaryColor,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Analyzing damage...',
                        style: GoogleFonts.inter(
                          color: const Color.fromARGB(255, 32, 21, 21),
                          fontSize: 16,
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
                                    Icons.error_outline,
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
      padding: EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.black,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          content,
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8.w),
              Text(
                'Error',
                style: GoogleFonts.inter(
                  color: Colors.red,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            message,
            style: GoogleFonts.inter(color: Color(0xFF2A2A2A), fontSize: 14.sp),
          ),
        ],
      ),
    );
  }

  // Helper method to build simple damage item display (single string)
  Widget _buildDamageItem(String displayValue) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.sp),
      decoration: BoxDecoration(
        color: GlobalStyles.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        displayValue,
        style: GoogleFonts.inter(
          color: Color(0xFF2A2A2A),
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
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
          style: GoogleFonts.inter(
            color: _getSeverityColor(displayValue),
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
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

    // Format cost values with dollar sign and 2 decimal places
    if (lowerField.contains('cost')) {
      if (value is num) {
        return _formatCurrency(value.toDouble());
      } else {
        try {
          final numValue = double.parse(value.toString());
          return _formatCurrency(numValue);
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
      return const Icon(Icons.directions_car, color: Colors.blue, size: 16);
    } else if (lowerField.contains('damage_type')) {
      return const Icon(Icons.build, color: Colors.orange, size: 16);
    } else if (lowerField.contains('severity')) {
      return const Icon(Icons.warning, color: Colors.amber, size: 16);
    } else if (lowerField.contains('cost')) {
      return const Icon(Icons.monetization_on, color: Colors.green, size: 16);
    } else if (lowerField.contains('multiplier')) {
      return const Icon(Icons.percent, color: Colors.purple, size: 16);
    } else {
      return const Icon(Icons.info_outline, color: Colors.grey, size: 16);
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
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.r)),
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
                    style: GoogleFonts.inter(
                      color: GlobalStyles.secondaryColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
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
              style: GoogleFonts.inter(
                color: GlobalStyles.secondaryColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
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
      icon: Icons.warning_amber_rounded,
      content: Column(
        children: [
          const Icon(
            Icons.report_problem_outlined,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            "The damage is severe. Please proceed to issuing a claim.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
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
            icon: Icons.analytics,
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
                            style: GoogleFonts.inter(
                              color: Color(0xFF2A2A2A),
                              fontSize: 14.sp,
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
                                  style: GoogleFonts.inter(
                                    color: _getSeverityColor(overallSeverity),
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
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
                            style: GoogleFonts.inter(
                              color: Color(0xFF2A2A2A),
                              fontSize: 14.sp,
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
                            style: GoogleFonts.inter(
                              color: Color(0xFF2A2A2A),
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          if (hasCost! &&
                              costEstimate != 'Estimate not available')
                            Text(
                              costEstimate!,
                              style: GoogleFonts.inter(
                                color: Color(0xFF2A2A2A),
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
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
            icon: Icons.car_crash,
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
                        color: GlobalStyles.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        'Analysis Complete',
                        style: GoogleFonts.inter(
                          color: GlobalStyles.primaryColor,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
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
          const Icon(Icons.info_outline, color: Color(0x772A2A2A), size: 20),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'No damage information available',
              style: GoogleFonts.inter(
                color: Color(0x992A2A2A),
                fontSize: 16.sp,
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
                            style: GoogleFonts.inter(
                              color: Color(0x992A2A2A),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
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
                        style: GoogleFonts.inter(
                          color: GlobalStyles.secondaryColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
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
                                  style: GoogleFonts.inter(
                                    color: Color(0x992A2A2A),
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
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
