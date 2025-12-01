import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_picker/file_picker.dart';
import '../services/local_storage_service.dart';
import 'file_writer.dart';

class PDFService {
  // --- Reusable Header Widget ---
  static pw.Widget _buildHeader(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerLeft,
      margin: const pw.EdgeInsets.only(bottom: 20.0),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'InsureVis',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 24,
                  color: PdfColors.black,
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Vehicle Damage Assessment',
                    style: pw.TextStyle(fontSize: 11, color: PdfColors.black),
                  ),
                  pw.Text(
                    'contact@insurevis.com',
                    style: pw.TextStyle(fontSize: 11, color: PdfColors.black),
                  ),
                  pw.Text(
                    '+1 234 567 890',
                    style: pw.TextStyle(fontSize: 11, color: PdfColors.black),
                  ),
                ],
              ),
            ],
          ),
          pw.Divider(),
        ],
      ),
    );
  }

  // --- Reusable Footer Widget ---
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 20.0),
      child: pw.Column(
        children: [
          pw.Divider(),
          pw.SizedBox(height: 10),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            'This is an automated report. For inquiries, please contact our support team.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
          ),
        ],
      ),
    );
  }

  /// Generate and save multiple results PDF with user file picker
  static Future<String?> generateAndSaveMultiplePDFWithPicker({
    required List<String> imagePaths,
    required Map<String, Map<String, dynamic>> apiResponses,
    String? suggestedFileName,
  }) async {
    try {
      final pdf = await _generateMultiplePDF(imagePaths, apiResponses);
      if (pdf == null) return null;

      return await _savePDFWithPicker(
        pdf,
        suggestedFileName ??
            'multi_damage_assessment_${DateTime.now().toString().split(' ')[0]}.pdf',
      );
    } catch (e) {
      print('Error generating multiple PDF with picker: $e');
      return null;
    }
  }

  /// Generate PDF document for multiple results. THIS IS THE CORE GENERATOR.
  static Future<pw.Document?> _generateMultiplePDF(
    List<String> imagePaths,
    Map<String, Map<String, dynamic>> apiResponses,
  ) async {
    try {
      final pdf = pw.Document();
      final responseEntries = apiResponses.entries.toList();

      // Calculate total estimated cost from all responses
      double totalEstimatedCost = 0.0;
      bool hasAnySevere = false;
      for (var entry in responseEntries) {
        final apiResponse = entry.value;
        final overallSeverity =
            apiResponse['overall_severity']?.toString() ?? '';
        if (overallSeverity.toLowerCase() == 'severe') {
          hasAnySevere = true;
        }

        final totalCost = apiResponse['total_cost']?.toString() ?? '';
        if (totalCost.isNotEmpty && totalCost != 'Not available') {
          try {
            var tc = totalCost.trim();
            // Remove currency symbols and extract numeric value
            if (tc.startsWith('₱')) {
              tc = tc.substring(1).trim();
            } else if (tc.toUpperCase().startsWith('PHP')) {
              tc = tc.substring(3).trim();
              if (tc.startsWith(':') ||
                  tc.startsWith('-') ||
                  tc.startsWith('.')) {
                tc = tc.substring(1).trim();
              }
            }
            // Remove commas if present
            tc = tc.replaceAll(',', '');
            final parsed = double.tryParse(tc);
            if (parsed != null) {
              totalEstimatedCost += parsed;
            }
          } catch (e) {
            print('Error parsing cost: $e');
          }
        }
      }

      // Build all content widgets (summary + assessments)
      final List<pw.Widget> allContent = [];

      // Add summary page content
      allContent.add(
        _buildSummaryPage(
          responseEntries.length,
          totalEstimatedCost,
          hasAnySevere,
        ),
      );

      // Add individual assessment widgets
      for (var i = 0; i < responseEntries.length; i++) {
        final entry = responseEntries[i];
        final responseKey = entry.key;
        final apiResponse = entry.value;

        // Check if the key corresponds to a real file. If not, it's a manual entry.
        final imageFile = File(responseKey);
        final imagePathForPage =
            await imageFile.exists()
                ? responseKey
                : ''; // Pass empty path for manual

        allContent.add(pw.SizedBox(height: 30));
        allContent.add(
          _buildIndividualResult(i + 1, imagePathForPage, apiResponse),
        );
      }

      // Add everything in a single MultiPage to allow natural page breaks
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: _buildHeader,
          footer: _buildFooter,
          build: (pw.Context context) => allContent,
        ),
      );

      return pdf;
    } catch (e) {
      print('Error generating multiple PDF: $e');
      return null;
    }
  }

  /// Public method to generate and save a PDF, intended for auto-saving.
  static Future<String?> generateMultipleResultsPDF({
    required List<String> imagePaths,
    required Map<String, Map<String, dynamic>> apiResponses,
  }) async {
    try {
      final pdf = await _generateMultiplePDF(imagePaths, apiResponses);
      if (pdf == null) return null;

      return await _savePDF(
        pdf,
        'multi_damage_assessment_${DateTime.now().toString().split(' ')[0]}.pdf',
      );
    } catch (e) {
      print('Error generating multi-results PDF: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  /// Public method to generate PDF bytes, useful for sharing or custom saving.
  static Future<Uint8List?> generateMultipleResultsPDFBytes({
    required List<String> imagePaths,
    required Map<String, Map<String, dynamic>> apiResponses,
  }) async {
    try {
      final pdf = await _generateMultiplePDF(imagePaths, apiResponses);
      if (pdf == null) return null;
      final bytes = await pdf.save();
      return Uint8List.fromList(bytes);
    } catch (e) {
      print('Error generating PDF bytes: $e');
      return null;
    }
  }

  /// Generate PDF and save to temporary directory for use in job estimate
  /// Returns the file path of the temporary PDF, or null if generation fails
  static Future<String?> generateTemporaryPDF({
    required List<String> imagePaths,
    required Map<String, Map<String, dynamic>> apiResponses,
  }) async {
    try {
      final pdf = await _generateMultiplePDF(imagePaths, apiResponses);
      if (pdf == null) return null;

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'job_estimate_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final tempFile = File('${tempDir.path}/$fileName');

      // Save PDF bytes to temporary file
      final bytes = await pdf.save();
      await tempFile.writeAsBytes(bytes);

      if (await tempFile.exists() && await tempFile.length() > 0) {
        print('Temporary PDF generated at: ${tempFile.path}');
        return tempFile.path;
      }

      return null;
    } catch (e) {
      print('Error generating temporary PDF: $e');
      return null;
    }
  }

  /// Builds a summary page showing the total estimated cost
  static pw.Widget _buildSummaryPage(
    int totalAssessments,
    double totalEstimatedCost,
    bool hasAnySevere,
  ) {
    String formattedTotal;
    if (hasAnySevere) {
      formattedTotal = 'To be given by mechanic';
    } else {
      // Format with comma separator for thousands
      final formatter = NumberFormat('#,##0.00', 'en_US');
      formattedTotal = 'PHP ${formatter.format(totalEstimatedCost)}';
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Center(
          child: pw.Text(
            'Vehicle Damage Assessment Report',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
        ),
        pw.SizedBox(height: 15),

        // Report details - simple text format
        pw.Text(
          'Report Date: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
          style: pw.TextStyle(fontSize: 12, color: PdfColors.black),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Total Assessments: $totalAssessments',
          style: pw.TextStyle(fontSize: 12, color: PdfColors.black),
        ),
        pw.SizedBox(height: 20),

        // Total estimated cost box
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 2),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                'Total Estimated Cost',
                style: pw.TextStyle(fontSize: 14, color: PdfColors.black),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                formattedTotal,
                style: pw.TextStyle(
                  fontSize: 26,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 20),

        pw.Text(
          'Detailed Assessment',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'This report contains $totalAssessments detailed damage assessment(s). '
          'Each assessment includes information about detected damages, severity levels, '
          'and individual cost estimates. Please review each section carefully',
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.black),
        ),
      ],
    );
  }

  /// Builds the content for a single page of the PDF report.
  static pw.Widget _buildIndividualResult(
    int entryNumber,
    String imagePath, // Will be empty for manual damages
    Map<String, dynamic> apiResponse,
  ) {
    pw.ImageProvider? image;
    if (imagePath.isNotEmpty) {
      try {
        final imageFile = File(imagePath);
        if (imageFile.existsSync()) {
          final imageBytes = imageFile.readAsBytesSync();
          image = pw.MemoryImage(imageBytes);
        }
      } catch (e) {
        print('Warning: Failed to load image for PDF page: $e');
      }
    }

    final overallSeverity =
        apiResponse['overall_severity']?.toString() ?? 'Manual Entry';
    final isSevere = overallSeverity.toLowerCase() == 'severe';
    final totalCost = apiResponse['total_cost']?.toString() ?? 'Not available';
    final damages = apiResponse['damages'] ?? apiResponse['prediction'] ?? [];
    final bool isManual = imagePath.isEmpty;

    String formattedCost;
    if (isSevere) {
      formattedCost = 'To be given by mechanic';
    } else {
      formattedCost = 'Not available';
      if (totalCost != 'Not available' && totalCost.isNotEmpty) {
        try {
          // Normalize cases where totalCost may start with the peso symbol (₱) or 'PHP'.
          // We want the PDF to always display 'PHP <amount>'.
          var tc = totalCost.trim();
          if (tc.startsWith('₱')) {
            // Remove the peso symbol and any whitespace after it
            tc = tc.substring(1).trim();
            // If what's left is numeric, format it; otherwise keep as-is but prefix with PHP
            final parsed = double.tryParse(tc);
            if (parsed != null) {
              formattedCost = 'PHP ${parsed.toStringAsFixed(2)}';
            } else {
              formattedCost = 'PHP $tc';
            }
          } else if (tc.toUpperCase().startsWith('PHP')) {
            // Remove leading 'PHP' and any punctuation/space
            var after = tc.substring(3).trim();
            if (after.startsWith(':') ||
                after.startsWith('-') ||
                after.startsWith('.')) {
              after = after.substring(1).trim();
            }
            final parsed = double.tryParse(after);
            if (parsed != null) {
              formattedCost = 'PHP ${parsed.toStringAsFixed(2)}';
            } else if (after.isNotEmpty) {
              formattedCost = 'PHP $after';
            } else {
              // If nothing after 'PHP', just keep original normalized
              formattedCost = 'PHP';
            }
          } else {
            final cost = double.parse(tc);
            formattedCost = 'PHP ${cost.toStringAsFixed(2)}';
          }
        } catch (e) {
          // Fallback: ensure we at least prefix with PHP instead of the peso symbol
          if (totalCost.startsWith('₱')) {
            formattedCost = 'PHP ${totalCost.substring(1).trim()}';
          } else if (totalCost.toUpperCase().startsWith('PHP')) {
            formattedCost = totalCost;
          } else {
            formattedCost = 'PHP $totalCost';
          }
        }
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          isManual ? 'Added Manual Damages' : 'Image $entryNumber Analysis',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
        pw.SizedBox(height: 15),

        if (image != null) ...[
          pw.Center(
            child: pw.Container(
              width: 150,
              height: 150,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              child: pw.Image(image, fit: pw.BoxFit.contain),
            ),
          ),
          pw.SizedBox(height: 20),
        ],

        // Assessment Summary section - only show for non-manual entries
        if (!isManual) ...[
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Assessment Summary',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.Text(
                      'Damage Detected: ${damages.length}',
                      style: pw.TextStyle(fontSize: 12, color: PdfColors.black),
                    ),
                  ],
                ),
                pw.Divider(color: PdfColors.black),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Damaged Part:',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.black,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            damages.isNotEmpty
                                ? _capitalizeFirst(
                                  damages[0]['label']?.toString() ??
                                      damages[0]['damage_type']?.toString() ??
                                      damages[0]['damaged_part']?.toString() ??
                                      'Unknown',
                                )
                                : 'N/A',
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Severity:',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.black,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            _capitalizeFirst(overallSeverity),
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Damage Type:',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.black,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            damages.isNotEmpty
                                ? _capitalizeFirst(
                                  damages[0]['damage_category']?.toString() ??
                                      damages[0]['class']?.toString() ??
                                      damages[0]['type']?.toString() ??
                                      'Scratch / Paint Wear',
                                )
                                : 'N/A',
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        pw.SizedBox(height: 15),

        // Cost Estimation section for non-severe damages (both image-based and manual)
        if (damages.isNotEmpty && !isSevere) ...[
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Cost Estimation',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.Divider(color: PdfColors.black),
                // Header row
                pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'Damaged Part:',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'Action:',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        'Cost:',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                ...damages.asMap().entries.map((entry) {
                  final damage = entry.value;
                  final label =
                      damage['label']?.toString() ??
                      damage['damage_type']?.toString() ??
                      damage['damaged_part']?.toString() ??
                      'Unknown';
                  final action =
                      damage['recommended_action']?.toString() ??
                      damage['action']?.toString() ??
                      'Repair';
                  final cost =
                      damage['cost']?.toString() ??
                      damage['estimated_cost']?.toString() ??
                      '0';

                  String formattedItemCost = 'PHP 0.00';
                  try {
                    var costStr = cost.trim();
                    if (costStr.startsWith('₱')) {
                      costStr = costStr.substring(1).trim();
                    } else if (costStr.toUpperCase().startsWith('PHP')) {
                      costStr = costStr.substring(3).trim();
                    }
                    costStr = costStr.replaceAll(',', '');
                    final parsed = double.tryParse(costStr);
                    if (parsed != null) {
                      final formatter = NumberFormat('#,##0.00', 'en_US');
                      formattedItemCost = 'PHP ${formatter.format(parsed)}';
                    }
                  } catch (e) {
                    formattedItemCost = cost;
                  }

                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            _capitalizeFirst(label),
                            style: pw.TextStyle(
                              fontSize: 11,
                              color: PdfColors.black,
                            ),
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            _capitalizeFirst(action),
                            style: pw.TextStyle(
                              fontSize: 11,
                              color: PdfColors.black,
                            ),
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            formattedItemCost,
                            style: pw.TextStyle(
                              fontSize: 11,
                              color: PdfColors.black,
                            ),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // --- File Saving and Utility Functions ---

  static Future<String?> savePdfBytesToDirectory(
    Uint8List pdfBytes,
    String fileName,
    String directoryPath,
  ) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      String finalFileName = fileName;
      int counter = 1;
      while (await File('${directory.path}/$finalFileName').exists()) {
        final nameWithoutExtension = fileName.replaceAll('.pdf', '');
        finalFileName = '${nameWithoutExtension}_$counter.pdf';
        counter++;
      }
      final file = File('${directory.path}/$finalFileName');
      await file.writeAsBytes(pdfBytes);
      if (await file.exists() && await file.length() > 0) {
        return file.path;
      }
      return null;
    } catch (e) {
      print('Error saving PDF to directory: $e');
      return null;
    }
  }

  static Future<bool> _isPathUnderAllowedDirs(String path) async {
    try {
      if (path.isEmpty || path.startsWith('content://')) return false;
      final normalized = path.replaceAll('\\', '/');
      final appDoc = await getApplicationDocumentsDirectory();
      if (normalized.startsWith(appDoc.path)) return true;
      try {
        final ext = await getExternalStorageDirectory();
        if (ext != null && normalized.startsWith(ext.path)) return true;
      } catch (_) {}
      try {
        final externalDocs = await getExternalStorageDirectories(
          type: StorageDirectory.documents,
        );
        if (externalDocs != null) {
          for (final d in externalDocs) {
            if (normalized.startsWith(d.path)) return true;
          }
        }
      } catch (_) {}
      return false;
    } catch (e) {
      print('Error validating path allowed dirs: $e');
      return false;
    }
  }

  static Future<String?> savePdfBytesWithPicker(
    Uint8List pdfBytes,
    String suggestedFileName,
  ) async {
    try {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save PDF Report',
        fileName: suggestedFileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: pdfBytes,
      );
      if (outputFile == null) return null;
      if (!outputFile.toLowerCase().endsWith('.pdf')) {
        outputFile = '$outputFile.pdf';
      }
      if (outputFile.startsWith('content://')) {
        await FileWriter.writeBytesToUri(outputFile, pdfBytes);
        return outputFile;
      }
      if (outputFile.startsWith('/')) {
        final allowed = await _isPathUnderAllowedDirs(outputFile);
        if (!allowed) {
          print(
            'Picker returned unsafe absolute path ($outputFile). Falling back to app documents save.',
          );
          return await LocalStorageService.saveFileToDocuments(
            pdfBytes,
            suggestedFileName,
            allowPicker: false,
          );
        }
      }
      final file = File(outputFile);
      final directory = file.parent;
      if (!await directory.exists()) await directory.create(recursive: true);
      await file.writeAsBytes(pdfBytes);
      if (await file.exists() && await file.length() > 0) return file.path;
      return null;
    } catch (e) {
      print('Error saving PDF with picker: $e');
      return null;
    }
  }

  static Future<String?> _savePDF(pw.Document pdf, String fileName) async {
    try {
      final bytesList = await pdf.save();
      final pdfBytes = Uint8List.fromList(bytesList);
      try {
        final pickedPath = await savePdfBytesWithPicker(pdfBytes, fileName);
        if (pickedPath != null) return pickedPath;
      } catch (e) {
        print('Picker save attempt failed: $e');
      }
      try {
        final saved = await LocalStorageService.saveFileToDocuments(
          pdfBytes,
          fileName,
          allowPicker: false,
        );
        if (saved != null) return saved;
      } catch (e) {
        print('LocalStorageService save failed: $e');
      }
      try {
        final tempDir = Directory.systemTemp.createTempSync('pdf_fallback_');
        final fallbackFile = File('${tempDir.path}/$fileName');
        await fallbackFile.writeAsBytes(pdfBytes);
        if (await fallbackFile.exists() && await fallbackFile.length() > 0) {
          print('Fallback save successful: ${fallbackFile.path}');
          return fallbackFile.path;
        }
      } catch (e) {
        print('Fallback temp save failed: $e');
      }
      return null;
    } catch (e) {
      print('Error saving PDF: $e');
      return null;
    }
  }

  static Future<String?> _savePDFWithPicker(
    pw.Document pdf,
    String suggestedFileName,
  ) async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        print(
          'FilePicker.saveFile not supported on mobile; falling back to default save',
        );
        return await _savePDF(pdf, suggestedFileName);
      }
      final pdfBytes = await pdf.save();
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save PDF Report',
        fileName: suggestedFileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: pdfBytes,
      );
      if (outputFile == null) {
        print('User cancelled file picker');
        return null;
      }
      if (!outputFile.toLowerCase().endsWith('.pdf')) {
        outputFile = '$outputFile.pdf';
      }
      if (outputFile.startsWith('content://')) {
        try {
          await FileWriter.writeBytesToUri(
            outputFile,
            Uint8List.fromList(pdfBytes),
          );
        } catch (e) {
          throw Exception('Failed to write to content URI: $e');
        }
      } else if (outputFile.startsWith('/')) {
        final allowed = await _isPathUnderAllowedDirs(outputFile);
        if (!allowed) {
          print(
            'User picked an absolute path that is not under allowed directories: $outputFile',
          );
          print('Falling back to default save location...');
          return await _savePDF(pdf, suggestedFileName);
        }
        final file = File(outputFile);
        final directory = file.parent;
        if (!await directory.exists()) await directory.create(recursive: true);
        await file.writeAsBytes(pdfBytes);
      } else {
        final file = File(outputFile);
        final directory = file.parent;
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        await file.writeAsBytes(pdfBytes);
      }
      if (outputFile.startsWith('content://')) {
        print('PDF written to content URI: $outputFile');
        print('PDF size: ${pdfBytes.length} bytes');
        return outputFile;
      } else {
        final writtenFile = File(outputFile);
        if (await writtenFile.exists() && await writtenFile.length() > 0) {
          print(
            'PDF saved successfully to user-chosen location: ${writtenFile.path}',
          );
          print('PDF size: ${pdfBytes.length} bytes');
          return writtenFile.path;
        } else {
          throw Exception(
            'File was not written successfully to chosen location',
          );
        }
      }
    } catch (e) {
      print('Error saving PDF with file picker: $e');
      print('Falling back to default save location...');
      return await _savePDF(pdf, suggestedFileName);
    }
  }

  static String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
