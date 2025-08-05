import 'dart:async';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/adventure_system.dart';
import '../services/enhanced_location_service.dart';
import '../services/weather_service.dart';
import 'dart:convert';

enum EnemyType {
  shadow,
  beast,
  elemental,
  undead,
  construct,
  dragon,
  guardian,
  trickster,
  merchant,
  scholar,
}

enum EnemyAggressionLevel {
  passive,
  neutral,
  aggressive,
  hostile,
  territorial,
}

enum EnemyBehaviorState {
  patrolling,
  alert,
  pursuing,
  fleeing,
  idle,
  guarding,
  trading,
  socializing,
}

enum EncounterType {
  battle,
  treasure,
  merchant,
  social,
  puzzle,
  information,
  challenge,
  blessing,
}

class EnemyData {
  final String id;
  final String name;
  final EnemyType type;
  final EnemyAggressionLevel aggressionLevel;
  final EnemyStrength strength;
  final List<Position> patrolRoute;
  final int pauseDuration;
  final double detectionRadius;
  final GeoLocation homeLocation;
  final POIType preferredLocation;
  final Map<String, dynamic> metadata;
  final List<String> possibleEncounters;
  final bool isLocationBound;
  final DateTime spawnedAt;
  final DateTime? despawnAt;

  EnemyData({
    required this.id,
    required this.name,
    required this.type,
    required this.aggressionLevel,
    required this.strength,
    required this.patrolRoute,
    this.pauseDuration = 3,
    this.detectionRadius = 100.0,
    required this.homeLocation,
    required this.preferredLocation,
    required this.metadata,
    required this.possibleEncounters,
    this.isLocationBound = true,
    required this.spawnedAt,
    this.despawnAt,
  });

  // Calculate distance from enemy to player
  double distanceToPlayer(GeoLocation playerLocation) {
    return homeLocation.distanceTo(playerLocation);
  }

  // Check if enemy should despawn
  bool shouldDespawn() {
    if (despawnAt != null && DateTime.now().isAfter(despawnAt!)) {
      return true;
    }
    return false;
  }
}

enum EnemyStrength {
  weak,
  normal,
  strong,
  elite,
  boss,
}

class EncounterData {
  final String id;
  final EncounterType type;
  final EnemyData enemy;
  final GeoLocation location;
  final String title;
  final String description;
  final List<String> actions;
  final Map<String, dynamic> rewards;
  final int difficulty;
  final bool isActive;
  final DateTime triggeredAt;

  EncounterData({
    required this.id,
    required this.type,
    required this.enemy,
    required this.location,
    required this.title,
    required this.description,
    required this.actions,
    required this.rewards,
    required this.difficulty,
    this.isActive = true,
    required this.triggeredAt,
  });
}

class EncounterService {
  static final EncounterService _instance = EncounterService._internal();
  factory EncounterService() => _instance;
  EncounterService._internal();

  final List<EnemyData> _activeEnemies = [];
  final List<EncounterData> _activeEncounters = [];
  final StreamController<EncounterData> _encounterController = StreamController.broadcast();
  final StreamController<EnemyData> _enemySpawnController = StreamController.broadcast();

  Timer? _spawnTimer;
  Timer? _cleanupTimer;
  final Random _random = Random();

  // Configuration
  final int maxEnemiesPerLocation = 3;
  final double enemySpawnRadius = 1000.0; // 1km
  final Duration enemyLifespan = Duration(hours: 2);
  final Duration spawnInterval = Duration(minutes: 5);

  // Streams
  Stream<EncounterData> get encounterStream => _encounterController.stream;
  Stream<EnemyData> get enemySpawnStream => _enemySpawnController.stream;

  // Getters
  List<EnemyData> get activeEnemies => _activeEnemies;
  List<EncounterData> get activeEncounters => _activeEncounters;

  // Initialize service
  Future<void> initialize() async {
    await _loadPersistentData();
    _startSpawnTimer();
    _startCleanupTimer();
    print('Encounter Service initialized');
  }

  // Start enemy spawning based on location
  void _startSpawnTimer() {
    _spawnTimer = Timer.periodic(spawnInterval, (timer) async {
      await _spawnLocationBasedEnemies();
    });
  }

  // Start cleanup timer for expired enemies
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(Duration(minutes: 10), (timer) {
      _cleanupExpiredEnemies();
    });
  }

  // Spawn enemies based on current location and nearby POIs
  Future<void> _spawnLocationBasedEnemies() async {
    final locationService = EnhancedLocationService();
    final currentLocation = locationService.currentLocation;
    
    if (currentLocation == null) return;

    try {
      // Discover nearby POIs to determine enemy spawn types
      final nearbyPOIs = await locationService.discoverNearbyPOIs(
        radius: enemySpawnRadius,
      );

      for (final poi in nearbyPOIs) {
        // Don't spawn too many enemies per location
        final existingEnemiesAtLocation = _activeEnemies
            .where((enemy) => enemy.homeLocation.distanceTo(poi.location) < 200)
            .length;

        if (existingEnemiesAtLocation >= maxEnemiesPerLocation) continue;

        // Determine if we should spawn an enemy based on POI type and time
        if (_shouldSpawnEnemyAtPOI(poi)) {
          final enemy = await _createLocationBasedEnemy(poi, currentLocation);
          if (enemy != null) {
            _activeEnemies.add(enemy);
            _enemySpawnController.add(enemy);
            print('Spawned ${enemy.name} at ${poi.name}');
          }
        }
      }

      await _savePersistentData();
    } catch (e) {
      print('Error spawning location-based enemies: $e');
    }
  }

  // Determine if enemy should spawn at POI
  bool _shouldSpawnEnemyAtPOI(PointOfInterest poi) {
    // Higher chance at locations with high quest potential
    final baseChance = poi.questPotential * 0.3; // 0-30% base chance
    
    // Time of day affects spawn rates
    final hour = DateTime.now().hour;
    double timeMultiplier = 1.0;
    
    if (hour >= 22 || hour <= 6) {
      timeMultiplier = 1.5; // More enemies at night
    } else if (hour >= 10 && hour <= 16) {
      timeMultiplier = 0.7; // Fewer enemies during busy day hours
    }

    // POI type affects spawn probability
    double typeMultiplier = 1.0;
    switch (poi.type) {
      case POIType.nature:
        typeMultiplier = 1.3; // Nature areas have more creatures
        break;
      case POIType.spiritual:
        typeMultiplier = 0.8; // Sacred places have fewer aggressive enemies
        break;
      case POIType.social:
        typeMultiplier = 0.6; // Social areas have fewer enemies
        break;
      case POIType.fitness:
        typeMultiplier = 1.1; // Gyms might have training dummies/constructs
        break;
      default:
        typeMultiplier = 1.0;
    }

    final finalChance = baseChance * timeMultiplier * typeMultiplier;
    return _random.nextDouble() < finalChance;
  }

  // Create enemy based on POI characteristics
  Future<EnemyData?> _createLocationBasedEnemy(PointOfInterest poi, GeoLocation playerLocation) async {
    try {
      final enemyType = _determineEnemyTypeForPOI(poi);
      final strength = _calculateEnemyStrength(poi);
      final aggressionLevel = _determineAggressionLevel(poi, enemyType);
      
      // Create patrol route around the POI
      final patrolRoute = _generatePatrolRoute(poi.location, 100.0);
      
      // Determine possible encounters
      final encounters = _generatePossibleEncounters(poi, enemyType);

      final enemy = EnemyData(
        id: 'enemy_${poi.id}_${DateTime.now().millisecondsSinceEpoch}',
        name: _generateEnemyName(enemyType, poi),
        type: enemyType,
        aggressionLevel: aggressionLevel,
        strength: strength,
        patrolRoute: patrolRoute,
        pauseDuration: _random.nextInt(5) + 2, // 2-6 seconds
        detectionRadius: _calculateDetectionRadius(strength),
        homeLocation: poi.location,
        preferredLocation: poi.type,
        metadata: {
          'poi_id': poi.id,
          'poi_name': poi.name,
          'poi_type': poi.type.toString(),
          'spawn_time': DateTime.now().toIso8601String(),
          'weather_spawned': await _getCurrentWeatherCondition(),
        },
        possibleEncounters: encounters,
        isLocationBound: true,
        spawnedAt: DateTime.now(),
        despawnAt: DateTime.now().add(enemyLifespan),
      );

      return enemy;
    } catch (e) {
      print('Error creating location-based enemy: $e');
      return null;
    }
  }

  // Determine enemy type based on POI
  EnemyType _determineEnemyTypeForPOI(PointOfInterest poi) {
    switch (poi.type) {
      case POIType.nature:
        // Nature areas spawn beasts and elementals
        return _random.nextBool() ? EnemyType.beast : EnemyType.elemental;
      
      case POIType.spiritual:
        // Churches and temples might have guardians or undead
        return _random.nextDouble() < 0.3 ? EnemyType.undead : EnemyType.guardian;
      
      case POIType.fitness:
        // Gyms have training constructs or guardians
        return _random.nextBool() ? EnemyType.construct : EnemyType.guardian;
      
      case POIType.education:
        // Libraries and schools have scholars or constructs
        return _random.nextBool() ? EnemyType.scholar : EnemyType.construct;
      
      case POIType.social:
        // Social areas have merchants or tricksters
        return _random.nextBool() ? EnemyType.merchant : EnemyType.trickster;
      
      case POIType.shopping:
        // Shopping areas have merchants
        return EnemyType.merchant;
      
      case POIType.medical:
        // Hospitals have guardians (protecting) or constructs
        return _random.nextBool() ? EnemyType.guardian : EnemyType.construct;
      
      case POIType.entertainment:
        // Entertainment venues have tricksters or merchants
        return _random.nextBool() ? EnemyType.trickster : EnemyType.merchant;
      
      default:
        // Generic locations have shadows or beasts
        return _random.nextBool() ? EnemyType.shadow : EnemyType.beast;
    }
  }

  // Calculate enemy strength based on POI rating and popularity
  EnemyStrength _calculateEnemyStrength(PointOfInterest poi) {
    double strengthScore = 0.0;
    
    // Rating affects strength
    strengthScore += (poi.rating / 5.0) * 2.0; // 0-2 points
    
    // Quest potential affects strength
    strengthScore += poi.questPotential * 2.0; // 0-2 points
    
    // Random factor
    strengthScore += _random.nextDouble(); // 0-1 points
    
    if (strengthScore >= 4.5) return EnemyStrength.boss;
    if (strengthScore >= 3.5) return EnemyStrength.elite;
    if (strengthScore >= 2.5) return EnemyStrength.strong;
    if (strengthScore >= 1.5) return EnemyStrength.normal;
    return EnemyStrength.weak;
  }

  // Determine aggression level
  EnemyAggressionLevel _determineAggressionLevel(PointOfInterest poi, EnemyType type) {
    // Base aggression by type
    Map<EnemyType, EnemyAggressionLevel> baseAggression = {
      EnemyType.shadow: EnemyAggressionLevel.neutral,
      EnemyType.beast: EnemyAggressionLevel.aggressive,
      EnemyType.elemental: EnemyAggressionLevel.neutral,
      EnemyType.undead: EnemyAggressionLevel.hostile,
      EnemyType.construct: EnemyAggressionLevel.neutral,
      EnemyType.dragon: EnemyAggressionLevel.territorial,
      EnemyType.guardian: EnemyAggressionLevel.territorial,
      EnemyType.trickster: EnemyAggressionLevel.passive,
      EnemyType.merchant: EnemyAggressionLevel.passive,
      EnemyType.scholar: EnemyAggressionLevel.passive,
    };

    // Modify based on POI type
    EnemyAggressionLevel aggression = baseAggression[type] ?? EnemyAggressionLevel.neutral;
    
    switch (poi.type) {
      case POIType.spiritual:
        // Sacred places have more peaceful enemies
        if (aggression == EnemyAggressionLevel.hostile) {
          aggression = EnemyAggressionLevel.aggressive;
        } else if (aggression == EnemyAggressionLevel.aggressive) {
          aggression = EnemyAggressionLevel.neutral;
        }
        break;
      
      case POIType.social:
        // Social areas have less aggressive enemies
        if (aggression == EnemyAggressionLevel.hostile) {
          aggression = EnemyAggressionLevel.neutral;
        } else if (aggression == EnemyAggressionLevel.aggressive) {
          aggression = EnemyAggressionLevel.passive;
        }
        break;
      
      case POIType.nature:
        // Wild areas might be more dangerous
        if (aggression == EnemyAggressionLevel.passive) {
          aggression = EnemyAggressionLevel.neutral;
        }
        break;
      
      default:
        break;
    }

    return aggression;
  }

  // Generate patrol route around location
  List<Position> _generatePatrolRoute(GeoLocation center, double radiusMeters) {
    final route = <Position>[];
    final pointCount = 3 + _random.nextInt(3); // 3-5 patrol points
    
    for (int i = 0; i < pointCount; i++) {
      final angle = (i / pointCount) * 2 * math.pi;
      final distance = radiusMeters * (0.5 + _random.nextDouble() * 0.5); // 50-100% of radius
      
      final lat = center.latitude! + (distance * math.cos(angle)) / 111000;
      final lng = center.longitude! + (distance * math.sin(angle)) / (111000 * math.cos(center.latitude! * math.pi / 180));
      
      route.add(Position.fromMap({
        'latitude': lat,
        'longitude': lng,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'accuracy': 10.0,
        'altitude': center.altitude ?? 0.0,
        'heading': 0.0,
        'speed': 0.0,
        'speedAccuracy': 0.0,
      }));
    }
    
    return route;
  }

  // Calculate detection radius based on strength
  double _calculateDetectionRadius(EnemyStrength strength) {
    switch (strength) {
      case EnemyStrength.weak:
        return 50.0;
      case EnemyStrength.normal:
        return 75.0;
      case EnemyStrength.strong:
        return 100.0;
      case EnemyStrength.elite:
        return 125.0;
      case EnemyStrength.boss:
        return 150.0;
    }
  }

  // Generate enemy name
  String _generateEnemyName(EnemyType type, PointOfInterest poi) {
    final locationName = poi.name.split(' ').first;
    
    switch (type) {
      case EnemyType.shadow:
        return 'Shadow of $locationName';
      case EnemyType.beast:
        return '$locationName Guardian Beast';
      case EnemyType.elemental:
        return '$locationName Elemental';
      case EnemyType.undead:
        return 'Restless Spirit of $locationName';
      case EnemyType.construct:
        return '$locationName Sentinel';
      case EnemyType.dragon:
        return 'Dragon of $locationName';
      case EnemyType.guardian:
        return 'Guardian of $locationName';
      case EnemyType.trickster:
        return '$locationName Trickster';
      case EnemyType.merchant:
        return '$locationName Merchant';
      case EnemyType.scholar:
        return '$locationName Scholar';
    }
  }

  // Generate possible encounters
  List<String> _generatePossibleEncounters(PointOfInterest poi, EnemyType type) {
    final encounters = <String>[];
    
    // Base encounters by type
    switch (type) {
      case EnemyType.shadow:
        encounters.addAll(['battle', 'stealth_challenge', 'riddle']);
        break;
      case EnemyType.beast:
        encounters.addAll(['battle', 'taming_challenge', 'nature_wisdom']);
        break;
      case EnemyType.elemental:
        encounters.addAll(['battle', 'elemental_harmony', 'weather_blessing']);
        break;
      case EnemyType.undead:
        encounters.addAll(['battle', 'spirit_communication', 'blessing_ritual']);
        break;
      case EnemyType.construct:
        encounters.addAll(['battle', 'puzzle_challenge', 'repair_quest']);
        break;
      case EnemyType.dragon:
        encounters.addAll(['battle', 'treasure_negotiation', 'ancient_wisdom']);
        break;
      case EnemyType.guardian:
        encounters.addAll(['test_of_worth', 'protection_blessing', 'wisdom_sharing']);
        break;
      case EnemyType.trickster:
        encounters.addAll(['riddle_game', 'illusion_challenge', 'trade_game']);
        break;
      case EnemyType.merchant:
        encounters.addAll(['trading', 'information_exchange', 'quest_offering']);
        break;
      case EnemyType.scholar:
        encounters.addAll(['knowledge_sharing', 'research_assistance', 'ancient_lore']);
        break;
    }

    // Add POI-specific encounters
    switch (poi.type) {
      case POIType.fitness:
        encounters.addAll(['training_challenge', 'strength_test']);
        break;
      case POIType.social:
        encounters.addAll(['social_challenge', 'networking_game']);
        break;
      case POIType.spiritual:
        encounters.addAll(['meditation_challenge', 'spiritual_guidance']);
        break;
      case POIType.nature:
        encounters.addAll(['nature_challenge', 'environmental_puzzle']);
        break;
      case POIType.education:
        encounters.addAll(['knowledge_test', 'research_collaboration']);
        break;
      default:
        break;
    }

    return encounters;
  }

  // Get current weather condition
  Future<String> _getCurrentWeatherCondition() async {
    try {
      final weatherService = WeatherService();
      final weather = await weatherService.getCurrentWeather();
      return weather?.condition ?? 'clear';
    } catch (e) {
      return 'unknown';
    }
  }

  // Trigger encounter with enemy
  Future<EncounterData?> triggerEncounter(EnemyData enemy, GeoLocation playerLocation) async {
    if (enemy.possibleEncounters.isEmpty) return null;

    try {
      final encounterType = _selectEncounterType(enemy);
      final encounter = _createEncounter(enemy, playerLocation, encounterType);
      
      _activeEncounters.add(encounter);
      _encounterController.add(encounter);
      
      print('Triggered ${encounter.type} encounter with ${enemy.name}');
      return encounter;
    } catch (e) {
      print('Error triggering encounter: $e');
      return null;
    }
  }

  // Select encounter type based on enemy and situation
  EncounterType _selectEncounterType(EnemyData enemy) {
    // Select random encounter from possible types
    final possibleTypes = enemy.possibleEncounters;
    final selectedType = possibleTypes[_random.nextInt(possibleTypes.length)];
    
    switch (selectedType) {
      case 'battle':
        return EncounterType.battle;
      case 'trading':
        return EncounterType.merchant;
      case 'riddle':
      case 'puzzle_challenge':
        return EncounterType.puzzle;
      case 'knowledge_sharing':
      case 'information_exchange':
        return EncounterType.information;
      case 'social_challenge':
      case 'networking_game':
        return EncounterType.social;
      case 'blessing_ritual':
      case 'protection_blessing':
        return EncounterType.blessing;
      case 'training_challenge':
      case 'strength_test':
        return EncounterType.challenge;
      default:
        return EncounterType.battle;
    }
  }

  // Create encounter
  EncounterData _createEncounter(EnemyData enemy, GeoLocation playerLocation, EncounterType type) {
    final title = _generateEncounterTitle(enemy, type);
    final description = _generateEncounterDescription(enemy, type);
    final actions = _generateEncounterActions(enemy, type);
    final rewards = _generateEncounterRewards(enemy, type);
    final difficulty = _calculateEncounterDifficulty(enemy);

    return EncounterData(
      id: 'encounter_${enemy.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      enemy: enemy,
      location: playerLocation,
      title: title,
      description: description,
      actions: actions,
      rewards: rewards,
      difficulty: difficulty,
      triggeredAt: DateTime.now(),
    );
  }

  // Generate encounter title
  String _generateEncounterTitle(EnemyData enemy, EncounterType type) {
    switch (type) {
      case EncounterType.battle:
        return 'Battle with ${enemy.name}';
      case EncounterType.merchant:
        return 'Trading Opportunity with ${enemy.name}';
      case EncounterType.puzzle:
        return 'Puzzle from ${enemy.name}';
      case EncounterType.information:
        return 'Knowledge Exchange with ${enemy.name}';
      case EncounterType.social:
        return 'Social Challenge from ${enemy.name}';
      case EncounterType.blessing:
        return 'Blessing from ${enemy.name}';
      case EncounterType.challenge:
        return 'Challenge from ${enemy.name}';
      case EncounterType.treasure:
        return 'Treasure Guarded by ${enemy.name}';
    }
  }

  // Generate encounter description
  String _generateEncounterDescription(EnemyData enemy, EncounterType type) {
    final locationName = enemy.metadata['poi_name'] ?? 'this location';
    
    switch (type) {
      case EncounterType.battle:
        return 'The ${enemy.name} blocks your path at $locationName. '
            'You must prove your worth in combat to proceed!';
      
      case EncounterType.merchant:
        return 'The ${enemy.name} offers to trade valuable items. '
            'What treasures might they have for exchange?';
      
      case EncounterType.puzzle:
        return 'The ${enemy.name} presents you with an ancient riddle. '
            'Solve it to earn their respect and rewards!';
      
      case EncounterType.information:
        return 'The ${enemy.name} possesses knowledge of this area. '
            'They\'re willing to share secrets for the right price.';
      
      case EncounterType.social:
        return 'The ${enemy.name} challenges you to a social game. '
            'Can you outwit them and earn their favor?';
      
      case EncounterType.blessing:
        return 'The ${enemy.name} offers to bestow a blessing upon you. '
            'Accept their gift to gain temporary powers!';
      
      case EncounterType.challenge:
        return 'The ${enemy.name} tests your abilities with a physical challenge. '
            'Prove your strength and earn valuable rewards!';
      
      case EncounterType.treasure:
        return 'The ${enemy.name} guards a hidden treasure at $locationName. '
            'Will you attempt to claim it?';
    }
  }

  // Generate encounter actions
  List<String> _generateEncounterActions(EnemyData enemy, EncounterType type) {
    switch (type) {
      case EncounterType.battle:
        return ['Fight', 'Flee', 'Negotiate'];
      case EncounterType.merchant:
        return ['Trade', 'Browse Wares', 'Leave'];
      case EncounterType.puzzle:
        return ['Solve Riddle', 'Ask for Hint', 'Give Up'];
      case EncounterType.information:
        return ['Ask Questions', 'Offer Payment', 'Leave'];
      case EncounterType.social:
        return ['Accept Challenge', 'Decline', 'Negotiate Terms'];
      case EncounterType.blessing:
        return ['Accept Blessing', 'Decline', 'Ask Price'];
      case EncounterType.challenge:
        return ['Accept Challenge', 'Decline', 'Ask for Training'];
      case EncounterType.treasure:
        return ['Attempt to Take', 'Negotiate', 'Leave Peacefully'];
    }
  }

  // Generate encounter rewards
  Map<String, dynamic> _generateEncounterRewards(EnemyData enemy, EncounterType type) {
    final rewards = <String, dynamic>{};
    
    // Base rewards by enemy strength
    int baseXP = 50;
    int baseGold = 25;
    
    switch (enemy.strength) {
      case EnemyStrength.weak:
        baseXP = 50;
        baseGold = 25;
        break;
      case EnemyStrength.normal:
        baseXP = 100;
        baseGold = 50;
        break;
      case EnemyStrength.strong:
        baseXP = 200;
        baseGold = 100;
        break;
      case EnemyStrength.elite:
        baseXP = 350;
        baseGold = 175;
        break;
      case EnemyStrength.boss:
        baseXP = 500;
        baseGold = 250;
        break;
    }

    rewards['experience'] = baseXP;
    rewards['gold'] = baseGold;

    // Type-specific rewards
    switch (type) {
      case EncounterType.battle:
        rewards['battle_tokens'] = 1;
        break;
      case EncounterType.merchant:
        rewards['trade_goods'] = ['random_item'];
        break;
      case EncounterType.puzzle:
        rewards['wisdom_points'] = 1;
        break;
      case EncounterType.information:
        rewards['knowledge_fragments'] = 1;
        break;
      case EncounterType.social:
        rewards['social_influence'] = 1;
        break;
      case EncounterType.blessing:
        rewards['temporary_blessing'] = 'random_blessing';
        break;
      case EncounterType.challenge:
        rewards['fitness_points'] = 1;
        break;
      case EncounterType.treasure:
        rewards['treasure_items'] = ['rare_item'];
        break;
    }

    return rewards;
  }

  // Calculate encounter difficulty
  int _calculateEncounterDifficulty(EnemyData enemy) {
    switch (enemy.strength) {
      case EnemyStrength.weak:
        return 1;
      case EnemyStrength.normal:
        return 2;
      case EnemyStrength.strong:
        return 3;
      case EnemyStrength.elite:
        return 4;
      case EnemyStrength.boss:
        return 5;
    }
  }

  // Cleanup expired enemies
  void _cleanupExpiredEnemies() {
    final now = DateTime.now();
    final expiredEnemies = _activeEnemies.where((enemy) => enemy.shouldDespawn()).toList();
    
    for (final enemy in expiredEnemies) {
      _activeEnemies.remove(enemy);
      print('Despawned expired enemy: ${enemy.name}');
    }

    // Also cleanup old encounters
    _activeEncounters.removeWhere((encounter) => 
        now.difference(encounter.triggeredAt).inHours > 1);
  }

  // Get enemies near location
  List<EnemyData> getEnemiesNearLocation(GeoLocation location, {double radiusMeters = 500.0}) {
    return _activeEnemies.where((enemy) {
      final distance = enemy.homeLocation.distanceTo(location);
      return distance <= radiusMeters;
    }).toList();
  }

  // Check if player is near any enemy
  EnemyData? checkPlayerNearEnemies(GeoLocation playerLocation, {double threshold = 100.0}) {
    for (final enemy in _activeEnemies) {
      final distance = enemy.distanceToPlayer(playerLocation);
      if (distance <= enemy.detectionRadius && distance <= threshold) {
        return enemy;
      }
    }
    return null;
  }

  // Save persistent data
  Future<void> _savePersistentData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enemyData = _activeEnemies.map((enemy) => {
        'id': enemy.id,
        'name': enemy.name,
        'type': enemy.type.toString(),
        'aggressionLevel': enemy.aggressionLevel.toString(),
        'strength': enemy.strength.toString(),
        'homeLocation': enemy.homeLocation.toJson(),
        'preferredLocation': enemy.preferredLocation.toString(),
        'metadata': enemy.metadata,
        'possibleEncounters': enemy.possibleEncounters,
        'spawnedAt': enemy.spawnedAt.toIso8601String(),
        'despawnAt': enemy.despawnAt?.toIso8601String(),
      }).toList();

      await prefs.setString('active_enemies', json.encode(enemyData));
    } catch (e) {
      print('Error saving persistent enemy data: $e');
    }
  }

  // Load persistent data
  Future<void> _loadPersistentData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enemyDataString = prefs.getString('active_enemies');
      
      if (enemyDataString != null) {
        final enemyDataList = json.decode(enemyDataString) as List;
        final now = DateTime.now();
        
        for (final enemyJson in enemyDataList) {
          final spawnedAt = DateTime.parse(enemyJson['spawnedAt']);
          final despawnAt = enemyJson['despawnAt'] != null 
              ? DateTime.parse(enemyJson['despawnAt']) 
              : null;
          
          // Only restore enemies that haven't expired
          if (despawnAt == null || now.isBefore(despawnAt)) {
            // Note: This is a simplified restoration - in a full implementation
            // you'd need to properly reconstruct the patrol routes and other complex data
            print('Restored enemy: ${enemyJson['name']}');
          }
        }
      }
    } catch (e) {
      print('Error loading persistent enemy data: $e');
    }
  }

  // Dispose service
  void dispose() {
    _spawnTimer?.cancel();
    _cleanupTimer?.cancel();
    _encounterController.close();
    _enemySpawnController.close();
  }
} 