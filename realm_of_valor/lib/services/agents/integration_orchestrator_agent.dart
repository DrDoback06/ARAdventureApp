import 'dart:async';
import 'dart:developer' as developer;
import '../../services/event_bus.dart';

/// Base class for all agents in the system
abstract class BaseAgent {
  final String agentId;
  final EventBus eventBus;
  final List<String> _subscriptionIds = [];
  bool _isInitialized = false;
  bool _isDisposed = false;

  BaseAgent({
    required this.agentId,
    EventBus? eventBus,
  }) : eventBus = eventBus ?? EventBus();

  /// Initialize the agent
  Future<void> initialize() async {
    if (_isInitialized || _isDisposed) return;

    try {
      await onInitialize();
      _subscribeToEvents();
      _isInitialized = true;
      
      developer.log('Agent $agentId initialized successfully', name: 'BaseAgent');
    } catch (e) {
      developer.log('Failed to initialize agent $agentId: $e', name: 'BaseAgent');
      rethrow;
    }
  }

  /// Override this method to implement agent-specific initialization
  Future<void> onInitialize() async {}

  /// Subscribe to events - override this method to add subscriptions
  void _subscribeToEvents() {
    subscribeToEvents();
  }

  /// Override this method to subscribe to specific events
  void subscribeToEvents() {}

  /// Helper method to subscribe to events
  void subscribe(String eventType, EventHandler handler, {bool isGlobal = false}) {
    final subscriptionId = eventBus.subscribe(
      agentId: agentId,
      eventType: eventType,
      handler: handler,
      isGlobal: isGlobal,
    );
    _subscriptionIds.add(subscriptionId);
  }

  /// Publish an event
  Future<void> publishEvent(AgentEvent event) async {
    await eventBus.publish(event);
  }

  /// Publish an event and wait for response
  Future<AgentEventResponse?> publishEventAndWaitForResponse(
    AgentEvent event, {
    Duration? timeout,
  }) async {
    return await eventBus.publishAndWaitForResponse(event, timeout: timeout);
  }

  /// Send a response to an event
  void sendResponse(AgentEventResponse response) {
    eventBus.sendResponse(response);
  }

  /// Create an event with this agent as the source
  AgentEvent createEvent({
    String? targetAgent,
    required String eventType,
    required Map<String, dynamic> data,
    EventPriority priority = EventPriority.medium,
    bool requiresResponse = false,
    String? correlationId,
  }) {
    return AgentEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString() + '_' + agentId,
      sourceAgent: agentId,
      targetAgent: targetAgent,
      eventType: eventType,
      data: data,
      priority: priority,
      requiresResponse: requiresResponse,
      correlationId: correlationId,
    );
  }

  /// Create a response to an event
  AgentEventResponse createResponse({
    required String originalEventId,
    required String responseType,
    required Map<String, dynamic> data,
    bool success = true,
    String? error,
  }) {
    return AgentEventResponse(
      originalEventId: originalEventId,
      sourceAgent: agentId,
      responseType: responseType,
      data: data,
      success: success,
      error: error,
    );
  }

  /// Check if agent is initialized
  bool get isInitialized => _isInitialized;

  /// Check if agent is disposed
  bool get isDisposed => _isDisposed;

  /// Dispose of the agent
  Future<void> dispose() async {
    if (_isDisposed) return;

    // Unsubscribe from all events
    for (final subscriptionId in _subscriptionIds) {
      eventBus.unsubscribe(subscriptionId);
    }
    _subscriptionIds.clear();

    await onDispose();
    _isDisposed = true;
    
    developer.log('Agent $agentId disposed', name: 'BaseAgent');
  }

  /// Override this method to implement agent-specific disposal
  Future<void> onDispose() async {}
}

/// Health status of an agent
enum AgentHealth {
  healthy,
  warning,
  critical,
  offline,
}

/// Agent status information
class AgentStatus {
  final String agentId;
  final AgentHealth health;
  final DateTime lastHeartbeat;
  final Map<String, dynamic> metrics;
  final String? errorMessage;

  AgentStatus({
    required this.agentId,
    required this.health,
    DateTime? lastHeartbeat,
    this.metrics = const {},
    this.errorMessage,
  }) : lastHeartbeat = lastHeartbeat ?? DateTime.now();
}

/// Integration Orchestrator Agent - Central coordinator for all agents
class IntegrationOrchestratorAgent extends BaseAgent {
  static const String _agentTypeId = 'integration_orchestrator';

  final Map<String, BaseAgent> _agents = {};
  final Map<String, AgentStatus> _agentStatus = {};
  final Map<String, Timer> _heartbeatTimers = {};
  final Map<String, List<AgentEvent>> _eventQueue = {};
  
  // Configuration
  final Duration heartbeatInterval;
  final Duration heartbeatTimeout;
  final int maxQueueSize;

  IntegrationOrchestratorAgent({
    EventBus? eventBus,
    this.heartbeatInterval = const Duration(seconds: 30),
    this.heartbeatTimeout = const Duration(seconds: 60),
    this.maxQueueSize = 1000,
  }) : super(agentId: agentId, eventBus: eventBus);

  @override
  Future<void> onInitialize() async {
    developer.log('Initializing Integration Orchestrator Agent', name: agentId);
    
    // Start monitoring system health
    _startSystemMonitoring();
  }

  @override
  void subscribeToEvents() {
    // Subscribe to all events for monitoring and routing
    subscribe('*', _handleAllEvents, isGlobal: true);
    
    // Subscribe to specific system events
    subscribe(EventTypes.systemError, _handleSystemError);
    subscribe(EventTypes.systemWarning, _handleSystemWarning);
    subscribe('agent_heartbeat', _handleHeartbeat);
    subscribe('agent_register', _handleAgentRegistration);
    subscribe('agent_unregister', _handleAgentUnregistration);
  }

  /// Register an agent with the orchestrator
  Future<void> registerAgent(BaseAgent agent) async {
    if (_agents.containsKey(agent.agentId)) {
      developer.log('Agent ${agent.agentId} is already registered', name: agentId);
      return;
    }

    _agents[agent.agentId] = agent;
    _agentStatus[agent.agentId] = AgentStatus(
      agentId: agent.agentId,
      health: AgentHealth.healthy,
    );

    // Initialize the agent if not already initialized
    if (!agent.isInitialized) {
      await agent.initialize();
    }

    // Start heartbeat monitoring
    _startHeartbeatMonitoring(agent.agentId);

    // Notify about agent registration
    await publishEvent(createEvent(
      eventType: 'agent_registered',
      data: {'agentId': agent.agentId},
    ));

    developer.log('Registered agent: ${agent.agentId}', name: agentId);
  }

  /// Unregister an agent
  Future<void> unregisterAgent(String agentId) async {
    final agent = _agents.remove(agentId);
    if (agent != null) {
      await agent.dispose();
    }

    _agentStatus.remove(agentId);
    _heartbeatTimers[agentId]?.cancel();
    _heartbeatTimers.remove(agentId);
    _eventQueue.remove(agentId);

    // Notify about agent unregistration
    await publishEvent(createEvent(
      eventType: 'agent_unregistered',
      data: {'agentId': agentId},
    ));

    developer.log('Unregistered agent: $agentId', name: this.agentId);
  }

  /// Get all registered agents
  Map<String, BaseAgent> get registeredAgents => Map.unmodifiable(_agents);

  /// Get agent status information
  Map<String, AgentStatus> get agentStatuses => Map.unmodifiable(_agentStatus);

  /// Get system health overview
  Map<String, dynamic> getSystemHealth() {
    final healthCounts = <AgentHealth, int>{};
    for (final status in _agentStatus.values) {
      healthCounts[status.health] = (healthCounts[status.health] ?? 0) + 1;
    }

    return {
      'totalAgents': _agents.length,
      'healthCounts': healthCounts.map((k, v) => MapEntry(k.toString(), v)),
      'lastCheck': DateTime.now().toIso8601String(),
      'eventQueueSizes': _eventQueue.map((k, v) => MapEntry(k, v.length)),
    };
  }

  /// Force health check of all agents
  Future<void> performHealthCheck() async {
    for (final agentId in _agents.keys) {
      await _checkAgentHealth(agentId);
    }
  }

  /// Restart an agent
  Future<void> restartAgent(String agentId) async {
    final agent = _agents[agentId];
    if (agent == null) {
      developer.log('Cannot restart agent $agentId: not found', name: this.agentId);
      return;
    }

    developer.log('Restarting agent $agentId', name: this.agentId);

    try {
      await agent.dispose();
      await agent.initialize();
      
      _updateAgentStatus(agentId, AgentHealth.healthy);
      developer.log('Agent $agentId restarted successfully', name: this.agentId);
    } catch (e) {
      _updateAgentStatus(agentId, AgentHealth.critical, 'Restart failed: $e');
      developer.log('Failed to restart agent $agentId: $e', name: this.agentId);
    }
  }

  /// Handle all events for monitoring and routing
  Future<AgentEventResponse?> _handleAllEvents(AgentEvent event) async {
    // Log event for monitoring
    developer.log(
      'Event: ${event.eventType} from ${event.sourceAgent} to ${event.targetAgent ?? 'broadcast'}',
      name: agentId,
    );

    // Update agent activity
    if (_agentStatus.containsKey(event.sourceAgent)) {
      _updateAgentActivity(event.sourceAgent);
    }

    // Handle event routing if needed
    await _routeEvent(event);

    return null; // Orchestrator typically doesn't respond to events
  }

  /// Route events based on priority and target
  Future<void> _routeEvent(AgentEvent event) async {
    // Handle critical events immediately
    if (event.priority == EventPriority.critical) {
      // Critical events get immediate attention
      await _processCriticalEvent(event);
    }

    // Queue events for offline agents
    if (event.targetAgent != null) {
      final targetStatus = _agentStatus[event.targetAgent];
      if (targetStatus?.health == AgentHealth.offline) {
        _queueEvent(event.targetAgent!, event);
      }
    }
  }

  /// Process critical events
  Future<void> _processCriticalEvent(AgentEvent event) async {
    developer.log('Processing critical event: ${event.eventType}', name: agentId);
    
    // Handle system critical events
    if (event.eventType == EventTypes.systemError) {
      await _handleSystemCriticalError(event);
    }
  }

  /// Queue event for offline agent
  void _queueEvent(String agentId, AgentEvent event) {
    _eventQueue.putIfAbsent(agentId, () => []).add(event);
    
    // Limit queue size
    final queue = _eventQueue[agentId]!;
    if (queue.length > maxQueueSize) {
      queue.removeAt(0); // Remove oldest event
    }
  }

  /// Process queued events for an agent
  Future<void> _processQueuedEvents(String agentId) async {
    final queue = _eventQueue[agentId];
    if (queue == null || queue.isEmpty) return;

    developer.log('Processing ${queue.length} queued events for $agentId', name: this.agentId);

    for (final event in queue) {
      await publishEvent(event);
    }

    queue.clear();
  }

  /// Handle system errors
  Future<AgentEventResponse?> _handleSystemError(AgentEvent event) async {
    developer.log('System error: ${event.data}', name: agentId);
    
    final sourceAgent = event.sourceAgent;
    _updateAgentStatus(sourceAgent, AgentHealth.critical, event.data['error']?.toString());

    // Attempt recovery if possible
    await _attemptAgentRecovery(sourceAgent);

    return createResponse(
      originalEventId: event.id,
      responseType: 'error_acknowledged',
      data: {'acknowledged': true},
    );
  }

  /// Handle system warnings
  Future<AgentEventResponse?> _handleSystemWarning(AgentEvent event) async {
    developer.log('System warning: ${event.data}', name: agentId);
    
    final sourceAgent = event.sourceAgent;
    _updateAgentStatus(sourceAgent, AgentHealth.warning, event.data['warning']?.toString());

    return createResponse(
      originalEventId: event.id,
      responseType: 'warning_acknowledged',
      data: {'acknowledged': true},
    );
  }

  /// Handle agent heartbeat
  Future<AgentEventResponse?> _handleHeartbeat(AgentEvent event) async {
    final agentId = event.sourceAgent;
    _updateAgentActivity(agentId);
    
    return createResponse(
      originalEventId: event.id,
      responseType: 'heartbeat_acknowledged',
      data: {'timestamp': DateTime.now().toIso8601String()},
    );
  }

  /// Handle agent registration requests
  Future<AgentEventResponse?> _handleAgentRegistration(AgentEvent event) async {
    final requestedAgentId = event.data['agentId'];
    
    return createResponse(
      originalEventId: event.id,
      responseType: 'registration_response',
      data: {
        'accepted': true,
        'agentId': requestedAgentId,
      },
    );
  }

  /// Handle agent unregistration requests
  Future<AgentEventResponse?> _handleAgentUnregistration(AgentEvent event) async {
    final requestedAgentId = event.data['agentId'];
    await unregisterAgent(requestedAgentId);
    
    return createResponse(
      originalEventId: event.id,
      responseType: 'unregistration_response',
      data: {
        'accepted': true,
        'agentId': requestedAgentId,
      },
    );
  }

  /// Start system monitoring
  void _startSystemMonitoring() {
    Timer.periodic(heartbeatInterval, (timer) {
      _performSystemHealthCheck();
    });
  }

  /// Start heartbeat monitoring for an agent
  void _startHeartbeatMonitoring(String agentId) {
    _heartbeatTimers[agentId] = Timer.periodic(heartbeatTimeout, (timer) {
      _checkAgentHealth(agentId);
    });
  }

  /// Perform system health check
  void _performSystemHealthCheck() {
    for (final agentId in _agents.keys) {
      _checkAgentHealth(agentId);
    }
  }

  /// Check health of a specific agent
  Future<void> _checkAgentHealth(String agentId) async {
    final status = _agentStatus[agentId];
    if (status == null) return;

    final timeSinceHeartbeat = DateTime.now().difference(status.lastHeartbeat);
    
    if (timeSinceHeartbeat > heartbeatTimeout) {
      _updateAgentStatus(agentId, AgentHealth.offline, 'Heartbeat timeout');
      developer.log('Agent $agentId is offline (no heartbeat)', name: this.agentId);
    } else if (timeSinceHeartbeat > heartbeatTimeout ~/ 2) {
      _updateAgentStatus(agentId, AgentHealth.warning, 'Heartbeat delayed');
    }
  }

  /// Update agent status
  void _updateAgentStatus(String agentId, AgentHealth health, [String? errorMessage]) {
    _agentStatus[agentId] = AgentStatus(
      agentId: agentId,
      health: health,
      errorMessage: errorMessage,
    );
  }

  /// Update agent activity (heartbeat)
  void _updateAgentActivity(String agentId) {
    final currentStatus = _agentStatus[agentId];
    if (currentStatus != null) {
      _agentStatus[agentId] = AgentStatus(
        agentId: agentId,
        health: AgentHealth.healthy,
        metrics: currentStatus.metrics,
      );

      // Process any queued events if agent came back online
      if (currentStatus.health == AgentHealth.offline) {
        _processQueuedEvents(agentId);
      }
    }
  }

  /// Attempt to recover an agent
  Future<void> _attemptAgentRecovery(String agentId) async {
    developer.log('Attempting recovery for agent $agentId', name: this.agentId);
    
    try {
      await restartAgent(agentId);
    } catch (e) {
      developer.log('Recovery failed for agent $agentId: $e', name: this.agentId);
    }
  }

  /// Handle system critical errors
  Future<void> _handleSystemCriticalError(AgentEvent event) async {
    final sourceAgent = event.sourceAgent;
    developer.log('Critical system error from $sourceAgent: ${event.data}', name: agentId);
    
    // Mark agent as critical
    _updateAgentStatus(sourceAgent, AgentHealth.critical, event.data['error']?.toString());
    
    // Attempt immediate recovery
    await _attemptAgentRecovery(sourceAgent);
  }

  @override
  Future<void> onDispose() async {
    // Cancel all timers
    for (final timer in _heartbeatTimers.values) {
      timer.cancel();
    }
    _heartbeatTimers.clear();

    // Dispose all registered agents
    for (final agent in _agents.values) {
      await agent.dispose();
    }
    _agents.clear();
    _agentStatus.clear();
    _eventQueue.clear();

    developer.log('Integration Orchestrator Agent disposed', name: agentId);
  }
}

/// Singleton instance of the Integration Orchestrator
class AgentOrchestrator {
  static IntegrationOrchestratorAgent? _instance;
  
  static IntegrationOrchestratorAgent get instance {
    _instance ??= IntegrationOrchestratorAgent();
    return _instance!;
  }

  static Future<void> initialize() async {
    await instance.initialize();
  }

  static Future<void> dispose() async {
    if (_instance != null) {
      await _instance!.dispose();
      _instance = null;
    }
  }
}