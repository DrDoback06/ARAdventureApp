import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/character_model.dart';
import '../models/card_model.dart';

class CharacterService {
  static const String _charactersKey = 'saved_characters';
  static const String _currentCharacterKey = 'current_character';
  
  final SharedPreferences _prefs;
  final List<GameCharacter> _characters = [];
  GameCharacter? _currentCharacter;
  
  CharacterService(this._prefs) {
    _loadCharacters();
    _loadCurrentCharacter();
  }
  
  // Force clear corrupted data - useful for testing
  Future<void> clearAllData() async {
    await _clearCorruptedData();
  }
  
  // Character Management
  Future<void> createCharacter(GameCharacter character) async {
    _characters.add(character);
    await _saveCharacters();
    
    // Set as current character if it's the first one
    if (_currentCharacter == null) {
      await setCurrentCharacter(character.id);
    }
  }
  
  List<GameCharacter> getAllCharacters() => List.unmodifiable(_characters);
  
  GameCharacter? getCharacter(String id) {
    try {
      return _characters.firstWhere((character) => character.id == id);
    } catch (e) {
      return null;
    }
  }
  
  GameCharacter? getCurrentCharacter() => _currentCharacter;
  
  Future<void> setCurrentCharacter(String id) async {
    final character = getCharacter(id);
    if (character != null) {
      _currentCharacter = character;
      await _prefs.setString(_currentCharacterKey, id);
    }
  }
  
  Future<void> updateCharacter(GameCharacter updatedCharacter) async {
    final index = _characters.indexWhere((character) => character.id == updatedCharacter.id);
    if (index != -1) {
      _characters[index] = updatedCharacter;
      await _saveCharacters();
      
      // Update current character if it's the one being updated
      if (_currentCharacter?.id == updatedCharacter.id) {
        _currentCharacter = updatedCharacter;
      }
    }
  }
  
  Future<void> deleteCharacter(String id) async {
    _characters.removeWhere((character) => character.id == id);
    await _saveCharacters();
    
    // Clear current character if it was deleted
    if (_currentCharacter?.id == id) {
      _currentCharacter = null;
      await _prefs.remove(_currentCharacterKey);
    }
  }
  
  // Equipment Management
  Future<bool> equipItem(String characterId, CardInstance item) async {
    final character = getCharacter(characterId);
    if (character == null) return false;
    
    // Check if character can equip this item
    if (!_canEquipItem(character, item)) return false;
    
    // Remove from inventory
    final updatedInventory = List<CardInstance>.from(character.inventory);
    updatedInventory.removeWhere((invItem) => invItem.instanceId == item.instanceId);
    
    // Equip the item
    final updatedEquipment = _equipItemToSlot(character.equipment, item);
    
    final updatedCharacter = character.copyWith(
      equipment: updatedEquipment,
      inventory: updatedInventory,
    );
    
    await updateCharacter(updatedCharacter);
    return true;
  }
  
  Future<bool> unequipItem(String characterId, EquipmentSlot slot) async {
    final character = getCharacter(characterId);
    if (character == null) return false;
    
    final equippedItem = _getEquippedItem(character.equipment, slot);
    if (equippedItem == null) return false;
    
    // Check if there's space in inventory
    if (character.inventory.length >= 40) return false; // 8x5 inventory grid
    
    // Remove from equipment
    final updatedEquipment = _unequipItemFromSlot(character.equipment, slot);
    
    // Add to inventory
    final updatedInventory = List<CardInstance>.from(character.inventory);
    updatedInventory.add(equippedItem);
    
    final updatedCharacter = character.copyWith(
      equipment: updatedEquipment,
      inventory: updatedInventory,
    );
    
    await updateCharacter(updatedCharacter);
    return true;
  }
  
  // Inventory Management
  Future<bool> addToInventory(String characterId, CardInstance item) async {
    final character = getCharacter(characterId);
    if (character == null) return false;
    
    // Check if inventory has space
    if (character.inventory.length >= 40) return false;
    
    final updatedInventory = List<CardInstance>.from(character.inventory);
    updatedInventory.add(item);
    
    final updatedCharacter = character.copyWith(inventory: updatedInventory);
    await updateCharacter(updatedCharacter);
    return true;
  }
  
  Future<bool> removeFromInventory(String characterId, String itemInstanceId) async {
    final character = getCharacter(characterId);
    if (character == null) return false;
    
    final updatedInventory = List<CardInstance>.from(character.inventory);
    updatedInventory.removeWhere((item) => item.instanceId == itemInstanceId);
    
    final updatedCharacter = character.copyWith(inventory: updatedInventory);
    await updateCharacter(updatedCharacter);
    return true;
  }
  
  Future<bool> moveToStash(String characterId, String itemInstanceId) async {
    final character = getCharacter(characterId);
    if (character == null) return false;
    
    final item = character.inventory.firstWhere(
      (item) => item.instanceId == itemInstanceId,
      orElse: () => throw Exception('Item not found'),
    );
    
    // Check if stash has space
    if (character.stash.length >= 48) return false; // 8x6 stash grid
    
    final updatedInventory = List<CardInstance>.from(character.inventory);
    updatedInventory.removeWhere((invItem) => invItem.instanceId == itemInstanceId);
    
    final updatedStash = List<CardInstance>.from(character.stash);
    updatedStash.add(item);
    
    final updatedCharacter = character.copyWith(
      inventory: updatedInventory,
      stash: updatedStash,
    );
    
    await updateCharacter(updatedCharacter);
    return true;
  }
  
  Future<bool> moveFromStash(String characterId, String itemInstanceId) async {
    final character = getCharacter(characterId);
    if (character == null) return false;
    
    final item = character.stash.firstWhere(
      (item) => item.instanceId == itemInstanceId,
      orElse: () => throw Exception('Item not found'),
    );
    
    // Check if inventory has space
    if (character.inventory.length >= 40) return false;
    
    final updatedStash = List<CardInstance>.from(character.stash);
    updatedStash.removeWhere((stashItem) => stashItem.instanceId == itemInstanceId);
    
    final updatedInventory = List<CardInstance>.from(character.inventory);
    updatedInventory.add(item);
    
    final updatedCharacter = character.copyWith(
      inventory: updatedInventory,
      stash: updatedStash,
    );
    
    await updateCharacter(updatedCharacter);
    return true;
  }
  
  // Character Progression
  Future<bool> allocateStatPoint(String characterId, String statName) async {
    final character = getCharacter(characterId);
    if (character == null || character.availableStatPoints <= 0) return false;
    
    GameCharacter updatedCharacter;
    
    switch (statName.toLowerCase()) {
      case 'strength':
        updatedCharacter = character.copyWith(
          allocatedStrength: character.allocatedStrength + 1,
          availableStatPoints: character.availableStatPoints - 1,
        );
        break;
      case 'dexterity':
        updatedCharacter = character.copyWith(
          allocatedDexterity: character.allocatedDexterity + 1,
          availableStatPoints: character.availableStatPoints - 1,
        );
        break;
      case 'vitality':
        updatedCharacter = character.copyWith(
          allocatedVitality: character.allocatedVitality + 1,
          availableStatPoints: character.availableStatPoints - 1,
        );
        break;
      case 'energy':
        updatedCharacter = character.copyWith(
          allocatedEnergy: character.allocatedEnergy + 1,
          availableStatPoints: character.availableStatPoints - 1,
        );
        break;
      default:
        return false;
    }
    
    await updateCharacter(updatedCharacter);
    return true;
  }
  
  Future<bool> addExperience(String characterId, int experience) async {
    final character = getCharacter(characterId);
    if (character == null) return false;
    
    int newExperience = character.experience + experience;
    int newLevel = character.level;
    int newAvailableStatPoints = character.availableStatPoints;
    int newAvailableSkillPoints = character.availableSkillPoints;
    
    // Check for level ups
    while (newExperience >= character.experienceToNext) {
      newExperience -= character.experienceToNext;
      newLevel++;
      newAvailableStatPoints += 5; // 5 stat points per level
      newAvailableSkillPoints += 1; // 1 skill point per level
    }
    
    final updatedCharacter = character.copyWith(
      experience: newExperience,
      level: newLevel,
      availableStatPoints: newAvailableStatPoints,
      availableSkillPoints: newAvailableSkillPoints,
      experienceToNext: _calculateExperienceToNext(newLevel),
    );
    
    await updateCharacter(updatedCharacter);
    return true;
  }
  
  // Skill Management
  Future<bool> learnSkill(String characterId, Skill skill) async {
    final character = getCharacter(characterId);
    if (character == null || character.availableSkillPoints <= 0) return false;
    
    // Check if character already knows this skill
    if (character.skills.any((s) => s.id == skill.id)) return false;
    
    // Check class requirement
    if (skill.requiredClass != character.characterClass) return false;
    
    // Check prerequisites
    for (final prerequisite in skill.prerequisites) {
      if (!character.skills.any((s) => s.id == prerequisite)) {
        return false;
      }
    }
    
    final updatedSkills = List<Skill>.from(character.skills);
    updatedSkills.add(skill);
    
    final updatedCharacter = character.copyWith(
      skills: updatedSkills,
      availableSkillPoints: character.availableSkillPoints - 1,
    );
    
    await updateCharacter(updatedCharacter);
    return true;
  }
  
  Future<bool> upgradeSkill(String characterId, String skillId) async {
    final character = getCharacter(characterId);
    if (character == null || character.availableSkillPoints <= 0) return false;
    
    final skillIndex = character.skills.indexWhere((s) => s.id == skillId);
    if (skillIndex == -1) return false;
    
    final skill = character.skills[skillIndex];
    if (skill.level >= skill.maxLevel) return false;
    
    final updatedSkills = List<Skill>.from(character.skills);
    updatedSkills[skillIndex] = skill.copyWith(level: skill.level + 1);
    
    final updatedCharacter = character.copyWith(
      skills: updatedSkills,
      availableSkillPoints: character.availableSkillPoints - 1,
    );
    
    await updateCharacter(updatedCharacter);
    return true;
  }
  
  // Utility Methods
  bool canEquipItem(String characterId, CardInstance item) {
    final character = getCharacter(characterId);
    if (character == null) return false;
    return _canEquipItem(character, item);
  }
  
  List<CardInstance> getEquippedItems(String characterId) {
    final character = getCharacter(characterId);
    if (character == null) return [];
    return character.equipment.getAllEquippedItems();
  }
  
  Map<String, dynamic> getCharacterStats(String characterId) {
    final character = getCharacter(characterId);
    if (character == null) return {};
    
    return {
      'strength': character.totalStrength,
      'dexterity': character.totalDexterity,
      'vitality': character.totalVitality,
      'energy': character.totalEnergy,
      'health': character.maxHealth,
      'mana': character.maxMana,
      'attack': character.attackRating,
      'defense': character.defense,
      'level': character.level,
      'experience': character.experience,
      'experienceToNext': character.experienceToNext,
    };
  }
  
  // Private helper methods
  void _loadCharacters() {
    final charactersJson = _prefs.getString(_charactersKey);
    if (charactersJson != null) {
      final charactersList = jsonDecode(charactersJson) as List;
      _characters.clear();
      _characters.addAll(charactersList.map((json) => GameCharacter.fromJson(json)));
    }
  }
  
  Future<void> _saveCharacters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clean up characters before saving to remove any null values
      final cleanedCharacters = _characters.map((character) {
        return character.copyWith(
          inventory: character.inventory.where((item) => item != null).toList(),
          stash: character.stash.where((item) => item != null).toList(),
          skillSlots: character.skillSlots.where((item) => item != null).toList(),
        );
      }).toList();
      
      final charactersJson = cleanedCharacters.map((c) => c.toJson()).toList();
      await prefs.setString('characters', jsonEncode(charactersJson));
      
      if (_currentCharacter?.id != null) {
        await prefs.setString('currentCharacterId', _currentCharacter!.id);
      }
    } catch (e) {
      print('Error saving characters: $e');
      // Clear corrupted data and start fresh
      await _clearCorruptedData();
    }
  }
  
  Future<void> _clearCorruptedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('characters');
      await prefs.remove('currentCharacterId');
      _characters.clear();
      _currentCharacter = null;
      print('Cleared corrupted character data');
    } catch (e) {
      print('Error clearing corrupted data: $e');
    }
  }
  
  void _loadCurrentCharacter() {
    final currentCharacterId = _prefs.getString(_currentCharacterKey);
    if (currentCharacterId != null) {
      _currentCharacter = getCharacter(currentCharacterId);
    }
  }
  
  bool _canEquipItem(GameCharacter character, CardInstance item) {
    // Check level requirement
    if (character.level < item.card.levelRequirement) return false;
    
    // Check class requirement
    if (item.card.allowedClasses.isNotEmpty && 
        !item.card.allowedClasses.contains(character.characterClass)) {
      return false;
    }
    
    // Check if item is equippable
    if (item.card.equipmentSlot == EquipmentSlot.none) return false;
    
    return true;
  }
  
  Equipment _equipItemToSlot(Equipment equipment, CardInstance item) {
    switch (item.card.equipmentSlot) {
      case EquipmentSlot.helmet:
        return equipment.copyWith(helmet: item);
      case EquipmentSlot.armor:
        return equipment.copyWith(armor: item);
      case EquipmentSlot.weapon1:
        return equipment.copyWith(weapon1: item);
      case EquipmentSlot.weapon2:
        return equipment.copyWith(weapon2: item);
      case EquipmentSlot.gloves:
        return equipment.copyWith(gloves: item);
      case EquipmentSlot.boots:
        return equipment.copyWith(boots: item);
      case EquipmentSlot.belt:
        return equipment.copyWith(belt: item);
      case EquipmentSlot.ring1:
        return equipment.copyWith(ring1: item);
      case EquipmentSlot.ring2:
        return equipment.copyWith(ring2: item);
      case EquipmentSlot.amulet:
        return equipment.copyWith(amulet: item);
      default:
        return equipment;
    }
  }
  
  Equipment _unequipItemFromSlot(Equipment equipment, EquipmentSlot slot) {
    switch (slot) {
      case EquipmentSlot.helmet:
        return equipment.copyWith(helmet: null);
      case EquipmentSlot.armor:
        return equipment.copyWith(armor: null);
      case EquipmentSlot.weapon1:
        return equipment.copyWith(weapon1: null);
      case EquipmentSlot.weapon2:
        return equipment.copyWith(weapon2: null);
      case EquipmentSlot.gloves:
        return equipment.copyWith(gloves: null);
      case EquipmentSlot.boots:
        return equipment.copyWith(boots: null);
      case EquipmentSlot.belt:
        return equipment.copyWith(belt: null);
      case EquipmentSlot.ring1:
        return equipment.copyWith(ring1: null);
      case EquipmentSlot.ring2:
        return equipment.copyWith(ring2: null);
      case EquipmentSlot.amulet:
        return equipment.copyWith(amulet: null);
      default:
        return equipment;
    }
  }
  
  CardInstance? _getEquippedItem(Equipment equipment, EquipmentSlot slot) {
    switch (slot) {
      case EquipmentSlot.helmet:
        return equipment.helmet;
      case EquipmentSlot.armor:
        return equipment.armor;
      case EquipmentSlot.weapon1:
        return equipment.weapon1;
      case EquipmentSlot.weapon2:
        return equipment.weapon2;
      case EquipmentSlot.gloves:
        return equipment.gloves;
      case EquipmentSlot.boots:
        return equipment.boots;
      case EquipmentSlot.belt:
        return equipment.belt;
      case EquipmentSlot.ring1:
        return equipment.ring1;
      case EquipmentSlot.ring2:
        return equipment.ring2;
      case EquipmentSlot.amulet:
        return equipment.amulet;
      default:
        return null;
    }
  }
  
  int _calculateExperienceToNext(int level) {
    return level * 1000; // Simple formula, can be made more complex
  }
}