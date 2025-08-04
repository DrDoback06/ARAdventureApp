import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/battle_controller.dart';
import '../providers/character_provider.dart';
import '../models/battle_model.dart';
import '../models/card_model.dart';
import '../widgets/player_portrait_widget.dart';
import '../widgets/battle_log_widget.dart';
import '../widgets/three_hand_system_widget.dart';
import '../widgets/enhanced_timer_widget.dart';
import '../widgets/battle_rewards_widget.dart';
import '../widgets/hearthstone_card_widget.dart';
import '../widgets/visual_effects_widget.dart';
import '../widgets/spell_counter_overlay_widget.dart';
import '../widgets/battle_calculator_widget.dart';
import '../services/battle_rewards_service.dart';
import '../constants/theme.dart';
import '../models/unified_particle_system.dart';
import '../effects/particle_system.dart';
import 'dart:math' as math;

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
                IgnorePointer(
                  child: ParticleSystem(
                    type: ParticleType.energy,
                    center: const Offset(400, 300),
                    intensity: 0.5,
                    continuous: true,
                  ),
                ),
                
                // Visual Effects Layer
                VisualEffectsWidget(
                  effects: battleController.visualEffects,
                  child: const SizedBox.expand(),
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
                
                // Enhanced Spell Counter Overlay with 8-second timer! ⚡
                SpellCounterOverlayWidget(
                  controller: battleController,
                ),
                
                // Enhanced Timer Widget - Top Center
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: EnhancedTimerWidget(
                      totalSeconds: 60,
                      remainingSeconds: battleController.turnTimeRemaining,
                      isActive: battleController.battle.currentPlayerId == battleController.getCurrentPlayer()?.id,
                      playerName: battleController.getCurrentPlayer()?.name,
                    ),
                  ),
                ),
                
                // Spell Casting Animation Overlay - THE EPIC MAGIC SYSTEM! ✨⚡
                // SpellAnimationWidget(
                //   battleController: battleController,
                // ),
                
                // Status Effect Overlays for All Players - DRAMATIC PARTICLE EFFECTS! 🌟⚡
                // ...battleController.battle.players.map((player) {
                //   final statusEffects = _convertPlayerStatusEffects(player);
                //   if (statusEffects.isEmpty) return const SizedBox.shrink();
                //   
                //   return Positioned(
                //     left: _getPlayerPosition(player.id, context).dx - 100,
                //     top: _getPlayerPosition(player.id, context).dy - 100,
                //     child: IgnorePointer(
                //       child: StatusEffectOverlay(
                //         statusEffects: statusEffects,
                //         size: 200.0,
                //       ),
                //     ),
                //   );
                // }).toList(),
                
                // EPIC DRAG ARROW SYSTEM! 🏹⚡
                // if (battleController.isDragging)
                //   IgnorePointer(
                //     child: DragArrowWidget(
                //       startPosition: battleController.dragStartPosition,
                //       currentPosition: battleController.dragCurrentPosition,
                //       draggedCard: battleController.draggedCard,
                //       draggedAction: battleController.draggedAction,
                //       hoveredTargetId: battleController.hoveredTargetId,
                //       isValidTarget: battleController.hoveredTargetId != null &&
                //           battleController.isValidDragTarget(battleController.hoveredTargetId!),
                //     ),
                //   ),
                
                // Battle Rewards Overlay
                if (battleController.battleCompleted && battleController.battleRewards != null)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.8),
                      child: Center(
                        child: BattleRewardsWidget(
                          rewards: battleController.battleRewards!,
                          performance: battleController.battlePerformance ?? BattlePerformance.average,
                          characterProvider: context.read<CharacterProvider>(),
                          onApplyRewards: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ),
                  ),
                
                // Battle Calculator Widget
                if (battleController.getCurrentPlayer() != null)
                  BattleCalculatorWidget(
                    controller: battleController,
                    currentPlayer: battleController.getCurrentPlayer()!,
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
  // Temporarily commented out to fix compilation issues
  // List<StatusEffect> _convertPlayerStatusEffects(BattlePlayer player) {
  //   final effects = <StatusEffect>[];
  //   
  //   for (final entry in player.statusEffects.entries) {
  //     final effectName = entry.key.toLowerCase();
  //     final duration = entry.value;
  //     
  //     switch (effectName) {
  //       case 'burn':
  //       case 'burning':
  //         effects.add(StatusEffect.burning(duration: duration));
  //         break;
  //       case 'freeze':
  //       case 'frozen':
  //         effects.add(StatusEffect.frozen(duration: duration));
  //         break;
  //       case 'shock':
  //       case 'shocked':
  //         effects.add(StatusEffect.shocked(duration: duration));
  //         break;
  //       case 'strength':
  //       case 'strengthened':
  //         effects.add(StatusEffect.strengthened(duration: duration));
  //         break;
  //       case 'shield':
  //       case 'shielded':
  //         effects.add(StatusEffect.shielded(duration: duration));
  //         break;
  //       case 'regenerating':
  //       case 'heal':
  //         effects.add(StatusEffect.regenerating(duration: duration));
  //         break;
  //       case 'weakened':
  //       case 'weak':
  //         effects.add(StatusEffect.weakened(duration: duration));
  //         break;
  //       case 'silenced':
  //       case 'silence':
  //         effects.add(StatusEffect.silenced(duration: duration));
  //         break;
  //       case 'blessed':
  //       case 'blessing':
  //         effects.add(StatusEffect.blessed(duration: duration));
  //         break;
  //       default:
  //         // Create a generic effect for unknown status effects
  //         effects.add(StatusEffect(
  //           type: StatusEffectType.blessed,
  //           duration: duration,
  //           intensity: 1.0,
  //         ));
  //         break;
  //     }
  //   }
  //   
  //   return effects;
  // }

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
                      onCardDropped: (card, targetId) => controller.playCardOnTarget(card, targetId),
                      onAttackDropped: (targetId) => _performDragAttack(controller, targetId),
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
                    onCardDropped: (card, targetId) => controller.playCardOnTarget(card, targetId),
                    onAttackDropped: (targetId) => _performDragAttack(controller, targetId),
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
                    onCardDropped: (card, targetId) => controller.playCardOnTarget(card, targetId),
                    onAttackDropped: (targetId) => _performDragAttack(controller, targetId),
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
                    
                    onCardDropped: (card, targetId) => controller.playCardOnTarget(card, targetId),
                    onAttackDropped: (targetId) => _performDragAttack(controller, targetId),
                    
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
                  
                  onCardDropped: (card, targetId) => controller.playCardOnTarget(card, targetId),
                  onAttackDropped: (targetId) => _performDragAttack(controller, targetId),
                  
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
                    
                    onCardDropped: (card, targetId) => controller.playCardOnTarget(card, targetId),
                    onAttackDropped: (targetId) => _performDragAttack(controller, targetId),
                    
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
              for (int i = 1; i < 4 && i < players.length; i++)
                Expanded(
                  child: PlayerPortraitWidget(
                    player: players[i],
                    isActive: controller.battle.currentPlayerId == players[i].id,
                    
                    onCardDropped: (card, targetId) => controller.playCardOnTarget(card, targetId),
                    onAttackDropped: (targetId) => _performDragAttack(controller, targetId),
                    
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
                  
                  onCardDropped: (card, targetId) => controller.playCardOnTarget(card, targetId),
                  onAttackDropped: (targetId) => _performDragAttack(controller, targetId),
                  
                  isHovered: controller.hoveredTargetId == players[0].id,
                  draggedCard: controller.draggedCard,
                  draggedAction: controller.draggedAction,
                  onDragEnter: (targetId) => controller.setHoveredTarget(targetId),
                  onDragLeave: (targetId) => controller.setHoveredTarget(null),
                ),
              ),
              for (int i = 4; i < 6 && i < players.length; i++)
                Expanded(
                  child: PlayerPortraitWidget(
                    player: players[i],
                    isActive: controller.battle.currentPlayerId == players[i].id,
                    
                    onCardDropped: (card, targetId) => controller.playCardOnTarget(card, targetId),
                    onAttackDropped: (targetId) => _performDragAttack(controller, targetId),
                    
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
        ...currentPlayer.character.equipment.getAllEquippedItems().map((item) => 
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
                  item.card.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ATK: ${item.card.attack} DEF: ${item.card.defense}',
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
        // Show available skills as draggable cards
        ...currentPlayer.activeSkills.map((skill) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Draggable<ActionCard>(
              data: ActionCard(
                id: skill.id,
                name: skill.name,
                description: skill.description,
                cost: skill.cost,
                type: ActionCardType.spell, // Use spell type for skills
                effect: skill.effects.isNotEmpty ? skill.effects.first.toString() : 'damage:${skill.attack}',
                rarity: CardRarity.common,
              ),
              onDragStarted: () {
                print('[DRAG] Started dragging skill: ${skill.name}');
                // Convert GameCard to ActionCard for drag handling
                final actionCard = ActionCard(
                  id: skill.id,
                  name: skill.name,
                  description: skill.description,
                  cost: skill.cost,
                  type: ActionCardType.spell, // Use spell type for skills
                  effect: skill.effects.isNotEmpty ? skill.effects.first.toString() : 'damage:${skill.attack}',
                  rarity: CardRarity.common,
                );
                controller.startSkillDrag(actionCard, Offset.zero);
              },
              onDragEnd: (details) {
                print('[DRAG] Ended dragging skill');
                controller.endDrag();
              },
              feedback: Material(
                color: Colors.transparent,
                child: Container(
                  width: 100,
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      skill.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.5,
                child: Container(
                  width: 100,
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      skill.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              child: Container(
                width: 100,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: controller.canUseSkill(skill) 
                        ? Colors.white 
                        : Colors.grey,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      skill.name,
                      style: TextStyle(
                        color: controller.canUseSkill(skill) 
                            ? Colors.white 
                            : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${skill.cost} MP',
                      style: TextStyle(
                        color: controller.canUseSkill(skill) 
                            ? Colors.white70 
                            : Colors.grey,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ).toList(),
      ],
    );
  }

  Widget _buildPlayerActions(BattleController controller) {
    return Container(
      height: 160,
      decoration: const BoxDecoration(
        color: Color(0xFF0f3460),
        border: Border(
          top: BorderSide(color: Color(0xFFe94560), width: 2),
        ),
      ),
      child: Column(
        children: [
          // Three Hand System (Action Cards, Skills, Inventory)
          Container(
            height: 200,
            child: ThreeHandSystemWidget(
              controller: controller,
              currentPlayer: controller.getCurrentPlayer()!,
              isCurrentPlayer: controller.battle.currentPlayerId == controller.getCurrentPlayer()?.id,
            ),
          ),
          
          // Action Buttons
          Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              children: [
                _buildActionButton(
                  'End Turn',
                  Icons.skip_next,
                  controller.canEndTurn(),
                  () => controller.endTurn(),
                ),
                const SizedBox(width: 16),
                
                // Mana Display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213e),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.water_drop, color: Colors.blue, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        '${controller.getCurrentPlayer()?.currentMana ?? 0}/${controller.getCurrentPlayer()?.maxMana ?? 0}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
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
              padding: const EdgeInsets.all(4),
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
          child: Draggable<ActionCard>(
            data: card,
            onDragStarted: () {
              print('[DRAG] Started dragging hand card: ${card.name}');
              controller.startCardDrag(card, Offset.zero);
            },
            onDragEnd: (details) {
              print('[DRAG] Ended dragging hand card');
              controller.endDrag();
            },
            feedback: Material(
              color: Colors.transparent,
              child: Container(
                width: 100,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFFe94560),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    card.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.5,
              child: HearthstoneCardWidget(
                card: card,
                controller: controller,
                canPlay: false,
                isGhost: controller.ghostCardsInHand.contains(card.id),
              ),
            ),
            child: HearthstoneCardWidget(
              card: card,
              controller: controller,
              canPlay: canPlay,
              isGhost: controller.ghostCardsInHand.contains(card.id),
              onTap: () => controller.selectCard(card),
            ),
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
                child: HearthstoneCardWidget(
                  card: drawnCard,
                  controller: controller,
                  canPlay: true,
                  onTap: () {},
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
