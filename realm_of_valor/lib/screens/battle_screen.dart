import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/battle_model.dart';
import '../models/card_model.dart';
import '../providers/battle_controller.dart';
import '../widgets/battle_card_widget.dart';
import '../widgets/player_portrait_widget.dart';
import '../widgets/battle_log_widget.dart';
import '../widgets/spell_counter_widget.dart';
import '../widgets/spell_animation_widget.dart';
import '../widgets/status_effect_overlay.dart';
import '../widgets/drag_arrow_widget.dart';
import '../widgets/simple_test_widget.dart';
import '../effects/particle_system.dart';

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
                
                // EPIC PARTICLE SYSTEM LAYER! ⚡🔥✨
                const IgnorePointer(
                  child: BattleParticleSystem(),
                ),
                
                // FORCE LOAD - Particle Test (will be visible when new code loads)
                Positioned(
                  top: 100,
                  left: 100,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('NEW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                
                // Card Draw Popup
                if (battleController.showCardDrawPopup)
                  _buildCardDrawPopup(battleController),
                
                // Battle Result Dialog
                if (battleController.battle.status == BattleStatus.finished)
                  _buildBattleResultDialog(battleController),
                
                // Real-Time Spell Counter Overlay - THE EPIC FINALE! ⚡
                if (battleController.waitingForCounters)
                  Builder(
                    builder: (context) {
                      final currentPlayer = battleController.getCurrentPlayer();
                      if (currentPlayer == null) return const SizedBox();
                      
                      // Find counter spells in hand
                      final availableCounters = currentPlayer.hand.where((card) => 
                        card.type == ActionCardType.counter).toList();
                      
                      return SpellCounterWidget(
                        spellCounterSystem: battleController.spellCounterSystem,
                        currentPlayer: currentPlayer,
                        onCounterAttempt: (counterSpell) {
                          final success = battleController.attemptSpellCounter(counterSpell);
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('⚡ ${counterSpell.name} cast as counter!'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                
                // Spell Casting Animation Overlay - THE EPIC MAGIC SYSTEM! ✨⚡
                SpellAnimationWidget(
                  battleController: battleController,
                ),
                
                // Status Effect Overlays for All Players - DRAMATIC PARTICLE EFFECTS! 🌟⚡
                ...battleController.battle.players.map((player) {
                  final statusEffects = _convertPlayerStatusEffects(player);
                  if (statusEffects.isEmpty) return const SizedBox.shrink();
                  
                  return Positioned(
                    left: _getPlayerPosition(player.id, context).dx - 100,
                    top: _getPlayerPosition(player.id, context).dy - 100,
                    child: IgnorePointer(
                      child: StatusEffectOverlay(
                        statusEffects: statusEffects,
                        size: 200.0,
                      ),
                    ),
                  );
                }).toList(),
                
                // EPIC DRAG ARROW SYSTEM! 🏹⚡
                if (battleController.isDragging)
                  IgnorePointer(
                    child: DragArrowWidget(
                      startPosition: battleController.dragStartPosition,
                      currentPosition: battleController.dragCurrentPosition,
                      draggedCard: battleController.draggedCard,
                      draggedAction: battleController.draggedAction,
                      hoveredTargetId: battleController.hoveredTargetId,
                      isValidTarget: battleController.hoveredTargetId != null &&
                          battleController.isValidDragTarget(battleController.hoveredTargetId!),
                    ),
                  ),
                
                // DEBUG: Test if enhanced features are loading
                const Positioned(
                  top: 50,
                  right: 50,
                  child: SimpleTestWidget(),
                ),
                
                // DEBUG: Force drag test button
                Positioned(
                  top: 200,
                  right: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      // Force trigger drag state for testing
                      battleController.startAttackDrag(const Offset(100, 100));
                      battleController.setHoveredTarget(battleController.battle.players.length > 1 
                          ? battleController.battle.players[1].id 
                          : battleController.battle.players[0].id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('TEST DRAG'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Generate drag properties for PlayerPortraitWidget
  Map<String, dynamic> _getDragPropertiesForPlayer(BattleController controller, String playerId) {
    return {
      'isValidDragTarget': controller.isValidDragTarget(playerId),
      'isHovered': controller.hoveredTargetId == playerId,
      'draggedCard': controller.draggedCard,
      'draggedAction': controller.draggedAction,
      'onDragEnter': (String targetId) => controller.setHoveredTarget(targetId),
      'onDragLeave': (String targetId) => controller.setHoveredTarget(null),
    };
  }

  /// Convert player status effects to enhanced status effects for particle system
  List<StatusEffect> _convertPlayerStatusEffects(BattlePlayer player) {
    final effects = <StatusEffect>[];
    
    for (final entry in player.statusEffects.entries) {
      final effectName = entry.key.toLowerCase();
      final duration = entry.value;
      
      switch (effectName) {
        case 'burn':
        case 'burning':
          effects.add(StatusEffect.burning(duration: duration));
          break;
        case 'freeze':
        case 'frozen':
          effects.add(StatusEffect.frozen(duration: duration));
          break;
        case 'shock':
        case 'shocked':
          effects.add(StatusEffect.shocked(duration: duration));
          break;
        case 'strength':
        case 'strengthened':
          effects.add(StatusEffect.strengthened(duration: duration));
          break;
        case 'shield':
        case 'shielded':
          effects.add(StatusEffect.shielded(duration: duration));
          break;
        case 'regenerating':
        case 'heal':
          effects.add(StatusEffect.regenerating(duration: duration));
          break;
        case 'weakened':
        case 'weak':
          effects.add(StatusEffect.weakened(duration: duration));
          break;
        case 'silenced':
        case 'silence':
          effects.add(StatusEffect.silenced(duration: duration));
          break;
        case 'blessed':
        case 'blessing':
          effects.add(StatusEffect.blessed(duration: duration));
          break;
        default:
          // Create a generic effect for unknown status effects
          effects.add(StatusEffect(
            type: StatusEffectType.blessed,
            duration: duration,
            intensity: 1.0,
          ));
          break;
      }
    }
    
    return effects;
  }

  /// Get approximate player position for animations
  Offset _getPlayerPosition(String playerId, BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    // Find player index
    final playerIndex = widget.battle.players.indexWhere((p) => p.id == playerId);
    if (playerIndex == -1) {
      return Offset(screenSize.width * 0.5, screenSize.height * 0.5); // Center fallback
    }
    
    final playerCount = widget.battle.players.length;
    
    if (playerCount <= 2) {
      // Two player layout
      if (playerIndex == 0) {
        return Offset(screenSize.width * 0.5, screenSize.height * 0.75); // Bottom player
      } else {
        return Offset(screenSize.width * 0.5, screenSize.height * 0.25); // Top player
      }
    } else if (playerCount <= 4) {
      // Four player layout
      switch (playerIndex) {
        case 0:
          return Offset(screenSize.width * 0.25, screenSize.height * 0.75); // Bottom left
        case 1:
          return Offset(screenSize.width * 0.25, screenSize.height * 0.25); // Top left
        case 2:
          return Offset(screenSize.width * 0.75, screenSize.height * 0.25); // Top right
        case 3:
          return Offset(screenSize.width * 0.75, screenSize.height * 0.75); // Bottom right
        default:
          return Offset(screenSize.width * 0.5, screenSize.height * 0.5);
      }
    } else {
      // Six player layout
      switch (playerIndex) {
        case 0:
          return Offset(screenSize.width * 0.2, screenSize.height * 0.75); // Bottom left
        case 1:
          return Offset(screenSize.width * 0.2, screenSize.height * 0.25); // Top left
        case 2:
          return Offset(screenSize.width * 0.5, screenSize.height * 0.25); // Top center
        case 3:
          return Offset(screenSize.width * 0.8, screenSize.height * 0.25); // Top right
        case 4:
          return Offset(screenSize.width * 0.5, screenSize.height * 0.75); // Bottom center
        case 5:
          return Offset(screenSize.width * 0.8, screenSize.height * 0.75); // Bottom right
        default:
          return Offset(screenSize.width * 0.5, screenSize.height * 0.5);
      }
    }
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
                      onCardDropped: (card, targetId) => controller.playCardOnTarget(card, targetId),
                      onAttackDropped: (targetId) => _performDragAttack(controller, targetId),
                      isValidDragTarget: controller.isValidDragTarget(players[1].id),
                      isHovered: controller.hoveredTargetId == players[1].id,
                      draggedCard: controller.draggedCard,
                      draggedAction: controller.draggedAction,
                      onDragEnter: (targetId) => controller.setHoveredTarget(targetId),
                      onDragLeave: (targetId) => controller.setHoveredTarget(null),
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
                    onCardDropped: (card, targetId) => controller.playCardOnTarget(card, targetId),
                    onAttackDropped: (targetId) => _performDragAttack(controller, targetId),
                    isValidDragTarget: controller.isValidDragTarget(players[0].id),
                    isHovered: controller.hoveredTargetId == players[0].id,
                    draggedCard: controller.draggedCard,
                    draggedAction: controller.draggedAction,
                    onDragEnter: (targetId) => controller.setHoveredTarget(targetId),
                    onDragLeave: (targetId) => controller.setHoveredTarget(null),
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
                    onCardDropped: (card, targetId) => controller.playCardOnTarget(card, targetId),
                    onAttackDropped: (targetId) => _performDragAttack(controller, targetId),
                    isValidDragTarget: controller.isValidDragTarget(players[1].id),
                    isHovered: controller.hoveredTargetId == players[1].id,
                    draggedCard: controller.draggedCard,
                    draggedAction: controller.draggedAction,
                    onDragEnter: (targetId) => controller.setHoveredTarget(targetId),
                    onDragLeave: (targetId) => controller.setHoveredTarget(null),
                  ),
                ),
              if (players.length > 2)
                Expanded(
                  child: PlayerPortraitWidget(
                    player: players[2],
                    isActive: controller.battle.currentPlayerId == players[2].id,
                    isOpponent: true,
                    onTap: () => controller.selectTarget(players[2].id),
                    onCardDropped: (card, targetId) => controller.playCardOnTarget(card, targetId),
                    onAttackDropped: (targetId) => _performDragAttack(controller, targetId),
                    isValidDragTarget: controller.isValidDragTarget(players[2].id),
                    isHovered: controller.hoveredTargetId == players[2].id,
                    draggedCard: controller.draggedCard,
                    draggedAction: controller.draggedAction,
                    onDragEnter: (targetId) => controller.setHoveredTarget(targetId),
                    onDragLeave: (targetId) => controller.setHoveredTarget(null),
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
                  onCardDropped: (card, targetId) => controller.playCardOnTarget(card, targetId),
                  onAttackDropped: (targetId) => _performDragAttack(controller, targetId),
                  isValidDragTarget: controller.isValidDragTarget(players[0].id),
                  isHovered: controller.hoveredTargetId == players[0].id,
                  draggedCard: controller.draggedCard,
                  draggedAction: controller.draggedAction,
                  onDragEnter: (targetId) => controller.setHoveredTarget(targetId),
                  onDragLeave: (targetId) => controller.setHoveredTarget(null),
                ),
              ),
              if (players.length > 3)
                Expanded(
                  child: PlayerPortraitWidget(
                    player: players[3],
                    isActive: controller.battle.currentPlayerId == players[3].id,
                    isOpponent: false,
                    onTap: () => controller.selectTarget(players[3].id),
                    onCardDropped: (card, targetId) => controller.playCardOnTarget(card, targetId),
                    onAttackDropped: (targetId) => _performDragAttack(controller, targetId),
                    isValidDragTarget: controller.isValidDragTarget(players[3].id),
                    isHovered: controller.hoveredTargetId == players[3].id,
                    draggedCard: controller.draggedCard,
                    draggedAction: controller.draggedAction,
                    onDragEnter: (targetId) => controller.setHoveredTarget(targetId),
                    onDragLeave: (targetId) => controller.setHoveredTarget(null),
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
                    onCardDropped: (card, targetId) => controller.playCardOnTarget(card, targetId),
                    onAttackDropped: (targetId) => _performDragAttack(controller, targetId),
                    isValidDragTarget: controller.isValidDragTarget(players[i].id),
                    isHovered: controller.hoveredTargetId == players[i].id,
                    draggedCard: controller.draggedCard,
                    draggedAction: controller.draggedAction,
                    onDragEnter: (targetId) => controller.setHoveredTarget(targetId),
                    onDragLeave: (targetId) => controller.setHoveredTarget(null),
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
                  onCardDropped: (card, targetId) => controller.playCardOnTarget(card, targetId),
                  onAttackDropped: (targetId) => _performDragAttack(controller, targetId),
                  isValidDragTarget: controller.isValidDragTarget(players[0].id),
                  isHovered: controller.hoveredTargetId == players[0].id,
                  draggedCard: controller.draggedCard,
                  draggedAction: controller.draggedAction,
                  onDragEnter: (targetId) => controller.setHoveredTarget(targetId),
                  onDragLeave: (targetId) => controller.setHoveredTarget(null),
                ),
              ),
              for (int i = 4; i < 6 && i < players.length)
                Expanded(
                  child: PlayerPortraitWidget(
                    player: players[i],
                    isActive: controller.battle.currentPlayerId == players[i].id,
                    isOpponent: false,
                    onTap: () => controller.selectTarget(players[i].id),
                    onCardDropped: (card, targetId) => controller.playCardOnTarget(card, targetId),
                    onAttackDropped: (targetId) => _performDragAttack(controller, targetId),
                    isValidDragTarget: controller.isValidDragTarget(players[i].id),
                    isHovered: controller.hoveredTargetId == players[i].id,
                    draggedCard: controller.draggedCard,
                    draggedAction: controller.draggedAction,
                    onDragEnter: (targetId) => controller.setHoveredTarget(targetId),
                    onDragLeave: (targetId) => controller.setHoveredTarget(null),
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
                controller.canAttack()
                    ? Listener(
                        onPointerDown: (event) {
                          controller.startAttackDrag(event.position);
                        },
                        onPointerMove: (event) {
                          controller.updateDragPosition(event.position);
                        },
                        onPointerUp: (event) {
                          controller.endDrag();
                        },
                        child: Draggable<String>(
                          data: 'ATTACK',
                          feedback: Material(
                            color: Colors.transparent,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFe94560),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.flash_on, color: Colors.white, size: 20),
                                  SizedBox(width: 4),
                                  Text(
                                    'ATTACK',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.5,
                            child: _buildActionButton(
                              'Attack',
                              Icons.flash_on,
                              false,
                              () {},
                            ),
                          ),
                          child: _buildActionButton(
                            'Attack',
                            Icons.flash_on,
                            controller.canAttack(),
                            () => controller.performAttack(),
                          ),
                        ),
                      )
                    : _buildActionButton(
                        'Attack',
                        Icons.flash_on,
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
          child: canPlay 
              ? Listener(
                  onPointerDown: (event) {
                    controller.startCardDrag(card, event.position);
                  },
                  onPointerMove: (event) {
                    controller.updateDragPosition(event.position);
                  },
                  onPointerUp: (event) {
                    controller.endDrag();
                  },
                  child: Draggable<ActionCard>(
                    data: card,
                    feedback: Material(
                      color: Colors.transparent,
                      child: Transform.scale(
                        scale: 1.2,
                        child: Container(
                          width: 100,
                          child: BattleCardWidget(
                            card: card,
                            canPlay: true,
                            isSelected: true,
                            onTap: () {},
                            onPlay: () {},
                          ),
                        ),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.5,
                      child: BattleCardWidget(
                        card: card,
                        canPlay: false,
                        isSelected: false,
                        onTap: () {},
                        onPlay: () {},
                      ),
                    ),
                    child: BattleCardWidget(
                      card: card,
                      canPlay: canPlay,
                      isSelected: controller.selectedCard == card,
                      onTap: () => controller.selectCard(card),
                      onPlay: () => controller.playCard(card),
                    ),
                  ),
                )
              : BattleCardWidget(
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

  Widget _buildCardDrawPopup(BattleController controller) {
    final drawnCard = controller.drawnCard;
    if (drawnCard == null) return const SizedBox();

    final currentPlayer = controller.getCurrentPlayer();
    final canAddToHand = currentPlayer != null && currentPlayer.hand.length < 10;

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
              const Text(
                'Card Drawn!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Card Display
              Container(
                width: 200,
                height: 280,
                child: BattleCardWidget(
                  card: drawnCard,
                  canPlay: true,
                  isSelected: false,
                  onTap: () {},
                  onPlay: () {},
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Hand Status
              if (currentPlayer != null)
                Text(
                  'Hand: ${currentPlayer.hand.length}/10 cards',
                  style: TextStyle(
                    color: canAddToHand ? Colors.white : Colors.orange,
                    fontSize: 14,
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Discard Button
                  ElevatedButton.icon(
                    onPressed: () => controller.discardDrawnCard(),
                    icon: const Icon(Icons.delete),
                    label: const Text('Discard'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  
                  // Add to Hand Button
                  ElevatedButton.icon(
                    onPressed: canAddToHand 
                        ? () => controller.acceptDrawnCard()
                        : null,
                    icon: const Icon(Icons.add),
                    label: const Text('Add to Hand'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canAddToHand 
                          ? const Color(0xFFe94560) 
                          : Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              
              // Hand Full Warning
              if (!canAddToHand)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your hand is full! You must discard this card or discard another card from your hand.',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
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

  void _performDragAttack(BattleController controller, String targetId) {
    // ENHANCED: Direct drag attack without requiring target selection first
    final currentPlayer = controller.getCurrentPlayer();
    if (currentPlayer == null) return;
    
    // Automatically set target and perform attack
    controller.selectTarget(targetId);
    
    // Trigger spectacular attack animation with particles!
    controller.triggerTestParticleEffect(ParticleType.fire);
    
    // Perform the attack
    controller.performAttack();
    
    // Show attack feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚔️ ${currentPlayer.name} attacks!'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 1),
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