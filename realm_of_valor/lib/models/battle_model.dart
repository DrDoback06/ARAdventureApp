import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'card_model.dart';
import 'character_model.dart';

part 'battle_model.g.dart';

enum BattleType {
  pvp,
  pve,
  tournament,
}

enum BattleStatus {
  waiting,
  active,
  paused,
  finished,
  abandoned,
}

enum ActionCardType {
  buff,
  debuff,
  damage,
  heal,
  skip,
  counter,
  special,
  physical,
  spell,
  support,
}

@JsonSerializable()
class ActionCard {
  final String id;
  final String name;
  final String description;
  final ActionCardType type;
  final String effect;
  final int cost;
  final String physicalRequirement;
  final CardRarity rarity;
  final Map<String, dynamic> properties;

  ActionCard({
    String? id,
    required this.name,
    required this.description,
    required this.type,
    required this.effect,
    this.cost = 0,
    this.physicalRequirement = '',
    this.rarity = CardRarity.common,
    Map<String, dynamic>? properties,
  })  : id = id ?? const Uuid().v4(),
        properties = properties ?? <String, dynamic>{};

  factory ActionCard.fromJson(Map<String, dynamic> json) =>
      _$ActionCardFromJson(json);
  Map<String, dynamic> toJson() => _$ActionCardToJson(this);

  // Predefined action cards
  static List<ActionCard> getDefaultActionDeck() {
    return [
      ActionCard(
        name: 'Push-up Power',
        description: 'Perform 5 push-ups before attacking to gain +5 damage',
        type: ActionCardType.physical,
        effect: 'damage_bonus:5',
        physicalRequirement: 'push_ups:5',
      ),
      ActionCard(
        name: 'Double Strike',
        description: 'Deal double damage this turn',
        type: ActionCardType.buff,
        effect: 'double_damage',
      ),
      ActionCard(
        name: 'Weakened',
        description: 'Deal half damage this turn',
        type: ActionCardType.debuff,
        effect: 'half_damage',
      ),
      ActionCard(
        name: 'Skip Turn',
        description: 'Miss your next turn',
        type: ActionCardType.skip,
        effect: 'skip_turn',
      ),
      ActionCard(
        name: 'Counter Attack',
        description: 'Counter your opponent\'s next attack',
        type: ActionCardType.counter,
        effect: 'counter_next',
      ),
      ActionCard(
        name: 'Stop Action',
        description: 'Cancel any action as your opponent plays it',
        type: ActionCardType.special,
        effect: 'cancel_action',
      ),
      ActionCard(
        name: 'Healing Potion',
        description: 'Restore 20 health',
        type: ActionCardType.heal,
        effect: 'heal:20',
      ),
      ActionCard(
        name: 'Mana Surge',
        description: 'Gain 10 extra mana this turn',
        type: ActionCardType.buff,
        effect: 'mana_bonus:10',
      ),
    ];
  }
}

@JsonSerializable()
class BattlePlayer {
  final String id;
  final String name;
  final GameCharacter character;
  final List<ActionCard> hand;
  final List<ActionCard> actionDeck;
  final List<GameCard> activeSkills;
  final int currentHealth;
  final int currentMana;
  final int maxHealth;
  final int maxMana;
  final bool isReady;
  final bool isActive;
  final Map<String, dynamic> statusEffects;

  BattlePlayer({
    String? id,
    required this.name,
    required this.character,
    List<ActionCard>? hand,
    List<ActionCard>? actionDeck,
    List<GameCard>? activeSkills,
    int? currentHealth,
    int? currentMana,
    int? maxHealth,
    int? maxMana,
    this.isReady = false,
    this.isActive = false,
    Map<String, dynamic>? statusEffects,
  })  : id = id ?? const Uuid().v4(),
        hand = hand ?? <ActionCard>[],
        actionDeck = actionDeck ?? ActionCard.getDefaultActionDeck(),
        activeSkills = activeSkills ?? <GameCard>[],
        currentHealth = currentHealth ?? character.maxHealth,
        currentMana = currentMana ?? character.maxMana,
        maxHealth = maxHealth ?? character.maxHealth,
        maxMana = maxMana ?? character.maxMana,
        statusEffects = statusEffects ?? <String, dynamic>{};

  factory BattlePlayer.fromJson(Map<String, dynamic> json) =>
      _$BattlePlayerFromJson(json);
  Map<String, dynamic> toJson() => _$BattlePlayerToJson(this);

  BattlePlayer copyWith({
    String? id,
    String? name,
    GameCharacter? character,
    List<ActionCard>? hand,
    List<ActionCard>? actionDeck,
    List<GameCard>? activeSkills,
    int? currentHealth,
    int? currentMana,
    int? maxHealth,
    int? maxMana,
    bool? isReady,
    bool? isActive,
    Map<String, dynamic>? statusEffects,
  }) {
    return BattlePlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      character: character ?? this.character,
      hand: hand ?? this.hand,
      actionDeck: actionDeck ?? this.actionDeck,
      activeSkills: activeSkills ?? this.activeSkills,
      currentHealth: currentHealth ?? this.currentHealth,
      currentMana: currentMana ?? this.currentMana,
      maxHealth: maxHealth ?? this.maxHealth,
      maxMana: maxMana ?? this.maxMana,
      isReady: isReady ?? this.isReady,
      isActive: isActive ?? this.isActive,
      statusEffects: statusEffects ?? this.statusEffects,
    );
  }
}

@JsonSerializable()
class BattleLog {
  final String id;
  final String playerId;
  final String action;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  BattleLog({
    String? id,
    required this.playerId,
    required this.action,
    required this.description,
    DateTime? timestamp,
    Map<String, dynamic>? data,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now(),
        data = data ?? <String, dynamic>{};

  factory BattleLog.fromJson(Map<String, dynamic> json) =>
      _$BattleLogFromJson(json);
  Map<String, dynamic> toJson() => _$BattleLogToJson(this);
}

@JsonSerializable()
class Battle {
  final String id;
  final String name;
  final BattleType type;
  final BattleStatus status;
  final List<BattlePlayer> players;
  final List<BattleLog> battleLog;
  final int currentTurn;
  final String currentPlayerId;
  final int maxTurns;
  final DateTime startTime;
  final DateTime? endTime;
  final String? winnerId;
  final Map<String, dynamic> battleSettings;

  Battle({
    String? id,
    required this.name,
    required this.type,
    this.status = BattleStatus.waiting,
    List<BattlePlayer>? players,
    List<BattleLog>? battleLog,
    this.currentTurn = 0,
    this.currentPlayerId = '',
    this.maxTurns = 50,
    DateTime? startTime,
    this.endTime,
    this.winnerId,
    Map<String, dynamic>? battleSettings,
  })  : id = id ?? const Uuid().v4(),
        players = players ?? <BattlePlayer>[],
        battleLog = battleLog ?? <BattleLog>[],
        startTime = startTime ?? DateTime.now(),
        battleSettings = battleSettings ?? <String, dynamic>{};

  factory Battle.fromJson(Map<String, dynamic> json) => _$BattleFromJson(json);
  Map<String, dynamic> toJson() => _$BattleToJson(this);

  Battle copyWith({
    String? id,
    String? name,
    BattleType? type,
    BattleStatus? status,
    List<BattlePlayer>? players,
    List<BattleLog>? battleLog,
    int? currentTurn,
    String? currentPlayerId,
    int? maxTurns,
    DateTime? startTime,
    DateTime? endTime,
    String? winnerId,
    Map<String, dynamic>? battleSettings,
  }) {
    return Battle(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      players: players ?? this.players,
      battleLog: battleLog ?? this.battleLog,
      currentTurn: currentTurn ?? this.currentTurn,
      currentPlayerId: currentPlayerId ?? this.currentPlayerId,
      maxTurns: maxTurns ?? this.maxTurns,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      winnerId: winnerId ?? this.winnerId,
      battleSettings: battleSettings ?? this.battleSettings,
    );
  }
}

@JsonSerializable()
class EnemyCard {
  final String id;
  final String name;
  final String description;
  final int health;
  final int mana;
  final int attackPower;
  final int defense;
  final List<String> abilities;
  final List<String> weaknesses;
  final String imageUrl;
  final CardRarity rarity;
  final Map<String, dynamic> battleActions;

  EnemyCard({
    String? id,
    required this.name,
    required this.description,
    required this.health,
    required this.mana,
    required this.attackPower,
    required this.defense,
    List<String>? abilities,
    List<String>? weaknesses,
    this.imageUrl = '',
    this.rarity = CardRarity.common,
    Map<String, dynamic>? battleActions,
  })  : id = id ?? const Uuid().v4(),
        abilities = abilities ?? <String>[],
        weaknesses = weaknesses ?? <String>[],
        battleActions = battleActions ?? <String, dynamic>{};

  factory EnemyCard.fromJson(Map<String, dynamic> json) =>
      _$EnemyCardFromJson(json);
  Map<String, dynamic> toJson() => _$EnemyCardToJson(this);
}

class AttackCard extends ActionCard {
  final int baseDamage;
  final String characterId;
  final Map<String, int> damageModifiers; // equipment, buffs, etc.
  
  AttackCard({
    required String characterId,
    required int baseDamage,
    Map<String, int>? damageModifiers,
    String? id,
  }) : baseDamage = baseDamage,
       characterId = characterId,
       damageModifiers = damageModifiers ?? <String, int>{},
       super(
         id: id,
         name: 'Attack',
         description: 'Basic physical attack',
         type: ActionCardType.damage,
         effect: 'physical_attack',
         cost: 0,
         rarity: CardRarity.common,
       );

  int get totalDamage {
    int total = baseDamage;
    damageModifiers.forEach((key, value) {
      total += value;
    });
    return total;
  }

  // TODO: Add JSON serialization when build_runner is available
  // factory AttackCard.fromJson(Map<String, dynamic> json) =>
  //     _$AttackCardFromJson(json);
  // Map<String, dynamic> toJson() => _$AttackCardToJson(this);
}

class SkillCard extends ActionCard {
  final String skillId;
  final String characterId;
  final int baseManaCost;
  final int baseDamage;
  final String skillType; // 'active', 'passive', 'ultimate'
  final int cooldown;
  final int currentCooldown;
  final Map<String, int> skillModifiers;
  
  SkillCard({
    required String skillId,
    required String characterId,
    required String name,
    required String description,
    required int baseManaCost,
    required int baseDamage,
    required String skillType,
    this.cooldown = 0,
    this.currentCooldown = 0,
    Map<String, int>? skillModifiers,
    String? id,
  }) : skillId = skillId,
       characterId = characterId,
       baseManaCost = baseManaCost,
       baseDamage = baseDamage,
       skillType = skillType,
       skillModifiers = skillModifiers ?? <String, int>{},
       super(
         id: id,
         name: name,
         description: description,
         type: ActionCardType.spell,
         effect: 'skill_${skillType}',
         cost: baseManaCost,
         rarity: CardRarity.rare,
       );

  int get totalManaCost {
    int total = baseManaCost;
    skillModifiers.forEach((key, value) {
      if (key.startsWith('mana_')) {
        total += value;
      }
    });
    return total;
  }

  int get totalDamage {
    int total = baseDamage;
    skillModifiers.forEach((key, value) {
      if (key.startsWith('damage_')) {
        total += value;
      }
    });
    return total;
  }

  bool get isOnCooldown => currentCooldown > 0;

  // TODO: Add JSON serialization when build_runner is available
  // factory SkillCard.fromJson(Map<String, dynamic> json) =>
  //     _$SkillCardFromJson(json);
  // Map<String, dynamic> toJson() => _$SkillCardToJson(this);
}