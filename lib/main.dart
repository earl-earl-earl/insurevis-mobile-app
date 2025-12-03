import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insurevis/screens/main-screens/profile_screen.dart';
import 'package:insurevis/screens/main-screens/claims_screen.dart';
import 'package:insurevis/models/firebase_msg.dart';
import 'package:insurevis/screens/other-screens/faq_screen.dart';
import 'package:insurevis/screens/other-screens/gallery_view.dart';
import 'package:insurevis/screens/other-screens/insurance_document_upload.dart';
import 'package:insurevis/screens/other-screens/pdf_assessment_view.dart';
import 'package:insurevis/screens/other-screens/privacy_policy_screen.dart';
import 'package:insurevis/screens/other-screens/terms_of_service_screen.dart';
import 'package:insurevis/screens/other-screens/vehicle_information_form.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:insurevis/services/user_device_service.dart';
import 'package:insurevis/config/supabase_config.dart';
import 'package:insurevis/services/prices_repository.dart';
import 'package:insurevis/services/car_brands_repository.dart';
import 'package:insurevis/screens/login-signup/signin.dart';
import 'package:insurevis/screens/login-signup/signup.dart';
import 'package:insurevis/screens/login-signup/app_initializer.dart';
import 'package:insurevis/screens/main-screens/main_container.dart';
import 'package:insurevis/screens/onboarding/app_onboarding_page.dart';
import 'package:insurevis/screens/other-screens/camera.dart';
import 'package:insurevis/screens/other-screens/notification_center.dart';
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
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    try {
      await FirebaseMsg().initFCM();
    } catch (e) {
      debugPrint('Warning: FirebaseMsg.initFCM failed: $e');
    }
  } catch (e) {
    // If Firebase fails (no network / misconfigured), log and continue so app can work offline
    debugPrint('Warning: Firebase initialization failed: $e');
  }

  // Initialize Supabase (best-effort). If it fails, continue with limited functionality.
  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );

    // Start user device service to manage FCM tokens (best-effort)
    try {
      final _deviceService = UserDeviceService(Supabase.instance.client);
      await _deviceService.init();
    } catch (e) {
      debugPrint('Warning: UserDeviceService.init failed: $e');
    }
  } catch (e) {
    debugPrint('Warning: Supabase initialization failed: $e');
  }

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

  // Initialize car brands cache in background thread
  Future.microtask(() async {
    try {
      await CarBrandsRepository.instance.init();
    } catch (e, st) {
      // Don't block app start on car brands init failures
      debugPrint('CarBrandsRepository init failed: $e\n$st');
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

  // Global key for navigation
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

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

                  // When user opens app from notification (app in background or foreground)
                  FirebaseMsg.onMessageOpenedCallback = (message) {
                    // Refresh from database
                    notificationProvider.refreshNotifications();

                    // Navigate to notification center using global navigator key
                    MainApp.navigatorKey.currentState?.pushNamed(
                      '/notifications',
                    );
                  };

                  // Handle initial message when app is opened from terminated state
                  FirebaseMessaging.instance.getInitialMessage().then((
                    message,
                  ) {
                    if (message != null) {
                      debugPrint(
                        'App opened from terminated state via notification',
                      );
                      notificationProvider.refreshNotifications();

                      // Set a flag to navigate after app initialization completes
                      AppInitializerState.shouldNavigateToNotifications = true;
                    }
                  });
                } catch (e) {
                  print('Error registering FCM callbacks: $e');
                }
              });
              return MaterialApp(
                title: 'InsureVis',
                navigatorKey: MainApp.navigatorKey,
                theme: themeProvider.lightTheme.copyWith(
                  // Apply custom fonts to theme
                  textTheme: themeProvider.lightTheme.textTheme.apply(
                    fontFamily: 'Manrope', // Body font
                  ),
                  // Headings use Geist font
                  primaryTextTheme: themeProvider.lightTheme.primaryTextTheme
                      .apply(
                        fontFamily: 'Geist', // Heading font
                      ),
                ),
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
                  '/notifications': (context) => const NotificationCenter(),
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
                  '/vehicle_info': (context) => const VehicleInformationForm(),
                },
              );
            },
          ),
        );
      },
    );
  }
}
