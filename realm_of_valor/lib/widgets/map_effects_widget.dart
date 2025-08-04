import 'package:flutter/material.dart';
import 'dart:math';

import '../constants/theme.dart';

class MapEffectsWidget extends StatefulWidget {
  final bool showParticles;
  final dynamic weather; // Weather data for effects

  const MapEffectsWidget({
    super.key,
    this.showParticles = true,
    this.weather,
  });

  @override
  State<MapEffectsWidget> createState() => _MapEffectsWidgetState();
}

class _MapEffectsWidgetState extends State<MapEffectsWidget>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _weatherController;
  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _weatherController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _generateParticles();
  }

  @override
  void dispose() {
    _particleController.dispose();
    _weatherController.dispose();
    super.dispose();
  }

  void _generateParticles() {
    _particles.clear();
    for (int i = 0; i < 20; i++) {
      _particles.add(Particle(
        x: _random.nextDouble() * 400,
        y: _random.nextDouble() * 800,
        speed: 0.5 + _random.nextDouble() * 1.0,
        size: 2 + _random.nextDouble() * 4,
        color: _getParticleColor(),
      ));
    }
  }

  Color _getParticleColor() {
    if (widget.weather != null) {
      // Weather-based particle colors
      final weatherType = widget.weather.toString().toLowerCase();
      if (weatherType.contains('rain')) return Colors.blue;
      if (weatherType.contains('snow')) return Colors.white;
      if (weatherType.contains('storm')) return Colors.purple;
    }
    return RealmOfValorTheme.accentGold;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showParticles) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: Listenable.merge([_particleController, _weatherController]),
      builder: (context, child) {
        return CustomPaint(
          painter: MapEffectsPainter(
            particles: _particles,
            animation: _particleController.value,
            weather: widget.weather,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class MapEffectsPainter extends CustomPainter {
  final List<Particle> particles;
  final double animation;
  final dynamic weather;

  MapEffectsPainter({
    required this.particles,
    required this.animation,
    this.weather,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw particles
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(0.6)
        ..style = PaintingStyle.fill;

      final x = particle.x + (particle.speed * animation * 100);
      final y = particle.y - (particle.speed * animation * 50);

      if (x < size.width && y > 0) {
        canvas.drawCircle(
          Offset(x, y),
          particle.size,
          paint,
        );
      }
    }

    // Draw weather effects
    if (weather != null) {
      _drawWeatherEffects(canvas, size);
    }
  }

  void _drawWeatherEffects(Canvas canvas, Size size) {
    final weatherType = weather.toString().toLowerCase();
    
    if (weatherType.contains('rain')) {
      _drawRain(canvas, size);
    } else if (weatherType.contains('snow')) {
      _drawSnow(canvas, size);
    } else if (weatherType.contains('storm')) {
      _drawStorm(canvas, size);
    }
  }

  void _drawRain(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..strokeWidth = 1;

    for (int i = 0; i < 50; i++) {
      final x = (i * 20) % size.width;
      final y = (animation * 200 + i * 10) % size.height;
      
      canvas.drawLine(
        Offset(x, y),
        Offset(x, y + 20),
        paint,
      );
    }
  }

  void _drawSnow(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 30; i++) {
      final x = (i * 30) % size.width;
      final y = (animation * 100 + i * 15) % size.height;
      
      canvas.drawCircle(
        Offset(x, y),
        2,
        paint,
      );
    }
  }

  void _drawStorm(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.purple.withOpacity(0.4)
      ..strokeWidth = 2;

    for (int i = 0; i < 20; i++) {
      final x = (i * 40) % size.width;
      final y = (animation * 300 + i * 20) % size.height;
      
      canvas.drawLine(
        Offset(x, y),
        Offset(x + 10, y + 30),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Particle {
  final double x;
  final double y;
  final double speed;
  final double size;
  final Color color;

  Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.color,
  });
} 