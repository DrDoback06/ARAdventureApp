import 'dart:async';
import 'dart:developer' as developer;

/// Priority levels for events
enum EventPriority {
  critical(1, 100), // Must respond within 100ms
  high(2, 1000),    // Must respond within 1 second
  medium(3, 5000),  // Must respond within 5 seconds
  low(4, -1);       // No immediate response required

  const EventPriority(this.level, this.timeoutMs);
  final int level;
  final int timeoutMs;
}

/// Base class for all agent events
class AgentEvent {
  final String id;
  final String sourceAgent;
  final String? targetAgent; // null for broadcast
  final String eventType;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final EventPriority priority;
  final bool requiresResponse;
  final String? correlationId;

  AgentEvent({
    required this.id,
    required this.sourceAgent,
    this.targetAgent,
    required this.eventType,
    required this.data,
    DateTime? timestamp,
    this.priority = EventPriority.medium,
    this.requiresResponse = false,
    this.correlationId,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'AgentEvent{id: $id, source: $sourceAgent, target: $targetAgent, '
           'type: $eventType, priority: $priority, requiresResponse: $requiresResponse}';
  }
}

/// Response to an agent event
class AgentEventResponse {
  final String originalEventId;
  final String sourceAgent;
  final String responseType;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool success;
  final String? error;

  AgentEventResponse({
    required this.originalEventId,
    required this.sourceAgent,
    required this.responseType,
    required this.data,
    DateTime? timestamp,
    this.success = true,
    this.error,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Event handler callback type
typedef EventHandler = Future<AgentEventResponse?> Function(AgentEvent event);

/// Subscription to events
class EventSubscription {
  final String id;
  final String agentId;
  final String eventType;
  final EventHandler handler;
  final bool isGlobal; // if true, receives all events regardless of target

  EventSubscription({
    required this.id,
    required this.agentId,
    required this.eventType,
    required this.handler,
    this.isGlobal = false,
  });
}

/// Central event bus for agent communication
class EventBus {
  static final EventBus _instance = EventBus._internal();
  factory EventBus() => _instance;
  EventBus._internal();

  final Map<String, List<EventSubscription>> _subscriptions = {};
  final Map<String, Completer<AgentEventResponse>> _pendingResponses = {};
  final List<AgentEvent> _eventHistory = [];
  final StreamController<AgentEvent> _eventStreamController = 
      StreamController<AgentEvent>.broadcast();

  /// Get stream of all events (for debugging/monitoring)
  Stream<AgentEvent> get eventStream => _eventStreamController.stream;

  /// Subscribe to specific event types
  String subscribe({
    required String agentId,
    required String eventType,
    required EventHandler handler,
    bool isGlobal = false,
  }) {
    final subscriptionId = DateTime.now().millisecondsSinceEpoch.toString() + 
                          '_' + agentId;
    
    final subscription = EventSubscription(
      id: subscriptionId,
      agentId: agentId,
      eventType: eventType,
      handler: handler,
      isGlobal: isGlobal,
    );

    _subscriptions.putIfAbsent(eventType, () => []).add(subscription);
    
    developer.log(
      'Agent $agentId subscribed to $eventType events',
      name: 'EventBus',
    );

    return subscriptionId;
  }

  /// Unsubscribe from events
  void unsubscribe(String subscriptionId) {
    _subscriptions.forEach((eventType, subscriptions) {
      subscriptions.removeWhere((sub) => sub.id == subscriptionId);
    });
  }

  /// Publish an event
  Future<void> publish(AgentEvent event) async {
    _eventHistory.add(event);
    _eventStreamController.add(event);

    developer.log(
      'Publishing event: ${event.eventType} from ${event.sourceAgent}',
      name: 'EventBus',
    );

    // Get relevant subscriptions
    final subscriptions = _getRelevantSubscriptions(event);

    // Process subscriptions based on priority
    if (event.priority == EventPriority.critical) {
      await _processCriticalEvent(event, subscriptions);
    } else {
      _processNormalEvent(event, subscriptions);
    }
  }

  /// Send event and wait for response
  Future<AgentEventResponse?> publishAndWaitForResponse(
    AgentEvent event, {
    Duration? timeout,
  }) async {
    if (!event.requiresResponse) {
      throw ArgumentError('Event must require response to wait for one');
    }

    final completer = Completer<AgentEventResponse>();
    _pendingResponses[event.id] = completer;

    // Set up timeout based on priority
    final timeoutDuration = timeout ?? 
      (event.priority.timeoutMs > 0 
        ? Duration(milliseconds: event.priority.timeoutMs)
        : const Duration(seconds: 30));

    // Publish the event
    await publish(event);

    // Wait for response with timeout
    try {
      return await completer.future.timeout(timeoutDuration);
    } on TimeoutException {
      _pendingResponses.remove(event.id);
      developer.log(
        'Timeout waiting for response to event ${event.id}',
        name: 'EventBus',
      );
      return null;
    }
  }

  /// Send response to an event
  void sendResponse(AgentEventResponse response) {
    final completer = _pendingResponses.remove(response.originalEventId);
    if (completer != null && !completer.isCompleted) {
      completer.complete(response);
    }
  }

  /// Get relevant subscriptions for an event
  List<EventSubscription> _getRelevantSubscriptions(AgentEvent event) {
    final subscriptions = <EventSubscription>[];

    // Get direct subscriptions for this event type
    final directSubs = _subscriptions[event.eventType] ?? [];
    
    for (final sub in directSubs) {
      // Include if it's global, or if it's targeted to this agent, or if it's a broadcast
      if (sub.isGlobal || 
          event.targetAgent == null || 
          event.targetAgent == sub.agentId) {
        subscriptions.add(sub);
      }
    }

    // Get global subscriptions (those that want all events)
    final globalSubs = _subscriptions.values
        .expand((subs) => subs)
        .where((sub) => sub.isGlobal && !subscriptions.contains(sub));
    
    subscriptions.addAll(globalSubs);

    return subscriptions;
  }

  /// Process critical events synchronously
  Future<void> _processCriticalEvent(
    AgentEvent event,
    List<EventSubscription> subscriptions,
  ) async {
    for (final subscription in subscriptions) {
      try {
        final response = await subscription.handler(event);
        if (response != null && event.requiresResponse) {
          sendResponse(response);
        }
      } catch (e) {
        developer.log(
          'Error handling critical event in ${subscription.agentId}: $e',
          name: 'EventBus',
        );
      }
    }
  }

  /// Process normal events asynchronously
  void _processNormalEvent(
    AgentEvent event,
    List<EventSubscription> subscriptions,
  ) {
    for (final subscription in subscriptions) {
      subscription.handler(event).then((response) {
        if (response != null && event.requiresResponse) {
          sendResponse(response);
        }
      }).catchError((e) {
        developer.log(
          'Error handling event in ${subscription.agentId}: $e',
          name: 'EventBus',
        );
      });
    }
  }

  /// Get event history (for debugging)
  List<AgentEvent> getEventHistory({int? limit}) {
    if (limit != null && limit < _eventHistory.length) {
      return _eventHistory.sublist(_eventHistory.length - limit);
    }
    return List.from(_eventHistory);
  }

  /// Clear event history
  void clearHistory() {
    _eventHistory.clear();
  }

  /// Get subscription info (for debugging)
  Map<String, int> getSubscriptionInfo() {
    return _subscriptions.map((eventType, subs) => 
        MapEntry(eventType, subs.length));
  }

  /// Dispose of the event bus
  void dispose() {
    _subscriptions.clear();
    _pendingResponses.clear();
    _eventHistory.clear();
    _eventStreamController.close();
  }
}

/// Common event types used across agents
class EventTypes {
  // Character events
  static const String characterUpdated = 'character_updated';
  static const String characterLevelUp = 'character_level_up';
  static const String characterStatsChanged = 'character_stats_changed';
  static const String characterXpGained = 'character_xp_gained';

  // Battle events
  static const String battleStarted = 'battle_started';
  static const String battleTurnResolved = 'battle_turn_resolved';
  static const String battleEnded = 'battle_ended';
  static const String battleResult = 'battle_result';

  // Quest events
  static const String questStarted = 'quest_started';
  static const String questUpdated = 'quest_updated';
  static const String questCompleted = 'quest_completed';
  static const String questFailed = 'quest_failed';

  // Card events
  static const String cardScanned = 'card_scanned';
  static const String cardEquipped = 'card_equipped';
  static const String cardUnequipped = 'card_unequipped';
  static const String inventoryChanged = 'inventory_changed';

  // Fitness events
  static const String fitnessUpdate = 'fitness_update';
  static const String activityDetected = 'activity_detected';
  static const String fitnessGoalReached = 'fitness_goal_reached';

  // Location events
  static const String locationUpdate = 'location_update';
  static const String poiDetected = 'poi_detected';
  static const String geofenceEntered = 'geofence_entered';
  static const String geofenceExited = 'geofence_exited';

  // Achievement events
  static const String achievementUnlocked = 'achievement_unlocked';
  static const String achievementProgress = 'achievement_progress';

  // UI events
  static const String uiNavigation = 'ui_navigation';
  static const String uiButtonPressed = 'ui_button_pressed';
  static const String uiWindowOpened = 'ui_window_opened';
  static const String uiWindowClosed = 'ui_window_closed';

  // System events
  static const String systemError = 'system_error';
  static const String systemWarning = 'system_warning';
  static const String systemInfo = 'system_info';
  static const String dataSync = 'data_sync';
}

/// Event data helper classes
class CharacterUpdateData {
  final String characterId;
  final Map<String, dynamic> statChanges;
  final int xpGained;
  final List<String> itemsGained;
  final List<String> achievementsUnlocked;

  CharacterUpdateData({
    required this.characterId,
    this.statChanges = const {},
    this.xpGained = 0,
    this.itemsGained = const [],
    this.achievementsUnlocked = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'characterId': characterId,
      'statChanges': statChanges,
      'xpGained': xpGained,
      'itemsGained': itemsGained,
      'achievementsUnlocked': achievementsUnlocked,
    };
  }

  factory CharacterUpdateData.fromJson(Map<String, dynamic> json) {
    return CharacterUpdateData(
      characterId: json['characterId'],
      statChanges: Map<String, dynamic>.from(json['statChanges'] ?? {}),
      xpGained: json['xpGained'] ?? 0,
      itemsGained: List<String>.from(json['itemsGained'] ?? []),
      achievementsUnlocked: List<String>.from(json['achievementsUnlocked'] ?? []),
    );
  }
}

class BattleResultData {
  final String battleId;
  final bool isVictory;
  final int xpGained;
  final List<String> itemsGained;
  final Map<String, dynamic> statistics;
  final List<String> achievementsUnlocked;

  BattleResultData({
    required this.battleId,
    required this.isVictory,
    this.xpGained = 0,
    this.itemsGained = const [],
    this.statistics = const {},
    this.achievementsUnlocked = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'battleId': battleId,
      'isVictory': isVictory,
      'xpGained': xpGained,
      'itemsGained': itemsGained,
      'statistics': statistics,
      'achievementsUnlocked': achievementsUnlocked,
    };
  }

  factory BattleResultData.fromJson(Map<String, dynamic> json) {
    return BattleResultData(
      battleId: json['battleId'],
      isVictory: json['isVictory'] ?? false,
      xpGained: json['xpGained'] ?? 0,
      itemsGained: List<String>.from(json['itemsGained'] ?? []),
      statistics: Map<String, dynamic>.from(json['statistics'] ?? {}),
      achievementsUnlocked: List<String>.from(json['achievementsUnlocked'] ?? []),
    );
  }
}

class FitnessUpdateData {
  final String activityType;
  final int duration; // in minutes
  final int calories;
  final int steps;
  final Map<String, dynamic> metrics;
  final int xpGained;
  final List<String> achievementsUnlocked;

  FitnessUpdateData({
    required this.activityType,
    this.duration = 0,
    this.calories = 0,
    this.steps = 0,
    this.metrics = const {},
    this.xpGained = 0,
    this.achievementsUnlocked = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'activityType': activityType,
      'duration': duration,
      'calories': calories,
      'steps': steps,
      'metrics': metrics,
      'xpGained': xpGained,
      'achievementsUnlocked': achievementsUnlocked,
    };
  }

  factory FitnessUpdateData.fromJson(Map<String, dynamic> json) {
    return FitnessUpdateData(
      activityType: json['activityType'],
      duration: json['duration'] ?? 0,
      calories: json['calories'] ?? 0,
      steps: json['steps'] ?? 0,
      metrics: Map<String, dynamic>.from(json['metrics'] ?? {}),
      xpGained: json['xpGained'] ?? 0,
      achievementsUnlocked: List<String>.from(json['achievementsUnlocked'] ?? []),
    );
  }
}