import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/physical_activity_model.dart';
import '../models/character_model.dart';

enum FitnessTracker {
  appleWatch,
  wearOS,
  fitbit,
  garmin,
  samsung,
  polar,
  suunto,
  generic,
}

enum HeartRateZone {
  resting,    // < 50% max HR
  fatBurn,    // 50-60% max HR
  aerobic,    // 60-70% max HR  
  anaerobic,  // 70-85% max HR
  peak,       // 85%+ max HR
}

class RealTimeMetrics {
  final int? heartRate;
  final HeartRateZone? heartRateZone;
  final int steps;
  final double calories;
  final double distance;
  final bool isWorkingOut;
  final double energyLevel; // 0.0 to 1.0
  final double stressLevel; // 0.0 to 1.0
  final DateTime timestamp;

  RealTimeMetrics({
    this.heartRate,
    this.heartRateZone,
    this.steps = 0,
    this.calories = 0.0,
    this.distance = 0.0,
    this.isWorkingOut = false,
    this.energyLevel = 0.7,
    this.stressLevel = 0.5,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'heartRate': heartRate,
      'heartRateZone': heartRateZone?.toString(),
      'steps': steps,
      'calories': calories,
      'distance': distance,
      'isWorkingOut': isWorkingOut,
      'energyLevel': energyLevel,
      'stressLevel': stressLevel,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class FitnessStatBoosts {
  final List<StatBoost> realTimeBoosts;
  final List<StatBoost> dailyBoosts;
  final List<StatBoost> weeklyBoosts;
  final Map<String, double> multipliers;

  FitnessStatBoosts({
    List<StatBoost>? realTimeBoosts,
    List<StatBoost>? dailyBoosts,
    List<StatBoost>? weeklyBoosts,
    Map<String, double>? multipliers,
  })  : realTimeBoosts = realTimeBoosts ?? <StatBoost>[],
        dailyBoosts = dailyBoosts ?? <StatBoost>[],
        weeklyBoosts = weeklyBoosts ?? <StatBoost>[],
        multipliers = multipliers ?? <String, double>{};

  List<StatBoost> get allActiveBoosts {
    return [
      ...realTimeBoosts,
      ...dailyBoosts,
      ...weeklyBoosts,
    ].where((boost) => !boost.isExpired).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'realTimeBoosts': realTimeBoosts.map((b) => b.toJson()).toList(),
      'dailyBoosts': dailyBoosts.map((b) => b.toJson()).toList(),
      'weeklyBoosts': weeklyBoosts.map((b) => b.toJson()).toList(),
      'multipliers': multipliers,
    };
  }
}

class FitnessTrackerService {
  static final FitnessTrackerService _instance = FitnessTrackerService._internal();
  factory FitnessTrackerService() => _instance;
  FitnessTrackerService._internal();

  // Platform channels for native integrations
  static const MethodChannel _appleWatchChannel = MethodChannel('apple_watch');
  static const MethodChannel _wearOSChannel = MethodChannel('wear_os');
  static const MethodChannel _fitbitChannel = MethodChannel('fitbit');
  static const MethodChannel _garminChannel = MethodChannel('garmin');

  // Health plugin for cross-platform health data
  final Health _health = Health();

  // State management
  Timer? _realTimeTimer;
  final StreamController<RealTimeMetrics> _metricsController = 
      StreamController<RealTimeMetrics>.broadcast();
  final StreamController<FitnessStatBoosts> _boostsController = 
      StreamController<FitnessStatBoosts>.broadcast();

  RealTimeMetrics? _latestMetrics;
  FitnessStatBoosts _currentBoosts = FitnessStatBoosts();
  Set<FitnessTracker> _connectedTrackers = <FitnessTracker>{};
  int _maxHeartRate = 190; // Default, should be calculated or configured per user

  // Streams for external listening
  Stream<RealTimeMetrics> get metricsStream => _metricsController.stream;
  Stream<FitnessStatBoosts> get boostsStream => _boostsController.stream;
  
  // Getters
  RealTimeMetrics? get latestMetrics => _latestMetrics;
  FitnessStatBoosts get currentBoosts => _currentBoosts;
  Set<FitnessTracker> get connectedTrackers => Set.from(_connectedTrackers);

  // Initialize the fitness tracker service
  Future<bool> initialize() async {
    try {
      // Request permissions for health data
      final types = [
        HealthDataType.HEART_RATE,
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.DISTANCE_WALKING_RUNNING,
        HealthDataType.WORKOUT,
      ];

      final permissions = await _health.requestAuthorization(types);
      if (!permissions) {
        print('Health permissions not granted');
        return false;
      }

      await loadPreferences();
      await _startRealTimeMonitoring();
      
      return true;
    } catch (e) {
      print('Error initializing fitness tracker: $e');
      return false;
    }
  }

  // Start real-time monitoring
  Future<void> _startRealTimeMonitoring() async {
    _realTimeTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _updateRealTimeMetrics();
    });

    // Initial update
    await _updateRealTimeMetrics();
  }

  // Update real-time metrics
  Future<void> _updateRealTimeMetrics() async {
    try {
      final now = DateTime.now();
      final startTime = now.subtract(const Duration(minutes: 5));

      // Get latest health data
      final healthData = await _health.getHealthDataFromTypes(
        types: [
          HealthDataType.HEART_RATE,
          HealthDataType.STEPS,
          HealthDataType.ACTIVE_ENERGY_BURNED,
          HealthDataType.DISTANCE_WALKING_RUNNING,
        ],
        startTime: startTime,
        endTime: now,
      );

      int? latestHeartRate;
      int totalSteps = 0;
      double totalCalories = 0;
      double totalDistance = 0;

      for (var point in healthData) {
        if (point.value is NumericHealthValue) {
          final value = (point.value as NumericHealthValue).numericValue;
          
          switch (point.type) {
            case HealthDataType.HEART_RATE:
              latestHeartRate = value.toInt();
              break;
            case HealthDataType.STEPS:
              totalSteps += value.toInt();
              break;
            case HealthDataType.ACTIVE_ENERGY_BURNED:
              totalCalories += value.toDouble();
              break;
            case HealthDataType.DISTANCE_WALKING_RUNNING:
              totalDistance += value.toDouble();
              break;
            default:
              break;
          }
        }
      }

      // Calculate heart rate zone
      HeartRateZone? heartRateZone;
      if (latestHeartRate != null) {
        final hrPercent = latestHeartRate / _maxHeartRate;
        if (hrPercent < 0.5) {
          heartRateZone = HeartRateZone.resting;
        } else if (hrPercent < 0.6) {
          heartRateZone = HeartRateZone.fatBurn;
        } else if (hrPercent < 0.7) {
          heartRateZone = HeartRateZone.aerobic;
        } else if (hrPercent < 0.85) {
          heartRateZone = HeartRateZone.anaerobic;
        } else {
          heartRateZone = HeartRateZone.peak;
        }
      }

      // Detect if user is working out (simplified logic)
      final isWorkingOut = latestHeartRate != null && 
                          latestHeartRate > (_maxHeartRate * 0.6) &&
                          totalSteps > 50; // Moving with elevated heart rate

      // Create metrics object
      final metrics = RealTimeMetrics(
        heartRate: latestHeartRate,
        heartRateZone: heartRateZone,
        steps: totalSteps,
        calories: totalCalories,
        distance: totalDistance,
        isWorkingOut: isWorkingOut,
        energyLevel: _calculateEnergyLevel(latestHeartRate, totalSteps),
        stressLevel: _calculateStressLevel(latestHeartRate),
      );

      _latestMetrics = metrics;
      _metricsController.add(metrics);

      // Update stat boosts based on current metrics
      await _updateStatBoosts(metrics);

    } catch (e) {
      print('Error updating real-time metrics: $e');
    }
  }

  // Calculate energy level based on activity
  double _calculateEnergyLevel(int? heartRate, int steps) {
    double energy = 0.7; // Base energy level

    // Heart rate contribution
    if (heartRate != null) {
      final hrPercent = heartRate / _maxHeartRate;
      if (hrPercent > 0.8) {
        energy = math.max(0.9, energy); // High intensity = high energy
      } else if (hrPercent < 0.4) {
        energy = math.min(0.5, energy); // Very low HR = low energy
      }
    }

    // Steps contribution (recent activity)
    if (steps > 100) {
      energy = math.min(1.0, energy + 0.2);
    } else if (steps < 10) {
      energy = math.max(0.3, energy - 0.2);
    }

    return energy.clamp(0.0, 1.0);
  }

  // Calculate stress level based on heart rate variability (simplified)
  double _calculateStressLevel(int? heartRate) {
    if (heartRate == null) return 0.5;

    final hrPercent = heartRate / _maxHeartRate;
    
    // High heart rate when not exercising indicates stress
    if (hrPercent > 0.7 && !(_latestMetrics?.isWorkingOut ?? false)) {
      return 0.8;
    } else if (hrPercent < 0.4) {
      return 0.2; // Very relaxed
    }
    
    return 0.4; // Normal
  }

  // Update stat boosts based on current metrics
  Future<void> _updateStatBoosts(RealTimeMetrics metrics) async {
    final realTimeBoosts = <StatBoost>[];
    final multipliers = <String, double>{};

    // Heart rate zone effects
    if (metrics.heartRateZone != null) {
      switch (metrics.heartRateZone!) {
        case HeartRateZone.resting:
          realTimeBoosts.add(StatBoost(
            name: 'Resting State',
            description: 'Calm and focused mind',
            statType: 'intelligence',
            bonusValue: 5,
            sourceActivity: ActivityType.other,
            expiresAt: DateTime.now().add(const Duration(minutes: 30)),
          ));
          break;
        case HeartRateZone.fatBurn:
          realTimeBoosts.add(StatBoost(
            name: 'Fat Burn Zone',
            description: 'Optimal metabolism for endurance',
            statType: 'vitality',
            bonusValue: 8,
            sourceActivity: ActivityType.cardio,
            expiresAt: DateTime.now().add(const Duration(minutes: 30)),
          ));
          break;
        case HeartRateZone.aerobic:
          realTimeBoosts.add(StatBoost(
            name: 'Aerobic Power',
            description: 'Enhanced cardiovascular performance',
            statType: 'vitality',
            bonusValue: 12,
            sourceActivity: ActivityType.cardio,
            expiresAt: DateTime.now().add(const Duration(minutes: 30)),
          ));
          realTimeBoosts.add(StatBoost(
            name: 'Athletic Prowess',
            description: 'Active heart rate boosts agility',
            statType: 'dexterity',
            bonusValue: 6,
            sourceActivity: ActivityType.cardio,
            expiresAt: DateTime.now().add(const Duration(minutes: 30)),
          ));
          break;
        case HeartRateZone.anaerobic:
          realTimeBoosts.add(StatBoost(
            name: 'Anaerobic Power',
            description: 'High intensity training effects',
            statType: 'strength',
            bonusValue: 15,
            sourceActivity: ActivityType.cardio,
            expiresAt: DateTime.now().add(const Duration(minutes: 30)),
          ));
          multipliers['combat_damage'] = 1.2;
          break;
        case HeartRateZone.peak:
          realTimeBoosts.add(StatBoost(
            name: 'Peak Performance',
            description: 'Maximum effort unleashes potential',
            statType: 'strength',
            bonusValue: 20,
            sourceActivity: ActivityType.cardio,
            expiresAt: DateTime.now().add(const Duration(minutes: 30)),
          ));
          multipliers['combat_damage'] = 1.4;
          multipliers['movement_speed'] = 1.3;
          break;
      }
    }

    // Energy level effects
    if (metrics.energyLevel > 0.8) {
      realTimeBoosts.add(StatBoost(
        name: 'High Energy',
        description: 'Feeling energized and ready for action',
        statType: 'vitality',
        bonusValue: 10,
        sourceActivity: ActivityType.other,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      ));
      multipliers['experience_gain'] = 1.15;
    } else if (metrics.energyLevel < 0.3) {
      realTimeBoosts.add(StatBoost(
        name: 'Exhausted',
        description: 'Low energy affects performance',
        statType: 'vitality',
        bonusValue: -5,
        sourceActivity: ActivityType.other,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      ));
      multipliers['experience_gain'] = 0.9;
    }

    // Workout bonus
    if (metrics.isWorkingOut) {
      realTimeBoosts.add(StatBoost(
        name: 'Active Workout',
        description: 'Currently exercising - all stats boosted!',
        statType: 'all',
        bonusValue: 8,
        sourceActivity: ActivityType.other,
        expiresAt: DateTime.now().add(const Duration(minutes: 45)),
      ));
      multipliers['experience_gain'] = 1.25;
      multipliers['loot_chance'] = 1.1;
    }

    // Get daily activity boosts
    final dailyBoosts = await _getDailyActivityBoosts();
    final weeklyBoosts = await _getWeeklyActivityBoosts();

    _currentBoosts = FitnessStatBoosts(
      realTimeBoosts: realTimeBoosts,
      dailyBoosts: dailyBoosts,
      weeklyBoosts: weeklyBoosts,
      multipliers: multipliers,
    );
  }

  // Get daily activity boosts
  Future<List<StatBoost>> _getDailyActivityBoosts() async {
    final boosts = <StatBoost>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    try {
      // Get today's health data
      final healthData = await _health.getHealthDataFromTypes(
        types: [
          HealthDataType.STEPS,
          HealthDataType.ACTIVE_ENERGY_BURNED,
          HealthDataType.WORKOUT,
        ],
        startTime: today,
        endTime: now,
      );

      int totalSteps = 0;
      double totalCalories = 0;
      int workoutMinutes = 0;

      for (var point in healthData) {
        if (point.value is NumericHealthValue) {
          final value = (point.value as NumericHealthValue).numericValue;
          
          switch (point.type) {
            case HealthDataType.STEPS:
              totalSteps += value.toInt();
              break;
            case HealthDataType.ACTIVE_ENERGY_BURNED:
              totalCalories += value.toDouble();
              break;
            case HealthDataType.WORKOUT:
              workoutMinutes += 30; // Assume 30 min workout
              break;
            default:
              break;
          }
        }
      }

      // Step milestones
      if (totalSteps >= 10000) {
        boosts.add(StatBoost(
          name: 'Daily Walker',
          description: '10,000+ steps today',
          statType: 'vitality',
          bonusValue: 15,
          sourceActivity: ActivityType.walking,
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        ));
      } else if (totalSteps >= 5000) {
        boosts.add(StatBoost(
          name: 'Active Day',
          description: '5,000+ steps today',
          statType: 'vitality',
          bonusValue: 8,
          sourceActivity: ActivityType.walking,
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        ));
      }

      // Calorie burn milestones
      if (totalCalories >= 500) {
        boosts.add(StatBoost(
          name: 'Calorie Crusher',
          description: '500+ calories burned today',
          statType: 'strength',
          bonusValue: 12,
          sourceActivity: ActivityType.cardio,
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        ));
      }

      // Workout completion
      if (workoutMinutes >= 30) {
        boosts.add(StatBoost(
          name: 'Dedicated Athlete',
          description: 'Completed workout today',
          statType: 'all',
          bonusValue: 10,
          sourceActivity: ActivityType.other,
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        ));
      }

    } catch (e) {
      print('Error getting daily activity boosts: $e');
    }

    return boosts;
  }

  // Get weekly activity boosts
  Future<List<StatBoost>> _getWeeklyActivityBoosts() async {
    final boosts = <StatBoost>[];
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    try {
      // Get week's health data
      final healthData = await _health.getHealthDataFromTypes(
        types: [
          HealthDataType.WORKOUT,
          HealthDataType.ACTIVE_ENERGY_BURNED,
        ],
        startTime: weekStart,
        endTime: now,
      );

      int workoutDays = 0;
      double weeklyCalories = 0;

      for (var point in healthData) {
        if (point.value is NumericHealthValue) {
          final value = (point.value as NumericHealthValue).numericValue;
          
          switch (point.type) {
            case HealthDataType.WORKOUT:
              workoutDays++;
              break;
            case HealthDataType.ACTIVE_ENERGY_BURNED:
              weeklyCalories += value.toDouble();
              break;
            default:
              break;
          }
        }
      }

      // Weekly workout consistency
      if (workoutDays >= 5) {
        boosts.add(StatBoost(
          name: 'Fitness Champion',
          description: '5+ workout days this week',
          statType: 'all',
          bonusValue: 20,
          sourceActivity: ActivityType.other,
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        ));
      } else if (workoutDays >= 3) {
        boosts.add(StatBoost(
          name: 'Consistent Athlete',
          description: '3+ workout days this week',
          statType: 'vitality',
          bonusValue: 15,
          sourceActivity: ActivityType.other,
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        ));
      }

      // Weekly calorie burn
      if (weeklyCalories >= 2000) {
        boosts.add(StatBoost(
          name: 'Calorie Dominator',
          description: '2000+ calories burned this week',
          statType: 'strength',
          bonusValue: 18,
          sourceActivity: ActivityType.cardio,
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        ));
      }

    } catch (e) {
      print('Error getting weekly activity boosts: $e');
    }

    return boosts;
  }

  // Apply boosts to character
  GameCharacter applyFitnessBoosts(GameCharacter character) {
    final allBoosts = [
      ..._currentBoosts.realTimeBoosts,
      ..._currentBoosts.dailyBoosts,
      ..._currentBoosts.weeklyBoosts,
    ].where((boost) => !boost.isExpired).toList();

    int strengthBonus = 0;
    int dexterityBonus = 0;
    int vitalityBonus = 0;
    int intelligenceBonus = 0;

    for (var boost in allBoosts) {
      switch (boost.statType) {
        case 'strength':
          strengthBonus += boost.bonusValue;
          break;
        case 'dexterity':
          dexterityBonus += boost.bonusValue;
          break;
        case 'vitality':
          vitalityBonus += boost.bonusValue;
          break;
        case 'intelligence':
          intelligenceBonus += boost.bonusValue;
          break;
        case 'all':
          strengthBonus += boost.bonusValue;
          dexterityBonus += boost.bonusValue;
          vitalityBonus += boost.bonusValue;
          intelligenceBonus += boost.bonusValue;
          break;
      }
    }

    return character.copyWith(
      allocatedStrength: character.allocatedStrength + strengthBonus,
      allocatedDexterity: character.allocatedDexterity + dexterityBonus,
      allocatedVitality: character.allocatedVitality + vitalityBonus,
      allocatedEnergy: character.allocatedEnergy + intelligenceBonus,
    );
  }

  // Get fitness tracker status for UI
  Map<String, dynamic> getFitnessTrackerStatus() {
    return {
      'connected_trackers': _connectedTrackers.map((t) => t.toString()).toList(),
      'latest_heart_rate': _latestMetrics?.heartRate,
      'heart_rate_zone': _latestMetrics?.heartRateZone?.toString(),
      'is_working_out': _latestMetrics?.isWorkingOut ?? false,
      'energy_level': _latestMetrics?.energyLevel ?? 0.7,
      'stress_level': _latestMetrics?.stressLevel ?? 0.5,
      'active_boosts': _currentBoosts.realTimeBoosts.length + 
                      _currentBoosts.dailyBoosts.length + 
                      _currentBoosts.weeklyBoosts.length,
      'multipliers': _currentBoosts.multipliers,
    };
  }

  // Connect to specific fitness tracker
  Future<bool> connectTracker(FitnessTracker tracker) async {
    try {
      switch (tracker) {
        case FitnessTracker.fitbit:
          final connected = await _connectFitbit();
          if (connected) _connectedTrackers.add(tracker);
          return connected;
        case FitnessTracker.garmin:
          final connected = await _connectGarmin();
          if (connected) _connectedTrackers.add(tracker);
          return connected;
        default:
          return false;
      }
    } catch (e) {
      print('Error connecting to $tracker: $e');
      return false;
    }
  }

  // Connect to Fitbit
  Future<bool> _connectFitbit() async {
    try {
      final result = await _fitbitChannel.invokeMethod('connect', {
        'client_id': 'YOUR_FITBIT_CLIENT_ID',
        'scopes': ['activity', 'heartrate', 'profile'],
      });
      return result == true;
    } catch (e) {
      print('Fitbit connection error: $e');
      return false;
    }
  }

  // Connect to Garmin
  Future<bool> _connectGarmin() async {
    try {
      final result = await _garminChannel.invokeMethod('connect', {
        'consumer_key': 'YOUR_GARMIN_CONSUMER_KEY',
        'consumer_secret': 'YOUR_GARMIN_CONSUMER_SECRET',
      });
      return result == true;
    } catch (e) {
      print('Garmin connection error: $e');
      return false;
    }
  }

  // Save fitness tracker preferences
  Future<void> savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'connected_fitness_trackers',
        _connectedTrackers.map((t) => t.toString()).toList(),
      );
      await prefs.setInt('max_heart_rate', _maxHeartRate);
    } catch (e) {
      print('Error saving fitness tracker preferences: $e');
    }
  }

  // Load fitness tracker preferences
  Future<void> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trackerStrings = prefs.getStringList('connected_fitness_trackers') ?? [];
      _connectedTrackers = trackerStrings
          .map((s) => FitnessTracker.values.firstWhere(
                (t) => t.toString() == s,
                orElse: () => FitnessTracker.generic,
              ))
          .toSet();
      _maxHeartRate = prefs.getInt('max_heart_rate') ?? 190;
    } catch (e) {
      print('Error loading fitness tracker preferences: $e');
    }
  }

  // Dispose resources
  void dispose() {
    _realTimeTimer?.cancel();
    _metricsController.close();
    _boostsController.close();
  }
} 