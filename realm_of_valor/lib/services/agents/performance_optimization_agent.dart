import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/event_bus.dart';
import 'integration_orchestrator_agent.dart';

/// Performance metric types
enum PerformanceMetricType {
  frameRate,
  memoryUsage,
  cpuUsage,
  batteryDrain,
  networkLatency,
  diskIO,
  renderTime,
  agentResponseTime,
  eventProcessingTime,
  uiResponseTime,
}

/// Performance severity levels
enum PerformanceSeverity {
  optimal,
  good,
  warning,
  critical,
  emergency,
}

/// Optimization strategies
enum OptimizationStrategy {
  reduceAgentFrequency,
  enableLazyLoading,
  clearCaches,
  reduceLevelOfDetail,
  pauseNonCriticalAgents,
  optimizeNetworkRequests,
  compressData,
  freeMemory,
  throttleAnimations,
  emergencyMode,
}

/// Performance benchmark
class PerformanceBenchmark {
  final String metricName;
  final double targetValue;
  final double warningThreshold;
  final double criticalThreshold;
  final PerformanceMetricType type;
  final String unit;

  const PerformanceBenchmark({
    required this.metricName,
    required this.targetValue,
    required this.warningThreshold,
    required this.criticalThreshold,
    required this.type,
    required this.unit,
  });

  PerformanceSeverity evaluateValue(double value) {
    if (value <= targetValue * 1.1) return PerformanceSeverity.optimal;
    if (value <= warningThreshold) return PerformanceSeverity.good;
    if (value <= criticalThreshold) return PerformanceSeverity.warning;
    if (value <= criticalThreshold * 1.5) return PerformanceSeverity.critical;
    return PerformanceSeverity.emergency;
  }

  Map<String, dynamic> toJson() {
    return {
      'metricName': metricName,
      'targetValue': targetValue,
      'warningThreshold': warningThreshold,
      'criticalThreshold': criticalThreshold,
      'type': type.toString(),
      'unit': unit,
    };
  }

  factory PerformanceBenchmark.fromJson(Map<String, dynamic> json) {
    return PerformanceBenchmark(
      metricName: json['metricName'],
      targetValue: (json['targetValue'] ?? 0.0).toDouble(),
      warningThreshold: (json['warningThreshold'] ?? 0.0).toDouble(),
      criticalThreshold: (json['criticalThreshold'] ?? 0.0).toDouble(),
      type: PerformanceMetricType.values.firstWhere(
        (t) => t.toString() == json['type'],
        orElse: () => PerformanceMetricType.frameRate,
      ),
      unit: json['unit'] ?? '',
    );
  }
}

/// Performance metric reading
class PerformanceMetric {
  final String metricId;
  final PerformanceMetricType type;
  final double value;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final PerformanceSeverity severity;

  PerformanceMetric({
    String? metricId,
    required this.type,
    required this.value,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    required this.severity,
  }) : metricId = metricId ?? 'metric_${DateTime.now().millisecondsSinceEpoch}',
       timestamp = timestamp ?? DateTime.now(),
       metadata = metadata ?? {};

  Map<String, dynamic> toJson() {
    return {
      'metricId': metricId,
      'type': type.toString(),
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'severity': severity.toString(),
    };
  }

  factory PerformanceMetric.fromJson(Map<String, dynamic> json) {
    return PerformanceMetric(
      metricId: json['metricId'],
      type: PerformanceMetricType.values.firstWhere(
        (t) => t.toString() == json['type'],
        orElse: () => PerformanceMetricType.frameRate,
      ),
      value: (json['value'] ?? 0.0).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      severity: PerformanceSeverity.values.firstWhere(
        (s) => s.toString() == json['severity'],
        orElse: () => PerformanceSeverity.good,
      ),
    );
  }
}

/// Performance optimization recommendation
class OptimizationRecommendation {
  final String recommendationId;
  final OptimizationStrategy strategy;
  final String description;
  final double expectedImprovement;
  final PerformanceSeverity priority;
  final Map<String, dynamic> parameters;
  final DateTime createdAt;
  final bool isApplied;
  final double? actualImprovement;

  OptimizationRecommendation({
    String? recommendationId,
    required this.strategy,
    required this.description,
    required this.expectedImprovement,
    required this.priority,
    Map<String, dynamic>? parameters,
    DateTime? createdAt,
    this.isApplied = false,
    this.actualImprovement,
  }) : recommendationId = recommendationId ?? 'rec_${DateTime.now().millisecondsSinceEpoch}',
       parameters = parameters ?? {},
       createdAt = createdAt ?? DateTime.now();

  OptimizationRecommendation copyWith({
    bool? isApplied,
    double? actualImprovement,
  }) {
    return OptimizationRecommendation(
      recommendationId: recommendationId,
      strategy: strategy,
      description: description,
      expectedImprovement: expectedImprovement,
      priority: priority,
      parameters: Map.from(parameters),
      createdAt: createdAt,
      isApplied: isApplied ?? this.isApplied,
      actualImprovement: actualImprovement ?? this.actualImprovement,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recommendationId': recommendationId,
      'strategy': strategy.toString(),
      'description': description,
      'expectedImprovement': expectedImprovement,
      'priority': priority.toString(),
      'parameters': parameters,
      'createdAt': createdAt.toIso8601String(),
      'isApplied': isApplied,
      'actualImprovement': actualImprovement,
    };
  }

  factory OptimizationRecommendation.fromJson(Map<String, dynamic> json) {
    return OptimizationRecommendation(
      recommendationId: json['recommendationId'],
      strategy: OptimizationStrategy.values.firstWhere(
        (s) => s.toString() == json['strategy'],
        orElse: () => OptimizationStrategy.clearCaches,
      ),
      description: json['description'],
      expectedImprovement: (json['expectedImprovement'] ?? 0.0).toDouble(),
      priority: PerformanceSeverity.values.firstWhere(
        (p) => p.toString() == json['priority'],
        orElse: () => PerformanceSeverity.good,
      ),
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
      isApplied: json['isApplied'] ?? false,
      actualImprovement: json['actualImprovement']?.toDouble(),
    );
  }
}

/// Performance session data
class PerformanceSession {
  final String sessionId;
  final DateTime startTime;
  final DateTime? endTime;
  final Map<PerformanceMetricType, List<double>> metrics;
  final List<OptimizationRecommendation> appliedOptimizations;
  final Map<String, dynamic> deviceInfo;
  final double averageFrameRate;
  final double peakMemoryUsage;
  final int totalOptimizations;

  PerformanceSession({
    String? sessionId,
    DateTime? startTime,
    this.endTime,
    Map<PerformanceMetricType, List<double>>? metrics,
    List<OptimizationRecommendation>? appliedOptimizations,
    Map<String, dynamic>? deviceInfo,
    this.averageFrameRate = 0.0,
    this.peakMemoryUsage = 0.0,
    this.totalOptimizations = 0,
  }) : sessionId = sessionId ?? 'session_${DateTime.now().millisecondsSinceEpoch}',
       startTime = startTime ?? DateTime.now(),
       metrics = metrics ?? {},
       appliedOptimizations = appliedOptimizations ?? [],
       deviceInfo = deviceInfo ?? {};

  PerformanceSession copyWith({
    DateTime? endTime,
    Map<PerformanceMetricType, List<double>>? metrics,
    List<OptimizationRecommendation>? appliedOptimizations,
    double? averageFrameRate,
    double? peakMemoryUsage,
    int? totalOptimizations,
  }) {
    return PerformanceSession(
      sessionId: sessionId,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      metrics: metrics ?? Map.from(this.metrics),
      appliedOptimizations: appliedOptimizations ?? List.from(this.appliedOptimizations),
      deviceInfo: deviceInfo,
      averageFrameRate: averageFrameRate ?? this.averageFrameRate,
      peakMemoryUsage: peakMemoryUsage ?? this.peakMemoryUsage,
      totalOptimizations: totalOptimizations ?? this.totalOptimizations,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'metrics': metrics.map((k, v) => MapEntry(k.toString(), v)),
      'appliedOptimizations': appliedOptimizations.map((o) => o.toJson()).toList(),
      'deviceInfo': deviceInfo,
      'averageFrameRate': averageFrameRate,
      'peakMemoryUsage': peakMemoryUsage,
      'totalOptimizations': totalOptimizations,
    };
  }
}

/// Performance Optimization Agent - Advanced performance monitoring and optimization
class PerformanceOptimizationAgent extends BaseAgent {
  static const String agentId = 'performance_optimization';

  final SharedPreferences _prefs;

  // Current performance session
  PerformanceSession? _currentSession;

  // Performance monitoring
  final Map<PerformanceMetricType, PerformanceBenchmark> _benchmarks = {};
  final List<PerformanceMetric> _metrics = [];
  final List<OptimizationRecommendation> _recommendations = {};

  // Real-time monitoring
  Timer? _monitoringTimer;
  Timer? _optimizationTimer;
  Timer? _reportingTimer;

  // Performance state
  double _currentFrameRate = 60.0;
  double _currentMemoryUsage = 0.0;
  double _currentCPUUsage = 0.0;
  double _currentBatteryDrain = 0.0;
  DateTime? _lastBatteryCheck;

  // Optimization state
  bool _isOptimizing = false;
  int _totalOptimizationsApplied = 0;
  final Map<OptimizationStrategy, DateTime> _lastOptimizationTimes = {};

  // Agent performance tracking
  final Map<String, List<double>> _agentPerformance = {};
  final Map<String, int> _agentEventCounts = {};

  // Thresholds and configurations
  static const int maxMetricsHistory = 1000;
  static const int maxRecommendationsHistory = 100;
  static const Duration optimizationCooldown = Duration(minutes: 5);

  PerformanceOptimizationAgent({
    required SharedPreferences prefs,
  }) : _prefs = prefs,
       super(agentId: agentId);

  @override
  Future<void> onInitialize() async {
    developer.log('Initializing Performance Optimization Agent', name: agentId);

    // Load performance data
    await _loadPerformanceData();

    // Initialize benchmarks
    _initializeBenchmarks();

    // Start monitoring
    _startPerformanceMonitoring();
    _startOptimizationChecks();
    _startPerformanceReporting();

    // Start new session
    _startNewSession();

    developer.log('Performance Optimization Agent initialized', name: agentId);
  }

  @override
  void subscribeToEvents() {
    // System events for performance impact tracking
    subscribe('system_startup', _handleSystemStartup);
    subscribe('system_shutdown', _handleSystemShutdown);

    // Agent events for performance tracking
    subscribe('agent_registered', _handleAgentRegistered);
    subscribe('agent_event_processed', _handleAgentEventProcessed);

    // UI events for frame rate monitoring
    subscribe(EventTypes.uiWindowOpened, _handleUIEvent);
    subscribe(EventTypes.uiButtonPressed, _handleUIEvent);

    // Resource-intensive events
    subscribe('ar_session_started', _handleResourceIntensiveEvent);
    subscribe('battle_started', _handleResourceIntensiveEvent);
    subscribe('weather_updated', _handleResourceIntensiveEvent);

    // Performance-specific events
    subscribe('performance_request_optimization', _handleOptimizationRequest);
    subscribe('performance_get_metrics', _handleGetMetrics);
    subscribe('performance_force_cleanup', _handleForceCleanup);
    subscribe('performance_set_target', _handleSetTarget);

    // User management
    subscribe('user_login', _handleUserLogin);
    subscribe('user_logout', _handleUserLogout);
  }

  /// Start a new performance session
  void _startNewSession() {
    _currentSession = PerformanceSession(
      deviceInfo: _getDeviceInfo(),
    );

    publishEvent(createEvent(
      eventType: 'performance_session_started',
      data: {
        'sessionId': _currentSession!.sessionId,
        'deviceInfo': _currentSession!.deviceInfo,
      },
    ));

    developer.log('Performance session started: ${_currentSession!.sessionId}', name: agentId);
  }

  /// End current performance session
  void _endCurrentSession() {
    if (_currentSession == null) return;

    final avgFrameRate = _calculateAverageMetric(PerformanceMetricType.frameRate);
    final peakMemory = _calculatePeakMetric(PerformanceMetricType.memoryUsage);

    _currentSession = _currentSession!.copyWith(
      endTime: DateTime.now(),
      averageFrameRate: avgFrameRate,
      peakMemoryUsage: peakMemory,
      totalOptimizations: _totalOptimizationsApplied,
    );

    publishEvent(createEvent(
      eventType: 'performance_session_ended',
      data: {
        'sessionId': _currentSession!.sessionId,
        'duration': DateTime.now().difference(_currentSession!.startTime).inMinutes,
        'averageFrameRate': avgFrameRate,
        'peakMemoryUsage': peakMemory,
        'totalOptimizations': _totalOptimizationsApplied,
      },
    ));

    developer.log('Performance session ended: ${_currentSession!.sessionId}', name: agentId);
  }

  /// Record a performance metric
  void recordMetric(PerformanceMetricType type, double value, {Map<String, dynamic>? metadata}) {
    final benchmark = _benchmarks[type];
    final severity = benchmark?.evaluateValue(value) ?? PerformanceSeverity.good;

    final metric = PerformanceMetric(
      type: type,
      value: value,
      severity: severity,
      metadata: metadata ?? {},
    );

    _metrics.add(metric);

    // Keep metrics history manageable
    if (_metrics.length > maxMetricsHistory) {
      _metrics.removeAt(0);
    }

    // Update current values
    switch (type) {
      case PerformanceMetricType.frameRate:
        _currentFrameRate = value;
        break;
      case PerformanceMetricType.memoryUsage:
        _currentMemoryUsage = value;
        break;
      case PerformanceMetricType.cpuUsage:
        _currentCPUUsage = value;
        break;
      case PerformanceMetricType.batteryDrain:
        _currentBatteryDrain = value;
        break;
      default:
        break;
    }

    // Add to session metrics
    if (_currentSession != null) {
      _currentSession!.metrics[type] ??= [];
      _currentSession!.metrics[type]!.add(value);
      
      // Keep session metrics manageable
      if (_currentSession!.metrics[type]!.length > 100) {
        _currentSession!.metrics[type]!.removeAt(0);
      }
    }

    // Check if optimization is needed
    if (severity == PerformanceSeverity.warning || severity == PerformanceSeverity.critical) {
      _scheduleOptimization(type, severity);
    }

    // Publish metric event for other agents
    publishEvent(createEvent(
      eventType: 'performance_metric_recorded',
      data: {
        'type': type.toString(),
        'value': value,
        'severity': severity.toString(),
        'metadata': metadata,
      },
    ));
  }

  /// Get current performance overview
  Map<String, dynamic> getPerformanceOverview() {
    final recentMetrics = _metrics.where((m) => 
        DateTime.now().difference(m.timestamp).inMinutes < 5).toList();

    final severityCounts = <String, int>{};
    for (final severity in PerformanceSeverity.values) {
      severityCounts[severity.toString()] = recentMetrics
          .where((m) => m.severity == severity).length;
    }

    return {
      'currentFrameRate': _currentFrameRate,
      'currentMemoryUsage': _currentMemoryUsage,
      'currentCPUUsage': _currentCPUUsage,
      'currentBatteryDrain': _currentBatteryDrain,
      'activeOptimizations': _getActiveOptimizations(),
      'recentMetricsCount': recentMetrics.length,
      'severityDistribution': severityCounts,
      'totalOptimizationsApplied': _totalOptimizationsApplied,
      'sessionId': _currentSession?.sessionId,
      'sessionDuration': _currentSession != null 
          ? DateTime.now().difference(_currentSession!.startTime).inMinutes 
          : 0,
      'topPerformingAgents': _getTopPerformingAgents(),
      'bottomPerformingAgents': _getBottomPerformingAgents(),
    };
  }

  /// Apply an optimization recommendation
  Future<bool> applyOptimization(OptimizationRecommendation recommendation) async {
    if (_isOptimizing) return false;

    // Check cooldown
    final lastTime = _lastOptimizationTimes[recommendation.strategy];
    if (lastTime != null && 
        DateTime.now().difference(lastTime) < optimizationCooldown) {
      return false;
    }

    _isOptimizing = true;
    final startTime = DateTime.now();

    try {
      developer.log('Applying optimization: ${recommendation.strategy}', name: agentId);

      // Measure performance before optimization
      final beforeMetrics = _getCurrentMetrics();

      // Apply optimization based on strategy
      bool applied = false;
      switch (recommendation.strategy) {
        case OptimizationStrategy.clearCaches:
          applied = await _clearCaches();
          break;
        case OptimizationStrategy.freeMemory:
          applied = await _freeMemory();
          break;
        case OptimizationStrategy.reduceAgentFrequency:
          applied = await _reduceAgentFrequency(recommendation.parameters);
          break;
        case OptimizationStrategy.pauseNonCriticalAgents:
          applied = await _pauseNonCriticalAgents();
          break;
        case OptimizationStrategy.optimizeNetworkRequests:
          applied = await _optimizeNetworkRequests();
          break;
        case OptimizationStrategy.throttleAnimations:
          applied = await _throttleAnimations();
          break;
        case OptimizationStrategy.emergencyMode:
          applied = await _activateEmergencyMode();
          break;
        default:
          applied = false;
      }

      if (applied) {
        // Wait a moment for effects to take place
        await Future.delayed(const Duration(seconds: 2));

        // Measure performance after optimization
        final afterMetrics = _getCurrentMetrics();
        final actualImprovement = _calculateImprovement(beforeMetrics, afterMetrics);

        // Update recommendation
        final updatedRec = recommendation.copyWith(
          isApplied: true,
          actualImprovement: actualImprovement,
        );

        // Update in list
        final index = _recommendations.indexWhere((r) => r.recommendationId == recommendation.recommendationId);
        if (index >= 0) {
          _recommendations[index] = updatedRec;
        }

        _totalOptimizationsApplied++;
        _lastOptimizationTimes[recommendation.strategy] = DateTime.now();

        // Add to current session
        if (_currentSession != null) {
          _currentSession!.appliedOptimizations.add(updatedRec);
        }

        publishEvent(createEvent(
          eventType: 'optimization_applied',
          data: {
            'strategy': recommendation.strategy.toString(),
            'expectedImprovement': recommendation.expectedImprovement,
            'actualImprovement': actualImprovement,
            'duration': DateTime.now().difference(startTime).inMilliseconds,
          },
        ));

        developer.log('Optimization applied successfully: ${recommendation.strategy}', name: agentId);
      }

      return applied;

    } catch (e) {
      developer.log('Error applying optimization: $e', name: agentId);
      return false;
    } finally {
      _isOptimizing = false;
    }
  }

  /// Get performance recommendations
  List<OptimizationRecommendation> getRecommendations({PerformanceSeverity? minPriority}) {
    var recommendations = _recommendations.where((r) => !r.isApplied).toList();
    
    if (minPriority != null) {
      recommendations = recommendations.where((r) => 
          PerformanceSeverity.values.indexOf(r.priority) >= 
          PerformanceSeverity.values.indexOf(minPriority)).toList();
    }

    // Sort by priority and expected improvement
    recommendations.sort((a, b) {
      final priorityCompare = PerformanceSeverity.values.indexOf(b.priority)
          .compareTo(PerformanceSeverity.values.indexOf(a.priority));
      if (priorityCompare != 0) return priorityCompare;
      return b.expectedImprovement.compareTo(a.expectedImprovement);
    });

    return recommendations;
  }

  /// Force immediate performance cleanup
  Future<void> forceCleanup() async {
    developer.log('Force cleanup initiated', name: agentId);

    // Apply all critical and warning optimizations
    final criticalRecommendations = getRecommendations(minPriority: PerformanceSeverity.warning);
    
    for (final recommendation in criticalRecommendations.take(3)) { // Limit to 3 at once
      await applyOptimization(recommendation);
    }

    // Additional emergency measures
    await _emergencyCleanup();

    publishEvent(createEvent(
      eventType: 'force_cleanup_completed',
      data: {
        'optimizationsApplied': criticalRecommendations.length,
        'timestamp': DateTime.now().toIso8601String(),
      },
    ));
  }

  /// Initialize performance benchmarks
  void _initializeBenchmarks() {
    _benchmarks.clear();

    _benchmarks[PerformanceMetricType.frameRate] = const PerformanceBenchmark(
      metricName: 'Frame Rate',
      targetValue: 60.0,
      warningThreshold: 45.0,
      criticalThreshold: 30.0,
      type: PerformanceMetricType.frameRate,
      unit: 'fps',
    );

    _benchmarks[PerformanceMetricType.memoryUsage] = const PerformanceBenchmark(
      metricName: 'Memory Usage',
      targetValue: 150.0, // MB
      warningThreshold: 200.0,
      criticalThreshold: 300.0,
      type: PerformanceMetricType.memoryUsage,
      unit: 'MB',
    );

    _benchmarks[PerformanceMetricType.cpuUsage] = const PerformanceBenchmark(
      metricName: 'CPU Usage',
      targetValue: 30.0, // %
      warningThreshold: 60.0,
      criticalThreshold: 80.0,
      type: PerformanceMetricType.cpuUsage,
      unit: '%',
    );

    _benchmarks[PerformanceMetricType.batteryDrain] = const PerformanceBenchmark(
      metricName: 'Battery Drain',
      targetValue: 5.0, // %/hour
      warningThreshold: 10.0,
      criticalThreshold: 20.0,
      type: PerformanceMetricType.batteryDrain,
      unit: '%/hour',
    );

    _benchmarks[PerformanceMetricType.agentResponseTime] = const PerformanceBenchmark(
      metricName: 'Agent Response Time',
      targetValue: 10.0, // ms
      warningThreshold: 50.0,
      criticalThreshold: 100.0,
      type: PerformanceMetricType.agentResponseTime,
      unit: 'ms',
    );

    _benchmarks[PerformanceMetricType.networkLatency] = const PerformanceBenchmark(
      metricName: 'Network Latency',
      targetValue: 100.0, // ms
      warningThreshold: 500.0,
      criticalThreshold: 1000.0,
      type: PerformanceMetricType.networkLatency,
      unit: 'ms',
    );

    developer.log('Performance benchmarks initialized', name: agentId);
  }

  /// Start performance monitoring
  void _startPerformanceMonitoring() {
    _monitoringTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _collectPerformanceMetrics();
    });
  }

  /// Start optimization checks
  void _startOptimizationChecks() {
    _optimizationTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkForOptimizationOpportunities();
    });
  }

  /// Start performance reporting
  void _startPerformanceReporting() {
    _reportingTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _generatePerformanceReport();
    });
  }

  /// Collect current performance metrics
  void _collectPerformanceMetrics() {
    try {
      // Simulate frame rate measurement (in real app, this would use actual frame timing)
      final frameRate = 60.0 - (math.Random().nextDouble() * 10.0);
      recordMetric(PerformanceMetricType.frameRate, frameRate);

      // Simulate memory usage (in real app, this would use actual memory APIs)
      final memoryUsage = 100.0 + (math.Random().nextDouble() * 100.0);
      recordMetric(PerformanceMetricType.memoryUsage, memoryUsage);

      // Simulate CPU usage
      final cpuUsage = 20.0 + (math.Random().nextDouble() * 40.0);
      recordMetric(PerformanceMetricType.cpuUsage, cpuUsage);

      // Check battery drain (less frequently)
      if (_lastBatteryCheck == null || 
          DateTime.now().difference(_lastBatteryCheck!).inMinutes > 5) {
        final batteryDrain = 3.0 + (math.Random().nextDouble() * 7.0);
        recordMetric(PerformanceMetricType.batteryDrain, batteryDrain);
        _lastBatteryCheck = DateTime.now();
      }

    } catch (e) {
      developer.log('Error collecting performance metrics: $e', name: agentId);
    }
  }

  /// Check for optimization opportunities
  void _checkForOptimizationOpportunities() {
    if (_isOptimizing) return;

    final recentMetrics = _metrics.where((m) => 
        DateTime.now().difference(m.timestamp).inMinutes < 5).toList();

    // Check for performance issues
    final warningMetrics = recentMetrics.where((m) => 
        m.severity == PerformanceSeverity.warning).toList();
    final criticalMetrics = recentMetrics.where((m) => 
        m.severity == PerformanceSeverity.critical).toList();

    // Generate recommendations based on issues
    if (criticalMetrics.isNotEmpty) {
      _generateCriticalRecommendations(criticalMetrics);
    } else if (warningMetrics.isNotEmpty) {
      _generateWarningRecommendations(warningMetrics);
    }

    // Check agent performance
    _checkAgentPerformance();
  }

  /// Generate critical performance recommendations
  void _generateCriticalRecommendations(List<PerformanceMetric> criticalMetrics) {
    for (final metric in criticalMetrics) {
      switch (metric.type) {
        case PerformanceMetricType.memoryUsage:
          _addRecommendation(OptimizationRecommendation(
            strategy: OptimizationStrategy.freeMemory,
            description: 'High memory usage detected. Free up memory by clearing caches and unused objects.',
            expectedImprovement: 30.0,
            priority: PerformanceSeverity.critical,
            parameters: {'targetReduction': 0.3},
          ));
          break;

        case PerformanceMetricType.frameRate:
          _addRecommendation(OptimizationRecommendation(
            strategy: OptimizationStrategy.throttleAnimations,
            description: 'Low frame rate detected. Reduce visual complexity and throttle animations.',
            expectedImprovement: 25.0,
            priority: PerformanceSeverity.critical,
            parameters: {'animationQuality': 'low'},
          ));
          break;

        case PerformanceMetricType.cpuUsage:
          _addRecommendation(OptimizationRecommendation(
            strategy: OptimizationStrategy.pauseNonCriticalAgents,
            description: 'High CPU usage detected. Pause non-critical background agents.',
            expectedImprovement: 40.0,
            priority: PerformanceSeverity.critical,
            parameters: {'pauseDuration': 300}, // 5 minutes
          ));
          break;

        default:
          break;
      }
    }
  }

  /// Generate warning-level recommendations
  void _generateWarningRecommendations(List<PerformanceMetric> warningMetrics) {
    for (final metric in warningMetrics) {
      switch (metric.type) {
        case PerformanceMetricType.memoryUsage:
          _addRecommendation(OptimizationRecommendation(
            strategy: OptimizationStrategy.clearCaches,
            description: 'Memory usage above optimal. Clear unnecessary caches.',
            expectedImprovement: 15.0,
            priority: PerformanceSeverity.warning,
          ));
          break;

        case PerformanceMetricType.agentResponseTime:
          _addRecommendation(OptimizationRecommendation(
            strategy: OptimizationStrategy.reduceAgentFrequency,
            description: 'Agent response times high. Reduce update frequency for non-critical agents.',
            expectedImprovement: 20.0,
            priority: PerformanceSeverity.warning,
            parameters: {'reductionFactor': 0.5},
          ));
          break;

        default:
          break;
      }
    }
  }

  /// Check individual agent performance
  void _checkAgentPerformance() {
    final poorPerformers = _getBottomPerformingAgents();
    
    if (poorPerformers.isNotEmpty) {
      _addRecommendation(OptimizationRecommendation(
        strategy: OptimizationStrategy.reduceAgentFrequency,
        description: 'Some agents are performing poorly. Reduce their update frequency.',
        expectedImprovement: 15.0,
        priority: PerformanceSeverity.warning,
        parameters: {
          'targetAgents': poorPerformers.map((a) => a['agentId']).toList(),
        },
      ));
    }
  }

  /// Add optimization recommendation
  void _addRecommendation(OptimizationRecommendation recommendation) {
    // Avoid duplicate recommendations
    final existingRec = _recommendations.firstWhere(
      (r) => r.strategy == recommendation.strategy && !r.isApplied,
      orElse: () => recommendation,
    );

    if (existingRec == recommendation) {
      _recommendations.add(recommendation);
      
      // Keep recommendations history manageable
      if (_recommendations.length > maxRecommendationsHistory) {
        _recommendations.removeAt(0);
      }

      publishEvent(createEvent(
        eventType: 'optimization_recommendation_created',
        data: {
          'recommendationId': recommendation.recommendationId,
          'strategy': recommendation.strategy.toString(),
          'priority': recommendation.priority.toString(),
          'expectedImprovement': recommendation.expectedImprovement,
        },
      ));
    }
  }

  /// Generate performance report
  void _generatePerformanceReport() {
    final overview = getPerformanceOverview();
    final recommendations = getRecommendations();

    final report = {
      'reportId': 'report_${DateTime.now().millisecondsSinceEpoch}',
      'timestamp': DateTime.now().toIso8601String(),
      'overview': overview,
      'recommendations': recommendations.map((r) => r.toJson()).toList(),
      'sessionInfo': _currentSession?.toJson(),
    };

    publishEvent(createEvent(
      eventType: 'performance_report_generated',
      data: report,
    ));

    developer.log('Performance report generated', name: agentId);
  }

  /// Schedule optimization based on performance issue
  void _scheduleOptimization(PerformanceMetricType type, PerformanceSeverity severity) {
    if (severity == PerformanceSeverity.emergency) {
      // Apply emergency optimization immediately
      Timer.run(() async {
        await _activateEmergencyMode();
      });
    } else if (severity == PerformanceSeverity.critical) {
      // Apply critical optimization after short delay
      Timer(const Duration(seconds: 10), () async {
        final criticalRecs = getRecommendations(minPriority: PerformanceSeverity.critical);
        if (criticalRecs.isNotEmpty) {
          await applyOptimization(criticalRecs.first);
        }
      });
    }
  }

  /// Calculate average metric value
  double _calculateAverageMetric(PerformanceMetricType type) {
    final typeMetrics = _metrics.where((m) => m.type == type).toList();
    if (typeMetrics.isEmpty) return 0.0;
    
    final sum = typeMetrics.fold(0.0, (sum, m) => sum + m.value);
    return sum / typeMetrics.length;
  }

  /// Calculate peak metric value
  double _calculatePeakMetric(PerformanceMetricType type) {
    final typeMetrics = _metrics.where((m) => m.type == type).toList();
    if (typeMetrics.isEmpty) return 0.0;
    
    return typeMetrics.map((m) => m.value).reduce(math.max);
  }

  /// Get current metrics snapshot
  Map<PerformanceMetricType, double> _getCurrentMetrics() {
    return {
      PerformanceMetricType.frameRate: _currentFrameRate,
      PerformanceMetricType.memoryUsage: _currentMemoryUsage,
      PerformanceMetricType.cpuUsage: _currentCPUUsage,
      PerformanceMetricType.batteryDrain: _currentBatteryDrain,
    };
  }

  /// Calculate improvement between metric snapshots
  double _calculateImprovement(Map<PerformanceMetricType, double> before, Map<PerformanceMetricType, double> after) {
    double totalImprovement = 0.0;
    int count = 0;

    for (final type in before.keys) {
      if (after.containsKey(type)) {
        final beforeValue = before[type]!;
        final afterValue = after[type]!;
        
        // Calculate improvement percentage (positive = better)
        double improvement;
        if (type == PerformanceMetricType.frameRate) {
          improvement = ((afterValue - beforeValue) / beforeValue) * 100;
        } else {
          improvement = ((beforeValue - afterValue) / beforeValue) * 100;
        }
        
        totalImprovement += improvement;
        count++;
      }
    }

    return count > 0 ? totalImprovement / count : 0.0;
  }

  /// Get device information
  Map<String, dynamic> _getDeviceInfo() {
    return {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'numberOfProcessors': Platform.numberOfProcessors,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Get active optimizations
  List<Map<String, dynamic>> _getActiveOptimizations() {
    return _recommendations.where((r) => r.isApplied).map((r) => {
      'strategy': r.strategy.toString(),
      'actualImprovement': r.actualImprovement,
      'appliedAt': r.createdAt.toIso8601String(),
    }).toList();
  }

  /// Get top performing agents
  List<Map<String, dynamic>> _getTopPerformingAgents() {
    return _agentPerformance.entries
        .where((entry) => entry.value.isNotEmpty)
        .map((entry) => {
          'agentId': entry.key,
          'averageResponseTime': entry.value.fold(0.0, (sum, time) => sum + time) / entry.value.length,
          'eventCount': _agentEventCounts[entry.key] ?? 0,
        })
        .toList()
      ..sort((a, b) => (a['averageResponseTime'] as double).compareTo(b['averageResponseTime'] as double))
      ..take(5);
  }

  /// Get bottom performing agents
  List<Map<String, dynamic>> _getBottomPerformingAgents() {
    return _agentPerformance.entries
        .where((entry) => entry.value.isNotEmpty)
        .map((entry) => {
          'agentId': entry.key,
          'averageResponseTime': entry.value.fold(0.0, (sum, time) => sum + time) / entry.value.length,
          'eventCount': _agentEventCounts[entry.key] ?? 0,
        })
        .toList()
      ..sort((a, b) => (b['averageResponseTime'] as double).compareTo(a['averageResponseTime'] as double))
      ..take(3);
  }

  // Optimization Implementation Methods

  /// Clear caches optimization
  Future<bool> _clearCaches() async {
    try {
      // Clear various caches
      publishEvent(createEvent(
        eventType: 'system_clear_caches',
        data: {'requester': agentId},
      ));

      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      developer.log('Error clearing caches: $e', name: agentId);
      return false;
    }
  }

  /// Free memory optimization
  Future<bool> _freeMemory() async {
    try {
      // Request garbage collection and memory cleanup
      publishEvent(createEvent(
        eventType: 'system_free_memory',
        data: {'requester': agentId},
      ));

      await Future.delayed(const Duration(milliseconds: 1000));
      return true;
    } catch (e) {
      developer.log('Error freeing memory: $e', name: agentId);
      return false;
    }
  }

  /// Reduce agent frequency optimization
  Future<bool> _reduceAgentFrequency(Map<String, dynamic> parameters) async {
    try {
      final reductionFactor = parameters['reductionFactor'] ?? 0.5;
      final targetAgents = parameters['targetAgents'] as List<String>?;

      publishEvent(createEvent(
        eventType: 'system_reduce_agent_frequency',
        data: {
          'reductionFactor': reductionFactor,
          'targetAgents': targetAgents,
          'requester': agentId,
        },
      ));

      return true;
    } catch (e) {
      developer.log('Error reducing agent frequency: $e', name: agentId);
      return false;
    }
  }

  /// Pause non-critical agents optimization
  Future<bool> _pauseNonCriticalAgents() async {
    try {
      final nonCriticalAgents = [
        'analytics',
        'weather_integration',
        'social_features',
        'audio',
      ];

      publishEvent(createEvent(
        eventType: 'system_pause_agents',
        data: {
          'agentIds': nonCriticalAgents,
          'duration': 300, // 5 minutes
          'requester': agentId,
        },
      ));

      return true;
    } catch (e) {
      developer.log('Error pausing non-critical agents: $e', name: agentId);
      return false;
    }
  }

  /// Optimize network requests
  Future<bool> _optimizeNetworkRequests() async {
    try {
      publishEvent(createEvent(
        eventType: 'system_optimize_network',
        data: {
          'enableCompression': true,
          'batchRequests': true,
          'requester': agentId,
        },
      ));

      return true;
    } catch (e) {
      developer.log('Error optimizing network requests: $e', name: agentId);
      return false;
    }
  }

  /// Throttle animations optimization
  Future<bool> _throttleAnimations() async {
    try {
      publishEvent(createEvent(
        eventType: 'system_throttle_animations',
        data: {
          'quality': 'low',
          'frameRate': 30,
          'requester': agentId,
        },
      ));

      return true;
    } catch (e) {
      developer.log('Error throttling animations: $e', name: agentId);
      return false;
    }
  }

  /// Activate emergency mode
  Future<bool> _activateEmergencyMode() async {
    try {
      developer.log('Activating emergency mode', name: agentId);

      // Apply all emergency optimizations
      await _clearCaches();
      await _freeMemory();
      await _pauseNonCriticalAgents();
      await _throttleAnimations();

      publishEvent(createEvent(
        eventType: 'system_emergency_mode_activated',
        data: {
          'activatedBy': agentId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ));

      return true;
    } catch (e) {
      developer.log('Error activating emergency mode: $e', name: agentId);
      return false;
    }
  }

  /// Emergency cleanup
  Future<void> _emergencyCleanup() async {
    try {
      // Clear all optimization cooldowns for emergency
      _lastOptimizationTimes.clear();

      // Apply most aggressive optimizations
      await Future.wait([
        _clearCaches(),
        _freeMemory(),
        _pauseNonCriticalAgents(),
        _throttleAnimations(),
      ]);

    } catch (e) {
      developer.log('Error in emergency cleanup: $e', name: agentId);
    }
  }

  /// Load performance data
  Future<void> _loadPerformanceData() async {
    try {
      // Load metrics history
      final metricsJson = _prefs.getString('performance_metrics');
      if (metricsJson != null) {
        final data = jsonDecode(metricsJson) as List;
        _metrics.addAll(data.map((m) => PerformanceMetric.fromJson(m)));
      }

      // Load recommendations
      final recommendationsJson = _prefs.getString('performance_recommendations');
      if (recommendationsJson != null) {
        final data = jsonDecode(recommendationsJson) as List;
        _recommendations.addAll(data.map((r) => OptimizationRecommendation.fromJson(r)));
      }

      // Load agent performance data
      final agentPerfJson = _prefs.getString('agent_performance');
      if (agentPerfJson != null) {
        final data = jsonDecode(agentPerfJson) as Map<String, dynamic>;
        for (final entry in data.entries) {
          _agentPerformance[entry.key] = List<double>.from(entry.value);
        }
      }

    } catch (e) {
      developer.log('Error loading performance data: $e', name: agentId);
    }
  }

  /// Save performance data
  Future<void> _savePerformanceData() async {
    try {
      // Save recent metrics
      final recentMetrics = _metrics.take(100).toList();
      await _prefs.setString('performance_metrics', 
          jsonEncode(recentMetrics.map((m) => m.toJson()).toList()));

      // Save recent recommendations
      final recentRecs = _recommendations.take(20).toList();
      await _prefs.setString('performance_recommendations',
          jsonEncode(recentRecs.map((r) => r.toJson()).toList()));

      // Save agent performance data
      final agentPerfData = <String, List<double>>{};
      for (final entry in _agentPerformance.entries) {
        agentPerfData[entry.key] = entry.value.take(50).toList();
      }
      await _prefs.setString('agent_performance', jsonEncode(agentPerfData));

    } catch (e) {
      developer.log('Error saving performance data: $e', name: agentId);
    }
  }

  // Event Handlers

  /// Handle system startup
  Future<AgentEventResponse?> _handleSystemStartup(AgentEvent event) async {
    _startNewSession();

    return createResponse(
      originalEventId: event.id,
      responseType: 'performance_system_startup_processed',
      data: {'sessionStarted': true},
    );
  }

  /// Handle system shutdown
  Future<AgentEventResponse?> _handleSystemShutdown(AgentEvent event) async {
    _endCurrentSession();
    await _savePerformanceData();

    return createResponse(
      originalEventId: event.id,
      responseType: 'performance_system_shutdown_processed',
      data: {'sessionEnded': true},
    );
  }

  /// Handle agent registered
  Future<AgentEventResponse?> _handleAgentRegistered(AgentEvent event) async {
    final agentId = event.data['agentId'];
    
    if (agentId != null) {
      _agentPerformance[agentId] = [];
      _agentEventCounts[agentId] = 0;
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'performance_agent_tracked',
      data: {'agentId': agentId},
    );
  }

  /// Handle agent event processed
  Future<AgentEventResponse?> _handleAgentEventProcessed(AgentEvent event) async {
    final agentId = event.data['agentId'];
    final responseTime = event.data['responseTime']?.toDouble();

    if (agentId != null && responseTime != null) {
      _agentPerformance[agentId] ??= [];
      _agentPerformance[agentId]!.add(responseTime);
      
      // Keep agent performance history manageable
      if (_agentPerformance[agentId]!.length > 100) {
        _agentPerformance[agentId]!.removeAt(0);
      }

      _agentEventCounts[agentId] = (_agentEventCounts[agentId] ?? 0) + 1;

      // Record agent response time metric
      recordMetric(PerformanceMetricType.agentResponseTime, responseTime, metadata: {
        'agentId': agentId,
      });
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'performance_agent_event_tracked',
      data: {'agentId': agentId, 'responseTime': responseTime},
    );
  }

  /// Handle UI events
  Future<AgentEventResponse?> _handleUIEvent(AgentEvent event) async {
    // UI events can indicate frame rate issues
    recordMetric(PerformanceMetricType.uiResponseTime, 16.67, metadata: {
      'eventType': event.eventType,
    });

    return createResponse(
      originalEventId: event.id,
      responseType: 'performance_ui_event_tracked',
      data: {'eventType': event.eventType},
    );
  }

  /// Handle resource intensive events
  Future<AgentEventResponse?> _handleResourceIntensiveEvent(AgentEvent event) async {
    // Mark start of resource-intensive operation
    recordMetric(PerformanceMetricType.renderTime, 33.33, metadata: {
      'operation': event.eventType,
      'startTime': DateTime.now().toIso8601String(),
    });

    return createResponse(
      originalEventId: event.id,
      responseType: 'performance_intensive_event_tracked',
      data: {'operation': event.eventType},
    );
  }

  /// Handle optimization requests
  Future<AgentEventResponse?> _handleOptimizationRequest(AgentEvent event) async {
    final strategy = event.data['strategy'];
    
    if (strategy != null) {
      final optimizationStrategy = OptimizationStrategy.values.firstWhere(
        (s) => s.toString().contains(strategy),
        orElse: () => OptimizationStrategy.clearCaches,
      );

      final recommendation = OptimizationRecommendation(
        strategy: optimizationStrategy,
        description: 'Manual optimization request',
        expectedImprovement: 10.0,
        priority: PerformanceSeverity.good,
        parameters: event.data['parameters'] ?? {},
      );

      final applied = await applyOptimization(recommendation);

      return createResponse(
        originalEventId: event.id,
        responseType: 'optimization_request_processed',
        data: {
          'strategy': strategy,
          'applied': applied,
        },
        success: applied,
      );
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'optimization_request_failed',
      data: {'error': 'No strategy specified'},
      success: false,
    );
  }

  /// Handle get metrics requests
  Future<AgentEventResponse?> _handleGetMetrics(AgentEvent event) async {
    final overview = getPerformanceOverview();

    return createResponse(
      originalEventId: event.id,
      responseType: 'performance_metrics_retrieved',
      data: overview,
    );
  }

  /// Handle force cleanup requests
  Future<AgentEventResponse?> _handleForceCleanup(AgentEvent event) async {
    await forceCleanup();

    return createResponse(
      originalEventId: event.id,
      responseType: 'force_cleanup_completed',
      data: {'cleanupCompleted': true},
    );
  }

  /// Handle set target requests
  Future<AgentEventResponse?> _handleSetTarget(AgentEvent event) async {
    final metricType = event.data['metricType'];
    final targetValue = event.data['targetValue']?.toDouble();

    if (metricType != null && targetValue != null) {
      final type = PerformanceMetricType.values.firstWhere(
        (t) => t.toString().contains(metricType),
        orElse: () => PerformanceMetricType.frameRate,
      );

      // Update benchmark if it exists
      final existingBenchmark = _benchmarks[type];
      if (existingBenchmark != null) {
        _benchmarks[type] = PerformanceBenchmark(
          metricName: existingBenchmark.metricName,
          targetValue: targetValue,
          warningThreshold: existingBenchmark.warningThreshold,
          criticalThreshold: existingBenchmark.criticalThreshold,
          type: type,
          unit: existingBenchmark.unit,
        );
      }

      return createResponse(
        originalEventId: event.id,
        responseType: 'performance_target_set',
        data: {
          'metricType': metricType,
          'targetValue': targetValue,
        },
      );
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'performance_target_set_failed',
      data: {'error': 'Invalid parameters'},
      success: false,
    );
  }

  /// Handle user login
  Future<AgentEventResponse?> _handleUserLogin(AgentEvent event) async {
    // Start fresh session for user
    _startNewSession();

    return createResponse(
      originalEventId: event.id,
      responseType: 'user_login_performance_processed',
      data: {'newSessionStarted': true},
    );
  }

  /// Handle user logout
  Future<AgentEventResponse?> _handleUserLogout(AgentEvent event) async {
    // End session and save data
    _endCurrentSession();
    await _savePerformanceData();

    return createResponse(
      originalEventId: event.id,
      responseType: 'user_logout_performance_processed',
      data: {'sessionEnded': true, 'dataSaved': true},
    );
  }

  @override
  Future<void> onDispose() async {
    // Stop all timers
    _monitoringTimer?.cancel();
    _optimizationTimer?.cancel();
    _reportingTimer?.cancel();

    // End current session
    _endCurrentSession();

    // Save all performance data
    await _savePerformanceData();

    developer.log('Performance Optimization Agent disposed', name: agentId);
  }
}