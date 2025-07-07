import 'package:json_annotation/json_annotation.dart';
import 'package:realm_of_valor/models/card_model.dart';
import 'package:realm_of_valor/models/adventure_system.dart';
import 'package:uuid/uuid.dart';
import 'dart:math' as math;

part 'merchant_system.g.dart';

enum MerchantType {
  wandering,
  fitness,
  guild,
  legendary,
  seasonal,
  physical,
}

enum MerchantRarity {
  common,
  rare,
  epic,
  legendary,
}

@JsonSerializable()
class MerchantInventoryItem {
  final String cardId;
  final int price;
  final int stock;
  final double discountPercent;
  final Map<String, dynamic> requirements;
  final bool isLimitedTime;
  final DateTime? expiresAt;

  MerchantInventoryItem({
    required this.cardId,
    required this.price,
    this.stock = 1,
    this.discountPercent = 0.0,
    Map<String, dynamic>? requirements,
    this.isLimitedTime = false,
    this.expiresAt,
  }) : requirements = requirements ?? {};

  factory MerchantInventoryItem.fromJson(Map<String, dynamic> json) =>
      _$MerchantInventoryItemFromJson(json);
  Map<String, dynamic> toJson() => _$MerchantInventoryItemToJson(this);

  int get finalPrice => (price * (1 - discountPercent / 100)).round();
  bool get isAvailable => stock > 0 && (!isLimitedTime || (expiresAt?.isAfter(DateTime.now()) ?? true));
}

@JsonSerializable()
class Merchant {
  final String id;
  final String name;
  final String description;
  final MerchantType type;
  final MerchantRarity rarity;
  final GeoLocation? location;
  final double? radius;
  final List<MerchantInventoryItem> inventory;
  final DateTime spawnTime;
  final DateTime? despawnTime;
  final bool isActive;
  final Map<String, dynamic> specialOffers;
  final List<String> dialogues;
  final String avatarUrl;
  final Map<String, dynamic> metadata;

  Merchant({
    String? id,
    required this.name,
    required this.description,
    required this.type,
    this.rarity = MerchantRarity.common,
    this.location,
    this.radius = 100.0,
    List<MerchantInventoryItem>? inventory,
    DateTime? spawnTime,
    this.despawnTime,
    this.isActive = true,
    Map<String, dynamic>? specialOffers,
    List<String>? dialogues,
    this.avatarUrl = '',
    Map<String, dynamic>? metadata,
  }) : id = id ?? const Uuid().v4(),
       inventory = inventory ?? [],
       spawnTime = spawnTime ?? DateTime.now(),
       specialOffers = specialOffers ?? {},
       dialogues = dialogues ?? [],
       metadata = metadata ?? {};

  factory Merchant.fromJson(Map<String, dynamic> json) =>
      _$MerchantFromJson(json);
  Map<String, dynamic> toJson() => _$MerchantToJson(this);

  Merchant copyWith({
    String? id,
    String? name,
    String? description,
    MerchantType? type,
    MerchantRarity? rarity,
    GeoLocation? location,
    double? radius,
    List<MerchantInventoryItem>? inventory,
    DateTime? spawnTime,
    DateTime? despawnTime,
    bool? isActive,
    Map<String, dynamic>? specialOffers,
    List<String>? dialogues,
    String? avatarUrl,
    Map<String, dynamic>? metadata,
  }) {
    return Merchant(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      location: location ?? this.location,
      radius: radius ?? this.radius,
      inventory: inventory ?? this.inventory,
      spawnTime: spawnTime ?? this.spawnTime,
      despawnTime: despawnTime ?? this.despawnTime,
      isActive: isActive ?? this.isActive,
      specialOffers: specialOffers ?? this.specialOffers,
      dialogues: dialogues ?? this.dialogues,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isExpired => despawnTime != null && DateTime.now().isAfter(despawnTime!);
  List<MerchantInventoryItem> get availableItems => inventory.where((item) => item.isAvailable).toList();
  int get totalItems => inventory.fold(0, (sum, item) => sum + item.stock);
}

class MerchantSystem {
  // Epic merchants with amazing inventories!
  static List<Merchant> get legendaryMerchants => [
    Merchant(
      name: 'Zelios the Eternal Trader',
      description: 'A legendary merchant who has traveled across realms for centuries, bringing the rarest artifacts to worthy adventurers.',
      type: MerchantType.legendary,
      rarity: MerchantRarity.legendary,
      inventory: [
        MerchantInventoryItem(
          cardId: 'excalibur',
          price: 10000,
          stock: 1,
          requirements: {'level': 50, 'legendary_quests_completed': 5},
          isLimitedTime: true,
          expiresAt: DateTime.now().add(Duration(hours: 24)),
        ),
        MerchantInventoryItem(
          cardId: 'ancient_dragon',
          price: 15000,
          stock: 1,
          requirements: {'dragons_defeated': 3, 'guild_rank': 'captain'},
        ),
        MerchantInventoryItem(
          cardId: 'elixir_of_life',
          price: 5000,
          stock: 3,
          discountPercent: 20.0,
        ),
      ],
      dialogues: [
        'Ah, another seeker of power! I have just the thing for someone of your... caliber.',
        'These artifacts have seen the rise and fall of empires. Choose wisely!',
        'My wares are not for the weak-hearted. Each item carries the weight of legend.',
      ],
      specialOffers: {
        'bundle_deal': 'Buy 3 legendary items, get 25% off the total!',
        'loyalty_discount': 'Return customers get 10% off all purchases',
      },
    ),
    Merchant(
      name: 'Master Forge-Heart',
      description: 'The greatest weaponsmith in all the realms, crafting weapons for heroes who prove their worth through fitness and dedication.',
      type: MerchantType.fitness,
      rarity: MerchantRarity.epic,
      inventory: [
        MerchantInventoryItem(
          cardId: 'stormhammer',
          price: 7500,
          stock: 2,
          requirements: {'steps_total': 100000, 'calories_burned': 5000},
        ),
        MerchantInventoryItem(
          cardId: 'shadowfang',
          price: 6000,
          stock: 1,
          requirements: {'distance_traveled': 50000, 'battles_won': 25},
        ),
        MerchantInventoryItem(
          cardId: 'dragon_scale_armor',
          price: 8000,
          stock: 1,
          requirements: {'fitness_achievements': 10, 'perfect_battles': 3},
        ),
      ],
      dialogues: [
        'Only those who forge their bodies can wield weapons I forge! Show me your dedication!',
        'Each step you take, each calorie you burn - these make you worthy of my masterwork.',
        'True strength comes from within. Your fitness journey proves your inner fire!',
      ],
      specialOffers: {
        'fitness_warrior_discount': 'Active fitness trackers get 15% off all weapons!',
        'marathon_achievement': 'Complete a marathon distance for exclusive weapon access!',
      },
    ),
  ];

  // Wandering merchants that appear in different locations
  static List<Merchant> get wanderingMerchants => [
    Merchant(
      name: 'Pip the Potion Peddler',
      description: 'A cheerful gnome who appears in parks with healing potions and magical trinkets.',
      type: MerchantType.wandering,
      rarity: MerchantRarity.common,
      inventory: [
        MerchantInventoryItem(cardId: 'health_potion', price: 50, stock: 10),
        MerchantInventoryItem(cardId: 'mana_potion', price: 75, stock: 8),
        MerchantInventoryItem(cardId: 'healing_herbs', price: 25, stock: 15),
        MerchantInventoryItem(cardId: 'energy_drink', price: 100, stock: 5),
      ],
      dialogues: [
        'Welcome, welcome! Fresh potions brewed this morning!',
        'Feeling tired from your adventures? I have just the remedy!',
        'My grandmother\'s recipes - guaranteed to restore your vitality!',
      ],
      despawnTime: DateTime.now().add(Duration(hours: 6)),
    ),
    Merchant(
      name: 'Captain Cardsworth',
      description: 'A mysterious figure in a long coat who deals in rare cards and mysterious artifacts.',
      type: MerchantType.wandering,
      rarity: MerchantRarity.rare,
      inventory: [
        MerchantInventoryItem(cardId: 'mystery_box', price: 200, stock: 5),
        MerchantInventoryItem(cardId: 'rare_card_pack', price: 500, stock: 3),
        MerchantInventoryItem(cardId: 'ancient_scroll', price: 300, stock: 2),
        MerchantInventoryItem(cardId: 'lucky_charm', price: 750, stock: 1),
      ],
      dialogues: [
        'Psst... I\'ve got some items that fell off a dragon\'s hoard...',
        'These cards? Let\'s just say they have... interesting origins.',
        'Buyer beware - some of these items have minds of their own!',
      ],
      despawnTime: DateTime.now().add(Duration(hours: 4)),
    ),
  ];

  // Fitness-focused merchants that reward active players
  static List<Merchant> get fitnessMerchants => [
    Merchant(
      name: 'Coach Thunder',
      description: 'A motivational fitness guru who rewards dedication with powerful equipment.',
      type: MerchantType.fitness,
      rarity: MerchantRarity.rare,
      inventory: [
        MerchantInventoryItem(
          cardId: 'runner_boots',
          price: 1000,
          stock: 5,
          requirements: {'daily_steps': 10000},
          discountPercent: 25.0,
        ),
        MerchantInventoryItem(
          cardId: 'warrior_training',
          price: 800,
          stock: 3,
          requirements: {'calories_burned_today': 500},
        ),
        MerchantInventoryItem(
          cardId: 'endurance_boost',
          price: 1200,
          stock: 2,
          requirements: {'active_days_streak': 7},
        ),
        MerchantInventoryItem(
          cardId: 'champion_spirit',
          price: 2000,
          stock: 1,
          requirements: {'fitness_level': 25, 'marathons_completed': 1},
        ),
      ],
      dialogues: [
        'No pain, no gain! Your dedication deserves the best gear!',
        'I can see the fire in your eyes - that\'s the spirit of a true champion!',
        'Every step counts, every rep matters! Let me fuel your journey!',
      ],
      specialOffers: {
        'daily_athlete_bonus': 'Complete daily fitness goals for 25% off!',
        'streak_reward': 'Maintain a 7-day streak for exclusive items!',
      },
    ),
  ];

  // Guild merchants with exclusive member benefits
  static List<Merchant> get guildMerchants => [
    Merchant(
      name: 'Guild Quartermaster Magnus',
      description: 'Serves guild members with exclusive equipment and supplies.',
      type: MerchantType.guild,
      rarity: MerchantRarity.epic,
      inventory: [
        MerchantInventoryItem(
          cardId: 'guild_banner',
          price: 2500,
          stock: 1,
          requirements: {'guild_rank': 'officer'},
        ),
        MerchantInventoryItem(
          cardId: 'brotherhood_ring',
          price: 1500,
          stock: 5,
          requirements: {'guild_member': true},
          discountPercent: 30.0,
        ),
        MerchantInventoryItem(
          cardId: 'teamwork_charm',
          price: 1000,
          stock: 10,
          requirements: {'guild_events_participated': 3},
        ),
      ],
      dialogues: [
        'Greetings, guild member! Your loyalty deserves the finest rewards.',
        'Together we are stronger! These items will aid your guild\'s glory.',
        'Your guild\'s achievements unlock greater treasures!',
      ],
      specialOffers: {
        'guild_loyalty_discount': 'Guild members get special pricing!',
        'bulk_guild_order': 'Order for the entire guild at wholesale prices!',
      },
    ),
  ];

  // Seasonal and event merchants
  static List<Merchant> get seasonalMerchants => [
    Merchant(
      name: 'Holly the Winter Sprite',
      description: 'Brings magical winter items during the holiday season.',
      type: MerchantType.seasonal,
      rarity: MerchantRarity.rare,
      inventory: [
        MerchantInventoryItem(cardId: 'winter_crown', price: 1500, stock: 3),
        MerchantInventoryItem(cardId: 'frost_sword', price: 2000, stock: 2),
        MerchantInventoryItem(cardId: 'snow_spirit', price: 1200, stock: 5),
        MerchantInventoryItem(cardId: 'holiday_cheer', price: 500, stock: 10),
      ],
      dialogues: [
        'Brrr! The winter magic is strong this season!',
        'These items carry the joy and wonder of the winter holidays!',
        'May your adventures be merry and your battles victorious!',
      ],
      specialOffers: {
        'holiday_special': 'Buy 2 items, get 1 free during December!',
        'new_year_resolution': 'Fitness goals unlock exclusive winter gear!',
      },
      despawnTime: DateTime.now().add(Duration(days: 30)), // Available for a month
    ),
  ];

  // Dynamic inventory generation (Diablo-style!)
  static List<MerchantInventoryItem> generateRandomInventory(
    MerchantType type,
    MerchantRarity rarity,
    Map<String, dynamic> playerStats,
  ) {
    final random = math.Random();
    final inventory = <MerchantInventoryItem>[];
    
    // Base inventory size based on merchant rarity
    int inventorySize = 3;
    switch (rarity) {
      case MerchantRarity.common:
        inventorySize = random.nextInt(3) + 3; // 3-5 items
        break;
      case MerchantRarity.rare:
        inventorySize = random.nextInt(4) + 5; // 5-8 items
        break;
      case MerchantRarity.epic:
        inventorySize = random.nextInt(6) + 8; // 8-13 items
        break;
      case MerchantRarity.legendary:
        inventorySize = random.nextInt(8) + 15; // 15-22 items
        break;
    }

    // Available card pools based on merchant type
    final cardPools = _getCardPoolsForMerchant(type, playerStats);
    
    for (int i = 0; i < inventorySize; i++) {
      if (cardPools.isNotEmpty) {
        final cardId = cardPools[random.nextInt(cardPools.length)];
        final basePrice = _calculateCardPrice(cardId, rarity);
        final stock = random.nextInt(3) + 1;
        final hasDiscount = random.nextDouble() < 0.3; // 30% chance for discount
        final discount = hasDiscount ? random.nextDouble() * 25 : 0.0; // Up to 25% off
        
        inventory.add(MerchantInventoryItem(
          cardId: cardId,
          price: basePrice,
          stock: stock,
          discountPercent: discount,
          requirements: _generateRequirements(cardId, type),
        ));
      }
    }
    
    return inventory;
  }

  static List<String> _getCardPoolsForMerchant(MerchantType type, Map<String, dynamic> playerStats) {
    switch (type) {
      case MerchantType.fitness:
        return [
          'runner_boots', 'warrior_training', 'endurance_boost', 'strength_potion',
          'speed_boots', 'champion_spirit', 'fitness_tracker', 'energy_drink',
          'protein_powder', 'workout_gear', 'motivation_crystal'
        ];
      case MerchantType.wandering:
        return [
          'health_potion', 'mana_potion', 'mystery_box', 'ancient_scroll',
          'lucky_charm', 'traveler_pack', 'compass', 'map_fragment',
          'healing_herbs', 'energy_crystal'
        ];
      case MerchantType.guild:
        return [
          'guild_banner', 'brotherhood_ring', 'teamwork_charm', 'leadership_crown',
          'guild_emblem', 'cooperation_crystal', 'unity_gem', 'alliance_seal'
        ];
      case MerchantType.legendary:
        return [
          'excalibur', 'stormhammer', 'ancient_dragon', 'elixir_of_life',
          'dragon_scale_armor', 'phoenix_feather', 'time_crystal', 'void_essence',
          'cosmic_orb', 'infinity_stone'
        ];
      case MerchantType.seasonal:
        return [
          'winter_crown', 'spring_blossom', 'summer_flame', 'autumn_leaf',
          'holiday_cheer', 'seasonal_spirit', 'festival_mask', 'celebration_firework'
        ];
      case MerchantType.physical:
        return [
          'PHYS_EXC_001', 'PHYS_MJO_001', 'PHYS_DRA_001', 'PHYS_BAH_001',
          'collectors_album', 'trading_handbook', 'card_protector'
        ];
      default:
        return ['health_potion', 'mystery_box', 'ancient_scroll'];
    }
  }

  static int _calculateCardPrice(String cardId, MerchantRarity merchantRarity) {
    // Base prices based on card rarity and merchant rarity
    int basePrice = 100;
    
    // Legendary cards cost more
    if (cardId.contains('excalibur') || cardId.contains('dragon') || cardId.contains('ancient')) {
      basePrice = 5000;
    } else if (cardId.contains('storm') || cardId.contains('shadow') || cardId.contains('epic')) {
      basePrice = 2000;
    } else if (cardId.contains('rare') || cardId.contains('magic')) {
      basePrice = 500;
    }
    
    // Merchant rarity affects prices
    switch (merchantRarity) {
      case MerchantRarity.common:
        return (basePrice * 1.0).round();
      case MerchantRarity.rare:
        return (basePrice * 0.85).round(); // 15% discount
      case MerchantRarity.epic:
        return (basePrice * 0.75).round(); // 25% discount
      case MerchantRarity.legendary:
        return (basePrice * 0.60).round(); // 40% discount
    }
  }

  static Map<String, dynamic> _generateRequirements(String cardId, MerchantType type) {
    final requirements = <String, dynamic>{};
    
    switch (type) {
      case MerchantType.fitness:
        requirements['steps_total'] = 5000;
        requirements['calories_burned'] = 200;
        break;
      case MerchantType.guild:
        requirements['guild_member'] = true;
        break;
      case MerchantType.legendary:
        requirements['level'] = 25;
        requirements['achievements_unlocked'] = 10;
        break;
      default:
        break;
    }
    
    return requirements;
  }

  // Merchant spawning system for real-world locations
  static Merchant spawnMerchantAtLocation(GeoLocation location, LocationType locationType) {
    final random = math.Random();
    
    // Different location types spawn different merchant types
    MerchantType merchantType;
    switch (locationType) {
      case LocationType.gym:
        merchantType = MerchantType.fitness;
        break;
      case LocationType.business:
        merchantType = MerchantType.wandering;
        break;
      case LocationType.park:
        merchantType = random.nextBool() ? MerchantType.wandering : MerchantType.seasonal;
        break;
      default:
        merchantType = MerchantType.wandering;
    }
    
    final rarity = _generateMerchantRarity();
    final name = _generateMerchantName(merchantType, rarity);
    final description = _generateMerchantDescription(merchantType);
    
    return Merchant(
      name: name,
      description: description,
      type: merchantType,
      rarity: rarity,
      location: location,
      inventory: generateRandomInventory(merchantType, rarity, {}),
      dialogues: _generateMerchantDialogues(merchantType),
      despawnTime: DateTime.now().add(Duration(
        hours: rarity == MerchantRarity.legendary ? 24 : random.nextInt(8) + 2,
      )),
    );
  }

  static MerchantRarity _generateMerchantRarity() {
    final random = math.Random();
    final roll = random.nextDouble();
    
    if (roll < 0.01) return MerchantRarity.legendary; // 1%
    if (roll < 0.10) return MerchantRarity.epic;      // 9%
    if (roll < 0.30) return MerchantRarity.rare;      // 20%
    return MerchantRarity.common;                     // 70%
  }

  static String _generateMerchantName(MerchantType type, MerchantRarity rarity) {
    final names = {
      MerchantType.fitness: ['Coach Thunder', 'Trainer Maximus', 'Fitness Guru Zen', 'Iron Will Smith'],
      MerchantType.wandering: ['Pip the Peddler', 'Roaming Roger', 'Wanderer William', 'Nomad Nancy'],
      MerchantType.guild: ['Quartermaster Quinn', 'Guild Master Grant', 'Brotherhood Bob', 'Unity Uma'],
      MerchantType.legendary: ['Zelios the Eternal', 'Mystic Marcus', 'Legendary Luna', 'Ancient Atlas'],
      MerchantType.seasonal: ['Holly Winter-heart', 'Spring Blossom', 'Summer Solaris', 'Autumn Amber'],
    };
    
    final typeNames = names[type] ?? ['Mysterious Merchant'];
    final random = math.Random();
    return typeNames[random.nextInt(typeNames.length)];
  }

  static String _generateMerchantDescription(MerchantType type) {
    final descriptions = {
      MerchantType.fitness: 'A dedicated trainer who rewards fitness achievements with powerful gear.',
      MerchantType.wandering: 'A mysterious traveler with exotic goods from distant lands.',
      MerchantType.guild: 'A loyal supporter of guilds and communities.',
      MerchantType.legendary: 'An ancient being with access to the rarest artifacts.',
      MerchantType.seasonal: 'A seasonal spirit bringing themed items and joy.',
    };
    
    return descriptions[type] ?? 'A merchant with interesting wares.';
  }

  static List<String> _generateMerchantDialogues(MerchantType type) {
    final dialogues = {
      MerchantType.fitness: [
        'Stay strong, warrior! Your dedication deserves the best gear!',
        'I can see the fire of determination in your eyes!',
        'Every step forward is a step toward greatness!',
      ],
      MerchantType.wandering: [
        'Welcome, traveler! I have wares from distant realms!',
        'These items have seen many adventures - now they seek new heroes!',
        'Coin for goods, stories for memories!',
      ],
      MerchantType.guild: [
        'United we stand! Your guild deserves the finest equipment!',
        'Together we are stronger than any individual!',
        'Your loyalty to your guild is commendable!',
      ],
      MerchantType.legendary: [
        'These artifacts have witnessed the rise and fall of empires...',
        'Only the worthy may claim these legendary treasures.',
        'Power calls to power - I sense great potential in you.',
      ],
      MerchantType.seasonal: [
        'The seasons bring magic and wonder to our world!',
        'Celebrate the beauty of nature with these special items!',
        'Each season has its own gifts for those who appreciate them!',
      ],
    };
    
    return dialogues[type] ?? ['Welcome to my shop!'];
  }

  // Special merchant events
  static List<Merchant> createMegaSaleEvent() {
    return [
      Merchant(
        name: 'Flash Sale Felix',
        description: 'A time-limited merchant offering incredible deals!',
        type: MerchantType.wandering,
        rarity: MerchantRarity.epic,
        inventory: [
          MerchantInventoryItem(cardId: 'legendary_pack', price: 1000, stock: 100, discountPercent: 75.0),
          MerchantInventoryItem(cardId: 'epic_bundle', price: 500, stock: 200, discountPercent: 60.0),
          MerchantInventoryItem(cardId: 'rare_collection', price: 200, stock: 500, discountPercent: 50.0),
        ],
        dialogues: [
          'FLASH SALE! Everything must go!',
          'These prices won\'t last long - grab them while you can!',
          'Once in a lifetime deals happening RIGHT NOW!',
        ],
        specialOffers: {
          'flash_sale': 'Limited time only - massive discounts on everything!',
        },
        despawnTime: DateTime.now().add(Duration(hours: 2)), // Only 2 hours!
      ),
    ];
  }
}