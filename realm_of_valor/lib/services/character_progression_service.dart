import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/character_model.dart';

// Enums for the comprehensive skill system
enum CharacterClass {
  barbarian,
  sorcerer,
  paladin,
  assassin,
  druid,
  necromancer,
  amazon,
  monk,
}

enum SkillTreeType {
  combat,      // Barbarian, Amazon, Monk
  berserker,   // Barbarian
  magic,       // Sorcerer, Necromancer
  elemental,   // Sorcerer
  holy,        // Paladin
  protection,  // Paladin
  shadow,      // Assassin
  stealth,     // Assassin
  nature,      // Druid
  shapeshifting, // Druid
  death,       // Necromancer
  summoning,   // Necromancer
  archery,     // Amazon
  javelin,     // Amazon
  martial,     // Monk
  meditation,  // Monk
  
  // Shared basic tree
  basic,
  survival,
  social,
  crafting,
}

enum SkillTier {
  basic,
  intermediate,
  advanced,
  master,
  legendary,
}

class Skill {
  final String id;
  final String name;
  final String description;
  final SkillTreeType treeType;
  final SkillTier tier;
  final int maxLevel;
  final int requiredLevel;
  final List<String> prerequisites;
  final Map<String, dynamic> effects;
  final int skillPointCost;
  final String? icon;

  const Skill({
    required this.id,
    required this.name,
    required this.description,
    required this.treeType,
    required this.tier,
    required this.maxLevel,
    required this.requiredLevel,
    required this.prerequisites,
    required this.effects,
    required this.skillPointCost,
    this.icon,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'treeType': treeType.name,
      'tier': tier.name,
      'maxLevel': maxLevel,
      'requiredLevel': requiredLevel,
      'prerequisites': prerequisites,
      'effects': effects,
      'skillPointCost': skillPointCost,
      'icon': icon,
    };
  }

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      treeType: SkillTreeType.values.firstWhere(
        (e) => e.name == json['treeType'],
      ),
      tier: SkillTier.values.firstWhere(
        (e) => e.name == json['tier'],
      ),
      maxLevel: json['maxLevel'] as int,
      requiredLevel: json['requiredLevel'] as int,
      prerequisites: List<String>.from(json['prerequisites'] as List),
      effects: Map<String, dynamic>.from(json['effects'] as Map),
      skillPointCost: json['skillPointCost'] as int,
      icon: json['icon'] as String?,
    );
  }
}

class SkillNode {
  final String id;
  final Skill skill;
  final int currentLevel;
  final bool isUnlocked;
  final bool isMaxed;
  final List<String> connectedNodes;

  const SkillNode({
    required this.id,
    required this.skill,
    this.currentLevel = 0,
    this.isUnlocked = false,
    this.isMaxed = false,
    required this.connectedNodes,
  });

  SkillNode copyWith({
    int? currentLevel,
    bool? isUnlocked,
    bool? isMaxed,
  }) {
    return SkillNode(
      id: id,
      skill: skill,
      currentLevel: currentLevel ?? this.currentLevel,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isMaxed: isMaxed ?? this.isMaxed,
      connectedNodes: connectedNodes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'skill': skill.toJson(),
      'currentLevel': currentLevel,
      'isUnlocked': isUnlocked,
      'isMaxed': isMaxed,
      'connectedNodes': connectedNodes,
    };
  }

  factory SkillNode.fromJson(Map<String, dynamic> json) {
    return SkillNode(
      id: json['id'] as String,
      skill: Skill.fromJson(Map<String, dynamic>.from(json['skill'] as Map)),
      currentLevel: json['currentLevel'] as int? ?? 0,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      isMaxed: json['isMaxed'] as bool? ?? false,
      connectedNodes: List<String>.from(json['connectedNodes'] as List),
    );
  }
}

class CharacterProgressionService extends ChangeNotifier {
  static CharacterProgressionService? _instance;
  static CharacterProgressionService get instance => _instance ??= CharacterProgressionService._();
  CharacterProgressionService._();

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // Skill tree data
  final Map<String, Skill> _skills = {};
  final Map<String, SkillNode> _skillNodes = {};
  final Map<String, int> _skillLevels = {};
  final Map<String, bool> _skillUnlocks = {};
  int _availableSkillPoints = 0;

  // Getters
  Map<String, Skill> get skills => Map.unmodifiable(_skills);
  Map<String, SkillNode> get skillNodes => Map.unmodifiable(_skillNodes);
  Map<String, int> get skillLevels => Map.unmodifiable(_skillLevels);
  Map<String, bool> get skillUnlocks => Map.unmodifiable(_skillUnlocks);
  int get availableSkillPoints => _availableSkillPoints;

  // Initialize service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    await _loadProgressionData();
    _initializeSkills();
    _isInitialized = true;
    notifyListeners();
  }

  // Load progression data from preferences
  Future<void> _loadProgressionData() async {
    final skillLevelsList = _prefs.getStringList('progression_skill_levels') ?? [];
    for (final levelStr in skillLevelsList) {
      final parts = levelStr.split(':');
      if (parts.length == 2) {
        final skillId = parts[0];
        final level = int.tryParse(parts[1]) ?? 0;
        _skillLevels[skillId] = level;
      }
    }

    final skillUnlocksList = _prefs.getStringList('progression_skill_unlocks') ?? [];
    for (final unlockStr in skillUnlocksList) {
      _skillUnlocks[unlockStr] = true;
    }

    _availableSkillPoints = _prefs.getInt('progression_skill_points') ?? 0;
  }

  // Save progression data to preferences
  Future<void> _saveProgressionData() async {
    final skillLevelsList = _skillLevels.entries
        .map((entry) => '${entry.key}:${entry.value}')
        .toList();
    await _prefs.setStringList('progression_skill_levels', skillLevelsList);

    final skillUnlocksList = _skillUnlocks.keys.toList();
    await _prefs.setStringList('progression_skill_unlocks', skillUnlocksList);

    await _prefs.setInt('progression_skill_points', _availableSkillPoints);
  }

  // Add skill to the service
  void _addSkill(Skill skill) {
    _skills[skill.id] = skill;
  }

  // Initialize all skills
  void _initializeSkills() {
    _initializeBasicSkills();
    _initializeClassSpecificSkills();
  }

  // Initialize basic skills available to all classes
  void _initializeBasicSkills() {
    // Combat Skills
    _addSkill(Skill(
      id: 'sword_mastery',
      name: 'Sword Mastery',
      description: 'Increases damage with swords and reduces cooldown',
      treeType: SkillTreeType.combat,
      tier: SkillTier.basic,
      maxLevel: 5,
      requiredLevel: 1,
      prerequisites: [],
      effects: {
        'damage_bonus': 10,
        'cooldown_reduction': 5,
      },
      skillPointCost: 1,
    ));

    _addSkill(Skill(
      id: 'critical_strike',
      name: 'Critical Strike',
      description: 'Increases critical hit chance and damage',
      treeType: SkillTreeType.combat,
      tier: SkillTier.intermediate,
      maxLevel: 3,
      requiredLevel: 5,
      prerequisites: ['sword_mastery'],
      effects: {
        'crit_chance': 5,
        'crit_damage': 15,
      },
      skillPointCost: 2,
    ));

    _addSkill(Skill(
      id: 'battle_tactics',
      name: 'Battle Tactics',
      description: 'Advanced combat techniques and positioning',
      treeType: SkillTreeType.combat,
      tier: SkillTier.advanced,
      maxLevel: 3,
      requiredLevel: 10,
      prerequisites: ['critical_strike'],
      effects: {
        'dodge_chance': 8,
        'counter_chance': 10,
      },
      skillPointCost: 3,
    ));

    // Magic Skills
    _addSkill(Skill(
      id: 'fire_magic',
      name: 'Fire Magic',
      description: 'Unlock fire-based spells and abilities',
      treeType: SkillTreeType.magic,
      tier: SkillTier.basic,
      maxLevel: 5,
      requiredLevel: 1,
      prerequisites: [],
      effects: {
        'fire_damage': 20,
        'mana_efficiency': 10,
      },
      skillPointCost: 1,
    ));

    _addSkill(Skill(
      id: 'ice_magic',
      name: 'Ice Magic',
      description: 'Unlock ice-based spells and crowd control',
      treeType: SkillTreeType.magic,
      tier: SkillTier.intermediate,
      maxLevel: 3,
      requiredLevel: 5,
      prerequisites: ['fire_magic'],
      effects: {
        'ice_damage': 15,
        'slow_duration': 2,
      },
      skillPointCost: 2,
    ));

    _addSkill(Skill(
      id: 'arcane_mastery',
      name: 'Arcane Mastery',
      description: 'Master of all magical elements',
      treeType: SkillTreeType.magic,
      tier: SkillTier.master,
      maxLevel: 1,
      requiredLevel: 15,
      prerequisites: ['ice_magic'],
      effects: {
        'all_magic_damage': 25,
        'spell_critical_chance': 10,
      },
      skillPointCost: 5,
    ));

    // Survival Skills
    _addSkill(Skill(
      id: 'health_regeneration',
      name: 'Health Regeneration',
      description: 'Increases health regeneration rate',
      treeType: SkillTreeType.survival,
      tier: SkillTier.basic,
      maxLevel: 5,
      requiredLevel: 1,
      prerequisites: [],
      effects: {
        'health_regen': 2,
        'max_health': 20,
      },
      skillPointCost: 1,
    ));

    _addSkill(Skill(
      id: 'toughness',
      name: 'Toughness',
      description: 'Increases damage resistance and armor',
      treeType: SkillTreeType.survival,
      tier: SkillTier.intermediate,
      maxLevel: 3,
      requiredLevel: 5,
      prerequisites: ['health_regeneration'],
      effects: {
        'damage_resistance': 8,
        'armor_bonus': 15,
      },
      skillPointCost: 2,
    ));

    _addSkill(Skill(
      id: 'immortality',
      name: 'Immortality',
      description: 'Chance to survive fatal damage',
      treeType: SkillTreeType.survival,
      tier: SkillTier.legendary,
      maxLevel: 1,
      requiredLevel: 20,
      prerequisites: ['toughness'],
      effects: {
        'survival_chance': 10,
        'revival_health': 50,
      },
      skillPointCost: 10,
    ));

    // Social Skills
    _addSkill(Skill(
      id: 'charisma',
      name: 'Charisma',
      description: 'Improves social interactions and trading',
      treeType: SkillTreeType.social,
      tier: SkillTier.basic,
      maxLevel: 5,
      requiredLevel: 1,
      prerequisites: [],
      effects: {
        'trade_bonus': 10,
        'reputation_gain': 15,
      },
      skillPointCost: 1,
    ));

    _addSkill(Skill(
      id: 'leadership',
      name: 'Leadership',
      description: 'Guild bonuses and team coordination',
      treeType: SkillTreeType.social,
      tier: SkillTier.advanced,
      maxLevel: 3,
      requiredLevel: 10,
      prerequisites: ['charisma'],
      effects: {
        'guild_bonus': 20,
        'team_coordination': 15,
      },
      skillPointCost: 3,
    ));

    // Crafting Skills
    _addSkill(Skill(
      id: 'weapon_crafting',
      name: 'Weapon Crafting',
      description: 'Craft and enhance weapons',
      treeType: SkillTreeType.crafting,
      tier: SkillTier.basic,
      maxLevel: 5,
      requiredLevel: 1,
      prerequisites: [],
      effects: {
        'crafting_quality': 10,
        'material_efficiency': 15,
      },
      skillPointCost: 1,
    ));

    _addSkill(Skill(
      id: 'armor_crafting',
      name: 'Armor Crafting',
      description: 'Craft and enhance armor pieces',
      treeType: SkillTreeType.crafting,
      tier: SkillTier.intermediate,
      maxLevel: 3,
      requiredLevel: 5,
      prerequisites: ['weapon_crafting'],
      effects: {
        'armor_quality': 15,
        'defense_bonus': 10,
      },
      skillPointCost: 2,
    ));

    // Initialize skill nodes
    _initializeSkillNodes();
  }

  // Initialize skill nodes with connections
  void _initializeSkillNodes() {
    // Combat tree
    _skillNodes['sword_mastery'] = SkillNode(
      id: 'sword_mastery',
      skill: _skills['sword_mastery']!,
      connectedNodes: ['critical_strike'],
    );

    _skillNodes['critical_strike'] = SkillNode(
      id: 'critical_strike',
      skill: _skills['critical_strike']!,
      connectedNodes: ['sword_mastery', 'battle_tactics'],
    );

    _skillNodes['battle_tactics'] = SkillNode(
      id: 'battle_tactics',
      skill: _skills['battle_tactics']!,
      connectedNodes: ['critical_strike'],
    );

    // Magic tree
    _skillNodes['fire_magic'] = SkillNode(
      id: 'fire_magic',
      skill: _skills['fire_magic']!,
      connectedNodes: ['ice_magic'],
    );

    _skillNodes['ice_magic'] = SkillNode(
      id: 'ice_magic',
      skill: _skills['ice_magic']!,
      connectedNodes: ['fire_magic', 'arcane_mastery'],
    );

    _skillNodes['arcane_mastery'] = SkillNode(
      id: 'arcane_mastery',
      skill: _skills['arcane_mastery']!,
      connectedNodes: ['ice_magic'],
    );

    // Survival tree
    _skillNodes['health_regeneration'] = SkillNode(
      id: 'health_regeneration',
      skill: _skills['health_regeneration']!,
      connectedNodes: ['toughness'],
    );

    _skillNodes['toughness'] = SkillNode(
      id: 'toughness',
      skill: _skills['toughness']!,
      connectedNodes: ['health_regeneration', 'immortality'],
    );

    _skillNodes['immortality'] = SkillNode(
      id: 'immortality',
      skill: _skills['immortality']!,
      connectedNodes: ['toughness'],
    );

    // Social tree
    _skillNodes['charisma'] = SkillNode(
      id: 'charisma',
      skill: _skills['charisma']!,
      connectedNodes: ['leadership'],
    );

    _skillNodes['leadership'] = SkillNode(
      id: 'leadership',
      skill: _skills['leadership']!,
      connectedNodes: ['charisma'],
    );

    // Crafting tree
    _skillNodes['weapon_crafting'] = SkillNode(
      id: 'weapon_crafting',
      skill: _skills['weapon_crafting']!,
      connectedNodes: ['armor_crafting'],
    );

    _skillNodes['armor_crafting'] = SkillNode(
      id: 'armor_crafting',
      skill: _skills['armor_crafting']!,
      connectedNodes: ['weapon_crafting'],
    );

    // Update node states
    _updateSkillNodeStates();
  }

  // Update skill node states based on levels and unlocks
  void _updateSkillNodeStates() {
    for (final node in _skillNodes.values) {
      final currentLevel = _skillLevels[node.id] ?? 0;
      final isUnlocked = _skillUnlocks[node.id] ?? false;
      final isMaxed = currentLevel >= node.skill.maxLevel;

      _skillNodes[node.id] = node.copyWith(
        currentLevel: currentLevel,
        isUnlocked: isUnlocked,
        isMaxed: isMaxed,
      );
    }
  }

  // Add skill points
  void addSkillPoints(int points) {
    _availableSkillPoints += points;
    _saveProgressionData();
    notifyListeners();

    if (kDebugMode) {
      print('[CharacterProgressionService] Added $points skill points. Total: $_availableSkillPoints');
    }
  }

  // Add experience to character progression
  void addExperience(int experience, {String? source}) {
    // This method is called by other services to add experience
    // The actual character leveling is handled by CharacterService
    // This method can be used for skill progression or other progression systems
    
    if (kDebugMode) {
      print('[CharacterProgressionService] Experience gained: $experience from $source');
    }
    
    // Could add skill points based on experience gained
    // For now, just log the experience gain
    notifyListeners();
  }

  // Spend skill points
  void spendSkillPoints(int points) {
    if (_availableSkillPoints >= points) {
      _availableSkillPoints -= points;
      _saveProgressionData();
      notifyListeners();

      if (kDebugMode) {
        print('[CharacterProgressionService] Spent $points skill points. Remaining: $_availableSkillPoints');
      }
    }
  }

  // Upgrade a skill
  bool upgradeSkill(String skillId) {
    final skill = _skills[skillId];
    if (skill == null) return false;

    final node = _skillNodes[skillId];
    if (node == null) return false;

    // Check if skill can be upgraded
    if (node.isMaxed) {
      if (kDebugMode) {
        print('[CharacterProgressionService] Skill $skillId is already maxed');
      }
      return false;
    }

    // Check if player has enough skill points
    if (_availableSkillPoints < skill.skillPointCost) {
      if (kDebugMode) {
        print('[CharacterProgressionService] Not enough skill points for $skillId');
      }
      return false;
    }

    // Check prerequisites
    if (!_checkPrerequisites(skill)) {
      if (kDebugMode) {
        print('[CharacterProgressionService] Prerequisites not met for $skillId');
      }
      return false;
    }

    // Upgrade the skill
    final currentLevel = _skillLevels[skillId] ?? 0;
    _skillLevels[skillId] = currentLevel + 1;
    _skillUnlocks[skillId] = true;

    // Spend skill points
    spendSkillPoints(skill.skillPointCost);

    // Update node state
    _updateSkillNodeStates();
    _saveProgressionData();
    notifyListeners();

    if (kDebugMode) {
      print('[CharacterProgressionService] Upgraded skill $skillId to level ${currentLevel + 1}');
    }

    return true;
  }

  // Check if skill prerequisites are met
  bool _checkPrerequisites(Skill skill) {
    for (final prerequisiteId in skill.prerequisites) {
      final prerequisiteLevel = _skillLevels[prerequisiteId] ?? 0;
      final prerequisiteSkill = _skills[prerequisiteId];
      
      if (prerequisiteSkill == null || prerequisiteLevel < prerequisiteSkill.maxLevel) {
        return false;
      }
    }
    return true;
  }

  // Get skill level
  int getSkillLevel(String skillId) {
    return _skillLevels[skillId] ?? 0;
  }

  // Check if skill is unlocked
  bool isSkillUnlocked(String skillId) {
    return _skillUnlocks[skillId] ?? false;
  }

  // Check if skill is maxed
  bool isSkillMaxed(String skillId) {
    final skill = _skills[skillId];
    if (skill == null) return false;
    
    final currentLevel = _skillLevels[skillId] ?? 0;
    return currentLevel >= skill.maxLevel;
  }

  // Get skills by tree type
  List<Skill> getSkillsByTree(SkillTreeType treeType) {
    return _skills.values
        .where((skill) => skill.treeType == treeType)
        .toList();
  }

  // Get skill nodes by tree type
  List<SkillNode> getSkillNodesByTree(SkillTreeType treeType) {
    return _skillNodes.values
        .where((node) => node.skill.treeType == treeType)
        .toList();
  }

  // Get all skill effects for a character
  Map<String, dynamic> getSkillEffects() {
    final effects = <String, dynamic>{};

    for (final entry in _skillLevels.entries) {
      final skillId = entry.key;
      final level = entry.value;
      final skill = _skills[skillId];

      if (skill != null && level > 0) {
        for (final effectEntry in skill.effects.entries) {
          final effectName = effectEntry.key;
          final baseValue = effectEntry.value as num;
          final totalValue = baseValue * level;

          if (effects.containsKey(effectName)) {
            effects[effectName] = (effects[effectName] as num) + totalValue;
          } else {
            effects[effectName] = totalValue;
          }
        }
      }
    }

    return effects;
  }

  // Get skill tree statistics
  Map<String, dynamic> getSkillTreeStatistics() {
    final stats = <String, dynamic>{};
    
    for (final treeType in SkillTreeType.values) {
      final treeSkills = getSkillsByTree(treeType);
      final unlockedSkills = treeSkills.where((skill) => isSkillUnlocked(skill.id)).length;
      final maxedSkills = treeSkills.where((skill) => isSkillMaxed(skill.id)).length;
      final totalLevels = treeSkills.fold<int>(0, (sum, skill) => sum + getSkillLevel(skill.id));

      stats[treeType.name] = {
        'totalSkills': treeSkills.length,
        'unlockedSkills': unlockedSkills,
        'maxedSkills': maxedSkills,
        'totalLevels': totalLevels,
        'completionRate': treeSkills.isNotEmpty ? unlockedSkills / treeSkills.length : 0.0,
      };
    }

    stats['totalSkillPoints'] = _availableSkillPoints;
    stats['totalUnlockedSkills'] = _skillUnlocks.length;
    stats['totalSkillLevels'] = _skillLevels.values.fold<int>(0, (sum, level) => sum + level);

    return stats;
  }

  // Reset skill tree (for testing or respec)
  void resetSkillTree() {
    _skillLevels.clear();
    _skillUnlocks.clear();
    _availableSkillPoints = 20; // Give some points back
    _updateSkillNodeStates();
    _saveProgressionData();
    notifyListeners();

    if (kDebugMode) {
      print('[CharacterProgressionService] Skill tree reset');
    }
  }

  // Initialize class-specific skills
  void _initializeClassSpecificSkills() {
    // Barbarian Skills
    _addSkill(Skill(
      id: 'berserker_rage',
      name: 'Berserker Rage',
      description: 'Enter a state of berserker rage, increasing damage and attack speed',
      treeType: SkillTreeType.berserker,
      tier: SkillTier.basic,
      maxLevel: 5,
      requiredLevel: 1,
      prerequisites: [],
      effects: {
        'damage_bonus': 15,
        'attack_speed': 10,
        'rage_duration': 30,
      },
      skillPointCost: 1,
    ));

    _addSkill(Skill(
      id: 'battle_cry',
      name: 'Battle Cry',
      description: 'Intimidate enemies and boost allies',
      treeType: SkillTreeType.berserker,
      tier: SkillTier.intermediate,
      maxLevel: 3,
      requiredLevel: 5,
      prerequisites: ['berserker_rage'],
      effects: {
        'enemy_fear': 20,
        'ally_damage_bonus': 10,
      },
      skillPointCost: 2,
    ));

    // Sorcerer Skills
    _addSkill(Skill(
      id: 'elemental_mastery',
      name: 'Elemental Mastery',
      description: 'Master of fire, ice, and lightning elements',
      treeType: SkillTreeType.elemental,
      tier: SkillTier.basic,
      maxLevel: 5,
      requiredLevel: 1,
      prerequisites: [],
      effects: {
        'fire_damage': 25,
        'ice_damage': 25,
        'lightning_damage': 25,
      },
      skillPointCost: 1,
    ));

    _addSkill(Skill(
      id: 'spell_weaving',
      name: 'Spell Weaving',
      description: 'Combine multiple spells for devastating effects',
      treeType: SkillTreeType.elemental,
      tier: SkillTier.advanced,
      maxLevel: 3,
      requiredLevel: 10,
      prerequisites: ['elemental_mastery'],
      effects: {
        'spell_combination_bonus': 50,
        'mana_efficiency': 20,
      },
      skillPointCost: 3,
    ));

    // Paladin Skills
    _addSkill(Skill(
      id: 'holy_light',
      name: 'Holy Light',
      description: 'Channel divine light to heal and damage undead',
      treeType: SkillTreeType.holy,
      tier: SkillTier.basic,
      maxLevel: 5,
      requiredLevel: 1,
      prerequisites: [],
      effects: {
        'healing_power': 30,
        'undead_damage': 50,
      },
      skillPointCost: 1,
    ));

    _addSkill(Skill(
      id: 'divine_protection',
      name: 'Divine Protection',
      description: 'Create a protective barrier against evil',
      treeType: SkillTreeType.protection,
      tier: SkillTier.intermediate,
      maxLevel: 3,
      requiredLevel: 5,
      prerequisites: ['holy_light'],
      effects: {
        'damage_reduction': 25,
        'evil_resistance': 40,
      },
      skillPointCost: 2,
    ));

    // Assassin Skills
    _addSkill(Skill(
      id: 'shadow_step',
      name: 'Shadow Step',
      description: 'Move through shadows and strike from stealth',
      treeType: SkillTreeType.shadow,
      tier: SkillTier.basic,
      maxLevel: 5,
      requiredLevel: 1,
      prerequisites: [],
      effects: {
        'stealth_damage': 100,
        'stealth_duration': 10,
      },
      skillPointCost: 1,
    ));

    _addSkill(Skill(
      id: 'poison_mastery',
      name: 'Poison Mastery',
      description: 'Master the art of deadly poisons',
      treeType: SkillTreeType.stealth,
      tier: SkillTier.intermediate,
      maxLevel: 3,
      requiredLevel: 5,
      prerequisites: ['shadow_step'],
      effects: {
        'poison_damage': 30,
        'poison_duration': 15,
      },
      skillPointCost: 2,
    ));

    // Druid Skills
    _addSkill(Skill(
      id: 'nature_affinity',
      name: 'Nature Affinity',
      description: 'Connect with nature and gain its powers',
      treeType: SkillTreeType.nature,
      tier: SkillTier.basic,
      maxLevel: 5,
      requiredLevel: 1,
      prerequisites: [],
      effects: {
        'nature_damage': 25,
        'healing_bonus': 20,
      },
      skillPointCost: 1,
    ));

    _addSkill(Skill(
      id: 'wild_shape',
      name: 'Wild Shape',
      description: 'Transform into powerful animal forms',
      treeType: SkillTreeType.shapeshifting,
      tier: SkillTier.intermediate,
      maxLevel: 3,
      requiredLevel: 5,
      prerequisites: ['nature_affinity'],
      effects: {
        'transformation_duration': 60,
        'form_power_bonus': 30,
      },
      skillPointCost: 2,
    ));

    // Necromancer Skills
    _addSkill(Skill(
      id: 'death_touch',
      name: 'Death Touch',
      description: 'Channel the power of death itself',
      treeType: SkillTreeType.death,
      tier: SkillTier.basic,
      maxLevel: 5,
      requiredLevel: 1,
      prerequisites: [],
      effects: {
        'death_damage': 40,
        'life_drain': 15,
      },
      skillPointCost: 1,
    ));

    _addSkill(Skill(
      id: 'raise_dead',
      name: 'Raise Dead',
      description: 'Summon undead minions to fight for you',
      treeType: SkillTreeType.summoning,
      tier: SkillTier.intermediate,
      maxLevel: 3,
      requiredLevel: 5,
      prerequisites: ['death_touch'],
      effects: {
        'minion_count': 2,
        'minion_power': 50,
      },
      skillPointCost: 2,
    ));

    // Amazon Skills
    _addSkill(Skill(
      id: 'precise_shot',
      name: 'Precise Shot',
      description: 'Master the art of archery',
      treeType: SkillTreeType.archery,
      tier: SkillTier.basic,
      maxLevel: 5,
      requiredLevel: 1,
      prerequisites: [],
      effects: {
        'ranged_damage': 25,
        'accuracy': 15,
      },
      skillPointCost: 1,
    ));

    _addSkill(Skill(
      id: 'javelin_mastery',
      name: 'Javelin Mastery',
      description: 'Master throwing javelins with deadly precision',
      treeType: SkillTreeType.javelin,
      tier: SkillTier.intermediate,
      maxLevel: 3,
      requiredLevel: 5,
      prerequisites: ['precise_shot'],
      effects: {
        'javelin_damage': 40,
        'piercing_chance': 25,
      },
      skillPointCost: 2,
    ));

    // Monk Skills
    _addSkill(Skill(
      id: 'martial_arts',
      name: 'Martial Arts',
      description: 'Master hand-to-hand combat techniques',
      treeType: SkillTreeType.martial,
      tier: SkillTier.basic,
      maxLevel: 5,
      requiredLevel: 1,
      prerequisites: [],
      effects: {
        'unarmed_damage': 30,
        'dodge_chance': 15,
      },
      skillPointCost: 1,
    ));

    _addSkill(Skill(
      id: 'meditation',
      name: 'Meditation',
      description: 'Enter deep meditation for spiritual power',
      treeType: SkillTreeType.meditation,
      tier: SkillTier.intermediate,
      maxLevel: 3,
      requiredLevel: 5,
      prerequisites: ['martial_arts'],
      effects: {
        'spiritual_power': 25,
        'mana_regeneration': 20,
      },
      skillPointCost: 2,
    ));
  }
} 