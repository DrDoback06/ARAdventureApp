import 'package:flutter/material.dart';

import '../constants/theme.dart';
import '../models/adventure_map_model.dart';

class CollapsibleWeatherWidget extends StatefulWidget {
  final WeatherData? weather;
  final Map<String, dynamic> effects;

  const CollapsibleWeatherWidget({
    super.key,
    this.weather,
    required this.effects,
  });

  @override
  State<CollapsibleWeatherWidget> createState() => _CollapsibleWeatherWidgetState();
}

class _CollapsibleWeatherWidgetState extends State<CollapsibleWeatherWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heightAnimation = Tween<double>(
      begin: 80.0,
      end: 200.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.weather == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _heightAnimation,
      builder: (context, child) {
        return Container(
          height: _heightAnimation.value,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: RealmOfValorTheme.surfaceMedium.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: RealmOfValorTheme.accentGold.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header - Fixed height
              GestureDetector(
                onTap: _toggleExpanded,
                child: Container(
                  height: 76, // Reduced from 80 to prevent overflow
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      _buildWeatherIcon(widget.weather!.condition),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.weather!.description.toUpperCase(),
                              style: TextStyle(
                                color: RealmOfValorTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${widget.weather!.temperature.round()}°C',
                              style: TextStyle(
                                color: RealmOfValorTheme.accentGold,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: RealmOfValorTheme.accentGold,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Expanded content - Flexible height
              if (_isExpanded) ...[
                const Divider(
                  color: RealmOfValorTheme.textSecondary,
                  height: 1,
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Humidity
                        Row(
                          children: [
                            Icon(
                              Icons.water_drop,
                              color: RealmOfValorTheme.textSecondary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Humidity: ${widget.weather!.humidity.round()}%',
                              style: TextStyle(
                                color: RealmOfValorTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // Wind speed
                        Row(
                          children: [
                            Icon(
                              Icons.air,
                              color: RealmOfValorTheme.textSecondary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Wind: ${widget.weather!.windSpeed.round()} km/h',
                              style: TextStyle(
                                color: RealmOfValorTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Weather effects
                        if (widget.effects.isNotEmpty) ...[
                          Text(
                            'Weather Effects',
                            style: TextStyle(
                              color: RealmOfValorTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: RealmOfValorTheme.accentGold.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: RealmOfValorTheme.accentGold.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.effects['description'] ?? 'Weather effects active',
                                  style: TextStyle(
                                    color: RealmOfValorTheme.textPrimary,
                                    fontSize: 12,
                                  ),
                                ),
                                if (widget.effects['xpMultiplier'] != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'XP Multiplier: ${widget.effects['xpMultiplier']}x',
                                    style: TextStyle(
                                      color: RealmOfValorTheme.accentGold,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeatherIcon(WeatherCondition condition) {
    IconData icon;
    Color color;
    
    switch (condition) {
      case WeatherCondition.clear:
        icon = Icons.wb_sunny;
        color = Colors.orange;
        break;
      case WeatherCondition.cloudy:
        icon = Icons.cloud;
        color = Colors.grey;
        break;
      case WeatherCondition.rainy:
        icon = Icons.umbrella;
        color = Colors.blue;
        break;
      case WeatherCondition.stormy:
        icon = Icons.thunderstorm;
        color = Colors.purple;
        break;
      case WeatherCondition.snowy:
        icon = Icons.ac_unit;
        color = Colors.cyan;
        break;
      case WeatherCondition.windy:
        icon = Icons.air;
        color = Colors.green;
        break;
      case WeatherCondition.foggy:
        icon = Icons.cloud;
        color = Colors.grey;
        break;
      case WeatherCondition.sunny:
        icon = Icons.wb_sunny;
        color = Colors.yellow;
        break;
      default:
        icon = Icons.cloud;
        color = Colors.grey;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }
} 