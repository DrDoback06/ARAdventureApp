// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_system.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventReward _$EventRewardFromJson(Map<String, dynamic> json) => EventReward(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String,
      tier: $enumDecode(_$RewardTierEnumMap, json['tier']),
      cardIds:
          (json['cardIds'] as List<dynamic>?)?.map((e) => e as String).toList(),
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      gold: (json['gold'] as num?)?.toInt() ?? 0,
      specialRewards: json['specialRewards'] as Map<String, dynamic>?,
      isExclusive: json['isExclusive'] as bool? ?? false,
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
    );

Map<String, dynamic> _$EventRewardToJson(EventReward instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'tier': _$RewardTierEnumMap[instance.tier]!,
      'cardIds': instance.cardIds,
      'xp': instance.xp,
      'gold': instance.gold,
      'specialRewards': instance.specialRewards,
      'isExclusive': instance.isExclusive,
      'expiresAt': instance.expiresAt?.toIso8601String(),
    };

const _$RewardTierEnumMap = {
  RewardTier.bronze: 'bronze',
  RewardTier.silver: 'silver',
  RewardTier.gold: 'gold',
  RewardTier.platinum: 'platinum',
  RewardTier.diamond: 'diamond',
  RewardTier.legendary: 'legendary',
};

EventObjective _$EventObjectiveFromJson(Map<String, dynamic> json) =>
    EventObjective(
      id: json['id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      requirements: json['requirements'] as Map<String, dynamic>,
      currentProgress: (json['currentProgress'] as num?)?.toInt() ?? 0,
      targetProgress: (json['targetProgress'] as num).toInt(),
      isCompleted: json['isCompleted'] as bool? ?? false,
      reward: json['reward'] == null
          ? null
          : EventReward.fromJson(json['reward'] as Map<String, dynamic>),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$EventObjectiveToJson(EventObjective instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'type': instance.type,
      'requirements': instance.requirements,
      'currentProgress': instance.currentProgress,
      'targetProgress': instance.targetProgress,
      'isCompleted': instance.isCompleted,
      'reward': instance.reward,
      'metadata': instance.metadata,
    };

GameEvent _$GameEventFromJson(Map<String, dynamic> json) => GameEvent(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$EventTypeEnumMap, json['type']),
      status: $enumDecodeNullable(_$EventStatusEnumMap, json['status']) ??
          EventStatus.upcoming,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      objectives: (json['objectives'] as List<dynamic>?)
          ?.map((e) => EventObjective.fromJson(e as Map<String, dynamic>))
          .toList(),
      rewards: (json['rewards'] as List<dynamic>?)
          ?.map((e) => EventReward.fromJson(e as Map<String, dynamic>))
          .toList(),
      requirements: json['requirements'] as Map<String, dynamic>?,
      globalProgress: json['globalProgress'] as Map<String, dynamic>?,
      isRecurring: json['isRecurring'] as bool? ?? false,
      iconUrl: json['iconUrl'] as String? ?? '',
      bannerUrl: json['bannerUrl'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$GameEventToJson(GameEvent instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'type': _$EventTypeEnumMap[instance.type]!,
      'status': _$EventStatusEnumMap[instance.status]!,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'objectives': instance.objectives,
      'rewards': instance.rewards,
      'requirements': instance.requirements,
      'globalProgress': instance.globalProgress,
      'isRecurring': instance.isRecurring,
      'iconUrl': instance.iconUrl,
      'bannerUrl': instance.bannerUrl,
      'metadata': instance.metadata,
    };

const _$EventTypeEnumMap = {
  EventType.limited_time: 'limited_time',
  EventType.seasonal: 'seasonal',
  EventType.community: 'community',
  EventType.guild: 'guild',
  EventType.fitness: 'fitness',
  EventType.collection: 'collection',
  EventType.pvp: 'pvp',
  EventType.exploration: 'exploration',
  EventType.charity: 'charity',
};

const _$EventStatusEnumMap = {
  EventStatus.upcoming: 'upcoming',
  EventStatus.active: 'active',
  EventStatus.ending_soon: 'ending_soon',
  EventStatus.completed: 'completed',
  EventStatus.failed: 'failed',
};
