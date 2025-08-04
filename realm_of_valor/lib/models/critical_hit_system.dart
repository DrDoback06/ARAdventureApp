import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'battle_model.dart';
import 'card_model.dart';
import '../effects/particle_system.dart';
import 'unified_particle_system.dart';

enum CriticalType {
  normal,
  critical,
  superCritical,
  devastatingCritical,
}

class CriticalHit {
  final CriticalType type;
  final double damageMultiplier;
  final String effectName;
  final Color effectColor;
  final ParticleType particleEffect;
  final Duration animationDuration;
  final bool screenShake;
  final String soundEffect;

  const CriticalHit({
    required this.type,
    required this.damageMultiplier,
    required this.effectName,
    required this.effectColor,
    required this.particleEffect,
    required this.animationDuration,
    this.screenShake = false,
    required this.soundEffect,
  });
}

class CriticalHitSystem {
  static const List<CriticalHit> _criticalTypes = [
    CriticalHit(
      type: CriticalType.critical,
      damageMultiplier: 1.5,
      effectName: 'Critical Hit!',
      effectColor: Colors.yellow,
      particleEffect: ParticleType.sparkle,
      animationDuration: Duration(milliseconds: 800),
      soundEffect: 'critical_hit',
    ),
    CriticalHit(
      type: CriticalType.superCritical,
      damageMultiplier: 2.0,
      effectName: 'SUPER CRITICAL!',
      effectColor: Colors.orange,
      particleEffect: ParticleType.explosion,
      animationDuration: Duration(milliseconds: 1200),
      screenShake: true,
      soundEffect: 'super_critical',
    ),
    CriticalHit(
      type: CriticalType.devastatingCritical,
      damageMultiplier: 3.0,
      effectName: 'DEVASTATING CRITICAL!!',
      effectColor: Colors.red,
      particleEffect: ParticleType.explosion,
      animationDuration: Duration(milliseconds: 1500),
      screenShake: true,
      soundEffect: 'devastating_critical',
    ),
  ];

  final math.Random _random = math.Random();
  final Map<String, PlayerCriticalStats> _playerStats = {};

  /// Calculate critical hit result for an attack or spell
  CriticalHitResult calculateCritical(String playerId, ActionCard card, int baseDamage) {
    final stats = _getPlayerStats(playerId);
    final baseCritChance = _calculateBaseCritChance(card, stats);
    final roll = _random.nextDouble();

    // Determine critical type based on thresholds
    CriticalType critType = CriticalType.normal;
    double critChance = baseCritChance;

    // Devastating Critical (0.5% base chance)
    if (roll <= critChance * 0.005) {
      critType = CriticalType.devastatingCritical;
    }
    // Super Critical (2% base chance)
    else if (roll <= critChance * 0.02) {
      critType = CriticalType.superCritical;
    }
    // Regular Critical (15% base chance)
    else if (roll <= critChance * 0.15) {
      critType = CriticalType.critical;
    }

    if (critType != CriticalType.normal) {
      final critData = _criticalTypes.firstWhere((c) => c.type == critType);
      final finalDamage = (baseDamage * critData.damageMultiplier).round();
      
      // Update player stats
      stats.totalCrits++;
      stats.critStreak++;
      stats.highestCrit = math.max(stats.highestCrit, finalDamage);
      
      return CriticalHitResult(
        isCritical: true,
        criticalType: critType,
        originalDamage: baseDamage,
        finalDamage: finalDamage,
        criticalData: critData,
        criticalMessage: _generateCriticalMessage(critType, finalDamage),
      );
    } else {
      // Reset crit streak on non-critical
      stats.critStreak = 0;
      
      return CriticalHitResult(
        isCritical: false,
        criticalType: CriticalType.normal,
        originalDamage: baseDamage,
        finalDamage: baseDamage,
        criticalData: null,
        criticalMessage: '',
      );
    }
  }

  /// Calculate base critical hit chance
  double _calculateBaseCritChance(ActionCard card, PlayerCriticalStats stats) {
    double chance = 0.15; // Base 15% crit chance

    // Card type modifiers
    switch (card.type) {
      case ActionCardType.physical:
        chance += 0.05; // Physical attacks have +5% crit chance
        break;
      case ActionCardType.spell:
        chance += 0.03; // Spells have +3% crit chance
        break;
      case ActionCardType.damage:
        chance += 0.08; // Damage skills have +8% crit chance
        break;
      default:
        break;
    }

    // Card rarity modifiers
    switch (card.rarity) {
      case CardRarity.common:
        // No modifier
        break;
      case CardRarity.uncommon:
        chance += 0.02;
        break;
      case CardRarity.rare:
        chance += 0.05;
        break;
      case CardRarity.epic:
        chance += 0.08;
        break;
      case CardRarity.legendary:
        chance += 0.12;
        break;
      case CardRarity.mythic:
      case CardRarity.holographic:
      case CardRarity.firstEdition:
      case CardRarity.limitedEdition:
        chance += 0.15; // Ultra-rare cards get maximum bonus
        break;
    }

    // High-cost cards have better crit chance
    if (card.cost >= 5) {
      chance += 0.05;
    } else if (card.cost >= 3) {
      chance += 0.02;
    }

    // Critical streak bonus (luck streaks)
    if (stats.critStreak >= 3) {
      chance += 0.03; // +3% after 3 non-crits
    } else if (stats.critStreak >= 5) {
      chance += 0.05; // +5% after 5 non-crits
    }

    // Specific card name bonuses
    final cardName = card.name.toLowerCase();
    if (cardName.contains('precise') || cardName.contains('aimed')) {
      chance += 0.1; // Precision cards get +10%
    } else if (cardName.contains('lucky') || cardName.contains('fortune')) {
      chance += 0.15; // Lucky cards get +15%
    } else if (cardName.contains('devastating') || cardName.contains('crushing')) {
      chance += 0.08; // Devastating cards get +8%
    }

    return math.min(chance, 0.95); // Cap at 95% max crit chance
  }

  /// Get or create player critical stats
  PlayerCriticalStats _getPlayerStats(String playerId) {
    return _playerStats.putIfAbsent(playerId, () => PlayerCriticalStats());
  }

  /// Generate exciting critical hit messages
  String _generateCriticalMessage(CriticalType type, int damage) {
    final messages = {
      CriticalType.critical: [
        'A well-placed strike!',
        'Right on target!',
        'Excellent technique!',
        'A precise blow!',
        'Perfect timing!',
      ],
      CriticalType.superCritical: [
        'An incredible strike!',
        'MAXIMUM POWER!',
        'Extraordinary hit!',
        'Legendary technique!',
        'Overwhelming force!',
      ],
      CriticalType.devastatingCritical: [
        'ULTIMATE DESTRUCTION!',
        'WORLD-SHATTERING BLOW!',
        'APOCALYPTIC STRIKE!',
        'REALITY-BREAKING HIT!',
        'COSMIC DEVASTATION!',
      ],
    };

    final typeMessages = messages[type] ?? ['Critical Hit!'];
    final randomMessage = typeMessages[_random.nextInt(typeMessages.length)];
    
    return '$randomMessage ($damage damage)';
  }

  /// Get player's critical hit statistics
  PlayerCriticalStats getPlayerStats(String playerId) {
    return _getPlayerStats(playerId);
  }

  /// Reset player stats (for new battles)
  void resetPlayerStats(String playerId) {
    _playerStats[playerId] = PlayerCriticalStats();
  }

  /// Get all critical hit types for UI display
  List<CriticalHit> getAllCriticalTypes() {
    return List.from(_criticalTypes);
  }

  /// Check if card has critical hit potential
  bool hasCriticalPotential(ActionCard card) {
    return card.type == ActionCardType.physical ||
           card.type == ActionCardType.spell ||
           card.type == ActionCardType.damage;
  }

  /// Get critical chance display for UI
  String getCriticalChanceDisplay(String playerId, ActionCard card) {
    final stats = _getPlayerStats(playerId);
    final chance = _calculateBaseCritChance(card, stats);
    return '${(chance * 100).toStringAsFixed(1)}%';
  }
}

class PlayerCriticalStats {
  int totalCrits = 0;
  int critStreak = 0; // Consecutive non-crits (for luck bonus)
  int highestCrit = 0;
  int totalAttacks = 0;

  double get criticalRate => totalAttacks > 0 ? totalCrits / totalAttacks : 0.0;
  
  String get criticalRateDisplay => '${(criticalRate * 100).toStringAsFixed(1)}%';
}

class CriticalHitResult {
  final bool isCritical;
  final CriticalType criticalType;
  final int originalDamage;
  final int finalDamage;
  final CriticalHit? criticalData;
  final String criticalMessage;

  CriticalHitResult({
    required this.isCritical,
    required this.criticalType,
    required this.originalDamage,
    required this.finalDamage,
    required this.criticalData,
    required this.criticalMessage,
  });

  int get bonusDamage => finalDamage - originalDamage;
} 