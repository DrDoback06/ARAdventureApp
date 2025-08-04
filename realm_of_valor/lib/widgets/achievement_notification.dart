import 'package:flutter/material.dart';
import '../constants/theme.dart';

class AchievementNotification extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color? backgroundColor;
  final Color? iconColor;
  final Duration duration;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const AchievementNotification({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.backgroundColor,
    this.iconColor,
    this.duration = const Duration(seconds: 4),
    this.onTap,
    this.onDismiss,
  });

  @override
  State<AchievementNotification> createState() => _AchievementNotificationState();
}

class _AchievementNotificationState extends State<AchievementNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _showNotification();
  }

  void _showNotification() async {
    await _animationController.forward();
    
    // Auto-dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _hideNotification();
      }
    });
  }

  void _hideNotification() async {
    await _animationController.reverse();
    if (mounted && widget.onDismiss != null) {
      widget.onDismiss!();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 100),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: _buildNotificationContent(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationContent() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? RealmOfValorTheme.accentGold,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.iconColor ?? Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.backgroundColor ?? RealmOfValorTheme.accentGold,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.message,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Close button
                IconButton(
                  onPressed: _hideNotification,
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AchievementNotificationManager {
  static final AchievementNotificationManager _instance = AchievementNotificationManager._internal();
  factory AchievementNotificationManager() => _instance;
  AchievementNotificationManager._internal();

  final List<AchievementNotification> _notifications = [];
  final List<VoidCallback> _dismissCallbacks = [];

  void showAchievement({
    required String title,
    required String message,
    IconData icon = Icons.emoji_events,
    Color? backgroundColor,
    Color? iconColor,
    Duration? duration,
    VoidCallback? onTap,
  }) {
    print('DEBUG: Showing achievement notification: $title');
    
    AchievementNotification? notification;
    notification = AchievementNotification(
      title: title,
      message: message,
      icon: icon,
      backgroundColor: backgroundColor,
      iconColor: iconColor,
      duration: duration ?? const Duration(seconds: 4),
      onTap: onTap,
      onDismiss: () => _removeNotification(notification!),
    );

    _notifications.add(notification);
    _dismissCallbacks.forEach((callback) => callback());
  }

  void showLevelUp({
    required int newLevel,
    required String characterName,
  }) {
    showAchievement(
      title: 'Level Up!',
      message: '$characterName reached level $newLevel!',
      icon: Icons.trending_up,
      backgroundColor: RealmOfValorTheme.accentGold,
      iconColor: Colors.white,
      duration: const Duration(seconds: 5),
    );
  }

  void showQuestCompleted({
    required String questName,
    required int experience,
    required int gold,
  }) {
    showAchievement(
      title: 'Quest Completed!',
      message: '$questName completed! +$experience XP, +$gold Gold',
      icon: Icons.assignment_turned_in,
      backgroundColor: Colors.green,
      iconColor: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  void showItemFound({
    required String itemName,
    required String rarity,
  }) {
    Color backgroundColor;
    switch (rarity.toLowerCase()) {
      case 'legendary':
        backgroundColor = Colors.orange;
        break;
      case 'epic':
        backgroundColor = Colors.purple;
        break;
      case 'rare':
        backgroundColor = Colors.blue;
        break;
      default:
        backgroundColor = Colors.grey;
    }

    showAchievement(
      title: 'Item Found!',
      message: 'Found $itemName ($rarity)',
      icon: Icons.inventory,
      backgroundColor: backgroundColor,
      iconColor: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  void showActivityMilestone({
    required String activityType,
    required String milestone,
  }) {
    showAchievement(
      title: 'Activity Milestone!',
      message: '$activityType: $milestone',
      icon: Icons.fitness_center,
      backgroundColor: Colors.teal,
      iconColor: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  void _removeNotification(AchievementNotification notification) {
    _notifications.remove(notification);
  }

  void addDismissCallback(VoidCallback callback) {
    _dismissCallbacks.add(callback);
  }

  void removeDismissCallback(VoidCallback callback) {
    _dismissCallbacks.remove(callback);
  }

  List<AchievementNotification> get notifications => List.unmodifiable(_notifications);
} 