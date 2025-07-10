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

class SpellCounterSystem extends ChangeNotifier {
  static final SpellCounterSystem _instance = SpellCounterSystem._internal();
  factory SpellCounterSystem() => _instance;
  SpellCounterSystem._internal();

  PendingSpell? _currentPendingSpell;
  final List<CounterSpellAttempt> _counterAttempts = [];
  Timer? _interruptTimer;
  
  // Elemental Counter Rules
  static final List<SpellCounterRule> _counterRules = [
    // Classic Elemental Oppositions
    SpellCounterRule(
      sourceElement: SpellElement.fire,
      counterElement: SpellElement.water,
      counterType: CounterType.elemental,
      effectiveness: 1.5,
      description: 'Water extinguishes fire completely',
    ),
    SpellCounterRule(
      sourceElement: SpellElement.fire,
      counterElement: SpellElement.ice,
      counterType: CounterType.elemental,
      effectiveness: 1.8,
      description: 'Ice flash-freezes fire magic',
    ),
    SpellCounterRule(
      sourceElement: SpellElement.water,
      counterElement: SpellElement.lightning,
      counterType: CounterType.amplify,
      effectiveness: 2.0,
      description: 'Lightning conducts through water, amplifying both spells',
    ),
    SpellCounterRule(
      sourceElement: SpellElement.earth,
      counterElement: SpellElement.air,
      counterType: CounterType.elemental,
      effectiveness: 1.3,
      description: 'Wind scatters earth magic',
    ),
    SpellCounterRule(
      sourceElement: SpellElement.light,
      counterElement: SpellElement.shadow,
      counterType: CounterType.elemental,
      effectiveness: 2.0,
      description: 'Light and shadow annihilate each other',
    ),
    SpellCounterRule(
      sourceElement: SpellElement.shadow,
      counterElement: SpellElement.light,
      counterType: CounterType.elemental,
      effectiveness: 2.0,
      description: 'Pure light banishes shadow',
    ),
    
    // Advanced Combinations
    SpellCounterRule(
      sourceElement: SpellElement.fire,
      counterElement: SpellElement.earth,
      counterType: CounterType.absorb,
      effectiveness: 0.7,
      description: 'Earth absorbs fire, creating lava magic',
    ),
    SpellCounterRule(
      sourceElement: SpellElement.water,
      counterElement: SpellElement.ice,
      counterType: CounterType.amplify,
      effectiveness: 1.5,
      description: 'Water becomes ice, strengthening cold magic',
    ),
    SpellCounterRule(
      sourceElement: SpellElement.lightning,
      counterElement: SpellElement.earth,
      counterType: CounterType.elemental,
      effectiveness: 1.0,
      description: 'Earth grounds lightning harmlessly',
    ),
    
    // Universal Counters
    SpellCounterRule(
      sourceElement: SpellElement.arcane,
      counterElement: SpellElement.arcane,
      counterType: CounterType.dispel,
      effectiveness: 1.0,
      description: 'Arcane magic disrupts any spell',
    ),
  ];

  // Getters
  PendingSpell? get currentPendingSpell => _currentPendingSpell;
  List<CounterSpellAttempt> get counterAttempts => List.unmodifiable(_counterAttempts);
  bool get hasActiveInterrupt => _currentPendingSpell != null && !_currentPendingSpell!.isExpired;

  /// Start an interrupt window for a spell
  void startInterruptWindow(ActionCard spell, String casterId, String targetId) {
    // Cancel any existing interrupt
    _cancelCurrentInterrupt();
    
    _currentPendingSpell = PendingSpell(
      spell: spell,
      casterId: casterId,
      targetId: targetId,
      castTime: DateTime.now(),
    );
    
    if (kDebugMode) {
      print('[SPELL COUNTER] Interrupt window started for ${spell.name} (${_currentPendingSpell!.interruptWindowMs}ms)');
    }
    
    // Start countdown timer
    _interruptTimer = Timer(Duration(milliseconds: _currentPendingSpell!.interruptWindowMs), () {
      _resolveSpellWithCounters();
    });
    
    notifyListeners();
  }

  /// Attempt to counter the current pending spell
  bool attemptCounter(ActionCard counterSpell, String counterId) {
    if (_currentPendingSpell == null || _currentPendingSpell!.isExpired) {
      return false;
    }
    
    final counterType = _getCounterType(_currentPendingSpell!.spell, counterSpell);
    if (counterType == null) {
      return false; // Not a valid counter
    }
    
    final attempt = CounterSpellAttempt(
      counterSpell: counterSpell,
      counterId: counterId,
      targetSpellId: _currentPendingSpell!.spell.id,
      attemptTime: DateTime.now(),
      counterType: counterType,
    );
    
    _counterAttempts.add(attempt);
    
    if (kDebugMode) {
      print('[SPELL COUNTER] ${counterSpell.name} attempts to counter ${_currentPendingSpell!.spell.name}');
    }
    
    notifyListeners();
    return true;
  }

  /// Check if a card can counter the current pending spell
  bool canCounter(ActionCard potentialCounter) {
    if (_currentPendingSpell == null) return false;
    return _getCounterType(_currentPendingSpell!.spell, potentialCounter) != null;
  }

  /// Get available counter spells from a player's hand
  List<ActionCard> getAvailableCounters(List<ActionCard> hand) {
    if (_currentPendingSpell == null) return [];
    
    return hand.where((card) => canCounter(card)).toList();
  }

  /// Force resolve the spell immediately (for testing or instant counters)
  void forceResolve() {
    _interruptTimer?.cancel();
    _resolveSpellWithCounters();
  }

  /// Get the counter type between two spells
  CounterType? _getCounterType(ActionCard originalSpell, ActionCard counterSpell) {
    final originalElement = _getSpellElement(originalSpell);
    final counterElement = _getSpellElement(counterSpell);
    
    // Check for elemental counters
    final rule = _counterRules.firstWhere(
      (rule) => rule.sourceElement == originalElement && rule.counterElement == counterElement,
      orElse: () => SpellCounterRule(
        sourceElement: SpellElement.neutral,
        counterElement: SpellElement.neutral,
        counterType: CounterType.dispel,
        effectiveness: 0.0,
        description: 'No effect',
      ),
    );
    
    if (rule.effectiveness > 0.0) {
      return rule.counterType;
    }
    
    // Check for generic dispel spells
    if (counterSpell.effect.contains('dispel') || counterSpell.effect.contains('cancel_action')) {
      return CounterType.dispel;
    }
    
    return null;
  }

  /// Get the elemental type of a spell based on its properties
  SpellElement _getSpellElement(ActionCard spell) {
    final name = spell.name.toLowerCase();
    final description = spell.description.toLowerCase();
    final effect = spell.effect.toLowerCase();
    
    // Fire spells
    if (name.contains('fire') || name.contains('burn') || name.contains('flame') || 
        description.contains('fire') || description.contains('burn') || effect.contains('burn')) {
      return SpellElement.fire;
    }
    
    // Water spells
    if (name.contains('water') || name.contains('wave') || name.contains('tsunami') ||
        description.contains('water') || description.contains('wave')) {
      return SpellElement.water;
    }
    
    // Ice spells
    if (name.contains('ice') || name.contains('frost') || name.contains('freeze') ||
        description.contains('ice') || description.contains('frost') || effect.contains('freeze')) {
      return SpellElement.ice;
    }
    
    // Lightning spells
    if (name.contains('lightning') || name.contains('thunder') || name.contains('shock') ||
        description.contains('lightning') || description.contains('thunder') || effect.contains('shock')) {
      return SpellElement.lightning;
    }
    
    // Light spells
    if (name.contains('light') || name.contains('holy') || name.contains('divine') ||
        description.contains('light') || description.contains('holy') || description.contains('divine')) {
      return SpellElement.light;
    }
    
    // Shadow spells
    if (name.contains('shadow') || name.contains('dark') || name.contains('curse') ||
        description.contains('shadow') || description.contains('dark') || effect.contains('curse')) {
      return SpellElement.shadow;
    }
    
    // Earth spells
    if (name.contains('earth') || name.contains('stone') || name.contains('rock') ||
        description.contains('earth') || description.contains('stone')) {
      return SpellElement.earth;
    }
    
    // Air spells
    if (name.contains('air') || name.contains('wind') || name.contains('gust') ||
        description.contains('air') || description.contains('wind')) {
      return SpellElement.air;
    }
    
    // Nature spells
    if (name.contains('nature') || name.contains('growth') || name.contains('thorn') ||
        description.contains('nature') || description.contains('growth')) {
      return SpellElement.nature;
    }
    
    // Arcane spells
    if (name.contains('arcane') || name.contains('magic') || name.contains('dispel') ||
        description.contains('arcane') || description.contains('magic')) {
      return SpellElement.arcane;
    }
    
    // Physical abilities
    if (spell.type == ActionCardType.physical || name.contains('strike') || name.contains('attack')) {
      return SpellElement.physical;
    }
    
    return SpellElement.neutral;
  }

  /// Resolve the pending spell with all counter attempts
  void _resolveSpellWithCounters() {
    if (_currentPendingSpell == null) return;
    
    final originalSpell = _currentPendingSpell!;
    final counters = List<CounterSpellAttempt>.from(_counterAttempts);
    
    if (kDebugMode) {
      print('[SPELL COUNTER] Resolving ${originalSpell.spell.name} with ${counters.length} counter attempts');
    }
    
    // Calculate final effect based on counters
    double effectMultiplier = 1.0;
    List<String> resolutionMessages = [];
    
    for (final counter in counters) {
      final rule = _counterRules.firstWhere(
        (rule) => rule.sourceElement == _getSpellElement(originalSpell.spell) && 
                  rule.counterElement == _getSpellElement(counter.counterSpell),
        orElse: () => SpellCounterRule(
          sourceElement: SpellElement.neutral,
          counterElement: SpellElement.neutral,
          counterType: CounterType.dispel,
          effectiveness: 1.0,
          description: 'Generic counter',
        ),
      );
      
      switch (counter.counterType) {
        case CounterType.elemental:
          effectMultiplier = 1.0 - rule.effectiveness;
          resolutionMessages.add('${counter.counterSpell.name} ${rule.description}');
          break;
        case CounterType.dispel:
          effectMultiplier = 0.0;
          resolutionMessages.add('${counter.counterSpell.name} dispels ${originalSpell.spell.name}!');
          break;
        case CounterType.absorb:
          effectMultiplier = 0.0;
          resolutionMessages.add('${counter.counterSpell.name} absorbs ${originalSpell.spell.name}!');
          // TODO: Apply absorbed power to counter caster
          break;
        case CounterType.reflect:
          effectMultiplier = 0.0;
          resolutionMessages.add('${counter.counterSpell.name} reflects ${originalSpell.spell.name} back!');
          // TODO: Apply spell to original caster
          break;
        case CounterType.amplify:
          effectMultiplier = rule.effectiveness;
          resolutionMessages.add('${counter.counterSpell.name} amplifies ${originalSpell.spell.name}!');
          // TODO: Apply amplified effect to both caster and counter caster
          break;
      }
    }
    
    // Cleanup
    _currentPendingSpell = null;
    _counterAttempts.clear();
    _interruptTimer?.cancel();
    _interruptTimer = null;
    
    notifyListeners();
    
    // Return resolution data for the battle controller to handle
    onSpellResolved?.call(originalSpell, counters, effectMultiplier, resolutionMessages);
  }

  void _cancelCurrentInterrupt() {
    _interruptTimer?.cancel();
    _interruptTimer = null;
    _currentPendingSpell = null;
    _counterAttempts.clear();
    notifyListeners();
  }

  // Callback for when spell resolution completes
  Function(PendingSpell, List<CounterSpellAttempt>, double, List<String>)? onSpellResolved;

  @override
  void dispose() {
    _interruptTimer?.cancel();
    super.dispose();
  }
}