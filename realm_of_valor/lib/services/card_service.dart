import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card_model.dart';

class CardService {
  static const String _cardsKey = 'saved_cards';
  static const String _templatesKey = 'card_templates';
  static const String _unlockedCardsKey = 'unlocked_cards';
  
  final SharedPreferences _prefs;
  final List<GameCard> _cards = [];
  final List<GameCard> _templates = [];
  final List<String> _unlockedCardIds = [];
  final Random _random = Random();
  
  CardService(this._prefs) {
    _loadCards();
    _loadTemplates();
    _initializeDefaultTemplates();
    _loadUnlockedCards();
  }
  
  // CRUD Operations
  Future<void> createCard(GameCard card) async {
    _cards.add(card);
    await _saveCards();
  }
  
  List<GameCard> getAllCards() => List.unmodifiable(_cards);
  
  GameCard? getCard(String id) {
    try {
      return _cards.firstWhere((card) => card.id == id);
    } catch (e) {
      return null;
    }
  }
  
  Future<void> updateCard(GameCard updatedCard) async {
    final index = _cards.indexWhere((card) => card.id == updatedCard.id);
    if (index != -1) {
      _cards[index] = updatedCard;
      await _saveCards();
    }
  }
  
  Future<void> deleteCard(String id) async {
    _cards.removeWhere((card) => card.id == id);
    await _saveCards();
  }
  
  // Search and Filter
  List<GameCard> searchCards(String query) {
    if (query.isEmpty) return getAllCards();
    
    final lowerQuery = query.toLowerCase();
    return _cards.where((card) {
      return card.name.toLowerCase().contains(lowerQuery) ||
          card.description.toLowerCase().contains(lowerQuery) ||
          card.type.toString().toLowerCase().contains(lowerQuery);
    }).toList();
  }
  
  List<GameCard> getCardsByType(CardType type) {
    return _cards.where((card) => card.type == type).toList();
  }
  
  List<GameCard> getCardsByRarity(CardRarity rarity) {
    return _cards.where((card) => card.rarity == rarity).toList();
  }
  
  List<GameCard> getCardsByClass(CharacterClass characterClass) {
    return _cards.where((card) => 
        card.allowedClasses.isEmpty || 
        card.allowedClasses.contains(characterClass)).toList();
  }
  
  // Card Validation
  List<String> validateCard(GameCard card) {
    final errors = <String>[];
    
    if (card.name.trim().isEmpty) {
      errors.add('Card name cannot be empty');
    }
    
    if (card.description.trim().isEmpty) {
      errors.add('Card description cannot be empty');
    }
    
    if (card.cost < 0) {
      errors.add('Card cost cannot be negative');
    }
    
    if (card.levelRequirement < 1 || card.levelRequirement > 100) {
      errors.add('Level requirement must be between 1 and 100');
    }
    
    if (card.durability < 1 || card.durability > 1000) {
      errors.add('Durability must be between 1 and 1000');
    }
    
    if (card.maxStack < 1 || card.maxStack > 1000) {
      errors.add('Max stack must be between 1 and 1000');
    }
    
    // Equipment slot validation
    if (card.type == CardType.weapon && 
        card.equipmentSlot != EquipmentSlot.weapon1 && 
        card.equipmentSlot != EquipmentSlot.weapon2) {
      errors.add('Weapon cards must have weapon1 or weapon2 equipment slot');
    }
    
    if (card.type == CardType.armor && 
        card.equipmentSlot != EquipmentSlot.armor &&
        card.equipmentSlot != EquipmentSlot.helmet &&
        card.equipmentSlot != EquipmentSlot.gloves &&
        card.equipmentSlot != EquipmentSlot.boots) {
      errors.add('Armor cards must have appropriate armor equipment slot');
    }
    
    return errors;
  }
  
  // Templates
  List<GameCard> getTemplates() => List.unmodifiable(_templates);
  
  Future<void> saveAsTemplate(GameCard card) async {
    final template = card.copyWith(id: null); // Generate new ID for template
    _templates.add(template);
    await _saveTemplates();
  }
  
  Future<void> deleteTemplate(String id) async {
    _templates.removeWhere((template) => template.id == id);
    await _saveTemplates();
  }
  
  GameCard createFromTemplate(String templateId) {
    final template = _templates.firstWhere((t) => t.id == templateId);
    return template.copyWith(id: null); // Generate new ID for the card
  }
  
  // Card Statistics
  Map<String, int> getCardStatistics() {
    final stats = <String, int>{};
    
    // Count by type
    for (final type in CardType.values) {
      stats['${type.name}_count'] = getCardsByType(type).length;
    }
    
    // Count by rarity
    for (final rarity in CardRarity.values) {
      stats['${rarity.name}_count'] = getCardsByRarity(rarity).length;
    }
    
    stats['total_cards'] = _cards.length;
    stats['total_templates'] = _templates.length;
    
    return stats;
  }
  
  // Import/Export
  String exportCards() {
    final data = {
      'cards': _cards.map((card) => card.toJson()).toList(),
      'templates': _templates.map((template) => template.toJson()).toList(),
      'exported_at': DateTime.now().toIso8601String(),
    };
    return jsonEncode(data);
  }
  
  Future<bool> importCards(String jsonData) async {
    try {
      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      
      if (data['cards'] != null) {
        final importedCards = (data['cards'] as List)
            .map((json) => GameCard.fromJson(json))
            .toList();
        _cards.addAll(importedCards);
        await _saveCards();
      }
      
      if (data['templates'] != null) {
        final importedTemplates = (data['templates'] as List)
            .map((json) => GameCard.fromJson(json))
            .toList();
        _templates.addAll(importedTemplates);
        await _saveTemplates();
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Quick Card Creation
  GameCard createBasicWeapon({
    required String name,
    required String description,
    int damage = 10,
    int levelRequirement = 1,
    CardRarity rarity = CardRarity.common,
  }) {
    return GameCard(
      name: name,
      description: description,
      type: CardType.weapon,
      rarity: rarity,
      equipmentSlot: EquipmentSlot.weapon1,
      levelRequirement: levelRequirement,
      statModifiers: [
        StatModifier(statName: 'damage', value: damage),
      ],
    );
  }
  
  GameCard createBasicArmor({
    required String name,
    required String description,
    required EquipmentSlot slot,
    int defense = 5,
    int levelRequirement = 1,
    CardRarity rarity = CardRarity.common,
  }) {
    return GameCard(
      name: name,
      description: description,
      type: CardType.armor,
      rarity: rarity,
      equipmentSlot: slot,
      levelRequirement: levelRequirement,
      statModifiers: [
        StatModifier(statName: 'defense', value: defense),
      ],
    );
  }
  
  GameCard createBasicConsumable({
    required String name,
    required String description,
    required String effectType,
    required int effectValue,
    int maxStack = 10,
    CardRarity rarity = CardRarity.common,
  }) {
    return GameCard(
      name: name,
      description: description,
      type: CardType.consumable,
      rarity: rarity,
      maxStack: maxStack,
      isConsumable: true,
      effects: [
        CardEffect(
          type: effectType,
          value: effectValue.toString(),
          description: description,
        ),
      ],
    );
  }
  
  // Random Card Generation
  GameCard generateRandomCard() {
    return generateEnhancedRandomCard();
  }
  
  // Generate treasure chest with multiple cards
  List<GameCard> generateTreasureChest(int cardCount) {
    final cards = <GameCard>[];
    for (int i = 0; i < cardCount; i++) {
      cards.add(generateRandomCard());
    }
    return cards;
  }
  
  // Enhanced card generation using the amazing database
  GameCard generateEnhancedRandomCard() {
    // Create amazing cards from the database instead of basic ones
    final random = Random();
    final epicCards = [
      // Legendary Weapons
      GameCard(
        name: 'Excalibur, Blade of Kings',
        description: 'A legendary sword that gleams with ancient power. +50 ATK, +20 DEF.',
        type: CardType.weapon,
        rarity: CardRarity.legendary,
        cost: 12,
        statModifiers: [
          StatModifier(statName: 'attack', value: 50),
          StatModifier(statName: 'defense', value: 20),
        ],
        levelRequirement: 25,
        equipmentSlot: EquipmentSlot.weapon1,
      ),
      GameCard(
        name: 'Shadowfang Dagger',
        description: 'Forged in the depths of shadow. +35 ATK, +15 AGI. Poison on critical hits.',
        type: CardType.weapon,
        rarity: CardRarity.epic,
        cost: 8,
        statModifiers: [
          StatModifier(statName: 'attack', value: 35),
          StatModifier(statName: 'dexterity', value: 15),
        ],
        levelRequirement: 15,
        equipmentSlot: EquipmentSlot.weapon1,
      ),
      GameCard(
        name: 'Storm Hammer Mjolnir',
        description: 'Thunder crashes with every swing. +45 ATK, +25 STR. Lightning damage.',
        type: CardType.weapon,
        rarity: CardRarity.legendary,
        cost: 11,
        statModifiers: [
          StatModifier(statName: 'attack', value: 45),
          StatModifier(statName: 'strength', value: 25),
        ],
        levelRequirement: 20,
        equipmentSlot: EquipmentSlot.weapon1,
      ),
      // Epic Armor
      GameCard(
        name: 'Ancient Dragon Scale Mail',
        description: 'Forged from dragon scales. +60 DEF, +30 HP. Fire immunity.',
        type: CardType.armor,
        rarity: CardRarity.mythic,
        cost: 15,
        statModifiers: [
          StatModifier(statName: 'defense', value: 60),
          StatModifier(statName: 'vitality', value: 30),
        ],
        levelRequirement: 30,
        equipmentSlot: EquipmentSlot.armor,
      ),
      GameCard(
        name: 'Arcane Silk Robes',
        description: 'Woven with magical threads. +15 DEF, +25 INT, +20 MP.',
        type: CardType.armor,
        rarity: CardRarity.uncommon,
        cost: 5,
        statModifiers: [
          StatModifier(statName: 'defense', value: 15),
          StatModifier(statName: 'energy', value: 25),
        ],
        levelRequirement: 8,
        equipmentSlot: EquipmentSlot.armor,
      ),
      // Powerful Spells
      GameCard(
        name: 'Meteor Storm',
        description: 'Rain fiery destruction from the heavens. Deals 80 damage to all enemies.',
        type: CardType.spell,
        rarity: CardRarity.legendary,
        cost: 10,
        statModifiers: [
          StatModifier(statName: 'attack', value: 80),
        ],
        levelRequirement: 22,
      ),
      GameCard(
        name: 'Divine Healing Light',
        description: 'Restore 50 HP and cure all ailments.',
        type: CardType.spell,
        rarity: CardRarity.rare,
        cost: 6,
        statModifiers: [
          StatModifier(statName: 'healing', value: 50),
        ],
        levelRequirement: 12,
      ),
      // Rare Consumables
      GameCard(
        name: 'Elixir of Eternal Life',
        description: 'Restore full HP and gain temporary invulnerability.',
        type: CardType.consumable,
        rarity: CardRarity.mythic,
        cost: 20,
        statModifiers: [
          StatModifier(statName: 'healing', value: 999),
        ],
        levelRequirement: 35,
        maxStack: 1,
      ),
      GameCard(
        name: 'Phoenix Rising Potion',
        description: 'Instantly revive with full health and +50% damage for 5 minutes.',
        type: CardType.consumable,
        rarity: CardRarity.legendary,
        cost: 12,
        statModifiers: [
          StatModifier(statName: 'revival', value: 1),
        ],
        levelRequirement: 18,
        maxStack: 3,
      ),
    ];
    
    // Weighted selection based on rarity
    final randomValue = random.nextDouble();
    if (randomValue < 0.1) {
      // 10% chance for epic+ cards
      final epicFiltered = epicCards.where((card) => 
        card.rarity == CardRarity.legendary || 
        card.rarity == CardRarity.mythic || 
        card.rarity == CardRarity.epic
      ).toList();
      return epicFiltered[random.nextInt(epicFiltered.length)];
    } else if (randomValue < 0.3) {
      // 20% chance for rare+ cards
      final rareFiltered = epicCards.where((card) => 
        card.rarity == CardRarity.rare || 
        card.rarity == CardRarity.epic ||
        card.rarity == CardRarity.legendary
      ).toList();
      return rareFiltered.isNotEmpty ? rareFiltered[random.nextInt(rareFiltered.length)] : epicCards[random.nextInt(epicCards.length)];
    } else {
      // 70% chance for any card
      return epicCards[random.nextInt(epicCards.length)];
    }
  }
  
  // Private helper methods
  void _loadCards() {
    final cardsJson = _prefs.getString(_cardsKey);
    if (cardsJson != null) {
      final cardsList = jsonDecode(cardsJson) as List;
      _cards.clear();
      _cards.addAll(cardsList.map((json) => GameCard.fromJson(json)));
    }
  }
  
  Future<void> _saveCards() async {
    final cardsJson = jsonEncode(_cards.map((card) => card.toJson()).toList());
    await _prefs.setString(_cardsKey, cardsJson);
  }
  
  void _loadTemplates() {
    final templatesJson = _prefs.getString(_templatesKey);
    if (templatesJson != null) {
      final templatesList = jsonDecode(templatesJson) as List;
      _templates.clear();
      _templates.addAll(templatesList.map((json) => GameCard.fromJson(json)));
    }
  }
  
  Future<void> _saveTemplates() async {
    final templatesJson = jsonEncode(_templates.map((template) => template.toJson()).toList());
    await _prefs.setString(_templatesKey, templatesJson);
  }
  
  void _initializeDefaultTemplates() {
    if (_templates.isEmpty) {
      _templates.addAll([
        createBasicWeapon(
          name: 'Basic Sword Template',
          description: 'A simple sword template for creating weapon cards',
          damage: 15,
        ),
        createBasicArmor(
          name: 'Basic Helmet Template',
          description: 'A simple helmet template for creating armor cards',
          slot: EquipmentSlot.helmet,
          defense: 8,
        ),
        createBasicConsumable(
          name: 'Health Potion Template',
          description: 'A healing potion template',
          effectType: 'heal',
          effectValue: 50,
        ),
      ]);
    }
  }
  
  String _generateRandomName(CardType type, CardRarity rarity) {
    final prefixes = {
      CardRarity.common: ['Simple', 'Basic', 'Plain'],
      CardRarity.uncommon: ['Fine', 'Quality', 'Sturdy'],
      CardRarity.rare: ['Superior', 'Excellent', 'Masterwork'],
      CardRarity.epic: ['Legendary', 'Heroic', 'Mythical'],
      CardRarity.legendary: ['Divine', 'Celestial', 'Eternal'],
      CardRarity.mythic: ['Godlike', 'Transcendent', 'Ultimate'],
    };
    
    final suffixes = {
      CardType.weapon: ['Sword', 'Axe', 'Bow', 'Staff', 'Dagger'],
      CardType.armor: ['Armor', 'Shield', 'Helmet', 'Boots', 'Gloves'],
      CardType.consumable: ['Potion', 'Elixir', 'Scroll', 'Tome', 'Crystal'],
      CardType.spell: ['Bolt', 'Wave', 'Storm', 'Blessing', 'Curse'],
      CardType.skill: ['Technique', 'Art', 'Mastery', 'Form', 'Style'],
    };
    
    final random = Random();
    final prefix = prefixes[rarity]![random.nextInt(prefixes[rarity]!.length)];
    final suffix = suffixes[type]![random.nextInt(suffixes[type]!.length)];
    
    return '$prefix $suffix';
  }
  
  String _generateRandomDescription(CardType type) {
    final descriptions = {
      CardType.weapon: [
        'A weapon forged in the fires of battle.',
        'Sharp steel that has seen many conflicts.',
        'A reliable tool for any adventurer.',
      ],
      CardType.armor: [
        'Protective gear crafted by skilled artisans.',
        'Sturdy defense against the dangers ahead.',
        'Armor that has saved many lives.',
      ],
      CardType.consumable: [
        'A useful item for any journey.',
        'Carefully prepared by skilled alchemists.',
        'A valuable resource in times of need.',
      ],
    };
    
    final random = Random();
    final typeDescriptions = descriptions[type] ?? ['A mysterious item of unknown origin.'];
    return typeDescriptions[random.nextInt(typeDescriptions.length)];
  }
  
  EquipmentSlot _getRandomEquipmentSlot(CardType type) {
    final slots = {
      CardType.weapon: [EquipmentSlot.weapon1, EquipmentSlot.weapon2],
      CardType.armor: [
        EquipmentSlot.helmet,
        EquipmentSlot.armor,
        EquipmentSlot.gloves,
        EquipmentSlot.boots,
      ],
      CardType.accessory: [
        EquipmentSlot.ring1,
        EquipmentSlot.ring2,
        EquipmentSlot.amulet,
        EquipmentSlot.belt,
      ],
    };
    
    final typeSlots = slots[type] ?? [EquipmentSlot.none];
    final random = Random();
    return typeSlots[random.nextInt(typeSlots.length)];
  }
  
  List<StatModifier> _generateRandomStatModifiers(CardType type, CardRarity rarity) {
    final random = Random();
    final rarityMultiplier = {
      CardRarity.common: 1,
      CardRarity.uncommon: 2,
      CardRarity.rare: 3,
      CardRarity.epic: 4,
      CardRarity.legendary: 5,
      CardRarity.mythic: 6,
    };
    
    final multiplier = rarityMultiplier[rarity] ?? 1;
    final modifiers = <StatModifier>[];
    
    switch (type) {
      case CardType.weapon:
        modifiers.add(StatModifier(
          statName: 'damage',
          value: (random.nextInt(10) + 5) * multiplier,
        ));
        if (random.nextBool()) {
          modifiers.add(StatModifier(
            statName: 'attack',
            value: (random.nextInt(20) + 10) * multiplier,
          ));
        }
        break;
      case CardType.armor:
        modifiers.add(StatModifier(
          statName: 'defense',
          value: (random.nextInt(8) + 3) * multiplier,
        ));
        if (random.nextBool()) {
          modifiers.add(StatModifier(
            statName: 'health',
            value: (random.nextInt(30) + 15) * multiplier,
          ));
        }
        break;
      case CardType.accessory:
        final stats = ['strength', 'dexterity', 'vitality', 'energy'];
        final stat = stats[random.nextInt(stats.length)];
        modifiers.add(StatModifier(
          statName: stat,
          value: (random.nextInt(5) + 2) * multiplier,
        ));
        break;
      default:
        break;
    }
    
    return modifiers;
  }
  
  void _loadUnlockedCards() {
    final unlockedJson = _prefs.getString(_unlockedCardsKey);
    if (unlockedJson != null) {
      final List<dynamic> unlocked = jsonDecode(unlockedJson);
      _unlockedCardIds.clear();
      _unlockedCardIds.addAll(unlocked.cast<String>());
    }
  }
  
  Future<void> _saveUnlockedCards() async {
    final unlockedJson = jsonEncode(_unlockedCardIds);
    await _prefs.setString(_unlockedCardsKey, unlockedJson);
  }
  
  List<String> get unlockedCardIds => List.unmodifiable(_unlockedCardIds);
  
  Future<void> unlockCard(String cardId) async {
    if (!_unlockedCardIds.contains(cardId)) {
      _unlockedCardIds.add(cardId);
      await _saveUnlockedCards();
    }
  }
  
  bool isCardUnlocked(String cardId) {
    return _unlockedCardIds.contains(cardId);
  }
}