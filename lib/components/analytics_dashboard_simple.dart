import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/assessment_model.dart';

class AnalyticsDashboard extends StatefulWidget {
  final List<Assessment> assessments;
  final VoidCallback? onExportData;
  final VoidCallback? onGenerateReport;

  const AnalyticsDashboard({
    super.key,
    required this.assessments,
    this.onExportData,
    this.onGenerateReport,
  });

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
                ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
          if (widget.onExportData != null)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: widget.onExportData,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Trends', icon: Icon(Icons.trending_up)),
            Tab(text: 'Insights', icon: Icon(Icons.lightbulb)),
            Tab(text: 'Export', icon: Icon(Icons.file_download)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildTrendsTab(),
          _buildInsightsTab(),
          _buildExportTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final completedAssessments =
        widget.assessments
            .where((a) => a.status == AssessmentStatus.completed)
            .toList();

    final processingCount =
        widget.assessments
            .where((a) => a.status == AssessmentStatus.processing)
            .length;

    final failedCount =
        widget.assessments
            .where((a) => a.status == AssessmentStatus.failed)
            .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKPICards(completedAssessments, processingCount, failedCount),
          const SizedBox(height: 24),
          _buildStatusChart(),
          const SizedBox(height: 24),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildKPICards(
    List<Assessment> completed,
    int processing,
    int failed,
  ) {
    final totalAssessments = widget.assessments.length;
    final successRate =
        totalAssessments > 0
            ? (completed.length / totalAssessments * 100).toStringAsFixed(1)
            : '0.0';

    return Row(
      children: [
        Expanded(
          child: _buildKPICard(
            'Total Assessments',
            totalAssessments.toString(),
            Icons.assessment,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKPICard(
            'Completed',
            completed.length.toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKPICard(
            'Success Rate',
            '$successRate%',
            Icons.trending_up,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKPICard(
            'Processing',
            processing.toString(),
            Icons.hourglass_empty,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildStatusChart() {
    final completed =
        widget.assessments
            .where((a) => a.status == AssessmentStatus.completed)
            .length;
    final processing =
        widget.assessments
            .where((a) => a.status == AssessmentStatus.processing)
            .length;
    final failed =
        widget.assessments
            .where((a) => a.status == AssessmentStatus.failed)
            .length;

    if (widget.assessments.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(child: Text('No assessments to display')),
      );
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assessment Status Distribution',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: completed.toDouble(),
                    title: 'Completed\n$completed',
                    color: Colors.green,
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: processing.toDouble(),
                    title: 'Processing\n$processing',
                    color: Colors.orange,
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: failed.toDouble(),
                    title: 'Failed\n$failed',
                    color: Colors.red,
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final recentAssessments = widget.assessments.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (recentAssessments.isEmpty)
            const Center(child: Text('No recent activity'))
          else
            ...recentAssessments.map(
              (assessment) => _buildActivityItem(assessment),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Assessment assessment) {
    IconData icon;
    Color color;

    switch (assessment.status) {
      case AssessmentStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case AssessmentStatus.processing:
        icon = Icons.hourglass_empty;
        color = Colors.orange;
        break;
      case AssessmentStatus.failed:
        icon = Icons.error;
        color = Colors.red;
        break;
    }

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text('Assessment ${assessment.id}'),
      subtitle: Text('${assessment.timestamp.toString().split('.')[0]}'),
      trailing: Chip(
        label: Text(
          assessment.status.name.toUpperCase(),
          style: const TextStyle(fontSize: 10),
        ),
        backgroundColor: color.withValues(alpha: 0.1),
        labelStyle: TextStyle(color: color),
      ),
    );
  }

  Widget _buildTrendsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Trends Analysis',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Coming soon - detailed trend analysis and predictions',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lightbulb, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'AI Insights',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Coming soon - AI-powered insights and recommendations',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildExportTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Export Options',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildExportCard(
            'Export to CSV',
            'Download assessment data as CSV file',
            Icons.table_chart,
            Colors.green,
            () => widget.onExportData?.call(),
          ),
          const SizedBox(height: 16),
          _buildExportCard(
            'Export to Excel',
            'Download detailed Excel report with analytics',
            Icons.description,
            Colors.blue,
            () => widget.onExportData?.call(),
          ),
          const SizedBox(height: 16),
          _buildExportCard(
            'Generate PDF Report',
            'Create comprehensive PDF report',
            Icons.picture_as_pdf,
            Colors.red,
            () => widget.onGenerateReport?.call(),
          ),
        ],
      ),
    );
  }

  Widget _buildExportCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return Card(
      elevation: 4,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
