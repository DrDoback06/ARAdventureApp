import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../services/window_persistence_service.dart';
import '../services/accessibility_service.dart';
import 'character_sheet_content.dart';
import 'inventory_content.dart';
import 'settings_content.dart';
import 'social_content.dart';
import 'skills_content.dart';
import 'quest_content.dart';
import 'dart:math' as math;

enum WindowType {
  characterSheet,
  inventory,
  skills,
  quests,
  social,
  settings,
}

class MobileWindowManager extends StatefulWidget {
  final Widget child;

  const MobileWindowManager({
    super.key,
    required this.child,
  });

  @override
  State<MobileWindowManager> createState() => _MobileWindowManagerState();
}

class _MobileWindowManagerState extends State<MobileWindowManager> {
  final Map<WindowType, bool> _windowStates = {};
  final WindowPersistenceService _persistenceService = WindowPersistenceService();
  final AccessibilityService _accessibilityService = AccessibilityService();
  
  @override
  void initState() {
    super.initState();
    _loadWindowStates();
  }

  Future<void> _loadWindowStates() async {
    final savedStates = await _persistenceService.loadWindowStates();
    
    setState(() {
      for (WindowType type in WindowType.values) {
        final key = type.toString().split('.').last;
        _windowStates[type] = savedStates[key] ?? false;
      }
    });
    
    print('DEBUG: Loaded window states: $_windowStates');
  }

  void toggleWindow(WindowType type) {
    setState(() {
      _windowStates[type] = !(_windowStates[type] ?? false);
    });
    _saveWindowStates();
  }

  Future<void> _saveWindowStates() async {
    final states = <String, bool>{};
    for (final entry in _windowStates.entries) {
      final key = entry.key.toString().split('.').last;
      states[key] = entry.value;
    }
    await _persistenceService.saveWindowStates(states);
  }

  bool isWindowOpen(WindowType type) {
    return _windowStates[type] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content
        widget.child,
        
        // Floating Action Buttons
        Positioned(
          bottom: 20,
          right: 20,
          child: Column(
            children: [
              _buildFloatingActionButton(
                icon: Icons.person,
                label: 'Character',
                onPressed: () {
                  print('DEBUG: Character button pressed');
                  toggleWindow(WindowType.characterSheet);
                },
                isActive: isWindowOpen(WindowType.characterSheet),
                heroTag: 'character_fab',
              ),
              const SizedBox(height: 12),
              _buildFloatingActionButton(
                icon: Icons.inventory,
                label: 'Inventory',
                onPressed: () {
                  print('DEBUG: Inventory button pressed');
                  toggleWindow(WindowType.inventory);
                },
                isActive: isWindowOpen(WindowType.inventory),
                heroTag: 'inventory_fab',
              ),
              const SizedBox(height: 12),
              _buildFloatingActionButton(
                icon: Icons.account_tree,
                label: 'Skills',
                onPressed: () {
                  print('DEBUG: Skills button pressed');
                  toggleWindow(WindowType.skills);
                },
                isActive: isWindowOpen(WindowType.skills),
                heroTag: 'skills_fab',
              ),
              const SizedBox(height: 12),
              _buildFloatingActionButton(
                icon: Icons.assignment,
                label: 'Quests',
                onPressed: () {
                  print('DEBUG: Quests button pressed');
                  toggleWindow(WindowType.quests);
                },
                isActive: isWindowOpen(WindowType.quests),
                heroTag: 'quests_fab',
              ),
              const SizedBox(height: 12),
              _buildFloatingActionButton(
                icon: Icons.people,
                label: 'Social',
                onPressed: () {
                  print('DEBUG: Social button pressed');
                  toggleWindow(WindowType.social);
                },
                isActive: isWindowOpen(WindowType.social),
                heroTag: 'social_fab',
              ),
              const SizedBox(height: 12),
              _buildFloatingActionButton(
                icon: Icons.settings,
                label: 'Settings',
                onPressed: () {
                  print('DEBUG: Settings button pressed');
                  toggleWindow(WindowType.settings);
                },
                isActive: isWindowOpen(WindowType.settings),
                heroTag: 'settings_fab',
              ),
            ],
          ),
        ),
        
        // Windows
        if (_windowStates[WindowType.characterSheet] == true)
          _buildCharacterSheetWindow(),
        if (_windowStates[WindowType.inventory] == true)
          _buildInventoryWindow(),
        if (_windowStates[WindowType.skills] == true)
          _buildSkillsWindow(),
        if (_windowStates[WindowType.quests] == true)
          _buildQuestsWindow(),
        if (_windowStates[WindowType.social] == true)
          _buildSocialWindow(),
        if (_windowStates[WindowType.settings] == true)
          _buildSettingsWindow(),
      ],
    );
  }

  Widget _buildFloatingActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isActive,
    required String heroTag,
  }) {
    final accessibleLabel = _accessibilityService.getAccessibleLabel(
      isActive ? 'Close $label' : 'Open $label',
      context: 'Window'
    );
    
    return _accessibilityService.makeButtonAccessible(
      label: accessibleLabel,
      hint: isActive ? 'Double tap to close $label window' : 'Double tap to open $label window',
      onPressed: onPressed,
      child: Column(
        children: [
          FloatingActionButton(
            heroTag: heroTag,
            onPressed: onPressed,
            backgroundColor: isActive 
                ? RealmOfValorTheme.accentGold 
                : RealmOfValorTheme.surfaceMedium,
            foregroundColor: isActive 
                ? Colors.white 
                : RealmOfValorTheme.accentGold,
            child: Icon(icon),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterSheetWindow() {
    return _buildBottomSheet(
      title: 'Character Sheet',
      onClose: () => toggleWindow(WindowType.characterSheet),
      child: const CharacterSheetContent(),
    );
  }

  Widget _buildInventoryWindow() {
    return _buildFullScreenOverlay(
      title: 'Inventory',
      onClose: () => toggleWindow(WindowType.inventory),
      child: const InventoryContent(),
    );
  }

  Widget _buildSkillsWindow() {
    return _buildFullScreenOverlay(
      title: 'Skills',
      onClose: () => toggleWindow(WindowType.skills),
      child: const SkillsContent(),
    );
  }

  Widget _buildQuestsWindow() {
    return _buildFullScreenOverlay(
      title: 'Quests',
      onClose: () => toggleWindow(WindowType.quests),
      child: const QuestContent(),
    );
  }

  Widget _buildSettingsWindow() {
    return _buildBottomSheet(
      title: 'Settings',
      onClose: () => toggleWindow(WindowType.settings),
      child: const SettingsContent(),
    );
  }

  Widget _buildBottomSheet({
    required String title,
    required VoidCallback onClose,
    required Widget child,
  }) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return GestureDetector(
          onPanEnd: (details) {
            // Detect diagonal swipes
            final velocity = details.velocity;
            final speed = math.sqrt(velocity.pixelsPerSecond.dx * velocity.pixelsPerSecond.dx + 
                          velocity.pixelsPerSecond.dy * velocity.pixelsPerSecond.dy);
            if (speed > 800) {
              final angle = math.atan2(velocity.pixelsPerSecond.dy, velocity.pixelsPerSecond.dx);
              if (angle > -0.5 && angle < 0.5) {
                // Right swipe
                print('DEBUG: Diagonal right swipe detected - closing window');
                _accessibilityService.announceToScreenReader('Window closed by swipe gesture');
                onClose();
              } else if (angle > 1.0 && angle < 2.0) {
                // Down swipe
                print('DEBUG: Diagonal down swipe detected - closing window');
                _accessibilityService.announceToScreenReader('Window closed by swipe gesture');
                onClose();
              }
            }
          },
          child: Material(
            color: RealmOfValorTheme.surfaceMedium,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            elevation: 10,
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: RealmOfValorTheme.textSecondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _accessibilityService.makeHeadingAccessible(
                        label: title,
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: RealmOfValorTheme.textPrimary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _accessibilityService.makeButtonAccessible(
                        label: 'Close $title window',
                        hint: 'Double tap to close window',
                        onPressed: onClose,
                        child: IconButton(
                          onPressed: onClose,
                          icon: const Icon(
                            Icons.close,
                            color: RealmOfValorTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: child,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFullScreenOverlay({
    required String title,
    required VoidCallback onClose,
    required Widget child,
  }) {
    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: GestureDetector(
          onPanEnd: (details) {
            // Detect diagonal swipes
            final velocity = details.velocity;
            final speed = math.sqrt(velocity.pixelsPerSecond.dx * velocity.pixelsPerSecond.dx + 
                          velocity.pixelsPerSecond.dy * velocity.pixelsPerSecond.dy);
            if (speed > 800) {
              final angle = math.atan2(velocity.pixelsPerSecond.dy, velocity.pixelsPerSecond.dx);
              if (angle > -0.5 && angle < 0.5) {
                // Right swipe
                print('DEBUG: Diagonal right swipe detected - closing window');
                _accessibilityService.announceToScreenReader('Window closed by swipe gesture');
                onClose();
              } else if (angle > 1.0 && angle < 2.0) {
                // Down swipe
                print('DEBUG: Diagonal down swipe detected - closing window');
                _accessibilityService.announceToScreenReader('Window closed by swipe gesture');
                onClose();
              }
            }
          },
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: RealmOfValorTheme.surfaceMedium,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _accessibilityService.makeHeadingAccessible(
                        label: title,
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: RealmOfValorTheme.textPrimary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _accessibilityService.makeButtonAccessible(
                        label: 'Close $title window',
                        hint: 'Double tap to close window',
                        onPressed: onClose,
                        child: IconButton(
                          onPressed: onClose,
                          icon: const Icon(
                            Icons.close,
                            color: RealmOfValorTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialWindow() {
    return _buildFullScreenOverlay(
      title: 'Social',
      onClose: () => toggleWindow(WindowType.social),
      child: const SocialContent(),
    );
  }
} 