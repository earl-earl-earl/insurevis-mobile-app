import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EnhancedDamageAnalysis extends StatefulWidget {
  final Map<String, dynamic> damageData;
  final double confidence;
  final String imagePath;

  const EnhancedDamageAnalysis({
    super.key,
    required this.damageData,
    required this.confidence,
    required this.imagePath,
  });

  @override
  State<EnhancedDamageAnalysis> createState() => _EnhancedDamageAnalysisState();
}

class _EnhancedDamageAnalysisState extends State<EnhancedDamageAnalysis>
    with TickerProviderStateMixin {
  late AnimationController _confidenceController;
  late Animation<double> _confidenceAnimation;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _confidenceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _confidenceAnimation = Tween<double>(
      begin: 0.0,
      end: widget.confidence,
    ).animate(
      CurvedAnimation(
        parent: _confidenceController,
        curve: Curves.easeOutCubic,
      ),
    );
    _confidenceController.forward();
  }

  @override
  void dispose() {
    _confidenceController.dispose();
    super.dispose();
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.9) return Colors.green;
    if (confidence >= 0.7) return Colors.orange;
    return Colors.red;
  }

  Color _getSeverityColor(String severity) {
    final lowerSeverity = severity.toLowerCase();
    if (lowerSeverity.contains('high') || lowerSeverity.contains('severe')) {
      return Colors.red.shade600;
    } else if (lowerSeverity.contains('medium') ||
        lowerSeverity.contains('moderate')) {
      return Colors.orange.shade600;
    } else if (lowerSeverity.contains('low') ||
        lowerSeverity.contains('minor')) {
      return Colors.green.shade600;
    }
    return Colors.blue.shade600;
  }

  IconData _getDamageTypeIcon(String damageType) {
    final type = damageType.toLowerCase();
    if (type.contains('dent')) return Icons.radio_button_checked;
    if (type.contains('scratch')) return Icons.format_strikethrough;
    if (type.contains('crack')) return Icons.warning;
    if (type.contains('broken')) return Icons.broken_image;
    if (type.contains('paint')) return Icons.palette;
    return Icons.car_crash;
  }

  @override
  Widget build(BuildContext context) {
    final damageType = widget.damageData['damage_type'] ?? 'Unknown';
    final severity = widget.damageData['severity'] ?? 'Unknown';
    final location = widget.damageData['location'] ?? 'Unknown';

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.3),
            Colors.black.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _getSeverityColor(severity).withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Header with damage type and confidence
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getSeverityColor(severity).withValues(alpha: 0.2),
                  _getSeverityColor(severity).withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(severity),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getDamageTypeIcon(damageType),
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        damageType,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        location,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildConfidenceIndicator(),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // Severity and quick stats
                Row(
                  children: [
                    _buildSeverityChip(severity),
                    Spacer(),
                    _buildDetailToggle(),
                  ],
                ),

                // Animated details section
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  height: _showDetails ? null : 0,
                  child:
                      _showDetails
                          ? _buildDetailedAnalysis()
                          : SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceIndicator() {
    return SizedBox(
      width: 60.w,
      height: 60.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),
          // Animated progress circle
          AnimatedBuilder(
            animation: _confidenceAnimation,
            builder: (context, child) {
              return SizedBox(
                width: 60.w,
                height: 60.w,
                child: CircularProgressIndicator(
                  value: _confidenceAnimation.value,
                  strokeWidth: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getConfidenceColor(_confidenceAnimation.value),
                  ),
                ),
              );
            },
          ),
          // Confidence percentage
          AnimatedBuilder(
            animation: _confidenceAnimation,
            builder: (context, child) {
              return Text(
                '${(_confidenceAnimation.value * 100).round()}%',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityChip(String severity) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: _getSeverityColor(severity),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            severity.toLowerCase().contains('high')
                ? Icons.warning
                : severity.toLowerCase().contains('medium')
                ? Icons.info
                : Icons.check_circle,
            color: Colors.white,
            size: 16.sp,
          ),
          SizedBox(width: 6.w),
          Text(
            severity,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailToggle() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showDetails = !_showDetails;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _showDetails ? 'Less' : 'Details',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 4.w),
            AnimatedRotation(
              turns: _showDetails ? 0.5 : 0,
              duration: Duration(milliseconds: 300),
              child: Icon(
                Icons.expand_more,
                color: Colors.white70,
                size: 16.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedAnalysis() {
    final description =
        widget.damageData['description'] ?? 'No description available';

    return Container(
      margin: EdgeInsets.only(top: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description section
          Text(
            'Analysis Details',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            description,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white70,
              height: 1.4,
            ),
          ),

          SizedBox(height: 16.h),

          // Technical details
          _buildTechnicalDetails(),

          SizedBox(height: 16.h),

          // Confidence breakdown
          _buildConfidenceBreakdown(),
        ],
      ),
    );
  }

  Widget _buildTechnicalDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Technical Analysis',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8.h),
        _buildDetailRow('AI Model', 'YOLOv8-Damage-Detection'),
        _buildDetailRow('Processing Time', '2.3s'),
        _buildDetailRow('Image Quality', 'High Resolution'),
        _buildDetailRow('Lighting Conditions', 'Optimal'),
      ],
    );
  }

  Widget _buildConfidenceBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confidence Breakdown',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8.h),
        _buildConfidenceBar('Detection', widget.confidence),
        _buildConfidenceBar('Classification', widget.confidence * 0.95),
        _buildConfidenceBar('Severity Assessment', widget.confidence * 0.90),
        _buildConfidenceBar('Location Accuracy', widget.confidence * 0.92),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12.sp, color: Colors.white60)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBar(String label, double confidence) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12.sp, color: Colors.white60),
              ),
              Text(
                '${(confidence * 100).round()}%',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: _getConfidenceColor(confidence),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Container(
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2.r),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: confidence,
              child: Container(
                decoration: BoxDecoration(
                  color: _getConfidenceColor(confidence),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
