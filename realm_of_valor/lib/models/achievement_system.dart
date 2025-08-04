import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

part 'achievement_system.g.dart';

enum AchievementType {
  collection,
  exploration,
  fitness,
  battle,
  social,
  quest,
  seasonal,
  legendary,
  secret,
}

enum AchievementTier {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
  legendary,
  mythic,
}

enum BadgeCategory {
  collector,
  explorer,
  warrior,
  socialite,
  champion,
  guardian,
  legend,
  special,
}

@JsonSerializable()
class Achievement {
  final String id;
  final String name;
  final String description;
  final AchievementType type;
  final AchievementTier tier;
  final String iconUrl;
  final Map<String, dynamic> requirements;
  final Map<String, dynamic> progress;
  final Map<String, dynamic> rewards;
  final bool isCompleted;
  final bool isHidden;
  final DateTime? completedAt;
  final int points;
  final List<String> prerequisites;
  final Map<String, dynamic> metadata;

  Achievement({
    String? id,
    required this.name,
    required this.description,
    required this.type,
    this.tier = AchievementTier.bronze,
    this.iconUrl = '',
    Map<String, dynamic>? requirements,
    Map<String, dynamic>? progress,
    Map<String, dynamic>? rewards,
    this.isCompleted = false,
    this.isHidden = false,
    this.completedAt,
    this.points = 10,
    List<String>? prerequisites,
    Map<String, dynamic>? metadata,
  }) : id = id ?? const Uuid().v4(),
       requirements = requirements ?? {},
       progress = progress ?? {},
       rewards = rewards ?? {},
       prerequisites = prerequisites ?? [],
       metadata = metadata ?? {};

  factory Achievement.fromJson(Map<String, dynamic> json) =>
      _$AchievementFromJson(json);
  Map<String, dynamic> toJson() => _$AchievementToJson(this);

  Achievement copyWith({
    String? id,
    String? name,
    String? description,
    AchievementType? type,
    AchievementTier? tier,
    String? iconUrl,
    Map<String, dynamic>? requirements,
    Map<String, dynamic>? progress,
    Map<String, dynamic>? rewards,
    bool? isCompleted,
    bool? isHidden,
    DateTime? completedAt,
    int? points,
    List<String>? prerequisites,
    Map<String, dynamic>? metadata,
  }) {
    return Achievement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      tier: tier ?? this.tier,
      iconUrl: iconUrl ?? this.iconUrl,
      requirements: requirements ?? this.requirements,
      progress: progress ?? this.progress,
      rewards: rewards ?? this.rewards,
      isCompleted: isCompleted ?? this.isCompleted,
      isHidden: isHidden ?? this.isHidden,
      completedAt: completedAt ?? this.completedAt,
      points: points ?? this.points,
      prerequisites: prerequisites ?? this.prerequisites,
      metadata: metadata ?? this.metadata,
    );
  }

  double get progressPercentage {
    final current = progress['current'] ?? 0;
    final target = requirements['target'] ?? 1;
    return target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
  }

  Color get rarityColor {
    switch (tier) {
      case AchievementTier.bronze:
        return const Color(0xFFCD7F32);
      case AchievementTier.silver:
        return const Color(0xFFC0C0C0);
      case AchievementTier.gold:
        return const Color(0xFFFFD700);
      case AchievementTier.platinum:
        return const Color(0xFFE5E4E2);
      case AchievementTier.diamond:
        return const Color(0xFFB9F2FF);
      case AchievementTier.mythic:
        return const Color(0xFF8A2BE2);
      case AchievementTier.legendary:
        return const Color(0xFFFF4500);
    }
  }
}

@JsonSerializable()
class Collection {
  final String id;
  final String name;
  final String description;
  final List<String> cardIds;
  final List<String> ownedCardIds;
  final Map<String, int> cardCounts;
  final Map<String, dynamic> bonuses;
  final bool isCompleted;
  final DateTime? completedAt;
  final int completionReward;
  final List<String> rewardCards;
  final Map<String, dynamic> metadata;

  Collection({
    String? id,
    required this.name,
    required this.description,
    List<String>? cardIds,
    List<String>? ownedCardIds,
    Map<String, int>? cardCounts,
    Map<String, dynamic>? bonuses,
    this.isCompleted = false,
    this.completedAt,
    this.completionReward = 0,
    List<String>? rewardCards,
    Map<String, dynamic>? metadata,
  }) : id = id ?? const Uuid().v4(),
       cardIds = cardIds ?? [],
       ownedCardIds = ownedCardIds ?? [],
       cardCounts = cardCounts ?? {},
       bonuses = bonuses ?? {},
       rewardCards = rewardCards ?? [],
       metadata = metadata ?? {};

  factory Collection.fromJson(Map<String, dynamic> json) =>
      _$CollectionFromJson(json);
  Map<String, dynamic> toJson() => _$CollectionToJson(this);

  Collection copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? cardIds,
    List<String>? ownedCardIds,
    Map<String, int>? cardCounts,
    Map<String, dynamic>? bonuses,
    bool? isCompleted,
    DateTime? completedAt,
    int? completionReward,
    List<String>? rewardCards,
    Map<String, dynamic>? metadata,
  }) {
    return Collection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      cardIds: cardIds ?? this.cardIds,
      ownedCardIds: ownedCardIds ?? this.ownedCardIds,
      cardCounts: cardCounts ?? this.cardCounts,
      bonuses: bonuses ?? this.bonuses,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      completionReward: completionReward ?? this.completionReward,
      rewardCards: rewardCards ?? this.rewardCards,
      metadata: metadata ?? this.metadata,
    );
  }

  double get completionPercentage {
    return cardIds.isNotEmpty ? (ownedCardIds.length / cardIds.length) : 0.0;
  }

  int get missingCards => cardIds.length - ownedCardIds.length;
}

@JsonSerializable()
class Badge {
  final String id;
  final String name;
  final String description;
  final BadgeCategory category;
  final String iconUrl;
  final String colorHex;
  final DateTime earnedAt;
  final Map<String, dynamic> criteria;
  final Map<String, dynamic> metadata;

  Badge({
    String? id,
    required this.name,
    required this.description,
    required this.category,
    this.iconUrl = '',
    this.colorHex = '#FFD700',
    DateTime? earnedAt,
    Map<String, dynamic>? criteria,
    Map<String, dynamic>? metadata,
  }) : id = id ?? const Uuid().v4(),
       earnedAt = earnedAt ?? DateTime.now(),
       criteria = criteria ?? {},
       metadata = metadata ?? {};

  factory Badge.fromJson(Map<String, dynamic> json) =>
      _$BadgeFromJson(json);
  Map<String, dynamic> toJson() => _$BadgeToJson(this);

  Badge copyWith({
    String? id,
    String? name,
    String? description,
    BadgeCategory? category,
    String? iconUrl,
    String? colorHex,
    DateTime? earnedAt,
    Map<String, dynamic>? criteria,
    Map<String, dynamic>? metadata,
  }) {
    return Badge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      iconUrl: iconUrl ?? this.iconUrl,
      colorHex: colorHex ?? this.colorHex,
      earnedAt: earnedAt ?? this.earnedAt,
      criteria: criteria ?? this.criteria,
      metadata: metadata ?? this.metadata,
    );
  }
}

class AchievementSystem {
  // Epic collection achievements that make collecting addictive!
  static List<Achievement> get collectionAchievements => [
    // Card Collection Mastery
    Achievement(
      name: 'First Steps',
      description: 'Collect your first 10 cards',
      type: AchievementType.collection,
      tier: AchievementTier.bronze,
      requirements: {'cards_owned': 10},
      rewards: {'xp': 100, 'gold': 50, 'cards': ['collector_badge']},
      points: 10,
    ),
    Achievement(
      name: 'Growing Collection',
      description: 'Amass a collection of 50 unique cards',
      type: AchievementType.collection,
      tier: AchievementTier.silver,
      requirements: {'cards_owned': 50},
      rewards: {'xp': 500, 'gold': 200, 'cards': ['collection_master']},
      points: 25,
      prerequisites: ['first_steps'],
    ),
    Achievement(
      name: 'Serious Collector',
      description: 'Own 100 different cards',
      type: AchievementType.collection,
      tier: AchievementTier.gold,
      requirements: {'cards_owned': 100},
      rewards: {'xp': 1000, 'gold': 500, 'cards': ['golden_collector']},
      points: 50,
    ),
    Achievement(
      name: 'Master Collector',
      description: 'Possess 250 unique cards in your collection',
      type: AchievementType.collection,
      tier: AchievementTier.platinum,
      requirements: {'cards_owned': 250},
      rewards: {'xp': 2500, 'gold': 1000, 'cards': ['platinum_collector', 'collection_crown']},
      points: 100,
    ),
    Achievement(
      name: 'Legendary Hoarder',
      description: 'Collect all 500+ cards in the realm!',
      type: AchievementType.collection,
      tier: AchievementTier.legendary,
      requirements: {'cards_owned': 500},
      rewards: {'xp': 10000, 'gold': 5000, 'cards': ['complete_collection_crown', 'master_of_all']},
      points: 500,
    ),
    
    // Rarity-based achievements
    Achievement(
      name: 'Rare Hunter',
      description: 'Collect 10 rare cards',
      type: AchievementType.collection,
      tier: AchievementTier.silver,
      requirements: {'rare_cards': 10},
      rewards: {'xp': 300, 'gold': 150, 'cards': ['rare_hunter_badge']},
      points: 30,
    ),
    Achievement(
      name: 'Epic Seeker',
      description: 'Own 5 epic cards',
      type: AchievementType.collection,
      tier: AchievementTier.gold,
      requirements: {'epic_cards': 5},
      rewards: {'xp': 750, 'gold': 400, 'cards': ['epic_seeker_medal']},
      points: 75,
    ),
    Achievement(
      name: 'Legend Collector',
      description: 'Possess 3 legendary cards',
      type: AchievementType.collection,
      tier: AchievementTier.platinum,
      requirements: {'legendary_cards': 3},
      rewards: {'xp': 1500, 'gold': 800, 'cards': ['legend_collector_crown']},
      points: 150,
    ),
    Achievement(
      name: 'Mythic Master',
      description: 'Own a mythic card - the rarest of all!',
      type: AchievementType.collection,
      tier: AchievementTier.mythic,
      requirements: {'mythic_cards': 1},
      rewards: {'xp': 5000, 'gold': 2500, 'cards': ['mythic_master_throne']},
      points: 1000,
    ),
    
    // Set Collection achievements
    Achievement(
      name: 'Core Master',
      description: 'Complete the entire Core set',
      type: AchievementType.collection,
      tier: AchievementTier.gold,
      requirements: {'complete_set': 'core'},
      rewards: {'xp': 1000, 'gold': 500, 'cards': ['core_master_emblem']},
      points: 100,
    ),
    Achievement(
      name: 'Shadow Walker',
      description: 'Collect all cards from the Shadows set',
      type: AchievementType.collection,
      tier: AchievementTier.platinum,
      requirements: {'complete_set': 'shadows'},
      rewards: {'xp': 2000, 'gold': 1000, 'cards': ['shadow_walker_cloak']},
      points: 200,
    ),
    Achievement(
      name: 'Elemental Lord',
      description: 'Master all elemental cards',
      type: AchievementType.collection,
      tier: AchievementTier.diamond,
      requirements: {'complete_set': 'elements'},
      rewards: {'xp': 3000, 'gold': 1500, 'cards': ['elemental_lord_staff']},
      points: 300,
    ),
  ];

  // Fitness and exploration achievements
  static List<Achievement> get fitnessAchievements => [
    Achievement(
      name: 'First Steps',
      description: 'Take your first 1,000 steps',
      type: AchievementType.fitness,
      tier: AchievementTier.bronze,
      requirements: {'steps': 1000},
      rewards: {'xp': 50, 'gold': 25, 'cards': ['walking_boots']},
      points: 10,
    ),
    Achievement(
      name: 'Daily Walker',
      description: 'Walk 10,000 steps in a single day',
      type: AchievementType.fitness,
      tier: AchievementTier.silver,
      requirements: {'daily_steps': 10000},
      rewards: {'xp': 200, 'gold': 100, 'cards': ['daily_walker_medal']},
      points: 25,
    ),
    Achievement(
      name: 'Marathon Master',
      description: 'Walk the distance of a marathon (42.2km)',
      type: AchievementType.fitness,
      tier: AchievementTier.platinum,
      requirements: {'total_distance': 42200},
      rewards: {'xp': 2000, 'gold': 1000, 'cards': ['marathon_crown']},
      points: 200,
    ),
    Achievement(
      name: 'Calorie Crusher',
      description: 'Burn 1,000 calories through activity',
      type: AchievementType.fitness,
      tier: AchievementTier.gold,
      requirements: {'calories_burned': 1000},
      rewards: {'xp': 500, 'gold': 250, 'cards': ['calorie_crusher_trophy']},
      points: 50,
    ),
    Achievement(
      name: 'Explorer Extraordinaire',
      description: 'Visit 100 different locations',
      type: AchievementType.exploration,
      tier: AchievementTier.diamond,
      requirements: {'unique_locations': 100},
      rewards: {'xp': 2500, 'gold': 1200, 'cards': ['explorer_compass', 'world_map']},
      points: 250,
    ),
  ];

  // Battle achievements
  static List<Achievement> get battleAchievements => [
    Achievement(
      name: 'First Victory',
      description: 'Win your first battle',
      type: AchievementType.battle,
      tier: AchievementTier.bronze,
      requirements: {'battles_won': 1},
      rewards: {'xp': 100, 'gold': 50, 'cards': ['victory_token']},
      points: 15,
    ),
    Achievement(
      name: 'Warrior',
      description: 'Achieve 10 battle victories',
      type: AchievementType.battle,
      tier: AchievementTier.silver,
      requirements: {'battles_won': 10},
      rewards: {'xp': 500, 'gold': 250, 'cards': ['warrior_badge']},
      points: 50,
    ),
    Achievement(
      name: 'Champion',
      description: 'Win 50 battles to become a true champion',
      type: AchievementType.battle,
      tier: AchievementTier.gold,
      requirements: {'battles_won': 50},
      rewards: {'xp': 1500, 'gold': 750, 'cards': ['champion_sword']},
      points: 150,
    ),
    Achievement(
      name: 'Perfect Fighter',
      description: 'Win a battle without taking any damage',
      type: AchievementType.battle,
      tier: AchievementTier.platinum,
      requirements: {'perfect_victories': 1},
      rewards: {'xp': 1000, 'gold': 500, 'cards': ['perfect_shield']},
      points: 100,
    ),
    Achievement(
      name: 'Dragon Slayer',
      description: 'Defeat the Ancient Dragon',
      type: AchievementType.battle,
      tier: AchievementTier.legendary,
      requirements: {'dragons_defeated': 1},
      rewards: {'xp': 5000, 'gold': 2500, 'cards': ['dragon_slayer_title', 'dragonbane_sword']},
      points: 500,
    ),
  ];

  // Social achievements
  static List<Achievement> get socialAchievements => [
    Achievement(
      name: 'Social Butterfly',
      description: 'Make your first friend in the realm',
      type: AchievementType.social,
      tier: AchievementTier.bronze,
      requirements: {'friends': 1},
      rewards: {'xp': 100, 'gold': 50, 'cards': ['friendship_bracelet']},
      points: 15,
    ),
    Achievement(
      name: 'Guild Founder',
      description: 'Create or join your first guild',
      type: AchievementType.social,
      tier: AchievementTier.silver,
      requirements: {'guild_membership': 1},
      rewards: {'xp': 300, 'gold': 150, 'cards': ['guild_emblem']},
      points: 30,
    ),
    Achievement(
      name: 'Trade Master',
      description: 'Complete 10 successful trades',
      type: AchievementType.social,
      tier: AchievementTier.gold,
      requirements: {'successful_trades': 10},
      rewards: {'xp': 750, 'gold': 400, 'cards': ['merchant_seal']},
      points: 75,
    ),
    Achievement(
      name: 'Community Leader',
      description: 'Help organize 5 guild events',
      type: AchievementType.social,
      tier: AchievementTier.platinum,
      requirements: {'events_organized': 5},
      rewards: {'xp': 2000, 'gold': 1000, 'cards': ['leadership_crown']},
      points: 200,
    ),
  ];

  // Secret achievements for fun discoveries!
  static List<Achievement> get secretAchievements => [
    Achievement(
      name: 'Night Owl',
      description: 'Play between midnight and 4 AM',
      type: AchievementType.secret,
      tier: AchievementTier.silver,
      requirements: {'night_sessions': 1},
      rewards: {'xp': 200, 'gold': 100, 'cards': ['night_owl_mask']},
      points: 25,
      isHidden: true,
    ),
    Achievement(
      name: 'Early Bird',
      description: 'Start a session before 6 AM',
      type: AchievementType.secret,
      tier: AchievementTier.silver,
      requirements: {'early_sessions': 1},
      rewards: {'xp': 200, 'gold': 100, 'cards': ['early_bird_feather']},
      points: 25,
      isHidden: true,
    ),
    Achievement(
      name: 'Lucky Seven',
      description: 'Open 7 card packs in a row',
      type: AchievementType.secret,
      tier: AchievementTier.gold,
      requirements: {'consecutive_packs': 7},
      rewards: {'xp': 777, 'gold': 777, 'cards': ['lucky_charm']},
      points: 77,
      isHidden: true,
    ),
    Achievement(
      name: 'Speed Demon',
      description: 'Complete a quest in under 5 minutes',
      type: AchievementType.secret,
      tier: AchievementTier.platinum,
      requirements: {'speed_completion': 300}, // 5 minutes in seconds
      rewards: {'xp': 1000, 'gold': 500, 'cards': ['speed_boots']},
      points: 100,
      isHidden: true,
    ),
  ];

  // Amazing collections to complete
  static List<Collection> get epicCollections => [
    Collection(
      name: 'Legendary Weapons Arsenal',
      description: 'Collect all the legendary weapons of the realm',
      cardIds: ['excalibur', 'stormhammer', 'shadowfang', 'dragonbane', 'lightbringer'],
      bonuses: {'attack_bonus': 20, 'critical_chance': 10},
      completionReward: 5000,
      rewardCards: ['weapon_master_title', 'arsenal_key'],
    ),
    Collection(
      name: 'Dragon Hoard',
      description: 'Gather all dragon-related cards',
      cardIds: ['ancient_dragon', 'dragon_scale_armor', 'dragon_breath', 'dragon_egg', 'baby_dragon'],
      bonuses: {'fire_resistance': 50, 'intimidation': 25},
      completionReward: 7500,
      rewardCards: ['dragon_lord_crown', 'flame_of_eternity'],
    ),
    Collection(
      name: 'Elemental Mastery',
      description: 'Master all elemental cards and spells',
      cardIds: ['fireball', 'ice_shard', 'lightning_bolt', 'earth_quake', 'wind_slash'],
      bonuses: {'elemental_damage': 30, 'mana_efficiency': 20},
      completionReward: 3000,
      rewardCards: ['elemental_master_staff', 'primal_essence'],
    ),
    Collection(
      name: 'Shadow Realm',
      description: 'Embrace the darkness with all shadow cards',
      cardIds: ['shadow_wraith', 'void_drain', 'shadow_clone', 'darkness_embrace', 'night_terror'],
      bonuses: {'stealth_bonus': 40, 'shadow_damage': 25},
      completionReward: 4000,
      rewardCards: ['shadow_master_cloak', 'void_crystal'],
    ),
    Collection(
      name: 'Physical Card Legends',
      description: 'Own all the rare physical collector cards',
      cardIds: ['PHYS_EXC_001', 'PHYS_MJO_001', 'PHYS_DRA_001', 'PHYS_BAH_001'],
      bonuses: {'collector_prestige': 100, 'trading_bonus': 50},
      completionReward: 25000,
      rewardCards: ['ultimate_collector_throne', 'physical_master_certificate'],
    ),
  ];

  // Badge system for various accomplishments
  static List<Badge> get availableBadges => [
    Badge(
      name: 'Card Collector',
      description: 'Awarded for collecting 100 unique cards',
      category: BadgeCategory.collector,
      colorHex: '#4CAF50',
      criteria: {'cards_collected': 100},
    ),
    Badge(
      name: 'Fitness Enthusiast',
      description: 'Walk 50,000 steps in total',
      category: BadgeCategory.explorer,
      colorHex: '#FF9800',
      criteria: {'total_steps': 50000},
    ),
    Badge(
      name: 'Battle Veteran',
      description: 'Win 25 battles',
      category: BadgeCategory.warrior,
      colorHex: '#F44336',
      criteria: {'battles_won': 25},
    ),
    Badge(
      name: 'Guild Master',
      description: 'Successfully lead a guild for 30 days',
      category: BadgeCategory.socialite,
      colorHex: '#9C27B0',
      criteria: {'guild_leadership_days': 30},
    ),
    Badge(
      name: 'Champion of the Realm',
      description: 'Achieve the highest battle ranking',
      category: BadgeCategory.champion,
      colorHex: '#FFD700',
      criteria: {'highest_ranking': 1},
    ),
    Badge(
      name: 'Legendary Explorer',
      description: 'Visit every type of location in the game',
      category: BadgeCategory.explorer,
      colorHex: '#00BCD4',
      criteria: {'location_types_visited': 15},
    ),
  ];

  // Progress tracking helpers
  static Achievement? checkAchievementProgress(
    Achievement achievement,
    Map<String, dynamic> playerStats,
  ) {
    bool isCompleted = true;
    final updatedProgress = Map<String, dynamic>.from(achievement.progress);
    
    for (final requirement in achievement.requirements.entries) {
      final requiredValue = requirement.value;
      final currentValue = playerStats[requirement.key] ?? 0;
      
      updatedProgress[requirement.key] = currentValue;
      
      if (currentValue < requiredValue) {
        isCompleted = false;
      }
    }
    
    if (isCompleted && !achievement.isCompleted) {
      return achievement.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
        progress: updatedProgress,
      );
    } else if (!isCompleted) {
      return achievement.copyWith(
        progress: updatedProgress,
      );
    }
    
    return null;
  }

  static Collection updateCollectionProgress(
    Collection collection,
    List<String> ownedCardIds,
  ) {
    final ownedFromCollection = collection.cardIds
        .where((cardId) => ownedCardIds.contains(cardId))
        .toList();
    
    final isCompleted = ownedFromCollection.length == collection.cardIds.length;
    
    return collection.copyWith(
      ownedCardIds: ownedFromCollection,
      isCompleted: isCompleted,
      completedAt: isCompleted && !collection.isCompleted ? DateTime.now() : collection.completedAt,
    );
  }

  // Reward calculation
  static Map<String, dynamic> calculateAchievementRewards(Achievement achievement) {
    final baseRewards = Map<String, dynamic>.from(achievement.rewards);
    
    // Tier multipliers
    double multiplier = 1.0;
    switch (achievement.tier) {
      case AchievementTier.bronze:
        multiplier = 1.0;
        break;
      case AchievementTier.silver:
        multiplier = 1.5;
        break;
      case AchievementTier.gold:
        multiplier = 2.0;
        break;
      case AchievementTier.platinum:
        multiplier = 3.0;
        break;
      case AchievementTier.diamond:
        multiplier = 4.0;
        break;
      case AchievementTier.legendary:
        multiplier = 5.0;
        break;
      case AchievementTier.mythic:
        multiplier = 10.0;
        break;
    }
    
    // Apply multiplier to numerical rewards
    if (baseRewards.containsKey('xp')) {
      baseRewards['xp'] = (baseRewards['xp'] * multiplier).round();
    }
    if (baseRewards.containsKey('gold')) {
      baseRewards['gold'] = (baseRewards['gold'] * multiplier).round();
    }
    
    // Add tier-specific bonus cards
    final bonusCards = <String>[];
    if (achievement.tier == AchievementTier.legendary) {
      bonusCards.add('legendary_achievement_crown');
    }
    if (achievement.tier == AchievementTier.mythic) {
      bonusCards.add('mythic_achievement_throne');
    }
    
    if (bonusCards.isNotEmpty) {
      final existingCards = List<String>.from(baseRewards['cards'] ?? []);
      existingCards.addAll(bonusCards);
      baseRewards['cards'] = existingCards;
    }
    
    return baseRewards;
  }

  // Get all achievements
  static List<Achievement> get allAchievements => [
    ...collectionAchievements,
    ...fitnessAchievements,
    ...battleAchievements,
    ...socialAchievements,
    ...secretAchievements,
  ];

  // Achievement statistics
  static Map<String, dynamic> getAchievementStats(List<Achievement> playerAchievements) {
    final completed = playerAchievements.where((a) => a.isCompleted).length;
    final total = allAchievements.length;
    final totalPoints = playerAchievements
        .where((a) => a.isCompleted)
        .fold(0, (sum, achievement) => sum + achievement.points);
    
    final tierCounts = <AchievementTier, int>{};
    for (final achievement in playerAchievements.where((a) => a.isCompleted)) {
      tierCounts[achievement.tier] = (tierCounts[achievement.tier] ?? 0) + 1;
    }
    
    return {
      'completed': completed,
      'total': total,
      'completion_percentage': total > 0 ? (completed / total * 100).round() : 0,
      'total_points': totalPoints,
      'tier_counts': tierCounts,
      'achievement_score': _calculateAchievementScore(totalPoints, tierCounts),
    };
  }
  
  static int _calculateAchievementScore(int totalPoints, Map<AchievementTier, int> tierCounts) {
    int score = totalPoints;
    
    // Bonus points for tier diversity
    score += (tierCounts[AchievementTier.legendary] ?? 0) * 100;
    score += (tierCounts[AchievementTier.mythic] ?? 0) * 500;
    
    return score;
  }

  // Generate daily/weekly challenges
  static List<Achievement> generateDailyChallenges() {
    final today = DateTime.now();
    return [
      Achievement(
        id: 'daily_${today.day}_${today.month}',
        name: 'Daily Adventurer',
        description: 'Complete today\'s fitness and exploration goals',
        type: AchievementType.fitness,
        tier: AchievementTier.bronze,
        requirements: {'daily_steps': 5000, 'locations_visited': 2},
        rewards: {'xp': 200, 'gold': 100, 'cards': ['daily_reward_box']},
        points: 20,
        metadata: {'expires_at': today.add(const Duration(days: 1)).toIso8601String()},
      ),
      Achievement(
        id: 'daily_collection_${today.day}_${today.month}',
        name: 'Card Hunter',
        description: 'Find and collect 3 new cards today',
        type: AchievementType.collection,
        tier: AchievementTier.silver,
        requirements: {'daily_cards_found': 3},
        rewards: {'xp': 300, 'gold': 150, 'cards': ['collection_boost']},
        points: 30,
        metadata: {'expires_at': today.add(const Duration(days: 1)).toIso8601String()},
      ),
    ];
  }
}