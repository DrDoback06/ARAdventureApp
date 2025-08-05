import 'dart:async';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:background_location/background_location.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/adventure_system.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

extension StringExtension on String {
  String get capitalized => this.isEmpty ? this : this[0].toUpperCase() + this.substring(1);
}

class LocationEvent {
  final String id;
  final String type;
  final GeoLocation location;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  LocationEvent({
    required this.id,
    required this.type,
    required this.location,
    required this.timestamp,
    required this.data,
  });

  factory LocationEvent.fromJson(Map<String, dynamic> json) {
    return LocationEvent(
      id: json['id'],
      type: json['type'],
      location: GeoLocation.fromJson(json['location']),
      timestamp: DateTime.parse(json['timestamp']),
      data: json['data'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'location': location.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }
}

class GeofenceRegion {
  final String id;
  final String name;
  final GeoLocation center;
  final double radius;
  final String eventType;
  final Map<String, dynamic> data;
  final bool isActive;

  GeofenceRegion({
    required this.id,
    required this.name,
    required this.center,
    required this.radius,
    required this.eventType,
    required this.data,
    this.isActive = true,
  });

  bool containsLocation(GeoLocation location) {
    final distance = center.distanceTo(location);
    return distance <= radius;
  }

  factory GeofenceRegion.fromJson(Map<String, dynamic> json) {
    return GeofenceRegion(
      id: json['id'],
      name: json['name'],
      center: GeoLocation.fromJson(json['center']),
      radius: json['radius'].toDouble(),
      eventType: json['eventType'],
      data: json['data'] ?? {},
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'center': center.toJson(),
      'radius': radius,
      'eventType': eventType,
      'data': data,
      'isActive': isActive,
    };
  }
}

class AdventureRoute {
  final String id;
  final String name;
  final String description;
  final List<GeoLocation> waypoints;
  final double totalDistance;
  final int estimatedDuration;
  final String difficulty;
  final List<String> highlights;
  final Map<String, dynamic> metadata;

  AdventureRoute({
    required this.id,
    required this.name,
    required this.description,
    required this.waypoints,
    required this.totalDistance,
    required this.estimatedDuration,
    required this.difficulty,
    required this.highlights,
    required this.metadata,
  });

  factory AdventureRoute.fromJson(Map<String, dynamic> json) {
    return AdventureRoute(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      waypoints: (json['waypoints'] as List)
          .map((w) => GeoLocation.fromJson(w))
          .toList(),
      totalDistance: json['totalDistance'].toDouble(),
      estimatedDuration: json['estimatedDuration'],
      difficulty: json['difficulty'],
      highlights: List<String>.from(json['highlights'] ?? []),
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'waypoints': waypoints.map((w) => w.toJson()).toList(),
      'totalDistance': totalDistance,
      'estimatedDuration': estimatedDuration,
      'difficulty': difficulty,
      'highlights': highlights,
      'metadata': metadata,
    };
  }
}

class EnhancedLocationService {
  static final EnhancedLocationService _instance = EnhancedLocationService._internal();
  factory EnhancedLocationService() => _instance;
  EnhancedLocationService._internal();

  // Google Places API key
  static const String _googlePlacesApiKey = 'YOUR_GOOGLE_PLACES_API_KEY'; // Replace with actual key

  final List<LocationEvent> _locationHistory = [];
  final Set<GeofenceRegion> _activeGeofences = {};
  final StreamController<LocationEvent> _locationEventController = StreamController.broadcast();
  
  bool _isTracking = false;
  bool _enableBackground = false;
  GeoLocation? _currentLocation;
  Timer? _trackingTimer;

  // Stream for location events
  Stream<LocationEvent> get locationEvents => _locationEventController.stream;
  
  // Current location getter
  GeoLocation? get currentLocation => _currentLocation;
  bool get isTracking => _isTracking;

  // POI Categories for quest generation
  final Map<String, List<String>> _poiCategories = {
    'fitness': ['gym', 'fitness_center', 'stadium', 'swimming_pool', 'sports_complex'],
    'social': ['restaurant', 'bar', 'cafe', 'pub', 'night_club', 'community_center'],
    'spiritual': ['church', 'mosque', 'synagogue', 'temple', 'place_of_worship'],
    'nature': ['park', 'nature_reserve', 'botanical_garden', 'zoo', 'aquarium'],
    'education': ['school', 'university', 'library', 'museum'],
    'shopping': ['shopping_mall', 'store', 'supermarket', 'pharmacy'],
    'transportation': ['subway_station', 'train_station', 'bus_station', 'airport'],
    'medical': ['hospital', 'doctor', 'dentist', 'veterinary_care'],
    'entertainment': ['movie_theater', 'amusement_park', 'bowling_alley', 'casino'],
    'lodging': ['lodging', 'hotel', 'motel', 'resort'],
  };

  // Initialize the service
  Future<void> initialize() async {
    await _setupLocationServices();
    print('Enhanced Location Service initialized');
  }

  // Setup location services and permissions
  Future<void> _setupLocationServices() async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get initial location
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      _currentLocation = GeoLocation(
        id: 'current',
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
        accuracy: position.accuracy,
        timestamp: DateTime.now(),
      );

      print('Initial location: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}');
    } catch (e) {
      print('Error setting up location services: $e');
      rethrow;
    }
  }

  // Start location tracking
  Future<void> startTracking({bool enableBackground = false}) async {
    if (_isTracking) return;

    _enableBackground = enableBackground;
    _isTracking = true;

    if (enableBackground) {
      await _startBackgroundTracking();
    } else {
      await _startForegroundTracking();
    }

    print('Location tracking started (background: $enableBackground)');
  }

  // Stop location tracking
  Future<void> stopTracking() async {
    _isTracking = false;
    _trackingTimer?.cancel();
    
    if (_enableBackground) {
      await BackgroundLocation.stopLocationService();
    }
  }

  // Start foreground tracking
  Future<void> _startForegroundTracking() async {
    _trackingTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await _updateLocation();
    });
  }

  // Start background tracking
  Future<void> _startBackgroundTracking() async {
    await BackgroundLocation.setAndroidNotification(
      title: 'Realm of Valor Adventure Mode',
      message: 'Tracking your location for quest adventures',
      icon: '@mipmap/ic_launcher',
    );
    
    await BackgroundLocation.startLocationService(distanceFilter: 20);
    
    BackgroundLocation.getLocationUpdates((location) {
      _handleBackgroundLocationUpdate(location);
    });
  }

  // Update current location
  Future<void> _updateLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      final newLocation = GeoLocation(
        id: 'current_${DateTime.now().millisecondsSinceEpoch}',
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
        accuracy: position.accuracy,
        timestamp: DateTime.now(),
      );

      _currentLocation = newLocation;
      await _checkGeofenceRegions(newLocation);
      await _triggerLocationBasedEvents(newLocation);

    } catch (e) {
      print('Error updating location: $e');
    }
  }

  // Handle background location updates
  void _handleBackgroundLocationUpdate(Location location) {
    final newLocation = GeoLocation(
      id: 'bg_${DateTime.now().millisecondsSinceEpoch}',
      latitude: location.latitude ?? 0,
      longitude: location.longitude ?? 0,
      altitude: location.altitude,
      accuracy: location.accuracy,
      timestamp: DateTime.now(),
    );

    _currentLocation = newLocation;
    _checkGeofenceRegions(newLocation);
    _triggerLocationBasedEvents(newLocation);
  }

  // Discover nearby POIs using Google Places API
  Future<List<PointOfInterest>> discoverNearbyPOIs({
    double radius = 1000.0,
    String? category,
    int maxResults = 20,
  }) async {
    if (_currentLocation == null) {
      throw Exception('Current location not available');
    }

    try {
      // Build Google Places API request
      String url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
          'location=${_currentLocation!.latitude},${_currentLocation!.longitude}&'
          'radius=$radius&'
          'key=$_googlePlacesApiKey';

      // Add category filter if specified
      if (category != null && _poiCategories.containsKey(category)) {
        final types = _poiCategories[category]!.join('|');
        url += '&type=$types';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          return _parseGooglePlacesResponse(data, category ?? 'general');
        } else {
          print('Google Places API error: ${data['status']}');
          return _generateMockPOIs(category);
        }
      } else {
        print('Google Places API request failed: ${response.statusCode}');
        return _generateMockPOIs(category);
      }
    } catch (e) {
      print('Error discovering POIs: $e');
      return _generateMockPOIs(category);
    }
  }

  // Parse Google Places API response
  List<PointOfInterest> _parseGooglePlacesResponse(
    Map<String, dynamic> data, 
    String category
  ) {
    final results = data['results'] as List;
    
    return results.map<PointOfInterest>((place) {
      final geometry = place['geometry']['location'];
      final location = GeoLocation(
        id: place['place_id'],
        latitude: geometry['lat'].toDouble(),
        longitude: geometry['lng'].toDouble(),
        timestamp: DateTime.now(),
      );

      // Determine POI type from Google Places types
      final types = (place['types'] as List).cast<String>();
      final poiType = _determinePOIType(types);

      return PointOfInterest(
        id: place['place_id'],
        name: place['name'] ?? 'Unknown Location',
        description: _generatePOIDescription(poiType, place),
        location: location,
        type: poiType,
        category: category,
        rating: place['rating']?.toDouble() ?? 0.0,
        isDiscovered: false,
        discoveredAt: null,
        questPotential: _calculateQuestPotential(poiType, place),
        metadata: {
          'google_place_id': place['place_id'],
          'price_level': place['price_level'],
          'user_ratings_total': place['user_ratings_total'],
          'vicinity': place['vicinity'],
          'types': types,
          'photo_reference': place['photos']?.isNotEmpty == true 
              ? place['photos'][0]['photo_reference'] 
              : null,
        },
      );
    }).toList();
  }

  // Determine POI type from Google Places types
  POIType _determinePOIType(List<String> types) {
    // Priority mapping for POI types
    if (types.contains('gym') || types.contains('fitness_center')) {
      return POIType.fitness;
    }
    if (types.contains('restaurant') || types.contains('cafe') || types.contains('bar')) {
      return POIType.social;
    }
    if (types.contains('church') || types.contains('place_of_worship')) {
      return POIType.spiritual;
    }
    if (types.contains('park') || types.contains('nature_reserve')) {
      return POIType.nature;
    }
    if (types.contains('school') || types.contains('university') || types.contains('library')) {
      return POIType.education;
    }
    if (types.contains('shopping_mall') || types.contains('store')) {
      return POIType.shopping;
    }
    if (types.contains('hospital') || types.contains('doctor')) {
      return POIType.medical;
    }
    if (types.contains('movie_theater') || types.contains('amusement_park')) {
      return POIType.entertainment;
    }
    
    return POIType.generic;
  }

  // Generate POI description based on type
  String _generatePOIDescription(POIType type, Map<String, dynamic> place) {
    final name = place['name'] ?? 'Unknown Location';
    final vicinity = place['vicinity'] ?? '';
    
    switch (type) {
      case POIType.fitness:
        return 'Train your body and spirit at $name. Perfect for fitness quests and strength challenges.';
      case POIType.social:
        return 'Gather with fellow adventurers at $name. Social quests and community events await.';
      case POIType.spiritual:
        return 'Find inner peace and wisdom at $name. Meditation and holy quests can be discovered here.';
      case POIType.nature:
        return 'Explore the natural wonders of $name. Nature quests and exploration adventures begin here.';
      case POIType.education:
        return 'Expand your knowledge at $name. Learning quests and scholarly challenges await.';
      case POIType.shopping:
        return 'Discover treasures and trade at $name. Collection quests and trading opportunities available.';
      case POIType.medical:
        return 'Healing and restoration can be found at $name. Recovery quests and health challenges await.';
      case POIType.entertainment:
        return 'Fun and excitement await at $name. Entertainment quests and leisure activities available.';
      default:
        return 'Mysterious adventures await at $name in $vicinity.';
    }
  }

  // Calculate quest potential based on POI characteristics
  double _calculateQuestPotential(POIType type, Map<String, dynamic> place) {
    double potential = 0.5; // Base potential
    
    // Rating affects potential
    final rating = place['rating']?.toDouble() ?? 0.0;
    if (rating > 0) {
      potential += (rating / 5.0) * 0.3; // Max +0.3
    }
    
    // User ratings count affects potential
    final ratingsCount = place['user_ratings_total'] ?? 0;
    if (ratingsCount > 100) {
      potential += 0.2; // Popular places get bonus
    }
    
    // Type-specific bonuses
    switch (type) {
      case POIType.fitness:
      case POIType.nature:
        potential += 0.2; // Adventure-friendly locations
        break;
      case POIType.social:
      case POIType.entertainment:
        potential += 0.15; // Good for social quests
        break;
      default:
        break;
    }
    
    return math.min(1.0, potential); // Cap at 1.0
  }

  // Generate location-specific quests based on POI type
  Future<List<LocationQuest>> generateLocationQuests(PointOfInterest poi) async {
    final quests = <LocationQuest>[];
    
    switch (poi.type) {
      case POIType.fitness:
        quests.addAll(_generateFitnessQuests(poi));
        break;
      case POIType.social:
        quests.addAll(_generateSocialQuests(poi));
        break;
      case POIType.spiritual:
        quests.addAll(_generateSpiritualQuests(poi));
        break;
      case POIType.nature:
        quests.addAll(_generateNatureQuests(poi));
        break;
      case POIType.education:
        quests.addAll(_generateEducationQuests(poi));
        break;
      case POIType.shopping:
        quests.addAll(_generateShoppingQuests(poi));
        break;
      case POIType.medical:
        quests.addAll(_generateMedicalQuests(poi));
        break;
      case POIType.entertainment:
        quests.addAll(_generateEntertainmentQuests(poi));
        break;
      default:
        quests.addAll(_generateGenericQuests(poi));
        break;
    }
    
    return quests;
  }

  // Generate fitness-specific quests
  List<LocationQuest> _generateFitnessQuests(PointOfInterest poi) {
    return [
      LocationQuest(
        id: 'fitness_${poi.id}_workout',
        title: 'Warrior Training Session',
        description: 'Complete a workout session at ${poi.name} to gain strength and endurance.',
        location: poi,
        questType: 'fitness',
        difficulty: 'medium',
        experienceReward: 300,
        requirements: [
          'Visit ${poi.name}',
          'Spend 30 minutes training',
          'Complete 3 different exercises',
        ],
        objectives: [
          QuestObjective(
            id: 'visit_gym',
            description: 'Arrive at ${poi.name}',
            type: 'location_visit',
            targetValue: 1,
          ),
          QuestObjective(
            id: 'workout_duration',
            description: 'Train for 30 minutes',
            type: 'time_spent',
            targetValue: 1800, // 30 minutes in seconds
          ),
        ],
      ),
      LocationQuest(
        id: 'fitness_${poi.id}_strength',
        title: 'Forge of Power',
        description: 'Test your might in the halls of strength at ${poi.name}.',
        location: poi,
        questType: 'fitness',
        difficulty: 'hard',
        experienceReward: 500,
        requirements: [
          'Demonstrate strength training',
          'Complete endurance challenge',
        ],
      ),
    ];
  }

  // Generate social-specific quests
  List<LocationQuest> _generateSocialQuests(PointOfInterest poi) {
    return [
      LocationQuest(
        id: 'social_${poi.id}_gathering',
        title: 'Tavern Tales',
        description: 'Share stories and forge friendships at ${poi.name}.',
        location: poi,
        questType: 'social',
        difficulty: 'easy',
        experienceReward: 200,
        requirements: [
          'Visit ${poi.name}',
          'Interact with other patrons',
          'Share a story or listen to tales',
        ],
      ),
      LocationQuest(
        id: 'social_${poi.id}_network',
        title: 'Guild Recruitment',
        description: 'Build your network of allies at ${poi.name}.',
        location: poi,
        questType: 'social',
        difficulty: 'medium',
        experienceReward: 350,
        requirements: [
          'Meet 3 new people',
          'Exchange contact information',
        ],
      ),
    ];
  }

  // Generate spiritual/meditation quests
  List<LocationQuest> _generateSpiritualQuests(PointOfInterest poi) {
    return [
      LocationQuest(
        id: 'spiritual_${poi.id}_meditation',
        title: 'Sacred Contemplation',
        description: 'Find inner peace and wisdom through meditation at ${poi.name}.',
        location: poi,
        questType: 'spiritual',
        difficulty: 'easy',
        experienceReward: 250,
        requirements: [
          'Visit ${poi.name}',
          'Meditate for 15 minutes',
          'Reflect on personal growth',
        ],
      ),
      LocationQuest(
        id: 'spiritual_${poi.id}_pilgrimage',
        title: 'Pilgrimage of Understanding',
        description: 'Embark on a spiritual journey at ${poi.name}.',
        location: poi,
        questType: 'spiritual',
        difficulty: 'medium',
        experienceReward: 400,
        requirements: [
          'Spend 1 hour in contemplation',
          'Learn about the location\'s history',
        ],
      ),
    ];
  }

  // Generate nature exploration quests
  List<LocationQuest> _generateNatureQuests(PointOfInterest poi) {
    return [
      LocationQuest(
        id: 'nature_${poi.id}_explore',
        title: 'Nature\'s Secrets',
        description: 'Discover the hidden wonders of ${poi.name}.',
        location: poi,
        questType: 'exploration',
        difficulty: 'easy',
        experienceReward: 300,
        requirements: [
          'Explore different areas of ${poi.name}',
          'Take photos of interesting flora/fauna',
          'Walk for at least 30 minutes',
        ],
      ),
      LocationQuest(
        id: 'nature_${poi.id}_treasure',
        title: 'Geocache Hunter',
        description: 'Search for hidden treasures in the natural sanctuary of ${poi.name}.',
        location: poi,
        questType: 'collection',
        difficulty: 'medium',
        experienceReward: 450,
        requirements: [
          'Search for 3 hidden locations',
          'Document your discoveries',
        ],
      ),
    ];
  }

  // Generate education quests
  List<LocationQuest> _generateEducationQuests(PointOfInterest poi) {
    return [
      LocationQuest(
        id: 'education_${poi.id}_learn',
        title: 'Scholar\'s Quest',
        description: 'Expand your knowledge at ${poi.name}.',
        location: poi,
        questType: 'education',
        difficulty: 'medium',
        experienceReward: 350,
        requirements: [
          'Visit ${poi.name}',
          'Learn something new',
          'Share your knowledge with others',
        ],
      ),
    ];
  }

  // Generate shopping/collection quests
  List<LocationQuest> _generateShoppingQuests(PointOfInterest poi) {
    return [
      LocationQuest(
        id: 'shopping_${poi.id}_treasure',
        title: 'Merchant\'s Mission',
        description: 'Discover rare items and treasures at ${poi.name}.',
        location: poi,
        questType: 'collection',
        difficulty: 'easy',
        experienceReward: 200,
        requirements: [
          'Browse the merchant\'s wares',
          'Find 3 interesting items',
        ],
      ),
    ];
  }

  // Generate medical/healing quests
  List<LocationQuest> _generateMedicalQuests(PointOfInterest poi) {
    return [
      LocationQuest(
        id: 'medical_${poi.id}_wellness',
        title: 'Temple of Healing',
        description: 'Focus on health and wellness at ${poi.name}.',
        location: poi,
        questType: 'wellness',
        difficulty: 'easy',
        experienceReward: 250,
        requirements: [
          'Visit for health-related purpose',
          'Practice self-care',
        ],
      ),
    ];
  }

  // Generate entertainment quests
  List<LocationQuest> _generateEntertainmentQuests(PointOfInterest poi) {
    return [
      LocationQuest(
        id: 'entertainment_${poi.id}_fun',
        title: 'Jester\'s Challenge',
        description: 'Enjoy recreational activities at ${poi.name}.',
        location: poi,
        questType: 'entertainment',
        difficulty: 'easy',
        experienceReward: 200,
        requirements: [
          'Participate in an activity',
          'Have fun for at least 1 hour',
        ],
      ),
    ];
  }

  // Generate generic quests for unknown POI types
  List<LocationQuest> _generateGenericQuests(PointOfInterest poi) {
    return [
      LocationQuest(
        id: 'generic_${poi.id}_visit',
        title: 'Unknown Territory',
        description: 'Explore the mysteries of ${poi.name}.',
        location: poi,
        questType: 'exploration',
        difficulty: 'easy',
        experienceReward: 150,
        requirements: [
          'Visit ${poi.name}',
          'Spend 15 minutes exploring',
        ],
      ),
    ];
  }

  // Generate mock POIs for fallback when API fails
  List<PointOfInterest> _generateMockPOIs(String? category) {
    if (_currentLocation == null) return [];

    final mockPOIs = <PointOfInterest>[];
    final random = math.Random();

    // Generate a few mock POIs around current location
    for (int i = 0; i < 5; i++) {
      final distance = 200 + random.nextDouble() * 800; // 200-1000m away
      final angle = random.nextDouble() * 2 * math.pi;
      
      final lat = _currentLocation!.latitude + (distance * math.cos(angle)) / 111000;
      final lng = _currentLocation!.longitude + (distance * math.sin(angle)) / (111000 * math.cos(_currentLocation!.latitude * math.pi / 180));

      final types = [POIType.fitness, POIType.social, POIType.nature, POIType.entertainment, POIType.shopping];
      final type = types[random.nextInt(types.length)];

      mockPOIs.add(PointOfInterest(
        id: 'mock_poi_${i + 1}',
        name: 'Mock ${type.name.capitalized} Location ${i + 1}',
        description: 'A simulated location for testing purposes.',
        location: GeoLocation(
          id: 'mock_location_${i + 1}',
          latitude: lat,
          longitude: lng,
          timestamp: DateTime.now(),
        ),
        type: type,
        category: category ?? 'general',
        rating: 3.0 + random.nextDouble() * 2.0, // 3.0-5.0 rating
        isDiscovered: false,
        discoveredAt: null,
        questPotential: 0.5 + random.nextDouble() * 0.5, // 0.5-1.0 potential
        metadata: {
          'is_mock': true,
          'created_at': DateTime.now().toIso8601String(),
        },
      ));
    }

    return mockPOIs;
  }

  // Add geofence region
  Future<void> addGeofence(GeofenceRegion geofence) async {
    _activeGeofences.add(geofence);
    await _saveGeofences();
  }

  // Remove geofence
  Future<void> removeGeofence(String geofenceId) async {
    _activeGeofences.removeWhere((g) => g.id == geofenceId);
    await _saveGeofences();
  }

  // Create geofences for POIs
  Future<void> createGeofencesForPOIs(List<PointOfInterest> pois) async {
    for (final poi in pois) {
      final geofence = GeofenceRegion(
        id: 'poi_${poi.id}',
        name: poi.name,
        center: poi.location,
        radius: 100, // Small radius for POIs
        eventType: 'poi_entered',
        data: {
          'poi_id': poi.id,
          'poi_type': poi.type.toString(),
          'poi_description': poi.description,
        },
      );

      await addGeofence(geofence);
    }
  }

  // Create geofences for quests
  Future<void> createGeofencesForQuests(List<Quest> quests) async {
    for (final quest in quests) {
      if (quest.location != null) {
        final geofence = GeofenceRegion(
          id: 'quest_${quest.id}',
          name: quest.title,
          center: quest.location!,
          radius: quest.radius ?? 100,
          eventType: 'quest_area_entered',
          data: {
            'quest_id': quest.id,
            'quest_type': quest.type.toString(),
            'quest_level': quest.level,
          },
        );

        await addGeofence(geofence);
      }
    }
  }

  // Get nearby POIs
  Future<List<PointOfInterest>> getNearbyPOIs(GeoLocation location, {double radius = 1000}) async {
    // This would typically query a backend service
    // For now, returning sample POIs
    return _generateSamplePOIs(location, radius);
  }

  // Generate sample POIs for demonstration
  List<PointOfInterest> _generateSamplePOIs(GeoLocation center, double radius) {
    final pois = <PointOfInterest>[];
    final random = math.Random();

    final poiTypes = [
      POIType.park,
      POIType.gym,
      POIType.restaurant,
      POIType.monument,
      POIType.library,
    ];

    for (int i = 0; i < 10; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final distance = random.nextDouble() * radius;
      
      final lat = center.latitude + (distance * math.cos(angle)) / 111000;
      final lng = center.longitude + (distance * math.sin(angle)) / (111000 * math.cos(center.latitude * math.pi / 180));

      final poi = PointOfInterest(
        id: 'sample_poi_${i + 1}',
        name: 'Adventure Point ${i + 1}',
        description: 'A mysterious location waiting to be explored',
        location: GeoLocation(latitude: lat, longitude: lng),
        type: poiTypes[random.nextInt(poiTypes.length)],
        category: 'generic',
        rating: 0.0,
        isDiscovered: false,
        discoveredAt: null,
        questPotential: 0.5,
        metadata: {},
      );

      pois.add(poi);
    }

    return pois;
  }

  // Get location address
  Future<String> getAddressFromLocation(GeoLocation location) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.street}, ${place.locality}, ${place.country}';
      }
      
      return 'Unknown location';
    } catch (e) {
      print('Error getting address: $e');
      return 'Unknown location';
    }
  }

  // Generate adventure routes
  Future<List<AdventureRoute>> generateAdventureRoutes(GeoLocation startLocation) async {
    final routes = <AdventureRoute>[];

    // Sample route 1: Urban Explorer
    routes.add(AdventureRoute(
      id: 'urban_explorer_1',
      name: 'Urban Explorer Challenge',
      description: 'Discover hidden gems in your city with this exciting urban adventure route.',
      waypoints: _generateRouteWaypoints(startLocation, 5, 2000),
      totalDistance: 3500,
      estimatedDuration: 45,
      difficulty: 'Medium',
      highlights: ['Historic landmarks', 'Street art', 'Local cafes', 'Hidden alleys'],
      metadata: {
        'route_type': 'walking',
        'terrain': 'urban',
        'elevation_gain': 50,
      },
    ));

    // Sample route 2: Nature Trail
    routes.add(AdventureRoute(
      id: 'nature_trail_1',
      name: 'Mystic Forest Trail',
      description: 'Journey through enchanted woodlands and discover the secrets of nature.',
      waypoints: _generateRouteWaypoints(startLocation, 8, 5000),
      totalDistance: 6200,
      estimatedDuration: 90,
      difficulty: 'Hard',
      highlights: ['Ancient trees', 'Wildlife spotting', 'Scenic viewpoints', 'Hidden streams'],
      metadata: {
        'route_type': 'hiking',
        'terrain': 'forest',
        'elevation_gain': 200,
      },
    ));

    return routes;
  }

  // Generate waypoints for a route
  List<GeoLocation> _generateRouteWaypoints(GeoLocation start, int count, double maxRadius) {
    final waypoints = <GeoLocation>[start];
    final random = math.Random();
    
    GeoLocation current = start;
    
    for (int i = 0; i < count; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final distance = 200 + random.nextDouble() * 800; // 200-1000m between waypoints
      
      final lat = current.latitude + (distance * math.cos(angle)) / 111000;
      final lng = current.longitude + (distance * math.sin(angle)) / (111000 * math.cos(current.latitude * math.pi / 180));
      
      current = GeoLocation(latitude: lat, longitude: lng);
      waypoints.add(current);
    }
    
    return waypoints;
  }

  // Calculate route statistics
  Map<String, dynamic> calculateRouteStats(List<GeoLocation> route) {
    if (route.length < 2) return {};

    double totalDistance = 0;
    double maxElevation = route.first.altitude ?? 0;
    double minElevation = route.first.altitude ?? 0;

    for (int i = 1; i < route.length; i++) {
      totalDistance += route[i - 1].distanceTo(route[i]);
      
      if (route[i].altitude != null) {
        maxElevation = math.max(maxElevation, route[i].altitude!);
        minElevation = math.min(minElevation, route[i].altitude!);
      }
    }

    return {
      'total_distance': totalDistance,
      'elevation_gain': maxElevation - minElevation,
      'waypoint_count': route.length,
      'estimated_time': (totalDistance / 5.0 * 60).round(), // ~5 km/h walking speed
    };
  }

  // Data persistence
  Future<void> _saveGeofences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final geofenceJson = jsonEncode(_activeGeofences.map((g) => g.toJson()).toList());
      await prefs.setString('geofences', geofenceJson);
    } catch (e) {
      print('Error saving geofences: $e');
    }
  }

  Future<void> _loadGeofences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final geofenceJson = prefs.getString('geofences');
      
      if (geofenceJson != null) {
        final geofenceList = jsonDecode(geofenceJson) as List;
        _activeGeofences.addAll(geofenceList
            .map((json) => GeofenceRegion.fromJson(json))
            .toList());
      }
    } catch (e) {
      print('Error loading geofences: $e');
    }
  }

  Future<void> _saveLocationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = jsonEncode(_locationHistory.map((e) => e.toJson()).toList());
      await prefs.setString('location_history', historyJson);
    } catch (e) {
      print('Error saving location history: $e');
    }
  }

  Future<void> _loadLocationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('location_history');
      
      if (historyJson != null) {
        final historyList = jsonDecode(historyJson) as List;
        _locationHistory = historyList
            .map((json) => LocationEvent.fromJson(json))
            .toList();
      }
    } catch (e) {
      print('Error loading location history: $e');
    }
  }

  // Check geofences for triggers
  Future<void> _checkGeofenceRegions(GeoLocation location) async {
    for (final geofence in _activeGeofences) {
      if (!geofence.isActive) continue;

      if (geofence.containsLocation(location)) {
        final event = LocationEvent(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: geofence.eventType,
          location: location,
          timestamp: DateTime.now(),
          data: {
            'geofence_id': geofence.id,
            'geofence_name': geofence.name,
            ...geofence.data,
          },
        );

        _locationEventController.add(event);
      }
    }
  }

  // Trigger location-based events (e.g., quest generation)
  Future<void> _triggerLocationBasedEvents(GeoLocation location) async {
    if (_currentLocation == null) return;

    final nearbyPOIs = await discoverNearbyPOIs(radius: 1000);
    final discoveredPOIs = nearbyPOIs.where((poi) => poi.isDiscovered == false).toList();

    for (final poi in discoveredPOIs) {
      final quests = await generateLocationQuests(poi);
      for (final quest in quests) {
        final event = LocationEvent(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'quest_discovered',
          location: location,
          timestamp: DateTime.now(),
          data: {
            'quest_id': quest.id,
            'quest_title': quest.title,
            'quest_type': quest.questType,
            'quest_difficulty': quest.difficulty,
            'quest_experience_reward': quest.experienceReward,
            'quest_location_id': poi.id,
            'quest_location_name': poi.name,
          },
        );
        _locationEventController.add(event);
      }
      poi.isDiscovered = true;
      poi.discoveredAt = DateTime.now();
    }
  }

  // Cleanup
  void dispose() {
    stopTracking();
    _locationEventController.close();
  }
}