import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../constants/theme.dart';
import '../models/adventure_map_model.dart';
import '../models/quest_model.dart';
import '../services/adventure_map_service.dart';
import '../services/audio_service.dart';
import '../services/loot_system_service.dart';
import '../widgets/quest_card_widget.dart';
import '../widgets/location_card_widget.dart';
import '../widgets/weather_widget.dart';
import '../widgets/leaderboard_widget.dart';
import '../widgets/web_map_widget.dart';
import '../widgets/quest_details_widget.dart';
import '../widgets/collapsible_weather_widget.dart';
import '../widgets/loot_cache_widget.dart';

class EnhancedAdventureMapScreen extends StatefulWidget {
  const EnhancedAdventureMapScreen({super.key});

  @override
  State<EnhancedAdventureMapScreen> createState() => _EnhancedAdventureMapScreenState();
}

class _EnhancedAdventureMapScreenState extends State<EnhancedAdventureMapScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  Set<Polyline> _polylines = {};
  
  // Map state
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(51.5074, -0.1278), // London default
    zoom: 12.0,
  );
  
  // UI state
  bool _isMapView = true;
  bool _isLoading = true;
  String _selectedFilter = 'all';
  double _searchRadius = 5.0; // km
  
  // Data
  List<MapLocation> _nearbyLocations = [];
  List<AdventureQuest> _nearbyQuests = [];
  List<AdventureQuest> _featuredQuests = [];
  WeatherData? _currentWeather;
  Map<String, dynamic> _weatherEffects = {};
  List<LootCache> _nearbyLootCaches = [];
  
  // UI State
  AdventureQuest? _selectedQuest;
  bool _isQuestDetailsVisible = false;
  Set<Polyline> _pathPolylines = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeMap();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    setState(() => _isLoading = true);
    
    try {
      final mapService = context.read<AdventureMapService>();
      await mapService.initialize();
      
      // Get user location
      final userLocation = mapService.currentUserLocation;
      if (userLocation != null) {
        _initialCameraPosition = CameraPosition(
          target: LatLng(userLocation.latitude, userLocation.longitude),
          zoom: 14.0,
        );
      }
      
      // Load data
      await _loadMapData();
      
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error initializing map: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMapData() async {
    final mapService = context.read<AdventureMapService>();
    
    // Load nearby locations and quests
    _nearbyLocations = mapService.getLocationsInRadius(_searchRadius);
    _nearbyQuests = mapService.getNearbyQuests(_searchRadius);
    _featuredQuests = mapService.getFeaturedQuests();
    
    // Load nearby loot caches
    _nearbyLootCaches = mapService.getNearbyLootCaches(_searchRadius * 1000);
    
    // Debug output
    debugPrint('Loaded ${_nearbyLocations.length} nearby locations');
    debugPrint('Loaded ${_nearbyQuests.length} nearby quests');
    debugPrint('Loaded ${_featuredQuests.length} featured quests');
    debugPrint('Strava trails loaded: ${mapService.trailPolylines.length}');
    debugPrint('Loot caches loaded: ${_nearbyLootCaches.length}');
    
    // Load weather data
    final weatherData = mapService.weatherData;
    _currentWeather = weatherData['current'];
    _weatherEffects = mapService.getWeatherEffects();
    
    // Create markers
    _createMarkers();
    
    setState(() {});
  }

  void _createMarkers() {
    _markers.clear();
    final mapService = context.read<AdventureMapService>();
    
    // User location marker
    final userLocation = mapService.currentUserLocation;
    if (userLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(userLocation.latitude, userLocation.longitude),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'You are here',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
    
    // Location markers
    for (final location in _nearbyLocations) {
      _markers.add(
        Marker(
          markerId: MarkerId('location_${location.id}'),
          position: LatLng(location.latitude, location.longitude),
          infoWindow: InfoWindow(
            title: location.name,
            snippet: location.type == LocationType.trail 
                ? 'Strava Trail - Tap for details' 
                : location.description,
          ),
          icon: _getLocationIcon(location.type),
          onTap: () => _showLocationDetails(location),
        ),
      );
    }
    
    // Quest markers
    for (final quest in _nearbyQuests) {
      _markers.add(
        Marker(
          markerId: MarkerId('quest_${quest.id}'),
          position: LatLng(quest.mapLocation.latitude, quest.mapLocation.longitude),
          infoWindow: InfoWindow(
            title: quest.name,
            snippet: 'Quest Available',
          ),
          icon: _getQuestIcon(quest),
          onTap: () => _showQuestDetails(quest),
        ),
      );
    }
    
    // Loot cache markers
    for (final cache in _nearbyLootCaches) {
      _markers.add(
        Marker(
          markerId: MarkerId('loot_${cache.id}'),
          position: cache.position,
          infoWindow: InfoWindow(
            title: cache.name,
            snippet: '${cache.rarityName} Loot Cache',
          ),
          icon: _getLootCacheIcon(cache),
          onTap: () => _showLootCacheDetails(cache),
        ),
      );
    }
  }

  BitmapDescriptor _getLocationIcon(LocationType type) {
    switch (type) {
      case LocationType.trail:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case LocationType.pub:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case LocationType.restaurant:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case LocationType.park:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case LocationType.gym:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      case LocationType.landmark:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      default:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
    }
  }

  BitmapDescriptor _getQuestIcon(AdventureQuest quest) {
    // Create more appealing quest markers based on type and difficulty
    switch (quest.type) {
      case QuestType.exploration:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      case QuestType.battle:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case QuestType.collection:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case QuestType.social:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case QuestType.fitness:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      case QuestType.walking:
      case QuestType.running:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case QuestType.climbing:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      case QuestType.location:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta);
      default:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }
  }

  BitmapDescriptor _getLootCacheIcon(LootCache cache) {
    switch (cache.rarity) {
      case LootRarity.common:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case LootRarity.uncommon:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case LootRarity.rare:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      case LootRarity.epic:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta);
      case LootRarity.legendary:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
    }
  }

  void _showLootCacheDetails(LootCache cache) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LootDetailsSheet(cache: cache),
    );
  }

  void _showLocationDetails(MapLocation location) {
    // Check if there are any quests associated with this location
    final associatedQuests = _findQuestsForLocation(location);
    
    debugPrint('Location clicked: ${location.name}');
    debugPrint('Found ${associatedQuests.length} associated quests');
    
    if (associatedQuests.isNotEmpty) {
      // Show quest details for the first quest (or let user choose)
      debugPrint('Showing quest details for: ${associatedQuests.first.name}');
      _showQuestDetails(associatedQuests.first);
    } else {
      // Show basic location details
      debugPrint('No quests found, showing location details');
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => LocationDetailsSheet(location: location),
      );
    }
  }

  List<AdventureQuest> _findQuestsForLocation(MapLocation location) {
    final mapService = context.read<AdventureMapService>();
    final allQuests = [..._nearbyQuests, ..._featuredQuests];
    
    debugPrint('Searching through ${allQuests.length} total quests');
    
    return allQuests.where((quest) {
      // Check if quest location matches the clicked location
      // Use a more flexible matching approach
      final locationDistance = _calculateDistance(
        location.latitude, 
        location.longitude,
        quest.mapLocation.latitude, 
        quest.mapLocation.longitude,
      );
      
      debugPrint('Quest ${quest.name}: distance = ${locationDistance.toStringAsFixed(1)}m');
      
      // Consider quests within 500 meters of the location (increased from 100m)
      return locationDistance <= 500.0;
    }).toList();
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Simple distance calculation using Haversine formula
    const double earthRadius = 6371000; // meters
    
    final double dLat = (lat2 - lat1) * (pi / 180);
    final double dLon = (lon2 - lon1) * (pi / 180);
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }


  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onCameraMove(CameraPosition position) {
    // Update search radius based on zoom level - increased for more quests
    final zoom = position.zoom;
    if (zoom < 10) {
      _searchRadius = 50.0; // Increased from 20.0
    } else if (zoom < 12) {
      _searchRadius = 25.0; // Increased from 10.0
    } else if (zoom < 14) {
      _searchRadius = 15.0; // Increased from 5.0
    } else {
      _searchRadius = 8.0; // Increased from 2.0
    }
  }

  void _onCameraIdle() {
    // Reload data for new area
    _loadMapData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RealmOfValorTheme.surfaceDark,
      appBar: AppBar(
        title: const Text('Adventure Map'),
        backgroundColor: RealmOfValorTheme.surfaceDark,
        foregroundColor: RealmOfValorTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isMapView ? Icons.list : Icons.map),
            onPressed: () {
              setState(() => _isMapView = !_isMapView);
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: RealmOfValorTheme.accentGold,
          labelColor: RealmOfValorTheme.accentGold,
          unselectedLabelColor: RealmOfValorTheme.textSecondary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Map'),
            Tab(text: 'Nearby'),
            Tab(text: 'Featured'),
            Tab(text: 'Events'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(RealmOfValorTheme.accentGold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading Adventure Map...',
                    style: TextStyle(
                      color: RealmOfValorTheme.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMapTab(),
                _buildNearbyTab(),
                _buildFeaturedTab(),
                _buildEventsTab(),
              ],
            ),
    );
  }

  Widget _buildMapTab() {
    final mapService = context.read<AdventureMapService>();
    final allPolylines = <Polyline>{};
    
    // Add path polylines
    allPolylines.addAll(_pathPolylines);
    
    // Add trail polylines from Strava
    allPolylines.addAll(mapService.trailPolylines);
    
    return Stack(
      children: [
        // Main map
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          margin: const EdgeInsets.all(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: WebMapWidget(
              locations: _nearbyLocations,
              userLocation: mapService.currentUserLocation,
              onLocationSelected: (LatLng position) {
                // Handle location selection
                debugPrint('Location selected: $position');
              },
              onCameraMove: _onCameraMove,
              onCameraIdle: _onCameraIdle,
              polylines: allPolylines,
            ),
          ),
        ),
        
        // Weather widget
        Positioned(
          top: 16,
          left: 16,
          child: CollapsibleWeatherWidget(
            weather: _currentWeather,
            effects: _weatherEffects,
          ),
        ),
        
        // Strava trails indicator
        Positioned(
          top: 100,
          right: 16,
          child: _buildStravaTrailsIndicator(),
        ),
        
        // Quest details overlay
        if (_isQuestDetailsVisible && _selectedQuest != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: QuestDetailsWidget(
              quest: _selectedQuest!,
              onStartQuest: (quest) {
                context.read<AdventureMapService>().startQuest(quest.id);
                _hideQuestDetails();
              },
              onStopQuest: (quest) {
                context.read<AdventureMapService>().stopQuest(quest.id);
                _hideQuestDetails();
              },
              onShowPath: (quest) {
                _showPathToQuest(quest);
                _hideQuestDetails();
              },
              isActive: context.read<AdventureMapService>().isQuestActive(_selectedQuest!.id),
            ),
          ),
        
        // Bottom action bar
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: RealmOfValorTheme.surfaceMedium.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showSearchDialog,
                    icon: const Icon(Icons.search),
                    label: const Text('Search'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RealmOfValorTheme.surfaceDark,
                      foregroundColor: RealmOfValorTheme.accentGold,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _addLocation,
                    icon: const Icon(Icons.add_location),
                    label: const Text('Add Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RealmOfValorTheme.surfaceDark,
                      foregroundColor: RealmOfValorTheme.accentGold,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showLeaderboard,
                    icon: const Icon(Icons.leaderboard),
                    label: const Text('Leaderboard'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RealmOfValorTheme.surfaceDark,
                      foregroundColor: RealmOfValorTheme.accentGold,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: RealmOfValorTheme.accentGold,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: RealmOfValorTheme.accentGold.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _createQuest,
                    icon: const Icon(Icons.add, color: Colors.white, size: 28),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.search,
          label: 'Search',
          onTap: _showSearchDialog,
        ),
        _buildActionButton(
          icon: Icons.add_location,
          label: 'Add Location',
          onTap: _addLocation,
        ),
        _buildActionButton(
          icon: Icons.emoji_events,
          label: 'Leaderboard',
          onTap: _showLeaderboard,
        ),
        _buildActionButton(
          icon: Icons.group,
          label: 'Events',
          onTap: _showEvents,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: RealmOfValorTheme.surfaceMedium.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: RealmOfValorTheme.accentGold.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: RealmOfValorTheme.accentGold,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: RealmOfValorTheme.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Nearby Quests',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: RealmOfValorTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${_nearbyQuests.length} available',
                style: TextStyle(
                  color: RealmOfValorTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _nearbyQuests.isEmpty
                ? _buildEmptyState(
                    icon: Icons.explore,
                    title: 'No Nearby Quests',
                    subtitle: 'Explore the map to find quests near you',
                  )
                : ListView.builder(
                    itemCount: _nearbyQuests.length,
                    itemBuilder: (context, index) {
                      final quest = _nearbyQuests[index];
                      return ListTile(
                        title: Text(quest.name),
                        subtitle: Text(quest.description),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${quest.experienceReward} XP'),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                if (context.read<AdventureMapService>().isQuestActive(quest.id)) {
                                  context.read<AdventureMapService>().stopQuest(quest.id);
                                } else {
                                  context.read<AdventureMapService>().startQuest(quest.id);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.read<AdventureMapService>().isQuestActive(quest.id)
                                    ? Colors.red
                                    : RealmOfValorTheme.accentGold,
                                foregroundColor: context.read<AdventureMapService>().isQuestActive(quest.id)
                                    ? Colors.white
                                    : RealmOfValorTheme.surfaceDark,
                              ),
                              child: Text(
                                context.read<AdventureMapService>().isQuestActive(quest.id)
                                    ? 'Stop'
                                    : 'Start',
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _showQuestDetails(quest),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Featured Quests',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _featuredQuests.isEmpty
                ? _buildEmptyState(
                    icon: Icons.star,
                    title: 'No Featured Quests',
                    subtitle: 'Check back later for special quests',
                  )
                : ListView.builder(
                    itemCount: _featuredQuests.length,
                    itemBuilder: (context, index) {
                      final quest = _featuredQuests[index];
                      return ListTile(
                        title: Text(quest.name),
                        subtitle: Text(quest.description),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${quest.experienceReward} XP'),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                if (context.read<AdventureMapService>().isQuestActive(quest.id)) {
                                  context.read<AdventureMapService>().stopQuest(quest.id);
                                } else {
                                  context.read<AdventureMapService>().startQuest(quest.id);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.read<AdventureMapService>().isQuestActive(quest.id)
                                    ? Colors.red
                                    : RealmOfValorTheme.accentGold,
                                foregroundColor: context.read<AdventureMapService>().isQuestActive(quest.id)
                                    ? Colors.white
                                    : RealmOfValorTheme.surfaceDark,
                              ),
                              child: Text(
                                context.read<AdventureMapService>().isQuestActive(quest.id)
                                    ? 'Stop'
                                    : 'Start',
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _showQuestDetails(quest),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsTab() {
    final mapService = context.read<AdventureMapService>();
    final events = mapService.events;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Events',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: events.isEmpty
                ? _buildEmptyState(
                    icon: Icons.event,
                    title: 'No Events',
                    subtitle: 'Join events to compete with other players',
                  )
                : ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return EventCardWidget(event: event);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: RealmOfValorTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: RealmOfValorTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      heroTag: 'enhanced_map_create_quest_button',
      onPressed: _showCreateQuestDialog,
      backgroundColor: RealmOfValorTheme.accentGold,
      foregroundColor: RealmOfValorTheme.surfaceDark,
      icon: const Icon(Icons.add),
      label: const Text('Create Quest'),
    );
  }

  // Dialog Methods
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Locations'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption('All', 'all'),
            _buildFilterOption('Trails', 'trail'),
            _buildFilterOption('Restaurants', 'restaurant'),
            _buildFilterOption('Pubs', 'pub'),
            _buildFilterOption('Parks', 'park'),
            _buildFilterOption('Gyms', 'gym'),
            _buildFilterOption('Landmarks', 'landmark'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadMapData();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String label, String value) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: _selectedFilter,
      onChanged: (newValue) {
        setState(() => _selectedFilter = newValue!);
      },
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Locations'),
        content: const Text('Search functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _addLocation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Location'),
        content: const Text('Add location functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLeaderboard() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leaderboard'),
        content: const Text('Leaderboard functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEvents() {
    // Navigate to events tab
    _tabController.animateTo(3);
  }

  void _showCreateQuestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Quest'),
        content: const Text('Create quest functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _createQuest() {
    _showCreateQuestDialog();
  }

  void _showPathToQuest(AdventureQuest quest) async {
    // Show path to quest location using proper navigation
    final userLocation = context.read<AdventureMapService>().currentUserLocation;
    if (userLocation != null) {
      try {
        // Get directions from Google Directions API
        final directions = await _getDirectionsToLocation(
          userLocation.latitude,
          userLocation.longitude,
          quest.mapLocation.latitude,
          quest.mapLocation.longitude,
        );
        
        if (directions.isNotEmpty) {
          // Create polyline from directions
          final polyline = Polyline(
            polylineId: PolylineId('path_to_quest_${quest.id}'),
            points: directions,
            color: RealmOfValorTheme.accentGold,
            width: 4,
            patterns: [PatternItem.dot, PatternItem.gap(8)],
          );
          
          setState(() {
            _pathPolylines.add(polyline);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Path to ${quest.name} displayed')),
          );
        } else {
          // Fallback to straight line if directions fail
          _showStraightLinePath(quest);
        }
      } catch (e) {
        debugPrint('Error getting directions: $e');
        // Fallback to straight line
        _showStraightLinePath(quest);
      }
    }
  }

  Future<List<LatLng>> _getDirectionsToLocation(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) async {
    try {
      final apiKey = 'AIzaSyBJoOf8e7Lw2fiFoTY3etNTTkBu-JKhOQQ';
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=$startLat,$startLng'
        '&destination=$endLat,$endLng'
        '&mode=walking'
        '&key=$apiKey'
      );
      
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List;
        
        if (routes.isNotEmpty) {
          final route = routes.first;
          final legs = route['legs'] as List;
          
          if (legs.isNotEmpty) {
            final leg = legs.first;
            final steps = leg['steps'] as List;
            
            final points = <LatLng>[];
            for (final step in steps) {
              final polyline = step['polyline']['points'] as String;
              final decodedPoints = _decodePolyline(polyline);
              points.addAll(decodedPoints);
            }
            
            return points;
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching directions: $e');
    }
    
    return [];
  }

  void _showStraightLinePath(AdventureQuest quest) {
    // Fallback to straight line path
    final userLocation = context.read<AdventureMapService>().currentUserLocation;
    if (userLocation != null) {
      final polyline = Polyline(
        polylineId: PolylineId('path_to_quest_${quest.id}'),
        points: [
          LatLng(userLocation.latitude, userLocation.longitude),
          LatLng(quest.mapLocation.latitude, quest.mapLocation.longitude),
        ],
        color: RealmOfValorTheme.accentGold,
        width: 3,
      );
      
      setState(() {
        _pathPolylines.add(polyline);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Direct path to ${quest.name} displayed')),
      );
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
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

      final p = LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble());
      poly.add(p);
    }
    return poly;
  }

  void _showQuestDetails(AdventureQuest quest) {
    debugPrint('Showing quest details for: ${quest.name}');
    setState(() {
      _selectedQuest = quest;
      _isQuestDetailsVisible = true;
    });
    
    // Add haptic feedback for better UX
    HapticFeedback.lightImpact();
  }

  void _hideQuestDetails() {
    debugPrint('Hiding quest details');
    setState(() {
      _isQuestDetailsVisible = false;
      _selectedQuest = null;
    });
  }

  Widget _buildStravaTrailsIndicator() {
    final mapService = context.read<AdventureMapService>();
    final isLoading = mapService.isLoadingTrails;
    final hasTrails = mapService.trailPolylines.isNotEmpty;

    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: RealmOfValorTheme.surfaceMedium.withOpacity(0.8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: RealmOfValorTheme.accentGold.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(RealmOfValorTheme.accentGold),
              strokeWidth: 2,
            ),
            SizedBox(width: 8),
            Text(
              'Loading Trails...',
              style: TextStyle(
                color: RealmOfValorTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else if (hasTrails) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: RealmOfValorTheme.surfaceMedium.withOpacity(0.8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: RealmOfValorTheme.accentGold.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_bike,
              color: RealmOfValorTheme.accentGold,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Strava Trails Loaded',
              style: TextStyle(
                color: RealmOfValorTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink(); // No indicator if not loading and no trails
    }
  }
}

// Supporting Widgets
class LocationDetailsSheet extends StatelessWidget {
  final MapLocation location;

  const LocationDetailsSheet({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: RealmOfValorTheme.textSecondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: RealmOfValorTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    location.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: RealmOfValorTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLocationInfo(),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Column(
      children: [
        _buildInfoRow('Address', location.address),
        if (location.rating != null)
          _buildInfoRow('Rating', '${location.rating}/5'),
        if (location.reviewCount != null)
          _buildInfoRow('Reviews', '${location.reviewCount}'),
        _buildInfoRow('Type', location.type.name),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: RealmOfValorTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Implement directions
            },
            icon: const Icon(Icons.directions),
            label: const Text('Directions'),
            style: ElevatedButton.styleFrom(
              backgroundColor: RealmOfValorTheme.accentGold,
              foregroundColor: RealmOfValorTheme.surfaceDark,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Implement share
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
            style: ElevatedButton.styleFrom(
              backgroundColor: RealmOfValorTheme.surfaceDark,
              foregroundColor: RealmOfValorTheme.accentGold,
            ),
          ),
        ),
      ],
    );
  }
}

class QuestDetailsSheet extends StatelessWidget {
  final AdventureQuest quest;

  const QuestDetailsSheet({super.key, required this.quest});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: RealmOfValorTheme.textSecondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: RealmOfValorTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    quest.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: RealmOfValorTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildQuestInfo(),
                  const SizedBox(height: 16),
                  _buildObjectives(),
                  const SizedBox(height: 16),
                  _buildRewards(),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestInfo() {
    return Column(
      children: [
        _buildInfoRow('Difficulty', quest.difficulty.name),
        _buildInfoRow('Type', quest.type.name),
        _buildInfoRow('Status', quest.status.name),
        _buildInfoRow('Experience', '${quest.experienceReward} XP'),
        _buildInfoRow('Gold', '${quest.goldReward} Gold'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: RealmOfValorTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObjectives() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Objectives',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: RealmOfValorTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...quest.objectives.map((objective) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(
                objective.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: objective.isCompleted 
                    ? Colors.green 
                    : RealmOfValorTheme.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  objective.description,
                  style: TextStyle(color: RealmOfValorTheme.textSecondary),
                ),
              ),
              Text(
                '${objective.currentValue}/${objective.targetValue}',
                style: TextStyle(
                  color: RealmOfValorTheme.accentGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildRewards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rewards',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: RealmOfValorTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...quest.rewards.map((reward) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(
                Icons.star,
                color: RealmOfValorTheme.accentGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${reward.name}: ${reward.value}',
                style: TextStyle(color: RealmOfValorTheme.textSecondary),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Implement start quest
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Quest'),
            style: ElevatedButton.styleFrom(
              backgroundColor: RealmOfValorTheme.accentGold,
              foregroundColor: RealmOfValorTheme.surfaceDark,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Implement share quest
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
            style: ElevatedButton.styleFrom(
              backgroundColor: RealmOfValorTheme.surfaceDark,
              foregroundColor: RealmOfValorTheme.accentGold,
            ),
          ),
        ),
      ],
    );
  }
}

class EventCardWidget extends StatelessWidget {
  final MapEvent event;

  const EventCardWidget({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: RealmOfValorTheme.accentGold.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.event,
                color: RealmOfValorTheme.accentGold,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: RealmOfValorTheme.textPrimary,
                      ),
                    ),
                    Text(
                      event.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: RealmOfValorTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: event.isActive 
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  event.isActive ? 'ACTIVE' : 'INACTIVE',
                  style: TextStyle(
                    color: event.isActive ? Colors.green : Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: RealmOfValorTheme.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  event.location.name,
                  style: TextStyle(
                    color: RealmOfValorTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.people,
                color: RealmOfValorTheme.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${event.participants.length}/${event.maxParticipants} participants',
                style: TextStyle(
                  color: RealmOfValorTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Implement join event
                  },
                  child: const Text('Join Event'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RealmOfValorTheme.accentGold,
                    foregroundColor: RealmOfValorTheme.surfaceDark,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 