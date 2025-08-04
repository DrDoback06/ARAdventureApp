import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/battle_replay_system.dart';

class BattleReplayService {
  static const String _replaysKey = 'battle_replays';
  
  final SharedPreferences _prefs;
  final List<BattleReplay> _replays = [];

  BattleReplayService(this._prefs) {
    _loadReplays();
  }

  /// Load replays from storage
  void _loadReplays() {
    final data = _prefs.getString(_replaysKey);
    if (data != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(data);
        _replays.clear();
        for (final json in jsonList) {
          // For now, create a simple replay without JSON serialization
          // In a full implementation, you'd use BattleReplay.fromJson(json)
          _replays.add(_createReplayFromJson(json));
        }
      } catch (e) {
        print('Error loading replays: $e');
      }
    }
  }

  /// Save replays to storage
  Future<void> _saveReplays() async {
    try {
      final jsonList = _replays.map((replay) => replay.toJson()).toList();
      final data = jsonEncode(jsonList);
      await _prefs.setString(_replaysKey, data);
    } catch (e) {
      print('Error saving replays: $e');
    }
  }

  /// Create a replay from JSON (temporary implementation)
  BattleReplay _createReplayFromJson(Map<String, dynamic> json) {
    return BattleReplay(
      battleId: json['battleId'] ?? '',
      battleName: json['battleName'] ?? '',
      playerIds: List<String>.from(json['playerIds'] ?? []),
      playerNames: List<String>.from(json['playerNames'] ?? []),
      battleStartTime: DateTime.parse(json['battleStartTime'] ?? DateTime.now().toIso8601String()),
      battleEndTime: DateTime.parse(json['battleEndTime'] ?? DateTime.now().toIso8601String()),
      battleDuration: Duration(milliseconds: json['battleDurationMs'] ?? 0),
      winnerId: json['winnerId'],
      actions: [], // Simplified for now
      battleSettings: Map<String, dynamic>.from(json['battleSettings'] ?? {}),
      finalStats: Map<String, dynamic>.from(json['finalStats'] ?? {}),
    );
  }

  /// Save a new replay
  Future<void> saveReplay(BattleReplay replay) async {
    _replays.add(replay);
    await _saveReplays();
  }

  /// Get all replays
  List<BattleReplay> getAllReplays() {
    return List.unmodifiable(_replays);
  }

  /// Get replays by player
  List<BattleReplay> getReplaysByPlayer(String playerId) {
    return _replays.where((replay) => replay.playerIds.contains(playerId)).toList();
  }

  /// Get recent replays (last 10)
  List<BattleReplay> getRecentReplays({int limit = 10}) {
    final sortedReplays = List<BattleReplay>.from(_replays);
    sortedReplays.sort((a, b) => b.battleEndTime.compareTo(a.battleEndTime));
    return sortedReplays.take(limit).toList();
  }

  /// Get replay by ID
  BattleReplay? getReplayById(String replayId) {
    try {
      return _replays.firstWhere((replay) => replay.id == replayId);
    } catch (e) {
      return null;
    }
  }

  /// Delete a replay
  Future<void> deleteReplay(String replayId) async {
    _replays.removeWhere((replay) => replay.id == replayId);
    await _saveReplays();
  }

  /// Get replay statistics
  Map<String, dynamic> getReplayStats() {
    if (_replays.isEmpty) return {};

    final totalBattles = _replays.length;
    final totalDuration = _replays.fold<Duration>(
      Duration.zero,
      (total, replay) => total + replay.battleDuration,
    );
    final averageDuration = Duration(
      milliseconds: totalDuration.inMilliseconds ~/ totalBattles,
    );

    final playerStats = <String, Map<String, dynamic>>{};
    for (final replay in _replays) {
      for (final playerId in replay.playerIds) {
        if (!playerStats.containsKey(playerId)) {
          playerStats[playerId] = {
            'battles': 0,
            'wins': 0,
            'totalDamage': 0,
            'totalHealing': 0,
          };
        }
        
        final stats = playerStats[playerId]!;
        stats['battles'] = (stats['battles'] as int) + 1;
        
        if (replay.winnerId == playerId) {
          stats['wins'] = (stats['wins'] as int) + 1;
        }
        
        // Calculate damage and healing from replay actions
        final playerActions = replay.getActionsByPlayer(playerId);
        for (final action in playerActions) {
          switch (action.type) {
            case ReplayActionType.damageDealt:
              final damage = action.data['damage'] as int? ?? 0;
              stats['totalDamage'] = (stats['totalDamage'] as int) + damage;
              break;
            case ReplayActionType.healingReceived:
              final healing = action.data['healing'] as int? ?? 0;
              stats['totalHealing'] = (stats['totalHealing'] as int) + healing;
              break;
            default:
              break;
          }
        }
      }
    }

    return {
      'totalBattles': totalBattles,
      'averageDuration': averageDuration,
      'totalDuration': totalDuration,
      'playerStats': playerStats,
    };
  }

  /// Get battle highlights
  List<BattleReplay> getHighlightReplays() {
    return _replays.where((replay) {
      // Consider a replay a highlight if it has significant actions
      final highlights = replay.getHighlights();
      return highlights.length >= 5; // At least 5 significant actions
    }).toList();
  }

  /// Search replays
  List<BattleReplay> searchReplays(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _replays.where((replay) {
      return replay.battleName.toLowerCase().contains(lowercaseQuery) ||
             replay.playerNames.any((name) => name.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  /// Get replays by date range
  List<BattleReplay> getReplaysByDateRange(DateTime start, DateTime end) {
    return _replays.where((replay) {
      return replay.battleStartTime.isAfter(start) && 
             replay.battleStartTime.isBefore(end);
    }).toList();
  }

  /// Clear all replays
  Future<void> clearAllReplays() async {
    _replays.clear();
    await _saveReplays();
  }

  /// Export replays to JSON
  String exportReplaysToJson() {
    final jsonList = _replays.map((replay) => replay.toJson()).toList();
    return jsonEncode(jsonList);
  }

  /// Import replays from JSON
  Future<void> importReplaysFromJson(String jsonData) async {
    try {
      final List<dynamic> jsonList = jsonDecode(jsonData);
      for (final json in jsonList) {
        final replay = _createReplayFromJson(json);
        _replays.add(replay);
      }
      await _saveReplays();
    } catch (e) {
      print('Error importing replays: $e');
      rethrow;
    }
  }
} 