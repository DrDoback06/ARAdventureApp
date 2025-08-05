import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/battle_system.dart';
import '../models/adventure_system.dart';
import 'enhanced_location_service.dart';
import 'encounter_service.dart';

class ComprehensiveBattleEngine extends ChangeNotifier {
  static final ComprehensiveBattleEngine _instance = ComprehensiveBattleEngine._internal();
  factory ComprehensiveBattleEngine() => _instance;
  ComprehensiveBattleEngine._internal();

  // Battle state management
  BattleState? _currentBattle;
  final List<BattleState> _activeBattles = [];
  final List<MatchmakingRequest> _matchmakingQueue = [];
  final StreamController<BattleState> _battleUpdatesController = StreamController.broadcast();
  final StreamController<MatchmakingResult> _matchFoundController = StreamController.broadcast();
  
  // AI system
  final Map<String, AIPersonality> _aiPersonalities = {};
  final Random _random = Random();
  
  // Card and deck management
  final Map<String, List<BattleCard>> _playerDecks = {};
  final Map<String, Map<String, int>> _playerCollections = {}; // cardId -> quantity
  final CardLibrary _cardLibrary = CardLibrary();
  
  // Tournament system
  final List<Tournament> _activeTournaments = [];
  final Map<String, TournamentBracket> _tournamentBrackets = {};

  // Streams
  Stream<BattleState> get battleUpdates => _battleUpdatesController.stream;
  Stream<MatchmakingResult> get matchFound => _matchFoundController.stream;

  // Getters
  BattleState? get currentBattle => _currentBattle;
  List<BattleState> get activeBattles => _activeBattles;
  List<Tournament> get activeTournaments => _activeTournaments;

  // Enhanced Idea 1: Multi-layered AI System
  // Enhanced Idea 2: Dynamic Card Generation System

  // Initialize the battle engine
  Future<void> initialize() async {
    await _loadPlayerData();
    await _initializeAIPersonalities();
    await _loadActiveBattles();
    _startMatchmakingService();
    print('Comprehensive Battle Engine initialized');
  }

  // CORE BATTLE MANAGEMENT

  // Start a new battle
  Future<BattleState> startBattle({
    required BattlePlayer player1,
    required BattlePlayer player2,
    required BattleType type,
    Map<String, dynamic>? battleConditions,
  }) async {
    final battle = BattleState(
      type: type,
      player1: player1,
      player2: player2,
      battleConditions: battleConditions ?? {},
    );

    _currentBattle = battle;
    _activeBattles.add(battle);

    // Initialize battle
    await _initializeBattle(battle);
    
    _battleUpdatesController.add(battle);
    notifyListeners();

    return battle;
  }

  // Initialize battle setup
  Future<void> _initializeBattle(BattleState battle) async {
    // Shuffle decks
    battle.player1.deck.shuffle(_random);
    battle.player2.deck.shuffle(_random);

    // Draw initial hands
    for (int i = 0; i < 4; i++) {
      battle.player1.drawCard();
      battle.player2.drawCard();
    }

    // Set first player (random or by initiative)
    final firstPlayer = _determineFirstPlayer(battle.player1, battle.player2);
    battle.activePlayerId = firstPlayer.id;
    
    // Start first turn
    battle.phase = BattlePhase.gameStart;
    battle.activePlayer.startTurn();
    
    battle.addLogEntry('Battle begins! ${firstPlayer.name} goes first.');
  }

  // Determine first player based on character stats
  BattlePlayer _determineFirstPlayer(BattlePlayer player1, BattlePlayer player2) {
    // Use dexterity as initiative, with random tiebreaker
    final p1Initiative = player1.stats.dexterity + _random.nextInt(20);
    final p2Initiative = player2.stats.dexterity + _random.nextInt(20);
    
    return p1Initiative >= p2Initiative ? player1 : player2;
  }

  // Play a card
  Future<bool> playCard(String battleId, String playerId, BattleCard card, {dynamic target}) async {
    final battle = _getBattleById(battleId);
    if (battle == null || battle.isGameOver) return false;

    final player = _getPlayerById(battle, playerId);
    if (player == null || !player.isActive) return false;

    // Validate card play
    if (!player.hand.contains(card)) return false;
    if (!card.canBePlayedBy(player.stats, player.characterClass, player.currentMana)) return false;

    // Execute card effects
    final success = await _executeCardPlay(battle, player, card, target);
    
    if (success) {
      battle.addLogEntry('${player.name} plays ${card.name}');
      _battleUpdatesController.add(battle);
      notifyListeners();
      
      // Check for battle end conditions
      await _checkBattleEndConditions(battle);
    }

    return success;
  }

  // Execute card play with all effects
  Future<bool> _executeCardPlay(BattleState battle, BattlePlayer player, BattleCard card, dynamic target) async {
    // Play the card
    final success = player.playCard(card, target: target);
    if (!success) return false;

    // Apply card effects based on type
    switch (card.type) {
      case CardType.spell:
        await _executeSpellEffects(battle, player, card, target);
        break;
      case CardType.creature:
        await _executeCreatureSummon(battle, player, card);
        break;
      case CardType.enchantment:
        await _executeEnchantmentEffects(battle, player, card);
        break;
      case CardType.artifact:
        await _executeArtifactEffects(battle, player, card);
        break;
      case CardType.skill:
        await _executeSkillEffects(battle, player, card, target);
        break;
      case CardType.combo:
        await _executeComboEffects(battle, player, card, target);
        break;
    }

    return true;
  }

  // Execute spell effects
  Future<void> _executeSpellEffects(BattleState battle, BattlePlayer caster, BattleCard spell, dynamic target) async {
    // Handle different spell types based on abilities
    for (final ability in spell.abilities) {
      switch (ability) {
        case 'strength_scaling':
          final damage = spell.attack! + caster.stats.strength ~/ 2;
          await _dealDamage(battle, target, damage, spell.damageTypes.first, caster);
          break;
        case 'intelligence_scaling':
          final damage = spell.attack! + caster.stats.intelligence ~/ 3;
          await _dealDamage(battle, target, damage, spell.damageTypes.first, caster);
          break;
        case 'burn_chance':
          await _dealDamage(battle, target, spell.attack!, spell.damageTypes.first, caster);
          if (_random.nextDouble() < 0.3) {
            await _applyStatusEffect(target, 'burning', 3);
          }
          break;
        case 'heal':
          await _healTarget(battle, target, spell.attack!, caster);
          break;
        case 'draw_card':
          if (target is BattlePlayer) {
            target.drawCard();
          }
          break;
        case 'mana_restore':
          if (target is BattlePlayer) {
            target.restoreMana(spell.attack!);
          }
          break;
      }
    }

    // Handle special spell keywords
    for (final keyword in spell.keywords) {
      switch (keyword) {
        case 'elemental':
          // Elemental spells have enhanced effects against certain creature types
          break;
        case 'instant':
          // Instant spells can interrupt opponent actions
          break;
        case 'channeled':
          // Channeled spells require multiple turns
          break;
      }
    }
  }

  // Execute creature summon
  Future<void> _executeCreatureSummon(BattleState battle, BattlePlayer summoner, BattleCard creatureCard) async {
    // Creature is already added to battlefield by playCard
    final creature = summoner.battlefield.last;
    
    // Apply summoning effects
    for (final ability in creatureCard.abilities) {
      switch (ability) {
        case 'charge':
          creature.canAttack = true; // Can attack immediately
          break;
        case 'taunt':
          // All enemy attacks must target this creature
          break;
        case 'stealth':
          creature.addStatusEffect('stealth', 2);
          break;
        case 'lifesteal':
          // Heals summoner when dealing damage
          break;
        case 'poisonous':
          // Destroys any creature it damages
          break;
      }
    }

    battle.addLogEntry('${summoner.name} summons ${creatureCard.name}');
  }

  // Deal damage with all calculations
  Future<void> _dealDamage(BattleState battle, dynamic target, int baseDamage, DamageType damageType, BattlePlayer source) async {
    if (target is BattlePlayer) {
      final effectiveDamage = source.stats.calculateDamage(baseDamage, damageType, target.stats);
      target.takeDamage(effectiveDamage, damageType);
      battle.addLogEntry('${target.name} takes $effectiveDamage ${damageType.toString()} damage');
    } else if (target is BattleCreature) {
      final damage = source.stats.rollCriticalHit() ? (baseDamage * 1.5).round() : baseDamage;
      target.takeDamage(damage);
      battle.addLogEntry('${target.card.name} takes $damage damage');
    }
  }

  // Heal target
  Future<void> _healTarget(BattleState battle, dynamic target, int amount, BattlePlayer source) async {
    if (target is BattlePlayer) {
      target.heal(amount);
      battle.addLogEntry('${target.name} heals for $amount');
    } else if (target is BattleCreature) {
      target.heal(amount);
      battle.addLogEntry('${target.card.name} heals for $amount');
    }
  }

  // Apply status effect
  Future<void> _applyStatusEffect(dynamic target, String effect, int duration) async {
    if (target is BattleCreature) {
      target.addStatusEffect(effect, duration);
    }
  }

  // End turn
  Future<void> endTurn(String battleId, String playerId) async {
    final battle = _getBattleById(battleId);
    if (battle == null || battle.isGameOver) return;

    final player = _getPlayerById(battle, playerId);
    if (player == null || !player.isActive) return;

    battle.nextTurn();
    battle.turnPhase = TurnPhase.draw;
    
    battle.addLogEntry('${player.name} ends their turn');
    _battleUpdatesController.add(battle);
    notifyListeners();

    // AI turn if opponent is AI
    final opponent = battle.inactivePlayer;
    if (opponent.id.startsWith('ai_')) {
      await _executeAITurn(battle, opponent);
    }
  }

  // Check battle end conditions
  Future<void> _checkBattleEndConditions(BattleState battle) async {
    if (battle.player1.isDead) {
      battle.endBattle(battle.player2.id);
      await _completeBattle(battle);
    } else if (battle.player2.isDead) {
      battle.endBattle(battle.player1.id);
      await _completeBattle(battle);
    } else if (battle.player1.deck.isEmpty && battle.player1.hand.isEmpty) {
      // Deck exhaustion
      battle.endBattle(battle.player2.id);
      await _completeBattle(battle);
    } else if (battle.player2.deck.isEmpty && battle.player2.hand.isEmpty) {
      battle.endBattle(battle.player1.id);
      await _completeBattle(battle);
    }
  }

  // Complete battle and distribute rewards
  Future<void> _completeBattle(BattleState battle) async {
    _activeBattles.remove(battle);
    if (_currentBattle == battle) {
      _currentBattle = null;
    }

    // Apply rewards to players
    await _applyBattleRewards(battle);
    
    battle.addLogEntry('Battle completed!');
    _battleUpdatesController.add(battle);
    notifyListeners();
  }

  // Apply battle rewards
  Future<void> _applyBattleRewards(BattleState battle) async {
    final winnerRewards = battle.rewards['winner'] as Map<String, dynamic>?;
    final loserRewards = battle.rewards['loser'] as Map<String, dynamic>?;

    if (winnerRewards != null && battle.winnerId != null) {
      await _applyPlayerRewards(battle.winnerId!, winnerRewards);
    }

    // Apply participation rewards to loser
    final loserId = battle.winnerId == battle.player1.id ? battle.player2.id : battle.player1.id;
    if (loserRewards != null) {
      await _applyPlayerRewards(loserId, loserRewards);
    }
  }

  // Apply rewards to specific player
  Future<void> _applyPlayerRewards(String playerId, Map<String, dynamic> rewards) async {
    // This would integrate with character progression system
    print('Applying rewards to $playerId: $rewards');
    
    // Add cards to collection
    final cardRewards = rewards['cards'] as List<String>?;
    if (cardRewards != null) {
      for (final cardReward in cardRewards) {
        await _addCardToCollection(playerId, cardReward);
      }
    }
  }

  // AI BATTLE SYSTEM

  // Initialize AI personalities
  Future<void> _initializeAIPersonalities() async {
    _aiPersonalities.clear();
    
    // Aggressive AI
    _aiPersonalities['aggressive'] = AIPersonality(
      name: 'Aggressive',
      preferredStrategy: AIStrategy.aggressive,
      cardPlayStyle: 'face_damage',
      riskTolerance: 0.8,
      adaptability: 0.3,
    );

    // Defensive AI
    _aiPersonalities['defensive'] = AIPersonality(
      name: 'Defensive',
      preferredStrategy: AIStrategy.defensive,
      cardPlayStyle: 'control',
      riskTolerance: 0.2,
      adaptability: 0.6,
    );

    // Balanced AI
    _aiPersonalities['balanced'] = AIPersonality(
      name: 'Balanced',
      preferredStrategy: AIStrategy.balanced,
      cardPlayStyle: 'tempo',
      riskTolerance: 0.5,
      adaptability: 0.8,
    );

    // Combo AI
    _aiPersonalities['combo'] = AIPersonality(
      name: 'Combo Master',
      preferredStrategy: AIStrategy.combo,
      cardPlayStyle: 'combo',
      riskTolerance: 0.4,
      adaptability: 0.7,
    );
  }

  // Create AI opponent
  BattlePlayer createAIOpponent({
    required CharacterClass characterClass,
    required int level,
    AIPersonality? personality,
  }) {
    personality ??= _aiPersonalities.values.elementAt(_random.nextInt(_aiPersonalities.length));
    
    final stats = _generateAIStats(characterClass, level);
    final deck = _generateAIDeck(characterClass, level, personality);
    
    return BattlePlayer(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      name: '${personality.name} ${characterClass.name.toUpperCase()}',
      characterClass: characterClass,
      stats: stats,
      deck: deck,
    );
  }

  // Generate AI character stats
  CharacterStats _generateAIStats(CharacterClass characterClass, int level) {
    final baseStats = _getClassBaseStats(characterClass);
    final levelMultiplier = 1.0 + (level * 0.1);
    
    return CharacterStats(
      strength: (baseStats['strength']! * levelMultiplier).round(),
      dexterity: (baseStats['dexterity']! * levelMultiplier).round(),
      intelligence: (baseStats['intelligence']! * levelMultiplier).round(),
      vitality: (baseStats['vitality']! * levelMultiplier).round(),
      energy: (baseStats['energy']! * levelMultiplier).round(),
      luck: (baseStats['luck']! * levelMultiplier).round(),
    );
  }

  // Get base stats for character classes
  Map<String, int> _getClassBaseStats(CharacterClass characterClass) {
    switch (characterClass) {
      case CharacterClass.warrior:
        return {'strength': 25, 'dexterity': 15, 'intelligence': 10, 'vitality': 20, 'energy': 10, 'luck': 10};
      case CharacterClass.mage:
        return {'strength': 10, 'dexterity': 15, 'intelligence': 25, 'vitality': 15, 'energy': 20, 'luck': 10};
      case CharacterClass.rogue:
        return {'strength': 15, 'dexterity': 25, 'intelligence': 15, 'vitality': 15, 'energy': 10, 'luck': 15};
      case CharacterClass.paladin:
        return {'strength': 20, 'dexterity': 15, 'intelligence': 15, 'vitality': 20, 'energy': 15, 'luck': 10};
      case CharacterClass.necromancer:
        return {'strength': 10, 'dexterity': 15, 'intelligence': 20, 'vitality': 15, 'energy': 20, 'luck': 15};
      default:
        return {'strength': 15, 'dexterity': 15, 'intelligence': 15, 'vitality': 15, 'energy': 15, 'luck': 15};
    }
  }

  // Generate AI deck
  List<BattleCard> _generateAIDeck(CharacterClass characterClass, int level, AIPersonality personality) {
    final deck = <BattleCard>[];
    
    // Generate 30 cards based on class, level, and personality
    deck.addAll(_cardLibrary.generateDeckForClass(characterClass, level));
    
    // Adjust deck based on AI personality
    _adjustDeckForPersonality(deck, personality);
    
    return deck;
  }

  // Adjust deck composition based on AI personality
  void _adjustDeckForPersonality(List<BattleCard> deck, AIPersonality personality) {
    switch (personality.preferredStrategy) {
      case AIStrategy.aggressive:
        // Add more low-cost, high-damage cards
        break;
      case AIStrategy.defensive:
        // Add more healing and defensive cards
        break;
      case AIStrategy.combo:
        // Add more synergistic cards
        break;
      default:
        break;
    }
  }

  // Execute AI turn
  Future<void> _executeAITurn(BattleState battle, BattlePlayer aiPlayer) async {
    // Wait a bit to simulate thinking
    await Future.delayed(Duration(milliseconds: 1000 + _random.nextInt(2000)));

    final personality = _getAIPersonality(aiPlayer);
    final strategy = _determineAIStrategy(battle, aiPlayer, personality);

    // Execute AI actions based on strategy
    await _executeAIStrategy(battle, aiPlayer, strategy);

    // End AI turn
    await endTurn(battle.id, aiPlayer.id);
  }

  // Get AI personality from player name
  AIPersonality _getAIPersonality(BattlePlayer aiPlayer) {
    for (final personality in _aiPersonalities.values) {
      if (aiPlayer.name.contains(personality.name)) {
        return personality;
      }
    }
    return _aiPersonalities['balanced']!;
  }

  // Determine AI strategy for this turn
  AIStrategy _determineAIStrategy(BattleState battle, BattlePlayer aiPlayer, AIPersonality personality) {
    final opponent = aiPlayer.id == battle.player1.id ? battle.player2 : battle.player1;
    final healthRatio = aiPlayer.currentHealth / aiPlayer.stats.health;
    final opponentHealthRatio = opponent.currentHealth / opponent.stats.health;

    // Adapt strategy based on game state
    if (healthRatio < 0.3 && personality.adaptability > 0.5) {
      return AIStrategy.defensive; // Switch to survival mode
    }
    
    if (opponentHealthRatio < 0.2 && personality.riskTolerance > 0.6) {
      return AIStrategy.aggressive; // Go for the kill
    }

    return personality.preferredStrategy;
  }

  // Execute AI strategy
  Future<void> _executeAIStrategy(BattleState battle, BattlePlayer aiPlayer, AIStrategy strategy) async {
    switch (strategy) {
      case AIStrategy.aggressive:
        await _executeAggressiveStrategy(battle, aiPlayer);
        break;
      case AIStrategy.defensive:
        await _executeDefensiveStrategy(battle, aiPlayer);
        break;
      case AIStrategy.combo:
        await _executeComboStrategy(battle, aiPlayer);
        break;
      case AIStrategy.balanced:
        await _executeBalancedStrategy(battle, aiPlayer);
        break;
    }
  }

  // Execute aggressive AI strategy
  Future<void> _executeAggressiveStrategy(BattleState battle, BattlePlayer aiPlayer) async {
    final opponent = aiPlayer.id == battle.player1.id ? battle.player2 : battle.player1;
    
    // Prioritize direct damage to opponent
    final damageCards = aiPlayer.hand.where((card) => 
      card.targetType == TargetType.opponent && 
      card.canBePlayedBy(aiPlayer.stats, aiPlayer.characterClass, aiPlayer.currentMana)
    ).toList();

    if (damageCards.isNotEmpty) {
      final bestCard = damageCards.reduce((a, b) => 
        (a.attack ?? 0) > (b.attack ?? 0) ? a : b);
      await playCard(battle.id, aiPlayer.id, bestCard, target: opponent);
    }

    // Play creatures that can attack immediately
    final creatureCards = aiPlayer.hand.where((card) => 
      card.type == CardType.creature &&
      card.canBePlayedBy(aiPlayer.stats, aiPlayer.characterClass, aiPlayer.currentMana)
    ).toList();

    if (creatureCards.isNotEmpty) {
      final bestCreature = creatureCards.reduce((a, b) => 
        (a.attack ?? 0) > (b.attack ?? 0) ? a : b);
      await playCard(battle.id, aiPlayer.id, bestCreature);
    }
  }

  // Execute defensive AI strategy  
  Future<void> _executeDefensiveStrategy(BattleState battle, BattlePlayer aiPlayer) async {
    // Prioritize healing and defensive cards
    final healCards = aiPlayer.hand.where((card) => 
      card.abilities.contains('heal') &&
      card.canBePlayedBy(aiPlayer.stats, aiPlayer.characterClass, aiPlayer.currentMana)
    ).toList();

    if (healCards.isNotEmpty && aiPlayer.currentHealth < aiPlayer.stats.health * 0.7) {
      await playCard(battle.id, aiPlayer.id, healCards.first, target: aiPlayer);
    }

    // Play defensive creatures
    final defensiveCreatures = aiPlayer.hand.where((card) => 
      card.type == CardType.creature &&
      (card.defense ?? 0) > (card.attack ?? 0) &&
      card.canBePlayedBy(aiPlayer.stats, aiPlayer.characterClass, aiPlayer.currentMana)
    ).toList();

    if (defensiveCreatures.isNotEmpty) {
      await playCard(battle.id, aiPlayer.id, defensiveCreatures.first);
    }
  }

  // MATCHMAKING SYSTEM

  // Start matchmaking service
  void _startMatchmakingService() {
    Timer.periodic(Duration(seconds: 5), (timer) {
      _processMatchmaking();
    });
  }

  // Add player to matchmaking queue
  Future<void> addToMatchmaking(MatchmakingRequest request) async {
    _matchmakingQueue.add(request);
    print('Added ${request.playerName} to matchmaking queue');
  }

  // Process matchmaking queue
  void _processMatchmaking() {
    if (_matchmakingQueue.length < 2) return;

    final matches = <MatchmakingResult>[];
    final processedRequests = <MatchmakingRequest>[];

    for (int i = 0; i < _matchmakingQueue.length - 1; i++) {
      final request1 = _matchmakingQueue[i];
      
      for (int j = i + 1; j < _matchmakingQueue.length; j++) {
        final request2 = _matchmakingQueue[j];
        
        if (_isGoodMatch(request1, request2)) {
          final match = MatchmakingResult(
            matchId: 'match_${DateTime.now().millisecondsSinceEpoch}',
            player1Id: request1.playerId,
            player2Id: request2.playerId,
            battleType: request1.preferredBattleType,
          );
          
          matches.add(match);
          processedRequests.addAll([request1, request2]);
          _matchFoundController.add(match);
          break;
        }
      }
      
      if (processedRequests.contains(request1)) break;
    }

    // Remove processed requests
    for (final request in processedRequests) {
      _matchmakingQueue.remove(request);
    }
  }

  // Check if two players make a good match
  bool _isGoodMatch(MatchmakingRequest request1, MatchmakingRequest request2) {
    // Check battle type compatibility
    if (request1.preferredBattleType != request2.preferredBattleType) return false;
    
    // Check rating difference (within 200 points)
    final ratingDiff = (request1.playerRating - request2.playerRating).abs();
    if (ratingDiff > 200) return false;
    
    // Check if they're looking for friend matches
    if (request1.friendIds.isNotEmpty) {
      return request1.friendIds.contains(request2.playerId);
    }
    
    return true;
  }

  // CARD AND DECK MANAGEMENT

  // Add card to player collection
  Future<void> _addCardToCollection(String playerId, String cardReward) async {
    if (!_playerCollections.containsKey(playerId)) {
      _playerCollections[playerId] = {};
    }
    
    // Generate random card based on reward type
    final card = _generateCardFromReward(cardReward);
    
    final collection = _playerCollections[playerId]!;
    collection[card.id] = (collection[card.id] ?? 0) + 1;
    
    await _savePlayerData();
  }

  // Generate card from reward string
  BattleCard _generateCardFromReward(String rewardType) {
    // This is where the dynamic card generation comes in
    switch (rewardType) {
      case 'random_common_card':
        return _cardLibrary.generateRandomCard(rarity: 1);
      case 'random_uncommon_card':
        return _cardLibrary.generateRandomCard(rarity: 2);
      case 'random_rare_card':
        return _cardLibrary.generateRandomCard(rarity: 3);
      case 'random_epic_card':
        return _cardLibrary.generateRandomCard(rarity: 4);
      case 'random_legendary_card':
        return _cardLibrary.generateRandomCard(rarity: 5);
      default:
        return _cardLibrary.generateRandomCard(rarity: 1);
    }
  }

  // Build deck for player
  Future<List<BattleCard>> buildDeckForPlayer(String playerId, CharacterClass characterClass) async {
    final collection = _playerCollections[playerId] ?? {};
    return _cardLibrary.buildOptimalDeck(collection, characterClass);
  }

  // UTILITY METHODS

  BattleState? _getBattleById(String battleId) {
    return _activeBattles.firstWhere((battle) => battle.id == battleId, orElse: () => null);
  }

  BattlePlayer? _getPlayerById(BattleState battle, String playerId) {
    if (battle.player1.id == playerId) return battle.player1;
    if (battle.player2.id == playerId) return battle.player2;
    return null;
  }

  // ADVENTURE MODE INTEGRATION

  // Start adventure encounter battle
  Future<BattleState?> startAdventureEncounter(EnemyData enemy, BattlePlayer player) async {
    final aiOpponent = _createAIFromEnemy(enemy);
    
    return await startBattle(
      player1: player,
      player2: aiOpponent,
      type: BattleType.adventure,
      battleConditions: {
        'location': enemy.homeLocation.toJson(),
        'enemy_type': enemy.type.toString(),
        'encounter_bonus': true,
      },
    );
  }

  // Create AI opponent from adventure enemy
  BattlePlayer _createAIFromEnemy(EnemyData enemy) {
    final characterClass = _mapEnemyTypeToClass(enemy.type);
    final level = _calculateEnemyLevel(enemy.strength);
    final personality = _selectPersonalityForEnemy(enemy);
    
    return createAIOpponent(
      characterClass: characterClass,
      level: level,
      personality: personality,
    );
  }

  // Map enemy type to character class
  CharacterClass _mapEnemyTypeToClass(EnemyType enemyType) {
    switch (enemyType) {
      case EnemyType.shadow:
        return CharacterClass.rogue;
      case EnemyType.beast:
        return CharacterClass.barbarian;
      case EnemyType.elemental:
        return CharacterClass.mage;
      case EnemyType.undead:
        return CharacterClass.necromancer;
      case EnemyType.construct:
        return CharacterClass.warrior;
      case EnemyType.dragon:
        return CharacterClass.mage;
      case EnemyType.guardian:
        return CharacterClass.paladin;
      case EnemyType.trickster:
        return CharacterClass.rogue;
      case EnemyType.merchant:
        return CharacterClass.rogue;
      case EnemyType.scholar:
        return CharacterClass.mage;
    }
  }

  // Calculate enemy level from strength
  int _calculateEnemyLevel(EnemyStrength strength) {
    switch (strength) {
      case EnemyStrength.weak:
        return 1 + _random.nextInt(3); // 1-3
      case EnemyStrength.normal:
        return 3 + _random.nextInt(4); // 3-6
      case EnemyStrength.strong:
        return 6 + _random.nextInt(5); // 6-10
      case EnemyStrength.elite:
        return 10 + _random.nextInt(6); // 10-15
      case EnemyStrength.boss:
        return 15 + _random.nextInt(11); // 15-25
    }
  }

  // Select AI personality for enemy
  AIPersonality _selectPersonalityForEnemy(EnemyData enemy) {
    switch (enemy.aggressionLevel) {
      case EnemyAggressionLevel.passive:
        return _aiPersonalities['defensive']!;
      case EnemyAggressionLevel.neutral:
        return _aiPersonalities['balanced']!;
      case EnemyAggressionLevel.aggressive:
      case EnemyAggressionLevel.hostile:
        return _aiPersonalities['aggressive']!;
      case EnemyAggressionLevel.territorial:
        return _aiPersonalities['defensive']!;
    }
  }

  // PLACEHOLDER METHODS FOR MISSING IMPLEMENTATIONS

  Future<void> _executeEnchantmentEffects(BattleState battle, BattlePlayer player, BattleCard card) async {
    // Implement enchantment effects
  }

  Future<void> _executeArtifactEffects(BattleState battle, BattlePlayer player, BattleCard card) async {
    // Implement artifact effects
  }

  Future<void> _executeSkillEffects(BattleState battle, BattlePlayer player, BattleCard card, dynamic target) async {
    // Implement skill effects
  }

  Future<void> _executeComboEffects(BattleState battle, BattlePlayer player, BattleCard card, dynamic target) async {
    // Implement combo effects
  }

  Future<void> _executeComboStrategy(BattleState battle, BattlePlayer aiPlayer) async {
    // Implement combo AI strategy
  }

  Future<void> _executeBalancedStrategy(BattleState battle, BattlePlayer aiPlayer) async {
    // Implement balanced AI strategy
  }

  // DATA PERSISTENCE

  Future<void> _loadPlayerData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load player collections
      final collectionsData = prefs.getString('player_collections');
      if (collectionsData != null) {
        final decoded = json.decode(collectionsData) as Map<String, dynamic>;
        _playerCollections.clear();
        for (final entry in decoded.entries) {
          _playerCollections[entry.key] = Map<String, int>.from(entry.value);
        }
      }
      
      // Load player decks
      final decksData = prefs.getString('player_decks');
      if (decksData != null) {
        // Implementation for loading decks
      }
    } catch (e) {
      print('Error loading player data: $e');
    }
  }

  Future<void> _savePlayerData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save player collections
      await prefs.setString('player_collections', json.encode(_playerCollections));
      
      // Save player decks
      // Implementation for saving decks
    } catch (e) {
      print('Error saving player data: $e');
    }
  }

  Future<void> _loadActiveBattles() async {
    // Load any persistent battle states
  }

  // Dispose
  void dispose() {
    _battleUpdatesController.close();
    _matchFoundController.close();
    super.dispose();
  }
}

// Enhanced AI system classes
class AIPersonality {
  final String name;
  final AIStrategy preferredStrategy;
  final String cardPlayStyle;
  final double riskTolerance; // 0.0 to 1.0
  final double adaptability; // 0.0 to 1.0

  AIPersonality({
    required this.name,
    required this.preferredStrategy,
    required this.cardPlayStyle,
    required this.riskTolerance,
    required this.adaptability,
  });
}

enum AIStrategy {
  aggressive,
  defensive,
  combo,
  balanced,
}

// Tournament system classes
class Tournament {
  final String id;
  final String name;
  final TournamentType type;
  final List<String> participants;
  final Map<String, dynamic> prizes;
  final DateTime startTime;
  final DateTime endTime;
  final TournamentStatus status;

  Tournament({
    required this.id,
    required this.name,
    required this.type,
    required this.participants,
    required this.prizes,
    required this.startTime,
    required this.endTime,
    required this.status,
  });
}

enum TournamentType {
  singleElimination,
  doubleElimination,
  roundRobin,
  swiss,
}

enum TournamentStatus {
  registration,
  active,
  completed,
  cancelled,
}

class TournamentBracket {
  final String tournamentId;
  final List<List<String>> rounds;
  final Map<String, String> matchResults;

  TournamentBracket({
    required this.tournamentId,
    required this.rounds,
    required this.matchResults,
  });
}

// Enhanced card library with dynamic generation
extension CardLibraryExtensions on CardLibrary {
  // Generate random card of specific rarity
  BattleCard generateRandomCard({int rarity = 1}) {
    // Implementation for dynamic card generation based on templates
    return BattleCard(
      name: 'Generated Card',
      description: 'A dynamically generated card',
      type: CardType.spell,
      manaCost: 3,
      attack: 3,
      rarity: rarity,
    );
  }

  // Build optimal deck from collection
  List<BattleCard> buildOptimalDeck(Map<String, int> collection, CharacterClass characterClass) {
    // Implementation for building optimal deck based on collection and class
    return [];
  }
}