// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrailData _$TrailDataFromJson(Map<String, dynamic> json) => TrailData(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      difficulty: $enumDecode(_$TrailDifficultyEnumMap, json['difficulty']),
      type: $enumDecode(_$TrailTypeEnumMap, json['type']),
      lengthKm: (json['lengthKm'] as num).toDouble(),
      elevationGainM: (json['elevationGainM'] as num).toInt(),
      estimatedTimeMinutes: (json['estimatedTimeMinutes'] as num).toInt(),
      rating: (json['rating'] as num).toDouble(),
      reviewCount: (json['reviewCount'] as num).toInt(),
      startLocation:
          GeoLocation.fromJson(json['startLocation'] as Map<String, dynamic>),
      endLocation:
          GeoLocation.fromJson(json['endLocation'] as Map<String, dynamic>),
      route: (json['route'] as List<dynamic>)
          .map((e) => GeoLocation.fromJson(e as Map<String, dynamic>))
          .toList(),
      features: (json['features'] as List<dynamic>)
          .map((e) => TrailFeature.fromJson(e as Map<String, dynamic>))
          .toList(),
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      mapUrl: json['mapUrl'] as String?,
      currentConditions: json['currentConditions'] == null
          ? null
          : TrailConditions.fromJson(
              json['currentConditions'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TrailDataToJson(TrailData instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'difficulty': _$TrailDifficultyEnumMap[instance.difficulty]!,
      'type': _$TrailTypeEnumMap[instance.type]!,
      'lengthKm': instance.lengthKm,
      'elevationGainM': instance.elevationGainM,
      'estimatedTimeMinutes': instance.estimatedTimeMinutes,
      'rating': instance.rating,
      'reviewCount': instance.reviewCount,
      'startLocation': instance.startLocation,
      'endLocation': instance.endLocation,
      'route': instance.route,
      'features': instance.features,
      'tags': instance.tags,
      'thumbnailUrl': instance.thumbnailUrl,
      'mapUrl': instance.mapUrl,
      'currentConditions': instance.currentConditions,
    };

const _$TrailDifficultyEnumMap = {
  TrailDifficulty.easy: 'easy',
  TrailDifficulty.moderate: 'moderate',
  TrailDifficulty.hard: 'hard',
  TrailDifficulty.expert: 'expert',
};

const _$TrailTypeEnumMap = {
  TrailType.hiking: 'hiking',
  TrailType.walking: 'walking',
  TrailType.running: 'running',
  TrailType.biking: 'biking',
  TrailType.climbing: 'climbing',
  TrailType.backpacking: 'backpacking',
};

TrailFeature _$TrailFeatureFromJson(Map<String, dynamic> json) => TrailFeature(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      location: GeoLocation.fromJson(json['location'] as Map<String, dynamic>),
      photos:
          (json['photos'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$TrailFeatureToJson(TrailFeature instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'type': instance.type,
      'location': instance.location,
      'photos': instance.photos,
    };

TrailConditions _$TrailConditionsFromJson(Map<String, dynamic> json) =>
    TrailConditions(
      status: json['status'] as String,
      statusDescription: json['statusDescription'] as String?,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      alerts:
          (json['alerts'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$TrailConditionsToJson(TrailConditions instance) =>
    <String, dynamic>{
      'status': instance.status,
      'statusDescription': instance.statusDescription,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
      'alerts': instance.alerts,
    };
