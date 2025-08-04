import 'package:flutter/material.dart';
import '../models/battle_model.dart';
import '../models/card_model.dart';
import 'dart:math' as math;
import 'dart:async';

class EnhancedTargetHighlightWidget extends StatefulWidget {
  final Widget child;
  final bool isValidTarget;
  final bool isHovered;
  final ActionCard? draggedCard;
  final String? draggedAction;
  final String playerId;

  const EnhancedTargetHighlightWidget({
    Key? key,
    required this.child,
    required this.isValidTarget,
    required this.isHovered,
    this.draggedCard,
    this.draggedAction,
    required this.playerId,
  }) : super(key: key);

  @override
  State<EnhancedTargetHighlightWidget> createState() => _EnhancedTargetHighlightWidgetState();
}

class _EnhancedTargetHighlightWidgetState extends State<EnhancedTargetHighlightWidget>
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _particleController;
  late AnimationController _forbiddenController;
  
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _forbiddenAnimation;
  late Animation<double> _scaleAnimation;
  
  // Spell casting state
  bool _isCasting = false;
  double _castProgress = 0.0;
  Duration _remainingCastTime = Duration.zero;
  DateTime? _castStartTime;
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    _forbiddenController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.3,
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
    
    _forbiddenAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _forbiddenController,
      curve: Curves.elasticOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
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
    _forbiddenController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Show forbidden animation if target is invalid but being hovered
    if (!widget.isValidTarget && widget.isHovered) {
      _forbiddenController.forward();
      return _buildForbiddenTarget();
    } else {
      _forbiddenController.reverse();
    }
    
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
          clipBehavior: Clip.none,
          children: [
            // Element-based magical aura
            if (widget.isValidTarget)
              _buildElementalAura(),
            
            // Rotating element symbols
            if (widget.isHovered && widget.isValidTarget)
              _buildRotatingElements(),
            
            // Elemental particles
            if (widget.isValidTarget)
              _buildElementalParticles(),
            
            // Enhanced child with scale animation
            Transform.scale(
              scale: widget.isHovered ? _scaleAnimation.value : 1.0,
              child: widget.child,
            ),
            
            // Target overlay with element styling
            if (widget.isHovered && widget.isValidTarget)
              _buildElementalTargetOverlay(),
              
            // Countdown timer overlay for spells
            if (widget.isValidTarget && _shouldShowTimer())
              _buildTimerOverlay(),
          ],
        );
      },
    );
  }
  
  Widget _buildForbiddenTarget() {
    return AnimatedBuilder(
      animation: _forbiddenAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Shake effect
            Transform.translate(
              offset: Offset(
                math.sin(_forbiddenAnimation.value * math.pi * 6) * 5,
                0,
              ),
              child: widget.child,
            ),
            
            // Red X overlay
            if (_forbiddenAnimation.value > 0.5)
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.8),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 48,
                ),
              ),
          ],
        );
      },
    );
  }
  
  Widget _buildElementalAura() {
    final elementStyle = _getElementStyle();
    
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            elementStyle.primaryColor.withOpacity(0.0),
            elementStyle.primaryColor.withOpacity(0.3 * _pulseAnimation.value),
            elementStyle.secondaryColor.withOpacity(0.5 * _pulseAnimation.value),
            elementStyle.primaryColor.withOpacity(0.2 * _pulseAnimation.value),
            Colors.transparent,
          ],
          stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: elementStyle.primaryColor.withOpacity(0.4 * _pulseAnimation.value),
            blurRadius: 25.0 * _pulseAnimation.value,
            spreadRadius: 8.0 * _pulseAnimation.value,
          ),
        ],
      ),
    );
  }
  
  Widget _buildRotatingElements() {
    final elementStyle = _getElementStyle();
    
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        children: List.generate(elementStyle.symbolCount, (index) {
          final angle = (2 * math.pi * index / elementStyle.symbolCount) + _rotationAnimation.value;
          final radius = 80.0 + 20 * math.sin(_pulseAnimation.value * math.pi);
          
          return Positioned(
            left: 100 + radius * math.cos(angle) - 15,
            top: 100 + radius * math.sin(angle) - 15,
            child: Transform.rotate(
              angle: _rotationAnimation.value * (index % 2 == 0 ? 1 : -1),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      elementStyle.primaryColor,
                      elementStyle.secondaryColor,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: elementStyle.primaryColor.withOpacity(0.8),
                      blurRadius: 10.0,
                      spreadRadius: 2.0,
                    ),
                  ],
                ),
                child: Icon(
                  elementStyle.symbolIcon,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
  
  Widget _buildElementalParticles() {
    final elementStyle = _getElementStyle();
    
    return SizedBox(
      width: 250,
      height: 250,
      child: CustomPaint(
        painter: ElementalParticlesPainter(
          particleProgress: _particleAnimation.value,
          elementStyle: elementStyle,
          effectType: elementStyle.effectType,
        ),
      ),
    );
  }
  
  Widget _buildElementalTargetOverlay() {
    final elementStyle = _getElementStyle();
    
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: elementStyle.primaryColor,
          width: 4.0 * _pulseAnimation.value,
        ),
        gradient: RadialGradient(
          colors: [
            elementStyle.primaryColor.withOpacity(0.2),
            elementStyle.primaryColor.withOpacity(0.4),
            elementStyle.primaryColor.withOpacity(0.1),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: elementStyle.primaryColor.withOpacity(0.6),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        elementStyle.targetIcon,
        color: elementStyle.primaryColor,
        size: 32,
      ),
    );
  }
  
  Widget _buildTimerOverlay() {
    if (!_shouldShowTimer() || !_isCasting) {
      return const SizedBox.shrink();
    }
    
    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getElementStyle().primaryColor,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer,
                color: _getElementStyle().primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${_remainingCastTime.inSeconds}.${(_remainingCastTime.inMilliseconds % 1000 / 100).round()}s',
                style: TextStyle(
                  color: _getElementStyle().primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: LinearProgressIndicator(
                  value: _castProgress,
                  backgroundColor: Colors.grey[600],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getElementStyle().primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  bool _shouldShowTimer() {
    // Show timer if there's a pending spell being cast
    return widget.draggedCard?.type == ActionCardType.spell;
  }
  
  ElementStyle _getElementStyle() {
    // Determine style based on dragged item
    if (widget.draggedAction == 'ATTACK') {
      return ElementStyle(
        primaryColor: const Color(0xFFDC143C), // Crimson
        secondaryColor: const Color(0xFFFF6347), // Tomato
        symbolIcon: Icons.flash_on,
        targetIcon: Icons.gps_fixed,
        symbolCount: 8,
        particleCount: 15,
        effectType: ElementEffectType.physical,
      );
    }
    
    if (widget.draggedCard != null) {
      final card = widget.draggedCard!;
      final name = card.name.toLowerCase();
      
      // Fire element
      if (name.contains('fire') || name.contains('burn') || name.contains('flame')) {
        return ElementStyle(
          primaryColor: const Color(0xFFFF4500), // OrangeRed
          secondaryColor: const Color(0xFFFF8C00), // DarkOrange
          symbolIcon: Icons.local_fire_department,
          targetIcon: Icons.whatshot,
          symbolCount: 12,
          particleCount: 25,
          effectType: ElementEffectType.fire,
        );
      }
      
      // Ice element
      if (name.contains('ice') || name.contains('frost') || name.contains('freeze')) {
        return ElementStyle(
          primaryColor: const Color(0xFF00BFFF), // DeepSkyBlue
          secondaryColor: const Color(0xFF87CEEB), // SkyBlue
          symbolIcon: Icons.ac_unit,
          targetIcon: Icons.ac_unit,
          symbolCount: 6,
          particleCount: 20,
          effectType: ElementEffectType.ice,
        );
      }
      
      // Lightning element
      if (name.contains('lightning') || name.contains('shock') || name.contains('thunder')) {
        return ElementStyle(
          primaryColor: const Color(0xFFFFD700), // Gold
          secondaryColor: const Color(0xFFFFFF00), // Yellow
          symbolIcon: Icons.flash_on,
          targetIcon: Icons.electric_bolt,
          symbolCount: 10,
          particleCount: 30,
          effectType: ElementEffectType.lightning,
        );
      }
      
      // Shadow/Dark element
      if (name.contains('shadow') || name.contains('curse') || name.contains('dark')) {
        return ElementStyle(
          primaryColor: const Color(0xFF8B008B), // DarkMagenta
          secondaryColor: const Color(0xFF4B0082), // Indigo
          symbolIcon: Icons.dark_mode,
          targetIcon: Icons.nights_stay,
          symbolCount: 8,
          particleCount: 18,
          effectType: ElementEffectType.shadow,
        );
      }
      
      // Healing element
      if (name.contains('heal') || name.contains('holy') || name.contains('restore')) {
        return ElementStyle(
          primaryColor: const Color(0xFF32CD32), // LimeGreen
          secondaryColor: const Color(0xFF98FB98), // PaleGreen
          symbolIcon: Icons.healing,
          targetIcon: Icons.favorite,
          symbolCount: 6,
          particleCount: 22,
          effectType: ElementEffectType.healing,
        );
      }
      
      // Arcane element
      if (name.contains('arcane') || name.contains('dispel') || name.contains('magic')) {
        return ElementStyle(
          primaryColor: const Color(0xFF9370DB), // MediumPurple
          secondaryColor: const Color(0xFFBA55D3), // MediumOrchid
          symbolIcon: Icons.auto_awesome,
          targetIcon: Icons.stars,
          symbolCount: 12,
          particleCount: 35,
          effectType: ElementEffectType.arcane,
        );
      }
      
      // Buff effects
      if (card.type == ActionCardType.buff) {
        return ElementStyle(
          primaryColor: const Color(0xFF1E90FF), // DodgerBlue
          secondaryColor: const Color(0xFF87CEFA), // LightSkyBlue
          symbolIcon: Icons.arrow_upward,
          targetIcon: Icons.trending_up,
          symbolCount: 6,
          particleCount: 12,
          effectType: ElementEffectType.buff,
        );
      }
      
      // Debuff effects
      if (card.type == ActionCardType.debuff) {
        return ElementStyle(
          primaryColor: const Color(0xFF8B0000), // DarkRed
          secondaryColor: const Color(0xFFCD5C5C), // IndianRed
          symbolIcon: Icons.arrow_downward,
          targetIcon: Icons.trending_down,
          symbolCount: 8,
          particleCount: 16,
          effectType: ElementEffectType.debuff,
        );
      }
    }
    
    // Default style
    return ElementStyle(
      primaryColor: Colors.white,
      secondaryColor: Colors.grey.shade300,
      symbolIcon: Icons.circle,
      targetIcon: Icons.radio_button_checked,
      symbolCount: 4,
      particleCount: 8,
      effectType: ElementEffectType.generic,
    );
  }
}

class ElementalParticlesPainter extends CustomPainter {
  final double particleProgress;
  final ElementStyle elementStyle;
  final ElementEffectType effectType;

  ElementalParticlesPainter({
    required this.particleProgress,
    required this.elementStyle,
    required this.effectType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final random = math.Random(42); // Fixed seed for consistent patterns
    
    for (int i = 0; i < elementStyle.particleCount; i++) {
      final progress = (particleProgress + i / elementStyle.particleCount) % 1.0;
      
      switch (effectType) {
        case ElementEffectType.fire:
          _drawFireParticle(canvas, center, progress, i, random);
          break;
        case ElementEffectType.ice:
          _drawIceParticle(canvas, center, progress, i, random);
          break;
        case ElementEffectType.lightning:
          _drawLightningParticle(canvas, center, progress, i, random);
          break;
        case ElementEffectType.shadow:
          _drawShadowParticle(canvas, center, progress, i, random);
          break;
        case ElementEffectType.healing:
          _drawHealingParticle(canvas, center, progress, i, random);
          break;
        case ElementEffectType.arcane:
          _drawArcaneParticle(canvas, center, progress, i, random);
          break;
        default:
          _drawGenericParticle(canvas, center, progress, i, random);
          break;
      }
    }
  }
  
  void _drawFireParticle(Canvas canvas, Offset center, double progress, int index, math.Random random) {
    final angle = random.nextDouble() * 2 * math.pi;
    final radius = 40.0 + progress * 60.0;
    final flickerOffset = math.sin(progress * math.pi * 8) * 5;
    
    final position = center + Offset(
      math.cos(angle) * radius + flickerOffset,
      math.sin(angle) * radius - progress * 20, // Rise upward
    );
    
    final size = (3.0 + index % 3) * (1.0 - progress) * (0.8 + 0.4 * math.sin(progress * math.pi * 3));
    final opacity = (1.0 - progress) * 0.9;
    
    final paint = Paint()
      ..color = (index % 2 == 0 ? elementStyle.primaryColor : elementStyle.secondaryColor)
          .withOpacity(opacity);
    
    // Draw flame shape
    final flamePath = Path()
      ..moveTo(position.dx, position.dy + size)
      ..quadraticBezierTo(
        position.dx - size * 0.6, position.dy + size * 0.3,
        position.dx, position.dy - size,
      )
      ..quadraticBezierTo(
        position.dx + size * 0.6, position.dy + size * 0.3,
        position.dx, position.dy + size,
      );
    
    canvas.drawPath(flamePath, paint);
  }
  
  void _drawIceParticle(Canvas canvas, Offset center, double progress, int index, math.Random random) {
    final angle = random.nextDouble() * 2 * math.pi;
    final radius = 30.0 + progress * 50.0;
    
    final position = center + Offset(
      math.cos(angle) * radius,
      math.sin(angle) * radius,
    );
    
    final size = (2.0 + index % 2) * (1.0 - progress * 0.5);
    final opacity = (1.0 - progress) * 0.8;
    
    final paint = Paint()
      ..color = elementStyle.primaryColor.withOpacity(opacity)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    // Draw crystal/snowflake shape
    for (int i = 0; i < 6; i++) {
      final spikeAngle = i * math.pi / 3;
      final start = position;
      final end = position + Offset(
        math.cos(spikeAngle) * size,
        math.sin(spikeAngle) * size,
      );
      canvas.drawLine(start, end, paint);
    }
  }
  
  void _drawLightningParticle(Canvas canvas, Offset center, double progress, int index, math.Random random) {
    final angle = random.nextDouble() * 2 * math.pi;
    final radius = 25.0 + progress * 80.0;
    
    final position = center + Offset(
      math.cos(angle) * radius,
      math.sin(angle) * radius,
    );
    
    final size = (4.0 + index % 3) * (1.0 - progress * 0.3);
    final opacity = (1.0 - progress) * (0.6 + 0.4 * math.sin(progress * math.pi * 10));
    
    final paint = Paint()
      ..color = elementStyle.primaryColor.withOpacity(opacity)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    // Draw lightning bolt
    final lightningPath = Path()
      ..moveTo(position.dx - size, position.dy - size)
      ..lineTo(position.dx + size * 0.3, position.dy)
      ..lineTo(position.dx - size * 0.3, position.dy)
      ..lineTo(position.dx + size, position.dy + size);
    
    canvas.drawPath(lightningPath, paint);
  }
  
  void _drawShadowParticle(Canvas canvas, Offset center, double progress, int index, math.Random random) {
    final angle = random.nextDouble() * 2 * math.pi;
    final radius = 35.0 + progress * 45.0;
    final swirl = math.sin(progress * math.pi * 4) * 15;
    
    final position = center + Offset(
      math.cos(angle) * radius + swirl,
      math.sin(angle) * radius,
    );
    
    final size = (3.0 + index % 4) * (1.0 - progress * 0.7);
    final opacity = (1.0 - progress) * 0.7;
    
    final paint = Paint()
      ..color = elementStyle.primaryColor.withOpacity(opacity);
    
    // Draw wispy shadow
    canvas.drawCircle(position, size, paint);
    canvas.drawCircle(position + Offset(size * 0.5, 0), size * 0.7, paint);
  }
  
  void _drawHealingParticle(Canvas canvas, Offset center, double progress, int index, math.Random random) {
    final angle = random.nextDouble() * 2 * math.pi;
    final radius = 20.0 + progress * 40.0;
    final float = math.sin(progress * math.pi * 2) * 10;
    
    final position = center + Offset(
      math.cos(angle) * radius,
      math.sin(angle) * radius - float,
    );
    
    final size = (2.5 + index % 2) * (1.0 - progress * 0.4);
    final opacity = (1.0 - progress) * 0.8;
    
    final paint = Paint()
      ..color = elementStyle.primaryColor.withOpacity(opacity)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    // Draw healing cross
    canvas.drawLine(
      Offset(position.dx - size, position.dy),
      Offset(position.dx + size, position.dy),
      paint,
    );
    canvas.drawLine(
      Offset(position.dx, position.dy - size),
      Offset(position.dx, position.dy + size),
      paint,
    );
  }
  
  void _drawArcaneParticle(Canvas canvas, Offset center, double progress, int index, math.Random random) {
    final angle = random.nextDouble() * 2 * math.pi;
    final radius = 30.0 + progress * 70.0;
    final spiral = progress * math.pi * 4;
    
    final position = center + Offset(
      math.cos(angle + spiral) * radius,
      math.sin(angle + spiral) * radius,
    );
    
    final size = (3.0 + index % 3) * (1.0 - progress * 0.5);
    final opacity = (1.0 - progress) * (0.7 + 0.3 * math.sin(progress * math.pi * 6));
    
    final paint = Paint()
      ..color = (index % 3 == 0 ? elementStyle.primaryColor : elementStyle.secondaryColor)
          .withOpacity(opacity);
    
    // Draw star shape
    final starPath = Path();
    const points = 5;
    for (int i = 0; i < points * 2; i++) {
      final starAngle = i * math.pi / points;
      final starRadius = i % 2 == 0 ? size : size * 0.5;
      final x = position.dx + math.cos(starAngle) * starRadius;
      final y = position.dy + math.sin(starAngle) * starRadius;
      
      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }
    starPath.close();
    
    canvas.drawPath(starPath, paint);
  }
  
  void _drawGenericParticle(Canvas canvas, Offset center, double progress, int index, math.Random random) {
    final angle = random.nextDouble() * 2 * math.pi;
    final radius = 25.0 + progress * 35.0;
    
    final position = center + Offset(
      math.cos(angle) * radius,
      math.sin(angle) * radius,
    );
    
    final size = (2.0 + index % 2) * (1.0 - progress);
    final opacity = (1.0 - progress) * 0.6;
    
    final paint = Paint()
      ..color = elementStyle.primaryColor.withOpacity(opacity);
    
    canvas.drawCircle(position, size, paint);
  }

  @override
  bool shouldRepaint(ElementalParticlesPainter oldDelegate) {
    return oldDelegate.particleProgress != particleProgress;
  }
}

class ElementStyle {
  final Color primaryColor;
  final Color secondaryColor;
  final IconData symbolIcon;
  final IconData targetIcon;
  final int symbolCount;
  final int particleCount;
  final ElementEffectType effectType;

  ElementStyle({
    required this.primaryColor,
    required this.secondaryColor,
    required this.symbolIcon,
    required this.targetIcon,
    required this.symbolCount,
    required this.particleCount,
    required this.effectType,
  });
}

enum ElementEffectType {
  fire,
  ice,
  lightning,
  shadow,
  healing,
  arcane,
  buff,
  debuff,
  physical,
  generic,
}

// Spell casting methods
extension SpellCasting on _EnhancedTargetHighlightWidgetState {
  void _startSpellCast() {
    setState(() {
      _isCasting = true;
      _castProgress = 0.0;
      _castStartTime = DateTime.now();
      _remainingCastTime = const Duration(seconds: 3); // Default cast time
    });
    
    // Start countdown timer
    _startCastTimer();
  }

  void _startCastTimer() {
    final totalDuration = _remainingCastTime.inMilliseconds;
    final interval = 100; // Update every 100ms
    
    Timer.periodic(Duration(milliseconds: interval), (timer) {
      if (!mounted || !_isCasting) {
        timer.cancel();
        return;
      }
      
      final elapsed = DateTime.now().difference(_castStartTime!).inMilliseconds;
      final progress = (elapsed / totalDuration).clamp(0.0, 1.0);
      
      setState(() {
        _castProgress = progress;
        _remainingCastTime = Duration(milliseconds: (totalDuration - elapsed).clamp(0, totalDuration));
      });
      
      if (progress >= 1.0) {
        _completeSpellCast();
        timer.cancel();
      }
    });
  }

  void _completeSpellCast() {
    setState(() {
      _isCasting = false;
      _castProgress = 1.0;
      _remainingCastTime = Duration.zero;
    });
  }

  void _cancelSpellCast() {
    setState(() {
      _isCasting = false;
      _castProgress = 0.0;
      _remainingCastTime = Duration.zero;
    });
  }
} 