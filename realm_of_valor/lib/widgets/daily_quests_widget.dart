import 'package:flutter/material.dart';
import '../services/daily_quest_service.dart';
import '../constants/theme.dart';

class DailyQuestsWidget extends StatefulWidget {
  final VoidCallback? onQuestCompleted;

  const DailyQuestsWidget({
    super.key,
    this.onQuestCompleted,
  });

  @override
  State<DailyQuestsWidget> createState() => _DailyQuestsWidgetState();
}

class _DailyQuestsWidgetState extends State<DailyQuestsWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final DailyQuestService _questService = DailyQuestService.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: QuestType.values.length + 1, // +1 for "All" tab
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: RealmOfValorTheme.accentGold,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: RealmOfValorTheme.surfaceMedium,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.assignment,
                  color: RealmOfValorTheme.accentGold,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daily Quests',
                        style: TextStyle(
                          color: RealmOfValorTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_questService.getCompletedQuests().length}/${_questService.dailyQuests.length} Completed',
                        style: const TextStyle(
                          color: RealmOfValorTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatisticsButton(),
              ],
            ),
          ),

          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: RealmOfValorTheme.surfaceMedium,
              border: Border(
                bottom: BorderSide(
                  color: RealmOfValorTheme.accentGold.withOpacity(0.3),
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: RealmOfValorTheme.accentGold,
              labelColor: RealmOfValorTheme.accentGold,
              unselectedLabelColor: RealmOfValorTheme.textSecondary,
              tabs: [
                const Tab(text: 'All'),
                ...QuestType.values.map((type) {
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getTypeIcon(type), size: 16),
                        const SizedBox(width: 4),
                        Text(_getTypeName(type)),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllQuestsTab(),
                ...QuestType.values.map((type) {
                  return _buildTypeTab(type);
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsButton() {
    return IconButton(
      onPressed: _showStatistics,
      icon: const Icon(
        Icons.analytics,
        color: RealmOfValorTheme.accentGold,
      ),
      tooltip: 'View Statistics',
    );
  }

  Widget _buildAllQuestsTab() {
    final allQuests = _questService.dailyQuests.values.toList();
    final completedQuests = _questService.getCompletedQuests();
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Completed Quests
        if (completedQuests.isNotEmpty) ...[
          _buildSectionHeader('Completed Today', Icons.check_circle),
          const SizedBox(height: 8),
          ...completedQuests.take(3).map((quest) {
            return _buildQuestCard(quest);
          }).toList(),
          const SizedBox(height: 24),
        ],

        // Active Quests
        _buildSectionHeader('Active Quests', Icons.pending),
        const SizedBox(height: 8),
        ...allQuests.where((quest) => !quest.isCompleted).map((quest) {
          return _buildQuestCard(quest);
        }).toList(),
      ],
    );
  }

  Widget _buildTypeTab(QuestType type) {
    final quests = _questService.getQuestsByType(type);
    
    if (quests.isEmpty) {
      return const Center(
        child: Text(
          'No quests in this category yet',
          style: TextStyle(
            color: RealmOfValorTheme.textSecondary,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: quests.length,
      itemBuilder: (context, index) {
        final quest = quests[index];
        return _buildQuestCard(quest);
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: RealmOfValorTheme.accentGold,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: RealmOfValorTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestCard(DailyQuest quest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: quest.isCompleted 
              ? quest.rarityColor 
              : RealmOfValorTheme.textSecondary.withOpacity(0.3),
          width: quest.isCompleted ? 2 : 1,
        ),
        boxShadow: quest.isCompleted ? [
          BoxShadow(
            color: quest.rarityColor.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ] : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: quest.isCompleted 
                        ? quest.rarityColor.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: quest.isCompleted 
                          ? quest.rarityColor 
                          : Colors.grey,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      quest.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest.title,
                        style: TextStyle(
                          color: quest.isCompleted 
                              ? RealmOfValorTheme.textPrimary 
                              : RealmOfValorTheme.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        quest.description,
                        style: const TextStyle(
                          color: RealmOfValorTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (quest.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: quest.rarityColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getRarityName(quest.rarity),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(
                        color: RealmOfValorTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${quest.currentProgress}/${quest.requiredProgress}',
                      style: TextStyle(
                        color: quest.isCompleted 
                            ? quest.rarityColor 
                            : RealmOfValorTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: quest.progressPercentage,
                  backgroundColor: Colors.grey.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    quest.isCompleted 
                        ? quest.rarityColor 
                        : RealmOfValorTheme.accentGold,
                  ),
                ),
              ],
            ),

            // Rewards
            if (quest.rewards.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Rewards:',
                style: TextStyle(
                  color: RealmOfValorTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: quest.rewards.entries.map((entry) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: RealmOfValorTheme.accentGold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: RealmOfValorTheme.accentGold.withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      '${entry.key}: ${entry.value}',
                      style: const TextStyle(
                        color: RealmOfValorTheme.accentGold,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            // Time Remaining
            if (!quest.isCompleted && !quest.isExpired) ...[
              const SizedBox(height: 8),
              Text(
                'Expires: ${_formatTimeRemaining(quest.expiresAt)}',
                style: const TextStyle(
                  color: RealmOfValorTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],

            // Completion Date
            if (quest.isCompleted && quest.completedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Completed: ${_formatDate(quest.completedAt!)}',
                style: const TextStyle(
                  color: RealmOfValorTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(QuestType type) {
    switch (type) {
      case QuestType.battle:
        return Icons.flash_on;
      case QuestType.collection:
        return Icons.inventory;
      case QuestType.exploration:
        return Icons.explore;
      case QuestType.social:
        return Icons.people;
      case QuestType.progression:
        return Icons.trending_up;
      case QuestType.special:
        return Icons.star;
      case QuestType.achievement:
        return Icons.emoji_events;
    }
  }

  String _getTypeName(QuestType type) {
    switch (type) {
      case QuestType.battle:
        return 'Battle';
      case QuestType.collection:
        return 'Collection';
      case QuestType.exploration:
        return 'Exploration';
      case QuestType.social:
        return 'Social';
      case QuestType.progression:
        return 'Progression';
      case QuestType.special:
        return 'Special';
      case QuestType.achievement:
        return 'Achievement';
    }
  }

  String _getRarityName(QuestRarity rarity) {
    switch (rarity) {
      case QuestRarity.common:
        return 'Common';
      case QuestRarity.rare:
        return 'Rare';
      case QuestRarity.epic:
        return 'Epic';
      case QuestRarity.legendary:
        return 'Legendary';
    }
  }

  String _formatTimeRemaining(DateTime expiresAt) {
    final now = DateTime.now();
    final difference = expiresAt.difference(now);
    
    if (difference.isNegative) {
      return 'Expired';
    }
    
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showStatistics() {
    final stats = _questService.getStatistics();
    final rarityStats = _questService.getRarityStatistics();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RealmOfValorTheme.surfaceDark,
        title: const Text(
          'Quest Statistics',
          style: TextStyle(
            color: RealmOfValorTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Total Quests', '${stats['total']}'),
            _buildStatRow('Completed', '${stats['completed']}'),
            _buildStatRow('Progress', '${(stats['progress'] * 100).toStringAsFixed(1)}%'),
            const Divider(color: RealmOfValorTheme.textSecondary),
            const Text(
              'By Type:',
              style: TextStyle(
                color: RealmOfValorTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...QuestType.values.map((type) {
              final count = stats['typeStats'][type] ?? 0;
              return _buildStatRow(
                _getTypeName(type),
                '$count',
              );
            }),
            const Divider(color: RealmOfValorTheme.textSecondary),
            const Text(
              'By Rarity:',
              style: TextStyle(
                color: RealmOfValorTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...QuestRarity.values.map((rarity) {
              final count = rarityStats[rarity] ?? 0;
              return _buildStatRow(
                _getRarityName(rarity),
                '$count',
                color: _getRarityColor(rarity),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: RealmOfValorTheme.accentGold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: RealmOfValorTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? RealmOfValorTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRarityColor(QuestRarity rarity) {
    switch (rarity) {
      case QuestRarity.common:
        return Colors.grey;
      case QuestRarity.rare:
        return Colors.blue;
      case QuestRarity.epic:
        return Colors.purple;
      case QuestRarity.legendary:
        return Colors.orange;
    }
  }
} 