import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/character_model.dart';
import '../models/card_model.dart';

enum QRScanMode {
  card,
  quest,
  enemy,
  item,
  location,
  achievement,
}

enum QRCodeType {
  card,
  quest,
  enemy,
  item,
  location,
  achievement,
  unknown,
}

class QRCodeData {
  final String id;
  final QRCodeType type;
  final String title;
  final String description;
  final Map<String, dynamic> data;
  final DateTime scannedAt;
  final bool isRedeemed;

  const QRCodeData({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.data,
    required this.scannedAt,
    this.isRedeemed = false,
  });

  QRCodeData copyWith({
    bool? isRedeemed,
  }) {
    return QRCodeData(
      id: id,
      type: type,
      title: title,
      description: description,
      data: data,
      scannedAt: scannedAt,
      isRedeemed: isRedeemed ?? this.isRedeemed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'description': description,
      'data': data,
      'scannedAt': scannedAt.millisecondsSinceEpoch,
      'isRedeemed': isRedeemed,
    };
  }

  factory QRCodeData.fromJson(Map<String, dynamic> json) {
    return QRCodeData(
      id: json['id'] as String,
      type: QRCodeType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map),
      scannedAt: DateTime.fromMillisecondsSinceEpoch(json['scannedAt'] as int),
      isRedeemed: json['isRedeemed'] as bool? ?? false,
    );
  }
}

class QRScannerService extends ChangeNotifier {
  static QRScannerService? _instance;
  static QRScannerService get instance => _instance ??= QRScannerService._();
  QRScannerService._();

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // QR Scanner data
  final List<QRCodeData> _scannedCodes = [];
  final Map<String, QRCodeData> _availableCodes = {};
  QRScanMode _currentMode = QRScanMode.card;

  // Getters
  List<QRCodeData> get scannedCodes => List.unmodifiable(_scannedCodes);
  Map<String, QRCodeData> get availableCodes => Map.unmodifiable(_availableCodes);
  QRScanMode get currentMode => _currentMode;

  // Initialize service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    await _loadQRData();
    _initializeSampleCodes();
    _isInitialized = true;
    notifyListeners();
  }

  // Load QR data from preferences
  Future<void> _loadQRData() async {
    final scannedCodesJson = _prefs.getStringList('qr_scanned_codes') ?? [];
    _scannedCodes.clear();
    for (final json in scannedCodesJson) {
      try {
        final data = Map<String, dynamic>.from(json as Map);
        _scannedCodes.add(QRCodeData.fromJson(data));
      } catch (e) {
        if (kDebugMode) {
          print('[QRScannerService] Error loading scanned code: $e');
        }
      }
    }
  }

  // Save QR data to preferences
  Future<void> _saveQRData() async {
    final scannedCodesJson = _scannedCodes
        .map((code) => code.toJson().toString())
        .toList();
    await _prefs.setStringList('qr_scanned_codes', scannedCodesJson);
  }

  // Initialize sample QR codes
  void _initializeSampleCodes() {
    // Card QR codes
    _availableCodes['card_sword_legendary'] = QRCodeData(
      id: 'card_sword_legendary',
      type: QRCodeType.card,
      title: 'Legendary Sword',
      description: 'A powerful legendary sword card',
      data: {
        'cardId': 'sword_legendary',
        'rarity': 'legendary',
        'equipmentSlot': 'weapon',
        'requiredLevel': 20,
        'damage': 150,
        'durability': 100,
      },
      scannedAt: DateTime.now(),
    );

    _availableCodes['card_shield_epic'] = QRCodeData(
      id: 'card_shield_epic',
      type: QRCodeType.card,
      title: 'Epic Shield',
      description: 'A sturdy epic shield card',
      data: {
        'cardId': 'shield_epic',
        'rarity': 'epic',
        'equipmentSlot': 'offhand',
        'requiredLevel': 15,
        'defense': 80,
        'block_chance': 15,
      },
      scannedAt: DateTime.now(),
    );

    // Quest QR codes
    _availableCodes['quest_dragon_hunt'] = QRCodeData(
      id: 'quest_dragon_hunt',
      type: QRCodeType.quest,
      title: 'Dragon Hunt Quest',
      description: 'Hunt down the ancient dragon',
      data: {
        'questId': 'dragon_hunt',
        'type': 'battle',
        'requiredLevel': 25,
        'experience': 500,
        'gold': 200,
        'items': ['dragon_scales', 'dragon_heart'],
      },
      scannedAt: DateTime.now(),
    );

    _availableCodes['quest_treasure_map'] = QRCodeData(
      id: 'quest_treasure_map',
      type: QRCodeType.quest,
      title: 'Treasure Map Quest',
      description: 'Follow the map to find hidden treasure',
      data: {
        'questId': 'treasure_map',
        'type': 'exploration',
        'requiredLevel': 10,
        'experience': 300,
        'gold': 150,
        'items': ['ancient_coin', 'gemstone'],
      },
      scannedAt: DateTime.now(),
    );

    // Enemy QR codes
    _availableCodes['enemy_dragon'] = QRCodeData(
      id: 'enemy_dragon',
      type: QRCodeType.enemy,
      title: 'Ancient Dragon',
      description: 'A powerful ancient dragon enemy',
      data: {
        'enemyId': 'ancient_dragon',
        'level': 30,
        'health': 1000,
        'damage': 200,
        'experience': 500,
        'loot': ['dragon_scales', 'dragon_heart', 'gold'],
      },
      scannedAt: DateTime.now(),
    );

    _availableCodes['enemy_goblin'] = QRCodeData(
      id: 'enemy_goblin',
      type: QRCodeType.enemy,
      title: 'Goblin Warrior',
      description: 'A fierce goblin warrior',
      data: {
        'enemyId': 'goblin_warrior',
        'level': 5,
        'health': 100,
        'damage': 25,
        'experience': 50,
        'loot': ['goblin_ear', 'copper_coin'],
      },
      scannedAt: DateTime.now(),
    );

    // Item QR codes
    _availableCodes['item_health_potion'] = QRCodeData(
      id: 'item_health_potion',
      type: QRCodeType.item,
      title: 'Health Potion',
      description: 'Restores health when consumed',
      data: {
        'itemId': 'health_potion',
        'type': 'consumable',
        'effect': 'heal',
        'value': 100,
        'stackable': true,
        'max_stack': 10,
      },
      scannedAt: DateTime.now(),
    );

    _availableCodes['item_mana_potion'] = QRCodeData(
      id: 'item_mana_potion',
      type: QRCodeType.item,
      title: 'Mana Potion',
      description: 'Restores mana when consumed',
      data: {
        'itemId': 'mana_potion',
        'type': 'consumable',
        'effect': 'mana',
        'value': 80,
        'stackable': true,
        'max_stack': 10,
      },
      scannedAt: DateTime.now(),
    );

    // Location QR codes
    _availableCodes['location_dragon_cave'] = QRCodeData(
      id: 'location_dragon_cave',
      type: QRCodeType.location,
      title: 'Dragon Cave',
      description: 'A dangerous cave inhabited by dragons',
      data: {
        'locationId': 'dragon_cave',
        'type': 'dungeon',
        'requiredLevel': 20,
        'enemies': ['dragon', 'dragon_whelp'],
        'loot': ['dragon_scales', 'dragon_heart'],
        'experience': 1000,
      },
      scannedAt: DateTime.now(),
    );

    // Achievement QR codes
    _availableCodes['achievement_first_scan'] = QRCodeData(
      id: 'achievement_first_scan',
      type: QRCodeType.achievement,
      title: 'First Scan',
      description: 'Scan your first QR code',
      data: {
        'achievementId': 'first_scan',
        'experience': 50,
        'gold': 25,
        'title': 'QR Scanner',
      },
      scannedAt: DateTime.now(),
    );
  }

  // Set scan mode
  void setScanMode(QRScanMode mode) {
    _currentMode = mode;
    notifyListeners();

    if (kDebugMode) {
      print('[QRScannerService] Scan mode set to: ${mode.name}');
    }
  }

  // Scan a QR code
  Future<QRCodeData?> scanQRCode(String qrData) async {
    try {
      // Parse QR data (in a real app, this would decode the actual QR code)
      final codeData = _parseQRData(qrData);
      
      if (codeData != null) {
        // Check if code is available
        if (_availableCodes.containsKey(codeData.id)) {
          final scannedCode = _availableCodes[codeData.id]!;
          
          // Add to scanned codes if not already scanned
          if (!_scannedCodes.any((code) => code.id == scannedCode.id)) {
            _scannedCodes.add(scannedCode);
            await _saveQRData();
            notifyListeners();

            if (kDebugMode) {
              print('[QRScannerService] Scanned QR code: ${scannedCode.title}');
            }

            return scannedCode;
          } else {
            if (kDebugMode) {
              print('[QRScannerService] QR code already scanned: ${scannedCode.title}');
            }
            return null;
          }
        } else {
          if (kDebugMode) {
            print('[QRScannerService] QR code not found: $qrData');
          }
          return null;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[QRScannerService] Error scanning QR code: $e');
      }
    }

    return null;
  }

  // Parse QR data (simulate QR code parsing)
  QRCodeData? _parseQRData(String qrData) {
    // In a real implementation, this would parse actual QR code data
    // For now, we'll simulate by checking if the data matches our available codes
    
    // Check if the QR data matches any of our available codes
    for (final code in _availableCodes.values) {
      if (qrData.contains(code.id) || qrData.contains(code.title.toLowerCase())) {
        return code;
      }
    }

    // If no match found, create a generic code based on the scan mode
    return _createGenericCode(qrData);
  }

  // Create a generic QR code based on scan mode
  QRCodeData? _createGenericCode(String qrData) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final id = '${_currentMode.name}_${timestamp}';
    
    switch (_currentMode) {
      case QRScanMode.card:
        return QRCodeData(
          id: id,
          type: QRCodeType.card,
          title: 'Mystery Card',
          description: 'A mysterious card found through QR scanning',
          data: {
            'cardId': 'mystery_card_$timestamp',
            'rarity': 'common',
            'equipmentSlot': 'weapon',
            'requiredLevel': 1,
            'damage': 10,
          },
          scannedAt: DateTime.now(),
        );
      
      case QRScanMode.quest:
        return QRCodeData(
          id: id,
          type: QRCodeType.quest,
          title: 'Mystery Quest',
          description: 'A mysterious quest found through QR scanning',
          data: {
            'questId': 'mystery_quest_$timestamp',
            'type': 'exploration',
            'requiredLevel': 1,
            'experience': 50,
            'gold': 25,
          },
          scannedAt: DateTime.now(),
        );
      
      case QRScanMode.enemy:
        return QRCodeData(
          id: id,
          type: QRCodeType.enemy,
          title: 'Mystery Enemy',
          description: 'A mysterious enemy found through QR scanning',
          data: {
            'enemyId': 'mystery_enemy_$timestamp',
            'level': 1,
            'health': 50,
            'damage': 10,
            'experience': 25,
          },
          scannedAt: DateTime.now(),
        );
      
      case QRScanMode.item:
        return QRCodeData(
          id: id,
          type: QRCodeType.item,
          title: 'Mystery Item',
          description: 'A mysterious item found through QR scanning',
          data: {
            'itemId': 'mystery_item_$timestamp',
            'type': 'consumable',
            'effect': 'heal',
            'value': 25,
          },
          scannedAt: DateTime.now(),
        );
      
      case QRScanMode.location:
        return QRCodeData(
          id: id,
          type: QRCodeType.location,
          title: 'Mystery Location',
          description: 'A mysterious location found through QR scanning',
          data: {
            'locationId': 'mystery_location_$timestamp',
            'type': 'exploration',
            'requiredLevel': 1,
            'experience': 100,
          },
          scannedAt: DateTime.now(),
        );
      
      case QRScanMode.achievement:
        return QRCodeData(
          id: id,
          type: QRCodeType.achievement,
          title: 'Mystery Achievement',
          description: 'A mysterious achievement found through QR scanning',
          data: {
            'achievementId': 'mystery_achievement_$timestamp',
            'experience': 25,
            'gold': 10,
          },
          scannedAt: DateTime.now(),
        );
    }
  }

  // Redeem a scanned QR code
  Future<bool> redeemQRCode(String codeId) async {
    final scannedCode = _scannedCodes.firstWhere(
      (code) => code.id == codeId,
      orElse: () => throw Exception('QR code not found'),
    );

    if (scannedCode.isRedeemed) {
      if (kDebugMode) {
        print('[QRScannerService] QR code already redeemed: ${scannedCode.title}');
      }
      return false;
    }

    // Mark as redeemed
    final index = _scannedCodes.indexWhere((code) => code.id == codeId);
    if (index != -1) {
      _scannedCodes[index] = scannedCode.copyWith(isRedeemed: true);
      await _saveQRData();
      notifyListeners();

      if (kDebugMode) {
        print('[QRScannerService] Redeemed QR code: ${scannedCode.title}');
      }

      return true;
    }

    return false;
  }

  // Get scanned codes by type
  List<QRCodeData> getScannedCodesByType(QRCodeType type) {
    return _scannedCodes.where((code) => code.type == type).toList();
  }

  // Get available codes by type
  List<QRCodeData> getAvailableCodesByType(QRCodeType type) {
    return _availableCodes.values.where((code) => code.type == type).toList();
  }

  // Get QR scanner statistics
  Map<String, dynamic> getQRScannerStatistics() {
    final totalScanned = _scannedCodes.length;
    final totalRedeemed = _scannedCodes.where((code) => code.isRedeemed).length;
    final totalAvailable = _availableCodes.length;

    final typeStats = <String, int>{};
    for (final type in QRCodeType.values) {
      typeStats[type.name] = _scannedCodes.where((code) => code.type == type).length;
    }

    return {
      'totalScanned': totalScanned,
      'totalRedeemed': totalRedeemed,
      'totalAvailable': totalAvailable,
      'completionRate': totalAvailable > 0 ? totalScanned / totalAvailable : 0.0,
      'redemptionRate': totalScanned > 0 ? totalRedeemed / totalScanned : 0.0,
      'typeStats': typeStats,
    };
  }

  // Clear all scanned codes (for testing)
  void clearScannedCodes() {
    _scannedCodes.clear();
    _saveQRData();
    notifyListeners();

    if (kDebugMode) {
      print('[QRScannerService] Cleared all scanned codes');
    }
  }

  // Add a custom QR code
  void addCustomQRCode(QRCodeData code) {
    _availableCodes[code.id] = code;
    notifyListeners();

    if (kDebugMode) {
      print('[QRScannerService] Added custom QR code: ${code.title}');
    }
  }

  // Remove a QR code
  void removeQRCode(String codeId) {
    _availableCodes.remove(codeId);
    _scannedCodes.removeWhere((code) => code.id == codeId);
    _saveQRData();
    notifyListeners();

    if (kDebugMode) {
      print('[QRScannerService] Removed QR code: $codeId');
    }
  }
}