import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/adventure_system.dart';
import '../models/character_model.dart';

enum AdventureRank {
  novice,
  explorer,
  adventurer,
  veteran,
  champion,
  legend,
  mythic,
}

class AdventureStreak {
  final int currentStreak;
  final int longestStreak;
  final DateTime lastCheckIn;
  final List<DateTime> checkInHistory;
  final Map<String, int> weeklyActivities;

  AdventureStreak({
    this.currentStreak = 0,
    this.longestStreak = 0,
    required this.lastCheckIn,
    List<DateTime>? checkInHistory,
    Map<String, int>? weeklyActivities,
  }) : checkInHistory = checkInHistory ?? [],
       weeklyActivities = weeklyActivities ?? {};

  factory AdventureStreak.fromJson(Map<String, dynamic> json) {
    return AdventureStreak(
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      lastCheckIn: DateTime.parse(json['lastCheckIn']),
      checkInHistory: (json['checkInHistory'] as List?)
          ?.map((date) => DateTime.parse(date))
          .toList() ?? [],
      weeklyActivities: Map<String, int>.from(json['weeklyActivities'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastCheckIn': lastCheckIn.toIso8601String(),
      'checkInHistory': checkInHistory.map((date) => date.toIso8601String()).toList(),
      'weeklyActivities': weeklyActivities,
    };
  }

  AdventureStreak copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastCheckIn,
    List<DateTime>? checkInHistory,
    Map<String, int>? weeklyActivities,
  }) {
    return AdventureStreak(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      checkInHistory: checkInHistory ?? this.checkInHistory,
      weeklyActivities: weeklyActivities ?? this.weeklyActivities,
    );
  }
}

class AdventureProfile {
  final String characterId;
  final int adventureXP;
  final AdventureRank rank;
  final List<String> unlockedTitles;
  final String? activeTitle;
  final Map<String, int> locationVisits;
  final Map<String, int> questCompletions;
  final Map<String, DateTime> achievements;
  final AdventureStreak streak;
  final List<String> favoriteLocations;
  final Map<String, dynamic> personalizedContent;
  final DateTime lastAdventureTime;
  final int totalDistanceTraveled;
  final int questsCompleted;
  final int encountersWon;

  AdventureProfile({
    required this.characterId,
    this.adventureXP = 0,
    this.rank = AdventureRank.novice,
    List<String>? unlockedTitles,
    this.activeTitle,
    Map<String, int>? locationVisits,
    Map<String, int>? questCompletions,
    Map<String, DateTime>? achievements,
    required this.streak,
    List<String>? favoriteLocations,
    Map<String, dynamic>? personalizedContent,
    required this.lastAdventureTime,
    this.totalDistanceTraveled = 0,
    this.questsCompleted = 0,
    this.encountersWon = 0,
  }) : unlockedTitles = unlockedTitles ?? [],
       locationVisits = locationVisits ?? {},
       questCompletions = questCompletions ?? {},
       achievements = achievements ?? {},
       favoriteLocations = favoriteLocations ?? [],
       personalizedContent = personalizedContent ?? {};

  factory AdventureProfile.fromJson(Map<String, dynamic> json) {
    return AdventureProfile(
      characterId: json['characterId'],
      adventureXP: json['adventureXP'] ?? 0,
      rank: AdventureRank.values[json['rank'] ?? 0],
      unlockedTitles: List<String>.from(json['unlockedTitles'] ?? []),
      activeTitle: json['activeTitle'],
      locationVisits: Map<String, int>.from(json['locationVisits'] ?? {}),
      questCompletions: Map<String, int>.from(json['questCompletions'] ?? {}),
      achievements: (json['achievements'] as Map?)?.map(
        (key, value) => MapEntry(key.toString(), DateTime.parse(value)),
      ) ?? {},
      streak: AdventureStreak.fromJson(json['streak'] ?? {}),
      favoriteLocations: List<String>.from(json['favoriteLocations'] ?? []),
      personalizedContent: Map<String, dynamic>.from(json['personalizedContent'] ?? {}),
      lastAdventureTime: DateTime.parse(json['lastAdventureTime'] ?? DateTime.now().toIso8601String()),
      totalDistanceTraveled: json['totalDistanceTraveled'] ?? 0,
      questsCompleted: json['questsCompleted'] ?? 0,
      encountersWon: json['encountersWon'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'characterId': characterId,
      'adventureXP': adventureXP,
      'rank': rank.index,
      'unlockedTitles': unlockedTitles,
      'activeTitle': activeTitle,
      'locationVisits': locationVisits,
      'questCompletions': questCompletions,
      'achievements': achievements.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
      'streak': streak.toJson(),
      'favoriteLocations': favoriteLocations,
      'personalizedContent': personalizedContent,
      'lastAdventureTime': lastAdventureTime.toIso8601String(),
      'totalDistanceTraveled': totalDistanceTraveled,
      'questsCompleted': questsCompleted,
      'encountersWon': encountersWon,
    };
  }

  int get rankProgress {
    final currentRankXP = _getRankXPRequirement(rank);
    final nextRankXP = _getRankXPRequirement(_getNextRank());
    final progressInRank = adventureXP - currentRankXP;
    final rankRange = nextRankXP - currentRankXP;
    return rankRange > 0 ? ((progressInRank / rankRange) * 100).round() : 100;
  }

  AdventureRank _getNextRank() {
    final currentIndex = rank.index;
    return currentIndex < AdventureRank.values.length - 1
        ? AdventureRank.values[currentIndex + 1]
        : rank;
  }

  int _getRankXPRequirement(AdventureRank rank) {
    switch (rank) {
      case AdventureRank.novice: return 0;
      case AdventureRank.explorer: return 1000;
      case AdventureRank.adventurer: return 2500;
      case AdventureRank.veteran: return 5000;
      case AdventureRank.champion: return 10000;
      case AdventureRank.legend: return 20000;
      case AdventureRank.mythic: return 50000;
    }
  }
}

class DailyReward {
  final String id;
  final String name;
  final String description;
  final String type; // xp, cards, gold, items
  final int value;
  final String? iconPath;
  final bool isSpecial;

  DailyReward({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.value,
    this.iconPath,
    this.isSpecial = false,
  });

  factory DailyReward.fromJson(Map<String, dynamic> json) {
    return DailyReward(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: json['type'],
      value: json['value'],
      iconPath: json['iconPath'],
      isSpecial: json['isSpecial'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'value': value,
      'iconPath': iconPath,
      'isSpecial': isSpecial,
    };
  }
}

class AdventureProgressionService {
  static final AdventureProgressionService _instance = AdventureProgressionService._internal();
  factory AdventureProgressionService() => _instance;
  AdventureProgressionService._internal();

  final StreamController<AdventureProfile> _profileController = StreamController.broadcast();
  final StreamController<DailyReward> _rewardController = StreamController.broadcast();
  
  Stream<AdventureProfile> get profileStream => _profileController.stream;
  Stream<DailyReward> get rewardStream => _rewardController.stream;

  AdventureProfile? _currentProfile;
  
  AdventureProfile? get currentProfile => _currentProfile;

  // Initialize progression for character
  Future<AdventureProfile> initializeAdventureProfile(String characterId) async {
    try {
      _currentProfile = await _loadAdventureProfile(characterId);
      
      if (_currentProfile == null) {
        _currentProfile = AdventureProfile(
          characterId: characterId,
          streak: AdventureStreak(lastCheckIn: DateTime.now()),
          lastAdventureTime: DateTime.now(),
        );
        await _saveAdventureProfile(_currentProfile!);
      }

      _profileController.add(_currentProfile!);
      return _currentProfile!;
    } catch (e) {
      print('Error initializing adventure profile: $e');
      rethrow;
    }
  }

  // Daily check-in system
  Future<DailyReward?> performDailyCheckIn() async {
    if (_currentProfile == null) return null;

    final now = DateTime.now();
    final lastCheckIn = _currentProfile!.streak.lastCheckIn;
    final daysSinceLastCheckIn = now.difference(lastCheckIn).inDays;

    if (daysSinceLastCheckIn == 0) {
      return null; // Already checked in today
    }

    // Calculate new streak
    int newStreak;
    if (daysSinceLastCheckIn == 1) {
      newStreak = _currentProfile!.streak.currentStreak + 1;
    } else {
      newStreak = 1; // Reset streak if missed a day
    }

    // Update streak
    final updatedStreak = _currentProfile!.streak.copyWith(
      currentStreak: newStreak,
      longestStreak: math.max(_currentProfile!.streak.longestStreak, newStreak),
      lastCheckIn: now,
      checkInHistory: [..._currentProfile!.streak.checkInHistory, now],
    );

    // Generate daily reward
    final reward = _generateDailyReward(newStreak);

    // Apply reward to character
    await _applyRewardToCharacter(reward);

    // Update adventure profile
    _currentProfile = AdventureProfile(
      characterId: _currentProfile!.characterId,
      adventureXP: _currentProfile!.adventureXP + (reward.type == 'xp' ? reward.value : 50),
      rank: _calculateRank(_currentProfile!.adventureXP + 50),
      unlockedTitles: _currentProfile!.unlockedTitles,
      activeTitle: _currentProfile!.activeTitle,
      locationVisits: _currentProfile!.locationVisits,
      questCompletions: _currentProfile!.questCompletions,
      achievements: _currentProfile!.achievements,
      streak: updatedStreak,
      favoriteLocations: _currentProfile!.favoriteLocations,
      personalizedContent: _currentProfile!.personalizedContent,
      lastAdventureTime: now,
      totalDistanceTraveled: _currentProfile!.totalDistanceTraveled,
      questsCompleted: _currentProfile!.questsCompleted,
      encountersWon: _currentProfile!.encountersWon,
    );

    await _saveAdventureProfile(_currentProfile!);
    _profileController.add(_currentProfile!);
    _rewardController.add(reward);

    return reward;
  }

  // Award adventure XP and track progress
  Future<void> awardAdventureXP(int xp, String reason) async {
    if (_currentProfile == null) return;

    final oldRank = _currentProfile!.rank;
    final newXP = _currentProfile!.adventureXP + xp;
    final newRank = _calculateRank(newXP);

    _currentProfile = AdventureProfile(
      characterId: _currentProfile!.characterId,
      adventureXP: newXP,
      rank: newRank,
      unlockedTitles: _currentProfile!.unlockedTitles,
      activeTitle: _currentProfile!.activeTitle,
      locationVisits: _currentProfile!.locationVisits,
      questCompletions: _currentProfile!.questCompletions,
      achievements: _currentProfile!.achievements,
      streak: _currentProfile!.streak,
      favoriteLocations: _currentProfile!.favoriteLocations,
      personalizedContent: _currentProfile!.personalizedContent,
      lastAdventureTime: DateTime.now(),
      totalDistanceTraveled: _currentProfile!.totalDistanceTraveled,
      questsCompleted: _currentProfile!.questsCompleted,
      encountersWon: _currentProfile!.encountersWon,
    );

    // Check for rank up
    if (newRank != oldRank) {
      await _handleRankUp(newRank);
    }

    await _saveAdventureProfile(_currentProfile!);
    _profileController.add(_currentProfile!);
  }

  // Track quest completion
  Future<void> trackQuestCompletion(Quest quest) async {
    if (_currentProfile == null) return;

    final questType = quest.type.toString();
    final updatedCompletions = Map<String, int>.from(_currentProfile!.questCompletions);
    updatedCompletions[questType] = (updatedCompletions[questType] ?? 0) + 1;

    _currentProfile = AdventureProfile(
      characterId: _currentProfile!.characterId,
      adventureXP: _currentProfile!.adventureXP,
      rank: _currentProfile!.rank,
      unlockedTitles: _currentProfile!.unlockedTitles,
      activeTitle: _currentProfile!.activeTitle,
      locationVisits: _currentProfile!.locationVisits,
      questCompletions: updatedCompletions,
      achievements: _currentProfile!.achievements,
      streak: _currentProfile!.streak,
      favoriteLocations: _currentProfile!.favoriteLocations,
      personalizedContent: _currentProfile!.personalizedContent,
      lastAdventureTime: DateTime.now(),
      totalDistanceTraveled: _currentProfile!.totalDistanceTraveled,
      questsCompleted: _currentProfile!.questsCompleted + 1,
      encountersWon: _currentProfile!.encountersWon,
    );

    await _saveAdventureProfile(_currentProfile!);
    _profileController.add(_currentProfile!);
  }

  // Track location visits
  Future<void> trackLocationVisit(POI poi) async {
    if (_currentProfile == null) return;

    final locationKey = '${poi.type.toString()}_${poi.id}';
    final updatedVisits = Map<String, int>.from(_currentProfile!.locationVisits);
    updatedVisits[locationKey] = (updatedVisits[locationKey] ?? 0) + 1;

    // Add to favorites if visited multiple times
    final updatedFavorites = List<String>.from(_currentProfile!.favoriteLocations);
    if (updatedVisits[locationKey]! >= 3 && !updatedFavorites.contains(poi.id)) {
      updatedFavorites.add(poi.id);
    }

    _currentProfile = AdventureProfile(
      characterId: _currentProfile!.characterId,
      adventureXP: _currentProfile!.adventureXP,
      rank: _currentProfile!.rank,
      unlockedTitles: _currentProfile!.unlockedTitles,
      activeTitle: _currentProfile!.activeTitle,
      locationVisits: updatedVisits,
      questCompletions: _currentProfile!.questCompletions,
      achievements: _currentProfile!.achievements,
      streak: _currentProfile!.streak,
      favoriteLocations: updatedFavorites,
      personalizedContent: _currentProfile!.personalizedContent,
      lastAdventureTime: DateTime.now(),
      totalDistanceTraveled: _currentProfile!.totalDistanceTraveled,
      questsCompleted: _currentProfile!.questsCompleted,
      encountersWon: _currentProfile!.encountersWon,
    );

    await _saveAdventureProfile(_currentProfile!);
    _profileController.add(_currentProfile!);
  }

  // Get personalized content recommendations
  List<String> getPersonalizedRecommendations() {
    if (_currentProfile == null) return [];

    final recommendations = <String>[];
    
    // Based on streak
    if (_currentProfile!.streak.currentStreak >= 7) {
      recommendations.add('🔥 Streak Master! Try a legendary quest to keep the momentum!');
    }

    // Based on favorite activities
    final topQuestType = _getTopQuestType();
    if (topQuestType != null) {
      recommendations.add('🎯 New ${topQuestType.split('.').last} quests are available nearby!');
    }

    // Based on weather and time
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour <= 10) {
      recommendations.add('🌅 Perfect morning for an exploration quest!');
    } else if (hour >= 17 && hour <= 20) {
      recommendations.add('🌆 Evening adventure time! Try a fitness challenge.');
    }

    // Based on location history
    if (_currentProfile!.favoriteLocations.isNotEmpty) {
      recommendations.add('📍 New content available at your favorite locations!');
    }

    return recommendations;
  }

  // Generate daily reward based on streak
  DailyReward _generateDailyReward(int streak) {
    if (streak >= 30) {
      return DailyReward(
        id: 'legendary_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Legendary Chest',
        description: '30-day streak! Epic rewards inside!',
        type: 'cards',
        value: 5,
        isSpecial: true,
      );
    } else if (streak >= 14) {
      return DailyReward(
        id: 'epic_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Epic Reward Box',
        description: '2-week streak achievement!',
        type: 'cards',
        value: 3,
        isSpecial: true,
      );
    } else if (streak >= 7) {
      return DailyReward(
        id: 'rare_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Weekly Bonus',
        description: 'One week of adventures!',
        type: 'xp',
        value: 500,
        isSpecial: true,
      );
    } else if (streak >= 3) {
      return DailyReward(
        id: 'uncommon_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Adventure Boost',
        description: '3-day streak bonus!',
        type: 'xp',
        value: 200,
      );
    } else {
      return DailyReward(
        id: 'common_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Daily Coin',
        description: 'Thanks for checking in!',
        type: 'gold',
        value: 100,
      );
    }
  }

  // Calculate adventure rank based on XP
  AdventureRank _calculateRank(int xp) {
    if (xp >= 50000) return AdventureRank.mythic;
    if (xp >= 20000) return AdventureRank.legend;
    if (xp >= 10000) return AdventureRank.champion;
    if (xp >= 5000) return AdventureRank.veteran;
    if (xp >= 2500) return AdventureRank.adventurer;
    if (xp >= 1000) return AdventureRank.explorer;
    return AdventureRank.novice;
  }

  // Handle rank up rewards and unlocks
  Future<void> _handleRankUp(AdventureRank newRank) async {
    final newTitles = _getTitlesForRank(newRank);
    final updatedTitles = List<String>.from(_currentProfile!.unlockedTitles)
      ..addAll(newTitles.where((title) => !_currentProfile!.unlockedTitles.contains(title)));

    _currentProfile = AdventureProfile(
      characterId: _currentProfile!.characterId,
      adventureXP: _currentProfile!.adventureXP,
      rank: newRank,
      unlockedTitles: updatedTitles,
      activeTitle: _currentProfile!.activeTitle,
      locationVisits: _currentProfile!.locationVisits,
      questCompletions: _currentProfile!.questCompletions,
      achievements: _currentProfile!.achievements,
      streak: _currentProfile!.streak,
      favoriteLocations: _currentProfile!.favoriteLocations,
      personalizedContent: _currentProfile!.personalizedContent,
      lastAdventureTime: _currentProfile!.lastAdventureTime,
      totalDistanceTraveled: _currentProfile!.totalDistanceTraveled,
      questsCompleted: _currentProfile!.questsCompleted,
      encountersWon: _currentProfile!.encountersWon,
    );

    // Award rank up bonus
    final rankUpReward = DailyReward(
      id: 'rankup_${newRank.toString()}',
      name: 'Rank Up!',
      description: 'Promoted to ${newRank.toString().split('.').last}!',
      type: 'cards',
      value: newRank.index + 1,
      isSpecial: true,
    );

    _rewardController.add(rankUpReward);
  }

  // Get titles for rank
  List<String> _getTitlesForRank(AdventureRank rank) {
    switch (rank) {
      case AdventureRank.novice:
        return ['Novice Explorer'];
      case AdventureRank.explorer:
        return ['Seasoned Explorer', 'Trail Walker'];
      case AdventureRank.adventurer:
        return ['True Adventurer', 'Quest Seeker'];
      case AdventureRank.veteran:
        return ['Veteran Explorer', 'Master Traveler'];
      case AdventureRank.champion:
        return ['Adventure Champion', 'Realm Guardian'];
      case AdventureRank.legend:
        return ['Living Legend', 'Epic Wanderer'];
      case AdventureRank.mythic:
        return ['Mythic Adventurer', 'World Walker', 'Legendary Hero'];
    }
  }

  // Get top quest type
  String? _getTopQuestType() {
    if (_currentProfile!.questCompletions.isEmpty) return null;
    
    return _currentProfile!.questCompletions.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  // Apply reward to character
  Future<void> _applyRewardToCharacter(DailyReward reward) async {
    // This would integrate with your character service
    // For now, we'll just track it in the adventure profile
    print('Applied ${reward.name} to character: ${reward.type} +${reward.value}');
  }

  // Data persistence
  Future<AdventureProfile?> _loadAdventureProfile(String characterId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('adventure_profile_$characterId');
      
      if (profileJson != null) {
        final profileData = jsonDecode(profileJson);
        return AdventureProfile.fromJson(profileData);
      }
      
      return null;
    } catch (e) {
      print('Error loading adventure profile: $e');
      return null;
    }
  }

  Future<void> _saveAdventureProfile(AdventureProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = jsonEncode(profile.toJson());
      await prefs.setString('adventure_profile_${profile.characterId}', profileJson);
    } catch (e) {
      print('Error saving adventure profile: $e');
    }
  }

  // Cleanup
  void dispose() {
    _profileController.close();
    _rewardController.close();
  }
}