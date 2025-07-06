// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StatModifier _$StatModifierFromJson(Map<String, dynamic> json) => StatModifier(
      statName: json['statName'] as String,
      value: (json['value'] as num).toInt(),
      isPercentage: json['isPercentage'] as bool? ?? false,
    );

Map<String, dynamic> _$StatModifierToJson(StatModifier instance) =>
    <String, dynamic>{
      'statName': instance.statName,
      'value': instance.value,
      'isPercentage': instance.isPercentage,
    };

CardCondition _$CardConditionFromJson(Map<String, dynamic> json) =>
    CardCondition(
      type: json['type'] as String,
      value: json['value'] as String,
      description: json['description'] as String,
    );

Map<String, dynamic> _$CardConditionToJson(CardCondition instance) =>
    <String, dynamic>{
      'type': instance.type,
      'value': instance.value,
      'description': instance.description,
    };

CardEffect _$CardEffectFromJson(Map<String, dynamic> json) => CardEffect(
      type: json['type'] as String,
      value: json['value'] as String,
      description: json['description'] as String,
      duration: (json['duration'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$CardEffectToJson(CardEffect instance) =>
    <String, dynamic>{
      'type': instance.type,
      'value': instance.value,
      'description': instance.description,
      'duration': instance.duration,
    };

GameCard _$GameCardFromJson(Map<String, dynamic> json) => GameCard(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$CardTypeEnumMap, json['type']),
      rarity: $enumDecodeNullable(_$CardRarityEnumMap, json['rarity']) ??
          CardRarity.common,
      equipmentSlot:
          $enumDecodeNullable(_$EquipmentSlotEnumMap, json['equipmentSlot']) ??
              EquipmentSlot.none,
      allowedClasses: (json['allowedClasses'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$CharacterClassEnumMap, e))
          .toSet(),
      statModifiers: (json['statModifiers'] as List<dynamic>?)
          ?.map((e) => StatModifier.fromJson(e as Map<String, dynamic>))
          .toList(),
      conditions: (json['conditions'] as List<dynamic>?)
          ?.map((e) => CardCondition.fromJson(e as Map<String, dynamic>))
          .toList(),
      effects: (json['effects'] as List<dynamic>?)
          ?.map((e) => CardEffect.fromJson(e as Map<String, dynamic>))
          .toList(),
      imageUrl: json['imageUrl'] as String? ?? '',
      cost: (json['cost'] as num?)?.toInt() ?? 0,
      levelRequirement: (json['levelRequirement'] as num?)?.toInt() ?? 1,
      durability: (json['durability'] as num?)?.toInt() ?? 100,
      maxStack: (json['maxStack'] as num?)?.toInt() ?? 1,
      isConsumable: json['isConsumable'] as bool? ?? false,
      isTradeable: json['isTradeable'] as bool? ?? true,
      customProperties: json['customProperties'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$GameCardToJson(GameCard instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'type': _$CardTypeEnumMap[instance.type]!,
      'rarity': _$CardRarityEnumMap[instance.rarity]!,
      'equipmentSlot': _$EquipmentSlotEnumMap[instance.equipmentSlot]!,
      'allowedClasses': instance.allowedClasses
          .map((e) => _$CharacterClassEnumMap[e]!)
          .toList(),
      'statModifiers': instance.statModifiers,
      'conditions': instance.conditions,
      'effects': instance.effects,
      'imageUrl': instance.imageUrl,
      'cost': instance.cost,
      'levelRequirement': instance.levelRequirement,
      'durability': instance.durability,
      'maxStack': instance.maxStack,
      'isConsumable': instance.isConsumable,
      'isTradeable': instance.isTradeable,
      'customProperties': instance.customProperties,
    };

const _$CardTypeEnumMap = {
  CardType.item: 'item',
  CardType.quest: 'quest',
  CardType.adventure: 'adventure',
  CardType.skill: 'skill',
  CardType.weapon: 'weapon',
  CardType.armor: 'armor',
  CardType.accessory: 'accessory',
  CardType.consumable: 'consumable',
  CardType.spell: 'spell',
};

const _$CardRarityEnumMap = {
  CardRarity.common: 'common',
  CardRarity.uncommon: 'uncommon',
  CardRarity.rare: 'rare',
  CardRarity.epic: 'epic',
  CardRarity.legendary: 'legendary',
  CardRarity.mythic: 'mythic',
};

const _$EquipmentSlotEnumMap = {
  EquipmentSlot.none: 'none',
  EquipmentSlot.helmet: 'helmet',
  EquipmentSlot.armor: 'armor',
  EquipmentSlot.weapon1: 'weapon1',
  EquipmentSlot.weapon2: 'weapon2',
  EquipmentSlot.gloves: 'gloves',
  EquipmentSlot.boots: 'boots',
  EquipmentSlot.belt: 'belt',
  EquipmentSlot.ring1: 'ring1',
  EquipmentSlot.ring2: 'ring2',
  EquipmentSlot.amulet: 'amulet',
};

const _$CharacterClassEnumMap = {
  CharacterClass.paladin: 'paladin',
  CharacterClass.barbarian: 'barbarian',
  CharacterClass.necromancer: 'necromancer',
  CharacterClass.sorceress: 'sorceress',
  CharacterClass.amazon: 'amazon',
  CharacterClass.assassin: 'assassin',
  CharacterClass.druid: 'druid',
  CharacterClass.monk: 'monk',
  CharacterClass.crusader: 'crusader',
  CharacterClass.witchDoctor: 'witchDoctor',
  CharacterClass.wizard: 'wizard',
  CharacterClass.demonHunter: 'demonHunter',
};

CardInstance _$CardInstanceFromJson(Map<String, dynamic> json) => CardInstance(
      instanceId: json['instanceId'] as String?,
      card: GameCard.fromJson(json['card'] as Map<String, dynamic>),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      currentDurability: (json['currentDurability'] as num?)?.toInt(),
      acquiredAt: json['acquiredAt'] == null
          ? null
          : DateTime.parse(json['acquiredAt'] as String),
      instanceData: json['instanceData'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$CardInstanceToJson(CardInstance instance) =>
    <String, dynamic>{
      'instanceId': instance.instanceId,
      'card': instance.card,
      'quantity': instance.quantity,
      'currentDurability': instance.currentDurability,
      'acquiredAt': instance.acquiredAt.toIso8601String(),
      'instanceData': instance.instanceData,
    };
