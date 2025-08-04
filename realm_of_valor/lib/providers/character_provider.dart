import 'package:flutter/foundation.dart';
import '../models/character_model.dart';
import '../models/card_model.dart';
import '../services/character_service.dart' hide Skill;
import '../services/daily_quest_service.dart';
import '../services/achievement_service.dart';

class CharacterProvider with ChangeNotifier {
  final CharacterService _characterService;
  
  // Activity tracking
  final List<ActivityEntry> _recentActivity = [];
  
  // Level-up detection
  bool _hasLeveledUp = false;
  
  // Current character - now properly managed
  GameCharacter? _currentCharacter;
  
  CharacterProvider(this._characterService) {
    _initializeProvider();
  }
  
  void _initializeProvider() {
    // Create a proper character with all fields
    _currentCharacter = GameCharacter(
      name: 'Adventurer',
      characterClass: CharacterClass.paladin,
      level: 1,
      experience: 0,
      baseStrength: 15,
      baseDexterity: 10,
      baseVitality: 12,
      baseEnergy: 8,
      gold: 1250, // Add initial gold
      equipment: Equipment(), // Initialize empty equipment
      inventory: <CardInstance>[], // Initialize empty inventory
      stash: <CardInstance>[], // Initialize empty stash
    );
  }
  
  // Get current character
  GameCharacter? get currentCharacter => _currentCharacter;
  
  // Get all characters - return current character for now
  List<GameCharacter> get allCharacters => _currentCharacter != null ? [_currentCharacter!] : [];
  
  List<ActivityEntry> get recentActivity => List.unmodifiable(_recentActivity.reversed.take(10));
  bool get hasLeveledUp => _hasLeveledUp;
  
  void clearLevelUpFlag() {
    _hasLeveledUp = false;
    notifyListeners();
  }
  
  // Quest Progress Tracking
  void _updateQuestProgress(QuestType type, int amount) {
    try {
      final questService = DailyQuestService.instance;
      questService.updateProgressByType(type, amount);
    } catch (e) {
      debugPrint('Error updating quest progress: $e');
    }
  }
  
  // Achievement Progress Tracking
  void _updateAchievementProgress(String achievementId, int amount) {
    try {
      final achievementService = AchievementService.instance;
      achievementService.updateProgress(achievementId, amount);
    } catch (e) {
      debugPrint('Error updating achievement progress: $e');
    }
  }
  
  void _updateAchievementProgressByCategory(AchievementCategory category, int amount) {
    try {
      final achievementService = AchievementService.instance;
      achievementService.updateProgressByCategory(category, amount);
    } catch (e) {
      debugPrint('Error updating achievement progress by category: $e');
    }
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
    _currentCharacter = character;
    _addActivity('Created character: ${character.name}', 'person_add');
    notifyListeners();
  }
  
  Future<void> updateCharacter(GameCharacter character) async {
    _currentCharacter = character;
    notifyListeners();
  }
  
  Future<void> deleteCharacter(String id) async {
    _addActivity('Deleted character', 'delete');
    notifyListeners();
  }
  
  // Equipment Management
  Future<bool> equipItem(CardInstance item) async {
    if (_currentCharacter == null) return false;
    
    // Determine which slot this item should go in based on card type
    EquipmentSlot? targetSlot = _getEquipmentSlotForCard(item.card);
    if (targetSlot == null) {
      debugPrint('[CharacterProvider] Cannot determine equipment slot for ${item.card.name}');
      return false;
    }
    
    // Remove item from inventory
    final updatedInventory = List<CardInstance>.from(_currentCharacter!.inventory);
    final itemIndex = updatedInventory.indexWhere((i) => i.instanceId == item.instanceId);
    if (itemIndex == -1) {
      debugPrint('[CharacterProvider] Item not found in inventory: ${item.card.name}');
      return false;
    }
    updatedInventory.removeAt(itemIndex);
    
    // Update equipment
    final updatedEquipment = _updateEquipmentSlot(_currentCharacter!.equipment, targetSlot, item);
    
    // Update character
    _currentCharacter = _currentCharacter!.copyWith(
      inventory: updatedInventory,
      equipment: updatedEquipment,
    );
    
    _addActivity('Equipped ${item.card.name}', 'check_circle', details: item.card.type.name);
    debugPrint('[CharacterProvider] Equipped ${item.card.name} to $targetSlot');
    notifyListeners();
    return true;
  }
  
  Future<bool> unequipItem(EquipmentSlot slot) async {
    if (_currentCharacter == null) return false;
    
    final equippedItem = _currentCharacter!.equipment.getItemInSlot(slot);
    if (equippedItem == null) {
      debugPrint('[CharacterProvider] No item equipped in slot: $slot');
      return false;
    }
    
    // Remove from equipment
    final updatedEquipment = _updateEquipmentSlot(_currentCharacter!.equipment, slot, null);
    
    // Add to inventory
    final updatedInventory = List<CardInstance>.from(_currentCharacter!.inventory)..add(equippedItem);
    
    // Update character
    _currentCharacter = _currentCharacter!.copyWith(
      inventory: updatedInventory,
      equipment: updatedEquipment,
    );
    
    _addActivity('Unequipped ${equippedItem.card.name}', 'remove_circle', details: slot.name);
    debugPrint('[CharacterProvider] Unequipped ${equippedItem.card.name} from $slot');
    notifyListeners();
    return true;
  }
  
  // Inventory Management
  Future<bool> addToInventory(CardInstance item) async {
    if (_currentCharacter == null) return false;
    
    final updatedInventory = List<CardInstance>.from(_currentCharacter!.inventory)..add(item);
    _currentCharacter = _currentCharacter!.copyWith(inventory: updatedInventory);
    
    _addActivity('Found ${item.card.name}', 'add_box', details: item.card.rarity.name);
    
    // Update quest progress
    _updateQuestProgress(QuestType.collection, 1);
    
    // Update collection achievements
    _updateAchievementProgress('first_item', 1);
    _updateAchievementProgress('item_hoarder', 1);
    _updateAchievementProgress('rare_collector', 1);
    
    debugPrint('[CharacterProvider] Added ${item.card.name} to inventory. Total items: ${updatedInventory.length}');
    notifyListeners();
    return true;
  }
  
  Future<bool> removeFromInventory(String itemInstanceId) async {
    if (_currentCharacter == null) return false;
    
    final updatedInventory = List<CardInstance>.from(_currentCharacter!.inventory);
    final itemIndex = updatedInventory.indexWhere((i) => i.instanceId == itemInstanceId);
    if (itemIndex == -1) return false;
    
    final removedItem = updatedInventory.removeAt(itemIndex);
    _currentCharacter = _currentCharacter!.copyWith(inventory: updatedInventory);
    
    _addActivity('Discarded ${removedItem.card.name}', 'delete', details: 'inventory');
    debugPrint('[CharacterProvider] Removed ${removedItem.card.name} from inventory');
    notifyListeners();
    return true;
  }
  
  Future<bool> moveToStash(String itemInstanceId) async {
    if (_currentCharacter == null) return false;
    
    final updatedInventory = List<CardInstance>.from(_currentCharacter!.inventory);
    final itemIndex = updatedInventory.indexWhere((i) => i.instanceId == itemInstanceId);
    if (itemIndex == -1) return false;
    
    final item = updatedInventory.removeAt(itemIndex);
    final updatedStash = List<CardInstance>.from(_currentCharacter!.stash)..add(item);
    
    _currentCharacter = _currentCharacter!.copyWith(
      inventory: updatedInventory,
      stash: updatedStash,
    );
    
    _addActivity('Moved ${item.card.name} to stash', 'storage');
    debugPrint('[CharacterProvider] Moved ${item.card.name} to stash');
    notifyListeners();
    return true;
  }
  
  Future<bool> moveFromStash(String itemInstanceId) async {
    if (_currentCharacter == null) return false;
    
    final updatedStash = List<CardInstance>.from(_currentCharacter!.stash);
    final itemIndex = updatedStash.indexWhere((i) => i.instanceId == itemInstanceId);
    if (itemIndex == -1) return false;
    
    final item = updatedStash.removeAt(itemIndex);
    final updatedInventory = List<CardInstance>.from(_currentCharacter!.inventory)..add(item);
    
    _currentCharacter = _currentCharacter!.copyWith(
      inventory: updatedInventory,
      stash: updatedStash,
    );
    
    _addActivity('Moved ${item.card.name} from stash', 'inventory');
    debugPrint('[CharacterProvider] Moved ${item.card.name} from stash');
    notifyListeners();
    return true;
  }
  
  // Character Progression
  Future<bool> allocateStatPoint(String statName) async {
    if (_currentCharacter == null) return false;
    
    _addActivity('Increased ${statName.toUpperCase()}', 'trending_up', details: '+1 point');
    notifyListeners();
    return true;
  }
  
  Future<bool> addExperience(int experience, {String? source}) async {
    if (_currentCharacter == null) return false;
    
    final oldLevel = _currentCharacter!.level;
    final newExperience = _currentCharacter!.experience + experience;
    
    // Check for level up
    final newLevel = _calculateLevel(newExperience);
    final hasLeveledUp = newLevel > oldLevel;
    
    _currentCharacter = _currentCharacter!.copyWith(
      experience: newExperience,
      level: newLevel,
    );
    
    if (hasLeveledUp) {
      _hasLeveledUp = true;
      _addActivity('Level Up!', 'trending_up', details: 'Level $newLevel');
    }
    
    _addActivity(
      'Gained $experience XP', 
      'trending_up', 
      details: source ?? 'adventure'
    );
    
    debugPrint('[CharacterProvider] Added $experience XP. Current XP: $newExperience, Level: $newLevel');
    notifyListeners();
    return true;
  }

  Future<bool> addGold(int gold, {String? source}) async {
    if (_currentCharacter == null) return false;
    
    final newGold = _currentCharacter!.gold + gold;
    _currentCharacter = _currentCharacter!.copyWith(gold: newGold);
    
    _addActivity(
      'Gained $gold Gold', 
      'monetization_on', 
      details: source ?? 'adventure'
    );
    
    debugPrint('[CharacterProvider] Added $gold gold. Current gold: $newGold');
    notifyListeners();
    return true;
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
  
  Future<void> completeQuest(String questName, int expReward, List<CardInstance>? itemRewards, {int goldReward = 0}) async {
    await addExperience(expReward, source: 'Quest: $questName');
    
    if (goldReward > 0) {
      await addGold(goldReward, source: 'Quest: $questName');
    }
    
    if (itemRewards != null) {
      for (final item in itemRewards) {
        await addToInventory(item);
      }
    }
    
    _addActivity('Completed quest: $questName', 'assignment_turned_in', details: '+$expReward XP${goldReward > 0 ? ', +$goldReward Gold' : ''}');
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
    if (_currentCharacter == null) return false;
    
    _addActivity('Learned skill: ${skill.name}', 'psychology', details: 'level ${skill.level}');
    notifyListeners();
    return true;
  }
  
  Future<bool> upgradeSkill(String skillId) async {
    if (_currentCharacter == null) return false;
    
    _addActivity('Upgraded skill', 'upgrade', details: 'level up');
    notifyListeners();
    return true;
  }
  
  // Utility Methods
  bool canEquipItem(CardInstance item) {
    if (_currentCharacter == null) return false;
    return true; // For now, allow all items
  }
  
  List<CardInstance> getEquippedItems() {
    if (_currentCharacter == null) return [];
    return _currentCharacter!.equipment.getAllEquippedItems();
  }
  
  Map<String, dynamic> getCharacterStats() {
    if (_currentCharacter == null) return {};
    return {
      'strength': _currentCharacter!.totalStrength,
      'dexterity': _currentCharacter!.totalDexterity,
      'vitality': _currentCharacter!.totalVitality,
      'energy': _currentCharacter!.totalEnergy,
    };
  }
  
  // Helper methods for equipment management
  EquipmentSlot? _getEquipmentSlotForCard(GameCard card) {
    switch (card.type) {
      case CardType.weapon:
        return EquipmentSlot.weapon1;
      case CardType.armor:
        return EquipmentSlot.armor;
      case CardType.accessory:
        // For accessories, we'll need to determine the specific type based on card name or other properties
        // For now, default to ring1
        return EquipmentSlot.ring1;
      case CardType.item:
        // For general items, we'll need to determine the specific type based on card name or other properties
        // For now, return null to indicate it can't be equipped
        return null;
      default:
        return null;
    }
  }
  
  Equipment _updateEquipmentSlot(Equipment equipment, EquipmentSlot slot, CardInstance? item) {
    switch (slot) {
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
      case EquipmentSlot.none:
        return equipment; // No change for none slot
    }
  }
  
  int _calculateLevel(int experience) {
    // Simple level calculation: 1000 XP per level
    return (experience / 1000).floor() + 1;
  }
  
  // Quick access to current character properties
  String? get currentCharacterName => _currentCharacter?.name;
  CharacterClass? get currentCharacterClass => _currentCharacter?.characterClass;
  int get currentCharacterLevel => _currentCharacter?.level ?? 1;
  int get currentCharacterHealth => _currentCharacter?.maxHealth ?? 100;
  int get currentCharacterMana => _currentCharacter?.maxMana ?? 50;
  int get availableStatPoints => _currentCharacter?.availableStatPoints ?? 0;
  int get availableSkillPoints => _currentCharacter?.availableSkillPoints ?? 0;
  
  // Equipment slots
  CardInstance? get equippedHelmet => _currentCharacter?.equipment.helmet;
  CardInstance? get equippedArmor => _currentCharacter?.equipment.armor;
  CardInstance? get equippedWeapon1 => _currentCharacter?.equipment.weapon1;
  CardInstance? get equippedWeapon2 => _currentCharacter?.equipment.weapon2;
  CardInstance? get equippedGloves => _currentCharacter?.equipment.gloves;
  CardInstance? get equippedBoots => _currentCharacter?.equipment.boots;
  CardInstance? get equippedBelt => _currentCharacter?.equipment.belt;
  CardInstance? get equippedRing1 => _currentCharacter?.equipment.ring1;
  CardInstance? get equippedRing2 => _currentCharacter?.equipment.ring2;
  CardInstance? get equippedAmulet => _currentCharacter?.equipment.amulet;
  
  // Inventory and stash
  List<CardInstance> get inventory => _currentCharacter?.inventory ?? [];
  List<CardInstance> get stash => _currentCharacter?.stash ?? [];
  List<Skill> get skills => _currentCharacter?.skills ?? [];
  List<CardInstance> get skillSlots => _currentCharacter?.skillSlots ?? [];
  
  // Stats
  int get totalStrength => _currentCharacter?.totalStrength ?? 0;
  int get totalDexterity => _currentCharacter?.totalDexterity ?? 0;
  int get totalVitality => _currentCharacter?.totalVitality ?? 0;
  int get totalEnergy => _currentCharacter?.totalEnergy ?? 0;
  int get attackRating => _currentCharacter?.attackRating ?? 10;
  int get defense => _currentCharacter?.defense ?? 10;
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