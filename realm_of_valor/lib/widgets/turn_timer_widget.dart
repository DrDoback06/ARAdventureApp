import 'package:flutter/material.dart';
import 'dart:async';

class TurnTimerWidget extends StatefulWidget {
  final int totalSeconds;
  final int remainingSeconds;
  final VoidCallback? onTimeUp;
  final bool isActive;

  const TurnTimerWidget({
    super.key,
    required this.totalSeconds,
    required this.remainingSeconds,
    this.onTimeUp,
    this.isActive = false,
  });

  @override
  State<TurnTimerWidget> createState() => _TurnTimerWidgetState();
}

class _TurnTimerWidgetState extends State<TurnTimerWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _shakeAnimation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );

    _startPulseAnimation();
  }

  @override
  void didUpdateWidget(TurnTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Start urgent animations when time is low
    if (widget.remainingSeconds <= 10 && widget.remainingSeconds > 0) {
      _pulseController.repeat(reverse: true);
      if (widget.remainingSeconds <= 3) {
        _shakeController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _shakeController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startPulseAnimation() {
    if (widget.remainingSeconds <= 10 && widget.remainingSeconds > 0) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return const SizedBox.shrink();
    }

    final percentage = widget.remainingSeconds / widget.totalSeconds;
    final isUrgent = widget.remainingSeconds <= 10;
    final isCritical = widget.remainingSeconds <= 3;

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _shakeAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getTimerColor(isUrgent, isCritical).withOpacity(0.9),
                    _getTimerColor(isUrgent, isCritical).withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getTimerColor(isUrgent, isCritical),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getTimerColor(isUrgent, isCritical).withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Timer icon
                  Icon(
                    Icons.timer,
                    color: Colors.white,
                    size: 20,
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Time display
                  Text(
                    '${widget.remainingSeconds}s',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isUrgent ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Progress bar
                  Container(
                    width: 60,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: percentage,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3),
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

  Color _getTimerColor(bool isUrgent, bool isCritical) {
    if (isCritical) {
      return Colors.red;
    } else if (isUrgent) {
      return Colors.orange;
    } else {
      return const Color(0xFFe94560);
    }
  }
} 