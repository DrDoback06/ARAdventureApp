import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

class AccessibilityService {
  static final AccessibilityService _instance = AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  bool _isScreenReaderEnabled = false;
  bool _isHighContrastEnabled = false;
  bool _isLargeTextEnabled = false;
  double _textScaleFactor = 1.0;

  bool get isScreenReaderEnabled => _isScreenReaderEnabled;
  bool get isHighContrastEnabled => _isHighContrastEnabled;
  bool get isLargeTextEnabled => _isLargeTextEnabled;
  double get textScaleFactor => _textScaleFactor;

  void initialize(BuildContext context) {
    _updateAccessibilitySettings(context);
    print('DEBUG: Accessibility service initialized');
  }

  void _updateAccessibilitySettings(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    _isScreenReaderEnabled = mediaQuery.accessibleNavigation;
    _isHighContrastEnabled = mediaQuery.highContrast;
    _isLargeTextEnabled = mediaQuery.textScaleFactor > 1.0;
    _textScaleFactor = mediaQuery.textScaleFactor;
    
    print('DEBUG: Accessibility settings updated - ScreenReader: $_isScreenReaderEnabled, HighContrast: $_isHighContrastEnabled, LargeText: $_isLargeTextEnabled');
  }

  String getAccessibleLabel(String text, {String? context}) {
    if (!_isScreenReaderEnabled) return text;
    
    if (context != null) {
      return '$context: $text';
    }
    return text;
  }

  String getAccessibleHint(String hint) {
    if (!_isScreenReaderEnabled) return hint;
    return hint;
  }

  Color getAccessibleColor(Color baseColor, {bool isImportant = false}) {
    if (!_isHighContrastEnabled) return baseColor;
    
    // Increase contrast for high contrast mode
    if (isImportant) {
      return baseColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    }
    
    return baseColor;
  }

  double getAccessibleFontSize(double baseSize) {
    return baseSize * _textScaleFactor;
  }

  EdgeInsets getAccessiblePadding(EdgeInsets basePadding) {
    if (_isLargeTextEnabled) {
      return EdgeInsets.all(basePadding.left * 1.2);
    }
    return basePadding;
  }

  double getAccessibleIconSize(double baseSize) {
    if (_isLargeTextEnabled) {
      return baseSize * 1.2;
    }
    return baseSize;
  }

  Widget makeAccessible({
    required Widget child,
    String? label,
    String? hint,
    bool isButton = false,
    bool isHeading = false,
    bool isImage = false,
  }) {
    return Semantics(
      label: label != null ? getAccessibleLabel(label) : null,
      hint: hint != null ? getAccessibleHint(hint) : null,
      button: isButton,
      header: isHeading,
      image: isImage,
      child: child,
    );
  }

  Widget makeButtonAccessible({
    required Widget child,
    required String label,
    String? hint,
    VoidCallback? onPressed,
  }) {
    return Semantics(
      label: getAccessibleLabel(label),
      hint: hint != null ? getAccessibleHint(hint) : null,
      button: true,
      enabled: onPressed != null,
      child: child,
    );
  }

  Widget makeHeadingAccessible({
    required Widget child,
    required String label,
    int level = 1,
  }) {
    return Semantics(
      label: getAccessibleLabel(label),
      header: true,
      child: child,
    );
  }

  Widget makeImageAccessible({
    required Widget child,
    required String label,
    String? description,
  }) {
    return Semantics(
      label: getAccessibleLabel(label),
      hint: description != null ? getAccessibleHint(description) : null,
      image: true,
      child: child,
    );
  }

  Widget makeListAccessible({
    required Widget child,
    required String label,
    int itemCount = 0,
  }) {
    return Semantics(
      label: getAccessibleLabel(label),
      child: child,
    );
  }

  Widget makeProgressAccessible({
    required Widget child,
    required String label,
    required double value,
    double maxValue = 1.0,
  }) {
    final percentage = ((value / maxValue) * 100).round();
    return Semantics(
      label: getAccessibleLabel(label),
      value: '$percentage%',
      child: child,
    );
  }

  Widget makeStatusAccessible({
    required Widget child,
    required String label,
    required String status,
  }) {
    return Semantics(
      label: getAccessibleLabel(label),
      value: status,
      child: child,
    );
  }

  String getCharacterStatsLabel(String characterName, Map<String, int> stats) {
    if (!_isScreenReaderEnabled) return '';
    
    final statStrings = stats.entries.map((entry) {
      return '${entry.key}: ${entry.value}';
    }).join(', ');
    
    return getAccessibleLabel('$characterName stats: $statStrings');
  }

  String getQuestLabel(String questTitle, String status, int experience, int gold) {
    if (!_isScreenReaderEnabled) return '';
    
    return getAccessibleLabel(
      '$questTitle quest, status: $status, rewards: $experience experience, $gold gold',
      context: 'Quest'
    );
  }

  String getItemLabel(String itemName, String rarity, String type) {
    if (!_isScreenReaderEnabled) return '';
    
    return getAccessibleLabel(
      '$itemName, $rarity $type',
      context: 'Item'
    );
  }

  String getActivityLabel(String activityType, String status, int duration) {
    if (!_isScreenReaderEnabled) return '';
    
    return getAccessibleLabel(
      '$activityType activity, $status, duration: $duration minutes',
      context: 'Activity'
    );
  }

  String getNotificationLabel(String title, String message) {
    if (!_isScreenReaderEnabled) return '';
    
    return getAccessibleLabel(
      '$title: $message',
      context: 'Notification'
    );
  }

  void announceToScreenReader(String message) {
    if (_isScreenReaderEnabled) {
      SemanticsService.announce(message, TextDirection.ltr);
      print('DEBUG: Announced to screen reader: $message');
    }
  }

  void announceAchievement(String achievement) {
    announceToScreenReader('Achievement unlocked: $achievement');
  }

  void announceLevelUp(String characterName, int newLevel) {
    announceToScreenReader('$characterName reached level $newLevel!');
  }

  void announceQuestCompleted(String questName) {
    announceToScreenReader('Quest completed: $questName');
  }

  void announceItemFound(String itemName, String rarity) {
    announceToScreenReader('Found $rarity item: $itemName');
  }

  void announceActivityMilestone(String activityType, String milestone) {
    announceToScreenReader('$activityType milestone: $milestone');
  }
} 