import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TutorialStep {
  welcome,
  characterCreation,
  skillTree,
  battleSystem,
  damageCalculator,
  dailyQuests,
  achievements,
  socialFeatures,
  fitnessTracking,
  locationExploration,
  cardSystem,
  qrScanner,
  settings,
  complete,
}

enum TutorialType {
  overlay,    // Overlay on existing UI
  modal,      // Modal dialog
  highlight,  // Highlight specific elements
  walkthrough, // Step-by-step walkthrough
}

class TutorialStepData {
  final TutorialStep step;
  final String title;
  final String description;
  final String? imagePath;
  final TutorialType type;
  final List<String>? actions;
  final bool isRequired;
  final Duration? estimatedTime;

  const TutorialStepData({
    required this.step,
    required this.title,
    required this.description,
    this.imagePath,
    required this.type,
    this.actions,
    this.isRequired = true,
    this.estimatedTime,
  });
}

class TutorialService extends ChangeNotifier {
  static TutorialService? _instance;
  static TutorialService get instance => _instance ??= TutorialService._();
  TutorialService._();

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // Tutorial state
  bool _isTutorialActive = false;
  TutorialStep _currentStep = TutorialStep.welcome;
  bool _isFirstTimeUser = true;
  Map<TutorialStep, bool> _completedSteps = {};
  Map<TutorialStep, DateTime> _stepCompletionTimes = {};

  // Tutorial data
  final Map<TutorialStep, TutorialStepData> _tutorialSteps = {
    TutorialStep.welcome: TutorialStepData(
      step: TutorialStep.welcome,
      title: "Welcome to Realm of Valor! 🎮",
      description: "Your ultimate character tracking and progression app. Let's get you started on your adventure!",
      type: TutorialType.modal,
      estimatedTime: Duration(seconds: 30),
    ),
    TutorialStep.characterCreation: TutorialStepData(
      step: TutorialStep.characterCreation,
      title: "Create Your Character 👤",
      description: "Choose from 8 unique character classes, each with their own skills and abilities. Your character will grow with you as you explore the real world!",
      type: TutorialType.walkthrough,
      actions: ["Tap 'Create Character'", "Choose your class", "Set your name", "Confirm creation"],
      estimatedTime: Duration(minutes: 2),
    ),
    TutorialStep.skillTree: TutorialStepData(
      step: TutorialStep.skillTree,
      title: "Master Your Skills 🌟",
      description: "Unlock powerful abilities in your skill tree. Each class has unique skill trees that enhance your character's capabilities in battle and exploration.",
      type: TutorialType.highlight,
      actions: ["Open Skill Tree", "Select a skill", "Spend skill points", "See your progress"],
      estimatedTime: Duration(minutes: 3),
    ),
    TutorialStep.battleSystem: TutorialStepData(
      step: TutorialStep.battleSystem,
      title: "Enter the Battleground ⚔️",
      description: "Test your skills in turn-based combat against AI opponents or other players. Use your cards strategically to emerge victorious!",
      type: TutorialType.walkthrough,
      actions: ["Open Battleground", "Select opponent", "Draw cards", "Play your hand", "Win the battle"],
      estimatedTime: Duration(minutes: 5),
    ),
    TutorialStep.damageCalculator: TutorialStepData(
      step: TutorialStep.damageCalculator,
      title: "Calculate Your Power 📊",
      description: "Perfect for physical card games! Calculate damage and defense with precision. Scan QR codes from physical cards or input manually.",
      type: TutorialType.overlay,
      actions: ["Open Calculator", "Select mode", "Input values", "Get results"],
      estimatedTime: Duration(minutes: 2),
    ),
    TutorialStep.dailyQuests: TutorialStepData(
      step: TutorialStep.dailyQuests,
      title: "Daily Challenges 🎯",
      description: "Complete daily quests to earn rewards and experience. New challenges appear every day to keep your adventure fresh!",
      type: TutorialType.highlight,
      actions: ["View daily quests", "Accept a quest", "Complete objective", "Claim rewards"],
      estimatedTime: Duration(minutes: 2),
    ),
    TutorialStep.achievements: TutorialStepData(
      step: TutorialStep.achievements,
      title: "Achieve Greatness 🏆",
      description: "Track your progress with achievements. From battle victories to real-world exploration, every achievement brings you closer to legendary status!",
      type: TutorialType.highlight,
      actions: ["Browse achievements", "Check progress", "Unlock achievements", "View rewards"],
      estimatedTime: Duration(minutes: 2),
    ),
    TutorialStep.socialFeatures: TutorialStepData(
      step: TutorialStep.socialFeatures,
      title: "Connect with Friends 👥",
      description: "Add friends, join guilds, and share your achievements. Battle together and compete on leaderboards!",
      type: TutorialType.overlay,
      actions: ["Add a friend", "Join a guild", "Share achievement", "View leaderboard"],
      estimatedTime: Duration(minutes: 3),
    ),
    TutorialStep.fitnessTracking: TutorialStepData(
      step: TutorialStep.fitnessTracking,
      title: "Real-World Integration 🏃‍♂️",
      description: "Connect your fitness tracker to earn XP from real-world activities. Every step, workout, and adventure contributes to your character's growth!",
      type: TutorialType.modal,
      actions: ["Connect fitness app", "Grant permissions", "Start tracking", "Earn XP"],
      estimatedTime: Duration(minutes: 3),
    ),
    TutorialStep.locationExploration: TutorialStepData(
      step: TutorialStep.locationExploration,
      title: "Explore the World 🌍",
      description: "Check in at locations to discover new areas and earn exploration rewards. Visit restaurants, gyms, parks, and historical sites!",
      type: TutorialType.overlay,
      actions: ["Enable location", "Find nearby POIs", "Check in", "Earn rewards"],
      estimatedTime: Duration(minutes: 2),
    ),
    TutorialStep.cardSystem: TutorialStepData(
      step: TutorialStep.cardSystem,
      title: "Master Your Cards 🃏",
      description: "Collect and manage your card collection. Each card has unique abilities that can turn the tide of battle!",
      type: TutorialType.highlight,
      actions: ["View collection", "Inspect cards", "Organize deck", "Test combinations"],
      estimatedTime: Duration(minutes: 3),
    ),
    TutorialStep.qrScanner: TutorialStepData(
      step: TutorialStep.qrScanner,
      title: "Scan Physical Cards 📱",
      description: "Integrate your physical card collection with the app. Scan QR codes to automatically add cards to your digital collection!",
      type: TutorialType.walkthrough,
      actions: ["Open scanner", "Point at QR code", "Confirm card", "Add to collection"],
      estimatedTime: Duration(minutes: 2),
    ),
    TutorialStep.settings: TutorialStepData(
      step: TutorialStep.settings,
      title: "Customize Your Experience ⚙️",
      description: "Adjust audio, notifications, and other preferences to make the app perfect for your playstyle.",
      type: TutorialType.highlight,
      actions: ["Open settings", "Adjust audio", "Set notifications", "Save preferences"],
      estimatedTime: Duration(minutes: 2),
    ),
    TutorialStep.complete: TutorialStepData(
      step: TutorialStep.complete,
      title: "You're Ready for Adventure! 🚀",
      description: "Congratulations! You've completed the tutorial and are ready to embark on your epic journey. Your character awaits your next adventure!",
      type: TutorialType.modal,
      isRequired: false,
      estimatedTime: Duration(seconds: 30),
    ),
  };

  // Getters
  bool get isTutorialActive => _isTutorialActive;
  TutorialStep get currentStep => _currentStep;
  bool get isFirstTimeUser => _isFirstTimeUser;
  Map<TutorialStep, bool> get completedSteps => Map.unmodifiable(_completedSteps);
  Map<TutorialStep, DateTime> get stepCompletionTimes => Map.unmodifiable(_stepCompletionTimes);
  TutorialStepData get currentStepData => _tutorialSteps[_currentStep]!;
  List<TutorialStepData> get allTutorialSteps => _tutorialSteps.values.toList();

  // Initialize tutorial service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    await _loadTutorialData();
    _isInitialized = true;
    notifyListeners();
  }

  // Load tutorial data from preferences
  Future<void> _loadTutorialData() async {
    _isFirstTimeUser = _prefs.getBool('isFirstTimeUser') ?? true;
    _isTutorialActive = _prefs.getBool('isTutorialActive') ?? false;
    
    final currentStepIndex = _prefs.getInt('currentTutorialStep') ?? 0;
    _currentStep = TutorialStep.values[currentStepIndex];

    // Load completed steps
    _completedSteps.clear();
    for (final step in TutorialStep.values) {
      final isCompleted = _prefs.getBool('tutorial_step_${step.name}') ?? false;
      _completedSteps[step] = isCompleted;
    }

    // Load completion times
    _stepCompletionTimes.clear();
    for (final step in TutorialStep.values) {
      final timestamp = _prefs.getInt('tutorial_time_${step.name}');
      if (timestamp != null) {
        _stepCompletionTimes[step] = DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    }
  }

  // Save tutorial data to preferences
  Future<void> _saveTutorialData() async {
    await _prefs.setBool('isFirstTimeUser', _isFirstTimeUser);
    await _prefs.setBool('isTutorialActive', _isTutorialActive);
    await _prefs.setInt('currentTutorialStep', _currentStep.index);

    // Save completed steps
    for (final entry in _completedSteps.entries) {
      await _prefs.setBool('tutorial_step_${entry.key.name}', entry.value);
    }

    // Save completion times
    for (final entry in _stepCompletionTimes.entries) {
      await _prefs.setInt('tutorial_time_${entry.key.name}', entry.value.millisecondsSinceEpoch);
    }
  }

  // Start tutorial
  Future<void> startTutorial() async {
    _isTutorialActive = true;
    _currentStep = TutorialStep.welcome;
    await _saveTutorialData();
    notifyListeners();
  }

  // Complete current step
  Future<void> completeCurrentStep() async {
    _completedSteps[_currentStep] = true;
    _stepCompletionTimes[_currentStep] = DateTime.now();
    await _saveTutorialData();
    notifyListeners();
  }

  // Move to next step
  Future<void> nextStep() async {
    final currentIndex = TutorialStep.values.indexOf(_currentStep);
    if (currentIndex < TutorialStep.values.length - 1) {
      _currentStep = TutorialStep.values[currentIndex + 1];
      await _saveTutorialData();
      notifyListeners();
    }
  }

  // Move to previous step
  Future<void> previousStep() async {
    final currentIndex = TutorialStep.values.indexOf(_currentStep);
    if (currentIndex > 0) {
      _currentStep = TutorialStep.values[currentIndex - 1];
      await _saveTutorialData();
      notifyListeners();
    }
  }

  // Skip tutorial
  Future<void> skipTutorial() async {
    _isTutorialActive = false;
    _isFirstTimeUser = false;
    // Mark all steps as completed
    for (final step in TutorialStep.values) {
      _completedSteps[step] = true;
    }
    await _saveTutorialData();
    notifyListeners();
  }

  // Complete tutorial
  Future<void> completeTutorial() async {
    _isTutorialActive = false;
    _isFirstTimeUser = false;
    _currentStep = TutorialStep.complete;
    _completedSteps[TutorialStep.complete] = true;
    _stepCompletionTimes[TutorialStep.complete] = DateTime.now();
    await _saveTutorialData();
    notifyListeners();
  }

  // Get tutorial progress
  double get tutorialProgress {
    final completedCount = _completedSteps.values.where((completed) => completed).length;
    return completedCount / TutorialStep.values.length;
  }

  // Get step progress
  double get stepProgress {
    final currentIndex = TutorialStep.values.indexOf(_currentStep);
    return currentIndex / (TutorialStep.values.length - 1);
  }

  // Check if step is completed
  bool isStepCompleted(TutorialStep step) {
    return _completedSteps[step] ?? false;
  }

  // Get step completion time
  DateTime? getStepCompletionTime(TutorialStep step) {
    return _stepCompletionTimes[step];
  }

  // Get tutorial statistics
  Map<String, dynamic> getTutorialStatistics() {
    final totalSteps = TutorialStep.values.length;
    final completedSteps = _completedSteps.values.where((completed) => completed).length;
    final totalTime = _stepCompletionTimes.values.fold<Duration>(
      Duration.zero,
      (total, time) => total + Duration(milliseconds: time.millisecondsSinceEpoch),
    );

    return {
      'totalSteps': totalSteps,
      'completedSteps': completedSteps,
      'completionRate': completedSteps / totalSteps,
      'totalTime': totalTime,
      'averageTimePerStep': totalTime.inMilliseconds / completedSteps,
      'isFirstTimeUser': _isFirstTimeUser,
      'isTutorialActive': _isTutorialActive,
    };
  }

  // Reset tutorial
  Future<void> resetTutorial() async {
    _isTutorialActive = false;
    _isFirstTimeUser = true;
    _currentStep = TutorialStep.welcome;
    _completedSteps.clear();
    _stepCompletionTimes.clear();
    await _saveTutorialData();
    notifyListeners();
  }

  // Show tutorial for specific step
  Future<void> showTutorialForStep(TutorialStep step) async {
    _currentStep = step;
    _isTutorialActive = true;
    await _saveTutorialData();
    notifyListeners();
  }

  // Check if tutorial should be shown
  bool shouldShowTutorial() {
    return _isFirstTimeUser || _isTutorialActive;
  }

  // Get next step data
  TutorialStepData? getNextStepData() {
    final currentIndex = TutorialStep.values.indexOf(_currentStep);
    if (currentIndex < TutorialStep.values.length - 1) {
      final nextStep = TutorialStep.values[currentIndex + 1];
      return _tutorialSteps[nextStep];
    }
    return null;
  }

  // Get previous step data
  TutorialStepData? getPreviousStepData() {
    final currentIndex = TutorialStep.values.indexOf(_currentStep);
    if (currentIndex > 0) {
      final previousStep = TutorialStep.values[currentIndex - 1];
      return _tutorialSteps[previousStep];
    }
    return null;
  }
} 