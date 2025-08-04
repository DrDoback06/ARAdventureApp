import 'dart:math';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'adventure_route.dart';
import 'adventure_system.dart';

part 'trail_model.g.dart';

enum TrailDifficulty {
  easy,
  moderate,
  hard,
  expert,
}

enum TrailType {
  hiking,
  walking,
  running,
  biking,
  climbing,
  backpacking,
}

@JsonSerializable()
class TrailData {
  final String id;
  final String name;
  final String description;
  final TrailDifficulty difficulty;
  final TrailType type;
  final double lengthKm;
  final int elevationGainM;
  final int estimatedTimeMinutes;
  final double rating;
  final int reviewCount;
  final GeoLocation startLocation;
  final GeoLocation endLocation;
  final List<GeoLocation> route;
  final List<TrailFeature> features;
  final List<String> tags;
  final String? thumbnailUrl;
  final String? mapUrl;
  final TrailConditions? currentConditions;

  TrailData({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.type,
    required this.lengthKm,
    required this.elevationGainM,
    required this.estimatedTimeMinutes,
    required this.rating,
    required this.reviewCount,
    required this.startLocation,
    required this.endLocation,
    required this.route,
    required this.features,
    required this.tags,
    this.thumbnailUrl,
    this.mapUrl,
    this.currentConditions,
  });

  factory TrailData.fromJson(Map<String, dynamic> json) =>
      _$TrailDataFromJson(json);
  Map<String, dynamic> toJson() => _$TrailDataToJson(this);

  // Convert trail to adventure route
  AdventureRoute toAdventureRoute() {
    return AdventureRoute(
      id: 'trail_$id',
      name: 'Adventure: $name',
      description: 'Follow this $lengthKm km trail and discover hidden quests along the way!\n\n$description',
      difficulty: _mapTrailDifficultyToRouteDifficulty(difficulty),
      distanceKm: lengthKm,
      estimatedDuration: Duration(minutes: estimatedTimeMinutes + 30), // Extra time for quests
      elevationGain: elevationGainM.toDouble(),
      route: route,
      waypoints: _createWaypointsFromFeatures(),
      tags: [...tags, 'trail', 'hiking'],
      activityType: _mapTrailTypeToActivityType(type),
    );
  }

  RouteDifficulty _mapTrailDifficultyToRouteDifficulty(TrailDifficulty difficulty) {
    switch (difficulty) {
      case TrailDifficulty.easy:
        return RouteDifficulty.easy;
      case TrailDifficulty.moderate:
        return RouteDifficulty.medium;
      case TrailDifficulty.hard:
      case TrailDifficulty.expert:
        return RouteDifficulty.hard;
    }
  }

  String _mapTrailTypeToActivityType(TrailType type) {
    switch (type) {
      case TrailType.hiking:
      case TrailType.walking:
        return 'hiking';
      case TrailType.running:
        return 'running';
      case TrailType.biking:
        return 'cycling';
      case TrailType.climbing:
        return 'climbing';
      case TrailType.backpacking:
        return 'backpacking';
    }
  }

  List<RouteWaypoint> _createWaypointsFromFeatures() {
    return features.map((feature) => RouteWaypoint(
      id: 'feature_${feature.id}',
      name: feature.name,
      description: feature.description,
      location: feature.location,
      type: feature.type,
      isRequired: false,
    )).toList();
  }

  String get difficultyColor {
    switch (difficulty) {
      case TrailDifficulty.easy:
        return '#4CAF50'; // Green
      case TrailDifficulty.moderate:
        return '#FF9800'; // Orange  
      case TrailDifficulty.hard:
        return '#F44336'; // Red
      case TrailDifficulty.expert:
        return '#9C27B0'; // Purple
    }
  }

  String get difficultyIcon {
    switch (difficulty) {
      case TrailDifficulty.easy:
        return '🟢';
      case TrailDifficulty.moderate:
        return '🟡';
      case TrailDifficulty.hard:
        return '🔴';
      case TrailDifficulty.expert:
        return '⚫';
    }
  }
}

@JsonSerializable()
class TrailFeature {
  final String id;
  final String name;
  final String description;
  final String type; // waterfall, viewpoint, bridge, camp, etc.
  final GeoLocation location;
  final List<String> photos;

  TrailFeature({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.location,
    required this.photos,
  });

  factory TrailFeature.fromJson(Map<String, dynamic> json) =>
      _$TrailFeatureFromJson(json);
  Map<String, dynamic> toJson() => _$TrailFeatureToJson(this);
}

@JsonSerializable()
class TrailConditions {
  final String status; // open, closed, caution
  final String? statusDescription;
  final DateTime lastUpdated;
  final List<String> alerts;

  TrailConditions({
    required this.status,
    this.statusDescription,
    required this.lastUpdated,
    required this.alerts,
  });

  factory TrailConditions.fromJson(Map<String, dynamic> json) =>
      _$TrailConditionsFromJson(json);
  Map<String, dynamic> toJson() => _$TrailConditionsToJson(this);

  bool get isOpen => status.toLowerCase() == 'open';
  bool get hasAlerts => alerts.isNotEmpty;
} 