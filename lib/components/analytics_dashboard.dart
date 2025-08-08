import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/assessment_model.dart';
import '../services/export_service.dart';

class AnalyticsDashboard extends StatefulWidget {
  final List<Assessment> assessments;

  const AnalyticsDashboard({super.key, required this.assessments});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTimeRange = '6 months';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.access_time),
            onSelected: (value) {
              setState(() {
                _selectedTimeRange = value;
              });
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: '1 month',
                    child: Text('Last Month'),
                  ),
                  const PopupMenuItem(
                    value: '3 months',
                    child: Text('Last 3 Months'),
                  ),
                  const PopupMenuItem(
                    value: '6 months',
                    child: Text('Last 6 Months'),
                  ),
                  const PopupMenuItem(
                    value: '1 year',
                    child: Text('Last Year'),
                  ),
                  const PopupMenuItem(value: 'all', child: Text('All Time')),
                ],
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportAnalytics,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.trending_up), text: 'Trends'),
            Tab(icon: Icon(Icons.pie_chart), text: 'Distribution'),
            Tab(icon: Icon(Icons.attach_money), text: 'Costs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildTrendsTab(),
          _buildDistributionTab(),
          _buildCostsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final filteredAssessments = _getFilteredAssessments();
    final totalAssessments = filteredAssessments.length;
    final totalCost = filteredAssessments.fold<double>(0.0, (sum, assessment) {
      final cost = assessment.results?['estimatedCost'] as double?;
      return sum + (cost ?? 0.0);
    });
    final avgCost = totalAssessments > 0 ? totalCost / totalAssessments : 0.0;

    final pendingCount =
        filteredAssessments
            .where((a) => a.status == AssessmentStatus.processing)
            .length;
    final completedCount =
        filteredAssessments
            .where((a) => a.status == AssessmentStatus.completed)
            .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key Metrics Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Assessments',
                  totalAssessments.toString(),
                  Icons.assessment,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Total Cost',
                  '\$${totalCost.toStringAsFixed(0)}',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Average Cost',
                  '\$${avgCost.toStringAsFixed(0)}',
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Completion Rate',
                  '${totalAssessments > 0 ? ((completedCount / totalAssessments) * 100).toStringAsFixed(1) : 0}%',
                  Icons.check_circle,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Activity
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Activity',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...filteredAssessments
                      .take(5)
                      .map((assessment) => _buildActivityItem(assessment)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Quick Status Overview
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status Overview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatusIndicator(
                        'Pending',
                        pendingCount,
                        Colors.orange,
                      ),
                      _buildStatusIndicator(
                        'Completed',
                        completedCount,
                        Colors.green,
                      ),
                      _buildStatusIndicator(
                        'In Review',
                        filteredAssessments
                            .where((a) => a.status == 'review')
                            .length,
                        Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    final filteredAssessments = _getFilteredAssessments();
    final monthlyData = _getMonthlyData(filteredAssessments);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Assessment Count Trend
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Assessment Count Trend',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: LineChart(_buildAssessmentTrendChart(monthlyData)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Cost Trend
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cost Trend',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: LineChart(_buildCostTrendChart(monthlyData)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Severity Trend
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Severity Distribution Over Time',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 250,
                    child: BarChart(_buildSeverityTrendChart(monthlyData)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionTab() {
    final filteredAssessments = _getFilteredAssessments();
    final damageTypeDistribution = _getDamageTypeDistribution(
      filteredAssessments,
    );
    final severityDistribution = _getSeverityDistribution(filteredAssessments);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Damage Type Distribution
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Damage Type Distribution',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      _buildDamageTypePieChart(damageTypeDistribution),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Severity Distribution
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Severity Distribution',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      _buildSeverityPieChart(severityDistribution),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Vehicle Make Distribution
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vehicle Make Distribution',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 250,
                    child: BarChart(
                      _buildVehicleMakeChart(filteredAssessments),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostsTab() {
    final filteredAssessments = _getFilteredAssessments();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cost by Damage Type
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Average Cost by Damage Type',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 250,
                    child: BarChart(
                      _buildCostByDamageTypeChart(filteredAssessments),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Cost by Severity
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Average Cost by Severity',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      _buildCostBySeverityChart(filteredAssessments),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Cost Range Distribution
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cost Range Distribution',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._buildCostRangeList(filteredAssessments),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Assessment assessment) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getStatusColor(assessment.status),
        child: const Icon(Icons.directions_car, color: Colors.white),
      ),
      title: Text(
        '${assessment.results?['vehicleInfo']?['make'] ?? 'Unknown'} ${assessment.results?['vehicleInfo']?['model'] ?? ''}',
      ),
      subtitle: Text(
        '${assessment.results?['damageAnalysis']?['type'] ?? 'Unknown damage'} - \$${assessment.results?['estimatedCost']?.toString() ?? '0'}',
      ),
      trailing: Text(
        assessment.timestamp.toString().split(' ')[0],
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }

  Widget _buildStatusIndicator(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  List<Assessment> _getFilteredAssessments() {
    final now = DateTime.now();
    DateTime cutoffDate;

    switch (_selectedTimeRange) {
      case '1 month':
        cutoffDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case '3 months':
        cutoffDate = DateTime(now.year, now.month - 3, now.day);
        break;
      case '6 months':
        cutoffDate = DateTime(now.year, now.month - 6, now.day);
        break;
      case '1 year':
        cutoffDate = DateTime(now.year - 1, now.month, now.day);
        break;
      default:
        return widget.assessments;
    }

    return widget.assessments.where((assessment) {
      return assessment.timestamp.isAfter(cutoffDate);
    }).toList();
  }

  Map<String, Map<String, dynamic>> _getMonthlyData(
    List<Assessment> assessments,
  ) {
    final monthlyData = <String, Map<String, dynamic>>{};

    for (final assessment in assessments) {
      final date = assessment.timestamp;
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';

      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = {
          'count': 0,
          'totalCost': 0.0,
          'severityCounts': <String, int>{},
        };
      }

      monthlyData[monthKey]!['count'] =
          (monthlyData[monthKey]!['count'] as int) + 1;

      final cost = assessment.results?['estimatedCost'] as double? ?? 0.0;
      monthlyData[monthKey]!['totalCost'] =
          (monthlyData[monthKey]!['totalCost'] as double) + cost;

      final severity =
          assessment.results?['damageAnalysis']?['severity'] as String? ??
          'Unknown';
      final severityCounts =
          monthlyData[monthKey]!['severityCounts'] as Map<String, int>;
      severityCounts[severity] = (severityCounts[severity] ?? 0) + 1;
    }

    return monthlyData;
  }

  Map<String, int> _getDamageTypeDistribution(List<Assessment> assessments) {
    final distribution = <String, int>{};

    for (final assessment in assessments) {
      final damageType =
          assessment.results?['damageAnalysis']?['type'] as String? ??
          'Unknown';
      distribution[damageType] = (distribution[damageType] ?? 0) + 1;
    }

    return distribution;
  }

  Map<String, int> _getSeverityDistribution(List<Assessment> assessments) {
    final distribution = <String, int>{};

    for (final assessment in assessments) {
      final severity =
          assessment.results?['damageAnalysis']?['severity'] as String? ??
          'Unknown';
      distribution[severity] = (distribution[severity] ?? 0) + 1;
    }

    return distribution;
  }

  Color _getStatusColor(AssessmentStatus status) {
    switch (status) {
      case AssessmentStatus.completed:
        return Colors.green;
      case AssessmentStatus.processing:
        return Colors.orange;
      case AssessmentStatus.failed:
        return Colors.red;
    }
  }

  LineChartData _buildAssessmentTrendChart(
    Map<String, Map<String, dynamic>> monthlyData,
  ) {
    final spots = <FlSpot>[];
    final sortedEntries =
        monthlyData.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    for (int i = 0; i < sortedEntries.length; i++) {
      final count = sortedEntries[i].value['count'] as int;
      spots.add(FlSpot(i.toDouble(), count.toDouble()));
    }

    return LineChartData(
      gridData: const FlGridData(show: true),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < sortedEntries.length) {
                final monthKey = sortedEntries[index].key;
                return Text(monthKey.substring(5)); // Show month only
              }
              return const Text('');
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: true),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.blue,
          barWidth: 3,
          belowBarData: BarAreaData(
            show: true,
            color: Colors.blue.withOpacity(0.3),
          ),
        ),
      ],
    );
  }

  LineChartData _buildCostTrendChart(
    Map<String, Map<String, dynamic>> monthlyData,
  ) {
    final spots = <FlSpot>[];
    final sortedEntries =
        monthlyData.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    for (int i = 0; i < sortedEntries.length; i++) {
      final totalCost = sortedEntries[i].value['totalCost'] as double;
      spots.add(FlSpot(i.toDouble(), totalCost));
    }

    return LineChartData(
      gridData: const FlGridData(show: true),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) => Text('\$${value.toInt()}'),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < sortedEntries.length) {
                final monthKey = sortedEntries[index].key;
                return Text(monthKey.substring(5));
              }
              return const Text('');
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: true),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.green,
          barWidth: 3,
          belowBarData: BarAreaData(
            show: true,
            color: Colors.green.withOpacity(0.3),
          ),
        ),
      ],
    );
  }

  BarChartData _buildSeverityTrendChart(
    Map<String, Map<String, dynamic>> monthlyData,
  ) {
    // Implementation for severity trend chart
    final sortedEntries =
        monthlyData.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: 20,
      barTouchData: BarTouchData(enabled: false),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < sortedEntries.length) {
                return Text(sortedEntries[index].key.substring(5));
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: [],
    );
  }

  PieChartData _buildDamageTypePieChart(Map<String, int> distribution) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];
    int colorIndex = 0;

    return PieChartData(
      sections:
          distribution.entries.map((entry) {
            final color = colors[colorIndex % colors.length];
            colorIndex++;

            return PieChartSectionData(
              color: color,
              value: entry.value.toDouble(),
              title: '${entry.key}\n${entry.value}',
              radius: 80,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
    );
  }

  PieChartData _buildSeverityPieChart(Map<String, int> distribution) {
    final severityColors = {
      'Low': Colors.green,
      'Medium': Colors.orange,
      'High': Colors.red,
      'Critical': Colors.purple,
    };

    return PieChartData(
      sections:
          distribution.entries.map((entry) {
            final color = severityColors[entry.key] ?? Colors.grey;

            return PieChartSectionData(
              color: color,
              value: entry.value.toDouble(),
              title: '${entry.key}\n${entry.value}',
              radius: 80,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
    );
  }

  BarChartData _buildVehicleMakeChart(List<Assessment> assessments) {
    final makeDistribution = <String, int>{};

    for (final assessment in assessments) {
      final make =
          assessment.results?['vehicleInfo']?['make'] as String? ?? 'Unknown';
      makeDistribution[make] = (makeDistribution[make] ?? 0) + 1;
    }

    final sortedEntries =
        makeDistribution.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value))
          ..take(10);

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY:
          sortedEntries.isNotEmpty
              ? sortedEntries.first.value.toDouble() + 2
              : 10,
      barTouchData: BarTouchData(enabled: false),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < sortedEntries.length) {
                return RotatedBox(
                  quarterTurns: 1,
                  child: Text(
                    sortedEntries[index].key,
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups:
          sortedEntries.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value.toDouble(),
                  color: Colors.blue,
                  width: 20,
                ),
              ],
            );
          }).toList(),
    );
  }

  BarChartData _buildCostByDamageTypeChart(List<Assessment> assessments) {
    final damageTypeCosts = <String, List<double>>{};

    for (final assessment in assessments) {
      final damageType =
          assessment.results?['damageAnalysis']?['type'] as String? ??
          'Unknown';
      final cost = assessment.results?['estimatedCost'] as double? ?? 0.0;
      damageTypeCosts.putIfAbsent(damageType, () => []).add(cost);
    }

    final avgCosts = damageTypeCosts.map((key, value) {
      final avg =
          value.isNotEmpty ? value.reduce((a, b) => a + b) / value.length : 0.0;
      return MapEntry(key, avg);
    });

    final sortedEntries =
        avgCosts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: sortedEntries.isNotEmpty ? sortedEntries.first.value + 500 : 1000,
      barTouchData: BarTouchData(enabled: false),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < sortedEntries.length) {
                return RotatedBox(
                  quarterTurns: 1,
                  child: Text(
                    sortedEntries[index].key,
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) => Text('\$${value.toInt()}'),
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups:
          sortedEntries.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value,
                  color: Colors.green,
                  width: 20,
                ),
              ],
            );
          }).toList(),
    );
  }

  BarChartData _buildCostBySeverityChart(List<Assessment> assessments) {
    final severityCosts = <String, List<double>>{};

    for (final assessment in assessments) {
      final severity =
          assessment.results?['damageAnalysis']?['severity'] as String? ??
          'Unknown';
      final cost = assessment.results?['estimatedCost'] as double? ?? 0.0;
      severityCosts.putIfAbsent(severity, () => []).add(cost);
    }

    final avgCosts = severityCosts.map((key, value) {
      final avg =
          value.isNotEmpty ? value.reduce((a, b) => a + b) / value.length : 0.0;
      return MapEntry(key, avg);
    });

    final severityOrder = ['Low', 'Medium', 'High', 'Critical'];
    final orderedEntries =
        severityOrder
            .where((severity) => avgCosts.containsKey(severity))
            .map((severity) => MapEntry(severity, avgCosts[severity]!))
            .toList();

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY:
          orderedEntries.isNotEmpty
              ? orderedEntries
                      .map((e) => e.value)
                      .reduce((a, b) => a > b ? a : b) +
                  500
              : 1000,
      barTouchData: BarTouchData(enabled: false),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < orderedEntries.length) {
                return Text(orderedEntries[index].key);
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) => Text('\$${value.toInt()}'),
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups:
          orderedEntries.asMap().entries.map((entry) {
            final severityColors = {
              'Low': Colors.green,
              'Medium': Colors.orange,
              'High': Colors.red,
              'Critical': Colors.purple,
            };

            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value,
                  color: severityColors[entry.value.key] ?? Colors.blue,
                  width: 30,
                ),
              ],
            );
          }).toList(),
    );
  }

  List<Widget> _buildCostRangeList(List<Assessment> assessments) {
    final costRanges = {
      'Under \$500': 0,
      '\$500 - \$1,000': 0,
      '\$1,000 - \$2,500': 0,
      '\$2,500 - \$5,000': 0,
      '\$5,000 - \$10,000': 0,
      'Over \$10,000': 0,
    };

    for (final assessment in assessments) {
      final cost = assessment.results?['estimatedCost'] as double? ?? 0.0;

      if (cost < 500) {
        costRanges['Under \$500'] = costRanges['Under \$500']! + 1;
      } else if (cost < 1000) {
        costRanges['\$500 - \$1,000'] = costRanges['\$500 - \$1,000']! + 1;
      } else if (cost < 2500) {
        costRanges['\$1,000 - \$2,500'] = costRanges['\$1,000 - \$2,500']! + 1;
      } else if (cost < 5000) {
        costRanges['\$2,500 - \$5,000'] = costRanges['\$2,500 - \$5,000']! + 1;
      } else if (cost < 10000) {
        costRanges['\$5,000 - \$10,000'] =
            costRanges['\$5,000 - \$10,000']! + 1;
      } else {
        costRanges['Over \$10,000'] = costRanges['Over \$10,000']! + 1;
      }
    }

    return costRanges.entries.map((entry) {
      final percentage =
          assessments.isNotEmpty
              ? (entry.value / assessments.length) * 100
              : 0.0;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                entry.key,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text('${entry.value} (${percentage.toStringAsFixed(1)}%)'),
            ),
            Expanded(
              flex: 2,
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Future<void> _exportAnalytics() async {
    try {
      final assessmentData =
          widget.assessments
              .map(
                (assessment) => {
                  'id': assessment.id,
                  'date': assessment.timestamp.toIso8601String(),
                  'vehicleInfo': assessment.results?['vehicleInfo'] ?? {},
                  'damageAnalysis': assessment.results?['damageAnalysis'] ?? {},
                  'estimatedCost': assessment.results?['estimatedCost'] ?? 0.0,
                  'status': assessment.status.name,
                  'metadata': assessment.results?['metadata'] ?? {},
                  'images': assessment.results?['images'] ?? [],
                  'notes': assessment.results?['notes'] ?? '',
                  'createdAt': assessment.timestamp.toIso8601String(),
                  'updatedAt': assessment.timestamp.toIso8601String(),
                },
              )
              .toList();

      final filePath = await ExportService.exportToExcel(
        assessments: assessmentData,
        fileName:
            'analytics_dashboard_${DateTime.now().millisecondsSinceEpoch}',
        includeCharts: true,
        includeImages: false,
      );

      if (filePath != null) {
        await ExportService.shareExportedFile(
          filePath,
          title: 'InsureVis Analytics Dashboard Export',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Analytics exported successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to export analytics'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
