import 'package:flutter/material.dart';
import 'package:camera/camera.dart'; // Make sure camera types like FlashMode are imported
import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:google_fonts/google_fonts.dart'; // Not used in this version
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/other-screens/result-screen.dart';
import 'package:insurevis/other-screens/gallery_view.dart';
// import 'package:photo_manager/photo_manager.dart'; // REMOVED: No longer used
import 'package:provider/provider.dart';
import 'package:insurevis/providers/assessment_provider.dart';

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
      _cameras = await availableCameras();
      // Handle case where no cameras are available
      if (_cameras.isEmpty) {
        print("No cameras found on device.");
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

    // Ensure the selected index is valid
    if (cameraIndex < 0 || cameraIndex >= _cameras.length) {
      cameraIndex = 0; // Default to the first camera (usually back)
      _selectedCameraIndex = 0;
    }

    final camera = _cameras[cameraIndex];
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false, // Disable audio if not needed
      imageFormatGroup: ImageFormatGroup.jpeg, // Or nv21 / yuv420
    );

    // Assign the future for the FutureBuilder
    _initializeControllerFuture = _controller!
        .initialize()
        .then((_) {
          // After initialization, set the initial flash mode (off)
          // Do this after initialize() completes successfully
          if (mounted) {
            // Set initial flash mode on the actual controller
            _controller!.setFlashMode(_currentFlashMode).catchError((e) {
              print("Error setting initial flash mode: $e");
              // Optionally inform user if setting flash fails
            });
          }
        })
        .catchError((e) {
          print("Error initializing camera: $e");
          if (e is CameraException) {
            switch (e.code) {
              case 'CameraAccessDenied':
                print("Camera access denied");
                // Handle access denial - show message
                break;
              default:
                print("Camera Error: ${e.description}");
                // Handle other errors
                break;
            }
          }
          if (mounted) {
            setState(() => _isInitializing = false); // Stop loading on error
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to initialize camera: ${e.description ?? e}',
                ), // Show description or error itself
              ),
            );
          }
          // Rethrow or handle error as needed for future chaining
          throw e;
        });

    // Await initialization ONLY if not part of the initial setup driven by _initCameraOnly
    // This await is mainly for the switch camera logic where we rebuild immediately
    try {
      await _initializeControllerFuture;
    } catch (e) {
      // Error already handled in catchError block above
      print("Initialization future caught error (already handled)");
    }

    // Update state if switching cameras and already mounted
    if (mounted && !_isInitializing) {
      // Ensure rebuild happens after initialization future is complete/handled
      setState(() {}); // Rebuild with the new controller
    }
  }

  @override
  void dispose() {
    _controller?.dispose(); // Dispose the controller when the widget is removed
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

      final XFile imageFile = await _controller!.takePicture();

      if (mounted) {
        // Add the photo to assessments before navigating
        final assessmentProvider = Provider.of<AssessmentProvider>(
          context,
          listen: false,
        );
        final assessment = await assessmentProvider.addAssessment(
          imageFile.path,
        );

        // Navigate to results screen with the assessment ID
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ResultsScreen(
                  imagePath: imageFile.path,
                  assessmentId: assessment.id,
                ),
          ),
        );
      }
    } catch (e) {
      print("Error taking picture: $e");
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
      print("Camera not ready to change flash mode.");
      return;
    }

    FlashMode nextFlashMode;
    switch (_currentFlashMode) {
      case FlashMode.off:
        nextFlashMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        nextFlashMode = FlashMode.always; // Use 'always' for 'on' state
        break;
      case FlashMode.always:
      case FlashMode.torch: // Treat torch same as always for cycling
        nextFlashMode = FlashMode.off;
        break;
    }

    try {
      // Ensure initialization future is complete before setting flash
      await _initializeControllerFuture;
      await _controller!.setFlashMode(nextFlashMode);
      // Update state only after successfully setting the mode
      if (mounted) {
        setState(() {
          _currentFlashMode = nextFlashMode;
        });
        print("Flash mode set to: $nextFlashMode");
      }
    } catch (e) {
      print("Error setting flash mode to $nextFlashMode: $e");
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
        return Icons.flash_off_rounded;
      case FlashMode.auto:
        return Icons.flash_auto_rounded;
      case FlashMode.always:
      case FlashMode.torch: // Show 'on' icon for torch as well
        return Icons.flash_on_rounded;
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
      backgroundColor: Colors.black,
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
                child: CircularProgressIndicator(color: Colors.white),
              ),

          // --- Loading Overlay (Optional but good UX) ---
          if (_isInitializing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withAlpha(128), // 0.5 * 255
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),

          // --- Top Controls (Positioned Manually) ---
          // Close Button
          Positioned(
            top:
                topPadding +
                GlobalStyles.leadingPaddingTop, // Account for status bar
            left: GlobalStyles.leadingPaddingLeft,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(77), // 0.3 * 255
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 30.sp,
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
            top:
                topPadding +
                GlobalStyles.leadingPaddingTop, // Account for status bar
            right: GlobalStyles.leadingPaddingLeft,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(77), // 0.3 * 255
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  _getFlashIcon(), // Use helper to get dynamic icon
                  color: Colors.white,
                  size: 22.sp,
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
                bottom: 20.h,
                left: 20.w,
                right: 20.w, // Adjust for bottom padding
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              // Consider adding bottom safe area padding if needed:
              // padding: EdgeInsets.only(bottom: bottomPadding),
              child: Padding(
                // Wrap Row in Padding for consistent spacing
                padding: EdgeInsets.symmetric(vertical: 25.h, horizontal: 20.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // --- Gallery Button ---
                    GestureDetector(
                      onTap: _openGallery,
                      child: Container(
                        width: 55.w,
                        height: 55.w,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(51), // 0.2 * 255
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: Colors.white54, width: 1),
                        ),
                        child: Icon(
                          Icons.photo_library_outlined,
                          color: Colors.white70,
                          size: 28.sp,
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
                        padding: EdgeInsets.all(
                          4.w,
                        ), // Padding for the outer border
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3.w),
                        ),
                        child: Container(
                          width: 65.w, // Inner circle size
                          height: 65.w,
                          decoration: const BoxDecoration(
                            color: Colors.white,
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
                                        color: Colors.black,
                                      ),
                                    ),
                                  ) // Show indicator while capturing
                                  : null,
                        ),
                      ),
                    ),

                    // Spacer to maintain layout balance
                    SizedBox(width: 55.w),
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
