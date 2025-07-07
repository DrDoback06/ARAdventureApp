// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'adventure_system.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeoLocation _$GeoLocationFromJson(Map<String, dynamic> json) => GeoLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$GeoLocationToJson(GeoLocation instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'altitude': instance.altitude,
      'accuracy': instance.accuracy,
      'timestamp': instance.timestamp.toIso8601String(),
    };

QuestObjective _$QuestObjectiveFromJson(Map<String, dynamic> json) =>
    QuestObjective(
      id: json['id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      requirements: json['requirements'] as Map<String, dynamic>?,
      progress: json['progress'] as Map<String, dynamic>?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      xpReward: (json['xpReward'] as num?)?.toInt() ?? 0,
      itemRewards: (json['itemRewards'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$QuestObjectiveToJson(QuestObjective instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'type': instance.type,
      'requirements': instance.requirements,
      'progress': instance.progress,
      'isCompleted': instance.isCompleted,
      'xpReward': instance.xpReward,
      'itemRewards': instance.itemRewards,
    };

Quest _$QuestFromJson(Map<String, dynamic> json) => Quest(
      id: json['id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$QuestTypeEnumMap, json['type']),
      level: (json['level'] as num?)?.toInt() ?? 1,
      location: json['location'] == null
          ? null
          : GeoLocation.fromJson(json['location'] as Map<String, dynamic>),
      radius: (json['radius'] as num?)?.toDouble(),
      objectives: (json['objectives'] as List<dynamic>?)
          ?.map((e) => QuestObjective.fromJson(e as Map<String, dynamic>))
          .toList(),
      rewards: json['rewards'] as Map<String, dynamic>?,
      startTime: json['startTime'] == null
          ? null
          : DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      isActive: json['isActive'] as bool? ?? true,
      isCompleted: json['isCompleted'] as bool? ?? false,
      xpReward: (json['xpReward'] as num?)?.toInt() ?? 0,
      cardRewards: (json['cardRewards'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$QuestToJson(Quest instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'type': _$QuestTypeEnumMap[instance.type]!,
      'level': instance.level,
      'location': instance.location,
      'radius': instance.radius,
      'objectives': instance.objectives,
      'rewards': instance.rewards,
      'startTime': instance.startTime?.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'isActive': instance.isActive,
      'isCompleted': instance.isCompleted,
      'xpReward': instance.xpReward,
      'cardRewards': instance.cardRewards,
      'metadata': instance.metadata,
    };

const _$QuestTypeEnumMap = {
  QuestType.exploration: 'exploration',
  QuestType.fitness: 'fitness',
  QuestType.social: 'social',
  QuestType.collection: 'collection',
  QuestType.battle: 'battle',
  QuestType.treasure: 'treasure',
  QuestType.seasonal: 'seasonal',
  QuestType.daily: 'daily',
  QuestType.weekly: 'weekly',
  QuestType.legendary: 'legendary',
};

WorldSpawn _$WorldSpawnFromJson(Map<String, dynamic> json) => WorldSpawn(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$SpawnTypeEnumMap, json['type']),
      location: GeoLocation.fromJson(json['location'] as Map<String, dynamic>),
      radius: (json['radius'] as num?)?.toDouble() ?? 50.0,
      spawnTime: json['spawnTime'] == null
          ? null
          : DateTime.parse(json['spawnTime'] as String),
      despawnTime: json['despawnTime'] == null
          ? null
          : DateTime.parse(json['despawnTime'] as String),
      level: (json['level'] as num?)?.toInt() ?? 1,
      availableCards: (json['availableCards'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      rewards: json['rewards'] as Map<String, dynamic>?,
      isActive: json['isActive'] as bool? ?? true,
      maxInteractions: (json['maxInteractions'] as num?)?.toInt() ?? 10,
      currentInteractions: (json['currentInteractions'] as num?)?.toInt() ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$WorldSpawnToJson(WorldSpawn instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'type': _$SpawnTypeEnumMap[instance.type]!,
      'location': instance.location,
      'radius': instance.radius,
      'spawnTime': instance.spawnTime.toIso8601String(),
      'despawnTime': instance.despawnTime?.toIso8601String(),
      'level': instance.level,
      'availableCards': instance.availableCards,
      'rewards': instance.rewards,
      'isActive': instance.isActive,
      'maxInteractions': instance.maxInteractions,
      'currentInteractions': instance.currentInteractions,
      'metadata': instance.metadata,
    };

const _$SpawnTypeEnumMap = {
  SpawnType.common: 'common',
  SpawnType.uncommon: 'uncommon',
  SpawnType.rare: 'rare',
  SpawnType.epic: 'epic',
  SpawnType.legendary: 'legendary',
  SpawnType.boss: 'boss',
  SpawnType.treasure: 'treasure',
  SpawnType.portal: 'portal',
  SpawnType.merchant: 'merchant',
  SpawnType.guild: 'guild',
};

POI _$POIFromJson(Map<String, dynamic> json) => POI(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$LocationTypeEnumMap, json['type']),
      location: GeoLocation.fromJson(json['location'] as Map<String, dynamic>),
      radius: (json['radius'] as num?)?.toDouble() ?? 100.0,
      isActive: json['isActive'] as bool? ?? true,
      properties: json['properties'] as Map<String, dynamic>?,
      associatedQuests: (json['associatedQuests'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      spawnHistory: (json['spawnHistory'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      lastVisited: json['lastVisited'] == null
          ? null
          : DateTime.parse(json['lastVisited'] as String),
    );

Map<String, dynamic> _$POIToJson(POI instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'type': _$LocationTypeEnumMap[instance.type]!,
      'location': instance.location,
      'radius': instance.radius,
      'isActive': instance.isActive,
      'properties': instance.properties,
      'associatedQuests': instance.associatedQuests,
      'spawnHistory': instance.spawnHistory,
      'popularity': instance.popularity,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastVisited': instance.lastVisited?.toIso8601String(),
    };

const _$LocationTypeEnumMap = {
  LocationType.park: 'park',
  LocationType.gym: 'gym',
  LocationType.restaurant: 'restaurant',
  LocationType.business: 'business',
  LocationType.monument: 'monument',
  LocationType.bridge: 'bridge',
  LocationType.library: 'library',
  LocationType.school: 'school',
  LocationType.hospital: 'hospital',
  LocationType.church: 'church',
  LocationType.mall: 'mall',
  LocationType.beach: 'beach',
  LocationType.mountain: 'mountain',
  LocationType.trail: 'trail',
  LocationType.other: 'other',
};
