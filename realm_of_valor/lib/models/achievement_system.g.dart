// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement_system.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Achievement _$AchievementFromJson(Map<String, dynamic> json) => Achievement(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$AchievementTypeEnumMap, json['type']),
      tier: $enumDecodeNullable(_$AchievementTierEnumMap, json['tier']) ??
          AchievementTier.bronze,
      iconUrl: json['iconUrl'] as String? ?? '',
      requirements: json['requirements'] as Map<String, dynamic>?,
      progress: json['progress'] as Map<String, dynamic>?,
      rewards: json['rewards'] as Map<String, dynamic>?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isHidden: json['isHidden'] as bool? ?? false,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      points: (json['points'] as num?)?.toInt() ?? 10,
      prerequisites: (json['prerequisites'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$AchievementToJson(Achievement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'type': _$AchievementTypeEnumMap[instance.type]!,
      'tier': _$AchievementTierEnumMap[instance.tier]!,
      'iconUrl': instance.iconUrl,
      'requirements': instance.requirements,
      'progress': instance.progress,
      'rewards': instance.rewards,
      'isCompleted': instance.isCompleted,
      'isHidden': instance.isHidden,
      'completedAt': instance.completedAt?.toIso8601String(),
      'points': instance.points,
      'prerequisites': instance.prerequisites,
      'metadata': instance.metadata,
    };

const _$AchievementTypeEnumMap = {
  AchievementType.collection: 'collection',
  AchievementType.exploration: 'exploration',
  AchievementType.fitness: 'fitness',
  AchievementType.battle: 'battle',
  AchievementType.social: 'social',
  AchievementType.quest: 'quest',
  AchievementType.seasonal: 'seasonal',
  AchievementType.legendary: 'legendary',
  AchievementType.secret: 'secret',
};

const _$AchievementTierEnumMap = {
  AchievementTier.bronze: 'bronze',
  AchievementTier.silver: 'silver',
  AchievementTier.gold: 'gold',
  AchievementTier.platinum: 'platinum',
  AchievementTier.diamond: 'diamond',
  AchievementTier.legendary: 'legendary',
  AchievementTier.mythic: 'mythic',
};

Collection _$CollectionFromJson(Map<String, dynamic> json) => Collection(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String,
      cardIds:
          (json['cardIds'] as List<dynamic>?)?.map((e) => e as String).toList(),
      ownedCardIds: (json['ownedCardIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      cardCounts: (json['cardCounts'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ),
      bonuses: json['bonuses'] as Map<String, dynamic>?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      completionReward: (json['completionReward'] as num?)?.toInt() ?? 0,
      rewardCards: (json['rewardCards'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$CollectionToJson(Collection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'cardIds': instance.cardIds,
      'ownedCardIds': instance.ownedCardIds,
      'cardCounts': instance.cardCounts,
      'bonuses': instance.bonuses,
      'isCompleted': instance.isCompleted,
      'completedAt': instance.completedAt?.toIso8601String(),
      'completionReward': instance.completionReward,
      'rewardCards': instance.rewardCards,
      'metadata': instance.metadata,
    };

Badge _$BadgeFromJson(Map<String, dynamic> json) => Badge(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String,
      category: $enumDecode(_$BadgeCategoryEnumMap, json['category']),
      iconUrl: json['iconUrl'] as String? ?? '',
      colorHex: json['colorHex'] as String? ?? '#FFD700',
      earnedAt: json['earnedAt'] == null
          ? null
          : DateTime.parse(json['earnedAt'] as String),
      criteria: json['criteria'] as Map<String, dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$BadgeToJson(Badge instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'category': _$BadgeCategoryEnumMap[instance.category]!,
      'iconUrl': instance.iconUrl,
      'colorHex': instance.colorHex,
      'earnedAt': instance.earnedAt.toIso8601String(),
      'criteria': instance.criteria,
      'metadata': instance.metadata,
    };

const _$BadgeCategoryEnumMap = {
  BadgeCategory.collector: 'collector',
  BadgeCategory.explorer: 'explorer',
  BadgeCategory.warrior: 'warrior',
  BadgeCategory.socialite: 'socialite',
  BadgeCategory.champion: 'champion',
  BadgeCategory.guardian: 'guardian',
  BadgeCategory.legend: 'legend',
  BadgeCategory.special: 'special',
};
