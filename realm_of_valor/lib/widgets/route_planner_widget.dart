import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/adventure_system.dart';
import '../services/enhanced_location_service.dart';
import '../services/audio_service.dart';
import '../services/analytics_service.dart';
import '../constants/theme.dart';
import 'route_navigation_widget.dart';

class RoutePlannerWidget extends StatefulWidget {
  final List<AdventureRoute> routes;
  final GeoLocation? currentLocation;

  const RoutePlannerWidget({
    Key? key,
    required this.routes,
    this.currentLocation,
  }) : super(key: key);

  @override
  State<RoutePlannerWidget> createState() => _RoutePlannerWidgetState();
}

class _RoutePlannerWidgetState extends State<RoutePlannerWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  GoogleMapController? _mapController;
  int _selectedRouteIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                gradient: LinearGradient(
                  colors: [Colors.blue[600]!, Colors.purple[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.route,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Adventure Route Planner',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Tab bar
            Container(
              color: Colors.grey[800],
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.list),
                    text: 'Routes',
                  ),
                  Tab(
                    icon: Icon(Icons.map),
                    text: 'Map View',
                  ),
                ],
                indicatorColor: Colors.blue,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
              ),
            ),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRoutesList(),
                  _buildMapView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutesList() {
    if (widget.routes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.route,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No routes available',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Routes will appear based on your location',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.routes.length,
      itemBuilder: (context, index) {
        final route = widget.routes[index];
        return _buildRouteCard(route, index);
      },
    );
  }

  Widget _buildRouteCard(AdventureRoute route, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _selectedRouteIndex == index
              ? Colors.blue
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedRouteIndex = index;
          });
          _tabController.animateTo(1); // Switch to map view
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(route.difficulty),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getRouteIcon(route),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getDifficultyColor(route.difficulty).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getDifficultyColor(route.difficulty),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                route.difficulty,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(route.totalDistance / 1000).toStringAsFixed(1)} km',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                route.description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 16),

              // Stats
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildStatItem(
                      Icons.schedule,
                      '${route.estimatedDuration} min',
                      'Duration',
                    ),
                    const SizedBox(width: 20),
                    _buildStatItem(
                      Icons.place,
                      '${route.waypoints.length}',
                      'Waypoints',
                    ),
                    const SizedBox(width: 20),
                    if (route.metadata['elevation_gain'] != null)
                      _buildStatItem(
                        Icons.terrain,
                        '${route.metadata['elevation_gain']}m',
                        'Elevation',
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Highlights
              if (route.highlights.isNotEmpty) ...[
                const Text(
                  'Highlights:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: route.highlights.map((highlight) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        highlight,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedRouteIndex = index;
                        });
                        _tabController.animateTo(1);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('View on Map'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _startRoute(route);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Start Route'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildMapView() {
    if (widget.routes.isEmpty) {
      return const Center(
        child: Text(
          'No routes to display',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final selectedRoute = widget.routes[_selectedRouteIndex];
    final markers = <Marker>{};
    final polylines = <Polyline>{};

    // Add waypoint markers
    for (int i = 0; i < selectedRoute.waypoints.length; i++) {
      final waypoint = selectedRoute.waypoints[i];
      markers.add(
        Marker(
          markerId: MarkerId('waypoint_$i'),
          position: LatLng(waypoint.latitude, waypoint.longitude),
          icon: i == 0
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
              : i == selectedRoute.waypoints.length - 1
                  ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
                  : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: i == 0
                ? 'Start'
                : i == selectedRoute.waypoints.length - 1
                    ? 'Finish'
                    : 'Waypoint ${i + 1}',
          ),
        ),
      );
    }

    // Add route polyline
    if (selectedRoute.waypoints.length > 1) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: selectedRoute.waypoints
              .map((wp) => LatLng(wp.latitude, wp.longitude))
              .toList(),
          color: Colors.blue,
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      );
    }

    return Column(
      children: [
        // Route selector
        if (widget.routes.length > 1)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[800],
            child: Row(
              children: [
                const Text(
                  'Route:',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<int>(
                    value: _selectedRouteIndex,
                    dropdownColor: Colors.grey[700],
                    style: const TextStyle(color: Colors.white),
                    items: widget.routes.asMap().entries.map((entry) {
                      return DropdownMenuItem<int>(
                        value: entry.key,
                        child: Text(
                          entry.value.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedRouteIndex = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

        // Map
        Expanded(
          child: GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: selectedRoute.waypoints.isNotEmpty
                  ? LatLng(
                      selectedRoute.waypoints.first.latitude,
                      selectedRoute.waypoints.first.longitude,
                    )
                  : const LatLng(51.5074, -0.1278),
              zoom: 14.0,
            ),
            markers: markers,
            polylines: polylines,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
        ),

        // Route info bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[800],
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedRoute.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(selectedRoute.totalDistance / 1000).toStringAsFixed(1)} km • ${selectedRoute.estimatedDuration} min • ${selectedRoute.difficulty}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _startRoute(selectedRoute),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Start'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getRouteIcon(AdventureRoute route) {
    final type = route.metadata['route_type']?.toString().toLowerCase() ?? '';
    
    switch (type) {
      case 'walking':
        return Icons.directions_walk;
      case 'hiking':
        return Icons.hiking;
      case 'cycling':
        return Icons.directions_bike;
      case 'running':
        return Icons.directions_run;
      default:
        return Icons.explore;
    }
  }

  void _startRoute(AdventureRoute route) {
    final audioService = context.read<AudioService>();
    final analyticsService = context.read<AnalyticsService>();
    
    // Track route start
    analyticsService.trackEvent(
      EventType.locationVisited,
      'Route Started',
      properties: {
        'route_name': route.name,
        'route_distance': route.totalDistance,
        'route_duration': route.estimatedDuration,
        'route_difficulty': route.difficulty,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    
    audioService.playQuestComplete();
    Navigator.of(context).pop();
    
    // Show route navigation options
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start ${route.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Distance: ${(route.totalDistance / 1000).toStringAsFixed(1)} km'),
            Text('Duration: ${route.estimatedDuration} minutes'),
            Text('Difficulty: ${route.difficulty}'),
            const SizedBox(height: 16),
            const Text('Choose navigation method:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _launchExternalNavigation(route);
            },
            child: const Text('External App'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startInAppNavigation(route);
            },
            child: const Text('In-App'),
          ),
        ],
      ),
    );
  }

  void _launchExternalNavigation(AdventureRoute route) {
    final audioService = context.read<AudioService>();
    final analyticsService = context.read<AnalyticsService>();
    
    // Track external navigation
    analyticsService.trackEvent(
      EventType.locationVisited,
      'External Navigation Launched',
      properties: {
        'route_name': route.name,
        'navigation_type': 'external_app',
      },
    );
    
    audioService.playButtonClick();
    
    // Simulate launching external navigation app
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Launching navigation app for ${route.name}'),
        backgroundColor: Colors.blue,
        action: SnackBarAction(
          label: 'Open',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Launch actual navigation app
            print('Launching external navigation for ${route.name}');
          },
        ),
      ),
    );
  }

  void _startInAppNavigation(AdventureRoute route) {
    final audioService = context.read<AudioService>();
    final analyticsService = context.read<AnalyticsService>();
    
    // Track in-app navigation
    analyticsService.trackEvent(
      EventType.locationVisited,
      'In-App Navigation Started',
      properties: {
        'route_name': route.name,
        'navigation_type': 'in_app',
      },
    );
    
    audioService.playQuestComplete();
    
    // Navigate to in-app navigation screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RouteNavigationWidget(
          destinationName: route.name,
          destinationLatitude: route.waypoints.first.latitude,
          destinationLongitude: route.waypoints.first.longitude,
          currentLatitude: 37.7749, // Default to San Francisco
          currentLongitude: -122.4194,
          onRouteComplete: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Completed route: ${route.name}!'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }
}