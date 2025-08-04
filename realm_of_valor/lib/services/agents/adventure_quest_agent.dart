import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/event_bus.dart';
import '../../models/quest_model.dart' as quest_model;
import '../../models/adventure_system.dart' as adventure_system;
import '../../services/enhanced_location_service.dart';
import 'integration_orchestrator_agent.dart';

/// Adventure state tracking
enum AdventureState {
  available,
  active,
  completed,
  failed,
  locked,
}

/// AR interaction types
enum ARInteractionType {
  cardScan,
  objectDetection,
  locationMarker,
  virtualBattle,
  treasureHunt,
  puzzleGame,
}

/// Adventure instance with user progress
class AdventureInstance {
  final String id;
  final String userId;
  final String questId;
  final AdventureState state;
  final DateTime startTime;
  final DateTime? completionTime;
  final Map<String, dynamic> progressData;
  final List<String> completedObjectives;
  final List<String> visitedWaypoints;
  final double completionPercentage;

  AdventureInstance({
    required this.id,
    required this.userId,
    required this.questId,
    this.state = AdventureState.available,
    DateTime? startTime,
    this.completionTime,
    Map<String, dynamic>? progressData,
    List<String>? completedObjectives,
    List<String>? visitedWaypoints,
    this.completionPercentage = 0.0,
  }) : startTime = startTime ?? DateTime.now(),
       progressData = progressData ?? {},
       completedObjectives = completedObjectives ?? [],
       visitedWaypoints = visitedWaypoints ?? [];

  AdventureInstance copyWith({
    String? id,
    String? userId,
    String? questId,
    AdventureState? state,
    DateTime? startTime,
    DateTime? completionTime,
    Map<String, dynamic>? progressData,
    List<String>? completedObjectives,
    List<String>? visitedWaypoints,
    double? completionPercentage,
  }) {
    return AdventureInstance(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      questId: questId ?? this.questId,
      state: state ?? this.state,
      startTime: startTime ?? this.startTime,
      completionTime: completionTime ?? this.completionTime,
      progressData: progressData ?? Map.from(this.progressData),
      completedObjectives: completedObjectives ?? List.from(this.completedObjectives),
      visitedWaypoints: visitedWaypoints ?? List.from(this.visitedWaypoints),
      completionPercentage: completionPercentage ?? this.completionPercentage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'questId': questId,
      'state': state.toString(),
      'startTime': startTime.toIso8601String(),
      'completionTime': completionTime?.toIso8601String(),
      'progressData': progressData,
      'completedObjectives': completedObjectives,
      'visitedWaypoints': visitedWaypoints,
      'completionPercentage': completionPercentage,
    };
  }

  factory AdventureInstance.fromJson(Map<String, dynamic> json) {
    return AdventureInstance(
      id: json['id'],
      userId: json['userId'],
      questId: json['questId'],
      state: AdventureState.values.firstWhere(
        (s) => s.toString() == json['state'],
        orElse: () => AdventureState.available,
      ),
      startTime: DateTime.parse(json['startTime']),
      completionTime: json['completionTime'] != null ? DateTime.parse(json['completionTime']) : null,
      progressData: Map<String, dynamic>.from(json['progressData'] ?? {}),
      completedObjectives: List<String>.from(json['completedObjectives'] ?? []),
      visitedWaypoints: List<String>.from(json['visitedWaypoints'] ?? []),
      completionPercentage: (json['completionPercentage'] ?? 0.0).toDouble(),
    );
  }
}

/// AR experience configuration
class ARExperience {
  final String id;
  final String name;
  final String description;
  final ARInteractionType type;
  final GeoLocation? location;
  final double? triggerRadius;
  final Map<String, dynamic> config;
  final List<String> requiredItems;
  final Map<String, dynamic> rewards;

  ARExperience({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.location,
    this.triggerRadius,
    Map<String, dynamic>? config,
    List<String>? requiredItems,
    Map<String, dynamic>? rewards,
  }) : config = config ?? {},
       requiredItems = requiredItems ?? [],
       rewards = rewards ?? {};
}

/// POI (Point of Interest) for location-based quests
class PointOfInterest {
  final String id;
  final String name;
  final String description;
  final GeoLocation location;
  final String category;
  final List<String> tags;
  final Map<String, dynamic> properties;
  final List<ARExperience> arExperiences;
  final bool isActive;

  PointOfInterest({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.category,
    List<String>? tags,
    Map<String, dynamic>? properties,
    List<ARExperience>? arExperiences,
    this.isActive = true,
  }) : tags = tags ?? [],
       properties = properties ?? {},
       arExperiences = arExperiences ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location.toJson(),
      'category': category,
      'tags': tags,
      'properties': properties,
      'isActive': isActive,
    };
  }

  factory PointOfInterest.fromJson(Map<String, dynamic> json) {
    return PointOfInterest(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      location: GeoLocation.fromJson(json['location']),
      category: json['category'],
      tags: List<String>.from(json['tags'] ?? []),
      properties: Map<String, dynamic>.from(json['properties'] ?? {}),
      isActive: json['isActive'] ?? true,
    );
  }
}

/// Adventure Quest Agent - AI-Powered Quest Generation & World State Management
class AdventureQuestAgent extends BaseAgent {
  static const String _agentTypeId = 'adventure_quest';

  // Dependencies
  final SharedPreferences _prefs;
  final EnhancedLocationService? _locationService;

  // Current user context
  String? _currentUserId;
  GeoLocation? _currentLocation;

  // Quest Management
  final List<quest_model.Quest> _activeQuests = [];
  final Map<String, quest_model.Quest> _availableQuests = {};
  final Map<String, AdventureInstance> _activeAdventures = {}; // instanceId -> adventure
  final Map<String, List<String>> _userActiveQuests = {}; // userId -> List<instanceId>
  final Map<String, List<String>> _userCompletedQuests = {}; // userId -> List<questId>

  // Location and POI management
  final Map<String, PointOfInterest> _pointsOfInterest = {};
  final List<GeofenceRegion> _activeGeofences = [];

  // AR experiences
  final Map<String, ARExperience> _arExperiences = {};
  final Map<String, List<String>> _locationARMapping = {}; // locationId -> List<arExperienceId>

  // Real-time tracking
  StreamSubscription<Position>? _locationSubscription;
  Timer? _questProgressTimer;
  final List<Map<String, dynamic>> _recentActivities = [];

  AdventureQuestAgent({
    required SharedPreferences prefs,
    EnhancedLocationService? locationService,
    }) : _prefs = prefs,
        _locationService = locationService,
        super(agentId: _agentTypeId);

  @override
  Future<void> onInitialize() async {
    developer.log('Initializing Adventure & Quest Agent', name: _agentTypeId);

    // Load quest database
    await _loadQuestDatabase();

    // Initialize POIs and AR experiences
    await _initializePointsOfInterest();
    await _initializeARExperiences();

    // Load user adventure data
    await _loadUserAdventureData();

    // Start location tracking if service available
    if (_locationService != null) {
      await _initializeLocationTracking();
    }

    // Start quest progress monitoring
    _startQuestProgressMonitoring();

    developer.log('Adventure & Quest Agent initialized with ${_availableQuests.length} quests and ${_pointsOfInterest.length} POIs', name: _agentTypeId);
  }

  @override
  void subscribeToEvents() {
    // Quest management events
    subscribe('start_quest', _handleStartQuest);
    subscribe('complete_quest', _handleCompleteQuest);
    subscribe('abandon_quest', _handleAbandonQuest);
    subscribe('get_available_quests', _handleGetAvailableQuests);
    subscribe('get_active_quests', _handleGetActiveQuests);
    subscribe('get_quest_progress', _handleGetQuestProgress);

    // Location-based events
    subscribe('location_update', _handleLocationUpdate);
    subscribe('poi_detected', _handlePOIDetected);
    subscribe('geofence_entered', _handleGeofenceEntered);
    subscribe('geofence_exited', _handleGeofenceExited);

    // AR experience events
    subscribe('trigger_ar_experience', _handleTriggerARExperience);
    subscribe('complete_ar_interaction', _handleCompleteARInteraction);

    // Adventure progression events
    subscribe('update_quest_objective', _handleUpdateQuestObjective);
    subscribe('check_quest_completion', _handleCheckQuestCompletion);

    // Fitness integration events
    subscribe(EventTypes.fitnessUpdate, _handleFitnessUpdate);
    subscribe(EventTypes.locationUpdate, _handleLocationUpdate);

    // Battle integration events
    subscribe(EventTypes.battleResult, _handleBattleResult);

    // Card integration events
    subscribe(EventTypes.cardScanned, _handleCardScanned);

    // User management
    subscribe('user_login', _handleUserLogin);
    subscribe('user_logout', _handleUserLogout);

    // Data persistence
    subscribe('save_adventure_data', _handleSaveAdventureData);
    subscribe('load_adventure_data', _handleLoadAdventureData);
  }

  /// Start a quest for a user
  Future<AdventureInstance?> startQuest(String userId, String questId) async {
    final quest = _availableQuests[questId];
    if (quest == null) {
      developer.log('Quest not found: $questId', name: _agentTypeId);
      return null;
    }

    // Check prerequisites
    if (!_checkQuestPrerequisites(userId, quest)) {
      developer.log('Quest prerequisites not met for user $userId: $questId', name: _agentTypeId);
      return null;
    }

    // Create adventure instance
    final instanceId = 'adventure_${DateTime.now().millisecondsSinceEpoch}';
    final adventure = AdventureInstance(
      id: instanceId,
      userId: userId,
      questId: questId,
      state: AdventureState.active,
    );

    _activeAdventures[instanceId] = adventure;
    _userActiveQuests.putIfAbsent(userId, () => []).add(instanceId);

    // Set up geofences for location-based objectives
    if (quest.location != null) {
      _setupQuestGeofences(adventure, quest);
    }

    // Publish quest started event
    await publishEvent(createEvent(
      eventType: EventTypes.questStarted,
      data: {
        'userId': userId,
        'questId': questId,
        'instanceId': instanceId,
        'questType': quest.type.toString(),
        'difficulty': quest.difficulty.toString(),
      },
      priority: EventPriority.high,
    ));

    _logActivity('quest_started', {
      'userId': userId,
      'questId': questId,
      'instanceId': instanceId,
    });

    await _saveUserAdventureData(userId);
    return adventure;
  }

  /// Complete a quest
  Future<bool> completeQuest(String userId, String instanceId) async {
    final adventure = _activeAdventures[instanceId];
    if (adventure == null || adventure.userId != userId) {
      return false;
    }

    final quest = _availableQuests[adventure.questId];
    if (quest == null) return false;

    // Check if all objectives are completed
    if (!_isQuestComplete(adventure, quest)) {
      developer.log('Quest not yet complete: ${adventure.questId}', name: _agentTypeId);
      return false;
    }

    // Mark as completed
    final completedAdventure = adventure.copyWith(
      state: AdventureState.completed,
      completionTime: DateTime.now(),
      completionPercentage: 100.0,
    );

    _activeAdventures[instanceId] = completedAdventure;
    _userActiveQuests[userId]?.remove(instanceId);
    _userCompletedQuests.putIfAbsent(userId, () => []).add(adventure.questId);

    // Remove quest-specific geofences
    _removeQuestGeofences(adventure);

    // Distribute rewards
    await _distributeQuestRewards(userId, quest, completedAdventure);

    // Publish quest completed event
    await publishEvent(createEvent(
      eventType: EventTypes.questCompleted,
      data: {
        'userId': userId,
        'questId': adventure.questId,
        'instanceId': instanceId,
        'completionTime': completedAdventure.completionTime!.toIso8601String(),
        'experienceReward': quest.experienceReward,
        'goldReward': quest.goldReward,
      },
      priority: EventPriority.high,
    ));

    _logActivity('quest_completed', {
      'userId': userId,
      'questId': adventure.questId,
      'instanceId': instanceId,
      'experienceReward': quest.experienceReward,
    });

    await _saveUserAdventureData(userId);
    return true;
  }

  /// Update quest objective progress
  Future<void> updateQuestObjective(String userId, String objectiveType, dynamic value) async {
    final userActiveQuests = _userActiveQuests[userId] ?? [];
    
    for (final instanceId in userActiveQuests) {
      final adventure = _activeAdventures[instanceId];
      if (adventure == null) continue;

      final quest = _availableQuests[adventure.questId];
      if (quest == null) continue;

      bool updated = false;
      final newProgressData = Map<String, dynamic>.from(adventure.progressData);

      // Update objectives based on type
      for (final objective in quest.objectives) {
        if (objective.type == objectiveType && !objective.isCompleted) {
          final currentValue = newProgressData[objective.id] ?? 0;
          final newValue = _calculateNewObjectiveValue(objective, currentValue, value);
          newProgressData[objective.id] = newValue;

          if (newValue >= objective.targetValue) {
            newProgressData['${objective.id}_completed'] = true;
            updated = true;
          }
        }
      }

      if (updated) {
        // Calculate overall progress
        final completionPercentage = _calculateQuestProgress(quest, newProgressData);
        
        final updatedAdventure = adventure.copyWith(
          progressData: newProgressData,
          completionPercentage: completionPercentage,
        );

        _activeAdventures[instanceId] = updatedAdventure;

        // Check if quest is now complete
        if (_isQuestComplete(updatedAdventure, quest)) {
          await completeQuest(userId, instanceId);
        } else {
          // Publish progress update
          await publishEvent(createEvent(
            eventType: EventTypes.questProgress,
            data: {
              'userId': userId,
              'questId': adventure.questId,
              'instanceId': instanceId,
              'objectiveType': objectiveType,
              'progress': completionPercentage,
            },
          ));
        }
      }
    }

    await _saveUserAdventureData(userId);
  }

  /// Trigger AR experience
  Future<Map<String, dynamic>?> triggerARExperience(String userId, String experienceId, {Map<String, dynamic>? context}) async {
    final experience = _arExperiences[experienceId];
    if (experience == null) return null;

    // Check if user is in correct location (if required)
    if (experience.location != null && _currentLocation != null) {
      final distance = experience.location!.distanceTo(_currentLocation!);
      if (experience.triggerRadius != null && distance > experience.triggerRadius!) {
        developer.log('User too far from AR experience location: $experienceId', name: _agentTypeId);
        return null;
      }
    }

    // Process AR experience based on type
    final result = await _processARExperience(userId, experience, context);

    // Publish AR experience event
    await publishEvent(createEvent(
      eventType: EventTypes.arExperienceTriggered,
      data: {
        'userId': userId,
        'experienceId': experienceId,
        'type': experience.type.toString(),
        'location': _currentLocation?.toJson(),
        'result': result,
      },
    ));

    _logActivity('ar_experience', {
      'userId': userId,
      'experienceId': experienceId,
      'type': experience.type.toString(),
    });

    return result;
  }

  /// Process AR experience based on type
  Future<Map<String, dynamic>> _processARExperience(String userId, ARExperience experience, Map<String, dynamic>? context) async {
    switch (experience.type) {
      case ARInteractionType.cardScan:
        return _processCardScanAR(userId, experience, context);
      case ARInteractionType.virtualBattle:
        return _processVirtualBattleAR(userId, experience, context);
      case ARInteractionType.treasureHunt:
        return _processTreasureHuntAR(userId, experience, context);
      case ARInteractionType.puzzleGame:
        return _processPuzzleGameAR(userId, experience, context);
      case ARInteractionType.locationMarker:
        return _processLocationMarkerAR(userId, experience, context);
      case ARInteractionType.objectDetection:
        return _processObjectDetectionAR(userId, experience, context);
      default:
        return {'success': false, 'error': 'Unknown AR experience type'};
    }
  }

  /// Process card scan AR experience
  Future<Map<String, dynamic>> _processCardScanAR(String userId, ARExperience experience, Map<String, dynamic>? context) async {
    // This would integrate with the Card System Agent for QR scanning
    await publishEvent(createEvent(
      eventType: 'scan_qr_card',
      targetAgent: 'card_system',
      data: {
        'userId': userId,
        'source': 'ar_experience',
        'experienceId': experience.id,
      },
    ));

    return {
      'success': true,
      'type': 'card_scan',
      'message': 'QR scan interface activated',
      'rewards': experience.rewards,
    };
  }

  /// Process virtual battle AR experience
  Future<Map<String, dynamic>> _processVirtualBattleAR(String userId, ARExperience experience, Map<String, dynamic>? context) async {
    // This would integrate with the Battle System Agent
    await publishEvent(createEvent(
      eventType: 'start_ar_battle',
      targetAgent: 'battle_system',
      data: {
        'userId': userId,
        'battleType': 'ar_encounter',
        'location': _currentLocation?.toJson(),
        'experienceId': experience.id,
      },
    ));

    return {
      'success': true,
      'type': 'virtual_battle',
      'message': 'AR battle initiated',
      'battleConfig': experience.config,
    };
  }

  /// Process treasure hunt AR experience
  Future<Map<String, dynamic>> _processTreasureHuntAR(String userId, ARExperience experience, Map<String, dynamic>? context) async {
    final random = math.Random();
    final foundTreasure = random.nextBool();

    if (foundTreasure) {
      // Distribute treasure rewards
      await publishEvent(createEvent(
        eventType: 'inventory_reward',
        targetAgent: 'card_system',
        data: {
          'userId': userId,
          'cards': experience.rewards['cards'] ?? [],
          'gold': experience.rewards['gold'] ?? 50,
          'source': 'ar_treasure_hunt',
        },
      ));

      await updateQuestObjective(userId, 'treasure_found', 1);
    }

    return {
      'success': true,
      'type': 'treasure_hunt',
      'found': foundTreasure,
      'message': foundTreasure ? 'Treasure discovered!' : 'Keep searching...',
      'rewards': foundTreasure ? experience.rewards : {},
    };
  }

  /// Process puzzle game AR experience
  Future<Map<String, dynamic>> _processPuzzleGameAR(String userId, ARExperience experience, Map<String, dynamic>? context) async {
    final difficulty = experience.config['difficulty'] ?? 'medium';
    final solutionProvided = context?['solution'] != null;
    final correctSolution = experience.config['solution'];

    final success = solutionProvided && context!['solution'] == correctSolution;

    if (success) {
      await updateQuestObjective(userId, 'puzzle_solved', 1);
      
      // Award intelligence bonus
      await publishEvent(createEvent(
        eventType: 'character_reward',
        targetAgent: 'character_management',
        data: {
          'userId': userId,
          'statBonus': {'intelligence': 2},
          'source': 'ar_puzzle',
        },
      ));
    }

    return {
      'success': success,
      'type': 'puzzle_game',
      'difficulty': difficulty,
      'message': success ? 'Puzzle solved!' : 'Try again...',
      'rewards': success ? experience.rewards : {},
    };
  }

  /// Process location marker AR experience
  Future<Map<String, dynamic>> _processLocationMarkerAR(String userId, ARExperience experience, Map<String, dynamic>? context) async {
    await updateQuestObjective(userId, 'location_visited', 1);

    return {
      'success': true,
      'type': 'location_marker',
      'message': 'Location discovered!',
      'locationInfo': experience.config['locationInfo'] ?? {},
      'rewards': experience.rewards,
    };
  }

  /// Process object detection AR experience
  Future<Map<String, dynamic>> _processObjectDetectionAR(String userId, ARExperience experience, Map<String, dynamic>? context) async {
    final detectedObject = context?['detectedObject'];
    final expectedObject = experience.config['expectedObject'];

    final success = detectedObject == expectedObject;

    if (success) {
      await updateQuestObjective(userId, 'object_detected', 1);
    }

    return {
      'success': success,
      'type': 'object_detection',
      'detected': detectedObject,
      'expected': expectedObject,
      'message': success ? 'Object found!' : 'Keep looking...',
      'rewards': success ? experience.rewards : {},
    };
  }

  /// Load quest database
  Future<void> _loadQuestDatabase() async {
    // Load default quests
    final defaultQuests = quest_model.Quest.getDefaultQuests();
    for (final quest in defaultQuests) {
      _availableQuests[quest.id] = quest;
    }

    // Add location-based quests
    _availableQuests.addAll(_createLocationBasedQuests());

    // Add AR experience quests
    _availableQuests.addAll(_createARExperienceQuests());

    developer.log('Loaded ${_availableQuests.length} quests', name: _agentTypeId);
  }

  /// Create location-based quests
  Map<String, quest_model.Quest> _createLocationBasedQuests() {
    return {
      'city_explorer': quest_model.Quest(
        name: 'City Explorer',
        description: 'Visit 3 historical landmarks in your city',
        story: 'The city holds ancient secrets. Visit the marked locations to uncover the hidden history.',
        type: quest_model.QuestType.exploration,
        difficulty: quest_model.QuestDifficulty.medium,
        objectives: [
          quest_model.QuestObjective(
            description: 'Visit historical landmark 1',
            type: 'location_visited',
            targetValue: 1,
          ),
          quest_model.QuestObjective(
            description: 'Visit historical landmark 2',
            type: 'location_visited',
            targetValue: 1,
          ),
          quest_model.QuestObjective(
            description: 'Visit historical landmark 3',
            type: 'location_visited',
            targetValue: 1,
          ),
        ],
        rewards: [
          quest_model.QuestReward(
            type: 'card',
            name: 'Explorer\'s Compass',
            value: 1,
            cardId: 'explorers_compass',
          ),
        ],
        experienceReward: 400,
        goldReward: 150,
      ),
      'park_ranger': quest_model.Quest(
        name: 'Park Ranger',
        description: 'Walk through 5 different parks and discover nature',
        story: 'The natural world is calling. Become one with nature by exploring local parks.',
        type: quest_model.QuestType.exploration,
        difficulty: quest_model.QuestDifficulty.easy,
        objectives: [
          quest_model.QuestObjective(
            description: 'Visit 5 different parks',
            type: 'park_visited',
            targetValue: 5,
          ),
          quest_model.QuestObjective(
            description: 'Walk 3 miles total',
            type: 'distance',
            targetValue: 4828, // meters
          ),
        ],
        rewards: [
          quest_model.QuestReward(
            type: 'stat_boost',
            name: 'Nature\'s Blessing',
            value: 3,
          ),
        ],
        experienceReward: 250,
        goldReward: 100,
      ),
    };
  }

  /// Create AR experience quests
  Map<String, quest_model.Quest> _createARExperienceQuests() {
    return {
      'ar_treasure_hunter': quest_model.Quest(
        name: 'AR Treasure Hunter',
        description: 'Use AR to find 3 hidden treasures around the city',
        story: 'Ancient treasures are hidden in plain sight. Use your AR vision to uncover them.',
        type: quest_model.QuestType.exploration,
        difficulty: quest_model.QuestDifficulty.hard,
        objectives: [
          quest_model.QuestObjective(
            description: 'Find AR treasure 1',
            type: 'treasure_found',
            targetValue: 1,
          ),
          quest_model.QuestObjective(
            description: 'Find AR treasure 2',
            type: 'treasure_found',
            targetValue: 1,
          ),
          quest_model.QuestObjective(
            description: 'Find AR treasure 3',
            type: 'treasure_found',
            targetValue: 1,
          ),
        ],
        rewards: [
          quest_model.QuestReward(
            type: 'card',
            name: 'Treasure Hunter\'s Map',
            value: 1,
            cardId: 'treasure_map',
          ),
        ],
        experienceReward: 600,
        goldReward: 300,
      ),
      'ar_puzzle_master': quest_model.Quest(
        name: 'AR Puzzle Master',
        description: 'Solve 5 AR puzzles scattered around the world',
        story: 'Test your wit against ancient puzzles that appear through AR magic.',
        type: quest_model.QuestType.exploration,
        difficulty: quest_model.QuestDifficulty.expert,
        objectives: [
          quest_model.QuestObjective(
            description: 'Solve AR puzzles',
            type: 'puzzle_solved',
            targetValue: 5,
          ),
        ],
        rewards: [
          quest_model.QuestReward(
            type: 'stat_boost',
            name: 'Mind Sharpening',
            value: 5,
          ),
        ],
        experienceReward: 800,
        goldReward: 400,
      ),
    };
  }

  /// Initialize Points of Interest
  Future<void> _initializePointsOfInterest() async {
    // Example POIs - in production, these would be loaded from a database
    _pointsOfInterest.addAll({
      'central_park': PointOfInterest(
        id: 'central_park',
        name: 'Central Park',
        description: 'A large public park in the heart of the city',
        location: GeoLocation(latitude: 40.7851, longitude: -73.9683),
        category: 'park',
        tags: ['nature', 'recreation', 'walking'],
      ),
      'city_library': PointOfInterest(
        id: 'city_library',
        name: 'City Library',
        description: 'The main public library with vast knowledge',
        location: GeoLocation(latitude: 40.7531, longitude: -73.9822),
        category: 'landmark',
        tags: ['education', 'books', 'quiet'],
      ),
      'adventure_statue': PointOfInterest(
        id: 'adventure_statue',
        name: 'Adventure Statue',
        description: 'A statue commemorating great adventurers',
        location: GeoLocation(latitude: 40.7614, longitude: -73.9776),
        category: 'monument',
        tags: ['history', 'art', 'inspiration'],
      ),
    });

    developer.log('Initialized ${_pointsOfInterest.length} POIs', name: _agentTypeId);
  }

  /// Initialize AR experiences
  Future<void> _initializeARExperiences() async {
    _arExperiences.addAll({
      'park_treasure': ARExperience(
        id: 'park_treasure',
        name: 'Hidden Park Treasure',
        description: 'Find the treasure hidden in the park using AR',
        type: ARInteractionType.treasureHunt,
        location: GeoLocation(latitude: 40.7851, longitude: -73.9683),
        triggerRadius: 50.0,
        rewards: {'gold': 100, 'cards': ['treasure_chest']},
      ),
      'library_puzzle': ARExperience(
        id: 'library_puzzle',
        name: 'Ancient Library Puzzle',
        description: 'Solve the riddle of the ancient library',
        type: ARInteractionType.puzzleGame,
        location: GeoLocation(latitude: 40.7531, longitude: -73.9822),
        triggerRadius: 30.0,
        config: {'difficulty': 'medium', 'solution': 'knowledge'},
        rewards: {'xp': 200, 'cards': ['wisdom_scroll']},
      ),
      'statue_scan': ARExperience(
        id: 'statue_scan',
        name: 'Scan the Adventure Statue',
        description: 'Use AR to scan the statue and unlock its secrets',
        type: ARInteractionType.objectDetection,
        location: GeoLocation(latitude: 40.7614, longitude: -73.9776),
        triggerRadius: 20.0,
        config: {'expectedObject': 'adventure_statue'},
        rewards: {'xp': 150, 'statBonus': {'strength': 1}},
      ),
    });

    // Map AR experiences to locations
    _locationARMapping['central_park'] = ['park_treasure'];
    _locationARMapping['city_library'] = ['library_puzzle'];
    _locationARMapping['adventure_statue'] = ['statue_scan'];

    developer.log('Initialized ${_arExperiences.length} AR experiences', name: _agentTypeId);
  }

  /// Initialize location tracking
  Future<void> _initializeLocationTracking() async {
    try {
      // Check location permissions
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requestedPermission = await Geolocator.requestPermission();
        if (requestedPermission == LocationPermission.denied) {
          developer.log('Location permission denied', name: _agentTypeId);
          return;
        }
      }

      // Start location tracking
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen(_onLocationUpdate);

      developer.log('Location tracking initialized', name: _agentTypeId);
    } catch (e) {
      developer.log('Error initializing location tracking: $e', name: _agentTypeId);
    }
  }

  /// Handle location updates
  void _onLocationUpdate(Position position) {
    _currentLocation = GeoLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      accuracy: position.accuracy,
      timestamp: position.timestamp,
    );

    // Check for POI proximity
    _checkPOIProximity();

    // Check geofence triggers
    _checkGeofenceTriggers();

    // Publish location update
    publishEvent(createEvent(
      eventType: EventTypes.locationUpdate,
      data: {
        'userId': _currentUserId,
        'location': _currentLocation!.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      },
    ));
  }

  /// Check POI proximity
  void _checkPOIProximity() {
    if (_currentLocation == null || _currentUserId == null) return;

    for (final poi in _pointsOfInterest.values) {
      if (!poi.isActive) continue;

      final distance = poi.location.distanceTo(_currentLocation!);
      if (distance <= 50.0) { // Within 50 meters
        publishEvent(createEvent(
          eventType: EventTypes.poiDetected,
          data: {
            'userId': _currentUserId,
            'poiId': poi.id,
            'poi': poi.toJson(),
            'distance': distance,
            'arExperiences': _locationARMapping[poi.id] ?? [],
          },
        ));
      }
    }
  }

  /// Check geofence triggers
  void _checkGeofenceTriggers() {
    if (_currentLocation == null || _currentUserId == null) return;

    for (final geofence in _activeGeofences) {
      if (!geofence.isActive) continue;

      final wasInside = geofence.data['userInside'] == true;
      final isInside = geofence.containsLocation(_currentLocation!);

      if (!wasInside && isInside) {
        // Entered geofence
        geofence.data['userInside'] = true;
        publishEvent(createEvent(
          eventType: 'geofence_entered',
          data: {
            'userId': _currentUserId,
            'geofenceId': geofence.id,
            'eventType': geofence.eventType,
            'data': geofence.data,
          },
        ));
      } else if (wasInside && !isInside) {
        // Exited geofence
        geofence.data['userInside'] = false;
        publishEvent(createEvent(
          eventType: 'geofence_exited',
          data: {
            'userId': _currentUserId,
            'geofenceId': geofence.id,
            'eventType': geofence.eventType,
            'data': geofence.data,
          },
        ));
      }
    }
  }

  /// Setup quest-specific geofences
  void _setupQuestGeofences(AdventureInstance adventure, quest_model.Quest quest) {
    // Main quest location
    if (quest.location != null) {
      final geofence = GeofenceRegion(
        id: 'quest_${adventure.id}_main',
        name: 'Quest Location: ${quest.name}',
        center: GeoLocation(
          latitude: quest.location!.latitude,
          longitude: quest.location!.longitude,
        ),
        radius: quest.location!.radius ?? 50.0,
        eventType: 'quest_location',
        data: {
          'questId': quest.id,
          'instanceId': adventure.id,
          'userId': adventure.userId,
          'userInside': false,
        },
      );
      _activeGeofences.add(geofence);
    }

    // Waypoint geofences
    for (int i = 0; i < quest.waypoints.length; i++) {
      final waypoint = quest.waypoints[i];
      final geofence = GeofenceRegion(
        id: 'quest_${adventure.id}_waypoint_$i',
        name: 'Waypoint $i: ${waypoint.name}',
        center: GeoLocation(
          latitude: waypoint.latitude,
          longitude: waypoint.longitude,
        ),
        radius: waypoint.radius ?? 30.0,
        eventType: 'quest_waypoint',
        data: {
          'questId': quest.id,
          'instanceId': adventure.id,
          'userId': adventure.userId,
          'waypointIndex': i,
          'waypointId': waypoint.id,
          'userInside': false,
        },
      );
      _activeGeofences.add(geofence);
    }
  }

  /// Remove quest-specific geofences
  void _removeQuestGeofences(AdventureInstance adventure) {
    _activeGeofences.removeWhere((geofence) =>
        geofence.data['instanceId'] == adventure.id);
  }

  /// Check quest prerequisites
  bool _checkQuestPrerequisites(String userId, quest_model.Quest quest) {
    final completedQuests = _userCompletedQuests[userId] ?? [];
    
    for (final prerequisite in quest.prerequisites) {
      if (!completedQuests.contains(prerequisite)) {
        return false;
      }
    }
    return true;
  }

  /// Check if quest is complete
  bool _isQuestComplete(AdventureInstance adventure, quest_model.Quest quest) {
    for (final objective in quest.objectives) {
      final currentValue = adventure.progressData[objective.id] ?? 0;
      if (currentValue < objective.targetValue) {
        return false;
      }
    }
    return true;
  }

  /// Calculate quest progress percentage
  double _calculateQuestProgress(quest_model.Quest quest, Map<String, dynamic> progressData) {
    if (quest.objectives.isEmpty) return 0.0;

    double totalProgress = 0.0;
    for (final objective in quest.objectives) {
      final currentValue = progressData[objective.id] ?? 0;
      final progress = math.min(currentValue / objective.targetValue, 1.0);
      totalProgress += progress;
    }

    return (totalProgress / quest.objectives.length) * 100.0;
  }

  /// Calculate new objective value
  dynamic _calculateNewObjectiveValue(quest_model.QuestObjective objective, dynamic currentValue, dynamic newValue) {
    switch (objective.type) {
      case 'distance':
      case 'steps':
      case 'elevation':
      case 'calories':
        return (currentValue ?? 0) + (newValue ?? 0);
      case 'location_visited':
      case 'treasure_found':
      case 'puzzle_solved':
      case 'object_detected':
        return (currentValue ?? 0) + 1;
      default:
        return newValue;
    }
  }

  /// Distribute quest rewards
  Future<void> _distributeQuestRewards(String userId, quest_model.Quest quest, AdventureInstance adventure) async {
    // Experience and gold rewards
    if (quest.experienceReward > 0 || quest.goldReward > 0) {
      await publishEvent(createEvent(
        eventType: 'character_reward',
        targetAgent: 'character_management',
        data: {
          'userId': userId,
          'xp': quest.experienceReward,
          'source': 'quest_completion',
          'questId': quest.id,
        },
      ));

      await publishEvent(createEvent(
        eventType: 'inventory_reward',
        targetAgent: 'card_system',
        data: {
          'userId': userId,
          'gold': quest.goldReward,
          'source': 'quest_completion',
          'questId': quest.id,
        },
      ));
    }

    // Quest-specific rewards
    for (final reward in quest.rewards) {
      switch (reward.type) {
        case 'card':
          if (reward.cardId != null) {
            await publishEvent(createEvent(
              eventType: 'inventory_reward',
              targetAgent: 'card_system',
              data: {
                'userId': userId,
                'cards': [reward.cardId],
                'source': 'quest_reward',
              },
            ));
          }
          break;
        case 'stat_boost':
          await publishEvent(createEvent(
            eventType: 'character_reward',
            targetAgent: 'character_management',
            data: {
              'userId': userId,
              'statBonus': {reward.name.toLowerCase(): reward.value},
              'source': 'quest_reward',
            },
          ));
          break;
        case 'item':
          // Handle other item types
          break;
      }
    }
  }

  /// Start quest progress monitoring
  void _startQuestProgressMonitoring() {
    _questProgressTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _monitorQuestProgress();
    });
  }

  /// Monitor quest progress
  void _monitorQuestProgress() {
    for (final adventure in _activeAdventures.values) {
      final quest = _availableQuests[adventure.questId];
      if (quest == null) continue;

      // Check for time-based quest failures
      if (quest.deadline != null && DateTime.now().isAfter(quest.deadline!)) {
        _failQuest(adventure.userId, adventure.id, 'deadline_exceeded');
      }
    }
  }

  /// Fail a quest
  Future<void> _failQuest(String userId, String instanceId, String reason) async {
    final adventure = _activeAdventures[instanceId];
    if (adventure == null) return;

    final failedAdventure = adventure.copyWith(
      state: AdventureState.failed,
      completionTime: DateTime.now(),
    );

    _activeAdventures[instanceId] = failedAdventure;
    _userActiveQuests[userId]?.remove(instanceId);

    // Remove quest-specific geofences
    _removeQuestGeofences(adventure);

    // Publish quest failed event
    await publishEvent(createEvent(
      eventType: EventTypes.questFailed,
      data: {
        'userId': userId,
        'questId': adventure.questId,
        'instanceId': instanceId,
        'reason': reason,
      },
    ));

    _logActivity('quest_failed', {
      'userId': userId,
      'questId': adventure.questId,
      'instanceId': instanceId,
      'reason': reason,
    });
  }

  /// Load user adventure data
  Future<void> _loadUserAdventureData() async {
    // Load from SharedPreferences as backup
    final adventuresJson = _prefs.getString('user_adventures');
    if (adventuresJson != null) {
      try {
        final data = jsonDecode(adventuresJson) as Map<String, dynamic>;
        
        // Load active adventures
        if (data['active'] != null) {
          final activeData = data['active'] as Map<String, dynamic>;
          for (final entry in activeData.entries) {
            _activeAdventures[entry.key] = AdventureInstance.fromJson(entry.value);
          }
        }

        // Load user active quests
        if (data['userActive'] != null) {
          final userActiveData = data['userActive'] as Map<String, dynamic>;
          for (final entry in userActiveData.entries) {
            _userActiveQuests[entry.key] = List<String>.from(entry.value);
          }
        }

        // Load user completed quests
        if (data['userCompleted'] != null) {
          final userCompletedData = data['userCompleted'] as Map<String, dynamic>;
          for (final entry in userCompletedData.entries) {
            _userCompletedQuests[entry.key] = List<String>.from(entry.value);
          }
        }
      } catch (e) {
        developer.log('Error loading user adventure data: $e', name: _agentTypeId);
      }
    }
  }

  /// Save user adventure data
  Future<void> _saveUserAdventureData(String userId) async {
    // Save to Data Persistence Agent
    await publishEvent(createEvent(
      eventType: 'save_data',
      targetAgent: 'data_persistence',
      data: {
        'collection': 'user_adventures',
        'id': userId,
        'data': {
          'activeQuests': _userActiveQuests[userId] ?? [],
          'completedQuests': _userCompletedQuests[userId] ?? [],
          'activeAdventures': (_activeAdventures.values
              .where((a) => a.userId == userId)
              .map((a) => a.toJson())
              .toList()),
        },
      },
    ));

    // Also save to SharedPreferences as backup
    await _saveAllAdventureData();
  }

  /// Save all adventure data to SharedPreferences
  Future<void> _saveAllAdventureData() async {
    final data = {
      'active': _activeAdventures.map((k, v) => MapEntry(k, v.toJson())),
      'userActive': _userActiveQuests,
      'userCompleted': _userCompletedQuests,
    };
    await _prefs.setString('user_adventures', jsonEncode(data));
  }

  /// Log activity
  void _logActivity(String action, Map<String, dynamic> data) {
    _recentActivities.add({
      'action': action,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Keep only last 100 activities
    if (_recentActivities.length > 100) {
      _recentActivities.removeAt(0);
    }
  }

  // Event Handlers

  /// Handle start quest events
  Future<AgentEventResponse?> _handleStartQuest(AgentEvent event) async {
    final userId = event.data['userId'] ?? _currentUserId;
    final questId = event.data['questId'];

    if (userId == null || questId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'start_quest_failed',
        data: {'error': 'Missing required parameters'},
        success: false,
      );
    }

    final adventure = await startQuest(userId, questId);

    return createResponse(
      originalEventId: event.id,
      responseType: adventure != null ? 'quest_started' : 'start_quest_failed',
      data: adventure?.toJson() ?? {'error': 'Failed to start quest'},
      success: adventure != null,
    );
  }

  /// Handle complete quest events
  Future<AgentEventResponse?> _handleCompleteQuest(AgentEvent event) async {
    final userId = event.data['userId'] ?? _currentUserId;
    final instanceId = event.data['instanceId'];

    if (userId == null || instanceId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'complete_quest_failed',
        data: {'error': 'Missing required parameters'},
        success: false,
      );
    }

    final success = await completeQuest(userId, instanceId);

    return createResponse(
      originalEventId: event.id,
      responseType: success ? 'quest_completed' : 'complete_quest_failed',
      data: {'success': success, 'instanceId': instanceId},
      success: success,
    );
  }

  /// Handle abandon quest events
  Future<AgentEventResponse?> _handleAbandonQuest(AgentEvent event) async {
    final userId = event.data['userId'] ?? _currentUserId;
    final instanceId = event.data['instanceId'];

    if (userId == null || instanceId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'abandon_quest_failed',
        data: {'error': 'Missing required parameters'},
        success: false,
      );
    }

    await _failQuest(userId, instanceId, 'abandoned');

    return createResponse(
      originalEventId: event.id,
      responseType: 'quest_abandoned',
      data: {'instanceId': instanceId},
    );
  }

  /// Handle get available quests events
  Future<AgentEventResponse?> _handleGetAvailableQuests(AgentEvent event) async {
    final userId = event.data['userId'] ?? _currentUserId;
    final questType = event.data['type'];
    final difficulty = event.data['difficulty'];

    if (userId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'get_quests_failed',
        data: {'error': 'No user ID provided'},
        success: false,
      );
    }

    var availableQuests = _availableQuests.values.where((quest) {
      // Filter by prerequisites
      if (!_checkQuestPrerequisites(userId, quest)) return false;
      
      // Filter by type if specified
      if (questType != null && quest.type.toString() != questType) return false;
      
      // Filter by difficulty if specified
      if (difficulty != null && quest.difficulty.toString() != difficulty) return false;
      
      return true;
    }).toList();

    return createResponse(
      originalEventId: event.id,
      responseType: 'available_quests',
      data: {
        'quests': availableQuests.map((q) => q.toJson()).toList(),
        'count': availableQuests.length,
      },
    );
  }

  /// Handle get active quests events
  Future<AgentEventResponse?> _handleGetActiveQuests(AgentEvent event) async {
    final userId = event.data['userId'] ?? _currentUserId;

    if (userId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'get_active_quests_failed',
        data: {'error': 'No user ID provided'},
        success: false,
      );
    }

    final activeInstanceIds = _userActiveQuests[userId] ?? [];
    final activeAdventures = activeInstanceIds
        .map((id) => _activeAdventures[id])
        .where((adventure) => adventure != null)
        .cast<AdventureInstance>()
        .toList();

    return createResponse(
      originalEventId: event.id,
      responseType: 'active_quests',
      data: {
        'adventures': activeAdventures.map((a) => a.toJson()).toList(),
        'count': activeAdventures.length,
      },
    );
  }

  /// Handle get quest progress events
  Future<AgentEventResponse?> _handleGetQuestProgress(AgentEvent event) async {
    final userId = event.data['userId'] ?? _currentUserId;
    final instanceId = event.data['instanceId'];

    if (userId == null || instanceId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'get_progress_failed',
        data: {'error': 'Missing required parameters'},
        success: false,
      );
    }

    final adventure = _activeAdventures[instanceId];
    if (adventure == null || adventure.userId != userId) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'get_progress_failed',
        data: {'error': 'Adventure not found'},
        success: false,
      );
    }

    final quest = _availableQuests[adventure.questId];
    
    return createResponse(
      originalEventId: event.id,
      responseType: 'quest_progress',
      data: {
        'adventure': adventure.toJson(),
        'quest': quest?.toJson(),
        'progress': adventure.completionPercentage,
      },
    );
  }

  /// Handle location update events
  Future<AgentEventResponse?> _handleLocationUpdate(AgentEvent event) async {
    final userId = event.data['userId'];
    final latitude = event.data['latitude'];
    final longitude = event.data['longitude'];

    if (userId != null && latitude != null && longitude != null) {
      _currentLocation = GeoLocation(
        latitude: latitude.toDouble(),
        longitude: longitude.toDouble(),
      );

      // Update location-based quest objectives
      await updateQuestObjective(userId, 'location_update', _currentLocation);
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'location_update_processed',
      data: {'processed': true},
    );
  }

  /// Handle POI detected events
  Future<AgentEventResponse?> _handlePOIDetected(AgentEvent event) async {
    final userId = event.data['userId'];
    final poiId = event.data['poiId'];

    if (userId != null && poiId != null) {
      await updateQuestObjective(userId, 'location_visited', 1);
      await updateQuestObjective(userId, 'poi_visited', 1);
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'poi_detection_processed',
      data: {'poiId': poiId},
    );
  }

  /// Handle geofence entered events
  Future<AgentEventResponse?> _handleGeofenceEntered(AgentEvent event) async {
    final userId = event.data['userId'];
    final geofenceId = event.data['geofenceId'];
    final eventType = event.data['eventType'];
    final data = event.data['data'];

    if (eventType == 'quest_location' && data['instanceId'] != null) {
      await updateQuestObjective(userId, 'location_reached', 1);
    } else if (eventType == 'quest_waypoint' && data['waypointId'] != null) {
      await updateQuestObjective(userId, 'waypoint_reached', 1);
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'geofence_entered_processed',
      data: {'geofenceId': geofenceId, 'eventType': eventType},
    );
  }

  /// Handle geofence exited events
  Future<AgentEventResponse?> _handleGeofenceExited(AgentEvent event) async {
    final geofenceId = event.data['geofenceId'];
    final eventType = event.data['eventType'];

    return createResponse(
      originalEventId: event.id,
      responseType: 'geofence_exited_processed',
      data: {'geofenceId': geofenceId, 'eventType': eventType},
    );
  }

  /// Handle trigger AR experience events
  Future<AgentEventResponse?> _handleTriggerARExperience(AgentEvent event) async {
    final userId = event.data['userId'] ?? _currentUserId;
    final experienceId = event.data['experienceId'];
    final context = event.data['context'];

    if (userId == null || experienceId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'ar_experience_failed',
        data: {'error': 'Missing required parameters'},
        success: false,
      );
    }

    final result = await triggerARExperience(userId, experienceId, context: context);

    return createResponse(
      originalEventId: event.id,
      responseType: result != null ? 'ar_experience_triggered' : 'ar_experience_failed',
      data: result ?? {'error': 'AR experience not found'},
      success: result != null,
    );
  }

  /// Handle complete AR interaction events
  Future<AgentEventResponse?> _handleCompleteARInteraction(AgentEvent event) async {
    final userId = event.data['userId'] ?? _currentUserId;
    final experienceId = event.data['experienceId'];
    final result = event.data['result'];

    if (userId != null && experienceId != null) {
      await updateQuestObjective(userId, 'ar_interaction', 1);
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'ar_interaction_completed',
      data: {'experienceId': experienceId, 'result': result},
    );
  }

  /// Handle update quest objective events
  Future<AgentEventResponse?> _handleUpdateQuestObjective(AgentEvent event) async {
    final userId = event.data['userId'] ?? _currentUserId;
    final objectiveType = event.data['objectiveType'];
    final value = event.data['value'];

    if (userId == null || objectiveType == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'update_objective_failed',
        data: {'error': 'Missing required parameters'},
        success: false,
      );
    }

    await updateQuestObjective(userId, objectiveType, value);

    return createResponse(
      originalEventId: event.id,
      responseType: 'quest_objective_updated',
      data: {'objectiveType': objectiveType, 'value': value},
    );
  }

  /// Handle check quest completion events
  Future<AgentEventResponse?> _handleCheckQuestCompletion(AgentEvent event) async {
    final userId = event.data['userId'] ?? _currentUserId;

    if (userId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'check_completion_failed',
        data: {'error': 'No user ID provided'},
        success: false,
      );
    }

    final activeInstanceIds = _userActiveQuests[userId] ?? [];
    final completedQuests = <String>[];

    for (final instanceId in activeInstanceIds) {
      final adventure = _activeAdventures[instanceId];
      if (adventure == null) continue;

      final quest = _availableQuests[adventure.questId];
      if (quest == null) continue;

      if (_isQuestComplete(adventure, quest)) {
        await completeQuest(userId, instanceId);
        completedQuests.add(adventure.questId);
      }
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'quest_completion_checked',
      data: {
        'completedQuests': completedQuests,
        'count': completedQuests.length,
      },
    );
  }

  /// Handle fitness update events
  Future<AgentEventResponse?> _handleFitnessUpdate(AgentEvent event) async {
    final userId = event.data['userId'];
    final steps = event.data['steps'] ?? 0;
    final distance = event.data['distance'] ?? 0.0;
    final calories = event.data['calories'] ?? 0;

    if (userId != null) {
      await updateQuestObjective(userId, 'steps', steps);
      await updateQuestObjective(userId, 'distance', distance);
      await updateQuestObjective(userId, 'calories', calories);
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'fitness_update_processed',
      data: {'steps': steps, 'distance': distance, 'calories': calories},
    );
  }

  /// Handle battle result events
  Future<AgentEventResponse?> _handleBattleResult(AgentEvent event) async {
    final userId = event.data['userId'];
    final isVictory = event.data['isVictory'] ?? false;

    if (userId != null) {
      await updateQuestObjective(userId, 'battles_fought', 1);
      if (isVictory) {
        await updateQuestObjective(userId, 'battles_won', 1);
      }
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'battle_result_processed',
      data: {'isVictory': isVictory},
    );
  }

  /// Handle card scanned events
  Future<AgentEventResponse?> _handleCardScanned(AgentEvent event) async {
    final userId = event.data['scannedBy'];

    if (userId != null) {
      await updateQuestObjective(userId, 'cards_scanned', 1);
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'card_scan_processed',
      data: {'processed': true},
    );
  }

  /// Handle user login events
  Future<AgentEventResponse?> _handleUserLogin(AgentEvent event) async {
    final userId = event.data['userId'];
    _currentUserId = userId;

    if (userId != null) {
      // Initialize user data if needed
      _userActiveQuests.putIfAbsent(userId, () => []);
      _userCompletedQuests.putIfAbsent(userId, () => []);

      await _saveUserAdventureData(userId);
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'user_login_processed',
      data: {'userId': userId},
    );
  }

  /// Handle user logout events
  Future<AgentEventResponse?> _handleUserLogout(AgentEvent event) async {
    if (_currentUserId != null) {
      await _saveUserAdventureData(_currentUserId!);
      _currentUserId = null;
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'user_logout_processed',
      data: {'loggedOut': true},
    );
  }

  /// Handle save adventure data events
  Future<AgentEventResponse?> _handleSaveAdventureData(AgentEvent event) async {
    await _saveAllAdventureData();

    return createResponse(
      originalEventId: event.id,
      responseType: 'adventure_data_saved',
      data: {'saved': true},
    );
  }

  /// Handle load adventure data events
  Future<AgentEventResponse?> _handleLoadAdventureData(AgentEvent event) async {
    await _loadUserAdventureData();

    return createResponse(
      originalEventId: event.id,
      responseType: 'adventure_data_loaded',
      data: {'loaded': true},
    );
  }

  @override
  Future<void> onDispose() async {
    // Cancel subscriptions
    _locationSubscription?.cancel();
    _questProgressTimer?.cancel();

    // Save all data
    await _saveAllAdventureData();

    developer.log('Adventure & Quest Agent disposed', name: _agentTypeId);
  }
}