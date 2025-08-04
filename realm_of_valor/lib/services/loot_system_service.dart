import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/adventure_map_model.dart';
import '../models/quest_model.dart';

enum LootRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

enum LootType {
  gold,
  experience,
  item,
  weapon,
  armor,
  potion,
  scroll,
  gem,
  artifact,
}

class LootItem {
  final String id;
  final String name;
  final String description;
  final LootType type;
  final LootRarity rarity;
  final int value;
  final String? iconPath;
  final Map<String, dynamic> properties;
  final DateTime spawnTime;
  final DateTime? expirationTime;

  LootItem({
    String? id,
    required this.name,
    required this.description,
    required this.type,
    required this.rarity,
    required this.value,
    this.iconPath,
    Map<String, dynamic>? properties,
    DateTime? spawnTime,
    this.expirationTime,
  })  : id = id ?? _generateId(),
        properties = properties ?? {},
        spawnTime = spawnTime ?? DateTime.now();

  static String _generateId() {
    return 'loot_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  Color get rarityColor {
    switch (rarity) {
      case LootRarity.common:
        return Colors.grey;
      case LootRarity.uncommon:
        return Colors.green;
      case LootRarity.rare:
        return Colors.blue;
      case LootRarity.epic:
        return Colors.purple;
      case LootRarity.legendary:
        return Colors.orange;
    }
  }

  String get rarityName {
    switch (rarity) {
      case LootRarity.common:
        return 'Common';
      case LootRarity.uncommon:
        return 'Uncommon';
      case LootRarity.rare:
        return 'Rare';
      case LootRarity.epic:
        return 'Epic';
      case LootRarity.legendary:
        return 'Legendary';
    }
  }
}

class LootCache {
  final String id;
  final String name;
  final String description;
  final LatLng position;
  final LootRarity rarity;
  final List<LootItem> items;
  final DateTime spawnTime;
  final DateTime? expirationTime;
  final bool isDiscovered;
  final bool isCollected;

  LootCache({
    String? id,
    required this.name,
    required this.description,
    required this.position,
    required this.rarity,
    List<LootItem>? items,
    DateTime? spawnTime,
    this.expirationTime,
    this.isDiscovered = false,
    this.isCollected = false,
  })  : id = id ?? _generateId(),
        items = items ?? [],
        spawnTime = spawnTime ?? DateTime.now();

  static String _generateId() {
    return 'cache_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  Color get rarityColor => _getLootItem().rarityColor;
  String get rarityName => _getLootItem().rarityName;

  LootItem _getLootItem() {
    return items.isNotEmpty ? items.first : LootItem(
      name: 'Unknown Treasure',
      description: 'A mysterious cache of loot',
      type: LootType.item,
      rarity: LootRarity.common,
      value: 0,
    );
  }
}

class LootSystemService extends ChangeNotifier {
  static final LootSystemService _instance = LootSystemService._internal();
  factory LootSystemService() => _instance;
  LootSystemService._internal();

  // Data storage
  List<LootCache> _lootCaches = [];
  List<LootItem> _inventory = [];
  Map<String, int> _inventoryCounts = {};
  
  // Loot templates
  final Map<LootRarity, List<LootItem>> _lootTemplates = {
    LootRarity.common: [
      LootItem(
        name: 'Copper Coin',
        description: 'A simple copper coin',
        type: LootType.gold,
        rarity: LootRarity.common,
        value: 1,
      ),
      LootItem(
        name: 'Minor Health Potion',
        description: 'Restores a small amount of health',
        type: LootType.potion,
        rarity: LootRarity.common,
        value: 10,
      ),
      LootItem(
        name: 'Rusty Dagger',
        description: 'A basic weapon',
        type: LootType.weapon,
        rarity: LootRarity.common,
        value: 5,
      ),
    ],
    LootRarity.uncommon: [
      LootItem(
        name: 'Silver Coin',
        description: 'A valuable silver coin',
        type: LootType.gold,
        rarity: LootRarity.uncommon,
        value: 5,
      ),
      LootItem(
        name: 'Health Potion',
        description: 'Restores health',
        type: LootType.potion,
        rarity: LootRarity.uncommon,
        value: 25,
      ),
      LootItem(
        name: 'Iron Sword',
        description: 'A reliable weapon',
        type: LootType.weapon,
        rarity: LootRarity.uncommon,
        value: 15,
      ),
    ],
    LootRarity.rare: [
      LootItem(
        name: 'Gold Coin',
        description: 'A precious gold coin',
        type: LootType.gold,
        rarity: LootRarity.rare,
        value: 10,
      ),
      LootItem(
        name: 'Greater Health Potion',
        description: 'Restores significant health',
        type: LootType.potion,
        rarity: LootRarity.rare,
        value: 50,
      ),
      LootItem(
        name: 'Steel Sword',
        description: 'A powerful weapon',
        type: LootType.weapon,
        rarity: LootRarity.rare,
        value: 30,
      ),
    ],
    LootRarity.epic: [
      LootItem(
        name: 'Platinum Coin',
        description: 'An extremely valuable coin',
        type: LootType.gold,
        rarity: LootRarity.epic,
        value: 25,
      ),
      LootItem(
        name: 'Elixir of Life',
        description: 'Restores all health',
        type: LootType.potion,
        rarity: LootRarity.epic,
        value: 100,
      ),
      LootItem(
        name: 'Mythril Sword',
        description: 'A legendary weapon',
        type: LootType.weapon,
        rarity: LootRarity.epic,
        value: 75,
      ),
    ],
    LootRarity.legendary: [
      LootItem(
        name: 'Dragon Gold',
        description: 'A coin of immense value',
        type: LootType.gold,
        rarity: LootRarity.legendary,
        value: 100,
      ),
      LootItem(
        name: 'Phoenix Elixir',
        description: 'Brings you back from the dead',
        type: LootType.potion,
        rarity: LootRarity.legendary,
        value: 500,
      ),
      LootItem(
        name: 'Excalibur',
        description: 'The legendary sword',
        type: LootType.weapon,
        rarity: LootRarity.legendary,
        value: 1000,
      ),
    ],
  };

  // Getters
  List<LootCache> get lootCaches => _lootCaches;
  List<LootItem> get inventory => _inventory;
  Map<String, int> get inventoryCounts => _inventoryCounts;

  // Spawn loot caches around user location
  Future<void> spawnLootCaches(UserLocation userLocation, double radius) async {
    final random = Random();
    final numCaches = 3 + random.nextInt(3); // 3-5 caches
    
    for (int i = 0; i < numCaches; i++) {
      // Generate random position within radius
      final angle = random.nextDouble() * 2 * pi;
      final distance = random.nextDouble() * radius * 0.8; // Keep within 80% of radius
      
      final latOffset = distance * cos(angle) / 111000; // Approximate meters to degrees
      final lngOffset = distance * sin(angle) / (111000 * cos(userLocation.latitude * pi / 180));
      
      final position = LatLng(
        userLocation.latitude + latOffset,
        userLocation.longitude + lngOffset,
      );
      
      // Determine rarity based on distance and randomness
      final rarity = _determineRarity(distance, random);
      
      // Generate loot items for this cache
      final items = _generateLootItems(rarity, random);
      
      final cache = LootCache(
        name: _generateCacheName(rarity),
        description: _generateCacheDescription(rarity),
        position: position,
        rarity: rarity,
        items: items,
        expirationTime: DateTime.now().add(Duration(hours: 2 + random.nextInt(4))),
      );
      
      _lootCaches.add(cache);
    }
    
    notifyListeners();
    debugPrint('Spawned ${numCaches} loot caches');
  }

  LootRarity _determineRarity(double distance, Random random) {
    final distanceFactor = distance / 5000; // Normalize distance
    final randomFactor = random.nextDouble();
    final combinedFactor = (distanceFactor + randomFactor) / 2;
    
    if (combinedFactor > 0.9) return LootRarity.legendary;
    if (combinedFactor > 0.7) return LootRarity.epic;
    if (combinedFactor > 0.5) return LootRarity.rare;
    if (combinedFactor > 0.3) return LootRarity.uncommon;
    return LootRarity.common;
  }

  List<LootItem> _generateLootItems(LootRarity rarity, Random random) {
    final items = <LootItem>[];
    final templates = _lootTemplates[rarity] ?? _lootTemplates[LootRarity.common]!;
    
    // Generate 1-3 items per cache
    final numItems = 1 + random.nextInt(3);
    
    for (int i = 0; i < numItems; i++) {
      final template = templates[random.nextInt(templates.length)];
      items.add(template);
    }
    
    return items;
  }

  String _generateCacheName(LootRarity rarity) {
    final names = {
      LootRarity.common: ['Small Chest', 'Wooden Box', 'Simple Cache'],
      LootRarity.uncommon: ['Iron Chest', 'Locked Box', 'Hidden Cache'],
      LootRarity.rare: ['Golden Chest', 'Ancient Cache', 'Mysterious Box'],
      LootRarity.epic: ['Crystal Chest', 'Legendary Cache', 'Sacred Box'],
      LootRarity.legendary: ['Dragon Hoard', 'Divine Cache', 'Mythical Chest'],
    };
    
    final nameList = names[rarity] ?? names[LootRarity.common]!;
    return nameList[Random().nextInt(nameList.length)];
  }

  String _generateCacheDescription(LootRarity rarity) {
    final descriptions = {
      LootRarity.common: 'A simple cache with basic loot',
      LootRarity.uncommon: 'A well-hidden cache with decent rewards',
      LootRarity.rare: 'An ancient cache with valuable treasures',
      LootRarity.epic: 'A legendary cache with powerful artifacts',
      LootRarity.legendary: 'A mythical cache with the rarest treasures',
    };
    
    return descriptions[rarity] ?? descriptions[LootRarity.common]!;
  }

  // Collect loot from a cache
  Future<bool> collectLoot(String cacheId, UserLocation userLocation) async {
    final cacheIndex = _lootCaches.indexWhere((cache) => cache.id == cacheId);
    if (cacheIndex == -1) return false;
    
    final cache = _lootCaches[cacheIndex];
    
    // Check if user is close enough to collect
    final distance = _calculateDistance(
      userLocation.latitude,
      userLocation.longitude,
      cache.position.latitude,
      cache.position.longitude,
    );
    
    if (distance > 50) { // Must be within 50 meters
      debugPrint('Too far to collect loot: ${distance.toStringAsFixed(1)}m');
      return false;
    }
    
    // Add items to inventory
    for (final item in cache.items) {
      _addToInventory(item);
    }
    
    // Mark cache as collected
    _lootCaches[cacheIndex] = LootCache(
      id: cache.id,
      name: cache.name,
      description: cache.description,
      position: cache.position,
      rarity: cache.rarity,
      items: cache.items,
      spawnTime: cache.spawnTime,
      expirationTime: cache.expirationTime,
      isDiscovered: true,
      isCollected: true,
    );
    
    notifyListeners();
    debugPrint('Collected loot from ${cache.name}');
    return true;
  }

  void _addToInventory(LootItem item) {
    _inventory.add(item);
    _inventoryCounts[item.id] = (_inventoryCounts[item.id] ?? 0) + 1;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    
    final double dLat = (lat2 - lat1) * (pi / 180);
    final double dLon = (lon2 - lon1) * (pi / 180);
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  // Get nearby loot caches
  List<LootCache> getNearbyLootCaches(UserLocation userLocation, double radius) {
    return _lootCaches.where((cache) {
      if (cache.isCollected) return false;
      
      final distance = _calculateDistance(
        userLocation.latitude,
        userLocation.longitude,
        cache.position.latitude,
        cache.position.longitude,
      );
      
      return distance <= radius;
    }).toList();
  }

  // Clear expired loot caches
  void clearExpiredCaches() {
    final now = DateTime.now();
    _lootCaches.removeWhere((cache) {
      return cache.expirationTime != null && cache.expirationTime!.isBefore(now);
    });
    notifyListeners();
  }

  // Get inventory statistics
  Map<String, dynamic> getInventoryStats() {
    final stats = <String, dynamic>{
      'totalItems': _inventory.length,
      'uniqueItems': _inventoryCounts.length,
      'totalValue': 0,
      'rarityCounts': <String, int>{},
      'typeCounts': <String, int>{},
    };
    
    for (final item in _inventory) {
      stats['totalValue'] += item.value;
      stats['rarityCounts'][item.rarityName] = (stats['rarityCounts'][item.rarityName] ?? 0) + 1;
      stats['typeCounts'][item.type.name] = (stats['typeCounts'][item.type.name] ?? 0) + 1;
    }
    
    return stats;
  }
} 