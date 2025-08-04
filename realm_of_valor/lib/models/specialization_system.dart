import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'character_model.dart';
import 'card_model.dart';

part 'specialization_system.g.dart';

enum SpecializationType {
  offensive,
  defensive,
  support,
  utility,
  hybrid,
}

enum SpecializationTier {
  novice,
  adept,
  expert,
  master,
  legendary,
}

@JsonSerializable()
class SpecializationNode {
  final String id;
  final String name;
  final String description;
  final SpecializationType type;
  final SpecializationTier tier;
  final int cost;
  final List<String> prerequisites;
  final Map<String, dynamic> effects;
  final String iconPath;
  final bool isUnlocked;
  final bool isActive;

  SpecializationNode({
    String? id,
    required this.name,
    required this.description,
    required this.type,
    required this.tier,
    required this.cost,
    List<String>? prerequisites,
    Map<String, dynamic>? effects,
    this.iconPath = '',
    this.isUnlocked = false,
    this.isActive = false,
  }) : id = id ?? const Uuid().v4(),
       prerequisites = prerequisites ?? [],
       effects = effects ?? {};

  factory SpecializationNode.fromJson(Map<String, dynamic> json) =>
      _$SpecializationNodeFromJson(json);
  Map<String, dynamic> toJson() => _$SpecializationNodeToJson(this);

  SpecializationNode copyWith({
    String? id,
    String? name,
    String? description,
    SpecializationType? type,
    SpecializationTier? tier,
    int? cost,
    List<String>? prerequisites,
    Map<String, dynamic>? effects,
    String? iconPath,
    bool? isUnlocked,
    bool? isActive,
  }) {
    return SpecializationNode(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      tier: tier ?? this.tier,
      cost: cost ?? this.cost,
      prerequisites: prerequisites ?? this.prerequisites,
      effects: effects ?? this.effects,
      iconPath: iconPath ?? this.iconPath,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isActive: isActive ?? this.isActive,
    );
  }
}

@JsonSerializable()
class SpecializationTree {
  final String id;
  final String name;
  final String description;
  final CharacterClass characterClass;
  final List<SpecializationNode> nodes;
  final Map<String, List<String>> connections; // nodeId -> [connectedNodeIds]
  final int maxActiveNodes;
  final int totalSkillPoints;

  SpecializationTree({
    String? id,
    required this.name,
    required this.description,
    required this.characterClass,
    List<SpecializationNode>? nodes,
    Map<String, List<String>>? connections,
    this.maxActiveNodes = 3,
    this.totalSkillPoints = 0,
  }) : id = id ?? const Uuid().v4(),
       nodes = nodes ?? [],
       connections = connections ?? {};

  factory SpecializationTree.fromJson(Map<String, dynamic> json) =>
      _$SpecializationTreeFromJson(json);
  Map<String, dynamic> toJson() => _$SpecializationTreeToJson(this);

  SpecializationTree copyWith({
    String? id,
    String? name,
    String? description,
    CharacterClass? characterClass,
    List<SpecializationNode>? nodes,
    Map<String, List<String>>? connections,
    int? maxActiveNodes,
    int? totalSkillPoints,
  }) {
    return SpecializationTree(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      characterClass: characterClass ?? this.characterClass,
      nodes: nodes ?? this.nodes,
      connections: connections ?? this.connections,
      maxActiveNodes: maxActiveNodes ?? this.maxActiveNodes,
      totalSkillPoints: totalSkillPoints ?? this.totalSkillPoints,
    );
  }

  // Get available nodes for a character
  List<SpecializationNode> getAvailableNodes(GameCharacter character) {
    return nodes.where((node) => _canUnlockNode(node, character)).toList();
  }

  // Check if a node can be unlocked
  bool _canUnlockNode(SpecializationNode node, GameCharacter character) {
    if (node.isUnlocked) return false;
    
    // Check skill points
    if (character.availableSkillPoints < node.cost) return false;
    
    // Check prerequisites
    for (final prerequisiteId in node.prerequisites) {
      final prerequisite = nodes.firstWhere((n) => n.id == prerequisiteId);
      if (!prerequisite.isUnlocked) return false;
    }
    
    return true;
  }

  // Get active specializations
  List<SpecializationNode> getActiveSpecializations() {
    return nodes.where((node) => node.isActive).toList();
  }

  // Calculate total effects from active specializations
  Map<String, dynamic> calculateActiveEffects() {
    final effects = <String, dynamic>{};
    
    for (final node in getActiveSpecializations()) {
      for (final entry in node.effects.entries) {
        final key = entry.key;
        final value = entry.value;
        
        if (effects.containsKey(key)) {
          // Combine effects (add for numbers, merge for lists)
          if (value is num && effects[key] is num) {
            effects[key] = (effects[key] as num) + value;
          } else if (value is List && effects[key] is List) {
            (effects[key] as List).addAll(value);
          }
        } else {
          effects[key] = value;
        }
      }
    }
    
    return effects;
  }
}

class SpecializationSystem {
  static final Map<CharacterClass, SpecializationTree> _specializationTrees = {
    CharacterClass.paladin: _createPaladinTree(),
    CharacterClass.barbarian: _createBarbarianTree(),
    CharacterClass.sorceress: _createSorceressTree(),
    CharacterClass.necromancer: _createNecromancerTree(),
    CharacterClass.amazon: _createAmazonTree(),
    CharacterClass.assassin: _createAssassinTree(),
    CharacterClass.druid: _createDruidTree(),
    CharacterClass.monk: _createMonkTree(),
    CharacterClass.crusader: _createCrusaderTree(),
    CharacterClass.witchDoctor: _createWitchDoctorTree(),
    CharacterClass.wizard: _createWizardTree(),
    CharacterClass.demonHunter: _createDemonHunterTree(),
  };

  static SpecializationTree? getSpecializationTree(CharacterClass characterClass) {
    return _specializationTrees[characterClass];
  }

  static List<SpecializationTree> getAllSpecializationTrees() {
    return _specializationTrees.values.toList();
  }

  // Paladin Specialization Tree
  static SpecializationTree _createPaladinTree() {
    return SpecializationTree(
      name: 'Holy Order',
      description: 'Choose your path in the service of light',
      characterClass: CharacterClass.paladin,
      nodes: [
        // Novice Tier
        SpecializationNode(
          name: 'Divine Favor',
          description: 'Increases healing effectiveness by 20%',
          type: SpecializationType.support,
          tier: SpecializationTier.novice,
          cost: 1,
          effects: {'healing_bonus': 0.2},
        ),
        SpecializationNode(
          name: 'Holy Shield',
          description: 'Reduces incoming damage by 15%',
          type: SpecializationType.defensive,
          tier: SpecializationTier.novice,
          cost: 1,
          effects: {'damage_reduction': 0.15},
        ),
        
        // Adept Tier
        SpecializationNode(
          name: 'Divine Strike',
          description: 'Holy attacks deal 25% more damage',
          type: SpecializationType.offensive,
          tier: SpecializationTier.adept,
          cost: 2,
          prerequisites: ['Divine Favor'],
          effects: {'holy_damage_bonus': 0.25},
        ),
        SpecializationNode(
          name: 'Guardian\'s Aura',
          description: 'Allies within range gain 10% damage reduction',
          type: SpecializationType.support,
          tier: SpecializationTier.adept,
          cost: 2,
          prerequisites: ['Holy Shield'],
          effects: {'ally_damage_reduction': 0.1},
        ),
        
        // Expert Tier
        SpecializationNode(
          name: 'Divine Intervention',
          description: 'Chance to prevent fatal damage once per battle',
          type: SpecializationType.defensive,
          tier: SpecializationTier.expert,
          cost: 3,
          prerequisites: ['Divine Strike', 'Guardian\'s Aura'],
          effects: {'divine_intervention': true},
        ),
        
        // Master Tier
        SpecializationNode(
          name: 'Avatar of Light',
          description: 'Transform into a powerful divine being',
          type: SpecializationType.hybrid,
          tier: SpecializationTier.master,
          cost: 5,
          prerequisites: ['Divine Intervention'],
          effects: {'avatar_form': true, 'all_stats_bonus': 0.5},
        ),
      ],
      connections: {
        'Divine Favor': ['Divine Strike'],
        'Holy Shield': ['Guardian\'s Aura'],
        'Divine Strike': ['Divine Intervention'],
        'Guardian\'s Aura': ['Divine Intervention'],
        'Divine Intervention': ['Avatar of Light'],
      },
    );
  }

  // Barbarian Specialization Tree
  static SpecializationTree _createBarbarianTree() {
    return SpecializationTree(
      name: 'Path of the Warrior',
      description: 'Embrace your primal instincts',
      characterClass: CharacterClass.barbarian,
      nodes: [
        // Novice Tier
        SpecializationNode(
          name: 'Berserker Rage',
          description: 'Deal 20% more damage when below 50% health',
          type: SpecializationType.offensive,
          tier: SpecializationTier.novice,
          cost: 1,
          effects: {'berserker_rage': 0.2},
        ),
        SpecializationNode(
          name: 'Iron Skin',
          description: 'Gain 20% additional armor',
          type: SpecializationType.defensive,
          tier: SpecializationTier.novice,
          cost: 1,
          effects: {'armor_bonus': 0.2},
        ),
        
        // Adept Tier
        SpecializationNode(
          name: 'Blood Frenzy',
          description: 'Critical hits heal you for 10% of damage dealt',
          type: SpecializationType.offensive,
          tier: SpecializationTier.adept,
          cost: 2,
          prerequisites: ['Berserker Rage'],
          effects: {'blood_frenzy': 0.1},
        ),
        SpecializationNode(
          name: 'Unstoppable',
          description: 'Cannot be stunned or slowed',
          type: SpecializationType.defensive,
          tier: SpecializationTier.adept,
          cost: 2,
          prerequisites: ['Iron Skin'],
          effects: {'unstoppable': true},
        ),
        
        // Expert Tier
        SpecializationNode(
          name: 'Rampage',
          description: 'Killing an enemy grants 50% attack speed for 3 turns',
          type: SpecializationType.offensive,
          tier: SpecializationTier.expert,
          cost: 3,
          prerequisites: ['Blood Frenzy', 'Unstoppable'],
          effects: {'rampage': true},
        ),
        
        // Master Tier
        SpecializationNode(
          name: 'Titan\'s Might',
          description: 'Become an unstoppable force of nature',
          type: SpecializationType.hybrid,
          tier: SpecializationTier.master,
          cost: 5,
          prerequisites: ['Rampage'],
          effects: {'titan_form': true, 'damage_bonus': 1.0},
        ),
      ],
      connections: {
        'Berserker Rage': ['Blood Frenzy'],
        'Iron Skin': ['Unstoppable'],
        'Blood Frenzy': ['Rampage'],
        'Unstoppable': ['Rampage'],
        'Rampage': ['Titan\'s Might'],
      },
    );
  }

  // Sorceress Specialization Tree
  static SpecializationTree _createSorceressTree() {
    return SpecializationTree(
      name: 'Arcane Mastery',
      description: 'Master the elements and arcane arts',
      characterClass: CharacterClass.sorceress,
      nodes: [
        // Novice Tier
        SpecializationNode(
          name: 'Elemental Affinity',
          description: 'Fire, Ice, and Lightning spells deal 15% more damage',
          type: SpecializationType.offensive,
          tier: SpecializationTier.novice,
          cost: 1,
          effects: {'elemental_damage_bonus': 0.15},
        ),
        SpecializationNode(
          name: 'Mana Surge',
          description: 'Regenerate 20% more mana per turn',
          type: SpecializationType.utility,
          tier: SpecializationTier.novice,
          cost: 1,
          effects: {'mana_regeneration_bonus': 0.2},
        ),
        
        // Adept Tier
        SpecializationNode(
          name: 'Spell Mastery',
          description: 'Spells cost 25% less mana',
          type: SpecializationType.utility,
          tier: SpecializationTier.adept,
          cost: 2,
          prerequisites: ['Mana Surge'],
          effects: {'spell_cost_reduction': 0.25},
        ),
        SpecializationNode(
          name: 'Elemental Storm',
          description: 'Chance to cast a free spell after casting',
          type: SpecializationType.offensive,
          tier: SpecializationTier.adept,
          cost: 2,
          prerequisites: ['Elemental Affinity'],
          effects: {'elemental_storm': 0.3},
        ),
        
        // Expert Tier
        SpecializationNode(
          name: 'Archmage\'s Insight',
          description: 'All spells have a chance to be cast twice',
          type: SpecializationType.offensive,
          tier: SpecializationTier.expert,
          cost: 3,
          prerequisites: ['Spell Mastery', 'Elemental Storm'],
          effects: {'double_cast': 0.25},
        ),
        
        // Master Tier
        SpecializationNode(
          name: 'Elemental Ascension',
          description: 'Become one with the elements',
          type: SpecializationType.hybrid,
          tier: SpecializationTier.master,
          cost: 5,
          prerequisites: ['Archmage\'s Insight'],
          effects: {'elemental_ascension': true, 'spell_power_bonus': 1.0},
        ),
      ],
      connections: {
        'Elemental Affinity': ['Elemental Storm'],
        'Mana Surge': ['Spell Mastery'],
        'Elemental Storm': ['Archmage\'s Insight'],
        'Spell Mastery': ['Archmage\'s Insight'],
        'Archmage\'s Insight': ['Elemental Ascension'],
      },
    );
  }

  // Placeholder trees for other classes
  static SpecializationTree _createNecromancerTree() => _createGenericTree('Necromancy', CharacterClass.necromancer);
  static SpecializationTree _createAmazonTree() => _createGenericTree('Amazonian Arts', CharacterClass.amazon);
  static SpecializationTree _createAssassinTree() => _createGenericTree('Shadow Arts', CharacterClass.assassin);
  static SpecializationTree _createDruidTree() => _createGenericTree('Nature\'s Path', CharacterClass.druid);
  static SpecializationTree _createMonkTree() => _createGenericTree('Monastic Discipline', CharacterClass.monk);
  static SpecializationTree _createCrusaderTree() => _createGenericTree('Crusader\'s Path', CharacterClass.crusader);
  static SpecializationTree _createWitchDoctorTree() => _createGenericTree('Voodoo Arts', CharacterClass.witchDoctor);
  static SpecializationTree _createWizardTree() => _createGenericTree('Arcane Studies', CharacterClass.wizard);
  static SpecializationTree _createDemonHunterTree() => _createGenericTree('Demon Hunter\'s Path', CharacterClass.demonHunter);

  static SpecializationTree _createGenericTree(String name, CharacterClass characterClass) {
    return SpecializationTree(
      name: name,
      description: 'Specialization tree for $name',
      characterClass: characterClass,
      nodes: [
        SpecializationNode(
          name: 'Basic Training',
          description: 'Gain 10% bonus to primary stats',
          type: SpecializationType.utility,
          tier: SpecializationTier.novice,
          cost: 1,
          effects: {'stat_bonus': 0.1},
        ),
      ],
    );
  }
} 