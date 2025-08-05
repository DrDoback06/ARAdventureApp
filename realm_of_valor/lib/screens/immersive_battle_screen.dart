import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'dart:math' as math;

import '../models/battle_system.dart';
import '../services/comprehensive_battle_engine.dart';
import '../services/immersive_battle_enhancements.dart';
import '../widgets/dynamic_avatar_widget.dart';
import '../widgets/stress_monitor_widget.dart';
import '../widgets/voice_command_widget.dart';
import '../widgets/environmental_effects_widget.dart';
import '../widgets/consequence_display_widget.dart';
import '../widgets/legendary_moment_widget.dart';
import '../widgets/battle_arena_customizer_widget.dart';

class ImmersiveBattleScreen extends StatefulWidget {
  final BattleState battle;
  final String playerId;

  const ImmersiveBattleScreen({
    Key? key,
    required this.battle,
    required this.playerId,
  }) : super(key: key);

  @override
  State<ImmersiveBattleScreen> createState() => _ImmersiveBattleScreenState();
}

class _ImmersiveBattleScreenState extends State<ImmersiveBattleScreen>
    with TickerProviderStateMixin {
  
  // Animation controllers for immersive effects
  late AnimationController _avatarEmotionController;
  late AnimationController _stressVisualizationController;
  late AnimationController _environmentalEffectsController;
  late AnimationController _consequenceAnimationController;
  late AnimationController _legendaryMomentController;
  late AnimationController _victoryMonumentController;
  late AnimationController _defeatRecoveryController;
  
  // Battle state
  BattleCard? _selectedCard;
  bool _isVoiceCommandActive = false;
  bool _showStressMonitor = true;
  bool _showConsequencePreview = false;
  bool _isHighStakesBattle = false;
  bool _cameraEnabled = false;
  
  // Immersive features state
  double _currentStressLevel = 0.0;
  EmotionalState _playerEmotion = EmotionalState.neutral;
  List<String> _activeBattleCries = [];
  String? _currentEnvironmentalEffect;
  Map<String, dynamic>? _previewedConsequences;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeImmersiveFeatures();
    _setupBattleListeners();
  }

  void _initializeAnimations() {
    _avatarEmotionController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _stressVisualizationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _environmentalEffectsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _consequenceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _legendaryMomentController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _victoryMonumentController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    _defeatRecoveryController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
  }

  Future<void> _initializeImmersiveFeatures() async {
    final enhancements = context.read<ImmersiveBattleEnhancements>();
    
    // Initialize all enhancement systems
    await enhancements.initializeAvatarSystem();
    await enhancements.initializeBattleSpeech();
    await enhancements.initializeStressMonitoring();
    await enhancements.initializeConsequencesSystem();
    await enhancements.initializeVoiceCommands();
    await enhancements.initializeCameraFeatures();
    await enhancements.initializeCoachingSystem();
    await enhancements.initializeAdaptiveSoundtrack();
    await enhancements.initializeMentorshipSystem();
    
    // Check if this is a high-stakes battle requiring biometric auth
    _isHighStakesBattle = _determineIfHighStakes(widget.battle);
    if (_isHighStakesBattle) {
      final authenticated = await enhancements.authenticateForHighStakesBattle(widget.playerId);
      if (!authenticated) {
        _showAuthenticationFailedDialog();
        return;
      }
    }
    
    // Speak battle start
    await enhancements.speakBattleEvent(widget.playerId, BattleSpeechEvent.battleStart);
    
    // Trigger battle start haptics
    await enhancements.triggerHapticFeedback(HapticType.cardDraw);
    
    // Apply environmental factors
    await enhancements.integrateEnvironmentalFactors(widget.battle, null);
    
    // Start voice command listening
    await enhancements.startListeningForCommands(widget.battle.id);
  }

  void _setupBattleListeners() {
    // Listen for battle updates and trigger appropriate responses
    context.read<ComprehensiveBattleEngine>().addListener(() {
      _handleBattleStateChanges();
    });
    
    // Listen for stress level changes
    context.read<ImmersiveBattleEnhancements>().addListener(() {
      _handleStressLevelChanges();
    });
  }

  void _handleBattleStateChanges() {
    final battleEngine = context.read<ComprehensiveBattleEngine>();
    final enhancements = context.read<ImmersiveBattleEnhancements>();
    final battle = battleEngine.currentBattle;
    
    if (battle != null && battle.id == widget.battle.id) {
      // Update stress visualization
      _stressVisualizationController.forward();
      
      // Check for legendary moments
      enhancements.checkForLegendaryMoment(battle, widget.playerId);
      
      // Update battle music based on intensity
      enhancements.updateBattleMusic(battle, widget.playerId);
      
      // Provide real-time coaching if needed
      enhancements.provideRealTimeCoaching(widget.playerId, battle);
      
      // Check for battle fatigue
      enhancements.trackBattleFatigue(widget.playerId);
      
      // Apply social pressure if spectators present
      enhancements.applySocialPressure(battle);
      
      if (battle.isGameOver) {
        _handleBattleEnd(battle);
      }
    }
  }

  void _handleStressLevelChanges() {
    // Update stress visualization and trigger appropriate responses
    setState(() {
      // Update stress level would come from enhancement service
    });
    
    if (_currentStressLevel > 0.8) {
      _triggerStressResponse();
    }
  }

  Future<void> _handleBattleEnd(BattleState battle) async {
    final enhancements = context.read<ImmersiveBattleEnhancements>();
    final isWinner = battle.winnerId == widget.playerId;
    
    // Apply battle consequences
    await enhancements.applyBattleConsequences(widget.playerId, battle, isWinner);
    
    // Create battle memory
    await enhancements.createBattleMemory(battle, widget.playerId);
    
    // Process post-battle injuries
    await enhancements.processPostBattleInjuries(widget.playerId, battle);
    
    // Update battle reputation
    await enhancements.updateBattleReputation(widget.playerId, battle);
    
    if (isWinner) {
      await _handleVictory(battle);
    } else {
      await _handleDefeat(battle);
    }
    
    // Create cinematic replay
    await enhancements.createCinematicReplay(battle);
    
    // Check for battle ascension
    await enhancements.checkForBattleAscension(widget.playerId);
  }

  Future<void> _handleVictory(BattleState battle) async {
    final enhancements = context.read<ImmersiveBattleEnhancements>();
    
    // Speak victory
    await enhancements.speakBattleEvent(widget.playerId, BattleSpeechEvent.victory);
    
    // Trigger victory haptics
    await enhancements.triggerHapticFeedback(HapticType.victory);
    
    // Trigger victory celebration
    await enhancements.triggerVictoryCelebration(widget.playerId, battle);
    
    // Capture victory moment
    if (_cameraEnabled) {
      await enhancements.captureVictoryMoment(widget.playerId, battle);
    }
    
    // Create victory monument if worthy
    await enhancements.createVictoryMonument(widget.playerId, battle);
    
    // Animate victory
    _victoryMonumentController.forward();
  }

  Future<void> _handleDefeat(BattleState battle) async {
    final enhancements = context.read<ImmersiveBattleEnhancements>();
    
    // Speak defeat
    await enhancements.speakBattleEvent(widget.playerId, BattleSpeechEvent.defeat);
    
    // Trigger defeat haptics
    await enhancements.triggerHapticFeedback(HapticType.defeat);
    
    // Process immersive loss conditions
    await enhancements.processImmersiveLoss(widget.playerId, battle);
    
    // Provide defeat support
    await enhancements.provideDefeatSupport(widget.playerId, battle);
    
    // Create adaptive nemesis from this defeat
    await enhancements.createAdaptiveNemesis(widget.playerId, battle);
    
    // Match with mentor if needed
    await enhancements.matchWithMentor(widget.playerId);
    
    // Animate defeat recovery
    _defeatRecoveryController.forward();
  }

  void _triggerStressResponse() {
    final enhancements = context.read<ImmersiveBattleEnhancements>();
    
    // Trigger stress-relief haptics
    enhancements.triggerHapticFeedback(HapticType.heartbeat);
    
    // Show stress management UI
    _showStressManagementDialog();
    
    // Animate stress visualization
    _stressVisualizationController.repeat();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ComprehensiveBattleEngine, ImmersiveBattleEnhancements>(
      builder: (context, battleEngine, enhancements, child) {
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
              // Main battle view with environmental effects
              _buildImmersiveBattleView(battle, player, opponent),
              
              // Dynamic avatar overlay
              Positioned(
                bottom: 20,
                left: 20,
                child: _buildDynamicAvatarOverlay(player),
              ),
              
              // Stress monitor
              if (_showStressMonitor)
                Positioned(
                  top: 40,
                  right: 20,
                  child: _buildStressMonitor(),
                ),
              
              // Voice command indicator
              if (_isVoiceCommandActive)
                Positioned(
                  top: 100,
                  left: 20,
                  child: _buildVoiceCommandIndicator(),
                ),
              
              // Consequence preview
              if (_showConsequencePreview)
                Positioned(
                  center: true,
                  child: _buildConsequencePreview(),
                ),
              
              // Environmental effects overlay
              if (_currentEnvironmentalEffect != null)
                _buildEnvironmentalEffectsOverlay(),
              
              // Legendary moment celebration
              AnimatedBuilder(
                animation: _legendaryMomentController,
                builder: (context, child) {
                  if (_legendaryMomentController.value == 0) return const SizedBox.shrink();
                  return _buildLegendaryMomentCelebration();
                },
              ),
              
              // Battle analytics floating button
              Positioned(
                top: 40,
                left: 20,
                child: _buildAnalyticsButton(),
              ),
              
              // Proximity players indicator
              Positioned(
                top: 200,
                right: 20,
                child: _buildProximityPlayersIndicator(),
              ),
              
              // Arena customization controls
              Positioned(
                bottom: 20,
                right: 20,
                child: _buildArenaCustomizationButton(),
              ),
              
              // Battle fatigue warning
              if (_shouldShowFatigueWarning())
                Positioned(
                  top: 300,
                  left: 0,
                  right: 0,
                  child: _buildFatigueWarning(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImmersiveBattleView(BattleState battle, BattlePlayer player, BattlePlayer opponent) {
    return Container(
      decoration: _buildDynamicBackground(),
      child: Column(
        children: [
          // Enhanced opponent area with emotional display
          Expanded(
            flex: 2,
            child: _buildEnhancedOpponentArea(battle, opponent),
          ),
          
          // Enhanced battlefield with environmental effects
          Expanded(
            flex: 3,
            child: _buildEnhancedBattlefield(battle, player, opponent),
          ),
          
          // Enhanced player area with consequences preview
          Expanded(
            flex: 3,
            child: _buildEnhancedPlayerArea(battle, player),
          ),
        ],
      ),
    );
  }

  BoxDecoration _buildDynamicBackground() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: _getStressAdjustedColors(),
      ),
    );
  }

  List<Color> _getStressAdjustedColors() {
    if (_currentStressLevel > 0.8) {
      return [Colors.red.shade900.withOpacity(0.8), Colors.black];
    } else if (_currentStressLevel > 0.5) {
      return [Colors.orange.shade900.withOpacity(0.7), Colors.black];
    } else {
      return [Colors.purple.shade900.withOpacity(0.6), Colors.black];
    }
  }

  Widget _buildDynamicAvatarOverlay(BattlePlayer player) {
    return AnimatedBuilder(
      animation: _avatarEmotionController,
      builder: (context, child) {
        return DynamicAvatarWidget(
          player: player,
          emotionalState: _playerEmotion,
          stressLevel: _currentStressLevel,
          animationValue: _avatarEmotionController.value,
          onEmotionChange: (emotion) {
            setState(() => _playerEmotion = emotion);
          },
        );
      },
    );
  }

  Widget _buildStressMonitor() {
    return AnimatedBuilder(
      animation: _stressVisualizationController,
      builder: (context, child) {
        return StressMonitorWidget(
          stressLevel: _currentStressLevel,
          animationValue: _stressVisualizationController.value,
          showDetails: true,
          onStressThresholdReached: () => _triggerStressResponse(),
        );
      },
    );
  }

  Widget _buildVoiceCommandIndicator() {
    return VoiceCommandWidget(
      isActive: _isVoiceCommandActive,
      onToggle: () => _toggleVoiceCommands(),
      supportedCommands: const [
        'Play card',
        'End turn',
        'Help',
        'Surrender',
        'Show analytics',
      ],
    );
  }

  Widget _buildConsequencePreview() {
    return AnimatedBuilder(
      animation: _consequenceAnimationController,
      builder: (context, child) {
        return ConsequenceDisplayWidget(
          consequences: _previewedConsequences,
          animationValue: _consequenceAnimationController.value,
          onDismiss: () => setState(() => _showConsequencePreview = false),
        );
      },
    );
  }

  Widget _buildEnvironmentalEffectsOverlay() {
    return AnimatedBuilder(
      animation: _environmentalEffectsController,
      builder: (context, child) {
        return EnvironmentalEffectsWidget(
          effectType: _currentEnvironmentalEffect!,
          intensity: _environmentalEffectsController.value,
        );
      },
    );
  }

  Widget _buildLegendaryMomentCelebration() {
    return LegendaryMomentWidget(
      animationValue: _legendaryMomentController.value,
      momentType: 'Epic Victory',
      rarity: 5,
      onComplete: () => _legendaryMomentController.reset(),
    );
  }

  Widget _buildAnalyticsButton() {
    return FloatingActionButton(
      mini: true,
      backgroundColor: Colors.blue.withOpacity(0.8),
      onPressed: () => _showBattleAnalytics(),
      child: const Icon(Icons.analytics, color: Colors.white),
    );
  }

  Widget _buildProximityPlayersIndicator() {
    return FutureBuilder<List<String>>(
      future: context.read<ImmersiveBattleEnhancements>()
          .findNearbyPlayers(GeoLocation(latitude: 0, longitude: 0), 1.0),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people, color: Colors.white, size: 16),
                Text(
                  '${snapshot.data!.length} nearby',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildArenaCustomizationButton() {
    return FloatingActionButton(
      mini: true,
      backgroundColor: Colors.purple.withOpacity(0.8),
      onPressed: () => _showArenaCustomization(),
      child: const Icon(Icons.settings, color: Colors.white),
    );
  }

  Widget _buildFatigueWarning() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.white),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Battle fatigue detected. Consider taking a break for optimal performance.',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () => _dismissFatigueWarning(),
            child: const Text('Dismiss', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedOpponentArea(BattleState battle, BattlePlayer opponent) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Opponent avatar with AI personality display
          Expanded(
            flex: 2,
            child: _buildOpponentAvatarWithPersonality(opponent),
          ),
          
          // Battle speech bubble
          Expanded(
            flex: 2,
            child: _buildBattleSpeechBubble(opponent),
          ),
          
          // Opponent hand with AI hints
          Expanded(
            flex: 3,
            child: _buildOpponentHandWithHints(opponent),
          ),
          
          // Enhanced battle controls
          Expanded(
            flex: 1,
            child: _buildEnhancedBattleControls(battle),
          ),
        ],
      ),
    );
  }

  Widget _buildOpponentAvatarWithPersonality(BattlePlayer opponent) {
    return Column(
      children: [
        // Avatar with emotion display
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.red.shade600, Colors.red.shade800],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(Icons.android, size: 40, color: Colors.white),
        ),
        
        const SizedBox(height: 8),
        
        // AI personality indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'AGGRESSIVE AI',
            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        
        // Health and mana bars with stress indicators
        const SizedBox(height: 8),
        _buildStatusBars(opponent, isPlayer: false),
      ],
    );
  }

  Widget _buildBattleSpeechBubble(BattlePlayer opponent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade400),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _getLatestOpponentSpeech(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // Audio visualization for speech
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) => 
              Container(
                width: 3,
                height: 10 + (index * 5),
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpponentHandWithHints(BattlePlayer opponent) {
    return Column(
      children: [
        // Hand cards
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: opponent.handSize,
            itemBuilder: (context, index) {
              return Container(
                width: 50,
                margin: const EdgeInsets.symmetric(horizontal: 2),
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
                  child: Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                ),
              );
            },
          ),
        ),
        
        // AI behavior hint
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.yellow.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _getAIBehaviorHint(),
            style: const TextStyle(color: Colors.yellow, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedBattleControls(BattleState battle) {
    return Column(
      children: [
        // Battle menu
        IconButton(
          onPressed: () => _showEnhancedBattleMenu(),
          icon: const Icon(Icons.menu, color: Colors.white),
        ),
        
        // Camera toggle
        IconButton(
          onPressed: () => _toggleCamera(),
          icon: Icon(
            _cameraEnabled ? Icons.camera_alt : Icons.camera_alt_outlined,
            color: _cameraEnabled ? Colors.green : Colors.white,
          ),
        ),
        
        // Voice command toggle
        IconButton(
          onPressed: () => _toggleVoiceCommands(),
          icon: Icon(
            _isVoiceCommandActive ? Icons.mic : Icons.mic_off,
            color: _isVoiceCommandActive ? Colors.green : Colors.white,
          ),
        ),
        
        // Stress monitor toggle
        IconButton(
          onPressed: () => setState(() => _showStressMonitor = !_showStressMonitor),
          icon: Icon(
            Icons.favorite,
            color: _showStressMonitor ? Colors.red : Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedBattlefield(BattleState battle, BattlePlayer player, BattlePlayer opponent) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Opponent battlefield with environmental effects
          Expanded(
            child: _buildBattlefieldSection(
              creatures: opponent.battlefield,
              isPlayerSide: false,
              environmentalEffect: _currentEnvironmentalEffect,
            ),
          ),
          
          // Enhanced center battle info
          Container(
            height: 80,
            child: _buildEnhancedBattleInfo(battle),
          ),
          
          // Player battlefield with consequences preview
          Expanded(
            child: _buildBattlefieldSection(
              creatures: player.battlefield,
              isPlayerSide: true,
              environmentalEffect: _currentEnvironmentalEffect,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBattlefieldSection({
    required List<BattleCreature> creatures,
    required bool isPlayerSide,
    String? environmentalEffect,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPlayerSide ? Colors.blue.shade400 : Colors.red.shade400,
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // Environmental effect overlay
          if (environmentalEffect != null)
            _buildEnvironmentalOverlay(environmentalEffect),
          
          // Creatures
          GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.8,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: creatures.length,
            itemBuilder: (context, index) {
              return _buildEnhancedCreatureCard(creatures[index], isPlayerSide);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedCreatureCard(BattleCreature creature, bool isPlayerSide) {
    return GestureDetector(
      onTap: () => _onCreatureSelected(creature),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: isPlayerSide 
                ? [Colors.blue.shade600, Colors.blue.shade800]
                : [Colors.red.shade600, Colors.red.shade800],
          ),
          boxShadow: [
            BoxShadow(
              color: (isPlayerSide ? Colors.blue : Colors.red).withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Creature info
            Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    creature.card.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Attack
                      Column(
                        children: [
                          const Icon(Icons.sword, color: Colors.white, size: 12),
                          Text(
                            '${creature.currentAttack}',
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                      
                      // Health
                      Column(
                        children: [
                          const Icon(Icons.favorite, color: Colors.white, size: 12),
                          Text(
                            '${creature.currentHealth}',
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Status effects
            if (creature.statusEffects.isNotEmpty)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.purple,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${creature.statusEffects.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 8),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedBattleInfo(BattleState battle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade400, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Turn indicator with stress color
          _buildStressAdjustedTurnIndicator(battle),
          
          // Phase indicator with animations
          _buildAnimatedPhaseIndicator(battle),
          
          // Enhanced turn timer
          _buildEnhancedTurnTimer(),
          
          // Consequence preview button
          _buildConsequencePreviewButton(),
          
          // Environmental indicator
          if (_currentEnvironmentalEffect != null)
            _buildEnvironmentalIndicator(),
        ],
      ),
    );
  }

  Widget _buildStressAdjustedTurnIndicator(BattleState battle) {
    final isPlayerTurn = battle.activePlayerId == widget.playerId;
    final color = _getStressAdjustedColor(isPlayerTurn);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Text(
        isPlayerTurn ? 'YOUR TURN' : 'OPPONENT TURN',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildAnimatedPhaseIndicator(BattleState battle) {
    return AnimatedBuilder(
      animation: _stressVisualizationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_stressVisualizationController.value * 0.1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Turn ${battle.turnNumber}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              Text(
                battle.turnPhase.name.toUpperCase(),
                style: TextStyle(color: Colors.grey.shade300, fontSize: 8),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnhancedTurnTimer() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Stress-affected timer ring
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getStressAdjustedColor(true),
            ),
          ),
        ),
        
        // Timer text
        const Text(
          '45s',
          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildConsequencePreviewButton() {
    return GestureDetector(
      onTap: () => _showConsequencePreview(),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning, color: Colors.white, size: 16),
            Text(
              'RISKS',
              style: TextStyle(color: Colors.white, fontSize: 8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentalIndicator() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wb_sunny, color: Colors.white, size: 14),
          Text(
            _currentEnvironmentalEffect!.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 7),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedPlayerArea(BattleState battle, BattlePlayer player) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Enhanced player info with consequences
          Expanded(
            flex: 1,
            child: _buildEnhancedPlayerInfo(player),
          ),
          
          // Enhanced player hand with voice hints
          Expanded(
            flex: 2,
            child: _buildEnhancedPlayerHand(battle, player),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedPlayerInfo(BattlePlayer player) {
    return Row(
      children: [
        // Enhanced player portrait with real-time emotion
        Expanded(
          flex: 2,
          child: _buildPlayerPortraitWithEmotion(player),
        ),
        
        // Enhanced deck info with analytics
        Expanded(
          flex: 1,
          child: _buildEnhancedDeckInfo(player),
        ),
        
        // Enhanced action buttons with voice hints
        Expanded(
          flex: 1,
          child: _buildEnhancedActionButtons(),
        ),
      ],
    );
  }

  Widget _buildPlayerPortraitWithEmotion(BattlePlayer player) {
    return Row(
      children: [
        // Avatar with dynamic emotion
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: _getEmotionColors(_playerEmotion),
            ),
            boxShadow: [
              BoxShadow(
                color: _getEmotionColors(_playerEmotion).first.withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: const Icon(Icons.person, size: 30, color: Colors.white),
        ),
        
        const SizedBox(width: 12),
        
        // Enhanced status with stress indicators
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                player.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              
              const SizedBox(height: 4),
              
              // Enhanced status bars
              _buildStatusBars(player, isPlayer: true),
              
              const SizedBox(height: 4),
              
              // Emotion indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getEmotionColors(_playerEmotion).first.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _playerEmotion.name.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBars(BattlePlayer player, {required bool isPlayer}) {
    return Column(
      children: [
        // Health bar with stress effects
        Row(
          children: [
            const Icon(Icons.favorite, color: Colors.red, size: 12),
            const SizedBox(width: 4),
            Expanded(
              child: LinearProgressIndicator(
                value: player.currentHealth / player.stats.health,
                backgroundColor: Colors.red.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isPlayer && _currentStressLevel > 0.7 
                      ? Colors.orange 
                      : Colors.red,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${player.currentHealth}/${player.stats.health}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ],
        ),
        
        const SizedBox(height: 2),
        
        // Mana bar with stress effects
        Row(
          children: [
            const Icon(Icons.water_drop, color: Colors.blue, size: 12),
            const SizedBox(width: 4),
            Expanded(
              child: LinearProgressIndicator(
                value: player.currentMana / player.stats.mana,
                backgroundColor: Colors.blue.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isPlayer && _currentStressLevel > 0.7 
                      ? Colors.purple 
                      : Colors.blue,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${player.currentMana}/${player.stats.mana}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnhancedDeckInfo(BattlePlayer player) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Enhanced deck button with analytics
        GestureDetector(
          onTap: () => _showDeckAnalytics(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade800,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade400),
            ),
            child: Column(
              children: [
                const Icon(Icons.style, color: Colors.white, size: 16),
                Text(
                  'Deck: ${player.deckSize}',
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                ),
                Text(
                  'Win Rate: 67%',
                  style: TextStyle(color: Colors.green.shade300, fontSize: 8),
                ),
              ],
            ),
          ),
        ),
        
        // Enhanced graveyard with replay
        GestureDetector(
          onTap: () => _showGraveyardAnalysis(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade600),
            ),
            child: Column(
              children: [
                const Icon(Icons.delete, color: Colors.white, size: 16),
                Text(
                  'Grave: ${player.graveyard.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                ),
                const Text(
                  'Replay',
                  style: TextStyle(color: Colors.purple, fontSize: 8),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedActionButtons() {
    return Column(
      children: [
        // Enhanced end turn with voice hint
        Expanded(
          child: Stack(
            children: [
              ElevatedButton(
                onPressed: _canEndTurn() ? _endTurn : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getStressAdjustedColor(true),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('END TURN', style: TextStyle(fontSize: 10)),
              ),
              
              if (_isVoiceCommandActive)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Enhanced options with analytics
        Expanded(
          child: ElevatedButton(
            onPressed: () => _showEnhancedOptions(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('ANALYTICS', style: TextStyle(fontSize: 10)),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedPlayerHand(BattleState battle, BattlePlayer player) {
    return Container(
      height: 140,
      child: Stack(
        children: [
          // Card hand
          PageView.builder(
            itemCount: (player.hand.length / 5).ceil(),
            itemBuilder: (context, pageIndex) {
              final startIndex = pageIndex * 5;
              final endIndex = math.min(startIndex + 5, player.hand.length);
              final pageCards = player.hand.sublist(startIndex, endIndex);
              
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: pageCards.map((card) => _buildEnhancedHandCard(battle, player, card)).toList(),
              );
            },
          ),
          
          // Voice command overlay
          if (_isVoiceCommandActive)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '🎤 Say "Play [card name]" to play a card',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEnhancedHandCard(BattleState battle, BattlePlayer player, BattleCard card) {
    final canPlay = card.canBePlayedBy(player.stats, player.characterClass, player.currentMana);
    final isSelected = _selectedCard?.id == card.id;
    
    return GestureDetector(
      onTap: () => _onCardSelected(card, canPlay),
      onLongPress: () => _showCardConsequencePreview(card),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()
          ..translate(0.0, isSelected ? -20.0 : 0.0),
        child: Stack(
          children: [
            // Enhanced card widget
            Container(
              width: 70,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: _getCardColors(card, canPlay),
                ),
                border: Border.all(
                  color: isSelected ? Colors.yellow : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getCardGlowColor(card, canPlay),
                    blurRadius: isSelected ? 15 : 5,
                    spreadRadius: isSelected ? 3 : 1,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Mana cost
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${card.manaCost}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    
                    // Card name
                    Text(
                      card.name,
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Attack/Health if creature
                    if (card.attack != null || card.health != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (card.attack != null)
                            Text('${card.attack}', style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                          if (card.health != null)
                            Text('${card.health}', style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            
            // Stress indicator for risky plays
            if (_wouldIncreaseStress(card))
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning, color: Colors.white, size: 8),
                ),
              ),
            
            // Voice command hint
            if (_isVoiceCommandActive && canPlay)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.8),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '🎤',
                    style: TextStyle(fontSize: 8),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentalOverlay(String effectType) {
    switch (effectType) {
      case 'rain':
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.withOpacity(0.3), Colors.transparent],
            ),
          ),
        );
      case 'fire':
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [Colors.red.withOpacity(0.4), Colors.transparent],
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

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
              'Battle Session Lost',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your battle session has been disconnected.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Return to Adventure'),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods
  BattlePlayer? _getPlayer(BattleState battle) {
    return battle.player1.id == widget.playerId ? battle.player1 : battle.player2;
  }

  BattlePlayer? _getOpponent(BattleState battle) {
    return battle.player1.id == widget.playerId ? battle.player2 : battle.player1;
  }

  Color _getStressAdjustedColor(bool isPositive) {
    if (_currentStressLevel > 0.8) {
      return isPositive ? Colors.orange.shade600 : Colors.red.shade600;
    } else if (_currentStressLevel > 0.5) {
      return isPositive ? Colors.yellow.shade600 : Colors.orange.shade600;
    } else {
      return isPositive ? Colors.green.shade600 : Colors.red.shade600;
    }
  }

  List<Color> _getEmotionColors(EmotionalState emotion) {
    switch (emotion) {
      case EmotionalState.confident:
        return [Colors.green.shade600, Colors.green.shade800];
      case EmotionalState.nervous:
        return [Colors.orange.shade600, Colors.orange.shade800];
      case EmotionalState.excited:
        return [Colors.purple.shade600, Colors.purple.shade800];
      case EmotionalState.frustrated:
        return [Colors.red.shade600, Colors.red.shade800];
      case EmotionalState.defeated:
        return [Colors.grey.shade600, Colors.grey.shade800];
      case EmotionalState.triumphant:
        return [Colors.yellow.shade600, Colors.yellow.shade800];
      default:
        return [Colors.blue.shade600, Colors.blue.shade800];
    }
  }

  List<Color> _getCardColors(BattleCard card, bool canPlay) {
    if (!canPlay) {
      return [Colors.grey.shade600, Colors.grey.shade800];
    }
    
    switch (card.rarity) {
      case 1: return [Colors.grey.shade400, Colors.grey.shade600]; // Common
      case 2: return [Colors.green.shade400, Colors.green.shade600]; // Uncommon
      case 3: return [Colors.blue.shade400, Colors.blue.shade600]; // Rare
      case 4: return [Colors.purple.shade400, Colors.purple.shade600]; // Epic
      case 5: return [Colors.orange.shade400, Colors.orange.shade600]; // Legendary
      default: return [Colors.grey.shade400, Colors.grey.shade600];
    }
  }

  Color _getCardGlowColor(BattleCard card, bool canPlay) {
    if (!canPlay) return Colors.transparent;
    
    switch (card.rarity) {
      case 1: return Colors.grey.withOpacity(0.3);
      case 2: return Colors.green.withOpacity(0.4);
      case 3: return Colors.blue.withOpacity(0.5);
      case 4: return Colors.purple.withOpacity(0.6);
      case 5: return Colors.orange.withOpacity(0.7);
      default: return Colors.transparent;
    }
  }

  bool _determineIfHighStakes(BattleState battle) {
    return battle.type == BattleType.tournament || 
           battle.battleConditions.containsKey('high_stakes') ||
           battle.battleConditions.containsKey('ranked');
  }

  bool _wouldIncreaseStress(BattleCard card) {
    return card.manaCost > 5 || card.rarity >= 4 || card.abilities.contains('risky');
  }

  bool _canEndTurn() {
    final battle = context.read<ComprehensiveBattleEngine>().currentBattle;
    return battle?.activePlayerId == widget.playerId;
  }

  bool _shouldShowFatigueWarning() {
    // This would be determined by the enhancement service
    return false;
  }

  String _getLatestOpponentSpeech() {
    // This would come from the AI speech system
    return "Your move, adventurer!";
  }

  String _getAIBehaviorHint() {
    return "AI is playing aggressively";
  }

  // Event Handlers
  void _onCardSelected(BattleCard card, bool canPlay) {
    if (!canPlay) return;
    
    setState(() {
      _selectedCard = card;
    });
    
    final enhancements = context.read<ImmersiveBattleEnhancements>();
    enhancements.triggerHapticFeedback(HapticType.cardPlay);
    enhancements.speakBattleEvent(widget.playerId, BattleSpeechEvent.cardPlayed, context: {'card': card});
  }

  void _onCreatureSelected(BattleCreature creature) {
    // Handle creature selection for targeting
  }

  void _endTurn() {
    final battleEngine = context.read<ComprehensiveBattleEngine>();
    battleEngine.endTurn(widget.battle.id, widget.playerId);
  }

  void _toggleVoiceCommands() {
    setState(() {
      _isVoiceCommandActive = !_isVoiceCommandActive;
    });
    
    final enhancements = context.read<ImmersiveBattleEnhancements>();
    if (_isVoiceCommandActive) {
      enhancements.startListeningForCommands(widget.battle.id);
    }
  }

  void _toggleCamera() {
    setState(() {
      _cameraEnabled = !_cameraEnabled;
    });
  }

  void _showConsequencePreview() {
    setState(() {
      _showConsequencePreview = true;
    });
    _consequenceAnimationController.forward();
  }

  void _showCardConsequencePreview(BattleCard card) {
    // Show what would happen if this card is played
  }

  void _showStressManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stress Level High'),
        content: const Text('Your stress level is elevated. Consider taking a moment to breathe and refocus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement stress reduction techniques
            },
            child: const Text('Take Break'),
          ),
        ],
      ),
    );
  }

  void _showBattleAnalytics() async {
    final enhancements = context.read<ImmersiveBattleEnhancements>();
    final analytics = await enhancements.generateBattleAnalytics(widget.playerId);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Battle Analytics'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Win Rate: ${analytics['winRate']?.toStringAsFixed(1)}%'),
              Text('Avg Duration: ${analytics['averageBattleDuration']}'),
              Text('Stress Pattern: ${analytics['stressPatterns']}'),
              // Add more analytics display
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showArenaCustomization() {
    showDialog(
      context: context,
      builder: (context) => BattleArenaCustomizerWidget(
        currentTheme: 'default',
        onThemeChanged: (theme) {
          // Apply arena customization
        },
      ),
    );
  }

  void _showEnhancedBattleMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Battle Analytics'),
              onTap: () {
                Navigator.pop(context);
                _showBattleAnalytics();
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Find Nearby Players'),
              onTap: () {
                Navigator.pop(context);
                _findNearbyPlayers();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(_cameraEnabled ? 'Disable Camera' : 'Enable Camera'),
              onTap: () {
                Navigator.pop(context);
                _toggleCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Customize Arena'),
              onTap: () {
                Navigator.pop(context);
                _showArenaCustomization();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEnhancedOptions() {
    // Show enhanced options with analytics
    _showBattleAnalytics();
  }

  void _showDeckAnalytics() {
    // Show detailed deck performance analytics
  }

  void _showGraveyardAnalysis() {
    // Show graveyard cards with replay functionality
  }

  void _showAuthenticationFailedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Failed'),
        content: const Text('This is a high-stakes battle requiring biometric authentication. Please try again.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Exit Battle'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final enhancements = context.read<ImmersiveBattleEnhancements>();
              final success = await enhancements.authenticateForHighStakesBattle(widget.playerId);
              if (!success) {
                _showAuthenticationFailedDialog();
              }
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _dismissFatigueWarning() {
    // Dismiss fatigue warning
  }

  void _findNearbyPlayers() async {
    final enhancements = context.read<ImmersiveBattleEnhancements>();
    final nearbyPlayers = await enhancements.findNearbyPlayers(
      GeoLocation(latitude: 0, longitude: 0), 
      1.0,
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nearby Players'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Found ${nearbyPlayers.length} players within 1km'),
            // Show list of nearby players with invite options
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _avatarEmotionController.dispose();
    _stressVisualizationController.dispose();
    _environmentalEffectsController.dispose();
    _consequenceAnimationController.dispose();
    _legendaryMomentController.dispose();
    _victoryMonumentController.dispose();
    _defeatRecoveryController.dispose();
    super.dispose();
  }
}