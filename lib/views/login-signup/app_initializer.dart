import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/providers/auth_provider.dart';
import 'package:insurevis/onboarding/app_onboarding_page.dart';
import 'package:insurevis/views/main-screens/main_container.dart';
import 'package:insurevis/services/local_storage_service.dart';

/// App initialization screen that handles authentication state,
/// preloads assets, and determines which screen to show on app startup
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  AppInitializerState createState() => AppInitializerState();
}

class AppInitializerState extends State<AppInitializer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Loading state management
  // ignore: unused_field
  bool _assetsLoaded = false;
  String _loadingStatus = "Initializing...";
  double _loadingProgress = 0.0;

  // Static flag for notification navigation from terminated state
  static bool shouldNavigateToNotifications = false;

  // List of assets to preload
  final List<String> _imagePaths = [
    'assets/images/app_logo.png',
    'assets/images/camera_bg.png',
    'assets/images/loggers.png',
    'assets/images/onboarding.jpeg',
    'assets/images/welcome_car.png',
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // Start the loading process
    _startLoadingProcess();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Start the complete loading process
  Future<void> _startLoadingProcess() async {
    try {
      // Step 1: Initialize app folders
      setState(() {
        _loadingStatus = "Setting up app folders...";
        _loadingProgress = 0.1;
      });
      await _initializeAppFolders();

      // Step 2: Preload assets
      setState(() {
        _loadingStatus = "Loading assets...";
        _loadingProgress = 0.4;
      });
      await _preloadAssets();

      // Step 3: Initialize authentication
      setState(() {
        _loadingStatus = "Initializing authentication...";
        _loadingProgress = 0.8;
      });
      await _initializeAuth();

      setState(() {
        _loadingStatus = "Ready!";
        _loadingProgress = 1.0;
      });

      // Wait a minimum amount of time for smooth UX
      await Future.delayed(const Duration(milliseconds: 500));

      // Native splash removed - proceed to next screen

      if (mounted) {
        _navigateToNextScreen();
      }
    } catch (e) {
      // Native splash removed - proceed to error handling
      if (mounted) {
        _showErrorAndNavigateToOnboarding();
      }
    }
  }

  /// Preload all application assets
  Future<void> _preloadAssets() async {
    setState(() {
      _loadingStatus = "Loading assets...";
      _loadingProgress = 0.0;
    });

    for (int i = 0; i < _imagePaths.length; i++) {
      try {
        await precacheImage(AssetImage(_imagePaths[i]), context);

        if (mounted) {
          setState(() {
            _loadingProgress =
                (i + 1) / _imagePaths.length * 0.7; // 70% for assets
            _loadingStatus = "Loading assets... ${i + 1}/${_imagePaths.length}";
          });
        }

        // Small delay to show progress
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        // Continue loading even if one asset fails
        if (mounted) {
          setState(() {
            _loadingStatus = "Failed to load some assets";
          });
        }
      }
    }

    if (mounted) {
      setState(() {
        _assetsLoaded = true;
        _loadingProgress = 0.7;
        _loadingStatus = "Assets loaded successfully";
      });
    }
  }

  /// Initialize app folder structure
  Future<void> _initializeAppFolders() async {
    try {
      final success = await LocalStorageService.initializeAppFolders();
      if (success) {
        print('App folders initialized successfully');
      } else {
        print('Warning: App folders initialization failed, but continuing...');
      }
    } catch (e) {
      print('Error during folder initialization: $e');
      // Don't throw error - this shouldn't prevent app from starting
    }
  }

  /// Initialize authentication
  Future<void> _initializeAuth() async {
    if (mounted) {
      setState(() {
        _loadingStatus = "Initializing authentication...";
        _loadingProgress = 0.7;
      });
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // Initialize auth provider
      await authProvider.initialize();

      if (mounted) {
        setState(() {
          _loadingStatus = "Authentication initialized";
          _loadingProgress = 1.0;
          _loadingStatus = "Ready!";
        });
      }
    } catch (e) {
      // Log the error but do not rethrow so app can continue offline.
      if (mounted) {
        setState(() {
          _loadingStatus =
              "Authentication initialization failed (offline mode)";
        });
      }
      debugPrint('Auth initialize failed, continuing in offline mode: $e');
      // Intentionally do not rethrow. The app will navigate using the current
      // value of authProvider.isLoggedIn (likely false) so onboarding or cached
      // screens can proceed even when network/auth failed.
    }
  }

  void _navigateToNextScreen() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isLoggedIn) {
      // User is logged in - go to home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainContainer()),
      ).then((_) {
        // After navigation completes, check if we need to navigate to notifications
        if (AppInitializerState.shouldNavigateToNotifications) {
          AppInitializerState.shouldNavigateToNotifications =
              false; // Reset flag
          // Navigate to notifications after a short delay to ensure UI is ready
          Future.delayed(const Duration(milliseconds: 300), () {
            if (context.mounted) {
              Navigator.of(context).pushNamed('/notifications');
            }
          });
        }
      });
    } else {
      // User is not logged in - go to onboarding screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AppOnboardingScreen()),
      );
    }
  }

  void _showErrorAndNavigateToOnboarding() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Failed to initialize app. Please restart.",
          style: TextStyle(
            fontFamily: GlobalStyles.fontFamilyBody,
            fontSize: GlobalStyles.fontSizeBody2,
            fontWeight: GlobalStyles.fontWeightMedium,
            color: GlobalStyles.surfaceMain,
          ),
        ),
        backgroundColor: GlobalStyles.errorMain,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
        ),
        margin: EdgeInsets.all(GlobalStyles.paddingNormal),
      ),
    );

    // Navigate to onboarding after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AppOnboardingScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalStyles.backgroundMain,
      appBar: AppBar(
        backgroundColor: GlobalStyles.backgroundMain,
        elevation: 0,
      ),
      body: SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App logo
                    Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage("assets/images/logo/4.png"),
                          fit: BoxFit.contain,
                        ),
                      ),
                      height: 120.h,
                      width: 120.w,
                    ),

                    SizedBox(height: 40.h),

                    // App name
                    RichText(
                      text: TextSpan(
                        text: "Insure",
                        style: TextStyle(
                          fontFamily: GlobalStyles.fontFamilyHeading,
                          color: GlobalStyles.textPrimary,
                          fontSize: GlobalStyles.fontSizeH1,
                          fontWeight: GlobalStyles.fontWeightBold,
                          letterSpacing: GlobalStyles.letterSpacingH1,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: "Vis",
                            style: TextStyle(
                              fontFamily: GlobalStyles.fontFamilyHeading,
                              color: GlobalStyles.primaryMain,
                              fontSize: GlobalStyles.fontSizeH1,
                              fontWeight: GlobalStyles.fontWeightBold,
                              letterSpacing: GlobalStyles.letterSpacingH1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 8.h),

                    // Tagline
                    Text(
                      "AI-Powered Vehicle Assessment",
                      style: TextStyle(
                        fontFamily: GlobalStyles.fontFamilyBody,
                        color: GlobalStyles.primaryMain,
                        fontSize: GlobalStyles.fontSizeH6,
                        fontWeight: GlobalStyles.fontWeightMedium,
                      ),
                    ),

                    SizedBox(height: 60.h),

                    // Loading progress and status
                    SizedBox(
                      width: 250.w,
                      child: Column(
                        children: [
                          // Progress bar
                          Container(
                            width: double.infinity,
                            height: 6.h,
                            decoration: BoxDecoration(
                              color: GlobalStyles.inputBorderColor,
                              borderRadius: BorderRadius.circular(
                                GlobalStyles.radiusFull,
                              ),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _loadingProgress,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: GlobalStyles.primaryMain,
                                  borderRadius: BorderRadius.circular(
                                    GlobalStyles.radiusFull,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),

                          // Loading status text
                          Text(
                            _loadingStatus,
                            style: TextStyle(
                              fontFamily: GlobalStyles.fontFamilyBody,
                              color: GlobalStyles.textTertiary,
                              fontSize: GlobalStyles.fontSizeBody2,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: 8.h),

                          // Progress percentage
                          Text(
                            "${(_loadingProgress * 100).toInt()}%",
                            style: TextStyle(
                              fontFamily: GlobalStyles.fontFamilyBody,
                              color: GlobalStyles.primaryMain,
                              fontSize: GlobalStyles.fontSizeH6,
                              fontWeight: GlobalStyles.fontWeightSemiBold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 60.h),

                    // Connection status indicator
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return FutureBuilder<bool>(
                          future: authProvider.checkConnection(),
                          builder: (context, snapshot) {
                            final isConnected = snapshot.data ?? false;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 8.w,
                                  height: 8.h,
                                  decoration: BoxDecoration(
                                    color:
                                        isConnected
                                            ? GlobalStyles.successMain
                                            : GlobalStyles.errorMain,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: GlobalStyles.spacingSm),
                                Text(
                                  isConnected ? "Connected" : "No Connection",
                                  style: TextStyle(
                                    fontFamily: GlobalStyles.fontFamilyBody,
                                    color: GlobalStyles.textDisabled,
                                    fontSize: GlobalStyles.fontSizeCaption,
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
