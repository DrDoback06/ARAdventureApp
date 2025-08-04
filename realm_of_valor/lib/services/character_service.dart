import 'dart:math';
import 'package:flutter/foundation.dart';

class CharacterService extends ChangeNotifier {
  static final CharacterService _instance = CharacterService._internal();
  factory CharacterService() => _instance;
  CharacterService._internal();

  Character? _currentCharacter;
  List<Achievement> _achievements = [];
  List<Skill> _skills = [];
  final Random _random = Random();

  // Enhanced Features
  bool _autoLevelUp = true;
  bool _skillProgression = true;
  bool _achievementTracking = true;
  bool _characterCustomization = true;
  bool _experienceMultipliers = true;

  // Getters
  Character? get currentCharacter => _currentCharacter;
  List<Achievement> get achievements => _achievements;
  List<Skill> get skills => _skills;

  // Initialize character
  Future<void> initialize() async {
    // Create default character if none exists
    if (_currentCharacter == null) {
      _currentCharacter = _createDefaultCharacter();
    }
    
    // Initialize achievements
    _initializeAchievements();
    
    // Initialize skills
    _initializeSkills();
  }

  // Create default character
  Character _createDefaultCharacter() {
    return Character(
      id: 'character_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Adventurer',
      level: 1,
      experience: 0,
      experienceToNextLevel: 100,
      health: 100,
      maxHealth: 100,
      stamina: 100,
      maxStamina: 100,
      gold: 50,
      gems: 10,
      reputation: 0,
      achievements: [],
      skills: [],
      equipment: {},
      inventory: [],
      stats: CharacterStats(
        strength: 10,
        agility: 10,
        intelligence: 10,
        endurance: 10,
        luck: 10,
      ),
      isActive: true,
    );
  }

  // Initialize achievements
  void _initializeAchievements() {
    _achievements = [
      Achievement(
        id: 'first_quest',
        title: 'First Steps',
        description: 'Complete your first quest',
        type: AchievementType.quest,
        requirement: 1,
        rewardXP: 50,
        rewardGold: 25,
        isUnlocked: false,
      ),
      Achievement(
        id: 'explorer',
        title: 'Explorer',
        description: 'Visit 10 different locations',
        type: AchievementType.exploration,
        requirement: 10,
        rewardXP: 200,
        rewardGold: 100,
        isUnlocked: false,
      ),
      Achievement(
        id: 'social_butterfly',
        title: 'Social Butterfly',
        description: 'Complete 5 social quests',
        type: AchievementType.social,
        requirement: 5,
        rewardXP: 150,
        rewardGold: 75,
        isUnlocked: false,
      ),
      Achievement(
        id: 'fitness_fanatic',
        title: 'Fitness Fanatic',
        description: 'Complete 10 fitness quests',
        type: AchievementType.fitness,
        requirement: 10,
        rewardXP: 300,
        rewardGold: 150,
        isUnlocked: false,
      ),
      Achievement(
        id: 'treasure_hunter',
        title: 'Treasure Hunter',
        description: 'Collect 20 loot items',
        type: AchievementType.collection,
        requirement: 20,
        rewardXP: 400,
        rewardGold: 200,
        isUnlocked: false,
      ),
    ];
  }

  // Initialize skills
  void _initializeSkills() {
    _skills = [
      Skill(
        id: 'exploration',
        name: 'Exploration',
        description: 'Improves exploration efficiency',
        level: 1,
        experience: 0,
        maxLevel: 10,
        effect: SkillEffect.exploration,
        value: 1.0,
      ),
      Skill(
        id: 'social',
        name: 'Social',
        description: 'Improves social interactions',
        level: 1,
        experience: 0,
        maxLevel: 10,
        effect: SkillEffect.social,
        value: 1.0,
      ),
      Skill(
        id: 'fitness',
        name: 'Fitness',
        description: 'Improves physical performance',
        level: 1,
        experience: 0,
        maxLevel: 10,
        effect: SkillEffect.fitness,
        value: 1.0,
      ),
      Skill(
        id: 'luck',
        name: 'Luck',
        description: 'Increases luck in all activities',
        level: 1,
        experience: 0,
        maxLevel: 10,
        effect: SkillEffect.luck,
        value: 1.0,
      ),
    ];
  }

  // Get current character
  Character getCurrentCharacter() {
    return _currentCharacter ?? _createDefaultCharacter();
  }

  // Add experience to character
  void addExperience(int amount) {
    if (_currentCharacter == null) return;

    _currentCharacter!.experience += amount;
    
    // Check for level up
    while (_currentCharacter!.experience >= _currentCharacter!.experienceToNextLevel) {
      _levelUp();
    }
    
    notifyListeners();
  }

  // Level up character
  void _levelUp() {
    if (_currentCharacter == null) return;

    _currentCharacter!.level++;
    _currentCharacter!.experience -= _currentCharacter!.experienceToNextLevel;
    _currentCharacter!.experienceToNextLevel = _calculateNextLevelExperience();
    
    // Increase stats
    _currentCharacter!.stats.strength += _random.nextInt(3) + 1;
    _currentCharacter!.stats.agility += _random.nextInt(3) + 1;
    _currentCharacter!.stats.intelligence += _random.nextInt(3) + 1;
    _currentCharacter!.stats.endurance += _random.nextInt(3) + 1;
    _currentCharacter!.stats.luck += _random.nextInt(2) + 1;
    
    // Increase health and stamina
    _currentCharacter!.maxHealth += 10;
    _currentCharacter!.health = _currentCharacter!.maxHealth;
    _currentCharacter!.maxStamina += 5;
    _currentCharacter!.stamina = _currentCharacter!.maxStamina;
    
    // Add gold bonus
    _currentCharacter!.gold += _currentCharacter!.level * 10;
    
    notifyListeners();
  }

  // Calculate experience needed for next level
  int _calculateNextLevelExperience() {
    if (_currentCharacter == null) return 100;
    
    // Exponential growth: base * (level ^ 1.5)
    return (100 * pow(_currentCharacter!.level, 1.5)).round();
  }

  // Add gold to character
  void addGold(int amount) {
    if (_currentCharacter == null) return;
    
    _currentCharacter!.gold += amount;
    notifyListeners();
  }

  // Add gems to character
  void addGems(int amount) {
    if (_currentCharacter == null) return;
    
    _currentCharacter!.gems += amount;
    notifyListeners();
  }

  // Add reputation to character
  void addReputation(int amount) {
    if (_currentCharacter == null) return;
    
    _currentCharacter!.reputation += amount;
    notifyListeners();
  }

  // Use stamina
  void useStamina(int amount) {
    if (_currentCharacter == null) return;
    
    _currentCharacter!.stamina = (_currentCharacter!.stamina - amount).clamp(0, _currentCharacter!.maxStamina);
    notifyListeners();
  }

  // Restore stamina
  void restoreStamina(int amount) {
    if (_currentCharacter == null) return;
    
    _currentCharacter!.stamina = (_currentCharacter!.stamina + amount).clamp(0, _currentCharacter!.maxStamina);
    notifyListeners();
  }

  // Add skill experience
  void addSkillExperience(String skillId, int amount) {
    if (!_skillProgression) return;
    
    final skill = _skills.firstWhere((s) => s.id == skillId);
    skill.experience += amount;
    
    // Check for skill level up
    while (skill.experience >= _calculateSkillLevelExperience(skill.level) && skill.level < skill.maxLevel) {
      _skillLevelUp(skill);
    }
    
    notifyListeners();
  }

  // Skill level up
  void _skillLevelUp(Skill skill) {
    skill.level++;
    skill.experience -= _calculateSkillLevelExperience(skill.level - 1);
    skill.value = 1.0 + (skill.level - 1) * 0.2; // 20% increase per level
    
    notifyListeners();
  }

  // Calculate skill level experience
  int _calculateSkillLevelExperience(int level) {
    return 100 * level * level; // Quadratic growth
  }

  // Check and unlock achievements
  void checkAchievements(AchievementType type, int progress) {
    if (!_achievementTracking) return;
    
    for (final achievement in _achievements) {
      if (achievement.type == type && !achievement.isUnlocked) {
        if (progress >= achievement.requirement) {
          _unlockAchievement(achievement);
        }
      }
    }
  }

  // Unlock achievement
  void _unlockAchievement(Achievement achievement) {
    achievement.isUnlocked = true;
    
    // Add rewards
    addExperience(achievement.rewardXP);
    addGold(achievement.rewardGold);
    
    // Add to character's achievements
    if (_currentCharacter != null) {
      _currentCharacter!.achievements.add(achievement.id);
    }
    
    notifyListeners();
  }

  // Get character statistics
  Map<String, dynamic> getCharacterStats() {
    if (_currentCharacter == null) return {};

    return {
      'level': _currentCharacter!.level,
      'experience': _currentCharacter!.experience,
      'experienceToNextLevel': _currentCharacter!.experienceToNextLevel,
      'health': _currentCharacter!.health,
      'maxHealth': _currentCharacter!.maxHealth,
      'stamina': _currentCharacter!.stamina,
      'maxStamina': _currentCharacter!.maxStamina,
      'gold': _currentCharacter!.gold,
      'gems': _currentCharacter!.gems,
      'reputation': _currentCharacter!.reputation,
      'achievements': _currentCharacter!.achievements.length,
      'skills': _skills.length,
      'strength': _currentCharacter!.stats.strength,
      'agility': _currentCharacter!.stats.agility,
      'intelligence': _currentCharacter!.stats.intelligence,
      'endurance': _currentCharacter!.stats.endurance,
      'luck': _currentCharacter!.stats.luck,
    };
  }

  // Enhanced Features

  // Toggle auto level up
  void toggleAutoLevelUp() {
    _autoLevelUp = !_autoLevelUp;
  }

  // Toggle skill progression
  void toggleSkillProgression() {
    _skillProgression = !_skillProgression;
  }

  // Toggle achievement tracking
  void toggleAchievementTracking() {
    _achievementTracking = !_achievementTracking;
  }

  // Toggle character customization
  void toggleCharacterCustomization() {
    _characterCustomization = !_characterCustomization;
  }

  // Toggle experience multipliers
  void toggleExperienceMultipliers() {
    _experienceMultipliers = !_experienceMultipliers;
  }

  // Get experience multiplier
  double getExperienceMultiplier() {
    if (!_experienceMultipliers) return 1.0;
    
    double multiplier = 1.0;
    
    // Add skill bonuses
    for (final skill in _skills) {
      if (skill.effect == SkillEffect.exploration) {
        multiplier += (skill.value - 1.0) * 0.1; // 10% of skill bonus
      }
    }
    
    return multiplier;
  }

  // Dispose
  void dispose() {
    _achievements.clear();
    _skills.clear();
  }
}

// Character Models
class Character {
  final String id;
  final String name;
  int level;
  int experience;
  int experienceToNextLevel;
  int health;
  int maxHealth;
  int stamina;
  int maxStamina;
  int gold;
  int gems;
  int reputation;
  List<String> achievements;
  List<String> skills;
  Map<String, dynamic> equipment;
  List<String> inventory;
  CharacterStats stats;
  bool isActive;

  Character({
    required this.id,
    required this.name,
    required this.level,
    required this.experience,
    required this.experienceToNextLevel,
    required this.health,
    required this.maxHealth,
    required this.stamina,
    required this.maxStamina,
    required this.gold,
    required this.gems,
    required this.reputation,
    List<String>? achievements,
    List<String>? skills,
    Map<String, dynamic>? equipment,
    List<String>? inventory,
    required this.stats,
    this.isActive = true,
  })  : achievements = achievements ?? [],
        skills = skills ?? [],
        equipment = equipment ?? {},
        inventory = inventory ?? [];
}

class CharacterStats {
  int strength;
  int agility;
  int intelligence;
  int endurance;
  int luck;

  CharacterStats({
    required this.strength,
    required this.agility,
    required this.intelligence,
    required this.endurance,
    required this.luck,
  });
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final AchievementType type;
  final int requirement;
  final int rewardXP;
  final int rewardGold;
  bool isUnlocked;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.requirement,
    required this.rewardXP,
    required this.rewardGold,
    this.isUnlocked = false,
  });
}

enum AchievementType {
  quest,
  exploration,
  social,
  fitness,
  collection,
  battle,
  time,
  weather,
}

class Skill {
  final String id;
  final String name;
  final String description;
  int level;
  int experience;
  final int maxLevel;
  final SkillEffect effect;
  double value;

  Skill({
    required this.id,
    required this.name,
    required this.description,
    required this.level,
    required this.experience,
    required this.maxLevel,
    required this.effect,
    required this.value,
  });
}

enum SkillEffect {
  exploration,
  social,
  fitness,
  luck,
}