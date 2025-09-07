import 'dart:io';
import 'package:flutter/material.dart';
import 'package:insurevis/utils/pdf_service.dart';
import 'package:insurevis/services/enhanced_pdf_service_simple.dart';
import 'package:insurevis/models/assessment_model.dart';
import 'package:insurevis/utils/pdf_debug_helper.dart';

/// Simple test app to demonstrate PDF generation working correctly
/// Run with: flutter run -d windows lib/test_pdf_generation.dart
void main() {
  runApp(const PDFTestApp());
}

class PDFTestApp extends StatelessWidget {
  const PDFTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Generation Test',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const PDFTestScreen(),
    );
  }
}

class PDFTestScreen extends StatefulWidget {
  const PDFTestScreen({super.key});

  @override
  State<PDFTestScreen> createState() => _PDFTestScreenState();
}

class _PDFTestScreenState extends State<PDFTestScreen> {
  String _statusText = 'Ready to test PDF generation';
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _checkPDFCapabilities();
  }

  Future<void> _checkPDFCapabilities() async {
    setState(() {
      _statusText = 'Checking PDF capabilities...';
    });

    await PDFDebugHelper.printPDFDebugInfo();

    setState(() {
      _statusText = 'PDF capabilities checked. Ready to generate PDFs.';
    });
  }

  Future<void> _generateBasicPDF() async {
    if (_isGenerating) return;

    setState(() {
      _isGenerating = true;
      _statusText = 'Generating basic PDF...';
    });

    try {
      // Create mock API response
      final mockResponse = {
        'overall_severity': 'moderate',
        'total_cost': '2500.00',
        'damages': [
          {
            'area': 'front_bumper',
            'severity': 'moderate',
            'cost': '1500.00',
            'description': 'Dented front bumper requiring replacement',
          },
          {
            'area': 'headlight',
            'severity': 'minor',
            'cost': '1000.00',
            'description': 'Cracked headlight lens',
          },
        ],
      };

      final result = await PDFService.generateSingleResultPDF(
        imagePath:
            'non_existent_image.jpg', // Intentionally missing to test graceful handling
        apiResponse: mockResponse,
      );

      if (result != null) {
        setState(() {
          _statusText = 'Basic PDF generated successfully!\nSaved at: $result';
        });
      } else {
        setState(() {
          _statusText = 'Basic PDF generation failed!';
        });
      }
    } catch (e) {
      setState(() {
        _statusText = 'Error generating basic PDF: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _generateEnhancedPDF() async {
    if (_isGenerating) return;

    setState(() {
      _isGenerating = true;
      _statusText = 'Generating enhanced PDF...';
    });

    try {
      final pdfService = EnhancedPDFService();

      // Create mock assessments
      final mockAssessments = [
        Assessment(
          id: 'demo-1',
          imagePath: 'demo_image_1.jpg',
          timestamp: DateTime.now(),
          status: AssessmentStatus.completed,
          results: {
            'damage_type': 'dent',
            'severity': 'moderate',
            'cost': '1800.00',
            'area': 'door_panel',
          },
        ),
        Assessment(
          id: 'demo-2',
          imagePath: 'demo_image_2.jpg',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          status: AssessmentStatus.completed,
          results: {
            'damage_type': 'scratch',
            'severity': 'minor',
            'cost': '700.00',
            'area': 'rear_bumper',
          },
        ),
      ];

      final result = await pdfService.generateReport(
        mockAssessments,
        reportType: 'summary',
        clientName: 'Demo Client',
        policyNumber: 'DEMO-2024-001',
      );

      setState(() {
        _statusText = 'Enhanced PDF generated successfully!\nSaved at: $result';
      });
    } catch (e) {
      setState(() {
        _statusText = 'Error generating enhanced PDF: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _openGeneratedPDFsFolder() async {
    try {
      final currentDir = Directory.current;
      final pdfDir = Directory('${currentDir.path}/generated_pdfs');

      if (await pdfDir.exists()) {
        // On Windows, open the folder in Explorer
        if (Platform.isWindows) {
          await Process.run('explorer', [pdfDir.path]);
        } else {
          setState(() {
            _statusText = 'PDF folder location: ${pdfDir.path}';
          });
        }
      } else {
        setState(() {
          _statusText =
              'Generated PDFs folder does not exist yet. Generate a PDF first.';
        });
      }
    } catch (e) {
      setState(() {
        _statusText = 'Error opening PDF folder: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('PDF Generation Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'PDF Generator Testing',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              child: Text(
                _statusText,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateBasicPDF,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Generate Basic PDF'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateEnhancedPDF,
              icon: const Icon(Icons.description),
              label: const Text('Generate Enhanced PDF'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _openGeneratedPDFsFolder,
              icon: const Icon(Icons.folder_open),
              label: const Text('Open PDFs Folder'),
            ),
            const SizedBox(height: 20),
            if (_isGenerating) const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text(
              'PDFs will be saved in: [project]/generated_pdfs/',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
