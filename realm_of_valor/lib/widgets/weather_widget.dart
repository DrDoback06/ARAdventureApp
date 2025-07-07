import 'package:flutter/material.dart';
import '../services/weather_service.dart';

class WeatherWidget extends StatelessWidget {
  final WeatherData weather;

  const WeatherWidget({
    Key? key,
    required this.weather,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: _getWeatherGradient(),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    _getWeatherIcon(),
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${weather.temperature.round()}°C',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          weather.condition,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: weather.isGoodForOutdoorActivity
                          ? Colors.green.withOpacity(0.3)
                          : Colors.orange.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: weather.isGoodForOutdoorActivity
                            ? Colors.green
                            : Colors.orange,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      weather.isGoodForOutdoorActivity
                          ? 'Perfect for Adventure!'
                          : 'Adventure with Caution',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.speed,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Wind: ${weather.windSpeed.toStringAsFixed(1)} m/s ${weather.windDirection}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.water_drop,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${weather.humidity}%',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getAdventureIcon(),
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              weather.adventureRecommendation,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (weather.forecast.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Next 24 Hours',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: weather.forecast.length.clamp(0, 8),
                    itemBuilder: (context, index) {
                      final forecast = weather.forecast[index];
                      return Container(
                        width: 60,
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${forecast.date.hour}:00',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                            Icon(
                              _getConditionIcon(forecast.condition),
                              color: Colors.white,
                              size: 16,
                            ),
                            Text(
                              '${forecast.maxTemp.round()}°',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  LinearGradient _getWeatherGradient() {
    if (weather.condition.toLowerCase().contains('rain') ||
        weather.condition.toLowerCase().contains('storm')) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF4A5568),
          Color(0xFF2D3748),
        ],
      );
    } else if (weather.condition.toLowerCase().contains('snow')) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF718096),
          Color(0xFF4A5568),
        ],
      );
    } else if (weather.condition.toLowerCase().contains('cloud')) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF667EEA),
          Color(0xFF764BA2),
        ],
      );
    } else {
      // Clear/sunny weather
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF667EEA),
          Color(0xFF764BA2),
        ],
      );
    }
  }

  IconData _getWeatherIcon() {
    final condition = weather.condition.toLowerCase();
    
    if (condition.contains('rain')) {
      return Icons.grain;
    } else if (condition.contains('snow')) {
      return Icons.ac_unit;
    } else if (condition.contains('storm')) {
      return Icons.flash_on;
    } else if (condition.contains('cloud')) {
      return Icons.cloud;
    } else if (condition.contains('clear') || condition.contains('sunny')) {
      return Icons.wb_sunny;
    } else {
      return Icons.wb_cloudy;
    }
  }

  IconData _getConditionIcon(String condition) {
    final cond = condition.toLowerCase();
    
    if (cond.contains('rain')) {
      return Icons.grain;
    } else if (cond.contains('snow')) {
      return Icons.ac_unit;
    } else if (cond.contains('storm')) {
      return Icons.flash_on;
    } else if (cond.contains('cloud')) {
      return Icons.cloud;
    } else if (cond.contains('clear') || cond.contains('sunny')) {
      return Icons.wb_sunny;
    } else {
      return Icons.wb_cloudy;
    }
  }

  IconData _getAdventureIcon() {
    final condition = weather.condition.toLowerCase();
    
    if (condition.contains('rain')) {
      return Icons.waves; // Water elemental
    } else if (condition.contains('snow')) {
      return Icons.ac_unit; // Ice/frost
    } else if (condition.contains('storm')) {
      return Icons.flash_on; // Lightning magic
    } else if (condition.contains('clear') || condition.contains('sunny')) {
      return Icons.wb_sunny; // Solar power
    } else if (weather.windSpeed > 15) {
      return Icons.air; // Wind magic
    } else {
      return Icons.explore; // General adventure
    }
  }
}