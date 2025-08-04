import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../models/weather_model.dart';
import '../models/card_model.dart';

class ItemFindingService extends ChangeNotifier {
  static final ItemFindingService _instance = ItemFindingService._internal();
  factory ItemFindingService() => _instance;
  ItemFindingService._internal();

  final Random _random = Random();
  final List<ItemSpawn> _activeSpawns = [];
  Timer? _spawnTimer;
  Timer? _vibrationTimer;
  bool _isVibrating = false;
  
  // Configuration
  static const double _spawnRadius = 0.5; // 500 meters
  static const double _vibrationRadius = 0.1; // 100 meters
  static const int _maxSpawns = 5;
  static const Duration _spawnInterval = Duration(minutes: 10);
  static const Duration _vibrationInterval = Duration(seconds: 2);

  // Getters
  List<ItemSpawn> get activeSpawns => _activeSpawns;
  bool get isVibrating => _isVibrating;

  // Initialize the service
  void initialize() {
    debugPrint('[ItemFindingService] Initializing...');
    _startSpawnTimer();
    _startVibrationTimer();
  }

  // Start spawn timer
  void _startSpawnTimer() {
    _spawnTimer = Timer.periodic(_spawnInterval, (timer) {
      _spawnRandomItems();
    });
  }

  // Start vibration timer
  void _startVibrationTimer() {
    _vibrationTimer = Timer.periodic(_vibrationInterval, (timer) {
      _checkVibrationProximity();
    });
  }

  // Spawn random items around the player
  void _spawnRandomItems() async {
    try {
      final currentLocation = await _getCurrentLocation();
      if (currentLocation == null) return;

      // Remove old spawns
      _activeSpawns.removeWhere((spawn) => 
        DateTime.now().difference(spawn.spawnTime).inHours > 2);

      // Don't spawn if we have too many
      if (_activeSpawns.length >= _maxSpawns) return;

      // Random chance to spawn (30%)
      if (_random.nextDouble() > 0.3) return;

      // Generate random position within spawn radius
      final angle = _random.nextDouble() * 2 * pi;
      final distance = _random.nextDouble() * _spawnRadius;
      
      final spawnLat = currentLocation.latitude + (distance * cos(angle) / 111000);
      final spawnLng = currentLocation.longitude + (distance * sin(angle) / (111000 * cos(currentLocation.latitude * pi / 180)));

      // Generate random item
      final item = _generateRandomItem();
      
      final spawn = ItemSpawn(
        id: 'spawn_${DateTime.now().millisecondsSinceEpoch}',
        location: UserLocation(
          userId: 'item_spawn',
          latitude: spawnLat,
          longitude: spawnLng,
          accuracy: 0,
          timestamp: DateTime.now(),
        ),
        item: item,
        spawnTime: DateTime.now(),
        isCollected: false,
      );

      _activeSpawns.add(spawn);
      notifyListeners();
      
      debugPrint('[ItemFindingService] Spawned ${item.card.name} at $spawnLat, $spawnLng');
    } catch (e) {
      debugPrint('[ItemFindingService] Error spawning items: $e');
    }
  }

  // Check if player is close to any items for vibration
  void _checkVibrationProximity() async {
    try {
      final currentLocation = await _getCurrentLocation();
      if (currentLocation == null) return;

      bool shouldVibrate = false;
      
      for (final spawn in _activeSpawns) {
        if (spawn.isCollected) continue;
        
        final distance = Geolocator.distanceBetween(
          currentLocation.latitude,
          currentLocation.longitude,
          spawn.location.latitude,
          spawn.location.longitude,
        ) / 1000; // Convert to kilometers
        
        if (distance <= _vibrationRadius) {
          shouldVibrate = true;
          break;
        }
      }

      if (shouldVibrate && !_isVibrating) {
        _startVibration();
      } else if (!shouldVibrate && _isVibrating) {
        _stopVibration();
      }
    } catch (e) {
      debugPrint('[ItemFindingService] Error checking vibration proximity: $e');
    }
  }

  // Start vibration
  void _startVibration() {
    _isVibrating = true;
    notifyListeners();
    
    HapticFeedback.mediumImpact();
    
    // Continue vibration pattern
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_isVibrating) {
        timer.cancel();
        return;
      }
      HapticFeedback.mediumImpact();
    });
  }

  // Stop vibration
  void _stopVibration() {
    _isVibrating = false;
    notifyListeners();
  }

  // Collect an item
  Future<CardInstance?> collectItem(String spawnId) async {
    final spawn = _activeSpawns.firstWhere(
      (spawn) => spawn.id == spawnId,
      orElse: () => throw Exception('Spawn not found'),
    );

    if (spawn.isCollected) return null;

    // Mark as collected
    spawn.isCollected = true;
    _activeSpawns.remove(spawn);
    notifyListeners();

    // Stop vibration if no more items nearby
    _checkVibrationProximity();

    return spawn.item;
  }

  // Get current location
  Future<UserLocation?> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      return UserLocation(
        userId: 'player',
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[ItemFindingService] Error getting current location: $e');
      return null;
    }
  }

  // Generate random item
  CardInstance _generateRandomItem() {
    final items = [
      CardInstance(
        card: GameCard(
          name: 'Health Potion',
          description: 'Restores 50 health points',
          type: CardType.item,
          rarity: CardRarity.common,
        ),
      ),
      CardInstance(
        card: GameCard(
          name: 'Mana Potion',
          description: 'Restores 50 mana points',
          type: CardType.item,
          rarity: CardRarity.common,
        ),
      ),
      CardInstance(
        card: GameCard(
          name: 'Rare Herb',
          description: 'A valuable herb for crafting',
          type: CardType.item,
          rarity: CardRarity.uncommon,
        ),
      ),
      CardInstance(
        card: GameCard(
          name: 'Ancient Coin',
          description: 'An old coin with mysterious properties',
          type: CardType.item,
          rarity: CardRarity.rare,
        ),
      ),
      CardInstance(
        card: GameCard(
          name: 'Magic Crystal',
          description: 'A crystal that glows with magical energy',
          type: CardType.item,
          rarity: CardRarity.epic,
        ),
      ),
    ];

    // Weighted random selection based on rarity
    final weights = [0.5, 0.3, 0.15, 0.04, 0.01]; // Common, Uncommon, Rare, Epic, Legendary
    final random = _random.nextDouble();
    
    int index = 0;
    double cumulativeWeight = 0;
    
    for (int i = 0; i < weights.length; i++) {
      cumulativeWeight += weights[i];
      if (random <= cumulativeWeight) {
        index = i;
        break;
      }
    }

    return items[index];
  }

  // Dispose
  void dispose() {
    _spawnTimer?.cancel();
    _vibrationTimer?.cancel();
    super.dispose();
  }
}

class ItemSpawn {
  final String id;
  final UserLocation location;
  final CardInstance item;
  final DateTime spawnTime;
  bool isCollected;

  ItemSpawn({
    required this.id,
    required this.location,
    required this.item,
    required this.spawnTime,
    this.isCollected = false,
  });
} 