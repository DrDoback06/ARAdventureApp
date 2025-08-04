import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/character_model.dart';
import '../models/adventure_map_model.dart';

class CombatService extends ChangeNotifier {
  static final CombatService _instance = CombatService._internal();
  factory CombatService() => _instance;
  CombatService._internal();

  List<LegendaryEncounter> _legendaryEncounters = [];
  List<CombatEvent> _activeCombatEvents = [];
  final Random _random = Random();

  // Getters
  List<LegendaryEncounter> get legendaryEncounters => _legendaryEncounters;
  List<CombatEvent> get activeCombatEvents => _activeCombatEvents;

  // Check for nearby enemies
  void checkNearbyEnemies(UserLocation location) {
    // Generate random encounters based on location
    if (_random.nextDouble() < 0.1) { // 10% chance
      _generateLegendaryEncounter(location);
    }
  }

  // Generate legendary encounter
  void _generateLegendaryEncounter(UserLocation location) {
    final encounter = LegendaryEncounter(
      id: 'encounter_${DateTime.now().millisecondsSinceEpoch}',
      name: _generateEncounterName(),
      description: _generateEncounterDescription(),
      location: LatLng(location.latitude, location.longitude),
      difficulty: _calculateEncounterDifficulty(location),
      rewards: _generateEncounterRewards(),
      isActive: true,
      expiresAt: DateTime.now().add(const Duration(hours: 2)),
    );

    _legendaryEncounters.add(encounter);
    notifyListeners();
  }

  // Start legendary encounter
  void startLegendaryEncounter(LegendaryEncounter encounter) {
    final combatEvent = CombatEvent(
      id: 'combat_${DateTime.now().millisecondsSinceEpoch}',
      encounter: encounter,
      startTime: DateTime.now(),
      isActive: true,
    );

    _activeCombatEvents.add(combatEvent);
    encounter.isActive = false;
    notifyListeners();
  }

  // Get legendary encounters
  List<LegendaryEncounter> getLegendaryEncounters() {
    return _legendaryEncounters.where((e) => e.isActive).toList();
  }

  // Generate encounter name
  String _generateEncounterName() {
    final names = [
      'Ancient Guardian',
      'Shadow Assassin',
      'Crystal Golem',
      'Storm Dragon',
      'Void Walker',
      'Time Bender',
      'Elemental Master',
      'Chaos Bringer',
    ];
    return names[_random.nextInt(names.length)];
  }

  // Generate encounter description
  String _generateEncounterDescription() {
    final descriptions = [
      'A powerful entity has appeared in this area. Approach with caution.',
      'Ancient magic emanates from this location. A legendary foe awaits.',
      'The air crackles with energy. A formidable opponent has been spotted.',
      'Dark forces have gathered here. Only the strongest can prevail.',
    ];
    return descriptions[_random.nextInt(descriptions.length)];
  }

  // Calculate encounter difficulty
  EncounterDifficulty _calculateEncounterDifficulty(UserLocation location) {
    // Base difficulty on time, location, etc.
    final hour = DateTime.now().hour;
    if (hour >= 22 || hour <= 6) {
      return EncounterDifficulty.legendary; // Night encounters are harder
    }
    
    final difficulties = EncounterDifficulty.values;
    return difficulties[_random.nextInt(difficulties.length)];
  }

  // Generate encounter rewards
  Map<String, dynamic> _generateEncounterRewards() {
    return {
      'experience': 500 + _random.nextInt(500),
      'gold': 100 + _random.nextInt(200),
      'items': _random.nextInt(3),
      'special': _random.nextBool(),
    };
  }

  // Clean up expired encounters
  void _cleanupExpiredEncounters() {
    final now = DateTime.now();
    _legendaryEncounters.removeWhere((e) => 
      e.expiresAt != null && e.expiresAt!.isBefore(now)
    );
    _activeCombatEvents.removeWhere((e) => 
      e.startTime.isBefore(now.subtract(const Duration(hours: 1)))
    );
  }

  // Dispose
  @override
  void dispose() {
    _legendaryEncounters.clear();
    _activeCombatEvents.clear();
    super.dispose();
  }
}

// Combat Models
class LegendaryEncounter {
  final String id;
  final String name;
  final String description;
  final LatLng location;
  final EncounterDifficulty difficulty;
  final Map<String, dynamic> rewards;
  bool isActive;
  final DateTime? expiresAt;

  LegendaryEncounter({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.difficulty,
    required this.rewards,
    this.isActive = true,
    this.expiresAt,
  });
}

class CombatEvent {
  final String id;
  final LegendaryEncounter encounter;
  final DateTime startTime;
  bool isActive;

  CombatEvent({
    required this.id,
    required this.encounter,
    required this.startTime,
    this.isActive = true,
  });
}

enum EncounterDifficulty {
  easy,
  medium,
  hard,
  epic,
  legendary,
} 