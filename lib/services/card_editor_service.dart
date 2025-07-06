import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/card_model.dart';

/// Service for creating, editing, and managing cards
/// This is the core card editor that allows developers to create cards visually
class CardEditorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _cardsCollection = 'cards';
  final String _cardTemplatesCollection = 'card_templates';
  
  /// Creates a new card and saves it to the database
  /// Returns the created card's ID
  Future<String> createCard(GameCard card) async {
    try {
      final cardData = card.toJson();
      await _firestore.collection(_cardsCollection).doc(card.id).set(cardData);
      return card.id;
    } catch (e) {
      throw Exception('Failed to create card: $e');
    }
  }
  
  /// Updates an existing card
  Future<void> updateCard(GameCard card) async {
    try {
      final cardData = card.toJson();
      await _firestore.collection(_cardsCollection).doc(card.id).update(cardData);
    } catch (e) {
      throw Exception('Failed to update card: $e');
    }
  }
  
  /// Deletes a card from the database
  Future<void> deleteCard(String cardId) async {
    try {
      await _firestore.collection(_cardsCollection).doc(cardId).delete();
    } catch (e) {
      throw Exception('Failed to delete card: $e');
    }
  }
  
  /// Gets a card by its ID
  Future<GameCard?> getCard(String cardId) async {
    try {
      final doc = await _firestore.collection(_cardsCollection).doc(cardId).get();
      if (doc.exists) {
        return GameCard.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get card: $e');
    }
  }
  
  /// Gets all cards from the database
  Future<List<GameCard>> getAllCards() async {
    try {
      final snapshot = await _firestore.collection(_cardsCollection).get();
      return snapshot.docs.map((doc) => GameCard.fromJson(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to get cards: $e');
    }
  }
  
  /// Gets cards by type
  Future<List<GameCard>> getCardsByType(CardType type) async {
    try {
      final snapshot = await _firestore
          .collection(_cardsCollection)
          .where('type', isEqualTo: type.name)
          .get();
      return snapshot.docs.map((doc) => GameCard.fromJson(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to get cards by type: $e');
    }
  }
  
  /// Gets cards by class
  Future<List<GameCard>> getCardsByClass(CharacterClass characterClass) async {
    try {
      final snapshot = await _firestore
          .collection(_cardsCollection)
          .where('allowedClasses', arrayContains: characterClass.name)
          .get();
      return snapshot.docs.map((doc) => GameCard.fromJson(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to get cards by class: $e');
    }
  }
  
  /// Gets cards by rarity
  Future<List<GameCard>> getCardsByRarity(CardRarity rarity) async {
    try {
      final snapshot = await _firestore
          .collection(_cardsCollection)
          .where('rarity', isEqualTo: rarity.name)
          .get();
      return snapshot.docs.map((doc) => GameCard.fromJson(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to get cards by rarity: $e');
    }
  }
  
  /// Searches cards by name or description
  Future<List<GameCard>> searchCards(String query) async {
    try {
      final snapshot = await _firestore.collection(_cardsCollection).get();
      final cards = snapshot.docs.map((doc) => GameCard.fromJson(doc.data())).toList();
      
      return cards.where((card) {
        return card.name.toLowerCase().contains(query.toLowerCase()) ||
               card.description.toLowerCase().contains(query.toLowerCase()) ||
               card.lore.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      throw Exception('Failed to search cards: $e');
    }
  }
  
  /// Creates a card template for quick card creation
  Future<void> createCardTemplate(String templateName, GameCard templateCard) async {
    try {
      final templateData = {
        'name': templateName,
        'template': templateCard.toJson(),
        'createdAt': DateTime.now().toIso8601String(),
      };
      await _firestore.collection(_cardTemplatesCollection).add(templateData);
    } catch (e) {
      throw Exception('Failed to create card template: $e');
    }
  }
  
  /// Gets all card templates
  Future<List<Map<String, dynamic>>> getCardTemplates() async {
    try {
      final snapshot = await _firestore.collection(_cardTemplatesCollection).get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get card templates: $e');
    }
  }
  
  /// Creates a card from a template
  Future<GameCard> createCardFromTemplate(String templateId, Map<String, dynamic> overrides) async {
    try {
      final templateDoc = await _firestore.collection(_cardTemplatesCollection).doc(templateId).get();
      if (!templateDoc.exists) {
        throw Exception('Template not found');
      }
      
      final templateData = templateDoc.data()!;
      final templateCard = GameCard.fromJson(templateData['template']);
      
      // Apply overrides
      final newCard = templateCard.copyWith(
        name: overrides['name'] ?? templateCard.name,
        description: overrides['description'] ?? templateCard.description,
        attack: overrides['attack'] ?? templateCard.attack,
        defense: overrides['defense'] ?? templateCard.defense,
        manaCost: overrides['manaCost'] ?? templateCard.manaCost,
        goldValue: overrides['goldValue'] ?? templateCard.goldValue,
        // Add more overrides as needed
      );
      
      return newCard;
    } catch (e) {
      throw Exception('Failed to create card from template: $e');
    }
  }
  
  /// Validates a card before saving
  bool validateCard(GameCard card) {
    // Basic validation rules
    if (card.name.isEmpty) return false;
    if (card.description.isEmpty) return false;
    if (card.attack < 0) return false;
    if (card.defense < 0) return false;
    if (card.manaCost < 0) return false;
    if (card.goldValue < 0) return false;
    
    // Validate stat modifiers
    for (var modifier in card.statModifiers) {
      if (modifier.statName.isEmpty) return false;
    }
    
    // Validate conditions
    for (var condition in card.conditions) {
      if (condition.conditionType.isEmpty) return false;
      if (condition.conditionKey.isEmpty) return false;
    }
    
    // Validate effects
    for (var effect in card.effects) {
      if (effect.effectType.isEmpty) return false;
      if (effect.target.isEmpty) return false;
    }
    
    return true;
  }
  
  /// Creates a basic weapon card
  GameCard createBasicWeapon({
    required String name,
    required String description,
    required int attack,
    required int durability,
    List<CharacterClass> allowedClasses = const [CharacterClass.all],
    List<StatModifier> statModifiers = const [],
    List<CardCondition> conditions = const [],
    int goldValue = 10,
    CardRarity rarity = CardRarity.common,
  }) {
    return GameCard(
      name: name,
      description: description,
      type: CardType.weapon,
      equipmentSlot: EquipmentSlot.weapon1,
      attack: attack,
      durability: durability,
      allowedClasses: allowedClasses,
      statModifiers: statModifiers,
      conditions: conditions,
      goldValue: goldValue,
      rarity: rarity,
      createdBy: 'card_editor',
    );
  }
  
  /// Creates a basic armor card
  GameCard createBasicArmor({
    required String name,
    required String description,
    required int defense,
    required int durability,
    EquipmentSlot equipmentSlot = EquipmentSlot.armor,
    List<CharacterClass> allowedClasses = const [CharacterClass.all],
    List<StatModifier> statModifiers = const [],
    List<CardCondition> conditions = const [],
    int goldValue = 10,
    CardRarity rarity = CardRarity.common,
  }) {
    return GameCard(
      name: name,
      description: description,
      type: CardType.armor,
      equipmentSlot: equipmentSlot,
      defense: defense,
      durability: durability,
      allowedClasses: allowedClasses,
      statModifiers: statModifiers,
      conditions: conditions,
      goldValue: goldValue,
      rarity: rarity,
      createdBy: 'card_editor',
    );
  }
  
  /// Creates a basic skill card
  GameCard createBasicSkill({
    required String name,
    required String description,
    required int manaCost,
    required List<CardEffect> effects,
    List<CharacterClass> allowedClasses = const [CharacterClass.all],
    List<CardCondition> conditions = const [],
    int maxUsesPerTurn = 1,
    int cooldownTurns = 0,
    CardRarity rarity = CardRarity.common,
  }) {
    return GameCard(
      name: name,
      description: description,
      type: CardType.skill,
      equipmentSlot: EquipmentSlot.skill1,
      manaCost: manaCost,
      effects: effects,
      allowedClasses: allowedClasses,
      conditions: conditions,
      maxUsesPerTurn: maxUsesPerTurn,
      cooldownTurns: cooldownTurns,
      rarity: rarity,
      createdBy: 'card_editor',
    );
  }
  
  /// Creates a basic quest card
  GameCard createBasicQuest({
    required String name,
    required String description,
    required String questObjective,
    required Map<String, dynamic> questRewards,
    List<CharacterClass> allowedClasses = const [CharacterClass.all],
    List<CardCondition> conditions = const [],
    CardRarity rarity = CardRarity.common,
  }) {
    return GameCard(
      name: name,
      description: description,
      type: CardType.quest,
      questObjective: questObjective,
      questRewards: questRewards,
      allowedClasses: allowedClasses,
      conditions: conditions,
      rarity: rarity,
      createdBy: 'card_editor',
    );
  }
  
  /// Creates a basic consumable card
  GameCard createBasicConsumable({
    required String name,
    required String description,
    required List<CardEffect> effects,
    int maxUsesPerGame = 1,
    bool isConsumable = true,
    int goldValue = 5,
    CardRarity rarity = CardRarity.common,
  }) {
    return GameCard(
      name: name,
      description: description,
      type: CardType.consumable,
      effects: effects,
      maxUsesPerGame: maxUsesPerGame,
      isConsumable: isConsumable,
      goldValue: goldValue,
      rarity: rarity,
      createdBy: 'card_editor',
    );
  }
  
  /// Duplicates a card with a new ID
  Future<GameCard> duplicateCard(String cardId, {String? newName}) async {
    try {
      final originalCard = await getCard(cardId);
      if (originalCard == null) {
        throw Exception('Card not found');
      }
      
      final duplicatedCard = GameCard(
        name: newName ?? '${originalCard.name} (Copy)',
        description: originalCard.description,
        type: originalCard.type,
        rarity: originalCard.rarity,
        allowedClasses: originalCard.allowedClasses,
        equipmentSlot: originalCard.equipmentSlot,
        imageUrl: originalCard.imageUrl,
        iconUrl: originalCard.iconUrl,
        visualProperties: originalCard.visualProperties,
        attack: originalCard.attack,
        defense: originalCard.defense,
        manaCost: originalCard.manaCost,
        durability: originalCard.durability,
        statModifiers: originalCard.statModifiers,
        conditions: originalCard.conditions,
        effects: originalCard.effects,
        maxUsesPerGame: originalCard.maxUsesPerGame,
        maxUsesPerTurn: originalCard.maxUsesPerTurn,
        cooldownTurns: originalCard.cooldownTurns,
        isConsumable: originalCard.isConsumable,
        isUnique: originalCard.isUnique,
        questObjective: originalCard.questObjective,
        questRewards: originalCard.questRewards,
        goldValue: originalCard.goldValue,
        isTradeable: originalCard.isTradeable,
        isCraftable: originalCard.isCraftable,
        craftingMaterials: originalCard.craftingMaterials,
        lore: originalCard.lore,
        tags: originalCard.tags,
        createdBy: 'card_editor',
      );
      
      await createCard(duplicatedCard);
      return duplicatedCard;
    } catch (e) {
      throw Exception('Failed to duplicate card: $e');
    }
  }
  
  /// Exports cards to JSON format
  Future<Map<String, dynamic>> exportCards({
    List<String>? cardIds,
    CardType? filterByType,
    CharacterClass? filterByClass,
    CardRarity? filterByRarity,
  }) async {
    try {
      List<GameCard> cards;
      
      if (cardIds != null) {
        cards = [];
        for (String id in cardIds) {
          final card = await getCard(id);
          if (card != null) cards.add(card);
        }
      } else {
        cards = await getAllCards();
      }
      
      // Apply filters
      if (filterByType != null) {
        cards = cards.where((card) => card.type == filterByType).toList();
      }
      if (filterByClass != null) {
        cards = cards.where((card) => card.allowedClasses.contains(filterByClass)).toList();
      }
      if (filterByRarity != null) {
        cards = cards.where((card) => card.rarity == filterByRarity).toList();
      }
      
      return {
        'cards': cards.map((card) => card.toJson()).toList(),
        'exportedAt': DateTime.now().toIso8601String(),
        'totalCards': cards.length,
      };
    } catch (e) {
      throw Exception('Failed to export cards: $e');
    }
  }
  
  /// Imports cards from JSON format
  Future<List<String>> importCards(Map<String, dynamic> importData) async {
    try {
      if (!importData.containsKey('cards')) {
        throw Exception('Invalid import data: missing cards array');
      }
      
      final List<dynamic> cardDataList = importData['cards'];
      final List<String> importedCardIds = [];
      
      for (var cardData in cardDataList) {
        try {
          final card = GameCard.fromJson(cardData);
          // Generate new ID to avoid conflicts
          final newCard = GameCard(
            name: card.name,
            description: card.description,
            type: card.type,
            rarity: card.rarity,
            allowedClasses: card.allowedClasses,
            equipmentSlot: card.equipmentSlot,
            imageUrl: card.imageUrl,
            iconUrl: card.iconUrl,
            visualProperties: card.visualProperties,
            attack: card.attack,
            defense: card.defense,
            manaCost: card.manaCost,
            durability: card.durability,
            statModifiers: card.statModifiers,
            conditions: card.conditions,
            effects: card.effects,
            maxUsesPerGame: card.maxUsesPerGame,
            maxUsesPerTurn: card.maxUsesPerTurn,
            cooldownTurns: card.cooldownTurns,
            isConsumable: card.isConsumable,
            isUnique: card.isUnique,
            questObjective: card.questObjective,
            questRewards: card.questRewards,
            goldValue: card.goldValue,
            isTradeable: card.isTradeable,
            isCraftable: card.isCraftable,
            craftingMaterials: card.craftingMaterials,
            lore: card.lore,
            tags: card.tags,
            createdBy: 'imported',
          );
          
          await createCard(newCard);
          importedCardIds.add(newCard.id);
        } catch (e) {
          // Skip invalid cards but continue importing others
          print('Failed to import card: $e');
        }
      }
      
      return importedCardIds;
    } catch (e) {
      throw Exception('Failed to import cards: $e');
    }
  }
  
  /// Gets card statistics for the developer dashboard
  Future<Map<String, dynamic>> getCardStatistics() async {
    try {
      final cards = await getAllCards();
      
      final stats = {
        'totalCards': cards.length,
        'cardsByType': <String, int>{},
        'cardsByClass': <String, int>{},
        'cardsByRarity': <String, int>{},
        'averageAttack': 0.0,
        'averageDefense': 0.0,
        'averageManaCost': 0.0,
        'averageGoldValue': 0.0,
      };
      
      int totalAttack = 0;
      int totalDefense = 0;
      int totalManaCost = 0;
      int totalGoldValue = 0;
      
      for (var card in cards) {
        // Count by type
        stats['cardsByType'][card.type.name] = 
            (stats['cardsByType'][card.type.name] ?? 0) + 1;
        
        // Count by rarity
        stats['cardsByRarity'][card.rarity.name] = 
            (stats['cardsByRarity'][card.rarity.name] ?? 0) + 1;
        
        // Count by class
        for (var characterClass in card.allowedClasses) {
          stats['cardsByClass'][characterClass.name] = 
              (stats['cardsByClass'][characterClass.name] ?? 0) + 1;
        }
        
        // Sum for averages
        totalAttack += card.attack;
        totalDefense += card.defense;
        totalManaCost += card.manaCost;
        totalGoldValue += card.goldValue;
      }
      
      if (cards.isNotEmpty) {
        stats['averageAttack'] = totalAttack / cards.length;
        stats['averageDefense'] = totalDefense / cards.length;
        stats['averageManaCost'] = totalManaCost / cards.length;
        stats['averageGoldValue'] = totalGoldValue / cards.length;
      }
      
      return stats;
    } catch (e) {
      throw Exception('Failed to get card statistics: $e');
    }
  }
}