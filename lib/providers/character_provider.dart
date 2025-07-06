import 'package:flutter/foundation.dart';
import '../models/character_model.dart';
import '../models/card_model.dart';
import '../services/character_service.dart';

/// Provider for managing character state and operations
class CharacterProvider extends ChangeNotifier {
  final CharacterService _characterService = CharacterService();
  
  // Current state
  List<GameCharacter> _characters = [];
  GameCharacter? _selectedCharacter;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<GameCharacter> get characters => _characters;
  GameCharacter? get selectedCharacter => _selectedCharacter;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// Sets loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// Sets error state
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
  
  /// Loads all characters for a player
  Future<void> loadPlayerCharacters(String playerId) async {
    _setLoading(true);
    _setError(null);
    
    try {
      _characters = await _characterService.getPlayerCharacters(playerId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load characters: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Selects a character
  void selectCharacter(GameCharacter character) {
    _selectedCharacter = character;
    notifyListeners();
  }
  
  /// Creates a new character
  Future<String?> createCharacter(GameCharacter character) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final characterId = await _characterService.createCharacter(character);
      _characters.add(character);
      notifyListeners();
      return characterId;
    } catch (e) {
      _setError('Failed to create character: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Updates a character
  Future<bool> updateCharacter(GameCharacter character) async {
    _setLoading(true);
    _setError(null);
    
    try {
      await _characterService.updateCharacter(character);
      
      // Update in local list
      final index = _characters.indexWhere((c) => c.id == character.id);
      if (index != -1) {
        _characters[index] = character;
      }
      
      // Update selected character if it's the same one
      if (_selectedCharacter?.id == character.id) {
        _selectedCharacter = character;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update character: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Deletes a character
  Future<bool> deleteCharacter(String characterId) async {
    _setLoading(true);
    _setError(null);
    
    try {
      await _characterService.deleteCharacter(characterId);
      
      // Remove from local list
      _characters.removeWhere((c) => c.id == characterId);
      
      // Clear selected character if it was deleted
      if (_selectedCharacter?.id == characterId) {
        _selectedCharacter = null;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete character: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Equips an item to a character
  Future<bool> equipItem(String characterId, CardInstance item) async {
    _setError(null);
    
    try {
      final updatedCharacter = await _characterService.equipItem(characterId, item);
      
      // Update in local list
      final index = _characters.indexWhere((c) => c.id == characterId);
      if (index != -1) {
        _characters[index] = updatedCharacter;
      }
      
      // Update selected character if it's the same one
      if (_selectedCharacter?.id == characterId) {
        _selectedCharacter = updatedCharacter;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to equip item: $e');
      return false;
    }
  }
  
  /// Unequips an item from a character
  Future<bool> unequipItem(String characterId, EquipmentSlot slot) async {
    _setError(null);
    
    try {
      final updatedCharacter = await _characterService.unequipItem(characterId, slot);
      
      // Update in local list
      final index = _characters.indexWhere((c) => c.id == characterId);
      if (index != -1) {
        _characters[index] = updatedCharacter;
      }
      
      // Update selected character if it's the same one
      if (_selectedCharacter?.id == characterId) {
        _selectedCharacter = updatedCharacter;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to unequip item: $e');
      return false;
    }
  }
  
  /// Adds an item to character's inventory
  Future<bool> addItemToInventory(String characterId, CardInstance item) async {
    _setError(null);
    
    try {
      final updatedCharacter = await _characterService.addItemToInventory(characterId, item);
      
      // Update in local list
      final index = _characters.indexWhere((c) => c.id == characterId);
      if (index != -1) {
        _characters[index] = updatedCharacter;
      }
      
      // Update selected character if it's the same one
      if (_selectedCharacter?.id == characterId) {
        _selectedCharacter = updatedCharacter;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add item to inventory: $e');
      return false;
    }
  }
  
  /// Removes an item from character's inventory
  Future<bool> removeItemFromInventory(String characterId, String itemInstanceId) async {
    _setError(null);
    
    try {
      final updatedCharacter = await _characterService.removeItemFromInventory(characterId, itemInstanceId);
      
      // Update in local list
      final index = _characters.indexWhere((c) => c.id == characterId);
      if (index != -1) {
        _characters[index] = updatedCharacter;
      }
      
      // Update selected character if it's the same one
      if (_selectedCharacter?.id == characterId) {
        _selectedCharacter = updatedCharacter;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to remove item from inventory: $e');
      return false;
    }
  }
  
  /// Moves an item from inventory to stash
  Future<bool> moveItemToStash(String characterId, String itemInstanceId) async {
    _setError(null);
    
    try {
      final updatedCharacter = await _characterService.moveItemToStash(characterId, itemInstanceId);
      
      // Update in local list
      final index = _characters.indexWhere((c) => c.id == characterId);
      if (index != -1) {
        _characters[index] = updatedCharacter;
      }
      
      // Update selected character if it's the same one
      if (_selectedCharacter?.id == characterId) {
        _selectedCharacter = updatedCharacter;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to move item to stash: $e');
      return false;
    }
  }
  
  /// Moves an item from stash to inventory
  Future<bool> moveItemFromStash(String characterId, String itemInstanceId) async {
    _setError(null);
    
    try {
      final updatedCharacter = await _characterService.moveItemFromStash(characterId, itemInstanceId);
      
      // Update in local list
      final index = _characters.indexWhere((c) => c.id == characterId);
      if (index != -1) {
        _characters[index] = updatedCharacter;
      }
      
      // Update selected character if it's the same one
      if (_selectedCharacter?.id == characterId) {
        _selectedCharacter = updatedCharacter;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to move item from stash: $e');
      return false;
    }
  }
  
  /// Levels up a character
  Future<bool> levelUpCharacter(String characterId) async {
    _setError(null);
    
    try {
      final updatedCharacter = await _characterService.levelUpCharacter(characterId);
      
      // Update in local list
      final index = _characters.indexWhere((c) => c.id == characterId);
      if (index != -1) {
        _characters[index] = updatedCharacter;
      }
      
      // Update selected character if it's the same one
      if (_selectedCharacter?.id == characterId) {
        _selectedCharacter = updatedCharacter;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to level up character: $e');
      return false;
    }
  }
  
  /// Allocates stat points to a character
  Future<bool> allocateStatPoints(
    String characterId,
    int strengthPoints,
    int dexterityPoints,
    int vitalityPoints,
    int energyPoints,
  ) async {
    _setError(null);
    
    try {
      final updatedCharacter = await _characterService.allocateStatPoints(
        characterId,
        strengthPoints,
        dexterityPoints,
        vitalityPoints,
        energyPoints,
      );
      
      // Update in local list
      final index = _characters.indexWhere((c) => c.id == characterId);
      if (index != -1) {
        _characters[index] = updatedCharacter;
      }
      
      // Update selected character if it's the same one
      if (_selectedCharacter?.id == characterId) {
        _selectedCharacter = updatedCharacter;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to allocate stat points: $e');
      return false;
    }
  }
  
  /// Adds experience to a character
  Future<bool> addExperience(String characterId, int experiencePoints) async {
    _setError(null);
    
    try {
      final updatedCharacter = await _characterService.addExperience(characterId, experiencePoints);
      
      // Update in local list
      final index = _characters.indexWhere((c) => c.id == characterId);
      if (index != -1) {
        _characters[index] = updatedCharacter;
      }
      
      // Update selected character if it's the same one
      if (_selectedCharacter?.id == characterId) {
        _selectedCharacter = updatedCharacter;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add experience: $e');
      return false;
    }
  }
  
  /// Updates character's health
  Future<bool> updateHealth(String characterId, int newHealth) async {
    _setError(null);
    
    try {
      final updatedCharacter = await _characterService.updateHealth(characterId, newHealth);
      
      // Update in local list
      final index = _characters.indexWhere((c) => c.id == characterId);
      if (index != -1) {
        _characters[index] = updatedCharacter;
      }
      
      // Update selected character if it's the same one
      if (_selectedCharacter?.id == characterId) {
        _selectedCharacter = updatedCharacter;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update health: $e');
      return false;
    }
  }
  
  /// Updates character's mana
  Future<bool> updateMana(String characterId, int newMana) async {
    _setError(null);
    
    try {
      final updatedCharacter = await _characterService.updateMana(characterId, newMana);
      
      // Update in local list
      final index = _characters.indexWhere((c) => c.id == characterId);
      if (index != -1) {
        _characters[index] = updatedCharacter;
      }
      
      // Update selected character if it's the same one
      if (_selectedCharacter?.id == characterId) {
        _selectedCharacter = updatedCharacter;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update mana: $e');
      return false;
    }
  }
  
  /// Refreshes a character's data from the server
  Future<bool> refreshCharacter(String characterId) async {
    _setError(null);
    
    try {
      final character = await _characterService.getCharacter(characterId);
      if (character == null) {
        _setError('Character not found');
        return false;
      }
      
      // Update in local list
      final index = _characters.indexWhere((c) => c.id == characterId);
      if (index != -1) {
        _characters[index] = character;
      }
      
      // Update selected character if it's the same one
      if (_selectedCharacter?.id == characterId) {
        _selectedCharacter = character;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to refresh character: $e');
      return false;
    }
  }
  
  /// Gets a character by ID from the local list
  GameCharacter? getCharacterById(String characterId) {
    try {
      return _characters.firstWhere((c) => c.id == characterId);
    } catch (e) {
      return null;
    }
  }
  
  /// Gets characters by class
  List<GameCharacter> getCharactersByClass(CharacterClass characterClass) {
    return _characters.where((c) => c.characterClass == characterClass).toList();
  }
  
  /// Gets characters by level range
  List<GameCharacter> getCharactersByLevelRange(int minLevel, int maxLevel) {
    return _characters.where((c) => c.level >= minLevel && c.level <= maxLevel).toList();
  }
  
  /// Clears all character data
  void clearCharacters() {
    _characters.clear();
    _selectedCharacter = null;
    _error = null;
    notifyListeners();
  }
  
  /// Clears error state
  void clearError() {
    _error = null;
    notifyListeners();
  }
}