import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/login-signup/signin.dart';
import 'package:insurevis/login-signup/signin_email.dart';
import 'package:insurevis/main-screens/home.dart';
import 'package:insurevis/onboarding/app_onboarding_page.dart';
import 'package:insurevis/onboarding/welcome.dart';
// ignore: depend_on_referenced_packages
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(412, 915),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          theme: ThemeData(
            fontFamily: GoogleFonts.poppins().fontFamily,
            primarySwatch: GlobalStyles.richVibrantPurple,
            primaryColor: GlobalStyles.richVibrantPurple[500],
            splashColor: GlobalStyles.richVibrantPurple[800],
            highlightColor: GlobalStyles.richVibrantPurple[700],
            hoverColor: GlobalStyles.richVibrantPurple[50],
            splashFactory: InkRipple.splashFactory,
          ),
          home: const Welcome(),
          debugShowCheckedModeBanner: false,
          routes: {
            '/signin': (context) => const SignIn(),
            '/signin_email': (context) => const SignInEmail(),
            '/app_onboarding': (context) => const AppOnboardingScreen(),
            '/home': (context) => const Home(),
          },
        );
      },
    );
  }
}
