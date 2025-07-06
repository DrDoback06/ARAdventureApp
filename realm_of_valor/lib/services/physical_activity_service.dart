import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health/health.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/physical_activity_model.dart';
import '../models/character_model.dart';
import 'dart:convert';

class PhysicalActivityService {
  static final PhysicalActivityService _instance = PhysicalActivityService._internal();
  factory PhysicalActivityService() => _instance;
  PhysicalActivityService._internal();

  final Health _health = Health();
  final Random _random = Random();
  
  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;
  
  FitnessProfile? _currentProfile;
  
  // Initialize health tracking
  Future<bool> initializeHealthTracking(String playerId) async {
    try {
      // Request permissions
      final permissionStatus = await Permission.activityRecognition.request();
      if (!permissionStatus.isGranted) {
        return false;
      }

      // Configure health data types
      final types = [
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
        HealthDataType.DISTANCE_WALKING_RUNNING,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.WORKOUT,
      ];

      // Request health permissions
      final healthPermission = await _health.requestAuthorization(types);
      if (!healthPermission) {
        return false;
      }

      // Load or create fitness profile
      _currentProfile = await _loadFitnessProfile(playerId) ?? 
          FitnessProfile(playerId: playerId);

      // Start step counting
      await _startStepCounting();

      return true;
    } catch (e) {
      print('Error initializing health tracking: $e');
      return false;
    }
  }

  // Start step counting
  Future<void> _startStepCounting() async {
    try {
      _stepCountSubscription = Pedometer.stepCountStream.listen(
        (StepCount event) {
          _updateStepCount(event.steps);
        },
        onError: (error) {
          print('Step counting error: $error');
        },
      );

      _pedestrianStatusSubscription = Pedometer.pedestrianStatusStream.listen(
        (PedestrianStatus event) {
          _updatePedestrianStatus(event.status);
        },
        onError: (error) {
          print('Pedestrian status error: $error');
        },
      );
    } catch (e) {
      print('Error starting step counting: $e');
    }
  }

  // Update step count
  void _updateStepCount(int steps) {
    if (_currentProfile == null) return;

    final today = DateTime.now();
    var todayActivity = _currentProfile!.getTodayActivity();
    
    if (todayActivity == null) {
      todayActivity = DailyActivity(date: today);
      _currentProfile!.dailyActivities.add(todayActivity);
    }

    // Update step count
    final updatedActivity = todayActivity.copyWith(totalSteps: steps);
    final index = _currentProfile!.dailyActivities.indexWhere(
      (activity) => _isSameDay(activity.date, today),
    );
    
    if (index != -1) {
      _currentProfile!.dailyActivities[index] = updatedActivity;
    }

    // Check for step milestones
    _checkStepMilestones(steps);
    
    // Save profile
    _saveFitnessProfile(_currentProfile!);
  }

  // Update pedestrian status
  void _updatePedestrianStatus(String status) {
    // This could be used for real-time activity detection
    print('Pedestrian status: $status');
  }

  // Get health data for date range
  Future<List<HealthDataPoint>> getHealthData(DateTime start, DateTime end) async {
    try {
      final types = [
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
        HealthDataType.DISTANCE_WALKING_RUNNING,
        HealthDataType.ACTIVE_ENERGY_BURNED,
      ];

      return await _health.getHealthDataFromTypes(
        types: types,
        startTime: start,
        endTime: end,
      );
    } catch (e) {
      print('Error getting health data: $e');
      return [];
    }
  }

  // Start workout session
  Future<WorkoutSession> startWorkoutSession({
    required String name,
    required ActivityType type,
    required ActivityIntensity intensity,
  }) async {
    final session = WorkoutSession(
      name: name,
      type: type,
      intensity: intensity,
    );

    // In a real implementation, you'd start health data collection here
    await _health.writeWorkoutData(
      activityType: _mapActivityTypeToHealth(type),
      start: session.startTime,
      end: session.startTime, // Will be updated when workout ends
    );

    return session;
  }

  // End workout session
  Future<WorkoutSession> endWorkoutSession(WorkoutSession session) async {
    final endTime = DateTime.now();
    final duration = endTime.difference(session.startTime).inSeconds;

    // Get health data for the workout period
    final healthData = await getHealthData(session.startTime, endTime);
    
    // Process health data into metrics
    final metrics = _processHealthDataToMetrics(healthData);

    final completedSession = session.copyWith(
      endTime: endTime,
      duration: duration,
      metrics: metrics,
      isCompleted: true,
    );

    // Apply stat boosts based on workout
    final statBoosts = StatBoost.getActivityBoosts(
      session.type,
      session.intensity.index,
    );

    if (_currentProfile != null) {
      _currentProfile!.activeBoosts.addAll(statBoosts);
      
      // Add workout to today's activity
      final today = DateTime.now();
      var todayActivity = _currentProfile!.getTodayActivity();
      
      if (todayActivity == null) {
        todayActivity = DailyActivity(date: today);
        _currentProfile!.dailyActivities.add(todayActivity);
      }

      final updatedActivity = todayActivity.copyWith(
        workouts: [...todayActivity.workouts, completedSession],
        activeMinutes: todayActivity.activeMinutes + (duration ~/ 60),
      );

      final index = _currentProfile!.dailyActivities.indexWhere(
        (activity) => _isSameDay(activity.date, today),
      );
      
      if (index != -1) {
        _currentProfile!.dailyActivities[index] = updatedActivity;
      }

      await _saveFitnessProfile(_currentProfile!);
    }

    return completedSession;
  }

  // Get active stat boosts
  List<StatBoost> getActiveStatBoosts() {
    if (_currentProfile == null) return [];
    return _currentProfile!.getActiveBoosts();
  }

  // Create fitness goal
  Future<FitnessGoal> createFitnessGoal({
    required String name,
    required String description,
    required ActivityType type,
    required int targetValue,
    required String unit,
    required DateTime endDate,
  }) async {
    final goal = FitnessGoal(
      name: name,
      description: description,
      type: type,
      targetValue: targetValue,
      unit: unit,
      startDate: DateTime.now(),
      endDate: endDate,
    );

    if (_currentProfile != null) {
      _currentProfile!.goals.add(goal);
      await _saveFitnessProfile(_currentProfile!);
    }

    return goal;
  }

  // Update fitness goal progress
  Future<void> updateGoalProgress(String goalId, int progress) async {
    if (_currentProfile == null) return;

    final goalIndex = _currentProfile!.goals.indexWhere((g) => g.id == goalId);
    if (goalIndex == -1) return;

    final goal = _currentProfile!.goals[goalIndex];
    final updatedGoal = FitnessGoal(
      id: goal.id,
      name: goal.name,
      description: goal.description,
      type: goal.type,
      targetValue: goal.targetValue,
      currentValue: progress,
      unit: goal.unit,
      startDate: goal.startDate,
      endDate: goal.endDate,
      isCompleted: progress >= goal.targetValue,
    );

    _currentProfile!.goals[goalIndex] = updatedGoal;

    // Check if goal is completed
    if (updatedGoal.isCompleted && !goal.isCompleted) {
      await _handleGoalCompletion(updatedGoal);
    }

    await _saveFitnessProfile(_currentProfile!);
  }

  // Handle goal completion
  Future<void> _handleGoalCompletion(FitnessGoal goal) async {
    // Award rewards for completing the goal
    final rewards = goal.rewards;
    
    // Apply stat boosts
    final completionBoosts = StatBoost.getActivityBoosts(goal.type, 2);
    
    if (_currentProfile != null) {
      _currentProfile!.activeBoosts.addAll(completionBoosts);
    }

    // Log achievement
    print('Goal completed: ${goal.name}');
  }

  // Check step milestones
  void _checkStepMilestones(int steps) {
    final milestones = [1000, 5000, 10000, 15000, 20000];
    
    for (final milestone in milestones) {
      if (steps >= milestone) {
        // Award milestone achievement
        _awardStepMilestone(milestone);
      }
    }
  }

  // Award step milestone
  void _awardStepMilestone(int milestone) {
    if (_currentProfile == null) return;

    final today = DateTime.now();
    var todayActivity = _currentProfile!.getTodayActivity();
    
    if (todayActivity == null) {
      todayActivity = DailyActivity(date: today);
      _currentProfile!.dailyActivities.add(todayActivity);
    }

    final achievementKey = 'steps_$milestone';
    if (!todayActivity.achievements.containsKey(achievementKey)) {
      final updatedAchievements = Map<String, int>.from(todayActivity.achievements);
      updatedAchievements[achievementKey] = milestone;
      
      final updatedActivity = todayActivity.copyWith(achievements: updatedAchievements);
      
      final index = _currentProfile!.dailyActivities.indexWhere(
        (activity) => _isSameDay(activity.date, today),
      );
      
      if (index != -1) {
        _currentProfile!.dailyActivities[index] = updatedActivity;
      }

      // Award stat boost
      final boost = StatBoost(
        name: 'Step Milestone',
        description: 'Achieved $milestone steps',
        statType: 'vitality',
        bonusValue: milestone ~/ 1000,
        sourceActivity: ActivityType.walking,
      );

      _currentProfile!.activeBoosts.add(boost);
      
      print('Step milestone achieved: $milestone steps!');
    }
  }

  // Get daily activity summary
  DailyActivity? getTodayActivity() {
    if (_currentProfile == null) return null;
    return _currentProfile!.getTodayActivity();
  }

  // Get activity history
  List<DailyActivity> getActivityHistory(int days) {
    if (_currentProfile == null) return [];
    
    final now = DateTime.now();
    return _currentProfile!.dailyActivities.where((activity) {
      final daysDiff = now.difference(activity.date).inDays;
      return daysDiff <= days;
    }).toList();
  }

  // Get fitness goals
  List<FitnessGoal> getFitnessGoals() {
    if (_currentProfile == null) return [];
    return _currentProfile!.goals;
  }

  // Simulate activity data for testing
  Future<void> simulateActivity() async {
    if (_currentProfile == null) return;

    final today = DateTime.now();
    var todayActivity = _currentProfile!.getTodayActivity();
    
    if (todayActivity == null) {
      todayActivity = DailyActivity(date: today);
      _currentProfile!.dailyActivities.add(todayActivity);
    }

    // Simulate step data
    final randomSteps = _random.nextInt(5000) + 3000;
    final randomDistance = randomSteps * 0.8; // ~0.8 meters per step
    final randomCalories = randomSteps * 0.04; // ~0.04 calories per step

    final simulatedActivity = todayActivity.copyWith(
      totalSteps: randomSteps,
      totalDistance: randomDistance,
      totalCalories: randomCalories.round(),
      activeMinutes: _random.nextInt(60) + 30,
    );

    final index = _currentProfile!.dailyActivities.indexWhere(
      (activity) => _isSameDay(activity.date, today),
    );
    
    if (index != -1) {
      _currentProfile!.dailyActivities[index] = simulatedActivity;
    }

    await _saveFitnessProfile(_currentProfile!);
  }

  // Helper methods
  HealthWorkoutActivityType _mapActivityTypeToHealth(ActivityType type) {
    switch (type) {
      case ActivityType.running:
        return HealthWorkoutActivityType.RUNNING;
      case ActivityType.walking:
        return HealthWorkoutActivityType.WALKING;
      case ActivityType.cycling:
        return HealthWorkoutActivityType.BIKING;
      case ActivityType.swimming:
        return HealthWorkoutActivityType.SWIMMING;
      case ActivityType.yoga:
        return HealthWorkoutActivityType.YOGA;
      case ActivityType.weightlifting:
        return HealthWorkoutActivityType.STRENGTH_TRAINING;
      default:
        return HealthWorkoutActivityType.OTHER;
    }
  }

  List<HealthMetrics> _processHealthDataToMetrics(List<HealthDataPoint> healthData) {
    final metrics = <HealthMetrics>[];
    
    for (final point in healthData) {
      final value = point.value;
      final numericValue = value is HealthValue ? 
        (value.numericValue ?? 0.0) : 
        (value as num).toDouble();
        
      final metric = HealthMetrics(
        steps: point.type == HealthDataType.STEPS ? numericValue.toInt() : 0,
        distanceMeters: point.type == HealthDataType.DISTANCE_WALKING_RUNNING ? numericValue : 0,
        heartRate: point.type == HealthDataType.HEART_RATE ? numericValue.toInt() : 0,
        caloriesBurned: point.type == HealthDataType.ACTIVE_ENERGY_BURNED ? numericValue.toInt() : 0,
        elevationGain: 0, // Would need additional data source
        timestamp: point.dateFrom,
      );
      
      metrics.add(metric);
    }
    
    return metrics;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Data persistence
  Future<FitnessProfile?> _loadFitnessProfile(String playerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('fitness_profile_$playerId');
      
      if (profileJson != null) {
        final profileData = jsonDecode(profileJson);
        return FitnessProfile.fromJson(profileData);
      }
      
      return null;
    } catch (e) {
      print('Error loading fitness profile: $e');
      return null;
    }
  }

  Future<void> _saveFitnessProfile(FitnessProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = jsonEncode(profile.toJson());
      await prefs.setString('fitness_profile_${profile.playerId}', profileJson);
    } catch (e) {
      print('Error saving fitness profile: $e');
    }
  }

  // Cleanup
  void dispose() {
    _stepCountSubscription?.cancel();
    _pedestrianStatusSubscription?.cancel();
  }
}

// Sample fitness goals for different activities
class FitnessGoalTemplates {
  static List<FitnessGoal> getDefaultGoals() {
    final now = DateTime.now();
    final endOfWeek = now.add(const Duration(days: 7));
    final endOfMonth = DateTime(now.year, now.month + 1, now.day);

    return [
      FitnessGoal(
        name: 'Daily Steps',
        description: 'Walk 10,000 steps every day',
        type: ActivityType.walking,
        targetValue: 10000,
        unit: 'steps',
        startDate: now,
        endDate: endOfWeek,
        rewards: {'experience': 100, 'gold': 50},
      ),
      FitnessGoal(
        name: 'Weekly Runner',
        description: 'Run 3 times this week',
        type: ActivityType.running,
        targetValue: 3,
        unit: 'sessions',
        startDate: now,
        endDate: endOfWeek,
        rewards: {'experience': 200, 'gold': 100},
      ),
      FitnessGoal(
        name: 'Monthly Warrior',
        description: 'Complete 20 workouts this month',
        type: ActivityType.other,
        targetValue: 20,
        unit: 'workouts',
        startDate: now,
        endDate: endOfMonth,
        rewards: {'experience': 500, 'gold': 250},
      ),
      FitnessGoal(
        name: 'Strength Builder',
        description: 'Do strength training 3 times per week',
        type: ActivityType.weightlifting,
        targetValue: 3,
        unit: 'sessions',
        startDate: now,
        endDate: endOfWeek,
        rewards: {'experience': 300, 'gold': 150},
      ),
    ];
  }
}