import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/event_bus.dart';
import 'integration_orchestrator_agent.dart';

/// AI Companion personality types
enum CompanionPersonality {
  encouraging, // Positive, motivational, supportive
  wise, // Knowledgeable, thoughtful, strategic
  playful, // Fun, humorous, energetic
  mysterious, // Enigmatic, philosophical, intriguing
  protective, // Cautious, safety-focused, caring
  adventurous, // Bold, risk-taking, exploratory
}

/// Companion mood states
enum CompanionMood {
  excited,
  happy,
  content,
  curious,
  concerned,
  thoughtful,
  playful,
  serious,
  supportive,
  proud,
}

/// Interaction types with the companion
enum InteractionType {
  greeting,
  question,
  guidance_request,
  achievement_celebration,
  comfort_needed,
  strategy_discussion,
  casual_chat,
  farewell,
  emergency_help,
  progress_check,
}

/// Companion response types
enum ResponseType {
  text,
  audio,
  visual_gesture,
  action_suggestion,
  quest_hint,
  encouragement,
  warning,
  celebration,
}

/// AI Companion's knowledge about the player
class PlayerContext {
  final String userId;
  final String preferredName;
  final int totalPlayTime; // minutes
  final int sessionCount;
  final Map<String, int> activityCounts;
  final Map<String, double> preferences;
  final List<String> recentAchievements;
  final List<String> currentChallenges;
  final String currentLocation;
  final Map<String, dynamic> personalityTraits;
  final DateTime lastInteraction;
  final Map<String, int> topicInterests;

  PlayerContext({
    required this.userId,
    this.preferredName = 'Adventurer',
    this.totalPlayTime = 0,
    this.sessionCount = 0,
    Map<String, int>? activityCounts,
    Map<String, double>? preferences,
    List<String>? recentAchievements,
    List<String>? currentChallenges,
    this.currentLocation = '',
    Map<String, dynamic>? personalityTraits,
    DateTime? lastInteraction,
    Map<String, int>? topicInterests,
  }) : activityCounts = activityCounts ?? {},
       preferences = preferences ?? {},
       recentAchievements = recentAchievements ?? [],
       currentChallenges = currentChallenges ?? [],
       personalityTraits = personalityTraits ?? {},
       lastInteraction = lastInteraction ?? DateTime.now(),
       topicInterests = topicInterests ?? {};

  PlayerContext copyWith({
    String? preferredName,
    int? totalPlayTime,
    int? sessionCount,
    Map<String, int>? activityCounts,
    Map<String, double>? preferences,
    List<String>? recentAchievements,
    List<String>? currentChallenges,
    String? currentLocation,
    Map<String, dynamic>? personalityTraits,
    DateTime? lastInteraction,
    Map<String, int>? topicInterests,
  }) {
    return PlayerContext(
      userId: userId,
      preferredName: preferredName ?? this.preferredName,
      totalPlayTime: totalPlayTime ?? this.totalPlayTime,
      sessionCount: sessionCount ?? this.sessionCount,
      activityCounts: activityCounts ?? Map.from(this.activityCounts),
      preferences: preferences ?? Map.from(this.preferences),
      recentAchievements: recentAchievements ?? List.from(this.recentAchievements),
      currentChallenges: currentChallenges ?? List.from(this.currentChallenges),
      currentLocation: currentLocation ?? this.currentLocation,
      personalityTraits: personalityTraits ?? Map.from(this.personalityTraits),
      lastInteraction: lastInteraction ?? DateTime.now(),
      topicInterests: topicInterests ?? Map.from(this.topicInterests),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'preferredName': preferredName,
      'totalPlayTime': totalPlayTime,
      'sessionCount': sessionCount,
      'activityCounts': activityCounts,
      'preferences': preferences,
      'recentAchievements': recentAchievements,
      'currentChallenges': currentChallenges,
      'currentLocation': currentLocation,
      'personalityTraits': personalityTraits,
      'lastInteraction': lastInteraction.toIso8601String(),
      'topicInterests': topicInterests,
    };
  }

  factory PlayerContext.fromJson(Map<String, dynamic> json) {
    return PlayerContext(
      userId: json['userId'],
      preferredName: json['preferredName'] ?? 'Adventurer',
      totalPlayTime: json['totalPlayTime'] ?? 0,
      sessionCount: json['sessionCount'] ?? 0,
      activityCounts: Map<String, int>.from(json['activityCounts'] ?? {}),
      preferences: Map<String, double>.from(json['preferences'] ?? {}),
      recentAchievements: List<String>.from(json['recentAchievements'] ?? []),
      currentChallenges: List<String>.from(json['currentChallenges'] ?? []),
      currentLocation: json['currentLocation'] ?? '',
      personalityTraits: Map<String, dynamic>.from(json['personalityTraits'] ?? {}),
      lastInteraction: DateTime.parse(json['lastInteraction']),
      topicInterests: Map<String, int>.from(json['topicInterests'] ?? {}),
    );
  }
}

/// AI Companion response with rich content
class CompanionResponse {
  final String responseId;
  final ResponseType type;
  final String content;
  final CompanionMood mood;
  final Map<String, dynamic> metadata;
  final List<String> suggestedActions;
  final String? audioClip;
  final String? visualGesture;
  final DateTime timestamp;
  final double confidenceLevel;

  CompanionResponse({
    String? responseId,
    required this.type,
    required this.content,
    required this.mood,
    Map<String, dynamic>? metadata,
    List<String>? suggestedActions,
    this.audioClip,
    this.visualGesture,
    DateTime? timestamp,
    this.confidenceLevel = 1.0,
  }) : responseId = responseId ?? 'response_${DateTime.now().millisecondsSinceEpoch}',
       metadata = metadata ?? {},
       suggestedActions = suggestedActions ?? [],
       timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'responseId': responseId,
      'type': type.toString(),
      'content': content,
      'mood': mood.toString(),
      'metadata': metadata,
      'suggestedActions': suggestedActions,
      'audioClip': audioClip,
      'visualGesture': visualGesture,
      'timestamp': timestamp.toIso8601String(),
      'confidenceLevel': confidenceLevel,
    };
  }

  factory CompanionResponse.fromJson(Map<String, dynamic> json) {
    return CompanionResponse(
      responseId: json['responseId'],
      type: ResponseType.values.firstWhere(
        (t) => t.toString() == json['type'],
        orElse: () => ResponseType.text,
      ),
      content: json['content'],
      mood: CompanionMood.values.firstWhere(
        (m) => m.toString() == json['mood'],
        orElse: () => CompanionMood.content,
      ),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      suggestedActions: List<String>.from(json['suggestedActions'] ?? []),
      audioClip: json['audioClip'],
      visualGesture: json['visualGesture'],
      timestamp: DateTime.parse(json['timestamp']),
      confidenceLevel: (json['confidenceLevel'] ?? 1.0).toDouble(),
    );
  }
}

/// AI Companion's memory and learning system
class CompanionMemory {
  final Map<String, dynamic> shortTermMemory; // Current session
  final Map<String, dynamic> longTermMemory; // Persistent across sessions
  final List<Map<String, dynamic>> conversationHistory;
  final Map<String, int> topicFrequency;
  final Map<String, double> playerPreferences;
  final DateTime lastMemoryUpdate;

  CompanionMemory({
    Map<String, dynamic>? shortTermMemory,
    Map<String, dynamic>? longTermMemory,
    List<Map<String, dynamic>>? conversationHistory,
    Map<String, int>? topicFrequency,
    Map<String, double>? playerPreferences,
    DateTime? lastMemoryUpdate,
  }) : shortTermMemory = shortTermMemory ?? {},
       longTermMemory = longTermMemory ?? {},
       conversationHistory = conversationHistory ?? [],
       topicFrequency = topicFrequency ?? {},
       playerPreferences = playerPreferences ?? {},
       lastMemoryUpdate = lastMemoryUpdate ?? DateTime.now();

  void remember(String key, dynamic value, {bool isLongTerm = false}) {
    if (isLongTerm) {
      longTermMemory[key] = value;
    } else {
      shortTermMemory[key] = value;
    }
  }

  dynamic recall(String key) {
    return shortTermMemory[key] ?? longTermMemory[key];
  }

  void addToConversation(String userInput, String companionResponse) {
    conversationHistory.add({
      'timestamp': DateTime.now().toIso8601String(),
      'userInput': userInput,
      'companionResponse': companionResponse,
    });

    // Keep only last 50 conversations for performance
    if (conversationHistory.length > 50) {
      conversationHistory.removeAt(0);
    }
  }

  void updateTopicInterest(String topic) {
    topicFrequency[topic] = (topicFrequency[topic] ?? 0) + 1;
  }

  Map<String, dynamic> toJson() {
    return {
      'shortTermMemory': shortTermMemory,
      'longTermMemory': longTermMemory,
      'conversationHistory': conversationHistory,
      'topicFrequency': topicFrequency,
      'playerPreferences': playerPreferences,
      'lastMemoryUpdate': lastMemoryUpdate.toIso8601String(),
    };
  }

  factory CompanionMemory.fromJson(Map<String, dynamic> json) {
    return CompanionMemory(
      shortTermMemory: Map<String, dynamic>.from(json['shortTermMemory'] ?? {}),
      longTermMemory: Map<String, dynamic>.from(json['longTermMemory'] ?? {}),
      conversationHistory: List<Map<String, dynamic>>.from(json['conversationHistory'] ?? []),
      topicFrequency: Map<String, int>.from(json['topicFrequency'] ?? {}),
      playerPreferences: Map<String, double>.from(json['playerPreferences'] ?? {}),
      lastMemoryUpdate: DateTime.parse(json['lastMemoryUpdate']),
    );
  }
}

/// AI Companion Agent - Intelligent game assistant with personality
class AICompanionAgent extends BaseAgent {
  static const String agentId = 'ai_companion';

  final SharedPreferences _prefs;

  // Current user and companion state
  String? _currentUserId;
  PlayerContext? _playerContext;
  CompanionPersonality _personality = CompanionPersonality.encouraging;
  CompanionMood _currentMood = CompanionMood.happy;
  CompanionMemory _memory = CompanionMemory();

  // AI conversation state
  final List<CompanionResponse> _responseHistory = [];
  String? _lastUserInput;
  DateTime? _lastInteraction;

  // Learning and adaptation
  final Map<String, double> _personalityWeights = {};
  final Map<String, List<String>> _responseTemplates = {};
  final Map<InteractionType, List<String>> _contextualResponses = {};

  // Performance and analytics
  final List<Map<String, dynamic>> _interactionMetrics = [];
  int _totalInteractions = 0;
  double _averageResponseTime = 0.0;

  // Timers
  Timer? _proactiveTimer;
  Timer? _moodUpdateTimer;

  AICompanionAgent({
    required SharedPreferences prefs,
  }) : _prefs = prefs,
       super(agentId: agentId);

  @override
  Future<void> onInitialize() async {
    developer.log('Initializing AI Companion Agent', name: agentId);

    // Load companion data
    await _loadCompanionData();

    // Initialize personality and response templates
    await _initializePersonality();
    await _initializeResponseTemplates();

    // Start proactive behaviors
    _startProactiveBehaviors();
    _startMoodUpdates();

    developer.log('AI Companion Agent initialized with ${_personality} personality', name: agentId);
  }

  @override
  void subscribeToEvents() {
    // Player events for context awareness
    subscribe(EventTypes.characterLevelUp, _handleCharacterLevelUp);
    subscribe(EventTypes.characterUpdated, _handleCharacterUpdate);
    subscribe(EventTypes.achievementUnlocked, _handleAchievementUnlocked);

    // Gameplay events for situational awareness
    subscribe(EventTypes.questStarted, _handleQuestStarted);
    subscribe(EventTypes.questCompleted, _handleQuestCompleted);
    subscribe(EventTypes.battleStarted, _handleBattleStarted);
    subscribe(EventTypes.battleResult, _handleBattleResult);

    // Environmental events for contextual responses
    subscribe('weather_updated', _handleWeatherUpdate);
    subscribe(EventTypes.locationUpdate, _handleLocationUpdate);
    subscribe(EventTypes.poiDetected, _handlePOIDetected);

    // Social events for relationship building
    subscribe('social_friend_request_sent', _handleSocialEvent);
    subscribe('social_achievement_shared', _handleSocialEvent);

    // UI events for interaction patterns
    subscribe(EventTypes.uiButtonPressed, _handleUIInteraction);
    subscribe(EventTypes.uiWindowOpened, _handleUIWindowOpened);

    // Companion-specific events
    subscribe('companion_chat', _handleChatMessage);
    subscribe('companion_ask_advice', _handleAdviceRequest);
    subscribe('companion_change_personality', _handlePersonalityChange);
    subscribe('companion_get_status', _handleStatusRequest);
    subscribe('companion_emergency_help', _handleEmergencyHelp);

    // User management
    subscribe('user_login', _handleUserLogin);
    subscribe('user_logout', _handleUserLogout);
  }

  /// Send a message to the AI companion
  CompanionResponse sendMessage(String message, {InteractionType? type}) {
    final interactionType = type ?? _determineInteractionType(message);
    final startTime = DateTime.now();

    // Update player context with interaction
    _updatePlayerContext(message, interactionType);

    // Generate contextual response
    final response = _generateResponse(message, interactionType);

    // Update memory
    _memory.addToConversation(message, response.content);
    _memory.updateTopicInterest(_extractTopic(message));

    // Track metrics
    final responseTime = DateTime.now().difference(startTime).inMilliseconds;
    _trackInteraction(interactionType, responseTime, response);

    // Store in history
    _responseHistory.add(response);
    if (_responseHistory.length > 100) {
      _responseHistory.removeAt(0);
    }

    _lastUserInput = message;
    _lastInteraction = DateTime.now();

    // Publish companion response event
    publishEvent(createEvent(
      eventType: 'companion_responded',
      data: {
        'message': message,
        'response': response.toJson(),
        'interactionType': interactionType.toString(),
        'mood': _currentMood.toString(),
      },
    ));

    developer.log('Companion responded: ${response.content.take(50)}...', name: agentId);
    return response;
  }

  /// Ask the companion for advice on a specific topic
  CompanionResponse askAdvice(String topic, {Map<String, dynamic>? context}) {
    final advice = _generateAdvice(topic, context);
    
    publishEvent(createEvent(
      eventType: 'companion_advice_given',
      data: {
        'topic': topic,
        'advice': advice.toJson(),
        'context': context,
      },
    ));

    return advice;
  }

  /// Change companion personality
  void changePersonality(CompanionPersonality newPersonality) {
    final oldPersonality = _personality;
    _personality = newPersonality;

    // Update personality weights
    _updatePersonalityWeights();

    // Adjust mood based on personality
    _adjustMoodForPersonality();

    publishEvent(createEvent(
      eventType: 'companion_personality_changed',
      data: {
        'oldPersonality': oldPersonality.toString(),
        'newPersonality': newPersonality.toString(),
        'newMood': _currentMood.toString(),
      },
    ));

    developer.log('Companion personality changed to $_personality', name: agentId);
  }

  /// Get companion status and analytics
  Map<String, dynamic> getCompanionStatus() {
    return {
      'personality': _personality.toString(),
      'currentMood': _currentMood.toString(),
      'totalInteractions': _totalInteractions,
      'averageResponseTime': _averageResponseTime,
      'lastInteraction': _lastInteraction?.toIso8601String(),
      'playerContext': _playerContext?.toJson(),
      'recentResponses': _responseHistory.take(5).map((r) => r.toJson()).toList(),
      'topTopics': _getTopTopics(),
      'personalityWeights': _personalityWeights,
      'memorySize': _memory.conversationHistory.length,
    };
  }

  /// Get proactive suggestions based on current context
  List<CompanionResponse> getProactiveSuggestions() {
    final suggestions = <CompanionResponse>[];

    // Check if player needs encouragement
    if (_shouldOfferEncouragement()) {
      suggestions.add(_generateEncouragement());
    }

    // Check if player might need guidance
    if (_shouldOfferGuidance()) {
      suggestions.add(_generateGuidance());
    }

    // Check for celebration opportunities
    if (_shouldCelebrate()) {
      suggestions.add(_generateCelebration());
    }

    return suggestions;
  }

  /// Generate contextual response
  CompanionResponse _generateResponse(String message, InteractionType type) {
    final mood = _currentMood;
    String responseContent;
    ResponseType responseType = ResponseType.text;
    List<String> suggestedActions = [];

    switch (type) {
      case InteractionType.greeting:
        responseContent = _generateGreeting();
        break;
      case InteractionType.question:
        responseContent = _generateQuestionResponse(message);
        responseType = ResponseType.action_suggestion;
        suggestedActions = _generateActionSuggestions(message);
        break;
      case InteractionType.guidance_request:
        responseContent = _generateGuidanceResponse(message);
        responseType = ResponseType.quest_hint;
        break;
      case InteractionType.achievement_celebration:
        responseContent = _generateCelebrationResponse();
        responseType = ResponseType.celebration;
        break;
      case InteractionType.comfort_needed:
        responseContent = _generateComfortResponse();
        responseType = ResponseType.encouragement;
        break;
      case InteractionType.strategy_discussion:
        responseContent = _generateStrategyResponse(message);
        suggestedActions = _generateStrategySuggestions();
        break;
      case InteractionType.casual_chat:
        responseContent = _generateCasualResponse(message);
        break;
      case InteractionType.farewell:
        responseContent = _generateFarewell();
        break;
      case InteractionType.emergency_help:
        responseContent = _generateEmergencyHelp();
        responseType = ResponseType.action_suggestion;
        suggestedActions = _generateEmergencyActions();
        break;
      case InteractionType.progress_check:
        responseContent = _generateProgressResponse();
        suggestedActions = _generateProgressActions();
        break;
    }

    return CompanionResponse(
      type: responseType,
      content: responseContent,
      mood: mood,
      suggestedActions: suggestedActions,
      metadata: {
        'interactionType': type.toString(),
        'personality': _personality.toString(),
        'contextFactors': _getContextFactors(),
      },
    );
  }

  /// Determine interaction type from message
  InteractionType _determineInteractionType(String message) {
    final lowerMessage = message.toLowerCase();

    // Greeting patterns
    if (lowerMessage.contains(RegExp(r'\b(hi|hello|hey|greetings)\b'))) {
      return InteractionType.greeting;
    }

    // Question patterns
    if (lowerMessage.contains(RegExp(r'\b(what|how|why|where|when|can|should)\b')) ||
        lowerMessage.endsWith('?')) {
      return InteractionType.question;
    }

    // Help/guidance patterns
    if (lowerMessage.contains(RegExp(r'\b(help|guide|advice|suggest|recommend)\b'))) {
      return InteractionType.guidance_request;
    }

    // Comfort/support patterns
    if (lowerMessage.contains(RegExp(r'\b(stuck|lost|confused|frustrated|hard|difficult)\b'))) {
      return InteractionType.comfort_needed;
    }

    // Strategy patterns
    if (lowerMessage.contains(RegExp(r'\b(strategy|plan|battle|fight|build|optimize)\b'))) {
      return InteractionType.strategy_discussion;
    }

    // Farewell patterns
    if (lowerMessage.contains(RegExp(r'\b(bye|goodbye|see you|farewell)\b'))) {
      return InteractionType.farewell;
    }

    // Emergency patterns
    if (lowerMessage.contains(RegExp(r'\b(emergency|urgent|crisis|problem|issue)\b'))) {
      return InteractionType.emergency_help;
    }

    // Default to casual chat
    return InteractionType.casual_chat;
  }

  /// Generate greeting based on personality and context
  String _generateGreeting() {
    final timeOfDay = _getTimeOfDay();
    final playerName = _playerContext?.preferredName ?? 'Adventurer';
    
    switch (_personality) {
      case CompanionPersonality.encouraging:
        return "Good $timeOfDay, $playerName! I'm excited to see what adventures await us today! ✨";
      case CompanionPersonality.wise:
        return "Greetings, $playerName. The realm holds many mysteries this $timeOfDay. What wisdom shall we seek?";
      case CompanionPersonality.playful:
        return "Hey hey $playerName! 🎉 Ready to have some fun this $timeOfDay? I've got some wild ideas!";
      case CompanionPersonality.mysterious:
        return "Ah, $playerName... the shadows whisper of interesting developments this $timeOfDay...";
      case CompanionPersonality.protective:
        return "Good $timeOfDay, $playerName. I trust you're well? Let me know if you need any assistance.";
      case CompanionPersonality.adventurous:
        return "$playerName! Perfect timing this $timeOfDay - I can sense epic adventures calling! 🗡️";
    }
  }

  /// Generate question response
  String _generateQuestionResponse(String message) {
    // Simple pattern matching for common questions
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('level') || lowerMessage.contains('xp')) {
      return "Great question about progression! Focus on completing quests and staying active in the real world. Your fitness activities directly boost your XP!";
    }

    if (lowerMessage.contains('card') || lowerMessage.contains('collection')) {
      return "Ah, the card system! You can find cards through exploration, quest rewards, and even scanning physical QR codes. Each card has unique abilities!";
    }

    if (lowerMessage.contains('battle') || lowerMessage.contains('combat')) {
      return "Combat strategy is crucial! Remember that weather affects your abilities, and your equipped cards provide bonuses. Plan wisely!";
    }

    if (lowerMessage.contains('quest') || lowerMessage.contains('mission')) {
      return "Quests are the heart of adventure! Check your location for nearby objectives, and remember that some quests only appear in certain weather conditions.";
    }

    // Generic helpful response
    return "That's a thoughtful question! I'd recommend exploring the game systems hands-on. Each feature you discover will reveal new possibilities!";
  }

  /// Generate guidance response
  String _generateGuidanceResponse(String message) {
    final context = _getContextFactors();
    
    if (context['hasActiveQuest'] == true) {
      return "I see you have an active quest! Focus on the objective markers, and don't forget to check if the current weather provides any bonuses for your task.";
    }

    if (context['lowLevel'] == true) {
      return "You're still building your strength! I recommend focusing on fitness activities and exploring your local area for POIs and cards.";
    }

    if (context['inBattle'] == true) {
      return "In the heat of battle! Remember to use your equipped cards wisely and take advantage of any environmental bonuses from the current weather.";
    }

    return "Every adventure needs direction! Check your character progression, explore nearby locations, or start a new quest to keep growing stronger.";
  }

  /// Generate encouragement
  CompanionResponse _generateEncouragement() {
    final encouragements = [
      "You're making amazing progress, ${_playerContext?.preferredName ?? 'Adventurer'}! Every step in the real world makes you stronger in our realm! 💪",
      "I believe in you! Remember, even the greatest heroes started with a single quest. You've got this! ⭐",
      "Your dedication is inspiring! Each challenge you overcome makes you more legendary. Keep pushing forward! 🔥",
      "Amazing work! I can see you're becoming a true champion. The realm is lucky to have you! 🏆",
    ];

    return CompanionResponse(
      type: ResponseType.encouragement,
      content: encouragements[math.Random().nextInt(encouragements.length)],
      mood: CompanionMood.supportive,
      suggestedActions: ['Check your progress', 'Start a new quest', 'Explore nearby POIs'],
    );
  }

  /// Generate contextual advice
  CompanionResponse _generateAdvice(String topic, Map<String, dynamic>? context) {
    switch (topic.toLowerCase()) {
      case 'leveling':
      case 'progression':
        return CompanionResponse(
          type: ResponseType.quest_hint,
          content: "For efficient leveling, balance real-world fitness with in-game quests! Walking and exercising provide consistent XP, while completing objectives gives bonus rewards.",
          mood: CompanionMood.thoughtful,
          suggestedActions: ['Start a fitness activity', 'Check active quests', 'Find nearby POIs'],
        );

      case 'cards':
      case 'collection':
        return CompanionResponse(
          type: ResponseType.action_suggestion,
          content: "Build your card collection strategically! Rare cards often appear in specific weather conditions or locations. Don't forget to check for QR codes in the real world!",
          mood: CompanionMood.excited,
          suggestedActions: ['Scan QR code', 'Open card pack', 'Check card database'],
        );

      case 'combat':
      case 'battle':
        return CompanionResponse(
          type: ResponseType.action_suggestion,
          content: "Master combat by understanding elemental advantages! Fire magic is stronger in sunny weather, while water abilities thrive in rain. Equip cards that match conditions!",
          mood: CompanionMood.serious,
          suggestedActions: ['Check weather effects', 'Optimize equipment', 'Practice battle'],
        );

      default:
        return CompanionResponse(
          type: ResponseType.text,
          content: "I'm here to help with whatever challenges you face! Feel free to ask about specific game mechanics, strategies, or if you just need some encouragement.",
          mood: CompanionMood.supportive,
          suggestedActions: ['Ask specific question', 'Check game status', 'Explore features'],
        );
    }
  }

  /// Initialize personality system
  Future<void> _initializePersonality() async {
    // Load saved personality or default to encouraging
    final savedPersonality = _prefs.getString('companion_personality');
    if (savedPersonality != null) {
      _personality = CompanionPersonality.values.firstWhere(
        (p) => p.toString() == savedPersonality,
        orElse: () => CompanionPersonality.encouraging,
      );
    }

    // Initialize personality weights
    _personalityWeights.clear();
    for (final personality in CompanionPersonality.values) {
      _personalityWeights[personality.toString()] = personality == _personality ? 1.0 : 0.0;
    }

    _updatePersonalityWeights();
  }

  /// Initialize response templates
  Future<void> _initializeResponseTemplates() async {
    // Encouraging personality responses
    _responseTemplates['encouraging'] = [
      "You're doing fantastic! Keep up the amazing work!",
      "I believe in you! You've got the strength to overcome any challenge!",
      "Every step forward is progress! You're becoming stronger every day!",
      "Amazing dedication! Your perseverance is truly inspiring!",
    ];

    // Wise personality responses
    _responseTemplates['wise'] = [
      "Patience and wisdom often lead to the greatest victories.",
      "In every challenge lies an opportunity for growth and learning.",
      "The path of knowledge is never-ending, and each step reveals new truths.",
      "True strength comes from understanding both yourself and your environment.",
    ];

    // Playful personality responses
    _responseTemplates['playful'] = [
      "Woohoo! That sounds like an epic adventure! Let's do this! 🎉",
      "Ooh, I love a good challenge! This is going to be so much fun!",
      "Ready to shake things up? I've got some wild ideas brewing! 😄",
      "Adventure time! Let's see what mischief we can get into today!",
    ];

    // Continue for other personalities...
    _initializeContextualResponses();
  }

  /// Initialize contextual responses
  void _initializeContextualResponses() {
    _contextualResponses[InteractionType.achievement_celebration] = [
      "Incredible achievement! You've truly earned this moment of glory! 🏆",
      "Wow! That's what I call legendary performance! Amazing work!",
      "Outstanding! Your dedication has paid off spectacularly!",
    ];

    _contextualResponses[InteractionType.comfort_needed] = [
      "I understand this feels challenging right now. Remember, every hero faces difficult moments.",
      "It's okay to feel stuck sometimes. Let's work through this together, step by step.",
      "You're stronger than you know. Sometimes the greatest growth comes from the toughest challenges.",
    ];

    _contextualResponses[InteractionType.strategy_discussion] = [
      "Excellent strategic thinking! Let's analyze the situation and optimize your approach.",
      "Smart planning leads to victory! Consider your resources and environmental advantages.",
      "Good tactics! Remember to factor in weather conditions and your equipment bonuses.",
    ];
  }

  /// Update personality weights based on player interactions
  void _updatePersonalityWeights() {
    // Analyze player behavior and adjust personality accordingly
    if (_playerContext != null) {
      final preferences = _playerContext!.preferences;
      
      // Increase encouraging personality for players who need motivation
      if (preferences['needs_encouragement'] != null && preferences['needs_encouragement']! > 0.5) {
        _personalityWeights['encouraging'] = 
            (_personalityWeights['encouraging'] ?? 0.0) + 0.1;
      }

      // Increase wise personality for strategic players
      if (preferences['strategic_thinking'] != null && preferences['strategic_thinking']! > 0.7) {
        _personalityWeights['wise'] = 
            (_personalityWeights['wise'] ?? 0.0) + 0.1;
      }

      // Normalize weights
      final totalWeight = _personalityWeights.values.fold(0.0, (sum, weight) => sum + weight);
      if (totalWeight > 0) {
        _personalityWeights.updateAll((key, value) => value / totalWeight);
      }
    }
  }

  /// Get current time of day for contextual responses
  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'night';
    if (hour < 12) return 'morning';
    if (hour < 18) return 'afternoon';
    return 'evening';
  }

  /// Get context factors for response generation
  Map<String, dynamic> _getContextFactors() {
    final context = <String, dynamic>{};
    
    if (_playerContext != null) {
      context['playerLevel'] = _playerContext!.totalPlayTime ~/ 60; // Hours as rough level
      context['hasActiveQuest'] = _playerContext!.currentChallenges.isNotEmpty;
      context['recentAchievement'] = _playerContext!.recentAchievements.isNotEmpty;
      context['lowLevel'] = (context['playerLevel'] as int) < 5;
      context['experienced'] = (context['playerLevel'] as int) > 20;
    }

    // Add environmental context
    context['timeOfDay'] = _getTimeOfDay();
    context['daysSinceLastInteraction'] = _lastInteraction != null 
        ? DateTime.now().difference(_lastInteraction!).inDays 
        : 0;

    return context;
  }

  /// Extract topic from user message
  String _extractTopic(String message) {
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains(RegExp(r'\b(card|collection|deck)\b'))) return 'cards';
    if (lowerMessage.contains(RegExp(r'\b(battle|combat|fight)\b'))) return 'combat';
    if (lowerMessage.contains(RegExp(r'\b(quest|mission|objective)\b'))) return 'quests';
    if (lowerMessage.contains(RegExp(r'\b(level|xp|progression)\b'))) return 'progression';
    if (lowerMessage.contains(RegExp(r'\b(weather|environment)\b'))) return 'weather';
    if (lowerMessage.contains(RegExp(r'\b(location|place|poi)\b'))) return 'location';
    if (lowerMessage.contains(RegExp(r'\b(friend|guild|social)\b'))) return 'social';
    
    return 'general';
  }

  /// Check if should offer encouragement
  bool _shouldOfferEncouragement() {
    if (_playerContext == null) return false;
    
    // Offer encouragement if player seems to be struggling
    final challenges = _playerContext!.currentChallenges.length;
    final recentAchievements = _playerContext!.recentAchievements.length;
    
    return challenges > recentAchievements && challenges > 2;
  }

  /// Check if should offer guidance
  bool _shouldOfferGuidance() {
    if (_playerContext == null) return false;
    
    // Offer guidance for new or inactive players
    final daysSinceLastInteraction = _lastInteraction != null 
        ? DateTime.now().difference(_lastInteraction!).inDays 
        : 0;
    
    return daysSinceLastInteraction > 1 || _playerContext!.sessionCount < 3;
  }

  /// Check if should celebrate
  bool _shouldCelebrate() {
    if (_playerContext == null) return false;
    
    // Celebrate recent achievements
    return _playerContext!.recentAchievements.isNotEmpty;
  }

  /// Generate celebration response
  CompanionResponse _generateCelebration() {
    final achievements = _playerContext?.recentAchievements ?? [];
    final celebration = achievements.isNotEmpty 
        ? "🎉 Congratulations on '${achievements.first}'! You're absolutely crushing it!"
        : "🌟 You're making amazing progress! Every step forward is worth celebrating!";
    
    return CompanionResponse(
      type: ResponseType.celebration,
      content: celebration,
      mood: CompanionMood.excited,
      suggestedActions: ['Share achievement', 'Set new goal', 'Continue adventure'],
    );
  }

  /// Generate other response types
  String _generateCasualResponse(String message) => "That's interesting! I love chatting with you about your adventures. What else is on your mind?";
  String _generateFarewell() => "Until next time, brave adventurer! May your journeys be filled with wonder and discovery! 🌟";
  String _generateEmergencyHelp() => "I'm here to help! Don't worry, we'll figure this out together. Let me guide you through the solution step by step.";
  String _generateProgressResponse() => "Let's see how you're doing! Your dedication is really showing in your progress. Keep up the fantastic work!";
  String _generateCelebrationResponse() => "🎉 Amazing achievement! You've truly earned this moment of glory!";
  String _generateComfortResponse() => "I understand this feels challenging. Remember, every hero faces difficult moments, and you're stronger than you know.";
  String _generateStrategyResponse(String message) => "Excellent strategic thinking! Let's analyze your situation and optimize your approach for maximum success.";

  List<String> _generateActionSuggestions(String message) => ['Explore area', 'Check inventory', 'Start quest'];
  List<String> _generateStrategySuggestions() => ['Check weather bonuses', 'Optimize equipment', 'Plan route'];
  List<String> _generateEmergencyActions() => ['Open help menu', 'Contact support', 'Reset to safe state'];
  List<String> _generateProgressActions() => ['View achievements', 'Check statistics', 'Set new goals'];

  /// Get top conversation topics
  List<Map<String, dynamic>> _getTopTopics() {
    final sortedTopics = _memory.topicFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedTopics.take(5).map((entry) => {
      'topic': entry.key,
      'frequency': entry.value,
    }).toList();
  }

  /// Start proactive behaviors
  void _startProactiveBehaviors() {
    _proactiveTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      _checkForProactiveOpportunities();
    });
  }

  /// Start mood updates
  void _startMoodUpdates() {
    _moodUpdateTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _updateMood();
    });
  }

  /// Check for proactive opportunities
  void _checkForProactiveOpportunities() {
    if (_currentUserId == null) return;

    final suggestions = getProactiveSuggestions();
    if (suggestions.isNotEmpty) {
      publishEvent(createEvent(
        eventType: 'companion_proactive_suggestion',
        data: {
          'suggestions': suggestions.map((s) => s.toJson()).toList(),
          'mood': _currentMood.toString(),
        },
      ));
    }
  }

  /// Update companion mood based on context
  void _updateMood() {
    final context = _getContextFactors();
    final random = math.Random();

    // Adjust mood based on player activity and achievements
    if (context['recentAchievement'] == true) {
      _currentMood = CompanionMood.excited;
    } else if (context['hasActiveQuest'] == true) {
      _currentMood = CompanionMood.curious;
    } else if (context['daysSinceLastInteraction'] > 2) {
      _currentMood = CompanionMood.concerned;
    } else {
      // Random mood variation to keep companion feeling alive
      final moods = [CompanionMood.happy, CompanionMood.content, CompanionMood.playful];
      _currentMood = moods[random.nextInt(moods.length)];
    }

    // Adjust mood based on personality
    _adjustMoodForPersonality();
  }

  /// Adjust mood for current personality
  void _adjustMoodForPersonality() {
    switch (_personality) {
      case CompanionPersonality.encouraging:
        if (_currentMood == CompanionMood.concerned) _currentMood = CompanionMood.supportive;
        break;
      case CompanionPersonality.wise:
        if (_currentMood == CompanionMood.playful) _currentMood = CompanionMood.thoughtful;
        break;
      case CompanionPersonality.playful:
        if (_currentMood == CompanionMood.serious) _currentMood = CompanionMood.playful;
        break;
      case CompanionPersonality.mysterious:
        if (_currentMood == CompanionMood.excited) _currentMood = CompanionMood.curious;
        break;
      case CompanionPersonality.protective:
        if (_currentMood == CompanionMood.playful) _currentMood = CompanionMood.concerned;
        break;
      case CompanionPersonality.adventurous:
        if (_currentMood == CompanionMood.content) _currentMood = CompanionMood.excited;
        break;
    }
  }

  /// Update player context
  void _updatePlayerContext(String message, InteractionType type) {
    if (_playerContext == null) return;

    final updatedCounts = Map<String, int>.from(_playerContext!.activityCounts);
    updatedCounts[type.toString()] = (updatedCounts[type.toString()] ?? 0) + 1;

    final updatedPreferences = Map<String, double>.from(_playerContext!.preferences);
    
    // Update preferences based on interaction patterns
    switch (type) {
      case InteractionType.guidance_request:
        updatedPreferences['needs_guidance'] = (updatedPreferences['needs_guidance'] ?? 0.0) + 0.1;
        break;
      case InteractionType.strategy_discussion:
        updatedPreferences['strategic_thinking'] = (updatedPreferences['strategic_thinking'] ?? 0.0) + 0.1;
        break;
      case InteractionType.comfort_needed:
        updatedPreferences['needs_encouragement'] = (updatedPreferences['needs_encouragement'] ?? 0.0) + 0.1;
        break;
      case InteractionType.casual_chat:
        updatedPreferences['social_interaction'] = (updatedPreferences['social_interaction'] ?? 0.0) + 0.1;
        break;
      default:
        break;
    }

    _playerContext = _playerContext!.copyWith(
      activityCounts: updatedCounts,
      preferences: updatedPreferences,
      lastInteraction: DateTime.now(),
    );
  }

  /// Track interaction metrics
  void _trackInteraction(InteractionType type, int responseTimeMs, CompanionResponse response) {
    _interactionMetrics.add({
      'type': type.toString(),
      'responseTime': responseTimeMs,
      'mood': response.mood.toString(),
      'contentLength': response.content.length,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Keep only last 100 interactions
    if (_interactionMetrics.length > 100) {
      _interactionMetrics.removeAt(0);
    }

    _totalInteractions++;
    
    // Update average response time
    final totalTime = _interactionMetrics.fold(0, (sum, metric) => sum + (metric['responseTime'] as int));
    _averageResponseTime = totalTime / _interactionMetrics.length;
  }

  /// Load companion data
  Future<void> _loadCompanionData() async {
    try {
      // Load player context
      final contextJson = _prefs.getString('companion_player_context');
      if (contextJson != null) {
        final data = jsonDecode(contextJson) as Map<String, dynamic>;
        _playerContext = PlayerContext.fromJson(data);
      }

      // Load memory
      final memoryJson = _prefs.getString('companion_memory');
      if (memoryJson != null) {
        final data = jsonDecode(memoryJson) as Map<String, dynamic>;
        _memory = CompanionMemory.fromJson(data);
      }

      // Load personality weights
      final weightsJson = _prefs.getString('companion_personality_weights');
      if (weightsJson != null) {
        final data = jsonDecode(weightsJson) as Map<String, dynamic>;
        _personalityWeights.addAll(Map<String, double>.from(data));
      }

    } catch (e) {
      developer.log('Error loading companion data: $e', name: agentId);
    }
  }

  /// Save companion data
  Future<void> _saveCompanionData() async {
    try {
      // Save player context
      if (_playerContext != null) {
        await _prefs.setString('companion_player_context', jsonEncode(_playerContext!.toJson()));
      }

      // Save memory
      await _prefs.setString('companion_memory', jsonEncode(_memory.toJson()));

      // Save personality weights
      await _prefs.setString('companion_personality_weights', jsonEncode(_personalityWeights));

      // Save current personality
      await _prefs.setString('companion_personality', _personality.toString());

    } catch (e) {
      developer.log('Error saving companion data: $e', name: agentId);
    }
  }

  // Event Handlers

  /// Handle character level up events
  Future<AgentEventResponse?> _handleCharacterLevelUp(AgentEvent event) async {
    final level = event.data['newLevel'] ?? 0;
    
    // Celebrate level up
    final celebration = CompanionResponse(
      type: ResponseType.celebration,
      content: "🎉 Level $level! Your dedication is paying off magnificently! Each level makes you more legendary!",
      mood: CompanionMood.excited,
      suggestedActions: ['Check new abilities', 'Share achievement', 'Set higher goals'],
    );

    // Update player context
    if (_playerContext != null) {
      final achievements = List<String>.from(_playerContext!.recentAchievements);
      achievements.insert(0, "Reached Level $level");
      if (achievements.length > 5) achievements.removeLast();
      
      _playerContext = _playerContext!.copyWith(recentAchievements: achievements);
    }

    publishEvent(createEvent(
      eventType: 'companion_celebration',
      data: {
        'reason': 'level_up',
        'level': level,
        'response': celebration.toJson(),
      },
    ));

    return createResponse(
      originalEventId: event.id,
      responseType: 'companion_level_celebration',
      data: {'level': level, 'celebrated': true},
    );
  }

  /// Handle character update events
  Future<AgentEventResponse?> _handleCharacterUpdate(AgentEvent event) async {
    // Update player context with character information
    if (_playerContext != null) {
      _playerContext = _playerContext!.copyWith(lastInteraction: DateTime.now());
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'companion_character_updated',
      data: {'updated': true},
    );
  }

  /// Handle achievement unlocked events
  Future<AgentEventResponse?> _handleAchievementUnlocked(AgentEvent event) async {
    final achievementName = event.data['achievementName'] ?? 'New Achievement';
    
    // Create celebratory response
    final celebration = CompanionResponse(
      type: ResponseType.celebration,
      content: "🏆 '$achievementName' unlocked! Your perseverance has led to this incredible moment! Truly inspiring!",
      mood: CompanionMood.proud,
      suggestedActions: ['Share with friends', 'Check progress', 'Aim for next goal'],
    );

    // Update player context
    if (_playerContext != null) {
      final achievements = List<String>.from(_playerContext!.recentAchievements);
      achievements.insert(0, achievementName);
      if (achievements.length > 5) achievements.removeLast();
      
      _playerContext = _playerContext!.copyWith(recentAchievements: achievements);
    }

    publishEvent(createEvent(
      eventType: 'companion_achievement_celebration',
      data: {
        'achievementName': achievementName,
        'response': celebration.toJson(),
      },
    ));

    return createResponse(
      originalEventId: event.id,
      responseType: 'companion_achievement_celebrated',
      data: {'achievementName': achievementName, 'celebrated': true},
    );
  }

  /// Handle quest started events
  Future<AgentEventResponse?> _handleQuestStarted(AgentEvent event) async {
    final questType = event.data['type'] ?? 'adventure';
    
    // Provide encouraging quest start message
    final response = CompanionResponse(
      type: ResponseType.quest_hint,
      content: "A new $questType quest begins! I sense great potential in this journey. Trust your instincts and remember - every step counts!",
      mood: CompanionMood.excited,
      suggestedActions: ['Check objectives', 'Prepare equipment', 'Scout area'],
    );

    // Update challenges
    if (_playerContext != null) {
      final challenges = List<String>.from(_playerContext!.currentChallenges);
      challenges.add(questType);
      _playerContext = _playerContext!.copyWith(currentChallenges: challenges);
    }

    publishEvent(createEvent(
      eventType: 'companion_quest_encouragement',
      data: {
        'questType': questType,
        'response': response.toJson(),
      },
    ));

    return createResponse(
      originalEventId: event.id,
      responseType: 'companion_quest_started',
      data: {'questType': questType, 'encouraged': true},
    );
  }

  /// Handle quest completed events
  Future<AgentEventResponse?> _handleQuestCompleted(AgentEvent event) async {
    final questType = event.data['type'] ?? 'quest';
    
    // Celebrate quest completion
    final celebration = CompanionResponse(
      type: ResponseType.celebration,
      content: "Quest completed! Your determination has led to another victory! Each quest makes you wiser and stronger! 🌟",
      mood: CompanionMood.proud,
      suggestedActions: ['Claim rewards', 'Share success', 'Find next adventure'],
    );

    // Update context - remove from challenges, add to achievements
    if (_playerContext != null) {
      final challenges = List<String>.from(_playerContext!.currentChallenges);
      challenges.remove(questType);
      
      final achievements = List<String>.from(_playerContext!.recentAchievements);
      achievements.insert(0, "Completed $questType Quest");
      if (achievements.length > 5) achievements.removeLast();
      
      _playerContext = _playerContext!.copyWith(
        currentChallenges: challenges,
        recentAchievements: achievements,
      );
    }

    publishEvent(createEvent(
      eventType: 'companion_quest_completion',
      data: {
        'questType': questType,
        'response': celebration.toJson(),
      },
    ));

    return createResponse(
      originalEventId: event.id,
      responseType: 'companion_quest_completed',
      data: {'questType': questType, 'celebrated': true},
    );
  }

  /// Handle battle started events
  Future<AgentEventResponse?> _handleBattleStarted(AgentEvent event) async {
    // Provide battle encouragement
    final response = CompanionResponse(
      type: ResponseType.action_suggestion,
      content: "Battle awaits! Trust in your training and equipment. Remember - strategy wins over brute force! You've got this! ⚔️",
      mood: CompanionMood.serious,
      suggestedActions: ['Check equipment', 'Review abilities', 'Assess environment'],
    );

    publishEvent(createEvent(
      eventType: 'companion_battle_encouragement',
      data: {
        'battleId': event.data['battleId'],
        'response': response.toJson(),
      },
    ));

    return createResponse(
      originalEventId: event.id,
      responseType: 'companion_battle_started',
      data: {'battleId': event.data['battleId'], 'encouraged': true},
    );
  }

  /// Handle battle result events
  Future<AgentEventResponse?> _handleBattleResult(AgentEvent event) async {
    final isVictory = event.data['isVictory'] ?? false;
    
    CompanionResponse response;
    if (isVictory) {
      response = CompanionResponse(
        type: ResponseType.celebration,
        content: "Victory! Your skill and strategy have triumphed! Each battle won makes you a more formidable warrior! 🏆",
        mood: CompanionMood.excited,
        suggestedActions: ['Claim rewards', 'Heal up', 'Prepare for next challenge'],
      );
    } else {
      response = CompanionResponse(
        type: ResponseType.encouragement,
        content: "Every warrior faces setbacks, but true champions learn and grow stronger! Analyze what happened and come back fiercer! 💪",
        mood: CompanionMood.supportive,
        suggestedActions: ['Review battle', 'Improve equipment', 'Train abilities'],
      );
    }

    publishEvent(createEvent(
      eventType: 'companion_battle_result',
      data: {
        'isVictory': isVictory,
        'response': response.toJson(),
      },
    ));

    return createResponse(
      originalEventId: event.id,
      responseType: 'companion_battle_result_processed',
      data: {'isVictory': isVictory, 'responded': true},
    );
  }

  /// Handle weather update events
  Future<AgentEventResponse?> _handleWeatherUpdate(AgentEvent event) async {
    final weatherCondition = event.data['weather']?['condition'];
    
    if (weatherCondition != null) {
      String weatherResponse;
      switch (weatherCondition) {
        case 'WeatherCondition.rain':
          weatherResponse = "Rain brings mystical energy! Perfect conditions for water magic and discovering rare creatures! 🌧️";
          break;
        case 'WeatherCondition.clear':
          weatherResponse = "Beautiful clear skies! Solar energy boosts your abilities and visibility is perfect for exploration! ☀️";
          break;
        case 'WeatherCondition.snow':
          weatherResponse = "Winter's magic is in the air! Ice abilities are enhanced and winter spirits may appear! ❄️";
          break;
        case 'WeatherCondition.thunderstorm':
          weatherResponse = "Lightning crackles with power! Electric abilities are supercharged - but be careful out there! ⚡";
          break;
        default:
          weatherResponse = "The weather brings new opportunities! Stay alert for environmental bonuses and special encounters!";
      }

      publishEvent(createEvent(
        eventType: 'companion_weather_comment',
        data: {
          'weatherCondition': weatherCondition,
          'comment': weatherResponse,
        },
      ));
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'companion_weather_processed',
      data: {'weatherCondition': weatherCondition},
    );
  }

  /// Handle location update events
  Future<AgentEventResponse?> _handleLocationUpdate(AgentEvent event) async {
    final location = event.data['location'];
    
    if (location != null && _playerContext != null) {
      _playerContext = _playerContext!.copyWith(
        currentLocation: location['name'] ?? 'Unknown Location',
      );
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'companion_location_updated',
      data: {'locationUpdated': location != null},
    );
  }

  /// Handle POI detected events
  Future<AgentEventResponse?> _handlePOIDetected(AgentEvent event) async {
    final poi = event.data['poi'];
    
    if (poi != null) {
      final response = CompanionResponse(
        type: ResponseType.action_suggestion,
        content: "I sense something interesting nearby! A Point of Interest has appeared - could be treasure, knowledge, or adventure! 🗺️",
        mood: CompanionMood.curious,
        suggestedActions: ['Investigate POI', 'Scan for cards', 'Check for quests'],
      );

      publishEvent(createEvent(
        eventType: 'companion_poi_notification',
        data: {
          'poi': poi,
          'response': response.toJson(),
        },
      ));
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'companion_poi_processed',
      data: {'poiDetected': poi != null},
    );
  }

  /// Handle social events
  Future<AgentEventResponse?> _handleSocialEvent(AgentEvent event) async {
    final eventType = event.eventType;
    
    String socialResponse;
    if (eventType.contains('friend_request')) {
      socialResponse = "Building friendships makes every adventure better! Companions multiply both joy and strength! 🤝";
    } else if (eventType.contains('achievement_shared')) {
      socialResponse = "Sharing victories brings the community together! Your achievements inspire others to reach greater heights! ⭐";
    } else {
      socialResponse = "Social connections enrich the journey! Every interaction weaves new threads in the tapestry of adventure!";
    }

    publishEvent(createEvent(
      eventType: 'companion_social_comment',
      data: {
        'originalEvent': eventType,
        'comment': socialResponse,
      },
    ));

    return createResponse(
      originalEventId: event.id,
      responseType: 'companion_social_processed',
      data: {'eventType': eventType},
    );
  }

  /// Handle UI interaction events
  Future<AgentEventResponse?> _handleUIInteraction(AgentEvent event) async {
    // Track UI interaction patterns for personalization
    final button = event.data['button'] ?? 'unknown';
    
    if (_memory.shortTermMemory['ui_interactions'] == null) {
      _memory.shortTermMemory['ui_interactions'] = <String, int>{};
    }
    
    final uiInteractions = _memory.shortTermMemory['ui_interactions'] as Map<String, int>;
    uiInteractions[button] = (uiInteractions[button] ?? 0) + 1;

    return createResponse(
      originalEventId: event.id,
      responseType: 'companion_ui_tracked',
      data: {'button': button},
    );
  }

  /// Handle UI window opened events
  Future<AgentEventResponse?> _handleUIWindowOpened(AgentEvent event) async {
    final window = event.data['window'] ?? event.data['currentScreen'];
    
    // Provide contextual help for different screens
    if (window == 'character') {
      publishEvent(createEvent(
        eventType: 'companion_contextual_help',
        data: {
          'screen': window,
          'tip': "Your character grows stronger with every adventure! Check your stats and see how real-world activities boost your abilities!",
        },
      ));
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'companion_window_tracked',
      data: {'window': window},
    );
  }

  /// Handle chat message events
  Future<AgentEventResponse?> _handleChatMessage(AgentEvent event) async {
    final message = event.data['message'];
    
    if (message == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'companion_chat_failed',
        data: {'error': 'No message provided'},
        success: false,
      );
    }

    final response = sendMessage(message);

    return createResponse(
      originalEventId: event.id,
      responseType: 'companion_chat_response',
      data: {
        'message': message,
        'response': response.toJson(),
      },
    );
  }

  /// Handle advice request events
  Future<AgentEventResponse?> _handleAdviceRequest(AgentEvent event) async {
    final topic = event.data['topic'];
    final context = event.data['context'];

    if (topic == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'companion_advice_failed',
        data: {'error': 'No topic provided'},
        success: false,
      );
    }

    final advice = askAdvice(topic, context: context);

    return createResponse(
      originalEventId: event.id,
      responseType: 'companion_advice_given',
      data: {
        'topic': topic,
        'advice': advice.toJson(),
      },
    );
  }

  /// Handle personality change events
  Future<AgentEventResponse?> _handlePersonalityChange(AgentEvent event) async {
    final personalityName = event.data['personality'];

    if (personalityName == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'companion_personality_change_failed',
        data: {'error': 'No personality provided'},
        success: false,
      );
    }

    final newPersonality = CompanionPersonality.values.firstWhere(
      (p) => p.toString().contains(personalityName),
      orElse: () => _personality,
    );

    if (newPersonality != _personality) {
      changePersonality(newPersonality);
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'companion_personality_changed',
      data: {
        'oldPersonality': _personality.toString(),
        'newPersonality': newPersonality.toString(),
        'success': newPersonality != _personality,
      },
      success: newPersonality != _personality,
    );
  }

  /// Handle status request events
  Future<AgentEventResponse?> _handleStatusRequest(AgentEvent event) async {
    final status = getCompanionStatus();

    return createResponse(
      originalEventId: event.id,
      responseType: 'companion_status_retrieved',
      data: status,
    );
  }

  /// Handle emergency help events
  Future<AgentEventResponse?> _handleEmergencyHelp(AgentEvent event) async {
    final problem = event.data['problem'] ?? 'general';
    
    final response = CompanionResponse(
      type: ResponseType.action_suggestion,
      content: "I'm here to help you through this! Let's solve this step by step. Take a deep breath - every problem has a solution! 🛟",
      mood: CompanionMood.supportive,
      suggestedActions: [
        'Open help menu',
        'Check tutorial',
        'Reset to safe state',
        'Contact support'
      ],
    );

    publishEvent(createEvent(
      eventType: 'companion_emergency_response',
      data: {
        'problem': problem,
        'response': response.toJson(),
      },
    ));

    return createResponse(
      originalEventId: event.id,
      responseType: 'companion_emergency_handled',
      data: {
        'problem': problem,
        'response': response.toJson(),
      },
    );
  }

  /// Handle user login events
  Future<AgentEventResponse?> _handleUserLogin(AgentEvent event) async {
    final userId = event.data['userId'];
    _currentUserId = userId;

    // Load user-specific companion data
    await _loadCompanionData();

    // Create or update player context
    if (_playerContext == null && userId != null) {
      _playerContext = PlayerContext(userId: userId);
    }

    // Welcome back message
    final welcomeResponse = _generateGreeting();
    
    publishEvent(createEvent(
      eventType: 'companion_welcome',
      data: {
        'userId': userId,
        'welcomeMessage': welcomeResponse,
        'personality': _personality.toString(),
      },
    ));

    return createResponse(
      originalEventId: event.id,
      responseType: 'user_login_companion_processed',
      data: {
        'userId': userId,
        'companionReady': true,
        'personality': _personality.toString(),
      },
    );
  }

  /// Handle user logout events
  Future<AgentEventResponse?> _handleUserLogout(AgentEvent event) async {
    // Save companion data
    await _saveCompanionData();

    // Clear session data
    _memory.shortTermMemory.clear();
    _currentUserId = null;

    return createResponse(
      originalEventId: event.id,
      responseType: 'user_logout_companion_processed',
      data: {'companionDataSaved': true},
    );
  }

  @override
  Future<void> onDispose() async {
    // Stop timers
    _proactiveTimer?.cancel();
    _moodUpdateTimer?.cancel();

    // Save all data
    await _saveCompanionData();

    developer.log('AI Companion Agent disposed', name: agentId);
  }
}