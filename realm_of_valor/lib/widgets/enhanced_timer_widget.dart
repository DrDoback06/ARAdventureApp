import 'package:flutter/material.dart';
import 'dart:async';
import '../constants/theme.dart';

class EnhancedTimerWidget extends StatefulWidget {
  final int totalSeconds;
  final int remainingSeconds;
  final VoidCallback? onTimeUp;
  final bool isActive;
  final String? playerName;

  const EnhancedTimerWidget({
    super.key,
    required this.totalSeconds,
    required this.remainingSeconds,
    this.onTimeUp,
    this.isActive = false,
    this.playerName,
  });

  @override
  State<EnhancedTimerWidget> createState() => _EnhancedTimerWidgetState();
}

class _EnhancedTimerWidgetState extends State<EnhancedTimerWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<double> _glowAnimation;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _shakeAnimation = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
    
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _startAnimations();
  }

  @override
  void didUpdateWidget(EnhancedTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isActive != oldWidget.isActive) {
      _startAnimations();
    }
    
    // Update animations based on remaining time
    _updateAnimations();
  }

  void _startAnimations() {
    if (widget.isActive) {
      _updateTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        _updateAnimations();
      });
    } else {
      _updateTimer?.cancel();
      _pulseController.stop();
      _shakeController.stop();
      _glowController.stop();
    }
  }

  void _updateAnimations() {
    if (!widget.isActive) return;
    
    final percentage = widget.remainingSeconds / widget.totalSeconds;
    
    if (percentage <= 0.25) {
      // Critical time - intense animations
      _pulseController.repeat(reverse: true);
      _shakeController.repeat(reverse: true);
      _glowController.repeat(reverse: true);
    } else if (percentage <= 0.5) {
      // Warning time - moderate animations
      _pulseController.repeat(reverse: true);
      _shakeController.stop();
      _glowController.repeat(reverse: true);
    } else {
      // Normal time - subtle animations
      _pulseController.stop();
      _shakeController.stop();
      _glowController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    _glowController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return const SizedBox.shrink();
    }

    final percentage = widget.remainingSeconds / widget.totalSeconds;
    final isUrgent = percentage <= 0.25;
    final isWarning = percentage <= 0.5;

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _shakeAnimation, _glowAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getTimerColor(isUrgent, isWarning).withOpacity(0.9),
                    _getTimerColor(isUrgent, isWarning).withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: _getTimerColor(isUrgent, isWarning),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getTimerColor(isUrgent, isWarning).withOpacity(_glowAnimation.value * 0.6),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Timer icon with animation
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Icon(
                          Icons.timer,
                          color: Colors.white,
                          size: 24,
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Time display
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.remainingSeconds}s',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isUrgent ? 22 : 20,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              offset: const Offset(1, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                      if (widget.playerName != null)
                        Text(
                          widget.playerName!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Progress bar
                  Container(
                    width: 80,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: percentage,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              Colors.white.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
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
    );
  }

  Color _getTimerColor(bool isUrgent, bool isWarning) {
    if (isUrgent) {
      return Colors.red;
    } else if (isWarning) {
      return Colors.orange;
    } else {
      return const Color(0xFFe94560);
    }
  }
} 