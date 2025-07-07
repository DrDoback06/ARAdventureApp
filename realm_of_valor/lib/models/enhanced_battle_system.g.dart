// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enhanced_battle_system.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ElementalAffinities _$ElementalAffinitiesFromJson(Map<String, dynamic> json) =>
    ElementalAffinities();

Map<String, dynamic> _$ElementalAffinitiesToJson(
        ElementalAffinities instance) =>
    <String, dynamic>{};

BattleAction _$BattleActionFromJson(Map<String, dynamic> json) => BattleAction(
      id: json['id'] as String?,
      type: $enumDecode(_$ActionTypeEnumMap, json['type']),
      name: json['name'] as String,
      description: json['description'] as String,
      element: $enumDecodeNullable(_$ElementTypeEnumMap, json['element']) ??
          ElementType.physical,
      baseDamage: (json['baseDamage'] as num?)?.toInt() ?? 0,
      manaCost: (json['manaCost'] as num?)?.toInt() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toInt() ?? 100,
      criticalChance: (json['criticalChance'] as num?)?.toInt() ?? 5,
      statusEffects: (json['statusEffects'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$StatusEffectEnumMap, e))
          .toList(),
      properties: json['properties'] as Map<String, dynamic>?,
      isCombo: json['isCombo'] as bool? ?? false,
      comboRequirements: (json['comboRequirements'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      priority: (json['priority'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$BattleActionToJson(BattleAction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$ActionTypeEnumMap[instance.type]!,
      'name': instance.name,
      'description': instance.description,
      'element': _$ElementTypeEnumMap[instance.element]!,
      'baseDamage': instance.baseDamage,
      'manaCost': instance.manaCost,
      'accuracy': instance.accuracy,
      'criticalChance': instance.criticalChance,
      'statusEffects':
          instance.statusEffects.map((e) => _$StatusEffectEnumMap[e]!).toList(),
      'properties': instance.properties,
      'isCombo': instance.isCombo,
      'comboRequirements': instance.comboRequirements,
      'priority': instance.priority,
    };

const _$ActionTypeEnumMap = {
  ActionType.attack: 'attack',
  ActionType.defend: 'defend',
  ActionType.spell: 'spell',
  ActionType.item: 'item',
  ActionType.skill: 'skill',
  ActionType.combo: 'combo',
  ActionType.counter: 'counter',
  ActionType.charge: 'charge',
};

const _$ElementTypeEnumMap = {
  ElementType.fire: 'fire',
  ElementType.water: 'water',
  ElementType.earth: 'earth',
  ElementType.air: 'air',
  ElementType.light: 'light',
  ElementType.shadow: 'shadow',
  ElementType.lightning: 'lightning',
  ElementType.ice: 'ice',
  ElementType.nature: 'nature',
  ElementType.arcane: 'arcane',
  ElementType.physical: 'physical',
  ElementType.neutral: 'neutral',
};

const _$StatusEffectEnumMap = {
  StatusEffect.poison: 'poison',
  StatusEffect.burn: 'burn',
  StatusEffect.freeze: 'freeze',
  StatusEffect.shock: 'shock',
  StatusEffect.blind: 'blind',
  StatusEffect.curse: 'curse',
  StatusEffect.blessing: 'blessing',
  StatusEffect.shield: 'shield',
  StatusEffect.regeneration: 'regeneration',
  StatusEffect.berserk: 'berserk',
  StatusEffect.stealth: 'stealth',
  StatusEffect.haste: 'haste',
  StatusEffect.slow: 'slow',
  StatusEffect.weakness: 'weakness',
  StatusEffect.strength: 'strength',
  StatusEffect.immunity: 'immunity',
};

StatusEffectInstance _$StatusEffectInstanceFromJson(
        Map<String, dynamic> json) =>
    StatusEffectInstance(
      id: json['id'] as String?,
      type: $enumDecode(_$StatusEffectEnumMap, json['type']),
      duration: (json['duration'] as num).toInt(),
      intensity: (json['intensity'] as num?)?.toInt() ?? 1,
      source: json['source'] as String,
      properties: json['properties'] as Map<String, dynamic>?,
      appliedAt: json['appliedAt'] == null
          ? null
          : DateTime.parse(json['appliedAt'] as String),
    );

Map<String, dynamic> _$StatusEffectInstanceToJson(
        StatusEffectInstance instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$StatusEffectEnumMap[instance.type]!,
      'duration': instance.duration,
      'intensity': instance.intensity,
      'source': instance.source,
      'properties': instance.properties,
      'appliedAt': instance.appliedAt.toIso8601String(),
    };

BattleParticipant _$BattleParticipantFromJson(Map<String, dynamic> json) =>
    BattleParticipant(
      id: json['id'] as String?,
      name: json['name'] as String,
      level: (json['level'] as num).toInt(),
      primaryElement:
          $enumDecodeNullable(_$ElementTypeEnumMap, json['primaryElement']) ??
              ElementType.neutral,
      secondaryElement:
          $enumDecodeNullable(_$ElementTypeEnumMap, json['secondaryElement']),
      stats: (json['stats'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ),
      deck: (json['deck'] as List<dynamic>?)
          ?.map((e) => GameCard.fromJson(e as Map<String, dynamic>))
          .toList(),
      hand: (json['hand'] as List<dynamic>?)
          ?.map((e) => GameCard.fromJson(e as Map<String, dynamic>))
          .toList(),
      statusEffects: (json['statusEffects'] as List<dynamic>?)
          ?.map((e) => StatusEffectInstance.fromJson(e as Map<String, dynamic>))
          .toList(),
      battleState: json['battleState'] as Map<String, dynamic>?,
      isAI: json['isAI'] as bool? ?? false,
      playerId: json['playerId'] as String?,
    );

Map<String, dynamic> _$BattleParticipantToJson(BattleParticipant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'level': instance.level,
      'primaryElement': _$ElementTypeEnumMap[instance.primaryElement]!,
      'secondaryElement': _$ElementTypeEnumMap[instance.secondaryElement],
      'stats': instance.stats,
      'deck': instance.deck,
      'hand': instance.hand,
      'statusEffects': instance.statusEffects,
      'battleState': instance.battleState,
      'isAI': instance.isAI,
      'playerId': instance.playerId,
    };

EnhancedBattle _$EnhancedBattleFromJson(Map<String, dynamic> json) =>
    EnhancedBattle(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String,
      participants: (json['participants'] as List<dynamic>?)
          ?.map((e) => BattleParticipant.fromJson(e as Map<String, dynamic>))
          .toList(),
      phase: $enumDecodeNullable(_$BattlePhaseEnumMap, json['phase']) ??
          BattlePhase.preparation,
      currentTurn: (json['currentTurn'] as num?)?.toInt() ?? 1,
      activeParticipantId: json['activeParticipantId'] as String?,
      battleState: json['battleState'] as Map<String, dynamic>?,
      battleLog: (json['battleLog'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      startTime: json['startTime'] == null
          ? null
          : DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      winnerId: json['winnerId'] as String?,
      rewards: json['rewards'] as Map<String, dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$EnhancedBattleToJson(EnhancedBattle instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'participants': instance.participants,
      'phase': _$BattlePhaseEnumMap[instance.phase]!,
      'currentTurn': instance.currentTurn,
      'activeParticipantId': instance.activeParticipantId,
      'battleState': instance.battleState,
      'battleLog': instance.battleLog,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'winnerId': instance.winnerId,
      'rewards': instance.rewards,
      'metadata': instance.metadata,
    };

const _$BattlePhaseEnumMap = {
  BattlePhase.preparation: 'preparation',
  BattlePhase.combat: 'combat',
  BattlePhase.resolution: 'resolution',
  BattlePhase.ended: 'ended',
};
