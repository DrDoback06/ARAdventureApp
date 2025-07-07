import 'package:json_annotation/json_annotation.dart';
import 'package:realm_of_valor/models/card_model.dart';
import 'package:realm_of_valor/models/adventure_system.dart';
import 'package:uuid/uuid.dart';
import 'dart:math' as math;

part 'weather_system.g.dart';

enum WeatherType {
  sunny,
  cloudy,
  rainy,
  stormy,
  snowy,
  foggy,
  windy,
  extreme, // Heatwave, blizzard, etc.
}

enum Season {
  spring,
  summer,
  autumn,
  winter,
}

@JsonSerializable()
class WeatherCondition {
  final WeatherType type;
  final double temperature; // In Celsius
  final double humidity; // Percentage
  final double windSpeed; // km/h
  final double visibility; // km
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  WeatherCondition({
    required this.type,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.visibility,
    required this.description,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) : timestamp = timestamp ?? DateTime.now(),
       metadata = metadata ?? {};

  factory WeatherCondition.fromJson(Map<String, dynamic> json) =>
      _$WeatherConditionFromJson(json);
  Map<String, dynamic> toJson() => _$WeatherConditionToJson(this);

  Season get currentSeason {
    final month = timestamp.month;
    if (month >= 3 && month <= 5) return Season.spring;
    if (month >= 6 && month <= 8) return Season.summer;
    if (month >= 9 && month <= 11) return Season.autumn;
    return Season.winter;
  }

  bool get isExtreme {
    return temperature > 35 || temperature < -10 || windSpeed > 50 || type == WeatherType.extreme;
  }

  bool get isFavorableForOutdoor {
    return !isExtreme && type != WeatherType.stormy && visibility > 5;
  }
}

@JsonSerializable()
class WeatherEvent {
  final String id;
  final String name;
  final String description;
  final WeatherType requiredWeather;
  final Season? requiredSeason;
  final List<String> bonusCards;
  final Map<String, dynamic> bonuses;
  final DateTime startTime;
  final DateTime endTime;
  final bool isActive;
  final Map<String, dynamic> metadata;

  WeatherEvent({
    String? id,
    required this.name,
    required this.description,
    required this.requiredWeather,
    this.requiredSeason,
    List<String>? bonusCards,
    Map<String, dynamic>? bonuses,
    required this.startTime,
    required this.endTime,
    this.isActive = true,
    Map<String, dynamic>? metadata,
  }) : id = id ?? const Uuid().v4(),
       bonusCards = bonusCards ?? [],
       bonuses = bonuses ?? {},
       metadata = metadata ?? {};

  factory WeatherEvent.fromJson(Map<String, dynamic> json) =>
      _$WeatherEventFromJson(json);
  Map<String, dynamic> toJson() => _$WeatherEventToJson(this);

  bool isValidForWeather(WeatherCondition weather) {
    final weatherMatches = weather.type == requiredWeather;
    final seasonMatches = requiredSeason == null || weather.currentSeason == requiredSeason;
    final timeValid = DateTime.now().isAfter(startTime) && DateTime.now().isBefore(endTime);
    
    return weatherMatches && seasonMatches && timeValid && isActive;
  }
}

class WeatherSystem {
  // Amazing weather-based events and bonuses!
  static List<WeatherEvent> get weatherEvents => [
    // Sunny Weather Events
    WeatherEvent(
      name: 'Solar Blessing',
      description: 'The sun\'s rays energize all adventurers! Gain bonus XP and find rare Solar cards.',
      requiredWeather: WeatherType.sunny,
      bonusCards: ['solar_crystal', 'sun_blade', 'light_energy', 'solar_panel'],
      bonuses: {
        'xp_multiplier': 1.5,
        'solar_card_spawn_rate': 3.0,
        'energy_regeneration': 1.2,
      },
      startTime: DateTime.now(),
      endTime: DateTime.now().add(Duration(hours: 12)),
    ),
    
    // Rainy Weather Events  
    WeatherEvent(
      name: 'Storm\'s Gift',
      description: 'Lightning crackles through the air! Electric and Water cards appear more frequently.',
      requiredWeather: WeatherType.rainy,
      bonusCards: ['lightning_rod', 'storm_essence', 'rain_drop', 'thunder_spirit'],
      bonuses: {
        'electric_spell_power': 1.3,
        'water_healing_bonus': 1.25,
        'storm_card_spawn_rate': 2.5,
      },
      startTime: DateTime.now(),
      endTime: DateTime.now().add(Duration(hours: 8)),
    ),

    WeatherEvent(
      name: 'Tempest Fury',
      description: 'Powerful storms rage! Only the brave venture out for legendary storm artifacts.',
      requiredWeather: WeatherType.stormy,
      bonusCards: ['tempest_crown', 'hurricane_sword', 'storm_lord_cloak', 'lightning_essence'],
      bonuses: {
        'legendary_drop_rate': 2.0,
        'storm_resistance': 0.5,
        'courage_bonus_xp': 2.0,
      },
      startTime: DateTime.now(),
      endTime: DateTime.now().add(Duration(hours: 6)),
    ),

    // Snow Weather Events
    WeatherEvent(
      name: 'Winter\'s Embrace',
      description: 'Snow falls gently, revealing hidden ice treasures and winter spirits.',
      requiredWeather: WeatherType.snowy,
      requiredSeason: Season.winter,
      bonusCards: ['ice_crystal', 'snow_spirit', 'winter_wolf', 'frost_armor'],
      bonuses: {
        'ice_spell_power': 1.4,
        'winter_card_spawn_rate': 2.0,
        'cold_resistance': 0.3,
      },
      startTime: DateTime.now(),
      endTime: DateTime.now().add(Duration(hours: 10)),
    ),

    // Foggy Weather Events
    WeatherEvent(
      name: 'Mystic Mist',
      description: 'Mysterious fog conceals rare shadow creatures and ancient secrets.',
      requiredWeather: WeatherType.foggy,
      bonusCards: ['shadow_veil', 'mist_walker', 'phantom_blade', 'ethereal_essence'],
      bonuses: {
        'stealth_bonus': 1.5,
        'shadow_card_spawn_rate': 2.2,
        'mystery_bonus': 1.3,
      },
      startTime: DateTime.now(),
      endTime: DateTime.now().add(Duration(hours: 6)),
    ),

    // Windy Weather Events
    WeatherEvent(
      name: 'Gale Force Adventure',
      description: 'Strong winds carry rare air elemental cards from distant realms.',
      requiredWeather: WeatherType.windy,
      bonusCards: ['wind_blade', 'air_elemental', 'storm_rider', 'gale_boots'],
      bonuses: {
        'movement_speed': 1.3,
        'air_spell_power': 1.35,
        'wind_card_spawn_rate': 2.8,
      },
      startTime: DateTime.now(),
      endTime: DateTime.now().add(Duration(hours: 8)),
    ),
  ];

  // Seasonal events that last for entire seasons
  static List<WeatherEvent> get seasonalEvents => [
    WeatherEvent(
      name: 'Spring Awakening Festival',
      description: 'Nature awakens! All outdoor activities give bonus rewards and nature cards bloom.',
      requiredWeather: WeatherType.sunny, // Spring sunshine
      requiredSeason: Season.spring,
      bonusCards: ['spring_blossom', 'nature_guardian', 'growth_crystal', 'life_essence'],
      bonuses: {
        'outdoor_activity_xp': 2.0,
        'nature_card_spawn_rate': 3.0,
        'healing_effectiveness': 1.5,
        'fitness_motivation': 1.4,
      },
      startTime: DateTime(DateTime.now().year, 3, 20), // Spring Equinox
      endTime: DateTime(DateTime.now().year, 6, 20),   // Summer Solstice
    ),

    WeatherEvent(
      name: 'Summer Solstice Power',
      description: 'The longest day brings maximum energy! Fire cards and fitness rewards are amplified.',
      requiredWeather: WeatherType.sunny,
      requiredSeason: Season.summer,
      bonusCards: ['summer_flame', 'solar_crown', 'heat_wave', 'energy_burst'],
      bonuses: {
        'fire_spell_power': 1.6,
        'fitness_xp_multiplier': 1.8,
        'energy_regeneration': 1.5,
        'summer_card_spawn_rate': 2.5,
      },
      startTime: DateTime(DateTime.now().year, 6, 20),
      endTime: DateTime(DateTime.now().year, 9, 22),
    ),

    WeatherEvent(
      name: 'Autumn Harvest Moon',
      description: 'The harvest moon brings wisdom and rare earth treasures.',
      requiredWeather: WeatherType.cloudy, // Autumn clouds
      requiredSeason: Season.autumn,
      bonusCards: ['harvest_moon', 'autumn_leaf', 'earth_crystal', 'wisdom_scroll'],
      bonuses: {
        'earth_spell_power': 1.4,
        'collection_bonus': 1.3,
        'wisdom_xp_bonus': 1.6,
        'treasure_find_rate': 1.5,
      },
      startTime: DateTime(DateTime.now().year, 9, 22),
      endTime: DateTime(DateTime.now().year, 12, 21),
    ),

    WeatherEvent(
      name: 'Winter Solstice Magic',
      description: 'The longest night awakens ancient ice magic and legendary winter spirits.',
      requiredWeather: WeatherType.snowy,
      requiredSeason: Season.winter,
      bonusCards: ['winter_solstice_crown', 'ice_lord_scepter', 'aurora_cloak', 'frost_dragon'],
      bonuses: {
        'ice_spell_power': 1.7,
        'legendary_spawn_rate': 2.0,
        'winter_endurance': 1.5,
        'holiday_spirit_bonus': 2.0,
      },
      startTime: DateTime(DateTime.now().year, 12, 21),
      endTime: DateTime(DateTime.now().year + 1, 3, 20),
    ),
  ];

  // Weather-based card spawning modifiers
  static Map<WeatherType, Map<String, dynamic>> get weatherSpawnModifiers => {
    WeatherType.sunny: {
      'card_types': ['solar', 'light', 'energy', 'fire'],
      'spawn_rate_multiplier': 1.5,
      'bonus_xp': 1.2,
      'preferred_locations': [LocationType.park, LocationType.beach],
    },
    WeatherType.rainy: {
      'card_types': ['water', 'storm', 'lightning', 'nature'],
      'spawn_rate_multiplier': 1.3,
      'bonus_xp': 1.1,
      'preferred_locations': [LocationType.park, LocationType.bridge],
    },
    WeatherType.stormy: {
      'card_types': ['lightning', 'storm', 'chaos', 'power'],
      'spawn_rate_multiplier': 2.0,
      'bonus_xp': 1.5,
      'preferred_locations': [LocationType.monument, LocationType.mountain],
      'danger_bonus': 1.8, // Extra rewards for braving the storm
    },
    WeatherType.snowy: {
      'card_types': ['ice', 'winter', 'crystal', 'frost'],
      'spawn_rate_multiplier': 1.4,
      'bonus_xp': 1.3,
      'preferred_locations': [LocationType.park, LocationType.mountain],
    },
    WeatherType.foggy: {
      'card_types': ['shadow', 'mystery', 'phantom', 'stealth'],
      'spawn_rate_multiplier': 1.6,
      'bonus_xp': 1.25,
      'preferred_locations': [LocationType.bridge, LocationType.trail],
    },
    WeatherType.windy: {
      'card_types': ['air', 'wind', 'speed', 'flight'],
      'spawn_rate_multiplier': 1.4,
      'bonus_xp': 1.15,
      'preferred_locations': [LocationType.mountain, LocationType.beach],
    },
    WeatherType.cloudy: {
      'card_types': ['neutral', 'wisdom', 'balance', 'earth'],
      'spawn_rate_multiplier': 1.0,
      'bonus_xp': 1.0,
      'preferred_locations': [], // No preference
    },
  };

  // Fitness motivation based on weather
  static Map<String, dynamic> getFitnessMotivationForWeather(WeatherCondition weather) {
    final motivation = <String, dynamic>{};
    
    switch (weather.type) {
      case WeatherType.sunny:
        if (weather.temperature >= 15 && weather.temperature <= 25) {
          motivation['message'] = 'Perfect weather for outdoor adventure! Get out there and explore!';
          motivation['bonus_multiplier'] = 1.5;
          motivation['suggested_activities'] = ['walking', 'running', 'cycling', 'hiking'];
        } else if (weather.temperature > 30) {
          motivation['message'] = 'Hot day ahead! Stay hydrated and find shaded areas for your quest.';
          motivation['bonus_multiplier'] = 1.2;
          motivation['warnings'] = ['Stay hydrated', 'Seek shade', 'Avoid peak sun hours'];
        }
        break;
        
      case WeatherType.rainy:
        motivation['message'] = 'Rainy day magic is in the air! Indoor activities or brave the elements for rare storm cards!';
        motivation['bonus_multiplier'] = 1.3;
        motivation['suggested_activities'] = ['indoor cycling', 'yoga', 'strength training'];
        motivation['outdoor_bonus'] = 2.0; // Extra rewards for outdoor bravery
        break;
        
      case WeatherType.snowy:
        motivation['message'] = 'Winter wonderland awaits! Bundle up for magical snow adventures!';
        motivation['bonus_multiplier'] = 1.4;
        motivation['suggested_activities'] = ['winter walking', 'snowshoeing', 'winter sports'];
        motivation['warnings'] = ['Dress warmly', 'Watch for ice', 'Shorter outdoor sessions'];
        break;
        
      case WeatherType.stormy:
        motivation['message'] = 'Storms rage outside! Perfect time for indoor training or brave the tempest for legendary rewards!';
        motivation['bonus_multiplier'] = 2.0;
        motivation['suggested_activities'] = ['indoor workouts', 'meditation', 'strength training'];
        motivation['outdoor_bonus'] = 3.0; // Maximum rewards for storm bravery
        motivation['warnings'] = ['Safety first', 'Avoid outdoor activities', 'Lightning danger'];
        break;
        
      case WeatherType.foggy:
        motivation['message'] = 'Mysterious fog brings hidden opportunities! Perfect for mindful walking.';
        motivation['bonus_multiplier'] = 1.25;
        motivation['suggested_activities'] = ['mindful walking', 'meditation', 'gentle exercise'];
        motivation['warnings'] = ['Limited visibility', 'Stay on known paths'];
        break;
        
      case WeatherType.windy:
        motivation['message'] = 'Windy conditions add challenge to your adventure! Let the wind power your journey!';
        motivation['bonus_multiplier'] = 1.3;
        motivation['suggested_activities'] = ['power walking', 'resistance training', 'balance exercises'];
        break;
        
      default:
        motivation['message'] = 'Every day is a good day for adventure!';
        motivation['bonus_multiplier'] = 1.0;
        motivation['suggested_activities'] = ['walking', 'light exercise'];
    }
    
    return motivation;
  }

  // Dynamic quest generation based on weather
  static List<Quest> generateWeatherQuests(WeatherCondition weather) {
    final quests = <Quest>[];
    final now = DateTime.now();
    
    switch (weather.type) {
      case WeatherType.sunny:
        quests.add(Quest(
          title: 'Solar Energy Collector',
          description: 'Harness the power of the sun! Walk 5000 steps in sunny weather to collect solar energy cards.',
          type: QuestType.fitness,
          level: 1,
          xpReward: 300,
          cardRewards: ['solar_crystal', 'sun_blade', 'light_energy'],
          endTime: now.add(Duration(hours: 8)),
          objectives: [
            QuestObjective(
              title: 'Soak Up the Sun',
              description: 'Take 5000 steps while it\'s sunny',
              type: 'sunny_steps',
              requirements: {'steps': 5000, 'weather': 'sunny'},
              xpReward: 200,
            ),
            QuestObjective(
              title: 'Solar Power',
              description: 'Spend 30 minutes outdoors in sunlight',
              type: 'outdoor_time',
              requirements: {'minutes': 30, 'weather': 'sunny'},
              xpReward: 100,
            ),
          ],
        ));
        break;
        
      case WeatherType.rainy:
        quests.add(Quest(
          title: 'Storm Chaser',
          description: 'Brave the rain to collect rare storm cards! Indoor activities also count.',
          type: QuestType.fitness,
          level: 2,
          xpReward: 400,
          cardRewards: ['storm_essence', 'rain_drop', 'thunder_spirit'],
          endTime: now.add(Duration(hours: 6)),
          objectives: [
            QuestObjective(
              title: 'Weather the Storm',
              description: 'Stay active for 20 minutes during rain',
              type: 'rainy_activity',
              requirements: {'active_minutes': 20, 'weather': 'rainy'},
              xpReward: 250,
            ),
            QuestObjective(
              title: 'Lightning Reflexes',
              description: 'Complete 2 quick exercises during the storm',
              type: 'storm_exercises',
              requirements: {'exercises': 2, 'weather': 'rainy'},
              xpReward: 150,
            ),
          ],
        ));
        break;
        
      case WeatherType.snowy:
        quests.add(Quest(
          title: 'Winter Warrior',
          description: 'Embrace the cold! Winter activities unlock magical ice treasures.',
          type: QuestType.fitness,
          level: 3,
          xpReward: 500,
          cardRewards: ['ice_crystal', 'winter_wolf', 'frost_armor'],
          endTime: now.add(Duration(hours: 10)),
          objectives: [
            QuestObjective(
              title: 'Brave the Cold',
              description: 'Take 3000 steps in snowy weather',
              type: 'snowy_steps',
              requirements: {'steps': 3000, 'weather': 'snowy'},
              xpReward: 300,
            ),
            QuestObjective(
              title: 'Winter Endurance',
              description: 'Stay active outdoors for 15 minutes in snow',
              type: 'winter_endurance',
              requirements: {'minutes': 15, 'weather': 'snowy'},
              xpReward: 200,
            ),
          ],
        ));
        break;
        
      default:
        break;
    }
    
    return quests;
  }

  // Weather-based merchant spawning
  static List<String> getWeatherMerchantCards(WeatherCondition weather) {
    switch (weather.type) {
      case WeatherType.sunny:
        return ['solar_crystal', 'sun_blade', 'light_energy', 'solar_panel', 'bright_armor'];
      case WeatherType.rainy:
        return ['storm_essence', 'rain_drop', 'thunder_spirit', 'lightning_rod', 'storm_cloak'];
      case WeatherType.snowy:
        return ['ice_crystal', 'winter_wolf', 'frost_armor', 'snow_spirit', 'arctic_blade'];
      case WeatherType.stormy:
        return ['tempest_crown', 'hurricane_sword', 'storm_lord_cloak', 'lightning_essence', 'chaos_orb'];
      case WeatherType.foggy:
        return ['shadow_veil', 'mist_walker', 'phantom_blade', 'ethereal_essence', 'stealth_cloak'];
      case WeatherType.windy:
        return ['wind_blade', 'air_elemental', 'storm_rider', 'gale_boots', 'wind_spirit'];
      default:
        return ['weather_charm', 'climate_crystal', 'neutral_essence'];
    }
  }

  // Calculate weather-based XP bonus
  static double calculateWeatherXPBonus(WeatherCondition weather, bool isOutdoorActivity) {
    double bonus = 1.0;
    
    // Base weather bonus
    final weatherModifier = weatherSpawnModifiers[weather.type];
    if (weatherModifier != null) {
      bonus *= weatherModifier['bonus_xp'] ?? 1.0;
    }
    
    // Outdoor activity bonus during challenging weather
    if (isOutdoorActivity) {
      switch (weather.type) {
        case WeatherType.stormy:
          bonus *= 2.0; // Double XP for storm bravery
          break;
        case WeatherType.snowy:
          bonus *= 1.5; // 50% bonus for cold weather endurance
          break;
        case WeatherType.rainy:
          bonus *= 1.3; // 30% bonus for rain dedication
          break;
        case WeatherType.extreme:
          bonus *= 1.8; // 80% bonus for extreme weather courage
          break;
        default:
          break;
      }
    }
    
    // Temperature-based modifiers
    if (weather.temperature < 0) {
      bonus *= 1.4; // Cold weather endurance bonus
    } else if (weather.temperature > 35) {
      bonus *= 1.3; // Hot weather perseverance bonus
    }
    
    return bonus;
  }

  // Weather safety recommendations
  static Map<String, dynamic> getWeatherSafetyInfo(WeatherCondition weather) {
    final safety = <String, dynamic>{};
    
    switch (weather.type) {
      case WeatherType.sunny:
        if (weather.temperature > 30) {
          safety['level'] = 'caution';
          safety['recommendations'] = [
            'Stay hydrated - drink water frequently',
            'Wear sunscreen and protective clothing',
            'Avoid outdoor activities during peak sun (11 AM - 3 PM)',
            'Seek shade when possible',
          ];
          safety['indoor_alternatives'] = [
            'Indoor cycling or treadmill',
            'Mall walking in air conditioning',
            'Swimming at indoor pools',
          ];
        } else {
          safety['level'] = 'ideal';
          safety['recommendations'] = [
            'Perfect weather for outdoor activities!',
            'Still wear sunscreen for extended exposure',
            'Stay hydrated',
          ];
        }
        break;
        
      case WeatherType.stormy:
        safety['level'] = 'danger';
        safety['recommendations'] = [
          'Avoid all outdoor activities',
          'Stay indoors until storm passes',
          'Unplug electronics during lightning',
          'Have indoor backup activities ready',
        ];
        safety['indoor_alternatives'] = [
          'Bodyweight exercises',
          'Yoga or stretching',
          'Indoor strength training',
          'Meditation and breathing exercises',
        ];
        break;
        
      case WeatherType.snowy:
        safety['level'] = 'caution';
        safety['recommendations'] = [
          'Dress in warm, layered clothing',
          'Wear proper footwear with good traction',
          'Limit outdoor exposure time',
          'Watch for signs of hypothermia',
        ];
        safety['cold_weather_tips'] = [
          'Cover exposed skin',
          'Stay dry - wet clothing loses insulation',
          'Keep moving to maintain body heat',
          'Know the signs of frostbite',
        ];
        break;
        
      case WeatherType.rainy:
        safety['level'] = 'moderate';
        safety['recommendations'] = [
          'Wear waterproof clothing if going outside',
          'Be extra careful on wet surfaces',
          'Increase visibility with bright colors',
          'Consider indoor alternatives',
        ];
        break;
        
      default:
        safety['level'] = 'good';
        safety['recommendations'] = [
          'Great weather for outdoor activities!',
          'Stay aware of changing conditions',
        ];
    }
    
    return safety;
  }

  // Create weather-specific world spawns
  static List<WorldSpawn> createWeatherSpawns(WeatherCondition weather, GeoLocation location) {
    final spawns = <WorldSpawn>[];
    final now = DateTime.now();
    final weatherCards = getWeatherMerchantCards(weather);
    
    // Main weather spawn
    spawns.add(WorldSpawn(
      name: '${weather.type.name.capitalize()} Essence Node',
      description: 'A magical manifestation of ${weather.type.name} energy, offering weather-specific treasures.',
      type: SpawnType.rare,
      location: location,
      radius: 75,
      availableCards: weatherCards,
      rewards: {
        'xp': (100 * calculateWeatherXPBonus(weather, true)).round(),
        'gold': 75,
        'weather_essence': 1,
      },
      despawnTime: now.add(Duration(hours: 4)),
      metadata: {
        'weather_type': weather.type.name,
        'temperature': weather.temperature,
        'requires_weather': true,
      },
    ));
    
    // Special rare spawn for extreme weather
    if (weather.isExtreme) {
      spawns.add(WorldSpawn(
        name: 'Extreme Weather Guardian',
        description: 'A legendary being that only appears during extreme weather conditions.',
        type: SpawnType.legendary,
        location: location,
        radius: 100,
        availableCards: ['extreme_weather_crown', 'elemental_mastery', 'storm_king_scepter'],
        rewards: {
          'xp': 500,
          'gold': 250,
          'legendary_essence': 1,
        },
        maxInteractions: 1,
        despawnTime: now.add(Duration(hours: 2)),
        metadata: {
          'extreme_weather': true,
          'courage_bonus': 2.0,
        },
      ));
    }
    
    return spawns;
  }
}

// Helper extension for string capitalization
extension StringCapitalization on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}