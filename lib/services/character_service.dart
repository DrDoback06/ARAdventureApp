import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/character_model.dart';
import '../models/card_model.dart';

/// Service for managing characters, their inventory, and equipment
class CharacterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _charactersCollection = 'characters';
  final String _characterTemplatesCollection = 'character_templates';
  
  /// Creates a new character
  Future<String> createCharacter(GameCharacter character) async {
    try {
      final characterData = character.toJson();
      await _firestore.collection(_charactersCollection).doc(character.id).set(characterData);
      return character.id;
    } catch (e) {
      throw Exception('Failed to create character: $e');
    }
  }
  
  /// Updates an existing character
  Future<void> updateCharacter(GameCharacter character) async {
    try {
      final characterData = character.toJson();
      await _firestore.collection(_charactersCollection).doc(character.id).update(characterData);
    } catch (e) {
      throw Exception('Failed to update character: $e');
    }
  }
  
  /// Gets a character by ID
  Future<GameCharacter?> getCharacter(String characterId) async {
    try {
      final doc = await _firestore.collection(_charactersCollection).doc(characterId).get();
      if (doc.exists) {
        return GameCharacter.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get character: $e');
    }
  }
  
  /// Gets all characters for a player
  Future<List<GameCharacter>> getPlayerCharacters(String playerId) async {
    try {
      final snapshot = await _firestore
          .collection(_charactersCollection)
          .where('playerId', isEqualTo: playerId)
          .get();
      return snapshot.docs.map((doc) => GameCharacter.fromJson(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to get player characters: $e');
    }
  }
  
  /// Deletes a character
  Future<void> deleteCharacter(String characterId) async {
    try {
      await _firestore.collection(_charactersCollection).doc(characterId).delete();
    } catch (e) {
      throw Exception('Failed to delete character: $e');
    }
  }
  
  /// Equips an item to a character
  Future<GameCharacter> equipItem(String characterId, CardInstance item) async {
    try {
      final character = await getCharacter(characterId);
      if (character == null) {
        throw Exception('Character not found');
      }
      
      // Check if character can equip this item
      if (!character.canEquip(item)) {
        throw Exception('Character cannot equip this item');
      }
      
      // Remove item from inventory
      final newInventory = List<CardInstance>.from(character.inventory);
      newInventory.removeWhere((inventoryItem) => inventoryItem.instanceId == item.instanceId);
      
      // Get current equipment in the target slot
      final currentEquipment = character.equipment.getSlot(item.card.equipmentSlot);
      
      // If there's already an item equipped, move it to inventory
      if (currentEquipment != null) {
        newInventory.add(currentEquipment.copyWithUsage(isEquipped: false));
      }
      
      // Equip the new item
      final newEquipment = character.equipment.copyWithSlot(
        item.card.equipmentSlot,
        item.copyWithUsage(isEquipped: true),
      );
      
      // Update character
      final updatedCharacter = character.copyWithEquipment(newEquipment).copyWithInventory(newInventory);
      await updateCharacter(updatedCharacter);
      
      return updatedCharacter;
    } catch (e) {
      throw Exception('Failed to equip item: $e');
    }
  }
  
  /// Unequips an item from a character
  Future<GameCharacter> unequipItem(String characterId, EquipmentSlot slot) async {
    try {
      final character = await getCharacter(characterId);
      if (character == null) {
        throw Exception('Character not found');
      }
      
      final equippedItem = character.equipment.getSlot(slot);
      if (equippedItem == null) {
        throw Exception('No item equipped in that slot');
      }
      
      // Check if there's space in inventory
      if (character.inventory.length >= character.inventorySize) {
        throw Exception('Inventory is full');
      }
      
      // Remove item from equipment
      final newEquipment = character.equipment.copyWithSlot(slot, null);
      
      // Add item to inventory
      final newInventory = List<CardInstance>.from(character.inventory);
      newInventory.add(equippedItem.copyWithUsage(isEquipped: false));
      
      // Update character
      final updatedCharacter = character.copyWithEquipment(newEquipment).copyWithInventory(newInventory);
      await updateCharacter(updatedCharacter);
      
      return updatedCharacter;
    } catch (e) {
      throw Exception('Failed to unequip item: $e');
    }
  }
  
  /// Adds an item to character's inventory
  Future<GameCharacter> addItemToInventory(String characterId, CardInstance item) async {
    try {
      final character = await getCharacter(characterId);
      if (character == null) {
        throw Exception('Character not found');
      }
      
      // Check if there's space in inventory
      if (character.inventory.length >= character.inventorySize) {
        throw Exception('Inventory is full');
      }
      
      final newInventory = List<CardInstance>.from(character.inventory);
      newInventory.add(item);
      
      final updatedCharacter = character.copyWithInventory(newInventory);
      await updateCharacter(updatedCharacter);
      
      return updatedCharacter;
    } catch (e) {
      throw Exception('Failed to add item to inventory: $e');
    }
  }
  
  /// Removes an item from character's inventory
  Future<GameCharacter> removeItemFromInventory(String characterId, String itemInstanceId) async {
    try {
      final character = await getCharacter(characterId);
      if (character == null) {
        throw Exception('Character not found');
      }
      
      final newInventory = List<CardInstance>.from(character.inventory);
      newInventory.removeWhere((item) => item.instanceId == itemInstanceId);
      
      final updatedCharacter = character.copyWithInventory(newInventory);
      await updateCharacter(updatedCharacter);
      
      return updatedCharacter;
    } catch (e) {
      throw Exception('Failed to remove item from inventory: $e');
    }
  }
  
  /// Moves an item from inventory to stash
  Future<GameCharacter> moveItemToStash(String characterId, String itemInstanceId) async {
    try {
      final character = await getCharacter(characterId);
      if (character == null) {
        throw Exception('Character not found');
      }
      
      // Check if there's space in stash
      if (character.stash.length >= character.stashSize) {
        throw Exception('Stash is full');
      }
      
      // Find the item in inventory
      final item = character.inventory.firstWhere(
        (item) => item.instanceId == itemInstanceId,
        orElse: () => throw Exception('Item not found in inventory'),
      );
      
      // Remove from inventory and add to stash
      final newInventory = List<CardInstance>.from(character.inventory);
      newInventory.removeWhere((item) => item.instanceId == itemInstanceId);
      
      final newStash = List<CardInstance>.from(character.stash);
      newStash.add(item);
      
      final updatedCharacter = GameCharacter(
        id: character.id,
        name: character.name,
        characterClass: character.characterClass,
        portraitUrl: character.portraitUrl,
        level: character.level,
        experience: character.experience,
        experienceToNext: character.experienceToNext,
        statPoints: character.statPoints,
        skillPoints: character.skillPoints,
        baseStrength: character.baseStrength,
        baseDexterity: character.baseDexterity,
        baseVitality: character.baseVitality,
        baseEnergy: character.baseEnergy,
        currentHealth: character.currentHealth,
        maxHealth: character.maxHealth,
        currentMana: character.currentMana,
        maxMana: character.maxMana,
        attack: character.attack,
        defense: character.defense,
        accuracy: character.accuracy,
        dodge: character.dodge,
        criticalChance: character.criticalChance,
        criticalDamage: character.criticalDamage,
        equipment: character.equipment,
        inventory: newInventory,
        stash: newStash,
        inventorySize: character.inventorySize,
        stashSize: character.stashSize,
        skills: character.skills,
        skillTrees: character.skillTrees,
        renownPoints: character.renownPoints,
        completedQuests: character.completedQuests,
        activeQuests: character.activeQuests,
        gameFlags: character.gameFlags,
        gold: character.gold,
        currencies: character.currencies,
        createdAt: character.createdAt,
        lastPlayed: DateTime.now(),
        playerId: character.playerId,
      );
      
      await updateCharacter(updatedCharacter);
      return updatedCharacter;
    } catch (e) {
      throw Exception('Failed to move item to stash: $e');
    }
  }
  
  /// Moves an item from stash to inventory
  Future<GameCharacter> moveItemFromStash(String characterId, String itemInstanceId) async {
    try {
      final character = await getCharacter(characterId);
      if (character == null) {
        throw Exception('Character not found');
      }
      
      // Check if there's space in inventory
      if (character.inventory.length >= character.inventorySize) {
        throw Exception('Inventory is full');
      }
      
      // Find the item in stash
      final item = character.stash.firstWhere(
        (item) => item.instanceId == itemInstanceId,
        orElse: () => throw Exception('Item not found in stash'),
      );
      
      // Remove from stash and add to inventory
      final newStash = List<CardInstance>.from(character.stash);
      newStash.removeWhere((item) => item.instanceId == itemInstanceId);
      
      final newInventory = List<CardInstance>.from(character.inventory);
      newInventory.add(item);
      
      final updatedCharacter = GameCharacter(
        id: character.id,
        name: character.name,
        characterClass: character.characterClass,
        portraitUrl: character.portraitUrl,
        level: character.level,
        experience: character.experience,
        experienceToNext: character.experienceToNext,
        statPoints: character.statPoints,
        skillPoints: character.skillPoints,
        baseStrength: character.baseStrength,
        baseDexterity: character.baseDexterity,
        baseVitality: character.baseVitality,
        baseEnergy: character.baseEnergy,
        currentHealth: character.currentHealth,
        maxHealth: character.maxHealth,
        currentMana: character.currentMana,
        maxMana: character.maxMana,
        attack: character.attack,
        defense: character.defense,
        accuracy: character.accuracy,
        dodge: character.dodge,
        criticalChance: character.criticalChance,
        criticalDamage: character.criticalDamage,
        equipment: character.equipment,
        inventory: newInventory,
        stash: newStash,
        inventorySize: character.inventorySize,
        stashSize: character.stashSize,
        skills: character.skills,
        skillTrees: character.skillTrees,
        renownPoints: character.renownPoints,
        completedQuests: character.completedQuests,
        activeQuests: character.activeQuests,
        gameFlags: character.gameFlags,
        gold: character.gold,
        currencies: character.currencies,
        createdAt: character.createdAt,
        lastPlayed: DateTime.now(),
        playerId: character.playerId,
      );
      
      await updateCharacter(updatedCharacter);
      return updatedCharacter;
    } catch (e) {
      throw Exception('Failed to move item from stash: $e');
    }
  }
  
  /// Levels up a character
  Future<GameCharacter> levelUpCharacter(String characterId) async {
    try {
      final character = await getCharacter(characterId);
      if (character == null) {
        throw Exception('Character not found');
      }
      
      if (character.experience < character.experienceToNext) {
        throw Exception('Not enough experience to level up');
      }
      
      final newLevel = character.level + 1;
      final newExperience = character.experience - character.experienceToNext;
      final newExperienceToNext = _calculateExperienceToNext(newLevel);
      final newStatPoints = character.statPoints + 5; // 5 stat points per level
      final newSkillPoints = character.skillPoints + 1; // 1 skill point per level
      
      // Recalculate health and mana based on new level
      final newMaxHealth = GameCharacter._calculateMaxHealth(character.baseVitality, newLevel);
      final newMaxMana = GameCharacter._calculateMaxMana(character.baseEnergy, newLevel);
      
      final updatedCharacter = GameCharacter(
        id: character.id,
        name: character.name,
        characterClass: character.characterClass,
        portraitUrl: character.portraitUrl,
        level: newLevel,
        experience: newExperience,
        experienceToNext: newExperienceToNext,
        statPoints: newStatPoints,
        skillPoints: newSkillPoints,
        baseStrength: character.baseStrength,
        baseDexterity: character.baseDexterity,
        baseVitality: character.baseVitality,
        baseEnergy: character.baseEnergy,
        currentHealth: newMaxHealth, // Full heal on level up
        maxHealth: newMaxHealth,
        currentMana: newMaxMana, // Full mana on level up
        maxMana: newMaxMana,
        attack: character.attack,
        defense: character.defense,
        accuracy: character.accuracy,
        dodge: character.dodge,
        criticalChance: character.criticalChance,
        criticalDamage: character.criticalDamage,
        equipment: character.equipment,
        inventory: character.inventory,
        stash: character.stash,
        inventorySize: character.inventorySize,
        stashSize: character.stashSize,
        skills: character.skills,
        skillTrees: character.skillTrees,
        renownPoints: character.renownPoints,
        completedQuests: character.completedQuests,
        activeQuests: character.activeQuests,
        gameFlags: character.gameFlags,
        gold: character.gold,
        currencies: character.currencies,
        createdAt: character.createdAt,
        lastPlayed: DateTime.now(),
        playerId: character.playerId,
      );
      
      await updateCharacter(updatedCharacter);
      return updatedCharacter;
    } catch (e) {
      throw Exception('Failed to level up character: $e');
    }
  }
  
  /// Allocates stat points to a character
  Future<GameCharacter> allocateStatPoints(
    String characterId,
    int strengthPoints,
    int dexterityPoints,
    int vitalityPoints,
    int energyPoints,
  ) async {
    try {
      final character = await getCharacter(characterId);
      if (character == null) {
        throw Exception('Character not found');
      }
      
      final totalPointsToAllocate = strengthPoints + dexterityPoints + vitalityPoints + energyPoints;
      
      if (totalPointsToAllocate > character.statPoints) {
        throw Exception('Not enough stat points available');
      }
      
      if (strengthPoints < 0 || dexterityPoints < 0 || vitalityPoints < 0 || energyPoints < 0) {
        throw Exception('Cannot allocate negative stat points');
      }
      
      final newBaseStrength = character.baseStrength + strengthPoints;
      final newBaseDexterity = character.baseDexterity + dexterityPoints;
      final newBaseVitality = character.baseVitality + vitalityPoints;
      final newBaseEnergy = character.baseEnergy + energyPoints;
      final newStatPoints = character.statPoints - totalPointsToAllocate;
      
      // Recalculate health and mana based on new vitality and energy
      final newMaxHealth = GameCharacter._calculateMaxHealth(newBaseVitality, character.level);
      final newMaxMana = GameCharacter._calculateMaxMana(newBaseEnergy, character.level);
      
      // Increase current health and mana proportionally
      final healthIncrease = newMaxHealth - character.maxHealth;
      final manaIncrease = newMaxMana - character.maxMana;
      final newCurrentHealth = (character.currentHealth + healthIncrease).clamp(0, newMaxHealth);
      final newCurrentMana = (character.currentMana + manaIncrease).clamp(0, newMaxMana);
      
      final updatedCharacter = GameCharacter(
        id: character.id,
        name: character.name,
        characterClass: character.characterClass,
        portraitUrl: character.portraitUrl,
        level: character.level,
        experience: character.experience,
        experienceToNext: character.experienceToNext,
        statPoints: newStatPoints,
        skillPoints: character.skillPoints,
        baseStrength: newBaseStrength,
        baseDexterity: newBaseDexterity,
        baseVitality: newBaseVitality,
        baseEnergy: newBaseEnergy,
        currentHealth: newCurrentHealth,
        maxHealth: newMaxHealth,
        currentMana: newCurrentMana,
        maxMana: newMaxMana,
        attack: character.attack,
        defense: character.defense,
        accuracy: character.accuracy,
        dodge: character.dodge,
        criticalChance: character.criticalChance,
        criticalDamage: character.criticalDamage,
        equipment: character.equipment,
        inventory: character.inventory,
        stash: character.stash,
        inventorySize: character.inventorySize,
        stashSize: character.stashSize,
        skills: character.skills,
        skillTrees: character.skillTrees,
        renownPoints: character.renownPoints,
        completedQuests: character.completedQuests,
        activeQuests: character.activeQuests,
        gameFlags: character.gameFlags,
        gold: character.gold,
        currencies: character.currencies,
        createdAt: character.createdAt,
        lastPlayed: DateTime.now(),
        playerId: character.playerId,
      );
      
      await updateCharacter(updatedCharacter);
      return updatedCharacter;
    } catch (e) {
      throw Exception('Failed to allocate stat points: $e');
    }
  }
  
  /// Adds experience to a character
  Future<GameCharacter> addExperience(String characterId, int experiencePoints) async {
    try {
      final character = await getCharacter(characterId);
      if (character == null) {
        throw Exception('Character not found');
      }
      
      final newExperience = character.experience + experiencePoints;
      
      final updatedCharacter = GameCharacter(
        id: character.id,
        name: character.name,
        characterClass: character.characterClass,
        portraitUrl: character.portraitUrl,
        level: character.level,
        experience: newExperience,
        experienceToNext: character.experienceToNext,
        statPoints: character.statPoints,
        skillPoints: character.skillPoints,
        baseStrength: character.baseStrength,
        baseDexterity: character.baseDexterity,
        baseVitality: character.baseVitality,
        baseEnergy: character.baseEnergy,
        currentHealth: character.currentHealth,
        maxHealth: character.maxHealth,
        currentMana: character.currentMana,
        maxMana: character.maxMana,
        attack: character.attack,
        defense: character.defense,
        accuracy: character.accuracy,
        dodge: character.dodge,
        criticalChance: character.criticalChance,
        criticalDamage: character.criticalDamage,
        equipment: character.equipment,
        inventory: character.inventory,
        stash: character.stash,
        inventorySize: character.inventorySize,
        stashSize: character.stashSize,
        skills: character.skills,
        skillTrees: character.skillTrees,
        renownPoints: character.renownPoints,
        completedQuests: character.completedQuests,
        activeQuests: character.activeQuests,
        gameFlags: character.gameFlags,
        gold: character.gold,
        currencies: character.currencies,
        createdAt: character.createdAt,
        lastPlayed: DateTime.now(),
        playerId: character.playerId,
      );
      
      await updateCharacter(updatedCharacter);
      return updatedCharacter;
    } catch (e) {
      throw Exception('Failed to add experience: $e');
    }
  }
  
  /// Calculates experience needed for next level
  int _calculateExperienceToNext(int level) {
    // Exponential growth similar to Diablo II
    return (level * 100 * (level + 1) / 2).round();
  }
  
  /// Creates a character template
  Future<void> createCharacterTemplate(String templateName, GameCharacter templateCharacter) async {
    try {
      final templateData = {
        'name': templateName,
        'template': templateCharacter.toJson(),
        'createdAt': DateTime.now().toIso8601String(),
      };
      await _firestore.collection(_characterTemplatesCollection).add(templateData);
    } catch (e) {
      throw Exception('Failed to create character template: $e');
    }
  }
  
  /// Gets all character templates
  Future<List<Map<String, dynamic>>> getCharacterTemplates() async {
    try {
      final snapshot = await _firestore.collection(_characterTemplatesCollection).get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get character templates: $e');
    }
  }
  
  /// Creates a character from template
  Future<GameCharacter> createCharacterFromTemplate(
    String templateId,
    String characterName,
    String playerId,
  ) async {
    try {
      final templateDoc = await _firestore.collection(_characterTemplatesCollection).doc(templateId).get();
      if (!templateDoc.exists) {
        throw Exception('Template not found');
      }
      
      final templateData = templateDoc.data()!;
      final templateCharacter = GameCharacter.fromJson(templateData['template']);
      
      final newCharacter = GameCharacter(
        name: characterName,
        characterClass: templateCharacter.characterClass,
        portraitUrl: templateCharacter.portraitUrl,
        level: templateCharacter.level,
        experience: templateCharacter.experience,
        experienceToNext: templateCharacter.experienceToNext,
        statPoints: templateCharacter.statPoints,
        skillPoints: templateCharacter.skillPoints,
        baseStrength: templateCharacter.baseStrength,
        baseDexterity: templateCharacter.baseDexterity,
        baseVitality: templateCharacter.baseVitality,
        baseEnergy: templateCharacter.baseEnergy,
        playerId: playerId,
      );
      
      await createCharacter(newCharacter);
      return newCharacter;
    } catch (e) {
      throw Exception('Failed to create character from template: $e');
    }
  }
  
  /// Updates character's health
  Future<GameCharacter> updateHealth(String characterId, int newHealth) async {
    try {
      final character = await getCharacter(characterId);
      if (character == null) {
        throw Exception('Character not found');
      }
      
      final clampedHealth = newHealth.clamp(0, character.getActualMaxHealth());
      
      final updatedCharacter = GameCharacter(
        id: character.id,
        name: character.name,
        characterClass: character.characterClass,
        portraitUrl: character.portraitUrl,
        level: character.level,
        experience: character.experience,
        experienceToNext: character.experienceToNext,
        statPoints: character.statPoints,
        skillPoints: character.skillPoints,
        baseStrength: character.baseStrength,
        baseDexterity: character.baseDexterity,
        baseVitality: character.baseVitality,
        baseEnergy: character.baseEnergy,
        currentHealth: clampedHealth,
        maxHealth: character.maxHealth,
        currentMana: character.currentMana,
        maxMana: character.maxMana,
        attack: character.attack,
        defense: character.defense,
        accuracy: character.accuracy,
        dodge: character.dodge,
        criticalChance: character.criticalChance,
        criticalDamage: character.criticalDamage,
        equipment: character.equipment,
        inventory: character.inventory,
        stash: character.stash,
        inventorySize: character.inventorySize,
        stashSize: character.stashSize,
        skills: character.skills,
        skillTrees: character.skillTrees,
        renownPoints: character.renownPoints,
        completedQuests: character.completedQuests,
        activeQuests: character.activeQuests,
        gameFlags: character.gameFlags,
        gold: character.gold,
        currencies: character.currencies,
        createdAt: character.createdAt,
        lastPlayed: DateTime.now(),
        playerId: character.playerId,
      );
      
      await updateCharacter(updatedCharacter);
      return updatedCharacter;
    } catch (e) {
      throw Exception('Failed to update health: $e');
    }
  }
  
  /// Updates character's mana
  Future<GameCharacter> updateMana(String characterId, int newMana) async {
    try {
      final character = await getCharacter(characterId);
      if (character == null) {
        throw Exception('Character not found');
      }
      
      final clampedMana = newMana.clamp(0, character.getActualMaxMana());
      
      final updatedCharacter = GameCharacter(
        id: character.id,
        name: character.name,
        characterClass: character.characterClass,
        portraitUrl: character.portraitUrl,
        level: character.level,
        experience: character.experience,
        experienceToNext: character.experienceToNext,
        statPoints: character.statPoints,
        skillPoints: character.skillPoints,
        baseStrength: character.baseStrength,
        baseDexterity: character.baseDexterity,
        baseVitality: character.baseVitality,
        baseEnergy: character.baseEnergy,
        currentHealth: character.currentHealth,
        maxHealth: character.maxHealth,
        currentMana: clampedMana,
        maxMana: character.maxMana,
        attack: character.attack,
        defense: character.defense,
        accuracy: character.accuracy,
        dodge: character.dodge,
        criticalChance: character.criticalChance,
        criticalDamage: character.criticalDamage,
        equipment: character.equipment,
        inventory: character.inventory,
        stash: character.stash,
        inventorySize: character.inventorySize,
        stashSize: character.stashSize,
        skills: character.skills,
        skillTrees: character.skillTrees,
        renownPoints: character.renownPoints,
        completedQuests: character.completedQuests,
        activeQuests: character.activeQuests,
        gameFlags: character.gameFlags,
        gold: character.gold,
        currencies: character.currencies,
        createdAt: character.createdAt,
        lastPlayed: DateTime.now(),
        playerId: character.playerId,
      );
      
      await updateCharacter(updatedCharacter);
      return updatedCharacter;
    } catch (e) {
      throw Exception('Failed to update mana: $e');
    }
  }
}