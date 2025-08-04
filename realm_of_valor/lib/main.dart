import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Services
import 'services/audio_service.dart';
import 'services/fitness_tracker_service.dart';
import 'services/daily_quest_service.dart';
import 'services/achievement_service.dart';
import 'services/social_service.dart';
import 'services/analytics_service.dart';
import 'services/ai_battle_service.dart';
import 'services/advanced_battle_service.dart';
import 'services/character_progression_service.dart';
import 'services/qr_scanner_service.dart';
import 'services/character_service.dart';
import 'services/accessibility_service.dart';

// Providers
import 'providers/battle_controller.dart';
import 'providers/character_provider.dart';
import 'providers/activity_provider.dart';

// Screens
import 'screens/home_screen.dart';

// Constants
import 'constants/theme.dart';

// Models
import 'models/battle_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Add error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };
  
  runApp(const RealmOfValorApp());
}

class RealmOfValorApp extends StatelessWidget {
  const RealmOfValorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Character Provider
        ChangeNotifierProvider<CharacterProvider>(
          create: (context) => CharacterProvider(CharacterService()),
        ),
        
        // Activity Provider
        ChangeNotifierProvider<ActivityProvider>(
          create: (context) {
            final provider = ActivityProvider();
            provider.initialize();
            return provider;
          },
        ),
        
        // Battle Controller
        ChangeNotifierProvider<BattleController>(
          create: (context) => BattleController(
            Battle(
              id: 'default_battle',
              name: 'Default Battle',
              type: BattleType.pve,
              players: [],
              currentPlayerId: '',
              status: BattleStatus.waiting,
            ),
          ),
        ),
        
        // Services
        ChangeNotifierProvider<AudioService>.value(value: AudioService.instance),
        ChangeNotifierProvider<FitnessTrackerService>.value(value: FitnessTrackerService.instance),
        ChangeNotifierProvider<DailyQuestService>.value(value: DailyQuestService.instance),
        ChangeNotifierProvider<AchievementService>.value(value: AchievementService.instance),
        ChangeNotifierProvider<SocialService>.value(value: SocialService.instance),
        ChangeNotifierProvider<AnalyticsService>.value(value: AnalyticsService.instance),
        ChangeNotifierProvider<AIBattleService>.value(value: AIBattleService.instance),
        ChangeNotifierProvider<AdvancedBattleService>.value(value: AdvancedBattleService.instance),
        ChangeNotifierProvider<CharacterProgressionService>.value(value: CharacterProgressionService.instance),
        ChangeNotifierProvider<QRScannerService>.value(value: QRScannerService.instance),
      ],
      child: MaterialApp(
        title: 'Realm of Valor',
        theme: RealmOfValorTheme.darkTheme,
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          // Initialize accessibility service
          AccessibilityService().initialize(context);
          
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
            child: child!,
          );
        },
      ),
    );
  }
}