import 'package:camera/camera.dart';
import 'package:insurevis/services/camera_buffer_service.dart';

class CameraUtils {
  /// Initialize camera with the specified camera index
  static Future<CameraController?> initializeCamera(
    int cameraIndex,
    List<CameraDescription> cameras,
  ) async {
    if (cameras.isEmpty) {
      final cameraList = await availableCameras();
      if (cameraList.isEmpty) {
        return null;
      }
      cameras.addAll(cameraList);
    }

    // Ensure the selected index is valid
    final validIndex =
        (cameraIndex >= 0 && cameraIndex < cameras.length) ? cameraIndex : 0;

    final camera = cameras[validIndex];
    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await controller.initialize();

    // Set initial flash mode to off
    await controller.setFlashMode(FlashMode.off);

    return controller;
  }

  /// Get available cameras
  static Future<List<CameraDescription>> getAvailableCameras() async {
    return await availableCameras();
  }

  /// Take a picture using the camera controller
  static Future<XFile?> takePicture(CameraController? controller) async {
    if (controller == null || !controller.value.isInitialized) {
      return null;
    }

    // Clear buffers before taking picture to prevent overflow
    await CameraBufferService.clearBuffers();

    final XFile imageFile = await controller.takePicture();

    // Optimize memory after taking picture
    await CameraBufferService.optimizeMemory();

    return imageFile;
  }

  /// Toggle flash mode
  static Future<FlashMode> toggleFlashMode(
    CameraController? controller,
    FlashMode currentMode,
  ) async {
    if (controller == null || !controller.value.isInitialized) {
      return currentMode;
    }

    FlashMode nextFlashMode;
    switch (currentMode) {
      case FlashMode.off:
        nextFlashMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        nextFlashMode = FlashMode.always;
        break;
      case FlashMode.always:
      case FlashMode.torch:
        nextFlashMode = FlashMode.off;
        break;
    }

    await controller.setFlashMode(nextFlashMode);
    return nextFlashMode;
  }

  /// Dispose camera controller and cleanup buffers
  static Future<void> disposeCamera(CameraController? controller) async {
    CameraBufferService.clearBuffers();
    await controller?.dispose();
  }

  /// Initialize camera buffer optimization
  static void initializeBufferOptimization() {
    CameraBufferService.initializeBufferOptimization();
  }
}
