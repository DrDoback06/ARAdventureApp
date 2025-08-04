import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/specialization_system.dart';
import '../models/character_model.dart';
import '../models/card_model.dart';

class SpecializationService {
  static const String _specializationsKey = 'character_specializations';
  
  final SharedPreferences _prefs;
  final Map<String, Map<String, dynamic>> _characterSpecializations = {};

  SpecializationService(this._prefs) {
    _loadSpecializations();
  }

  /// Load specializations from storage
  void _loadSpecializations() {
    final data = _prefs.getString(_specializationsKey);
    if (data != null) {
      final Map<String, dynamic> json = jsonDecode(data);
      _characterSpecializations.clear();
      json.forEach((characterId, specializations) {
        _characterSpecializations[characterId] = Map<String, dynamic>.from(specializations);
      });
    }
  }

  /// Save specializations to storage
  Future<void> _saveSpecializations() async {
    final data = jsonEncode(_characterSpecializations);
    await _prefs.setString(_specializationsKey, data);
  }

  /// Get specialization tree for a character class
  SpecializationTree? getSpecializationTree(CharacterClass characterClass) {
    return SpecializationSystem.getSpecializationTree(characterClass);
  }

  /// Get character's current specializations
  Map<String, dynamic> getCharacterSpecializations(String characterId) {
    return _characterSpecializations[characterId] ?? {};
  }

  /// Unlock a specialization node
  Future<bool> unlockSpecialization(String characterId, String nodeId, GameCharacter character) async {
    final tree = getSpecializationTree(character.characterClass);
    if (tree == null) return false;

    final node = tree.nodes.firstWhere((n) => n.id == nodeId);
    if (!_canUnlockNode(node, character, tree)) return false;

    // Deduct skill points
    final updatedCharacter = character.copyWith(
      availableSkillPoints: character.availableSkillPoints - node.cost,
    );

    // Update specializations
    final characterSpecs = Map<String, dynamic>.from(getCharacterSpecializations(characterId));
    characterSpecs[nodeId] = {
      'unlocked': true,
      'active': false,
      'unlockedAt': DateTime.now().toIso8601String(),
    };
    _characterSpecializations[characterId] = characterSpecs;

    await _saveSpecializations();
    return true;
  }

  /// Check if a node can be unlocked
  bool _canUnlockNode(SpecializationNode node, GameCharacter character, SpecializationTree tree) {
    if (node.isUnlocked) return false;
    
    // Check skill points
    if (character.availableSkillPoints < node.cost) return false;
    
    // Check prerequisites
    for (final prerequisiteId in node.prerequisites) {
      final prerequisite = tree.nodes.firstWhere((n) => n.id == prerequisiteId);
      if (!prerequisite.isUnlocked) return false;
    }
    
    return true;
  }

  /// Activate a specialization
  Future<bool> activateSpecialization(String characterId, String nodeId, CharacterClass characterClass) async {
    final characterSpecs = getCharacterSpecializations(characterId);
    if (!characterSpecs.containsKey(nodeId) || !characterSpecs[nodeId]['unlocked']) {
      return false;
    }

    // Check if we can activate more specializations
    final activeCount = characterSpecs.values.where((spec) => spec['active'] == true).length;
    final tree = getSpecializationTree(characterClass);
    if (tree != null && activeCount >= tree.maxActiveNodes) {
      return false;
    }

    // Activate the specialization
    characterSpecs[nodeId]['active'] = true;
    _characterSpecializations[characterId] = characterSpecs;

    await _saveSpecializations();
    return true;
  }

  /// Deactivate a specialization
  Future<bool> deactivateSpecialization(String characterId, String nodeId) async {
    final characterSpecs = getCharacterSpecializations(characterId);
    if (!characterSpecs.containsKey(nodeId)) return false;

    characterSpecs[nodeId]['active'] = false;
    _characterSpecializations[characterId] = characterSpecs;

    await _saveSpecializations();
    return true;
  }

  /// Get active specializations for a character
  List<Map<String, dynamic>> getActiveSpecializations(String characterId) {
    final characterSpecs = getCharacterSpecializations(characterId);
    return characterSpecs.entries
        .where((entry) => entry.value['active'] == true)
        .map((entry) => <String, dynamic>{
              'nodeId': entry.key,
              ...entry.value,
            })
        .toList();
  }

  /// Calculate total effects from active specializations
  Map<String, dynamic> calculateSpecializationEffects(String characterId, CharacterClass characterClass) {
    final tree = getSpecializationTree(characterClass);
    if (tree == null) return {};

    final activeSpecs = getActiveSpecializations(characterId);
    final effects = <String, dynamic>{};

    for (final spec in activeSpecs) {
      final node = tree.nodes.firstWhere((n) => n.id == spec['nodeId']);
      for (final entry in node.effects.entries) {
        final key = entry.key;
        final value = entry.value;

        if (effects.containsKey(key)) {
          // Combine effects
          if (value is num && effects[key] is num) {
            effects[key] = (effects[key] as num) + value;
          } else if (value is List && effects[key] is List) {
            (effects[key] as List).addAll(value);
          }
        } else {
          effects[key] = value;
        }
      }
    }

    return effects;
  }

  /// Apply specialization effects to a character
  GameCharacter applySpecializationEffects(GameCharacter character) {
    final effects = calculateSpecializationEffects(character.id, character.characterClass);
    
    // Apply stat bonuses
    if (effects.containsKey('stat_bonus')) {
      final bonus = effects['stat_bonus'] as double;
      // Apply to base stats
      character = character.copyWith(
        baseStrength: (character.baseStrength * (1 + bonus)).round(),
        baseDexterity: (character.baseDexterity * (1 + bonus)).round(),
        baseVitality: (character.baseVitality * (1 + bonus)).round(),
        baseEnergy: (character.baseEnergy * (1 + bonus)).round(),
      );
    }

    // Apply damage bonuses
    if (effects.containsKey('damage_bonus')) {
      final bonus = effects['damage_bonus'] as double;
      // This would be applied during battle calculations
    }

    // Apply healing bonuses
    if (effects.containsKey('healing_bonus')) {
      final bonus = effects['healing_bonus'] as double;
      // This would be applied during healing calculations
    }

    return character;
  }

  /// Get available specializations for a character
  List<SpecializationNode> getAvailableSpecializations(GameCharacter character) {
    final tree = getSpecializationTree(character.characterClass);
    if (tree == null) return [];

    return tree.getAvailableNodes(character);
  }

  /// Get unlocked specializations for a character
  List<SpecializationNode> getUnlockedSpecializations(String characterId, CharacterClass characterClass) {
    final tree = getSpecializationTree(characterClass);
    if (tree == null) return [];

    final characterSpecs = getCharacterSpecializations(characterId);
    return tree.nodes.where((node) => 
        characterSpecs.containsKey(node.id) && characterSpecs[node.id]['unlocked'] == true
    ).toList();
  }

  /// Reset all specializations for a character (for respec)
  Future<void> resetSpecializations(String characterId) async {
    _characterSpecializations.remove(characterId);
    await _saveSpecializations();
  }

  /// Get specialization progress for a character
  Map<String, dynamic> getSpecializationProgress(String characterId, CharacterClass characterClass) {
    final tree = getSpecializationTree(characterClass);
    if (tree == null) return {};

    final characterSpecs = getCharacterSpecializations(characterId);
    final unlockedCount = characterSpecs.values.where((spec) => spec['unlocked'] == true).length;
    final activeCount = characterSpecs.values.where((spec) => spec['active'] == true).length;

    return {
      'totalNodes': tree.nodes.length,
      'unlockedNodes': unlockedCount,
      'activeNodes': activeCount,
      'maxActiveNodes': tree.maxActiveNodes,
      'progress': unlockedCount / tree.nodes.length,
    };
  }
} 