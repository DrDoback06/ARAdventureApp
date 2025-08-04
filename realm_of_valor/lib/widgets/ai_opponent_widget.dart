import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../models/ai_opponent_data.dart';
import '../services/ai_battle_service.dart';

class AIOpponentWidget extends StatelessWidget {
  final String name;
  final String description;
  final AIDifficulty difficulty;
  final AIStrategy strategy;
  final VoidCallback onTap;

  const AIOpponentWidget({
    super.key,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.strategy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: RealmOfValorTheme.surfaceMedium,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getDifficultyIcon(),
                    color: _getDifficultyColor(),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: RealmOfValorTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: RealmOfValorTheme.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      difficulty.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getDifficultyColor(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: RealmOfValorTheme.accentGold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      strategy.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: RealmOfValorTheme.accentGold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getDifficultyIcon() {
    switch (difficulty) {
      case AIDifficulty.easy:
        return Icons.star;
      case AIDifficulty.medium:
        return Icons.stars;
      case AIDifficulty.hard:
        return Icons.star_rate;
      case AIDifficulty.expert:
        return Icons.star_half;
      case AIDifficulty.legendary:
        return Icons.whatshot;
    }
  }

  Color _getDifficultyColor() {
    switch (difficulty) {
      case AIDifficulty.easy:
        return Colors.green;
      case AIDifficulty.medium:
        return Colors.orange;
      case AIDifficulty.hard:
        return Colors.red;
      case AIDifficulty.expert:
        return Colors.deepOrange;
      case AIDifficulty.legendary:
        return Colors.purple;
    }
  }
} 