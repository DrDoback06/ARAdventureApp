import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/weather_model.dart';
import '../models/quest_type_model.dart';

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  static const String _apiKey = 'YOUR_OPENWEATHERMAP_API_KEY';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  WeatherData? _currentWeather;
  List<WeatherEffect> _weatherEffects = [];
  bool _isInitialized = false;

  // Enhanced Features
  bool _showWeatherEffects = true;
  bool _dynamicWeather = true;
  bool _weatherNotifications = true;
  bool _weatherBonuses = true;

  // Getters
  WeatherData? get currentWeather => _currentWeather;
  List<WeatherEffect> get weatherEffects => _weatherEffects;
  bool get isInitialized => _isInitialized;

  // Initialize weather service
  Future<void> initialize() async {
    try {
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
    }
  }

  // Get current weather for location
  Future<WeatherData> getCurrentWeather(UserLocation location) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/weather?lat=${location.latitude}&lon=${location.longitude}&appid=$_apiKey&units=metric'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _currentWeather = _parseWeatherData(data);
        _updateWeatherEffects();
        return _currentWeather!;
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      // Return mock weather data for development
      _currentWeather = _getMockWeatherData(location);
      _updateWeatherEffects();
      return _currentWeather!;
    }
  }

  // Parse weather data from API response
  WeatherData _parseWeatherData(Map<String, dynamic> data) {
    final weather = data['weather'][0];
    final main = data['main'];
    final wind = data['wind'];

    return WeatherData(
      temperature: main['temp'].toDouble(),
      feelsLike: main['feels_like'].toDouble(),
      humidity: main['humidity'].toDouble(),
      pressure: main['pressure'].toDouble(),
      windSpeed: wind['speed'].toDouble(),
      windDirection: wind['deg'].toDouble(),
      condition: WeatherCondition.values.firstWhere(
        (condition) => condition.name.toLowerCase() == weather['main'].toLowerCase(),
        orElse: () => WeatherCondition.clear,
      ),
      description: weather['description'],
      icon: weather['icon'],
      timestamp: DateTime.now(),
    );
  }

  // Get mock weather data for development
  WeatherData _getMockWeatherData(UserLocation location) {
    final conditions = WeatherCondition.values;
    final randomCondition = conditions[DateTime.now().millisecond % conditions.length];

    return WeatherData(
      temperature: 20.0 + (DateTime.now().millisecond % 20),
      feelsLike: 22.0 + (DateTime.now().millisecond % 15),
      humidity: 60.0 + (DateTime.now().millisecond % 30),
      pressure: 1013.0 + (DateTime.now().millisecond % 20),
      windSpeed: 5.0 + (DateTime.now().millisecond % 15),
      windDirection: DateTime.now().millisecond % 360,
      condition: randomCondition,
      description: _getWeatherDescription(randomCondition),
      icon: _getWeatherIcon(randomCondition),
      timestamp: DateTime.now(),
    );
  }

  // Get weather description
  String _getWeatherDescription(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.clear:
        return 'Clear sky';
      case WeatherCondition.clouds:
        return 'Cloudy';
      case WeatherCondition.rain:
        return 'Light rain';
      case WeatherCondition.snow:
        return 'Light snow';
      case WeatherCondition.thunderstorm:
        return 'Thunderstorm';
      case WeatherCondition.drizzle:
        return 'Drizzle';
      case WeatherCondition.mist:
        return 'Misty';
      case WeatherCondition.fog:
        return 'Foggy';
      case WeatherCondition.haze:
        return 'Hazy';
      case WeatherCondition.smoke:
        return 'Smoky';
      case WeatherCondition.dust:
        return 'Dusty';
      case WeatherCondition.sand:
        return 'Sandy';
      case WeatherCondition.ash:
        return 'Ashy';
      case WeatherCondition.squall:
        return 'Squally';
      case WeatherCondition.tornado:
        return 'Tornado';
    }
  }

  // Get weather icon
  String _getWeatherIcon(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.clear:
        return '01d';
      case WeatherCondition.clouds:
        return '03d';
      case WeatherCondition.rain:
        return '10d';
      case WeatherCondition.snow:
        return '13d';
      case WeatherCondition.thunderstorm:
        return '11d';
      case WeatherCondition.drizzle:
        return '09d';
      case WeatherCondition.mist:
        return '50d';
      case WeatherCondition.fog:
        return '50d';
      case WeatherCondition.haze:
        return '50d';
      case WeatherCondition.smoke:
        return '50d';
      case WeatherCondition.dust:
        return '50d';
      case WeatherCondition.sand:
        return '50d';
      case WeatherCondition.ash:
        return '50d';
      case WeatherCondition.squall:
        return '11d';
      case WeatherCondition.tornado:
        return '11d';
    }
  }

  // Update weather effects based on current weather
  void _updateWeatherEffects() {
    if (!_showWeatherEffects || _currentWeather == null) return;

    _weatherEffects.clear();

    switch (_currentWeather!.condition) {
      case WeatherCondition.rain:
        _weatherEffects.add(WeatherEffect(
          type: WeatherEffectType.rain,
          intensity: 0.7,
          duration: const Duration(minutes: 30),
        ));
        break;
      case WeatherCondition.snow:
        _weatherEffects.add(WeatherEffect(
          type: WeatherEffectType.snow,
          intensity: 0.8,
          duration: const Duration(minutes: 45),
        ));
        break;
      case WeatherCondition.thunderstorm:
        _weatherEffects.add(WeatherEffect(
          type: WeatherEffectType.lightning,
          intensity: 0.9,
          duration: const Duration(minutes: 20),
        ));
        break;
      case WeatherCondition.fog:
        _weatherEffects.add(WeatherEffect(
          type: WeatherEffectType.fog,
          intensity: 0.6,
          duration: const Duration(hours: 2),
        ));
        break;
      case WeatherCondition.clear:
        _weatherEffects.add(WeatherEffect(
          type: WeatherEffectType.sunshine,
          intensity: 0.5,
          duration: const Duration(hours: 1),
        ));
        break;
      default:
        break;
    }
  }

  // Get weather effects
  List<WeatherEffect> getWeatherEffects() {
    return _weatherEffects;
  }

  // Update weather effects for location
  void updateWeatherEffects(UserLocation location) async {
    if (!_dynamicWeather) return;

    final weather = await getCurrentWeather(location);
    _updateWeatherEffects();
  }

  // Get weather bonus for quests
  double getWeatherBonus(QuestType questType) {
    if (!_weatherBonuses || _currentWeather == null) return 1.0;

    switch (questType) {
      case QuestType.exploration:
        if (_currentWeather!.condition == WeatherCondition.clear) {
          return 1.2; // 20% bonus for clear weather
        }
        break;
      case QuestType.fitness:
        if (_currentWeather!.condition == WeatherCondition.rain) {
          return 1.3; // 30% bonus for rain (challenging)
        }
        break;
      case QuestType.battle:
        if (_currentWeather!.condition == WeatherCondition.thunderstorm) {
          return 1.4; // 40% bonus for thunderstorm
        }
        break;
      default:
        break;
    }

    return 1.0;
  }

  // Check if weather is suitable for outdoor activities
  bool isWeatherSuitableForOutdoor() {
    if (_currentWeather == null) return true;

    switch (_currentWeather!.condition) {
      case WeatherCondition.thunderstorm:
      case WeatherCondition.tornado:
        return false;
      default:
        return true;
    }
  }

  // Get weather forecast (simplified)
  List<WeatherData> getWeatherForecast(UserLocation location, int hours) {
    final forecast = <WeatherData>[];
    final conditions = WeatherCondition.values;

    for (int i = 0; i < hours; i++) {
      final condition = conditions[DateTime.now().millisecond % conditions.length];
      forecast.add(WeatherData(
        temperature: 20.0 + (i * 2),
        feelsLike: 22.0 + (i * 2),
        humidity: 60.0,
        pressure: 1013.0,
        windSpeed: 5.0,
        windDirection: 180.0,
        condition: condition,
        description: _getWeatherDescription(condition),
        icon: _getWeatherIcon(condition),
        timestamp: DateTime.now().add(Duration(hours: i)),
      ));
    }

    return forecast;
  }

  // Enhanced Features

  // Toggle weather effects
  void toggleWeatherEffects() {
    _showWeatherEffects = !_showWeatherEffects;
  }

  // Toggle dynamic weather
  void toggleDynamicWeather() {
    _dynamicWeather = !_dynamicWeather;
  }

  // Toggle weather notifications
  void toggleWeatherNotifications() {
    _weatherNotifications = !_weatherNotifications;
  }

  // Toggle weather bonuses
  void toggleWeatherBonuses() {
    _weatherBonuses = !_weatherBonuses;
  }

  // Get weather statistics
  Map<String, dynamic> getWeatherStats() {
    if (_currentWeather == null) return {};

    return {
      'temperature': _currentWeather!.temperature,
      'feelsLike': _currentWeather!.feelsLike,
      'humidity': _currentWeather!.humidity,
      'pressure': _currentWeather!.pressure,
      'windSpeed': _currentWeather!.windSpeed,
      'windDirection': _currentWeather!.windDirection,
      'condition': _currentWeather!.condition.name,
      'description': _currentWeather!.description,
      'icon': _currentWeather!.icon,
      'timestamp': _currentWeather!.timestamp.toIso8601String(),
      'effectsCount': _weatherEffects.length,
      'showEffects': _showWeatherEffects,
      'dynamicWeather': _dynamicWeather,
      'weatherNotifications': _weatherNotifications,
      'weatherBonuses': _weatherBonuses,
    };
  }

  // Dispose
  void dispose() {
    _weatherEffects.clear();
  }
}

// Weather Models
class WeatherData {
  final double temperature;
  final double feelsLike;
  final double humidity;
  final double pressure;
  final double windSpeed;
  final double windDirection;
  final WeatherCondition condition;
  final String description;
  final String icon;
  final DateTime timestamp;

  WeatherData({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.pressure,
    required this.windSpeed,
    required this.windDirection,
    required this.condition,
    required this.description,
    required this.icon,
    required this.timestamp,
  });
}

enum WeatherCondition {
  clear,
  clouds,
  rain,
  snow,
  thunderstorm,
  drizzle,
  mist,
  fog,
  haze,
  smoke,
  dust,
  sand,
  ash,
  squall,
  tornado,
}

class WeatherEffect {
  final WeatherEffectType type;
  final double intensity;
  final Duration duration;
  final DateTime startTime;

  WeatherEffect({
    required this.type,
    required this.intensity,
    required this.duration,
    DateTime? startTime,
  }) : startTime = startTime ?? DateTime.now();

  bool get isActive {
    return DateTime.now().difference(startTime) < duration;
  }

  double get remainingIntensity {
    if (!isActive) return 0.0;
    final elapsed = DateTime.now().difference(startTime);
    final progress = elapsed.inMilliseconds / duration.inMilliseconds;
    return intensity * (1.0 - progress);
  }
}

enum WeatherEffectType {
  rain,
  snow,
  lightning,
  fog,
  sunshine,
  wind,
  storm,
}