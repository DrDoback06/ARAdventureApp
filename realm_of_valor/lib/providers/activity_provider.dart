import 'package:flutter/material.dart';
import '../models/activity_model.dart';
import '../services/activity_tracking_service.dart';

class ActivityProvider extends ChangeNotifier {
  ActivityTrackingService? _activityService;
  ActivityData? _currentActivity;
  List<ActivityLog> _recentActivities = [];
  bool _isTracking = false;
  String _currentStatus = 'Resting';
  String? _connectedDevice;

  // Getters
  ActivityData? get currentActivity => _currentActivity;
  List<ActivityLog> get recentActivities => _recentActivities;
  bool get isTracking => _isTracking;
  String get currentStatus => _currentStatus;
  String? get connectedDevice => _connectedDevice;

  // Initialize activity tracking service
  void initialize() {
    _activityService = ActivityTrackingService.instance;
    _loadRecentActivities();
    _checkDeviceConnection();
  }

  // Start activity tracking
  Future<void> startTracking(ActivityType type) async {
    if (_activityService == null) return;

    try {
      await _activityService!.startTracking(type);
      _isTracking = true;
      _currentStatus = _getStatusForActivity(type);
      _currentActivity = ActivityData(
        type: type,
        startTime: DateTime.now(),
        distance: 0,
        calories: 0,
        steps: 0,
        duration: Duration.zero,
      );
      notifyListeners();
      
      // Start listening to activity updates
      _activityService!.activityStream.listen(_onActivityUpdate);
      
      print('DEBUG: Started tracking ${type.name}');
    } catch (e) {
      print('DEBUG: Error starting activity tracking: $e');
    }
  }

  // Stop activity tracking
  Future<void> stopTracking() async {
    if (_activityService == null || !_isTracking) return;

    try {
      final activityData = await _activityService!.stopTracking();
      if (activityData != null) {
        _addActivityLog(activityData);
      }
      
      _isTracking = false;
      _currentStatus = 'Resting';
      _currentActivity = null;
      notifyListeners();
      
      print('DEBUG: Stopped activity tracking');
    } catch (e) {
      print('DEBUG: Error stopping activity tracking: $e');
    }
  }

  // Manual activity logging
  void logManualActivity(ActivityData activityData) {
    _addActivityLog(activityData);
    print('DEBUG: Manually logged activity: ${activityData.type.name}');
  }

  // Check for connected fitness devices
  Future<void> _checkDeviceConnection() async {
    if (_activityService == null) return;

    try {
      _connectedDevice = await _activityService!.getConnectedDevice();
      notifyListeners();
      print('DEBUG: Connected device: $_connectedDevice');
    } catch (e) {
      print('DEBUG: Error checking device connection: $e');
    }
  }

  // Handle activity updates from tracking service
  void _onActivityUpdate(ActivityData activityData) {
    _currentActivity = activityData;
    notifyListeners();
    print('DEBUG: Activity update - ${activityData.type.name}: ${activityData.distance}m');
  }

  // Add activity to recent logs
  void _addActivityLog(ActivityData activityData) {
    final activityLog = ActivityLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: activityData.type,
      startTime: activityData.startTime,
      endTime: DateTime.now(),
      duration: activityData.duration,
      distance: activityData.distance,
      calories: activityData.calories,
      steps: activityData.steps,
    );

    _recentActivities.insert(0, activityLog);
    
    // Keep only last 50 activities
    if (_recentActivities.length > 50) {
      _recentActivities = _recentActivities.take(50).toList();
    }

    notifyListeners();
    print('DEBUG: Added activity log: ${activityLog.type.name}');
  }

  // Load recent activities from storage
  Future<void> _loadRecentActivities() async {
    // TODO: Load from local storage or database
    // For now, using empty list
    _recentActivities = [];
  }

  // Get status string for activity type
  String _getStatusForActivity(ActivityType type) {
    switch (type) {
      case ActivityType.running:
        return 'Running';
      case ActivityType.walking:
        return 'Walking';
      case ActivityType.cycling:
        return 'Cycling';
      case ActivityType.gym:
        return 'Training';
      case ActivityType.adventure:
        return 'Adventuring';
      case ActivityType.yoga:
        return 'Meditating';
      default:
        return 'Active';
    }
  }

  // Get activity statistics
  Map<String, dynamic> getActivityStats() {
    if (_recentActivities.isEmpty) {
      return {
        'totalDistance': 0,
        'totalCalories': 0,
        'totalSteps': 0,
        'totalDuration': Duration.zero,
        'activitiesThisWeek': 0,
        'activitiesThisMonth': 0,
      };
    }

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = now.subtract(const Duration(days: 30));

    int totalDistance = 0;
    int totalCalories = 0;
    int totalSteps = 0;
    Duration totalDuration = Duration.zero;
    int activitiesThisWeek = 0;
    int activitiesThisMonth = 0;

    for (final activity in _recentActivities) {
      totalDistance += activity.distance;
      totalCalories += activity.calories;
      totalSteps += activity.steps;
      totalDuration += activity.duration;

      if (activity.startTime.isAfter(weekAgo)) {
        activitiesThisWeek++;
      }
      if (activity.startTime.isAfter(monthAgo)) {
        activitiesThisMonth++;
      }
    }

    return {
      'totalDistance': totalDistance,
      'totalCalories': totalCalories,
      'totalSteps': totalSteps,
      'totalDuration': totalDuration,
      'activitiesThisWeek': activitiesThisWeek,
      'activitiesThisMonth': activitiesThisMonth,
    };
  }

  // Get current activity summary
  Map<String, dynamic> getCurrentActivitySummary() {
    if (_currentActivity == null) {
      return {
        'isActive': false,
        'status': _currentStatus,
        'duration': Duration.zero,
        'distance': 0,
        'calories': 0,
        'steps': 0,
      };
    }

    return {
      'isActive': _isTracking,
      'status': _currentStatus,
      'duration': _currentActivity!.duration,
      'distance': _currentActivity!.distance,
      'calories': _currentActivity!.calories,
      'steps': _currentActivity!.steps,
    };
  }

  @override
  void dispose() {
    _activityService?.dispose();
    super.dispose();
  }
} 