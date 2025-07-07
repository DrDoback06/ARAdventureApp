import 'package:json_annotation/json_annotation.dart';
import 'package:realm_of_valor/models/card_model.dart';
import 'package:uuid/uuid.dart';
import 'dart:math' as math;

part 'enhanced_battle_system.g.dart';

enum ElementType {
  fire,
  water,
  earth,
  air,
  light,
  shadow,
  lightning,
  ice,
  nature,
  arcane,
  physical,
  neutral,
}

enum BattlePhase {
  preparation,
  combat,
  resolution,
  ended,
}

enum ActionType {
  attack,
  defend,
  spell,
  item,
  skill,
  combo,
  counter,
  charge,
}

enum StatusEffect {
  poison,
  burn,
  freeze,
  shock,
  blind,
  curse,
  blessing,
  shield,
  regeneration,
  berserk,
  stealth,
  haste,
  slow,
  weakness,
  strength,
  immunity,
}

@JsonSerializable()
class ElementalAffinities {
  static const Map<ElementType, List<ElementType>> weaknesses = {
    ElementType.fire: [ElementType.water, ElementType.ice],
    ElementType.water: [ElementType.lightning, ElementType.nature],
    ElementType.earth: [ElementType.air, ElementType.nature],
    ElementType.air: [ElementType.lightning, ElementType.ice],
    ElementType.light: [ElementType.shadow],
    ElementType.shadow: [ElementType.light],
    ElementType.lightning: [ElementType.earth],
    ElementType.ice: [ElementType.fire],
    ElementType.nature: [ElementType.fire, ElementType.ice],
    ElementType.arcane: [ElementType.physical],
    ElementType.physical: [ElementType.arcane],
    ElementType.neutral: [],
  };

  static const Map<ElementType, List<ElementType>> strengths = {
    ElementType.fire: [ElementType.nature, ElementType.ice],
    ElementType.water: [ElementType.fire, ElementType.earth],
    ElementType.earth: [ElementType.lightning, ElementType.fire],
    ElementType.air: [ElementType.earth, ElementType.fire],
    ElementType.light: [ElementType.shadow],
    ElementType.shadow: [ElementType.light],
    ElementType.lightning: [ElementType.water, ElementType.air],
    ElementType.ice: [ElementType.water, ElementType.nature],
    ElementType.nature: [ElementType.earth, ElementType.water],
    ElementType.arcane: [ElementType.physical],
    ElementType.physical: [ElementType.arcane],
    ElementType.neutral: [],
  };

  static double getEffectiveness(ElementType attacker, ElementType defender) {
    if (strengths[attacker]?.contains(defender) ?? false) {
      return 1.5; // 50% more damage
    }
    if (weaknesses[attacker]?.contains(defender) ?? false) {
      return 0.5; // 50% less damage
    }
    return 1.0; // Normal damage
  }
}

@JsonSerializable()
class BattleAction {
  final String id;
  final ActionType type;
  final String name;
  final String description;
  final ElementType element;
  final int baseDamage;
  final int manaCost;
  final int accuracy;
  final int criticalChance;
  final List<StatusEffect> statusEffects;
  final Map<String, dynamic> properties;
  final bool isCombo;
  final List<String> comboRequirements;
  final int priority;

  BattleAction({
    String? id,
    required this.type,
    required this.name,
    required this.description,
    this.element = ElementType.physical,
    this.baseDamage = 0,
    this.manaCost = 0,
    this.accuracy = 100,
    this.criticalChance = 5,
    List<StatusEffect>? statusEffects,
    Map<String, dynamic>? properties,
    this.isCombo = false,
    List<String>? comboRequirements,
    this.priority = 0,
  }) : id = id ?? const Uuid().v4(),
       statusEffects = statusEffects ?? [],
       properties = properties ?? {},
       comboRequirements = comboRequirements ?? [];

  factory BattleAction.fromJson(Map<String, dynamic> json) =>
      _$BattleActionFromJson(json);
  Map<String, dynamic> toJson() => _$BattleActionToJson(this);
}

@JsonSerializable()
class StatusEffectInstance {
  final String id;
  final StatusEffect type;
  final int duration;
  final int intensity;
  final String source;
  final Map<String, dynamic> properties;
  final DateTime appliedAt;

  StatusEffectInstance({
    String? id,
    required this.type,
    required this.duration,
    this.intensity = 1,
    required this.source,
    Map<String, dynamic>? properties,
    DateTime? appliedAt,
  }) : id = id ?? const Uuid().v4(),
       properties = properties ?? {},
       appliedAt = appliedAt ?? DateTime.now();

  factory StatusEffectInstance.fromJson(Map<String, dynamic> json) =>
      _$StatusEffectInstanceFromJson(json);
  Map<String, dynamic> toJson() => _$StatusEffectInstanceToJson(this);

  StatusEffectInstance copyWith({
    String? id,
    StatusEffect? type,
    int? duration,
    int? intensity,
    String? source,
    Map<String, dynamic>? properties,
    DateTime? appliedAt,
  }) {
    return StatusEffectInstance(
      id: id ?? this.id,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      intensity: intensity ?? this.intensity,
      source: source ?? this.source,
      properties: properties ?? this.properties,
      appliedAt: appliedAt ?? this.appliedAt,
    );
  }
}

@JsonSerializable()
class BattleParticipant {
  final String id;
  final String name;
  final int level;
  final ElementType primaryElement;
  final ElementType? secondaryElement;
  final Map<String, int> stats;
  final List<GameCard> deck;
  final List<GameCard> hand;
  final List<StatusEffectInstance> statusEffects;
  final Map<String, dynamic> battleState;
  final bool isAI;
  final String? playerId;

  BattleParticipant({
    String? id,
    required this.name,
    required this.level,
    this.primaryElement = ElementType.neutral,
    this.secondaryElement,
    Map<String, int>? stats,
    List<GameCard>? deck,
    List<GameCard>? hand,
    List<StatusEffectInstance>? statusEffects,
    Map<String, dynamic>? battleState,
    this.isAI = false,
    this.playerId,
  }) : id = id ?? const Uuid().v4(),
       stats = stats ?? {
         'hp': 100,
         'max_hp': 100,
         'mp': 50,
         'max_mp': 50,
         'attack': 20,
         'defense': 15,
         'speed': 10,
         'luck': 5,
       },
       deck = deck ?? [],
       hand = hand ?? [],
       statusEffects = statusEffects ?? [],
       battleState = battleState ?? {};

  factory BattleParticipant.fromJson(Map<String, dynamic> json) =>
      _$BattleParticipantFromJson(json);
  Map<String, dynamic> toJson() => _$BattleParticipantToJson(this);

  BattleParticipant copyWith({
    String? id,
    String? name,
    int? level,
    ElementType? primaryElement,
    ElementType? secondaryElement,
    Map<String, int>? stats,
    List<GameCard>? deck,
    List<GameCard>? hand,
    List<StatusEffectInstance>? statusEffects,
    Map<String, dynamic>? battleState,
    bool? isAI,
    String? playerId,
  }) {
    return BattleParticipant(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
      primaryElement: primaryElement ?? this.primaryElement,
      secondaryElement: secondaryElement ?? this.secondaryElement,
      stats: stats ?? this.stats,
      deck: deck ?? this.deck,
      hand: hand ?? this.hand,
      statusEffects: statusEffects ?? this.statusEffects,
      battleState: battleState ?? this.battleState,
      isAI: isAI ?? this.isAI,
      playerId: playerId ?? this.playerId,
    );
  }

  bool get isAlive => (stats['hp'] ?? 0) > 0;
  int get currentHP => stats['hp'] ?? 0;
  int get maxHP => stats['max_hp'] ?? 100;
  int get currentMP => stats['mp'] ?? 0;
  int get maxMP => stats['max_mp'] ?? 50;
}

@JsonSerializable()
class EnhancedBattle {
  final String id;
  final String name;
  final String description;
  final List<BattleParticipant> participants;
  final BattlePhase phase;
  final int currentTurn;
  final String? activeParticipantId;
  final Map<String, dynamic> battleState;
  final List<String> battleLog;
  final DateTime startTime;
  final DateTime? endTime;
  final String? winnerId;
  final Map<String, dynamic> rewards;
  final Map<String, dynamic> metadata;

  EnhancedBattle({
    String? id,
    required this.name,
    required this.description,
    List<BattleParticipant>? participants,
    this.phase = BattlePhase.preparation,
    this.currentTurn = 1,
    this.activeParticipantId,
    Map<String, dynamic>? battleState,
    List<String>? battleLog,
    DateTime? startTime,
    this.endTime,
    this.winnerId,
    Map<String, dynamic>? rewards,
    Map<String, dynamic>? metadata,
  }) : id = id ?? const Uuid().v4(),
       participants = participants ?? [],
       battleState = battleState ?? {},
       battleLog = battleLog ?? [],
       startTime = startTime ?? DateTime.now(),
       rewards = rewards ?? {},
       metadata = metadata ?? {};

  factory EnhancedBattle.fromJson(Map<String, dynamic> json) =>
      _$EnhancedBattleFromJson(json);
  Map<String, dynamic> toJson() => _$EnhancedBattleToJson(this);

  EnhancedBattle copyWith({
    String? id,
    String? name,
    String? description,
    List<BattleParticipant>? participants,
    BattlePhase? phase,
    int? currentTurn,
    String? activeParticipantId,
    Map<String, dynamic>? battleState,
    List<String>? battleLog,
    DateTime? startTime,
    DateTime? endTime,
    String? winnerId,
    Map<String, dynamic>? rewards,
    Map<String, dynamic>? metadata,
  }) {
    return EnhancedBattle(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      participants: participants ?? this.participants,
      phase: phase ?? this.phase,
      currentTurn: currentTurn ?? this.currentTurn,
      activeParticipantId: activeParticipantId ?? this.activeParticipantId,
      battleState: battleState ?? this.battleState,
      battleLog: battleLog ?? this.battleLog,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      winnerId: winnerId ?? this.winnerId,
      rewards: rewards ?? this.rewards,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isEnded => phase == BattlePhase.ended;
  List<BattleParticipant> get aliveParticipants => 
      participants.where((p) => p.isAlive).toList();
}

class EnhancedBattleSystem {
  // Epic battle actions database
  static List<BattleAction> get epicActions => [
    // Fire Actions
    BattleAction(
      type: ActionType.spell,
      name: 'Inferno Blast',
      description: 'Unleash a devastating blast of fire that can burn enemies for multiple turns',
      element: ElementType.fire,
      baseDamage: 80,
      manaCost: 15,
      accuracy: 85,
      criticalChance: 15,
      statusEffects: [StatusEffect.burn],
      priority: 2,
    ),
    BattleAction(
      type: ActionType.combo,
      name: 'Phoenix Rising',
      description: 'A legendary combo that revives the user with full health if they would be defeated',
      element: ElementType.fire,
      baseDamage: 120,
      manaCost: 25,
      accuracy: 100,
      criticalChance: 25,
      isCombo: true,
      comboRequirements: ['fire_spell', 'light_spell'],
      priority: 5,
    ),
    
    // Water Actions
    BattleAction(
      type: ActionType.spell,
      name: 'Tsunami Wave',
      description: 'A massive wave that damages all enemies and can freeze them',
      element: ElementType.water,
      baseDamage: 60,
      manaCost: 12,
      accuracy: 90,
      criticalChance: 10,
      statusEffects: [StatusEffect.freeze],
      properties: {'area_damage': true},
      priority: 3,
    ),
    BattleAction(
      type: ActionType.spell,
      name: 'Healing Spring',
      description: 'Restore health and cleanse status effects with pure water magic',
      element: ElementType.water,
      baseDamage: -50, // Negative damage = healing
      manaCost: 8,
      accuracy: 100,
      properties: {'healing': true, 'cleanse': true},
      priority: 4,
    ),
    
    // Lightning Actions
    BattleAction(
      type: ActionType.attack,
      name: 'Chain Lightning',
      description: 'Lightning that jumps between enemies, dealing massive damage',
      element: ElementType.lightning,
      baseDamage: 70,
      manaCost: 10,
      accuracy: 95,
      criticalChance: 20,
      statusEffects: [StatusEffect.shock],
      properties: {'chain_damage': 3},
      priority: 6,
    ),
    
    // Shadow Actions
    BattleAction(
      type: ActionType.skill,
      name: 'Shadow Clone',
      description: 'Create shadow clones to confuse enemies and gain extra attacks',
      element: ElementType.shadow,
      baseDamage: 40,
      manaCost: 12,
      accuracy: 100,
      statusEffects: [StatusEffect.stealth],
      properties: {'clone_attacks': 2},
      priority: 1,
    ),
    BattleAction(
      type: ActionType.spell,
      name: 'Void Drain',
      description: 'Drain life from enemies while cursing them',
      element: ElementType.shadow,
      baseDamage: 45,
      manaCost: 8,
      accuracy: 90,
      statusEffects: [StatusEffect.curse],
      properties: {'life_drain': true},
      priority: 2,
    ),
    
    // Light Actions
    BattleAction(
      type: ActionType.spell,
      name: 'Divine Strike',
      description: 'A holy attack that deals massive damage to shadow creatures',
      element: ElementType.light,
      baseDamage: 90,
      manaCost: 14,
      accuracy: 95,
      criticalChance: 25,
      statusEffects: [StatusEffect.blessing],
      priority: 3,
    ),
    BattleAction(
      type: ActionType.skill,
      name: 'Guardian\'s Shield',
      description: 'Protect allies with a barrier of light that reflects damage',
      element: ElementType.light,
      baseDamage: 0,
      manaCost: 10,
      accuracy: 100,
      statusEffects: [StatusEffect.shield],
      properties: {'damage_reflection': 0.5},
      priority: 5,
    ),
    
    // Physical Actions
    BattleAction(
      type: ActionType.attack,
      name: 'Berserker Combo',
      description: 'A relentless series of attacks that increases in power',
      element: ElementType.physical,
      baseDamage: 35,
      manaCost: 5,
      accuracy: 90,
      criticalChance: 15,
      statusEffects: [StatusEffect.berserk],
      properties: {'multi_hit': 3, 'damage_increase': 1.2},
      priority: 2,
    ),
    BattleAction(
      type: ActionType.skill,
      name: 'Perfect Counter',
      description: 'Counter the next attack with double damage',
      element: ElementType.physical,
      baseDamage: 0,
      manaCost: 8,
      accuracy: 100,
      properties: {'counter_damage': 2.0},
      priority: 7,
    ),
  ];

  // Status effect processing
  static Map<String, dynamic> processStatusEffects(BattleParticipant participant) {
    final effects = <String, dynamic>{};
    final toRemove = <StatusEffectInstance>[];
    
    for (final statusEffect in participant.statusEffects) {
      switch (statusEffect.type) {
        case StatusEffect.poison:
          effects['poison_damage'] = statusEffect.intensity * 5;
          break;
        case StatusEffect.burn:
          effects['burn_damage'] = statusEffect.intensity * 8;
          break;
        case StatusEffect.regeneration:
          effects['heal_amount'] = statusEffect.intensity * 10;
          break;
        case StatusEffect.berserk:
          effects['attack_multiplier'] = 1.5;
          break;
        case StatusEffect.shield:
          effects['damage_reduction'] = 0.5;
          break;
        case StatusEffect.haste:
          effects['speed_multiplier'] = 1.3;
          break;
        case StatusEffect.slow:
          effects['speed_multiplier'] = 0.7;
          break;
        default:
          break;
      }
      
      // Decrease duration
      if (statusEffect.duration <= 1) {
        toRemove.add(statusEffect);
      }
    }
    
    effects['remove_effects'] = toRemove;
    return effects;
  }

  // Damage calculation with elements and effects
  static int calculateDamage(
    BattleAction action,
    BattleParticipant attacker,
    BattleParticipant defender,
  ) {
    double damage = action.baseDamage.toDouble();
    
    // Apply attacker's attack stat
    damage += (attacker.stats['attack'] ?? 0) * 0.5;
    
    // Apply elemental effectiveness
    damage *= ElementalAffinities.getEffectiveness(
      action.element,
      defender.primaryElement,
    );
    
    // Apply defender's defense
    damage -= (defender.stats['defense'] ?? 0) * 0.3;
    
    // Apply status effect modifiers
    final attackerEffects = processStatusEffects(attacker);
    final defenderEffects = processStatusEffects(defender);
    
    if (attackerEffects['attack_multiplier'] != null) {
      damage *= attackerEffects['attack_multiplier'];
    }
    
    if (defenderEffects['damage_reduction'] != null) {
      damage *= (1 - defenderEffects['damage_reduction']);
    }
    
    // Random variance (90% to 110%)
    final random = math.Random();
    damage *= 0.9 + (random.nextDouble() * 0.2);
    
    // Critical hit check
    if (random.nextInt(100) < action.criticalChance) {
      damage *= 2.0;
    }
    
    return math.max(0, damage.round());
  }

  // AI decision making for monsters
  static BattleAction selectAIAction(
    BattleParticipant aiParticipant,
    List<BattleParticipant> enemies,
  ) {
    final availableActions = epicActions.where((action) => 
      action.manaCost <= aiParticipant.currentMP
    ).toList();
    
    if (availableActions.isEmpty) {
      // Default attack if no mana
      return BattleAction(
        type: ActionType.attack,
        name: 'Basic Attack',
        description: 'A simple physical attack',
        element: ElementType.physical,
        baseDamage: 25,
        manaCost: 0,
        accuracy: 90,
      );
    }
    
    // AI strategy: prefer high-damage actions when enemy is low health
    final lowestHealthEnemy = enemies.reduce((a, b) => 
      a.currentHP < b.currentHP ? a : b
    );
    
    if (lowestHealthEnemy.currentHP < 30) {
      // Go for the kill
      final highDamageActions = availableActions.where((action) => 
        action.baseDamage > 60
      ).toList();
      
      if (highDamageActions.isNotEmpty) {
        return highDamageActions[math.Random().nextInt(highDamageActions.length)];
      }
    }
    
    // Use healing if low health
    if (aiParticipant.currentHP < aiParticipant.maxHP * 0.3) {
      final healingActions = availableActions.where((action) => 
        action.properties['healing'] == true
      ).toList();
      
      if (healingActions.isNotEmpty) {
        return healingActions[math.Random().nextInt(healingActions.length)];
      }
    }
    
    // Random selection with preference for higher priority actions
    final weightedActions = <BattleAction>[];
    for (final action in availableActions) {
      final weight = action.priority + 1;
      for (int i = 0; i < weight; i++) {
        weightedActions.add(action);
      }
    }
    
    return weightedActions[math.Random().nextInt(weightedActions.length)];
  }

  // Combo system
  static List<BattleAction> getAvailableCombos(List<BattleAction> recentActions) {
    final availableCombos = <BattleAction>[];
    
    for (final action in epicActions.where((a) => a.isCombo)) {
      bool canPerform = true;
      
      for (final requirement in action.comboRequirements) {
        bool hasRequirement = false;
        
        for (final recentAction in recentActions) {
          if (recentAction.name.toLowerCase().contains(requirement.toLowerCase()) ||
              recentAction.element.name.toLowerCase().contains(requirement.toLowerCase())) {
            hasRequirement = true;
            break;
          }
        }
        
        if (!hasRequirement) {
          canPerform = false;
          break;
        }
      }
      
      if (canPerform) {
        availableCombos.add(action);
      }
    }
    
    return availableCombos;
  }

  // Battle rewards calculation
  static Map<String, dynamic> calculateBattleRewards(
    EnhancedBattle battle,
    BattleParticipant winner,
  ) {
    final rewards = <String, dynamic>{};
    
    // Base XP and gold
    int baseXP = 100;
    int baseGold = 50;
    
    // Multiply by opponent levels
    for (final participant in battle.participants) {
      if (participant.id != winner.id) {
        baseXP += participant.level * 15;
        baseGold += participant.level * 10;
      }
    }
    
    // Battle length bonus (longer battles = more rewards)
    final battleDuration = battle.endTime?.difference(battle.startTime) ?? Duration.zero;
    final durationBonus = (battleDuration.inMinutes * 0.1).clamp(0.0, 1.0);
    
    rewards['xp'] = (baseXP * (1 + durationBonus)).round();
    rewards['gold'] = (baseGold * (1 + durationBonus)).round();
    
    // Card rewards based on battle performance
    final cardRewards = <String>[];
    
    // Always get a random common card
    cardRewards.add('victory_token');
    
    // Chance for rare cards based on performance
    if (winner.currentHP > winner.maxHP * 0.5) {
      cardRewards.add('battle_mastery');
    }
    
    // Elemental-based rewards
    switch (winner.primaryElement) {
      case ElementType.fire:
        cardRewards.add('flame_essence');
        break;
      case ElementType.water:
        cardRewards.add('water_crystal');
        break;
      case ElementType.lightning:
        cardRewards.add('storm_core');
        break;
      case ElementType.shadow:
        cardRewards.add('shadow_shard');
        break;
      case ElementType.light:
        cardRewards.add('light_fragment');
        break;
      default:
        cardRewards.add('battle_trophy');
    }
    
    rewards['cards'] = cardRewards;
    
    return rewards;
  }

  // Create epic boss battles
  static EnhancedBattle createDragonBattle(BattleParticipant player) {
    final dragon = BattleParticipant(
      name: 'Ancient Fire Dragon',
      level: 50,
      primaryElement: ElementType.fire,
      secondaryElement: ElementType.shadow,
      stats: {
        'hp': 1000,
        'max_hp': 1000,
        'mp': 200,
        'max_mp': 200,
        'attack': 80,
        'defense': 60,
        'speed': 30,
        'luck': 20,
      },
      isAI: true,
    );
    
    return EnhancedBattle(
      name: 'Battle with the Ancient Dragon',
      description: 'Face the legendary dragon in an epic battle that will test all your skills!',
      participants: [player, dragon],
      phase: BattlePhase.preparation,
      rewards: {
        'xp': 2000,
        'gold': 1000,
        'cards': ['ancient_dragon', 'dragon_scale_armor', 'flame_of_eternity'],
      },
    );
  }

  // Create arena battles
  static EnhancedBattle createArenaBattle(BattleParticipant player) {
    final opponent = BattleParticipant(
      name: 'Arena Champion',
      level: player.level + math.Random().nextInt(5),
      primaryElement: ElementType.values[math.Random().nextInt(ElementType.values.length)],
      stats: {
        'hp': 100 + (player.level * 10),
        'max_hp': 100 + (player.level * 10),
        'mp': 50 + (player.level * 5),
        'max_mp': 50 + (player.level * 5),
        'attack': 20 + (player.level * 2),
        'defense': 15 + (player.level * 2),
        'speed': 10 + player.level,
        'luck': 5 + player.level,
      },
      isAI: true,
    );
    
    return EnhancedBattle(
      name: 'Arena Championship',
      description: 'Prove your worth in the arena against skilled opponents!',
      participants: [player, opponent],
      phase: BattlePhase.preparation,
      rewards: {
        'xp': 150 + (player.level * 10),
        'gold': 100 + (player.level * 5),
        'cards': ['champion_medal', 'arena_trophy'],
      },
    );
  }
}