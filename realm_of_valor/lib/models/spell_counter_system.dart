import 'package:flutter/foundation.dart';
import 'package:realm_of_valor/models/battle_model.dart';
import 'package:realm_of_valor/models/card_model.dart';
import 'dart:async';

enum SpellElement {
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

enum CounterType {
  elemental,      // Fire counters Ice, Water counters Fire, etc.
  dispel,         // Generic counter that cancels any spell
  absorb,         // Absorb the spell and gain its power
  reflect,        // Bounce spell back to caster
  amplify,        // Make the spell stronger but also affect caster
}

class SpellCounterRule {
  final SpellElement sourceElement;
  final SpellElement counterElement;
  final CounterType counterType;
  final double effectiveness; // 0.0 = no effect, 1.0 = full counter, 2.0 = amplified
  final String description;

  SpellCounterRule({
    required this.sourceElement,
    required this.counterElement,
    required this.counterType,
    required this.effectiveness,
    required this.description,
  });
}

class PendingSpell {
  final ActionCard spell;
  final String casterId;
  final String targetId;
  final DateTime castTime;
  final int interruptWindowMs;
  
  PendingSpell({
    required this.spell,
    required this.casterId,
    required this.targetId,
    required this.castTime,
    this.interruptWindowMs = 8000, // 8 second window
  });
  
  bool get isExpired => DateTime.now().difference(castTime).inMilliseconds >= interruptWindowMs;
  int get remainingMs => interruptWindowMs - DateTime.now().difference(castTime).inMilliseconds;
}

class CounterSpellAttempt {
  final ActionCard counterSpell;
  final String counterId;
  final String targetSpellId;
  final DateTime attemptTime;
  final CounterType counterType;
  
  CounterSpellAttempt({
    required this.counterSpell,
    required this.counterId,
    required this.targetSpellId,
    required this.attemptTime,
    required this.counterType,
  });
}

class SpellCounterSystem {
  final Map<String, List<CounterStack>> _counterStacks = {};
  final Map<String, PendingSpell> _pendingSpells = {};
  final List<CounterSpellAttempt> _counterAttempts = [];
  
  // Callback for when a spell is resolved
  Function(PendingSpell, List<CounterSpellAttempt>, double, List<String>)? onSpellResolved;
  
  /// Add a counter spell to the stack for a specific player
  void addCounterSpell(String playerId, ActionCard counterCard, String targetSpellId) {
    _counterStacks.putIfAbsent(playerId, () => []);
    _counterStacks[playerId]!.add(CounterStack(
      counterCard: counterCard,
      targetSpellId: targetSpellId,
      timestamp: DateTime.now(),
    ));
  }
  
  /// Get the current pending spell
  PendingSpell? get currentPendingSpell {
    if (_pendingSpells.isEmpty) return null;
    return _pendingSpells.values.first;
  }
  
  /// Check if there's an active interrupt window
  bool get hasActiveInterrupt {
    return _pendingSpells.isNotEmpty;
  }
  
  /// Force resolve the current spell
  void forceResolve() {
    if (_pendingSpells.isNotEmpty) {
      final spell = _pendingSpells.values.first;
      _pendingSpells.clear();
      onSpellResolved?.call(spell, _counterAttempts, 1.0, ['Force resolved']);
    }
  }
  
  /// Check if a spell can be countered and return the counter card if available
  ActionCard? checkForCounter(String targetPlayerId, String spellId) {
    final counters = _counterStacks[targetPlayerId];
    if (counters == null || counters.isEmpty) return null;
    
    // Find the most recent counter that matches this spell
    final matchingCounter = counters.lastWhere(
      (counter) => counter.targetSpellId == spellId,
      orElse: () => CounterStack(
        counterCard: ActionCard(
          name: 'Skip',
          description: 'Skip action',
          type: ActionCardType.skip,
          effect: 'skip',
        ), 
        targetSpellId: '', 
        timestamp: DateTime.now()
      ),
    );
    
    if (matchingCounter.targetSpellId.isEmpty) return null;
    
    // Remove the used counter
    counters.removeWhere((counter) => counter.targetSpellId == spellId);
    
    return matchingCounter.counterCard;
  }
  
  /// Get all active counter stacks for a player
  List<CounterStack> getCounterStacks(String playerId) {
    return _counterStacks[playerId] ?? [];
  }
  
  /// Clear all counter stacks for a player
  void clearCounterStacks(String playerId) {
    _counterStacks[playerId]?.clear();
  }
  
  /// Clear all counter stacks
  void clearAllStacks() {
    _counterStacks.clear();
  }
  
  /// Check if a player has any active counters
  bool hasActiveCounters(String playerId) {
    final counters = _counterStacks[playerId];
    return counters != null && counters.isNotEmpty;
  }
  
  /// Get the total number of counter spells a player has ready
  int getCounterCount(String playerId) {
    return _counterStacks[playerId]?.length ?? 0;
  }
  
  /// Start an interrupt window for a spell
  void startInterruptWindow(ActionCard spell, String casterId, String targetId) {
    final pendingSpell = PendingSpell(
      spell: spell,
      casterId: casterId,
      targetId: targetId,
      castTime: DateTime.now(),
    );
    _pendingSpells[spell.id] = pendingSpell;
  }
  
  /// Attempt to counter a spell
  bool attemptCounter(ActionCard counterSpell, String counterId) {
    // Find the most recent pending spell
    if (_pendingSpells.isEmpty) return false;
    
    final latestSpell = _pendingSpells.values.last;
    if (latestSpell.isExpired) {
      _pendingSpells.remove(latestSpell.spell.id);
      return false;
    }
    
    final attempt = CounterSpellAttempt(
      counterSpell: counterSpell,
      counterId: counterId,
      targetSpellId: latestSpell.spell.id,
      attemptTime: DateTime.now(),
      counterType: CounterType.dispel, // Default to dispel
    );
    
    _counterAttempts.add(attempt);
    
    // Resolve the spell with counter result
    if (onSpellResolved != null) {
      onSpellResolved!(latestSpell, [attempt], 1.0, ['Spell countered!']);
    }
    
    _pendingSpells.remove(latestSpell.spell.id);
    return true;
  }
}

class CounterStack {
  final ActionCard counterCard;
  final String targetSpellId;
  final DateTime timestamp;
  
  const CounterStack({
    required this.counterCard,
    required this.targetSpellId,
    required this.timestamp,
  });
}

/// Extension to battle model for counter spell creation
extension CounterSpells on ActionCard {
  static ActionCard counterSpell({
    String name = 'Counter Spell',
    String description = 'Negates the next spell cast against you',
    int cost = 2,
  }) {
    return ActionCard(
      id: 'counter_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      type: ActionCardType.counter,
      effect: 'counter',
      cost: cost,
      physicalRequirement: '',
    );
  }
  
  static ActionCard reflect({
    String name = 'Spell Reflect',
    String description = 'Reflects the next spell back to the caster',
    int cost = 3,
  }) {
    return ActionCard(
      id: 'reflect_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      type: ActionCardType.counter,
      effect: 'reflect',
      cost: cost,
      physicalRequirement: '',
    );
  }
  
  static ActionCard absorb({
    String name = 'Spell Absorb',
    String description = 'Absorbs the next spell and converts it to mana',
    int cost = 4,
  }) {
    return ActionCard(
      id: 'absorb_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      type: ActionCardType.counter,
      effect: 'absorb',
      cost: cost,
      physicalRequirement: '',
    );
  }
}