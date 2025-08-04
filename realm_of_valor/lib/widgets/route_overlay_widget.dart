import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../constants/theme.dart';

class RouteOverlayWidget extends StatelessWidget {
  final List<NavigationRoute> routes;
  final Function(NavigationRoute)? onRouteSelect;

  const RouteOverlayWidget({
    super.key,
    required this.routes,
    this.onRouteSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (routes.isEmpty) return const SizedBox.shrink();

    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: RealmOfValorTheme.surfaceMedium.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.route,
                  color: RealmOfValorTheme.accentGold,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Available Routes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: RealmOfValorTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...routes.map((route) => _buildRouteItem(route)),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteItem(NavigationRoute route) {
    return GestureDetector(
      onTap: () => onRouteSelect?.call(route),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: RealmOfValorTheme.surfaceDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: RealmOfValorTheme.accentGold.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getRouteIcon(route.type),
              color: _getRouteColor(route.type),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: RealmOfValorTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '${route.distance.toStringAsFixed(1)}km • ${route.duration.inMinutes}min',
                    style: TextStyle(
                      fontSize: 12,
                      color: RealmOfValorTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: RealmOfValorTheme.accentGold,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getRouteIcon(RouteType type) {
    switch (type) {
      case RouteType.walking:
        return Icons.directions_walk;
      case RouteType.running:
        return Icons.directions_run;
      case RouteType.cycling:
        return Icons.directions_bike;
      case RouteType.driving:
        return Icons.directions_car;
      case RouteType.transit:
        return Icons.directions_bus;
    }
  }

  Color _getRouteColor(RouteType type) {
    switch (type) {
      case RouteType.walking:
        return Colors.green;
      case RouteType.running:
        return Colors.orange;
      case RouteType.cycling:
        return Colors.blue;
      case RouteType.driving:
        return Colors.red;
      case RouteType.transit:
        return Colors.purple;
    }
  }
}

// Navigation Models
class NavigationRoute {
  final String id;
  final String name;
  final RouteType type;
  final double distance;
  final Duration duration;
  final List<LatLng> waypoints;
  final String? description;

  NavigationRoute({
    required this.id,
    required this.name,
    required this.type,
    required this.distance,
    required this.duration,
    required this.waypoints,
    this.description,
  });
}

enum RouteType {
  walking,
  running,
  cycling,
  driving,
  transit,
} 