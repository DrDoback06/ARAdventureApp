import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:realm_of_valor/models/battle_model.dart';
import 'package:realm_of_valor/models/card_model.dart';
import 'package:realm_of_valor/models/character_model.dart';
import 'package:realm_of_valor/models/elemental_combo_system.dart';
import 'package:realm_of_valor/models/battle_result_model.dart';
import 'package:realm_of_valor/models/critical_hit_system.dart';
import 'package:realm_of_valor/models/team_system.dart';
import '../models/spell_counter_system.dart';
import '../models/unified_particle_system.dart';
import '../widgets/visual_effects_widget.dart';
import '../services/character_service.dart';
import '../services/audio_service.dart';
import '../services/screen_shake_service.dart';
import '../services/particle_system_service.dart';
import '../services/ai_battle_service.dart';
import '../services/battle_rewards_service.dart';
// import '../providers/character_provider.dart'; // Temporarily disabled
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:realm_of_valor/services/achievement_service.dart';
import 'package:realm_of_valor/services/daily_quest_service.dart';
import 'package:realm_of_valor/services/character_progression_service.dart';

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
  
  // Elemental Combo System
  final ElementalComboSystem _comboSystem = ElementalComboSystem();
  
  // Critical Hit System
  final CriticalHitSystem _criticalSystem = CriticalHitSystem();
  
  // Team System for coordinated attacks and chain reactions
  final TeamSystem _teamSystem = TeamSystem();
  
  // Spell Animation System
  ActionCard? _currentSpellAnimation;
  String? _spellCasterId;
  String? _spellTargetId;
  bool _showSpellAnimation = false;
  
  // Status Effect System - simplified
  bool _showStatusBanner = false;
  
  // Simplified Drag & Drop System
  ActionCard? _draggedCard;
  String? _hoveredTargetId;
  bool _isDragging = false;
  
  Timer? _turnTimer;
  int _turnTimeRemaining = 60; // 60 seconds per turn
  
  // Attack and Skill Cards
  List<ActionCard> _attackCards = [];
  List<ActionCard> _skillCards = [];
  List<ActionCard> _inventoryCards = [];
  
  // Visual Effects
  List<VisualEffect> _visualEffects = [];
  
  // Battle Tracking for Rewards
  int _damageDealt = 0;
  int _damageTaken = 0;
  int _cardsPlayed = 0;
  int _skillsUsed = 0;
  int _turnsTaken = 0;
  int _battleStreak = 0;
  bool _isVictory = false;
  bool _perfectVictory = true; // Track if no damage taken
  
  // Battle Rewards System
  List<BattleReward>? _battleRewards;
  BattlePerformance? _battlePerformance;
  bool _battleCompleted = false;
  BattleResult? _lastBattleResult;
  
  // Character Progression Integration - will use existing character provider
  // final CharacterService _characterService = CharacterService();
  
  // Dynamic Difficulty System
  double _difficultyMultiplier = 1.0;
  int _playerLevel = 1;
  int _playerPowerRating = 0;
  
  // Spell casting and counter system
  Timer? _spellCastTimer;
  ActionCard? _pendingSpell;
  String? _pendingSpellCaster;
  String? _pendingSpellTarget;
  int _spellCounterTimeRemaining = 0;
  List<String> _ghostCardsInHand = []; // Cards that are "used" but not discarded yet

  // Getters for UI
  ActionCard? get draggedCard => _draggedCard;
  List<ActionCard> get attackCards => _attackCards;
  List<ActionCard> get skillCards => _skillCards;
  List<ActionCard> get inventoryCards => _inventoryCards;
  List<VisualEffect> get visualEffects => _visualEffects;
  int get damageDealt => _damageDealt;
  int get damageTaken => _damageTaken;
  int get cardsPlayed => _cardsPlayed;
  int get skillsUsed => _skillsUsed;
  int get turnsTaken => _turnsTaken;
  String? get hoveredTargetId => _hoveredTargetId;
  bool get isDragging => _isDragging;
  List<BattleReward>? get battleRewards => _battleRewards;
  BattlePerformance? get battlePerformance => _battlePerformance;
  bool get battleCompleted => _battleCompleted;
  BattleResult? get lastBattleResult => _lastBattleResult;
  int get turnTimeRemaining => _turnTimeRemaining;
  int get spellCounterTimeRemaining => _spellCounterTimeRemaining;
  ActionCard? get pendingSpell => _pendingSpell;
  String? get pendingSpellCaster => _pendingSpellCaster;
  String? get pendingSpellTarget => _pendingSpellTarget;
  List<String> get ghostCardsInHand => _ghostCardsInHand;

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
  bool get showStatusBanner => _showStatusBanner;
  
      // Legacy compatibility getters
    Offset? get dragStartPosition => null; // Simplified - no longer tracking position
    String? get draggedAction => _draggedCard?.effect;
  
  // Additional getters for enhanced functionality
  List<BattlePlayer> get allPlayers => _battle.players;

  void _initializeBattle() {
    if (_battle.status == BattleStatus.waiting) {
      _startBattle();
    }
  }

  /// Generate Attack Card for a player based on their stats and equipment
  ActionCard _generateAttackCard(BattlePlayer player) {
    int baseDamage = player.character.attackRating;
    
    // Calculate equipment bonuses
    Map<String, int> damageModifiers = {};
    final equippedItems = player.character.equipment.getAllEquippedItems();
    for (var item in equippedItems) {
      if (item.card.type == CardType.weapon) {
        // Add weapon damage bonus
        damageModifiers['weapon_${item.card.name}'] = item.card.attack;
      } else if (item.card.type == CardType.accessory) {
        // Add accessory bonuses
        damageModifiers['accessory_${item.card.name}'] = item.card.attack;
      }
    }
    
    // Calculate total damage
    int totalDamage = baseDamage;
    damageModifiers.forEach((key, value) {
      totalDamage += value;
    });
    
    return ActionCard(
      name: 'Attack',
      description: 'Deal $totalDamage damage',
      type: ActionCardType.damage,
      effect: 'physical_attack:$totalDamage',
      cost: 0,
      rarity: CardRarity.common,
      properties: {
        'baseDamage': baseDamage,
        'damageModifiers': damageModifiers,
        'totalDamage': totalDamage,
        'characterId': player.id,
      },
    );
  }

  /// Generate Skill Cards for a player based on their class and level
  List<ActionCard> _generateSkillCards(BattlePlayer player) {
    List<ActionCard> skills = [];
    
    // Generate skills based on player class
    switch (player.character.characterClass.toString().toLowerCase()) {
      case 'barbarian':
        skills.addAll([
          ActionCard(
            name: 'Berserker Rage',
            description: 'Gain +20 attack for 3 turns',
            type: ActionCardType.buff,
            effect: 'berserker_rage',
            cost: 6,
            rarity: CardRarity.rare,
            properties: {
              'skillType': 'active',
              'duration': 3,
              'attackBonus': 20,
              'characterId': player.id,
            },
          ),
          ActionCard(
            name: 'Whirlwind',
            description: 'Deal 25 damage to all enemies',
            type: ActionCardType.damage,
            effect: 'whirlwind',
            cost: 7,
            rarity: CardRarity.rare,
            properties: {
              'skillType': 'active',
              'damage': 25,
              'target': 'all_enemies',
              'characterId': player.id,
            },
          ),
        ]);
        break;
      case 'paladin':
        skills.addAll([
          ActionCard(
            name: 'Divine Light',
            description: 'Heal 30 HP and gain +10 defense',
            type: ActionCardType.heal,
            effect: 'divine_light',
            cost: 5,
            rarity: CardRarity.rare,
            properties: {
              'skillType': 'active',
              'heal': 30,
              'defenseBonus': 10,
              'characterId': player.id,
            },
          ),
          ActionCard(
            name: 'Shield Bash',
            description: 'Deal 15 damage and stun for 1 turn',
            type: ActionCardType.damage,
            effect: 'shield_bash',
            cost: 4,
            rarity: CardRarity.rare,
            properties: {
              'skillType': 'active',
              'damage': 15,
              'stun': 1,
              'characterId': player.id,
            },
          ),
        ]);
        break;
      case 'sorceress':
        skills.addAll([
          ActionCard(
            name: 'Fireball',
            description: 'Deal 35 fire damage',
            type: ActionCardType.spell,
            effect: 'fireball',
            cost: 6,
            rarity: CardRarity.rare,
            properties: {
              'skillType': 'active',
              'damage': 35,
              'element': 'fire',
              'characterId': player.id,
            },
          ),
          ActionCard(
            name: 'Ice Shield',
            description: 'Gain 20 shield points',
            type: ActionCardType.buff,
            effect: 'ice_shield',
            cost: 4,
            rarity: CardRarity.rare,
            properties: {
              'skillType': 'active',
              'shield': 20,
              'characterId': player.id,
            },
          ),
        ]);
        break;
      case 'amazon':
        skills.addAll([
          ActionCard(
            name: 'Multi Shot',
            description: 'Deal 20 damage to 3 random enemies',
            type: ActionCardType.damage,
            effect: 'multi_shot',
            cost: 5,
            rarity: CardRarity.rare,
            properties: {
              'skillType': 'active',
              'damage': 20,
              'targets': 3,
              'characterId': player.id,
            },
          ),
          ActionCard(
            name: 'Poison Arrow',
            description: 'Deal 15 damage and apply poison for 3 turns',
            type: ActionCardType.debuff,
            effect: 'poison_arrow',
            cost: 4,
            rarity: CardRarity.rare,
            properties: {
              'skillType': 'active',
              'damage': 15,
              'poison': 3,
              'characterId': player.id,
            },
          ),
        ]);
        break;
    }
    
    return skills;
  }

  void _setupSpellCounterCallbacks() {
    _spellCounterSystem.onSpellResolved = (pendingSpell, counters, effectMultiplier, messages) {
      _resolveSpellWithCounterResult(pendingSpell, counters, effectMultiplier, messages);
    };
  }

  void _startBattle() {
    if (_battle.status != BattleStatus.active) {
      _battle = _battle.copyWith(
        status: BattleStatus.active,
        startTime: DateTime.now(),
      );
      
      // Initialize difficulty scaling
      initializeBattleWithDifficulty();
      
      // Reset battle tracking
      _resetBattleTracking();
      
      _addBattleLog('⚔️ Battle begins!', 'System');
      notifyListeners();
    }
    
    // Initialize attack and skill cards for all players
    _initializePlayerCards();
    
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

  void _initializePlayerCards() {
    _attackCards.clear();
    _skillCards.clear();
    _inventoryCards.clear();
    
    // Generate attack and skill cards for current player
    final currentPlayer = getCurrentPlayer();
    if (currentPlayer != null) {
      _attackCards.add(_generateAttackCard(currentPlayer));
      _skillCards.addAll(_generateSkillCards(currentPlayer));
      
      // Add inventory items as cards
      for (var item in currentPlayer.character.inventory) {
        if (item.card.type == CardType.consumable || item.card.type == CardType.spell) {
          _inventoryCards.add(ActionCard(
            name: item.card.name,
            description: item.card.description,
            type: ActionCardType.special,
            effect: 'inventory_item:${item.card.id}',
            cost: item.card.cost,
            rarity: item.card.rarity,
            properties: {
              'itemId': item.card.id,
              'itemType': item.card.type.toString(),
              'characterId': currentPlayer.id,
            },
          ));
        }
      }
    }
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
    
    // FIXED: Properly toggle card selection and prevent double-play
    if (_selectedCard?.id == card.id) {
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
    
    // Track the action for rewards
    if (card.type == ActionCardType.damage) {
      trackDamageDealt(card.properties['totalDamage'] ?? 0);
    }
    trackCardPlayed();
    
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
    if (_pendingSpell == null || _spellCounterTimeRemaining <= 0) return false;
    
    final currentPlayer = getCurrentPlayer();
    if (currentPlayer == null || currentPlayer.currentMana < counterSpell.cost) {
      _playErrorSound();
      return false;
    }
    
    // Consume mana for counter attempt
    final updatedPlayer = currentPlayer.copyWith(
      currentMana: currentPlayer.currentMana - counterSpell.cost,
    );
    _updatePlayer(updatedPlayer);
    
    // Remove counter card from hand
    final updatedHand = List<ActionCard>.from(currentPlayer.hand);
    updatedHand.removeWhere((card) => card.id == counterSpell.id);
    final finalPlayer = updatedPlayer.copyWith(hand: updatedHand);
    _updatePlayer(finalPlayer);
    
    // Calculate counter success based on card power and element matching
    final success = _calculateCounterSuccess(counterSpell, _pendingSpell!);
    
    if (success) {
      _addBattleLog('✋ ${currentPlayer.name} counters ${_pendingSpell!.name} with ${counterSpell.name}!', currentPlayer.name);
      _playSpellCounterSound();
      
      // Return mana to original caster
      if (_pendingSpellCaster != null) {
        final caster = getPlayerById(_pendingSpellCaster!);
        if (caster != null) {
          final refundedCaster = caster.copyWith(
            currentMana: caster.currentMana + _pendingSpell!.cost,
          );
          _updatePlayer(refundedCaster);
        }
      }
      
      // Cancel the spell
      _cancelSpell();
      return true;
    } else {
      _addBattleLog('❌ ${currentPlayer.name}\'s counter attempt failed! ${_pendingSpell!.name} continues...', currentPlayer.name);
      _playCounterFailSound();
      return false;
    }
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
    // Handle cards with no specific effects but have damage type
    if (card.effect.isEmpty && card.type == ActionCardType.damage) {
      // Default damage based on cost
      final damageAmount = math.max(1, card.cost * 2);
      final newHealth = math.max(0, target.currentHealth - damageAmount);
      final updatedTarget = target.copyWith(currentHealth: newHealth);
      _updatePlayer(updatedTarget);
      _addBattleLog('${caster.name} casts ${card.name} dealing $damageAmount damage to ${target.name}!', caster.name);
      
      if (newHealth <= 0) {
        _addBattleLog('${target.name} has been defeated!', 'System');
        _checkBattleEnd();
      }
      return;
    }
    
    // Handle cards with no specific effects but have heal type
    if (card.effect.isEmpty && card.type == ActionCardType.heal) {
      final healAmount = math.max(1, card.cost * 3);
      _healPlayer(target.id, healAmount);
      return;
    }
    
    final effects = card.effect.split(',');
    
    for (final effect in effects) {
      final parts = effect.trim().split(':');
      final effectType = parts[0];
      final effectValue = parts.length > 1 ? parts[1] : '';
      
      switch (effectType) {
        case 'damage_bonus':
          final bonus = int.tryParse(effectValue) ?? 0;
          _addBattleLog('${target.name} gains +$bonus attack damage!', caster.name);
          // Apply temporary damage bonus
          final updatedStatusEffects = Map<String, int>.from(target.statusEffects);
          updatedStatusEffects['damage_bonus'] = 3; // Lasts 3 turns
          final updatedTarget = target.copyWith(statusEffects: updatedStatusEffects);
          _updatePlayer(updatedTarget);
          break;
          
        case 'double_damage':
          _addBattleLog('${target.name}\'s next attack will deal double damage!', caster.name);
          final updatedStatusEffects = Map<String, int>.from(target.statusEffects);
          updatedStatusEffects['double_damage'] = 1; // Next attack only
          final updatedTarget = target.copyWith(statusEffects: updatedStatusEffects);
          _updatePlayer(updatedTarget);
          break;
          
        case 'half_damage':
          _addBattleLog('${target.name}\'s next attack will deal half damage!', caster.name);
          final updatedStatusEffects = Map<String, int>.from(target.statusEffects);
          updatedStatusEffects['weakened'] = 2; // Lasts 2 turns
          final updatedTarget = target.copyWith(statusEffects: updatedStatusEffects);
          _updatePlayer(updatedTarget);
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
          final updatedStatusEffects = Map<String, int>.from(target.statusEffects);
          updatedStatusEffects['extra_attack'] = 1; // This turn only
          final updatedTarget = target.copyWith(statusEffects: updatedStatusEffects);
          _updatePlayer(updatedTarget);
          break;
          
        case 'damage':
          final damageAmount = int.tryParse(effectValue) ?? 0;
          if (damageAmount > 0) {
            _applyDamageWithEffects(target.id, damageAmount, effectType: ParticleType.fire);
          }
          break;
          
        case 'physical_attack':
          // For Attack cards, use the totalDamage from properties
          int attackDamage = card.properties['totalDamage'] ?? 0;
          if (attackDamage == 0) {
            // Fallback to base damage calculation
            attackDamage = caster.character.attackRating;
            // Add equipment bonuses
            final equippedItems = caster.character.equipment.getAllEquippedItems();
            for (var item in equippedItems) {
              if (item.card.type == CardType.weapon) {
                attackDamage += item.card.attack;
              }
            }
          }
          
          if (attackDamage > 0) {
            final finalDamage = math.max(1, attackDamage - target.character.defense);
            final newHealth = math.max(0, target.currentHealth - finalDamage);
            final updatedTarget = target.copyWith(currentHealth: newHealth);
            _updatePlayer(updatedTarget);
            _addBattleLog('${caster.name}\'s attack deals $finalDamage damage to ${target.name}! (${target.currentHealth} → $newHealth HP)', caster.name);
            
            if (newHealth <= 0) {
              _addBattleLog('${target.name} has been defeated!', 'System');
              _checkBattleEnd();
            }
          }
          break;
          
        case 'direct_damage':
          final damageAmount = int.tryParse(effectValue) ?? 0;
          if (damageAmount > 0) {
            final newHealth = math.max(0, target.currentHealth - damageAmount);
            final updatedTarget = target.copyWith(currentHealth: newHealth);
            _updatePlayer(updatedTarget);
            _addBattleLog('${caster.name}\'s spell deals $damageAmount damage to ${target.name}! (${target.currentHealth} → $newHealth HP)', caster.name);
            
            if (newHealth <= 0) {
              _addBattleLog('${target.name} has been defeated!', 'System');
              _checkBattleEnd();
            }
          }
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

  // Enhanced Attack System with better validation
  bool canAttack() {
    // Check if it's the player's turn
    if (_currentPhase != BattlePhase.playPhase && _currentPhase != BattlePhase.attackPhase) {
      return false;
    }
    
    // Check if attack was already used this turn
    if (_attackUsed) {
      return false;
    }
    
    // Check if a target is selected
    if (_selectedTargetId == null) {
      return false;
    }
    
    final currentPlayer = getCurrentPlayer();
    if (currentPlayer == null) {
      return false;
    }
    
    // Check if target is valid (not self, not defeated)
    final target = getPlayerById(_selectedTargetId!);
    if (target == null || target.id == currentPlayer.id || target.currentHealth <= 0) {
      return false;
    }
    
    // Check mana cost (30% of max mana)
    final attackCost = (currentPlayer.maxMana * 0.3).round();
    if (currentPlayer.currentMana < attackCost) {
      return false;
    }
    
    return true;
  }

  void performAttack() {
    if (!canAttack()) return;
    
    final attacker = getCurrentPlayer();
    final target = getPlayerById(_selectedTargetId!);
    
    if (attacker == null || target == null) return;
    
    // Calculate attack cost (30% of max mana)
    final attackCost = (attacker.maxMana * 0.3).round();
    
    // Deduct mana for attack
    final updatedAttacker = attacker.copyWith(
      currentMana: math.max(0, attacker.currentMana - attackCost),
    );
    _updatePlayer(updatedAttacker);
    
    // Calculate damage
    int baseDamage = attacker.character.attackRating;
    
    // Apply equipment bonuses
    int equipmentBonus = 0;
    final equippedItems = attacker.character.equipment.getAllEquippedItems();
    for (var item in equippedItems) {
      if (item.card.type == CardType.weapon) {
        equipmentBonus += item.card.attack;
      }
    }
    
    final totalDamage = baseDamage + equipmentBonus;
    final finalDamage = math.max(1, totalDamage - target.character.defense);
    
    // Apply damage
    final newHealth = math.max(0, target.currentHealth - finalDamage);
    final updatedTarget = target.copyWith(currentHealth: newHealth);
    _updatePlayer(updatedTarget);
    
    _addBattleLog(
      '${attacker.name} attacks ${target.name} for $finalDamage damage! (${target.currentHealth} → $newHealth HP) [-$attackCost MP]',
      attacker.name,
    );
    
    // Track the attack for rewards
    trackDamageDealt(finalDamage);
    
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
    
    // Check if player has enough mana
    final skillCost = skill.cost ?? 0;
    if (currentPlayer.currentMana < skillCost) return false;
    
    // Check if it's the player's turn
    if (battle.currentPlayerId != currentPlayer.id) return false;
    
    // Check if player is alive
    if (currentPlayer.currentHealth <= 0) return false;
    
    return true;
  }

  void useSkill(GameCard skill) {
    if (!canUseSkill(skill)) {
      print('[BATTLE] Cannot use skill: ${skill.name}');
      return;
    }

    final currentPlayer = getCurrentPlayer();
    if (currentPlayer == null) return;

    // Deduct mana cost
    final skillCost = skill.cost ?? 0;
    _restoreMana(currentPlayer.id, -skillCost);

    // Apply skill effects
    _applySkillEffect(skill, currentPlayer);

    // Add to battle log
    _addBattleLog('Used skill: ${skill.name}', currentPlayer.name);

    notifyListeners();
  }

  bool canUseItem(CardInstance item) {
    final currentPlayer = getCurrentPlayer();
    if (currentPlayer == null) return false;
    
    // Check if it's the player's turn
    if (battle.currentPlayerId != currentPlayer.id) return false;
    
    // Check if player is alive
    if (currentPlayer.currentHealth <= 0) return false;
    
    // Check if item is usable (has usable property)
    final isUsable = item.card.customProperties['usable'] == true;
    if (!isUsable) return false;
    
    return true;
  }

  void useItem(CardInstance item) {
    if (!canUseItem(item)) {
      print('[BATTLE] Cannot use item: ${item.card.name}');
      return;
    }

    final currentPlayer = getCurrentPlayer();
    if (currentPlayer == null) return;

    // Apply item effects
    _applyItemEffect(item, currentPlayer);

    // Add to battle log
    _addBattleLog('Used item: ${item.card.name}', currentPlayer.name);

    notifyListeners();
  }

  void _applyItemEffect(CardInstance item, BattlePlayer player) {
    // Apply item effects based on item properties
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
          print('[BATTLE] Unknown item effect: $effect');
      }
    }
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
      // FIXED: All players draw cards from turn 1, not just from turn 3
      _drawCardWithPopup(currentPlayer.id);
      
      // Restore some mana (50% of max mana per turn for faster gameplay)
      final manaRestore = (currentPlayer.maxMana * 0.5).round();
      if (manaRestore > 0) {
        _restoreMana(currentPlayer.id, manaRestore);
      }
      
      _addBattleLog('${currentPlayer.name}\'s turn begins!', currentPlayer.name);
    }
    
    // Start turn timer
    _startTurnTimer();
    
    // FIXED: Immediately move to play phase so player can act
    _currentPhase = BattlePhase.playPhase;
    _showPhaseIndicatorWithDelay();
    notifyListeners();
  }

  void _drawCards(String playerId, int count) {
    final player = getPlayerById(playerId);
    if (player == null) return;
    
    final availableCards = List<ActionCard>.from(player.actionDeck);
    if (availableCards.isEmpty) return;
    
    final random = math.Random();
    final updatedHand = List<ActionCard>.from(player.hand);
    
    for (int i = 0; i < count && availableCards.isNotEmpty; i++) {
      final cardIndex = random.nextInt(availableCards.length);
      final drawnCard = availableCards[cardIndex];
      
      if (updatedHand.length < 10) { // Max hand size
        updatedHand.add(drawnCard);
        availableCards.removeAt(cardIndex);
      }
    }
    
    final updatedPlayer = player.copyWith(hand: updatedHand);
    _updatePlayer(updatedPlayer);
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
    
    // Track turn completion for rewards
    _trackTurnCompleted();
    
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
    
    // Get all alive players
    final alivePlayers = _battle.players.where((p) => p.currentHealth > 0).toList();
    if (alivePlayers.isEmpty) return;
    
    // Find the next alive player in order
    int nextIndex = currentPlayerIndex;
    do {
      nextIndex = (nextIndex + 1) % _battle.players.length;
    } while (_battle.players[nextIndex].currentHealth <= 0);
    
    _battle = _battle.copyWith(
      currentPlayerId: _battle.players[nextIndex].id,
      currentTurn: _battle.currentTurn + 1,
    );
  }

  // Battle Management
  void _checkBattleEnd() {
    final alivePlayers = _battle.players.where((player) => player.currentHealth > 0).toList();
    
    if (alivePlayers.length <= 1) {
      _battle = _battle.copyWith(status: BattleStatus.finished);
      
      // Determine winner and apply rewards
      if (alivePlayers.isNotEmpty) {
        final winner = alivePlayers.first;
        _isVictory = winner.id == getCurrentPlayer()?.id;
        
        // Track achievements and quests
        _trackBattleAchievements();
        _trackDailyQuests();
        
        // Award experience
        _awardExperience();
        
        // Calculate battle performance
        final performance = BattleRewardsService.instance.calculatePerformance(
          damageDealt: _damageDealt,
          damageTaken: _damageTaken,
          cardsPlayed: _cardsPlayed,
          turnsTaken: _turnsTaken,
          isVictory: _isVictory,
          playerLevel: getCurrentPlayer()?.character.level ?? 1,
          battleStreak: _battleStreak,
        );
        
        // Generate rewards
        final rewards = BattleRewardsService.instance.generateRewards(
          performance: performance,
          playerLevel: getCurrentPlayer()?.character.level ?? 1,
          battleStreak: _battleStreak,
          isVictory: _isVictory,
        );
        
        // Apply rewards (this will be handled by the UI)
        _battleRewards = rewards;
        _battlePerformance = performance;
        
        _addBattleLog(
          _isVictory 
              ? '${winner.name} wins the battle!' 
              : 'Battle ended. ${winner.name} is victorious!',
          'System',
        );
      } else {
        _addBattleLog('Battle ended in a draw!', 'System');
      }
      
      _turnTimer?.cancel();
      notifyListeners();
    }
  }

  /// Track battle-related achievements
  void _trackBattleAchievements() {
    final achievementService = AchievementService.instance;
    
    // First Blood achievement
    if (_isVictory) {
      achievementService.updateProgress('first_blood', 1);
    }
    
    // Battle Master achievement (win 10 battles)
    if (_isVictory) {
      achievementService.updateProgress('battle_master', 1);
    }
    
    // Legendary Warrior achievement (win 50 battles)
    if (_isVictory) {
      achievementService.updateProgress('legendary_warrior', 1);
    }
    
    // Perfect Victory achievement (win without taking damage)
    if (_isVictory && _perfectVictory) {
      achievementService.updateProgress('perfect_victory', 1);
    }
    
    // Streak Master achievement (win 5 battles in a row)
    if (_isVictory) {
      achievementService.updateProgress('streak_master', 1);
    }
  }

  /// Track daily quest progress
  void _trackDailyQuests() {
    final questService = DailyQuestService.instance;
    
    // Battle quests
    if (_isVictory) {
      questService.updateProgressByType(QuestType.battle, 1);
    }
    
    // Special quests (perfect victory)
    if (_isVictory && _perfectVictory) {
      questService.updateProgressByType(QuestType.special, 1);
    }
  }

  /// Award experience and track character progression
  void _awardExperience() {
    final progressionService = CharacterProgressionService.instance;
    
    // Award base experience for battle completion
    int baseExp = 50;
    
    // Bonus experience for victory
    if (_isVictory) {
      baseExp += 100;
      
      // Bonus for perfect victory
      if (_perfectVictory) {
        baseExp += 50;
      }
      
      // Bonus for battle difficulty
      baseExp += (10 * _difficultyMultiplier).round();
    }
    
    // Award experience to current player
    final currentPlayer = getCurrentPlayer();
    if (currentPlayer != null) {
      progressionService.addExperience(baseExp);
      
      if (kDebugMode) {
        print('[BattleController] Awarded $baseExp XP to ${currentPlayer.name}');
      }
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
    
    // Keep only last 50 log entries to prevent memory issues
    if (updatedLog.length > 50) {
      updatedLog.removeRange(0, updatedLog.length - 50);
    }
    
    _battle = _battle.copyWith(battleLog: updatedLog);
    
    // Debug logging
    if (kDebugMode) {
      print('[BATTLE LOG] $description');
    }
  }

  /// Add formatted battle log entry with emojis and styling
  void _addFormattedBattleLog(String message, String playerName, {String? emoji}) {
    final formattedMessage = emoji != null ? '$emoji $message' : message;
    _addBattleLog(formattedMessage, playerName);
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
    final effectName = _getSimpleStatusEffectName(spell.name);
    
    // Add to player's status effects
    final updatedStatusEffects = Map<String, int>.from(target.statusEffects);
    updatedStatusEffects[effectName] = 3; // Default duration
    
    final updatedTarget = target.copyWith(statusEffects: updatedStatusEffects);
    _updatePlayer(updatedTarget);
    
    _addBattleLog('⚡ ${target.name} is affected by $effectName!', 'System');
  }
  
  /// Get simple status effect name for spell
  String _getSimpleStatusEffectName(String spellName) {
    final name = spellName.toLowerCase();
    
    if (name.contains('fire') || name.contains('burn') || name.contains('flame')) {
      return 'burning';
    } else if (name.contains('ice') || name.contains('frost') || name.contains('freeze')) {
      return 'frozen';
    } else if (name.contains('lightning') || name.contains('shock') || name.contains('thunder')) {
      return 'shocked';
    } else if (name.contains('heal') || name.contains('regenerate') || name.contains('cure')) {
      return 'regenerating';
    } else if (name.contains('shield') || name.contains('protect') || name.contains('barrier')) {
      return 'shielded';
    } else if (name.contains('bless') || name.contains('divine') || name.contains('holy')) {
      return 'blessed';
    } else if (name.contains('curse') || name.contains('weaken') || name.contains('debuff')) {
      return 'weakened';
    } else if (name.contains('silence') || name.contains('mute') || name.contains('quiet')) {
      return 'silenced';
    } else if (name.contains('strength') || name.contains('power') || name.contains('might')) {
      return 'strengthened';
    } else {
      return 'blessed'; // Default effect
    }
  }

  /// Show status effect message
  void _showStatusEffectMessage(String effectName) {
    _addBattleLog('✨ Status effect: $effectName', 'System');
  }

  /// Manually trigger particle effects for testing
  void triggerTestParticleEffect(ParticleType type) {
    // This could be used for testing or special events
    notifyListeners();
  }
  
  // =================== NEW HELPER METHODS ===================
  
  /// Play error sound when action cannot be performed
  void _playErrorSound() {
    AudioService.instance.playError();
  }
  
  /// Play sound when lifting a card
  void _playCardLiftSound(ActionCard card) {
    AudioService.instance.playCardLift();
  }
  
  /// Play sound when lifting attack button
  void _playAttackLiftSound() {
    AudioService.instance.playAttack();
  }
  
  /// Play sound when hovering over valid target
  void _playTargetHoverSound() {
    AudioService.instance.playTargetHover();
  }
  
  /// Play sound when casting spell
  void _playSpellCastSound(ActionCard spell) {
    AudioService.instance.playSpellCast();
  }
  
  /// Play sound when spell resolves
  void _playSpellResolveSound(ActionCard spell) {
    AudioService.instance.playSpellResolve();
  }
  
  /// Play attack sound
  void _playAttackSound() {
    AudioService.instance.playAttack();
  }
  
  /// Get target at screen position
  String? _getTargetAtPosition(Offset position) {
    // TODO: Implement hit testing for player portraits
    // For now, return null - this will be implemented when we update the UI
    return null;
  }
  

  
  /// Check if a target is valid for current drag operation
  bool isValidDragTarget(String targetId) {
    if (!_isDragging) return false;
    
    final target = getPlayerById(targetId);
    if (target == null || target.currentHealth <= 0) return false;
    
    final currentPlayer = getCurrentPlayer();
    if (currentPlayer == null) return false;
    
    // Attack targeting rules
    if (_draggedCard?.effect == 'ATTACK') {
      return !isFriendly(targetId);
    }
    
    // Card targeting rules
    if (_draggedCard != null) {
      switch (_draggedCard!.type) {
        case ActionCardType.heal:
        case ActionCardType.buff:
          return true; // Can target anyone
        case ActionCardType.damage:
        case ActionCardType.debuff:
        case ActionCardType.spell:
          return !isFriendly(targetId);
        case ActionCardType.special:
        case ActionCardType.counter:
          return true;
        default:
          return true;
      }
    }
    
    return false;
  }
  
  /// Animate card snapping back to hand
  void _snapBackToHand() {
    // TODO: Implement snap-back animation
    print('[ANIMATION] Card snaps back to hand');
  }
  
  /// Set hovered target during drag
  void setHoveredTarget(String? targetId) {
    if (_hoveredTargetId != targetId) {
      _hoveredTargetId = targetId;
      notifyListeners();
    }
  }
  
  /// Clear all drag state
  void _clearDragState() {
    _draggedCard = null;
    _hoveredTargetId = null;
    _isDragging = false;
    notifyListeners();
  }
  
  /// Start spell cast particle effects
  void _startSpellCastParticles(ActionCard spell, String targetId) {
    // TODO: Implement spell casting particles
    print('[PARTICLES] Spell casting: ${spell.name} -> $targetId');
  }
  
  /// Start attack animation
  void _startAttackAnimation(String targetId) {
    // TODO: Implement attack animation
    print('[ANIMATION] Attack -> $targetId');
  }
  
  /// Cancel pending spell
  void _cancelSpell() {
    if (_spellCastTimer != null) {
      _spellCastTimer!.cancel();
      _spellCastTimer = null;
    }
    
    // Return mana if spell was cancelled
    if (_pendingSpell != null && _pendingSpellCaster != null) {
      final caster = getPlayerById(_pendingSpellCaster!);
      if (caster != null) {
        final updatedCaster = caster.copyWith(
          currentMana: caster.currentMana + _pendingSpell!.cost,
        );
        _updatePlayer(updatedCaster);
      }
    }
    
    _ghostCardsInHand.removeWhere((id) => id == (_pendingSpell?.id ?? ''));
    
    _pendingSpell = null;
    _pendingSpellCaster = null;
    _pendingSpellTarget = null;
    _spellCounterTimeRemaining = 0;
    
    notifyListeners();
  }
  
  /// Skip spell counter and immediately resolve the spell
  void skipSpellCounter() {
    if (_spellCastTimer != null) {
      _spellCastTimer!.cancel();
      _spellCastTimer = null;
    }
    
    _addBattleLog('⏰ Time\'s up! Turn automatically ended.', 'System');
    _resolveSpell();
  }
  
  /// Get particle type for spell
  ParticleType _getSpellParticleType(ActionCard spell) {
    if (spell.name.toLowerCase().contains('fire') || 
        spell.name.toLowerCase().contains('burn')) {
      return ParticleType.fire;
    } else if (spell.name.toLowerCase().contains('lightning') || 
               spell.name.toLowerCase().contains('shock')) {
      return ParticleType.lightning;
    } else if (spell.name.toLowerCase().contains('ice') || 
               spell.name.toLowerCase().contains('frost')) {
      return ParticleType.ice;
    } else if (spell.name.toLowerCase().contains('heal')) {
                     return ParticleType.healing;
      }
      return ParticleType.magic;
  }
  
  /// Get element name for spell
  String _getElementName(ActionCard spell) {
    if (spell.name.toLowerCase().contains('fire')) return 'fire';
    if (spell.name.toLowerCase().contains('lightning')) return 'lightning';
    if (spell.name.toLowerCase().contains('ice')) return 'ice';
    if (spell.name.toLowerCase().contains('shadow')) return 'shadow';
    if (spell.name.toLowerCase().contains('arcane')) return 'arcane';
    return 'magical';
  }
  
  /// Apply burn effect over time
  void _applyBurnEffect(String playerId, int damage) {
    final player = getPlayerById(playerId);
    if (player == null) return;
    
    // Add burn status effect
    final statusEffects = Map<String, dynamic>.from(player.statusEffects);
    statusEffects['burn'] = {
      'damage': damage,
      'turns': 3, // Burns for 3 turns
    };
    
    final updatedPlayer = player.copyWith(statusEffects: statusEffects);
    _updatePlayer(updatedPlayer);
  }
  
  /// Apply status effect to player
  void _applyStatusEffect(String playerId, String effect, int duration) {
    final player = getPlayerById(playerId);
    if (player == null) return;
    
    final statusEffects = Map<String, dynamic>.from(player.statusEffects);
    statusEffects[effect] = {
      'turns': duration,
    };
    
    final updatedPlayer = player.copyWith(statusEffects: statusEffects);
    _updatePlayer(updatedPlayer);
  }
  
  /// Trigger spell resolution effects
  void _triggerSpellResolveEffects(ActionCard spell, String targetId) {
    // TODO: Implement spell resolution particle effects
    print('[EFFECTS] Spell resolved: ${spell.name} on $targetId');
  }
  

  
  /// Calculate whether a counter attempt succeeds
  bool _calculateCounterSuccess(ActionCard counterCard, ActionCard targetSpell) {
    double successChance = 0.7; // Base 70% success rate
    
    // Generic counters are always successful
    if (counterCard.name.toLowerCase().contains('dispel') ||
        counterCard.name.toLowerCase().contains('counterspell')) {
      successChance = 0.9;
    }
    
    // Element-specific counters have higher success rates
    if (_isElementalCounter(counterCard, targetSpell)) {
      successChance = 0.95;
    }
    
    // Higher cost counters are more reliable
    if (counterCard.cost >= targetSpell.cost) {
      successChance += 0.1;
    }
    
    return math.Random().nextDouble() < successChance;
  }
  
  /// Check if counter card is elementally effective against target spell
  bool _isElementalCounter(ActionCard counterCard, ActionCard targetSpell) {
    final counterName = counterCard.name.toLowerCase();
    final spellName = targetSpell.name.toLowerCase();
    
    // Water/Ice counters Fire
    if ((counterName.contains('water') || counterName.contains('ice')) &&
        (spellName.contains('fire') || spellName.contains('burn'))) {
      return true;
    }
    
    // Earth counters Lightning
    if (counterName.contains('earth') && 
        (spellName.contains('lightning') || spellName.contains('shock'))) {
      return true;
    }
    
    // Light counters Shadow
    if (counterName.contains('light') && 
        (spellName.contains('shadow') || spellName.contains('curse'))) {
      return true;
    }
    
    return false;
  }
  
  /// Play sound for successful spell counter
  void _playSpellCounterSound() {
    // TODO: Implement audio system
    print('[AUDIO] Spell counter success');
  }
  
  /// Play sound for failed counter attempt
  void _playCounterFailSound() {
    // TODO: Implement audio system
    print('[AUDIO] Counter attempt failed');
  }
  
  /// Start the turn timer countdown
  void _startTurnTimer() {
    _turnTimer?.cancel();
    _turnTimeRemaining = 60; // 60 seconds per turn
    
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _turnTimeRemaining--;
      
      if (_turnTimeRemaining <= 0) {
        // Time's up - auto end turn
        _addBattleLog('⏰ Time\'s up! Turn automatically ended.', 'System');
        timer.cancel();
        endTurn();
      } else if (_turnTimeRemaining <= 5) {
        // Play urgent sound effect
        _playUrgentTimerSound();
      } else if (_turnTimeRemaining <= 15) {
        // Play warning sound effect
        _playWarningTimerSound();
      }
      
      notifyListeners();
    });
    
    // Check if current player is AI
    final currentPlayer = getCurrentPlayer();
    if (currentPlayer != null && currentPlayer.id.startsWith('ai_')) {
      _handleAITurn();
    }
  }

  /// Handle AI turn
  void _handleAITurn() async {
    final currentPlayer = getCurrentPlayer();
    if (currentPlayer == null || !currentPlayer.id.startsWith('ai_')) return;
    
    // Add a small delay to make AI feel more natural
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Get AI decision
    final aiService = AIBattleService.instance;
    final decision = await aiService.makeDecision(
      aiPlayer: _convertToAIPlayer(currentPlayer),
      allPlayers: _battle.players,
      currentPhase: _currentPhase,
      turnTimeRemaining: _turnTimeRemaining,
    );
    
    // Execute AI decision
    _executeAIDecision(decision);
  }

  /// Convert BattlePlayer to AIPlayer for AI service
  AIPlayer _convertToAIPlayer(BattlePlayer player) {
    return AIPlayer(
      id: player.id,
      name: player.name,
      character: player.character,
      difficulty: AIDifficulty.medium, // Default difficulty
      strategy: AIStrategy.balanced, // Default strategy
      actionDeck: player.actionDeck,
      hand: player.hand,
      currentHealth: player.currentHealth,
      maxHealth: player.maxHealth,
      currentMana: player.currentMana,
      maxMana: player.maxMana,
      statusEffects: player.statusEffects.map((key, value) => MapEntry(key, value as int)),
    );
  }

  /// Execute AI decision
  void _executeAIDecision(AIDecision decision) {
    switch (decision.type) {
      case AIDecisionType.playCard:
        if (decision.card != null && decision.targetId != null) {
          _selectedCard = decision.card;
          _selectedTargetId = decision.targetId;
          playCardOnTarget(decision.card!, decision.targetId!);
        }
        break;
      case AIDecisionType.attack:
        if (decision.targetId != null) {
          _selectedTargetId = decision.targetId;
          performAttack();
        }
        break;
      case AIDecisionType.endTurn:
        endTurn();
        break;
    }
  }
  
  /// Play sound for urgent timer (last 5 seconds)
  void _playUrgentTimerSound() {
    // TODO: Implement audio system
    print('[AUDIO] Urgent timer tick - ${_turnTimeRemaining}s left!');
  }
  
  /// Play sound for warning timer (last 15 seconds)
  void _playWarningTimerSound() {
    // TODO: Implement audio system
    print('[AUDIO] Warning timer tick - ${_turnTimeRemaining}s left');
  }
  
  /// Play sound for elemental combo
  void _playComboSound(ElementalCombo combo) {
    // TODO: Implement audio system
    print('[AUDIO] 🌟 COMBO: ${combo.name}!');
  }
  
  /// Apply special combo effects
  void _applyComboEffect(String effect, String targetId, String casterName) {
    if (effect.startsWith('chain_damage:')) {
      final jumps = int.tryParse(effect.split(':')[1]) ?? 1;
      _applyChainDamage(targetId, jumps);
    } else if (effect.startsWith('stun:')) {
      final duration = int.tryParse(effect.split(':')[1]) ?? 1;
      _applyStatusEffect(targetId, 'stunned', duration);
      _addBattleLog('😵 ${getPlayerById(targetId)?.name} is stunned for $duration turns!', 'System');
    } else if (effect == 'damage_all_enemies') {
      _damageAllEnemies(casterName);
    } else if (effect.startsWith('heal_all_allies:')) {
      final healing = int.tryParse(effect.split(':')[1]) ?? 20;
      _healAllAllies(casterName, healing);
    } else if (effect.startsWith('freeze_all:')) {
      final duration = int.tryParse(effect.split(':')[1]) ?? 1;
      _freezeAllEnemies(casterName, duration);
    }
    // Add more combo effects as needed
  }
  
  /// Apply chain lightning damage
  void _applyChainDamage(String initialTargetId, int jumps) {
    final visited = <String>{initialTargetId};
    String currentTarget = initialTargetId;
    
    for (int i = 0; i < jumps; i++) {
      // Find nearest unvisited enemy
      final nextTarget = _findNearestEnemy(currentTarget, visited);
      if (nextTarget == null) break;
      
      visited.add(nextTarget);
      final damage = (30 * (0.7 * i)).round(); // Decreasing damage
      _applyDamageWithEffects(nextTarget, damage, effectType: ParticleType.lightning);
      
      final targetName = getPlayerById(nextTarget)?.name ?? 'Unknown';
      _addBattleLog('⚡ Lightning chains to ${targetName} for $damage damage!', 'System');
      
      currentTarget = nextTarget;
    }
  }
  
  /// Find nearest enemy for chain effects
  String? _findNearestEnemy(String fromPlayerId, Set<String> visited) {
    // Simple implementation - find first enemy not in visited set
    final currentPlayer = getPlayerById(fromPlayerId);
    if (currentPlayer == null) return null;
    
    for (final player in _battle.players) {
      if (!visited.contains(player.id) && 
          !isFriendly(player.id) && 
          player.currentHealth > 0) {
        return player.id;
      }
    }
    return null;
  }
  
  /// Damage all enemies
  void _damageAllEnemies(String casterName) {
    final caster = _battle.players.firstWhere((p) => p.name == casterName);
    for (final player in _battle.players) {
      if (!isFriendly(player.id) && player.currentHealth > 0) {
        _applyDamageWithEffects(player.id, 25, effectType: ParticleType.explosion);
        _addBattleLog('💥 ${player.name} takes 25 area damage!', 'System');
      }
    }
  }
  
  /// Heal all allies
  void _healAllAllies(String casterName, int healing) {
    final caster = _battle.players.firstWhere((p) => p.name == casterName);
    for (final player in _battle.players) {
      if (isFriendly(player.id)) {
        _applyHealingWithEffects(player.id, healing);
        _addBattleLog('✨ ${player.name} heals for $healing HP!', 'System');
      }
    }
  }
  
  /// Freeze all enemies
  void _freezeAllEnemies(String casterName, int duration) {
    final caster = _battle.players.firstWhere((p) => p.name == casterName);
    for (final player in _battle.players) {
      if (!isFriendly(player.id) && player.currentHealth > 0) {
        _applyStatusEffect(player.id, 'frozen', duration);
        _addBattleLog('❄️ ${player.name} is frozen for $duration turns!', 'System');
      }
    }
  }
  
  /// Play critical hit sound based on critical type
  void _playCriticalHitSound(CriticalType critType) {
    switch (critType) {
      case CriticalType.critical:
        AudioService.instance.playCriticalHit();
        break;
      case CriticalType.superCritical:
        AudioService.instance.playSuperCritical();
        break;
      case CriticalType.devastatingCritical:
        AudioService.instance.playDevastatingCritical();
        break;
      default:
        break;
    }
    
    // Add screen shake based on critical type
    final screenShakeService = ScreenShakeService.instance;
    switch (critType) {
      case CriticalType.critical:
        screenShakeService.mediumShake();
        break;
      case CriticalType.superCritical:
        screenShakeService.heavyShake();
        break;
      case CriticalType.devastatingCritical:
        screenShakeService.explosionShake();
        break;
      default:
        break;
    }
  }
  
  /// Trigger screen shake effect
  void _triggerScreenShake() {
    final screenShakeService = ScreenShakeService.instance;
    screenShakeService.lightShake();
    print('[EFFECT] 📳 Screen shake triggered!');
  }
  
  /// Start enhanced damage particles with critical hit effects
  void _startDamageParticles(String playerId, ParticleType? effectType, int damage, CriticalHitResult? critResult) {
    final particleSystemService = ParticleSystemService.instance;
    
    if (critResult?.isCritical ?? false) {
      final critType = critResult!.criticalType;
      print('[PARTICLES] Enhanced ${critType.name} damage particles for $damage damage on $playerId');
      
      // Trigger special particle effects based on critical type
      switch (critType) {
        case CriticalType.critical:
          particleSystemService.createSparkleEffect(Offset.zero);
          print('[PARTICLES] ⚡ Sparkling critical particles');
          break;
        case CriticalType.superCritical:
          particleSystemService.createExplosionEffect(Offset.zero);
          print('[PARTICLES] 🔥 Explosive critical particles');
          break;
        case CriticalType.devastatingCritical:
          particleSystemService.createExplosionEffect(Offset.zero);
          particleSystemService.createLightningEffect(Offset.zero, Offset(100, 100));
          print('[PARTICLES] 💥 Reality-breaking critical particles');
          break;
        default:
          break;
      }
    } else {
      // Standard damage particles
      if (effectType != null) {
        switch (effectType) {
          case ParticleType.fire:
            particleSystemService.createFireEffect(Offset.zero);
            break;
          case ParticleType.ice:
            particleSystemService.createIceEffect(Offset.zero);
            break;
          case ParticleType.lightning:
            particleSystemService.createLightningEffect(Offset.zero, Offset(50, 50));
            break;
          case ParticleType.healing:
            particleSystemService.createHealingEffect(Offset.zero);
            break;
          case ParticleType.damage:
            particleSystemService.createDamageEffect(Offset.zero);
            break;
          default:
            particleSystemService.createDamageEffect(Offset.zero);
            break;
        }
        print('[PARTICLES] Standard $effectType damage particles for $damage damage on $playerId');
      } else {
        // Default damage particles when no effect type specified
        particleSystemService.createDamageEffect(Offset.zero);
        print('[PARTICLES] Default damage particles for $damage damage on $playerId');
      }
    }
  }
  
  /// Execute chain reaction effects
  void _executeChainReaction(ChainReactionResult chainResult) {
    final reaction = chainResult.reaction;
    
    _addBattleLog('⚡ CHAIN REACTION: ${reaction.name}! (${chainResult.totalJumps} jumps)', 'System');
    _playChainReactionSound(reaction.type);
    
    // Apply damage/effects to each target in the chain
    for (final target in chainResult.affectedTargets) {
      final player = getPlayerById(target.playerId);
      if (player == null) continue;
      
      // Apply damage with chain reaction effects
      _applyDamageWithEffects(
        target.playerId,
        target.damage,
        effectType: _convertParticleType(target.effectType),
        sourceCard: chainResult.sourceSpell,
        attackerId: chainResult.casterId,
      );
      
      // Add specific chain reaction log
      _addBattleLog('⚡ ${reaction.name} jumps to ${player.name} for ${target.damage} damage! (Jump #${target.jumpNumber})', 'System');
      
      // Trigger chain-specific effects
      _triggerChainEffects(reaction.type, target.playerId);
    }
  }
  
  /// Play sound for chain reactions
  void _playChainReactionSound(ChainReactionType type) {
    // TODO: Implement audio system
    switch (type) {
      case ChainReactionType.lightningJump:
        print('[AUDIO] ⚡ Crackling lightning chain!');
        break;
      case ChainReactionType.fireSpread:
        print('[AUDIO] 🔥 Spreading flames!');
        break;
      case ChainReactionType.iceShatter:
        print('[AUDIO] ❄️ Ice shattering cascade!');
        break;
      case ChainReactionType.healingWave:
        print('[AUDIO] ✨ Healing energy flowing!');
        break;
      default:
        print('[AUDIO] 🌊 Chain reaction sound');
        break;
    }
  }
  
  /// Trigger additional effects for specific chain types
  void _triggerChainEffects(ChainReactionType type, String playerId) {
    switch (type) {
      case ChainReactionType.lightningJump:
        // Lightning chains can stun
        _applyStatusEffect(playerId, 'paralyzed', 1);
        break;
      case ChainReactionType.fireSpread:
        // Fire spreads can cause burning
        _applyBurnEffect(playerId, 5);
        break;
      case ChainReactionType.iceShatter:
        // Ice can slow movement
        _applyStatusEffect(playerId, 'slowed', 2);
        break;
      case ChainReactionType.healingWave:
        // Healing can remove debuffs
        _removeDebuffs(playerId);
        break;
      default:
        break;
    }
  }
  
  /// Remove debuffs from a player
  void _removeDebuffs(String playerId) {
    // TODO: Implement debuff removal
    print('[EFFECT] Removing debuffs from $playerId');
  }


  /// Start dragging a card with Hearthstone-style lifting
  void startCardDrag(ActionCard card, Offset startPosition) {
    // Check if player can afford the card
    final currentPlayer = getCurrentPlayer();
    if (currentPlayer == null || currentPlayer.currentMana < card.cost) {
      _playErrorSound();
      return;
    }
    
    _draggedCard = card;
    _hoveredTargetId = null;
    _isDragging = true;
    
    print('[DRAG] Started dragging card: ${card.name}');
    _playCardLiftSound(card);
    notifyListeners();
  }
  
  /// Start dragging an attack action
  void startAttackDrag(Offset startPosition) {
    final currentPlayer = getCurrentPlayer();
    if (currentPlayer == null || !canAttack()) {
      _playErrorSound();
      return;
    }
    
    // Use the attack card instead of just an action
    if (_attackCards.isNotEmpty) {
      _draggedCard = _attackCards.first;
      print('[DRAG] Started dragging attack card: ${_draggedCard!.name}');
    } else {
      _draggedCard = null;
      print('[DRAG] No attack card available');
    }
    _hoveredTargetId = null;
    _isDragging = true;
    
    _playAttackLiftSound();
    notifyListeners();
  }

  /// Start dragging a skill card
  void startSkillDrag(ActionCard skillCard, Offset startPosition) {
    final currentPlayer = getCurrentPlayer();
    if (currentPlayer == null || currentPlayer.currentMana < skillCard.cost) {
      _playErrorSound();
      return;
    }
    
    _draggedCard = skillCard;
    _hoveredTargetId = null;
    _isDragging = true;
    
    print('[DRAG] Started dragging skill card: ${skillCard.name}');
    _playCardLiftSound(skillCard);
    notifyListeners();
  }

  /// Select an attack card
  void selectAttackCard(ActionCard card) {
    _selectedCard = card;
    notifyListeners();
  }

  /// Select a skill card
  void selectSkillCard(ActionCard card) {
    _selectedCard = card;
    notifyListeners();
  }

  /// Select an inventory card
  void selectInventoryCard(ActionCard card) {
    _selectedCard = card;
    notifyListeners();
  }

  /// Check if target is valid for card
  bool isValidTarget(ActionCard card, String targetId) {
    final target = getPlayerById(targetId);
    if (target == null || target.currentHealth <= 0) return false;
    
    final currentPlayer = getCurrentPlayer();
    if (currentPlayer == null) return false;
    
    // Attack cards can only target enemies
    if (card.name == 'Attack') {
      return !isFriendly(targetId);
    }
    
    // Skill cards have different targeting rules
    switch (card.type) {
      case ActionCardType.heal:
      case ActionCardType.buff:
        return true; // Can target anyone
      case ActionCardType.damage:
      case ActionCardType.debuff:
      case ActionCardType.spell:
        return !isFriendly(targetId);
      case ActionCardType.special:
        return true;
      default:
        return true;
    }
  }

  /// Add visual effect
  void addVisualEffect(VisualEffect effect) {
    _visualEffects.add(effect);
    notifyListeners();
    
    // Remove effect after animation duration
    Timer(Duration(milliseconds: effect.type == VisualEffectType.damageNumber ? 1000 : 800), () {
      _visualEffects.remove(effect);
      notifyListeners();
    });
  }

  /// Create damage number effect
  void showDamageNumber(int damage, Offset position, {bool isCritical = false}) {
    addVisualEffect(VisualEffect(
      type: VisualEffectType.damageNumber,
      position: position,
      data: {
        'damage': damage,
        'isCritical': isCritical,
      },
    ));
  }

  /// Create elemental effect
  void showElementalEffect(String element, Offset position) {
    addVisualEffect(VisualEffect(
      type: VisualEffectType.elementalEffect,
      position: position,
      data: {
        'element': element,
      },
    ));
  }

  /// Create screen shake effect
  void showScreenShake() {
    addVisualEffect(VisualEffect(
      type: VisualEffectType.screenShake,
      position: const Offset(0, 0),
      data: {},
    ));
  }

  /// Create critical hit effect
  void showCriticalHit(Offset position) {
    addVisualEffect(VisualEffect(
      type: VisualEffectType.criticalHit,
      position: position,
      data: {},
    ));
  }

  /// Track damage dealt
  void trackDamageDealt(int damage) {
    _damageDealt += damage;
  }

  /// Track damage taken
  void trackDamageTaken(int damage) {
    _damageTaken += damage;
    if (damage > 0) {
      _perfectVictory = false;
    }
  }

  /// Track card played
  void trackCardPlayed() {
    _cardsPlayed++;
  }

  /// Track skill used
  void trackSkillUsed() {
    _skillsUsed++;
  }

  /// Track turn taken
  void trackTurn() {
    _turnsTaken++;
  }

  /// Award battle rewards to winner
  // Future<void> applyBattleRewards(CharacterProvider characterProvider) async {
  //   if (_battleRewards != null) {
  //     await BattleRewardsService.instance.applyRewards(
  //       rewards: _battleRewards!,
  //       characterProvider: characterProvider,
  //     );
  //     
  //     // Clear rewards after applying
  //     _battleRewards = null;
  //     _battlePerformance = null;
  //     notifyListeners();
  //   }
  // }
  
  /// Update drag position and check target validity
  void updateDragPosition(Offset currentPosition) {
    if (!_isDragging) return;
    
    _hoveredTargetId = _getTargetAtPosition(currentPosition);
    
    // Check what target we're hovering over
    final newHoveredTarget = _hoveredTargetId;
    
    if (newHoveredTarget != _hoveredTargetId) {
      _hoveredTargetId = newHoveredTarget;
      notifyListeners();
    }
    
    notifyListeners();
  }
  
  /// End drag operation - either cast spell/attack or snap back
  void endDrag() {
    if (!_isDragging) return;
    
    print('[DRAG] Ending drag operation');
    
    if (_hoveredTargetId != null && _draggedCard != null) {
      // Valid drop - execute action
      print('[DRAG] Executing action on target: $_hoveredTargetId');
      if (_draggedCard!.effect.contains('physical_attack')) {
        _executeAttack(_hoveredTargetId!);
      } else {
        _executeSpellCast(_draggedCard!, _hoveredTargetId!);
      }
    } else {
      // Invalid drop - snap back with animation
      print('[DRAG] Invalid drop, snapping back');
      _snapBackToHand();
    }
    
    _clearDragState();
  }
  
  /// Execute spell casting with 8-second counter window
  void _executeSpellCast(ActionCard spell, String targetId) {
    final currentPlayer = getCurrentPlayer();
    if (currentPlayer == null) return;
    
    // Consume mana immediately
    final updatedPlayer = currentPlayer.copyWith(
      currentMana: currentPlayer.currentMana - spell.cost,
    );
    _updatePlayer(updatedPlayer);
    
    // Add card to ghost hand (visible but grayed out)
    _ghostCardsInHand.add(spell.id);
    
    // Track card play for rewards
    _trackCardPlayed(spell);
    
    // Start spell casting process
    _pendingSpell = spell;
    _pendingSpellCaster = currentPlayer.id;
    _pendingSpellTarget = targetId;
    _spellCounterTimeRemaining = 8; // 8 seconds to counter
    
    _addBattleLog('${currentPlayer.name} casts ${spell.name}! (${_spellCounterTimeRemaining}s to counter)', currentPlayer.name);
    _playSpellCastSound(spell);
    _startSpellCastParticles(spell, targetId);
    
    // Start countdown timer
    _spellCastTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _spellCounterTimeRemaining--;
      
      if (_spellCounterTimeRemaining <= 0) {
        _resolveSpell();
        timer.cancel();
      } else {
        _addBattleLog('⏰ ${_spellCounterTimeRemaining}s remaining to counter!', 'System');
        notifyListeners();
      }
    });
    
    notifyListeners();
  }
  
  /// Execute basic attack with critical hit calculation
  void _executeAttack(String targetId) {
    final currentPlayer = getCurrentPlayer();
    final target = getPlayerById(targetId);
    
    if (currentPlayer == null || target == null) return;
    
    _playAttackSound();
    _startAttackAnimation(targetId);
    
    // Create a basic attack card for critical calculation
    final attackCard = ActionCard(
      id: 'basic_attack',
      name: 'Attack',
      description: 'Basic attack',
      cost: 0,
      type: ActionCardType.physical,
      effect: 'damage:${currentPlayer.character.attackRating}',
      rarity: CardRarity.common,
    );
    
    // Apply damage with critical hit support
    final damage = currentPlayer.character.attackRating;
    _applyDamageWithEffects(
      targetId, 
      damage, 
      effectType: ParticleType.explosion,
      sourceCard: attackCard,
      attackerId: currentPlayer.id,
    );
    
    _addBattleLog('${currentPlayer.name} attacks ${target.name}!', currentPlayer.name);
  }
  
  /// Resolve spell after counter window expires
  void _resolveSpell() {
    if (_pendingSpell == null || _pendingSpellTarget == null) return;
    
    final spell = _pendingSpell!;
    final targetId = _pendingSpellTarget!;
    final target = getPlayerById(targetId);
    
    if (target == null) {
      _cancelSpell();
      return;
    }
    
    // Apply spell effects based on type
    _applySpellEffects(spell, targetId);
    
    // Handle card discard/return logic
    _handleCardAfterUse(spell);
    
    // Clear pending spell
    _pendingSpell = null;
    _pendingSpellCaster = null;
    _pendingSpellTarget = null;
    _spellCounterTimeRemaining = 0;
    
    notifyListeners();
  }
  
  /// Apply spell effects with enhanced visuals and combo system
  void _applySpellEffects(ActionCard spell, String targetId) {
    final target = getPlayerById(targetId);
    if (target == null) return;
    
    final caster = getPlayerById(_pendingSpellCaster ?? '');
    final casterName = caster?.name ?? 'Unknown';
    
    // Record spell cast for combo system
    if (caster != null) {
      _comboSystem.recordSpellCast(caster.id, spell, targetId);
    }
    
    // Parse base spell effects
    final effects = spell.effect.split(',');
    int baseDamage = 0;
    
    // Extract base damage
    for (final effect in effects) {
      if (effect.startsWith('damage:')) {
        baseDamage = int.tryParse(effect.split(':')[1]) ?? 0;
        break;
      }
    }
    
    // Apply combo effects if any
    final spellResult = _comboSystem.applyComboEffects(
      caster?.id ?? '', 
      spell, 
      targetId, 
      baseDamage
    );
    
    // Show combo notification
    if (spellResult.comboTriggered != null) {
      final combo = spellResult.comboTriggered!;
      _addBattleLog('🌟 ELEMENTAL COMBO: ${combo.name}! ${combo.description}', casterName);
      _playComboSound(combo);
    }
    
    // Apply enhanced effects
    for (final effect in effects) {
             if (effect.startsWith('damage:')) {
        // Use combo-enhanced damage
        final finalDamage = spellResult.comboTriggered != null ? spellResult.damage : baseDamage;
        _applyDamageWithEffects(
          targetId, 
          finalDamage, 
          effectType: _convertParticleType(spellResult.particleEffect),
          sourceCard: spell,
          attackerId: caster?.id,
        );
        
        final damageType = spellResult.comboTriggered?.name ?? _getElementName(spell);
        _addBattleLog('💥 ${target.name} takes $finalDamage $damageType damage!', 'System');
        
      } else if (effect.startsWith('heal:')) {
        final healing = int.tryParse(effect.split(':')[1]) ?? 0;
        _applyHealingWithEffects(targetId, healing);
        _addBattleLog('✨ ${target.name} heals for $healing HP!', 'System');
        
      } else if (effect.startsWith('burn:')) {
        final burnDamage = int.tryParse(effect.split(':')[1]) ?? 0;
        _applyBurnEffect(targetId, burnDamage);
        _addBattleLog('🔥 ${target.name} is burning for $burnDamage damage per turn!', 'System');
        
      } else if (effect == 'double_damage') {
        _applyStatusEffect(targetId, 'double_damage', 2);
        _addBattleLog('⚡ ${target.name} will deal double damage next turn!', 'System');
      }
    }
    
    // Apply additional combo effects
    for (final comboEffect in spellResult.effects) {
      _applyComboEffect(comboEffect, targetId, casterName);
    }
    
    // Check for chain reactions
    final chainReactions = _teamSystem.checkChainReactions(
      caster?.id ?? '',
      spell,
      targetId,
      _battle.players,
    );
    
    // Execute chain reactions
    for (final chainResult in chainReactions) {
      _executeChainReaction(chainResult);
    }
    
    // Play spell resolution sound and effects
    _playSpellResolveSound(spell);
    _triggerSpellResolveEffects(spell, targetId);
  }
  
  /// Handle card logic after use (discard vs return to hand)
  void _handleCardAfterUse(ActionCard card) {
    _ghostCardsInHand.removeWhere((id) => id == card.id);
    
    // Check card properties for discard logic
    final shouldDiscard = card.properties['discard_after_use'] == true || 
                         card.type == ActionCardType.spell; // Most spells are discarded
    
    if (!shouldDiscard) {
      // Card returns to hand (like basic attacks)
      final currentPlayer = getCurrentPlayer();
      if (currentPlayer != null) {
        final updatedHand = List<ActionCard>.from(currentPlayer.hand);
        if (!updatedHand.any((c) => c.id == card.id)) {
          updatedHand.add(card);
          final updatedPlayer = currentPlayer.copyWith(hand: updatedHand);
          _updatePlayer(updatedPlayer);
        }
      }
    }
    
    notifyListeners();
  }

  /// Apply healing with visual effects
  void _applyHealingWithEffects(String playerId, int amount) {
    _healPlayer(playerId, amount);
    
    final player = getPlayerById(playerId);
    if (player != null) {
      _addBattleLog('✨ ${player.name} heals for $amount HP!', 'System');
    }
  }

  /// Apply damage with critical hit calculation and visual effects
  void _applyDamageWithEffects(String playerId, int amount, {ParticleType? effectType, ActionCard? sourceCard, String? attackerId}) {
    final player = getPlayerById(playerId);
    if (player == null) return;
    
    int finalDamage = amount;
    CriticalHitResult? critResult;
    
    // Calculate critical hit if we have source information
    if (sourceCard != null && attackerId != null) {
      critResult = _criticalSystem.calculateCritical(attackerId, sourceCard, amount);
      finalDamage = critResult.finalDamage;
      
      // Update attacker's total attacks
      final attackerStats = _criticalSystem.getPlayerStats(attackerId);
      attackerStats.totalAttacks++;
      
      // Show critical hit message
      if (critResult.isCritical) {
        _addBattleLog('⚡ CRITICAL HIT! ${critResult.criticalMessage}', 'System');
        _playCriticalHitSound(critResult.criticalType);
        
        // Trigger screen shake for higher tier crits
        if (critResult.criticalData?.screenShake ?? false) {
          _triggerScreenShake();
        }
      }
    }
    
    // Apply difficulty scaling to damage
    finalDamage = _applyDifficultyScaling(finalDamage);
    
    // Track damage dealt for rewards
    _trackDamageDealt(finalDamage);
    
    final newHealth = math.max(0, player.currentHealth - finalDamage);
    final updatedPlayer = player.copyWith(currentHealth: newHealth);
    _updatePlayer(updatedPlayer);
    
    // Show enhanced damage effect for criticals
    if (effectType != null) {
      _startDamageParticles(playerId, effectType, finalDamage, critResult);
    }
    
    // Enhanced damage log message
    final damageMessage = critResult?.isCritical ?? false 
        ? '💥 ${player.name} takes $finalDamage CRITICAL damage!'
        : '💥 ${player.name} takes $finalDamage damage!';
    _addBattleLog(damageMessage, 'System');
    
    if (newHealth <= 0) {
      _addBattleLog('💀 ${player.name} has been defeated!', 'System');
      _checkBattleEnd();
    }
  }

  /// Convert legacy ParticleType to unified ParticleType
  ParticleType? _convertParticleType(ParticleType? effectType) {
    if (effectType == null) return null;
    
    // Since we're now using the unified system, just return the same type
    return effectType;
  }

  @override
  void dispose() {
    // Safely dispose of resources
    try {
      // Note: SpellCounterSystem doesn't extend ChangeNotifier anymore, so no dispose needed
    } catch (e) {
      if (kDebugMode) {
        print('Error disposing battle controller: $e');
      }
    }
    super.dispose();
  }

  /// Calculate battle rewards based on performance
  Map<String, dynamic> _calculateBattleRewards() {
    final baseXP = 100;
    final baseSkillPoints = 1;
    final baseStatPoints = 2;
    
    // Performance multipliers
    double damageMultiplier = math.min(_damageDealt / 100.0, 3.0); // Max 3x for damage
    double efficiencyMultiplier = math.min(_cardsPlayed / 5.0, 2.0); // Max 2x for efficiency
    double skillMultiplier = math.min(_skillsUsed / 3.0, 1.5); // Max 1.5x for skills
    
    // Calculate rewards
    final totalXP = (baseXP * (1 + damageMultiplier + efficiencyMultiplier)).round();
    final totalSkillPoints = (baseSkillPoints * (1 + skillMultiplier)).round();
    final totalStatPoints = baseStatPoints;
    
    // Battle-specific rewards
    final List<String> rewardCards = [];
    final List<String> rewardTitles = [];
    
    // Award cards based on performance
    if (_damageDealt > 200) rewardCards.add('damage_master_card');
    if (_cardsPlayed > 8) rewardCards.add('efficiency_card');
    if (_skillsUsed > 5) rewardCards.add('skill_master_card');
    if (_turnsTaken < 5) rewardCards.add('speed_demon_card');
    
    // Award titles based on performance
    if (_damageDealt > 300) rewardTitles.add('Damage Dealer');
    if (_cardsPlayed > 10) rewardTitles.add('Card Master');
    if (_skillsUsed > 7) rewardTitles.add('Skill User');
    if (_turnsTaken < 3) rewardTitles.add('Speed Demon');
    
    return {
      'xp': totalXP,
      'skillPoints': totalSkillPoints,
      'statPoints': totalStatPoints,
      'cards': rewardCards,
      'titles': rewardTitles,
      'performance': {
        'damageDealt': _damageDealt,
        'cardsPlayed': _cardsPlayed,
        'skillsUsed': _skillsUsed,
        'turnsTaken': _turnsTaken,
        'efficiency': _cardsPlayed > 0 ? _damageDealt / _cardsPlayed : 0,
      }
    };
  }

  /// Award battle rewards to character
  Future<void> _awardBattleRewards() async {
    if (_battleCompleted) return; // Prevent double awarding
    
    // Calculate battle performance
    final performance = BattleRewardsService.instance.calculatePerformance(
      damageDealt: _damageDealt,
      damageTaken: _damageTaken,
      cardsPlayed: _cardsPlayed,
      turnsTaken: _turnsTaken,
      isVictory: _getWinner() != null,
      playerLevel: getCurrentPlayer()?.character.level ?? 1,
      battleStreak: _battleStreak,
    );
    
    // Generate rewards
    _battleRewards = BattleRewardsService.instance.generateRewards(
      performance: performance,
      playerLevel: getCurrentPlayer()?.character.level ?? 1,
      battleStreak: _battleStreak,
      isVictory: _getWinner() != null,
    );
    
    _battlePerformance = performance;
    _battleCompleted = true;
    
    // Log battle completion
    _addBattleLog('🏆 Battle completed! Rewards calculated.', 'System');
    
    // Store battle result for UI display
    _lastBattleResult = BattleResult(
      battleId: _battle.id,
      outcome: _getWinner() != null ? BattleOutcome.victory : BattleOutcome.defeat,
      winner: _getWinner() != null ? getCurrentPlayer()?.character : null,
      loser: _getWinner() == null ? getCurrentPlayer()?.character : null,
      experienceGained: _damageDealt * 10, // Simple calculation
      goldGained: _damageDealt * 2, // Simple calculation
      itemsGained: [], // Will be populated by rewards system
    );
    
    notifyListeners();
  }

  /// Get the winner of the battle
  String? _getWinner() {
    final alivePlayers = _battle.players.where((p) => p.currentHealth > 0).toList();
    if (alivePlayers.length == 1) {
      return alivePlayers.first.id;
    }
    return null; // Draw or battle still ongoing
  }

  /// Reset battle tracking for new battle
  void _resetBattleTracking() {
    _damageDealt = 0;
    _damageTaken = 0;
    _cardsPlayed = 0;
    _skillsUsed = 0;
    _turnsTaken = 0;
    _battleRewards = null;
    _battlePerformance = null;
    _battleCompleted = false;
    _lastBattleResult = null;
  }

  /// Track card play for rewards
  void _trackCardPlayed(ActionCard card) {
    _cardsPlayed++;
    _addBattleLog('📊 Card played: ${card.name}', 'System');
  }

  /// Track skill use for rewards
  void _trackSkillUsed(String skillName) {
    _skillsUsed++;
    _addBattleLog('📊 Skill used: $skillName', 'System');
  }

  /// Track damage dealt for rewards
  void _trackDamageDealt(int damage) {
    _damageDealt += damage;
  }

  /// Track turn completion for rewards
  void _trackTurnCompleted() {
    _turnsTaken++;
  }

  /// Calculate dynamic difficulty based on player level and power
  void _calculateDifficultyScaling() {
    final currentPlayer = getCurrentPlayer();
    if (currentPlayer == null) return;
    
    // Calculate player power rating
    _playerPowerRating = _calculatePlayerPowerRating(currentPlayer);
    _playerLevel = currentPlayer.character.level;
    
    // Base difficulty multiplier on level
    _difficultyMultiplier = 1.0 + (_playerLevel - 1) * 0.1; // 10% increase per level
    
    // Adjust for power rating
    if (_playerPowerRating > 1000) {
      _difficultyMultiplier += 0.2; // 20% bonus for high power players
    } else if (_playerPowerRating > 500) {
      _difficultyMultiplier += 0.1; // 10% bonus for medium power players
    }
    
    // Cap difficulty at 3x
    _difficultyMultiplier = _difficultyMultiplier.clamp(0.5, 3.0);
    
    _addBattleLog('⚖️ Difficulty adjusted: ${_difficultyMultiplier.toStringAsFixed(1)}x', 'System');
  }

  /// Calculate player power rating
  int _calculatePlayerPowerRating(BattlePlayer player) {
    int powerRating = 0;
    
    // Base stats contribution
    powerRating += (player.character.baseStrength + player.character.allocatedStrength) * 2;
    powerRating += (player.character.baseDexterity + player.character.allocatedDexterity) * 2;
    powerRating += (player.character.baseVitality + player.character.allocatedVitality) * 3;
    powerRating += (player.character.baseEnergy + player.character.allocatedEnergy) * 2;
    
    // Level contribution
    powerRating += player.character.level * 50;
    
    // Equipment contribution
    final equippedItems = player.character.equipment.getAllEquippedItems();
    for (final item in equippedItems) {
      powerRating += item.card.attack * 3;
      powerRating += item.card.defense * 2;
      powerRating += item.card.health * 1;
      powerRating += item.card.mana * 1;
    }
    
    return powerRating;
  }

  /// Apply difficulty scaling to damage calculations
  int _applyDifficultyScaling(int baseDamage) {
    return (baseDamage * _difficultyMultiplier).round();
  }

  /// Apply difficulty scaling to enemy health
  int _applyDifficultyScalingToHealth(int baseHealth) {
    return (baseHealth * _difficultyMultiplier).round();
  }

  /// Initialize battle with difficulty scaling
  void initializeBattleWithDifficulty() {
    _calculateDifficultyScaling();
    
    // Scale enemy health based on difficulty (enemies are typically players 2+ in PvE)
    for (int i = 1; i < _battle.players.length; i++) {
      final player = _battle.players[i];
      final scaledHealth = _applyDifficultyScalingToHealth(player.maxHealth);
      final updatedPlayer = player.copyWith(
        currentHealth: scaledHealth,
        maxHealth: scaledHealth,
      );
      _updatePlayer(updatedPlayer);
    }
    
    _addBattleLog('🎯 Battle difficulty set to ${_difficultyMultiplier.toStringAsFixed(1)}x', 'System');
  }
}