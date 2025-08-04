import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../models/quest_model.dart';

/// Enhanced Quest Pin Widget with animated avatars for different quest types
class EnhancedQuestPinWidget extends StatefulWidget {
  final Quest quest;
  final double size;
  final VoidCallback? onTap;
  final bool isActive;
  final bool isPulsing;

  const EnhancedQuestPinWidget({
    Key? key,
    required this.quest,
    this.size = 60.0,
    this.onTap,
    this.isActive = false,
    this.isPulsing = true,
  }) : super(key: key);

  @override
  State<EnhancedQuestPinWidget> createState() => _EnhancedQuestPinWidgetState();
}

class _EnhancedQuestPinWidgetState extends State<EnhancedQuestPinWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _bounceController;
  late AnimationController _rotationController;
  late AnimationController _glowController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation for quest availability
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Bounce animation for interaction feedback
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    // Rotation animation for special quests
    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_rotationController);

    // Glow animation for rare/legendary quests
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Start animations based on quest properties
    if (widget.isPulsing) {
      _pulseController.repeat(reverse: true);
    }

    if (_isSpecialQuest()) {
      _rotationController.repeat();
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bounceController.dispose();
    _rotationController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  bool _isSpecialQuest() {
    return widget.quest.difficulty == QuestDifficulty.expert ||
           widget.quest.metadata['legendary'] == true ||
           widget.quest.metadata['milestone_celebration'] == true;
  }

  QuestPinStyle _getQuestPinStyle() {
    switch (widget.quest.type) {
      case QuestType.fitness:
        return QuestPinStyle(
          avatar: '💪',
          primaryColor: Colors.green,
          secondaryColor: Colors.lightGreen,
          borderColor: Colors.greenAccent,
          shadowColor: Colors.green.withOpacity(0.6),
        );
      case QuestType.walking:
        return QuestPinStyle(
          avatar: '🚶‍♂️',
          primaryColor: Colors.blue,
          secondaryColor: Colors.lightBlue,
          borderColor: Colors.blueAccent,
          shadowColor: Colors.blue.withOpacity(0.6),
        );
      case QuestType.running:
        return QuestPinStyle(
          avatar: '🏃‍♂️',
          primaryColor: Colors.orange,
          secondaryColor: Colors.deepOrange,
          borderColor: Colors.orangeAccent,
          shadowColor: Colors.orange.withOpacity(0.6),
        );
      case QuestType.climbing:
        return QuestPinStyle(
          avatar: '🧗‍♂️',
          primaryColor: Colors.brown,
          secondaryColor: Colors.brown.shade300,
          borderColor: Colors.brown.shade400,
          shadowColor: Colors.brown.withOpacity(0.6),
        );
      case QuestType.exploration:
        return QuestPinStyle(
          avatar: '🗺️',
          primaryColor: Colors.purple,
          secondaryColor: Colors.purpleAccent,
          borderColor: Colors.deepPurple,
          shadowColor: Colors.purple.withOpacity(0.6),
        );
      case QuestType.collection:
        return QuestPinStyle(
          avatar: '📦',
          primaryColor: Colors.indigo,
          secondaryColor: Colors.indigoAccent,
          borderColor: Colors.indigo.shade400,
          shadowColor: Colors.indigo.withOpacity(0.6),
        );
      case QuestType.battle:
        return QuestPinStyle(
          avatar: '⚔️',
          primaryColor: Colors.red,
          secondaryColor: Colors.redAccent,
          borderColor: Colors.red.shade400,
          shadowColor: Colors.red.withOpacity(0.6),
        );
      case QuestType.social:
        return QuestPinStyle(
          avatar: '👥',
          primaryColor: Colors.pink,
          secondaryColor: Colors.pinkAccent,
          borderColor: Colors.pink.shade400,
          shadowColor: Colors.pink.withOpacity(0.6),
        );
      case QuestType.location:
        return QuestPinStyle(
          avatar: '📍',
          primaryColor: Colors.teal,
          secondaryColor: Colors.tealAccent,
          borderColor: Colors.teal.shade400,
          shadowColor: Colors.teal.withOpacity(0.6),
        );
    }
  }

  Widget _buildDifficultyIndicator(QuestPinStyle style) {
    final difficultyColors = {
      QuestDifficulty.easy: Colors.green,
      QuestDifficulty.medium: Colors.yellow,
      QuestDifficulty.hard: Colors.orange,
      QuestDifficulty.expert: Colors.red,
    };

    final difficultyIcons = {
      QuestDifficulty.easy: '⭐',
      QuestDifficulty.medium: '⭐⭐',
      QuestDifficulty.hard: '⭐⭐⭐',
      QuestDifficulty.expert: '💎',
    };

    return Positioned(
      top: -2,
      right: -2,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: difficultyColors[widget.quest.difficulty],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Text(
          difficultyIcons[widget.quest.difficulty] ?? '⭐',
          style: const TextStyle(fontSize: 8),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    if (widget.quest.objectives.isEmpty) return const SizedBox.shrink();

    final totalObjectives = widget.quest.objectives.length;
    final completedObjectives = widget.quest.objectives
        .where((obj) => obj.isCompleted)
        .length;
    final progress = totalObjectives > 0 ? completedObjectives / totalObjectives : 0.0;

    if (progress == 0) return const SizedBox.shrink();

    return Positioned(
      bottom: -3,
      left: widget.size * 0.1,
      right: widget.size * 0.1,
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          color: Colors.grey.shade300,
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: progress == 1.0 ? Colors.green : Colors.blue,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialEffects(QuestPinStyle style) {
    if (!_isSpecialQuest()) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: widget.size * 1.5,
          height: widget.size * 1.5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: style.primaryColor.withOpacity(_glowAnimation.value * 0.8),
                blurRadius: 20 * _glowAnimation.value,
                spreadRadius: 5 * _glowAnimation.value,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuestTypeLabel(QuestPinStyle style) {
    return Positioned(
      bottom: -20,
      left: -30,
      right: -30,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: style.primaryColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Text(
          widget.quest.type.name.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = _getQuestPinStyle();

    return GestureDetector(
      onTap: () {
        _bounceController.forward().then((_) {
          _bounceController.reverse();
        });
        widget.onTap?.call();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _pulseAnimation,
          _bounceAnimation,
          _rotationAnimation,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value * _bounceAnimation.value,
            child: Transform.rotate(
              angle: _isSpecialQuest() ? _rotationAnimation.value : 0,
              child: SizedBox(
                width: widget.size * 1.8,
                height: widget.size * 1.8,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Special effects for rare quests
                    _buildSpecialEffects(style),
                    
                    // Main quest pin
                    Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            style.secondaryColor,
                            style.primaryColor,
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.isActive ? Colors.white : style.borderColor,
                          width: widget.isActive ? 3 : 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: style.shadowColor,
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                          if (widget.isActive)
                            BoxShadow(
                              color: Colors.white.withOpacity(0.8),
                              blurRadius: 12,
                              spreadRadius: 3,
                            ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          style.avatar,
                          style: TextStyle(
                            fontSize: widget.size * 0.4,
                          ),
                        ),
                      ),
                    ),

                    // Difficulty indicator
                    _buildDifficultyIndicator(style),

                    // Progress indicator
                    _buildProgressIndicator(),

                    // Quest type label
                    _buildQuestTypeLabel(style),

                    // Active quest indicator
                    if (widget.isActive)
                      Positioned(
                        top: -8,
                        left: -8,
                        right: -8,
                        bottom: -8,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class QuestPinStyle {
  final String avatar;
  final Color primaryColor;
  final Color secondaryColor;
  final Color borderColor;
  final Color shadowColor;

  const QuestPinStyle({
    required this.avatar,
    required this.primaryColor,
    required this.secondaryColor,
    required this.borderColor,
    required this.shadowColor,
  });
}

/// Quest Pin Collection Widget for grouping multiple quests in the same area
class QuestPinCollectionWidget extends StatefulWidget {
  final List<Quest> quests;
  final double size;
  final VoidCallback? onTap;

  const QuestPinCollectionWidget({
    Key? key,
    required this.quests,
    this.size = 60.0,
    this.onTap,
  }) : super(key: key);

  @override
  State<QuestPinCollectionWidget> createState() => _QuestPinCollectionWidgetState();
}

class _QuestPinCollectionWidgetState extends State<QuestPinCollectionWidget>
    with TickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleExpansion,
      child: AnimatedBuilder(
        animation: _expandAnimation,
        builder: (context, child) {
          return SizedBox(
            width: widget.size * 3,
            height: widget.size * 3,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Main collection indicator
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    gradient: const RadialGradient(
                      colors: [
                        Colors.purple,
                        Colors.deepPurple,
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.6),
                        blurRadius: 12,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '📚',
                      style: TextStyle(fontSize: widget.size * 0.4),
                    ),
                  ),
                ),

                // Quest count indicator
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      '${widget.quests.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Expanded quest pins
                if (_isExpanded)
                  ...widget.quests.asMap().entries.map((entry) {
                    final index = entry.key;
                    final quest = entry.value;
                    final angle = (2 * math.pi * index) / widget.quests.length;
                    final radius = widget.size * 1.2 * _expandAnimation.value;
                    
                    return Transform.translate(
                      offset: Offset(
                        radius * math.cos(angle),
                        radius * math.sin(angle),
                      ),
                      child: Transform.scale(
                        scale: 0.8 * _expandAnimation.value,
                        child: EnhancedQuestPinWidget(
                          quest: quest,
                          size: widget.size * 0.7,
                          isPulsing: false,
                          onTap: () {
                            widget.onTap?.call();
                          },
                        ),
                      ),
                    );
                  }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}