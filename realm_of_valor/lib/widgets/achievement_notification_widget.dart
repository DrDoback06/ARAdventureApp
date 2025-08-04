import 'package:flutter/material.dart';
import '../services/achievement_service.dart';
import '../constants/theme.dart';

class AchievementNotificationWidget extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback? onDismiss;

  const AchievementNotificationWidget({
    super.key,
    required this.achievement,
    this.onDismiss,
  });

  @override
  State<AchievementNotificationWidget> createState() => _AchievementNotificationWidgetState();
}

class _AchievementNotificationWidgetState extends State<AchievementNotificationWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _glowController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    _startAnimation();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _startAnimation() {
    _slideController.forward();
    _glowController.repeat(reverse: true);
    
    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _slideController.reverse().then((_) {
          widget.onDismiss?.call();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: widget.achievement.rarityColor.withOpacity(0.3 * _glowAnimation.value),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: _buildNotificationContent(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.achievement.rarityColor.withOpacity(0.2),
            RealmOfValorTheme.surfaceDark,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.achievement.rarityColor,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Achievement Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: widget.achievement.rarityColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.achievement.rarityColor,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                _getAchievementIcon(widget.achievement),
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Achievement Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: RealmOfValorTheme.accentGold,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Achievement Unlocked!',
                      style: TextStyle(
                        color: widget.achievement.rarityColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.achievement.title,
                  style: const TextStyle(
                    color: RealmOfValorTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.achievement.description,
                  style: const TextStyle(
                    color: RealmOfValorTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.achievement.rarityColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getRarityName(widget.achievement.tier),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Dismiss Button
          IconButton(
            onPressed: () {
              _slideController.reverse().then((_) {
                widget.onDismiss?.call();
              });
            },
            icon: const Icon(
              Icons.close,
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _getAchievementIcon(Achievement achievement) {
    // Return a default icon based on achievement category
    switch (achievement.category) {
      case AchievementCategory.collection:
        return '📚';
      case AchievementCategory.exploration:
        return '🗺️';
      case AchievementCategory.fitness:
        return '💪';
      case AchievementCategory.battle:
        return '⚔️';
      case AchievementCategory.social:
        return '👥';
      case AchievementCategory.progression:
        return '📈';
      case AchievementCategory.special:
        return '⭐';
    }
  }

  String _getRarityName(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return 'Bronze';
      case AchievementTier.silver:
        return 'Silver';
      case AchievementTier.gold:
        return 'Gold';
      case AchievementTier.platinum:
        return 'Platinum';
    }
  }
}

class AchievementNotificationOverlay extends StatefulWidget {
  final Widget child;

  const AchievementNotificationOverlay({
    super.key,
    required this.child,
  });

  @override
  State<AchievementNotificationOverlay> createState() => _AchievementNotificationOverlayState();
}

class _AchievementNotificationOverlayState extends State<AchievementNotificationOverlay> {
  final List<Achievement> _pendingNotifications = [];
  final AchievementService _achievementService = AchievementService.instance;

  @override
  void initState() {
    super.initState();
    _achievementService.addListener(_onAchievementUnlocked);
  }

  @override
  void dispose() {
    _achievementService.removeListener(_onAchievementUnlocked);
    super.dispose();
  }

  void _onAchievementUnlocked() {
    final recentUnlocks = _achievementService.recentUnlocks;
    for (final achievementId in recentUnlocks) {
      final achievement = _achievementService.getAchievement(achievementId);
      if (achievement != null && achievement.unlockedAt != null) {
        _showNotification(achievement);
      }
    }
  }

  void _showNotification(Achievement achievement) {
    setState(() {
      _pendingNotifications.add(achievement);
    });
  }

  void _dismissNotification(Achievement achievement) {
    setState(() {
      _pendingNotifications.remove(achievement);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Achievement notifications
        ..._pendingNotifications.map((achievement) {
          return Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AchievementNotificationWidget(
              achievement: achievement,
              onDismiss: () => _dismissNotification(achievement),
            ),
          );
        }).toList(),
      ],
    );
  }
} 