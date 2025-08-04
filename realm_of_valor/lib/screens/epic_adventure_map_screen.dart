import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'dart:convert'; // Added for JSON decoding
import 'package:http/http.dart' as http; // Added for HTTP requests

import '../services/location_service.dart';
import '../services/weather_service.dart';
import '../services/quest_generator_service.dart';
import '../services/loot_system_service.dart';
import '../services/dynamic_event_service.dart';
import '../services/navigation_service.dart';
import '../services/character_service.dart';
import '../services/combat_service.dart';
import '../services/social_service.dart';
import '../services/performance_service.dart';
import '../services/encounter_service.dart';
import '../services/adventure_map_service.dart';
import '../services/fitness_tracker_service.dart';
import '../services/item_finding_service.dart';

import '../widgets/quest_details_sheet.dart';
import '../widgets/quest_tracking_widget.dart'; // Re-enabled
import '../widgets/gps_spoof_controller.dart';
import '../widgets/rewards_popup_widget.dart';
import '../widgets/equipment_inventory_widget.dart';
import '../widgets/mobile_window_manager.dart';

import '../models/character_model.dart';
import '../models/weather_model.dart';
import '../constants/theme.dart';
import '../providers/character_provider.dart';
import '../models/card_model.dart';

class EpicAdventureMapScreen extends StatefulWidget {
  const EpicAdventureMapScreen({super.key});

  @override
  State<EpicAdventureMapScreen> createState() => _EpicAdventureMapScreenState();
}

class _EpicAdventureMapScreenState extends State<EpicAdventureMapScreen>
    with TickerProviderStateMixin {
  // Core Map Controllers
  GoogleMapController? _mapController;
  late AnimationController _mapAnimationController;
  late AnimationController _uiAnimationController;
  
  // Map State
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  Set<Polyline> _polylines = {};
  UserLocation? _currentLocation;
  double _searchRadius = 5.0; // km
  bool _isMapReady = false;
  
  // UI State
  bool _showQuestLog = false;
  bool _showInventory = false;
  bool _isQuestActive = false;
  bool _showRewards = false; // New state for rewards display
  AdventureQuest? _currentRewardQuest; // Track which quest has rewards
  
  // Enhanced Features State
  bool _showHapticFeedback = true;
  bool _showSoundEffects = true;
  bool _showAchievementPopups = true;
  bool _showLevelUpAnimations = true;
  
  // Services
  late AdventureMapService _adventureMapService;
  late LocationService _locationService;
  late WeatherService _weatherService;
  late QuestGeneratorService _questGeneratorService;
  late LootSystemService _lootSystemService;
  late DynamicEventService _dynamicEventService;
  late NavigationService _navigationService;
  late CharacterService _characterService;
  late CombatService _combatService;
  late SocialService _socialService;
  late PerformanceService _performanceService;
  late EncounterService _encounterService;
  late ItemFindingService _itemFindingService;

  // Quest Management
  Set<String> _activeQuests = {};
  List<AdventureQuest> _availableQuests = [];

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeMap();
    _loadMapData(); // This will initialize AdventureMapService and load location/quests
  }

  void _initializeServices() {
    _adventureMapService = AdventureMapService();
    _locationService = LocationService.instance;
    _questGeneratorService = QuestGeneratorService();
    _weatherService = WeatherService();
    _lootSystemService = LootSystemService();
    _dynamicEventService = DynamicEventService();
    _navigationService = NavigationService();
    _characterService = CharacterService();
    _combatService = CombatService();
    _socialService = SocialService.instance;
    _performanceService = PerformanceService.instance;
    _encounterService = EncounterService();
    _itemFindingService = ItemFindingService();
    
    // Initialize item finding service
    _itemFindingService.initialize();
  }

  void _initializeMap() {
    _mapAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _uiAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  void _startLocationUpdates() {
    // Listen to AdventureMapService updates
    _adventureMapService.addListener(() {
      if (mounted) {
        setState(() {
          _currentLocation = _adventureMapService.currentUserLocation;
          _availableQuests = _adventureMapService.quests;
          _updateMapMarkers();
        });
      }
    });
    
    // Listen to ItemFindingService updates
    _itemFindingService.addListener(() {
      if (mounted) {
        setState(() {
          _updateMapMarkers();
        });
      }
    });
  }

  Future<void> _requestPermissions() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showPermissionDialog();
      }
    } catch (e) {
      debugPrint('Permission error: $e');
    }
  }

  Future<void> _loadMapData() async {
    try {
      debugPrint('[EpicAdventureMapScreen] Starting to load map data...');
      
      // Initialize AdventureMapService
      await _adventureMapService.initialize();
      debugPrint('[EpicAdventureMapScreen] AdventureMapService initialized');
      
      // Get current location and quests from AdventureMapService
      _currentLocation = _adventureMapService.currentUserLocation;
      _availableQuests = _adventureMapService.quests;
      
      debugPrint('[EpicAdventureMapScreen] Current location: $_currentLocation');
      debugPrint('[EpicAdventureMapScreen] Available quests: ${_availableQuests.length}');
      
      // Update map markers
      _updateMapMarkers();
      
      // Animate camera to user location
      if (_currentLocation != null && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
            12,
          ),
        );
      }
      
      // Start location tracking
      _startLocationUpdates();
      
      setState(() {
        _isMapReady = true;
      });
      
      // Trigger initial animations
      _mapAnimationController.forward();
      _uiAnimationController.forward();
      
      debugPrint('[EpicAdventureMapScreen] Map data loaded successfully');
      
    } catch (e) {
      debugPrint('[EpicAdventureMapScreen] Error loading map data: $e');
      _showErrorDialog('Failed to load map data');
    }
  }

  void _updateMapMarkers() {
    debugPrint('[EpicAdventureMapScreen] Updating map markers...');
    debugPrint('[EpicAdventureMapScreen] Available quests: ${_availableQuests.length}');
    debugPrint('[EpicAdventureMapScreen] Current location: $_currentLocation');
    debugPrint('[EpicAdventureMapScreen] AdventureMapService quests: ${_adventureMapService.quests.length}');
    debugPrint('[EpicAdventureMapScreen] AdventureMapService current location: ${_adventureMapService.currentUserLocation}');
    
    _markers.clear();
    
    // Add quest markers
    for (final quest in _availableQuests) {
      debugPrint('[EpicAdventureMapScreen] Adding quest marker: ${quest.title} at ${quest.location}');
      _markers.add(
        Marker(
          markerId: MarkerId('quest_${quest.id}'),
          position: quest.location,
          icon: _getQuestMarkerIcon(quest),
          onTap: () => _showQuestDetails(quest),
          infoWindow: InfoWindow(
            title: quest.title,
            snippet: quest.description,
          ),
        ),
      );
    }
    
    // Add item spawn markers
    for (final spawn in _itemFindingService.activeSpawns) {
      if (!spawn.isCollected) {
        debugPrint('[EpicAdventureMapScreen] Adding item spawn marker: ${spawn.item.card.name}');
        _markers.add(
          Marker(
            markerId: MarkerId('item_${spawn.id}'),
            position: LatLng(spawn.location.latitude, spawn.location.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
            onTap: () => _showItemSpawnDetails(spawn),
            infoWindow: InfoWindow(
              title: 'Item Found!',
              snippet: spawn.item.card.name,
            ),
          ),
        );
      }
    }
    
    // Add player marker
    if (_currentLocation != null) {
      debugPrint('[EpicAdventureMapScreen] Adding player marker at ${_currentLocation!.latitude}, ${_currentLocation!.longitude}');
      _markers.add(
        Marker(
          markerId: const MarkerId('player'),
          position: LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'You',
            snippet: 'Current Location',
          ),
        ),
      );
    }
    
    debugPrint('[EpicAdventureMapScreen] Total markers: ${_markers.length}');
  }

  BitmapDescriptor _getQuestMarkerIcon(AdventureQuest quest) {
    switch (quest.type) {
      case QuestType.exploration:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case QuestType.social:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case QuestType.fitness:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case QuestType.collection:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      case QuestType.battle:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case QuestType.walking:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      case QuestType.running:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      case QuestType.climbing:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
      case QuestType.location:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      case QuestType.time:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      case QuestType.weather:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
    }
  }

  void _startLocationTracking() {
    _locationService.startLocationUpdates((location) {
      setState(() {
        _currentLocation = location;
      });
      
      // Update player marker
      _updatePlayerMarker();
      
      // Check quest progress
      _checkQuestProgress(location);
    });
  }

  void _updatePlayerMarker() {
    if (_currentLocation != null) {
      setState(() {
        _markers.removeWhere((marker) => marker.markerId.value == 'player');
        _markers.add(
          Marker(
            markerId: const MarkerId('player'),
            position: LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(
              title: 'You',
              snippet: 'Current Location',
            ),
          ),
        );
      });
    }
  }

  void _checkQuestProgress(UserLocation location) {
    for (final quest in _availableQuests) {
      if (_activeQuests.contains(quest.id)) {
        final distance = Geolocator.distanceBetween(
          location.latitude,
          location.longitude,
          quest.location.latitude,
          quest.location.longitude,
        );
        
        // If within quest radius, complete the quest
        if (distance <= quest.radius) {
          _completeQuest(quest);
        }
      }
    }
  }

  void _showQuestDetails(AdventureQuest quest) {
    debugPrint('[EpicAdventureMapScreen] Showing quest details for: ${quest.title}');
    if (_showHapticFeedback) {
      HapticFeedback.mediumImpact();
    }
    
    final characterProvider = Provider.of<CharacterProvider>(context, listen: false);
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => GestureDetector(
        onScaleUpdate: (_) {}, // Prevent map zooming when touching this widget
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.4,
            height: MediaQuery.of(context).size.height,
            child: QuestDetailsSheet(
              quest: quest,
              onStartQuest: () => _startQuest(quest, characterProvider),
              onStopQuest: () => _stopQuest(quest, characterProvider),
              onShowPath: () => _showPathToQuest(quest),
              isActive: _activeQuests.contains(quest.id),
            ),
          ),
        ),
      ),
    );
  }

  void _startQuest(AdventureQuest quest, CharacterProvider characterProvider) {
    debugPrint('[EpicAdventureMapScreen] Starting quest: ${quest.title}');
    setState(() {
      _activeQuests.add(quest.id);
    });
    
    // Update character with quest start
    characterProvider.startQuest(quest.title, '${quest.location.latitude}, ${quest.location.longitude}');
    
    // Close the quest details sheet
    Navigator.of(context).pop();
    
    // Show quest started notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Started quest: ${quest.title}'),
        backgroundColor: RealmOfValorTheme.accentGold,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _stopQuest(AdventureQuest quest, CharacterProvider characterProvider) {
    debugPrint('[EpicAdventureMapScreen] Stopping quest: ${quest.title}');
    setState(() {
      _activeQuests.remove(quest.id);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Stopped quest: ${quest.title}'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showPathToQuest(AdventureQuest quest) {
    debugPrint('[EpicAdventureMapScreen] Showing path to quest: ${quest.title}');
    
    if (_currentLocation != null) {
      // Clear existing routes
      setState(() {
        _polylines.clear();
      });
      
      // Get walking route from Google Maps Directions API
      _getWalkingRoute(
        LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
        quest.location,
      );
      
      // Show route info
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Getting route to ${quest.title}...'),
          backgroundColor: RealmOfValorTheme.accentGold,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _getWalkingRoute(LatLng origin, LatLng destination) async {
    try {
      // Check if we have a valid API key (not the placeholder)
      const apiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
      if (apiKey == 'YOUR_GOOGLE_MAPS_API_KEY') {
        debugPrint('[EpicAdventureMapScreen] Google Maps API key not configured. Using fallback route.');
        _showFallbackRoute(origin, destination);
        return;
      }

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=walking'
        '&key=$apiKey'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final points = _decodePolyline(route['overview_polyline']['points']);

          setState(() {
            _polylines.add(
              Polyline(
                polylineId: PolylineId('walking_route'),
                points: points,
                color: Colors.blue,
                width: 6,
                geodesic: true,
                patterns: [PatternItem.dot, PatternItem.gap(10)],
              ),
            );
          });

          _mapController?.animateCamera(
            CameraUpdate.newLatLngBounds(
              _getBoundsForRoute(points),
              50,
            ),
          );

          final duration = route['legs'][0]['duration']['text'];
          final distance = route['legs'][0]['distance']['text'];

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Walking route: $distance, $duration'),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          _showFallbackRoute(origin, destination);
        }
      } else {
        _showFallbackRoute(origin, destination);
      }
    } catch (e) {
      debugPrint('[EpicAdventureMapScreen] Error getting route: $e');
      _showFallbackRoute(origin, destination);
    }
  }

  void _showFallbackRoute(LatLng origin, LatLng destination) {
    final points = [origin, destination];

    setState(() {
      _polylines.add(
        Polyline(
          polylineId: PolylineId('fallback_route'),
          points: points,
          color: Colors.red,
          width: 4,
          geodesic: true,
          patterns: [PatternItem.dot, PatternItem.gap(10)],
        ),
      );
    });

    // Calculate approximate distance and time
    final distance = _calculateDistance(origin, destination);
    final estimatedTime = _calculateEstimatedTime(distance, isWalking: true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Direct route: ${distance.toStringAsFixed(1)}km, ~${estimatedTime}min (API key needed for detailed routing)'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final lat1 = point1.latitude * (pi / 180);
    final lat2 = point2.latitude * (pi / 180);
    final deltaLat = (point2.latitude - point1.latitude) * (pi / 180);
    final deltaLng = (point2.longitude - point1.longitude) * (pi / 180);
    
    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLng / 2) * sin(deltaLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  String _calculateEstimatedTime(double distanceKm, {bool isWalking = true}) {
    // Walking speed: ~5 km/h, Cycling: ~15 km/h
    final speedKmH = isWalking ? 5.0 : 15.0;
    final timeHours = distanceKm / speedKmH;
    final timeMinutes = (timeHours * 60).round();
    return timeMinutes.toString();
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
  
  // Generate realistic route points with waypoints
  List<LatLng> _generateRoutePoints(LatLng start, LatLng end) {
    final points = <LatLng>[start];
    
    // Add intermediate waypoints for more realistic routing
    final distance = Geolocator.distanceBetween(
      start.latitude, start.longitude,
      end.latitude, end.longitude,
    );
    
    if (distance > 1000) { // If distance > 1km, add waypoints
      final numWaypoints = (distance / 500).round().clamp(1, 5);
      
      for (int i = 1; i <= numWaypoints; i++) {
        final ratio = i / (numWaypoints + 1);
        final lat = start.latitude + (end.latitude - start.latitude) * ratio;
        final lng = start.longitude + (end.longitude - start.longitude) * ratio;
        
        // Add some randomness to make it look more like a real route
        final random = Random();
        final latOffset = (random.nextDouble() - 0.5) * 0.001;
        final lngOffset = (random.nextDouble() - 0.5) * 0.001;
        
        points.add(LatLng(lat + latOffset, lng + lngOffset));
      }
    }
    
    points.add(end);
    return points;
  }

  LatLngBounds _getBoundsForRoute(List<LatLng> points) {
    double? minLat, maxLat, minLng, maxLng;
    
    for (final point in points) {
      minLat = minLat == null ? point.latitude : min(minLat, point.latitude);
      maxLat = maxLat == null ? point.latitude : max(maxLat, point.latitude);
      minLng = minLng == null ? point.longitude : min(minLng, point.longitude);
      maxLng = maxLng == null ? point.longitude : max(maxLng, point.longitude);
    }
    
    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  void _completeQuest(AdventureQuest quest) {
    final characterProvider = Provider.of<CharacterProvider>(context, listen: false);
    final fitnessTracker = Provider.of<FitnessTrackerService>(context, listen: false);
    
    // Calculate distance traveled (simplified - in real app this would track actual distance)
    final distanceTraveled = quest.radius * 1000; // Convert radius from km to meters
    
    // Complete quest in character system with proper gold and XP rewards
    characterProvider.completeQuest(
      quest.title,
      quest.rewardXP,
      quest.rewards.map((r) => CardInstance(
        card: GameCard(
          name: r.description,
          description: r.description,
          type: CardType.item,
          rarity: CardRarity.common,
        ),
      )).toList(),
      goldReward: quest.rewardGold,
    );
    
    // Log distance to fitness tracker
    fitnessTracker.addQuestDistance(distanceTraveled, quest.title);
    
    // Remove from active quests
    setState(() {
      _activeQuests.remove(quest.id);
      _markers.removeWhere((marker) => marker.markerId.value == 'quest_${quest.id}');
    });
    
    // Show completion notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Quest completed: ${quest.title} (+${quest.rewardXP} XP, +${quest.rewardGold} Gold)'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
    
    // Show reward animation
    _showRewardAnimation(quest);
  }

  void _showRewardAnimation(AdventureQuest quest) {
    setState(() {
      _showRewards = true;
      _showInventory = true; // Open inventory when showing rewards
      _currentRewardQuest = quest;
    });
  }

  List<Widget> _buildAllRewards(AdventureQuest quest) {
    final widgets = <Widget>[];
    
    // Add XP and Gold rewards
    widgets.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildRewardItem(Icons.star, '${quest.rewardXP} XP', Colors.amber),
          _buildRewardItem(Icons.monetization_on, '${quest.rewardGold} Gold', Colors.yellow),
        ],
      ),
    );
    
    // Add item rewards
    final itemRewards = quest.rewards.where((r) => r.type == RewardType.item).toList();
    if (itemRewards.isNotEmpty) {
      widgets.add(const SizedBox(height: 16));
      widgets.add(
        Text(
          'Items Found:',
          style: TextStyle(
            color: RealmOfValorTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );
      widgets.add(const SizedBox(height: 8));
      
      // Display item rewards in a grid
      final itemWidgets = <Widget>[];
      for (final reward in itemRewards) {
        itemWidgets.add(
          _buildItemReward(reward),
        );
      }
      
      widgets.add(
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: itemWidgets,
        ),
      );
    }
    
    return widgets;
  }

  Widget _buildItemReward(QuestReward reward) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: RealmOfValorTheme.accentGold.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getItemIcon(reward.description),
            color: _getItemColor(reward.description),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            reward.description,
            style: TextStyle(
              color: RealmOfValorTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (reward.amount > 1)
            Text(
              'x${reward.amount}',
              style: TextStyle(
                color: RealmOfValorTheme.accentGold,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  IconData _getItemIcon(String itemName) {
    final lowerName = itemName.toLowerCase();
    if (lowerName.contains('sword') || lowerName.contains('weapon')) {
      return Icons.gps_fixed;
    } else if (lowerName.contains('armor') || lowerName.contains('shield')) {
      return Icons.shield;
    } else if (lowerName.contains('potion') || lowerName.contains('heal')) {
      return Icons.local_drink;
    } else if (lowerName.contains('scroll') || lowerName.contains('spell')) {
      return Icons.auto_stories;
    } else if (lowerName.contains('treasure') || lowerName.contains('gold')) {
      return Icons.workspace_premium;
    } else if (lowerName.contains('rare')) {
      return Icons.diamond;
    } else {
      return Icons.inventory;
    }
  }

  Color _getItemColor(String itemName) {
    final lowerName = itemName.toLowerCase();
    if (lowerName.contains('rare')) {
      return Colors.purple;
    } else if (lowerName.contains('epic')) {
      return Colors.deepPurple;
    } else if (lowerName.contains('legendary')) {
      return Colors.orange;
    } else if (lowerName.contains('potion')) {
      return Colors.green;
    } else if (lowerName.contains('weapon')) {
      return Colors.red;
    } else if (lowerName.contains('armor')) {
      return Colors.blue;
    } else {
      return RealmOfValorTheme.accentGold;
    }
  }

  Color _getRarityColor(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.common:
        return Colors.grey;
      case CardRarity.uncommon:
        return Colors.green;
      case CardRarity.rare:
        return Colors.blue;
      case CardRarity.epic:
        return Colors.purple;
      case CardRarity.legendary:
        return Colors.orange;
      case CardRarity.mythic:
        return Colors.red;
      case CardRarity.holographic:
        return Colors.cyan;
      case CardRarity.firstEdition:
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRewardItem(IconData icon, String text, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text('This app needs location access to provide the adventure map experience.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _requestPermissions();
            },
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showItemSpawnDetails(ItemSpawn spawn) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RealmOfValorTheme.surfaceDark,
        title: Text(
          'Item Found!',
          style: TextStyle(
            color: RealmOfValorTheme.accentGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getItemIcon(spawn.item.card.name),
              color: _getItemColor(spawn.item.card.name),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              spawn.item.card.name,
              style: TextStyle(
                color: RealmOfValorTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              spawn.item.card.description,
              style: TextStyle(
                color: RealmOfValorTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Rarity: ${spawn.item.card.rarity.name.toUpperCase()}',
              style: TextStyle(
                color: _getRarityColor(spawn.item.card.rarity),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: RealmOfValorTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _collectItem(spawn);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RealmOfValorTheme.accentGold,
              foregroundColor: Colors.black,
            ),
            child: const Text('Collect'),
          ),
        ],
      ),
    );
  }

  Future<void> _collectItem(ItemSpawn spawn) async {
    try {
      final collectedItem = await _itemFindingService.collectItem(spawn.id);
      if (collectedItem != null) {
        // Add to character inventory
        final characterProvider = Provider.of<CharacterProvider>(context, listen: false);
        await characterProvider.addToInventory(collectedItem);
        
        // Update map markers
        _updateMapMarkers();
        
        // Show success notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Collected ${collectedItem.card.name}!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error collecting item: $e');
    }
  }

  @override
  void dispose() {
    _mapAnimationController.dispose();
    _uiAnimationController.dispose();
    _locationService.stopLocationUpdates();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main Map
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _currentLocation != null 
                ? LatLng(_currentLocation!.latitude, _currentLocation!.longitude)
                : const LatLng(52.2405, -0.9027), // Northampton, UK as fallback
              zoom: 12, // Zoom out a bit to see more quests
            ),
            markers: _markers,
            circles: _circles,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            onCameraMove: (CameraPosition position) {
              // Handle camera movement
            },
            // Disable map interactions when inventory is open
            zoomGesturesEnabled: !_showInventory && !_showQuestLog,
            scrollGesturesEnabled: !_showInventory && !_showQuestLog,
            tiltGesturesEnabled: !_showInventory && !_showQuestLog,
            rotateGesturesEnabled: !_showInventory && !_showQuestLog,
          ),
          
          // UI Overlays with gesture detection
          _buildTopBar(),
          _buildQuestLog(),
          _buildQuestTrackingWidget(), // Re-enabled
          if (_showInventory)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: EquipmentInventoryWidget(
                onClose: () {
                  setState(() {
                    _showInventory = false;
                    _showRewards = false;
                    _currentRewardQuest = null;
                  });
                },
                onItemDropped: (item) async {
                  debugPrint('[EpicAdventureMapScreen] Item dropped in inventory: ${item.card.name}');
                  final characterProvider = Provider.of<CharacterProvider>(context, listen: false);
                  await characterProvider.addToInventory(item);
                  
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${item.card.name} added to inventory!'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                showRewards: _showRewards,
                rewardQuest: _currentRewardQuest,
                onRewardCollected: (item) async {
                  debugPrint('[EpicAdventureMapScreen] Reward collected: ${item.card.name}');
                  final characterProvider = Provider.of<CharacterProvider>(context, listen: false);
                  await characterProvider.addToInventory(item);
                  
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${item.card.name} added to inventory!'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                onRewardsClosed: () {
                  setState(() {
                    _showRewards = false;
                    _currentRewardQuest = null;
                  });
                  
                  // Complete the quest after rewards are handled
                  if (_currentRewardQuest != null) {
                    _completeQuest(_currentRewardQuest!);
                    _currentRewardQuest = null;
                  }
                },
              ),
            ),
          GpsSpoofController(
            currentLocation: _currentLocation != null 
              ? LatLng(_currentLocation!.latitude, _currentLocation!.longitude)
              : const LatLng(52.2405, -0.9027), // Northampton, UK as fallback
            onLocationChanged: _updateSpoofedLocation,
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: GestureDetector(
        onScaleUpdate: (_) {}, // Prevent map zooming when touching this widget
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: RealmOfValorTheme.surfaceDark.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.explore,
                color: RealmOfValorTheme.accentGold,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Adventure Map',
                  style: TextStyle(
                    color: RealmOfValorTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  debugPrint('[EpicAdventureMapScreen] Toggling quest log: ${!_showQuestLog}');
                  setState(() {
                    _showQuestLog = !_showQuestLog;
                  });
                },
                icon: Icon(
                  _showQuestLog ? Icons.close : Icons.list,
                  color: RealmOfValorTheme.accentGold,
                ),
              ),
                             IconButton(
                 onPressed: () {
                   debugPrint('[EpicAdventureMapScreen] Toggling inventory: ${!_showInventory}');
                   setState(() {
                     _showInventory = !_showInventory;
                   });
                 },
                 icon: Icon(
                   Icons.inventory,
                   color: RealmOfValorTheme.accentGold,
                 ),
               ),
               IconButton(
                 onPressed: () {
                   debugPrint('[EpicAdventureMapScreen] Clearing routes');
                   setState(() {
                     _polylines.clear();
                   });
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(
                       content: const Text('Routes cleared'),
                       backgroundColor: Colors.orange,
                       duration: const Duration(seconds: 1),
                     ),
                   );
                 },
                 icon: Icon(
                   Icons.clear_all,
                   color: RealmOfValorTheme.accentGold,
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestLog() {
    if (!_showQuestLog) return const SizedBox.shrink();
    
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      left: 16,
      right: 16,
      child: GestureDetector(
        onScaleUpdate: (_) {}, // Prevent map zooming when touching this widget
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: RealmOfValorTheme.surfaceDark.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available Quests',
                style: TextStyle(
                  color: RealmOfValorTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _availableQuests.length,
                  itemBuilder: (context, index) {
                    final quest = _availableQuests[index];
                    final isActive = _activeQuests.contains(quest.id);
                    
                    return ListTile(
                      leading: Icon(
                        _getQuestIcon(quest.type),
                        color: isActive ? Colors.green : RealmOfValorTheme.accentGold,
                      ),
                      title: Text(
                        quest.title,
                        style: TextStyle(
                          color: RealmOfValorTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        quest.description,
                        style: TextStyle(
                          color: RealmOfValorTheme.textSecondary,
                        ),
                      ),
                      trailing: Text(
                        '${quest.rewardXP} XP',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () => _showQuestDetails(quest),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getQuestIcon(QuestType type) {
    switch (type) {
      case QuestType.exploration:
        return Icons.explore;
      case QuestType.social:
        return Icons.people;
      case QuestType.fitness:
        return Icons.fitness_center;
      case QuestType.collection:
        return Icons.collections;
      case QuestType.battle:
        return Icons.sports_martial_arts;
      case QuestType.walking:
        return Icons.directions_walk;
      case QuestType.running:
        return Icons.directions_run;
      case QuestType.climbing:
        return Icons.terrain;
      case QuestType.location:
        return Icons.location_on;
      case QuestType.time:
        return Icons.access_time;
      case QuestType.weather:
        return Icons.cloud;
    }
  }

  Widget _buildQuestTrackingWidget() {
    // Show quest tracking widget if there's an active quest
    if (_activeQuests.isEmpty) return const SizedBox.shrink();
    
    final activeQuest = _availableQuests.firstWhere(
      (quest) => _activeQuests.contains(quest.id),
      orElse: () => _availableQuests.first,
    );
    
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      left: 16,
      child: GestureDetector(
        onScaleUpdate: (_) {}, // Prevent map zooming when touching this widget
        child: QuestTrackingWidget(
          quest: activeQuest,
          onStopQuest: () => _stopQuest(activeQuest, Provider.of<CharacterProvider>(context, listen: false)),
          onShowFullDetails: () => _showQuestDetails(activeQuest),
        ),
      ),
    );
  }

  void _updateSpoofedLocation(LatLng newLocation) {
    setState(() {
      _currentLocation = UserLocation(
        userId: 'player',
        latitude: newLocation.latitude,
        longitude: newLocation.longitude,
        accuracy: 0,
        timestamp: DateTime.now(),
      );
      _updateMapMarkers();
    });
    
    // Check quest progress with new location
    _checkQuestProgress(_currentLocation!);
  }
} 