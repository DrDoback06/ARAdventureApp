import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'card_model.dart';

part 'character_model.g.dart';

@JsonSerializable()
class Equipment {
  final CardInstance? helmet;
  final CardInstance? armor;
  final CardInstance? weapon1;
  final CardInstance? weapon2;
  final CardInstance? gloves;
  final CardInstance? boots;
  final CardInstance? belt;
  final CardInstance? ring1;
  final CardInstance? ring2;
  final CardInstance? amulet;

  Equipment({
    this.helmet,
    this.armor,
    this.weapon1,
    this.weapon2,
    this.gloves,
    this.boots,
    this.belt,
    this.ring1,
    this.ring2,
    this.amulet,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) =>
      _$EquipmentFromJson(json);
  Map<String, dynamic> toJson() => _$EquipmentToJson(this);

  Equipment copyWith({
    CardInstance? helmet,
    CardInstance? armor,
    CardInstance? weapon1,
    CardInstance? weapon2,
    CardInstance? gloves,
    CardInstance? boots,
    CardInstance? belt,
    CardInstance? ring1,
    CardInstance? ring2,
    CardInstance? amulet,
  }) {
    return Equipment(
      helmet: helmet ?? this.helmet,
      armor: armor ?? this.armor,
      weapon1: weapon1 ?? this.weapon1,
      weapon2: weapon2 ?? this.weapon2,
      gloves: gloves ?? this.gloves,
      boots: boots ?? this.boots,
      belt: belt ?? this.belt,
      ring1: ring1 ?? this.ring1,
      ring2: ring2 ?? this.ring2,
      amulet: amulet ?? this.amulet,
    );
  }

  List<CardInstance> getAllEquippedItems() {
    return [
      helmet,
      armor,
      weapon1,
      weapon2,
      gloves,
      boots,
      belt,
      ring1,
      ring2,
      amulet,
    ].where((item) => item != null).cast<CardInstance>().toList();
  }

  CardInstance? getItemInSlot(EquipmentSlot slot) {
    switch (slot) {
      case EquipmentSlot.helmet:
        return helmet;
      case EquipmentSlot.armor:
        return armor;
      case EquipmentSlot.weapon1:
        return weapon1;
      case EquipmentSlot.weapon2:
        return weapon2;
      case EquipmentSlot.gloves:
        return gloves;
      case EquipmentSlot.boots:
        return boots;
      case EquipmentSlot.belt:
        return belt;
      case EquipmentSlot.ring1:
        return ring1;
      case EquipmentSlot.ring2:
        return ring2;
      case EquipmentSlot.amulet:
        return amulet;
      default:
        return null;
    }
  }
}

@JsonSerializable()
class Skill {
  final String id;
  final String name;
  final String description;
  final int level;
  final int maxLevel;
  final CharacterClass requiredClass;
  final List<String> prerequisites;
  final List<StatModifier> bonuses;
  final String iconUrl;

  Skill({
    String? id,
    required this.name,
    required this.description,
    this.level = 0,
    this.maxLevel = 20,
    required this.requiredClass,
    List<String>? prerequisites,
    List<StatModifier>? bonuses,
    this.iconUrl = '',
  })  : id = id ?? const Uuid().v4(),
        prerequisites = prerequisites ?? <String>[],
        bonuses = bonuses ?? <StatModifier>[];

  factory Skill.fromJson(Map<String, dynamic> json) => _$SkillFromJson(json);
  Map<String, dynamic> toJson() => _$SkillToJson(this);

  Skill copyWith({
    String? id,
    String? name,
    String? description,
    int? level,
    int? maxLevel,
    CharacterClass? requiredClass,
    List<String>? prerequisites,
    List<StatModifier>? bonuses,
    String? iconUrl,
  }) {
    return Skill(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      level: level ?? this.level,
      maxLevel: maxLevel ?? this.maxLevel,
      requiredClass: requiredClass ?? this.requiredClass,
      prerequisites: prerequisites ?? this.prerequisites,
      bonuses: bonuses ?? this.bonuses,
      iconUrl: iconUrl ?? this.iconUrl,
    );
  }
}

@JsonSerializable()
class GameCharacter {
  final String id;
  final String name;
  final CharacterClass characterClass;
  final int level;
  final int experience;
  final int experienceToNext;
  
  // Core Diablo II stats
  final int baseStrength;
  final int baseDexterity;
  final int baseVitality;
  final int baseEnergy;
  
  // Allocated stat points
  final int allocatedStrength;
  final int allocatedDexterity;
  final int allocatedVitality;
  final int allocatedEnergy;
  
  // Available points
  final int availableStatPoints;
  final int availableSkillPoints;
  
  final Equipment equipment;
  final List<CardInstance> inventory;
  final List<CardInstance> stash;
  final List<Skill> skills;
  final List<CardInstance> skillSlots;
  
  final int gold;
  final DateTime createdAt;
  final DateTime lastPlayed;
  final Map<String, dynamic> characterData;

  GameCharacter({
    String? id,
    required this.name,
    required this.characterClass,
    this.level = 1,
    this.experience = 0,
    int? experienceToNext,
    this.baseStrength = 10,
    this.baseDexterity = 10,
    this.baseVitality = 10,
    this.baseEnergy = 10,
    this.allocatedStrength = 0,
    this.allocatedDexterity = 0,
    this.allocatedVitality = 0,
    this.allocatedEnergy = 0,
    this.availableStatPoints = 0,
    this.availableSkillPoints = 0,
    Equipment? equipment,
    List<CardInstance>? inventory,
    List<CardInstance>? stash,
    List<Skill>? skills,
    List<CardInstance>? skillSlots,
    int? gold,
    DateTime? createdAt,
    DateTime? lastPlayed,
    Map<String, dynamic>? characterData,
  })  : id = id ?? const Uuid().v4(),
        experienceToNext = experienceToNext ?? _calculateExperienceToNext(level),
        equipment = equipment ?? Equipment(),
        inventory = inventory ?? <CardInstance>[],
        stash = stash ?? <CardInstance>[],
        skills = skills ?? <Skill>[],
        skillSlots = skillSlots ?? <CardInstance>[],
        gold = gold ?? 0,
        createdAt = createdAt ?? DateTime.now(),
        lastPlayed = lastPlayed ?? DateTime.now(),
        characterData = characterData ?? <String, dynamic>{};

  static int _calculateExperienceToNext(int level) {
    return level * 1000; // Simple formula, can be made more complex
  }

  factory GameCharacter.fromJson(Map<String, dynamic> json) =>
      _$GameCharacterFromJson(json);
  Map<String, dynamic> toJson() => _$GameCharacterToJson(this);

  // Calculated stats including equipment bonuses
  int get totalStrength {
    int total = baseStrength + allocatedStrength;
    for (var item in equipment.getAllEquippedItems()) {
      for (var modifier in item.card.statModifiers) {
        if (modifier.statName.toLowerCase() == 'strength') {
          total += modifier.isPercentage 
              ? ((baseStrength + allocatedStrength) * modifier.value / 100).round()
              : modifier.value;
        }
      }
    }
    return total;
  }

  int get totalDexterity {
    int total = baseDexterity + allocatedDexterity;
    for (var item in equipment.getAllEquippedItems()) {
      for (var modifier in item.card.statModifiers) {
        if (modifier.statName.toLowerCase() == 'dexterity') {
          total += modifier.isPercentage 
              ? ((baseDexterity + allocatedDexterity) * modifier.value / 100).round()
              : modifier.value;
        }
      }
    }
    return total;
  }

  int get totalVitality {
    int total = baseVitality + allocatedVitality;
    for (var item in equipment.getAllEquippedItems()) {
      for (var modifier in item.card.statModifiers) {
        if (modifier.statName.toLowerCase() == 'vitality') {
          total += modifier.isPercentage 
              ? ((baseVitality + allocatedVitality) * modifier.value / 100).round()
              : modifier.value;
        }
      }
    }
    return total;
  }

  int get totalEnergy {
    int total = baseEnergy + allocatedEnergy;
    for (var item in equipment.getAllEquippedItems()) {
      for (var modifier in item.card.statModifiers) {
        if (modifier.statName.toLowerCase() == 'energy') {
          total += modifier.isPercentage 
              ? ((baseEnergy + allocatedEnergy) * modifier.value / 100).round()
              : modifier.value;
        }
      }
    }
    return total;
  }

  // Battle system properties
  int get maxHealth => (totalVitality * 10) + 100;
  int get attack => totalStrength * 2;
  List<CardInstance> get equippedItems => equipment.getAllEquippedItems();

  int get maxMana {
    int base = 30 + (level * 5);
    int energyBonus = totalEnergy * 2;
    int equipmentBonus = 0;
    
    for (var item in equipment.getAllEquippedItems()) {
      for (var modifier in item.card.statModifiers) {
        if (modifier.statName.toLowerCase() == 'mana') {
          equipmentBonus += modifier.isPercentage 
              ? ((base + energyBonus) * modifier.value / 100).round()
              : modifier.value;
        }
      }
    }
    
    return base + energyBonus + equipmentBonus;
  }

  int get attackRating {
    int base = level * 5;
    int dexterityBonus = totalDexterity;
    int equipmentBonus = 0;
    
    for (var item in equipment.getAllEquippedItems()) {
      for (var modifier in item.card.statModifiers) {
        if (modifier.statName.toLowerCase() == 'attack' || 
            modifier.statName.toLowerCase() == 'accuracy') {
          equipmentBonus += modifier.isPercentage 
              ? ((base + dexterityBonus) * modifier.value / 100).round()
              : modifier.value;
        }
      }
    }
    
    return base + dexterityBonus + equipmentBonus;
  }

  int get defense {
    int base = level * 2;
    int dexterityBonus = totalDexterity ~/ 4;
    int equipmentBonus = 0;
    
    for (var item in equipment.getAllEquippedItems()) {
      for (var modifier in item.card.statModifiers) {
        if (modifier.statName.toLowerCase() == 'defense' || 
            modifier.statName.toLowerCase() == 'armor') {
          equipmentBonus += modifier.isPercentage 
              ? ((base + dexterityBonus) * modifier.value / 100).round()
              : modifier.value;
        }
      }
    }
    
    return base + dexterityBonus + equipmentBonus;
  }

  GameCharacter copyWith({
    String? id,
    String? name,
    CharacterClass? characterClass,
    int? level,
    int? experience,
    int? experienceToNext,
    int? baseStrength,
    int? baseDexterity,
    int? baseVitality,
    int? baseEnergy,
    int? allocatedStrength,
    int? allocatedDexterity,
    int? allocatedVitality,
    int? allocatedEnergy,
    int? availableStatPoints,
    int? availableSkillPoints,
    Equipment? equipment,
    List<CardInstance>? inventory,
    List<CardInstance>? stash,
    List<Skill>? skills,
    List<CardInstance>? skillSlots,
    int? gold,
    DateTime? createdAt,
    DateTime? lastPlayed,
    Map<String, dynamic>? characterData,
  }) {
    return GameCharacter(
      id: id ?? this.id,
      name: name ?? this.name,
      characterClass: characterClass ?? this.characterClass,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      experienceToNext: experienceToNext ?? this.experienceToNext,
      baseStrength: baseStrength ?? this.baseStrength,
      baseDexterity: baseDexterity ?? this.baseDexterity,
      baseVitality: baseVitality ?? this.baseVitality,
      baseEnergy: baseEnergy ?? this.baseEnergy,
      allocatedStrength: allocatedStrength ?? this.allocatedStrength,
      allocatedDexterity: allocatedDexterity ?? this.allocatedDexterity,
      allocatedVitality: allocatedVitality ?? this.allocatedVitality,
      allocatedEnergy: allocatedEnergy ?? this.allocatedEnergy,
      availableStatPoints: availableStatPoints ?? this.availableStatPoints,
      availableSkillPoints: availableSkillPoints ?? this.availableSkillPoints,
      equipment: equipment ?? this.equipment,
      inventory: inventory ?? this.inventory,
      stash: stash ?? this.stash,
      skills: skills ?? this.skills,
      skillSlots: skillSlots ?? this.skillSlots,
      gold: gold ?? this.gold,
      createdAt: createdAt ?? this.createdAt,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      characterData: characterData ?? this.characterData,
    );
  }
}