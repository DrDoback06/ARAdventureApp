import 'package:flutter/foundation.dart';
import '../models/character_model.dart';
import '../models/card_model.dart';
import '../services/character_service.dart';

class CharacterProvider with ChangeNotifier {
  final CharacterService _characterService;
  
  CharacterProvider(this._characterService);
  
  GameCharacter? get currentCharacter => _characterService.getCurrentCharacter();
  List<GameCharacter> get allCharacters => _characterService.getAllCharacters();
  
  // Character Management
  Future<void> createCharacter(GameCharacter character) async {
    await _characterService.createCharacter(character);
    notifyListeners();
  }
  
  Future<void> setCurrentCharacter(String id) async {
    await _characterService.setCurrentCharacter(id);
    notifyListeners();
  }
  
  Future<void> updateCharacter(GameCharacter character) async {
    await _characterService.updateCharacter(character);
    notifyListeners();
  }
  
  Future<void> deleteCharacter(String id) async {
    await _characterService.deleteCharacter(id);
    notifyListeners();
  }
  
  // Equipment Management
  Future<bool> equipItem(CardInstance item) async {
    final character = currentCharacter;
    if (character == null) return false;
    
    final success = await _characterService.equipItem(character.id, item);
    if (success) {
      notifyListeners();
    }
    return success;
  }
  
  Future<bool> unequipItem(EquipmentSlot slot) async {
    final character = currentCharacter;
    if (character == null) return false;
    
    final success = await _characterService.unequipItem(character.id, slot);
    if (success) {
      notifyListeners();
    }
    return success;
  }
  
  // Inventory Management
  Future<bool> addToInventory(CardInstance item) async {
    final character = currentCharacter;
    if (character == null) return false;
    
    final success = await _characterService.addToInventory(character.id, item);
    if (success) {
      notifyListeners();
    }
    return success;
  }
  
  Future<bool> removeFromInventory(String itemInstanceId) async {
    final character = currentCharacter;
    if (character == null) return false;
    
    final success = await _characterService.removeFromInventory(character.id, itemInstanceId);
    if (success) {
      notifyListeners();
    }
    return success;
  }
  
  Future<bool> moveToStash(String itemInstanceId) async {
    final character = currentCharacter;
    if (character == null) return false;
    
    final success = await _characterService.moveToStash(character.id, itemInstanceId);
    if (success) {
      notifyListeners();
    }
    return success;
  }
  
  Future<bool> moveFromStash(String itemInstanceId) async {
    final character = currentCharacter;
    if (character == null) return false;
    
    final success = await _characterService.moveFromStash(character.id, itemInstanceId);
    if (success) {
      notifyListeners();
    }
    return success;
  }
  
  // Character Progression
  Future<bool> allocateStatPoint(String statName) async {
    final character = currentCharacter;
    if (character == null) return false;
    
    final success = await _characterService.allocateStatPoint(character.id, statName);
    if (success) {
      notifyListeners();
    }
    return success;
  }
  
  Future<bool> addExperience(int experience) async {
    final character = currentCharacter;
    if (character == null) return false;
    
    final success = await _characterService.addExperience(character.id, experience);
    if (success) {
      notifyListeners();
    }
    return success;
  }
  
  // Skill Management
  Future<bool> learnSkill(Skill skill) async {
    final character = currentCharacter;
    if (character == null) return false;
    
    final success = await _characterService.learnSkill(character.id, skill);
    if (success) {
      notifyListeners();
    }
    return success;
  }
  
  Future<bool> upgradeSkill(String skillId) async {
    final character = currentCharacter;
    if (character == null) return false;
    
    final success = await _characterService.upgradeSkill(character.id, skillId);
    if (success) {
      notifyListeners();
    }
    return success;
  }
  
  // Utility Methods
  bool canEquipItem(CardInstance item) {
    final character = currentCharacter;
    if (character == null) return false;
    return _characterService.canEquipItem(character.id, item);
  }
  
  List<CardInstance> getEquippedItems() {
    final character = currentCharacter;
    if (character == null) return [];
    return _characterService.getEquippedItems(character.id);
  }
  
  Map<String, dynamic> getCharacterStats() {
    final character = currentCharacter;
    if (character == null) return {};
    return _characterService.getCharacterStats(character.id);
  }
  
  // Quick access to current character properties
  String? get currentCharacterName => currentCharacter?.name;
  CharacterClass? get currentCharacterClass => currentCharacter?.characterClass;
  int get currentCharacterLevel => currentCharacter?.level ?? 1;
  int get currentCharacterHealth => currentCharacter?.maxHealth ?? 0;
  int get currentCharacterMana => currentCharacter?.maxMana ?? 0;
  int get availableStatPoints => currentCharacter?.availableStatPoints ?? 0;
  int get availableSkillPoints => currentCharacter?.availableSkillPoints ?? 0;
  
  // Equipment slots
  CardInstance? get equippedHelmet => currentCharacter?.equipment.helmet;
  CardInstance? get equippedArmor => currentCharacter?.equipment.armor;
  CardInstance? get equippedWeapon1 => currentCharacter?.equipment.weapon1;
  CardInstance? get equippedWeapon2 => currentCharacter?.equipment.weapon2;
  CardInstance? get equippedGloves => currentCharacter?.equipment.gloves;
  CardInstance? get equippedBoots => currentCharacter?.equipment.boots;
  CardInstance? get equippedBelt => currentCharacter?.equipment.belt;
  CardInstance? get equippedRing1 => currentCharacter?.equipment.ring1;
  CardInstance? get equippedRing2 => currentCharacter?.equipment.ring2;
  CardInstance? get equippedAmulet => currentCharacter?.equipment.amulet;
  
  // Inventory and stash
  List<CardInstance> get inventory => currentCharacter?.inventory ?? [];
  List<CardInstance> get stash => currentCharacter?.stash ?? [];
  List<Skill> get skills => currentCharacter?.skills ?? [];
  List<CardInstance> get skillSlots => currentCharacter?.skillSlots ?? [];
  
  // Stats
  int get totalStrength => currentCharacter?.totalStrength ?? 0;
  int get totalDexterity => currentCharacter?.totalDexterity ?? 0;
  int get totalVitality => currentCharacter?.totalVitality ?? 0;
  int get totalEnergy => currentCharacter?.totalEnergy ?? 0;
  int get attackRating => currentCharacter?.attackRating ?? 0;
  int get defense => currentCharacter?.defense ?? 0;
}