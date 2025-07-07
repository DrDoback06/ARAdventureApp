# 🚀 Realm of Valor Adventure Mode Setup Guide

This comprehensive guide will walk you through setting up all the adventure mode enhancements to ensure everything works correctly.

---

## 📋 Prerequisites

### System Requirements
- Flutter SDK 3.16.0 or higher
- Dart SDK 3.2.0 or higher
- Android Studio / Xcode for mobile development
- Git for version control

### Development Environment
```bash
# Verify Flutter installation
flutter doctor

# Ensure you're in the project directory
cd realm_of_valor
```

---

## 🔧 Step 1: Install Dependencies

### Update pubspec.yaml
Ensure all required dependencies are in your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Existing dependencies (keep these)
  cupertino_icons: ^1.0.2
  provider: ^6.1.1
  shared_preferences: ^2.2.2
  http: ^1.1.0
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
  permission_handler: ^11.0.1
  health: ^10.1.0
  
  # New adventure mode dependencies
  background_location: ^0.13.0
  geocoding: ^3.0.0
  google_polyline_algorithm: ^3.1.0
  weather: ^3.1.1
  oauth2: ^2.0.2
  dio: ^5.4.3+1
  location: ^6.0.2
  google_maps_cluster_manager: ^3.0.0+1
  gpx: ^2.2.1
  
  # AR dependencies
  arcore_flutter_plugin: ^0.0.9
  arkit_plugin: ^0.11.0
  camera: ^0.10.5+5
  
  # Additional utilities
  intl: ^0.18.1
  uuid: ^4.1.0
  path_provider: ^2.1.1
  sqflite: ^2.3.0
  image_picker: ^1.0.4
  url_launcher: ^6.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

### Install Dependencies
```bash
flutter pub get
```

---

## 🔑 Step 2: API Keys and Configurations

### 2.1 Google Maps API Setup

1. **Get Google Maps API Key**:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project or select existing one
   - Enable these APIs:
     - Maps SDK for Android
     - Maps SDK for iOS
     - Places API
     - Geocoding API
     - Directions API

2. **Configure Android**:
   Create/update `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <manifest xmlns:android="http://schemas.android.com/apk/res/android">
       <application
           android:label="realm_of_valor"
           android:name="${applicationName}"
           android:icon="@mipmap/ic_launcher">
           
           <!-- Add Google Maps API Key -->
           <meta-data android:name="com.google.android.geo.API_KEY"
                      android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
           
           <activity
               android:name=".MainActivity"
               android:exported="true"
               android:launchMode="singleTop"
               android:theme="@style/LaunchTheme"
               android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
               android:hardwareAccelerated="true"
               android:windowSoftInputMode="adjustResize">
               <meta-data
                   android:name="io.flutter.embedding.android.NormalTheme"
                   android:resource="@style/NormalTheme" />
               <intent-filter android:autoVerify="true">
                   <action android:name="android.intent.action.MAIN"/>
                   <category android:name="android.intent.category.LAUNCHER"/>
               </intent-filter>
           </activity>
           <meta-data
               android:name="flutterEmbedding"
               android:value="2" />
       </application>
       
       <!-- Add required permissions -->
       <uses-permission android:name="android.permission.INTERNET" />
       <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
       <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
       <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
       <uses-permission android:name="android.permission.CAMERA" />
       <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
       <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
       <uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
   </manifest>
   ```

3. **Configure iOS**:
   Update `ios/Runner/Info.plist`:
   ```xml
   <dict>
       <!-- Existing keys -->
       
       <!-- Add location permissions -->
       <key>NSLocationWhenInUseUsageDescription</key>
       <string>This app needs location access to provide adventure mode features.</string>
       <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
       <string>This app needs background location access for adventure tracking.</string>
       <key>NSLocationAlwaysUsageDescription</key>
       <string>This app needs background location access for adventure tracking.</string>
       
       <!-- Camera permissions for AR -->
       <key>NSCameraUsageDescription</key>
       <string>This app needs camera access for AR encounters.</string>
       
       <!-- Motion permissions -->
       <key>NSMotionUsageDescription</key>
       <string>This app uses motion data for fitness tracking.</string>
       
       <!-- Health permissions -->
       <key>NSHealthShareUsageDescription</key>
       <string>This app integrates with HealthKit for fitness tracking.</string>
       <key>NSHealthUpdateUsageDescription</key>
       <string>This app integrates with HealthKit for fitness tracking.</string>
   </dict>
   ```

   Add to `ios/Runner/AppDelegate.swift`:
   ```swift
   import UIKit
   import Flutter
   import GoogleMaps

   @UIApplicationMain
   @objc class AppDelegate: FlutterAppDelegate {
     override func application(
       _ application: UIApplication,
       didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
     ) -> Bool {
       GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
       GeneratedPluginRegistrant.register(with: self)
       return super.application(application, didFinishLaunchingWithOptions: launchOptions)
     }
   }
   ```

### 2.2 Weather API Setup

1. **Met Office API (UK)**:
   - Register at [Met Office DataHub](https://datahub.metoffice.gov.uk/)
   - Get your API key
   - Note: Free tier has rate limits

2. **OpenWeatherMap API (Global Fallback)**:
   - Register at [OpenWeatherMap](https://openweathermap.org/api)
   - Get your free API key
   - Upgrade to paid plan for production use

### 2.3 Strava API Setup

1. **Create Strava App**:
   - Go to [Strava Developers](https://developers.strava.com/)
   - Create a new application
   - Note down:
     - Client ID
     - Client Secret
     - Authorization Callback Domain

2. **Configure OAuth Redirect**:
   - Set callback URL to: `your-app://strava-auth`
   - Add to Android `AndroidManifest.xml`:
   ```xml
   <activity android:name="com.linusu.flutter_web_auth.CallbackActivity" android:exported="true">
       <intent-filter android:autoVerify="true">
           <action android:name="android.intent.action.VIEW" />
           <category android:name="android.intent.category.DEFAULT" />
           <category android:name="android.intent.category.BROWSABLE" />
           <data android:scheme="your-app" />
       </intent-filter>
   </activity>
   ```

---

## 🏗️ Step 3: Environment Configuration

### Create Environment Config File
Create `lib/config/environment_config.dart`:

```dart
class EnvironmentConfig {
  // Google Maps
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
  
  // Weather APIs
  static const String metOfficeApiKey = 'YOUR_MET_OFFICE_API_KEY';
  static const String openWeatherMapApiKey = 'YOUR_OPENWEATHERMAP_API_KEY';
  
  // Strava OAuth
  static const String stravaClientId = 'YOUR_STRAVA_CLIENT_ID';
  static const String stravaClientSecret = 'YOUR_STRAVA_CLIENT_SECRET';
  static const String stravaRedirectUri = 'your-app://strava-auth';
  
  // App Configuration
  static const String appName = 'Realm of Valor';
  static const String appVersion = '1.0.0';
  
  // Server endpoints (replace with your backend URLs)
  static const String baseApiUrl = 'https://your-api-server.com';
  static const String websocketUrl = 'wss://your-websocket-server.com';
  
  // Feature flags
  static const bool enableAR = true;
  static const bool enableBackgroundLocation = true;
  static const bool enablePushNotifications = true;
  
  // Game balance
  static const double encounterBaseRadius = 100.0; // meters
  static const int maxDailyEncounters = 50;
  static const int streakMaxDays = 365;
}
```

### Add to .gitignore
```gitignore
# Environment configuration
lib/config/environment_config.dart

# API keys
*.env
.env.*

# Build files
/build/
/android/app/build/
/ios/build/
```

### Create Template File
Create `lib/config/environment_config.template.dart`:
```dart
// Copy this file to environment_config.dart and fill in your API keys
class EnvironmentConfig {
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY_HERE';
  static const String metOfficeApiKey = 'YOUR_MET_OFFICE_API_KEY_HERE';
  static const String openWeatherMapApiKey = 'YOUR_OPENWEATHERMAP_API_KEY_HERE';
  static const String stravaClientId = 'YOUR_STRAVA_CLIENT_ID_HERE';
  static const String stravaClientSecret = 'YOUR_STRAVA_CLIENT_SECRET_HERE';
  static const String stravaRedirectUri = 'your-app://strava-auth';
  // ... rest of configuration
}
```

---

## 🎯 Step 4: Initialize Core Services

### Update Main App File
Update `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

// Import all services
import 'services/adventure_progression_service.dart';
import 'services/social_adventure_service.dart';
import 'services/seasonal_event_service.dart';
import 'services/achievement_service.dart';
import 'services/character_customization_service.dart';
import 'services/adventure_journal_service.dart';
import 'services/dynamic_difficulty_service.dart';
import 'services/ar_encounter_service.dart';
import 'services/weather_service.dart';
import 'services/strava_service.dart';
import 'services/enhanced_location_service.dart';

// Import screens
import 'screens/adventure_map_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Request permissions early
  await requestPermissions();
  
  runApp(MyApp());
}

Future<void> requestPermissions() async {
  await [
    Permission.location,
    Permission.locationWhenInUse,
    Permission.locationAlways,
    Permission.camera,
    Permission.storage,
    Permission.activityRecognition,
  ].request();
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core services
        ChangeNotifierProvider(create: (_) => AdventureProgressionService()),
        ChangeNotifierProvider(create: (_) => SocialAdventureService()),
        ChangeNotifierProvider(create: (_) => SeasonalEventService()),
        ChangeNotifierProvider(create: (_) => AchievementService()),
        ChangeNotifierProvider(create: (_) => CharacterCustomizationService()),
        ChangeNotifierProvider(create: (_) => AdventureJournalService()),
        ChangeNotifierProvider(create: (_) => DynamicDifficultyService()),
        ChangeNotifierProvider(create: (_) => AREncounterService()),
        
        // Utility services
        Provider(create: (_) => WeatherService()),
        Provider(create: (_) => StravaService()),
        Provider(create: (_) => EnhancedLocationService()),
      ],
      child: MaterialApp(
        title: 'Realm of Valor',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: HomeScreen(),
        routes: {
          '/adventure-map': (context) => AdventureMapScreen(),
        },
      ),
    );
  }
}
```

---

## 📱 Step 5: Database Setup

### Create Database Helper
Create `lib/database/database_helper.dart`:

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'realm_of_valor.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Adventure progression
    await db.execute('''
      CREATE TABLE adventure_progress(
        id INTEGER PRIMARY KEY,
        user_id TEXT,
        adventure_xp INTEGER DEFAULT 0,
        adventure_rank TEXT DEFAULT 'Novice',
        check_in_streak INTEGER DEFAULT 0,
        last_check_in TEXT,
        titles_unlocked TEXT
      )
    ''');

    // Achievements
    await db.execute('''
      CREATE TABLE achievements(
        id TEXT PRIMARY KEY,
        category TEXT,
        title TEXT,
        description TEXT,
        rarity TEXT,
        is_hidden INTEGER DEFAULT 0,
        progress INTEGER DEFAULT 0,
        target INTEGER,
        unlocked_at TEXT,
        is_unlocked INTEGER DEFAULT 0
      )
    ''');

    // Character customization
    await db.execute('''
      CREATE TABLE customization_items(
        id TEXT PRIMARY KEY,
        category TEXT,
        name TEXT,
        description TEXT,
        rarity TEXT,
        unlock_requirement TEXT,
        is_unlocked INTEGER DEFAULT 0,
        is_equipped INTEGER DEFAULT 0,
        unlock_date TEXT
      )
    ''');

    // Adventure journal
    await db.execute('''
      CREATE TABLE journal_entries(
        id TEXT PRIMARY KEY,
        date TEXT,
        type TEXT,
        title TEXT,
        description TEXT,
        mood TEXT,
        location_lat REAL,
        location_lng REAL,
        weather TEXT,
        photos TEXT,
        is_favorite INTEGER DEFAULT 0
      )
    ''');

    // Social features
    await db.execute('''
      CREATE TABLE social_data(
        id INTEGER PRIMARY KEY,
        user_id TEXT,
        friend_ids TEXT,
        guild_id TEXT,
        challenges_sent TEXT,
        challenges_received TEXT,
        leaderboard_scores TEXT
      )
    ''');
  }
}
```

---

## 🧪 Step 6: Testing Setup

### Create Test Configuration
Create `test/test_config.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestConfig {
  static Future<void> setupTests() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Mock shared preferences
    SharedPreferences.setMockInitialValues({});
    
    // Set test environment variables
    const Map<String, String> testEnv = {
      'GOOGLE_MAPS_API_KEY': 'test_key',
      'MET_OFFICE_API_KEY': 'test_key',
      'OPENWEATHERMAP_API_KEY': 'test_key',
      'STRAVA_CLIENT_ID': 'test_client_id',
      'STRAVA_CLIENT_SECRET': 'test_client_secret',
    };
  }
}
```

### Run Tests
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/services/adventure_progression_service_test.dart

# Run tests with coverage
flutter test --coverage
```

---

## 🚀 Step 7: Build and Deploy

### Debug Build
```bash
# Android
flutter run

# iOS
flutter run --simulator

# Chrome (for development)
flutter run -d chrome
```

### Release Build
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

---

## 🔧 Step 8: Troubleshooting Common Issues

### Location Permissions
If location isn't working:
```dart
// Check permission status
final permission = await Permission.location.status;
if (permission.isDenied) {
  await Permission.location.request();
}

// For background location (Android)
if (await Permission.locationAlways.isDenied) {
  await Permission.locationAlways.request();
}
```

### Google Maps Issues
```bash
# Clean build
flutter clean
flutter pub get

# Check API key in both Android and iOS configurations
# Ensure all required APIs are enabled in Google Cloud Console
```

### AR Issues
```dart
// Check AR availability
final isARAvailable = await ARCore.checkAvailability();
if (!isARAvailable) {
  // Show fallback UI
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('AR Not Available'),
      content: Text('Your device doesn\'t support AR features.'),
    ),
  );
}
```

### API Rate Limiting
```dart
// Implement exponential backoff
Future<T> retryWithBackoff<T>(Future<T> Function() operation) async {
  int attempts = 0;
  while (attempts < 3) {
    try {
      return await operation();
    } catch (e) {
      attempts++;
      if (attempts >= 3) rethrow;
      await Future.delayed(Duration(seconds: pow(2, attempts).toInt()));
    }
  }
  throw Exception('Max retries exceeded');
}
```

---

## 📋 Step 9: Verification Checklist

### ✅ Basic Setup
- [ ] All dependencies installed successfully
- [ ] API keys configured in environment file
- [ ] Permissions added to Android and iOS manifests
- [ ] App builds without errors

### ✅ Core Features
- [ ] Maps display correctly with current location
- [ ] Weather data loads and displays
- [ ] Location tracking works in background
- [ ] Database initializes and stores data
- [ ] Services communicate properly

### ✅ Adventure Features
- [ ] Adventure progression tracking works
- [ ] Achievements unlock and display
- [ ] Character customization items appear
- [ ] Journal entries save correctly
- [ ] Social features (if testing with multiple users)

### ✅ Advanced Features
- [ ] AR encounters work on supported devices
- [ ] Strava integration (if configured)
- [ ] Seasonal events display
- [ ] Dynamic difficulty adapts to user

### ✅ Performance
- [ ] App launches quickly
- [ ] No memory leaks during extended use
- [ ] Background location doesn't drain battery excessively
- [ ] UI remains responsive during data operations

---

## 🎯 Step 10: Production Deployment

### Pre-Production Checklist
- [ ] All API keys are production keys (not test/development)
- [ ] Rate limiting implemented for all external APIs
- [ ] Error handling and logging configured
- [ ] Analytics tracking set up
- [ ] Push notifications configured (if using)
- [ ] App store metadata and screenshots prepared

### Monitoring Setup
```dart
// Add crash reporting
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  
  runApp(MyApp());
}
```

### Performance Monitoring
```dart
// Add performance monitoring
import 'package:firebase_performance/firebase_performance.dart';

class PerformanceMonitor {
  static Future<T> trackOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final trace = FirebasePerformance.instance.newTrace(operationName);
    await trace.start();
    
    try {
      final result = await operation();
      trace.setMetric('success', 1);
      return result;
    } catch (e) {
      trace.setMetric('error', 1);
      rethrow;
    } finally {
      await trace.stop();
    }
  }
}
```

---

## 🎉 Congratulations!

Your Realm of Valor adventure mode is now fully set up! The app should provide:

- **Immersive location-based gameplay**
- **Comprehensive progression systems**
- **Social features and competitions**
- **Seasonal content and events**
- **AR encounters on supported devices**
- **Fitness tracking integration**
- **Weather-reactive gameplay**

For ongoing maintenance, monitor API usage, user feedback, and performance metrics to continuously improve the adventure experience.

Remember to regularly update dependencies and API keys, and consider user feedback for future enhancements!