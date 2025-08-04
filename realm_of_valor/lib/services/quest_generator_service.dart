import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/weather_model.dart' hide WeatherCondition;

import '../models/quest_model.dart';
import '../config/api_config.dart';
import 'dungeon_master_service.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';

class QuestGeneratorService extends ChangeNotifier {
  static final QuestGeneratorService _instance = QuestGeneratorService._internal();
  factory QuestGeneratorService() => _instance;
  QuestGeneratorService._internal();

  List<AdventureQuest> _activeQuests = [];
  List<QuestChain> _questChains = [];
  final Random _random = Random();

  // Enhanced Features
  bool _dynamicQuestGeneration = true;
  bool _questChainsEnabled = true;
  bool _weatherBasedQuests = true;
  bool _timeBasedQuests = true;
  bool _difficultyScaling = true;

  // Getters
  List<AdventureQuest> get activeQuests => _activeQuests;
  List<QuestChain> get questChains => _questChains;

  // Generate quests around the player's location
  Future<List<AdventureQuest>> generateQuests(UserLocation location, double radius) async {
    debugPrint('[QuestGeneratorService] Generating quests around location: ${location.latitude}, ${location.longitude} with radius: $radius');
    final quests = <AdventureQuest>[];
    final numQuests = 5 + _random.nextInt(5); // 5-10 quests
    debugPrint('[QuestGeneratorService] Will generate $numQuests base quests');

    for (int i = 0; i < numQuests; i++) {
      final questLocation = _generateRandomLocation(location, radius);
      final difficulty = _calculateDifficulty(QuestType.exploration);
      
      quests.add(AdventureQuest(
        id: 'quest_${DateTime.now().millisecondsSinceEpoch}_$i',
        title: _generateExplorationTitle(),
        description: _generateExplorationDescription(),
        type: QuestType.exploration,
        difficulty: difficulty,
        location: questLocation,
        radius: 50.0,
        rewardXP: _calculateRewardXP(difficulty),
        rewardGold: _calculateRewardGold(difficulty),
        rewards: _generateRewards(difficulty),
        expirationTime: DateTime.now().add(const Duration(hours: 2)),
        isActive: false,
        isCompleted: false,
      ));
    }

    // Add other quest types
    quests.addAll(_generateSocialQuests(location, radius));
    quests.addAll(_generateFitnessQuests(location, radius));
    quests.addAll(_generateCollectionQuests(location, radius));
    quests.addAll(_generateBattleQuests(location, radius));
    quests.addAll(_generateWalkingQuests(location, radius));
    quests.addAll(_generateRunningQuests(location, radius));
    quests.addAll(_generateClimbingQuests(location, radius));
    quests.addAll(_generateLocationQuests(location, radius));
    quests.addAll(_generateTimeBasedQuests(location, radius));
    quests.addAll(_generateWeatherBasedQuests(location, radius));

    return quests;
  }

  // Generate exploration quests
  List<AdventureQuest> _generateExplorationQuests(UserLocation location, double radius) {
    final quests = <AdventureQuest>[];
    final numQuests = 3 + _random.nextInt(3);

    for (int i = 0; i < numQuests; i++) {
      final questLocation = _generateRandomLocation(location, radius);
      final difficulty = _calculateDifficulty(QuestType.exploration);
      
      quests.add(AdventureQuest(
        id: 'exploration_${DateTime.now().millisecondsSinceEpoch}_$i',
        title: _generateExplorationTitle(),
        description: _generateExplorationDescription(),
        type: QuestType.exploration,
        difficulty: difficulty,
        location: questLocation,
        radius: 50.0,
        rewardXP: _calculateRewardXP(difficulty),
        rewardGold: _calculateRewardGold(difficulty),
        rewards: _generateRewards(difficulty),
        expirationTime: DateTime.now().add(Duration(hours: 2 + _random.nextInt(4))),
        isActive: false,
        isCompleted: false,
      ));
    }

    return quests;
  }

  // Generate social quests
  List<AdventureQuest> _generateSocialQuests(UserLocation location, double radius) {
    final quests = <AdventureQuest>[];
    final numQuests = 2 + _random.nextInt(2);

    for (int i = 0; i < numQuests; i++) {
      final questLocation = _generateRandomLocation(location, radius);
      final difficulty = _calculateDifficulty(QuestType.social);
      
      quests.add(AdventureQuest(
        id: 'social_${DateTime.now().millisecondsSinceEpoch}_$i',
        title: _generateSocialTitle(),
        description: _generateSocialDescription(),
        type: QuestType.social,
        difficulty: difficulty,
        location: questLocation,
        radius: 100.0,
        rewardXP: _calculateRewardXP(difficulty),
        rewardGold: _calculateRewardGold(difficulty),
        rewards: _generateRewards(difficulty),
        expirationTime: DateTime.now().add(Duration(hours: 4 + _random.nextInt(6))),
        isActive: false,
        isCompleted: false,
      ));
    }

    return quests;
  }

  // Generate fitness quests
  List<AdventureQuest> _generateFitnessQuests(UserLocation location, double radius) {
    final quests = <AdventureQuest>[];
    final numQuests = 2 + _random.nextInt(3);

    for (int i = 0; i < numQuests; i++) {
      final questLocation = _generateRandomLocation(location, radius);
      final difficulty = _calculateDifficulty(QuestType.fitness);
      
      quests.add(AdventureQuest(
        id: 'fitness_${DateTime.now().millisecondsSinceEpoch}_$i',
        title: _generateFitnessTitle(),
        description: _generateFitnessDescription(),
        type: QuestType.fitness,
        difficulty: difficulty,
        location: questLocation,
        radius: 75.0,
        rewardXP: _calculateRewardXP(difficulty) * 2, // Double XP for fitness
        rewardGold: _calculateRewardGold(difficulty),
        rewards: _generateRewards(difficulty),
        expirationTime: DateTime.now().add(Duration(hours: 3 + _random.nextInt(4))),
        isActive: false,
        isCompleted: false,
      ));
    }

    return quests;
  }

  // Generate collection quests
  List<AdventureQuest> _generateCollectionQuests(UserLocation location, double radius) {
    final quests = <AdventureQuest>[];
    final numQuests = 2 + _random.nextInt(2);

    for (int i = 0; i < numQuests; i++) {
      final questLocation = _generateRandomLocation(location, radius);
      final difficulty = _calculateDifficulty(QuestType.collection);
      
      quests.add(AdventureQuest(
        id: 'collection_${DateTime.now().millisecondsSinceEpoch}_$i',
        title: _generateCollectionTitle(),
        description: _generateCollectionDescription(),
        type: QuestType.collection,
        difficulty: difficulty,
        location: questLocation,
        radius: 60.0,
        rewardXP: _calculateRewardXP(difficulty),
        rewardGold: _calculateRewardGold(difficulty) * 2, // Double gold for collection
        rewards: _generateRewards(difficulty),
        expirationTime: DateTime.now().add(Duration(hours: 6 + _random.nextInt(8))),
        isActive: false,
        isCompleted: false,
      ));
    }

    return quests;
  }

  // Generate battle quests
  List<AdventureQuest> _generateBattleQuests(UserLocation location, double radius) {
    final quests = <AdventureQuest>[];
    final numQuests = 1 + _random.nextInt(2);

    for (int i = 0; i < numQuests; i++) {
      final questLocation = _generateRandomLocation(location, radius);
      final difficulty = _calculateDifficulty(QuestType.battle);
      
      quests.add(AdventureQuest(
        id: 'battle_${DateTime.now().millisecondsSinceEpoch}_$i',
        title: _generateBattleTitle(),
        description: _generateBattleDescription(),
        type: QuestType.battle,
        difficulty: difficulty,
        location: questLocation,
        radius: 80.0,
        rewardXP: _calculateRewardXP(difficulty) * 3, // Triple XP for battles
        rewardGold: _calculateRewardGold(difficulty) * 2, // Double gold for battles
        rewards: _generateRewards(difficulty),
        expirationTime: DateTime.now().add(Duration(hours: 8 + _random.nextInt(12))),
        isActive: false,
        isCompleted: false,
      ));
    }

    return quests;
  }

  // Generate walking quests
  List<AdventureQuest> _generateWalkingQuests(UserLocation location, double radius) {
    final quests = <AdventureQuest>[];
    final numQuests = 2 + _random.nextInt(3);

    for (int i = 0; i < numQuests; i++) {
      final questLocation = _generateRandomLocation(location, radius);
      final difficulty = _calculateDifficulty(QuestType.walking);
      
      quests.add(AdventureQuest(
        id: 'walking_${DateTime.now().millisecondsSinceEpoch}_$i',
        title: _generateWalkingTitle(),
        description: _generateWalkingDescription(),
        type: QuestType.walking,
        difficulty: difficulty,
        location: questLocation,
        radius: 40.0,
        rewardXP: _calculateRewardXP(difficulty),
        rewardGold: _calculateRewardGold(difficulty),
        rewards: _generateRewards(difficulty),
        expirationTime: DateTime.now().add(Duration(hours: 1 + _random.nextInt(3))),
        isActive: false,
        isCompleted: false,
      ));
    }

    return quests;
  }

  // Generate running quests
  List<AdventureQuest> _generateRunningQuests(UserLocation location, double radius) {
    final quests = <AdventureQuest>[];
    final numQuests = 1 + _random.nextInt(2);

    for (int i = 0; i < numQuests; i++) {
      final questLocation = _generateRandomLocation(location, radius);
      final difficulty = _calculateDifficulty(QuestType.running);
      
      quests.add(AdventureQuest(
        id: 'running_${DateTime.now().millisecondsSinceEpoch}_$i',
        title: _generateRunningTitle(),
        description: _generateRunningDescription(),
        type: QuestType.running,
        difficulty: difficulty,
        location: questLocation,
        radius: 120.0,
        rewardXP: _calculateRewardXP(difficulty) * 2, // Double XP for running
        rewardGold: _calculateRewardGold(difficulty),
        rewards: _generateRewards(difficulty),
        expirationTime: DateTime.now().add(Duration(hours: 2 + _random.nextInt(4))),
        isActive: false,
        isCompleted: false,
      ));
    }

    return quests;
  }

  // Generate climbing quests
  List<AdventureQuest> _generateClimbingQuests(UserLocation location, double radius) {
    final quests = <AdventureQuest>[];
    final numQuests = 1 + _random.nextInt(2);

    for (int i = 0; i < numQuests; i++) {
      final questLocation = _generateRandomLocation(location, radius);
      final difficulty = _calculateDifficulty(QuestType.climbing);
      
      quests.add(AdventureQuest(
        id: 'climbing_${DateTime.now().millisecondsSinceEpoch}_$i',
        title: _generateClimbingTitle(),
        description: _generateClimbingDescription(),
        type: QuestType.climbing,
        difficulty: difficulty,
        location: questLocation,
        radius: 90.0,
        rewardXP: _calculateRewardXP(difficulty) * 2, // Double XP for climbing
        rewardGold: _calculateRewardGold(difficulty),
        rewards: _generateRewards(difficulty),
        expirationTime: DateTime.now().add(Duration(hours: 4 + _random.nextInt(6))),
        isActive: false,
        isCompleted: false,
      ));
    }

    return quests;
  }

  // Generate location quests
  List<AdventureQuest> _generateLocationQuests(UserLocation location, double radius) {
    final quests = <AdventureQuest>[];
    final numQuests = 2 + _random.nextInt(3);

    for (int i = 0; i < numQuests; i++) {
      final questLocation = _generateRandomLocation(location, radius);
      final difficulty = _calculateDifficulty(QuestType.location);
      
      quests.add(AdventureQuest(
        id: 'location_${DateTime.now().millisecondsSinceEpoch}_$i',
        title: _generateLocationTitle(),
        description: _generateLocationDescription(),
        type: QuestType.location,
        difficulty: difficulty,
        location: questLocation,
        radius: 70.0,
        rewardXP: _calculateRewardXP(difficulty),
        rewardGold: _calculateRewardGold(difficulty),
        rewards: _generateRewards(difficulty),
        expirationTime: DateTime.now().add(Duration(hours: 3 + _random.nextInt(5))),
        isActive: false,
        isCompleted: false,
      ));
    }

    return quests;
  }

  // Generate time-based quests
  List<AdventureQuest> _generateTimeBasedQuests(UserLocation location, double radius) {
    if (!_timeBasedQuests) return [];

    final quests = <AdventureQuest>[];
    final currentHour = DateTime.now().hour;
    
    // Morning quests (6-10 AM)
    if (currentHour >= 6 && currentHour <= 10) {
      quests.add(_generateMorningQuest(location, radius));
    }
    
    // Evening quests (6-10 PM)
    if (currentHour >= 18 && currentHour <= 22) {
      quests.add(_generateEveningQuest(location, radius));
    }
    
    // Night quests (10 PM - 6 AM)
    if (currentHour >= 22 || currentHour <= 6) {
      quests.add(_generateNightQuest(location, radius));
    }

    return quests;
  }

  // Generate weather-based quests
  List<AdventureQuest> _generateWeatherBasedQuests(UserLocation location, double radius) {
    if (!_weatherBasedQuests) return [];

    final quests = <AdventureQuest>[];
    
    // This would be connected to weather service
    // For now, generate random weather quests
    if (_random.nextBool()) {
      quests.add(_generateWeatherQuest(location, radius));
    }

    return quests;
  }

  // Generate random location within radius
  LatLng _generateRandomLocation(UserLocation center, double radius) {
    final angle = _random.nextDouble() * 2 * pi;
    final distance = _random.nextDouble() * radius * 1000; // Convert to meters

    final latOffset = distance * cos(angle) / 111000; // Approximate meters to degrees
    final lngOffset = distance * sin(angle) / (111000 * cos(center.latitude * pi / 180));

    return LatLng(
      center.latitude + latOffset,
      center.longitude + lngOffset,
    );
  }

  // Calculate quest difficulty
  QuestDifficulty _calculateDifficulty(QuestType type) {
    switch (type) {
      case QuestType.exploration:
        return QuestDifficulty.medium;
      case QuestType.social:
        return QuestDifficulty.easy;
      case QuestType.fitness:
        return QuestDifficulty.hard;
      case QuestType.collection:
        return QuestDifficulty.medium;
      case QuestType.battle:
        return QuestDifficulty.hard;
      case QuestType.time:
        return QuestDifficulty.medium;
      case QuestType.weather:
        return QuestDifficulty.hard;
      case QuestType.walking:
        return QuestDifficulty.easy;
      case QuestType.running:
        return QuestDifficulty.medium;
      case QuestType.climbing:
        return QuestDifficulty.hard;
      case QuestType.location:
        return QuestDifficulty.medium;
    }
  }

  // Calculate distance between two points
  double _calculateDistance(UserLocation start, LatLng end) {
    const double earthRadius = 6371000; // meters

    final double dLat = (end.latitude - start.latitude) * (pi / 180);
    final double dLon = (end.longitude - start.longitude) * (pi / 180);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(start.latitude * (pi / 180)) * cos(end.latitude * (pi / 180)) *
        sin(dLon / 2) * sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  // Calculate reward XP based on difficulty
  int _calculateRewardXP(QuestDifficulty difficulty) {
    switch (difficulty) {
      case QuestDifficulty.easy:
        return 50 + _random.nextInt(50);
      case QuestDifficulty.medium:
        return 100 + _random.nextInt(100);
      case QuestDifficulty.hard:
        return 200 + _random.nextInt(150);
      case QuestDifficulty.epic:
        return 400 + _random.nextInt(300);
    }
  }

  // Calculate reward gold based on difficulty
  int _calculateRewardGold(QuestDifficulty difficulty) {
    switch (difficulty) {
      case QuestDifficulty.easy:
        return 10 + _random.nextInt(20);
      case QuestDifficulty.medium:
        return 30 + _random.nextInt(40);
      case QuestDifficulty.hard:
        return 70 + _random.nextInt(60);
      case QuestDifficulty.epic:
        return 150 + _random.nextInt(100);
    }
  }

  // Generate rewards based on difficulty
  List<QuestReward> _generateRewards(QuestDifficulty difficulty) {
    final rewards = <QuestReward>[];
    
    // Add base rewards
    rewards.add(QuestReward(
      type: RewardType.xp,
      amount: _calculateRewardXP(difficulty),
      description: 'Experience Points',
    ));
    
    rewards.add(QuestReward(
      type: RewardType.gold,
      amount: _calculateRewardGold(difficulty),
      description: 'Gold Coins',
    ));

    // Add item rewards based on difficulty and quest type
    final itemRewards = _generateItemRewards(difficulty);
    rewards.addAll(itemRewards);

    return rewards;
  }

  // Generate item rewards based on difficulty
  List<QuestReward> _generateItemRewards(QuestDifficulty difficulty) {
    final rewards = <QuestReward>[];
    
    // Base chance for items based on difficulty
    double itemChance;
    switch (difficulty) {
      case QuestDifficulty.easy:
        itemChance = 0.1; // 10% chance
        break;
      case QuestDifficulty.medium:
        itemChance = 0.3; // 30% chance
        break;
      case QuestDifficulty.hard:
        itemChance = 0.6; // 60% chance
        break;
      case QuestDifficulty.epic:
        itemChance = 0.9; // 90% chance
        break;
    }

    if (_random.nextDouble() < itemChance) {
      final item = _generateRandomItem(difficulty);
      rewards.add(QuestReward(
        type: RewardType.item,
        amount: item['amount'],
        description: item['description'],
      ));
    }

    // Epic quests can have multiple items
    if (difficulty == QuestDifficulty.epic && _random.nextBool()) {
      final secondItem = _generateRandomItem(difficulty);
      rewards.add(QuestReward(
        type: RewardType.item,
        amount: secondItem['amount'],
        description: secondItem['description'],
      ));
    }

    return rewards;
  }

  // Generate a random item based on difficulty
  Map<String, dynamic> _generateRandomItem(QuestDifficulty difficulty) {
    final items = <Map<String, dynamic>>[];
    
    // Common items (all difficulties)
    items.addAll([
      {'description': 'Health Potion', 'amount': 1 + _random.nextInt(3)},
      {'description': 'Mana Potion', 'amount': 1 + _random.nextInt(3)},
      {'description': 'Basic Sword', 'amount': 1},
      {'description': 'Leather Armor', 'amount': 1},
      {'description': 'Small Shield', 'amount': 1},
    ]);

    // Uncommon items (medium and up)
    if (difficulty != QuestDifficulty.easy) {
      items.addAll([
        {'description': 'Steel Sword', 'amount': 1},
        {'description': 'Chain Mail', 'amount': 1},
        {'description': 'Magic Scroll', 'amount': 1},
        {'description': 'Healing Crystal', 'amount': 1},
        {'description': 'Rare Herb', 'amount': 2 + _random.nextInt(3)},
      ]);
    }

    // Rare items (hard and epic)
    if (difficulty == QuestDifficulty.hard || difficulty == QuestDifficulty.epic) {
      items.addAll([
        {'description': 'Rare Steel Sword', 'amount': 1},
        {'description': 'Mystic Armor', 'amount': 1},
        {'description': 'Ancient Scroll', 'amount': 1},
        {'description': 'Dragon Scale', 'amount': 1},
        {'description': 'Epic Potion', 'amount': 1},
        {'description': 'Treasure Map', 'amount': 1},
      ]);
    }

    // Epic items (epic difficulty only)
    if (difficulty == QuestDifficulty.epic) {
      items.addAll([
        {'description': 'Legendary Sword', 'amount': 1},
        {'description': 'Dragon Armor', 'amount': 1},
        {'description': 'Mythic Scroll', 'amount': 1},
        {'description': 'Phoenix Feather', 'amount': 1},
        {'description': 'Ancient Relic', 'amount': 1},
        {'description': 'Crystal of Power', 'amount': 1},
      ]);
    }

    return items[_random.nextInt(items.length)];
  }

  // Quest title generators
  String _generateExplorationTitle() {
    final titles = [
      'Hidden Treasure Hunt',
      'Ancient Ruins Discovery',
      'Secret Garden Path',
      'Mysterious Cave Entrance',
      'Lost Temple Quest',
      'Forgotten Landmark',
      'Sacred Grove Visit',
      'Historic Site Exploration',
    ];
    return titles[_random.nextInt(titles.length)];
  }

  String _generateSocialTitle() {
    final titles = [
      'Community Meetup',
      'Local Festival Visit',
      'Cafe Social Hour',
      'Pub Night Adventure',
      'Restaurant Discovery',
      'Market Place Visit',
      'Cultural Event',
      'Social Gathering',
    ];
    return titles[_random.nextInt(titles.length)];
  }

  String _generateFitnessTitle() {
    final titles = [
      'Morning Run Challenge',
      'Hiking Adventure',
      'Cycling Route',
      'Park Workout',
      'Trail Exploration',
      'Fitness Challenge',
      'Endurance Test',
      'Strength Training',
    ];
    return titles[_random.nextInt(titles.length)];
  }

  String _generateCollectionTitle() {
    final titles = [
      'Artifact Collection',
      'Herb Gathering',
      'Mineral Discovery',
      'Photo Collection',
      'Souvenir Hunt',
      'Treasure Map Quest',
      'Relic Recovery',
      'Collector\'s Challenge',
    ];
    return titles[_random.nextInt(titles.length)];
  }

  String _generateBattleTitle() {
    final titles = [
      'Monster Encounter',
      'Guardian Challenge',
      'Boss Battle',
      'Arena Combat',
      'Duel Challenge',
      'Warrior\'s Test',
      'Combat Training',
      'Epic Showdown',
    ];
    return titles[_random.nextInt(titles.length)];
  }

  String _generateWalkingTitle() {
    final titles = [
      'City Walk',
      'Local Tour',
      'Sightseeing',
      'Historical Walk',
      'Artistic Tour',
      'Cultural Journey',
      'Discovery Walk',
      'Walking Adventure',
    ];
    return titles[_random.nextInt(titles.length)];
  }

  String _generateRunningTitle() {
    final titles = [
      'Morning Run',
      'Evening Jog',
      'Fitness Challenge',
      'Endurance Test',
      'Running Adventure',
      'Challenge Run',
      'Speed Workout',
      'Run for Fun',
    ];
    return titles[_random.nextInt(titles.length)];
  }

  String _generateClimbingTitle() {
    final titles = [
      'Mountain Climb',
      'Rocky Ascent',
      'Hiking Challenge',
      'Trail Challenge',
      'Climbing Adventure',
      'Mountain Challenge',
      'Endurance Climb',
      'Strength Test',
    ];
    return titles[_random.nextInt(titles.length)];
  }

  String _generateLocationTitle() {
    final titles = [
      'Local Landmark',
      'Historical Site',
      'Interesting Place',
      'Unique Location',
      'Interesting Spot',
      'Interesting Area',
      'Interesting Location',
      'Interesting Place',
    ];
    return titles[_random.nextInt(titles.length)];
  }

  // Quest description generators
  String _generateExplorationDescription() {
    final descriptions = [
      'Explore the hidden corners of this mysterious location and discover its secrets.',
      'Venture into the unknown and uncover ancient mysteries waiting to be found.',
      'Navigate through challenging terrain to reach a legendary discovery.',
      'Follow the clues to uncover a long-lost treasure hidden in plain sight.',
    ];
    return descriptions[_random.nextInt(descriptions.length)];
  }

  String _generateSocialDescription() {
    final descriptions = [
      'Connect with fellow adventurers and share stories of your journey.',
      'Join the local community in celebration and make new friends.',
      'Experience the vibrant culture and traditions of this area.',
      'Participate in social activities and strengthen community bonds.',
    ];
    return descriptions[_random.nextInt(descriptions.length)];
  }

  String _generateFitnessDescription() {
    final descriptions = [
      'Push your physical limits and test your endurance in this challenging quest.',
      'Complete a demanding fitness challenge to prove your strength and stamina.',
      'Navigate through difficult terrain while maintaining peak physical condition.',
      'Endure a grueling workout that will test your mental and physical fortitude.',
    ];
    return descriptions[_random.nextInt(descriptions.length)];
  }

  String _generateCollectionDescription() {
    final descriptions = [
      'Gather rare and valuable items scattered throughout the area.',
      'Search for hidden artifacts that hold great historical significance.',
      'Collect unique specimens and materials for your personal collection.',
      'Follow a treasure map to discover valuable loot and rare items.',
    ];
    return descriptions[_random.nextInt(descriptions.length)];
  }

  String _generateBattleDescription() {
    final descriptions = [
      'Face off against powerful enemies in an epic battle for glory.',
      'Test your combat skills against formidable opponents.',
      'Prove your worth in a challenging arena battle.',
      'Engage in intense combat to earn respect and rewards.',
    ];
    return descriptions[_random.nextInt(descriptions.length)];
  }

  String _generateWalkingDescription() {
    final descriptions = [
      'Take a leisurely stroll through the city or explore nearby landmarks.',
      'Discover hidden gems and interesting spots in your local area.',
      'Visit historical sites and cultural landmarks on foot.',
      'Explore the city on a guided walking tour.',
      'Discover the beauty of your local environment on a leisurely walk.',
      'Take a cultural journey and learn about the history of your area.',
      'Go on a discovery walk and find unique places.',
      'Enjoy a leisurely walk and discover new things.',
    ];
    return descriptions[_random.nextInt(descriptions.length)];
  }

  String _generateRunningDescription() {
    final descriptions = [
      'Complete a demanding morning run to start your day.',
      'Push your physical limits and test your endurance in this challenging run.',
      'Navigate through difficult terrain while maintaining peak physical condition.',
      'Endure a grueling workout that will test your mental and physical fortitude.',
      'Complete a demanding fitness challenge to prove your strength and stamina.',
      'Challenge your body and mind in this demanding run.',
      'Push your limits and test your endurance in this challenging run.',
      'Endure a grueling workout that will test your mental and physical fortitude.',
    ];
    return descriptions[_random.nextInt(descriptions.length)];
  }

  String _generateClimbingDescription() {
    final descriptions = [
      'Climb a mountain or a challenging trail to test your endurance.',
      'Complete a demanding fitness challenge to prove your strength and stamina.',
      'Navigate through difficult terrain while maintaining peak physical condition.',
      'Endure a grueling workout that will test your mental and physical fortitude.',
      'Challenge your body and mind in this demanding climb.',
      'Push your limits and test your endurance in this challenging climb.',
      'Endure a grueling workout that will test your mental and physical fortitude.',
      'Push your limits and test your endurance in this challenging climb.',
    ];
    return descriptions[_random.nextInt(descriptions.length)];
  }

  String _generateLocationDescription() {
    final descriptions = [
      'Visit a local landmark or historical site to learn about its history.',
      'Discover a unique location or interesting spot in your area.',
      'Visit a cultural landmark or interesting place in your local area.',
      'Explore the beauty of your local environment and find unique places.',
      'Discover a unique location or interesting spot in your area.',
      'Visit a cultural landmark or interesting place in your local area.',
      'Explore the beauty of your local environment and find unique places.',
      'Discover a unique location or interesting spot in your area.',
    ];
    return descriptions[_random.nextInt(descriptions.length)];
  }

  // Time-based quest generators
  AdventureQuest _generateMorningQuest(UserLocation location, double radius) {
    final questLocation = _generateRandomLocation(location, radius);
    return AdventureQuest(
      id: 'morning_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Morning Energy Boost',
      description: 'Start your day with an energizing morning quest.',
      type: QuestType.time,
      difficulty: QuestDifficulty.medium,
      location: questLocation,
      radius: 100.0,
      rewardXP: 150,
      rewardGold: 50,
      rewards: _generateRewards(QuestDifficulty.medium),
      expirationTime: DateTime.now().add(const Duration(hours: 2)),
      isActive: false,
      isCompleted: false,
    );
  }

  AdventureQuest _generateEveningQuest(UserLocation location, double radius) {
    final questLocation = _generateRandomLocation(location, radius);
    return AdventureQuest(
      id: 'evening_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Evening Wind Down',
      description: 'Complete a relaxing evening quest to end your day.',
      type: QuestType.time,
      difficulty: QuestDifficulty.easy,
      location: questLocation,
      radius: 75.0,
      rewardXP: 100,
      rewardGold: 30,
      rewards: _generateRewards(QuestDifficulty.easy),
      expirationTime: DateTime.now().add(const Duration(hours: 3)),
      isActive: false,
      isCompleted: false,
    );
  }

  AdventureQuest _generateNightQuest(UserLocation location, double radius) {
    final questLocation = _generateRandomLocation(location, radius);
    return AdventureQuest(
      id: 'night_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Night Watch',
      description: 'Embark on a mysterious night-time adventure.',
      type: QuestType.time,
      difficulty: QuestDifficulty.hard,
      location: questLocation,
      radius: 150.0,
      rewardXP: 250,
      rewardGold: 80,
      rewards: _generateRewards(QuestDifficulty.hard),
      expirationTime: DateTime.now().add(const Duration(hours: 4)),
      isActive: false,
      isCompleted: false,
    );
  }

  AdventureQuest _generateWeatherQuest(UserLocation location, double radius) {
    final questLocation = _generateRandomLocation(location, radius);
    return AdventureQuest(
      id: 'weather_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Weather Challenge',
      description: 'Face the elements in this weather-dependent quest.',
      type: QuestType.weather,
      difficulty: QuestDifficulty.hard,
      location: questLocation,
      radius: 120.0,
      rewardXP: 300,
      rewardGold: 100,
      rewards: _generateRewards(QuestDifficulty.hard),
      expirationTime: DateTime.now().add(const Duration(hours: 2)),
      isActive: false,
      isCompleted: false,
    );
  }

  // Enhanced Features

  // Check nearby quests
  void checkNearbyQuests(UserLocation location) {
    for (final quest in _activeQuests) {
      final distance = _calculateDistance(location, quest.location);
      if (distance <= quest.radius) {
        // Quest is nearby - could trigger notifications
      }
    }
  }

  // Get quests near position
  List<AdventureQuest> getQuestsNearPosition(LatLng position, double radius) {
    return _activeQuests.where((quest) {
      final distance = _calculateDistance(
        UserLocation(
          userId: 'player',
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: 0,
          timestamp: DateTime.now(),
        ),
        quest.location,
      );
      return distance <= radius;
    }).toList();
  }

  // Get active quests
  List<AdventureQuest> getActiveQuests() {
    return _activeQuests.where((quest) => quest.isActive).toList();
  }

  // Get quest chains
  List<QuestChain> getQuestChains() {
    return _questChains;
  }

  // Update quest chain
  void updateQuestChain(QuestChain chain) {
    // Update quest chain progress
  }

  // Toggle enhanced features
  void toggleDynamicQuestGeneration() {
    _dynamicQuestGeneration = !_dynamicQuestGeneration;
  }

  void toggleQuestChains() {
    _questChainsEnabled = !_questChainsEnabled;
  }

  void toggleWeatherBasedQuests() {
    _weatherBasedQuests = !_weatherBasedQuests;
  }

  void toggleTimeBasedQuests() {
    _timeBasedQuests = !_timeBasedQuests;
  }

  void toggleDifficultyScaling() {
    _difficultyScaling = !_difficultyScaling;
  }

  // Get quest statistics
  Map<String, dynamic> getQuestStats() {
    return {
      'totalQuests': _activeQuests.length,
      'activeQuests': getActiveQuests().length,
      'completedQuests': _activeQuests.where((q) => q.isCompleted).length,
      'questChains': _questChains.length,
      'dynamicGeneration': _dynamicQuestGeneration,
      'questChainsEnabled': _questChainsEnabled,
      'weatherBasedQuests': _weatherBasedQuests,
      'timeBasedQuests': _timeBasedQuests,
      'difficultyScaling': _difficultyScaling,
    };
  }

  // Dispose
  void dispose() {
    _activeQuests.clear();
    _questChains.clear();
  }
}

// Quest Models
class AdventureQuest {
  final String id;
  final String title;
  final String description;
  final QuestType type;
  final QuestDifficulty difficulty;
  final LatLng location;
  final double radius;
  final int rewardXP;
  final int rewardGold;
  final List<QuestReward> rewards;
  final DateTime? expirationTime;
  final WeatherCondition? requiredWeather;
  final TimeOfDay? requiredTime;
  bool isActive;
  bool isCompleted;

  AdventureQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.location,
    required this.radius,
    required this.rewardXP,
    required this.rewardGold,
    required this.rewards,
    this.expirationTime,
    this.requiredWeather,
    this.requiredTime,
    this.isActive = false,
    this.isCompleted = false,
  });
}

enum QuestType {
  exploration,
  social,
  fitness,
  collection,
  battle,
  time,
  weather,
  walking,
  running,
  climbing,
  location,
}

enum QuestDifficulty {
  easy,
  medium,
  hard,
  epic,
}

enum RewardType {
  xp,
  gold,
  item,
  experience,
}

class QuestReward {
  final RewardType type;
  final int amount;
  final String description;

  QuestReward({
    required this.type,
    required this.amount,
    required this.description,
  });
}

enum TimeOfDay {
  morning,
  afternoon,
  evening,
  night,
}

class QuestChain {
  final String id;
  final String title;
  final String description;
  final List<AdventureQuest> quests;
  int currentStep;
  bool isCompleted;

  QuestChain({
    required this.id,
    required this.title,
    required this.description,
    required this.quests,
    this.currentStep = 0,
    this.isCompleted = false,
  });
} 