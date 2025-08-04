import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/character_model.dart';
import '../models/card_model.dart';
import '../models/battle_model.dart';
import '../providers/character_provider.dart';

enum RewardType {
  experience,
  gold,
  cards,
  equipment,
  skills,
  achievements,
  titles,
  currency,
}

enum BattlePerformance {
  poor,
  average,
  good,
  excellent,
  legendary,
}

class BattleReward {
  final RewardType type;
  final int amount;
  final String? itemId;
  final String? description;
  final Color? color;

  BattleReward({
    required this.type,
    required this.amount,
    this.itemId,
    this.description,
    this.color,
  });
}

class BattleRewardsService extends ChangeNotifier {
  static BattleRewardsService? _instance;
  static BattleRewardsService get instance => _instance ??= BattleRewardsService._();

  BattleRewardsService._();

  // Performance multipliers for different battle outcomes
  final Map<BattlePerformance, double> _performanceMultipliers = {
    BattlePerformance.poor: 0.5,
    BattlePerformance.average: 1.0,
    BattlePerformance.good: 1.5,
    BattlePerformance.excellent: 2.0,
    BattlePerformance.legendary: 3.0,
  };

  // Special rewards for different performance levels
  final Map<BattlePerformance, List<BattleReward>> _specialRewards = {
    BattlePerformance.poor: [
      BattleReward(
        type: RewardType.experience,
        amount: 10,
        description: 'Consolation XP',
        color: Colors.grey,
      ),
    ],
    BattlePerformance.average: [
      BattleReward(
        type: RewardType.experience,
        amount: 25,
        description: 'Standard XP',
        color: Colors.white,
      ),
      BattleReward(
        type: RewardType.gold,
        amount: 15,
        description: 'Standard Gold',
        color: Colors.yellow,
      ),
    ],
    BattlePerformance.good: [
      BattleReward(
        type: RewardType.experience,
        amount: 50,
        description: 'Good Performance XP',
        color: Colors.green,
      ),
      BattleReward(
        type: RewardType.gold,
        amount: 35,
        description: 'Good Performance Gold',
        color: Colors.yellow,
      ),
      BattleReward(
        type: RewardType.cards,
        amount: 1,
        description: 'Random Card',
        color: Colors.blue,
      ),
    ],
    BattlePerformance.excellent: [
      BattleReward(
        type: RewardType.experience,
        amount: 100,
        description: 'Excellent Performance XP',
        color: Colors.blue,
      ),
      BattleReward(
        type: RewardType.gold,
        amount: 75,
        description: 'Excellent Performance Gold',
        color: Colors.yellow,
      ),
      BattleReward(
        type: RewardType.cards,
        amount: 2,
        description: 'Rare Cards',
        color: Colors.purple,
      ),
      BattleReward(
        type: RewardType.equipment,
        amount: 1,
        description: 'Rare Equipment',
        color: Colors.orange,
      ),
    ],
    BattlePerformance.legendary: [
      BattleReward(
        type: RewardType.experience,
        amount: 200,
        description: 'Legendary Performance XP',
        color: Colors.red,
      ),
      BattleReward(
        type: RewardType.gold,
        amount: 150,
        description: 'Legendary Performance Gold',
        color: Colors.yellow,
      ),
      BattleReward(
        type: RewardType.cards,
        amount: 3,
        description: 'Epic Cards',
        color: Colors.deepPurple,
      ),
      BattleReward(
        type: RewardType.equipment,
        amount: 2,
        description: 'Epic Equipment',
        color: Colors.deepOrange,
      ),
      BattleReward(
        type: RewardType.achievements,
        amount: 1,
        description: 'Battle Achievement',
        color: Colors.amber,
      ),
      BattleReward(
        type: RewardType.titles,
        amount: 1,
        description: 'Battle Title',
        color: Colors.cyan,
      ),
    ],
  };

  void initialize() {
    if (kDebugMode) {
      print('[BattleRewardsService] Initialized');
    }
  }

  /// Calculate battle performance based on various factors
  BattlePerformance calculatePerformance({
    required int damageDealt,
    required int damageTaken,
    required int cardsPlayed,
    required int turnsTaken,
    required bool isVictory,
    required int playerLevel,
    required int battleStreak,
  }) {
    double score = 0.0;
    
    // Base score from victory/defeat
    score += isVictory ? 50.0 : 10.0;
    
    // Damage dealt bonus (normalized by player level)
    double damageRatio = damageDealt / (playerLevel * 10.0);
    score += damageRatio * 30.0;
    
    // Damage taken penalty (less damage taken = better)
    double damageTakenRatio = damageTaken / (playerLevel * 15.0);
    score -= damageTakenRatio * 20.0;
    
    // Card efficiency bonus
    double cardEfficiency = cardsPlayed / turnsTaken.toDouble();
    score += cardEfficiency * 15.0;
    
    // Battle streak bonus
    score += battleStreak * 5.0;
    
    // Determine performance level
    if (score >= 120) return BattlePerformance.legendary;
    if (score >= 90) return BattlePerformance.excellent;
    if (score >= 60) return BattlePerformance.good;
    if (score >= 30) return BattlePerformance.average;
    return BattlePerformance.poor;
  }

  /// Generate rewards based on battle performance
  List<BattleReward> generateRewards({
    required BattlePerformance performance,
    required int playerLevel,
    required int battleStreak,
    required bool isVictory,
  }) {
    List<BattleReward> rewards = [];
    
    // Base rewards
    int baseXP = playerLevel * 10;
    int baseGold = playerLevel * 5;
    
    // Apply performance multiplier
    double multiplier = _performanceMultipliers[performance] ?? 1.0;
    
    // Add base rewards
    rewards.add(BattleReward(
      type: RewardType.experience,
      amount: (baseXP * multiplier).round(),
      description: 'Battle Experience',
      color: Colors.green,
    ));
    
    rewards.add(BattleReward(
      type: RewardType.gold,
      amount: (baseGold * multiplier).round(),
      description: 'Battle Gold',
      color: Colors.yellow,
    ));
    
    // Add special rewards based on performance
    final specialRewards = _specialRewards[performance] ?? [];
    rewards.addAll(specialRewards);
    
    // Victory bonus
    if (isVictory) {
      rewards.add(BattleReward(
        type: RewardType.experience,
        amount: (playerLevel * 5).round(),
        description: 'Victory Bonus',
        color: Colors.amber,
      ));
    }
    
    // Battle streak bonus
    if (battleStreak > 0) {
      rewards.add(BattleReward(
        type: RewardType.gold,
        amount: battleStreak * 10,
        description: 'Streak Bonus',
        color: Colors.orange,
      ));
    }
    
    return rewards;
  }

  /// Apply rewards to character
  Future<void> applyRewards({
    required List<BattleReward> rewards,
    required CharacterProvider characterProvider,
  }) async {
    final character = characterProvider.currentCharacter;
    if (character == null) return;
    
    for (final reward in rewards) {
      switch (reward.type) {
        case RewardType.experience:
          await _applyExperienceReward(reward, characterProvider);
          break;
        case RewardType.gold:
          await _applyGoldReward(reward, characterProvider);
          break;
        case RewardType.cards:
          await _applyCardReward(reward, characterProvider);
          break;
        case RewardType.equipment:
          await _applyEquipmentReward(reward, characterProvider);
          break;
        case RewardType.skills:
          await _applySkillReward(reward, characterProvider);
          break;
        case RewardType.achievements:
          await _applyAchievementReward(reward, characterProvider);
          break;
        case RewardType.titles:
          await _applyTitleReward(reward, characterProvider);
          break;
        case RewardType.currency:
          await _applyCurrencyReward(reward, characterProvider);
          break;
      }
    }
    
    // Character is automatically saved by the provider
    notifyListeners();
  }

  Future<void> _applyExperienceReward(BattleReward reward, CharacterProvider characterProvider) async {
    final character = characterProvider.currentCharacter;
    if (character == null) return;
    
    final newExperience = character.experience + reward.amount;
    final newLevel = _calculateLevel(newExperience);
    
    await characterProvider.updateCharacter(
      character.copyWith(
        experience: newExperience,
        level: newLevel,
      ),
    );
    
    if (kDebugMode) {
      print('[BattleRewardsService] Applied ${reward.amount} XP');
    }
  }

  Future<void> _applyGoldReward(BattleReward reward, CharacterProvider characterProvider) async {
    final character = characterProvider.currentCharacter;
    if (character == null) return;
    
    final currentGold = character.characterData['gold'] ?? 0;
    final newGold = currentGold + reward.amount;
    final updatedCharacterData = Map<String, dynamic>.from(character.characterData);
    updatedCharacterData['gold'] = newGold;
    
    await characterProvider.updateCharacter(
      character.copyWith(characterData: updatedCharacterData),
    );
    
    if (kDebugMode) {
      print('[BattleRewardsService] Applied ${reward.amount} Gold');
    }
  }

  Future<void> _applyCardReward(BattleReward reward, CharacterProvider characterProvider) async {
    final character = characterProvider.currentCharacter;
    if (character == null) return;
    
    // Generate random cards based on reward amount
    for (int i = 0; i < reward.amount; i++) {
      final randomCard = _generateRandomCard(character.characterClass);
      final newInventory = List<CardInstance>.from(character.inventory);
      newInventory.add(randomCard);
      
      await characterProvider.updateCharacter(
        character.copyWith(inventory: newInventory),
      );
    }
    
    if (kDebugMode) {
      print('[BattleRewardsService] Applied ${reward.amount} cards');
    }
  }

  Future<void> _applyEquipmentReward(BattleReward reward, CharacterProvider characterProvider) async {
    final character = characterProvider.currentCharacter;
    if (character == null) return;
    
    // Generate random equipment based on character level
    final randomEquipment = _generateRandomEquipment(character.characterClass, character.level);
    final newInventory = List<CardInstance>.from(character.inventory);
    newInventory.add(randomEquipment);
    
    await characterProvider.updateCharacter(
      character.copyWith(inventory: newInventory),
    );
    
    if (kDebugMode) {
      print('[BattleRewardsService] Applied equipment reward');
    }
  }

  Future<void> _applySkillReward(BattleReward reward, CharacterProvider characterProvider) async {
    final character = characterProvider.currentCharacter;
    if (character == null) return;
    
    // Add skill points
    final newSkillPoints = character.availableSkillPoints + reward.amount;
    
    await characterProvider.updateCharacter(
      character.copyWith(availableSkillPoints: newSkillPoints),
    );
    
    if (kDebugMode) {
      print('[BattleRewardsService] Applied ${reward.amount} skill points');
    }
  }

  Future<void> _applyAchievementReward(BattleReward reward, CharacterProvider characterProvider) async {
    // TODO: Implement achievement system
    if (kDebugMode) {
      print('[BattleRewardsService] Achievement reward (not implemented yet)');
    }
  }

  Future<void> _applyTitleReward(BattleReward reward, CharacterProvider characterProvider) async {
    // TODO: Implement title system
    if (kDebugMode) {
      print('[BattleRewardsService] Title reward (not implemented yet)');
    }
  }

  Future<void> _applyCurrencyReward(BattleReward reward, CharacterProvider characterProvider) async {
    // TODO: Implement premium currency system
    if (kDebugMode) {
      print('[BattleRewardsService] Currency reward (not implemented yet)');
    }
  }

  int _calculateLevel(int experience) {
    // Simple level calculation: every 100 XP = 1 level
    return (experience / 100).floor() + 1;
  }

  CardInstance _generateRandomCard(CharacterClass characterClass) {
    // Generate a random card based on character class
    final cardTypes = [CardType.weapon, CardType.armor, CardType.consumable, CardType.spell];
    final randomType = cardTypes[DateTime.now().millisecondsSinceEpoch % cardTypes.length];
    
    return CardInstance(
      card: GameCard(
        name: 'Random ${randomType.name}',
        description: 'A random ${randomType.name} card',
        type: randomType,
        rarity: CardRarity.common,
        cost: 1,
        attack: 5,
        defense: 3,
      ),
      quantity: 1,
    );
  }

  CardInstance _generateRandomEquipment(CharacterClass characterClass, int level) {
    // Generate equipment appropriate for character class and level
    final equipmentTypes = [CardType.weapon, CardType.armor, CardType.accessory];
    final randomType = equipmentTypes[DateTime.now().millisecondsSinceEpoch % equipmentTypes.length];
    
    return CardInstance(
      card: GameCard(
        name: 'Level $level ${randomType.name}',
        description: 'A level $level ${randomType.name}',
        type: randomType,
        rarity: CardRarity.rare,
        cost: level * 2,
        attack: level * 3,
        defense: level * 2,
        levelRequirement: level,
      ),
      quantity: 1,
    );
  }

  /// Get display information for rewards
  Map<String, dynamic> getRewardDisplayInfo(BattleReward reward) {
    IconData icon;
    String label;
    
    switch (reward.type) {
      case RewardType.experience:
        icon = Icons.star;
        label = 'XP';
        break;
      case RewardType.gold:
        icon = Icons.monetization_on;
        label = 'Gold';
        break;
      case RewardType.cards:
        icon = Icons.style;
        label = 'Cards';
        break;
      case RewardType.equipment:
        icon = Icons.shield;
        label = 'Equipment';
        break;
      case RewardType.skills:
        icon = Icons.psychology;
        label = 'Skill Points';
        break;
      case RewardType.achievements:
        icon = Icons.emoji_events;
        label = 'Achievement';
        break;
      case RewardType.titles:
        icon = Icons.workspace_premium;
        label = 'Title';
        break;
      case RewardType.currency:
        icon = Icons.diamond;
        label = 'Currency';
        break;
    }
    
    return {
      'icon': icon,
      'label': label,
      'color': reward.color ?? Colors.white,
      'description': reward.description ?? '',
    };
  }
} 