import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/weather_model.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';

class DynamicEventService {
  static final DynamicEventService _instance = DynamicEventService._internal();
  factory DynamicEventService() => _instance;
  DynamicEventService._internal();

  List<DynamicEvent> _activeEvents = [];
  List<CommunityEvent> _communityEvents = [];
  final Random _random = Random();

  // Enhanced Features
  bool _timeBasedEvents = true;
  bool _weatherBasedEvents = true;
  bool _communityEventsEnabled = true;
  bool _specialEvents = true;
  bool _eventNotifications = true;

  // Getters
  List<DynamicEvent> get activeEvents => _activeEvents;
  List<CommunityEvent> get communityEvents => _communityEvents;

  // Get active events for location
  Future<List<DynamicEvent>> getActiveEvents(UserLocation location) async {
    final events = <DynamicEvent>[];
    
    // Generate different types of events
    events.addAll(_generateTimeBasedEvents(location));
    events.addAll(_generateWeatherBasedEvents(location));
    events.addAll(_generateSpecialEvents(location));
    events.addAll(_generateCommunityEvents(location));

    // Update active events
    _activeEvents = events;
    
    return events;
  }

  // Generate time-based events
  List<DynamicEvent> _generateTimeBasedEvents(UserLocation location) {
    if (!_timeBasedEvents) return [];

    final events = <DynamicEvent>[];
    final currentHour = DateTime.now().hour;
    
    // Morning events (6-10 AM)
    if (currentHour >= 6 && currentHour <= 10) {
      events.add(_generateMorningEvent(location));
    }
    
    // Afternoon events (12-4 PM)
    if (currentHour >= 12 && currentHour <= 16) {
      events.add(_generateAfternoonEvent(location));
    }
    
    // Evening events (6-10 PM)
    if (currentHour >= 18 && currentHour <= 22) {
      events.add(_generateEveningEvent(location));
    }
    
    // Night events (10 PM - 6 AM)
    if (currentHour >= 22 || currentHour <= 6) {
      events.add(_generateNightEvent(location));
    }

    return events;
  }

  // Generate weather-based events
  List<DynamicEvent> _generateWeatherBasedEvents(UserLocation location) {
    if (!_weatherBasedEvents) return [];

    final events = <DynamicEvent>[];
    
    // This would be connected to weather service
    // For now, generate random weather events
    if (_random.nextBool()) {
      events.add(_generateWeatherEvent(location));
    }

    return events;
  }

  // Generate special events
  List<DynamicEvent> _generateSpecialEvents(UserLocation location) {
    if (!_specialEvents) return [];

    final events = <DynamicEvent>[];
    
    // Weekend events
    final now = DateTime.now();
    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      events.add(_generateWeekendEvent(location));
    }
    
    // Holiday events (simplified)
    if (_isHoliday(now)) {
      events.add(_generateHolidayEvent(location));
    }

    return events;
  }

  // Generate community events
  List<DynamicEvent> _generateCommunityEvents(UserLocation location) {
    if (!_communityEventsEnabled) return [];

    final events = <DynamicEvent>[];
    
    // Generate community events
    if (_random.nextBool()) {
      events.add(_generateCommunityEvent(location));
    }

    return events;
  }

  // Generate random location within radius
  LatLng _generateRandomLocation(UserLocation center, double radius) {
    final angle = _random.nextDouble() * 2 * pi;
    final distance = _random.nextDouble() * radius * 1000; // Convert to meters

    final latOffset = distance * cos(angle) / 111000; // Approximate meters to degrees
    final lngOffset = distance * sin(angle) / (111000 * cos(center.latitude * pi / 180));

    return LatLng(
      center.latitude + latOffset,
      center.longitude + lngOffset,
    );
  }

  // Time-based event generators
  DynamicEvent _generateMorningEvent(UserLocation location) {
    final eventLocation = _generateRandomLocation(location, 2.0);
    return DynamicEvent(
      id: 'morning_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Morning Energy Rush',
      description: 'Start your day with an energizing morning event!',
      type: EventType.time,
      location: eventLocation,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(const Duration(hours: 2)),
      rewardXP: 100,
      rewardGold: 30,
      maxParticipants: 50,
      currentParticipants: 0,
      isActive: true,
    );
  }

  DynamicEvent _generateAfternoonEvent(UserLocation location) {
    final eventLocation = _generateRandomLocation(location, 2.0);
    return DynamicEvent(
      id: 'afternoon_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Afternoon Adventure',
      description: 'Take a break and join this exciting afternoon event!',
      type: EventType.time,
      location: eventLocation,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(const Duration(hours: 3)),
      rewardXP: 150,
      rewardGold: 45,
      maxParticipants: 75,
      currentParticipants: 0,
      isActive: true,
    );
  }

  DynamicEvent _generateEveningEvent(UserLocation location) {
    final eventLocation = _generateRandomLocation(location, 2.0);
    return DynamicEvent(
      id: 'evening_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Evening Social',
      description: 'Wind down with fellow adventurers in this evening event!',
      type: EventType.time,
      location: eventLocation,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(const Duration(hours: 4)),
      rewardXP: 200,
      rewardGold: 60,
      maxParticipants: 100,
      currentParticipants: 0,
      isActive: true,
    );
  }

  DynamicEvent _generateNightEvent(UserLocation location) {
    final eventLocation = _generateRandomLocation(location, 2.0);
    return DynamicEvent(
      id: 'night_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Night Watch',
      description: 'Embark on a mysterious night-time adventure!',
      type: EventType.time,
      location: eventLocation,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(const Duration(hours: 6)),
      rewardXP: 300,
      rewardGold: 90,
      maxParticipants: 25,
      currentParticipants: 0,
      isActive: true,
    );
  }

  // Weather-based event generator
  DynamicEvent _generateWeatherEvent(UserLocation location) {
    final eventLocation = _generateRandomLocation(location, 2.0);
    return DynamicEvent(
      id: 'weather_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Weather Challenge',
      description: 'Face the elements in this weather-dependent event!',
      type: EventType.weather,
      location: eventLocation,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(const Duration(hours: 2)),
      rewardXP: 250,
      rewardGold: 75,
      maxParticipants: 40,
      currentParticipants: 0,
      isActive: true,
    );
  }

  // Special event generators
  DynamicEvent _generateWeekendEvent(UserLocation location) {
    final eventLocation = _generateRandomLocation(location, 3.0);
    return DynamicEvent(
      id: 'weekend_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Weekend Festival',
      description: 'Join the weekend celebration with special rewards!',
      type: EventType.special,
      location: eventLocation,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(const Duration(hours: 8)),
      rewardXP: 500,
      rewardGold: 150,
      maxParticipants: 200,
      currentParticipants: 0,
      isActive: true,
    );
  }

  DynamicEvent _generateHolidayEvent(UserLocation location) {
    final eventLocation = _generateRandomLocation(location, 3.0);
    return DynamicEvent(
      id: 'holiday_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Holiday Celebration',
      description: 'Celebrate the holiday with this special event!',
      type: EventType.special,
      location: eventLocation,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(const Duration(hours: 12)),
      rewardXP: 1000,
      rewardGold: 300,
      maxParticipants: 500,
      currentParticipants: 0,
      isActive: true,
    );
  }

  // Community event generator
  DynamicEvent _generateCommunityEvent(UserLocation location) {
    final eventLocation = _generateRandomLocation(location, 2.0);
    return DynamicEvent(
      id: 'community_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Community Gathering',
      description: 'Connect with your local community in this special event!',
      type: EventType.community,
      location: eventLocation,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(const Duration(hours: 6)),
      rewardXP: 400,
      rewardGold: 120,
      maxParticipants: 150,
      currentParticipants: 0,
      isActive: true,
    );
  }

  // Check if current date is a holiday (simplified)
  bool _isHoliday(DateTime date) {
    // Simplified holiday check - in real app, would use a holiday API
    final month = date.month;
    final day = date.day;
    
    // Common holidays (simplified)
    if (month == 12 && day == 25) return true; // Christmas
    if (month == 1 && day == 1) return true; // New Year
    if (month == 7 && day == 4) return true; // Independence Day (US)
    if (month == 11 && day == 11) return true; // Veterans Day (US)
    
    return false;
  }

  // Enhanced Features

  // Check nearby events
  void checkNearbyEvents(UserLocation location) {
    for (final event in _activeEvents) {
      final distance = _calculateDistance(location, event.location);
      if (distance <= 1000) { // Within 1km
        // Event is nearby - could trigger notifications
      }
    }
  }

  // Get events near position
  List<DynamicEvent> getEventsNearPosition(LatLng position, double radius) {
    return _activeEvents.where((event) {
      final distance = _calculateDistance(
        UserLocation(
          userId: 'player',
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: 0,
          timestamp: DateTime.now(),
        ),
        event.location,
      );
      return distance <= radius;
    }).toList();
  }

  // Calculate distance between two points
  double _calculateDistance(UserLocation start, LatLng end) {
    const double earthRadius = 6371000; // meters

    final double dLat = (end.latitude - start.latitude) * (pi / 180);
    final double dLon = (end.longitude - start.longitude) * (pi / 180);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(start.latitude * (pi / 180)) * cos(end.latitude * (pi / 180)) *
        sin(dLon / 2) * sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  // Join community event
  void joinCommunityEvent(CommunityEvent event) {
    // Handle joining community events
  }

  // Toggle enhanced features
  void toggleTimeBasedEvents() {
    _timeBasedEvents = !_timeBasedEvents;
  }

  void toggleWeatherBasedEvents() {
    _weatherBasedEvents = !_weatherBasedEvents;
  }

  void toggleCommunityEvents() {
    _communityEventsEnabled = !_communityEventsEnabled;
  }

  void toggleSpecialEvents() {
    _specialEvents = !_specialEvents;
  }

  void toggleEventNotifications() {
    _eventNotifications = !_eventNotifications;
  }

  // Get event statistics
  Map<String, dynamic> getEventStats() {
    return {
      'totalEvents': _activeEvents.length,
      'activeEvents': _activeEvents.where((e) => e.isActive).length,
      'communityEvents': _communityEvents.length,
      'timeBasedEvents': _timeBasedEvents,
      'weatherBasedEvents': _weatherBasedEvents,
      'communityEventsEnabled': _communityEventsEnabled,
      'specialEvents': _specialEvents,
      'eventNotifications': _eventNotifications,
    };
  }

  // Dispose
  void dispose() {
    _activeEvents.clear();
    _communityEvents.clear();
  }
}

// Event Models
class DynamicEvent {
  final String id;
  final String title;
  final String description;
  final EventType type;
  final LatLng location;
  final DateTime startTime;
  final DateTime endTime;
  final int rewardXP;
  final int rewardGold;
  final int maxParticipants;
  int currentParticipants;
  bool isActive;

  DynamicEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.location,
    required this.startTime,
    required this.endTime,
    required this.rewardXP,
    required this.rewardGold,
    required this.maxParticipants,
    this.currentParticipants = 0,
    this.isActive = true,
  });
}

enum EventType {
  time,
  weather,
  special,
  community,
}

class CommunityEvent {
  final String id;
  final String title;
  final String description;
  final LatLng location;
  final DateTime startTime;
  final DateTime endTime;
  final int maxParticipants;
  final List<String> participants;
  final Map<String, dynamic> requirements;

  CommunityEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startTime,
    required this.endTime,
    required this.maxParticipants,
    List<String>? participants,
    Map<String, dynamic>? requirements,
  })  : participants = participants ?? [],
        requirements = requirements ?? {};
} 