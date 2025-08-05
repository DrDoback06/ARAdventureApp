import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/weather_model.dart';
import '../services/location_service.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  List<NavigationRoute> _optimizedRoutes = [];
  NavigationRoute? _currentRoute;
  final Random _random = Random();

  // Google Directions API key - should be moved to config
  static const String _googleApiKey = 'YOUR_GOOGLE_MAPS_API_KEY'; // Replace with actual key

  // Enhanced Features
  bool _routeOptimization = true;
  bool _turnByTurnDirections = true;
  bool _offlineMode = false;
  bool _trafficAware = true;
  bool _batteryOptimized = true;

  // Getters
  List<NavigationRoute> get optimizedRoutes => _optimizedRoutes;
  NavigationRoute? get currentRoute => _currentRoute;

  // Calculate route between two points using Google Directions API
  Future<NavigationRoute> calculateRoute(
    UserLocation start,
    LatLng destination,
    RouteType routeType, {
    List<LatLng>? waypoints,
    bool avoidTolls = false,
    bool avoidHighways = false,
  }) async {
    try {
      // Try Google Directions API first
      final route = await _getGoogleDirectionsRoute(
        start, 
        destination, 
        routeType,
        waypoints: waypoints,
        avoidTolls: avoidTolls,
        avoidHighways: avoidHighways,
      );
      
      if (route != null) {
        _currentRoute = route;
        return route;
      }
      
      // Fallback to mock route if API fails
      final mockRoute = _createMockRoute(start, destination, routeType);
      _currentRoute = mockRoute;
      return mockRoute;
    } catch (e) {
      print('Error calculating route: $e');
      // Return a simple direct route if everything fails
      return _createDirectRoute(start, destination, routeType);
    }
  }

  // Get route from Google Directions API
  Future<NavigationRoute?> _getGoogleDirectionsRoute(
    UserLocation start,
    LatLng destination,
    RouteType routeType, {
    List<LatLng>? waypoints,
    bool avoidTolls = false,
    bool avoidHighways = false,
  }) async {
    try {
      // Convert route type to Google API mode
      String mode = _routeTypeToGoogleMode(routeType);
      
      // Build URL
      String url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${start.latitude},${start.longitude}&'
          'destination=${destination.latitude},${destination.longitude}&'
          'mode=$mode&'
          'key=$_googleApiKey';
      
      // Add waypoints if provided
      if (waypoints != null && waypoints.isNotEmpty) {
        String waypointsStr = waypoints
            .map((wp) => '${wp.latitude},${wp.longitude}')
            .join('|');
        url += '&waypoints=$waypointsStr';
      }
      
      // Add route preferences
      if (avoidTolls) url += '&avoid=tolls';
      if (avoidHighways) url += '&avoid=highways';
      if (_trafficAware && mode == 'driving') url += '&departure_time=now';
      
      // Make API request
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          return _parseGoogleDirectionsResponse(data, start, destination, routeType);
        }
      }
      
      print('Google Directions API failed: ${response.statusCode}');
      return null;
    } catch (e) {
      print('Error calling Google Directions API: $e');
      return null;
    }
  }

  // Parse Google Directions API response
  NavigationRoute _parseGoogleDirectionsResponse(
    Map<String, dynamic> data,
    UserLocation start,
    LatLng destination,
    RouteType routeType,
  ) {
    final route = data['routes'][0];
    final leg = route['legs'][0];
    
    // Extract route polyline
    final polylinePoints = _decodePolyline(route['overview_polyline']['points']);
    
    // Extract distance and duration
    final distance = leg['distance']['value'].toDouble(); // in meters
    final duration = Duration(seconds: leg['duration']['value']);
    
    // Extract turn-by-turn directions
    final steps = leg['steps'] as List;
    final directions = steps.map((step) {
      return DirectionStep(
        instruction: _stripHtmlTags(step['html_instructions']),
        distance: step['distance']['value'].toDouble(),
        duration: Duration(seconds: step['duration']['value']),
        maneuver: _parseManeuverType(step['maneuver'] ?? 'straight'),
        startLocation: LatLng(
          step['start_location']['lat'],
          step['start_location']['lng'],
        ),
        endLocation: LatLng(
          step['end_location']['lat'],
          step['end_location']['lng'],
        ),
      );
    }).toList();
    
    return NavigationRoute(
      id: 'google_${DateTime.now().millisecondsSinceEpoch}',
      startLocation: start,
      endLocation: destination,
      waypoints: polylinePoints,
      distance: distance,
      duration: duration,
      routeType: routeType,
      trafficLevel: _calculateTrafficLevel(leg),
      isOptimized: true,
      hasTolls: _routeHasTolls(route),
      hasHighways: _routeHasHighways(route),
      isCurrent: true,
      directions: directions,
      polylineEncoded: route['overview_polyline']['points'],
    );
  }

  // Decode Google polyline to list of LatLng points
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  // Convert quest route type to Google API mode
  String _routeTypeToGoogleMode(RouteType routeType) {
    switch (routeType) {
      case RouteType.walking:
        return 'walking';
      case RouteType.cycling:
        return 'bicycling';
      case RouteType.driving:
        return 'driving';
      case RouteType.transit:
        return 'transit';
      default:
        return 'walking';
    }
  }

  // Strip HTML tags from Google directions
  String _stripHtmlTags(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  // Parse maneuver type from Google API
  ManeuverType _parseManeuverType(String maneuver) {
    switch (maneuver.toLowerCase()) {
      case 'turn-left':
        return ManeuverType.turnLeft;
      case 'turn-right':
        return ManeuverType.turnRight;
      case 'turn-slight-left':
        return ManeuverType.slightLeft;
      case 'turn-slight-right':
        return ManeuverType.slightRight;
      case 'uturn-left':
      case 'uturn-right':
        return ManeuverType.uTurn;
      case 'merge':
        return ManeuverType.merge;
      case 'ramp-left':
      case 'ramp-right':
        return ManeuverType.exit;
      default:
        return ManeuverType.straight;
    }
  }

  // Calculate traffic level from Google API response
  TrafficLevel _calculateTrafficLevel(Map<String, dynamic> leg) {
    if (leg.containsKey('duration_in_traffic')) {
      final normalDuration = leg['duration']['value'];
      final trafficDuration = leg['duration_in_traffic']['value'];
      final ratio = trafficDuration / normalDuration;
      
      if (ratio < 1.1) return TrafficLevel.low;
      if (ratio < 1.3) return TrafficLevel.medium;
      if (ratio < 1.5) return TrafficLevel.high;
      return TrafficLevel.severe;
    }
    return TrafficLevel.low;
  }

  // Check if route has tolls
  bool _routeHasTolls(Map<String, dynamic> route) {
    final warnings = route['warnings'] as List?;
    if (warnings != null) {
      return warnings.any((warning) => 
        warning.toString().toLowerCase().contains('toll'));
    }
    return false;
  }

  // Check if route has highways
  bool _routeHasHighways(Map<String, dynamic> route) {
    final summary = route['summary'] as String?;
    if (summary != null) {
      return summary.toLowerCase().contains('highway') ||
             summary.toLowerCase().contains('freeway') ||
             summary.toLowerCase().contains('motorway');
    }
    return false;
  }

  // Calculate optimal route for quest completion
  Future<NavigationRoute> calculateQuestRoute(
    UserLocation playerLocation,
    LatLng questLocation,
    QuestType questType, {
    List<LatLng>? questWaypoints,
  }) async {
    // Determine best route type based on quest type
    RouteType routeType = _getOptimalRouteTypeForQuest(questType);
    
    // Include quest waypoints if available
    return await calculateRoute(
      playerLocation,
      questLocation,
      routeType,
      waypoints: questWaypoints,
    );
  }

  // Get optimal route type for different quest types
  RouteType _getOptimalRouteTypeForQuest(QuestType questType) {
    switch (questType) {
      case QuestType.fitness:
      case QuestType.walking:
        return RouteType.walking;
      case QuestType.running:
        return RouteType.walking;
      case QuestType.climbing:
        return RouteType.walking;
      case QuestType.location:
      case QuestType.exploration:
      case QuestType.social:
      case QuestType.collection:
        return RouteType.walking;
      case QuestType.battle:
        return RouteType.walking;
      default:
        return RouteType.walking;
    }
  }

  // Create mock route for development
  NavigationRoute _createMockRoute(
    UserLocation start,
    LatLng destination,
    RouteType routeType,
  ) {
    final waypoints = _generateWaypoints(start, destination);
    final distance = _calculateDistance(start, destination);
    final duration = _calculateDuration(distance, routeType);
    
    return NavigationRoute(
      id: 'route_${DateTime.now().millisecondsSinceEpoch}',
      startLocation: start,
      endLocation: destination,
      waypoints: waypoints,
      distance: distance,
      duration: duration,
      routeType: routeType,
      trafficLevel: _getRandomTrafficLevel(),
      isOptimized: _routeOptimization,
      hasTolls: _random.nextBool(),
      hasHighways: _random.nextBool(),
      isCurrent: true,
    );
  }

  // Create direct route (fallback)
  NavigationRoute _createDirectRoute(
    UserLocation start,
    LatLng destination,
    RouteType routeType,
  ) {
    final distance = _calculateDistance(start, destination);
    final duration = _calculateDuration(distance, routeType);
    
    return NavigationRoute(
      id: 'direct_${DateTime.now().millisecondsSinceEpoch}',
      startLocation: start,
      endLocation: destination,
      waypoints: [start.toLatLng(), destination],
      distance: distance,
      duration: duration,
      routeType: routeType,
      trafficLevel: TrafficLevel.low,
      isOptimized: false,
      hasTolls: false,
      hasHighways: false,
      isCurrent: true,
    );
  }

  // Generate waypoints for route
  List<LatLng> _generateWaypoints(UserLocation start, LatLng destination) {
    final waypoints = <LatLng>[];
    final numWaypoints = 2 + _random.nextInt(3); // 2-4 waypoints
    
    for (int i = 0; i < numWaypoints; i++) {
      final progress = (i + 1) / (numWaypoints + 1);
      final lat = start.latitude + (destination.latitude - start.latitude) * progress;
      final lng = start.longitude + (destination.longitude - start.longitude) * progress;
      
      // Add some randomness to make it more realistic
      final latOffset = (_random.nextDouble() - 0.5) * 0.001;
      final lngOffset = (_random.nextDouble() - 0.5) * 0.001;
      
      waypoints.add(LatLng(lat + latOffset, lng + lngOffset));
    }
    
    return waypoints;
  }

  // Calculate distance between two points
  double _calculateDistance(UserLocation start, LatLng destination) {
    const double earthRadius = 6371000; // meters

    final double dLat = (destination.latitude - start.latitude) * (pi / 180);
    final double dLon = (destination.longitude - start.longitude) * (pi / 180);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(start.latitude * (pi / 180)) * cos(destination.latitude * (pi / 180)) *
        sin(dLon / 2) * sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  // Calculate duration based on distance and route type
  Duration _calculateDuration(double distance, RouteType routeType) {
    double speedKmh = 5.0; // Walking speed by default
    
    switch (routeType) {
      case RouteType.walking:
        speedKmh = 5.0;
        break;
      case RouteType.cycling:
        speedKmh = 15.0;
        break;
      case RouteType.driving:
        speedKmh = 50.0;
        break;
      case RouteType.transit:
        speedKmh = 25.0;
        break;
    }
    
    final durationHours = distance / 1000 / speedKmh;
    return Duration(minutes: (durationHours * 60).round());
  }

  // Get random traffic level
  TrafficLevel _getRandomTrafficLevel() {
    final levels = TrafficLevel.values;
    return levels[_random.nextInt(levels.length)];
  }

  // Get optimized routes for multiple destinations
  Future<List<NavigationRoute>> getOptimizedRoutes(
    UserLocation start,
    List<LatLng> destinations,
  ) async {
    final routes = <NavigationRoute>[];
    
    for (int i = 0; i < destinations.length; i++) {
      final route = await calculateRoute(
        start,
        destinations[i],
        RouteType.walking,
      );
      routes.add(route);
    }
    
    // Sort by distance if optimization is enabled
    if (_routeOptimization) {
      routes.sort((a, b) => a.distance.compareTo(b.distance));
    }
    
    _optimizedRoutes = routes;
    return routes;
  }

  // Select a route
  void selectRoute(NavigationRoute route) {
    _currentRoute = route;
    route.isCurrent = true;
  }

  // Get turn-by-turn directions
  List<DirectionStep> getTurnByTurnDirections(NavigationRoute route) {
    if (!_turnByTurnDirections) return [];

    final directions = <DirectionStep>[];
    final waypoints = route.waypoints;
    
    for (int i = 0; i < waypoints.length - 1; i++) {
      final current = waypoints[i];
      final next = waypoints[i + 1];
      
      directions.add(DirectionStep(
        instruction: _generateDirectionInstruction(i, current, next),
        distance: _calculateDistance(
          UserLocation(
            userId: 'player',
            latitude: current.latitude,
            longitude: current.longitude,
            accuracy: 0,
            timestamp: DateTime.now(),
          ),
          next,
        ),
        duration: Duration(minutes: 2 + _random.nextInt(5)),
        maneuver: _getRandomManeuver(),
        startLocation: current,
        endLocation: next,
      ));
    }
    
    return directions;
  }

  // Generate direction instruction
  String _generateDirectionInstruction(int step, LatLng current, LatLng next) {
    final instructions = [
      'Continue straight ahead',
      'Turn right',
      'Turn left',
      'Slight right',
      'Slight left',
      'U-turn',
      'Merge onto road',
      'Exit roundabout',
    ];
    
    return instructions[_random.nextInt(instructions.length)];
  }

  // Get random maneuver type
  ManeuverType _getRandomManeuver() {
    final maneuvers = ManeuverType.values;
    return maneuvers[_random.nextInt(maneuvers.length)];
  }

  // Enhanced Features

  // Toggle route optimization
  void toggleRouteOptimization() {
    _routeOptimization = !_routeOptimization;
  }

  // Toggle turn-by-turn directions
  void toggleTurnByTurnDirections() {
    _turnByTurnDirections = !_turnByTurnDirections;
  }

  // Toggle offline mode
  void toggleOfflineMode() {
    _offlineMode = !_offlineMode;
  }

  // Toggle traffic awareness
  void toggleTrafficAware() {
    _trafficAware = !_trafficAware;
  }

  // Toggle battery optimization
  void toggleBatteryOptimization() {
    _batteryOptimized = !_batteryOptimized;
  }

  // Get navigation statistics
  Map<String, dynamic> getNavigationStats() {
    return {
      'currentRoute': _currentRoute?.id,
      'optimizedRoutes': _optimizedRoutes.length,
      'routeOptimization': _routeOptimization,
      'turnByTurnDirections': _turnByTurnDirections,
      'offlineMode': _offlineMode,
      'trafficAware': _trafficAware,
      'batteryOptimized': _batteryOptimized,
    };
  }

  // Dispose
  void dispose() {
    _optimizedRoutes.clear();
    _currentRoute = null;
  }
}

// Navigation Models
class NavigationRoute {
  final String id;
  final UserLocation startLocation;
  final LatLng endLocation;
  final List<LatLng> waypoints;
  final double distance;
  final Duration duration;
  final RouteType routeType;
  final TrafficLevel trafficLevel;
  final bool isOptimized;
  final bool hasTolls;
  final bool hasHighways;
  bool isCurrent;
  final List<DirectionStep>? directions; // Added for Google Directions
  final String? polylineEncoded; // Added for Google Directions

  NavigationRoute({
    required this.id,
    required this.startLocation,
    required this.endLocation,
    required this.waypoints,
    required this.distance,
    required this.duration,
    required this.routeType,
    required this.trafficLevel,
    required this.isOptimized,
    required this.hasTolls,
    required this.hasHighways,
    this.isCurrent = false,
    this.directions, // Initialize new fields
    this.polylineEncoded,
  });
}

enum RouteType {
  walking,
  cycling,
  driving,
  transit,
}

enum TrafficLevel {
  low,
  medium,
  high,
  severe,
}

class DirectionStep {
  final String instruction;
  final double distance;
  final Duration duration;
  final ManeuverType maneuver;
  final LatLng startLocation; // Added for Google Directions
  final LatLng endLocation; // Added for Google Directions

  DirectionStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.maneuver,
    required this.startLocation,
    required this.endLocation,
  });
}

enum ManeuverType {
  straight,
  turnRight,
  turnLeft,
  slightRight,
  slightLeft,
  uTurn,
  merge,
  exit,
} 