import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EnhancedPDFService {
  static const String _reportVersion = '2.0';
  static const String _companyName = 'InsureVis AI Assessment';
  
  // Enhanced PDF generation with professional layout
  static Future<String?> generateProfessionalReport({
    required List<Map<String, dynamic>> assessments,
    required Map<String, dynamic> userInfo,
    PDFTemplate template = PDFTemplate.comprehensive,
    bool includePhotos = true,
    bool includeAnalytics = true,
    String? customTitle,
    Map<String, String>? customBranding,
  }) async {
    try {
      final pdf = pw.Document();
      
      // Load custom fonts and assets
      final logoBytes = await _loadAsset('assets/images/app_logo.png');
      final logoImage = logoBytes != null ? pw.MemoryImage(logoBytes) : null;
      
      // Generate pages based on template
      switch (template) {
        case PDFTemplate.comprehensive:
          await _generateComprehensiveReport(pdf, assessments, userInfo, logoImage, includePhotos, includeAnalytics, customTitle);
          break;
        case PDFTemplate.summary:
          await _generateSummaryReport(pdf, assessments, userInfo, logoImage);
          break;
        case PDFTemplate.insurance:
          await _generateInsuranceReport(pdf, assessments, userInfo, logoImage);
          break;
        case PDFTemplate.technical:
          await _generateTechnicalReport(pdf, assessments, userInfo, logoImage, includeAnalytics);
          break;
      }
      
      return await _savePDF(pdf, 'assessment_report_${DateTime.now().millisecondsSinceEpoch}');
    } catch (e) {
      print('Error generating PDF: $e');
      return null;
    }
  }
  
  // Comprehensive report with all details
  static Future<void> _generateComprehensiveReport(
    pw.Document pdf,
    List<Map<String, dynamic>> assessments,
    Map<String, dynamic> userInfo,
    pw.ImageProvider? logo,
    bool includePhotos,
    bool includeAnalytics,
    String? customTitle,
  ) async {
    final headerStyle = pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold);
    final subHeaderStyle = pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold);
    final bodyStyle = pw.TextStyle(fontSize: 12);
    final captionStyle = pw.TextStyle(fontSize: 10, color: PdfColors.grey700);
    
    // Cover Page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => _buildCoverPage(logo, customTitle ?? 'Vehicle Damage Assessment Report', userInfo, headerStyle),
      ),
    );
    
    // Executive Summary
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildHeader(logo, 'Executive Summary'),
        footer: (context) => _buildFooter(context.pageNumber),
        build: (context) => [
          _buildExecutiveSummary(assessments, subHeaderStyle, bodyStyle),
        ],
      ),
    );
    
    // Detailed Assessment Pages
    for (int i = 0; i < assessments.length; i++) {
      final assessment = assessments[i];
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (context) => _buildHeader(logo, 'Assessment ${i + 1} Details'),
          footer: (context) => _buildFooter(context.pageNumber),
          build: (context) => [
            await _buildDetailedAssessment(assessment, i + 1, subHeaderStyle, bodyStyle, captionStyle, includePhotos),
          ],
        ),
      );
    }
    
    // Analytics and Recommendations (if enabled)
    if (includeAnalytics) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (context) => _buildHeader(logo, 'Analytics & Recommendations'),
          footer: (context) => _buildFooter(context.pageNumber),
          build: (context) => [
            _buildAnalyticsSection(assessments, subHeaderStyle, bodyStyle),
            pw.SizedBox(height: 20),
            _buildRecommendationsSection(assessments, subHeaderStyle, bodyStyle),
          ],
        ),
      );
    }
    
    // Appendix
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildHeader(logo, 'Appendix'),
        footer: (context) => _buildFooter(context.pageNumber),
        build: (context) => [
          _buildAppendix(subHeaderStyle, bodyStyle),
        ],
      ),
    );
  }
  
  // Cover page builder
  static pw.Widget _buildCoverPage(
    pw.ImageProvider? logo,
    String title,
    Map<String, dynamic> userInfo,
    pw.TextStyle headerStyle,
  ) {
    return pw.Container(
      padding: pw.EdgeInsets.all(40),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [PdfColors.blue900, PdfColors.blue600],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logo != null) ...[
            pw.Container(
              width: 100,
              height: 100,
              child: pw.Image(logo),
            ),
            pw.SizedBox(height: 40),
          ],
          pw.Text(
            title,
            style: headerStyle.copyWith(color: PdfColors.white),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Powered by AI Technology',
            style: pw.TextStyle(fontSize: 16, color: PdfColors.white70),
          ),
          pw.SizedBox(height: 60),
          pw.Container(
            padding: pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColors.white.withAlpha(0.1),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'Report Details',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                ),
                pw.SizedBox(height: 15),
                _buildInfoRow('Customer:', userInfo['name'] ?? 'Not specified', PdfColors.white),
                _buildInfoRow('Email:', userInfo['email'] ?? 'Not specified', PdfColors.white),
                _buildInfoRow('Generated:', _formatDate(DateTime.now()), PdfColors.white),
                _buildInfoRow('Report Version:', _reportVersion, PdfColors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Executive summary builder
  static pw.Widget _buildExecutiveSummary(
    List<Map<String, dynamic>> assessments,
    pw.TextStyle subHeaderStyle,
    pw.TextStyle bodyStyle,
  ) {
    final totalCost = _calculateTotalCost(assessments);
    final overallSeverity = _getOverallSeverity(assessments);
    final damageCount = assessments.length;
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Executive Summary', style: subHeaderStyle),
        pw.SizedBox(height: 20),
        
        // Key metrics cards
        pw.Row(
          children: [
            pw.Expanded(child: _buildMetricCard('Total Assessments', damageCount.toString(), PdfColors.blue)),
            pw.SizedBox(width: 10),
            pw.Expanded(child: _buildMetricCard('Overall Severity', overallSeverity, _getSeverityColor(overallSeverity))),
            pw.SizedBox(width: 10),
            pw.Expanded(child: _buildMetricCard('Estimated Cost', '\$${totalCost.toStringAsFixed(2)}', PdfColors.green)),
          ],
        ),
        
        pw.SizedBox(height: 30),
        
        // Summary text
        pw.Text('Assessment Overview', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Text(
          'This comprehensive report analyzes $damageCount vehicle damage assessment(s) using advanced AI technology. '
          'The overall severity has been classified as $overallSeverity with an estimated total repair cost of \$${totalCost.toStringAsFixed(2)}. '
          'Each assessment has been thoroughly analyzed for damage type, location, severity, and cost implications.',
          style: bodyStyle,
        ),
        
        pw.SizedBox(height: 20),
        
        // Damage distribution
        _buildDamageDistribution(assessments, bodyStyle),
      ],
    );
  }
  
  // Detailed assessment builder
  static Future<pw.Widget> _buildDetailedAssessment(
    Map<String, dynamic> assessment,
    int assessmentNumber,
    pw.TextStyle subHeaderStyle,
    pw.TextStyle bodyStyle,
    pw.TextStyle captionStyle,
    bool includePhotos,
  ) async {
    final imagePath = assessment['imagePath'] ?? '';
    pw.ImageProvider? image;
    
    if (includePhotos && imagePath.isNotEmpty) {
      try {
        final imageFile = File(imagePath);
        if (await imageFile.exists()) {
          final imageBytes = await imageFile.readAsBytes();
          image = pw.MemoryImage(imageBytes);
        }
      } catch (e) {
        print('Error loading image for PDF: $e');
      }
    }
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Assessment $assessmentNumber', style: subHeaderStyle),
        pw.SizedBox(height: 20),
        
        // Assessment details table
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            _buildTableRow('Damage Type', assessment['damage_type'] ?? 'Unknown', true),
            _buildTableRow('Severity', assessment['severity'] ?? 'Unknown', false),
            _buildTableRow('Location', assessment['location'] ?? 'Unknown', true),
            _buildTableRow('Confidence', '${((assessment['confidence'] ?? 0.0) * 100).round()}%', false),
            _buildTableRow('Cost Estimate', '\$${assessment['cost_estimate'] ?? '0'}', true),
            _buildTableRow('Timestamp', _formatDate(DateTime.tryParse(assessment['timestamp'] ?? '') ?? DateTime.now()), false),
          ],
        ),
        
        pw.SizedBox(height: 20),
        
        // Image (if available)
        if (image != null) ...[
          pw.Text('Damage Photo', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Container(
            height: 300,
            width: double.infinity,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Image(image, fit: pw.BoxFit.contain),
          ),
          pw.SizedBox(height: 5),
          pw.Text('Photo taken during assessment', style: captionStyle),
          pw.SizedBox(height: 20),
        ],
        
        // Detailed description
        if (assessment['description'] != null) ...[
          pw.Text('Analysis Details', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Text(assessment['description'], style: bodyStyle),
        ],
      ],
    );
  }
  
  // Analytics section builder
  static pw.Widget _buildAnalyticsSection(
    List<Map<String, dynamic>> assessments,
    pw.TextStyle subHeaderStyle,
    pw.TextStyle bodyStyle,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Assessment Analytics', style: subHeaderStyle),
        pw.SizedBox(height: 20),
        
        // Cost breakdown chart (simplified for PDF)
        _buildCostBreakdownChart(assessments),
        
        pw.SizedBox(height: 20),
        
        // Severity distribution
        _buildSeverityDistributionChart(assessments),
      ],
    );
  }
  
  // Helper methods
  static pw.Widget _buildHeader(pw.ImageProvider? logo, String title) {
    return pw.Container(
      padding: pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        children: [
          if (logo != null) ...[
            pw.Container(width: 30, height: 30, child: pw.Image(logo)),
            pw.SizedBox(width: 10),
          ],
          pw.Expanded(
            child: pw.Text(
              title,
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(
            _companyName,
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildFooter(int pageNumber) {
    return pw.Container(
      padding: pw.EdgeInsets.only(top: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by $_companyName',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.Text(
            'Page $pageNumber',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildMetricCard(String label, String value, PdfColor color) {
    return pw.Container(
      padding: pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: color.withAlpha(0.1),
        border: pw.Border.all(color: color, width: 2),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(value, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: color)),
          pw.SizedBox(height: 5),
          pw.Text(label, style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
        ],
      ),
    );
  }
  
  static pw.TableRow _buildTableRow(String label, String value, bool isOdd) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: isOdd ? PdfColors.grey50 : null,
      ),
      children: [
        pw.Container(
          padding: pw.EdgeInsets.all(8),
          child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
        pw.Container(
          padding: pw.EdgeInsets.all(8),
          child: pw.Text(value),
        ),
      ],
    );
  }
  
  // Email integration
  static Future<bool> emailReport({
    required String pdfPath,
    required String recipientEmail,
    required String senderEmail,
    required String senderPassword,
    String? customMessage,
    List<String>? ccEmails,
  }) async {
    try {
      final smtpServer = gmail(senderEmail, senderPassword);
      
      final message = Message()
        ..from = Address(senderEmail, 'InsureVis Assessment')
        ..recipients.add(recipientEmail)
        ..ccRecipients.addAll(ccEmails ?? [])
        ..subject = 'Vehicle Damage Assessment Report - ${_formatDate(DateTime.now())}'
        ..text = customMessage ?? _getDefaultEmailMessage()
        ..attachments = [FileAttachment(File(pdfPath))];
      
      final sendReport = await send(message, smtpServer);
      print('Email sent: ${sendReport.toString()}');
      return true;
    } catch (e) {
      print('Error sending email: $e');
      return false;
    }
  }
  
  // Share functionality
  static Future<void> shareReport(String pdfPath) async {
    try {
      await Share.shareXFiles([XFile(pdfPath)], 
        text: 'Vehicle Damage Assessment Report generated by InsureVis');
    } catch (e) {
      print('Error sharing PDF: $e');
    }
  }
  
  // Generate shareable link (placeholder for cloud integration)
  static Future<String?> generateShareableLink(String pdfPath) async {
    // This would integrate with your cloud storage service
    // For now, return a placeholder
    return 'https://insurevis.com/reports/${DateTime.now().millisecondsSinceEpoch}';
  }
  
  // Helper functions
  static Future<Uint8List?> _loadAsset(String path) async {
    try {
      final byteData = await rootBundle.load(path);
      return byteData.buffer.asUint8List();
    } catch (e) {
      print('Error loading asset $path: $e');
      return null;
    }
  }
  
  static double _calculateTotalCost(List<Map<String, dynamic>> assessments) {
    return assessments.fold(0.0, (sum, assessment) {
      final costStr = assessment['cost_estimate']?.toString() ?? '0';
      final cost = double.tryParse(costStr.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
      return sum + cost;
    });
  }
  
  static String _getOverallSeverity(List<Map<String, dynamic>> assessments) {
    if (assessments.isEmpty) return 'None';
    
    final severities = assessments
        .map((a) => a['severity']?.toString().toLowerCase() ?? 'low')
        .toList();
    
    if (severities.any((s) => s.contains('high') || s.contains('severe'))) {
      return 'High';
    } else if (severities.any((s) => s.contains('medium') || s.contains('moderate'))) {
      return 'Medium';
    } else {
      return 'Low';
    }
  }
  
  static PdfColor _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'severe':
        return PdfColors.red;
      case 'medium':
      case 'moderate':
        return PdfColors.orange;
      case 'low':
      case 'minor':
        return PdfColors.green;
      default:
        return PdfColors.blue;
    }
  }
  
  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  static String _getDefaultEmailMessage() {
    return '''
Dear Customer,

Please find attached your vehicle damage assessment report generated by InsureVis AI technology.

This report contains:
- Detailed damage analysis
- Cost estimates
- Professional recommendations
- High-resolution photos

If you have any questions about this report, please don't hesitate to contact us.

Best regards,
InsureVis Team
''';
  }
  
  static Future<String?> _savePDF(pw.Document pdf, String filename) async {
    try {
      final output = await getApplicationDocumentsDirectory();
      final file = File('${output.path}/$filename.pdf');
      await file.writeAsBytes(await pdf.save());
      return file.path;
    } catch (e) {
      print('Error saving PDF: $e');
      return null;
    }
  }
  
  // Placeholder methods for chart building (would be implemented with actual chart widgets)
  static pw.Widget _buildDamageDistribution(List<Map<String, dynamic>> assessments, pw.TextStyle bodyStyle) {
    return pw.Text('Damage distribution analysis would go here', style: bodyStyle);
  }
  
  static pw.Widget _buildCostBreakdownChart(List<Map<String, dynamic>> assessments) {
    return pw.Text('Cost breakdown chart would go here');
  }
  
  static pw.Widget _buildSeverityDistributionChart(List<Map<String, dynamic>> assessments) {
    return pw.Text('Severity distribution chart would go here');
  }
  
  static pw.Widget _buildRecommendationsSection(List<Map<String, dynamic>> assessments, pw.TextStyle subHeaderStyle, pw.TextStyle bodyStyle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Recommendations', style: subHeaderStyle),
        pw.SizedBox(height: 10),
        pw.Text('Professional recommendations based on assessment results would go here', style: bodyStyle),
      ],
    );
  }
  
  static pw.Widget _buildAppendix(pw.TextStyle subHeaderStyle, pw.TextStyle bodyStyle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Technical Appendix', style: subHeaderStyle),
        pw.SizedBox(height: 10),
        pw.Text('Technical details and methodology would go here', style: bodyStyle),
      ],
    );
  }
  
  static pw.Widget _buildInfoRow(String label, String value, PdfColor color) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(color: color)),
          pw.Text(value, style: pw.TextStyle(color: color, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}

// PDF Template options
enum PDFTemplate {
  comprehensive,
  summary,
  insurance,
  technical,
}
