import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/adventure_system.dart' as adv;

class POIService {
  static final POIService _instance = POIService._internal();
  factory POIService() => _instance;
  POIService._internal();

  // Default search radius in meters
  double defaultRadiusMeters = 1500.0;

  // Fetch nearby POIs around a user location
  Future<List<adv.POI>> fetchNearbyPOIs(
    adv.GeoLocation center, {
    double? radiusMeters,
    int limit = 50,
  }) async {
    final radius = (radiusMeters ?? defaultRadiusMeters).toInt();

    final query = _buildOverpassQuery(center.latitude, center.longitude, radius, limit);
    final response = await http.post(
      Uri.parse('https://overpass-api.de/api/interpreter'),
      body: {'data': query},
    );

    if (response.statusCode != 200) {
      return [];
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final elements = List<Map<String, dynamic>>.from(data['elements'] ?? []);

    final pois = <adv.POI>[];
    for (final e in elements) {
      final tags = Map<String, dynamic>.from(e['tags'] ?? {});
      final lat = (e['lat'] ?? (e['center']?['lat']))?.toDouble();
      final lon = (e['lon'] ?? (e['center']?['lon']))?.toDouble();
      if (lat == null || lon == null) continue;

      final name = (tags['name'] as String?) ?? _inferNameFromTags(tags) ?? 'Unknown Place';
      final category = _inferCategory(tags);
      final locationType = _mapCategoryToLocationType(category);

      pois.add(
        adv.POI(
          name: name,
          description: _buildDescription(tags, category),
          type: locationType,
          location: adv.GeoLocation(latitude: lat, longitude: lon),
          radius: 100.0,
          properties: {
            'category': category,
            'source': 'osm_overpass',
            'raw_tags': tags,
          },
        ),
      );
    }

    return pois;
  }

  String _buildOverpassQuery(double lat, double lon, int radius, int limit) {
    // Search common POI types; limit keeps results reasonable
    // amenity: restaurant, cafe, bar, pub, fast_food, library, school, hospital, gym, place_of_worship
    // leisure: park
    // tourism: museum, attraction
    // historic: *
    return '''
[out:json][timeout:25];
(
  node(around:$radius,$lat,$lon)["amenity"~"restaurant|cafe|bar|pub|fast_food|library|school|hospital|place_of_worship|clinic|pharmacy|college|university|bank|post_office|cinema|theatre|arts_centre|marketplace|community_centre|nightclub|bureau_de_change"]; 
  node(around:$radius,$lat,$lon)["leisure"~"park|fitness_centre|sports_centre|stadium|pitch|swimming_pool"]; 
  node(around:$radius,$lat,$lon)["tourism"~"museum|attraction|gallery|viewpoint"]; 
  node(around:$radius,$lat,$lon)["shop"~"supermarket|convenience|bakery|butcher|greengrocer|mall|department_store|sports|outdoor|books|coffee"]; 
  node(around:$radius,$lat,$lon)["historic"]; 
);
out center $limit;
''';
  }

  String? _inferNameFromTags(Map<String, dynamic> tags) {
    return tags['brand'] as String? ?? tags['operator'] as String?;
  }

  String _inferCategory(Map<String, dynamic> tags) {
    final amenity = tags['amenity'] as String?;
    final leisure = tags['leisure'] as String?;
    final tourism = tags['tourism'] as String?;
    final shop = tags['shop'] as String?;
    final historic = tags['historic'] as String?;

    if (leisure == 'park') return 'park';

    switch (amenity) {
      case 'restaurant':
      case 'fast_food':
        return 'restaurant';
      case 'cafe':
        return 'cafe';
      case 'library':
        return 'library';
      case 'school':
      case 'college':
      case 'university':
        return 'school';
      case 'hospital':
      case 'clinic':
      case 'pharmacy':
        return 'hospital';
      case 'bar':
      case 'pub':
      case 'nightclub':
        return 'pub';
      case 'place_of_worship':
        return 'temple';
      case 'cinema':
      case 'theatre':
      case 'arts_centre':
        return 'venue';
      case 'community_centre':
        return 'community_center';
      case 'marketplace':
        return 'market';
    }

    switch (leisure) {
      case 'fitness_centre':
      case 'sports_centre':
      case 'stadium':
      case 'pitch':
      case 'swimming_pool':
        return 'gym';
    }

    switch (tourism) {
      case 'museum':
        return 'museum';
      case 'attraction':
      case 'gallery':
      case 'viewpoint':
        return 'landmark';
    }

    if (historic != null) return 'monument';

    switch (shop) {
      case 'supermarket':
      case 'convenience':
      case 'bakery':
      case 'butcher':
      case 'greengrocer':
      case 'mall':
      case 'department_store':
        return 'shop';
      case 'sports':
      case 'outdoor':
        return 'outdoor_shop';
      case 'books':
        return 'bookshop';
      case 'coffee':
        return 'cafe';
    }

    return 'poi';
  }

  adv.LocationType _mapCategoryToLocationType(String category) {
    switch (category) {
      case 'park':
        return adv.LocationType.park;
      case 'gym':
        return adv.LocationType.gym;
      case 'restaurant':
        return adv.LocationType.restaurant;
      case 'library':
        return adv.LocationType.library;
      case 'school':
        return adv.LocationType.school;
      case 'monument':
      case 'landmark':
        return adv.LocationType.monument;
      case 'pub':
        return adv.LocationType.business;
      default:
        return adv.LocationType.other;
    }
  }

  String _buildDescription(Map<String, dynamic> tags, String category) {
    final cuisine = tags['cuisine'];
    final operator = tags['operator'];
    final brand = tags['brand'];
    final info = [
      if (cuisine != null) 'Cuisine: $cuisine',
      if (operator != null) 'Operator: $operator',
      if (brand != null) 'Brand: $brand',
    ].where((e) => e.isNotEmpty).join(' • ');
    if (info.isEmpty) return category;
    return '$category • $info';
  }
}