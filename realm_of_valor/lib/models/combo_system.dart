import 'dart:math';
import 'package:flutter/material.dart';
import 'particle_type.dart';

/// Different types of combo effects
enum ComboType {
  elemental,    // Fire + Fire = Inferno
  opposing,     // Fire + Ice = Steam Explosion  
  supportive,   // Heal + Shield = Divine Protection
  destructive,  // Damage + Damage = Critical Strike
  tactical,     // Buff + Debuff = Tactical Advantage
}

enum ComboTrigger {
  consecutive,  // Cast spells one after another
  simultaneous, // Cast multiple spells in same turn
  stacking,     // Build up combo over multiple turns
  reactive,     // Triggered by opponent's actions
}

class SpellCombo {
  final String id;
  final String name;
  final String description;
  final List<ActionCardType> requiredSpellTypes;
  final List<String> requiredSpellNames; // Optional: specific spell names
  final ComboType type;
  final ComboTrigger trigger;
  final int maxTurnsToComplete;
  final double damageMultiplier;
  final Map<String, dynamic> bonusEffects;
  final ParticleType comboParticleEffect;
  final int requiredSpellCount;
  
  SpellCombo({
    String? id,
    required this.name,
    required this.description,
    required this.requiredSpellTypes,
    List<String>? requiredSpellNames,
    required this.type,
    this.trigger = ComboTrigger.consecutive,
    this.maxTurnsToComplete = 3,
    this.damageMultiplier = 1.5,
    Map<String, dynamic>? bonusEffects,
    this.comboParticleEffect = ParticleType.explosion,
    int? requiredSpellCount,
  }) : id = id ?? const Uuid().v4(),
       requiredSpellNames = requiredSpellNames ?? <String>[],
       bonusEffects = bonusEffects ?? <String, dynamic>{},
       requiredSpellCount = requiredSpellCount ?? requiredSpellTypes.length;

  bool canTrigger(List<ActionCard> spellSequence) {
    if (spellSequence.length < requiredSpellCount) return false;
    
    // Check if we have the required spell types
    final recentSpells = spellSequence.take(requiredSpellCount).toList();
    
    // Check type requirements
    for (final requiredType in requiredSpellTypes) {
      if (!recentSpells.any((spell) => spell.type == requiredType)) {
        return false;
      }
    }
    
    // Check specific spell name requirements
    for (final requiredName in requiredSpellNames) {
      if (!recentSpells.any((spell) => spell.name.toLowerCase().contains(requiredName.toLowerCase()))) {
        return false;
      }
    }
    
    return true;
  }

  ComboResult execute(List<ActionCard> triggeredSpells, BattlePlayer caster, BattlePlayer target) {
    final totalDamage = triggeredSpells.fold<int>(0, (sum, spell) {
      // Extract damage from spell effect
      final effect = spell.effect.toLowerCase();
      final damageMatch = RegExp(r'damage:(\d+)').firstMatch(effect);
      final baseDamage = damageMatch != null ? int.parse(damageMatch.group(1)!) : 0;
      return sum + baseDamage;
    });
    
    final comboDamage = (totalDamage * damageMultiplier).round();
    
    return ComboResult(
      comboId: id,
      comboName: name,
      triggeredSpells: triggeredSpells,
      casterId: caster.id,
      targetId: target.id,
      totalDamage: comboDamage,
      bonusEffects: Map<String, dynamic>.from(bonusEffects),
      particleEffect: comboParticleEffect,
      executedAt: DateTime.now(),
    );
  }
}

class ComboResult {
  final String comboId;
  final String comboName;
  final List<ActionCard> triggeredSpells;
  final String casterId;
  final String targetId;
  final int totalDamage;
  final Map<String, dynamic> bonusEffects;
  final ParticleType particleEffect;
  final DateTime executedAt;
  
  ComboResult({
    required this.comboId,
    required this.comboName,
    required this.triggeredSpells,
    required this.casterId,
    required this.targetId,
    required this.totalDamage,
    required this.bonusEffects,
    required this.particleEffect,
    required this.executedAt,
  });
}

class ComboTracker {
  final String playerId;
  final List<ActionCard> recentSpells;
  final int turnCast;
  final DateTime lastCastTime;
  
  ComboTracker({
    required this.playerId,
    List<ActionCard>? recentSpells,
    required this.turnCast,
    DateTime? lastCastTime,
  }) : recentSpells = recentSpells ?? <ActionCard>[],
       lastCastTime = lastCastTime ?? DateTime.now();

  ComboTracker addSpell(ActionCard spell, int currentTurn) {
    final newSpells = List<ActionCard>.from(recentSpells);
    newSpells.add(spell);
    
    // Keep only recent spells (last 5 spells or spells from last 3 turns)
    final filteredSpells = newSpells.where((s) {
      final spellIndex = newSpells.indexOf(s);
      return spellIndex >= newSpells.length - 5; // Keep last 5 spells
    }).toList();
    
    return ComboTracker(
      playerId: playerId,
      recentSpells: filteredSpells,
      turnCast: currentTurn,
      lastCastTime: DateTime.now(),
    );
  }

  bool isWithinComboWindow(int currentTurn, int maxTurns) {
    return (currentTurn - turnCast) <= maxTurns;
  }
}

class SpellComboSystem {
  final Map<String, ComboTracker> _playerTrackers = {};
  final List<SpellCombo> _availableCombos = [];
  final List<ComboResult> _recentCombos = [];
  
  // Callback for when a combo is executed
  Function(ComboResult)? onComboExecuted;
  
  SpellComboSystem() {
    _initializeBasicCombos();
  }
  
  void _initializeBasicCombos() {
    _availableCombos.addAll([
      // Elemental Combos
      SpellCombo(
        name: 'Inferno Burst',
        description: 'Fire spells combine for massive burn damage',
        requiredSpellTypes: [ActionCardType.spell, ActionCardType.spell],
        requiredSpellNames: ['fire', 'flame'],
        type: ComboType.elemental,
        trigger: ComboTrigger.consecutive,
        damageMultiplier: 2.0,
        bonusEffects: {'burn_duration': 3, 'extra_damage': 15},
        comboParticleEffect: ParticleType.fire,
      ),
      
      SpellCombo(
        name: 'Frost Nova',
        description: 'Ice spells create area freeze effect',
        requiredSpellTypes: [ActionCardType.spell, ActionCardType.spell],
        requiredSpellNames: ['ice', 'frost'],
        type: ComboType.elemental,
        trigger: ComboTrigger.consecutive,
        damageMultiplier: 1.8,
        bonusEffects: {'freeze_duration': 2, 'area_effect': true},
        comboParticleEffect: ParticleType.ice,
      ),
      
      SpellCombo(
        name: 'Thunder Storm',
        description: 'Lightning spells chain between enemies',
        requiredSpellTypes: [ActionCardType.spell, ActionCardType.spell],
        requiredSpellNames: ['lightning', 'thunder'],
        type: ComboType.elemental,
        trigger: ComboTrigger.consecutive,
        damageMultiplier: 1.7,
        bonusEffects: {'chain_targets': 2, 'shock_duration': 2},
        comboParticleEffect: ParticleType.lightning,
      ),
      
      // Opposing Element Combos
      SpellCombo(
        name: 'Steam Explosion',
        description: 'Fire and Ice create devastating steam blast',
        requiredSpellTypes: [ActionCardType.spell, ActionCardType.spell],
        requiredSpellNames: ['fire', 'ice'],
        type: ComboType.opposing,
        trigger: ComboTrigger.consecutive,
        damageMultiplier: 2.5,
        bonusEffects: {'area_damage': 20, 'blind_duration': 1},
        comboParticleEffect: ParticleType.explosion,
      ),
      
      // Support Combos
      SpellCombo(
        name: 'Divine Protection',
        description: 'Heal and Shield create powerful defensive barrier',
        requiredSpellTypes: [ActionCardType.heal, ActionCardType.buff],
        type: ComboType.supportive,
        trigger: ComboTrigger.consecutive,
        damageMultiplier: 1.0,
        bonusEffects: {'shield_strength': 30, 'heal_boost': 1.5},
        comboParticleEffect: ParticleType.shield,
      ),
      
      // Destructive Combos
      SpellCombo(
        name: 'Critical Strike',
        description: 'Multiple damage spells guarantee critical hit',
        requiredSpellTypes: [ActionCardType.damage, ActionCardType.damage],
        type: ComboType.destructive,
        trigger: ComboTrigger.consecutive,
        damageMultiplier: 2.2,
        bonusEffects: {'critical_chance': 100, 'armor_pierce': true},
        comboParticleEffect: ParticleType.explosion,
      ),
      
      // Tactical Combos
      SpellCombo(
        name: 'Tactical Advantage',
        description: 'Buff and Debuff create strategic superiority',
        requiredSpellTypes: [ActionCardType.buff, ActionCardType.debuff],
        type: ComboType.tactical,
        trigger: ComboTrigger.consecutive,
        damageMultiplier: 1.3,
        bonusEffects: {'extra_turn': true, 'mana_restore': 5},
        comboParticleEffect: ParticleType.arcane,
      ),
    ]);
  }
  
  void trackSpellCast(String playerId, ActionCard spell, int currentTurn) {
    final currentTracker = _playerTrackers[playerId] ?? ComboTracker(
      playerId: playerId,
      turnCast: currentTurn,
    );
    
    final updatedTracker = currentTracker.addSpell(spell, currentTurn);
    _playerTrackers[playerId] = updatedTracker;
    
    // Check for possible combos
    _checkForCombos(playerId, currentTurn);
  }
  
  void _checkForCombos(String playerId, int currentTurn) {
    final tracker = _playerTrackers[playerId];
    if (tracker == null) return;
    
    for (final combo in _availableCombos) {
      if (tracker.isWithinComboWindow(currentTurn, combo.maxTurnsToComplete)) {
        if (combo.canTrigger(tracker.recentSpells)) {
          // Found a valid combo!
          _triggerCombo(combo, tracker, playerId);
          break; // Only trigger one combo per spell cast
        }
      }
    }
  }
  
  void _triggerCombo(SpellCombo combo, ComboTracker tracker, String playerId) {
    // This would need actual player and target references
    // For now, we'll create a combo result that can be handled by the battle controller
    final triggeredSpells = tracker.recentSpells.take(combo.requiredSpellCount).toList();
    
    // Create a placeholder combo result
    final comboResult = ComboResult(
      comboId: combo.id,
      comboName: combo.name,
      triggeredSpells: triggeredSpells,
      casterId: playerId,
      targetId: 'placeholder', // This would be determined by the battle controller
      totalDamage: 0, // This would be calculated with actual spell effects
      bonusEffects: combo.bonusEffects,
      particleEffect: combo.comboParticleEffect,
      executedAt: DateTime.now(),
    );
    
    _recentCombos.add(comboResult);
    
    // Notify the battle controller
    onComboExecuted?.call(comboResult);
    
    // Clear the combo tracker to prevent repeated triggering
    _playerTrackers[playerId] = ComboTracker(
      playerId: playerId,
      turnCast: tracker.turnCast,
    );
  }
  
  List<SpellCombo> getPossibleCombos(String playerId) {
    final tracker = _playerTrackers[playerId];
    if (tracker == null) return [];
    
    return _availableCombos.where((combo) {
      final recentTypes = tracker.recentSpells.map((s) => s.type).toSet();
      final requiredTypes = combo.requiredSpellTypes.toSet();
      
      // Check if player has cast any of the required spell types recently
      return requiredTypes.intersection(recentTypes).isNotEmpty;
    }).toList();
  }
  
  List<ComboResult> getRecentCombos({int limit = 10}) {
    return _recentCombos.take(limit).toList();
  }
  
  void clearPlayerTracker(String playerId) {
    _playerTrackers.remove(playerId);
  }
  
  void clearAllTrackers() {
    _playerTrackers.clear();
  }
  
  // Get combo suggestions for the current spell sequence
  List<String> getComboSuggestions(String playerId) {
    final tracker = _playerTrackers[playerId];
    if (tracker == null || tracker.recentSpells.isEmpty) return [];
    
    final suggestions = <String>[];
    
    for (final combo in _availableCombos) {
      final recentSpellTypes = tracker.recentSpells.map((s) => s.type).toList();
      final recentSpellNames = tracker.recentSpells.map((s) => s.name.toLowerCase()).toList();
      
      // Check how close we are to completing this combo
      final typeMatches = combo.requiredSpellTypes.where((type) => 
          recentSpellTypes.contains(type)).length;
      final nameMatches = combo.requiredSpellNames.where((name) => 
          recentSpellNames.any((spellName) => spellName.contains(name.toLowerCase()))).length;
      
      if (typeMatches > 0 || nameMatches > 0) {
        final totalRequired = combo.requiredSpellCount;
        final totalMatches = typeMatches + nameMatches;
        
        if (totalMatches >= totalRequired - 1) {
          // Very close to combo
          suggestions.add('${combo.name} (1 spell needed)');
        } else if (totalMatches >= totalRequired - 2) {
          // Getting close to combo
          suggestions.add('${combo.name} (${totalRequired - totalMatches} spells needed)');
        }
      }
    }
    
    return suggestions;
  }
} 

enum ChargeLevel {
  normal,      // 0-1 seconds
  charged,     // 1-2 seconds  
  supercharged, // 2-3 seconds
  overcharged, // 3+ seconds
}

class SpellCharge {
  final ChargeLevel level;
  final String name;
  final String description;
  final double damageMultiplier;
  final double manaCostMultiplier;
  final Color chargeColor;
  final ParticleType chargeEffect;
  final List<String> bonusEffects;
  final Duration minimumHoldTime;

  const SpellCharge({
    required this.level,
    required this.name,
    required this.description,
    required this.damageMultiplier,
    required this.manaCostMultiplier,
    required this.chargeColor,
    required this.chargeEffect,
    required this.bonusEffects,
    required this.minimumHoldTime,
  });
}

class ChargingSpell {
  final ActionCard card;
  final String casterId;
  final String targetId;
  final DateTime startTime;
  late Timer _chargeTimer;
  ChargeLevel currentLevel = ChargeLevel.normal;
  final Function(ChargingSpell) onChargeChange;
  final Function(ChargingSpell) onOvercharge;

  ChargingSpell({
    required this.card,
    required this.casterId,
    required this.targetId,
    required this.startTime,
    required this.onChargeChange,
    required this.onOvercharge,
  }) {
    _startCharging();
  }

  void _startCharging() {
    _chargeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final elapsed = DateTime.now().difference(startTime);
      final newLevel = _calculateChargeLevel(elapsed);
      
      if (newLevel != currentLevel) {
        currentLevel = newLevel;
        onChargeChange(this);
        
        // Trigger overcharge warning
        if (newLevel == ChargeLevel.overcharged) {
          onOvercharge(this);
        }
      }
    });
  }

  ChargeLevel _calculateChargeLevel(Duration elapsed) {
    final seconds = elapsed.inMilliseconds / 1000.0;
    
    if (seconds >= 3.0) {
      return ChargeLevel.overcharged;
    } else if (seconds >= 2.0) {
      return ChargeLevel.supercharged;
    } else if (seconds >= 1.0) {
      return ChargeLevel.charged;
    } else {
      return ChargeLevel.normal;
    }
  }

  Duration get chargeTime => DateTime.now().difference(startTime);
  
  double get chargeProgress {
    final seconds = chargeTime.inMilliseconds / 1000.0;
    return math.min(seconds / 3.0, 1.0); // Max out at 3 seconds
  }

  void stopCharging() {
    _chargeTimer.cancel();
  }

  void dispose() {
    _chargeTimer.cancel();
  }
}

class SpellChargingSystem {
  final Map<String, ChargingSpell> _activeCharges = {};
  final List<SpellCharge> _chargeDefinitions = [
    SpellCharge(
      level: ChargeLevel.normal,
      name: 'Quick Cast',
      description: 'Standard spell power',
      damageMultiplier: 1.0,
      manaCostMultiplier: 1.0,
      chargeColor: Colors.white,
      chargeEffect: ParticleType.sparkle,
      bonusEffects: [],
      minimumHoldTime: Duration.zero,
    ),
    
    SpellCharge(
      level: ChargeLevel.charged,
      name: 'Charged',
      description: 'Enhanced spell power and effects',
      damageMultiplier: 1.3,
      manaCostMultiplier: 1.1,
      chargeColor: Colors.yellow,
      chargeEffect: ParticleType.energy,
      bonusEffects: ['piercing'],
      minimumHoldTime: Duration(seconds: 1),
    ),
    
    SpellCharge(
      level: ChargeLevel.supercharged,
      name: 'Supercharged',
      description: 'Greatly enhanced power with bonus effects',
      damageMultiplier: 1.7,
      manaCostMultiplier: 1.25,
      chargeColor: Colors.orange,
      chargeEffect: ParticleType.lightning,
      bonusEffects: ['piercing', 'splash_damage', 'critical_bonus'],
      minimumHoldTime: Duration(seconds: 2),
    ),
    
    SpellCharge(
      level: ChargeLevel.overcharged,
      name: 'OVERCHARGED',
      description: 'Maximum power but increased mana cost and risk',
      damageMultiplier: 2.2,
      manaCostMultiplier: 1.5,
      chargeColor: Colors.red,
      chargeEffect: ParticleType.explosion,
      bonusEffects: ['piercing', 'splash_damage', 'critical_bonus', 'area_effect'],
      minimumHoldTime: Duration(seconds: 3),
    ),
  ];

  /// Start charging a spell
  String startCharging(
    ActionCard card,
    String casterId,
    String targetId,
    Function(ChargingSpell) onChargeChange,
    Function(ChargingSpell) onOvercharge,
  ) {
    final chargeId = '${casterId}_${DateTime.now().millisecondsSinceEpoch}';
    
    final chargingSpell = ChargingSpell(
      card: card,
      casterId: casterId,
      targetId: targetId,
      startTime: DateTime.now(),
      onChargeChange: onChargeChange,
      onOvercharge: onOvercharge,
    );
    
    _activeCharges[chargeId] = chargingSpell;
    return chargeId;
  }

  /// Release a charging spell
  SpellChargeResult? releaseCharge(String chargeId) {
    final chargingSpell = _activeCharges[chargeId];
    if (chargingSpell == null) return null;
    
    final chargeData = getChargeData(chargingSpell.currentLevel);
    final result = SpellChargeResult(
      originalCard: chargingSpell.card,
      chargeLevel: chargingSpell.currentLevel,
      chargeData: chargeData,
      chargeTime: chargingSpell.chargeTime,
      enhancedDamage: _calculateEnhancedDamage(chargingSpell.card, chargeData),
      enhancedManaCost: _calculateEnhancedManaCost(chargingSpell.card, chargeData),
      bonusEffects: chargeData.bonusEffects,
      casterId: chargingSpell.casterId,
      targetId: chargingSpell.targetId,
    );
    
    chargingSpell.dispose();
    _activeCharges.remove(chargeId);
    
    return result;
  }

  /// Cancel a charging spell
  void cancelCharge(String chargeId) {
    final chargingSpell = _activeCharges[chargeId];
    if (chargingSpell != null) {
      chargingSpell.dispose();
      _activeCharges.remove(chargeId);
    }
  }

  /// Get charge data for a specific level
  SpellCharge getChargeData(ChargeLevel level) {
    return _chargeDefinitions.firstWhere((charge) => charge.level == level);
  }

  /// Calculate enhanced damage based on charge level
  int _calculateEnhancedDamage(ActionCard card, SpellCharge chargeData) {
    // Extract base damage from card
    final baseDamage = _extractDamageFromCard(card);
    return (baseDamage * chargeData.damageMultiplier).round();
  }

  /// Calculate enhanced mana cost based on charge level
  int _calculateEnhancedManaCost(ActionCard card, SpellCharge chargeData) {
    return (card.cost * chargeData.manaCostMultiplier).round();
  }

  /// Extract damage value from card effect
  int _extractDamageFromCard(ActionCard card) {
    final effects = card.effect.split(',');
    for (final effect in effects) {
      if (effect.trim().startsWith('damage:')) {
        return int.tryParse(effect.split(':')[1]) ?? 0;
      }
    }
    return 0;
  }

  /// Get currently charging spell
  ChargingSpell? getChargingSpell(String chargeId) {
    return _activeCharges[chargeId];
  }

  /// Get all active charges
  Map<String, ChargingSpell> getAllActiveCharges() {
    return Map.from(_activeCharges);
  }

  /// Check if a card can be charged
  bool canChargeCard(ActionCard card) {
    // Only spell and special cards can be charged
    return card.type == ActionCardType.spell || 
           card.type == ActionCardType.special ||
           card.type == ActionCardType.damage;
  }

  /// Get charge visual effects for UI
  ChargeVisualEffect getChargeVisualEffect(ChargeLevel level) {
    final chargeData = getChargeData(level);
    
    return ChargeVisualEffect(
      level: level,
      color: chargeData.chargeColor,
      particleType: chargeData.chargeEffect,
      glowIntensity: _getGlowIntensity(level),
      pulseSpeed: _getPulseSpeed(level),
      showWarning: level == ChargeLevel.overcharged,
    );
  }

  double _getGlowIntensity(ChargeLevel level) {
    switch (level) {
      case ChargeLevel.normal:
        return 0.0;
      case ChargeLevel.charged:
        return 0.3;
      case ChargeLevel.supercharged:
        return 0.6;
      case ChargeLevel.overcharged:
        return 1.0;
    }
  }

  double _getPulseSpeed(ChargeLevel level) {
    switch (level) {
      case ChargeLevel.normal:
        return 1.0;
      case ChargeLevel.charged:
        return 1.2;
      case ChargeLevel.supercharged:
        return 1.5;
      case ChargeLevel.overcharged:
        return 2.0;
    }
  }

  /// Apply charge effects to spell
  String applyChargeEffects(SpellChargeResult chargeResult, String originalEffect) {
    var enhancedEffect = originalEffect;
    final bonusEffects = chargeResult.bonusEffects;
    
    // Apply bonus effects
    if (bonusEffects.contains('piercing')) {
      enhancedEffect += ',ignore_armor';
    }
    if (bonusEffects.contains('splash_damage')) {
      enhancedEffect += ',splash:50';
    }
    if (bonusEffects.contains('critical_bonus')) {
      enhancedEffect += ',critical_chance:+20';
    }
    if (bonusEffects.contains('area_effect')) {
      enhancedEffect += ',damage_all_nearby:25';
    }
    
    return enhancedEffect;
  }

  /// Clear all active charges (for cleanup)
  void clearAllCharges() {
    for (final charge in _activeCharges.values) {
      charge.dispose();
    }
    _activeCharges.clear();
  }

  /// Get charge descriptions for UI
  List<SpellCharge> getAllChargeTypes() {
    return List.from(_chargeDefinitions);
  }
}

class SpellChargeResult {
  final ActionCard originalCard;
  final ChargeLevel chargeLevel;
  final SpellCharge chargeData;
  final Duration chargeTime;
  final int enhancedDamage;
  final int enhancedManaCost;
  final List<String> bonusEffects;
  final String casterId;
  final String targetId;

  SpellChargeResult({
    required this.originalCard,
    required this.chargeLevel,
    required this.chargeData,
    required this.chargeTime,
    required this.enhancedDamage,
    required this.enhancedManaCost,
    required this.bonusEffects,
    required this.casterId,
    required this.targetId,
  });

  int get bonusDamage => enhancedDamage - _getBaseDamage();
  int get bonusManaCost => enhancedManaCost - originalCard.cost;
  
  int _getBaseDamage() {
    final effects = originalCard.effect.split(',');
    for (final effect in effects) {
      if (effect.trim().startsWith('damage:')) {
        return int.tryParse(effect.split(':')[1]) ?? 0;
      }
    }
    return 0;
  }
}

class ChargeVisualEffect {
  final ChargeLevel level;
  final Color color;
  final ParticleType particleType;
  final double glowIntensity;
  final double pulseSpeed;
  final bool showWarning;

  ChargeVisualEffect({
    required this.level,
    required this.color,
    required this.particleType,
    required this.glowIntensity,
    required this.pulseSpeed,
    required this.showWarning,
  });
} 