import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../services/achievement_service.dart';
import '../services/audio_service.dart';

class AchievementsWidget extends StatefulWidget {
  const AchievementsWidget({super.key});

  @override
  State<AchievementsWidget> createState() => _AchievementsWidgetState();
}

class _AchievementsWidgetState extends State<AchievementsWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RealmOfValorTheme.surfaceDark,
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: RealmOfValorTheme.surfaceDark,
        foregroundColor: RealmOfValorTheme.textPrimary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: RealmOfValorTheme.accentGold,
          labelColor: RealmOfValorTheme.accentGold,
          unselectedLabelColor: RealmOfValorTheme.textSecondary,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Recent'),
            Tab(text: 'Progress'),
            Tab(text: 'Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllAchievementsTab(),
          _buildRecentAchievementsTab(),
          _buildProgressTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  Widget _buildAllAchievementsTab() {
    return Consumer<AchievementService>(
      builder: (context, achievementService, child) {
        final achievements = achievementService.achievements.values.toList();
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'All Achievements',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: RealmOfValorTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: achievements.length,
                  itemBuilder: (context, index) {
                    final achievement = achievements[index];
                    final isUnlocked = achievementService.unlockedAchievements.contains(achievement.id);
                    final progress = achievementService.getAchievementProgress(achievement.id);
                    
                    return _buildAchievementCard(achievement, isUnlocked, progress);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentAchievementsTab() {
    return Consumer<AchievementService>(
      builder: (context, achievementService, child) {
        final recentAchievements = achievementService.getRecentAchievements();
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent Unlocks',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: RealmOfValorTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: recentAchievements.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.emoji_events,
                              size: 64,
                              color: RealmOfValorTheme.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Achievements Yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: RealmOfValorTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start playing to unlock achievements!',
                              style: TextStyle(
                                fontSize: 14,
                                color: RealmOfValorTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: recentAchievements.length,
                        itemBuilder: (context, index) {
                          final achievement = recentAchievements[index];
                          return _buildAchievementCard(achievement, true, 1.0);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressTab() {
    return Consumer<AchievementService>(
      builder: (context, achievementService, child) {
        final stats = achievementService.getAchievementStatistics();
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progress Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: RealmOfValorTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _buildProgressCard(
                      'Total Achievements',
                      '${stats['totalAchievements']}',
                      Icons.emoji_events,
                      RealmOfValorTheme.accentGold,
                    ),
                    const SizedBox(height: 12),
                    _buildProgressCard(
                      'Unlocked',
                      '${stats['unlockedCount']}',
                      Icons.check_circle,
                      Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildProgressCard(
                      'Completion Rate',
                      '${(stats['completionRate'] * 100).round()}%',
                      Icons.trending_up,
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildProgressCard(
                      'Recent Unlocks',
                      '${stats['recentAchievements']}',
                      Icons.new_releases,
                      Colors.orange,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsTab() {
    return Consumer<AchievementService>(
      builder: (context, achievementService, child) {
        final stats = achievementService.getAchievementStatistics();
        final rarityStats = achievementService.getRarityStatistics();
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Achievement Statistics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: RealmOfValorTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _buildCategoryStats(stats['categoryStats'] as Map<String, int>),
                    const SizedBox(height: 16),
                    _buildRarityStats(rarityStats),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAchievementCard(Achievement achievement, bool isUnlocked, double progress) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked 
              ? _getRarityColor(achievement.rarity)
              : RealmOfValorTheme.accentGold.withOpacity(0.3),
          width: isUnlocked ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isUnlocked 
                      ? _getRarityColor(achievement.rarity).withOpacity(0.2)
                      : RealmOfValorTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isUnlocked ? Icons.emoji_events : Icons.lock,
                  color: isUnlocked 
                      ? _getRarityColor(achievement.rarity)
                      : RealmOfValorTheme.textSecondary,
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: RealmOfValorTheme.textPrimary,
                      ),
                    ),
                    Text(
                      achievement.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: RealmOfValorTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRarityColor(achievement.rarity).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  achievement.rarity.name.toUpperCase(),
                  style: TextStyle(
                    color: _getRarityColor(achievement.rarity),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!isUnlocked) ...[
            LinearProgressIndicator(
              value: progress,
              backgroundColor: RealmOfValorTheme.surfaceDark,
              valueColor: AlwaysStoppedAnimation<Color>(_getRarityColor(achievement.rarity)),
            ),
            const SizedBox(height: 8),
            Text(
              'Progress: ${(progress * achievement.requiredProgress).round()}/${achievement.requiredProgress}',
              style: TextStyle(
                fontSize: 12,
                color: RealmOfValorTheme.textSecondary,
              ),
            ),
          ],
          if (isUnlocked && achievement.unlockedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Unlocked: ${_formatDate(achievement.unlockedAt!)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green,
              ),
            ),
          ],
          const SizedBox(height: 12),
          _buildRewardsList(achievement.rewards),
        ],
      ),
    );
  }

  Widget _buildProgressCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: RealmOfValorTheme.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: RealmOfValorTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStats(Map<String, int> categoryStats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RealmOfValorTheme.accentGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Progress',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...categoryStats.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    entry.key.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: RealmOfValorTheme.textSecondary,
                    ),
                  ),
                ),
                Text(
                  '${entry.value}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: RealmOfValorTheme.textPrimary,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildRarityStats(Map<AchievementRarity, int> rarityStats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RealmOfValorTheme.accentGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rarity Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...rarityStats.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getRarityColor(entry.key),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.key.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: RealmOfValorTheme.textSecondary,
                    ),
                  ),
                ),
                Text(
                  '${entry.value}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: RealmOfValorTheme.textPrimary,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildRewardsList(Map<String, dynamic> rewards) {
    if (rewards.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rewards:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: RealmOfValorTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: rewards.entries.map((entry) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: RealmOfValorTheme.accentGold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${entry.value} ${entry.key}',
              style: TextStyle(
                fontSize: 10,
                color: RealmOfValorTheme.accentGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Color _getRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return Colors.grey;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return Colors.orange;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 