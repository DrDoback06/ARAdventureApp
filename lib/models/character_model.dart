import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'card_model.dart';

part 'character_model.g.dart';

/// Represents a skill in the character's skill tree
@JsonSerializable()
class Skill {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final int level;
  final int maxLevel;
  final int pointsInvested;
  final List<String> prerequisites; // Required skill IDs
  final List<StatModifier> bonuses; // Stat bonuses this skill provides
  final List<CardEffect> effects; // Effects this skill can trigger
  final String skillTree; // Which tree this skill belongs to
  
  const Skill({
    required this.id,
    required this.name,
    required this.description,
    this.iconUrl = '',
    this.level = 0,
    this.maxLevel = 20,
    this.pointsInvested = 0,
    this.prerequisites = const [],
    this.bonuses = const [],
    this.effects = const [],
    required this.skillTree,
  });
  
  factory Skill.fromJson(Map<String, dynamic> json) => _$SkillFromJson(json);
  Map<String, dynamic> toJson() => _$SkillToJson(this);
  
  /// Creates a copy with updated level/points
  Skill copyWith({
    int? level,
    int? pointsInvested,
  }) {
    return Skill(
      id: id,
      name: name,
      description: description,
      iconUrl: iconUrl,
      level: level ?? this.level,
      maxLevel: maxLevel,
      pointsInvested: pointsInvested ?? this.pointsInvested,
      prerequisites: prerequisites,
      bonuses: bonuses,
      effects: effects,
      skillTree: skillTree,
    );
  }
}

/// Represents the character's equipment setup
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
  final CardInstance? skill1; // Active skill slot 1
  final CardInstance? skill2; // Active skill slot 2
  
  const Equipment({
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
    this.skill1,
    this.skill2,
  });
  
  factory Equipment.fromJson(Map<String, dynamic> json) => _$EquipmentFromJson(json);
  Map<String, dynamic> toJson() => _$EquipmentToJson(this);
  
  /// Gets the card instance for a specific equipment slot
  CardInstance? getSlot(EquipmentSlot slot) {
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
      case EquipmentSlot.skill1:
        return skill1;
      case EquipmentSlot.skill2:
        return skill2;
      case EquipmentSlot.none:
        return null;
    }
  }
  
  /// Creates a copy with a new item equipped in the specified slot
  Equipment copyWithSlot(EquipmentSlot slot, CardInstance? item) {
    switch (slot) {
      case EquipmentSlot.helmet:
        return Equipment(
          helmet: item,
          armor: armor,
          weapon1: weapon1,
          weapon2: weapon2,
          gloves: gloves,
          boots: boots,
          belt: belt,
          ring1: ring1,
          ring2: ring2,
          amulet: amulet,
          skill1: skill1,
          skill2: skill2,
        );
      case EquipmentSlot.armor:
        return Equipment(
          helmet: helmet,
          armor: item,
          weapon1: weapon1,
          weapon2: weapon2,
          gloves: gloves,
          boots: boots,
          belt: belt,
          ring1: ring1,
          ring2: ring2,
          amulet: amulet,
          skill1: skill1,
          skill2: skill2,
        );
      case EquipmentSlot.weapon1:
        return Equipment(
          helmet: helmet,
          armor: armor,
          weapon1: item,
          weapon2: weapon2,
          gloves: gloves,
          boots: boots,
          belt: belt,
          ring1: ring1,
          ring2: ring2,
          amulet: amulet,
          skill1: skill1,
          skill2: skill2,
        );
      case EquipmentSlot.weapon2:
        return Equipment(
          helmet: helmet,
          armor: armor,
          weapon1: weapon1,
          weapon2: item,
          gloves: gloves,
          boots: boots,
          belt: belt,
          ring1: ring1,
          ring2: ring2,
          amulet: amulet,
          skill1: skill1,
          skill2: skill2,
        );
      case EquipmentSlot.gloves:
        return Equipment(
          helmet: helmet,
          armor: armor,
          weapon1: weapon1,
          weapon2: weapon2,
          gloves: item,
          boots: boots,
          belt: belt,
          ring1: ring1,
          ring2: ring2,
          amulet: amulet,
          skill1: skill1,
          skill2: skill2,
        );
      case EquipmentSlot.boots:
        return Equipment(
          helmet: helmet,
          armor: armor,
          weapon1: weapon1,
          weapon2: weapon2,
          gloves: gloves,
          boots: item,
          belt: belt,
          ring1: ring1,
          ring2: ring2,
          amulet: amulet,
          skill1: skill1,
          skill2: skill2,
        );
      case EquipmentSlot.belt:
        return Equipment(
          helmet: helmet,
          armor: armor,
          weapon1: weapon1,
          weapon2: weapon2,
          gloves: gloves,
          boots: boots,
          belt: item,
          ring1: ring1,
          ring2: ring2,
          amulet: amulet,
          skill1: skill1,
          skill2: skill2,
        );
      case EquipmentSlot.ring1:
        return Equipment(
          helmet: helmet,
          armor: armor,
          weapon1: weapon1,
          weapon2: weapon2,
          gloves: gloves,
          boots: boots,
          belt: belt,
          ring1: item,
          ring2: ring2,
          amulet: amulet,
          skill1: skill1,
          skill2: skill2,
        );
      case EquipmentSlot.ring2:
        return Equipment(
          helmet: helmet,
          armor: armor,
          weapon1: weapon1,
          weapon2: weapon2,
          gloves: gloves,
          boots: boots,
          belt: belt,
          ring1: ring1,
          ring2: item,
          amulet: amulet,
          skill1: skill1,
          skill2: skill2,
        );
      case EquipmentSlot.amulet:
        return Equipment(
          helmet: helmet,
          armor: armor,
          weapon1: weapon1,
          weapon2: weapon2,
          gloves: gloves,
          boots: boots,
          belt: belt,
          ring1: ring1,
          ring2: ring2,
          amulet: item,
          skill1: skill1,
          skill2: skill2,
        );
      case EquipmentSlot.skill1:
        return Equipment(
          helmet: helmet,
          armor: armor,
          weapon1: weapon1,
          weapon2: weapon2,
          gloves: gloves,
          boots: boots,
          belt: belt,
          ring1: ring1,
          ring2: ring2,
          amulet: amulet,
          skill1: item,
          skill2: skill2,
        );
      case EquipmentSlot.skill2:
        return Equipment(
          helmet: helmet,
          armor: armor,
          weapon1: weapon1,
          weapon2: weapon2,
          gloves: gloves,
          boots: boots,
          belt: belt,
          ring1: ring1,
          ring2: ring2,
          amulet: amulet,
          skill1: skill1,
          skill2: item,
        );
      case EquipmentSlot.none:
        return this;
    }
  }
  
  /// Gets all equipped items as a list
  List<CardInstance> getAllEquipped() {
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
      skill1,
      skill2,
    ].where((item) => item != null).cast<CardInstance>().toList();
  }
}

/// Main Character model - represents a player character
@JsonSerializable()
class GameCharacter {
  final String id;
  final String name;
  final CharacterClass characterClass;
  final String portraitUrl;
  
  // Core stats (like Diablo II)
  final int level;
  final int experience;
  final int experienceToNext;
  final int statPoints; // Available stat points to allocate
  final int skillPoints; // Available skill points to allocate
  
  // Base stats (before equipment/skill modifiers)
  final int baseStrength;
  final int baseDexterity;
  final int baseVitality;
  final int baseEnergy;
  
  // Derived stats (calculated from base stats + equipment + skills)
  final int currentHealth;
  final int maxHealth;
  final int currentMana;
  final int maxMana;
  final int attack;
  final int defense;
  final int accuracy;
  final int dodge;
  final int criticalChance;
  final int criticalDamage;
  
  // Equipment and inventory
  final Equipment equipment;
  final List<CardInstance> inventory; // Inventory items
  final List<CardInstance> stash; // Stash items
  final int inventorySize;
  final int stashSize;
  
  // Skills
  final Map<String, Skill> skills; // All available skills
  final List<String> skillTrees; // Available skill trees for this class
  
  // Game progress
  final int renownPoints;
  final List<String> completedQuests;
  final List<String> activeQuests;
  final Map<String, dynamic> gameFlags; // Various game state flags
  
  // Economy
  final int gold;
  final Map<String, int> currencies; // Other currencies
  
  // Metadata
  final DateTime createdAt;
  final DateTime? lastPlayed;
  final String playerId;
  
  GameCharacter({
    String? id,
    required this.name,
    required this.characterClass,
    this.portraitUrl = '',
    this.level = 1,
    this.experience = 0,
    this.experienceToNext = 100,
    this.statPoints = 0,
    this.skillPoints = 1,
    this.baseStrength = 10,
    this.baseDexterity = 10,
    this.baseVitality = 10,
    this.baseEnergy = 10,
    int? currentHealth,
    int? maxHealth,
    int? currentMana,
    int? maxMana,
    this.attack = 1,
    this.defense = 0,
    this.accuracy = 75,
    this.dodge = 5,
    this.criticalChance = 5,
    this.criticalDamage = 150,
    this.equipment = const Equipment(),
    this.inventory = const [],
    this.stash = const [],
    this.inventorySize = 40, // 8x5 grid like Diablo II
    this.stashSize = 48, // 8x6 grid
    this.skills = const {},
    List<String>? skillTrees,
    this.renownPoints = 0,
    this.completedQuests = const [],
    this.activeQuests = const [],
    this.gameFlags = const {},
    this.gold = 0,
    this.currencies = const {},
    DateTime? createdAt,
    this.lastPlayed,
    required this.playerId,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       skillTrees = skillTrees ?? _getDefaultSkillTrees(characterClass),
       maxHealth = maxHealth ?? _calculateMaxHealth(baseVitality, level),
       currentHealth = currentHealth ?? _calculateMaxHealth(baseVitality, level),
       maxMana = maxMana ?? _calculateMaxMana(baseEnergy, level),
       currentMana = currentMana ?? _calculateMaxMana(baseEnergy, level);
  
  factory GameCharacter.fromJson(Map<String, dynamic> json) => _$GameCharacterFromJson(json);
  Map<String, dynamic> toJson() => _$GameCharacterToJson(this);
  
  /// Gets the default skill trees for a character class
  static List<String> _getDefaultSkillTrees(CharacterClass characterClass) {
    switch (characterClass) {
      case CharacterClass.holy:
        return ['Divine', 'Protection', 'Healing'];
      case CharacterClass.chaos:
        return ['Destruction', 'Corruption', 'Summoning'];
      case CharacterClass.arcane:
        return ['Elemental', 'Enchantment', 'Manipulation'];
      case CharacterClass.all:
        return ['Universal'];
    }
  }
  
  /// Calculates max health based on vitality and level
  static int _calculateMaxHealth(int vitality, int level) {
    return 50 + (vitality * 2) + (level * 3);
  }
  
  /// Calculates max mana based on energy and level
  static int _calculateMaxMana(int energy, int level) {
    return 25 + (energy * 2) + (level * 2);
  }
  
  /// Gets the total strength including equipment bonuses
  int getTotalStrength() {
    int total = baseStrength;
    for (var item in equipment.getAllEquipped()) {
      for (var modifier in item.card.statModifiers) {
        if (modifier.statName == 'strength') {
          total += modifier.value;
        }
      }
    }
    return total;
  }
  
  /// Gets the total dexterity including equipment bonuses
  int getTotalDexterity() {
    int total = baseDexterity;
    for (var item in equipment.getAllEquipped()) {
      for (var modifier in item.card.statModifiers) {
        if (modifier.statName == 'dexterity') {
          total += modifier.value;
        }
      }
    }
    return total;
  }
  
  /// Gets the total vitality including equipment bonuses
  int getTotalVitality() {
    int total = baseVitality;
    for (var item in equipment.getAllEquipped()) {
      for (var modifier in item.card.statModifiers) {
        if (modifier.statName == 'vitality') {
          total += modifier.value;
        }
      }
    }
    return total;
  }
  
  /// Gets the total energy including equipment bonuses
  int getTotalEnergy() {
    int total = baseEnergy;
    for (var item in equipment.getAllEquipped()) {
      for (var modifier in item.card.statModifiers) {
        if (modifier.statName == 'energy') {
          total += modifier.value;
        }
      }
    }
    return total;
  }
  
  /// Gets the total attack including equipment bonuses
  int getTotalAttack() {
    int total = attack;
    
    // Add weapon damage
    if (equipment.weapon1 != null) {
      total += equipment.weapon1!.card.getTotalAttack();
    }
    if (equipment.weapon2 != null) {
      total += equipment.weapon2!.card.getTotalAttack();
    }
    
    // Add other equipment bonuses
    for (var item in equipment.getAllEquipped()) {
      for (var modifier in item.card.statModifiers) {
        if (modifier.statName == 'attack') {
          total += modifier.value;
        }
      }
    }
    
    return total;
  }
  
  /// Gets the total defense including equipment bonuses
  int getTotalDefense() {
    int total = defense;
    
    // Add armor defense
    if (equipment.armor != null) {
      total += equipment.armor!.card.getTotalDefense();
    }
    
    // Add other equipment bonuses
    for (var item in equipment.getAllEquipped()) {
      for (var modifier in item.card.statModifiers) {
        if (modifier.statName == 'defense') {
          total += modifier.value;
        }
      }
    }
    
    return total;
  }
  
  /// Calculates the actual max health including equipment and skill bonuses
  int getActualMaxHealth() {
    int totalVitality = getTotalVitality();
    int baseHealth = _calculateMaxHealth(totalVitality, level);
    
    // Add equipment health bonuses
    for (var item in equipment.getAllEquipped()) {
      for (var modifier in item.card.statModifiers) {
        if (modifier.statName == 'health') {
          baseHealth += modifier.value;
        }
      }
    }
    
    return baseHealth;
  }
  
  /// Calculates the actual max mana including equipment and skill bonuses
  int getActualMaxMana() {
    int totalEnergy = getTotalEnergy();
    int baseMana = _calculateMaxMana(totalEnergy, level);
    
    // Add equipment mana bonuses
    for (var item in equipment.getAllEquipped()) {
      for (var modifier in item.card.statModifiers) {
        if (modifier.statName == 'mana') {
          baseMana += modifier.value;
        }
      }
    }
    
    return baseMana;
  }
  
  /// Checks if the character can equip a specific item
  bool canEquip(CardInstance item) {
    // Check class restrictions
    if (!item.card.canBeUsedByClass(characterClass)) {
      return false;
    }
    
    // Check stat requirements
    for (var condition in item.card.conditions) {
      if (condition.conditionType == 'stat') {
        int currentStat = 0;
        switch (condition.conditionKey) {
          case 'strength':
            currentStat = getTotalStrength();
            break;
          case 'dexterity':
            currentStat = getTotalDexterity();
            break;
          case 'vitality':
            currentStat = getTotalVitality();
            break;
          case 'energy':
            currentStat = getTotalEnergy();
            break;
          case 'level':
            currentStat = level;
            break;
        }
        
        if (!_checkCondition(currentStat, condition.conditionValue, condition.operator)) {
          return false;
        }
      }
    }
    
    return true;
  }
  
  /// Helper method to check if a condition is met
  bool _checkCondition(dynamic currentValue, dynamic requiredValue, String operator) {
    switch (operator) {
      case '>=':
        return currentValue >= requiredValue;
      case '>':
        return currentValue > requiredValue;
      case '<=':
        return currentValue <= requiredValue;
      case '<':
        return currentValue < requiredValue;
      case '==':
        return currentValue == requiredValue;
      case '!=':
        return currentValue != requiredValue;
      default:
        return false;
    }
  }
  
  /// Creates a copy of the character with updated equipment
  GameCharacter copyWithEquipment(Equipment newEquipment) {
    return GameCharacter(
      id: id,
      name: name,
      characterClass: characterClass,
      portraitUrl: portraitUrl,
      level: level,
      experience: experience,
      experienceToNext: experienceToNext,
      statPoints: statPoints,
      skillPoints: skillPoints,
      baseStrength: baseStrength,
      baseDexterity: baseDexterity,
      baseVitality: baseVitality,
      baseEnergy: baseEnergy,
      currentHealth: currentHealth,
      maxHealth: maxHealth,
      currentMana: currentMana,
      maxMana: maxMana,
      attack: attack,
      defense: defense,
      accuracy: accuracy,
      dodge: dodge,
      criticalChance: criticalChance,
      criticalDamage: criticalDamage,
      equipment: newEquipment,
      inventory: inventory,
      stash: stash,
      inventorySize: inventorySize,
      stashSize: stashSize,
      skills: skills,
      skillTrees: skillTrees,
      renownPoints: renownPoints,
      completedQuests: completedQuests,
      activeQuests: activeQuests,
      gameFlags: gameFlags,
      gold: gold,
      currencies: currencies,
      createdAt: createdAt,
      lastPlayed: DateTime.now(),
      playerId: playerId,
    );
  }
  
  /// Creates a copy with updated inventory
  GameCharacter copyWithInventory(List<CardInstance> newInventory) {
    return GameCharacter(
      id: id,
      name: name,
      characterClass: characterClass,
      portraitUrl: portraitUrl,
      level: level,
      experience: experience,
      experienceToNext: experienceToNext,
      statPoints: statPoints,
      skillPoints: skillPoints,
      baseStrength: baseStrength,
      baseDexterity: baseDexterity,
      baseVitality: baseVitality,
      baseEnergy: baseEnergy,
      currentHealth: currentHealth,
      maxHealth: maxHealth,
      currentMana: currentMana,
      maxMana: maxMana,
      attack: attack,
      defense: defense,
      accuracy: accuracy,
      dodge: dodge,
      criticalChance: criticalChance,
      criticalDamage: criticalDamage,
      equipment: equipment,
      inventory: newInventory,
      stash: stash,
      inventorySize: inventorySize,
      stashSize: stashSize,
      skills: skills,
      skillTrees: skillTrees,
      renownPoints: renownPoints,
      completedQuests: completedQuests,
      activeQuests: activeQuests,
      gameFlags: gameFlags,
      gold: gold,
      currencies: currencies,
      createdAt: createdAt,
      lastPlayed: DateTime.now(),
      playerId: playerId,
    );
  }
}