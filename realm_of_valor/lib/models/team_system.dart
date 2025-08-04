import 'package:flutter/material.dart';
import 'battle_model.dart';
import '../effects/particle_system.dart';
import 'unified_particle_system.dart';
import 'dart:math' as math;

enum TeamFormation {
  aggressive,
  defensive,
  balanced,
  supportive,
  chaotic,
}

enum ChainReactionType {
  lightningJump,
  fireSpread,
  iceShatter,
  poisonCloud,
  healingWave,
  shadowLeap,
  windSlash,
  earthRumble,
}

class ChainReaction {
  final ChainReactionType type;
  final String name;
  final String description;
  final int maxJumps;
  final double damageDecay;
  final double jumpRange;
  final ParticleType effectType;
  final List<String> triggerSpells;
  final bool requiresLineOfSight;

  const ChainReaction({
    required this.type,
    required this.name,
    required this.description,
    required this.maxJumps,
    required this.damageDecay,
    required this.jumpRange,
    required this.effectType,
    required this.triggerSpells,
    this.requiresLineOfSight = false,
  });
}

class TeamCombo {
  final String id;
  final String name;
  final String description;
  final List<ActionCardType> requiredCardTypes;
  final int requiredPlayers;
  final double damageMultiplier;
  final List<String> effects;
  final ParticleType comboEffect;
  final Duration executionWindow;

  const TeamCombo({
    required this.id,
    required this.name,
    required this.description,
    required this.requiredCardTypes,
    required this.requiredPlayers,
    required this.damageMultiplier,
    required this.effects,
    required this.comboEffect,
    this.executionWindow = const Duration(seconds: 5),
  });
}

class TeamSystem {
  final Map<String, TeamFormation> _teamFormations = {};
  final Map<String, List<String>> _teamMembers = {}; // teamId -> playerIds
  final List<ChainReaction> _chainReactions = [
    ChainReaction(
      type: ChainReactionType.lightningJump,
      name: 'Chain Lightning',
      description: 'Lightning jumps between nearby enemies',
      maxJumps: 4,
      damageDecay: 0.8, // 20% damage reduction per jump
      jumpRange: 100.0,
      effectType: ParticleType.lightning,
      triggerSpells: ['lightning bolt', 'shock', 'thunder', 'chain lightning'],
    ),
    
    ChainReaction(
      type: ChainReactionType.fireSpread,
      name: 'Spreading Flames',
      description: 'Fire spreads to adjacent burning targets',
      maxJumps: 6,
      damageDecay: 0.9, // 10% damage reduction per spread
      jumpRange: 80.0,
      effectType: ParticleType.fire,
      triggerSpells: ['fireball', 'flame strike', 'burning hands', 'inferno'],
    ),
    
    ChainReaction(
      type: ChainReactionType.iceShatter,
      name: 'Ice Shatter',
      description: 'Frozen enemies shatter and damage nearby foes',
      maxJumps: 3,
      damageDecay: 0.7, // 30% damage reduction per shatter
      jumpRange: 120.0,
      effectType: ParticleType.ice,
      triggerSpells: ['ice shard', 'frost bolt', 'blizzard', 'freeze'],
    ),
    
    ChainReaction(
      type: ChainReactionType.poisonCloud,
      name: 'Toxic Cloud',
      description: 'Poison spreads through air to nearby enemies',
      maxJumps: 5,
      damageDecay: 0.85, // 15% damage reduction per spread
      jumpRange: 150.0,
      effectType: ParticleType.poison,
      triggerSpells: ['poison dart', 'toxic cloud', 'acid spray', 'plague'],
    ),
    
    ChainReaction(
      type: ChainReactionType.healingWave,
      name: 'Healing Wave',
      description: 'Healing energy flows between injured allies',
      maxJumps: 4,
      damageDecay: 0.9, // 10% healing reduction per wave
      jumpRange: 200.0,
      effectType: ParticleType.heal,
      triggerSpells: ['heal', 'mass heal', 'regeneration', 'blessing'],
    ),
    
    ChainReaction(
      type: ChainReactionType.shadowLeap,
      name: 'Shadow Leap',
      description: 'Dark energy leaps between enemies in shadows',
      maxJumps: 3,
      damageDecay: 0.75, // 25% damage reduction per leap
      jumpRange: 180.0,
      effectType: ParticleType.shadow,
      triggerSpells: ['shadow bolt', 'darkness', 'drain life', 'curse'],
    ),
  ];

  final List<TeamCombo> _teamCombos = [
    TeamCombo(
      id: 'elemental_storm',
      name: 'Elemental Storm',
      description: 'Fire, Ice, and Lightning combine for devastating area damage',
      requiredCardTypes: [ActionCardType.spell, ActionCardType.spell, ActionCardType.spell],
      requiredPlayers: 3,
      damageMultiplier: 2.5,
      effects: ['area_damage:all', 'stun:2', 'elemental_weakness:3'],
      comboEffect: ParticleType.lightning,
    ),
    
    TeamCombo(
      id: 'coordinated_strike',
      name: 'Coordinated Strike',
      description: 'Multiple physical attacks in perfect synchronization',
      requiredCardTypes: [ActionCardType.physical, ActionCardType.physical],
      requiredPlayers: 2,
      damageMultiplier: 1.8,
      effects: ['ignore_armor', 'knockdown:1'],
      comboEffect: ParticleType.explosion,
    ),
    
    TeamCombo(
      id: 'healing_circle',
      name: 'Healing Circle',
      description: 'Combined healing magic creates a restoration aura',
      requiredCardTypes: [ActionCardType.heal, ActionCardType.heal],
      requiredPlayers: 2,
      damageMultiplier: 2.0, // Applied to healing
      effects: ['remove_all_debuffs', 'magic_resistance:3'],
      comboEffect: ParticleType.heal,
    ),
    
    TeamCombo(
      id: 'tactical_maneuver',
      name: 'Tactical Maneuver',
      description: 'Support and damage cards combine for strategic advantage',
      requiredCardTypes: [ActionCardType.support, ActionCardType.damage],
      requiredPlayers: 2,
      damageMultiplier: 1.6,
      effects: ['extra_turn', 'damage_boost:2'],
      comboEffect: ParticleType.holy,
    ),
  ];

  /// Check for chain reactions when a spell is cast
  List<ChainReactionResult> checkChainReactions(
    String casterId,
    ActionCard spell,
    String primaryTargetId,
    List<BattlePlayer> allPlayers,
  ) {
    final results = <ChainReactionResult>[];
    
    // Find matching chain reactions
    for (final reaction in _chainReactions) {
      if (_canTriggerChainReaction(spell, reaction)) {
        final chainResult = _executeChainReaction(
          reaction,
          casterId,
          primaryTargetId,
          allPlayers,
          spell,
        );
        if (chainResult.affectedTargets.isNotEmpty) {
          results.add(chainResult);
        }
      }
    }
    
    return results;
  }

  /// Check if a spell can trigger a specific chain reaction
  bool _canTriggerChainReaction(ActionCard spell, ChainReaction reaction) {
    final spellName = spell.name.toLowerCase();
    return reaction.triggerSpells.any((trigger) => spellName.contains(trigger));
  }

  /// Execute a chain reaction
  ChainReactionResult _executeChainReaction(
    ChainReaction reaction,
    String casterId,
    String primaryTargetId,
    List<BattlePlayer> allPlayers,
    ActionCard sourceSpell,
  ) {
    final affectedTargets = <ChainTarget>[];
    final visited = <String>{primaryTargetId};
    String currentTargetId = primaryTargetId;
    
    // Extract base damage from spell
    int baseDamage = _extractDamageFromSpell(sourceSpell);
    double currentDamage = baseDamage.toDouble();
    
    for (int jump = 0; jump < reaction.maxJumps; jump++) {
      // Find next target within range
      final nextTarget = _findNearestChainTarget(
        currentTargetId,
        allPlayers,
        visited,
        reaction,
        casterId,
      );
      
      if (nextTarget == null) break;
      
      // Calculate damage for this jump
      currentDamage *= reaction.damageDecay;
      final jumpDamage = currentDamage.round();
      
      affectedTargets.add(ChainTarget(
        playerId: nextTarget,
        damage: jumpDamage,
        jumpNumber: jump + 1,
        effectType: reaction.effectType,
      ));
      
      visited.add(nextTarget);
      currentTargetId = nextTarget;
      
      // Stop if damage becomes negligible
      if (jumpDamage < 1) break;
    }
    
    return ChainReactionResult(
      reaction: reaction,
      sourceSpell: sourceSpell,
      casterId: casterId,
      affectedTargets: affectedTargets,
      totalJumps: affectedTargets.length,
    );
  }

  /// Find the nearest valid target for chain reaction
  String? _findNearestChainTarget(
    String fromTargetId,
    List<BattlePlayer> allPlayers,
    Set<String> visited,
    ChainReaction reaction,
    String casterId,
  ) {
    // Simple distance-based targeting (in a real game, you'd use actual positions)
    final validTargets = allPlayers.where((player) =>
      !visited.contains(player.id) &&
      player.currentHealth > 0 &&
      _isValidChainTarget(player.id, casterId, reaction)
    ).toList();
    
    if (validTargets.isEmpty) return null;
    
    // For now, return a random valid target
    // In a real implementation, you'd calculate actual distances
    final random = math.Random();
    return validTargets[random.nextInt(validTargets.length)].id;
  }

  /// Check if a player is a valid target for chain reaction
  bool _isValidChainTarget(String playerId, String casterId, ChainReaction reaction) {
    // Healing reactions target allies, damage reactions target enemies
    final isHealingReaction = reaction.type == ChainReactionType.healingWave;
    final sameTeam = areTeammates(playerId, casterId);
    
    return isHealingReaction ? sameTeam : !sameTeam;
  }

  /// Extract damage value from spell effect string
  int _extractDamageFromSpell(ActionCard spell) {
    final effects = spell.effect.split(',');
    for (final effect in effects) {
      if (effect.trim().startsWith('damage:')) {
        return int.tryParse(effect.split(':')[1]) ?? 0;
      }
    }
    return 0;
  }

  /// Check for team combos during coordinated actions
  List<TeamComboResult> checkTeamCombos(
    List<TeamAction> pendingActions,
    Duration timeWindow,
  ) {
    final results = <TeamComboResult>[];
    
    for (final combo in _teamCombos) {
      final comboResult = _checkSpecificCombo(combo, pendingActions, timeWindow);
      if (comboResult != null) {
        results.add(comboResult);
      }
    }
    
    return results;
  }

  /// Check if pending actions can form a specific team combo
  TeamComboResult? _checkSpecificCombo(
    TeamCombo combo,
    List<TeamAction> actions,
    Duration timeWindow,
  ) {
    if (actions.length < combo.requiredPlayers) return null;
    
    // Group actions by time window
    final recentActions = actions.where((action) =>
      DateTime.now().difference(action.timestamp) <= timeWindow
    ).toList();
    
    if (recentActions.length < combo.requiredPlayers) return null;
    
    // Check if card types match combo requirements
    final actionTypes = recentActions.map((a) => a.card.type).toList();
    final requiredTypes = List.from(combo.requiredCardTypes);
    
    for (final type in actionTypes) {
      if (requiredTypes.contains(type)) {
        requiredTypes.remove(type);
      }
    }
    
    if (requiredTypes.isNotEmpty) return null;
    
    // Combo conditions met!
    return TeamComboResult(
      combo: combo,
      participatingActions: recentActions.take(combo.requiredPlayers).toList(),
      timestamp: DateTime.now(),
    );
  }

  /// Set team formation for better coordination
  void setTeamFormation(String teamId, TeamFormation formation) {
    _teamFormations[teamId] = formation;
  }

  /// Get formation bonuses
  Map<String, double> getFormationBonuses(String teamId) {
    final formation = _teamFormations[teamId] ?? TeamFormation.balanced;
    
    switch (formation) {
      case TeamFormation.aggressive:
        return {'damage': 1.2, 'critical_chance': 1.15, 'defense': 0.9};
      case TeamFormation.defensive:
        return {'damage': 0.9, 'defense': 1.3, 'healing': 1.1};
      case TeamFormation.balanced:
        return {'damage': 1.0, 'defense': 1.0, 'healing': 1.0, 'mana_regen': 1.1};
      case TeamFormation.supportive:
        return {'healing': 1.4, 'mana_regen': 1.2, 'damage': 0.85};
      case TeamFormation.chaotic:
        return {'critical_chance': 1.3, 'spell_power': 1.2, 'consistency': 0.8};
    }
  }

  /// Check if two players are teammates
  bool areTeammates(String playerId1, String playerId2) {
    // Simple implementation - in a real game you'd have proper team data
    return playerId1.startsWith('ally') && playerId2.startsWith('ally') ||
           playerId1.startsWith('enemy') && playerId2.startsWith('enemy');
  }

  /// Get all available chain reactions for UI display
  List<ChainReaction> getAllChainReactions() {
    return List.from(_chainReactions);
  }

  /// Get all team combos for UI display
  List<TeamCombo> getAllTeamCombos() {
    return List.from(_teamCombos);
  }
}

class ChainTarget {
  final String playerId;
  final int damage;
  final int jumpNumber;
  final ParticleType effectType;

  ChainTarget({
    required this.playerId,
    required this.damage,
    required this.jumpNumber,
    required this.effectType,
  });
}

class ChainReactionResult {
  final ChainReaction reaction;
  final ActionCard sourceSpell;
  final String casterId;
  final List<ChainTarget> affectedTargets;
  final int totalJumps;

  ChainReactionResult({
    required this.reaction,
    required this.sourceSpell,
    required this.casterId,
    required this.affectedTargets,
    required this.totalJumps,
  });
}

class TeamAction {
  final String playerId;
  final ActionCard card;
  final String targetId;
  final DateTime timestamp;

  TeamAction({
    required this.playerId,
    required this.card,
    required this.targetId,
    required this.timestamp,
  });
}

class TeamComboResult {
  final TeamCombo combo;
  final List<TeamAction> participatingActions;
  final DateTime timestamp;

  TeamComboResult({
    required this.combo,
    required this.participatingActions,
    required this.timestamp,
  });
} 