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

// Agent System
import 'services/agents/integration_orchestrator_agent.dart';
import 'services/agents/character_management_agent.dart';
import 'services/agents/fitness_tracking_agent.dart';
import 'services/agents/battle_system_agent.dart';
import 'services/agents/data_persistence_agent.dart';
import 'services/agents/achievement_agent.dart';
import 'services/agents/card_system_agent.dart';
import 'services/agents/adventure_quest_agent.dart';
import 'services/agents/location_services_agent.dart';
import 'services/agents/ui_ux_agent.dart';
import 'services/agents/audio_agent.dart';
import 'services/agents/social_features_agent.dart';
import 'services/agents/ar_rendering_agent.dart';
import 'services/agents/analytics_agent.dart';
import 'services/agents/weather_integration_agent.dart';
import 'services/agents/ai_companion_agent.dart';
import 'services/agents/performance_optimization_agent.dart';

// Providers
import 'providers/battle_controller.dart';
import 'providers/character_provider.dart';
import 'providers/activity_provider.dart';

// Screens
import 'screens/home_screen.dart';

// Constants
import 'constants/theme.dart';

// Models
import 'models/battle_model.dart' as battle_models;

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize SharedPreferences with error handling
    final prefs = await SharedPreferences.getInstance();
    
    // Initialize the agent system
    await _initializeAgentSystem(prefs);
    
    // Add error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
    };
    
    runApp(RealmOfValorApp(prefs: prefs));
  } catch (e) {
    print('Failed to initialize app: $e');
    // Fallback to simple app if initialization fails
    runApp(const ErrorApp());
  }
}

/// Initialize the agent system
Future<void> _initializeAgentSystem(SharedPreferences prefs) async {
  try {
    // Initialize the Integration Orchestrator
    await AgentOrchestrator.initialize();
    
    // Initialize and register core agents
    final characterAgent = CharacterManagementAgent();
    final fitnessAgent = FitnessTrackingAgent();
    final battleAgent = BattleSystemAgent();
    final dataAgent = DataPersistenceAgent(prefs: prefs);
    final achievementAgent = AchievementAgent();
    final cardAgent = CardSystemAgent(prefs: prefs);
    final adventureAgent = AdventureQuestAgent(prefs: prefs);
    final locationAgent = LocationServicesAgent(prefs: prefs);
    final uiAgent = UIUXAgent(prefs: prefs);
    final audioAgent = AudioAgent(prefs: prefs);
    final socialAgent = SocialFeaturesAgent(prefs: prefs);
    final arAgent = ARRenderingAgent(prefs: prefs);
    final analyticsAgent = AnalyticsAgent(prefs: prefs);
    final weatherAgent = WeatherIntegrationAgent(prefs: prefs);
    final aiCompanionAgent = AICompanionAgent(prefs: prefs);
    final performanceAgent = PerformanceOptimizationAgent(prefs: prefs);
    
    await AgentOrchestrator.instance.registerAgent(characterAgent);
    await AgentOrchestrator.instance.registerAgent(fitnessAgent);
    await AgentOrchestrator.instance.registerAgent(battleAgent);
    await AgentOrchestrator.instance.registerAgent(dataAgent);
    await AgentOrchestrator.instance.registerAgent(achievementAgent);
    await AgentOrchestrator.instance.registerAgent(cardAgent);
    await AgentOrchestrator.instance.registerAgent(adventureAgent);
    await AgentOrchestrator.instance.registerAgent(locationAgent);
    await AgentOrchestrator.instance.registerAgent(uiAgent);
    await AgentOrchestrator.instance.registerAgent(audioAgent);
    await AgentOrchestrator.instance.registerAgent(socialAgent);
    await AgentOrchestrator.instance.registerAgent(arAgent);
    await AgentOrchestrator.instance.registerAgent(analyticsAgent);
    await AgentOrchestrator.instance.registerAgent(weatherAgent);
    await AgentOrchestrator.instance.registerAgent(aiCompanionAgent);
    await AgentOrchestrator.instance.registerAgent(performanceAgent);
    
    print('Agent system initialized successfully');
  } catch (e) {
    print('Failed to initialize agent system: $e');
    // Continue without agent system for now
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Realm of Valor - Error',
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('App failed to initialize'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => main(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RealmOfValorApp extends StatelessWidget {
  final SharedPreferences prefs;
  
  const RealmOfValorApp({super.key, required this.prefs});

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
            battle_models.Battle(
              name: 'Default Battle',
              type: battle_models.BattleType.pve,
              status: battle_models.BattleStatus.waiting,
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