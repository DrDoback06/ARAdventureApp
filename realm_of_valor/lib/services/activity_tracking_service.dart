import 'dart:async';
import '../models/activity_model.dart';

class ActivityTrackingService {
  static ActivityTrackingService? _instance;
  static ActivityTrackingService get instance => _instance ??= ActivityTrackingService._();

  ActivityTrackingService._();

  // Stream controllers
  final StreamController<ActivityData> _activityController = StreamController<ActivityData>.broadcast();
  final StreamController<String> _deviceStatusController = StreamController<String>.broadcast();

  // Activity tracking state
  ActivityType? _currentActivityType;
  DateTime? _activityStartTime;
  Timer? _updateTimer;
  bool _isTracking = false;

  // Data sources
  FitnessTracker? _fitnessTracker;
  GPSTracker? _gpsTracker;
  ManualTracker? _manualTracker;

  // Current activity data
  ActivityData? _currentActivityData;

  // Getters
  Stream<ActivityData> get activityStream => _activityController.stream;
  Stream<String> get deviceStatusStream => _deviceStatusController.stream;
  bool get isTracking => _isTracking;
  ActivityData? get currentActivityData => _currentActivityData;

  // Initialize the service
  Future<void> initialize() async {
    print('DEBUG: Initializing ActivityTrackingService');
    
    // Initialize data sources
    _fitnessTracker = FitnessTracker();
    _gpsTracker = GPSTracker();
    _manualTracker = ManualTracker();
    
    // Check for connected devices
    await _checkDeviceConnection();
    
    print('DEBUG: ActivityTrackingService initialized');
  }

  // Start tracking an activity
  Future<void> startTracking(ActivityType activityType) async {
    if (_isTracking) {
      print('DEBUG: Already tracking an activity');
      return;
    }

    try {
      _currentActivityType = activityType;
      _activityStartTime = DateTime.now();
      _isTracking = true;

      // Initialize activity data
      _currentActivityData = ActivityData(
        type: activityType,
        startTime: _activityStartTime!,
        distance: 0,
        calories: 0,
        steps: 0,
        duration: Duration.zero,
      );

      // Start data collection from available sources
      await _startDataCollection();

      // Start update timer
      _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _updateActivityData();
      });

      print('DEBUG: Started tracking ${activityType.name}');
    } catch (e) {
      print('DEBUG: Error starting activity tracking: $e');
      rethrow;
    }
  }

  // Stop tracking and return final activity data
  Future<ActivityData?> stopTracking() async {
    if (!_isTracking) {
      print('DEBUG: No activity to stop');
      return null;
    }

    try {
      _isTracking = false;
      _updateTimer?.cancel();
      _updateTimer = null;

      // Stop data collection
      await _stopDataCollection();

      // Calculate final activity data
      final finalActivityData = _currentActivityData;
      _currentActivityData = null;
      _currentActivityType = null;
      _activityStartTime = null;

      print('DEBUG: Stopped tracking activity');
      return finalActivityData;
    } catch (e) {
      print('DEBUG: Error stopping activity tracking: $e');
      rethrow;
    }
  }

  // Start data collection from available sources
  Future<void> _startDataCollection() async {
    // Priority: Fitness Tracker > GPS > Manual
    if (await _fitnessTracker!.isConnected()) {
      await _fitnessTracker!.startTracking();
      print('DEBUG: Using fitness tracker for data collection');
    } else if (await _gpsTracker!.isAvailable()) {
      await _gpsTracker!.startTracking();
      print('DEBUG: Using GPS for data collection');
    } else {
      await _manualTracker!.startTracking();
      print('DEBUG: Using manual tracking');
    }
  }

  // Stop data collection
  Future<void> _stopDataCollection() async {
    await _fitnessTracker?.stopTracking();
    await _gpsTracker?.stopTracking();
    await _manualTracker?.stopTracking();
  }

  // Update activity data from all sources
  void _updateActivityData() {
    if (!_isTracking || _currentActivityData == null) return;

    // Get data from the active source
    final newData = _getCurrentSourceData();
    if (newData != null) {
      _currentActivityData = newData;
      _activityController.add(_currentActivityData!);
    }
  }

  // Get current data from the active source
  ActivityData? _getCurrentSourceData() {
    if (_fitnessTracker?.isActive == true) {
      return _fitnessTracker!.getCurrentData();
    } else if (_gpsTracker?.isActive == true) {
      return _gpsTracker!.getCurrentData();
    } else if (_manualTracker?.isActive == true) {
      return _manualTracker!.getCurrentData();
    }
    return null;
  }

  // Check for connected fitness devices
  Future<String?> getConnectedDevice() async {
    try {
      if (await _fitnessTracker!.isConnected()) {
        final deviceName = await _fitnessTracker!.getDeviceName();
        _deviceStatusController.add('Connected: $deviceName');
        return deviceName;
      } else {
        _deviceStatusController.add('No fitness device connected');
        return null;
      }
    } catch (e) {
      print('DEBUG: Error checking device connection: $e');
      _deviceStatusController.add('Error checking device');
      return null;
    }
  }

  // Check device connection status
  Future<void> _checkDeviceConnection() async {
    await getConnectedDevice();
  }

  // Manual activity logging
  Future<void> logManualActivity(ActivityData activityData) async {
    try {
      // Save to local storage
      await _saveActivityLog(activityData);
      
      // Notify listeners
      _activityController.add(activityData);
      
      print('DEBUG: Manually logged activity: ${activityData.type.name}');
    } catch (e) {
      print('DEBUG: Error logging manual activity: $e');
      rethrow;
    }
  }

  // Save activity log to local storage
  Future<void> _saveActivityLog(ActivityData activityData) async {
    // TODO: Implement local storage
    // For now, just print to console
    print('DEBUG: Saving activity log: ${activityData.toJson()}');
  }

  // Get activity statistics
  Future<Map<String, dynamic>> getActivityStats() async {
    // TODO: Load from local storage
    return {
      'totalDistance': 0,
      'totalCalories': 0,
      'totalSteps': 0,
      'totalDuration': Duration.zero,
      'activitiesThisWeek': 0,
      'activitiesThisMonth': 0,
    };
  }

  // Dispose resources
  void dispose() {
    _updateTimer?.cancel();
    _activityController.close();
    _deviceStatusController.close();
    _fitnessTracker?.dispose();
    _gpsTracker?.dispose();
    _manualTracker?.dispose();
  }
}

// Fitness Tracker Implementation
class FitnessTracker {
  bool _isConnected = false;
  bool _isActive = false;
  ActivityData? _currentData;

  bool get isActive => _isActive;

  Future<bool> isConnected() async {
    // TODO: Implement actual fitness device connection check
    // For now, simulate connection
    _isConnected = true;
    return _isConnected;
  }

  Future<String> getDeviceName() async {
    // TODO: Get actual device name
    return 'Simulated Fitness Tracker';
  }

  Future<void> startTracking() async {
    _isActive = true;
    _currentData = ActivityData(
      type: ActivityType.running,
      startTime: DateTime.now(),
      distance: 0,
      calories: 0,
      steps: 0,
      duration: Duration.zero,
    );
  }

  Future<void> stopTracking() async {
    _isActive = false;
    _currentData = null;
  }

  ActivityData? getCurrentData() {
    if (!_isActive) return null;
    
    // Simulate data updates
    if (_currentData != null) {
      final now = DateTime.now();
      final duration = now.difference(_currentData!.startTime);
      
      // Simulate some activity data
      final simulatedDistance = (duration.inSeconds * 2).toDouble(); // 2 m/s
      final simulatedCalories = (duration.inMinutes * 8).toDouble(); // 8 cal/min
      final simulatedSteps = (duration.inSeconds * 2).toDouble(); // 2 steps/sec
      
      _currentData = ActivityData(
        type: _currentData!.type,
        startTime: _currentData!.startTime,
        distance: simulatedDistance.round(),
        calories: simulatedCalories.round(),
        steps: simulatedSteps.round(),
        duration: duration,
        speed: 2.0, // 2 m/s
        heartRate: 140.0, // 140 bpm
      );
    }
    
    return _currentData;
  }

  void dispose() {
    _isActive = false;
    _currentData = null;
  }
}

// GPS Tracker Implementation
class GPSTracker {
  bool _isAvailable = false;
  bool _isActive = false;
  ActivityData? _currentData;

  bool get isActive => _isActive;

  Future<bool> isAvailable() async {
    // TODO: Check GPS availability
    _isAvailable = true;
    return _isAvailable;
  }

  Future<void> startTracking() async {
    _isActive = true;
    _currentData = ActivityData(
      type: ActivityType.walking,
      startTime: DateTime.now(),
      distance: 0,
      calories: 0,
      steps: 0,
      duration: Duration.zero,
    );
  }

  Future<void> stopTracking() async {
    _isActive = false;
    _currentData = null;
  }

  ActivityData? getCurrentData() {
    if (!_isActive) return null;
    
    // Simulate GPS data
    if (_currentData != null) {
      final now = DateTime.now();
      final duration = now.difference(_currentData!.startTime);
      
      // Simulate walking data
      final simulatedDistance = (duration.inSeconds * 1.5).toDouble(); // 1.5 m/s walking
      final simulatedCalories = (duration.inMinutes * 5).toDouble(); // 5 cal/min walking
      final simulatedSteps = (duration.inSeconds * 1.5).toDouble(); // 1.5 steps/sec
      
      _currentData = ActivityData(
        type: _currentData!.type,
        startTime: _currentData!.startTime,
        distance: simulatedDistance.round(),
        calories: simulatedCalories.round(),
        steps: simulatedSteps.round(),
        duration: duration,
        speed: 1.5, // 1.5 m/s
        elevation: 0.0, // Flat ground
      );
    }
    
    return _currentData;
  }

  void dispose() {
    _isActive = false;
    _currentData = null;
  }
}

// Manual Tracker Implementation
class ManualTracker {
  bool _isActive = false;
  ActivityData? _currentData;

  bool get isActive => _isActive;

  Future<void> startTracking() async {
    _isActive = true;
    _currentData = ActivityData(
      type: ActivityType.other,
      startTime: DateTime.now(),
      distance: 0,
      calories: 0,
      steps: 0,
      duration: Duration.zero,
    );
  }

  Future<void> stopTracking() async {
    _isActive = false;
    _currentData = null;
  }

  ActivityData? getCurrentData() {
    if (!_isActive) return null;
    
    // Manual tracking doesn't auto-update
    return _currentData;
  }

  // Update manual activity data
  void updateData({
    int? distance,
    int? calories,
    int? steps,
    double? speed,
    double? elevation,
  }) {
    if (_currentData != null && _isActive) {
      final now = DateTime.now();
      final duration = now.difference(_currentData!.startTime);
      
      _currentData = ActivityData(
        type: _currentData!.type,
        startTime: _currentData!.startTime,
        distance: distance ?? _currentData!.distance,
        calories: calories ?? _currentData!.calories,
        steps: steps ?? _currentData!.steps,
        duration: duration,
        speed: speed ?? _currentData!.speed,
        elevation: elevation ?? _currentData!.elevation,
      );
    }
  }

  void dispose() {
    _isActive = false;
    _currentData = null;
  }
} 