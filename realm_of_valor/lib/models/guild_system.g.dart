// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guild_system.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GuildMember _$GuildMemberFromJson(Map<String, dynamic> json) => GuildMember(
      id: json['id'] as String?,
      playerId: json['playerId'] as String,
      playerName: json['playerName'] as String,
      playerAvatar: json['playerAvatar'] as String? ?? '',
      rank: $enumDecodeNullable(_$GuildRankEnumMap, json['rank']) ??
          GuildRank.member,
      contributionPoints: (json['contributionPoints'] as num?)?.toInt() ?? 0,
      activityScore: (json['activityScore'] as num?)?.toInt() ?? 0,
      joinedDate: json['joinedDate'] == null
          ? null
          : DateTime.parse(json['joinedDate'] as String),
      lastActive: json['lastActive'] == null
          ? null
          : DateTime.parse(json['lastActive'] as String),
      achievements: json['achievements'] as Map<String, dynamic>?,
      specialties: (json['specialties'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$GuildMemberToJson(GuildMember instance) =>
    <String, dynamic>{
      'id': instance.id,
      'playerId': instance.playerId,
      'playerName': instance.playerName,
      'playerAvatar': instance.playerAvatar,
      'rank': _$GuildRankEnumMap[instance.rank]!,
      'contributionPoints': instance.contributionPoints,
      'activityScore': instance.activityScore,
      'joinedDate': instance.joinedDate.toIso8601String(),
      'lastActive': instance.lastActive.toIso8601String(),
      'achievements': instance.achievements,
      'specialties': instance.specialties,
      'metadata': instance.metadata,
    };

const _$GuildRankEnumMap = {
  GuildRank.member: 'member',
  GuildRank.officer: 'officer',
  GuildRank.captain: 'captain',
  GuildRank.general: 'general',
  GuildRank.guildmaster: 'guildmaster',
};

Guild _$GuildFromJson(Map<String, dynamic> json) => Guild(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String,
      emblem: json['emblem'] as String? ?? '',
      motto: json['motto'] as String? ?? '',
      members: (json['members'] as List<dynamic>?)
          ?.map((e) => GuildMember.fromJson(e as Map<String, dynamic>))
          .toList(),
      level: (json['level'] as num?)?.toInt() ?? 1,
      experience: (json['experience'] as num?)?.toInt() ?? 0,
      treasury: (json['treasury'] as num?)?.toInt() ?? 0,
      perks: json['perks'] as Map<String, dynamic>?,
      achievements: (json['achievements'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      createdDate: json['createdDate'] == null
          ? null
          : DateTime.parse(json['createdDate'] as String),
      settings: json['settings'] as Map<String, dynamic>?,
      bannedPlayers: (json['bannedPlayers'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      statistics: json['statistics'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$GuildToJson(Guild instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'emblem': instance.emblem,
      'motto': instance.motto,
      'members': instance.members,
      'level': instance.level,
      'experience': instance.experience,
      'treasury': instance.treasury,
      'perks': instance.perks,
      'achievements': instance.achievements,
      'createdDate': instance.createdDate.toIso8601String(),
      'settings': instance.settings,
      'bannedPlayers': instance.bannedPlayers,
      'statistics': instance.statistics,
    };

GuildEvent _$GuildEventFromJson(Map<String, dynamic> json) => GuildEvent(
      id: json['id'] as String?,
      guildId: json['guildId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$GuildEventTypeEnumMap, json['type']),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      participants: (json['participants'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      requirements: json['requirements'] as Map<String, dynamic>?,
      rewards: json['rewards'] as Map<String, dynamic>?,
      progress: json['progress'] as Map<String, dynamic>?,
      isActive: json['isActive'] as bool? ?? true,
      createdBy: json['createdBy'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$GuildEventToJson(GuildEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'guildId': instance.guildId,
      'name': instance.name,
      'description': instance.description,
      'type': _$GuildEventTypeEnumMap[instance.type]!,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'participants': instance.participants,
      'requirements': instance.requirements,
      'rewards': instance.rewards,
      'progress': instance.progress,
      'isActive': instance.isActive,
      'createdBy': instance.createdBy,
      'metadata': instance.metadata,
    };

const _$GuildEventTypeEnumMap = {
  GuildEventType.raid: 'raid',
  GuildEventType.tournament: 'tournament',
  GuildEventType.treasure_hunt: 'treasure_hunt',
  GuildEventType.exploration: 'exploration',
  GuildEventType.social: 'social',
  GuildEventType.training: 'training',
  GuildEventType.charity: 'charity',
};

TradeOffer _$TradeOfferFromJson(Map<String, dynamic> json) => TradeOffer(
      id: json['id'] as String?,
      fromPlayerId: json['fromPlayerId'] as String,
      toPlayerId: json['toPlayerId'] as String,
      offeredCardIds: (json['offeredCardIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      requestedCardIds: (json['requestedCardIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      goldOffered: (json['goldOffered'] as num?)?.toInt() ?? 0,
      goldRequested: (json['goldRequested'] as num?)?.toInt() ?? 0,
      message: json['message'] as String? ?? '',
      status: $enumDecodeNullable(_$TradeStatusEnumMap, json['status']) ??
          TradeStatus.pending,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$TradeOfferToJson(TradeOffer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fromPlayerId': instance.fromPlayerId,
      'toPlayerId': instance.toPlayerId,
      'offeredCardIds': instance.offeredCardIds,
      'requestedCardIds': instance.requestedCardIds,
      'goldOffered': instance.goldOffered,
      'goldRequested': instance.goldRequested,
      'message': instance.message,
      'status': _$TradeStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'metadata': instance.metadata,
    };

const _$TradeStatusEnumMap = {
  TradeStatus.pending: 'pending',
  TradeStatus.active: 'active',
  TradeStatus.completed: 'completed',
  TradeStatus.cancelled: 'cancelled',
  TradeStatus.expired: 'expired',
};

SocialRelationship _$SocialRelationshipFromJson(Map<String, dynamic> json) =>
    SocialRelationship(
      id: json['id'] as String?,
      playerId: json['playerId'] as String,
      relatedPlayerId: json['relatedPlayerId'] as String,
      type: $enumDecode(_$RelationshipTypeEnumMap, json['type']),
      note: json['note'] as String? ?? '',
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      lastInteraction: json['lastInteraction'] == null
          ? null
          : DateTime.parse(json['lastInteraction'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$SocialRelationshipToJson(SocialRelationship instance) =>
    <String, dynamic>{
      'id': instance.id,
      'playerId': instance.playerId,
      'relatedPlayerId': instance.relatedPlayerId,
      'type': _$RelationshipTypeEnumMap[instance.type]!,
      'note': instance.note,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastInteraction': instance.lastInteraction.toIso8601String(),
      'metadata': instance.metadata,
    };

const _$RelationshipTypeEnumMap = {
  RelationshipType.friend: 'friend',
  RelationshipType.rival: 'rival',
  RelationshipType.mentor: 'mentor',
  RelationshipType.student: 'student',
  RelationshipType.ally: 'ally',
  RelationshipType.blocked: 'blocked',
};
