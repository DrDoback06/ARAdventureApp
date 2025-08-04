import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'battle_model.dart';
import 'card_model.dart';

part 'battle_replay_system.g.dart';

enum ReplayActionType {
  turnStart,
  cardPlayed,
  skillUsed,
  attackPerformed,
  damageDealt,
  healingReceived,
  playerDefeated,
  turnEnd,
  battleEnd,
}

@JsonSerializable()
class ReplayAction {
  final String id;
  final ReplayActionType type;
  final String playerId;
  final String? targetId;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int turnNumber;

  ReplayAction({
    String? id,
    required this.type,
    required this.playerId,
    this.targetId,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    required this.turnNumber,
  }) : id = id ?? const Uuid().v4(),
       data = data ?? {},
       timestamp = timestamp ?? DateTime.now();

  factory ReplayAction.fromJson(Map<String, dynamic> json) =>
      _$ReplayActionFromJson(json);
  Map<String, dynamic> toJson() => _$ReplayActionToJson(this);
}

@JsonSerializable()
class BattleReplay {
  final String id;
  final String battleId;
  final String battleName;
  final List<String> playerIds;
  final List<String> playerNames;
  final DateTime battleStartTime;
  final DateTime battleEndTime;
  final Duration battleDuration;
  final String? winnerId;
  final List<ReplayAction> actions;
  final Map<String, dynamic> battleSettings;
  final Map<String, dynamic> finalStats;

  BattleReplay({
    String? id,
    required this.battleId,
    required this.battleName,
    required this.playerIds,
    required this.playerNames,
    required this.battleStartTime,
    required this.battleEndTime,
    required this.battleDuration,
    this.winnerId,
    List<ReplayAction>? actions,
    Map<String, dynamic>? battleSettings,
    Map<String, dynamic>? finalStats,
  }) : id = id ?? const Uuid().v4(),
       actions = actions ?? [],
       battleSettings = battleSettings ?? {},
       finalStats = finalStats ?? {};

  factory BattleReplay.fromJson(Map<String, dynamic> json) =>
      _$BattleReplayFromJson(json);
  Map<String, dynamic> toJson() => _$BattleReplayToJson(this);

  BattleReplay copyWith({
    String? id,
    String? battleId,
    String? battleName,
    List<String>? playerIds,
    List<String>? playerNames,
    DateTime? battleStartTime,
    DateTime? battleEndTime,
    Duration? battleDuration,
    String? winnerId,
    List<ReplayAction>? actions,
    Map<String, dynamic>? battleSettings,
    Map<String, dynamic>? finalStats,
  }) {
    return BattleReplay(
      id: id ?? this.id,
      battleId: battleId ?? this.battleId,
      battleName: battleName ?? this.battleName,
      playerIds: playerIds ?? this.playerIds,
      playerNames: playerNames ?? this.playerNames,
      battleStartTime: battleStartTime ?? this.battleStartTime,
      battleEndTime: battleEndTime ?? this.battleEndTime,
      battleDuration: battleDuration ?? this.battleDuration,
      winnerId: winnerId ?? this.winnerId,
      actions: actions ?? this.actions,
      battleSettings: battleSettings ?? this.battleSettings,
      finalStats: finalStats ?? this.finalStats,
    );
  }

  // Get replay duration
  Duration get replayDuration => battleDuration;

  // Get total actions
  int get totalActions => actions.length;

  // Get actions by player
  List<ReplayAction> getActionsByPlayer(String playerId) {
    return actions.where((action) => action.playerId == playerId).toList();
  }

  // Get actions by type
  List<ReplayAction> getActionsByType(ReplayActionType type) {
    return actions.where((action) => action.type == type).toList();
  }

  // Get battle highlights (significant actions)
  List<ReplayAction> getHighlights() {
    return actions.where((action) => 
      action.type == ReplayActionType.damageDealt ||
      action.type == ReplayActionType.playerDefeated ||
      action.type == ReplayActionType.battleEnd
    ).toList();
  }

  // Get player statistics
  Map<String, Map<String, dynamic>> getPlayerStats() {
    final stats = <String, Map<String, dynamic>>{};
    
    for (final playerId in playerIds) {
      stats[playerId] = {
        'damageDealt': 0,
        'damageReceived': 0,
        'cardsPlayed': 0,
        'skillsUsed': 0,
        'healingDone': 0,
        'turnsTaken': 0,
      };
    }
    
    for (final action in actions) {
      final playerStats = stats[action.playerId]!;
      
      switch (action.type) {
        case ReplayActionType.cardPlayed:
          playerStats['cardsPlayed'] = (playerStats['cardsPlayed'] as int) + 1;
          break;
        case ReplayActionType.skillUsed:
          playerStats['skillsUsed'] = (playerStats['skillsUsed'] as int) + 1;
          break;
        case ReplayActionType.damageDealt:
          final damage = action.data['damage'] as int? ?? 0;
          playerStats['damageDealt'] = (playerStats['damageDealt'] as int) + damage;
          if (action.targetId != null) {
            final targetStats = stats[action.targetId!]!;
            targetStats['damageReceived'] = (targetStats['damageReceived'] as int) + damage;
          }
          break;
        case ReplayActionType.healingReceived:
          final healing = action.data['healing'] as int? ?? 0;
          playerStats['healingDone'] = (playerStats['healingDone'] as int) + healing;
          break;
        case ReplayActionType.turnStart:
          playerStats['turnsTaken'] = (playerStats['turnsTaken'] as int) + 1;
          break;
        default:
          break;
      }
    }
    
    return stats;
  }
}

class BattleReplayRecorder {
  final List<ReplayAction> _actions = [];
  final String _battleId;
  final String _battleName;
  final List<String> _playerIds;
  final List<String> _playerNames;
  final DateTime _startTime;
  final Map<String, dynamic> _battleSettings;

  BattleReplayRecorder({
    required String battleId,
    required String battleName,
    required List<String> playerIds,
    required List<String> playerNames,
    required Map<String, dynamic> battleSettings,
  }) : _battleId = battleId,
       _battleName = battleName,
       _playerIds = playerIds,
       _playerNames = playerNames,
       _startTime = DateTime.now(),
       _battleSettings = battleSettings;

  // Record turn start
  void recordTurnStart(String playerId, int turnNumber) {
    _addAction(ReplayActionType.turnStart, playerId, turnNumber: turnNumber);
  }

  // Record card played
  void recordCardPlayed(String playerId, ActionCard card, String? targetId, int turnNumber) {
    _addAction(
      ReplayActionType.cardPlayed,
      playerId,
      targetId: targetId,
      data: {
        'cardId': card.id,
        'cardName': card.name,
        'cardCost': card.cost,
        'cardType': card.type.toString(),
      },
      turnNumber: turnNumber,
    );
  }

  // Record skill used
  void recordSkillUsed(String playerId, String skillName, String? targetId, int turnNumber) {
    _addAction(
      ReplayActionType.skillUsed,
      playerId,
      targetId: targetId,
      data: {
        'skillName': skillName,
      },
      turnNumber: turnNumber,
    );
  }

  // Record attack performed
  void recordAttackPerformed(String playerId, String targetId, int damage, int turnNumber) {
    _addAction(
      ReplayActionType.attackPerformed,
      playerId,
      targetId: targetId,
      data: {
        'damage': damage,
        'attackType': 'physical',
      },
      turnNumber: turnNumber,
    );
  }

  // Record damage dealt
  void recordDamageDealt(String playerId, String targetId, int damage, String damageType, int turnNumber) {
    _addAction(
      ReplayActionType.damageDealt,
      playerId,
      targetId: targetId,
      data: {
        'damage': damage,
        'damageType': damageType,
        'isCritical': false,
      },
      turnNumber: turnNumber,
    );
  }

  // Record critical damage
  void recordCriticalDamage(String playerId, String targetId, int damage, String damageType, int turnNumber) {
    _addAction(
      ReplayActionType.damageDealt,
      playerId,
      targetId: targetId,
      data: {
        'damage': damage,
        'damageType': damageType,
        'isCritical': true,
      },
      turnNumber: turnNumber,
    );
  }

  // Record healing received
  void recordHealingReceived(String playerId, int healing, int turnNumber) {
    _addAction(
      ReplayActionType.healingReceived,
      playerId,
      data: {
        'healing': healing,
      },
      turnNumber: turnNumber,
    );
  }

  // Record player defeated
  void recordPlayerDefeated(String playerId, String defeatedBy, int turnNumber) {
    _addAction(
      ReplayActionType.playerDefeated,
      defeatedBy,
      targetId: playerId,
      data: {
        'defeatedPlayer': playerId,
      },
      turnNumber: turnNumber,
    );
  }

  // Record turn end
  void recordTurnEnd(String playerId, int turnNumber) {
    _addAction(ReplayActionType.turnEnd, playerId, turnNumber: turnNumber);
  }

  // Record battle end
  void recordBattleEnd(String? winnerId, Map<String, dynamic> finalStats) {
    _addAction(
      ReplayActionType.battleEnd,
      winnerId ?? '',
      data: {
        'winnerId': winnerId,
        'finalStats': finalStats,
      },
      turnNumber: 0,
    );
  }

  void _addAction(
    ReplayActionType type,
    String playerId, {
    String? targetId,
    Map<String, dynamic>? data,
    required int turnNumber,
  }) {
    final action = ReplayAction(
      type: type,
      playerId: playerId,
      targetId: targetId,
      data: data ?? {},
      turnNumber: turnNumber,
    );
    _actions.add(action);
  }

  // Create battle replay
  BattleReplay createReplay({
    String? winnerId,
    Map<String, dynamic>? finalStats,
  }) {
    final endTime = DateTime.now();
    final duration = endTime.difference(_startTime);
    
    return BattleReplay(
      battleId: _battleId,
      battleName: _battleName,
      playerIds: _playerIds,
      playerNames: _playerNames,
      battleStartTime: _startTime,
      battleEndTime: endTime,
      battleDuration: duration,
      winnerId: winnerId,
      actions: List.from(_actions),
      battleSettings: _battleSettings,
      finalStats: finalStats ?? {},
    );
  }

  // Get current actions
  List<ReplayAction> get currentActions => List.unmodifiable(_actions);
} 