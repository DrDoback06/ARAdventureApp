import 'package:flutter/material.dart';
import 'battle_model.dart';
import '../effects/particle_system.dart';
import 'unified_particle_system.dart';

enum ElementType {
  fire,
  ice,
  lightning,
  water,
  earth,
  air,
  light,
  shadow,
  arcane,
  nature,
}

enum ComboType {
  steam,        // Fire + Ice/Water
  electrocution, // Lightning + Water
  magma,        // Fire + Earth
  blizzard,     // Ice + Air
  thunderstorm, // Lightning + Air
  earthquake,   // Earth + Lightning
  eclipse,      // Light + Shadow
  inferno,      // Fire + Air
  flood,        // Water + Earth
  plasmaBolt,   // Lightning + Fire
  frostShock,   // Ice + Lightning
  healingRain,  // Water + Nature
  shadowFire,   // Shadow + Fire
  holyLight,    // Light + Nature
  voidStorm,    // Shadow + Lightning
}

class ElementalCombo {
  final ComboType type;
  final List<ElementType> requiredElements;
  final String name;
  final String description;
  final int damageMultiplier;
  final List<String> effects;
  final ParticleType particleEffect;
  final Color comboColor;
  final Duration comboDuration;

  const ElementalCombo({
    required this.type,
    required this.requiredElements,
    required this.name,
    required this.description,
    required this.damageMultiplier,
    required this.effects,
    required this.particleEffect,
    required this.comboColor,
    this.comboDuration = const Duration(seconds: 3),
  });
}

class ElementalComboSystem {
  final List<ElementCastRecord> _recentCasts = [];
  final Map<String, List<ElementalCombo>> _activeCombosByPlayer = {};
  final List<ElementalCombo> _allCombos = [
    // Fire-based combos
    ElementalCombo(
      type: ComboType.steam,
      requiredElements: [ElementType.fire, ElementType.ice],
      name: 'Steam Explosion',
      description: 'Fire and Ice create a devastating steam explosion!',
      damageMultiplier: 2,
      effects: ['damage_all_enemies', 'blind:2'],
      particleEffect: ParticleType.fire, // We'll use existing particles
      comboColor: Colors.grey,
    ),
    
    ElementalCombo(
      type: ComboType.electrocution,
      requiredElements: [ElementType.lightning, ElementType.water],
      name: 'Electrocution',
      description: 'Lightning through water conducts massive damage!',
      damageMultiplier: 3,
      effects: ['chain_damage:2', 'stun:1'],
      particleEffect: ParticleType.lightning,
      comboColor: Colors.cyan,
    ),
    
    ElementalCombo(
      type: ComboType.magma,
      requiredElements: [ElementType.fire, ElementType.earth],
      name: 'Magma Eruption',
      description: 'Fire and Earth erupt in molten fury!',
      damageMultiplier: 2,
      effects: ['burning_ground:5', 'damage_over_time:3'],
      particleEffect: ParticleType.fire,
      comboColor: Colors.deepOrange,
    ),
    
    ElementalCombo(
      type: ComboType.blizzard,
      requiredElements: [ElementType.ice, ElementType.air],
      name: 'Blizzard',
      description: 'Ice and Wind create a freezing storm!',
      damageMultiplier: 2,
      effects: ['freeze_all:2', 'reduce_visibility'],
      particleEffect: ParticleType.ice,
      comboColor: Colors.lightBlue,
    ),
    
    ElementalCombo(
      type: ComboType.thunderstorm,
      requiredElements: [ElementType.lightning, ElementType.air],
      name: 'Thunderstorm',
      description: 'Lightning and Wind create a chaotic storm!',
      damageMultiplier: 2,
      effects: ['random_target_strikes:5', 'confusion:2'],
      particleEffect: ParticleType.lightning,
      comboColor: Colors.yellow,
    ),
    
    ElementalCombo(
      type: ComboType.earthquake,
      requiredElements: [ElementType.earth, ElementType.lightning],
      name: 'Earthquake',
      description: 'Earth splits with lightning\'s power!',
      damageMultiplier: 3,
      effects: ['knockdown_all', 'terrain_damage:4'],
      particleEffect: ParticleType.earth,
      comboColor: Colors.brown,
    ),
    
    ElementalCombo(
      type: ComboType.eclipse,
      requiredElements: [ElementType.light, ElementType.shadow],
      name: 'Solar Eclipse',
      description: 'Light and Shadow merge in cosmic power!',
      damageMultiplier: 4,
      effects: ['time_stop:1', 'massive_damage'],
      particleEffect: ParticleType.shadow,
      comboColor: Colors.purple,
    ),
    
    ElementalCombo(
      type: ComboType.plasmaBolt,
      requiredElements: [ElementType.lightning, ElementType.fire],
      name: 'Plasma Bolt',
      description: 'Lightning and Fire create superheated plasma!',
      damageMultiplier: 3,
      effects: ['armor_piercing', 'energy_burn:3'],
      particleEffect: ParticleType.lightning,
      comboColor: Colors.pink,
    ),
    
    ElementalCombo(
      type: ComboType.frostShock,
      requiredElements: [ElementType.ice, ElementType.lightning],
      name: 'Frost Shock',
      description: 'Ice and Lightning create paralyzing cold!',
      damageMultiplier: 2,
      effects: ['paralysis:3', 'mana_drain:50'],
      particleEffect: ParticleType.ice,
      comboColor: Colors.lightBlue,
    ),
    
    ElementalCombo(
      type: ComboType.healingRain,
      requiredElements: [ElementType.water, ElementType.nature],
      name: 'Healing Rain',
      description: 'Water and Nature restore all allies!',
      damageMultiplier: 0, // Healing combo
      effects: ['heal_all_allies:50', 'regeneration:5'],
      particleEffect: ParticleType.heal,
      comboColor: Colors.green,
    ),
  ];

  /// Record a spell cast with its element
  void recordSpellCast(String playerId, ActionCard spell, String targetId) {
    final element = _getSpellElement(spell);
    if (element == null) return;

    final record = ElementCastRecord(
      playerId: playerId,
      spell: spell,
      element: element,
      targetId: targetId,
      timestamp: DateTime.now(),
    );

    _recentCasts.add(record);
    
    // Remove old casts (combos must be within 10 seconds)
    _recentCasts.removeWhere((cast) =>
      DateTime.now().difference(cast.timestamp).inSeconds > 10);

    // Check for combos
    _checkForCombos(playerId);
  }

  /// Check if recent casts form any combos
  void _checkForCombos(String playerId) {
    final playerCasts = _recentCasts
        .where((cast) => cast.playerId == playerId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Most recent first

    if (playerCasts.length < 2) return;

    for (final combo in _allCombos) {
      if (_canFormCombo(playerCasts, combo)) {
        _triggerCombo(playerId, combo, playerCasts);
        break; // Only trigger one combo at a time
      }
    }
  }

  /// Check if player casts can form a specific combo
  bool _canFormCombo(List<ElementCastRecord> casts, ElementalCombo combo) {
    final requiredElements = List<ElementType>.from(combo.requiredElements);
    
    for (final cast in casts.take(4)) { // Check last 4 casts
      if (requiredElements.contains(cast.element)) {
        requiredElements.remove(cast.element);
        if (requiredElements.isEmpty) return true;
      }
    }
    
    return false;
  }

  /// Trigger a combo effect
  void _triggerCombo(String playerId, ElementalCombo combo, List<ElementCastRecord> casts) {
    // Add to active combos
    _activeCombosByPlayer.putIfAbsent(playerId, () => []);
    _activeCombosByPlayer[playerId]!.add(combo);

    // Remove the casts used for this combo
    final usedElements = List<ElementType>.from(combo.requiredElements);
    for (final cast in casts) {
      if (usedElements.contains(cast.element)) {
        usedElements.remove(cast.element);
        _recentCasts.remove(cast);
        if (usedElements.isEmpty) break;
      }
    }

    print('🌟 COMBO TRIGGERED: ${combo.name} by $playerId!');
  }

  /// Get all active combos for a player
  List<ElementalCombo> getActiveCombos(String playerId) {
    return _activeCombosByPlayer[playerId] ?? [];
  }

  /// Apply combo effects to spell damage/effects
  SpellResult applyComboEffects(String playerId, ActionCard spell, String targetId, int baseDamage) {
    final activeCombos = getActiveCombos(playerId);
    if (activeCombos.isEmpty) {
      return SpellResult(
        damage: baseDamage,
        effects: [],
        particleEffect: _getSpellParticleType(spell),
        comboTriggered: null,
      );
    }

    // Apply the most recent combo
    final combo = activeCombos.last;
    final enhancedDamage = combo.damageMultiplier > 0 
        ? baseDamage * combo.damageMultiplier 
        : baseDamage;
    
    // Remove the used combo
    _activeCombosByPlayer[playerId]!.remove(combo);

    return SpellResult(
      damage: enhancedDamage,
      effects: combo.effects,
      particleEffect: combo.particleEffect,
      comboTriggered: combo,
    );
  }

  /// Determine element type from spell
  ElementType? _getSpellElement(ActionCard spell) {
    final name = spell.name.toLowerCase();
    
    if (name.contains('fire') || name.contains('burn') || name.contains('flame')) {
      return ElementType.fire;
    }
    if (name.contains('ice') || name.contains('frost') || name.contains('freeze')) {
      return ElementType.ice;
    }
    if (name.contains('lightning') || name.contains('shock') || name.contains('thunder')) {
      return ElementType.lightning;
    }
    if (name.contains('water') || name.contains('wave') || name.contains('flood')) {
      return ElementType.water;
    }
    if (name.contains('earth') || name.contains('stone') || name.contains('rock')) {
      return ElementType.earth;
    }
    if (name.contains('air') || name.contains('wind') || name.contains('storm')) {
      return ElementType.air;
    }
    if (name.contains('light') || name.contains('holy') || name.contains('divine')) {
      return ElementType.light;
    }
    if (name.contains('shadow') || name.contains('dark') || name.contains('curse')) {
      return ElementType.shadow;
    }
    if (name.contains('arcane') || name.contains('magic') || name.contains('dispel')) {
      return ElementType.arcane;
    }
    if (name.contains('nature') || name.contains('heal') || name.contains('growth')) {
      return ElementType.nature;
    }
    
    return null; // Non-elemental spell
  }

  /// Get particle type for spell (fallback method)
  ParticleType _getSpellParticleType(ActionCard spell) {
    final name = spell.name.toLowerCase();
    if (name.contains('fire') || name.contains('burn')) return ParticleType.fire;
    if (name.contains('ice') || name.contains('frost')) return ParticleType.ice;
    if (name.contains('lightning') || name.contains('shock')) return ParticleType.lightning;
    if (name.contains('heal')) return ParticleType.heal;
    return ParticleType.arcane;
  }

  /// Clear all combos for a player (on turn end)
  void clearPlayerCombos(String playerId) {
    _activeCombosByPlayer[playerId]?.clear();
    _recentCasts.removeWhere((cast) => cast.playerId == playerId);
  }

  /// Get all available combo descriptions for UI
  List<ElementalCombo> getAllCombos() {
    return List.from(_allCombos);
  }
}

class ElementCastRecord {
  final String playerId;
  final ActionCard spell;
  final ElementType element;
  final String targetId;
  final DateTime timestamp;

  ElementCastRecord({
    required this.playerId,
    required this.spell,
    required this.element,
    required this.targetId,
    required this.timestamp,
  });
}

class SpellResult {
  final int damage;
  final List<String> effects;
  final ParticleType particleEffect;
  final ElementalCombo? comboTriggered;

  SpellResult({
    required this.damage,
    required this.effects,
    required this.particleEffect,
    this.comboTriggered,
  });
} 