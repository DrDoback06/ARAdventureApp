import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quest_model.dart';
import '../services/event_bus.dart';

/// Community Events Service for real-world player meetups and activities
class CommunityEventsService {
  static const String version = '1.0.0';
  
  final SharedPreferences _prefs;
  
  // Event storage
  final List<CommunityEvent> _allEvents = [];
  final Map<String, List<CommunityEvent>> _userEvents = {};
  final Map<String, EventRegistration> _userRegistrations = {};
  
  // Event categories
  static const List<EventCategory> availableCategories = [
    EventCategory.fitness,
    EventCategory.gaming,
    EventCategory.social,
    EventCategory.trading,
    EventCategory.exploration,
    EventCategory.competition,
  ];

  CommunityEventsService({required SharedPreferences prefs}) : _prefs = prefs;

  /// Initialize the community events service
  Future<void> initialize() async {
    await _loadEventsFromStorage();
    await _cleanupExpiredEvents();
  }

  /// Create a new community event
  Future<CommunityEvent?> createEvent({
    required String organizerId,
    required String title,
    required String description,
    required EventCategory category,
    required DateTime scheduledTime,
    required Position location,
    required int maxParticipants,
    required bool isPublic,
    Map<String, dynamic>? additionalData,
  }) async {
    // Validate event creation
    final validation = await _validateEventCreation(
      organizerId: organizerId,
      scheduledTime: scheduledTime,
      location: location,
      category: category,
    );
    
    if (!validation.isValid) {
      throw EventCreationException(validation.message);
    }

    final event = CommunityEvent(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}',
      organizerId: organizerId,
      title: title,
      description: description,
      category: category,
      scheduledTime: scheduledTime,
      location: EventLocation(
        latitude: location.latitude,
        longitude: location.longitude,
        address: await _getLocationAddress(location),
        venue: additionalData?['venue'] as String?,
      ),
      maxParticipants: maxParticipants,
      isPublic: isPublic,
      status: EventStatus.scheduled,
      createdAt: DateTime.now(),
      registrationDeadline: scheduledTime.subtract(const Duration(hours: 1)),
      additionalData: additionalData ?? {},
    );

    _allEvents.add(event);
    _userEvents.putIfAbsent(organizerId, () => []).add(event);
    
    await _saveEventsToStorage();
    
    // Publish event creation
    EventBus.instance.publish(AgentEvent(
      id: 'community_event_created',
      type: 'community_event_created',
      agentId: 'community_events',
      data: {
        'event': event.toJson(),
        'organizerId': organizerId,
      },
    ));

    // Notify nearby players
    await _notifyNearbyPlayers(event);

    return event;
  }

  /// Find events near a location
  Future<List<CommunityEvent>> findNearbyEvents({
    required Position userLocation,
    required double radiusKm,
    List<EventCategory>? categories,
    DateTime? startTime,
    DateTime? endTime,
    int limit = 50,
  }) async {
    final nearbyEvents = <CommunityEvent>[];
    
    for (final event in _allEvents) {
      if (event.status != EventStatus.scheduled) continue;
      
      // Check distance
      final distance = Geolocator.distanceBetween(
        userLocation.latitude,
        userLocation.longitude,
        event.location.latitude,
        event.location.longitude,
      ) / 1000; // Convert to km
      
      if (distance > radiusKm) continue;
      
      // Check category filter
      if (categories != null && !categories.contains(event.category)) continue;
      
      // Check time filter
      if (startTime != null && event.scheduledTime.isBefore(startTime)) continue;
      if (endTime != null && event.scheduledTime.isAfter(endTime)) continue;
      
      // Check if event is public or user has access
      if (!event.isPublic) {
        // Add logic for private event access
        continue;
      }
      
      nearbyEvents.add(event);
    }
    
    // Sort by distance and relevance
    nearbyEvents.sort((a, b) {
      final distanceA = Geolocator.distanceBetween(
        userLocation.latitude,
        userLocation.longitude,
        a.location.latitude,
        a.location.longitude,
      );
      final distanceB = Geolocator.distanceBetween(
        userLocation.latitude,
        userLocation.longitude,
        b.location.latitude,
        b.location.longitude,
      );
      return distanceA.compareTo(distanceB);
    });
    
    return nearbyEvents.take(limit).toList();
  }

  /// Register for an event
  Future<EventRegistrationResult> registerForEvent({
    required String userId,
    required String eventId,
    String? message,
  }) async {
    final event = _allEvents.firstWhere(
      (e) => e.id == eventId,
      orElse: () => throw EventNotFoundException('Event not found: $eventId'),
    );

    // Validate registration
    final validation = _validateRegistration(userId, event);
    if (!validation.isValid) {
      return EventRegistrationResult(
        success: false,
        message: validation.message,
      );
    }

    final registration = EventRegistration(
      userId: userId,
      eventId: eventId,
      registeredAt: DateTime.now(),
      status: RegistrationStatus.confirmed,
      message: message,
    );

    _userRegistrations['${userId}_$eventId'] = registration;
    
    // Update event participant count
    final updatedEvent = event.copyWith(
      currentParticipants: event.currentParticipants + 1,
    );
    final eventIndex = _allEvents.indexWhere((e) => e.id == eventId);
    _allEvents[eventIndex] = updatedEvent;
    
    await _saveEventsToStorage();
    
    // Notify event organizer
    await _notifyEventOrganizer(event, registration);
    
    return EventRegistrationResult(
      success: true,
      message: 'Successfully registered for ${event.title}!',
      registration: registration,
    );
  }

  /// Get events created by a user
  List<CommunityEvent> getUserCreatedEvents(String userId) {
    return _userEvents[userId] ?? [];
  }

  /// Get events user is registered for
  List<CommunityEvent> getUserRegisteredEvents(String userId) {
    final registeredEventIds = _userRegistrations.entries
        .where((entry) => entry.key.startsWith('${userId}_'))
        .map((entry) => entry.value.eventId)
        .toList();
    
    return _allEvents
        .where((event) => registeredEventIds.contains(event.id))
        .toList();
  }

  /// Generate popular fitness-focused events
  Future<List<CommunityEvent>> generatePopularFitnessEvents({
    required Position userLocation,
  }) async {
    final events = <CommunityEvent>[];
    final now = DateTime.now();
    
    // Morning run group
    events.add(CommunityEvent(
      id: 'fitness_morning_run_${now.millisecondsSinceEpoch}',
      organizerId: 'system',
      title: 'Morning Warriors Run Club',
      description: 'Join fellow adventurers for an energizing morning run! All fitness levels welcome. We\'ll explore scenic routes while building our real-world stamina.',
      category: EventCategory.fitness,
      scheduledTime: DateTime(now.year, now.month, now.day + 1, 7, 0),
      location: EventLocation(
        latitude: userLocation.latitude + 0.01,
        longitude: userLocation.longitude + 0.01,
        address: 'Local Park - Main Entrance',
        venue: 'Riverside Park',
      ),
      maxParticipants: 20,
      isPublic: true,
      status: EventStatus.scheduled,
      createdAt: now,
      registrationDeadline: DateTime(now.year, now.month, now.day + 1, 6, 0),
      additionalData: {
        'distance': '5K',
        'pace': 'Relaxed',
        'equipment_needed': 'Running shoes, water bottle',
        'quest_rewards': true,
      },
    ));

    // Evening hiking group
    events.add(CommunityEvent(
      id: 'fitness_evening_hike_${now.millisecondsSinceEpoch}',
      organizerId: 'system',
      title: 'Sunset Trail Explorers',
      description: 'Discover hidden trails and earn exploration XP! Evening hike with beautiful sunset views. Perfect for completing distance-based quests.',
      category: EventCategory.exploration,
      scheduledTime: DateTime(now.year, now.month, now.day + 2, 18, 30),
      location: EventLocation(
        latitude: userLocation.latitude - 0.02,
        longitude: userLocation.longitude + 0.015,
        address: 'Mountain Trail Head',
        venue: 'Eagle Peak Trailhead',
      ),
      maxParticipants: 15,
      isPublic: true,
      status: EventStatus.scheduled,
      createdAt: now,
      registrationDeadline: DateTime(now.year, now.month, now.day + 2, 16, 0),
      additionalData: {
        'difficulty': 'Moderate',
        'distance': '3.2 miles',
        'elevation_gain': '600 feet',
        'quest_rewards': true,
      },
    ));

    return events;
  }

  /// Generate gaming and social events
  Future<List<CommunityEvent>> generateGamingEvents({
    required Position userLocation,
  }) async {
    final events = <CommunityEvent>[];
    final now = DateTime.now();
    
    // Card trading meetup
    events.add(CommunityEvent(
      id: 'gaming_card_trade_${now.millisecondsSinceEpoch}',
      organizerId: 'system',
      title: 'Realm of Valor Card Trading Bazaar',
      description: 'Bring your duplicate cards and trade with fellow collectors! Share strategies, show off rare finds, and build the perfect deck.',
      category: EventCategory.trading,
      scheduledTime: DateTime(now.year, now.month, now.day + 3, 14, 0),
      location: EventLocation(
        latitude: userLocation.latitude + 0.005,
        longitude: userLocation.longitude - 0.01,
        address: 'Community Center',
        venue: 'Downtown Community Hall',
      ),
      maxParticipants: 30,
      isPublic: true,
      status: EventStatus.scheduled,
      createdAt: now,
      registrationDeadline: DateTime(now.year, now.month, now.day + 3, 12, 0),
      additionalData: {
        'bring': 'Physical cards for trading',
        'activities': ['Card trading', 'Deck building workshop', 'Mini tournaments'],
        'special_rewards': true,
      },
    ));

    // Group quest adventure
    events.add(CommunityEvent(
      id: 'gaming_group_quest_${now.millisecondsSinceEpoch}',
      organizerId: 'system',
      title: 'Epic Group Quest: The Downtown Dragon Hunt',
      description: 'Team up for an epic multi-location quest! Work together to solve puzzles, complete challenges, and defeat the legendary Downtown Dragon.',
      category: EventCategory.gaming,
      scheduledTime: DateTime(now.year, now.month, now.day + 5, 10, 0),
      location: EventLocation(
        latitude: userLocation.latitude,
        longitude: userLocation.longitude,
        address: 'City Center Plaza',
        venue: 'Central Plaza',
      ),
      maxParticipants: 12,
      isPublic: true,
      status: EventStatus.scheduled,
      createdAt: now,
      registrationDeadline: DateTime(now.year, now.month, now.day + 5, 8, 0),
      additionalData: {
        'duration': '3-4 hours',
        'team_size': '3-4 players per team',
        'rewards': 'Legendary items and massive XP',
        'difficulty': 'Hard',
      },
    ));

    return events;
  }

  // Private helper methods
  Future<EventValidationResult> _validateEventCreation({
    required String organizerId,
    required DateTime scheduledTime,
    required Position location,
    required EventCategory category,
  }) async {
    // Check if scheduled time is in the future
    if (scheduledTime.isBefore(DateTime.now().add(const Duration(hours: 2)))) {
      return EventValidationResult(
        isValid: false,
        message: 'Events must be scheduled at least 2 hours in advance',
      );
    }

    // Check if user has too many events scheduled
    final userEventCount = _userEvents[organizerId]?.length ?? 0;
    if (userEventCount >= 5) {
      return EventValidationResult(
        isValid: false,
        message: 'You can only have 5 active events at a time',
      );
    }

    return EventValidationResult(isValid: true);
  }

  EventValidationResult _validateRegistration(String userId, CommunityEvent event) {
    // Check if event is full
    if (event.currentParticipants >= event.maxParticipants) {
      return EventValidationResult(
        isValid: false,
        message: 'Event is full',
      );
    }

    // Check if user is already registered
    if (_userRegistrations.containsKey('${userId}_${event.id}')) {
      return EventValidationResult(
        isValid: false,
        message: 'You are already registered for this event',
      );
    }

    // Check if registration deadline has passed
    if (DateTime.now().isAfter(event.registrationDeadline)) {
      return EventValidationResult(
        isValid: false,
        message: 'Registration deadline has passed',
      );
    }

    return EventValidationResult(isValid: true);
  }

  Future<String> _getLocationAddress(Position position) async {
    // In a real implementation, this would use a geocoding service
    return 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
  }

  Future<void> _notifyNearbyPlayers(CommunityEvent event) async {
    // Notify players within a reasonable distance about the new event
    // This would integrate with the notification system
  }

  Future<void> _notifyEventOrganizer(CommunityEvent event, EventRegistration registration) async {
    // Notify the event organizer about new registration
  }

  Future<void> _loadEventsFromStorage() async {
    try {
      final eventsJson = _prefs.getString('community_events');
      if (eventsJson != null) {
        final List<dynamic> eventsList = jsonDecode(eventsJson);
        _allEvents.clear();
        _allEvents.addAll(
          eventsList.map((e) => CommunityEvent.fromJson(e)).toList()
        );
      }

      final registrationsJson = _prefs.getString('event_registrations');
      if (registrationsJson != null) {
        final Map<String, dynamic> registrations = jsonDecode(registrationsJson);
        _userRegistrations.clear();
        registrations.forEach((key, value) {
          _userRegistrations[key] = EventRegistration.fromJson(value);
        });
      }
    } catch (e) {
      print('Error loading events from storage: $e');
    }
  }

  Future<void> _saveEventsToStorage() async {
    try {
      final eventsJson = jsonEncode(_allEvents.map((e) => e.toJson()).toList());
      await _prefs.setString('community_events', eventsJson);

      final registrationsJson = jsonEncode(
        _userRegistrations.map((key, value) => MapEntry(key, value.toJson()))
      );
      await _prefs.setString('event_registrations', registrationsJson);
    } catch (e) {
      print('Error saving events to storage: $e');
    }
  }

  Future<void> _cleanupExpiredEvents() async {
    final now = DateTime.now();
    _allEvents.removeWhere((event) => 
      event.scheduledTime.isBefore(now.subtract(const Duration(days: 1)))
    );
    await _saveEventsToStorage();
  }
}

// Supporting classes and enums
enum EventCategory {
  fitness,
  gaming,
  social,
  trading,
  exploration,
  competition,
}

enum EventStatus {
  scheduled,
  inProgress,
  completed,
  cancelled,
}

enum RegistrationStatus {
  confirmed,
  waitlisted,
  cancelled,
}

class CommunityEvent {
  final String id;
  final String organizerId;
  final String title;
  final String description;
  final EventCategory category;
  final DateTime scheduledTime;
  final EventLocation location;
  final int maxParticipants;
  final int currentParticipants;
  final bool isPublic;
  final EventStatus status;
  final DateTime createdAt;
  final DateTime registrationDeadline;
  final Map<String, dynamic> additionalData;

  CommunityEvent({
    required this.id,
    required this.organizerId,
    required this.title,
    required this.description,
    required this.category,
    required this.scheduledTime,
    required this.location,
    required this.maxParticipants,
    this.currentParticipants = 0,
    required this.isPublic,
    required this.status,
    required this.createdAt,
    required this.registrationDeadline,
    Map<String, dynamic>? additionalData,
  }) : additionalData = additionalData ?? {};

  CommunityEvent copyWith({
    String? id,
    String? organizerId,
    String? title,
    String? description,
    EventCategory? category,
    DateTime? scheduledTime,
    EventLocation? location,
    int? maxParticipants,
    int? currentParticipants,
    bool? isPublic,
    EventStatus? status,
    DateTime? createdAt,
    DateTime? registrationDeadline,
    Map<String, dynamic>? additionalData,
  }) {
    return CommunityEvent(
      id: id ?? this.id,
      organizerId: organizerId ?? this.organizerId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      location: location ?? this.location,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      isPublic: isPublic ?? this.isPublic,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'organizerId': organizerId,
    'title': title,
    'description': description,
    'category': category.name,
    'scheduledTime': scheduledTime.toIso8601String(),
    'location': location.toJson(),
    'maxParticipants': maxParticipants,
    'currentParticipants': currentParticipants,
    'isPublic': isPublic,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'registrationDeadline': registrationDeadline.toIso8601String(),
    'additionalData': additionalData,
  };

  factory CommunityEvent.fromJson(Map<String, dynamic> json) => CommunityEvent(
    id: json['id'],
    organizerId: json['organizerId'],
    title: json['title'],
    description: json['description'],
    category: EventCategory.values.firstWhere((e) => e.name == json['category']),
    scheduledTime: DateTime.parse(json['scheduledTime']),
    location: EventLocation.fromJson(json['location']),
    maxParticipants: json['maxParticipants'],
    currentParticipants: json['currentParticipants'] ?? 0,
    isPublic: json['isPublic'],
    status: EventStatus.values.firstWhere((e) => e.name == json['status']),
    createdAt: DateTime.parse(json['createdAt']),
    registrationDeadline: DateTime.parse(json['registrationDeadline']),
    additionalData: Map<String, dynamic>.from(json['additionalData'] ?? {}),
  );
}

class EventLocation {
  final double latitude;
  final double longitude;
  final String address;
  final String? venue;

  EventLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.venue,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'venue': venue,
  };

  factory EventLocation.fromJson(Map<String, dynamic> json) => EventLocation(
    latitude: json['latitude'],
    longitude: json['longitude'],
    address: json['address'],
    venue: json['venue'],
  );
}

class EventRegistration {
  final String userId;
  final String eventId;
  final DateTime registeredAt;
  final RegistrationStatus status;
  final String? message;

  EventRegistration({
    required this.userId,
    required this.eventId,
    required this.registeredAt,
    required this.status,
    this.message,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'eventId': eventId,
    'registeredAt': registeredAt.toIso8601String(),
    'status': status.name,
    'message': message,
  };

  factory EventRegistration.fromJson(Map<String, dynamic> json) => EventRegistration(
    userId: json['userId'],
    eventId: json['eventId'],
    registeredAt: DateTime.parse(json['registeredAt']),
    status: RegistrationStatus.values.firstWhere((e) => e.name == json['status']),
    message: json['message'],
  );
}

class EventRegistrationResult {
  final bool success;
  final String message;
  final EventRegistration? registration;

  EventRegistrationResult({
    required this.success,
    required this.message,
    this.registration,
  });
}

class EventValidationResult {
  final bool isValid;
  final String message;

  EventValidationResult({
    required this.isValid,
    this.message = '',
  });
}

class EventCreationException implements Exception {
  final String message;
  EventCreationException(this.message);
}

class EventNotFoundException implements Exception {
  final String message;
  EventNotFoundException(this.message);
}