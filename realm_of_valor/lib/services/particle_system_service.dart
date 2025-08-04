import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/unified_particle_system.dart';

enum ParticleBehavior {
  fade,
  explode,
  spiral,
  wave,
  random,
  follow,
  gravity,
  wind,
}

class Particle {
  final String id;
  final ParticleType type;
  final Offset position;
  final Offset velocity;
  final Color color;
  final double size;
  final double life;
  final double maxLife;
  final ParticleBehavior behavior;
  final Map<String, dynamic> properties;

  Particle({
    String? id,
    required this.type,
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.life,
    required this.maxLife,
    this.behavior = ParticleBehavior.fade,
    Map<String, dynamic>? properties,
  })  : id = id ?? _generateParticleId(),
        properties = properties ?? {};

  static String _generateParticleId() {
    return 'particle_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}';
  }

  bool get isAlive => life > 0;
  double get lifePercentage => life / maxLife;

  Particle copyWith({
    String? id,
    ParticleType? type,
    Offset? position,
    Offset? velocity,
    Color? color,
    double? size,
    double? life,
    double? maxLife,
    ParticleBehavior? behavior,
    Map<String, dynamic>? properties,
  }) {
    return Particle(
      id: id ?? this.id,
      type: type ?? this.type,
      position: position ?? this.position,
      velocity: velocity ?? this.velocity,
      color: color ?? this.color,
      size: size ?? this.size,
      life: life ?? this.life,
      maxLife: maxLife ?? this.maxLife,
      behavior: behavior ?? this.behavior,
      properties: properties ?? this.properties,
    );
  }
}

class ParticleSystem {
  final String id;
  final List<Particle> particles;
  final Offset origin;
  final ParticleType type;
  final int maxParticles;
  final Duration duration;
  final bool autoDestroy;

  ParticleSystem({
    String? id,
    List<Particle>? particles,
    required this.origin,
    required this.type,
    this.maxParticles = 50,
    this.duration = const Duration(seconds: 2),
    this.autoDestroy = true,
  })  : id = id ?? _generateSystemId(),
        particles = particles ?? [];

  static String _generateSystemId() {
    return 'system_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}';
  }

  bool get isActive => particles.any((p) => p.isAlive);
  int get activeParticleCount => particles.where((p) => p.isAlive).length;
}

class ParticleSystemService extends ChangeNotifier {
  static ParticleSystemService? _instance;
  static ParticleSystemService get instance => _instance ??= ParticleSystemService._();
  
  ParticleSystemService._();
  
  List<ParticleSystem> _activeSystems = [];
  bool _isEnabled = true;
  int _maxSystems = 10;
  
  // Getters
  List<ParticleSystem> get activeSystems => _activeSystems;
  bool get isEnabled => _isEnabled;
  int get totalActiveParticles => _activeSystems.fold(0, (sum, system) => sum + system.activeParticleCount);

  // Initialize particle system
  void initialize() {
    _isEnabled = true;
    debugPrint('[PARTICLE_SYSTEM] Service initialized');
  }

  // Create fire particles
  ParticleSystem createFireEffect(Offset position, {int count = 20}) {
    final particles = <Particle>[];
    final random = math.Random();
    
    for (int i = 0; i < count; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final speed = 50 + random.nextDouble() * 100;
      final velocity = Offset(
        math.cos(angle) * speed,
        math.sin(angle) * speed - 100, // Upward bias
      );
      
      particles.add(Particle(
        type: ParticleType.fire,
        position: position,
        velocity: velocity,
        color: Color.lerp(Colors.orange, Colors.red, random.nextDouble())!,
        size: 3 + random.nextDouble() * 5,
        life: 1.0 + random.nextDouble() * 1.0,
        maxLife: 1.0 + random.nextDouble() * 1.0,
        behavior: ParticleBehavior.fade,
        properties: {
          'gravity': -50.0,
          'fadeRate': 0.02,
        },
      ));
    }
    
    final system = ParticleSystem(
      origin: position,
      type: ParticleType.fire,
      maxParticles: count,
      duration: const Duration(milliseconds: 1500),
    );
    
    _activeSystems.add(system);
    notifyListeners();
    return system;
  }

  // Create ice particles
  ParticleSystem createIceEffect(Offset position, {int count = 15}) {
    final particles = <Particle>[];
    final random = math.Random();
    
    for (int i = 0; i < count; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final speed = 30 + random.nextDouble() * 60;
      final velocity = Offset(
        math.cos(angle) * speed,
        math.sin(angle) * speed,
      );
      
      particles.add(Particle(
        type: ParticleType.ice,
        position: position,
        velocity: velocity,
        color: Color.lerp(Colors.lightBlue, Colors.blue, random.nextDouble())!,
        size: 2 + random.nextDouble() * 4,
        life: 2.0 + random.nextDouble() * 1.0,
        maxLife: 2.0 + random.nextDouble() * 1.0,
        behavior: ParticleBehavior.fade,
        properties: {
          'gravity': -20.0,
          'fadeRate': 0.015,
        },
      ));
    }
    
    final system = ParticleSystem(
      origin: position,
      type: ParticleType.ice,
      maxParticles: count,
      duration: const Duration(milliseconds: 2000),
    );
    
    _activeSystems.add(system);
    notifyListeners();
    return system;
  }

  // Create lightning particles
  ParticleSystem createLightningEffect(Offset start, Offset end) {
    final particles = <Particle>[];
    final random = math.Random();
    final distance = (end - start).distance;
    final segments = (distance / 20).round();
    
    for (int i = 0; i < segments; i++) {
      final t = i / segments;
      final position = Offset.lerp(start, end, t)!;
      final offset = Offset(
        (random.nextDouble() - 0.5) * 10,
        (random.nextDouble() - 0.5) * 10,
      );
      
      particles.add(Particle(
        type: ParticleType.lightning,
        position: position + offset,
        velocity: Offset.zero,
        color: Colors.yellow,
        size: 2 + random.nextDouble() * 3,
        life: 0.3 + random.nextDouble() * 0.2,
        maxLife: 0.3 + random.nextDouble() * 0.2,
        behavior: ParticleBehavior.fade,
        properties: {
          'fadeRate': 0.1,
        },
      ));
    }
    
    final system = ParticleSystem(
      origin: start,
      type: ParticleType.lightning,
      maxParticles: segments,
      duration: const Duration(milliseconds: 300),
    );
    
    _activeSystems.add(system);
    notifyListeners();
    return system;
  }

  // Create healing particles
  ParticleSystem createHealingEffect(Offset position, {int count = 12}) {
    final particles = <Particle>[];
    final random = math.Random();
    
    for (int i = 0; i < count; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final speed = 40 + random.nextDouble() * 60;
      final velocity = Offset(
        math.cos(angle) * speed,
        math.sin(angle) * speed - 80, // Upward bias
      );
      
      particles.add(Particle(
        type: ParticleType.healing,
        position: position,
        velocity: velocity,
        color: Color.lerp(Colors.green, Colors.lightGreen, random.nextDouble())!,
        size: 3 + random.nextDouble() * 4,
        life: 1.5 + random.nextDouble() * 1.0,
        maxLife: 1.5 + random.nextDouble() * 1.0,
        behavior: ParticleBehavior.fade,
        properties: {
          'gravity': -30.0,
          'fadeRate': 0.02,
        },
      ));
    }
    
    final system = ParticleSystem(
      origin: position,
      type: ParticleType.healing,
      maxParticles: count,
      duration: const Duration(milliseconds: 1800),
    );
    
    _activeSystems.add(system);
    notifyListeners();
    return system;
  }

  // Create damage particles
  ParticleSystem createDamageEffect(Offset position, {int count = 8}) {
    final particles = <Particle>[];
    final random = math.Random();
    
    for (int i = 0; i < count; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final speed = 60 + random.nextDouble() * 80;
      final velocity = Offset(
        math.cos(angle) * speed,
        math.sin(angle) * speed,
      );
      
      particles.add(Particle(
        type: ParticleType.damage,
        position: position,
        velocity: velocity,
        color: Colors.red,
        size: 4 + random.nextDouble() * 6,
        life: 0.8 + random.nextDouble() * 0.4,
        maxLife: 0.8 + random.nextDouble() * 0.4,
        behavior: ParticleBehavior.fade,
        properties: {
          'gravity': -40.0,
          'fadeRate': 0.03,
        },
      ));
    }
    
    final system = ParticleSystem(
      origin: position,
      type: ParticleType.damage,
      maxParticles: count,
      duration: const Duration(milliseconds: 1200),
    );
    
    _activeSystems.add(system);
    notifyListeners();
    return system;
  }

  // Create explosion particles
  ParticleSystem createExplosionEffect(Offset position, {int count = 30}) {
    final particles = <Particle>[];
    final random = math.Random();
    
    for (int i = 0; i < count; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final speed = 80 + random.nextDouble() * 120;
      final velocity = Offset(
        math.cos(angle) * speed,
        math.sin(angle) * speed,
      );
      
      final colors = [Colors.orange, Colors.red, Colors.yellow, Colors.white];
      final color = colors[random.nextInt(colors.length)];
      
      particles.add(Particle(
        type: ParticleType.explosion,
        position: position,
        velocity: velocity,
        color: color,
        size: 5 + random.nextDouble() * 8,
        life: 1.0 + random.nextDouble() * 1.0,
        maxLife: 1.0 + random.nextDouble() * 1.0,
        behavior: ParticleBehavior.explode,
        properties: {
          'gravity': -60.0,
          'fadeRate': 0.025,
        },
      ));
    }
    
    final system = ParticleSystem(
      origin: position,
      type: ParticleType.explosion,
      maxParticles: count,
      duration: const Duration(milliseconds: 1500),
    );
    
    _activeSystems.add(system);
    notifyListeners();
    return system;
  }

  // Create sparkle particles
  ParticleSystem createSparkleEffect(Offset position, {int count = 10}) {
    final particles = <Particle>[];
    final random = math.Random();
    
    for (int i = 0; i < count; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final speed = 20 + random.nextDouble() * 40;
      final velocity = Offset(
        math.cos(angle) * speed,
        math.sin(angle) * speed - 30,
      );
      
      particles.add(Particle(
        type: ParticleType.sparkle,
        position: position,
        velocity: velocity,
        color: Color.lerp(Colors.yellow, Colors.white, random.nextDouble())!,
        size: 2 + random.nextDouble() * 3,
        life: 2.0 + random.nextDouble() * 1.0,
        maxLife: 2.0 + random.nextDouble() * 1.0,
        behavior: ParticleBehavior.spiral,
        properties: {
          'gravity': -15.0,
          'fadeRate': 0.01,
          'spiralRate': 0.1,
        },
      ));
    }
    
    final system = ParticleSystem(
      origin: position,
      type: ParticleType.sparkle,
      maxParticles: count,
      duration: const Duration(milliseconds: 2500),
    );
    
    _activeSystems.add(system);
    notifyListeners();
    return system;
  }

  // Update all particle systems
  void update(double deltaTime) {
    if (!_isEnabled) return;
    
    for (final system in _activeSystems) {
      for (final particle in system.particles) {
        if (!particle.isAlive) continue;
        
        // Update position
        final newPosition = particle.position + particle.velocity * deltaTime;
        
        // Update velocity based on behavior
        Offset newVelocity = particle.velocity;
        switch (particle.behavior) {
          case ParticleBehavior.gravity:
            final gravity = particle.properties['gravity'] as double? ?? -50.0;
            newVelocity = Offset(newVelocity.dx, newVelocity.dy + gravity * deltaTime);
            break;
          case ParticleBehavior.wind:
            final windForce = particle.properties['windForce'] as Offset? ?? const Offset(10, 0);
            newVelocity += windForce * deltaTime;
            break;
          case ParticleBehavior.spiral:
            final spiralRate = particle.properties['spiralRate'] as double? ?? 0.1;
            final angle = math.atan2(newVelocity.dy, newVelocity.dx) + spiralRate * deltaTime;
            final speed = newVelocity.distance;
            newVelocity = Offset(
              math.cos(angle) * speed,
              math.sin(angle) * speed,
            );
            break;
          default:
            break;
        }
        
        // Update life
        final fadeRate = particle.properties['fadeRate'] as double? ?? 0.02;
        final newLife = particle.life - fadeRate;
        
        // Update particle
        final index = system.particles.indexOf(particle);
        if (index >= 0) {
          system.particles[index] = particle.copyWith(
            position: newPosition,
            velocity: newVelocity,
            life: newLife,
          );
        }
      }
    }
    
    // Remove dead systems
    _activeSystems.removeWhere((system) => !system.isActive);
    notifyListeners();
  }

  // Clear all particle systems
  void clear() {
    _activeSystems.clear();
    notifyListeners();
  }

  // Enable/disable particle system
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      clear();
    }
    notifyListeners();
  }

  // Get particle system statistics
  Map<String, dynamic> getStats() {
    return {
      'activeSystems': _activeSystems.length,
      'totalParticles': totalActiveParticles,
      'isEnabled': _isEnabled,
      'maxSystems': _maxSystems,
    };
  }
} 