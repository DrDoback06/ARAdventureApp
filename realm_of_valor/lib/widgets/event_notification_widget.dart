import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../constants/theme.dart';
import '../services/dynamic_event_service.dart';

class EventNotificationWidget extends StatelessWidget {
  final DynamicEvent event;
  final VoidCallback? onJoin;

  const EventNotificationWidget({
    super.key,
    required this.event,
    this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: RealmOfValorTheme.textSecondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildEventInfo(),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getEventColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getEventIcon(),
                color: _getEventColor(),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: RealmOfValorTheme.textPrimary,
                    ),
                  ),
                  Text(
                    event.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: RealmOfValorTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getEventColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            event.type.name.toUpperCase(),
            style: TextStyle(
              color: _getEventColor(),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Event Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: RealmOfValorTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        _buildInfoRow('Type', event.type.name.toUpperCase()),
        _buildInfoRow('Duration', '${event.endTime.difference(event.startTime).inMinutes} minutes'),
        _buildInfoRow('Rewards', '${event.rewardXP} XP, ${event.rewardGold} Gold'),
        _buildInfoRow('Participants', '${event.currentParticipants}/${event.maxParticipants}'),
        _buildInfoRow('Status', event.isActive ? 'ACTIVE' : 'INACTIVE'),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (onJoin != null && event.isActive)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onJoin,
              icon: const Icon(Icons.group),
              label: const Text('Join Event'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getEventColor(),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        if (!event.isActive)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Event Not Active',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: RealmOfValorTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Color _getEventColor() {
    switch (event.type) {
      case EventType.time:
        return Colors.yellow;
      case EventType.weather:
        return Colors.cyan;
      case EventType.special:
        return Colors.purple;
      case EventType.community:
        return Colors.green;
    }
  }

  IconData _getEventIcon() {
    switch (event.type) {
      case EventType.time:
        return Icons.access_time;
      case EventType.weather:
        return Icons.wb_sunny;
      case EventType.special:
        return Icons.star;
      case EventType.community:
        return Icons.people;
    }
  }
} 