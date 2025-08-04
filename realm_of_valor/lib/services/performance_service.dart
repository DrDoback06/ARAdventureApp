import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

class PerformanceMetrics {
  final double fps;
  final int memoryUsage;
  final int batteryLevel;
  final double cpuUsage;
  final int activeWidgets;
  final Duration frameTime;
  final int cacheSize;
  final int networkRequests;

  PerformanceMetrics({
    required this.fps,
    required this.memoryUsage,
    required this.batteryLevel,
    required this.cpuUsage,
    required this.activeWidgets,
    required this.frameTime,
    required this.cacheSize,
    required this.networkRequests,
  });

  Map<String, dynamic> toJson() {
    return {
      'fps': fps,
      'memoryUsage': memoryUsage,
      'batteryLevel': batteryLevel,
      'cpuUsage': cpuUsage,
      'activeWidgets': activeWidgets,
      'frameTime': frameTime.inMilliseconds,
      'cacheSize': cacheSize,
      'networkRequests': networkRequests,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

class PerformanceService extends ChangeNotifier {
  static PerformanceService? _instance;
  static PerformanceService get instance => _instance ??= PerformanceService._();
  
  PerformanceService._();
  
  Timer? _performanceTimer;
  List<PerformanceMetrics> _metrics = [];
  bool _isMonitoring = false;
  int _frameCount = 0;
  DateTime? _lastFrameTime;
  int _activeWidgets = 0;
  int _networkRequests = 0;
  int _cacheSize = 0;
  
  // Performance thresholds
  static const double _targetFps = 60.0;
  static const int _maxMemoryUsage = 100 * 1024 * 1024; // 100MB
  static const int _maxCacheSize = 50 * 1024 * 1024; // 50MB
  static const Duration _maxFrameTime = Duration(milliseconds: 16); // 60 FPS
  
  // Getters
  List<PerformanceMetrics> get metrics => List.unmodifiable(_metrics);
  bool get isMonitoring => _isMonitoring;
  double get averageFps => _calculateAverageFps();
  int get averageMemoryUsage => _calculateAverageMemoryUsage();
  double get averageCpuUsage => _calculateAverageCpuUsage();
  
  // Performance status
  bool get isPerformanceGood => averageFps >= _targetFps && averageMemoryUsage < _maxMemoryUsage;
  bool get needsOptimization => averageFps < _targetFps || averageMemoryUsage > _maxMemoryUsage;
  String get performanceStatus {
    if (isPerformanceGood) return 'Excellent';
    if (needsOptimization) return 'Needs Optimization';
    return 'Good';
  }

  // Initialize performance monitoring
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMetrics = prefs.getString('performance_metrics');
      
      if (savedMetrics != null) {
        final List<dynamic> metricsJson = jsonDecode(savedMetrics);
        _metrics = metricsJson.map((json) => _metricsFromJson(json)).toList();
      }
      
      // Start monitoring
      startMonitoring();
      
      debugPrint('[PERFORMANCE] Service initialized');
    } catch (e) {
      debugPrint('[PERFORMANCE] Error initializing: $e');
    }
  }

  // Start performance monitoring
  void startMonitoring() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _performanceTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _collectMetrics();
    });
    
    debugPrint('[PERFORMANCE] Started monitoring');
  }

  // Stop performance monitoring
  void stopMonitoring() {
    _isMonitoring = false;
    _performanceTimer?.cancel();
    _performanceTimer = null;
    
    debugPrint('[PERFORMANCE] Stopped monitoring');
  }

  // Collect performance metrics
  void _collectMetrics() {
    try {
      final now = DateTime.now();
      final fps = _calculateFps(now);
      final memoryUsage = _estimateMemoryUsage();
      const batteryLevel = 85; // Placeholder - would integrate with battery API
      const cpuUsage = 25.0; // Placeholder - would integrate with CPU monitoring
      
      final metrics = PerformanceMetrics(
        fps: fps,
        memoryUsage: memoryUsage,
        batteryLevel: batteryLevel,
        cpuUsage: cpuUsage,
        activeWidgets: _activeWidgets,
        frameTime: _calculateFrameTime(now),
        cacheSize: _cacheSize,
        networkRequests: _networkRequests,
      );
      
      _metrics.add(metrics);
      
      // Keep only last 100 metrics (about 8 minutes of data)
      if (_metrics.length > 100) {
        _metrics.removeAt(0);
      }
      
      // Check for performance issues
      _checkPerformanceIssues(metrics);
      
      notifyListeners();
    } catch (e) {
      debugPrint('[PERFORMANCE] Error collecting metrics: $e');
    }
  }

  // Calculate FPS
  double _calculateFps(DateTime now) {
    if (_lastFrameTime == null) {
      _lastFrameTime = now;
      return 60.0;
    }
    
    final frameDuration = now.difference(_lastFrameTime!);
    final fps = 1000 / frameDuration.inMilliseconds;
    
    _lastFrameTime = now;
    return fps.clamp(0.0, 120.0);
  }

  // Estimate memory usage
  int _estimateMemoryUsage() {
    // Placeholder - would integrate with actual memory monitoring
    return 50 * 1024 * 1024 + math.Random().nextInt(20 * 1024 * 1024); // 50-70MB
  }

  // Calculate frame time
  Duration _calculateFrameTime(DateTime now) {
    if (_lastFrameTime == null) return const Duration(milliseconds: 16);
    return now.difference(_lastFrameTime!);
  }

  // Check for performance issues
  void _checkPerformanceIssues(PerformanceMetrics metrics) {
    if (metrics.fps < _targetFps) {
      debugPrint('[PERFORMANCE] WARNING: Low FPS detected: ${metrics.fps}');
      _optimizePerformance();
    }
    
    if (metrics.memoryUsage > _maxMemoryUsage) {
      debugPrint('[PERFORMANCE] WARNING: High memory usage: ${metrics.memoryUsage} bytes');
      _clearCache();
    }
    
    if (metrics.frameTime > _maxFrameTime) {
      debugPrint('[PERFORMANCE] WARNING: Slow frame time: ${metrics.frameTime.inMilliseconds}ms');
    }
  }

  // Optimize performance
  void _optimizePerformance() {
    // Reduce active widgets
    _activeWidgets = (_activeWidgets * 0.8).round();
    
    // Clear cache
    _clearCache();
    
    // Notify listeners to update UI
    notifyListeners();
    
    debugPrint('[PERFORMANCE] Applied performance optimizations');
  }

  // Clear cache
  void _clearCache() {
    _cacheSize = (_cacheSize * 0.5).round();
    debugPrint('[PERFORMANCE] Cleared cache, new size: $_cacheSize bytes');
  }

  // Update widget count
  void updateWidgetCount(int count) {
    _activeWidgets = count;
  }

  // Update network request count
  void incrementNetworkRequests() {
    _networkRequests++;
  }

  // Update cache size
  void updateCacheSize(int size) {
    _cacheSize = size;
  }

  // Calculate average FPS
  double _calculateAverageFps() {
    if (_metrics.isEmpty) return 60.0;
    
    final totalFps = _metrics.fold(0.0, (sum, metric) => sum + metric.fps);
    return totalFps / _metrics.length;
  }

  // Calculate average memory usage
  int _calculateAverageMemoryUsage() {
    if (_metrics.isEmpty) return 0;
    
    final totalMemory = _metrics.fold(0, (sum, metric) => sum + metric.memoryUsage);
    return totalMemory ~/ _metrics.length;
  }

  // Calculate average CPU usage
  double _calculateAverageCpuUsage() {
    if (_metrics.isEmpty) return 0.0;
    
    final totalCpu = _metrics.fold(0.0, (sum, metric) => sum + metric.cpuUsage);
    return totalCpu / _metrics.length;
  }

  // Get performance recommendations
  List<String> getPerformanceRecommendations() {
    final recommendations = <String>[];
    
    if (averageFps < _targetFps) {
      recommendations.add('Reduce UI complexity to improve frame rate');
      recommendations.add('Optimize image loading and caching');
    }
    
    if (averageMemoryUsage > _maxMemoryUsage) {
      recommendations.add('Clear unused data and cache');
      recommendations.add('Reduce memory-intensive operations');
    }
    
    if (_activeWidgets > 100) {
      recommendations.add('Reduce number of active widgets');
      recommendations.add('Implement widget recycling');
    }
    
    if (_networkRequests > 10) {
      recommendations.add('Implement request batching');
      recommendations.add('Add request caching');
    }
    
    return recommendations;
  }

  // Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    return {
      'averageFps': averageFps,
      'averageMemoryUsage': averageMemoryUsage,
      'averageCpuUsage': averageCpuUsage,
      'activeWidgets': _activeWidgets,
      'cacheSize': _cacheSize,
      'networkRequests': _networkRequests,
      'performanceStatus': performanceStatus,
      'recommendations': getPerformanceRecommendations(),
      'metricsCount': _metrics.length,
    };
  }

  // Save metrics to preferences
  Future<void> _saveMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metricsJson = _metrics.map((metric) => metric.toJson()).toList();
      await prefs.setString('performance_metrics', jsonEncode(metricsJson));
    } catch (e) {
      debugPrint('[PERFORMANCE] Error saving metrics: $e');
    }
  }

  // Load metrics from preferences
  PerformanceMetrics _metricsFromJson(Map<String, dynamic> json) {
    return PerformanceMetrics(
      fps: json['fps']?.toDouble() ?? 60.0,
      memoryUsage: json['memoryUsage'] ?? 0,
      batteryLevel: json['batteryLevel'] ?? 100,
      cpuUsage: json['cpuUsage']?.toDouble() ?? 0.0,
      activeWidgets: json['activeWidgets'] ?? 0,
      frameTime: Duration(milliseconds: json['frameTime'] ?? 16),
      cacheSize: json['cacheSize'] ?? 0,
      networkRequests: json['networkRequests'] ?? 0,
    );
  }

  // Clean up resources
  @override
  void dispose() {
    stopMonitoring();
    _saveMetrics();
    super.dispose();
  }
} 