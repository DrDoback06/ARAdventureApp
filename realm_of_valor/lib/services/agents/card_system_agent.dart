import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/event_bus.dart';
import '../../models/card_model.dart';
import '../../models/card_database.dart';
import '../../services/qr_scanner_service.dart';
import 'integration_orchestrator_agent.dart';

/// Card ownership tracking
class OwnedCard {
  final String ownerId;
  final String cardId;
  final int quantity;
  final DateTime acquiredAt;
  final String source; // 'scanned', 'reward', 'shop', 'trade', etc.
  final Map<String, dynamic> metadata;

  OwnedCard({
    required this.ownerId,
    required this.cardId,
    this.quantity = 1,
    DateTime? acquiredAt,
    this.source = 'unknown',
    this.metadata = const {},
  }) : acquiredAt = acquiredAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'ownerId': ownerId,
      'cardId': cardId,
      'quantity': quantity,
      'acquiredAt': acquiredAt.toIso8601String(),
      'source': source,
      'metadata': metadata,
    };
  }

  factory OwnedCard.fromJson(Map<String, dynamic> json) {
    return OwnedCard(
      ownerId: json['ownerId'],
      cardId: json['cardId'],
      quantity: json['quantity'] ?? 1,
      acquiredAt: DateTime.parse(json['acquiredAt']),
      source: json['source'] ?? 'unknown',
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  OwnedCard copyWith({
    String? ownerId,
    String? cardId,
    int? quantity,
    DateTime? acquiredAt,
    String? source,
    Map<String, dynamic>? metadata,
  }) {
    return OwnedCard(
      ownerId: ownerId ?? this.ownerId,
      cardId: cardId ?? this.cardId,
      quantity: quantity ?? this.quantity,
      acquiredAt: acquiredAt ?? this.acquiredAt,
      source: source ?? this.source,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Equipment loadout
class EquipmentLoadout {
  final String ownerId;
  final Map<EquipmentSlot, String> equippedCards; // slot -> cardId
  final DateTime lastModified;

  EquipmentLoadout({
    required this.ownerId,
    Map<EquipmentSlot, String>? equippedCards,
    DateTime? lastModified,
  }) : equippedCards = equippedCards ?? {},
       lastModified = lastModified ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'ownerId': ownerId,
      'equippedCards': equippedCards.map((slot, cardId) => MapEntry(slot.toString(), cardId)),
      'lastModified': lastModified.toIso8601String(),
    };
  }

  factory EquipmentLoadout.fromJson(Map<String, dynamic> json) {
    final equippedMap = <EquipmentSlot, String>{};
    final equipped = json['equippedCards'] as Map<String, dynamic>? ?? {};
    
    for (final entry in equipped.entries) {
      final slot = EquipmentSlot.values.firstWhere(
        (s) => s.toString() == entry.key,
        orElse: () => EquipmentSlot.none,
      );
      if (slot != EquipmentSlot.none) {
        equippedMap[slot] = entry.value;
      }
    }

    return EquipmentLoadout(
      ownerId: json['ownerId'],
      equippedCards: equippedMap,
      lastModified: DateTime.parse(json['lastModified']),
    );
  }

  EquipmentLoadout copyWith({
    String? ownerId,
    Map<EquipmentSlot, String>? equippedCards,
    DateTime? lastModified,
  }) {
    return EquipmentLoadout(
      ownerId: ownerId ?? this.ownerId,
      equippedCards: equippedCards ?? Map.from(this.equippedCards),
      lastModified: lastModified ?? DateTime.now(),
    );
  }
}

/// Card pack configuration
class CardPack {
  final String id;
  final String name;
  final String description;
  final int cardCount;
  final Map<CardRarity, double> rarityWeights;
  final int cost;
  final CardSet? restrictedSet;

  CardPack({
    required this.id,
    required this.name,
    required this.description,
    this.cardCount = 5,
    Map<CardRarity, double>? rarityWeights,
    this.cost = 100,
    this.restrictedSet,
  }) : rarityWeights = rarityWeights ?? CardDatabase.rarityWeights;
}

/// Card System Agent - Complete card management with QR integration
class CardSystemAgent extends BaseAgent {
  static const String agentId = 'card_system';

  final SharedPreferences _prefs;
  final QRScannerService _qrScanner;

  // Current user context
  String? _currentUserId;

  // Card databases
  final Map<String, GameCard> _allCards = {};
  final Map<String, List<OwnedCard>> _userInventories = {}; // userId -> cards
  final Map<String, EquipmentLoadout> _userEquipment = {}; // userId -> loadout
  
  // Card packs and shop
  final Map<String, CardPack> _cardPacks = {};
  final Map<String, int> _userCurrency = {}; // userId -> gold

  // Recent activity tracking
  final List<Map<String, dynamic>> _recentActivity = [];

  CardSystemAgent({
    required SharedPreferences prefs,
    QRScannerService? qrScanner,
  }) : _prefs = prefs,
       _qrScanner = qrScanner ?? QRScannerService._internal(),
       super(agentId: agentId);

  @override
  Future<void> onInitialize() async {
    developer.log('Initializing Card System Agent', name: agentId);

    // Load card databases
    await _loadCardDatabase();
    
    // Initialize card packs
    _initializeCardPacks();
    
    // Load user data
    await _loadUserData();

    developer.log('Card System Agent initialized with ${_allCards.length} cards', name: agentId);
  }

  @override
  void subscribeToEvents() {
    // QR scanning events
    subscribe('scan_qr_card', _handleQRCardScan);
    subscribe('process_qr_result', _handleQRResult);

    // Inventory management
    subscribe('get_inventory', _handleGetInventory);
    subscribe('add_card_to_inventory', _handleAddCardToInventory);
    subscribe('remove_card_from_inventory', _handleRemoveCardFromInventory);
    subscribe('transfer_card', _handleTransferCard);

    // Equipment management
    subscribe('equip_card', _handleEquipCard);
    subscribe('unequip_card', _handleUnequipCard);
    subscribe('get_equipment', _handleGetEquipment);
    subscribe('get_equipment_stats', _handleGetEquipmentStats);

    // Card collection
    subscribe('get_card_collection', _handleGetCardCollection);
    subscribe('search_cards', _handleSearchCards);
    subscribe('get_card_details', _handleGetCardDetails);

    // Shop and packs
    subscribe('get_card_packs', _handleGetCardPacks);
    subscribe('open_card_pack', _handleOpenCardPack);
    subscribe('buy_card_pack', _handleBuyCardPack);
    subscribe('get_shop_inventory', _handleGetShopInventory);

    // Rewards and achievements
    subscribe('inventory_reward', _handleInventoryReward);
    subscribe('character_reward', _handleCharacterReward);

    // User management
    subscribe('user_login', _handleUserLogin);
    subscribe('user_logout', _handleUserLogout);

    // Data persistence
    subscribe('save_card_data', _handleSaveCardData);
    subscribe('load_card_data', _handleLoadCardData);
  }

  /// Scan and process QR card
  Future<QRScanResult?> scanQRCard(String qrData) async {
    try {
      final result = await _qrScanner.scanAndParseQR(qrData);
      
      if (result != null) {
        // Publish QR scan event
        await publishEvent(createEvent(
          eventType: EventTypes.cardScanned,
          data: {
            'qrData': qrData,
            'cardType': result.type.toString(),
            'scannedBy': _currentUserId,
            'timestamp': DateTime.now().toIso8601String(),
          },
        ));

        _logActivity('qr_scan', {
          'cardType': result.type.toString(),
          'userId': _currentUserId,
        });
      }

      return result;
    } catch (e) {
      developer.log('Error scanning QR card: $e', name: agentId);
      return null;
    }
  }

  /// Add card to user inventory
  Future<bool> addCardToInventory(String userId, String cardId, {
    int quantity = 1,
    String source = 'unknown',
    Map<String, dynamic> metadata = const {},
  }) async {
    if (!_allCards.containsKey(cardId)) {
      developer.log('Card not found: $cardId', name: agentId);
      return false;
    }

    final ownedCard = OwnedCard(
      ownerId: userId,
      cardId: cardId,
      quantity: quantity,
      source: source,
      metadata: metadata,
    );

    _userInventories.putIfAbsent(userId, () => []).add(ownedCard);

    // Publish inventory change event
    await publishEvent(createEvent(
      eventType: EventTypes.inventoryChanged,
      data: {
        'userId': userId,
        'itemsGained': [cardId],
        'quantities': [quantity],
        'source': source,
      },
    ));

    _logActivity('card_acquired', {
      'userId': userId,
      'cardId': cardId,
      'quantity': quantity,
      'source': source,
    });

    await _saveUserInventory(userId);
    return true;
  }

  /// Equip card to slot
  Future<bool> equipCard(String userId, String cardId, EquipmentSlot slot) async {
    final card = _allCards[cardId];
    if (card == null) return false;

    // Check if user owns the card
    final userInventory = _userInventories[userId] ?? [];
    final ownedCard = userInventory.firstWhere(
      (owned) => owned.cardId == cardId,
      orElse: () => OwnedCard(ownerId: '', cardId: ''),
    );

    if (ownedCard.cardId.isEmpty) {
      developer.log('User $userId does not own card $cardId', name: agentId);
      return false;
    }

    // Check if card can be equipped to this slot
    if (card.equipmentSlot != slot && card.equipmentSlot != EquipmentSlot.none) {
      developer.log('Card $cardId cannot be equipped to slot $slot', name: agentId);
      return false;
    }

    // Get or create equipment loadout
    var loadout = _userEquipment[userId] ?? EquipmentLoadout(ownerId: userId);

    // Unequip any existing card in this slot
    if (loadout.equippedCards.containsKey(slot)) {
      await unequipCard(userId, slot);
      loadout = _userEquipment[userId] ?? EquipmentLoadout(ownerId: userId);
    }

    // Equip the new card
    loadout = loadout.copyWith(
      equippedCards: {
        ...loadout.equippedCards,
        slot: cardId,
      },
    );

    _userEquipment[userId] = loadout;

    // Publish equipment change event
    await publishEvent(createEvent(
      eventType: EventTypes.cardEquipped,
      data: {
        'userId': userId,
        'cardId': cardId,
        'slotType': slot.toString(),
        'cardStats': _calculateCardStats(card),
      },
    ));

    _logActivity('card_equipped', {
      'userId': userId,
      'cardId': cardId,
      'slot': slot.toString(),
    });

    await _saveUserEquipment(userId);
    return true;
  }

  /// Unequip card from slot
  Future<bool> unequipCard(String userId, EquipmentSlot slot) async {
    final loadout = _userEquipment[userId];
    if (loadout == null || !loadout.equippedCards.containsKey(slot)) {
      return false;
    }

    final cardId = loadout.equippedCards[slot]!;
    final newEquipped = Map<EquipmentSlot, String>.from(loadout.equippedCards);
    newEquipped.remove(slot);

    _userEquipment[userId] = loadout.copyWith(equippedCards: newEquipped);

    // Publish equipment change event
    await publishEvent(createEvent(
      eventType: EventTypes.cardUnequipped,
      data: {
        'userId': userId,
        'cardId': cardId,
        'slotType': slot.toString(),
      },
    ));

    _logActivity('card_unequipped', {
      'userId': userId,
      'cardId': cardId,
      'slot': slot.toString(),
    });

    await _saveUserEquipment(userId);
    return true;
  }

  /// Get user's equipment stats
  Map<String, int> getEquipmentStats(String userId) {
    final loadout = _userEquipment[userId];
    if (loadout == null) return {};

    final totalStats = <String, int>{};

    for (final cardId in loadout.equippedCards.values) {
      final card = _allCards[cardId];
      if (card != null) {
        final cardStats = _calculateCardStats(card);
        for (final entry in cardStats.entries) {
          totalStats[entry.key] = (totalStats[entry.key] ?? 0) + entry.value;
        }
      }
    }

    return totalStats;
  }

  /// Open card pack
  Future<List<GameCard>> openCardPack(String userId, String packId) async {
    final pack = _cardPacks[packId];
    if (pack == null) return [];

    // Check if user has enough currency
    final userGold = _userCurrency[userId] ?? 0;
    if (userGold < pack.cost) {
      developer.log('User $userId does not have enough gold for pack $packId', name: agentId);
      return [];
    }

    // Deduct cost
    _userCurrency[userId] = userGold - pack.cost;

    // Generate cards
    final cards = _generatePackCards(pack);

    // Add cards to inventory
    for (final card in cards) {
      await addCardToInventory(
        userId, 
        card.id, 
        source: 'card_pack_$packId',
        metadata: {'packId': packId},
      );
    }

    _logActivity('pack_opened', {
      'userId': userId,
      'packId': packId,
      'cardCount': cards.length,
      'cardIds': cards.map((c) => c.id).toList(),
    });

    await _saveUserCurrency(userId);
    return cards;
  }

  /// Generate cards for a pack
  List<GameCard> _generatePackCards(CardPack pack) {
    final random = math.Random();
    final cards = <GameCard>[];

    for (int i = 0; i < pack.cardCount; i++) {
      // Select rarity based on weights
      CardRarity selectedRarity = CardRarity.common;
      double randomValue = random.nextDouble();
      double cumulative = 0.0;

      for (final entry in pack.rarityWeights.entries) {
        cumulative += entry.value;
        if (randomValue <= cumulative) {
          selectedRarity = entry.key;
          break;
        }
      }

      // Get cards of selected rarity
      List<GameCard> availableCards;
      if (pack.restrictedSet != null) {
        availableCards = _allCards.values
            .where((card) => card.rarity == selectedRarity && card.set == pack.restrictedSet)
            .toList();
      } else {
        availableCards = _allCards.values
            .where((card) => card.rarity == selectedRarity)
            .toList();
      }

      if (availableCards.isNotEmpty) {
        cards.add(availableCards[random.nextInt(availableCards.length)]);
      }
    }

    return cards;
  }

  /// Calculate card stats for equipment bonuses
  Map<String, int> _calculateCardStats(GameCard card) {
    final stats = <String, int>{};

    // Add base stats
    if (card.attack > 0) stats['attack'] = card.attack;
    if (card.defense > 0) stats['defense'] = card.defense;
    if (card.health > 0) stats['health'] = card.health;
    if (card.mana > 0) stats['mana'] = card.mana;
    if (card.strength > 0) stats['strength'] = card.strength;
    if (card.agility > 0) stats['agility'] = card.agility;
    if (card.intelligence > 0) stats['intelligence'] = card.intelligence;

    // Add stat modifiers
    for (final modifier in card.statModifiers) {
      if (modifier.isPercentage) {
        // Handle percentage modifiers differently if needed
        stats['${modifier.statName}_percent'] = modifier.value;
      } else {
        stats[modifier.statName] = (stats[modifier.statName] ?? 0) + modifier.value;
      }
    }

    return stats;
  }

  /// Load card database
  Future<void> _loadCardDatabase() async {
    // Load from CardDatabase
    final allCards = <GameCard>[];
    allCards.addAll(CardDatabase.weapons);
    allCards.addAll(CardDatabase.armor);
    // Add more collections from CardDatabase as needed

    for (final card in allCards) {
      _allCards[card.id] = card;
    }

    developer.log('Loaded ${_allCards.length} cards from database', name: agentId);
  }

  /// Initialize card packs
  void _initializeCardPacks() {
    _cardPacks.addAll({
      'starter_pack': CardPack(
        id: 'starter_pack',
        name: 'Starter Pack',
        description: 'Perfect for new adventurers',
        cardCount: 5,
        cost: 100,
        rarityWeights: {
          CardRarity.common: 0.7,
          CardRarity.uncommon: 0.25,
          CardRarity.rare: 0.05,
          CardRarity.epic: 0.0,
          CardRarity.legendary: 0.0,
          CardRarity.mythic: 0.0,
        },
      ),
      'premium_pack': CardPack(
        id: 'premium_pack',
        name: 'Premium Pack',
        description: 'Higher chance of rare cards',
        cardCount: 5,
        cost: 250,
        rarityWeights: {
          CardRarity.common: 0.4,
          CardRarity.uncommon: 0.3,
          CardRarity.rare: 0.2,
          CardRarity.epic: 0.08,
          CardRarity.legendary: 0.02,
          CardRarity.mythic: 0.0,
        },
      ),
      'legendary_pack': CardPack(
        id: 'legendary_pack',
        name: 'Legendary Pack',
        description: 'Guaranteed rare or better cards',
        cardCount: 3,
        cost: 500,
        rarityWeights: {
          CardRarity.common: 0.0,
          CardRarity.uncommon: 0.0,
          CardRarity.rare: 0.7,
          CardRarity.epic: 0.2,
          CardRarity.legendary: 0.09,
          CardRarity.mythic: 0.01,
        },
      ),
    });
  }

  /// Load user data
  Future<void> _loadUserData() async {
    // This would typically load from Data Persistence Agent
    // For now, load from SharedPreferences
    await _loadUserInventories();
    await _loadUserEquipment();
    await _loadUserCurrency();
  }

  /// Load user inventories
  Future<void> _loadUserInventories() async {
    final inventoriesJson = _prefs.getString('user_inventories');
    if (inventoriesJson != null) {
      try {
        final data = jsonDecode(inventoriesJson) as Map<String, dynamic>;
        for (final entry in data.entries) {
          final userId = entry.key;
          final inventoryData = entry.value as List;
          _userInventories[userId] = inventoryData
              .map((json) => OwnedCard.fromJson(json))
              .toList();
        }
      } catch (e) {
        developer.log('Error loading user inventories: $e', name: agentId);
      }
    }
  }

  /// Load user equipment
  Future<void> _loadUserEquipment() async {
    final equipmentJson = _prefs.getString('user_equipment');
    if (equipmentJson != null) {
      try {
        final data = jsonDecode(equipmentJson) as Map<String, dynamic>;
        for (final entry in data.entries) {
          final userId = entry.key;
          _userEquipment[userId] = EquipmentLoadout.fromJson(entry.value);
        }
      } catch (e) {
        developer.log('Error loading user equipment: $e', name: agentId);
      }
    }
  }

  /// Load user currency
  Future<void> _loadUserCurrency() async {
    final currencyJson = _prefs.getString('user_currency');
    if (currencyJson != null) {
      try {
        final data = jsonDecode(currencyJson) as Map<String, dynamic>;
        for (final entry in data.entries) {
          _userCurrency[entry.key] = entry.value as int;
        }
      } catch (e) {
        developer.log('Error loading user currency: $e', name: agentId);
      }
    }
  }

  /// Save user inventory
  Future<void> _saveUserInventory(String userId) async {
    final inventory = _userInventories[userId] ?? [];
    await publishEvent(createEvent(
      eventType: 'save_data',
      targetAgent: 'data_persistence',
      data: {
        'collection': 'user_inventories',
        'id': userId,
        'data': {'inventory': inventory.map((card) => card.toJson()).toList()},
      },
    ));

    // Also save to SharedPreferences as backup
    await _saveAllUserInventories();
  }

  /// Save user equipment
  Future<void> _saveUserEquipment(String userId) async {
    final equipment = _userEquipment[userId];
    if (equipment != null) {
      await publishEvent(createEvent(
        eventType: 'save_data',
        targetAgent: 'data_persistence',
        data: {
          'collection': 'user_equipment',
          'id': userId,
          'data': equipment.toJson(),
        },
      ));
    }

    // Also save to SharedPreferences as backup
    await _saveAllUserEquipment();
  }

  /// Save user currency
  Future<void> _saveUserCurrency(String userId) async {
    final currency = _userCurrency[userId] ?? 0;
    await publishEvent(createEvent(
      eventType: 'save_data',
      targetAgent: 'data_persistence',
      data: {
        'collection': 'user_currency',
        'id': userId,
        'data': {'gold': currency},
      },
    ));

    // Also save to SharedPreferences as backup
    await _saveAllUserCurrency();
  }

  /// Save all user inventories to SharedPreferences
  Future<void> _saveAllUserInventories() async {
    final data = _userInventories.map((userId, inventory) =>
        MapEntry(userId, inventory.map((card) => card.toJson()).toList()));
    await _prefs.setString('user_inventories', jsonEncode(data));
  }

  /// Save all user equipment to SharedPreferences
  Future<void> _saveAllUserEquipment() async {
    final data = _userEquipment.map((userId, equipment) =>
        MapEntry(userId, equipment.toJson()));
    await _prefs.setString('user_equipment', jsonEncode(data));
  }

  /// Save all user currency to SharedPreferences
  Future<void> _saveAllUserCurrency() async {
    await _prefs.setString('user_currency', jsonEncode(_userCurrency));
  }

  /// Log activity
  void _logActivity(String action, Map<String, dynamic> data) {
    _recentActivity.add({
      'action': action,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Keep only last 100 activities
    if (_recentActivity.length > 100) {
      _recentActivity.removeAt(0);
    }
  }

  /// Handle QR card scan events
  Future<AgentEventResponse?> _handleQRCardScan(AgentEvent event) async {
    final qrData = event.data['qrData'];
    
    try {
      final result = await scanQRCard(qrData);
      
      return createResponse(
        originalEventId: event.id,
        responseType: 'qr_scan_result',
        data: result != null ? {
          'success': true,
          'type': result.type.toString(),
          'actions': result.availableActions,
        } : {
          'success': false,
          'error': 'Failed to parse QR code',
        },
      );
    } catch (e) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'qr_scan_failed',
        data: {'error': e.toString()},
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Handle QR result processing events
  Future<AgentEventResponse?> _handleQRResult(AgentEvent event) async {
    final action = event.data['action'];
    final qrData = event.data['qrData'];
    final userId = event.data['userId'] ?? _currentUserId;

    if (userId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'qr_result_failed',
        data: {'error': 'No user ID provided'},
        success: false,
      );
    }

    try {
      final result = await _qrScanner.scanAndParseQR(qrData);
      if (result == null) {
        return createResponse(
          originalEventId: event.id,
          responseType: 'qr_result_failed',
          data: {'error': 'Invalid QR data'},
          success: false,
        );
      }

      switch (action) {
        case 'Add to Inventory':
          if (result.type == QRCardType.item && result.data is GameCard) {
            final card = result.data as GameCard;
            await addCardToInventory(userId, card.id, source: 'qr_scan');
          }
          break;
        case 'Equip':
          if (result.type == QRCardType.item && result.data is GameCard) {
            final card = result.data as GameCard;
            if (card.equipmentSlot != EquipmentSlot.none) {
              await equipCard(userId, card.id, card.equipmentSlot);
            }
          }
          break;
      }

      return createResponse(
        originalEventId: event.id,
        responseType: 'qr_result_processed',
        data: {'action': action, 'processed': true},
      );
    } catch (e) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'qr_result_failed',
        data: {'error': e.toString()},
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Handle get inventory events
  Future<AgentEventResponse?> _handleGetInventory(AgentEvent event) async {
    final userId = event.data['userId'] ?? _currentUserId;
    
    if (userId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'inventory_failed',
        data: {'error': 'No user ID provided'},
        success: false,
      );
    }

    final inventory = _userInventories[userId] ?? [];
    final inventoryWithCards = inventory.map((owned) {
      final card = _allCards[owned.cardId];
      return {
        'owned': owned.toJson(),
        'card': card?.toJson(),
      };
    }).toList();

    return createResponse(
      originalEventId: event.id,
      responseType: 'inventory_data',
      data: {
        'userId': userId,
        'inventory': inventoryWithCards,
        'totalCards': inventory.length,
        'uniqueCards': inventory.map((c) => c.cardId).toSet().length,
      },
    );
  }

  /// Handle add card to inventory events
  Future<AgentEventResponse?> _handleAddCardToInventory(AgentEvent event) async {
    final userId = event.data['userId'] ?? _currentUserId;
    final cardId = event.data['cardId'];
    final quantity = event.data['quantity'] ?? 1;
    final source = event.data['source'] ?? 'unknown';
    final metadata = Map<String, dynamic>.from(event.data['metadata'] ?? {});

    if (userId == null || cardId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'add_card_failed',
        data: {'error': 'Missing required parameters'},
        success: false,
      );
    }

    final success = await addCardToInventory(
      userId,
      cardId,
      quantity: quantity,
      source: source,
      metadata: metadata,
    );

    return createResponse(
      originalEventId: event.id,
      responseType: success ? 'card_added' : 'add_card_failed',
      data: {
        'userId': userId,
        'cardId': cardId,
        'quantity': quantity,
        'success': success,
      },
      success: success,
    );
  }

  /// Handle remove card from inventory events
  Future<AgentEventResponse?> _handleRemoveCardFromInventory(AgentEvent event) async {
    final userId = event.data['userId'] ?? _currentUserId;
    final cardId = event.data['cardId'];
    final quantity = event.data['quantity'] ?? 1;

    if (userId == null || cardId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'remove_card_failed',
        data: {'error': 'Missing required parameters'},
        success: false,
      );
    }

    final inventory = _userInventories[userId] ?? [];
    final cardIndex = inventory.indexWhere((owned) => owned.cardId == cardId);
    
    if (cardIndex == -1) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'remove_card_failed',
        data: {'error': 'Card not found in inventory'},
        success: false,
      );
    }

    final ownedCard = inventory[cardIndex];
    if (ownedCard.quantity <= quantity) {
      inventory.removeAt(cardIndex);
    } else {
      inventory[cardIndex] = ownedCard.copyWith(quantity: ownedCard.quantity - quantity);
    }

    await _saveUserInventory(userId);

    return createResponse(
      originalEventId: event.id,
      responseType: 'card_removed',
      data: {
        'userId': userId,
        'cardId': cardId,
        'quantity': quantity,
      },
    );
  }

  /// Handle transfer card events
  Future<AgentEventResponse?> _handleTransferCard(AgentEvent event) async {
    final fromUserId = event.data['fromUserId'];
    final toUserId = event.data['toUserId'];
    final cardId = event.data['cardId'];
    final quantity = event.data['quantity'] ?? 1;

    if (fromUserId == null || toUserId == null || cardId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'transfer_failed',
        data: {'error': 'Missing required parameters'},
        success: false,
      );
    }

    // Remove from sender
    await _handleRemoveCardFromInventory(createEvent(
      eventType: 'remove_card_from_inventory',
      data: {'userId': fromUserId, 'cardId': cardId, 'quantity': quantity},
    ));

    // Add to receiver
    await addCardToInventory(
      toUserId,
      cardId,
      quantity: quantity,
      source: 'transfer_from_$fromUserId',
    );

    return createResponse(
      originalEventId: event.id,
      responseType: 'card_transferred',
      data: {
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'cardId': cardId,
        'quantity': quantity,
      },
    );
  }

  /// Handle equip card events
  Future<AgentEventResponse?> _handleEquipCard(AgentEvent event) async {
    final userId = event.data['userId'] ?? _currentUserId;
    final cardId = event.data['cardId'];
    final slotName = event.data['slot'];

    if (userId == null || cardId == null || slotName == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'equip_failed',
        data: {'error': 'Missing required parameters'},
        success: false,
      );
    }

    final slot = EquipmentSlot.values.firstWhere(
      (s) => s.toString() == slotName,
      orElse: () => EquipmentSlot.none,
    );

    if (slot == EquipmentSlot.none) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'equip_failed',
        data: {'error': 'Invalid equipment slot'},
        success: false,
      );
    }

    final success = await equipCard(userId, cardId, slot);

    return createResponse(
      originalEventId: event.id,
      responseType: success ? 'card_equipped' : 'equip_failed',
      data: {
        'userId': userId,
        'cardId': cardId,
        'slot': slotName,
        'success': success,
      },
      success: success,
    );
  }

  /// Handle unequip card events
  Future<AgentEventResponse?> _handleUnequipCard(AgentEvent event) async {
    final userId = event.data['userId'] ?? _currentUserId;
    final slotName = event.data['slot'];

    if (userId == null || slotName == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'unequip_failed',
        data: {'error': 'Missing required parameters'},
        success: false,
      );
    }

    final slot = EquipmentSlot.values.firstWhere(
      (s) => s.toString() == slotName,
      orElse: () => EquipmentSlot.none,
    );

    if (slot == EquipmentSlot.none) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'unequip_failed',
        data: {'error': 'Invalid equipment slot'},
        success: false,
      );
    }

    final success = await unequipCard(userId, slot);

    return createResponse(
      originalEventId: event.id,
      responseType: success ? 'card_unequipped' : 'unequip_failed',
      data: {
        'userId': userId,
        'slot': slotName,
        'success': success,
      },
      success: success,
    );
  }

  /// Handle get equipment events
  Future<AgentEventResponse?> _handleGetEquipment(AgentEvent event) async {
    final userId = event.data['userId'] ?? _currentUserId;
    
    if (userId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'equipment_failed',
        data: {'error': 'No user ID provided'},
        success: false,
      );
    }

    final loadout = _userEquipment[userId] ?? EquipmentLoadout(ownerId: userId);
    final equipmentWithCards = <String, dynamic>{};

    for (final entry in loadout.equippedCards.entries) {
      final card = _allCards[entry.value];
      equipmentWithCards[entry.key.toString()] = {
        'cardId': entry.value,
        'card': card?.toJson(),
      };
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'equipment_data',
      data: {
        'userId': userId,
        'equipment': equipmentWithCards,
        'lastModified': loadout.lastModified.toIso8601String(),
      },
    );
  }

  /// Handle get equipment stats events
  Future<AgentEventResponse?> _handleGetEquipmentStats(AgentEvent event) async {
    final userId = event.data['userId'] ?? _currentUserId;
    
    if (userId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'equipment_stats_failed',
        data: {'error': 'No user ID provided'},
        success: false,
      );
    }

    final stats = getEquipmentStats(userId);

    return createResponse(
      originalEventId: event.id,
      responseType: 'equipment_stats',
      data: {
        'userId': userId,
        'stats': stats,
      },
    );
  }

  /// Handle get card collection events
  Future<AgentEventResponse?> _handleGetCardCollection(AgentEvent event) async {
    final userId = event.data['userId'] ?? _currentUserId;
    final includeUnowned = event.data['includeUnowned'] ?? false;
    
    if (userId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'collection_failed',
        data: {'error': 'No user ID provided'},
        success: false,
      );
    }

    final inventory = _userInventories[userId] ?? [];
    final ownedCardIds = inventory.map((owned) => owned.cardId).toSet();

    List<Map<String, dynamic>> collection;
    if (includeUnowned) {
      collection = _allCards.values.map((card) {
        final isOwned = ownedCardIds.contains(card.id);
        return {
          'card': card.toJson(),
          'owned': isOwned,
          'quantity': isOwned ? inventory.firstWhere((o) => o.cardId == card.id).quantity : 0,
        };
      }).toList();
    } else {
      collection = inventory.map((owned) {
        final card = _allCards[owned.cardId];
        return {
          'owned': owned.toJson(),
          'card': card?.toJson(),
        };
      }).toList();
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'card_collection',
      data: {
        'userId': userId,
        'collection': collection,
        'totalCards': _allCards.length,
        'ownedCards': ownedCardIds.length,
        'completionPercentage': (ownedCardIds.length / _allCards.length * 100).round(),
      },
    );
  }

  /// Handle search cards events
  Future<AgentEventResponse?> _handleSearchCards(AgentEvent event) async {
    final query = event.data['query'] ?? '';
    final type = event.data['type'];
    final rarity = event.data['rarity'];
    final set = event.data['set'];

    var results = _allCards.values.toList();

    // Apply filters
    if (query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      results = results.where((card) =>
          card.name.toLowerCase().contains(lowerQuery) ||
          card.description.toLowerCase().contains(lowerQuery)).toList();
    }

    if (type != null) {
      final cardType = CardType.values.firstWhere(
        (t) => t.toString() == type,
        orElse: () => CardType.item,
      );
      results = results.where((card) => card.type == cardType).toList();
    }

    if (rarity != null) {
      final cardRarity = CardRarity.values.firstWhere(
        (r) => r.toString() == rarity,
        orElse: () => CardRarity.common,
      );
      results = results.where((card) => card.rarity == cardRarity).toList();
    }

    if (set != null) {
      final cardSet = CardSet.values.firstWhere(
        (s) => s.toString() == set,
        orElse: () => CardSet.core,
      );
      results = results.where((card) => card.set == cardSet).toList();
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'search_results',
      data: {
        'query': query,
        'results': results.map((card) => card.toJson()).toList(),
        'count': results.length,
      },
    );
  }

  /// Handle get card details events
  Future<AgentEventResponse?> _handleGetCardDetails(AgentEvent event) async {
    final cardId = event.data['cardId'];
    
    if (cardId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'card_details_failed',
        data: {'error': 'No card ID provided'},
        success: false,
      );
    }

    final card = _allCards[cardId];
    if (card == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'card_details_failed',
        data: {'error': 'Card not found'},
        success: false,
      );
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'card_details',
      data: {
        'card': card.toJson(),
        'stats': _calculateCardStats(card),
      },
    );
  }

  /// Handle get card packs events
  Future<AgentEventResponse?> _handleGetCardPacks(AgentEvent event) async {
    final packs = _cardPacks.values.map((pack) => {
      'id': pack.id,
      'name': pack.name,
      'description': pack.description,
      'cardCount': pack.cardCount,
      'cost': pack.cost,
      'rarityWeights': pack.rarityWeights.map((k, v) => MapEntry(k.toString(), v)),
    }).toList();

    return createResponse(
      originalEventId: event.id,
      responseType: 'card_packs',
      data: {
        'packs': packs,
        'count': packs.length,
      },
    );
  }

  /// Handle open card pack events
  Future<AgentEventResponse?> _handleOpenCardPack(AgentEvent event) async {
    final userId = event.data['userId'] ?? _currentUserId;
    final packId = event.data['packId'];

    if (userId == null || packId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'pack_open_failed',
        data: {'error': 'Missing required parameters'},
        success: false,
      );
    }

    final cards = await openCardPack(userId, packId);

    return createResponse(
      originalEventId: event.id,
      responseType: cards.isNotEmpty ? 'pack_opened' : 'pack_open_failed',
      data: {
        'userId': userId,
        'packId': packId,
        'cards': cards.map((card) => card.toJson()).toList(),
        'cardCount': cards.length,
      },
      success: cards.isNotEmpty,
    );
  }

  /// Handle buy card pack events
  Future<AgentEventResponse?> _handleBuyCardPack(AgentEvent event) async {
    final userId = event.data['userId'] ?? _currentUserId;
    final packId = event.data['packId'];

    if (userId == null || packId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'pack_buy_failed',
        data: {'error': 'Missing required parameters'},
        success: false,
      );
    }

    final pack = _cardPacks[packId];
    if (pack == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'pack_buy_failed',
        data: {'error': 'Pack not found'},
        success: false,
      );
    }

    final userGold = _userCurrency[userId] ?? 0;
    if (userGold < pack.cost) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'pack_buy_failed',
        data: {'error': 'Insufficient gold'},
        success: false,
      );
    }

    // Immediately open the pack after buying
    final cards = await openCardPack(userId, packId);

    return createResponse(
      originalEventId: event.id,
      responseType: 'pack_bought',
      data: {
        'userId': userId,
        'packId': packId,
        'cost': pack.cost,
        'remainingGold': _userCurrency[userId] ?? 0,
        'cards': cards.map((card) => card.toJson()).toList(),
      },
    );
  }

  /// Handle get shop inventory events
  Future<AgentEventResponse?> _handleGetShopInventory(AgentEvent event) async {
    final userId = event.data['userId'] ?? _currentUserId;
    
    return createResponse(
      originalEventId: event.id,
      responseType: 'shop_inventory',
      data: {
        'packs': _cardPacks.values.map((pack) => {
          'id': pack.id,
          'name': pack.name,
          'description': pack.description,
          'cost': pack.cost,
          'cardCount': pack.cardCount,
        }).toList(),
        'userGold': _userCurrency[userId] ?? 0,
      },
    );
  }

  /// Handle inventory reward events
  Future<AgentEventResponse?> _handleInventoryReward(AgentEvent event) async {
    final userId = event.data['userId'];
    final cards = List<String>.from(event.data['cards'] ?? []);
    final gold = event.data['gold'] ?? 0;
    final source = event.data['source'] ?? 'reward';

    if (userId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'inventory_reward_failed',
        data: {'error': 'No user ID provided'},
        success: false,
      );
    }

    // Add cards to inventory
    for (final cardId in cards) {
      await addCardToInventory(userId, cardId, source: source);
    }

    // Add gold
    if (gold > 0) {
      _userCurrency[userId] = (_userCurrency[userId] ?? 0) + gold;
      await _saveUserCurrency(userId);
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'inventory_reward_processed',
      data: {
        'userId': userId,
        'cardsAdded': cards.length,
        'goldAdded': gold,
        'source': source,
      },
    );
  }

  /// Handle character reward events
  Future<AgentEventResponse?> _handleCharacterReward(AgentEvent event) async {
    // This agent doesn't directly handle character rewards,
    // but it can acknowledge the event
    return createResponse(
      originalEventId: event.id,
      responseType: 'character_reward_acknowledged',
      data: {'acknowledged': true},
    );
  }

  /// Handle user login events
  Future<AgentEventResponse?> _handleUserLogin(AgentEvent event) async {
    final userId = event.data['userId'];
    _currentUserId = userId;

    if (userId != null) {
      // Initialize user data if needed
      _userInventories.putIfAbsent(userId, () => []);
      _userEquipment.putIfAbsent(userId, () => EquipmentLoadout(ownerId: userId));
      _userCurrency.putIfAbsent(userId, () => 1000); // Starting gold

      await _saveUserInventory(userId);
      await _saveUserEquipment(userId);
      await _saveUserCurrency(userId);
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'user_login_processed',
      data: {'userId': userId},
    );
  }

  /// Handle user logout events
  Future<AgentEventResponse?> _handleUserLogout(AgentEvent event) async {
    if (_currentUserId != null) {
      await _saveUserInventory(_currentUserId!);
      await _saveUserEquipment(_currentUserId!);
      await _saveUserCurrency(_currentUserId!);
      _currentUserId = null;
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'user_logout_processed',
      data: {'loggedOut': true},
    );
  }

  /// Handle save card data events
  Future<AgentEventResponse?> _handleSaveCardData(AgentEvent event) async {
    await _saveAllUserInventories();
    await _saveAllUserEquipment();
    await _saveAllUserCurrency();

    return createResponse(
      originalEventId: event.id,
      responseType: 'card_data_saved',
      data: {'saved': true},
    );
  }

  /// Handle load card data events
  Future<AgentEventResponse?> _handleLoadCardData(AgentEvent event) async {
    await _loadUserData();

    return createResponse(
      originalEventId: event.id,
      responseType: 'card_data_loaded',
      data: {'loaded': true},
    );
  }

  @override
  Future<void> onDispose() async {
    // Save all user data
    await _saveAllUserInventories();
    await _saveAllUserEquipment();
    await _saveAllUserCurrency();

    developer.log('Card System Agent disposed', name: agentId);
  }
}