import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class FileWriter {
  static const MethodChannel _channel = MethodChannel('insurevis/file_writer');

  /// Write bytes to the given content URI (Android SAF style).
  /// Returns true on success, throws on error.
  static Future<bool> writeBytesToUri(String uri, Uint8List bytes) async {
    try {
      final result = await _channel.invokeMethod('writeToUri', {
        'uri': uri,
        'bytes': bytes,
      });
      return result == true;
    } on PlatformException catch (e) {
      throw Exception('Platform error writing to URI: ${e.message}');
    } catch (e) {
      throw Exception('Error writing to URI: $e');
    }
  }

  /// Launches a native directory picker (SAF) and returns the picked tree URI string, or null if cancelled.
  static Future<String?> pickDirectory() async {
    try {
      final result = await _channel.invokeMethod('pickDirectory');
      if (result == null) return null;
      return result as String;
    } on PlatformException catch (e) {
      throw Exception('Platform error picking directory: ${e.message}');
    }
  }

  /// Save a file into a previously picked tree URI. Returns the new file URI string on success.
  static Future<String?> saveFileToTree(
    String treeUri,
    String fileName,
    Uint8List bytes,
  ) async {
    try {
      final result = await _channel.invokeMethod('saveFileToTree', {
        'treeUri': treeUri,
        'fileName': fileName,
        'bytes': bytes,
      });
      if (result == null) return null;
      return result as String;
    } on PlatformException catch (e) {
      throw Exception('Platform error saving to tree: ${e.message}');
    }
  }
}
