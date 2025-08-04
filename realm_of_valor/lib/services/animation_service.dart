import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

enum HapticFeedbackType {
  lightImpact,
  mediumImpact,
  heavyImpact,
  selectionClick,
  successNotification,
  warningNotification,
  errorNotification,
}

enum AnimationType {
  fadeIn,
  fadeOut,
  slideIn,
  slideOut,
  scaleIn,
  scaleOut,
  rotate,
  bounce,
  shake,
  pulse,
  glow,
  shimmer,
  particle,
  ripple,
  morph,
}

enum AnimationCurve {
  linear,
  easeIn,
  easeOut,
  easeInOut,
  elastic,
  bounce,
  back,
}

class AnimationConfig {
  final AnimationType type;
  final Duration duration;
  final AnimationCurve curve;
  final double? delay;
  final bool repeat;
  final int? repeatCount;
  final bool reverse;
  final Map<String, dynamic>? properties;

  AnimationConfig({
    required this.type,
    required this.duration,
    this.curve = AnimationCurve.easeInOut,
    this.delay,
    this.repeat = false,
    this.repeatCount,
    this.reverse = false,
    this.properties,
  });

  Curve get flutterCurve {
    switch (curve) {
      case AnimationCurve.linear:
        return Curves.linear;
      case AnimationCurve.easeIn:
        return Curves.easeIn;
      case AnimationCurve.easeOut:
        return Curves.easeOut;
      case AnimationCurve.easeInOut:
        return Curves.easeInOut;
      case AnimationCurve.elastic:
        return Curves.elasticIn;
      case AnimationCurve.bounce:
        return Curves.bounceIn;
      case AnimationCurve.back:
        return Curves.easeInBack;
    }
  }
}

class AnimationService extends ChangeNotifier {
  static AnimationService? _instance;
  static AnimationService get instance => _instance ??= AnimationService._();
  
  AnimationService._();
  
  bool _isEnabled = true;
  bool _isReducedMotion = false;
  Map<String, AnimationController> _controllers = {};
  Map<String, Animation<double>> _animations = {};
  
  // Getters
  bool get isEnabled => _isEnabled;
  bool get isReducedMotion => _isReducedMotion;
  Map<String, AnimationController> get controllers => _controllers;
  Map<String, Animation<double>> get animations => _animations;

  // Initialize animation service
  void initialize() {
    _isEnabled = true;
    _isReducedMotion = false;
    debugPrint('[ANIMATION] Service initialized');
  }

  // Create animation controller
  AnimationController createController(
    String key,
    TickerProvider vsync, {
    Duration? duration,
  }) {
    if (_controllers.containsKey(key)) {
      _controllers[key]!.dispose();
    }
    
    final controller = AnimationController(
      duration: duration ?? const Duration(milliseconds: 300),
      vsync: vsync,
    );
    
    _controllers[key] = controller;
    return controller;
  }

  // Create animation
  Animation<double> createAnimation(
    String key,
    TickerProvider vsync, {
    AnimationConfig? config,
  }) {
    final controller = createController(key, vsync, duration: config?.duration);
    final animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: config?.flutterCurve ?? Curves.easeInOut,
    ));
    
    _animations[key] = animation;
    return animation;
  }

  // Play animation
  Future<void> playAnimation(
    String key, {
    AnimationConfig? config,
    VoidCallback? onComplete,
  }) async {
    if (!_isEnabled || _isReducedMotion) return;
    
    final controller = _controllers[key];
    if (controller == null) return;
    
    if (config?.delay != null) {
      await Future.delayed(Duration(milliseconds: (config!.delay! * 1000).round()));
    }
    
    if (config?.repeat == true) {
      if (config?.reverse == true) {
        controller.repeat(reverse: true);
      } else {
        controller.repeat();
      }
    } else {
      controller.forward().then((_) {
        onComplete?.call();
      });
    }
  }

  // Stop animation
  void stopAnimation(String key) {
    final controller = _controllers[key];
    if (controller != null) {
      controller.stop();
    }
  }

  // Dispose animation
  void disposeAnimation(String key) {
    final controller = _controllers[key];
    if (controller != null) {
      controller.dispose();
      _controllers.remove(key);
      _animations.remove(key);
    }
  }

  // Dispose all animations
  void disposeAll() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _animations.clear();
  }

  // Enable/disable animations
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    notifyListeners();
  }

  // Set reduced motion
  void setReducedMotion(bool reduced) {
    _isReducedMotion = reduced;
    notifyListeners();
  }

  // Fade in animation
  Widget fadeIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    double delay = 0.0,
  }) {
    return AnimatedOpacity(
      opacity: _isEnabled && !_isReducedMotion ? 1.0 : 1.0,
      duration: _isReducedMotion ? Duration.zero : duration,
      curve: curve,
      child: child,
    );
  }

  // Fade out animation
  Widget fadeOut({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return AnimatedOpacity(
      opacity: _isEnabled && !_isReducedMotion ? 0.0 : 0.0,
      duration: _isReducedMotion ? Duration.zero : duration,
      curve: curve,
      child: child,
    );
  }

  // Slide in animation
  Widget slideIn({
    required Widget child,
    Offset begin = const Offset(0, 1),
    Offset end = Offset.zero,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: begin, end: end),
      duration: _isReducedMotion ? Duration.zero : duration,
      curve: curve,
      builder: (context, offset, child) {
        return Transform.translate(
          offset: offset,
          child: child,
        );
      },
      child: child,
    );
  }

  // Scale animation
  Widget scale({
    required Widget child,
    double begin = 0.0,
    double end = 1.0,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: end),
      duration: _isReducedMotion ? Duration.zero : duration,
      curve: curve,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: child,
    );
  }

  // Rotate animation
  Widget rotate({
    required Widget child,
    double begin = 0.0,
    double end = 360.0,
    Duration duration = const Duration(milliseconds: 1000),
    Curve curve = Curves.linear,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: end),
      duration: _isReducedMotion ? Duration.zero : duration,
      curve: curve,
      builder: (context, angle, child) {
        return Transform.rotate(
          angle: angle * math.pi / 180,
          child: child,
        );
      },
      child: child,
    );
  }

  // Bounce animation
  Widget bounce({
    required Widget child,
    Duration duration = const Duration(milliseconds: 600),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: _isReducedMotion ? Duration.zero : duration,
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }

  // Shake animation
  Widget shake({
    required Widget child,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: _isReducedMotion ? Duration.zero : duration,
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final shake = math.sin(value * math.pi * 10) * 10 * (1 - value);
        return Transform.translate(
          offset: Offset(shake, 0),
          child: child,
        );
      },
      child: child,
    );
  }

  // Pulse animation
  Widget pulse({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1000),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 1.2),
      duration: _isReducedMotion ? Duration.zero : duration,
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: child,
    );
  }

  // Glow animation
  Widget glow({
    required Widget child,
    Color glowColor = Colors.blue,
    Duration duration = const Duration(milliseconds: 1000),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: _isReducedMotion ? Duration.zero : duration,
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: glowColor.withOpacity(value * 0.5),
                blurRadius: 20 * value,
                spreadRadius: 5 * value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: child,
    );
  }

  // Shimmer animation
  Widget shimmer({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -1.0, end: 2.0),
      duration: _isReducedMotion ? Duration.zero : duration,
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(value - 1, 0),
              end: Alignment(value, 0),
              colors: const [
                Colors.transparent,
                Colors.white,
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: child,
    );
  }

  // Ripple animation
  Widget ripple({
    required Widget child,
    Color rippleColor = Colors.white,
    Duration duration = const Duration(milliseconds: 600),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: _isReducedMotion ? Duration.zero : duration,
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            Positioned.fill(
              child: CustomPaint(
                painter: RipplePainter(
                  progress: value,
                  color: rippleColor,
                ),
              ),
            ),
          ],
        );
      },
      child: child,
    );
  }

  // Morph animation
  Widget morph({
    required Widget child,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: _isReducedMotion ? Duration.zero : duration,
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(0, 0, 1 + value * 0.1)
            ..setEntry(1, 1, 1 - value * 0.05),
          child: child,
        );
      },
      child: child,
    );
  }

  // Staggered animation for lists
  Widget staggeredList({
    required List<Widget> children,
    Duration staggerDuration = const Duration(milliseconds: 100),
    Duration animationDuration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return Column(
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: _isReducedMotion 
            ? Duration.zero 
            : animationDuration + (staggerDuration * index),
          curve: curve,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 50 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: child,
        );
      }).toList(),
    );
  }

  // Page transition animation
  Widget pageTransition({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: _isReducedMotion ? Duration.zero : duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 100 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  // Card flip animation
  Widget cardFlip({
    required Widget front,
    required Widget back,
    bool isFlipped = false,
    Duration duration = const Duration(milliseconds: 600),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: isFlipped ? 1.0 : 0.0),
      duration: _isReducedMotion ? Duration.zero : duration,
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final angle = value * math.pi;
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          alignment: Alignment.center,
          child: angle < math.pi / 2 ? front : back,
        );
      },
    );
  }

  // Haptic feedback
  void hapticFeedback({HapticFeedbackType type = HapticFeedbackType.lightImpact}) {
    if (_isEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  // Vibration feedback
  void vibrationFeedback({int milliseconds = 100}) {
    if (_isEnabled) {
      HapticFeedback.heavyImpact();
    }
  }
}

// Custom painter for ripple effect
class RipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  RipplePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity((1 - progress) * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = progress * math.min(size.width, size.height) / 2;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
} 