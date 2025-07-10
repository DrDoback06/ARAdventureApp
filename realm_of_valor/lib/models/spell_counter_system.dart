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
  
  /// Add a counter spell to the stack for a specific player
  void addCounterSpell(String playerId, ActionCard counterCard, String targetSpellId) {
    _counterStacks.putIfAbsent(playerId, () => []);
    _counterStacks[playerId]!.add(CounterStack(
      counterCard: counterCard,
      targetSpellId: targetSpellId,
      timestamp: DateTime.now(),
    ));
  }
  
  /// Check if a spell can be countered and return the counter card if available
  ActionCard? checkForCounter(String targetPlayerId, String spellId) {
    final counters = _counterStacks[targetPlayerId];
    if (counters == null || counters.isEmpty) return null;
    
    // Find the most recent counter that matches this spell
    final matchingCounter = counters.lastWhere(
      (counter) => counter.targetSpellId == spellId,
      orElse: () => CounterStack(
        counterCard: ActionCard.skip(), 
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
      cost: cost,
      physicalRequirement: '',
    );
  }
}