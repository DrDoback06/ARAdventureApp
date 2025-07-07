import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/adventure_system.dart';
import 'dart:convert';

enum ProximityStatus {
  far,        // > 500m away
  nearby,     // 100-500m away  
  close,      // 20-100m away
  veryClose,  // 5-20m away
  atLocation, // < 5m away
}

enum VerificationResult {
  success,
  tooFar,
  gpsInaccurate,
  movingTooFast,
  timeRequired,
  alreadyCompleted,
  noGpsSignal,
}

class LocationProgress {
  final String questId;
  final String objectiveId;
  final GeoLocation targetLocation;
  final double requiredRadius;
  final ProximityStatus proximityStatus;
  final double distanceToTarget;
  final DateTime firstDetected;
  final DateTime lastUpdate;
  final int timeSpentInRange; // seconds
  final int requiredTime; // seconds needed at location
  final bool isCompleted;
  final List<Position> locationHistory;

  LocationProgress({
    required this.questId,
    required this.objectiveId,
    required this.targetLocation,
    required this.requiredRadius,
    required this.proximityStatus,
    required this.distanceToTarget,
    required this.firstDetected,
    required this.lastUpdate,
    this.timeSpentInRange = 0,
    this.requiredTime = 0,
    this.isCompleted = false,
    List<Position>? locationHistory,
  }) : locationHistory = locationHistory ?? <Position>[];

  double get completionProgress {
    if (requiredTime <= 0) return isCompleted ? 1.0 : 0.0;
    return (timeSpentInRange / requiredTime).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() {
    return {
      'questId': questId,
      'objectiveId': objectiveId,
      'targetLocation': targetLocation.toJson(),
      'requiredRadius': requiredRadius,
      'proximityStatus': proximityStatus.index,
      'distanceToTarget': distanceToTarget,
      'firstDetected': firstDetected.toIso8601String(),
      'lastUpdate': lastUpdate.toIso8601String(),
      'timeSpentInRange': timeSpentInRange,
      'requiredTime': requiredTime,
      'isCompleted': isCompleted,
    };
  }

  static LocationProgress fromJson(Map<String, dynamic> json) {
    return LocationProgress(
      questId: json['questId'],
      objectiveId: json['objectiveId'],
      targetLocation: GeoLocation.fromJson(json['targetLocation']),
      requiredRadius: json['requiredRadius'],
      proximityStatus: ProximityStatus.values[json['proximityStatus']],
      distanceToTarget: json['distanceToTarget'],
      firstDetected: DateTime.parse(json['firstDetected']),
      lastUpdate: DateTime.parse(json['lastUpdate']),
      timeSpentInRange: json['timeSpentInRange'] ?? 0,
      requiredTime: json['requiredTime'] ?? 0,
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}

class LocationVerificationService {
  static final LocationVerificationService _instance = LocationVerificationService._internal();
  factory LocationVerificationService() => _instance;
  LocationVerificationService._internal();

  final StreamController<List<LocationProgress>> _progressController = 
      StreamController<List<LocationProgress>>.broadcast();
  final StreamController<LocationProgress> _completionController = 
      StreamController<LocationProgress>.broadcast();

  Timer? _trackingTimer;
  Position? _lastPosition;
  DateTime? _lastPositionTime;
  Map<String, LocationProgress> _activeTracking = {};
  List<Position> _locationHistory = [];
  
  // Anti-cheating settings
  static const double _maxReasonableSpeed = 30.0; // m/s (108 km/h)
  static const double _minGpsAccuracy = 50.0; // meters
  static const int _minTimeAtLocation = 10; // seconds
  static const int _maxLocationHistorySize = 100;

  Stream<List<LocationProgress>> get progressStream => _progressController.stream;
  Stream<LocationProgress> get completionStream => _completionController.stream;
  Map<String, LocationProgress> get activeTracking => _activeTracking;

  // Initialize the service
  Future<bool> initialize() async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return false;
      }

      // Load saved progress
      await _loadSavedProgress();
      
      return true;
    } catch (e) {
      print('Error initializing location verification: $e');
      return false;
    }
  }

  // Start tracking quest locations
  Future<void> startTracking(List<Quest> activeQuests) async {
    // Stop existing tracking
    await stopTracking();

    // Set up tracking for quest objectives with locations
    for (final quest in activeQuests) {
      for (final objective in quest.objectives) {
        if (_hasLocationRequirement(objective)) {
          await _addLocationTracking(quest, objective);
        }
      }
    }

    // Start position monitoring
    _trackingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _updateLocationTracking();
    });

    print('Started tracking ${_activeTracking.length} location objectives');
  }

  // Stop all tracking
  Future<void> stopTracking() async {
    _trackingTimer?.cancel();
    await _saveProgress();
  }

  // Add location tracking for a specific objective
  Future<void> _addLocationTracking(Quest quest, QuestObjective objective) async {
    final targetLocation = _extractLocationFromObjective(objective);
    final radius = _extractRadiusFromObjective(objective);
    final requiredTime = _extractTimeRequirement(objective);
    
    if (targetLocation != null) {
      final key = '${quest.id}_${objective.id}';
      _activeTracking[key] = LocationProgress(
        questId: quest.id,
        objectiveId: objective.id ?? '',
        targetLocation: targetLocation,
        requiredRadius: radius,
        proximityStatus: ProximityStatus.far,
        distanceToTarget: double.infinity,
        firstDetected: DateTime.now(),
        lastUpdate: DateTime.now(),
        requiredTime: requiredTime,
      );
    }
  }

  // Update location tracking
  Future<void> _updateLocationTracking() async {
    try {
      final position = await _getCurrentPosition();
      if (position == null) return;

      // Anti-cheating: Check for unrealistic movement
      if (_lastPosition != null && _lastPositionTime != null) {
        final distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        final timeDiff = DateTime.now().difference(_lastPositionTime!).inSeconds;
        if (timeDiff > 0) {
          final speed = distance / timeDiff;
          if (speed > _maxReasonableSpeed) {
            print('⚠️ Unrealistic movement detected: ${speed.toStringAsFixed(1)} m/s');
            return; // Skip this update
          }
        }
      }

      // Anti-cheating: Check GPS accuracy
      if (position.accuracy > _minGpsAccuracy) {
        print('⚠️ GPS accuracy too low: ${position.accuracy.toStringAsFixed(1)}m');
        return; // Skip this update
      }

      _lastPosition = position;
      _lastPositionTime = DateTime.now();

      // Add to location history
      _locationHistory.add(position);
      if (_locationHistory.length > _maxLocationHistorySize) {
        _locationHistory.removeRange(0, _locationHistory.length - _maxLocationHistorySize);
      }

      // Update all tracked locations
      final updatedProgress = <LocationProgress>[];
      for (final key in _activeTracking.keys) {
        final progress = await _updateLocationProgress(_activeTracking[key]!, position);
        if (progress != null) {
          _activeTracking[key] = progress;
          updatedProgress.add(progress);
          
          // Check for completion
          if (progress.isCompleted && !_activeTracking[key]!.isCompleted) {
            _completionController.add(progress);
          }
        }
      }

      // Notify listeners
      _progressController.add(updatedProgress);
      
    } catch (e) {
      print('Error updating location tracking: $e');
    }
  }

  // Update progress for a specific location
  Future<LocationProgress?> _updateLocationProgress(
    LocationProgress currentProgress,
    Position userPosition,
  ) async {
    final distance = Geolocator.distanceBetween(
      userPosition.latitude,
      userPosition.longitude,
      currentProgress.targetLocation.latitude,
      currentProgress.targetLocation.longitude,
    );

    final proximityStatus = _calculateProximityStatus(distance);
    final isInRange = distance <= currentProgress.requiredRadius;
    final now = DateTime.now();

    // Calculate time spent in range
    int timeSpentInRange = currentProgress.timeSpentInRange;
    if (isInRange && currentProgress.proximityStatus != ProximityStatus.far) {
      final timeDiff = now.difference(currentProgress.lastUpdate).inSeconds;
      timeSpentInRange += timeDiff;
    }

    // Check if objective is completed
    bool isCompleted = currentProgress.isCompleted;
    if (!isCompleted && isInRange) {
      if (currentProgress.requiredTime > 0) {
        // Time-based completion
        isCompleted = timeSpentInRange >= currentProgress.requiredTime;
      } else {
        // Location-based completion (just need to reach the spot)
        isCompleted = distance <= math.min(currentProgress.requiredRadius, 20.0);
      }
    }

    return LocationProgress(
      questId: currentProgress.questId,
      objectiveId: currentProgress.objectiveId,
      targetLocation: currentProgress.targetLocation,
      requiredRadius: currentProgress.requiredRadius,
      proximityStatus: proximityStatus,
      distanceToTarget: distance,
      firstDetected: currentProgress.firstDetected,
      lastUpdate: now,
      timeSpentInRange: timeSpentInRange,
      requiredTime: currentProgress.requiredTime,
      isCompleted: isCompleted,
      locationHistory: [...currentProgress.locationHistory, userPosition],
    );
  }

  // Get current position with error handling
  Future<Position?> _getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5, // Only update if moved 5m
        ),
      );
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  // Calculate proximity status based on distance
  ProximityStatus _calculateProximityStatus(double distance) {
    if (distance < 5) return ProximityStatus.atLocation;
    if (distance < 20) return ProximityStatus.veryClose;
    if (distance < 100) return ProximityStatus.close;
    if (distance < 500) return ProximityStatus.nearby;
    return ProximityStatus.far;
  }

  // Verify quest completion with anti-cheating measures
  Future<VerificationResult> verifyQuestCompletion(
    String questId,
    String objectiveId,
  ) async {
    final key = '${questId}_$objectiveId';
    final progress = _activeTracking[key];
    
    if (progress == null) {
      return VerificationResult.noGpsSignal;
    }

    if (progress.isCompleted) {
      return VerificationResult.alreadyCompleted;
    }

    if (progress.distanceToTarget > progress.requiredRadius) {
      return VerificationResult.tooFar;
    }

    final currentPosition = await _getCurrentPosition();
    if (currentPosition == null) {
      return VerificationResult.noGpsSignal;
    }

    if (currentPosition.accuracy > _minGpsAccuracy) {
      return VerificationResult.gpsInaccurate;
    }

    // Check if enough time has been spent at location
    if (progress.requiredTime > 0 && 
        progress.timeSpentInRange < progress.requiredTime) {
      return VerificationResult.timeRequired;
    }

    return VerificationResult.success;
  }

  // Get user-friendly status message
  String getStatusMessage(LocationProgress progress) {
    switch (progress.proximityStatus) {
      case ProximityStatus.atLocation:
        if (progress.requiredTime > 0) {
          final remaining = progress.requiredTime - progress.timeSpentInRange;
          if (remaining > 0) {
            return 'Stay here for ${remaining}s more!';
          }
          return '✅ Objective completed!';
        }
        return '✅ You\'ve reached the location!';
      case ProximityStatus.veryClose:
        return '🎯 Very close! ${progress.distanceToTarget.round()}m away';
      case ProximityStatus.close:
        return '📍 Getting close! ${progress.distanceToTarget.round()}m away';
      case ProximityStatus.nearby:
        return '🚶 Head this way! ${(progress.distanceToTarget / 1000).toStringAsFixed(1)}km away';
      case ProximityStatus.far:
        return '🗺️ ${(progress.distanceToTarget / 1000).toStringAsFixed(1)}km to destination';
    }
  }

  // Helper methods for extracting location data from objectives
  bool _hasLocationRequirement(QuestObjective objective) {
    return objective.type == 'location_visit' ||
           objective.type == 'location_time' ||
           objective.requirements?.containsKey('location') == true;
  }

  GeoLocation? _extractLocationFromObjective(QuestObjective objective) {
    final locationData = objective.requirements?['location'];
    if (locationData is Map<String, dynamic>) {
      return GeoLocation.fromJson(locationData);
    }
    return null;
  }

  double _extractRadiusFromObjective(QuestObjective objective) {
    return (objective.requirements?['radius'] as num?)?.toDouble() ?? 50.0;
  }

  int _extractTimeRequirement(QuestObjective objective) {
    if (objective.type == 'location_time') {
      return (objective.requirements?['time_minutes'] as num?)?.toInt() ?? 0 * 60;
    }
    return 0;
  }

  // Get proximity percentage (for UI progress bars)
  double getProximityPercentage(LocationProgress progress) {
    if (progress.distanceToTarget <= progress.requiredRadius) {
      return 1.0;
    }
    
    // Scale from 0% at 1km to 100% at required radius
    final maxDistance = math.max(1000.0, progress.requiredRadius * 2);
    final percentage = 1.0 - (progress.distanceToTarget / maxDistance);
    return percentage.clamp(0.0, 1.0);
  }

  // Data persistence
  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressData = <String, dynamic>{};
      
      _activeTracking.forEach((key, progress) {
        progressData[key] = progress.toJson();
      });
      
      await prefs.setString('location_verification_progress', jsonEncode(progressData));
    } catch (e) {
      print('Error saving location progress: $e');
    }
  }

  Future<void> _loadSavedProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString('location_verification_progress');
      
      if (progressJson != null) {
        final progressData = jsonDecode(progressJson) as Map<String, dynamic>;
        
        progressData.forEach((key, value) {
          try {
            _activeTracking[key] = LocationProgress.fromJson(value);
          } catch (e) {
            print('Error loading progress for $key: $e');
          }
        });
      }
    } catch (e) {
      print('Error loading saved progress: $e');
    }
  }

  // Cleanup method
  void dispose() {
    _trackingTimer?.cancel();
    _progressController.close();
    _completionController.close();
  }
} 