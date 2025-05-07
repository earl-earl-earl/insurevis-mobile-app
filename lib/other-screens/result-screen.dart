// filepath: c:\Users\Regine Torremoro\Desktop\Earl John\insurevis\lib\other-screens\result-screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ResultsScreen extends StatefulWidget {
  final String imagePath;

  const ResultsScreen({super.key, required this.imagePath});

  @override
  ResultsScreenState createState() => ResultsScreenState();
}

class ResultsScreenState extends State<ResultsScreen> {
  String? _apiResponse;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _uploadImage();
  }

  Future<void> _uploadImage() async {
    final url = Uri.parse(
      'https://rooster-faithful-terminally.ngrok-free.app/predict', // Replace with your API endpoint
    ); // Replace with your API endpoint
    final file = File(widget.imagePath);

    try {
      final request = http.MultipartRequest('POST', url)
        ..files.add(await http.MultipartFile.fromPath('image_file', file.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseBody);

        setState(() {
          _apiResponse = jsonResponse.toString(); // Display the JSON response
          _isLoading = false;
        });
      } else {
        setState(() {
          _apiResponse = 'Error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _apiResponse = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.file(File(widget.imagePath)), // Display the image
                    const SizedBox(height: 20),
                    Text(
                      _apiResponse ?? 'No response',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
    );
  }
}
