// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quest_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuestLocation _$QuestLocationFromJson(Map<String, dynamic> json) =>
    QuestLocation(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radius: (json['radius'] as num?)?.toDouble(),
      imageUrl: json['imageUrl'] as String?,
      properties: json['properties'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$QuestLocationToJson(QuestLocation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'radius': instance.radius,
      'imageUrl': instance.imageUrl,
      'properties': instance.properties,
    };

QuestObjective _$QuestObjectiveFromJson(Map<String, dynamic> json) =>
    QuestObjective(
      id: json['id'] as String?,
      description: json['description'] as String,
      type: json['type'] as String,
      targetValue: (json['targetValue'] as num).toInt(),
      currentValue: (json['currentValue'] as num?)?.toInt() ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      properties: json['properties'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$QuestObjectiveToJson(QuestObjective instance) =>
    <String, dynamic>{
      'id': instance.id,
      'description': instance.description,
      'type': instance.type,
      'targetValue': instance.targetValue,
      'currentValue': instance.currentValue,
      'isCompleted': instance.isCompleted,
      'properties': instance.properties,
    };

QuestReward _$QuestRewardFromJson(Map<String, dynamic> json) => QuestReward(
      type: json['type'] as String,
      name: json['name'] as String,
      value: (json['value'] as num).toInt(),
      cardId: json['cardId'] as String?,
      properties: json['properties'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$QuestRewardToJson(QuestReward instance) =>
    <String, dynamic>{
      'type': instance.type,
      'name': instance.name,
      'value': instance.value,
      'cardId': instance.cardId,
      'properties': instance.properties,
    };

Quest _$QuestFromJson(Map<String, dynamic> json) => Quest(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String,
      story: json['story'] as String,
      type: $enumDecode(_$QuestTypeEnumMap, json['type']),
      status: $enumDecodeNullable(_$QuestStatusEnumMap, json['status']) ??
          QuestStatus.available,
      difficulty:
          $enumDecodeNullable(_$QuestDifficultyEnumMap, json['difficulty']) ??
              QuestDifficulty.medium,
      objectives: (json['objectives'] as List<dynamic>?)
          ?.map((e) => QuestObjective.fromJson(e as Map<String, dynamic>))
          .toList(),
      rewards: (json['rewards'] as List<dynamic>?)
          ?.map((e) => QuestReward.fromJson(e as Map<String, dynamic>))
          .toList(),
      location: json['location'] == null
          ? null
          : QuestLocation.fromJson(json['location'] as Map<String, dynamic>),
      waypoints: (json['waypoints'] as List<dynamic>?)
          ?.map((e) => QuestLocation.fromJson(e as Map<String, dynamic>))
          .toList(),
      startTime: json['startTime'] == null
          ? null
          : DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      deadline: json['deadline'] == null
          ? null
          : DateTime.parse(json['deadline'] as String),
      experienceReward: (json['experienceReward'] as num?)?.toInt() ?? 100,
      goldReward: (json['goldReward'] as num?)?.toInt() ?? 50,
      prerequisites: (json['prerequisites'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$QuestToJson(Quest instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'story': instance.story,
      'type': _$QuestTypeEnumMap[instance.type]!,
      'status': _$QuestStatusEnumMap[instance.status]!,
      'difficulty': _$QuestDifficultyEnumMap[instance.difficulty]!,
      'objectives': instance.objectives,
      'rewards': instance.rewards,
      'location': instance.location,
      'waypoints': instance.waypoints,
      'startTime': instance.startTime?.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'deadline': instance.deadline?.toIso8601String(),
      'experienceReward': instance.experienceReward,
      'goldReward': instance.goldReward,
      'prerequisites': instance.prerequisites,
      'metadata': instance.metadata,
    };

const _$QuestTypeEnumMap = {
  QuestType.walking: 'walking',
  QuestType.running: 'running',
  QuestType.climbing: 'climbing',
  QuestType.location: 'location',
  QuestType.exploration: 'exploration',
  QuestType.collection: 'collection',
  QuestType.battle: 'battle',
  QuestType.social: 'social',
  QuestType.fitness: 'fitness',
};

const _$QuestStatusEnumMap = {
  QuestStatus.available: 'available',
  QuestStatus.active: 'active',
  QuestStatus.completed: 'completed',
  QuestStatus.failed: 'failed',
  QuestStatus.locked: 'locked',
};

const _$QuestDifficultyEnumMap = {
  QuestDifficulty.easy: 'easy',
  QuestDifficulty.medium: 'medium',
  QuestDifficulty.hard: 'hard',
  QuestDifficulty.expert: 'expert',
  QuestDifficulty.legendary: 'legendary',
};

QuestProgress _$QuestProgressFromJson(Map<String, dynamic> json) =>
    QuestProgress(
      questId: json['questId'] as String,
      playerId: json['playerId'] as String,
      startTime: json['startTime'] == null
          ? null
          : DateTime.parse(json['startTime'] as String),
      lastUpdateTime: json['lastUpdateTime'] == null
          ? null
          : DateTime.parse(json['lastUpdateTime'] as String),
      progressData: json['progressData'] as Map<String, dynamic>?,
      completedObjectives: (json['completedObjectives'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$QuestProgressToJson(QuestProgress instance) =>
    <String, dynamic>{
      'questId': instance.questId,
      'playerId': instance.playerId,
      'startTime': instance.startTime.toIso8601String(),
      'lastUpdateTime': instance.lastUpdateTime?.toIso8601String(),
      'progressData': instance.progressData,
      'completedObjectives': instance.completedObjectives,
    };
