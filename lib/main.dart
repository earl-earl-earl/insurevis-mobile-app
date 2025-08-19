import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart'; // Add this import
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:insurevis/config/supabase_config.dart';
import 'package:insurevis/login-signup/signin.dart';
import 'package:insurevis/login-signup/signup.dart';
import 'package:insurevis/login-signup/app_initializer.dart';
import 'package:insurevis/main-screens/main_container.dart';
import 'package:insurevis/onboarding/app_onboarding_page.dart';
import 'package:insurevis/other-screens/camera.dart';
import 'package:insurevis/providers/assessment_provider.dart';
import 'package:insurevis/providers/notification_provider.dart';
import 'package:insurevis/providers/user_provider.dart';
import 'package:insurevis/providers/auth_provider.dart';
import 'package:insurevis/providers/theme_provider.dart';
// ignore: depend_on_referenced_packages
import 'dart:io'; // Add this import for Platform

void main() async {
  // Add these lines for better performance
  WidgetsFlutterBinding.ensureInitialized();

  // Preserve the splash screen until we manually remove it
  FlutterNativeSplash.preserve(
    widgetsBinding: WidgetsFlutterBinding.ensureInitialized(),
  );

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

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
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => UserProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => NotificationProvider()),
            ChangeNotifierProxyProvider<
              NotificationProvider,
              AssessmentProvider
            >(
              create: (_) => AssessmentProvider(),
              update: (_, notificationProvider, assessmentProvider) {
                if (assessmentProvider != null) {
                  assessmentProvider.onNotificationNeeded = (
                    type,
                    title,
                    message,
                  ) {
                    if (type == 'assessment_started') {
                      notificationProvider.addAssessmentStarted(title);
                    } else if (type == 'assessment_completed') {
                      notificationProvider.addAssessmentCompleted(title);
                    }
                  };
                }
                return assessmentProvider ?? AssessmentProvider();
              },
            ),
          ],
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return MaterialApp(
                title: 'InsureVis',
                theme: themeProvider.lightTheme,
                darkTheme: themeProvider.darkTheme,
                themeMode:
                    themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
                debugShowCheckedModeBanner: false,
                home: const AppInitializer(),
                routes: {
                  '/signin': (context) => const SignIn(),
                  '/signup': (context) => const SignUp(),
                  '/app_onboarding': (context) => const AppOnboardingScreen(),
                  '/home': (context) => const MainContainer(),
                  '/camera': (context) => const CameraScreen(),
                },
              );
            },
          ),
        );
      },
    );
  }
}
