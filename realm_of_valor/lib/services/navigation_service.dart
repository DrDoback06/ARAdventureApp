import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/weather_model.dart';
import '../services/location_service.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  List<NavigationRoute> _optimizedRoutes = [];
  NavigationRoute? _currentRoute;
  final Random _random = Random();

  // Enhanced Features
  bool _routeOptimization = true;
  bool _turnByTurnDirections = true;
  bool _offlineMode = false;
  bool _trafficAware = true;
  bool _batteryOptimized = true;

  // Getters
  List<NavigationRoute> get optimizedRoutes => _optimizedRoutes;
  NavigationRoute? get currentRoute => _currentRoute;

  // Calculate route between two points
  Future<NavigationRoute> calculateRoute(
    UserLocation start,
    LatLng destination,
    RouteType routeType,
  ) async {
    try {
      // In a real app, this would call Google Directions API
      // For now, create a mock route
      final route = _createMockRoute(start, destination, routeType);
      _currentRoute = route;
      return route;
    } catch (e) {
      // Return a simple direct route if API fails
      return _createDirectRoute(start, destination, routeType);
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

  DirectionStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.maneuver,
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