import 'package:flutter/foundation.dart';
import 'package:realm_of_valor/models/battle_model.dart';
import 'package:realm_of_valor/models/card_model.dart';
import 'package:realm_of_valor/models/character_model.dart';
import 'dart:math' as math;

enum BattlePhase {
  startTurn,
  playPhase,
  attackPhase,
  endTurn,
}

class BattleController extends ChangeNotifier {
  Battle _battle;
  BattlePhase _currentPhase = BattlePhase.startTurn;
  ActionCard? _selectedCard;
  String? _selectedTargetId;
  bool _showPhaseIndicator = false;
  bool _showInventory = false;
  bool _showSkills = false;
  bool _attackUsed = false;
  bool _cardPlayedThisTurn = false;

  BattleController(this._battle) {
    _initializeBattle();
  }

  // Getters
  Battle get battle => _battle;
  BattlePhase get currentPhase => _currentPhase;
  ActionCard? get selectedCard => _selectedCard;
  String? get selectedTargetId => _selectedTargetId;
  bool get showPhaseIndicator => _showPhaseIndicator;
  bool get showInventory => _showInventory;
  bool get showSkills => _showSkills;

  void _initializeBattle() {
    if (_battle.status == BattleStatus.waiting) {
      _startBattle();
    }
  }

  void _startBattle() {
    _battle = _battle.copyWith(
      status: BattleStatus.active,
      currentPlayerId: _battle.players.isNotEmpty ? _battle.players.first.id : '',
    );
    
    // Draw initial hands for all players
    for (var player in _battle.players) {
      _drawCards(player.id, 5); // Initial hand of 5 cards
    }
    
    _addBattleLog('Battle Started!', 'System');
    _showPhaseIndicatorWithDelay();
    notifyListeners();
  }

  void _showPhaseIndicatorWithDelay() {
    _showPhaseIndicator = true;
    notifyListeners();
    
    Future.delayed(const Duration(seconds: 2), () {
      _showPhaseIndicator = false;
      notifyListeners();
    });
  }

  BattlePlayer? getCurrentPlayer() {
    return _battle.players.firstWhere(
      (player) => player.id == _battle.currentPlayerId,
      orElse: () => _battle.players.first,
    );
  }

  BattlePlayer? getPlayerById(String playerId) {
    try {
      return _battle.players.firstWhere((player) => player.id == playerId);
    } catch (e) {
      return null;
    }
  }

  // Card Management
  void selectCard(ActionCard card) {
    if (_currentPhase != BattlePhase.playPhase || _cardPlayedThisTurn) {
      _addBattleLog('Cannot select card during ${_currentPhase.name} phase', getCurrentPlayer()?.name ?? 'Unknown');
      return;
    }
    
    if (_selectedCard == card) {
      _selectedCard = null;
    } else {
      _selectedCard = card;
    }
    notifyListeners();
  }

  void selectTarget(String targetId) {
    _selectedTargetId = targetId;
    notifyListeners();
  }

  bool canPlayCard(ActionCard card) {
    final currentPlayer = getCurrentPlayer();
    if (currentPlayer == null) return false;
    
    // Check phase
    if (_currentPhase != BattlePhase.playPhase && !card.effect.contains('interrupt')) {
      return false;
    }
    
    // Check if already played a card this turn
    if (_cardPlayedThisTurn && !card.effect.contains('anytime')) {
      return false;
    }
    
    // Check mana cost
    if (card.cost > currentPlayer.currentMana) {
      return false;
    }
    
    return true;
  }

  void playCard(ActionCard card) {
    if (!canPlayCard(card)) {
      _addBattleLog('Cannot play ${card.name}', getCurrentPlayer()?.name ?? 'Unknown');
      return;
    }
    
    final currentPlayer = getCurrentPlayer();
    if (currentPlayer == null) return;
    
    // Remove card from hand
    final updatedHand = List<ActionCard>.from(currentPlayer.hand);
    updatedHand.remove(card);
    
    // Deduct mana cost
    final updatedPlayer = currentPlayer.copyWith(
      hand: updatedHand,
      currentMana: math.max(0, currentPlayer.currentMana - card.cost),
    );
    
    _updatePlayer(updatedPlayer);
    
    // Apply card effect
    _applyCardEffect(card, currentPlayer);
    
    _cardPlayedThisTurn = true;
    _selectedCard = null;
    
    _addBattleLog('${currentPlayer.name} played ${card.name}', currentPlayer.name);
    
    // Check if card allows additional actions
    if (card.effect.contains('also_attack')) {
      _addBattleLog('${card.name} grants an additional attack!', currentPlayer.name);
    }
    
    notifyListeners();
  }

  void _applyCardEffect(ActionCard card, BattlePlayer player) {
    final effects = card.effect.split(',');
    
    for (final effect in effects) {
      final parts = effect.trim().split(':');
      final effectType = parts[0];
      final effectValue = parts.length > 1 ? parts[1] : '';
      
      switch (effectType) {
        case 'damage_bonus':
          final bonus = int.tryParse(effectValue) ?? 0;
          _addBattleLog('${player.name} gains +$bonus attack damage!', player.name);
          break;
          
        case 'double_damage':
          _addBattleLog('${player.name}\'s next attack will deal double damage!', player.name);
          break;
          
        case 'half_damage':
          _addBattleLog('${player.name}\'s next attack will deal half damage!', player.name);
          break;
          
        case 'skip_turn':
          _addBattleLog('${player.name} must skip their next turn!', player.name);
          break;
          
        case 'counter_next':
          _addBattleLog('${player.name} prepares to counter the next attack!', player.name);
          break;
          
        case 'cancel_action':
          _addBattleLog('${player.name} cancels the opponent\'s action!', player.name);
          break;
          
        case 'heal':
          final healAmount = int.tryParse(effectValue) ?? 0;
          _healPlayer(player.id, healAmount);
          break;
          
        case 'mana_bonus':
          final manaBonus = int.tryParse(effectValue) ?? 0;
          _restoreMana(player.id, manaBonus);
          break;
          
        case 'discard_random_opponent_card':
          _discardRandomOpponentCard(player.id);
          break;
          
        case 'gain_1_extra_attack':
          _addBattleLog('${player.name} gains an extra attack this turn!', player.name);
          break;
      }
    }
  }

  void _healPlayer(String playerId, int amount) {
    final player = getPlayerById(playerId);
    if (player == null) return;
    
    final newHealth = math.min(player.maxHealth, player.currentHealth + amount);
    final updatedPlayer = player.copyWith(currentHealth: newHealth);
    _updatePlayer(updatedPlayer);
    
    _addBattleLog('${player.name} heals for $amount HP (${player.currentHealth} → $newHealth)', player.name);
  }

  void _restoreMana(String playerId, int amount) {
    final player = getPlayerById(playerId);
    if (player == null) return;
    
    final newMana = math.min(player.maxMana, player.currentMana + amount);
    final updatedPlayer = player.copyWith(currentMana: newMana);
    _updatePlayer(updatedPlayer);
    
    _addBattleLog('${player.name} restores $amount MP (${player.currentMana} → $newMana)', player.name);
  }

  void _discardRandomOpponentCard(String playerId) {
    final opponents = _battle.players.where((p) => p.id != playerId).toList();
    if (opponents.isEmpty) return;
    
    final random = math.Random();
    final opponent = opponents[random.nextInt(opponents.length)];
    
    if (opponent.hand.isNotEmpty) {
      final cardToDiscard = opponent.hand[random.nextInt(opponent.hand.length)];
      final updatedHand = List<ActionCard>.from(opponent.hand);
      updatedHand.remove(cardToDiscard);
      
      final updatedOpponent = opponent.copyWith(hand: updatedHand);
      _updatePlayer(updatedOpponent);
      
      _addBattleLog('${opponent.name} discards ${cardToDiscard.name}', opponent.name);
    }
  }

  // Attack System
  bool canAttack() {
    if (_currentPhase != BattlePhase.attackPhase) return false;
    if (_attackUsed) return false;
    if (_selectedTargetId == null) return false;
    
    final target = getPlayerById(_selectedTargetId!);
    return target != null && target.id != getCurrentPlayer()?.id;
  }

  void performAttack() {
    if (!canAttack()) return;
    
    final attacker = getCurrentPlayer();
    final target = getPlayerById(_selectedTargetId!);
    
    if (attacker == null || target == null) return;
    
    // Calculate damage
    int baseDamage = attacker.character.attack;
    
    // Apply status effects and modifiers here
    // TODO: Implement status effect calculations
    
    final finalDamage = math.max(1, baseDamage - target.character.defense);
    
    // Apply damage
    final newHealth = math.max(0, target.currentHealth - finalDamage);
    final updatedTarget = target.copyWith(currentHealth: newHealth);
    _updatePlayer(updatedTarget);
    
    _addBattleLog(
      '${attacker.name} attacks ${target.name} for $finalDamage damage! (${target.currentHealth} → $newHealth HP)',
      attacker.name,
    );
    
    _attackUsed = true;
    
    // Check if target is defeated
    if (newHealth <= 0) {
      _addBattleLog('${target.name} has been defeated!', 'System');
      _checkBattleEnd();
    }
    
    notifyListeners();
  }

  // Skill System
  bool canUseSkill(GameCard skill) {
    final currentPlayer = getCurrentPlayer();
    if (currentPlayer == null) return false;
    
    // Check phase
    if (_currentPhase != BattlePhase.playPhase) return false;
    
    // Check mana cost
    if (skill.cost > currentPlayer.currentMana) return false;
    
    return true;
  }

  void useSkill(GameCard skill) {
    if (!canUseSkill(skill)) {
      _addBattleLog('Cannot use ${skill.name}', getCurrentPlayer()?.name ?? 'Unknown');
      return;
    }
    
    final currentPlayer = getCurrentPlayer();
    if (currentPlayer == null) return;
    
    // Deduct mana cost
    final updatedPlayer = currentPlayer.copyWith(
      currentMana: math.max(0, currentPlayer.currentMana - skill.cost),
    );
    _updatePlayer(updatedPlayer);
    
    _addBattleLog('${currentPlayer.name} uses ${skill.name}!', currentPlayer.name);
    
    // Apply skill effects
    _applySkillEffect(skill, currentPlayer);
    
    notifyListeners();
  }

  void _applySkillEffect(GameCard skill, BattlePlayer player) {
    // Apply skill effects based on the skill's properties
    for (final effect in skill.effects) {
      switch (effect.type) {
        case 'heal':
          final healAmount = int.tryParse(effect.value) ?? 0;
          _healPlayer(player.id, healAmount);
          break;
        case 'damage':
          if (_selectedTargetId != null) {
            _dealSkillDamage(player.id, _selectedTargetId!, int.tryParse(effect.value) ?? 0);
          }
          break;
        // Add more skill effects as needed
      }
    }
  }

  void _dealSkillDamage(String attackerId, String targetId, int damage) {
    final target = getPlayerById(targetId);
    if (target == null) return;
    
    final newHealth = math.max(0, target.currentHealth - damage);
    final updatedTarget = target.copyWith(currentHealth: newHealth);
    _updatePlayer(updatedTarget);
    
    _addBattleLog('Skill deals $damage damage to ${target.name}!', getPlayerById(attackerId)?.name ?? 'Unknown');
    
    if (newHealth <= 0) {
      _addBattleLog('${target.name} has been defeated by the skill!', 'System');
      _checkBattleEnd();
    }
  }

  // Turn Management
  void startTurn() {
    _currentPhase = BattlePhase.startTurn;
    _attackUsed = false;
    _cardPlayedThisTurn = false;
    _selectedCard = null;
    _selectedTargetId = null;
    
    final currentPlayer = getCurrentPlayer();
    if (currentPlayer != null) {
      // Draw a card at the start of turn
      _drawCards(currentPlayer.id, 1);
      
      // Restore some mana
      final manaRestore = math.min(2, currentPlayer.maxMana - currentPlayer.currentMana);
      if (manaRestore > 0) {
        _restoreMana(currentPlayer.id, manaRestore);
      }
      
      _addBattleLog('${currentPlayer.name}\'s turn begins!', currentPlayer.name);
    }
    
    // Move to play phase
    _currentPhase = BattlePhase.playPhase;
    _showPhaseIndicatorWithDelay();
    notifyListeners();
  }

  void moveToAttackPhase() {
    if (_currentPhase != BattlePhase.playPhase) return;
    
    _currentPhase = BattlePhase.attackPhase;
    _showPhaseIndicatorWithDelay();
    notifyListeners();
  }

  bool canEndTurn() {
    return _currentPhase != BattlePhase.endTurn;
  }

  void endTurn() {
    if (!canEndTurn()) return;
    
    _currentPhase = BattlePhase.endTurn;
    
    final currentPlayer = getCurrentPlayer();
    if (currentPlayer != null) {
      _addBattleLog('${currentPlayer.name}\'s turn ends.', currentPlayer.name);
    }
    
    // Move to next player
    _moveToNextPlayer();
    
    // Start next turn
    Future.delayed(const Duration(milliseconds: 500), () {
      startTurn();
    });
    
    notifyListeners();
  }

  void _moveToNextPlayer() {
    final currentPlayerIndex = _battle.players.indexWhere((p) => p.id == _battle.currentPlayerId);
    if (currentPlayerIndex == -1) return;
    
    // Find next alive player
    int nextIndex = (currentPlayerIndex + 1) % _battle.players.length;
    while (_battle.players[nextIndex].currentHealth <= 0 && nextIndex != currentPlayerIndex) {
      nextIndex = (nextIndex + 1) % _battle.players.length;
    }
    
    _battle = _battle.copyWith(
      currentPlayerId: _battle.players[nextIndex].id,
      currentTurn: _battle.currentTurn + 1,
    );
  }

  void _drawCards(String playerId, int count) {
    final player = getPlayerById(playerId);
    if (player == null) return;
    
    final updatedHand = List<ActionCard>.from(player.hand);
    final availableCards = List<ActionCard>.from(player.actionDeck);
    
    for (int i = 0; i < count && availableCards.isNotEmpty && updatedHand.length < 10; i++) {
      final random = math.Random();
      final cardIndex = random.nextInt(availableCards.length);
      final drawnCard = availableCards[cardIndex];
      
      updatedHand.add(drawnCard);
      // Note: In a real game, you'd remove from deck, but for testing we keep it available
    }
    
    final updatedPlayer = player.copyWith(hand: updatedHand);
    _updatePlayer(updatedPlayer);
    
    if (count == 1) {
      _addBattleLog('${player.name} draws a card.', player.name);
    } else {
      _addBattleLog('${player.name} draws $count cards.', player.name);
    }
  }

  // Battle Management
  void _checkBattleEnd() {
    final alivePlayers = _battle.players.where((p) => p.currentHealth > 0).toList();
    
    if (alivePlayers.length <= 1) {
      final winner = alivePlayers.isNotEmpty ? alivePlayers.first : null;
      
      _battle = _battle.copyWith(
        status: BattleStatus.finished,
        winnerId: winner?.id,
        endTime: DateTime.now(),
      );
      
      if (winner != null) {
        _addBattleLog('${winner.name} is victorious!', 'System');
      } else {
        _addBattleLog('Battle ended in a draw!', 'System');
      }
      
      notifyListeners();
    }
  }

  void pauseBattle() {
    if (_battle.status == BattleStatus.active) {
      _battle = _battle.copyWith(status: BattleStatus.paused);
      _addBattleLog('Battle paused.', 'System');
      notifyListeners();
    }
  }

  void resumeBattle() {
    if (_battle.status == BattleStatus.paused) {
      _battle = _battle.copyWith(status: BattleStatus.active);
      _addBattleLog('Battle resumed.', 'System');
      notifyListeners();
    }
  }

  void forfeitBattle() {
    final currentPlayer = getCurrentPlayer();
    if (currentPlayer != null) {
      _addBattleLog('${currentPlayer.name} forfeits the battle!', currentPlayer.name);
      
      // Set current player's health to 0
      final updatedPlayer = currentPlayer.copyWith(currentHealth: 0);
      _updatePlayer(updatedPlayer);
      
      _checkBattleEnd();
    }
  }

  // UI State Management
  void toggleInventory() {
    _showInventory = !_showInventory;
    _showSkills = false;
    notifyListeners();
  }

  void toggleSkills() {
    _showSkills = !_showSkills;
    _showInventory = false;
    notifyListeners();
  }

  // Helper Methods
  void _updatePlayer(BattlePlayer updatedPlayer) {
    final playerIndex = _battle.players.indexWhere((p) => p.id == updatedPlayer.id);
    if (playerIndex != -1) {
      final updatedPlayers = List<BattlePlayer>.from(_battle.players);
      updatedPlayers[playerIndex] = updatedPlayer;
      _battle = _battle.copyWith(players: updatedPlayers);
    }
  }

  void _addBattleLog(String description, String actorName) {
    final logEntry = BattleLog(
      playerId: actorName == 'System' ? 'system' : getCurrentPlayer()?.id ?? 'unknown',
      action: 'log',
      description: description,
    );
    
    final updatedLog = List<BattleLog>.from(_battle.battleLog);
    updatedLog.add(logEntry);
    
    _battle = _battle.copyWith(battleLog: updatedLog);
    
    // Debug logging
    if (kDebugMode) {
      print('[BATTLE LOG] $description');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}