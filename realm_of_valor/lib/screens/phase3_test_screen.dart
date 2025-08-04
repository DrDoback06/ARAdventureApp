import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../widgets/achievement_notification.dart';
import '../widgets/draggable_quest_widget.dart';
import '../services/accessibility_service.dart';

class Phase3TestScreen extends StatefulWidget {
  const Phase3TestScreen({super.key});

  @override
  State<Phase3TestScreen> createState() => _Phase3TestScreenState();
}

class _Phase3TestScreenState extends State<Phase3TestScreen> {
  final AchievementNotificationManager _notificationManager = AchievementNotificationManager();
  final DraggableQuestManager _questManager = DraggableQuestManager();
  final AccessibilityService _accessibilityService = AccessibilityService();
  
  final List<QuestData> _sampleQuests = [
    QuestData(
      id: 'quest_1',
      title: 'Daily Exercise',
      description: 'Complete 30 minutes of physical activity',
      experience: 150,
      gold: 50,
      status: 'active',
      deadline: DateTime.now().add(const Duration(hours: 2)),
      location: 'Gym',
    ),
    QuestData(
      id: 'quest_2',
      title: 'Adventure Walk',
      description: 'Walk 5km in the city',
      experience: 200,
      gold: 75,
      status: 'active',
      deadline: DateTime.now().add(const Duration(days: 1)),
      location: 'City Center',
    ),
    QuestData(
      id: 'quest_3',
      title: 'Battle Victory',
      description: 'Win 3 battles in the arena',
      experience: 300,
      gold: 100,
      status: 'completed',
      deadline: DateTime.now().add(const Duration(hours: 6)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupQuestWidgets();
  }

  void _setupQuestWidgets() {
    for (final quest in _sampleQuests) {
      final widget = DraggableQuestWidget(
        quest: quest,
        onTap: () => _showQuestDetails(quest),
        onComplete: () => _completeQuest(quest),
        onAbandon: () => _abandonQuest(quest),
        onPositionChanged: (position) => _saveQuestPosition(quest.id, position),
      );
      _questManager.addQuestWidget(widget);
    }
  }

  void _showQuestDetails(QuestData quest) {
    print('DEBUG: Showing quest details: ${quest.title}');
    _accessibilityService.announceToScreenReader('Quest details: ${quest.title}');
  }

  void _completeQuest(QuestData quest) {
    print('DEBUG: Completing quest: ${quest.title}');
    _notificationManager.showQuestCompleted(
      questName: quest.title,
      experience: quest.experience,
      gold: quest.gold,
    );
    _accessibilityService.announceQuestCompleted(quest.title);
  }

  void _abandonQuest(QuestData quest) {
    print('DEBUG: Abandoning quest: ${quest.title}');
    _accessibilityService.announceToScreenReader('Quest abandoned: ${quest.title}');
  }

  void _saveQuestPosition(String questId, Offset position) {
    print('DEBUG: Saving quest position: $questId at $position');
  }

  void _testAchievementNotifications() {
    print('DEBUG: Testing achievement notifications');
    
    // Test different types of notifications
    _notificationManager.showAchievement(
      title: 'First Steps',
      message: 'Complete your first quest',
      icon: Icons.emoji_events,
      backgroundColor: Colors.orange,
    );

    _notificationManager.showLevelUp(
      newLevel: 5,
      characterName: 'Hero',
    );

    _notificationManager.showItemFound(
      itemName: 'Legendary Sword',
      rarity: 'Legendary',
    );

    _notificationManager.showActivityMilestone(
      activityType: 'Running',
      milestone: '10km completed',
    );
  }

  void _testAccessibilityFeatures() {
    print('DEBUG: Testing accessibility features');
    
    _accessibilityService.announceAchievement('First Steps');
    _accessibilityService.announceLevelUp('Hero', 5);
    _accessibilityService.announceItemFound('Legendary Sword', 'Legendary');
    _accessibilityService.announceActivityMilestone('Running', '10km completed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RealmOfValorTheme.surfaceDark,
      appBar: AppBar(
        title: const Text('Phase 3 Test Screen'),
        backgroundColor: RealmOfValorTheme.surfaceMedium,
        foregroundColor: RealmOfValorTheme.textPrimary,
      ),
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTestSection(
                  title: 'Achievement Notifications',
                  description: 'Test different types of achievement notifications',
                  onTest: _testAchievementNotifications,
                ),
                const SizedBox(height: 16),
                _buildTestSection(
                  title: 'Accessibility Features',
                  description: 'Test screen reader announcements and accessibility',
                  onTest: _testAccessibilityFeatures,
                ),
                const SizedBox(height: 16),
                _buildTestSection(
                  title: 'Draggable Quest Widgets',
                  description: 'Drag quest widgets around the screen',
                  onTest: () => print('DEBUG: Quest widgets are already active'),
                ),
                const SizedBox(height: 16),
                _buildTestSection(
                  title: 'Swipe Gestures',
                  description: 'Swipe down on bottom sheets or right on full screens to close',
                  onTest: () => print('DEBUG: Swipe gestures are active'),
                ),
                const SizedBox(height: 16),
                _buildTestSection(
                  title: 'Window Persistence',
                  description: 'Window states are automatically saved and restored',
                  onTest: () => print('DEBUG: Window persistence is active'),
                ),
                const SizedBox(height: 16),
                _buildAccessibilityInfo(),
              ],
            ),
          ),
          
          // Draggable quest widgets
          ..._questManager.questWidgets.map((widget) => widget),
        ],
      ),
    );
  }

  Widget _buildTestSection({
    required String title,
    required String description,
    required VoidCallback onTest,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RealmOfValorTheme.accentGold, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onTest,
            style: ElevatedButton.styleFrom(
              backgroundColor: RealmOfValorTheme.accentGold,
              foregroundColor: Colors.white,
            ),
            child: const Text('Test Feature'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessibilityInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RealmOfValorTheme.accentGold, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accessibility Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Screen Reader: ${_accessibilityService.isScreenReaderEnabled ? "Enabled" : "Disabled"}',
            style: TextStyle(
              fontSize: 14,
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
          Text(
            'High Contrast: ${_accessibilityService.isHighContrastEnabled ? "Enabled" : "Disabled"}',
            style: TextStyle(
              fontSize: 14,
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
          Text(
            'Large Text: ${_accessibilityService.isLargeTextEnabled ? "Enabled" : "Disabled"}',
            style: TextStyle(
              fontSize: 14,
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
          Text(
            'Text Scale: ${_accessibilityService.textScaleFactor.toStringAsFixed(2)}x',
            style: TextStyle(
              fontSize: 14,
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
} 