import 'dart:async';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quest_model.dart';
import '../services/quest_service.dart';
import '../services/agents/fitness_tracking_agent.dart';
import '../services/event_bus.dart';

/// Enhanced Fitness Quest Service
/// Builds upon existing quest system to create personalized fitness goal-based quests
class EnhancedFitnessQuestService {
  static const String version = '1.0.0';
  
  final QuestService _questService;
  final FitnessTrackingAgent _fitnessAgent;
  final SharedPreferences _prefs;
  
  // Fitness goal tracking
  final Map<String, FitnessGoal> _userFitnessGoals = {};
  final Map<String, List<Quest>> _personalizedQuests = {};
  final Map<String, FitnessLevel> _userFitnessLevels = {};
  
  // Quest generation parameters
  static const Map<String, Map<String, dynamic>> questTemplates = {
    'step_challenge': {
      'baseSteps': 5000,
      'maxSteps': 20000,
      'stepIncrement': 1000,
      'expReward': 150,
      'goldReward': 75,
    },
    'distance_adventure': {
      'baseDistance': 1609, // 1 mile in meters
      'maxDistance': 8047, // 5 miles in meters
      'distanceIncrement': 804, // 0.5 mile increment
      'expReward': 200,
      'goldReward': 100,
    },
    'time_trial': {
      'baseMinutes': 15,
      'maxMinutes': 60,
      'timeIncrement': 5,
      'expReward': 120,
      'goldReward': 60,
    },
    'calorie_burn': {
      'baseCalories': 200,
      'maxCalories': 800,
      'calorieIncrement': 100,
      'expReward': 180,
      'goldReward': 90,
    },
  };

  EnhancedFitnessQuestService({
    required QuestService questService,
    required FitnessTrackingAgent fitnessAgent,
    required SharedPreferences prefs,
  }) : _questService = questService,
       _fitnessAgent = fitnessAgent,
       _prefs = prefs;

  /// Initialize the enhanced fitness quest service
  Future<void> initialize(String userId) async {
    await _loadUserFitnessGoals(userId);
    await _loadUserFitnessLevel(userId);
    await _generateInitialPersonalizedQuests(userId);
  }

  /// Set or update user fitness goals
  Future<void> setFitnessGoal({
    required String userId,
    required FitnessGoalType type,
    required int targetValue,
    required String timeframe,
    String? customName,
  }) async {
    final goal = FitnessGoal(
      id: '${type.name}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      type: type,
      targetValue: targetValue,
      currentValue: 0,
      timeframe: timeframe,
      customName: customName,
      createdAt: DateTime.now(),
      isActive: true,
    );
    
    _userFitnessGoals[userId] = goal;
    await _saveFitnessGoals();
    
    // Generate quests based on new goal
    await _generateQuestsForGoal(userId, goal);
    
    // Publish event
    EventBus.instance.publish(AgentEvent(
      id: 'fitness_goal_set',
      type: 'fitness_goal_updated',
      agentId: 'enhanced_fitness_quest',
      data: {
        'userId': userId,
        'goal': goal.toJson(),
      },
    ));
  }

  /// Generate personalized fitness quests based on user goals and fitness level
  Future<List<Quest>> generatePersonalizedFitnessQuests({
    required String userId,
    required Position? userLocation,
  }) async {
    final userGoal = _userFitnessGoals[userId];
    final fitnessLevel = _userFitnessLevels[userId] ?? FitnessLevel.beginner;
    final currentStats = _fitnessAgent.getCurrentStats();
    
    final quests = <Quest>[];
    
    if (userGoal != null && userGoal.isActive) {
      // Generate quests based on specific fitness goal
      quests.addAll(await _generateGoalBasedQuests(userId, userGoal, userLocation));
    }
    
    // Generate adaptive quests based on fitness level
    quests.addAll(await _generateAdaptiveQuests(userId, fitnessLevel, currentStats, userLocation));
    
    // Generate progressive difficulty quests
    quests.addAll(await _generateProgressiveQuests(userId, fitnessLevel, userLocation));
    
    // Generate milestone celebration quests
    quests.addAll(await _generateMilestoneQuests(userId, currentStats));
    
    _personalizedQuests[userId] = quests;
    return quests;
  }

  /// Generate quests based on specific fitness goals
  Future<List<Quest>> _generateGoalBasedQuests(
    String userId,
    FitnessGoal goal,
    Position? userLocation,
  ) async {
    final quests = <Quest>[];
    
    switch (goal.type) {
      case FitnessGoalType.stepCount:
        quests.addAll(await _generateStepBasedQuests(userId, goal, userLocation));
        break;
      case FitnessGoalType.distance:
        quests.addAll(await _generateDistanceBasedQuests(userId, goal, userLocation));
        break;
      case FitnessGoalType.duration:
        quests.addAll(await _generateTimeBasedQuests(userId, goal, userLocation));
        break;
      case FitnessGoalType.calories:
        quests.addAll(await _generateCalorieBasedQuests(userId, goal, userLocation));
        break;
      case FitnessGoalType.heartRate:
        quests.addAll(await _generateHeartRateQuests(userId, goal, userLocation));
        break;
    }
    
    return quests;
  }

  /// Generate step-based fitness quests
  Future<List<Quest>> _generateStepBasedQuests(
    String userId,
    FitnessGoal goal,
    Position? userLocation,
  ) async {
    final quests = <Quest>[];
    final currentStats = _fitnessAgent.getCurrentStats();
    final dailySteps = currentStats['steps'] as int;
    
    // Progressive step challenges
    final progressiveSteps = _calculateProgressiveSteps(goal.targetValue, dailySteps);
    
    for (int i = 0; i < 3; i++) {
      final stepTarget = progressiveSteps[i];
      final difficulty = _calculateQuestDifficulty(stepTarget, goal.targetValue);
      
      quests.add(Quest(
        name: _generateStepQuestName(stepTarget, i),
        description: 'Walk ${stepTarget} steps to unlock your inner warrior strength!',
        story: _generateStepQuestStory(stepTarget, i),
        type: QuestType.fitness,
        difficulty: difficulty,
        location: userLocation != null ? QuestLocation(
          name: 'Your Adventure Starting Point',
          description: 'Begin your fitness journey from here',
          latitude: userLocation.latitude,
          longitude: userLocation.longitude,
        ) : null,
        objectives: [
          QuestObjective(
            description: 'Walk $stepTarget steps',
            type: 'step_count',
            targetValue: stepTarget,
            currentValue: 0,
          ),
        ],
        experienceReward: _calculateExpReward(stepTarget, 'steps'),
        goldReward: _calculateGoldReward(stepTarget, 'steps'),
        rewards: _generateFitnessRewards(stepTarget, 'steps'),
        metadata: {
          'fitnessGoalId': goal.id,
          'questType': 'step_challenge',
          'difficulty_factor': stepTarget / goal.targetValue,
          'adaptive': true,
        },
      ));
    }
    
    return quests;
  }

  /// Generate distance-based fitness quests
  Future<List<Quest>> _generateDistanceBasedQuests(
    String userId,
    FitnessGoal goal,
    Position? userLocation,
  ) async {
    final quests = <Quest>[];
    
    if (userLocation == null) return quests;
    
    // Generate route-based distance quests
    final distances = [
      (goal.targetValue * 0.5).round(), // 50% of goal
      (goal.targetValue * 0.75).round(), // 75% of goal
      goal.targetValue, // Full goal
    ];
    
    for (int i = 0; i < distances.length; i++) {
      final distance = distances[i];
      final route = await _generateAdventureRoute(userLocation, distance);
      final difficulty = _calculateDistanceDifficulty(distance);
      
      quests.add(Quest(
        name: _generateDistanceQuestName(distance, i),
        description: 'Embark on a ${_formatDistance(distance)} adventure through your realm!',
        story: _generateDistanceQuestStory(distance, i),
        type: QuestType.walking,
        difficulty: difficulty,
        location: QuestLocation(
          name: 'Adventure Starting Point',
          description: 'Your epic journey begins here',
          latitude: userLocation.latitude,
          longitude: userLocation.longitude,
        ),
        waypoints: route,
        objectives: [
          QuestObjective(
            description: 'Travel ${_formatDistance(distance)}',
            type: 'distance',
            targetValue: distance,
            currentValue: 0,
          ),
          QuestObjective(
            description: 'Visit all waypoints on your journey',
            type: 'waypoints',
            targetValue: route.length,
            currentValue: 0,
          ),
        ],
        experienceReward: _calculateExpReward(distance, 'distance'),
        goldReward: _calculateGoldReward(distance, 'distance'),
        rewards: _generateFitnessRewards(distance, 'distance'),
        metadata: {
          'fitnessGoalId': goal.id,
          'questType': 'distance_adventure',
          'route_generated': true,
          'adaptive': true,
        },
      ));
    }
    
    return quests;
  }

  /// Generate time-based fitness quests
  Future<List<Quest>> _generateTimeBasedQuests(
    String userId,
    FitnessGoal goal,
    Position? userLocation,
  ) async {
    final quests = <Quest>[];
    
    // Generate different activity time challenges
    final timeTargets = [
      (goal.targetValue * 0.6).round(), // 60% of goal
      (goal.targetValue * 0.8).round(), // 80% of goal
      goal.targetValue, // Full goal
    ];
    
    final activities = ['walking', 'jogging', 'cycling'];
    
    for (int i = 0; i < timeTargets.length; i++) {
      final timeTarget = timeTargets[i];
      final activity = activities[i % activities.length];
      final difficulty = _calculateTimeDifficulty(timeTarget);
      
      quests.add(Quest(
        name: _generateTimeQuestName(timeTarget, activity),
        description: 'Spend ${timeTarget} minutes ${activity} to master your endurance!',
        story: _generateTimeQuestStory(timeTarget, activity),
        type: QuestType.fitness,
        difficulty: difficulty,
        location: userLocation != null ? QuestLocation(
          name: 'Endurance Training Ground',
          description: 'Train your stamina and willpower here',
          latitude: userLocation.latitude,
          longitude: userLocation.longitude,
        ) : null,
        objectives: [
          QuestObjective(
            description: 'Be active for $timeTarget minutes',
            type: 'active_time',
            targetValue: timeTarget,
            currentValue: 0,
          ),
        ],
        experienceReward: _calculateExpReward(timeTarget, 'time'),
        goldReward: _calculateGoldReward(timeTarget, 'time'),
        rewards: _generateFitnessRewards(timeTarget, 'time'),
        metadata: {
          'fitnessGoalId': goal.id,
          'questType': 'time_trial',
          'activity_type': activity,
          'adaptive': true,
        },
      ));
    }
    
    return quests;
  }

  /// Generate calorie-based fitness quests
  Future<List<Quest>> _generateCalorieBasedQuests(
    String userId,
    FitnessGoal goal,
    Position? userLocation,
  ) async {
    final quests = <Quest>[];
    
    final calorieTargets = [
      (goal.targetValue * 0.5).round(),
      (goal.targetValue * 0.75).round(),
      goal.targetValue,
    ];
    
    for (int i = 0; i < calorieTargets.length; i++) {
      final calorieTarget = calorieTargets[i];
      final difficulty = _calculateCalorieDifficulty(calorieTarget);
      
      quests.add(Quest(
        name: _generateCalorieQuestName(calorieTarget, i),
        description: 'Burn $calorieTarget calories to fuel your magical powers!',
        story: _generateCalorieQuestStory(calorieTarget, i),
        type: QuestType.fitness,
        difficulty: difficulty,
        objectives: [
          QuestObjective(
            description: 'Burn $calorieTarget calories through activity',
            type: 'calories',
            targetValue: calorieTarget,
            currentValue: 0,
          ),
        ],
        experienceReward: _calculateExpReward(calorieTarget, 'calories'),
        goldReward: _calculateGoldReward(calorieTarget, 'calories'),
        rewards: _generateFitnessRewards(calorieTarget, 'calories'),
        metadata: {
          'fitnessGoalId': goal.id,
          'questType': 'calorie_burn',
          'adaptive': true,
        },
      ));
    }
    
    return quests;
  }

  /// Generate heart rate-based fitness quests
  Future<List<Quest>> _generateHeartRateQuests(
    String userId,
    FitnessGoal goal,
    Position? userLocation,
  ) async {
    final quests = <Quest>[];
    
    // Heart rate zone training quests
    final zones = [
      {'name': 'Fat Burn Zone', 'min': 120, 'max': 140, 'minutes': 20},
      {'name': 'Cardio Zone', 'min': 140, 'max': 160, 'minutes': 15},
      {'name': 'Peak Zone', 'min': 160, 'max': 180, 'minutes': 10},
    ];
    
    for (int i = 0; i < zones.length; i++) {
      final zone = zones[i];
      final difficulty = QuestDifficulty.values[i];
      
      quests.add(Quest(
        name: 'Heart Warrior: ${zone['name']}',
        description: 'Train in the ${zone['name']} to strengthen your cardiovascular system!',
        story: 'Ancient warriors knew that controlling the heart\'s rhythm was key to unlocking inner power. Train in the ${zone['name']} to master this ancient art.',
        type: QuestType.fitness,
        difficulty: difficulty,
        objectives: [
          QuestObjective(
            description: 'Maintain heart rate between ${zone['min']}-${zone['max']} BPM for ${zone['minutes']} minutes',
            type: 'heart_rate_zone',
            targetValue: zone['minutes'] as int,
            currentValue: 0,
          ),
        ],
        experienceReward: 250 + (i * 50),
        goldReward: 125 + (i * 25),
        rewards: _generateHeartRateRewards(i),
        metadata: {
          'fitnessGoalId': goal.id,
          'questType': 'heart_rate_training',
          'zone_min': zone['min'],
          'zone_max': zone['max'],
          'adaptive': true,
        },
      ));
    }
    
    return quests;
  }

  /// Generate adaptive quests based on fitness level
  Future<List<Quest>> _generateAdaptiveQuests(
    String userId,
    FitnessLevel fitnessLevel,
    Map<String, dynamic> currentStats,
    Position? userLocation,
  ) async {
    final quests = <Quest>[];
    final dailySteps = currentStats['steps'] as int;
    
    // Adaptive daily challenge based on recent performance
    final adaptiveStepTarget = _calculateAdaptiveStepTarget(dailySteps, fitnessLevel);
    
    quests.add(Quest(
      name: 'Daily Warrior Challenge',
      description: 'Prove your dedication with today\'s adaptive fitness challenge!',
      story: 'Each day brings new opportunities for growth. Today, the realm challenges you to push beyond yesterday\'s limits.',
      type: QuestType.fitness,
      difficulty: _calculateAdaptiveDifficulty(adaptiveStepTarget, dailySteps),
      objectives: [
        QuestObjective(
          description: 'Complete your personalized daily challenge: $adaptiveStepTarget steps',
          type: 'adaptive_steps',
          targetValue: adaptiveStepTarget,
          currentValue: dailySteps,
        ),
      ],
      experienceReward: _calculateAdaptiveExpReward(adaptiveStepTarget, fitnessLevel),
      goldReward: _calculateAdaptiveGoldReward(adaptiveStepTarget, fitnessLevel),
      rewards: _generateAdaptiveRewards(fitnessLevel),
      deadline: DateTime.now().add(const Duration(days: 1)),
      metadata: {
        'questType': 'adaptive_daily',
        'fitness_level': fitnessLevel.name,
        'adaptive': true,
        'daily_challenge': true,
      },
    ));
    
    return quests;
  }

  /// Generate progressive difficulty quests
  Future<List<Quest>> _generateProgressiveQuests(
    String userId,
    FitnessLevel fitnessLevel,
    Position? userLocation,
  ) async {
    final quests = <Quest>[];
    
    // Weekly progression quest
    final weeklyTarget = _calculateWeeklyTarget(fitnessLevel);
    
    quests.add(Quest(
      name: 'Seven Days of Valor',
      description: 'A week-long journey to test your commitment and unlock greater power!',
      story: 'The ancient masters believed that true strength comes from consistency. Prove your dedication over seven days and unlock the secrets of sustained power.',
      type: QuestType.fitness,
      difficulty: _getFitnessLevelDifficulty(fitnessLevel),
      objectives: [
        QuestObjective(
          description: 'Complete $weeklyTarget steps over 7 days',
          type: 'weekly_steps',
          targetValue: weeklyTarget,
          currentValue: 0,
        ),
        QuestObjective(
          description: 'Be active for at least 30 minutes each day',
          type: 'daily_activity_streak',
          targetValue: 7,
          currentValue: 0,
        ),
      ],
      experienceReward: _calculateProgressiveExpReward(weeklyTarget),
      goldReward: _calculateProgressiveGoldReward(weeklyTarget),
      rewards: _generateProgressiveRewards(fitnessLevel),
      deadline: DateTime.now().add(const Duration(days: 7)),
      metadata: {
        'questType': 'progressive_weekly',
        'fitness_level': fitnessLevel.name,
        'weekly_challenge': true,
      },
    ));
    
    return quests;
  }

  /// Generate milestone celebration quests
  Future<List<Quest>> _generateMilestoneQuests(
    String userId,
    Map<String, dynamic> currentStats,
  ) async {
    final quests = <Quest>[];
    final dailySteps = currentStats['steps'] as int;
    
    // Check for step milestones
    final stepMilestones = [5000, 10000, 15000, 20000, 25000];
    for (final milestone in stepMilestones) {
      if (dailySteps >= milestone && dailySteps < milestone + 1000) {
        quests.add(Quest(
          name: 'Milestone Master: ${_formatNumber(milestone)} Steps',
          description: 'Celebrate reaching $milestone steps - you\'re becoming a true fitness legend!',
          story: 'The realm recognizes your achievement! You have walked $milestone steps, joining the ranks of legendary adventurers who understand that every step is a victory.',
          type: QuestType.fitness,
          difficulty: QuestDifficulty.easy,
          objectives: [
            QuestObjective(
              description: 'Maintain your momentum - reach ${milestone + 1000} steps',
              type: 'milestone_celebration',
              targetValue: milestone + 1000,
              currentValue: dailySteps,
            ),
          ],
          experienceReward: 500,
          goldReward: 250,
          rewards: _generateMilestoneRewards(milestone),
          metadata: {
            'questType': 'milestone_celebration',
            'milestone_value': milestone,
            'celebration': true,
          },
        ));
        break; // Only one milestone quest at a time
      }
    }
    
    return quests;
  }

  // Helper methods for quest generation
  List<int> _calculateProgressiveSteps(int goalTarget, int currentDaily) {
    final baseStep = math.max(currentDaily, 3000);
    final increment = ((goalTarget - baseStep) / 3).round();
    
    return [
      baseStep + increment,
      baseStep + (increment * 2),
      goalTarget,
    ];
  }

  QuestDifficulty _calculateQuestDifficulty(int value, int maxValue) {
    final ratio = value / maxValue;
    if (ratio <= 0.3) return QuestDifficulty.easy;
    if (ratio <= 0.6) return QuestDifficulty.medium;
    if (ratio <= 0.8) return QuestDifficulty.hard;
    return QuestDifficulty.expert;
  }

  QuestDifficulty _calculateDistanceDifficulty(int distance) {
    if (distance <= 1609) return QuestDifficulty.easy; // 1 mile
    if (distance <= 3218) return QuestDifficulty.medium; // 2 miles
    if (distance <= 4828) return QuestDifficulty.hard; // 3 miles
    return QuestDifficulty.expert; // 3+ miles
  }

  QuestDifficulty _calculateTimeDifficulty(int minutes) {
    if (minutes <= 20) return QuestDifficulty.easy;
    if (minutes <= 40) return QuestDifficulty.medium;
    if (minutes <= 60) return QuestDifficulty.hard;
    return QuestDifficulty.expert;
  }

  QuestDifficulty _calculateCalorieDifficulty(int calories) {
    if (calories <= 200) return QuestDifficulty.easy;
    if (calories <= 400) return QuestDifficulty.medium;
    if (calories <= 600) return QuestDifficulty.hard;
    return QuestDifficulty.expert;
  }

  int _calculateExpReward(int value, String type) {
    switch (type) {
      case 'steps': return (value / 100).round() * 10;
      case 'distance': return (value / 100).round() * 15;
      case 'time': return value * 8;
      case 'calories': return value * 2;
      default: return 100;
    }
  }

  int _calculateGoldReward(int value, String type) {
    return (_calculateExpReward(value, type) * 0.5).round();
  }

  List<QuestReward> _generateFitnessRewards(int value, String type) {
    final rewards = <QuestReward>[];
    
    // Always give fitness-themed rewards
    rewards.add(QuestReward(
      type: 'item',
      name: 'Endurance Potion',
      value: 1,
    ));
    
    // Add type-specific rewards
    switch (type) {
      case 'steps':
        if (value >= 10000) {
          rewards.add(QuestReward(
            type: 'item',
            name: 'Swift Walker Boots',
            value: 1,
          ));
        }
        break;
      case 'distance':
        if (value >= 3218) { // 2 miles
          rewards.add(QuestReward(
            type: 'item',
            name: 'Explorer\'s Compass',
            value: 1,
          ));
        }
        break;
      case 'time':
        if (value >= 30) {
          rewards.add(QuestReward(
            type: 'item',
            name: 'Persistence Charm',
            value: 1,
          ));
        }
        break;
      case 'calories':
        if (value >= 300) {
          rewards.add(QuestReward(
            type: 'item',
            name: 'Metabolic Enhancer',
            value: 1,
          ));
        }
        break;
    }
    
    return rewards;
  }

  List<QuestReward> _generateHeartRateRewards(int zoneLevel) {
    return [
      QuestReward(type: 'item', name: 'Heart Rate Monitor Crystal', value: 1),
      QuestReward(type: 'item', name: 'Cardiovascular Elixir', value: 1),
      if (zoneLevel >= 2) QuestReward(type: 'item', name: 'Peak Performance Badge', value: 1),
    ];
  }

  List<QuestReward> _generateAdaptiveRewards(FitnessLevel level) {
    switch (level) {
      case FitnessLevel.beginner:
        return [
          QuestReward(type: 'item', name: 'Novice Training Gear', value: 1),
          QuestReward(type: 'item', name: 'Motivation Scroll', value: 1),
        ];
      case FitnessLevel.intermediate:
        return [
          QuestReward(type: 'item', name: 'Athletic Enhancement Potion', value: 1),
          QuestReward(type: 'item', name: 'Progress Tracker', value: 1),
        ];
      case FitnessLevel.advanced:
        return [
          QuestReward(type: 'item', name: 'Elite Athlete Emblem', value: 1),
          QuestReward(type: 'item', name: 'Peak Performance Enhancer', value: 1),
        ];
      case FitnessLevel.expert:
        return [
          QuestReward(type: 'item', name: 'Legendary Fitness Artifact', value: 1),
          QuestReward(type: 'item', name: 'Master Trainer\'s Wisdom', value: 1),
        ];
    }
  }

  List<QuestReward> _generateProgressiveRewards(FitnessLevel level) {
    final rewards = <QuestReward>[
      QuestReward(type: 'item', name: 'Seven-Day Victory Crown', value: 1),
      QuestReward(type: 'experience', name: 'Consistency Bonus', value: 1000),
    ];
    
    if (level.index >= FitnessLevel.intermediate.index) {
      rewards.add(QuestReward(type: 'item', name: 'Dedication Medallion', value: 1));
    }
    
    return rewards;
  }

  List<QuestReward> _generateMilestoneRewards(int milestone) {
    return [
      QuestReward(type: 'gold', name: 'Milestone Bonus', value: milestone ~/ 100),
      QuestReward(type: 'item', name: '${_formatNumber(milestone)} Steps Achievement Badge', value: 1),
      if (milestone >= 10000) QuestReward(type: 'item', name: 'Daily Walker\'s Crown', value: 1),
      if (milestone >= 20000) QuestReward(type: 'item', name: 'Step Master\'s Legendary Ring', value: 1),
    ];
  }

  // Quest naming and story generation
  String _generateStepQuestName(int steps, int level) {
    final names = [
      'The ${_formatNumber(steps)} Step Journey',
      'Pathway to ${_formatNumber(steps)} Steps',
      'The Great ${_formatNumber(steps)} Step Adventure',
    ];
    return names[level % names.length];
  }

  String _generateStepQuestStory(int steps, int level) {
    final stories = [
      'Every journey begins with a single step, but great adventures require ${_formatNumber(steps)} of them. Begin your quest and let each step strengthen your resolve.',
      'The ancient path-walkers knew that ${_formatNumber(steps)} steps would unlock hidden reserves of inner strength. Follow in their footsteps.',
      'Legend speaks of warriors who could walk ${_formatNumber(steps)} steps without rest, their spirits growing stronger with each footfall. Can you match their endurance?',
    ];
    return stories[level % stories.length];
  }

  String _generateDistanceQuestName(int distance, int level) {
    final distanceStr = _formatDistance(distance);
    final names = [
      'The $distanceStr Expedition',
      'Journey of $distanceStr',
      'The Great $distanceStr Adventure',
    ];
    return names[level % names.length];
  }

  String _generateDistanceQuestStory(int distance, int level) {
    final distanceStr = _formatDistance(distance);
    final stories = [
      'The realm calls you to explore $distanceStr of its hidden paths. Each meter traveled reveals new wonders and strengthens your adventuring spirit.',
      'Ancient maps speak of treasures hidden exactly $distanceStr from where you stand. Only by completing this journey will you claim what awaits.',
      'The distance of $distanceStr separates you from becoming a true explorer of this realm. Let your feet carry you to greatness.',
    ];
    return stories[level % stories.length];
  }

  String _generateTimeQuestName(int minutes, String activity) {
    return 'The $minutes-Minute ${activity.toUpperCase()} Trial';
  }

  String _generateTimeQuestStory(int minutes, String activity) {
    return 'Time is the ultimate test of dedication. Spend $minutes minutes in focused $activity, and discover the patience and persistence that forge true champions.';
  }

  String _generateCalorieQuestName(int calories, int level) {
    final names = [
      'The $calories Calorie Burn',
      'Fire of $calories Calories',
      'The Great $calories Calorie Challenge',
    ];
    return names[level % names.length];
  }

  String _generateCalorieQuestStory(int calories, int level) {
    return 'Your body is a furnace, and each calorie burned is fuel for your growing power. Burn $calories calories and feel your energy transform into pure strength.';
  }

  // Utility methods
  String _formatDistance(int meters) {
    if (meters >= 1609) {
      final miles = meters / 1609;
      return '${miles.toStringAsFixed(1)} mile${miles != 1.0 ? 's' : ''}';
    } else {
      return '${meters}m';
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  // Additional helper methods for fitness level management
  int _calculateAdaptiveStepTarget(int currentDaily, FitnessLevel level) {
    final baseIncrease = switch (level) {
      FitnessLevel.beginner => 500,
      FitnessLevel.intermediate => 1000,
      FitnessLevel.advanced => 1500,
      FitnessLevel.expert => 2000,
    };
    
    return math.max(currentDaily + baseIncrease, 5000);
  }

  QuestDifficulty _calculateAdaptiveDifficulty(int target, int current) {
    final increase = target - current;
    if (increase <= 1000) return QuestDifficulty.easy;
    if (increase <= 2000) return QuestDifficulty.medium;
    if (increase <= 3000) return QuestDifficulty.hard;
    return QuestDifficulty.expert;
  }

  QuestDifficulty _getFitnessLevelDifficulty(FitnessLevel level) {
    return QuestDifficulty.values[level.index];
  }

  int _calculateWeeklyTarget(FitnessLevel level) {
    return switch (level) {
      FitnessLevel.beginner => 35000, // 5K per day
      FitnessLevel.intermediate => 70000, // 10K per day
      FitnessLevel.advanced => 105000, // 15K per day
      FitnessLevel.expert => 140000, // 20K per day
    };
  }

  int _calculateAdaptiveExpReward(int steps, FitnessLevel level) {
    final base = (steps / 100).round() * 10;
    final multiplier = switch (level) {
      FitnessLevel.beginner => 1.5,
      FitnessLevel.intermediate => 1.2,
      FitnessLevel.advanced => 1.0,
      FitnessLevel.expert => 0.8,
    };
    return (base * multiplier).round();
  }

  int _calculateAdaptiveGoldReward(int steps, FitnessLevel level) {
    return (_calculateAdaptiveExpReward(steps, level) * 0.5).round();
  }

  int _calculateProgressiveExpReward(int weeklySteps) {
    return (weeklySteps / 1000).round() * 100;
  }

  int _calculateProgressiveGoldReward(int weeklySteps) {
    return (_calculateProgressiveExpReward(weeklySteps) * 0.6).round();
  }

  // Route generation
  Future<List<QuestLocation>> _generateAdventureRoute(Position start, int distance) async {
    // Simple route generation - in production this would use proper routing APIs
    final waypoints = <QuestLocation>[];
    final numWaypoints = math.min((distance / 500).round(), 8); // Waypoint every 500m, max 8
    
    final random = math.Random();
    
    for (int i = 0; i < numWaypoints; i++) {
      final offsetLat = (random.nextDouble() - 0.5) * 0.01; // ~1km range
      final offsetLng = (random.nextDouble() - 0.5) * 0.01;
      
      waypoints.add(QuestLocation(
        name: 'Adventure Waypoint ${i + 1}',
        description: 'A mysterious location on your journey',
        latitude: start.latitude + offsetLat,
        longitude: start.longitude + offsetLng,
      ));
    }
    
    return waypoints;
  }

  // Data persistence
  Future<void> _loadUserFitnessGoals(String userId) async {
    final goalsJson = _prefs.getString('fitness_goals_$userId');
    if (goalsJson != null) {
      final goalData = jsonDecode(goalsJson) as Map<String, dynamic>;
      _userFitnessGoals[userId] = FitnessGoal.fromJson(goalData);
    }
  }

  Future<void> _loadUserFitnessLevel(String userId) async {
    final levelIndex = _prefs.getInt('fitness_level_$userId') ?? 0;
    _userFitnessLevels[userId] = FitnessLevel.values[levelIndex];
  }

  Future<void> _saveFitnessGoals() async {
    for (final entry in _userFitnessGoals.entries) {
      await _prefs.setString('fitness_goals_${entry.key}', jsonEncode(entry.value.toJson()));
    }
  }

  Future<void> _generateInitialPersonalizedQuests(String userId) async {
    final position = await Geolocator.getCurrentPosition();
    await generatePersonalizedFitnessQuests(userId: userId, userLocation: position);
  }

  Future<void> _generateQuestsForGoal(String userId, FitnessGoal goal) async {
    final position = await Geolocator.getCurrentPosition();
    final quests = await _generateGoalBasedQuests(userId, goal, position);
    
    // Add quests to the quest service
    for (final quest in quests) {
      _questService.addQuest(quest);
    }
  }

  // Public API methods
  List<Quest> getPersonalizedQuests(String userId) {
    return _personalizedQuests[userId] ?? [];
  }

  FitnessGoal? getUserFitnessGoal(String userId) {
    return _userFitnessGoals[userId];
  }

  FitnessLevel getUserFitnessLevel(String userId) {
    return _userFitnessLevels[userId] ?? FitnessLevel.beginner;
  }

  Future<void> updateUserFitnessLevel(String userId, FitnessLevel level) async {
    _userFitnessLevels[userId] = level;
    await _prefs.setInt('fitness_level_$userId', level.index);
  }
}

// Supporting classes
enum FitnessGoalType {
  stepCount,
  distance,
  duration,
  calories,
  heartRate,
}

enum FitnessLevel {
  beginner,
  intermediate,
  advanced,
  expert,
}

class FitnessGoal {
  final String id;
  final String userId;
  final FitnessGoalType type;
  final int targetValue;
  final int currentValue;
  final String timeframe;
  final String? customName;
  final DateTime createdAt;
  final bool isActive;

  FitnessGoal({
    required this.id,
    required this.userId,
    required this.type,
    required this.targetValue,
    required this.currentValue,
    required this.timeframe,
    this.customName,
    required this.createdAt,
    required this.isActive,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'type': type.name,
    'targetValue': targetValue,
    'currentValue': currentValue,
    'timeframe': timeframe,
    'customName': customName,
    'createdAt': createdAt.toIso8601String(),
    'isActive': isActive,
  };

  factory FitnessGoal.fromJson(Map<String, dynamic> json) => FitnessGoal(
    id: json['id'],
    userId: json['userId'],
    type: FitnessGoalType.values.firstWhere((e) => e.name == json['type']),
    targetValue: json['targetValue'],
    currentValue: json['currentValue'],
    timeframe: json['timeframe'],
    customName: json['customName'],
    createdAt: DateTime.parse(json['createdAt']),
    isActive: json['isActive'],
  );
}