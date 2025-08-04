enum ActivityType {
  running,
  walking,
  cycling,
  gym,
  adventure,
  yoga,
  swimming,
  hiking,
  other,
}

class ActivityData {
  final ActivityType type;
  final DateTime startTime;
  final int distance; // in meters
  final int calories;
  final int steps;
  final Duration duration;
  final double? speed; // in m/s
  final double? elevation; // in meters
  final double? heartRate; // bpm

  ActivityData({
    required this.type,
    required this.startTime,
    required this.distance,
    required this.calories,
    required this.steps,
    required this.duration,
    this.speed,
    this.elevation,
    this.heartRate,
  });

  // Convert to character stat updates
  Map<String, int> toCharacterStats() {
    final stats = <String, int>{};
    
    // Base XP from activity
    stats['experience'] = _calculateXP();
    
    // Distance-based stats
    if (distance > 0) {
      stats['stamina'] = (distance / 100).round(); // 1 stamina per 100m
      stats['health'] = (distance / 500).round(); // 1 health per 500m
    }
    
    // Calorie-based stats
    if (calories > 0) {
      stats['strength'] = (calories / 50).round(); // 1 strength per 50 calories
      stats['defense'] = (calories / 100).round(); // 1 defense per 100 calories
    }
    
    // Step-based stats
    if (steps > 0) {
      stats['energy'] = (steps / 1000).round(); // 1 energy per 1000 steps
      stats['agility'] = (steps / 2000).round(); // 1 agility per 2000 steps
    }
    
    // Duration-based stats
    final minutes = duration.inMinutes;
    if (minutes > 0) {
      stats['experience'] = (stats['experience'] ?? 0) + (minutes * 2); // 2 XP per minute
    }
    
    // Speed-based stats (if available)
    if (speed != null && speed! > 0) {
      stats['dexterity'] = (speed! * 10).round(); // 1 dexterity per 0.1 m/s
    }
    
    // Elevation-based stats (if available)
    if (elevation != null && elevation! > 0) {
      stats['strength'] = (stats['strength'] ?? 0) + (elevation! / 10).round(); // 1 strength per 10m elevation
      stats['stamina'] = (stats['stamina'] ?? 0) + (elevation! / 20).round(); // 1 stamina per 20m elevation
    }
    
    return stats;
  }

  // Calculate base XP based on activity type and intensity
  int _calculateXP() {
    int baseXP = 0;
    
    switch (type) {
      case ActivityType.running:
        baseXP = (distance / 100).round() + (calories / 10).round(); // High intensity
        break;
      case ActivityType.walking:
        baseXP = (distance / 200).round() + (calories / 20).round(); // Low intensity
        break;
      case ActivityType.cycling:
        baseXP = (distance / 150).round() + (calories / 15).round(); // Medium intensity
        break;
      case ActivityType.gym:
        baseXP = (calories / 5).round(); // Strength training
        break;
      case ActivityType.adventure:
        baseXP = (distance / 100).round() + (calories / 10).round() + (duration.inMinutes * 2); // Adventure bonus
        break;
      case ActivityType.yoga:
        baseXP = (duration.inMinutes * 3) + (calories / 30).round(); // Mind-body focus
        break;
      case ActivityType.swimming:
        baseXP = (distance / 50).round() + (calories / 8).round(); // High resistance
        break;
      case ActivityType.hiking:
        baseXP = (distance / 120).round() + (calories / 12).round() + (elevation?.round() ?? 0); // Terrain bonus
        break;
      case ActivityType.other:
        baseXP = (distance / 300).round() + (calories / 25).round(); // Generic
        break;
    }
    
    return baseXP;
  }

  // Create from JSON
  factory ActivityData.fromJson(Map<String, dynamic> json) {
    return ActivityData(
      type: ActivityType.values.firstWhere(
        (e) => e.toString() == 'ActivityType.${json['type']}',
      ),
      startTime: DateTime.parse(json['startTime']),
      distance: json['distance'] ?? 0,
      calories: json['calories'] ?? 0,
      steps: json['steps'] ?? 0,
      duration: Duration(milliseconds: json['durationMs'] ?? 0),
      speed: json['speed'],
      elevation: json['elevation'],
      heartRate: json['heartRate'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'startTime': startTime.toIso8601String(),
      'distance': distance,
      'calories': calories,
      'steps': steps,
      'durationMs': duration.inMilliseconds,
      'speed': speed,
      'elevation': elevation,
      'heartRate': heartRate,
    };
  }
}

class ActivityLog {
  final String id;
  final ActivityType type;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final int distance;
  final int calories;
  final int steps;
  final double? averageSpeed;
  final double? totalElevation;
  final double? averageHeartRate;

  ActivityLog({
    required this.id,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.distance,
    required this.calories,
    required this.steps,
    this.averageSpeed,
    this.totalElevation,
    this.averageHeartRate,
  });

  // Get activity summary for display
  String get summary {
    final distanceKm = (distance / 1000.0).toStringAsFixed(1);
    final durationHours = duration.inHours;
    final durationMinutes = duration.inMinutes % 60;
    
    return '${type.name.toUpperCase()} - ${distanceKm}km in ${durationHours}h ${durationMinutes}m';
  }

  // Get intensity level
  String get intensity {
    final caloriesPerMinute = duration.inMinutes > 0 ? calories / duration.inMinutes : 0;
    
    if (caloriesPerMinute > 10) return 'High';
    if (caloriesPerMinute > 5) return 'Medium';
    return 'Low';
  }

  // Create from JSON
  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'],
      type: ActivityType.values.firstWhere(
        (e) => e.toString() == 'ActivityType.${json['type']}',
      ),
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      duration: Duration(milliseconds: json['durationMs']),
      distance: json['distance'] ?? 0,
      calories: json['calories'] ?? 0,
      steps: json['steps'] ?? 0,
      averageSpeed: json['averageSpeed'],
      totalElevation: json['totalElevation'],
      averageHeartRate: json['averageHeartRate'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationMs': duration.inMilliseconds,
      'distance': distance,
      'calories': calories,
      'steps': steps,
      'averageSpeed': averageSpeed,
      'totalElevation': totalElevation,
      'averageHeartRate': averageHeartRate,
    };
  }
} 