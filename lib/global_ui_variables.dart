import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class GlobalStyles {
  static const MaterialColor richVibrantPurple =
      MaterialColor(0xFF5E4FCF, <int, Color>{
        50: Color(0xFFF1EFFB),
        100: Color(0xFFDAD5F5),
        200: Color(0xFFC0B9EF),
        300: Color(0xFFA59CE8),
        400: Color(0xFF8F84E3),
        500: Color(0xFF5E4FCF),
        600: Color(0xFF5346BA),
        700: Color(0xFF483DA5),
        800: Color(0xFF3D3390),
        900: Color(0xFF2E246E),
      });

  static const Color primaryColor = Color(0xFF5E4FCF);
  static const Color secondaryColor = Color(0xFFA39BC8);

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
  static const Color backgroundColorStart = darkBackgroundColorStart;
  static const Color backgroundColorEnd = darkBackgroundColorEnd;
  static const Color appBarBackgroundColor = darkAppBarBackgroundColor;
  static const Color textColor = darkTextColor;
  static const Color textSecondaryColor = darkTextSecondaryColor;

  static final EdgeInsets defaultPadding = EdgeInsets.symmetric(
    horizontal: 30.w,
  );

  // Dynamic text styles based on theme
  static TextStyle getHeadingStyle(bool isDarkMode) => GoogleFonts.poppins(
    color: primaryColor,
    fontSize: 60.sp,
    fontWeight: FontWeight.w900,
    height: 1,
  );

  static TextStyle getSubheadingStyle(bool isDarkMode) => GoogleFonts.poppins(
    color: getTextColor(isDarkMode),
    fontSize: 20.sp,
    fontWeight: FontWeight.w900,
    height: 1,
  );

  static TextStyle getButtonTextStyle(bool isDarkMode) => GoogleFonts.poppins(
    color: getTextSecondaryColor(isDarkMode),
    fontWeight: FontWeight.w900,
    fontSize: 14.sp,
  );

  static TextStyle getOnboardingTitleStyle(bool isDarkMode) =>
      GoogleFonts.poppins(
        color: getTextColor(isDarkMode),
        fontSize: 35.sp,
        fontWeight: FontWeight.w900,
        height: 1,
      );

  static TextStyle getOnboardingDescriptionStyle(bool isDarkMode) =>
      GoogleFonts.poppins(color: getTextColor(isDarkMode), fontSize: 13.sp);

  static TextStyle getLoadingTextStyle(bool isDarkMode) =>
      GoogleFonts.poppins(color: getTextColor(isDarkMode), fontSize: 16.sp);

  // Legacy static text styles for backward compatibility
  static final TextStyle headingStyle = GoogleFonts.poppins(
    color: primaryColor,
    fontSize: 60.sp,
    fontWeight: FontWeight.w900,
    height: 1,
  );

  static final TextStyle subheadingStyle = GoogleFonts.poppins(
    color: textColor,
    fontSize: 20.sp,
    fontWeight: FontWeight.w900,
    height: 1,
  );

  static final TextStyle buttonTextStyle = GoogleFonts.poppins(
    color: textSecondaryColor,
    fontWeight: FontWeight.w900,
    fontSize: 14.sp,
  );
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

  static const Color gradientBackgroundStart = Color(0xFF1E1E1E);
  static const Color gradientBackgroundEnd = Color.fromARGB(255, 7, 7, 7);
  static const Color circularButtonColor = Color(0xFF6B4AFF);

  static final TextStyle loadingTextStyle = GoogleFonts.poppins(
    color: textColor,
    fontSize: 16.sp,
  );

  // Dynamic gradient background
  static BoxDecoration getGradientBackground(bool isDarkMode) => BoxDecoration(
    gradient: LinearGradient(
      colors: [
        isDarkMode ? gradientBackgroundStart : lightBackgroundColorStart,
        isDarkMode ? gradientBackgroundEnd : lightBackgroundColorEnd,
      ],
      end: Alignment.bottomCenter,
    ),
  );

  static final BoxDecoration gradientBackground = const BoxDecoration(
    gradient: LinearGradient(
      colors: [gradientBackgroundStart, gradientBackgroundEnd],
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
