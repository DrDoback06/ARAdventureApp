import 'package:realm_of_valor/models/card_model.dart';

class CardDatabase {
  static const Map<CardRarity, double> rarityWeights = {
    CardRarity.common: 0.60,
    CardRarity.uncommon: 0.25,
    CardRarity.rare: 0.10,
    CardRarity.epic: 0.04,
    CardRarity.legendary: 0.009,
    CardRarity.mythic: 0.001,
    CardRarity.holographic: 0.0005,
    CardRarity.firstEdition: 0.0002,
    CardRarity.limitedEdition: 0.0001,
  };

  static const Map<CardRarity, String> rarityColors = {
    CardRarity.common: '#FFFFFF',
    CardRarity.uncommon: '#00FF00',
    CardRarity.rare: '#0080FF',
    CardRarity.epic: '#8000FF',
    CardRarity.legendary: '#FF8000',
    CardRarity.mythic: '#FF0080',
    CardRarity.holographic: '#FFD700',
    CardRarity.firstEdition: '#FF4500',
    CardRarity.limitedEdition: '#DC143C',
  };

  // WEAPONS - Diablo-style with amazing variety
  static List<GameCard> get weapons => [
    // Legendary Weapons
    GameCard(
      id: 'excalibur',
      name: 'Excalibur, Blade of Kings',
      description: 'A legendary sword that gleams with ancient power. +50 ATK, +20 DEF. Grants immunity to fear effects.',
      type: CardType.item,
      rarity: CardRarity.legendary,
      set: CardSet.ancients,
      cost: 12,
      attack: 50,
      defense: 20,
      effects: [
        CardEffect(type: 'immunity', value: 'fear'),
        CardEffect(type: 'bonus_xp', value: '25'),
      ],
      imageUrl: 'assets/cards/excalibur.png',
      physicalCardId: 'PHYS_EXC_001',
    ),
    GameCard(
      id: 'shadowfang',
      name: 'Shadowfang Dagger',
      description: 'Forged in the depths of shadow. +35 ATK, +15 AGI. Chance to inflict poison on critical hits.',
      type: CardType.item,
      rarity: CardRarity.epic,
      set: CardSet.shadows,
      cost: 8,
      attack: 35,
      agility: 15,
      effects: [
        CardEffect(type: 'critical_poison', value: '30'),
        CardEffect(type: 'stealth_bonus', value: '10'),
      ],
      imageUrl: 'assets/cards/shadowfang.png',
    ),
    GameCard(
      id: 'stormhammer',
      name: 'Mjolnir, Storm Hammer',
      description: 'Thunder crashes with every swing. +45 ATK, +25 STR. Lightning damage on all attacks.',
      type: CardType.item,
      rarity: CardRarity.legendary,
      set: CardSet.elements,
      cost: 11,
      attack: 45,
      strength: 25,
      effects: [
        CardEffect(type: 'lightning_damage', value: '20'),
        CardEffect(type: 'area_damage', value: '3'),
      ],
      imageUrl: 'assets/cards/stormhammer.png',
      physicalCardId: 'PHYS_MJO_001',
    ),
    // Common to Rare Weapons
    GameCard(
      id: 'iron_sword',
      name: 'Iron Sword',
      description: 'A reliable blade for new adventurers. +15 ATK.',
      type: CardType.item,
      rarity: CardRarity.common,
      set: CardSet.core,
      cost: 3,
      attack: 15,
      imageUrl: 'assets/cards/iron_sword.png',
    ),
    GameCard(
      id: 'elvish_bow',
      name: 'Elvish Longbow',
      description: 'Crafted by woodland elves. +25 ATK, +10 AGI. Increased range.',
      type: CardType.item,
      rarity: CardRarity.uncommon,
      set: CardSet.core,
      cost: 5,
      attack: 25,
      agility: 10,
      effects: [
        CardEffect(type: 'range_bonus', value: '5'),
      ],
      imageUrl: 'assets/cards/elvish_bow.png',
    ),
    GameCard(
      id: 'fire_staff',
      name: 'Staff of Burning Embers',
      description: 'Channels the power of flame. +20 ATK, +15 INT. Fire spells cost 2 less mana.',
      type: CardType.item,
      rarity: CardRarity.rare,
      set: CardSet.elements,
      cost: 7,
      attack: 20,
      intelligence: 15,
      effects: [
        CardEffect(type: 'fire_cost_reduction', value: '2'),
        CardEffect(type: 'fire_damage_bonus', value: '10'),
      ],
      imageUrl: 'assets/cards/fire_staff.png',
    ),
  ];

  // ARMOR - Defensive gear with set bonuses
  static List<GameCard> get armor => [
    GameCard(
      id: 'dragon_scale_armor',
      name: 'Ancient Dragon Scale Mail',
      description: 'Forged from the scales of an ancient red dragon. +60 DEF, +30 HP. Immune to fire damage.',
      type: CardType.item,
      rarity: CardRarity.mythic,
      set: CardSet.ancients,
      cost: 15,
      defense: 60,
      health: 30,
      effects: [
        CardEffect(type: 'immunity', value: 'fire'),
        CardEffect(type: 'fear_aura', value: '5'),
      ],
      imageUrl: 'assets/cards/dragon_scale_armor.png',
      physicalCardId: 'PHYS_DRA_001',
    ),
    GameCard(
      id: 'leather_armor',
      name: 'Studded Leather Armor',
      description: 'Light protection for agile fighters. +20 DEF, +5 AGI.',
      type: CardType.item,
      rarity: CardRarity.common,
      set: CardSet.core,
      cost: 4,
      defense: 20,
      agility: 5,
      imageUrl: 'assets/cards/leather_armor.png',
    ),
    GameCard(
      id: 'mage_robes',
      name: 'Arcane Silk Robes',
      description: 'Woven with magical threads. +15 DEF, +25 INT, +20 MP.',
      type: CardType.item,
      rarity: CardRarity.uncommon,
      set: CardSet.mystics,
      cost: 5,
      defense: 15,
      intelligence: 25,
      mana: 20,
      effects: [
        CardEffect(type: 'spell_power', value: '10'),
      ],
      imageUrl: 'assets/cards/mage_robes.png',
    ),
  ];

  // SPELLS - Magical abilities
  static List<GameCard> get spells => [
    GameCard(
      id: 'meteor',
      name: 'Meteor Storm',
      description: 'Rain fiery destruction from the heavens. Deals 80 damage to all enemies.',
      type: CardType.spell,
      rarity: CardRarity.legendary,
      set: CardSet.elements,
      cost: 10,
      attack: 80,
      effects: [
        CardEffect(type: 'area_damage', value: 'all'),
        CardEffect(type: 'burn', value: '3'),
      ],
      imageUrl: 'assets/cards/meteor.png',
    ),
    GameCard(
      id: 'healing_light',
      name: 'Divine Healing Light',
      description: 'Restore 50 HP and cure all ailments.',
      type: CardType.spell,
      rarity: CardRarity.rare,
      set: CardSet.mystics,
      cost: 6,
      effects: [
        CardEffect(type: 'heal', value: '50'),
        CardEffect(type: 'cure_all', value: '1'),
      ],
      imageUrl: 'assets/cards/healing_light.png',
    ),
    GameCard(
      id: 'fireball',
      name: 'Fireball',
      description: 'Launch a ball of flame at your enemy. Deals 30 fire damage.',
      type: CardType.spell,
      rarity: CardRarity.common,
      set: CardSet.elements,
      cost: 3,
      attack: 30,
      effects: [
        CardEffect(type: 'fire_damage', value: '30'),
      ],
      imageUrl: 'assets/cards/fireball.png',
    ),
  ];

  // ENEMIES - Monsters to battle
  static List<GameCard> get enemies => [
    GameCard(
      id: 'ancient_dragon',
      name: 'Bahamut, The Ancient Dragon',
      description: 'The most feared dragon in all the realms. Immense power and ancient wisdom.',
      type: CardType.enemy,
      rarity: CardRarity.mythic,
      set: CardSet.ancients,
      cost: 0,
      attack: 120,
      defense: 80,
      health: 500,
      effects: [
        CardEffect(type: 'breath_weapon', value: '100'),
        CardEffect(type: 'fear_aura', value: '10'),
        CardEffect(type: 'spell_immunity', value: '50'),
      ],
      imageUrl: 'assets/cards/ancient_dragon.png',
      physicalCardId: 'PHYS_BAH_001',
    ),
    GameCard(
      id: 'shadow_wraith',
      name: 'Shadow Wraith',
      description: 'A malevolent spirit that feeds on fear.',
      type: CardType.enemy,
      rarity: CardRarity.rare,
      set: CardSet.shadows,
      cost: 0,
      attack: 45,
      defense: 20,
      health: 80,
      effects: [
        CardEffect(type: 'drain_life', value: '15'),
        CardEffect(type: 'incorporeal', value: '1'),
      ],
      imageUrl: 'assets/cards/shadow_wraith.png',
    ),
    GameCard(
      id: 'goblin_warrior',
      name: 'Goblin Warrior',
      description: 'A fierce but small warrior from the mountain caves.',
      type: CardType.enemy,
      rarity: CardRarity.common,
      set: CardSet.core,
      cost: 0,
      attack: 20,
      defense: 15,
      health: 35,
      imageUrl: 'assets/cards/goblin_warrior.png',
    ),
  ];

  // ACTION CARDS - Pokemon-style battle moves
  static List<GameCard> get actions => [
    GameCard(
      id: 'berserker_rage',
      name: 'Berserker Rage',
      description: 'Enter a violent rage. Double attack for 3 turns, but take 25% more damage.',
      type: CardType.action,
      rarity: CardRarity.epic,
      set: CardSet.champions,
      cost: 4,
      effects: [
        CardEffect(type: 'double_attack', value: '3'),
        CardEffect(type: 'damage_taken_increase', value: '25'),
      ],
      imageUrl: 'assets/cards/berserker_rage.png',
    ),
    GameCard(
      id: 'stealth_strike',
      name: 'Stealth Strike',
      description: 'Become invisible and strike from the shadows. Guaranteed critical hit.',
      type: CardType.action,
      rarity: CardRarity.rare,
      set: CardSet.shadows,
      cost: 3,
      effects: [
        CardEffect(type: 'stealth', value: '1'),
        CardEffect(type: 'guaranteed_critical', value: '1'),
      ],
      imageUrl: 'assets/cards/stealth_strike.png',
    ),
    GameCard(
      id: 'power_strike',
      name: 'Power Strike',
      description: 'A basic but effective attack. +10 damage.',
      type: CardType.action,
      rarity: CardRarity.common,
      set: CardSet.core,
      cost: 2,
      attack: 10,
      imageUrl: 'assets/cards/power_strike.png',
    ),
  ];

  // CONSUMABLES - Potions and items
  static List<GameCard> get consumables => [
    GameCard(
      id: 'elixir_of_life',
      name: 'Elixir of Eternal Life',
      description: 'A legendary potion that extends life. Restore full HP and gain temporary invulnerability.',
      type: CardType.consumable,
      rarity: CardRarity.mythic,
      set: CardSet.ancients,
      cost: 20,
      effects: [
        CardEffect(type: 'full_heal', value: '1'),
        CardEffect(type: 'invulnerability', value: '5'),
      ],
      imageUrl: 'assets/cards/elixir_of_life.png',
      physicalCardId: 'PHYS_ELI_001',
    ),
    GameCard(
      id: 'health_potion',
      name: 'Health Potion',
      description: 'Restore 50 HP.',
      type: CardType.consumable,
      rarity: CardRarity.common,
      set: CardSet.core,
      cost: 2,
      effects: [
        CardEffect(type: 'heal', value: '50'),
      ],
      imageUrl: 'assets/cards/health_potion.png',
    ),
  ];

  // Get all cards
  static List<GameCard> get allCards => [
    ...weapons,
    ...armor,
    ...spells,
    ...enemies,
    ...actions,
    ...consumables,
  ];

  // Get cards by rarity
  static List<GameCard> getCardsByRarity(CardRarity rarity) {
    return allCards.where((card) => card.rarity == rarity).toList();
  }

  // Get cards by set
  static List<GameCard> getCardsBySet(CardSet set) {
    return allCards.where((card) => card.set == set).toList();
  }

  // Get random card with rarity weights
  static GameCard getRandomCard() {
    final random = DateTime.now().millisecondsSinceEpoch;
    double totalWeight = rarityWeights.values.reduce((a, b) => a + b);
    double randomValue = (random % 1000) / 1000.0 * totalWeight;
    
    double currentWeight = 0.0;
    for (final rarity in rarityWeights.keys) {
      currentWeight += rarityWeights[rarity]!;
      if (randomValue <= currentWeight) {
        final cardsOfRarity = getCardsByRarity(rarity);
        if (cardsOfRarity.isNotEmpty) {
          return cardsOfRarity[random % cardsOfRarity.length];
        }
      }
    }
    
    return allCards.first; // Fallback
  }

  // Get booster pack (5 cards with guaranteed rare+)
  static List<GameCard> getBoosterPack() {
    final pack = <GameCard>[];
    
    // Guaranteed rare or better
    final rareCards = allCards.where((card) => 
      card.rarity == CardRarity.rare || 
      card.rarity == CardRarity.epic ||
      card.rarity == CardRarity.legendary ||
      card.rarity == CardRarity.mythic
    ).toList();
    
    final random = DateTime.now().millisecondsSinceEpoch;
    pack.add(rareCards[random % rareCards.length]);
    
    // 4 additional random cards
    for (int i = 0; i < 4; i++) {
      pack.add(getRandomCard());
    }
    
    return pack;
  }

  // Physical card integration
  static GameCard? getCardByPhysicalId(String physicalId) {
    return allCards.firstWhere(
      (card) => card.physicalCardId == physicalId,
      orElse: () => allCards.first,
    );
  }

  // Deck building helpers
  static bool isValidDeck(List<GameCard> deck) {
    return deck.length >= 30 && deck.length <= 60;
  }

  static int getTotalDeckCost(List<GameCard> deck) {
    return deck.fold(0, (sum, card) => sum + card.cost);
  }
}