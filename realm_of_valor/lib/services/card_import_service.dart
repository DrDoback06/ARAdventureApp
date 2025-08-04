import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/card_model.dart';

/// Service for importing and exporting cards using JSON format
/// This makes it easy for agents to create cards and import them into the app
class CardImportService {
  
  /// Import cards from JSON string
  /// Used when receiving card data from an agent or external source
  static List<GameCard> importCardsFromJson(String jsonData) {
    try {
      final List<dynamic> cardsJson = json.decode(jsonData);
      return cardsJson.map((cardJson) => GameCard.fromJson(cardJson)).toList();
    } catch (e) {
      print('Error importing cards from JSON: $e');
      return [];
    }
  }
  
  /// Export cards to JSON string
  /// Used when sending card data to an agent or external source
  static String exportCardsToJson(List<GameCard> cards) {
    try {
      final List<Map<String, dynamic>> cardsJson = cards.map((card) => card.toJson()).toList();
      return json.encode(cardsJson);
    } catch (e) {
      print('Error exporting cards to JSON: $e');
      return '[]';
    }
  }
  
  /// Import cards from a JSON file in assets
  /// Used for loading predefined card sets
  static Future<List<GameCard>> importCardsFromAsset(String assetPath) async {
    try {
      final String jsonString = await rootBundle.loadString(assetPath);
      return importCardsFromJson(jsonString);
    } catch (e) {
      print('Error importing cards from asset $assetPath: $e');
      return [];
    }
  }
  
  /// Import cards from a local JSON file
  /// Used for loading custom card sets
  static Future<List<GameCard>> importCardsFromFile(String filePath) async {
    try {
      // This would need to be implemented based on your file system access
      // For now, we'll return an empty list
      return [];
    } catch (e) {
      print('Error importing cards from file $filePath: $e');
      return [];
    }
  }
  
  /// Export cards to a JSON file
  /// Used for saving custom card sets
  static Future<bool> exportCardsToFile(List<GameCard> cards, String filePath) async {
    try {
      final String jsonData = exportCardsToJson(cards);
      // This would need to be implemented based on your file system access
      // For now, we'll return false
      return false;
    } catch (e) {
      print('Error exporting cards to file $filePath: $e');
      return false;
    }
  }
  
  /// Validate card data before import
  /// Ensures all required fields are present and valid
  static bool validateCardData(Map<String, dynamic> cardData) {
    final requiredFields = ['name', 'description', 'type'];
    
    for (final field in requiredFields) {
      if (!cardData.containsKey(field) || cardData[field] == null) {
        print('Missing required field: $field');
        return false;
      }
    }
    
    // Validate type
    final validTypes = CardType.values.map((e) => e.name).toList();
    if (!validTypes.contains(cardData['type'])) {
      print('Invalid card type: ${cardData['type']}');
      return false;
    }
    
    // Validate rarity
    if (cardData.containsKey('rarity')) {
      final validRarities = CardRarity.values.map((e) => e.name).toList();
      if (!validRarities.contains(cardData['rarity'])) {
        print('Invalid card rarity: ${cardData['rarity']}');
        return false;
      }
    }
    
    return true;
  }
  
  /// Generate a sample card JSON for testing
  static String generateSampleCardJson() {
    final sampleCard = {
      "id": "sample_sword",
      "name": "Iron Sword",
      "description": "A reliable blade for new adventurers. +15 ATK.",
      "type": "weapon",
      "rarity": "common",
      "set": "core",
      "cost": 3,
      "attack": 15,
      "defense": 0,
      "health": 0,
      "mana": 0,
      "strength": 0,
      "agility": 0,
      "intelligence": 0,
      "durability": 100,
      "maxStack": 1,
      "isConsumable": false,
      "isTradeable": true,
      "equipmentSlot": "weapon1",
      "allowedClasses": ["all"],
      "statModifiers": [
        {
          "statName": "attack",
          "value": 15,
          "isPercentage": false
        }
      ],
      "conditions": [],
      "effects": [],
      "imageUrl": "assets/cards/iron_sword.png",
      "physicalCardId": "PHYS_IRON_001",
      "lore": "A simple but effective weapon for beginners.",
      "tags": ["weapon", "sword", "melee"],
      "customProperties": {}
    };
    
    return json.encode([sampleCard]);
  }
  
  /// Generate a complete card set JSON for testing
  static String generateCompleteCardSetJson() {
    final List<Map<String, dynamic>> cards = [];
    
    // Add some sample cards of different types
    cards.addAll([
      {
        "id": "iron_sword",
        "name": "Iron Sword",
        "description": "A reliable blade for new adventurers. +15 ATK.",
        "type": "weapon",
        "rarity": "common",
        "set": "core",
        "cost": 3,
        "attack": 15,
        "equipmentSlot": "weapon1",
        "allowedClasses": ["all"],
        "statModifiers": [{"statName": "attack", "value": 15, "isPercentage": false}],
        "imageUrl": "assets/cards/iron_sword.png",
        "physicalCardId": "PHYS_IRON_001",
        "lore": "A simple but effective weapon for beginners.",
        "tags": ["weapon", "sword", "melee"]
      },
      {
        "id": "leather_armor",
        "name": "Leather Armor",
        "description": "Light protection for agile fighters. +20 DEF, +5 AGI.",
        "type": "armor",
        "rarity": "common",
        "set": "core",
        "cost": 4,
        "defense": 20,
        "agility": 5,
        "equipmentSlot": "armor",
        "allowedClasses": ["all"],
        "statModifiers": [
          {"statName": "defense", "value": 20, "isPercentage": false},
          {"statName": "agility", "value": 5, "isPercentage": false}
        ],
        "imageUrl": "assets/cards/leather_armor.png",
        "physicalCardId": "PHYS_LEATHER_001",
        "lore": "Basic protection for those who value mobility.",
        "tags": ["armor", "leather", "light"]
      },
      {
        "id": "fireball",
        "name": "Fireball",
        "description": "Launch a ball of flame at your enemy. Deals 30 fire damage.",
        "type": "spell",
        "rarity": "common",
        "set": "elements",
        "cost": 3,
        "attack": 30,
        "allowedClasses": ["arcane", "chaos"],
        "effects": [{"type": "fire_damage", "value": "30", "duration": 0}],
        "imageUrl": "assets/cards/fireball.png",
        "physicalCardId": "PHYS_FIREBALL_001",
        "lore": "A basic but effective fire spell.",
        "tags": ["spell", "fire", "damage"]
      },
      {
        "id": "health_potion",
        "name": "Health Potion",
        "description": "Restore 50 HP.",
        "type": "consumable",
        "rarity": "common",
        "set": "core",
        "cost": 2,
        "isConsumable": true,
        "allowedClasses": ["all"],
        "effects": [{"type": "heal", "value": "50", "duration": 0}],
        "imageUrl": "assets/cards/health_potion.png",
        "physicalCardId": "PHYS_HEALTH_001",
        "lore": "A simple healing potion.",
        "tags": ["consumable", "heal", "potion"]
      },
      {
        "id": "goblin_warrior",
        "name": "Goblin Warrior",
        "description": "A fierce but small warrior from the mountain caves.",
        "type": "enemy",
        "rarity": "common",
        "set": "core",
        "cost": 0,
        "attack": 20,
        "defense": 15,
        "health": 35,
        "allowedClasses": ["all"],
        "imageUrl": "assets/cards/goblin_warrior.png",
        "physicalCardId": "PHYS_GOBLIN_001",
        "lore": "Small but fierce creatures that live in caves.",
        "tags": ["enemy", "goblin", "warrior"]
      }
    ]);
    
    return json.encode(cards);
  }
  
  /// Merge multiple card sets into one
  static List<GameCard> mergeCardSets(List<List<GameCard>> cardSets) {
    final Map<String, GameCard> mergedCards = {};
    
    for (final cardSet in cardSets) {
      for (final card in cardSet) {
        mergedCards[card.id] = card;
      }
    }
    
    return mergedCards.values.toList();
  }
  
  /// Filter cards by various criteria
  static List<GameCard> filterCards(List<GameCard> cards, {
    CardType? type,
    CardRarity? rarity,
    CardSet? set,
    List<CharacterClass>? allowedClasses,
    String? searchTerm,
  }) {
    return cards.where((card) {
      if (type != null && card.type != type) return false;
      if (rarity != null && card.rarity != rarity) return false;
      if (set != null && card.set != set) return false;
      if (allowedClasses != null && !allowedClasses.any((cls) => card.allowedClasses.contains(cls))) return false;
      if (searchTerm != null && !card.name.toLowerCase().contains(searchTerm.toLowerCase())) return false;
      return true;
    }).toList();
  }
  
  /// Get card statistics
  static Map<String, dynamic> getCardStatistics(List<GameCard> cards) {
    final Map<String, int> typeCount = {};
    final Map<String, int> rarityCount = {};
    final Map<String, int> setCount = {};
    
    for (final card in cards) {
      typeCount[card.type.name] = (typeCount[card.type.name] ?? 0) + 1;
      rarityCount[card.rarity.name] = (rarityCount[card.rarity.name] ?? 0) + 1;
      setCount[card.set.name] = (setCount[card.set.name] ?? 0) + 1;
    }
    
    return {
      'totalCards': cards.length,
      'typeBreakdown': typeCount,
      'rarityBreakdown': rarityCount,
      'setBreakdown': setCount,
    };
  }
  
  /// Validate a complete card set
  static List<String> validateCardSet(List<GameCard> cards) {
    final List<String> errors = [];
    final Set<String> ids = {};
    
    for (final card in cards) {
      // Check for duplicate IDs
      if (ids.contains(card.id)) {
        errors.add('Duplicate card ID: ${card.id}');
      } else {
        ids.add(card.id);
      }
      
      // Check for missing required fields
      if (card.name.isEmpty) {
        errors.add('Card ${card.id} has empty name');
      }
      
      if (card.description.isEmpty) {
        errors.add('Card ${card.id} has empty description');
      }
      
      // Check for invalid stat values
      if (card.attack < 0) {
        errors.add('Card ${card.id} has negative attack value');
      }
      
      if (card.defense < 0) {
        errors.add('Card ${card.id} has negative defense value');
      }
      
      if (card.cost < 0) {
        errors.add('Card ${card.id} has negative cost');
      }
    }
    
    return errors;
  }
}

/// Extension methods for easier card manipulation
extension CardListExtensions on List<GameCard> {
  /// Filter cards by type
  List<GameCard> byType(CardType type) {
    return where((card) => card.type == type).toList();
  }
  
  /// Filter cards by rarity
  List<GameCard> byRarity(CardRarity rarity) {
    return where((card) => card.rarity == rarity).toList();
  }
  
  /// Filter cards by set
  List<GameCard> bySet(CardSet set) {
    return where((card) => card.set == set).toList();
  }
  
  /// Filter cards by class
  List<GameCard> byClass(CharacterClass characterClass) {
    return where((card) => card.allowedClasses.contains(characterClass)).toList();
  }
  
  /// Search cards by name
  List<GameCard> searchByName(String searchTerm) {
    return where((card) => card.name.toLowerCase().contains(searchTerm.toLowerCase())).toList();
  }
  
  /// Get cards with specific stat modifier
  List<GameCard> withStatModifier(String statName) {
    return where((card) => card.statModifiers.any((mod) => mod.statName == statName)).toList();
  }
  
  /// Get cards with specific effect
  List<GameCard> withEffect(String effectType) {
    return where((card) => card.effects.any((effect) => effect.type == effectType)).toList();
  }
  
  /// Sort cards by name
  List<GameCard> sortedByName() {
    final sorted = List<GameCard>.from(this);
    sorted.sort((a, b) => a.name.compareTo(b.name));
    return sorted;
  }
  
  /// Sort cards by cost
  List<GameCard> sortedByCost() {
    final sorted = List<GameCard>.from(this);
    sorted.sort((a, b) => a.cost.compareTo(b.cost));
    return sorted;
  }
  
  /// Sort cards by rarity
  List<GameCard> sortedByRarity() {
    final sorted = List<GameCard>.from(this);
    sorted.sort((a, b) => a.rarity.index.compareTo(b.rarity.index));
    return sorted;
  }
} 