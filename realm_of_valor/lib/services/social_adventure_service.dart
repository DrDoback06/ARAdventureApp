import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/adventure_system.dart';
import 'adventure_progression_service.dart';

enum LeaderboardType {
  weeklySteps,
  monthlyDistance,
  questsCompleted,
  adventureXP,
  streakLength,
  locationsVisited,
}

class LeaderboardEntry {
  final String playerId;
  final String playerName;
  final String? avatar;
  final int score;
  final int rank;
  final AdventureRank adventureRank;
  final String? activeTitle;
  final DateTime lastUpdate;

  LeaderboardEntry({
    required this.playerId,
    required this.playerName,
    this.avatar,
    required this.score,
    required this.rank,
    required this.adventureRank,
    this.activeTitle,
    required this.lastUpdate,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      playerId: json['playerId'],
      playerName: json['playerName'],
      avatar: json['avatar'],
      score: json['score'],
      rank: json['rank'],
      adventureRank: AdventureRank.values[json['adventureRank'] ?? 0],
      activeTitle: json['activeTitle'],
      lastUpdate: DateTime.parse(json['lastUpdate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'playerName': playerName,
      'avatar': avatar,
      'score': score,
      'rank': rank,
      'adventureRank': adventureRank.index,
      'activeTitle': activeTitle,
      'lastUpdate': lastUpdate.toIso8601String(),
    };
  }
}

class ChallengeInvite {
  final String id;
  final String fromPlayerId;
  final String fromPlayerName;
  final String toPlayerId;
  final String challengeType;
  final String title;
  final String description;
  final Map<String, dynamic> requirements;
  final Map<String, dynamic> rewards;
  final DateTime expiresAt;
  final bool isAccepted;
  final bool isCompleted;

  ChallengeInvite({
    required this.id,
    required this.fromPlayerId,
    required this.fromPlayerName,
    required this.toPlayerId,
    required this.challengeType,
    required this.title,
    required this.description,
    required this.requirements,
    required this.rewards,
    required this.expiresAt,
    this.isAccepted = false,
    this.isCompleted = false,
  });

  factory ChallengeInvite.fromJson(Map<String, dynamic> json) {
    return ChallengeInvite(
      id: json['id'],
      fromPlayerId: json['fromPlayerId'],
      fromPlayerName: json['fromPlayerName'],
      toPlayerId: json['toPlayerId'],
      challengeType: json['challengeType'],
      title: json['title'],
      description: json['description'],
      requirements: Map<String, dynamic>.from(json['requirements']),
      rewards: Map<String, dynamic>.from(json['rewards']),
      expiresAt: DateTime.parse(json['expiresAt']),
      isAccepted: json['isAccepted'] ?? false,
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromPlayerId': fromPlayerId,
      'fromPlayerName': fromPlayerName,
      'toPlayerId': toPlayerId,
      'challengeType': challengeType,
      'title': title,
      'description': description,
      'requirements': requirements,
      'rewards': rewards,
      'expiresAt': expiresAt.toIso8601String(),
      'isAccepted': isAccepted,
      'isCompleted': isCompleted,
    };
  }
}

class TeamAdventure {
  final String id;
  final String name;
  final String description;
  final List<String> memberIds;
  final List<String> memberNames;
  final GeoLocation? targetLocation;
  final double? radius;
  final Quest? groupQuest;
  final Map<String, int> memberProgress;
  final Map<String, dynamic> rewards;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isActive;

  TeamAdventure({
    required this.id,
    required this.name,
    required this.description,
    required this.memberIds,
    required this.memberNames,
    this.targetLocation,
    this.radius,
    this.groupQuest,
    required this.memberProgress,
    required this.rewards,
    required this.createdAt,
    this.completedAt,
    this.isActive = true,
  });

  factory TeamAdventure.fromJson(Map<String, dynamic> json) {
    return TeamAdventure(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      memberIds: List<String>.from(json['memberIds']),
      memberNames: List<String>.from(json['memberNames']),
      targetLocation: json['targetLocation'] != null
          ? GeoLocation.fromJson(json['targetLocation'])
          : null,
      radius: json['radius']?.toDouble(),
      groupQuest: json['groupQuest'] != null
          ? Quest.fromJson(json['groupQuest'])
          : null,
      memberProgress: Map<String, int>.from(json['memberProgress']),
      rewards: Map<String, dynamic>.from(json['rewards']),
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'memberIds': memberIds,
      'memberNames': memberNames,
      'targetLocation': targetLocation?.toJson(),
      'radius': radius,
      'groupQuest': groupQuest?.toJson(),
      'memberProgress': memberProgress,
      'rewards': rewards,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  double get completionPercentage {
    if (memberProgress.isEmpty) return 0.0;
    final totalProgress = memberProgress.values.reduce((a, b) => a + b);
    final maxProgress = memberProgress.length * 100; // Assuming 100% per member
    return (totalProgress / maxProgress * 100).clamp(0.0, 100.0);
  }
}

class SocialAdventureService {
  static final SocialAdventureService _instance = SocialAdventureService._internal();
  factory SocialAdventureService() => _instance;
  SocialAdventureService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StreamController<List<LeaderboardEntry>> _leaderboardController = StreamController.broadcast();
  final StreamController<List<ChallengeInvite>> _challengeController = StreamController.broadcast();
  final StreamController<List<TeamAdventure>> _teamAdventureController = StreamController.broadcast();

  Stream<List<LeaderboardEntry>> get leaderboardStream => _leaderboardController.stream;
  Stream<List<ChallengeInvite>> get challengeStream => _challengeController.stream;
  Stream<List<TeamAdventure>> get teamAdventureStream => _teamAdventureController.stream;

  String? _currentPlayerId;
  List<String> _friendsList = [];

  // Initialize social features
  Future<void> initialize(String playerId) async {
    _currentPlayerId = playerId;
    await _loadFriendsList();
    _setupRealtimeListeners();
  }

  // Get leaderboard data
  Future<List<LeaderboardEntry>> getLeaderboard(LeaderboardType type, {int limit = 50}) async {
    try {
      final collection = _getLeaderboardCollection(type);
      final query = await _firestore
          .collection('leaderboards')
          .doc(collection)
          .collection('entries')
          .orderBy('score', descending: true)
          .limit(limit)
          .get();

      final entries = query.docs.asMap().entries.map((entry) {
        final data = entry.value.data();
        return LeaderboardEntry.fromJson({
          ...data,
          'rank': entry.key + 1,
        });
      }).toList();

      _leaderboardController.add(entries);
      return entries;
    } catch (e) {
      print('Error getting leaderboard: $e');
      return [];
    }
  }

  // Update player's leaderboard score
  Future<void> updateLeaderboardScore(LeaderboardType type, int score, {
    String? playerName,
    AdventureRank? rank,
    String? activeTitle,
  }) async {
    if (_currentPlayerId == null) return;

    try {
      final collection = _getLeaderboardCollection(type);
      await _firestore
          .collection('leaderboards')
          .doc(collection)
          .collection('entries')
          .doc(_currentPlayerId)
          .set({
        'playerId': _currentPlayerId,
        'playerName': playerName ?? 'Unknown',
        'score': score,
        'adventureRank': rank?.index ?? 0,
        'activeTitle': activeTitle,
        'lastUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating leaderboard score: $e');
    }
  }

  // Send challenge invite
  Future<void> sendChallengeInvite({
    required String toPlayerId,
    required String challengeType,
    required String title,
    required String description,
    required Map<String, dynamic> requirements,
    required Map<String, dynamic> rewards,
  }) async {
    if (_currentPlayerId == null) return;

    try {
      final challengeId = _firestore.collection('challenges').doc().id;
      final invite = ChallengeInvite(
        id: challengeId,
        fromPlayerId: _currentPlayerId!,
        fromPlayerName: await _getPlayerName(_currentPlayerId!),
        toPlayerId: toPlayerId,
        challengeType: challengeType,
        title: title,
        description: description,
        requirements: requirements,
        rewards: rewards,
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      await _firestore
          .collection('challenges')
          .doc(challengeId)
          .set(invite.toJson());

      // Send push notification (would integrate with FCM)
      await _sendChallengeNotification(toPlayerId, invite);
    } catch (e) {
      print('Error sending challenge invite: $e');
    }
  }

  // Accept challenge
  Future<void> acceptChallenge(String challengeId) async {
    try {
      await _firestore
          .collection('challenges')
          .doc(challengeId)
          .update({
        'isAccepted': true,
        'acceptedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error accepting challenge: $e');
    }
  }

  // Create team adventure
  Future<TeamAdventure> createTeamAdventure({
    required String name,
    required String description,
    required List<String> memberIds,
    GeoLocation? targetLocation,
    double? radius,
    Quest? groupQuest,
  }) async {
    try {
      final adventureId = _firestore.collection('team_adventures').doc().id;
      final memberNames = <String>[];
      
      for (final memberId in memberIds) {
        memberNames.add(await _getPlayerName(memberId));
      }

      final teamAdventure = TeamAdventure(
        id: adventureId,
        name: name,
        description: description,
        memberIds: memberIds,
        memberNames: memberNames,
        targetLocation: targetLocation,
        radius: radius,
        groupQuest: groupQuest,
        memberProgress: {for (String id in memberIds) id: 0},
        rewards: {
          'xp': 500 * memberIds.length,
          'cards': memberIds.length,
          'title': 'Team Player',
        },
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('team_adventures')
          .doc(adventureId)
          .set(teamAdventure.toJson());

      return teamAdventure;
    } catch (e) {
      print('Error creating team adventure: $e');
      rethrow;
    }
  }

  // Update team progress
  Future<void> updateTeamProgress(String adventureId, String playerId, int progress) async {
    try {
      await _firestore
          .collection('team_adventures')
          .doc(adventureId)
          .update({
        'memberProgress.$playerId': progress,
        'lastUpdate': FieldValue.serverTimestamp(),
      });

      // Check if adventure is completed
      final adventure = await getTeamAdventure(adventureId);
      if (adventure != null && adventure.completionPercentage >= 100) {
        await _completeTeamAdventure(adventureId);
      }
    } catch (e) {
      print('Error updating team progress: $e');
    }
  }

  // Get team adventure
  Future<TeamAdventure?> getTeamAdventure(String adventureId) async {
    try {
      final doc = await _firestore
          .collection('team_adventures')
          .doc(adventureId)
          .get();

      if (doc.exists) {
        return TeamAdventure.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting team adventure: $e');
      return null;
    }
  }

  // Get nearby players for team formation
  Future<List<Map<String, dynamic>>> getNearbyPlayers(GeoLocation location, {double radius = 1000}) async {
    try {
      // This would use geohashing for efficient location queries
      final query = await _firestore
          .collection('player_locations')
          .where('isActive', isEqualTo: true)
          .limit(20)
          .get();

      final nearbyPlayers = <Map<String, dynamic>>[];
      
      for (final doc in query.docs) {
        final data = doc.data();
        final playerLocation = GeoLocation.fromJson(data['location']);
        final distance = location.distanceTo(playerLocation);
        
        if (distance <= radius && doc.id != _currentPlayerId) {
          nearbyPlayers.add({
            'playerId': doc.id,
            'playerName': data['playerName'],
            'distance': distance,
            'adventureRank': data['adventureRank'],
            'isOnline': data['lastSeen'] != null &&
                DateTime.now().difference(data['lastSeen'].toDate()).inMinutes < 30,
          });
        }
      }

      // Sort by distance
      nearbyPlayers.sort((a, b) => a['distance'].compareTo(b['distance']));
      return nearbyPlayers;
    } catch (e) {
      print('Error getting nearby players: $e');
      return [];
    }
  }

  // Create pre-defined social challenges
  List<Map<String, dynamic>> getSocialChallengeTemplates() {
    return [
      {
        'type': 'step_race',
        'title': 'Step Challenge',
        'description': 'First to reach 10,000 steps wins!',
        'requirements': {'steps': 10000},
        'rewards': {'xp': 200, 'cards': 2},
        'duration': 1, // days
      },
      {
        'type': 'distance_race',
        'title': 'Distance Marathon',
        'description': 'Who can travel furthest this week?',
        'requirements': {'distance': 50000}, // 50km
        'rewards': {'xp': 500, 'cards': 3, 'title': 'Marathon Master'},
        'duration': 7,
      },
      {
        'type': 'quest_sprint',
        'title': 'Quest Sprint',
        'description': 'Complete 5 quests before your friend!',
        'requirements': {'quests': 5},
        'rewards': {'xp': 300, 'cards': 2},
        'duration': 3,
      },
      {
        'type': 'location_explorer',
        'title': 'Location Explorer',
        'description': 'Visit 10 different POIs this weekend!',
        'requirements': {'locations': 10, 'unique': true},
        'rewards': {'xp': 400, 'cards': 3, 'title': 'Social Explorer'},
        'duration': 2,
      },
    ];
  }

  // Generate weekly group events
  Future<List<Map<String, dynamic>>> getWeeklyGroupEvents() async {
    final events = <Map<String, dynamic>>[];
    final now = DateTime.now();
    
    // Community Challenge
    events.add({
      'id': 'community_${now.weekday}',
      'title': 'Community Distance Challenge',
      'description': 'Help your region reach 1,000km combined this week!',
      'type': 'community',
      'target': 1000000, // meters
      'current': await _getCommunityProgress('distance'),
      'rewards': ['Rare Cards for All', 'Community Badge'],
      'endsAt': _getEndOfWeek(),
    });

    // Regional Conquest
    events.add({
      'id': 'conquest_${now.weekday}',
      'title': 'Regional POI Conquest',
      'description': 'Visit POIs to claim territory for your region!',
      'type': 'conquest',
      'target': 500, // POI visits
      'current': await _getCommunityProgress('poi_visits'),
      'rewards': ['Territory Bonuses', 'Regional Title'],
      'endsAt': _getEndOfWeek(),
    });

    return events;
  }

  // Helper methods
  String _getLeaderboardCollection(LeaderboardType type) {
    switch (type) {
      case LeaderboardType.weeklySteps:
        return 'weekly_steps';
      case LeaderboardType.monthlyDistance:
        return 'monthly_distance';
      case LeaderboardType.questsCompleted:
        return 'quests_completed';
      case LeaderboardType.adventureXP:
        return 'adventure_xp';
      case LeaderboardType.streakLength:
        return 'streak_length';
      case LeaderboardType.locationsVisited:
        return 'locations_visited';
    }
  }

  Future<String> _getPlayerName(String playerId) async {
    try {
      final doc = await _firestore.collection('players').doc(playerId).get();
      return doc.data()?['name'] ?? 'Unknown Player';
    } catch (e) {
      return 'Unknown Player';
    }
  }

  Future<void> _sendChallengeNotification(String playerId, ChallengeInvite invite) async {
    // Would integrate with FCM for push notifications
    print('Sending challenge notification to $playerId: ${invite.title}');
  }

  Future<void> _completeTeamAdventure(String adventureId) async {
    await _firestore
        .collection('team_adventures')
        .doc(adventureId)
        .update({
      'isActive': false,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<int> _getCommunityProgress(String type) async {
    // This would aggregate community data
    return math.Random().nextInt(750000); // Mock data
  }

  DateTime _getEndOfWeek() {
    final now = DateTime.now();
    final daysUntilSunday = 7 - now.weekday;
    return now.add(Duration(days: daysUntilSunday)).copyWith(
      hour: 23,
      minute: 59,
      second: 59,
    );
  }

  Future<void> _loadFriendsList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final friendsJson = prefs.getString('friends_$_currentPlayerId');
      if (friendsJson != null) {
        _friendsList = List<String>.from(jsonDecode(friendsJson));
      }
    } catch (e) {
      print('Error loading friends list: $e');
    }
  }

  void _setupRealtimeListeners() {
    if (_currentPlayerId == null) return;

    // Listen for challenge invites
    _firestore
        .collection('challenges')
        .where('toPlayerId', isEqualTo: _currentPlayerId)
        .where('isAccepted', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      final challenges = snapshot.docs
          .map((doc) => ChallengeInvite.fromJson(doc.data()))
          .toList();
      _challengeController.add(challenges);
    });

    // Listen for team adventures
    _firestore
        .collection('team_adventures')
        .where('memberIds', arrayContains: _currentPlayerId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      final adventures = snapshot.docs
          .map((doc) => TeamAdventure.fromJson(doc.data()))
          .toList();
      _teamAdventureController.add(adventures);
    });
  }

  // Cleanup
  void dispose() {
    _leaderboardController.close();
    _challengeController.close();
    _teamAdventureController.close();
  }
}