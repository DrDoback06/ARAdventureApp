// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'physical_activity_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HealthMetrics _$HealthMetricsFromJson(Map<String, dynamic> json) =>
    HealthMetrics(
      steps: (json['steps'] as num).toInt(),
      distanceMeters: (json['distanceMeters'] as num).toDouble(),
      heartRate: (json['heartRate'] as num).toInt(),
      caloriesBurned: (json['caloriesBurned'] as num).toInt(),
      elevationGain: (json['elevationGain'] as num).toDouble(),
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$HealthMetricsToJson(HealthMetrics instance) =>
    <String, dynamic>{
      'steps': instance.steps,
      'distanceMeters': instance.distanceMeters,
      'heartRate': instance.heartRate,
      'caloriesBurned': instance.caloriesBurned,
      'elevationGain': instance.elevationGain,
      'timestamp': instance.timestamp.toIso8601String(),
    };

WorkoutSession _$WorkoutSessionFromJson(Map<String, dynamic> json) =>
    WorkoutSession(
      id: json['id'] as String?,
      name: json['name'] as String,
      type: $enumDecode(_$ActivityTypeEnumMap, json['type']),
      intensity: $enumDecode(_$ActivityIntensityEnumMap, json['intensity']),
      startTime: json['startTime'] == null
          ? null
          : DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      metrics: (json['metrics'] as List<dynamic>?)
          ?.map((e) => HealthMetrics.fromJson(e as Map<String, dynamic>))
          .toList(),
      exercises: json['exercises'] as Map<String, dynamic>?,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );

Map<String, dynamic> _$WorkoutSessionToJson(WorkoutSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$ActivityTypeEnumMap[instance.type]!,
      'intensity': _$ActivityIntensityEnumMap[instance.intensity]!,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'duration': instance.duration,
      'metrics': instance.metrics,
      'exercises': instance.exercises,
      'isCompleted': instance.isCompleted,
    };

const _$ActivityTypeEnumMap = {
  ActivityType.walking: 'walking',
  ActivityType.running: 'running',
  ActivityType.cycling: 'cycling',
  ActivityType.swimming: 'swimming',
  ActivityType.climbing: 'climbing',
  ActivityType.pushUps: 'pushUps',
  ActivityType.squats: 'squats',
  ActivityType.planks: 'planks',
  ActivityType.jumping: 'jumping',
  ActivityType.yoga: 'yoga',
  ActivityType.weightlifting: 'weightlifting',
  ActivityType.cardio: 'cardio',
  ActivityType.other: 'other',
};

const _$ActivityIntensityEnumMap = {
  ActivityIntensity.low: 'low',
  ActivityIntensity.moderate: 'moderate',
  ActivityIntensity.high: 'high',
  ActivityIntensity.extreme: 'extreme',
};

DailyActivity _$DailyActivityFromJson(Map<String, dynamic> json) =>
    DailyActivity(
      id: json['id'] as String?,
      date: DateTime.parse(json['date'] as String),
      totalSteps: (json['totalSteps'] as num?)?.toInt() ?? 0,
      totalDistance: (json['totalDistance'] as num?)?.toDouble() ?? 0.0,
      totalCalories: (json['totalCalories'] as num?)?.toInt() ?? 0,
      totalElevation: (json['totalElevation'] as num?)?.toDouble() ?? 0.0,
      activeMinutes: (json['activeMinutes'] as num?)?.toInt() ?? 0,
      workouts: (json['workouts'] as List<dynamic>?)
          ?.map((e) => WorkoutSession.fromJson(e as Map<String, dynamic>))
          .toList(),
      achievements: (json['achievements'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ),
    );

Map<String, dynamic> _$DailyActivityToJson(DailyActivity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'totalSteps': instance.totalSteps,
      'totalDistance': instance.totalDistance,
      'totalCalories': instance.totalCalories,
      'totalElevation': instance.totalElevation,
      'activeMinutes': instance.activeMinutes,
      'workouts': instance.workouts,
      'achievements': instance.achievements,
    };

FitnessGoal _$FitnessGoalFromJson(Map<String, dynamic> json) => FitnessGoal(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$ActivityTypeEnumMap, json['type']),
      targetValue: (json['targetValue'] as num).toInt(),
      currentValue: (json['currentValue'] as num?)?.toInt() ?? 0,
      unit: json['unit'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
      rewards: (json['rewards'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ),
    );

Map<String, dynamic> _$FitnessGoalToJson(FitnessGoal instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'type': _$ActivityTypeEnumMap[instance.type]!,
      'targetValue': instance.targetValue,
      'currentValue': instance.currentValue,
      'unit': instance.unit,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'isCompleted': instance.isCompleted,
      'rewards': instance.rewards,
    };

StatBoost _$StatBoostFromJson(Map<String, dynamic> json) => StatBoost(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String,
      statType: json['statType'] as String,
      bonusValue: (json['bonusValue'] as num).toInt(),
      earnedAt: json['earnedAt'] == null
          ? null
          : DateTime.parse(json['earnedAt'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      sourceActivity:
          $enumDecode(_$ActivityTypeEnumMap, json['sourceActivity']),
    );

Map<String, dynamic> _$StatBoostToJson(StatBoost instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'statType': instance.statType,
      'bonusValue': instance.bonusValue,
      'earnedAt': instance.earnedAt.toIso8601String(),
      'expiresAt': instance.expiresAt.toIso8601String(),
      'isActive': instance.isActive,
      'sourceActivity': _$ActivityTypeEnumMap[instance.sourceActivity]!,
    };

FitnessProfile _$FitnessProfileFromJson(Map<String, dynamic> json) =>
    FitnessProfile(
      id: json['id'] as String?,
      playerId: json['playerId'] as String,
      dailyActivities: (json['dailyActivities'] as List<dynamic>?)
          ?.map((e) => DailyActivity.fromJson(e as Map<String, dynamic>))
          .toList(),
      goals: (json['goals'] as List<dynamic>?)
          ?.map((e) => FitnessGoal.fromJson(e as Map<String, dynamic>))
          .toList(),
      activeBoosts: (json['activeBoosts'] as List<dynamic>?)
          ?.map((e) => StatBoost.fromJson(e as Map<String, dynamic>))
          .toList(),
      personalRecords: (json['personalRecords'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ),
      lastSyncTime: json['lastSyncTime'] == null
          ? null
          : DateTime.parse(json['lastSyncTime'] as String),
    );

Map<String, dynamic> _$FitnessProfileToJson(FitnessProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'playerId': instance.playerId,
      'dailyActivities': instance.dailyActivities,
      'goals': instance.goals,
      'activeBoosts': instance.activeBoosts,
      'personalRecords': instance.personalRecords,
      'lastSyncTime': instance.lastSyncTime.toIso8601String(),
    };
