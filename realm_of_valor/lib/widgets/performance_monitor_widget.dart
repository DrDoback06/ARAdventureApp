import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/performance_service.dart';
import '../constants/theme.dart';

class PerformanceMonitorWidget extends StatelessWidget {
  final bool showCompact;
  
  const PerformanceMonitorWidget({
    super.key,
    this.showCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PerformanceService>(
      builder: (context, performanceService, child) {
        final stats = performanceService.getPerformanceStats();
        
        if (showCompact) {
          return _buildCompactView(context, stats);
        } else {
          return _buildFullView(context, stats);
        }
      },
    );
  }

  Widget _buildCompactView(BuildContext context, Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getPerformanceIcon(stats['performanceStatus']),
                  color: _getPerformanceColor(stats['performanceStatus']),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Performance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: RealmOfValorTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPerformanceColor(stats['performanceStatus']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    stats['performanceStatus'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildCompactMetric(
                    'FPS',
                    '${stats['averageFps'].round()}',
                    Icons.speed,
                    RealmOfValorTheme.accentGold,
                  ),
                ),
                Expanded(
                  child: _buildCompactMetric(
                    'Memory',
                    '${(stats['averageMemoryUsage'] / (1024 * 1024)).round()}MB',
                    Icons.memory,
                    RealmOfValorTheme.manaBlue,
                  ),
                ),
                Expanded(
                  child: _buildCompactMetric(
                    'CPU',
                    '${stats['averageCpuUsage'].round()}%',
                    Icons.memory,
                    RealmOfValorTheme.experienceGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullView(BuildContext context, Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getPerformanceIcon(stats['performanceStatus']),
                  color: _getPerformanceColor(stats['performanceStatus']),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Performance Monitor',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: RealmOfValorTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Real-time performance metrics',
                        style: TextStyle(
                          fontSize: 12,
                          color: RealmOfValorTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showDetailedStats(context, stats),
                  icon: const Icon(Icons.analytics, color: RealmOfValorTheme.accentGold),
                  tooltip: 'Detailed Statistics',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Performance status
            _buildPerformanceStatus(stats),
            const SizedBox(height: 16),
            
            // Metrics grid
            _buildMetricsGrid(stats),
            const SizedBox(height: 16),
            
            // Recommendations
            if (stats['recommendations'] != null && (stats['recommendations'] as List).isNotEmpty)
              _buildRecommendations(stats['recommendations']),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: RealmOfValorTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceStatus(Map<String, dynamic> stats) {
    final status = stats['performanceStatus'] as String;
    final color = _getPerformanceColor(status);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _getPerformanceIcon(status),
            color: color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status: $status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  _getPerformanceDescription(status),
                  style: const TextStyle(
                    fontSize: 12,
                    color: RealmOfValorTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(Map<String, dynamic> stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: [
        _buildMetricCard(
          'Frame Rate',
          '${stats['averageFps'].round()} FPS',
          Icons.speed,
          RealmOfValorTheme.accentGold,
          stats['averageFps'] >= 60 ? 'Good' : 'Needs Improvement',
        ),
        _buildMetricCard(
          'Memory Usage',
          '${(stats['averageMemoryUsage'] / (1024 * 1024)).round()} MB',
          Icons.memory,
          RealmOfValorTheme.manaBlue,
          stats['averageMemoryUsage'] < 100 * 1024 * 1024 ? 'Good' : 'High',
        ),
        _buildMetricCard(
          'CPU Usage',
          '${stats['averageCpuUsage'].round()}%',
          Icons.memory,
          RealmOfValorTheme.experienceGreen,
          stats['averageCpuUsage'] < 50 ? 'Good' : 'High',
        ),
        _buildMetricCard(
          'Active Widgets',
          '${stats['activeWidgets']}',
          Icons.widgets,
          RealmOfValorTheme.healthRed,
          stats['activeWidgets'] < 100 ? 'Good' : 'Many',
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String status) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: RealmOfValorTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            status,
            style: const TextStyle(
              fontSize: 10,
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(List<String> recommendations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Optimization Recommendations',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: RealmOfValorTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...recommendations.map((recommendation) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: RealmOfValorTheme.accentGold,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  recommendation,
                  style: const TextStyle(
                    fontSize: 12,
                    color: RealmOfValorTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  IconData _getPerformanceIcon(String status) {
    switch (status.toLowerCase()) {
      case 'excellent':
        return Icons.speed;
      case 'good':
        return Icons.check_circle;
      case 'needs optimization':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  Color _getPerformanceColor(String status) {
    switch (status.toLowerCase()) {
      case 'excellent':
        return RealmOfValorTheme.experienceGreen;
      case 'good':
        return RealmOfValorTheme.accentGold;
      case 'needs optimization':
        return Colors.orange;
      default:
        return RealmOfValorTheme.textSecondary;
    }
  }

  String _getPerformanceDescription(String status) {
    switch (status.toLowerCase()) {
      case 'excellent':
        return 'App is running smoothly with optimal performance';
      case 'good':
        return 'Performance is acceptable with minor optimizations possible';
      case 'needs optimization':
        return 'Consider applying performance optimizations';
      default:
        return 'Performance status unknown';
    }
  }

  void _showDetailedStats(BuildContext context, Map<String, dynamic> stats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detailed Performance Statistics'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailedStatRow('Average FPS', '${stats['averageFps'].round()}'),
              _buildDetailedStatRow('Average Memory', '${(stats['averageMemoryUsage'] / (1024 * 1024)).round()} MB'),
              _buildDetailedStatRow('Average CPU', '${stats['averageCpuUsage'].round()}%'),
              _buildDetailedStatRow('Active Widgets', '${stats['activeWidgets']}'),
              _buildDetailedStatRow('Cache Size', '${(stats['cacheSize'] / (1024 * 1024)).round()} MB'),
              _buildDetailedStatRow('Network Requests', '${stats['networkRequests']}'),
              _buildDetailedStatRow('Metrics Collected', '${stats['metricsCount']}'),
              const Divider(),
              const Text(
                'Performance Recommendations:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...(stats['recommendations'] as List<String>).map((rec) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $rec', style: const TextStyle(fontSize: 12)),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
} 