import 'dart:async';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:background_location/background_location.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/adventure_system.dart';
import 'dart:convert';

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

  StreamController<GeoLocation>? _locationController;
  StreamController<LocationEvent>? _eventController;
  
  Timer? _locationTimer;
  GeoLocation? _lastKnownLocation;
  List<GeofenceRegion> _geofences = [];
  List<LocationEvent> _locationHistory = [];
  
  bool _isTracking = false;
  bool _backgroundTrackingEnabled = false;

  Stream<GeoLocation>? get locationStream => _locationController?.stream;
  Stream<LocationEvent>? get eventStream => _eventController?.stream;
  
  GeoLocation? get lastKnownLocation => _lastKnownLocation;
  bool get isTracking => _isTracking;

  // Initialize location service
  Future<bool> initialize() async {
    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      // Initialize streams
      _locationController = StreamController<GeoLocation>.broadcast();
      _eventController = StreamController<LocationEvent>.broadcast();

      // Load saved data
      await _loadGeofences();
      await _loadLocationHistory();

      return true;
    } catch (e) {
      print('Error initializing location service: $e');
      return false;
    }
  }

  // Start location tracking
  Future<void> startTracking({bool enableBackground = false}) async {
    if (_isTracking) return;

    try {
      _isTracking = true;
      _backgroundTrackingEnabled = enableBackground;

      if (enableBackground) {
        await _startBackgroundTracking();
      } else {
        await _startForegroundTracking();
      }
    } catch (e) {
      print('Error starting location tracking: $e');
      _isTracking = false;
    }
  }

  // Stop location tracking
  Future<void> stopTracking() async {
    _isTracking = false;
    _locationTimer?.cancel();
    
    if (_backgroundTrackingEnabled) {
      await BackgroundLocation.stopLocationService();
    }
  }

  // Start foreground tracking
  Future<void> _startForegroundTracking() async {
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        
        final location = GeoLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          altitude: position.altitude,
          accuracy: position.accuracy,
        );

        await _updateLocation(location);
      } catch (e) {
        print('Error getting location: $e');
      }
    });
  }

  // Start background tracking
  Future<void> _startBackgroundTracking() async {
    await BackgroundLocation.setAndroidNotification(
      title: 'Realm of Valor Adventure Mode',
      message: 'Tracking your location for epic adventures!',
      icon: '@mipmap/ic_launcher',
    );

    await BackgroundLocation.setAndroidConfiguration(1000);
    await BackgroundLocation.startLocationService(distanceFilter: 20);

    BackgroundLocation.getLocationUpdates((location) {
      final geoLocation = GeoLocation(
        latitude: location.latitude ?? 0.0,
        longitude: location.longitude ?? 0.0,
        altitude: location.altitude,
        accuracy: location.accuracy,
      );
      
      _updateLocation(geoLocation);
    });
  }

  // Update location and trigger events
  Future<void> _updateLocation(GeoLocation location) async {
    _lastKnownLocation = location;
    _locationController?.add(location);

    // Add to history
    _locationHistory.add(LocationEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'location_update',
      location: location,
      timestamp: DateTime.now(),
      data: {},
    ));

    // Limit history size
    if (_locationHistory.length > 1000) {
      _locationHistory = _locationHistory.sublist(_locationHistory.length - 1000);
    }

    // Check geofences
    await _checkGeofences(location);

    // Save location history periodically
    if (_locationHistory.length % 10 == 0) {
      await _saveLocationHistory();
    }
  }

  // Check geofences for triggers
  Future<void> _checkGeofences(GeoLocation location) async {
    for (final geofence in _geofences) {
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

        _eventController?.add(event);
      }
    }
  }

  // Add geofence region
  Future<void> addGeofence(GeofenceRegion geofence) async {
    _geofences.add(geofence);
    await _saveGeofences();
  }

  // Remove geofence
  Future<void> removeGeofence(String geofenceId) async {
    _geofences.removeWhere((g) => g.id == geofenceId);
    await _saveGeofences();
  }

  // Create geofences for POIs
  Future<void> createGeofencesForPOIs(List<POI> pois) async {
    for (final poi in pois) {
      final geofence = GeofenceRegion(
        id: 'poi_${poi.id}',
        name: poi.name,
        center: poi.location,
        radius: poi.radius,
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
  Future<List<POI>> getNearbyPOIs(GeoLocation location, {double radius = 1000}) async {
    // This would typically query a backend service
    // For now, returning sample POIs
    return _generateSamplePOIs(location, radius);
  }

  // Generate sample POIs for demonstration
  List<POI> _generateSamplePOIs(GeoLocation center, double radius) {
    final pois = <POI>[];
    final random = math.Random();

    final poiTypes = [
      LocationType.park,
      LocationType.gym,
      LocationType.restaurant,
      LocationType.monument,
      LocationType.library,
    ];

    for (int i = 0; i < 10; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final distance = random.nextDouble() * radius;
      
      final lat = center.latitude + (distance * math.cos(angle)) / 111000;
      final lng = center.longitude + (distance * math.sin(angle)) / (111000 * math.cos(center.latitude * math.pi / 180));

      final poi = POI(
        name: 'Adventure Point ${i + 1}',
        description: 'A mysterious location waiting to be explored',
        type: poiTypes[random.nextInt(poiTypes.length)],
        location: GeoLocation(latitude: lat, longitude: lng),
        radius: 50 + random.nextDouble() * 100,
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
      final geofenceJson = jsonEncode(_geofences.map((g) => g.toJson()).toList());
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
        _geofences = geofenceList
            .map((json) => GeofenceRegion.fromJson(json))
            .toList();
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

  // Cleanup
  void dispose() {
    stopTracking();
    _locationController?.close();
    _eventController?.close();
  }
}