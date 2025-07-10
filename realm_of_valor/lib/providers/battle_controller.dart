import 'package:flutter/foundation.dart';
import 'package:realm_of_valor/models/battle_model.dart';
import 'package:realm_of_valor/models/card_model.dart';
import 'package:realm_of_valor/models/character_model.dart';
import 'package:realm_of_valor/models/spell_counter_system.dart';
import 'package:realm_of_valor/widgets/spell_animation_widget.dart';
import 'package:realm_of_valor/widgets/status_effect_overlay.dart';
import 'package:realm_of_valor/effects/particle_system.dart';
import 'dart:math' as math;
import 'dart:async';

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
  ActionCard? _drawnCard;
  bool _showCardDrawPopup = false;
  
  // Spell Counter System
  final SpellCounterSystem _spellCounterSystem = SpellCounterSystem();
  bool _waitingForCounters = false;
  
  // Spell Animation System
  ActionCard? _currentSpellAnimation;
  String? _spellCasterId;
  String? _spellTargetId;
  bool _showSpellAnimation = false;
  
  // Status Effect System
  StatusEffect? _currentStatusBanner;
  bool _showStatusBanner = false;

  BattleController(this._battle) {
    _initializeBattle();
    _setupSpellCounterCallbacks();
  }

  // Getters
  Battle get battle => _battle;
  BattlePhase get currentPhase => _currentPhase;
  ActionCard? get selectedCard => _selectedCard;
  String? get selectedTargetId => _selectedTargetId;
  bool get showPhaseIndicator => _showPhaseIndicator;
  bool get showInventory => _showInventory;
  bool get showSkills => _showSkills;
  ActionCard? get drawnCard => _drawnCard;
  bool get showCardDrawPopup => _showCardDrawPopup;
  SpellCounterSystem get spellCounterSystem => _spellCounterSystem;
  bool get waitingForCounters => _waitingForCounters;
  ActionCard? get currentSpellAnimation => _currentSpellAnimation;
  String? get spellCasterId => _spellCasterId;
  String? get spellTargetId => _spellTargetId;
  bool get showSpellAnimation => _showSpellAnimation;
  StatusEffect? get currentStatusBanner => _currentStatusBanner;
  bool get showStatusBanner => _showStatusBanner;

  void _initializeBattle() {
    if (_battle.status == BattleStatus.waiting) {
      _startBattle();
    }
  }

  void _setupSpellCounterCallbacks() {
    _spellCounterSystem.onSpellResolved = (pendingSpell, counters, effectMultiplier, messages) {
      _resolveSpellWithCounterResult(pendingSpell, counters, effectMultiplier, messages);
    };
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
    
    // Start the first player's turn immediately
    Future.delayed(const Duration(milliseconds: 1000), () {
      startTurn();
    });
    
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
    try {
      return _battle.players.firstWhere(
        (player) => player.id == _battle.currentPlayerId,
      );
    } catch (e) {
      return _battle.players.isNotEmpty ? _battle.players.first : null;
    }
  }

  BattlePlayer? getPlayerById(String playerId) {
    try {
      return _battle.players.firstWhere((player) => player.id == playerId);
    } catch (e) {
      return null;
    }
  }

  /// Determines team based on player index (even = team A, odd = team B)
  int getPlayerTeam(String playerId) {
    final playerIndex = _battle.players.indexWhere((p) => p.id == playerId);
    return playerIndex % 2; // 0 = Team A, 1 = Team B
  }

  /// Gets team members for a given team
  List<BattlePlayer> getTeamMembers(int team) {
    return _battle.players.where((player) {
      final index = _battle.players.indexOf(player);
      return index % 2 == team;
    }).toList();
  }

  /// Check if player is on friendly team relative to current player
  bool isFriendly(String playerId) {
    final currentPlayer = getCurrentPlayer();
    if (currentPlayer == null) return false;
    return getPlayerTeam(playerId) == getPlayerTeam(currentPlayer.id);
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
    
    // If we have a selected card and target, play the card automatically
    if (_selectedCard != null && _selectedTargetId != null) {
      playCardOnTarget(_selectedCard!, _selectedTargetId!);
    }
    
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
    // For now, keep the old method for non-targeted cards
    // Most cards should use playCardOnTarget instead
    if (!canPlayCard(card)) {
      _addBattleLog('Cannot play ${card.name}', getCurrentPlayer()?.name ?? 'Unknown');
      return;
    }
    
    final currentPlayer = getCurrentPlayer();
    if (currentPlayer == null) return;
    
    // Apply to self by default
    playCardOnTarget(card, currentPlayer.id);
  }

  void playCardOnTarget(ActionCard card, String targetId) {
    if (!canPlayCard(card)) {
      _addBattleLog('Cannot play ${card.name}', getCurrentPlayer()?.name ?? 'Unknown');
      return;
    }
    
    final currentPlayer = getCurrentPlayer();
    final target = getPlayerById(targetId);
    if (currentPlayer == null || target == null) return;
    
    // Check if this card should trigger an interrupt window
    if (_shouldTriggerInterrupt(card)) {
      _startSpellInterrupt(card, currentPlayer.id, targetId);
      return;
    }
    
    // Trigger spell casting animation
    _triggerSpellAnimation(card, currentPlayer.id, targetId);
    
    // Remove card from hand
    final updatedHand = List<ActionCard>.from(currentPlayer.hand);
    updatedHand.remove(card);
    
    // Deduct mana cost
    final updatedPlayer = currentPlayer.copyWith(
      hand: updatedHand,
      currentMana: math.max(0, currentPlayer.currentMana - card.cost),
    );
    
    _updatePlayer(updatedPlayer);
    
    // Apply card effect to target
    _applyCardEffectToTarget(card, currentPlayer, target);
    
    // Generate status effect from spell if applicable
    _applyStatusEffectFromSpell(card, target);
    
    _cardPlayedThisTurn = true;
    _selectedCard = null;
    _selectedTargetId = null;
    
    _addBattleLog('${currentPlayer.name} played ${card.name} on ${target.name}', currentPlayer.name);
    
    // Check if card allows additional actions
    if (card.effect.contains('also_attack')) {
      _addBattleLog('${card.name} grants an additional attack!', currentPlayer.name);
    }
    
    notifyListeners();
  }

  /// Check if a card should trigger the interrupt window
  bool _shouldTriggerInterrupt(ActionCard card) {
    // Trigger interrupt for powerful spells and certain card types
    if (card.cost >= 4) return true; // High-cost cards are interruptible
    if (card.type == ActionCardType.special) return true;
    if (card.effect.contains('damage') && card.effect.contains('all')) return true; // Area damage
    if (card.effect.contains('double_damage')) return true;
    if (card.name.toLowerCase().contains('fire') || 
        card.name.toLowerCase().contains('lightning') ||
        card.name.toLowerCase().contains('ice') ||
        card.name.toLowerCase().contains('shadow')) return true;
    
    return false;
  }

  /// Start the spell interrupt window
  void _startSpellInterrupt(ActionCard spell, String casterId, String targetId) {
    _waitingForCounters = true;
    _spellCounterSystem.startInterruptWindow(spell, casterId, targetId);
    
    _addBattleLog('⚡ ${spell.name} is being cast! Opponents have 8 seconds to counter!', getCurrentPlayer()?.name ?? 'Unknown');
    
    notifyListeners();
  }

  /// Attempt to counter the current spell
  bool attemptSpellCounter(ActionCard counterSpell) {
    final currentPlayer = getCurrentPlayer();
    if (currentPlayer == null) return false;
    
    if (!canPlayCard(counterSpell)) return false;
    
    final success = _spellCounterSystem.attemptCounter(counterSpell, currentPlayer.id);
    if (success) {
      // Remove counter spell from hand and deduct mana
      final updatedHand = List<ActionCard>.from(currentPlayer.hand);
      updatedHand.remove(counterSpell);
      
      final updatedPlayer = currentPlayer.copyWith(
        hand: updatedHand,
        currentMana: math.max(0, currentPlayer.currentMana - counterSpell.cost),
      );
      
      _updatePlayer(updatedPlayer);
      _addBattleLog('⚡ ${currentPlayer.name} attempts to counter with ${counterSpell.name}!', currentPlayer.name);
      
      notifyListeners();
    }
    
    return success;
  }

  /// Resolve spell after interrupt window ends
  void _resolveSpellWithCounterResult(PendingSpell pendingSpell, List<CounterSpellAttempt> counters, double effectMultiplier, List<String> messages) {
    _waitingForCounters = false;
    
    final caster = getPlayerById(pendingSpell.casterId);
    final target = getPlayerById(pendingSpell.targetId);
    
    if (caster == null || target == null) return;
    
    // Remove original spell from caster's hand if not already done
    final updatedHand = List<ActionCard>.from(caster.hand);
    if (updatedHand.contains(pendingSpell.spell)) {
      updatedHand.remove(pendingSpell.spell);
      
      final updatedCaster = caster.copyWith(
        hand: updatedHand,
        currentMana: math.max(0, caster.currentMana - pendingSpell.spell.cost),
      );
      
      _updatePlayer(updatedCaster);
    }
    
    // Log counter resolution messages
    for (final message in messages) {
      _addBattleLog('⚡ $message', 'System');
    }
    
    if (effectMultiplier > 0.0) {
      // Apply modified spell effect
      _addBattleLog('⚡ ${pendingSpell.spell.name} resolves with ${(effectMultiplier * 100).round()}% effectiveness!', 'System');
      _applyCardEffectToTargetWithMultiplier(pendingSpell.spell, caster, target, effectMultiplier);
    } else {
      _addBattleLog('⚡ ${pendingSpell.spell.name} is completely nullified!', 'System');
    }
    
    _cardPlayedThisTurn = true;
    _selectedCard = null;
    _selectedTargetId = null;
    
    notifyListeners();
  }

  void _applyCardEffect(ActionCard card, BattlePlayer player) {
    // Redirect to target-based system
    _applyCardEffectToTarget(card, player, player);
  }

  void _applyCardEffectToTarget(ActionCard card, BattlePlayer caster, BattlePlayer target) {
    final effects = card.effect.split(',');
    
    for (final effect in effects) {
      final parts = effect.trim().split(':');
      final effectType = parts[0];
      final effectValue = parts.length > 1 ? parts[1] : '';
      
      switch (effectType) {
        case 'damage_bonus':
          final bonus = int.tryParse(effectValue) ?? 0;
          _addBattleLog('${target.name} gains +$bonus attack damage!', caster.name);
          // TODO: Apply damage bonus status effect
          break;
          
        case 'double_damage':
          _addBattleLog('${target.name}\'s next attack will deal double damage!', caster.name);
          // TODO: Apply double damage status effect
          break;
          
        case 'half_damage':
          _addBattleLog('${target.name}\'s next attack will deal half damage!', caster.name);
          // TODO: Apply damage reduction status effect
          break;
          
        case 'skip_turn':
          _addBattleLog('${target.name} must skip their next turn!', caster.name);
          // TODO: Apply skip turn status effect
          break;
          
        case 'counter_next':
          _addBattleLog('${target.name} prepares to counter the next attack!', caster.name);
          // TODO: Apply counter status effect
          break;
          
        case 'cancel_action':
          _addBattleLog('${caster.name} cancels ${target.name}\'s action!', caster.name);
          // TODO: Implement action cancellation
          break;
          
        case 'heal':
          final healAmount = int.tryParse(effectValue) ?? 0;
          _healPlayer(target.id, healAmount);
          break;
          
        case 'mana_bonus':
          final manaBonus = int.tryParse(effectValue) ?? 0;
          _restoreMana(target.id, manaBonus);
          break;
          
        case 'discard_random_opponent_card':
          if (!isFriendly(target.id)) {
            _discardRandomCard(target.id);
          }
          break;
          
        case 'gain_1_extra_attack':
          _addBattleLog('${target.name} gains an extra attack this turn!', caster.name);
          // TODO: Apply extra attack status effect
          break;
      }
    }
  }

  void _applyCardEffectToTargetWithMultiplier(ActionCard card, BattlePlayer caster, BattlePlayer target, double multiplier) {
    final effects = card.effect.split(',');
    
    for (final effect in effects) {
      final parts = effect.trim().split(':');
      final effectType = parts[0];
      final effectValue = parts.length > 1 ? parts[1] : '';
      
      switch (effectType) {
        case 'damage_bonus':
          final bonus = ((int.tryParse(effectValue) ?? 0) * multiplier).round();
          _addBattleLog('${target.name} gains +$bonus attack damage!', caster.name);
          // TODO: Apply damage bonus status effect
          break;
          
        case 'double_damage':
          if (multiplier > 0.5) {
            _addBattleLog('${target.name}\'s next attack will deal ${multiplier > 1.0 ? 'amplified' : 'reduced'} double damage!', caster.name);
          }
          // TODO: Apply double damage status effect with multiplier
          break;
          
        case 'heal':
          final healAmount = ((int.tryParse(effectValue) ?? 0) * multiplier).round();
          _healPlayer(target.id, healAmount);
          break;
          
        case 'mana_bonus':
          final manaBonus = ((int.tryParse(effectValue) ?? 0) * multiplier).round();
          _restoreMana(target.id, manaBonus);
          break;
          
        // Add more effect types as needed
        default:
          // Fall back to normal effect application
          _applyCardEffectToTarget(card, caster, target);
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

  void _discardRandomCard(String playerId) {
    final player = getPlayerById(playerId);
    if (player == null || player.hand.isEmpty) return;
    
    final random = math.Random();
    final cardToDiscard = player.hand[random.nextInt(player.hand.length)];
    final updatedHand = List<ActionCard>.from(player.hand);
    updatedHand.remove(cardToDiscard);
    
    final updatedPlayer = player.copyWith(hand: updatedHand);
    _updatePlayer(updatedPlayer);
    
    _addBattleLog('${player.name} discards ${cardToDiscard.name}', player.name);
  }

  // Attack System with REBALANCED COSTS
  bool canAttack() {
    if (_currentPhase != BattlePhase.attackPhase) return false;
    if (_attackUsed) return false;
    if (_selectedTargetId == null) return false;
    
    final currentPlayer = getCurrentPlayer();
    if (currentPlayer == null) return false;
    
    // NEW: Attacks now cost significant mana (70-80% of max mana)
    final attackCost = (currentPlayer.maxMana * 0.75).round();
    if (currentPlayer.currentMana < attackCost) return false;
    
    final target = getPlayerById(_selectedTargetId!);
    return target != null;
  }

  void performAttack() {
    if (!canAttack()) return;
    
    final attacker = getCurrentPlayer();
    final target = getPlayerById(_selectedTargetId!);
    
    if (attacker == null || target == null) return;
    
    // Calculate attack cost (75% of max mana)
    final attackCost = (attacker.maxMana * 0.75).round();
    
    // Deduct mana for attack
    final updatedAttacker = attacker.copyWith(
      currentMana: math.max(0, attacker.currentMana - attackCost),
    );
    _updatePlayer(updatedAttacker);
    
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
      '${attacker.name} attacks ${target.name} for $finalDamage damage! (${target.currentHealth} → $newHealth HP) [-$attackCost MP]',
      attacker.name,
    );
    
    _attackUsed = true;
    _selectedTargetId = null;
    
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

  // Turn Management with TEAM ALTERNATION
  void startTurn() {
    _currentPhase = BattlePhase.startTurn;
    _attackUsed = false;
    _cardPlayedThisTurn = false;
    _selectedCard = null;
    _selectedTargetId = null;
    
    final currentPlayer = getCurrentPlayer();
    if (currentPlayer != null) {
      // Draw a card at the start of turn with popup
      _drawCardWithPopup(currentPlayer.id);
      
      // Restore some mana (25% of max mana per turn)
      final manaRestore = (currentPlayer.maxMana * 0.25).round();
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

  void _drawCardWithPopup(String playerId) {
    final player = getPlayerById(playerId);
    if (player == null) return;
    
    final availableCards = List<ActionCard>.from(player.actionDeck);
    if (availableCards.isNotEmpty) {
      final random = math.Random();
      final cardIndex = random.nextInt(availableCards.length);
      final drawnCard = availableCards[cardIndex];
      
      _drawnCard = drawnCard;
      _showCardDrawPopup = true;
      notifyListeners();
    }
  }

  void acceptDrawnCard() {
    final currentPlayer = getCurrentPlayer();
    final drawnCard = _drawnCard;
    
    if (currentPlayer == null || drawnCard == null) return;
    
    final updatedHand = List<ActionCard>.from(currentPlayer.hand);
    
    if (updatedHand.length >= 10) {
      // Hand is full - need to choose which card to discard
      _showHandOverflowDialog();
      return;
    }
    
    updatedHand.add(drawnCard);
    final updatedPlayer = currentPlayer.copyWith(hand: updatedHand);
    _updatePlayer(updatedPlayer);
    
    _addBattleLog('${currentPlayer.name} adds ${drawnCard.name} to hand.', currentPlayer.name);
    
    _dismissCardDrawPopup();
  }

  void discardDrawnCard() {
    final currentPlayer = getCurrentPlayer();
    final drawnCard = _drawnCard;
    
    if (currentPlayer == null || drawnCard == null) return;
    
    _addBattleLog('${currentPlayer.name} discards ${drawnCard.name}.', currentPlayer.name);
    
    _dismissCardDrawPopup();
  }

  void _dismissCardDrawPopup() {
    _drawnCard = null;
    _showCardDrawPopup = false;
    notifyListeners();
  }

  void _showHandOverflowDialog() {
    // This will be handled in the UI layer
    // For now, auto-discard the drawn card
    discardDrawnCard();
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
    
    // Move to next player using TEAM ALTERNATION
    _moveToNextPlayerTeamBased();
    
    // Start next turn
    Future.delayed(const Duration(milliseconds: 500), () {
      startTurn();
    });
    
    notifyListeners();
  }

  void _moveToNextPlayerTeamBased() {
    final currentPlayerIndex = _battle.players.indexWhere((p) => p.id == _battle.currentPlayerId);
    if (currentPlayerIndex == -1) return;
    
    final currentTeam = getPlayerTeam(_battle.currentPlayerId);
    final opposingTeam = currentTeam == 0 ? 1 : 0;
    
    // Get alive players from opposing team
    final opposingTeamPlayers = getTeamMembers(opposingTeam).where((p) => p.currentHealth > 0).toList();
    
    if (opposingTeamPlayers.isNotEmpty) {
      // Find next player in opposing team
      // Use round-robin within the team
      final currentOpposingIndex = opposingTeamPlayers.indexWhere((p) => 
          _battle.players.indexOf(p) > currentPlayerIndex);
      
      if (currentOpposingIndex != -1) {
        // Found a player in opposing team after current player
        _battle = _battle.copyWith(
          currentPlayerId: opposingTeamPlayers[currentOpposingIndex].id,
          currentTurn: _battle.currentTurn + 1,
        );
      } else {
        // No player found after current, take first alive opposing team player
        _battle = _battle.copyWith(
          currentPlayerId: opposingTeamPlayers.first.id,
          currentTurn: _battle.currentTurn + 1,
        );
      }
    } else {
      // No alive players in opposing team, continue with current team
      final currentTeamPlayers = getTeamMembers(currentTeam).where((p) => p.currentHealth > 0).toList();
      if (currentTeamPlayers.isNotEmpty) {
        final nextInTeam = currentTeamPlayers.firstWhere(
          (p) => _battle.players.indexOf(p) > currentPlayerIndex,
          orElse: () => currentTeamPlayers.first,
        );
        
        _battle = _battle.copyWith(
          currentPlayerId: nextInTeam.id,
          currentTurn: _battle.currentTurn + 1,
        );
      }
    }
  }

  // Battle Management
  void _checkBattleEnd() {
    final team0Players = getTeamMembers(0).where((p) => p.currentHealth > 0).toList();
    final team1Players = getTeamMembers(1).where((p) => p.currentHealth > 0).toList();
    
    if (team0Players.isEmpty || team1Players.isEmpty) {
      final winningTeam = team0Players.isNotEmpty ? 0 : 1;
      final winningPlayers = winningTeam == 0 ? team0Players : team1Players;
      final winner = winningPlayers.isNotEmpty ? winningPlayers.first : null;
      
      _battle = _battle.copyWith(
        status: BattleStatus.finished,
        winnerId: winner?.id,
        endTime: DateTime.now(),
      );
      
      if (winner != null) {
        _addBattleLog('Team ${winningTeam + 1} is victorious!', 'System');
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

  /// Trigger spectacular spell casting animation
  void _triggerSpellAnimation(ActionCard spell, String casterId, String targetId) {
    _currentSpellAnimation = spell;
    _spellCasterId = casterId;
    _spellTargetId = targetId;
    _showSpellAnimation = true;
    
    notifyListeners();
    
    // Auto-hide animation after duration
    Timer(const Duration(milliseconds: 3000), () {
      _showSpellAnimation = false;
      _currentSpellAnimation = null;
      _spellCasterId = null;
      _spellTargetId = null;
      notifyListeners();
    });
  }

  /// Apply status effects from spells and show banner
  void _applyStatusEffectFromSpell(ActionCard spell, BattlePlayer target) {
    final statusEffect = StatusEffectManager.getEffectForSpell(spell.name);
    
    // Add to player's status effects
    final updatedStatusEffects = Map<String, int>.from(target.statusEffects);
    updatedStatusEffects[statusEffect.name.toLowerCase()] = statusEffect.duration;
    
    final updatedTarget = target.copyWith(statusEffects: updatedStatusEffects);
    _updatePlayer(updatedTarget);
    
    // Show status effect banner
    _showStatusEffectBanner(statusEffect);
    
    _addBattleLog('⚡ ${target.name} is affected by ${statusEffect.name}!', 'System');
  }

  /// Show dramatic status effect banner
  void _showStatusEffectBanner(StatusEffect effect) {
    _currentStatusBanner = effect;
    _showStatusBanner = true;
    
    notifyListeners();
    
    // Auto-hide banner after 3 seconds
    Timer(const Duration(milliseconds: 3000), () {
      _showStatusBanner = false;
      _currentStatusBanner = null;
      notifyListeners();
    });
  }

  /// Manually trigger particle effects for testing
  void triggerTestParticleEffect(ParticleType type) {
    // This could be used for testing or special events
    notifyListeners();
  }

  /// Apply healing with visual effects
  void _applyHealingWithEffects(String playerId, int amount) {
    _healPlayer(playerId, amount);
    
    // Show healing effect
    _showStatusEffectBanner(StatusEffect.regenerating());
    
    final player = getPlayerById(playerId);
    if (player != null) {
      _addBattleLog('✨ ${player.name} heals for $amount HP!', 'System');
    }
  }

  /// Apply damage with visual effects
  void _applyDamageWithEffects(String playerId, int amount, {ParticleType? effectType}) {
    final player = getPlayerById(playerId);
    if (player == null) return;
    
    final newHealth = math.max(0, player.currentHealth - amount);
    final updatedPlayer = player.copyWith(currentHealth: newHealth);
    _updatePlayer(updatedPlayer);
    
    // Show damage effect
    if (effectType != null) {
      // Could trigger specific particle effect here
    }
    
    _addBattleLog('💥 ${player.name} takes $amount damage!', 'System');
    
    if (newHealth <= 0) {
      _addBattleLog('💀 ${player.name} has been defeated!', 'System');
      _checkBattleEnd();
    }
  }

  @override
  void dispose() {
    _spellCounterSystem.dispose();
    super.dispose();
  }
}