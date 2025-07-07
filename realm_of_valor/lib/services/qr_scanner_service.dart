import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card_model.dart';
import '../models/battle_model.dart';
import '../models/quest_model.dart';

enum QRCardType {
  item,
  enemy,
  quest,
  skill,
  spell,
  attribute,
  unknown,
}

class QRScanResult {
  final QRCardType type;
  final dynamic data;
  final String rawData;
  final List<String> availableActions;

  QRScanResult({
    required this.type,
    required this.data,
    required this.rawData,
    required this.availableActions,
  });
}

class QRScannerService {
  static QRScannerService? _instance;
  static Future<QRScannerService> getInstance() async {
    _instance ??= QRScannerService._internal();
    return _instance!;
  }
  
  QRScannerService._internal();

  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<QRScanResult?> scanAndParseQR(String qrData) async {
    try {
      // Try to parse as JSON first
      final Map<String, dynamic> data = jsonDecode(qrData);
      
      // Determine card type based on data structure
      if (data.containsKey('type')) {
        switch (data['type']) {
          case 'item':
          case 'weapon':
          case 'armor':
          case 'accessory':
          case 'consumable':
            return _parseItemCard(data);
          case 'enemy':
            return _parseEnemyCard(data);
          case 'quest':
            return _parseQuestCard(data);
          case 'skill':
            return _parseSkillCard(data);
          case 'spell':
            return _parseSpellCard(data);
          case 'attribute':
            return _parseAttributeCard(data);
          default:
            return QRScanResult(
              type: QRCardType.unknown,
              data: data,
              rawData: qrData,
              availableActions: ['Dismiss'],
            );
        }
      }
      
      // If no type specified, try to infer from structure
      return _inferCardType(data, qrData);
    } catch (e) {
      // If JSON parsing fails, treat as plain text
      return QRScanResult(
        type: QRCardType.unknown,
        data: qrData,
        rawData: qrData,
        availableActions: ['Dismiss'],
      );
    }
  }

  QRScanResult _parseItemCard(Map<String, dynamic> data) {
    try {
      final card = GameCard.fromJson(data);
      List<String> actions = [];
      
      if (card.equipmentSlot != EquipmentSlot.none) {
        actions.add('Equip');
      }
      
      actions.addAll(['Add to Inventory', 'Sell', 'Discard']);
      
      if (card.isTradeable) {
        actions.add('Trade');
      }
      
      return QRScanResult(
        type: QRCardType.item,
        data: card,
        rawData: jsonEncode(data),
        availableActions: actions,
      );
    } catch (e) {
      return QRScanResult(
        type: QRCardType.unknown,
        data: data,
        rawData: jsonEncode(data),
        availableActions: ['Dismiss'],
      );
    }
  }

  QRScanResult _parseEnemyCard(Map<String, dynamic> data) {
    try {
      final enemy = EnemyCard.fromJson(data);
      List<String> actions = [];
      
      // Add actions based on enemy card properties
      if (enemy.battleActions.containsKey('challenge')) {
        actions.add('Challenge to Battle');
      }
      
      if (enemy.battleActions.containsKey('recruit')) {
        actions.add('Recruit as Ally');
      }
      
      if (enemy.battleActions.containsKey('trade')) {
        actions.add('Trade with Enemy');
      }
      
      actions.addAll(['Study Enemy', 'Add to Bestiary', 'Dismiss']);
      
      return QRScanResult(
        type: QRCardType.enemy,
        data: enemy,
        rawData: jsonEncode(data),
        availableActions: actions,
      );
    } catch (e) {
      return QRScanResult(
        type: QRCardType.unknown,
        data: data,
        rawData: jsonEncode(data),
        availableActions: ['Dismiss'],
      );
    }
  }

  QRScanResult _parseQuestCard(Map<String, dynamic> data) {
    try {
      final quest = Quest.fromJson(data);
      List<String> actions = [];
      
      if (quest.status == QuestStatus.available) {
        actions.add('Start Quest');
      }
      
      if (quest.location != null) {
        actions.add('Show on Map');
      }
      
      actions.addAll(['View Details', 'Save for Later', 'Dismiss']);
      
      return QRScanResult(
        type: QRCardType.quest,
        data: quest,
        rawData: jsonEncode(data),
        availableActions: actions,
      );
    } catch (e) {
      return QRScanResult(
        type: QRCardType.unknown,
        data: data,
        rawData: jsonEncode(data),
        availableActions: ['Dismiss'],
      );
    }
  }

  QRScanResult _parseSkillCard(Map<String, dynamic> data) {
    try {
      final skill = GameCard.fromJson(data);
      List<String> actions = [];
      
      actions.addAll(['Learn Skill', 'Add to Inventory', 'Share with Friend']);
      
      if (skill.levelRequirement > 1) {
        actions.add('Save for Later');
      }
      
      actions.add('Dismiss');
      
      return QRScanResult(
        type: QRCardType.skill,
        data: skill,
        rawData: jsonEncode(data),
        availableActions: actions,
      );
    } catch (e) {
      return QRScanResult(
        type: QRCardType.unknown,
        data: data,
        rawData: jsonEncode(data),
        availableActions: ['Dismiss'],
      );
    }
  }

  QRScanResult _parseSpellCard(Map<String, dynamic> data) {
    try {
      final spell = GameCard.fromJson(data);
      List<String> actions = [];
      
      actions.addAll(['Learn Spell', 'Add to Spellbook', 'Add to Inventory']);
      
      if (spell.isTradeable) {
        actions.add('Trade');
      }
      
      actions.add('Dismiss');
      
      return QRScanResult(
        type: QRCardType.spell,
        data: spell,
        rawData: jsonEncode(data),
        availableActions: actions,
      );
    } catch (e) {
      return QRScanResult(
        type: QRCardType.unknown,
        data: data,
        rawData: jsonEncode(data),
        availableActions: ['Dismiss'],
      );
    }
  }

  QRScanResult _parseAttributeCard(Map<String, dynamic> data) {
    List<String> actions = [];
    
    if (data.containsKey('bonus_type')) {
      if (data['bonus_type'] == 'flat') {
        actions.add('Apply Bonus');
      } else if (data['bonus_type'] == 'choice') {
        actions.add('Choose Attribute');
      }
    }
    
    actions.addAll(['Add to Inventory', 'Save for Later', 'Dismiss']);
    
    return QRScanResult(
      type: QRCardType.attribute,
      data: data,
      rawData: jsonEncode(data),
      availableActions: actions,
    );
  }

  QRScanResult _inferCardType(Map<String, dynamic> data, String rawData) {
    // Try to infer card type from common fields
    if (data.containsKey('equipmentSlot') || data.containsKey('statModifiers')) {
      return _parseItemCard(data);
    }
    
    if (data.containsKey('health') && data.containsKey('attackPower')) {
      return _parseEnemyCard(data);
    }
    
    if (data.containsKey('objectives') || data.containsKey('location')) {
      return _parseQuestCard(data);
    }
    
    return QRScanResult(
      type: QRCardType.unknown,
      data: data,
      rawData: rawData,
      availableActions: ['Dismiss'],
    );
  }

  Future<void> showQRResultPopup(BuildContext context, QRScanResult result) async {
    await showDialog(
      context: context,
      builder: (context) => QRResultDialog(result: result),
    );
  }

  // Generate some example QR codes for testing
  String generateSampleItemQR() {
    final card = GameCard(
      name: 'Dragon Slayer Sword',
      description: 'A legendary sword forged from dragon scales',
      type: CardType.weapon,
      rarity: CardRarity.legendary,
      equipmentSlot: EquipmentSlot.weapon1,
      statModifiers: [
        StatModifier(statName: 'strength', value: 25),
        StatModifier(statName: 'attack', value: 50),
      ],
      levelRequirement: 15,
      cost: 5000,
    );
    
    return jsonEncode(card.toJson());
  }

  String generateSampleEnemyQR() {
    final enemy = EnemyCard(
      name: 'Ancient Dragon',
      description: 'A powerful dragon that has terrorized the land for centuries',
      health: 500,
      mana: 200,
      attackPower: 80,
      defense: 40,
      abilities: ['Fire Breath', 'Dragon Roar', 'Tail Swipe'],
      weaknesses: ['Ice Magic', 'Lightning'],
      rarity: CardRarity.legendary,
      battleActions: {
        'challenge': true,
        'recruit': false,
        'trade': false,
      },
    );
    
    return jsonEncode(enemy.toJson());
  }

  String generateSampleQuestQR() {
    final quest = Quest(
      name: 'The Lost Temple',
      description: 'Explore an ancient temple hidden in the mountains',
      story: 'Local legends speak of a temple filled with untold riches...',
      type: QuestType.exploration,
      difficulty: QuestDifficulty.hard,
      location: QuestLocation(
        name: 'Mountain Temple',
        description: 'Ancient ruins on the mountain peak',
        latitude: 40.7128,
        longitude: -74.0060,
      ),
      objectives: [
        QuestObjective(
          description: 'Reach the temple location',
          type: 'location',
          targetValue: 1,
        ),
        QuestObjective(
          description: 'Solve the ancient puzzle',
          type: 'puzzle',
          targetValue: 3,
        ),
      ],
      experienceReward: 1000,
      goldReward: 500,
    );
    
    return jsonEncode(quest.toJson());
  }
}

class QRResultDialog extends StatelessWidget {
  final QRScanResult result;
  
  const QRResultDialog({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_getDialogTitle()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardDisplay(),
            const SizedBox(height: 16),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  String _getDialogTitle() {
    switch (result.type) {
      case QRCardType.item:
        return 'Item Found!';
      case QRCardType.enemy:
        return 'Enemy Encounter!';
      case QRCardType.quest:
        return 'Quest Available!';
      case QRCardType.skill:
        return 'Skill Discovered!';
      case QRCardType.spell:
        return 'Spell Found!';
      case QRCardType.attribute:
        return 'Attribute Boost!';
      default:
        return 'QR Code Scanned';
    }
  }

  Widget _buildCardDisplay() {
    switch (result.type) {
      case QRCardType.item:
        return _buildItemDisplay(result.data as GameCard);
      case QRCardType.enemy:
        return _buildEnemyDisplay(result.data as EnemyCard);
      case QRCardType.quest:
        return _buildQuestDisplay(result.data as Quest);
      case QRCardType.skill:
        return _buildSkillDisplay(result.data as GameCard);
      case QRCardType.spell:
        return _buildSpellDisplay(result.data as GameCard);
      case QRCardType.attribute:
        return _buildAttributeDisplay(result.data as Map<String, dynamic>);
      default:
        return Text('Unknown card type: ${result.rawData}');
    }
  }

  Widget _buildItemDisplay(GameCard card) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          card.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(card.description),
        const SizedBox(height: 8),
        Text('Type: ${card.type.name}'),
        Text('Rarity: ${card.rarity.name}'),
        if (card.statModifiers.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Stats:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...card.statModifiers.map((stat) => Text(
            '${stat.statName}: ${stat.isPercentage ? '${stat.value}%' : '+${stat.value}'}',
          )),
        ],
      ],
    );
  }

  Widget _buildEnemyDisplay(EnemyCard enemy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          enemy.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(enemy.description),
        const SizedBox(height: 8),
        Text('Health: ${enemy.health}'),
        Text('Attack: ${enemy.attackPower}'),
        Text('Defense: ${enemy.defense}'),
        if (enemy.abilities.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Abilities:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...enemy.abilities.map((ability) => Text('• $ability')),
        ],
      ],
    );
  }

  Widget _buildQuestDisplay(Quest quest) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          quest.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(quest.description),
        const SizedBox(height: 8),
        Text('Type: ${quest.type.name}'),
        Text('Difficulty: ${quest.difficulty.name}'),
        Text('Experience: ${quest.experienceReward}'),
        Text('Gold: ${quest.goldReward}'),
        if (quest.objectives.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Objectives:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...quest.objectives.map((obj) => Text('• ${obj.description}')),
        ],
      ],
    );
  }

  Widget _buildSkillDisplay(GameCard skill) {
    return _buildItemDisplay(skill);
  }

  Widget _buildSpellDisplay(GameCard spell) {
    return _buildItemDisplay(spell);
  }

  Widget _buildAttributeDisplay(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data['name'] ?? 'Attribute Boost',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(data['description'] ?? 'Boost your character attributes'),
        const SizedBox(height: 8),
        if (data['bonus_type'] == 'flat')
          Text('${data['stat_name']}: +${data['bonus_value']}'),
        if (data['bonus_type'] == 'choice')
          Text('Choose any attribute: +${data['bonus_value']} points'),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: result.availableActions.map((action) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _handleAction(context, action),
              child: Text(action),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _handleAction(BuildContext context, String action) {
    Navigator.of(context).pop();
    
    switch (action) {
      case 'Equip':
        _handleEquipAction(context);
        break;
      case 'Add to Inventory':
        _handleAddToInventoryAction(context);
        break;
      case 'Challenge to Battle':
        _handleChallengeAction(context);
        break;
      case 'Start Quest':
        _handleStartQuestAction(context);
        break;
      case 'Show on Map':
        _handleShowOnMapAction(context);
        break;
      case 'Learn Skill':
        _handleLearnSkillAction(context);
        break;
      case 'Apply Bonus':
        _handleApplyBonusAction(context);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action "$action" not implemented yet')),
        );
    }
  }

  void _handleEquipAction(BuildContext context) {
    // TODO: Implement equip logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item equipped successfully!')),
    );
  }

  void _handleAddToInventoryAction(BuildContext context) {
    // TODO: Implement add to inventory logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item added to inventory!')),
    );
  }

  void _handleChallengeAction(BuildContext context) {
    // TODO: Implement battle challenge logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Battle challenge initiated!')),
    );
  }

  void _handleStartQuestAction(BuildContext context) {
    // TODO: Implement quest start logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quest started!')),
    );
  }

  void _handleShowOnMapAction(BuildContext context) {
    // TODO: Implement show on map logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Showing quest location on map!')),
    );
  }

  void _handleLearnSkillAction(BuildContext context) {
    // TODO: Implement learn skill logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Skill learned!')),
    );
  }

  void _handleApplyBonusAction(BuildContext context) {
    // TODO: Implement apply bonus logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attribute bonus applied!')),
    );
  }
}