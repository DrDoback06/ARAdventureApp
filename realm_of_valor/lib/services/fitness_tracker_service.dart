import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/character_provider.dart';
import '../services/achievement_service.dart';
import '../services/character_progression_service.dart';
import '../services/character_service.dart';

enum FitnessActivityType {
  walking,
  running,
  cycling,
  swimming,
  yoga,
  steps,
  weightlifting,
  hiking,
  dancing,
  tennis,
  basketball,
}

enum FitnessTrackerType {
  steps,
  distance,
  calories,
  heartRate,
  workoutDuration,
  flexibility,
  balance,
}

class FitnessActivity {
  final String id;
  final FitnessActivityType type;
  final double value;
  final String unit;
  final DateTime timestamp;
  final String? description;
  final Map<String, dynamic>? metadata;

  const FitnessActivity({
    required this.id,
    required this.type,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.description,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'value': value,
      'unit': unit,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'description': description,
      'metadata': metadata,
    };
  }

  factory FitnessActivity.fromJson(Map<String, dynamic> json) {
    return FitnessActivity(
      id: json['id'],
      type: FitnessActivityType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      value: json['value'].toDouble(),
      unit: json['unit'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      description: json['description'],
      metadata: json['metadata'],
    );
  }
}

class WorkoutSession {
  final String id;
  final FitnessActivityType activityType;
  final DateTime startTime;
  DateTime? endTime;
  Duration duration;
  int caloriesBurned;
  double distance;
  int steps;
  int heartRate;

  WorkoutSession({
    required this.id,
    required this.activityType,
    required this.startTime,
    this.endTime,
    this.duration = Duration.zero,
    this.caloriesBurned = 0,
    this.distance = 0.0,
    this.steps = 0,
    this.heartRate = 0,
  });

  WorkoutSession copyWith({
    DateTime? endTime,
    Duration? duration,
    int? caloriesBurned,
    double? distance,
    int? steps,
    int? heartRate,
  }) {
    return WorkoutSession(
      id: id,
      activityType: activityType,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      distance: distance ?? this.distance,
      steps: steps ?? this.steps,
      heartRate: heartRate ?? this.heartRate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activityType': activityType.name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration.inMilliseconds,
      'caloriesBurned': caloriesBurned,
      'distance': distance,
      'steps': steps,
      'heartRate': heartRate,
    };
  }

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'] as String,
      activityType: FitnessActivityType.values.firstWhere(
        (e) => e.name == json['activityType'],
      ),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
      duration: Duration(milliseconds: json['duration'] as int),
      caloriesBurned: json['caloriesBurned'] as int,
      distance: json['distance'] as double,
      steps: json['steps'] as int,
      heartRate: json['heartRate'] as int,
    );
  }
}

class FitnessTrackerService extends ChangeNotifier {
  static FitnessTrackerService? _instance;
  static FitnessTrackerService get instance => _instance ??= FitnessTrackerService._();
  FitnessTrackerService._();

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // Fitness tracking state
  FitnessTrackerType _currentTracker = FitnessTrackerType.steps;
  bool _isTracking = false;
  List<FitnessActivity> _activities = [];
  Map<FitnessActivityType, double> _dailyTotals = {};
  Map<FitnessActivityType, double> _weeklyTotals = {};
  Map<FitnessActivityType, double> _monthlyTotals = {};

  // Workout session tracking
  WorkoutSession? _currentSession;
  List<WorkoutSession> _workoutSessions = [];

  // Character progression integration
  CharacterProgressionService? _characterProgression;
  CharacterService? _characterService;

  // Getters
  FitnessTrackerType get currentTracker => _currentTracker;
  bool get isTracking => _isTracking;
  List<FitnessActivity> get activities => List.unmodifiable(_activities);
  Map<FitnessActivityType, double> get dailyTotals => Map.unmodifiable(_dailyTotals);
  Map<FitnessActivityType, double> get weeklyTotals => Map.unmodifiable(_weeklyTotals);
  Map<FitnessActivityType, double> get monthlyTotals => Map.unmodifiable(_monthlyTotals);

  // Initialize service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    await _loadFitnessData();
    _isInitialized = true;
    notifyListeners();
  }

  // Set character services for integration
  void setCharacterServices(CharacterProgressionService progression, CharacterService? character) {
    _characterProgression = progression;
    _characterService = character;
  }

  // Load fitness data from preferences
  Future<void> _loadFitnessData() async {
    final trackerIndex = _prefs.getInt('fitness_tracker_type') ?? 0;
    _currentTracker = FitnessTrackerType.values[trackerIndex];
    _isTracking = _prefs.getBool('fitness_is_tracking') ?? false;

    // Load activities
    final activitiesJson = _prefs.getStringList('fitness_activities') ?? [];
    _activities = activitiesJson
        .map((json) => FitnessActivity.fromJson(Map<String, dynamic>.from(json as Map)))
        .toList();

    // Load workout sessions
    final workoutSessionsJson = _prefs.getStringList('fitness_workout_sessions') ?? [];
    _workoutSessions = workoutSessionsJson
        .map((json) => WorkoutSession.fromJson(Map<String, dynamic>.from(json as Map)))
        .toList();

    // Calculate totals
    _calculateTotals();
  }

  // Save fitness data to preferences
  Future<void> _saveFitnessData() async {
    await _prefs.setInt('fitness_tracker_type', _currentTracker.index);
    await _prefs.setBool('fitness_is_tracking', _isTracking);

    // Save activities
    final activitiesJson = _activities
        .map((activity) => activity.toJson())
        .map((json) => json.toString())
        .toList();
    await _prefs.setStringList('fitness_activities', activitiesJson);

    // Save workout sessions
    final workoutSessionsJson = _workoutSessions
        .map((session) => session.toJson())
        .map((json) => json.toString())
        .toList();
    await _prefs.setStringList('fitness_workout_sessions', workoutSessionsJson);
  }

  // Start fitness tracking
  Future<void> startTracking(FitnessTrackerType trackerType) async {
    _currentTracker = trackerType;
    _isTracking = true;
    await _saveFitnessData();
    notifyListeners();
  }

  // Stop fitness tracking
  Future<void> stopTracking() async {
    _isTracking = false;
    await _saveFitnessData();
    notifyListeners();
  }

  // Add fitness activity
  Future<void> addActivity(FitnessActivity activity) async {
    // Ensure service is initialized
    if (!_isInitialized) {
      await initialize();
    }
    
    _activities.add(activity);
    
    // Keep only last 1000 activities
    if (_activities.length > 1000) {
      _activities.removeRange(0, _activities.length - 1000);
    }

    _calculateTotals();
    await _saveFitnessData();
    
    // Award XP based on activity
    await _awardFitnessXP(activity);
    
    notifyListeners();
  }

  // Add manual activity
  Future<void> addManualActivity(
    FitnessActivityType type,
    double value,
    String unit,
    String? description,
  ) async {
    final activity = FitnessActivity(
      id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      value: value,
      unit: unit,
      timestamp: DateTime.now(),
      description: description,
      metadata: {
        'source': 'manual',
        'tracker': _currentTracker.name,
      },
    );

    await addActivity(activity);
  }

  // Add distance traveled for quest completion
  Future<void> addQuestDistance(double distanceMeters, String questName) async {
    // Ensure service is initialized
    if (!_isInitialized) {
      await initialize();
    }
    
    final activity = FitnessActivity(
      id: 'quest_${DateTime.now().millisecondsSinceEpoch}',
      type: FitnessActivityType.walking,
      value: distanceMeters,
      unit: 'meters',
      timestamp: DateTime.now(),
      description: 'Quest completion: $questName',
      metadata: {
        'source': 'quest',
        'quest_name': questName,
        'tracker': _currentTracker.name,
      },
    );

    await addActivity(activity);
  }

  // Start a workout session
  void startWorkoutSession(FitnessActivityType activityType) {
    final session = WorkoutSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      activityType: activityType,
      startTime: DateTime.now(),
      duration: Duration.zero,
      caloriesBurned: 0,
      distance: 0.0,
      steps: 0,
      heartRate: 0,
    );
    
    _currentSession = session;
    _workoutSessions.add(session);
    notifyListeners();
    
    if (kDebugMode) {
      print('[FitnessTrackerService] Started workout: ${activityType.name}');
    }
  }

  // End the current workout session
  void endWorkoutSession() {
    if (_currentSession != null) {
      final endTime = DateTime.now();
      final duration = endTime.difference(_currentSession!.startTime);
      
      _currentSession = _currentSession!.copyWith(
        endTime: endTime,
        duration: duration,
        caloriesBurned: _calculateCaloriesBurned(_currentSession!.activityType, duration),
        distance: _calculateDistance(_currentSession!.activityType, duration),
        steps: _calculateSteps(_currentSession!.activityType, duration),
        heartRate: _calculateHeartRate(_currentSession!.activityType, duration),
      );
      
      // Apply stat boosts based on workout
      _applyWorkoutRewards(_currentSession!);
      
      _currentSession = null;
      notifyListeners();
      
      if (kDebugMode) {
        print('[FitnessTrackerService] Ended workout session');
      }
    }
  }

  // Update current session with real-time data
  void updateSessionProgress({
    int? steps,
    double? distance,
    int? heartRate,
    int? calories,
  }) {
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        steps: steps ?? _currentSession!.steps,
        distance: distance ?? _currentSession!.distance,
        heartRate: heartRate ?? _currentSession!.heartRate,
        caloriesBurned: calories ?? _currentSession!.caloriesBurned,
      );
      notifyListeners();
    }
  }

  // Calculate calories burned based on activity type and duration
  int _calculateCaloriesBurned(FitnessActivityType activityType, Duration duration) {
    final minutes = duration.inMinutes;
    final caloriesPerMinute = _getCaloriesPerMinute(activityType);
    return (minutes * caloriesPerMinute).round();
  }

  // Calculate distance based on activity type and duration
  double _calculateDistance(FitnessActivityType activityType, Duration duration) {
    final minutes = duration.inMinutes;
    final speedKmh = _getSpeedKmh(activityType);
    return (minutes * speedKmh / 60.0);
  }

  // Calculate steps based on activity type and duration
  int _calculateSteps(FitnessActivityType activityType, Duration duration) {
    final minutes = duration.inMinutes;
    final stepsPerMinute = _getStepsPerMinute(activityType);
    return (minutes * stepsPerMinute).round();
  }

  // Calculate heart rate based on activity intensity
  int _calculateHeartRate(FitnessActivityType activityType, Duration duration) {
    final baseHeartRate = 70;
    final intensityMultiplier = _getIntensityMultiplier(activityType);
    final timeMultiplier = (duration.inMinutes / 30.0).clamp(0.0, 2.0);
    
    return (baseHeartRate + (intensityMultiplier * timeMultiplier)).round();
  }

  // Get calories burned per minute for activity type
  double _getCaloriesPerMinute(FitnessActivityType activityType) {
    switch (activityType) {
      case FitnessActivityType.steps:
        return 2.0;
      case FitnessActivityType.walking:
        return 4.0;
      case FitnessActivityType.running:
        return 10.0;
      case FitnessActivityType.cycling:
        return 8.0;
      case FitnessActivityType.swimming:
        return 9.0;
      case FitnessActivityType.weightlifting:
        return 6.0;
      case FitnessActivityType.yoga:
        return 3.0;
      case FitnessActivityType.hiking:
        return 7.0;
      case FitnessActivityType.dancing:
        return 5.0;
      case FitnessActivityType.tennis:
        return 8.5;
      case FitnessActivityType.basketball:
        return 9.5;
    }
  }

  // Get speed in km/h for activity type
  double _getSpeedKmh(FitnessActivityType activityType) {
    switch (activityType) {
      case FitnessActivityType.steps:
        return 0.0;
      case FitnessActivityType.walking:
        return 5.0;
      case FitnessActivityType.running:
        return 10.0;
      case FitnessActivityType.cycling:
        return 20.0;
      case FitnessActivityType.swimming:
        return 2.0;
      case FitnessActivityType.weightlifting:
        return 0.0;
      case FitnessActivityType.yoga:
        return 0.0;
      case FitnessActivityType.hiking:
        return 4.0;
      case FitnessActivityType.dancing:
        return 0.0;
      case FitnessActivityType.tennis:
        return 0.0;
      case FitnessActivityType.basketball:
        return 0.0;
    }
  }

  // Get steps per minute for activity type
  double _getStepsPerMinute(FitnessActivityType activityType) {
    switch (activityType) {
      case FitnessActivityType.steps:
        return 100.0;
      case FitnessActivityType.walking:
        return 100.0;
      case FitnessActivityType.running:
        return 150.0;
      case FitnessActivityType.cycling:
        return 0.0;
      case FitnessActivityType.swimming:
        return 0.0;
      case FitnessActivityType.weightlifting:
        return 20.0;
      case FitnessActivityType.yoga:
        return 10.0;
      case FitnessActivityType.hiking:
        return 80.0;
      case FitnessActivityType.dancing:
        return 120.0;
      case FitnessActivityType.tennis:
        return 80.0;
      case FitnessActivityType.basketball:
        return 100.0;
    }
  }

  // Get intensity multiplier for heart rate calculation
  double _getIntensityMultiplier(FitnessActivityType activityType) {
    switch (activityType) {
      case FitnessActivityType.steps:
        return 15.0;
      case FitnessActivityType.walking:
        return 20.0;
      case FitnessActivityType.running:
        return 50.0;
      case FitnessActivityType.cycling:
        return 40.0;
      case FitnessActivityType.swimming:
        return 35.0;
      case FitnessActivityType.weightlifting:
        return 30.0;
      case FitnessActivityType.yoga:
        return 10.0;
      case FitnessActivityType.hiking:
        return 25.0;
      case FitnessActivityType.dancing:
        return 35.0;
      case FitnessActivityType.tennis:
        return 45.0;
      case FitnessActivityType.basketball:
        return 50.0;
    }
  }

  // Apply workout rewards to character stats
  void _applyWorkoutRewards(WorkoutSession session) {
    final characterProvider = _getCharacterProvider();
    if (characterProvider == null) return;

    final character = characterProvider.currentCharacter;
    if (character == null) return;

    // Calculate stat boosts based on workout
    final statBoosts = _calculateStatBoosts(session);
    
    // Apply the boosts by adding experience (simulating stat boosts)
    final experienceGained = _calculateWorkoutExperience(session);
    characterProvider.addExperience(experienceGained, source: 'Workout: ${session.activityType.name}');
    
    // Check for achievements
    _checkWorkoutAchievements(session);
    
    if (kDebugMode) {
      print('[FitnessTrackerService] Applied workout rewards: $statBoosts');
    }
  }

  // Calculate stat boosts based on workout session
  Map<String, int> _calculateStatBoosts(WorkoutSession session) {
    final boosts = <String, int>{};
    
    switch (session.activityType) {
      case FitnessActivityType.steps:
        boosts['vitality'] = (session.duration.inMinutes / 15).round();
        boosts['energy'] = (session.duration.inMinutes / 20).round();
        break;
      case FitnessActivityType.walking:
      case FitnessActivityType.running:
      case FitnessActivityType.hiking:
        boosts['strength'] = (session.duration.inMinutes / 10).round();
        boosts['vitality'] = (session.duration.inMinutes / 8).round();
        break;
      case FitnessActivityType.cycling:
        boosts['dexterity'] = (session.duration.inMinutes / 10).round();
        boosts['vitality'] = (session.duration.inMinutes / 12).round();
        break;
      case FitnessActivityType.swimming:
        boosts['strength'] = (session.duration.inMinutes / 12).round();
        boosts['dexterity'] = (session.duration.inMinutes / 15).round();
        boosts['vitality'] = (session.duration.inMinutes / 10).round();
        break;
      case FitnessActivityType.weightlifting:
        boosts['strength'] = (session.duration.inMinutes / 5).round();
        boosts['vitality'] = (session.duration.inMinutes / 8).round();
        break;
      case FitnessActivityType.yoga:
        boosts['energy'] = (session.duration.inMinutes / 10).round();
        boosts['dexterity'] = (session.duration.inMinutes / 15).round();
        break;
      case FitnessActivityType.dancing:
        boosts['dexterity'] = (session.duration.inMinutes / 8).round();
        boosts['energy'] = (session.duration.inMinutes / 12).round();
        break;
      case FitnessActivityType.tennis:
      case FitnessActivityType.basketball:
        boosts['strength'] = (session.duration.inMinutes / 12).round();
        boosts['dexterity'] = (session.duration.inMinutes / 10).round();
        boosts['vitality'] = (session.duration.inMinutes / 15).round();
        break;
    }
    
    return boosts;
  }

  // Calculate experience gained from workout
  int _calculateWorkoutExperience(WorkoutSession session) {
    final baseExperience = session.duration.inMinutes * 2;
    final intensityBonus = _getIntensityMultiplier(session.activityType) / 10;
    return (baseExperience * (1 + intensityBonus)).round();
  }

  // Check for workout-related achievements
  void _checkWorkoutAchievements(WorkoutSession session) {
    final achievementService = _getAchievementService();
    if (achievementService == null) return;

    // Check for workout duration achievements
    if (session.duration.inMinutes >= 30) {
      // achievementService.unlockAchievement('workout_30_min');
      if (kDebugMode) {
        print('[FitnessTrackerService] Achievement unlocked: workout_30_min');
      }
    }
    if (session.duration.inMinutes >= 60) {
      // achievementService.unlockAchievement('workout_1_hour');
      if (kDebugMode) {
        print('[FitnessTrackerService] Achievement unlocked: workout_1_hour');
      }
    }
    if (session.duration.inMinutes >= 120) {
      // achievementService.unlockAchievement('workout_2_hours');
      if (kDebugMode) {
        print('[FitnessTrackerService] Achievement unlocked: workout_2_hours');
      }
    }

    // Check for activity-specific achievements
    switch (session.activityType) {
      case FitnessActivityType.running:
        if (session.distance >= 5.0) {
          // achievementService.unlockAchievement('run_5km');
          if (kDebugMode) {
            print('[FitnessTrackerService] Achievement unlocked: run_5km');
          }
        }
        if (session.distance >= 10.0) {
          // achievementService.unlockAchievement('run_10km');
          if (kDebugMode) {
            print('[FitnessTrackerService] Achievement unlocked: run_10km');
          }
        }
        break;
      case FitnessActivityType.cycling:
        if (session.distance >= 20.0) {
          // achievementService.unlockAchievement('cycle_20km');
          if (kDebugMode) {
            print('[FitnessTrackerService] Achievement unlocked: cycle_20km');
          }
        }
        break;
      case FitnessActivityType.swimming:
        if (session.duration.inMinutes >= 30) {
          // achievementService.unlockAchievement('swim_30_min');
          if (kDebugMode) {
            print('[FitnessTrackerService] Achievement unlocked: swim_30_min');
          }
        }
        break;
      default:
        break;
    }
  }

  // Get character provider from context
  CharacterProvider? _getCharacterProvider() {
    // This would need to be implemented with proper context access
    // For now, we'll return null and handle it gracefully
    return null;
  }

  // Get achievement service from context
  AchievementService? _getAchievementService() {
    // This would need to be implemented with proper context access
    // For now, we'll return null and handle it gracefully
    return null;
  }

  // Calculate totals
  void _calculateTotals() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    _dailyTotals.clear();
    _weeklyTotals.clear();
    _monthlyTotals.clear();

    for (final activity in _activities) {
      final activityDate = DateTime(
        activity.timestamp.year,
        activity.timestamp.month,
        activity.timestamp.day,
      );

      // Daily totals
      if (activityDate.isAtSameMomentAs(today)) {
        _dailyTotals[activity.type] = (_dailyTotals[activity.type] ?? 0) + activity.value;
      }

      // Weekly totals
      if (activityDate.isAfter(weekStart.subtract(const Duration(days: 1)))) {
        _weeklyTotals[activity.type] = (_weeklyTotals[activity.type] ?? 0) + activity.value;
      }

      // Monthly totals
      if (activityDate.isAfter(monthStart.subtract(const Duration(days: 1)))) {
        _monthlyTotals[activity.type] = (_monthlyTotals[activity.type] ?? 0) + activity.value;
      }
    }
  }

  // Award XP based on fitness activity
  Future<void> _awardFitnessXP(FitnessActivity activity) async {
    if (_characterProgression == null) return;

    int xpAmount = 0;
    String source = '';

    switch (activity.type) {
      case FitnessActivityType.steps:
        xpAmount = (activity.value / 1000).round(); // 1 XP per 1000 steps
        source = 'Steps';
        break;
      case FitnessActivityType.walking:
        xpAmount = (activity.value * 2).round(); // 2 XP per minute
        source = 'Walking';
        break;
      case FitnessActivityType.running:
        xpAmount = (activity.value * 5).round(); // 5 XP per minute
        source = 'Running';
        break;
      case FitnessActivityType.cycling:
        xpAmount = (activity.value * 3).round(); // 3 XP per minute
        source = 'Cycling';
        break;
      case FitnessActivityType.swimming:
        xpAmount = (activity.value * 8).round(); // 8 XP per minute
        source = 'Swimming';
        break;
      case FitnessActivityType.yoga:
        xpAmount = (activity.value * 2).round(); // 2 XP per minute
        source = 'Yoga';
        break;
      case FitnessActivityType.weightlifting:
        xpAmount = (activity.value * 3).round(); // 3 XP per minute
        source = 'Weightlifting';
        break;
      case FitnessActivityType.hiking:
        xpAmount = (activity.value * 4).round(); // 4 XP per minute
        source = 'Hiking';
        break;
      case FitnessActivityType.dancing:
        xpAmount = (activity.value * 3).round(); // 3 XP per minute
        source = 'Dancing';
        break;
      case FitnessActivityType.tennis:
        xpAmount = (activity.value * 4).round(); // 4 XP per minute
        source = 'Tennis';
        break;
      case FitnessActivityType.basketball:
        xpAmount = (activity.value * 5).round(); // 5 XP per minute
        source = 'Basketball';
        break;
    }

    if (xpAmount > 0) {
      _characterProgression!.addExperience(xpAmount, source: source);
    }
  }

  // Get fitness statistics
  Map<String, dynamic> getFitnessStatistics() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    final todayActivities = _activities.where(
      (activity) => activity.timestamp.isAfter(today.subtract(const Duration(days: 1))),
    ).toList();

    final weekActivities = _activities.where(
      (activity) => activity.timestamp.isAfter(weekStart.subtract(const Duration(days: 1))),
    ).toList();

    final monthActivities = _activities.where(
      (activity) => activity.timestamp.isAfter(monthStart.subtract(const Duration(days: 1))),
    ).toList();

    return {
      'totalActivities': _activities.length,
      'todayActivities': todayActivities.length,
      'weekActivities': weekActivities.length,
      'monthActivities': monthActivities.length,
      'dailyTotals': _dailyTotals,
      'weeklyTotals': _weeklyTotals,
      'monthlyTotals': _monthlyTotals,
      'currentStreak': _calculateStreak(),
      'longestStreak': _calculateLongestStreak(),
      'favoriteActivity': _getFavoriteActivity(),
      'totalXP': _calculateTotalXP(),
    };
  }

  // Calculate current streak
  int _calculateStreak() {
    if (_activities.isEmpty) return 0;

    final now = DateTime.now();
    int streak = 0;
    DateTime currentDate = DateTime(now.year, now.month, now.day);

    while (true) {
      final hasActivity = _activities.any((activity) {
        final activityDate = DateTime(
          activity.timestamp.year,
          activity.timestamp.month,
          activity.timestamp.day,
        );
        return activityDate.isAtSameMomentAs(currentDate);
      });

      if (hasActivity) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  // Calculate longest streak
  int _calculateLongestStreak() {
    if (_activities.isEmpty) return 0;

    int longestStreak = 0;
    int currentStreak = 0;
    DateTime? lastDate;

    final sortedActivities = List<FitnessActivity>.from(_activities)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (final activity in sortedActivities) {
      final activityDate = DateTime(
        activity.timestamp.year,
        activity.timestamp.month,
        activity.timestamp.day,
      );

      if (lastDate == null) {
        currentStreak = 1;
      } else {
        final daysDifference = activityDate.difference(lastDate).inDays;
        if (daysDifference == 1) {
          currentStreak++;
        } else {
          longestStreak = longestStreak > currentStreak ? longestStreak : currentStreak;
          currentStreak = 1;
        }
      }

      lastDate = activityDate;
    }

    return longestStreak > currentStreak ? longestStreak : currentStreak;
  }

  // Get favorite activity type
  FitnessActivityType? _getFavoriteActivity() {
    if (_activities.isEmpty) return null;

    final activityCounts = <FitnessActivityType, int>{};
    for (final activity in _activities) {
      activityCounts[activity.type] = (activityCounts[activity.type] ?? 0) + 1;
    }

    FitnessActivityType? favorite;
    int maxCount = 0;

    for (final entry in activityCounts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        favorite = entry.key;
      }
    }

    return favorite;
  }

  // Calculate total XP earned from fitness
  int _calculateTotalXP() {
    int totalXP = 0;
    for (final activity in _activities) {
      // Use the same XP calculation logic as _awardFitnessXP
      switch (activity.type) {
        case FitnessActivityType.steps:
          totalXP += (activity.value / 1000).round();
          break;
        case FitnessActivityType.walking:
          totalXP += (activity.value * 2).round();
          break;
        case FitnessActivityType.running:
          totalXP += (activity.value * 5).round();
          break;
        case FitnessActivityType.cycling:
          totalXP += (activity.value * 3).round();
          break;
        case FitnessActivityType.swimming:
          totalXP += (activity.value * 8).round();
          break;
        case FitnessActivityType.yoga:
          totalXP += (activity.value * 2).round();
          break;
        case FitnessActivityType.weightlifting:
          totalXP += (activity.value * 3).round();
          break;
        case FitnessActivityType.hiking:
          totalXP += (activity.value * 4).round();
          break;
        case FitnessActivityType.dancing:
          totalXP += (activity.value * 3).round();
          break;
        case FitnessActivityType.tennis:
          totalXP += (activity.value * 4).round();
          break;
        case FitnessActivityType.basketball:
          totalXP += (activity.value * 5).round();
          break;
      }
    }
    return totalXP;
  }

  // Get activities by date range
  List<FitnessActivity> getActivitiesByDateRange(DateTime start, DateTime end) {
    return _activities.where((activity) {
      return activity.timestamp.isAfter(start.subtract(const Duration(days: 1))) &&
             activity.timestamp.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  // Get activities by type
  List<FitnessActivity> getActivitiesByType(FitnessActivityType type) {
    return _activities.where((activity) => activity.type == type).toList();
  }

  // Clear all activities
  Future<void> clearActivities() async {
    _activities.clear();
    _calculateTotals();
    await _saveFitnessData();
    notifyListeners();
  }

  // Export fitness data
  Map<String, dynamic> exportFitnessData() {
    return {
      'trackerType': _currentTracker.name,
      'isTracking': _isTracking,
      'activities': _activities.map((activity) => activity.toJson()).toList(),
      'statistics': getFitnessStatistics(),
    };
  }

  // Import fitness data
  Future<void> importFitnessData(Map<String, dynamic> data) async {
    if (data.containsKey('trackerType')) {
      _currentTracker = FitnessTrackerType.values.firstWhere(
        (e) => e.name == data['trackerType'],
      );
    }

    if (data.containsKey('isTracking')) {
      _isTracking = data['isTracking'];
    }

    if (data.containsKey('activities')) {
      final activitiesList = data['activities'] as List;
      _activities = activitiesList
          .map((json) => FitnessActivity.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    }

    _calculateTotals();
    await _saveFitnessData();
    notifyListeners();
  }

  String _getActivityIcon(FitnessActivityType activityType) {
    switch (activityType) {
      case FitnessActivityType.walking:
        return '🚶';
      case FitnessActivityType.running:
        return '🏃';
      case FitnessActivityType.cycling:
        return '🚴';
      case FitnessActivityType.swimming:
        return '🏊';
      case FitnessActivityType.yoga:
        return '🧘';
      case FitnessActivityType.steps:
        return '👣';
      case FitnessActivityType.weightlifting:
        return '🏋️';
      case FitnessActivityType.hiking:
        return '🏔️';
      case FitnessActivityType.dancing:
        return '💃';
      case FitnessActivityType.tennis:
        return '🎾';
      case FitnessActivityType.basketball:
        return '🏀';
    }
  }

  String _getActivityName(FitnessActivityType activityType) {
    switch (activityType) {
      case FitnessActivityType.walking:
        return 'Walking';
      case FitnessActivityType.running:
        return 'Running';
      case FitnessActivityType.cycling:
        return 'Cycling';
      case FitnessActivityType.swimming:
        return 'Swimming';
      case FitnessActivityType.yoga:
        return 'Yoga';
      case FitnessActivityType.steps:
        return 'Steps';
      case FitnessActivityType.weightlifting:
        return 'Weightlifting';
      case FitnessActivityType.hiking:
        return 'Hiking';
      case FitnessActivityType.dancing:
        return 'Dancing';
      case FitnessActivityType.tennis:
        return 'Tennis';
      case FitnessActivityType.basketball:
        return 'Basketball';
    }
  }
} 