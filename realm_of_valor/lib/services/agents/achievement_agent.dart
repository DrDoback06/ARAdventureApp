import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import '../../services/event_bus.dart';
import 'integration_orchestrator_agent.dart';

/// Achievement type enumeration
enum AchievementType {
  progression, // Character level, XP milestones
  collection,  // Card collection, item gathering
  combat,      // Battle victories, kill counts
  fitness,     // Step goals, activity milestones
  exploration, // Location visits, distance traveled
  social,      // Friend interactions, guild activities
  special,     // Rare events, seasonal activities
}

/// Achievement rarity levels
enum AchievementRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  mythic,
}

/// Achievement definition
class Achievement {
  final String id;
  final String name;
  final String description;
  final AchievementType type;
  final AchievementRarity rarity;
  final Map<String, dynamic> requirements;
  final Map<String, dynamic> rewards;
  final String? icon;
  final bool isHidden;
  final bool isRepeatable;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final List<String> prerequisites;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.rarity = AchievementRarity.common,
    this.requirements = const {},
    this.rewards = const {},
    this.icon,
    this.isHidden = false,
    this.isRepeatable = false,
    this.availableFrom,
    this.availableUntil,
    this.prerequisites = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString(),
      'rarity': rarity.toString(),
      'requirements': requirements,
      'rewards': rewards,
      'icon': icon,
      'isHidden': isHidden,
      'isRepeatable': isRepeatable,
      'availableFrom': availableFrom?.toIso8601String(),
      'availableUntil': availableUntil?.toIso8601String(),
      'prerequisites': prerequisites,
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: AchievementType.values.firstWhere(
        (t) => t.toString() == json['type'],
        orElse: () => AchievementType.progression,
      ),
      rarity: AchievementRarity.values.firstWhere(
        (r) => r.toString() == json['rarity'],
        orElse: () => AchievementRarity.common,
      ),
      requirements: Map<String, dynamic>.from(json['requirements'] ?? {}),
      rewards: Map<String, dynamic>.from(json['rewards'] ?? {}),
      icon: json['icon'],
      isHidden: json['isHidden'] ?? false,
      isRepeatable: json['isRepeatable'] ?? false,
      availableFrom: json['availableFrom'] != null ? DateTime.parse(json['availableFrom']) : null,
      availableUntil: json['availableUntil'] != null ? DateTime.parse(json['availableUntil']) : null,
      prerequisites: List<String>.from(json['prerequisites'] ?? []),
    );
  }
}

/// User's achievement progress
class AchievementProgress {
  final String achievementId;
  final String userId;
  final Map<String, dynamic> progress;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime lastUpdated;
  final int completionCount;

  AchievementProgress({
    required this.achievementId,
    required this.userId,
    this.progress = const {},
    this.isCompleted = false,
    this.completedAt,
    DateTime? lastUpdated,
    this.completionCount = 0,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  AchievementProgress copyWith({
    String? achievementId,
    String? userId,
    Map<String, dynamic>? progress,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? lastUpdated,
    int? completionCount,
  }) {
    return AchievementProgress(
      achievementId: achievementId ?? this.achievementId,
      userId: userId ?? this.userId,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      completionCount: completionCount ?? this.completionCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'achievementId': achievementId,
      'userId': userId,
      'progress': progress,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'completionCount': completionCount,
    };
  }

  factory AchievementProgress.fromJson(Map<String, dynamic> json) {
    return AchievementProgress(
      achievementId: json['achievementId'],
      userId: json['userId'],
      progress: Map<String, dynamic>.from(json['progress'] ?? {}),
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      lastUpdated: DateTime.parse(json['lastUpdated']),
      completionCount: json['completionCount'] ?? 0,
    );
  }
}

/// Achievement notification
class AchievementNotification {
  final String achievementId;
  final String userId;
  final String title;
  final String message;
  final AchievementRarity rarity;
  final Map<String, dynamic> rewards;
  final DateTime timestamp;

  AchievementNotification({
    required this.achievementId,
    required this.userId,
    required this.title,
    required this.message,
    required this.rarity,
    this.rewards = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Achievement Agent - Track all progress types and distribute rewards
class AchievementAgent extends BaseAgent {
  static const String agentId = 'achievement';

  final Map<String, Achievement> _achievements = {};
  final Map<String, Map<String, AchievementProgress>> _userProgress = {}; // userId -> achievementId -> progress
  final List<AchievementNotification> _notifications = [];
  
  // Current user context
  String? _currentUserId;
  
  // Progress tracking
  final Map<String, dynamic> _userStats = {};
  Timer? _progressTimer;

  AchievementAgent() : super(agentId: agentId);

  @override
  Future<void> onInitialize() async {
    developer.log('Initializing Achievement Agent', name: agentId);
    
    // Initialize achievement definitions
    _initializeAchievements();
    
    // Load user progress from data persistence
    await _loadUserProgress();
    
    // Start periodic progress checks
    _startProgressTracking();
    
    developer.log('Achievement Agent initialized with ${_achievements.length} achievements', name: agentId);
  }

  @override
  void subscribeToEvents() {
    // Character progression events
    subscribe(EventTypes.characterUpdated, _handleCharacterUpdated);
    subscribe(EventTypes.characterLevelUp, _handleCharacterLevelUp);
    subscribe(EventTypes.characterXpGained, _handleCharacterXpGained);
    
    // Battle events
    subscribe(EventTypes.battleResult, _handleBattleResult);
    
    // Fitness events
    subscribe(EventTypes.fitnessUpdate, _handleFitnessUpdate);
    subscribe(EventTypes.fitnessGoalReached, _handleFitnessGoalReached);
    
    // Quest events
    subscribe(EventTypes.questCompleted, _handleQuestCompleted);
    
    // Card events
    subscribe(EventTypes.cardScanned, _handleCardScanned);
    subscribe(EventTypes.inventoryChanged, _handleInventoryChanged);
    
    // Location events
    subscribe(EventTypes.locationUpdate, _handleLocationUpdate);
    subscribe(EventTypes.poiDetected, _handlePoiDetected);
    
    // Achievement management
    subscribe('get_achievements', _handleGetAchievements);
    subscribe('get_user_progress', _handleGetUserProgress);
    subscribe('check_achievement', _handleCheckAchievement);
    subscribe('unlock_achievement', _handleUnlockAchievement);
    subscribe('get_notifications', _handleGetNotifications);
    subscribe('clear_notifications', _handleClearNotifications);
    
    // User management
    subscribe('user_login', _handleUserLogin);
    subscribe('user_logout', _handleUserLogout);
  }

  /// Initialize achievement definitions
  void _initializeAchievements() {
    final achievements = [
      // Character Progression Achievements
      Achievement(
        id: 'first_steps',
        name: 'First Steps',
        description: 'Create your first character',
        type: AchievementType.progression,
        rarity: AchievementRarity.common,
        requirements: {'characterCreated': 1},
        rewards: {'xp': 100, 'gold': 50},
      ),
      Achievement(
        id: 'level_5',
        name: 'Getting Strong',
        description: 'Reach character level 5',
        type: AchievementType.progression,
        rarity: AchievementRarity.common,
        requirements: {'characterLevel': 5},
        rewards: {'xp': 200, 'gold': 100},
      ),
      Achievement(
        id: 'level_10',
        name: 'Veteran Adventurer',
        description: 'Reach character level 10',
        type: AchievementType.progression,
        rarity: AchievementRarity.uncommon,
        requirements: {'characterLevel': 10},
        rewards: {'xp': 500, 'gold': 250, 'cards': ['rare_weapon']},
      ),
      Achievement(
        id: 'level_25',
        name: 'Elite Hero',
        description: 'Reach character level 25',
        type: AchievementType.progression,
        rarity: AchievementRarity.rare,
        requirements: {'characterLevel': 25},
        rewards: {'xp': 1000, 'gold': 500, 'cards': ['epic_armor']},
      ),
      Achievement(
        id: 'xp_master',
        name: 'Experience Master',
        description: 'Gain 10,000 total experience points',
        type: AchievementType.progression,
        rarity: AchievementRarity.epic,
        requirements: {'totalXp': 10000},
        rewards: {'xp': 2000, 'gold': 1000, 'cards': ['legendary_gem']},
      ),

      // Combat Achievements
      Achievement(
        id: 'first_victory',
        name: 'First Blood',
        description: 'Win your first battle',
        type: AchievementType.combat,
        rarity: AchievementRarity.common,
        requirements: {'battlesWon': 1},
        rewards: {'xp': 150, 'gold': 75},
      ),
      Achievement(
        id: 'warrior',
        name: 'Warrior',
        description: 'Win 10 battles',
        type: AchievementType.combat,
        rarity: AchievementRarity.uncommon,
        requirements: {'battlesWon': 10},
        rewards: {'xp': 300, 'gold': 150, 'cards': ['battle_axe']},
      ),
      Achievement(
        id: 'champion',
        name: 'Champion',
        description: 'Win 50 battles',
        type: AchievementType.combat,
        rarity: AchievementRarity.rare,
        requirements: {'battlesWon': 50},
        rewards: {'xp': 1000, 'gold': 500, 'cards': ['champion_crown']},
      ),
      Achievement(
        id: 'dragon_slayer',
        name: 'Dragon Slayer',
        description: 'Defeat the Ancient Dragon',
        type: AchievementType.combat,
        rarity: AchievementRarity.legendary,
        requirements: {'dragonKills': 1},
        rewards: {'xp': 5000, 'gold': 2500, 'cards': ['dragon_sword', 'dragon_scale_armor']},
      ),

      // Fitness Achievements
      Achievement(
        id: 'first_steps_fitness',
        name: 'On the Move',
        description: 'Take your first 1,000 steps',
        type: AchievementType.fitness,
        rarity: AchievementRarity.common,
        requirements: {'totalSteps': 1000},
        rewards: {'xp': 100, 'statBonus': {'vitality': 1}},
      ),
      Achievement(
        id: 'walker',
        name: 'Walker',
        description: 'Take 10,000 steps in a day',
        type: AchievementType.fitness,
        rarity: AchievementRarity.uncommon,
        requirements: {'dailySteps': 10000},
        rewards: {'xp': 200, 'statBonus': {'vitality': 2, 'dexterity': 1}},
        isRepeatable: true,
      ),
      Achievement(
        id: 'marathon_runner',
        name: 'Marathon Runner',
        description: 'Take 50,000 steps in a day',
        type: AchievementType.fitness,
        rarity: AchievementRarity.epic,
        requirements: {'dailySteps': 50000},
        rewards: {'xp': 1000, 'gold': 500, 'statBonus': {'vitality': 5, 'dexterity': 3}},
        isRepeatable: true,
      ),
      Achievement(
        id: 'active_lifestyle',
        name: 'Active Lifestyle',
        description: 'Reach daily step goal for 7 consecutive days',
        type: AchievementType.fitness,
        rarity: AchievementRarity.rare,
        requirements: {'consecutiveDayGoals': 7},
        rewards: {'xp': 500, 'gold': 250, 'cards': ['fitness_tracker']},
      ),

      // Collection Achievements
      Achievement(
        id: 'collector',
        name: 'Collector',
        description: 'Collect 10 different cards',
        type: AchievementType.collection,
        rarity: AchievementRarity.uncommon,
        requirements: {'uniqueCards': 10},
        rewards: {'xp': 200, 'gold': 100, 'cards': ['card_pack']},
      ),
      Achievement(
        id: 'hoarder',
        name: 'Hoarder',
        description: 'Collect 50 different cards',
        type: AchievementType.collection,
        rarity: AchievementRarity.rare,
        requirements: {'uniqueCards': 50},
        rewards: {'xp': 1000, 'gold': 500, 'cards': ['rare_card_pack']},
      ),
      Achievement(
        id: 'master_collector',
        name: 'Master Collector',
        description: 'Collect 100 different cards',
        type: AchievementType.collection,
        rarity: AchievementRarity.legendary,
        requirements: {'uniqueCards': 100},
        rewards: {'xp': 2500, 'gold': 1000, 'cards': ['legendary_card_pack']},
      ),

      // Exploration Achievements
      Achievement(
        id: 'explorer',
        name: 'Explorer',
        description: 'Visit 5 different locations',
        type: AchievementType.exploration,
        rarity: AchievementRarity.common,
        requirements: {'locationsVisited': 5},
        rewards: {'xp': 200, 'gold': 100},
      ),
      Achievement(
        id: 'wanderer',
        name: 'Wanderer',
        description: 'Travel 100 kilometers',
        type: AchievementType.exploration,
        rarity: AchievementRarity.uncommon,
        requirements: {'totalDistance': 100000}, // in meters
        rewards: {'xp': 500, 'gold': 250, 'cards': ['travel_boots']},
      ),

      // Special Achievements
      Achievement(
        id: 'early_adopter',
        name: 'Early Adopter',
        description: 'Join during the beta period',
        type: AchievementType.special,
        rarity: AchievementRarity.mythic,
        requirements: {'betaUser': true},
        rewards: {'xp': 1000, 'gold': 500, 'cards': ['beta_badge']},
        isHidden: true,
      ),
      Achievement(
        id: 'daily_dedication',
        name: 'Daily Dedication',
        description: 'Log in for 30 consecutive days',
        type: AchievementType.special,
        rarity: AchievementRarity.epic,
        requirements: {'consecutiveLogins': 30},
        rewards: {'xp': 1500, 'gold': 750, 'cards': ['dedication_crown']},
      ),
    ];

    for (final achievement in achievements) {
      _achievements[achievement.id] = achievement;
    }
  }

  /// Update user progress for specific metrics
  Future<void> updateProgress(String userId, Map<String, dynamic> updates) async {
    if (_userStats[userId] == null) {
      _userStats[userId] = <String, dynamic>{};
    }

    final userStats = _userStats[userId] as Map<String, dynamic>;
    final previousStats = Map<String, dynamic>.from(userStats);
    
    // Update stats
    for (final entry in updates.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value is int) {
        userStats[key] = (userStats[key] ?? 0) + value;
      } else if (value is double) {
        userStats[key] = (userStats[key] ?? 0.0) + value;
      } else {
        userStats[key] = value;
      }
    }

    // Check for achievement unlocks
    await _checkAchievements(userId, userStats, previousStats);
    
    // Save progress
    await _saveUserProgress(userId);
  }

  /// Check achievements for a user
  Future<void> _checkAchievements(String userId, Map<String, dynamic> currentStats, Map<String, dynamic> previousStats) async {
    final unlockedAchievements = <String>[];
    
    for (final achievement in _achievements.values) {
      // Skip if not available yet
      if (achievement.availableFrom != null && DateTime.now().isBefore(achievement.availableFrom!)) {
        continue;
      }
      
      // Skip if expired
      if (achievement.availableUntil != null && DateTime.now().isAfter(achievement.availableUntil!)) {
        continue;
      }
      
      // Check prerequisites
      if (achievement.prerequisites.isNotEmpty) {
        final hasPrerequisites = achievement.prerequisites.every((prereqId) {
          final progress = _getUserProgress(userId, prereqId);
          return progress?.isCompleted == true;
        });
        if (!hasPrerequisites) continue;
      }
      
      final progress = _getUserProgress(userId, achievement.id);
      
      // Skip if already completed and not repeatable
      if (progress?.isCompleted == true && !achievement.isRepeatable) {
        continue;
      }
      
      // Check requirements
      bool meetsRequirements = true;
      final progressData = <String, dynamic>{};
      
      for (final requirement in achievement.requirements.entries) {
        final key = requirement.key;
        final requiredValue = requirement.value;
        final currentValue = currentStats[key] ?? 0;
        
        progressData[key] = currentValue;
        
        if (currentValue < requiredValue) {
          meetsRequirements = false;
        }
      }
      
      if (meetsRequirements) {
        // Achievement unlocked!
        await _unlockAchievement(userId, achievement.id, progressData);
        unlockedAchievements.add(achievement.id);
      } else {
        // Update progress
        await _updateAchievementProgress(userId, achievement.id, progressData);
      }
    }
    
    if (unlockedAchievements.isNotEmpty) {
      developer.log('Unlocked ${unlockedAchievements.length} achievements for user $userId', name: agentId);
    }
  }

  /// Unlock an achievement
  Future<void> _unlockAchievement(String userId, String achievementId, Map<String, dynamic> progressData) async {
    final achievement = _achievements[achievementId];
    if (achievement == null) return;
    
    final existingProgress = _getUserProgress(userId, achievementId);
    final completionCount = (existingProgress?.completionCount ?? 0) + 1;
    
    final progress = AchievementProgress(
      achievementId: achievementId,
      userId: userId,
      progress: progressData,
      isCompleted: true,
      completedAt: DateTime.now(),
      completionCount: completionCount,
    );
    
    _userProgress.putIfAbsent(userId, () => {})[achievementId] = progress;
    
    // Create notification
    final notification = AchievementNotification(
      achievementId: achievementId,
      userId: userId,
      title: 'Achievement Unlocked!',
      message: '${achievement.name}: ${achievement.description}',
      rarity: achievement.rarity,
      rewards: achievement.rewards,
    );
    
    _notifications.add(notification);
    
    // Distribute rewards
    await _distributeRewards(userId, achievement.rewards);
    
    // Publish achievement unlocked event
    await publishEvent(createEvent(
      eventType: EventTypes.achievementUnlocked,
      data: {
        'achievementId': achievementId,
        'userId': userId,
        'achievement': achievement.toJson(),
        'rewards': achievement.rewards,
        'completionCount': completionCount,
      },
      priority: EventPriority.high,
    ));
    
    developer.log('Achievement unlocked: $achievementId for user $userId', name: agentId);
  }

  /// Update achievement progress
  Future<void> _updateAchievementProgress(String userId, String achievementId, Map<String, dynamic> progressData) async {
    final existingProgress = _getUserProgress(userId, achievementId);
    
    final progress = AchievementProgress(
      achievementId: achievementId,
      userId: userId,
      progress: progressData,
      isCompleted: false,
      completionCount: existingProgress?.completionCount ?? 0,
    );
    
    _userProgress.putIfAbsent(userId, () => {})[achievementId] = progress;
    
    // Publish progress update event
    await publishEvent(createEvent(
      eventType: EventTypes.achievementProgress,
      data: {
        'achievementId': achievementId,
        'userId': userId,
        'progress': progressData,
      },
    ));
  }

  /// Distribute rewards to the user
  Future<void> _distributeRewards(String userId, Map<String, dynamic> rewards) async {
    // Send rewards to Character Management Agent
    if (rewards.containsKey('xp') || rewards.containsKey('statBonus')) {
      await publishEvent(createEvent(
        eventType: 'character_reward',
        targetAgent: 'character_management',
        data: {
          'userId': userId,
          'xp': rewards['xp'] ?? 0,
          'statBonus': rewards['statBonus'] ?? {},
          'source': 'achievement',
        },
      ));
    }
    
    // Send items/cards to inventory
    if (rewards.containsKey('cards') || rewards.containsKey('gold')) {
      await publishEvent(createEvent(
        eventType: 'inventory_reward',
        targetAgent: 'card_system',
        data: {
          'userId': userId,
          'cards': rewards['cards'] ?? [],
          'gold': rewards['gold'] ?? 0,
          'source': 'achievement',
        },
      ));
    }
  }

  /// Get user progress for an achievement
  AchievementProgress? _getUserProgress(String userId, String achievementId) {
    return _userProgress[userId]?[achievementId];
  }

  /// Load user progress from data persistence
  Future<void> _loadUserProgress() async {
    // TODO: Load from Data Persistence Agent
    developer.log('Loading user progress from storage', name: agentId);
  }

  /// Save user progress to data persistence
  Future<void> _saveUserProgress(String userId) async {
    // TODO: Save to Data Persistence Agent
    final userProgress = _userProgress[userId];
    if (userProgress != null) {
      await publishEvent(createEvent(
        eventType: 'save_data',
        targetAgent: 'data_persistence',
        data: {
          'collection': 'achievement_progress',
          'id': userId,
          'data': {
            'progress': userProgress.map((k, v) => MapEntry(k, v.toJson())),
            'stats': _userStats[userId] ?? {},
          },
        },
      ));
    }
  }

  /// Start progress tracking
  void _startProgressTracking() {
    _progressTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _performPeriodicChecks();
    });
  }

  /// Perform periodic checks
  void _performPeriodicChecks() {
    // Check daily goals, streaks, etc.
    if (_currentUserId != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Example: Check daily login streak
      final userStats = _userStats[_currentUserId] as Map<String, dynamic>?;
      if (userStats != null) {
        final lastLogin = userStats['lastLoginDate'];
        if (lastLogin != null) {
          final lastLoginDate = DateTime.parse(lastLogin);
          final lastLoginDay = DateTime(lastLoginDate.year, lastLoginDate.month, lastLoginDate.day);
          
          if (today.difference(lastLoginDay).inDays == 1) {
            // Consecutive day
            userStats['consecutiveLogins'] = (userStats['consecutiveLogins'] ?? 0) + 1;
          } else if (today.difference(lastLoginDay).inDays > 1) {
            // Streak broken
            userStats['consecutiveLogins'] = 1;
          }
        }
        
        userStats['lastLoginDate'] = now.toIso8601String();
        updateProgress(_currentUserId!, {'consecutiveLogins': 0}); // Trigger check
      }
    }
  }

  /// Handle character updated events
  Future<AgentEventResponse?> _handleCharacterUpdated(AgentEvent event) async {
    final characterId = event.data['characterId'];
    if (_currentUserId != null) {
      await updateProgress(_currentUserId!, {
        'characterUpdated': 1,
        'characterCreated': 1,
      });
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'character_update_processed',
      data: {'characterId': characterId},
    );
  }

  /// Handle character level up events
  Future<AgentEventResponse?> _handleCharacterLevelUp(AgentEvent event) async {
    final characterId = event.data['characterId'];
    final newLevel = event.data['newLevel'];
    
    if (_currentUserId != null) {
      await updateProgress(_currentUserId!, {
        'characterLevel': newLevel,
        'levelUps': 1,
      });
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'level_up_processed',
      data: {'characterId': characterId, 'newLevel': newLevel},
    );
  }

  /// Handle character XP gained events
  Future<AgentEventResponse?> _handleCharacterXpGained(AgentEvent event) async {
    final xpGained = event.data['xpGained'] ?? 0;
    
    if (_currentUserId != null && xpGained > 0) {
      await updateProgress(_currentUserId!, {
        'totalXp': xpGained,
      });
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'xp_gain_processed',
      data: {'xpGained': xpGained},
    );
  }

  /// Handle battle result events
  Future<AgentEventResponse?> _handleBattleResult(AgentEvent event) async {
    final isVictory = event.data['isVictory'] ?? false;
    final battleId = event.data['battleId'];
    
    if (_currentUserId != null) {
      final updates = <String, dynamic>{
        'battlesPlayed': 1,
      };
      
      if (isVictory) {
        updates['battlesWon'] = 1;
        
        // Check for special enemy defeats
        final statistics = event.data['statistics'] as Map<String, dynamic>?;
        if (statistics != null) {
          // Add specific enemy kill tracking
          updates['enemiesDefeated'] = 1;
        }
      } else {
        updates['battlesLost'] = 1;
      }
      
      await updateProgress(_currentUserId!, updates);
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'battle_result_processed',
      data: {'battleId': battleId, 'isVictory': isVictory},
    );
  }

  /// Handle fitness update events
  Future<AgentEventResponse?> _handleFitnessUpdate(AgentEvent event) async {
    final steps = event.data['steps'] ?? 0;
    final calories = event.data['calories'] ?? 0;
    final duration = event.data['duration'] ?? 0;
    
    if (_currentUserId != null && steps > 0) {
      await updateProgress(_currentUserId!, {
        'totalSteps': steps,
        'totalCalories': calories,
        'totalActiveMinutes': duration,
        'dailySteps': steps, // This should be tracked separately for daily goals
      });
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'fitness_update_processed',
      data: {'steps': steps, 'calories': calories},
    );
  }

  /// Handle fitness goal reached events
  Future<AgentEventResponse?> _handleFitnessGoalReached(AgentEvent event) async {
    final goalType = event.data['goalType'];
    
    if (_currentUserId != null) {
      await updateProgress(_currentUserId!, {
        '${goalType}Reached': 1,
        'goalsReached': 1,
      });
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'fitness_goal_processed',
      data: {'goalType': goalType},
    );
  }

  /// Handle quest completed events
  Future<AgentEventResponse?> _handleQuestCompleted(AgentEvent event) async {
    final questId = event.data['questId'];
    
    if (_currentUserId != null) {
      await updateProgress(_currentUserId!, {
        'questsCompleted': 1,
      });
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'quest_completion_processed',
      data: {'questId': questId},
    );
  }

  /// Handle card scanned events
  Future<AgentEventResponse?> _handleCardScanned(AgentEvent event) async {
    final cardId = event.data['cardId'];
    
    if (_currentUserId != null) {
      await updateProgress(_currentUserId!, {
        'cardsScanned': 1,
      });
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'card_scan_processed',
      data: {'cardId': cardId},
    );
  }

  /// Handle inventory changed events
  Future<AgentEventResponse?> _handleInventoryChanged(AgentEvent event) async {
    final itemsGained = List<String>.from(event.data['itemsGained'] ?? []);
    
    if (_currentUserId != null && itemsGained.isNotEmpty) {
      await updateProgress(_currentUserId!, {
        'itemsCollected': itemsGained.length,
        'uniqueCards': itemsGained.length, // Simplified - should track unique cards properly
      });
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'inventory_change_processed',
      data: {'itemsGained': itemsGained.length},
    );
  }

  /// Handle location update events
  Future<AgentEventResponse?> _handleLocationUpdate(AgentEvent event) async {
    final latitude = event.data['latitude'];
    final longitude = event.data['longitude'];
    
    if (_currentUserId != null && latitude != null && longitude != null) {
      await updateProgress(_currentUserId!, {
        'locationUpdates': 1,
      });
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'location_update_processed',
      data: {'processed': true},
    );
  }

  /// Handle POI detected events
  Future<AgentEventResponse?> _handlePoiDetected(AgentEvent event) async {
    final poiId = event.data['poiId'];
    
    if (_currentUserId != null) {
      await updateProgress(_currentUserId!, {
        'poisVisited': 1,
        'locationsVisited': 1,
      });
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'poi_detection_processed',
      data: {'poiId': poiId},
    );
  }

  /// Handle get achievements events
  Future<AgentEventResponse?> _handleGetAchievements(AgentEvent event) async {
    final includeHidden = event.data['includeHidden'] ?? false;
    final type = event.data['type']; // Optional filter by type
    
    final filteredAchievements = _achievements.values.where((achievement) {
      if (!includeHidden && achievement.isHidden) return false;
      if (type != null && achievement.type.toString() != type) return false;
      return true;
    }).toList();

    return createResponse(
      originalEventId: event.id,
      responseType: 'achievements_list',
      data: {
        'achievements': filteredAchievements.map((a) => a.toJson()).toList(),
        'count': filteredAchievements.length,
      },
    );
  }

  /// Handle get user progress events
  Future<AgentEventResponse?> _handleGetUserProgress(AgentEvent event) async {
    final userId = event.data['userId'] ?? _currentUserId;
    
    if (userId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'user_progress_failed',
        data: {'error': 'No user ID provided'},
        success: false,
      );
    }

    final userProgress = _userProgress[userId] ?? {};
    final userStats = _userStats[userId] ?? {};

    return createResponse(
      originalEventId: event.id,
      responseType: 'user_progress',
      data: {
        'userId': userId,
        'progress': userProgress.map((k, v) => MapEntry(k, v.toJson())),
        'stats': userStats,
        'completedCount': userProgress.values.where((p) => p.isCompleted).length,
        'totalCount': _achievements.length,
      },
    );
  }

  /// Handle check achievement events
  Future<AgentEventResponse?> _handleCheckAchievement(AgentEvent event) async {
    final achievementId = event.data['achievementId'];
    final userId = event.data['userId'] ?? _currentUserId;
    
    if (userId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'achievement_check_failed',
        data: {'error': 'No user ID provided'},
        success: false,
      );
    }

    final progress = _getUserProgress(userId, achievementId);
    final achievement = _achievements[achievementId];

    return createResponse(
      originalEventId: event.id,
      responseType: 'achievement_status',
      data: {
        'achievementId': achievementId,
        'userId': userId,
        'isCompleted': progress?.isCompleted ?? false,
        'progress': progress?.progress ?? {},
        'achievement': achievement?.toJson(),
        'completionCount': progress?.completionCount ?? 0,
      },
    );
  }

  /// Handle unlock achievement events (manual unlock)
  Future<AgentEventResponse?> _handleUnlockAchievement(AgentEvent event) async {
    final achievementId = event.data['achievementId'];
    final userId = event.data['userId'] ?? _currentUserId;
    
    if (userId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'achievement_unlock_failed',
        data: {'error': 'No user ID provided'},
        success: false,
      );
    }

    await _unlockAchievement(userId, achievementId, {});

    return createResponse(
      originalEventId: event.id,
      responseType: 'achievement_unlocked',
      data: {'achievementId': achievementId, 'userId': userId},
    );
  }

  /// Handle get notifications events
  Future<AgentEventResponse?> _handleGetNotifications(AgentEvent event) async {
    final userId = event.data['userId'] ?? _currentUserId;
    
    if (userId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'notifications_failed',
        data: {'error': 'No user ID provided'},
        success: false,
      );
    }

    final userNotifications = _notifications.where((n) => n.userId == userId).toList();

    return createResponse(
      originalEventId: event.id,
      responseType: 'notifications_list',
      data: {
        'notifications': userNotifications.map((n) => {
          'achievementId': n.achievementId,
          'title': n.title,
          'message': n.message,
          'rarity': n.rarity.toString(),
          'rewards': n.rewards,
          'timestamp': n.timestamp.toIso8601String(),
        }).toList(),
        'count': userNotifications.length,
      },
    );
  }

  /// Handle clear notifications events
  Future<AgentEventResponse?> _handleClearNotifications(AgentEvent event) async {
    final userId = event.data['userId'] ?? _currentUserId;
    
    if (userId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'clear_notifications_failed',
        data: {'error': 'No user ID provided'},
        success: false,
      );
    }

    final countBefore = _notifications.length;
    _notifications.removeWhere((n) => n.userId == userId);
    final countAfter = _notifications.length;

    return createResponse(
      originalEventId: event.id,
      responseType: 'notifications_cleared',
      data: {
        'userId': userId,
        'cleared': countBefore - countAfter,
      },
    );
  }

  /// Handle user login events
  Future<AgentEventResponse?> _handleUserLogin(AgentEvent event) async {
    final userId = event.data['userId'];
    _currentUserId = userId;
    
    if (userId != null) {
      // Initialize user stats if needed
      if (_userStats[userId] == null) {
        _userStats[userId] = <String, dynamic>{};
      }
      
      // Track login
      await updateProgress(userId, {'logins': 1});
      await _loadUserProgress();
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'user_login_processed',
      data: {'userId': userId},
    );
  }

  /// Handle user logout events
  Future<AgentEventResponse?> _handleUserLogout(AgentEvent event) async {
    if (_currentUserId != null) {
      await _saveUserProgress(_currentUserId!);
      _currentUserId = null;
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'user_logout_processed',
      data: {'loggedOut': true},
    );
  }

  @override
  Future<void> onDispose() async {
    _progressTimer?.cancel();
    
    // Save all user progress
    for (final userId in _userProgress.keys) {
      await _saveUserProgress(userId);
    }
    
    developer.log('Achievement Agent disposed', name: agentId);
  }
}