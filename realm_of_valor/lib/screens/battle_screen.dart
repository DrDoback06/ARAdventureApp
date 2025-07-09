import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/battle_model.dart';
import '../models/card_model.dart';
import '../providers/battle_controller.dart';
import '../widgets/battle_card_widget.dart';
import '../widgets/player_portrait_widget.dart';
import '../widgets/battle_log_widget.dart';

class BattleScreen extends StatefulWidget {
  final Battle battle;

  const BattleScreen({
    Key? key,
    required this.battle,
  }) : super(key: key);

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen>
    with TickerProviderStateMixin {
  late AnimationController _cardAnimationController;
  late AnimationController _damageAnimationController;

  @override
  void initState() {
    super.initState();
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _damageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _damageAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => BattleController(widget.battle),
      child: Scaffold(
        backgroundColor: const Color(0xFF1a1a2e),
        body: Consumer<BattleController>(
          builder: (context, battleController, child) {
            return Stack(
              children: [
                // Background
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF16213e),
                        Color(0xFF0f3460),
                        Color(0xFF1a1a2e),
                      ],
                    ),
                  ),
                ),
                
                // Main Battle Layout
                Column(
                  children: [
                    // Top Status Bar
                    _buildTopStatusBar(battleController),
                    
                    // Battle Field
                    Expanded(
                      child: Row(
                        children: [
                          // Battle Log (Left Side)
                          SizedBox(
                            width: 300,
                            child: BattleLogWidget(
                              battleLog: battleController.battle.battleLog,
                            ),
                          ),
                          
                          // Main Battle Area
                          Expanded(
                            child: _buildBattleField(battleController),
                          ),
                          
                          // Inventory/Skills Panel (Right Side)
                          SizedBox(
                            width: 250,
                            child: _buildSidePanel(battleController),
                          ),
                        ],
                      ),
                    ),
                    
                    // Player Hand and Actions
                    _buildPlayerActions(battleController),
                  ],
                ),
                
                // Turn Phase Indicator
                if (battleController.showPhaseIndicator)
                  _buildPhaseIndicator(battleController),
                
                // Battle Result Dialog
                if (battleController.battle.status == BattleStatus.finished)
                  _buildBattleResultDialog(battleController),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopStatusBar(BattleController controller) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0f3460),
        border: Border(
          bottom: BorderSide(color: Color(0xFFe94560), width: 2),
        ),
      ),
      child: Row(
        children: [
          // Battle Name
          Text(
            controller.battle.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          
          // Turn Counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFe94560),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Turn ${controller.battle.currentTurn}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Settings/Menu Button
          IconButton(
            onPressed: () => _showBattleMenu(context, controller),
            icon: const Icon(Icons.menu, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBattleField(BattleController controller) {
    final players = controller.battle.players;
    final playerCount = players.length;
    
    // Dynamic layout based on player count
    if (playerCount <= 2) {
      return _buildTwoPlayerLayout(controller, players);
    } else if (playerCount <= 4) {
      return _buildFourPlayerLayout(controller, players);
    } else {
      return _buildSixPlayerLayout(controller, players);
    }
  }

  Widget _buildTwoPlayerLayout(BattleController controller, List<BattlePlayer> players) {
    return Column(
      children: [
        // Opponent
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (players.length > 1)
                  Expanded(
                    child: PlayerPortraitWidget(
                      player: players[1],
                      isActive: controller.battle.currentPlayerId == players[1].id,
                      isOpponent: true,
                      onTap: () => controller.selectTarget(players[1].id),
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        // Battle Center
        Container(
          height: 100,
          child: _buildBattleCenter(controller),
        ),
        
        // Current Player
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: PlayerPortraitWidget(
                    player: players[0],
                    isActive: controller.battle.currentPlayerId == players[0].id,
                    isOpponent: false,
                    onTap: () => controller.selectTarget(players[0].id),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFourPlayerLayout(BattleController controller, List<BattlePlayer> players) {
    return Column(
      children: [
        // Top Row (2 players)
        Expanded(
          child: Row(
            children: [
              if (players.length > 1)
                Expanded(
                  child: PlayerPortraitWidget(
                    player: players[1],
                    isActive: controller.battle.currentPlayerId == players[1].id,
                    isOpponent: true,
                    onTap: () => controller.selectTarget(players[1].id),
                  ),
                ),
              if (players.length > 2)
                Expanded(
                  child: PlayerPortraitWidget(
                    player: players[2],
                    isActive: controller.battle.currentPlayerId == players[2].id,
                    isOpponent: true,
                    onTap: () => controller.selectTarget(players[2].id),
                  ),
                ),
            ],
          ),
        ),
        
        // Battle Center
        Container(
          height: 80,
          child: _buildBattleCenter(controller),
        ),
        
        // Bottom Row (2 players)
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: PlayerPortraitWidget(
                  player: players[0],
                  isActive: controller.battle.currentPlayerId == players[0].id,
                  isOpponent: false,
                  onTap: () => controller.selectTarget(players[0].id),
                ),
              ),
              if (players.length > 3)
                Expanded(
                  child: PlayerPortraitWidget(
                    player: players[3],
                    isActive: controller.battle.currentPlayerId == players[3].id,
                    isOpponent: false,
                    onTap: () => controller.selectTarget(players[3].id),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSixPlayerLayout(BattleController controller, List<BattlePlayer> players) {
    return Column(
      children: [
        // Top Row (3 players)
        Expanded(
          child: Row(
            children: [
              for (int i = 1; i < 4 && i < players.length)
                Expanded(
                  child: PlayerPortraitWidget(
                    player: players[i],
                    isActive: controller.battle.currentPlayerId == players[i].id,
                    isOpponent: true,
                    onTap: () => controller.selectTarget(players[i].id),
                  ),
                ),
            ],
          ),
        ),
        
        // Battle Center
        Container(
          height: 60,
          child: _buildBattleCenter(controller),
        ),
        
        // Bottom Row (3 players)
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: PlayerPortraitWidget(
                  player: players[0],
                  isActive: controller.battle.currentPlayerId == players[0].id,
                  isOpponent: false,
                  onTap: () => controller.selectTarget(players[0].id),
                ),
              ),
              for (int i = 4; i < 6 && i < players.length)
                Expanded(
                  child: PlayerPortraitWidget(
                    player: players[i],
                    isActive: controller.battle.currentPlayerId == players[i].id,
                    isOpponent: false,
                    onTap: () => controller.selectTarget(players[i].id),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBattleCenter(BattleController controller) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFe94560), width: 2),
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFF16213e).withOpacity(0.5),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (controller.selectedCard != null) ...[
              const Icon(
                Icons.flash_on,
                color: Color(0xFFe94560),
                size: 24,
              ),
              Text(
                'Card Selected',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ] else ...[
              Text(
                controller.currentPhase.name.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFFe94560),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSidePanel(BattleController controller) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0f3460),
        border: Border(
          left: BorderSide(color: Color(0xFFe94560), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Panel Header
          Container(
            height: 50,
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFe94560), width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: controller.showInventory ? null : () => controller.toggleInventory(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: controller.showInventory 
                          ? const Color(0xFFe94560) 
                          : const Color(0xFF16213e),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Inventory', style: TextStyle(fontSize: 10)),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: ElevatedButton(
                    onPressed: controller.showSkills ? null : () => controller.toggleSkills(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: controller.showSkills 
                          ? const Color(0xFFe94560) 
                          : const Color(0xFF16213e),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Skills', style: TextStyle(fontSize: 10)),
                  ),
                ),
              ],
            ),
          ),
          
          // Panel Content
          Expanded(
            child: controller.showInventory
                ? _buildInventoryPanel(controller)
                : _buildSkillsPanel(controller),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryPanel(BattleController controller) {
    final currentPlayer = controller.getCurrentPlayer();
    if (currentPlayer == null) return const SizedBox();

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        const Text(
          'Equipped Items',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // Show equipped items (read-only for now)
        ...currentPlayer.character.equippedItems.map((item) => 
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF16213e),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFe94560).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ATK: ${item.attack} DEF: ${item.defense}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ).toList(),
      ],
    );
  }

  Widget _buildSkillsPanel(BattleController controller) {
    final currentPlayer = controller.getCurrentPlayer();
    if (currentPlayer == null) return const SizedBox();

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        const Text(
          'Available Skills',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // Show available skills
        ...currentPlayer.activeSkills.map((skill) => 
          GestureDetector(
            onTap: () => controller.useSkill(skill),
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF16213e),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: controller.canUseSkill(skill) 
                      ? const Color(0xFFe94560) 
                      : const Color(0xFFe94560).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skill.name,
                    style: TextStyle(
                      color: controller.canUseSkill(skill) 
                          ? Colors.white 
                          : Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Cost: ${skill.cost} MP',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    skill.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 9,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ).toList(),
      ],
    );
  }

  Widget _buildPlayerActions(BattleController controller) {
    return Container(
      height: 180,
      decoration: const BoxDecoration(
        color: Color(0xFF0f3460),
        border: Border(
          top: BorderSide(color: Color(0xFFe94560), width: 2),
        ),
      ),
      child: Column(
        children: [
          // Action Buttons
          Container(
            height: 50,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                _buildActionButton(
                  'Attack',
                  Icons.sword,
                  controller.canAttack(),
                  () => controller.performAttack(),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  'End Turn',
                  Icons.skip_next,
                  controller.canEndTurn(),
                  () => controller.endTurn(),
                ),
                const SizedBox(width: 16),
                
                // Mana Display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213e),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.water_drop, color: Colors.blue, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${controller.getCurrentPlayer()?.currentMana ?? 0}/${controller.getCurrentPlayer()?.maxMana ?? 0}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Hand Cards
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              child: _buildHandCards(controller),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, bool enabled, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? const Color(0xFFe94560) : const Color(0xFF16213e),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildHandCards(BattleController controller) {
    final currentPlayer = controller.getCurrentPlayer();
    if (currentPlayer == null || currentPlayer.hand.isEmpty) {
      return const Center(
        child: Text(
          'No cards in hand',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: currentPlayer.hand.length,
      itemBuilder: (context, index) {
        final card = currentPlayer.hand[index];
        final canPlay = controller.canPlayCard(card);
        
        return Container(
          width: 100,
          margin: const EdgeInsets.only(right: 8),
          child: BattleCardWidget(
            card: card,
            canPlay: canPlay,
            isSelected: controller.selectedCard == card,
            onTap: () => controller.selectCard(card),
            onPlay: () => controller.playCard(card),
          ),
        );
      },
    );
  }

  Widget _buildPhaseIndicator(BattleController controller) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFe94560),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Text(
          '${controller.currentPhase.name.toUpperCase()} PHASE',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBattleResultDialog(BattleController controller) {
    final winner = controller.battle.winnerId != null
        ? controller.battle.players.firstWhere((p) => p.id == controller.battle.winnerId)
        : null;

    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0f3460),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFe94560), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events,
                color: Color(0xFFe94560),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                winner != null ? '${winner.name} Wins!' : 'Battle Ended',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFe94560),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text(
                  'Return to Map',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBattleMenu(BuildContext context, BattleController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0f3460),
        title: const Text('Battle Menu', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.pause, color: Colors.white),
              title: const Text('Pause Battle', style: TextStyle(color: Colors.white)),
              onTap: () {
                controller.pauseBattle();
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.white),
              title: const Text('Forfeit Battle', style: TextStyle(color: Colors.white)),
              onTap: () {
                controller.forfeitBattle();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}