import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/character_model.dart';

enum GuildRank {
  member,
  officer,
  leader,
}

enum GuildEventType {
  battle,
  quest,
  raid,
  social,
}

enum TradeStatus {
  pending,
  accepted,
  declined,
  cancelled,
}

enum RelationshipType {
  friend,
  rival,
  mentor,
  student,
}

class GuildMember {
  final String id;
  final String name;
  final int level;
  final GuildRank rank;
  final DateTime joinedAt;
  final int contribution;
  final bool isOnline;

  const GuildMember({
    required this.id,
    required this.name,
    required this.level,
    required this.rank,
    required this.joinedAt,
    this.contribution = 0,
    this.isOnline = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'level': level,
      'rank': rank.name,
      'joinedAt': joinedAt.millisecondsSinceEpoch,
      'contribution': contribution,
      'isOnline': isOnline,
    };
  }

  factory GuildMember.fromJson(Map<String, dynamic> json) {
    return GuildMember(
      id: json['id'] as String,
      name: json['name'] as String,
      level: json['level'] as int,
      rank: GuildRank.values.firstWhere(
        (e) => e.name == json['rank'],
      ),
      joinedAt: DateTime.fromMillisecondsSinceEpoch(json['joinedAt'] as int),
      contribution: json['contribution'] as int? ?? 0,
      isOnline: json['isOnline'] as bool? ?? false,
    );
  }
}

class Guild {
  final String id;
  final String name;
  final String description;
  final String leaderId;
  final List<GuildMember> members;
  final int level;
  final int experience;
  final DateTime createdAt;
  final String? banner;

  const Guild({
    required this.id,
    required this.name,
    required this.description,
    required this.leaderId,
    required this.members,
    this.level = 1,
    this.experience = 0,
    required this.createdAt,
    this.banner,
  });

  Guild copyWith({
    String? name,
    String? description,
    List<GuildMember>? members,
    int? level,
    int? experience,
  }) {
    return Guild(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      leaderId: leaderId,
      members: members ?? this.members,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      createdAt: createdAt,
      banner: banner,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'leaderId': leaderId,
      'members': members.map((member) => member.toJson()).toList(),
      'level': level,
      'experience': experience,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'banner': banner,
    };
  }

  factory Guild.fromJson(Map<String, dynamic> json) {
    return Guild(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      leaderId: json['leaderId'] as String,
      members: (json['members'] as List)
          .map((memberJson) => GuildMember.fromJson(Map<String, dynamic>.from(memberJson as Map)))
          .toList(),
      level: json['level'] as int? ?? 1,
      experience: json['experience'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      banner: json['banner'] as String?,
    );
  }
}

class GuildEvent {
  final String id;
  final String guildId;
  final String title;
  final String description;
  final GuildEventType type;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> participants;
  final Map<String, dynamic> rewards;

  const GuildEvent({
    required this.id,
    required this.guildId,
    required this.title,
    required this.description,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.participants,
    required this.rewards,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'guildId': guildId,
      'title': title,
      'description': description,
      'type': type.name,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'participants': participants,
      'rewards': rewards,
    };
  }

  factory GuildEvent.fromJson(Map<String, dynamic> json) {
    return GuildEvent(
      id: json['id'] as String,
      guildId: json['guildId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: GuildEventType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      startTime: DateTime.fromMillisecondsSinceEpoch(json['startTime'] as int),
      endTime: DateTime.fromMillisecondsSinceEpoch(json['endTime'] as int),
      participants: List<String>.from(json['participants'] as List),
      rewards: Map<String, dynamic>.from(json['rewards'] as Map),
    );
  }
}

class TradeOffer {
  final String id;
  final String fromPlayerId;
  final String toPlayerId;
  final List<String> offeredItems;
  final List<String> requestedItems;
  final int offeredGold;
  final int requestedGold;
  final TradeStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  const TradeOffer({
    required this.id,
    required this.fromPlayerId,
    required this.toPlayerId,
    required this.offeredItems,
    required this.requestedItems,
    this.offeredGold = 0,
    this.requestedGold = 0,
    this.status = TradeStatus.pending,
    required this.createdAt,
    this.respondedAt,
  });

  TradeOffer copyWith({
    TradeStatus? status,
    DateTime? respondedAt,
  }) {
    return TradeOffer(
      id: id,
      fromPlayerId: fromPlayerId,
      toPlayerId: toPlayerId,
      offeredItems: offeredItems,
      requestedItems: requestedItems,
      offeredGold: offeredGold,
      requestedGold: requestedGold,
      status: status ?? this.status,
      createdAt: createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromPlayerId': fromPlayerId,
      'toPlayerId': toPlayerId,
      'offeredItems': offeredItems,
      'requestedItems': requestedItems,
      'offeredGold': offeredGold,
      'requestedGold': requestedGold,
      'status': status.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'respondedAt': respondedAt?.millisecondsSinceEpoch,
    };
  }

  factory TradeOffer.fromJson(Map<String, dynamic> json) {
    return TradeOffer(
      id: json['id'] as String,
      fromPlayerId: json['fromPlayerId'] as String,
      toPlayerId: json['toPlayerId'] as String,
      offeredItems: List<String>.from(json['offeredItems'] as List),
      requestedItems: List<String>.from(json['requestedItems'] as List),
      offeredGold: json['offeredGold'] as int? ?? 0,
      requestedGold: json['requestedGold'] as int? ?? 0,
      status: TradeStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      respondedAt: json['respondedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['respondedAt'] as int)
          : null,
    );
  }
}

class SocialRelationship {
  final String id;
  final String playerId;
  final String friendId;
  final RelationshipType type;
  final DateTime createdAt;
  final int interactionCount;

  const SocialRelationship({
    required this.id,
    required this.playerId,
    required this.friendId,
    required this.type,
    required this.createdAt,
    this.interactionCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'playerId': playerId,
      'friendId': friendId,
      'type': type.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'interactionCount': interactionCount,
    };
  }

  factory SocialRelationship.fromJson(Map<String, dynamic> json) {
    return SocialRelationship(
      id: json['id'] as String,
      playerId: json['playerId'] as String,
      friendId: json['friendId'] as String,
      type: RelationshipType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      interactionCount: json['interactionCount'] as int? ?? 0,
    );
  }
}

class SocialService extends ChangeNotifier {
  static SocialService? _instance;
  static SocialService get instance => _instance ??= SocialService._();
  SocialService._();

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // Social data
  final List<SocialRelationship> _relationships = [];
  final List<TradeOffer> _tradeOffers = [];
  final List<Guild> _guilds = [];
  final List<GuildEvent> _guildEvents = [];
  String? _currentGuildId;

  // Getters
  List<SocialRelationship> get relationships => List.unmodifiable(_relationships);
  List<TradeOffer> get tradeOffers => List.unmodifiable(_tradeOffers);
  List<Guild> get guilds => List.unmodifiable(_guilds);
  List<GuildEvent> get guildEvents => List.unmodifiable(_guildEvents);
  String? get currentGuildId => _currentGuildId;

  // Initialize service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    await _loadSocialData();
    _initializeSampleData();
    _isInitialized = true;
    notifyListeners();
  }

  // Load social data from preferences
  Future<void> _loadSocialData() async {
    final relationshipsJson = _prefs.getStringList('social_relationships') ?? [];
    _relationships.clear();
    for (final json in relationshipsJson) {
      try {
        final data = Map<String, dynamic>.from(json as Map);
        _relationships.add(SocialRelationship.fromJson(data));
      } catch (e) {
        if (kDebugMode) {
          print('[SocialService] Error loading relationship: $e');
        }
      }
    }

    final tradeOffersJson = _prefs.getStringList('social_trade_offers') ?? [];
    _tradeOffers.clear();
    for (final json in tradeOffersJson) {
      try {
        final data = Map<String, dynamic>.from(json as Map);
        _tradeOffers.add(TradeOffer.fromJson(data));
      } catch (e) {
        if (kDebugMode) {
          print('[SocialService] Error loading trade offer: $e');
        }
      }
    }

    final guildsJson = _prefs.getStringList('social_guilds') ?? [];
    _guilds.clear();
    for (final json in guildsJson) {
      try {
        final data = Map<String, dynamic>.from(json as Map);
        _guilds.add(Guild.fromJson(data));
      } catch (e) {
        if (kDebugMode) {
          print('[SocialService] Error loading guild: $e');
        }
      }
    }

    _currentGuildId = _prefs.getString('social_current_guild');
  }

  // Save social data to preferences
  Future<void> _saveSocialData() async {
    final relationshipsJson = _relationships
        .map((relationship) => relationship.toJson().toString())
        .toList();
    await _prefs.setStringList('social_relationships', relationshipsJson);

    final tradeOffersJson = _tradeOffers
        .map((offer) => offer.toJson().toString())
        .toList();
    await _prefs.setStringList('social_trade_offers', tradeOffersJson);

    final guildsJson = _guilds
        .map((guild) => guild.toJson().toString())
        .toList();
    await _prefs.setStringList('social_guilds', guildsJson);

    if (_currentGuildId != null) {
      await _prefs.setString('social_current_guild', _currentGuildId!);
    }
  }

  // Initialize sample data
  void _initializeSampleData() {
    // Create sample guilds
    if (_guilds.isEmpty) {
      _guilds.add(Guild(
        id: 'guild_1',
        name: 'Dragon Slayers',
        description: 'Elite guild focused on defeating powerful dragons',
        leaderId: 'player_1',
        members: [
          GuildMember(
            id: 'player_1',
            name: 'DragonSlayer',
            level: 25,
            rank: GuildRank.leader,
            joinedAt: DateTime.now().subtract(const Duration(days: 30)),
            contribution: 1500,
            isOnline: true,
          ),
          GuildMember(
            id: 'player_2',
            name: 'FireMage',
            level: 20,
            rank: GuildRank.officer,
            joinedAt: DateTime.now().subtract(const Duration(days: 25)),
            contribution: 800,
            isOnline: false,
          ),
          GuildMember(
            id: 'player_3',
            name: 'IceWarrior',
            level: 18,
            rank: GuildRank.member,
            joinedAt: DateTime.now().subtract(const Duration(days: 15)),
            contribution: 400,
            isOnline: true,
          ),
        ],
        level: 3,
        experience: 2500,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ));

      _guilds.add(Guild(
        id: 'guild_2',
        name: 'Shadow Assassins',
        description: 'Stealth-focused guild for advanced players',
        leaderId: 'player_4',
        members: [
          GuildMember(
            id: 'player_4',
            name: 'ShadowMaster',
            level: 30,
            rank: GuildRank.leader,
            joinedAt: DateTime.now().subtract(const Duration(days: 45)),
            contribution: 2000,
            isOnline: true,
          ),
        ],
        level: 2,
        experience: 1200,
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
      ));
    }

    // Create sample relationships
    if (_relationships.isEmpty) {
      _relationships.add(SocialRelationship(
        id: 'rel_1',
        playerId: 'current_player',
        friendId: 'player_1',
        type: RelationshipType.friend,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        interactionCount: 15,
      ));

      _relationships.add(SocialRelationship(
        id: 'rel_2',
        playerId: 'current_player',
        friendId: 'player_2',
        type: RelationshipType.rival,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        interactionCount: 8,
      ));
    }

    // Create sample trade offers
    if (_tradeOffers.isEmpty) {
      _tradeOffers.add(TradeOffer(
        id: 'trade_1',
        fromPlayerId: 'player_1',
        toPlayerId: 'current_player',
        offeredItems: ['sword_legendary'],
        requestedItems: ['shield_epic'],
        offeredGold: 100,
        requestedGold: 50,
        status: TradeStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ));
    }

    // Create sample guild events
    if (_guildEvents.isEmpty) {
      _guildEvents.add(GuildEvent(
        id: 'event_1',
        guildId: 'guild_1',
        title: 'Dragon Raid',
        description: 'Join us for an epic dragon raid!',
        type: GuildEventType.raid,
        startTime: DateTime.now().add(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 4)),
        participants: ['player_1', 'player_2'],
        rewards: {'experience': 500, 'gold': 200, 'items': ['dragon_scales']},
      ));
    }
  }

  // Friend system methods
  void addFriend(String friendId, RelationshipType type) {
    final existingRelationship = _relationships.any(
      (rel) => rel.playerId == 'current_player' && rel.friendId == friendId,
    );

    if (existingRelationship) {
      if (kDebugMode) {
        print('[SocialService] Relationship already exists');
      }
      return;
    }

    final relationship = SocialRelationship(
      id: 'rel_${DateTime.now().millisecondsSinceEpoch}',
      playerId: 'current_player',
      friendId: friendId,
      type: type,
      createdAt: DateTime.now(),
    );

    _relationships.add(relationship);
    _saveSocialData();
    notifyListeners();

    if (kDebugMode) {
      print('[SocialService] Added friend: $friendId');
    }
  }

  void removeFriend(String friendId) {
    _relationships.removeWhere(
      (rel) => rel.playerId == 'current_player' && rel.friendId == friendId,
    );
    _saveSocialData();
    notifyListeners();

    if (kDebugMode) {
      print('[SocialService] Removed friend: $friendId');
    }
  }

  List<SocialRelationship> getFriends() {
    return _relationships.where(
      (rel) => rel.playerId == 'current_player' && rel.type == RelationshipType.friend,
    ).toList();
  }

  List<SocialRelationship> getRivals() {
    return _relationships.where(
      (rel) => rel.playerId == 'current_player' && rel.type == RelationshipType.rival,
    ).toList();
  }

  // Guild system methods
  void createGuild(String name, String description) {
    final guild = Guild(
      id: 'guild_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      leaderId: 'current_player',
      members: [
        GuildMember(
          id: 'current_player',
          name: 'Current Player',
          level: 15,
          rank: GuildRank.leader,
          joinedAt: DateTime.now(),
          contribution: 0,
          isOnline: true,
        ),
      ],
      level: 1,
      experience: 0,
      createdAt: DateTime.now(),
    );

    _guilds.add(guild);
    _currentGuildId = guild.id;
    _saveSocialData();
    notifyListeners();

    if (kDebugMode) {
      print('[SocialService] Created guild: $name');
    }
  }

  void joinGuild(String guildId) {
    final guild = _guilds.firstWhere((g) => g.id == guildId);
    final member = GuildMember(
      id: 'current_player',
      name: 'Current Player',
      level: 15,
      rank: GuildRank.member,
      joinedAt: DateTime.now(),
      contribution: 0,
      isOnline: true,
    );

    final updatedGuild = guild.copyWith(
      members: [...guild.members, member],
    );

    final index = _guilds.indexWhere((g) => g.id == guildId);
    if (index != -1) {
      _guilds[index] = updatedGuild;
      _currentGuildId = guildId;
      _saveSocialData();
      notifyListeners();

      if (kDebugMode) {
        print('[SocialService] Joined guild: ${guild.name}');
      }
    }
  }

  void leaveGuild() {
    if (_currentGuildId == null) return;

    final guild = _guilds.firstWhere((g) => g.id == _currentGuildId);
    final updatedMembers = guild.members.where(
      (member) => member.id != 'current_player',
    ).toList();

    final updatedGuild = guild.copyWith(members: updatedMembers);
    final index = _guilds.indexWhere((g) => g.id == _currentGuildId);
    
    if (index != -1) {
      _guilds[index] = updatedGuild;
      _currentGuildId = null;
      _saveSocialData();
      notifyListeners();

      if (kDebugMode) {
        print('[SocialService] Left guild: ${guild.name}');
      }
    }
  }

  Guild? getCurrentGuild() {
    if (_currentGuildId == null) return null;
    try {
      return _guilds.firstWhere((g) => g.id == _currentGuildId);
    } catch (e) {
      return null;
    }
  }

  // Trade system methods
  void createTradeOffer(
    String toPlayerId,
    List<String> offeredItems,
    List<String> requestedItems,
    int offeredGold,
    int requestedGold,
  ) {
    final tradeOffer = TradeOffer(
      id: 'trade_${DateTime.now().millisecondsSinceEpoch}',
      fromPlayerId: 'current_player',
      toPlayerId: toPlayerId,
      offeredItems: offeredItems,
      requestedItems: requestedItems,
      offeredGold: offeredGold,
      requestedGold: requestedGold,
      status: TradeStatus.pending,
      createdAt: DateTime.now(),
    );

    _tradeOffers.add(tradeOffer);
    _saveSocialData();
    notifyListeners();

    if (kDebugMode) {
      print('[SocialService] Created trade offer to: $toPlayerId');
    }
  }

  void respondToTradeOffer(String tradeId, TradeStatus response) {
    final index = _tradeOffers.indexWhere((offer) => offer.id == tradeId);
    if (index != -1) {
      final offer = _tradeOffers[index];
      final updatedOffer = offer.copyWith(
        status: response,
        respondedAt: DateTime.now(),
      );

      _tradeOffers[index] = updatedOffer;
      _saveSocialData();
      notifyListeners();

      if (kDebugMode) {
        print('[SocialService] Responded to trade offer: $response');
      }
    }
  }

  List<TradeOffer> getPendingTradeOffers() {
    return _tradeOffers.where(
      (offer) => offer.toPlayerId == 'current_player' && offer.status == TradeStatus.pending,
    ).toList();
  }

  List<TradeOffer> getSentTradeOffers() {
    return _tradeOffers.where(
      (offer) => offer.fromPlayerId == 'current_player',
    ).toList();
  }

  // Guild event methods
  void createGuildEvent(
    String title,
    String description,
    GuildEventType type,
    DateTime startTime,
    DateTime endTime,
    Map<String, dynamic> rewards,
  ) {
    final currentGuild = getCurrentGuild();
    if (currentGuild == null) return;

    final event = GuildEvent(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}',
      guildId: currentGuild.id,
      title: title,
      description: description,
      type: type,
      startTime: startTime,
      endTime: endTime,
      participants: ['current_player'],
      rewards: rewards,
    );

    _guildEvents.add(event);
    _saveSocialData();
    notifyListeners();

    if (kDebugMode) {
      print('[SocialService] Created guild event: $title');
    }
  }

  void joinGuildEvent(String eventId) {
    final index = _guildEvents.indexWhere((event) => event.id == eventId);
    if (index != -1) {
      final event = _guildEvents[index];
      if (!event.participants.contains('current_player')) {
        final updatedParticipants = [...event.participants, 'current_player'];
        final updatedEvent = GuildEvent(
          id: event.id,
          guildId: event.guildId,
          title: event.title,
          description: event.description,
          type: event.type,
          startTime: event.startTime,
          endTime: event.endTime,
          participants: updatedParticipants,
          rewards: event.rewards,
        );

        _guildEvents[index] = updatedEvent;
        _saveSocialData();
        notifyListeners();

        if (kDebugMode) {
          print('[SocialService] Joined guild event: ${event.title}');
        }
      }
    }
  }

  List<GuildEvent> getCurrentGuildEvents() {
    if (_currentGuildId == null) return [];
    return _guildEvents.where((event) => event.guildId == _currentGuildId).toList();
  }

  // Social statistics
  Map<String, dynamic> getSocialStatistics() {
    final friends = getFriends();
    final rivals = getRivals();
    final currentGuild = getCurrentGuild();
    final pendingTrades = getPendingTradeOffers();

    return {
      'friendsCount': friends.length,
      'rivalsCount': rivals.length,
      'guildMembership': currentGuild != null,
      'guildName': currentGuild?.name,
      'guildLevel': currentGuild?.level ?? 0,
      'pendingTrades': pendingTrades.length,
      'totalRelationships': _relationships.length,
      'totalTradeOffers': _tradeOffers.length,
      'totalGuilds': _guilds.length,
      'totalGuildEvents': _guildEvents.length,
    };
  }
} 