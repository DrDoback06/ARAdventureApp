import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'dart:math' as math;

part 'adventure_system.g.dart';

enum QuestType {
  exploration,
  fitness,
  social,
  collection,
  battle,
  treasure,
  seasonal,
  daily,
  weekly,
  legendary,
}

enum LocationType {
  park,
  gym,
  restaurant,
  business,
  monument,
  bridge,
  library,
  school,
  hospital,
  church,
  mall,
  beach,
  mountain,
  trail,
  other,
}

enum POIType {
  fitness,
  social,
  spiritual,
  nature,
  education,
  shopping,
  medical,
  entertainment,
  generic,
}

enum SpawnType {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  boss,
  treasure,
  portal,
  merchant,
  guild,
}

@JsonSerializable()
class GeoLocation {
  final String? id;
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final DateTime timestamp;

  GeoLocation({
    this.id,
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory GeoLocation.fromJson(Map<String, dynamic> json) =>
      _$GeoLocationFromJson(json);
  Map<String, dynamic> toJson() => _$GeoLocationToJson(this);

  // Calculate distance between two locations in meters
  double distanceTo(GeoLocation other) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    final lat1Rad = latitude * (3.141592653589793 / 180);
    final lat2Rad = other.latitude * (3.141592653589793 / 180);
    final deltaLatRad = (other.latitude - latitude) * (3.141592653589793 / 180);
    final deltaLonRad = (other.longitude - longitude) * (3.141592653589793 / 180);

    final a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLonRad / 2) * math.sin(deltaLonRad / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }
}

@JsonSerializable()
class QuestObjective {
  final String id;
  final String title;
  final String description;
  final String type;
  final Map<String, dynamic> requirements;
  final Map<String, dynamic> progress;
  final bool isCompleted;
  final int xpReward;
  final List<String> itemRewards;

  QuestObjective({
    String? id,
    required this.title,
    required this.description,
    required this.type,
    Map<String, dynamic>? requirements,
    Map<String, dynamic>? progress,
    this.isCompleted = false,
    this.xpReward = 0,
    List<String>? itemRewards,
  }) : id = id ?? const Uuid().v4(),
       requirements = requirements ?? {},
       progress = progress ?? {},
       itemRewards = itemRewards ?? [];

  factory QuestObjective.fromJson(Map<String, dynamic> json) =>
      _$QuestObjectiveFromJson(json);
  Map<String, dynamic> toJson() => _$QuestObjectiveToJson(this);

  QuestObjective copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    Map<String, dynamic>? requirements,
    Map<String, dynamic>? progress,
    bool? isCompleted,
    int? xpReward,
    List<String>? itemRewards,
  }) {
    return QuestObjective(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      requirements: requirements ?? this.requirements,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      xpReward: xpReward ?? this.xpReward,
      itemRewards: itemRewards ?? this.itemRewards,
    );
  }
}

@JsonSerializable()
class Quest {
  final String id;
  final String title;
  final String description;
  final QuestType type;
  final int level;
  final GeoLocation? location;
  final double? radius;
  final List<QuestObjective> objectives;
  final Map<String, dynamic> rewards;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isActive;
  final bool isCompleted;
  final int xpReward;
  final List<String> cardRewards;
  final Map<String, dynamic> metadata;

  Quest({
    String? id,
    required this.title,
    required this.description,
    required this.type,
    this.level = 1,
    this.location,
    this.radius,
    List<QuestObjective>? objectives,
    Map<String, dynamic>? rewards,
    this.startTime,
    this.endTime,
    this.isActive = true,
    this.isCompleted = false,
    this.xpReward = 0,
    List<String>? cardRewards,
    Map<String, dynamic>? metadata,
  }) : id = id ?? const Uuid().v4(),
       objectives = objectives ?? [],
       rewards = rewards ?? {},
       cardRewards = cardRewards ?? [],
       metadata = metadata ?? {};

  factory Quest.fromJson(Map<String, dynamic> json) =>
      _$QuestFromJson(json);
  Map<String, dynamic> toJson() => _$QuestToJson(this);

  Quest copyWith({
    String? id,
    String? title,
    String? description,
    QuestType? type,
    int? level,
    GeoLocation? location,
    double? radius,
    List<QuestObjective>? objectives,
    Map<String, dynamic>? rewards,
    DateTime? startTime,
    DateTime? endTime,
    bool? isActive,
    bool? isCompleted,
    int? xpReward,
    List<String>? cardRewards,
    Map<String, dynamic>? metadata,
  }) {
    return Quest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      level: level ?? this.level,
      location: location ?? this.location,
      radius: radius ?? this.radius,
      objectives: objectives ?? this.objectives,
      rewards: rewards ?? this.rewards,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
      isCompleted: isCompleted ?? this.isCompleted,
      xpReward: xpReward ?? this.xpReward,
      cardRewards: cardRewards ?? this.cardRewards,
      metadata: metadata ?? this.metadata,
    );
  }
}

@JsonSerializable()
class WorldSpawn {
  final String id;
  final String name;
  final String description;
  final SpawnType type;
  final GeoLocation location;
  final double radius;
  final DateTime spawnTime;
  final DateTime? despawnTime;
  final int level;
  final List<String> availableCards;
  final Map<String, dynamic> rewards;
  final bool isActive;
  final int maxInteractions;
  final int currentInteractions;
  final Map<String, dynamic> metadata;

  WorldSpawn({
    String? id,
    required this.name,
    required this.description,
    required this.type,
    required this.location,
    this.radius = 50.0,
    DateTime? spawnTime,
    this.despawnTime,
    this.level = 1,
    List<String>? availableCards,
    Map<String, dynamic>? rewards,
    this.isActive = true,
    this.maxInteractions = 10,
    this.currentInteractions = 0,
    Map<String, dynamic>? metadata,
  }) : id = id ?? const Uuid().v4(),
       spawnTime = spawnTime ?? DateTime.now(),
       availableCards = availableCards ?? [],
       rewards = rewards ?? {},
       metadata = metadata ?? {};

  factory WorldSpawn.fromJson(Map<String, dynamic> json) =>
      _$WorldSpawnFromJson(json);
  Map<String, dynamic> toJson() => _$WorldSpawnToJson(this);

  WorldSpawn copyWith({
    String? id,
    String? name,
    String? description,
    SpawnType? type,
    GeoLocation? location,
    double? radius,
    DateTime? spawnTime,
    DateTime? despawnTime,
    int? level,
    List<String>? availableCards,
    Map<String, dynamic>? rewards,
    bool? isActive,
    int? maxInteractions,
    int? currentInteractions,
    Map<String, dynamic>? metadata,
  }) {
    return WorldSpawn(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      location: location ?? this.location,
      radius: radius ?? this.radius,
      spawnTime: spawnTime ?? this.spawnTime,
      despawnTime: despawnTime ?? this.despawnTime,
      level: level ?? this.level,
      availableCards: availableCards ?? this.availableCards,
      rewards: rewards ?? this.rewards,
      isActive: isActive ?? this.isActive,
      maxInteractions: maxInteractions ?? this.maxInteractions,
      currentInteractions: currentInteractions ?? this.currentInteractions,
      metadata: metadata ?? this.metadata,
    );
  }
}

@JsonSerializable()
class POI {
  final String id;
  final String name;
  final String description;
  final LocationType type;
  final GeoLocation location;
  final double radius;
  final bool isActive;
  final Map<String, dynamic> properties;
  final List<String> associatedQuests;
  final List<String> spawnHistory;
  final double popularity;
  final DateTime createdAt;
  final DateTime? lastVisited;

  POI({
    String? id,
    required this.name,
    required this.description,
    required this.type,
    required this.location,
    this.radius = 100.0,
    this.isActive = true,
    Map<String, dynamic>? properties,
    List<String>? associatedQuests,
    List<String>? spawnHistory,
    this.popularity = 0.0,
    DateTime? createdAt,
    this.lastVisited,
  }) : id = id ?? const Uuid().v4(),
       properties = properties ?? {},
       associatedQuests = associatedQuests ?? [],
       spawnHistory = spawnHistory ?? [],
       createdAt = createdAt ?? DateTime.now();

  factory POI.fromJson(Map<String, dynamic> json) =>
      _$POIFromJson(json);
  Map<String, dynamic> toJson() => _$POIToJson(this);

  POI copyWith({
    String? id,
    String? name,
    String? description,
    LocationType? type,
    GeoLocation? location,
    double? radius,
    bool? isActive,
    Map<String, dynamic>? properties,
    List<String>? associatedQuests,
    List<String>? spawnHistory,
    double? popularity,
    DateTime? createdAt,
    DateTime? lastVisited,
  }) {
    return POI(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      location: location ?? this.location,
      radius: radius ?? this.radius,
      isActive: isActive ?? this.isActive,
      properties: properties ?? this.properties,
      associatedQuests: associatedQuests ?? this.associatedQuests,
      spawnHistory: spawnHistory ?? this.spawnHistory,
      popularity: popularity ?? this.popularity,
      createdAt: createdAt ?? this.createdAt,
      lastVisited: lastVisited ?? this.lastVisited,
    );
  }
}

@JsonSerializable()
class PointOfInterest {
  final String id;
  final String name;
  final String description;
  final GeoLocation location;
  final POIType type;
  final String category;
  final double rating;
  bool isDiscovered;
  DateTime? discoveredAt;
  final double questPotential;
  final Map<String, dynamic> metadata;

  PointOfInterest({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.type,
    required this.category,
    required this.rating,
    required this.isDiscovered,
    required this.discoveredAt,
    required this.questPotential,
    required this.metadata,
  });

  factory PointOfInterest.fromJson(Map<String, dynamic> json) =>
      _$PointOfInterestFromJson(json);
  Map<String, dynamic> toJson() => _$PointOfInterestToJson(this);
}

@JsonSerializable()
class LocationQuest {
  final String id;
  final String title;
  final String description;
  final PointOfInterest location;
  final String questType;
  final String difficulty;
  final int experienceReward;
  final List<String> requirements;
  final List<QuestObjective>? objectives;

  LocationQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.questType,
    required this.difficulty,
    required this.experienceReward,
    required this.requirements,
    this.objectives,
  });

  factory LocationQuest.fromJson(Map<String, dynamic> json) =>
      _$LocationQuestFromJson(json);
  Map<String, dynamic> toJson() => _$LocationQuestToJson(this);
}

@JsonSerializable()
class StravaSegment {
  final String id;
  final String name;
  final String activityType;
  final double distance;
  final double averageGrade;
  final double maximumGrade;
  final double elevationHigh;
  final double elevationLow;
  final double startLatitude;
  final double startLongitude;
  final double endLatitude;
  final double endLongitude;
  final int climbCategory;
  final String city;
  final String state;
  final String country;
  final bool hazardous;
  final int starCount;
  final int effortCount;
  final String polyline;
  final SegmentLeaderboard kom;
  final SegmentLeaderboard qom;

  StravaSegment({
    required this.id,
    required this.name,
    required this.activityType,
    required this.distance,
    required this.averageGrade,
    required this.maximumGrade,
    required this.elevationHigh,
    required this.elevationLow,
    required this.startLatitude,
    required this.startLongitude,
    required this.endLatitude,
    required this.endLongitude,
    required this.climbCategory,
    required this.city,
    required this.state,
    required this.country,
    required this.hazardous,
    required this.starCount,
    required this.effortCount,
    required this.polyline,
    required this.kom,
    required this.qom,
  });

  factory StravaSegment.fromJson(Map<String, dynamic> json) =>
      _$StravaSegmentFromJson(json);
  Map<String, dynamic> toJson() => _$StravaSegmentToJson(this);
}

@JsonSerializable()
class SegmentLeaderboard {
  final String athleteName;
  final int elapsedTime;
  final DateTime dateAchieved;

  SegmentLeaderboard({
    required this.athleteName,
    required this.elapsedTime,
    required this.dateAchieved,
  });

  factory SegmentLeaderboard.fromJson(Map<String, dynamic> json) =>
      _$SegmentLeaderboardFromJson(json);
  Map<String, dynamic> toJson() => _$SegmentLeaderboardToJson(this);
}

@JsonSerializable()
class StravaRoute {
  final String id;
  final String name;
  final String description;
  final double distance;
  final double elevationGain;
  final String type;
  final String surfaceType;
  final List<GeoLocation> waypoints;
  final bool isPrivate;
  final int starCount;
  final StravaAthlete? athlete;
  final int? estimatedMovingTime;
  final String? polyline;

  StravaRoute({
    required this.id,
    required this.name,
    required this.description,
    required this.distance,
    required this.elevationGain,
    required this.type,
    required this.surfaceType,
    required this.waypoints,
    required this.isPrivate,
    required this.starCount,
    this.athlete,
    this.estimatedMovingTime,
    this.polyline,
  });

  factory StravaRoute.fromJson(Map<String, dynamic> json) =>
      _$StravaRouteFromJson(json);
  Map<String, dynamic> toJson() => _$StravaRouteToJson(this);
}

@JsonSerializable()
class StravaAthlete {
  final String id;
  final String firstName;
  final String lastName;
  final String? profileMedium;

  StravaAthlete({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profileMedium,
  });

  factory StravaAthlete.fromJson(Map<String, dynamic> json) =>
      _$StravaAthleteFromJson(json);
  Map<String, dynamic> toJson() => _$StravaAthleteToJson(this);
}

@JsonSerializable()
class TrailQuest {
  final String id;
  final String title;
  final String description;
  final String segmentId;
  final String segmentName;
  final double distance;
  final double elevationGain;
  final double averageGrade;
  final String difficulty;
  final String questType;
  final GeoLocation startLocation;
  final GeoLocation endLocation;
  final String polyline;
  final int experienceReward;
  final List<QuestObjective> objectives;
  final List<String> rewards;
  final SegmentLeaderboard kom;
  final SegmentLeaderboard qom;
  final int effortCount;
  final int starCount;
  final bool isHazardous;
  final int climbCategory;

  TrailQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.segmentId,
    required this.segmentName,
    required this.distance,
    required this.elevationGain,
    required this.averageGrade,
    required this.difficulty,
    required this.questType,
    required this.startLocation,
    required this.endLocation,
    required this.polyline,
    required this.experienceReward,
    required this.objectives,
    required this.rewards,
    required this.kom,
    required this.qom,
    required this.effortCount,
    required this.starCount,
    required this.isHazardous,
    required this.climbCategory,
  });

  factory TrailQuest.fromJson(Map<String, dynamic> json) =>
      _$TrailQuestFromJson(json);
  Map<String, dynamic> toJson() => _$TrailQuestToJson(this);
}

@JsonSerializable()
class ActivityReward {
  final String id;
  final String activityId;
  final String activityName;
  final String activityType;
  final int experienceGained;
  final int goldGained;
  final List<String> itemsEarned;
  final double distanceCovered;
  final int caloriesBurned;
  final List<String> achievementsUnlocked;
  final DateTime completedAt;

  ActivityReward({
    required this.id,
    required this.activityId,
    required this.activityName,
    required this.activityType,
    required this.experienceGained,
    required this.goldGained,
    required this.itemsEarned,
    required this.distanceCovered,
    required this.caloriesBurned,
    required this.achievementsUnlocked,
    required this.completedAt,
  });

  factory ActivityReward.fromJson(Map<String, dynamic> json) =>
      _$ActivityRewardFromJson(json);
  Map<String, dynamic> toJson() => _$ActivityRewardToJson(this);
}

class AdventureSystem {
  // Pre-defined amazing quests
  static List<Quest> get epicQuests => [
    Quest(
      title: 'The Dragon\'s Treasure Hunt',
      description: 'Legends speak of an ancient dragon\'s hoard hidden in your city. Follow the clues and visit 5 different parks to uncover pieces of the treasure map!',
      type: QuestType.treasure,
      level: 5,
      radius: 5000,
      xpReward: 500,
      cardRewards: ['ancient_dragon', 'dragon_scale_armor', 'treasure_map'],
      objectives: [
        QuestObjective(
          title: 'Visit the First Sanctuary',
          description: 'Find and visit a park to discover the first clue',
          type: 'location_visit',
          requirements: {'location_type': 'park', 'count': 1},
          xpReward: 100,
          itemRewards: ['treasure_map_piece_1'],
        ),
        QuestObjective(
          title: 'Walk the Ancient Path',
          description: 'Walk 2 kilometers while exploring to awaken the dragon\'s magic',
          type: 'distance',
          requirements: {'distance': 2000},
          xpReward: 100,
        ),
        QuestObjective(
          title: 'Gather the Sacred Five',
          description: 'Visit 5 different parks to complete the treasure map',
          type: 'location_visit',
          requirements: {'location_type': 'park', 'count': 5, 'unique': true},
          xpReward: 200,
          itemRewards: ['treasure_map_complete'],
        ),
      ],
    ),
    Quest(
      title: 'The Merchant\'s Journey',
      description: 'Help a traveling merchant by visiting businesses around town. Each location holds valuable trade goods!',
      type: QuestType.exploration,
      level: 3,
      radius: 3000,
      xpReward: 300,
      cardRewards: ['merchant_pack', 'trade_goods', 'gold_coins'],
      objectives: [
        QuestObjective(
          title: 'Visit the Marketplace',
          description: 'Find and visit 3 different businesses',
          type: 'location_visit',
          requirements: {'location_type': 'business', 'count': 3},
          xpReward: 150,
          itemRewards: ['trade_goods'],
        ),
        QuestObjective(
          title: 'The Fitness Challenge',
          description: 'Burn 200 calories while exploring',
          type: 'calories',
          requirements: {'calories': 200},
          xpReward: 150,
        ),
      ],
    ),
    Quest(
      title: 'Guardian of the Realm',
      description: 'Protect the realm by defeating shadow creatures that spawn near monuments and landmarks!',
      type: QuestType.battle,
      level: 7,
      radius: 10000,
      xpReward: 750,
      cardRewards: ['guardian_sword', 'light_armor', 'shadow_wraith'],
      objectives: [
        QuestObjective(
          title: 'Seek the Ancient Monuments',
          description: 'Visit 3 monuments or landmarks to find shadow creatures',
          type: 'location_visit',
          requirements: {'location_type': 'monument', 'count': 3},
          xpReward: 200,
        ),
        QuestObjective(
          title: 'Battle the Darkness',
          description: 'Defeat 5 shadow creatures in battle',
          type: 'battle',
          requirements: {'enemy_type': 'shadow', 'count': 5},
          xpReward: 300,
          itemRewards: ['shadow_essence'],
        ),
        QuestObjective(
          title: 'The Guardian\'s Trial',
          description: 'Take 10,000 steps to prove your dedication',
          type: 'steps',
          requirements: {'steps': 10000},
          xpReward: 250,
        ),
      ],
    ),
  ];

  static List<Quest> get dailyQuests => [
    Quest(
      title: 'Morning Explorer',
      description: 'Start your day with adventure! Visit any location and take 1000 steps.',
      type: QuestType.daily,
      level: 1,
      xpReward: 100,
      cardRewards: ['health_potion', 'explorer_boots'],
      endTime: DateTime.now().add(Duration(hours: 24)),
      objectives: [
        QuestObjective(
          title: 'Take Your First Steps',
          description: 'Take 1000 steps to begin your adventure',
          type: 'steps',
          requirements: {'steps': 1000},
          xpReward: 50,
        ),
        QuestObjective(
          title: 'Discover a Location',
          description: 'Visit any point of interest',
          type: 'location_visit',
          requirements: {'any_location': true, 'count': 1},
          xpReward: 50,
          itemRewards: ['explorer_compass'],
        ),
      ],
    ),
    Quest(
      title: 'Fitness Warrior',
      description: 'Prove your strength by burning calories and staying active!',
      type: QuestType.fitness,
      level: 2,
      xpReward: 150,
      cardRewards: ['strength_potion', 'warrior_training'],
      endTime: DateTime.now().add(Duration(hours: 24)),
      objectives: [
        QuestObjective(
          title: 'Burn Energy',
          description: 'Burn 150 calories through activity',
          type: 'calories',
          requirements: {'calories': 150},
          xpReward: 100,
        ),
        QuestObjective(
          title: 'Stay Active',
          description: 'Be active for 30 minutes total',
          type: 'active_time',
          requirements: {'minutes': 30},
          xpReward: 50,
        ),
      ],
    ),
  ];

  static List<Quest> get weeklyQuests => [
    Quest(
      title: 'Master Explorer',
      description: 'Become a true explorer by visiting diverse locations and staying active all week!',
      type: QuestType.weekly,
      level: 4,
      xpReward: 1000,
      cardRewards: ['master_explorer_badge', 'legendary_compass', 'adventure_pack'],
      endTime: DateTime.now().add(Duration(days: 7)),
      objectives: [
        QuestObjective(
          title: 'Visit the Diverse Realm',
          description: 'Visit 5 different types of locations',
          type: 'location_variety',
          requirements: {'unique_types': 5},
          xpReward: 300,
        ),
        QuestObjective(
          title: 'The Weekly Challenge',
          description: 'Walk 25 kilometers this week',
          type: 'distance',
          requirements: {'distance': 25000},
          xpReward: 400,
        ),
        QuestObjective(
          title: 'Treasure Hunter',
          description: 'Collect 10 different item cards',
          type: 'collection',
          requirements: {'unique_items': 10},
          xpReward: 300,
        ),
      ],
    ),
  ];

  // Location-based spawns
  static List<WorldSpawn> generateSpawnsForLocation(GeoLocation location, LocationType type) {
    final spawns = <WorldSpawn>[];
    final now = DateTime.now();

    switch (type) {
      case LocationType.park:
        spawns.addAll([
          WorldSpawn(
            name: 'Mystical Grove',
            description: 'A magical grove where nature spirits dwell',
            type: SpawnType.common,
            location: location,
            radius: 75,
            availableCards: ['elvish_bow', 'nature_spirit', 'healing_herbs'],
            rewards: {'xp': 50, 'gold': 25},
            despawnTime: now.add(Duration(hours: 4)),
          ),
          WorldSpawn(
            name: 'Ancient Tree Portal',
            description: 'An ancient tree that serves as a portal to other realms',
            type: SpawnType.rare,
            location: location,
            radius: 50,
            availableCards: ['portal_key', 'ancient_wisdom', 'tree_guardian'],
            rewards: {'xp': 150, 'gold': 75},
            maxInteractions: 3,
            despawnTime: now.add(Duration(hours: 8)),
          ),
        ]);
        break;

      case LocationType.gym:
        spawns.addAll([
          WorldSpawn(
            name: 'Training Grounds',
            description: 'Where warriors come to hone their skills',
            type: SpawnType.common,
            location: location,
            radius: 100,
            availableCards: ['training_weights', 'strength_potion', 'warrior_spirit'],
            rewards: {'xp': 75, 'gold': 35},
            despawnTime: now.add(Duration(hours: 6)),
          ),
          WorldSpawn(
            name: 'Champion\'s Arena',
            description: 'Face the ultimate fitness challenge',
            type: SpawnType.epic,
            location: location,
            radius: 75,
            availableCards: ['champion_belt', 'victory_crown', 'ultimate_training'],
            rewards: {'xp': 300, 'gold': 150},
            maxInteractions: 5,
            despawnTime: now.add(Duration(hours: 12)),
          ),
        ]);
        break;

      case LocationType.monument:
        spawns.addAll([
          WorldSpawn(
            name: 'Ancient Guardian',
            description: 'The spirit of an ancient guardian protects this place',
            type: SpawnType.legendary,
            location: location,
            radius: 60,
            availableCards: ['guardian_sword', 'ancient_shield', 'spirit_blessing'],
            rewards: {'xp': 500, 'gold': 250},
            maxInteractions: 2,
            despawnTime: now.add(Duration(hours: 24)),
          ),
        ]);
        break;

      case LocationType.business:
        spawns.addAll([
          WorldSpawn(
            name: 'Traveling Merchant',
            description: 'A merchant with exotic goods from distant lands',
            type: SpawnType.uncommon,
            location: location,
            radius: 50,
            availableCards: ['exotic_goods', 'trade_coins', 'merchant_map'],
            rewards: {'xp': 100, 'gold': 50},
            despawnTime: now.add(Duration(hours: 3)),
          ),
        ]);
        break;

      default:
        spawns.add(
          WorldSpawn(
            name: 'Mysterious Presence',
            description: 'Something mysterious lingers in this area',
            type: SpawnType.common,
            location: location,
            radius: 50,
            availableCards: ['mystery_box', 'unknown_artifact'],
            rewards: {'xp': 25, 'gold': 15},
            despawnTime: now.add(Duration(hours: 2)),
          ),
        );
    }

    return spawns;
  }

  // Quest generation based on location
  static List<Quest> generateQuestsForLocation(GeoLocation location, LocationType type) {
    final quests = <Quest>[];
    final now = DateTime.now();

    switch (type) {
      case LocationType.park:
        quests.add(
          Quest(
            title: 'Nature\'s Blessing',
            description: 'Spend time in nature to restore your spirit and gain nature\'s blessing',
            type: QuestType.fitness,
            level: 1,
            location: location,
            radius: 200,
            xpReward: 200,
            cardRewards: ['nature_blessing', 'forest_spirit'],
            endTime: now.add(Duration(hours: 6)),
            objectives: [
              QuestObjective(
                title: 'Embrace Nature',
                description: 'Stay in the park for 15 minutes',
                type: 'location_time',
                requirements: {'time_minutes': 15},
                xpReward: 100,
              ),
              QuestObjective(
                title: 'Nature Walk',
                description: 'Take 500 steps while in the park',
                type: 'location_steps',
                requirements: {'steps': 500},
                xpReward: 100,
              ),
            ],
          ),
        );
        break;

      case LocationType.gym:
        quests.add(
          Quest(
            title: 'Strength Training',
            description: 'Push your limits at the gym to unlock your true potential',
            type: QuestType.fitness,
            level: 3,
            location: location,
            radius: 150,
            xpReward: 300,
            cardRewards: ['strength_boost', 'gym_membership'],
            endTime: now.add(Duration(hours: 8)),
            objectives: [
              QuestObjective(
                title: 'Workout Session',
                description: 'Burn 200 calories during your gym session',
                type: 'location_calories',
                requirements: {'calories': 200},
                xpReward: 150,
              ),
              QuestObjective(
                title: 'Dedication',
                description: 'Spend 45 minutes at the gym',
                type: 'location_time',
                requirements: {'time_minutes': 45},
                xpReward: 150,
              ),
            ],
          ),
        );
        break;

      default:
        break;
    }

    return quests;
  }

  // Reward calculation based on activity
  static Map<String, dynamic> calculateRewards(Map<String, dynamic> activity) {
    final rewards = <String, dynamic>{};
    final baseXP = 10;
    final baseGold = 5;
    
    // Steps reward
    final steps = activity['steps'] ?? 0;
    rewards['xp'] = baseXP + (steps / 100).floor();
    rewards['gold'] = baseGold + (steps / 200).floor();
    
    // Distance reward
    final distance = activity['distance'] ?? 0.0;
    rewards['xp'] = (rewards['xp'] ?? 0) + (distance / 100).floor();
    rewards['gold'] = (rewards['gold'] ?? 0) + (distance / 200).floor();
    
    // Calories reward
    final calories = activity['calories'] ?? 0;
    rewards['xp'] = (rewards['xp'] ?? 0) + (calories / 10).floor();
    rewards['gold'] = (rewards['gold'] ?? 0) + (calories / 20).floor();
    
    // Time bonus
    final activeTime = activity['active_time'] ?? 0;
    if (activeTime > 30) {
      rewards['xp'] = (rewards['xp'] ?? 0) + 50;
      rewards['gold'] = (rewards['gold'] ?? 0) + 25;
    }
    
    return rewards;
  }

  // Special seasonal events
  static List<Quest> get seasonalQuests => [
    Quest(
      title: 'Winter Solstice Adventure',
      description: 'Celebrate the longest night with a magical winter quest!',
      type: QuestType.seasonal,
      level: 5,
      xpReward: 1000,
      cardRewards: ['winter_crown', 'frost_sword', 'snow_spirit'],
      startTime: DateTime(DateTime.now().year, 12, 21),
      endTime: DateTime(DateTime.now().year, 12, 25),
      objectives: [
        QuestObjective(
          title: 'Embrace the Cold',
          description: 'Stay active outdoors for 2 hours during winter',
          type: 'outdoor_time',
          requirements: {'hours': 2, 'season': 'winter'},
          xpReward: 500,
        ),
        QuestObjective(
          title: 'Light in the Darkness',
          description: 'Visit 7 different locations to spread light',
          type: 'location_visit',
          requirements: {'count': 7, 'unique': true},
          xpReward: 500,
        ),
      ],
    ),
  ];
}