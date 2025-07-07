import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/adventure_system.dart';
import 'adventure_progression_service.dart';

enum DifficultyLevel {
  beginner,    // 0-20% difficulty
  easy,        // 20-40% difficulty  
  normal,      // 40-60% difficulty
  hard,        // 60-80% difficulty
  expert,      // 80-95% difficulty
  master,      // 95-100% difficulty
}

enum PlayerSkillType {
  exploration,
  fitness,
  combat,
  social,
  consistency,
  progression,
}

enum ContentPreference {
  exploration_focused,
  fitness_focused,
  social_focused,
  achievement_focused,
  casual_play,
  hardcore_play,
  variety_seeker,
}

class PlayerSkillProfile {
  final Map<PlayerSkillType, double> skillLevels; // 0.0 to 1.0
  final Map<PlayerSkillType, List<double>> recentPerformance;
  final Map<PlayerSkillType, DateTime> lastUpdate;
  final double overallSkillLevel;
  final List<ContentPreference> preferences;
  final Map<String, double> activitySuccessRates;
  final Map<String, int> completionTimes;

  PlayerSkillProfile({
    Map<PlayerSkillType, double>? skillLevels,
    Map<PlayerSkillType, List<double>>? recentPerformance,
    Map<PlayerSkillType, DateTime>? lastUpdate,
    this.overallSkillLevel = 0.0,
    List<ContentPreference>? preferences,
    Map<String, double>? activitySuccessRates,
    Map<String, int>? completionTimes,
  }) : skillLevels = skillLevels ?? {for (var skill in PlayerSkillType.values) skill: 0.0},
       recentPerformance = recentPerformance ?? {for (var skill in PlayerSkillType.values) skill: []},
       lastUpdate = lastUpdate ?? {},
       preferences = preferences ?? [ContentPreference.casual_play],
       activitySuccessRates = activitySuccessRates ?? {},
       completionTimes = completionTimes ?? {};

  factory PlayerSkillProfile.fromJson(Map<String, dynamic> json) {
    return PlayerSkillProfile(
      skillLevels: (json['skillLevels'] as Map?)?.map((key, value) => 
          MapEntry(PlayerSkillType.values[int.parse(key)], value.toDouble())) ?? {},
      recentPerformance: (json['recentPerformance'] as Map?)?.map((key, value) => 
          MapEntry(PlayerSkillType.values[int.parse(key)], List<double>.from(value))) ?? {},
      lastUpdate: (json['lastUpdate'] as Map?)?.map((key, value) => 
          MapEntry(PlayerSkillType.values[int.parse(key)], DateTime.parse(value))) ?? {},
      overallSkillLevel: json['overallSkillLevel']?.toDouble() ?? 0.0,
      preferences: (json['preferences'] as List?)?.map((index) => 
          ContentPreference.values[index]).toList() ?? [],
      activitySuccessRates: (json['activitySuccessRates'] as Map?)?.map((key, value) => 
          MapEntry(key.toString(), value.toDouble())) ?? {},
      completionTimes: (json['completionTimes'] as Map?)?.map((key, value) => 
          MapEntry(key.toString(), value as int)) ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skillLevels': skillLevels.map((key, value) => MapEntry(key.index.toString(), value)),
      'recentPerformance': recentPerformance.map((key, value) => MapEntry(key.index.toString(), value)),
      'lastUpdate': lastUpdate.map((key, value) => MapEntry(key.index.toString(), value.toIso8601String())),
      'overallSkillLevel': overallSkillLevel,
      'preferences': preferences.map((pref) => pref.index).toList(),
      'activitySuccessRates': activitySuccessRates,
      'completionTimes': completionTimes,
    };
  }
}

class DifficultyParameters {
  final DifficultyLevel level;
  final double questComplexityMultiplier;
  final double spawnRateMultiplier;
  final double rewardMultiplier;
  final double xpMultiplier;
  final Map<String, double> typeSpecificModifiers;
  final double failureToleranceRate;
  final int recommendedSessionTime; // minutes

  DifficultyParameters({
    required this.level,
    required this.questComplexityMultiplier,
    required this.spawnRateMultiplier,
    required this.rewardMultiplier,
    required this.xpMultiplier,
    Map<String, double>? typeSpecificModifiers,
    required this.failureToleranceRate,
    required this.recommendedSessionTime,
  }) : typeSpecificModifiers = typeSpecificModifiers ?? {};

  factory DifficultyParameters.fromLevel(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.beginner:
        return DifficultyParameters(
          level: level,
          questComplexityMultiplier: 0.5,
          spawnRateMultiplier: 1.5,
          rewardMultiplier: 1.2,
          xpMultiplier: 1.1,
          typeSpecificModifiers: {
            'exploration': 0.7,
            'fitness': 0.6,
            'combat': 0.5,
          },
          failureToleranceRate: 0.8,
          recommendedSessionTime: 15,
        );
      case DifficultyLevel.easy:
        return DifficultyParameters(
          level: level,
          questComplexityMultiplier: 0.7,
          spawnRateMultiplier: 1.3,
          rewardMultiplier: 1.1,
          xpMultiplier: 1.05,
          typeSpecificModifiers: {
            'exploration': 0.8,
            'fitness': 0.7,
            'combat': 0.6,
          },
          failureToleranceRate: 0.7,
          recommendedSessionTime: 20,
        );
      case DifficultyLevel.normal:
        return DifficultyParameters(
          level: level,
          questComplexityMultiplier: 1.0,
          spawnRateMultiplier: 1.0,
          rewardMultiplier: 1.0,
          xpMultiplier: 1.0,
          typeSpecificModifiers: {},
          failureToleranceRate: 0.5,
          recommendedSessionTime: 30,
        );
      case DifficultyLevel.hard:
        return DifficultyParameters(
          level: level,
          questComplexityMultiplier: 1.3,
          spawnRateMultiplier: 0.8,
          rewardMultiplier: 1.2,
          xpMultiplier: 1.1,
          typeSpecificModifiers: {
            'exploration': 1.2,
            'fitness': 1.3,
            'combat': 1.4,
          },
          failureToleranceRate: 0.3,
          recommendedSessionTime: 45,
        );
      case DifficultyLevel.expert:
        return DifficultyParameters(
          level: level,
          questComplexityMultiplier: 1.6,
          spawnRateMultiplier: 0.6,
          rewardMultiplier: 1.4,
          xpMultiplier: 1.2,
          typeSpecificModifiers: {
            'exploration': 1.5,
            'fitness': 1.6,
            'combat': 1.7,
          },
          failureToleranceRate: 0.2,
          recommendedSessionTime: 60,
        );
      case DifficultyLevel.master:
        return DifficultyParameters(
          level: level,
          questComplexityMultiplier: 2.0,
          spawnRateMultiplier: 0.4,
          rewardMultiplier: 1.6,
          xpMultiplier: 1.3,
          typeSpecificModifiers: {
            'exploration': 1.8,
            'fitness': 2.0,
            'combat': 2.2,
          },
          failureToleranceRate: 0.1,
          recommendedSessionTime: 90,
        );
    }
  }
}

class PersonalizedContent {
  final List<Quest> recommendedQuests;
  final List<POI> suggestedLocations;
  final Map<String, double> contentWeights;
  final List<String> personalizedTips;
  final Map<String, dynamic> adaptiveSettings;
  final DateTime generatedAt;

  PersonalizedContent({
    required this.recommendedQuests,
    required this.suggestedLocations,
    required this.contentWeights,
    required this.personalizedTips,
    required this.adaptiveSettings,
    required this.generatedAt,
  });
}

class DynamicDifficultyService {
  static final DynamicDifficultyService _instance = DynamicDifficultyService._internal();
  factory DynamicDifficultyService() => _instance;
  DynamicDifficultyService._internal();

  final StreamController<DifficultyParameters> _difficultyController = StreamController.broadcast();
  final StreamController<PersonalizedContent> _contentController = StreamController.broadcast();

  Stream<DifficultyParameters> get difficultyStream => _difficultyController.stream;
  Stream<PersonalizedContent> get contentStream => _contentController.stream;

  PlayerSkillProfile? _skillProfile;
  DifficultyParameters? _currentDifficulty;
  PersonalizedContent? _currentContent;
  String? _playerId;
  Timer? _adaptationTimer;

  // Initialize dynamic difficulty system
  Future<void> initialize(String playerId) async {
    _playerId = playerId;
    await _loadPlayerData();
    
    if (_skillProfile == null) {
      _skillProfile = PlayerSkillProfile();
      await _savePlayerData();
    }

    _currentDifficulty = _calculateOptimalDifficulty();
    _currentContent = await _generatePersonalizedContent();

    _difficultyController.add(_currentDifficulty!);
    _contentController.add(_currentContent!);

    _startAdaptationTimer();
  }

  // Track player performance for adaptation
  Future<void> trackPerformance({
    required PlayerSkillType skillType,
    required double performance, // 0.0 to 1.0
    required String activityType,
    required bool wasSuccessful,
    required int completionTimeMs,
  }) async {
    if (_skillProfile == null) return;

    // Update recent performance
    final recentPerf = List<double>.from(_skillProfile!.recentPerformance[skillType] ?? []);
    recentPerf.add(performance);
    if (recentPerf.length > 10) recentPerf.removeAt(0); // Keep last 10 performances

    // Calculate new skill level (weighted average)
    final currentSkill = _skillProfile!.skillLevels[skillType] ?? 0.0;
    final newSkill = (currentSkill * 0.8) + (performance * 0.2);

    // Update activity success rates
    final successKey = '${activityType}_success';
    final attempts = _skillProfile!.activitySuccessRates['${activityType}_attempts'] ?? 0.0;
    final successes = _skillProfile!.activitySuccessRates[successKey] ?? 0.0;
    
    final newAttempts = attempts + 1;
    final newSuccesses = successes + (wasSuccessful ? 1 : 0);
    final newSuccessRate = newSuccesses / newAttempts;

    // Update completion times
    final timeKey = '${activityType}_time';
    final avgTime = _skillProfile!.completionTimes[timeKey] ?? completionTimeMs;
    final newAvgTime = ((avgTime * attempts) + completionTimeMs) ~/ newAttempts;

    // Create updated profile
    _skillProfile = PlayerSkillProfile(
      skillLevels: {
        ..._skillProfile!.skillLevels,
        skillType: newSkill.clamp(0.0, 1.0),
      },
      recentPerformance: {
        ..._skillProfile!.recentPerformance,
        skillType: recentPerf,
      },
      lastUpdate: {
        ..._skillProfile!.lastUpdate,
        skillType: DateTime.now(),
      },
      overallSkillLevel: _calculateOverallSkill({
        ..._skillProfile!.skillLevels,
        skillType: newSkill.clamp(0.0, 1.0),
      }),
      preferences: _skillProfile!.preferences,
      activitySuccessRates: {
        ..._skillProfile!.activitySuccessRates,
        successKey: newSuccessRate,
        '${activityType}_attempts': newAttempts,
      },
      completionTimes: {
        ..._skillProfile!.completionTimes,
        timeKey: newAvgTime,
      },
    );

    await _savePlayerData();
    await _checkForDifficultyAdjustment();
  }

  // Track player preferences based on behavior
  Future<void> trackPreferences({
    required String activityType,
    required double engagementLevel, // 0.0 to 1.0
    required int sessionDuration,
  }) async {
    if (_skillProfile == null) return;

    // Analyze preferences based on engagement and time spent
    final newPreferences = List<ContentPreference>.from(_skillProfile!.preferences);

    if (activityType.contains('exploration') && engagementLevel > 0.7) {
      if (!newPreferences.contains(ContentPreference.exploration_focused)) {
        newPreferences.add(ContentPreference.exploration_focused);
      }
    }

    if (activityType.contains('fitness') && engagementLevel > 0.7) {
      if (!newPreferences.contains(ContentPreference.fitness_focused)) {
        newPreferences.add(ContentPreference.fitness_focused);
      }
    }

    if (activityType.contains('social') && engagementLevel > 0.7) {
      if (!newPreferences.contains(ContentPreference.social_focused)) {
        newPreferences.add(ContentPreference.social_focused);
      }
    }

    // Determine play style based on session patterns
    if (sessionDuration > 60 && !newPreferences.contains(ContentPreference.hardcore_play)) {
      newPreferences.remove(ContentPreference.casual_play);
      newPreferences.add(ContentPreference.hardcore_play);
    } else if (sessionDuration < 20 && !newPreferences.contains(ContentPreference.casual_play)) {
      newPreferences.remove(ContentPreference.hardcore_play);
      newPreferences.add(ContentPreference.casual_play);
    }

    _skillProfile = PlayerSkillProfile(
      skillLevels: _skillProfile!.skillLevels,
      recentPerformance: _skillProfile!.recentPerformance,
      lastUpdate: _skillProfile!.lastUpdate,
      overallSkillLevel: _skillProfile!.overallSkillLevel,
      preferences: newPreferences,
      activitySuccessRates: _skillProfile!.activitySuccessRates,
      completionTimes: _skillProfile!.completionTimes,
    );

    await _savePlayerData();
    _currentContent = await _generatePersonalizedContent();
    _contentController.add(_currentContent!);
  }

  // Get current difficulty parameters
  DifficultyParameters getCurrentDifficulty() {
    return _currentDifficulty ?? DifficultyParameters.fromLevel(DifficultyLevel.normal);
  }

  // Get personalized content
  PersonalizedContent? getCurrentContent() {
    return _currentContent;
  }

  // Get skill profile
  PlayerSkillProfile? getSkillProfile() {
    return _skillProfile;
  }

  // Manually adjust difficulty
  Future<void> setDifficultyLevel(DifficultyLevel level) async {
    _currentDifficulty = DifficultyParameters.fromLevel(level);
    _difficultyController.add(_currentDifficulty!);
    await _savePlayerData();
  }

  // Generate adaptive quest based on current parameters
  Quest generateAdaptiveQuest({
    required QuestType baseType,
    required String location,
    GeoLocation? geoLocation,
  }) {
    if (_skillProfile == null || _currentDifficulty == null) {
      return _generateDefaultQuest(baseType, location, geoLocation);
    }

    final skillLevel = _getRelevantSkillLevel(baseType);
    final difficulty = _currentDifficulty!;
    
    // Adjust quest parameters based on skill and difficulty
    final baseXP = 100;
    final adjustedXP = (baseXP * difficulty.xpMultiplier * (1 + skillLevel)).round();
    
    final complexityMultiplier = difficulty.questComplexityMultiplier;
    final objectives = _generateAdaptiveObjectives(baseType, complexityMultiplier, skillLevel);

    return Quest(
      title: _generateAdaptiveTitle(baseType, difficulty.level),
      description: _generateAdaptiveDescription(baseType, difficulty.level),
      type: baseType,
      level: _calculateQuestLevel(skillLevel, difficulty.level),
      xpReward: adjustedXP,
      cardRewards: _generateAdaptiveRewards(skillLevel, difficulty.rewardMultiplier),
      objectives: objectives,
      location: geoLocation,
      timeLimit: _calculateTimeLimit(baseType, skillLevel),
      metadata: {
        'difficulty_level': difficulty.level.toString(),
        'adapted_for_skill': skillLevel,
        'personalized': true,
      },
    );
  }

  // Generate recommended content for session
  List<String> getSessionRecommendations() {
    if (_skillProfile == null || _currentContent == null) {
      return ['Start with a simple exploration quest to get warmed up!'];
    }

    final recommendations = <String>[];
    final profile = _skillProfile!;
    final content = _currentContent!;

    // Time-based recommendations
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour <= 10) {
      recommendations.add('🌅 Morning energy detected! Perfect time for fitness quests.');
    } else if (hour >= 17 && hour <= 20) {
      recommendations.add('🌆 Evening adventure time! Try some exploration quests.');
    }

    // Skill-based recommendations
    final lowestSkill = profile.skillLevels.entries
        .reduce((a, b) => a.value < b.value ? a : b);
    
    if (lowestSkill.value < 0.3) {
      recommendations.add('💪 Consider focusing on ${_skillTypeToString(lowestSkill.key)} to improve your overall abilities!');
    }

    // Preference-based recommendations
    if (profile.preferences.contains(ContentPreference.variety_seeker)) {
      recommendations.add('🎲 Try something new today! Mix different quest types for variety.');
    }

    // Success rate recommendations
    final bestActivity = profile.activitySuccessRates.entries
        .where((e) => e.key.endsWith('_success'))
        .fold<MapEntry<String, double>?>(null, (best, current) {
      if (best == null || current.value > best.value) return current;
      return best;
    });

    if (bestActivity != null && bestActivity.value > 0.8) {
      final activityType = bestActivity.key.replaceAll('_success', '');
      recommendations.add('⭐ You\'re excelling at $activityType! Try a harder challenge.');
    }

    return recommendations.take(3).toList();
  }

  // Private helper methods
  Future<void> _checkForDifficultyAdjustment() async {
    if (_skillProfile == null) return;

    final currentDifficultyLevel = _currentDifficulty?.level ?? DifficultyLevel.normal;
    final optimalDifficultyLevel = _calculateOptimalDifficultyLevel();

    if (currentDifficultyLevel != optimalDifficultyLevel) {
      _currentDifficulty = DifficultyParameters.fromLevel(optimalDifficultyLevel);
      _difficultyController.add(_currentDifficulty!);
      print('Difficulty adjusted to: $optimalDifficultyLevel');
    }
  }

  DifficultyParameters _calculateOptimalDifficulty() {
    if (_skillProfile == null) {
      return DifficultyParameters.fromLevel(DifficultyLevel.normal);
    }

    return DifficultyParameters.fromLevel(_calculateOptimalDifficultyLevel());
  }

  DifficultyLevel _calculateOptimalDifficultyLevel() {
    if (_skillProfile == null) return DifficultyLevel.normal;

    final overallSkill = _skillProfile!.overallSkillLevel;
    final hasHardcorePreference = _skillProfile!.preferences.contains(ContentPreference.hardcore_play);
    final hasCasualPreference = _skillProfile!.preferences.contains(ContentPreference.casual_play);

    // Adjust based on preferences
    var targetDifficulty = overallSkill;
    if (hasHardcorePreference) targetDifficulty += 0.2;
    if (hasCasualPreference) targetDifficulty -= 0.2;

    targetDifficulty = targetDifficulty.clamp(0.0, 1.0);

    if (targetDifficulty < 0.2) return DifficultyLevel.beginner;
    if (targetDifficulty < 0.4) return DifficultyLevel.easy;
    if (targetDifficulty < 0.6) return DifficultyLevel.normal;
    if (targetDifficulty < 0.8) return DifficultyLevel.hard;
    if (targetDifficulty < 0.95) return DifficultyLevel.expert;
    return DifficultyLevel.master;
  }

  double _calculateOverallSkill(Map<PlayerSkillType, double> skillLevels) {
    if (skillLevels.isEmpty) return 0.0;
    
    final totalSkill = skillLevels.values.fold(0.0, (sum, skill) => sum + skill);
    return totalSkill / skillLevels.length;
  }

  Future<PersonalizedContent> _generatePersonalizedContent() async {
    if (_skillProfile == null) {
      return PersonalizedContent(
        recommendedQuests: [],
        suggestedLocations: [],
        contentWeights: {},
        personalizedTips: [],
        adaptiveSettings: {},
        generatedAt: DateTime.now(),
      );
    }

    final profile = _skillProfile!;
    final contentWeights = <String, double>{};

    // Calculate content weights based on preferences
    for (final preference in profile.preferences) {
      switch (preference) {
        case ContentPreference.exploration_focused:
          contentWeights['exploration'] = (contentWeights['exploration'] ?? 0.0) + 0.4;
          break;
        case ContentPreference.fitness_focused:
          contentWeights['fitness'] = (contentWeights['fitness'] ?? 0.0) + 0.4;
          break;
        case ContentPreference.social_focused:
          contentWeights['social'] = (contentWeights['social'] ?? 0.0) + 0.4;
          break;
        case ContentPreference.achievement_focused:
          contentWeights['achievement'] = (contentWeights['achievement'] ?? 0.0) + 0.3;
          break;
        case ContentPreference.variety_seeker:
          contentWeights['variety'] = (contentWeights['variety'] ?? 0.0) + 0.3;
          break;
        default:
          break;
      }
    }

    // Normalize weights
    final totalWeight = contentWeights.values.fold(0.0, (sum, weight) => sum + weight);
    if (totalWeight > 0) {
      contentWeights.updateAll((key, value) => value / totalWeight);
    }

    return PersonalizedContent(
      recommendedQuests: await _generateRecommendedQuests(contentWeights),
      suggestedLocations: _generateSuggestedLocations(contentWeights),
      contentWeights: contentWeights,
      personalizedTips: _generatePersonalizedTips(),
      adaptiveSettings: _generateAdaptiveSettings(),
      generatedAt: DateTime.now(),
    );
  }

  Future<List<Quest>> _generateRecommendedQuests(Map<String, double> weights) async {
    final quests = <Quest>[];
    
    // Generate quests based on content weights
    if ((weights['exploration'] ?? 0.0) > 0.3) {
      quests.add(_generateAdaptiveExplorationQuest());
    }
    
    if ((weights['fitness'] ?? 0.0) > 0.3) {
      quests.add(_generateAdaptiveFitnessQuest());
    }
    
    if ((weights['social'] ?? 0.0) > 0.3) {
      quests.add(_generateAdaptiveSocialQuest());
    }

    return quests;
  }

  List<POI> _generateSuggestedLocations(Map<String, double> weights) {
    // This would generate POIs based on player preferences
    return [];
  }

  List<String> _generatePersonalizedTips() {
    if (_skillProfile == null) return [];

    final tips = <String>[];
    final profile = _skillProfile!;

    // Skill-based tips
    final lowestSkill = profile.skillLevels.entries
        .reduce((a, b) => a.value < b.value ? a : b);

    switch (lowestSkill.key) {
      case PlayerSkillType.exploration:
        tips.add('🗺️ Try visiting new locations to improve your exploration skills!');
        break;
      case PlayerSkillType.fitness:
        tips.add('💪 Start with shorter fitness goals and gradually increase intensity.');
        break;
      case PlayerSkillType.combat:
        tips.add('⚔️ Practice battle encounters to improve your combat strategy.');
        break;
      case PlayerSkillType.social:
        tips.add('👥 Connect with other adventurers to enhance your social skills.');
        break;
      case PlayerSkillType.consistency:
        tips.add('📅 Try to maintain a regular adventure schedule for better progress.');
        break;
      case PlayerSkillType.progression:
        tips.add('📈 Focus on completing objectives to improve your progression rate.');
        break;
    }

    return tips;
  }

  Map<String, dynamic> _generateAdaptiveSettings() {
    if (_skillProfile == null) return {};

    final profile = _skillProfile!;
    final settings = <String, dynamic>{};

    // Adjust spawn rates based on skill
    settings['spawn_rate_multiplier'] = 0.8 + (profile.overallSkillLevel * 0.4);
    
    // Adjust quest frequency
    if (profile.preferences.contains(ContentPreference.casual_play)) {
      settings['quest_frequency'] = 'low';
      settings['session_length_target'] = 15;
    } else if (profile.preferences.contains(ContentPreference.hardcore_play)) {
      settings['quest_frequency'] = 'high';
      settings['session_length_target'] = 60;
    } else {
      settings['quest_frequency'] = 'normal';
      settings['session_length_target'] = 30;
    }

    return settings;
  }

  double _getRelevantSkillLevel(QuestType questType) {
    if (_skillProfile == null) return 0.0;

    switch (questType) {
      case QuestType.exploration:
        return _skillProfile!.skillLevels[PlayerSkillType.exploration] ?? 0.0;
      case QuestType.fitness:
        return _skillProfile!.skillLevels[PlayerSkillType.fitness] ?? 0.0;
      case QuestType.battle:
        return _skillProfile!.skillLevels[PlayerSkillType.combat] ?? 0.0;
      case QuestType.social:
        return _skillProfile!.skillLevels[PlayerSkillType.social] ?? 0.0;
      default:
        return _skillProfile!.overallSkillLevel;
    }
  }

  List<QuestObjective> _generateAdaptiveObjectives(
    QuestType type, 
    double complexityMultiplier, 
    double skillLevel,
  ) {
    final baseObjectives = 1 + (complexityMultiplier * 2).round();
    final objectives = <QuestObjective>[];

    for (int i = 0; i < baseObjectives; i++) {
      objectives.add(QuestObjective(
        title: 'Adaptive Objective ${i + 1}',
        description: 'Complete this objective adapted to your skill level',
        type: type.toString(),
        requirements: _generateAdaptiveRequirements(type, skillLevel),
        xpReward: (50 * (1 + skillLevel)).round(),
      ));
    }

    return objectives;
  }

  Map<String, dynamic> _generateAdaptiveRequirements(QuestType type, double skillLevel) {
    switch (type) {
      case QuestType.exploration:
        return {
          'distance': (1000 * (1 + skillLevel)).round(),
          'locations': (2 * (1 + skillLevel)).round(),
        };
      case QuestType.fitness:
        return {
          'steps': (3000 * (1 + skillLevel)).round(),
          'calories': (100 * (1 + skillLevel)).round(),
        };
      case QuestType.battle:
        return {
          'encounters': (2 * (1 + skillLevel)).round(),
          'wins': (1 * (1 + skillLevel * 0.5)).round(),
        };
      default:
        return {'generic': (10 * (1 + skillLevel)).round()};
    }
  }

  String _generateAdaptiveTitle(QuestType type, DifficultyLevel difficulty) {
    final difficultyName = difficulty.toString().split('.').last;
    final typeName = type.toString().split('.').last;
    return '$difficultyName ${typeName.capitalize()} Challenge';
  }

  String _generateAdaptiveDescription(QuestType type, DifficultyLevel difficulty) {
    return 'An adaptive ${type.toString().split('.').last} quest tailored to ${difficulty.toString().split('.').last} difficulty level.';
  }

  int _calculateQuestLevel(double skillLevel, DifficultyLevel difficulty) {
    final baseLevel = 1 + (skillLevel * 5).round();
    final difficultyBonus = difficulty.index;
    return baseLevel + difficultyBonus;
  }

  List<String> _generateAdaptiveRewards(double skillLevel, double rewardMultiplier) {
    final baseRewards = ['basic_card'];
    final rewardCount = (1 + (skillLevel * rewardMultiplier)).round();
    
    final rewards = <String>[];
    for (int i = 0; i < rewardCount; i++) {
      rewards.add('adaptive_reward_$i');
    }
    
    return rewards;
  }

  int? _calculateTimeLimit(QuestType type, double skillLevel) {
    switch (type) {
      case QuestType.fitness:
        return (3600 * (2 - skillLevel)).round(); // 1-2 hours based on skill
      case QuestType.exploration:
        return (7200 * (2 - skillLevel)).round(); // 2-4 hours based on skill
      default:
        return null;
    }
  }

  Quest _generateDefaultQuest(QuestType type, String location, GeoLocation? geoLocation) {
    return Quest(
      title: 'Default ${type.toString().split('.').last} Quest',
      description: 'A standard quest at $location',
      type: type,
      level: 1,
      xpReward: 100,
      cardRewards: ['basic_card'],
      objectives: [
        QuestObjective(
          title: 'Complete objective',
          description: 'Finish this basic objective',
          type: 'default',
          requirements: {'target': 1},
          xpReward: 50,
        ),
      ],
      location: geoLocation,
    );
  }

  Quest _generateAdaptiveExplorationQuest() {
    return generateAdaptiveQuest(
      baseType: QuestType.exploration,
      location: 'Nearby Area',
    );
  }

  Quest _generateAdaptiveFitnessQuest() {
    return generateAdaptiveQuest(
      baseType: QuestType.fitness,
      location: 'Current Location',
    );
  }

  Quest _generateAdaptiveSocialQuest() {
    return generateAdaptiveQuest(
      baseType: QuestType.social,
      location: 'Community',
    );
  }

  String _skillTypeToString(PlayerSkillType type) {
    return type.toString().split('.').last;
  }

  void _startAdaptationTimer() {
    _adaptationTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _checkForDifficultyAdjustment();
    });
  }

  // Data persistence
  Future<void> _savePlayerData() async {
    if (_playerId == null || _skillProfile == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = jsonEncode(_skillProfile!.toJson());
      final difficultyJson = _currentDifficulty != null 
          ? jsonEncode({'level': _currentDifficulty!.level.index})
          : null;

      await prefs.setString('skill_profile_$_playerId', profileJson);
      if (difficultyJson != null) {
        await prefs.setString('difficulty_$_playerId', difficultyJson);
      }
    } catch (e) {
      print('Error saving player data: $e');
    }
  }

  Future<void> _loadPlayerData() async {
    if (_playerId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('skill_profile_$_playerId');
      final difficultyJson = prefs.getString('difficulty_$_playerId');

      if (profileJson != null) {
        final profileData = jsonDecode(profileJson);
        _skillProfile = PlayerSkillProfile.fromJson(profileData);
      }

      if (difficultyJson != null) {
        final difficultyData = jsonDecode(difficultyJson);
        final level = DifficultyLevel.values[difficultyData['level'] ?? 2];
        _currentDifficulty = DifficultyParameters.fromLevel(level);
      }
    } catch (e) {
      print('Error loading player data: $e');
    }
  }

  // Cleanup
  void dispose() {
    _difficultyController.close();
    _contentController.close();
    _adaptationTimer?.cancel();
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}