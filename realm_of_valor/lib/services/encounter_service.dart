import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/location_service.dart';
import '../services/quest_generator_service.dart';
import '../models/weather_model.dart';

class EncounterService extends ChangeNotifier {
  static final EncounterService _instance = EncounterService._internal();
  factory EncounterService() => _instance;
  EncounterService._internal();

  final Random _random = Random();
  List<Encounter> _activeEncounters = [];

  // Getters
  List<Encounter> get activeEncounters => _activeEncounters;

  // Generate encounters for a quest
  List<Encounter> generateEncountersForQuest(AdventureQuest quest, UserLocation playerLocation) {
    final encounters = <Encounter>[];
    final numEncounters = 1 + _random.nextInt(3); // 1-3 encounters

    for (int i = 0; i < numEncounters; i++) {
      final encounterLocation = _generateEncounterLocation(playerLocation, quest.location);
      final encounter = _createEncounter(quest.type, encounterLocation, i);
      encounters.add(encounter);
    }

    return encounters;
  }

  // Generate encounter location along the route
  LatLng _generateEncounterLocation(UserLocation start, LatLng end) {
    // Generate a point along the route between start and end
    final progress = 0.3 + (_random.nextDouble() * 0.4); // 30-70% along the route
    
    final lat = start.latitude + (end.latitude - start.latitude) * progress;
    final lng = start.longitude + (end.longitude - start.longitude) * progress;
    
    // Add some randomness to the side of the route
    final offset = (_random.nextDouble() - 0.5) * 0.001; // Small offset
    
    return LatLng(lat + offset, lng + offset);
  }

  // Create encounter based on quest type
  Encounter _createEncounter(QuestType questType, LatLng location, int index) {
    switch (questType) {
      case QuestType.exploration:
        return _createExplorationEncounter(location, index);
      case QuestType.fitness:
        return _createFitnessEncounter(location, index);
      case QuestType.battle:
        return _createBattleEncounter(location, index);
      case QuestType.social:
        return _createSocialEncounter(location, index);
      case QuestType.collection:
        return _createCollectionEncounter(location, index);
      case QuestType.walking:
        return _createWalkingEncounter(location, index);
      case QuestType.running:
        return _createRunningEncounter(location, index);
      case QuestType.climbing:
        return _createClimbingEncounter(location, index);
      case QuestType.location:
        return _createLocationEncounter(location, index);
      case QuestType.time:
        return _createExplorationEncounter(location, index); // Default to exploration for time-based
      case QuestType.weather:
        return _createExplorationEncounter(location, index); // Default to exploration for weather-based
    }
  }

  Encounter _createExplorationEncounter(LatLng location, int index) {
    final encounters = [
      Encounter(
        id: 'exploration_encounter_$index',
        title: 'Ancient Skeleton',
        description: 'A skeletal warrior rises from the ground! Will you fight or flee?',
        type: EncounterType.battle,
        location: location,
        rewardXP: 50,
        rewardGold: 25,
        difficulty: EncounterDifficulty.easy,
      ),
      Encounter(
        id: 'exploration_encounter_$index',
        title: 'Hidden Treasure',
        description: 'You discover a hidden treasure chest! What riches await?',
        type: EncounterType.collection,
        location: location,
        rewardXP: 75,
        rewardGold: 100,
        difficulty: EncounterDifficulty.medium,
      ),
    ];
    return encounters[_random.nextInt(encounters.length)];
  }

  Encounter _createFitnessEncounter(LatLng location, int index) {
    final encounters = [
      Encounter(
        id: 'fitness_encounter_$index',
        title: 'Fitness Challenge',
        description: 'Complete a quick fitness challenge to boost your stats!',
        type: EncounterType.fitness,
        location: location,
        rewardXP: 100,
        rewardGold: 50,
        difficulty: EncounterDifficulty.medium,
      ),
      Encounter(
        id: 'fitness_encounter_$index',
        title: 'Endurance Test',
        description: 'Test your endurance with a challenging workout.',
        type: EncounterType.fitness,
        location: location,
        rewardXP: 150,
        rewardGold: 75,
        difficulty: EncounterDifficulty.hard,
      ),
    ];
    return encounters[_random.nextInt(encounters.length)];
  }

  Encounter _createBattleEncounter(LatLng location, int index) {
    final encounters = [
      Encounter(
        id: 'battle_encounter_$index',
        title: 'Rival Trainer',
        description: 'A rival trainer challenges you to a battle!',
        type: EncounterType.battle,
        location: location,
        rewardXP: 200,
        rewardGold: 150,
        difficulty: EncounterDifficulty.hard,
      ),
      Encounter(
        id: 'battle_encounter_$index',
        title: 'Wild Monster',
        description: 'A fierce monster blocks your path!',
        type: EncounterType.battle,
        location: location,
        rewardXP: 175,
        rewardGold: 125,
        difficulty: EncounterDifficulty.medium,
      ),
    ];
    return encounters[_random.nextInt(encounters.length)];
  }

  Encounter _createSocialEncounter(LatLng location, int index) {
    final encounters = [
      Encounter(
        id: 'social_encounter_$index',
        title: 'Friendly Local',
        description: 'A friendly local shares interesting stories about the area.',
        type: EncounterType.social,
        location: location,
        rewardXP: 50,
        rewardGold: 25,
        difficulty: EncounterDifficulty.easy,
      ),
      Encounter(
        id: 'social_encounter_$index',
        title: 'Traveling Merchant',
        description: 'A traveling merchant offers rare items for sale.',
        type: EncounterType.social,
        location: location,
        rewardXP: 75,
        rewardGold: 100,
        difficulty: EncounterDifficulty.medium,
      ),
    ];
    return encounters[_random.nextInt(encounters.length)];
  }

  Encounter _createCollectionEncounter(LatLng location, int index) {
    final encounters = [
      Encounter(
        id: 'collection_encounter_$index',
        title: 'Rare Item',
        description: 'You find a rare item that could be valuable.',
        type: EncounterType.collection,
        location: location,
        rewardXP: 75,
        rewardGold: 150,
        difficulty: EncounterDifficulty.medium,
      ),
      Encounter(
        id: 'collection_encounter_$index',
        title: 'Hidden Cache',
        description: 'A hidden cache contains valuable treasures.',
        type: EncounterType.collection,
        location: location,
        rewardXP: 100,
        rewardGold: 200,
        difficulty: EncounterDifficulty.medium,
      ),
    ];
    return encounters[_random.nextInt(encounters.length)];
  }

  Encounter _createWalkingEncounter(LatLng location, int index) {
    final encounters = [
      Encounter(
        id: 'walking_encounter_$index',
        title: 'Scenic View',
        description: 'A beautiful scenic view perfect for a photo.',
        type: EncounterType.exploration,
        location: location,
        rewardXP: 25,
        rewardGold: 10,
        difficulty: EncounterDifficulty.easy,
      ),
      Encounter(
        id: 'walking_encounter_$index',
        title: 'Historical Marker',
        description: 'A historical marker tells an interesting story.',
        type: EncounterType.exploration,
        location: location,
        rewardXP: 50,
        rewardGold: 25,
        difficulty: EncounterDifficulty.easy,
      ),
    ];
    return encounters[_random.nextInt(encounters.length)];
  }

  Encounter _createRunningEncounter(LatLng location, int index) {
    final encounters = [
      Encounter(
        id: 'running_encounter_$index',
        title: 'Speed Challenge',
        description: 'A speed challenge tests your running ability.',
        type: EncounterType.fitness,
        location: location,
        rewardXP: 100,
        rewardGold: 50,
        difficulty: EncounterDifficulty.medium,
      ),
      Encounter(
        id: 'running_encounter_$index',
        title: 'Endurance Test',
        description: 'An endurance test pushes your limits.',
        type: EncounterType.fitness,
        location: location,
        rewardXP: 150,
        rewardGold: 75,
        difficulty: EncounterDifficulty.hard,
      ),
    ];
    return encounters[_random.nextInt(encounters.length)];
  }

  Encounter _createClimbingEncounter(LatLng location, int index) {
    final encounters = [
      Encounter(
        id: 'climbing_encounter_$index',
        title: 'Rock Climbing',
        description: 'A perfect spot for rock climbing practice.',
        type: EncounterType.fitness,
        location: location,
        rewardXP: 150,
        rewardGold: 75,
        difficulty: EncounterDifficulty.hard,
      ),
      Encounter(
        id: 'climbing_encounter_$index',
        title: 'Mountain Trail',
        description: 'A challenging mountain trail awaits.',
        type: EncounterType.fitness,
        location: location,
        rewardXP: 200,
        rewardGold: 100,
        difficulty: EncounterDifficulty.expert,
      ),
    ];
    return encounters[_random.nextInt(encounters.length)];
  }

  Encounter _createLocationEncounter(LatLng location, int index) {
    final encounters = [
      Encounter(
        id: 'location_encounter_$index',
        title: 'Historical Site',
        description: 'A historical site reveals fascinating stories.',
        type: EncounterType.exploration,
        location: location,
        rewardXP: 75,
        rewardGold: 40,
        difficulty: EncounterDifficulty.medium,
      ),
      Encounter(
        id: 'location_encounter_$index',
        title: 'Cultural Landmark',
        description: 'A cultural landmark showcases local heritage.',
        type: EncounterType.exploration,
        location: location,
        rewardXP: 100,
        rewardGold: 60,
        difficulty: EncounterDifficulty.medium,
      ),
    ];
    return encounters[_random.nextInt(encounters.length)];
  }

  // Check if player is near an encounter
  bool isNearEncounter(UserLocation playerLocation, Encounter encounter) {
    final distance = _calculateDistance(playerLocation, encounter.location);
    return distance <= 50.0; // 50 meters radius
  }

  // Calculate distance between two points
  double _calculateDistance(UserLocation location1, LatLng location2) {
    // Simple distance calculation (in real app, use proper geolocation formula)
    final latDiff = location1.latitude - location2.latitude;
    final lngDiff = location1.longitude - location2.longitude;
    return (latDiff * latDiff + lngDiff * lngDiff).abs();
  }

  // Complete encounter
  void completeEncounter(Encounter encounter) {
    _activeEncounters.remove(encounter);
    notifyListeners();
  }

  // Add encounter to active list
  void addEncounter(Encounter encounter) {
    _activeEncounters.add(encounter);
    notifyListeners();
  }
}

// Encounter model
class Encounter {
  final String id;
  final String title;
  final String description;
  final EncounterType type;
  final LatLng location;
  final int rewardXP;
  final int rewardGold;
  final EncounterDifficulty difficulty;
  bool isCompleted;

  Encounter({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.location,
    required this.rewardXP,
    required this.rewardGold,
    required this.difficulty,
    this.isCompleted = false,
  });
}

enum EncounterType {
  exploration,
  fitness,
  battle,
  social,
  collection,
}

enum EncounterDifficulty {
  easy,
  medium,
  hard,
  expert,
  legendary,
} 