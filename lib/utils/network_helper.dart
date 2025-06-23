import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class NetworkHelper {
  static Future<bool> checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> checkApiEndpoint(String url) async {
    try {
      final uri = Uri.parse(url);
      final client = _createHttpClient();

      final response = await client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'ngrok-skip-browser-warning': 'true',
              'User-Agent': 'InsurevisApp/1.0',
            },
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode < 500; // Accept any non-server error
    } catch (e) {
      print('API endpoint check failed: $e');
      return false;
    }
  }

  static http.Client _createHttpClient() {
    final ioClient = HttpClient();
    ioClient.badCertificateCallback = (cert, host, port) => true;
    ioClient.connectionTimeout = const Duration(seconds: 10);
    ioClient.idleTimeout = const Duration(seconds: 30);

    return IOClient(ioClient);
  }

  static Future<http.Response> makeRequest({
    required String url,
    required String method,
    Map<String, String>? headers,
    Object? body,
  }) async {
    final client = _createHttpClient();
    final uri = Uri.parse(url);

    final defaultHeaders = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      'User-Agent': 'InsurevisApp/1.0',
      ...?headers,
    };

    switch (method.toUpperCase()) {
      case 'GET':
        return await client.get(uri, headers: defaultHeaders);
      case 'POST':
        return await client.post(uri, headers: defaultHeaders, body: body);
      case 'PUT':
        return await client.put(uri, headers: defaultHeaders, body: body);
      case 'DELETE':
        return await client.delete(uri, headers: defaultHeaders);
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }

  static Future<http.StreamedResponse> sendMultipartRequest({
    required String url,
    required String filePath,
    required String fileFieldName,
    Map<String, String>? additionalFields,
  }) async {
    final client = _createHttpClient();
    final uri = Uri.parse(url);

    final request =
        http.MultipartRequest('POST', uri)
          ..files.add(
            await http.MultipartFile.fromPath(fileFieldName, filePath),
          )
          ..headers.addAll({
            'Accept': 'application/json',
            'ngrok-skip-browser-warning': 'true',
            'User-Agent': 'InsurevisApp/1.0',
          });

    if (additionalFields != null) {
      request.fields.addAll(additionalFields);
    }

    return await client.send(request);
  }
}
