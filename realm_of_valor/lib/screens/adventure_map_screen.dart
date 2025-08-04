import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../services/audio_service.dart';
import '../services/daily_quest_service.dart';
import '../models/character_model.dart';

class AdventureMapScreen extends StatefulWidget {
  const AdventureMapScreen({super.key});

  @override
  State<AdventureMapScreen> createState() => _AdventureMapScreenState();
}

class _AdventureMapScreenState extends State<AdventureMapScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<DailyQuest> _availableQuests = [];
  List<DailyQuest> _activeQuests = [];
  List<DailyQuest> _completedQuests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadQuests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadQuests() {
    // Load quests from the daily quest service
    final questService = context.read<DailyQuestService>();
    _availableQuests = questService.dailyQuests.values.toList();
    _activeQuests = _availableQuests.where((q) => !q.isCompleted && !q.isExpired).toList();
    _completedQuests = _availableQuests.where((q) => q.isCompleted).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RealmOfValorTheme.surfaceDark,
      appBar: AppBar(
        title: const Text('Adventure Map'),
        backgroundColor: RealmOfValorTheme.surfaceDark,
        foregroundColor: RealmOfValorTheme.textPrimary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: RealmOfValorTheme.accentGold,
          labelColor: RealmOfValorTheme.accentGold,
          unselectedLabelColor: RealmOfValorTheme.textSecondary,
          tabs: const [
            Tab(text: 'Available'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAvailableQuestsTab(),
          _buildActiveQuestsTab(),
          _buildCompletedQuestsTab(),
        ],
      ),
    );
  }

  Widget _buildAvailableQuestsTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Quests',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _availableQuests.length,
              itemBuilder: (context, index) {
                final quest = _availableQuests[index];
                return _buildQuestCard(quest, 'Available');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveQuestsTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Quests',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _activeQuests.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment,
                          size: 64,
                          color: RealmOfValorTheme.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Active Quests',
                          style: TextStyle(
                            fontSize: 18,
                            color: RealmOfValorTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start a quest from the Available tab',
                          style: TextStyle(
                            fontSize: 14,
                            color: RealmOfValorTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _activeQuests.length,
                    itemBuilder: (context, index) {
                      final quest = _activeQuests[index];
                      return _buildQuestCard(quest, 'Active');
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedQuestsTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Completed Quests',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _completedQuests.isEmpty
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
                          'No Completed Quests',
                          style: TextStyle(
                            fontSize: 18,
                            color: RealmOfValorTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Complete quests to see them here',
                          style: TextStyle(
                            fontSize: 14,
                            color: RealmOfValorTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _completedQuests.length,
                    itemBuilder: (context, index) {
                      final quest = _completedQuests[index];
                      return _buildQuestCard(quest, 'Completed');
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestCard(DailyQuest quest, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getQuestBorderColor(quest.type).withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getQuestIcon(quest.type),
                color: _getQuestBorderColor(quest.type),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.title,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: quest.rarityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  quest.rarity.name.toUpperCase(),
                  style: TextStyle(
                    color: quest.rarityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: quest.progressPercentage,
            backgroundColor: RealmOfValorTheme.surfaceDark,
            valueColor: AlwaysStoppedAnimation<Color>(RealmOfValorTheme.accentGold),
          ),
          const SizedBox(height: 8),
          Text(
            'Progress: ${quest.currentProgress}/${quest.requiredProgress}',
            style: TextStyle(
              fontSize: 12,
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _buildQuestActions(quest, status),
        ],
      ),
    );
  }

  Widget _buildQuestActions(DailyQuest quest, String status) {
    switch (status) {
      case 'Available':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _viewQuestDetails(quest),
                style: ElevatedButton.styleFrom(
                  backgroundColor: RealmOfValorTheme.surfaceDark,
                  foregroundColor: RealmOfValorTheme.accentGold,
                ),
                child: const Text('View Details'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _startQuest(quest),
                style: ElevatedButton.styleFrom(
                  backgroundColor: RealmOfValorTheme.accentGold,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Start Quest'),
              ),
            ),
          ],
        );
      case 'Active':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _viewQuestProgress(quest),
                style: ElevatedButton.styleFrom(
                  backgroundColor: RealmOfValorTheme.surfaceDark,
                  foregroundColor: RealmOfValorTheme.accentGold,
                ),
                child: const Text('View Progress'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _completeQuest(quest),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Complete'),
              ),
            ),
          ],
        );
      case 'Completed':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _viewQuestDetails(quest),
                style: ElevatedButton.styleFrom(
                  backgroundColor: RealmOfValorTheme.surfaceDark,
                  foregroundColor: RealmOfValorTheme.accentGold,
                ),
                child: const Text('View Details'),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Completed',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Color _getQuestBorderColor(QuestType type) {
    switch (type) {
      case QuestType.battle:
        return Colors.red;
      case QuestType.collection:
        return Colors.green;
      case QuestType.exploration:
        return Colors.cyan;
      case QuestType.social:
        return Colors.pink;
      case QuestType.progression:
        return Colors.yellow;
      case QuestType.special:
        return Colors.indigo;
      case QuestType.achievement:
        return Colors.amber;
    }
  }

  IconData _getQuestIcon(QuestType type) {
    switch (type) {
      case QuestType.battle:
        return Icons.sports_martial_arts;
      case QuestType.collection:
        return Icons.collections;
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

  void _startQuest(DailyQuest quest) {
    AudioService.instance.playSound(AudioType.buttonClick);
    
    setState(() {
      _activeQuests.add(quest);
      _availableQuests.remove(quest);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Started quest: ${quest.title}'),
        backgroundColor: RealmOfValorTheme.accentGold,
      ),
    );
  }

  void _viewQuestProgress(DailyQuest quest) {
    AudioService.instance.playSound(AudioType.buttonClick);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RealmOfValorTheme.surfaceMedium,
        title: Text(
          quest.title,
          style: TextStyle(
            color: RealmOfValorTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quest.description,
              style: TextStyle(color: RealmOfValorTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              'Progress: 0/${quest.requiredProgress}',
              style: TextStyle(
                color: RealmOfValorTheme.accentGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(color: RealmOfValorTheme.accentGold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _completeQuest(quest);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RealmOfValorTheme.accentGold,
              foregroundColor: Colors.white,
            ),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  void _completeQuest(DailyQuest quest) {
    setState(() {
      _activeQuests.remove(quest);
      _completedQuests.add(quest);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Completed quest: ${quest.title}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _acceptQuest(DailyQuest quest) {
    AudioService.instance.playSound(AudioType.buttonClick);
    
    // Add quest to active quests
    final questService = context.read<DailyQuestService>();
    questService.acceptQuest(quest);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Quest accepted: ${quest.title}'),
        backgroundColor: RealmOfValorTheme.accentGold,
      ),
    );
    
    setState(() {
      // Refresh the quest list
    });
  }

  void _viewQuestDetails(DailyQuest quest) {
    AudioService.instance.playSound(AudioType.buttonClick);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RealmOfValorTheme.surfaceMedium,
        title: Text(
          quest.title,
          style: TextStyle(
            color: RealmOfValorTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quest.description,
              style: TextStyle(
                color: RealmOfValorTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  _getQuestIcon(quest.type),
                  color: _getQuestBorderColor(quest.type),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Type: ${quest.type.name.toUpperCase()}',
                  style: TextStyle(
                    color: RealmOfValorTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: quest.rarityColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Rarity: ${quest.rarity.name.toUpperCase()}',
                  style: TextStyle(
                    color: RealmOfValorTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: quest.progressPercentage,
              backgroundColor: RealmOfValorTheme.surfaceDark,
              valueColor: AlwaysStoppedAnimation<Color>(RealmOfValorTheme.accentGold),
            ),
            const SizedBox(height: 4),
            Text(
              'Progress: ${quest.currentProgress}/${quest.requiredProgress}',
              style: TextStyle(
                color: RealmOfValorTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Rewards:',
              style: TextStyle(
                color: RealmOfValorTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ...quest.rewards.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    _getRewardIcon(entry.key),
                    color: RealmOfValorTheme.accentGold,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${entry.value} ${entry.key}',
                    style: TextStyle(
                      color: RealmOfValorTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(color: RealmOfValorTheme.accentGold),
            ),
          ),
          if (!quest.isCompleted && !quest.isExpired)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _acceptQuest(quest);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: RealmOfValorTheme.accentGold,
                foregroundColor: Colors.white,
              ),
              child: const Text('Accept Quest'),
            ),
        ],
      ),
    );
  }

  IconData _getRewardIcon(String rewardType) {
    switch (rewardType.toLowerCase()) {
      case 'gold':
        return Icons.monetization_on;
      case 'experience':
        return Icons.trending_up;
      case 'items':
        return Icons.inventory;
      case 'skill points':
        return Icons.psychology;
      case 'stat points':
        return Icons.fitness_center;
      default:
        return Icons.star;
    }
  }
}