// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_system.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SkillRequirement _$SkillRequirementFromJson(Map<String, dynamic> json) =>
    SkillRequirement(
      prerequisiteSkillId: json['prerequisiteSkillId'] as String?,
      minimumLevel: (json['minimumLevel'] as num?)?.toInt() ?? 1,
      minimumSkillPoints: (json['minimumSkillPoints'] as num?)?.toInt() ?? 0,
      attributeRequirements:
          (json['attributeRequirements'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ),
      requiredAchievements: (json['requiredAchievements'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      otherRequirements: json['otherRequirements'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$SkillRequirementToJson(SkillRequirement instance) =>
    <String, dynamic>{
      'prerequisiteSkillId': instance.prerequisiteSkillId,
      'minimumLevel': instance.minimumLevel,
      'minimumSkillPoints': instance.minimumSkillPoints,
      'attributeRequirements': instance.attributeRequirements,
      'requiredAchievements': instance.requiredAchievements,
      'otherRequirements': instance.otherRequirements,
    };

SkillEffect _$SkillEffectFromJson(Map<String, dynamic> json) => SkillEffect(
      type: json['type'] as String,
      value: (json['value'] as num).toDouble(),
      target: json['target'] as String,
      duration: (json['duration'] as num?)?.toInt() ?? -1,
      parameters: json['parameters'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$SkillEffectToJson(SkillEffect instance) =>
    <String, dynamic>{
      'type': instance.type,
      'value': instance.value,
      'target': instance.target,
      'duration': instance.duration,
      'parameters': instance.parameters,
    };

Skill _$SkillFromJson(Map<String, dynamic> json) => Skill(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String,
      school: $enumDecode(_$SkillSchoolEnumMap, json['school']),
      type: $enumDecode(_$SkillTypeEnumMap, json['type']),
      tier: $enumDecode(_$SkillTierEnumMap, json['tier']),
      maxRank: (json['maxRank'] as num?)?.toInt() ?? 5,
      currentRank: (json['currentRank'] as num?)?.toInt() ?? 0,
      requirements: json['requirements'] == null
          ? null
          : SkillRequirement.fromJson(
              json['requirements'] as Map<String, dynamic>),
      effects: (json['effects'] as List<dynamic>?)
          ?.map((e) => SkillEffect.fromJson(e as Map<String, dynamic>))
          .toList(),
      manaCost: (json['manaCost'] as num?)?.toInt() ?? 0,
      cooldown: (json['cooldown'] as num?)?.toInt() ?? 0,
      iconUrl: json['iconUrl'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$SkillToJson(Skill instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'school': _$SkillSchoolEnumMap[instance.school]!,
      'type': _$SkillTypeEnumMap[instance.type]!,
      'tier': _$SkillTierEnumMap[instance.tier]!,
      'maxRank': instance.maxRank,
      'currentRank': instance.currentRank,
      'requirements': instance.requirements,
      'effects': instance.effects,
      'manaCost': instance.manaCost,
      'cooldown': instance.cooldown,
      'iconUrl': instance.iconUrl,
      'metadata': instance.metadata,
    };

const _$SkillSchoolEnumMap = {
  SkillSchool.combat: 'combat',
  SkillSchool.elementalism: 'elementalism',
  SkillSchool.restoration: 'restoration',
  SkillSchool.shadow: 'shadow',
  SkillSchool.nature: 'nature',
  SkillSchool.fitness: 'fitness',
  SkillSchool.social: 'social',
  SkillSchool.crafting: 'crafting',
  SkillSchool.exploration: 'exploration',
};

const _$SkillTypeEnumMap = {
  SkillType.passive: 'passive',
  SkillType.active: 'active',
  SkillType.toggle: 'toggle',
  SkillType.ultimate: 'ultimate',
};

const _$SkillTierEnumMap = {
  SkillTier.novice: 'novice',
  SkillTier.apprentice: 'apprentice',
  SkillTier.adept: 'adept',
  SkillTier.expert: 'expert',
  SkillTier.master: 'master',
  SkillTier.grandmaster: 'grandmaster',
};

SkillTree _$SkillTreeFromJson(Map<String, dynamic> json) => SkillTree(
      school: $enumDecode(_$SkillSchoolEnumMap, json['school']),
      name: json['name'] as String,
      description: json['description'] as String,
      skills: (json['skills'] as List<dynamic>?)
          ?.map((e) => Skill.fromJson(e as Map<String, dynamic>))
          .toList(),
      connections: (json['connections'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      ),
      schoolBonuses: json['schoolBonuses'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$SkillTreeToJson(SkillTree instance) => <String, dynamic>{
      'school': _$SkillSchoolEnumMap[instance.school]!,
      'name': instance.name,
      'description': instance.description,
      'skills': instance.skills,
      'connections': instance.connections,
      'schoolBonuses': instance.schoolBonuses,
    };
