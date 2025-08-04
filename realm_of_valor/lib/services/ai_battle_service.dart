import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'dart:async';
import '../models/battle_model.dart';
import '../models/card_model.dart';
import '../models/character_model.dart';
import '../providers/battle_controller.dart';

enum AIDifficulty {
  easy,
  medium,
  hard,
  expert,
  legendary,
}

enum AIStrategy {
  aggressive,    // Focus on damage and attacks
  defensive,     // Focus on healing and protection
  balanced,      // Mix of offense and defense
  tactical,      // Focus on combos and status effects
  random,        // Random actions
}

class AIPlayer {
  final String id;
  final String name;
  final GameCharacter character;
  final AIDifficulty difficulty;
  final AIStrategy strategy;
  final List<ActionCard> actionDeck;
  final List<ActionCard> hand;
  final int currentHealth;
  final int maxHealth;
  final int currentMana;
  final int maxMana;
  final Map<String, int> statusEffects;

  AIPlayer({
    required this.id,
    required this.name,
    required this.character,
    required this.difficulty,
    required this.strategy,
    required this.actionDeck,
    required this.hand,
    required this.currentHealth,
    required this.maxHealth,
    required this.currentMana,
    required this.maxMana,
    required this.statusEffects,
  });

  AIPlayer copyWith({
    String? id,
    String? name,
    GameCharacter? character,
    AIDifficulty? difficulty,
    AIStrategy? strategy,
    List<ActionCard>? actionDeck,
    List<ActionCard>? hand,
    int? currentHealth,
    int? maxHealth,
    int? currentMana,
    int? maxMana,
    Map<String, int>? statusEffects,
  }) {
    return AIPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      character: character ?? this.character,
      difficulty: difficulty ?? this.difficulty,
      strategy: strategy ?? this.strategy,
      actionDeck: actionDeck ?? this.actionDeck,
      hand: hand ?? this.hand,
      currentHealth: currentHealth ?? this.currentHealth,
      maxMana: maxMana ?? this.maxMana,
      currentMana: currentMana ?? this.currentMana,
      maxHealth: maxHealth ?? this.maxHealth,
      statusEffects: statusEffects ?? this.statusEffects,
    );
  }
}

class AIBattleService extends ChangeNotifier {
  static AIBattleService? _instance;
  static AIBattleService get instance => _instance ??= AIBattleService._();
  
  AIBattleService._();

  // AI Decision Making
  AIDecision? _lastDecision;
  Timer? _aiThinkingTimer;
  bool _isAITurn = false;

  // AI Difficulty Settings
  final Map<AIDifficulty, AIDifficultySettings> _difficultySettings = {
    AIDifficulty.easy: AIDifficultySettings(
      thinkingTime: Duration(milliseconds: 500),
      accuracy: 0.6,
      aggressiveness: 0.3,
      tacticalAwareness: 0.2,
    ),
    AIDifficulty.medium: AIDifficultySettings(
      thinkingTime: Duration(milliseconds: 1000),
      accuracy: 0.75,
      aggressiveness: 0.5,
      tacticalAwareness: 0.4,
    ),
    AIDifficulty.hard: AIDifficultySettings(
      thinkingTime: Duration(milliseconds: 1500),
      accuracy: 0.85,
      aggressiveness: 0.7,
      tacticalAwareness: 0.6,
    ),
    AIDifficulty.expert: AIDifficultySettings(
      thinkingTime: Duration(milliseconds: 2000),
      accuracy: 0.95,
      aggressiveness: 0.9,
      tacticalAwareness: 0.8,
    ),
  };

  AIDecision? get lastDecision => _lastDecision;
  bool get isAITurn => _isAITurn;

  void initialize() {
    debugPrint('AI Battle Service initialized');
  }

  /// Generate AI opponent with specified difficulty
  AIPlayer generateAIOpponent({
    required String name,
    required AIDifficulty difficulty,
    required AIStrategy strategy,
    required GameCharacter character,
  }) {
    // Generate AI deck based on strategy
    final actionDeck = _generateAIDeck(strategy, difficulty);
    
    return AIPlayer(
      id: 'ai_${name.toLowerCase().replaceAll(' ', '_')}',
      name: name,
      character: character,
      difficulty: difficulty,
      strategy: strategy,
      actionDeck: actionDeck,
      hand: [],
      currentHealth: character.maxHealth,
      maxHealth: character.maxHealth,
      currentMana: character.maxMana,
      maxMana: character.maxMana,
      statusEffects: {},
    );
  }

  /// Generate AI deck based on strategy
  List<ActionCard> _generateAIDeck(AIStrategy strategy, AIDifficulty difficulty) {
    final deck = <ActionCard>[];
    final random = math.Random();
    
    switch (strategy) {
      case AIStrategy.aggressive:
        // Focus on attack cards
        for (int i = 0; i < 15; i++) {
          deck.add(_generateAttackCard(difficulty));
        }
        for (int i = 0; i < 5; i++) {
          deck.add(_generateSkillCard(difficulty));
        }
        break;
        
      case AIStrategy.defensive:
        // Focus on healing and protection
        for (int i = 0; i < 10; i++) {
          deck.add(_generateHealCard(difficulty));
        }
        for (int i = 0; i < 10; i++) {
          deck.add(_generateDefenseCard(difficulty));
        }
        break;
        
      case AIStrategy.balanced:
        // Mix of all card types
        for (int i = 0; i < 8; i++) {
          deck.add(_generateAttackCard(difficulty));
        }
        for (int i = 0; i < 6; i++) {
          deck.add(_generateHealCard(difficulty));
        }
        for (int i = 0; i < 6; i++) {
          deck.add(_generateSkillCard(difficulty));
        }
        break;
        
      case AIStrategy.tactical:
        // Focus on status effects and combos
        for (int i = 0; i < 10; i++) {
          deck.add(_generateStatusCard(difficulty));
        }
        for (int i = 0; i < 10; i++) {
          deck.add(_generateComboCard(difficulty));
        }
        break;
        
      case AIStrategy.random:
        // Random mix
        for (int i = 0; i < 20; i++) {
          final cardTypes = [
            () => _generateAttackCard(difficulty),
            () => _generateHealCard(difficulty),
            () => _generateSkillCard(difficulty),
            () => _generateStatusCard(difficulty),
          ];
          deck.add(cardTypes[random.nextInt(cardTypes.length)]());
        }
        break;
    }
    
    return deck;
  }

  /// Generate attack card based on difficulty
  ActionCard _generateAttackCard(AIDifficulty difficulty) {
    final baseDamage = _getDifficultyMultiplier(difficulty) * 15;
    final cost = (baseDamage * 0.3).round();
    
    return ActionCard(
      name: 'AI Attack',
      description: 'A powerful attack',
      type: ActionCardType.damage,
      effect: 'damage:${baseDamage.round()}',
      cost: cost,
    );
  }

  /// Generate heal card based on difficulty
  ActionCard _generateHealCard(AIDifficulty difficulty) {
    final baseHealing = _getDifficultyMultiplier(difficulty) * 20;
    final cost = (baseHealing * 0.25).round();
    
    return ActionCard(
      name: 'AI Heal',
      description: 'Restore health',
      type: ActionCardType.heal,
      effect: 'heal:${baseHealing.round()}',
      cost: cost,
    );
  }

  /// Generate skill card based on difficulty
  ActionCard _generateSkillCard(AIDifficulty difficulty) {
    final baseEffect = _getDifficultyMultiplier(difficulty) * 10;
    final cost = (baseEffect * 0.4).round();
    
    return ActionCard(
      name: 'AI Skill',
      description: 'A tactical skill',
      type: ActionCardType.buff,
      effect: 'buff:${baseEffect.round()}',
      cost: cost,
    );
  }

  /// Generate defense card based on difficulty
  ActionCard _generateDefenseCard(AIDifficulty difficulty) {
    final baseDefense = _getDifficultyMultiplier(difficulty) * 12;
    final cost = (baseDefense * 0.35).round();
    
    return ActionCard(
      name: 'AI Defense',
      description: 'Defensive skill',
      type: ActionCardType.buff,
      effect: 'defense:${baseDefense.round()}',
      cost: cost,
    );
  }

  /// Generate status effect card based on difficulty
  ActionCard _generateStatusCard(AIDifficulty difficulty) {
    final baseEffect = _getDifficultyMultiplier(difficulty) * 8;
    final cost = (baseEffect * 0.5).round();
    
    return ActionCard(
      name: 'AI Status',
      description: 'Apply status effect',
      type: ActionCardType.debuff,
      effect: 'poison:${baseEffect.round()}',
      cost: cost,
    );
  }

  /// Generate combo card based on difficulty
  ActionCard _generateComboCard(AIDifficulty difficulty) {
    final baseEffect = _getDifficultyMultiplier(difficulty) * 12;
    final cost = (baseEffect * 0.6).round();
    
    return ActionCard(
      name: 'AI Combo',
      description: 'A combo attack',
      type: ActionCardType.damage,
      effect: 'combo:${baseEffect.round()}',
      cost: cost,
    );
  }

  /// Get difficulty multiplier
  double _getDifficultyMultiplier(AIDifficulty difficulty) {
    switch (difficulty) {
      case AIDifficulty.easy:
        return 0.8;
      case AIDifficulty.medium:
        return 1.0;
      case AIDifficulty.hard:
        return 1.3;
      case AIDifficulty.expert:
        return 1.6;
      case AIDifficulty.legendary:
        return 2.0;
    }
  }

  /// Make AI decision for a turn
  Future<AIDecision> makeDecision({
    required AIPlayer aiPlayer,
    required List<BattlePlayer> allPlayers,
    required BattlePhase currentPhase,
    required int turnTimeRemaining,
  }) async {
    _isAITurn = true;
    notifyListeners();
    
    final settings = _difficultySettings[aiPlayer.difficulty]!;
    
    // Simulate thinking time
    await Future.delayed(settings.thinkingTime);
    
    final decision = _calculateDecision(
      aiPlayer: aiPlayer,
      allPlayers: allPlayers,
      currentPhase: currentPhase,
      settings: settings,
    );
    
    _lastDecision = decision;
    _isAITurn = false;
    notifyListeners();
    
    return decision;
  }

  /// Calculate AI decision based on strategy and difficulty
  AIDecision _calculateDecision({
    required AIPlayer aiPlayer,
    required List<BattlePlayer> allPlayers,
    required BattlePhase currentPhase,
    required AIDifficultySettings settings,
  }) {
    final random = math.Random();
    final enemies = allPlayers.where((p) => p.id != aiPlayer.id).toList();
    final allies = allPlayers.where((p) => p.id == aiPlayer.id).toList();
    
    // Check if AI should heal
    final shouldHeal = _shouldHeal(aiPlayer, settings);
    if (shouldHeal && aiPlayer.hand.any((card) => card.type == ActionCardType.heal)) {
      final healCard = aiPlayer.hand.firstWhere((card) => card.type == ActionCardType.heal);
      return AIDecision.playCard(
        card: healCard,
        targetId: aiPlayer.id,
        reason: 'Healing self',
      );
    }
    
    // Check if AI should attack
    if (enemies.isNotEmpty && aiPlayer.hand.any((card) => card.type == ActionCardType.damage)) {
      final target = _selectBestTarget(enemies, aiPlayer.strategy);
      final attackCard = _selectBestAttackCard(aiPlayer.hand, target, settings);
      
      if (attackCard != null) {
        return AIDecision.playCard(
          card: attackCard,
          targetId: target.id,
          reason: 'Attacking enemy',
        );
      }
    }
    
    // Check if AI should use skill
    if (aiPlayer.hand.any((card) => card.type == ActionCardType.buff || card.type == ActionCardType.debuff)) {
      final skillCard = _selectBestSkillCard(aiPlayer.hand, aiPlayer.strategy);
      final target = _selectSkillTarget(skillCard, enemies, allies, aiPlayer.strategy);
      
      if (skillCard != null && target != null) {
        return AIDecision.playCard(
          card: skillCard,
          targetId: target.id,
          reason: 'Using skill',
        );
      }
    }
    
    // Default: end turn
    return AIDecision.endTurn(reason: 'No valid actions');
  }

  /// Determine if AI should heal
  bool _shouldHeal(AIPlayer aiPlayer, AIDifficultySettings settings) {
    final healthPercentage = aiPlayer.currentHealth / aiPlayer.maxHealth;
    final random = math.Random();
    
    // More likely to heal at lower health
    if (healthPercentage < 0.3) {
      return random.nextDouble() < 0.9;
    } else if (healthPercentage < 0.5) {
      return random.nextDouble() < 0.6;
    } else if (healthPercentage < 0.7) {
      return random.nextDouble() < 0.3;
    }
    
    return false;
  }

  /// Select best target for attack
  BattlePlayer _selectBestTarget(List<BattlePlayer> enemies, AIStrategy strategy) {
    switch (strategy) {
      case AIStrategy.aggressive:
        // Target lowest health enemy
        return enemies.reduce((a, b) => a.currentHealth < b.currentHealth ? a : b);
      case AIStrategy.tactical:
        // Target highest threat (highest attack)
        return enemies.reduce((a, b) => a.character.attackRating > b.character.attackRating ? a : b);
      case AIStrategy.defensive:
        // Target weakest enemy
        return enemies.reduce((a, b) => a.character.defense < b.character.defense ? a : b);
      default:
        // Random target
        return enemies[math.Random().nextInt(enemies.length)];
    }
  }

  /// Select best attack card
  ActionCard? _selectBestAttackCard(List<ActionCard> hand, BattlePlayer target, AIDifficultySettings settings) {
    final attackCards = hand.where((card) => card.type == ActionCardType.damage).toList();
    if (attackCards.isEmpty) return null;
    
    // Sort by effect value (damage)
    attackCards.sort((a, b) {
      final aDamage = _extractDamageFromEffect(a.effect);
      final bDamage = _extractDamageFromEffect(b.effect);
      return bDamage.compareTo(aDamage);
    });
    
    // Apply accuracy check
    final random = math.Random();
    if (random.nextDouble() > settings.accuracy) {
      // Miss - return random card
      return attackCards[random.nextInt(attackCards.length)];
    }
    
    return attackCards.first;
  }

  /// Extract damage value from effect string
  int _extractDamageFromEffect(String effect) {
    if (effect.startsWith('damage:')) {
      return int.tryParse(effect.split(':')[1]) ?? 0;
    }
    return 0;
  }

  /// Select best skill card
  ActionCard? _selectBestSkillCard(List<ActionCard> hand, AIStrategy strategy) {
    final skillCards = hand.where((card) => 
      card.type == ActionCardType.buff || 
      card.type == ActionCardType.debuff
    ).toList();
    if (skillCards.isEmpty) return null;
    
    switch (strategy) {
      case AIStrategy.tactical:
        // Prefer debuff cards
        final debuffCards = skillCards.where((card) => card.type == ActionCardType.debuff).toList();
        return debuffCards.isNotEmpty ? debuffCards.first : skillCards.first;
      case AIStrategy.defensive:
        // Prefer buff cards
        final buffCards = skillCards.where((card) => card.type == ActionCardType.buff).toList();
        return buffCards.isNotEmpty ? buffCards.first : skillCards.first;
      default:
        return skillCards.first;
    }
  }

  /// Select target for skill
  BattlePlayer? _selectSkillTarget(ActionCard? skillCard, List<BattlePlayer> enemies, List<BattlePlayer> allies, AIStrategy strategy) {
    if (skillCard == null) return null;
    
    // If it's a healing skill, target self or ally
    if (skillCard.type == ActionCardType.heal) {
      return allies.isNotEmpty ? allies.first : null;
    }
    
    // If it's a damage skill, target enemy
    if (skillCard.type == ActionCardType.damage && enemies.isNotEmpty) {
      return enemies.first;
    }
    
    // If it's a debuff, target enemy
    if (skillCard.type == ActionCardType.debuff && enemies.isNotEmpty) {
      return enemies.first;
    }
    
    // If it's a buff, target self or ally
    if (skillCard.type == ActionCardType.buff) {
      return allies.isNotEmpty ? allies.first : null;
    }
    
    return null;
  }

  @override
  void dispose() {
    _aiThinkingTimer?.cancel();
    super.dispose();
  }
}

/// AI Decision data class
class AIDecision {
  final AIDecisionType type;
  final ActionCard? card;
  final String? targetId;
  final String reason;

  AIDecision({
    required this.type,
    this.card,
    this.targetId,
    required this.reason,
  });

  factory AIDecision.playCard({
    required ActionCard card,
    required String targetId,
    required String reason,
  }) {
    return AIDecision(
      type: AIDecisionType.playCard,
      card: card,
      targetId: targetId,
      reason: reason,
    );
  }

  factory AIDecision.endTurn({required String reason}) {
    return AIDecision(
      type: AIDecisionType.endTurn,
      reason: reason,
    );
  }

  factory AIDecision.attack({
    required String targetId,
    required String reason,
  }) {
    return AIDecision(
      type: AIDecisionType.attack,
      targetId: targetId,
      reason: reason,
    );
  }
}

enum AIDecisionType {
  playCard,
  endTurn,
  attack,
}

/// AI Difficulty Settings
class AIDifficultySettings {
  final Duration thinkingTime;
  final double accuracy;
  final double aggressiveness;
  final double tacticalAwareness;

  AIDifficultySettings({
    required this.thinkingTime,
    required this.accuracy,
    required this.aggressiveness,
    required this.tacticalAwareness,
  });
} 