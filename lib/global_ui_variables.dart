import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
  static const Color backgroundColorStart = Color(0xFF1D1F24);
  static const Color backgroundColorEnd = Color(0xFF121316);
  static const Color appBarBackgroundColor = Color(0xFF1E1E1E);
  static const Color textColor = Colors.white;
  static const Color textSecondaryColor = Colors.white70;

  static final EdgeInsets defaultPadding = EdgeInsets.symmetric(
    horizontal: 30.w,
  );

  static final TextStyle headingStyle = TextStyle(
    color: primaryColor,
    fontSize: 60.sp,
    fontWeight: FontWeight.w900,
    height: 1,
  );

  static final TextStyle subheadingStyle = TextStyle(
    color: textColor,
    fontSize: 20.sp,
    fontWeight: FontWeight.w900,
    height: 1,
  );

  static final TextStyle buttonTextStyle = TextStyle(
    color: textSecondaryColor,
    fontWeight: FontWeight.w900,
    fontSize: 14.sp,
  );

  // Onboarding styles
  static final TextStyle onboardingTitleStyle = TextStyle(
    color: textColor,
    fontSize: 35.sp,
    fontWeight: FontWeight.w900,
    height: 1,
  );

  static final TextStyle onboardingDescriptionStyle = TextStyle(
    color: textColor,
    fontSize: 13.sp,
  );

  static final TextStyle buttonNextTextStyle = TextStyle(
    color: Color(0xFF2B1D6B),
    fontSize: 16.sp,
    fontWeight: FontWeight.w900,
  );

  static const Color indicatorActiveColor = Colors.white;
  static const Color indicatorInactiveColor = Colors.grey;

  static const Color gradientBackgroundStart = Color(0xFF1E1E1E);
  static const Color gradientBackgroundEnd = Color.fromARGB(255, 7, 7, 7);
  static const Color circularButtonColor = Color(0xFF6B4AFF);

  static final TextStyle welcomeHeadingStyle = TextStyle(
    color: primaryColor,
    fontSize: 40.sp,
    fontWeight: FontWeight.w900,
  );

  static final TextStyle welcomeSubheadingStyle = TextStyle(
    color: textColor,
    fontSize: 40.sp,
    fontWeight: FontWeight.w900,
  );

  static final TextStyle loadingTextStyle = TextStyle(
    color: textColor,
    fontSize: 16.sp,
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
