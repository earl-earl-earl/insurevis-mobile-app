import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/login-signup/signin.dart';
import 'package:insurevis/login-signup/signin_email.dart';
import 'package:insurevis/main-screens/main_container.dart';
import 'package:insurevis/onboarding/app_onboarding_page.dart';
import 'package:insurevis/onboarding/welcome.dart';
import 'package:insurevis/providers/assessment_provider.dart';
// ignore: depend_on_referenced_packages
import 'package:google_fonts/google_fonts.dart';
import 'dart:io'; // Add this import for Platform

void main() {
  // Add these lines for better performance
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation
  // For Vulkan/OpenGL settings, configure in Android manifest instead
  if (Platform.isAndroid) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  // Optimize frame rendering
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Preload common images used across the app
    precacheImage(const AssetImage('assets/images/onboarding.jpeg'), context);

    return ScreenUtilInit(
      designSize: const Size(412, 915),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AssessmentProvider()),
            // Add other providers if needed
          ],
          child: MaterialApp(
            title: 'Insurevis',
            theme: ThemeData(
              fontFamily: GoogleFonts.poppins().fontFamily,
              primarySwatch: GlobalStyles.richVibrantPurple,
              // Add these lines for smoother scrolling
              scrollbarTheme: ScrollbarThemeData(
                thickness: MaterialStateProperty.all(4),
                thumbColor: MaterialStateProperty.all(
                  GlobalStyles.primaryColor.withOpacity(0.5),
                ),
              ),
              // Note: For image optimization, set quality on individual Image widgets
              primaryColor: GlobalStyles.primaryColor,
              scaffoldBackgroundColor: Colors.transparent,
              colorScheme: ColorScheme.fromSeed(
                seedColor: GlobalStyles.primaryColor,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            // Add this for better performance
            debugShowCheckedModeBanner: false,

            // Your existing routes
            home: const Welcome(),
            routes: {
              '/signin': (context) => const SignIn(),
              '/signin_email': (context) => const SignInEmail(),
              '/app_onboarding': (context) => const AppOnboardingScreen(),
              '/home':
                  (context) =>
                      const MainContainer(), // Changed from Home to MainContainer
            },
          ),
        );
      },
    );
  }
}
