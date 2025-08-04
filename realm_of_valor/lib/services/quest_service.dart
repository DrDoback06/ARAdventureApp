import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quest_model.dart';
import 'dart:convert';

class QuestService {
  static final QuestService _instance = QuestService._internal();
  factory QuestService() => _instance;
  QuestService._internal();

  final Random _random = Random();
  final List<Quest> _availableQuests = [];
  final List<Quest> _activeQuests = [];
  final List<Quest> _completedQuests = [];
  final Map<String, QuestProgress> _questProgress = {};

  // Initialize quest service
  Future<void> initialize(String playerId) async {
    await _loadQuestData(playerId);
    await _generateInitialQuests();
  }

  // Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );
      print('Current location: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Generate location-based quests
  Future<List<Quest>> generateLocationBasedQuests(Position userLocation) async {
    final quests = <Quest>[];

    // Generate walking/running quests
    quests.addAll(await _generateMovementQuests(userLocation));

    // Generate exploration quests
    quests.addAll(await _generateExplorationQuests(userLocation));

    // Generate location-specific quests
    quests.addAll(await _generateLocationQuests(userLocation));

    return quests;
  }

  // Generate movement quests (walking, running)
  Future<List<Quest>> _generateMovementQuests(Position userLocation) async {
    final quests = <Quest>[];
    
    // Generate walking route quest
    final walkingRoute = await _generateWalkingRoute(userLocation, 1609); // 1 mile
    if (walkingRoute.isNotEmpty) {
      quests.add(Quest(
        name: 'Morning Mile Adventure',
        description: 'Walk the magical mile to discover hidden treasures',
        story: 'The ancient paths whisper of treasures hidden along this route. Walk the mile and claim your reward!',
        type: QuestType.walking,
        difficulty: QuestDifficulty.easy,
        location: QuestLocation(
          name: 'Starting Point',
          description: 'Begin your journey here',
          latitude: userLocation.latitude,
          longitude: userLocation.longitude,
        ),
        waypoints: walkingRoute,
        objectives: [
          QuestObjective(
            description: 'Walk 1 mile following the route',
            type: 'distance',
            targetValue: 1609,
          ),
          QuestObjective(
            description: 'Visit all waypoints',
            type: 'waypoints',
            targetValue: walkingRoute.length,
          ),
        ],
        experienceReward: 200,
        goldReward: 100,
        rewards: [
          QuestReward(type: 'item', name: 'Traveler\'s Boots', value: 1),
        ],
      ));
    }

    // Generate running quest
    final runningRoute = await _generateRunningRoute(userLocation, 3218); // 2 miles
    if (runningRoute.isNotEmpty) {
      quests.add(Quest(
        name: 'Swift Messenger',
        description: 'Run the messenger\'s route to deliver urgent news',
        story: 'The kingdom needs a swift messenger to deliver crucial information. Are you up for the challenge?',
        type: QuestType.running,
        difficulty: QuestDifficulty.medium,
        location: QuestLocation(
          name: 'Messenger\'s Start',
          description: 'The messenger\'s guild awaits',
          latitude: userLocation.latitude,
          longitude: userLocation.longitude,
        ),
        waypoints: runningRoute,
        objectives: [
          QuestObjective(
            description: 'Run 2 miles following the route',
            type: 'distance',
            targetValue: 3218,
          ),
          QuestObjective(
            description: 'Complete within 30 minutes',
            type: 'time',
            targetValue: 1800, // 30 minutes in seconds
          ),
        ],
        experienceReward: 400,
        goldReward: 200,
        rewards: [
          QuestReward(type: 'item', name: 'Runner\'s Endurance Potion', value: 1),
        ],
      ));
    }

    return quests;
  }

  // Generate exploration quests
  Future<List<Quest>> _generateExplorationQuests(Position userLocation) async {
    final quests = <Quest>[];
    
    // Find nearby points of interest
    final nearbyPOIs = await _findNearbyPointsOfInterest(userLocation);
    
    if (nearbyPOIs.isNotEmpty) {
      quests.add(Quest(
        name: 'Urban Explorer',
        description: 'Discover the hidden secrets of your city',
        story: 'Every city holds mysteries waiting to be uncovered. Explore these locations to reveal their secrets.',
        type: QuestType.exploration,
        difficulty: QuestDifficulty.medium,
        waypoints: nearbyPOIs.take(5).toList(),
        objectives: [
          QuestObjective(
            description: 'Visit 5 different locations',
            type: 'location_visits',
            targetValue: 5,
          ),
        ],
        experienceReward: 300,
        goldReward: 150,
        rewards: [
          QuestReward(type: 'skill', name: 'Navigation', value: 1),
          QuestReward(type: 'item', name: 'Explorer\'s Compass', value: 1),
        ],
      ));
    }

    return quests;
  }

  // Generate location-specific quests
  Future<List<Quest>> _generateLocationQuests(Position userLocation) async {
    final quests = <Quest>[];
    
    // Generate mountain climbing quest if mountains are nearby
    final nearbyMountains = await _findNearbyMountains(userLocation);
    if (nearbyMountains.isNotEmpty) {
      final mountain = nearbyMountains.first;
      quests.add(Quest(
        name: 'Mountain Conqueror',
        description: 'Scale the mighty peak to claim ancient treasures',
        story: 'Legends speak of artifacts hidden at the mountain\'s peak. Only the brave dare to climb.',
        type: QuestType.climbing,
        difficulty: QuestDifficulty.hard,
        location: mountain,
        objectives: [
          QuestObjective(
            description: 'Reach the mountain summit',
            type: 'elevation',
            targetValue: 500, // 500 meters elevation gain
          ),
          QuestObjective(
            description: 'Maintain elevated heart rate for 20 minutes',
            type: 'heart_rate',
            targetValue: 1200, // 20 minutes in seconds
          ),
        ],
        experienceReward: 800,
        goldReward: 400,
        rewards: [
          QuestReward(type: 'item', name: 'Mountain Climber\'s Gear', value: 1),
          QuestReward(type: 'item', name: 'Peak Conqueror\'s Crown', value: 1),
        ],
      ));
    }

    return quests;
  }

  // Generate walking route
  Future<List<QuestLocation>> _generateWalkingRoute(Position start, int targetDistance) async {
    final waypoints = <QuestLocation>[];
    
    // Generate a simple circular route
    final radiusKm = targetDistance / 1000.0 / (2 * pi); // Rough circular distance
    final numWaypoints = 8;
    
    for (int i = 0; i < numWaypoints; i++) {
      final angle = (i / numWaypoints) * 2 * pi;
      final lat = start.latitude + (radiusKm / 111.0) * cos(angle);
      final lng = start.longitude + (radiusKm / (111.0 * cos(start.latitude * pi / 180))) * sin(angle);
      
      waypoints.add(QuestLocation(
        name: 'Waypoint ${i + 1}',
        description: 'Checkpoint along your journey',
        latitude: lat,
        longitude: lng,
        radius: 50.0, // 50 meter radius
      ));
    }
    
    return waypoints;
  }

  // Generate running route
  Future<List<QuestLocation>> _generateRunningRoute(Position start, int targetDistance) async {
    // For now, use similar logic to walking but with different waypoints
    return await _generateWalkingRoute(start, targetDistance);
  }

  // Find nearby points of interest
  Future<List<QuestLocation>> _findNearbyPointsOfInterest(Position userLocation) async {
    // In a real implementation, you'd use Google Places API or similar
    // For now, generate some sample locations
    final sampleLocations = [
      QuestLocation(
        name: 'Ancient Library',
        description: 'A repository of forgotten knowledge',
        latitude: userLocation.latitude + 0.01,
        longitude: userLocation.longitude + 0.01,
        radius: 100.0,
      ),
      QuestLocation(
        name: 'Mystic Park',
        description: 'Where nature\'s magic is strongest',
        latitude: userLocation.latitude - 0.01,
        longitude: userLocation.longitude + 0.01,
        radius: 100.0,
      ),
      QuestLocation(
        name: 'Trader\'s Market',
        description: 'Hub of commerce and secrets',
        latitude: userLocation.latitude + 0.01,
        longitude: userLocation.longitude - 0.01,
        radius: 100.0,
      ),
      QuestLocation(
        name: 'Temple of Reflection',
        description: 'A place of peace and contemplation',
        latitude: userLocation.latitude - 0.01,
        longitude: userLocation.longitude - 0.01,
        radius: 100.0,
      ),
      QuestLocation(
        name: 'Craftsman\'s Workshop',
        description: 'Where magical items are forged',
        latitude: userLocation.latitude + 0.005,
        longitude: userLocation.longitude + 0.005,
        radius: 100.0,
      ),
    ];
    
    return sampleLocations;
  }

  // Find nearby mountains
  Future<List<QuestLocation>> _findNearbyMountains(Position userLocation) async {
    // In a real implementation, you'd use a terrain API
    // For now, generate sample mountain locations
    return [
      QuestLocation(
        name: 'Dragon\'s Peak',
        description: 'The highest mountain in the region',
        latitude: userLocation.latitude + 0.05,
        longitude: userLocation.longitude + 0.05,
        radius: 200.0,
      ),
    ];
  }

  // Start a quest
  Future<void> startQuest(String questId, String playerId) async {
    final quest = _availableQuests.firstWhere((q) => q.id == questId);
    
    final startedQuest = quest.copyWith(
      status: QuestStatus.active,
      startTime: DateTime.now(),
    );
    
    _availableQuests.removeWhere((q) => q.id == questId);
    _activeQuests.add(startedQuest);
    
    // Create quest progress
    _questProgress[questId] = QuestProgress(
      questId: questId,
      playerId: playerId,
    );
    
    await _saveQuestData(playerId);
  }

  // Update quest progress
  Future<void> updateQuestProgress(String questId, String objectiveType, int value) async {
    final questIndex = _activeQuests.indexWhere((q) => q.id == questId);
    if (questIndex == -1) return;
    
    final quest = _activeQuests[questIndex];
    final progress = _questProgress[questId];
    if (progress == null) return;
    
    // Update objectives
    final updatedObjectives = <QuestObjective>[];
    bool questCompleted = true;
    
    for (final objective in quest.objectives) {
      if (objective.type == objectiveType) {
        final updatedObjective = objective.copyWith(
          currentValue: (objective.currentValue + value).clamp(0, objective.targetValue),
          isCompleted: (objective.currentValue + value) >= objective.targetValue,
        );
        updatedObjectives.add(updatedObjective);
        
        if (!updatedObjective.isCompleted) {
          questCompleted = false;
        }
      } else {
        updatedObjectives.add(objective);
        if (!objective.isCompleted) {
          questCompleted = false;
        }
      }
    }
    
    // Update quest
    final updatedQuest = quest.copyWith(
      objectives: updatedObjectives,
      status: questCompleted ? QuestStatus.completed : QuestStatus.active,
      endTime: questCompleted ? DateTime.now() : null,
    );
    
    _activeQuests[questIndex] = updatedQuest;
    
    if (questCompleted) {
      await _completeQuest(questId);
    }
    
    await _saveQuestData(progress.playerId);
  }

  // Complete a quest
  Future<void> _completeQuest(String questId) async {
    final questIndex = _activeQuests.indexWhere((q) => q.id == questId);
    if (questIndex == -1) return;
    
    final quest = _activeQuests[questIndex];
    _activeQuests.removeAt(questIndex);
    _completedQuests.add(quest);
    
    // Award rewards to player
    await _awardQuestRewards(quest);
    print('Quest completed: ${quest.name}');
    print('Rewards: ${quest.experienceReward} XP, ${quest.goldReward} Gold');
    
    for (final reward in quest.rewards) {
      print('Reward: ${reward.name} (${reward.type})');
    }
  }

  // Award quest rewards
  Future<void> _awardQuestRewards(Quest quest) async {
    try {
      // Award experience points
      if (quest.experienceReward > 0) {
        await _addExperienceToCharacter(quest.experienceReward);
        print('Awarded ${quest.experienceReward} XP');
      }
      
      // Award gold
      if (quest.goldReward > 0) {
        await _addGoldToCharacter(quest.goldReward);
        print('Awarded ${quest.goldReward} Gold');
      }
      
      // Award item rewards
      for (final reward in quest.rewards) {
        switch (reward.type) {
          case 'item':
            await _addItemToInventory(reward.name, reward.value);
            print('Awarded item: ${reward.name}');
            break;
          case 'skill':
            await _unlockSkillForCharacter(reward.name);
            print('Unlocked skill: ${reward.name}');
            break;
          case 'attribute':
            await _increaseCharacterAttribute(reward.name, reward.value);
            print('Increased attribute: ${reward.name}');
            break;
          case 'title':
            await _awardTitleToCharacter(reward.name);
            print('Awarded title: ${reward.name}');
            break;
          case 'gold':
            await _addGoldToCharacter(reward.value);
            print('Awarded gold: ${reward.value}');
            break;
          case 'experience':
            await _addExperienceToCharacter(reward.value);
            print('Awarded experience: ${reward.value}');
            break;
          default:
            print('Awarded ${reward.type}: ${reward.name}');
            break;
        }
      }
      
      // Save quest completion
      await _saveQuestData('default_player');
      
    } catch (e) {
      print('Error awarding quest rewards: $e');
    }
  }

  // Add experience to character
  Future<void> _addExperienceToCharacter(int experience) async {
    try {
      // This would integrate with CharacterProvider
      // For now, we'll simulate the experience gain
      print('Character gained $experience experience points');
    } catch (e) {
      print('Error adding experience: $e');
    }
  }

  // Add gold to character
  Future<void> _addGoldToCharacter(int gold) async {
    try {
      // This would integrate with inventory/currency system
      print('Character gained $gold gold');
    } catch (e) {
      print('Error adding gold: $e');
    }
  }

  // Add item to inventory
  Future<void> _addItemToInventory(String itemName, int quantity) async {
    try {
      // This would integrate with inventory system
      print('Added $quantity x $itemName to inventory');
    } catch (e) {
      print('Error adding item to inventory: $e');
    }
  }

  // Unlock skill for character
  Future<void> _unlockSkillForCharacter(String skillName) async {
    try {
      // This would integrate with skill system
      print('Unlocked skill: $skillName');
    } catch (e) {
      print('Error unlocking skill: $e');
    }
  }

  // Increase character attribute
  Future<void> _increaseCharacterAttribute(String attributeName, int value) async {
    try {
      // This would integrate with character stats system
      print('Increased $attributeName by $value');
    } catch (e) {
      print('Error increasing attribute: $e');
    }
  }

  // Award title to character
  Future<void> _awardTitleToCharacter(String titleName) async {
    try {
      // This would integrate with title/achievement system
      print('Awarded title: $titleName');
    } catch (e) {
      print('Error awarding title: $e');
    }
  }

  // Check location-based quest progress
  Future<void> checkLocationProgress(Position currentLocation) async {
    for (final quest in _activeQuests) {
      if (quest.type == QuestType.location || quest.type == QuestType.exploration) {
        await _checkLocationObjectives(quest, currentLocation);
      }
    }
  }

  // Check location objectives
  Future<void> _checkLocationObjectives(Quest quest, Position currentLocation) async {
    for (final waypoint in quest.waypoints) {
      final distance = Geolocator.distanceBetween(
        currentLocation.latitude,
        currentLocation.longitude,
        waypoint.latitude,
        waypoint.longitude,
      );
      
      if (distance <= (waypoint.radius ?? 100.0)) {
        // Player is at this waypoint
        await updateQuestProgress(quest.id, 'location_visits', 1);
      }
    }
  }

  // Generate random encounters
  Future<List<MapEncounter>> generateRandomEncounters(Position userLocation, int radius) async {
    final encounters = <MapEncounter>[];
    final numEncounters = _random.nextInt(3) + 1; // 1-3 encounters
    
    for (int i = 0; i < numEncounters; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final distance = _random.nextDouble() * radius;
      
      final lat = userLocation.latitude + (distance / 111000.0) * cos(angle);
      final lng = userLocation.longitude + (distance / (111000.0 * cos(userLocation.latitude * pi / 180))) * sin(angle);
      
      final encounterType = EncounterType.values[_random.nextInt(EncounterType.values.length)];
      
      encounters.add(MapEncounter(
        id: 'encounter_${DateTime.now().millisecondsSinceEpoch}_$i',
        type: encounterType,
        name: _getEncounterName(encounterType),
        description: _getEncounterDescription(encounterType),
        latitude: lat,
        longitude: lng,
        radius: 50.0,
        isActive: true,
        expiresAt: DateTime.now().add(const Duration(hours: 2)),
      ));
    }
    
    return encounters;
  }

  // Get encounter name
  String _getEncounterName(EncounterType type) {
    switch (type) {
      case EncounterType.treasure:
        return 'Hidden Treasure';
      case EncounterType.enemy:
        return 'Wild Monster';
      case EncounterType.merchant:
        return 'Traveling Merchant';
      case EncounterType.ally:
        return 'Friendly Adventurer';
      case EncounterType.mystery:
        return 'Strange Phenomenon';
    }
  }

  // Get encounter description
  String _getEncounterDescription(EncounterType type) {
    switch (type) {
      case EncounterType.treasure:
        return 'A chest glints in the sunlight, promising valuable rewards.';
      case EncounterType.enemy:
        return 'A dangerous creature prowls the area, ready for battle.';
      case EncounterType.merchant:
        return 'A merchant offers rare goods and services.';
      case EncounterType.ally:
        return 'A fellow adventurer seeks companionship on their journey.';
      case EncounterType.mystery:
        return 'Something unusual has been spotted in this location.';
    }
  }

  // Get available quests
  List<Quest> getAvailableQuests() => List.unmodifiable(_availableQuests);

  // Get active quests
  List<Quest> getActiveQuests() => List.unmodifiable(_activeQuests);

  // Get completed quests
  List<Quest> getCompletedQuests() => List.unmodifiable(_completedQuests);

  // Generate initial quests
  Future<void> _generateInitialQuests() async {
    if (_availableQuests.isEmpty) {
      _availableQuests.addAll(Quest.getDefaultQuests());
    }
  }

  // Data persistence
  Future<void> _loadQuestData(String playerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load available quests
      final availableQuestsJson = prefs.getString('available_quests_$playerId') ?? '[]';
      final availableQuestsList = List<Map<String, dynamic>>.from(jsonDecode(availableQuestsJson));
      _availableQuests.clear();
      _availableQuests.addAll(availableQuestsList.map((json) => Quest.fromJson(json)));
      
      // Load active quests
      final activeQuestsJson = prefs.getString('active_quests_$playerId') ?? '[]';
      final activeQuestsList = List<Map<String, dynamic>>.from(jsonDecode(activeQuestsJson));
      _activeQuests.clear();
      _activeQuests.addAll(activeQuestsList.map((json) => Quest.fromJson(json)));
      
      // Load completed quests
      final completedQuestsJson = prefs.getString('completed_quests_$playerId') ?? '[]';
      final completedQuestsList = List<Map<String, dynamic>>.from(jsonDecode(completedQuestsJson));
      _completedQuests.clear();
      _completedQuests.addAll(completedQuestsList.map((json) => Quest.fromJson(json)));
      
      // Load quest progress
      final progressJson = prefs.getString('quest_progress_$playerId') ?? '{}';
      final progressMap = Map<String, dynamic>.from(jsonDecode(progressJson));
      _questProgress.clear();
      progressMap.forEach((key, value) {
        _questProgress[key] = QuestProgress.fromJson(value);
      });
    } catch (e) {
      print('Error loading quest data: $e');
    }
  }

  Future<void> _saveQuestData(String playerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save available quests
      final availableQuestsJson = jsonEncode(_availableQuests.map((q) => q.toJson()).toList());
      await prefs.setString('available_quests_$playerId', availableQuestsJson);
      
      // Save active quests
      final activeQuestsJson = jsonEncode(_activeQuests.map((q) => q.toJson()).toList());
      await prefs.setString('active_quests_$playerId', activeQuestsJson);
      
      // Save completed quests
      final completedQuestsJson = jsonEncode(_completedQuests.map((q) => q.toJson()).toList());
      await prefs.setString('completed_quests_$playerId', completedQuestsJson);
      
      // Save quest progress
      final progressMap = <String, dynamic>{};
      _questProgress.forEach((key, value) {
        progressMap[key] = value.toJson();
      });
      final progressJson = jsonEncode(progressMap);
      await prefs.setString('quest_progress_$playerId', progressJson);
    } catch (e) {
      print('Error saving quest data: $e');
    }
  }
}

// Map encounter types
enum EncounterType {
  treasure,
  enemy,
  merchant,
  ally,
  mystery,
}

// Map encounter class
class MapEncounter {
  final String id;
  final EncounterType type;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final double radius;
  final bool isActive;
  final DateTime expiresAt;
  final Map<String, dynamic> data;

  MapEncounter({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.isActive,
    required this.expiresAt,
    Map<String, dynamic>? data,
  }) : data = data ?? {};

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}