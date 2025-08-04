import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../services/advanced_battle_service.dart';
import '../services/ai_battle_service.dart';
import '../services/audio_service.dart';
import '../models/character_model.dart';

class AdvancedBattleScreen extends StatefulWidget {
  final AdvancedBattleService battleService;
  final AIBattleService aiBattleService;

  const AdvancedBattleScreen({
    super.key,
    required this.battleService,
    required this.aiBattleService,
  });

  @override
  State<AdvancedBattleScreen> createState() => _AdvancedBattleScreenState();
}

class _AdvancedBattleScreenState extends State<AdvancedBattleScreen>
    with TickerProviderStateMixin {
  late AnimationController _battleAnimationController;
  late AnimationController _damageAnimationController;
  late Animation<double> _damageAnimation;
  
  bool _isPlayerTurn = true;
  bool _isAITurn = false;
  String _battleLog = '';
  List<String> _battleHistory = [];

  @override
  void initState() {
    super.initState();
    _battleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _damageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _damageAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _damageAnimationController, curve: Curves.easeOut),
    );
    
    _startBattle();
  }

  @override
  void dispose() {
    _battleAnimationController.dispose();
    _damageAnimationController.dispose();
    super.dispose();
  }

  void _startBattle() {
    _addBattleLog('⚔️ Battle has begun!', 'System');
    _checkBattleStatus();
  }

  void _addBattleLog(String message, String source) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final logEntry = '[$timestamp] $source: $message';
    setState(() {
      _battleHistory.add(logEntry);
      _battleLog = _battleHistory.join('\n');
    });
  }

  void _checkBattleStatus() {
    final battle = widget.battleService;
    
    if (battle.isBattleOver) {
      _endBattle();
      return;
    }

    final currentPlayer = battle.currentPlayer;
    if (currentPlayer != null) {
      setState(() {
        _isPlayerTurn = currentPlayer.isPlayer;
        _isAITurn = !currentPlayer.isPlayer;
      });

      if (_isAITurn) {
        _handleAITurn();
      }
    }
  }

  void _handleAITurn() async {
    _addBattleLog('🤖 AI is thinking...', 'System');
    
    await Future.delayed(const Duration(seconds: 1));
    
    final currentPlayer = widget.battleService.currentPlayer;
    if (currentPlayer != null) {
      final availableCombos = widget.battleService.getAvailableCombosForCurrentPlayer();
      
      if (availableCombos.isNotEmpty) {
        final selectedCombo = availableCombos.first;
        _executeCombo(selectedCombo, currentPlayer);
      } else {
        _addBattleLog('🤖 AI passes turn', 'System');
        _endTurn();
      }
    }
  }

  void _executeCombo(ComboMove combo, BattleParticipant attacker) {
    final targets = widget.battleService.getValidTargets(combo);
    
    if (targets.isNotEmpty) {
      final target = targets.first;
      _addBattleLog('${attacker.name} uses ${combo.name}!', 'Battle');
      
      // Execute the combo using the service
      widget.battleService.executeCombo(combo.id, target.id);
      
      // Show damage animation
      _showDamageAnimation(combo.damage, target);
      
      // Apply status effects
      for (final effect in combo.effects) {
        _addBattleLog('${target.name} is affected by ${effect.description}', 'Battle');
      }
      
      _addBattleLog('${target.name} takes ${combo.damage} damage!', 'Battle');
      
      // Check if target is defeated
      final updatedTarget = widget.battleService.participants.firstWhere((p) => p.id == target.id);
      if (!updatedTarget.isAlive) {
        _addBattleLog('💀 ${target.name} has been defeated!', 'System');
      }
      
      _checkBattleStatus();
    }
  }

  int _calculateDamage(ComboMove combo, BattleParticipant attacker, BattleParticipant target) {
    final baseDamage = combo.damage;
    final attackerStrength = attacker.maxHealth / 10; // Simplified strength calculation
    final targetDefense = target.maxHealth / 15; // Simplified defense calculation
    
    final damage = (baseDamage + attackerStrength - targetDefense).clamp(1, double.infinity).toInt();
    return damage;
  }

  void _showDamageAnimation(int damage, BattleParticipant target) {
    _damageAnimationController.forward().then((_) {
      _damageAnimationController.reverse();
    });
  }

  void _endTurn() {
    widget.battleService.endTurn();
    _checkBattleStatus();
  }

  void _endBattle() {
    final winner = widget.battleService.aliveParticipants.firstOrNull;
    if (winner != null) {
      _addBattleLog('🏆 ${winner.name} wins the battle!', 'System');
    } else {
      _addBattleLog('🤝 Battle ended in a draw!', 'System');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RealmOfValorTheme.surfaceDark,
      appBar: AppBar(
        title: const Text('Advanced Battle'),
        backgroundColor: RealmOfValorTheme.surfaceDark,
        foregroundColor: RealmOfValorTheme.textPrimary,
        actions: [
          IconButton(
            onPressed: _endTurn,
            icon: const Icon(Icons.skip_next),
            tooltip: 'End Turn',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildBattleStatus(),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildBattleField(),
                ),
                Expanded(
                  flex: 1,
                  child: _buildBattlePanel(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBattleStatus() {
    final battle = widget.battleService;
    final currentPlayer = battle.currentPlayer;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        border: Border(
          bottom: BorderSide(color: RealmOfValorTheme.accentGold.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Turn ${battle.turnNumber}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: RealmOfValorTheme.accentGold,
                  ),
                ),
                Text(
                  'Current Player: ${currentPlayer?.name ?? 'None'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: RealmOfValorTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isPlayerTurn ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _isPlayerTurn ? 'Your Turn' : 'AI Turn',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBattleField() {
    final battle = widget.battleService;
    final participants = battle.participants;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Player side
          Expanded(
            child: _buildParticipantSection(
              participants.where((p) => p.isPlayer).toList(),
              'Your Team',
              Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          // Enemy side
          Expanded(
            child: _buildParticipantSection(
              participants.where((p) => !p.isPlayer).toList(),
              'Enemy Team',
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantSection(List<BattleParticipant> participants, String title, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: participants.length,
              itemBuilder: (context, index) {
                final participant = participants[index];
                return _buildParticipantCard(participant, color);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantCard(BattleParticipant participant, Color color) {
    final isCurrentPlayer = widget.battleService.currentPlayer?.id == participant.id;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentPlayer 
            ? color.withOpacity(0.2) 
            : RealmOfValorTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrentPlayer ? color : color.withOpacity(0.3),
          width: isCurrentPlayer ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color,
            child: Text(
              participant.name.substring(0, 1),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: RealmOfValorTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: participant.healthPercentage,
                  backgroundColor: RealmOfValorTheme.surfaceDark,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                const SizedBox(height: 2),
                Text(
                  'HP: ${participant.currentHealth}/${participant.maxHealth}',
                  style: TextStyle(
                    fontSize: 12,
                    color: RealmOfValorTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (participant.isStunned)
            Icon(
              Icons.block,
              color: Colors.orange,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildBattlePanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        border: Border(
          left: BorderSide(color: RealmOfValorTheme.accentGold.withOpacity(0.3)),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Battle Log',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RealmOfValorTheme.surfaceDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: RealmOfValorTheme.accentGold.withOpacity(0.3)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _battleLog,
                  style: TextStyle(
                    fontSize: 12,
                    color: RealmOfValorTheme.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_isPlayerTurn) _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final availableCombos = widget.battleService.getAvailableCombosForCurrentPlayer();
    
    return Column(
      children: [
        Text(
          'Available Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: RealmOfValorTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...availableCombos.map((combo) => _buildActionButton(combo)),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _endTurn,
          style: ElevatedButton.styleFrom(
            backgroundColor: RealmOfValorTheme.accentGold,
            foregroundColor: Colors.white,
          ),
          child: const Text('End Turn'),
        ),
      ],
    );
  }

  Widget _buildActionButton(ComboMove combo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: () {
          final currentPlayer = widget.battleService.currentPlayer;
          if (currentPlayer != null) {
            _executeCombo(combo, currentPlayer);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: RealmOfValorTheme.surfaceDark,
          foregroundColor: RealmOfValorTheme.accentGold,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Column(
          children: [
            Text(
              combo.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${combo.damage} DMG • ${combo.manaCost} MP',
              style: TextStyle(
                fontSize: 12,
                color: RealmOfValorTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 