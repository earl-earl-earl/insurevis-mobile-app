import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Design System Variables - Based on theme_design_system.json
/// Soft, clean, modern design system with professional soft colors
class GlobalStyles {
  // ==================== COLORS ====================

  // Primary Colors (Soft Professional Blue)
  static const Color primaryMain = Color(0xFF64B5F6); // Colors.blue[300]
  static const Color primaryLight = Color(0xFF90CAF9); // Colors.blue[200]
  static const Color primaryDark = Color(0xFF42A5F5); // Colors.blue[400]

  // Background Colors (Very Light Gray / Off-White)
  static const Color backgroundMain = Color(0xFFF8F8F8);
  static const Color backgroundAlternative = Color(0xFFFAFAFA);

  // Surface Colors (White with soft shadows)
  static const Color surfaceMain = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  // Text Colors (Dark Gray Hierarchy)
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF333333);
  static const Color textTertiary = Color(0xFF666666);
  static const Color textDisabled = Color(0xFF999999);

  // Accent Colors (Professional highlights - limit to 1-2)
  static const Color accent1 = Color(0xFF81C784); // Soft green
  static const Color accent2 = Color(0xFFFFB74D); // Soft amber

  // Feedback Colors (Professional soft tones for states)
  static const Color successMain = Color(0xFF81C784); // Colors.green[300]
  static const Color successLight = Color(0xFFA5D6A7); // Colors.green[200]
  static const Color errorMain = Color(0xFFE57373); // Colors.red[300]
  static const Color errorLight = Color(0xFFEF9A9A); // Colors.red[200]
  static const Color warningMain = Color(0xFFFFB74D); // Colors.orange[300]
  static const Color warningLight = Color(0xFFFFCC80); // Colors.orange[200]
  static const Color infoMain = Color(0xFF64B5F6); // Colors.blue[300]
  static const Color infoLight = Color(0xFF90CAF9); // Colors.blue[200]
  static const Color purpleMain = Color(0xFFBA68C8); // Colors.purple[300]
  static const Color purpleLight = Color(0xFFCE93D8); // Colors.purple[200]

  // State Colors
  static const double disabledOpacity = 0.4;
  static const Color focusRingColor = primaryMain;
  static const double hoverOpacity = 0.8;

  // ==================== TYPOGRAPHY ====================

  // Font Families (from assets/fonts/)
  static const String fontFamilyHeading = 'Geist'; // For headings and titles
  static const String fontFamilyBody = 'Manrope'; // For body text and UI

  // Typography Scale - Headings (using Geist)
  static double get fontSizeH1 => 32.sp;
  static double get fontSizeH2 => 28.sp;
  static double get fontSizeH3 => 24.sp;
  static double get fontSizeH4 => 20.sp;
  static double get fontSizeH5 => 18.sp;
  static double get fontSizeH6 => 16.sp;

  // Typography Scale - Body (using Manrope)
  static double get fontSizeBody1 => 16.sp;
  static double get fontSizeBody2 => 14.sp;
  static double get fontSizeCaption => 12.sp;
  static double get fontSizeButton => 14.sp;

  // Font Weights
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;

  // Line Heights
  static double get lineHeightH1 => 40.h;
  static double get lineHeightH2 => 36.h;
  static double get lineHeightH3 => 32.h;
  static double get lineHeightH4 => 28.h;
  static double get lineHeightH5 => 24.h;
  static double get lineHeightH6 => 22.h;
  static double get lineHeightBody1 => 24.h;
  static double get lineHeightBody2 => 20.h;
  static double get lineHeightCaption => 16.h;
  static double get lineHeightButton => 20.h;

  // Letter Spacing
  static const double letterSpacingH1 = -0.5;
  static const double letterSpacingH2 = -0.4;
  static const double letterSpacingH3 = -0.3;
  static const double letterSpacingH4 = -0.2;
  static const double letterSpacingButton = 0.5;

  // ==================== SPACING ====================

  static double get spacingUnit => 8.w;
  static double get spacingXs => 4.w;
  static double get spacingSm => 8.w;
  static double get spacingMd => 16.w;
  static double get spacingLg => 24.w;
  static double get spacingXl => 32.w;
  static double get spacingXxl => 48.w;
  static double get spacingXxxl => 64.w;

  // Component Spacing
  static double get paddingTight => 8.w;
  static double get paddingNormal => 16.w;
  static double get paddingLoose => 24.w;

  static double get marginTight => 8.w;
  static double get marginNormal => 16.w;
  static double get marginLoose => 24.w;

  static double get gapTight => 8.w;
  static double get gapNormal => 16.w;
  static double get gapLoose => 24.w;

  // Layout Spacing
  static double get contentMaxWidth => 1200.w;
  static double get sideMargin => 16.w;
  static double get sectionSpacing => 48.h;

  // ==================== BORDER RADIUS ====================

  static double get radiusNone => 0.r;
  static double get radiusSm => 4.r;
  static double get radiusMd => 8.r;
  static double get radiusLg => 12.r;
  static double get radiusXl => 16.r;
  static double get radiusXxl => 24.r;
  static double get radiusFull => 9999.r;
  static double get radiusDefault => 8.r;

  // ==================== SHADOWS ====================
  // Soft, subtle shadows for flat design with depth

  static BoxShadow get shadowSm => BoxShadow(
    color: const Color.fromRGBO(0, 0, 0, 0.04),
    offset: Offset(0, 1.h),
    blurRadius: 2.r,
  );

  static BoxShadow get shadowMd => BoxShadow(
    color: const Color.fromRGBO(0, 0, 0, 0.06),
    offset: Offset(0, 2.h),
    blurRadius: 4.r,
  );

  static BoxShadow get shadowLg => BoxShadow(
    color: const Color.fromRGBO(0, 0, 0, 0.08),
    offset: Offset(0, 4.h),
    blurRadius: 8.r,
  );

  static BoxShadow get shadowXl => BoxShadow(
    color: const Color.fromRGBO(0, 0, 0, 0.10),
    offset: Offset(0, 8.h),
    blurRadius: 16.r,
  );

  static BoxShadow get shadowDefault => shadowMd;

  // ==================== ICONS ====================
  // Using Lucide Icons: outlined with thin stroke for default, filled for active

  static double get iconSizeXs => 16.sp;
  static double get iconSizeSm => 20.sp;
  static double get iconSizeMd => 24.sp;
  static double get iconSizeLg => 32.sp;
  static double get iconSizeXl => 40.sp;

  static const double iconStrokeWidthThin = 1.0;
  static const double iconStrokeWidthNormal = 1.5;
  static const double iconStrokeWidthThick = 2.0;
  static const double iconStrokeWidthDefault = 1.5;

  // ==================== COMPONENTS ====================

  // Button Component
  static double get buttonBorderRadius => 8.r;
  static EdgeInsets get buttonPadding =>
      EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h);
  static BoxShadow get buttonShadow => shadowMd;

  // Card Component
  static const Color cardBackground = surfaceMain;
  static double get cardBorderRadius => 12.r;
  static EdgeInsets get cardPadding => EdgeInsets.all(24.w);
  static BoxShadow get cardShadow => shadowMd;

  // Input Component
  static const Color inputBackground = surfaceMain;
  static const Color inputBorderColor = Color(0xFFE0E0E0);
  static double get inputBorderRadius => 8.r;
  static EdgeInsets get inputPadding =>
      EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h);
  static const Color inputFocusBorderColor = primaryMain;

  // Dialog Component
  static const Color dialogBackground = surfaceMain;
  static double get dialogBorderRadius => 16.r;
  static EdgeInsets get dialogPadding => EdgeInsets.all(32.w);
  static BoxShadow get dialogShadow => shadowXl;
  static const Color dialogOverlay = Color.fromRGBO(0, 0, 0, 0.4);

  // Navbar Component
  static const Color navbarBackground = surfaceMain;
  static double get navbarHeight => 64.h;
  static BoxShadow get navbarShadow => shadowSm;
  static EdgeInsets get navbarPadding => EdgeInsets.symmetric(horizontal: 24.w);

  // Chip Component
  static const Color chipBackground = backgroundMain;
  static double get chipBorderRadius => 16.r;
  static EdgeInsets get chipPadding =>
      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h);
  static double get chipFontSize => 12.sp;

  // ==================== ANIMATIONS ====================
  // Using cubic-bezier for easing

  // Durations
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 350);
  static const Duration durationSlower = Duration(milliseconds: 500);

  // Easing Curves
  static const Curve easingStandard =
      Curves.easeInOut; // cubic-bezier(0.4, 0.0, 0.2, 1)
  static const Curve easingDecelerate =
      Curves.easeOut; // cubic-bezier(0.0, 0.0, 0.2, 1)
  static const Curve easingAccelerate =
      Curves.easeIn; // cubic-bezier(0.4, 0.0, 1, 1)
  static const Curve easingSharp =
      Curves.easeInOut; // cubic-bezier(0.4, 0.0, 0.6, 1)
  static const Curve easingDefault = easingStandard;

  // ==================== ACCESSIBILITY ====================

  static double get minTouchTarget => 44.w;
  static const double minContrast = 4.5; // WCAG AA standard
  static double get focusOutlineWidth => 2.w;
  static double get focusOutlineOffset => 2.w;

  // ==================== BREAKPOINTS ====================

  static double get breakpointMobile => 0.w;
  static double get breakpointTablet => 768.w;
  static double get breakpointDesktop => 1024.w;
  static double get breakpointWide => 1440.w;
}
