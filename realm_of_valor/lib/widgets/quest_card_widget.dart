import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../models/adventure_map_model.dart';
import '../models/quest_model.dart';

class QuestCardWidget extends StatelessWidget {
  final AdventureQuest quest;
  final VoidCallback? onTap;
  final VoidCallback? onStart;
  final bool isFeatured;

  const QuestCardWidget({
    super.key,
    required this.quest,
    this.onTap,
    this.onStart,
    this.isFeatured = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getQuestBorderColor().withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getQuestIcon(),
                      color: _getQuestBorderColor(),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quest.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: RealmOfValorTheme.textPrimary,
                            ),
                          ),
                          Text(
                            quest.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: RealmOfValorTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isFeatured)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: RealmOfValorTheme.accentGold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'FEATURED',
                          style: TextStyle(
                            color: RealmOfValorTheme.accentGold,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildQuestInfo(),
                const SizedBox(height: 12),
                _buildProgressBar(),
                const SizedBox(height: 12),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestInfo() {
    return Row(
      children: [
        _buildInfoChip('Difficulty', quest.difficulty.name),
        const SizedBox(width: 8),
        _buildInfoChip('Type', quest.type.name),
        const SizedBox(width: 8),
        _buildInfoChip('XP', '${quest.experienceReward}'),
      ],
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: RealmOfValorTheme.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final completedObjectives = quest.objectives.where((obj) => obj.isCompleted).length;
    final totalObjectives = quest.objectives.length;
    final progress = totalObjectives > 0 ? completedObjectives / totalObjectives : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                fontSize: 12,
                color: RealmOfValorTheme.textSecondary,
              ),
            ),
            Text(
              '$completedObjectives/$totalObjectives',
              style: TextStyle(
                fontSize: 12,
                color: RealmOfValorTheme.accentGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: RealmOfValorTheme.surfaceDark,
          valueColor: AlwaysStoppedAnimation<Color>(RealmOfValorTheme.accentGold),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (onStart != null)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow, size: 16),
              label: const Text('Start Quest'),
              style: ElevatedButton.styleFrom(
                backgroundColor: RealmOfValorTheme.accentGold,
                foregroundColor: RealmOfValorTheme.surfaceDark,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        if (onStart != null) const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.info, size: 16),
            label: const Text('Details'),
            style: OutlinedButton.styleFrom(
              foregroundColor: RealmOfValorTheme.accentGold,
              side: BorderSide(color: RealmOfValorTheme.accentGold),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  Color _getQuestBorderColor() {
    switch (quest.difficulty) {
      case QuestDifficulty.easy:
        return Colors.green;
      case QuestDifficulty.medium:
        return Colors.orange;
      case QuestDifficulty.hard:
        return Colors.red;
      case QuestDifficulty.expert:
        return Colors.purple;
      case QuestDifficulty.legendary:
        return RealmOfValorTheme.accentGold;
    }
  }

  IconData _getQuestIcon() {
    switch (quest.type) {
      case QuestType.walking:
        return Icons.directions_walk;
      case QuestType.running:
        return Icons.directions_run;
      case QuestType.climbing:
        return Icons.trending_up;
      case QuestType.location:
        return Icons.location_on;
      case QuestType.exploration:
        return Icons.explore;
      case QuestType.collection:
        return Icons.collections;
      case QuestType.battle:
        return Icons.sports_kabaddi;
      case QuestType.social:
        return Icons.group;
      case QuestType.fitness:
        return Icons.fitness_center;
    }
  }
} 