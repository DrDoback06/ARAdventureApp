import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/adventure_system.dart';

class WeatherData {
  final String location;
  final double temperature;
  final String condition;
  final String description;
  final int humidity;
  final double windSpeed;
  final String windDirection;
  final double pressure;
  final double visibility;
  final DateTime timestamp;
  final String icon;
  final List<WeatherForecast> forecast;

  WeatherData({
    required this.location,
    required this.temperature,
    required this.condition,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.pressure,
    required this.visibility,
    required this.timestamp,
    required this.icon,
    required this.forecast,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      location: json['location'] ?? 'Unknown',
      temperature: (json['temperature'] ?? 0).toDouble(),
      condition: json['condition'] ?? 'Unknown',
      description: json['description'] ?? '',
      humidity: json['humidity'] ?? 0,
      windSpeed: (json['windSpeed'] ?? 0).toDouble(),
      windDirection: json['windDirection'] ?? 'N',
      pressure: (json['pressure'] ?? 0).toDouble(),
      visibility: (json['visibility'] ?? 0).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      icon: json['icon'] ?? '',
      forecast: (json['forecast'] as List? ?? [])
          .map((f) => WeatherForecast.fromJson(f))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': location,
      'temperature': temperature,
      'condition': condition,
      'description': description,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'windDirection': windDirection,
      'pressure': pressure,
      'visibility': visibility,
      'timestamp': timestamp.toIso8601String(),
      'icon': icon,
      'forecast': forecast.map((f) => f.toJson()).toList(),
    };
  }

  bool get isGoodForOutdoorActivity {
    return temperature > 5 && 
           temperature < 30 && 
           windSpeed < 20 && 
           !condition.toLowerCase().contains('rain') &&
           !condition.toLowerCase().contains('storm');
  }

  String get adventureRecommendation {
    if (temperature < 0) return 'Perfect for frost giant hunting! ❄️';
    if (temperature > 25 && condition.toLowerCase().contains('sunny')) {
      return 'Ideal weather for dragon encounters! ☀️';
    }
    if (condition.toLowerCase().contains('rain')) {
      return 'Great for water elemental quests! 🌧️';
    }
    if (windSpeed > 15) return 'Windy conditions perfect for air magic! 💨';
    if (condition.toLowerCase().contains('cloud')) {
      return 'Mysterious clouds hide ancient secrets! ☁️';
    }
    return 'Perfect weather for epic adventures! ⚔️';
  }
}

class WeatherForecast {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final String condition;
  final String icon;
  final double rainChance;

  WeatherForecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.condition,
    required this.icon,
    required this.rainChance,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      date: DateTime.parse(json['date']),
      maxTemp: (json['maxTemp'] ?? 0).toDouble(),
      minTemp: (json['minTemp'] ?? 0).toDouble(),
      condition: json['condition'] ?? '',
      icon: json['icon'] ?? '',
      rainChance: (json['rainChance'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'maxTemp': maxTemp,
      'minTemp': minTemp,
      'condition': condition,
      'icon': icon,
      'rainChance': rainChance,
    };
  }
}

class WeatherService {
  static const String _metOfficeApiKey = 'YOUR_MET_OFFICE_API_KEY'; // You'll need to get this
  static const String _openWeatherApiKey = 'YOUR_OPENWEATHER_API_KEY'; // Fallback
  
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  WeatherData? _cachedWeather;
  DateTime? _lastWeatherUpdate;

  // Get weather data for current location
  Future<WeatherData?> getCurrentWeather() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      return await getWeatherForLocation(
        GeoLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
    } catch (e) {
      print('Error getting current weather: $e');
      return null;
    }
  }

  // Get weather data for specific location
  Future<WeatherData?> getWeatherForLocation(GeoLocation location) async {
    try {
      // Check cache first (refresh every 30 minutes)
      if (_cachedWeather != null && 
          _lastWeatherUpdate != null &&
          DateTime.now().difference(_lastWeatherUpdate!).inMinutes < 30) {
        return _cachedWeather;
      }

      WeatherData? weather;

      // Try Met Office first (for UK locations)
      if (_isUKLocation(location)) {
        weather = await _getMetOfficeWeather(location);
      }

      // Fallback to OpenWeatherMap
      weather ??= await _getOpenWeatherMapData(location);

      if (weather != null) {
        _cachedWeather = weather;
        _lastWeatherUpdate = DateTime.now();
      }

      return weather;
    } catch (e) {
      print('Error getting weather for location: $e');
      return null;
    }
  }

  // Check if location is in UK (rough bounds)
  bool _isUKLocation(GeoLocation location) {
    return location.latitude >= 49.0 && 
           location.latitude <= 61.0 &&
           location.longitude >= -8.0 && 
           location.longitude <= 2.0;
  }

  // Met Office weather data (UK specific)
  Future<WeatherData?> _getMetOfficeWeather(GeoLocation location) async {
    try {
      // Met Office DataPoint API
      final url = 'http://datapoint.metoffice.gov.uk/public/data/val/wxfcs/all/json/sitelist'
          '?key=$_metOfficeApiKey';

      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Process Met Office specific data format
        return _parseMetOfficeData(data, location);
      }
    } catch (e) {
      print('Met Office API error: $e');
    }
    return null;
  }

  // OpenWeatherMap fallback
  Future<WeatherData?> _getOpenWeatherMapData(GeoLocation location) async {
    try {
      final url = 'https://api.openweathermap.org/data/2.5/weather'
          '?lat=${location.latitude}&lon=${location.longitude}'
          '&appid=$_openWeatherApiKey&units=metric';

      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseOpenWeatherData(data);
      }
    } catch (e) {
      print('OpenWeatherMap API error: $e');
    }
    return null;
  }

  // Parse Met Office data format
  WeatherData? _parseMetOfficeData(Map<String, dynamic> data, GeoLocation location) {
    try {
      // This is a simplified parser - you'd need to implement the full Met Office format
      return WeatherData(
        location: data['Locations']?['Location']?[0]?['name'] ?? 'UK Location',
        temperature: 15.0, // You'd extract this from the actual API response
        condition: 'Partly Cloudy',
        description: 'Met Office data',
        humidity: 65,
        windSpeed: 10.0,
        windDirection: 'SW',
        pressure: 1013.0,
        visibility: 10.0,
        timestamp: DateTime.now(),
        icon: '02d',
        forecast: [], // You'd parse the forecast data here
      );
    } catch (e) {
      print('Error parsing Met Office data: $e');
      return null;
    }
  }

  // Parse OpenWeatherMap data
  WeatherData? _parseOpenWeatherData(Map<String, dynamic> data) {
    try {
      final main = data['main'] ?? {};
      final weather = (data['weather'] as List?)?.first ?? {};
      final wind = data['wind'] ?? {};

      return WeatherData(
        location: data['name'] ?? 'Unknown',
        temperature: (main['temp'] ?? 0).toDouble(),
        condition: weather['main'] ?? 'Unknown',
        description: weather['description'] ?? '',
        humidity: main['humidity'] ?? 0,
        windSpeed: (wind['speed'] ?? 0).toDouble(),
        windDirection: _degreeToDirection(wind['deg'] ?? 0),
        pressure: (main['pressure'] ?? 0).toDouble(),
        visibility: ((data['visibility'] ?? 0) / 1000).toDouble(),
        timestamp: DateTime.now(),
        icon: weather['icon'] ?? '',
        forecast: [], // Would need separate API call for forecast
      );
    } catch (e) {
      print('Error parsing OpenWeatherMap data: $e');
      return null;
    }
  }

  // Convert wind degree to direction
  String _degreeToDirection(int degree) {
    const directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
                       'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    final index = ((degree + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }

  // Get weather-based spawn modifiers
  Map<String, double> getWeatherSpawnModifiers(WeatherData weather) {
    final modifiers = <String, double>{};

    // Temperature effects
    if (weather.temperature < 5) {
      modifiers['ice_creatures'] = 2.0;
      modifiers['fire_creatures'] = 0.5;
    } else if (weather.temperature > 25) {
      modifiers['fire_creatures'] = 2.0;
      modifiers['ice_creatures'] = 0.5;
    }

    // Weather condition effects
    if (weather.condition.toLowerCase().contains('rain')) {
      modifiers['water_creatures'] = 2.0;
      modifiers['earth_creatures'] = 1.5;
    }

    if (weather.condition.toLowerCase().contains('clear')) {
      modifiers['light_creatures'] = 1.5;
      modifiers['rare_spawns'] = 1.2;
    }

    if (weather.condition.toLowerCase().contains('cloud')) {
      modifiers['shadow_creatures'] = 1.5;
      modifiers['mystery_encounters'] = 1.3;
    }

    if (weather.windSpeed > 15) {
      modifiers['air_creatures'] = 2.0;
      modifiers['flying_creatures'] = 1.5;
    }

    return modifiers;
  }

  // Generate weather-based quests
  List<String> getWeatherBasedQuestSuggestions(WeatherData weather) {
    final suggestions = <String>[];

    if (weather.isGoodForOutdoorActivity) {
      suggestions.add('Perfect weather for exploration quests!');
      suggestions.add('Ideal conditions for fitness challenges.');
    }

    if (weather.condition.toLowerCase().contains('rain')) {
      suggestions.add('Rainy Day Indoor Treasure Hunt');
      suggestions.add('Storm Chaser Achievement');
    }

    if (weather.temperature < 5) {
      suggestions.add('Winter Warrior Challenge');
      suggestions.add('Frost Giant Territory Exploration');
    }

    if (weather.condition.toLowerCase().contains('sunny')) {
      suggestions.add('Solar Explorer Mission');
      suggestions.add('Daylight Discovery Quest');
    }

    return suggestions;
  }

  // Clear cache
  void clearCache() {
    _cachedWeather = null;
    _lastWeatherUpdate = null;
  }
}