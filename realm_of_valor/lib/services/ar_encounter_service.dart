import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/adventure_system.dart';

enum AREncounterType {
  creature_battle,
  treasure_hunt,
  portal_discovery,
  magical_gathering,
  boss_encounter,
  environmental_puzzle,
  companion_interaction,
}

enum ARInteractionType {
  tap_to_attack,
  gesture_spell,
  movement_dodge,
  voice_command,
  device_tilt,
  camera_scan,
  proximity_trigger,
}

enum AREnvironmentType {
  urban,
  park,
  forest,
  water,
  indoor,
  landmark,
  open_field,
}

class ARCreature {
  final String id;
  final String name;
  final String description;
  final String modelPath;
  final String texturePath;
  final List<String> animationPaths;
  final int health;
  final int attackPower;
  final double scale;
  final List<ARInteractionType> supportedInteractions;
  final Map<String, dynamic> behaviors;
  final AREnvironmentType preferredEnvironment;
  final String rarity;
  final List<String> soundEffects;

  ARCreature({
    required this.id,
    required this.name,
    required this.description,
    required this.modelPath,
    required this.texturePath,
    required this.animationPaths,
    required this.health,
    required this.attackPower,
    required this.scale,
    required this.supportedInteractions,
    required this.behaviors,
    required this.preferredEnvironment,
    required this.rarity,
    required this.soundEffects,
  });

  factory ARCreature.fromJson(Map<String, dynamic> json) {
    return ARCreature(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      modelPath: json['modelPath'],
      texturePath: json['texturePath'],
      animationPaths: List<String>.from(json['animationPaths'] ?? []),
      health: json['health'] ?? 100,
      attackPower: json['attackPower'] ?? 10,
      scale: json['scale']?.toDouble() ?? 1.0,
      supportedInteractions: (json['supportedInteractions'] as List?)
          ?.map((index) => ARInteractionType.values[index])
          .toList() ?? [],
      behaviors: Map<String, dynamic>.from(json['behaviors'] ?? {}),
      preferredEnvironment: AREnvironmentType.values[json['preferredEnvironment'] ?? 0],
      rarity: json['rarity'] ?? 'common',
      soundEffects: List<String>.from(json['soundEffects'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'modelPath': modelPath,
      'texturePath': texturePath,
      'animationPaths': animationPaths,
      'health': health,
      'attackPower': attackPower,
      'scale': scale,
      'supportedInteractions': supportedInteractions.map((interaction) => interaction.index).toList(),
      'behaviors': behaviors,
      'preferredEnvironment': preferredEnvironment.index,
      'rarity': rarity,
      'soundEffects': soundEffects,
    };
  }
}

class AREncounter {
  final String id;
  final AREncounterType type;
  final ARCreature? creature;
  final GeoLocation location;
  final DateTime spawnTime;
  final DateTime? expiresAt;
  final Map<String, dynamic> environmentData;
  final List<ARInteractionType> requiredInteractions;
  final Map<String, dynamic> rewards;
  final int difficulty;
  final bool isActive;
  final Map<String, dynamic> arParameters;
  final String? questId;

  AREncounter({
    required this.id,
    required this.type,
    this.creature,
    required this.location,
    required this.spawnTime,
    this.expiresAt,
    required this.environmentData,
    required this.requiredInteractions,
    required this.rewards,
    required this.difficulty,
    this.isActive = true,
    required this.arParameters,
    this.questId,
  });

  factory AREncounter.fromJson(Map<String, dynamic> json) {
    return AREncounter(
      id: json['id'],
      type: AREncounterType.values[json['type'] ?? 0],
      creature: json['creature'] != null 
          ? ARCreature.fromJson(json['creature'])
          : null,
      location: GeoLocation.fromJson(json['location']),
      spawnTime: DateTime.parse(json['spawnTime']),
      expiresAt: json['expiresAt'] != null 
          ? DateTime.parse(json['expiresAt'])
          : null,
      environmentData: Map<String, dynamic>.from(json['environmentData'] ?? {}),
      requiredInteractions: (json['requiredInteractions'] as List?)
          ?.map((index) => ARInteractionType.values[index])
          .toList() ?? [],
      rewards: Map<String, dynamic>.from(json['rewards'] ?? {}),
      difficulty: json['difficulty'] ?? 1,
      isActive: json['isActive'] ?? true,
      arParameters: Map<String, dynamic>.from(json['arParameters'] ?? {}),
      questId: json['questId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'creature': creature?.toJson(),
      'location': location.toJson(),
      'spawnTime': spawnTime.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'environmentData': environmentData,
      'requiredInteractions': requiredInteractions.map((interaction) => interaction.index).toList(),
      'rewards': rewards,
      'difficulty': difficulty,
      'isActive': isActive,
      'arParameters': arParameters,
      'questId': questId,
    };
  }

  bool get isExpired {
    return expiresAt != null && DateTime.now().isAfter(expiresAt!);
  }

  double get timeRemaining {
    if (expiresAt == null) return double.infinity;
    final remaining = expiresAt!.difference(DateTime.now()).inSeconds.toDouble();
    return math.max(0.0, remaining);
  }
}

class ARSession {
  final String id;
  final AREncounter encounter;
  final DateTime startTime;
  final Map<ARInteractionType, int> interactionCounts;
  final List<Map<String, dynamic>> playerActions;
  final Map<String, dynamic> sessionState;
  final bool isCompleted;
  final Map<String, dynamic>? results;

  ARSession({
    required this.id,
    required this.encounter,
    required this.startTime,
    Map<ARInteractionType, int>? interactionCounts,
    List<Map<String, dynamic>>? playerActions,
    Map<String, dynamic>? sessionState,
    this.isCompleted = false,
    this.results,
  }) : interactionCounts = interactionCounts ?? {},
       playerActions = playerActions ?? [],
       sessionState = sessionState ?? {};

  ARSession copyWith({
    Map<ARInteractionType, int>? interactionCounts,
    List<Map<String, dynamic>>? playerActions,
    Map<String, dynamic>? sessionState,
    bool? isCompleted,
    Map<String, dynamic>? results,
  }) {
    return ARSession(
      id: id,
      encounter: encounter,
      startTime: startTime,
      interactionCounts: interactionCounts ?? this.interactionCounts,
      playerActions: playerActions ?? this.playerActions,
      sessionState: sessionState ?? this.sessionState,
      isCompleted: isCompleted ?? this.isCompleted,
      results: results ?? this.results,
    );
  }

  Duration get sessionDuration => DateTime.now().difference(startTime);
}

class AREncounterService {
  static final AREncounterService _instance = AREncounterService._internal();
  factory AREncounterService() => _instance;
  AREncounterService._internal();

  final StreamController<List<AREncounter>> _encountersController = StreamController.broadcast();
  final StreamController<AREncounter> _newEncounterController = StreamController.broadcast();
  final StreamController<ARSession?> _sessionController = StreamController.broadcast();

  Stream<List<AREncounter>> get encountersStream => _encountersController.stream;
  Stream<AREncounter> get newEncounterStream => _newEncounterController.stream;
  Stream<ARSession?> get sessionStream => _sessionController.stream;

  List<AREncounter> _activeEncounters = [];
  List<ARCreature> _availableCreatures = [];
  ARSession? _currentSession;
  String? _playerId;
  bool _isARSupported = false;
  Timer? _spawnTimer;

  // Initialize AR service
  Future<void> initialize(String playerId) async {
    _playerId = playerId;
    await _checkARSupport();
    await _loadEncounterData();
    _initializeCreatures();
    _startSpawnTimer();
    
    _encountersController.add(_activeEncounters);
  }

  // Check if AR is supported on device
  Future<void> _checkARSupport() async {
    try {
      // This would check ARCore/ARKit availability
      _isARSupported = true; // Mock implementation
      print('AR Support: $_isARSupported');
    } catch (e) {
      _isARSupported = false;
      print('AR not supported: $e');
    }
  }

  // Get AR support status
  bool get isARSupported => _isARSupported;

  // Spawn AR encounter at location
  Future<AREncounter?> spawnEncounter({
    required GeoLocation location,
    AREncounterType? preferredType,
    int? difficulty,
    String? questId,
  }) async {
    if (!_isARSupported) return null;

    final encounterType = preferredType ?? _getRandomEncounterType();
    final environment = _detectEnvironmentType(location);
    final encounterDifficulty = difficulty ?? _calculateDynamicDifficulty();

    final encounter = await _createEncounter(
      type: encounterType,
      location: location,
      environment: environment,
      difficulty: encounterDifficulty,
      questId: questId,
    );

    if (encounter != null) {
      _activeEncounters.add(encounter);
      await _saveEncounterData();
      
      _encountersController.add(_activeEncounters);
      _newEncounterController.add(encounter);
    }

    return encounter;
  }

  // Start AR session for encounter
  Future<ARSession?> startARSession(String encounterId) async {
    if (!_isARSupported) return null;

    final encounter = _activeEncounters.firstWhere(
      (enc) => enc.id == encounterId,
      orElse: () => throw Exception('Encounter not found'),
    );

    if (encounter.isExpired || !encounter.isActive) {
      return null;
    }

    _currentSession = ARSession(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
      encounter: encounter,
      startTime: DateTime.now(),
      sessionState: {
        'player_health': 100,
        'creature_health': encounter.creature?.health ?? 100,
        'phase': 'introduction',
        'score': 0,
      },
    );

    _sessionController.add(_currentSession);
    return _currentSession;
  }

  // Process AR interaction during session
  Future<Map<String, dynamic>?> processARInteraction({
    required ARInteractionType interactionType,
    required Map<String, dynamic> interactionData,
  }) async {
    if (_currentSession == null || _currentSession!.isCompleted) {
      return null;
    }

    final session = _currentSession!;
    final encounter = session.encounter;

    // Update interaction counts
    final updatedCounts = Map<ARInteractionType, int>.from(session.interactionCounts);
    updatedCounts[interactionType] = (updatedCounts[interactionType] ?? 0) + 1;

    // Record player action
    final action = {
      'type': interactionType.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'data': interactionData,
    };

    final updatedActions = List<Map<String, dynamic>>.from(session.playerActions)
      ..add(action);

    // Process interaction based on type and encounter
    final interactionResult = _processInteractionLogic(
      interactionType,
      interactionData,
      session,
    );

    // Update session state
    final updatedState = Map<String, dynamic>.from(session.sessionState);
    updatedState.addAll(interactionResult['stateChanges'] ?? {});

    // Check for session completion
    final isCompleted = _checkSessionCompletion(updatedState, encounter);
    Map<String, dynamic>? results;

    if (isCompleted) {
      results = _calculateSessionResults(session, updatedState);
      await _completeEncounter(encounter.id, results);
    }

    _currentSession = session.copyWith(
      interactionCounts: updatedCounts,
      playerActions: updatedActions,
      sessionState: updatedState,
      isCompleted: isCompleted,
      results: results,
    );

    _sessionController.add(_currentSession);

    return {
      'success': interactionResult['success'] ?? false,
      'damage': interactionResult['damage'] ?? 0,
      'effect': interactionResult['effect'],
      'feedback': interactionResult['feedback'],
      'sessionState': updatedState,
      'isCompleted': isCompleted,
      'results': results,
    };
  }

  // Get nearby AR encounters
  List<AREncounter> getNearbyEncounters(GeoLocation location, {double radius = 100}) {
    return _activeEncounters.where((encounter) {
      if (!encounter.isActive || encounter.isExpired) return false;
      final distance = location.distanceTo(encounter.location);
      return distance <= radius;
    }).toList();
  }

  // Get encounters by type
  List<AREncounter> getEncountersByType(AREncounterType type) {
    return _activeEncounters.where((encounter) => 
        encounter.type == type && encounter.isActive && !encounter.isExpired
    ).toList();
  }

  // End current AR session
  Future<void> endARSession({bool completed = false}) async {
    if (_currentSession == null) return;

    if (!completed && !_currentSession!.isCompleted) {
      // Save session progress for later resume
      await _saveSessionProgress(_currentSession!);
    }

    _currentSession = null;
    _sessionController.add(null);
  }

  // Get AR creature models
  List<ARCreature> getAvailableCreatures({AREnvironmentType? environment}) {
    if (environment == null) return _availableCreatures;
    
    return _availableCreatures.where((creature) => 
        creature.preferredEnvironment == environment
    ).toList();
  }

  // Create custom AR encounter for quest
  Future<AREncounter?> createQuestEncounter({
    required String questId,
    required GeoLocation location,
    required AREncounterType type,
    Map<String, dynamic>? customParameters,
  }) async {
    return await spawnEncounter(
      location: location,
      preferredType: type,
      questId: questId,
    );
  }

  // Get AR session statistics
  Map<String, dynamic> getARStatistics() {
    final completedEncounters = _activeEncounters.where((enc) => !enc.isActive).length;
    final totalSpawned = _activeEncounters.length;
    
    return {
      'total_encounters': totalSpawned,
      'completed_encounters': completedEncounters,
      'active_encounters': _activeEncounters.where((enc) => enc.isActive).length,
      'ar_supported': _isARSupported,
      'average_session_duration': _calculateAverageSessionDuration(),
      'most_common_interaction': _getMostCommonInteraction(),
    };
  }

  // Private helper methods
  Future<AREncounter?> _createEncounter({
    required AREncounterType type,
    required GeoLocation location,
    required AREnvironmentType environment,
    required int difficulty,
    String? questId,
  }) async {
    final creature = _selectCreatureForEncounter(type, environment, difficulty);
    if (creature == null && type == AREncounterType.creature_battle) return null;

    final encounterId = 'ar_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}';
    
    return AREncounter(
      id: encounterId,
      type: type,
      creature: creature,
      location: location,
      spawnTime: DateTime.now(),
      expiresAt: DateTime.now().add(_getEncounterDuration(type)),
      environmentData: _generateEnvironmentData(environment, location),
      requiredInteractions: _getRequiredInteractions(type, difficulty),
      rewards: _generateEncounterRewards(type, difficulty),
      difficulty: difficulty,
      arParameters: _generateARParameters(type, environment, difficulty),
      questId: questId,
    );
  }

  ARCreature? _selectCreatureForEncounter(
    AREncounterType type, 
    AREnvironmentType environment, 
    int difficulty,
  ) {
    if (type != AREncounterType.creature_battle && type != AREncounterType.boss_encounter) {
      return null;
    }

    final suitableCreatures = _availableCreatures.where((creature) =>
        creature.preferredEnvironment == environment &&
        _getCreatureDifficulty(creature) <= difficulty
    ).toList();

    if (suitableCreatures.isEmpty) return null;

    return suitableCreatures[math.Random().nextInt(suitableCreatures.length)];
  }

  AREncounterType _getRandomEncounterType() {
    final types = AREncounterType.values;
    return types[math.Random().nextInt(types.length)];
  }

  AREnvironmentType _detectEnvironmentType(GeoLocation location) {
    // This would use location services and mapping data to detect environment
    // For now, return a random environment
    final environments = AREnvironmentType.values;
    return environments[math.Random().nextInt(environments.length)];
  }

  int _calculateDynamicDifficulty() {
    // This would integrate with the dynamic difficulty service
    return 1 + math.Random().nextInt(5); // 1-5 difficulty range
  }

  Map<String, dynamic> _generateEnvironmentData(AREnvironmentType environment, GeoLocation location) {
    return {
      'environment_type': environment.toString(),
      'lighting_conditions': _detectLightingConditions(),
      'surface_detection': true,
      'occlusion_enabled': environment != AREnvironmentType.open_field,
      'recommended_distance': _getRecommendedViewingDistance(environment),
    };
  }

  List<ARInteractionType> _getRequiredInteractions(AREncounterType type, int difficulty) {
    switch (type) {
      case AREncounterType.creature_battle:
        return [ARInteractionType.tap_to_attack, ARInteractionType.movement_dodge];
      case AREncounterType.treasure_hunt:
        return [ARInteractionType.camera_scan, ARInteractionType.tap_to_attack];
      case AREncounterType.portal_discovery:
        return [ARInteractionType.proximity_trigger, ARInteractionType.gesture_spell];
      case AREncounterType.magical_gathering:
        return [ARInteractionType.gesture_spell, ARInteractionType.device_tilt];
      case AREncounterType.boss_encounter:
        return [
          ARInteractionType.tap_to_attack,
          ARInteractionType.movement_dodge,
          ARInteractionType.gesture_spell,
        ];
      case AREncounterType.environmental_puzzle:
        return [ARInteractionType.camera_scan, ARInteractionType.device_tilt];
      case AREncounterType.companion_interaction:
        return [ARInteractionType.voice_command, ARInteractionType.gesture_spell];
    }
  }

  Map<String, dynamic> _generateEncounterRewards(AREncounterType type, int difficulty) {
    final baseXP = 50 * difficulty;
    final baseCards = difficulty;

    return {
      'xp': baseXP,
      'cards': baseCards,
      'gold': 25 * difficulty,
      'special_items': type == AREncounterType.boss_encounter ? ['legendary_shard'] : [],
    };
  }

  Map<String, dynamic> _generateARParameters(
    AREncounterType type, 
    AREnvironmentType environment, 
    int difficulty,
  ) {
    return {
      'spawn_animation': 'fade_in',
      'interaction_radius': 2.0 + (difficulty * 0.5),
      'model_scale': 0.5 + (difficulty * 0.1),
      'particle_effects': type == AREncounterType.boss_encounter,
      'sound_enabled': true,
      'haptic_feedback': true,
      'movement_speed': 1.0 + (difficulty * 0.2),
    };
  }

  Duration _getEncounterDuration(AREncounterType type) {
    switch (type) {
      case AREncounterType.creature_battle:
        return const Duration(minutes: 15);
      case AREncounterType.treasure_hunt:
        return const Duration(minutes: 20);
      case AREncounterType.portal_discovery:
        return const Duration(minutes: 10);
      case AREncounterType.magical_gathering:
        return const Duration(minutes: 30);
      case AREncounterType.boss_encounter:
        return const Duration(hours: 1);
      case AREncounterType.environmental_puzzle:
        return const Duration(minutes: 25);
      case AREncounterType.companion_interaction:
        return const Duration(minutes: 5);
    }
  }

  Map<String, dynamic> _processInteractionLogic(
    ARInteractionType interactionType,
    Map<String, dynamic> interactionData,
    ARSession session,
  ) {
    final encounter = session.encounter;
    final creature = encounter.creature;
    final sessionState = session.sessionState;

    switch (interactionType) {
      case ARInteractionType.tap_to_attack:
        return _processTapAttack(interactionData, creature, sessionState);
      case ARInteractionType.gesture_spell:
        return _processGestureSpell(interactionData, creature, sessionState);
      case ARInteractionType.movement_dodge:
        return _processMovementDodge(interactionData, creature, sessionState);
      case ARInteractionType.voice_command:
        return _processVoiceCommand(interactionData, creature, sessionState);
      case ARInteractionType.device_tilt:
        return _processDeviceTilt(interactionData, creature, sessionState);
      case ARInteractionType.camera_scan:
        return _processCameraScan(interactionData, encounter, sessionState);
      case ARInteractionType.proximity_trigger:
        return _processProximityTrigger(interactionData, encounter, sessionState);
    }
  }

  Map<String, dynamic> _processTapAttack(
    Map<String, dynamic> data, 
    ARCreature? creature, 
    Map<String, dynamic> state,
  ) {
    final accuracy = data['accuracy'] ?? 0.8;
    final damage = (10 * accuracy).round();
    final currentCreatureHealth = state['creature_health'] ?? 100;
    final newCreatureHealth = math.max(0, currentCreatureHealth - damage);

    return {
      'success': accuracy > 0.5,
      'damage': damage,
      'effect': 'damage_dealt',
      'feedback': accuracy > 0.8 ? 'Critical hit!' : 'Hit!',
      'stateChanges': {'creature_health': newCreatureHealth},
    };
  }

  Map<String, dynamic> _processGestureSpell(
    Map<String, dynamic> data, 
    ARCreature? creature, 
    Map<String, dynamic> state,
  ) {
    final gestureAccuracy = data['gesture_accuracy'] ?? 0.5;
    final spellPower = (15 * gestureAccuracy).round();

    return {
      'success': gestureAccuracy > 0.6,
      'damage': spellPower,
      'effect': 'spell_cast',
      'feedback': gestureAccuracy > 0.8 ? 'Perfect spell!' : 'Spell cast!',
      'stateChanges': {
        'creature_health': math.max(0, (state['creature_health'] ?? 100) - spellPower),
        'score': (state['score'] ?? 0) + (spellPower * 2),
      },
    };
  }

  Map<String, dynamic> _processMovementDodge(
    Map<String, dynamic> data, 
    ARCreature? creature, 
    Map<String, dynamic> state,
  ) {
    final dodgeSuccess = data['dodge_success'] ?? false;
    final playerHealth = state['player_health'] ?? 100;

    return {
      'success': dodgeSuccess,
      'damage': 0,
      'effect': dodgeSuccess ? 'dodge_success' : 'dodge_failed',
      'feedback': dodgeSuccess ? 'Perfect dodge!' : 'Hit taken!',
      'stateChanges': {
        'player_health': dodgeSuccess ? playerHealth : math.max(0, playerHealth - 15),
      },
    };
  }

  Map<String, dynamic> _processVoiceCommand(
    Map<String, dynamic> data, 
    ARCreature? creature, 
    Map<String, dynamic> state,
  ) {
    final commandRecognized = data['command_recognized'] ?? false;
    
    return {
      'success': commandRecognized,
      'damage': 0,
      'effect': 'voice_interaction',
      'feedback': commandRecognized ? 'Command understood!' : 'Try again!',
      'stateChanges': {
        'score': (state['score'] ?? 0) + (commandRecognized ? 10 : 0),
      },
    };
  }

  Map<String, dynamic> _processDeviceTilt(
    Map<String, dynamic> data, 
    ARCreature? creature, 
    Map<String, dynamic> state,
  ) {
    final tiltAngle = data['tilt_angle'] ?? 0.0;
    final correctTilt = (tiltAngle.abs() - 45.0).abs() < 10.0;

    return {
      'success': correctTilt,
      'damage': 0,
      'effect': 'device_interaction',
      'feedback': correctTilt ? 'Perfect angle!' : 'Adjust your device!',
      'stateChanges': {
        'score': (state['score'] ?? 0) + (correctTilt ? 5 : 0),
      },
    };
  }

  Map<String, dynamic> _processCameraScan(
    Map<String, dynamic> data, 
    AREncounter encounter, 
    Map<String, dynamic> state,
  ) {
    final objectDetected = data['object_detected'] ?? false;
    
    return {
      'success': objectDetected,
      'damage': 0,
      'effect': 'scan_complete',
      'feedback': objectDetected ? 'Object found!' : 'Keep scanning!',
      'stateChanges': {
        'scan_progress': math.min(100, (state['scan_progress'] ?? 0) + 25),
        'score': (state['score'] ?? 0) + (objectDetected ? 15 : 0),
      },
    };
  }

  Map<String, dynamic> _processProximityTrigger(
    Map<String, dynamic> data, 
    AREncounter encounter, 
    Map<String, dynamic> state,
  ) {
    final inRange = data['in_range'] ?? false;
    
    return {
      'success': inRange,
      'damage': 0,
      'effect': 'proximity_activated',
      'feedback': inRange ? 'Portal activated!' : 'Get closer!',
      'stateChanges': {
        'portal_progress': math.min(100, (state['portal_progress'] ?? 0) + 20),
      },
    };
  }

  bool _checkSessionCompletion(Map<String, dynamic> state, AREncounter encounter) {
    switch (encounter.type) {
      case AREncounterType.creature_battle:
      case AREncounterType.boss_encounter:
        return (state['creature_health'] ?? 100) <= 0 || (state['player_health'] ?? 100) <= 0;
      case AREncounterType.treasure_hunt:
        return (state['scan_progress'] ?? 0) >= 100;
      case AREncounterType.portal_discovery:
        return (state['portal_progress'] ?? 0) >= 100;
      case AREncounterType.magical_gathering:
        return (state['score'] ?? 0) >= 100;
      case AREncounterType.environmental_puzzle:
        return state['puzzle_solved'] ?? false;
      case AREncounterType.companion_interaction:
        return state['interaction_complete'] ?? false;
    }
  }

  Map<String, dynamic> _calculateSessionResults(ARSession session, Map<String, dynamic> finalState) {
    final playerWon = (finalState['creature_health'] ?? 100) <= 0 && 
                     (finalState['player_health'] ?? 100) > 0;
    final score = finalState['score'] ?? 0;
    final duration = session.sessionDuration.inSeconds;

    return {
      'victory': playerWon,
      'score': score,
      'duration_seconds': duration,
      'performance_rating': _calculatePerformanceRating(session, finalState),
      'rewards_earned': playerWon ? session.encounter.rewards : {},
      'experience_gained': playerWon ? (session.encounter.rewards['xp'] ?? 0) : 0,
    };
  }

  double _calculatePerformanceRating(ARSession session, Map<String, dynamic> finalState) {
    final duration = session.sessionDuration.inSeconds;
    final score = finalState['score'] ?? 0;
    final playerHealth = finalState['player_health'] ?? 100;
    
    // Calculate rating based on multiple factors
    var rating = 0.0;
    rating += (score / 100) * 40; // Score contribution (40%)
    rating += (playerHealth / 100) * 30; // Health remaining (30%)
    rating += math.max(0, (180 - duration) / 180) * 30; // Speed bonus (30%)
    
    return rating.clamp(0.0, 100.0);
  }

  Future<void> _completeEncounter(String encounterId, Map<String, dynamic> results) async {
    final index = _activeEncounters.indexWhere((enc) => enc.id == encounterId);
    if (index != -1) {
      final encounter = _activeEncounters[index];
      final completedEncounter = AREncounter(
        id: encounter.id,
        type: encounter.type,
        creature: encounter.creature,
        location: encounter.location,
        spawnTime: encounter.spawnTime,
        expiresAt: encounter.expiresAt,
        environmentData: encounter.environmentData,
        requiredInteractions: encounter.requiredInteractions,
        rewards: encounter.rewards,
        difficulty: encounter.difficulty,
        isActive: false,
        arParameters: encounter.arParameters,
        questId: encounter.questId,
      );
      
      _activeEncounters[index] = completedEncounter;
      await _saveEncounterData();
      _encountersController.add(_activeEncounters);
    }
  }

  void _initializeCreatures() {
    _availableCreatures = [
      ARCreature(
        id: 'fire_sprite',
        name: 'Fire Sprite',
        description: 'A magical creature of flame and light',
        modelPath: 'models/fire_sprite.glb',
        texturePath: 'textures/fire_sprite.png',
        animationPaths: ['animations/fire_idle.anim', 'animations/fire_attack.anim'],
        health: 80,
        attackPower: 15,
        scale: 0.8,
        supportedInteractions: [ARInteractionType.tap_to_attack, ARInteractionType.gesture_spell],
        behaviors: {'aggressive': true, 'flee_threshold': 20},
        preferredEnvironment: AREnvironmentType.open_field,
        rarity: 'uncommon',
        soundEffects: ['fire_crackle.wav', 'fire_attack.wav'],
      ),
      ARCreature(
        id: 'water_guardian',
        name: 'Water Guardian',
        description: 'Ancient protector of water sources',
        modelPath: 'models/water_guardian.glb',
        texturePath: 'textures/water_guardian.png',
        animationPaths: ['animations/water_idle.anim', 'animations/water_heal.anim'],
        health: 120,
        attackPower: 10,
        scale: 1.2,
        supportedInteractions: [ARInteractionType.movement_dodge, ARInteractionType.voice_command],
        behaviors: {'defensive': true, 'heal_rate': 5},
        preferredEnvironment: AREnvironmentType.water,
        rarity: 'rare',
        soundEffects: ['water_flow.wav', 'water_splash.wav'],
      ),
      // Add more creatures...
    ];
  }

  String _detectLightingConditions() {
    // This would use device sensors to detect lighting
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour <= 18) return 'daylight';
    if (hour >= 19 && hour <= 21) return 'twilight';
    return 'night';
  }

  double _getRecommendedViewingDistance(AREnvironmentType environment) {
    switch (environment) {
      case AREnvironmentType.indoor:
        return 1.5;
      case AREnvironmentType.urban:
        return 2.0;
      case AREnvironmentType.park:
      case AREnvironmentType.forest:
        return 3.0;
      case AREnvironmentType.open_field:
        return 4.0;
      default:
        return 2.5;
    }
  }

  int _getCreatureDifficulty(ARCreature creature) {
    return (creature.health + creature.attackPower) ~/ 20;
  }

  double _calculateAverageSessionDuration() {
    // This would calculate from stored session data
    return 120.0; // 2 minutes average
  }

  String _getMostCommonInteraction() {
    // This would analyze stored interaction data
    return 'tap_to_attack';
  }

  void _startSpawnTimer() {
    _spawnTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      _cleanupExpiredEncounters();
    });
  }

  void _cleanupExpiredEncounters() {
    _activeEncounters.removeWhere((encounter) => encounter.isExpired);
    _encountersController.add(_activeEncounters);
  }

  Future<void> _saveSessionProgress(ARSession session) async {
    // Save session for later resume
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ar_session_${session.id}', jsonEncode({
      'session_data': session.sessionState,
      'encounter_id': session.encounter.id,
      'start_time': session.startTime.toIso8601String(),
    }));
  }

  // Data persistence
  Future<void> _saveEncounterData() async {
    if (_playerId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final encountersJson = jsonEncode(_activeEncounters.map((enc) => enc.toJson()).toList());
      await prefs.setString('ar_encounters_$_playerId', encountersJson);
    } catch (e) {
      print('Error saving AR encounter data: $e');
    }
  }

  Future<void> _loadEncounterData() async {
    if (_playerId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final encountersJson = prefs.getString('ar_encounters_$_playerId');

      if (encountersJson != null) {
        final encountersList = jsonDecode(encountersJson) as List;
        _activeEncounters = encountersList
            .map((json) => AREncounter.fromJson(json))
            .where((encounter) => !encounter.isExpired)
            .toList();
      }
    } catch (e) {
      print('Error loading AR encounter data: $e');
    }
  }

  // Cleanup
  void dispose() {
    _encountersController.close();
    _newEncounterController.close();
    _sessionController.close();
    _spawnTimer?.cancel();
  }
}