import 'dart:math';
import 'package:flutter/foundation.dart';

import '../models/adventure_map_model.dart';
import '../models/quest_model.dart';

class DungeonMasterService extends ChangeNotifier {
  static final DungeonMasterService _instance = DungeonMasterService._internal();
  factory DungeonMasterService() => _instance;
  DungeonMasterService._internal();

  // Story templates and contextual elements
  final Map<String, List<String>> _storyTemplates = {
    'pub': [
      'The local tavern buzzes with life as adventurers gather to share tales. {name} has become a hub for travelers seeking both refreshment and companionship.',
      'Legends speak of the mysterious patrons who frequent {name}. Some say they hold secrets that could change the course of your journey.',
      'The warm glow of {name} beckons weary travelers. Inside, you might find allies for your next adventure or hear whispers of hidden treasures.',
    ],
    'park': [
      'Ancient magic lingers in the air of {name}. The trees whisper secrets to those who listen carefully.',
      'The peaceful grounds of {name} hide more than meets the eye. Local legends speak of enchanted clearings and mystical encounters.',
      'Nature\'s sanctuary, {name} offers both tranquility and adventure. Many have discovered unexpected treasures while exploring its paths.',
    ],
    'trail': [
      'The winding path of {name} has challenged countless adventurers. Each step brings you closer to discovery or danger.',
      'Ancient footsteps echo along {name}. This trail has witnessed the passage of heroes and villains alike.',
      'The rugged terrain of {name} tests the mettle of all who dare to traverse it. Rewards await those who persevere.',
    ],
    'landmark': [
      'The majestic {name} stands as a testament to the region\'s rich history. Its walls hold stories of glory and conquest.',
      'Centuries of history are etched into the very stones of {name}. Each corner reveals a new chapter in the saga.',
      'The iconic {name} draws visitors from far and wide. Some seek knowledge, others seek adventure, but all find something unexpected.',
    ],
    'culturalSite': [
      'The hallowed halls of {name} preserve the wisdom of ages past. Scholars and seekers alike find enlightenment within.',
      'Cultural treasures await discovery at {name}. The artifacts and exhibits tell stories of civilizations long gone.',
      'The artistic and historical significance of {name} makes it a beacon for those seeking to understand the world\'s mysteries.',
    ],
  };

  final Map<String, List<String>> _weatherStories = {
    'rainy': [
      'The rain creates an atmosphere of mystery and adventure. Water droplets dance on ancient stones, revealing hidden patterns.',
      'Storm clouds gather overhead, adding drama to your quest. The weather itself seems to be part of the challenge.',
      'The rhythmic patter of rain creates a soothing backdrop for exploration. Some say secrets are easier to find in the rain.',
    ],
    'stormy': [
      'Lightning illuminates the landscape in brief, dramatic flashes. The storm adds an element of danger and excitement.',
      'The howling wind carries whispers of ancient secrets. The storm seems to be testing your resolve.',
      'Thunder echoes like the drums of war, urging you forward despite the challenging conditions.',
    ],
    'snowy': [
      'A blanket of snow transforms the landscape into a winter wonderland. The pristine white reveals hidden paths.',
      'The crisp air and snow-covered ground create a magical atmosphere. Every step leaves a mark in the untouched snow.',
      'Winter\'s embrace adds a layer of challenge and beauty to your adventure. The cold tests your endurance.',
    ],
    'clear': [
      'Perfect weather for adventure! The clear skies promise good fortune and smooth travels.',
      'The bright sun illuminates your path, making it easier to spot hidden treasures and secrets.',
      'Ideal conditions for exploration. The weather gods seem to favor your quest today.',
    ],
  };

  final Map<String, List<String>> _timeStories = {
    'morning': [
      'The dawn breaks, bringing new opportunities and fresh challenges. Morning light reveals paths that were hidden in darkness.',
      'Early risers often find the best treasures. The morning air is crisp with possibility.',
      'A new day begins, and with it comes the promise of adventure. The world is yours to explore.',
    ],
    'afternoon': [
      'The sun reaches its zenith, casting long shadows that reveal hidden details in the landscape.',
      'Midday brings the warmth of the sun and the energy of a world in full activity.',
      'The afternoon light creates perfect conditions for discovery and exploration.',
    ],
    'evening': [
      'As the sun sets, the world takes on a magical quality. Evening light reveals secrets hidden during the day.',
      'The golden hour approaches, when everything seems touched by enchantment.',
      'Twilight brings mystery and romance to your adventure. The fading light creates an atmosphere of wonder.',
    ],
    'night': [
      'Under the cover of darkness, the world transforms. Night reveals sights unseen during the day.',
      'The moon and stars guide your path through the nocturnal landscape.',
      'Night adventures carry an extra element of danger and excitement. The darkness holds many secrets.',
    ],
  };

  // Generate contextual story for a quest
  String generateContextualStory(
    MapLocation location,
    WeatherData weather,
    QuestDifficulty difficulty,
  ) {
    final stories = <String>[];
    
    // Add location-specific story
    final locationStories = _storyTemplates[location.type.name] ?? _storyTemplates['landmark']!;
    stories.add(locationStories[Random().nextInt(locationStories.length)]
        .replaceAll('{name}', location.name));
    
    // Add weather context
    final weatherStories = _weatherStories[weather.condition.name] ?? _weatherStories['clear']!;
    stories.add(weatherStories[Random().nextInt(weatherStories.length)]);
    
    // Add time context
    final timeOfDay = _getTimeOfDay();
    final timeStories = _timeStories[timeOfDay] ?? _timeStories['afternoon']!;
    stories.add(timeStories[Random().nextInt(timeStories.length)]);
    
    // Add difficulty context
    stories.add(_getDifficultyContext(difficulty));
    
    return stories.join(' ');
  }

  // Generate dynamic quest name based on context
  String generateDynamicQuestName(
    MapLocation location,
    WeatherData weather,
    QuestDifficulty difficulty,
  ) {
    final timeOfDay = _getTimeOfDay();
    final weatherCondition = weather.condition.name;
    
    final templates = <String>[];
    
    switch (location.type) {
      case LocationType.pub:
        templates.addAll([
          'Social Quest: The Gathering at {name}',
          'Evening Adventure: Tales from {name}',
          'Community Challenge: Friends at {name}',
          'Night Quest: Secrets of {name}',
        ]);
        break;
      case LocationType.trail:
        templates.addAll([
          'Trail Quest: The Path to {name}',
          'Exploration: Discovering {name}',
          'Adventure Quest: Journey to {name}',
          'Nature Challenge: Exploring {name}',
        ]);
        break;
      case LocationType.park:
        templates.addAll([
          'Nature Quest: The Green Heart of {name}',
          'Exploration: Discovering {name}',
          'Peaceful Journey: Walking {name}',
          'Outdoor Adventure: Exploring {name}',
        ]);
        break;
      case LocationType.landmark:
        templates.addAll([
          'Historical Quest: The Legend of {name}',
          'Cultural Journey: Discovering {name}',
          'Heritage Adventure: Exploring {name}',
          'Landmark Quest: The Story of {name}',
        ]);
        break;
      case LocationType.business:
        templates.addAll([
          'Business Quest: Exploring {name}',
          'Discovery Quest: The Secrets of {name}',
          'Exploration: Journey to {name}',
          'Challenge Quest: The Path to {name}',
        ]);
        break;
      case LocationType.historicalSite:
        templates.addAll([
          'Historical Quest: The Legend of {name}',
          'Cultural Journey: Discovering {name}',
          'Heritage Adventure: Exploring {name}',
          'Landmark Quest: The Story of {name}',
        ]);
        break;
      default:
        templates.addAll([
          'Adventure Quest: Exploring {name}',
          'Discovery Quest: The Secrets of {name}',
          'Exploration: Journey to {name}',
          'Challenge Quest: The Path to {name}',
        ]);
    }
    
    String template = templates[Random().nextInt(templates.length)];
    template = template.replaceAll('{name}', location.name);
    
    // Add weather/time modifiers
    if (weather.condition == WeatherCondition.rainy || weather.condition == WeatherCondition.stormy) {
      template = 'Storm Quest: $template';
    } else if (weather.condition == WeatherCondition.snowy) {
      template = 'Winter Quest: $template';
    } else if (timeOfDay == 'night') {
      template = 'Night Quest: $template';
    } else if (timeOfDay == 'evening') {
      template = 'Evening Quest: $template';
    }
    
    return template;
  }

  // Generate dynamic description
  String generateDynamicDescription(
    MapLocation location,
    WeatherData weather,
    QuestDifficulty difficulty,
  ) {
    final distance = location.properties['distance'] ?? 'unknown';
    final duration = location.properties['duration'] ?? 'unknown';
    final timeOfDay = _getTimeOfDay();
    
    String description = 'Visit ${location.name} and experience what this ${location.type.name} has to offer. ';
    description += 'Distance: $distance, Estimated time: $duration. ';
    
    // Add contextual details
    switch (location.type) {
      case LocationType.pub:
        description += 'Perfect for socializing and meeting fellow adventurers. ';
        if (timeOfDay == 'evening' || timeOfDay == 'night') {
          description += 'The atmosphere is especially lively at this time. ';
        }
        break;
      case LocationType.trail:
        description += 'A challenging path that rewards perseverance with stunning views. ';
        if (weather.condition == WeatherCondition.rainy) {
          description += 'The rain makes the trail more challenging but also more rewarding. ';
        }
        break;
      case LocationType.park:
        description += 'A peaceful retreat where nature and adventure meet. ';
        if (weather.condition == WeatherCondition.clear) {
          description += 'Perfect weather for outdoor exploration. ';
        }
        break;
      case LocationType.landmark:
        description += 'A place of historical significance with stories waiting to be discovered. ';
        break;
      default:
        description += 'An interesting location worth exploring. ';
        break;
    }
    
    // Add difficulty context
    switch (difficulty) {
      case QuestDifficulty.easy:
        description += 'This quest is perfect for beginners.';
        break;
      case QuestDifficulty.medium:
        description += 'This quest offers a good challenge for experienced adventurers.';
        break;
      case QuestDifficulty.hard:
        description += 'This quest will test your skills and determination.';
        break;
      case QuestDifficulty.expert:
        description += 'Only the most skilled adventurers should attempt this quest.';
        break;
      case QuestDifficulty.legendary:
        description += 'This legendary quest is reserved for the most elite adventurers.';
        break;
    }
    
    return description;
  }

  // Generate contextual objectives
  List<QuestObjective> generateContextualObjectives(
    MapLocation location,
    QuestDifficulty difficulty,
  ) {
    final objectives = <QuestObjective>[];
    
    // Base objective
    objectives.add(QuestObjective(
      description: 'Visit ${location.name}',
      type: 'location_visit',
      targetValue: 1,
      currentValue: 0,
    ));
    
    // Add contextual objectives based on location type
    switch (location.type) {
      case LocationType.pub:
        objectives.add(QuestObjective(
          description: 'Spend at least 30 minutes at ${location.name}',
          type: 'social_interaction',
          targetValue: 1,
          currentValue: 0,
        ));
        break;
      case LocationType.trail:
        objectives.add(QuestObjective(
          description: 'Complete the full trail at ${location.name}',
          type: 'trail_completion',
          targetValue: 1,
          currentValue: 0,
        ));
        break;
      case LocationType.park:
        objectives.add(QuestObjective(
          description: 'Explore at least 3 different areas of ${location.name}',
          type: 'park_exploration',
          targetValue: 3,
          currentValue: 0,
        ));
        break;
      case LocationType.landmark:
        objectives.add(QuestObjective(
          description: 'Learn about the history of ${location.name}',
          type: 'cultural_learning',
          targetValue: 1,
          currentValue: 0,
        ));
        break;
      case LocationType.business:
        objectives.add(QuestObjective(
          description: 'Explore ${location.name}',
          type: 'business_exploration',
          targetValue: 1,
          currentValue: 0,
        ));
        break;
      case LocationType.poi:
        objectives.add(QuestObjective(
          description: 'Discover ${location.name}',
          type: 'poi_exploration',
          targetValue: 1,
          currentValue: 0,
        ));
        break;
      case LocationType.runningTrack:
        objectives.add(QuestObjective(
          description: 'Complete a run at ${location.name}',
          type: 'running_challenge',
          targetValue: 1,
          currentValue: 0,
        ));
        break;
      case LocationType.gym:
        objectives.add(QuestObjective(
          description: 'Complete a workout at ${location.name}',
          type: 'fitness_challenge',
          targetValue: 1,
          currentValue: 0,
        ));
        break;
      default:
        objectives.add(QuestObjective(
          description: 'Explore ${location.name}',
          type: 'general_exploration',
          targetValue: 1,
          currentValue: 0,
        ));
        break;
    }
    
    // Add difficulty-based objectives
    if (difficulty == QuestDifficulty.hard || difficulty == QuestDifficulty.expert) {
      objectives.add(QuestObjective(
        description: 'Take a photo at ${location.name}',
        type: 'photo_evidence',
        targetValue: 1,
        currentValue: 0,
      ));
    }
    
    if (difficulty == QuestDifficulty.expert || difficulty == QuestDifficulty.legendary) {
      objectives.add(QuestObjective(
        description: 'Share your experience at ${location.name}',
        type: 'social_sharing',
        targetValue: 1,
        currentValue: 0,
      ));
    }
    
    return objectives;
  }

  // Helper methods
  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }

  String _getDifficultyContext(QuestDifficulty difficulty) {
    switch (difficulty) {
      case QuestDifficulty.easy:
        return 'This quest is perfect for those just beginning their adventure.';
      case QuestDifficulty.medium:
        return 'This quest will challenge your skills and expand your horizons.';
      case QuestDifficulty.hard:
        return 'This quest requires determination and skill. The rewards will be worth the effort.';
      case QuestDifficulty.expert:
        return 'Only experienced adventurers should attempt this quest. The challenges are great, but so are the rewards.';
      case QuestDifficulty.legendary:
        return 'This legendary quest is the ultimate test of skill and courage. Few have succeeded, but those who do become legends.';
    }
  }

  // Generate dynamic events based on context
  List<MapEvent> generateDynamicEvents(
    List<MapLocation> locations,
    WeatherData weather,
  ) {
    final events = <MapEvent>[];
    final timeOfDay = _getTimeOfDay();
    
    // Generate weather-based events
    if (weather.condition == WeatherCondition.rainy && locations.isNotEmpty) {
      events.add(MapEvent(
        name: 'Rainy Day Challenge',
        description: 'Complete quests in the rain for bonus rewards',
        location: locations.first,
        startTime: DateTime.now(),
        endTime: DateTime.now().add(Duration(hours: 24)),
        eventType: 'weather_challenge',
        maxParticipants: 50,
        participants: [],
        isActive: true,
      ));
    }
    
    // Generate time-based events
    if (timeOfDay == 'evening') {
      final pubLocation = locations.where((l) => l.type == LocationType.pub).firstOrNull;
      if (pubLocation != null) {
        events.add(MapEvent(
          name: 'Evening Social Gathering',
          description: 'Visit pubs and social locations for group bonuses',
          location: pubLocation,
          startTime: DateTime.now(),
          endTime: DateTime.now().add(Duration(hours: 6)),
          eventType: 'social_gathering',
          maxParticipants: 20,
          participants: [],
          isActive: true,
        ));
      }
    }
    
    return events;
  }
} 