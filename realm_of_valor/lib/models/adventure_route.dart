import 'package:flutter/material.dart';

/// Difficulty levels for adventure routes
enum RouteDifficulty {
  easy,
  medium,
  hard,
  expert,
}

/// A waypoint along an adventure route
class RouteWaypoint {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final Map<String, dynamic> metadata;

  RouteWaypoint({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'metadata': metadata,
    };
  }

  factory RouteWaypoint.fromJson(Map<String, dynamic> json) {
    return RouteWaypoint(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      imageUrl: json['imageUrl'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

/// An adventure route with waypoints and challenges
class AdventureRoute {
  final String id;
  final String name;
  final String description;
  final RouteDifficulty difficulty;
  final List<RouteWaypoint> waypoints;
  final double estimatedDistance; // in kilometers
  final int estimatedDuration; // in minutes
  final List<String> tags;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  AdventureRoute({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.waypoints,
    required this.estimatedDistance,
    required this.estimatedDuration,
    List<String>? tags,
    this.imageUrl,
    this.isActive = true,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) : tags = tags ?? [],
       createdAt = createdAt ?? DateTime.now(),
       metadata = metadata ?? {};

  /// Get the difficulty name as a string
  String get difficultyName {
    switch (difficulty) {
      case RouteDifficulty.easy:
        return 'Easy';
      case RouteDifficulty.medium:
        return 'Medium';
      case RouteDifficulty.hard:
        return 'Hard';
      case RouteDifficulty.expert:
        return 'Expert';
    }
  }

  /// Get the difficulty color
  Color get difficultyColor {
    switch (difficulty) {
      case RouteDifficulty.easy:
        return Colors.green;
      case RouteDifficulty.medium:
        return Colors.orange;
      case RouteDifficulty.hard:
        return Colors.red;
      case RouteDifficulty.expert:
        return Colors.purple;
    }
  }

  /// Get the total number of waypoints
  int get waypointCount => waypoints.length;

  /// Check if the route has any waypoints
  bool get hasWaypoints => waypoints.isNotEmpty;

  /// Get the starting waypoint
  RouteWaypoint? get startWaypoint => waypoints.isNotEmpty ? waypoints.first : null;

  /// Get the ending waypoint
  RouteWaypoint? get endWaypoint => waypoints.isNotEmpty ? waypoints.last : null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'difficulty': difficulty.toString(),
      'waypoints': waypoints.map((w) => w.toJson()).toList(),
      'estimatedDistance': estimatedDistance,
      'estimatedDuration': estimatedDuration,
      'tags': tags,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory AdventureRoute.fromJson(Map<String, dynamic> json) {
    return AdventureRoute(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      difficulty: _parseDifficulty(json['difficulty']),
      waypoints: (json['waypoints'] as List<dynamic>?)
          ?.map((w) => RouteWaypoint.fromJson(w))
          .toList() ?? [],
      estimatedDistance: (json['estimatedDistance'] ?? 0.0).toDouble(),
      estimatedDuration: json['estimatedDuration'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      imageUrl: json['imageUrl'],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  static RouteDifficulty _parseDifficulty(String? difficultyStr) {
    switch (difficultyStr) {
      case 'RouteDifficulty.easy':
        return RouteDifficulty.easy;
      case 'RouteDifficulty.medium':
        return RouteDifficulty.medium;
      case 'RouteDifficulty.hard':
        return RouteDifficulty.hard;
      case 'RouteDifficulty.expert':
        return RouteDifficulty.expert;
      default:
        return RouteDifficulty.easy;
    }
  }

  AdventureRoute copyWith({
    String? id,
    String? name,
    String? description,
    RouteDifficulty? difficulty,
    List<RouteWaypoint>? waypoints,
    double? estimatedDistance,
    int? estimatedDuration,
    List<String>? tags,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return AdventureRoute(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      waypoints: waypoints ?? this.waypoints,
      estimatedDistance: estimatedDistance ?? this.estimatedDistance,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }
}