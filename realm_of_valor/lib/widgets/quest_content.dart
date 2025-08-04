import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../providers/character_provider.dart';
import '../models/character_model.dart';
import 'draggable_quest_widget.dart';

class QuestContent extends StatefulWidget {
  const QuestContent({super.key});

  @override
  State<QuestContent> createState() => _QuestContentState();
}

class _QuestContentState extends State<QuestContent> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DraggableQuestManager _questManager = DraggableQuestManager();
  final List<QuestData> _sampleQuests = [
    QuestData(
      id: 'quest_1',
      title: 'Dragon Slayer',
      description: 'Defeat the ancient dragon in the mountains',
      experience: 500,
      gold: 100,
      status: 'active',
      deadline: DateTime.now().add(const Duration(days: 3)),
      location: 'Mountain Peak',
    ),
    QuestData(
      id: 'quest_2',
      title: 'Treasure Hunter',
      description: 'Find the lost treasure in the forest',
      experience: 300,
      gold: 75,
      status: 'active',
      deadline: DateTime.now().add(const Duration(days: 1)),
      location: 'Dark Forest',
    ),
    QuestData(
      id: 'quest_3',
      title: 'Merchant\'s Delivery',
      description: 'Deliver the package to the village',
      experience: 150,
      gold: 25,
      status: 'completed',
      deadline: DateTime.now().subtract(const Duration(hours: 2)),
      location: 'Village Square',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeQuestWidgets();
    print('DEBUG: QuestContent initialized');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeQuestWidgets() {
    // Add sample quest widgets to the manager
    for (final quest in _sampleQuests) {
      final widget = DraggableQuestWidget(
        quest: quest,
        onTap: () => _showQuestDetails(quest),
        onComplete: () => _completeQuest(quest),
        onAbandon: () => _abandonQuest(quest),
        onPositionChanged: (position) => _updateQuestPosition(quest.id, position),
      );
      _questManager.addQuestWidget(widget);
    }
  }

  void _showQuestDetails(QuestData quest) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RealmOfValorTheme.surfaceMedium,
        title: Text(
          quest.title,
          style: TextStyle(color: RealmOfValorTheme.textPrimary),
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
            Row(
              children: [
                Icon(Icons.star, color: RealmOfValorTheme.accentGold, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${quest.experience} XP',
                  style: TextStyle(color: RealmOfValorTheme.accentGold),
                ),
                const SizedBox(width: 16),
                Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${quest.gold} Gold',
                  style: TextStyle(color: Colors.amber),
                ),
              ],
            ),
            if (quest.location != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    quest.location!,
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ],
            if (quest.deadline != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Deadline: ${_formatDeadline(quest.deadline!)}',
                    style: TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _completeQuest(QuestData quest) {
    // TODO: Implement quest completion logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Quest completed: ${quest.title}'),
        backgroundColor: Colors.green,
      ),
    );
    print('DEBUG: Quest completed: ${quest.title}');
  }

  void _abandonQuest(QuestData quest) {
    // TODO: Implement quest abandonment logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Quest abandoned: ${quest.title}'),
        backgroundColor: Colors.orange,
      ),
    );
    print('DEBUG: Quest abandoned: ${quest.title}');
  }

  void _updateQuestPosition(String questId, Offset position) {
    print('DEBUG: Quest position updated: $questId at $position');
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    
    if (difference.isNegative) {
      return 'Overdue';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours';
    } else {
      return '${difference.inMinutes} minutes';
    }
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: Building QuestContent');
    return Consumer<CharacterProvider>(
      builder: (context, characterProvider, child) {
        final character = characterProvider.currentCharacter;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: RealmOfValorTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: RealmOfValorTheme.primaryLight,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.assignment,
                    color: RealmOfValorTheme.accentGold,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Quest Manager',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: RealmOfValorTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: RealmOfValorTheme.accentGold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_sampleQuests.where((q) => q.status == 'active').length} Active',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  color: RealmOfValorTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: RealmOfValorTheme.accentGold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: RealmOfValorTheme.textSecondary,
                  tabs: const [
                    Tab(text: 'Active'),
                    Tab(text: 'Completed'),
                    Tab(text: 'Available'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildActiveQuestsTab(),
                    _buildCompletedQuestsTab(),
                    _buildAvailableQuestsTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveQuestsTab() {
    final activeQuests = _sampleQuests.where((q) => q.status == 'active').toList();
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Quests',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (activeQuests.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 48,
                    color: RealmOfValorTheme.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No active quests',
                    style: TextStyle(
                      fontSize: 16,
                      color: RealmOfValorTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            ...activeQuests.map((quest) => _buildQuestCard(quest)),
        ],
      ),
    );
  }

  Widget _buildCompletedQuestsTab() {
    final completedQuests = _sampleQuests.where((q) => q.status == 'completed').toList();
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Completed Quests',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (completedQuests.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 48,
                    color: RealmOfValorTheme.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No completed quests',
                    style: TextStyle(
                      fontSize: 16,
                      color: RealmOfValorTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            ...completedQuests.map((quest) => _buildQuestCard(quest)),
        ],
      ),
    );
  }

  Widget _buildAvailableQuestsTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Quests',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildQuestGenerator(),
        ],
      ),
    );
  }

  Widget _buildQuestGenerator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RealmOfValorTheme.accentGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generate New Quest',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Create a new quest widget that you can drag around the screen',
            style: TextStyle(
              fontSize: 14,
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _generateNewQuest,
            icon: const Icon(Icons.add),
            label: const Text('Generate Quest'),
            style: ElevatedButton.styleFrom(
              backgroundColor: RealmOfValorTheme.accentGold,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestCard(QuestData quest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: quest.status == 'active' 
              ? Colors.blue 
              : quest.status == 'completed' 
                  ? Colors.green 
                  : Colors.grey,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                quest.status == 'active' 
                    ? Icons.play_arrow 
                    : quest.status == 'completed' 
                        ? Icons.check_circle 
                        : Icons.help,
                color: quest.status == 'active' 
                    ? Colors.blue 
                    : quest.status == 'completed' 
                        ? Colors.green 
                        : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  quest.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: RealmOfValorTheme.textPrimary,
                  ),
                ),
              ),
              if (quest.status == 'active')
                IconButton(
                  onPressed: () => _showQuestDetails(quest),
                  icon: const Icon(Icons.info_outline),
                  iconSize: 20,
                  color: RealmOfValorTheme.textSecondary,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            quest.description,
            style: TextStyle(
              fontSize: 14,
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.star, color: RealmOfValorTheme.accentGold, size: 16),
              const SizedBox(width: 4),
              Text(
                '${quest.experience} XP',
                style: TextStyle(
                  fontSize: 12,
                  color: RealmOfValorTheme.accentGold,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.monetization_on, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(
                '${quest.gold} Gold',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _generateNewQuest() {
    final newQuest = QuestData(
      id: 'quest_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Generated Quest ${DateTime.now().millisecondsSinceEpoch % 1000}',
      description: 'A randomly generated quest for testing',
      experience: 100 + (DateTime.now().millisecondsSinceEpoch % 400),
      gold: 10 + (DateTime.now().millisecondsSinceEpoch % 90),
      status: 'active',
      deadline: DateTime.now().add(const Duration(days: 1)),
      location: 'Random Location',
    );

    final widget = DraggableQuestWidget(
      quest: newQuest,
      onTap: () => _showQuestDetails(newQuest),
      onComplete: () => _completeQuest(newQuest),
      onAbandon: () => _abandonQuest(newQuest),
      onPositionChanged: (position) => _updateQuestPosition(newQuest.id, position),
    );

    _questManager.addQuestWidget(widget);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('New quest generated: ${newQuest.title}'),
        backgroundColor: RealmOfValorTheme.accentGold,
      ),
    );

    print('DEBUG: Generated new quest: ${newQuest.title}');
  }
} 