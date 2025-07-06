// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Equipment _$EquipmentFromJson(Map<String, dynamic> json) => Equipment(
      helmet: json['helmet'] == null
          ? null
          : CardInstance.fromJson(json['helmet'] as Map<String, dynamic>),
      armor: json['armor'] == null
          ? null
          : CardInstance.fromJson(json['armor'] as Map<String, dynamic>),
      weapon1: json['weapon1'] == null
          ? null
          : CardInstance.fromJson(json['weapon1'] as Map<String, dynamic>),
      weapon2: json['weapon2'] == null
          ? null
          : CardInstance.fromJson(json['weapon2'] as Map<String, dynamic>),
      gloves: json['gloves'] == null
          ? null
          : CardInstance.fromJson(json['gloves'] as Map<String, dynamic>),
      boots: json['boots'] == null
          ? null
          : CardInstance.fromJson(json['boots'] as Map<String, dynamic>),
      belt: json['belt'] == null
          ? null
          : CardInstance.fromJson(json['belt'] as Map<String, dynamic>),
      ring1: json['ring1'] == null
          ? null
          : CardInstance.fromJson(json['ring1'] as Map<String, dynamic>),
      ring2: json['ring2'] == null
          ? null
          : CardInstance.fromJson(json['ring2'] as Map<String, dynamic>),
      amulet: json['amulet'] == null
          ? null
          : CardInstance.fromJson(json['amulet'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$EquipmentToJson(Equipment instance) => <String, dynamic>{
      'helmet': instance.helmet,
      'armor': instance.armor,
      'weapon1': instance.weapon1,
      'weapon2': instance.weapon2,
      'gloves': instance.gloves,
      'boots': instance.boots,
      'belt': instance.belt,
      'ring1': instance.ring1,
      'ring2': instance.ring2,
      'amulet': instance.amulet,
    };

Skill _$SkillFromJson(Map<String, dynamic> json) => Skill(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String,
      level: (json['level'] as num?)?.toInt() ?? 0,
      maxLevel: (json['maxLevel'] as num?)?.toInt() ?? 20,
      requiredClass:
          $enumDecode(_$CharacterClassEnumMap, json['requiredClass']),
      prerequisites: (json['prerequisites'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      bonuses: (json['bonuses'] as List<dynamic>?)
          ?.map((e) => StatModifier.fromJson(e as Map<String, dynamic>))
          .toList(),
      iconUrl: json['iconUrl'] as String? ?? '',
    );

Map<String, dynamic> _$SkillToJson(Skill instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'level': instance.level,
      'maxLevel': instance.maxLevel,
      'requiredClass': _$CharacterClassEnumMap[instance.requiredClass]!,
      'prerequisites': instance.prerequisites,
      'bonuses': instance.bonuses,
      'iconUrl': instance.iconUrl,
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

GameCharacter _$GameCharacterFromJson(Map<String, dynamic> json) =>
    GameCharacter(
      id: json['id'] as String?,
      name: json['name'] as String,
      characterClass:
          $enumDecode(_$CharacterClassEnumMap, json['characterClass']),
      level: (json['level'] as num?)?.toInt() ?? 1,
      experience: (json['experience'] as num?)?.toInt() ?? 0,
      experienceToNext: (json['experienceToNext'] as num?)?.toInt(),
      baseStrength: (json['baseStrength'] as num?)?.toInt() ?? 10,
      baseDexterity: (json['baseDexterity'] as num?)?.toInt() ?? 10,
      baseVitality: (json['baseVitality'] as num?)?.toInt() ?? 10,
      baseEnergy: (json['baseEnergy'] as num?)?.toInt() ?? 10,
      allocatedStrength: (json['allocatedStrength'] as num?)?.toInt() ?? 0,
      allocatedDexterity: (json['allocatedDexterity'] as num?)?.toInt() ?? 0,
      allocatedVitality: (json['allocatedVitality'] as num?)?.toInt() ?? 0,
      allocatedEnergy: (json['allocatedEnergy'] as num?)?.toInt() ?? 0,
      availableStatPoints: (json['availableStatPoints'] as num?)?.toInt() ?? 0,
      availableSkillPoints:
          (json['availableSkillPoints'] as num?)?.toInt() ?? 0,
      equipment: json['equipment'] == null
          ? null
          : Equipment.fromJson(json['equipment'] as Map<String, dynamic>),
      inventory: (json['inventory'] as List<dynamic>?)
          ?.map((e) => CardInstance.fromJson(e as Map<String, dynamic>))
          .toList(),
      stash: (json['stash'] as List<dynamic>?)
          ?.map((e) => CardInstance.fromJson(e as Map<String, dynamic>))
          .toList(),
      skills: (json['skills'] as List<dynamic>?)
          ?.map((e) => Skill.fromJson(e as Map<String, dynamic>))
          .toList(),
      skillSlots: (json['skillSlots'] as List<dynamic>?)
          ?.map((e) => CardInstance.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      lastPlayed: json['lastPlayed'] == null
          ? null
          : DateTime.parse(json['lastPlayed'] as String),
      characterData: json['characterData'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$GameCharacterToJson(GameCharacter instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'characterClass': _$CharacterClassEnumMap[instance.characterClass]!,
      'level': instance.level,
      'experience': instance.experience,
      'experienceToNext': instance.experienceToNext,
      'baseStrength': instance.baseStrength,
      'baseDexterity': instance.baseDexterity,
      'baseVitality': instance.baseVitality,
      'baseEnergy': instance.baseEnergy,
      'allocatedStrength': instance.allocatedStrength,
      'allocatedDexterity': instance.allocatedDexterity,
      'allocatedVitality': instance.allocatedVitality,
      'allocatedEnergy': instance.allocatedEnergy,
      'availableStatPoints': instance.availableStatPoints,
      'availableSkillPoints': instance.availableSkillPoints,
      'equipment': instance.equipment,
      'inventory': instance.inventory,
      'stash': instance.stash,
      'skills': instance.skills,
      'skillSlots': instance.skillSlots,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastPlayed': instance.lastPlayed.toIso8601String(),
      'characterData': instance.characterData,
    };
