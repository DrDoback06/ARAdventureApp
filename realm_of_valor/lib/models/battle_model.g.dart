// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'battle_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActionCard _$ActionCardFromJson(Map<String, dynamic> json) => ActionCard(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$ActionCardTypeEnumMap, json['type']),
      effect: json['effect'] as String,
      cost: (json['cost'] as num?)?.toInt() ?? 0,
      physicalRequirement: json['physicalRequirement'] as String? ?? '',
      properties: json['properties'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ActionCardToJson(ActionCard instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'type': _$ActionCardTypeEnumMap[instance.type]!,
      'effect': instance.effect,
      'cost': instance.cost,
      'physicalRequirement': instance.physicalRequirement,
      'properties': instance.properties,
    };

const _$ActionCardTypeEnumMap = {
  ActionCardType.buff: 'buff',
  ActionCardType.debuff: 'debuff',
  ActionCardType.damage: 'damage',
  ActionCardType.heal: 'heal',
  ActionCardType.skip: 'skip',
  ActionCardType.counter: 'counter',
  ActionCardType.special: 'special',
  ActionCardType.physical: 'physical',
};

BattlePlayer _$BattlePlayerFromJson(Map<String, dynamic> json) => BattlePlayer(
      id: json['id'] as String?,
      name: json['name'] as String,
      character:
          GameCharacter.fromJson(json['character'] as Map<String, dynamic>),
      hand: (json['hand'] as List<dynamic>?)
          ?.map((e) => ActionCard.fromJson(e as Map<String, dynamic>))
          .toList(),
      actionDeck: (json['actionDeck'] as List<dynamic>?)
          ?.map((e) => ActionCard.fromJson(e as Map<String, dynamic>))
          .toList(),
      activeSkills: (json['activeSkills'] as List<dynamic>?)
          ?.map((e) => GameCard.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentHealth: (json['currentHealth'] as num?)?.toInt(),
      currentMana: (json['currentMana'] as num?)?.toInt(),
      maxHealth: (json['maxHealth'] as num?)?.toInt(),
      maxMana: (json['maxMana'] as num?)?.toInt(),
      isReady: json['isReady'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? false,
      statusEffects: json['statusEffects'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$BattlePlayerToJson(BattlePlayer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'character': instance.character,
      'hand': instance.hand,
      'actionDeck': instance.actionDeck,
      'activeSkills': instance.activeSkills,
      'currentHealth': instance.currentHealth,
      'currentMana': instance.currentMana,
      'maxHealth': instance.maxHealth,
      'maxMana': instance.maxMana,
      'isReady': instance.isReady,
      'isActive': instance.isActive,
      'statusEffects': instance.statusEffects,
    };

BattleLog _$BattleLogFromJson(Map<String, dynamic> json) => BattleLog(
      id: json['id'] as String?,
      playerId: json['playerId'] as String,
      action: json['action'] as String,
      description: json['description'] as String,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      data: json['data'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$BattleLogToJson(BattleLog instance) => <String, dynamic>{
      'id': instance.id,
      'playerId': instance.playerId,
      'action': instance.action,
      'description': instance.description,
      'timestamp': instance.timestamp.toIso8601String(),
      'data': instance.data,
    };

Battle _$BattleFromJson(Map<String, dynamic> json) => Battle(
      id: json['id'] as String?,
      name: json['name'] as String,
      type: $enumDecode(_$BattleTypeEnumMap, json['type']),
      status: $enumDecodeNullable(_$BattleStatusEnumMap, json['status']) ??
          BattleStatus.waiting,
      players: (json['players'] as List<dynamic>?)
          ?.map((e) => BattlePlayer.fromJson(e as Map<String, dynamic>))
          .toList(),
      battleLog: (json['battleLog'] as List<dynamic>?)
          ?.map((e) => BattleLog.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentTurn: (json['currentTurn'] as num?)?.toInt() ?? 0,
      currentPlayerId: json['currentPlayerId'] as String? ?? '',
      maxTurns: (json['maxTurns'] as num?)?.toInt() ?? 50,
      startTime: json['startTime'] == null
          ? null
          : DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      winnerId: json['winnerId'] as String?,
      battleSettings: json['battleSettings'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$BattleToJson(Battle instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$BattleTypeEnumMap[instance.type]!,
      'status': _$BattleStatusEnumMap[instance.status]!,
      'players': instance.players,
      'battleLog': instance.battleLog,
      'currentTurn': instance.currentTurn,
      'currentPlayerId': instance.currentPlayerId,
      'maxTurns': instance.maxTurns,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'winnerId': instance.winnerId,
      'battleSettings': instance.battleSettings,
    };

const _$BattleTypeEnumMap = {
  BattleType.pvp: 'pvp',
  BattleType.pve: 'pve',
  BattleType.tournament: 'tournament',
};

const _$BattleStatusEnumMap = {
  BattleStatus.waiting: 'waiting',
  BattleStatus.active: 'active',
  BattleStatus.paused: 'paused',
  BattleStatus.finished: 'finished',
  BattleStatus.abandoned: 'abandoned',
};

EnemyCard _$EnemyCardFromJson(Map<String, dynamic> json) => EnemyCard(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String,
      health: (json['health'] as num).toInt(),
      mana: (json['mana'] as num).toInt(),
      attackPower: (json['attackPower'] as num).toInt(),
      defense: (json['defense'] as num).toInt(),
      abilities: (json['abilities'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      weaknesses: (json['weaknesses'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      imageUrl: json['imageUrl'] as String? ?? '',
      rarity: $enumDecodeNullable(_$CardRarityEnumMap, json['rarity']) ??
          CardRarity.common,
      battleActions: json['battleActions'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$EnemyCardToJson(EnemyCard instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'health': instance.health,
      'mana': instance.mana,
      'attackPower': instance.attackPower,
      'defense': instance.defense,
      'abilities': instance.abilities,
      'weaknesses': instance.weaknesses,
      'imageUrl': instance.imageUrl,
      'rarity': _$CardRarityEnumMap[instance.rarity]!,
      'battleActions': instance.battleActions,
    };

const _$CardRarityEnumMap = {
  CardRarity.common: 'common',
  CardRarity.uncommon: 'uncommon',
  CardRarity.rare: 'rare',
  CardRarity.epic: 'epic',
  CardRarity.legendary: 'legendary',
  CardRarity.mythic: 'mythic',
  CardRarity.holographic: 'holographic',
  CardRarity.firstEdition: 'firstEdition',
  CardRarity.limitedEdition: 'limitedEdition',
};
