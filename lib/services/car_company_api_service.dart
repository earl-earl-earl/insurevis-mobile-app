import 'dart:convert';
import 'package:http/http.dart' as http;

class CarCompanyApiService {
  static const String baseUrl = 'http://localhost:8080/api';

  // Verify vehicle information with car company
  static Future<Map<String, dynamic>> verifyVehicleInfo(String vin) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vehicle/$vin'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_API_TOKEN',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to verify vehicle: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error verifying vehicle: $e');
    }
  }

  // Check warranty status
  static Future<Map<String, dynamic>> checkWarranty(String vin) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/warranty/$vin'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_API_TOKEN',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to check warranty: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error checking warranty: $e');
    }
  }

  // Submit document for verification
  static Future<Map<String, dynamic>> submitDocumentForVerification({
    required String vin,
    required String documentType,
    required String documentPath,
    required String assessmentId,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/verify/document'),
      );

      request.headers.addAll({'Authorization': 'Bearer YOUR_API_TOKEN'});

      request.fields.addAll({
        'vin': vin,
        'document_type': documentType,
        'assessment_id': assessmentId,
      });

      request.files.add(
        await http.MultipartFile.fromPath('document', documentPath),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to submit document: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error submitting document: $e');
    }
  }

  // Check for recalls
  static Future<Map<String, dynamic>> checkRecalls(String vin) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recall/check'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_API_TOKEN',
        },
        body: json.encode({'vin': vin}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to check recalls: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error checking recalls: $e');
    }
  }

  // Validate VIN format
  static bool isValidVin(String vin) {
    if (vin.length != 17) return false;

    // VIN should not contain I, O, or Q
    final RegExp vinPattern = RegExp(r'^[A-HJ-NPR-Z0-9]{17}$');
    return vinPattern.hasMatch(vin);
  }

  // Get vehicle specifications from manufacturer
  static Future<Map<String, dynamic>> getVehicleSpecs(String vin) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vehicle/$vin/specs'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_API_TOKEN',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get vehicle specs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting vehicle specs: $e');
    }
  }

  // Submit assessment to car company for validation
  static Future<Map<String, dynamic>> submitAssessmentForValidation({
    required String vin,
    required Map<String, dynamic> assessmentData,
    required List<String> imagePaths,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/assessment/validate'),
      );

      request.headers.addAll({'Authorization': 'Bearer YOUR_API_TOKEN'});

      request.fields.addAll({
        'vin': vin,
        'assessment_data': json.encode(assessmentData),
      });

      // Add images
      for (int i = 0; i < imagePaths.length; i++) {
        request.files.add(
          await http.MultipartFile.fromPath('image_$i', imagePaths[i]),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to submit assessment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error submitting assessment: $e');
    }
  }
}
