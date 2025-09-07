import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/providers/auth_provider.dart';
import 'package:insurevis/onboarding/app_onboarding_page.dart';
import 'package:insurevis/main-screens/main_container.dart';
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
  bool _assetsLoaded = false;
  bool _authInitialized = false;
  String _loadingStatus = "Initializing...";
  double _loadingProgress = 0.0;

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

      // Remove the native splash screen after initialization is complete
      FlutterNativeSplash.remove();

      if (mounted) {
        _navigateToNextScreen();
      }
    } catch (e) {
      // Remove splash screen even on error
      FlutterNativeSplash.remove();
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
          _authInitialized = true;
          _loadingProgress = 1.0;
          _loadingStatus = "Ready!";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingStatus = "Authentication initialization failed";
        });
      }
      rethrow;
    }
  }

  void _navigateToNextScreen() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isLoggedIn) {
      // User is logged in - go to home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainContainer()),
      );
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
        content: const Text("Failed to initialize app. Please restart."),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        margin: const EdgeInsets.all(20),
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
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              GlobalStyles.backgroundColorStart,
              GlobalStyles.backgroundColorEnd,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
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
                          image: AssetImage("assets/images/loggers.png"),
                        ),
                      ),
                      height: 120.h,
                      width: 120.w,
                    ),

                    SizedBox(height: 40.h),

                    // App name
                    Text(
                      "InsureVis",
                      style: GlobalStyles.headingStyle.copyWith(
                        color: Colors.white,
                        fontSize: 36.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 8.h),

                    // Tagline
                    Text(
                      "AI-Powered Vehicle Assessment",
                      style: TextStyle(
                        color: GlobalStyles.primaryColor,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
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
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(3.r),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _loadingProgress,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: GlobalStyles.primaryColor,
                                  borderRadius: BorderRadius.circular(3.r),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),

                          // Loading status text
                          Text(
                            _loadingStatus,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14.sp,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: 8.h),

                          // Progress percentage
                          Text(
                            "${(_loadingProgress * 100).toInt()}%",
                            style: TextStyle(
                              color: GlobalStyles.primaryColor,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
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
                                        isConnected ? Colors.green : Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  isConnected ? "Connected" : "No Connection",
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12.sp,
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
