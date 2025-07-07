import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/adventure_system.dart';
import '../models/character_model.dart';
import 'adventure_progression_service.dart';

enum CustomizationCategory {
  outfit,
  accessories,
  pets,
  backgrounds,
  emotes,
  titles,
  effects,
}

enum UnlockCondition {
  adventure_xp,
  quests_completed,
  distance_traveled,
  achievements_earned,
  seasonal_event,
  social_activity,
  purchase,
  default_unlocked,
}

class CustomizationItem {
  final String id;
  final String name;
  final String description;
  final CustomizationCategory category;
  final String iconPath;
  final String? assetPath;
  final UnlockCondition unlockCondition;
  final Map<String, dynamic> unlockRequirements;
  final bool isUnlocked;
  final bool isEquipped;
  final DateTime? unlockedAt;
  final String rarity;
  final Map<String, dynamic> metadata;
  final bool isAnimated;
  final bool isLimited;

  CustomizationItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.iconPath,
    this.assetPath,
    required this.unlockCondition,
    required this.unlockRequirements,
    this.isUnlocked = false,
    this.isEquipped = false,
    this.unlockedAt,
    this.rarity = 'common',
    Map<String, dynamic>? metadata,
    this.isAnimated = false,
    this.isLimited = false,
  }) : metadata = metadata ?? {};

  factory CustomizationItem.fromJson(Map<String, dynamic> json) {
    return CustomizationItem(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: CustomizationCategory.values[json['category'] ?? 0],
      iconPath: json['iconPath'],
      assetPath: json['assetPath'],
      unlockCondition: UnlockCondition.values[json['unlockCondition'] ?? 0],
      unlockRequirements: Map<String, dynamic>.from(json['unlockRequirements'] ?? {}),
      isUnlocked: json['isUnlocked'] ?? false,
      isEquipped: json['isEquipped'] ?? false,
      unlockedAt: json['unlockedAt'] != null 
          ? DateTime.parse(json['unlockedAt'])
          : null,
      rarity: json['rarity'] ?? 'common',
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      isAnimated: json['isAnimated'] ?? false,
      isLimited: json['isLimited'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.index,
      'iconPath': iconPath,
      'assetPath': assetPath,
      'unlockCondition': unlockCondition.index,
      'unlockRequirements': unlockRequirements,
      'isUnlocked': isUnlocked,
      'isEquipped': isEquipped,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'rarity': rarity,
      'metadata': metadata,
      'isAnimated': isAnimated,
      'isLimited': isLimited,
    };
  }

  CustomizationItem copyWith({
    bool? isUnlocked,
    bool? isEquipped,
    DateTime? unlockedAt,
  }) {
    return CustomizationItem(
      id: id,
      name: name,
      description: description,
      category: category,
      iconPath: iconPath,
      assetPath: assetPath,
      unlockCondition: unlockCondition,
      unlockRequirements: unlockRequirements,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isEquipped: isEquipped ?? this.isEquipped,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      rarity: rarity,
      metadata: metadata,
      isAnimated: isAnimated,
      isLimited: isLimited,
    );
  }
}

class CharacterAppearance {
  final String characterId;
  final Map<CustomizationCategory, String?> equippedItems;
  final String? activeTitle;
  final String? activePet;
  final String? activeBackground;
  final List<String> favoriteEmotes;
  final Map<String, dynamic> characterStats;

  CharacterAppearance({
    required this.characterId,
    Map<CustomizationCategory, String?>? equippedItems,
    this.activeTitle,
    this.activePet,
    this.activeBackground,
    List<String>? favoriteEmotes,
    Map<String, dynamic>? characterStats,
  }) : equippedItems = equippedItems ?? {},
       favoriteEmotes = favoriteEmotes ?? [],
       characterStats = characterStats ?? {};

  factory CharacterAppearance.fromJson(Map<String, dynamic> json) {
    final equippedItemsMap = <CustomizationCategory, String?>{};
    final equippedJson = json['equippedItems'] as Map<String, dynamic>? ?? {};
    
    for (final entry in equippedJson.entries) {
      final categoryIndex = int.tryParse(entry.key);
      if (categoryIndex != null && categoryIndex < CustomizationCategory.values.length) {
        equippedItemsMap[CustomizationCategory.values[categoryIndex]] = entry.value;
      }
    }

    return CharacterAppearance(
      characterId: json['characterId'],
      equippedItems: equippedItemsMap,
      activeTitle: json['activeTitle'],
      activePet: json['activePet'],
      activeBackground: json['activeBackground'],
      favoriteEmotes: List<String>.from(json['favoriteEmotes'] ?? []),
      characterStats: Map<String, dynamic>.from(json['characterStats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    final equippedItemsJson = <String, String?>{};
    for (final entry in equippedItems.entries) {
      equippedItemsJson[entry.key.index.toString()] = entry.value;
    }

    return {
      'characterId': characterId,
      'equippedItems': equippedItemsJson,
      'activeTitle': activeTitle,
      'activePet': activePet,
      'activeBackground': activeBackground,
      'favoriteEmotes': favoriteEmotes,
      'characterStats': characterStats,
    };
  }
}

class CharacterCustomizationService {
  static final CharacterCustomizationService _instance = CharacterCustomizationService._internal();
  factory CharacterCustomizationService() => _instance;
  CharacterCustomizationService._internal();

  final StreamController<List<CustomizationItem>> _itemsController = StreamController.broadcast();
  final StreamController<CustomizationItem> _itemUnlockedController = StreamController.broadcast();
  final StreamController<CharacterAppearance> _appearanceController = StreamController.broadcast();

  Stream<List<CustomizationItem>> get itemsStream => _itemsController.stream;
  Stream<CustomizationItem> get itemUnlockedStream => _itemUnlockedController.stream;
  Stream<CharacterAppearance> get appearanceStream => _appearanceController.stream;

  List<CustomizationItem> _customizationItems = [];
  CharacterAppearance? _currentAppearance;
  String? _characterId;

  // Initialize customization system
  Future<void> initialize(String characterId) async {
    _characterId = characterId;
    await _loadPlayerCustomizations();
    _initializeCustomizationItems();
    _itemsController.add(_customizationItems);
    
    if (_currentAppearance != null) {
      _appearanceController.add(_currentAppearance!);
    }
  }

  // Initialize all customization items
  void _initializeCustomizationItems() {
    _customizationItems = [
      // Outfit Items
      ..._createOutfitItems(),
      // Accessories
      ..._createAccessoryItems(),
      // Pets
      ..._createPetItems(),
      // Backgrounds
      ..._createBackgroundItems(),
      // Emotes
      ..._createEmoteItems(),
      // Titles
      ..._createTitleItems(),
      // Effects
      ..._createEffectItems(),
    ];
  }

  // Create outfit customization items
  List<CustomizationItem> _createOutfitItems() {
    return [
      CustomizationItem(
        id: 'default_outfit',
        name: 'Basic Adventurer',
        description: 'Your starting adventure outfit',
        category: CustomizationCategory.outfit,
        iconPath: 'customization/outfits/default.png',
        assetPath: 'customization/outfits/default_full.png',
        unlockCondition: UnlockCondition.default_unlocked,
        unlockRequirements: {},
        isUnlocked: true,
        rarity: 'common',
      ),
      CustomizationItem(
        id: 'explorer_outfit',
        name: 'Seasoned Explorer',
        description: 'Gear for the experienced adventurer',
        category: CustomizationCategory.outfit,
        iconPath: 'customization/outfits/explorer.png',
        assetPath: 'customization/outfits/explorer_full.png',
        unlockCondition: UnlockCondition.adventure_xp,
        unlockRequirements: {'adventure_xp': 1000},
        rarity: 'uncommon',
      ),
      CustomizationItem(
        id: 'knight_armor',
        name: 'Knight\'s Armor',
        description: 'Protective armor for brave warriors',
        category: CustomizationCategory.outfit,
        iconPath: 'customization/outfits/knight.png',
        assetPath: 'customization/outfits/knight_full.png',
        unlockCondition: UnlockCondition.quests_completed,
        unlockRequirements: {'battle_quests': 25},
        rarity: 'rare',
      ),
      CustomizationItem(
        id: 'mystic_robes',
        name: 'Mystic Robes',
        description: 'Enchanted robes that shimmer with magic',
        category: CustomizationCategory.outfit,
        iconPath: 'customization/outfits/mystic.png',
        assetPath: 'customization/outfits/mystic_full.png',
        unlockCondition: UnlockCondition.achievements_earned,
        unlockRequirements: {'rare_achievements': 5},
        rarity: 'epic',
        isAnimated: true,
      ),
      CustomizationItem(
        id: 'legendary_regalia',
        name: 'Legendary Regalia',
        description: 'The ultimate adventurer\'s attire',
        category: CustomizationCategory.outfit,
        iconPath: 'customization/outfits/legendary.png',
        assetPath: 'customization/outfits/legendary_full.png',
        unlockCondition: UnlockCondition.adventure_xp,
        unlockRequirements: {'adventure_xp': 50000},
        rarity: 'legendary',
        isAnimated: true,
      ),
    ];
  }

  // Create accessory items
  List<CustomizationItem> _createAccessoryItems() {
    return [
      CustomizationItem(
        id: 'explorer_hat',
        name: 'Explorer\'s Hat',
        description: 'A trusty hat for all adventures',
        category: CustomizationCategory.accessories,
        iconPath: 'customization/accessories/explorer_hat.png',
        unlockCondition: UnlockCondition.distance_traveled,
        unlockRequirements: {'distance': 10000},
        rarity: 'common',
      ),
      CustomizationItem(
        id: 'fitness_band',
        name: 'Fitness Tracker',
        description: 'Shows your dedication to fitness',
        category: CustomizationCategory.accessories,
        iconPath: 'customization/accessories/fitness_band.png',
        unlockCondition: UnlockCondition.quests_completed,
        unlockRequirements: {'fitness_quests': 10},
        rarity: 'uncommon',
      ),
      CustomizationItem(
        id: 'wings_of_wind',
        name: 'Wings of Wind',
        description: 'Magical wings that flutter in the breeze',
        category: CustomizationCategory.accessories,
        iconPath: 'customization/accessories/wings.png',
        unlockCondition: UnlockCondition.distance_traveled,
        unlockRequirements: {'distance': 100000},
        rarity: 'epic',
        isAnimated: true,
      ),
      CustomizationItem(
        id: 'crown_of_seasons',
        name: 'Crown of Seasons',
        description: 'A crown that changes with the seasons',
        category: CustomizationCategory.accessories,
        iconPath: 'customization/accessories/crown.png',
        unlockCondition: UnlockCondition.seasonal_event,
        unlockRequirements: {'seasonal_events_completed': 4},
        rarity: 'legendary',
        isAnimated: true,
        isLimited: true,
      ),
    ];
  }

  // Create pet items
  List<CustomizationItem> _createPetItems() {
    return [
      CustomizationItem(
        id: 'adventure_cat',
        name: 'Adventure Cat',
        description: 'A curious cat that loves to explore',
        category: CustomizationCategory.pets,
        iconPath: 'customization/pets/cat.png',
        unlockCondition: UnlockCondition.quests_completed,
        unlockRequirements: {'exploration_quests': 5},
        rarity: 'common',
      ),
      CustomizationItem(
        id: 'fitness_dog',
        name: 'Fitness Buddy',
        description: 'An energetic dog that motivates you to exercise',
        category: CustomizationCategory.pets,
        iconPath: 'customization/pets/dog.png',
        unlockCondition: UnlockCondition.distance_traveled,
        unlockRequirements: {'distance': 50000},
        rarity: 'uncommon',
        isAnimated: true,
      ),
      CustomizationItem(
        id: 'wise_owl',
        name: 'Wise Owl',
        description: 'An owl that guides you on night adventures',
        category: CustomizationCategory.pets,
        iconPath: 'customization/pets/owl.png',
        unlockCondition: UnlockCondition.quests_completed,
        unlockRequirements: {'night_quests': 20},
        rarity: 'rare',
      ),
      CustomizationItem(
        id: 'phoenix_companion',
        name: 'Phoenix Companion',
        description: 'A legendary phoenix that grants courage',
        category: CustomizationCategory.pets,
        iconPath: 'customization/pets/phoenix.png',
        unlockCondition: UnlockCondition.achievements_earned,
        unlockRequirements: {'legendary_achievements': 1},
        rarity: 'legendary',
        isAnimated: true,
      ),
    ];
  }

  // Create background items
  List<CustomizationItem> _createBackgroundItems() {
    return [
      CustomizationItem(
        id: 'forest_glade',
        name: 'Forest Glade',
        description: 'A peaceful forest clearing',
        category: CustomizationCategory.backgrounds,
        iconPath: 'customization/backgrounds/forest.png',
        unlockCondition: UnlockCondition.quests_completed,
        unlockRequirements: {'exploration_quests': 10},
        rarity: 'common',
      ),
      CustomizationItem(
        id: 'mountain_peak',
        name: 'Mountain Peak',
        description: 'View from the highest summit',
        category: CustomizationCategory.backgrounds,
        iconPath: 'customization/backgrounds/mountain.png',
        unlockCondition: UnlockCondition.distance_traveled,
        unlockRequirements: {'distance': 25000},
        rarity: 'uncommon',
      ),
      CustomizationItem(
        id: 'aurora_sky',
        name: 'Aurora Sky',
        description: 'Dancing lights in the night sky',
        category: CustomizationCategory.backgrounds,
        iconPath: 'customization/backgrounds/aurora.png',
        unlockCondition: UnlockCondition.seasonal_event,
        unlockRequirements: {'winter_events': 1},
        rarity: 'epic',
        isAnimated: true,
      ),
      CustomizationItem(
        id: 'realm_nexus',
        name: 'Realm Nexus',
        description: 'The mystical center of all realms',
        category: CustomizationCategory.backgrounds,
        iconPath: 'customization/backgrounds/nexus.png',
        unlockCondition: UnlockCondition.adventure_xp,
        unlockRequirements: {'adventure_xp': 25000},
        rarity: 'legendary',
        isAnimated: true,
      ),
    ];
  }

  // Create emote items
  List<CustomizationItem> _createEmoteItems() {
    return [
      CustomizationItem(
        id: 'wave_emote',
        name: 'Friendly Wave',
        description: 'A cheerful greeting',
        category: CustomizationCategory.emotes,
        iconPath: 'customization/emotes/wave.png',
        unlockCondition: UnlockCondition.default_unlocked,
        unlockRequirements: {},
        isUnlocked: true,
        rarity: 'common',
      ),
      CustomizationItem(
        id: 'victory_pose',
        name: 'Victory Pose',
        description: 'Celebrate your achievements',
        category: CustomizationCategory.emotes,
        iconPath: 'customization/emotes/victory.png',
        unlockCondition: UnlockCondition.quests_completed,
        unlockRequirements: {'quests': 25},
        rarity: 'uncommon',
      ),
      CustomizationItem(
        id: 'dance_emote',
        name: 'Adventure Dance',
        description: 'Show off your moves',
        category: CustomizationCategory.emotes,
        iconPath: 'customization/emotes/dance.png',
        unlockCondition: UnlockCondition.social_activity,
        unlockRequirements: {'friends': 10},
        rarity: 'rare',
        isAnimated: true,
      ),
      CustomizationItem(
        id: 'legendary_salute',
        name: 'Legendary Salute',
        description: 'A salute worthy of legends',
        category: CustomizationCategory.emotes,
        iconPath: 'customization/emotes/salute.png',
        unlockCondition: UnlockCondition.achievements_earned,
        unlockRequirements: {'legendary_achievements': 3},
        rarity: 'legendary',
        isAnimated: true,
      ),
    ];
  }

  // Create title items
  List<CustomizationItem> _createTitleItems() {
    return [
      CustomizationItem(
        id: 'novice_adventurer',
        name: 'Novice Adventurer',
        description: 'Just starting your journey',
        category: CustomizationCategory.titles,
        iconPath: 'customization/titles/novice.png',
        unlockCondition: UnlockCondition.default_unlocked,
        unlockRequirements: {},
        isUnlocked: true,
        rarity: 'common',
      ),
      CustomizationItem(
        id: 'step_counter',
        name: 'Step Counter',
        description: 'Master of movement',
        category: CustomizationCategory.titles,
        iconPath: 'customization/titles/step_counter.png',
        unlockCondition: UnlockCondition.distance_traveled,
        unlockRequirements: {'steps': 100000},
        rarity: 'uncommon',
      ),
      CustomizationItem(
        id: 'quest_master',
        name: 'Quest Master',
        description: 'Completed countless adventures',
        category: CustomizationCategory.titles,
        iconPath: 'customization/titles/quest_master.png',
        unlockCondition: UnlockCondition.quests_completed,
        unlockRequirements: {'quests': 100},
        rarity: 'rare',
      ),
      CustomizationItem(
        id: 'realm_guardian',
        name: 'Realm Guardian',
        description: 'Protector of all realms',
        category: CustomizationCategory.titles,
        iconPath: 'customization/titles/guardian.png',
        unlockCondition: UnlockCondition.adventure_xp,
        unlockRequirements: {'adventure_xp': 20000},
        rarity: 'epic',
      ),
      CustomizationItem(
        id: 'eternal_legend',
        name: 'Eternal Legend',
        description: 'A name that will be remembered forever',
        category: CustomizationCategory.titles,
        iconPath: 'customization/titles/legend.png',
        unlockCondition: UnlockCondition.achievements_earned,
        unlockRequirements: {'mythic_achievements': 1},
        rarity: 'mythic',
      ),
    ];
  }

  // Create effect items
  List<CustomizationItem> _createEffectItems() {
    return [
      CustomizationItem(
        id: 'sparkle_trail',
        name: 'Sparkle Trail',
        description: 'Leave a trail of sparkles behind you',
        category: CustomizationCategory.effects,
        iconPath: 'customization/effects/sparkles.png',
        unlockCondition: UnlockCondition.achievements_earned,
        unlockRequirements: {'achievements': 10},
        rarity: 'uncommon',
        isAnimated: true,
      ),
      CustomizationItem(
        id: 'flame_aura',
        name: 'Flame Aura',
        description: 'Surrounded by mystical flames',
        category: CustomizationCategory.effects,
        iconPath: 'customization/effects/flames.png',
        unlockCondition: UnlockCondition.seasonal_event,
        unlockRequirements: {'summer_events': 1},
        rarity: 'rare',
        isAnimated: true,
      ),
      CustomizationItem(
        id: 'cosmic_glow',
        name: 'Cosmic Glow',
        description: 'Radiate with the power of stars',
        category: CustomizationCategory.effects,
        iconPath: 'customization/effects/cosmic.png',
        unlockCondition: UnlockCondition.adventure_xp,
        unlockRequirements: {'adventure_xp': 30000},
        rarity: 'epic',
        isAnimated: true,
      ),
      CustomizationItem(
        id: 'divine_radiance',
        name: 'Divine Radiance',
        description: 'Blessed with divine light',
        category: CustomizationCategory.effects,
        iconPath: 'customization/effects/divine.png',
        unlockCondition: UnlockCondition.achievements_earned,
        unlockRequirements: {'mythic_achievements': 1},
        rarity: 'mythic',
        isAnimated: true,
      ),
    ];
  }

  // Check and unlock new items based on player progress
  Future<void> checkForNewUnlocks(AdventureProfile profile) async {
    for (int i = 0; i < _customizationItems.length; i++) {
      final item = _customizationItems[i];
      if (item.isUnlocked) continue;

      if (_checkUnlockRequirements(item, profile)) {
        final unlockedItem = item.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
        
        _customizationItems[i] = unlockedItem;
        _itemUnlockedController.add(unlockedItem);
      }
    }

    await _savePlayerCustomizations();
    _itemsController.add(_customizationItems);
  }

  // Check if unlock requirements are met
  bool _checkUnlockRequirements(CustomizationItem item, AdventureProfile profile) {
    switch (item.unlockCondition) {
      case UnlockCondition.adventure_xp:
        final requiredXP = item.unlockRequirements['adventure_xp'] ?? 0;
        return profile.adventureXP >= requiredXP;
        
      case UnlockCondition.quests_completed:
        final requirements = item.unlockRequirements;
        for (final entry in requirements.entries) {
          final questType = entry.key;
          final required = entry.value;
          final completed = profile.questCompletions[questType] ?? 0;
          if (completed < required) return false;
        }
        return true;
        
      case UnlockCondition.distance_traveled:
        final requiredDistance = item.unlockRequirements['distance'] ?? 0;
        final requiredSteps = item.unlockRequirements['steps'] ?? 0;
        return profile.totalDistanceTraveled >= requiredDistance ||
               (requiredSteps > 0 && profile.totalDistanceTraveled * 1.3 >= requiredSteps);
        
      case UnlockCondition.achievements_earned:
        // This would check against achievement service
        return false; // Placeholder
        
      case UnlockCondition.seasonal_event:
        // This would check against seasonal event completion
        return false; // Placeholder
        
      case UnlockCondition.social_activity:
        // This would check social features
        return false; // Placeholder
        
      case UnlockCondition.purchase:
        return false; // Would be unlocked through purchase
        
      case UnlockCondition.default_unlocked:
        return true;
    }
  }

  // Equip customization item
  Future<void> equipItem(String itemId) async {
    final item = _customizationItems.firstWhere((item) => item.id == itemId);
    if (!item.isUnlocked) return;

    if (_currentAppearance == null) {
      _currentAppearance = CharacterAppearance(characterId: _characterId!);
    }

    // Unequip other items in the same category
    for (int i = 0; i < _customizationItems.length; i++) {
      final currentItem = _customizationItems[i];
      if (currentItem.category == item.category && currentItem.isEquipped) {
        _customizationItems[i] = currentItem.copyWith(isEquipped: false);
      }
    }

    // Equip the new item
    final itemIndex = _customizationItems.indexWhere((item) => item.id == itemId);
    _customizationItems[itemIndex] = item.copyWith(isEquipped: true);

    // Update appearance
    final updatedEquipped = Map<CustomizationCategory, String?>.from(_currentAppearance!.equippedItems);
    updatedEquipped[item.category] = itemId;

    _currentAppearance = CharacterAppearance(
      characterId: _currentAppearance!.characterId,
      equippedItems: updatedEquipped,
      activeTitle: item.category == CustomizationCategory.titles ? item.name : _currentAppearance!.activeTitle,
      activePet: item.category == CustomizationCategory.pets ? itemId : _currentAppearance!.activePet,
      activeBackground: item.category == CustomizationCategory.backgrounds ? itemId : _currentAppearance!.activeBackground,
      favoriteEmotes: _currentAppearance!.favoriteEmotes,
      characterStats: _currentAppearance!.characterStats,
    );

    await _savePlayerCustomizations();
    _itemsController.add(_customizationItems);
    _appearanceController.add(_currentAppearance!);
  }

  // Unequip customization item
  Future<void> unequipItem(String itemId) async {
    final itemIndex = _customizationItems.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) return;

    final item = _customizationItems[itemIndex];
    _customizationItems[itemIndex] = item.copyWith(isEquipped: false);

    if (_currentAppearance != null) {
      final updatedEquipped = Map<CustomizationCategory, String?>.from(_currentAppearance!.equippedItems);
      updatedEquipped[item.category] = null;

      _currentAppearance = CharacterAppearance(
        characterId: _currentAppearance!.characterId,
        equippedItems: updatedEquipped,
        activeTitle: item.category == CustomizationCategory.titles ? null : _currentAppearance!.activeTitle,
        activePet: item.category == CustomizationCategory.pets ? null : _currentAppearance!.activePet,
        activeBackground: item.category == CustomizationCategory.backgrounds ? null : _currentAppearance!.activeBackground,
        favoriteEmotes: _currentAppearance!.favoriteEmotes,
        characterStats: _currentAppearance!.characterStats,
      );

      await _savePlayerCustomizations();
      _itemsController.add(_customizationItems);
      _appearanceController.add(_currentAppearance!);
    }
  }

  // Get items by category
  List<CustomizationItem> getItemsByCategory(CustomizationCategory category) {
    return _customizationItems.where((item) => item.category == category).toList();
  }

  // Get unlocked items
  List<CustomizationItem> getUnlockedItems() {
    return _customizationItems.where((item) => item.isUnlocked).toList();
  }

  // Get equipped items
  List<CustomizationItem> getEquippedItems() {
    return _customizationItems.where((item) => item.isEquipped).toList();
  }

  // Get current appearance
  CharacterAppearance? getCurrentAppearance() {
    return _currentAppearance;
  }

  // Get customization stats
  Map<String, dynamic> getCustomizationStats() {
    final totalItems = _customizationItems.length;
    final unlockedItems = _customizationItems.where((item) => item.isUnlocked).length;
    final equippedItems = _customizationItems.where((item) => item.isEquipped).length;

    final categoryStats = <String, Map<String, int>>{};
    for (final category in CustomizationCategory.values) {
      final categoryItems = _customizationItems.where((item) => item.category == category).toList();
      final categoryUnlocked = categoryItems.where((item) => item.isUnlocked).length;
      
      categoryStats[category.toString()] = {
        'total': categoryItems.length,
        'unlocked': categoryUnlocked,
      };
    }

    return {
      'total_items': totalItems,
      'unlocked_items': unlockedItems,
      'equipped_items': equippedItems,
      'unlock_percentage': totalItems > 0 ? (unlockedItems / totalItems * 100).round() : 0,
      'categories': categoryStats,
    };
  }

  // Add to favorite emotes
  Future<void> addFavoriteEmote(String emoteId) async {
    if (_currentAppearance == null) return;

    final updatedFavorites = List<String>.from(_currentAppearance!.favoriteEmotes);
    if (!updatedFavorites.contains(emoteId) && updatedFavorites.length < 6) {
      updatedFavorites.add(emoteId);

      _currentAppearance = CharacterAppearance(
        characterId: _currentAppearance!.characterId,
        equippedItems: _currentAppearance!.equippedItems,
        activeTitle: _currentAppearance!.activeTitle,
        activePet: _currentAppearance!.activePet,
        activeBackground: _currentAppearance!.activeBackground,
        favoriteEmotes: updatedFavorites,
        characterStats: _currentAppearance!.characterStats,
      );

      await _savePlayerCustomizations();
      _appearanceController.add(_currentAppearance!);
    }
  }

  // Data persistence
  Future<void> _savePlayerCustomizations() async {
    if (_characterId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final itemsJson = jsonEncode(_customizationItems.map((item) => item.toJson()).toList());
      final appearanceJson = _currentAppearance != null 
          ? jsonEncode(_currentAppearance!.toJson())
          : null;

      await prefs.setString('customization_items_$_characterId', itemsJson);
      if (appearanceJson != null) {
        await prefs.setString('character_appearance_$_characterId', appearanceJson);
      }
    } catch (e) {
      print('Error saving customizations: $e');
    }
  }

  Future<void> _loadPlayerCustomizations() async {
    if (_characterId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final itemsJson = prefs.getString('customization_items_$_characterId');
      final appearanceJson = prefs.getString('character_appearance_$_characterId');

      if (itemsJson != null) {
        final itemsList = jsonDecode(itemsJson) as List;
        final savedItems = itemsList.map((json) => CustomizationItem.fromJson(json)).toList();
        
        // Merge with current items (in case new ones were added)
        for (final saved in savedItems) {
          final index = _customizationItems.indexWhere((item) => item.id == saved.id);
          if (index != -1) {
            _customizationItems[index] = saved;
          }
        }
      }

      if (appearanceJson != null) {
        final appearanceData = jsonDecode(appearanceJson);
        _currentAppearance = CharacterAppearance.fromJson(appearanceData);
      }
    } catch (e) {
      print('Error loading customizations: $e');
    }
  }

  // Cleanup
  void dispose() {
    _itemsController.close();
    _itemUnlockedController.close();
    _appearanceController.close();
  }
}