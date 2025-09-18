import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class GlobalStyles {
  static const MaterialColor vibrantBlue = MaterialColor(
    0xFF0066FF,
    <int, Color>{
      50: Color(0xFFE6F0FF),
      100: Color(0xFFB3D1FF),
      200: Color(0xFF80B3FF),
      300: Color(0xFF4D94FF),
      400: Color(0xFF1A75FF),
      500: Color(0xFF0066FF), // Base
      600: Color(0xFF0059E6),
      700: Color(0xFF0047B3),
      800: Color(0xFF003380),
      900: Color(0xFF002266),
    },
  );

  static const Color primaryColor = Color(0xFF0066FF);
  static const Color secondaryColor = Color(0xFF4D94FF);

  // Dark theme colors
  static const Color darkBackgroundColorStart = Color(0xFF1D1F24);
  static const Color darkBackgroundColorEnd = Color(0xFF121316);
  static const Color darkAppBarBackgroundColor = Color(0xFF1E1E1E);
  static const Color darkTextColor = Colors.white;
  static const Color darkTextSecondaryColor = Colors.white70;

  // Light theme colors
  static const Color lightBackgroundColorStart = Color(0xFFF8F9FA);
  static const Color lightBackgroundColorEnd = Color(0xFFE9ECEF);
  static const Color lightAppBarBackgroundColor = Colors.white;
  static const Color lightTextColor = Color(0xFF212529);
  static const Color lightTextSecondaryColor = Color(0xFF6C757D);

  // Dynamic color getters based on theme
  static Color getBackgroundColorStart(bool isDarkMode) {
    return isDarkMode ? darkBackgroundColorStart : lightBackgroundColorStart;
  }

  static Color getBackgroundColorEnd(bool isDarkMode) {
    return isDarkMode ? darkBackgroundColorEnd : lightBackgroundColorEnd;
  }

  static Color getAppBarBackgroundColor(bool isDarkMode) {
    return isDarkMode ? darkAppBarBackgroundColor : lightAppBarBackgroundColor;
  }

  static Color getTextColor(bool isDarkMode) {
    return isDarkMode ? darkTextColor : lightTextColor;
  }

  static Color getTextSecondaryColor(bool isDarkMode) {
    return isDarkMode ? darkTextSecondaryColor : lightTextSecondaryColor;
  }

  // Keep legacy static colors for backward compatibility
  // static const Color backgroundColorStart = darkBackgroundColorStart;
  // static const Color backgroundColorEnd = darkBackgroundColorEnd;
  // static const Color appBarBackgroundColor = darkAppBarBackgroundColor;
  static const Color backgroundColorStart = lightBackgroundColorStart;
  static const Color backgroundColorEnd = lightBackgroundColorEnd;
  static const Color appBarBackgroundColor = lightAppBarBackgroundColor;
  static const Color textColor = lightTextColor;
  static const Color textSecondaryColor = lightTextSecondaryColor;

  static final EdgeInsets defaultPadding = EdgeInsets.symmetric(
    horizontal: 30.w,
  );

  // Google Sans-like text styles using Inter (default for most UI elements)
  static TextStyle getGoogleSansHeadingStyle(bool isDarkMode) =>
      GoogleFonts.inter(
        color: primaryColor,
        fontSize: 60.sp,
        fontWeight: FontWeight.w900,
        height: 1,
      );

  static TextStyle getGoogleSansSubheadingStyle(bool isDarkMode) =>
      GoogleFonts.inter(
        color: getTextColor(isDarkMode),
        fontSize: 20.sp,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );

  static TextStyle getGoogleSansButtonTextStyle(bool isDarkMode) =>
      GoogleFonts.inter(
        color: getTextSecondaryColor(isDarkMode),
        fontWeight: FontWeight.w600,
        fontSize: 14.sp,
      );

  static TextStyle getGoogleSansBodyStyle(bool isDarkMode) => GoogleFonts.inter(
    color: getTextColor(isDarkMode),
    fontSize: 16.sp,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle getGoogleSansCaptionStyle(bool isDarkMode) =>
      GoogleFonts.inter(
        color: getTextSecondaryColor(isDarkMode),
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
      );

  // Poppins text styles (kept for specific branding elements)
  static TextStyle getPoppinsHeadingStyle(bool isDarkMode) =>
      GoogleFonts.poppins(
        color: primaryColor,
        fontSize: 60.sp,
        fontWeight: FontWeight.w900,
        height: 1,
      );

  static TextStyle getPoppinsBrandStyle(bool isDarkMode) => GoogleFonts.poppins(
    color: primaryColor,
    fontSize: 24.sp,
    fontWeight: FontWeight.w700,
  );

  // Dynamic text styles based on theme (now defaulting to Google Sans)
  static TextStyle getHeadingStyle(bool isDarkMode) =>
      getGoogleSansHeadingStyle(isDarkMode);

  static TextStyle getSubheadingStyle(bool isDarkMode) =>
      getGoogleSansSubheadingStyle(isDarkMode);

  static TextStyle getButtonTextStyle(bool isDarkMode) =>
      getGoogleSansButtonTextStyle(isDarkMode);

  static TextStyle getOnboardingTitleStyle(bool isDarkMode) =>
      getGoogleSansSubheadingStyle(
        isDarkMode,
      ).copyWith(fontSize: 35.sp, fontWeight: FontWeight.w700);

  static TextStyle getOnboardingDescriptionStyle(bool isDarkMode) =>
      getGoogleSansBodyStyle(isDarkMode).copyWith(fontSize: 13.sp);

  static TextStyle getLoadingTextStyle(bool isDarkMode) =>
      getGoogleSansBodyStyle(isDarkMode);

  // Legacy static text styles for backward compatibility (updated to use Inter)
  static final TextStyle headingStyle = GoogleFonts.inter(
    color: primaryColor,
    fontSize: 60.sp,
    fontWeight: FontWeight.w900,
    height: 1,
  );

  static final TextStyle subheadingStyle = GoogleFonts.inter(
    color: textColor,
    fontSize: 20.sp,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static final TextStyle buttonTextStyle = GoogleFonts.inter(
    color: textSecondaryColor,
    fontWeight: FontWeight.w600,
    fontSize: 14.sp,
  );

  // Poppins branding styles (for logo, app name, and brand-specific elements)
  static TextStyle getPoppinsBranding({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
  }) {
    return GoogleFonts.poppins(
      color: color ?? primaryColor,
      fontSize: fontSize ?? 16.sp,
      fontWeight: fontWeight ?? FontWeight.w700,
      height: height,
    );
  }

  static TextStyle getPoppinsTitle({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
  }) {
    return GoogleFonts.poppins(
      color: color ?? textColor,
      fontSize: fontSize ?? 24.sp,
      fontWeight: fontWeight ?? FontWeight.w800,
      height: height,
    );
  }

  // Onboarding styles
  static final TextStyle onboardingTitleStyle = GoogleFonts.poppins(
    color: textColor,
    fontSize: 35.sp,
    fontWeight: FontWeight.w900,
    height: 1,
  );

  static final TextStyle onboardingDescriptionStyle = GoogleFonts.poppins(
    color: textColor,
    fontSize: 13.sp,
  );

  static final TextStyle buttonNextTextStyle = GoogleFonts.poppins(
    color: Color(0xFF2B1D6B),
    fontSize: 16.sp,
    fontWeight: FontWeight.w900,
  );

  static const Color indicatorActiveColor = Colors.white;
  static const Color indicatorInactiveColor = Colors.grey;

  // static const Color gradientBackgroundStart = Color(0xFF1E1E1E);
  // static const Color gradientBackgroundEnd = Color.fromARGB(255, 7, 7, 7);
  static const Color circularButtonColor = Color(0xFF6B4AFF);

  static final TextStyle loadingTextStyle = GoogleFonts.poppins(
    color: textColor,
    fontSize: 16.sp,
  );

  // Dynamic gradient background
  static BoxDecoration getGradientBackground(bool isDarkMode) => BoxDecoration(
    gradient: LinearGradient(
      colors: [
        isDarkMode ? backgroundColorStart : lightBackgroundColorStart,
        isDarkMode ? backgroundColorEnd : lightBackgroundColorEnd,
      ],
      end: Alignment.bottomCenter,
    ),
  );

  static final BoxDecoration gradientBackground = const BoxDecoration(
    gradient: LinearGradient(
      colors: [backgroundColorStart, backgroundColorEnd],
      end: Alignment.bottomCenter,
    ),
  );

  static final ButtonStyle circularButtonStyle = ElevatedButton.styleFrom(
    shape: const CircleBorder(),
    fixedSize: Size(60.w, 60.w),
    backgroundColor: circularButtonColor,
    padding: EdgeInsets.all(0.r),
  );

  static final double leadingPaddingLeft = 30.0;
  static final double leadingPaddingTop = 20.0;
  static final Color paleWhite = Colors.white24;

  static AppBar buildCustomAppBar({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required Color appBarBackgroundColor,
  }) {
    return AppBar(
      backgroundColor: appBarBackgroundColor,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: Icon(icon, color: color, size: 24.sp),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
