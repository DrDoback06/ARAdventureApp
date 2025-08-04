import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/event_bus.dart';
import 'integration_orchestrator_agent.dart';

/// UI notification types
enum NotificationType {
  achievement,
  questComplete,
  questProgress,
  levelUp,
  itemGained,
  poiDiscovered,
  battleResult,
  fitnessGoal,
  arExperience,
  social,
  system,
}

/// UI notification priority
enum NotificationPriority {
  low,
  medium,
  high,
  critical,
}

/// UI Notification data structure
class UINotification {
  final String id;
  final NotificationType type;
  final NotificationPriority priority;
  final String title;
  final String message;
  final String? iconPath;
  final Color? backgroundColor;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final Duration? displayDuration;
  final bool persistent;
  final List<UIAction> actions;

  UINotification({
    String? id,
    required this.type,
    this.priority = NotificationPriority.medium,
    required this.title,
    required this.message,
    this.iconPath,
    this.backgroundColor,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    this.displayDuration,
    this.persistent = false,
    List<UIAction>? actions,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       data = data ?? {},
       timestamp = timestamp ?? DateTime.now(),
       actions = actions ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'priority': priority.toString(),
      'title': title,
      'message': message,
      'iconPath': iconPath,
      'backgroundColor': backgroundColor?.value,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'displayDuration': displayDuration?.inMilliseconds,
      'persistent': persistent,
      'actions': actions.map((a) => a.toJson()).toList(),
    };
  }

  factory UINotification.fromJson(Map<String, dynamic> json) {
    return UINotification(
      id: json['id'],
      type: NotificationType.values.firstWhere(
        (t) => t.toString() == json['type'],
        orElse: () => NotificationType.system,
      ),
      priority: NotificationPriority.values.firstWhere(
        (p) => p.toString() == json['priority'],
        orElse: () => NotificationPriority.medium,
      ),
      title: json['title'],
      message: json['message'],
      iconPath: json['iconPath'],
      backgroundColor: json['backgroundColor'] != null ? Color(json['backgroundColor']) : null,
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      timestamp: DateTime.parse(json['timestamp']),
      displayDuration: json['displayDuration'] != null ? Duration(milliseconds: json['displayDuration']) : null,
      persistent: json['persistent'] ?? false,
      actions: (json['actions'] as List? ?? []).map((a) => UIAction.fromJson(a)).toList(),
    );
  }
}

/// UI Action for notifications
class UIAction {
  final String id;
  final String label;
  final String eventType;
  final Map<String, dynamic> eventData;
  final IconData? icon;
  final Color? color;

  UIAction({
    required this.id,
    required this.label,
    required this.eventType,
    Map<String, dynamic>? eventData,
    this.icon,
    this.color,
  }) : eventData = eventData ?? {};

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'eventType': eventType,
      'eventData': eventData,
      'iconCodePoint': icon?.codePoint,
      'iconFontFamily': icon?.fontFamily,
      'color': color?.value,
    };
  }

  factory UIAction.fromJson(Map<String, dynamic> json) {
    return UIAction(
      id: json['id'],
      label: json['label'],
      eventType: json['eventType'],
      eventData: Map<String, dynamic>.from(json['eventData'] ?? {}),
      icon: json['iconCodePoint'] != null ? IconData(
        json['iconCodePoint'],
        fontFamily: json['iconFontFamily'],
      ) : null,
      color: json['color'] != null ? Color(json['color']) : null,
    );
  }
}

/// UI Theme configuration
class UIThemeConfig {
  final String themeName;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color accentColor;
  final Brightness brightness;
  final Map<String, dynamic> customColors;

  UIThemeConfig({
    required this.themeName,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.accentColor,
    this.brightness = Brightness.dark,
    Map<String, dynamic>? customColors,
  }) : customColors = customColors ?? {};

  Map<String, dynamic> toJson() {
    return {
      'themeName': themeName,
      'primaryColor': primaryColor.value,
      'secondaryColor': secondaryColor.value,
      'backgroundColor': backgroundColor.value,
      'surfaceColor': surfaceColor.value,
      'accentColor': accentColor.value,
      'brightness': brightness.toString(),
      'customColors': customColors,
    };
  }

  factory UIThemeConfig.fromJson(Map<String, dynamic> json) {
    return UIThemeConfig(
      themeName: json['themeName'],
      primaryColor: Color(json['primaryColor']),
      secondaryColor: Color(json['secondaryColor']),
      backgroundColor: Color(json['backgroundColor']),
      surfaceColor: Color(json['surfaceColor']),
      accentColor: Color(json['accentColor']),
      brightness: json['brightness'] == 'Brightness.light' ? Brightness.light : Brightness.dark,
      customColors: Map<String, dynamic>.from(json['customColors'] ?? {}),
    );
  }
}

/// UI State for dynamic interface management
class UIState {
  final String currentScreen;
  final Map<String, dynamic> screenData;
  final bool isLoading;
  final String? loadingMessage;
  final List<String> activeDialogs;
  final Map<String, dynamic> overlayData;

  UIState({
    this.currentScreen = 'dashboard',
    Map<String, dynamic>? screenData,
    this.isLoading = false,
    this.loadingMessage,
    List<String>? activeDialogs,
    Map<String, dynamic>? overlayData,
  }) : screenData = screenData ?? {},
       activeDialogs = activeDialogs ?? [],
       overlayData = overlayData ?? {};

  UIState copyWith({
    String? currentScreen,
    Map<String, dynamic>? screenData,
    bool? isLoading,
    String? loadingMessage,
    List<String>? activeDialogs,
    Map<String, dynamic>? overlayData,
  }) {
    return UIState(
      currentScreen: currentScreen ?? this.currentScreen,
      screenData: screenData ?? Map.from(this.screenData),
      isLoading: isLoading ?? this.isLoading,
      loadingMessage: loadingMessage ?? this.loadingMessage,
      activeDialogs: activeDialogs ?? List.from(this.activeDialogs),
      overlayData: overlayData ?? Map.from(this.overlayData),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentScreen': currentScreen,
      'screenData': screenData,
      'isLoading': isLoading,
      'loadingMessage': loadingMessage,
      'activeDialogs': activeDialogs,
      'overlayData': overlayData,
    };
  }

  factory UIState.fromJson(Map<String, dynamic> json) {
    return UIState(
      currentScreen: json['currentScreen'] ?? 'dashboard',
      screenData: Map<String, dynamic>.from(json['screenData'] ?? {}),
      isLoading: json['isLoading'] ?? false,
      loadingMessage: json['loadingMessage'],
      activeDialogs: List<String>.from(json['activeDialogs'] ?? []),
      overlayData: Map<String, dynamic>.from(json['overlayData'] ?? {}),
    );
  }
}

/// UI/UX Agent - Dynamic interface and notification management
class UIUXAgent extends BaseAgent {
  static const String agentId = 'ui_ux';

  final SharedPreferences _prefs;

  // Current user context
  String? _currentUserId;

  // UI State Management
  UIState _currentUIState = UIState();
  UIThemeConfig _currentTheme = _getDefaultTheme();

  // Notification Management
  final List<UINotification> _activeNotifications = [];
  final List<UINotification> _notificationHistory = [];
  Timer? _notificationCleanupTimer;

  // UI Analytics
  final Map<String, int> _screenVisitCounts = {};
  final Map<String, Duration> _screenTimeSpent = {};
  final Map<String, DateTime> _screenEnterTimes = {};

  // Dynamic UI Configuration
  final Map<String, Map<String, dynamic>> _dynamicWidgetConfigs = {};
  final Map<String, bool> _featureFlags = {};

  // Performance Monitoring
  final List<Map<String, dynamic>> _uiPerformanceMetrics = [];
  DateTime? _lastUIUpdate;

  UIUXAgent({
    required SharedPreferences prefs,
  }) : _prefs = prefs,
       super(agentId: agentId);

  @override
  Future<void> onInitialize() async {
    developer.log('Initializing UI/UX Agent', name: agentId);

    // Load UI configuration
    await _loadUIConfiguration();

    // Load theme settings
    await _loadThemeConfiguration();

    // Load user preferences
    await _loadUserPreferences();

    // Initialize feature flags
    _initializeFeatureFlags();

    // Start cleanup timer
    _startNotificationCleanup();

    developer.log('UI/UX Agent initialized with theme: ${_currentTheme.themeName}', name: agentId);
  }

  @override
  void subscribeToEvents() {
    // Character events
    subscribe(EventTypes.characterUpdated, _handleCharacterUpdate);
    subscribe(EventTypes.characterLevelUp, _handleLevelUp);
    subscribe(EventTypes.characterStatsChanged, _handleStatsChanged);

    // Quest events
    subscribe(EventTypes.questStarted, _handleQuestStarted);
    subscribe(EventTypes.questCompleted, _handleQuestCompleted);
    subscribe(EventTypes.questFailed, _handleQuestFailed);
    subscribe(EventTypes.questProgress, _handleQuestProgress);

    // Battle events
    subscribe(EventTypes.battleStarted, _handleBattleStarted);
    subscribe(EventTypes.battleEnded, _handleBattleEnded);
    subscribe(EventTypes.battleResult, _handleBattleResult);

    // Card events
    subscribe(EventTypes.cardScanned, _handleCardScanned);
    subscribe(EventTypes.inventoryChanged, _handleInventoryChanged);

    // Location events
    subscribe(EventTypes.locationUpdate, _handleLocationUpdate);
    subscribe(EventTypes.poiDetected, _handlePOIDetected);
    subscribe(EventTypes.geofenceEntered, _handleGeofenceEntered);

    // Fitness events
    subscribe(EventTypes.fitnessUpdate, _handleFitnessUpdate);
    subscribe(EventTypes.fitnessGoalReached, _handleFitnessGoalReached);

    // Achievement events
    subscribe(EventTypes.achievementUnlocked, _handleAchievementUnlocked);

    // AR events
    subscribe(EventTypes.arExperienceTriggered, _handleARExperience);

    // System events
    subscribe(EventTypes.systemError, _handleSystemError);
    subscribe(EventTypes.systemWarning, _handleSystemWarning);

    // UI-specific events
    subscribe('ui_screen_changed', _handleScreenChanged);
    subscribe('ui_theme_changed', _handleThemeChanged);
    subscribe('ui_notification_action', _handleNotificationAction);
    subscribe('ui_widget_config_changed', _handleWidgetConfigChanged);

    // User management
    subscribe('user_login', _handleUserLogin);
    subscribe('user_logout', _handleUserLogout);
  }

  /// Show notification to user
  String showNotification({
    required NotificationType type,
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.medium,
    String? iconPath,
    Color? backgroundColor,
    Duration? displayDuration,
    bool persistent = false,
    List<UIAction>? actions,
    Map<String, dynamic>? data,
  }) {
    final notification = UINotification(
      type: type,
      priority: priority,
      title: title,
      message: message,
      iconPath: iconPath,
      backgroundColor: backgroundColor ?? _getNotificationColor(type),
      displayDuration: displayDuration ?? _getDefaultDuration(priority),
      persistent: persistent,
      actions: actions ?? [],
      data: data,
    );

    _activeNotifications.add(notification);
    _notificationHistory.add(notification);

    // Sort notifications by priority
    _activeNotifications.sort((a, b) => b.priority.index.compareTo(a.priority.index));

    // Publish UI notification event
    publishEvent(createEvent(
      eventType: EventTypes.uiNotification,
      data: {
        'notificationId': notification.id,
        'type': type.toString(),
        'priority': priority.toString(),
        'title': title,
        'message': message,
        'notification': notification.toJson(),
      },
      priority: _getEventPriority(priority),
    ));

    _logUIMetric('notification_shown', {
      'type': type.toString(),
      'priority': priority.toString(),
      'persistent': persistent,
    });

    // Auto-remove non-persistent notifications
    if (!persistent && displayDuration != null) {
      Timer(displayDuration, () => dismissNotification(notification.id));
    }

    developer.log('Notification shown: $title', name: agentId);
    return notification.id;
  }

  /// Dismiss notification
  bool dismissNotification(String notificationId) {
    final removed = _activeNotifications.removeWhere((n) => n.id == notificationId);
    
    if (removed > 0) {
      publishEvent(createEvent(
        eventType: 'ui_notification_dismissed',
        data: {'notificationId': notificationId},
      ));

      _logUIMetric('notification_dismissed', {'notificationId': notificationId});
      return true;
    }
    return false;
  }

  /// Update UI state
  void updateUIState({
    String? currentScreen,
    Map<String, dynamic>? screenData,
    bool? isLoading,
    String? loadingMessage,
    List<String>? activeDialogs,
    Map<String, dynamic>? overlayData,
  }) {
    final previousScreen = _currentUIState.currentScreen;
    
    _currentUIState = _currentUIState.copyWith(
      currentScreen: currentScreen,
      screenData: screenData,
      isLoading: isLoading,
      loadingMessage: loadingMessage,
      activeDialogs: activeDialogs,
      overlayData: overlayData,
    );

    // Track screen analytics
    if (currentScreen != null && currentScreen != previousScreen) {
      _trackScreenTransition(previousScreen, currentScreen);
    }

    // Publish UI state change
    publishEvent(createEvent(
      eventType: EventTypes.uiWindowOpened,
      data: {
        'previousScreen': previousScreen,
        'currentScreen': _currentUIState.currentScreen,
        'uiState': _currentUIState.toJson(),
      },
    ));

    _lastUIUpdate = DateTime.now();
  }

  /// Change theme
  void changeTheme(UIThemeConfig newTheme) {
    final previousTheme = _currentTheme.themeName;
    _currentTheme = newTheme;

    publishEvent(createEvent(
      eventType: 'ui_theme_changed',
      data: {
        'previousTheme': previousTheme,
        'newTheme': newTheme.themeName,
        'themeConfig': newTheme.toJson(),
      },
    ));

    _logUIMetric('theme_changed', {
      'previousTheme': previousTheme,
      'newTheme': newTheme.themeName,
    });

    _saveThemeConfiguration();
  }

  /// Configure dynamic widget
  void configureWidget(String widgetId, Map<String, dynamic> config) {
    _dynamicWidgetConfigs[widgetId] = config;

    publishEvent(createEvent(
      eventType: 'ui_widget_config_changed',
      data: {
        'widgetId': widgetId,
        'config': config,
      },
    ));

    _saveUIConfiguration();
  }

  /// Get widget configuration
  Map<String, dynamic> getWidgetConfig(String widgetId) {
    return Map.from(_dynamicWidgetConfigs[widgetId] ?? {});
  }

  /// Set feature flag
  void setFeatureFlag(String feature, bool enabled) {
    _featureFlags[feature] = enabled;

    publishEvent(createEvent(
      eventType: 'ui_feature_flag_changed',
      data: {
        'feature': feature,
        'enabled': enabled,
      },
    ));

    _saveUIConfiguration();
  }

  /// Check feature flag
  bool isFeatureEnabled(String feature) {
    return _featureFlags[feature] ?? false;
  }

  /// Get UI analytics
  Map<String, dynamic> getUIAnalytics() {
    final totalScreenTime = _screenTimeSpent.values.fold(Duration.zero, (sum, duration) => sum + duration);
    
    return {
      'screenVisitCounts': _screenVisitCounts,
      'screenTimeSpent': _screenTimeSpent.map((k, v) => MapEntry(k, v.inSeconds)),
      'totalScreenTime': totalScreenTime.inSeconds,
      'activeNotifications': _activeNotifications.length,
      'notificationHistory': _notificationHistory.length,
      'currentTheme': _currentTheme.themeName,
      'featureFlags': _featureFlags,
      'lastUIUpdate': _lastUIUpdate?.toIso8601String(),
    };
  }

  /// Track screen transition
  void _trackScreenTransition(String fromScreen, String toScreen) {
    final now = DateTime.now();
    
    // Record exit time for previous screen
    final enterTime = _screenEnterTimes[fromScreen];
    if (enterTime != null) {
      final timeSpent = now.difference(enterTime);
      _screenTimeSpent[fromScreen] = (_screenTimeSpent[fromScreen] ?? Duration.zero) + timeSpent;
    }

    // Record visit count and enter time for new screen
    _screenVisitCounts[toScreen] = (_screenVisitCounts[toScreen] ?? 0) + 1;
    _screenEnterTimes[toScreen] = now;

    _logUIMetric('screen_transition', {
      'fromScreen': fromScreen,
      'toScreen': toScreen,
      'timestamp': now.toIso8601String(),
    });
  }

  /// Initialize feature flags
  void _initializeFeatureFlags() {
    _featureFlags.addAll({
      'dark_mode': true,
      'notifications_enabled': true,
      'analytics_enabled': true,
      'ar_features': true,
      'location_features': true,
      'social_features': false, // Not yet implemented
      'advanced_ui': true,
      'debug_mode': false,
    });
  }

  /// Get default theme
  static UIThemeConfig _getDefaultTheme() {
    return UIThemeConfig(
      themeName: 'dark_whimsical',
      primaryColor: const Color(0xFF6366F1),
      secondaryColor: const Color(0xFF8B5CF6),
      backgroundColor: const Color(0xFF0F172A),
      surfaceColor: const Color(0xFF1E293B),
      accentColor: const Color(0xFFF59E0B),
      brightness: Brightness.dark,
      customColors: {
        'questColor': 0xFF10B981,
        'battleColor': 0xFFEF4444,
        'achievementColor': 0xFFF59E0B,
        'arColor': 0xFF8B5CF6,
        'fitnessColor': 0xFF06B6D4,
      },
    );
  }

  /// Get notification color based on type
  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.achievement:
        return const Color(0xFFF59E0B);
      case NotificationType.questComplete:
        return const Color(0xFF10B981);
      case NotificationType.levelUp:
        return const Color(0xFF8B5CF6);
      case NotificationType.battleResult:
        return const Color(0xFFEF4444);
      case NotificationType.arExperience:
        return const Color(0xFF8B5CF6);
      case NotificationType.fitnessGoal:
        return const Color(0xFF06B6D4);
      default:
        return _currentTheme.primaryColor;
    }
  }

  /// Get default display duration based on priority
  Duration _getDefaultDuration(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return const Duration(seconds: 3);
      case NotificationPriority.medium:
        return const Duration(seconds: 5);
      case NotificationPriority.high:
        return const Duration(seconds: 8);
      case NotificationPriority.critical:
        return const Duration(seconds: 10);
    }
  }

  /// Convert notification priority to event priority
  EventPriority _getEventPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return EventPriority.low;
      case NotificationPriority.medium:
        return EventPriority.normal;
      case NotificationPriority.high:
        return EventPriority.high;
      case NotificationPriority.critical:
        return EventPriority.critical;
    }
  }

  /// Start notification cleanup timer
  void _startNotificationCleanup() {
    _notificationCleanupTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final now = DateTime.now();
      
      // Remove expired non-persistent notifications
      _activeNotifications.removeWhere((notification) {
        if (notification.persistent) return false;
        if (notification.displayDuration == null) return false;
        
        final expiry = notification.timestamp.add(notification.displayDuration!);
        return now.isAfter(expiry);
      });

      // Limit notification history to last 100
      if (_notificationHistory.length > 100) {
        _notificationHistory.removeRange(0, _notificationHistory.length - 100);
      }
    });
  }

  /// Log UI metric
  void _logUIMetric(String metricType, Map<String, dynamic> data) {
    _uiPerformanceMetrics.add({
      'metricType': metricType,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Keep only last 50 metrics
    if (_uiPerformanceMetrics.length > 50) {
      _uiPerformanceMetrics.removeAt(0);
    }
  }

  /// Load UI configuration
  Future<void> _loadUIConfiguration() async {
    final configJson = _prefs.getString('ui_configuration');
    if (configJson != null) {
      try {
        final data = jsonDecode(configJson) as Map<String, dynamic>;
        
        if (data['widgetConfigs'] != null) {
          _dynamicWidgetConfigs.addAll(
            Map<String, Map<String, dynamic>>.from(data['widgetConfigs']),
          );
        }

        if (data['featureFlags'] != null) {
          _featureFlags.addAll(Map<String, bool>.from(data['featureFlags']));
        }

        if (data['uiState'] != null) {
          _currentUIState = UIState.fromJson(data['uiState']);
        }
      } catch (e) {
        developer.log('Error loading UI configuration: $e', name: agentId);
      }
    }
  }

  /// Save UI configuration
  Future<void> _saveUIConfiguration() async {
    final data = {
      'widgetConfigs': _dynamicWidgetConfigs,
      'featureFlags': _featureFlags,
      'uiState': _currentUIState.toJson(),
    };
    await _prefs.setString('ui_configuration', jsonEncode(data));
  }

  /// Load theme configuration
  Future<void> _loadThemeConfiguration() async {
    final themeJson = _prefs.getString('ui_theme');
    if (themeJson != null) {
      try {
        final data = jsonDecode(themeJson) as Map<String, dynamic>;
        _currentTheme = UIThemeConfig.fromJson(data);
      } catch (e) {
        developer.log('Error loading theme configuration: $e', name: agentId);
      }
    }
  }

  /// Save theme configuration
  Future<void> _saveThemeConfiguration() async {
    await _prefs.setString('ui_theme', jsonEncode(_currentTheme.toJson()));
  }

  /// Load user preferences
  Future<void> _loadUserPreferences() async {
    final prefsJson = _prefs.getString('ui_user_preferences');
    if (prefsJson != null) {
      try {
        final data = jsonDecode(prefsJson) as Map<String, dynamic>;
        
        if (data['screenVisitCounts'] != null) {
          _screenVisitCounts.addAll(Map<String, int>.from(data['screenVisitCounts']));
        }

        if (data['screenTimeSpent'] != null) {
          final timeData = Map<String, int>.from(data['screenTimeSpent']);
          for (final entry in timeData.entries) {
            _screenTimeSpent[entry.key] = Duration(seconds: entry.value);
          }
        }
      } catch (e) {
        developer.log('Error loading user preferences: $e', name: agentId);
      }
    }
  }

  /// Save user preferences
  Future<void> _saveUserPreferences() async {
    final data = {
      'screenVisitCounts': _screenVisitCounts,
      'screenTimeSpent': _screenTimeSpent.map((k, v) => MapEntry(k, v.inSeconds)),
    };
    await _prefs.setString('ui_user_preferences', jsonEncode(data));
  }

  // Event Handlers

  /// Handle character update events
  Future<AgentEventResponse?> _handleCharacterUpdate(AgentEvent event) async {
    updateUIState(
      screenData: {
        ..._currentUIState.screenData,
        'characterData': event.data,
        'lastCharacterUpdate': DateTime.now().toIso8601String(),
      },
    );

    return createResponse(
      originalEventId: event.id,
      responseType: 'character_update_ui_processed',
      data: {'processed': true},
    );
  }

  /// Handle level up events
  Future<AgentEventResponse?> _handleLevelUp(AgentEvent event) async {
    final level = event.data['newLevel'] ?? 0;
    final characterName = event.data['characterName'] ?? 'Character';

    showNotification(
      type: NotificationType.levelUp,
      title: 'Level Up!',
      message: '$characterName reached level $level!',
      priority: NotificationPriority.high,
      persistent: false,
      actions: [
        UIAction(
          id: 'view_character',
          label: 'View Character',
          eventType: 'ui_screen_changed',
          eventData: {'screen': 'character'},
          icon: Icons.person,
        ),
      ],
    );

    return createResponse(
      originalEventId: event.id,
      responseType: 'level_up_notification_shown',
      data: {'level': level},
    );
  }

  /// Handle stats changed events
  Future<AgentEventResponse?> _handleStatsChanged(AgentEvent event) async {
    updateUIState(
      overlayData: {
        ..._currentUIState.overlayData,
        'statChanges': event.data,
        'showStatAnimation': true,
      },
    );

    // Auto-hide stat animation after 3 seconds
    Timer(const Duration(seconds: 3), () {
      updateUIState(
        overlayData: {
          ..._currentUIState.overlayData,
          'showStatAnimation': false,
        },
      );
    });

    return createResponse(
      originalEventId: event.id,
      responseType: 'stats_ui_updated',
      data: {'animated': true},
    );
  }

  /// Handle quest started events
  Future<AgentEventResponse?> _handleQuestStarted(AgentEvent event) async {
    final questName = event.data['questName'] ?? 'New Quest';

    showNotification(
      type: NotificationType.questProgress,
      title: 'Quest Started',
      message: 'You started: $questName',
      priority: NotificationPriority.medium,
      actions: [
        UIAction(
          id: 'view_quest',
          label: 'View Quest',
          eventType: 'ui_screen_changed',
          eventData: {'screen': 'quests'},
          icon: Icons.map,
        ),
      ],
    );

    return createResponse(
      originalEventId: event.id,
      responseType: 'quest_start_notification_shown',
      data: {'questName': questName},
    );
  }

  /// Handle quest completed events
  Future<AgentEventResponse?> _handleQuestCompleted(AgentEvent event) async {
    final questName = event.data['questName'] ?? 'Quest';
    final xpReward = event.data['experienceReward'] ?? 0;
    final goldReward = event.data['goldReward'] ?? 0;

    showNotification(
      type: NotificationType.questComplete,
      title: 'Quest Complete!',
      message: '$questName completed! Gained $xpReward XP and $goldReward gold.',
      priority: NotificationPriority.high,
      persistent: false,
      actions: [
        UIAction(
          id: 'view_rewards',
          label: 'View Rewards',
          eventType: 'ui_screen_changed',
          eventData: {'screen': 'inventory'},
          icon: Icons.card_giftcard,
        ),
      ],
    );

    return createResponse(
      originalEventId: event.id,
      responseType: 'quest_complete_notification_shown',
      data: {'questName': questName, 'xpReward': xpReward, 'goldReward': goldReward},
    );
  }

  /// Handle quest failed events
  Future<AgentEventResponse?> _handleQuestFailed(AgentEvent event) async {
    final questName = event.data['questName'] ?? 'Quest';
    final reason = event.data['reason'] ?? 'unknown';

    showNotification(
      type: NotificationType.questProgress,
      title: 'Quest Failed',
      message: '$questName failed: $reason',
      priority: NotificationPriority.medium,
      backgroundColor: Colors.red.shade800,
    );

    return createResponse(
      originalEventId: event.id,
      responseType: 'quest_failed_notification_shown',
      data: {'questName': questName, 'reason': reason},
    );
  }

  /// Handle quest progress events
  Future<AgentEventResponse?> _handleQuestProgress(AgentEvent event) async {
    final progress = event.data['progress'] ?? 0.0;
    
    updateUIState(
      overlayData: {
        ..._currentUIState.overlayData,
        'questProgress': progress,
        'showQuestProgress': true,
      },
    );

    return createResponse(
      originalEventId: event.id,
      responseType: 'quest_progress_ui_updated',
      data: {'progress': progress},
    );
  }

  /// Handle battle started events
  Future<AgentEventResponse?> _handleBattleStarted(AgentEvent event) async {
    updateUIState(
      currentScreen: 'battle',
      screenData: {
        'battleData': event.data,
        'battleStartTime': DateTime.now().toIso8601String(),
      },
      overlayData: {
        ..._currentUIState.overlayData,
        'inBattle': true,
      },
    );

    return createResponse(
      originalEventId: event.id,
      responseType: 'battle_ui_activated',
      data: {'battleStarted': true},
    );
  }

  /// Handle battle ended events
  Future<AgentEventResponse?> _handleBattleEnded(AgentEvent event) async {
    updateUIState(
      overlayData: {
        ..._currentUIState.overlayData,
        'inBattle': false,
        'battleResult': event.data,
      },
    );

    return createResponse(
      originalEventId: event.id,
      responseType: 'battle_ui_deactivated',
      data: {'battleEnded': true},
    );
  }

  /// Handle battle result events
  Future<AgentEventResponse?> _handleBattleResult(AgentEvent event) async {
    final isVictory = event.data['isVictory'] ?? false;
    final xpGained = event.data['xpGained'] ?? 0;

    showNotification(
      type: NotificationType.battleResult,
      title: isVictory ? 'Victory!' : 'Defeat',
      message: isVictory 
          ? 'You won the battle and gained $xpGained XP!'
          : 'You were defeated in battle.',
      priority: NotificationPriority.high,
      backgroundColor: isVictory ? Colors.green.shade800 : Colors.red.shade800,
      actions: isVictory ? [
        UIAction(
          id: 'view_rewards',
          label: 'View Rewards',
          eventType: 'ui_screen_changed',
          eventData: {'screen': 'inventory'},
          icon: Icons.card_giftcard,
        ),
      ] : null,
    );

    return createResponse(
      originalEventId: event.id,
      responseType: 'battle_result_notification_shown',
      data: {'isVictory': isVictory, 'xpGained': xpGained},
    );
  }

  /// Handle card scanned events
  Future<AgentEventResponse?> _handleCardScanned(AgentEvent event) async {
    showNotification(
      type: NotificationType.itemGained,
      title: 'Card Scanned',
      message: 'Successfully scanned a new card!',
      priority: NotificationPriority.medium,
      actions: [
        UIAction(
          id: 'view_inventory',
          label: 'View Inventory',
          eventType: 'ui_screen_changed',
          eventData: {'screen': 'inventory'},
          icon: Icons.inventory,
        ),
      ],
    );

    return createResponse(
      originalEventId: event.id,
      responseType: 'card_scan_notification_shown',
      data: {'processed': true},
    );
  }

  /// Handle inventory changed events
  Future<AgentEventResponse?> _handleInventoryChanged(AgentEvent event) async {
    final itemsGained = event.data['itemsGained'] ?? [];
    
    if (itemsGained.isNotEmpty) {
      showNotification(
        type: NotificationType.itemGained,
        title: 'Items Gained',
        message: 'You gained ${itemsGained.length} new item(s)!',
        priority: NotificationPriority.medium,
      );
    }

    updateUIState(
      screenData: {
        ..._currentUIState.screenData,
        'inventoryUpdate': event.data,
        'lastInventoryUpdate': DateTime.now().toIso8601String(),
      },
    );

    return createResponse(
      originalEventId: event.id,
      responseType: 'inventory_ui_updated',
      data: {'itemsGained': itemsGained.length},
    );
  }

  /// Handle location update events
  Future<AgentEventResponse?> _handleLocationUpdate(AgentEvent event) async {
    updateUIState(
      screenData: {
        ..._currentUIState.screenData,
        'locationData': event.data,
        'lastLocationUpdate': DateTime.now().toIso8601String(),
      },
    );

    return createResponse(
      originalEventId: event.id,
      responseType: 'location_ui_updated',
      data: {'processed': true},
    );
  }

  /// Handle POI detected events
  Future<AgentEventResponse?> _handlePOIDetected(AgentEvent event) async {
    final poiName = event.data['poi']?['name'] ?? 'Point of Interest';
    final distance = event.data['distance'] ?? 0;

    showNotification(
      type: NotificationType.poiDiscovered,
      title: 'Location Discovered!',
      message: '$poiName is ${distance.round()}m away',
      priority: NotificationPriority.medium,
      actions: [
        UIAction(
          id: 'view_map',
          label: 'View Map',
          eventType: 'ui_screen_changed',
          eventData: {'screen': 'map'},
          icon: Icons.map,
        ),
        UIAction(
          id: 'visit_poi',
          label: 'Visit',
          eventType: 'visit_poi',
          eventData: {'poiId': event.data['poiId']},
          icon: Icons.location_on,
        ),
      ],
    );

    return createResponse(
      originalEventId: event.id,
      responseType: 'poi_notification_shown',
      data: {'poiName': poiName, 'distance': distance},
    );
  }

  /// Handle geofence entered events
  Future<AgentEventResponse?> _handleGeofenceEntered(AgentEvent event) async {
    final geofenceName = event.data['geofenceName'] ?? 'Area';

    showNotification(
      type: NotificationType.poiDiscovered,
      title: 'Area Entered',
      message: 'You entered $geofenceName',
      priority: NotificationPriority.medium,
    );

    return createResponse(
      originalEventId: event.id,
      responseType: 'geofence_notification_shown',
      data: {'geofenceName': geofenceName},
    );
  }

  /// Handle fitness update events
  Future<AgentEventResponse?> _handleFitnessUpdate(AgentEvent event) async {
    updateUIState(
      screenData: {
        ..._currentUIState.screenData,
        'fitnessData': event.data,
        'lastFitnessUpdate': DateTime.now().toIso8601String(),
      },
    );

    return createResponse(
      originalEventId: event.id,
      responseType: 'fitness_ui_updated',
      data: {'processed': true},
    );
  }

  /// Handle fitness goal reached events
  Future<AgentEventResponse?> _handleFitnessGoalReached(AgentEvent event) async {
    final goalType = event.data['goalType'] ?? 'fitness goal';
    final value = event.data['value'] ?? 0;

    showNotification(
      type: NotificationType.fitnessGoal,
      title: 'Fitness Goal Reached!',
      message: 'You achieved your $goalType: $value',
      priority: NotificationPriority.high,
      backgroundColor: const Color(0xFF06B6D4),
    );

    return createResponse(
      originalEventId: event.id,
      responseType: 'fitness_goal_notification_shown',
      data: {'goalType': goalType, 'value': value},
    );
  }

  /// Handle achievement unlocked events
  Future<AgentEventResponse?> _handleAchievementUnlocked(AgentEvent event) async {
    final achievementName = event.data['name'] ?? 'Achievement';
    final rarity = event.data['rarity'] ?? 'common';

    showNotification(
      type: NotificationType.achievement,
      title: 'Achievement Unlocked!',
      message: '$achievementName ($rarity)',
      priority: NotificationPriority.high,
      persistent: false,
      actions: [
        UIAction(
          id: 'view_achievements',
          label: 'View Achievements',
          eventType: 'ui_screen_changed',
          eventData: {'screen': 'achievements'},
          icon: Icons.emoji_events,
        ),
      ],
    );

    return createResponse(
      originalEventId: event.id,
      responseType: 'achievement_notification_shown',
      data: {'achievementName': achievementName, 'rarity': rarity},
    );
  }

  /// Handle AR experience events
  Future<AgentEventResponse?> _handleARExperience(AgentEvent event) async {
    final experienceType = event.data['type'] ?? 'AR Experience';

    showNotification(
      type: NotificationType.arExperience,
      title: 'AR Experience Available',
      message: '$experienceType is ready to explore!',
      priority: NotificationPriority.high,
      backgroundColor: const Color(0xFF8B5CF6),
      actions: [
        UIAction(
          id: 'start_ar',
          label: 'Start AR',
          eventType: 'trigger_ar_experience',
          eventData: {'experienceId': event.data['experienceId']},
          icon: Icons.view_in_ar,
        ),
      ],
    );

    return createResponse(
      originalEventId: event.id,
      responseType: 'ar_experience_notification_shown',
      data: {'experienceType': experienceType},
    );
  }

  /// Handle system error events
  Future<AgentEventResponse?> _handleSystemError(AgentEvent event) async {
    final error = event.data['error'] ?? 'System error occurred';

    showNotification(
      type: NotificationType.system,
      title: 'System Error',
      message: error,
      priority: NotificationPriority.critical,
      backgroundColor: Colors.red.shade900,
      persistent: true,
    );

    return createResponse(
      originalEventId: event.id,
      responseType: 'system_error_notification_shown',
      data: {'error': error},
    );
  }

  /// Handle system warning events
  Future<AgentEventResponse?> _handleSystemWarning(AgentEvent event) async {
    final warning = event.data['warning'] ?? 'System warning';

    showNotification(
      type: NotificationType.system,
      title: 'Warning',
      message: warning,
      priority: NotificationPriority.medium,
      backgroundColor: Colors.orange.shade800,
    );

    return createResponse(
      originalEventId: event.id,
      responseType: 'system_warning_notification_shown',
      data: {'warning': warning},
    );
  }

  /// Handle screen changed events
  Future<AgentEventResponse?> _handleScreenChanged(AgentEvent event) async {
    final newScreen = event.data['screen'];
    
    if (newScreen != null) {
      updateUIState(currentScreen: newScreen);
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'screen_changed',
      data: {'newScreen': newScreen},
    );
  }

  /// Handle theme changed events
  Future<AgentEventResponse?> _handleThemeChanged(AgentEvent event) async {
    final themeName = event.data['themeName'];
    
    if (themeName != null) {
      // Load theme configuration if needed
      await _loadThemeConfiguration();
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'theme_changed',
      data: {'themeName': themeName},
    );
  }

  /// Handle notification action events
  Future<AgentEventResponse?> _handleNotificationAction(AgentEvent event) async {
    final notificationId = event.data['notificationId'];
    final actionId = event.data['actionId'];

    // Find the notification and action
    final notification = _activeNotifications.firstWhere(
      (n) => n.id == notificationId,
      orElse: () => UINotification(type: NotificationType.system, title: '', message: ''),
    );

    if (notification.id.isNotEmpty) {
      final action = notification.actions.firstWhere(
        (a) => a.id == actionId,
        orElse: () => UIAction(id: '', label: '', eventType: ''),
      );

      if (action.id.isNotEmpty) {
        // Execute the action by publishing its event
        await publishEvent(createEvent(
          eventType: action.eventType,
          data: action.eventData,
        ));

        // Dismiss the notification if it's not persistent
        if (!notification.persistent) {
          dismissNotification(notificationId);
        }
      }
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'notification_action_executed',
      data: {'notificationId': notificationId, 'actionId': actionId},
    );
  }

  /// Handle widget config changed events
  Future<AgentEventResponse?> _handleWidgetConfigChanged(AgentEvent event) async {
    final widgetId = event.data['widgetId'];
    final config = event.data['config'];

    if (widgetId != null && config != null) {
      configureWidget(widgetId, Map<String, dynamic>.from(config));
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'widget_config_changed',
      data: {'widgetId': widgetId},
    );
  }

  /// Handle user login events
  Future<AgentEventResponse?> _handleUserLogin(AgentEvent event) async {
    final userId = event.data['userId'];
    _currentUserId = userId;

    // Reset UI state for new user
    updateUIState(
      currentScreen: 'dashboard',
      screenData: {},
      isLoading: false,
      activeDialogs: [],
      overlayData: {},
    );

    // Clear active notifications
    _activeNotifications.clear();

    // Welcome notification
    if (userId != null) {
      showNotification(
        type: NotificationType.system,
        title: 'Welcome Back!',
        message: 'Ready for your next adventure?',
        priority: NotificationPriority.medium,
      );
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'user_login_ui_processed',
      data: {'userId': userId},
    );
  }

  /// Handle user logout events
  Future<AgentEventResponse?> _handleUserLogout(AgentEvent event) async {
    // Save user preferences
    await _saveUserPreferences();
    await _saveUIConfiguration();

    // Clear user data
    _currentUserId = null;
    _activeNotifications.clear();

    // Reset to login screen
    updateUIState(
      currentScreen: 'login',
      screenData: {},
      isLoading: false,
      activeDialogs: [],
      overlayData: {},
    );

    return createResponse(
      originalEventId: event.id,
      responseType: 'user_logout_ui_processed',
      data: {'loggedOut': true},
    );
  }

  @override
  Future<void> onDispose() async {
    // Cancel timers
    _notificationCleanupTimer?.cancel();

    // Save all data
    await _saveUIConfiguration();
    await _saveThemeConfiguration();
    await _saveUserPreferences();

    developer.log('UI/UX Agent disposed', name: agentId);
  }
}