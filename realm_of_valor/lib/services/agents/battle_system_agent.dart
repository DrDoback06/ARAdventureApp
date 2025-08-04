import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../services/event_bus.dart';
import '../../models/character.dart';
import '../../models/card.dart';
import 'integration_orchestrator_agent.dart';

/// Enemy data structure
class Enemy {
  final String id;
  final String name;
  final int level;
  final Map<String, int> stats;
  final List<String> abilities;
  final Map<String, dynamic> lootTable;

  Enemy({
    required this.id,
    required this.name,
    required this.level,
    required this.stats,
    this.abilities = const [],
    this.lootTable = const {},
  });

  int get health => stats['health'] ?? 100;
  int get attack => stats['attack'] ?? 10;
  int get defense => stats['defense'] ?? 5;
  int get speed => stats['speed'] ?? 10;
}

/// Battle state
enum BattleState {
  preparing,
  playerTurn,
  enemyTurn,
  victory,
  defeat,
  fled,
}

/// Battle action types
enum BattleActionType {
  attack,
  defend,
  useSkill,
  useItem,
  flee,
}

/// Battle action
class BattleAction {
  final BattleActionType type;
  final String? targetId;
  final String? skillId;
  final String? itemId;
  final Map<String, dynamic> parameters;

  BattleAction({
    required this.type,
    this.targetId,
    this.skillId,
    this.itemId,
    this.parameters = const {},
  });
}

/// Battle turn result
class BattleTurnResult {
  final String actorId;
  final BattleAction action;
  final int damage;
  final int healing;
  final List<String> effects;
  final Map<String, dynamic> changes;

  BattleTurnResult({
    required this.actorId,
    required this.action,
    this.damage = 0,
    this.healing = 0,
    this.effects = const [],
    this.changes = const {},
  });
}

/// Active battle instance
class Battle {
  final String id;
  final String playerId;
  final Enemy enemy;
  BattleState state;
  int playerHealth;
  int playerMaxHealth;
  int enemyHealth;
  int enemyMaxHealth;
  int turnNumber;
  List<BattleTurnResult> turnHistory;
  Map<String, int> playerStats;
  List<String> activeEffects;

  Battle({
    required this.id,
    required this.playerId,
    required this.enemy,
    required this.playerHealth,
    required this.playerMaxHealth,
    required this.playerStats,
    this.state = BattleState.preparing,
    this.turnNumber = 0,
    this.turnHistory = const [],
    this.activeEffects = const [],
  }) : enemyHealth = enemy.health,
       enemyMaxHealth = enemy.health;

  bool get isPlayerTurn => state == BattleState.playerTurn;
  bool get isEnemyTurn => state == BattleState.enemyTurn;
  bool get isActive => state == BattleState.playerTurn || state == BattleState.enemyTurn;
  bool get isFinished => state == BattleState.victory || state == BattleState.defeat || state == BattleState.fled;
}

/// Battle System Agent - Handle all combat mechanics and visual effects
class BattleSystemAgent extends BaseAgent {
  static const String agentId = 'battle_system';

  final Map<String, Battle> _activeBattles = {};
  final Map<String, Enemy> _enemyDatabase = {};
  
  // Battle configuration
  static const int baseAttackDamage = 10;
  static const int criticalHitChance = 15; // 15% chance
  static const double criticalHitMultiplier = 1.5;
  static const int fleeSuccessChance = 75; // 75% chance

  BattleSystemAgent() : super(agentId: agentId);

  @override
  Future<void> onInitialize() async {
    developer.log('Initializing Battle System Agent', name: agentId);
    
    // Initialize enemy database
    _initializeEnemyDatabase();
    
    developer.log('Battle System Agent initialized', name: agentId);
  }

  @override
  void subscribeToEvents() {
    // Battle management events
    subscribe('start_battle', _handleStartBattle);
    subscribe('battle_action', _handleBattleAction);
    subscribe('end_battle', _handleEndBattle);
    subscribe('flee_battle', _handleFleeBattle);
    
    // Character events for battle calculations
    subscribe(EventTypes.characterUpdated, _handleCharacterUpdated);
    subscribe(EventTypes.characterStatsChanged, _handleCharacterStatsChanged);
    
    // Adventure events that trigger battles
    subscribe('encounter_enemy', _handleEncounterEnemy);
    subscribe('random_battle', _handleRandomBattle);
  }

  /// Start a new battle
  Future<String> startBattle({
    required String playerId,
    required String enemyId,
    Map<String, int>? playerStats,
    int? playerHealth,
  }) async {
    final enemy = _enemyDatabase[enemyId];
    if (enemy == null) {
      throw ArgumentError('Enemy not found: $enemyId');
    }

    final battleId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Get player stats (would normally come from Character Management Agent)
    final stats = playerStats ?? _getDefaultPlayerStats();
    final maxHealth = stats['vitality']! * 10;
    final currentHealth = playerHealth ?? maxHealth;

    final battle = Battle(
      id: battleId,
      playerId: playerId,
      enemy: enemy,
      playerHealth: currentHealth,
      playerMaxHealth: maxHealth,
      playerStats: stats,
    );

    _activeBattles[battleId] = battle;

    // Start the battle
    await _startBattleTurn(battleId);

    developer.log('Battle started: $battleId vs ${enemy.name}', name: agentId);

    // Publish battle started event
    await publishEvent(createEvent(
      eventType: EventTypes.battleStarted,
      data: {
        'battleId': battleId,
        'playerId': playerId,
        'enemyId': enemyId,
        'enemyName': enemy.name,
        'enemyLevel': enemy.level,
        'playerHealth': currentHealth,
        'playerMaxHealth': maxHealth,
        'enemyHealth': battle.enemyHealth,
        'enemyMaxHealth': battle.enemyMaxHealth,
      },
    ));

    return battleId;
  }

  /// Execute a battle action
  Future<BattleTurnResult> executeBattleAction(String battleId, BattleAction action) async {
    final battle = _activeBattles[battleId];
    if (battle == null || !battle.isActive) {
      throw StateError('Battle not found or not active: $battleId');
    }

    if (!battle.isPlayerTurn) {
      throw StateError('Not player turn');
    }

    // Execute player action
    final playerResult = await _executeAction(battle, action, isPlayer: true);
    battle.turnHistory = [...battle.turnHistory, playerResult];

    // Apply action results
    await _applyTurnResult(battle, playerResult);

    // Check if battle ended
    if (_checkBattleEnd(battle)) {
      await _endBattle(battle);
      return playerResult;
    }

    // Switch to enemy turn
    battle.state = BattleState.enemyTurn;
    await _publishTurnResult(battle, playerResult);

    // Execute enemy turn after a delay
    Timer(const Duration(seconds: 2), () {
      _executeEnemyTurn(battleId);
    });

    return playerResult;
  }

  /// Initialize enemy database
  void _initializeEnemyDatabase() {
    _enemyDatabase.addAll({
      'goblin': Enemy(
        id: 'goblin',
        name: 'Goblin Warrior',
        level: 1,
        stats: {'health': 50, 'attack': 8, 'defense': 3, 'speed': 12},
        abilities: ['slash', 'dodge'],
        lootTable: {'gold': 15, 'items': ['rusty_sword', 'leather_boots']},
      ),
      'orc': Enemy(
        id: 'orc',
        name: 'Orc Berserker',
        level: 3,
        stats: {'health': 120, 'attack': 15, 'defense': 8, 'speed': 8},
        abilities: ['rage', 'heavy_strike'],
        lootTable: {'gold': 35, 'items': ['iron_axe', 'orc_helm']},
      ),
      'skeleton': Enemy(
        id: 'skeleton',
        name: 'Undead Skeleton',
        level: 2,
        stats: {'health': 75, 'attack': 12, 'defense': 6, 'speed': 10},
        abilities: ['bone_throw', 'reassemble'],
        lootTable: {'gold': 25, 'items': ['bone_club', 'skull_helmet']},
      ),
      'dragon': Enemy(
        id: 'dragon',
        name: 'Ancient Dragon',
        level: 10,
        stats: {'health': 500, 'attack': 50, 'defense': 30, 'speed': 15},
        abilities: ['fire_breath', 'wing_attack', 'intimidate'],
        lootTable: {'gold': 500, 'items': ['dragon_scale', 'dragon_heart', 'legendary_sword']},
      ),
    });
  }

  /// Start a battle turn
  Future<void> _startBattleTurn(String battleId) async {
    final battle = _activeBattles[battleId];
    if (battle == null) return;

    battle.turnNumber++;
    
    // Determine who goes first based on speed
    final playerSpeed = battle.playerStats['dexterity'] ?? 10;
    final enemySpeed = battle.enemy.speed;
    
    if (playerSpeed >= enemySpeed) {
      battle.state = BattleState.playerTurn;
    } else {
      battle.state = BattleState.enemyTurn;
      // Execute enemy turn immediately if they go first
      await _executeEnemyTurn(battleId);
    }
  }

  /// Execute an action
  Future<BattleTurnResult> _executeAction(Battle battle, BattleAction action, {required bool isPlayer}) async {
    switch (action.type) {
      case BattleActionType.attack:
        return _executeAttack(battle, isPlayer);
      case BattleActionType.defend:
        return _executeDefend(battle, isPlayer);
      case BattleActionType.useSkill:
        return _executeSkill(battle, action.skillId!, isPlayer);
      case BattleActionType.useItem:
        return _executeItem(battle, action.itemId!, isPlayer);
      case BattleActionType.flee:
        return _executeFlee(battle);
    }
  }

  /// Execute attack action
  Future<BattleTurnResult> _executeAttack(Battle battle, bool isPlayer) async {
    final actorId = isPlayer ? battle.playerId : battle.enemy.id;
    final attackStat = isPlayer ? (battle.playerStats['strength'] ?? 10) : battle.enemy.attack;
    final defenseStat = isPlayer ? battle.enemy.defense : (battle.playerStats['vitality'] ?? 10);
    
    // Calculate base damage
    int damage = math.max(1, attackStat - defenseStat + baseAttackDamage);
    
    // Add randomness (±20%)
    final randomFactor = 0.8 + (math.Random().nextDouble() * 0.4);
    damage = (damage * randomFactor).round();
    
    // Check for critical hit
    final criticalRoll = math.Random().nextInt(100);
    final isCritical = criticalRoll < criticalHitChance;
    if (isCritical) {
      damage = (damage * criticalHitMultiplier).round();
    }
    
    final effects = <String>[];
    if (isCritical) effects.add('critical_hit');
    
    return BattleTurnResult(
      actorId: actorId,
      action: BattleAction(type: BattleActionType.attack),
      damage: damage,
      effects: effects,
    );
  }

  /// Execute defend action
  Future<BattleTurnResult> _executeDefend(Battle battle, bool isPlayer) async {
    final actorId = isPlayer ? battle.playerId : battle.enemy.id;
    
    return BattleTurnResult(
      actorId: actorId,
      action: BattleAction(type: BattleActionType.defend),
      effects: ['defending'],
      changes: {'defense_bonus': 5},
    );
  }

  /// Execute skill action
  Future<BattleTurnResult> _executeSkill(Battle battle, String skillId, bool isPlayer) async {
    final actorId = isPlayer ? battle.playerId : battle.enemy.id;
    
    // Simplified skill system - would be expanded with actual skill database
    int damage = 0;
    int healing = 0;
    final effects = <String>[];
    
    switch (skillId) {
      case 'fireball':
        damage = 25 + math.Random().nextInt(15);
        effects.add('burn');
        break;
      case 'heal':
        healing = 20 + math.Random().nextInt(10);
        effects.add('healed');
        break;
      case 'poison_strike':
        damage = 15;
        effects.add('poisoned');
        break;
      default:
        damage = 10;
    }
    
    return BattleTurnResult(
      actorId: actorId,
      action: BattleAction(type: BattleActionType.useSkill, skillId: skillId),
      damage: damage,
      healing: healing,
      effects: effects,
    );
  }

  /// Execute item action
  Future<BattleTurnResult> _executeItem(Battle battle, String itemId, bool isPlayer) async {
    final actorId = isPlayer ? battle.playerId : battle.enemy.id;
    
    // Simplified item system
    int healing = 0;
    final effects = <String>[];
    
    switch (itemId) {
      case 'health_potion':
        healing = 50;
        effects.add('healed');
        break;
      case 'mana_potion':
        effects.add('mana_restored');
        break;
      default:
        healing = 25;
    }
    
    return BattleTurnResult(
      actorId: actorId,
      action: BattleAction(type: BattleActionType.useItem, itemId: itemId),
      healing: healing,
      effects: effects,
    );
  }

  /// Execute flee action
  Future<BattleTurnResult> _executeFlee(Battle battle) async {
    final success = math.Random().nextInt(100) < fleeSuccessChance;
    
    return BattleTurnResult(
      actorId: battle.playerId,
      action: BattleAction(type: BattleActionType.flee),
      effects: success ? ['fled_successfully'] : ['flee_failed'],
      changes: {'flee_success': success},
    );
  }

  /// Apply turn result to battle state
  Future<void> _applyTurnResult(Battle battle, BattleTurnResult result) async {
    // Apply damage
    if (result.damage > 0) {
      if (result.actorId == battle.playerId) {
        // Player attacking enemy
        battle.enemyHealth = math.max(0, battle.enemyHealth - result.damage);
      } else {
        // Enemy attacking player
        battle.playerHealth = math.max(0, battle.playerHealth - result.damage);
      }
    }
    
    // Apply healing
    if (result.healing > 0) {
      if (result.actorId == battle.playerId) {
        battle.playerHealth = math.min(battle.playerMaxHealth, battle.playerHealth + result.healing);
      } else {
        battle.enemyHealth = math.min(battle.enemyMaxHealth, battle.enemyHealth + result.healing);
      }
    }
    
    // Handle flee
    if (result.action.type == BattleActionType.flee && result.changes['flee_success'] == true) {
      battle.state = BattleState.fled;
    }
  }

  /// Execute enemy turn
  Future<void> _executeEnemyTurn(String battleId) async {
    final battle = _activeBattles[battleId];
    if (battle == null || battle.state != BattleState.enemyTurn) return;

    // Simple AI: randomly choose between attack and skill
    BattleAction action;
    final actionRoll = math.Random().nextInt(100);
    
    if (actionRoll < 20 && battle.enemy.abilities.isNotEmpty) {
      // 20% chance to use skill
      final skill = battle.enemy.abilities[math.Random().nextInt(battle.enemy.abilities.length)];
      action = BattleAction(type: BattleActionType.useSkill, skillId: skill);
    } else {
      // 80% chance to attack
      action = BattleAction(type: BattleActionType.attack);
    }

    final enemyResult = await _executeAction(battle, action, isPlayer: false);
    battle.turnHistory = [...battle.turnHistory, enemyResult];

    await _applyTurnResult(battle, enemyResult);
    await _publishTurnResult(battle, enemyResult);

    // Check if battle ended
    if (_checkBattleEnd(battle)) {
      await _endBattle(battle);
      return;
    }

    // Switch back to player turn
    battle.state = BattleState.playerTurn;
  }

  /// Check if battle has ended
  bool _checkBattleEnd(Battle battle) {
    return battle.playerHealth <= 0 || 
           battle.enemyHealth <= 0 || 
           battle.state == BattleState.fled;
  }

  /// End the battle
  Future<void> _endBattle(Battle battle) async {
    // Determine outcome
    BattleState finalState;
    if (battle.state == BattleState.fled) {
      finalState = BattleState.fled;
    } else if (battle.playerHealth <= 0) {
      finalState = BattleState.defeat;
    } else {
      finalState = BattleState.victory;
    }

    battle.state = finalState;

    // Calculate rewards for victory
    int xpGained = 0;
    List<String> itemsGained = [];
    int goldGained = 0;

    if (finalState == BattleState.victory) {
      xpGained = _calculateXpReward(battle.enemy);
      final loot = _generateLoot(battle.enemy);
      itemsGained = loot['items'] ?? [];
      goldGained = loot['gold'] ?? 0;
    }

    // Create battle result
    final battleResult = BattleResultData(
      battleId: battle.id,
      isVictory: finalState == BattleState.victory,
      xpGained: xpGained,
      itemsGained: itemsGained,
      statistics: {
        'turnCount': battle.turnNumber,
        'damageDealt': battle.turnHistory
            .where((turn) => turn.actorId == battle.playerId)
            .map((turn) => turn.damage)
            .fold(0, (a, b) => a + b),
        'damageTaken': battle.turnHistory
            .where((turn) => turn.actorId != battle.playerId)
            .map((turn) => turn.damage)
            .fold(0, (a, b) => a + b),
        'goldGained': goldGained,
      },
    );

    // Publish battle result
    await publishEvent(createEvent(
      eventType: EventTypes.battleResult,
      data: battleResult.toJson(),
      priority: EventPriority.high,
    ));

    // Clean up
    _activeBattles.remove(battle.id);

    developer.log('Battle ended: ${battle.id} - $finalState', name: agentId);
  }

  /// Calculate XP reward
  int _calculateXpReward(Enemy enemy) {
    return enemy.level * 10 + enemy.health ~/ 5;
  }

  /// Generate loot
  Map<String, dynamic> _generateLoot(Enemy enemy) {
    final loot = <String, dynamic>{};
    
    // Base gold reward
    final baseGold = enemy.lootTable['gold'] ?? 0;
    final goldVariance = (baseGold * 0.3).round();
    loot['gold'] = baseGold + math.Random().nextInt(goldVariance * 2) - goldVariance;
    
    // Item drops
    final possibleItems = List<String>.from(enemy.lootTable['items'] ?? []);
    final itemsGained = <String>[];
    
    for (final item in possibleItems) {
      // 30% chance for each item
      if (math.Random().nextInt(100) < 30) {
        itemsGained.add(item);
      }
    }
    
    loot['items'] = itemsGained;
    return loot;
  }

  /// Publish turn result
  Future<void> _publishTurnResult(Battle battle, BattleTurnResult result) async {
    await publishEvent(createEvent(
      eventType: EventTypes.battleTurnResolved,
      data: {
        'battleId': battle.id,
        'turnNumber': battle.turnNumber,
        'actorId': result.actorId,
        'actionType': result.action.type.toString(),
        'damage': result.damage,
        'healing': result.healing,
        'effects': result.effects,
        'playerHealth': battle.playerHealth,
        'playerMaxHealth': battle.playerMaxHealth,
        'enemyHealth': battle.enemyHealth,
        'enemyMaxHealth': battle.enemyMaxHealth,
        'isPlayerTurn': battle.isPlayerTurn,
      },
    ));
  }

  /// Get default player stats
  Map<String, int> _getDefaultPlayerStats() {
    return {
      'strength': 20,
      'dexterity': 20,
      'vitality': 20,
      'energy': 20,
    };
  }

  /// Handle start battle events
  Future<AgentEventResponse?> _handleStartBattle(AgentEvent event) async {
    final playerId = event.data['playerId'];
    final enemyId = event.data['enemyId'];
    final playerStats = event.data['playerStats'] != null 
        ? Map<String, int>.from(event.data['playerStats'])
        : null;
    final playerHealth = event.data['playerHealth'];

    try {
      final battleId = await startBattle(
        playerId: playerId,
        enemyId: enemyId,
        playerStats: playerStats,
        playerHealth: playerHealth,
      );

      return createResponse(
        originalEventId: event.id,
        responseType: 'battle_started',
        data: {'battleId': battleId},
      );
    } catch (e) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'battle_start_failed',
        data: {'error': e.toString()},
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Handle battle action events
  Future<AgentEventResponse?> _handleBattleAction(AgentEvent event) async {
    final battleId = event.data['battleId'];
    final actionData = event.data['action'];
    
    final action = BattleAction(
      type: BattleActionType.values.firstWhere(
        (type) => type.toString() == actionData['type'],
      ),
      targetId: actionData['targetId'],
      skillId: actionData['skillId'],
      itemId: actionData['itemId'],
      parameters: Map<String, dynamic>.from(actionData['parameters'] ?? {}),
    );

    try {
      final result = await executeBattleAction(battleId, action);

      return createResponse(
        originalEventId: event.id,
        responseType: 'battle_action_executed',
        data: {
          'battleId': battleId,
          'damage': result.damage,
          'healing': result.healing,
          'effects': result.effects,
        },
      );
    } catch (e) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'battle_action_failed',
        data: {'error': e.toString()},
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Handle end battle events
  Future<AgentEventResponse?> _handleEndBattle(AgentEvent event) async {
    final battleId = event.data['battleId'];
    final battle = _activeBattles[battleId];
    
    if (battle != null) {
      await _endBattle(battle);
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'battle_ended',
      data: {'battleId': battleId},
    );
  }

  /// Handle flee battle events
  Future<AgentEventResponse?> _handleFleeBattle(AgentEvent event) async {
    final battleId = event.data['battleId'];
    
    try {
      final fleeAction = BattleAction(type: BattleActionType.flee);
      final result = await executeBattleAction(battleId, fleeAction);

      return createResponse(
        originalEventId: event.id,
        responseType: 'flee_attempted',
        data: {
          'battleId': battleId,
          'success': result.effects.contains('fled_successfully'),
        },
      );
    } catch (e) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'flee_failed',
        data: {'error': e.toString()},
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Handle character updated events
  Future<AgentEventResponse?> _handleCharacterUpdated(AgentEvent event) async {
    // Character updates might affect active battles
    return createResponse(
      originalEventId: event.id,
      responseType: 'character_update_acknowledged',
      data: {'acknowledged': true},
    );
  }

  /// Handle character stats changed events
  Future<AgentEventResponse?> _handleCharacterStatsChanged(AgentEvent event) async {
    final characterId = event.data['characterId'];
    
    // Update stats for any active battles involving this character
    for (final battle in _activeBattles.values) {
      if (battle.playerId == characterId) {
        // Update battle stats from event data
        final statChanges = Map<String, dynamic>.from(event.data['statChanges'] ?? {});
        for (final entry in statChanges.entries) {
          if (battle.playerStats.containsKey(entry.key)) {
            battle.playerStats[entry.key] = entry.value;
          }
        }
      }
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'battle_stats_updated',
      data: {'characterId': characterId},
    );
  }

  /// Handle encounter enemy events
  Future<AgentEventResponse?> _handleEncounterEnemy(AgentEvent event) async {
    final playerId = event.data['playerId'];
    final enemyId = event.data['enemyId'] ?? 'goblin'; // Default enemy
    
    // Start battle automatically
    final battleId = await startBattle(
      playerId: playerId,
      enemyId: enemyId,
    );

    return createResponse(
      originalEventId: event.id,
      responseType: 'battle_started_from_encounter',
      data: {'battleId': battleId},
    );
  }

  /// Handle random battle events
  Future<AgentEventResponse?> _handleRandomBattle(AgentEvent event) async {
    final playerId = event.data['playerId'];
    
    // Choose random enemy based on player level (would be enhanced with proper scaling)
    final enemies = ['goblin', 'skeleton', 'orc'];
    final randomEnemy = enemies[math.Random().nextInt(enemies.length)];
    
    final battleId = await startBattle(
      playerId: playerId,
      enemyId: randomEnemy,
    );

    return createResponse(
      originalEventId: event.id,
      responseType: 'random_battle_started',
      data: {'battleId': battleId, 'enemyId': randomEnemy},
    );
  }

  @override
  Future<void> onDispose() async {
    // End all active battles
    for (final battle in _activeBattles.values) {
      battle.state = BattleState.fled;
    }
    _activeBattles.clear();
    
    developer.log('Battle System Agent disposed', name: agentId);
  }
}