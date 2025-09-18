import 'dart:io';
// import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/assessment_model.dart';

class EnhancedPDFService {
  static const String _version = '2.0';
  static const String _companyName = 'InsureVis';
  static const String _companyTagline = 'AI-Powered Vehicle Assessment';

  /// Generate different types of PDF reports
  Future<String> generateReport(
    List<Assessment> assessments, {
    String reportType = 'summary',
    String? clientName,
    String? policyNumber,
  }) async {
    switch (reportType.toLowerCase()) {
      case 'summary':
        return _generateSummaryReport(assessments, clientName, policyNumber);
      case 'insurance':
        return _generateInsuranceReport(assessments, clientName, policyNumber);
      case 'technical':
        return _generateTechnicalReport(assessments, clientName, policyNumber);
      default:
        return _generateSummaryReport(assessments, clientName, policyNumber);
    }
  }

  Future<String> _generateSummaryReport(
    List<Assessment> assessments,
    String? clientName,
    String? policyNumber,
  ) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build:
            (context) => [
              // Header
              _buildHeader(),
              pw.SizedBox(height: 30),

              // Report Info
              _buildReportInfo('Summary Report', clientName, policyNumber, now),
              pw.SizedBox(height: 20),

              // Executive Summary
              _buildExecutiveSummary(assessments),
              pw.SizedBox(height: 20),

              // Assessment Overview
              _buildAssessmentOverview(assessments),
            ],
      ),
    );

    return _savePDF(pdf, 'summary_report_${now.toString().split(' ')[0]}');
  }

  Future<String> _generateInsuranceReport(
    List<Assessment> assessments,
    String? clientName,
    String? policyNumber,
  ) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build:
            (context) => [
              _buildHeader(),
              pw.SizedBox(height: 30),
              _buildReportInfo(
                'Insurance Claim Report',
                clientName,
                policyNumber,
                now,
              ),
              pw.SizedBox(height: 20),
              _buildInsuranceDetails(assessments),
            ],
      ),
    );

    return _savePDF(pdf, 'insurance_report_${now.toString().split(' ')[0]}');
  }

  Future<String> _generateTechnicalReport(
    List<Assessment> assessments,
    String? clientName,
    String? policyNumber,
  ) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build:
            (context) => [
              _buildHeader(),
              pw.SizedBox(height: 30),
              _buildReportInfo(
                'Technical Assessment Report',
                clientName,
                policyNumber,
                now,
              ),
              pw.SizedBox(height: 20),
              _buildTechnicalDetails(assessments),
            ],
      ),
    );

    return _savePDF(pdf, 'technical_report_${now.toString().split(' ')[0]}');
  }

  pw.Widget _buildHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue900,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _companyName,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                _companyTagline,
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 14),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Text(
              'v$_version',
              style: pw.TextStyle(
                color: PdfColors.blue900,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildReportInfo(
    String reportTitle,
    String? clientName,
    String? policyNumber,
    DateTime generatedAt,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            reportTitle,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (clientName != null) pw.Text('Client: $clientName'),
                  if (policyNumber != null) pw.Text('Policy: $policyNumber'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Generated: ${generatedAt.toString().split('.')[0]}'),
                  pw.Text('Version: $_version'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildExecutiveSummary(List<Assessment> assessments) {
    final completed =
        assessments.where((a) => a.status == AssessmentStatus.completed).length;
    final processing =
        assessments
            .where((a) => a.status == AssessmentStatus.processing)
            .length;
    final failed =
        assessments.where((a) => a.status == AssessmentStatus.failed).length;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Executive Summary',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem('Total', assessments.length.toString()),
                  _buildSummaryItem('Completed', completed.toString()),
                  _buildSummaryItem('Processing', processing.toString()),
                  _buildSummaryItem('Failed', failed.toString()),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.Text(label),
      ],
    );
  }

  pw.Widget _buildAssessmentOverview(List<Assessment> assessments) {
    if (assessments.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Text(
          'No assessments available',
          style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Assessment Details',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table.fromTextArray(
          headers: ['ID', 'Date', 'Status', 'Results'],
          data:
              assessments.map((assessment) {
                // Safely handle potentially null values
                final id = assessment.id.isNotEmpty ? assessment.id : 'Unknown';
                final date = assessment.timestamp.toString().split(' ').first;
                final status = assessment.status.name.toUpperCase();
                final results =
                    assessment.results != null ? 'Available' : 'N/A';

                return [id, date, status, results];
              }).toList(),
          border: pw.TableBorder.all(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellAlignment: pw.Alignment.centerLeft,
          cellPadding: const pw.EdgeInsets.all(8),
          rowDecoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildInsuranceDetails(List<Assessment> assessments) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Insurance Claim Details',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'This section would contain insurance-specific analysis and recommendations.',
        ),
      ],
    );
  }

  pw.Widget _buildTechnicalDetails(List<Assessment> assessments) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Technical Analysis',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'This section would contain detailed technical analysis and AI insights.',
        ),
      ],
    );
  }

  Future<String> _savePDF(pw.Document pdf, String filename) async {
    try {
      final bytes = await pdf.save();
      Directory dir;

      // For mobile devices, handle permissions
      if (Platform.isAndroid || Platform.isIOS) {
        bool hasPermission = false;

        try {
          if (Platform.isAndroid) {
            // For Android 13+, we need storage permissions
            var status = await Permission.storage.request();
            hasPermission = status.isGranted;

            // For Android 11+ (API 30+), try manage external storage
            if (!hasPermission) {
              status = await Permission.manageExternalStorage.request();
              hasPermission = status.isGranted;
            }

            // Also request media permissions for modern Android
            if (!hasPermission) {
              final mediaStatus = await Permission.photos.request();
              hasPermission = mediaStatus.isGranted;
            }
          } else if (Platform.isIOS) {
            // For iOS, request photo library permissions
            var status = await Permission.photos.request();
            hasPermission = status.isGranted;
          }
        } catch (e) {
          print('Permission handling error: $e');
          hasPermission = false;
        }

        if (!hasPermission) {
          print('Storage permissions not granted');
          // Continue with fallback to app directory
        }
      }

      // Create InsureVis/documents directory in phone storage
      try {
        if (Platform.isAndroid) {
          // Try to get external storage directory first
          Directory? externalDir;
          try {
            externalDir = await getExternalStorageDirectory();
          } catch (e) {
            print('Could not get external storage: $e');
          }

          if (externalDir != null) {
            // Avoid using parent traversal (../../). Prefer public external
            // documents directories when possible, otherwise use the
            // app-specific external directory under the app sandbox.
            try {
              final externalDocs = await getExternalStorageDirectories(
                type: StorageDirectory.documents,
              );
              if (externalDocs != null && externalDocs.isNotEmpty) {
                dir = Directory(
                  '${externalDocs.first.path}/InsureVis/documents',
                );
              } else {
                dir = Directory('${externalDir.path}/InsureVis/documents');
              }
            } catch (e) {
              print('Could not determine public external documents dir: $e');
              dir = Directory('${externalDir.path}/InsureVis/documents');
            }
          } else {
            // Fallback to app documents directory
            final appDir = await getApplicationDocumentsDirectory();
            dir = Directory('${appDir.path}/InsureVis/documents');
          }
        } else if (Platform.isIOS) {
          // For iOS, use app documents directory
          final appDir = await getApplicationDocumentsDirectory();
          dir = Directory('${appDir.path}/InsureVis/documents');
        } else {
          // For desktop platforms, use current directory
          final currentDir = Directory.current;
          dir = Directory('${currentDir.path}/generated_pdfs');
        }

        // Ensure directory exists
        if (!await dir.exists()) {
          await dir.create(recursive: true);
          print('Created InsureVis/documents directory: ${dir.path}');
        }

        print('Using InsureVis/documents directory: ${dir.path}');
      } catch (e) {
        print('Could not create InsureVis/documents directory: $e');

        // Fallback to app documents directory
        try {
          final appDir = await getApplicationDocumentsDirectory();
          dir = Directory('${appDir.path}/PDFs');
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
          print('Using fallback app directory: ${dir.path}');
        } catch (fallbackError) {
          print('Fallback directory creation failed: $fallbackError');
          // Last resort: temp directory
          dir = Directory.systemTemp.createTempSync('pdf_fallback_');
          print('Using temporary directory as last resort: ${dir.path}');
        }
      }

      // Generate unique filename if file exists
      String finalFilename = filename;
      int counter = 1;
      while (await File('${dir.path}/$finalFilename.pdf').exists()) {
        finalFilename = '${filename}_$counter';
        counter++;
      }

      final file = File('${dir.path}/$finalFilename.pdf');
      await file.writeAsBytes(bytes);

      // Verify file was written
      if (await file.exists() && await file.length() > 0) {
        print('PDF saved successfully: ${file.path}');
        return file.path;
      } else {
        throw Exception('File verification failed');
      }
    } catch (e) {
      debugPrint('Error saving PDF: $e');
      rethrow;
    }
  }

  /// Share the PDF file
  Future<void> sharePDF(String filePath) async {
    try {
      await Share.shareXFiles([XFile(filePath)]);
    } catch (e) {
      debugPrint('Error sharing PDF: $e');
    }
  }

  /// Email the PDF file (placeholder implementation)
  Future<void> emailPDF(
    String filePath, {
    required String recipientEmail,
    String? subject,
    String? body,
  }) async {
    try {
      // This would integrate with a proper email service
      debugPrint('Email PDF feature - would send to: $recipientEmail');
      debugPrint('Subject: ${subject ?? "Assessment Report"}');
      debugPrint('File: $filePath');
    } catch (e) {
      debugPrint('Error emailing PDF: $e');
    }
  }

  /// Generate shareable link (placeholder implementation)
  Future<String?> generateShareableLink(String filePath) async {
    try {
      // This would upload to cloud storage and return a shareable link
      final filename = filePath.split('/').last;
      final shareableUrl = 'https://insurevis.app/shared/$filename';
      debugPrint('Generated shareable link: $shareableUrl');
      return shareableUrl;
    } catch (e) {
      debugPrint('Error generating shareable link: $e');
      return null;
    }
  }
}
