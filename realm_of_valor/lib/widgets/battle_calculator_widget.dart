import 'package:flutter/material.dart';
import '../models/battle_model.dart';
import '../models/character_model.dart';
import '../models/card_model.dart';
import '../providers/battle_controller.dart';
import '../constants/theme.dart';

class BattleCalculatorWidget extends StatefulWidget {
  final BattleController controller;
  final BattlePlayer currentPlayer;

  const BattleCalculatorWidget({
    super.key,
    required this.controller,
    required this.currentPlayer,
  });

  @override
  State<BattleCalculatorWidget> createState() => _BattleCalculatorWidgetState();
}

class _BattleCalculatorWidgetState extends State<BattleCalculatorWidget> {
  final TextEditingController _baseDamageController = TextEditingController();
  final TextEditingController _baseDefenseController = TextEditingController();
  final TextEditingController _skillDamageController = TextEditingController();
  final TextEditingController _spellDamageController = TextEditingController();
  
  bool _showCalculator = false;
  String _calculationResult = '';

  @override
  void dispose() {
    _baseDamageController.dispose();
    _baseDefenseController.dispose();
    _skillDamageController.dispose();
    _spellDamageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Column(
        children: [
          // Calculator Toggle Button
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _showCalculator = !_showCalculator;
              });
            },
            backgroundColor: RealmOfValorTheme.accentGold,
            child: Icon(
              _showCalculator ? Icons.close : Icons.calculate,
              color: Colors.white,
            ),
          ),
          
          // Calculator Panel
          if (_showCalculator)
            Container(
              width: 300,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: RealmOfValorTheme.surfaceDark.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: RealmOfValorTheme.accentGold, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: RealmOfValorTheme.accentGold.withOpacity(0.2),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calculate,
                          color: RealmOfValorTheme.accentGold,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Battle Calculator',
                          style: TextStyle(
                            color: RealmOfValorTheme.accentGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Calculator Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPlayerStats(),
                        const SizedBox(height: 16),
                        _buildInputFields(),
                        const SizedBox(height: 16),
                        _buildCalculationButtons(),
                        const SizedBox(height: 16),
                        _buildResultDisplay(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerStats() {
    final character = widget.currentPlayer.character;
    final equipment = character.equipment.getAllEquippedItems();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RealmOfValorTheme.accentGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Player Stats',
            style: TextStyle(
              color: RealmOfValorTheme.accentGold,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Attack', character.attack.toString()),
              ),
              Expanded(
                child: _buildStatItem('Defense', character.defense.toString()),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Strength', character.totalStrength.toString()),
              ),
              Expanded(
                child: _buildStatItem('Dexterity', character.totalDexterity.toString()),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Vitality', character.totalVitality.toString()),
              ),
              Expanded(
                child: _buildStatItem('Energy', character.totalEnergy.toString()),
              ),
            ],
          ),
          if (equipment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Equipment Bonuses',
              style: TextStyle(
                color: RealmOfValorTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            ...equipment.map((item) => Text(
              '• ${item.card.name}: +${item.card.attack} ATK, +${item.card.defense} DEF',
              style: TextStyle(
                color: RealmOfValorTheme.textSecondary,
                fontSize: 10,
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: RealmOfValorTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: RealmOfValorTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Input Values',
          style: TextStyle(
            color: RealmOfValorTheme.accentGold,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        _buildInputField('Base Damage', _baseDamageController, '0'),
        const SizedBox(height: 8),
        _buildInputField('Base Defense', _baseDefenseController, '0'),
        const SizedBox(height: 8),
        _buildInputField('Skill Damage', _skillDamageController, '0'),
        const SizedBox(height: 8),
        _buildInputField('Spell Damage', _spellDamageController, '0'),
      ],
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, String placeholder) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              color: RealmOfValorTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            style: TextStyle(
              color: RealmOfValorTheme.textPrimary,
              fontSize: 12,
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(
                color: RealmOfValorTheme.textSecondary,
                fontSize: 12,
              ),
              filled: true,
              fillColor: RealmOfValorTheme.surfaceDark.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: RealmOfValorTheme.accentGold.withOpacity(0.3)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  Widget _buildCalculationButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _calculateAttack,
            style: ElevatedButton.styleFrom(
              backgroundColor: RealmOfValorTheme.accentGold,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            child: const Text('Calculate Attack', style: TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: _calculateDefense,
            style: ElevatedButton.styleFrom(
              backgroundColor: RealmOfValorTheme.accentGold,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            child: const Text('Calculate Defense', style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildResultDisplay() {
    if (_calculationResult.isEmpty) {
      return const SizedBox();
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RealmOfValorTheme.accentGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calculation Result',
            style: TextStyle(
              color: RealmOfValorTheme.accentGold,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _calculationResult,
            style: TextStyle(
              color: RealmOfValorTheme.textPrimary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _calculateAttack() {
    final character = widget.currentPlayer.character;
    final baseDamage = int.tryParse(_baseDamageController.text) ?? 0;
    final skillDamage = int.tryParse(_skillDamageController.text) ?? 0;
    final spellDamage = int.tryParse(_spellDamageController.text) ?? 0;
    
    // Calculate total attack
    int totalAttack = character.attack + baseDamage + skillDamage + spellDamage;
    
    // Add equipment bonuses
    for (var item in character.equipment.getAllEquippedItems()) {
      totalAttack += item.card.attack;
    }
    
    // Add status effect bonuses
    final statusEffects = widget.currentPlayer.statusEffects;
    if (statusEffects['attack_bonus'] != null) {
      totalAttack += (statusEffects['attack_bonus'] as num).toInt();
    }
    
    setState(() {
      _calculationResult = '''
Attack Calculation:
• Base Character Attack: ${character.attack}
• Input Base Damage: $baseDamage
• Skill Damage: $skillDamage
• Spell Damage: $spellDamage
• Equipment Bonuses: ${character.equipment.getAllEquippedItems().fold(0, (sum, item) => sum + item.card.attack)}
• Status Effects: ${statusEffects['attack_bonus'] ?? 0}
• Total Attack: $totalAttack
''';
    });
  }

  void _calculateDefense() {
    final character = widget.currentPlayer.character;
    final baseDefense = int.tryParse(_baseDefenseController.text) ?? 0;
    
    // Calculate total defense
    int totalDefense = character.defense + baseDefense;
    
    // Add equipment bonuses
    for (var item in character.equipment.getAllEquippedItems()) {
      totalDefense += item.card.defense;
    }
    
    // Add status effect bonuses
    final statusEffects = widget.currentPlayer.statusEffects;
    if (statusEffects['defense_bonus'] != null) {
      totalDefense += (statusEffects['defense_bonus'] as num).toInt();
    }
    
    setState(() {
      _calculationResult = '''
Defense Calculation:
• Base Character Defense: ${character.defense}
• Input Base Defense: $baseDefense
• Equipment Bonuses: ${character.equipment.getAllEquippedItems().fold(0, (sum, item) => sum + item.card.defense)}
• Status Effects: ${statusEffects['defense_bonus'] ?? 0}
• Total Defense: $totalDefense
''';
    });
  }
} 