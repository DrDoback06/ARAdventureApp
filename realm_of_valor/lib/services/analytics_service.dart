import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;

enum EventType {
  // User Actions
  appLaunch,
  appClose,
  screenView,
  buttonClick,
  cardInteraction,
  battleStart,
  battleEnd,
  questComplete,
  achievementUnlocked,
  levelUp,
  itemAcquired,
  itemUsed,
  qrCodeScanned,
  
  // Game Events
  characterCreated,
  characterDeleted,
  skillLearned,
  equipmentChanged,
  inventoryOpened,
  shopVisited,
  tradeCompleted,
  guildJoined,
  friendAdded,
  
  // Performance Events
  performanceIssue,
  crashReported,
  memoryWarning,
  slowFrameRate,
  
  // Social Events
  messageSent,
  tradeOfferSent,
  guildActivity,
  friendOnline,
  
  // Adventure Events
  locationVisited,
  fitnessGoalMet,
  weatherIntegration,
  dailyStreak,
}

enum UserSegment {
  newUser,
  casualPlayer,
  activePlayer,
  hardcorePlayer,
  returningPlayer,
}

class AnalyticsEvent {
  final String id;
  final EventType type;
  final String name;
  final Map<String, dynamic> properties;
  final DateTime timestamp;
  final String? userId;
  final String? sessionId;

  AnalyticsEvent({
    String? id,
    required this.type,
    required this.name,
    Map<String, dynamic>? properties,
    DateTime? timestamp,
    this.userId,
    this.sessionId,
  })  : id = id ?? _generateEventId(),
        properties = properties ?? {},
        timestamp = timestamp ?? DateTime.now();

  static String _generateEventId() {
    return 'event_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'name': name,
      'properties': properties,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'sessionId': sessionId,
    };
  }

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      id: json['id'],
      type: EventType.values.firstWhere((e) => e.name == json['type']),
      name: json['name'],
      properties: Map<String, dynamic>.from(json['properties']),
      timestamp: DateTime.parse(json['timestamp']),
      userId: json['userId'],
      sessionId: json['sessionId'],
    );
  }
}

class UserSession {
  final String id;
  final DateTime startTime;
  DateTime? endTime;
  final String? userId;
  final Map<String, dynamic> deviceInfo;
  final List<String> events = [];

  UserSession({
    String? id,
    DateTime? startTime,
    this.endTime,
    this.userId,
    Map<String, dynamic>? deviceInfo,
  })  : id = id ?? _generateSessionId(),
        startTime = startTime ?? DateTime.now(),
        deviceInfo = deviceInfo ?? {};

  static String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}';
  }

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'userId': userId,
      'deviceInfo': deviceInfo,
      'events': events,
      'duration': duration.inSeconds,
    };
  }

  factory UserSession.fromJson(Map<String, dynamic> json) {
    final session = UserSession(
      id: json['id'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      userId: json['userId'],
      deviceInfo: Map<String, dynamic>.from(json['deviceInfo']),
    );
    
    if (json['events'] != null) {
      session.events.addAll(List<String>.from(json['events']));
    }
    
    return session;
  }
}

class AnalyticsService extends ChangeNotifier {
  static AnalyticsService? _instance;
  static AnalyticsService get instance => _instance ??= AnalyticsService._();
  
  AnalyticsService._();
  
  List<AnalyticsEvent> _events = [];
  List<UserSession> _sessions = [];
  UserSession? _currentSession;
  String? _currentUserId;
  bool _isEnabled = true;
  bool _isDebugMode = false;
  
  // Analytics data
  Map<String, int> _eventCounts = {};
  Map<String, Duration> _screenTime = {};
  Map<String, int> _userActions = {};
  List<Map<String, dynamic>> _performanceMetrics = [];
  
  // Getters
  List<AnalyticsEvent> get events => _events;
  List<UserSession> get sessions => _sessions;
  UserSession? get currentSession => _currentSession;
  bool get isEnabled => _isEnabled;
  bool get isDebugMode => _isDebugMode;
  Map<String, int> get eventCounts => _eventCounts;
  Map<String, Duration> get screenTime => _screenTime;
  Map<String, int> get userActions => _userActions;

  // Initialize analytics
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEvents = prefs.getString('analytics_events');
      final savedSessions = prefs.getString('analytics_sessions');
      final isEnabled = prefs.getBool('analytics_enabled') ?? true;
      final isDebugMode = prefs.getBool('analytics_debug') ?? false;
      
      if (savedEvents != null) {
        final List<dynamic> eventsJson = jsonDecode(savedEvents);
        _events = eventsJson.map((json) => AnalyticsEvent.fromJson(json)).toList();
      }
      
      if (savedSessions != null) {
        final List<dynamic> sessionsJson = jsonDecode(savedSessions);
        _sessions = sessionsJson.map((json) => UserSession.fromJson(json)).toList();
      }
      
      _isEnabled = isEnabled;
      _isDebugMode = isDebugMode;
      
      // Start new session
      _startNewSession();
      
      debugPrint('[ANALYTICS] Service initialized with ${_events.length} events, ${_sessions.length} sessions');
    } catch (e) {
      debugPrint('[ANALYTICS] Error initializing: $e');
    }
  }

  // Start new session
  void _startNewSession() {
    _currentSession = UserSession(
      userId: _currentUserId,
      deviceInfo: _getDeviceInfo(),
    );
    _sessions.add(_currentSession!);
    
    // Track session start
    trackEvent(
      EventType.appLaunch,
      'Session Started',
      properties: {
        'sessionId': _currentSession!.id,
        'userId': _currentUserId,
      },
    );
  }

  // Get device information
  Map<String, dynamic> _getDeviceInfo() {
    return {
      'platform': 'Flutter',
      'version': '1.0.0',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Track event
  void trackEvent(
    EventType type,
    String name, {
    Map<String, dynamic>? properties,
    String? userId,
  }) {
    if (!_isEnabled) return;
    
    final event = AnalyticsEvent(
      type: type,
      name: name,
      properties: properties ?? {},
      userId: userId ?? _currentUserId,
      sessionId: _currentSession?.id,
    );
    
    _events.add(event);
    _currentSession?.events.add(event.id);
    
    // Update event counts
    _eventCounts[type.name] = (_eventCounts[type.name] ?? 0) + 1;
    
    // Update user actions
    _userActions[name] = (_userActions[name] ?? 0) + 1;
    
    if (_isDebugMode) {
      debugPrint('[ANALYTICS] Event: $name (${type.name})');
    }
    
    notifyListeners();
    _saveEvents();
  }

  // Track screen view
  void trackScreenView(String screenName) {
    trackEvent(
      EventType.screenView,
      'Screen View',
      properties: {
        'screenName': screenName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track button click
  void trackButtonClick(String buttonName, {String? screenName}) {
    trackEvent(
      EventType.buttonClick,
      'Button Click',
      properties: {
        'buttonName': buttonName,
        'screenName': screenName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track battle events
  void trackBattleEvent(String eventName, Map<String, dynamic> battleData) {
    trackEvent(
      EventType.battleStart,
      eventName,
      properties: {
        ...battleData,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track quest completion
  void trackQuestComplete(String questName, int xpReward, List<String> itemRewards) {
    trackEvent(
      EventType.questComplete,
      'Quest Complete',
      properties: {
        'questName': questName,
        'xpReward': xpReward,
        'itemRewards': itemRewards,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track achievement unlock
  void trackAchievementUnlocked(String achievementName, String category, String rarity) {
    trackEvent(
      EventType.achievementUnlocked,
      'Achievement Unlocked',
      properties: {
        'achievementName': achievementName,
        'category': category,
        'rarity': rarity,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track level up
  void trackLevelUp(int oldLevel, int newLevel, int totalXp) {
    trackEvent(
      EventType.levelUp,
      'Level Up',
      properties: {
        'oldLevel': oldLevel,
        'newLevel': newLevel,
        'totalXp': totalXp,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track performance metrics
  void trackPerformanceMetrics(Map<String, dynamic> metrics) {
    _performanceMetrics.add({
      ...metrics,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // Keep only last 100 performance metrics
    if (_performanceMetrics.length > 100) {
      _performanceMetrics.removeAt(0);
    }
    
    trackEvent(
      EventType.performanceIssue,
      'Performance Metrics',
      properties: metrics,
    );
  }

  // Set user ID
  void setUserId(String userId) {
    _currentUserId = userId;
    if (_currentSession != null) {
      // _currentSession!.userId = userId; // Commented out - userId is final
    }
  }

  // End current session
  void endSession() {
    if (_currentSession != null) {
      _currentSession!.endTime = DateTime.now();
      
      trackEvent(
        EventType.appClose,
        'Session Ended',
        properties: {
          'sessionDuration': _currentSession!.duration.inSeconds,
          'eventsCount': _currentSession!.events.length,
        },
      );
      
      _currentSession = null;
    }
  }

  // Get analytics summary
  Map<String, dynamic> getAnalyticsSummary() {
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    final last7Days = now.subtract(const Duration(days: 7));
    
    final recentEvents = _events.where((e) => e.timestamp.isAfter(last24Hours)).toList();
    final recentSessions = _sessions.where((s) => s.startTime.isAfter(last7Days)).toList();
    
    return {
      'totalEvents': _events.length,
      'totalSessions': _sessions.length,
      'eventsLast24Hours': recentEvents.length,
      'sessionsLast7Days': recentSessions.length,
      'averageSessionDuration': _calculateAverageSessionDuration(),
      'mostActiveHour': _calculateMostActiveHour(),
      'topEvents': _getTopEvents(5),
      'topScreens': _getTopScreens(5),
      'userEngagement': _calculateUserEngagement(),
      'performanceIssues': _performanceMetrics.length,
    };
  }

  // Calculate average session duration
  Duration _calculateAverageSessionDuration() {
    if (_sessions.isEmpty) return Duration.zero;
    
    final totalDuration = _sessions.fold<Duration>(
      Duration.zero,
      (total, session) => total + session.duration,
    );
    
    return Duration(seconds: totalDuration.inSeconds ~/ _sessions.length);
  }

  // Calculate most active hour
  int _calculateMostActiveHour() {
    final hourCounts = <int, int>{};
    
    for (final event in _events) {
      final hour = event.timestamp.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }
    
    if (hourCounts.isEmpty) return 0;
    
    return hourCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  // Get top events
  List<Map<String, dynamic>> _getTopEvents(int count) {
    final sortedEvents = _eventCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEvents.take(count).map((entry) => {
      'event': entry.key,
      'count': entry.value,
    }).toList();
  }

  // Get top screens
  List<Map<String, dynamic>> _getTopScreens(int count) {
    final screenCounts = <String, int>{};
    
    for (final event in _events) {
      if (event.type == EventType.screenView) {
        final screenName = event.properties['screenName'] as String?;
        if (screenName != null) {
          screenCounts[screenName] = (screenCounts[screenName] ?? 0) + 1;
        }
      }
    }
    
    final sortedScreens = screenCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedScreens.take(count).map((entry) => {
      'screen': entry.key,
      'views': entry.value,
    }).toList();
  }

  // Calculate user engagement
  Map<String, dynamic> _calculateUserEngagement() {
    final now = DateTime.now();
    final last7Days = now.subtract(const Duration(days: 7));
    final last30Days = now.subtract(const Duration(days: 30));
    
    final sessions7Days = _sessions.where((s) => s.startTime.isAfter(last7Days)).length;
    final sessions30Days = _sessions.where((s) => s.startTime.isAfter(last30Days)).length;
    
    return {
      'sessionsLast7Days': sessions7Days,
      'sessionsLast30Days': sessions30Days,
      'averageSessionsPerDay': sessions7Days / 7,
      'retentionRate': sessions30Days > 0 ? (sessions7Days / sessions30Days) * 100 : 0,
    };
  }

  // Get user segment
  UserSegment getUserSegment() {
    final sessionsLast30Days = _sessions.where((s) => 
      s.startTime.isAfter(DateTime.now().subtract(const Duration(days: 30)))
    ).length;
    
    if (sessionsLast30Days == 0) return UserSegment.newUser;
    if (sessionsLast30Days < 7) return UserSegment.casualPlayer;
    if (sessionsLast30Days < 21) return UserSegment.activePlayer;
    return UserSegment.hardcorePlayer;
  }

  // Enable/disable analytics
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('analytics_enabled', enabled);
    notifyListeners();
  }

  // Set debug mode
  Future<void> setDebugMode(bool debug) async {
    _isDebugMode = debug;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('analytics_debug', debug);
    notifyListeners();
  }

  // Clear analytics data
  Future<void> clearData() async {
    _events.clear();
    _sessions.clear();
    _eventCounts.clear();
    _screenTime.clear();
    _userActions.clear();
    _performanceMetrics.clear();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('analytics_events');
    await prefs.remove('analytics_sessions');
    
    notifyListeners();
  }

  // Save events to preferences
  Future<void> _saveEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = _events.map((event) => event.toJson()).toList();
      final sessionsJson = _sessions.map((session) => session.toJson()).toList();
      
      await prefs.setString('analytics_events', jsonEncode(eventsJson));
      await prefs.setString('analytics_sessions', jsonEncode(sessionsJson));
    } catch (e) {
      debugPrint('[ANALYTICS] Error saving events: $e');
    }
  }

  // Export analytics data
  Map<String, dynamic> exportData() {
    return {
      'events': _events.map((e) => e.toJson()).toList(),
      'sessions': _sessions.map((s) => s.toJson()).toList(),
      'summary': getAnalyticsSummary(),
      'performanceMetrics': _performanceMetrics,
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }
} 