import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants/theme.dart';
import 'providers/character_provider.dart';
import 'services/character_service.dart';
import 'services/card_service.dart';
import 'services/enhanced_location_service.dart';
import 'services/weather_service.dart';
import 'services/strava_service.dart';
import 'services/physical_activity_service.dart';
import 'services/fitness_tracker_service.dart';
import 'services/location_verification_service.dart';
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
import 'screens/home_screen.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize SharedPreferences with error handling
    final prefs = await SharedPreferences.getInstance();
    
    // Initialize the agent system
    await _initializeAgentSystem();
    
    runApp(RealmOfValorApp(prefs: prefs));
  } catch (e) {
    // Fallback to simple app if initialization fails
    runApp(const ErrorApp());
  }
}

/// Initialize the agent system
Future<void> _initializeAgentSystem() async {
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
        // Services
        Provider<SharedPreferences>.value(value: prefs),
        Provider<CharacterService>(
          create: (context) {
            try {
              return CharacterService(prefs);
            } catch (e) {
              debugPrint('CharacterService initialization error: $e');
              rethrow;
            }
          },
        ),
        Provider<CardService>(
          create: (context) {
            try {
              return CardService(prefs);
            } catch (e) {
              debugPrint('CardService initialization error: $e');
              rethrow;
            }
          },
        ),
        
        // Adventure Mode Services
        Provider<EnhancedLocationService>(
          create: (context) {
            try {
              return EnhancedLocationService();
            } catch (e) {
              debugPrint('EnhancedLocationService initialization error: $e');
              rethrow;
            }
          },
        ),
        Provider<WeatherService>(
          create: (context) {
            try {
              return WeatherService();
            } catch (e) {
              debugPrint('WeatherService initialization error: $e');
              rethrow;
            }
          },
        ),
        Provider<StravaService>(
          create: (context) {
            try {
              return StravaService();
            } catch (e) {
              debugPrint('StravaService initialization error: $e');
              rethrow;
            }
          },
        ),
        Provider<PhysicalActivityService>(
          create: (context) {
            try {
              return PhysicalActivityService();
            } catch (e) {
              debugPrint('PhysicalActivityService initialization error: $e');
              rethrow;
            }
          },
        ),
        Provider<FitnessTrackerService>(
          create: (context) {
            try {
              return FitnessTrackerService();
            } catch (e) {
              debugPrint('FitnessTrackerService initialization error: $e');
              rethrow;
            }
          },
        ),
        Provider<LocationVerificationService>(
          create: (context) {
            try {
              return LocationVerificationService();
            } catch (e) {
              debugPrint('LocationVerificationService initialization error: $e');
              rethrow;
            }
          },
        ),
        
        // State Providers
        ChangeNotifierProvider<CharacterProvider>(
          create: (context) {
            try {
              return CharacterProvider(
                context.read<CharacterService>(),
              );
            } catch (e) {
              debugPrint('CharacterProvider initialization error: $e');
              rethrow;
            }
          },
        ),
      ],
      child: MaterialApp(
        title: 'Realm of Valor',
        debugShowCheckedModeBanner: false,
        theme: RealmOfValorTheme.darkTheme,
        home: const LoadingWrapper(),
      ),
    );
  }
}

class LoadingWrapper extends StatefulWidget {
  const LoadingWrapper({super.key});

  @override
  State<LoadingWrapper> createState() => _LoadingWrapperState();
}

class _LoadingWrapperState extends State<LoadingWrapper> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Add a small delay to ensure all providers are ready
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Just check if the context is still mounted and providers exist
      if (!mounted) return;
      
      // Simple validation without calling potentially problematic methods
      try {
        context.read<CharacterService>();
        context.read<CardService>();
        context.read<CharacterProvider>();
      } catch (e) {
        debugPrint('Provider access error: $e');
        // Continue anyway - providers might initialize later
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('App initialization error: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: RealmOfValorTheme.primaryDark,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: RealmOfValorTheme.accentGold,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.castle,
                  size: 40,
                  color: RealmOfValorTheme.primaryDark,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Realm of Valor',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: RealmOfValorTheme.accentGold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Loading your adventure...',
                style: TextStyle(
                  fontSize: 16,
                  color: RealmOfValorTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(RealmOfValorTheme.accentGold),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: RealmOfValorTheme.primaryDark,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: RealmOfValorTheme.healthRed,
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to load app',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: RealmOfValorTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(
                  fontSize: 14,
                  color: RealmOfValorTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _initializeApp();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return const HomeScreen();
  }
}