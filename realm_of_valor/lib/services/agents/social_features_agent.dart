import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/event_bus.dart';
import 'integration_orchestrator_agent.dart';

/// Social relationship types
enum SocialRelationType {
  friend,
  blocked,
  pending, // Friend request pending
  guild_member,
  guild_leader,
  guild_officer,
}

/// Social activity types
enum SocialActivityType {
  friend_request,
  quest_invitation,
  guild_invitation,
  battle_challenge,
  trade_request,
  achievement_share,
  location_share,
  guild_quest,
  social_event,
}

/// Guild permission levels
enum GuildPermission {
  member, // Basic member
  officer, // Can invite, manage events
  leader, // Full control
}

/// Social notification types
enum SocialNotificationType {
  friend_request_received,
  friend_request_accepted,
  guild_invitation,
  quest_invitation,
  battle_challenge,
  guild_announcement,
  achievement_celebration,
  location_event,
}

/// User profile for social features
class SocialProfile {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int level;
  final String status; // online, offline, away, busy
  final Map<String, dynamic> stats;
  final List<String> badges;
  final DateTime lastSeen;
  final bool isOnline;
  final Map<String, dynamic> preferences;

  SocialProfile({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.level = 1,
    this.status = 'offline',
    Map<String, dynamic>? stats,
    List<String>? badges,
    DateTime? lastSeen,
    this.isOnline = false,
    Map<String, dynamic>? preferences,
  }) : stats = stats ?? {},
       badges = badges ?? [],
       lastSeen = lastSeen ?? DateTime.now(),
       preferences = preferences ?? {};

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'level': level,
      'status': status,
      'stats': stats,
      'badges': badges,
      'lastSeen': lastSeen.toIso8601String(),
      'isOnline': isOnline,
      'preferences': preferences,
    };
  }

  factory SocialProfile.fromJson(Map<String, dynamic> json) {
    return SocialProfile(
      userId: json['userId'],
      displayName: json['displayName'],
      avatarUrl: json['avatarUrl'],
      level: json['level'] ?? 1,
      status: json['status'] ?? 'offline',
      stats: Map<String, dynamic>.from(json['stats'] ?? {}),
      badges: List<String>.from(json['badges'] ?? []),
      lastSeen: DateTime.parse(json['lastSeen']),
      isOnline: json['isOnline'] ?? false,
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
    );
  }

  SocialProfile copyWith({
    String? displayName,
    String? avatarUrl,
    int? level,
    String? status,
    Map<String, dynamic>? stats,
    List<String>? badges,
    DateTime? lastSeen,
    bool? isOnline,
    Map<String, dynamic>? preferences,
  }) {
    return SocialProfile(
      userId: userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      level: level ?? this.level,
      status: status ?? this.status,
      stats: stats ?? Map.from(this.stats),
      badges: badges ?? List.from(this.badges),
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      preferences: preferences ?? Map.from(this.preferences),
    );
  }
}

/// Social relationship between users
class SocialRelationship {
  final String relationshipId;
  final String userId;
  final String targetUserId;
  final SocialRelationType type;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  SocialRelationship({
    String? relationshipId,
    required this.userId,
    required this.targetUserId,
    required this.type,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) : relationshipId = relationshipId ?? '${userId}_${targetUserId}_${type.toString()}',
       createdAt = createdAt ?? DateTime.now(),
       metadata = metadata ?? {};

  Map<String, dynamic> toJson() {
    return {
      'relationshipId': relationshipId,
      'userId': userId,
      'targetUserId': targetUserId,
      'type': type.toString(),
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory SocialRelationship.fromJson(Map<String, dynamic> json) {
    return SocialRelationship(
      relationshipId: json['relationshipId'],
      userId: json['userId'],
      targetUserId: json['targetUserId'],
      type: SocialRelationType.values.firstWhere(
        (t) => t.toString() == json['type'],
        orElse: () => SocialRelationType.friend,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

/// Guild structure
class Guild {
  final String guildId;
  final String name;
  final String description;
  final String leaderId;
  final List<GuildMember> members;
  final Map<String, dynamic> settings;
  final List<String> tags;
  final DateTime createdAt;
  final Map<String, dynamic> stats;
  final String? bannerUrl;
  final int memberLimit;

  Guild({
    String? guildId,
    required this.name,
    this.description = '',
    required this.leaderId,
    List<GuildMember>? members,
    Map<String, dynamic>? settings,
    List<String>? tags,
    DateTime? createdAt,
    Map<String, dynamic>? stats,
    this.bannerUrl,
    this.memberLimit = 50,
  }) : guildId = guildId ?? 'guild_${DateTime.now().millisecondsSinceEpoch}',
       members = members ?? [],
       settings = settings ?? {},
       tags = tags ?? [],
       createdAt = createdAt ?? DateTime.now(),
       stats = stats ?? {};

  Map<String, dynamic> toJson() {
    return {
      'guildId': guildId,
      'name': name,
      'description': description,
      'leaderId': leaderId,
      'members': members.map((m) => m.toJson()).toList(),
      'settings': settings,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'stats': stats,
      'bannerUrl': bannerUrl,
      'memberLimit': memberLimit,
    };
  }

  factory Guild.fromJson(Map<String, dynamic> json) {
    return Guild(
      guildId: json['guildId'],
      name: json['name'],
      description: json['description'] ?? '',
      leaderId: json['leaderId'],
      members: (json['members'] as List? ?? [])
          .map((m) => GuildMember.fromJson(m))
          .toList(),
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      stats: Map<String, dynamic>.from(json['stats'] ?? {}),
      bannerUrl: json['bannerUrl'],
      memberLimit: json['memberLimit'] ?? 50,
    );
  }
}

/// Guild member information
class GuildMember {
  final String userId;
  final GuildPermission permission;
  final DateTime joinedAt;
  final Map<String, dynamic> contributions;
  final String? title;

  GuildMember({
    required this.userId,
    this.permission = GuildPermission.member,
    DateTime? joinedAt,
    Map<String, dynamic>? contributions,
    this.title,
  }) : joinedAt = joinedAt ?? DateTime.now(),
       contributions = contributions ?? {};

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'permission': permission.toString(),
      'joinedAt': joinedAt.toIso8601String(),
      'contributions': contributions,
      'title': title,
    };
  }

  factory GuildMember.fromJson(Map<String, dynamic> json) {
    return GuildMember(
      userId: json['userId'],
      permission: GuildPermission.values.firstWhere(
        (p) => p.toString() == json['permission'],
        orElse: () => GuildPermission.member,
      ),
      joinedAt: DateTime.parse(json['joinedAt']),
      contributions: Map<String, dynamic>.from(json['contributions'] ?? {}),
      title: json['title'],
    );
  }
}

/// Social activity or invitation
class SocialActivity {
  final String activityId;
  final SocialActivityType type;
  final String fromUserId;
  final String toUserId;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isActive;
  final Map<String, dynamic> responses;

  SocialActivity({
    String? activityId,
    required this.type,
    required this.fromUserId,
    required this.toUserId,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    this.expiresAt,
    this.isActive = true,
    Map<String, dynamic>? responses,
  }) : activityId = activityId ?? 'activity_${DateTime.now().millisecondsSinceEpoch}',
       data = data ?? {},
       createdAt = createdAt ?? DateTime.now(),
       responses = responses ?? {};

  Map<String, dynamic> toJson() {
    return {
      'activityId': activityId,
      'type': type.toString(),
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'isActive': isActive,
      'responses': responses,
    };
  }

  factory SocialActivity.fromJson(Map<String, dynamic> json) {
    return SocialActivity(
      activityId: json['activityId'],
      type: SocialActivityType.values.firstWhere(
        (t) => t.toString() == json['type'],
        orElse: () => SocialActivityType.friend_request,
      ),
      fromUserId: json['fromUserId'],
      toUserId: json['toUserId'],
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      isActive: json['isActive'] ?? true,
      responses: Map<String, dynamic>.from(json['responses'] ?? {}),
    );
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

/// Social notification
class SocialNotification {
  final String notificationId;
  final SocialNotificationType type;
  final String userId;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final bool isRead;
  final List<SocialNotificationAction> actions;

  SocialNotification({
    String? notificationId,
    required this.type,
    required this.userId,
    required this.title,
    required this.message,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    this.isRead = false,
    List<SocialNotificationAction>? actions,
  }) : notificationId = notificationId ?? 'notif_${DateTime.now().millisecondsSinceEpoch}',
       data = data ?? {},
       createdAt = createdAt ?? DateTime.now(),
       actions = actions ?? [];

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'type': type.toString(),
      'userId': userId,
      'title': title,
      'message': message,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'actions': actions.map((a) => a.toJson()).toList(),
    };
  }

  factory SocialNotification.fromJson(Map<String, dynamic> json) {
    return SocialNotification(
      notificationId: json['notificationId'],
      type: SocialNotificationType.values.firstWhere(
        (t) => t.toString() == json['type'],
        orElse: () => SocialNotificationType.friend_request_received,
      ),
      userId: json['userId'],
      title: json['title'],
      message: json['message'],
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
      isRead: json['isRead'] ?? false,
      actions: (json['actions'] as List? ?? [])
          .map((a) => SocialNotificationAction.fromJson(a))
          .toList(),
    );
  }
}

/// Social notification action
class SocialNotificationAction {
  final String actionId;
  final String label;
  final String eventType;
  final Map<String, dynamic> eventData;

  SocialNotificationAction({
    required this.actionId,
    required this.label,
    required this.eventType,
    Map<String, dynamic>? eventData,
  }) : eventData = eventData ?? {};

  Map<String, dynamic> toJson() {
    return {
      'actionId': actionId,
      'label': label,
      'eventType': eventType,
      'eventData': eventData,
    };
  }

  factory SocialNotificationAction.fromJson(Map<String, dynamic> json) {
    return SocialNotificationAction(
      actionId: json['actionId'],
      label: json['label'],
      eventType: json['eventType'],
      eventData: Map<String, dynamic>.from(json['eventData'] ?? {}),
    );
  }
}

/// Social Features Agent - Friend system, guilds, and multiplayer features
class SocialFeaturesAgent extends BaseAgent {
  static const String _agentTypeId = 'social_features';

  final SharedPreferences _prefs;

  // Current user context
  String? _currentUserId;
  SocialProfile? _currentUserProfile;

  // Social system state
  final Map<String, SocialProfile> _userProfiles = {};
  final Map<String, SocialRelationship> _relationships = {};
  final Map<String, Guild> _guilds = {};
  final Map<String, SocialActivity> _activities = {};
  final Map<String, SocialNotification> _notifications = {};

  // Current user's social data
  final List<String> _friendsList = [];
  final List<String> _blockedList = [];
  String? _currentGuildId;

  // Timers and periodic tasks
  Timer? _activityCleanupTimer;
  Timer? _onlineStatusTimer;

  // Performance monitoring
  final List<Map<String, dynamic>> _socialMetrics = [];
  int _totalInteractions = 0;
  DateTime? _lastSocialActivity;

  SocialFeaturesAgent({
    required SharedPreferences prefs,
  }) : _prefs = prefs,
       super(agentId: _agentTypeId);

  @override
  Future<void> onInitialize() async {
    developer.log('Initializing Social Features Agent', name: agentId);

    // Load social data
    await _loadSocialData();

    // Initialize default profiles and guilds
    await _initializeDefaultSocialContent();

    // Start periodic tasks
    _startActivityCleanup();
    _startOnlineStatusUpdates();

    developer.log('Social Features Agent initialized with ${_userProfiles.length} profiles and ${_guilds.length} guilds', name: agentId);
  }

  @override
  void subscribeToEvents() {
    // Character events
    subscribe(EventTypes.characterLevelUp, _handleCharacterLevelUp);
    subscribe(EventTypes.characterUpdated, _handleCharacterUpdate);

    // Achievement events
    subscribe(EventTypes.achievementUnlocked, _handleAchievementUnlocked);

    // Quest events
    subscribe(EventTypes.questCompleted, _handleQuestCompleted);

    // Battle events
    subscribe(EventTypes.battleResult, _handleBattleResult);

    // Location events
    subscribe(EventTypes.locationUpdate, _handleLocationUpdate);
    subscribe(EventTypes.poiDetected, _handlePOIDetected);

    // Social-specific events
    subscribe('social_send_friend_request', _handleSendFriendRequest);
    subscribe('social_accept_friend_request', _handleAcceptFriendRequest);
    subscribe('social_decline_friend_request', _handleDeclineFriendRequest);
    subscribe('social_remove_friend', _handleRemoveFriend);
    subscribe('social_block_user', _handleBlockUser);
    subscribe('social_unblock_user', _handleUnblockUser);

    // Guild events
    subscribe('social_create_guild', _handleCreateGuild);
    subscribe('social_join_guild', _handleJoinGuild);
    subscribe('social_leave_guild', _handleLeaveGuild);
    subscribe('social_invite_to_guild', _handleInviteToGuild);
    subscribe('social_promote_guild_member', _handlePromoteGuildMember);
    subscribe('social_kick_guild_member', _handleKickGuildMember);

    // Activity events
    subscribe('social_invite_to_quest', _handleInviteToQuest);
    subscribe('social_challenge_to_battle', _handleChallengeToBattle);
    subscribe('social_share_achievement', _handleShareAchievement);
    subscribe('social_share_location', _handleShareLocation);

    // Notification events
    subscribe('social_mark_notification_read', _handleMarkNotificationRead);
    subscribe('social_clear_notifications', _handleClearNotifications);

    // User management
    subscribe('user_login', _handleUserLogin);
    subscribe('user_logout', _handleUserLogout);
  }

  /// Send friend request
  String sendFriendRequest(String targetUserId, {String? message}) {
    if (_currentUserId == null || targetUserId == _currentUserId) {
      return '';
    }

    // Check if relationship already exists
    final existingRelation = _getRelationship(_currentUserId!, targetUserId);
    if (existingRelation != null) {
      developer.log('Relationship already exists: ${existingRelation.type}', name: agentId);
      return '';
    }

    // Create friend request activity
    final activity = SocialActivity(
      type: SocialActivityType.friend_request,
      fromUserId: _currentUserId!,
      toUserId: targetUserId,
      data: {'message': message ?? 'Would like to be friends'},
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );

    _activities[activity.activityId] = activity;

    // Create pending relationship
    final relationship = SocialRelationship(
      userId: _currentUserId!,
      targetUserId: targetUserId,
      type: SocialRelationType.pending,
      metadata: {'requestId': activity.activityId},
    );

    _relationships[relationship.relationshipId] = relationship;

    // Create notification for target user
    _createSocialNotification(
      targetUserId,
      SocialNotificationType.friend_request_received,
      'Friend Request',
      '${_currentUserProfile?.displayName ?? 'Someone'} sent you a friend request',
      {
        'fromUserId': _currentUserId,
        'activityId': activity.activityId,
      },
      [
        SocialNotificationAction(
          actionId: 'accept',
          label: 'Accept',
          eventType: 'social_accept_friend_request',
          eventData: {'activityId': activity.activityId},
        ),
        SocialNotificationAction(
          actionId: 'decline',
          label: 'Decline',
          eventType: 'social_decline_friend_request',
          eventData: {'activityId': activity.activityId},
        ),
      ],
    );

    // Publish event
    publishEvent(createEvent(
      eventType: 'social_friend_request_sent',
      data: {
        'fromUserId': _currentUserId,
        'toUserId': targetUserId,
        'activityId': activity.activityId,
      },
    ));

    _logSocialMetric('friend_request_sent', {
      'toUserId': targetUserId,
      'hasMessage': message != null,
    });

    developer.log('Friend request sent to $targetUserId', name: agentId);
    return activity.activityId;
  }

  /// Accept friend request
  bool acceptFriendRequest(String activityId) {
    final activity = _activities[activityId];
    if (activity == null || 
        activity.type != SocialActivityType.friend_request ||
        activity.toUserId != _currentUserId ||
        !activity.isActive ||
        activity.isExpired) {
      return false;
    }

    // Update relationships to friends
    _createFriendship(activity.fromUserId, activity.toUserId);

    // Deactivate activity
    _activities[activityId] = SocialActivity(
      activityId: activity.activityId,
      type: activity.type,
      fromUserId: activity.fromUserId,
      toUserId: activity.toUserId,
      data: activity.data,
      createdAt: activity.createdAt,
      expiresAt: activity.expiresAt,
      isActive: false,
      responses: {'accepted': true, 'acceptedAt': DateTime.now().toIso8601String()},
    );

    // Create notification for sender
    _createSocialNotification(
      activity.fromUserId,
      SocialNotificationType.friend_request_accepted,
      'Friend Request Accepted',
      '${_currentUserProfile?.displayName ?? 'Someone'} accepted your friend request',
      {'acceptedBy': _currentUserId},
    );

    // Publish event
    publishEvent(createEvent(
      eventType: 'social_friend_request_accepted',
      data: {
        'fromUserId': activity.fromUserId,
        'toUserId': activity.toUserId,
        'activityId': activityId,
      },
    ));

    _logSocialMetric('friend_request_accepted', {
      'fromUserId': activity.fromUserId,
    });

    developer.log('Friend request accepted: ${activity.fromUserId}', name: agentId);
    return true;
  }

  /// Create guild
  String createGuild(String name, String description, {List<String>? tags}) {
    if (_currentUserId == null || name.trim().isEmpty) {
      return '';
    }

    // Check if user is already in a guild
    if (_currentGuildId != null) {
      developer.log('User already in guild: $_currentGuildId', name: agentId);
      return '';
    }

    final guild = Guild(
      name: name.trim(),
      description: description.trim(),
      leaderId: _currentUserId!,
      tags: tags ?? [],
      members: [
        GuildMember(
          userId: _currentUserId!,
          permission: GuildPermission.leader,
        ),
      ],
    );

    _guilds[guild.guildId] = guild;
    _currentGuildId = guild.guildId;

    // Publish event
    publishEvent(createEvent(
      eventType: 'social_guild_created',
      data: {
        'guildId': guild.guildId,
        'guildName': name,
        'leaderId': _currentUserId,
      },
    ));

    _logSocialMetric('guild_created', {
      'guildId': guild.guildId,
      'memberCount': 1,
    });

    developer.log('Guild created: $name (${guild.guildId})', name: agentId);
    return guild.guildId;
  }

  /// Invite user to quest
  String inviteToQuest(String targetUserId, String questId, {String? message}) {
    if (_currentUserId == null || targetUserId == _currentUserId) {
      return '';
    }

    // Check if users are friends
    if (!_areFriends(_currentUserId!, targetUserId)) {
      developer.log('Cannot invite non-friend to quest', name: agentId);
      return '';
    }

    final activity = SocialActivity(
      type: SocialActivityType.quest_invitation,
      fromUserId: _currentUserId!,
      toUserId: targetUserId,
      data: {
        'questId': questId,
        'message': message ?? 'Join me on this quest!',
      },
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    );

    _activities[activity.activityId] = activity;

    // Create notification
    _createSocialNotification(
      targetUserId,
      SocialNotificationType.quest_invitation,
      'Quest Invitation',
      '${_currentUserProfile?.displayName ?? 'A friend'} invited you to a quest',
      {
        'fromUserId': _currentUserId,
        'questId': questId,
        'activityId': activity.activityId,
      },
      [
        SocialNotificationAction(
          actionId: 'accept_quest',
          label: 'Accept Quest',
          eventType: 'social_accept_quest_invitation',
          eventData: {'activityId': activity.activityId},
        ),
        SocialNotificationAction(
          actionId: 'decline_quest',
          label: 'Decline',
          eventType: 'social_decline_quest_invitation',
          eventData: {'activityId': activity.activityId},
        ),
      ],
    );

    // Publish event
    publishEvent(createEvent(
      eventType: 'social_quest_invitation_sent',
      data: {
        'fromUserId': _currentUserId,
        'toUserId': targetUserId,
        'questId': questId,
        'activityId': activity.activityId,
      },
    ));

    _logSocialMetric('quest_invitation_sent', {
      'toUserId': targetUserId,
      'questId': questId,
    });

    return activity.activityId;
  }

  /// Share achievement with friends
  void shareAchievement(String achievementId, String achievementName, {String? message}) {
    if (_currentUserId == null) return;

    final shareMessage = message ?? 'Check out my new achievement!';

    // Share with all friends
    for (final friendId in _friendsList) {
      _createSocialNotification(
        friendId,
        SocialNotificationType.achievement_celebration,
        'Friend Achievement',
        '${_currentUserProfile?.displayName ?? 'A friend'} unlocked: $achievementName',
        {
          'fromUserId': _currentUserId,
          'achievementId': achievementId,
          'achievementName': achievementName,
          'message': shareMessage,
        },
        [
          SocialNotificationAction(
            actionId: 'congratulate',
            label: 'Congratulate',
            eventType: 'social_send_congratulation',
            eventData: {
              'toUserId': _currentUserId,
              'achievementId': achievementId,
            },
          ),
        ],
      );
    }

    // Publish event
    publishEvent(createEvent(
      eventType: 'social_achievement_shared',
      data: {
        'fromUserId': _currentUserId,
        'achievementId': achievementId,
        'achievementName': achievementName,
        'friendCount': _friendsList.length,
      },
    ));

    _logSocialMetric('achievement_shared', {
      'achievementId': achievementId,
      'friendCount': _friendsList.length,
    });
  }

  /// Get user's social data
  Map<String, dynamic> getSocialData() {
    final guild = _currentGuildId != null ? _guilds[_currentGuildId!] : null;
    
    return {
      'currentProfile': _currentUserProfile?.toJson(),
      'friendsCount': _friendsList.length,
      'friends': _friendsList.map((id) => _userProfiles[id]?.toJson()).where((p) => p != null).toList(),
      'guild': guild?.toJson(),
      'pendingActivities': _activities.values
          .where((a) => a.toUserId == _currentUserId && a.isActive && !a.isExpired)
          .map((a) => a.toJson())
          .toList(),
      'notifications': _notifications.values
          .where((n) => n.userId == _currentUserId && !n.isRead)
          .map((n) => n.toJson())
          .toList(),
      'socialStats': {
        'totalInteractions': _totalInteractions,
        'lastActivity': _lastSocialActivity?.toIso8601String(),
        'onlineStatus': _currentUserProfile?.status ?? 'offline',
      },
    };
  }

  /// Get social analytics
  Map<String, dynamic> getSocialAnalytics() {
    final friendsByLevel = <String, int>{};
    for (final friendId in _friendsList) {
      final friend = _userProfiles[friendId];
      if (friend != null) {
        final levelRange = '${(friend.level ~/ 10) * 10}-${(friend.level ~/ 10) * 10 + 9}';
        friendsByLevel[levelRange] = (friendsByLevel[levelRange] ?? 0) + 1;
      }
    }

    final guildStats = _currentGuildId != null ? _guilds[_currentGuildId!] : null;

    return {
      'totalFriends': _friendsList.length,
      'totalBlocked': _blockedList.length,
      'guildMembership': guildStats != null,
      'guildSize': guildStats?.members.length ?? 0,
      'guildRole': guildStats?.members
          .firstWhere((m) => m.userId == _currentUserId, orElse: () => GuildMember(userId: ''))
          .permission.toString(),
      'friendsByLevel': friendsByLevel,
      'totalInteractions': _totalInteractions,
      'activitiesCount': _activities.length,
      'notificationsCount': _notifications.values.where((n) => n.userId == _currentUserId).length,
      'unreadNotifications': _notifications.values.where((n) => n.userId == _currentUserId && !n.isRead).length,
      'lastSocialActivity': _lastSocialActivity?.toIso8601String(),
    };
  }

  /// Create friendship between two users
  void _createFriendship(String userId1, String userId2) {
    // Remove any pending relationships
    _relationships.removeWhere((key, relation) => 
        (relation.userId == userId1 && relation.targetUserId == userId2) ||
        (relation.userId == userId2 && relation.targetUserId == userId1));

    // Create mutual friend relationships
    final relationship1 = SocialRelationship(
      userId: userId1,
      targetUserId: userId2,
      type: SocialRelationType.friend,
    );

    final relationship2 = SocialRelationship(
      userId: userId2,
      targetUserId: userId1,
      type: SocialRelationType.friend,
    );

    _relationships[relationship1.relationshipId] = relationship1;
    _relationships[relationship2.relationshipId] = relationship2;

    // Update friends lists
    if (userId1 == _currentUserId && !_friendsList.contains(userId2)) {
      _friendsList.add(userId2);
    }
    if (userId2 == _currentUserId && !_friendsList.contains(userId1)) {
      _friendsList.add(userId1);
    }
  }

  /// Check if two users are friends
  bool _areFriends(String userId1, String userId2) {
    return _getRelationship(userId1, userId2)?.type == SocialRelationType.friend;
  }

  /// Get relationship between two users
  SocialRelationship? _getRelationship(String userId1, String userId2) {
    return _relationships.values.firstWhere(
      (relation) => relation.userId == userId1 && relation.targetUserId == userId2,
      orElse: () => SocialRelationship(userId: '', targetUserId: '', type: SocialRelationType.friend),
    ).userId.isNotEmpty ? _relationships.values.firstWhere(
      (relation) => relation.userId == userId1 && relation.targetUserId == userId2,
    ) : null;
  }

  /// Create social notification
  void _createSocialNotification(
    String userId,
    SocialNotificationType type,
    String title,
    String message,
    Map<String, dynamic> data, [
    List<SocialNotificationAction>? actions,
  ]) {
    final notification = SocialNotification(
      type: type,
      userId: userId,
      title: title,
      message: message,
      data: data,
      actions: actions ?? [],
    );

    _notifications[notification.notificationId] = notification;

    // Publish notification event
    publishEvent(createEvent(
      eventType: 'social_notification_created',
      data: {
        'notificationId': notification.notificationId,
        'userId': userId,
        'type': type.toString(),
        'title': title,
      },
    ));
  }

  /// Start activity cleanup timer
  void _startActivityCleanup() {
    _activityCleanupTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      final now = DateTime.now();
      
      // Remove expired activities
      _activities.removeWhere((key, activity) => 
          !activity.isActive || activity.isExpired);

      // Remove old notifications (keep for 30 days)
      final cutoffDate = now.subtract(const Duration(days: 30));
      _notifications.removeWhere((key, notification) => 
          notification.createdAt.isBefore(cutoffDate));

      // Save data after cleanup
      _saveSocialData();
    });
  }

  /// Start online status updates
  void _startOnlineStatusUpdates() {
    _onlineStatusTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_currentUserProfile != null) {
        _currentUserProfile = _currentUserProfile!.copyWith(
          status: 'online',
          isOnline: true,
          lastSeen: DateTime.now(),
        );
        _userProfiles[_currentUserId!] = _currentUserProfile!;
      }
    });
  }

  /// Initialize default social content
  Future<void> _initializeDefaultSocialContent() async {
    // Create sample users (in a real app, these would come from the server)
    _userProfiles.addAll({
      'demo_user_1': SocialProfile(
        userId: 'demo_user_1',
        displayName: 'Alex Adventure',
        level: 15,
        status: 'online',
        isOnline: true,
        stats: {'quests_completed': 25, 'achievements': 18},
        badges: ['Explorer', 'Quest Master'],
      ),
      'demo_user_2': SocialProfile(
        userId: 'demo_user_2',
        displayName: 'Sarah Seeker',
        level: 12,
        status: 'away',
        isOnline: false,
        stats: {'quests_completed': 18, 'achievements': 14},
        badges: ['Treasure Hunter', 'Social Butterfly'],
      ),
      'demo_user_3': SocialProfile(
        userId: 'demo_user_3',
        displayName: 'Mike Mystic',
        level: 20,
        status: 'offline',
        isOnline: false,
        stats: {'quests_completed': 40, 'achievements': 32},
        badges: ['Guild Leader', 'Master Explorer', 'Legend'],
      ),
    });

    // Create demo guild
    _guilds['demo_guild_1'] = Guild(
      guildId: 'demo_guild_1',
      name: 'Realm Explorers',
      description: 'A guild for dedicated explorers and adventurers',
      leaderId: 'demo_user_3',
      members: [
        GuildMember(userId: 'demo_user_3', permission: GuildPermission.leader),
        GuildMember(userId: 'demo_user_1', permission: GuildPermission.officer),
        GuildMember(userId: 'demo_user_2', permission: GuildPermission.member),
      ],
      tags: ['exploration', 'quests', 'adventure'],
      stats: {'total_quests': 85, 'guild_level': 5},
    );
  }

  /// Load social data
  Future<void> _loadSocialData() async {
    try {
      // Load user profiles
      final profilesJson = _prefs.getString('social_profiles');
      if (profilesJson != null) {
        final data = jsonDecode(profilesJson) as Map<String, dynamic>;
        for (final entry in data.entries) {
          _userProfiles[entry.key] = SocialProfile.fromJson(entry.value);
        }
      }

      // Load relationships
      final relationshipsJson = _prefs.getString('social_relationships');
      if (relationshipsJson != null) {
        final data = jsonDecode(relationshipsJson) as Map<String, dynamic>;
        for (final entry in data.entries) {
          _relationships[entry.key] = SocialRelationship.fromJson(entry.value);
        }
      }

      // Load guilds
      final guildsJson = _prefs.getString('social_guilds');
      if (guildsJson != null) {
        final data = jsonDecode(guildsJson) as Map<String, dynamic>;
        for (final entry in data.entries) {
          _guilds[entry.key] = Guild.fromJson(entry.value);
        }
      }

      // Load activities
      final activitiesJson = _prefs.getString('social_activities');
      if (activitiesJson != null) {
        final data = jsonDecode(activitiesJson) as Map<String, dynamic>;
        for (final entry in data.entries) {
          _activities[entry.key] = SocialActivity.fromJson(entry.value);
        }
      }

      // Load notifications
      final notificationsJson = _prefs.getString('social_notifications');
      if (notificationsJson != null) {
        final data = jsonDecode(notificationsJson) as Map<String, dynamic>;
        for (final entry in data.entries) {
          _notifications[entry.key] = SocialNotification.fromJson(entry.value);
        }
      }

      // Load current user social state
      final userStateJson = _prefs.getString('social_user_state');
      if (userStateJson != null) {
        final data = jsonDecode(userStateJson) as Map<String, dynamic>;
        _friendsList.addAll(List<String>.from(data['friends'] ?? []));
        _blockedList.addAll(List<String>.from(data['blocked'] ?? []));
        _currentGuildId = data['guildId'];
      }

    } catch (e) {
      developer.log('Error loading social data: $e', name: agentId);
    }
  }

  /// Save social data
  Future<void> _saveSocialData() async {
    try {
      // Save profiles
      final profilesData = _userProfiles.map((k, v) => MapEntry(k, v.toJson()));
      await _prefs.setString('social_profiles', jsonEncode(profilesData));

      // Save relationships
      final relationshipsData = _relationships.map((k, v) => MapEntry(k, v.toJson()));
      await _prefs.setString('social_relationships', jsonEncode(relationshipsData));

      // Save guilds
      final guildsData = _guilds.map((k, v) => MapEntry(k, v.toJson()));
      await _prefs.setString('social_guilds', jsonEncode(guildsData));

      // Save activities
      final activitiesData = _activities.map((k, v) => MapEntry(k, v.toJson()));
      await _prefs.setString('social_activities', jsonEncode(activitiesData));

      // Save notifications
      final notificationsData = _notifications.map((k, v) => MapEntry(k, v.toJson()));
      await _prefs.setString('social_notifications', jsonEncode(notificationsData));

      // Save current user state
      final userState = {
        'friends': _friendsList,
        'blocked': _blockedList,
        'guildId': _currentGuildId,
      };
      await _prefs.setString('social_user_state', jsonEncode(userState));

    } catch (e) {
      developer.log('Error saving social data: $e', name: agentId);
    }
  }

  /// Log social metric
  void _logSocialMetric(String metricType, Map<String, dynamic> data) {
    _socialMetrics.add({
      'metricType': metricType,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Keep only last 100 metrics
    if (_socialMetrics.length > 100) {
      _socialMetrics.removeAt(0);
    }

    _totalInteractions++;
    _lastSocialActivity = DateTime.now();
  }

  // Event Handlers

  /// Handle character level up events
  Future<AgentEventResponse?> _handleCharacterLevelUp(AgentEvent event) async {
    final newLevel = event.data['newLevel'] ?? 0;
    
    // Update current user profile
    if (_currentUserProfile != null) {
      _currentUserProfile = _currentUserProfile!.copyWith(level: newLevel);
      _userProfiles[_currentUserId!] = _currentUserProfile!;
    }

    // Notify friends of level up
    for (final friendId in _friendsList) {
      _createSocialNotification(
        friendId,
        SocialNotificationType.achievement_celebration,
        'Friend Level Up',
        '${_currentUserProfile?.displayName ?? 'A friend'} reached level $newLevel!',
        {
          'fromUserId': _currentUserId,
          'newLevel': newLevel,
        },
        [
          SocialNotificationAction(
            actionId: 'congratulate',
            label: 'Congratulate',
            eventType: 'social_send_congratulation',
            eventData: {'toUserId': _currentUserId, 'reason': 'level_up'},
          ),
        ],
      );
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'social_level_up_shared',
      data: {'newLevel': newLevel, 'friendsNotified': _friendsList.length},
    );
  }

  /// Handle character update events
  Future<AgentEventResponse?> _handleCharacterUpdate(AgentEvent event) async {
    // Update profile stats from character data
    if (_currentUserProfile != null) {
      final characterData = event.data;
      final updatedStats = Map<String, dynamic>.from(_currentUserProfile!.stats);
      
      if (characterData['totalXp'] != null) {
        updatedStats['totalXp'] = characterData['totalXp'];
      }
      if (characterData['stats'] != null) {
        updatedStats.addAll(Map<String, dynamic>.from(characterData['stats']));
      }

      _currentUserProfile = _currentUserProfile!.copyWith(stats: updatedStats);
      _userProfiles[_currentUserId!] = _currentUserProfile!;
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'social_profile_updated',
      data: {'profileUpdated': true},
    );
  }

  /// Handle achievement unlocked events
  Future<AgentEventResponse?> _handleAchievementUnlocked(AgentEvent event) async {
    final achievementName = event.data['name'] ?? 'Achievement';
    final achievementId = event.data['id'] ?? '';

    // Auto-share certain achievements
    final autoShareAchievements = ['First Quest', 'Level 10', 'Level 20', 'Guild Master'];
    if (autoShareAchievements.contains(achievementName)) {
      shareAchievement(achievementId, achievementName);
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'social_achievement_processed',
      data: {'achievementName': achievementName, 'autoShared': autoShareAchievements.contains(achievementName)},
    );
  }

  /// Handle quest completed events
  Future<AgentEventResponse?> _handleQuestCompleted(AgentEvent event) async {
    final questName = event.data['questName'] ?? 'Quest';
    
    // Update quest completion stats
    if (_currentUserProfile != null) {
      final updatedStats = Map<String, dynamic>.from(_currentUserProfile!.stats);
      updatedStats['quests_completed'] = (updatedStats['quests_completed'] ?? 0) + 1;
      
      _currentUserProfile = _currentUserProfile!.copyWith(stats: updatedStats);
      _userProfiles[_currentUserId!] = _currentUserProfile!;
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'social_quest_completion_recorded',
      data: {'questName': questName},
    );
  }

  /// Handle battle result events
  Future<AgentEventResponse?> _handleBattleResult(AgentEvent event) async {
    final isVictory = event.data['isVictory'] ?? false;
    
    // Update battle stats
    if (_currentUserProfile != null && isVictory) {
      final updatedStats = Map<String, dynamic>.from(_currentUserProfile!.stats);
      updatedStats['battles_won'] = (updatedStats['battles_won'] ?? 0) + 1;
      
      _currentUserProfile = _currentUserProfile!.copyWith(stats: updatedStats);
      _userProfiles[_currentUserId!] = _currentUserProfile!;
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'social_battle_result_recorded',
      data: {'isVictory': isVictory},
    );
  }

  /// Handle location update events
  Future<AgentEventResponse?> _handleLocationUpdate(AgentEvent event) async {
    // Could be used for location-based social features
    return createResponse(
      originalEventId: event.id,
      responseType: 'social_location_processed',
      data: {'processed': true},
    );
  }

  /// Handle POI detected events
  Future<AgentEventResponse?> _handlePOIDetected(AgentEvent event) async {
    final poiName = event.data['poi']?['name'] ?? 'Location';
    
    // Share interesting POI discoveries with friends
    if (_friendsList.isNotEmpty) {
      for (final friendId in _friendsList.take(3)) { // Share with up to 3 friends
        _createSocialNotification(
          friendId,
          SocialNotificationType.location_event,
          'Friend Discovery',
          '${_currentUserProfile?.displayName ?? 'A friend'} discovered: $poiName',
          {
            'fromUserId': _currentUserId,
            'poiName': poiName,
            'poiData': event.data['poi'],
          },
        );
      }
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'social_poi_shared',
      data: {'poiName': poiName, 'friendsNotified': math.min(_friendsList.length, 3)},
    );
  }

  /// Handle send friend request events
  Future<AgentEventResponse?> _handleSendFriendRequest(AgentEvent event) async {
    final targetUserId = event.data['targetUserId'];
    final message = event.data['message'];

    if (targetUserId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'friend_request_failed',
        data: {'error': 'No target user ID provided'},
        success: false,
      );
    }

    final activityId = sendFriendRequest(targetUserId, message: message);

    return createResponse(
      originalEventId: event.id,
      responseType: 'friend_request_sent',
      data: {
        'targetUserId': targetUserId,
        'activityId': activityId,
        'success': activityId.isNotEmpty,
      },
      success: activityId.isNotEmpty,
    );
  }

  /// Handle accept friend request events
  Future<AgentEventResponse?> _handleAcceptFriendRequest(AgentEvent event) async {
    final activityId = event.data['activityId'];

    if (activityId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'accept_friend_request_failed',
        data: {'error': 'No activity ID provided'},
        success: false,
      );
    }

    final success = acceptFriendRequest(activityId);

    return createResponse(
      originalEventId: event.id,
      responseType: 'friend_request_accepted',
      data: {'activityId': activityId, 'success': success},
      success: success,
    );
  }

  /// Handle decline friend request events
  Future<AgentEventResponse?> _handleDeclineFriendRequest(AgentEvent event) async {
    final activityId = event.data['activityId'];

    if (activityId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'decline_friend_request_failed',
        data: {'error': 'No activity ID provided'},
        success: false,
      );
    }

    final activity = _activities[activityId];
    if (activity != null) {
      _activities[activityId] = SocialActivity(
        activityId: activity.activityId,
        type: activity.type,
        fromUserId: activity.fromUserId,
        toUserId: activity.toUserId,
        data: activity.data,
        createdAt: activity.createdAt,
        expiresAt: activity.expiresAt,
        isActive: false,
        responses: {'declined': true, 'declinedAt': DateTime.now().toIso8601String()},
      );
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'friend_request_declined',
      data: {'activityId': activityId, 'success': activity != null},
      success: activity != null,
    );
  }

  /// Handle remove friend events
  Future<AgentEventResponse?> _handleRemoveFriend(AgentEvent event) async {
    final friendUserId = event.data['friendUserId'];

    if (friendUserId == null || _currentUserId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'remove_friend_failed',
        data: {'error': 'Invalid user IDs'},
        success: false,
      );
    }

    // Remove friend relationships
    _relationships.removeWhere((key, relation) => 
        (relation.userId == _currentUserId && relation.targetUserId == friendUserId && relation.type == SocialRelationType.friend) ||
        (relation.userId == friendUserId && relation.targetUserId == _currentUserId && relation.type == SocialRelationType.friend));

    // Update friends list
    _friendsList.remove(friendUserId);

    _logSocialMetric('friend_removed', {'friendUserId': friendUserId});

    return createResponse(
      originalEventId: event.id,
      responseType: 'friend_removed',
      data: {'friendUserId': friendUserId, 'success': true},
    );
  }

  /// Handle block user events
  Future<AgentEventResponse?> _handleBlockUser(AgentEvent event) async {
    final targetUserId = event.data['targetUserId'];

    if (targetUserId == null || _currentUserId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'block_user_failed',
        data: {'error': 'Invalid user IDs'},
        success: false,
      );
    }

    // Remove from friends if they were friends
    _friendsList.remove(targetUserId);

    // Add to blocked list
    if (!_blockedList.contains(targetUserId)) {
      _blockedList.add(targetUserId);
    }

    // Create blocked relationship
    final relationship = SocialRelationship(
      userId: _currentUserId!,
      targetUserId: targetUserId,
      type: SocialRelationType.blocked,
    );

    _relationships[relationship.relationshipId] = relationship;

    _logSocialMetric('user_blocked', {'targetUserId': targetUserId});

    return createResponse(
      originalEventId: event.id,
      responseType: 'user_blocked',
      data: {'targetUserId': targetUserId, 'success': true},
    );
  }

  /// Handle unblock user events
  Future<AgentEventResponse?> _handleUnblockUser(AgentEvent event) async {
    final targetUserId = event.data['targetUserId'];

    if (targetUserId == null || _currentUserId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'unblock_user_failed',
        data: {'error': 'Invalid user IDs'},
        success: false,
      );
    }

    // Remove from blocked list
    _blockedList.remove(targetUserId);

    // Remove blocked relationship
    _relationships.removeWhere((key, relation) => 
        relation.userId == _currentUserId && 
        relation.targetUserId == targetUserId && 
        relation.type == SocialRelationType.blocked);

    _logSocialMetric('user_unblocked', {'targetUserId': targetUserId});

    return createResponse(
      originalEventId: event.id,
      responseType: 'user_unblocked',
      data: {'targetUserId': targetUserId, 'success': true},
    );
  }

  /// Handle create guild events
  Future<AgentEventResponse?> _handleCreateGuild(AgentEvent event) async {
    final guildName = event.data['name'];
    final description = event.data['description'] ?? '';
    final tags = event.data['tags'] as List<String>?;

    if (guildName == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'create_guild_failed',
        data: {'error': 'No guild name provided'},
        success: false,
      );
    }

    final guildId = createGuild(guildName, description, tags: tags);

    return createResponse(
      originalEventId: event.id,
      responseType: 'guild_created',
      data: {
        'guildId': guildId,
        'guildName': guildName,
        'success': guildId.isNotEmpty,
      },
      success: guildId.isNotEmpty,
    );
  }

  /// Handle join guild events
  Future<AgentEventResponse?> _handleJoinGuild(AgentEvent event) async {
    final guildId = event.data['guildId'];

    if (guildId == null || _currentUserId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'join_guild_failed',
        data: {'error': 'Invalid guild or user ID'},
        success: false,
      );
    }

    final guild = _guilds[guildId];
    if (guild == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'join_guild_failed',
        data: {'error': 'Guild not found'},
        success: false,
      );
    }

    // Add user to guild
    final newMember = GuildMember(userId: _currentUserId!);
    guild.members.add(newMember);
    _currentGuildId = guildId;

    _logSocialMetric('guild_joined', {'guildId': guildId});

    return createResponse(
      originalEventId: event.id,
      responseType: 'guild_joined',
      data: {'guildId': guildId, 'success': true},
    );
  }

  /// Handle leave guild events
  Future<AgentEventResponse?> _handleLeaveGuild(AgentEvent event) async {
    if (_currentGuildId == null || _currentUserId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'leave_guild_failed',
        data: {'error': 'Not in a guild'},
        success: false,
      );
    }

    final guild = _guilds[_currentGuildId!];
    if (guild != null) {
      guild.members.removeWhere((member) => member.userId == _currentUserId);
      
      // If leader is leaving and there are other members, promote someone
      if (guild.leaderId == _currentUserId && guild.members.isNotEmpty) {
        final newLeader = guild.members.first;
        newLeader.contributions['promoted_to_leader'] = DateTime.now().toIso8601String();
        guild.leaderId = newLeader.userId;
      }
    }

    final oldGuildId = _currentGuildId;
    _currentGuildId = null;

    _logSocialMetric('guild_left', {'guildId': oldGuildId});

    return createResponse(
      originalEventId: event.id,
      responseType: 'guild_left',
      data: {'guildId': oldGuildId, 'success': true},
    );
  }

  /// Handle invite to guild events
  Future<AgentEventResponse?> _handleInviteToGuild(AgentEvent event) async {
    final targetUserId = event.data['targetUserId'];
    final guildId = event.data['guildId'] ?? _currentGuildId;

    if (targetUserId == null || guildId == null || _currentUserId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'guild_invite_failed',
        data: {'error': 'Invalid parameters'},
        success: false,
      );
    }

    final guild = _guilds[guildId];
    if (guild == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'guild_invite_failed',
        data: {'error': 'Guild not found'},
        success: false,
      );
    }

    // Create guild invitation activity
    final activity = SocialActivity(
      type: SocialActivityType.guild_invitation,
      fromUserId: _currentUserId!,
      toUserId: targetUserId,
      data: {
        'guildId': guildId,
        'guildName': guild.name,
        'inviterName': _currentUserProfile?.displayName ?? 'Someone',
      },
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );

    _activities[activity.activityId] = activity;

    // Create notification
    _createSocialNotification(
      targetUserId,
      SocialNotificationType.guild_invitation,
      'Guild Invitation',
      'You have been invited to join ${guild.name}',
      {
        'fromUserId': _currentUserId,
        'guildId': guildId,
        'guildName': guild.name,
        'activityId': activity.activityId,
      },
      [
        SocialNotificationAction(
          actionId: 'accept_guild',
          label: 'Accept',
          eventType: 'social_accept_guild_invitation',
          eventData: {'activityId': activity.activityId},
        ),
        SocialNotificationAction(
          actionId: 'decline_guild',
          label: 'Decline',
          eventType: 'social_decline_guild_invitation',
          eventData: {'activityId': activity.activityId},
        ),
      ],
    );

    _logSocialMetric('guild_invitation_sent', {
      'guildId': guildId,
      'targetUserId': targetUserId,
    });

    return createResponse(
      originalEventId: event.id,
      responseType: 'guild_invitation_sent',
      data: {
        'targetUserId': targetUserId,
        'guildId': guildId,
        'activityId': activity.activityId,
      },
    );
  }

  /// Handle promote guild member events
  Future<AgentEventResponse?> _handlePromoteGuildMember(AgentEvent event) async {
    // Implementation for guild member promotion
    return createResponse(
      originalEventId: event.id,
      responseType: 'guild_member_promoted',
      data: {'implemented': false},
    );
  }

  /// Handle kick guild member events
  Future<AgentEventResponse?> _handleKickGuildMember(AgentEvent event) async {
    // Implementation for guild member kicking
    return createResponse(
      originalEventId: event.id,
      responseType: 'guild_member_kicked',
      data: {'implemented': false},
    );
  }

  /// Handle invite to quest events
  Future<AgentEventResponse?> _handleInviteToQuest(AgentEvent event) async {
    final targetUserId = event.data['targetUserId'];
    final questId = event.data['questId'];
    final message = event.data['message'];

    if (targetUserId == null || questId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'quest_invite_failed',
        data: {'error': 'Missing parameters'},
        success: false,
      );
    }

    final activityId = inviteToQuest(targetUserId, questId, message: message);

    return createResponse(
      originalEventId: event.id,
      responseType: 'quest_invitation_sent',
      data: {
        'targetUserId': targetUserId,
        'questId': questId,
        'activityId': activityId,
        'success': activityId.isNotEmpty,
      },
      success: activityId.isNotEmpty,
    );
  }

  /// Handle challenge to battle events
  Future<AgentEventResponse?> _handleChallengeToBattle(AgentEvent event) async {
    final targetUserId = event.data['targetUserId'];
    final message = event.data['message'] ?? 'Challenge you to a battle!';

    if (targetUserId == null || _currentUserId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'battle_challenge_failed',
        data: {'error': 'Invalid user IDs'},
        success: false,
      );
    }

    final activity = SocialActivity(
      type: SocialActivityType.battle_challenge,
      fromUserId: _currentUserId!,
      toUserId: targetUserId,
      data: {'message': message},
      expiresAt: DateTime.now().add(const Duration(hours: 4)),
    );

    _activities[activity.activityId] = activity;

    _createSocialNotification(
      targetUserId,
      SocialNotificationType.battle_challenge,
      'Battle Challenge',
      '${_currentUserProfile?.displayName ?? 'Someone'} challenges you to battle!',
      {
        'fromUserId': _currentUserId,
        'activityId': activity.activityId,
        'message': message,
      },
      [
        SocialNotificationAction(
          actionId: 'accept_battle',
          label: 'Accept',
          eventType: 'social_accept_battle_challenge',
          eventData: {'activityId': activity.activityId},
        ),
        SocialNotificationAction(
          actionId: 'decline_battle',
          label: 'Decline',
          eventType: 'social_decline_battle_challenge',
          eventData: {'activityId': activity.activityId},
        ),
      ],
    );

    _logSocialMetric('battle_challenge_sent', {'targetUserId': targetUserId});

    return createResponse(
      originalEventId: event.id,
      responseType: 'battle_challenge_sent',
      data: {
        'targetUserId': targetUserId,
        'activityId': activity.activityId,
      },
    );
  }

  /// Handle share achievement events
  Future<AgentEventResponse?> _handleShareAchievement(AgentEvent event) async {
    final achievementId = event.data['achievementId'];
    final achievementName = event.data['achievementName'];
    final message = event.data['message'];

    if (achievementId == null || achievementName == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'share_achievement_failed',
        data: {'error': 'Missing achievement data'},
        success: false,
      );
    }

    shareAchievement(achievementId, achievementName, message: message);

    return createResponse(
      originalEventId: event.id,
      responseType: 'achievement_shared',
      data: {
        'achievementId': achievementId,
        'friendsNotified': _friendsList.length,
      },
    );
  }

  /// Handle share location events
  Future<AgentEventResponse?> _handleShareLocation(AgentEvent event) async {
    final locationName = event.data['locationName'] ?? 'Current Location';
    final locationData = event.data['locationData'] ?? {};

    if (_friendsList.isEmpty) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'location_shared',
        data: {'friendsNotified': 0},
      );
    }

    // Share with all friends
    for (final friendId in _friendsList) {
      _createSocialNotification(
        friendId,
        SocialNotificationType.location_event,
        'Location Shared',
        '${_currentUserProfile?.displayName ?? 'A friend'} shared their location: $locationName',
        {
          'fromUserId': _currentUserId,
          'locationName': locationName,
          'locationData': locationData,
        },
      );
    }

    _logSocialMetric('location_shared', {
      'locationName': locationName,
      'friendsNotified': _friendsList.length,
    });

    return createResponse(
      originalEventId: event.id,
      responseType: 'location_shared',
      data: {'friendsNotified': _friendsList.length},
    );
  }

  /// Handle mark notification read events
  Future<AgentEventResponse?> _handleMarkNotificationRead(AgentEvent event) async {
    final notificationId = event.data['notificationId'];

    if (notificationId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'mark_notification_read_failed',
        data: {'error': 'No notification ID provided'},
        success: false,
      );
    }

    final notification = _notifications[notificationId];
    if (notification != null && notification.userId == _currentUserId) {
      _notifications[notificationId] = SocialNotification(
        notificationId: notification.notificationId,
        type: notification.type,
        userId: notification.userId,
        title: notification.title,
        message: notification.message,
        data: notification.data,
        createdAt: notification.createdAt,
        isRead: true,
        actions: notification.actions,
      );
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'notification_marked_read',
      data: {'notificationId': notificationId, 'success': notification != null},
      success: notification != null,
    );
  }

  /// Handle clear notifications events
  Future<AgentEventResponse?> _handleClearNotifications(AgentEvent event) async {
    final beforeDate = event.data['beforeDate'];
    
    int clearedCount = 0;
    if (beforeDate != null) {
      final cutoff = DateTime.parse(beforeDate);
      final toRemove = _notifications.values
          .where((n) => n.userId == _currentUserId && n.createdAt.isBefore(cutoff))
          .map((n) => n.notificationId)
          .toList();
      
      for (final id in toRemove) {
        _notifications.remove(id);
        clearedCount++;
      }
    } else {
      // Clear all notifications for current user
      final toRemove = _notifications.values
          .where((n) => n.userId == _currentUserId)
          .map((n) => n.notificationId)
          .toList();
      
      for (final id in toRemove) {
        _notifications.remove(id);
        clearedCount++;
      }
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'notifications_cleared',
      data: {'clearedCount': clearedCount},
    );
  }

  /// Handle user login events
  Future<AgentEventResponse?> _handleUserLogin(AgentEvent event) async {
    final userId = event.data['userId'];
    _currentUserId = userId;

    if (userId != null) {
      // Load or create user profile
      _currentUserProfile = _userProfiles[userId] ?? SocialProfile(
        userId: userId,
        displayName: 'Player ${userId.substring(0, 8)}',
        level: 1,
        status: 'online',
        isOnline: true,
      );

      _userProfiles[userId] = _currentUserProfile!;

      // Load user's social relationships
      _friendsList.clear();
      _blockedList.clear();
      
      for (final relationship in _relationships.values) {
        if (relationship.userId == userId) {
          if (relationship.type == SocialRelationType.friend) {
            _friendsList.add(relationship.targetUserId);
          } else if (relationship.type == SocialRelationType.blocked) {
            _blockedList.add(relationship.targetUserId);
          }
        }
      }

      // Find user's guild
      _currentGuildId = null;
      for (final guild in _guilds.values) {
        if (guild.members.any((member) => member.userId == userId)) {
          _currentGuildId = guild.guildId;
          break;
        }
      }

      // Load social data
      await _loadSocialData();
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'user_login_social_processed',
      data: {
        'userId': userId,
        'friendsCount': _friendsList.length,
        'hasGuild': _currentGuildId != null,
      },
    );
  }

  /// Handle user logout events
  Future<AgentEventResponse?> _handleUserLogout(AgentEvent event) async {
    // Update user status to offline
    if (_currentUserProfile != null) {
      _currentUserProfile = _currentUserProfile!.copyWith(
        status: 'offline',
        isOnline: false,
        lastSeen: DateTime.now(),
      );
      _userProfiles[_currentUserId!] = _currentUserProfile!;
    }

    // Save all social data
    await _saveSocialData();

    // Clear current user data
    _currentUserId = null;
    _currentUserProfile = null;
    _friendsList.clear();
    _blockedList.clear();
    _currentGuildId = null;

    return createResponse(
      originalEventId: event.id,
      responseType: 'user_logout_social_processed',
      data: {'socialDataSaved': true},
    );
  }

  @override
  Future<void> onDispose() async {
    // Cancel timers
    _activityCleanupTimer?.cancel();
    _onlineStatusTimer?.cancel();

    // Save all data
    await _saveSocialData();

    developer.log('Social Features Agent disposed', name: agentId);
  }
}