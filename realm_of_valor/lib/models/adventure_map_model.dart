import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'quest_model.dart';

// part 'adventure_map_model.g.dart';

enum LocationType {
  trail,
  business,
  pub,
  park,
  poi,
  runningTrack,
  gym,
  historicalSite,
  viewpoint,
  communityCenter,
  restaurant,
  cafe,
  shop,
  landmark,
  eventVenue,
  sportsFacility,
  outdoorActivity,
  culturalSite,
  naturalWonder,
  urbanExploration,
}

enum LocationStatus {
  active,
  inactive,
  seasonal,
  eventOnly,
  maintenance,
}

enum WeatherCondition {
  sunny,
  cloudy,
  rainy,
  snowy,
  stormy,
  foggy,
  windy,
  clear,
  overcast,
}

@JsonSerializable()
class MapLocation {
  final String id;
  final String name;
  final String description;
  final String address;
  final double latitude;
  final double longitude;
  final LocationType type;
  final LocationStatus status;
  final List<String> tags;
  final Map<String, dynamic> properties;
  final String? imageUrl;
  final String? websiteUrl;
  final String? phoneNumber;
  final double? rating;
  final int? reviewCount;
  final List<String> amenities;
  final Map<String, dynamic> businessInfo;
  final DateTime? lastUpdated;
  final bool isVerified;
  final String? createdBy;
  final List<String> questIds;
  final Map<String, dynamic> weatherEffects;
  final Map<String, dynamic> accessibilityInfo;

  MapLocation({
    String? id,
    required this.name,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.status = LocationStatus.active,
    List<String>? tags,
    Map<String, dynamic>? properties,
    this.imageUrl,
    this.websiteUrl,
    this.phoneNumber,
    this.rating,
    this.reviewCount,
    List<String>? amenities,
    Map<String, dynamic>? businessInfo,
    this.lastUpdated,
    this.isVerified = false,
    this.createdBy,
    List<String>? questIds,
    Map<String, dynamic>? weatherEffects,
    Map<String, dynamic>? accessibilityInfo,
  })  : id = id ?? const Uuid().v4(),
        tags = tags ?? <String>[],
        properties = properties ?? <String, dynamic>{},
        amenities = amenities ?? <String>[],
        businessInfo = businessInfo ?? <String, dynamic>{},
        questIds = questIds ?? <String>[],
        weatherEffects = weatherEffects ?? <String, dynamic>{},
        accessibilityInfo = accessibilityInfo ?? <String, dynamic>{};

  factory MapLocation.fromJson(Map<String, dynamic> json) {
    // TODO: Implement JSON serialization
    throw UnimplementedError('JSON serialization not implemented yet');
  }
  Map<String, dynamic> toJson() {
    // TODO: Implement JSON serialization
    throw UnimplementedError('JSON serialization not implemented yet');
  }

  MapLocation copyWith({
    String? id,
    String? name,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    LocationType? type,
    LocationStatus? status,
    List<String>? tags,
    Map<String, dynamic>? properties,
    String? imageUrl,
    String? websiteUrl,
    String? phoneNumber,
    double? rating,
    int? reviewCount,
    List<String>? amenities,
    Map<String, dynamic>? businessInfo,
    DateTime? lastUpdated,
    bool? isVerified,
    String? createdBy,
    List<String>? questIds,
    Map<String, dynamic>? weatherEffects,
    Map<String, dynamic>? accessibilityInfo,
  }) {
    return MapLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      type: type ?? this.type,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      properties: properties ?? this.properties,
      imageUrl: imageUrl ?? this.imageUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      amenities: amenities ?? this.amenities,
      businessInfo: businessInfo ?? this.businessInfo,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isVerified: isVerified ?? this.isVerified,
      createdBy: createdBy ?? this.createdBy,
      questIds: questIds ?? this.questIds,
      weatherEffects: weatherEffects ?? this.weatherEffects,
      accessibilityInfo: accessibilityInfo ?? this.accessibilityInfo,
    );
  }
}

@JsonSerializable()
class AdventureQuest extends Quest {
  final MapLocation mapLocation;
  final List<MapLocation> waypointLocations;
  final WeatherCondition? requiredWeather;
  final WeatherCondition? preferredWeather;
  final Map<String, dynamic> weatherBonuses;
  final List<String> requiredItems;
  final List<String> recommendedItems;
  final Map<String, dynamic> socialFeatures;
  final Map<String, dynamic> competitionFeatures;
  final bool isUserGenerated;
  final String? creatorId;
  final DateTime? eventStartTime;
  final DateTime? eventEndTime;
  final int maxParticipants;
  final List<String> participants;
  final Map<String, dynamic> leaderboard;
  final Map<String, dynamic> adventureRewards;

  AdventureQuest({
    String? id,
    required super.name,
    required super.description,
    required super.story,
    required super.type,
    super.status = QuestStatus.available,
    super.difficulty = QuestDifficulty.medium,
    List<QuestObjective>? objectives,
    List<QuestReward>? rewards,
    super.location,
    List<QuestLocation>? waypoints,
    super.startTime,
    super.endTime,
    super.deadline,
    super.experienceReward = 100,
    super.goldReward = 50,
    List<String>? prerequisites,
    Map<String, dynamic>? metadata,
    required this.mapLocation,
    List<MapLocation>? waypointLocations,
    this.requiredWeather,
    this.preferredWeather,
    Map<String, dynamic>? weatherBonuses,
    List<String>? requiredItems,
    List<String>? recommendedItems,
    Map<String, dynamic>? socialFeatures,
    Map<String, dynamic>? competitionFeatures,
    this.isUserGenerated = false,
    this.creatorId,
    this.eventStartTime,
    this.eventEndTime,
    this.maxParticipants = 0,
    List<String>? participants,
    Map<String, dynamic>? leaderboard,
    Map<String, dynamic>? adventureRewards,
  })  : waypointLocations = waypointLocations ?? <MapLocation>[],
        weatherBonuses = weatherBonuses ?? <String, dynamic>{},
        requiredItems = requiredItems ?? <String>[],
        recommendedItems = recommendedItems ?? <String>[],
        socialFeatures = socialFeatures ?? <String, dynamic>{},
        competitionFeatures = competitionFeatures ?? <String, dynamic>{},
        participants = participants ?? <String>[],
        leaderboard = leaderboard ?? <String, dynamic>{},
        adventureRewards = adventureRewards ?? <String, dynamic>{};

  factory AdventureQuest.fromJson(Map<String, dynamic> json) {
    // TODO: Implement JSON serialization
    throw UnimplementedError('JSON serialization not implemented yet');
  }
  Map<String, dynamic> toJson() {
    // TODO: Implement JSON serialization
    throw UnimplementedError('JSON serialization not implemented yet');
  }

  @override
  AdventureQuest copyWith({
    String? id,
    String? name,
    String? description,
    String? story,
    QuestType? type,
    QuestStatus? status,
    QuestDifficulty? difficulty,
    List<QuestObjective>? objectives,
    List<QuestReward>? rewards,
    QuestLocation? location,
    List<QuestLocation>? waypoints,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? deadline,
    int? experienceReward,
    int? goldReward,
    List<String>? prerequisites,
    Map<String, dynamic>? metadata,
    MapLocation? mapLocation,
    List<MapLocation>? waypointLocations,
    WeatherCondition? requiredWeather,
    WeatherCondition? preferredWeather,
    Map<String, dynamic>? weatherBonuses,
    List<String>? requiredItems,
    List<String>? recommendedItems,
    Map<String, dynamic>? socialFeatures,
    Map<String, dynamic>? competitionFeatures,
    bool? isUserGenerated,
    String? creatorId,
    DateTime? eventStartTime,
    DateTime? eventEndTime,
    int? maxParticipants,
    List<String>? participants,
    Map<String, dynamic>? leaderboard,
    Map<String, dynamic>? adventureRewards,
  }) {
    return AdventureQuest(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      story: story ?? this.story,
      type: type ?? this.type,
      status: status ?? this.status,
      difficulty: difficulty ?? this.difficulty,
      objectives: objectives ?? this.objectives,
      rewards: rewards ?? this.rewards,
      location: location ?? this.location,
      waypoints: waypoints ?? this.waypoints,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      deadline: deadline ?? this.deadline,
      experienceReward: experienceReward ?? this.experienceReward,
      goldReward: goldReward ?? this.goldReward,
      prerequisites: prerequisites ?? this.prerequisites,
      metadata: metadata ?? this.metadata,
      mapLocation: mapLocation ?? this.mapLocation,
      waypointLocations: waypointLocations ?? this.waypointLocations,
      requiredWeather: requiredWeather ?? this.requiredWeather,
      preferredWeather: preferredWeather ?? this.preferredWeather,
      weatherBonuses: weatherBonuses ?? this.weatherBonuses,
      requiredItems: requiredItems ?? this.requiredItems,
      recommendedItems: recommendedItems ?? this.recommendedItems,
      socialFeatures: socialFeatures ?? this.socialFeatures,
      competitionFeatures: competitionFeatures ?? this.competitionFeatures,
      isUserGenerated: isUserGenerated ?? this.isUserGenerated,
      creatorId: creatorId ?? this.creatorId,
      eventStartTime: eventStartTime ?? this.eventStartTime,
      eventEndTime: eventEndTime ?? this.eventEndTime,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      participants: participants ?? this.participants,
      leaderboard: leaderboard ?? this.leaderboard,
      adventureRewards: adventureRewards ?? this.adventureRewards,
    );
  }
}

@JsonSerializable()
class MapEvent {
  final String id;
  final String name;
  final String description;
  final MapLocation location;
  final DateTime startTime;
  final DateTime endTime;
  final String eventType;
  final List<String> participants;
  final int maxParticipants;
  final Map<String, dynamic> eventData;
  final Map<String, dynamic> rewards;
  final bool isActive;
  final String? createdBy;
  final Map<String, dynamic> metadata;

  MapEvent({
    String? id,
    required this.name,
    required this.description,
    required this.location,
    required this.startTime,
    required this.endTime,
    required this.eventType,
    List<String>? participants,
    this.maxParticipants = 0,
    Map<String, dynamic>? eventData,
    Map<String, dynamic>? rewards,
    this.isActive = true,
    this.createdBy,
    Map<String, dynamic>? metadata,
  })  : id = id ?? const Uuid().v4(),
        participants = participants ?? <String>[],
        eventData = eventData ?? <String, dynamic>{},
        rewards = rewards ?? <String, dynamic>{},
        metadata = metadata ?? <String, dynamic>{};

  factory MapEvent.fromJson(Map<String, dynamic> json) {
    // TODO: Implement JSON serialization
    throw UnimplementedError('JSON serialization not implemented yet');
  }
  Map<String, dynamic> toJson() {
    // TODO: Implement JSON serialization
    throw UnimplementedError('JSON serialization not implemented yet');
  }
}

@JsonSerializable()
class UserLocation {
  final String userId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final Map<String, dynamic> metadata;

  UserLocation({
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracy,
    this.altitude,
    this.speed,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? <String, dynamic>{};

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    // TODO: Implement JSON serialization
    throw UnimplementedError('JSON serialization not implemented yet');
  }
  Map<String, dynamic> toJson() {
    // TODO: Implement JSON serialization
    throw UnimplementedError('JSON serialization not implemented yet');
  }
}

@JsonSerializable()
class WeatherData {
  final WeatherCondition condition;
  final double temperature;
  final double humidity;
  final double windSpeed;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  WeatherData({
    required this.condition,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.timestamp,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? <String, dynamic>{};

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    // TODO: Implement JSON serialization
    throw UnimplementedError('JSON serialization not implemented yet');
  }
  Map<String, dynamic> toJson() {
    // TODO: Implement JSON serialization
    throw UnimplementedError('JSON serialization not implemented yet');
  }
}

@JsonSerializable()
class LeaderboardEntry {
  final String userId;
  final String questId;
  final String username;
  final double score;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  LeaderboardEntry({
    required this.userId,
    required this.questId,
    required this.username,
    required this.score,
    required this.timestamp,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? <String, dynamic>{};

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    // TODO: Implement JSON serialization
    throw UnimplementedError('JSON serialization not implemented yet');
  }
  Map<String, dynamic> toJson() {
    // TODO: Implement JSON serialization
    throw UnimplementedError('JSON serialization not implemented yet');
  }
} 