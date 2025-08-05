import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import '../models/battle_system.dart';
import '../services/comprehensive_battle_engine.dart';
import '../widgets/battle_card_widget.dart';
import '../widgets/battlefield_widget.dart';
import '../widgets/player_stats_widget.dart';
import '../widgets/turn_timer_widget.dart';
import '../widgets/battle_log_widget.dart';
import '../constants/theme.dart';

class ComprehensiveBattleScreen extends StatefulWidget {
  final BattleState battle;
  final String playerId;

  const ComprehensiveBattleScreen({
    Key? key,
    required this.battle,
    required this.playerId,
  }) : super(key: key);

  @override
  State<ComprehensiveBattleScreen> createState() => _ComprehensiveBattleScreenState();
}

class _ComprehensiveBattleScreenState extends State<ComprehensiveBattleScreen>
    with TickerProviderStateMixin {
  late AnimationController _cardDrawController;
  late AnimationController _turnTransitionController;
  late AnimationController _battleEffectsController;
  
  BattleCard? _selectedCard;
  dynamic _selectedTarget;
  bool _showBattleLog = false;
  bool _showDeckView = false;
  
  // Enhanced UI controllers
  late PageController _handPageController;
  late ScrollController _logScrollController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeControllers();
    _listenToBattleUpdates();
  }

  void _initializeAnimations() {
    _cardDrawController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _turnTransitionController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _battleEffectsController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  void _initializeControllers() {
    _handPageController = PageController();
    _logScrollController = ScrollController();
  }

  void _listenToBattleUpdates() {
    context.read<ComprehensiveBattleEngine>().addListener(() {
      if (mounted) {
        setState(() {});
        _handleBattleStateChanges();
      }
    });
  }

  void _handleBattleStateChanges() {
    final battleEngine = context.read<ComprehensiveBattleEngine>();
    final currentBattle = battleEngine.currentBattle;
    
    if (currentBattle != null && currentBattle.id == widget.battle.id) {
      // Animate turn transitions
      if (currentBattle.activePlayerId != widget.playerId) {
        _turnTransitionController.forward().then((_) {
          _turnTransitionController.reverse();
        });
      }
      
      // Auto-scroll battle log
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ComprehensiveBattleEngine>(
      builder: (context, battleEngine, child) {
        final battle = battleEngine.currentBattle ?? widget.battle;
        final player = _getPlayer(battle);
        final opponent = _getOpponent(battle);
        
        if (player == null || opponent == null) {
          return _buildBattleNotFoundScreen();
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              _buildBattleBackground(),
              _buildMainBattleView(battle, player, opponent),
              if (_selectedCard != null) _buildTargetingOverlay(battle, player, opponent),
              _buildTurnTransitionOverlay(battle),
              _buildBattleEndOverlay(battle),
            ],
          ),
        );
      },
    );
  }

  // Build battle background with dynamic effects
  Widget _buildBattleBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.purple.shade900.withOpacity(0.8),
            Colors.blue.shade900.withOpacity(0.6),
            Colors.black.withOpacity(0.9),
          ],
        ),
      ),
      child: AnimatedBuilder(
        animation: _battleEffectsController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3 * _battleEffectsController.value),
                  blurRadius: 20,
                  spreadRadius: 10,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Build main battle view
  Widget _buildMainBattleView(BattleState battle, BattlePlayer player, BattlePlayer opponent) {
    return Column(
      children: [
        // Opponent area
        Expanded(
          flex: 2,
          child: _buildOpponentArea(battle, opponent),
        ),
        
        // Battlefield
        Expanded(
          flex: 3,
          child: _buildBattlefield(battle, player, opponent),
        ),
        
        // Player area
        Expanded(
          flex: 3,
          child: _buildPlayerArea(battle, player),
        ),
      ],
    );
  }

  // Build opponent area
  Widget _buildOpponentArea(BattleState battle, BattlePlayer opponent) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Opponent portrait and stats
          Expanded(
            flex: 2,
            child: PlayerStatsWidget(
              player: opponent,
              isOpponent: true,
              showDetailedStats: false,
            ),
          ),
          
          // Opponent hand (face down cards)
          Expanded(
            flex: 3,
            child: _buildOpponentHand(opponent),
          ),
          
          // Battle controls
          Expanded(
            flex: 1,
            child: _buildBattleControls(battle),
          ),
        ],
      ),
    );
  }

  // Build opponent hand (face down cards)
  Widget _buildOpponentHand(BattlePlayer opponent) {
    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: opponent.handSize,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            child: _buildCardBack(),
          );
        },
      ),
    );
  }

  // Build card back
  Widget _buildCardBack() {
    return Container(
      width: 60,
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.purple.shade800],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.auto_awesome,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  // Build battlefield
  Widget _buildBattlefield(BattleState battle, BattlePlayer player, BattlePlayer opponent) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Opponent battlefield
          Expanded(
            child: BattlefieldWidget(
              creatures: opponent.battlefield,
              isPlayerSide: false,
              onCreatureSelected: _selectedCard != null ? _onTargetSelected : null,
            ),
          ),
          
          // Center divider with battle info
          Container(
            height: 60,
            child: _buildBattleInfo(battle),
          ),
          
          // Player battlefield
          Expanded(
            child: BattlefieldWidget(
              creatures: player.battlefield,
              isPlayerSide: true,
              onCreatureSelected: _selectedCard != null ? _onTargetSelected : null,
            ),
          ),
        ],
      ),
    );
  }

  // Build battle info center area
  Widget _buildBattleInfo(BattleState battle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade600, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTurnIndicator(battle),
          _buildPhaseIndicator(battle),
          _buildTurnTimer(),
          _buildBattleLogButton(),
        ],
      ),
    );
  }

  // Build turn indicator
  Widget _buildTurnIndicator(BattleState battle) {
    final isPlayerTurn = battle.activePlayerId == widget.playerId;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPlayerTurn ? Colors.green.shade600 : Colors.red.shade600,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        isPlayerTurn ? 'YOUR TURN' : 'OPPONENT TURN',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // Build phase indicator
  Widget _buildPhaseIndicator(BattleState battle) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Turn ${battle.turnNumber}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        Text(
          battle.turnPhase.name.toUpperCase(),
          style: TextStyle(color: Colors.grey.shade300, fontSize: 10),
        ),
      ],
    );
  }

  // Build turn timer
  Widget _buildTurnTimer() {
    return TurnTimerWidget(
      duration: const Duration(seconds: 90),
      onTimeOut: () => _endTurn(),
    );
  }

  // Build battle log button
  Widget _buildBattleLogButton() {
    return IconButton(
      onPressed: () => setState(() => _showBattleLog = !_showBattleLog),
      icon: Icon(
        _showBattleLog ? Icons.close : Icons.history,
        color: Colors.white,
      ),
    );
  }

  // Build player area
  Widget _buildPlayerArea(BattleState battle, BattlePlayer player) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Player stats and info
          Expanded(
            flex: 1,
            child: _buildPlayerInfo(player),
          ),
          
          // Player hand
          Expanded(
            flex: 2,
            child: _buildPlayerHand(battle, player),
          ),
        ],
      ),
    );
  }

  // Build player info
  Widget _buildPlayerInfo(BattlePlayer player) {
    return Row(
      children: [
        // Player portrait and stats
        Expanded(
          flex: 2,
          child: PlayerStatsWidget(
            player: player,
            isOpponent: false,
            showDetailedStats: true,
          ),
        ),
        
        // Deck and graveyard info
        Expanded(
          flex: 1,
          child: _buildDeckInfo(player),
        ),
        
        // Action buttons
        Expanded(
          flex: 1,
          child: _buildActionButtons(),
        ),
      ],
    );
  }

  // Build deck info
  Widget _buildDeckInfo(BattlePlayer player) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildDeckButton(player),
        _buildGraveyardButton(player),
      ],
    );
  }

  // Build deck button
  Widget _buildDeckButton(BattlePlayer player) {
    return GestureDetector(
      onTap: () => setState(() => _showDeckView = !_showDeckView),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.shade800,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade400),
        ),
        child: Column(
          children: [
            const Icon(Icons.style, color: Colors.white),
            Text(
              'Deck: ${player.deckSize}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  // Build graveyard button
  Widget _buildGraveyardButton(BattlePlayer player) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade600),
      ),
      child: Column(
        children: [
          const Icon(Icons.delete, color: Colors.white),
          Text(
            'Grave: ${player.graveyard.length}',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // Build action buttons
  Widget _buildActionButtons() {
    return Column(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _canEndTurn() ? _endTurn : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('END TURN'),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _showBattleOptions(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('OPTIONS'),
          ),
        ),
      ],
    );
  }

  // Build player hand
  Widget _buildPlayerHand(BattleState battle, BattlePlayer player) {
    return Container(
      height: 140,
      child: PageView.builder(
        controller: _handPageController,
        itemCount: (player.hand.length / 5).ceil(),
        itemBuilder: (context, pageIndex) {
          final startIndex = pageIndex * 5;
          final endIndex = math.min(startIndex + 5, player.hand.length);
          final pageCards = player.hand.sublist(startIndex, endIndex);
          
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: pageCards.map((card) => _buildHandCard(battle, player, card)).toList(),
          );
        },
      ),
    );
  }

  // Build hand card
  Widget _buildHandCard(BattleState battle, BattlePlayer player, BattleCard card) {
    final canPlay = card.canBePlayedBy(player.stats, player.characterClass, player.currentMana);
    final isSelected = _selectedCard?.id == card.id;
    
    return GestureDetector(
      onTap: () => _onCardSelected(card, canPlay),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()
          ..translate(0.0, isSelected ? -20.0 : 0.0),
        child: BattleCardWidget(
          card: card,
          canPlay: canPlay,
          isSelected: isSelected,
          showTooltip: true,
          size: CardSize.hand,
        ),
      ),
    );
  }

  // Build battle controls
  Widget _buildBattleControls(BattleState battle) {
    return Column(
      children: [
        IconButton(
          onPressed: () => _showBattleMenu(),
          icon: const Icon(Icons.menu, color: Colors.white),
        ),
        IconButton(
          onPressed: () => _toggleFullscreen(),
          icon: const Icon(Icons.fullscreen, color: Colors.white),
        ),
        IconButton(
          onPressed: () => _showBattleHelp(),
          icon: const Icon(Icons.help, color: Colors.white),
        ),
      ],
    );
  }

  // Build targeting overlay
  Widget _buildTargetingOverlay(BattleState battle, BattlePlayer player, BattlePlayer opponent) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Select Target for ${_selectedCard!.name}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Target Type: ${_selectedCard!.targetType.name}',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => _cancelTargeting(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  // Build turn transition overlay
  Widget _buildTurnTransitionOverlay(BattleState battle) {
    return AnimatedBuilder(
      animation: _turnTransitionController,
      builder: (context, child) {
        if (_turnTransitionController.value == 0) return const SizedBox.shrink();
        
        return Container(
          color: Colors.black.withOpacity(0.8 * _turnTransitionController.value),
          child: Center(
            child: Transform.scale(
              scale: _turnTransitionController.value,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.purple.shade600,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  battle.activePlayerId == widget.playerId ? 'YOUR TURN' : 'OPPONENT\'S TURN',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Build battle end overlay
  Widget _buildBattleEndOverlay(BattleState battle) {
    if (!battle.isGameOver) return const SizedBox.shrink();
    
    final isWinner = battle.winnerId == widget.playerId;
    
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isWinner ? Colors.green.shade800 : Colors.red.shade800,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (isWinner ? Colors.green : Colors.red).withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isWinner ? Icons.emoji_events : Icons.close,
                size: 64,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                isWinner ? 'VICTORY!' : 'DEFEAT',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildBattleResults(battle),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _rematch(),
                    child: const Text('REMATCH'),
                  ),
                  ElevatedButton(
                    onPressed: () => _exitBattle(),
                    child: const Text('EXIT'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build battle results
  Widget _buildBattleResults(BattleState battle) {
    final rewards = battle.winnerId == widget.playerId 
        ? battle.rewards['winner'] as Map<String, dynamic>?
        : battle.rewards['loser'] as Map<String, dynamic>?;
    
    if (rewards == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'REWARDS',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Experience: ${rewards['experience']}',
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            'Gold: ${rewards['gold']}',
            style: const TextStyle(color: Colors.white),
          ),
          if (rewards['cards'] != null)
            Text(
              'Cards: ${(rewards['cards'] as List).length}',
              style: const TextStyle(color: Colors.white),
            ),
        ],
      ),
    );
  }

  // Build battle not found screen
  Widget _buildBattleNotFoundScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Battle Not Found',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  // Event handlers
  void _onCardSelected(BattleCard card, bool canPlay) {
    if (!canPlay) return;
    
    setState(() {
      _selectedCard = card;
    });
    
    // If card doesn't need target, play immediately
    if (card.targetType == TargetType.none) {
      _playCard(card, null);
    }
  }

  void _onTargetSelected(dynamic target) {
    if (_selectedCard == null) return;
    
    _playCard(_selectedCard!, target);
  }

  void _playCard(BattleCard card, dynamic target) {
    final battleEngine = context.read<ComprehensiveBattleEngine>();
    battleEngine.playCard(widget.battle.id, widget.playerId, card, target: target);
    
    setState(() {
      _selectedCard = null;
      _selectedTarget = null;
    });
    
    // Trigger card play animation
    _battleEffectsController.forward().then((_) {
      _battleEffectsController.reverse();
    });
  }

  void _cancelTargeting() {
    setState(() {
      _selectedCard = null;
      _selectedTarget = null;
    });
  }

  void _endTurn() {
    final battleEngine = context.read<ComprehensiveBattleEngine>();
    battleEngine.endTurn(widget.battle.id, widget.playerId);
  }

  bool _canEndTurn() {
    final battle = context.read<ComprehensiveBattleEngine>().currentBattle;
    return battle?.activePlayerId == widget.playerId;
  }

  void _rematch() {
    // Implement rematch logic
    Navigator.of(context).pop();
  }

  void _exitBattle() {
    Navigator.of(context).pop();
  }

  void _showBattleMenu() {
    showDialog(
      context: context,
      builder: (context) => _buildBattleMenuDialog(),
    );
  }

  void _showBattleOptions() {
    showDialog(
      context: context,
      builder: (context) => _buildBattleOptionsDialog(),
    );
  }

  void _showBattleHelp() {
    showDialog(
      context: context,
      builder: (context) => _buildBattleHelpDialog(),
    );
  }

  void _toggleFullscreen() {
    // Implement fullscreen toggle
  }

  // Build dialogs
  Widget _buildBattleMenuDialog() {
    return AlertDialog(
      title: const Text('Battle Menu'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.pause),
            title: const Text('Pause Battle'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Surrender'),
            onTap: () => _surrender(),
          ),
        ],
      ),
    );
  }

  Widget _buildBattleOptionsDialog() {
    return AlertDialog(
      title: const Text('Battle Options'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Show Tooltips'),
            value: true,
            onChanged: (value) {},
          ),
          SwitchListTile(
            title: const Text('Auto-End Turn'),
            value: false,
            onChanged: (value) {},
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildBattleHelpDialog() {
    return AlertDialog(
      title: const Text('Battle Help'),
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('HOW TO PLAY:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• Tap cards in your hand to select them'),
            Text('• If targeting is required, tap your target'),
            Text('• Use mana to play cards'),
            Text('• End your turn when ready'),
            Text('• Reduce opponent health to 0 to win'),
            SizedBox(height: 16),
            Text('CARD TYPES:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• Creatures: Stay on battlefield'),
            Text('• Spells: Instant effects'),
            Text('• Enchantments: Ongoing effects'),
            Text('• Artifacts: Equipment effects'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it!'),
        ),
      ],
    );
  }

  void _surrender() {
    Navigator.pop(context); // Close dialog
    // Implement surrender logic
    _exitBattle();
  }

  // Utility methods
  BattlePlayer? _getPlayer(BattleState battle) {
    return battle.player1.id == widget.playerId ? battle.player1 : battle.player2;
  }

  BattlePlayer? _getOpponent(BattleState battle) {
    return battle.player1.id == widget.playerId ? battle.player2 : battle.player1;
  }

  @override
  void dispose() {
    _cardDrawController.dispose();
    _turnTransitionController.dispose();
    _battleEffectsController.dispose();
    _handPageController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }
}

// Enhanced card size enum
enum CardSize {
  hand,
  battlefield,
  preview,
  thumbnail,
}