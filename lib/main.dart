import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/login-signup/signin.dart';
import 'package:insurevis/main-screens/main_container.dart';
import 'package:insurevis/onboarding/app_onboarding_page.dart';
import 'package:insurevis/onboarding/welcome.dart';
import 'package:insurevis/providers/assessment_provider.dart';
import 'package:insurevis/providers/notification_provider.dart';
import 'package:insurevis/providers/user_provider.dart';
// ignore: depend_on_referenced_packages
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
            ChangeNotifierProvider(create: (_) => UserProvider()),
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
          child: MaterialApp(
            title: 'Insurevis',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              brightness: Brightness.light,
            ),
            debugShowCheckedModeBanner: false,
            home: const Welcome(),
            routes: {
              '/signin': (context) => const SignIn(),
              '/app_onboarding': (context) => const AppOnboardingScreen(),
              '/home': (context) => const MainContainer(),
            },
          ),
        );
      },
    );
  }
}
