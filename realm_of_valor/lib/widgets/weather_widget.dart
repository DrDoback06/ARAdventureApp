import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../models/adventure_map_model.dart';

class WeatherWidget extends StatelessWidget {
  final WeatherData? weather;
  final Map<String, dynamic> effects;

  const WeatherWidget({
    super.key,
    required this.weather,
    required this.effects,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: RealmOfValorTheme.accentGold.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildWeatherIcon(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWeatherInfo(),
                if (effects.isNotEmpty) _buildWeatherEffects(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherIcon() {
    IconData icon;
    Color color;

    if (weather == null) {
      icon = Icons.help_outline;
      color = RealmOfValorTheme.textSecondary;
    } else {
      switch (weather!.condition) {
        case WeatherCondition.sunny:
        case WeatherCondition.clear:
          icon = Icons.wb_sunny;
          color = Colors.orange;
          break;
        case WeatherCondition.cloudy:
        case WeatherCondition.overcast:
          icon = Icons.cloud;
          color = Colors.grey;
          break;
        case WeatherCondition.rainy:
          icon = Icons.umbrella;
          color = Colors.blue;
          break;
        case WeatherCondition.snowy:
          icon = Icons.ac_unit;
          color = Colors.lightBlue;
          break;
        case WeatherCondition.stormy:
          icon = Icons.thunderstorm;
          color = Colors.purple;
          break;
        case WeatherCondition.foggy:
          icon = Icons.cloud;
          color = Colors.grey;
          break;
        case WeatherCondition.windy:
          icon = Icons.air;
          color = Colors.green;
          break;
      }
    }

    return Icon(
      icon,
      color: color,
      size: 32,
    );
  }

  Widget _buildWeatherInfo() {
    if (weather == null) {
      return Text(
        'Weather unavailable',
        style: TextStyle(
          color: RealmOfValorTheme.textSecondary,
          fontSize: 12,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          weather!.description.toUpperCase(),
          style: TextStyle(
            color: RealmOfValorTheme.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${weather!.temperature.round()}°C',
          style: TextStyle(
            color: RealmOfValorTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Humidity: ${weather!.humidity.round()}%',
          style: TextStyle(
            color: RealmOfValorTheme.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherEffects() {
    final xpMultiplier = effects['xpMultiplier'] ?? 1.0;
    final description = effects['description'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _getEffectColor(xpMultiplier).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${(xpMultiplier * 100).round()}% XP',
            style: TextStyle(
              color: _getEffectColor(xpMultiplier),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (description.isNotEmpty)
          Text(
            description,
            style: TextStyle(
              color: RealmOfValorTheme.textSecondary,
              fontSize: 10,
            ),
          ),
      ],
    );
  }

  Color _getEffectColor(double multiplier) {
    if (multiplier > 1.5) {
      return Colors.purple;
    } else if (multiplier > 1.2) {
      return Colors.orange;
    } else if (multiplier > 1.0) {
      return Colors.green;
    } else {
      return RealmOfValorTheme.textSecondary;
    }
  }
}