import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/character_model.dart';
import '../providers/character_provider.dart';

enum QuestType {
  battle,
  collection,
  exploration,
  social,
  progression,
  special,
  achievement,
}

enum QuestRarity {
  common,
  rare,
  epic,
  legendary,
}

class DailyQuest {
  final String id;
  final String title;
  final String description;
  final QuestType type;
  final QuestRarity rarity;
  final int requiredProgress;
  final int currentProgress;
  final bool isCompleted;
  final DateTime? completedAt;
  final String icon;
  final Map<String, dynamic> rewards;
  final DateTime expiresAt;

  DailyQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.rarity,
    required this.requiredProgress,
    this.currentProgress = 0,
    this.isCompleted = false,
    this.completedAt,
    this.icon = '📋',
    this.rewards = const {},
    required this.expiresAt,
  });

  DailyQuest copyWith({
    String? id,
    String? title,
    String? description,
    QuestType? type,
    QuestRarity? rarity,
    int? requiredProgress,
    int? currentProgress,
    bool? isCompleted,
    DateTime? completedAt,
    String? icon,
    Map<String, dynamic>? rewards,
    DateTime? expiresAt,
  }) {
    return DailyQuest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      requiredProgress: requiredProgress ?? this.requiredProgress,
      currentProgress: currentProgress ?? this.currentProgress,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      icon: icon ?? this.icon,
      rewards: rewards ?? this.rewards,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  double get progressPercentage => 
      isCompleted ? 1.0 : (currentProgress / requiredProgress).clamp(0.0, 1.0);

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Color get rarityColor {
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

class DailyQuestService extends ChangeNotifier {
  static DailyQuestService? _instance;
  static DailyQuestService get instance => _instance ??= DailyQuestService._();

  DailyQuestService._();

  final Map<String, DailyQuest> _dailyQuests = {};
  final List<String> _completedQuests = [];
  DateTime? _lastRefreshDate;

  Map<String, DailyQuest> get dailyQuests => Map.unmodifiable(_dailyQuests);
  List<String> get completedQuests => List.unmodifiable(_completedQuests);
  DateTime? get lastRefreshDate => _lastRefreshDate;

  void initialize() {
    _checkAndRefreshQuests();
    if (kDebugMode) {
      print('[DailyQuestService] Initialized');
    }
  }

  void _checkAndRefreshQuests() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Check if we need to refresh quests (new day)
    if (_lastRefreshDate == null || !_isSameDay(_lastRefreshDate!, today)) {
      _refreshDailyQuests();
      _lastRefreshDate = today;
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  void _refreshDailyQuests() {
    _dailyQuests.clear();
    _completedQuests.clear();
    
    // Generate 3 random daily quests
    final questTypes = QuestType.values;
    final questRarities = QuestRarity.values;
    
    for (int i = 0; i < 3; i++) {
      final randomType = questTypes[DateTime.now().millisecondsSinceEpoch % questTypes.length];
      final randomRarity = questRarities[DateTime.now().millisecondsSinceEpoch % questRarities.length];
      
      final quest = _generateRandomQuest(randomType, randomRarity, i);
      _dailyQuests[quest.id] = quest;
    }
    
    if (kDebugMode) {
      print('[DailyQuestService] Refreshed daily quests');
    }
  }

  DailyQuest _generateRandomQuest(QuestType type, QuestRarity rarity, int index) {
    final questId = 'daily_quest_${DateTime.now().millisecondsSinceEpoch}_$index';
    final expiresAt = DateTime.now().add(const Duration(days: 1));
    
    switch (type) {
      case QuestType.battle:
        return _generateBattleQuest(questId, rarity, expiresAt);
      case QuestType.collection:
        return _generateCollectionQuest(questId, rarity, expiresAt);
      case QuestType.exploration:
        return _generateExplorationQuest(questId, rarity, expiresAt);
      case QuestType.social:
        return _generateSocialQuest(questId, rarity, expiresAt);
      case QuestType.progression:
        return _generateProgressionQuest(questId, rarity, expiresAt);
      case QuestType.special:
        return _generateSpecialQuest(questId, rarity, expiresAt);
      case QuestType.achievement:
        return _generateAchievementQuest(questId, rarity, expiresAt);
    }
  }

  DailyQuest _generateBattleQuest(String id, QuestRarity rarity, DateTime expiresAt) {
    final quests = [
      {
        'title': 'Victory Seeker',
        'description': 'Win 3 battles today',
        'required': 3,
        'icon': '⚔️',
        'rewards': {'experience': 50, 'gold': 25},
      },
      {
        'title': 'Perfect Warrior',
        'description': 'Win a battle without taking damage',
        'required': 1,
        'icon': '🛡️',
        'rewards': {'experience': 100, 'gold': 50, 'skill_points': 1},
      },
      {
        'title': 'Battle Master',
        'description': 'Win 5 battles today',
        'required': 5,
        'icon': '👑',
        'rewards': {'experience': 150, 'gold': 75, 'cards': 2},
      },
    ];
    
    final quest = quests[DateTime.now().millisecondsSinceEpoch % quests.length];
    
    return DailyQuest(
      id: id,
      title: quest['title'] as String,
      description: quest['description'] as String,
      type: QuestType.battle,
      rarity: rarity,
      requiredProgress: quest['required'] as int,
      icon: quest['icon'] as String,
      rewards: quest['rewards'] as Map<String, dynamic>,
      expiresAt: expiresAt,
    );
  }

  DailyQuest _generateCollectionQuest(String id, QuestRarity rarity, DateTime expiresAt) {
    final quests = [
      {
        'title': 'Card Collector',
        'description': 'Collect 5 new cards today',
        'required': 5,
        'icon': '🃏',
        'rewards': {'experience': 40, 'gold': 20, 'cards': 1},
      },
      {
        'title': 'Equipment Hunter',
        'description': 'Obtain 3 pieces of equipment',
        'required': 3,
        'icon': '⚔️',
        'rewards': {'experience': 60, 'gold': 30, 'equipment': 1},
      },
    ];
    
    final quest = quests[DateTime.now().millisecondsSinceEpoch % quests.length];
    
    return DailyQuest(
      id: id,
      title: quest['title'] as String,
      description: quest['description'] as String,
      type: QuestType.collection,
      rarity: rarity,
      requiredProgress: quest['required'] as int,
      icon: quest['icon'] as String,
      rewards: quest['rewards'] as Map<String, dynamic>,
      expiresAt: expiresAt,
    );
  }

  DailyQuest _generateExplorationQuest(String id, QuestRarity rarity, DateTime expiresAt) {
    final quests = [
      {
        'title': 'Adventure Seeker',
        'description': 'Complete 2 adventure missions',
        'required': 2,
        'icon': '🗺️',
        'rewards': {'experience': 45, 'gold': 25},
      },
      {
        'title': 'Explorer',
        'description': 'Visit 3 different locations',
        'required': 3,
        'icon': '🏃',
        'rewards': {'experience': 55, 'gold': 30},
      },
    ];
    
    final quest = quests[DateTime.now().millisecondsSinceEpoch % quests.length];
    
    return DailyQuest(
      id: id,
      title: quest['title'] as String,
      description: quest['description'] as String,
      type: QuestType.exploration,
      rarity: rarity,
      requiredProgress: quest['required'] as int,
      icon: quest['icon'] as String,
      rewards: quest['rewards'] as Map<String, dynamic>,
      expiresAt: expiresAt,
    );
  }

  DailyQuest _generateSocialQuest(String id, QuestRarity rarity, DateTime expiresAt) {
    final quests = [
      {
        'title': 'Social Butterfly',
        'description': 'Play 2 battles with friends',
        'required': 2,
        'icon': '🦋',
        'rewards': {'experience': 50, 'gold': 25},
      },
      {
        'title': 'Team Player',
        'description': 'Join 3 different battle lobbies',
        'required': 3,
        'icon': '👥',
        'rewards': {'experience': 60, 'gold': 30},
      },
    ];
    
    final quest = quests[DateTime.now().millisecondsSinceEpoch % quests.length];
    
    return DailyQuest(
      id: id,
      title: quest['title'] as String,
      description: quest['description'] as String,
      type: QuestType.social,
      rarity: rarity,
      requiredProgress: quest['required'] as int,
      icon: quest['icon'] as String,
      rewards: quest['rewards'] as Map<String, dynamic>,
      expiresAt: expiresAt,
    );
  }

  DailyQuest _generateProgressionQuest(String id, QuestRarity rarity, DateTime expiresAt) {
    final quests = [
      {
        'title': 'Level Up',
        'description': 'Gain 2 character levels',
        'required': 2,
        'icon': '📈',
        'rewards': {'experience': 100, 'gold': 50, 'skill_points': 2},
      },
      {
        'title': 'Skill Master',
        'description': 'Spend 5 skill points',
        'required': 5,
        'icon': '🧠',
        'rewards': {'experience': 80, 'gold': 40},
      },
    ];
    
    final quest = quests[DateTime.now().millisecondsSinceEpoch % quests.length];
    
    return DailyQuest(
      id: id,
      title: quest['title'] as String,
      description: quest['description'] as String,
      type: QuestType.progression,
      rarity: rarity,
      requiredProgress: quest['required'] as int,
      icon: quest['icon'] as String,
      rewards: quest['rewards'] as Map<String, dynamic>,
      expiresAt: expiresAt,
    );
  }

  DailyQuest _generateSpecialQuest(String id, QuestRarity rarity, DateTime expiresAt) {
    final quests = [
      {
        'title': 'Lucky Streak',
        'description': 'Win 3 battles in a row',
        'required': 3,
        'icon': '🍀',
        'rewards': {'experience': 120, 'gold': 60, 'cards': 3},
      },
      {
        'title': 'Perfect Day',
        'description': 'Complete all daily quests',
        'required': 1,
        'icon': '⭐',
        'rewards': {'experience': 200, 'gold': 100, 'skill_points': 3, 'title': 'Daily Master'},
      },
    ];
    
    final quest = quests[DateTime.now().millisecondsSinceEpoch % quests.length];
    
    return DailyQuest(
      id: id,
      title: quest['title'] as String,
      description: quest['description'] as String,
      type: QuestType.special,
      rarity: rarity,
      requiredProgress: quest['required'] as int,
      icon: quest['icon'] as String,
      rewards: quest['rewards'] as Map<String, dynamic>,
      expiresAt: expiresAt,
    );
  }

  DailyQuest _generateAchievementQuest(String id, QuestRarity rarity, DateTime expiresAt) {
    final quests = [
      {
        'title': 'Achievement Hunter',
        'description': 'Complete 5 achievements',
        'required': 5,
        'icon': '🏆',
        'rewards': {'experience': 150, 'gold': 75, 'achievements': 1},
      },
      {
        'title': 'Legendary Collector',
        'description': 'Obtain 3 legendary items',
        'required': 3,
        'icon': '⚔️',
        'rewards': {'experience': 200, 'gold': 100, 'legendary_items': 1},
      },
    ];
    
    final quest = quests[DateTime.now().millisecondsSinceEpoch % quests.length];
    
    return DailyQuest(
      id: id,
      title: quest['title'] as String,
      description: quest['description'] as String,
      type: QuestType.achievement,
      rarity: rarity,
      requiredProgress: quest['required'] as int,
      icon: quest['icon'] as String,
      rewards: quest['rewards'] as Map<String, dynamic>,
      expiresAt: expiresAt,
    );
  }

  // Accept a quest
  void acceptQuest(DailyQuest quest) {
    if (_dailyQuests.containsKey(quest.id)) {
      // Mark quest as accepted (you could add an 'accepted' field to DailyQuest)
      notifyListeners();
      if (kDebugMode) {
        print('[DailyQuestService] Quest accepted: ${quest.title}');
      }
    }
  }

  // Complete a quest
  void completeQuest(String questId) {
    if (_dailyQuests.containsKey(questId) && !_completedQuests.contains(questId)) {
      _completedQuests.add(questId);
      notifyListeners();
      if (kDebugMode) {
        print('[DailyQuestService] Quest completed: $questId');
      }
    }
  }

  // Update quest progress
  void updateQuestProgress(String questId, int progress) {
    if (_dailyQuests.containsKey(questId)) {
      final quest = _dailyQuests[questId]!;
      final updatedQuest = quest.copyWith(currentProgress: progress);
      _dailyQuests[questId] = updatedQuest;
      notifyListeners();
    }
  }

  /// Check if quest is completed
  bool isCompleted(String questId) {
    return _dailyQuests[questId]?.isCompleted ?? false;
  }

  /// Get quest by ID
  DailyQuest? getQuest(String questId) {
    return _dailyQuests[questId];
  }

  /// Get quests by type
  List<DailyQuest> getQuestsByType(QuestType type) {
    return _dailyQuests.values
        .where((quest) => quest.type == type)
        .toList();
  }

  /// Get completed quests
  List<DailyQuest> getCompletedQuests() {
    return _dailyQuests.values
        .where((quest) => quest.isCompleted)
        .toList();
  }

  /// Get progress for a specific quest
  double getProgress(String questId) {
    final quest = _dailyQuests[questId];
    return quest?.progressPercentage ?? 0.0;
  }

  /// Get quest statistics
  Map<String, dynamic> getStatistics() {
    final total = _dailyQuests.length;
    final completed = _dailyQuests.values.where((q) => q.isCompleted).length;
    final progress = total > 0 ? (completed / total) : 0.0;

    final typeStats = <QuestType, int>{};
    for (final type in QuestType.values) {
      typeStats[type] = _dailyQuests.values
          .where((q) => q.type == type && q.isCompleted)
          .length;
    }

    return {
      'total': total,
      'completed': completed,
      'progress': progress,
      'typeStats': typeStats,
    };
  }

  /// Get rarity statistics
  Map<QuestRarity, int> getRarityStatistics() {
    final stats = <QuestRarity, int>{};
    for (final rarity in QuestRarity.values) {
      stats[rarity] = _dailyQuests.values
          .where((q) => q.rarity == rarity && q.isCompleted)
          .length;
    }
    return stats;
  }

  /// Force refresh quests (for testing)
  void forceRefresh() {
    _refreshDailyQuests();
    notifyListeners();
  }

  /// Update progress for all quests of a specific type
  void updateProgressByType(QuestType type, int amount) {
    for (final quest in _dailyQuests.values) {
      if (quest.type == type && !quest.isCompleted) {
        final newProgress = quest.currentProgress + amount;
        final updatedQuest = quest.copyWith(
          currentProgress: newProgress,
          isCompleted: newProgress >= quest.requiredProgress,
          completedAt: newProgress >= quest.requiredProgress ? DateTime.now() : null,
        );
        _dailyQuests[quest.id] = updatedQuest;
        
        if (kDebugMode) {
          print('[DailyQuestService] Updated quest progress: ${quest.title} ($type) +$amount');
        }
      }
    }
    notifyListeners();
  }
} 