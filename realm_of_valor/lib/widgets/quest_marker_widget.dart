import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../constants/theme.dart';
import '../services/quest_generator_service.dart';

class QuestMarkerWidget extends StatelessWidget {
  final AdventureQuest quest;
  final VoidCallback? onTap;
  final bool isActive;

  const QuestMarkerWidget({
    super.key,
    required this.quest,
    this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: _getQuestColor().withOpacity(0.9),
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? RealmOfValorTheme.accentGold : Colors.white,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          _getQuestIcon(),
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Color _getQuestColor() {
    switch (quest.type) {
      case QuestType.exploration:
        return Colors.blue;
      case QuestType.social:
        return Colors.green;
      case QuestType.fitness:
        return Colors.orange;
      case QuestType.collection:
        return Colors.purple;
      case QuestType.battle:
        return Colors.red;
      case QuestType.walking:
        return Colors.cyan;
      case QuestType.running:
        return Colors.blue;
      case QuestType.climbing:
        return Colors.brown;
      case QuestType.location:
        return Colors.yellow;
      case QuestType.time:
        return Colors.indigo;
      case QuestType.weather:
        return Colors.lightBlue;
    }
  }

  IconData _getQuestIcon() {
    switch (quest.type) {
      case QuestType.exploration:
        return Icons.explore;
      case QuestType.social:
        return Icons.people;
      case QuestType.fitness:
        return Icons.fitness_center;
      case QuestType.collection:
        return Icons.collections;
      case QuestType.battle:
        return Icons.sports_martial_arts;
      case QuestType.walking:
        return Icons.directions_walk;
      case QuestType.running:
        return Icons.directions_run;
      case QuestType.climbing:
        return Icons.terrain;
      case QuestType.location:
        return Icons.location_on;
      case QuestType.time:
        return Icons.access_time;
      case QuestType.weather:
        return Icons.cloud;
    }
  }
} 