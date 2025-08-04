import 'package:flutter/material.dart';
import '../models/battle_model.dart';
import '../models/character_model.dart';
import '../models/card_model.dart';
import '../providers/enhanced_battle_controller.dart';
import '../constants/theme.dart';

class EnhancedBattleScreen extends StatefulWidget {
  final Battle battle;

  const EnhancedBattleScreen({
    super.key,
    required this.battle,
  });

  @override
  State<EnhancedBattleScreen> createState() => _EnhancedBattleScreenState();
}

class _EnhancedBattleScreenState extends State<EnhancedBattleScreen>
    with TickerProviderStateMixin {
  late EnhancedBattleController _controller;
  late TabController _tabController;
  int _activeHandIndex = 0;
  bool _showBattleLog = true; // Toggle for battle log visibility

  @override
  void initState() {
    super.initState();
    _controller = EnhancedBattleController(widget.battle);
    _tabController = TabController(length: 3, vsync: this);
    _controller.startTurn();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background
          _buildBackground(),
          
          // Main Battle UI
          Column(
            children: [
              // Header Bar with Timer
              _buildHeaderBar(),
              
              // Top Section - Enemy Player
              _buildEnemySection(),
              
              // Middle Section - Battle Field
              Expanded(
                child: _buildBattleField(),
              ),
              
              // Bottom Section - Player and Hands
              _buildPlayerSection(),
            ],
          ),
          
          // Spell Counter Overlay
          if (_controller.isSpellCounterActive)
            _buildSpellCounterOverlay(),
          
          // Battle Calculator
          if (_controller.showCalculator)
            _buildBattleCalculator(),
          
          // Floating Action Buttons
          _buildFloatingActions(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
                  colors: [
          Colors.black,
          Colors.grey[900]!,
        ],
        ),
      ),
    );
  }

  Widget _buildHeaderBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.9),
        border: Border(
          bottom: BorderSide(color: Colors.amber, width: 2),
        ),
      ),
      child: Row(
        children: [
          // Left side - Battle log toggle
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _showBattleLog = !_showBattleLog;
                  });
                },
                icon: Icon(
                  _showBattleLog ? Icons.chat_bubble : Icons.chat_bubble_outline,
                  color: Colors.amber,
                  size: 24,
                ),
                tooltip: 'Toggle Battle Log',
              ),
            ),
          ),
          
          // Center - Turn Timer
          Expanded(
            flex: 2,
            child: _buildTurnTimer(),
          ),
          
          // Right side - Phase indicator
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildPhaseIndicator(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnemySection() {
    final enemyPlayer = widget.battle.players.firstWhere(
      (p) => p.id != _controller.getCurrentPlayer()?.id,
    );

    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Enemy Portrait
          _buildPlayerPortrait(enemyPlayer, isEnemy: true),
          
          const SizedBox(width: 16),
          
          // Enemy Stats
          Expanded(
            child: _buildPlayerStats(enemyPlayer),
          ),
          
          // Turn Timer
          _buildTurnTimer(),
        ],
      ),
    );
  }

  Widget _buildBattleField() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: RealmOfValorTheme.accentGold.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Battle Phase Indicator
          _buildPhaseIndicator(),
          
          // Battle Log
          Expanded(
            child: _buildBattleLog(),
          ),
          
          // Spell Counter Timer
          if (_controller.isSpellCounterActive)
            _buildSpellCounterTimer(),
        ],
      ),
    );
  }

  Widget _buildPlayerSection() {
    final currentPlayer = _controller.getCurrentPlayer();
    if (currentPlayer == null) return const SizedBox();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Player Stats
          _buildPlayerStats(currentPlayer),
          
          const SizedBox(height: 16),
          
          // Three Hand System
          Expanded(
            child: _buildThreeHandSystem(currentPlayer),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerPortrait(BattlePlayer player, {bool isEnemy = false}) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isEnemy 
            ? Colors.red 
            : RealmOfValorTheme.accentGold,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: (isEnemy 
              ? Colors.red 
              : RealmOfValorTheme.accentGold).withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: Container(
          color: RealmOfValorTheme.surfaceDark,
          child: Icon(
            Icons.person,
            size: 40,
                      color: isEnemy 
            ? Colors.red 
            : RealmOfValorTheme.accentGold,
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerStats(BattlePlayer player) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          player.name,
          style: TextStyle(
            color: RealmOfValorTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Health Bar
            Expanded(
              child: _buildStatBar(
                'HP',
                player.currentHealth,
                player.maxHealth,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            // Mana Bar
            Expanded(
              child: _buildStatBar(
                'MP',
                player.currentMana,
                player.maxMana,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${player.currentHealth}/${player.maxHealth} HP | ${player.currentMana}/${player.maxMana} MP',
          style: TextStyle(
            color: RealmOfValorTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStatBar(String label, int current, int max, Color color) {
    final percentage = max > 0 ? current / max : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: RealmOfValorTheme.textSecondary,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: RealmOfValorTheme.surfaceDark,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTurnTimer() {
    final timeRemaining = _controller.turnTimeRemaining;
    final isUrgent = timeRemaining <= 10;
    final isCritical = timeRemaining <= 5;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800]!.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCritical ? Colors.red : isUrgent ? Colors.orange : Colors.amber,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isCritical ? Colors.red : isUrgent ? Colors.orange : Colors.amber).withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer,
                color: isCritical ? Colors.red : isUrgent ? Colors.orange : Colors.amber,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${timeRemaining}s',
                style: TextStyle(
                  color: isCritical ? Colors.red : isUrgent ? Colors.orange : Colors.amber,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'TURN TIMER',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Phase: ${_controller.currentPhase.name.toUpperCase()}',
        style: TextStyle(
          color: Colors.amber,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBattleLog() {
    if (!_showBattleLog) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800]!.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.chat_bubble, color: Colors.amber, size: 16),
              const SizedBox(width: 8),
              Text(
                'Battle Log',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 100,
            child: SingleChildScrollView(
              child: Text(
                _controller.battleLog,
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpellCounterTimer() {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Spell Counter: ${_controller.spellCounterTimeRemaining}s',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildThreeHandSystem(BattlePlayer player) {
    return Column(
      children: [
        // Hand Selector Tabs
        Container(
          decoration: BoxDecoration(
            color: RealmOfValorTheme.surfaceDark,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: RealmOfValorTheme.accentGold,
            unselectedLabelColor: RealmOfValorTheme.textSecondary,
            indicatorColor: RealmOfValorTheme.accentGold,
            tabs: const [
              Tab(text: 'Action Cards'),
              Tab(text: 'Skills'),
              Tab(text: 'Inventory'),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Hand Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildActionCardsHand(player),
              _buildSkillsHand(player),
              _buildInventoryHand(player),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionCardsHand(BattlePlayer player) {
    final actionCards = _controller.getActionHand(player.id);
    
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: actionCards.length,
      itemBuilder: (context, index) {
        final card = actionCards[index];
        return Container(
          width: 120,
          margin: const EdgeInsets.only(right: 8),
          child: _buildActionCard(card, player),
        );
      },
    );
  }

  Widget _buildSkillsHand(BattlePlayer player) {
    final skills = _controller.getSkillHand(player.id);
    
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: skills.length,
      itemBuilder: (context, index) {
        final skill = skills[index];
        return Container(
          width: 120,
          margin: const EdgeInsets.only(right: 8),
          child: _buildSkillCard(skill, player),
        );
      },
    );
  }

  Widget _buildInventoryHand(BattlePlayer player) {
    final inventory = _controller.getInventoryHand(player.id);
    
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: inventory.length,
      itemBuilder: (context, index) {
        final item = inventory[index];
        return Container(
          width: 120,
          margin: const EdgeInsets.only(right: 8),
          child: _buildInventoryCard(item, player),
        );
      },
    );
  }

  Widget _buildSkillCard(GameCard skill, BattlePlayer player) {
    return GestureDetector(
      onTap: () {
        if (_controller.canCastSpell(skill)) {
          // Show target selection
          _showTargetSelection(skill, player);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: RealmOfValorTheme.surfaceDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _controller.canCastSpell(skill) 
              ? RealmOfValorTheme.accentGold 
              : RealmOfValorTheme.textSecondary,
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: RealmOfValorTheme.accentGold.withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Icon(
                Icons.auto_awesome,
                color: RealmOfValorTheme.accentGold,
                size: 32,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(
                    skill.name,
                    style: TextStyle(
                      color: RealmOfValorTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cost: ${skill.cost ?? 0}',
                    style: TextStyle(
                      color: RealmOfValorTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(ActionCard card, BattlePlayer player) {
    return GestureDetector(
      onTap: () {
        if (_controller.canPlayCard(card)) {
          _controller.playActionCard(card, null);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: RealmOfValorTheme.surfaceDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _controller.canPlayCard(card) 
              ? RealmOfValorTheme.accentGold 
              : RealmOfValorTheme.textSecondary,
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: RealmOfValorTheme.accentGold.withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Icon(
                Icons.style,
                color: RealmOfValorTheme.accentGold,
                size: 32,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(
                    card.name,
                    style: TextStyle(
                      color: RealmOfValorTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card.type.name.toUpperCase(),
                    style: TextStyle(
                      color: RealmOfValorTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryCard(CardInstance item, BattlePlayer player) {
    return GestureDetector(
      onTap: () {
        // Use inventory item
        _controller.useItem(item);
      },
      child: Container(
        decoration: BoxDecoration(
          color: RealmOfValorTheme.surfaceDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: RealmOfValorTheme.accentGold.withOpacity(0.5),
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: RealmOfValorTheme.accentGold.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Icon(
                Icons.inventory,
                color: RealmOfValorTheme.accentGold,
                size: 32,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(
                    item.card.name,
                    style: TextStyle(
                      color: RealmOfValorTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Use Item',
                    style: TextStyle(
                      color: RealmOfValorTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpellCounterOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: RealmOfValorTheme.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red, width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SPELL COUNTER WINDOW',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${_controller.spellCaster?.name} cast ${_controller.lastCastedSpell?.name}',
                style: TextStyle(
                  color: RealmOfValorTheme.textPrimary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Time remaining: ${_controller.spellCounterTimeRemaining}s',
                style: TextStyle(
                  color: RealmOfValorTheme.accentGold,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Counter the spell
                      if (_controller.spellCaster != null && 
                          _controller.lastCastedSpell != null) {
                        // This would need to be implemented with actual counter spells
                        _controller.resolveSpell();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Counter'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Let the spell resolve
                      _controller.resolveSpell();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RealmOfValorTheme.accentGold,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Let Resolve'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBattleCalculator() {
    final currentPlayer = _controller.getCurrentPlayer();
    if (currentPlayer == null) return const SizedBox();

    // Create a simple calculator widget that works with our enhanced controller
    return Positioned(
      bottom: 16,
      right: 16,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900]!.withOpacity(0.95),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
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
                const Spacer(),
                IconButton(
                  onPressed: () => _controller.toggleCalculator(),
                  icon: Icon(Icons.close, color: RealmOfValorTheme.accentGold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Player: ${currentPlayer.name}',
              style: TextStyle(
                color: RealmOfValorTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Attack: ${currentPlayer.character.attack}',
              style: TextStyle(
                color: RealmOfValorTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            Text(
              'Defense: ${currentPlayer.character.defense}',
              style: TextStyle(
                color: RealmOfValorTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            Text(
              'Health: ${currentPlayer.currentHealth}/${currentPlayer.maxHealth}',
              style: TextStyle(
                color: RealmOfValorTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            Text(
              'Mana: ${currentPlayer.currentMana}/${currentPlayer.maxMana}',
              style: TextStyle(
                color: RealmOfValorTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActions() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Column(
        children: [
          // Calculator Toggle
          FloatingActionButton(
            heroTag: 'battle_calculator_button',
            onPressed: () => _controller.toggleCalculator(),
            backgroundColor: RealmOfValorTheme.accentGold,
            child: Icon(
              _controller.showCalculator ? Icons.close : Icons.calculate,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          // End Turn Button
          FloatingActionButton(
            heroTag: 'battle_end_turn_button',
            onPressed: () => _controller.endTurn(),
            backgroundColor: Colors.red,
            child: const Icon(
              Icons.skip_next,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showTargetSelection(GameCard skill, BattlePlayer caster) {
    final targets = widget.battle.players.where((p) => p.id != caster.id).toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Target for ${skill.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: targets.map((target) => ListTile(
            title: Text(target.name),
            subtitle: Text('HP: ${target.currentHealth}/${target.maxHealth}'),
            onTap: () {
              Navigator.of(context).pop();
              _controller.castSpell(skill, target);
            },
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
} 