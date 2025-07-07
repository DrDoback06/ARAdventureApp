// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cosmetic_system.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CosmeticItem _$CosmeticItemFromJson(Map<String, dynamic> json) => CosmeticItem(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$CosmeticTypeEnumMap, json['type']),
      rarity: $enumDecode(_$CosmeticRarityEnumMap, json['rarity']),
      unlockMethod: $enumDecode(_$UnlockMethodEnumMap, json['unlockMethod']),
      unlockRequirements: json['unlockRequirements'] as Map<String, dynamic>?,
      goldCost: (json['goldCost'] as num?)?.toInt() ?? 0,
      premiumCost: (json['premiumCost'] as num?)?.toInt() ?? 0,
      isAnimated: json['isAnimated'] as bool? ?? false,
      isExclusive: json['isExclusive'] as bool? ?? false,
      availableUntil: json['availableUntil'] == null
          ? null
          : DateTime.parse(json['availableUntil'] as String),
      previewUrl: json['previewUrl'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      properties: json['properties'] as Map<String, dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$CosmeticItemToJson(CosmeticItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'type': _$CosmeticTypeEnumMap[instance.type]!,
      'rarity': _$CosmeticRarityEnumMap[instance.rarity]!,
      'unlockMethod': _$UnlockMethodEnumMap[instance.unlockMethod]!,
      'unlockRequirements': instance.unlockRequirements,
      'goldCost': instance.goldCost,
      'premiumCost': instance.premiumCost,
      'isAnimated': instance.isAnimated,
      'isExclusive': instance.isExclusive,
      'availableUntil': instance.availableUntil?.toIso8601String(),
      'previewUrl': instance.previewUrl,
      'tags': instance.tags,
      'properties': instance.properties,
      'metadata': instance.metadata,
    };

const _$CosmeticTypeEnumMap = {
  CosmeticType.avatar_skin: 'avatar_skin',
  CosmeticType.avatar_outfit: 'avatar_outfit',
  CosmeticType.avatar_accessory: 'avatar_accessory',
  CosmeticType.ui_theme: 'ui_theme',
  CosmeticType.card_back: 'card_back',
  CosmeticType.border: 'border',
  CosmeticType.emote: 'emote',
  CosmeticType.title: 'title',
  CosmeticType.pet: 'pet',
  CosmeticType.mount: 'mount',
  CosmeticType.effect: 'effect',
  CosmeticType.background: 'background',
};

const _$CosmeticRarityEnumMap = {
  CosmeticRarity.common: 'common',
  CosmeticRarity.uncommon: 'uncommon',
  CosmeticRarity.rare: 'rare',
  CosmeticRarity.epic: 'epic',
  CosmeticRarity.legendary: 'legendary',
  CosmeticRarity.mythic: 'mythic',
  CosmeticRarity.exclusive: 'exclusive',
  CosmeticRarity.founders: 'founders',
};

const _$UnlockMethodEnumMap = {
  UnlockMethod.purchase: 'purchase',
  UnlockMethod.achievement: 'achievement',
  UnlockMethod.event: 'event',
  UnlockMethod.level: 'level',
  UnlockMethod.fitness: 'fitness',
  UnlockMethod.collection: 'collection',
  UnlockMethod.guild: 'guild',
  UnlockMethod.seasonal: 'seasonal',
  UnlockMethod.premium: 'premium',
  UnlockMethod.founder: 'founder',
  UnlockMethod.charity: 'charity',
};

PlayerCosmetics _$PlayerCosmeticsFromJson(Map<String, dynamic> json) =>
    PlayerCosmetics(
      playerId: json['playerId'] as String,
      equippedItems: (json['equippedItems'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry($enumDecode(_$CosmeticTypeEnumMap, k), e as String),
      ),
      ownedItems: (json['ownedItems'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      unlockDates: (json['unlockDates'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, DateTime.parse(e as String)),
      ),
      customizations: json['customizations'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$PlayerCosmeticsToJson(PlayerCosmetics instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'equippedItems': instance.equippedItems
          .map((k, e) => MapEntry(_$CosmeticTypeEnumMap[k]!, e)),
      'ownedItems': instance.ownedItems,
      'unlockDates':
          instance.unlockDates.map((k, e) => MapEntry(k, e.toIso8601String())),
      'customizations': instance.customizations,
    };
