import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/adventure_system.dart';
import 'adventure_progression_service.dart';

enum JournalEntryType {
  milestone,
  achievement,
  discovery,
  social,
  seasonal,
  rare_encounter,
  personal_record,
  memory,
}

enum JournalMood {
  excited,
  proud,
  adventurous,
  peaceful,
  accomplished,
  surprised,
  grateful,
  determined,
}

class JournalEntry {
  final String id;
  final String title;
  final String description;
  final JournalEntryType type;
  final DateTime timestamp;
  final GeoLocation? location;
  final String? locationName;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final List<String> imageUrls;
  final JournalMood mood;
  final int importance; // 1-5 scale
  final bool isFavorite;
  final Map<String, dynamic> stats;
  final String? weatherCondition;

  JournalEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.timestamp,
    this.location,
    this.locationName,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    List<String>? imageUrls,
    this.mood = JournalMood.adventurous,
    this.importance = 3,
    this.isFavorite = false,
    Map<String, dynamic>? stats,
    this.weatherCondition,
  }) : tags = tags ?? [],
       metadata = metadata ?? {},
       imageUrls = imageUrls ?? [],
       stats = stats ?? {};

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: JournalEntryType.values[json['type'] ?? 0],
      timestamp: DateTime.parse(json['timestamp']),
      location: json['location'] != null 
          ? GeoLocation.fromJson(json['location'])
          : null,
      locationName: json['locationName'],
      tags: List<String>.from(json['tags'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      mood: JournalMood.values[json['mood'] ?? 0],
      importance: json['importance'] ?? 3,
      isFavorite: json['isFavorite'] ?? false,
      stats: Map<String, dynamic>.from(json['stats'] ?? {}),
      weatherCondition: json['weatherCondition'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.index,
      'timestamp': timestamp.toIso8601String(),
      'location': location?.toJson(),
      'locationName': locationName,
      'tags': tags,
      'metadata': metadata,
      'imageUrls': imageUrls,
      'mood': mood.index,
      'importance': importance,
      'isFavorite': isFavorite,
      'stats': stats,
      'weatherCondition': weatherCondition,
    };
  }

  JournalEntry copyWith({
    bool? isFavorite,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return JournalEntry(
      id: id,
      title: title,
      description: description,
      type: type,
      timestamp: timestamp,
      location: location,
      locationName: locationName,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      imageUrls: imageUrls,
      mood: mood,
      importance: importance,
      isFavorite: isFavorite ?? this.isFavorite,
      stats: stats,
      weatherCondition: weatherCondition,
    );
  }
}

class AdventureMemory {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> relatedEntryIds;
  final Map<String, dynamic> summary;
  final List<String> highlights;
  final String memoryType; // week, month, season, achievement_series

  AdventureMemory({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.relatedEntryIds,
    required this.summary,
    required this.highlights,
    required this.memoryType,
  });

  factory AdventureMemory.fromJson(Map<String, dynamic> json) {
    return AdventureMemory(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      relatedEntryIds: List<String>.from(json['relatedEntryIds']),
      summary: Map<String, dynamic>.from(json['summary']),
      highlights: List<String>.from(json['highlights']),
      memoryType: json['memoryType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'relatedEntryIds': relatedEntryIds,
      'summary': summary,
      'highlights': highlights,
      'memoryType': memoryType,
    };
  }
}

class AdventureStats {
  final int totalEntries;
  final int favoriteEntries;
  final Map<JournalEntryType, int> entriesByType;
  final Map<JournalMood, int> entriesByMood;
  final Map<String, int> locationVisits;
  final List<String> mostUsedTags;
  final DateTime? firstEntry;
  final DateTime? lastEntry;
  final int streakDays;
  final Map<String, dynamic> personalRecords;

  AdventureStats({
    this.totalEntries = 0,
    this.favoriteEntries = 0,
    Map<JournalEntryType, int>? entriesByType,
    Map<JournalMood, int>? entriesByMood,
    Map<String, int>? locationVisits,
    List<String>? mostUsedTags,
    this.firstEntry,
    this.lastEntry,
    this.streakDays = 0,
    Map<String, dynamic>? personalRecords,
  }) : entriesByType = entriesByType ?? {},
       entriesByMood = entriesByMood ?? {},
       locationVisits = locationVisits ?? {},
       mostUsedTags = mostUsedTags ?? [],
       personalRecords = personalRecords ?? {};
}

class AdventureJournalService {
  static final AdventureJournalService _instance = AdventureJournalService._internal();
  factory AdventureJournalService() => _instance;
  AdventureJournalService._internal();

  final StreamController<List<JournalEntry>> _entriesController = StreamController.broadcast();
  final StreamController<JournalEntry> _newEntryController = StreamController.broadcast();
  final StreamController<List<AdventureMemory>> _memoriesController = StreamController.broadcast();

  Stream<List<JournalEntry>> get entriesStream => _entriesController.stream;
  Stream<JournalEntry> get newEntryStream => _newEntryController.stream;
  Stream<List<AdventureMemory>> get memoriesStream => _memoriesController.stream;

  List<JournalEntry> _journalEntries = [];
  List<AdventureMemory> _adventureMemories = [];
  String? _playerId;
  Timer? _memoryGenerationTimer;

  // Initialize journal service
  Future<void> initialize(String playerId) async {
    _playerId = playerId;
    await _loadJournalData();
    _startMemoryGenerationTimer();
    _entriesController.add(_journalEntries);
    _memoriesController.add(_adventureMemories);
  }

  // Auto-log adventure milestone
  Future<void> logMilestone({
    required String title,
    required String description,
    GeoLocation? location,
    String? locationName,
    Map<String, dynamic>? stats,
    List<String>? tags,
    JournalMood mood = JournalMood.accomplished,
    int importance = 4,
    String? weatherCondition,
  }) async {
    final entry = JournalEntry(
      id: _generateEntryId(),
      title: title,
      description: description,
      type: JournalEntryType.milestone,
      timestamp: DateTime.now(),
      location: location,
      locationName: locationName,
      tags: tags ?? [],
      mood: mood,
      importance: importance,
      stats: stats ?? {},
      weatherCondition: weatherCondition,
    );

    await _addEntry(entry);
  }

  // Auto-log achievement
  Future<void> logAchievement({
    required String achievementName,
    required String description,
    Map<String, dynamic>? rewards,
    GeoLocation? location,
    JournalMood mood = JournalMood.proud,
  }) async {
    final entry = JournalEntry(
      id: _generateEntryId(),
      title: '🏆 Achievement Unlocked: $achievementName',
      description: description,
      type: JournalEntryType.achievement,
      timestamp: DateTime.now(),
      location: location,
      tags: ['achievement', 'milestone'],
      mood: mood,
      importance: 4,
      metadata: {'rewards': rewards},
    );

    await _addEntry(entry);
  }

  // Auto-log new discovery
  Future<void> logDiscovery({
    required String title,
    required String description,
    required GeoLocation location,
    String? locationName,
    String? discoveryType,
    JournalMood mood = JournalMood.excited,
  }) async {
    final entry = JournalEntry(
      id: _generateEntryId(),
      title: '🔍 New Discovery: $title',
      description: description,
      type: JournalEntryType.discovery,
      timestamp: DateTime.now(),
      location: location,
      locationName: locationName,
      tags: ['discovery', discoveryType].where((tag) => tag != null).cast<String>().toList(),
      mood: mood,
      importance: 3,
    );

    await _addEntry(entry);
  }

  // Auto-log social interaction
  Future<void> logSocialInteraction({
    required String title,
    required String description,
    String? friendName,
    String? activityType,
    Map<String, dynamic>? results,
    JournalMood mood = JournalMood.grateful,
  }) async {
    final entry = JournalEntry(
      id: _generateEntryId(),
      title: '👥 $title',
      description: description,
      type: JournalEntryType.social,
      timestamp: DateTime.now(),
      tags: ['social', activityType, friendName].where((tag) => tag != null).cast<String>().toList(),
      mood: mood,
      importance: 3,
      metadata: {'results': results, 'friend': friendName},
    );

    await _addEntry(entry);
  }

  // Auto-log rare encounter
  Future<void> logRareEncounter({
    required String encounterName,
    required String description,
    required GeoLocation location,
    String? encounterType,
    Map<String, dynamic>? rewards,
    JournalMood mood = JournalMood.surprised,
  }) async {
    final entry = JournalEntry(
      id: _generateEntryId(),
      title: '✨ Rare Encounter: $encounterName',
      description: description,
      type: JournalEntryType.rare_encounter,
      timestamp: DateTime.now(),
      location: location,
      tags: ['rare', 'encounter', encounterType].where((tag) => tag != null).cast<String>().toList(),
      mood: mood,
      importance: 5,
      metadata: {'rewards': rewards, 'encounter_type': encounterType},
    );

    await _addEntry(entry);
  }

  // Auto-log personal record
  Future<void> logPersonalRecord({
    required String recordType,
    required String description,
    required dynamic recordValue,
    dynamic previousRecord,
    Map<String, dynamic>? stats,
    JournalMood mood = JournalMood.proud,
  }) async {
    final improvementText = previousRecord != null 
        ? ' (Previous: $previousRecord)' 
        : '';

    final entry = JournalEntry(
      id: _generateEntryId(),
      title: '📈 Personal Record: $recordType',
      description: '$description$improvementText',
      type: JournalEntryType.personal_record,
      timestamp: DateTime.now(),
      tags: ['record', 'achievement', recordType.toLowerCase().replaceAll(' ', '_')],
      mood: mood,
      importance: 4,
      stats: stats ?? {},
      metadata: {
        'record_type': recordType,
        'new_value': recordValue,
        'previous_value': previousRecord,
      },
    );

    await _addEntry(entry);
  }

  // Auto-log seasonal moment
  Future<void> logSeasonalMoment({
    required String seasonalEvent,
    required String description,
    GeoLocation? location,
    String? weatherCondition,
    JournalMood mood = JournalMood.peaceful,
  }) async {
    final entry = JournalEntry(
      id: _generateEntryId(),
      title: '🌿 Seasonal: $seasonalEvent',
      description: description,
      type: JournalEntryType.seasonal,
      timestamp: DateTime.now(),
      location: location,
      tags: ['seasonal', seasonalEvent.toLowerCase()],
      mood: mood,
      importance: 3,
      weatherCondition: weatherCondition,
    );

    await _addEntry(entry);
  }

  // Manually add journal entry
  Future<void> addManualEntry({
    required String title,
    required String description,
    GeoLocation? location,
    String? locationName,
    List<String>? tags,
    JournalMood mood = JournalMood.adventurous,
    int importance = 3,
    List<String>? imageUrls,
  }) async {
    final entry = JournalEntry(
      id: _generateEntryId(),
      title: title,
      description: description,
      type: JournalEntryType.memory,
      timestamp: DateTime.now(),
      location: location,
      locationName: locationName,
      tags: tags ?? [],
      mood: mood,
      importance: importance,
      imageUrls: imageUrls ?? [],
    );

    await _addEntry(entry);
  }

  // Get entries with filters
  List<JournalEntry> getEntries({
    JournalEntryType? type,
    JournalMood? mood,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? tags,
    bool? isFavorite,
    int? minImportance,
  }) {
    var filteredEntries = List<JournalEntry>.from(_journalEntries);

    if (type != null) {
      filteredEntries = filteredEntries.where((entry) => entry.type == type).toList();
    }

    if (mood != null) {
      filteredEntries = filteredEntries.where((entry) => entry.mood == mood).toList();
    }

    if (startDate != null) {
      filteredEntries = filteredEntries.where((entry) => 
          entry.timestamp.isAfter(startDate) || entry.timestamp.isAtSameMomentAs(startDate)
      ).toList();
    }

    if (endDate != null) {
      filteredEntries = filteredEntries.where((entry) => 
          entry.timestamp.isBefore(endDate) || entry.timestamp.isAtSameMomentAs(endDate)
      ).toList();
    }

    if (tags != null && tags.isNotEmpty) {
      filteredEntries = filteredEntries.where((entry) => 
          tags.any((tag) => entry.tags.contains(tag))
      ).toList();
    }

    if (isFavorite != null) {
      filteredEntries = filteredEntries.where((entry) => entry.isFavorite == isFavorite).toList();
    }

    if (minImportance != null) {
      filteredEntries = filteredEntries.where((entry) => entry.importance >= minImportance).toList();
    }

    return filteredEntries..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Get favorite entries
  List<JournalEntry> getFavoriteEntries() {
    return _journalEntries.where((entry) => entry.isFavorite).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Toggle favorite status
  Future<void> toggleFavorite(String entryId) async {
    final index = _journalEntries.indexWhere((entry) => entry.id == entryId);
    if (index != -1) {
      final entry = _journalEntries[index];
      _journalEntries[index] = entry.copyWith(isFavorite: !entry.isFavorite);
      
      await _saveJournalData();
      _entriesController.add(_journalEntries);
    }
  }

  // Add tags to entry
  Future<void> addTagsToEntry(String entryId, List<String> newTags) async {
    final index = _journalEntries.indexWhere((entry) => entry.id == entryId);
    if (index != -1) {
      final entry = _journalEntries[index];
      final updatedTags = List<String>.from(entry.tags);
      
      for (final tag in newTags) {
        if (!updatedTags.contains(tag)) {
          updatedTags.add(tag);
        }
      }
      
      _journalEntries[index] = entry.copyWith(tags: updatedTags);
      
      await _saveJournalData();
      _entriesController.add(_journalEntries);
    }
  }

  // Get journal statistics
  AdventureStats getJournalStats() {
    if (_journalEntries.isEmpty) {
      return AdventureStats();
    }

    final entriesByType = <JournalEntryType, int>{};
    final entriesByMood = <JournalMood, int>{};
    final locationVisits = <String, int>{};
    final allTags = <String>[];

    for (final entry in _journalEntries) {
      entriesByType[entry.type] = (entriesByType[entry.type] ?? 0) + 1;
      entriesByMood[entry.mood] = (entriesByMood[entry.mood] ?? 0) + 1;
      
      if (entry.locationName != null) {
        locationVisits[entry.locationName!] = (locationVisits[entry.locationName!] ?? 0) + 1;
      }
      
      allTags.addAll(entry.tags);
    }

    // Get most used tags
    final tagCounts = <String, int>{};
    for (final tag in allTags) {
      tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
    }
    
    final mostUsedTags = tagCounts.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

    final sortedEntries = List<JournalEntry>.from(_journalEntries)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return AdventureStats(
      totalEntries: _journalEntries.length,
      favoriteEntries: _journalEntries.where((entry) => entry.isFavorite).length,
      entriesByType: entriesByType,
      entriesByMood: entriesByMood,
      locationVisits: locationVisits,
      mostUsedTags: mostUsedTags.take(10).map((e) => e.key).toList(),
      firstEntry: sortedEntries.isNotEmpty ? sortedEntries.first.timestamp : null,
      lastEntry: sortedEntries.isNotEmpty ? sortedEntries.last.timestamp : null,
      streakDays: _calculateStreakDays(),
    );
  }

  // Generate adventure memories
  Future<void> generateMemories() async {
    final now = DateTime.now();
    
    // Generate weekly memory
    await _generateWeeklyMemory(now);
    
    // Generate monthly memory
    await _generateMonthlyMemory(now);
    
    // Generate seasonal memory
    await _generateSeasonalMemory(now);

    _memoriesController.add(_adventureMemories);
  }

  // Get adventure memories
  List<AdventureMemory> getMemories({String? memoryType}) {
    if (memoryType != null) {
      return _adventureMemories.where((memory) => memory.memoryType == memoryType).toList();
    }
    return _adventureMemories;
  }

  // Generate personalized insights
  List<String> generatePersonalizedInsights() {
    final stats = getJournalStats();
    final insights = <String>[];

    if (stats.totalEntries >= 10) {
      final topMood = stats.entriesByMood.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      insights.add('Your most common adventure mood is ${topMood.key.toString().split('.').last}! 😊');
    }

    if (stats.favoriteEntries >= 5) {
      insights.add('You\'ve marked ${stats.favoriteEntries} memories as favorites. They must be special! ⭐');
    }

    if (stats.streakDays >= 7) {
      insights.add('Amazing! You\'ve been journaling for ${stats.streakDays} days straight! 🔥');
    }

    final topLocations = stats.locationVisits.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    if (topLocations.isNotEmpty) {
      insights.add('${topLocations.first.key} seems to be your favorite adventure spot! 📍');
    }

    if (stats.entriesByType[JournalEntryType.achievement] != null && 
        stats.entriesByType[JournalEntryType.achievement]! >= 5) {
      insights.add('You\'re an achievement hunter with ${stats.entriesByType[JournalEntryType.achievement]} unlocked! 🏆');
    }

    return insights;
  }

  // Private helper methods
  Future<void> _addEntry(JournalEntry entry) async {
    _journalEntries.add(entry);
    _journalEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    await _saveJournalData();
    _entriesController.add(_journalEntries);
    _newEntryController.add(entry);
  }

  String _generateEntryId() {
    return 'journal_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}';
  }

  int _calculateStreakDays() {
    if (_journalEntries.isEmpty) return 0;

    final sortedEntries = List<JournalEntry>.from(_journalEntries)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    var streak = 1;
    var currentDate = DateTime(
      sortedEntries.first.timestamp.year,
      sortedEntries.first.timestamp.month,
      sortedEntries.first.timestamp.day,
    );

    for (int i = 1; i < sortedEntries.length; i++) {
      final entryDate = DateTime(
        sortedEntries[i].timestamp.year,
        sortedEntries[i].timestamp.month,
        sortedEntries[i].timestamp.day,
      );

      final expectedDate = currentDate.subtract(const Duration(days: 1));
      
      if (entryDate.isAtSameMomentAs(expectedDate)) {
        streak++;
        currentDate = entryDate;
      } else if (entryDate.isBefore(expectedDate)) {
        break;
      }
    }

    return streak;
  }

  Future<void> _generateWeeklyMemory(DateTime now) async {
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    
    final weekEntries = _journalEntries.where((entry) =>
        entry.timestamp.isAfter(weekStart) && entry.timestamp.isBefore(weekEnd)
    ).toList();

    if (weekEntries.length >= 3) {
      final memory = AdventureMemory(
        id: 'week_${weekStart.millisecondsSinceEpoch}',
        title: 'Week of Adventures',
        description: _generateWeekSummary(weekEntries),
        startDate: weekStart,
        endDate: weekEnd,
        relatedEntryIds: weekEntries.map((e) => e.id).toList(),
        summary: _generateWeekStats(weekEntries),
        highlights: _generateWeekHighlights(weekEntries),
        memoryType: 'week',
      );

      _adventureMemories.add(memory);
    }
  }

  Future<void> _generateMonthlyMemory(DateTime now) async {
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    
    final monthEntries = _journalEntries.where((entry) =>
        entry.timestamp.isAfter(monthStart) && entry.timestamp.isBefore(monthEnd)
    ).toList();

    if (monthEntries.length >= 10) {
      final memory = AdventureMemory(
        id: 'month_${monthStart.millisecondsSinceEpoch}',
        title: 'Monthly Adventure Summary',
        description: _generateMonthSummary(monthEntries),
        startDate: monthStart,
        endDate: monthEnd,
        relatedEntryIds: monthEntries.map((e) => e.id).toList(),
        summary: _generateMonthStats(monthEntries),
        highlights: _generateMonthHighlights(monthEntries),
        memoryType: 'month',
      );

      _adventureMemories.add(memory);
    }
  }

  Future<void> _generateSeasonalMemory(DateTime now) async {
    // Implementation for seasonal memories
  }

  String _generateWeekSummary(List<JournalEntry> entries) {
    final achievements = entries.where((e) => e.type == JournalEntryType.achievement).length;
    final discoveries = entries.where((e) => e.type == JournalEntryType.discovery).length;
    
    return 'This week you had $achievements achievements and made $discoveries new discoveries! '
           'Your adventures took you to ${entries.map((e) => e.locationName).where((name) => name != null).toSet().length} different places.';
  }

  Map<String, dynamic> _generateWeekStats(List<JournalEntry> entries) {
    return {
      'total_entries': entries.length,
      'achievements': entries.where((e) => e.type == JournalEntryType.achievement).length,
      'discoveries': entries.where((e) => e.type == JournalEntryType.discovery).length,
      'social_activities': entries.where((e) => e.type == JournalEntryType.social).length,
    };
  }

  List<String> _generateWeekHighlights(List<JournalEntry> entries) {
    final highlights = <String>[];
    
    final rareEncounters = entries.where((e) => e.type == JournalEntryType.rare_encounter);
    for (final encounter in rareEncounters) {
      highlights.add('🌟 ${encounter.title}');
    }
    
    final achievements = entries.where((e) => e.type == JournalEntryType.achievement);
    for (final achievement in achievements.take(3)) {
      highlights.add('🏆 ${achievement.title}');
    }
    
    return highlights;
  }

  String _generateMonthSummary(List<JournalEntry> entries) {
    return 'What an incredible month of adventures! You created ${entries.length} memories '
           'and visited ${entries.map((e) => e.locationName).where((name) => name != null).toSet().length} unique locations.';
  }

  Map<String, dynamic> _generateMonthStats(List<JournalEntry> entries) {
    return {
      'total_entries': entries.length,
      'unique_locations': entries.map((e) => e.locationName).where((name) => name != null).toSet().length,
      'favorite_count': entries.where((e) => e.isFavorite).length,
    };
  }

  List<String> _generateMonthHighlights(List<JournalEntry> entries) {
    final sortedByImportance = List<JournalEntry>.from(entries)
      ..sort((a, b) => b.importance.compareTo(a.importance));
    
    return sortedByImportance.take(5).map((entry) => entry.title).toList();
  }

  void _startMemoryGenerationTimer() {
    _memoryGenerationTimer = Timer.periodic(const Duration(hours: 24), (timer) {
      generateMemories();
    });
  }

  // Data persistence
  Future<void> _saveJournalData() async {
    if (_playerId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = jsonEncode(_journalEntries.map((entry) => entry.toJson()).toList());
      final memoriesJson = jsonEncode(_adventureMemories.map((memory) => memory.toJson()).toList());
      
      await prefs.setString('journal_entries_$_playerId', entriesJson);
      await prefs.setString('adventure_memories_$_playerId', memoriesJson);
    } catch (e) {
      print('Error saving journal data: $e');
    }
  }

  Future<void> _loadJournalData() async {
    if (_playerId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = prefs.getString('journal_entries_$_playerId');
      final memoriesJson = prefs.getString('adventure_memories_$_playerId');

      if (entriesJson != null) {
        final entriesList = jsonDecode(entriesJson) as List;
        _journalEntries = entriesList
            .map((json) => JournalEntry.fromJson(json))
            .toList();
        _journalEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }

      if (memoriesJson != null) {
        final memoriesList = jsonDecode(memoriesJson) as List;
        _adventureMemories = memoriesList
            .map((json) => AdventureMemory.fromJson(json))
            .toList();
      }
    } catch (e) {
      print('Error loading journal data: $e');
    }
  }

  // Cleanup
  void dispose() {
    _entriesController.close();
    _newEntryController.close();
    _memoriesController.close();
    _memoryGenerationTimer?.cancel();
  }
}