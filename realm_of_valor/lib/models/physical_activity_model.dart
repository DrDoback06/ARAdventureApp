import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'physical_activity_model.g.dart';

enum ActivityType {
  walking,
  running,
  cycling,
  swimming,
  climbing,
  pushUps,
  squats,
  planks,
  jumping,
  yoga,
  weightlifting,
  cardio,
  other,
}

enum ActivityIntensity {
  low,
  moderate,
  high,
  extreme,
}

@JsonSerializable()
class HealthMetrics {
  final int steps;
  final double distanceMeters;
  final int heartRate;
  final int caloriesBurned;
  final double elevationGain;
  final DateTime timestamp;

  HealthMetrics({
    required this.steps,
    required this.distanceMeters,
    required this.heartRate,
    required this.caloriesBurned,
    required this.elevationGain,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory HealthMetrics.fromJson(Map<String, dynamic> json) =>
      _$HealthMetricsFromJson(json);
  Map<String, dynamic> toJson() => _$HealthMetricsToJson(this);
}

@JsonSerializable()
class WorkoutSession {
  final String id;
  final String name;
  final ActivityType type;
  final ActivityIntensity intensity;
  final DateTime startTime;
  final DateTime? endTime;
  final int duration; // in seconds
  final List<HealthMetrics> metrics;
  final Map<String, dynamic> exercises;
  final bool isCompleted;

  WorkoutSession({
    String? id,
    required this.name,
    required this.type,
    required this.intensity,
    DateTime? startTime,
    this.endTime,
    this.duration = 0,
    List<HealthMetrics>? metrics,
    Map<String, dynamic>? exercises,
    this.isCompleted = false,
  })  : id = id ?? const Uuid().v4(),
        startTime = startTime ?? DateTime.now(),
        metrics = metrics ?? <HealthMetrics>[],
        exercises = exercises ?? <String, dynamic>{};

  factory WorkoutSession.fromJson(Map<String, dynamic> json) =>
      _$WorkoutSessionFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutSessionToJson(this);

  WorkoutSession copyWith({
    String? id,
    String? name,
    ActivityType? type,
    ActivityIntensity? intensity,
    DateTime? startTime,
    DateTime? endTime,
    int? duration,
    List<HealthMetrics>? metrics,
    Map<String, dynamic>? exercises,
    bool? isCompleted,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      intensity: intensity ?? this.intensity,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      metrics: metrics ?? this.metrics,
      exercises: exercises ?? this.exercises,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

@JsonSerializable()
class DailyActivity {
  final String id;
  final DateTime date;
  final int totalSteps;
  final double totalDistance;
  final int totalCalories;
  final double totalElevation;
  final int activeMinutes;
  final List<WorkoutSession> workouts;
  final Map<String, int> achievements;

  DailyActivity({
    String? id,
    required this.date,
    this.totalSteps = 0,
    this.totalDistance = 0.0,
    this.totalCalories = 0,
    this.totalElevation = 0.0,
    this.activeMinutes = 0,
    List<WorkoutSession>? workouts,
    Map<String, int>? achievements,
  })  : id = id ?? const Uuid().v4(),
        workouts = workouts ?? <WorkoutSession>[],
        achievements = achievements ?? <String, int>{};

  factory DailyActivity.fromJson(Map<String, dynamic> json) =>
      _$DailyActivityFromJson(json);
  Map<String, dynamic> toJson() => _$DailyActivityToJson(this);

  DailyActivity copyWith({
    String? id,
    DateTime? date,
    int? totalSteps,
    double? totalDistance,
    int? totalCalories,
    double? totalElevation,
    int? activeMinutes,
    List<WorkoutSession>? workouts,
    Map<String, int>? achievements,
  }) {
    return DailyActivity(
      id: id ?? this.id,
      date: date ?? this.date,
      totalSteps: totalSteps ?? this.totalSteps,
      totalDistance: totalDistance ?? this.totalDistance,
      totalCalories: totalCalories ?? this.totalCalories,
      totalElevation: totalElevation ?? this.totalElevation,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      workouts: workouts ?? this.workouts,
      achievements: achievements ?? this.achievements,
    );
  }
}

@JsonSerializable()
class FitnessGoal {
  final String id;
  final String name;
  final String description;
  final ActivityType type;
  final int targetValue;
  final int currentValue;
  final String unit;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCompleted;
  final Map<String, int> rewards;

  FitnessGoal({
    String? id,
    required this.name,
    required this.description,
    required this.type,
    required this.targetValue,
    this.currentValue = 0,
    required this.unit,
    required this.startDate,
    required this.endDate,
    this.isCompleted = false,
    Map<String, int>? rewards,
  })  : id = id ?? const Uuid().v4(),
        rewards = rewards ?? <String, int>{};

  factory FitnessGoal.fromJson(Map<String, dynamic> json) =>
      _$FitnessGoalFromJson(json);
  Map<String, dynamic> toJson() => _$FitnessGoalToJson(this);

  double get progress => targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;
}

@JsonSerializable()
class StatBoost {
  final String id;
  final String name;
  final String description;
  final String statType;
  final int bonusValue;
  final DateTime earnedAt;
  final DateTime expiresAt;
  final bool isActive;
  final ActivityType sourceActivity;

  StatBoost({
    String? id,
    required this.name,
    required this.description,
    required this.statType,
    required this.bonusValue,
    DateTime? earnedAt,
    DateTime? expiresAt,
    this.isActive = true,
    required this.sourceActivity,
  })  : id = id ?? const Uuid().v4(),
        earnedAt = earnedAt ?? DateTime.now(),
        expiresAt = expiresAt ?? DateTime.now().add(const Duration(hours: 24));

  factory StatBoost.fromJson(Map<String, dynamic> json) =>
      _$StatBoostFromJson(json);
  Map<String, dynamic> toJson() => _$StatBoostToJson(this);

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  // Predefined stat boosts based on activities
  static List<StatBoost> getActivityBoosts(ActivityType activity, int intensity) {
    switch (activity) {
      case ActivityType.running:
        return [
          StatBoost(
            name: 'Runner\'s High',
            description: 'Increased stamina from running',
            statType: 'vitality',
            bonusValue: 5 + intensity,
            sourceActivity: activity,
          ),
          StatBoost(
            name: 'Swift Feet',
            description: 'Enhanced agility from cardio',
            statType: 'dexterity',
            bonusValue: 3 + intensity,
            sourceActivity: activity,
          ),
        ];
      case ActivityType.weightlifting:
        return [
          StatBoost(
            name: 'Iron Will',
            description: 'Increased strength from lifting',
            statType: 'strength',
            bonusValue: 8 + intensity,
            sourceActivity: activity,
          ),
        ];
      case ActivityType.yoga:
        return [
          StatBoost(
            name: 'Inner Peace',
            description: 'Mental clarity from yoga',
            statType: 'energy',
            bonusValue: 4 + intensity,
            sourceActivity: activity,
          ),
          StatBoost(
            name: 'Flexibility',
            description: 'Enhanced dexterity from yoga',
            statType: 'dexterity',
            bonusValue: 3 + intensity,
            sourceActivity: activity,
          ),
        ];
      case ActivityType.climbing:
        return [
          StatBoost(
            name: 'Rock Solid',
            description: 'Increased strength from climbing',
            statType: 'strength',
            bonusValue: 6 + intensity,
            sourceActivity: activity,
          ),
          StatBoost(
            name: 'Sure Footed',
            description: 'Enhanced balance and agility',
            statType: 'dexterity',
            bonusValue: 4 + intensity,
            sourceActivity: activity,
          ),
        ];
      case ActivityType.swimming:
        return [
          StatBoost(
            name: 'Aquatic Endurance',
            description: 'Full body conditioning',
            statType: 'vitality',
            bonusValue: 6 + intensity,
            sourceActivity: activity,
          ),
          StatBoost(
            name: 'Fluid Motion',
            description: 'Enhanced coordination',
            statType: 'dexterity',
            bonusValue: 4 + intensity,
            sourceActivity: activity,
          ),
        ];
      default:
        return [
          StatBoost(
            name: 'Active Body',
            description: 'General fitness boost',
            statType: 'vitality',
            bonusValue: 2 + intensity,
            sourceActivity: activity,
          ),
        ];
    }
  }
}

@JsonSerializable()
class FitnessProfile {
  final String id;
  final String playerId;
  final List<DailyActivity> dailyActivities;
  final List<FitnessGoal> goals;
  final List<StatBoost> activeBoosts;
  final Map<String, int> personalRecords;
  final DateTime lastSyncTime;

  FitnessProfile({
    String? id,
    required this.playerId,
    List<DailyActivity>? dailyActivities,
    List<FitnessGoal>? goals,
    List<StatBoost>? activeBoosts,
    Map<String, int>? personalRecords,
    DateTime? lastSyncTime,
  })  : id = id ?? const Uuid().v4(),
        dailyActivities = dailyActivities ?? <DailyActivity>[],
        goals = goals ?? <FitnessGoal>[],
        activeBoosts = activeBoosts ?? <StatBoost>[],
        personalRecords = personalRecords ?? <String, int>{},
        lastSyncTime = lastSyncTime ?? DateTime.now();

  factory FitnessProfile.fromJson(Map<String, dynamic> json) =>
      _$FitnessProfileFromJson(json);
  Map<String, dynamic> toJson() => _$FitnessProfileToJson(this);

  DailyActivity? getTodayActivity() {
    final today = DateTime.now();
    return dailyActivities.firstWhere(
      (activity) => _isSameDay(activity.date, today),
      orElse: () => DailyActivity(date: today),
    );
  }

  List<StatBoost> getActiveBoosts() {
    return activeBoosts.where((boost) => boost.isActive && !boost.isExpired).toList();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}