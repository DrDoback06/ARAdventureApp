import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/adventure_system.dart';
import 'adventure_progression_service.dart';

enum AchievementCategory {
  exploration,
  fitness,
  social,
  seasonal,
  special,
  milestone,
  collection,
  combat,
}

enum AchievementRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  mythic,
}

class Achievement {
  final String id;
  final String name;
  final String description;
  final AchievementCategory category;
  final AchievementRarity rarity;
  final Map<String, dynamic> requirements;
  final Map<String, dynamic> progress;
  final Map<String, dynamic> rewards;
  final String iconPath;
  final bool isHidden;
  final bool isCompleted;
  final DateTime? completedAt;
  final List<String> prerequisites;
  final int maxProgress;
  final bool isRepeatable;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.rarity,
    required this.requirements,
    Map<String, dynamic>? progress,
    required this.rewards,
    required this.iconPath,
    this.isHidden = false,
    this.isCompleted = false,
    this.completedAt,
    List<String>? prerequisites,
    this.maxProgress = 1,
    this.isRepeatable = false,
  }) : progress = progress ?? {},
       prerequisites = prerequisites ?? [];

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: AchievementCategory.values[json['category'] ?? 0],
      rarity: AchievementRarity.values[json['rarity'] ?? 0],
      requirements: Map<String, dynamic>.from(json['requirements']),
      progress: Map<String, dynamic>.from(json['progress'] ?? {}),
      rewards: Map<String, dynamic>.from(json['rewards']),
      iconPath: json['iconPath'],
      isHidden: json['isHidden'] ?? false,
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'])
          : null,
      prerequisites: List<String>.from(json['prerequisites'] ?? []),
      maxProgress: json['maxProgress'] ?? 1,
      isRepeatable: json['isRepeatable'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.index,
      'rarity': rarity.index,
      'requirements': requirements,
      'progress': progress,
      'rewards': rewards,
      'iconPath': iconPath,
      'isHidden': isHidden,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'prerequisites': prerequisites,
      'maxProgress': maxProgress,
      'isRepeatable': isRepeatable,
    };
  }

  double get progressPercentage {
    if (maxProgress <= 1) return isCompleted ? 100.0 : 0.0;
    
    final currentProgress = progress.values.fold<num>(0, (sum, value) {
      if (value is num) return sum + value;
      return sum;
    });
    
    return (currentProgress / maxProgress * 100).clamp(0.0, 100.0);
  }

  Achievement copyWith({
    Map<String, dynamic>? progress,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return Achievement(
      id: id,
      name: name,
      description: description,
      category: category,
      rarity: rarity,
      requirements: requirements,
      progress: progress ?? this.progress,
      rewards: rewards,
      iconPath: iconPath,
      isHidden: isHidden,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      prerequisites: prerequisites,
      maxProgress: maxProgress,
      isRepeatable: isRepeatable,
    );
  }
}

class Badge {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final AchievementRarity rarity;
  final DateTime earnedAt;
  final String earnedFor;
  final Map<String, dynamic> metadata;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.rarity,
    required this.earnedAt,
    required this.earnedFor,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      iconPath: json['iconPath'],
      rarity: AchievementRarity.values[json['rarity'] ?? 0],
      earnedAt: DateTime.parse(json['earnedAt']),
      earnedFor: json['earnedFor'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconPath': iconPath,
      'rarity': rarity.index,
      'earnedAt': earnedAt.toIso8601String(),
      'earnedFor': earnedFor,
      'metadata': metadata,
    };
  }
}

class AchievementService {
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal();

  final StreamController<Achievement> _achievementUnlockedController = StreamController.broadcast();
  final StreamController<Badge> _badgeEarnedController = StreamController.broadcast();
  final StreamController<List<Achievement>> _achievementsController = StreamController.broadcast();

  Stream<Achievement> get achievementUnlockedStream => _achievementUnlockedController.stream;
  Stream<Badge> get badgeEarnedStream => _badgeEarnedController.stream;
  Stream<List<Achievement>> get achievementsStream => _achievementsController.stream;

  List<Achievement> _achievements = [];
  List<Badge> _earnedBadges = [];
  String? _playerId;

  // Initialize achievement system
  Future<void> initialize(String playerId) async {
    _playerId = playerId;
    await _loadPlayerProgress();
    _initializeAchievements();
    _achievementsController.add(_achievements);
  }

  // Initialize all available achievements
  void _initializeAchievements() {
    _achievements = [
      // Exploration Achievements
      ..._createExplorationAchievements(),
      // Fitness Achievements
      ..._createFitnessAchievements(),
      // Social Achievements
      ..._createSocialAchievements(),
      // Milestone Achievements
      ..._createMilestoneAchievements(),
      // Seasonal Achievements
      ..._createSeasonalAchievements(),
      // Special Achievements
      ..._createSpecialAchievements(),
      // Collection Achievements
      ..._createCollectionAchievements(),
      // Combat Achievements
      ..._createCombatAchievements(),
    ];
  }

  // Create exploration achievements
  List<Achievement> _createExplorationAchievements() {
    return [
      Achievement(
        id: 'first_steps',
        name: 'First Steps',
        description: 'Take your first 1,000 steps in adventure mode',
        category: AchievementCategory.exploration,
        rarity: AchievementRarity.common,
        requirements: {'steps': 1000},
        rewards: {'xp': 100, 'title': 'First Walker'},
        iconPath: 'achievements/first_steps.png',
      ),
      Achievement(
        id: 'location_explorer',
        name: 'Location Explorer',
        description: 'Visit 10 different POIs',
        category: AchievementCategory.exploration,
        rarity: AchievementRarity.uncommon,
        requirements: {'unique_locations': 10},
        rewards: {'xp': 250, 'cards': 2, 'title': 'Explorer'},
        iconPath: 'achievements/location_explorer.png',
      ),
      Achievement(
        id: 'world_traveler',
        name: 'World Traveler',
        description: 'Travel a total distance of 100 kilometers',
        category: AchievementCategory.exploration,
        rarity: AchievementRarity.rare,
        requirements: {'total_distance': 100000},
        rewards: {'xp': 500, 'cards': 3, 'title': 'World Traveler'},
        iconPath: 'achievements/world_traveler.png',
        maxProgress: 100000,
      ),
      Achievement(
        id: 'territory_master',
        name: 'Territory Master',
        description: 'Visit every type of location at least once',
        category: AchievementCategory.exploration,
        rarity: AchievementRarity.epic,
        requirements: {
          'parks': 1, 'gyms': 1, 'restaurants': 1, 
          'monuments': 1, 'libraries': 1
        },
        rewards: {'xp': 750, 'cards': 4, 'title': 'Territory Master'},
        iconPath: 'achievements/territory_master.png',
      ),
      Achievement(
        id: 'legendary_explorer',
        name: 'Legendary Explorer',
        description: 'Complete 100 exploration quests',
        category: AchievementCategory.exploration,
        rarity: AchievementRarity.legendary,
        requirements: {'exploration_quests': 100},
        rewards: {'xp': 1000, 'cards': 5, 'title': 'Legendary Explorer'},
        iconPath: 'achievements/legendary_explorer.png',
        maxProgress: 100,
      ),
    ];
  }

  // Create fitness achievements
  List<Achievement> _createFitnessAchievements() {
    return [
      Achievement(
        id: 'fitness_beginner',
        name: 'Fitness Beginner',
        description: 'Complete your first workout session',
        category: AchievementCategory.fitness,
        rarity: AchievementRarity.common,
        requirements: {'workouts': 1},
        rewards: {'xp': 50, 'title': 'Fitness Starter'},
        iconPath: 'achievements/fitness_beginner.png',
      ),
      Achievement(
        id: 'step_master',
        name: 'Step Master',
        description: 'Take 10,000 steps in a single day',
        category: AchievementCategory.fitness,
        rarity: AchievementRarity.uncommon,
        requirements: {'daily_steps': 10000},
        rewards: {'xp': 200, 'cards': 2, 'title': 'Step Master'},
        iconPath: 'achievements/step_master.png',
        isRepeatable: true,
      ),
      Achievement(
        id: 'marathon_runner',
        name: 'Marathon Runner',
        description: 'Run/walk 42.2 kilometers in adventure mode',
        category: AchievementCategory.fitness,
        rarity: AchievementRarity.rare,
        requirements: {'running_distance': 42200},
        rewards: {'xp': 600, 'cards': 3, 'title': 'Marathon Runner'},
        iconPath: 'achievements/marathon_runner.png',
        maxProgress: 42200,
      ),
      Achievement(
        id: 'fitness_champion',
        name: 'Fitness Champion',
        description: 'Maintain a 30-day workout streak',
        category: AchievementCategory.fitness,
        rarity: AchievementRarity.epic,
        requirements: {'workout_streak': 30},
        rewards: {'xp': 800, 'cards': 4, 'title': 'Fitness Champion'},
        iconPath: 'achievements/fitness_champion.png',
        maxProgress: 30,
      ),
      Achievement(
        id: 'legendary_athlete',
        name: 'Legendary Athlete',
        description: 'Burn 100,000 calories through adventures',
        category: AchievementCategory.fitness,
        rarity: AchievementRarity.legendary,
        requirements: {'total_calories': 100000},
        rewards: {'xp': 1200, 'cards': 5, 'title': 'Legendary Athlete'},
        iconPath: 'achievements/legendary_athlete.png',
        maxProgress: 100000,
      ),
    ];
  }

  // Create social achievements
  List<Achievement> _createSocialAchievements() {
    return [
      Achievement(
        id: 'social_butterfly',
        name: 'Social Butterfly',
        description: 'Add 5 friends to your adventure network',
        category: AchievementCategory.social,
        rarity: AchievementRarity.common,
        requirements: {'friends': 5},
        rewards: {'xp': 150, 'title': 'Social Butterfly'},
        iconPath: 'achievements/social_butterfly.png',
      ),
      Achievement(
        id: 'team_player',
        name: 'Team Player',
        description: 'Complete 10 team adventures',
        category: AchievementCategory.social,
        rarity: AchievementRarity.uncommon,
        requirements: {'team_adventures': 10},
        rewards: {'xp': 300, 'cards': 2, 'title': 'Team Player'},
        iconPath: 'achievements/team_player.png',
        maxProgress: 10,
      ),
      Achievement(
        id: 'challenge_master',
        name: 'Challenge Master',
        description: 'Win 25 friend challenges',
        category: AchievementCategory.social,
        rarity: AchievementRarity.rare,
        requirements: {'challenges_won': 25},
        rewards: {'xp': 500, 'cards': 3, 'title': 'Challenge Master'},
        iconPath: 'achievements/challenge_master.png',
        maxProgress: 25,
      ),
      Achievement(
        id: 'community_leader',
        name: 'Community Leader',
        description: 'Help organize 5 community events',
        category: AchievementCategory.social,
        rarity: AchievementRarity.epic,
        requirements: {'community_events': 5},
        rewards: {'xp': 750, 'cards': 4, 'title': 'Community Leader'},
        iconPath: 'achievements/community_leader.png',
        maxProgress: 5,
      ),
    ];
  }

  // Create milestone achievements
  List<Achievement> _createMilestoneAchievements() {
    return [
      Achievement(
        id: 'first_week',
        name: 'Week Warrior',
        description: 'Maintain a 7-day check-in streak',
        category: AchievementCategory.milestone,
        rarity: AchievementRarity.common,
        requirements: {'check_in_streak': 7},
        rewards: {'xp': 200, 'cards': 1, 'title': 'Week Warrior'},
        iconPath: 'achievements/first_week.png',
      ),
      Achievement(
        id: 'monthly_master',
        name: 'Monthly Master',
        description: 'Maintain a 30-day check-in streak',
        category: AchievementCategory.milestone,
        rarity: AchievementRarity.rare,
        requirements: {'check_in_streak': 30},
        rewards: {'xp': 500, 'cards': 3, 'title': 'Monthly Master'},
        iconPath: 'achievements/monthly_master.png',
        prerequisites: ['first_week'],
      ),
      Achievement(
        id: 'century_club',
        name: 'Century Club',
        description: 'Complete 100 quests of any type',
        category: AchievementCategory.milestone,
        rarity: AchievementRarity.epic,
        requirements: {'total_quests': 100},
        rewards: {'xp': 1000, 'cards': 4, 'title': 'Century Master'},
        iconPath: 'achievements/century_club.png',
        maxProgress: 100,
      ),
      Achievement(
        id: 'legendary_dedication',
        name: 'Legendary Dedication',
        description: 'Maintain a 365-day check-in streak',
        category: AchievementCategory.milestone,
        rarity: AchievementRarity.mythic,
        requirements: {'check_in_streak': 365},
        rewards: {'xp': 2000, 'cards': 10, 'title': 'Eternal Guardian'},
        iconPath: 'achievements/legendary_dedication.png',
        prerequisites: ['monthly_master'],
      ),
    ];
  }

  // Create seasonal achievements
  List<Achievement> _createSeasonalAchievements() {
    return [
      Achievement(
        id: 'spring_awakening',
        name: 'Spring Awakening',
        description: 'Complete the Spring Awakening event',
        category: AchievementCategory.seasonal,
        rarity: AchievementRarity.rare,
        requirements: {'spring_event_completion': 1},
        rewards: {'xp': 500, 'cards': 3, 'title': 'Spring Champion'},
        iconPath: 'achievements/spring_awakening.png',
        isHidden: true,
      ),
      Achievement(
        id: 'summer_solstice',
        name: 'Summer Solstice',
        description: 'Complete the Solar Festival event',
        category: AchievementCategory.seasonal,
        rarity: AchievementRarity.rare,
        requirements: {'summer_event_completion': 1},
        rewards: {'xp': 500, 'cards': 3, 'title': 'Solar Champion'},
        iconPath: 'achievements/summer_solstice.png',
        isHidden: true,
      ),
      Achievement(
        id: 'four_seasons_master',
        name: 'Four Seasons Master',
        description: 'Complete all seasonal events in one year',
        category: AchievementCategory.seasonal,
        rarity: AchievementRarity.legendary,
        requirements: {
          'spring_event_completion': 1,
          'summer_event_completion': 1,
          'autumn_event_completion': 1,
          'winter_event_completion': 1,
        },
        rewards: {'xp': 1500, 'cards': 6, 'title': 'Seasonal Master'},
        iconPath: 'achievements/four_seasons_master.png',
        prerequisites: ['spring_awakening', 'summer_solstice'],
      ),
    ];
  }

  // Create special achievements
  List<Achievement> _createSpecialAchievements() {
    return [
      Achievement(
        id: 'weather_warrior',
        name: 'Weather Warrior',
        description: 'Complete quests in all weather conditions',
        category: AchievementCategory.special,
        rarity: AchievementRarity.rare,
        requirements: {
          'sunny_quests': 5,
          'rainy_quests': 5,
          'cloudy_quests': 5,
          'snowy_quests': 1,
        },
        rewards: {'xp': 600, 'cards': 3, 'title': 'Weather Warrior'},
        iconPath: 'achievements/weather_warrior.png',
      ),
      Achievement(
        id: 'night_owl',
        name: 'Night Owl',
        description: 'Complete 20 quests after sunset',
        category: AchievementCategory.special,
        rarity: AchievementRarity.uncommon,
        requirements: {'night_quests': 20},
        rewards: {'xp': 300, 'cards': 2, 'title': 'Night Owl'},
        iconPath: 'achievements/night_owl.png',
        maxProgress: 20,
      ),
      Achievement(
        id: 'early_bird',
        name: 'Early Bird',
        description: 'Complete 20 quests before sunrise',
        category: AchievementCategory.special,
        rarity: AchievementRarity.uncommon,
        requirements: {'sunrise_quests': 20},
        rewards: {'xp': 300, 'cards': 2, 'title': 'Early Bird'},
        iconPath: 'achievements/early_bird.png',
        maxProgress: 20,
      ),
      Achievement(
        id: 'lucky_number',
        name: 'Lucky Number Seven',
        description: 'Find 7 rare spawns in one day',
        category: AchievementCategory.special,
        rarity: AchievementRarity.epic,
        requirements: {'daily_rare_spawns': 7},
        rewards: {'xp': 777, 'cards': 7, 'title': 'Lucky Finder'},
        iconPath: 'achievements/lucky_number.png',
        isHidden: true,
      ),
    ];
  }

  // Create collection achievements
  List<Achievement> _createCollectionAchievements() {
    return [
      Achievement(
        id: 'card_collector',
        name: 'Card Collector',
        description: 'Collect 50 unique cards from adventures',
        category: AchievementCategory.collection,
        rarity: AchievementRarity.uncommon,
        requirements: {'unique_cards': 50},
        rewards: {'xp': 300, 'cards': 3, 'title': 'Card Collector'},
        iconPath: 'achievements/card_collector.png',
        maxProgress: 50,
      ),
      Achievement(
        id: 'treasure_hunter',
        name: 'Treasure Hunter',
        description: 'Find 100 treasure chests',
        category: AchievementCategory.collection,
        rarity: AchievementRarity.rare,
        requirements: {'treasure_chests': 100},
        rewards: {'xp': 500, 'cards': 4, 'title': 'Treasure Hunter'},
        iconPath: 'achievements/treasure_hunter.png',
        maxProgress: 100,
      ),
      Achievement(
        id: 'master_collector',
        name: 'Master Collector',
        description: 'Collect 500 unique items from adventures',
        category: AchievementCategory.collection,
        rarity: AchievementRarity.legendary,
        requirements: {'unique_items': 500},
        rewards: {'xp': 1000, 'cards': 5, 'title': 'Master Collector'},
        iconPath: 'achievements/master_collector.png',
        maxProgress: 500,
      ),
    ];
  }

  // Create combat achievements
  List<Achievement> _createCombatAchievements() {
    return [
      Achievement(
        id: 'first_victory',
        name: 'First Victory',
        description: 'Win your first battle encounter',
        category: AchievementCategory.combat,
        rarity: AchievementRarity.common,
        requirements: {'battles_won': 1},
        rewards: {'xp': 100, 'cards': 1, 'title': 'Warrior'},
        iconPath: 'achievements/first_victory.png',
      ),
      Achievement(
        id: 'battle_tested',
        name: 'Battle Tested',
        description: 'Win 50 battle encounters',
        category: AchievementCategory.combat,
        rarity: AchievementRarity.rare,
        requirements: {'battles_won': 50},
        rewards: {'xp': 500, 'cards': 3, 'title': 'Battle Tested'},
        iconPath: 'achievements/battle_tested.png',
        maxProgress: 50,
      ),
      Achievement(
        id: 'legendary_warrior',
        name: 'Legendary Warrior',
        description: 'Defeat a legendary boss encounter',
        category: AchievementCategory.combat,
        rarity: AchievementRarity.legendary,
        requirements: {'legendary_bosses_defeated': 1},
        rewards: {'xp': 1000, 'cards': 5, 'title': 'Legendary Warrior'},
        iconPath: 'achievements/legendary_warrior.png',
        isHidden: true,
      ),
    ];
  }

  // Update achievement progress
  Future<void> updateProgress(String achievementId, Map<String, dynamic> progressData) async {
    final achievementIndex = _achievements.indexWhere((a) => a.id == achievementId);
    if (achievementIndex == -1) return;

    final achievement = _achievements[achievementIndex];
    if (achievement.isCompleted && !achievement.isRepeatable) return;

    // Update progress
    final updatedProgress = Map<String, dynamic>.from(achievement.progress);
    progressData.forEach((key, value) {
      updatedProgress[key] = (updatedProgress[key] ?? 0) + value;
    });

    // Check if achievement is completed
    bool isCompleted = _checkAchievementCompletion(achievement, updatedProgress);
    
    final updatedAchievement = achievement.copyWith(
      progress: updatedProgress,
      isCompleted: isCompleted,
      completedAt: isCompleted ? DateTime.now() : achievement.completedAt,
    );

    _achievements[achievementIndex] = updatedAchievement;

    if (isCompleted && !achievement.isCompleted) {
      await _handleAchievementCompletion(updatedAchievement);
    }

    await _savePlayerProgress();
    _achievementsController.add(_achievements);
  }

  // Check if achievement requirements are met
  bool _checkAchievementCompletion(Achievement achievement, Map<String, dynamic> progress) {
    for (final requirement in achievement.requirements.entries) {
      final currentProgress = progress[requirement.key] ?? 0;
      if (currentProgress < requirement.value) {
        return false;
      }
    }

    // Check prerequisites
    for (final prerequisiteId in achievement.prerequisites) {
      final prerequisite = _achievements.firstWhere((a) => a.id == prerequisiteId);
      if (!prerequisite.isCompleted) {
        return false;
      }
    }

    return true;
  }

  // Handle achievement completion
  Future<void> _handleAchievementCompletion(Achievement achievement) async {
    // Award rewards
    await _awardAchievementRewards(achievement);

    // Create badge
    final badge = Badge(
      id: 'badge_${achievement.id}',
      name: achievement.name,
      description: achievement.description,
      iconPath: achievement.iconPath,
      rarity: achievement.rarity,
      earnedAt: DateTime.now(),
      earnedFor: achievement.description,
    );

    _earnedBadges.add(badge);

    // Notify listeners
    _achievementUnlockedController.add(achievement);
    _badgeEarnedController.add(badge);

    await _savePlayerProgress();
  }

  // Award achievement rewards
  Future<void> _awardAchievementRewards(Achievement achievement) async {
    final rewards = achievement.rewards;
    
    // Award XP
    if (rewards['xp'] != null) {
      final progressionService = AdventureProgressionService();
      await progressionService.awardAdventureXP(
        rewards['xp'],
        'Achievement: ${achievement.name}',
      );
    }

    // Award cards, titles, etc. would integrate with your game systems
    print('Awarded achievement rewards: ${achievement.name}');
  }

  // Get achievements by category
  List<Achievement> getAchievementsByCategory(AchievementCategory category) {
    return _achievements.where((achievement) => 
        achievement.category == category && 
        (!achievement.isHidden || achievement.isCompleted)
    ).toList();
  }

  // Get completed achievements
  List<Achievement> getCompletedAchievements() {
    return _achievements.where((achievement) => achievement.isCompleted).toList();
  }

  // Get earned badges
  List<Badge> getEarnedBadges() {
    return _earnedBadges;
  }

  // Get achievement completion stats
  Map<String, dynamic> getCompletionStats() {
    final total = _achievements.where((a) => !a.isHidden).length;
    final completed = _achievements.where((a) => a.isCompleted && !a.isHidden).length;
    
    final categoriesStats = <String, Map<String, int>>{};
    for (final category in AchievementCategory.values) {
      final categoryAchievements = _achievements.where((a) => 
          a.category == category && !a.isHidden).toList();
      final categoryCompleted = categoryAchievements.where((a) => a.isCompleted).length;
      
      categoriesStats[category.toString()] = {
        'total': categoryAchievements.length,
        'completed': categoryCompleted,
      };
    }

    return {
      'total_achievements': total,
      'completed_achievements': completed,
      'completion_percentage': total > 0 ? (completed / total * 100).round() : 0,
      'total_badges': _earnedBadges.length,
      'categories': categoriesStats,
    };
  }

  // Auto-track common activities
  Future<void> trackSteps(int steps) async {
    await updateProgress('first_steps', {'steps': steps});
    await updateProgress('step_master', {'daily_steps': steps});
  }

  Future<void> trackLocationVisit(String locationType) async {
    await updateProgress('location_explorer', {'unique_locations': 1});
    await updateProgress('territory_master', {locationType: 1});
  }

  Future<void> trackQuestCompletion(String questType) async {
    await updateProgress('century_club', {'total_quests': 1});
    
    if (questType == 'exploration') {
      await updateProgress('legendary_explorer', {'exploration_quests': 1});
    }
  }

  Future<void> trackBattleVictory() async {
    await updateProgress('first_victory', {'battles_won': 1});
    await updateProgress('battle_tested', {'battles_won': 1});
  }

  Future<void> trackCheckInStreak(int streak) async {
    await updateProgress('first_week', {'check_in_streak': streak});
    await updateProgress('monthly_master', {'check_in_streak': streak});
    await updateProgress('legendary_dedication', {'check_in_streak': streak});
  }

  // Data persistence
  Future<void> _savePlayerProgress() async {
    if (_playerId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final achievementsJson = jsonEncode(_achievements.map((a) => a.toJson()).toList());
      final badgesJson = jsonEncode(_earnedBadges.map((b) => b.toJson()).toList());
      
      await prefs.setString('achievements_$_playerId', achievementsJson);
      await prefs.setString('badges_$_playerId', badgesJson);
    } catch (e) {
      print('Error saving achievement progress: $e');
    }
  }

  Future<void> _loadPlayerProgress() async {
    if (_playerId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final achievementsJson = prefs.getString('achievements_$_playerId');
      final badgesJson = prefs.getString('badges_$_playerId');

      if (achievementsJson != null) {
        final achievementsList = jsonDecode(achievementsJson) as List;
        final savedAchievements = achievementsList
            .map((json) => Achievement.fromJson(json))
            .toList();

        // Merge with current achievements (in case new ones were added)
        for (final saved in savedAchievements) {
          final index = _achievements.indexWhere((a) => a.id == saved.id);
          if (index != -1) {
            _achievements[index] = saved;
          }
        }
      }

      if (badgesJson != null) {
        final badgesList = jsonDecode(badgesJson) as List;
        _earnedBadges = badgesList
            .map((json) => Badge.fromJson(json))
            .toList();
      }
    } catch (e) {
      print('Error loading achievement progress: $e');
    }
  }

  // Cleanup
  void dispose() {
    _achievementUnlockedController.close();
    _badgeEarnedController.close();
    _achievementsController.close();
  }
}