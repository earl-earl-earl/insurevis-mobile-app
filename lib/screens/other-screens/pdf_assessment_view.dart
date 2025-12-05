import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:insurevis/utils/pdf_service.dart';
import 'package:insurevis/services/local_storage_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:insurevis/utils/file_writer.dart';
import 'package:insurevis/screens/other-screens/insurance_document_upload.dart';
import 'package:insurevis/utils/pdf_assessment_handler_utils.dart';
import 'package:insurevis/utils/pdf_assessment_widget_utils.dart';

class PDFAssessmentView extends StatefulWidget {
  final List<String>? imagePaths;
  final Map<String, Map<String, dynamic>>? apiResponses;
  final Map<String, String>? assessmentIds;
  final Map<String, String>? vehicleData;

  const PDFAssessmentView({
    super.key,
    this.imagePaths,
    this.apiResponses,
    this.assessmentIds,
    this.vehicleData,
  });

  @override
  State<PDFAssessmentView> createState() => _PDFAssessmentViewState();
}

class _PDFAssessmentViewState extends State<PDFAssessmentView>
    with TickerProviderStateMixin {
  bool _isSaving = false;
  late final PDFAssessmentHandler _handler;
  bool _showAddDamageForm = false;
  String? _newDamagePart;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _carParts = [
    "Back Bumper",
    "Back Door",
    "Back Wheel",
    "Back Window",
    "Back Windshield",
    "Fender",
    "Front Bumper",
    "Front Door",
    "Front Wheel",
    "Front Window",
    "Grille",
    "Headlight",
    "Hood",
    "License Plate",
    "Mirror",
    "Quarter Panel",
    "Rocker Panel",
    "Roof",
    "Tail Light",
    "Trunk",
    "Windshield",
  ];

  // Note: We do not maintain a local list of damage types here; manual damages
  // only require selecting the part, not the type.

  bool get _isDamageSevere => _handler.isDamageSevere(widget.apiResponses);

  @override
  void initState() {
    super.initState();
    _handler = PDFAssessmentHandler();
    _initializeAnimations();
    _initializeRepairOptions();
    _calculateEstimatedDamageCost();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: GlobalStyles.durationNormal,
    );
    _slideController = AnimationController(
      vsync: this,
      duration: GlobalStyles.durationSlow,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: GlobalStyles.easingDecelerate,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: GlobalStyles.easingDecelerate,
      ),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // Helper methods to access handler properties and methods
  String _formatCurrency(double amount) => _handler.formatCurrency(amount);
  String _capitalizeOption(String option) => _handler.capitalizeOption(option);
  String _formatLabel(String raw) => _handler.formatLabel(raw);
  double _parseToDouble(dynamic val) => _handler.parseToDouble(val);
  double _calculateCostForImage(String imagePath) =>
      _handler.calculateCostForImage(imagePath);
  double _calculateTotalFromPricingData() =>
      _handler.calculateTotalFromPricingData();
  Color _getSeverityColor(String severity) =>
      PDFAssessmentWidgetUtils.getSeverityColor(severity);

  Future<void> _fetchPricingForDamage(
    int damageIndex,
    String damagedPart,
    String selectedOption,
  ) async {
    await _handler.fetchPricingForDamage(
      damageIndex,
      damagedPart,
      selectedOption,
    );
    if (mounted) {
      setState(() {
        _calculateEstimatedDamageCost();
      });
    }
  }

  void _calculateEstimatedDamageCost() {
    _handler.calculateEstimatedDamageCost(widget.apiResponses);
    setState(() {});
  }

  void _initializeRepairOptions() {
    _handler.initializeRepairOptions(widget.apiResponses);

    // Fetch pricing for all detected damages
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

    for (var entry in damagesList.asMap().entries) {
      final idx = entry.key;
      final dmg = entry.value;
      String damagedPart = _handler.extractDamagedPart(dmg);
      _fetchPricingForDamage(idx, damagedPart, 'repair');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalStyles.backgroundMain,
      appBar: AppBar(
        backgroundColor: GlobalStyles.surfaceMain,
        elevation: 2,
        shadowColor: GlobalStyles.shadowMd.color,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: GlobalStyles.textPrimary,
            size: GlobalStyles.iconSizeMd,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Assessment Report',
          style: TextStyle(
            fontFamily: GlobalStyles.fontFamilyHeading,
            fontSize: GlobalStyles.fontSizeH5,
            fontWeight: GlobalStyles.fontWeightSemiBold,
            color: GlobalStyles.textPrimary,
            letterSpacing: GlobalStyles.letterSpacingH4,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed:
                _isSaving
                    ? null
                    : () {
                      HapticFeedback.mediumImpact();
                      _savePDF();
                    },
            icon:
                _isSaving
                    ? SizedBox(
                      width: GlobalStyles.iconSizeSm,
                      height: GlobalStyles.iconSizeSm,
                      child: CircularProgressIndicator(
                        color: GlobalStyles.primaryMain,
                        strokeWidth: 2,
                      ),
                    )
                    : Icon(
                      LucideIcons.download,
                      color: GlobalStyles.primaryMain,
                      size: GlobalStyles.iconSizeMd,
                    ),
            tooltip: 'Save PDF Report',
          ),
        ],
      ),
      body: SafeArea(child: _buildAssessmentContent()),
      bottomNavigationBar: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, (1 - value) * 50),
            child: Opacity(opacity: value, child: child),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: GlobalStyles.surfaceMain,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                offset: Offset(0, -2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: GlobalStyles.spacingMd,
              horizontal: GlobalStyles.paddingNormal,
            ),
            child: AnimatedContainer(
              duration: GlobalStyles.durationFast,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _proceedToClaimInsurance();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlobalStyles.primaryMain,
                  foregroundColor: GlobalStyles.surfaceMain,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      GlobalStyles.buttonBorderRadius,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: GlobalStyles.spacingMd,
                    horizontal: GlobalStyles.spacingLg,
                  ),
                  elevation: 4,
                  shadowColor: GlobalStyles.primaryMain.withValues(alpha: 0.3),
                  minimumSize: Size(double.infinity, 56),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Proceed to Claim Insurance',
                      style: TextStyle(
                        fontFamily: GlobalStyles.fontFamilyBody,
                        fontSize: GlobalStyles.fontSizeBody1,
                        fontWeight: GlobalStyles.fontWeightBold,
                        letterSpacing: GlobalStyles.letterSpacingButton,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssessmentContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(GlobalStyles.paddingNormal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(),
              SizedBox(height: GlobalStyles.spacingLg),
              _buildSummarySection(),
              SizedBox(height: GlobalStyles.spacingLg),
              _buildIndividualResults(),
              SizedBox(height: GlobalStyles.spacingLg),
              if (!_isDamageSevere) ...[
                _buildRepairOptionsSection(),
                SizedBox(height: GlobalStyles.spacingLg),
              ],
              _buildOverallAssessment(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GlobalStyles.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Vehicle Damage Assessment Report',
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyBody,
                  fontSize: GlobalStyles.fontSizeBody2,
                  fontWeight: GlobalStyles.fontWeightBold,
                  color: GlobalStyles.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: GlobalStyles.spacingMd),
          Text(
            'Generated on: ${DateTime.now().toString().substring(0, 19)}',
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyBody,
              fontSize: GlobalStyles.fontSizeCaption,
              color: GlobalStyles.textTertiary,
              fontWeight: GlobalStyles.fontWeightSemiBold,
            ),
          ),
          Text(
            'Total Images Analyzed: ${(widget.imagePaths ?? const <String>[]).length}',
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyBody,
              fontSize: GlobalStyles.fontSizeCaption,
              color: GlobalStyles.textTertiary,
              fontWeight: GlobalStyles.fontWeightSemiBold,
            ),
          ),
          SizedBox(height: GlobalStyles.spacingMd),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: GlobalStyles.easingDecelerate,
            builder: (context, value, child) {
              return Container(
                height: 3,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      GlobalStyles.primaryMain,
                      GlobalStyles.primaryMain.withValues(alpha: 0.0),
                    ],
                    stops: [value * 0.7, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(GlobalStyles.radiusFull),
                ),
              );
            },
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

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: GlobalStyles.easingDecelerate,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 20),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        padding: EdgeInsets.all(GlobalStyles.spacingMd),
        decoration: BoxDecoration(
          color: GlobalStyles.surfaceMain,
          borderRadius: BorderRadius.circular(GlobalStyles.radiusLg),
          boxShadow: [GlobalStyles.shadowMd],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(GlobalStyles.spacingSm),
                  decoration: BoxDecoration(
                    color: GlobalStyles.primaryMain.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(GlobalStyles.radiusSm),
                  ),
                  child: Icon(
                    LucideIcons.layoutGrid,
                    color: GlobalStyles.primaryMain,
                    size: GlobalStyles.iconSizeSm,
                  ),
                ),
                SizedBox(width: GlobalStyles.spacingSm),
                Text(
                  'Summary',
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyHeading,
                    fontSize: GlobalStyles.fontSizeBody1,
                    fontWeight: GlobalStyles.fontWeightBold,
                    color: GlobalStyles.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: GlobalStyles.spacingMd),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(
                    width: 180,
                    child: _buildSummaryCard(
                      'Estimated Cost',
                      _isDamageSevere
                          ? 'Mechanic'
                          : (_handler.estimatedDamageCost > 0
                              ? _formatCurrency(_handler.estimatedDamageCost)
                              : _formatCurrency(totalCost)),
                      LucideIcons.dollarSign,
                      _isDamageSevere
                          ? GlobalStyles.warningMain
                          : GlobalStyles.successMain,
                    ),
                  ),
                  SizedBox(width: GlobalStyles.spacingMd),
                  SizedBox(
                    width: 160,
                    child: _buildSummaryCard(
                      'Total Damages',
                      totalDamages.toString(),
                      LucideIcons.circleAlert,
                      GlobalStyles.errorMain,
                    ),
                  ),
                  SizedBox(width: GlobalStyles.spacingMd),
                  SizedBox(
                    width: 160,
                    child: _buildSummaryCard(
                      'Images',
                      (widget.imagePaths ?? const <String>[]).length.toString(),
                      LucideIcons.image,
                      GlobalStyles.infoMain,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, animValue, child) {
        return Transform.scale(scale: animValue, child: child);
      },
      child: Container(
        padding: EdgeInsets.all(GlobalStyles.spacingMd),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.12),
              color.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              offset: Offset(0, 2),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(GlobalStyles.spacingSm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: GlobalStyles.iconSizeSm),
            ),
            SizedBox(height: GlobalStyles.spacingSm),
            Text(
              value,
              style: TextStyle(
                fontFamily: GlobalStyles.fontFamilyHeading,
                fontSize: GlobalStyles.fontSizeBody2,
                fontWeight: GlobalStyles.fontWeightBold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: GlobalStyles.spacingXs),
            Text(
              label,
              style: TextStyle(
                fontFamily: GlobalStyles.fontFamilyBody,
                fontSize: GlobalStyles.fontSizeCaption,
                color: GlobalStyles.textSecondary,
                fontWeight: GlobalStyles.fontWeightMedium,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndividualResults() {
    final images = widget.imagePaths ?? const <String>[];
    if (images.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(GlobalStyles.spacingSm),
              decoration: BoxDecoration(
                color: GlobalStyles.infoMain.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(GlobalStyles.radiusSm),
              ),
              child: Icon(
                LucideIcons.images,
                color: GlobalStyles.infoMain,
                size: GlobalStyles.iconSizeMd,
              ),
            ),
            SizedBox(width: GlobalStyles.spacingMd),
            Text(
              'Individual Image Results',
              style: TextStyle(
                fontFamily: GlobalStyles.fontFamilyHeading,
                fontSize: GlobalStyles.fontSizeH6,
                fontWeight: GlobalStyles.fontWeightBold,
                color: GlobalStyles.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: GlobalStyles.spacingLg),
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
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (imageNumber * 100)),
      curve: GlobalStyles.easingDecelerate,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 30),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: GlobalStyles.spacingLg),
        decoration: BoxDecoration(
          color: GlobalStyles.surfaceMain,
          borderRadius: BorderRadius.circular(GlobalStyles.radiusLg),
          border: Border.all(
            color: GlobalStyles.primaryMain.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [GlobalStyles.shadowMd],
        ),
        child: Padding(
          padding: EdgeInsets.all(GlobalStyles.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
                    child: SizedBox(
                      width: GlobalStyles.spacingXxxl,
                      height: GlobalStyles.spacingXxxl,
                      child: Image.file(File(imagePath), fit: BoxFit.cover),
                    ),
                  ),
                  SizedBox(width: GlobalStyles.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Image $imageNumber',
                          style: TextStyle(
                            fontFamily: GlobalStyles.fontFamilyBody,
                            fontSize: GlobalStyles.fontSizeBody1,
                            fontWeight: GlobalStyles.fontWeightBold,
                            color: GlobalStyles.textPrimary,
                          ),
                        ),
                        if (response != null) ...[
                          SizedBox(height: GlobalStyles.spacingXs),
                          if (response.containsKey('overall_severity'))
                            Text(
                              'Severity: ${_formatLabel(response['overall_severity']?.toString() ?? '')}',
                              style: TextStyle(
                                fontFamily: GlobalStyles.fontFamilyBody,
                                fontSize: GlobalStyles.fontSizeCaption,
                                fontWeight: GlobalStyles.fontWeightSemiBold,
                                color: _getSeverityColor(
                                  response['overall_severity'].toString(),
                                ),
                              ),
                            ),
                          // Calculate cost based on user selections and fetched pricing
                          Builder(
                            builder: (context) {
                              if (_isDamageSevere) {
                                return Text(
                                  'Cost: To be given by the mechanic',
                                  style: TextStyle(
                                    fontFamily: GlobalStyles.fontFamilyBody,
                                    fontSize: GlobalStyles.fontSizeCaption,
                                    color: GlobalStyles.warningMain,
                                  ),
                                );
                              }

                              final calculatedCost = _calculateCostForImage(
                                imagePath,
                              );

                              // If we have calculated pricing data, use it; otherwise fall back to API response
                              if (calculatedCost > 0) {
                                return Text(
                                  'Cost: ${_formatCurrency(calculatedCost)}',
                                  style: TextStyle(
                                    fontFamily: GlobalStyles.fontFamilyBody,
                                    fontSize: GlobalStyles.fontSizeCaption,
                                    color: GlobalStyles.successMain,
                                  ),
                                );
                              } else if (response.containsKey('total_cost')) {
                                // Fallback to API response if pricing not yet loaded
                                return Text(
                                  'Cost: ${_formatCurrency(_parseToDouble(response['total_cost']))}',
                                  style: TextStyle(
                                    fontFamily: GlobalStyles.fontFamilyBody,
                                    fontSize: GlobalStyles.fontSizeCaption,
                                    color: GlobalStyles.successMain,
                                  ),
                                );
                              }

                              return const SizedBox.shrink();
                            },
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
                SizedBox(height: GlobalStyles.spacingMd),
                Text(
                  'Detected Damages:',
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyBody,
                    fontSize: GlobalStyles.fontSizeCaption,
                    fontWeight: GlobalStyles.fontWeightSemiBold,
                    color: GlobalStyles.textPrimary,
                  ),
                ),
                SizedBox(height: GlobalStyles.spacingSm),
                ..._buildDamagesList(response['damages']),
              ],
            ],
          ),
        ),
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
        padding: EdgeInsets.only(bottom: GlobalStyles.spacingXs),
        child: Row(
          children: [
            Icon(
              LucideIcons.circle,
              color: GlobalStyles.warningMain,
              size: GlobalStyles.fontSizeBody2,
            ),
            SizedBox(width: GlobalStyles.spacingSm),
            Expanded(
              child: Text(
                damageText,
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyBody,
                  fontSize: GlobalStyles.fontSizeBody2,
                  color: GlobalStyles.textTertiary,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildOverallAssessment() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: GlobalStyles.easingDecelerate,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 20),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        padding: EdgeInsets.all(GlobalStyles.spacingMd),
        decoration: BoxDecoration(
          color: GlobalStyles.surfaceMain,
          borderRadius: BorderRadius.circular(GlobalStyles.radiusLg),
          border: Border.all(
            color: GlobalStyles.primaryMain.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [GlobalStyles.shadowMd],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(GlobalStyles.spacingSm),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        GlobalStyles.primaryMain.withValues(alpha: 0.2),
                        GlobalStyles.primaryMain.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
                  ),
                  child: Icon(
                    LucideIcons.clipboardCheck,
                    color: GlobalStyles.primaryMain,
                    size: GlobalStyles.iconSizeMd,
                  ),
                ),
                SizedBox(width: GlobalStyles.spacingMd),
                Text(
                  'Overall Assessment',
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyHeading,
                    fontSize: GlobalStyles.fontSizeH5,
                    fontWeight: GlobalStyles.fontWeightBold,
                    color: GlobalStyles.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: GlobalStyles.spacingMd),
            Container(
              padding: EdgeInsets.all(GlobalStyles.spacingMd),
              decoration: BoxDecoration(
                color: GlobalStyles.primaryMain.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
                border: Border.all(
                  color: GlobalStyles.primaryMain.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                'This assessment report contains the analysis of ${(widget.imagePaths ?? const <String>[]).length} vehicle images. '
                'The damage detection was performed using AI-powered analysis to identify potential '
                'vehicle damages and provide cost estimates for repair or replacement.',
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyBody,
                  fontSize: GlobalStyles.fontSizeBody2,
                  color: GlobalStyles.textPrimary,
                  height: 1.6,
                ),
              ),
            ),
            SizedBox(height: GlobalStyles.spacingMd),
            Row(
              children: [
                Icon(
                  LucideIcons.info,
                  color: GlobalStyles.warningMain,
                  size: GlobalStyles.fontSizeBody2,
                ),
                SizedBox(width: GlobalStyles.spacingSm),
                Expanded(
                  child: Text(
                    'This assessment is for estimation purposes only. Professional inspection is recommended.',
                    style: TextStyle(
                      fontFamily: GlobalStyles.fontFamilyBody,
                      fontSize: GlobalStyles.fontSizeCaption,
                      color: GlobalStyles.warningMain,
                      fontWeight: GlobalStyles.fontWeightMedium,
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(GlobalStyles.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Repair Options (Manual)',
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyBody,
                    fontSize: GlobalStyles.fontSizeCaption,
                    fontWeight: GlobalStyles.fontWeightBold,
                    color: GlobalStyles.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: GlobalStyles.spacingMd),
            Text(
              'No AI-detected damages found. Add manual damages below to estimate costs.',
              style: TextStyle(
                fontFamily: GlobalStyles.fontFamilyBody,
                fontSize: GlobalStyles.fontSizeCaption,
                color: GlobalStyles.textTertiary,
              ),
            ),
            SizedBox(height: GlobalStyles.spacingMd),
            if (!_showAddDamageForm)
              SizedBox(
                width: double.infinity,
                height: GlobalStyles.spacingXxl,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _showAddDamageForm = true),
                  icon: Icon(
                    LucideIcons.plus,
                    color: GlobalStyles.surfaceMain,
                    size: GlobalStyles.fontSizeH6,
                  ),
                  label: Text(
                    'Add Damage',
                    style: TextStyle(
                      fontFamily: GlobalStyles.fontFamilyBody,
                      color: GlobalStyles.surfaceMain,
                      fontSize: GlobalStyles.fontSizeCaption,
                      fontWeight: GlobalStyles.fontWeightSemiBold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlobalStyles.primaryMain,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        GlobalStyles.radiusMd,
                      ),
                    ),
                  ),
                ),
              ),
            if (_showAddDamageForm) _buildAddDamageForm(),
            // Render manual damages (use negative global indices so they don't clash
            // with API damage indices which are >= 0)
            ..._handler.manualDamages.asMap().entries.map((e) {
              final displayedIndex = e.key;
              final globalIndex = -(displayedIndex + 1);
              return _buildManualDamageRepairOption(globalIndex, e.value);
            }).toList(),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GlobalStyles.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Repair Options',
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyHeading,
                  fontSize: GlobalStyles.fontSizeH6,
                  fontWeight: GlobalStyles.fontWeightBold,
                  color: GlobalStyles.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: GlobalStyles.spacingMd),
          Text(
            'Select your preferred option for each damaged part to calculate accurate cost estimates.',
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyBody,
              fontSize: GlobalStyles.fontSizeBody2,
              color: GlobalStyles.textTertiary,
              height: 1.5,
            ),
          ),
          SizedBox(height: GlobalStyles.spacingLg),
          for (int index = 0; index < damagesList.length; index++)
            _buildDamageRepairOption(index, damagesList[index]),
          SizedBox(height: GlobalStyles.spacingMd),
          // Always show manual repair options below detected damages so users can
          // add or remove manual damages in addition to AI-detected ones.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Manual Damages',
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyBody,
                  fontSize: GlobalStyles.fontSizeH6,
                  fontWeight: GlobalStyles.fontWeightBold,
                  color: GlobalStyles.textPrimary,
                ),
              ),
              SizedBox(height: GlobalStyles.spacingLg),

              if (!_showAddDamageForm)
                SizedBox(
                  width: double.infinity,
                  height: GlobalStyles.spacingXxl,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _showAddDamageForm = true),
                    icon: Icon(
                      LucideIcons.plus,
                      color: GlobalStyles.surfaceMain,
                      size: GlobalStyles.fontSizeH6,
                    ),
                    label: Text(
                      'Add',
                      style: TextStyle(
                        fontFamily: GlobalStyles.fontFamilyBody,
                        color: GlobalStyles.surfaceMain,
                        fontSize: GlobalStyles.fontSizeCaption,
                        fontWeight: GlobalStyles.fontWeightSemiBold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlobalStyles.primaryMain,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          GlobalStyles.radiusMd,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: GlobalStyles.spacingMd),
          if (_showAddDamageForm) _buildAddDamageForm(),
          // Render manual damages with negative indices
          ..._handler.manualDamages.asMap().entries.map((e) {
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
    String? selectedOption = _handler.selectedRepairOptions[index];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: GlobalStyles.easingDecelerate,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 20),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: GlobalStyles.spacingMd),
        padding: EdgeInsets.all(GlobalStyles.spacingMd),
        decoration: BoxDecoration(
          color: GlobalStyles.surfaceMain,
          borderRadius: BorderRadius.circular(GlobalStyles.radiusLg),
          border: Border.all(
            color: GlobalStyles.primaryMain.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [GlobalStyles.shadowMd],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "Damage ${index + 1}",
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyHeading,
                    color: GlobalStyles.textPrimary,
                    fontSize: GlobalStyles.fontSizeBody2,
                    fontWeight: GlobalStyles.fontWeightBold,
                  ),
                ),
              ],
            ),
            SizedBox(height: GlobalStyles.spacingSm),
            _buildDamageInfo(damagedPart, damageType),
            SizedBox(height: GlobalStyles.spacingSm),
            Row(
              children: [
                Expanded(
                  child: _buildOptionButton(
                    'Repair',
                    LucideIcons.wrench,
                    selectedOption == 'repair',
                    () {
                      setState(
                        () => _handler.selectedRepairOptions[index] = 'repair',
                      );
                      if (!_handler.repairPricingData.containsKey(index) &&
                          damagedPart != 'Unknown Part') {
                        _fetchPricingForDamage(index, damagedPart, 'repair');
                      } else {
                        _calculateEstimatedDamageCost();
                      }
                    },
                    GlobalStyles.infoMain,
                  ),
                ),
                SizedBox(width: GlobalStyles.spacingSm),
                Expanded(
                  child: _buildOptionButton(
                    'Replace',
                    LucideIcons.refreshCw,
                    selectedOption == 'replace',
                    () {
                      setState(
                        () => _handler.selectedRepairOptions[index] = 'replace',
                      );
                      if (!_handler.replacePricingData.containsKey(index) &&
                          damagedPart != 'Unknown Part') {
                        _fetchPricingForDamage(index, damagedPart, 'replace');
                      } else {
                        _calculateEstimatedDamageCost();
                      }
                    },
                    GlobalStyles.warningMain,
                  ),
                ),
              ],
            ),
            SizedBox(height: GlobalStyles.spacingSm),
            // Show pricing breakdown
            Builder(
              builder: (context) {
                final isLoading = _handler.isLoadingPricing[index] ?? false;
                final repairData = _handler.repairPricingData[index];
                final replacePricing = _handler.replacePricingData[index];

                if (isLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: GlobalStyles.primaryMain,
                    ),
                  );
                }

                if (selectedOption == 'repair') {
                  if (repairData != null &&
                      _hasValidPricingData(repairData, 'repair')) {
                    return _buildApiCostBreakdown(
                      'repair',
                      repairData,
                      damage,
                      null,
                    );
                  } else {
                    return Container(
                      padding: EdgeInsets.all(GlobalStyles.spacingMd),
                      decoration: BoxDecoration(
                        color: GlobalStyles.warningMain.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          GlobalStyles.radiusMd,
                        ),
                        border: Border.all(
                          color: GlobalStyles.warningMain.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.circleAlert,
                            color: GlobalStyles.warningMain,
                            size: GlobalStyles.fontSizeH6,
                          ),
                          SizedBox(width: GlobalStyles.spacingSm),
                          Expanded(
                            child: Text(
                              'Repair option is not applicable for $damagedPart',
                              style: TextStyle(
                                fontFamily: GlobalStyles.fontFamilyBody,
                                color: GlobalStyles.warningMain,
                                fontSize: GlobalStyles.fontSizeBody2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                } else if (selectedOption == 'replace') {
                  if (replacePricing != null &&
                      _hasValidPricingData(replacePricing, 'replace')) {
                    return _buildApiCostBreakdown(
                      'replace',
                      replacePricing,
                      damage,
                      repairData,
                    );
                  } else {
                    return Container(
                      padding: EdgeInsets.all(GlobalStyles.spacingMd),
                      decoration: BoxDecoration(
                        color: GlobalStyles.warningMain.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          GlobalStyles.radiusMd,
                        ),
                        border: Border.all(
                          color: GlobalStyles.warningMain.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.circleAlert,
                            color: GlobalStyles.warningMain,
                            size: GlobalStyles.fontSizeH6,
                          ),
                          SizedBox(width: GlobalStyles.spacingSm),
                          Expanded(
                            child: Text(
                              'Replace option is not applicable for $damagedPart',
                              style: TextStyle(
                                fontFamily: GlobalStyles.fontFamilyBody,
                                color: GlobalStyles.warningMain,
                                fontSize: GlobalStyles.fontSizeBody2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                }

                return SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDamageInfo(String damagedPart, String damageType) {
    return Container(
      padding: EdgeInsets.all(GlobalStyles.spacingMd),
      decoration: BoxDecoration(
        color: GlobalStyles.primaryMain.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
        border: Border.all(color: GlobalStyles.surfaceMain.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.car,
                color: GlobalStyles.infoMain,
                size: GlobalStyles.fontSizeBody1,
              ),
              SizedBox(width: GlobalStyles.spacingSm),
              Text(
                'Damaged Part: ',
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyBody,
                  color: GlobalStyles.textTertiary,
                  fontSize: GlobalStyles.fontSizeCaption,
                ),
              ),
              Expanded(
                child: Text(
                  damagedPart,
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyBody,
                    color: GlobalStyles.textPrimary,
                    fontSize: GlobalStyles.fontSizeCaption,
                    fontWeight: GlobalStyles.fontWeightSemiBold,
                  ),
                ),
              ),
            ],
          ),
          if (damageType.trim().isNotEmpty) ...[
            SizedBox(height: GlobalStyles.spacingSm),
            Row(
              children: [
                Icon(
                  LucideIcons.wrench,
                  color: GlobalStyles.warningMain,
                  size: GlobalStyles.fontSizeBody1,
                ),
                SizedBox(width: GlobalStyles.spacingSm),
                Text(
                  'Damage Type: ',
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyBody,
                    color: GlobalStyles.textTertiary,
                    fontSize: GlobalStyles.fontSizeCaption,
                  ),
                ),
                Expanded(
                  child: Text(
                    damageType,
                    style: TextStyle(
                      fontFamily: GlobalStyles.fontFamilyBody,
                      color: GlobalStyles.textPrimary,
                      fontSize: GlobalStyles.fontSizeCaption,
                      fontWeight: GlobalStyles.fontWeightSemiBold,
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
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: GlobalStyles.durationNormal,
      curve: GlobalStyles.easingDecelerate,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: EdgeInsets.only(
          top: GlobalStyles.spacingMd,
          bottom: GlobalStyles.spacingMd,
        ),
        padding: EdgeInsets.all(GlobalStyles.spacingLg),
        decoration: BoxDecoration(
          color: GlobalStyles.surfaceMain,
          borderRadius: BorderRadius.circular(GlobalStyles.radiusLg),
          border: Border.all(
            color: GlobalStyles.primaryMain.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [GlobalStyles.shadowMd],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Damage',
              style: TextStyle(
                fontFamily: GlobalStyles.fontFamilyBody,
                color: GlobalStyles.textPrimary,
                fontWeight: GlobalStyles.fontWeightBold,
              ),
            ),
            SizedBox(height: GlobalStyles.spacingSm),
            Container(
              padding: EdgeInsets.symmetric(horizontal: GlobalStyles.spacingMd),
              decoration: BoxDecoration(
                color: GlobalStyles.primaryMain.withAlpha((0.04 * 255).toInt()),
                borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
              ),
              child: DropdownButton<String>(
                value: _newDamagePart,
                hint: Text(
                  'Select part',
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyBody,
                    color: GlobalStyles.textTertiary,
                    fontSize: GlobalStyles.fontSizeBody1,
                  ),
                ),
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyBody,
                  color: GlobalStyles.textPrimary,
                  fontSize: GlobalStyles.fontSizeBody1,
                ),
                isExpanded: true,
                dropdownColor: GlobalStyles.surfaceMain,
                underline: const SizedBox.shrink(),
                items:
                    _carParts
                        .map(
                          (p) => DropdownMenuItem<String>(
                            value: p,
                            child: Text(
                              _formatLabel(p),
                              style: TextStyle(
                                fontFamily: GlobalStyles.fontFamilyBody,
                                color: GlobalStyles.textPrimary,
                                fontSize: GlobalStyles.fontSizeBody1,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (val) => setState(() => _newDamagePart = val),
              ),
            ),
            SizedBox(height: GlobalStyles.spacingSm),
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
                                _handler.manualDamages.add(map);
                                final newIndex =
                                    _handler.manualDamages.length - 1;
                                final globalIndex = -(newIndex + 1);
                                // default manual damage to 'repair' so it contributes to totals
                                _handler.selectedRepairOptions[globalIndex] =
                                    'repair';
                                _fetchPricingForDamage(
                                  globalIndex,
                                  _newDamagePart!,
                                  'repair',
                                );
                                _showAddDamageForm = false;
                                _newDamagePart = null;
                                // no damage type field maintained
                              });
                            },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateColor.resolveWith((states) {
                        if (states.contains(WidgetState.disabled)) {
                          return GlobalStyles.primaryMain.withValues(
                            alpha: GlobalStyles.disabledOpacity,
                          );
                        }
                        return GlobalStyles.primaryMain;
                      }),
                      foregroundColor: WidgetStateProperty.all<Color>(
                        GlobalStyles.surfaceMain,
                      ),
                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            GlobalStyles.radiusMd,
                          ),
                        ),
                      ),
                    ),
                    child: Text(
                      'Add',
                      style: TextStyle(
                        fontFamily: GlobalStyles.fontFamilyBody,
                        color: GlobalStyles.surfaceMain,
                        fontSize: GlobalStyles.fontSizeCaption,
                        fontWeight: GlobalStyles.fontWeightSemiBold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: GlobalStyles.spacingMd),
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        () => setState(() {
                          _showAddDamageForm = false;
                          _newDamagePart = null;
                        }),
                    style: ButtonStyle(
                      shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            GlobalStyles.radiusMd,
                          ),
                        ),
                      ),
                      side: WidgetStatePropertyAll<BorderSide>(BorderSide.none),
                      backgroundColor: WidgetStatePropertyAll<Color>(
                        GlobalStyles.primaryMain.withValues(alpha: 0.15),
                      ),
                      foregroundColor: WidgetStatePropertyAll<Color>(
                        GlobalStyles.primaryMain,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: GlobalStyles.fontFamilyBody,
                        color: GlobalStyles.primaryMain,
                        fontSize: GlobalStyles.fontSizeCaption,
                        fontWeight: GlobalStyles.fontWeightSemiBold,
                      ),
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

  Widget _buildManualDamageRepairOption(
    int globalIndex,
    Map<String, String> damage,
  ) {
    final damagedPart = damage['damaged_part'] ?? 'Unknown Part';
    final damageType = damage['damage_type'] ?? 'Unknown Damage';
    String? selectedOption = _handler.selectedRepairOptions[globalIndex];

    return Container(
      margin: EdgeInsets.symmetric(vertical: GlobalStyles.spacingMd),
      padding: EdgeInsets.all(GlobalStyles.spacingMd),
      decoration: BoxDecoration(
        color: GlobalStyles.surfaceMain,
        borderRadius: BorderRadius.circular(GlobalStyles.radiusLg),
        border: Border.all(
          color: GlobalStyles.primaryMain.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [GlobalStyles.shadowMd],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Manual Damage',
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyBody,
                  color: GlobalStyles.textSecondary,
                  fontSize: GlobalStyles.fontSizeH6,
                  fontWeight: GlobalStyles.fontWeightBold,
                ),
              ),
              Spacer(),
              // Remove (minus) icon for manual damage
              IconButton(
                onPressed: () {
                  // Convert negative globalIndex back to displayed index in _handler.manualDamages
                  final displayedIndex = -(globalIndex) - 1;
                  if (displayedIndex >= 0 &&
                      displayedIndex < _handler.manualDamages.length) {
                    setState(() {
                      // remove manual damage
                      _handler.manualDamages.removeAt(displayedIndex);

                      // Clear any existing manual-related state (negative keys)
                      _handler.selectedRepairOptions.keys
                          .where((k) => k < 0)
                          .toList()
                          .forEach(_handler.selectedRepairOptions.remove);
                      _handler.repairPricingData.keys
                          .where((k) => k < 0)
                          .toList()
                          .forEach(_handler.repairPricingData.remove);
                      _handler.replacePricingData.keys
                          .where((k) => k < 0)
                          .toList()
                          .forEach(_handler.replacePricingData.remove);
                      _handler.isLoadingPricing.keys
                          .where((k) => k < 0)
                          .toList()
                          .forEach(_handler.isLoadingPricing.remove);

                      // Re-initialize remaining manual damages: default to 'repair' and fetch pricing
                      for (var entry
                          in _handler.manualDamages.asMap().entries) {
                        final newDisplayed = entry.key;
                        final newGlobal = -(newDisplayed + 1);
                        // set default selection if not present
                        _handler.selectedRepairOptions[newGlobal] =
                            _handler.selectedRepairOptions[newGlobal] ??
                            'repair';
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
                  LucideIcons.circleX,
                  color: GlobalStyles.errorMain,
                  size: GlobalStyles.fontSizeH6,
                ),
                tooltip: 'Remove manual damage',
              ),
            ],
          ),
          SizedBox(height: GlobalStyles.spacingMd),
          _buildDamageInfo(damagedPart, damageType),
          SizedBox(height: GlobalStyles.spacingMd),
          Row(
            children: [
              Expanded(
                child: _buildOptionButton(
                  'Repair',
                  LucideIcons.wrench,
                  selectedOption == 'repair',
                  () {
                    setState(
                      () =>
                          _handler.selectedRepairOptions[globalIndex] =
                              'repair',
                    );
                    if (!_handler.repairPricingData.containsKey(globalIndex) &&
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
                  GlobalStyles.infoMain,
                ),
              ),
              SizedBox(width: GlobalStyles.spacingMd),
              Expanded(
                child: _buildOptionButton(
                  'Replace',
                  LucideIcons.refreshCw,
                  selectedOption == 'replace',
                  () {
                    setState(
                      () =>
                          _handler.selectedRepairOptions[globalIndex] =
                              'replace',
                    );
                    if (!_handler.replacePricingData.containsKey(globalIndex) &&
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
                  GlobalStyles.warningMain,
                ),
              ),
            ],
          ),
          SizedBox(height: GlobalStyles.spacingMd),
          // Show pricing breakdown for manual damages
          Builder(
            builder: (context) {
              final isLoading = _handler.isLoadingPricing[globalIndex] ?? false;
              final repairData = _handler.repairPricingData[globalIndex];
              final replacePricing = _handler.replacePricingData[globalIndex];

              if (isLoading) {
                return Center(
                  child: CircularProgressIndicator(
                    color: GlobalStyles.primaryMain,
                  ),
                );
              }

              if (selectedOption == 'repair') {
                if (repairData != null &&
                    _hasValidPricingData(repairData, 'repair')) {
                  // Create a dummy damage map for manual damage
                  final manualDamageMap = {
                    'damaged_part': damagedPart,
                    'damage_type': damageType,
                  };
                  return _buildApiCostBreakdown(
                    'repair',
                    repairData,
                    manualDamageMap,
                    null,
                  );
                } else {
                  return Container(
                    padding: EdgeInsets.all(GlobalStyles.spacingMd),
                    decoration: BoxDecoration(
                      color: GlobalStyles.warningMain.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        GlobalStyles.radiusMd,
                      ),
                      border: Border.all(
                        color: GlobalStyles.warningMain.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.circleAlert,
                          color: GlobalStyles.warningMain,
                          size: GlobalStyles.fontSizeH6,
                        ),
                        SizedBox(width: GlobalStyles.spacingSm),
                        Expanded(
                          child: Text(
                            'Repair option is not applicable for $damagedPart',
                            style: TextStyle(
                              fontFamily: GlobalStyles.fontFamilyBody,
                              color: GlobalStyles.warningMain,
                              fontSize: GlobalStyles.fontSizeBody2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              } else if (selectedOption == 'replace') {
                if (replacePricing != null &&
                    _hasValidPricingData(replacePricing, 'replace')) {
                  // Create a dummy damage map for manual damage
                  final manualDamageMap = {
                    'damaged_part': damagedPart,
                    'damage_type': damageType,
                  };
                  return _buildApiCostBreakdown(
                    'replace',
                    replacePricing,
                    manualDamageMap,
                    repairData,
                  );
                } else {
                  return Container(
                    padding: EdgeInsets.all(GlobalStyles.spacingMd),
                    decoration: BoxDecoration(
                      color: GlobalStyles.warningMain.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        GlobalStyles.radiusMd,
                      ),
                      border: Border.all(
                        color: GlobalStyles.warningMain.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.circleAlert,
                          color: GlobalStyles.warningMain,
                          size: GlobalStyles.fontSizeH6,
                        ),
                        SizedBox(width: GlobalStyles.spacingSm),
                        Expanded(
                          child: Text(
                            'Replace option is not applicable for $damagedPart',
                            style: TextStyle(
                              fontFamily: GlobalStyles.fontFamilyBody,
                              color: GlobalStyles.warningMain,
                              fontSize: GlobalStyles.fontSizeBody2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              }

              return SizedBox.shrink();
            },
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
    Color color,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
        splashColor: color.withValues(alpha: 0.2),
        highlightColor: color.withValues(alpha: 0.1),
        child: AnimatedContainer(
          duration: GlobalStyles.durationFast,
          curve: GlobalStyles.easingStandard,
          padding: EdgeInsets.symmetric(
            vertical: GlobalStyles.spacingSm,
            horizontal: GlobalStyles.spacingMd,
          ),
          decoration: BoxDecoration(
            gradient:
                isSelected
                    ? LinearGradient(
                      colors: [color, color.withValues(alpha: 0.85)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                    : null,
            color: isSelected ? null : GlobalStyles.surfaceMain,
            borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
            border: Border.all(color: color, width: isSelected ? 2.5 : 2),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: 1,
                      ),
                    ]
                    : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: GlobalStyles.durationFast,
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Icon(
                  icon,
                  color: isSelected ? GlobalStyles.surfaceMain : color,
                  size: GlobalStyles.iconSizeSm,
                ),
              ),
              SizedBox(width: GlobalStyles.spacingSm),
              Text(
                title,
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyBody,
                  color: isSelected ? GlobalStyles.surfaceMain : color,
                  fontSize: GlobalStyles.fontSizeCaption,
                  fontWeight: GlobalStyles.fontWeightBold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApiCostBreakdown(
    String option,
    Map<String, dynamic> apiPricing,
    Map<String, dynamic> damage, // Add damage parameter
    Map<String, dynamic>? bodyPaintPricing, // Add body-paint pricing for repair
  ) {
    double laborFee = 0.0;
    double finalPrice = 0.0;
    double bodyPaintPrice = 0.0;
    double thinsmithPrice = 0.0;

    if (option == 'replace') {
      // Replace: apiPricing has thinsmith (replacePricing), bodyPaintPricing has body-paint (repairPricing)
      thinsmithPrice = (apiPricing['insurance'] as num?)?.toDouble() ?? 0.0;
      laborFee =
          (apiPricing['cost_installation_personal'] as num?)?.toDouble() ??
          (bodyPaintPricing?['cost_installation_personal'] as num?)
              ?.toDouble() ??
          0.0;
      if (bodyPaintPricing != null) {
        bodyPaintPrice =
            (bodyPaintPricing['srp_insurance'] as num?)?.toDouble() ?? 0.0;
      }
      finalPrice = thinsmithPrice + bodyPaintPrice;
    } else {
      // Repair: apiPricing has body-paint (repairPricing)
      laborFee =
          (apiPricing['cost_installation_personal'] as num?)?.toDouble() ?? 0.0;
      bodyPaintPrice = (apiPricing['srp_insurance'] as num?)?.toDouble() ?? 0.0;
      finalPrice = bodyPaintPrice;
    }

    return Container(
      padding: EdgeInsets.all(GlobalStyles.radiusXl),
      decoration: BoxDecoration(
        color: GlobalStyles.primaryMain.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${option.toUpperCase()} PRICING',
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyBody,
                  color: GlobalStyles.primaryMain,
                  fontSize: GlobalStyles.fontSizeCaption,
                  fontWeight: GlobalStyles.fontWeightBold,
                ),
              ),
            ],
          ),
          SizedBox(height: GlobalStyles.spacingSm),
          _buildCostItem('Labor Fee', laborFee),
          if (option == 'repair') ...[
            SizedBox(height: GlobalStyles.spacingSm),
            _buildCostItem('Paint Price', bodyPaintPrice),
          ] else if (option == 'replace') ...[
            SizedBox(height: GlobalStyles.spacingSm),
            // For replace, show both thinsmith and body paint
            _buildCostItem('Part Price', thinsmithPrice),
            _buildCostItem('Paint Price', bodyPaintPrice),
          ],
          Divider(
            color: GlobalStyles.textSecondary.withValues(alpha: 0.3),
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  option == 'replace' ? 'TOTAL PRICE' : 'TOTAL REPAIR PRICE',
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyBody,
                    color: GlobalStyles.textPrimary,
                    fontSize: 14,
                    fontWeight: GlobalStyles.fontWeightBold,
                  ),
                ),
              ),
              Text(
                // Display total including labor fee so UI total matches computed totals
                _formatCurrency(finalPrice + laborFee),
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyBody,
                  color: GlobalStyles.primaryMain,
                  fontSize: 16,
                  fontWeight: GlobalStyles.fontWeightBold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _hasValidPricingData(Map<String, dynamic> pricingData, String option) {
    if (option == 'repair') {
      // For repair, we need body-paint pricing (srp_insurance)
      final bodyPaintPrice = pricingData['srp_insurance'];
      return bodyPaintPrice != null && bodyPaintPrice != 0;
    } else if (option == 'replace') {
      // For replace, we need thinsmith pricing (insurance)
      final thinsmithPrice = pricingData['insurance'];
      return thinsmithPrice != null && thinsmithPrice != 0;
    }
    return false;
  }

  Widget _buildCostItem(String label, double amount) {
    return Padding(
      padding: EdgeInsets.only(bottom: GlobalStyles.spacingSm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyBody,
              color: GlobalStyles.textTertiary,
              fontSize: GlobalStyles.fontSizeCaption,
              fontWeight: GlobalStyles.fontWeightMedium,
            ),
          ),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyBody,
              color: GlobalStyles.textPrimary,
              fontSize: GlobalStyles.fontSizeCaption,
              fontWeight: GlobalStyles.fontWeightSemiBold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _savePDF() async {
    setState(() => _isSaving = true);
    try {
      // Check existing permissions first
      bool hasPerm = await LocalStorageService.hasStoragePermissions();

      if (!hasPerm) {
        // Ask the user if they'd like to grant storage permission
        final shouldRequest = await showDialog<bool?>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(
                  'Storage permission required',
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyBody,
                    fontSize: GlobalStyles.fontSizeBody1,
                    fontWeight: GlobalStyles.fontWeightBold,
                  ),
                ),
                content: Text(
                  'To save the PDF report to your device we need storage permission. Would you like to grant it now?',
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyBody,
                    fontSize: GlobalStyles.fontSizeCaption,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Cancel',
                      style: TextStyle(fontFamily: GlobalStyles.fontFamilyBody),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
                      'Allow',
                      style: TextStyle(fontFamily: GlobalStyles.fontFamilyBody),
                    ),
                  ),
                ],
              ),
        );

        if (shouldRequest != true) {
          setState(() => _isSaving = false);
          return;
        }

        // Request permissions via service
        final granted = await LocalStorageService.requestStoragePermissions();
        if (!granted) {
          // If still not granted, offer to open app settings
          final openSettings = await showDialog<bool?>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text(
                    'Permission required',
                    style: TextStyle(
                      fontFamily: GlobalStyles.fontFamilyBody,
                      fontSize: GlobalStyles.fontSizeBody1,
                      fontWeight: GlobalStyles.fontWeightBold,
                    ),
                  ),
                  content: Text(
                    'Storage permission was not granted. You can open app settings to allow it manually.',
                    style: TextStyle(
                      fontFamily: GlobalStyles.fontFamilyBody,
                      fontSize: GlobalStyles.fontSizeCaption,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: GlobalStyles.fontFamilyBody,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(
                        'Open Settings',
                        style: TextStyle(
                          fontFamily: GlobalStyles.fontFamilyBody,
                        ),
                      ),
                    ),
                  ],
                ),
          );

          if (openSettings == true) {
            await openAppSettings();
          }
          setState(() => _isSaving = false);
          return;
        }
      }

      final Map<String, Map<String, dynamic>> pdfResponses = {};
      final apiResponsesForPdf =
          widget.apiResponses ?? <String, Map<String, dynamic>>{};

      // Process API responses and add individual damage costs
      apiResponsesForPdf.forEach((imagePath, response) {
        final copiedResponse = Map<String, dynamic>.from(response);

        // Get damage indices for this image
        final damageIndices = _handler.imageToDamageIndices[imagePath] ?? [];

        // If there are damages, add cost information to each damage
        if (copiedResponse['damages'] is List) {
          final damages = copiedResponse['damages'] as List;
          final updatedDamages = <Map<String, dynamic>>[];

          for (int i = 0; i < damages.length; i++) {
            final damage =
                damages[i] is Map<String, dynamic>
                    ? Map<String, dynamic>.from(
                      damages[i] as Map<String, dynamic>,
                    )
                    : <String, dynamic>{};

            // Get the global damage index for this damage
            final globalDamageIndex =
                i < damageIndices.length ? damageIndices[i] : -1;

            if (globalDamageIndex >= 0) {
              final selectedOption =
                  _handler.selectedRepairOptions[globalDamageIndex];

              // Calculate individual damage cost based on selected option
              double damageCost = 0.0;

              if (selectedOption == 'repair') {
                final repairData =
                    _handler.repairPricingData[globalDamageIndex];
                if (repairData != null) {
                  final repoTotal =
                      (repairData['total_with_labor'] as num?)?.toDouble();
                  if (repoTotal != null) {
                    damageCost = repoTotal;
                  } else {
                    final double bodyPaint =
                        (repairData['srp_insurance'] as num?)?.toDouble() ??
                        0.0;
                    final double labor =
                        (repairData['cost_installation_personal'] as num?)
                            ?.toDouble() ??
                        0.0;
                    damageCost = bodyPaint + labor;
                  }
                }
              } else if (selectedOption == 'replace') {
                final replacePricing =
                    _handler.replacePricingData[globalDamageIndex];
                final repairData =
                    _handler.repairPricingData[globalDamageIndex];
                if (replacePricing != null || repairData != null) {
                  final repoTotal =
                      (replacePricing?['total_with_labor'] as num?)
                          ?.toDouble() ??
                      (repairData?['total_with_labor'] as num?)?.toDouble();
                  if (repoTotal != null) {
                    damageCost = repoTotal;
                  } else {
                    final double thinsmith =
                        (replacePricing?['insurance'] as num?)?.toDouble() ??
                        0.0;
                    final double bodyPaint =
                        (repairData?['srp_insurance'] as num?)?.toDouble() ??
                        0.0;
                    final double labor =
                        (replacePricing?['cost_installation_personal'] as num?)
                            ?.toDouble() ??
                        (repairData?['cost_installation_personal'] as num?)
                            ?.toDouble() ??
                        0.0;
                    damageCost = thinsmith + bodyPaint + labor;
                  }
                }
              }

              // Add cost to damage item
              if (damageCost > 0.0) {
                damage['cost'] = _formatCurrency(damageCost);
              }

              // Update action based on user selection
              if (selectedOption != null) {
                damage['action'] = _capitalizeOption(selectedOption);
                damage['recommended_action'] = _capitalizeOption(
                  selectedOption,
                );
              }
            }

            updatedDamages.add(damage);
          }

          copiedResponse['damages'] = updatedDamages;
        }

        pdfResponses[imagePath] = copiedResponse;
      });

      // --- FIX: Correctly structure manual damages for the PDF service ---
      // Add manual damages as a separate entry if they exist
      if (_handler.manualDamages.isNotEmpty) {
        List<Map<String, dynamic>> manualDamagesForPdf = [];
        for (int i = 0; i < _handler.manualDamages.length; i++) {
          final m = _handler.manualDamages[i];
          final globalIndex = -(i + 1);
          final selectedOption = _handler.selectedRepairOptions[globalIndex];

          double damageCost = 0.0;

          if (selectedOption == 'repair') {
            final repairData = _handler.repairPricingData[globalIndex];
            if (repairData != null) {
              final repoTotal =
                  (repairData['total_with_labor'] as num?)?.toDouble();
              if (repoTotal != null) {
                damageCost = repoTotal;
              } else {
                final double bodyPaint =
                    (repairData['srp_insurance'] as num?)?.toDouble() ?? 0.0;
                final double labor =
                    (repairData['cost_installation_personal'] as num?)
                        ?.toDouble() ??
                    0.0;
                damageCost = bodyPaint + labor;
              }
            }
          } else if (selectedOption == 'replace') {
            final replacePricing = _handler.replacePricingData[globalIndex];
            final repairData = _handler.repairPricingData[globalIndex];
            if (replacePricing != null || repairData != null) {
              final repoTotal =
                  (replacePricing?['total_with_labor'] as num?)?.toDouble() ??
                  (repairData?['total_with_labor'] as num?)?.toDouble();
              if (repoTotal != null) {
                damageCost = repoTotal;
              } else {
                final double thinsmith =
                    (replacePricing?['insurance'] as num?)?.toDouble() ?? 0.0;
                final double bodyPaint =
                    (repairData?['srp_insurance'] as num?)?.toDouble() ?? 0.0;
                final double labor =
                    (replacePricing?['cost_installation_personal'] as num?)
                        ?.toDouble() ??
                    (repairData?['cost_installation_personal'] as num?)
                        ?.toDouble() ??
                    0.0;
                damageCost = thinsmith + bodyPaint + labor;
              }
            }
          }

          final damageMap = <String, dynamic>{
            'type': m['damaged_part'], // Key 'type' is read by the PDF service
            'damaged_part': m['damaged_part'],
            'severity': '', // No severity for manual damages
          };

          if (damageCost > 0.0) {
            damageMap['cost'] = _formatCurrency(damageCost);
          }

          if (selectedOption != null) {
            damageMap['action'] = _capitalizeOption(selectedOption);
            damageMap['recommended_action'] = _capitalizeOption(selectedOption);
          }

          manualDamagesForPdf.add(damageMap);
        }

        // Calculate total cost for manual damages only
        double manualDamagesTotalCost = 0.0;
        for (int i = 0; i < _handler.manualDamages.length; i++) {
          final globalIndex = -(i + 1);
          final selectedOption = _handler.selectedRepairOptions[globalIndex];

          if (selectedOption == 'repair') {
            final repairData = _handler.repairPricingData[globalIndex];
            if (repairData != null) {
              final repoTotal =
                  (repairData['total_with_labor'] as num?)?.toDouble();
              if (repoTotal != null) {
                manualDamagesTotalCost += repoTotal;
              } else {
                final double bodyPaint =
                    (repairData['srp_insurance'] as num?)?.toDouble() ?? 0.0;
                final double labor =
                    (repairData['cost_installation_personal'] as num?)
                        ?.toDouble() ??
                    0.0;
                manualDamagesTotalCost += (bodyPaint + labor);
              }
            }
          } else if (selectedOption == 'replace') {
            final replacePricing = _handler.replacePricingData[globalIndex];
            final repairData = _handler.repairPricingData[globalIndex];
            if (replacePricing != null || repairData != null) {
              final repoTotal =
                  (replacePricing?['total_with_labor'] as num?)?.toDouble() ??
                  (repairData?['total_with_labor'] as num?)?.toDouble();
              if (repoTotal != null) {
                manualDamagesTotalCost += repoTotal;
              } else {
                final double thinsmith =
                    (replacePricing?['insurance'] as num?)?.toDouble() ?? 0.0;
                final double bodyPaint =
                    (repairData?['srp_insurance'] as num?)?.toDouble() ?? 0.0;
                final double labor =
                    (replacePricing?['cost_installation_personal'] as num?)
                        ?.toDouble() ??
                    (repairData?['cost_installation_personal'] as num?)
                        ?.toDouble() ??
                    0.0;
                manualDamagesTotalCost += (thinsmith + bodyPaint + labor);
              }
            }
          }
        }

        pdfResponses['manual_report_1'] = {
          'overall_severity': 'Manual Assessment',
          'damages': manualDamagesForPdf,
          'total_cost': _formatCurrency(manualDamagesTotalCost),
        };
      }

      // Ensure every response passed to the PDF service has a usable total_cost
      // If not severe, fill missing/zero/'N/A' values using the computed
      // estimated cost. We distribute the estimate evenly across missing entries
      // so the PDF doesn't show 'N/A'.
      if (!_isDamageSevere && pdfResponses.isNotEmpty) {
        // prefer the already-calculated estimated cost (includes user choices)
        double totalToUse =
            _handler.estimatedDamageCost > 0
                ? _handler.estimatedDamageCost
                : _calculateTotalFromPricingData();

        // If totalToUse is still 0, try summing any existing response totals
        if (totalToUse <= 0) {
          double existingSum = 0.0;
          pdfResponses.forEach((k, v) {
            existingSum += _parseToDouble(v['total_cost']);
          });
          if (existingSum > 0) totalToUse = existingSum;
        }

        // Find keys that are missing a meaningful total_cost
        final missingKeys =
            pdfResponses.keys.where((k) {
              final val = pdfResponses[k]?['total_cost'];
              if (val == null) return true;
              final s = val.toString().toLowerCase();
              if (s.isEmpty) return true;
              if (s.contains('n/a')) return true;
              if (_parseToDouble(val) == 0.0) return true;
              return false;
            }).toList();

        if (missingKeys.isNotEmpty) {
          // Calculate individual cost for each image/entry based on its specific damages
          for (final k in missingKeys) {
            double costForThisEntry = 0.0;

            // Check if this key corresponds to an actual image path
            if (_handler.imageToDamageIndices.containsKey(k)) {
              // Calculate cost based on damages associated with this specific image
              costForThisEntry = _calculateCostForImage(k);
            } else if (k == 'manual_report_1') {
              // For manual damages, calculate the total from pricing data
              costForThisEntry = _calculateTotalFromPricingData();
            }

            // Format and assign the calculated cost
            final formatted =
                costForThisEntry > 0
                    ? _formatCurrency(costForThisEntry)
                    : 'N/A';
            pdfResponses[k]!['total_cost'] = formatted;
          }
        }
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
              backgroundColor: GlobalStyles.surfaceMain,
              title: Text(
                'Save Assessment Report',
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyBody,
                  color: GlobalStyles.textPrimary,
                  fontSize: GlobalStyles.fontSizeBody2,
                  fontWeight: GlobalStyles.fontWeightBold,
                ),
              ),
              content: Text(
                'Where do you want to save the generated PDF?',
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyBody,
                  color: GlobalStyles.textPrimary,
                  fontSize: GlobalStyles.fontSizeCaption,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop('auto'),
                  child: Text(
                    'Save to InsureVis/documents',
                    style: TextStyle(
                      fontFamily: GlobalStyles.fontFamilyBody,
                      color: GlobalStyles.primaryMain,
                      fontSize: GlobalStyles.fontSizeCaption,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop('choose'),
                  child: Text(
                    'Choose folder',
                    style: TextStyle(
                      fontFamily: GlobalStyles.fontFamilyBody,
                      color: GlobalStyles.primaryMain,
                      fontSize: GlobalStyles.fontSizeCaption,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: GlobalStyles.fontFamilyBody,
                      color: GlobalStyles.primaryMain,
                      fontSize: GlobalStyles.fontSizeCaption,
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
          final currentDate = DateTime.now().toString().substring(0, 10);
          final defaultFileName = 'Damage Assessment ($currentDate).pdf';
          try {
            final newFileUri = await FileWriter.saveFileToTree(
              treeUri,
              defaultFileName,
              bytes,
            );
            savedPath = newFileUri;
          } catch (e) {
            final currentDate = DateTime.now().toString().substring(0, 10);
            savedPath = await PDFService.savePdfBytesWithPicker(
              bytes,
              'Damage Assessment ($currentDate).pdf',
            );
          }
        } else {
          final currentDate = DateTime.now().toString().substring(0, 10);
          savedPath = await PDFService.savePdfBytesWithPicker(
            bytes,
            'Damage Assessment ($currentDate).pdf',
          );
        }
      }
      if (savedPath != null) {
        if (mounted) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.clearSnackBars();
          messenger.showSnackBar(
            SnackBar(
              content: Text('Assessment report saved successfully!'),
              backgroundColor: GlobalStyles.successMain,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Share',
                textColor: GlobalStyles.surfaceMain,
                onPressed: () {
                  messenger.hideCurrentSnackBar();
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
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error saving report: $e'),
            backgroundColor: GlobalStyles.errorMain,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _proceedToClaimInsurance() async {
    // Check if there are any damages (API-detected or manual)
    int totalDamages = 0;

    // Count API-detected damages
    final apiResponses =
        widget.apiResponses ?? <String, Map<String, dynamic>>{};
    for (var response in apiResponses.values) {
      if (response['damages'] is List) {
        totalDamages += (response['damages'] as List).length;
      } else if (response['prediction'] is List) {
        totalDamages += (response['prediction'] as List).length;
      }
    }

    // Count manual damages
    totalDamages += _handler.manualDamages.length;

    // If no damages found, show error and prevent navigation
    if (totalDamages == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please add at least one damage (automated or manual) to proceed.',
            ),
            backgroundColor: GlobalStyles.warningMain,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Generate temporary PDF for job estimate
    String? tempPdfPath;
    try {
      // Build the apiResponses with all damage information for PDF generation
      final Map<String, Map<String, dynamic>> pdfResponses = {};
      final apiResponsesForPdf =
          widget.apiResponses ?? <String, Map<String, dynamic>>{};

      // Process API responses and add individual damage costs
      apiResponsesForPdf.forEach((imagePath, response) {
        final copiedResponse = Map<String, dynamic>.from(response);

        // Get damage indices for this image
        final damageIndices = _handler.imageToDamageIndices[imagePath] ?? [];

        // If there are damages, add cost information to each damage
        if (copiedResponse['damages'] is List) {
          final damagesList = copiedResponse['damages'] as List;
          for (int i = 0; i < damagesList.length; i++) {
            if (i < damageIndices.length) {
              final damageIndex = damageIndices[i];
              final selectedOption =
                  _handler.selectedRepairOptions[damageIndex];
              if (selectedOption != null) {
                final damage = damagesList[i] as Map<String, dynamic>;
                damage['recommended_action'] = selectedOption;
                damage['action'] = selectedOption;

                // Calculate cost for this specific damage
                double damageCost = 0.0;
                if (selectedOption == 'repair') {
                  final repairData = _handler.repairPricingData[damageIndex];
                  if (repairData != null) {
                    final repoTotal =
                        (repairData['total_with_labor'] as num?)?.toDouble();
                    if (repoTotal != null) {
                      damageCost = repoTotal;
                    } else {
                      final double bodyPaint =
                          (repairData['srp_insurance'] as num?)?.toDouble() ??
                          0.0;
                      final double labor =
                          (repairData['cost_installation_personal'] as num?)
                              ?.toDouble() ??
                          0.0;
                      damageCost = bodyPaint + labor;
                    }
                  }
                } else if (selectedOption == 'replace') {
                  final replacePricing =
                      _handler.replacePricingData[damageIndex];
                  final repairData = _handler.repairPricingData[damageIndex];
                  if (replacePricing != null || repairData != null) {
                    final repoTotal =
                        (replacePricing?['total_with_labor'] as num?)
                            ?.toDouble() ??
                        (repairData?['total_with_labor'] as num?)?.toDouble();
                    if (repoTotal != null) {
                      damageCost = repoTotal;
                    } else {
                      final double thinsmith =
                          (replacePricing?['insurance'] as num?)?.toDouble() ??
                          0.0;
                      final double bodyPaint =
                          (repairData?['srp_insurance'] as num?)?.toDouble() ??
                          0.0;
                      final double labor =
                          (replacePricing?['cost_installation_personal']
                                  as num?)
                              ?.toDouble() ??
                          (repairData?['cost_installation_personal'] as num?)
                              ?.toDouble() ??
                          0.0;
                      damageCost = thinsmith + bodyPaint + labor;
                    }
                  }
                }

                damage['cost'] = damageCost.toString();
                damage['estimated_cost'] = damageCost.toString();
              }
            }
          }
        }

        pdfResponses[imagePath] = copiedResponse;
      });

      // Add manual damages as a separate entry if they exist
      if (_handler.manualDamages.isNotEmpty) {
        List<Map<String, dynamic>> manualDamagesForPdf = [];
        for (int i = 0; i < _handler.manualDamages.length; i++) {
          final manual = _handler.manualDamages[i];
          final globalIndex = -(i + 1);
          final damagedPart = manual['damaged_part'] ?? 'Unknown Part';
          final damageType = manual['damage_type'] ?? 'Unknown Damage';
          final selectedOption = _handler.selectedRepairOptions[globalIndex];

          if (selectedOption != null) {
            double damageCost = 0.0;
            if (selectedOption == 'repair') {
              final repairData = _handler.repairPricingData[globalIndex];
              if (repairData != null) {
                final repoTotal =
                    (repairData['total_with_labor'] as num?)?.toDouble();
                if (repoTotal != null) {
                  damageCost = repoTotal;
                } else {
                  final double bodyPaint =
                      (repairData['srp_insurance'] as num?)?.toDouble() ?? 0.0;
                  final double labor =
                      (repairData['cost_installation_personal'] as num?)
                          ?.toDouble() ??
                      0.0;
                  damageCost = bodyPaint + labor;
                }
              }
            } else if (selectedOption == 'replace') {
              final replacePricing = _handler.replacePricingData[globalIndex];
              final repairData = _handler.repairPricingData[globalIndex];
              if (replacePricing != null || repairData != null) {
                final repoTotal =
                    (replacePricing?['total_with_labor'] as num?)?.toDouble() ??
                    (repairData?['total_with_labor'] as num?)?.toDouble();
                if (repoTotal != null) {
                  damageCost = repoTotal;
                } else {
                  final double thinsmith =
                      (replacePricing?['insurance'] as num?)?.toDouble() ?? 0.0;
                  final double bodyPaint =
                      (repairData?['srp_insurance'] as num?)?.toDouble() ?? 0.0;
                  final double labor =
                      (replacePricing?['cost_installation_personal'] as num?)
                          ?.toDouble() ??
                      (repairData?['cost_installation_personal'] as num?)
                          ?.toDouble() ??
                      0.0;
                  damageCost = thinsmith + bodyPaint + labor;
                }
              }
            }

            manualDamagesForPdf.add({
              'label': damagedPart,
              'damaged_part': damagedPart,
              'damage_type': damageType,
              'recommended_action': selectedOption,
              'action': selectedOption,
              'cost': damageCost.toString(),
              'estimated_cost': damageCost.toString(),
            });
          }
        }

        if (manualDamagesForPdf.isNotEmpty) {
          double manualDamagesTotalCost = 0.0;
          for (var damage in manualDamagesForPdf) {
            try {
              final cost =
                  double.tryParse(damage['cost']?.toString() ?? '0') ?? 0.0;
              manualDamagesTotalCost += cost;
            } catch (e) {
              // Ignore parse errors
            }
          }

          pdfResponses['manual_report_1'] = {
            'damages': manualDamagesForPdf,
            'total_cost': manualDamagesTotalCost.toString(),
            'overall_severity': 'Manual Entry',
          };
        }
      }

      // Ensure every response has a usable total_cost
      if (!_isDamageSevere && pdfResponses.isNotEmpty) {
        double totalToUse = _handler.estimatedDamageCost;
        if (totalToUse <= 0) {
          for (var response in pdfResponses.values) {
            if (response['total_cost'] != null) {
              try {
                totalToUse += _parseToDouble(response['total_cost']);
              } catch (e) {
                // Ignore
              }
            }
          }
        }

        final missingKeys =
            pdfResponses.keys.where((key) {
              final val = pdfResponses[key]!['total_cost'];
              if (val == null) return true;
              if (val.toString().toLowerCase() == 'n/a') return true;
              try {
                final parsed = _parseToDouble(val);
                return parsed <= 0;
              } catch (e) {
                return true;
              }
            }).toList();

        if (missingKeys.isNotEmpty) {
          final perEntry = totalToUse / missingKeys.length;
          for (var key in missingKeys) {
            pdfResponses[key]!['total_cost'] = perEntry.toString();
          }
        }
      }

      if (_isDamageSevere) {
        pdfResponses.forEach((key, value) {
          value['total_cost'] = 'To be given by the mechanic';
        });
      }

      // Generate temporary PDF
      tempPdfPath = await PDFService.generateTemporaryPDF(
        imagePaths: widget.imagePaths ?? [],
        apiResponses: pdfResponses,
      );

      if (tempPdfPath != null) {
        print('Generated temporary PDF for job estimate: $tempPdfPath');
      }
    } catch (e) {
      print('Error generating temporary PDF: $e');
      // Continue even if PDF generation fails - it's not critical
    }

    // Navigate to Insurance Document Upload with selected repair options and pricing data
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => InsuranceDocumentUpload(
                imagePaths: widget.imagePaths ?? const <String>[],
                apiResponses:
                    widget.apiResponses ?? <String, Map<String, dynamic>>{},
                assessmentIds: widget.assessmentIds ?? <String, String>{},
                selectedRepairOptions: Map<int, String>.from(
                  _handler.selectedRepairOptions,
                ),
                repairPricingData: Map<int, Map<String, dynamic>>.from(
                  _handler.repairPricingData.map(
                    (k, v) => MapEntry(k, v ?? {}),
                  ),
                ),
                replacePricingData: Map<int, Map<String, dynamic>>.from(
                  _handler.replacePricingData.map(
                    (k, v) => MapEntry(k, v ?? {}),
                  ),
                ),
                manualDamages: List<Map<String, String>>.from(
                  _handler.manualDamages,
                ),
                estimatedDamageCost: _handler.estimatedDamageCost,
                vehicleData: widget.vehicleData,
                tempJobEstimatePdfPath: tempPdfPath,
              ),
        ),
      );
    }
  }

  Future<void> _sharePDF(String filePath) async {
    try {
      await Share.shareXFiles([
        XFile(filePath),
      ], text: 'Vehicle Assessment Report');
    } catch (e) {
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error sharing file: $e'),
            backgroundColor: GlobalStyles.errorMain,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
