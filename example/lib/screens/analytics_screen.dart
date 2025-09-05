import 'package:flutter/material.dart';
import 'package:flux/flux.dart';
import '../services/analytics_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key, required this.runtime});

  final FluxRuntime runtime;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, dynamic>? _analyticsSummary;
  Map<String, dynamic>? _detailedReport;
  bool _isLoadingSummary = true;
  bool _isGeneratingReport = false;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoadingSummary = true;
    });

    try {
      // 🔄 SERVICE PROXY SYSTEM: Call analytics service in worker isolate
      final analyticsService = widget.runtime.get<AnalyticsService>();
      final summary = await analyticsService.getAnalyticsSummary();

      setState(() {
        _analyticsSummary = summary;
        _isLoadingSummary = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSummary = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading analytics: $e')));
      }
    }
  }

  Future<void> _generateDetailedReport() async {
    setState(() {
      _isGeneratingReport = true;
    });

    try {
      // 🔄 SERVICE PROXY SYSTEM: Heavy computation in worker isolate
      final analyticsService = widget.runtime.get<AnalyticsService>();
      final report = await analyticsService.generateReport();

      setState(() {
        _detailedReport = report;
        _isGeneratingReport = false;
      });
    } catch (e) {
      setState(() {
        _isGeneratingReport = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating report: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingSummary) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary cards
          if (_analyticsSummary != null) ...[
            _buildSummarySection(),
            const SizedBox(height: 16),
          ],

          // Detailed report section
          _buildReportSection(),
          const SizedBox(height: 16),

          // Framework showcase
          _buildFrameworkShowcase(),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    final summary = _analyticsSummary!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics Summary',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Events',
                summary['totalEvents'].toString(),
                Icons.event,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                'Last 24h',
                summary['eventsLast24h'].toString(),
                Icons.today,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                'Last 7d',
                summary['eventsLast7d'].toString(),
                Icons.date_range,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Top actions
        if (summary['topActions'] != null &&
            (summary['topActions'] as Map).isNotEmpty) ...[
          Text('Top Actions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: (summary['topActions'] as Map<String, dynamic>)
                    .entries
                    .map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(child: Text(entry.key)),
                            Chip(
                              label: Text(entry.value.toString()),
                              backgroundColor: Colors.blue.withOpacity(0.1),
                            ),
                          ],
                        ),
                      );
                    })
                    .toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Detailed Report',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _isGeneratingReport ? null : _generateDetailedReport,
              icon: _isGeneratingReport
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                _isGeneratingReport ? 'Generating...' : 'Generate Report',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_isGeneratingReport)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Generating detailed analytics report...'),
                  const SizedBox(height: 8),
                  Text(
                    'Heavy computation running in worker isolate',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
        else if (_detailedReport != null)
          _buildDetailedReport()
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(
                    Icons.analytics_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  const Text('No detailed report generated yet'),
                  const SizedBox(height: 8),
                  Text(
                    'Generate a report to see advanced analytics',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDetailedReport() {
    final report = _detailedReport!;
    final summary = report['summary'] as Map<String, dynamic>;
    final trends = report['trends'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report Summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildReportMetric(
              'Total Events',
              summary['totalEvents'].toString(),
            ),
            _buildReportMetric('Task Events', summary['taskEvents'].toString()),
            _buildReportMetric(
              'Task Creations',
              summary['taskCreations'].toString(),
            ),
            _buildReportMetric(
              'Task Completions',
              summary['taskCompletions'].toString(),
            ),
            _buildReportMetric(
              'Completion Rate',
              '${summary['completionRate']}%',
            ),
            const SizedBox(height: 16),
            Text('Trends', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildReportMetric(
              'Daily Average',
              '${trends['dailyAverageEvents']} events',
            ),
            _buildReportMetric('Peak Day', trends['peakDay']),
            if (trends['mostActiveUsers'] != null &&
                (trends['mostActiveUsers'] as List).isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Most Active Users:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              ...(trends['mostActiveUsers'] as List).map(
                (user) => Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Text('• $user'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReportMetric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildFrameworkShowcase() {
    return Card(
      color: Colors.green.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.architecture, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Real-Time Flux Demonstration',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('This analytics tab shows Flux in action:'),
            const SizedBox(height: 8),
            _buildShowcasePoint(
              '📊',
              'AnalyticsService processes events in worker isolate',
            ),
            _buildShowcasePoint(
              '🔄',
              'Heavy report generation doesn\'t block UI',
            ),
            _buildShowcasePoint(
              '📡',
              'Events flow automatically from TaskService',
            ),
            _buildShowcasePoint(
              '🚀',
              'Zero configuration - everything just works!',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShowcasePoint(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: Colors.indigo),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
