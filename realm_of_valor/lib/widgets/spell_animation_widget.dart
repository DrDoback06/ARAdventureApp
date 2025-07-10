import 'package:flutter/material.dart';
import 'package:realm_of_valor/effects/particle_system.dart';
import 'package:realm_of_valor/models/battle_model.dart';
import 'dart:async';
import 'dart:math' as math;

enum SpellAnimationType {
  projectile,
  beam,
  explosion,
  aura,
  channel,
  shield,
  heal,
  counter,
  transformation,
}

class SpellCastingAnimation extends StatefulWidget {
  final ActionCard spell;
  final Offset startPosition;
  final Offset? targetPosition;
  final SpellAnimationType animationType;
  final Function()? onComplete;
  final Widget? background;
  
  const SpellCastingAnimation({
    Key? key,
    required this.spell,
    required this.startPosition,
    this.targetPosition,
    required this.animationType,
    this.onComplete,
    this.background,
  }) : super(key: key);

  @override
  State<SpellCastingAnimation> createState() => _SpellCastingAnimationState();
}

class _SpellCastingAnimationState extends State<SpellCastingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late Animation<double> _projectileAnimation;
  late Animation<double> _explosionAnimation;
  late Animation<double> _channelAnimation;
  late Animation<Offset> _beamAnimation;
  
  Timer? _delayTimer;
  bool _showExplosion = false;
  bool _showParticles = true;
  
  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      duration: _getAnimationDuration(),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    
    _setupAnimations();
    _startAnimation();
  }
  
  Duration _getAnimationDuration() {
    switch (widget.animationType) {
      case SpellAnimationType.projectile:
        return const Duration(milliseconds: 1200);
      case SpellAnimationType.beam:
        return const Duration(milliseconds: 800);
      case SpellAnimationType.explosion:
        return const Duration(milliseconds: 1500);
      case SpellAnimationType.aura:
        return const Duration(milliseconds: 2000);
      case SpellAnimationType.channel:
        return const Duration(milliseconds: 3000);
      case SpellAnimationType.shield:
        return const Duration(milliseconds: 1000);
      case SpellAnimationType.heal:
        return const Duration(milliseconds: 2500);
      case SpellAnimationType.counter:
        return const Duration(milliseconds: 600);
      case SpellAnimationType.transformation:
        return const Duration(milliseconds: 2000);
    }
  }
  
  void _setupAnimations() {
    _projectileAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));
    
    _explosionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.7, 1.0, curve: Curves.elasticOut),
    ));
    
    _channelAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.targetPosition != null) {
      _beamAnimation = Tween<Offset>(
        begin: widget.startPosition,
        end: widget.targetPosition!,
      ).animate(CurvedAnimation(
        parent: _mainController,
        curve: Curves.easeInOut,
      ));
    }
  }
  
  void _startAnimation() {
    _particleController.forward();
    
    if (widget.animationType == SpellAnimationType.projectile) {
      _mainController.forward().then((_) {
        setState(() {
          _showExplosion = true;
        });
        Timer(const Duration(milliseconds: 500), () {
          widget.onComplete?.call();
        });
      });
    } else if (widget.animationType == SpellAnimationType.explosion) {
      _delayTimer = Timer(const Duration(milliseconds: 200), () {
        setState(() {
          _showExplosion = true;
        });
      });
      _mainController.forward().then((_) {
        widget.onComplete?.call();
      });
    } else {
      _mainController.forward().then((_) {
        widget.onComplete?.call();
      });
    }
  }
  
  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    _delayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background
        if (widget.background != null) widget.background!,
        
        // Main spell animation
        AnimatedBuilder(
          animation: _mainController,
          builder: (context, child) {
            return _buildSpellAnimation();
          },
        ),
        
        // Particle effects
        if (_showParticles) _buildParticleEffects(),
        
        // Explosion effect
        if (_showExplosion) _buildExplosionEffect(),
      ],
    );
  }
  
  Widget _buildSpellAnimation() {
    switch (widget.animationType) {
      case SpellAnimationType.projectile:
        return _buildProjectileAnimation();
      case SpellAnimationType.beam:
        return _buildBeamAnimation();
      case SpellAnimationType.explosion:
        return _buildExplosionAnimation();
      case SpellAnimationType.aura:
        return _buildAuraAnimation();
      case SpellAnimationType.channel:
        return _buildChannelAnimation();
      case SpellAnimationType.shield:
        return _buildShieldAnimation();
      case SpellAnimationType.heal:
        return _buildHealAnimation();
      case SpellAnimationType.counter:
        return _buildCounterAnimation();
      case SpellAnimationType.transformation:
        return _buildTransformationAnimation();
    }
  }
  
  Widget _buildProjectileAnimation() {
    if (widget.targetPosition == null) return Container();
    
    final currentPosition = Offset.lerp(
      widget.startPosition,
      widget.targetPosition!,
      _projectileAnimation.value,
    ) ?? widget.startPosition;
    
    return Positioned(
      left: currentPosition.dx - 20,
      top: currentPosition.dy - 20,
      child: Transform.scale(
        scale: 1.0 + _projectileAnimation.value * 0.5,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: _getSpellColors(),
            ),
            boxShadow: [
              BoxShadow(
                color: _getSpellColors().first.withOpacity(0.8),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Icon(
            _getSpellIcon(),
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
  
  Widget _buildBeamAnimation() {
    if (widget.targetPosition == null) return Container();
    
    return CustomPaint(
      painter: BeamPainter(
        startPosition: widget.startPosition,
        endPosition: widget.targetPosition!,
        progress: _mainController.value,
        colors: _getSpellColors(),
        width: 8.0 + _mainController.value * 12.0,
      ),
      size: Size.infinite,
    );
  }
  
  Widget _buildExplosionAnimation() {
    final center = widget.targetPosition ?? widget.startPosition;
    final size = 100.0 * _explosionAnimation.value;
    
    return Positioned(
      left: center.dx - size / 2,
      top: center.dy - size / 2,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              _getSpellColors().first.withOpacity(0.8),
              _getSpellColors().last.withOpacity(0.4),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAuraAnimation() {
    final center = widget.startPosition;
    final size = 150.0 * _channelAnimation.value;
    
    return Positioned(
      left: center.dx - size / 2,
      top: center.dy - size / 2,
      child: Transform.rotate(
        angle: _channelAnimation.value * 2 * math.pi,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _getSpellColors().first.withOpacity(0.6),
              width: 3.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _getSpellColors().first.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildChannelAnimation() {
    final center = widget.startPosition;
    
    return Positioned(
      left: center.dx - 75,
      top: center.dy - 75,
      child: Stack(
        children: [
          // Inner circle
          Transform.scale(
            scale: 0.5 + _channelAnimation.value * 0.5,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: _getSpellColors(),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getSpellColors().first.withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          // Rotating outer ring
          Transform.rotate(
            angle: _channelAnimation.value * 4 * math.pi,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getSpellColors().last.withOpacity(0.8),
                  width: 4.0,
                ),
              ),
            ),
          ),
          // Spell icon
          Center(
            child: Icon(
              _getSpellIcon(),
              size: 40,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildShieldAnimation() {
    final center = widget.startPosition;
    final size = 120.0 * _channelAnimation.value;
    
    return Positioned(
      left: center.dx - size / 2,
      top: center.dy - size / 2,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.blue.withOpacity(0.1),
              Colors.cyan.withOpacity(0.3),
              Colors.blue.withOpacity(0.6),
            ],
          ),
          border: Border.all(
            color: Colors.cyan,
            width: 3.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Icon(
          Icons.shield,
          size: size * 0.4,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }
  
  Widget _buildHealAnimation() {
    final center = widget.targetPosition ?? widget.startPosition;
    
    return Stack(
      children: [
        // Upward floating plus symbols
        for (int i = 0; i < 5; i++)
          _buildFloatingHealSymbol(center, i),
        
        // Central glow
        Positioned(
          left: center.dx - 60,
          top: center.dy - 60,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.green.withOpacity(0.6),
                  Colors.lightGreen.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFloatingHealSymbol(Offset center, int index) {
    final angle = (index * 2 * math.pi / 5) + (_channelAnimation.value * 2 * math.pi);
    final radius = 40.0 + _channelAnimation.value * 20.0;
    final symbolPosition = Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius - _channelAnimation.value * 50,
    );
    
    return Positioned(
      left: symbolPosition.dx - 15,
      top: symbolPosition.dy - 15,
      child: Opacity(
        opacity: 1.0 - _channelAnimation.value,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.8),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
  
  Widget _buildCounterAnimation() {
    final center = widget.startPosition;
    
    return Positioned(
      left: center.dx - 100,
      top: center.dy - 100,
      child: Transform.scale(
        scale: _channelAnimation.value,
        child: Transform.rotate(
          angle: _channelAnimation.value * math.pi,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.purple.withOpacity(0.8),
                  Colors.magenta.withOpacity(0.6),
                  Colors.transparent,
                ],
              ),
              border: Border.all(
                color: Colors.purple,
                width: 4.0,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.block,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTransformationAnimation() {
    final center = widget.startPosition;
    
    return Positioned(
      left: center.dx - 80,
      top: center.dy - 80,
      child: Transform.scale(
        scale: 0.5 + _channelAnimation.value * 0.5,
        child: Transform.rotate(
          angle: _channelAnimation.value * 6 * math.pi,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Colors.red,
                  Colors.orange,
                  Colors.yellow,
                  Colors.green,
                  Colors.blue,
                  Colors.purple,
                  Colors.red,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildParticleEffects() {
    return ParticleSystem(
      type: _getParticleTypeForSpell(),
      center: widget.startPosition,
      continuous: false,
      duration: _getAnimationDuration(),
      intensity: 1.5,
      child: Container(),
    );
  }
  
  Widget _buildExplosionEffect() {
    final center = widget.targetPosition ?? widget.startPosition;
    return ParticleSystem(
      type: ParticleType.explosion,
      center: center,
      continuous: false,
      duration: const Duration(milliseconds: 1000),
      intensity: 2.0,
      child: Container(),
    );
  }
  
  List<Color> _getSpellColors() {
    final spellName = widget.spell.name.toLowerCase();
    
    if (spellName.contains('fire') || spellName.contains('flame')) {
      return [Colors.red, Colors.orange, Colors.yellow];
    } else if (spellName.contains('ice') || spellName.contains('frost')) {
      return [Colors.cyan, Colors.lightBlue, Colors.white];
    } else if (spellName.contains('lightning') || spellName.contains('shock')) {
      return [Colors.yellow, Colors.white, Colors.blue];
    } else if (spellName.contains('earth') || spellName.contains('stone')) {
      return [Colors.brown, Colors.green.shade800, Colors.grey];
    } else if (spellName.contains('water') || spellName.contains('wave')) {
      return [Colors.blue, Colors.lightBlue, Colors.cyan];
    } else if (spellName.contains('light') || spellName.contains('divine')) {
      return [Colors.white, Colors.yellow, Colors.gold];
    } else if (spellName.contains('shadow') || spellName.contains('dark')) {
      return [Colors.black, Colors.purple.shade900, Colors.grey.shade800];
    } else if (spellName.contains('heal') || spellName.contains('cure')) {
      return [Colors.green, Colors.lightGreen, Colors.white];
    } else if (spellName.contains('arcane') || spellName.contains('magic')) {
      return [Colors.purple, Colors.magenta, Colors.white];
    } else {
      return [Colors.blue, Colors.cyan, Colors.white];
    }
  }
  
  IconData _getSpellIcon() {
    final spellName = widget.spell.name.toLowerCase();
    
    if (spellName.contains('fire') || spellName.contains('flame')) {
      return Icons.local_fire_department;
    } else if (spellName.contains('ice') || spellName.contains('frost')) {
      return Icons.ac_unit;
    } else if (spellName.contains('lightning') || spellName.contains('shock')) {
      return Icons.flash_on;
    } else if (spellName.contains('earth') || spellName.contains('stone')) {
      return Icons.terrain;
    } else if (spellName.contains('water') || spellName.contains('wave')) {
      return Icons.water_drop;
    } else if (spellName.contains('light') || spellName.contains('divine')) {
      return Icons.wb_sunny;
    } else if (spellName.contains('shadow') || spellName.contains('dark')) {
      return Icons.nightlight;
    } else if (spellName.contains('heal') || spellName.contains('cure')) {
      return Icons.healing;
    } else if (spellName.contains('shield') || spellName.contains('protect')) {
      return Icons.shield;
    } else {
      return Icons.auto_awesome;
    }
  }
  
  ParticleType _getParticleTypeForSpell() {
    final spellName = widget.spell.name.toLowerCase();
    
    if (spellName.contains('fire') || spellName.contains('flame')) {
      return ParticleType.fire;
    } else if (spellName.contains('ice') || spellName.contains('frost')) {
      return ParticleType.ice;
    } else if (spellName.contains('lightning') || spellName.contains('shock')) {
      return ParticleType.lightning;
    } else if (spellName.contains('earth') || spellName.contains('stone')) {
      return ParticleType.earth;
    } else if (spellName.contains('water') || spellName.contains('wave')) {
      return ParticleType.water;
    } else if (spellName.contains('light') || spellName.contains('divine')) {
      return ParticleType.light;
    } else if (spellName.contains('shadow') || spellName.contains('dark')) {
      return ParticleType.shadow;
    } else if (spellName.contains('heal') || spellName.contains('cure')) {
      return ParticleType.heal;
    } else {
      return ParticleType.arcane;
    }
  }
}

class BeamPainter extends CustomPainter {
  final Offset startPosition;
  final Offset endPosition;
  final double progress;
  final List<Color> colors;
  final double width;
  
  BeamPainter({
    required this.startPosition,
    required this.endPosition,
    required this.progress,
    required this.colors,
    required this.width,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final currentEnd = Offset.lerp(startPosition, endPosition, progress) ?? endPosition;
    
    final paint = Paint()
      ..shader = LinearGradient(
        colors: colors,
      ).createShader(Rect.fromPoints(startPosition, currentEnd))
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    
    // Draw main beam
    canvas.drawLine(startPosition, currentEnd, paint);
    
    // Draw glow effect
    final glowPaint = Paint()
      ..color = colors.first.withOpacity(0.3)
      ..strokeWidth = width * 2
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    
    canvas.drawLine(startPosition, currentEnd, glowPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Helper to determine animation type based on spell
class SpellAnimationHelper {
  static SpellAnimationType getAnimationTypeForSpell(ActionCard spell) {
    final name = spell.name.toLowerCase();
    final description = spell.description.toLowerCase();
    
    if (name.contains('bolt') || name.contains('arrow') || name.contains('missile')) {
      return SpellAnimationType.projectile;
    } else if (name.contains('beam') || name.contains('ray') || name.contains('lance')) {
      return SpellAnimationType.beam;
    } else if (name.contains('explosion') || name.contains('blast') || name.contains('burst')) {
      return SpellAnimationType.explosion;
    } else if (name.contains('aura') || name.contains('field') || description.contains('area')) {
      return SpellAnimationType.aura;
    } else if (name.contains('channel') || description.contains('channel')) {
      return SpellAnimationType.channel;
    } else if (name.contains('shield') || name.contains('barrier') || name.contains('protect')) {
      return SpellAnimationType.shield;
    } else if (name.contains('heal') || name.contains('cure') || name.contains('regenerat')) {
      return SpellAnimationType.heal;
    } else if (spell.type == ActionCardType.counter) {
      return SpellAnimationType.counter;
    } else if (name.contains('transform') || name.contains('change') || name.contains('morph')) {
      return SpellAnimationType.transformation;
    } else {
      return SpellAnimationType.projectile; // Default
    }
  }
  
  static Offset getPlayerPosition(String playerId, Size screenSize) {
    // This would normally get the actual player portrait position
    // For now, return approximate positions based on layout
    switch (playerId) {
      case 'player1':
        return Offset(screenSize.width * 0.5, screenSize.height * 0.8);
      case 'player2':
        return Offset(screenSize.width * 0.5, screenSize.height * 0.2);
      default:
        return Offset(screenSize.width * 0.5, screenSize.height * 0.5);
    }
  }
}