import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../models/card_model.dart';
import '../services/audio_service.dart';
import '../services/qr_scanner_service.dart';
import 'qr_scanner_widget.dart';

class DamageCalculatorWidget extends StatefulWidget {
  const DamageCalculatorWidget({super.key});

  @override
  State<DamageCalculatorWidget> createState() => _DamageCalculatorWidgetState();
}

class _DamageCalculatorWidgetState extends State<DamageCalculatorWidget> {
  final TextEditingController _baseDamageController = TextEditingController();
  final TextEditingController _cardBonusController = TextEditingController();
  final TextEditingController _skillBonusController = TextEditingController();
  final TextEditingController _enemyDefenseController = TextEditingController();
  final TextEditingController _diceRollController = TextEditingController();

  bool _showBreakdown = false;
  bool _isPhysicalGame = false;
  String _calculationMode = 'attack';
  List<String> _calculationSteps = [];
  double? _finalResult;
  GameCard? _scannedCard;

  @override
  void dispose() {
    _baseDamageController.dispose();
    _cardBonusController.dispose();
    _skillBonusController.dispose();
    _enemyDefenseController.dispose();
    _diceRollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RealmOfValorTheme.surfaceDark,
      appBar: AppBar(
        title: const Text('Damage Calculator'),
        backgroundColor: RealmOfValorTheme.surfaceDark,
        foregroundColor: RealmOfValorTheme.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildGameModeToggle(),
            const SizedBox(height: 16),
            _buildModeSelection(),
            const SizedBox(height: 16),
            _buildQRScannerSection(),
            const SizedBox(height: 16),
            _buildInputFields(),
            const SizedBox(height: 16),
            _buildCalculateButton(),
            const SizedBox(height: 16),
            if (_finalResult != null) _buildResults(),
            const SizedBox(height: 16),
            if (_showBreakdown) _buildBreakdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            RealmOfValorTheme.surfaceMedium,
            RealmOfValorTheme.surfaceDark,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RealmOfValorTheme.accentGold, width: 2),
      ),
      child: Column(
        children: [
          Icon(
            Icons.calculate,
            color: RealmOfValorTheme.accentGold,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            'Damage Calculator',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Calculate damage and defense for physical card games',
            style: TextStyle(
              fontSize: 16,
              color: RealmOfValorTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGameModeToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RealmOfValorTheme.accentGold, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Game Mode',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isPhysicalGame = false;
                    });
                    AudioService.instance.playSound(AudioType.buttonClick);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_isPhysicalGame
                          ? RealmOfValorTheme.accentGold
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: RealmOfValorTheme.accentGold,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'In-Game',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: !_isPhysicalGame
                            ? Colors.white
                            : RealmOfValorTheme.textSecondary,
                        fontWeight: !_isPhysicalGame
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isPhysicalGame = true;
                    });
                    AudioService.instance.playSound(AudioType.buttonClick);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _isPhysicalGame
                          ? RealmOfValorTheme.accentGold
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: RealmOfValorTheme.accentGold,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Physical Cards',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _isPhysicalGame
                            ? Colors.white
                            : RealmOfValorTheme.textSecondary,
                        fontWeight: _isPhysicalGame
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RealmOfValorTheme.accentGold, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calculation Mode',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _calculationMode = 'attack';
                    });
                    AudioService.instance.playSound(AudioType.buttonClick);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _calculationMode == 'attack'
                          ? RealmOfValorTheme.accentGold
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Attack',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _calculationMode == 'attack'
                            ? Colors.white
                            : Colors.grey[300],
                        fontWeight: _calculationMode == 'attack'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _calculationMode = 'defend';
                    });
                    AudioService.instance.playSound(AudioType.buttonClick);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _calculationMode == 'defend'
                          ? RealmOfValorTheme.accentGold
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Defend',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _calculationMode == 'defend'
                            ? Colors.white
                            : Colors.grey[300],
                        fontWeight: _calculationMode == 'defend'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQRScannerSection() {
    if (!_isPhysicalGame) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RealmOfValorTheme.accentGold, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.qr_code_scanner,
                color: RealmOfValorTheme.accentGold,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'QR Code Scanner',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: RealmOfValorTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_scannedCard != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RealmOfValorTheme.surfaceDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: RealmOfValorTheme.accentGold, width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.style,
                    color: RealmOfValorTheme.accentGold,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _scannedCard!.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: RealmOfValorTheme.textPrimary,
                          ),
                        ),
                        Text(
                          _scannedCard!.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: RealmOfValorTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _scannedCard = null;
                      });
                      AudioService.instance.playSound(AudioType.buttonClick);
                    },
                    icon: Icon(
                      Icons.close,
                      color: RealmOfValorTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openQRScanner,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(_scannedCard != null ? 'Scan Another Card' : 'Scan Card'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RealmOfValorTheme.accentGold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RealmOfValorTheme.accentGold, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Input Values',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _baseDamageController,
            label: _calculationMode == 'attack' ? 'Base Attack' : 'Base Defense',
            hint: 'Enter base value',
            icon: Icons.flash_on,
          ),
          const SizedBox(height: 12),
          _buildInputField(
            controller: _cardBonusController,
            label: 'Card Bonus',
            hint: 'Enter card bonus',
            icon: Icons.style,
          ),
          const SizedBox(height: 12),
          _buildInputField(
            controller: _skillBonusController,
            label: 'Skill Bonus',
            hint: 'Enter skill bonus',
            icon: Icons.psychology,
          ),
          const SizedBox(height: 12),
          _buildInputField(
            controller: _enemyDefenseController,
            label: _calculationMode == 'attack' ? 'Enemy Defense' : 'Enemy Attack',
            hint: 'Enter enemy value',
            icon: Icons.shield,
          ),
          const SizedBox(height: 12),
          _buildInputField(
            controller: _diceRollController,
            label: 'Dice Roll',
            hint: 'Enter dice roll modifier',
            icon: Icons.casino,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: RealmOfValorTheme.accentGold,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: RealmOfValorTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(
            color: RealmOfValorTheme.textPrimary,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: RealmOfValorTheme.textSecondary,
            ),
            filled: true,
            fillColor: RealmOfValorTheme.surfaceDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: RealmOfValorTheme.accentGold,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: RealmOfValorTheme.accentGold.withOpacity(0.5),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: RealmOfValorTheme.accentGold,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalculateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _calculateDamage,
        icon: const Icon(Icons.calculate),
        label: const Text('Calculate'),
        style: ElevatedButton.styleFrom(
          backgroundColor: RealmOfValorTheme.accentGold,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RealmOfValorTheme.accentGold, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: RealmOfValorTheme.accentGold,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Final Result',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: RealmOfValorTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: RealmOfValorTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: RealmOfValorTheme.accentGold, width: 2),
            ),
            child: Column(
              children: [
                Text(
                  _finalResult!.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: RealmOfValorTheme.accentGold,
                  ),
                ),
                Text(
                  _calculationMode == 'attack' ? 'Total Damage' : 'Total Defense',
                  style: TextStyle(
                    fontSize: 16,
                    color: RealmOfValorTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showBreakdown = !_showBreakdown;
                    });
                    AudioService.instance.playSound(AudioType.buttonClick);
                  },
                  icon: Icon(
                    _showBreakdown ? Icons.expand_less : Icons.expand_more,
                    color: RealmOfValorTheme.accentGold,
                  ),
                  label: Text(
                    _showBreakdown ? 'Hide Breakdown' : 'Show Breakdown',
                    style: TextStyle(
                      color: RealmOfValorTheme.accentGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RealmOfValorTheme.accentGold, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calculation Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ..._calculationSteps.map((step) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.arrow_right,
                  color: RealmOfValorTheme.accentGold,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    step,
                    style: TextStyle(
                      fontSize: 14,
                      color: RealmOfValorTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  void _openQRScanner() {
    AudioService.instance.playSound(AudioType.buttonClick);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const QRScannerWidget(),
      ),
    );
  }

  void _calculateDamage() {
    AudioService.instance.playSound(AudioType.buttonClick);
    
    final baseDamage = double.tryParse(_baseDamageController.text) ?? 0;
    final cardBonus = double.tryParse(_cardBonusController.text) ?? 0;
    final skillBonus = double.tryParse(_skillBonusController.text) ?? 0;
    final enemyDefense = double.tryParse(_enemyDefenseController.text) ?? 0;
    final diceRoll = double.tryParse(_diceRollController.text) ?? 0;

    _calculationSteps.clear();

    // Add scanned card bonus if available
    double scannedCardBonus = 0;
    if (_scannedCard != null) {
      scannedCardBonus = _calculationMode == 'attack' 
          ? _scannedCard!.attack.toDouble()
          : _scannedCard!.defense.toDouble();
      _calculationSteps.add('Scanned card bonus: +$scannedCardBonus');
    }

    // Calculate total
    double total = baseDamage + cardBonus + skillBonus + scannedCardBonus + diceRoll;
    _calculationSteps.add('Base value: $baseDamage');
    _calculationSteps.add('Card bonus: +$cardBonus');
    _calculationSteps.add('Skill bonus: +$skillBonus');
    _calculationSteps.add('Dice roll: +$diceRoll');
    _calculationSteps.add('Subtotal: $total');

    // Apply enemy defense/attack
    if (_calculationMode == 'attack') {
      total -= enemyDefense;
      _calculationSteps.add('Enemy defense: -$enemyDefense');
    } else {
      total -= enemyDefense;
      _calculationSteps.add('Enemy attack: -$enemyDefense');
    }

    // Ensure minimum value
    total = total.clamp(0, double.infinity);
    _calculationSteps.add('Final result: $total');

    setState(() {
      _finalResult = total;
      _showBreakdown = true;
    });
  }
} 