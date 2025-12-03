import 'package:flutter/material.dart';
import 'package:camera/camera.dart'; // Make sure camera types like FlashMode are imported
// import 'package:flutter_screenutil/flutter_screenutil.dart';
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

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller; // Make nullable for initialization phase
  Future<void>? _initializeControllerFuture;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0; // 0 for back, 1 for front usually
  bool _isInitializing = true; // Flag for loading state
  bool _isTakingPicture = false; // Flag to prevent multiple captures

  // ADDED: State for flash mode
  FlashMode _currentFlashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
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
    final topPadding = MediaQuery.of(context).padding.top; // Status bar height
    // final bottomPadding = MediaQuery.of(context).padding.bottom; // Bottom safe area inset (optional)

    // Determine if flash controls should be enabled
    final bool canControlFlash =
        _controller != null &&
        _controller!.value.isInitialized &&
        !_isInitializing;

    return Scaffold(
      backgroundColor: GlobalStyles.textPrimary,
      // REMOVED: extendBodyBehindAppBar (no AppBar anymore)
      // REMOVED: appBar

      // Body is now the Stack containing everything
      body: Stack(
        children: [
          // --- Camera Preview (fills the entire Stack/Screen) ---
          // Check if controller is initialized before showing preview
          (canControlFlash) // Use combined condition
              ? Positioned.fill(
                // Make preview fill the stack
                child: FittedBox(
                  // Scales the preview
                  fit:
                      BoxFit
                          .cover, // Cover the entire screen, cropping if necessary
                  child: SizedBox(
                    width: size.width,
                    // Calculate height based on camera aspect ratio to avoid distortion
                    height: size.width * _controller!.value.aspectRatio,
                    child: CameraPreview(_controller!),
                  ),
                ),
              )
              : const Center(
                // Show loading indicator during initialization/switching
                child: CircularProgressIndicator(
                  color: GlobalStyles.surfaceMain,
                ),
              ),

          // --- Loading Overlay (Optional but good UX) ---
          if (_isInitializing)
            Positioned.fill(
              child: Container(
                color: GlobalStyles.textPrimary.withValues(alpha: 0.5),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: GlobalStyles.surfaceMain,
                  ),
                ),
              ),
            ),

          // --- Top Controls (Positioned Manually) ---
          // Close Button
          Positioned(
            top: topPadding + GlobalStyles.spacingMd, // Account for status bar
            left: GlobalStyles.spacingMd,
            child: Container(
              decoration: BoxDecoration(
                color: GlobalStyles.textPrimary.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                boxShadow: [GlobalStyles.shadowMd],
              ),
              child: IconButton(
                icon: Icon(
                  LucideIcons.x,
                  color: GlobalStyles.surfaceMain,
                  size: GlobalStyles.iconSizeLg,
                ),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                tooltip: 'Close Camera',
              ),
            ),
          ),

          // Flash Button - UPDATED
          Positioned(
            top: topPadding + GlobalStyles.spacingMd, // Account for status bar
            right: GlobalStyles.spacingMd,
            child: Container(
              decoration: BoxDecoration(
                color: GlobalStyles.textPrimary.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                boxShadow: [GlobalStyles.shadowMd],
              ),
              child: IconButton(
                icon: Icon(
                  _getFlashIcon(), // Use helper to get dynamic icon
                  color: GlobalStyles.surfaceMain,
                  size: GlobalStyles.iconSizeMd,
                ),
                // Disable button if camera isn't ready
                onPressed: canControlFlash ? _toggleFlashMode : null,
                tooltip:
                    'Toggle Flash (${_currentFlashMode.toString().split('.').last})', // Show current mode
              ),
            ),
          ),

          // --- Bottom Controls (Positioned Manually) ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              // Optional: Add a subtle background gradient for better contrast
              padding: EdgeInsets.only(
                bottom: GlobalStyles.paddingNormal,
                left: GlobalStyles.paddingNormal,
                right: GlobalStyles.paddingNormal,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    GlobalStyles.textPrimary.withValues(alpha: 0.0),
                    GlobalStyles.textPrimary.withValues(alpha: 0.4),
                    GlobalStyles.textPrimary.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              // Consider adding bottom safe area padding if needed:
              // padding: EdgeInsets.only(bottom: bottomPadding),
              child: Padding(
                // Wrap Row in Padding for consistent spacing
                padding: EdgeInsets.symmetric(
                  vertical: GlobalStyles.paddingLoose,
                  horizontal: GlobalStyles.paddingNormal,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // --- Gallery Button ---
                    GestureDetector(
                      onTap: _openGallery,
                      child: Container(
                        width: GlobalStyles.minTouchTarget,
                        height: GlobalStyles.minTouchTarget,
                        decoration: BoxDecoration(
                          color: GlobalStyles.surfaceMain.withValues(
                            alpha: 0.25,
                          ),
                          borderRadius: BorderRadius.circular(
                            GlobalStyles.radiusMd,
                          ),
                          border: Border.all(
                            color: GlobalStyles.surfaceMain.withValues(
                              alpha: 0.4,
                            ),
                            width: GlobalStyles.iconStrokeWidthNormal,
                          ),
                          boxShadow: [GlobalStyles.shadowMd],
                        ),
                        child: Icon(
                          LucideIcons.image,
                          color: GlobalStyles.surfaceMain,
                          size: GlobalStyles.iconSizeLg,
                        ),
                      ),
                    ),

                    // --- Take Photo Button ---
                    GestureDetector(
                      // Disable button if camera isn't ready
                      onTap:
                          canControlFlash && !_isTakingPicture
                              ? _takePicture
                              : null,
                      child: Container(
                        padding: EdgeInsets.all(GlobalStyles.spacingXs),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: GlobalStyles.surfaceMain,
                            width: GlobalStyles.iconStrokeWidthThick,
                          ),
                        ),
                        child: Container(
                          width: GlobalStyles.iconSizeXl * 1.6,
                          height: GlobalStyles.iconSizeXl * 1.6,
                          decoration: const BoxDecoration(
                            color: GlobalStyles.surfaceMain,
                            shape: BoxShape.circle,
                          ),
                          child:
                              _isTakingPicture
                                  ? const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: GlobalStyles.textPrimary,
                                      ),
                                    ),
                                  ) // Show indicator while capturing
                                  : null,
                        ),
                      ),
                    ),

                    // Spacer to maintain layout balance
                    SizedBox(width: GlobalStyles.minTouchTarget),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
