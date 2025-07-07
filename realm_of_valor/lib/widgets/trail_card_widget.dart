import 'package:flutter/material.dart';
import '../constants/theme.dart';

class TrailCardWidget extends StatelessWidget {
  final String name;
  final String description;
  final double lengthKm;
  final int elevationGainM;
  final String difficulty;
  final double rating;
  final int reviewCount;
  final VoidCallback? onTap;

  const TrailCardWidget({
    super.key,
    required this.name,
    required this.description,
    required this.lengthKm,
    required this.elevationGainM,
    required this.difficulty,
    required this.rating,
    required this.reviewCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trail header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.hiking,
                      color: _getDifficultyColor(),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: RealmOfValorTheme.textPrimary,
                          ),
                        ),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: RealmOfValorTheme.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getDifficultyIcon(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Trail stats
              Row(
                children: [
                  _buildStatChip(
                    Icons.straighten,
                    '${lengthKm.toStringAsFixed(1)} km',
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    Icons.trending_up,
                    '${elevationGainM}m ↗',
                    Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    Icons.star,
                    '${rating.toStringAsFixed(1)} ($reviewCount)',
                    Colors.amber,
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Adventure potential
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: RealmOfValorTheme.accentGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: RealmOfValorTheme.accentGold.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: RealmOfValorTheme.accentGold,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getAdventureDescription(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: RealmOfValorTheme.accentGold,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor() {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      case 'expert':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  String _getDifficultyIcon() {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return '🟢 Easy';
      case 'moderate':
        return '🟡 Moderate';
      case 'hard':
        return '🔴 Hard';
      case 'expert':
        return '⚫ Expert';
      default:
        return '🔵 Unknown';
    }
  }

  String _getAdventureDescription() {
    final xpReward = (lengthKm * 15 + elevationGainM / 10).round();
    return 'Adventure Quest: ${_getQuestCount()} objectives • $xpReward XP reward';
  }

  int _getQuestCount() {
    int count = 2; // Start + Finish
    if (elevationGainM > 200) count++; // Elevation challenge
    if (lengthKm > 5) count++; // Distance challenge
    return count;
  }
} 