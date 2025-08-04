import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WindowState {
  final String windowType;
  final bool isOpen;
  final Map<String, dynamic>? customData;

  WindowState({
    required this.windowType,
    required this.isOpen,
    this.customData,
  });

  Map<String, dynamic> toJson() {
    return {
      'windowType': windowType,
      'isOpen': isOpen,
      'customData': customData,
    };
  }

  factory WindowState.fromJson(Map<String, dynamic> json) {
    return WindowState(
      windowType: json['windowType'] as String,
      isOpen: json['isOpen'] as bool,
      customData: json['customData'] as Map<String, dynamic>?,
    );
  }
}

class QuestWidgetPosition {
  final String questId;
  final double x;
  final double y;
  final bool isExpanded;

  QuestWidgetPosition({
    required this.questId,
    required this.x,
    required this.y,
    required this.isExpanded,
  });

  Map<String, dynamic> toJson() {
    return {
      'questId': questId,
      'x': x,
      'y': y,
      'isExpanded': isExpanded,
    };
  }

  factory QuestWidgetPosition.fromJson(Map<String, dynamic> json) {
    return QuestWidgetPosition(
      questId: json['questId'] as String,
      x: json['x'] as double,
      y: json['y'] as double,
      isExpanded: json['isExpanded'] as bool,
    );
  }
}

class WindowPersistenceService {
  static final WindowPersistenceService _instance = WindowPersistenceService._internal();
  factory WindowPersistenceService() => _instance;
  WindowPersistenceService._internal();

  static const String _windowStatesKey = 'window_states';
  static const String _questPositionsKey = 'quest_positions';
  static const String _lastSessionKey = 'last_session';

  Future<void> saveWindowStates(Map<String, bool> windowStates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final states = windowStates.entries.map((entry) {
        return WindowState(
          windowType: entry.key,
          isOpen: entry.value,
        );
      }).toList();

      final jsonList = states.map((state) => state.toJson()).toList();
      await prefs.setString(_windowStatesKey, jsonEncode(jsonList));
      
      print('DEBUG: Saved window states: $windowStates');
    } catch (e) {
      print('DEBUG: Error saving window states: $e');
    }
  }

  Future<Map<String, bool>> loadWindowStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_windowStatesKey);
      
      if (jsonString != null) {
        final jsonList = jsonDecode(jsonString) as List;
        final states = jsonList.map((json) => WindowState.fromJson(json)).toList();
        
        final windowStates = <String, bool>{};
        for (final state in states) {
          windowStates[state.windowType] = state.isOpen;
        }
        
        print('DEBUG: Loaded window states: $windowStates');
        return windowStates;
      }
    } catch (e) {
      print('DEBUG: Error loading window states: $e');
    }
    
    return {};
  }

  Future<void> saveQuestPositions(List<QuestWidgetPosition> positions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = positions.map((pos) => pos.toJson()).toList();
      await prefs.setString(_questPositionsKey, jsonEncode(jsonList));
      
      print('DEBUG: Saved quest positions: ${positions.length} positions');
    } catch (e) {
      print('DEBUG: Error saving quest positions: $e');
    }
  }

  Future<List<QuestWidgetPosition>> loadQuestPositions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_questPositionsKey);
      
      if (jsonString != null) {
        final jsonList = jsonDecode(jsonString) as List;
        final positions = jsonList.map((json) => QuestWidgetPosition.fromJson(json)).toList();
        
        print('DEBUG: Loaded quest positions: ${positions.length} positions');
        return positions;
      }
    } catch (e) {
      print('DEBUG: Error loading quest positions: $e');
    }
    
    return [];
  }

  Future<void> saveLastSession(Map<String, dynamic> sessionData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSessionKey, jsonEncode(sessionData));
      
      print('DEBUG: Saved last session data');
    } catch (e) {
      print('DEBUG: Error saving last session: $e');
    }
  }

  Future<Map<String, dynamic>?> loadLastSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_lastSessionKey);
      
      if (jsonString != null) {
        final sessionData = jsonDecode(jsonString) as Map<String, dynamic>;
        print('DEBUG: Loaded last session data');
        return sessionData;
      }
    } catch (e) {
      print('DEBUG: Error loading last session: $e');
    }
    
    return null;
  }

  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_windowStatesKey);
      await prefs.remove(_questPositionsKey);
      await prefs.remove(_lastSessionKey);
      
      print('DEBUG: Cleared all window persistence data');
    } catch (e) {
      print('DEBUG: Error clearing data: $e');
    }
  }

  Future<void> saveCustomData(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_$key', jsonEncode(data));
      
      print('DEBUG: Saved custom data for key: $key');
    } catch (e) {
      print('DEBUG: Error saving custom data: $e');
    }
  }

  Future<Map<String, dynamic>?> loadCustomData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('custom_$key');
      
      if (jsonString != null) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        print('DEBUG: Loaded custom data for key: $key');
        return data;
      }
    } catch (e) {
      print('DEBUG: Error loading custom data: $e');
    }
    
    return null;
  }
} 