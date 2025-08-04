// Weather model without JSON serialization for now
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum WeatherCondition {
  sunny,
  cloudy,
  rainy,
  snowy,
  stormy,
  foggy,
  windy,
  clear,
  overcast,
}

class WeatherData {
  final WeatherCondition condition;
  final double temperature;
  final double humidity;
  final double windSpeed;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  WeatherData({
    required this.condition,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.timestamp,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? <String, dynamic>{};

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    // TODO: Implement JSON serialization
    throw UnimplementedError('JSON serialization not implemented yet');
  }
  
  Map<String, dynamic> toJson() {
    // TODO: Implement JSON serialization
    throw UnimplementedError('JSON serialization not implemented yet');
  }

  WeatherData copyWith({
    WeatherCondition? condition,
    double? temperature,
    double? humidity,
    double? windSpeed,
    String? description,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return WeatherData(
      condition: condition ?? this.condition,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      windSpeed: windSpeed ?? this.windSpeed,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }
}

class UserLocation {
  final String userId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final Map<String, dynamic> metadata;

  UserLocation({
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracy,
    this.altitude,
    this.speed,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? <String, dynamic>{};

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    // TODO: Implement JSON serialization
    throw UnimplementedError('JSON serialization not implemented yet');
  }
  
  Map<String, dynamic> toJson() {
    // TODO: Implement JSON serialization
    throw UnimplementedError('JSON serialization not implemented yet');
  }

  UserLocation copyWith({
    String? userId,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    double? accuracy,
    double? altitude,
    double? speed,
    Map<String, dynamic>? metadata,
  }) {
    return UserLocation(
      userId: userId ?? this.userId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      metadata: metadata ?? this.metadata,
    );
  }

  // Convert to Google Maps LatLng
  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }
} 