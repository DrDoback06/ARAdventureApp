import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/trail_model.dart';
import '../models/adventure_system.dart';
import '../config/api_config.dart';

class TrailService {
  static final TrailService _instance = TrailService._internal();
  factory TrailService() => _instance;
  TrailService._internal();

  List<TrailData> _cachedTrails = [];
  DateTime? _lastTrailUpdate;

  // Get trails near a location
  Future<List<TrailData>> getTrailsNearLocation(
    GeoLocation location, {
    double radiusKm = 25,
    int maxResults = 20,
    TrailDifficulty? difficulty,
    TrailType? type,
  }) async {
    try {
      // Check cache first (refresh every 2 hours)
      if (_cachedTrails.isNotEmpty &&
          _lastTrailUpdate != null &&
          DateTime.now().difference(_lastTrailUpdate!).inHours < 2) {
        return _filterTrails(_cachedTrails, difficulty: difficulty, type: type);
      }

      List<TrailData> trails = [];

      // Try different APIs in order of preference
      if (ApiConfig.hikingProjectApiKey != 'YOUR_HIKING_PROJECT_API_KEY') {
        trails = await _getHikingProjectTrails(location, radiusKm, maxResults);
      }

      if (trails.isEmpty && ApiConfig.allTrailsApiKey != 'YOUR_ALLTRAILS_API_KEY') {
        trails = await _getAllTrailsData(location, radiusKm, maxResults);
      }

      if (trails.isEmpty && ApiConfig.trailApiKey != 'YOUR_TRAIL_API_KEY') {
        trails = await _getTrailApiData(location, radiusKm, maxResults);
      }

      // Fallback to mock data for testing
      if (trails.isEmpty) {
        trails = _getMockTrails(location);
      }

      _cachedTrails = trails;
      _lastTrailUpdate = DateTime.now();

      return _filterTrails(trails, difficulty: difficulty, type: type);
    } catch (e) {
      print('Error getting trails: $e');
      return _getMockTrails(location);
    }
  }

  // Get trails suitable for adventure routes
  Future<List<AdventureRoute>> getAdventureTrails(
    GeoLocation location, {
    double radiusKm = 25,
  }) async {
    final trails = await getTrailsNearLocation(location, radiusKm: radiusKm);
    return trails.map((trail) => trail.toAdventureRoute()).toList();
  }

  // Hiking Project API (REI) - FREE
  Future<List<TrailData>> _getHikingProjectTrails(
    GeoLocation location,
    double radiusKm,
    int maxResults,
  ) async {
    try {
      final url = Uri.parse(
        'https://www.hikingproject.com/data/get-trails?'
        'lat=${location.latitude}&'
        'lon=${location.longitude}&'
        'maxDistance=${radiusKm.round()}&'
        'maxResults=$maxResults&'
        'key=${ApiConfig.hikingProjectApiKey}',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['trails'] as List)
            .map((trail) => _parseHikingProjectTrail(trail))
            .toList();
      }
    } catch (e) {
      print('Hiking Project API error: $e');
    }
    return [];
  }

  TrailData _parseHikingProjectTrail(Map<String, dynamic> json) {
    return TrailData(
      id: json['id'].toString(),
      name: json['name'] ?? 'Unnamed Trail',
      description: json['summary'] ?? '',
      difficulty: _parseHikingProjectDifficulty(json['difficulty']),
      type: TrailType.hiking,
      lengthKm: (json['length'] ?? 0).toDouble() * 1.60934, // miles to km
      elevationGainM: (json['ascent'] ?? 0).round(),
      estimatedTimeMinutes: _estimateTime(json['length'], json['difficulty']),
      rating: (json['stars'] ?? 0).toDouble(),
      reviewCount: json['starVotes'] ?? 0,
      startLocation: GeoLocation(
        latitude: json['latitude'] ?? 0.0,
        longitude: json['longitude'] ?? 0.0,
      ),
      endLocation: GeoLocation(
        latitude: json['latitude'] ?? 0.0,
        longitude: json['longitude'] ?? 0.0,
      ),
      route: [], // Would need additional API call for detailed route
      features: [],
      tags: ['hiking', json['type']?.toLowerCase() ?? 'trail'],
      thumbnailUrl: json['imgMedium'],
      mapUrl: json['url'],
    );
  }

  TrailDifficulty _parseHikingProjectDifficulty(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'green':
        return TrailDifficulty.easy;
      case 'greenblue':
      case 'blue':
        return TrailDifficulty.moderate;
      case 'blueblack':
      case 'black':
        return TrailDifficulty.hard;
      case 'dblack':
        return TrailDifficulty.expert;
      default:
        return TrailDifficulty.moderate;
    }
  }

  int _estimateTime(dynamic length, String? difficulty) {
    final lengthMiles = (length ?? 1).toDouble();
    final baseTime = (lengthMiles * 30).round(); // 30 min per mile base
    
    switch (difficulty?.toLowerCase()) {
      case 'green':
        return baseTime;
      case 'blue':
        return (baseTime * 1.2).round();
      case 'black':
        return (baseTime * 1.5).round();
      case 'dblack':
        return (baseTime * 2.0).round();
      default:
        return baseTime;
    }
  }

  // AllTrails API (if available)
  Future<List<TrailData>> _getAllTrailsData(
    GeoLocation location,
    double radiusKm,
    int maxResults,
  ) async {
    // AllTrails API is typically only available to business partners
    // This would be implemented if access is granted
    return [];
  }

  // TrailAPI (alternative)
  Future<List<TrailData>> _getTrailApiData(
    GeoLocation location,
    double radiusKm,
    int maxResults,
  ) async {
    // Implementation for TrailAPI or other trail data sources
    return [];
  }

  // Mock trails for testing
  List<TrailData> _getMockTrails(GeoLocation location) {
    return [
      TrailData(
        id: 'mock_1',
        name: 'Mystic Forest Loop',
        description: 'A magical journey through ancient woodlands with hidden waterfalls and scenic viewpoints.',
        difficulty: TrailDifficulty.moderate,
        type: TrailType.hiking,
        lengthKm: 5.2,
        elevationGainM: 300,
        estimatedTimeMinutes: 150,
        rating: 4.7,
        reviewCount: 128,
        startLocation: GeoLocation(
          latitude: location.latitude + 0.01,
          longitude: location.longitude + 0.01,
        ),
        endLocation: GeoLocation(
          latitude: location.latitude + 0.01,
          longitude: location.longitude + 0.01,
        ),
        route: [],
        features: [
          TrailFeature(
            id: 'waterfall_1',
            name: 'Hidden Falls',
            description: 'A secret waterfall perfect for photos',
            type: 'waterfall',
            location: GeoLocation(
              latitude: location.latitude + 0.005,
              longitude: location.longitude + 0.005,
            ),
            photos: [],
          ),
        ],
        tags: ['waterfall', 'forest', 'moderate'],
        thumbnailUrl: 'https://example.com/trail1.jpg',
      ),
      TrailData(
        id: 'mock_2',
        name: 'Dragon\'s Peak Trail',
        description: 'Challenge yourself with this steep climb to spectacular summit views.',
        difficulty: TrailDifficulty.hard,
        type: TrailType.hiking,
        lengthKm: 8.7,
        elevationGainM: 800,
        estimatedTimeMinutes: 240,
        rating: 4.9,
        reviewCount: 89,
        startLocation: GeoLocation(
          latitude: location.latitude - 0.02,
          longitude: location.longitude + 0.015,
        ),
        endLocation: GeoLocation(
          latitude: location.latitude - 0.015,
          longitude: location.longitude + 0.02,
        ),
        route: [],
        features: [
          TrailFeature(
            id: 'viewpoint_1',
            name: 'Summit Overlook',
            description: 'Panoramic views of the entire valley',
            type: 'viewpoint',
            location: GeoLocation(
              latitude: location.latitude - 0.015,
              longitude: location.longitude + 0.02,
            ),
            photos: [],
          ),
        ],
        tags: ['summit', 'views', 'challenging'],
        thumbnailUrl: 'https://example.com/trail2.jpg',
      ),
    ];
  }

  List<TrailData> _filterTrails(
    List<TrailData> trails, {
    TrailDifficulty? difficulty,
    TrailType? type,
  }) {
    return trails.where((trail) {
      if (difficulty != null && trail.difficulty != difficulty) return false;
      if (type != null && trail.type != type) return false;
      return true;
    }).toList();
  }

  // Convert trail to quest suggestions
  List<Quest> generateTrailQuests(TrailData trail) {
    final quests = <Quest>[];

    // Main trail completion quest
    quests.add(Quest(
      id: 'trail_${trail.id}_complete',
      title: 'Conquer ${trail.name}',
      description: 'Complete the ${trail.name} trail and discover its secrets',
      type: QuestType.exploration,
      level: _mapDifficultyToLevel(trail.difficulty),
      location: trail.startLocation,
      radius: trail.lengthKm * 1000 + 500, // Trail length plus buffer
      objectives: [
        QuestObjective(
          title: 'Start the Adventure',
          description: 'Begin your journey at the trailhead',
          type: 'location_visit',
          requirements: {'location': trail.startLocation.toJson(), 'radius': 50},
          xpReward: 25,
        ),
        QuestObjective(
          title: 'Complete the Trail',
          description: 'Reach the end of ${trail.name}',
          type: 'location_visit',
          requirements: {'location': trail.endLocation.toJson(), 'radius': 100},
          xpReward: trail.lengthKm.round() * 10,
        ),
      ],
      rewards: {
        'xp': trail.lengthKm.round() * 15 + trail.elevationGainM ~/ 10,
        'gold': trail.lengthKm.round() * 5,
        'title': 'Trail Conqueror',
      },
      timeLimit: Duration(hours: 8),
      metadata: {
        'trail_id': trail.id,
        'source': 'trail_service',
        'difficulty': trail.difficulty.name,
      },
    ));

    // Feature-specific quests
    for (final feature in trail.features) {
      quests.add(Quest(
        id: 'feature_${feature.id}',
        title: 'Discover ${feature.name}',
        description: feature.description,
        type: QuestType.exploration,
        level: 1,
        location: feature.location,
        radius: 50,
        objectives: [
          QuestObjective(
            title: 'Find ${feature.name}',
            description: 'Locate this special feature along the trail',
            type: 'location_visit',
            requirements: {'location': feature.location.toJson(), 'radius': 50},
            xpReward: 20,
          ),
        ],
        rewards: {'xp': 30, 'gold': 10},
        metadata: {
          'feature_id': feature.id,
          'feature_type': feature.type,
          'parent_trail': trail.id,
        },
      ));
    }

    return quests;
  }

  int _mapDifficultyToLevel(TrailDifficulty difficulty) {
    switch (difficulty) {
      case TrailDifficulty.easy:
        return 1;
      case TrailDifficulty.moderate:
        return 3;
      case TrailDifficulty.hard:
        return 5;
      case TrailDifficulty.expert:
        return 8;
    }
  }
} 