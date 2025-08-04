import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Practical AI Memory Service
/// Implements realistic memory capabilities for the AI companion
class PracticalAIMemoryService {
  static const String version = '1.0.0';
  static const int maxConversationHistory = 100;
  static const int maxPreferenceEntries = 50;
  static const int maxContextMemories = 30;
  
  final SharedPreferences _prefs;
  
  // Memory categories
  final Map<String, dynamic> _shortTermMemory = {};
  final Map<String, dynamic> _userPreferences = {};
  final List<ConversationEntry> _conversationHistory = [];
  final Map<String, int> _topicFrequency = {};
  final Map<String, DateTime> _lastInteractions = {};
  final Map<String, List<String>> _helpfulResponses = {};
  final Map<String, UserContext> _userContexts = {};
  
  PracticalAIMemoryService({required SharedPreferences prefs}) : _prefs = prefs;

  /// Initialize the memory service
  Future<void> initialize() async {
    await _loadMemoryFromStorage();
    await _cleanupOldMemories();
  }

  /// Store a conversation exchange
  Future<void> rememberConversation({
    required String userMessage,
    required String aiResponse,
    required String interactionType,
    required double satisfactionRating,
  }) async {
    final entry = ConversationEntry(
      timestamp: DateTime.now(),
      userMessage: userMessage,
      aiResponse: aiResponse,
      interactionType: interactionType,
      satisfactionRating: satisfactionRating,
      context: _getCurrentContext(),
    );
    
    _conversationHistory.add(entry);
    
    // Keep only recent conversations
    if (_conversationHistory.length > maxConversationHistory) {
      _conversationHistory.removeAt(0);
    }
    
    // Update topic frequency
    final topics = _extractTopics(userMessage);
    for (final topic in topics) {
      _topicFrequency[topic] = (_topicFrequency[topic] ?? 0) + 1;
    }
    
    // Remember helpful responses
    if (satisfactionRating >= 4.0) {
      _rememberHelpfulResponse(interactionType, aiResponse);
    }
    
    await _saveMemoryToStorage();
  }

  /// Learn user preferences from interactions
  Future<void> learnUserPreference({
    required String category,
    required String preference,
    required double confidence,
  }) async {
    final key = '${category}_$preference';
    final existing = _userPreferences[key] ?? 0.0;
    
    // Update preference with weighted average
    final newConfidence = (existing + confidence) / 2;
    _userPreferences[key] = newConfidence.clamp(0.0, 1.0);
    
    // Remove low-confidence preferences to save space
    _userPreferences.removeWhere((key, value) => value < 0.3);
    
    // Limit total preferences
    if (_userPreferences.length > maxPreferenceEntries) {
      final sortedEntries = _userPreferences.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      for (int i = 0; i < 10; i++) {
        _userPreferences.remove(sortedEntries[i].key);
      }
    }
    
    await _saveMemoryToStorage();
  }

  /// Remember user context and patterns
  Future<void> updateUserContext({
    required String userId,
    required String activityType,
    required Map<String, dynamic> contextData,
  }) async {
    final context = _userContexts[userId] ?? UserContext(userId: userId);
    
    context.lastActivity = DateTime.now();
    context.activityHistory.add(ActivityEntry(
      type: activityType,
      timestamp: DateTime.now(),
      data: contextData,
    ));
    
    // Keep only recent activities
    if (context.activityHistory.length > 20) {
      context.activityHistory.removeAt(0);
    }
    
    // Update patterns
    context.preferredTimes.add(DateTime.now().hour);
    if (context.preferredTimes.length > 50) {
      context.preferredTimes.removeAt(0);
    }
    
    // Update common difficulties
    if (contextData['difficulty'] != null) {
      final difficulty = contextData['difficulty'] as String;
      context.commonDifficulties[difficulty] = 
          (context.commonDifficulties[difficulty] ?? 0) + 1;
    }
    
    _userContexts[userId] = context;
    
    // Limit number of user contexts
    if (_userContexts.length > maxContextMemories) {
      final oldestUser = _userContexts.entries
          .reduce((a, b) => a.value.lastActivity.isBefore(b.value.lastActivity) ? a : b)
          .key;
      _userContexts.remove(oldestUser);
    }
    
    await _saveMemoryToStorage();
  }

  /// Get personalized greeting based on memory
  String getPersonalizedGreeting(String userId) {
    final context = _userContexts[userId];
    final timeOfDay = _getTimeOfDay();
    final lastInteraction = _lastInteractions[userId];
    
    String greeting = 'Hello there, adventurer!';
    
    if (context != null) {
      // Check preferred time patterns
      final currentHour = DateTime.now().hour;
      final preferredHours = context.preferredTimes;
      
      if (preferredHours.isNotEmpty) {
        final averageHour = preferredHours.reduce((a, b) => a + b) / preferredHours.length;
        if ((currentHour - averageHour).abs() < 2) {
          greeting = 'Perfect timing! Ready for our usual $timeOfDay adventure?';
        }
      }
      
      // Check activity patterns
      if (context.activityHistory.isNotEmpty) {
        final recentActivity = context.activityHistory.last;
        if (recentActivity.type == 'quest_completion') {
          greeting = 'Welcome back, quest master! Ready for your next challenge?';
        } else if (recentActivity.type == 'battle_victory') {
          greeting = 'Greetings, champion! Your battle prowess is impressive!';
        }
      }
    }
    
    // Check time since last interaction
    if (lastInteraction != null) {
      final daysSince = DateTime.now().difference(lastInteraction).inDays;
      if (daysSince > 7) {
        greeting = 'Welcome back! I\'ve missed our adventures together!';
      } else if (daysSince > 1) {
        greeting = 'Good to see you again! Ready to continue where we left off?';
      }
    }
    
    _lastInteractions[userId] = DateTime.now();
    return greeting;
  }

  /// Get contextual suggestions based on memory
  List<String> getContextualSuggestions(String userId) {
    final context = _userContexts[userId];
    final suggestions = <String>[];
    
    if (context == null) {
      return [
        'Try your first quest nearby',
        'Explore the card collection system',
        'Join a beginner-friendly guild',
      ];
    }
    
    // Suggest based on activity patterns
    final recentActivities = context.activityHistory
        .where((a) => DateTime.now().difference(a.timestamp).inDays < 7)
        .map((a) => a.type)
        .toList();
    
    if (!recentActivities.contains('quest_completion')) {
      suggestions.add('There are new quests waiting for you!');
    }
    
    if (!recentActivities.contains('battle_participation')) {
      suggestions.add('Practice battles to improve your skills');
    }
    
    if (!recentActivities.contains('social_interaction')) {
      suggestions.add('Connect with your guild for group adventures');
    }
    
    // Suggest based on common difficulties
    final mostCommonDifficulty = context.commonDifficulties.entries
        .fold<MapEntry<String, int>?>(null, (prev, current) =>
            prev == null || current.value > prev.value ? current : prev);
    
    if (mostCommonDifficulty != null) {
      switch (mostCommonDifficulty.key) {
        case 'easy':
          suggestions.add('Ready to try a medium difficulty challenge?');
          break;
        case 'medium':
          suggestions.add('You\'re doing great! Consider a hard challenge');
          break;
        case 'hard':
          suggestions.add('Impressive skills! Expert level awaits');
          break;
      }
    }
    
    // Suggest based on preferred times
    if (context.preferredTimes.isNotEmpty) {
      final currentHour = DateTime.now().hour;
      final averageHour = context.preferredTimes.reduce((a, b) => a + b) / context.preferredTimes.length;
      
      if ((currentHour - averageHour).abs() < 1) {
        suggestions.add('This is your favorite time to play! Perfect for a big adventure');
      }
    }
    
    return suggestions.take(3).toList();
  }

  /// Get relevant help based on past struggles
  String getRelevantHelp(String currentIssue) {
    // Check if we've helped with similar issues before
    final similarResponses = _helpfulResponses[currentIssue] ?? [];
    
    if (similarResponses.isNotEmpty) {
      return 'I remember helping with something similar before. ${similarResponses.last}';
    }
    
    // Look for related topics in conversation history
    final relatedConversations = _conversationHistory
        .where((c) => c.userMessage.toLowerCase().contains(currentIssue.toLowerCase()))
        .where((c) => c.satisfactionRating >= 4.0)
        .toList();
    
    if (relatedConversations.isNotEmpty) {
      final bestResponse = relatedConversations
          .reduce((a, b) => a.satisfactionRating > b.satisfactionRating ? a : b);
      return 'Based on our previous discussions, ${bestResponse.aiResponse}';
    }
    
    return 'Let me help you with that! I\'m learning about this topic.';
  }

  /// Get user preferences for a category
  Map<String, double> getUserPreferences(String category) {
    final categoryPrefs = <String, double>{};
    
    _userPreferences.forEach((key, value) {
      if (key.startsWith('${category}_')) {
        final prefName = key.substring(category.length + 1);
        categoryPrefs[prefName] = value;
      }
    });
    
    return categoryPrefs;
  }

  /// Get conversation insights
  ConversationInsights getConversationInsights() {
    final totalConversations = _conversationHistory.length;
    final averageSatisfaction = _conversationHistory.isEmpty ? 0.0 :
        _conversationHistory.map((c) => c.satisfactionRating).reduce((a, b) => a + b) / totalConversations;
    
    final topTopics = _topicFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final commonInteractionTypes = <String, int>{};
    for (final conversation in _conversationHistory) {
      commonInteractionTypes[conversation.interactionType] = 
          (commonInteractionTypes[conversation.interactionType] ?? 0) + 1;
    }
    
    return ConversationInsights(
      totalConversations: totalConversations,
      averageSatisfaction: averageSatisfaction,
      topTopics: topTopics.take(5).map((e) => e.key).toList(),
      commonInteractionTypes: commonInteractionTypes,
      memoryHealthScore: _calculateMemoryHealth(),
    );
  }

  /// Clear old or irrelevant memories
  Future<void> cleanupMemories() async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    
    // Remove old conversations
    _conversationHistory.removeWhere((c) => c.timestamp.isBefore(cutoffDate));
    
    // Remove old user contexts
    _userContexts.removeWhere((key, context) => 
        context.lastActivity.isBefore(cutoffDate));
    
    // Remove low-frequency topics
    _topicFrequency.removeWhere((key, value) => value < 3);
    
    // Remove old interaction timestamps
    _lastInteractions.removeWhere((key, timestamp) => 
        timestamp.isBefore(cutoffDate));
    
    await _saveMemoryToStorage();
  }

  // Private helper methods
  Future<void> _loadMemoryFromStorage() async {
    try {
      // Load conversation history
      final conversationJson = _prefs.getString('ai_conversation_history');
      if (conversationJson != null) {
        final List<dynamic> conversations = jsonDecode(conversationJson);
        _conversationHistory.clear();
        _conversationHistory.addAll(
          conversations.map((c) => ConversationEntry.fromJson(c)).toList()
        );
      }
      
      // Load user preferences
      final preferencesJson = _prefs.getString('ai_user_preferences');
      if (preferencesJson != null) {
        final Map<String, dynamic> prefs = jsonDecode(preferencesJson);
        _userPreferences.clear();
        _userPreferences.addAll(prefs.cast<String, double>());
      }
      
      // Load topic frequency
      final topicJson = _prefs.getString('ai_topic_frequency');
      if (topicJson != null) {
        final Map<String, dynamic> topics = jsonDecode(topicJson);
        _topicFrequency.clear();
        _topicFrequency.addAll(topics.cast<String, int>());
      }
      
      // Load user contexts
      final contextJson = _prefs.getString('ai_user_contexts');
      if (contextJson != null) {
        final Map<String, dynamic> contexts = jsonDecode(contextJson);
        _userContexts.clear();
        contexts.forEach((key, value) {
          _userContexts[key] = UserContext.fromJson(value);
        });
      }
      
    } catch (e) {
      print('Error loading AI memory: $e');
    }
  }

  Future<void> _saveMemoryToStorage() async {
    try {
      // Save conversation history
      final conversationJson = jsonEncode(
        _conversationHistory.map((c) => c.toJson()).toList()
      );
      await _prefs.setString('ai_conversation_history', conversationJson);
      
      // Save user preferences
      final preferencesJson = jsonEncode(_userPreferences);
      await _prefs.setString('ai_user_preferences', preferencesJson);
      
      // Save topic frequency
      final topicJson = jsonEncode(_topicFrequency);
      await _prefs.setString('ai_topic_frequency', topicJson);
      
      // Save user contexts
      final contextJson = jsonEncode(
        _userContexts.map((key, value) => MapEntry(key, value.toJson()))
      );
      await _prefs.setString('ai_user_contexts', contextJson);
      
    } catch (e) {
      print('Error saving AI memory: $e');
    }
  }

  Future<void> _cleanupOldMemories() async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 60));
    
    _conversationHistory.removeWhere((c) => c.timestamp.isBefore(cutoffDate));
    _userContexts.removeWhere((key, context) => 
        context.lastActivity.isBefore(cutoffDate));
    
    await _saveMemoryToStorage();
  }

  List<String> _extractTopics(String message) {
    final topics = <String>[];
    final lowerMessage = message.toLowerCase();
    
    // Define topic keywords
    final topicKeywords = {
      'cards': ['card', 'deck', 'collection', 'scan'],
      'battles': ['battle', 'fight', 'combat', 'tournament'],
      'quests': ['quest', 'adventure', 'mission', 'explore'],
      'fitness': ['steps', 'walking', 'exercise', 'health'],
      'guilds': ['guild', 'friends', 'social', 'team'],
      'ar': ['ar', 'camera', 'augmented', 'reality'],
      'help': ['help', 'problem', 'issue', 'stuck'],
      'tutorial': ['tutorial', 'learn', 'how', 'guide'],
    };
    
    topicKeywords.forEach((topic, keywords) {
      if (keywords.any((keyword) => lowerMessage.contains(keyword))) {
        topics.add(topic);
      }
    });
    
    return topics;
  }

  String _getCurrentContext() {
    final hour = DateTime.now().hour;
    final day = DateTime.now().weekday;
    
    String timeContext = 'morning';
    if (hour >= 12 && hour < 17) timeContext = 'afternoon';
    if (hour >= 17 && hour < 21) timeContext = 'evening';
    if (hour >= 21 || hour < 6) timeContext = 'night';
    
    String dayContext = 'weekday';
    if (day == 6 || day == 7) dayContext = 'weekend';
    
    return '${timeContext}_$dayContext';
  }

  void _rememberHelpfulResponse(String interactionType, String response) {
    final responses = _helpfulResponses[interactionType] ?? [];
    responses.add(response);
    
    // Keep only recent helpful responses
    if (responses.length > 5) {
      responses.removeAt(0);
    }
    
    _helpfulResponses[interactionType] = responses;
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }

  double _calculateMemoryHealth() {
    double health = 1.0;
    
    // Check conversation recency
    if (_conversationHistory.isNotEmpty) {
      final lastConversation = _conversationHistory.last;
      final daysSinceLastConversation = DateTime.now().difference(lastConversation.timestamp).inDays;
      if (daysSinceLastConversation > 7) health -= 0.2;
    } else {
      health -= 0.3;
    }
    
    // Check preference diversity
    if (_userPreferences.length < 5) health -= 0.1;
    
    // Check topic coverage
    if (_topicFrequency.length < 3) health -= 0.1;
    
    return health.clamp(0.0, 1.0);
  }
}

// Supporting classes
class ConversationEntry {
  final DateTime timestamp;
  final String userMessage;
  final String aiResponse;
  final String interactionType;
  final double satisfactionRating;
  final String context;

  ConversationEntry({
    required this.timestamp,
    required this.userMessage,
    required this.aiResponse,
    required this.interactionType,
    required this.satisfactionRating,
    required this.context,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'userMessage': userMessage,
    'aiResponse': aiResponse,
    'interactionType': interactionType,
    'satisfactionRating': satisfactionRating,
    'context': context,
  };

  factory ConversationEntry.fromJson(Map<String, dynamic> json) =>
      ConversationEntry(
        timestamp: DateTime.parse(json['timestamp']),
        userMessage: json['userMessage'],
        aiResponse: json['aiResponse'],
        interactionType: json['interactionType'],
        satisfactionRating: json['satisfactionRating'].toDouble(),
        context: json['context'],
      );
}

class UserContext {
  final String userId;
  DateTime lastActivity;
  final List<ActivityEntry> activityHistory;
  final List<int> preferredTimes;
  final Map<String, int> commonDifficulties;

  UserContext({
    required this.userId,
    DateTime? lastActivity,
    List<ActivityEntry>? activityHistory,
    List<int>? preferredTimes,
    Map<String, int>? commonDifficulties,
  }) : lastActivity = lastActivity ?? DateTime.now(),
       activityHistory = activityHistory ?? [],
       preferredTimes = preferredTimes ?? [],
       commonDifficulties = commonDifficulties ?? {};

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'lastActivity': lastActivity.toIso8601String(),
    'activityHistory': activityHistory.map((a) => a.toJson()).toList(),
    'preferredTimes': preferredTimes,
    'commonDifficulties': commonDifficulties,
  };

  factory UserContext.fromJson(Map<String, dynamic> json) => UserContext(
    userId: json['userId'],
    lastActivity: DateTime.parse(json['lastActivity']),
    activityHistory: (json['activityHistory'] as List)
        .map((a) => ActivityEntry.fromJson(a))
        .toList(),
    preferredTimes: List<int>.from(json['preferredTimes']),
    commonDifficulties: Map<String, int>.from(json['commonDifficulties']),
  );
}

class ActivityEntry {
  final String type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  ActivityEntry({
    required this.type,
    required this.timestamp,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'timestamp': timestamp.toIso8601String(),
    'data': data,
  };

  factory ActivityEntry.fromJson(Map<String, dynamic> json) => ActivityEntry(
    type: json['type'],
    timestamp: DateTime.parse(json['timestamp']),
    data: Map<String, dynamic>.from(json['data']),
  );
}

class ConversationInsights {
  final int totalConversations;
  final double averageSatisfaction;
  final List<String> topTopics;
  final Map<String, int> commonInteractionTypes;
  final double memoryHealthScore;

  ConversationInsights({
    required this.totalConversations,
    required this.averageSatisfaction,
    required this.topTopics,
    required this.commonInteractionTypes,
    required this.memoryHealthScore,
  });
}