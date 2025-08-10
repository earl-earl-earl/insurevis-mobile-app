// filepath: c:\Users\Regine Torremoro\Desktop\Earl John\insurevis\lib\other-screens\result_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:insurevis/global_ui_variables.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/providers/assessment_provider.dart';
import 'package:insurevis/utils/pdf_service.dart';
import 'package:insurevis/utils/network_helper.dart';

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
  bool _isGeneratingPdf = false;

  // Add these cached values to prevent reprocessing
  Map<String, dynamic>? _cachedResultData;
  String? _cachedOverallSeverity;
  dynamic _cachedDamageInfo;
  String? _cachedCostEstimate;
  bool? _cachedHasCost;
  late final File _imageFile;

  // Add this to track expanded state for damage cards
  final Map<int, bool> _expandedCards = {};

  // Add these state variables at the top of the class
  final Map<int, String> _selectedRepairOptions =
      {}; // Track repair/replace selection for each damage

  // Add these sample data structures for repair/replace costs
  Map<String, Map<String, dynamic>> _getRepairCosts(
    String damageType,
    String severity,
  ) {
    // Sample cost data - in a real app, this would come from your API or database
    final baseCosts = {
      'bumper': {
        'labor': 150.0,
        'materials': 200.0,
        'paint': 100.0,
        'tools': 50.0,
      },
      'door': {
        'labor': 200.0,
        'materials': 300.0,
        'paint': 150.0,
        'tools': 75.0,
      },
      'fender': {
        'labor': 180.0,
        'materials': 250.0,
        'paint': 120.0,
        'tools': 60.0,
      },
      'hood': {
        'labor': 220.0,
        'materials': 350.0,
        'paint': 180.0,
        'tools': 80.0,
      },
      'mirror': {
        'labor': 100.0,
        'materials': 120.0,
        'paint': 50.0,
        'tools': 30.0,
      },
      'headlight': {
        'labor': 120.0,
        'materials': 180.0,
        'paint': 0.0,
        'tools': 40.0,
      },
      'taillight': {
        'labor': 100.0,
        'materials': 150.0,
        'paint': 0.0,
        'tools': 35.0,
      },
      'windshield': {
        'labor': 250.0,
        'materials': 400.0,
        'paint': 0.0,
        'tools': 100.0,
      },
    };

    // Get base costs for the damage type
    String normalizedType = damageType.toLowerCase();
    Map<String, dynamic>? costs;

    for (String key in baseCosts.keys) {
      if (normalizedType.contains(key)) {
        costs = baseCosts[key];
        break;
      }
    }

    costs ??= {
      'labor': 150.0,
      'materials': 200.0,
      'paint': 100.0,
      'tools': 50.0,
    }; // Default costs

    // Apply severity multiplier
    double multiplier = 1.0;
    String lowerSeverity = severity.toLowerCase();
    if (lowerSeverity.contains('high') || lowerSeverity.contains('severe')) {
      multiplier = 1.5;
    } else if (lowerSeverity.contains('medium') ||
        lowerSeverity.contains('moderate')) {
      multiplier = 1.2;
    }

    return {
      'repair': {
        'labor': costs['labor']! * multiplier,
        'materials':
            costs['materials']! *
            multiplier *
            0.6, // Repair uses less materials
        'paint': costs['paint']! * multiplier, // Paint cost for repair
        'tools': costs['tools']! * multiplier,
        'total':
            (costs['labor']! + costs['materials']! * 0.6 + costs['tools']!) *
            multiplier,
      },
      'replace': {
        'part_price':
            costs['materials']! * multiplier * 1.3, // New part costs more
        'labor': costs['labor']! * multiplier * 0.8, // Replace takes less labor
        'paint':
            costs['paint']! * multiplier * 0.8, // Paint cost for replacement
        'tools': costs['tools']! * multiplier * 0.7, // Fewer tools needed
        'total':
            (costs['materials']! * 1.3 +
                costs['labor']! * 0.8 +
                costs['paint']! * 0.8 +
                costs['tools']! * 0.7) *
            multiplier,
      },
    };
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
    final url = 'https://rooster-faithful-terminally.ngrok-free.app/predict';

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

      // Use NetworkHelper for sending multipart request
      final streamedResponse = await NetworkHelper.sendMultipartRequest(
        url: url,
        filePath: _imageFile.path,
        fileFieldName: 'image_file',
      );

      // DEBUG: print("Response received: ${streamedResponse.statusCode}");

      final response = await http.Response.fromStream(streamedResponse);
      // DEBUG: print("Response body: ${response.body.substring(0, min(100, response.body.length))}...");

      if (response.statusCode == 200) {
        // Process data outside of setState to avoid UI jank
        // DEBUG: print("Success! Processing response...");
        await _processApiResponse(response.body);

        if (mounted) {
          setState(() {
            _apiResponse = response.body;
            _isLoading = false;
          });
        }
      } else {
        // DEBUG: print("Error: ${response.statusCode} - ${response.body}");
        if (mounted) {
          setState(() {
            _apiResponse = 'Error: ${response.statusCode} - ${response.body}';
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

  // Add PDF download functionality
  Future<void> _downloadPdf() async {
    if (_cachedResultData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data available to generate PDF'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final filePath = await PDFService.generateSingleResultPDF(
        imagePath: _imageFile.path,
        apiResponse: _cachedResultData!,
      );

      if (mounted) {
        if (filePath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF downloaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to generate PDF'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isGeneratingPdf = false;
      });
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
            _cachedCostEstimate =
                '₱${(_cachedCostEstimate as num).toStringAsFixed(2)}';
          } else {
            double cost = double.parse(_cachedCostEstimate.toString());
            _cachedCostEstimate = '₱${cost.toStringAsFixed(2)}';
          }
        } catch (e) {
          // If parsing fails, just prepend a dollar sign
          // DEBUG: print("Error formatting cost: $e");
          _cachedCostEstimate = '₱$_cachedCostEstimate';
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
      extendBodyBehindAppBar: true,
      appBar: GlobalStyles.buildCustomAppBar(
        context: context,
        icon: Icons.arrow_back_rounded,
        color: Colors.white,
        appBarBackgroundColor: Colors.transparent,
      ),
      // Only show bottom button when not loading
      bottomNavigationBar:
          _isLoading
              ? null
              : Container(
                color: GlobalStyles.backgroundColorEnd, // Match background
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: ElevatedButton(
                  onPressed: _isGeneratingPdf ? null : _downloadPdf,
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(
                      _isGeneratingPdf
                          ? Colors.grey
                          : GlobalStyles.primaryColor,
                    ),
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    ),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                  child:
                      _isGeneratingPdf
                          ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                "Generating PDF...",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          )
                          : const Text(
                            "Download PDF",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                ),
              ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              GlobalStyles.backgroundColorStart,
              GlobalStyles.backgroundColorEnd,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child:
            _isLoading
                ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: GlobalStyles.primaryColor,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Analyzing damage...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
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
                        const Text(
                          'Damage Assessment',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
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
                                color: Colors.grey[800],
                                child: const Center(
                                  child: Icon(
                                    Icons.error_outline,
                                    color: Colors.white,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: GlobalStyles.primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Error',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
        // Fixed: Removed one extra closing parenthesis here. Was `));`, now `);`
      ),
    );
  }

  // Helper method to build simple damage item display (single string)
  Widget _buildDamageItem(String displayValue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Text(
        displayValue,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }

  // Helper method for rendering formatted damage item (key-value with special handling)
  Widget _buildFormattedDamageItem(String fieldName, String displayValue) {
    if (fieldName.toLowerCase().contains('severity')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _getSeverityColor(displayValue).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getSeverityColor(displayValue).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          _capitalizeFirst(displayValue),
          style: TextStyle(
            color: _getSeverityColor(displayValue),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    }

    // Standard rendering for non-severity fields (can reuse _buildDamageItem logic or keep separate)
    return _buildDamageItem(
      displayValue,
    ); // Or duplicate the Container logic if preferred
  }

  // Format the value based on field name and content
  String _formatValue(String fieldName, dynamic value) {
    if (value == null) return "N/A";
    if (value is bool) return value ? "Yes" : "No";

    // Special handling for damage_type - only show class_name
    final lowerField = fieldName.toLowerCase();
    if (lowerField.contains('damage_type') && value is Map) {
      return value['class_name']?.toString() ?? "Unknown";
    }

    // Format cost values with dollar sign and 2 decimal places
    if (lowerField.contains('cost')) {
      if (value is num) {
        return '₱${value.toStringAsFixed(2)}';
      } else {
        try {
          final numValue = double.parse(value.toString());
          return '₱${numValue.toStringAsFixed(2)}';
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
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
                    style: const TextStyle(
                      color: GlobalStyles.secondaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white70,
                    size: 18,
                  ),
                ],
              ),
            )
          else
            Text(
              title,
              style: const TextStyle(
                color: GlobalStyles.secondaryColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 8),
          if (index == null || isExpanded) content,
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

      final damageInfo = _cachedDamageInfo;
      final costEstimate = _cachedCostEstimate;
      final hasCost = _cachedHasCost;
      final overallSeverity = _cachedOverallSeverity;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultCard(
            title: 'Overall Assessment',
            icon: Icons.analytics,
            content: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getSeverityColor(overallSeverity!).withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getSeverityColor(
                    overallSeverity,
                  ).withValues(alpha: 0.3),
                  width: 1,
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
                          const Text(
                            "Overall Severity",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: _getSeverityColor(
                                    overallSeverity,
                                  ).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _getSeverityColor(
                                      overallSeverity,
                                    ).withValues(alpha: 0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  overallSeverity,
                                  style: TextStyle(
                                    color: _getSeverityColor(overallSeverity),
                                    fontSize: 14,
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
                          const Text(
                            "Total Damages",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            resultData.containsKey('damages') &&
                                    resultData['damages'] is List
                                ? "${(resultData['damages'] as List).length}"
                                : "0", // Fallback if 'damages' is not a list or not present
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            costEstimate!,
                            style: TextStyle(
                              color: hasCost! ? Colors.white : Colors.white70,
                              fontSize: 16,
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
          const SizedBox(height: 16),
          _buildResultCard(
            title: 'Damage Detection',
            icon: Icons.car_crash,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: GlobalStyles.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Analysis complete',
                        style: TextStyle(
                          color: GlobalStyles.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDamageInfoDisplay(damageInfo),
              ],
            ),
          ), // Add some bottom padding
        ],
      );
    } catch (e) {
      // DEBUG: print("Error building results content: $e");
      return _buildErrorCard('Error displaying results: $e');
    }
  }

  // Build the damage information display based on type
  Widget _buildDamageInfoDisplay(dynamic damageInfo) {
    if (damageInfo is String &&
        damageInfo == 'No damage information available') {
      return const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'No damage information available',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
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

    if (damageInfo is Map) {
      return _buildDamageCard(
        // Using generic card for single map
        title: "DAMAGE DETECTED",
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final entry in damageInfo.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _getFieldIcon(entry.key.toString()),
                        const SizedBox(width: 8),
                        Text(
                          "${_formatFieldName(entry.key.toString())}:",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
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
        // DEBUG: print("Error parsing damage info string: $e");
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

    if (damage is Map) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
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
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.green,
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "DAMAGE ${index + 1}",
                        style: const TextStyle(
                          color: GlobalStyles.secondaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white70,
                    size: 18,
                  ),
                ],
              ),
            ),
            Divider(
              color: Colors.white.withValues(alpha: 0.1),
              height: 16,
              thickness: 1,
            ),
            if (isExpanded)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final subEntry in damage.entries)
                    // Skip bounding_box field from display
                    if (subEntry.key.toString().toLowerCase() != 'bounding_box')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _getFieldIcon(subEntry.key.toString()),
                                const SizedBox(width: 8),
                                Text(
                                  "${_formatFieldName(subEntry.key.toString())}:",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Corrected: Use _buildFormattedDamageItem for key-value pairs
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

                  // Add repair/replace section for each damage
                  _buildRepairReplaceSection(
                    index,
                    damage as Map<String, dynamic>,
                  ),
                ],
              ),
          ],
        ),
      );
    } else {
      // Simple list item (e.g., a string) in its own card, can be made collapsible too
      return _buildDamageCard(
        title: "DAMAGE ${index + 1}",
        content: _buildDamageItem(
          damage.toString(),
        ), // Uses the single-argument _buildDamageItem
        index: index, // Allow collapsing for these too
      );
    }
  }

  Widget _buildRepairReplaceSection(
    int damageIndex,
    Map<String, dynamic> damage,
  ) {
    String damageType =
        damage['damage_type']['class_name']?.toString() ??
        damage['part']?.toString() ??
        'Unknown';
    String severity = damage['severity']?.toString() ?? 'medium';

    String selectedOption = _selectedRepairOptions[damageIndex] ?? 'none';
    Map<String, Map<String, dynamic>> costs = _getRepairCosts(
      damageType,
      severity,
    );

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Repair Option:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Repair/Replace Buttons
          Row(
            children: [
              Expanded(
                child: _buildOptionButton(
                  'Repair',
                  Icons.build,
                  selectedOption == 'repair',
                  () {
                    setState(() {
                      _selectedRepairOptions[damageIndex] = 'repair';
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOptionButton(
                  'Replace',
                  Icons.autorenew,
                  selectedOption == 'replace',
                  () {
                    setState(() {
                      _selectedRepairOptions[damageIndex] = 'replace';
                    });
                  },
                ),
              ),
            ],
          ),

          // Cost Breakdown
          if (selectedOption != 'none') ...[
            const SizedBox(height: 16),
            _buildCostBreakdown(selectedOption, costs[selectedOption]!),
          ],
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? GlobalStyles.primaryColor.withValues(alpha: 0.2)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
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
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? GlobalStyles.primaryColor : Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostBreakdown(String option, Map<String, dynamic> costs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GlobalStyles.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: GlobalStyles.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                option == 'repair' ? Icons.build : Icons.autorenew,
                color: GlobalStyles.primaryColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '${option.toUpperCase()} COST BREAKDOWN',
                style: TextStyle(
                  color: GlobalStyles.primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Cost items
          if (option == 'repair') ...[
            _buildCostItem('Labor Cost', costs['labor']),
            _buildCostItem('Materials & Supplies', costs['materials']),
            _buildCostItem('Tools & Equipment', costs['tools']),
          ] else ...[
            _buildCostItem('New Part Price', costs['part_price']),
            _buildCostItem('Installation Labor', costs['labor']),
            _buildCostItem('Paint & Finishing', costs['paint']),
            _buildCostItem('Tools & Equipment', costs['tools']),
          ],

          const Divider(color: Colors.white30, height: 20),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL COST',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₱${costs['total'].toStringAsFixed(2)}',
                style: TextStyle(
                  color: GlobalStyles.primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostItem(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            '₱${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
