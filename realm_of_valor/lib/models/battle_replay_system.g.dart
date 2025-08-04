// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'battle_replay_system.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReplayAction _$ReplayActionFromJson(Map<String, dynamic> json) => ReplayAction(
      id: json['id'] as String?,
      type: $enumDecode(_$ReplayActionTypeEnumMap, json['type']),
      playerId: json['playerId'] as String,
      targetId: json['targetId'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      turnNumber: (json['turnNumber'] as num).toInt(),
    );

Map<String, dynamic> _$ReplayActionToJson(ReplayAction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$ReplayActionTypeEnumMap[instance.type]!,
      'playerId': instance.playerId,
      'targetId': instance.targetId,
      'data': instance.data,
      'timestamp': instance.timestamp.toIso8601String(),
      'turnNumber': instance.turnNumber,
    };

const _$ReplayActionTypeEnumMap = {
  ReplayActionType.turnStart: 'turnStart',
  ReplayActionType.cardPlayed: 'cardPlayed',
  ReplayActionType.skillUsed: 'skillUsed',
  ReplayActionType.attackPerformed: 'attackPerformed',
  ReplayActionType.damageDealt: 'damageDealt',
  ReplayActionType.healingReceived: 'healingReceived',
  ReplayActionType.playerDefeated: 'playerDefeated',
  ReplayActionType.turnEnd: 'turnEnd',
  ReplayActionType.battleEnd: 'battleEnd',
};

BattleReplay _$BattleReplayFromJson(Map<String, dynamic> json) => BattleReplay(
      id: json['id'] as String?,
      battleId: json['battleId'] as String,
      battleName: json['battleName'] as String,
      playerIds:
          (json['playerIds'] as List<dynamic>).map((e) => e as String).toList(),
      playerNames: (json['playerNames'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      battleStartTime: DateTime.parse(json['battleStartTime'] as String),
      battleEndTime: DateTime.parse(json['battleEndTime'] as String),
      battleDuration:
          Duration(microseconds: (json['battleDuration'] as num).toInt()),
      winnerId: json['winnerId'] as String?,
      actions: (json['actions'] as List<dynamic>?)
          ?.map((e) => ReplayAction.fromJson(e as Map<String, dynamic>))
          .toList(),
      battleSettings: json['battleSettings'] as Map<String, dynamic>?,
      finalStats: json['finalStats'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$BattleReplayToJson(BattleReplay instance) =>
    <String, dynamic>{
      'id': instance.id,
      'battleId': instance.battleId,
      'battleName': instance.battleName,
      'playerIds': instance.playerIds,
      'playerNames': instance.playerNames,
      'battleStartTime': instance.battleStartTime.toIso8601String(),
      'battleEndTime': instance.battleEndTime.toIso8601String(),
      'battleDuration': instance.battleDuration.inMicroseconds,
      'winnerId': instance.winnerId,
      'actions': instance.actions,
      'battleSettings': instance.battleSettings,
      'finalStats': instance.finalStats,
    };
