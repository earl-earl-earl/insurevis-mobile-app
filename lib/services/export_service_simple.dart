import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import '../models/assessment_model.dart';

class ExportService {
  static const String _exportVersion = '1.0';

  /// Export assessments to CSV format
  Future<String> exportToCSV(List<Assessment> assessments) async {
    try {
      // Prepare CSV data
      List<List<dynamic>> csvData = [
        [
          'ID',
          'Image Path',
          'Timestamp',
          'Status',
          'Error Message',
          'Has Results',
        ],
      ];

      for (var assessment in assessments) {
        csvData.add([
          assessment.id,
          assessment.imagePath,
          assessment.timestamp.toIso8601String(),
          assessment.status.name,
          assessment.errorMessage ?? '',
          assessment.results != null ? 'Yes' : 'No',
        ]);
      }

      // Convert to CSV string
      String csvString = const ListToCsvConverter().convert(csvData);

      // Save to file
      final dir = await getApplicationDocumentsDirectory();
      final filename =
          'assessments_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${dir.path}/$filename');
      await file.writeAsString(csvString);

      debugPrint('CSV exported to: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('Error exporting to CSV: $e');
      rethrow;
    }
  }

  /// Export assessments to Excel format with multiple sheets
  Future<String> exportToExcel(List<Assessment> assessments) async {
    try {
      var excel = Excel.createExcel();

      // Remove default sheet
      excel.delete('Sheet1');

      // Create Assessment Summary sheet
      _createSummarySheet(excel, assessments);

      // Create Detailed Assessment sheet
      _createDetailedSheet(excel, assessments);

      // Create Analytics sheet
      _createAnalyticsSheet(excel, assessments);

      // Save to file
      final dir = await getApplicationDocumentsDirectory();
      final filename =
          'assessments_report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File('${dir.path}/$filename');

      var fileBytes = excel.save();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
      }

      debugPrint('Excel exported to: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('Error exporting to Excel: $e');
      rethrow;
    }
  }

  void _createSummarySheet(Excel excel, List<Assessment> assessments) {
    var sheet = excel['Summary'];

    // Headers
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue(
      'Assessment Summary Report',
    );
    sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue(
      'Generated: ${DateTime.now()}',
    );
    sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue(
      'Total Assessments: ${assessments.length}',
    );

    // Status breakdown
    final completed =
        assessments.where((a) => a.status == AssessmentStatus.completed).length;
    final processing =
        assessments
            .where((a) => a.status == AssessmentStatus.processing)
            .length;
    final failed =
        assessments.where((a) => a.status == AssessmentStatus.failed).length;

    sheet.cell(CellIndex.indexByString('A5')).value = TextCellValue(
      'Status Breakdown:',
    );
    sheet.cell(CellIndex.indexByString('A6')).value = TextCellValue(
      'Completed: $completed',
    );
    sheet.cell(CellIndex.indexByString('A7')).value = TextCellValue(
      'Processing: $processing',
    );
    sheet.cell(CellIndex.indexByString('A8')).value = TextCellValue(
      'Failed: $failed',
    );
  }

  void _createDetailedSheet(Excel excel, List<Assessment> assessments) {
    var sheet = excel['Detailed Data'];

    // Headers
    final headers = [
      'ID',
      'Image Path',
      'Timestamp',
      'Status',
      'Error Message',
      'Has Results',
    ];
    for (int i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(headers[i]);
    }

    // Data rows
    for (int i = 0; i < assessments.length; i++) {
      final assessment = assessments[i];
      final rowIndex = i + 1;

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(assessment.id);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = TextCellValue(assessment.imagePath);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = TextCellValue(assessment.timestamp.toIso8601String());
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = TextCellValue(assessment.status.name);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .value = TextCellValue(assessment.errorMessage ?? '');
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = TextCellValue(assessment.results != null ? 'Yes' : 'No');
    }
  }

  void _createAnalyticsSheet(Excel excel, List<Assessment> assessments) {
    var sheet = excel['Analytics'];

    // Analytics data
    final total = assessments.length;
    final completed =
        assessments.where((a) => a.status == AssessmentStatus.completed).length;
    final processing =
        assessments
            .where((a) => a.status == AssessmentStatus.processing)
            .length;
    final failed =
        assessments.where((a) => a.status == AssessmentStatus.failed).length;
    final successRate =
        total > 0 ? (completed / total * 100).toStringAsFixed(2) : '0.00';

    // Headers and data
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Metric');
    sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('Value');

    sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue(
      'Total Assessments',
    );
    sheet.cell(CellIndex.indexByString('B2')).value = IntCellValue(total);

    sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue(
      'Completed',
    );
    sheet.cell(CellIndex.indexByString('B3')).value = IntCellValue(completed);

    sheet.cell(CellIndex.indexByString('A4')).value = TextCellValue(
      'Processing',
    );
    sheet.cell(CellIndex.indexByString('B4')).value = IntCellValue(processing);

    sheet.cell(CellIndex.indexByString('A5')).value = TextCellValue('Failed');
    sheet.cell(CellIndex.indexByString('B5')).value = IntCellValue(failed);

    sheet.cell(CellIndex.indexByString('A6')).value = TextCellValue(
      'Success Rate (%)',
    );
    sheet.cell(CellIndex.indexByString('B6')).value = TextCellValue(
      successRate,
    );
  }

  /// Share exported file
  Future<void> shareFile(String filePath) async {
    try {
      await Share.shareXFiles([XFile(filePath)]);
    } catch (e) {
      debugPrint('Error sharing file: $e');
    }
  }

  /// Get analytics summary
  Map<String, dynamic> getAnalyticsSummary(List<Assessment> assessments) {
    final total = assessments.length;
    final completed =
        assessments.where((a) => a.status == AssessmentStatus.completed).length;
    final processing =
        assessments
            .where((a) => a.status == AssessmentStatus.processing)
            .length;
    final failed =
        assessments.where((a) => a.status == AssessmentStatus.failed).length;
    final successRate = total > 0 ? (completed / total * 100) : 0.0;

    return {
      'total_assessments': total,
      'completed': completed,
      'processing': processing,
      'failed': failed,
      'success_rate': successRate,
      'export_timestamp': DateTime.now().toIso8601String(),
      'export_version': _exportVersion,
    };
  }
}
