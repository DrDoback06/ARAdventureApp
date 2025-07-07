import 'package:json_annotation/json_annotation.dart';
import 'package:realm_of_valor/models/card_model.dart';
import 'package:realm_of_valor/models/adventure_system.dart';
import 'package:uuid/uuid.dart';

part 'guild_system.g.dart';

enum GuildRank {
  member,
  officer,
  captain,
  general,
  guildmaster,
}

enum GuildEventType {
  raid,
  tournament,
  treasure_hunt,
  exploration,
  social,
  training,
  charity,
}

enum TradeStatus {
  pending,
  active,
  completed,
  cancelled,
  expired,
}

enum RelationshipType {
  friend,
  rival,
  mentor,
  student,
  ally,
  blocked,
}

@JsonSerializable()
class GuildMember {
  final String id;
  final String playerId;
  final String playerName;
  final String playerAvatar;
  final GuildRank rank;
  final int contributionPoints;
  final int activityScore;
  final DateTime joinedDate;
  final DateTime lastActive;
  final Map<String, dynamic> achievements;
  final List<String> specialties;
  final Map<String, dynamic> metadata;

  GuildMember({
    String? id,
    required this.playerId,
    required this.playerName,
    this.playerAvatar = '',
    this.rank = GuildRank.member,
    this.contributionPoints = 0,
    this.activityScore = 0,
    DateTime? joinedDate,
    DateTime? lastActive,
    Map<String, dynamic>? achievements,
    List<String>? specialties,
    Map<String, dynamic>? metadata,
  }) : id = id ?? const Uuid().v4(),
       joinedDate = joinedDate ?? DateTime.now(),
       lastActive = lastActive ?? DateTime.now(),
       achievements = achievements ?? {},
       specialties = specialties ?? [],
       metadata = metadata ?? {};

  factory GuildMember.fromJson(Map<String, dynamic> json) =>
      _$GuildMemberFromJson(json);
  Map<String, dynamic> toJson() => _$GuildMemberToJson(this);

  GuildMember copyWith({
    String? id,
    String? playerId,
    String? playerName,
    String? playerAvatar,
    GuildRank? rank,
    int? contributionPoints,
    int? activityScore,
    DateTime? joinedDate,
    DateTime? lastActive,
    Map<String, dynamic>? achievements,
    List<String>? specialties,
    Map<String, dynamic>? metadata,
  }) {
    return GuildMember(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      playerAvatar: playerAvatar ?? this.playerAvatar,
      rank: rank ?? this.rank,
      contributionPoints: contributionPoints ?? this.contributionPoints,
      activityScore: activityScore ?? this.activityScore,
      joinedDate: joinedDate ?? this.joinedDate,
      lastActive: lastActive ?? this.lastActive,
      achievements: achievements ?? this.achievements,
      specialties: specialties ?? this.specialties,
      metadata: metadata ?? this.metadata,
    );
  }
}

@JsonSerializable()
class Guild {
  final String id;
  final String name;
  final String description;
  final String emblem;
  final String motto;
  final List<GuildMember> members;
  final int level;
  final int experience;
  final int treasury;
  final Map<String, dynamic> perks;
  final List<String> achievements;
  final DateTime createdDate;
  final Map<String, dynamic> settings;
  final List<String> bannedPlayers;
  final Map<String, dynamic> statistics;

  Guild({
    String? id,
    required this.name,
    required this.description,
    this.emblem = '',
    this.motto = '',
    List<GuildMember>? members,
    this.level = 1,
    this.experience = 0,
    this.treasury = 0,
    Map<String, dynamic>? perks,
    List<String>? achievements,
    DateTime? createdDate,
    Map<String, dynamic>? settings,
    List<String>? bannedPlayers,
    Map<String, dynamic>? statistics,
  }) : id = id ?? const Uuid().v4(),
       members = members ?? [],
       perks = perks ?? {},
       achievements = achievements ?? [],
       createdDate = createdDate ?? DateTime.now(),
       settings = settings ?? {
         'isPublic': true,
         'autoAccept': false,
         'minLevel': 1,
         'maxMembers': 50,
         'requireApplication': true,
       },
       bannedPlayers = bannedPlayers ?? [],
       statistics = statistics ?? {
         'total_xp_earned': 0,
         'quests_completed': 0,
         'battles_won': 0,
         'treasure_found': 0,
       };

  factory Guild.fromJson(Map<String, dynamic> json) =>
      _$GuildFromJson(json);
  Map<String, dynamic> toJson() => _$GuildToJson(this);

  Guild copyWith({
    String? id,
    String? name,
    String? description,
    String? emblem,
    String? motto,
    List<GuildMember>? members,
    int? level,
    int? experience,
    int? treasury,
    Map<String, dynamic>? perks,
    List<String>? achievements,
    DateTime? createdDate,
    Map<String, dynamic>? settings,
    List<String>? bannedPlayers,
    Map<String, dynamic>? statistics,
  }) {
    return Guild(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      emblem: emblem ?? this.emblem,
      motto: motto ?? this.motto,
      members: members ?? this.members,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      treasury: treasury ?? this.treasury,
      perks: perks ?? this.perks,
      achievements: achievements ?? this.achievements,
      createdDate: createdDate ?? this.createdDate,
      settings: settings ?? this.settings,
      bannedPlayers: bannedPlayers ?? this.bannedPlayers,
      statistics: statistics ?? this.statistics,
    );
  }

  GuildMember? get guildmaster => members.firstWhere(
    (member) => member.rank == GuildRank.guildmaster,
    orElse: () => members.isNotEmpty ? members.first : GuildMember(playerId: '', playerName: ''),
  );

  int get memberCount => members.length;
  int get maxMembers => settings['maxMembers'] ?? 50;
  bool get isFull => memberCount >= maxMembers;
  int get averageLevel => members.isNotEmpty ? 
    members.map((m) => m.activityScore).reduce((a, b) => a + b) ~/ members.length : 0;
}

@JsonSerializable()
class GuildEvent {
  final String id;
  final String guildId;
  final String name;
  final String description;
  final GuildEventType type;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> participants;
  final Map<String, dynamic> requirements;
  final Map<String, dynamic> rewards;
  final Map<String, dynamic> progress;
  final bool isActive;
  final String createdBy;
  final Map<String, dynamic> metadata;

  GuildEvent({
    String? id,
    required this.guildId,
    required this.name,
    required this.description,
    required this.type,
    required this.startTime,
    required this.endTime,
    List<String>? participants,
    Map<String, dynamic>? requirements,
    Map<String, dynamic>? rewards,
    Map<String, dynamic>? progress,
    this.isActive = true,
    required this.createdBy,
    Map<String, dynamic>? metadata,
  }) : id = id ?? const Uuid().v4(),
       participants = participants ?? [],
       requirements = requirements ?? {},
       rewards = rewards ?? {},
       progress = progress ?? {},
       metadata = metadata ?? {};

  factory GuildEvent.fromJson(Map<String, dynamic> json) =>
      _$GuildEventFromJson(json);
  Map<String, dynamic> toJson() => _$GuildEventToJson(this);

  GuildEvent copyWith({
    String? id,
    String? guildId,
    String? name,
    String? description,
    GuildEventType? type,
    DateTime? startTime,
    DateTime? endTime,
    List<String>? participants,
    Map<String, dynamic>? requirements,
    Map<String, dynamic>? rewards,
    Map<String, dynamic>? progress,
    bool? isActive,
    String? createdBy,
    Map<String, dynamic>? metadata,
  }) {
    return GuildEvent(
      id: id ?? this.id,
      guildId: guildId ?? this.guildId,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      participants: participants ?? this.participants,
      requirements: requirements ?? this.requirements,
      rewards: rewards ?? this.rewards,
      progress: progress ?? this.progress,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      metadata: metadata ?? this.metadata,
    );
  }
}

@JsonSerializable()
class TradeOffer {
  final String id;
  final String fromPlayerId;
  final String toPlayerId;
  final List<String> offeredCardIds;
  final List<String> requestedCardIds;
  final int goldOffered;
  final int goldRequested;
  final String message;
  final TradeStatus status;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? completedAt;
  final Map<String, dynamic> metadata;

  TradeOffer({
    String? id,
    required this.fromPlayerId,
    required this.toPlayerId,
    List<String>? offeredCardIds,
    List<String>? requestedCardIds,
    this.goldOffered = 0,
    this.goldRequested = 0,
    this.message = '',
    this.status = TradeStatus.pending,
    DateTime? createdAt,
    DateTime? expiresAt,
    this.completedAt,
    Map<String, dynamic>? metadata,
  }) : id = id ?? const Uuid().v4(),
       offeredCardIds = offeredCardIds ?? [],
       requestedCardIds = requestedCardIds ?? [],
       createdAt = createdAt ?? DateTime.now(),
       expiresAt = expiresAt ?? DateTime.now().add(Duration(days: 7)),
       metadata = metadata ?? {};

  factory TradeOffer.fromJson(Map<String, dynamic> json) =>
      _$TradeOfferFromJson(json);
  Map<String, dynamic> toJson() => _$TradeOfferToJson(this);

  TradeOffer copyWith({
    String? id,
    String? fromPlayerId,
    String? toPlayerId,
    List<String>? offeredCardIds,
    List<String>? requestedCardIds,
    int? goldOffered,
    int? goldRequested,
    String? message,
    TradeStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) {
    return TradeOffer(
      id: id ?? this.id,
      fromPlayerId: fromPlayerId ?? this.fromPlayerId,
      toPlayerId: toPlayerId ?? this.toPlayerId,
      offeredCardIds: offeredCardIds ?? this.offeredCardIds,
      requestedCardIds: requestedCardIds ?? this.requestedCardIds,
      goldOffered: goldOffered ?? this.goldOffered,
      goldRequested: goldRequested ?? this.goldRequested,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isActive => status == TradeStatus.active && !isExpired;
}

@JsonSerializable()
class SocialRelationship {
  final String id;
  final String playerId;
  final String relatedPlayerId;
  final RelationshipType type;
  final String note;
  final DateTime createdAt;
  final DateTime lastInteraction;
  final Map<String, dynamic> metadata;

  SocialRelationship({
    String? id,
    required this.playerId,
    required this.relatedPlayerId,
    required this.type,
    this.note = '',
    DateTime? createdAt,
    DateTime? lastInteraction,
    Map<String, dynamic>? metadata,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       lastInteraction = lastInteraction ?? DateTime.now(),
       metadata = metadata ?? {};

  factory SocialRelationship.fromJson(Map<String, dynamic> json) =>
      _$SocialRelationshipFromJson(json);
  Map<String, dynamic> toJson() => _$SocialRelationshipToJson(this);

  SocialRelationship copyWith({
    String? id,
    String? playerId,
    String? relatedPlayerId,
    RelationshipType? type,
    String? note,
    DateTime? createdAt,
    DateTime? lastInteraction,
    Map<String, dynamic>? metadata,
  }) {
    return SocialRelationship(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      relatedPlayerId: relatedPlayerId ?? this.relatedPlayerId,
      type: type ?? this.type,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      lastInteraction: lastInteraction ?? this.lastInteraction,
      metadata: metadata ?? this.metadata,
    );
  }
}

class GuildSystem {
  // Amazing guild events and activities
  static List<GuildEvent> get epicGuildEvents => [
    GuildEvent(
      guildId: '',
      name: 'Dragon Siege',
      description: 'Unite your guild to face the Ancient Dragon! All members work together to defeat this legendary beast and claim epic rewards.',
      type: GuildEventType.raid,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(Duration(hours: 48)),
      requirements: {
        'min_participants': 10,
        'min_guild_level': 5,
        'total_power_required': 5000,
      },
      rewards: {
        'guild_xp': 2000,
        'guild_gold': 5000,
        'cards': ['ancient_dragon', 'dragon_slayer_badge', 'guild_victory_trophy'],
        'individual_xp': 500,
        'individual_gold': 200,
      },
      createdBy: 'system',
    ),
    GuildEvent(
      guildId: '',
      name: 'Treasure Hunt Championship',
      description: 'Compete against other guilds in a massive treasure hunt across your city! Find hidden treasures and claim victory!',
      type: GuildEventType.treasure_hunt,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(Duration(days: 3)),
      requirements: {
        'min_participants': 5,
        'locations_to_visit': 20,
        'treasures_to_find': 15,
      },
      rewards: {
        'guild_xp': 1500,
        'guild_gold': 3000,
        'cards': ['treasure_hunter_crown', 'golden_compass', 'guild_map'],
        'individual_rewards': true,
      },
      createdBy: 'system',
    ),
    GuildEvent(
      guildId: '',
      name: 'Arena Tournament',
      description: 'Prove your guild\'s strength in combat! Face other guilds in epic PvP battles.',
      type: GuildEventType.tournament,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(Duration(hours: 24)),
      requirements: {
        'min_participants': 8,
        'tournament_bracket': true,
        'battle_format': 'elimination',
      },
      rewards: {
        'winner_guild_xp': 3000,
        'winner_guild_gold': 10000,
        'winner_cards': ['tournament_champion', 'victory_crown', 'guild_honor'],
        'participation_rewards': true,
      },
      createdBy: 'system',
    ),
    GuildEvent(
      guildId: '',
      name: 'Community Service Day',
      description: 'Help your local community while earning guild rewards! Visit local businesses, clean parks, and spread positivity.',
      type: GuildEventType.charity,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(Duration(hours: 12)),
      requirements: {
        'min_participants': 3,
        'community_actions': 10,
        'businesses_visited': 5,
      },
      rewards: {
        'guild_xp': 1000,
        'guild_gold': 1500,
        'cards': ['community_hero', 'kindness_badge', 'local_legend'],
        'real_world_impact': true,
      },
      createdBy: 'system',
    ),
  ];

  // Guild perks and benefits
  static Map<int, Map<String, dynamic>> get guildLevelPerks => {
    1: {
      'name': 'New Guild',
      'max_members': 20,
      'perks': ['basic_chat', 'guild_quests'],
    },
    5: {
      'name': 'Established Guild',
      'max_members': 35,
      'perks': ['guild_bank', 'member_boost_5_percent', 'guild_events'],
    },
    10: {
      'name': 'Renowned Guild',
      'max_members': 50,
      'perks': ['guild_shop', 'member_boost_10_percent', 'raid_access'],
    },
    15: {
      'name': 'Elite Guild',
      'max_members': 75,
      'perks': ['guild_fortress', 'member_boost_15_percent', 'tournament_hosting'],
    },
    20: {
      'name': 'Legendary Guild',
      'max_members': 100,
      'perks': ['guild_mastery', 'member_boost_20_percent', 'realm_influence'],
    },
  };

  // Guild rank permissions
  static Map<GuildRank, List<String>> get rankPermissions => {
    GuildRank.member: [
      'chat',
      'participate_events',
      'view_guild_info',
      'trade_with_members',
    ],
    GuildRank.officer: [
      'chat',
      'participate_events',
      'view_guild_info',
      'trade_with_members',
      'invite_players',
      'moderate_chat',
      'organize_events',
    ],
    GuildRank.captain: [
      'chat',
      'participate_events',
      'view_guild_info',
      'trade_with_members',
      'invite_players',
      'moderate_chat',
      'organize_events',
      'kick_members',
      'manage_treasury',
      'edit_guild_info',
    ],
    GuildRank.general: [
      'chat',
      'participate_events',
      'view_guild_info',
      'trade_with_members',
      'invite_players',
      'moderate_chat',
      'organize_events',
      'kick_members',
      'manage_treasury',
      'edit_guild_info',
      'promote_demote',
      'manage_alliance',
    ],
    GuildRank.guildmaster: [
      'all_permissions',
      'disband_guild',
      'transfer_leadership',
      'manage_settings',
    ],
  };

  // Trading system helpers
  static bool isValidTrade(TradeOffer trade, Map<String, List<GameCard>> playerCards) {
    final fromPlayerCards = playerCards[trade.fromPlayerId] ?? [];
    final toPlayerCards = playerCards[trade.toPlayerId] ?? [];
    
    // Check if offering player has the cards they're offering
    for (final cardId in trade.offeredCardIds) {
      if (!fromPlayerCards.any((card) => card.id == cardId)) {
        return false;
      }
    }
    
    // Check if requesting player has the cards being requested
    for (final cardId in trade.requestedCardIds) {
      if (!toPlayerCards.any((card) => card.id == cardId)) {
        return false;
      }
    }
    
    return true;
  }

  static Map<String, dynamic> calculateTradeValue(TradeOffer trade, Map<String, GameCard> cardDatabase) {
    int offeredValue = trade.goldOffered;
    int requestedValue = trade.goldRequested;
    
    // Calculate card values based on rarity
    for (final cardId in trade.offeredCardIds) {
      final card = cardDatabase[cardId];
      if (card != null) {
        offeredValue += _getCardValue(card);
      }
    }
    
    for (final cardId in trade.requestedCardIds) {
      final card = cardDatabase[cardId];
      if (card != null) {
        requestedValue += _getCardValue(card);
      }
    }
    
    return {
      'offered_value': offeredValue,
      'requested_value': requestedValue,
      'is_fair': (offeredValue - requestedValue).abs() <= (offeredValue * 0.2), // Within 20%
      'difference': offeredValue - requestedValue,
    };
  }

  static int _getCardValue(GameCard card) {
    switch (card.rarity) {
      case CardRarity.common:
        return 10;
      case CardRarity.uncommon:
        return 25;
      case CardRarity.rare:
        return 50;
      case CardRarity.epic:
        return 100;
      case CardRarity.legendary:
        return 250;
      case CardRarity.mythic:
        return 500;
      case CardRarity.holographic:
        return 750;
      case CardRarity.firstEdition:
        return 1000;
      case CardRarity.limitedEdition:
        return 1500;
      default:
        return 10;
    }
  }

  // Guild quest generation
  static List<Quest> generateGuildQuests(Guild guild) {
    final quests = <Quest>[];
    final now = DateTime.now();
    
    // Scale quest difficulty with guild level
    final difficultyMultiplier = 1 + (guild.level * 0.2);
    
    quests.addAll([
      Quest(
        title: 'Guild Unity Challenge',
        description: 'Have ${guild.memberCount} guild members complete daily activities together',
        type: QuestType.social,
        level: guild.level,
        xpReward: (200 * difficultyMultiplier).round(),
        cardRewards: ['guild_unity_badge', 'teamwork_charm'],
        endTime: now.add(Duration(hours: 24)),
        objectives: [
          QuestObjective(
            title: 'Collective Steps',
            description: 'Guild members take a combined 50,000 steps',
            type: 'guild_steps',
            requirements: {'total_steps': 50000, 'guild_id': guild.id},
            xpReward: (100 * difficultyMultiplier).round(),
          ),
          QuestObjective(
            title: 'Location Diversity',
            description: 'Visit 20 different locations as a guild',
            type: 'guild_locations',
            requirements: {'unique_locations': 20, 'guild_id': guild.id},
            xpReward: (100 * difficultyMultiplier).round(),
          ),
        ],
      ),
      Quest(
        title: 'Guild Treasure Hunt',
        description: 'Work together to find hidden treasures around your city',
        type: QuestType.treasure,
        level: guild.level + 2,
        xpReward: (500 * difficultyMultiplier).round(),
        cardRewards: ['guild_treasure_map', 'collective_wealth', 'team_discovery'],
        endTime: now.add(Duration(days: 3)),
        objectives: [
          QuestObjective(
            title: 'Find the Ancient Relics',
            description: 'Discover 10 treasure locations as a guild',
            type: 'guild_treasure',
            requirements: {'treasures_found': 10, 'guild_id': guild.id},
            xpReward: (300 * difficultyMultiplier).round(),
          ),
          QuestObjective(
            title: 'Share the Wealth',
            description: 'Each member contributes to the guild treasury',
            type: 'guild_contribution',
            requirements: {'min_contributors': guild.memberCount, 'guild_id': guild.id},
            xpReward: (200 * difficultyMultiplier).round(),
          ),
        ],
      ),
    ]);
    
    return quests;
  }

  // Social interaction helpers
  static Map<String, dynamic> calculateGuildActivityScore(Guild guild) {
    final now = DateTime.now();
    final yesterday = now.subtract(Duration(days: 1));
    final lastWeek = now.subtract(Duration(days: 7));
    
    int dailyActiveMembers = 0;
    int weeklyActiveMembers = 0;
    int totalContributions = 0;
    
    for (final member in guild.members) {
      if (member.lastActive.isAfter(yesterday)) {
        dailyActiveMembers++;
      }
      if (member.lastActive.isAfter(lastWeek)) {
        weeklyActiveMembers++;
      }
      totalContributions += member.contributionPoints;
    }
    
    return {
      'daily_active_members': dailyActiveMembers,
      'weekly_active_members': weeklyActiveMembers,
      'total_contributions': totalContributions,
      'activity_percentage': guild.memberCount > 0 ? 
        (weeklyActiveMembers / guild.memberCount * 100).round() : 0,
      'guild_health': _calculateGuildHealth(guild, weeklyActiveMembers),
    };
  }
  
  static String _calculateGuildHealth(Guild guild, int weeklyActiveMembers) {
    final activityRate = guild.memberCount > 0 ? 
      weeklyActiveMembers / guild.memberCount : 0;
    
    if (activityRate >= 0.8) return 'Excellent';
    if (activityRate >= 0.6) return 'Good';
    if (activityRate >= 0.4) return 'Fair';
    if (activityRate >= 0.2) return 'Poor';
    return 'Inactive';
  }

  // Epic guild rewards
  static Map<String, dynamic> calculateGuildEventRewards(
    GuildEvent event,
    List<String> participants,
    Map<String, dynamic> performance,
  ) {
    final rewards = <String, dynamic>{};
    final baseRewards = event.rewards;
    
    // Performance multiplier
    double performanceMultiplier = 1.0;
    final completionRate = performance['completion_rate'] ?? 0.0;
    
    if (completionRate >= 1.0) {
      performanceMultiplier = 1.5; // Perfect completion bonus
    } else if (completionRate >= 0.8) {
      performanceMultiplier = 1.2; // Great performance
    } else if (completionRate >= 0.6) {
      performanceMultiplier = 1.0; // Standard rewards
    } else {
      performanceMultiplier = 0.7; // Reduced rewards
    }
    
    // Participation bonus
    final participationBonus = participants.length >= (event.requirements['min_participants'] ?? 0) ? 1.1 : 1.0;
    
    // Calculate final rewards
    final finalMultiplier = performanceMultiplier * participationBonus;
    
    rewards['guild_xp'] = ((baseRewards['guild_xp'] ?? 0) * finalMultiplier).round();
    rewards['guild_gold'] = ((baseRewards['guild_gold'] ?? 0) * finalMultiplier).round();
    rewards['individual_xp'] = ((baseRewards['individual_xp'] ?? 0) * finalMultiplier).round();
    rewards['individual_gold'] = ((baseRewards['individual_gold'] ?? 0) * finalMultiplier).round();
    
    // Card rewards (always given for participation)
    rewards['cards'] = baseRewards['cards'] ?? [];
    
    // Special achievement rewards
    if (completionRate >= 1.0) {
      rewards['achievement'] = 'Perfect Execution';
      rewards['bonus_cards'] = ['perfection_crown', 'guild_mastery'];
    }
    
    if (participants.length >= ((event.requirements['min_participants'] ?? 0) * 2)) {
      rewards['participation_achievement'] = 'Overwhelming Response';
      rewards['participation_bonus_cards'] = ['unity_gem', 'collective_power'];
    }
    
    return rewards;
  }

  // Create amazing guild events
  static GuildEvent createSeasonalGuildEvent(String guildId, String season) {
    final now = DateTime.now();
    
    switch (season.toLowerCase()) {
      case 'winter':
        return GuildEvent(
          guildId: guildId,
          name: 'Winter Solstice Celebration',
          description: 'Celebrate the winter season together! Complete winter-themed challenges and spread joy in your community.',
          type: GuildEventType.social,
          startTime: now,
          endTime: now.add(Duration(days: 7)),
          requirements: {
            'min_participants': 5,
            'winter_activities': 15,
            'community_visits': 10,
          },
          rewards: {
            'guild_xp': 2000,
            'guild_gold': 3000,
            'cards': ['winter_crown', 'frost_spirit', 'seasonal_joy'],
            'individual_xp': 300,
            'seasonal_bonus': true,
          },
          createdBy: 'system',
        );
      
      case 'spring':
        return GuildEvent(
          guildId: guildId,
          name: 'Spring Awakening',
          description: 'Welcome spring with outdoor adventures! Explore parks, gardens, and nature trails together.',
          type: GuildEventType.exploration,
          startTime: now,
          endTime: now.add(Duration(days: 5)),
          requirements: {
            'min_participants': 8,
            'nature_locations': 20,
            'distance_walked': 100000, // 100km total
          },
          rewards: {
            'guild_xp': 1800,
            'guild_gold': 2500,
            'cards': ['spring_blossom', 'nature_guardian', 'renewal_charm'],
            'individual_xp': 250,
          },
          createdBy: 'system',
        );
      
      default:
        return createCustomGuildEvent(guildId);
    }
  }
  
  static GuildEvent createCustomGuildEvent(String guildId) {
    final now = DateTime.now();
    
    return GuildEvent(
      guildId: guildId,
      name: 'Guild Adventure Challenge',
      description: 'Embark on an epic adventure together! Complete various challenges and strengthen your guild bonds.',
      type: GuildEventType.exploration,
      startTime: now,
      endTime: now.add(Duration(days: 2)),
      requirements: {
        'min_participants': 3,
        'total_distance': 50000,
        'locations_visited': 15,
      },
      rewards: {
        'guild_xp': 1000,
        'guild_gold': 1500,
        'cards': ['adventure_badge', 'guild_bond', 'explorer_spirit'],
        'individual_xp': 200,
      },
      createdBy: 'system',
    );
  }
}