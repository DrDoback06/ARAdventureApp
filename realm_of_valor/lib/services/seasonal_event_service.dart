import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/adventure_system.dart';
import '../services/weather_service.dart';

enum Season {
  spring,
  summer,
  autumn,
  winter,
}

enum EventType {
  seasonal,
  holiday,
  community,
  special,
  limited,
}

class SeasonalEvent {
  final String id;
  final String name;
  final String description;
  final EventType type;
  final Season? associatedSeason;
  final DateTime startDate;
  final DateTime endDate;
  final List<Quest> exclusiveQuests;
  final List<WorldSpawn> specialSpawns;
  final Map<String, dynamic> eventRewards;
  final Map<String, dynamic> eventModifiers;
  final bool isActive;
  final int participantCount;
  final String? bannerImageUrl;
  final Map<String, dynamic> metadata;

  SeasonalEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.associatedSeason,
    required this.startDate,
    required this.endDate,
    required this.exclusiveQuests,
    required this.specialSpawns,
    required this.eventRewards,
    required this.eventModifiers,
    this.isActive = true,
    this.participantCount = 0,
    this.bannerImageUrl,
    required this.metadata,
  });

  factory SeasonalEvent.fromJson(Map<String, dynamic> json) {
    return SeasonalEvent(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: EventType.values[json['type'] ?? 0],
      associatedSeason: json['associatedSeason'] != null 
          ? Season.values[json['associatedSeason']]
          : null,
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      exclusiveQuests: (json['exclusiveQuests'] as List?)
          ?.map((q) => Quest.fromJson(q))
          .toList() ?? [],
      specialSpawns: (json['specialSpawns'] as List?)
          ?.map((s) => WorldSpawn.fromJson(s))
          .toList() ?? [],
      eventRewards: Map<String, dynamic>.from(json['eventRewards'] ?? {}),
      eventModifiers: Map<String, dynamic>.from(json['eventModifiers'] ?? {}),
      isActive: json['isActive'] ?? true,
      participantCount: json['participantCount'] ?? 0,
      bannerImageUrl: json['bannerImageUrl'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.index,
      'associatedSeason': associatedSeason?.index,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'exclusiveQuests': exclusiveQuests.map((q) => q.toJson()).toList(),
      'specialSpawns': specialSpawns.map((s) => s.toJson()).toList(),
      'eventRewards': eventRewards,
      'eventModifiers': eventModifiers,
      'isActive': isActive,
      'participantCount': participantCount,
      'bannerImageUrl': bannerImageUrl,
      'metadata': metadata,
    };
  }

  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && now.isAfter(startDate) && now.isBefore(endDate);
  }

  Duration get timeRemaining {
    return endDate.difference(DateTime.now());
  }

  double get progressPercentage {
    final now = DateTime.now();
    final totalDuration = endDate.difference(startDate);
    final elapsed = now.difference(startDate);
    return (elapsed.inMilliseconds / totalDuration.inMilliseconds * 100).clamp(0.0, 100.0);
  }
}

class LimitedTimeOffer {
  final String id;
  final String title;
  final String description;
  final Map<String, dynamic> rewards;
  final Map<String, dynamic> requirements;
  final DateTime expiresAt;
  final bool isClaimed;
  final int maxClaims;
  final int currentClaims;

  LimitedTimeOffer({
    required this.id,
    required this.title,
    required this.description,
    required this.rewards,
    required this.requirements,
    required this.expiresAt,
    this.isClaimed = false,
    this.maxClaims = 1000,
    this.currentClaims = 0,
  });

  factory LimitedTimeOffer.fromJson(Map<String, dynamic> json) {
    return LimitedTimeOffer(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      rewards: Map<String, dynamic>.from(json['rewards']),
      requirements: Map<String, dynamic>.from(json['requirements']),
      expiresAt: DateTime.parse(json['expiresAt']),
      isClaimed: json['isClaimed'] ?? false,
      maxClaims: json['maxClaims'] ?? 1000,
      currentClaims: json['currentClaims'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'rewards': rewards,
      'requirements': requirements,
      'expiresAt': expiresAt.toIso8601String(),
      'isClaimed': isClaimed,
      'maxClaims': maxClaims,
      'currentClaims': currentClaims,
    };
  }

  bool get isAvailable {
    return DateTime.now().isBefore(expiresAt) && 
           currentClaims < maxClaims && 
           !isClaimed;
  }
}

class SeasonalEventService {
  static final SeasonalEventService _instance = SeasonalEventService._internal();
  factory SeasonalEventService() => _instance;
  SeasonalEventService._internal();

  final StreamController<List<SeasonalEvent>> _eventController = StreamController.broadcast();
  final StreamController<List<LimitedTimeOffer>> _offerController = StreamController.broadcast();
  
  Stream<List<SeasonalEvent>> get eventStream => _eventController.stream;
  Stream<List<LimitedTimeOffer>> get offerStream => _offerController.stream;

  List<SeasonalEvent> _activeEvents = [];
  List<LimitedTimeOffer> _activeOffers = [];
  Timer? _eventUpdateTimer;

  // Initialize seasonal events
  Future<void> initialize() async {
    await _loadActiveEvents();
    await _generateSeasonalContent();
    _startEventUpdateTimer();
  }

  // Get current season
  Season getCurrentSeason() {
    final now = DateTime.now();
    switch (now.month) {
      case 3:
      case 4:
      case 5:
        return Season.spring;
      case 6:
      case 7:
      case 8:
        return Season.summer;
      case 9:
      case 10:
      case 11:
        return Season.autumn;
      default:
        return Season.winter;
    }
  }

  // Get active events
  List<SeasonalEvent> getActiveEvents() {
    return _activeEvents.where((event) => event.isCurrentlyActive).toList();
  }

  // Get active limited-time offers
  List<LimitedTimeOffer> getActiveOffers() {
    return _activeOffers.where((offer) => offer.isAvailable).toList();
  }

  // Generate seasonal content based on current date and weather
  Future<void> _generateSeasonalContent() async {
    final season = getCurrentSeason();
    final now = DateTime.now();

    // Generate seasonal events
    await _generateSeasonalEvents(season);
    
    // Generate holiday events
    await _generateHolidayEvents(now);
    
    // Generate weather-based events
    await _generateWeatherEvents();
    
    // Generate limited-time offers
    await _generateLimitedTimeOffers();

    _eventController.add(_activeEvents);
    _offerController.add(_activeOffers);
  }

  // Generate seasonal events
  Future<void> _generateSeasonalEvents(Season season) async {
    switch (season) {
      case Season.spring:
        _activeEvents.add(_createSpringEvent());
        break;
      case Season.summer:
        _activeEvents.add(_createSummerEvent());
        break;
      case Season.autumn:
        _activeEvents.add(_createAutumnEvent());
        break;
      case Season.winter:
        _activeEvents.add(_createWinterEvent());
        break;
    }
  }

  // Create Spring event
  SeasonalEvent _createSpringEvent() {
    return SeasonalEvent(
      id: 'spring_awakening_2024',
      name: 'Spring Awakening',
      description: 'Nature awakens from winter slumber! Discover blooming adventures across the realm.',
      type: EventType.seasonal,
      associatedSeason: Season.spring,
      startDate: DateTime(DateTime.now().year, 3, 20),
      endDate: DateTime(DateTime.now().year, 6, 20),
      exclusiveQuests: [
        Quest(
          title: 'Flower Hunter',
          description: 'Visit 10 parks to collect spring flower essence.',
          type: QuestType.exploration,
          level: 2,
          xpReward: 300,
          cardRewards: ['spring_blossom', 'nature_sprite', 'growth_potion'],
          objectives: [
            QuestObjective(
              title: 'Visit Blooming Parks',
              description: 'Find parks with spring flowers',
              type: 'location_visit',
              requirements: {'location_type': 'park', 'count': 10},
              xpReward: 200,
            ),
          ],
        ),
        Quest(
          title: 'Spring Fitness Challenge',
          description: 'Take 50,000 steps during the spring season to awaken your vitality.',
          type: QuestType.fitness,
          level: 4,
          xpReward: 750,
          cardRewards: ['vitality_boost', 'spring_runner', 'endurance_charm'],
          objectives: [
            QuestObjective(
              title: 'Spring Steps',
              description: 'Walk your way to spring fitness',
              type: 'steps',
              requirements: {'steps': 50000},
              xpReward: 500,
            ),
          ],
        ),
      ],
      specialSpawns: [
        WorldSpawn(
          name: 'Spring Fairy Ring',
          description: 'A magical circle of flowers with nature spirits dancing within.',
          type: SpawnType.rare,
          location: GeoLocation(latitude: 0, longitude: 0), // Would be set dynamically
          level: 3,
          availableCards: ['nature_fairy', 'flower_magic', 'spring_blessing'],
          rewards: {'xp': 200, 'cards': 2},
        ),
      ],
      eventRewards: {
        'participation': {'xp': 100, 'title': 'Spring Explorer'},
        'completion': {'xp': 500, 'cards': 3, 'title': 'Nature\'s Champion'},
      },
      eventModifiers: {
        'nature_spawn_rate': 2.0,
        'park_xp_bonus': 1.5,
        'flower_encounter_chance': 0.3,
      },
      metadata: {
        'theme_color': '#4CAF50',
        'background_music': 'spring_melody.mp3',
      },
    );
  }

  // Create Summer event
  SeasonalEvent _createSummerEvent() {
    return SeasonalEvent(
      id: 'solar_festival_2024',
      name: 'Solar Festival',
      description: 'Harness the power of the summer sun in this blazing adventure festival!',
      type: EventType.seasonal,
      associatedSeason: Season.summer,
      startDate: DateTime(DateTime.now().year, 6, 21),
      endDate: DateTime(DateTime.now().year, 9, 22),
      exclusiveQuests: [
        Quest(
          title: 'Solar Explorer',
          description: 'Complete quests during sunny weather to collect solar energy.',
          type: QuestType.seasonal,
          level: 5,
          xpReward: 600,
          cardRewards: ['solar_crystal', 'sun_guardian', 'fire_elemental'],
          objectives: [
            QuestObjective(
              title: 'Sunny Day Adventures',
              description: 'Complete activities on sunny days',
              type: 'weather_activity',
              requirements: {'weather': 'sunny', 'activities': 15},
              xpReward: 400,
            ),
          ],
        ),
      ],
      specialSpawns: [
        WorldSpawn(
          name: 'Solar Portal',
          description: 'A shimmering gateway infused with concentrated sunlight.',
          type: SpawnType.legendary,
          location: GeoLocation(latitude: 0, longitude: 0),
          level: 6,
          availableCards: ['solar_dragon', 'light_magic', 'summer_blessing'],
          rewards: {'xp': 400, 'cards': 3},
        ),
      ],
      eventRewards: {
        'participation': {'xp': 150, 'title': 'Sun Seeker'},
        'completion': {'xp': 750, 'cards': 4, 'title': 'Solar Champion'},
      },
      eventModifiers: {
        'fire_spawn_rate': 2.5,
        'sunny_weather_xp_bonus': 2.0,
        'solar_encounter_chance': 0.4,
      },
      metadata: {
        'theme_color': '#FF9800',
        'background_music': 'summer_anthem.mp3',
      },
    );
  }

  // Create Autumn event
  SeasonalEvent _createAutumnEvent() {
    return SeasonalEvent(
      id: 'harvest_moon_2024',
      name: 'Harvest Moon Festival',
      description: 'Gather the bounty of autumn and celebrate the changing seasons.',
      type: EventType.seasonal,
      associatedSeason: Season.autumn,
      startDate: DateTime(DateTime.now().year, 9, 23),
      endDate: DateTime(DateTime.now().year, 12, 20),
      exclusiveQuests: [
        Quest(
          title: 'Autumn Harvest',
          description: 'Collect fallen leaves and autumn treasures from your journeys.',
          type: QuestType.collection,
          level: 3,
          xpReward: 400,
          cardRewards: ['autumn_leaf', 'harvest_spirit', 'golden_acorn'],
          objectives: [
            QuestObjective(
              title: 'Leaf Collector',
              description: 'Walk 25km to collect autumn leaves',
              type: 'distance',
              requirements: {'distance': 25000},
              xpReward: 250,
            ),
          ],
        ),
      ],
      specialSpawns: [
        WorldSpawn(
          name: 'Harvest Grove',
          description: 'An ancient grove where autumn spirits gather their bounty.',
          type: SpawnType.epic,
          location: GeoLocation(latitude: 0, longitude: 0),
          level: 4,
          availableCards: ['tree_guardian', 'autumn_magic', 'harvest_blessing'],
          rewards: {'xp': 300, 'cards': 2},
        ),
      ],
      eventRewards: {
        'participation': {'xp': 125, 'title': 'Harvest Helper'},
        'completion': {'xp': 600, 'cards': 3, 'title': 'Autumn Sage'},
      },
      eventModifiers: {
        'earth_spawn_rate': 2.0,
        'park_treasure_chance': 0.35,
        'autumn_encounter_chance': 0.3,
      },
      metadata: {
        'theme_color': '#FF6F00',
        'background_music': 'autumn_winds.mp3',
      },
    );
  }

  // Create Winter event
  SeasonalEvent _createWinterEvent() {
    return SeasonalEvent(
      id: 'winter_solstice_2024',
      name: 'Winter Solstice',
      description: 'Embrace the magic of winter and discover frost-touched adventures.',
      type: EventType.seasonal,
      associatedSeason: Season.winter,
      startDate: DateTime(DateTime.now().year, 12, 21),
      endDate: DateTime(DateTime.now().year + 1, 3, 19),
      exclusiveQuests: [
        Quest(
          title: 'Frost Walker',
          description: 'Brave the cold and complete winter challenges.',
          type: QuestType.seasonal,
          level: 6,
          xpReward: 800,
          cardRewards: ['ice_crystal', 'winter_wolf', 'frost_armor'],
          objectives: [
            QuestObjective(
              title: 'Winter Warrior',
              description: 'Stay active during cold weather',
              type: 'cold_weather_activity',
              requirements: {'temperature_max': 5, 'activities': 10},
              xpReward: 500,
            ),
          ],
        ),
      ],
      specialSpawns: [
        WorldSpawn(
          name: 'Frost Shrine',
          description: 'A mystical shrine covered in eternal ice and snow.',
          type: SpawnType.boss,
          location: GeoLocation(latitude: 0, longitude: 0),
          level: 7,
          availableCards: ['ice_dragon', 'winter_magic', 'solstice_blessing'],
          rewards: {'xp': 500, 'cards': 4},
        ),
      ],
      eventRewards: {
        'participation': {'xp': 200, 'title': 'Winter Explorer'},
        'completion': {'xp': 1000, 'cards': 5, 'title': 'Frost Master'},
      },
      eventModifiers: {
        'ice_spawn_rate': 3.0,
        'cold_weather_xp_bonus': 1.8,
        'winter_encounter_chance': 0.5,
      },
      metadata: {
        'theme_color': '#2196F3',
        'background_music': 'winter_magic.mp3',
      },
    );
  }

  // Generate holiday events
  Future<void> _generateHolidayEvents(DateTime date) async {
    // Halloween
    if (date.month == 10 && date.day >= 25 && date.day <= 31) {
      _activeEvents.add(_createHalloweenEvent());
    }
    
    // Christmas
    if (date.month == 12 && date.day >= 20 && date.day <= 25) {
      _activeEvents.add(_createChristmasEvent());
    }
    
    // New Year
    if ((date.month == 12 && date.day >= 31) || (date.month == 1 && date.day <= 2)) {
      _activeEvents.add(_createNewYearEvent());
    }
  }

  // Create Halloween event
  SeasonalEvent _createHalloweenEvent() {
    return SeasonalEvent(
      id: 'spooky_nights_2024',
      name: 'Spooky Nights',
      description: 'Ghostly adventures await in the darkest corners of the realm!',
      type: EventType.holiday,
      startDate: DateTime(DateTime.now().year, 10, 25),
      endDate: DateTime(DateTime.now().year, 11, 1),
      exclusiveQuests: [
        Quest(
          title: 'Ghost Hunter',
          description: 'Hunt for spectral creatures in moonlit locations.',
          type: QuestType.battle,
          level: 5,
          xpReward: 666,
          cardRewards: ['ghost_hunter', 'spectral_blade', 'phantom_cloak'],
          objectives: [
            QuestObjective(
              title: 'Night Explorer',
              description: 'Complete activities after sunset',
              type: 'night_activity',
              requirements: {'night_activities': 7},
              xpReward: 333,
            ),
          ],
        ),
      ],
      specialSpawns: [
        WorldSpawn(
          name: 'Haunted Manor',
          description: 'A spooky mansion where restless spirits roam.',
          type: SpawnType.boss,
          location: GeoLocation(latitude: 0, longitude: 0),
          level: 6,
          availableCards: ['ghost_king', 'shadow_magic', 'halloween_curse'],
          rewards: {'xp': 444, 'cards': 3},
        ),
      ],
      eventRewards: {
        'participation': {'xp': 200, 'title': 'Spirit Seeker'},
        'completion': {'xp': 666, 'cards': 4, 'title': 'Ghost Master'},
      },
      eventModifiers: {
        'shadow_spawn_rate': 4.0,
        'night_xp_bonus': 2.5,
        'spooky_encounter_chance': 0.6,
      },
      metadata: {
        'theme_color': '#FF5722',
        'background_music': 'spooky_nights.mp3',
      },
    );
  }

  // Generate weather-based events
  Future<void> _generateWeatherEvents() async {
    final weatherService = WeatherService();
    final weather = await weatherService.getCurrentWeather();
    
    if (weather != null) {
      if (weather.condition.toLowerCase().contains('rain')) {
        _activeEvents.add(_createRainyDayEvent());
      }
      
      if (weather.temperature > 30) {
        _activeOffers.add(_createHeatWaveOffer());
      }
    }
  }

  // Create rainy day event
  SeasonalEvent _createRainyDayEvent() {
    return SeasonalEvent(
      id: 'rainy_day_special',
      name: 'Rainy Day Adventure',
      description: 'Don\'t let the rain stop your adventures! Special rewards for brave explorers.',
      type: EventType.special,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(hours: 6)),
      exclusiveQuests: [
        Quest(
          title: 'Rain Walker',
          description: 'Take 3000 steps in the rain to prove your dedication.',
          type: QuestType.fitness,
          level: 2,
          xpReward: 200,
          cardRewards: ['rain_cloak', 'storm_boots'],
          objectives: [
            QuestObjective(
              title: 'Dancing in the Rain',
              description: 'Walk in rainy weather',
              type: 'weather_steps',
              requirements: {'steps': 3000, 'weather': 'rain'},
              xpReward: 150,
            ),
          ],
        ),
      ],
      specialSpawns: [],
      eventRewards: {
        'participation': {'xp': 100, 'title': 'Rain Dancer'},
      },
      eventModifiers: {
        'water_spawn_rate': 3.0,
        'rain_xp_bonus': 1.5,
      },
      metadata: {
        'theme_color': '#03A9F4',
      },
    );
  }

  // Generate limited-time offers
  Future<void> _generateLimitedTimeOffers() async {
    _activeOffers.add(LimitedTimeOffer(
      id: 'daily_bonus_${DateTime.now().day}',
      title: 'Explorer\'s Daily Bonus',
      description: 'Complete any quest today for bonus rewards!',
      rewards: {'xp': 150, 'gold': 200},
      requirements: {'quests_completed': 1},
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    ));

    _activeOffers.add(LimitedTimeOffer(
      id: 'weekend_warrior',
      title: 'Weekend Warrior Special',
      description: 'Take 15,000 steps this weekend for epic rewards!',
      rewards: {'xp': 500, 'cards': 3, 'title': 'Weekend Warrior'},
      requirements: {'steps': 15000, 'timeframe': 'weekend'},
      expiresAt: _getNextSunday(),
    ));
  }

  // Create heat wave offer
  LimitedTimeOffer _createHeatWaveOffer() {
    return LimitedTimeOffer(
      id: 'heat_wave_challenge',
      title: 'Heat Wave Challenge',
      description: 'Stay active during the hot weather for cooling rewards!',
      rewards: {'xp': 300, 'cards': 2, 'item': 'cooling_potion'},
      requirements: {'hot_weather_activities': 5, 'min_temperature': 30},
      expiresAt: DateTime.now().add(const Duration(hours: 12)),
    );
  }

  // Helper methods
  DateTime _getNextSunday() {
    final now = DateTime.now();
    final daysUntilSunday = 7 - now.weekday;
    return now.add(Duration(days: daysUntilSunday)).copyWith(
      hour: 23,
      minute: 59,
      second: 59,
    );
  }

  SeasonalEvent _createChristmasEvent() {
    return SeasonalEvent(
      id: 'winter_celebration_2024',
      name: 'Winter Celebration',
      description: 'Spread joy and discover magical winter gifts!',
      type: EventType.holiday,
      startDate: DateTime(DateTime.now().year, 12, 20),
      endDate: DateTime(DateTime.now().year, 12, 26),
      exclusiveQuests: [
        Quest(
          title: 'Gift Giver',
          description: 'Share the spirit of giving by completing social quests.',
          type: QuestType.social,
          level: 3,
          xpReward: 500,
          cardRewards: ['winter_gift', 'holiday_spirit', 'snow_angel'],
        ),
      ],
      specialSpawns: [],
      eventRewards: {
        'participation': {'xp': 250, 'title': 'Holiday Helper'},
        'completion': {'xp': 750, 'cards': 4, 'title': 'Winter Celebrant'},
      },
      eventModifiers: {
        'gift_spawn_rate': 2.0,
        'holiday_xp_bonus': 2.0,
      },
      metadata: {
        'theme_color': '#4CAF50',
        'background_music': 'winter_celebration.mp3',
      },
    );
  }

  SeasonalEvent _createNewYearEvent() {
    return SeasonalEvent(
      id: 'new_year_resolutions_2024',
      name: 'New Year Resolutions',
      description: 'Start the year with fresh adventure goals!',
      type: EventType.holiday,
      startDate: DateTime(DateTime.now().year, 12, 31),
      endDate: DateTime(DateTime.now().year + 1, 1, 7),
      exclusiveQuests: [
        Quest(
          title: 'Resolution Keeper',
          description: 'Set and achieve your first adventure goal of the year.',
          type: QuestType.fitness,
          level: 1,
          xpReward: 365,
          cardRewards: ['new_year_blessing', 'resolution_charm', 'fresh_start'],
        ),
      ],
      specialSpawns: [],
      eventRewards: {
        'participation': {'xp': 200, 'title': 'Resolution Setter'},
        'completion': {'xp': 500, 'cards': 3, 'title': 'New Year Champion'},
      },
      eventModifiers: {
        'motivation_bonus': 2.0,
        'goal_xp_bonus': 1.5,
      },
      metadata: {
        'theme_color': '#FFD700',
        'background_music': 'new_year_fanfare.mp3',
      },
    );
  }

  void _startEventUpdateTimer() {
    _eventUpdateTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _updateEventStatus();
    });
  }

  Future<void> _updateEventStatus() async {
    // Remove expired events
    _activeEvents.removeWhere((event) => !event.isCurrentlyActive);
    _activeOffers.removeWhere((offer) => !offer.isAvailable);
    
    // Check for new seasonal content
    await _generateSeasonalContent();
  }

  Future<void> _loadActiveEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getString('active_events');
      final offersJson = prefs.getString('active_offers');
      
      if (eventsJson != null) {
        final eventsList = jsonDecode(eventsJson) as List;
        _activeEvents = eventsList
            .map((json) => SeasonalEvent.fromJson(json))
            .where((event) => event.isCurrentlyActive)
            .toList();
      }
      
      if (offersJson != null) {
        final offersList = jsonDecode(offersJson) as List;
        _activeOffers = offersList
            .map((json) => LimitedTimeOffer.fromJson(json))
            .where((offer) => offer.isAvailable)
            .toList();
      }
    } catch (e) {
      print('Error loading active events: $e');
    }
  }

  Future<void> _saveActiveEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = jsonEncode(_activeEvents.map((e) => e.toJson()).toList());
      final offersJson = jsonEncode(_activeOffers.map((o) => o.toJson()).toList());
      
      await prefs.setString('active_events', eventsJson);
      await prefs.setString('active_offers', offersJson);
    } catch (e) {
      print('Error saving active events: $e');
    }
  }

  // Cleanup
  void dispose() {
    _eventController.close();
    _offerController.close();
    _eventUpdateTimer?.cancel();
  }
}