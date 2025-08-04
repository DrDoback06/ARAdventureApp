import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/event_bus.dart';
import 'integration_orchestrator_agent.dart';

/// Weather conditions
enum WeatherCondition {
  clear,
  partlyCloudy,
  cloudy,
  overcast,
  mist,
  fog,
  lightRain,
  rain,
  heavyRain,
  thunderstorm,
  lightSnow,
  snow,
  heavySnow,
  sleet,
  hail,
  windy,
  hurricane,
  tornado,
}

/// Weather intensity levels
enum WeatherIntensity {
  none,
  light,
  moderate,
  heavy,
  extreme,
}

/// Time of day
enum TimeOfDay {
  dawn,
  morning,
  midday,
  afternoon,
  evening,
  night,
  lateNight,
}

/// Season
enum Season {
  spring,
  summer,
  autumn,
  winter,
}

/// Weather data structure
class WeatherData {
  final WeatherCondition condition;
  final WeatherIntensity intensity;
  final double temperature; // Celsius
  final double humidity; // 0-100%
  final double windSpeed; // km/h
  final double windDirection; // degrees
  final double pressure; // hPa
  final double visibility; // km
  final double uvIndex; // 0-11+
  final DateTime timestamp;
  final String location;
  final Map<String, dynamic> rawData;

  WeatherData({
    required this.condition,
    this.intensity = WeatherIntensity.none,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.pressure,
    required this.visibility,
    required this.uvIndex,
    DateTime? timestamp,
    required this.location,
    Map<String, dynamic>? rawData,
  }) : timestamp = timestamp ?? DateTime.now(),
       rawData = rawData ?? {};

  Map<String, dynamic> toJson() {
    return {
      'condition': condition.toString(),
      'intensity': intensity.toString(),
      'temperature': temperature,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'windDirection': windDirection,
      'pressure': pressure,
      'visibility': visibility,
      'uvIndex': uvIndex,
      'timestamp': timestamp.toIso8601String(),
      'location': location,
      'rawData': rawData,
    };
  }

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      condition: WeatherCondition.values.firstWhere(
        (c) => c.toString() == json['condition'],
        orElse: () => WeatherCondition.clear,
      ),
      intensity: WeatherIntensity.values.firstWhere(
        (i) => i.toString() == json['intensity'],
        orElse: () => WeatherIntensity.none,
      ),
      temperature: (json['temperature'] ?? 20.0).toDouble(),
      humidity: (json['humidity'] ?? 50.0).toDouble(),
      windSpeed: (json['windSpeed'] ?? 0.0).toDouble(),
      windDirection: (json['windDirection'] ?? 0.0).toDouble(),
      pressure: (json['pressure'] ?? 1013.0).toDouble(),
      visibility: (json['visibility'] ?? 10.0).toDouble(),
      uvIndex: (json['uvIndex'] ?? 0.0).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      location: json['location'] ?? '',
      rawData: Map<String, dynamic>.from(json['rawData'] ?? {}),
    );
  }
}

/// Weather forecast
class WeatherForecast {
  final List<WeatherData> hourlyForecast;
  final List<WeatherData> dailyForecast;
  final DateTime lastUpdated;
  final String source;

  WeatherForecast({
    List<WeatherData>? hourlyForecast,
    List<WeatherData>? dailyForecast,
    DateTime? lastUpdated,
    this.source = 'simulated',
  }) : hourlyForecast = hourlyForecast ?? [],
       dailyForecast = dailyForecast ?? [],
       lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'hourlyForecast': hourlyForecast.map((w) => w.toJson()).toList(),
      'dailyForecast': dailyForecast.map((w) => w.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'source': source,
    };
  }

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      hourlyForecast: (json['hourlyForecast'] as List? ?? [])
          .map((w) => WeatherData.fromJson(w))
          .toList(),
      dailyForecast: (json['dailyForecast'] as List? ?? [])
          .map((w) => WeatherData.fromJson(w))
          .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      source: json['source'] ?? 'simulated',
    );
  }
}

/// Weather effect on gameplay
class WeatherEffect {
  final String effectId;
  final String name;
  final String description;
  final WeatherCondition triggeredBy;
  final WeatherIntensity minimumIntensity;
  final Map<String, double> statModifiers;
  final Map<String, double> spawnRateModifiers;
  final List<String> enabledQuests;
  final List<String> disabledQuests;
  final Map<String, dynamic> specialEffects;
  final Duration duration;
  final bool isActive;

  WeatherEffect({
    String? effectId,
    required this.name,
    required this.description,
    required this.triggeredBy,
    this.minimumIntensity = WeatherIntensity.light,
    Map<String, double>? statModifiers,
    Map<String, double>? spawnRateModifiers,
    List<String>? enabledQuests,
    List<String>? disabledQuests,
    Map<String, dynamic>? specialEffects,
    this.duration = const Duration(hours: 1),
    this.isActive = false,
  }) : effectId = effectId ?? 'effect_${DateTime.now().millisecondsSinceEpoch}',
       statModifiers = statModifiers ?? {},
       spawnRateModifiers = spawnRateModifiers ?? {},
       enabledQuests = enabledQuests ?? [],
       disabledQuests = disabledQuests ?? [],
       specialEffects = specialEffects ?? {};

  WeatherEffect copyWith({
    bool? isActive,
  }) {
    return WeatherEffect(
      effectId: effectId,
      name: name,
      description: description,
      triggeredBy: triggeredBy,
      minimumIntensity: minimumIntensity,
      statModifiers: Map.from(statModifiers),
      spawnRateModifiers: Map.from(spawnRateModifiers),
      enabledQuests: List.from(enabledQuests),
      disabledQuests: List.from(disabledQuests),
      specialEffects: Map.from(specialEffects),
      duration: duration,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'effectId': effectId,
      'name': name,
      'description': description,
      'triggeredBy': triggeredBy.toString(),
      'minimumIntensity': minimumIntensity.toString(),
      'statModifiers': statModifiers,
      'spawnRateModifiers': spawnRateModifiers,
      'enabledQuests': enabledQuests,
      'disabledQuests': disabledQuests,
      'specialEffects': specialEffects,
      'duration': duration.inMilliseconds,
      'isActive': isActive,
    };
  }

  factory WeatherEffect.fromJson(Map<String, dynamic> json) {
    return WeatherEffect(
      effectId: json['effectId'],
      name: json['name'],
      description: json['description'],
      triggeredBy: WeatherCondition.values.firstWhere(
        (c) => c.toString() == json['triggeredBy'],
        orElse: () => WeatherCondition.clear,
      ),
      minimumIntensity: WeatherIntensity.values.firstWhere(
        (i) => i.toString() == json['minimumIntensity'],
        orElse: () => WeatherIntensity.light,
      ),
      statModifiers: Map<String, double>.from(json['statModifiers'] ?? {}),
      spawnRateModifiers: Map<String, double>.from(json['spawnRateModifiers'] ?? {}),
      enabledQuests: List<String>.from(json['enabledQuests'] ?? []),
      disabledQuests: List<String>.from(json['disabledQuests'] ?? []),
      specialEffects: Map<String, dynamic>.from(json['specialEffects'] ?? {}),
      duration: Duration(milliseconds: json['duration'] ?? 3600000),
      isActive: json['isActive'] ?? false,
    );
  }
}

/// Environmental gameplay state
class EnvironmentalState {
  final WeatherData currentWeather;
  final TimeOfDay timeOfDay;
  final Season season;
  final double moonPhase; // 0.0 = new moon, 1.0 = full moon
  final List<WeatherEffect> activeEffects;
  final Map<String, double> environmentalBonuses;
  final DateTime lastUpdated;

  EnvironmentalState({
    required this.currentWeather,
    required this.timeOfDay,
    required this.season,
    this.moonPhase = 0.5,
    List<WeatherEffect>? activeEffects,
    Map<String, double>? environmentalBonuses,
    DateTime? lastUpdated,
  }) : activeEffects = activeEffects ?? [],
       environmentalBonuses = environmentalBonuses ?? {},
       lastUpdated = lastUpdated ?? DateTime.now();

  EnvironmentalState copyWith({
    WeatherData? currentWeather,
    TimeOfDay? timeOfDay,
    Season? season,
    double? moonPhase,
    List<WeatherEffect>? activeEffects,
    Map<String, double>? environmentalBonuses,
    DateTime? lastUpdated,
  }) {
    return EnvironmentalState(
      currentWeather: currentWeather ?? this.currentWeather,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      season: season ?? this.season,
      moonPhase: moonPhase ?? this.moonPhase,
      activeEffects: activeEffects ?? List.from(this.activeEffects),
      environmentalBonuses: environmentalBonuses ?? Map.from(this.environmentalBonuses),
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentWeather': currentWeather.toJson(),
      'timeOfDay': timeOfDay.toString(),
      'season': season.toString(),
      'moonPhase': moonPhase,
      'activeEffects': activeEffects.map((e) => e.toJson()).toList(),
      'environmentalBonuses': environmentalBonuses,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory EnvironmentalState.fromJson(Map<String, dynamic> json) {
    return EnvironmentalState(
      currentWeather: WeatherData.fromJson(json['currentWeather']),
      timeOfDay: TimeOfDay.values.firstWhere(
        (t) => t.toString() == json['timeOfDay'],
        orElse: () => TimeOfDay.midday,
      ),
      season: Season.values.firstWhere(
        (s) => s.toString() == json['season'],
        orElse: () => Season.spring,
      ),
      moonPhase: (json['moonPhase'] ?? 0.5).toDouble(),
      activeEffects: (json['activeEffects'] as List? ?? [])
          .map((e) => WeatherEffect.fromJson(e))
          .toList(),
      environmentalBonuses: Map<String, double>.from(json['environmentalBonuses'] ?? {}),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
}

/// Weather Integration Agent - Real-world weather affects gameplay
class WeatherIntegrationAgent extends BaseAgent {
  static const String agentId = 'weather_integration';

  final SharedPreferences _prefs;

  // Current environmental state
  EnvironmentalState? _currentState;
  WeatherForecast? _forecast;

  // Weather effects library
  final Map<String, WeatherEffect> _weatherEffects = {};
  final Map<WeatherCondition, List<String>> _conditionEffects = {};

  // Location tracking
  double? _currentLatitude;
  double? _currentLongitude;
  String? _currentLocation;

  // Update timers
  Timer? _weatherUpdateTimer;
  Timer? _timeUpdateTimer;
  Timer? _effectsUpdateTimer;

  // Performance tracking
  final List<Map<String, dynamic>> _weatherHistory = [];
  int _totalWeatherUpdates = 0;
  DateTime? _lastWeatherUpdate;

  WeatherIntegrationAgent({
    required SharedPreferences prefs,
  }) : _prefs = prefs,
       super(agentId: agentId);

  @override
  Future<void> onInitialize() async {
    developer.log('Initializing Weather Integration Agent', name: agentId);

    // Load weather data
    await _loadWeatherData();

    // Initialize weather effects
    await _initializeWeatherEffects();

    // Start update timers
    _startWeatherUpdates();
    _startTimeUpdates();
    _startEffectsUpdates();

    // Initialize with default state if needed
    if (_currentState == null) {
      await _initializeDefaultState();
    }

    developer.log('Weather Integration Agent initialized with ${_weatherEffects.length} weather effects', name: agentId);
  }

  @override
  void subscribeToEvents() {
    // Location events for weather updates
    subscribe(EventTypes.locationUpdate, _handleLocationUpdate);

    // Quest events for weather-dependent content
    subscribe(EventTypes.questStarted, _handleQuestStarted);
    subscribe(EventTypes.questCompleted, _handleQuestCompleted);

    // Battle events for weather effects
    subscribe(EventTypes.battleStarted, _handleBattleStarted);
    subscribe(EventTypes.battleTurnResolved, _handleBattleTurn);

    // Character events for environmental bonuses
    subscribe(EventTypes.characterUpdated, _handleCharacterUpdate);

    // AR events for environmental effects
    subscribe(EventTypes.arExperienceTriggered, _handleARExperience);

    // Weather-specific events
    subscribe('weather_request_update', _handleWeatherUpdateRequest);
    subscribe('weather_get_current', _handleGetCurrentWeather);
    subscribe('weather_get_forecast', _handleGetForecast);
    subscribe('weather_set_location', _handleSetLocation);

    // User management
    subscribe('user_login', _handleUserLogin);
    subscribe('user_logout', _handleUserLogout);
  }

  /// Get current weather data
  WeatherData? getCurrentWeather() {
    return _currentState?.currentWeather;
  }

  /// Get current environmental state
  EnvironmentalState? getEnvironmentalState() {
    return _currentState;
  }

  /// Get weather forecast
  WeatherForecast? getWeatherForecast() {
    return _forecast;
  }

  /// Update location for weather tracking
  void updateLocation(double latitude, double longitude, {String? locationName}) {
    _currentLatitude = latitude;
    _currentLongitude = longitude;
    _currentLocation = locationName ?? 'Unknown Location';

    // Trigger weather update for new location
    _updateWeatherData();

    publishEvent(createEvent(
      eventType: 'weather_location_updated',
      data: {
        'latitude': latitude,
        'longitude': longitude,
        'location': _currentLocation,
      },
    ));

    developer.log('Weather location updated: $_currentLocation', name: agentId);
  }

  /// Force weather update
  Future<void> forceWeatherUpdate() async {
    await _updateWeatherData();
  }

  /// Get active weather effects
  List<WeatherEffect> getActiveWeatherEffects() {
    return _currentState?.activeEffects ?? [];
  }

  /// Get environmental bonuses
  Map<String, double> getEnvironmentalBonuses() {
    return _currentState?.environmentalBonuses ?? {};
  }

  /// Check if weather condition enables specific content
  bool isWeatherContentEnabled(String contentId, WeatherCondition condition) {
    final effects = _getEffectsForCondition(condition);
    return effects.any((effect) => effect.enabledQuests.contains(contentId));
  }

  /// Get weather analytics
  Map<String, dynamic> getWeatherAnalytics() {
    final recentHistory = _weatherHistory.take(24).toList(); // Last 24 hours
    
    final conditionCounts = <String, int>{};
    for (final record in recentHistory) {
      final condition = record['condition'] as String? ?? 'unknown';
      conditionCounts[condition] = (conditionCounts[condition] ?? 0) + 1;
    }

    return {
      'currentWeather': _currentState?.currentWeather.toJson(),
      'location': _currentLocation,
      'totalUpdates': _totalWeatherUpdates,
      'lastUpdate': _lastWeatherUpdate?.toIso8601String(),
      'activeEffects': getActiveWeatherEffects().length,
      'environmentalBonuses': getEnvironmentalBonuses(),
      'recentConditions': conditionCounts,
      'forecastHours': _forecast?.hourlyForecast.length ?? 0,
      'forecastDays': _forecast?.dailyForecast.length ?? 0,
    };
  }

  /// Initialize default environmental state
  Future<void> _initializeDefaultState() async {
    final defaultWeather = WeatherData(
      condition: WeatherCondition.clear,
      temperature: 22.0,
      humidity: 60.0,
      windSpeed: 5.0,
      windDirection: 180.0,
      pressure: 1013.25,
      visibility: 10.0,
      uvIndex: 5.0,
      location: _currentLocation ?? 'Default Location',
    );

    _currentState = EnvironmentalState(
      currentWeather: defaultWeather,
      timeOfDay: _calculateTimeOfDay(DateTime.now()),
      season: _calculateSeason(DateTime.now()),
      moonPhase: _calculateMoonPhase(DateTime.now()),
    );

    await _updateEnvironmentalEffects();
  }

  /// Initialize weather effects library
  Future<void> _initializeWeatherEffects() async {
    // Clear weather effects
    _weatherEffects['sunny_boost'] = WeatherEffect(
      name: 'Sunny Day Boost',
      description: 'Clear skies increase XP gain and energy regeneration',
      triggeredBy: WeatherCondition.clear,
      statModifiers: {
        'xp_multiplier': 1.2,
        'energy_regen': 1.3,
        'movement_speed': 1.1,
      },
      spawnRateModifiers: {
        'fire_creatures': 1.5,
        'light_creatures': 2.0,
      },
      enabledQuests: ['solar_collection', 'daylight_exploration'],
      specialEffects: {
        'enhanced_visibility': true,
        'solar_charging': true,
      },
    );

    // Rainy weather effects
    _weatherEffects['rain_mystique'] = WeatherEffect(
      name: 'Rain Mystique',
      description: 'Rain enhances water magic and reveals hidden creatures',
      triggeredBy: WeatherCondition.rain,
      minimumIntensity: WeatherIntensity.light,
      statModifiers: {
        'water_magic_power': 1.5,
        'stealth': 1.2,
        'visibility': 0.8,
      },
      spawnRateModifiers: {
        'water_creatures': 2.0,
        'rare_creatures': 1.3,
        'fire_creatures': 0.5,
      },
      enabledQuests: ['rain_ritual', 'water_collection', 'storm_chase'],
      specialEffects: {
        'puddle_reflections': true,
        'enhanced_water_spells': true,
        'rain_sounds': true,
      },
    );

    // Snow weather effects
    _weatherEffects['winter_wonder'] = WeatherEffect(
      name: 'Winter Wonder',
      description: 'Snow conditions enable ice magic and winter creatures',
      triggeredBy: WeatherCondition.snow,
      statModifiers: {
        'ice_magic_power': 1.8,
        'cold_resistance': 1.5,
        'movement_speed': 0.8,
      },
      spawnRateModifiers: {
        'ice_creatures': 3.0,
        'winter_spirits': 2.5,
        'fire_creatures': 0.3,
      },
      enabledQuests: ['ice_crystal_hunt', 'snowflake_collection', 'winter_solstice'],
      specialEffects: {
        'snow_trails': true,
        'ice_formations': true,
        'crystalline_effects': true,
      },
    );

    // Thunderstorm effects
    _weatherEffects['storm_power'] = WeatherEffect(
      name: 'Storm Power',
      description: 'Thunderstorms supercharge lightning magic and electric creatures',
      triggeredBy: WeatherCondition.thunderstorm,
      minimumIntensity: WeatherIntensity.moderate,
      statModifiers: {
        'lightning_magic_power': 2.0,
        'electric_resistance': 1.3,
        'critical_chance': 1.4,
      },
      spawnRateModifiers: {
        'electric_creatures': 4.0,
        'storm_elementals': 3.0,
        'legendary_creatures': 1.8,
      },
      enabledQuests: ['lightning_rod', 'storm_chasing', 'thunder_collection'],
      specialEffects: {
        'lightning_strikes': true,
        'electric_auras': true,
        'storm_sounds': true,
      },
    );

    // Fog effects
    _weatherEffects['mystical_fog'] = WeatherEffect(
      name: 'Mystical Fog',
      description: 'Fog creates mysterious conditions and rare encounters',
      triggeredBy: WeatherCondition.fog,
      statModifiers: {
        'mystery_sense': 1.6,
        'stealth': 1.5,
        'visibility': 0.5,
      },
      spawnRateModifiers: {
        'ghost_creatures': 2.5,
        'shadow_creatures': 2.0,
        'rare_creatures': 1.8,
      },
      enabledQuests: ['fog_navigation', 'spirit_commune', 'mist_walking'],
      specialEffects: {
        'reduced_visibility': true,
        'mysterious_sounds': true,
        'phantom_appearances': true,
      },
    );

    // Wind effects
    _weatherEffects['wind_currents'] = WeatherEffect(
      name: 'Wind Currents',
      description: 'Strong winds enhance air magic and flying creatures',
      triggeredBy: WeatherCondition.windy,
      minimumIntensity: WeatherIntensity.moderate,
      statModifiers: {
        'air_magic_power': 1.4,
        'movement_speed': 1.2,
        'projectile_accuracy': 0.8,
      },
      spawnRateModifiers: {
        'flying_creatures': 2.5,
        'air_elementals': 2.0,
      },
      enabledQuests: ['wind_surfing', 'air_current_mapping', 'feather_collection'],
      specialEffects: {
        'wind_effects': true,
        'leaf_swirls': true,
        'enhanced_flight': true,
      },
    );

    // Map effects to conditions
    _conditionEffects.clear();
    for (final effect in _weatherEffects.values) {
      final condition = effect.triggeredBy;
      _conditionEffects[condition] ??= [];
      _conditionEffects[condition]!.add(effect.effectId);
    }

    developer.log('Weather effects library initialized', name: agentId);
  }

  /// Update weather data (simulated or from API)
  Future<void> _updateWeatherData() async {
    try {
      // In a real implementation, this would call a weather API
      // For now, we'll simulate realistic weather data
      final weather = _simulateWeatherData();
      
      final timeOfDay = _calculateTimeOfDay(DateTime.now());
      final season = _calculateSeason(DateTime.now());
      final moonPhase = _calculateMoonPhase(DateTime.now());

      _currentState = EnvironmentalState(
        currentWeather: weather,
        timeOfDay: timeOfDay,
        season: season,
        moonPhase: moonPhase,
      );

      // Update environmental effects
      await _updateEnvironmentalEffects();

      // Generate forecast
      _forecast = _generateWeatherForecast(weather);

      // Track weather history
      _weatherHistory.add({
        'condition': weather.condition.toString(),
        'temperature': weather.temperature,
        'humidity': weather.humidity,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Keep only last 168 hours (7 days)
      if (_weatherHistory.length > 168) {
        _weatherHistory.removeAt(0);
      }

      _totalWeatherUpdates++;
      _lastWeatherUpdate = DateTime.now();

      // Publish weather update event
      publishEvent(createEvent(
        eventType: 'weather_updated',
        data: {
          'weather': weather.toJson(),
          'timeOfDay': timeOfDay.toString(),
          'season': season.toString(),
          'moonPhase': moonPhase,
          'activeEffects': _currentState!.activeEffects.length,
        },
      ));

      developer.log('Weather updated: ${weather.condition} at ${weather.temperature}°C', name: agentId);

    } catch (e) {
      developer.log('Error updating weather data: $e', name: agentId);
    }
  }

  /// Simulate realistic weather data
  WeatherData _simulateWeatherData() {
    final now = DateTime.now();
    final season = _calculateSeason(now);
    final timeOfDay = _calculateTimeOfDay(now);
    final random = math.Random();

    // Base temperature ranges by season
    double baseTemp;
    switch (season) {
      case Season.spring:
        baseTemp = 15.0 + random.nextDouble() * 15.0; // 15-30°C
        break;
      case Season.summer:
        baseTemp = 20.0 + random.nextDouble() * 20.0; // 20-40°C
        break;
      case Season.autumn:
        baseTemp = 10.0 + random.nextDouble() * 15.0; // 10-25°C
        break;
      case Season.winter:
        baseTemp = -5.0 + random.nextDouble() * 15.0; // -5-10°C
        break;
    }

    // Adjust for time of day
    switch (timeOfDay) {
      case TimeOfDay.dawn:
      case TimeOfDay.night:
      case TimeOfDay.lateNight:
        baseTemp -= 5.0;
        break;
      case TimeOfDay.morning:
      case TimeOfDay.evening:
        baseTemp -= 2.0;
        break;
      case TimeOfDay.midday:
        baseTemp += 3.0;
        break;
      case TimeOfDay.afternoon:
        baseTemp += 1.0;
        break;
    }

    // Determine weather condition based on season and randomness
    WeatherCondition condition;
    WeatherIntensity intensity = WeatherIntensity.none;
    
    final conditionRoll = random.nextDouble();
    
    if (season == Season.winter && baseTemp < 0) {
      if (conditionRoll < 0.3) {
        condition = WeatherCondition.snow;
        intensity = WeatherIntensity.values[random.nextInt(WeatherIntensity.values.length)];
      } else if (conditionRoll < 0.6) {
        condition = WeatherCondition.cloudy;
      } else {
        condition = WeatherCondition.clear;
      }
    } else if (season == Season.summer) {
      if (conditionRoll < 0.1) {
        condition = WeatherCondition.thunderstorm;
        intensity = WeatherIntensity.moderate;
      } else if (conditionRoll < 0.2) {
        condition = WeatherCondition.rain;
        intensity = WeatherIntensity.light;
      } else if (conditionRoll < 0.4) {
        condition = WeatherCondition.partlyCloudy;
      } else {
        condition = WeatherCondition.clear;
      }
    } else {
      // Spring/Autumn
      if (conditionRoll < 0.2) {
        condition = WeatherCondition.rain;
        intensity = WeatherIntensity.values[1 + random.nextInt(3)]; // light to heavy
      } else if (conditionRoll < 0.4) {
        condition = WeatherCondition.cloudy;
      } else if (conditionRoll < 0.6) {
        condition = WeatherCondition.partlyCloudy;
      } else if (conditionRoll < 0.05) {
        condition = WeatherCondition.fog;
        intensity = WeatherIntensity.moderate;
      } else {
        condition = WeatherCondition.clear;
      }
    }

    // Add special weather effects occasionally
    if (random.nextDouble() < 0.05) { // 5% chance
      final specialWeathers = [
        WeatherCondition.thunderstorm,
        WeatherCondition.fog,
        WeatherCondition.windy,
        WeatherCondition.hail,
      ];
      condition = specialWeathers[random.nextInt(specialWeathers.length)];
      intensity = WeatherIntensity.moderate;
    }

    return WeatherData(
      condition: condition,
      intensity: intensity,
      temperature: baseTemp,
      humidity: 30.0 + random.nextDouble() * 60.0, // 30-90%
      windSpeed: random.nextDouble() * 30.0, // 0-30 km/h
      windDirection: random.nextDouble() * 360.0,
      pressure: 980.0 + random.nextDouble() * 60.0, // 980-1040 hPa
      visibility: condition == WeatherCondition.fog ? 0.5 + random.nextDouble() * 2.0 : 5.0 + random.nextDouble() * 15.0,
      uvIndex: timeOfDay == TimeOfDay.midday || timeOfDay == TimeOfDay.afternoon 
          ? random.nextDouble() * 11.0 
          : 0.0,
      location: _currentLocation ?? 'Simulated Location',
    );
  }

  /// Generate weather forecast
  WeatherForecast _generateWeatherForecast(WeatherData currentWeather) {
    final hourlyForecast = <WeatherData>[];
    final dailyForecast = <WeatherData>[];
    final random = math.Random();

    // Generate 24-hour forecast
    var baseCondition = currentWeather.condition;
    var baseTemp = currentWeather.temperature;
    
    for (int i = 1; i <= 24; i++) {
      final hour = DateTime.now().add(Duration(hours: i));
      final timeOfDay = _calculateTimeOfDay(hour);
      
      // Evolve weather gradually
      if (random.nextDouble() < 0.1) { // 10% chance of weather change each hour
        baseCondition = _getRandomAdjacentWeatherCondition(baseCondition);
      }
      
      // Temperature variation by time of day
      var hourTemp = baseTemp;
      switch (timeOfDay) {
        case TimeOfDay.dawn:
        case TimeOfDay.night:
          hourTemp -= 3.0;
          break;
        case TimeOfDay.morning:
        case TimeOfDay.evening:
          hourTemp -= 1.0;
          break;
        case TimeOfDay.midday:
          hourTemp += 4.0;
          break;
        case TimeOfDay.afternoon:
          hourTemp += 2.0;
          break;
        case TimeOfDay.lateNight:
          hourTemp -= 5.0;
          break;
      }

      hourlyForecast.add(WeatherData(
        condition: baseCondition,
        temperature: hourTemp + (random.nextDouble() - 0.5) * 4.0, // ±2°C variation
        humidity: currentWeather.humidity + (random.nextDouble() - 0.5) * 20.0,
        windSpeed: currentWeather.windSpeed + (random.nextDouble() - 0.5) * 10.0,
        windDirection: currentWeather.windDirection + (random.nextDouble() - 0.5) * 60.0,
        pressure: currentWeather.pressure + (random.nextDouble() - 0.5) * 10.0,
        visibility: currentWeather.visibility + (random.nextDouble() - 0.5) * 5.0,
        uvIndex: timeOfDay == TimeOfDay.midday || timeOfDay == TimeOfDay.afternoon 
            ? random.nextDouble() * 11.0 
            : 0.0,
        timestamp: hour,
        location: currentWeather.location,
      ));
    }

    // Generate 7-day forecast (daily averages)
    for (int i = 1; i <= 7; i++) {
      final day = DateTime.now().add(Duration(days: i));
      
      // Gradual weather evolution over days
      if (random.nextDouble() < 0.3) { // 30% chance of weather change each day
        baseCondition = _getRandomAdjacentWeatherCondition(baseCondition);
      }
      
      dailyForecast.add(WeatherData(
        condition: baseCondition,
        temperature: baseTemp + (random.nextDouble() - 0.5) * 8.0, // ±4°C variation
        humidity: currentWeather.humidity + (random.nextDouble() - 0.5) * 30.0,
        windSpeed: currentWeather.windSpeed + (random.nextDouble() - 0.5) * 15.0,
        windDirection: currentWeather.windDirection + (random.nextDouble() - 0.5) * 120.0,
        pressure: currentWeather.pressure + (random.nextDouble() - 0.5) * 20.0,
        visibility: currentWeather.visibility + (random.nextDouble() - 0.5) * 8.0,
        uvIndex: random.nextDouble() * 11.0,
        timestamp: day,
        location: currentWeather.location,
      ));
    }

    return WeatherForecast(
      hourlyForecast: hourlyForecast,
      dailyForecast: dailyForecast,
      source: 'simulated',
    );
  }

  /// Get random adjacent weather condition for realistic transitions
  WeatherCondition _getRandomAdjacentWeatherCondition(WeatherCondition current) {
    final random = math.Random();
    
    switch (current) {
      case WeatherCondition.clear:
        return [WeatherCondition.partlyCloudy, WeatherCondition.cloudy][random.nextInt(2)];
      case WeatherCondition.partlyCloudy:
        return [WeatherCondition.clear, WeatherCondition.cloudy, WeatherCondition.lightRain][random.nextInt(3)];
      case WeatherCondition.cloudy:
        return [WeatherCondition.partlyCloudy, WeatherCondition.overcast, WeatherCondition.lightRain][random.nextInt(3)];
      case WeatherCondition.overcast:
        return [WeatherCondition.cloudy, WeatherCondition.lightRain, WeatherCondition.rain][random.nextInt(3)];
      case WeatherCondition.lightRain:
        return [WeatherCondition.cloudy, WeatherCondition.rain, WeatherCondition.mist][random.nextInt(3)];
      case WeatherCondition.rain:
        return [WeatherCondition.lightRain, WeatherCondition.heavyRain, WeatherCondition.thunderstorm][random.nextInt(3)];
      case WeatherCondition.heavyRain:
        return [WeatherCondition.rain, WeatherCondition.thunderstorm][random.nextInt(2)];
      case WeatherCondition.thunderstorm:
        return [WeatherCondition.heavyRain, WeatherCondition.rain][random.nextInt(2)];
      case WeatherCondition.fog:
        return [WeatherCondition.mist, WeatherCondition.cloudy][random.nextInt(2)];
      case WeatherCondition.mist:
        return [WeatherCondition.fog, WeatherCondition.cloudy, WeatherCondition.clear][random.nextInt(3)];
      default:
        return WeatherCondition.clear;
    }
  }

  /// Update environmental effects based on current conditions
  Future<void> _updateEnvironmentalEffects() async {
    if (_currentState == null) return;

    final currentWeather = _currentState!.currentWeather;
    final activeEffects = <WeatherEffect>[];
    final environmentalBonuses = <String, double>{};

    // Find applicable weather effects
    final effectIds = _conditionEffects[currentWeather.condition] ?? [];
    for (final effectId in effectIds) {
      final effect = _weatherEffects[effectId];
      if (effect != null && 
          _isEffectApplicable(effect, currentWeather)) {
        activeEffects.add(effect.copyWith(isActive: true));
        
        // Apply stat modifiers
        for (final entry in effect.statModifiers.entries) {
          environmentalBonuses[entry.key] = 
              (environmentalBonuses[entry.key] ?? 1.0) * entry.value;
        }
      }
    }

    // Add time-based bonuses
    _addTimeBasedBonuses(environmentalBonuses);

    // Add seasonal bonuses
    _addSeasonalBonuses(environmentalBonuses);

    // Add moon phase bonuses
    _addMoonPhaseBonuses(environmentalBonuses);

    _currentState = _currentState!.copyWith(
      activeEffects: activeEffects,
      environmentalBonuses: environmentalBonuses,
    );

    // Publish environmental update
    publishEvent(createEvent(
      eventType: 'environmental_effects_updated',
      data: {
        'activeEffects': activeEffects.length,
        'bonuses': environmentalBonuses,
        'weatherCondition': currentWeather.condition.toString(),
      },
    ));
  }

  /// Check if weather effect is applicable
  bool _isEffectApplicable(WeatherEffect effect, WeatherData weather) {
    if (effect.triggeredBy != weather.condition) return false;
    
    // Check intensity requirement
    final intensityIndex = WeatherIntensity.values.indexOf(weather.intensity);
    final requiredIndex = WeatherIntensity.values.indexOf(effect.minimumIntensity);
    
    return intensityIndex >= requiredIndex;
  }

  /// Add time-based environmental bonuses
  void _addTimeBasedBonuses(Map<String, double> bonuses) {
    if (_currentState == null) return;

    switch (_currentState!.timeOfDay) {
      case TimeOfDay.dawn:
        bonuses['dawn_blessing'] = 1.1;
        bonuses['energy_regen'] = (bonuses['energy_regen'] ?? 1.0) * 1.2;
        break;
      case TimeOfDay.midday:
        bonuses['solar_power'] = 1.3;
        bonuses['visibility'] = (bonuses['visibility'] ?? 1.0) * 1.2;
        break;
      case TimeOfDay.night:
        bonuses['stealth'] = (bonuses['stealth'] ?? 1.0) * 1.3;
        bonuses['night_vision'] = 1.2;
        break;
      case TimeOfDay.lateNight:
        bonuses['shadow_magic'] = 1.4;
        bonuses['rare_spawn_rate'] = (bonuses['rare_spawn_rate'] ?? 1.0) * 1.2;
        break;
      default:
        break;
    }
  }

  /// Add seasonal environmental bonuses
  void _addSeasonalBonuses(Map<String, double> bonuses) {
    if (_currentState == null) return;

    switch (_currentState!.season) {
      case Season.spring:
        bonuses['growth_magic'] = 1.2;
        bonuses['healing_power'] = (bonuses['healing_power'] ?? 1.0) * 1.15;
        break;
      case Season.summer:
        bonuses['fire_magic'] = (bonuses['fire_magic'] ?? 1.0) * 1.3;
        bonuses['energy'] = (bonuses['energy'] ?? 1.0) * 1.1;
        break;
      case Season.autumn:
        bonuses['harvest_bonus'] = 1.25;
        bonuses['earth_magic'] = (bonuses['earth_magic'] ?? 1.0) * 1.2;
        break;
      case Season.winter:
        bonuses['ice_magic'] = (bonuses['ice_magic'] ?? 1.0) * 1.4;
        bonuses['endurance'] = (bonuses['endurance'] ?? 1.0) * 1.2;
        break;
    }
  }

  /// Add moon phase bonuses
  void _addMoonPhaseBonuses(Map<String, double> bonuses) {
    if (_currentState == null) return;

    final moonPhase = _currentState!.moonPhase;
    
    if (moonPhase > 0.8) { // Full moon
      bonuses['lunar_power'] = 1.5;
      bonuses['transformation_magic'] = 1.3;
      bonuses['werewolf_spawn_rate'] = 2.0;
    } else if (moonPhase < 0.2) { // New moon
      bonuses['shadow_magic'] = (bonuses['shadow_magic'] ?? 1.0) * 1.3;
      bonuses['stealth'] = (bonuses['stealth'] ?? 1.0) * 1.2;
      bonuses['vampire_spawn_rate'] = 1.8;
    }
  }

  /// Calculate time of day
  TimeOfDay _calculateTimeOfDay(DateTime dateTime) {
    final hour = dateTime.hour;
    
    if (hour >= 5 && hour < 7) return TimeOfDay.dawn;
    if (hour >= 7 && hour < 12) return TimeOfDay.morning;
    if (hour >= 12 && hour < 14) return TimeOfDay.midday;
    if (hour >= 14 && hour < 18) return TimeOfDay.afternoon;
    if (hour >= 18 && hour < 21) return TimeOfDay.evening;
    if (hour >= 21 && hour < 24) return TimeOfDay.night;
    return TimeOfDay.lateNight; // 0-5
  }

  /// Calculate season
  Season _calculateSeason(DateTime dateTime) {
    final month = dateTime.month;
    
    if (month >= 3 && month <= 5) return Season.spring;
    if (month >= 6 && month <= 8) return Season.summer;
    if (month >= 9 && month <= 11) return Season.autumn;
    return Season.winter;
  }

  /// Calculate moon phase (simplified)
  double _calculateMoonPhase(DateTime dateTime) {
    // Simplified moon phase calculation
    // Real implementation would use astronomical calculations
    final daysSinceNewMoon = dateTime.difference(DateTime(2024, 1, 11)).inDays % 29.5;
    return (daysSinceNewMoon / 29.5);
  }

  /// Get effects for weather condition
  List<WeatherEffect> _getEffectsForCondition(WeatherCondition condition) {
    final effectIds = _conditionEffects[condition] ?? [];
    return effectIds.map((id) => _weatherEffects[id]).where((e) => e != null).cast<WeatherEffect>().toList();
  }

  /// Start weather update timer
  void _startWeatherUpdates() {
    _weatherUpdateTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      _updateWeatherData();
    });
  }

  /// Start time update timer
  void _startTimeUpdates() {
    _timeUpdateTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_currentState != null) {
        final newTimeOfDay = _calculateTimeOfDay(DateTime.now());
        if (newTimeOfDay != _currentState!.timeOfDay) {
          _currentState = _currentState!.copyWith(
            timeOfDay: newTimeOfDay,
          );
          _updateEnvironmentalEffects();
        }
      }
    });
  }

  /// Start effects update timer
  void _startEffectsUpdates() {
    _effectsUpdateTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      _updateEnvironmentalEffects();
    });
  }

  /// Load weather data
  Future<void> _loadWeatherData() async {
    try {
      // Load current state
      final stateJson = _prefs.getString('weather_current_state');
      if (stateJson != null) {
        final data = jsonDecode(stateJson) as Map<String, dynamic>;
        _currentState = EnvironmentalState.fromJson(data);
      }

      // Load forecast
      final forecastJson = _prefs.getString('weather_forecast');
      if (forecastJson != null) {
        final data = jsonDecode(forecastJson) as Map<String, dynamic>;
        _forecast = WeatherForecast.fromJson(data);
      }

      // Load location
      _currentLatitude = _prefs.getDouble('weather_latitude');
      _currentLongitude = _prefs.getDouble('weather_longitude');
      _currentLocation = _prefs.getString('weather_location');

      // Load weather history
      final historyJson = _prefs.getString('weather_history');
      if (historyJson != null) {
        final data = jsonDecode(historyJson) as List;
        _weatherHistory.addAll(data.cast<Map<String, dynamic>>());
      }

    } catch (e) {
      developer.log('Error loading weather data: $e', name: agentId);
    }
  }

  /// Save weather data
  Future<void> _saveWeatherData() async {
    try {
      // Save current state
      if (_currentState != null) {
        await _prefs.setString('weather_current_state', jsonEncode(_currentState!.toJson()));
      }

      // Save forecast
      if (_forecast != null) {
        await _prefs.setString('weather_forecast', jsonEncode(_forecast!.toJson()));
      }

      // Save location
      if (_currentLatitude != null) await _prefs.setDouble('weather_latitude', _currentLatitude!);
      if (_currentLongitude != null) await _prefs.setDouble('weather_longitude', _currentLongitude!);
      if (_currentLocation != null) await _prefs.setString('weather_location', _currentLocation!);

      // Save recent weather history
      final recentHistory = _weatherHistory.take(168).toList(); // Last 7 days
      await _prefs.setString('weather_history', jsonEncode(recentHistory));

    } catch (e) {
      developer.log('Error saving weather data: $e', name: agentId);
    }
  }

  // Event Handlers

  /// Handle location update events
  Future<AgentEventResponse?> _handleLocationUpdate(AgentEvent event) async {
    final location = event.data['location'];
    if (location != null) {
      final latitude = location['latitude']?.toDouble();
      final longitude = location['longitude']?.toDouble();
      
      if (latitude != null && longitude != null) {
        updateLocation(latitude, longitude, locationName: location['name']);
      }
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'weather_location_updated',
      data: {
        'weatherLocationSet': location != null,
        'currentLocation': _currentLocation,
      },
    );
  }

  /// Handle quest started events
  Future<AgentEventResponse?> _handleQuestStarted(AgentEvent event) async {
    final questId = event.data['questId'];
    final questType = event.data['type'];
    
    // Check if current weather enables this quest
    final currentWeather = getCurrentWeather();
    if (currentWeather != null) {
      final isEnabled = isWeatherContentEnabled(questId ?? '', currentWeather.condition);
      
      if (isEnabled) {
        // Apply weather bonuses to quest
        final bonuses = getEnvironmentalBonuses();
        
        publishEvent(createEvent(
          eventType: 'weather_quest_bonus_applied',
          data: {
            'questId': questId,
            'questType': questType,
            'weatherCondition': currentWeather.condition.toString(),
            'bonuses': bonuses,
          },
        ));
      }
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'weather_quest_processed',
      data: {
        'questId': questId,
        'weatherAffected': currentWeather != null,
      },
    );
  }

  /// Handle quest completed events
  Future<AgentEventResponse?> _handleQuestCompleted(AgentEvent event) async {
    // Weather-specific quest completion bonuses
    final currentWeather = getCurrentWeather();
    if (currentWeather != null) {
      final bonuses = getEnvironmentalBonuses();
      
      // Apply completion bonuses based on weather
      if (bonuses.isNotEmpty) {
        publishEvent(createEvent(
          eventType: 'weather_completion_bonus',
          data: {
            'questId': event.data['questId'],
            'weatherCondition': currentWeather.condition.toString(),
            'bonuses': bonuses,
          },
        ));
      }
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'weather_quest_completion_processed',
      data: {'weatherBonusApplied': currentWeather != null},
    );
  }

  /// Handle battle started events
  Future<AgentEventResponse?> _handleBattleStarted(AgentEvent event) async {
    final currentWeather = getCurrentWeather();
    if (currentWeather != null) {
      final bonuses = getEnvironmentalBonuses();
      
      // Apply weather effects to battle
      publishEvent(createEvent(
        eventType: 'weather_battle_effects_applied',
        data: {
          'battleId': event.data['battleId'],
          'weatherCondition': currentWeather.condition.toString(),
          'intensity': currentWeather.intensity.toString(),
          'bonuses': bonuses,
          'visibility': currentWeather.visibility,
        },
      ));
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'weather_battle_processed',
      data: {
        'battleId': event.data['battleId'],
        'weatherEffectsApplied': currentWeather != null,
      },
    );
  }

  /// Handle battle turn events
  Future<AgentEventResponse?> _handleBattleTurn(AgentEvent event) async {
    final currentWeather = getCurrentWeather();
    
    // Apply weather-specific turn effects
    if (currentWeather != null) {
      final activeEffects = getActiveWeatherEffects();
      final relevantEffects = activeEffects.where((effect) => 
          effect.specialEffects.containsKey('battle_effects')).toList();
      
      if (relevantEffects.isNotEmpty) {
        publishEvent(createEvent(
          eventType: 'weather_turn_effects',
          data: {
            'battleId': event.data['battleId'],
            'turnNumber': event.data['turnNumber'],
            'weatherEffects': relevantEffects.map((e) => e.name).toList(),
          },
        ));
      }
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'weather_battle_turn_processed',
      data: {'weatherEffectsApplied': currentWeather != null},
    );
  }

  /// Handle character update events
  Future<AgentEventResponse?> _handleCharacterUpdate(AgentEvent event) async {
    final currentWeather = getCurrentWeather();
    
    if (currentWeather != null) {
      final bonuses = getEnvironmentalBonuses();
      
      // Apply environmental bonuses to character
      publishEvent(createEvent(
        eventType: 'weather_character_bonuses',
        data: {
          'characterId': event.data['characterId'],
          'weatherCondition': currentWeather.condition.toString(),
          'bonuses': bonuses,
          'timeOfDay': _currentState?.timeOfDay.toString(),
          'season': _currentState?.season.toString(),
        },
      ));
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'weather_character_processed',
      data: {'environmentalBonusesApplied': currentWeather != null},
    );
  }

  /// Handle AR experience events
  Future<AgentEventResponse?> _handleARExperience(AgentEvent event) async {
    final currentWeather = getCurrentWeather();
    
    if (currentWeather != null) {
      // Apply weather effects to AR experience
      final activeEffects = getActiveWeatherEffects();
      final visualEffects = activeEffects.where((effect) => 
          effect.specialEffects.isNotEmpty).toList();
      
      publishEvent(createEvent(
        eventType: 'weather_ar_effects',
        data: {
          'experienceType': event.data['type'],
          'weatherCondition': currentWeather.condition.toString(),
          'intensity': currentWeather.intensity.toString(),
          'visualEffects': visualEffects.map((e) => e.specialEffects).toList(),
          'visibility': currentWeather.visibility,
          'timeOfDay': _currentState?.timeOfDay.toString(),
        },
      ));
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'weather_ar_processed',
      data: {'weatherEffectsApplied': currentWeather != null},
    );
  }

  /// Handle weather update requests
  Future<AgentEventResponse?> _handleWeatherUpdateRequest(AgentEvent event) async {
    await _updateWeatherData();

    return createResponse(
      originalEventId: event.id,
      responseType: 'weather_update_completed',
      data: {
        'weather': _currentState?.currentWeather.toJson(),
        'updateTime': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Handle get current weather requests
  Future<AgentEventResponse?> _handleGetCurrentWeather(AgentEvent event) async {
    final currentWeather = getCurrentWeather();
    final environmentalState = getEnvironmentalState();

    return createResponse(
      originalEventId: event.id,
      responseType: 'weather_current_retrieved',
      data: {
        'weather': currentWeather?.toJson(),
        'environmentalState': environmentalState?.toJson(),
        'activeEffects': getActiveWeatherEffects().map((e) => e.toJson()).toList(),
      },
    );
  }

  /// Handle get forecast requests
  Future<AgentEventResponse?> _handleGetForecast(AgentEvent event) async {
    final forecast = getWeatherForecast();

    return createResponse(
      originalEventId: event.id,
      responseType: 'weather_forecast_retrieved',
      data: {
        'forecast': forecast?.toJson(),
        'hourlyCount': forecast?.hourlyForecast.length ?? 0,
        'dailyCount': forecast?.dailyForecast.length ?? 0,
      },
    );
  }

  /// Handle set location requests
  Future<AgentEventResponse?> _handleSetLocation(AgentEvent event) async {
    final latitude = event.data['latitude']?.toDouble();
    final longitude = event.data['longitude']?.toDouble();
    final locationName = event.data['locationName'];

    if (latitude != null && longitude != null) {
      updateLocation(latitude, longitude, locationName: locationName);
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'weather_location_set',
      data: {
        'latitude': latitude,
        'longitude': longitude,
        'locationName': _currentLocation,
        'success': latitude != null && longitude != null,
      },
      success: latitude != null && longitude != null,
    );
  }

  /// Handle user login events
  Future<AgentEventResponse?> _handleUserLogin(AgentEvent event) async {
    // Load user-specific weather preferences
    await _loadWeatherData();

    // Update weather if stale
    if (_lastWeatherUpdate == null || 
        DateTime.now().difference(_lastWeatherUpdate!).inMinutes > 30) {
      await _updateWeatherData();
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'user_login_weather_processed',
      data: {'weatherDataLoaded': true},
    );
  }

  /// Handle user logout events
  Future<AgentEventResponse?> _handleUserLogout(AgentEvent event) async {
    // Save weather data
    await _saveWeatherData();

    return createResponse(
      originalEventId: event.id,
      responseType: 'user_logout_weather_processed',
      data: {'weatherDataSaved': true},
    );
  }

  @override
  Future<void> onDispose() async {
    // Stop timers
    _weatherUpdateTimer?.cancel();
    _timeUpdateTimer?.cancel();
    _effectsUpdateTimer?.cancel();

    // Save all data
    await _saveWeatherData();

    developer.log('Weather Integration Agent disposed', name: agentId);
  }
}