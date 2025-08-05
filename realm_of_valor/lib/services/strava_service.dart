import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/adventure_system.dart';
import '../models/physical_activity_model.dart';

extension StringExtension on String {
  String get capitalized => this.isEmpty ? this : this[0].toUpperCase() + this.substring(1);
}

class StravaActivity {
  final String id;
  final String name;
  final String type;
  final DateTime startDate;
  final int duration;
  final double distance;
  final double? averageSpeed;
  final double? maxSpeed;
  final double? elevationGain;
  final int? averageHeartRate;
  final int? maxHeartRate;
  final List<GeoLocation> route;
  final Map<String, dynamic> metadata;

  StravaActivity({
    required this.id,
    required this.name,
    required this.type,
    required this.startDate,
    required this.duration,
    required this.distance,
    this.averageSpeed,
    this.maxSpeed,
    this.elevationGain,
    this.averageHeartRate,
    this.maxHeartRate,
    required this.route,
    required this.metadata,
  });

  factory StravaActivity.fromJson(Map<String, dynamic> json) {
    return StravaActivity(
      id: json['id'].toString(),
      name: json['name'] ?? 'Unnamed Activity',
      type: json['type'] ?? 'Unknown',
      startDate: DateTime.parse(json['start_date']),
      duration: json['moving_time'] ?? 0,
      distance: (json['distance'] ?? 0).toDouble(),
      averageSpeed: json['average_speed']?.toDouble(),
      maxSpeed: json['max_speed']?.toDouble(),
      elevationGain: json['total_elevation_gain']?.toDouble(),
      averageHeartRate: json['average_heartrate']?.toInt(),
      maxHeartRate: json['max_heartrate']?.toInt(),
      route: [], // Would be populated from detailed activity data
      metadata: json,
    );
  }

  // Convert to game workout session
  WorkoutSession toWorkoutSession() {
    final activityType = _mapStravaTypeToActivityType(type);
    final intensity = _calculateIntensity();
    
    return WorkoutSession(
      name: name,
      type: activityType,
      intensity: intensity,
      startTime: startDate,
      endTime: startDate.add(Duration(seconds: duration)),
      duration: duration,
      isCompleted: true,
      metrics: [
        HealthMetrics(
          steps: _estimateSteps(),
          distanceMeters: distance,
          heartRate: averageHeartRate ?? 0,
          caloriesBurned: _estimateCalories(),
          elevationGain: elevationGain ?? 0,
          timestamp: startDate,
        ),
      ],
    );
  }

  ActivityType _mapStravaTypeToActivityType(String stravaType) {
    switch (stravaType.toLowerCase()) {
      case 'run':
        return ActivityType.running;
      case 'walk':
        return ActivityType.walking;
      case 'ride':
        return ActivityType.cycling;
      case 'swim':
        return ActivityType.swimming;
      case 'yoga':
        return ActivityType.yoga;
      case 'workout':
        return ActivityType.weightlifting;
      default:
        return ActivityType.other;
    }
  }

  ActivityIntensity _calculateIntensity() {
    if (averageHeartRate != null) {
      if (averageHeartRate! > 160) return ActivityIntensity.high;
      if (averageHeartRate! > 120) return ActivityIntensity.moderate;
      return ActivityIntensity.low;
    }
    
    // Fallback based on speed
    if (averageSpeed != null) {
      if (type.toLowerCase() == 'run' && averageSpeed! > 5.0) return ActivityIntensity.high;
      if (type.toLowerCase() == 'ride' && averageSpeed! > 8.0) return ActivityIntensity.high;
    }
    
    return ActivityIntensity.moderate;
  }

  int _estimateSteps() {
    if (type.toLowerCase() == 'run' || type.toLowerCase() == 'walk') {
      return (distance * 1.3).round(); // Rough estimation
    }
    return 0;
  }

  int _estimateCalories() {
    // Very rough estimation based on activity type and duration
    double rate = 10.0; // calories per minute
    switch (type.toLowerCase()) {
      case 'run':
        rate = 15.0;
        break;
      case 'ride':
        rate = 12.0;
        break;
      case 'swim':
        rate = 18.0;
        break;
      case 'walk':
        rate = 5.0;
        break;
    }
    return ((duration / 60) * rate).round();
  }
}

class StravaSegment {
  final String id;
  final String name;
  final String activityType;
  final double distance;
  final double? averageGrade;
  final double? maximumGrade;
  final double? elevationHigh;
  final double? elevationLow;
  final GeoLocation startLocation;
  final GeoLocation endLocation;
  final List<GeoLocation> route;

  StravaSegment({
    required this.id,
    required this.name,
    required this.activityType,
    required this.distance,
    this.averageGrade,
    this.maximumGrade,
    this.elevationHigh,
    this.elevationLow,
    required this.startLocation,
    required this.endLocation,
    required this.route,
  });

  factory StravaSegment.fromJson(Map<String, dynamic> json) {
    final startLatLng = json['start_latlng'] as List?;
    final endLatLng = json['end_latlng'] as List?;
    
    return StravaSegment(
      id: json['id'].toString(),
      name: json['name'] ?? 'Unnamed Segment',
      activityType: json['activity_type'] ?? 'Run',
      distance: (json['distance'] ?? 0).toDouble(),
      averageGrade: json['average_grade']?.toDouble(),
      maximumGrade: json['maximum_grade']?.toDouble(),
      elevationHigh: json['elevation_high']?.toDouble(),
      elevationLow: json['elevation_low']?.toDouble(),
      startLocation: GeoLocation(
        latitude: startLatLng?[0] ?? 0.0,
        longitude: startLatLng?[1] ?? 0.0,
      ),
      endLocation: GeoLocation(
        latitude: endLatLng?[0] ?? 0.0,
        longitude: endLatLng?[1] ?? 0.0,
      ),
      route: [], // Would be populated from polyline data
    );
  }
}

class StravaService {
  static final StravaService _instance = StravaService._internal();
  factory StravaService() => _instance;
  StravaService._internal();

  final Dio _dio = Dio();
  oauth2.Client? _client;
  
  // Strava API configuration
  static const String _clientId = 'YOUR_STRAVA_CLIENT_ID';
  static const String _clientSecret = 'YOUR_STRAVA_CLIENT_SECRET';
  static const String _redirectUri = 'com.realmofvalor.app://oauth/strava';
  static const String _scope = 'read,activity:read';
  
  static const String _authorizationEndpoint = 'https://www.strava.com/oauth/authorize';
  static const String _tokenEndpoint = 'https://www.strava.com/oauth/token';
  static const String _apiBaseUrl = 'https://www.strava.com/api/v3';

  bool _isAuthenticated = false;
  Map<String, dynamic>? _athleteProfile;
  List<StravaActivity> _recentActivities = [];
  List<StravaSegment> _nearbySegments = [];
  List<StravaRoute> _popularRoutes = [];

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get athleteProfile => _athleteProfile;
  List<StravaActivity> get recentActivities => _recentActivities;
  List<StravaSegment> get nearbySegments => _nearbySegments;
  List<StravaRoute> get popularRoutes => _popularRoutes;

  // Initialize service
  Future<void> initialize() async {
    await _loadSavedCredentials();
    if (_isAuthenticated) {
      await _refreshData();
    }
  }

  // Authenticate with Strava
  Future<bool> authenticate() async {
    try {
      // Create OAuth2 client
      final grant = oauth2.AuthorizationCodeGrant(
        _clientId,
        Uri.parse(_authorizationEndpoint),
        Uri.parse(_tokenEndpoint),
        secret: _clientSecret,
      );

      // Get authorization URL
      final authorizationUrl = grant.getAuthorizationUrl(
        Uri.parse(_redirectUri),
        scopes: _scope.split(','),
      );

      print('Strava Authorization URL: $authorizationUrl');
      
      // In a real app, you'd open this URL in a web browser
      // and handle the redirect to get the authorization code
      // For this implementation, we'll simulate successful auth
      
      // Simulate receiving authorization code
      final authCode = 'simulated_auth_code';
      
      // Exchange code for access token
      _client = await grant.handleAuthorizationResponse({
        'code': authCode,
      });

      _isAuthenticated = true;
      await _saveCredentials();
      await _loadAthleteProfile();

      return true;
    } catch (e) {
      print('Strava authentication failed: $e');
      return false;
    }
  }

  // Discover nearby Strava segments (trails)
  Future<List<StravaSegment>> discoverNearbySegments({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    String activityType = 'running',
  }) async {
    if (!_isAuthenticated) {
      throw Exception('Must authenticate with Strava first');
    }

    try {
      final url = '$_apiBaseUrl/segments/explore';
      final response = await _dio.get(url, 
        queryParameters: {
          'bounds': '${latitude - 0.1},${longitude - 0.1},${latitude + 0.1},${longitude + 0.1}',
          'activity_type': activityType,
        },
        options: Options(
          headers: {'Authorization': 'Bearer ${_getAccessToken()}'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final segments = (data['segments'] as List)
            .map((segmentData) => StravaSegment.fromJson(segmentData))
            .toList();

        _nearbySegments = segments;
        return segments;
      } else {
        print('Failed to load Strava segments: ${response.statusCode}');
        return _generateMockSegments(latitude, longitude);
      }
    } catch (e) {
      print('Error loading Strava segments: $e');
      return _generateMockSegments(latitude, longitude);
    }
  }

  // Discover popular routes in area
  Future<List<StravaRoute>> discoverPopularRoutes({
    required double latitude,
    required double longitude,
    String activityType = 'running',
  }) async {
    if (!_isAuthenticated) {
      throw Exception('Must authenticate with Strava first');
    }

    try {
      // Strava doesn't have a public routes API endpoint
      // In a real implementation, you'd use the athlete's starred segments
      // or popular routes from the heat map API
      return _generateMockRoutes(latitude, longitude, activityType);
    } catch (e) {
      print('Error loading Strava routes: $e');
      return _generateMockRoutes(latitude, longitude, activityType);
    }
  }

  // Convert Strava segments to adventure quests
  Future<List<TrailQuest>> convertSegmentsToQuests(List<StravaSegment> segments) async {
    final quests = <TrailQuest>[];

    for (final segment in segments) {
      // Create different quest types based on segment characteristics
      final questDifficulty = _calculateQuestDifficulty(segment);
      final questType = _determineQuestType(segment);
      
      final quest = TrailQuest(
        id: 'strava_segment_${segment.id}',
        title: 'Conquer ${segment.name}',
        description: _generateSegmentQuestDescription(segment),
        segmentId: segment.id,
        segmentName: segment.name,
        distance: segment.distance,
        elevationGain: segment.elevationHigh - segment.elevationLow,
        averageGrade: segment.averageGrade,
        difficulty: questDifficulty,
        questType: questType,
        startLocation: GeoLocation(
          id: 'segment_start_${segment.id}',
          latitude: segment.startLatitude,
          longitude: segment.startLongitude,
          timestamp: DateTime.now(),
        ),
        endLocation: GeoLocation(
          id: 'segment_end_${segment.id}',
          latitude: segment.endLatitude,
          longitude: segment.endLongitude,
          timestamp: DateTime.now(),
        ),
        polyline: segment.polyline,
        experienceReward: _calculateExperienceReward(segment),
        objectives: _generateSegmentObjectives(segment),
        rewards: _generateSegmentRewards(segment),
        kom: segment.kom,
        qom: segment.qom,
        effortCount: segment.effortCount,
        starCount: segment.starCount,
        isHazardous: segment.hazardous,
        climbCategory: segment.climbCategory,
      );

      quests.add(quest);
    }

    return quests;
  }

  // Convert Strava routes to adventure routes
  Future<List<AdventureRoute>> convertRoutesToAdventures(List<StravaRoute> routes) async {
    final adventures = <AdventureRoute>[];

    for (final route in routes) {
      final adventure = AdventureRoute(
        id: 'strava_route_${route.id}',
        name: route.name,
        description: _generateRouteDescription(route),
        waypoints: route.waypoints,
        totalDistance: route.distance,
        estimatedDuration: Duration(seconds: (route.estimatedMovingTime ?? route.distance / 3).round()), // Rough estimate
        difficulty: _calculateRouteDifficulty(route),
        type: route.type,
        metadata: {
          'strava_route_id': route.id,
          'elevation_gain': route.elevationGain,
          'surface_type': route.surfaceType,
          'route_type': route.type,
          'created_by_athlete': route.athlete?.id,
          'star_count': route.starCount,
          'is_private': route.isPrivate,
        },
      );

      adventures.add(adventure);
    }

    return adventures;
  }

  // Sync recent activities and convert to game progress
  Future<List<ActivityReward>> syncRecentActivities() async {
    if (!_isAuthenticated) {
      throw Exception('Must authenticate with Strava first');
    }

    try {
      final url = '$_apiBaseUrl/athlete/activities';
      final response = await _dio.get(url,
        queryParameters: {
          'per_page': 30,
          'page': 1,
        },
        options: Options(
          headers: {'Authorization': 'Bearer ${_getAccessToken()}'},
        ),
      );

      if (response.statusCode == 200) {
        final activitiesData = response.data as List;
        _recentActivities = activitiesData
            .map((data) => StravaActivity.fromJson(data))
            .toList();

        // Convert activities to game rewards
        return _convertActivitiesToRewards(_recentActivities);
      } else {
        print('Failed to sync Strava activities: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error syncing Strava activities: $e');
      return [];
    }
  }

  // Generate quest description for Strava segment
  String _generateSegmentQuestDescription(StravaSegment segment) {
    final distance = (segment.distance / 1000).toStringAsFixed(1);
    final elevationGain = (segment.elevationHigh - segment.elevationLow).toStringAsFixed(0);
    final grade = segment.averageGrade.toStringAsFixed(1);

    String description = 'Embark on an epic adventure along ${segment.name}! ';
    description += 'This ${distance}km trail ';
    
    if (segment.averageGrade > 5) {
      description += 'features challenging climbs with ${elevationGain}m of elevation gain (${grade}% grade). ';
      description += 'Only the bravest warriors dare to conquer this mountain path!';
    } else if (segment.averageGrade < -5) {
      description += 'offers thrilling descents with ${elevationGain}m of elevation change. ';
      description += 'Feel the rush as you speed down this legendary trail!';
    } else {
      description += 'provides a balanced adventure perfect for all skill levels. ';
      description += 'Discover the beauty of this scenic route while earning valuable rewards!';
    }

    if (segment.starCount > 100) {
      description += '\n\nThis trail is beloved by ${segment.starCount} adventurers - join their ranks!';
    }

    return description;
  }

  // Generate route description
  String _generateRouteDescription(StravaRoute route) {
    final distance = (route.distance / 1000).toStringAsFixed(1);
    final elevationGain = route.elevationGain.toStringAsFixed(0);

    return 'Explore ${route.name}, a ${distance}km ${route.type} route with ${elevationGain}m of elevation gain. '
        'This carefully crafted adventure combines scenic beauty with physical challenge, '
        'perfect for earning experience points and discovering hidden treasures along the way!';
  }

  // Calculate quest difficulty based on segment characteristics
  String _calculateQuestDifficulty(StravaSegment segment) {
    final distance = segment.distance;
    final elevationGain = segment.elevationHigh - segment.elevationLow;
    final grade = segment.averageGrade.abs();

    int difficultyScore = 0;

    // Distance scoring
    if (distance > 10000) difficultyScore += 3; // >10km
    else if (distance > 5000) difficultyScore += 2; // 5-10km
    else if (distance > 1000) difficultyScore += 1; // 1-5km

    // Elevation scoring
    if (elevationGain > 500) difficultyScore += 3;
    else if (elevationGain > 200) difficultyScore += 2;
    else if (elevationGain > 50) difficultyScore += 1;

    // Grade scoring
    if (grade > 15) difficultyScore += 3;
    else if (grade > 8) difficultyScore += 2;
    else if (grade > 4) difficultyScore += 1;

    if (difficultyScore >= 7) return 'legendary';
    if (difficultyScore >= 5) return 'hard';
    if (difficultyScore >= 3) return 'medium';
    return 'easy';
  }

  // Calculate route difficulty
  String _calculateRouteDifficulty(StravaRoute route) {
    final distance = route.distance;
    final elevationGain = route.elevationGain;

    int difficultyScore = 0;

    if (distance > 50000) difficultyScore += 4; // >50km
    else if (distance > 25000) difficultyScore += 3; // 25-50km
    else if (distance > 10000) difficultyScore += 2; // 10-25km
    else if (distance > 5000) difficultyScore += 1; // 5-10km

    if (elevationGain > 1500) difficultyScore += 3;
    else if (elevationGain > 800) difficultyScore += 2;
    else if (elevationGain > 300) difficultyScore += 1;

    if (difficultyScore >= 6) return 'legendary';
    if (difficultyScore >= 4) return 'hard';
    if (difficultyScore >= 2) return 'medium';
    return 'easy';
  }

  // Determine quest type based on segment
  String _determineQuestType(StravaSegment segment) {
    if (segment.climbCategory > 0) return 'climbing';
    if (segment.averageGrade > 5) return 'uphill_challenge';
    if (segment.averageGrade < -5) return 'downhill_rush';
    if (segment.distance > 5000) return 'endurance';
    return 'exploration';
  }

  // Calculate experience reward
  int _calculateExperienceReward(StravaSegment segment) {
    final baseXP = 100;
    final distanceBonus = (segment.distance / 1000 * 50).round();
    final elevationBonus = ((segment.elevationHigh - segment.elevationLow) / 10).round();
    final popularityBonus = (segment.starCount / 10).round();
    
    return baseXP + distanceBonus + elevationBonus + popularityBonus;
  }

  // Generate segment objectives
  List<QuestObjective> _generateSegmentObjectives(StravaSegment segment) {
    final objectives = <QuestObjective>[];

    objectives.add(QuestObjective(
      id: 'complete_segment_${segment.id}',
      title: 'Complete the Segment',
      description: 'Successfully traverse ${segment.name} from start to finish',
      type: 'segment_completion',
      requirements: {
        'segment_id': segment.id,
        'distance': segment.distance,
      },
      progress: {},
      isCompleted: false,
      xpReward: 200,
      itemRewards: [],
    ));

    // Add time-based challenge if it's a popular segment
    if (segment.starCount > 50) {
      objectives.add(QuestObjective(
        id: 'beat_average_${segment.id}',
        title: 'Beat the Average Time',
        description: 'Complete the segment faster than the average time',
        type: 'time_challenge',
        requirements: {
          'segment_id': segment.id,
          'target_time': segment.effortCount > 0 ? segment.kom.elapsedTime * 1.2 : 600, // 20% above KOM or 10 min
        },
        progress: {},
        isCompleted: false,
        xpReward: 300,
        itemRewards: ['speed_boots'],
      ));
    }

    return objectives;
  }

  // Generate segment rewards
  List<String> _generateSegmentRewards(StravaSegment segment) {
    final rewards = <String>['trail_badge_${segment.id}'];

    if (segment.climbCategory > 0) {
      rewards.add('climber_badge');
      if (segment.climbCategory >= 3) rewards.add('mountain_conqueror_title');
    }

    if (segment.distance > 10000) {
      rewards.add('endurance_badge');
    }

    if (segment.starCount > 100) {
      rewards.add('popular_trail_explorer');
    }

    return rewards;
  }

  // Convert activities to rewards
  List<ActivityReward> _convertActivitiesToRewards(List<StravaActivity> activities) {
    final rewards = <ActivityReward>[];

    for (final activity in activities) {
      final workoutSession = activity.toWorkoutSession();
      
      rewards.add(ActivityReward(
        id: 'strava_activity_${activity.id}',
        activityId: activity.id,
        activityName: activity.name,
        activityType: activity.type,
        experienceGained: _calculateActivityExperience(activity),
        goldGained: _calculateActivityGold(activity),
        itemsEarned: _getActivityItems(activity),
        distanceCovered: activity.distance,
        caloriesBurned: workoutSession.metrics.first.caloriesBurned,
        achievementsUnlocked: _checkActivityAchievements(activity),
        completedAt: activity.startDate,
      ));
    }

    return rewards;
  }

  // Calculate activity experience
  int _calculateActivityExperience(StravaActivity activity) {
    int baseXP = 50;
    int distanceXP = (activity.distance / 1000 * 20).round(); // 20 XP per km
    int timeXP = (activity.duration / 60 / 10).round(); // 1 XP per 10 minutes
    int elevationXP = ((activity.elevationGain ?? 0) / 10).round(); // 1 XP per 10m elevation
    
    return baseXP + distanceXP + timeXP + elevationXP;
  }

  // Calculate activity gold
  int _calculateActivityGold(StravaActivity activity) {
    return (activity.distance / 1000 * 10).round(); // 10 gold per km
  }

  // Get activity items
  List<String> _getActivityItems(StravaActivity activity) {
    final items = <String>[];
    
    if (activity.distance > 10000) items.add('endurance_potion');
    if ((activity.elevationGain ?? 0) > 300) items.add('mountain_gear');
    if (activity.duration > 3600) items.add('determination_badge');
    
    return items;
  }

  // Check activity achievements
  List<String> _checkActivityAchievements(StravaActivity activity) {
    final achievements = <String>[];
    
    if (activity.distance > 21097) achievements.add('half_marathon_hero');
    if (activity.distance > 42195) achievements.add('marathon_legend');
    if ((activity.elevationGain ?? 0) > 1000) achievements.add('mountain_climber');
    
    return achievements;
  }

  // Generate mock segments for fallback
  List<StravaSegment> _generateMockSegments(double latitude, double longitude) {
    final segments = <StravaSegment>[];
    final random = math.Random();

    for (int i = 0; i < 3; i++) {
      final distance = 1000 + random.nextDouble() * 4000; // 1-5km
      final elevation = random.nextDouble() * 200; // 0-200m
      
      segments.add(StravaSegment(
        id: 'mock_segment_${i + 1}',
        name: 'Mock Trail ${i + 1}',
        activityType: 'running',
        distance: distance,
        averageGrade: random.nextDouble() * 10 - 5, // -5% to +5%
        maximumGrade: random.nextDouble() * 15,
        elevationHigh: elevation + 100,
        elevationLow: elevation,
        startLatitude: latitude + (random.nextDouble() - 0.5) * 0.01,
        startLongitude: longitude + (random.nextDouble() - 0.5) * 0.01,
        endLatitude: latitude + (random.nextDouble() - 0.5) * 0.01,
        endLongitude: longitude + (random.nextDouble() - 0.5) * 0.01,
        climbCategory: random.nextInt(2),
        city: 'Mock City',
        state: 'Mock State',
        country: 'Mock Country',
        hazardous: false,
        starCount: random.nextInt(200),
        effortCount: random.nextInt(1000),
        polyline: 'mock_polyline_${i + 1}',
        kom: SegmentLeaderboard(
          athleteName: 'Mock Athlete KOM',
          elapsedTime: 300 + random.nextInt(600),
          dateAchieved: DateTime.now().subtract(Duration(days: random.nextInt(365))),
        ),
        qom: SegmentLeaderboard(
          athleteName: 'Mock Athlete QOM',
          elapsedTime: 350 + random.nextInt(600),
          dateAchieved: DateTime.now().subtract(Duration(days: random.nextInt(365))),
        ),
      ));
    }

    return segments;
  }

  // Generate mock routes for fallback
  List<StravaRoute> _generateMockRoutes(double latitude, double longitude, String activityType) {
    final routes = <StravaRoute>[];
    final random = math.Random();

    for (int i = 0; i < 2; i++) {
      final distance = 5000 + random.nextDouble() * 15000; // 5-20km
      final waypoints = <GeoLocation>[];
      
      // Generate waypoints
      for (int j = 0; j < 5; j++) {
        waypoints.add(GeoLocation(
          id: 'waypoint_${i}_${j}',
          latitude: latitude + (random.nextDouble() - 0.5) * 0.02,
          longitude: longitude + (random.nextDouble() - 0.5) * 0.02,
          timestamp: DateTime.now(),
        ));
      }

      routes.add(StravaRoute(
        id: 'mock_route_${i + 1}',
        name: 'Mock ${activityType.capitalized} Route ${i + 1}',
        description: 'A scenic mock route for $activityType activities.',
        distance: distance,
        elevationGain: random.nextDouble() * 500,
        type: activityType,
        surfaceType: 'mixed',
        waypoints: waypoints,
        isPrivate: false,
        starCount: random.nextInt(50),
        athlete: StravaAthlete(
          id: 'mock_athlete_${i + 1}',
          firstName: 'Mock',
          lastName: 'Athlete',
          profileMedium: null,
        ),
        estimatedMovingTime: (distance / 4).round(), // 4 m/s average
        polyline: 'mock_route_polyline_${i + 1}',
      ));
    }

    return routes;
  }

  // Load saved credentials
  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('strava_access_token');
      
      if (accessToken != null) {
        // In a real implementation, you'd recreate the OAuth client
        _isAuthenticated = true;
        
        final athleteData = prefs.getString('strava_athlete_profile');
        if (athleteData != null) {
          _athleteProfile = json.decode(athleteData);
        }
      }
    } catch (e) {
      print('Error loading saved Strava credentials: $e');
    }
  }

  // Save credentials
  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // In a real implementation, you'd save the actual tokens
      await prefs.setString('strava_access_token', 'mock_access_token');
      
      if (_athleteProfile != null) {
        await prefs.setString('strava_athlete_profile', json.encode(_athleteProfile!));
      }
    } catch (e) {
      print('Error saving Strava credentials: $e');
    }
  }

  // Load athlete profile
  Future<void> _loadAthleteProfile() async {
    try {
      // Mock athlete profile
      _athleteProfile = {
        'id': 'mock_athlete_id',
        'firstname': 'Mock',
        'lastname': 'Athlete',
        'profile_medium': null,
        'city': 'Mock City',
        'state': 'Mock State',
        'country': 'Mock Country',
      };
    } catch (e) {
      print('Error loading athlete profile: $e');
    }
  }

  // Refresh data
  Future<void> _refreshData() async {
    // Mock refresh - in real implementation, this would fetch latest data
    print('Refreshing Strava data...');
  }

  // Get access token
  String _getAccessToken() {
    // In a real implementation, this would return the actual access token
    return 'mock_access_token';
  }

  // Helper methods
  int _calculateSegmentDifficulty(StravaSegment segment) {
    double difficulty = 1.0;
    
    // Base difficulty on distance
    difficulty += segment.distance / 5.0;
    
    // Add difficulty for elevation
    if (segment.averageGrade != null) {
      difficulty += segment.averageGrade! / 2.0;
    }
    
    return difficulty.clamp(1, 10).round();
  }

  List<String> _getSegmentRewards(StravaSegment segment) {
    final rewards = <String>['fitness_medal'];
    
    if (segment.distance > 10) {
      rewards.add('endurance_badge');
    }
    
    if ((segment.averageGrade ?? 0) > 5) {
      rewards.add('climber_trophy');
    }
    
    if (segment.activityType.toLowerCase() == 'cycling') {
      rewards.add('cycling_gear');
    } else {
      rewards.add('running_shoes');
    }
    
    return rewards;
  }

  List<GeoLocation> _decodePolyline(String encoded) {
    // Implement polyline decoding
    // This is a simplified version - you'd use a proper polyline decoder
    return [];
  }

  // Data persistence
  Future<void> _storeCredentials(Map<String, dynamic> tokenData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('strava_token_data', jsonEncode(tokenData));
  }

  Future<void> _loadStoredCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tokenDataJson = prefs.getString('strava_token_data');
      
      if (tokenDataJson != null) {
        final tokenData = jsonDecode(tokenDataJson);
        await _initializeApiClient(tokenData['access_token']);
        _isAuthenticated = true;
      }
    } catch (e) {
      print('Error loading stored Strava credentials: $e');
    }
  }

  Future<void> _initializeApiClient(String accessToken) async {
    _dio!.options.headers['Authorization'] = 'Bearer $accessToken';
  }

  // Sign out
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('strava_token_data');
    _isAuthenticated = false;
    _oauthClient = null;
  }
}