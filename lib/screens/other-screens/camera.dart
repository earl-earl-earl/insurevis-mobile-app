import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart'; // Make sure camera types like FlashMode are imported
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/screens/other-screens/multiple_results_screen.dart';
import 'package:insurevis/screens/other-screens/gallery_view.dart';
import 'package:insurevis/utils/camera_utils.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin {
  CameraController? _controller; // Make nullable for initialization phase
  Future<void>? _initializeControllerFuture;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0; // 0 for back, 1 for front usually
  bool _isInitializing = true; // Flag for loading state
  bool _isTakingPicture = false; // Flag to prevent multiple captures

  // ADDED: State for flash mode
  FlashMode _currentFlashMode = FlashMode.off;

  // Animation controllers for entry animations
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // Start animations after a brief delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
      }
    });

    // Initialize camera buffer optimization
    CameraUtils.initializeBufferOptimization();
    // Request permissions (only Camera needed now for core function) and initialize camera
    _initCameraOnly(); // Renamed from _initCameraAndGallery
  }

  // Renamed and simplified: Only initializes camera now
  Future<void> _initCameraOnly() async {
    // Ensure camera permissions (handled implicitly by camera plugin or explicitly if desired)
    // await _requestPermissions(); // You might still want a permission request step

    // Initialize camera
    await _initCamera(_selectedCameraIndex);

    if (mounted) {
      setState(() {
        _isInitializing = false; // Initialization complete
      });
    }
  }

  Future<void> _initCamera(int cameraIndex) async {
    // Dispose existing controller if switching cameras
    await _controller?.dispose();
    // Reset flash mode when initializing a new camera controller instance
    _currentFlashMode = FlashMode.off;

    if (_cameras.isEmpty) {
      _cameras = await CameraUtils.getAvailableCameras();
      // Handle case where no cameras are available
      if (_cameras.isEmpty) {
        // DEBUG: print("No cameras found on device.");
        if (mounted) {
          setState(() => _isInitializing = false); // Stop loading
          // Show an error message to the user
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No cameras available on this device.'),
            ),
          );
        }
        return;
      }
    }

    // Initialize camera using utility
    try {
      _controller = await CameraUtils.initializeCamera(cameraIndex, _cameras);

      if (_controller == null) {
        if (mounted) {
          setState(() => _isInitializing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to initialize camera')),
          );
        }
        return;
      }

      // Assign the future for the FutureBuilder
      _initializeControllerFuture = Future.value();

      // Update state if switching cameras and already mounted
      if (mounted && !_isInitializing) {
        setState(() {}); // Rebuild with the new controller
      }
    } catch (e) {
      // DEBUG: print("Error initializing camera: $e");
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            // DEBUG: print("Camera access denied");
            break;
          default:
            // DEBUG: print("Camera Error: ${e.description}");
            break;
        }
      }
      if (mounted) {
        setState(() => _isInitializing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to initialize camera: ${e is CameraException ? e.description : e}',
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Clear camera buffers and dispose controller
    CameraUtils.disposeCamera(_controller);
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isTakingPicture) {
      return;
    }

    setState(() => _isTakingPicture = true);

    try {
      // Provide haptic feedback
      await HapticFeedback.heavyImpact();

      await _initializeControllerFuture;

      final XFile? imageFile = await CameraUtils.takePicture(_controller);

      if (imageFile != null && mounted) {
        // Navigate to multiple results screen with the captured image
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    MultipleResultsScreen(imagePaths: [imageFile.path]),
          ),
        );
      }
    } catch (e) {
      // DEBUG: print("Error taking picture: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error taking picture: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isTakingPicture = false);
      }
    }
  } // Function to navigate to gallery

  void _openGallery() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GalleryScreen()),
    );
  }

  // ADDED: Function to toggle flash mode
  Future<void> _toggleFlashMode() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isInitializing) {
      // DEBUG: print("Camera not ready to change flash mode.");
      return;
    }

    try {
      // Provide haptic feedback
      await HapticFeedback.selectionClick();

      // Ensure initialization future is complete before setting flash
      await _initializeControllerFuture;

      final nextFlashMode = await CameraUtils.toggleFlashMode(
        _controller,
        _currentFlashMode,
      );

      // Update state only after successfully setting the mode
      if (mounted) {
        setState(() {
          _currentFlashMode = nextFlashMode;
        });
        // DEBUG: print("Flash mode set to: $nextFlashMode");
      }
    } catch (e) {
      // DEBUG: print("Error setting flash mode: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error setting flash mode: $e')));
      }
    }
  }

  // ADDED: Helper function to get the correct icon for the flash mode
  IconData _getFlashIcon() {
    switch (_currentFlashMode) {
      case FlashMode.off:
        return LucideIcons.zapOff;
      case FlashMode.auto:
        return LucideIcons.zap;
      case FlashMode.always:
      case FlashMode.torch: // Show 'on' icon for torch as well
        return LucideIcons.zap;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size and padding information
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;

    // Determine if flash controls should be enabled
    final bool canControlFlash =
        _controller != null &&
        _controller!.value.isInitialized &&
        !_isInitializing;

    return Scaffold(
      backgroundColor: GlobalStyles.textPrimary,
      body: Stack(
        children: [
          // --- Camera Preview (Background Layer) ---
          (canControlFlash)
              ? Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: size.width,
                    height: size.width * _controller!.value.aspectRatio,
                    child: CameraPreview(_controller!),
                  ),
                ),
              )
              : Container(
                color: GlobalStyles.textPrimary,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: GlobalStyles.surfaceMain,
                  ),
                ),
              ),

          // --- Loading Overlay ---
          if (_isInitializing)
            Positioned.fill(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  color: GlobalStyles.textPrimary.withValues(alpha: 0.6),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: GlobalStyles.surfaceMain,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ),
            ),

          // --- Top Controls Container ---
          Positioned(
            top: topPadding + GlobalStyles.spacingMd,
            left: GlobalStyles.spacingMd,
            right: GlobalStyles.spacingMd,
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Close Button
                    _buildControlButton(
                      icon: LucideIcons.x,
                      tooltip: 'Close Camera',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                    ),

                    // Flash Button
                    _buildControlButton(
                      icon: _getFlashIcon(),
                      tooltip:
                          'Flash: ${_currentFlashMode.toString().split('.').last}',
                      onPressed: canControlFlash ? _toggleFlashMode : null,
                      isEnabled: canControlFlash,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- Bottom Controls Container ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _slideController,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        GlobalStyles.textPrimary.withValues(alpha: 0.0),
                        GlobalStyles.textPrimary.withValues(alpha: 0.3),
                        GlobalStyles.textPrimary.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  padding: EdgeInsets.only(
                    left: GlobalStyles.spacingMd,
                    right: GlobalStyles.spacingMd,
                    top: GlobalStyles.spacingXl,
                    bottom:
                        GlobalStyles.spacingXl +
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Gallery Button
                      _buildBottomActionButton(
                        icon: LucideIcons.image,
                        tooltip: 'Open Gallery',
                        onPressed: _openGallery,
                      ),

                      // Capture Button
                      _buildCaptureButton(),

                      // Placeholder for layout balance
                      SizedBox(width: 56.w, height: 56.w),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a control button (top controls like close, flash)
  Widget _buildControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    bool isEnabled = true,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          radius: 28.w,
          child: Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: GlobalStyles.textPrimary.withValues(
                alpha: isEnabled ? 0.4 : 0.2,
              ),
              shape: BoxShape.circle,
              boxShadow: [GlobalStyles.shadowMd],
            ),
            child: Icon(
              icon,
              color: GlobalStyles.surfaceMain,
              size: GlobalStyles.iconSizeMd,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds bottom action buttons (gallery, etc.)
  Widget _buildBottomActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          radius: 28.w,
          child: Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: GlobalStyles.surfaceMain.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
              border: Border.all(
                color: GlobalStyles.surfaceMain.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [GlobalStyles.shadowMd],
            ),
            child: Icon(
              icon,
              color: GlobalStyles.surfaceMain,
              size: GlobalStyles.iconSizeLg,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the main capture button
  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap:
          (_controller != null &&
                  _controller!.value.isInitialized &&
                  !_isInitializing &&
                  !_isTakingPicture)
              ? _takePicture
              : null,
      child: AnimatedScale(
        scale: _isTakingPicture ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: EdgeInsets.all(GlobalStyles.spacingXs),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring
              Container(
                width: 72.w,
                height: 72.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: GlobalStyles.surfaceMain,
                    width: 3.5,
                  ),
                  boxShadow: [GlobalStyles.shadowLg],
                ),
              ),
              // Inner circle
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  color: GlobalStyles.surfaceMain,
                  shape: BoxShape.circle,
                  boxShadow: [GlobalStyles.shadowMd],
                ),
                child:
                    _isTakingPicture
                        ? Center(
                          child: SizedBox(
                            width: 24.sp,
                            height: 24.sp,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                GlobalStyles.textPrimary,
                              ),
                            ),
                          ),
                        )
                        : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
