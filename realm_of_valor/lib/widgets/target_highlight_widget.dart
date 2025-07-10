import 'package:flutter/material.dart';
import '../models/battle_model.dart';
import 'dart:math' as math;

class TargetHighlightWidget extends StatefulWidget {
  final Widget child;
  final bool isValidTarget;
  final bool isHovered;
  final ActionCard? draggedCard;
  final String? draggedAction;
  final String playerId;

  const TargetHighlightWidget({
    Key? key,
    required this.child,
    required this.isValidTarget,
    required this.isHovered,
    this.draggedCard,
    this.draggedAction,
    required this.playerId,
  }) : super(key: key);

  @override
  State<TargetHighlightWidget> createState() => _TargetHighlightWidgetState();
}

class _TargetHighlightWidgetState extends State<TargetHighlightWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _particleController;
  
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2.0 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
    
    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.linear,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
    _particleController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isValidTarget && !widget.isHovered) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseAnimation,
        _rotationAnimation,
        _particleAnimation,
        _scaleAnimation,
      ]),
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Magical aura background
            if (widget.isValidTarget)
              _buildMagicalAura(),
            
            // Rotating runes for special targets
            if (widget.isHovered && widget.isValidTarget)
              _buildRotatingRunes(),
            
            // Floating particles
            if (widget.isValidTarget)
              _buildFloatingParticles(),
            
            // Enhanced child with scale animation
            Transform.scale(
              scale: widget.isHovered ? _scaleAnimation.value : 1.0,
              child: widget.child,
            ),
            
            // Target overlay
            if (widget.isHovered)
              _buildTargetOverlay(),
          ],
        );
      },
    );
  }

  Widget _buildMagicalAura() {
    final highlightStyle = _getHighlightStyle();
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: highlightStyle.primaryColor.withOpacity(0.4 * _pulseAnimation.value),
            blurRadius: 15.0 * _pulseAnimation.value,
            spreadRadius: 5.0 * _pulseAnimation.value,
          ),
          BoxShadow(
            color: highlightStyle.secondaryColor.withOpacity(0.2 * _pulseAnimation.value),
            blurRadius: 25.0 * _pulseAnimation.value,
            spreadRadius: 10.0 * _pulseAnimation.value,
          ),
        ],
      ),
    );
  }

  Widget _buildRotatingRunes() {
    final highlightStyle = _getHighlightStyle();
    
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        children: List.generate(highlightStyle.runeCount, (index) {
          final angle = (2 * math.pi * index / highlightStyle.runeCount) + _rotationAnimation.value;
          final radius = 70.0;
          
          return Positioned(
            left: 80 + radius * math.cos(angle) - 10,
            top: 80 + radius * math.sin(angle) - 10,
            child: Transform.rotate(
              angle: _rotationAnimation.value + index * math.pi / 2,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: highlightStyle.primaryColor.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: highlightStyle.primaryColor.withOpacity(0.6),
                      blurRadius: 8.0,
                      spreadRadius: 2.0,
                    ),
                  ],
                ),
                child: Icon(
                  highlightStyle.runeIcon,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFloatingParticles() {
    final highlightStyle = _getHighlightStyle();
    
    return SizedBox(
      width: 200,
      height: 200,
      child: CustomPaint(
        painter: FloatingParticlesPainter(
          particleProgress: _particleAnimation.value,
          primaryColor: highlightStyle.primaryColor,
          secondaryColor: highlightStyle.secondaryColor,
          particleCount: highlightStyle.particleCount,
          effectType: highlightStyle.effectType,
        ),
      ),
    );
  }

  Widget _buildTargetOverlay() {
    final highlightStyle = _getHighlightStyle();
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: highlightStyle.primaryColor,
          width: 3.0 * _pulseAnimation.value,
        ),
        borderRadius: BorderRadius.circular(12),
        gradient: RadialGradient(
          colors: [
            highlightStyle.primaryColor.withOpacity(0.1),
            highlightStyle.primaryColor.withOpacity(0.3),
            highlightStyle.primaryColor.withOpacity(0.1),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Icon(
          highlightStyle.targetIcon,
          color: highlightStyle.primaryColor,
          size: 24,
        ),
      ),
    );
  }

  HighlightStyle _getHighlightStyle() {
    // Determine highlight style based on dragged item
    if (widget.draggedAction == 'ATTACK') {
      return HighlightStyle(
        primaryColor: Colors.red,
        secondaryColor: Colors.orange,
        runeIcon: Icons.flash_on,
        targetIcon: Icons.gps_fixed,
        runeCount: 6,
        particleCount: 12,
        effectType: HighlightEffectType.combat,
      );
    }
    
    if (widget.draggedCard != null) {
      switch (widget.draggedCard!.type) {
        case ActionCardType.damage:
          return HighlightStyle(
            primaryColor: Colors.red.shade600,
            secondaryColor: Colors.orange.shade400,
            runeIcon: Icons.local_fire_department,
            targetIcon: Icons.my_location,
            runeCount: 8,
            particleCount: 15,
            effectType: HighlightEffectType.fire,
          );
          
        case ActionCardType.heal:
          return HighlightStyle(
            primaryColor: Colors.green.shade400,
            secondaryColor: Colors.lightGreen.shade300,
            runeIcon: Icons.healing,
            targetIcon: Icons.favorite,
            runeCount: 6,
            particleCount: 20,
            effectType: HighlightEffectType.healing,
          );
          
        case ActionCardType.buff:
          return HighlightStyle(
            primaryColor: Colors.blue.shade500,
            secondaryColor: Colors.lightBlue.shade300,
            runeIcon: Icons.star,
            targetIcon: Icons.arrow_upward,
            runeCount: 5,
            particleCount: 10,
            effectType: HighlightEffectType.magic,
          );
          
        case ActionCardType.debuff:
          return HighlightStyle(
            primaryColor: Colors.purple.shade600,
            secondaryColor: Colors.purpleAccent.shade200,
            runeIcon: Icons.dangerous,
            targetIcon: Icons.arrow_downward,
            runeCount: 7,
            particleCount: 8,
            effectType: HighlightEffectType.curse,
          );
          
        case ActionCardType.special:
          return HighlightStyle(
            primaryColor: Colors.yellow.shade600,
            secondaryColor: Colors.amber.shade300,
            runeIcon: Icons.auto_awesome,
            targetIcon: Icons.stars,
            runeCount: 12,
            particleCount: 25,
            effectType: HighlightEffectType.divine,
          );
          
        default:
          return HighlightStyle(
            primaryColor: Colors.white,
            secondaryColor: Colors.grey.shade300,
            runeIcon: Icons.circle,
            targetIcon: Icons.radio_button_checked,
            runeCount: 4,
            particleCount: 6,
            effectType: HighlightEffectType.generic,
          );
      }
    }
    
    // Default style
    return HighlightStyle(
      primaryColor: Colors.white,
      secondaryColor: Colors.grey.shade300,
      runeIcon: Icons.circle,
      targetIcon: Icons.radio_button_checked,
      runeCount: 4,
      particleCount: 6,
      effectType: HighlightEffectType.generic,
    );
  }
}

class FloatingParticlesPainter extends CustomPainter {
  final double particleProgress;
  final Color primaryColor;
  final Color secondaryColor;
  final int particleCount;
  final HighlightEffectType effectType;

  FloatingParticlesPainter({
    required this.particleProgress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.particleCount,
    required this.effectType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final random = math.Random(42); // Fixed seed for consistent pattern
    
    for (int i = 0; i < particleCount; i++) {
      final progress = (particleProgress + i / particleCount) % 1.0;
      final angle = random.nextDouble() * 2 * math.pi;
      final radius = 30.0 + progress * 50.0;
      
      final position = center + Offset(
        math.cos(angle) * radius,
        math.sin(angle) * radius,
      );
      
      final particleSize = _getParticleSize(progress, i);
      final particleColor = _getParticleColor(progress, i);
      
      final paint = Paint()
        ..color = particleColor
        ..style = PaintingStyle.fill;
      
      // Draw particle based on effect type
      switch (effectType) {
        case HighlightEffectType.fire:
          _drawFireParticle(canvas, position, particleSize, paint);
          break;
        case HighlightEffectType.healing:
          _drawHealingParticle(canvas, position, particleSize, paint);
          break;
        case HighlightEffectType.divine:
          _drawDivineParticle(canvas, position, particleSize, paint);
          break;
        case HighlightEffectType.curse:
          _drawCurseParticle(canvas, position, particleSize, paint);
          break;
        default:
          canvas.drawCircle(position, particleSize, paint);
          break;
      }
    }
  }

  double _getParticleSize(double progress, int index) {
    final baseSize = 2.0 + index % 3;
    return baseSize * (1.0 - progress) * (0.5 + 0.5 * math.sin(progress * math.pi * 4));
  }

  Color _getParticleColor(double progress, int index) {
    final opacity = (1.0 - progress) * 0.8;
    return index % 2 == 0 
        ? primaryColor.withOpacity(opacity)
        : secondaryColor.withOpacity(opacity);
  }

  void _drawFireParticle(Canvas canvas, Offset position, double size, Paint paint) {
    // Draw flame-like particle
    final flamePath = Path()
      ..moveTo(position.dx, position.dy + size)
      ..quadraticBezierTo(
        position.dx - size * 0.5, position.dy,
        position.dx, position.dy - size,
      )
      ..quadraticBezierTo(
        position.dx + size * 0.5, position.dy,
        position.dx, position.dy + size,
      );
    
    canvas.drawPath(flamePath, paint);
  }

  void _drawHealingParticle(Canvas canvas, Offset position, double size, Paint paint) {
    // Draw cross-like healing particle
    final crossPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.3
      ..strokeCap = StrokeCap.round;
    
    canvas.drawLine(
      Offset(position.dx - size, position.dy),
      Offset(position.dx + size, position.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(position.dx, position.dy - size),
      Offset(position.dx, position.dy + size),
      crossPaint,
    );
  }

  void _drawDivineParticle(Canvas canvas, Offset position, double size, Paint paint) {
    // Draw star-like divine particle
    final starPath = Path();
    const points = 6;
    
    for (int i = 0; i < points * 2; i++) {
      final angle = i * math.pi / points;
      final radius = i % 2 == 0 ? size : size * 0.5;
      final x = position.dx + math.cos(angle) * radius;
      final y = position.dy + math.sin(angle) * radius;
      
      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }
    starPath.close();
    
    canvas.drawPath(starPath, paint);
  }

  void _drawCurseParticle(Canvas canvas, Offset position, double size, Paint paint) {
    // Draw spiky curse particle
    final spikePaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.2
      ..strokeCap = StrokeCap.round;
    
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final start = position + Offset(
        math.cos(angle) * size * 0.3,
        math.sin(angle) * size * 0.3,
      );
      final end = position + Offset(
        math.cos(angle) * size,
        math.sin(angle) * size,
      );
      
      canvas.drawLine(start, end, spikePaint);
    }
  }

  @override
  bool shouldRepaint(FloatingParticlesPainter oldDelegate) {
    return oldDelegate.particleProgress != particleProgress;
  }
}

class HighlightStyle {
  final Color primaryColor;
  final Color secondaryColor;
  final IconData runeIcon;
  final IconData targetIcon;
  final int runeCount;
  final int particleCount;
  final HighlightEffectType effectType;

  HighlightStyle({
    required this.primaryColor,
    required this.secondaryColor,
    required this.runeIcon,
    required this.targetIcon,
    required this.runeCount,
    required this.particleCount,
    required this.effectType,
  });
}

enum HighlightEffectType {
  combat,
  fire,
  ice,
  lightning,
  healing,
  magic,
  curse,
  divine,
  generic,
}