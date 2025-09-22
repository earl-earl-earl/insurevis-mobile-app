import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insurevis/main-screens/profile_screen.dart';
import 'package:insurevis/main-screens/claims_screen.dart';
import 'package:insurevis/models/firebase_msg.dart';
import 'package:insurevis/other-screens/faq_screen.dart';
import 'package:insurevis/other-screens/gallery_view.dart';
import 'package:insurevis/other-screens/insurance_document_upload.dart';
import 'package:insurevis/other-screens/pdf_assessment_view.dart';
import 'package:insurevis/other-screens/privacy_policy_screen.dart';
import 'package:insurevis/other-screens/terms_of_service_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:insurevis/services/user_device_service.dart';
import 'package:insurevis/config/supabase_config.dart';
import 'package:insurevis/services/prices_repository.dart';
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

  // Initialize prices cache so UI can read cached lists without hitting the API repeatedly.
  // Run asynchronously without awaiting so app startup isn't blocked. We use
  // Future.microtask to schedule the work on the event loop; moving this to a
  // separate isolate is possible but requires the init code to be isolate-safe.
  Future.microtask(() async {
    try {
      await PricesRepository.instance.init();
    } catch (e, st) {
      // Don't block app start on pricing init failures; UI will fallback to live fetches
      // Include stack trace to aid debugging.
      debugPrint('PricesRepository init failed: $e\n$st');
    }
  });

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
      statusBarColor: Color(0xFF2A2A2A),
      statusBarIconBrightness: Brightness.light,
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
    precacheImage(const AssetImage('assets/images/logo/4.png'), context);

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
                // Intentionally not forwarding assessment lifecycle events into NotificationProvider.
                // If you want assessment-driven notifications later, re-enable here with caution.
                return assessmentProvider ?? AssessmentProvider();
              },
            ),
          ],
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              // Register FCM in-memory callbacks once the widget tree is available
              WidgetsBinding.instance.addPostFrameCallback((_) {
                try {
                  final notificationProvider =
                      Provider.of<NotificationProvider>(context, listen: false);

                  // Foreground message: only refresh from database
                  // The server already creates the notification in DB and sends FCM
                  // We just need to sync the database notification to show in UI
                  FirebaseMsg.onMessageCallback = (message) {
                    // Only refresh from database - don't show additional local notification
                    // The FCM message itself provides the system notification
                    notificationProvider.refreshNotifications();
                  };

                  // When user opens app from notification
                  FirebaseMsg.onMessageOpenedCallback = (message) {
                    // Only refresh from database and handle navigation
                    // Don't show additional local notification
                    notificationProvider.refreshNotifications();

                    // TODO: Handle navigation to specific screen based on message data
                    // You can access message.data here to navigate to specific screens
                    // For example:
                    // if (message.data['screen'] == 'claims') {
                    //   Navigator.of(context).pushNamed('/claims');
                    // }
                  };
                } catch (e) {
                  print('Error registering FCM callbacks: $e');
                }
              });
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
                  '/terms': (context) => const TermsOfServiceScreen(),
                  '/assessment_report': (context) => const PDFAssessmentView(),
                },
              );
            },
          ),
        );
      },
    );
  }
}
