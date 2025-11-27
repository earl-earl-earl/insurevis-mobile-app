import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:image_picker/image_picker.dart';
import 'package:insurevis/api_config.dart';
import 'package:insurevis/utils/network_helper.dart';

/// Service for handling image uploads to the prediction API
class ImageUploadService {
  static final ImageUploadService _instance = ImageUploadService._internal();
  factory ImageUploadService() => _instance;
  ImageUploadService._internal();

  /// Uploads an image file to the prediction API using NetworkHelper
  ///
  /// Returns the parsed JSON response if successful, null otherwise
  Future<Map<String, dynamic>?> uploadImageFile({
    required String imagePath,
    String fileFieldName = 'image_file',
    int maxRetries = 2,
  }) async {
    int attempts = 0;
    Exception? lastError;

    while (attempts < maxRetries) {
      try {
        // Verify if image exists
        final imageFile = File(imagePath);
        if (!imageFile.existsSync()) {
          throw Exception('Image file not found: $imagePath');
        }

        // Use standard timeout for all attempts
        final timeout = const Duration(seconds: 60);

        // Use NetworkHelper for sending multipart request
        final streamedResponse = await NetworkHelper.sendMultipartRequest(
          url: ApiConfig.predictUrl,
          filePath: imagePath,
          fileFieldName: fileFieldName,
          timeout: timeout,
        );

        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          return json.decode(response.body) as Map<String, dynamic>;
        } else {
          throw Exception(
            'API Error: ${response.statusCode} - ${response.body}',
          );
        }
      } catch (e) {
        lastError = e as Exception;
        attempts++;

        if (attempts < maxRetries) {
          // Wait before retry with exponential backoff
          await Future.delayed(Duration(seconds: attempts * 2));
          print(
            'Retrying image upload (attempt ${attempts + 1}/$maxRetries)...',
          );
        }
      }
    }

    // All retries failed
    print('Failed to upload image after $maxRetries attempts: $lastError');
    throw lastError ?? Exception('Upload failed after $maxRetries attempts');
  }

  /// Uploads an XFile (from image picker) to the prediction API
  ///
  /// Returns true if successful, false otherwise
  Future<bool> uploadXFile({
    required XFile image,
    String fileFieldName = 'image_file',
  }) async {
    try {
      final url = Uri.parse(ApiConfig.predictUrl);

      final ioClient =
          HttpClient()..badCertificateCallback = (cert, host, port) => true;
      final client = IOClient(ioClient);

      final request =
          http.MultipartRequest('POST', url)
            ..files.add(
              await http.MultipartFile.fromPath(fileFieldName, image.path),
            )
            ..headers.addAll({
              'Accept': 'application/json',
              'ngrok-skip-browser-warning':
                  'true', // Skip ngrok browser warning
              'User-Agent': 'InsurevisApp/1.0',
            });

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      return response.statusCode == 200;
    } catch (e) {
      // DEBUG: print("Error uploading XFile: $e");
      return false;
    }
  }

  /// Uploads an XFile and returns the parsed response
  ///
  /// Returns the parsed JSON response if successful, null otherwise
  Future<Map<String, dynamic>?> uploadXFileWithResponse({
    required XFile image,
    String fileFieldName = 'image_file',
  }) async {
    try {
      final url = Uri.parse(ApiConfig.predictUrl);

      final ioClient =
          HttpClient()..badCertificateCallback = (cert, host, port) => true;
      final client = IOClient(ioClient);

      final request =
          http.MultipartRequest('POST', url)
            ..files.add(
              await http.MultipartFile.fromPath(fileFieldName, image.path),
            )
            ..headers.addAll({
              'Accept': 'application/json',
              'ngrok-skip-browser-warning':
                  'true', // Skip ngrok browser warning
              'User-Agent': 'InsurevisApp/1.0',
            });

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        // DEBUG: print("API Error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      // DEBUG: print("Error uploading XFile with response: $e");
      return null;
    }
  }

  /// Uploads an image file path using IOClient (for compatibility)
  ///
  /// Returns the parsed JSON response if successful, null otherwise
  Future<Map<String, dynamic>?> uploadImagePathWithIOClient({
    required String imagePath,
    String fileFieldName = 'image_file',
  }) async {
    try {
      final url = Uri.parse(ApiConfig.predictUrl);

      final ioClient =
          HttpClient()..badCertificateCallback = (cert, host, port) => true;
      final client = IOClient(ioClient);

      final request = http.MultipartRequest(
        'POST',
        url,
      )..files.add(await http.MultipartFile.fromPath(fileFieldName, imagePath));

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        // DEBUG: print("API Error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      // DEBUG: print("Error uploading image path with IOClient: $e");
      return null;
    }
  }
}
