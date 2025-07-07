import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/adventure_system.dart';
import '../services/enhanced_location_service.dart';
import '../services/weather_service.dart';
import '../services/strava_service.dart';
import '../services/physical_activity_service.dart';
import '../widgets/weather_widget.dart';
import '../widgets/quest_overlay_widget.dart';
import '../widgets/encounter_dialog.dart';
import '../widgets/route_planner_widget.dart';

class AdventureMapScreen extends StatefulWidget {
  const AdventureMapScreen({Key? key}) : super(key: key);

  @override
  State<AdventureMapScreen> createState() => _AdventureMapScreenState();
}

class _AdventureMapScreenState extends State<AdventureMapScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  final EnhancedLocationService _locationService = EnhancedLocationService();
  final WeatherService _weatherService = WeatherService();
  final StravaService _stravaService = StravaService();
  final PhysicalActivityService _activityService = PhysicalActivityService();

  GeoLocation? _currentLocation;
  WeatherData? _currentWeather;
  List<POI> _nearbyPOIs = [];
  List<Quest> _activeQuests = [];
  List<WorldSpawn> _activeSpawns = [];
  List<AdventureRoute> _suggestedRoutes = [];

  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  Set<Polyline> _polylines = {};

  StreamSubscription<GeoLocation>? _locationSubscription;
  StreamSubscription<LocationEvent>? _eventSubscription;

  bool _isLoading = true;
  bool _showWeather = true;
  bool _showQuests = true;
  bool _showRoutes = false;
  bool _adventureModeActive = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAdventureMode();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _eventSubscription?.cancel();
    _pulseController.dispose();
    _locationService.dispose();
    super.dispose();
  }

  Future<void> _initializeAdventureMode() async {
    try {
      // Initialize location service
      final locationInitialized = await _locationService.initialize();
      if (!locationInitialized) {
        _showError('Location permissions required for Adventure Mode');
        return;
      }

      // Initialize services
      await _stravaService.initialize();
      await _activityService.initializeHealthTracking('player_1');

      // Start location tracking
      await _locationService.startTracking(enableBackground: true);

      // Listen to location updates
      _locationSubscription = _locationService.locationStream?.listen(_onLocationUpdate);
      _eventSubscription = _locationService.eventStream?.listen(_onLocationEvent);

      setState(() {
        _adventureModeActive = true;
        _isLoading = false;
      });

      // Get initial location and data
      await _loadInitialData();
    } catch (e) {
      print('Error initializing adventure mode: $e');
      setState(() {
        _isLoading = false;
      });
      _showError('Failed to initialize Adventure Mode');
    }
  }

  Future<void> _loadInitialData() async {
    if (_currentLocation == null) return;

    try {
      // Load weather data
      _currentWeather = await _weatherService.getWeatherForLocation(_currentLocation!);

      // Load nearby POIs
      _nearbyPOIs = await _locationService.getNearbyPOIs(_currentLocation!);

      // Generate quests
      await _generateAdventureQuests();

      // Generate routes
      _suggestedRoutes = await _locationService.generateAdventureRoutes(_currentLocation!);

      // Update map markers
      await _updateMapMarkers();

      setState(() {});
    } catch (e) {
      print('Error loading initial data: $e');
    }
  }

  void _onLocationUpdate(GeoLocation location) {
    setState(() {
      _currentLocation = location;
    });

    // Update camera position
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(location.latitude, location.longitude),
        ),
      );
    }

    // Check for nearby content updates
    _checkForNearbyUpdates();
  }

  void _onLocationEvent(LocationEvent event) {
    switch (event.type) {
      case 'poi_entered':
        _handlePOIEncounter(event);
        break;
      case 'quest_area_entered':
        _handleQuestAreaEntered(event);
        break;
      case 'random_encounter':
        _handleRandomEncounter(event);
        break;
    }
  }

  Future<void> _generateAdventureQuests() async {
    if (_currentLocation == null) return;

    final quests = <Quest>[];

    // Add epic quests from the adventure system
    quests.addAll(AdventureSystem.epicQuests);

    // Add daily quests
    quests.addAll(AdventureSystem.dailyQuests);

    // Add weather-based quests
    if (_currentWeather != null) {
      final weatherQuests = _generateWeatherBasedQuests(_currentWeather!);
      quests.addAll(weatherQuests);
    }

    // Add Strava-based quests if authenticated
    if (_stravaService.isAuthenticated) {
      final segments = await _stravaService.exploreSegments(_currentLocation!);
      final stravaQuests = _stravaService.createQuestsFromSegments(segments);
      quests.addAll(stravaQuests);
    }

    // Filter quests by proximity and level
    _activeQuests = quests.where((quest) {
      if (quest.location == null) return true;
      final distance = _currentLocation!.distanceTo(quest.location!);
      return distance <= (quest.radius ?? 5000);
    }).take(10).toList();

    // Create geofences for quest areas
    await _locationService.createGeofencesForQuests(_activeQuests);
  }

  List<Quest> _generateWeatherBasedQuests(WeatherData weather) {
    final quests = <Quest>[];

    if (weather.condition.toLowerCase().contains('rain')) {
      quests.add(Quest(
        title: 'Storm Chaser',
        description: 'Embrace the storm! Complete activities during rainy weather.',
        type: QuestType.seasonal,
        level: 3,
        xpReward: 200,
        cardRewards: ['storm_cloak', 'water_elemental'],
        objectives: [
          QuestObjective(
            title: 'Walk in the Rain',
            description: 'Take 2000 steps while it\'s raining',
            type: 'steps_weather',
            requirements: {'steps': 2000, 'weather': 'rain'},
            xpReward: 100,
          ),
        ],
        metadata: {'weather_dependent': true},
      ));
    }

    if (weather.temperature > 25) {
      quests.add(Quest(
        title: 'Solar Warrior',
        description: 'Harness the power of the sun in this hot weather challenge!',
        type: QuestType.fitness,
        level: 4,
        xpReward: 250,
        cardRewards: ['solar_armor', 'sun_crystal'],
        objectives: [
          QuestObjective(
            title: 'Heat Endurance',
            description: 'Stay active for 30 minutes in hot weather',
            type: 'active_time_weather',
            requirements: {'active_minutes': 30, 'min_temperature': 25},
            xpReward: 150,
          ),
        ],
      ));
    }

    return quests;
  }

  Future<void> _updateMapMarkers() async {
    final markers = <Marker>{};
    final circles = <Circle>{};

    // Player location marker
    if (_currentLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('player'),
        position: LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'You are here!'),
      ));
    }

    // POI markers
    for (final poi in _nearbyPOIs) {
      markers.add(Marker(
        markerId: MarkerId('poi_${poi.id}'),
        position: LatLng(poi.location.latitude, poi.location.longitude),
        icon: _getMarkerIconForPOI(poi.type),
        infoWindow: InfoWindow(
          title: poi.name,
          snippet: poi.description,
        ),
        onTap: () => _showPOIDetails(poi),
      ));

      circles.add(Circle(
        circleId: CircleId('poi_circle_${poi.id}'),
        center: LatLng(poi.location.latitude, poi.location.longitude),
        radius: poi.radius,
        fillColor: Colors.blue.withOpacity(0.1),
        strokeColor: Colors.blue,
        strokeWidth: 1,
      ));
    }

    // Quest markers
    for (final quest in _activeQuests) {
      if (quest.location != null) {
        markers.add(Marker(
          markerId: MarkerId('quest_${quest.id}'),
          position: LatLng(quest.location!.latitude, quest.location!.longitude),
          icon: _getMarkerIconForQuest(quest.type),
          infoWindow: InfoWindow(
            title: quest.title,
            snippet: quest.description,
          ),
          onTap: () => _showQuestDetails(quest),
        ));

        circles.add(Circle(
          circleId: CircleId('quest_circle_${quest.id}'),
          center: LatLng(quest.location!.latitude, quest.location!.longitude),
          radius: quest.radius ?? 100,
          fillColor: _getQuestColor(quest.type).withOpacity(0.2),
          strokeColor: _getQuestColor(quest.type),
          strokeWidth: 2,
        ));
      }
    }

    // Spawn markers
    for (final spawn in _activeSpawns) {
      markers.add(Marker(
        markerId: MarkerId('spawn_${spawn.id}'),
        position: LatLng(spawn.location.latitude, spawn.location.longitude),
        icon: _getMarkerIconForSpawn(spawn.type),
        infoWindow: InfoWindow(
          title: spawn.name,
          snippet: spawn.description,
        ),
        onTap: () => _handleSpawnEncounter(spawn),
      ));
    }

    setState(() {
      _markers = markers;
      _circles = circles;
    });
  }

  BitmapDescriptor _getMarkerIconForPOI(LocationType type) {
    switch (type) {
      case LocationType.park:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case LocationType.gym:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case LocationType.restaurant:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case LocationType.monument:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  BitmapDescriptor _getMarkerIconForQuest(QuestType type) {
    switch (type) {
      case QuestType.treasure:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      case QuestType.battle:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case QuestType.exploration:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case QuestType.fitness:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      default:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
    }
  }

  BitmapDescriptor _getMarkerIconForSpawn(SpawnType type) {
    switch (type) {
      case SpawnType.legendary:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      case SpawnType.boss:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case SpawnType.treasure:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      default:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }
  }

  Color _getQuestColor(QuestType type) {
    switch (type) {
      case QuestType.treasure:
        return Colors.amber;
      case QuestType.battle:
        return Colors.red;
      case QuestType.exploration:
        return Colors.blue;
      case QuestType.fitness:
        return Colors.green;
      default:
        return Colors.purple;
    }
  }

  void _checkForNearbyUpdates() {
    // Generate random encounters based on location and weather
    if (_currentWeather != null && math.Random().nextDouble() < 0.01) {
      _generateRandomEncounter();
    }
  }

  void _generateRandomEncounter() {
    if (_currentLocation == null) return;

    final random = math.Random();
    final encounterTypes = ['battle', 'treasure', 'merchant', 'mystery'];
    final encounterType = encounterTypes[random.nextInt(encounterTypes.length)];

    final event = LocationEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'random_encounter',
      location: _currentLocation!,
      timestamp: DateTime.now(),
      data: {
        'encounter_type': encounterType,
        'level': random.nextInt(5) + 1,
        'weather_influenced': _currentWeather != null,
      },
    );

    _onLocationEvent(event);
  }

  void _handlePOIEncounter(LocationEvent event) {
    final poiId = event.data['poi_id'];
    final poi = _nearbyPOIs.firstWhere((p) => p.id == poiId);
    
    showDialog(
      context: context,
      builder: (context) => EncounterDialog(
        title: 'Discovered: ${poi.name}',
        description: 'You\'ve discovered a new location! ${poi.description}',
        rewards: ['50 XP', 'Explorer Badge'],
        onClaim: () {
          // Award exploration rewards
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _handleQuestAreaEntered(LocationEvent event) {
    final questId = event.data['quest_id'];
    final quest = _activeQuests.firstWhere((q) => q.id == questId);
    
    showDialog(
      context: context,
      builder: (context) => QuestOverlayWidget(
        quest: quest,
        onAccept: () {
          // Start quest
          Navigator.of(context).pop();
        },
        onDecline: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _handleRandomEncounter(LocationEvent event) {
    final encounterType = event.data['encounter_type'];
    final level = event.data['level'];

    String title;
    String description;
    List<String> rewards;

    switch (encounterType) {
      case 'battle':
        title = 'Wild Creature Spotted!';
        description = 'A level $level creature appears before you. Prepare for battle!';
        rewards = ['Battle XP', 'Combat Cards', 'Gold'];
        break;
      case 'treasure':
        title = 'Hidden Treasure Found!';
        description = 'You\'ve stumbled upon a hidden treasure chest!';
        rewards = ['Rare Cards', 'Gold Coins', 'Gems'];
        break;
      case 'merchant':
        title = 'Traveling Merchant';
        description = 'A mysterious merchant offers rare goods for trade.';
        rewards = ['Trading Opportunities', 'Rare Items'];
        break;
      default:
        title = 'Mysterious Event';
        description = 'Something strange is happening here...';
        rewards = ['Mystery Reward'];
    }

    showDialog(
      context: context,
      builder: (context) => EncounterDialog(
        title: title,
        description: description,
        rewards: rewards,
        onClaim: () {
          // Handle encounter rewards
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _handleSpawnEncounter(WorldSpawn spawn) {
    showDialog(
      context: context,
      builder: (context) => EncounterDialog(
        title: spawn.name,
        description: spawn.description,
        rewards: spawn.availableCards,
        onClaim: () {
          // Handle spawn interaction
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showPOIDetails(POI poi) {
    showBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              poi.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(poi.description),
            const SizedBox(height: 16),
            Text('Type: ${poi.type.toString().split('.').last}'),
            Text('Popularity: ${(poi.popularity * 100).toStringAsFixed(1)}%'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to POI or start POI-specific quest
              },
              child: const Text('Explore This Location'),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuestDetails(Quest quest) {
    showDialog(
      context: context,
      builder: (context) => QuestOverlayWidget(
        quest: quest,
        onAccept: () {
          Navigator.of(context).pop();
          // Start quest
        },
        onDecline: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
                if (_currentLocation != null) {
                  controller.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
                      15.0,
                    ),
                  );
                }
              },
              initialCameraPosition: CameraPosition(
                target: _currentLocation != null
                    ? LatLng(_currentLocation!.latitude, _currentLocation!.longitude)
                    : const LatLng(51.5074, -0.1278), // London default
                zoom: 15.0,
              ),
              markers: _markers,
              circles: _circles,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),

          // Weather overlay
          if (_showWeather && _currentWeather != null)
            Positioned(
              top: 50,
              left: 16,
              right: 16,
              child: WeatherWidget(weather: _currentWeather!),
            ),

          // Adventure mode controls
          Positioned(
            top: 50,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'weather',
                  mini: true,
                  onPressed: () => setState(() => _showWeather = !_showWeather),
                  backgroundColor: _showWeather ? Colors.blue : Colors.grey,
                  child: const Icon(Icons.wb_sunny),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'quests',
                  mini: true,
                  onPressed: () => setState(() => _showQuests = !_showQuests),
                  backgroundColor: _showQuests ? Colors.purple : Colors.grey,
                  child: const Icon(Icons.assignment),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'routes',
                  mini: true,
                  onPressed: () => setState(() => _showRoutes = !_showRoutes),
                  backgroundColor: _showRoutes ? Colors.green : Colors.grey,
                  child: const Icon(Icons.route),
                ),
              ],
            ),
          ),

          // Adventure mode status
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _adventureModeActive
                                ? Colors.green.withOpacity(_pulseAnimation.value)
                                : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _adventureModeActive 
                                ? 'Adventure Mode Active' 
                                : 'Adventure Mode Inactive',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (_currentLocation != null)
                            Text(
                              'Quests: ${_activeQuests.length} | POIs: ${_nearbyPOIs.length}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Floating action buttons
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_showRoutes)
                  FloatingActionButton(
                    heroTag: 'route_planner',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => RoutePlannerWidget(
                          routes: _suggestedRoutes,
                          currentLocation: _currentLocation,
                        ),
                      );
                    },
                    child: const Icon(Icons.explore),
                  ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: 'my_location',
                  onPressed: () {
                    if (_currentLocation != null && _mapController != null) {
                      _mapController!.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
                          15.0,
                        ),
                      );
                    }
                  },
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}