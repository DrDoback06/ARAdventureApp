import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../providers/activity_provider.dart';
import '../models/activity_model.dart';

class ActivityTrackingWidget extends StatefulWidget {
  const ActivityTrackingWidget({super.key});

  @override
  State<ActivityTrackingWidget> createState() => _ActivityTrackingWidgetState();
}

class _ActivityTrackingWidgetState extends State<ActivityTrackingWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityProvider>(
      builder: (context, activityProvider, child) {
        final currentActivity = activityProvider.currentActivity;
        final isTracking = activityProvider.isTracking;
        final currentStatus = activityProvider.currentStatus;
        final connectedDevice = activityProvider.connectedDevice;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: RealmOfValorTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: RealmOfValorTheme.primaryLight,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.fitness_center,
                    color: RealmOfValorTheme.accentGold,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Activity Tracking',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: RealmOfValorTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  _buildStatusIndicator(isTracking, currentStatus),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Device Status
              _buildDeviceStatus(connectedDevice),
              
              const SizedBox(height: 16),
              
              // Current Activity (if tracking)
              if (isTracking && currentActivity != null)
                _buildCurrentActivity(currentActivity!),
              
              const SizedBox(height: 16),
              
              // Quick Actions
              _buildQuickActions(activityProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(bool isTracking, String status) {
    Color statusColor;
    IconData statusIcon;
    
    if (isTracking) {
      statusColor = Colors.green;
      statusIcon = Icons.play_circle_filled;
    } else {
      statusColor = RealmOfValorTheme.textSecondary;
      statusIcon = Icons.pause_circle_filled;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceStatus(String? connectedDevice) {
    return Row(
      children: [
        Icon(
          connectedDevice != null ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
          color: connectedDevice != null ? Colors.green : RealmOfValorTheme.textSecondary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            connectedDevice ?? 'No device connected',
            style: TextStyle(
              color: connectedDevice != null ? Colors.green : RealmOfValorTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentActivity(ActivityData activity) {
    final duration = activity.duration;
    final distanceKm = (activity.distance / 1000.0).toStringAsFixed(1);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RealmOfValorTheme.accentGold),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getActivityIcon(activity.type),
                color: RealmOfValorTheme.accentGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                activity.type.name.toUpperCase(),
                style: const TextStyle(
                  color: RealmOfValorTheme.accentGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildActivityStat('Distance', '$distanceKm km', Icons.directions_walk),
              ),
              Expanded(
                child: _buildActivityStat('Calories', '${activity.calories}', Icons.local_fire_department),
              ),
              Expanded(
                child: _buildActivityStat('Duration', _formatDuration(duration), Icons.timer),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: RealmOfValorTheme.textSecondary,
          size: 16,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: RealmOfValorTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: RealmOfValorTheme.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(ActivityProvider activityProvider) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showActivityTypeDialog(activityProvider),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start'),
            style: ElevatedButton.styleFrom(
              backgroundColor: RealmOfValorTheme.accentGold,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: activityProvider.isTracking ? () => activityProvider.stopTracking() : null,
            icon: const Icon(Icons.stop),
            label: const Text('Stop'),
            style: ElevatedButton.styleFrom(
              backgroundColor: RealmOfValorTheme.surfaceDark,
              foregroundColor: RealmOfValorTheme.accentGold,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.running:
        return Icons.directions_run;
      case ActivityType.walking:
        return Icons.directions_walk;
      case ActivityType.cycling:
        return Icons.directions_bike;
      case ActivityType.gym:
        return Icons.fitness_center;
      case ActivityType.adventure:
        return Icons.explore;
      case ActivityType.yoga:
        return Icons.self_improvement;
      case ActivityType.swimming:
        return Icons.pool;
      case ActivityType.hiking:
        return Icons.terrain;
      case ActivityType.other:
        return Icons.sports;
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  void _showActivityTypeDialog(ActivityProvider activityProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RealmOfValorTheme.surfaceDark,
        title: const Text(
          'Start Activity',
          style: TextStyle(color: RealmOfValorTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ActivityType.values.map((type) {
            return ListTile(
              leading: Icon(
                _getActivityIcon(type),
                color: RealmOfValorTheme.accentGold,
              ),
              title: Text(
                type.name.toUpperCase(),
                style: const TextStyle(color: RealmOfValorTheme.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                activityProvider.startTracking(type);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
} 