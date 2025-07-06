import 'package:flutter/foundation.dart';
import '../models/character_model.dart';
import '../models/card_model.dart';
import '../services/character_service.dart';

class CharacterProvider with ChangeNotifier {
  final CharacterService _characterService;
  
  // Activity tracking
  final List<ActivityEntry> _recentActivity = [];
  
  // Level-up detection
  bool _hasLeveledUp = false;
  int _previousLevel = 0;
  
  CharacterProvider(this._characterService) {
    _initializeProvider();
  }
  
  void _initializeProvider() {
    final character = currentCharacter;
    if (character != null) {
      _previousLevel = character.level;
    }
  }
  
  GameCharacter? get currentCharacter => _characterService.getCurrentCharacter();
  List<GameCharacter> get allCharacters => _characterService.getAllCharacters();
  List<ActivityEntry> get recentActivity => List.unmodifiable(_recentActivity.reversed.take(10));
  bool get hasLeveledUp => _hasLeveledUp;
  
  void clearLevelUpFlag() {
    _hasLeveledUp = false;
    notifyListeners();
  }
  
  void _addActivity(String action, String icon, {String? details}) {
    final activity = ActivityEntry(
      action: action,
      icon: icon,
      timestamp: DateTime.now(),
      details: details,
    );
    _recentActivity.add(activity);
    
    // Keep only last 20 activities
    if (_recentActivity.length > 20) {
      _recentActivity.removeAt(0);
    }
    
    notifyListeners();
  }
  
  // Character Management
  Future<void> createCharacter(GameCharacter character) async {
    await _characterService.createCharacter(character);
    _previousLevel = character.level;
    _addActivity('Created character ${character.name}', 'person_add');
    notifyListeners();
  }
  
  Future<void> setCurrentCharacter(String id) async {
    await _characterService.setCurrentCharacter(id);
    final character = currentCharacter;
    if (character != null) {
      _previousLevel = character.level;
      _addActivity('Switched to ${character.name}', 'swap_horiz');
    }
    notifyListeners();
  }
  
  Future<void> updateCharacter(GameCharacter character) async {
    await _characterService.updateCharacter(character);
    notifyListeners();
  }
  
  Future<void> deleteCharacter(String id) async {
    final character = _characterService.getCharacter(id);
    await _characterService.deleteCharacter(id);
    if (character != null) {
      _addActivity('Deleted character ${character.name}', 'delete');
    }
    notifyListeners();
  }
  
  // Equipment Management
  Future<bool> equipItem(CardInstance item) async {
    final character = currentCharacter;
    if (character == null) return false;
    
    final success = await _characterService.equipItem(character.id, item);
    if (success) {
      _addActivity('Equipped ${item.card.name}', 'check_circle', details: item.card.type.name);
      notifyListeners();
    }
    return success;
  }
  
  Future<bool> unequipItem(EquipmentSlot slot) async {
    final character = currentCharacter;
    if (character == null) return false;
    
    final equippedItem = character.equipment.getItemInSlot(slot);
    final success = await _characterService.unequipItem(character.id, slot);
    if (success && equippedItem != null) {
      _addActivity('Unequipped ${equippedItem.card.name}', 'remove_circle', details: slot.name);
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
      _addActivity('Found ${item.card.name}', 'add_box', details: item.card.rarity.name);
      notifyListeners();
    }
    return success;
  }
  
  Future<bool> removeFromInventory(String itemInstanceId) async {
    final character = currentCharacter;
    if (character == null) return false;
    
    final item = character.inventory.firstWhere(
      (item) => item.instanceId == itemInstanceId,
      orElse: () => throw Exception('Item not found'),
    );
    
    final success = await _characterService.removeFromInventory(character.id, itemInstanceId);
    if (success) {
      _addActivity('Discarded ${item.card.name}', 'delete', details: 'inventory');
      notifyListeners();
    }
    return success;
  }
  
  Future<bool> moveToStash(String itemInstanceId) async {
    final character = currentCharacter;
    if (character == null) return false;
    
    final item = character.inventory.firstWhere(
      (item) => item.instanceId == itemInstanceId,
      orElse: () => throw Exception('Item not found'),
    );
    
    final success = await _characterService.moveToStash(character.id, itemInstanceId);
    if (success) {
      _addActivity('Moved ${item.card.name} to stash', 'storage');
      notifyListeners();
    }
    return success;
  }
  
  Future<bool> moveFromStash(String itemInstanceId) async {
    final character = currentCharacter;
    if (character == null) return false;
    
    final item = character.stash.firstWhere(
      (item) => item.instanceId == itemInstanceId,
      orElse: () => throw Exception('Item not found'),
    );
    
    final success = await _characterService.moveFromStash(character.id, itemInstanceId);
    if (success) {
      _addActivity('Moved ${item.card.name} from stash', 'inventory');
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
      _addActivity('Increased ${statName.toUpperCase()}', 'trending_up', details: '+1 point');
      notifyListeners();
    }
    return success;
  }
  
  Future<bool> addExperience(int experience, {String? source}) async {
    final character = currentCharacter;
    if (character == null) return false;
    
    final oldLevel = character.level;
    final success = await _characterService.addExperience(character.id, experience);
    
    if (success) {
      final updatedCharacter = currentCharacter!;
      final newLevel = updatedCharacter.level;
      
      // Check for level up
      if (newLevel > oldLevel) {
        _hasLeveledUp = true;
        _previousLevel = newLevel;
        final levelsGained = newLevel - oldLevel;
        _addActivity(
          'LEVEL UP! Reached level $newLevel', 
          'star', 
          details: '+${levelsGained * 5} stat points, +$levelsGained skill points'
        );
      } else {
        _addActivity(
          'Gained $experience XP', 
          'trending_up', 
          details: source ?? 'adventure'
        );
      }
      
      notifyListeners();
    }
    return success;
  }
  
  // Adventure and Quest Management
  Future<void> completeAdventure(String adventureName, int expReward, List<CardInstance>? itemRewards) async {
    await addExperience(expReward, source: adventureName);
    
    if (itemRewards != null) {
      for (final item in itemRewards) {
        await addToInventory(item);
      }
    }
    
    _addActivity('Completed $adventureName', 'explore', details: '+$expReward XP');
  }
  
  Future<void> startQuest(String questName, String location) async {
    _addActivity('Started quest: $questName', 'assignment', details: location);
    notifyListeners();
  }
  
  Future<void> completeQuest(String questName, int expReward, List<CardInstance>? itemRewards) async {
    await addExperience(expReward, source: 'Quest: $questName');
    
    if (itemRewards != null) {
      for (final item in itemRewards) {
        await addToInventory(item);
      }
    }
    
    _addActivity('Completed quest: $questName', 'assignment_turned_in', details: '+$expReward XP');
  }
  
  Future<void> winDuel(String opponentName, int expReward) async {
    await addExperience(expReward, source: 'Duel victory');
    _addActivity('Defeated $opponentName in duel', 'sports_martial_arts', details: '+$expReward XP');
  }
  
  Future<void> loseDuel(String opponentName) async {
    _addActivity('Lost duel to $opponentName', 'sentiment_dissatisfied', details: 'better luck next time');
  }
  
  // QR Code Integration
  Future<void> scanQRCode(String qrData) async {
    _addActivity('Scanned QR code', 'qr_code_scanner', details: 'physical card');
    notifyListeners();
    
    // This will be enhanced to parse different QR code types
    // For now, just log the activity
  }
  
  // Skill Management
  Future<bool> learnSkill(Skill skill) async {
    final character = currentCharacter;
    if (character == null) return false;
    
    final success = await _characterService.learnSkill(character.id, skill);
    if (success) {
      _addActivity('Learned skill: ${skill.name}', 'psychology', details: 'level ${skill.level}');
      notifyListeners();
    }
    return success;
  }
  
  Future<bool> upgradeSkill(String skillId) async {
    final character = currentCharacter;
    if (character == null) return false;
    
    final skill = character.skills.firstWhere((s) => s.id == skillId);
    final success = await _characterService.upgradeSkill(character.id, skillId);
    if (success) {
      _addActivity('Upgraded ${skill.name}', 'upgrade', details: 'level ${skill.level + 1}');
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

class ActivityEntry {
  final String action;
  final String icon;
  final DateTime timestamp;
  final String? details;
  
  ActivityEntry({
    required this.action,
    required this.icon,
    required this.timestamp,
    this.details,
  });
  
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}