import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:health/health.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/event_bus.dart';
import '../../services/fitness_tracker_service.dart';
import '../../services/physical_activity_service.dart';
import 'integration_orchestrator_agent.dart';

/// Fitness Tracking Agent - Convert real-world activities into character progression
class FitnessTrackingAgent extends BaseAgent {
  static const String _agentTypeId = 'fitness_tracking';

  final FitnessTrackerService _fitnessService;
  final PhysicalActivityService _activityService;
  
  // Health data tracking
  final Health _health = Health();
  StreamSubscription<StepCount>? _stepCountSubscription;
  Timer? _periodicUpdateTimer;
  
  // Activity tracking
  Map<String, int> _dailyStats = {};
  DateTime _lastUpdateTime = DateTime.now();
  int _totalStepsToday = 0;
  int _totalCaloriesToday = 0;
  int _totalActiveMinutesToday = 0;
  
  // Goals and thresholds
  static const int dailyStepGoal = 10000;
  static const int dailyCalorieGoal = 2000;
  static const int dailyActiveMinutesGoal = 60;
  
  // Activity detection thresholds
  static const int walkingStepsPerMinute = 100;
  static const int runningStepsPerMinute = 180;
  static const int cyclingCaloriesPerMinute = 8;
  
  bool _isInitialized = false;
  bool _hasHealthPermissions = false;

  FitnessTrackingAgent({
    FitnessTrackerService? fitnessService,
    PhysicalActivityService? activityService,
  }) : _fitnessService = fitnessService ?? FitnessTrackerService(),
        _activityService = activityService ?? PhysicalActivityService(),
        super(agentId: _agentTypeId);

  @override
  Future<void> onInitialize() async {
    developer.log('Initializing Fitness Tracking Agent', name: agentId);
    
    // Request health permissions
    await _requestHealthPermissions();
    
    // Initialize health data tracking
    if (_hasHealthPermissions) {
      await _initializeHealthTracking();
    }
    
    // Start periodic updates
    _startPeriodicUpdates();
    
    // Load today's stats
    await _loadDailyStats();
    
    _isInitialized = true;
    developer.log('Fitness Tracking Agent initialized', name: agentId);
  }

  @override
  void subscribeToEvents() {
    // Character events to track activity rewards
    subscribe(EventTypes.characterUpdated, _handleCharacterUpdated);
    
    // Quest events for fitness-based quests
    subscribe(EventTypes.questStarted, _handleQuestStarted);
    
    // Manual activity logging
    subscribe('log_activity', _handleLogActivity);
    subscribe('sync_fitness_data', _handleSyncFitnessData);
    subscribe('get_fitness_stats', _handleGetFitnessStats);
    subscribe('set_fitness_goal', _handleSetFitnessGoal);
    
    // Health permission requests
    subscribe('request_health_permissions', _handleRequestHealthPermissions);
  }

  /// Get current fitness stats
  Map<String, dynamic> getCurrentStats() {
    return {
      'steps': _totalStepsToday,
      'calories': _totalCaloriesToday,
      'activeMinutes': _totalActiveMinutesToday,
      'stepGoal': dailyStepGoal,
      'calorieGoal': dailyCalorieGoal,
      'activeMinutesGoal': dailyActiveMinutesGoal,
      'stepProgress': (_totalStepsToday / dailyStepGoal).clamp(0.0, 1.0),
      'calorieProgress': (_totalCaloriesToday / dailyCalorieGoal).clamp(0.0, 1.0),
      'activeMinutesProgress': (_totalActiveMinutesToday / dailyActiveMinutesGoal).clamp(0.0, 1.0),
      'lastUpdate': _lastUpdateTime.toIso8601String(),
      'hasPermissions': _hasHealthPermissions,
    };
  }

  /// Request health permissions
  Future<void> _requestHealthPermissions() async {
    try {
      // Request activity recognition permission
      final activityStatus = await Permission.activityRecognition.request();
      
      // Define health data types we want to access
      final types = [
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.WORKOUT,
        HealthDataType.DISTANCE_WALKING_RUNNING,
      ];

      // Request health permissions
      _hasHealthPermissions = await _health.requestAuthorization(types);
      
      developer.log('Health permissions granted: $_hasHealthPermissions', name: agentId);
      
      if (!_hasHealthPermissions) {
        developer.log('Health permissions denied - using fallback tracking', name: agentId);
        await _initializeFallbackTracking();
      }
      
    } catch (e) {
      developer.log('Error requesting health permissions: $e', name: agentId);
      _hasHealthPermissions = false;
      await _initializeFallbackTracking();
    }
  }

  /// Initialize health data tracking
  Future<void> _initializeHealthTracking() async {
    try {
      // Initialize step counter
      if (Platform.isAndroid || Platform.isIOS) {
        _stepCountSubscription = Pedometer.stepCountStream.listen(
          _onStepCount,
          onError: _onStepCountError,
        );
      }

      developer.log('Health tracking initialized', name: agentId);
    } catch (e) {
      developer.log('Error initializing health tracking: $e', name: agentId);
      await _initializeFallbackTracking();
    }
  }

  /// Initialize fallback tracking when health APIs are unavailable
  Future<void> _initializeFallbackTracking() async {
    developer.log('Initializing fallback fitness tracking', name: agentId);
    
    // Use timer-based simulation for demo purposes
    Timer.periodic(const Duration(minutes: 1), (timer) {
      _simulateActivity();
    });
  }

  /// Start periodic updates
  void _startPeriodicUpdates() {
    _periodicUpdateTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _performPeriodicUpdate();
    });
  }

  /// Handle step count updates
  void _onStepCount(StepCount stepCount) {
    final stepsToday = stepCount.steps;
    final previousSteps = _totalStepsToday;
    
    _totalStepsToday = stepsToday;
    
    // Calculate step increment
    final stepIncrement = stepsToday - previousSteps;
    if (stepIncrement > 0) {
      _processStepIncrement(stepIncrement);
    }
  }

  /// Handle step count errors
  void _onStepCountError(error) {
    developer.log('Step count error: $error', name: agentId);
  }

  /// Process step increment and detect activity
  void _processStepIncrement(int stepIncrement) {
    final now = DateTime.now();
    final timeDiff = now.difference(_lastUpdateTime).inMinutes;
    
    if (timeDiff > 0) {
      final stepsPerMinute = stepIncrement / timeDiff;
      
      // Detect activity type based on step rate
      String activityType = 'sedentary';
      int estimatedCalories = 0;
      
      if (stepsPerMinute >= runningStepsPerMinute) {
        activityType = 'running';
        estimatedCalories = (timeDiff * 12).round(); // ~12 cal/min running
      } else if (stepsPerMinute >= walkingStepsPerMinute) {
        activityType = 'walking';
        estimatedCalories = (timeDiff * 4).round(); // ~4 cal/min walking
      }
      
      if (activityType != 'sedentary') {
        _recordActivity(activityType, timeDiff, estimatedCalories, stepIncrement);
      }
    }
    
    _lastUpdateTime = now;
  }

  /// Record an activity
  Future<void> _recordActivity(String activityType, int duration, int calories, int steps) async {
    developer.log('Activity detected: $activityType for ${duration}min, ${calories}cal, ${steps}steps', name: agentId);
    
    // Update totals
    _totalCaloriesToday += calories;
    _totalActiveMinutesToday += duration;
    
    // Create fitness update data
    final fitnessData = FitnessUpdateData(
      activityType: activityType,
      duration: duration,
      calories: calories,
      steps: steps,
      xpGained: _calculateXpFromActivity(activityType, duration, calories, steps),
    );

    // Publish fitness update event
    await publishEvent(createEvent(
      eventType: EventTypes.fitnessUpdate,
      data: fitnessData.toJson(),
    ));

    // Publish activity detected event
    await publishEvent(createEvent(
      eventType: EventTypes.activityDetected,
      data: {
        'activityType': activityType,
        'duration': duration,
        'calories': calories,
        'steps': steps,
        'timestamp': DateTime.now().toIso8601String(),
      },
    ));

    // Check for goal achievements
    await _checkGoalAchievements();
  }

  /// Calculate XP from activity
  int _calculateXpFromActivity(String activityType, int duration, int calories, int steps) {
    int xp = 0;
    
    // Base XP from duration (1 XP per minute of activity)
    xp += duration;
    
    // Bonus XP based on activity intensity
    switch (activityType.toLowerCase()) {
      case 'running':
        xp += duration * 2; // 3x total for running
        break;
      case 'cycling':
        xp += (duration * 1.5).round(); // 2.5x total for cycling
        break;
      case 'strength_training':
        xp += duration * 3; // 4x total for strength training
        break;
      case 'swimming':
        xp += duration * 2; // 3x total for swimming
        break;
      case 'walking':
        xp += (duration * 0.5).round(); // 1.5x total for walking
        break;
    }
    
    // Bonus XP from calories (1 XP per 20 calories)
    xp += calories ~/ 20;
    
    // Bonus XP from steps (1 XP per 200 steps)
    xp += steps ~/ 200;
    
    return xp;
  }

  /// Check for goal achievements
  Future<void> _checkGoalAchievements() async {
    final achievements = <String>[];
    
    // Check step goal
    if (_totalStepsToday >= dailyStepGoal && !_dailyStats.containsKey('step_goal_reached')) {
      achievements.add('daily_step_goal');
      _dailyStats['step_goal_reached'] = 1;
    }
    
    // Check calorie goal
    if (_totalCaloriesToday >= dailyCalorieGoal && !_dailyStats.containsKey('calorie_goal_reached')) {
      achievements.add('daily_calorie_goal');
      _dailyStats['calorie_goal_reached'] = 1;
    }
    
    // Check active minutes goal
    if (_totalActiveMinutesToday >= dailyActiveMinutesGoal && !_dailyStats.containsKey('active_minutes_goal_reached')) {
      achievements.add('daily_active_minutes_goal');
      _dailyStats['active_minutes_goal_reached'] = 1;
    }
    
    // Publish goal achievements
    for (final achievement in achievements) {
      await publishEvent(createEvent(
        eventType: EventTypes.fitnessGoalReached,
        data: {
          'goalType': achievement,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ));
    }
  }

  /// Perform periodic update
  Future<void> _performPeriodicUpdate() async {
    if (!_hasHealthPermissions) return;
    
    try {
      // Fetch health data for today
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      // Fetch step count
      final stepData = await _health.getHealthDataFromTypes(
        [HealthDataType.STEPS],
        startOfDay,
        now,
      );
      
      if (stepData.isNotEmpty) {
        final totalSteps = stepData
            .map((data) => data.value as int)
            .reduce((a, b) => a + b);
        _totalStepsToday = totalSteps;
      }
      
      // Fetch calories
      final calorieData = await _health.getHealthDataFromTypes(
        [HealthDataType.ACTIVE_ENERGY_BURNED],
        startOfDay,
        now,
      );
      
      if (calorieData.isNotEmpty) {
        final totalCalories = calorieData
            .map((data) => (data.value as double).round())
            .reduce((a, b) => a + b);
        _totalCaloriesToday = totalCalories;
      }
      
      developer.log('Updated fitness stats: ${_totalStepsToday} steps, ${_totalCaloriesToday} calories', name: agentId);
      
    } catch (e) {
      developer.log('Error updating fitness data: $e', name: agentId);
    }
  }

  /// Simulate activity for fallback mode
  void _simulateActivity() {
    // Simple simulation for demo purposes
    final random = DateTime.now().millisecond % 100;
    
    if (random < 20) {
      // 20% chance of simulated activity
      final activities = ['walking', 'running', 'cycling'];
      final activityType = activities[random % activities.length];
      final duration = 5 + (random % 15); // 5-20 minutes
      final calories = duration * (activityType == 'running' ? 12 : 4);
      final steps = duration * (activityType == 'running' ? 180 : 100);
      
      _recordActivity(activityType, duration, calories, steps);
    }
  }

  /// Load daily stats from storage
  Future<void> _loadDailyStats() async {
    try {
      // Load stats from fitness service
      final stats = await _fitnessService.getDailyStats();
      _dailyStats = Map<String, int>.from(stats);
      
      _totalStepsToday = _dailyStats['steps'] ?? 0;
      _totalCaloriesToday = _dailyStats['calories'] ?? 0;
      _totalActiveMinutesToday = _dailyStats['activeMinutes'] ?? 0;
      
    } catch (e) {
      developer.log('Error loading daily stats: $e', name: agentId);
      _dailyStats = {};
    }
  }

  /// Save daily stats to storage
  Future<void> _saveDailyStats() async {
    try {
      _dailyStats['steps'] = _totalStepsToday;
      _dailyStats['calories'] = _totalCaloriesToday;
      _dailyStats['activeMinutes'] = _totalActiveMinutesToday;
      
      await _fitnessService.saveDailyStats(_dailyStats);
    } catch (e) {
      developer.log('Error saving daily stats: $e', name: agentId);
    }
  }

  /// Handle character updated events
  Future<AgentEventResponse?> _handleCharacterUpdated(AgentEvent event) async {
    // Character updates might trigger fitness-related achievements
    return createResponse(
      originalEventId: event.id,
      responseType: 'character_update_acknowledged',
      data: {'acknowledged': true},
    );
  }

  /// Handle quest started events
  Future<AgentEventResponse?> _handleQuestStarted(AgentEvent event) async {
    final questId = event.data['questId'];
    final questType = event.data['questType'];
    
    // Check if this is a fitness-related quest
    if (questType == 'fitness' || questType == 'activity') {
      developer.log('Fitness quest started: $questId', name: agentId);
      
      // Start tracking specific metrics for this quest
      // This would be expanded based on quest requirements
    }
    
    return createResponse(
      originalEventId: event.id,
      responseType: 'fitness_quest_acknowledged',
      data: {'questId': questId},
    );
  }

  /// Handle manual activity logging
  Future<AgentEventResponse?> _handleLogActivity(AgentEvent event) async {
    final activityType = event.data['activityType'];
    final duration = event.data['duration'] ?? 0;
    final calories = event.data['calories'] ?? 0;
    final steps = event.data['steps'] ?? 0;
    
    developer.log('Manual activity logged: $activityType', name: agentId);
    
    await _recordActivity(activityType, duration, calories, steps);
    
    return createResponse(
      originalEventId: event.id,
      responseType: 'activity_logged',
      data: {
        'activityType': activityType,
        'xpGained': _calculateXpFromActivity(activityType, duration, calories, steps),
      },
    );
  }

  /// Handle fitness data sync requests
  Future<AgentEventResponse?> _handleSyncFitnessData(AgentEvent event) async {
    developer.log('Syncing fitness data', name: agentId);
    
    await _performPeriodicUpdate();
    await _saveDailyStats();
    
    return createResponse(
      originalEventId: event.id,
      responseType: 'fitness_data_synced',
      data: getCurrentStats(),
    );
  }

  /// Handle fitness stats requests
  Future<AgentEventResponse?> _handleGetFitnessStats(AgentEvent event) async {
    return createResponse(
      originalEventId: event.id,
      responseType: 'fitness_stats',
      data: getCurrentStats(),
    );
  }

  /// Handle fitness goal setting
  Future<AgentEventResponse?> _handleSetFitnessGoal(AgentEvent event) async {
    final goalType = event.data['goalType'];
    final goalValue = event.data['goalValue'];
    
    developer.log('Fitness goal set: $goalType = $goalValue', name: agentId);
    
    // Store custom goals (would be expanded in full implementation)
    _dailyStats['${goalType}_goal'] = goalValue;
    await _saveDailyStats();
    
    return createResponse(
      originalEventId: event.id,
      responseType: 'fitness_goal_set',
      data: {'goalType': goalType, 'goalValue': goalValue},
    );
  }

  /// Handle health permission requests
  Future<AgentEventResponse?> _handleRequestHealthPermissions(AgentEvent event) async {
    await _requestHealthPermissions();
    
    if (_hasHealthPermissions) {
      await _initializeHealthTracking();
    }
    
    return createResponse(
      originalEventId: event.id,
      responseType: 'health_permissions_response',
      data: {'granted': _hasHealthPermissions},
    );
  }

  @override
  Future<void> onDispose() async {
    _stepCountSubscription?.cancel();
    _periodicUpdateTimer?.cancel();
    await _saveDailyStats();
    
    developer.log('Fitness Tracking Agent disposed', name: agentId);
  }
}