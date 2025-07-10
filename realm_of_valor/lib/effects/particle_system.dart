import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

enum ParticleType {
  // Elemental Effects
  fire,
  ice,
  lightning,
  earth,
  water,
  air,
  light,
  shadow,
  nature,
  arcane,
  
  // Status Effects
  burn,
  freeze,
  shock,
  poison,
  heal,
  shield,
  curse,
  blessing,
  
  // Buff/Debuff Effects
  strengthBoost,
  weakening,
  speedBoost,
  slowness,
  magicBoost,
  silence,
  
  // Special Effects
  explosion,
  sparkle,
  smoke,
  stars,
  energy,
  absorption,
  reflection,
  dispel,
}

class Particle {
  Offset position;
  Offset velocity;
  double size;
  Color color;
  double opacity;
  double life;
  double maxLife;
  double rotation;
  double rotationSpeed;
  
  Particle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.color,
    required this.life,
    required this.maxLife,
    this.opacity = 1.0,
    this.rotation = 0.0,
    this.rotationSpeed = 0.0,
  });
  
  void update(double deltaTime) {
    position += velocity * deltaTime;
    life -= deltaTime;
    opacity = (life / maxLife).clamp(0.0, 1.0);
    rotation += rotationSpeed * deltaTime;
    
    // Apply gravity for some effects
    velocity = Offset(velocity.dx, velocity.dy + 50 * deltaTime);
  }
  
  bool get isDead => life <= 0;
}

class ParticleSystem extends StatefulWidget {
  final ParticleType type;
  final Offset center;
  final double intensity;
  final Duration duration;
  final bool continuous;
  final Widget? child;
  
  const ParticleSystem({
    Key? key,
    required this.type,
    required this.center,
    this.intensity = 1.0,
    this.duration = const Duration(seconds: 3),
    this.continuous = false,
    this.child,
  }) : super(key: key);

  @override
  State<ParticleSystem> createState() => _ParticleSystemState();
}

class _ParticleSystemState extends State<ParticleSystem>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  final List<Particle> _particles = [];
  late Timer _spawnTimer;
  final math.Random _random = math.Random();
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // 60 FPS
    );
    
    _startParticleSystem();
    
    if (!widget.continuous) {
      Timer(widget.duration, () {
        if (mounted) {
          _stopParticleSystem();
        }
      });
    }
  }
  
  void _startParticleSystem() {
    _animationController.repeat();
    
    // Spawn particles based on type
    final spawnRate = _getSpawnRate();
    _spawnTimer = Timer.periodic(Duration(milliseconds: (1000 / spawnRate).round()), (timer) {
      if (mounted) {
        _spawnParticles();
      }
    });
    
    // Initial burst
    for (int i = 0; i < _getInitialBurst(); i++) {
      _spawnParticles();
    }
  }
  
  void _stopParticleSystem() {
    _spawnTimer.cancel();
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        _animationController.stop();
      }
    });
  }
  
  int _getSpawnRate() {
    switch (widget.type) {
      case ParticleType.fire:
      case ParticleType.lightning:
        return (20 * widget.intensity).round();
      case ParticleType.ice:
      case ParticleType.water:
        return (15 * widget.intensity).round();
      case ParticleType.explosion:
        return (50 * widget.intensity).round();
      case ParticleType.heal:
      case ParticleType.blessing:
        return (12 * widget.intensity).round();
      default:
        return (10 * widget.intensity).round();
    }
  }
  
  int _getInitialBurst() {
    switch (widget.type) {
      case ParticleType.explosion:
        return (30 * widget.intensity).round();
      case ParticleType.lightning:
        return (15 * widget.intensity).round();
      case ParticleType.dispel:
        return (20 * widget.intensity).round();
      default:
        return (5 * widget.intensity).round();
    }
  }
  
  void _spawnParticles() {
    final config = _getParticleConfig(widget.type);
    
    for (int i = 0; i < config.count; i++) {
      _particles.add(_createParticle(config));
    }
  }
  
  ParticleConfig _getParticleConfig(ParticleType type) {
    switch (type) {
      case ParticleType.fire:
        return ParticleConfig(
          colors: [Colors.red, Colors.orange, Colors.yellow],
          minSize: 3.0,
          maxSize: 8.0,
          minLife: 1.0,
          maxLife: 2.5,
          spread: 40.0,
          speed: 80.0,
          count: 3,
        );
        
      case ParticleType.ice:
        return ParticleConfig(
          colors: [Colors.cyan, Colors.lightBlue, Colors.white],
          minSize: 2.0,
          maxSize: 6.0,
          minLife: 2.0,
          maxLife: 4.0,
          spread: 30.0,
          speed: 40.0,
          count: 2,
        );
        
      case ParticleType.lightning:
        return ParticleConfig(
          colors: [Colors.yellow, Colors.white, Colors.blue],
          minSize: 4.0,
          maxSize: 12.0,
          minLife: 0.3,
          maxLife: 1.0,
          spread: 60.0,
          speed: 150.0,
          count: 5,
        );
        
      case ParticleType.earth:
        return ParticleConfig(
          colors: [Colors.brown, Colors.green.shade800, Colors.grey],
          minSize: 4.0,
          maxSize: 10.0,
          minLife: 2.0,
          maxLife: 3.5,
          spread: 25.0,
          speed: 30.0,
          count: 2,
        );
        
      case ParticleType.water:
        return ParticleConfig(
          colors: [Colors.blue, Colors.lightBlue, Colors.cyan],
          minSize: 3.0,
          maxSize: 7.0,
          minLife: 1.5,
          maxLife: 3.0,
          spread: 35.0,
          speed: 60.0,
          count: 3,
        );
        
      case ParticleType.light:
        return ParticleConfig(
          colors: [Colors.white, Colors.yellow, Colors.amber],
          minSize: 5.0,
          maxSize: 15.0,
          minLife: 1.0,
          maxLife: 2.0,
          spread: 45.0,
          speed: 70.0,
          count: 4,
        );
        
      case ParticleType.shadow:
        return ParticleConfig(
          colors: [Colors.black, Colors.purple.shade900, Colors.grey.shade800],
          minSize: 6.0,
          maxSize: 14.0,
          minLife: 1.5,
          maxLife: 3.0,
          spread: 50.0,
          speed: 50.0,
          count: 3,
        );
        
      case ParticleType.heal:
        return ParticleConfig(
          colors: [Colors.green, Colors.lightGreen, Colors.white],
          minSize: 4.0,
          maxSize: 8.0,
          minLife: 2.0,
          maxLife: 3.5,
          spread: 20.0,
          speed: -30.0, // Upward movement
          count: 3,
        );
        
      case ParticleType.burn:
        return ParticleConfig(
          colors: [Colors.red, Colors.orange, Colors.yellow.shade800],
          minSize: 2.0,
          maxSize: 5.0,
          minLife: 0.8,
          maxLife: 1.5,
          spread: 15.0,
          speed: 40.0,
          count: 4,
        );
        
      case ParticleType.freeze:
        return ParticleConfig(
          colors: [Colors.cyan, Colors.white, Colors.lightBlue.shade100],
          minSize: 3.0,
          maxSize: 6.0,
          minLife: 3.0,
          maxLife: 5.0,
          spread: 10.0,
          speed: 20.0,
          count: 2,
        );
        
      case ParticleType.shock:
        return ParticleConfig(
          colors: [Colors.yellow, Colors.white, Colors.blue.shade300],
          minSize: 2.0,
          maxSize: 8.0,
          minLife: 0.2,
          maxLife: 0.8,
          spread: 40.0,
          speed: 120.0,
          count: 6,
        );
        
      case ParticleType.strengthBoost:
        return ParticleConfig(
          colors: [Colors.red, Colors.orange, Colors.yellow],
          minSize: 6.0,
          maxSize: 12.0,
          minLife: 1.5,
          maxLife: 2.5,
          spread: 30.0,
          speed: -50.0, // Upward
          count: 2,
        );
        
      case ParticleType.shield:
        return ParticleConfig(
          colors: [Colors.blue, Colors.cyan, Colors.white],
          minSize: 8.0,
          maxSize: 16.0,
          minLife: 2.0,
          maxLife: 4.0,
          spread: 360.0, // Full circle
          speed: 25.0,
          count: 1,
        );
        
      case ParticleType.explosion:
        return ParticleConfig(
          colors: [Colors.white, Colors.yellow, Colors.orange, Colors.red],
          minSize: 8.0,
          maxSize: 20.0,
          minLife: 0.5,
          maxLife: 1.5,
          spread: 360.0,
          speed: 200.0,
          count: 8,
        );
        
      case ParticleType.dispel:
        return ParticleConfig(
          colors: [Colors.purple, Colors.pink, Colors.white],
          minSize: 6.0,
          maxSize: 14.0,
          minLife: 1.0,
          maxLife: 2.0,
          spread: 360.0,
          speed: -80.0, // Inward
          count: 5,
        );
        
      default:
        return ParticleConfig(
          colors: [Colors.white],
          minSize: 4.0,
          maxSize: 8.0,
          minLife: 1.0,
          maxLife: 2.0,
          spread: 30.0,
          speed: 50.0,
          count: 2,
        );
    }
  }
  
  Particle _createParticle(ParticleConfig config) {
    final angle = (_random.nextDouble() * config.spread - config.spread / 2) * math.pi / 180;
    final speed = config.speed + (_random.nextDouble() - 0.5) * config.speed * 0.3;
    final life = config.minLife + _random.nextDouble() * (config.maxLife - config.minLife);
    
    // Special movement patterns for certain effects
    Offset velocity;
    if (widget.type == ParticleType.dispel) {
      // Spiral inward
      velocity = Offset(
        math.cos(angle) * speed.abs(),
        math.sin(angle) * speed.abs(),
      );
    } else if (widget.type == ParticleType.heal || widget.type == ParticleType.blessing) {
      // Gentle upward float
      velocity = Offset(
        math.cos(angle) * speed.abs() * 0.3,
        -speed.abs(),
      );
    } else {
      velocity = Offset(
        math.cos(angle) * speed,
        math.sin(angle) * speed,
      );
    }
    
    return Particle(
      position: widget.center + Offset(
        (_random.nextDouble() - 0.5) * 20,
        (_random.nextDouble() - 0.5) * 20,
      ),
      velocity: velocity,
      size: config.minSize + _random.nextDouble() * (config.maxSize - config.minSize),
      color: config.colors[_random.nextInt(config.colors.length)],
      life: life,
      maxLife: life,
      rotationSpeed: (_random.nextDouble() - 0.5) * 4.0,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        _updateParticles();
        
        return Stack(
          children: [
            if (widget.child != null) widget.child!,
            CustomPaint(
              painter: ParticlePainter(_particles),
              size: Size.infinite,
            ),
          ],
        );
      },
    );
  }
  
  void _updateParticles() {
    const deltaTime = 0.016; // 60 FPS
    
    for (int i = _particles.length - 1; i >= 0; i--) {
      _particles[i].update(deltaTime);
      
      if (_particles[i].isDead) {
        _particles.removeAt(i);
      }
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _spawnTimer.cancel();
    super.dispose();
  }
}

class ParticleConfig {
  final List<Color> colors;
  final double minSize;
  final double maxSize;
  final double minLife;
  final double maxLife;
  final double spread; // degrees
  final double speed;
  final int count;
  
  ParticleConfig({
    required this.colors,
    required this.minSize,
    required this.maxSize,
    required this.minLife,
    required this.maxLife,
    required this.spread,
    required this.speed,
    required this.count,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  
  ParticlePainter(this.particles);
  
  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;
      
      // Draw particle based on type-specific shapes
      canvas.save();
      canvas.translate(particle.position.dx, particle.position.dy);
      canvas.rotate(particle.rotation);
      
      // Different shapes for different effects
      if (particle.color.value == Colors.lightBlue.value || 
          particle.color.value == Colors.yellow.value) {
        // Lightning - jagged shape
        _drawLightning(canvas, paint, particle.size);
      } else if (particle.color.value == Colors.cyan.value ||
                 particle.color.value == Colors.lightBlue.value) {
        // Ice - crystalline shape
        _drawCrystal(canvas, paint, particle.size);
      } else if (particle.color.value == Colors.green.value && 
                 particle.velocity.dy < 0) {
        // Healing - plus shape
        _drawPlus(canvas, paint, particle.size);
      } else {
        // Default circle
        canvas.drawCircle(Offset.zero, particle.size, paint);
      }
      
      canvas.restore();
    }
  }
  
  void _drawLightning(Canvas canvas, Paint paint, double size) {
    final path = Path();
    path.moveTo(-size, -size);
    path.lineTo(size * 0.3, -size * 0.3);
    path.lineTo(-size * 0.2, size * 0.2);
    path.lineTo(size, size);
    path.lineTo(size * 0.2, size * 0.5);
    path.lineTo(-size * 0.5, -size * 0.2);
    path.close();
    canvas.drawPath(path, paint);
  }
  
  void _drawCrystal(Canvas canvas, Paint paint, double size) {
    final path = Path();
    path.moveTo(0, -size);
    path.lineTo(size * 0.7, -size * 0.3);
    path.lineTo(size * 0.7, size * 0.3);
    path.lineTo(0, size);
    path.lineTo(-size * 0.7, size * 0.3);
    path.lineTo(-size * 0.7, -size * 0.3);
    path.close();
    canvas.drawPath(path, paint);
  }
  
  void _drawPlus(Canvas canvas, Paint paint, double size) {
    final rect1 = Rect.fromCenter(center: Offset.zero, width: size * 2, height: size * 0.6);
    final rect2 = Rect.fromCenter(center: Offset.zero, width: size * 0.6, height: size * 2);
    canvas.drawRect(rect1, paint);
    canvas.drawRect(rect2, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Helper to create common particle effects
class ParticleEffects {
  static Widget fireSpell({required Widget child}) {
    return ParticleSystem(
      type: ParticleType.fire,
      center: const Offset(50, 50),
      duration: const Duration(seconds: 2),
      intensity: 1.5,
      child: child,
    );
  }
  
  static Widget iceSpell({required Widget child}) {
    return ParticleSystem(
      type: ParticleType.ice,
      center: const Offset(50, 50),
      duration: const Duration(seconds: 2),
      intensity: 1.2,
      child: child,
    );
  }
  
  static Widget lightningSpell({required Widget child}) {
    return ParticleSystem(
      type: ParticleType.lightning,
      center: const Offset(50, 50),
      duration: const Duration(seconds: 1),
      intensity: 2.0,
      child: child,
    );
  }
  
  static Widget healingEffect({required Widget child}) {
    return ParticleSystem(
      type: ParticleType.heal,
      center: const Offset(50, 100),
      duration: const Duration(seconds: 3),
      intensity: 1.0,
      child: child,
    );
  }
  
  static Widget explosionEffect({required Widget child}) {
    return ParticleSystem(
      type: ParticleType.explosion,
      center: const Offset(50, 50),
      duration: const Duration(seconds: 1),
      intensity: 3.0,
      child: child,
    );
  }
  
  static Widget statusEffect(ParticleType type, {required Widget child, bool continuous = true}) {
    return ParticleSystem(
      type: type,
      center: const Offset(50, 50),
      continuous: continuous,
      duration: const Duration(seconds: 5),
      intensity: 0.8,
      child: child,
    );
  }
}