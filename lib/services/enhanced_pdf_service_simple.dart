import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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

    return _savePDF(pdf, 'summary_report_${now.millisecondsSinceEpoch}');
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

    return _savePDF(pdf, 'insurance_report_${now.millisecondsSinceEpoch}');
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

    return _savePDF(pdf, 'technical_report_${now.millisecondsSinceEpoch}');
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
              assessments
                  .map(
                    (assessment) => [
                      assessment.id,
                      assessment.timestamp.toString().split(' ')[0],
                      assessment.status.name.toUpperCase(),
                      assessment.results != null ? 'Available' : 'N/A',
                    ],
                  )
                  .toList(),
          border: pw.TableBorder.all(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellAlignment: pw.Alignment.centerLeft,
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
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename.pdf');
      await file.writeAsBytes(bytes);
      return file.path;
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
