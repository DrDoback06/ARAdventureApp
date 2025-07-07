import 'package:json_annotation/json_annotation.dart';
import 'package:realm_of_valor/models/card_model.dart';
import 'package:uuid/uuid.dart';
import 'dart:math' as math;

part 'skill_system.g.dart';

enum SkillSchool {
  combat,      // Physical fighting abilities
  elementalism, // Fire, water, earth, air magic
  restoration, // Healing and support magic
  shadow,      // Dark magic and stealth
  nature,      // Nature-based magic and abilities
  fitness,     // Real-world fitness enhancement skills
  social,      // Guild and multiplayer abilities
  crafting,    // Item creation and enhancement
  exploration, // Travel and discovery abilities
}

enum SkillType {
  passive,    // Always active bonuses
  active,     // Castable abilities
  toggle,     // On/off abilities
  ultimate,   // Powerful abilities with cooldowns
}

enum SkillTier {
  novice,     // Level 1-10
  apprentice, // Level 11-25
  adept,      // Level 26-50
  expert,     // Level 51-75
  master,     // Level 76-100
  grandmaster, // Level 100+
}

@JsonSerializable()
class SkillRequirement {
  final String? prerequisiteSkillId;
  final int minimumLevel;
  final int minimumSkillPoints;
  final Map<String, int> attributeRequirements;
  final List<String> requiredAchievements;
  final Map<String, dynamic> otherRequirements;

  SkillRequirement({
    this.prerequisiteSkillId,
    this.minimumLevel = 1,
    this.minimumSkillPoints = 0,
    Map<String, int>? attributeRequirements,
    List<String>? requiredAchievements,
    Map<String, dynamic>? otherRequirements,
  }) : attributeRequirements = attributeRequirements ?? {},
       requiredAchievements = requiredAchievements ?? [],
       otherRequirements = otherRequirements ?? {};

  factory SkillRequirement.fromJson(Map<String, dynamic> json) =>
      _$SkillRequirementFromJson(json);
  Map<String, dynamic> toJson() => _$SkillRequirementToJson(this);
}

@JsonSerializable()
class SkillEffect {
  final String type;
  final double value;
  final String target;
  final int duration; // In seconds, -1 for permanent
  final Map<String, dynamic> parameters;

  SkillEffect({
    required this.type,
    required this.value,
    required this.target,
    this.duration = -1,
    Map<String, dynamic>? parameters,
  }) : parameters = parameters ?? {};

  factory SkillEffect.fromJson(Map<String, dynamic> json) =>
      _$SkillEffectFromJson(json);
  Map<String, dynamic> toJson() => _$SkillEffectToJson(this);
}

@JsonSerializable()
class Skill {
  final String id;
  final String name;
  final String description;
  final SkillSchool school;
  final SkillType type;
  final SkillTier tier;
  final int maxRank;
  final int currentRank;
  final SkillRequirement requirements;
  final List<SkillEffect> effects;
  final int manaCost;
  final int cooldown; // In seconds
  final String iconUrl;
  final Map<String, dynamic> metadata;

  Skill({
    String? id,
    required this.name,
    required this.description,
    required this.school,
    required this.type,
    required this.tier,
    this.maxRank = 5,
    this.currentRank = 0,
    SkillRequirement? requirements,
    List<SkillEffect>? effects,
    this.manaCost = 0,
    this.cooldown = 0,
    this.iconUrl = '',
    Map<String, dynamic>? metadata,
  }) : id = id ?? const Uuid().v4(),
       requirements = requirements ?? SkillRequirement(),
       effects = effects ?? [],
       metadata = metadata ?? {};

  factory Skill.fromJson(Map<String, dynamic> json) =>
      _$SkillFromJson(json);
  Map<String, dynamic> toJson() => _$SkillToJson(this);

  Skill copyWith({
    String? id,
    String? name,
    String? description,
    SkillSchool? school,
    SkillType? type,
    SkillTier? tier,
    int? maxRank,
    int? currentRank,
    SkillRequirement? requirements,
    List<SkillEffect>? effects,
    int? manaCost,
    int? cooldown,
    String? iconUrl,
    Map<String, dynamic>? metadata,
  }) {
    return Skill(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      school: school ?? this.school,
      type: type ?? this.type,
      tier: tier ?? this.tier,
      maxRank: maxRank ?? this.maxRank,
      currentRank: currentRank ?? this.currentRank,
      requirements: requirements ?? this.requirements,
      effects: effects ?? this.effects,
      manaCost: manaCost ?? this.manaCost,
      cooldown: cooldown ?? this.cooldown,
      iconUrl: iconUrl ?? this.iconUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isLearned => currentRank > 0;
  bool get isMaxRank => currentRank >= maxRank;
  bool get isUltimate => type == SkillType.ultimate;
  double get effectivenessByRank => currentRank / maxRank;
}

@JsonSerializable()
class SkillTree {
  final SkillSchool school;
  final String name;
  final String description;
  final List<Skill> skills;
  final Map<String, List<String>> connections; // skill_id -> [connected_skill_ids]
  final Map<String, dynamic> schoolBonuses;

  SkillTree({
    required this.school,
    required this.name,
    required this.description,
    List<Skill>? skills,
    Map<String, List<String>>? connections,
    Map<String, dynamic>? schoolBonuses,
  }) : skills = skills ?? [],
       connections = connections ?? {},
       schoolBonuses = schoolBonuses ?? {};

  factory SkillTree.fromJson(Map<String, dynamic> json) =>
      _$SkillTreeFromJson(json);
  Map<String, dynamic> toJson() => _$SkillTreeToJson(this);

  List<Skill> getSkillsByTier(SkillTier tier) =>
      skills.where((skill) => skill.tier == tier).toList();
  
  List<Skill> getLearnedSkills() =>
      skills.where((skill) => skill.isLearned).toList();
  
  int get totalSkillPoints => skills.fold(0, (sum, skill) => sum + skill.currentRank);
}

class SkillSystem {
  // Combat Skill Tree - Physical fighting abilities
  static SkillTree get combatSkillTree => SkillTree(
    school: SkillSchool.combat,
    name: 'School of Combat',
    description: 'Master the art of physical warfare and tactical combat.',
    skills: [
      // Novice Tier
      Skill(
        id: 'weapon_mastery',
        name: 'Weapon Mastery',
        description: 'Increases damage dealt with all weapon cards.',
        school: SkillSchool.combat,
        type: SkillType.passive,
        tier: SkillTier.novice,
        maxRank: 5,
        effects: [
          SkillEffect(type: 'damage_multiplier', value: 0.05, target: 'weapon_cards'),
        ],
        requirements: SkillRequirement(minimumLevel: 1),
      ),
      Skill(
        id: 'battle_stance',
        name: 'Battle Stance',
        description: 'Increases defense and reduces incoming damage.',
        school: SkillSchool.combat,
        type: SkillType.toggle,
        tier: SkillTier.novice,
        maxRank: 3,
        effects: [
          SkillEffect(type: 'damage_reduction', value: 0.10, target: 'self'),
          SkillEffect(type: 'movement_speed', value: -0.15, target: 'self'),
        ],
        manaCost: 20,
        requirements: SkillRequirement(minimumLevel: 3),
      ),
      
      // Apprentice Tier
      Skill(
        id: 'berserker_rage',
        name: 'Berserker Rage',
        description: 'Enter a rage state, greatly increasing attack speed and damage.',
        school: SkillSchool.combat,
        type: SkillType.active,
        tier: SkillTier.apprentice,
        maxRank: 4,
        effects: [
          SkillEffect(type: 'attack_speed', value: 0.50, target: 'self', duration: 15),
          SkillEffect(type: 'damage_multiplier', value: 0.30, target: 'self', duration: 15),
          SkillEffect(type: 'defense_reduction', value: 0.20, target: 'self', duration: 15),
        ],
        manaCost: 40,
        cooldown: 60,
        requirements: SkillRequirement(
          prerequisiteSkillId: 'weapon_mastery',
          minimumLevel: 15,
        ),
      ),
      
      // Adept Tier
      Skill(
        id: 'perfect_strike',
        name: 'Perfect Strike',
        description: 'Next attack deals massive critical damage and cannot miss.',
        school: SkillSchool.combat,
        type: SkillType.active,
        tier: SkillTier.adept,
        maxRank: 3,
        effects: [
          SkillEffect(type: 'critical_multiplier', value: 3.0, target: 'next_attack'),
          SkillEffect(type: 'accuracy', value: 1.0, target: 'next_attack'),
        ],
        manaCost: 60,
        cooldown: 45,
        requirements: SkillRequirement(
          prerequisiteSkillId: 'berserker_rage',
          minimumLevel: 30,
        ),
      ),
      
      // Master Tier Ultimate
      Skill(
        id: 'weapon_storm',
        name: 'Weapon Storm',
        description: 'Unleash a devastating storm of weapon attacks hitting all enemies.',
        school: SkillSchool.combat,
        type: SkillType.ultimate,
        tier: SkillTier.master,
        maxRank: 1,
        effects: [
          SkillEffect(type: 'area_damage', value: 2.0, target: 'all_enemies'),
          SkillEffect(type: 'hit_count', value: 5.0, target: 'all_enemies'),
        ],
        manaCost: 100,
        cooldown: 300,
        requirements: SkillRequirement(
          prerequisiteSkillId: 'perfect_strike',
          minimumLevel: 80,
          attributeRequirements: {'strength': 50},
        ),
      ),
    ],
    schoolBonuses: {
      'damage_bonus_per_skill': 0.02,
      'critical_chance_bonus': 0.01,
    },
  );

  // Elementalism Skill Tree - Elemental magic
  static SkillTree get elementalismSkillTree => SkillTree(
    school: SkillSchool.elementalism,
    name: 'School of Elementalism',
    description: 'Harness the primal forces of fire, water, earth, and air.',
    skills: [
      // Fire Path
      Skill(
        id: 'fireball',
        name: 'Fireball',
        description: 'Launches a burning projectile that deals fire damage.',
        school: SkillSchool.elementalism,
        type: SkillType.active,
        tier: SkillTier.novice,
        maxRank: 5,
        effects: [
          SkillEffect(type: 'fire_damage', value: 50.0, target: 'enemy'),
          SkillEffect(type: 'burn_chance', value: 0.25, target: 'enemy'),
        ],
        manaCost: 25,
        cooldown: 3,
        requirements: SkillRequirement(minimumLevel: 2),
      ),
      Skill(
        id: 'meteor',
        name: 'Meteor',
        description: 'Calls down a devastating meteor from the sky.',
        school: SkillSchool.elementalism,
        type: SkillType.ultimate,
        tier: SkillTier.expert,
        maxRank: 3,
        effects: [
          SkillEffect(type: 'fire_damage', value: 300.0, target: 'area'),
          SkillEffect(type: 'burn_damage', value: 50.0, target: 'area', duration: 10),
        ],
        manaCost: 120,
        cooldown: 180,
        requirements: SkillRequirement(
          prerequisiteSkillId: 'fireball',
          minimumLevel: 60,
        ),
      ),
      
      // Water Path
      Skill(
        id: 'healing_spring',
        name: 'Healing Spring',
        description: 'Creates a spring that heals allies over time.',
        school: SkillSchool.elementalism,
        type: SkillType.active,
        tier: SkillTier.apprentice,
        maxRank: 4,
        effects: [
          SkillEffect(type: 'healing', value: 30.0, target: 'allies', duration: 20),
          SkillEffect(type: 'mana_regeneration', value: 5.0, target: 'allies', duration: 20),
        ],
        manaCost: 40,
        cooldown: 30,
        requirements: SkillRequirement(minimumLevel: 12),
      ),
      
      // Earth Path
      Skill(
        id: 'stone_armor',
        name: 'Stone Armor',
        description: 'Encases the caster in protective stone armor.',
        school: SkillSchool.elementalism,
        type: SkillType.active,
        tier: SkillTier.apprentice,
        maxRank: 4,
        effects: [
          SkillEffect(type: 'armor_bonus', value: 50.0, target: 'self', duration: 60),
          SkillEffect(type: 'earth_resistance', value: 0.5, target: 'self', duration: 60),
        ],
        manaCost: 35,
        cooldown: 20,
        requirements: SkillRequirement(minimumLevel: 10),
      ),
      
      // Air Path
      Skill(
        id: 'lightning_bolt',
        name: 'Lightning Bolt',
        description: 'Strikes enemies with a powerful bolt of lightning.',
        school: SkillSchool.elementalism,
        type: SkillType.active,
        tier: SkillTier.adept,
        maxRank: 5,
        effects: [
          SkillEffect(type: 'lightning_damage', value: 80.0, target: 'enemy'),
          SkillEffect(type: 'shock_chance', value: 0.35, target: 'enemy'),
          SkillEffect(type: 'chain_targets', value: 3.0, target: 'enemies'),
        ],
        manaCost: 45,
        cooldown: 5,
        requirements: SkillRequirement(minimumLevel: 25),
      ),
    ],
    schoolBonuses: {
      'elemental_mastery_per_skill': 0.03,
      'mana_efficiency': 0.05,
    },
  );

  // Fitness Skill Tree - Real-world fitness enhancement
  static SkillTree get fitnessSkillTree => SkillTree(
    school: SkillSchool.fitness,
    name: 'School of Physical Excellence',
    description: 'Enhance your real-world fitness and earn amazing in-game bonuses!',
    skills: [
      // Cardiovascular Path
      Skill(
        id: 'runners_endurance',
        name: 'Runner\'s Endurance',
        description: 'Increases XP gained from walking and running activities.',
        school: SkillSchool.fitness,
        type: SkillType.passive,
        tier: SkillTier.novice,
        maxRank: 5,
        effects: [
          SkillEffect(type: 'cardio_xp_multiplier', value: 0.20, target: 'self'),
          SkillEffect(type: 'energy_regeneration', value: 0.10, target: 'self'),
        ],
        requirements: SkillRequirement(minimumLevel: 1),
      ),
      Skill(
        id: 'marathon_spirit',
        name: 'Marathon Spirit',
        description: 'Gain massive bonuses for completing long-distance challenges.',
        school: SkillSchool.fitness,
        type: SkillType.passive,
        tier: SkillTier.expert,
        maxRank: 3,
        effects: [
          SkillEffect(type: 'distance_bonus_multiplier', value: 0.50, target: 'self'),
          SkillEffect(type: 'legendary_card_chance', value: 0.05, target: 'distance_rewards'),
        ],
        requirements: SkillRequirement(
          prerequisiteSkillId: 'runners_endurance',
          minimumLevel: 55,
          otherRequirements: {'marathons_completed': 1},
        ),
      ),
      
      // Strength Path
      Skill(
        id: 'iron_will',
        name: 'Iron Will',
        description: 'Strength training activities provide combat bonuses.',
        school: SkillSchool.fitness,
        type: SkillType.passive,
        tier: SkillTier.apprentice,
        maxRank: 4,
        effects: [
          SkillEffect(type: 'strength_xp_multiplier', value: 0.25, target: 'self'),
          SkillEffect(type: 'weapon_damage_bonus', value: 0.15, target: 'self'),
        ],
        requirements: SkillRequirement(minimumLevel: 15),
      ),
      
      // Flexibility Path
      Skill(
        id: 'zen_flexibility',
        name: 'Zen Flexibility',
        description: 'Yoga and stretching activities enhance mana and magical abilities.',
        school: SkillSchool.fitness,
        type: SkillType.passive,
        tier: SkillTier.apprentice,
        maxRank: 4,
        effects: [
          SkillEffect(type: 'flexibility_xp_multiplier', value: 0.30, target: 'self'),
          SkillEffect(type: 'mana_pool_bonus', value: 0.20, target: 'self'),
          SkillEffect(type: 'spell_cooldown_reduction', value: 0.10, target: 'self'),
        ],
        requirements: SkillRequirement(minimumLevel: 18),
      ),
      
      // Ultimate Fitness Skill
      Skill(
        id: 'fitness_mastery',
        name: 'Fitness Mastery',
        description: 'The pinnacle of physical excellence - all fitness activities provide incredible bonuses.',
        school: SkillSchool.fitness,
        type: SkillType.ultimate,
        tier: SkillTier.grandmaster,
        maxRank: 1,
        effects: [
          SkillEffect(type: 'all_fitness_xp_multiplier', value: 1.0, target: 'self'),
          SkillEffect(type: 'legendary_fitness_rewards', value: 1.0, target: 'self'),
          SkillEffect(type: 'fitness_inspiration_aura', value: 0.25, target: 'guild_members'),
        ],
        requirements: SkillRequirement(
          minimumLevel: 100,
          otherRequirements: {
            'total_steps': 1000000,
            'total_calories': 100000,
            'fitness_achievements': 50,
          },
        ),
      ),
    ],
    schoolBonuses: {
      'real_world_motivation': 0.05,
      'fitness_streak_bonus': 0.02,
    },
  );

  // Nature Skill Tree - Nature magic and exploration
  static SkillTree get natureSkillTree => SkillTree(
    school: SkillSchool.nature,
    name: 'School of Natural Harmony',
    description: 'Connect with nature and gain the power of the wilderness.',
    skills: [
      Skill(
        id: 'natures_blessing',
        name: 'Nature\'s Blessing',
        description: 'Outdoor activities provide enhanced rewards and healing.',
        school: SkillSchool.nature,
        type: SkillType.passive,
        tier: SkillTier.novice,
        maxRank: 5,
        effects: [
          SkillEffect(type: 'outdoor_xp_multiplier', value: 0.15, target: 'self'),
          SkillEffect(type: 'natural_healing_bonus', value: 0.10, target: 'self'),
        ],
        requirements: SkillRequirement(minimumLevel: 5),
      ),
      Skill(
        id: 'animal_companion',
        name: 'Animal Companion',
        description: 'Summon a spirit animal to aid in exploration and battles.',
        school: SkillSchool.nature,
        type: SkillType.active,
        tier: SkillTier.adept,
        maxRank: 3,
        effects: [
          SkillEffect(type: 'companion_damage', value: 40.0, target: 'enemies'),
          SkillEffect(type: 'exploration_bonus', value: 0.20, target: 'self', duration: 300),
        ],
        manaCost: 50,
        cooldown: 120,
        requirements: SkillRequirement(
          prerequisiteSkillId: 'natures_blessing',
          minimumLevel: 35,
        ),
      ),
      Skill(
        id: 'grove_sanctuary',
        name: 'Grove Sanctuary',
        description: 'Create a magical sanctuary that provides massive bonuses to all nearby allies.',
        school: SkillSchool.nature,
        type: SkillType.ultimate,
        tier: SkillTier.master,
        maxRank: 2,
        effects: [
          SkillEffect(type: 'healing_aura', value: 25.0, target: 'all_allies', duration: 180),
          SkillEffect(type: 'mana_regeneration_aura', value: 10.0, target: 'all_allies', duration: 180),
          SkillEffect(type: 'nature_spell_power_aura', value: 0.5, target: 'all_allies', duration: 180),
        ],
        manaCost: 100,
        cooldown: 600,
        requirements: SkillRequirement(
          prerequisiteSkillId: 'animal_companion',
          minimumLevel: 70,
        ),
      ),
    ],
    schoolBonuses: {
      'outdoor_spawn_rate_bonus': 0.10,
      'nature_card_affinity': 0.15,
    },
  );

  // Social Skill Tree - Guild and multiplayer abilities
  static SkillTree get socialSkillTree => SkillTree(
    school: SkillSchool.social,
    name: 'School of Leadership',
    description: 'Master the art of teamwork and guild coordination.',
    skills: [
      Skill(
        id: 'leadership_aura',
        name: 'Leadership Aura',
        description: 'Nearby guild members gain bonus XP and motivation.',
        school: SkillSchool.social,
        type: SkillType.passive,
        tier: SkillTier.apprentice,
        maxRank: 5,
        effects: [
          SkillEffect(type: 'guild_xp_bonus', value: 0.10, target: 'nearby_guild_members'),
          SkillEffect(type: 'guild_motivation_bonus', value: 0.05, target: 'nearby_guild_members'),
        ],
        requirements: SkillRequirement(
          minimumLevel: 20,
          otherRequirements: {'guild_member': true},
        ),
      ),
      Skill(
        id: 'rally_cry',
        name: 'Rally Cry',
        description: 'Inspire all guild members with a powerful motivational boost.',
        school: SkillSchool.social,
        type: SkillType.active,
        tier: SkillTier.adept,
        maxRank: 3,
        effects: [
          SkillEffect(type: 'guild_damage_bonus', value: 0.25, target: 'all_guild_members', duration: 120),
          SkillEffect(type: 'guild_defense_bonus', value: 0.20, target: 'all_guild_members', duration: 120),
        ],
        manaCost: 75,
        cooldown: 300,
        requirements: SkillRequirement(
          prerequisiteSkillId: 'leadership_aura',
          minimumLevel: 40,
          otherRequirements: {'guild_rank': 'officer'},
        ),
      ),
      Skill(
        id: 'guild_mastery',
        name: 'Guild Mastery',
        description: 'The ultimate expression of guild leadership and coordination.',
        school: SkillSchool.social,
        type: SkillType.ultimate,
        tier: SkillTier.grandmaster,
        maxRank: 1,
        effects: [
          SkillEffect(type: 'guild_legendary_bonus', value: 1.0, target: 'all_guild_members'),
          SkillEffect(type: 'guild_event_power', value: 2.0, target: 'guild'),
          SkillEffect(type: 'cross_guild_alliance_bonus', value: 0.5, target: 'allied_guilds'),
        ],
        requirements: SkillRequirement(
          prerequisiteSkillId: 'rally_cry',
          minimumLevel: 90,
          otherRequirements: {'guild_rank': 'guildmaster', 'guild_level': 25},
        ),
      ),
    ],
    schoolBonuses: {
      'guild_activity_bonus': 0.08,
      'social_quest_efficiency': 0.12,
    },
  );

  // Get all skill trees
  static List<SkillTree> get allSkillTrees => [
    combatSkillTree,
    elementalismSkillTree,
    fitnessSkillTree,
    natureSkillTree,
    socialSkillTree,
  ];

  // Skill point calculation
  static int calculateSkillPointsAvailable(int characterLevel) {
    // Base points per level + bonus points at milestones
    int basePoints = characterLevel;
    int bonusPoints = 0;
    
    // Milestone bonuses
    if (characterLevel >= 10) bonusPoints += 2;
    if (characterLevel >= 25) bonusPoints += 3;
    if (characterLevel >= 50) bonusPoints += 5;
    if (characterLevel >= 75) bonusPoints += 5;
    if (characterLevel >= 100) bonusPoints += 10;
    
    return basePoints + bonusPoints;
  }

  // Check if a skill can be learned
  static bool canLearnSkill(Skill skill, Map<String, dynamic> playerStats, List<Skill> knownSkills) {
    final requirements = skill.requirements;
    
    // Check level requirement
    if (playerStats['level'] < requirements.minimumLevel) return false;
    
    // Check prerequisite skill
    if (requirements.prerequisiteSkillId != null) {
      final prerequisite = knownSkills.firstWhere(
        (s) => s.id == requirements.prerequisiteSkillId,
        orElse: () => throw Exception('Prerequisite skill not found'),
      );
      if (prerequisite.currentRank == 0) return false;
    }
    
    // Check attribute requirements
    for (final entry in requirements.attributeRequirements.entries) {
      if ((playerStats[entry.key] ?? 0) < entry.value) return false;
    }
    
    // Check other requirements
    for (final entry in requirements.otherRequirements.entries) {
      if ((playerStats[entry.key] ?? 0) < entry.value) return false;
    }
    
    return true;
  }

  // Calculate total skill effects for a character
  static Map<String, double> calculateTotalSkillEffects(List<Skill> knownSkills) {
    final totalEffects = <String, double>{};
    
    for (final skill in knownSkills) {
      if (skill.currentRank > 0) {
        for (final effect in skill.effects) {
          final effectKey = '${effect.type}_${effect.target}';
          final effectValue = effect.value * (skill.currentRank / skill.maxRank);
          totalEffects[effectKey] = (totalEffects[effectKey] ?? 0) + effectValue;
        }
      }
    }
    
    return totalEffects;
  }

  // Get recommended skills for playstyle
  static List<Skill> getRecommendedSkills(String playstyle, int characterLevel) {
    final recommendations = <Skill>[];
    
    switch (playstyle.toLowerCase()) {
      case 'warrior':
        recommendations.addAll(combatSkillTree.skills.where((s) => 
          s.requirements.minimumLevel <= characterLevel));
        break;
      case 'mage':
        recommendations.addAll(elementalismSkillTree.skills.where((s) => 
          s.requirements.minimumLevel <= characterLevel));
        break;
      case 'fitness_enthusiast':
        recommendations.addAll(fitnessSkillTree.skills.where((s) => 
          s.requirements.minimumLevel <= characterLevel));
        break;
      case 'explorer':
        recommendations.addAll(natureSkillTree.skills.where((s) => 
          s.requirements.minimumLevel <= characterLevel));
        break;
      case 'guild_leader':
        recommendations.addAll(socialSkillTree.skills.where((s) => 
          s.requirements.minimumLevel <= characterLevel));
        break;
      default:
        // Mixed recommendations for versatile builds
        for (final tree in allSkillTrees) {
          recommendations.addAll(tree.skills.where((s) => 
            s.tier == SkillTier.novice && s.requirements.minimumLevel <= characterLevel)
            .take(1));
        }
    }
    
    return recommendations;
  }

  // Skill synergy calculator
  static Map<String, double> calculateSkillSynergies(List<Skill> knownSkills) {
    final synergies = <String, double>{};
    
    // Combat + Fitness synergy
    final combatSkills = knownSkills.where((s) => s.school == SkillSchool.combat).length;
    final fitnessSkills = knownSkills.where((s) => s.school == SkillSchool.fitness).length;
    if (combatSkills > 0 && fitnessSkills > 0) {
      synergies['warrior_athlete'] = math.min(combatSkills, fitnessSkills) * 0.1;
    }
    
    // Elementalism + Nature synergy
    final elementSkills = knownSkills.where((s) => s.school == SkillSchool.elementalism).length;
    final natureSkills = knownSkills.where((s) => s.school == SkillSchool.nature).length;
    if (elementSkills > 0 && natureSkills > 0) {
      synergies['elemental_druid'] = math.min(elementSkills, natureSkills) * 0.12;
    }
    
    // Social + Any other school synergy (leadership bonus)
    final socialSkills = knownSkills.where((s) => s.school == SkillSchool.social).length;
    if (socialSkills > 0) {
      final otherSchools = knownSkills.where((s) => s.school != SkillSchool.social).length;
      synergies['inspiring_leader'] = socialSkills * otherSchools * 0.02;
    }
    
    return synergies;
  }

  // Generate dynamic skill challenges
  static List<Map<String, dynamic>> generateSkillChallenges(List<Skill> knownSkills) {
    final challenges = <Map<String, dynamic>>[];
    
    for (final skill in knownSkills) {
      if (skill.currentRank > 0 && skill.currentRank < skill.maxRank) {
        final challenge = <String, dynamic>{
          'skill_id': skill.id,
          'skill_name': skill.name,
          'challenge_type': 'rank_up',
          'description': 'Master the next rank of ${skill.name}',
          'requirements': _generateRankUpRequirements(skill),
          'rewards': {
            'skill_rank_increase': 1,
            'xp': 100 * (skill.currentRank + 1),
            'special_rewards': _generateSkillRankRewards(skill),
          },
        };
        challenges.add(challenge);
      }
    }
    
    return challenges;
  }

  static Map<String, dynamic> _generateRankUpRequirements(Skill skill) {
    final requirements = <String, dynamic>{};
    
    switch (skill.school) {
      case SkillSchool.combat:
        requirements['battles_won'] = 5 * (skill.currentRank + 1);
        requirements['weapon_cards_used'] = 10 * (skill.currentRank + 1);
        break;
      case SkillSchool.fitness:
        requirements['fitness_activities'] = 3 * (skill.currentRank + 1);
        requirements['calories_burned'] = 200 * (skill.currentRank + 1);
        break;
      case SkillSchool.elementalism:
        requirements['spells_cast'] = 8 * (skill.currentRank + 1);
        requirements['elemental_cards_collected'] = 5 * (skill.currentRank + 1);
        break;
      case SkillSchool.nature:
        requirements['outdoor_activities'] = 4 * (skill.currentRank + 1);
        requirements['nature_locations_visited'] = 2 * (skill.currentRank + 1);
        break;
      case SkillSchool.social:
        requirements['guild_events_participated'] = 2 * (skill.currentRank + 1);
        requirements['players_helped'] = 3 * (skill.currentRank + 1);
        break;
      default:
        requirements['general_activities'] = 5 * (skill.currentRank + 1);
    }
    
    return requirements;
  }

  static List<String> _generateSkillRankRewards(Skill skill) {
    final rewards = <String>[];
    
    switch (skill.school) {
      case SkillSchool.combat:
        rewards.addAll(['weapon_enhancement_crystal', 'combat_mastery_tome']);
        break;
      case SkillSchool.fitness:
        rewards.addAll(['fitness_motivation_boost', 'endurance_enhancement']);
        break;
      case SkillSchool.elementalism:
        rewards.addAll(['elemental_essence', 'mana_crystal']);
        break;
      case SkillSchool.nature:
        rewards.addAll(['nature_blessing', 'outdoor_exploration_bonus']);
        break;
      case SkillSchool.social:
        rewards.addAll(['leadership_crown', 'guild_inspiration_aura']);
        break;
      default:
        rewards.add('skill_mastery_token');
    }
    
    return rewards;
  }
}