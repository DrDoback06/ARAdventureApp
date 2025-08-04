// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'specialization_system.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpecializationNode _$SpecializationNodeFromJson(Map<String, dynamic> json) =>
    SpecializationNode(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$SpecializationTypeEnumMap, json['type']),
      tier: $enumDecode(_$SpecializationTierEnumMap, json['tier']),
      cost: (json['cost'] as num).toInt(),
      prerequisites: (json['prerequisites'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      effects: json['effects'] as Map<String, dynamic>?,
      iconPath: json['iconPath'] as String? ?? '',
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? false,
    );

Map<String, dynamic> _$SpecializationNodeToJson(SpecializationNode instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'type': _$SpecializationTypeEnumMap[instance.type]!,
      'tier': _$SpecializationTierEnumMap[instance.tier]!,
      'cost': instance.cost,
      'prerequisites': instance.prerequisites,
      'effects': instance.effects,
      'iconPath': instance.iconPath,
      'isUnlocked': instance.isUnlocked,
      'isActive': instance.isActive,
    };

const _$SpecializationTypeEnumMap = {
  SpecializationType.offensive: 'offensive',
  SpecializationType.defensive: 'defensive',
  SpecializationType.support: 'support',
  SpecializationType.utility: 'utility',
  SpecializationType.hybrid: 'hybrid',
};

const _$SpecializationTierEnumMap = {
  SpecializationTier.novice: 'novice',
  SpecializationTier.adept: 'adept',
  SpecializationTier.expert: 'expert',
  SpecializationTier.master: 'master',
  SpecializationTier.legendary: 'legendary',
};

SpecializationTree _$SpecializationTreeFromJson(Map<String, dynamic> json) =>
    SpecializationTree(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String,
      characterClass:
          $enumDecode(_$CharacterClassEnumMap, json['characterClass']),
      nodes: (json['nodes'] as List<dynamic>?)
          ?.map((e) => SpecializationNode.fromJson(e as Map<String, dynamic>))
          .toList(),
      connections: (json['connections'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      ),
      maxActiveNodes: (json['maxActiveNodes'] as num?)?.toInt() ?? 3,
      totalSkillPoints: (json['totalSkillPoints'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$SpecializationTreeToJson(SpecializationTree instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'characterClass': _$CharacterClassEnumMap[instance.characterClass]!,
      'nodes': instance.nodes,
      'connections': instance.connections,
      'maxActiveNodes': instance.maxActiveNodes,
      'totalSkillPoints': instance.totalSkillPoints,
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
