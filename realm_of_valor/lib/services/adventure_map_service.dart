import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/weather_model.dart';
import '../services/quest_generator_service.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';
import '../services/encounter_service.dart';

class AdventureMapService extends ChangeNotifier {
  static final AdventureMapService _instance = AdventureMapService._internal();
  factory AdventureMapService() => _instance;
  AdventureMapService._internal();

  final QuestGeneratorService _questGenerator = QuestGeneratorService();
  final LocationService _locationService = LocationService.instance;
  final WeatherService _weatherService = WeatherService();
  final EncounterService _encounterService = EncounterService();

  List<AdventureQuest> _quests = [];
  Set<String> _activeQuestIds = {};
  UserLocation? _currentUserLocation;
  Map<String, dynamic> _weatherData = {};
  bool _isLoading = false;

  // Getters
  List<AdventureQuest> get quests => _quests;
  Set<String> get activeQuestIds => _activeQuestIds;
  UserLocation? get currentUserLocation => _currentUserLocation;
  Map<String, dynamic> get weatherData => _weatherData;
  bool get isLoading => _isLoading;

  // Initialize the service
  Future<void> initialize() async {
    debugPrint('[AdventureMapService] Initializing...');
    
    // Get current location
    await updateUserLocation();
    
    // Generate initial quests
    await generateQuests();
    
    // Start location tracking
    _locationService.startLocationUpdates((location) {
      _currentUserLocation = location;
      _updateQuestDistances();
      notifyListeners();
    });
    
    debugPrint('[AdventureMapService] Initialized successfully');
  }

  // Update user location
  Future<void> updateUserLocation() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUserLocation = await _locationService.getCurrentLocation();
      
      if (_currentUserLocation != null) {
        // Check if user is in Norwich area (for testing purposes, switch to Northampton)
        if (_currentUserLocation!.latitude > 52.6 && _currentUserLocation!.longitude > 1.2) {
          debugPrint('[AdventureMapService] Detected Norwich location, switching to Northampton for testing');
          _currentUserLocation = UserLocation(
            userId: 'player',
            latitude: 52.2405, // Northampton coordinates
            longitude: -0.9027,
            accuracy: _currentUserLocation!.accuracy,
            timestamp: DateTime.now(),
          );
        }
        
        debugPrint('[AdventureMapService] Location updated: ${_currentUserLocation!.latitude}, ${_currentUserLocation!.longitude}');
        
        // Update weather data for the new location
        await updateWeatherData();
        
        // Update quest distances
        _updateQuestDistances();
      } else {
        debugPrint('[AdventureMapService] Failed to get current location');
      }
    } catch (e) {
      debugPrint('[AdventureMapService] Error updating location: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Generate quests around current location
  Future<void> generateQuests() async {
    if (_currentUserLocation == null) {
      debugPrint('[AdventureMapService] No location available for quest generation');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('[AdventureMapService] Generating quests around location: ${_currentUserLocation!.latitude}, ${_currentUserLocation!.longitude}');
      
      // Generate quests in a 5km radius
      final newQuests = await _questGenerator.generateQuests(_currentUserLocation!, 5.0);
      
      _quests = newQuests;
      
      debugPrint('[AdventureMapService] Generated ${_quests.length} quests');
      for (int i = 0; i < _quests.length; i++) {
        debugPrint('[AdventureMapService] Quest $i: ${_quests[i].title} at ${_quests[i].location}');
      }
      
      // Update quest distances
      _updateQuestDistances();
      
    } catch (e) {
      debugPrint('[AdventureMapService] Error generating quests: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update weather data
  Future<void> updateWeatherData() async {
    if (_currentUserLocation == null) return;

    try {
      final weatherData = await _weatherService.getCurrentWeather(_currentUserLocation!);
      _weatherData = {
        'temperature': weatherData.temperature,
        'condition': weatherData.condition.name,
        'description': weatherData.description,
      };
      debugPrint('[AdventureMapService] Weather data updated');
    } catch (e) {
      debugPrint('[AdventureMapService] Error updating weather: $e');
    }
  }

  // Update distances for all quests
  void _updateQuestDistances() {
    if (_currentUserLocation == null) return;

    for (final quest in _quests) {
      // Calculate distance from current location to quest location
      final distance = _calculateDistance(
        _currentUserLocation!.latitude,
        _currentUserLocation!.longitude,
        quest.location.latitude,
        quest.location.longitude,
      );
      
      // Store distance in quest metadata (if available)
      // Note: The current AdventureQuest model doesn't have a distance field
      // This would need to be added to the model or stored separately
    }
  }

  // Calculate distance between two points
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double lat1Rad = _degreesToRadians(lat1);
    final double lat2Rad = _degreesToRadians(lat2);
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  // Quest management
  bool isQuestActive(String questId) {
    return _activeQuestIds.contains(questId);
  }

  void startQuest(String questId) {
    if (!_activeQuestIds.contains(questId)) {
      _activeQuestIds.add(questId);
      debugPrint('[AdventureMapService] Started quest: $questId');
      notifyListeners();
    }
  }

  void stopQuest(String questId) {
    if (_activeQuestIds.contains(questId)) {
      _activeQuestIds.remove(questId);
      debugPrint('[AdventureMapService] Stopped quest: $questId');
      notifyListeners();
    }
  }

  // Get quest by ID
  AdventureQuest? getQuestById(String questId) {
    try {
      return _quests.firstWhere((quest) => quest.id == questId);
    } catch (e) {
      return null;
    }
  }

  // Get nearby quests
  List<AdventureQuest> getNearbyQuests(double radius) {
    if (_currentUserLocation == null) return [];

    return _quests.where((quest) {
      final distance = _calculateDistance(
        _currentUserLocation!.latitude,
        _currentUserLocation!.longitude,
        quest.location.latitude,
        quest.location.longitude,
      );
      return distance <= radius;
    }).toList();
  }

  // Get quests by type
  List<AdventureQuest> getQuestsByType(QuestType type) {
    return _quests.where((quest) => quest.type == type).toList();
  }

  // Get active quests
  List<AdventureQuest> getActiveQuests() {
    return _quests.where((quest) => _activeQuestIds.contains(quest.id)).toList();
  }

  // Refresh quests
  Future<void> refreshQuests() async {
    await generateQuests();
  }

  // Cleanup
  @override
  void dispose() {
    _locationService.stopLocationUpdates();
    super.dispose();
  }
} 