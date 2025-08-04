import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../services/event_bus.dart';
import '../../models/character.dart';
import '../../models/card.dart';
import '../../services/character_service.dart';
import 'integration_orchestrator_agent.dart';

/// Character Management Agent - Central hub for all character-related functionality
class CharacterManagementAgent extends BaseAgent {
  static const String agentId = 'character_management';

  final CharacterService _characterService;
  Character? _currentCharacter;
  Timer? _autoSaveTimer;
  
  // XP conversion rates
  static const int stepsPerXp = 100;
  static const int caloriesPerXp = 10;
  static const int minutesExercisePerXp = 5;
  
  // Stat bonuses for activities
  static const Map<String, Map<String, int>> activityStatBonuses = {
    'walking': {'vitality': 1, 'dexterity': 1},
    'running': {'vitality': 2, 'dexterity': 2},
    'cycling': {'vitality': 1, 'dexterity': 2},
    'strength_training': {'strength': 3, 'vitality': 1},
    'yoga': {'dexterity': 2, 'energy': 1},
    'swimming': {'vitality': 2, 'strength': 1, 'dexterity': 1},
  };

  CharacterManagementAgent({
    CharacterService? characterService,
  }) : _characterService = characterService ?? CharacterService(),
        super(agentId: agentId);

  @override
  Future<void> onInitialize() async {
    developer.log('Initializing Character Management Agent', name: agentId);
    
    // Load current character
    await _loadCurrentCharacter();
    
    // Start auto-save timer
    _startAutoSave();
    
    developer.log('Character Management Agent initialized', name: agentId);
  }

  @override
  void subscribeToEvents() {
    // Fitness events
    subscribe(EventTypes.fitnessUpdate, _handleFitnessUpdate);
    subscribe(EventTypes.activityDetected, _handleActivityDetected);
    
    // Battle events
    subscribe(EventTypes.battleResult, _handleBattleResult);
    
    // Quest events
    subscribe(EventTypes.questCompleted, _handleQuestCompleted);
    
    // Card events
    subscribe(EventTypes.cardEquipped, _handleCardEquipped);
    subscribe(EventTypes.cardUnequipped, _handleCardUnequipped);
    
    // Character specific events
    subscribe('character_create', _handleCharacterCreate);
    subscribe('character_load', _handleCharacterLoad);
    subscribe('character_save', _handleCharacterSave);
    subscribe('character_level_up', _handleLevelUp);
    subscribe('character_stat_increase', _handleStatIncrease);
    subscribe('character_skill_unlock', _handleSkillUnlock);
    subscribe('character_equipment_change', _handleEquipmentChange);
    
    // Achievement events
    subscribe(EventTypes.achievementUnlocked, _handleAchievementUnlocked);
  }

  /// Get current character
  Character? get currentCharacter => _currentCharacter;

  /// Create a new character
  Future<Character> createCharacter({
    required String name,
    required CharacterClass characterClass,
    String? backstory,
  }) async {
    developer.log('Creating new character: $name ($characterClass)', name: agentId);
    
    final character = Character(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      characterClass: characterClass,
      level: 1,
      experience: 0,
      baseStats: _getStartingStats(characterClass),
      unallocatedStatPoints: 0,
      unallocatedSkillPoints: 1,
      backstory: backstory,
    );

    await _setCurrentCharacter(character);
    
    // Publish character creation event
    await publishEvent(createEvent(
      eventType: EventTypes.characterUpdated,
      data: CharacterUpdateData(
        characterId: character.id,
      ).toJson(),
    ));

    return character;
  }

  /// Load a character by ID
  Future<void> loadCharacter(String characterId) async {
    developer.log('Loading character: $characterId', name: agentId);
    
    try {
      final character = await _characterService.loadCharacter(characterId);
      await _setCurrentCharacter(character);
      
      // Publish character loaded event
      await publishEvent(createEvent(
        eventType: 'character_loaded',
        data: {'characterId': characterId},
      ));
      
    } catch (e) {
      developer.log('Failed to load character $characterId: $e', name: agentId);
      rethrow;
    }
  }

  /// Save current character
  Future<void> saveCurrentCharacter() async {
    if (_currentCharacter == null) return;
    
    try {
      await _characterService.saveCharacter(_currentCharacter!);
      
      // Publish character saved event
      await publishEvent(createEvent(
        eventType: 'character_saved',
        data: {'characterId': _currentCharacter!.id},
      ));
      
    } catch (e) {
      developer.log('Failed to save character: $e', name: agentId);
      rethrow;
    }
  }

  /// Award XP to current character
  Future<void> awardXp(int xp, {String? source}) async {
    if (_currentCharacter == null || xp <= 0) return;

    developer.log('Awarding $xp XP to character (source: ${source ?? 'unknown'})', name: agentId);

    final oldLevel = _currentCharacter!.level;
    final oldXp = _currentCharacter!.experience;
    
    _currentCharacter = _currentCharacter!.copyWith(
      experience: _currentCharacter!.experience + xp,
    );

    // Check for level up
    final newLevel = _calculateLevel(_currentCharacter!.experience);
    if (newLevel > oldLevel) {
      await _handleLevelUp(oldLevel, newLevel);
    }

    // Publish XP gained event
    await publishEvent(createEvent(
      eventType: EventTypes.characterXpGained,
      data: CharacterUpdateData(
        characterId: _currentCharacter!.id,
        xpGained: xp,
      ).toJson(),
    ));

    // Save character
    await saveCurrentCharacter();
  }

  /// Award items to current character
  Future<void> awardItems(List<String> itemIds, {String? source}) async {
    if (_currentCharacter == null || itemIds.isEmpty) return;

    developer.log('Awarding ${itemIds.length} items to character (source: ${source ?? 'unknown'})', name: agentId);

    // Publish items gained event
    await publishEvent(createEvent(
      eventType: EventTypes.inventoryChanged,
      data: CharacterUpdateData(
        characterId: _currentCharacter!.id,
        itemsGained: itemIds,
      ).toJson(),
    ));
  }

  /// Award stat bonuses for physical activities
  Future<void> awardActivityBonuses(String activityType, int duration) async {
    if (_currentCharacter == null) return;

    final bonuses = activityStatBonuses[activityType.toLowerCase()];
    if (bonuses == null) return;

    developer.log('Awarding activity bonuses for $activityType ($duration minutes)', name: agentId);

    // Calculate bonus based on duration (every 30 minutes gives 1x bonus)
    final multiplier = math.max(1, duration ~/ 30);
    
    final statChanges = <String, dynamic>{};
    for (final entry in bonuses.entries) {
      final bonus = entry.value * multiplier;
      statChanges[entry.key] = bonus;
    }

    // Apply temporary stat bonuses (could be permanent based on design)
    await _applyStatChanges(statChanges, temporary: true);

    // Publish stat changes
    await publishEvent(createEvent(
      eventType: EventTypes.characterStatsChanged,
      data: CharacterUpdateData(
        characterId: _currentCharacter!.id,
        statChanges: statChanges,
      ).toJson(),
    ));
  }

  /// Increase character stat
  Future<void> increasestat(String statName, int amount) async {
    if (_currentCharacter == null) return;

    if (_currentCharacter!.unallocatedStatPoints < amount) {
      developer.log('Not enough stat points to increase $statName by $amount', name: agentId);
      return;
    }

    developer.log('Increasing $statName by $amount', name: agentId);

    final currentStats = Map<String, int>.from(_currentCharacter!.baseStats);
    currentStats[statName] = (currentStats[statName] ?? 0) + amount;

    _currentCharacter = _currentCharacter!.copyWith(
      baseStats: currentStats,
      unallocatedStatPoints: _currentCharacter!.unallocatedStatPoints - amount,
    );

    // Publish stat change event
    await publishEvent(createEvent(
      eventType: EventTypes.characterStatsChanged,
      data: CharacterUpdateData(
        characterId: _currentCharacter!.id,
        statChanges: {statName: amount},
      ).toJson(),
    ));

    await saveCurrentCharacter();
  }

  /// Get character's total stats (including equipment bonuses)
  Map<String, int> getTotalStats() {
    if (_currentCharacter == null) return {};

    final totalStats = Map<String, int>.from(_currentCharacter!.baseStats);
    
    // Add equipment bonuses (this would integrate with the Card System Agent)
    final equipmentBonuses = _calculateEquipmentBonuses();
    for (final entry in equipmentBonuses.entries) {
      totalStats[entry.key] = (totalStats[entry.key] ?? 0) + entry.value;
    }

    return totalStats;
  }

  /// Handle fitness update events
  Future<AgentEventResponse?> _handleFitnessUpdate(AgentEvent event) async {
    final data = FitnessUpdateData.fromJson(event.data);
    
    // Convert fitness data to XP
    int xpGained = 0;
    xpGained += data.steps ~/ stepsPerXp;
    xpGained += data.calories ~/ caloriesPerXp;
    xpGained += data.duration ~/ minutesExercisePerXp;

    if (xpGained > 0) {
      await awardXp(xpGained, source: 'fitness_${data.activityType}');
    }

    // Award activity-specific stat bonuses
    await awardActivityBonuses(data.activityType, data.duration);

    return createResponse(
      originalEventId: event.id,
      responseType: 'fitness_processed',
      data: {'xpGained': xpGained},
    );
  }

  /// Handle activity detected events
  Future<AgentEventResponse?> _handleActivityDetected(AgentEvent event) async {
    final activityType = event.data['activityType'];
    final duration = event.data['duration'] ?? 0;
    
    await awardActivityBonuses(activityType, duration);

    return createResponse(
      originalEventId: event.id,
      responseType: 'activity_processed',
      data: {'processed': true},
    );
  }

  /// Handle battle result events
  Future<AgentEventResponse?> _handleBattleResult(AgentEvent event) async {
    final data = BattleResultData.fromJson(event.data);
    
    if (data.isVictory) {
      // Award XP for victory
      if (data.xpGained > 0) {
        await awardXp(data.xpGained, source: 'battle_victory');
      }

      // Award items
      if (data.itemsGained.isNotEmpty) {
        await awardItems(data.itemsGained, source: 'battle_loot');
      }
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'battle_rewards_processed',
      data: {'processed': true},
    );
  }

  /// Handle quest completed events
  Future<AgentEventResponse?> _handleQuestCompleted(AgentEvent event) async {
    final questId = event.data['questId'];
    final xpReward = event.data['xpReward'] ?? 0;
    final itemRewards = List<String>.from(event.data['itemRewards'] ?? []);

    developer.log('Processing quest completion: $questId', name: agentId);

    if (xpReward > 0) {
      await awardXp(xpReward, source: 'quest_$questId');
    }

    if (itemRewards.isNotEmpty) {
      await awardItems(itemRewards, source: 'quest_$questId');
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'quest_rewards_processed',
      data: {'processed': true},
    );
  }

  /// Handle card equipped events
  Future<AgentEventResponse?> _handleCardEquipped(AgentEvent event) async {
    final cardId = event.data['cardId'];
    final slotType = event.data['slotType'];
    
    developer.log('Card equipped: $cardId in $slotType', name: agentId);

    // Recalculate stats with new equipment
    await _recalculateStats();

    return createResponse(
      originalEventId: event.id,
      responseType: 'equipment_updated',
      data: {'cardId': cardId, 'slotType': slotType},
    );
  }

  /// Handle card unequipped events
  Future<AgentEventResponse?> _handleCardUnequipped(AgentEvent event) async {
    final cardId = event.data['cardId'];
    final slotType = event.data['slotType'];
    
    developer.log('Card unequipped: $cardId from $slotType', name: agentId);

    // Recalculate stats without equipment
    await _recalculateStats();

    return createResponse(
      originalEventId: event.id,
      responseType: 'equipment_updated',
      data: {'cardId': cardId, 'slotType': slotType},
    );
  }

  /// Handle character creation requests
  Future<AgentEventResponse?> _handleCharacterCreate(AgentEvent event) async {
    final name = event.data['name'];
    final className = event.data['class'];
    final backstory = event.data['backstory'];

    final characterClass = CharacterClass.values.firstWhere(
      (c) => c.toString().split('.').last == className,
      orElse: () => CharacterClass.paladin,
    );

    final character = await createCharacter(
      name: name,
      characterClass: characterClass,
      backstory: backstory,
    );

    return createResponse(
      originalEventId: event.id,
      responseType: 'character_created',
      data: {'characterId': character.id},
    );
  }

  /// Handle character load requests
  Future<AgentEventResponse?> _handleCharacterLoad(AgentEvent event) async {
    final characterId = event.data['characterId'];
    
    try {
      await loadCharacter(characterId);
      
      return createResponse(
        originalEventId: event.id,
        responseType: 'character_loaded',
        data: {'characterId': characterId},
      );
    } catch (e) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'character_load_failed',
        data: {'error': e.toString()},
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Handle character save requests
  Future<AgentEventResponse?> _handleCharacterSave(AgentEvent event) async {
    try {
      await saveCurrentCharacter();
      
      return createResponse(
        originalEventId: event.id,
        responseType: 'character_saved',
        data: {'saved': true},
      );
    } catch (e) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'character_save_failed',
        data: {'error': e.toString()},
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Handle level up requests
  Future<AgentEventResponse?> _handleLevelUp(AgentEvent event) async {
    final targetLevel = event.data['targetLevel'];
    
    if (_currentCharacter != null && targetLevel > _currentCharacter!.level) {
      await _handleLevelUp(_currentCharacter!.level, targetLevel);
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'level_up_processed',
      data: {'newLevel': _currentCharacter?.level},
    );
  }

  /// Handle stat increase requests
  Future<AgentEventResponse?> _handleStatIncrease(AgentEvent event) async {
    final statName = event.data['stat'];
    final amount = event.data['amount'] ?? 1;
    
    await increasestat(statName, amount);

    return createResponse(
      originalEventId: event.id,
      responseType: 'stat_increased',
      data: {'stat': statName, 'amount': amount},
    );
  }

  /// Handle skill unlock requests
  Future<AgentEventResponse?> _handleSkillUnlock(AgentEvent event) async {
    final skillId = event.data['skillId'];
    
    // TODO: Implement skill unlock logic
    developer.log('Skill unlock requested: $skillId', name: agentId);

    return createResponse(
      originalEventId: event.id,
      responseType: 'skill_unlocked',
      data: {'skillId': skillId},
    );
  }

  /// Handle equipment change requests
  Future<AgentEventResponse?> _handleEquipmentChange(AgentEvent event) async {
    await _recalculateStats();

    return createResponse(
      originalEventId: event.id,
      responseType: 'equipment_recalculated',
      data: {'totalStats': getTotalStats()},
    );
  }

  /// Handle achievement unlocked events
  Future<AgentEventResponse?> _handleAchievementUnlocked(AgentEvent event) async {
    final achievementId = event.data['achievementId'];
    final xpBonus = event.data['xpBonus'] ?? 0;
    
    developer.log('Achievement unlocked: $achievementId', name: agentId);

    if (xpBonus > 0) {
      await awardXp(xpBonus, source: 'achievement_$achievementId');
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'achievement_processed',
      data: {'achievementId': achievementId},
    );
  }

  /// Load current character from storage
  Future<void> _loadCurrentCharacter() async {
    try {
      // Try to load the last used character
      final characters = await _characterService.getCharacters();
      if (characters.isNotEmpty) {
        _currentCharacter = characters.first;
        developer.log('Loaded character: ${_currentCharacter!.name}', name: agentId);
      }
    } catch (e) {
      developer.log('Failed to load current character: $e', name: agentId);
    }
  }

  /// Set current character
  Future<void> _setCurrentCharacter(Character character) async {
    _currentCharacter = character;
    await saveCurrentCharacter();
  }

  /// Start auto-save timer
  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      saveCurrentCharacter();
    });
  }

  /// Handle level up logic
  Future<void> _handleLevelUp(int oldLevel, int newLevel) async {
    if (_currentCharacter == null) return;

    final levelsGained = newLevel - oldLevel;
    developer.log('Character leveled up from $oldLevel to $newLevel', name: agentId);

    // Award stat and skill points
    final statPointsGained = levelsGained * 5; // 5 stat points per level
    final skillPointsGained = levelsGained; // 1 skill point per level

    _currentCharacter = _currentCharacter!.copyWith(
      level: newLevel,
      unallocatedStatPoints: _currentCharacter!.unallocatedStatPoints + statPointsGained,
      unallocatedSkillPoints: _currentCharacter!.unallocatedSkillPoints + skillPointsGained,
    );

    // Publish level up event
    await publishEvent(createEvent(
      eventType: EventTypes.characterLevelUp,
      data: {
        'characterId': _currentCharacter!.id,
        'oldLevel': oldLevel,
        'newLevel': newLevel,
        'statPointsGained': statPointsGained,
        'skillPointsGained': skillPointsGained,
      },
    ));
  }

  /// Calculate character level from experience
  int _calculateLevel(int experience) {
    // Simple level calculation: level = sqrt(experience / 100) + 1
    return (math.sqrt(experience / 100).floor() + 1).clamp(1, 100);
  }

  /// Get starting stats for a character class
  Map<String, int> _getStartingStats(CharacterClass characterClass) {
    switch (characterClass) {
      case CharacterClass.paladin:
        return {'strength': 25, 'dexterity': 20, 'vitality': 25, 'energy': 15};
      case CharacterClass.barbarian:
        return {'strength': 30, 'dexterity': 20, 'vitality': 25, 'energy': 10};
      case CharacterClass.necromancer:
        return {'strength': 15, 'dexterity': 25, 'vitality': 15, 'energy': 30};
      case CharacterClass.sorceress:
        return {'strength': 10, 'dexterity': 25, 'vitality': 20, 'energy': 30};
      case CharacterClass.amazon:
        return {'strength': 20, 'dexterity': 30, 'vitality': 20, 'energy': 15};
      case CharacterClass.assassin:
        return {'strength': 20, 'dexterity': 30, 'vitality': 20, 'energy': 15};
      case CharacterClass.druid:
        return {'strength': 15, 'dexterity': 20, 'vitality': 25, 'energy': 25};
      case CharacterClass.monk:
        return {'strength': 25, 'dexterity': 25, 'vitality': 20, 'energy': 15};
      case CharacterClass.crusader:
        return {'strength': 25, 'dexterity': 20, 'vitality': 25, 'energy': 15};
      case CharacterClass.witchDoctor:
        return {'strength': 15, 'dexterity': 20, 'vitality': 20, 'energy': 30};
      case CharacterClass.wizard:
        return {'strength': 10, 'dexterity': 25, 'vitality': 20, 'energy': 30};
      case CharacterClass.demonHunter:
        return {'strength': 20, 'dexterity': 30, 'vitality': 20, 'energy': 15};
    }
  }

  /// Calculate equipment bonuses (placeholder - would integrate with Card System Agent)
  Map<String, int> _calculateEquipmentBonuses() {
    // This would be implemented by querying the Card System Agent for equipped items
    return <String, int>{};
  }

  /// Apply stat changes (temporary or permanent)
  Future<void> _applyStatChanges(Map<String, dynamic> changes, {bool temporary = false}) async {
    if (_currentCharacter == null) return;

    if (temporary) {
      // For now, we'll treat temporary bonuses as notifications
      // In a full implementation, this would track temporary effects
      developer.log('Applied temporary stat bonuses: $changes', name: agentId);
    } else {
      // Permanent stat changes
      final currentStats = Map<String, int>.from(_currentCharacter!.baseStats);
      for (final entry in changes.entries) {
        currentStats[entry.key] = (currentStats[entry.key] ?? 0) + (entry.value as int);
      }
      
      _currentCharacter = _currentCharacter!.copyWith(baseStats: currentStats);
      await saveCurrentCharacter();
    }
  }

  /// Recalculate total stats when equipment changes
  Future<void> _recalculateStats() async {
    if (_currentCharacter == null) return;

    // Publish stats recalculated event
    await publishEvent(createEvent(
      eventType: EventTypes.characterStatsChanged,
      data: CharacterUpdateData(
        characterId: _currentCharacter!.id,
        statChanges: getTotalStats(),
      ).toJson(),
    ));
  }

  @override
  Future<void> onDispose() async {
    _autoSaveTimer?.cancel();
    await saveCurrentCharacter();
    developer.log('Character Management Agent disposed', name: agentId);
  }
}