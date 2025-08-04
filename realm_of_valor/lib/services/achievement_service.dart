import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/character_model.dart';
import '../providers/character_provider.dart';

enum AchievementCategory {
  battle,
  exploration,
  collection,
  social,
  fitness,
  progression,
  special,
}

enum AchievementRarity {
  common,
  rare,
  epic,
  legendary,
}

enum AchievementTier {
  bronze,
  silver,
  gold,
  platinum,
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final AchievementCategory category;
  final AchievementRarity rarity;
  final AchievementTier tier;
  final int requiredProgress;
  final Map<String, dynamic> rewards;
  final DateTime? unlockedAt;
  final String? icon;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.rarity,
    required this.tier,
    required this.requiredProgress,
    required this.rewards,
    this.unlockedAt,
    this.icon,
  });

  Achievement copyWith({
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      category: category,
      rarity: rarity,
      tier: tier,
      requiredProgress: requiredProgress,
      rewards: rewards,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      icon: icon,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'rarity': rarity.name,
      'tier': tier.name,
      'requiredProgress': requiredProgress,
      'rewards': rewards,
      'unlockedAt': unlockedAt?.millisecondsSinceEpoch,
      'icon': icon,
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: AchievementCategory.values.firstWhere(
        (e) => e.name == json['category'],
      ),
      rarity: AchievementRarity.values.firstWhere(
        (e) => e.name == json['rarity'],
      ),
      tier: AchievementTier.values.firstWhere(
        (e) => e.name == json['tier'],
      ),
      requiredProgress: json['requiredProgress'] as int,
      rewards: Map<String, dynamic>.from(json['rewards'] as Map),
      unlockedAt: json['unlockedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['unlockedAt'] as int)
          : null,
      icon: json['icon'] as String?,
    );
  }

  Color get rarityColor {
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
}

class AchievementService extends ChangeNotifier {
  static AchievementService? _instance;
  static AchievementService get instance => _instance ??= AchievementService._();
  AchievementService._();

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // Achievement data
  final Map<String, Achievement> _achievements = {};
  final Set<String> _unlockedAchievements = {};
  final Map<String, int> _achievementProgress = {};
  final List<String> _recentUnlocks = [];

  // Getters
  Map<String, Achievement> get achievements => Map.unmodifiable(_achievements);
  Set<String> get unlockedAchievements => Set.unmodifiable(_unlockedAchievements);
  Map<String, int> get achievementProgress => Map.unmodifiable(_achievementProgress);
  List<String> get recentUnlocks => List.unmodifiable(_recentUnlocks);

  // Initialize service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    await _loadAchievementData();
    _initializeAchievements();
    _isInitialized = true;
    notifyListeners();
  }

  // Load achievement data from preferences
  Future<void> _loadAchievementData() async {
    final unlockedList = _prefs.getStringList('achievements_unlocked') ?? [];
    _unlockedAchievements.addAll(unlockedList);

    final progressList = _prefs.getStringList('achievements_progress') ?? [];
    for (final progressStr in progressList) {
      final parts = progressStr.split(':');
      if (parts.length == 2) {
        final achievementId = parts[0];
        final progress = int.tryParse(parts[1]) ?? 0;
        _achievementProgress[achievementId] = progress;
      }
    }

    final recentList = _prefs.getStringList('achievements_recent') ?? [];
    _recentUnlocks.addAll(recentList);
  }

  // Save achievement data to preferences
  Future<void> _saveAchievementData() async {
    await _prefs.setStringList('achievements_unlocked', _unlockedAchievements.toList());
    
    final progressList = _achievementProgress.entries
        .map((entry) => '${entry.key}:${entry.value}')
        .toList();
    await _prefs.setStringList('achievements_progress', progressList);
    
    await _prefs.setStringList('achievements_recent', _recentUnlocks);
  }

  // Add achievement to the service
  void _addAchievement(Achievement achievement) {
    _achievements[achievement.id] = achievement;
  }

  // Initialize all achievements
  void _initializeAchievements() {
    // Battle achievements
    _addAchievement(Achievement(
      id: 'first_blood',
      title: 'First Blood',
      description: 'Win your first battle',
      category: AchievementCategory.battle,
      rarity: AchievementRarity.common,
      tier: AchievementTier.bronze,
      requiredProgress: 1,
      rewards: {'experience': 50, 'gold': 25},
    ));

    _addAchievement(Achievement(
      id: 'battle_master',
      title: 'Battle Master',
      description: 'Win 10 battles',
      category: AchievementCategory.battle,
      rarity: AchievementRarity.rare,
      tier: AchievementTier.silver,
      requiredProgress: 10,
      rewards: {'experience': 200, 'gold': 100, 'skill_points': 2},
    ));

    _addAchievement(Achievement(
      id: 'legendary_warrior',
      title: 'Legendary Warrior',
      description: 'Win 50 battles',
      category: AchievementCategory.battle,
      rarity: AchievementRarity.legendary,
      tier: AchievementTier.gold,
      requiredProgress: 50,
      rewards: {'experience': 1000, 'gold': 500, 'skill_points': 5, 'title': 'Legendary Warrior'},
    ));

    _addAchievement(Achievement(
      id: 'perfect_victory',
      title: 'Perfect Victory',
      description: 'Win a battle without taking damage',
      category: AchievementCategory.battle,
      rarity: AchievementRarity.epic,
      tier: AchievementTier.platinum,
      requiredProgress: 1,
      rewards: {'experience': 300, 'gold': 150, 'equipment': 'Perfect Shield'},
    ));

    _addAchievement(Achievement(
      id: 'streak_master',
      title: 'Streak Master',
      description: 'Win 5 battles in a row',
      category: AchievementCategory.battle,
      rarity: AchievementRarity.rare,
      tier: AchievementTier.silver,
      requiredProgress: 5,
      rewards: {'experience': 400, 'gold': 200, 'skill_points': 3},
    ));

    // Progression achievements
    _addAchievement(Achievement(
      id: 'level_10',
      title: 'Apprentice',
      description: 'Reach level 10',
      category: AchievementCategory.progression,
      rarity: AchievementRarity.common,
      tier: AchievementTier.bronze,
      requiredProgress: 10,
      rewards: {'experience': 100, 'gold': 50, 'skill_points': 1},
    ));

    _addAchievement(Achievement(
      id: 'level_25',
      title: 'Adept',
      description: 'Reach level 25',
      category: AchievementCategory.progression,
      rarity: AchievementRarity.rare,
      tier: AchievementTier.silver,
      requiredProgress: 25,
      rewards: {'experience': 500, 'gold': 250, 'skill_points': 3},
    ));

    _addAchievement(Achievement(
      id: 'level_50',
      title: 'Master',
      description: 'Reach level 50',
      category: AchievementCategory.progression,
      rarity: AchievementRarity.epic,
      tier: AchievementTier.gold,
      requiredProgress: 50,
      rewards: {'experience': 1500, 'gold': 750, 'skill_points': 5, 'title': 'Master'},
    ));

    // Collection achievements
    _addAchievement(Achievement(
      id: 'card_collector',
      title: 'Card Collector',
      description: 'Collect 50 different cards',
      category: AchievementCategory.collection,
      rarity: AchievementRarity.rare,
      tier: AchievementTier.silver,
      requiredProgress: 50,
      rewards: {'experience': 300, 'gold': 150, 'cards': 5},
    ));

    _addAchievement(Achievement(
      id: 'equipment_master',
      title: 'Equipment Master',
      description: 'Equip a full set of legendary items',
      category: AchievementCategory.collection,
      rarity: AchievementRarity.legendary,
      tier: AchievementTier.gold,
      requiredProgress: 8,
      rewards: {'experience': 1000, 'gold': 500, 'title': 'Equipment Master'},
    ));

    // Fitness achievements
    _addAchievement(Achievement(
      id: 'workout_30_min',
      title: 'Fitness Enthusiast',
      description: 'Complete a 30-minute workout',
      category: AchievementCategory.fitness,
      rarity: AchievementRarity.common,
      tier: AchievementTier.bronze,
      requiredProgress: 1,
      rewards: {'experience': 100, 'gold': 50},
    ));

    _addAchievement(Achievement(
      id: 'workout_1_hour',
      title: 'Dedicated Athlete',
      description: 'Complete a 1-hour workout',
      category: AchievementCategory.fitness,
      rarity: AchievementRarity.rare,
      tier: AchievementTier.silver,
      requiredProgress: 1,
      rewards: {'experience': 300, 'gold': 150, 'skill_points': 2},
    ));

    _addAchievement(Achievement(
      id: 'run_5km',
      title: 'Distance Runner',
      description: 'Run 5km in a single session',
      category: AchievementCategory.fitness,
      rarity: AchievementRarity.epic,
      tier: AchievementTier.gold,
      requiredProgress: 1,
      rewards: {'experience': 500, 'gold': 250, 'equipment': 'Running Shoes'},
    ));

    // Special achievements
    _addAchievement(Achievement(
      id: 'daily_player',
      title: 'Daily Player',
      description: 'Play for 7 consecutive days',
      category: AchievementCategory.special,
      rarity: AchievementRarity.rare,
      tier: AchievementTier.silver,
      requiredProgress: 7,
      rewards: {'experience': 200, 'gold': 100, 'daily_bonus': true},
    ));

    _addAchievement(Achievement(
      id: 'social_butterfly',
      title: 'Social Butterfly',
      description: 'Play 10 battles with friends',
      category: AchievementCategory.social,
      rarity: AchievementRarity.epic,
      tier: AchievementTier.gold,
      requiredProgress: 10,
      rewards: {'experience': 400, 'gold': 200, 'title': 'Social Butterfly'},
    ));

    // Collection achievements
    _addAchievement(Achievement(
      id: 'achievement_collector_10',
      title: 'Achievement Hunter',
      description: 'Unlock 10 achievements',
      category: AchievementCategory.collection,
      rarity: AchievementRarity.rare,
      tier: AchievementTier.silver,
      requiredProgress: 10,
      rewards: {'experience': 200, 'gold': 100},
    ));

    _addAchievement(Achievement(
      id: 'achievement_collector_25',
      title: 'Achievement Master',
      description: 'Unlock 25 achievements',
      category: AchievementCategory.collection,
      rarity: AchievementRarity.epic,
      tier: AchievementTier.gold,
      requiredProgress: 25,
      rewards: {'experience': 500, 'gold': 250, 'title': 'Achievement Master'},
    ));

    _addAchievement(Achievement(
      id: 'achievement_collector_50',
      title: 'Achievement Legend',
      description: 'Unlock 50 achievements',
      category: AchievementCategory.collection,
      rarity: AchievementRarity.legendary,
      tier: AchievementTier.platinum,
      requiredProgress: 50,
      rewards: {'experience': 1000, 'gold': 500, 'title': 'Achievement Legend'},
    ));
  }

  // Unlock an achievement
  void unlockAchievement(String achievementId) {
    if (_unlockedAchievements.contains(achievementId)) {
      return; // Already unlocked
    }

    final achievement = _achievements[achievementId];
    if (achievement == null) {
      if (kDebugMode) {
        print('[AchievementService] Achievement not found: $achievementId');
      }
      return;
    }

    _unlockedAchievements.add(achievementId);
    _achievementProgress[achievementId] = achievement.requiredProgress;
    _recentUnlocks.add(achievementId);

    // Keep only last 10 recent unlocks
    if (_recentUnlocks.length > 10) {
      _recentUnlocks.removeAt(0);
    }

    // Award rewards
    _awardAchievementRewards(achievement);

    // Check for collection achievements
    _checkCollectionAchievements();

    // Save progress
    _saveAchievementData();
    notifyListeners();

    if (kDebugMode) {
      print('[AchievementService] Achievement unlocked: ${achievement.title}');
    }
  }

  // Update achievement progress
  void updateAchievementProgress(String achievementId, int progress) {
    if (_unlockedAchievements.contains(achievementId)) {
      return; // Already unlocked
    }

    final achievement = _achievements[achievementId];
    if (achievement == null) return;

    final currentProgress = _achievementProgress[achievementId] ?? 0;
    final newProgress = (currentProgress + progress).clamp(0, achievement.requiredProgress);
    
    _achievementProgress[achievementId] = newProgress;

    // Check if achievement should be unlocked
    if (newProgress >= achievement.requiredProgress) {
      unlockAchievement(achievementId);
    } else {
      _saveAchievementData();
      notifyListeners();
    }
  }

  // Award rewards for unlocking an achievement
  void _awardAchievementRewards(Achievement achievement) {
    final characterProvider = _getCharacterProvider();
    if (characterProvider == null) return;

    final character = characterProvider.currentCharacter;
    if (character == null) return;

    // Award experience
    if (achievement.rewards.containsKey('experience')) {
      characterProvider.addExperience(
        achievement.rewards['experience'] as int,
        source: 'Achievement: ${achievement.title}',
      );
    }

    // Award gold
    if (achievement.rewards.containsKey('gold')) {
      // Add gold to character (this would need to be implemented in CharacterProvider)
      if (kDebugMode) {
        print('[AchievementService] Awarded ${achievement.rewards['gold']} gold for ${achievement.title}');
      }
    }

    // Award items
    if (achievement.rewards.containsKey('equipment')) {
      // Add item to character inventory (this would need to be implemented)
      if (kDebugMode) {
        print('[AchievementService] Awarded equipment ${achievement.rewards['equipment']} for ${achievement.title}');
      }
    }

    // Award stat points
    if (achievement.rewards.containsKey('skill_points')) {
      // Add stat points to character (this would need to be implemented)
      if (kDebugMode) {
        print('[AchievementService] Awarded ${achievement.rewards['skill_points']} skill points for ${achievement.title}');
      }
    }
  }

  // Check for collection achievements
  void _checkCollectionAchievements() {
    final unlockedCount = _unlockedAchievements.length;
    
    // Check for achievement count milestones
    if (unlockedCount >= 10 && !_unlockedAchievements.contains('achievement_collector_10')) {
      unlockAchievement('achievement_collector_10');
    }
    if (unlockedCount >= 25 && !_unlockedAchievements.contains('achievement_collector_25')) {
      unlockAchievement('achievement_collector_25');
    }
    if (unlockedCount >= 50 && !_unlockedAchievements.contains('achievement_collector_50')) {
      unlockAchievement('achievement_collector_50');
    }

    // Check for category-specific achievements
    _checkCategoryAchievements();
  }

  // Check for category-specific achievements
  void _checkCategoryAchievements() {
    final categoryCounts = <AchievementCategory, int>{};
    
    for (final achievementId in _unlockedAchievements) {
      final achievement = _achievements[achievementId];
      if (achievement != null) {
        categoryCounts[achievement.category] = (categoryCounts[achievement.category] ?? 0) + 1;
      }
    }

    // Check for category milestones
    for (final entry in categoryCounts.entries) {
      final category = entry.key;
      final count = entry.value;
      
      if (count >= 5 && !_unlockedAchievements.contains('${category.name}_master_5')) {
        unlockAchievement('${category.name}_master_5');
      }
      if (count >= 10 && !_unlockedAchievements.contains('${category.name}_master_10')) {
        unlockAchievement('${category.name}_master_10');
      }
    }
  }

  // Get achievement by ID
  Achievement? getAchievement(String achievementId) {
    return _achievements[achievementId];
  }

  // Get achievement progress
  double getAchievementProgress(String achievementId) {
    final achievement = _achievements[achievementId];
    if (achievement == null) return 0.0;

    if (_unlockedAchievements.contains(achievementId)) {
      return 1.0;
    }

    final currentProgress = _achievementProgress[achievementId] ?? 0;
    return currentProgress / achievement.requiredProgress;
  }

  // Get achievements by category
  List<Achievement> getAchievementsByCategory(AchievementCategory category) {
    return _achievements.values
        .where((achievement) => achievement.category == category)
        .toList();
  }

  // Get unlocked achievements
  List<Achievement> getUnlockedAchievements() {
    return _unlockedAchievements
        .map((id) => _achievements[id])
        .where((achievement) => achievement != null)
        .cast<Achievement>()
        .toList();
  }

  // Get recent achievements (last 10)
  List<Achievement> getRecentAchievements() {
    final unlocked = getUnlockedAchievements();
    unlocked.sort((a, b) => b.unlockedAt?.compareTo(a.unlockedAt ?? DateTime.now()) ?? 0);
    return unlocked.take(10).toList();
  }

  // Get achievement statistics
  Map<String, dynamic> getAchievementStatistics() {
    final totalAchievements = _achievements.length;
    final unlockedCount = _unlockedAchievements.length;
    final completionRate = totalAchievements > 0 ? unlockedCount / totalAchievements : 0.0;

    final categoryStats = <String, int>{};
    for (final category in AchievementCategory.values) {
      final categoryAchievements = getAchievementsByCategory(category);
      final unlockedInCategory = categoryAchievements
          .where((achievement) => _unlockedAchievements.contains(achievement.id))
          .length;
      categoryStats[category.name] = unlockedInCategory;
    }

    return {
      'totalAchievements': totalAchievements,
      'unlockedCount': unlockedCount,
      'completionRate': completionRate,
      'categoryStats': categoryStats,
      'recentAchievements': getRecentAchievements().length,
    };
  }

  // Get rarity statistics
  Map<AchievementRarity, int> getRarityStatistics() {
    final stats = <AchievementRarity, int>{};
    for (final rarity in AchievementRarity.values) {
      stats[rarity] = _achievements.values
          .where((a) => a.rarity == rarity && _unlockedAchievements.contains(a.id))
          .length;
    }
    return stats;
  }

  // Get character provider from context
  CharacterProvider? _getCharacterProvider() {
    // This would need to be implemented with proper context access
    // For now, we'll return null and handle it gracefully
    return null;
  }

  /// Update progress for a specific achievement
  void updateProgress(String achievementId, int amount) {
    final achievement = _achievements[achievementId];
    if (achievement == null) return;

    if (_unlockedAchievements.contains(achievementId)) return; // Already unlocked

    final currentProgress = _achievementProgress[achievementId] ?? 0;
    final newProgress = currentProgress + amount;
    _achievementProgress[achievementId] = newProgress;

    if (kDebugMode) {
      print('[AchievementService] Updated progress for $achievementId: $currentProgress -> $newProgress');
    }

    // Check if achievement is now complete
    if (newProgress >= achievement.requiredProgress) {
      unlockAchievement(achievementId);
    } else {
      notifyListeners();
    }
  }

  /// Update progress for all achievements in a category
  void updateProgressByCategory(AchievementCategory category, int amount) {
    for (final achievement in _achievements.values) {
      if (achievement.category == category && !_unlockedAchievements.contains(achievement.id)) {
        updateProgress(achievement.id, amount);
      }
    }
  }
}