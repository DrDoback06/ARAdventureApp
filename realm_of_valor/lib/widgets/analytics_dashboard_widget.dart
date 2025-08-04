import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/analytics_service.dart';
import '../constants/theme.dart';

class AnalyticsDashboardWidget extends StatelessWidget {
  final bool showCompact;
  
  const AnalyticsDashboardWidget({
    super.key,
    this.showCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsService>(
      builder: (context, analyticsService, child) {
        final summary = analyticsService.getAnalyticsSummary();
        
        if (showCompact) {
          return _buildCompactView(context, summary);
        } else {
          return _buildFullView(context, analyticsService, summary);
        }
      },
    );
  }

  Widget _buildCompactView(BuildContext context, Map<String, dynamic> summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.analytics,
                  color: RealmOfValorTheme.accentGold,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Analytics',
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
                    color: RealmOfValorTheme.manaBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${summary['eventsLast24Hours']}',
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
                    'Sessions',
                    '${summary['sessionsLast7Days']}',
                    Icons.timeline,
                    RealmOfValorTheme.experienceGreen,
                  ),
                ),
                Expanded(
                  child: _buildCompactMetric(
                    'Avg Time',
                    '${(summary['averageSessionDuration'] as Duration).inMinutes}m',
                    Icons.access_time,
                    RealmOfValorTheme.manaBlue,
                  ),
                ),
                Expanded(
                  child: _buildCompactMetric(
                    'Engagement',
                    '${(summary['userEngagement']['retentionRate'] as double).round()}%',
                    Icons.trending_up,
                    RealmOfValorTheme.accentGold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullView(BuildContext context, AnalyticsService analyticsService, Map<String, dynamic> summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.analytics,
                  color: RealmOfValorTheme.accentGold,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analytics Dashboard',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: RealmOfValorTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Game performance and user insights',
                        style: TextStyle(
                          fontSize: 12,
                          color: RealmOfValorTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showDetailedAnalytics(context, analyticsService),
                  icon: const Icon(Icons.analytics, color: RealmOfValorTheme.accentGold),
                  tooltip: 'Detailed Analytics',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Key metrics
            _buildKeyMetrics(summary),
            const SizedBox(height: 16),
            
            // User engagement
            _buildEngagementSection(summary['userEngagement']),
            const SizedBox(height: 16),
            
            // Top events
            _buildTopEventsSection(summary['topEvents']),
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

  Widget _buildKeyMetrics(Map<String, dynamic> summary) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key Metrics (Last 24 Hours)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Events',
                  '${summary['eventsLast24Hours']}',
                  Icons.event,
                  RealmOfValorTheme.experienceGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Sessions',
                  '${summary['sessionsLast7Days']}',
                  Icons.timeline,
                  RealmOfValorTheme.manaBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Avg Session',
                  '${(summary['averageSessionDuration'] as Duration).inMinutes}m',
                  Icons.access_time,
                  RealmOfValorTheme.accentGold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Issues',
                  '${summary['performanceIssues']}',
                  Icons.warning,
                  RealmOfValorTheme.healthRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementSection(Map<String, dynamic> engagement) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Engagement',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildEngagementRow('Sessions (7 days)', '${engagement['sessionsLast7Days']}'),
          _buildEngagementRow('Sessions (30 days)', '${engagement['sessionsLast30Days']}'),
          _buildEngagementRow('Avg Sessions/Day', '${(engagement['averageSessionsPerDay'] as double).toStringAsFixed(1)}'),
          _buildEngagementRow('Retention Rate', '${(engagement['retentionRate'] as double).round()}%'),
        ],
      ),
    );
  }

  Widget _buildEngagementRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopEventsSection(List<dynamic> topEvents) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Events',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...topEvents.map((event) => _buildEventRow(
            event['event'] as String,
            event['count'] as int,
          )),
        ],
      ),
    );
  }

  Widget _buildEventRow(String eventName, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _formatEventName(eventName),
              style: const TextStyle(
                fontSize: 12,
                color: RealmOfValorTheme.textSecondary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: RealmOfValorTheme.accentGold,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatEventName(String eventName) {
    return eventName
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }

  void _showDetailedAnalytics(BuildContext context, AnalyticsService analyticsService) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Detailed Analytics',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: RealmOfValorTheme.accentGold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildDetailedSection('User Segment', _getUserSegmentInfo(analyticsService)),
                      const SizedBox(height: 16),
                      _buildDetailedSection('Performance Metrics', _getPerformanceInfo(analyticsService)),
                      const SizedBox(height: 16),
                      _buildDetailedSection('Event Timeline', _getEventTimeline(analyticsService)),
                      const SizedBox(height: 16),
                      _buildDetailedSection('Session Analysis', _getSessionAnalysis(analyticsService)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  List<Widget> _getUserSegmentInfo(AnalyticsService analyticsService) {
    final segment = analyticsService.getUserSegment();
    final segmentInfo = {
      UserSegment.newUser: {'name': 'New User', 'color': RealmOfValorTheme.experienceGreen},
      UserSegment.casualPlayer: {'name': 'Casual Player', 'color': RealmOfValorTheme.manaBlue},
      UserSegment.activePlayer: {'name': 'Active Player', 'color': RealmOfValorTheme.accentGold},
      UserSegment.hardcorePlayer: {'name': 'Hardcore Player', 'color': RealmOfValorTheme.healthRed},
    };
    
    final info = segmentInfo[segment]!;
    
    return [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: info['color'] as Color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          info['name'] as String,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ];
  }

  List<Widget> _getPerformanceInfo(AnalyticsService analyticsService) {
    return [
      const Text('Performance metrics will be displayed here'),
    ];
  }

  List<Widget> _getEventTimeline(AnalyticsService analyticsService) {
    final recentEvents = analyticsService.events.take(10).toList();
    
    return recentEvents.map((event) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            _getEventIcon(event.type),
            size: 16,
            color: RealmOfValorTheme.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              event.name,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Text(
            _formatTimeAgo(event.timestamp),
            style: const TextStyle(
              fontSize: 10,
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
        ],
      ),
    )).toList();
  }

  List<Widget> _getSessionAnalysis(AnalyticsService analyticsService) {
    final sessions = analyticsService.sessions.take(5).toList();
    
    return sessions.map((session) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.timeline, size: 16, color: RealmOfValorTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Session ${session.id.substring(0, 8)}...',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Text(
            '${session.duration.inMinutes}m',
            style: const TextStyle(
              fontSize: 10,
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
        ],
      ),
    )).toList();
  }

  IconData _getEventIcon(EventType type) {
    switch (type) {
      case EventType.appLaunch:
        return Icons.play_arrow;
      case EventType.buttonClick:
        return Icons.touch_app;
      case EventType.battleStart:
        return Icons.sports_kabaddi;
      case EventType.questComplete:
        return Icons.task_alt;
      case EventType.achievementUnlocked:
        return Icons.emoji_events;
      case EventType.levelUp:
        return Icons.trending_up;
      default:
        return Icons.event;
    }
  }

  String _formatTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
} 