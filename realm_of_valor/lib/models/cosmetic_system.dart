import 'package:json_annotation/json_annotation.dart';
import 'package:realm_of_valor/models/card_model.dart';
import 'package:uuid/uuid.dart';
import 'dart:math' as math;

part 'cosmetic_system.g.dart';

enum CosmeticType {
  avatar_skin,      // Character appearance
  avatar_outfit,    // Clothing and armor sets
  avatar_accessory, // Hats, jewelry, etc.
  ui_theme,         // Interface color schemes
  card_back,        // Card backing designs
  border,           // Profile and card borders
  emote,            // Expressions and animations
  title,            // Name titles and badges
  pet,              // Companion creatures
  mount,            // Transportation (for future AR features)
  effect,           // Particle effects and auras
  background,       // Profile backgrounds
}

enum CosmeticRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  mythic,
  exclusive,        // Event/achievement only
  founders,         // Special founder items
}

enum UnlockMethod {
  purchase,         // Buy with gold/premium currency
  achievement,      // Unlock through achievements
  event,            // Limited-time events
  level,            // Character level rewards
  fitness,          // Fitness milestones
  collection,       // Card collection rewards
  guild,            // Guild achievements
  seasonal,         // Seasonal rewards
  premium,          // Premium pass/subscription
  founder,          // Founder exclusive
  charity,          // Charity event rewards
}

@JsonSerializable()
class CosmeticItem {
  final String id;
  final String name;
  final String description;
  final CosmeticType type;
  final CosmeticRarity rarity;
  final UnlockMethod unlockMethod;
  final Map<String, dynamic> unlockRequirements;
  final int goldCost;
  final int premiumCost;
  final bool isAnimated;
  final bool isExclusive;
  final DateTime? availableUntil;
  final String previewUrl;
  final List<String> tags;
  final Map<String, dynamic> properties;
  final Map<String, dynamic> metadata;

  CosmeticItem({
    String? id,
    required this.name,
    required this.description,
    required this.type,
    required this.rarity,
    required this.unlockMethod,
    Map<String, dynamic>? unlockRequirements,
    this.goldCost = 0,
    this.premiumCost = 0,
    this.isAnimated = false,
    this.isExclusive = false,
    this.availableUntil,
    this.previewUrl = '',
    List<String>? tags,
    Map<String, dynamic>? properties,
    Map<String, dynamic>? metadata,
  }) : id = id ?? const Uuid().v4(),
       unlockRequirements = unlockRequirements ?? {},
       tags = tags ?? [],
       properties = properties ?? {},
       metadata = metadata ?? {};

  factory CosmeticItem.fromJson(Map<String, dynamic> json) =>
      _$CosmeticItemFromJson(json);
  Map<String, dynamic> toJson() => _$CosmeticItemToJson(this);

  CosmeticItem copyWith({
    String? id,
    String? name,
    String? description,
    CosmeticType? type,
    CosmeticRarity? rarity,
    UnlockMethod? unlockMethod,
    Map<String, dynamic>? unlockRequirements,
    int? goldCost,
    int? premiumCost,
    bool? isAnimated,
    bool? isExclusive,
    DateTime? availableUntil,
    String? previewUrl,
    List<String>? tags,
    Map<String, dynamic>? properties,
    Map<String, dynamic>? metadata,
  }) {
    return CosmeticItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      unlockMethod: unlockMethod ?? this.unlockMethod,
      unlockRequirements: unlockRequirements ?? this.unlockRequirements,
      goldCost: goldCost ?? this.goldCost,
      premiumCost: premiumCost ?? this.premiumCost,
      isAnimated: isAnimated ?? this.isAnimated,
      isExclusive: isExclusive ?? this.isExclusive,
      availableUntil: availableUntil ?? this.availableUntil,
      previewUrl: previewUrl ?? this.previewUrl,
      tags: tags ?? this.tags,
      properties: properties ?? this.properties,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isAvailable => availableUntil == null || DateTime.now().isBefore(availableUntil!);
  bool get requiresPremium => premiumCost > 0;
}

@JsonSerializable()
class PlayerCosmetics {
  final String playerId;
  final Map<CosmeticType, String> equippedItems; // type -> item_id
  final List<String> ownedItems;
  final Map<String, DateTime> unlockDates;
  final Map<String, dynamic> customizations;

  PlayerCosmetics({
    required this.playerId,
    Map<CosmeticType, String>? equippedItems,
    List<String>? ownedItems,
    Map<String, DateTime>? unlockDates,
    Map<String, dynamic>? customizations,
  }) : equippedItems = equippedItems ?? {},
       ownedItems = ownedItems ?? [],
       unlockDates = unlockDates ?? {},
       customizations = customizations ?? {};

  factory PlayerCosmetics.fromJson(Map<String, dynamic> json) =>
      _$PlayerCosmeticsFromJson(json);
  Map<String, dynamic> toJson() => _$PlayerCosmeticsToJson(this);

  PlayerCosmetics copyWith({
    String? playerId,
    Map<CosmeticType, String>? equippedItems,
    List<String>? ownedItems,
    Map<String, DateTime>? unlockDates,
    Map<String, dynamic>? customizations,
  }) {
    return PlayerCosmetics(
      playerId: playerId ?? this.playerId,
      equippedItems: equippedItems ?? this.equippedItems,
      ownedItems: ownedItems ?? this.ownedItems,
      unlockDates: unlockDates ?? this.unlockDates,
      customizations: customizations ?? this.customizations,
    );
  }

  bool ownsItem(String itemId) => ownedItems.contains(itemId);
  int get totalOwnedItems => ownedItems.length;
}

class CosmeticSystem {
  // Avatar Skins - Character appearance
  static List<CosmeticItem> get avatarSkins => [
    CosmeticItem(
      id: 'default_adventurer',
      name: 'Classic Adventurer',
      description: 'The timeless look of a seasoned adventurer',
      type: CosmeticType.avatar_skin,
      rarity: CosmeticRarity.common,
      unlockMethod: UnlockMethod.level,
      unlockRequirements: {'level': 1},
      tags: ['classic', 'starter'],
    ),
    CosmeticItem(
      id: 'dragon_knight',
      name: 'Dragon Knight',
      description: 'Forged in dragon fire, this legendary appearance commands respect',
      type: CosmeticType.avatar_skin,
      rarity: CosmeticRarity.legendary,
      unlockMethod: UnlockMethod.achievement,
      unlockRequirements: {'dragons_defeated': 100, 'dragon_collection_complete': true},
      isAnimated: true,
      tags: ['dragon', 'legendary', 'animated'],
      properties: {
        'glowing_eyes': true,
        'flame_aura': true,
        'dragon_scale_texture': true,
      },
    ),
    CosmeticItem(
      id: 'fitness_champion',
      name: 'Fitness Champion',
      description: 'The peak of physical perfection, earned through dedication',
      type: CosmeticType.avatar_skin,
      rarity: CosmeticRarity.epic,
      unlockMethod: UnlockMethod.fitness,
      unlockRequirements: {'total_steps': 1000000, 'fitness_achievements': 25},
      tags: ['fitness', 'athletic', 'muscular'],
      properties: {
        'enhanced_physique': true,
        'energy_aura': true,
        'victory_pose': true,
      },
    ),
    CosmeticItem(
      id: 'shadow_assassin',
      name: 'Shadow Assassin',
      description: 'Masters of stealth and precision, emerging from the darkness',
      type: CosmeticType.avatar_skin,
      rarity: CosmeticRarity.epic,
      unlockMethod: UnlockMethod.collection,
      unlockRequirements: {'shadow_cards_collected': 50, 'stealth_victories': 30},
      isAnimated: true,
      tags: ['shadow', 'stealth', 'dark'],
      properties: {
        'shadow_cloak': true,
        'stealth_shimmer': true,
        'darkness_aura': true,
      },
    ),
  ];

  // Avatar Outfits - Clothing and armor
  static List<CosmeticItem> get avatarOutfits => [
    CosmeticItem(
      id: 'royal_regalia',
      name: 'Royal Regalia',
      description: 'Fit for a king or queen of the realm',
      type: CosmeticType.avatar_outfit,
      rarity: CosmeticRarity.legendary,
      unlockMethod: UnlockMethod.achievement,
      goldCost: 10000,
      unlockRequirements: {'guild_rank': 'guildmaster', 'legendary_quests_completed': 10},
      isAnimated: true,
      tags: ['royal', 'prestigious', 'golden'],
      properties: {
        'golden_trim': true,
        'cape_animation': true,
        'crown_effect': true,
      },
    ),
    CosmeticItem(
      id: 'elemental_robes',
      name: 'Elemental Master Robes',
      description: 'Robes that shimmer with elemental power',
      type: CosmeticType.avatar_outfit,
      rarity: CosmeticRarity.epic,
      unlockMethod: UnlockMethod.collection,
      goldCost: 5000,
      unlockRequirements: {'elemental_mastery': true, 'spells_cast': 1000},
      isAnimated: true,
      tags: ['magical', 'elemental', 'flowing'],
      properties: {
        'elemental_swirls': true,
        'color_shifting': true,
        'magical_particles': true,
      },
    ),
    CosmeticItem(
      id: 'winter_formal',
      name: 'Winter Formal Attire',
      description: 'Elegant winter clothing for the holiday season',
      type: CosmeticType.avatar_outfit,
      rarity: CosmeticRarity.rare,
      unlockMethod: UnlockMethod.seasonal,
      goldCost: 2500,
      availableUntil: DateTime(DateTime.now().year, 2, 28),
      tags: ['winter', 'formal', 'seasonal'],
      properties: {
        'snow_effect': true,
        'elegant_style': true,
        'seasonal_exclusive': true,
      },
    ),
  ];

  // Avatar Accessories - Hats, jewelry, etc.
  static List<CosmeticItem> get avatarAccessories => [
    CosmeticItem(
      id: 'crown_of_achievement',
      name: 'Crown of Achievement',
      description: 'A shining crown for those who excel in all endeavors',
      type: CosmeticType.avatar_accessory,
      rarity: CosmeticRarity.mythic,
      unlockMethod: UnlockMethod.achievement,
      unlockRequirements: {'achievements_unlocked': 100, 'level': 75},
      isAnimated: true,
      isExclusive: true,
      tags: ['crown', 'achievement', 'prestigious'],
      properties: {
        'rainbow_glow': true,
        'sparkle_effect': true,
        'achievement_symbols': true,
      },
    ),
    CosmeticItem(
      id: 'fitness_headband',
      name: 'Champion\'s Headband',
      description: 'Worn by fitness champions to show their dedication',
      type: CosmeticType.avatar_accessory,
      rarity: CosmeticRarity.uncommon,
      unlockMethod: UnlockMethod.fitness,
      goldCost: 500,
      unlockRequirements: {'fitness_streak': 30},
      tags: ['fitness', 'sporty', 'motivational'],
    ),
    CosmeticItem(
      id: 'dragon_horn_helmet',
      name: 'Dragon Horn Helmet',
      description: 'A fearsome helmet crafted from real dragon horns',
      type: CosmeticType.avatar_accessory,
      rarity: CosmeticRarity.legendary,
      unlockMethod: UnlockMethod.event,
      unlockRequirements: {'dragon_awakening_event': true},
      isExclusive: true,
      availableUntil: DateTime.now().add(Duration(days: 7)),
      tags: ['dragon', 'helmet', 'fearsome'],
      properties: {
        'dragon_growl_sound': true,
        'intimidation_aura': true,
        'fire_breath_emote': true,
      },
    ),
  ];

  // UI Themes - Interface customization
  static List<CosmeticItem> get uiThemes => [
    CosmeticItem(
      id: 'dark_mode_elegant',
      name: 'Elegant Dark Mode',
      description: 'A sophisticated dark theme with golden accents',
      type: CosmeticType.ui_theme,
      rarity: CosmeticRarity.rare,
      unlockMethod: UnlockMethod.purchase,
      goldCost: 1500,
      tags: ['dark', 'elegant', 'sophisticated'],
      properties: {
        'color_scheme': {'primary': '#1a1a1a', 'accent': '#ffd700', 'text': '#ffffff'},
        'gradient_backgrounds': true,
        'smooth_animations': true,
      },
    ),
    CosmeticItem(
      id: 'nature_theme',
      name: 'Natural Harmony',
      description: 'A theme inspired by the beauty of nature',
      type: CosmeticType.ui_theme,
      rarity: CosmeticRarity.uncommon,
      unlockMethod: UnlockMethod.collection,
      goldCost: 1000,
      unlockRequirements: {'nature_cards_collected': 25},
      tags: ['nature', 'green', 'peaceful'],
      properties: {
        'color_scheme': {'primary': '#2d5016', 'accent': '#90ee90', 'text': '#f0f8ff'},
        'leaf_animations': true,
        'nature_sounds': true,
      },
    ),
    CosmeticItem(
      id: 'dragon_fire_theme',
      name: 'Dragon Fire',
      description: 'A fiery theme that burns with dragon power',
      type: CosmeticType.ui_theme,
      rarity: CosmeticRarity.legendary,
      unlockMethod: UnlockMethod.achievement,
      unlockRequirements: {'dragon_emperor_title': true},
      isAnimated: true,
      isExclusive: true,
      tags: ['dragon', 'fire', 'animated'],
      properties: {
        'color_scheme': {'primary': '#8b0000', 'accent': '#ff4500', 'text': '#ffd700'},
        'flame_particles': true,
        'dragon_roar_sounds': true,
        'animated_backgrounds': true,
      },
    ),
  ];

  // Card Backs - Card backing designs
  static List<CosmeticItem> get cardBacks => [
    CosmeticItem(
      id: 'classic_valor',
      name: 'Classic Valor',
      description: 'The original card back design',
      type: CosmeticType.card_back,
      rarity: CosmeticRarity.common,
      unlockMethod: UnlockMethod.level,
      unlockRequirements: {'level': 1},
      tags: ['classic', 'default'],
    ),
    CosmeticItem(
      id: 'celestial_stars',
      name: 'Celestial Stars',
      description: 'Cards that shimmer with starlight',
      type: CosmeticType.card_back,
      rarity: CosmeticRarity.epic,
      unlockMethod: UnlockMethod.achievement,
      goldCost: 3000,
      unlockRequirements: {'nighttime_activities': 50, 'constellation_complete': true},
      isAnimated: true,
      tags: ['celestial', 'stars', 'shimmering'],
      properties: {
        'twinkling_stars': true,
        'constellation_patterns': true,
        'night_sky_gradient': true,
      },
    ),
    CosmeticItem(
      id: 'founders_edition',
      name: 'Founder\'s Edition',
      description: 'Exclusive card back for founding members',
      type: CosmeticType.card_back,
      rarity: CosmeticRarity.founders,
      unlockMethod: UnlockMethod.founder,
      isExclusive: true,
      tags: ['founder', 'exclusive', 'prestigious'],
      properties: {
        'founder_crest': true,
        'premium_material': true,
        'exclusive_animation': true,
      },
    ),
  ];

  // Borders - Profile and card borders
  static List<CosmeticItem> get borders => [
    CosmeticItem(
      id: 'fitness_achievement_border',
      name: 'Fitness Achievement Border',
      description: 'A border that shows your fitness dedication',
      type: CosmeticType.border,
      rarity: CosmeticRarity.rare,
      unlockMethod: UnlockMethod.fitness,
      unlockRequirements: {'fitness_level': 50, 'calories_burned': 50000},
      tags: ['fitness', 'achievement', 'motivational'],
      properties: {
        'fitness_icons': true,
        'progress_indicators': true,
        'motivational_colors': true,
      },
    ),
    CosmeticItem(
      id: 'legendary_collector_border',
      name: 'Legendary Collector Border',
      description: 'For master collectors who have obtained legendary status',
      type: CosmeticType.border,
      rarity: CosmeticRarity.legendary,
      unlockMethod: UnlockMethod.collection,
      unlockRequirements: {'legendary_cards_collected': 25, 'collection_completion': 90},
      isAnimated: true,
      tags: ['legendary', 'collector', 'prestigious'],
      properties: {
        'golden_trim': true,
        'gem_accents': true,
        'collection_showcase': true,
      },
    ),
  ];

  // Emotes - Expressions and animations
  static List<CosmeticItem> get emotes => [
    CosmeticItem(
      id: 'victory_dance',
      name: 'Victory Dance',
      description: 'Celebrate your wins with style!',
      type: CosmeticType.emote,
      rarity: CosmeticRarity.uncommon,
      unlockMethod: UnlockMethod.achievement,
      goldCost: 750,
      unlockRequirements: {'battles_won': 50},
      isAnimated: true,
      tags: ['victory', 'celebration', 'fun'],
    ),
    CosmeticItem(
      id: 'dragon_roar',
      name: 'Dragon Roar',
      description: 'Channel your inner dragon with this fierce emote',
      type: CosmeticType.emote,
      rarity: CosmeticRarity.epic,
      unlockMethod: UnlockMethod.event,
      unlockRequirements: {'dragon_awakening_participation': true},
      isAnimated: true,
      tags: ['dragon', 'fierce', 'intimidating'],
      properties: {
        'sound_effect': 'dragon_roar.mp3',
        'screen_shake': true,
        'fire_particles': true,
      },
    ),
    CosmeticItem(
      id: 'fitness_flex',
      name: 'Fitness Flex',
      description: 'Show off your gains with this motivational emote',
      type: CosmeticType.emote,
      rarity: CosmeticRarity.rare,
      unlockMethod: UnlockMethod.fitness,
      goldCost: 1200,
      unlockRequirements: {'strength_milestones': 10},
      isAnimated: true,
      tags: ['fitness', 'strength', 'motivational'],
    ),
  ];

  // Titles - Name titles and badges
  static List<CosmeticItem> get titles => [
    CosmeticItem(
      id: 'dragon_emperor',
      name: 'Dragon Emperor',
      description: 'Supreme ruler of all dragonkind',
      type: CosmeticType.title,
      rarity: CosmeticRarity.mythic,
      unlockMethod: UnlockMethod.achievement,
      unlockRequirements: {'legendary_dragon_crown': true, 'dragons_defeated': 500},
      isExclusive: true,
      tags: ['dragon', 'emperor', 'supreme'],
    ),
    CosmeticItem(
      id: 'fitness_legend',
      name: 'Fitness Legend',
      description: 'A living inspiration to fitness enthusiasts everywhere',
      type: CosmeticType.title,
      rarity: CosmeticRarity.legendary,
      unlockMethod: UnlockMethod.fitness,
      unlockRequirements: {'fitness_mastery_skill': true, 'marathons_completed': 5},
      tags: ['fitness', 'legend', 'inspirational'],
    ),
    CosmeticItem(
      id: 'grand_collector',
      name: 'Grand Collector',
      description: 'Master of the art of collection',
      type: CosmeticType.title,
      rarity: CosmeticRarity.epic,
      unlockMethod: UnlockMethod.collection,
      unlockRequirements: {'sets_completed': 10, 'rare_cards_collected': 100},
      tags: ['collector', 'master', 'dedicated'],
    ),
    CosmeticItem(
      id: 'charity_champion',
      name: 'Charity Champion',
      description: 'Hero who makes a real-world difference',
      type: CosmeticType.title,
      rarity: CosmeticRarity.exclusive,
      unlockMethod: UnlockMethod.charity,
      unlockRequirements: {'charity_events_participated': 5, 'charity_impact': 1000},
      isExclusive: true,
      tags: ['charity', 'hero', 'real-world-impact'],
    ),
  ];

  // Pets - Companion creatures
  static List<CosmeticItem> get pets => [
    CosmeticItem(
      id: 'baby_dragon',
      name: 'Baby Dragon',
      description: 'A cute baby dragon that follows you on adventures',
      type: CosmeticType.pet,
      rarity: CosmeticRarity.legendary,
      unlockMethod: UnlockMethod.event,
      unlockRequirements: {'dragon_awakening_completion': true},
      isAnimated: true,
      isExclusive: true,
      tags: ['dragon', 'baby', 'adorable'],
      properties: {
        'flight_animation': true,
        'breathing_fire': true,
        'playful_behavior': true,
        'size': 'small',
      },
    ),
    CosmeticItem(
      id: 'fitness_buddy',
      name: 'Fitness Buddy',
      description: 'An energetic companion that motivates your workouts',
      type: CosmeticType.pet,
      rarity: CosmeticRarity.epic,
      unlockMethod: UnlockMethod.fitness,
      goldCost: 4000,
      unlockRequirements: {'fitness_level': 25, 'workout_streak': 21},
      isAnimated: true,
      tags: ['fitness', 'motivational', 'energetic'],
      properties: {
        'exercise_animations': true,
        'motivational_quotes': true,
        'workout_tracking': true,
      },
    ),
    CosmeticItem(
      id: 'shadow_cat',
      name: 'Shadow Cat',
      description: 'A mysterious feline that phases in and out of shadows',
      type: CosmeticType.pet,
      rarity: CosmeticRarity.rare,
      unlockMethod: UnlockMethod.collection,
      goldCost: 2500,
      unlockRequirements: {'shadow_cards_collected': 30},
      isAnimated: true,
      tags: ['shadow', 'cat', 'mysterious'],
      properties: {
        'phase_ability': true,
        'shadow_trail': true,
        'stealth_mode': true,
      },
    ),
  ];

  // Effects - Particle effects and auras
  static List<CosmeticItem> get effects => [
    CosmeticItem(
      id: 'champion_aura',
      name: 'Champion\'s Aura',
      description: 'A golden aura that shows your champion status',
      type: CosmeticType.effect,
      rarity: CosmeticRarity.legendary,
      unlockMethod: UnlockMethod.achievement,
      unlockRequirements: {'champion_title': true, 'tournament_wins': 10},
      isAnimated: true,
      tags: ['champion', 'golden', 'prestigious'],
      properties: {
        'golden_particles': true,
        'aura_intensity': 'high',
        'victory_enhancement': true,
      },
    ),
    CosmeticItem(
      id: 'elemental_swirl',
      name: 'Elemental Swirl',
      description: 'Swirling elemental energies surround your character',
      type: CosmeticType.effect,
      rarity: CosmeticRarity.epic,
      unlockMethod: UnlockMethod.collection,
      goldCost: 3500,
      unlockRequirements: {'elemental_mastery': true},
      isAnimated: true,
      tags: ['elemental', 'swirling', 'magical'],
      properties: {
        'multi_element_colors': true,
        'swirl_animation': true,
        'elemental_sounds': true,
      },
    ),
  ];

  // Seasonal Collections
  static List<CosmeticItem> get seasonalCosmetics => [
    // Halloween Collection
    CosmeticItem(
      id: 'halloween_witch_hat',
      name: 'Witch\'s Pointed Hat',
      description: 'A classic witch hat perfect for Halloween adventures',
      type: CosmeticType.avatar_accessory,
      rarity: CosmeticRarity.rare,
      unlockMethod: UnlockMethod.seasonal,
      goldCost: 1500,
      availableUntil: DateTime(DateTime.now().year, 11, 1),
      tags: ['halloween', 'witch', 'seasonal'],
    ),
    CosmeticItem(
      id: 'spooky_ghost_pet',
      name: 'Friendly Ghost',
      description: 'A cute ghost companion for the spooky season',
      type: CosmeticType.pet,
      rarity: CosmeticRarity.epic,
      unlockMethod: UnlockMethod.event,
      unlockRequirements: {'halloween_event_participation': true},
      isAnimated: true,
      availableUntil: DateTime(DateTime.now().year, 11, 1),
      tags: ['halloween', 'ghost', 'spooky'],
    ),
    
    // Winter Holiday Collection
    CosmeticItem(
      id: 'santa_hat',
      name: 'Festive Santa Hat',
      description: 'Spread holiday cheer with this jolly hat',
      type: CosmeticType.avatar_accessory,
      rarity: CosmeticRarity.uncommon,
      unlockMethod: UnlockMethod.seasonal,
      goldCost: 800,
      availableUntil: DateTime(DateTime.now().year + 1, 1, 15),
      tags: ['winter', 'christmas', 'festive'],
    ),
    CosmeticItem(
      id: 'winter_wonderland_theme',
      name: 'Winter Wonderland',
      description: 'A magical winter theme with snow effects',
      type: CosmeticType.ui_theme,
      rarity: CosmeticRarity.rare,
      unlockMethod: UnlockMethod.seasonal,
      goldCost: 2000,
      isAnimated: true,
      availableUntil: DateTime(DateTime.now().year + 1, 2, 28),
      tags: ['winter', 'snow', 'magical'],
      properties: {
        'snow_particles': true,
        'ice_crystal_effects': true,
        'winter_color_palette': true,
      },
    ),
  ];

  // Get all cosmetic items
  static List<CosmeticItem> get allCosmetics {
    final allItems = <CosmeticItem>[];
    allItems.addAll(avatarSkins);
    allItems.addAll(avatarOutfits);
    allItems.addAll(avatarAccessories);
    allItems.addAll(uiThemes);
    allItems.addAll(cardBacks);
    allItems.addAll(borders);
    allItems.addAll(emotes);
    allItems.addAll(titles);
    allItems.addAll(pets);
    allItems.addAll(effects);
    allItems.addAll(seasonalCosmetics);
    return allItems;
  }

  // Get cosmetics by type
  static List<CosmeticItem> getCosmeticsByType(CosmeticType type) {
    return allCosmetics.where((item) => item.type == type).toList();
  }

  // Get cosmetics by rarity
  static List<CosmeticItem> getCosmeticsByRarity(CosmeticRarity rarity) {
    return allCosmetics.where((item) => item.rarity == rarity).toList();
  }

  // Get available cosmetics (not expired)
  static List<CosmeticItem> getAvailableCosmetics() {
    return allCosmetics.where((item) => item.isAvailable).toList();
  }

  // Get unlockable cosmetics for player
  static List<CosmeticItem> getUnlockableCosmetics(Map<String, dynamic> playerStats) {
    return allCosmetics.where((item) => canUnlockCosmetic(item, playerStats)).toList();
  }

  // Check if player can unlock a cosmetic
  static bool canUnlockCosmetic(CosmeticItem item, Map<String, dynamic> playerStats) {
    if (!item.isAvailable) return false;
    
    // Check unlock requirements
    for (final entry in item.unlockRequirements.entries) {
      final requirement = entry.key;
      final value = entry.value;
      
      switch (requirement) {
        case 'level':
          if ((playerStats['level'] ?? 0) < value) return false;
          break;
        case 'dragons_defeated':
          if ((playerStats['dragons_defeated'] ?? 0) < value) return false;
          break;
        case 'total_steps':
          if ((playerStats['total_steps'] ?? 0) < value) return false;
          break;
        case 'fitness_level':
          if ((playerStats['fitness_level'] ?? 0) < value) return false;
          break;
        case 'achievements_unlocked':
          if ((playerStats['achievements_unlocked'] ?? 0) < value) return false;
          break;
        case 'guild_rank':
          if (playerStats['guild_rank'] != value) return false;
          break;
        default:
          // Check if player has the specific achievement/requirement
          if (!(playerStats[requirement] ?? false)) return false;
      }
    }
    
    return true;
  }

  // Calculate cosmetic prices based on rarity
  static Map<String, int> getCosmeticPricing(CosmeticRarity rarity) {
    switch (rarity) {
      case CosmeticRarity.common:
        return {'gold': 100, 'premium': 0};
      case CosmeticRarity.uncommon:
        return {'gold': 500, 'premium': 5};
      case CosmeticRarity.rare:
        return {'gold': 1500, 'premium': 15};
      case CosmeticRarity.epic:
        return {'gold': 4000, 'premium': 40};
      case CosmeticRarity.legendary:
        return {'gold': 10000, 'premium': 100};
      case CosmeticRarity.mythic:
        return {'gold': 25000, 'premium': 250};
      case CosmeticRarity.exclusive:
        return {'gold': 0, 'premium': 0}; // Achievement only
      case CosmeticRarity.founders:
        return {'gold': 0, 'premium': 0}; // Founder exclusive
      default:
        return {'gold': 100, 'premium': 0};
    }
  }

  // Generate daily cosmetic store rotation
  static List<CosmeticItem> generateDailyStore() {
    final random = math.Random();
    final storeItems = <CosmeticItem>[];
    
    // Always include some common/uncommon items
    final commonItems = getCosmeticsByRarity(CosmeticRarity.common);
    final uncommonItems = getCosmeticsByRarity(CosmeticRarity.uncommon);
    
    if (commonItems.isNotEmpty) {
      storeItems.add(commonItems[random.nextInt(commonItems.length)]);
    }
    if (uncommonItems.isNotEmpty) {
      storeItems.add(uncommonItems[random.nextInt(uncommonItems.length)]);
    }
    
    // Random chance for higher rarity items
    if (random.nextDouble() < 0.6) { // 60% chance for rare
      final rareItems = getCosmeticsByRarity(CosmeticRarity.rare);
      if (rareItems.isNotEmpty) {
        storeItems.add(rareItems[random.nextInt(rareItems.length)]);
      }
    }
    
    if (random.nextDouble() < 0.3) { // 30% chance for epic
      final epicItems = getCosmeticsByRarity(CosmeticRarity.epic);
      if (epicItems.isNotEmpty) {
        storeItems.add(epicItems[random.nextInt(epicItems.length)]);
      }
    }
    
    if (random.nextDouble() < 0.1) { // 10% chance for legendary
      final legendaryItems = getCosmeticsByRarity(CosmeticRarity.legendary);
      if (legendaryItems.isNotEmpty) {
        storeItems.add(legendaryItems[random.nextInt(legendaryItems.length)]);
      }
    }
    
    // Add seasonal items if available
    final availableSeasonalItems = seasonalCosmetics.where((item) => item.isAvailable).toList();
    if (availableSeasonalItems.isNotEmpty) {
      storeItems.add(availableSeasonalItems[random.nextInt(availableSeasonalItems.length)]);
    }
    
    return storeItems;
  }

  // Create cosmetic bundles
  static Map<String, dynamic> createCosmeticBundle(String bundleName, List<CosmeticItem> items, double discountPercent) {
    final totalGoldCost = items.fold(0, (sum, item) => sum + item.goldCost);
    final totalPremiumCost = items.fold(0, (sum, item) => sum + item.premiumCost);
    
    final bundleGoldCost = (totalGoldCost * (1 - discountPercent / 100)).round();
    final bundlePremiumCost = (totalPremiumCost * (1 - discountPercent / 100)).round();
    
    return {
      'name': bundleName,
      'items': items,
      'original_gold_cost': totalGoldCost,
      'original_premium_cost': totalPremiumCost,
      'bundle_gold_cost': bundleGoldCost,
      'bundle_premium_cost': bundlePremiumCost,
      'discount_percent': discountPercent,
      'savings_gold': totalGoldCost - bundleGoldCost,
      'savings_premium': totalPremiumCost - bundlePremiumCost,
    };
  }

  // Popular cosmetic bundles
  static List<Map<String, dynamic>> get popularBundles => [
    createCosmeticBundle(
      'Dragon Master Bundle',
      [
        avatarSkins.firstWhere((item) => item.id == 'dragon_knight'),
        avatarAccessories.firstWhere((item) => item.id == 'dragon_horn_helmet'),
        pets.firstWhere((item) => item.id == 'baby_dragon'),
        uiThemes.firstWhere((item) => item.id == 'dragon_fire_theme'),
      ],
      25.0, // 25% discount
    ),
    createCosmeticBundle(
      'Fitness Champion Bundle',
      [
        avatarSkins.firstWhere((item) => item.id == 'fitness_champion'),
        avatarAccessories.firstWhere((item) => item.id == 'fitness_headband'),
        pets.firstWhere((item) => item.id == 'fitness_buddy'),
        emotes.firstWhere((item) => item.id == 'fitness_flex'),
      ],
      20.0, // 20% discount
    ),
    createCosmeticBundle(
      'Royal Collection',
      [
        avatarOutfits.firstWhere((item) => item.id == 'royal_regalia'),
        avatarAccessories.firstWhere((item) => item.id == 'crown_of_achievement'),
        borders.firstWhere((item) => item.id == 'legendary_collector_border'),
        effects.firstWhere((item) => item.id == 'champion_aura'),
      ],
      30.0, // 30% discount
    ),
  ];

  // Get cosmetic recommendations for player
  static List<CosmeticItem> getRecommendationsForPlayer(Map<String, dynamic> playerStats, PlayerCosmetics playerCosmetics) {
    final recommendations = <CosmeticItem>[];
    
    // Recommend based on playstyle and achievements
    final level = playerStats['level'] ?? 0;
    final fitnessLevel = playerStats['fitness_level'] ?? 0;
    final dragonsDefeated = playerStats['dragons_defeated'] ?? 0;
    
    // Fitness-focused recommendations
    if (fitnessLevel > 20) {
      recommendations.addAll(
        allCosmetics.where((item) => 
          item.tags.contains('fitness') && 
          !playerCosmetics.ownsItem(item.id) &&
          canUnlockCosmetic(item, playerStats)
        ).take(3)
      );
    }
    
    // Dragon-themed recommendations
    if (dragonsDefeated > 10) {
      recommendations.addAll(
        allCosmetics.where((item) => 
          item.tags.contains('dragon') && 
          !playerCosmetics.ownsItem(item.id) &&
          canUnlockCosmetic(item, playerStats)
        ).take(2)
      );
    }
    
    // Level-based recommendations
    if (level > 25) {
      recommendations.addAll(
        allCosmetics.where((item) => 
          item.rarity == CosmeticRarity.epic && 
          !playerCosmetics.ownsItem(item.id) &&
          canUnlockCosmetic(item, playerStats)
        ).take(2)
      );
    }
    
    return recommendations.take(10).toList();
  }

  // Calculate cosmetic collection stats
  static Map<String, dynamic> calculateCollectionStats(PlayerCosmetics playerCosmetics) {
    final totalCosmetics = allCosmetics.length;
    final ownedCosmetics = playerCosmetics.totalOwnedItems;
    final completionPercentage = (ownedCosmetics / totalCosmetics * 100).round();
    
    final cosmeticsByType = <CosmeticType, int>{};
    final cosmeticsByRarity = <CosmeticRarity, int>{};
    
    for (final itemId in playerCosmetics.ownedItems) {
      final item = allCosmetics.firstWhere((cosmetic) => cosmetic.id == itemId, orElse: () => allCosmetics.first);
      cosmeticsByType[item.type] = (cosmeticsByType[item.type] ?? 0) + 1;
      cosmeticsByRarity[item.rarity] = (cosmeticsByRarity[item.rarity] ?? 0) + 1;
    }
    
    return {
      'total_cosmetics': totalCosmetics,
      'owned_cosmetics': ownedCosmetics,
      'completion_percentage': completionPercentage,
      'cosmetics_by_type': cosmeticsByType,
      'cosmetics_by_rarity': cosmeticsByRarity,
      'rarest_owned': _getRarestOwnedCosmetic(playerCosmetics),
      'collection_value': _calculateCollectionValue(playerCosmetics),
    };
  }

  static CosmeticRarity? _getRarestOwnedCosmetic(PlayerCosmetics playerCosmetics) {
    CosmeticRarity? rarest;
    
    for (final itemId in playerCosmetics.ownedItems) {
      final item = allCosmetics.firstWhere((cosmetic) => cosmetic.id == itemId, orElse: () => allCosmetics.first);
      if (rarest == null || item.rarity.index > rarest.index) {
        rarest = item.rarity;
      }
    }
    
    return rarest;
  }

  static int _calculateCollectionValue(PlayerCosmetics playerCosmetics) {
    int totalValue = 0;
    
    for (final itemId in playerCosmetics.ownedItems) {
      final item = allCosmetics.firstWhere((cosmetic) => cosmetic.id == itemId, orElse: () => allCosmetics.first);
      totalValue += item.goldCost;
    }
    
    return totalValue;
  }
}