import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/adventure_system.dart';
import '../models/physical_activity_model.dart';
import '../config/api_config.dart';

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
  static const String _clientId = ApiConfig.stravaClientId;
  static const String _clientSecret = ApiConfig.stravaClientSecret;
  static const String _redirectUrl = 'com.realmofvalor://auth/strava';
  static const String _scope = 'read,activity:read';
  
  static final StravaService _instance = StravaService._internal();
  factory StravaService() => _instance;
  StravaService._internal();

  Dio? _dio;
  oauth2.Client? _oauthClient;
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;

  // Initialize Strava service
  Future<void> initialize() async {
    _dio = Dio();
    await _loadStoredCredentials();
  }

  // Authenticate with Strava
  Future<bool> authenticate() async {
    try {
      final authorizationEndpoint = Uri.parse('https://www.strava.com/oauth/authorize');
      final tokenEndpoint = Uri.parse('https://www.strava.com/oauth/token');

      final grant = oauth2.AuthorizationCodeGrant(
        _clientId,
        authorizationEndpoint,
        tokenEndpoint,
        secret: _clientSecret,
      );

      final authorizationUrl = grant.getAuthorizationUrl(
        Uri.parse(_redirectUrl),
        scopes: _scope.split(','),
      );

      // In a real app, you'd launch this URL in a web view or browser
      print('Visit this URL to authorize: $authorizationUrl');
      
      // For now, we'll simulate successful authentication
      // In reality, you'd handle the callback and get the authorization code
      
      return true;
    } catch (e) {
      print('Strava authentication error: $e');
      return false;
    }
  }

  // Complete OAuth flow with authorization code
  Future<bool> completeAuthentication(String authorizationCode) async {
    try {
      final response = await _dio!.post(
        'https://www.strava.com/oauth/token',
        data: {
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'code': authorizationCode,
          'grant_type': 'authorization_code',
        },
      );

      if (response.statusCode == 200) {
        final tokenData = response.data;
        await _storeCredentials(tokenData);
        await _initializeApiClient(tokenData['access_token']);
        _isAuthenticated = true;
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error completing Strava authentication: $e');
      return false;
    }
  }

  // Get recent activities
  Future<List<StravaActivity>> getRecentActivities({int limit = 30}) async {
    if (!_isAuthenticated || _dio == null) return [];

    try {
      final response = await _dio!.get(
        'https://www.strava.com/api/v3/athlete/activities',
        queryParameters: {
          'per_page': limit,
          'page': 1,
        },
      );

      if (response.statusCode == 200) {
        final activities = (response.data as List)
            .map((json) => StravaActivity.fromJson(json))
            .toList();
        
        return activities;
      }
      
      return [];
    } catch (e) {
      print('Error getting Strava activities: $e');
      return [];
    }
  }

  // Get detailed activity with route data
  Future<StravaActivity?> getDetailedActivity(String activityId) async {
    if (!_isAuthenticated || _dio == null) return null;

    try {
      final response = await _dio!.get(
        'https://www.strava.com/api/v3/activities/$activityId',
        queryParameters: {
          'include_all_efforts': false,
        },
      );

      if (response.statusCode == 200) {
        final activity = StravaActivity.fromJson(response.data);
        
        // Get route data if available
        if (response.data['map']?['polyline'] != null) {
          final route = _decodePolyline(response.data['map']['polyline']);
          return StravaActivity(
            id: activity.id,
            name: activity.name,
            type: activity.type,
            startDate: activity.startDate,
            duration: activity.duration,
            distance: activity.distance,
            averageSpeed: activity.averageSpeed,
            maxSpeed: activity.maxSpeed,
            elevationGain: activity.elevationGain,
            averageHeartRate: activity.averageHeartRate,
            maxHeartRate: activity.maxHeartRate,
            route: route,
            metadata: activity.metadata,
          );
        }
        
        return activity;
      }
      
      return null;
    } catch (e) {
      print('Error getting detailed Strava activity: $e');
      return null;
    }
  }

  // Explore segments near location
  Future<List<StravaSegment>> exploreSegments(GeoLocation location, {double radius = 10.0}) async {
    if (!_isAuthenticated || _dio == null) return [];

    try {
      final response = await _dio!.get(
        'https://www.strava.com/api/v3/segments/explore',
        queryParameters: {
          'bounds': '${location.latitude - 0.1},${location.longitude - 0.1},'
                   '${location.latitude + 0.1},${location.longitude + 0.1}',
          'activity_type': 'running,cycling',
        },
      );

      if (response.statusCode == 200) {
        final segments = (response.data['segments'] as List)
            .map((json) => StravaSegment.fromJson(json))
            .toList();
        
        return segments;
      }
      
      return [];
    } catch (e) {
      print('Error exploring Strava segments: $e');
      return [];
    }
  }

  // Create adventure quests from Strava segments
  List<Quest> createQuestsFromSegments(List<StravaSegment> segments) {
    final quests = <Quest>[];

    for (final segment in segments) {
      final quest = Quest(
        title: 'Conquer the ${segment.name}',
        description: 'Complete this ${segment.distance.toStringAsFixed(1)}km segment to earn rewards!',
        type: QuestType.fitness,
        level: _calculateSegmentDifficulty(segment),
        location: segment.startLocation,
        radius: 100,
        xpReward: (segment.distance * 10).round(),
        cardRewards: _getSegmentRewards(segment),
        objectives: [
          QuestObjective(
            title: 'Complete the Segment',
            description: 'Finish the ${segment.name} segment',
            type: 'segment_completion',
            requirements: {
              'segment_id': segment.id,
              'distance': segment.distance,
            },
            xpReward: (segment.distance * 5).round(),
          ),
        ],
        metadata: {
          'strava_segment_id': segment.id,
          'segment_type': segment.activityType,
          'elevation_gain': segment.elevationHigh,
        },
      );

      quests.add(quest);
    }

    return quests;
  }

  // Sync Strava activities with game progress
  Future<void> syncActivitiesWithGame() async {
    try {
      final activities = await getRecentActivities(limit: 10);
      
      for (final activity in activities) {
        final workoutSession = activity.toWorkoutSession();
        
        // Here you'd integrate with your existing physical activity service
        // to update game progress, achievements, etc.
        
        // Award bonus XP for Strava activities
        await _awardStravaActivityBonus(activity);
      }
    } catch (e) {
      print('Error syncing Strava activities: $e');
    }
  }

  // Award bonus for Strava activities
  Future<void> _awardStravaActivityBonus(StravaActivity activity) async {
    final bonusXp = (activity.distance * 2).round();
    final bonusCoins = (activity.duration / 60).round();
    
    print('Awarded $bonusXp XP and $bonusCoins coins for Strava activity: ${activity.name}');
    
    // Here you'd actually update the player's progress
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