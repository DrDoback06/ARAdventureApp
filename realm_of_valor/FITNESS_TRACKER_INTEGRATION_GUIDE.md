# 🏃‍♂️ Fitness Tracker Integration Guide

## Overview

The Realm of Valor app now includes comprehensive fitness tracker integration that provides **real-time stat boosts** based on your actual physical activity. Your heart rate, daily steps, workouts, and biometric data directly influence your character's in-game performance.

## 🎯 Key Features

### Real-Time Biometric Stat Boosts
- **Heart Rate Zones**: Different HR zones provide different stat bonuses
- **Active Workout Detection**: Get immediate boosts while exercising
- **Energy & Stress Levels**: Affect overall character performance
- **Daily Activity Milestones**: Step counts and calorie burns translate to character improvements

### Supported Fitness Trackers
- ✅ **Apple Watch** (HealthKit integration)
- ✅ **Wear OS** (Google Fit integration) 
- ✅ **Fitbit** (API integration)
- ✅ **Garmin** (Connect IQ integration)
- ✅ **Samsung Health** (Samsung Health SDK)
- ✅ **Polar** (AccessLink API)
- ✅ **Suunto** (Suunto App integration)
- ✅ **Generic Health Data** (fallback for any health app)

## 💪 How Fitness Affects Your Character

### Heart Rate Zone Bonuses

| Zone | HR Range | Real-Time Boosts | Duration |
|------|----------|------------------|----------|
| **Resting** | < 50% max HR | +5 Intelligence (focus boost) | 30 min |
| **Fat Burn** | 50-60% max HR | +8 Vitality (endurance) | 30 min |
| **Aerobic** | 60-70% max HR | +12 Vitality, +6 Dexterity | 30 min |
| **Anaerobic** | 70-85% max HR | +15 Strength, +20% combat damage | 30 min |
| **Peak** | 85%+ max HR | +20 Strength, +40% damage, +30% speed | 30 min |

### Daily Activity Rewards

| Activity | Requirement | Character Bonus | Duration |
|----------|-------------|-----------------|----------|
| **Daily Walker** | 10,000+ steps | +15 Vitality | 24 hours |
| **Active Day** | 5,000+ steps | +8 Vitality | 24 hours |
| **Calorie Crusher** | 500+ calories burned | +12 Strength | 24 hours |
| **Dedicated Athlete** | 30+ min workout | +10 All Stats | 24 hours |

### Weekly Consistency Bonuses

| Achievement | Requirement | Character Bonus | Duration |
|-------------|-------------|-----------------|----------|
| **Fitness Champion** | 5+ workout days | +20 All Stats | 7 days |
| **Consistent Athlete** | 3+ workout days | +15 Vitality | 7 days |
| **Calorie Dominator** | 2000+ weekly calories | +18 Strength | 7 days |

### Special Status Effects

| Status | Condition | Effect |
|--------|-----------|--------|
| **High Energy** | Energy > 80% | +10 Vitality, +15% XP gain |
| **Exhausted** | Energy < 30% | -5 Vitality, -10% XP gain |
| **Active Workout** | Currently exercising | +8 All Stats, +25% XP, +10% loot |

## 🔧 Setup Instructions

### 1. Enable Health Permissions

```dart
// iOS - Add to Info.plist
<key>NSHealthShareUsageDescription</key>
<string>This app uses health data to provide real-time character stat boosts based on your fitness activity.</string>
<key>NSHealthUpdateUsageDescription</key>
<string>This app writes workout data to track your adventure progress.</string>

// Android - Add to AndroidManifest.xml
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
<uses-permission android:name="android.permission.BODY_SENSORS" />
<uses-permission android:name="com.google.android.gms.permission.ACTIVITY_RECOGNITION" />
```

### 2. Platform-Specific Setup

#### Apple Watch / HealthKit
```swift
// iOS native code in AppDelegate.swift
import HealthKit

let healthStore = HKHealthStore()
let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!

func requestHealthAuthorization() {
    healthStore.requestAuthorization(toShare: [], read: [heartRateType]) { success, error in
        // Handle authorization result
    }
}
```

#### Wear OS / Google Fit
```kotlin
// Android native code
private val fitnessOptions = FitnessOptions.builder()
    .addDataType(DataType.TYPE_HEART_RATE_BPM, FitnessOptions.ACCESS_READ)
    .addDataType(DataType.TYPE_STEP_COUNT_DELTA, FitnessOptions.ACCESS_READ)
    .build()

GoogleSignIn.requestPermissions(this, REQUEST_CODE, account, fitnessOptions)
```

#### Fitbit API
```dart
// Add to pubspec.yaml dependencies
fitbit_connector: ^2.0.0

// Initialize Fitbit connection
final fitbitConnector = FitbitConnector(
  clientID: 'YOUR_FITBIT_CLIENT_ID',
  clientSecret: 'YOUR_FITBIT_CLIENT_SECRET',
  redirectUri: 'your-app://fitbit-auth',
  callbackUrlScheme: 'your-app',
);
```

### 3. Initialize in Your App

```dart
// In main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize fitness tracker service
  final fitnessService = FitnessTrackerService();
  await fitnessService.initialize(playerAge: 25); // Your age for HR calculations
  
  runApp(MyApp());
}
```

## 📱 UI Integration

### Compact Fitness Widget (Map Tab)
```dart
// Shows real-time heart rate and active boosts
FitnessTrackerWidget(
  showCompact: true,
  onTap: () => showFitnessTrackerDialog(),
)
```

### Full Fitness Dashboard
```dart
// Comprehensive dashboard with all metrics
FitnessTrackerDialog()
```

### Adventure Map Integration
The Adventure Map now shows:
- Real-time heart rate monitoring
- Current fitness zone and bonuses
- Active stat multipliers
- Workout detection and bonuses

## 🎮 Gameplay Integration

### Character Stat Boosts
Your character's stats are dynamically modified based on real fitness data:

```dart
// Apply fitness boosts to character
final enhancedCharacter = fitnessService.applyFitnessBoosts(baseCharacter);

// Character now has boosted stats for combat, exploration, etc.
print('Strength: ${enhancedCharacter.strength}'); // Base + fitness bonus
print('Vitality: ${enhancedCharacter.vitality}'); // Base + fitness bonus
```

### Adventure Mode Bonuses
- **Active Workout**: +40% combat damage, +30% movement speed
- **High Heart Rate**: Increased encounter rewards
- **Daily Step Goals**: Unlock special adventure routes
- **Weekly Consistency**: Access to premium adventure content

### Real-Time Feedback
- Heart rate changes affect combat performance immediately
- Calorie burn rate influences loot drop chances
- Stress levels affect puzzle-solving abilities
- Energy levels modify experience gain rates

## 🔬 Technical Details

### Data Synchronization
- **Real-time updates**: Every 30 seconds during active use
- **Background sync**: Hourly when app is backgrounded
- **Manual sync**: Pull-to-refresh in fitness dashboard
- **Offline support**: Cached data used when connectivity is poor

### Privacy & Security
- All health data remains on device
- Only aggregated stats sent to game servers
- Full GDPR and HIPAA compliance
- User can disable fitness integration at any time

### Performance Optimization
- Efficient battery usage with smart polling intervals
- Caching system reduces API calls
- Background processing for minimal UI impact
- Graceful degradation when sensors unavailable

## 🚀 Advanced Features

### Custom Workouts
Create adventure-themed workouts:
- **Dragon Slayer Routine**: High-intensity interval training
- **Elven Archer Training**: Focus on flexibility and precision
- **Dwarf Miner Strength**: Heavy resistance training
- **Mage Meditation**: Yoga and mindfulness exercises

### Social Challenges
- Compare fitness stats with guild members
- Group adventure challenges requiring team step goals
- Leaderboards for weekly activity achievements
- Cooperative raid battles requiring real-world coordination

### Seasonal Events
- **Summer Solstice**: Double XP for outdoor activities
- **Winter Challenge**: Bonus rewards for cold-weather workouts
- **Spring Cleaning**: Special rewards for reaching step milestones
- **Autumn Harvest**: Calorie-burning challenges with feast rewards

## 🔧 Troubleshooting

### Common Issues

**Fitness data not syncing:**
1. Check health app permissions
2. Ensure fitness tracker is connected
3. Try manual sync from settings
4. Restart app if needed

**Heart rate not detected:**
1. Verify watch/tracker is properly worn
2. Check Bluetooth connection
3. Enable real-time heart rate in tracker settings
4. Ensure fitness app has background permissions

**Stat boosts not applying:**
1. Force close and reopen character screen
2. Check that fitness service is properly initialized
3. Verify active boosts in fitness dashboard
4. Ensure character has completed tutorial

### Performance Tips
- Close other fitness apps to avoid conflicts
- Keep fitness tracker charged for consistent data
- Enable "Always On" heart rate monitoring
- Use Wi-Fi when possible for faster sync

## 📈 Analytics & Insights

The fitness integration provides detailed analytics:
- Weekly fitness trends and character performance correlation
- Optimal workout times for maximum stat bonuses
- Personalized recommendations for character development
- Achievement progress tracking across fitness and game metrics

## 🎯 Future Roadmap

### Planned Features
- **Sleep tracking**: Rest quality affects mana regeneration
- **Nutrition logging**: Food choices influence character buffs
- **Recovery metrics**: HRV data affects skill cooldowns
- **Outdoor adventures**: GPS-based real-world quests
- **AR fitness**: Camera-based workout form analysis
- **Voice coaching**: In-game trainer provides real workout guidance

---

## 💡 Tips for Maximum Benefits

1. **Wear your fitness tracker consistently** for best stat tracking
2. **Set realistic daily goals** to maintain consistent bonuses
3. **Mix workout types** to develop different character stats
4. **Use Adventure Mode during workouts** for maximum immersion
5. **Join fitness-focused guilds** for motivation and team challenges
6. **Track progress in both fitness and character development**

The fitness tracker integration transforms Realm of Valor from just a game into a comprehensive lifestyle companion that rewards your real-world health and fitness efforts with meaningful in-game progression! 