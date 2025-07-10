import 'package:flutter/material.dart';
import '../models/battle_model.dart';
import '../effects/particle_system.dart';
import 'dart:math' as math;

class DragArrowWidget extends StatefulWidget {
  final Offset? startPosition;
  final Offset? currentPosition;
  final ActionCard? draggedCard;
  final String? draggedAction; // 'ATTACK' for basic attacks
  final String? hoveredTargetId;
  final bool isValidTarget;
  final VoidCallback? onComplete;

  const DragArrowWidget({
    Key? key,
    this.startPosition,
    this.currentPosition,
    this.draggedCard,
    this.draggedAction,
    this.hoveredTargetId,
    this.isValidTarget = false,
    this.onComplete,
  }) : super(key: key);

  @override
  State<DragArrowWidget> createState() => _DragArrowWidgetState();
}

class _DragArrowWidgetState extends State<DragArrowWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.linear,
    ));
    
    _pulseController.repeat(reverse: true);
    _particleController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.startPosition == null || widget.currentPosition == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _particleAnimation]),
      builder: (context, child) {
        return CustomPaint(
          painter: DragArrowPainter(
            startPosition: widget.startPosition!,
            endPosition: widget.currentPosition!,
            draggedCard: widget.draggedCard,
            draggedAction: widget.draggedAction,
            isValidTarget: widget.isValidTarget,
            pulseValue: _pulseAnimation.value,
            particleProgress: _particleAnimation.value,
          ),
          child: Container(),
        );
      },
    );
  }
}

class DragArrowPainter extends CustomPainter {
  final Offset startPosition;
  final Offset endPosition;
  final ActionCard? draggedCard;
  final String? draggedAction;
  final bool isValidTarget;
  final double pulseValue;
  final double particleProgress;

  DragArrowPainter({
    required this.startPosition,
    required this.endPosition,
    this.draggedCard,
    this.draggedAction,
    required this.isValidTarget,
    required this.pulseValue,
    required this.particleProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final arrowStyle = _getArrowStyle();
    
    // Draw the magical arrow
    _drawMagicalArrow(canvas, arrowStyle);
    
    // Draw particle trail
    _drawParticleTrail(canvas, arrowStyle);
    
    // Draw arrowhead
    _drawArrowhead(canvas, arrowStyle);
  }

  ArrowStyle _getArrowStyle() {
    // Determine arrow style based on dragged item
    if (draggedAction == 'ATTACK') {
      return ArrowStyle(
        colors: isValidTarget 
            ? [Colors.red, Colors.orange, Colors.yellow]
            : [Colors.grey, Colors.grey.shade400],
        thickness: 6.0 * pulseValue,
        particleColor: isValidTarget ? Colors.orange : Colors.grey,
        effectType: ArrowEffectType.combat,
      );
    }
    
    if (draggedCard != null) {
      switch (draggedCard!.type) {
        case ActionCardType.damage:
          return ArrowStyle(
            colors: isValidTarget
                ? [Colors.red.shade700, Colors.red, Colors.orange]
                : [Colors.grey, Colors.grey.shade400],
            thickness: (4.0 + draggedCard!.cost) * pulseValue,
            particleColor: isValidTarget ? Colors.red : Colors.grey,
            effectType: ArrowEffectType.fire,
          );
          
        case ActionCardType.heal:
          return ArrowStyle(
            colors: isValidTarget
                ? [Colors.green.shade700, Colors.green, Colors.lightGreen]
                : [Colors.grey, Colors.grey.shade400],
            thickness: (4.0 + draggedCard!.cost) * pulseValue,
            particleColor: isValidTarget ? Colors.green : Colors.grey,
            effectType: ArrowEffectType.healing,
          );
          
        case ActionCardType.buff:
          return ArrowStyle(
            colors: isValidTarget
                ? [Colors.blue.shade700, Colors.blue, Colors.lightBlue]
                : [Colors.grey, Colors.grey.shade400],
            thickness: (4.0 + draggedCard!.cost) * pulseValue,
            particleColor: isValidTarget ? Colors.blue : Colors.grey,
            effectType: ArrowEffectType.magic,
          );
          
        case ActionCardType.debuff:
          return ArrowStyle(
            colors: isValidTarget
                ? [Colors.purple.shade700, Colors.purple, Colors.purpleAccent]
                : [Colors.grey, Colors.grey.shade400],
            thickness: (4.0 + draggedCard!.cost) * pulseValue,
            particleColor: isValidTarget ? Colors.purple : Colors.grey,
            effectType: ArrowEffectType.curse,
          );
          
        case ActionCardType.special:
          return ArrowStyle(
            colors: isValidTarget
                ? [Colors.yellow.shade700, Colors.yellow, Colors.amber]
                : [Colors.grey, Colors.grey.shade400],
            thickness: (6.0 + draggedCard!.cost) * pulseValue,
            particleColor: isValidTarget ? Colors.yellow : Colors.grey,
            effectType: ArrowEffectType.divine,
          );
          
        default:
          return ArrowStyle(
            colors: isValidTarget
                ? [Colors.white, Colors.grey.shade300]
                : [Colors.grey, Colors.grey.shade400],
            thickness: 4.0 * pulseValue,
            particleColor: isValidTarget ? Colors.white : Colors.grey,
            effectType: ArrowEffectType.generic,
          );
      }
    }
    
    // Default style
    return ArrowStyle(
      colors: [Colors.white, Colors.grey.shade300],
      thickness: 4.0 * pulseValue,
      particleColor: Colors.white,
      effectType: ArrowEffectType.generic,
    );
  }

  void _drawMagicalArrow(Canvas canvas, ArrowStyle style) {
    final path = _createCurvedPath();
    
    // Create gradient paint
    final gradient = LinearGradient(
      colors: style.colors,
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
    
    final rect = Rect.fromPoints(startPosition, endPosition);
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.thickness
      ..strokeCap = StrokeCap.round;
    
    // Add glow effect for valid targets
    if (isValidTarget) {
      final glowPaint = Paint()
        ..color = style.colors.first.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.thickness * 2.5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
      
      canvas.drawPath(path, glowPaint);
    }
    
    // Draw main arrow
    canvas.drawPath(path, paint);
    
    // Add energy crackling effect for special cards
    if (style.effectType == ArrowEffectType.divine || 
        style.effectType == ArrowEffectType.fire) {
      _drawEnergyEffects(canvas, path, style);
    }
  }

  Path _createCurvedPath() {
    final distance = (endPosition - startPosition).distance;
    final midPoint = Offset(
      (startPosition.dx + endPosition.dx) / 2,
      (startPosition.dy + endPosition.dy) / 2,
    );
    
    // Create curved path for more dynamic arrow
    final controlOffset = distance * 0.2;
    final perpendicular = _getPerpendicularOffset(startPosition, endPosition);
    final controlPoint = midPoint + (perpendicular * controlOffset);
    
    final path = Path();
    path.moveTo(startPosition.dx, startPosition.dy);
    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      endPosition.dx,
      endPosition.dy,
    );
    
    return path;
  }

  Offset _getPerpendicularOffset(Offset start, Offset end) {
    final direction = end - start;
    return Offset(-direction.dy, direction.dx).normalize();
  }

  void _drawParticleTrail(Canvas canvas, ArrowStyle style) {
    if (!isValidTarget) return;
    
    const particleCount = 8;
    final path = _createCurvedPath();
    final pathMetrics = path.computeMetrics().first;
    
    for (int i = 0; i < particleCount; i++) {
      final progress = (i / particleCount + particleProgress) % 1.0;
      final position = pathMetrics.getTangentForOffset(
        pathMetrics.length * progress,
      )?.position;
      
      if (position != null) {
        final particlePaint = Paint()
          ..color = style.particleColor.withOpacity(
            (1.0 - progress) * 0.8,
          )
          ..style = PaintingStyle.fill;
        
        final particleSize = (3.0 + math.sin(progress * math.pi * 4) * 2.0) * 
                           (1.0 - progress);
        
        canvas.drawCircle(position, particleSize, particlePaint);
        
        // Add sparkle effect for divine/special effects
        if (style.effectType == ArrowEffectType.divine) {
          _drawSparkle(canvas, position, particleSize, style.particleColor);
        }
      }
    }
  }

  void _drawArrowhead(Canvas canvas, ArrowStyle style) {
    final direction = (endPosition - startPosition).normalize();
    final arrowheadLength = 20.0 * pulseValue;
    final arrowheadWidth = 12.0 * pulseValue;
    
    final perpendicular = Offset(-direction.dy, direction.dx);
    
    final tip = endPosition;
    final base1 = tip - (direction * arrowheadLength) + (perpendicular * arrowheadWidth / 2);
    final base2 = tip - (direction * arrowheadLength) - (perpendicular * arrowheadWidth / 2);
    
    final arrowheadPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base1.dx, base1.dy)
      ..lineTo(base2.dx, base2.dy)
      ..close();
    
    final arrowheadPaint = Paint()
      ..color = style.colors.last
      ..style = PaintingStyle.fill;
    
    // Add glow for valid targets
    if (isValidTarget) {
      final glowPaint = Paint()
        ..color = style.colors.first.withOpacity(0.5)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
      
      canvas.drawPath(arrowheadPath, glowPaint);
    }
    
    canvas.drawPath(arrowheadPath, arrowheadPaint);
  }

  void _drawEnergyEffects(Canvas canvas, Path path, ArrowStyle style) {
    final random = math.Random(particleProgress.hashCode);
    const crackleCount = 5;
    
    final pathMetrics = path.computeMetrics().first;
    
    for (int i = 0; i < crackleCount; i++) {
      final progress = random.nextDouble();
      final position = pathMetrics.getTangentForOffset(
        pathMetrics.length * progress,
      )?.position;
      
      if (position != null) {
        final crackleLength = 10.0 + random.nextDouble() * 15.0;
        final angle = random.nextDouble() * math.pi * 2;
        final endPos = position + Offset(
          math.cos(angle) * crackleLength,
          math.sin(angle) * crackleLength,
        );
        
        final cracklePaint = Paint()
          ..color = style.colors.first.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0 + random.nextDouble() * 2.0
          ..strokeCap = StrokeCap.round;
        
        canvas.drawLine(position, endPos, cracklePaint);
      }
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Color color) {
    final sparklePaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    
    // Draw sparkle cross
    canvas.drawLine(
      center + Offset(-size, 0),
      center + Offset(size, 0),
      sparklePaint,
    );
    canvas.drawLine(
      center + Offset(0, -size),
      center + Offset(0, size),
      sparklePaint,
    );
    
    // Draw diagonal lines
    final diagSize = size * 0.7;
    canvas.drawLine(
      center + Offset(-diagSize, -diagSize),
      center + Offset(diagSize, diagSize),
      sparklePaint,
    );
    canvas.drawLine(
      center + Offset(-diagSize, diagSize),
      center + Offset(diagSize, -diagSize),
      sparklePaint,
    );
  }

  @override
  bool shouldRepaint(DragArrowPainter oldDelegate) {
    return oldDelegate.startPosition != startPosition ||
           oldDelegate.endPosition != endPosition ||
           oldDelegate.isValidTarget != isValidTarget ||
           oldDelegate.pulseValue != pulseValue ||
           oldDelegate.particleProgress != particleProgress;
  }
}

class ArrowStyle {
  final List<Color> colors;
  final double thickness;
  final Color particleColor;
  final ArrowEffectType effectType;

  ArrowStyle({
    required this.colors,
    required this.thickness,
    required this.particleColor,
    required this.effectType,
  });
}

enum ArrowEffectType {
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

extension OffsetExtensions on Offset {
  Offset normalize() {
    final length = distance;
    return length == 0 ? const Offset(0, 0) : this / length;
  }
}