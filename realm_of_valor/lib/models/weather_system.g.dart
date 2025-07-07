// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_system.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeatherCondition _$WeatherConditionFromJson(Map<String, dynamic> json) =>
    WeatherCondition(
      type: $enumDecode(_$WeatherTypeEnumMap, json['type']),
      temperature: (json['temperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      windSpeed: (json['windSpeed'] as num).toDouble(),
      visibility: (json['visibility'] as num).toDouble(),
      description: json['description'] as String,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$WeatherConditionToJson(WeatherCondition instance) =>
    <String, dynamic>{
      'type': _$WeatherTypeEnumMap[instance.type]!,
      'temperature': instance.temperature,
      'humidity': instance.humidity,
      'windSpeed': instance.windSpeed,
      'visibility': instance.visibility,
      'description': instance.description,
      'timestamp': instance.timestamp.toIso8601String(),
      'metadata': instance.metadata,
    };

const _$WeatherTypeEnumMap = {
  WeatherType.sunny: 'sunny',
  WeatherType.cloudy: 'cloudy',
  WeatherType.rainy: 'rainy',
  WeatherType.stormy: 'stormy',
  WeatherType.snowy: 'snowy',
  WeatherType.foggy: 'foggy',
  WeatherType.windy: 'windy',
  WeatherType.extreme: 'extreme',
};

WeatherEvent _$WeatherEventFromJson(Map<String, dynamic> json) => WeatherEvent(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String,
      requiredWeather:
          $enumDecode(_$WeatherTypeEnumMap, json['requiredWeather']),
      requiredSeason:
          $enumDecodeNullable(_$SeasonEnumMap, json['requiredSeason']),
      bonusCards: (json['bonusCards'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      bonuses: json['bonuses'] as Map<String, dynamic>?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      isActive: json['isActive'] as bool? ?? true,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$WeatherEventToJson(WeatherEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'requiredWeather': _$WeatherTypeEnumMap[instance.requiredWeather]!,
      'requiredSeason': _$SeasonEnumMap[instance.requiredSeason],
      'bonusCards': instance.bonusCards,
      'bonuses': instance.bonuses,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'isActive': instance.isActive,
      'metadata': instance.metadata,
    };

const _$SeasonEnumMap = {
  Season.spring: 'spring',
  Season.summer: 'summer',
  Season.autumn: 'autumn',
  Season.winter: 'winter',
};
