import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insurevis/main-screens/profile_screen.dart';
import 'package:insurevis/main-screens/claims_screen.dart';
import 'package:insurevis/models/firebase_msg.dart';
import 'package:insurevis/other-screens/faq_screen.dart';
import 'package:insurevis/other-screens/gallery_view.dart';
import 'package:insurevis/other-screens/insurance_document_upload.dart';
import 'package:insurevis/other-screens/privacy_policy_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:insurevis/services/user_device_service.dart';
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

  // Initialize Firebase (required for firebase_messaging)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseMsg().initFCM();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Start user device service to manage FCM tokens
  final _deviceService = UserDeviceService(Supabase.instance.client);
  await _deviceService.init();

  // Force portrait orientation
  // For Vulkan/OpenGL settings, configure in Android manifest instead
  if (Platform.isAndroid) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
    ),
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
                // Keep darkTheme available but force the app to light mode
                darkTheme: themeProvider.darkTheme,
                themeMode: ThemeMode.light,
                debugShowCheckedModeBanner: false,
                home: const AppInitializer(),
                routes: {
                  '/signin': (context) => const SignIn(),
                  '/signup': (context) => const SignUp(),
                  '/app_onboarding': (context) => const AppOnboardingScreen(),
                  '/home': (context) => const MainContainer(),
                  // Claims list screen
                  ClaimsScreen.routeName: (context) => const ClaimsScreen(),
                  // Claim creation / document upload flow - provide empty defaults when navigating by name
                  '/claim_create':
                      (context) => const InsuranceDocumentUpload(
                        imagePaths: [],
                        apiResponses: {},
                        assessmentIds: {},
                      ),
                  '/camera': (context) => const CameraScreen(),
                  '/profile': (context) => const ProfileScreen(),
                  '/gallery': (context) => const GalleryScreen(),
                  '/faq': (context) => const FAQScreen(),
                  '/policy': (context) => const PrivacyPolicyScreen(),
                },
              );
            },
          ),
        );
      },
    );
  }
}
