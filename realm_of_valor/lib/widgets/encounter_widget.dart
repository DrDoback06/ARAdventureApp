import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../constants/theme.dart';
import '../services/encounter_service.dart';

class EncounterWidget extends StatelessWidget {
  final Encounter encounter;
  final VoidCallback? onEncounterComplete;
  final VoidCallback? onEncounterSkip;

  const EncounterWidget({
    super.key,
    required this.encounter,
    this.onEncounterComplete,
    this.onEncounterSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getEncounterColor().withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getEncounterColor().withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Encounter Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getEncounterColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getEncounterIcon(),
                  color: _getEncounterColor(),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      encounter.title,
                      style: TextStyle(
                        color: RealmOfValorTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor().withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        encounter.difficulty.name.toUpperCase(),
                        style: TextStyle(
                          color: _getDifficultyColor(),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Encounter Description
          Text(
            encounter.description,
            style: TextStyle(
              color: RealmOfValorTheme.textSecondary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          // Rewards Preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: RealmOfValorTheme.surfaceMedium,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildRewardItem(Icons.star, '${encounter.rewardXP} XP', Colors.amber),
                _buildRewardItem(Icons.monetization_on, '${encounter.rewardGold} Gold', Colors.yellow),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Action Buttons
          Row(
            children: [
              if (onEncounterSkip != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onEncounterSkip,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Skip'),
                  ),
                ),
              if (onEncounterSkip != null && onEncounterComplete != null)
                const SizedBox(width: 12),
              if (onEncounterComplete != null)
                Expanded(
                  child: ElevatedButton(
                    onPressed: onEncounterComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getEncounterColor(),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(_getActionText()),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRewardItem(IconData icon, String text, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getEncounterColor() {
    switch (encounter.type) {
      case EncounterType.exploration:
        return Colors.blue;
      case EncounterType.fitness:
        return Colors.orange;
      case EncounterType.battle:
        return Colors.red;
      case EncounterType.social:
        return Colors.green;
      case EncounterType.collection:
        return Colors.purple;
    }
  }

  IconData _getEncounterIcon() {
    switch (encounter.type) {
      case EncounterType.exploration:
        return Icons.explore;
      case EncounterType.fitness:
        return Icons.fitness_center;
      case EncounterType.battle:
        return Icons.sports_martial_arts;
      case EncounterType.social:
        return Icons.people;
      case EncounterType.collection:
        return Icons.collections;
    }
  }

  Color _getDifficultyColor() {
    switch (encounter.difficulty) {
      case EncounterDifficulty.easy:
        return Colors.green;
      case EncounterDifficulty.medium:
        return Colors.orange;
      case EncounterDifficulty.hard:
        return Colors.red;
      case EncounterDifficulty.expert:
        return Colors.purple;
      case EncounterDifficulty.legendary:
        return Colors.amber;
    }
  }

  String _getActionText() {
    switch (encounter.type) {
      case EncounterType.exploration:
        return 'Explore';
      case EncounterType.fitness:
        return 'Challenge';
      case EncounterType.battle:
        return 'Fight';
      case EncounterType.social:
        return 'Interact';
      case EncounterType.collection:
        return 'Collect';
    }
  }
}

class EncounterMarker extends StatelessWidget {
  final Encounter encounter;
  final VoidCallback? onTap;

  const EncounterMarker({
    super.key,
    required this.encounter,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getEncounterColor(),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: _getEncounterColor().withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          _getEncounterIcon(),
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Color _getEncounterColor() {
    switch (encounter.type) {
      case EncounterType.exploration:
        return Colors.blue;
      case EncounterType.fitness:
        return Colors.orange;
      case EncounterType.battle:
        return Colors.red;
      case EncounterType.social:
        return Colors.green;
      case EncounterType.collection:
        return Colors.purple;
    }
  }

  IconData _getEncounterIcon() {
    switch (encounter.type) {
      case EncounterType.exploration:
        return Icons.explore;
      case EncounterType.fitness:
        return Icons.fitness_center;
      case EncounterType.battle:
        return Icons.sports_martial_arts;
      case EncounterType.social:
        return Icons.people;
      case EncounterType.collection:
        return Icons.collections;
    }
  }
} 