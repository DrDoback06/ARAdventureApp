import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/battle_model.dart';
import '../models/character_model.dart';
import '../models/card_model.dart';

enum BattlePhase {
  startTurn,
  drawPhase,
  actionPhase,
  attackPhase,
  endTurn,
}

enum SpellCounterState {
  none,
  waitingForCounter,
  countered,
  resolved,
}

class EnhancedBattleController extends ChangeNotifier {
  Battle battle;
  BattlePhase _currentPhase = BattlePhase.startTurn;
  SpellCounterState _spellCounterState = SpellCounterState.none;
  
  // Turn Management
  Timer? _turnTimer;
  Timer? _spellCounterTimer;
  int _turnTimeLimit = 60; // 60 seconds per turn
  int _spellCounterWindow = 5; // 5 seconds for spell countering
  int _currentTurnTime = 0;
  int _currentSpellCounterTime = 0;
  
  // Spell Countering System
  GameCard? _lastCastedSpell;
  BattlePlayer? _spellCaster;
  BattlePlayer? _spellTarget;
  List<GameCard> _availableCounters = [];
  
  // Three Hand System
  Map<String, List<ActionCard>> _actionHands = {};
  Map<String, List<GameCard>> _skillHands = {};
  Map<String, List<CardInstance>> _inventoryHands = {};
  
  // Battle State
  bool _isPaused = false;
  bool _showCalculator = false;
  String _battleLog = '';
  
  // Visual Effects
  bool _showTargeting = false;
  String? _hoveredTargetId;
  List<String> _validTargets = [];
  
  EnhancedBattleController(this.battle) {
    _initializeHands();
    _dealInitialCards();
  }

  // Getters
  BattlePhase get currentPhase => _currentPhase;
  SpellCounterState get spellCounterState => _spellCounterState;
  int get turnTimeRemaining => _turnTimeLimit - _currentTurnTime;
  int get spellCounterTimeRemaining => _spellCounterWindow - _currentSpellCounterTime;
  bool get isSpellCounterActive => _spellCounterState == SpellCounterState.waitingForCounter;
  GameCard? get lastCastedSpell => _lastCastedSpell;
  BattlePlayer? get spellCaster => _spellCaster;
  BattlePlayer? get spellTarget => _spellTarget;
  bool get showTargeting => _showTargeting;
  String? get hoveredTargetId => _hoveredTargetId;
  List<String> get validTargets => _validTargets;
  bool get showCalculator => _showCalculator;
  String get battleLog => _battleLog;

  // Initialize the three-hand system
  void _initializeHands() {
    for (final player in battle.players) {
      _actionHands[player.id] = [];
      _skillHands[player.id] = player.activeSkills;
      _inventoryHands[player.id] = player.character.equipment.getAllEquippedItems();
    }
  }

  // Deal initial cards to all players
  void _dealInitialCards() {
    for (final player in battle.players) {
      for (int i = 0; i < 5; i++) {
        _drawActionCard(player);
      }
    }
  }

  // Enhanced Turn Management
  void startTurn() {
    final currentPlayer = getCurrentPlayer();
    if (currentPlayer == null) return;

    _currentPhase = BattlePhase.startTurn;
    _currentTurnTime = 0;
    
    // Draw a card at the beginning of turn
    _drawActionCard(currentPlayer);
    _currentPhase = BattlePhase.actionPhase;
    
    // Start turn timer
    _startTurnTimer();
    
    // Reset spell counter state
    _resetSpellCounterState();
    
    _addBattleLog('${currentPlayer.name}\'s turn begins', currentPlayer.name);
    notifyListeners();
  }

  void endTurn() {
    _turnTimer?.cancel();
    _switchToNextPlayer();
    startTurn();
  }

  void _startTurnTimer() {
    _turnTimer?.cancel();
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentTurnTime >= _turnTimeLimit) {
        timer.cancel();
        _addBattleLog('Turn time expired!', 'System');
        endTurn();
      } else {
        _currentTurnTime++;
        notifyListeners();
      }
    });
  }

  void pauseTimer() {
    _turnTimer?.cancel();
    _isPaused = true;
  }

  void resumeTimer() {
    if (_isPaused) {
      _isPaused = false;
      _startTurnTimer();
    }
  }

  // Enhanced Spell Casting with Countering
  void castSpell(GameCard spell, BattlePlayer target) {
    final currentPlayer = getCurrentPlayer();
    if (currentPlayer == null) return;

    if (!canCastSpell(spell)) {
      _addBattleLog('Cannot cast spell: ${spell.name}', currentPlayer.name);
      return;
    }

    // Deduct mana
    final spellCost = spell.cost ?? 0;
    _restoreMana(currentPlayer.id, -spellCost);

    // Cast the spell
    _applySpellEffect(spell, currentPlayer, target);
    _addBattleLog('Cast spell: ${spell.name} on ${target.name}', currentPlayer.name);

    // Start spell counter window
    _startSpellCounterWindow(spell, currentPlayer, target);

    notifyListeners();
  }

  void _startSpellCounterWindow(GameCard spell, BattlePlayer caster, BattlePlayer target) {
    _spellCounterState = SpellCounterState.waitingForCounter;
    _lastCastedSpell = spell;
    _spellCaster = caster;
    _spellTarget = target;
    _currentSpellCounterTime = 0;
    
    // Get available counters for other players
    _availableCounters = _getAvailableCounters();
    
    _spellCounterTimer?.cancel();
    _spellCounterTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSpellCounterTime >= _spellCounterWindow) {
        timer.cancel();
        _resolveSpell();
      } else {
        _currentSpellCounterTime++;
        notifyListeners();
      }
    });
    
    _addBattleLog('Spell counter window opened (${_spellCounterWindow}s)', 'System');
    notifyListeners();
  }

  List<GameCard> _getAvailableCounters() {
    List<GameCard> counters = [];
    for (final player in battle.players) {
      if (player.id != _spellCaster?.id) {
        for (final skill in _skillHands[player.id] ?? []) {
          if (skill.customProperties['can_counter'] == true) {
            counters.add(skill);
          }
        }
      }
    }
    return counters;
  }

  void counterSpell(GameCard counterSpell, BattlePlayer counterCaster) {
    if (_spellCounterState != SpellCounterState.waitingForCounter) {
      _addBattleLog('No spell to counter', 'System');
      return;
    }

    if (!canCastSpell(counterSpell)) {
      _addBattleLog('Cannot cast counter spell: ${counterSpell.name}', counterCaster.name);
      return;
    }

    // Deduct mana for counter spell
    final counterCost = counterSpell.cost ?? 0;
    _restoreMana(counterCaster.id, -counterCost);

    // Apply counter effect
    _applyCounterEffect(counterSpell, counterCaster, _spellCaster!);
    _addBattleLog('Countered ${_lastCastedSpell?.name} with ${counterSpell.name}', counterCaster.name);

    // End counter window
    _spellCounterTimer?.cancel();
    _spellCounterState = SpellCounterState.countered;
    _resolveSpell();

    notifyListeners();
  }

                void _resolveSpell() {
                if (_spellCounterState == SpellCounterState.waitingForCounter) {
                  _spellCounterState = SpellCounterState.resolved;
                  _addBattleLog('Spell ${_lastCastedSpell?.name} resolved successfully', 'System');
                }
                
                _resetSpellCounterState();
                notifyListeners();
              }

              // Public method for UI to call
              void resolveSpell() {
                _resolveSpell();
              }

  void _resetSpellCounterState() {
    _spellCounterState = SpellCounterState.none;
    _lastCastedSpell = null;
    _spellCaster = null;
    _spellTarget = null;
    _availableCounters.clear();
    _spellCounterTimer?.cancel();
  }

  // Enhanced Attack System with Perfect Defense
  void performAttack(BattlePlayer attacker, BattlePlayer defender, int attackValue) {
    if (attacker.currentHealth <= 0 || defender.currentHealth <= 0) return;

    pauseTimer(); // Pause timer for calculations

    final totalAttack = _calculateTotalAttack(attacker, attackValue);
    final totalDefense = _calculateTotalDefense(defender);

    _addBattleLog('${attacker.name} attacks ${defender.name} for $totalAttack damage', attacker.name);
    
    int damage = 0;
    bool perfectDefense = false;

    if (totalAttack > totalDefense) {
      damage = totalAttack - totalDefense;
      _damagePlayer(defender.id, damage);
      _addBattleLog('${defender.name} takes $damage damage', defender.name);
    } else if (totalAttack == totalDefense && totalAttack > 0) {
      perfectDefense = true;
      _addBattleLog('Perfect defense! ${defender.name} blocks all damage!', defender.name);
    } else {
      _addBattleLog('${defender.name} blocks all damage!', defender.name);
    }

    // Check for perfect defense counter attack
    if (perfectDefense) {
      _addBattleLog('Perfect defense! ${defender.name} gets a counter attack!', defender.name);
      _performCounterAttack(defender, attacker);
    }

    resumeTimer(); // Resume timer after calculations
    notifyListeners();
  }

  void _performCounterAttack(BattlePlayer counterAttacker, BattlePlayer target) {
    final counterAttackValue = _calculateTotalAttack(counterAttacker, 0);
    final counterDefense = _calculateTotalDefense(target);
    final counterDamage = (counterAttackValue - counterDefense).clamp(0, counterAttackValue);

    if (counterDamage > 0) {
      _damagePlayer(target.id, counterDamage);
      _addBattleLog('${counterAttacker.name} counter attacks for $counterDamage damage!', counterAttacker.name);
    }
  }

  // Enhanced Card Management
  void _drawActionCard(BattlePlayer player) {
    if ((_actionHands[player.id]?.length ?? 0) >= 10) {
      _addBattleLog('${player.name} has maximum hand size', player.name);
      return;
    }

    // Generate a random action card
    final newCard = _generateRandomActionCard();
    _actionHands[player.id]?.add(newCard);
    _addBattleLog('${player.name} draws ${newCard.name}', player.name);
  }

  ActionCard _generateRandomActionCard() {
    final types = ActionCardType.values;
    final randomType = types[Random().nextInt(types.length)];
    
    return ActionCard(
      id: 'card_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Random ${randomType.name}',
      description: 'A randomly generated ${randomType.name} card',
      type: randomType,
      cost: 0,
      rarity: CardRarity.common,
      effect: 'random_effect',
    );
  }

  void playActionCard(ActionCard card, BattlePlayer? target) {
    final currentPlayer = getCurrentPlayer();
    if (currentPlayer == null) return;

    if (!canPlayCard(card)) {
      _addBattleLog('Cannot play card: ${card.name}', currentPlayer.name);
      return;
    }

    // Remove card from hand
    _actionHands[currentPlayer.id]?.remove(card);

    // Apply card effect
    _applyCardEffect(card, currentPlayer, target);
    _addBattleLog('Played card: ${card.name}', currentPlayer.name);

    notifyListeners();
  }

  void discardCard(ActionCard card) {
    final currentPlayer = getCurrentPlayer();
    if (currentPlayer == null) return;

    if (_actionHands[currentPlayer.id]?.contains(card) == true) {
      _actionHands[currentPlayer.id]?.remove(card);
      _addBattleLog('${currentPlayer.name} discards ${card.name}', currentPlayer.name);
      notifyListeners();
    }
  }

  // Enhanced Status Effect System
  void _applyStatusEffect(String playerId, String effectType, int duration) {
    final player = battle.players.firstWhere((p) => p.id == playerId);
    player.statusEffects[effectType] = {
      'value': _getEffectValue(effectType),
      'duration': duration,
      'applied_turn': battle.currentTurn,
    };
  }

  int _getEffectValue(String effectType) {
    switch (effectType) {
      case 'attack_bonus':
        return 10;
      case 'defense_bonus':
        return 8;
      case 'mana_restore':
        return 20;
      case 'heal':
        return 15;
      default:
        return 5;
    }
  }

  // Enhanced Battle State Management
  void _switchToNextPlayer() {
    final currentIndex = battle.players.indexWhere((p) => p.id == battle.currentPlayerId);
    final nextIndex = (currentIndex + 1) % battle.players.length;
    // Note: This would need to be implemented in the Battle model
    // For now, we'll just log the turn change
    _addBattleLog('Turn ${battle.currentTurn + 1} begins', 'System');
    
    // Update status effects
    _updateStatusEffects();
  }

  void _updateStatusEffects() {
    for (final player in battle.players) {
      final effectsToRemove = <String>[];
      
      for (final entry in player.statusEffects.entries) {
        final effect = entry.value as Map<String, dynamic>;
        final appliedTurn = effect['applied_turn'] as int;
        final duration = effect['duration'] as int;
        
        if (battle.currentTurn - appliedTurn >= duration) {
          effectsToRemove.add(entry.key);
        }
      }
      
      for (final effectKey in effectsToRemove) {
        player.statusEffects.remove(effectKey);
        _addBattleLog('${player.name}\'s $effectKey effect expired', player.name);
      }
    }
  }

  // Enhanced Calculation Methods
  int _calculateTotalAttack(BattlePlayer player, int additionalDamage) {
    int total = player.character.attack + additionalDamage;
    
    // Add equipment bonuses
    for (final item in player.character.equipment.getAllEquippedItems()) {
      total += item.card.attack;
    }
    
    // Add status effects
    final statusEffects = player.statusEffects;
    if (statusEffects['attack_bonus'] != null) {
      final effect = statusEffects['attack_bonus'] as Map<String, dynamic>;
      total += (effect['value'] as num).toInt();
    }
    
    return total;
  }

  int _calculateTotalDefense(BattlePlayer player) {
    int total = player.character.defense;
    
    // Add equipment bonuses
    for (final item in player.character.equipment.getAllEquippedItems()) {
      total += item.card.defense;
    }
    
    // Add status effects
    final statusEffects = player.statusEffects;
    if (statusEffects['defense_bonus'] != null) {
      final effect = statusEffects['defense_bonus'] as Map<String, dynamic>;
      total += (effect['value'] as num).toInt();
    }
    
    return total;
  }

  // Utility Methods
  BattlePlayer? getCurrentPlayer() {
    return battle.players.firstWhere((p) => p.id == battle.currentPlayerId);
  }

  bool canCastSpell(GameCard spell) {
    final currentPlayer = getCurrentPlayer();
    if (currentPlayer == null) return false;
    
    final spellCost = spell.cost ?? 0;
    if (currentPlayer.currentMana < spellCost) return false;
    if (battle.currentPlayerId != currentPlayer.id) return false;
    if (currentPlayer.currentHealth <= 0) return false;
    
    return true;
  }

  bool canPlayCard(ActionCard card) {
    final currentPlayer = getCurrentPlayer();
    if (currentPlayer == null) return false;
    if (battle.currentPlayerId != currentPlayer.id) return false;
    if (currentPlayer.currentHealth <= 0) return false;
    
    return true;
  }

  void _addBattleLog(String message, String actor) {
    final timestamp = DateTime.now();
    // Note: This would need to be implemented in the Battle model
    // For now, we'll just update our local battle log
    _battleLog = '${_battleLog}${timestamp.hour}:${timestamp.minute} - $actor: $message\n';
  }

  void _damagePlayer(String playerId, int damage) {
    final player = battle.players.firstWhere((p) => p.id == playerId);
    // Note: This would need to be implemented in the BattlePlayer model
    // For now, we'll just log the damage
    _addBattleLog('${player.name} takes $damage damage', 'System');
  }

  void _healPlayer(String playerId, int healAmount) {
    final player = battle.players.firstWhere((p) => p.id == playerId);
    // Note: This would need to be implemented in the BattlePlayer model
    // For now, we'll just log the heal
    _addBattleLog('${player.name} heals $healAmount health', 'System');
  }

  void _restoreMana(String playerId, int manaAmount) {
    final player = battle.players.firstWhere((p) => p.id == playerId);
    // Note: This would need to be implemented in the BattlePlayer model
    // For now, we'll just log the mana change
    _addBattleLog('${player.name} ${manaAmount > 0 ? 'gains' : 'loses'} ${manaAmount.abs()} mana', 'System');
  }

  void _applySpellEffect(GameCard spell, BattlePlayer caster, BattlePlayer target) {
    // Implement spell effects based on spell properties
    final effect = spell.customProperties['effect'];
    if (effect != null) {
      switch (effect) {
        case 'damage':
          final damage = spell.customProperties['damage'] ?? 20;
          _damagePlayer(target.id, damage);
          break;
        case 'heal':
          final heal = spell.customProperties['heal'] ?? 20;
          _healPlayer(target.id, heal);
          break;
        case 'buff':
          final buffType = spell.customProperties['buff_type'] ?? 'attack_bonus';
          final duration = spell.customProperties['duration'] ?? 3;
          _applyStatusEffect(target.id, buffType, duration);
          break;
        default:
          // Default effect
          break;
      }
    }
  }

  void _applyCounterEffect(GameCard counterSpell, BattlePlayer counterCaster, BattlePlayer originalCaster) {
    // Implement counter effects based on spell properties
    final effect = counterSpell.customProperties['effect'];
    if (effect == 'counter') {
      // Cancel the original spell
      _addBattleLog('${counterSpell.name} cancels the original spell!', counterCaster.name);
    } else {
      // Default counter effect
      _addBattleLog('${counterSpell.name} counters the spell!', counterCaster.name);
    }
  }

  void _applyCardEffect(ActionCard card, BattlePlayer caster, BattlePlayer? target) {
    // Implement action card effects
    switch (card.type) {
      case ActionCardType.damage:
        if (target != null) {
          final damage = card.cost ?? 10;
          _damagePlayer(target.id, damage);
        }
        break;
      case ActionCardType.heal:
        if (target != null) {
          final heal = card.cost ?? 10;
          _healPlayer(target.id, heal);
        }
        break;
      case ActionCardType.buff:
        if (target != null) {
          _applyStatusEffect(target.id, 'attack_bonus', 3);
        }
        break;
      default:
        // Default card effect
        break;
    }
  }

  // UI Control Methods
  void toggleCalculator() {
    _showCalculator = !_showCalculator;
    notifyListeners();
  }

  void setHoveredTarget(String? targetId) {
    _hoveredTargetId = targetId;
    notifyListeners();
  }

  void setValidTargets(List<String> targets) {
    _validTargets = targets;
    _showTargeting = targets.isNotEmpty;
    notifyListeners();
  }

  // Drag and Drop Methods for HearthstoneCardWidget
  ActionCard? _draggedCard;
  Offset? _dragPosition;

  ActionCard? get draggedCard => _draggedCard;
  bool get isDragging => _draggedCard != null;

  void startCardDrag(ActionCard card, Offset position) {
    _draggedCard = card;
    _dragPosition = position;
    notifyListeners();
  }

  void updateDragPosition(Offset position) {
    _dragPosition = position;
    notifyListeners();
  }

  void endDrag() {
    _draggedCard = null;
    _dragPosition = null;
    notifyListeners();
  }

  // Get hands for UI
  List<ActionCard> getActionHand(String playerId) => _actionHands[playerId] ?? [];
  List<GameCard> getSkillHand(String playerId) => _skillHands[playerId] ?? [];
  List<CardInstance> getInventoryHand(String playerId) => _inventoryHands[playerId] ?? [];

  // Use item method
  void useItem(CardInstance item) {
    final currentPlayer = getCurrentPlayer();
    if (currentPlayer == null) return;

    if (!canUseItem(item)) {
      _addBattleLog('Cannot use item: ${item.card.name}', currentPlayer.name);
      return;
    }

    _applyItemEffect(item, currentPlayer);
    _addBattleLog('Used item: ${item.card.name}', currentPlayer.name);
    notifyListeners();
  }

  bool canUseItem(CardInstance item) {
    final currentPlayer = getCurrentPlayer();
    if (currentPlayer == null) return false;
    if (battle.currentPlayerId != currentPlayer.id) return false;
    if (currentPlayer.currentHealth <= 0) return false;
    final isUsable = item.card.customProperties['usable'] == true;
    if (!isUsable) return false;
    return true;
  }

  void _applyItemEffect(CardInstance item, BattlePlayer player) {
    final effect = item.card.customProperties['effect'];
    if (effect != null) {
      switch (effect) {
        case 'heal':
          final healAmount = item.card.customProperties['heal_amount'] ?? 20;
          _healPlayer(player.id, healAmount);
          break;
        case 'mana_restore':
          final manaAmount = item.card.customProperties['mana_amount'] ?? 30;
          _restoreMana(player.id, manaAmount);
          break;
        case 'buff':
          final buffType = item.card.customProperties['buff_type'];
          final buffValue = item.card.customProperties['buff_value'] ?? 10;
          _applyStatusEffect(player.id, buffType, 3); // 3 turn duration
          break;
        default:
          _addBattleLog('Unknown item effect: $effect', 'System');
      }
    }
  }

  @override
  void dispose() {
    _turnTimer?.cancel();
    _spellCounterTimer?.cancel();
    super.dispose();
  }
} 