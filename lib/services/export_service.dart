import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart';

class ExportService {
  /// Export assessments to CSV format
  static Future<String?> exportToCSV({
    required List<Map<String, dynamic>> assessments,
    String? fileName,
    bool includeImages = false,
  }) async {
    try {
      // Request storage permission
      if (!await _requestStoragePermission()) {
        throw Exception('Storage permission denied');
      }

      final csvData = <List<dynamic>>[];

      // Add headers
      csvData.add([
        'Assessment ID',
        'Date',
        'Vehicle Make',
        'Vehicle Model',
        'Vehicle Year',
        'Damage Type',
        'Severity Level',
        'Confidence Score',
        'Estimated Cost',
        'Status',
        'Location',
        'Weather',
        'Mileage',
        'Notes',
        'AI Analysis',
        'Recommendation',
        if (includeImages) 'Image Count',
        'Created At',
        'Updated At',
      ]);

      // Add assessment data
      for (final assessment in assessments) {
        final damageAnalysis =
            assessment['damageAnalysis'] as Map<String, dynamic>? ?? {};
        final vehicleInfo =
            assessment['vehicleInfo'] as Map<String, dynamic>? ?? {};
        final metadata = assessment['metadata'] as Map<String, dynamic>? ?? {};

        csvData.add([
          assessment['id'] ?? '',
          assessment['date'] ?? '',
          vehicleInfo['make'] ?? '',
          vehicleInfo['model'] ?? '',
          vehicleInfo['year'] ?? '',
          damageAnalysis['type'] ?? '',
          damageAnalysis['severity'] ?? '',
          damageAnalysis['confidence']?.toString() ?? '',
          assessment['estimatedCost']?.toString() ?? '',
          assessment['status'] ?? '',
          metadata['location'] ?? '',
          metadata['weather'] ?? '',
          metadata['mileage']?.toString() ?? '',
          assessment['notes'] ?? '',
          damageAnalysis['analysis'] ?? '',
          damageAnalysis['recommendation'] ?? '',
          if (includeImages)
            (assessment['images'] as List?)?.length.toString() ?? '0',
          assessment['createdAt'] ?? '',
          assessment['updatedAt'] ?? '',
        ]);
      }

      // Convert to CSV string
      final csvString = const ListToCsvConverter().convert(csvData);

      // Save to file
      final directory =
          await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/${fileName ?? 'assessments_export_${DateTime.now().millisecondsSinceEpoch}'}.csv',
      );
      await file.writeAsString(csvString);

      return file.path;
    } catch (e) {
      print('Error exporting to CSV: $e');
      return null;
    }
  }

  /// Export assessments to Excel format
  static Future<String?> exportToExcel({
    required List<Map<String, dynamic>> assessments,
    String? fileName,
    bool includeCharts = true,
    bool includeImages = false,
  }) async {
    try {
      // Request storage permission
      if (!await _requestStoragePermission()) {
        throw Exception('Storage permission denied');
      }

      final excel = Excel.createExcel();

      // Remove default sheet and create new ones
      excel.delete('Sheet1');

      // Create main data sheet
      final dataSheet = excel['Assessment Data'];
      await _createDataSheet(dataSheet, assessments, includeImages);

      // Create summary sheet
      final summarySheet = excel['Summary'];
      await _createSummarySheet(summarySheet, assessments);

      // Create analytics sheet
      if (includeCharts) {
        final analyticsSheet = excel['Analytics'];
        await _createAnalyticsSheet(analyticsSheet, assessments);
      }

      // Create cost analysis sheet
      final costSheet = excel['Cost Analysis'];
      await _createCostAnalysisSheet(costSheet, assessments);

      // Save to file
      final directory =
          await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final fileName_ =
          fileName ??
          'assessments_export_${DateTime.now().millisecondsSinceEpoch}';
      final file = File('${directory.path}/$fileName_.xlsx');
      final excelBytes = excel.encode();
      if (excelBytes != null) {
        await file.writeAsBytes(excelBytes);
        return file.path;
      }

      return null;
    } catch (e) {
      print('Error exporting to Excel: $e');
      return null;
    }
  }

  /// Create data sheet with all assessments
  static Future<void> _createDataSheet(
    Sheet sheet,
    List<Map<String, dynamic>> assessments,
    bool includeImages,
  ) async {
    // Add headers with styling
    final headers = [
      'Assessment ID',
      'Date',
      'Vehicle Make',
      'Vehicle Model',
      'Vehicle Year',
      'Damage Type',
      'Severity Level',
      'Confidence Score',
      'Estimated Cost',
      'Status',
      'Location',
      'Weather',
      'Mileage',
      'Notes',
      'AI Analysis',
      'Recommendation',
      if (includeImages) 'Image Count',
      'Created At',
      'Updated At',
    ];

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = headers[i] as CellValue?;
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.blue,
        fontColorHex: ExcelColor.white,
      );
    }

    // Add data rows
    for (int rowIndex = 0; rowIndex < assessments.length; rowIndex++) {
      final assessment = assessments[rowIndex];
      final damageAnalysis =
          assessment['damageAnalysis'] as Map<String, dynamic>? ?? {};
      final vehicleInfo =
          assessment['vehicleInfo'] as Map<String, dynamic>? ?? {};
      final metadata = assessment['metadata'] as Map<String, dynamic>? ?? {};

      final rowData = [
        assessment['id'] ?? '',
        assessment['date'] ?? '',
        vehicleInfo['make'] ?? '',
        vehicleInfo['model'] ?? '',
        vehicleInfo['year'] ?? '',
        damageAnalysis['type'] ?? '',
        damageAnalysis['severity'] ?? '',
        damageAnalysis['confidence']?.toString() ?? '',
        assessment['estimatedCost']?.toString() ?? '',
        assessment['status'] ?? '',
        metadata['location'] ?? '',
        metadata['weather'] ?? '',
        metadata['mileage']?.toString() ?? '',
        assessment['notes'] ?? '',
        damageAnalysis['analysis'] ?? '',
        damageAnalysis['recommendation'] ?? '',
        if (includeImages)
          (assessment['images'] as List?)?.length.toString() ?? '0',
        assessment['createdAt'] ?? '',
        assessment['updatedAt'] ?? '',
      ];

      for (int colIndex = 0; colIndex < rowData.length; colIndex++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(
            columnIndex: colIndex,
            rowIndex: rowIndex + 1,
          ),
        );
        cell.value = rowData[colIndex] as CellValue?;
      }
    }
  }

  /// Create summary sheet with key metrics
  static Future<void> _createSummarySheet(
    Sheet sheet,
    List<Map<String, dynamic>> assessments,
  ) async {
    // Summary statistics
    final totalAssessments = assessments.length;
    final avgCost =
        assessments.isNotEmpty
            ? assessments
                    .map((a) => (a['estimatedCost'] as num?) ?? 0)
                    .reduce((a, b) => a + b) /
                totalAssessments
            : 0;

    final severityCounts = <String, int>{};
    final damageTypeCounts = <String, int>{};
    final statusCounts = <String, int>{};

    for (final assessment in assessments) {
      final damageAnalysis =
          assessment['damageAnalysis'] as Map<String, dynamic>? ?? {};
      final severity = damageAnalysis['severity'] as String? ?? 'Unknown';
      final damageType = damageAnalysis['type'] as String? ?? 'Unknown';
      final status = assessment['status'] as String? ?? 'Unknown';

      severityCounts[severity] = (severityCounts[severity] ?? 0) + 1;
      damageTypeCounts[damageType] = (damageTypeCounts[damageType] ?? 0) + 1;
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    int currentRow = 0;

    // Title
    var cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
    );
    cell.value = 'Assessment Summary Report' as CellValue?;
    cell.cellStyle = CellStyle(bold: true, fontSize: 16);
    currentRow += 2;

    // General metrics
    final metrics = [
      ['Total Assessments', totalAssessments.toString()],
      ['Average Estimated Cost', '\$${avgCost.toStringAsFixed(2)}'],
      ['Report Generated', DateTime.now().toString().split('.')[0]],
    ];

    for (final metric in metrics) {
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
          )
          .value = metric[0] as CellValue?;
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow),
          )
          .value = metric[1] as CellValue?;
      currentRow++;
    }

    currentRow += 2;

    // Severity breakdown
    cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
    );
    cell.value = 'Severity Breakdown' as CellValue?;
    cell.cellStyle = CellStyle(bold: true);
    currentRow++;

    for (final entry in severityCounts.entries) {
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
          )
          .value = entry.key as CellValue?;
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow),
          )
          .value = entry.value.toString() as CellValue?;
      currentRow++;
    }

    currentRow += 2;

    // Damage type breakdown
    cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
    );
    cell.value = 'Damage Type Breakdown' as CellValue?;
    cell.cellStyle = CellStyle(bold: true);
    currentRow++;

    for (final entry in damageTypeCounts.entries) {
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
          )
          .value = entry.key as CellValue?;
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow),
          )
          .value = entry.value.toString() as CellValue?;
      currentRow++;
    }
  }

  /// Create analytics sheet with trends and insights
  static Future<void> _createAnalyticsSheet(
    Sheet sheet,
    List<Map<String, dynamic>> assessments,
  ) async {
    // Create monthly trend analysis
    final monthlyData = <String, Map<String, dynamic>>{};

    for (final assessment in assessments) {
      final dateStr = assessment['date'] as String? ?? '';
      if (dateStr.isNotEmpty) {
        final date = DateTime.tryParse(dateStr);
        if (date != null) {
          final monthKey =
              '${date.year}-${date.month.toString().padLeft(2, '0')}';
          if (!monthlyData.containsKey(monthKey)) {
            monthlyData[monthKey] = {
              'count': 0,
              'totalCost': 0.0,
              'severityCounts': <String, int>{},
            };
          }

          monthlyData[monthKey]!['count'] =
              (monthlyData[monthKey]!['count'] as int) + 1;
          monthlyData[monthKey]!['totalCost'] =
              (monthlyData[monthKey]!['totalCost'] as double) +
              ((assessment['estimatedCost'] as num?) ?? 0);

          final severity =
              (assessment['damageAnalysis']
                      as Map<String, dynamic>?)?['severity']
                  as String? ??
              'Unknown';
          final severityCounts =
              monthlyData[monthKey]!['severityCounts'] as Map<String, int>;
          severityCounts[severity] = (severityCounts[severity] ?? 0) + 1;
        }
      }
    }

    // Add headers
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
        'Month' as CellValue?;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value =
        'Assessment Count' as CellValue?;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value =
        'Total Cost' as CellValue?;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).value =
        'Average Cost' as CellValue?;

    int rowIndex = 1;
    for (final entry
        in monthlyData.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key))) {
      final data = entry.value;
      final count = data['count'] as int;
      final totalCost = data['totalCost'] as double;

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = entry.key as CellValue?;
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = count as CellValue?;
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = totalCost.toStringAsFixed(2) as CellValue?;
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = (count > 0 ? (totalCost / count).toStringAsFixed(2) : '0.00')
              as CellValue?;
      rowIndex++;
    }
  }

  /// Create cost analysis sheet
  static Future<void> _createCostAnalysisSheet(
    Sheet sheet,
    List<Map<String, dynamic>> assessments,
  ) async {
    // Cost analysis by various factors
    final costByType = <String, List<double>>{};
    final costBySeverity = <String, List<double>>{};

    for (final assessment in assessments) {
      final cost = (assessment['estimatedCost'] as num?)?.toDouble() ?? 0.0;
      final damageAnalysis =
          assessment['damageAnalysis'] as Map<String, dynamic>? ?? {};
      final type = damageAnalysis['type'] as String? ?? 'Unknown';
      final severity = damageAnalysis['severity'] as String? ?? 'Unknown';

      costByType.putIfAbsent(type, () => []).add(cost);
      costBySeverity.putIfAbsent(severity, () => []).add(cost);
    }

    int currentRow = 0;

    // Cost by damage type
    var cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
    );
    cell.value = 'Cost Analysis by Damage Type' as CellValue?;
    cell.cellStyle = CellStyle(bold: true, fontSize: 14);
    currentRow += 2;

    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
        .value = 'Damage Type' as CellValue?;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
        .value = 'Count' as CellValue?;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow))
        .value = 'Average Cost' as CellValue?;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow))
        .value = 'Total Cost' as CellValue?;
    currentRow++;

    for (final entry in costByType.entries) {
      final costs = entry.value;
      final avgCost =
          costs.isNotEmpty ? costs.reduce((a, b) => a + b) / costs.length : 0.0;
      final totalCost = costs.reduce((a, b) => a + b);

      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
          )
          .value = entry.key as CellValue?;
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow),
          )
          .value = costs.length as CellValue?;
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow),
          )
          .value = avgCost.toStringAsFixed(2) as CellValue?;
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow),
          )
          .value = totalCost.toStringAsFixed(2) as CellValue?;
      currentRow++;
    }

    currentRow += 2;

    // Cost by severity
    cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
    );
    cell.value = 'Cost Analysis by Severity' as CellValue?;
    cell.cellStyle = CellStyle(bold: true, fontSize: 14);
    currentRow += 2;

    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
        .value = 'Severity' as CellValue?;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
        .value = 'Count' as CellValue?;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow))
        .value = 'Average Cost' as CellValue?;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow))
        .value = 'Total Cost' as CellValue?;
    currentRow++;

    for (final entry in costBySeverity.entries) {
      final costs = entry.value;
      final avgCost =
          costs.isNotEmpty ? costs.reduce((a, b) => a + b) / costs.length : 0.0;
      final totalCost = costs.reduce((a, b) => a + b);

      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
          )
          .value = entry.key as CellValue?;
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow),
          )
          .value = costs.length as CellValue?;
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow),
          )
          .value = avgCost.toStringAsFixed(2) as CellValue?;
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow),
          )
          .value = totalCost.toStringAsFixed(2) as CellValue?;
      currentRow++;
    }
  }

  /// Export and share file
  static Future<void> shareExportedFile(
    String filePath, {
    String? title,
  }) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: title ?? 'Assessment Export',
        subject: 'InsureVis Assessment Export',
      );
    } catch (e) {
      print('Error sharing file: $e');
    }
  }

  /// Request storage permission
  static Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true; // iOS doesn't need explicit storage permission for app documents
  }
}

/// Export format options
enum ExportFormat { csv, excel, json }

/// Export options configuration
class ExportOptions {
  final ExportFormat format;
  final bool includeImages;
  final bool includeAnalytics;
  final bool includeCharts;
  final String? fileName;
  final String? customTitle;
  final Map<String, String>? customFields;

  const ExportOptions({
    this.format = ExportFormat.excel,
    this.includeImages = false,
    this.includeAnalytics = true,
    this.includeCharts = true,
    this.fileName,
    this.customTitle,
    this.customFields,
  });
}
