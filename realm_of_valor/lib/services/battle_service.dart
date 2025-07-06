import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/battle_model.dart';
import '../models/character_model.dart';
import '../models/card_model.dart';
import 'character_service.dart';
import 'dart:convert';

class BattleService {
  static final BattleService _instance = BattleService._internal();
  factory BattleService() => _instance;
  BattleService._internal();

  final CharacterService _characterService = CharacterService();
  final Random _random = Random();

  // Create a new battle
  Future<Battle> createBattle({
    required String name,
    required BattleType type,
    required List<GameCharacter> characters,
    Map<String, dynamic>? settings,
  }) async {
    final battle = Battle(
      name: name,
      type: type,
      players: characters.map((char) => BattlePlayer(
        name: char.name,
        character: char,
        actionDeck: ActionCard.getDefaultActionDeck()..shuffle(),
      )).toList(),
      battleSettings: settings ?? {},
    );

    // Draw initial hand for each player
    for (int i = 0; i < battle.players.length; i++) {
      battle.players[i] = _drawInitialHand(battle.players[i]);
    }

    return battle;
  }

  // Start a battle
  Future<Battle> startBattle(Battle battle) async {
    if (battle.players.length < 2) {
      throw Exception('Battle needs at least 2 players');
    }

    // Determine turn order (highest dexterity goes first)
    final sortedPlayers = [...battle.players];
    sortedPlayers.sort((a, b) => b.character.totalDexterity.compareTo(a.character.totalDexterity));

    final updatedBattle = battle.copyWith(
      status: BattleStatus.active,
      currentPlayerId: sortedPlayers.first.id,
      players: sortedPlayers,
    );

    // Log battle start
    await _logBattleAction(
      updatedBattle,
      'system',
      'battle_start',
      'Battle "${battle.name}" has begun!',
    );

    return updatedBattle;
  }

  // Process a turn
  Future<Battle> processTurn(Battle battle, String playerId, BattleTurnAction action) async {
    if (battle.status != BattleStatus.active) {
      throw Exception('Battle is not active');
    }

    if (battle.currentPlayerId != playerId) {
      throw Exception('Not your turn');
    }

    final currentPlayer = battle.players.firstWhere((p) => p.id == playerId);
    Battle updatedBattle = battle;

    // Process the action
    switch (action.type) {
      case BattleTurnActionType.attack:
        updatedBattle = await _processAttack(battle, currentPlayer, action);
        break;
      case BattleTurnActionType.useSkill:
        updatedBattle = await _processSkillUse(battle, currentPlayer, action);
        break;
      case BattleTurnActionType.useItem:
        updatedBattle = await _processItemUse(battle, currentPlayer, action);
        break;
      case BattleTurnActionType.playActionCard:
        updatedBattle = await _processActionCard(battle, currentPlayer, action);
        break;
      case BattleTurnActionType.endTurn:
        updatedBattle = await _endTurn(battle, currentPlayer);
        break;
    }

    // Check for battle end conditions
    updatedBattle = await _checkBattleEnd(updatedBattle);

    return updatedBattle;
  }

  // Process an attack action
  Future<Battle> _processAttack(Battle battle, BattlePlayer attacker, BattleTurnAction action) async {
    final targetId = action.targetId;
    if (targetId == null) {
      throw Exception('Attack requires a target');
    }

    final target = battle.players.firstWhere((p) => p.id == targetId);
    
    // Calculate damage
    int baseDamage = attacker.character.attackRating;
    int finalDamage = _calculateDamage(baseDamage, target.character.defense);

    // Apply status effects
    finalDamage = _applyStatusEffects(attacker, target, finalDamage);

    // Deal damage
    final updatedTarget = target.copyWith(
      currentHealth: (target.currentHealth - finalDamage).clamp(0, target.maxHealth),
    );

    // Update battle
    final updatedPlayers = battle.players.map((p) {
      if (p.id == target.id) return updatedTarget;
      return p;
    }).toList();

    await _logBattleAction(
      battle,
      attacker.id,
      'attack',
      '${attacker.name} attacks ${target.name} for $finalDamage damage!',
      {'damage': finalDamage, 'target': target.name},
    );

    return battle.copyWith(players: updatedPlayers);
  }

  // Process skill use
  Future<Battle> _processSkillUse(Battle battle, BattlePlayer player, BattleTurnAction action) async {
    final skillId = action.skillId;
    if (skillId == null) {
      throw Exception('Skill use requires a skill ID');
    }

    final skill = player.activeSkills.firstWhere((s) => s.id == skillId);
    
    // Check mana cost
    int manaCost = skill.cost;
    if (player.currentMana < manaCost) {
      throw Exception('Not enough mana');
    }

    // Use mana
    final updatedPlayer = player.copyWith(
      currentMana: player.currentMana - manaCost,
    );

    // Apply skill effects
    Battle updatedBattle = battle.copyWith(
      players: battle.players.map((p) => p.id == player.id ? updatedPlayer : p).toList(),
    );

    updatedBattle = await _applySkillEffects(updatedBattle, player, skill, action);

    await _logBattleAction(
      battle,
      player.id,
      'skill_use',
      '${player.name} uses ${skill.name}!',
      {'skill': skill.name, 'mana_cost': manaCost},
    );

    return updatedBattle;
  }

  // Process item use
  Future<Battle> _processItemUse(Battle battle, BattlePlayer player, BattleTurnAction action) async {
    final itemId = action.itemId;
    if (itemId == null) {
      throw Exception('Item use requires an item ID');
    }

    // Find item in character's inventory
    final item = player.character.inventory.firstWhere((i) => i.card.id == itemId);
    
    if (!item.card.isConsumable) {
      throw Exception('Item is not consumable');
    }

    // Apply item effects
    Battle updatedBattle = await _applyItemEffects(battle, player, item.card);

    await _logBattleAction(
      battle,
      player.id,
      'item_use',
      '${player.name} uses ${item.card.name}!',
      {'item': item.card.name},
    );

    return updatedBattle;
  }

  // Process action card
  Future<Battle> _processActionCard(Battle battle, BattlePlayer player, BattleTurnAction action) async {
    final cardId = action.actionCardId;
    if (cardId == null) {
      throw Exception('Action card use requires a card ID');
    }

    final actionCard = player.hand.firstWhere((c) => c.id == cardId);
    
    // Remove card from hand
    final updatedHand = player.hand.where((c) => c.id != cardId).toList();
    final updatedPlayer = player.copyWith(hand: updatedHand);

    // Apply action card effects
    Battle updatedBattle = battle.copyWith(
      players: battle.players.map((p) => p.id == player.id ? updatedPlayer : p).toList(),
    );

    updatedBattle = await _applyActionCardEffects(updatedBattle, player, actionCard);

    await _logBattleAction(
      battle,
      player.id,
      'action_card',
      '${player.name} plays ${actionCard.name}!',
      {'card': actionCard.name, 'effect': actionCard.effect},
    );

    return updatedBattle;
  }

  // End turn
  Future<Battle> _endTurn(Battle battle, BattlePlayer currentPlayer) async {
    // Draw a new action card
    final updatedPlayer = _drawActionCard(currentPlayer);
    
    // Regenerate mana
    final manaRegen = (currentPlayer.maxMana * 0.1).round();
    final playerWithMana = updatedPlayer.copyWith(
      currentMana: (updatedPlayer.currentMana + manaRegen).clamp(0, updatedPlayer.maxMana),
    );

    // Determine next player
    final currentIndex = battle.players.indexWhere((p) => p.id == currentPlayer.id);
    final nextIndex = (currentIndex + 1) % battle.players.length;
    final nextPlayerId = battle.players[nextIndex].id;

    final updatedBattle = battle.copyWith(
      currentTurn: battle.currentTurn + 1,
      currentPlayerId: nextPlayerId,
      players: battle.players.map((p) => p.id == currentPlayer.id ? playerWithMana : p).toList(),
    );

    await _logBattleAction(
      battle,
      currentPlayer.id,
      'end_turn',
      '${currentPlayer.name} ends their turn',
    );

    return updatedBattle;
  }

  // Draw initial hand
  BattlePlayer _drawInitialHand(BattlePlayer player) {
    final handSize = 3;
    final hand = player.actionDeck.take(handSize).toList();
    final remainingDeck = player.actionDeck.skip(handSize).toList();
    
    return player.copyWith(
      hand: hand,
      actionDeck: remainingDeck,
    );
  }

  // Draw action card
  BattlePlayer _drawActionCard(BattlePlayer player) {
    if (player.actionDeck.isEmpty) {
      // Shuffle discarded cards back into deck
      final shuffledDeck = ActionCard.getDefaultActionDeck()..shuffle();
      return player.copyWith(actionDeck: shuffledDeck);
    }

    final newCard = player.actionDeck.first;
    final remainingDeck = player.actionDeck.skip(1).toList();
    final updatedHand = [...player.hand, newCard];

    return player.copyWith(
      hand: updatedHand,
      actionDeck: remainingDeck,
    );
  }

  // Calculate damage
  int _calculateDamage(int baseDamage, int defense) {
    final damage = baseDamage - (defense * 0.5).round();
    return damage.clamp(1, baseDamage); // Minimum 1 damage
  }

  // Apply status effects
  int _applyStatusEffects(BattlePlayer attacker, BattlePlayer target, int damage) {
    int modifiedDamage = damage;

    // Check attacker's status effects
    if (attacker.statusEffects.containsKey('double_damage')) {
      modifiedDamage *= 2;
    }
    if (attacker.statusEffects.containsKey('half_damage')) {
      modifiedDamage = (modifiedDamage / 2).round();
    }

    // Check target's status effects
    if (target.statusEffects.containsKey('damage_reduction')) {
      final reduction = target.statusEffects['damage_reduction'] as int;
      modifiedDamage = (modifiedDamage * (1 - reduction / 100)).round();
    }

    return modifiedDamage.clamp(1, modifiedDamage);
  }

  // Apply skill effects
  Future<Battle> _applySkillEffects(Battle battle, BattlePlayer player, GameCard skill, BattleTurnAction action) async {
    // This is a simplified implementation - in a real game, you'd have more complex skill effects
    Battle updatedBattle = battle;

    for (final effect in skill.effects) {
      switch (effect.type) {
        case 'heal':
          final healAmount = int.parse(effect.value);
          final healedPlayer = battle.players.firstWhere((p) => p.id == player.id);
          final updatedPlayer = healedPlayer.copyWith(
            currentHealth: (healedPlayer.currentHealth + healAmount).clamp(0, healedPlayer.maxHealth),
          );
          updatedBattle = updatedBattle.copyWith(
            players: updatedBattle.players.map((p) => p.id == player.id ? updatedPlayer : p).toList(),
          );
          break;
        case 'damage':
          final damageAmount = int.parse(effect.value);
          if (action.targetId != null) {
            final target = battle.players.firstWhere((p) => p.id == action.targetId);
            final damagedTarget = target.copyWith(
              currentHealth: (target.currentHealth - damageAmount).clamp(0, target.maxHealth),
            );
            updatedBattle = updatedBattle.copyWith(
              players: updatedBattle.players.map((p) => p.id == action.targetId ? damagedTarget : p).toList(),
            );
          }
          break;
        case 'buff':
          // Apply temporary stat boost
          final buffedPlayer = battle.players.firstWhere((p) => p.id == player.id);
          final statusEffects = Map<String, dynamic>.from(buffedPlayer.statusEffects);
          statusEffects[effect.type] = effect.value;
          final updatedPlayer = buffedPlayer.copyWith(statusEffects: statusEffects);
          updatedBattle = updatedBattle.copyWith(
            players: updatedBattle.players.map((p) => p.id == player.id ? updatedPlayer : p).toList(),
          );
          break;
      }
    }

    return updatedBattle;
  }

  // Apply item effects
  Future<Battle> _applyItemEffects(Battle battle, BattlePlayer player, GameCard item) async {
    Battle updatedBattle = battle;

    for (final effect in item.effects) {
      switch (effect.type) {
        case 'heal':
          final healAmount = int.parse(effect.value);
          final healedPlayer = battle.players.firstWhere((p) => p.id == player.id);
          final updatedPlayer = healedPlayer.copyWith(
            currentHealth: (healedPlayer.currentHealth + healAmount).clamp(0, healedPlayer.maxHealth),
          );
          updatedBattle = updatedBattle.copyWith(
            players: updatedBattle.players.map((p) => p.id == player.id ? updatedPlayer : p).toList(),
          );
          break;
        case 'mana_restore':
          final manaAmount = int.parse(effect.value);
          final player = battle.players.firstWhere((p) => p.id == player.id);
          final updatedPlayer = player.copyWith(
            currentMana: (player.currentMana + manaAmount).clamp(0, player.maxMana),
          );
          updatedBattle = updatedBattle.copyWith(
            players: updatedBattle.players.map((p) => p.id == player.id ? updatedPlayer : p).toList(),
          );
          break;
      }
    }

    return updatedBattle;
  }

  // Apply action card effects
  Future<Battle> _applyActionCardEffects(Battle battle, BattlePlayer player, ActionCard actionCard) async {
    Battle updatedBattle = battle;

    switch (actionCard.effect) {
      case 'double_damage':
        final statusEffects = Map<String, dynamic>.from(player.statusEffects);
        statusEffects['double_damage'] = true;
        final updatedPlayer = player.copyWith(statusEffects: statusEffects);
        updatedBattle = updatedBattle.copyWith(
          players: updatedBattle.players.map((p) => p.id == player.id ? updatedPlayer : p).toList(),
        );
        break;
      case 'half_damage':
        final statusEffects = Map<String, dynamic>.from(player.statusEffects);
        statusEffects['half_damage'] = true;
        final updatedPlayer = player.copyWith(statusEffects: statusEffects);
        updatedBattle = updatedBattle.copyWith(
          players: updatedBattle.players.map((p) => p.id == player.id ? updatedPlayer : p).toList(),
        );
        break;
      case 'heal:20':
        final healedPlayer = battle.players.firstWhere((p) => p.id == player.id);
        final updatedPlayer = healedPlayer.copyWith(
          currentHealth: (healedPlayer.currentHealth + 20).clamp(0, healedPlayer.maxHealth),
        );
        updatedBattle = updatedBattle.copyWith(
          players: updatedBattle.players.map((p) => p.id == player.id ? updatedPlayer : p).toList(),
        );
        break;
      case 'skip_turn':
        // Skip next turn logic would be implemented here
        break;
    }

    return updatedBattle;
  }

  // Check battle end conditions
  Future<Battle> _checkBattleEnd(Battle battle) async {
    final alivePlayers = battle.players.where((p) => p.currentHealth > 0).toList();
    
    if (alivePlayers.length <= 1) {
      final winner = alivePlayers.isNotEmpty ? alivePlayers.first : null;
      
      await _logBattleAction(
        battle,
        winner?.id ?? 'system',
        'battle_end',
        winner != null ? '${winner.name} wins the battle!' : 'Battle ended in a draw!',
      );

      return battle.copyWith(
        status: BattleStatus.finished,
        winnerId: winner?.id,
        endTime: DateTime.now(),
      );
    }

    if (battle.currentTurn >= battle.maxTurns) {
      // Battle ends due to turn limit
      final winner = battle.players.reduce((a, b) => 
        a.currentHealth > b.currentHealth ? a : b);
      
      await _logBattleAction(
        battle,
        winner.id,
        'battle_end',
        'Battle ended due to turn limit. ${winner.name} wins!',
      );

      return battle.copyWith(
        status: BattleStatus.finished,
        winnerId: winner.id,
        endTime: DateTime.now(),
      );
    }

    return battle;
  }

  // Log battle actions
  Future<void> _logBattleAction(
    Battle battle,
    String playerId,
    String action,
    String description,
    [Map<String, dynamic>? data]
  ) async {
    final log = BattleLog(
      playerId: playerId,
      action: action,
      description: description,
      data: data ?? {},
    );

    // In a real implementation, you'd add this to the battle's log
    // For now, we'll just store it locally
    final prefs = await SharedPreferences.getInstance();
    final battleLogsJson = prefs.getString('battle_logs') ?? '[]';
    final battleLogs = List<Map<String, dynamic>>.from(jsonDecode(battleLogsJson));
    battleLogs.add(log.toJson());
    await prefs.setString('battle_logs', jsonEncode(battleLogs));
  }

  // Generate AI enemy for PvE battles
  Future<EnemyCard> generateRandomEnemy() async {
    final enemies = [
      EnemyCard(
        name: 'Goblin Warrior',
        description: 'A fierce goblin wielding a rusty sword',
        health: 80,
        mana: 40,
        attackPower: 25,
        defense: 15,
        abilities: ['Slash', 'War Cry'],
        rarity: CardRarity.common,
        battleActions: {'challenge': true},
      ),
      EnemyCard(
        name: 'Orc Shaman',
        description: 'A powerful orc spellcaster',
        health: 120,
        mana: 80,
        attackPower: 35,
        defense: 20,
        abilities: ['Lightning Bolt', 'Heal', 'Curse'],
        rarity: CardRarity.uncommon,
        battleActions: {'challenge': true},
      ),
      EnemyCard(
        name: 'Ancient Dragon',
        description: 'A legendary dragon with immense power',
        health: 300,
        mana: 150,
        attackPower: 60,
        defense: 40,
        abilities: ['Fire Breath', 'Dragon Roar', 'Tail Swipe', 'Flying'],
        rarity: CardRarity.legendary,
        battleActions: {'challenge': true},
      ),
    ];

    return enemies[_random.nextInt(enemies.length)];
  }
}

// Battle turn action types
enum BattleTurnActionType {
  attack,
  useSkill,
  useItem,
  playActionCard,
  endTurn,
}

// Battle turn action
class BattleTurnAction {
  final BattleTurnActionType type;
  final String? targetId;
  final String? skillId;
  final String? itemId;
  final String? actionCardId;
  final Map<String, dynamic>? parameters;

  BattleTurnAction({
    required this.type,
    this.targetId,
    this.skillId,
    this.itemId,
    this.actionCardId,
    this.parameters,
  });
}