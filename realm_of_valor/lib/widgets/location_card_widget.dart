import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../models/adventure_map_model.dart';

class LocationCardWidget extends StatelessWidget {
  final MapLocation location;
  final VoidCallback? onTap;
  final double? distance;

  const LocationCardWidget({
    super.key,
    required this.location,
    this.onTap,
    this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getLocationBorderColor().withOpacity(0.5),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getLocationIcon(),
                      color: _getLocationBorderColor(),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            location.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: RealmOfValorTheme.textPrimary,
                            ),
                          ),
                          Text(
                            location.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: RealmOfValorTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (location.isVerified)
                      Icon(
                        Icons.verified,
                        color: Colors.blue,
                        size: 16,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildLocationInfo(),
                if (distance != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: RealmOfValorTheme.accentGold,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${distance!.toStringAsFixed(1)} km away',
                        style: TextStyle(
                          color: RealmOfValorTheme.accentGold,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Row(
      children: [
        _buildInfoChip('Type', location.type.name),
        if (location.rating != null) ...[
          const SizedBox(width: 8),
          _buildInfoChip('Rating', '${location.rating}/5'),
        ],
        if (location.reviewCount != null) ...[
          const SizedBox(width: 8),
          _buildInfoChip('Reviews', '${location.reviewCount}'),
        ],
      ],
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: RealmOfValorTheme.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getLocationBorderColor() {
    switch (location.type) {
      case LocationType.trail:
        return Colors.green;
      case LocationType.pub:
        return Colors.orange;
      case LocationType.restaurant:
        return Colors.red;
      case LocationType.park:
        return Colors.green;
      case LocationType.gym:
        return Colors.purple;
      case LocationType.landmark:
        return Colors.yellow;
      case LocationType.culturalSite:
        return Colors.indigo;
      case LocationType.naturalWonder:
        return Colors.teal;
      default:
        return RealmOfValorTheme.accentGold;
    }
  }

  IconData _getLocationIcon() {
    switch (location.type) {
      case LocationType.trail:
        return Icons.directions_walk;
      case LocationType.pub:
        return Icons.local_bar;
      case LocationType.restaurant:
        return Icons.restaurant;
      case LocationType.park:
        return Icons.park;
      case LocationType.gym:
        return Icons.fitness_center;
      case LocationType.landmark:
        return Icons.landscape;
      case LocationType.culturalSite:
        return Icons.museum;
      case LocationType.naturalWonder:
        return Icons.nature;
      case LocationType.business:
        return Icons.business;
      case LocationType.poi:
        return Icons.place;
      case LocationType.runningTrack:
        return Icons.directions_run;
      case LocationType.historicalSite:
        return Icons.history;
      case LocationType.viewpoint:
        return Icons.visibility;
      case LocationType.communityCenter:
        return Icons.people;
      case LocationType.cafe:
        return Icons.local_cafe;
      case LocationType.shop:
        return Icons.shopping_bag;
      case LocationType.eventVenue:
        return Icons.event;
      case LocationType.sportsFacility:
        return Icons.sports_soccer;
      case LocationType.outdoorActivity:
        return Icons.outdoor_grill;
      case LocationType.urbanExploration:
        return Icons.explore;
    }
  }
} 