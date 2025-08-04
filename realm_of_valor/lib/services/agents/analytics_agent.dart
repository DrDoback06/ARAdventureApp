import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/event_bus.dart';
import 'integration_orchestrator_agent.dart';

/// Analytics event categories
enum AnalyticsEventCategory {
  user_behavior,
  gameplay,
  progression,
  social,
  monetization,
  performance,
  location,
  ar_interaction,
  audio_engagement,
  ui_interaction,
}

/// Analytics metrics types
enum MetricType {
  counter,
  gauge,
  histogram,
  timer,
  rate,
  percentage,
}

/// User segment categories
enum UserSegment {
  new_user,
  casual_player,
  regular_player,
  hardcore_player,
  social_player,
  collector,
  competitor,
  explorer,
  inactive,
  churned,
}

/// Prediction models
enum PredictionModel {
  churn_prediction,
  engagement_scoring,
  monetization_propensity,
  content_recommendation,
  difficulty_adjustment,
  social_match,
  location_preference,
}

/// Analytics event data structure
class AnalyticsEvent {
  final String eventId;
  final AnalyticsEventCategory category;
  final String name;
  final Map<String, dynamic> properties;
  final Map<String, dynamic> userProperties;
  final DateTime timestamp;
  final String? sessionId;
  final String? userId;
  final double? value;

  AnalyticsEvent({
    String? eventId,
    required this.category,
    required this.name,
    Map<String, dynamic>? properties,
    Map<String, dynamic>? userProperties,
    DateTime? timestamp,
    this.sessionId,
    this.userId,
    this.value,
  }) : eventId = eventId ?? 'event_${DateTime.now().millisecondsSinceEpoch}',
       properties = properties ?? {},
       userProperties = userProperties ?? {},
       timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'category': category.toString(),
      'name': name,
      'properties': properties,
      'userProperties': userProperties,
      'timestamp': timestamp.toIso8601String(),
      'sessionId': sessionId,
      'userId': userId,
      'value': value,
    };
  }

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      eventId: json['eventId'],
      category: AnalyticsEventCategory.values.firstWhere(
        (c) => c.toString() == json['category'],
        orElse: () => AnalyticsEventCategory.user_behavior,
      ),
      name: json['name'],
      properties: Map<String, dynamic>.from(json['properties'] ?? {}),
      userProperties: Map<String, dynamic>.from(json['userProperties'] ?? {}),
      timestamp: DateTime.parse(json['timestamp']),
      sessionId: json['sessionId'],
      userId: json['userId'],
      value: json['value']?.toDouble(),
    );
  }
}

/// Analytics metric
class AnalyticsMetric {
  final String metricId;
  final String name;
  final MetricType type;
  final double value;
  final Map<String, String> tags;
  final DateTime timestamp;
  final Duration? timeWindow;

  AnalyticsMetric({
    String? metricId,
    required this.name,
    required this.type,
    required this.value,
    Map<String, String>? tags,
    DateTime? timestamp,
    this.timeWindow,
  }) : metricId = metricId ?? 'metric_${DateTime.now().millisecondsSinceEpoch}',
       tags = tags ?? {},
       timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'metricId': metricId,
      'name': name,
      'type': type.toString(),
      'value': value,
      'tags': tags,
      'timestamp': timestamp.toIso8601String(),
      'timeWindow': timeWindow?.inMilliseconds,
    };
  }

  factory AnalyticsMetric.fromJson(Map<String, dynamic> json) {
    return AnalyticsMetric(
      metricId: json['metricId'],
      name: json['name'],
      type: MetricType.values.firstWhere(
        (t) => t.toString() == json['type'],
        orElse: () => MetricType.counter,
      ),
      value: (json['value'] ?? 0.0).toDouble(),
      tags: Map<String, String>.from(json['tags'] ?? {}),
      timestamp: DateTime.parse(json['timestamp']),
      timeWindow: json['timeWindow'] != null 
          ? Duration(milliseconds: json['timeWindow']) 
          : null,
    );
  }
}

/// User profile for analytics
class UserAnalyticsProfile {
  final String userId;
  final UserSegment segment;
  final Map<String, dynamic> traits;
  final Map<String, double> scores;
  final Map<String, int> counters;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final Duration totalPlayTime;
  final int sessionCount;
  final double engagementScore;
  final double churnRisk;
  final Map<String, dynamic> preferences;

  UserAnalyticsProfile({
    required this.userId,
    this.segment = UserSegment.new_user,
    Map<String, dynamic>? traits,
    Map<String, double>? scores,
    Map<String, int>? counters,
    DateTime? firstSeen,
    DateTime? lastSeen,
    Duration? totalPlayTime,
    this.sessionCount = 0,
    this.engagementScore = 0.0,
    this.churnRisk = 0.0,
    Map<String, dynamic>? preferences,
  }) : traits = traits ?? {},
       scores = scores ?? {},
       counters = counters ?? {},
       firstSeen = firstSeen ?? DateTime.now(),
       lastSeen = lastSeen ?? DateTime.now(),
       totalPlayTime = totalPlayTime ?? Duration.zero,
       preferences = preferences ?? {};

  UserAnalyticsProfile copyWith({
    UserSegment? segment,
    Map<String, dynamic>? traits,
    Map<String, double>? scores,
    Map<String, int>? counters,
    DateTime? lastSeen,
    Duration? totalPlayTime,
    int? sessionCount,
    double? engagementScore,
    double? churnRisk,
    Map<String, dynamic>? preferences,
  }) {
    return UserAnalyticsProfile(
      userId: userId,
      segment: segment ?? this.segment,
      traits: traits ?? Map.from(this.traits),
      scores: scores ?? Map.from(this.scores),
      counters: counters ?? Map.from(this.counters),
      firstSeen: firstSeen,
      lastSeen: lastSeen ?? this.lastSeen,
      totalPlayTime: totalPlayTime ?? this.totalPlayTime,
      sessionCount: sessionCount ?? this.sessionCount,
      engagementScore: engagementScore ?? this.engagementScore,
      churnRisk: churnRisk ?? this.churnRisk,
      preferences: preferences ?? Map.from(this.preferences),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'segment': segment.toString(),
      'traits': traits,
      'scores': scores,
      'counters': counters,
      'firstSeen': firstSeen.toIso8601String(),
      'lastSeen': lastSeen.toIso8601String(),
      'totalPlayTime': totalPlayTime.inMilliseconds,
      'sessionCount': sessionCount,
      'engagementScore': engagementScore,
      'churnRisk': churnRisk,
      'preferences': preferences,
    };
  }

  factory UserAnalyticsProfile.fromJson(Map<String, dynamic> json) {
    return UserAnalyticsProfile(
      userId: json['userId'],
      segment: UserSegment.values.firstWhere(
        (s) => s.toString() == json['segment'],
        orElse: () => UserSegment.new_user,
      ),
      traits: Map<String, dynamic>.from(json['traits'] ?? {}),
      scores: Map<String, double>.from(json['scores'] ?? {}),
      counters: Map<String, int>.from(json['counters'] ?? {}),
      firstSeen: DateTime.parse(json['firstSeen']),
      lastSeen: DateTime.parse(json['lastSeen']),
      totalPlayTime: Duration(milliseconds: json['totalPlayTime'] ?? 0),
      sessionCount: json['sessionCount'] ?? 0,
      engagementScore: (json['engagementScore'] ?? 0.0).toDouble(),
      churnRisk: (json['churnRisk'] ?? 0.0).toDouble(),
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
    );
  }
}

/// Analytics insight
class AnalyticsInsight {
  final String insightId;
  final String title;
  final String description;
  final String type; // trend, anomaly, prediction, recommendation
  final double confidence;
  final Map<String, dynamic> data;
  final DateTime discoveredAt;
  final bool isActionable;
  final List<String> tags;

  AnalyticsInsight({
    String? insightId,
    required this.title,
    required this.description,
    required this.type,
    this.confidence = 0.0,
    Map<String, dynamic>? data,
    DateTime? discoveredAt,
    this.isActionable = false,
    List<String>? tags,
  }) : insightId = insightId ?? 'insight_${DateTime.now().millisecondsSinceEpoch}',
       data = data ?? {},
       discoveredAt = discoveredAt ?? DateTime.now(),
       tags = tags ?? [];

  Map<String, dynamic> toJson() {
    return {
      'insightId': insightId,
      'title': title,
      'description': description,
      'type': type,
      'confidence': confidence,
      'data': data,
      'discoveredAt': discoveredAt.toIso8601String(),
      'isActionable': isActionable,
      'tags': tags,
    };
  }

  factory AnalyticsInsight.fromJson(Map<String, dynamic> json) {
    return AnalyticsInsight(
      insightId: json['insightId'],
      title: json['title'],
      description: json['description'],
      type: json['type'],
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      discoveredAt: DateTime.parse(json['discoveredAt']),
      isActionable: json['isActionable'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}

/// Analytics session
class AnalyticsSession {
  final String sessionId;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration? duration;
  final Map<String, int> eventCounts;
  final Map<String, double> metrics;
  final List<String> screens;
  final Map<String, dynamic> context;

  AnalyticsSession({
    String? sessionId,
    required this.userId,
    DateTime? startTime,
    this.endTime,
    this.duration,
    Map<String, int>? eventCounts,
    Map<String, double>? metrics,
    List<String>? screens,
    Map<String, dynamic>? context,
  }) : sessionId = sessionId ?? 'session_${DateTime.now().millisecondsSinceEpoch}',
       startTime = startTime ?? DateTime.now(),
       eventCounts = eventCounts ?? {},
       metrics = metrics ?? {},
       screens = screens ?? [],
       context = context ?? {};

  AnalyticsSession copyWith({
    DateTime? endTime,
    Duration? duration,
    Map<String, int>? eventCounts,
    Map<String, double>? metrics,
    List<String>? screens,
    Map<String, dynamic>? context,
  }) {
    return AnalyticsSession(
      sessionId: sessionId,
      userId: userId,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      eventCounts: eventCounts ?? Map.from(this.eventCounts),
      metrics: metrics ?? Map.from(this.metrics),
      screens: screens ?? List.from(this.screens),
      context: context ?? Map.from(this.context),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration?.inMilliseconds,
      'eventCounts': eventCounts,
      'metrics': metrics,
      'screens': screens,
      'context': context,
    };
  }

  factory AnalyticsSession.fromJson(Map<String, dynamic> json) {
    return AnalyticsSession(
      sessionId: json['sessionId'],
      userId: json['userId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      duration: json['duration'] != null ? Duration(milliseconds: json['duration']) : null,
      eventCounts: Map<String, int>.from(json['eventCounts'] ?? {}),
      metrics: Map<String, double>.from(json['metrics'] ?? {}),
      screens: List<String>.from(json['screens'] ?? []),
      context: Map<String, dynamic>.from(json['context'] ?? {}),
    );
  }
}

/// Analytics Agent - Advanced user behavior analysis and ML insights
class AnalyticsAgent extends BaseAgent {
  static const String agentId = 'analytics';

  final SharedPreferences _prefs;

  // Current user context
  String? _currentUserId;
  AnalyticsSession? _currentSession;

  // Analytics data stores
  final Map<String, UserAnalyticsProfile> _userProfiles = {};
  final List<AnalyticsEvent> _events = [];
  final List<AnalyticsMetric> _metrics = [];
  final List<AnalyticsInsight> _insights = {};
  final Map<String, AnalyticsSession> _sessions = {};

  // Machine Learning Models (simplified)
  final Map<PredictionModel, Map<String, dynamic>> _mlModels = {};
  final Map<String, double> _featureWeights = {};

  // Real-time analytics
  Timer? _analyticsTimer;
  Timer? _insightGenerator;
  Timer? _modelUpdater;

  // Performance tracking
  final List<Map<String, dynamic>> _performanceLog = [];
  int _totalEventsProcessed = 0;
  DateTime? _lastProcessingTime;

  AnalyticsAgent({
    required SharedPreferences prefs,
  }) : _prefs = prefs,
       super(agentId: agentId);

  @override
  Future<void> onInitialize() async {
    developer.log('Initializing Analytics Agent', name: agentId);

    // Load analytics data
    await _loadAnalyticsData();

    // Initialize ML models
    await _initializeMLModels();

    // Start real-time processing
    _startAnalyticsProcessing();

    // Start insight generation
    _startInsightGeneration();

    // Start model updating
    _startModelUpdating();

    developer.log('Analytics Agent initialized with ${_userProfiles.length} user profiles', name: agentId);
  }

  @override
  void subscribeToEvents() {
    // All events for comprehensive analytics
    subscribe(EventTypes.characterLevelUp, _handleCharacterEvent);
    subscribe(EventTypes.characterUpdated, _handleCharacterEvent);
    subscribe(EventTypes.characterXpGained, _handleCharacterEvent);

    subscribe(EventTypes.questStarted, _handleQuestEvent);
    subscribe(EventTypes.questCompleted, _handleQuestEvent);
    subscribe(EventTypes.questProgress, _handleQuestEvent);

    subscribe(EventTypes.battleStarted, _handleBattleEvent);
    subscribe(EventTypes.battleEnded, _handleBattleEvent);
    subscribe(EventTypes.battleResult, _handleBattleEvent);

    subscribe(EventTypes.cardScanned, _handleCardEvent);
    subscribe(EventTypes.inventoryChanged, _handleCardEvent);

    subscribe(EventTypes.achievementUnlocked, _handleAchievementEvent);
    subscribe(EventTypes.achievementProgress, _handleAchievementEvent);

    subscribe(EventTypes.fitnessUpdate, _handleFitnessEvent);
    subscribe(EventTypes.activityDetected, _handleFitnessEvent);

    subscribe(EventTypes.locationUpdate, _handleLocationEvent);
    subscribe(EventTypes.poiDetected, _handleLocationEvent);
    subscribe(EventTypes.geofenceEntered, _handleLocationEvent);

    subscribe(EventTypes.arExperienceTriggered, _handleAREvent);

    subscribe(EventTypes.uiButtonPressed, _handleUIEvent);
    subscribe(EventTypes.uiWindowOpened, _handleUIEvent);
    subscribe(EventTypes.uiNotification, _handleUIEvent);

    // Social events
    subscribe('social_friend_request_sent', _handleSocialEvent);
    subscribe('social_guild_created', _handleSocialEvent);
    subscribe('social_achievement_shared', _handleSocialEvent);

    // Audio events
    subscribe('audio_started', _handleAudioEvent);
    subscribe('audio_context_changed', _handleAudioEvent);

    // AR events
    subscribe('ar_session_started', _handleAREvent);
    subscribe('ar_object_placed', _handleAREvent);
    subscribe('ar_object_interacted', _handleAREvent);

    // User management
    subscribe('user_login', _handleUserLogin);
    subscribe('user_logout', _handleUserLogout);

    // Analytics-specific events
    subscribe('analytics_track_event', _handleTrackEvent);
    subscribe('analytics_track_metric', _handleTrackMetric);
    subscribe('analytics_get_insights', _handleGetInsights);
    subscribe('analytics_get_predictions', _handleGetPredictions);
    subscribe('analytics_segment_user', _handleSegmentUser);
  }

  /// Track analytics event
  void trackEvent(
    AnalyticsEventCategory category,
    String name, {
    Map<String, dynamic>? properties,
    double? value,
  }) {
    final event = AnalyticsEvent(
      category: category,
      name: name,
      properties: properties,
      userId: _currentUserId,
      sessionId: _currentSession?.sessionId,
      value: value,
    );

    _events.add(event);
    _totalEventsProcessed++;

    // Update session event counts
    if (_currentSession != null) {
      final eventCounts = Map<String, int>.from(_currentSession!.eventCounts);
      eventCounts[name] = (eventCounts[name] ?? 0) + 1;
      _currentSession = _currentSession!.copyWith(eventCounts: eventCounts);
    }

    // Update user profile
    _updateUserProfile(event);

    // Publish for other agents
    publishEvent(createEvent(
      eventType: 'analytics_event_tracked',
      data: {
        'category': category.toString(),
        'name': name,
        'userId': _currentUserId,
        'sessionId': _currentSession?.sessionId,
      },
    ));

    _logPerformanceMetric('event_tracked', {
      'category': category.toString(),
      'name': name,
      'hasValue': value != null,
    });

    developer.log('Analytics event tracked: $name', name: agentId);
  }

  /// Track analytics metric
  void trackMetric(
    String name,
    MetricType type,
    double value, {
    Map<String, String>? tags,
    Duration? timeWindow,
  }) {
    final metric = AnalyticsMetric(
      name: name,
      type: type,
      value: value,
      tags: tags,
      timeWindow: timeWindow,
    );

    _metrics.add(metric);

    // Update session metrics
    if (_currentSession != null) {
      final sessionMetrics = Map<String, double>.from(_currentSession!.metrics);
      sessionMetrics[name] = value;
      _currentSession = _currentSession!.copyWith(metrics: sessionMetrics);
    }

    publishEvent(createEvent(
      eventType: 'analytics_metric_tracked',
      data: {
        'name': name,
        'type': type.toString(),
        'value': value,
        'tags': tags,
      },
    ));

    _logPerformanceMetric('metric_tracked', {
      'name': name,
      'type': type.toString(),
      'value': value,
    });
  }

  /// Start user session
  String startSession(String userId) {
    // End previous session if exists
    if (_currentSession != null) {
      endSession();
    }

    _currentUserId = userId;
    _currentSession = AnalyticsSession(
      userId: userId,
      context: {
        'app_version': '1.0.0',
        'platform': 'mobile',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    _sessions[_currentSession!.sessionId] = _currentSession!;

    // Update user profile
    final profile = _userProfiles[userId];
    if (profile != null) {
      _userProfiles[userId] = profile.copyWith(
        sessionCount: profile.sessionCount + 1,
        lastSeen: DateTime.now(),
      );
    }

    trackEvent(AnalyticsEventCategory.user_behavior, 'session_started');

    developer.log('Analytics session started: ${_currentSession!.sessionId}', name: agentId);
    return _currentSession!.sessionId;
  }

  /// End user session
  void endSession() {
    if (_currentSession == null) return;

    final endTime = DateTime.now();
    final duration = endTime.difference(_currentSession!.startTime);

    _currentSession = _currentSession!.copyWith(
      endTime: endTime,
      duration: duration,
    );

    _sessions[_currentSession!.sessionId] = _currentSession!;

    // Update user profile with session data
    final profile = _userProfiles[_currentUserId!];
    if (profile != null) {
      _userProfiles[_currentUserId!] = profile.copyWith(
        totalPlayTime: profile.totalPlayTime + duration,
        lastSeen: endTime,
      );
    }

    trackEvent(AnalyticsEventCategory.user_behavior, 'session_ended', 
               value: duration.inSeconds.toDouble());

    _currentSession = null;
    _currentUserId = null;

    developer.log('Analytics session ended', name: agentId);
  }

  /// Get user predictions
  Map<PredictionModel, double> getUserPredictions(String userId) {
    final profile = _userProfiles[userId];
    if (profile == null) return {};

    final predictions = <PredictionModel, double>{};

    // Churn prediction
    predictions[PredictionModel.churn_prediction] = _predictChurn(profile);

    // Engagement scoring
    predictions[PredictionModel.engagement_scoring] = _scoreEngagement(profile);

    // Monetization propensity
    predictions[PredictionModel.monetization_propensity] = _predictMonetization(profile);

    return predictions;
  }

  /// Get content recommendations
  List<Map<String, dynamic>> getContentRecommendations(String userId, {int limit = 5}) {
    final profile = _userProfiles[userId];
    if (profile == null) return [];

    final recommendations = <Map<String, dynamic>>[];

    // Quest recommendations based on preferences
    if (profile.preferences['questTypes'] != null) {
      recommendations.add({
        'type': 'quest',
        'title': 'Recommended Quest',
        'description': 'Based on your preferred quest types',
        'confidence': 0.8,
        'data': {'questType': profile.preferences['questTypes']},
      });
    }

    // Card recommendations based on collection patterns
    if (profile.counters['cards_collected'] != null) {
      recommendations.add({
        'type': 'card',
        'title': 'Rare Card Available',
        'description': 'Complete your collection with this rare card',
        'confidence': 0.7,
        'data': {'cardRarity': 'rare'},
      });
    }

    // Social recommendations
    if (profile.scores['social_activity'] != null && profile.scores['social_activity']! > 0.5) {
      recommendations.add({
        'type': 'social',
        'title': 'Join a Guild',
        'description': 'Connect with other players in your area',
        'confidence': 0.6,
        'data': {'recommendationType': 'guild'},
      });
    }

    return recommendations.take(limit).toList();
  }

  /// Get analytics insights
  List<AnalyticsInsight> getInsights({String? category, bool? actionableOnly}) {
    var insights = _insights.toList();

    if (category != null) {
      insights = insights.where((i) => i.tags.contains(category)).toList();
    }

    if (actionableOnly == true) {
      insights = insights.where((i) => i.isActionable).toList();
    }

    // Sort by confidence and recency
    insights.sort((a, b) {
      final confidenceCompare = b.confidence.compareTo(a.confidence);
      if (confidenceCompare != 0) return confidenceCompare;
      return b.discoveredAt.compareTo(a.discoveredAt);
    });

    return insights;
  }

  /// Get user segment
  UserSegment getUserSegment(String userId) {
    final profile = _userProfiles[userId];
    if (profile == null) return UserSegment.new_user;

    return _calculateUserSegment(profile);
  }

  /// Get analytics dashboard data
  Map<String, dynamic> getAnalyticsDashboard() {
    final now = DateTime.now();
    final dayAgo = now.subtract(const Duration(days: 1));
    final weekAgo = now.subtract(const Duration(days: 7));

    // Daily active users
    final dailyActiveUsers = _sessions.values
        .where((s) => s.startTime.isAfter(dayAgo))
        .map((s) => s.userId)
        .toSet()
        .length;

    // Weekly active users
    final weeklyActiveUsers = _sessions.values
        .where((s) => s.startTime.isAfter(weekAgo))
        .map((s) => s.userId)
        .toSet()
        .length;

    // User segments distribution
    final segmentDistribution = <String, int>{};
    for (final segment in UserSegment.values) {
      segmentDistribution[segment.toString()] = _userProfiles.values
          .where((p) => p.segment == segment)
          .length;
    }

    // Top events
    final eventCounts = <String, int>{};
    for (final event in _events) {
      eventCounts[event.name] = (eventCounts[event.name] ?? 0) + 1;
    }
    final topEvents = eventCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Average session duration
    final sessionDurations = _sessions.values
        .where((s) => s.duration != null)
        .map((s) => s.duration!.inMinutes)
        .toList();
    final avgSessionDuration = sessionDurations.isNotEmpty
        ? sessionDurations.reduce((a, b) => a + b) / sessionDurations.length
        : 0.0;

    return {
      'totalUsers': _userProfiles.length,
      'dailyActiveUsers': dailyActiveUsers,
      'weeklyActiveUsers': weeklyActiveUsers,
      'totalSessions': _sessions.length,
      'averageSessionDuration': avgSessionDuration,
      'totalEvents': _events.length,
      'totalMetrics': _metrics.length,
      'totalInsights': _insights.length,
      'segmentDistribution': segmentDistribution,
      'topEvents': topEvents.take(10).map((e) => {
        'name': e.key,
        'count': e.value,
      }).toList(),
      'churnRisk': _userProfiles.values.map((p) => p.churnRisk).fold(0.0, (a, b) => a + b) / _userProfiles.length,
      'engagementScore': _userProfiles.values.map((p) => p.engagementScore).fold(0.0, (a, b) => a + b) / _userProfiles.length,
    };
  }

  /// Update user profile based on event
  void _updateUserProfile(AnalyticsEvent event) {
    if (event.userId == null) return;

    var profile = _userProfiles[event.userId!] ?? UserAnalyticsProfile(userId: event.userId!);

    // Update counters
    final counters = Map<String, int>.from(profile.counters);
    counters[event.name] = (counters[event.name] ?? 0) + 1;

    // Update traits based on event category
    final traits = Map<String, dynamic>.from(profile.traits);
    switch (event.category) {
      case AnalyticsEventCategory.gameplay:
        traits['gameplay_focused'] = true;
        break;
      case AnalyticsEventCategory.social:
        traits['social_player'] = true;
        break;
      case AnalyticsEventCategory.ar_interaction:
        traits['ar_enthusiast'] = true;
        break;
      default:
        break;
    }

    // Update scores
    final scores = Map<String, double>.from(profile.scores);
    scores['activity_score'] = (scores['activity_score'] ?? 0.0) + 1.0;

    // Calculate engagement score
    final engagementScore = _calculateEngagementScore(profile, event);

    // Calculate churn risk
    final churnRisk = _calculateChurnRisk(profile);

    // Determine segment
    final segment = _calculateUserSegment(profile);

    _userProfiles[event.userId!] = profile.copyWith(
      counters: counters,
      traits: traits,
      scores: scores,
      engagementScore: engagementScore,
      churnRisk: churnRisk,
      segment: segment,
      lastSeen: DateTime.now(),
    );
  }

  /// Calculate user engagement score
  double _calculateEngagementScore(UserAnalyticsProfile profile, AnalyticsEvent event) {
    double score = profile.engagementScore;

    // Base activity points
    score += 0.1;

    // Category-specific bonuses
    switch (event.category) {
      case AnalyticsEventCategory.gameplay:
        score += 0.5;
        break;
      case AnalyticsEventCategory.progression:
        score += 0.8;
        break;
      case AnalyticsEventCategory.social:
        score += 0.3;
        break;
      case AnalyticsEventCategory.ar_interaction:
        score += 0.4;
        break;
      default:
        score += 0.1;
        break;
    }

    // Session length bonus
    if (_currentSession != null) {
      final sessionMinutes = DateTime.now().difference(_currentSession!.startTime).inMinutes;
      score += sessionMinutes * 0.01;
    }

    // Daily activity bonus
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    final todayEvents = _events.where((e) => 
        e.userId == profile.userId && e.timestamp.isAfter(dayStart)).length;
    
    if (todayEvents > 10) score += 1.0;
    if (todayEvents > 20) score += 2.0;

    return math.min(100.0, score); // Cap at 100
  }

  /// Calculate churn risk
  double _calculateChurnRisk(UserAnalyticsProfile profile) {
    final daysSinceLastSeen = DateTime.now().difference(profile.lastSeen).inDays;
    
    double risk = 0.0;
    
    // Days since last activity
    if (daysSinceLastSeen > 7) risk += 0.3;
    if (daysSinceLastSeen > 14) risk += 0.3;
    if (daysSinceLastSeen > 30) risk += 0.4;

    // Low engagement
    if (profile.engagementScore < 10) risk += 0.2;
    if (profile.engagementScore < 5) risk += 0.3;

    // Low session count
    if (profile.sessionCount < 5) risk += 0.2;

    // Short play time
    if (profile.totalPlayTime.inHours < 2) risk += 0.2;

    return math.min(1.0, risk);
  }

  /// Calculate user segment
  UserSegment _calculateUserSegment(UserAnalyticsProfile profile) {
    final daysSinceFirst = DateTime.now().difference(profile.firstSeen).inDays;
    final sessionCount = profile.sessionCount;
    final engagementScore = profile.engagementScore;
    final churnRisk = profile.churnRisk;

    // Churned users
    if (churnRisk > 0.8 && daysSinceFirst > 30) return UserSegment.churned;
    
    // Inactive users
    if (churnRisk > 0.6) return UserSegment.inactive;

    // New users
    if (daysSinceFirst < 7 || sessionCount < 3) return UserSegment.new_user;

    // Social players
    if (profile.traits['social_player'] == true && engagementScore > 20) {
      return UserSegment.social_player;
    }

    // Hardcore players
    if (engagementScore > 50 && sessionCount > 20) return UserSegment.hardcore_player;

    // Regular players
    if (engagementScore > 20 && sessionCount > 10) return UserSegment.regular_player;

    // Collectors
    if (profile.counters['cards_collected'] != null && 
        profile.counters['cards_collected']! > 50) {
      return UserSegment.collector;
    }

    // Explorers
    if (profile.counters['poi_discovered'] != null && 
        profile.counters['poi_discovered']! > 10) {
      return UserSegment.explorer;
    }

    // Competitors
    if (profile.counters['battles_won'] != null && 
        profile.counters['battles_won']! > 20) {
      return UserSegment.competitor;
    }

    return UserSegment.casual_player;
  }

  /// Predict churn probability
  double _predictChurn(UserAnalyticsProfile profile) {
    // Simplified ML model for churn prediction
    double score = 0.0;

    // Feature: Days since last activity
    final daysSinceLastSeen = DateTime.now().difference(profile.lastSeen).inDays;
    score += daysSinceLastSeen * 0.05;

    // Feature: Engagement score (inverse relationship)
    score += (100 - profile.engagementScore) * 0.01;

    // Feature: Session frequency
    final avgDaysBetweenSessions = profile.sessionCount > 1 
        ? DateTime.now().difference(profile.firstSeen).inDays / profile.sessionCount
        : 30.0;
    score += avgDaysBetweenSessions * 0.02;

    // Feature: Total play time (inverse relationship)
    score += math.max(0, 10 - profile.totalPlayTime.inHours) * 0.05;

    return math.min(1.0, score);
  }

  /// Score user engagement
  double _scoreEngagement(UserAnalyticsProfile profile) {
    return profile.engagementScore / 100.0; // Normalize to 0-1
  }

  /// Predict monetization propensity
  double _predictMonetization(UserAnalyticsProfile profile) {
    double score = 0.0;

    // High engagement users more likely to monetize
    score += profile.engagementScore * 0.01;

    // Social players more likely to monetize
    if (profile.traits['social_player'] == true) score += 0.3;

    // Collectors more likely to monetize
    if (profile.segment == UserSegment.collector) score += 0.4;

    // Regular and hardcore players more likely to monetize
    if (profile.segment == UserSegment.regular_player) score += 0.2;
    if (profile.segment == UserSegment.hardcore_player) score += 0.5;

    // Long-term players more likely to monetize
    final daysPlaying = DateTime.now().difference(profile.firstSeen).inDays;
    if (daysPlaying > 30) score += 0.2;
    if (daysPlaying > 90) score += 0.3;

    return math.min(1.0, score);
  }

  /// Initialize ML models
  Future<void> _initializeMLModels() async {
    // Initialize simplified feature weights for different models
    _featureWeights.addAll({
      'days_since_last_seen': 0.3,
      'engagement_score': 0.4,
      'session_count': 0.2,
      'total_play_time': 0.1,
      'social_activity': 0.3,
      'cards_collected': 0.2,
      'battles_won': 0.15,
      'quests_completed': 0.15,
      'ar_interactions': 0.1,
      'ui_interactions': 0.05,
    });

    // Initialize model configurations
    _mlModels.addAll({
      PredictionModel.churn_prediction: {
        'type': 'logistic_regression',
        'features': ['days_since_last_seen', 'engagement_score', 'session_count'],
        'threshold': 0.7,
        'accuracy': 0.85,
      },
      PredictionModel.engagement_scoring: {
        'type': 'linear_regression',
        'features': ['session_count', 'total_play_time', 'social_activity'],
        'accuracy': 0.78,
      },
      PredictionModel.monetization_propensity: {
        'type': 'random_forest',
        'features': ['engagement_score', 'segment', 'cards_collected', 'social_activity'],
        'accuracy': 0.72,
      },
    });

    developer.log('ML models initialized', name: agentId);
  }

  /// Start analytics processing
  void _startAnalyticsProcessing() {
    _analyticsTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _processAnalytics();
    });
  }

  /// Start insight generation
  void _startInsightGeneration() {
    _insightGenerator = Timer.periodic(const Duration(hours: 1), (timer) {
      _generateInsights();
    });
  }

  /// Start model updating
  void _startModelUpdating() {
    _modelUpdater = Timer.periodic(const Duration(hours: 6), (timer) {
      _updateMLModels();
    });
  }

  /// Process analytics periodically
  void _processAnalytics() {
    final now = DateTime.now();
    
    // Update user segments
    for (final profile in _userProfiles.values) {
      final newSegment = _calculateUserSegment(profile);
      if (newSegment != profile.segment) {
        _userProfiles[profile.userId] = profile.copyWith(segment: newSegment);
        
        publishEvent(createEvent(
          eventType: 'user_segment_changed',
          data: {
            'userId': profile.userId,
            'oldSegment': profile.segment.toString(),
            'newSegment': newSegment.toString(),
          },
        ));
      }
    }

    // Clean old events (keep last 30 days)
    final cutoff = now.subtract(const Duration(days: 30));
    _events.removeWhere((event) => event.timestamp.isBefore(cutoff));
    _metrics.removeWhere((metric) => metric.timestamp.isBefore(cutoff));

    _lastProcessingTime = now;
    
    _logPerformanceMetric('analytics_processed', {
      'userProfiles': _userProfiles.length,
      'events': _events.length,
      'metrics': _metrics.length,
    });
  }

  /// Generate insights
  void _generateInsights() {
    // Trend analysis
    _analyzeTrends();
    
    // Anomaly detection
    _detectAnomalies();
    
    // User behavior patterns
    _analyzeUserBehaviorPatterns();
    
    developer.log('Generated ${_insights.length} insights', name: agentId);
  }

  /// Analyze trends
  void _analyzeTrends() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final twoWeeksAgo = now.subtract(const Duration(days: 14));

    // Active user trend
    final thisWeekUsers = _sessions.values
        .where((s) => s.startTime.isAfter(weekAgo))
        .map((s) => s.userId)
        .toSet()
        .length;

    final lastWeekUsers = _sessions.values
        .where((s) => s.startTime.isAfter(twoWeeksAgo) && s.startTime.isBefore(weekAgo))
        .map((s) => s.userId)
        .toSet()
        .length;

    if (lastWeekUsers > 0) {
      final growth = (thisWeekUsers - lastWeekUsers) / lastWeekUsers;
      
      if (growth.abs() > 0.1) { // 10% change threshold
        _insights.add(AnalyticsInsight(
          title: growth > 0 ? 'User Growth Trend' : 'User Decline Trend',
          description: 'Weekly active users ${growth > 0 ? "increased" : "decreased"} by ${(growth * 100).round()}%',
          type: 'trend',
          confidence: 0.8,
          isActionable: growth < -0.2, // Actionable if decline > 20%
          data: {
            'thisWeek': thisWeekUsers,
            'lastWeek': lastWeekUsers,
            'growthRate': growth,
          },
          tags: ['user_activity', 'weekly_trend'],
        ));
      }
    }
  }

  /// Detect anomalies
  void _detectAnomalies() {
    // Detect unusual churn rate
    final avgChurnRisk = _userProfiles.values
        .map((p) => p.churnRisk)
        .fold(0.0, (a, b) => a + b) / _userProfiles.length;

    if (avgChurnRisk > 0.6) {
      _insights.add(AnalyticsInsight(
        title: 'High Churn Risk Detected',
        description: 'Average churn risk is ${(avgChurnRisk * 100).round()}%, which is above normal levels',
        type: 'anomaly',
        confidence: 0.9,
        isActionable: true,
        data: {'avgChurnRisk': avgChurnRisk},
        tags: ['churn', 'user_retention'],
      ));
    }
  }

  /// Analyze user behavior patterns
  void _analyzeUserBehaviorPatterns() {
    // Most common event sequences
    final eventSequences = <String, int>{};
    
    // Analyze session patterns
    final sessionLengths = _sessions.values
        .where((s) => s.duration != null)
        .map((s) => s.duration!.inMinutes)
        .toList();

    if (sessionLengths.isNotEmpty) {
      final avgSessionLength = sessionLengths.reduce((a, b) => a + b) / sessionLengths.length;
      
      if (avgSessionLength < 5) {
        _insights.add(AnalyticsInsight(
          title: 'Short Session Pattern',
          description: 'Average session length is ${avgSessionLength.round()} minutes, indicating potential engagement issues',
          type: 'pattern',
          confidence: 0.7,
          isActionable: true,
          data: {'avgSessionLength': avgSessionLength},
          tags: ['session_length', 'engagement'],
        ));
      }
    }
  }

  /// Update ML models
  void _updateMLModels() {
    // In a real implementation, this would retrain models with new data
    // For now, we'll just update model accuracy metrics
    
    for (final model in _mlModels.keys) {
      final modelData = Map<String, dynamic>.from(_mlModels[model]!);
      
      // Simulate model accuracy changes based on data quality
      final currentAccuracy = modelData['accuracy'] ?? 0.5;
      final dataQuality = _userProfiles.length / 100.0; // More users = better data
      final newAccuracy = math.min(0.95, currentAccuracy + (dataQuality * 0.01));
      
      modelData['accuracy'] = newAccuracy;
      modelData['lastUpdated'] = DateTime.now().toIso8601String();
      
      _mlModels[model] = modelData;
    }

    _logPerformanceMetric('models_updated', {
      'modelCount': _mlModels.length,
      'dataSize': _userProfiles.length,
    });

    developer.log('ML models updated', name: agentId);
  }

  /// Load analytics data
  Future<void> _loadAnalyticsData() async {
    try {
      // Load user profiles
      final profilesJson = _prefs.getString('analytics_user_profiles');
      if (profilesJson != null) {
        final data = jsonDecode(profilesJson) as Map<String, dynamic>;
        for (final entry in data.entries) {
          _userProfiles[entry.key] = UserAnalyticsProfile.fromJson(entry.value);
        }
      }

      // Load recent events (last 30 days)
      final eventsJson = _prefs.getString('analytics_events');
      if (eventsJson != null) {
        final data = jsonDecode(eventsJson) as List;
        for (final eventData in data) {
          _events.add(AnalyticsEvent.fromJson(eventData));
        }
      }

      // Load sessions
      final sessionsJson = _prefs.getString('analytics_sessions');
      if (sessionsJson != null) {
        final data = jsonDecode(sessionsJson) as Map<String, dynamic>;
        for (final entry in data.entries) {
          _sessions[entry.key] = AnalyticsSession.fromJson(entry.value);
        }
      }

      // Load insights
      final insightsJson = _prefs.getString('analytics_insights');
      if (insightsJson != null) {
        final data = jsonDecode(insightsJson) as List;
        for (final insightData in data) {
          _insights.add(AnalyticsInsight.fromJson(insightData));
        }
      }

    } catch (e) {
      developer.log('Error loading analytics data: $e', name: agentId);
    }
  }

  /// Save analytics data
  Future<void> _saveAnalyticsData() async {
    try {
      // Save user profiles
      final profilesData = _userProfiles.map((k, v) => MapEntry(k, v.toJson()));
      await _prefs.setString('analytics_user_profiles', jsonEncode(profilesData));

      // Save recent events (last 7 days only for storage efficiency)
      final cutoff = DateTime.now().subtract(const Duration(days: 7));
      final recentEvents = _events.where((e) => e.timestamp.isAfter(cutoff)).toList();
      await _prefs.setString('analytics_events', jsonEncode(recentEvents.map((e) => e.toJson()).toList()));

      // Save sessions
      final sessionsData = _sessions.map((k, v) => MapEntry(k, v.toJson()));
      await _prefs.setString('analytics_sessions', jsonEncode(sessionsData));

      // Save insights
      await _prefs.setString('analytics_insights', jsonEncode(_insights.map((i) => i.toJson()).toList()));

    } catch (e) {
      developer.log('Error saving analytics data: $e', name: agentId);
    }
  }

  /// Log performance metric
  void _logPerformanceMetric(String metricType, Map<String, dynamic> data) {
    _performanceLog.add({
      'metricType': metricType,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Keep only last 100 metrics
    if (_performanceLog.length > 100) {
      _performanceLog.removeAt(0);
    }
  }

  // Event Handlers - Track all game events for comprehensive analytics

  /// Handle character events
  Future<AgentEventResponse?> _handleCharacterEvent(AgentEvent event) async {
    trackEvent(AnalyticsEventCategory.progression, event.eventType,
               properties: event.data);

    return createResponse(
      originalEventId: event.id,
      responseType: 'analytics_character_tracked',
      data: {'eventType': event.eventType},
    );
  }

  /// Handle quest events
  Future<AgentEventResponse?> _handleQuestEvent(AgentEvent event) async {
    trackEvent(AnalyticsEventCategory.gameplay, event.eventType,
               properties: event.data);

    return createResponse(
      originalEventId: event.id,
      responseType: 'analytics_quest_tracked',
      data: {'eventType': event.eventType},
    );
  }

  /// Handle battle events
  Future<AgentEventResponse?> _handleBattleEvent(AgentEvent event) async {
    trackEvent(AnalyticsEventCategory.gameplay, event.eventType,
               properties: event.data);

    return createResponse(
      originalEventId: event.id,
      responseType: 'analytics_battle_tracked',
      data: {'eventType': event.eventType},
    );
  }

  /// Handle card events
  Future<AgentEventResponse?> _handleCardEvent(AgentEvent event) async {
    trackEvent(AnalyticsEventCategory.progression, event.eventType,
               properties: event.data);

    return createResponse(
      originalEventId: event.id,
      responseType: 'analytics_card_tracked',
      data: {'eventType': event.eventType},
    );
  }

  /// Handle achievement events
  Future<AgentEventResponse?> _handleAchievementEvent(AgentEvent event) async {
    trackEvent(AnalyticsEventCategory.progression, event.eventType,
               properties: event.data);

    return createResponse(
      originalEventId: event.id,
      responseType: 'analytics_achievement_tracked',
      data: {'eventType': event.eventType},
    );
  }

  /// Handle fitness events
  Future<AgentEventResponse?> _handleFitnessEvent(AgentEvent event) async {
    trackEvent(AnalyticsEventCategory.user_behavior, event.eventType,
               properties: event.data);

    return createResponse(
      originalEventId: event.id,
      responseType: 'analytics_fitness_tracked',
      data: {'eventType': event.eventType},
    );
  }

  /// Handle location events
  Future<AgentEventResponse?> _handleLocationEvent(AgentEvent event) async {
    trackEvent(AnalyticsEventCategory.location, event.eventType,
               properties: event.data);

    return createResponse(
      originalEventId: event.id,
      responseType: 'analytics_location_tracked',
      data: {'eventType': event.eventType},
    );
  }

  /// Handle AR events
  Future<AgentEventResponse?> _handleAREvent(AgentEvent event) async {
    trackEvent(AnalyticsEventCategory.ar_interaction, event.eventType,
               properties: event.data);

    return createResponse(
      originalEventId: event.id,
      responseType: 'analytics_ar_tracked',
      data: {'eventType': event.eventType},
    );
  }

  /// Handle UI events
  Future<AgentEventResponse?> _handleUIEvent(AgentEvent event) async {
    trackEvent(AnalyticsEventCategory.ui_interaction, event.eventType,
               properties: event.data);

    return createResponse(
      originalEventId: event.id,
      responseType: 'analytics_ui_tracked',
      data: {'eventType': event.eventType},
    );
  }

  /// Handle social events
  Future<AgentEventResponse?> _handleSocialEvent(AgentEvent event) async {
    trackEvent(AnalyticsEventCategory.social, event.eventType,
               properties: event.data);

    return createResponse(
      originalEventId: event.id,
      responseType: 'analytics_social_tracked',
      data: {'eventType': event.eventType},
    );
  }

  /// Handle audio events
  Future<AgentEventResponse?> _handleAudioEvent(AgentEvent event) async {
    trackEvent(AnalyticsEventCategory.audio_engagement, event.eventType,
               properties: event.data);

    return createResponse(
      originalEventId: event.id,
      responseType: 'analytics_audio_tracked',
      data: {'eventType': event.eventType},
    );
  }

  /// Handle track event requests
  Future<AgentEventResponse?> _handleTrackEvent(AgentEvent event) async {
    final category = event.data['category'];
    final name = event.data['name'];
    final properties = event.data['properties'];
    final value = event.data['value']?.toDouble();

    if (category == null || name == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'analytics_track_event_failed',
        data: {'error': 'Missing category or name'},
        success: false,
      );
    }

    final analyticsCategory = AnalyticsEventCategory.values.firstWhere(
      (c) => c.toString() == category,
      orElse: () => AnalyticsEventCategory.user_behavior,
    );

    trackEvent(analyticsCategory, name, properties: properties, value: value);

    return createResponse(
      originalEventId: event.id,
      responseType: 'analytics_event_tracked',
      data: {'category': category, 'name': name},
    );
  }

  /// Handle track metric requests
  Future<AgentEventResponse?> _handleTrackMetric(AgentEvent event) async {
    final name = event.data['name'];
    final type = event.data['type'];
    final value = event.data['value']?.toDouble();

    if (name == null || type == null || value == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'analytics_track_metric_failed',
        data: {'error': 'Missing name, type, or value'},
        success: false,
      );
    }

    final metricType = MetricType.values.firstWhere(
      (t) => t.toString() == type,
      orElse: () => MetricType.counter,
    );

    trackMetric(name, metricType, value);

    return createResponse(
      originalEventId: event.id,
      responseType: 'analytics_metric_tracked',
      data: {'name': name, 'type': type, 'value': value},
    );
  }

  /// Handle get insights requests
  Future<AgentEventResponse?> _handleGetInsights(AgentEvent event) async {
    final category = event.data['category'];
    final actionableOnly = event.data['actionableOnly'];

    final insights = getInsights(category: category, actionableOnly: actionableOnly);

    return createResponse(
      originalEventId: event.id,
      responseType: 'analytics_insights_retrieved',
      data: {
        'insights': insights.map((i) => i.toJson()).toList(),
        'count': insights.length,
      },
    );
  }

  /// Handle get predictions requests
  Future<AgentEventResponse?> _handleGetPredictions(AgentEvent event) async {
    final userId = event.data['userId'] ?? _currentUserId;

    if (userId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'analytics_predictions_failed',
        data: {'error': 'No user ID provided'},
        success: false,
      );
    }

    final predictions = getUserPredictions(userId);
    final recommendations = getContentRecommendations(userId);

    return createResponse(
      originalEventId: event.id,
      responseType: 'analytics_predictions_retrieved',
      data: {
        'predictions': predictions.map((k, v) => MapEntry(k.toString(), v)),
        'recommendations': recommendations,
      },
    );
  }

  /// Handle segment user requests
  Future<AgentEventResponse?> _handleSegmentUser(AgentEvent event) async {
    final userId = event.data['userId'] ?? _currentUserId;

    if (userId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'analytics_segment_failed',
        data: {'error': 'No user ID provided'},
        success: false,
      );
    }

    final segment = getUserSegment(userId);

    return createResponse(
      originalEventId: event.id,
      responseType: 'analytics_user_segmented',
      data: {
        'userId': userId,
        'segment': segment.toString(),
      },
    );
  }

  /// Handle user login events
  Future<AgentEventResponse?> _handleUserLogin(AgentEvent event) async {
    final userId = event.data['userId'];
    
    if (userId != null) {
      startSession(userId);
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'user_login_analytics_processed',
      data: {'sessionStarted': userId != null},
    );
  }

  /// Handle user logout events
  Future<AgentEventResponse?> _handleUserLogout(AgentEvent event) async {
    endSession();
    await _saveAnalyticsData();

    return createResponse(
      originalEventId: event.id,
      responseType: 'user_logout_analytics_processed',
      data: {'sessionEnded': true},
    );
  }

  @override
  Future<void> onDispose() async {
    // Stop timers
    _analyticsTimer?.cancel();
    _insightGenerator?.cancel();
    _modelUpdater?.cancel();

    // End current session
    if (_currentSession != null) {
      endSession();
    }

    // Save all data
    await _saveAnalyticsData();

    developer.log('Analytics Agent disposed', name: agentId);
  }
}