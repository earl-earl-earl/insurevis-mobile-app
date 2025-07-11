import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math' as math;

class RealTimeDamageOverlay extends StatefulWidget {
  final bool isDetecting;
  final List<Map<String, dynamic>> detectedDamages;
  final Size previewSize;

  const RealTimeDamageOverlay({
    super.key,
    required this.isDetecting,
    required this.detectedDamages,
    required this.previewSize,
  });

  @override
  State<RealTimeDamageOverlay> createState() => _RealTimeDamageOverlayState();
}

class _RealTimeDamageOverlayState extends State<RealTimeDamageOverlay>
    with TickerProviderStateMixin {
  late AnimationController _scanController;
  late AnimationController _pulseController;
  late Animation<double> _scanAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _scanController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isDetecting) {
      _scanController.repeat();
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(RealTimeDamageOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isDetecting != oldWidget.isDetecting) {
      if (widget.isDetecting) {
        _scanController.repeat();
        _pulseController.repeat(reverse: true);
      } else {
        _scanController.stop();
        _pulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Color _getDamageColor(String damageType, double confidence) {
    if (confidence < 0.5) return Colors.yellow;

    final type = damageType.toLowerCase();
    if (type.contains('severe') || type.contains('high')) {
      return Colors.red;
    } else if (type.contains('moderate') || type.contains('medium')) {
      return Colors.orange;
    } else if (type.contains('minor') || type.contains('low')) {
      return Colors.green;
    }
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Scanning overlay when detecting
        if (widget.isDetecting) _buildScanningOverlay(),

        // Damage detection boxes
        ...widget.detectedDamages.map(
          (damage) => _buildDamageIndicator(damage),
        ),

        // Detection status indicator
        _buildDetectionStatus(),
      ],
    );
  }

  Widget _buildScanningOverlay() {
    return AnimatedBuilder(
      animation: _scanAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: widget.previewSize,
          painter: ScanLinePainter(_scanAnimation.value),
        );
      },
    );
  }

  Widget _buildDamageIndicator(Map<String, dynamic> damage) {
    final bbox =
        damage['bbox'] ?? {'x': 0.0, 'y': 0.0, 'width': 0.0, 'height': 0.0};
    final confidence = (damage['confidence'] ?? 0.0).toDouble();
    final damageType = damage['type'] ?? 'Unknown';

    final x = (bbox['x'] ?? 0.0) * widget.previewSize.width;
    final y = (bbox['y'] ?? 0.0) * widget.previewSize.height;
    final width = (bbox['width'] ?? 0.0) * widget.previewSize.width;
    final height = (bbox['height'] ?? 0.0) * widget.previewSize.height;

    return Positioned(
      left: x,
      top: y,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _getDamageColor(damageType, confidence),
                  width: 2.0,
                ),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Stack(
                children: [
                  // Confidence indicator
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: _getDamageColor(
                          damageType,
                          confidence,
                        ).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        '${(confidence * 100).round()}%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Damage type label
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        damageType,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetectionStatus() {
    return Positioned(
      top: 20.h,
      left: 20.w,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color:
                widget.isDetecting
                    ? Colors.green
                    : Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status indicator
            Container(
              width: 8.w,
              height: 8.w,
              decoration: BoxDecoration(
                color: widget.isDetecting ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 8.w),

            // Status text
            Text(
              widget.isDetecting ? 'AI Scanning...' : 'Ready to Scan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),

            // Damage count
            if (widget.detectedDamages.isNotEmpty) ...[
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  '${widget.detectedDamages.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ScanLinePainter extends CustomPainter {
  final double progress;

  ScanLinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.green.withValues(alpha: 0.8)
          ..strokeWidth = 2.0;

    // Calculate scan line position
    final y = size.height * progress;

    // Draw main scan line
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);

    // Draw gradient effect above and below
    final gradientPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.withValues(alpha: 0.0),
              Colors.green.withValues(alpha: 0.3),
              Colors.green.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromLTWH(0, y - 10, size.width, 20));

    canvas.drawRect(Rect.fromLTWH(0, y - 10, size.width, 20), gradientPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

// Sample data generator for testing
class DamageDetectionService {
  static List<Map<String, dynamic>> generateSampleDetections() {
    final random = math.Random();
    final detections = <Map<String, dynamic>>[];

    // Generate 1-3 random damage detections
    final count = random.nextInt(3) + 1;

    for (int i = 0; i < count; i++) {
      detections.add({
        'bbox': {
          'x': random.nextDouble() * 0.6, // Keep within reasonable bounds
          'y': random.nextDouble() * 0.6,
          'width': 0.1 + random.nextDouble() * 0.2,
          'height': 0.1 + random.nextDouble() * 0.2,
        },
        'confidence': 0.5 + random.nextDouble() * 0.5, // 50-100% confidence
        'type': ['Dent', 'Scratch', 'Paint Chip', 'Crack'][random.nextInt(4)],
      });
    }

    return detections;
  }
}
