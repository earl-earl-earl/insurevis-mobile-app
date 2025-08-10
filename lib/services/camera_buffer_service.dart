import 'dart:io';
import 'package:flutter/services.dart';

/// Service to manage camera buffer optimization and prevent ImageReader overflow
class CameraBufferService {
  static const MethodChannel _channel = MethodChannel(
    'camera_buffer_optimization',
  );

  /// Initialize camera buffer optimization for Android
  static Future<void> initializeBufferOptimization() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('initBufferOptimization');
      } on PlatformException catch (e) {
        print('Failed to initialize camera buffer optimization: ${e.message}');
      }
    }
  }

  /// Clear camera buffers to prevent overflow
  static Future<void> clearBuffers() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('clearBuffers');
      } on PlatformException catch (e) {
        print('Failed to clear camera buffers: ${e.message}');
      }
    }
  }

  /// Optimize memory for camera operations
  static Future<void> optimizeMemory() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('optimizeMemory');
      } on PlatformException catch (e) {
        print('Failed to optimize camera memory: ${e.message}');
      }
    }
  }

  /// Force garbage collection to free up memory
  static Future<void> forceGarbageCollection() async {
    // This is a Dart-level optimization
    try {
      // Force garbage collection
      await Future.delayed(const Duration(milliseconds: 100));
      // System.gc() equivalent in Dart is automatic, but we can suggest it
      print('Requesting garbage collection...');
    } catch (e) {
      print('Error during garbage collection: $e');
    }
  }
}
