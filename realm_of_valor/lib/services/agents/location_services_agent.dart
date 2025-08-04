import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/event_bus.dart';
import '../../models/adventure_system.dart';
import '../../services/enhanced_location_service.dart';
import 'integration_orchestrator_agent.dart';

/// Location tracking mode
enum LocationTrackingMode {
  off,
  passive,
  active,
  adventure, // High accuracy for quests
}

/// Location event types
enum LocationEventType {
  moved,
  poiEntered,
  poiExited,
  geofenceEntered,
  geofenceExited,
  significantLocationChange,
  adventureLocationReached,
}

/// Enhanced POI with gameplay mechanics
class GamePOI {
  final String id;
  final String name;
  final String description;
  final GeoLocation location;
  final String category;
  final List<String> tags;
  final double interactionRadius;
  final Map<String, dynamic> rewards;
  final List<String> availableQuests;
  final List<String> availableARExperiences;
  final bool requiresDiscovery;
  final bool isActive;
  final DateTime? discoveredAt;
  final int visitCount;

  GamePOI({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.category,
    List<String>? tags,
    this.interactionRadius = 50.0,
    Map<String, dynamic>? rewards,
    List<String>? availableQuests,
    List<String>? availableARExperiences,
    this.requiresDiscovery = false,
    this.isActive = true,
    this.discoveredAt,
    this.visitCount = 0,
  }) : tags = tags ?? [],
       rewards = rewards ?? {},
       availableQuests = availableQuests ?? [],
       availableARExperiences = availableARExperiences ?? [];

  GamePOI copyWith({
    String? id,
    String? name,
    String? description,
    GeoLocation? location,
    String? category,
    List<String>? tags,
    double? interactionRadius,
    Map<String, dynamic>? rewards,
    List<String>? availableQuests,
    List<String>? availableARExperiences,
    bool? requiresDiscovery,
    bool? isActive,
    DateTime? discoveredAt,
    int? visitCount,
  }) {
    return GamePOI(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      interactionRadius: interactionRadius ?? this.interactionRadius,
      rewards: rewards ?? this.rewards,
      availableQuests: availableQuests ?? this.availableQuests,
      availableARExperiences: availableARExperiences ?? this.availableARExperiences,
      requiresDiscovery: requiresDiscovery ?? this.requiresDiscovery,
      isActive: isActive ?? this.isActive,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      visitCount: visitCount ?? this.visitCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location.toJson(),
      'category': category,
      'tags': tags,
      'interactionRadius': interactionRadius,
      'rewards': rewards,
      'availableQuests': availableQuests,
      'availableARExperiences': availableARExperiences,
      'requiresDiscovery': requiresDiscovery,
      'isActive': isActive,
      'discoveredAt': discoveredAt?.toIso8601String(),
      'visitCount': visitCount,
    };
  }

  factory GamePOI.fromJson(Map<String, dynamic> json) {
    return GamePOI(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      location: GeoLocation.fromJson(json['location']),
      category: json['category'],
      tags: List<String>.from(json['tags'] ?? []),
      interactionRadius: (json['interactionRadius'] ?? 50.0).toDouble(),
      rewards: Map<String, dynamic>.from(json['rewards'] ?? {}),
      availableQuests: List<String>.from(json['availableQuests'] ?? []),
      availableARExperiences: List<String>.from(json['availableARExperiences'] ?? []),
      requiresDiscovery: json['requiresDiscovery'] ?? false,
      isActive: json['isActive'] ?? true,
      discoveredAt: json['discoveredAt'] != null ? DateTime.parse(json['discoveredAt']) : null,
      visitCount: json['visitCount'] ?? 0,
    );
  }
}

/// User location data
class UserLocationData {
  final String userId;
  final GeoLocation currentLocation;
  final DateTime lastUpdate;
  final double accuracy;
  final double speed;
  final double heading;
  final List<String> nearbyPOIs;
  final List<String> activeGeofences;
  final Map<String, dynamic> locationMetrics;

  UserLocationData({
    required this.userId,
    required this.currentLocation,
    DateTime? lastUpdate,
    this.accuracy = 0.0,
    this.speed = 0.0,
    this.heading = 0.0,
    List<String>? nearbyPOIs,
    List<String>? activeGeofences,
    Map<String, dynamic>? locationMetrics,
  }) : lastUpdate = lastUpdate ?? DateTime.now(),
       nearbyPOIs = nearbyPOIs ?? [],
       activeGeofences = activeGeofences ?? [],
       locationMetrics = locationMetrics ?? {};

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'currentLocation': currentLocation.toJson(),
      'lastUpdate': lastUpdate.toIso8601String(),
      'accuracy': accuracy,
      'speed': speed,
      'heading': heading,
      'nearbyPOIs': nearbyPOIs,
      'activeGeofences': activeGeofences,
      'locationMetrics': locationMetrics,
    };
  }

  factory UserLocationData.fromJson(Map<String, dynamic> json) {
    return UserLocationData(
      userId: json['userId'],
      currentLocation: GeoLocation.fromJson(json['currentLocation']),
      lastUpdate: DateTime.parse(json['lastUpdate']),
      accuracy: (json['accuracy'] ?? 0.0).toDouble(),
      speed: (json['speed'] ?? 0.0).toDouble(),
      heading: (json['heading'] ?? 0.0).toDouble(),
      nearbyPOIs: List<String>.from(json['nearbyPOIs'] ?? []),
      activeGeofences: List<String>.from(json['activeGeofences'] ?? []),
      locationMetrics: Map<String, dynamic>.from(json['locationMetrics'] ?? {}),
    );
  }
}

/// Location Services Agent - GPS integration with POI system and geofencing
class LocationServicesAgent extends BaseAgent {
  static const String agentId = 'location_services';

  final SharedPreferences _prefs;
  final EnhancedLocationService? _enhancedLocationService;

  // Current user context
  String? _currentUserId;
  LocationTrackingMode _trackingMode = LocationTrackingMode.passive;

  // Location data
  final Map<String, UserLocationData> _userLocations = {}; // userId -> location data
  final Map<String, GamePOI> _gamePOIs = {};
  final Map<String, GeofenceRegion> _geofenceRegions = {};

  // User discovery tracking
  final Map<String, Set<String>> _userDiscoveredPOIs = {}; // userId -> Set<poiId>
  final Map<String, Map<String, int>> _userPOIVisitCounts = {}; // userId -> poiId -> count

  // Location tracking
  StreamSubscription<Position>? _locationSubscription;
  Timer? _locationAnalysisTimer;
  Timer? _poisRefreshTimer;

  // Performance monitoring
  final List<Map<String, dynamic>> _locationEvents = [];
  int _totalLocationUpdates = 0;
  DateTime? _lastLocationUpdate;

  LocationServicesAgent({
    required SharedPreferences prefs,
    EnhancedLocationService? enhancedLocationService,
  }) : _prefs = prefs,
       _enhancedLocationService = enhancedLocationService,
       super(agentId: agentId);

  @override
  Future<void> onInitialize() async {
    developer.log('Initializing Location Services Agent', name: agentId);

    // Load POI database
    await _loadPOIDatabase();
    
    // Load geofence regions
    await _loadGeofenceRegions();

    // Load user location data
    await _loadUserLocationData();

    // Initialize location tracking
    await _initializeLocationTracking();

    // Start periodic tasks
    _startPeriodicTasks();

    developer.log('Location Services Agent initialized with ${_gamePOIs.length} POIs and ${_geofenceRegions.length} geofences', name: agentId);
  }

  @override
  void subscribeToEvents() {
    // Location management events
    subscribe('start_location_tracking', _handleStartLocationTracking);
    subscribe('stop_location_tracking', _handleStopLocationTracking);
    subscribe('set_tracking_mode', _handleSetTrackingMode);
    subscribe('get_user_location', _handleGetUserLocation);

    // POI management events
    subscribe('get_nearby_pois', _handleGetNearbyPOIs);
    subscribe('visit_poi', _handleVisitPOI);
    subscribe('discover_poi', _handleDiscoverPOI);
    subscribe('get_poi_details', _handleGetPOIDetails);

    // Geofence management events
    subscribe('create_geofence', _handleCreateGeofence);
    subscribe('remove_geofence', _handleRemoveGeofence);
    subscribe('get_active_geofences', _handleGetActiveGeofences);

    // Quest integration events
    subscribe('setup_quest_geofences', _handleSetupQuestGeofences);
    subscribe('remove_quest_geofences', _handleRemoveQuestGeofences);

    // Location metrics events
    subscribe('get_location_metrics', _handleGetLocationMetrics);
    subscribe('get_travel_summary', _handleGetTravelSummary);

    // User management
    subscribe('user_login', _handleUserLogin);
    subscribe('user_logout', _handleUserLogout);

    // Data persistence
    subscribe('save_location_data', _handleSaveLocationData);
    subscribe('load_location_data', _handleLoadLocationData);
  }

  /// Set location tracking mode
  Future<void> setTrackingMode(LocationTrackingMode mode) async {
    if (_trackingMode == mode) return;

    final previousMode = _trackingMode;
    _trackingMode = mode;

    // Restart location tracking with new settings
    await _restartLocationTracking();

    // Publish tracking mode change event
    await publishEvent(createEvent(
      eventType: 'location_tracking_mode_changed',
      data: {
        'previousMode': previousMode.toString(),
        'newMode': mode.toString(),
        'userId': _currentUserId,
      },
    ));

    developer.log('Location tracking mode changed: $previousMode -> $mode', name: agentId);
  }

  /// Get nearby POIs for a user
  List<GamePOI> getNearbyPOIs(String userId, {double radius = 1000.0}) {
    final userLocation = _userLocations[userId];
    if (userLocation == null) return [];

    final nearbyPOIs = <GamePOI>[];
    final userDiscovered = _userDiscoveredPOIs[userId] ?? <String>{};

    for (final poi in _gamePOIs.values) {
      if (!poi.isActive) continue;

      // Skip if requires discovery and not yet discovered
      if (poi.requiresDiscovery && !userDiscovered.contains(poi.id)) {
        continue;
      }

      final distance = poi.location.distanceTo(userLocation.currentLocation);
      if (distance <= radius) {
        nearbyPOIs.add(poi);
      }
    }

    // Sort by distance
    nearbyPOIs.sort((a, b) {
      final distanceA = a.location.distanceTo(userLocation.currentLocation);
      final distanceB = b.location.distanceTo(userLocation.currentLocation);
      return distanceA.compareTo(distanceB);
    });

    return nearbyPOIs;
  }

  /// Visit a POI
  Future<Map<String, dynamic>?> visitPOI(String userId, String poiId) async {
    final poi = _gamePOIs[poiId];
    final userLocation = _userLocations[userId];
    
    if (poi == null || userLocation == null) return null;

    // Check if user is within interaction radius
    final distance = poi.location.distanceTo(userLocation.currentLocation);
    if (distance > poi.interactionRadius) {
      return {
        'success': false,
        'error': 'Too far from POI',
        'distance': distance,
        'requiredDistance': poi.interactionRadius,
      };
    }

    // Update visit count
    final userVisitCounts = _userPOIVisitCounts.putIfAbsent(userId, () => {});
    final previousVisits = userVisitCounts[poiId] ?? 0;
    userVisitCounts[poiId] = previousVisits + 1;

    // Mark as discovered if not already
    final userDiscovered = _userDiscoveredPOIs.putIfAbsent(userId, () => <String>{});
    final wasDiscovered = userDiscovered.contains(poiId);
    if (!wasDiscovered) {
      userDiscovered.add(poiId);
    }

    // Distribute rewards (only on first visit for most rewards)
    Map<String, dynamic> rewards = {};
    if (poi.rewards.isNotEmpty && previousVisits == 0) {
      rewards = Map.from(poi.rewards);
      await _distributePOIRewards(userId, poi, rewards);
    }

    // Publish POI visit event
    await publishEvent(createEvent(
      eventType: EventTypes.poiDetected,
      data: {
        'userId': userId,
        'poiId': poiId,
        'poi': poi.toJson(),
        'distance': distance,
        'visitCount': userVisitCounts[poiId],
        'firstVisit': previousVisits == 0,
        'rewards': rewards,
        'availableQuests': poi.availableQuests,
        'availableARExperiences': poi.availableARExperiences,
      },
      priority: EventPriority.high,
    ));

    _logLocationEvent('poi_visited', {
      'userId': userId,
      'poiId': poiId,
      'distance': distance,
      'visitCount': userVisitCounts[poiId],
    });

    await _saveUserLocationData(userId);

    return {
      'success': true,
      'poi': poi.toJson(),
      'distance': distance,
      'visitCount': userVisitCounts[poiId],
      'firstVisit': previousVisits == 0,
      'rewards': rewards,
      'availableQuests': poi.availableQuests,
      'availableARExperiences': poi.availableARExperiences,
    };
  }

  /// Create a geofence region
  String createGeofence({
    required String name,
    required GeoLocation center,
    required double radius,
    required String eventType,
    Map<String, dynamic>? data,
    bool isActive = true,
  }) {
    final geofenceId = 'geofence_${DateTime.now().millisecondsSinceEpoch}';
    
    final geofence = GeofenceRegion(
      id: geofenceId,
      name: name,
      center: center,
      radius: radius,
      eventType: eventType,
      data: data ?? {},
      isActive: isActive,
    );

    _geofenceRegions[geofenceId] = geofence;

    developer.log('Created geofence: $name at ${center.latitude}, ${center.longitude}', name: agentId);
    return geofenceId;
  }

  /// Remove a geofence region
  bool removeGeofence(String geofenceId) {
    final removed = _geofenceRegions.remove(geofenceId);
    if (removed != null) {
      developer.log('Removed geofence: ${removed.name}', name: agentId);
      return true;
    }
    return false;
  }

  /// Get location metrics for a user
  Map<String, dynamic> getLocationMetrics(String userId) {
    final userLocation = _userLocations[userId];
    if (userLocation == null) {
      return {'error': 'No location data for user'};
    }

    final discoveredPOIs = _userDiscoveredPOIs[userId]?.length ?? 0;
    final totalVisits = _userPOIVisitCounts[userId]?.values.fold(0, (sum, count) => sum + count) ?? 0;
    final uniquePOIsVisited = _userPOIVisitCounts[userId]?.keys.length ?? 0;

    return {
      'userId': userId,
      'currentLocation': userLocation.currentLocation.toJson(),
      'lastUpdate': userLocation.lastUpdate.toIso8601String(),
      'accuracy': userLocation.accuracy,
      'speed': userLocation.speed,
      'discoveredPOIs': discoveredPOIs,
      'totalPOIVisits': totalVisits,
      'uniquePOIsVisited': uniquePOIsVisited,
      'nearbyPOIs': userLocation.nearbyPOIs.length,
      'activeGeofences': userLocation.activeGeofences.length,
      'locationMetrics': userLocation.locationMetrics,
    };
  }

  /// Initialize location tracking
  Future<void> _initializeLocationTracking() async {
    try {
      // Check location permissions
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requestedPermission = await Geolocator.requestPermission();
        if (requestedPermission == LocationPermission.denied) {
          developer.log('Location permission denied', name: agentId);
          return;
        }
      }

      await _startLocationTracking();
      developer.log('Location tracking initialized successfully', name: agentId);
    } catch (e) {
      developer.log('Error initializing location tracking: $e', name: agentId);
    }
  }

  /// Start location tracking based on current mode
  Future<void> _startLocationTracking() async {
    // Cancel existing subscription
    _locationSubscription?.cancel();

    LocationSettings locationSettings;
    switch (_trackingMode) {
      case LocationTrackingMode.off:
        return; // Don't start tracking
      case LocationTrackingMode.passive:
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.low,
          distanceFilter: 100, // Update every 100 meters
        );
        break;
      case LocationTrackingMode.active:
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 50, // Update every 50 meters
        );
        break;
      case LocationTrackingMode.adventure:
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        );
        break;
    }

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(_onLocationUpdate);

    developer.log('Started location tracking in $_trackingMode mode', name: agentId);
  }

  /// Restart location tracking with current settings
  Future<void> _restartLocationTracking() async {
    await _startLocationTracking();
  }

  /// Handle location updates
  void _onLocationUpdate(Position position) {
    if (_currentUserId == null) return;

    _totalLocationUpdates++;
    _lastLocationUpdate = DateTime.now();

    final geoLocation = GeoLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      accuracy: position.accuracy,
      timestamp: position.timestamp,
    );

    final previousLocation = _userLocations[_currentUserId!];

    // Calculate speed and heading if we have previous location
    double speed = position.speed;
    double heading = position.heading;

    if (previousLocation != null && speed == 0.0) {
      final distance = geoLocation.distanceTo(previousLocation.currentLocation);
      final timeDiff = geoLocation.timestamp!.difference(previousLocation.currentLocation.timestamp!).inSeconds;
      if (timeDiff > 0) {
        speed = distance / timeDiff; // m/s
      }
    }

    // Update user location data
    final userLocationData = UserLocationData(
      userId: _currentUserId!,
      currentLocation: geoLocation,
      accuracy: position.accuracy,
      speed: speed,
      heading: heading,
      locationMetrics: _calculateLocationMetrics(previousLocation, geoLocation),
    );

    _userLocations[_currentUserId!] = userLocationData;

    // Process location update
    _processLocationUpdate(_currentUserId!, userLocationData);

    // Publish location update event
    publishEvent(createEvent(
      eventType: EventTypes.locationUpdate,
      data: {
        'userId': _currentUserId,
        'location': geoLocation.toJson(),
        'accuracy': position.accuracy,
        'speed': speed,
        'heading': heading,
      },
    ));

    _logLocationEvent('location_update', {
      'userId': _currentUserId,
      'accuracy': position.accuracy,
      'speed': speed,
    });
  }

  /// Process location update for POI and geofence detection
  void _processLocationUpdate(String userId, UserLocationData locationData) {
    final currentLocation = locationData.currentLocation;

    // Check for nearby POIs
    final nearbyPOIs = <String>[];
    final userDiscovered = _userDiscoveredPOIs[userId] ?? <String>{};

    for (final poi in _gamePOIs.values) {
      if (!poi.isActive) continue;

      final distance = poi.location.distanceTo(currentLocation);
      
      // Add to nearby if within interaction radius
      if (distance <= poi.interactionRadius) {
        nearbyPOIs.add(poi.id);

        // Auto-discover POI if user is very close and it doesn't require special discovery
        if (!poi.requiresDiscovery && distance <= 20.0 && !userDiscovered.contains(poi.id)) {
          userDiscovered.add(poi.id);
          _userDiscoveredPOIs[userId] = userDiscovered;

          publishEvent(createEvent(
            eventType: 'poi_discovered',
            data: {
              'userId': userId,
              'poiId': poi.id,
              'poi': poi.toJson(),
              'distance': distance,
              'autoDiscovered': true,
            },
          ));
        }
      }
    }

    // Check geofences
    final activeGeofences = <String>[];
    for (final geofence in _geofenceRegions.values) {
      if (!geofence.isActive) continue;

      final wasInside = geofence.data['userInside_$userId'] == true;
      final isInside = geofence.containsLocation(currentLocation);

      if (!wasInside && isInside) {
        // Entered geofence
        geofence.data['userInside_$userId'] = true;
        activeGeofences.add(geofence.id);

        publishEvent(createEvent(
          eventType: EventTypes.geofenceEntered,
          data: {
            'userId': userId,
            'geofenceId': geofence.id,
            'geofenceName': geofence.name,
            'eventType': geofence.eventType,
            'data': geofence.data,
          },
        ));
      } else if (wasInside && !isInside) {
        // Exited geofence
        geofence.data['userInside_$userId'] = false;

        publishEvent(createEvent(
          eventType: EventTypes.geofenceExited,
          data: {
            'userId': userId,
            'geofenceId': geofence.id,
            'geofenceName': geofence.name,
            'eventType': geofence.eventType,
            'data': geofence.data,
          },
        ));
      }

      if (isInside) {
        activeGeofences.add(geofence.id);
      }
    }

    // Update user location data with nearby POIs and active geofences
    _userLocations[userId] = UserLocationData(
      userId: userId,
      currentLocation: currentLocation,
      accuracy: locationData.accuracy,
      speed: locationData.speed,
      heading: locationData.heading,
      nearbyPOIs: nearbyPOIs,
      activeGeofences: activeGeofences,
      locationMetrics: locationData.locationMetrics,
    );
  }

  /// Calculate location metrics
  Map<String, dynamic> _calculateLocationMetrics(UserLocationData? previous, GeoLocation current) {
    final metrics = <String, dynamic>{};

    if (previous != null) {
      final distance = current.distanceTo(previous.currentLocation);
      final timeDiff = current.timestamp!.difference(previous.currentLocation.timestamp!).inSeconds;
      
      metrics['distanceTraveled'] = distance;
      metrics['timeDelta'] = timeDiff;
      metrics['averageSpeed'] = timeDiff > 0 ? distance / timeDiff : 0.0;
    }

    metrics['timestamp'] = current.timestamp!.toIso8601String();
    return metrics;
  }

  /// Load POI database
  Future<void> _loadPOIDatabase() async {
    // Initialize with some example POIs
    _gamePOIs.addAll({
      'central_park_poi': GamePOI(
        id: 'central_park_poi',
        name: 'Central Park Adventure Zone',
        description: 'A magical place where adventures begin',
        location: GeoLocation(latitude: 40.7851, longitude: -73.9683),
        category: 'park',
        tags: ['nature', 'adventure', 'quests'],
        interactionRadius: 75.0,
        rewards: {
          'xp': 100,
          'gold': 25,
          'cards': ['nature_blessing'],
        },
        availableQuests: ['park_ranger', 'nature_photographer'],
        availableARExperiences: ['park_treasure', 'wildlife_scanner'],
        requiresDiscovery: false,
      ),
      'library_poi': GamePOI(
        id: 'library_poi',
        name: 'Ancient Library of Knowledge',
        description: 'A repository of ancient wisdom and modern learning',
        location: GeoLocation(latitude: 40.7531, longitude: -73.9822),
        category: 'landmark',
        tags: ['education', 'wisdom', 'puzzles'],
        interactionRadius: 50.0,
        rewards: {
          'xp': 150,
          'statBonus': {'intelligence': 2},
          'cards': ['wisdom_scroll'],
        },
        availableQuests: ['knowledge_seeker', 'puzzle_master'],
        availableARExperiences: ['library_puzzle', 'ancient_text_scanner'],
        requiresDiscovery: false,
      ),
      'museum_poi': GamePOI(
        id: 'museum_poi',
        name: 'Museum of Wonders',
        description: 'Artifacts from around the world await discovery',
        location: GeoLocation(latitude: 40.7614, longitude: -73.9776),
        category: 'culture',
        tags: ['history', 'artifacts', 'discovery'],
        interactionRadius: 60.0,
        rewards: {
          'xp': 200,
          'gold': 50,
          'cards': ['ancient_artifact', 'historian_badge'],
        },
        availableQuests: ['artifact_hunter', 'time_traveler'],
        availableARExperiences: ['artifact_scanner', 'historical_overlay'],
        requiresDiscovery: true, // Must be specifically discovered
      ),
      'hidden_cave_poi': GamePOI(
        id: 'hidden_cave_poi',
        name: 'Hidden Cave of Mysteries',
        description: 'A secret cave known only to true explorers',
        location: GeoLocation(latitude: 40.7505, longitude: -73.9934),
        category: 'secret',
        tags: ['hidden', 'treasure', 'mystery'],
        interactionRadius: 25.0,
        rewards: {
          'xp': 500,
          'gold': 200,
          'cards': ['cave_explorer_gear', 'mysterious_crystal'],
        },
        availableQuests: ['cave_explorer', 'crystal_seeker'],
        availableARExperiences: ['crystal_resonance', 'cave_painting_scanner'],
        requiresDiscovery: true,
      ),
    });

    developer.log('Loaded ${_gamePOIs.length} POIs', name: agentId);
  }

  /// Load geofence regions
  Future<void> _loadGeofenceRegions() async {
    // Load saved geofences from preferences
    final geofencesJson = _prefs.getString('geofence_regions');
    if (geofencesJson != null) {
      try {
        final data = jsonDecode(geofencesJson) as Map<String, dynamic>;
        for (final entry in data.entries) {
          _geofenceRegions[entry.key] = GeofenceRegion.fromJson(entry.value);
        }
      } catch (e) {
        developer.log('Error loading geofence regions: $e', name: agentId);
      }
    }

    developer.log('Loaded ${_geofenceRegions.length} geofence regions', name: agentId);
  }

  /// Distribute POI rewards
  Future<void> _distributePOIRewards(String userId, GamePOI poi, Map<String, dynamic> rewards) async {
    // Distribute XP and stat bonuses
    if (rewards.containsKey('xp') || rewards.containsKey('statBonus')) {
      await publishEvent(createEvent(
        eventType: 'character_reward',
        targetAgent: 'character_management',
        data: {
          'userId': userId,
          'xp': rewards['xp'] ?? 0,
          'statBonus': rewards['statBonus'] ?? {},
          'source': 'poi_visit_${poi.id}',
        },
      ));
    }

    // Distribute cards and gold
    if (rewards.containsKey('cards') || rewards.containsKey('gold')) {
      await publishEvent(createEvent(
        eventType: 'inventory_reward',
        targetAgent: 'card_system',
        data: {
          'userId': userId,
          'cards': rewards['cards'] ?? [],
          'gold': rewards['gold'] ?? 0,
          'source': 'poi_visit_${poi.id}',
        },
      ));
    }
  }

  /// Start periodic tasks
  void _startPeriodicTasks() {
    // Location analysis timer
    _locationAnalysisTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _performLocationAnalysis();
    });

    // POI refresh timer
    _poisRefreshTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _refreshPOIData();
    });
  }

  /// Perform periodic location analysis
  void _performLocationAnalysis() {
    if (_currentUserId == null) return;

    // Analyze user movement patterns, suggest nearby POIs, etc.
    final userLocation = _userLocations[_currentUserId!];
    if (userLocation == null) return;

    // Check for POIs that user might be interested in
    final suggestedPOIs = getNearbyPOIs(_currentUserId!, radius: 500.0);
    if (suggestedPOIs.isNotEmpty) {
      publishEvent(createEvent(
        eventType: 'location_suggestions',
        data: {
          'userId': _currentUserId,
          'suggestedPOIs': suggestedPOIs.take(3).map((poi) => poi.toJson()).toList(),
          'reason': 'nearby_analysis',
        },
      ));
    }
  }

  /// Refresh POI data
  void _refreshPOIData() {
    // This could involve loading new POIs from a server, updating existing ones, etc.
    developer.log('Refreshing POI data', name: agentId);
  }

  /// Load user location data
  Future<void> _loadUserLocationData() async {
    final locationDataJson = _prefs.getString('user_location_data');
    if (locationDataJson != null) {
      try {
        final data = jsonDecode(locationDataJson) as Map<String, dynamic>;
        
        // Load user locations
        if (data['userLocations'] != null) {
          final userLocationData = data['userLocations'] as Map<String, dynamic>;
          for (final entry in userLocationData.entries) {
            _userLocations[entry.key] = UserLocationData.fromJson(entry.value);
          }
        }

        // Load discovered POIs
        if (data['discoveredPOIs'] != null) {
          final discoveredData = data['discoveredPOIs'] as Map<String, dynamic>;
          for (final entry in discoveredData.entries) {
            _userDiscoveredPOIs[entry.key] = Set<String>.from(entry.value);
          }
        }

        // Load visit counts
        if (data['visitCounts'] != null) {
          final visitCountData = data['visitCounts'] as Map<String, dynamic>;
          for (final entry in visitCountData.entries) {
            _userPOIVisitCounts[entry.key] = Map<String, int>.from(entry.value);
          }
        }
      } catch (e) {
        developer.log('Error loading user location data: $e', name: agentId);
      }
    }
  }

  /// Save user location data
  Future<void> _saveUserLocationData(String userId) async {
    // Save to Data Persistence Agent
    await publishEvent(createEvent(
      eventType: 'save_data',
      targetAgent: 'data_persistence',
      data: {
        'collection': 'user_location_data',
        'id': userId,
        'data': {
          'currentLocation': _userLocations[userId]?.toJson(),
          'discoveredPOIs': _userDiscoveredPOIs[userId]?.toList() ?? [],
          'visitCounts': _userPOIVisitCounts[userId] ?? {},
        },
      },
    ));

    // Also save to SharedPreferences as backup
    await _saveAllLocationData();
  }

  /// Save all location data to SharedPreferences
  Future<void> _saveAllLocationData() async {
    final data = {
      'userLocations': _userLocations.map((k, v) => MapEntry(k, v.toJson())),
      'discoveredPOIs': _userDiscoveredPOIs.map((k, v) => MapEntry(k, v.toList())),
      'visitCounts': _userPOIVisitCounts,
    };
    await _prefs.setString('user_location_data', jsonEncode(data));

    // Save geofences
    final geofenceData = _geofenceRegions.map((k, v) => MapEntry(k, v.toJson()));
    await _prefs.setString('geofence_regions', jsonEncode(geofenceData));
  }

  /// Log location event
  void _logLocationEvent(String eventType, Map<String, dynamic> data) {
    _locationEvents.add({
      'eventType': eventType,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Keep only last 100 events
    if (_locationEvents.length > 100) {
      _locationEvents.removeAt(0);
    }
  }

  // Event Handlers

  /// Handle start location tracking events
  Future<AgentEventResponse?> _handleStartLocationTracking(AgentEvent event) async {
    final mode = event.data['mode'];
    
    if (mode != null) {
      final trackingMode = LocationTrackingMode.values.firstWhere(
        (m) => m.toString() == mode,
        orElse: () => LocationTrackingMode.active,
      );
      await setTrackingMode(trackingMode);
    } else {
      await _startLocationTracking();
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'location_tracking_started',
      data: {
        'mode': _trackingMode.toString(),
        'success': true,
      },
    );
  }

  /// Handle stop location tracking events
  Future<AgentEventResponse?> _handleStopLocationTracking(AgentEvent event) async {
    _locationSubscription?.cancel();
    _locationSubscription = null;

    return createResponse(
      originalEventId: event.id,
      responseType: 'location_tracking_stopped',
      data: {'success': true},
    );
  }

  /// Handle set tracking mode events
  Future<AgentEventResponse?> _handleSetTrackingMode(AgentEvent event) async {
    final mode = event.data['mode'];
    
    if (mode == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'set_tracking_mode_failed',
        data: {'error': 'No mode specified'},
        success: false,
      );
    }

    final trackingMode = LocationTrackingMode.values.firstWhere(
      (m) => m.toString() == mode,
      orElse: () => LocationTrackingMode.active,
    );

    await setTrackingMode(trackingMode);

    return createResponse(
      originalEventId: event.id,
      responseType: 'tracking_mode_set',
      data: {'mode': trackingMode.toString()},
    );
  }

  /// Handle get user location events
  Future<AgentEventResponse?> _handleGetUserLocation(AgentEvent event) async {
    final userId = event.data['userId'] ?? _currentUserId;
    
    if (userId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'get_location_failed',
        data: {'error': 'No user ID provided'},
        success: false,
      );
    }

    final userLocation = _userLocations[userId];
    
    return createResponse(
      originalEventId: event.id,
      responseType: 'user_location',
      data: userLocation?.toJson() ?? {'error': 'No location data available'},
      success: userLocation != null,
    );
  }

  /// Handle get nearby POIs events
  Future<AgentEventResponse?> _handleGetNearbyPOIs(AgentEvent event) async {
    final userId = event.data['userId'] ?? _currentUserId;
    final radius = (event.data['radius'] ?? 1000.0).toDouble();
    
    if (userId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'get_pois_failed',
        data: {'error': 'No user ID provided'},
        success: false,
      );
    }

    final nearbyPOIs = getNearbyPOIs(userId, radius: radius);
    
    return createResponse(
      originalEventId: event.id,
      responseType: 'nearby_pois',
      data: {
        'pois': nearbyPOIs.map((poi) => poi.toJson()).toList(),
        'count': nearbyPOIs.length,
        'radius': radius,
      },
    );
  }

  /// Handle visit POI events
  Future<AgentEventResponse?> _handleVisitPOI(AgentEvent event) async {
    final userId = event.data['userId'] ?? _currentUserId;
    final poiId = event.data['poiId'];
    
    if (userId == null || poiId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'visit_poi_failed',
        data: {'error': 'Missing required parameters'},
        success: false,
      );
    }

    final result = await visitPOI(userId, poiId);
    
    return createResponse(
      originalEventId: event.id,
      responseType: result?['success'] == true ? 'poi_visited' : 'visit_poi_failed',
      data: result ?? {'error': 'Failed to visit POI'},
      success: result?['success'] == true,
    );
  }

  /// Handle discover POI events
  Future<AgentEventResponse?> _handleDiscoverPOI(AgentEvent event) async {
    final userId = event.data['userId'] ?? _currentUserId;
    final poiId = event.data['poiId'];
    
    if (userId == null || poiId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'discover_poi_failed',
        data: {'error': 'Missing required parameters'},
        success: false,
      );
    }

    final userDiscovered = _userDiscoveredPOIs.putIfAbsent(userId, () => <String>{});
    final wasAlreadyDiscovered = userDiscovered.contains(poiId);
    
    if (!wasAlreadyDiscovered) {
      userDiscovered.add(poiId);
      await _saveUserLocationData(userId);
      
      final poi = _gamePOIs[poiId];
      if (poi != null) {
        await publishEvent(createEvent(
          eventType: 'poi_discovered',
          data: {
            'userId': userId,
            'poiId': poiId,
            'poi': poi.toJson(),
            'manualDiscovery': true,
          },
        ));
      }
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'poi_discovered',
      data: {
        'poiId': poiId,
        'alreadyDiscovered': wasAlreadyDiscovered,
      },
    );
  }

  /// Handle get POI details events
  Future<AgentEventResponse?> _handleGetPOIDetails(AgentEvent event) async {
    final poiId = event.data['poiId'];
    
    if (poiId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'get_poi_details_failed',
        data: {'error': 'No POI ID provided'},
        success: false,
      );
    }

    final poi = _gamePOIs[poiId];
    
    return createResponse(
      originalEventId: event.id,
      responseType: 'poi_details',
      data: poi?.toJson() ?? {'error': 'POI not found'},
      success: poi != null,
    );
  }

  /// Handle create geofence events
  Future<AgentEventResponse?> _handleCreateGeofence(AgentEvent event) async {
    final name = event.data['name'];
    final centerData = event.data['center'];
    final radius = event.data['radius'];
    final eventType = event.data['eventType'];
    final data = event.data['data'];
    
    if (name == null || centerData == null || radius == null || eventType == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'create_geofence_failed',
        data: {'error': 'Missing required parameters'},
        success: false,
      );
    }

    final center = GeoLocation.fromJson(centerData);
    final geofenceId = createGeofence(
      name: name,
      center: center,
      radius: radius.toDouble(),
      eventType: eventType,
      data: data,
    );

    return createResponse(
      originalEventId: event.id,
      responseType: 'geofence_created',
      data: {'geofenceId': geofenceId, 'name': name},
    );
  }

  /// Handle remove geofence events
  Future<AgentEventResponse?> _handleRemoveGeofence(AgentEvent event) async {
    final geofenceId = event.data['geofenceId'];
    
    if (geofenceId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'remove_geofence_failed',
        data: {'error': 'No geofence ID provided'},
        success: false,
      );
    }

    final success = removeGeofence(geofenceId);
    
    return createResponse(
      originalEventId: event.id,
      responseType: success ? 'geofence_removed' : 'remove_geofence_failed',
      data: {'geofenceId': geofenceId, 'success': success},
      success: success,
    );
  }

  /// Handle get active geofences events
  Future<AgentEventResponse?> _handleGetActiveGeofences(AgentEvent event) async {
    final activeGeofences = _geofenceRegions.values
        .where((geofence) => geofence.isActive)
        .map((geofence) => geofence.toJson())
        .toList();

    return createResponse(
      originalEventId: event.id,
      responseType: 'active_geofences',
      data: {
        'geofences': activeGeofences,
        'count': activeGeofences.length,
      },
    );
  }

  /// Handle setup quest geofences events
  Future<AgentEventResponse?> _handleSetupQuestGeofences(AgentEvent event) async {
    final questId = event.data['questId'];
    final locations = event.data['locations'] as List?;
    
    if (questId == null || locations == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'setup_quest_geofences_failed',
        data: {'error': 'Missing required parameters'},
        success: false,
      );
    }

    final geofenceIds = <String>[];
    for (int i = 0; i < locations.length; i++) {
      final locationData = locations[i];
      final center = GeoLocation.fromJson(locationData['location']);
      final radius = (locationData['radius'] ?? 50.0).toDouble();
      
      final geofenceId = createGeofence(
        name: 'Quest $questId Location ${i + 1}',
        center: center,
        radius: radius,
        eventType: 'quest_location',
        data: {
          'questId': questId,
          'locationIndex': i,
        },
      );
      geofenceIds.add(geofenceId);
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'quest_geofences_setup',
      data: {
        'questId': questId,
        'geofenceIds': geofenceIds,
        'count': geofenceIds.length,
      },
    );
  }

  /// Handle remove quest geofences events
  Future<AgentEventResponse?> _handleRemoveQuestGeofences(AgentEvent event) async {
    final questId = event.data['questId'];
    
    if (questId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'remove_quest_geofences_failed',
        data: {'error': 'No quest ID provided'},
        success: false,
      );
    }

    // Find and remove all geofences for this quest
    final removedIds = <String>[];
    _geofenceRegions.removeWhere((id, geofence) {
      if (geofence.data['questId'] == questId) {
        removedIds.add(id);
        return true;
      }
      return false;
    });

    return createResponse(
      originalEventId: event.id,
      responseType: 'quest_geofences_removed',
      data: {
        'questId': questId,
        'removedIds': removedIds,
        'count': removedIds.length,
      },
    );
  }

  /// Handle get location metrics events
  Future<AgentEventResponse?> _handleGetLocationMetrics(AgentEvent event) async {
    final userId = event.data['userId'] ?? _currentUserId;
    
    if (userId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'get_metrics_failed',
        data: {'error': 'No user ID provided'},
        success: false,
      );
    }

    final metrics = getLocationMetrics(userId);
    
    return createResponse(
      originalEventId: event.id,
      responseType: 'location_metrics',
      data: metrics,
    );
  }

  /// Handle get travel summary events
  Future<AgentEventResponse?> _handleGetTravelSummary(AgentEvent event) async {
    final userId = event.data['userId'] ?? _currentUserId;
    
    if (userId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'get_travel_summary_failed',
        data: {'error': 'No user ID provided'},
        success: false,
      );
    }

    final summary = {
      'userId': userId,
      'totalLocationUpdates': _totalLocationUpdates,
      'lastLocationUpdate': _lastLocationUpdate?.toIso8601String(),
      'trackingMode': _trackingMode.toString(),
      'discoveredPOIs': _userDiscoveredPOIs[userId]?.length ?? 0,
      'totalPOIVisits': _userPOIVisitCounts[userId]?.values.fold(0, (sum, count) => sum + count) ?? 0,
      'recentEvents': _locationEvents.take(10).toList(),
    };

    return createResponse(
      originalEventId: event.id,
      responseType: 'travel_summary',
      data: summary,
    );
  }

  /// Handle user login events
  Future<AgentEventResponse?> _handleUserLogin(AgentEvent event) async {
    final userId = event.data['userId'];
    _currentUserId = userId;

    if (userId != null) {
      // Initialize user data if needed
      _userDiscoveredPOIs.putIfAbsent(userId, () => <String>{});
      _userPOIVisitCounts.putIfAbsent(userId, () => <String, int>{});

      // Start location tracking if not already active
      if (_trackingMode != LocationTrackingMode.off && _locationSubscription == null) {
        await _startLocationTracking();
      }

      await _saveUserLocationData(userId);
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'user_login_processed',
      data: {'userId': userId},
    );
  }

  /// Handle user logout events
  Future<AgentEventResponse?> _handleUserLogout(AgentEvent event) async {
    if (_currentUserId != null) {
      await _saveUserLocationData(_currentUserId!);
      _currentUserId = null;
    }

    // Stop location tracking
    _locationSubscription?.cancel();
    _locationSubscription = null;

    return createResponse(
      originalEventId: event.id,
      responseType: 'user_logout_processed',
      data: {'loggedOut': true},
    );
  }

  /// Handle save location data events
  Future<AgentEventResponse?> _handleSaveLocationData(AgentEvent event) async {
    await _saveAllLocationData();

    return createResponse(
      originalEventId: event.id,
      responseType: 'location_data_saved',
      data: {'saved': true},
    );
  }

  /// Handle load location data events
  Future<AgentEventResponse?> _handleLoadLocationData(AgentEvent event) async {
    await _loadUserLocationData();

    return createResponse(
      originalEventId: event.id,
      responseType: 'location_data_loaded',
      data: {'loaded': true},
    );
  }

  @override
  Future<void> onDispose() async {
    // Cancel subscriptions and timers
    _locationSubscription?.cancel();
    _locationAnalysisTimer?.cancel();
    _poisRefreshTimer?.cancel();

    // Save all data
    await _saveAllLocationData();

    developer.log('Location Services Agent disposed', name: agentId);
  }
}