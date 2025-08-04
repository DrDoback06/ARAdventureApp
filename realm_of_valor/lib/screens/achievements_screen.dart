import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../services/achievement_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  late AchievementService _achievementService;
  AchievementCategory _selectedCategory = AchievementCategory.battle;

  @override
  void initState() {
    super.initState();
    _achievementService = AchievementService.instance;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RealmOfValorTheme.surfaceDark,
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: RealmOfValorTheme.surfaceDark,
        foregroundColor: RealmOfValorTheme.textPrimary,
      ),
      body: Consumer<AchievementService>(
        builder: (context, achievementService, child) {
          final achievements = achievementService.achievements.values.toList();
          final filteredAchievements = achievements.where(
            (achievement) => achievement.category == _selectedCategory,
          ).toList();

          return Column(
            children: [
              _buildCategoryFilter(),
              Expanded(
                child: _buildAchievementsList(filteredAchievements, achievementService),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: AchievementCategory.values.length,
        itemBuilder: (context, index) {
          final category = AchievementCategory.values[index];
          final isSelected = category == _selectedCategory;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_getCategoryName(category)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              backgroundColor: RealmOfValorTheme.surfaceMedium,
              selectedColor: RealmOfValorTheme.accentGold,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : RealmOfValorTheme.textPrimary,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAchievementsList(List<Achievement> achievements, AchievementService service) {
    if (achievements.isEmpty) {
      return Center(
        child: Text(
          'No achievements in this category',
          style: TextStyle(
            color: RealmOfValorTheme.textSecondary,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        final isUnlocked = service.unlockedAchievements.contains(achievement.id);
        final progress = service.getAchievementProgress(achievement.id);
        final progressPercentage = progress / achievement.requiredProgress;

        return _buildAchievementCard(achievement, isUnlocked, progress.toInt(), progressPercentage);
      },
    );
  }

  Widget _buildAchievementCard(Achievement achievement, bool isUnlocked, int progress, double progressPercentage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked ? achievement.rarityColor : Colors.grey,
          width: isUnlocked ? 2 : 1,
        ),
        boxShadow: isUnlocked ? [
          BoxShadow(
            color: achievement.rarityColor.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ] : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isUnlocked ? achievement.rarityColor.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isUnlocked ? Icons.emoji_events : Icons.lock,
                    color: isUnlocked ? achievement.rarityColor : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement.title,
                        style: TextStyle(
                          color: RealmOfValorTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        achievement.description,
                        style: TextStyle(
                          color: RealmOfValorTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: achievement.rarityColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    achievement.rarity.name.toUpperCase(),
                    style: TextStyle(
                      color: achievement.rarityColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!isUnlocked) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Progress: $progress/${achievement.requiredProgress}',
                      style: TextStyle(
                        color: RealmOfValorTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    '${(progressPercentage * 100).toInt()}%',
                    style: TextStyle(
                      color: RealmOfValorTheme.accentGold,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progressPercentage,
                backgroundColor: Colors.grey.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(RealmOfValorTheme.accentGold),
              ),
            ],
            if (isUnlocked && achievement.unlockedAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Unlocked ${_formatDateTime(achievement.unlockedAt!)}',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getCategoryName(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.battle:
        return 'Battle';
      case AchievementCategory.exploration:
        return 'Exploration';
      case AchievementCategory.collection:
        return 'Collection';
      case AchievementCategory.social:
        return 'Social';
      case AchievementCategory.fitness:
        return 'Fitness';
      case AchievementCategory.progression:
        return 'Progression';
      case AchievementCategory.special:
        return 'Special';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
} 