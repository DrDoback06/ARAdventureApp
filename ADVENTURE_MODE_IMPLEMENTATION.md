# Adventure Mode Implementation Guide

## Overview

This document describes the comprehensive Adventure Mode implementation for Realm of Valor, featuring geolocation-based gameplay similar to Pokémon Go, integrated with fitness tracking, weather data, and outdoor exploration features.

## Core Features Implemented

### 🗺️ Live Map with Real-time Location Tracking
- **Google Maps Integration**: Full map view showing player location, POIs, quests, and spawns
- **Background Location Tracking**: Continuous location monitoring for adventure events
- **Geofencing**: Automatic trigger zones for quests, POIs, and encounters
- **Real-time Updates**: Live map markers and circles showing active content

### 🌤️ Weather Integration
- **Met Office API**: UK-specific weather data integration
- **OpenWeatherMap Fallback**: International weather coverage
- **Weather-based Gameplay**: 
  - Dynamic spawn modifiers based on weather conditions
  - Weather-specific quests (Storm Chaser, Solar Warrior, etc.)
  - Adventure recommendations based on conditions
- **Beautiful Weather Widget**: Gradient backgrounds and adventure-themed recommendations

### 🏃 Enhanced Fitness Tracking
- **Strava Integration**: 
  - OAuth authentication with Strava API
  - Import activities and convert to game rewards
  - Strava segments become in-game quests
  - Route data for adventure planning
- **Health App Integration**: Steps, heart rate, calories, distance tracking
- **Fitness Goals**: Create and track custom fitness objectives
- **Activity Rewards**: XP, cards, and stat boosts for real-world activities

### 🎯 Dynamic Quest System
- **Location-based Quests**: Quests tied to specific geographic locations
- **Weather-dependent Quests**: Activities that change based on current weather
- **Fitness Quests**: Challenges requiring physical activity completion
- **Epic Quest Chains**: Multi-objective adventures with rich storytelling
- **Daily/Weekly Quests**: Regularly refreshed content

### 🗺️ Points of Interest (POI) System
- **Automatic POI Generation**: Parks, gyms, restaurants, monuments, landmarks
- **POI Discovery**: Rewards for visiting new locations
- **Location Types**: Different categories with unique encounter types
- **Popularity Tracking**: Dynamic popularity system for locations

### ⚔️ Random Encounter System
- **Dynamic Spawns**: Weather and location-influenced creature spawns
- **Encounter Types**: Battles, treasures, merchants, mysteries
- **Beautiful Encounter Dialogs**: Animated popups with reward previews
- **Contextual Events**: Different encounters based on location and conditions

### 🛤️ Adventure Route Planning
- **Route Generation**: AI-generated walking/hiking routes based on location
- **Difficulty Levels**: Easy, Medium, Hard routes with appropriate challenges
- **Route Visualization**: Map view with waypoints and elevation data
- **Activity Integration**: Routes optimized for different activity types
- **Trail Information**: Highlights, distance, duration, elevation gain

## Technical Architecture

### Services Layer

#### `WeatherService`
```dart
- getCurrentWeather(): Get weather for current location
- getWeatherForLocation(): Weather for specific coordinates  
- getWeatherSpawnModifiers(): Dynamic creature spawn rates
- getWeatherBasedQuestSuggestions(): Weather-specific quest ideas
```

#### `StravaService` 
```dart
- authenticate(): OAuth flow with Strava
- getRecentActivities(): Import recent Strava activities
- exploreSegments(): Find Strava segments near location
- createQuestsFromSegments(): Convert segments to game quests
- syncActivitiesWithGame(): Award XP/rewards for activities
```

#### `EnhancedLocationService`
```dart
- startTracking(): Begin location monitoring
- createGeofencesForPOIs(): Set up location triggers
- getNearbyPOIs(): Find points of interest nearby
- generateAdventureRoutes(): Create suggested routes
- getAddressFromLocation(): Reverse geocoding
```

### UI Components

#### `AdventureMapScreen`
- Main map interface with Google Maps
- Real-time location and POI markers  
- Weather overlay display
- Quest and encounter management
- Route planning integration

#### `WeatherWidget`
- Beautiful gradient weather display
- Adventure-themed weather recommendations
- Current conditions and forecast
- Activity suitability indicators

#### `QuestOverlayWidget`
- Immersive quest presentation dialogs
- Objective tracking and progress
- Reward previews and difficulty indicators
- Accept/decline quest functionality

#### `EncounterDialog`
- Animated encounter presentations
- Dynamic encounter types and rewards
- Beautiful visual effects and theming
- Context-sensitive action buttons

#### `RoutePlannerWidget`
- Tabbed interface for route browsing
- Map visualization of routes
- Route statistics and highlights
- Difficulty-based color coding

## Adventure Mode Features

### 🎮 Gameplay Mechanics

1. **Location-based Exploration**
   - Visit real-world locations to discover POIs
   - Unlock quests by entering specific geographic areas
   - Find hidden treasures at landmark locations
   - Complete fitness challenges along walking routes

2. **Weather-Enhanced Gameplay**
   - Different creatures spawn in different weather conditions
   - Rain increases water-type creature spawns
   - Sunny weather boosts rare encounter rates
   - Storm conditions enable special weather quests

3. **Fitness Integration**
   - Steps, calories, and distance automatically tracked
   - Strava activities imported for bonus rewards
   - Real hiking trails become adventure routes
   - Mountain climbing suggestions with elevation data

4. **Dynamic Content Generation**
   - Quests generated based on nearby POIs
   - Routes created using real walking paths
   - Encounters influenced by location and weather
   - Seasonal events tied to real calendar dates

### 🗺️ Map Features

1. **Interactive Markers**
   - Player location with blue marker
   - POI markers color-coded by type (parks=green, gyms=orange, etc.)
   - Quest markers with type-specific icons
   - Spawn markers for active creatures/events

2. **Visual Indicators**
   - Radius circles around POIs and quests
   - Route polylines for suggested paths
   - Weather-influenced visual theming
   - Animated markers for active content

3. **Real-time Updates**
   - Location tracking every 10 seconds
   - Background location updates when app backgrounded
   - Automatic geofence triggers
   - Dynamic content refreshing

## Setup Instructions

### 1. API Keys Required

Add these to your environment/config:

```dart
// Weather Service
static const String _metOfficeApiKey = 'YOUR_MET_OFFICE_API_KEY';
static const String _openWeatherApiKey = 'YOUR_OPENWEATHER_API_KEY';

// Strava Integration  
static const String _clientId = 'YOUR_STRAVA_CLIENT_ID';
static const String _clientSecret = 'YOUR_STRAVA_CLIENT_SECRET';

// Google Maps (already configured)
```

### 2. Permissions Setup

#### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
<uses-permission android:name="android.permission.INTERNET" />
```

#### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access for adventure mode gameplay</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs background location for adventure tracking</string>
<key>NSMotionUsageDescription</key>
<string>This app uses motion data for fitness tracking</string>
```

### 3. Integration with Existing Game

Add to your main navigation:

```dart
FloatingActionButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdventureMapScreen(),
      ),
    );
  },
  child: const Icon(Icons.explore),
)
```

## Usage Examples

### Starting Adventure Mode
```dart
// Initialize and start adventure mode
final locationService = EnhancedLocationService();
await locationService.initialize();
await locationService.startTracking(enableBackground: true);

// Navigate to adventure map
Navigator.push(context, MaterialPageRoute(
  builder: (context) => const AdventureMapScreen(),
));
```

### Creating Custom Quests
```dart
final customQuest = Quest(
  title: 'Local Explorer',
  description: 'Visit 3 parks in your neighborhood',
  type: QuestType.exploration,
  level: 2,
  location: currentLocation,
  radius: 2000,
  objectives: [
    QuestObjective(
      title: 'Visit Parks',
      description: 'Find and visit 3 different parks',
      type: 'location_visit',
      requirements: {'location_type': 'park', 'count': 3},
    ),
  ],
);
```

### Weather-based Encounters
```dart
// Weather service automatically modifies spawns
final weather = await WeatherService().getCurrentWeather();
final modifiers = weatherService.getWeatherSpawnModifiers(weather);

// Rain increases water creature spawns by 2x
if (modifiers['water_creatures'] == 2.0) {
  // Spawn more water-type encounters
}
```

## Future Enhancements

### 🎯 Planned Features
- **AR Integration**: Camera overlay for creature encounters
- **Social Features**: Share routes and compete with friends  
- **Advanced Route Planning**: Multi-day hiking expeditions
- **Local Event Integration**: Connect with real outdoor events
- **Trail Database**: Integration with AllTrails or similar services
- **Weather Alerts**: Severe weather notifications and safety features

### 🔧 Technical Improvements
- **Offline Map Support**: Cache map data for remote area usage
- **Battery Optimization**: More efficient background location tracking
- **Performance**: Optimize marker rendering for large datasets
- **Analytics**: Track player engagement and popular locations

## Dependencies Added

```yaml
dependencies:
  # Adventure Mode & Location Features
  background_location: ^0.13.0
  geocoding: ^3.0.0
  google_polyline_algorithm: ^3.1.0
  
  # Weather & Environment APIs
  weather: ^3.1.1
  
  # OAuth and API integrations (for Strava)
  oauth2: ^2.0.2
  dio: ^5.4.3+1
  
  # Enhanced location services
  location: ^6.0.2
  
  # Map clustering for POIs
  google_maps_cluster_manager: ^3.0.0+1
  
  # GPX file support for trails
  gpx: ^2.2.1
```

## Conclusion

This Adventure Mode implementation provides a comprehensive foundation for location-based gameplay, integrating real-world fitness activities with engaging game mechanics. The modular architecture allows for easy extension and customization while maintaining performance and user experience standards.

The system successfully combines:
- **Real-world exploration** with game rewards
- **Fitness tracking** with adventure progression  
- **Weather conditions** with dynamic gameplay
- **Beautiful UI** with practical functionality
- **Social features** with personal challenges

Players can now experience their local environment through the lens of an epic adventure, encouraging physical activity, exploration, and outdoor engagement while progressing in their favorite card-based RPG game.