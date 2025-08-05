import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'dart:math' as math;
import 'adventure_system.dart';

part 'battle_system.g.dart';

// Enhanced enums for battle system
enum BattleType {
  pve, // Player vs Environment (AI)
  pvp, // Player vs Player
  adventure, // Adventure mode encounters
  tournament, // Competitive tournaments
  practice, // Practice mode
  spectate, // Spectating battles
}

enum BattlePhase {
  preparation, // Deck selection and setup
  mulligan, // Initial hand mulligan
  gameStart, // Game initialization
  playerTurn, // Active player's turn
  opponentTurn, // Opponent's turn
  battleEnd, // Battle conclusion
  rewards, // Reward distribution
}

enum TurnPhase {
  draw, // Draw phase
  planning, // Planning and strategy
  action, // Play cards and actions
  combat, // Combat resolution
  end, // End turn
}

enum CardType {
  creature, // Summons with attack/defense
  spell, // Instant effects
  enchantment, // Ongoing effects
  artifact, // Equipment/items
  skill, // Character abilities
  combo, // Multi-card combinations
}

enum TargetType {
  none, // No target required
  self, // Target self
  opponent, // Target opponent
  creature, // Target any creature
  ownCreature, // Target own creature
  enemyCreature, // Target enemy creature
  all, // Target all units
}

enum DamageType {
  physical, // Reduced by armor
  magical, // Reduced by magic resistance
  pure, // Cannot be reduced
  fire, // Fire damage
  ice, // Ice damage
  lightning, // Lightning damage
  poison, // Poison damage
  holy, // Holy damage
  shadow, // Shadow damage
}

enum CharacterClass {
  warrior, // Strength-based fighter
  mage, // Intelligence-based caster
  rogue, // Dexterity-based assassin
  paladin, // Balanced holy warrior
  necromancer, // Death magic specialist
  barbarian, // Savage fighter
  sorceress, // Elemental specialist
  amazon, // Ranged specialist
  druid, // Nature magic
  monk, // Martial arts master
}

// Core character stats (Diablo II inspired)
@JsonSerializable()
class CharacterStats {
  final int strength; // Increases physical damage and carrying capacity
  final int dexterity; // Increases accuracy and defense
  final int intelligence; // Increases mana and spell damage
  final int vitality; // Increases health
  final int energy; // Increases mana pool
  final int luck; // Critical hit chance and rare drops
  
  // Derived stats
  final int health;
  final int mana;
  final int physicalDamage;
  final int magicalDamage;
  final int armor;
  final int magicResistance;
  final int criticalChance;
  final int dodgeChance;

  CharacterStats({
    required this.strength,
    required this.dexterity,
    required this.intelligence,
    required this.vitality,
    required this.energy,
    required this.luck,
    int? health,
    int? mana,
    int? physicalDamage,
    int? magicalDamage,
    int? armor,
    int? magicResistance,
    int? criticalChance,
    int? dodgeChance,
  }) : 
    health = health ?? (vitality * 10 + 50),
    mana = mana ?? (intelligence * 5 + energy * 3 + 25),
    physicalDamage = physicalDamage ?? (strength ~/ 2),
    magicalDamage = magicalDamage ?? (intelligence ~/ 3),
    armor = armor ?? (dexterity ~/ 4),
    magicResistance = magicResistance ?? (intelligence ~/ 5),
    criticalChance = criticalChance ?? (luck ~/ 10),
    dodgeChance = dodgeChance ?? (dexterity ~/ 15);

  factory CharacterStats.fromJson(Map<String, dynamic> json) =>
      _$CharacterStatsFromJson(json);
  Map<String, dynamic> toJson() => _$CharacterStatsToJson(this);

  // Calculate effective damage after reductions
  int calculateDamage(int baseDamage, DamageType damageType, CharacterStats target) {
    double reduction = 0.0;
    
    switch (damageType) {
      case DamageType.physical:
        reduction = target.armor / (target.armor + 100.0);
        break;
      case DamageType.magical:
      case DamageType.fire:
      case DamageType.ice:
      case DamageType.lightning:
      case DamageType.poison:
      case DamageType.holy:
      case DamageType.shadow:
        reduction = target.magicResistance / (target.magicResistance + 100.0);
        break;
      case DamageType.pure:
        reduction = 0.0;
        break;
    }
    
    final effectiveDamage = (baseDamage * (1.0 - reduction)).round();
    return math.max(1, effectiveDamage); // Minimum 1 damage
  }

  // Check for critical hit
  bool rollCriticalHit() {
    return math.Random().nextInt(100) < criticalChance;
  }

  // Check for dodge
  bool rollDodge() {
    return math.Random().nextInt(100) < dodgeChance;
  }
}

// Enhanced battle card with character integration
@JsonSerializable()
class BattleCard {
  final String id;
  final String name;
  final String description;
  final CardType type;
  final int manaCost;
  final int? attack;
  final int? defense;
  final int? health;
  final List<DamageType> damageTypes;
  final TargetType targetType;
  final List<String> abilities;
  final List<String> keywords;
  final String? imageUrl;
  final Map<String, dynamic> effects;
  final int rarity; // 1-5 (common to legendary)
  final List<CharacterClass> requiredClasses;
  final Map<String, int> statRequirements; // stat name -> minimum value
  final bool isChanneled; // Requires multiple turns
  final int? channelTurns;
  final String artist;
  final String flavorText;

  BattleCard({
    String? id,
    required this.name,
    required this.description,
    required this.type,
    required this.manaCost,
    this.attack,
    this.defense,
    this.health,
    List<DamageType>? damageTypes,
    this.targetType = TargetType.none,
    List<String>? abilities,
    List<String>? keywords,
    this.imageUrl,
    Map<String, dynamic>? effects,
    this.rarity = 1,
    List<CharacterClass>? requiredClasses,
    Map<String, int>? statRequirements,
    this.isChanneled = false,
    this.channelTurns,
    this.artist = 'Unknown Artist',
    this.flavorText = '',
  }) : id = id ?? const Uuid().v4(),
       damageTypes = damageTypes ?? [DamageType.physical],
       abilities = abilities ?? [],
       keywords = keywords ?? [],
       effects = effects ?? {},
       requiredClasses = requiredClasses ?? [],
       statRequirements = statRequirements ?? {};

  factory BattleCard.fromJson(Map<String, dynamic> json) =>
      _$BattleCardFromJson(json);
  Map<String, dynamic> toJson() => _$BattleCardToJson(this);

  // Check if card can be played by character
  bool canBePlayedBy(CharacterStats stats, CharacterClass characterClass, int availableMana) {
    // Check mana cost
    if (manaCost > availableMana) return false;
    
    // Check class requirements
    if (requiredClasses.isNotEmpty && !requiredClasses.contains(characterClass)) {
      return false;
    }
    
    // Check stat requirements
    for (final requirement in statRequirements.entries) {
      int characterStat = 0;
      switch (requirement.key.toLowerCase()) {
        case 'strength':
          characterStat = stats.strength;
          break;
        case 'dexterity':
          characterStat = stats.dexterity;
          break;
        case 'intelligence':
          characterStat = stats.intelligence;
          break;
        case 'vitality':
          characterStat = stats.vitality;
          break;
        case 'energy':
          characterStat = stats.energy;
          break;
        case 'luck':
          characterStat = stats.luck;
          break;
      }
      
      if (characterStat < requirement.value) return false;
    }
    
    return true;
  }

  // Calculate effective damage based on character stats
  int calculateEffectiveDamage(CharacterStats casterStats) {
    if (attack == null) return 0;
    
    int baseDamage = attack!;
    
    // Add character stat bonuses
    if (damageTypes.contains(DamageType.physical)) {
      baseDamage += casterStats.physicalDamage;
    }
    
    if (damageTypes.any((type) => type != DamageType.physical && type != DamageType.pure)) {
      baseDamage += casterStats.magicalDamage;
    }
    
    // Apply critical hit multiplier if applicable
    if (casterStats.rollCriticalHit()) {
      baseDamage = (baseDamage * 1.5).round();
    }
    
    return baseDamage;
  }

  // Get rarity name
  String get rarityName {
    switch (rarity) {
      case 1: return 'Common';
      case 2: return 'Uncommon';
      case 3: return 'Rare';
      case 4: return 'Epic';
      case 5: return 'Legendary';
      default: return 'Unknown';
    }
  }
}

// Creature on the battlefield
@JsonSerializable()
class BattleCreature {
  final String id;
  final BattleCard card;
  int currentHealth;
  int currentAttack;
  int currentDefense;
  final List<String> activeEffects;
  final Map<String, int> statusEffects; // effect name -> turns remaining
  final bool canAttack;
  final bool canDefend;
  final String ownerId;
  final int turnSummoned;

  BattleCreature({
    String? id,
    required this.card,
    int? currentHealth,
    int? currentAttack,
    int? currentDefense,
    List<String>? activeEffects,
    Map<String, int>? statusEffects,
    this.canAttack = true,
    this.canDefend = true,
    required this.ownerId,
    required this.turnSummoned,
  }) : id = id ?? const Uuid().v4(),
       currentHealth = currentHealth ?? card.health ?? 1,
       currentAttack = currentAttack ?? card.attack ?? 0,
       currentDefense = currentDefense ?? card.defense ?? 0,
       activeEffects = activeEffects ?? [],
       statusEffects = statusEffects ?? {};

  factory BattleCreature.fromJson(Map<String, dynamic> json) =>
      _$BattleCreatureFromJson(json);
  Map<String, dynamic> toJson() => _$BattleCreatureToJson(this);

  bool get isDead => currentHealth <= 0;
  bool get canActThisTurn => canAttack && !hasStatusEffect('stunned');

  bool hasStatusEffect(String effect) => statusEffects.containsKey(effect);

  void takeDamage(int damage) {
    currentHealth = math.max(0, currentHealth - damage);
  }

  void heal(int amount) {
    final maxHealth = card.health ?? 1;
    currentHealth = math.min(maxHealth, currentHealth + amount);
  }

  void addStatusEffect(String effect, int duration) {
    statusEffects[effect] = duration;
  }

  void removeStatusEffect(String effect) {
    statusEffects.remove(effect);
  }

  void updateStatusEffects() {
    final expiredEffects = <String>[];
    for (final entry in statusEffects.entries) {
      statusEffects[entry.key] = entry.value - 1;
      if (statusEffects[entry.key]! <= 0) {
        expiredEffects.add(entry.key);
      }
    }
    for (final effect in expiredEffects) {
      statusEffects.remove(effect);
    }
  }
}

// Player in battle
@JsonSerializable()
class BattlePlayer {
  final String id;
  final String name;
  final CharacterClass characterClass;
  final CharacterStats stats;
  int currentHealth;
  int currentMana;
  final List<BattleCard> deck;
  final List<BattleCard> hand;
  final List<BattleCard> graveyard;
  final List<BattleCreature> battlefield;
  final List<BattleCard> exile;
  final Map<String, dynamic> equipment; // equipped items affecting stats
  final Map<String, int> resources; // additional resources like combo points
  bool isActive;
  int turnCount;

  BattlePlayer({
    required this.id,
    required this.name,
    required this.characterClass,
    required this.stats,
    int? currentHealth,
    int? currentMana,
    List<BattleCard>? deck,
    List<BattleCard>? hand,
    List<BattleCard>? graveyard,
    List<BattleCreature>? battlefield,
    List<BattleCard>? exile,
    Map<String, dynamic>? equipment,
    Map<String, int>? resources,
    this.isActive = false,
    this.turnCount = 0,
  }) : currentHealth = currentHealth ?? stats.health,
       currentMana = currentMana ?? stats.mana,
       deck = deck ?? [],
       hand = hand ?? [],
       graveyard = graveyard ?? [],
       battlefield = battlefield ?? [],
       exile = exile ?? [],
       equipment = equipment ?? {},
       resources = resources ?? {};

  factory BattlePlayer.fromJson(Map<String, dynamic> json) =>
      _$BattlePlayerFromJson(json);
  Map<String, dynamic> toJson() => _$BattlePlayerToJson(this);

  bool get isDead => currentHealth <= 0;
  bool get canDrawCard => deck.isNotEmpty && hand.length < 10; // Max hand size
  int get handSize => hand.length;
  int get deckSize => deck.length;
  int get battlefieldSize => battlefield.length;

  // Draw card from deck
  BattleCard? drawCard() {
    if (deck.isEmpty) return null;
    
    final card = deck.removeAt(0);
    if (hand.length < 10) {
      hand.add(card);
      return card;
    } else {
      // Hand is full, card is discarded
      graveyard.add(card);
      return null;
    }
  }

  // Play card from hand
  bool playCard(BattleCard card, {dynamic target}) {
    if (!hand.contains(card)) return false;
    if (!card.canBePlayedBy(stats, characterClass, currentMana)) return false;
    
    hand.remove(card);
    currentMana -= card.manaCost;
    
    // Handle different card types
    switch (card.type) {
      case CardType.creature:
        final creature = BattleCreature(
          card: card,
          ownerId: id,
          turnSummoned: turnCount,
        );
        battlefield.add(creature);
        break;
      
      case CardType.spell:
        // Spell effects are handled by battle engine
        graveyard.add(card);
        break;
      
      case CardType.enchantment:
        // Enchantments stay on battlefield as ongoing effects
        // Implementation depends on specific enchantment
        graveyard.add(card);
        break;
      
      default:
        graveyard.add(card);
        break;
    }
    
    return true;
  }

  // Take damage with armor calculation
  void takeDamage(int damage, DamageType damageType) {
    final effectiveDamage = stats.calculateDamage(damage, damageType, stats);
    
    // Check for dodge
    if (stats.rollDodge()) {
      return; // Damage dodged
    }
    
    currentHealth = math.max(0, currentHealth - effectiveDamage);
  }

  // Heal player
  void heal(int amount) {
    currentHealth = math.min(stats.health, currentHealth + amount);
  }

  // Restore mana
  void restoreMana(int amount) {
    currentMana = math.min(stats.mana, currentMana + amount);
  }

  // Start new turn
  void startTurn() {
    isActive = true;
    turnCount++;
    
    // Restore mana (partial)
    final manaGain = math.min(5 + (turnCount ~/ 3), stats.mana ~/ 4);
    restoreMana(manaGain);
    
    // Draw card
    drawCard();
    
    // Update creatures on battlefield
    for (final creature in battlefield) {
      creature.updateStatusEffects();
    }
    
    // Remove dead creatures
    battlefield.removeWhere((creature) {
      if (creature.isDead) {
        graveyard.add(creature.card);
        return true;
      }
      return false;
    });
  }

  // End turn
  void endTurn() {
    isActive = false;
  }

  // Calculate total power on battlefield
  int get totalBattlefieldPower {
    return battlefield.fold(0, (sum, creature) => sum + creature.currentAttack);
  }

  // Get all available targets for spells/abilities
  List<dynamic> getAvailableTargets(TargetType targetType, BattlePlayer opponent) {
    final targets = <dynamic>[];
    
    switch (targetType) {
      case TargetType.self:
        targets.add(this);
        break;
      case TargetType.opponent:
        targets.add(opponent);
        break;
      case TargetType.creature:
        targets.addAll(battlefield);
        targets.addAll(opponent.battlefield);
        break;
      case TargetType.ownCreature:
        targets.addAll(battlefield);
        break;
      case TargetType.enemyCreature:
        targets.addAll(opponent.battlefield);
        break;
      case TargetType.all:
        targets.add(this);
        targets.add(opponent);
        targets.addAll(battlefield);
        targets.addAll(opponent.battlefield);
        break;
      case TargetType.none:
        break;
    }
    
    return targets;
  }
}

// Battle state management
@JsonSerializable()
class BattleState {
  final String id;
  final BattleType type;
  BattlePhase phase;
  TurnPhase turnPhase;
  final BattlePlayer player1;
  final BattlePlayer player2;
  String activePlayerId;
  int turnNumber;
  final List<String> battleLog;
  final Map<String, dynamic> globalEffects;
  final DateTime startTime;
  DateTime? endTime;
  String? winnerId;
  final Map<String, dynamic> battleConditions; // Special battle rules
  final Map<String, dynamic> rewards;

  BattleState({
    String? id,
    required this.type,
    this.phase = BattlePhase.preparation,
    this.turnPhase = TurnPhase.draw,
    required this.player1,
    required this.player2,
    String? activePlayerId,
    this.turnNumber = 1,
    List<String>? battleLog,
    Map<String, dynamic>? globalEffects,
    DateTime? startTime,
    this.endTime,
    this.winnerId,
    Map<String, dynamic>? battleConditions,
    Map<String, dynamic>? rewards,
  }) : id = id ?? const Uuid().v4(),
       activePlayerId = activePlayerId ?? player1.id,
       battleLog = battleLog ?? [],
       globalEffects = globalEffects ?? {},
       startTime = startTime ?? DateTime.now(),
       battleConditions = battleConditions ?? {},
       rewards = rewards ?? {};

  factory BattleState.fromJson(Map<String, dynamic> json) =>
      _$BattleStateFromJson(json);
  Map<String, dynamic> toJson() => _$BattleStateToJson(this);

  BattlePlayer get activePlayer => activePlayerId == player1.id ? player1 : player2;
  BattlePlayer get inactivePlayer => activePlayerId == player1.id ? player2 : player1;
  
  bool get isGameOver => winnerId != null || player1.isDead || player2.isDead;
  Duration get battleDuration => (endTime ?? DateTime.now()).difference(startTime);

  void addLogEntry(String entry) {
    battleLog.add('Turn $turnNumber: $entry');
  }

  void switchActivePlayer() {
    inactivePlayer.endTurn();
    activePlayerId = inactivePlayer.id;
    activePlayer.startTurn();
  }

  void nextTurn() {
    if (activePlayerId == player2.id) {
      turnNumber++;
    }
    switchActivePlayer();
  }

  void endBattle(String? winnerId) {
    this.winnerId = winnerId;
    phase = BattlePhase.battleEnd;
    endTime = DateTime.now();
    
    // Calculate rewards
    _calculateRewards();
  }

  void _calculateRewards() {
    final winner = winnerId == player1.id ? player1 : player2;
    final loser = winnerId == player1.id ? player2 : player1;
    
    // Base rewards
    final baseXP = 100;
    final baseGold = 50;
    
    // Victory bonuses
    rewards['winner'] = {
      'experience': (baseXP * 1.5).round(),
      'gold': (baseGold * 1.5).round(),
      'cards': _generateCardRewards(winner, true),
      'achievements': _checkAchievements(winner, true),
    };
    
    // Participation rewards
    rewards['loser'] = {
      'experience': (baseXP * 0.7).round(),
      'gold': (baseGold * 0.5).round(),
      'cards': _generateCardRewards(loser, false),
      'achievements': _checkAchievements(loser, false),
    };
  }

  List<String> _generateCardRewards(BattlePlayer player, bool isWinner) {
    final cardRewards = <String>[];
    
    if (isWinner) {
      // Winners get better card rewards
      cardRewards.add('random_rare_card');
      if (math.Random().nextDouble() < 0.1) {
        cardRewards.add('random_epic_card');
      }
    } else {
      // Losers get participation rewards
      cardRewards.add('random_common_card');
      if (math.Random().nextDouble() < 0.3) {
        cardRewards.add('random_uncommon_card');
      }
    }
    
    return cardRewards;
  }

  List<String> _checkAchievements(BattlePlayer player, bool isWinner) {
    final achievements = <String>[];
    
    if (isWinner) {
      achievements.add('victory_${type.toString()}');
      
      // Special achievements
      if (player.totalBattlefieldPower >= 20) {
        achievements.add('overwhelming_force');
      }
      
      if (battleDuration.inMinutes <= 5) {
        achievements.add('swift_victory');
      }
      
      if (player.currentHealth == player.stats.health) {
        achievements.add('flawless_victory');
      }
    }
    
    // Participation achievements
    if (player.graveyard.length >= 10) {
      achievements.add('card_master');
    }
    
    if (player.battlefield.length >= 5) {
      achievements.add('army_commander');
    }
    
    return achievements;
  }
}

// Matchmaking system
@JsonSerializable()
class MatchmakingRequest {
  final String playerId;
  final String playerName;
  final int playerRating;
  final CharacterClass characterClass;
  final int characterLevel;
  final BattleType preferredBattleType;
  final List<String> friendIds; // For friend matches
  final DateTime requestTime;
  final Map<String, dynamic> preferences;

  MatchmakingRequest({
    required this.playerId,
    required this.playerName,
    required this.playerRating,
    required this.characterClass,
    required this.characterLevel,
    required this.preferredBattleType,
    List<String>? friendIds,
    DateTime? requestTime,
    Map<String, dynamic>? preferences,
  }) : friendIds = friendIds ?? [],
       requestTime = requestTime ?? DateTime.now(),
       preferences = preferences ?? {};

  factory MatchmakingRequest.fromJson(Map<String, dynamic> json) =>
      _$MatchmakingRequestFromJson(json);
  Map<String, dynamic> toJson() => _$MatchmakingRequestToJson(this);
}

@JsonSerializable()
class MatchmakingResult {
  final String matchId;
  final String player1Id;
  final String player2Id;
  final BattleType battleType;
  final DateTime matchTime;
  final Map<String, dynamic> battleSettings;

  MatchmakingResult({
    required this.matchId,
    required this.player1Id,
    required this.player2Id,
    required this.battleType,
    DateTime? matchTime,
    Map<String, dynamic>? battleSettings,
  }) : matchTime = matchTime ?? DateTime.now(),
       battleSettings = battleSettings ?? {};

  factory MatchmakingResult.fromJson(Map<String, dynamic> json) =>
      _$MatchmakingResultFromJson(json);
  Map<String, dynamic> toJson() => _$MatchmakingResultToJson(this);
}

// Card effects and abilities system
abstract class CardEffect {
  final String name;
  final String description;
  final Map<String, dynamic> parameters;

  CardEffect({
    required this.name,
    required this.description,
    Map<String, dynamic>? parameters,
  }) : parameters = parameters ?? {};

  void execute(BattleState battleState, BattlePlayer caster, dynamic target);
}

class DamageEffect extends CardEffect {
  DamageEffect({
    required int damage,
    required DamageType damageType,
  }) : super(
    name: 'Damage',
    description: 'Deal $damage ${damageType.toString()} damage',
    parameters: {'damage': damage, 'damageType': damageType},
  );

  @override
  void execute(BattleState battleState, BattlePlayer caster, dynamic target) {
    final damage = parameters['damage'] as int;
    final damageType = parameters['damageType'] as DamageType;
    
    if (target is BattlePlayer) {
      target.takeDamage(damage, damageType);
      battleState.addLogEntry('${caster.name} deals $damage damage to ${target.name}');
    } else if (target is BattleCreature) {
      target.takeDamage(damage);
      battleState.addLogEntry('${caster.name} deals $damage damage to ${target.card.name}');
    }
  }
}

class HealEffect extends CardEffect {
  HealEffect({required int amount}) : super(
    name: 'Heal',
    description: 'Restore $amount health',
    parameters: {'amount': amount},
  );

  @override
  void execute(BattleState battleState, BattlePlayer caster, dynamic target) {
    final amount = parameters['amount'] as int;
    
    if (target is BattlePlayer) {
      target.heal(amount);
      battleState.addLogEntry('${caster.name} heals ${target.name} for $amount');
    } else if (target is BattleCreature) {
      target.heal(amount);
      battleState.addLogEntry('${caster.name} heals ${target.card.name} for $amount');
    }
  }
}

// Enhanced ideas for card generation
class CardLibrary {
  static final List<BattleCard> _baseCards = [
    // Basic Warrior Cards
    BattleCard(
      name: 'Heroic Strike',
      description: 'Deal damage equal to your Strength bonus',
      type: CardType.spell,
      manaCost: 2,
      attack: 0,
      targetType: TargetType.enemyCreature,
      damageTypes: [DamageType.physical],
      requiredClasses: [CharacterClass.warrior, CharacterClass.paladin],
      abilities: ['strength_scaling'],
      keywords: ['instant'],
    ),
    
    // Basic Mage Cards
    BattleCard(
      name: 'Fireball',
      description: 'Deal fire damage to target',
      type: CardType.spell,
      manaCost: 3,
      attack: 4,
      targetType: TargetType.opponent,
      damageTypes: [DamageType.fire],
      requiredClasses: [CharacterClass.mage, CharacterClass.sorceress],
      abilities: ['burn_chance'],
      keywords: ['elemental'],
    ),
    
    // Creature Cards
    BattleCard(
      name: 'Skeletal Warrior',
      description: 'A basic undead soldier',
      type: CardType.creature,
      manaCost: 2,
      attack: 2,
      defense: 1,
      health: 3,
      damageTypes: [DamageType.physical],
      abilities: ['undead'],
      keywords: ['minion'],
    ),
  ];

  static List<BattleCard> generateDeckForClass(CharacterClass characterClass, int level) {
    final deck = <BattleCard>[];
    
    // Add class-specific cards based on character level and class
    // This is where the Diablo II-style progression comes in
    
    return deck;
  }
}