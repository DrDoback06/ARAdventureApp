import 'package:json_annotation/json_annotation.dart';
import 'package:realm_of_valor/models/card_model.dart';
import 'package:realm_of_valor/models/adventure_system.dart';
import 'package:realm_of_valor/models/guild_system.dart';
import 'package:uuid/uuid.dart';
import 'dart:math' as math;

part 'event_system.g.dart';

enum EventType {
  limited_time,   // Special short-term events
  seasonal,       // Holiday and season-based events
  community,      // Server-wide community challenges
  guild,          // Guild-specific events
  fitness,        // Fitness-focused challenges
  collection,     // Card collection events
  pvp,           // Player vs Player tournaments
  exploration,    // Real-world exploration events
  charity,        // Real-world charity tie-ins
}

enum EventStatus {
  upcoming,
  active,
  ending_soon,
  completed,
  failed,
}

enum RewardTier {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
  legendary,
}

@JsonSerializable()
class EventReward {
  final String id;
  final String name;
  final String description;
  final RewardTier tier;
  final List<String> cardIds;
  final int xp;
  final int gold;
  final Map<String, dynamic> specialRewards;
  final bool isExclusive;
  final DateTime? expiresAt;

  EventReward({
    String? id,
    required this.name,
    required this.description,
    required this.tier,
    List<String>? cardIds,
    this.xp = 0,
    this.gold = 0,
    Map<String, dynamic>? specialRewards,
    this.isExclusive = false,
    this.expiresAt,
  }) : id = id ?? const Uuid().v4(),
       cardIds = cardIds ?? [],
       specialRewards = specialRewards ?? {};

  factory EventReward.fromJson(Map<String, dynamic> json) =>
      _$EventRewardFromJson(json);
  Map<String, dynamic> toJson() => _$EventRewardToJson(this);
}

@JsonSerializable()
class EventObjective {
  final String id;
  final String title;
  final String description;
  final String type;
  final Map<String, dynamic> requirements;
  final int currentProgress;
  final int targetProgress;
  final bool isCompleted;
  final EventReward? reward;
  final Map<String, dynamic> metadata;

  EventObjective({
    String? id,
    required this.title,
    required this.description,
    required this.type,
    required this.requirements,
    this.currentProgress = 0,
    required this.targetProgress,
    this.isCompleted = false,
    this.reward,
    Map<String, dynamic>? metadata,
  }) : id = id ?? const Uuid().v4(),
       metadata = metadata ?? {};

  factory EventObjective.fromJson(Map<String, dynamic> json) =>
      _$EventObjectiveFromJson(json);
  Map<String, dynamic> toJson() => _$EventObjectiveToJson(this);

  EventObjective copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    Map<String, dynamic>? requirements,
    int? currentProgress,
    int? targetProgress,
    bool? isCompleted,
    EventReward? reward,
    Map<String, dynamic>? metadata,
  }) {
    return EventObjective(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      requirements: requirements ?? this.requirements,
      currentProgress: currentProgress ?? this.currentProgress,
      targetProgress: targetProgress ?? this.targetProgress,
      isCompleted: isCompleted ?? this.isCompleted,
      reward: reward ?? this.reward,
      metadata: metadata ?? this.metadata,
    );
  }

  double get progressPercentage => currentProgress / targetProgress;
}

@JsonSerializable()
class GameEvent {
  final String id;
  final String name;
  final String description;
  final EventType type;
  final EventStatus status;
  final DateTime startTime;
  final DateTime endTime;
  final List<EventObjective> objectives;
  final List<EventReward> rewards;
  final Map<String, dynamic> requirements;
  final Map<String, dynamic> globalProgress;
  final bool isRecurring;
  final String iconUrl;
  final String bannerUrl;
  final Map<String, dynamic> metadata;

  GameEvent({
    String? id,
    required this.name,
    required this.description,
    required this.type,
    this.status = EventStatus.upcoming,
    required this.startTime,
    required this.endTime,
    List<EventObjective>? objectives,
    List<EventReward>? rewards,
    Map<String, dynamic>? requirements,
    Map<String, dynamic>? globalProgress,
    this.isRecurring = false,
    this.iconUrl = '',
    this.bannerUrl = '',
    Map<String, dynamic>? metadata,
  }) : id = id ?? const Uuid().v4(),
       objectives = objectives ?? [],
       rewards = rewards ?? [],
       requirements = requirements ?? {},
       globalProgress = globalProgress ?? {},
       metadata = metadata ?? {};

  factory GameEvent.fromJson(Map<String, dynamic> json) =>
      _$GameEventFromJson(json);
  Map<String, dynamic> toJson() => _$GameEventToJson(this);

  GameEvent copyWith({
    String? id,
    String? name,
    String? description,
    EventType? type,
    EventStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    List<EventObjective>? objectives,
    List<EventReward>? rewards,
    Map<String, dynamic>? requirements,
    Map<String, dynamic>? globalProgress,
    bool? isRecurring,
    String? iconUrl,
    String? bannerUrl,
    Map<String, dynamic>? metadata,
  }) {
    return GameEvent(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      objectives: objectives ?? this.objectives,
      rewards: rewards ?? this.rewards,
      requirements: requirements ?? this.requirements,
      globalProgress: globalProgress ?? this.globalProgress,
      isRecurring: isRecurring ?? this.isRecurring,
      iconUrl: iconUrl ?? this.iconUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isActive => status == EventStatus.active;
  bool get isEndingSoon => status == EventStatus.ending_soon;
  Duration get timeRemaining => endTime.difference(DateTime.now());
  Duration get timeSinceStart => DateTime.now().difference(startTime);
  double get eventProgress => objectives.isEmpty ? 0.0 : 
      objectives.map((o) => o.progressPercentage).reduce((a, b) => a + b) / objectives.length;
}

class EventSystem {
  // Current Limited-Time Events - Create FOMO and excitement!
  static List<GameEvent> get activeEvents => [
    // Dragon Awakening Event - Ultra rare dragons!
    GameEvent(
      name: 'The Great Dragon Awakening',
      description: 'Ancient dragons have awakened across the realm! This legendary event brings the rarest dragon cards ever seen. Participate now or miss out forever!',
      type: EventType.limited_time,
      status: EventStatus.active,
      startTime: DateTime.now().subtract(Duration(hours: 2)),
      endTime: DateTime.now().add(Duration(days: 7)),
      objectives: [
        EventObjective(
          title: 'Dragon Hunter',
          description: 'Defeat 10 dragon creatures in battle',
          type: 'defeat_dragons',
          requirements: {'creature_type': 'dragon', 'count': 10},
          targetProgress: 10,
          reward: EventReward(
            name: 'Dragon Scale Armor',
            description: 'Legendary armor forged from ancient dragon scales',
            tier: RewardTier.gold,
            cardIds: ['dragon_scale_armor'],
            xp: 500,
            gold: 1000,
          ),
        ),
        EventObjective(
          title: 'Dragon Lord\'s Treasure',
          description: 'Collect 5 different dragon cards during the event',
          type: 'collect_dragons',
          requirements: {'card_type': 'dragon', 'unique_count': 5},
          targetProgress: 5,
          reward: EventReward(
            name: 'Ancient Dragon Egg',
            description: 'A mysterious egg that may hatch into something extraordinary',
            tier: RewardTier.legendary,
            cardIds: ['ancient_dragon_egg'],
            xp: 1000,
            gold: 2500,
            specialRewards: {'dragon_companion': true, 'exclusive_title': 'Dragon Whisperer'},
            isExclusive: true,
          ),
        ),
        EventObjective(
          title: 'Dragon\'s Hoard Master',
          description: 'Complete the Dragon\'s Hoard collection (50 cards)',
          type: 'complete_collection',
          requirements: {'collection': 'dragons_hoard', 'completion': 100},
          targetProgress: 50,
          reward: EventReward(
            name: 'Legendary Dragon Crown',
            description: 'The ultimate symbol of dragon mastery',
            tier: RewardTier.legendary,
            cardIds: ['legendary_dragon_crown', 'elder_dragon_spirit'],
            xp: 2500,
            gold: 10000,
            specialRewards: {
              'exclusive_title': 'Dragon Emperor',
              'dragon_aura': true,
              'legendary_pet': 'ancient_dragon_companion',
            },
            isExclusive: true,
          ),
        ),
      ],
      rewards: [
        EventReward(
          name: 'Dragon Event Participation',
          description: 'Thank you for participating in the Dragon Awakening!',
          tier: RewardTier.bronze,
          cardIds: ['dragon_breath_potion', 'dragon_tooth_necklace'],
          xp: 200,
          gold: 500,
        ),
      ],
      metadata: {
        'event_theme': 'dragons',
        'rarity_boost': 2.0,
        'dragon_spawn_rate': 3.0,
        'community_goal': 'Defeat 1,000,000 dragons worldwide',
      },
    ),

    // Fitness Revolution Challenge
    GameEvent(
      name: 'New Year Fitness Revolution',
      description: 'Transform your life! Join millions in the ultimate fitness challenge. Real rewards for real results!',
      type: EventType.fitness,
      status: EventStatus.active,
      startTime: DateTime.now().subtract(Duration(days: 5)),
      endTime: DateTime.now().add(Duration(days: 25)),
      objectives: [
        EventObjective(
          title: 'Resolution Walker',
          description: 'Walk 100,000 steps during the event',
          type: 'fitness_steps',
          requirements: {'steps': 100000},
          targetProgress: 100000,
          reward: EventReward(
            name: 'Resolution Champion Badge',
            description: 'Proof of your dedication to fitness',
            tier: RewardTier.silver,
            cardIds: ['resolution_badge', 'motivation_crystal'],
            xp: 750,
            gold: 1500,
          ),
        ),
        EventObjective(
          title: 'Calorie Crusher',
          description: 'Burn 10,000 calories through activities',
          type: 'fitness_calories',
          requirements: {'calories': 10000},
          targetProgress: 10000,
          reward: EventReward(
            name: 'Calorie Crusher Crown',
            description: 'For those who crush their calorie goals!',
            tier: RewardTier.gold,
            cardIds: ['calorie_crusher_crown', 'endurance_boost'],
            xp: 1250,
            gold: 2500,
            specialRewards: {'fitness_multiplier': 1.5},
          ),
        ),
        EventObjective(
          title: 'Fitness Legend',
          description: 'Complete 30 different fitness activities',
          type: 'fitness_variety',
          requirements: {'activity_types': 30},
          targetProgress: 30,
          reward: EventReward(
            name: 'Fitness Legend Status',
            description: 'Legendary status for fitness mastery',
            tier: RewardTier.legendary,
            cardIds: ['fitness_legend_aura', 'ultimate_trainer'],
            xp: 3000,
            gold: 7500,
            specialRewards: {
              'exclusive_title': 'Fitness Legend',
              'lifetime_fitness_bonus': 1.25,
              'legendary_workout_gear': true,
            },
            isExclusive: true,
          ),
        ),
      ],
      globalProgress: {
        'total_steps_worldwide': 15000000,
        'goal_steps_worldwide': 100000000,
        'total_calories_worldwide': 500000,
        'goal_calories_worldwide': 5000000,
      },
      metadata: {
        'charity_partner': 'Global Health Initiative',
        'real_world_rewards': true,
        'fitness_tracking_required': true,
      },
    ),

    // Community Card Collection Event
    GameEvent(
      name: 'The Grand Card Collector\'s Festival',
      description: 'The ultimate collection event! Rare cards are spawning everywhere. Collect, trade, and become a collection master!',
      type: EventType.collection,
      status: EventStatus.active,
      startTime: DateTime.now().subtract(Duration(days: 1)),
      endTime: DateTime.now().add(Duration(days: 14)),
      objectives: [
        EventObjective(
          title: 'Festival Collector',
          description: 'Collect 100 cards during the festival',
          type: 'collect_cards',
          requirements: {'card_count': 100},
          targetProgress: 100,
          reward: EventReward(
            name: 'Collector\'s Satchel',
            description: 'A magical satchel that increases card storage',
            tier: RewardTier.silver,
            cardIds: ['collectors_satchel', 'card_finder'],
            xp: 500,
            gold: 1000,
            specialRewards: {'storage_increase': 50},
          ),
        ),
        EventObjective(
          title: 'Rare Card Master',
          description: 'Collect 25 rare or higher cards',
          type: 'collect_rare_cards',
          requirements: {'rarity': 'rare_or_higher', 'count': 25},
          targetProgress: 25,
          reward: EventReward(
            name: 'Rare Card Magnet',
            description: 'Increases your chance of finding rare cards',
            tier: RewardTier.gold,
            cardIds: ['rare_card_magnet', 'fortune_crystal'],
            xp: 1000,
            gold: 2000,
            specialRewards: {'rare_card_chance_bonus': 0.15},
          ),
        ),
        EventObjective(
          title: 'Collection Completionist',
          description: 'Complete 3 full card sets during the event',
          type: 'complete_sets',
          requirements: {'completed_sets': 3},
          targetProgress: 3,
          reward: EventReward(
            name: 'Master Collector\'s Crown',
            description: 'The ultimate symbol of collection mastery',
            tier: RewardTier.diamond,
            cardIds: ['master_collectors_crown', 'set_completion_bonus'],
            xp: 2000,
            gold: 5000,
            specialRewards: {
              'exclusive_title': 'Grand Collector',
              'set_completion_bonus': 2.0,
              'collection_mastery_aura': true,
            },
            isExclusive: true,
          ),
        ),
      ],
      metadata: {
        'spawn_rate_boost': 2.5,
        'trading_event': true,
        'special_card_packs_available': true,
      },
    ),
  ];

  // Seasonal Events - Holiday celebrations throughout the year
  static List<GameEvent> get seasonalEvents => [
    // Halloween Spooktacular
    GameEvent(
      name: 'Halloween Spooktacular',
      description: 'The veil between realms grows thin! Collect spooky cards and battle shadow creatures in this frightfully fun event!',
      type: EventType.seasonal,
      status: EventStatus.upcoming,
      startTime: DateTime(DateTime.now().year, 10, 20),
      endTime: DateTime(DateTime.now().year, 11, 3),
      isRecurring: true,
      objectives: [
        EventObjective(
          title: 'Ghost Hunter',
          description: 'Defeat 31 shadow creatures',
          type: 'defeat_shadows',
          requirements: {'creature_type': 'shadow', 'count': 31},
          targetProgress: 31,
          reward: EventReward(
            name: 'Ghostbuster Badge',
            description: 'For brave souls who hunt the supernatural',
            tier: RewardTier.gold,
            cardIds: ['ghostbuster_badge', 'spirit_ward'],
            xp: 666,
            gold: 1313,
          ),
        ),
        EventObjective(
          title: 'Trick-or-Treat Master',
          description: 'Visit 100 locations during Halloween',
          type: 'visit_locations',
          requirements: {'location_visits': 100},
          targetProgress: 100,
          reward: EventReward(
            name: 'Halloween Harvest',
            description: 'A bag full of spooky treats and treasures',
            tier: RewardTier.platinum,
            cardIds: ['halloween_harvest', 'candy_power', 'spooky_spirit'],
            xp: 1000,
            gold: 2500,
            specialRewards: {'halloween_exclusive_items': true},
            isExclusive: true,
          ),
        ),
      ],
      metadata: {
        'theme': 'halloween',
        'special_spawns': ['ghost', 'vampire', 'werewolf', 'witch'],
        'night_bonus': 2.0,
      },
    ),

    // Summer Solstice Festival
    GameEvent(
      name: 'Summer Solstice Festival',
      description: 'Celebrate the longest day of the year with outdoor adventures and solar-powered rewards!',
      type: EventType.seasonal,
      status: EventStatus.upcoming,
      startTime: DateTime(DateTime.now().year, 6, 20),
      endTime: DateTime(DateTime.now().year, 6, 22),
      isRecurring: true,
      objectives: [
        EventObjective(
          title: 'Solar Powered',
          description: 'Spend 12 hours outdoors during the festival',
          type: 'outdoor_time',
          requirements: {'outdoor_hours': 12},
          targetProgress: 12,
          reward: EventReward(
            name: 'Solar Crown',
            description: 'Harness the power of the summer sun',
            tier: RewardTier.gold,
            cardIds: ['solar_crown', 'sun_energy', 'summer_spirit'],
            xp: 1200,
            gold: 3000,
          ),
        ),
      ],
      metadata: {
        'outdoor_focus': true,
        'solar_bonus': 3.0,
        'community_celebration': true,
      },
    ),
  ];

  // Guild Events - Team-based challenges
  static List<GameEvent> get guildEvents => [
    GameEvent(
      name: 'Guild War of Legends',
      description: 'Epic guild vs guild warfare! Battle for supremacy and legendary rewards!',
      type: EventType.guild,
      status: EventStatus.active,
      startTime: DateTime.now().subtract(Duration(hours: 12)),
      endTime: DateTime.now().add(Duration(days: 3)),
      objectives: [
        EventObjective(
          title: 'Guild Warriors',
          description: 'Guild members win 1000 battles combined',
          type: 'guild_battles',
          requirements: {'guild_battle_wins': 1000},
          targetProgress: 1000,
          reward: EventReward(
            name: 'Guild Victory Banner',
            description: 'A banner commemorating your guild\'s prowess in battle',
            tier: RewardTier.platinum,
            cardIds: ['guild_victory_banner', 'warrior_spirit'],
            xp: 2000,
            gold: 5000,
          ),
        ),
        EventObjective(
          title: 'Legendary Guild',
          description: 'Be in the top 10 guilds at event end',
          type: 'guild_ranking',
          requirements: {'final_rank': 10},
          targetProgress: 1,
          reward: EventReward(
            name: 'Legendary Guild Status',
            description: 'Eternal recognition as a legendary guild',
            tier: RewardTier.legendary,
            cardIds: ['legendary_guild_crest', 'eternal_glory'],
            xp: 5000,
            gold: 15000,
            specialRewards: {
              'legendary_guild_title': true,
              'permanent_guild_bonuses': true,
              'hall_of_fame_entry': true,
            },
            isExclusive: true,
          ),
        ),
      ],
      metadata: {
        'pvp_focus': true,
        'guild_required': true,
        'leaderboard_event': true,
      },
    ),
  ];

  // Charity Events - Real-world impact
  static List<GameEvent> get charityEvents => [
    GameEvent(
      name: 'Steps for Clean Water',
      description: 'Walk for a cause! Every step you take helps provide clean water to communities in need. Real steps, real impact!',
      type: EventType.charity,
      status: EventStatus.active,
      startTime: DateTime.now().subtract(Duration(days: 3)),
      endTime: DateTime.now().add(Duration(days: 18)),
      objectives: [
        EventObjective(
          title: 'Water Walker',
          description: 'Walk 50,000 steps for clean water',
          type: 'charity_steps',
          requirements: {'steps': 50000, 'charity': 'clean_water'},
          targetProgress: 50000,
          reward: EventReward(
            name: 'Clean Water Champion',
            description: 'Recognition for supporting clean water initiatives',
            tier: RewardTier.diamond,
            cardIds: ['clean_water_champion', 'purity_crystal', 'healing_waters'],
            xp: 2500,
            gold: 0, // Charity events focus on impact, not gold
            specialRewards: {
              'charity_impact_badge': true,
              'real_world_donation': true,
              'exclusive_title': 'Water Guardian',
            },
            isExclusive: true,
          ),
        ),
      ],
      globalProgress: {
        'total_steps_for_charity': 2500000,
        'goal_steps_for_charity': 10000000,
        'estimated_impact': '100 communities will receive clean water',
      },
      metadata: {
        'charity_partner': 'Water.org',
        'real_world_impact': true,
        'steps_to_dollar_conversion': 0.01, // 1 cent per 100 steps
      },
    ),
  ];

  // Special Limited Edition Events - Ultra rare, never returning
  static List<GameEvent> get limitedEditionEvents => [
    GameEvent(
      name: 'Realm of Valor Anniversary Celebration',
      description: 'Celebrating our first anniversary! Exclusive cards that will NEVER be available again!',
      type: EventType.limited_time,
      status: EventStatus.upcoming,
      startTime: DateTime.now().add(Duration(days: 30)),
      endTime: DateTime.now().add(Duration(days: 37)),
      objectives: [
        EventObjective(
          title: 'Anniversary Veteran',
          description: 'Complete 10 anniversary challenges',
          type: 'anniversary_challenges',
          requirements: {'anniversary_challenge_count': 10},
          targetProgress: 10,
          reward: EventReward(
            name: 'Anniversary Veteran Seal',
            description: 'Proof you were here for our first anniversary',
            tier: RewardTier.legendary,
            cardIds: ['anniversary_seal_2024', 'founders_tribute', 'legacy_crystal'],
            xp: 5000,
            gold: 10000,
            specialRewards: {
              'exclusive_title': 'Anniversary Veteran',
              'founder_status': true,
              'lifetime_anniversary_bonuses': true,
            },
            isExclusive: true,
            expiresAt: DateTime.now().add(Duration(days: 37)),
          ),
        ),
      ],
      metadata: {
        'never_returning': true,
        'ultra_rare_spawns': true,
        'anniversary_exclusive': true,
      },
    ),
  ];

  // Dynamic Event Generation
  static GameEvent generateRandomWeeklyEvent() {
    final random = math.Random();
    final eventTypes = [
      'fitness_challenge',
      'card_hunting',
      'exploration_quest',
      'community_goal',
    ];
    
    final eventType = eventTypes[random.nextInt(eventTypes.length)];
    final now = DateTime.now();
    
    switch (eventType) {
      case 'fitness_challenge':
        return GameEvent(
          name: 'Weekly Fitness Challenge',
          description: 'Stay active this week and earn amazing rewards!',
          type: EventType.fitness,
          status: EventStatus.active,
          startTime: now,
          endTime: now.add(Duration(days: 7)),
          objectives: [
            EventObjective(
              title: 'Active Week',
              description: 'Be active for 5 days this week',
              type: 'active_days',
              requirements: {'active_days': 5},
              targetProgress: 5,
              reward: EventReward(
                name: 'Weekly Warrior Badge',
                description: 'For staying active all week long',
                tier: RewardTier.silver,
                cardIds: ['weekly_warrior', 'endurance_boost'],
                xp: 300,
                gold: 750,
              ),
            ),
          ],
          isRecurring: true,
        );
        
      case 'card_hunting':
        return GameEvent(
          name: 'Rare Card Hunt',
          description: 'Rare cards are spawning more frequently! Go hunting!',
          type: EventType.collection,
          status: EventStatus.active,
          startTime: now,
          endTime: now.add(Duration(days: 3)),
          objectives: [
            EventObjective(
              title: 'Rare Hunter',
              description: 'Find 10 rare cards during the hunt',
              type: 'find_rare_cards',
              requirements: {'rare_cards': 10},
              targetProgress: 10,
              reward: EventReward(
                name: 'Rare Hunter Badge',
                description: 'Master of finding rare treasures',
                tier: RewardTier.gold,
                cardIds: ['rare_hunter_badge', 'treasure_finder'],
                xp: 500,
                gold: 1250,
              ),
            ),
          ],
          metadata: {'rare_spawn_boost': 2.0},
        );
        
      default:
        return GameEvent(
          name: 'Community Explorer Challenge',
          description: 'Explore your community and discover new locations!',
          type: EventType.exploration,
          status: EventStatus.active,
          startTime: now,
          endTime: now.add(Duration(days: 5)),
          objectives: [
            EventObjective(
              title: 'Local Explorer',
              description: 'Visit 20 new locations',
              type: 'visit_new_locations',
              requirements: {'new_locations': 20},
              targetProgress: 20,
              reward: EventReward(
                name: 'Explorer\'s Compass',
                description: 'Points you toward new adventures',
                tier: RewardTier.silver,
                cardIds: ['explorers_compass', 'adventure_spirit'],
                xp: 400,
                gold: 1000,
              ),
            ),
          ],
        );
    }
  }

  // Event Management Functions
  static List<GameEvent> getAllActiveEvents() {
    final allEvents = <GameEvent>[];
    allEvents.addAll(activeEvents);
    allEvents.addAll(seasonalEvents.where((e) => e.isActive));
    allEvents.addAll(guildEvents.where((e) => e.isActive));
    allEvents.addAll(charityEvents.where((e) => e.isActive));
    return allEvents;
  }

  static List<GameEvent> getEventsForPlayer(Map<String, dynamic> playerData) {
    final playerEvents = <GameEvent>[];
    
    // All players get general events
    playerEvents.addAll(activeEvents);
    
    // Guild members get guild events
    if (playerData['guild_id'] != null) {
      playerEvents.addAll(guildEvents.where((e) => e.isActive));
    }
    
    // Fitness enthusiasts get extra fitness events
    if ((playerData['fitness_level'] ?? 0) > 10) {
      playerEvents.addAll(charityEvents.where((e) => e.type == EventType.fitness));
    }
    
    // High-level players get exclusive events
    if ((playerData['level'] ?? 0) > 50) {
      playerEvents.addAll(limitedEditionEvents.where((e) => e.isActive));
    }
    
    return playerEvents;
  }

  static Map<String, dynamic> calculateEventProgress(GameEvent event, Map<String, dynamic> playerStats) {
    final progress = <String, dynamic>{};
    
    for (final objective in event.objectives) {
      final currentProgress = _calculateObjectiveProgress(objective, playerStats);
      progress[objective.id] = {
        'current': currentProgress,
        'target': objective.targetProgress,
        'percentage': (currentProgress / objective.targetProgress * 100).clamp(0, 100),
        'completed': currentProgress >= objective.targetProgress,
      };
    }
    
    return progress;
  }

  static int _calculateObjectiveProgress(EventObjective objective, Map<String, dynamic> playerStats) {
    switch (objective.type) {
      case 'defeat_dragons':
        return playerStats['dragons_defeated'] ?? 0;
      case 'collect_dragons':
        return playerStats['dragon_cards_collected'] ?? 0;
      case 'fitness_steps':
        return playerStats['event_steps'] ?? 0;
      case 'fitness_calories':
        return playerStats['event_calories'] ?? 0;
      case 'collect_cards':
        return playerStats['event_cards_collected'] ?? 0;
      case 'visit_locations':
        return playerStats['event_locations_visited'] ?? 0;
      case 'guild_battles':
        return playerStats['guild_battle_wins'] ?? 0;
      case 'charity_steps':
        return playerStats['charity_steps'] ?? 0;
      default:
        return 0;
    }
  }

  // Event Notifications
  static List<Map<String, dynamic>> getEventNotifications(List<GameEvent> playerEvents) {
    final notifications = <Map<String, dynamic>>[];
    final now = DateTime.now();
    
    for (final event in playerEvents) {
      // Starting soon notifications
      if (event.status == EventStatus.upcoming && 
          event.startTime.difference(now).inHours <= 24) {
        notifications.add({
          'type': 'event_starting_soon',
          'title': '${event.name} Starts Soon!',
          'message': 'Get ready! ${event.name} begins in ${event.startTime.difference(now).inHours} hours!',
          'event_id': event.id,
          'priority': 'high',
        });
      }
      
      // Ending soon notifications
      if (event.status == EventStatus.ending_soon || 
          (event.isActive && event.timeRemaining.inHours <= 24)) {
        notifications.add({
          'type': 'event_ending_soon',
          'title': 'Last Chance: ${event.name}',
          'message': 'Only ${event.timeRemaining.inHours} hours left! Don\'t miss out on exclusive rewards!',
          'event_id': event.id,
          'priority': 'urgent',
        });
      }
      
      // New event notifications
      if (event.isActive && event.timeSinceStart.inHours <= 2) {
        notifications.add({
          'type': 'new_event_available',
          'title': 'New Event: ${event.name}',
          'message': event.description,
          'event_id': event.id,
          'priority': 'medium',
        });
      }
    }
    
    return notifications;
  }

  // Exclusive Reward System
  static List<EventReward> getExclusiveRewards() {
    final exclusiveRewards = <EventReward>[];
    
    for (final event in getAllActiveEvents()) {
      for (final objective in event.objectives) {
        if (objective.reward?.isExclusive == true) {
          exclusiveRewards.add(objective.reward!);
        }
      }
      
      for (final reward in event.rewards) {
        if (reward.isExclusive) {
          exclusiveRewards.add(reward);
        }
      }
    }
    
    return exclusiveRewards;
  }

  // Community Progress Tracking
  static Map<String, dynamic> getCommunityProgress() {
    return {
      'dragon_awakening': {
        'dragons_defeated_worldwide': 250000,
        'goal_dragons_worldwide': 1000000,
        'progress_percentage': 25.0,
        'estimated_completion': 'in 5 days',
      },
      'fitness_revolution': {
        'total_steps_worldwide': 15000000,
        'goal_steps_worldwide': 100000000,
        'progress_percentage': 15.0,
        'estimated_completion': 'in 20 days',
      },
      'charity_water': {
        'steps_for_charity': 2500000,
        'goal_steps_charity': 10000000,
        'progress_percentage': 25.0,
        'estimated_impact': '250 communities will receive clean water',
      },
    };
  }

  // Event Leaderboards
  static Map<String, dynamic> getEventLeaderboards(String eventId) {
    // Mock leaderboard data - would come from server in real implementation
    return {
      'top_players': [
        {'rank': 1, 'username': 'DragonSlayer2024', 'score': 15420, 'title': 'Dragon Emperor'},
        {'rank': 2, 'username': 'FitnessLegend', 'score': 14890, 'title': 'Fitness Master'},
        {'rank': 3, 'username': 'CardCollector', 'score': 14200, 'title': 'Grand Collector'},
        {'rank': 4, 'username': 'ExplorerExtraordinaire', 'score': 13850, 'title': 'World Walker'},
        {'rank': 5, 'username': 'GuildLeaderSupreme', 'score': 13500, 'title': 'Guild Champion'},
      ],
      'top_guilds': [
        {'rank': 1, 'guild_name': 'Dragon Hunters Elite', 'score': 89400, 'members': 50},
        {'rank': 2, 'guild_name': 'Fitness Warriors', 'score': 87200, 'members': 45},
        {'rank': 3, 'guild_name': 'Card Masters United', 'score': 84800, 'members': 42},
      ],
      'player_rank': 156,
      'guild_rank': 23,
    };
  }
}