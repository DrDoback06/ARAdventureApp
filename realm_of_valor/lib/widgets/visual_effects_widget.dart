import 'package:flutter/material.dart';
import 'dart:math' as math;

class VisualEffectsWidget extends StatefulWidget {
  final Widget child;
  final List<VisualEffect> effects;

  const VisualEffectsWidget({
    super.key,
    required this.child,
    required this.effects,
  });

  @override
  State<VisualEffectsWidget> createState() => _VisualEffectsWidgetState();
}

class _VisualEffectsWidgetState extends State<VisualEffectsWidget>
    with TickerProviderStateMixin {
  late AnimationController _damageController;
  late AnimationController _elementalController;
  late AnimationController _screenShakeController;
  
  late Animation<double> _damageAnimation;
  late Animation<double> _elementalAnimation;
  late Animation<double> _screenShakeAnimation;

  @override
  void initState() {
    super.initState();
    
    _damageController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _elementalController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _screenShakeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _damageAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _damageController, curve: Curves.easeOut),
    );
    
    _elementalAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _elementalController, curve: Curves.easeInOut),
    );
    
    _screenShakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _screenShakeController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _damageController.dispose();
    _elementalController.dispose();
    _screenShakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content
        widget.child,
        
        // Visual effects overlay
        ...widget.effects.map((effect) {
          switch (effect.type) {
            case VisualEffectType.damageNumber:
              return _buildDamageNumber(effect);
            case VisualEffectType.elementalEffect:
              return _buildElementalEffect(effect);
            case VisualEffectType.screenShake:
              return _buildScreenShake(effect);
            case VisualEffectType.criticalHit:
              return _buildCriticalHit(effect);
            default:
              return const SizedBox.shrink();
          }
        }).toList(),
      ],
    );
  }

  Widget _buildDamageNumber(VisualEffect effect) {
    return AnimatedBuilder(
      animation: _damageAnimation,
      builder: (context, child) {
        final progress = _damageAnimation.value;
        final offset = Offset(
          effect.position.dx + (math.Random().nextDouble() - 0.5) * 20,
          effect.position.dy - progress * 100,
        );
        
        return Positioned(
          left: offset.dx,
          top: offset.dy,
          child: Opacity(
            opacity: 1.0 - progress,
            child: Transform.scale(
              scale: 1.0 + progress * 0.5,
              child: Text(
                effect.data['damage']?.toString() ?? '0',
                style: TextStyle(
                  color: effect.data['isCritical'] == true 
                      ? Colors.red 
                      : Colors.orange,
                  fontSize: 20 + progress * 10,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      offset: const Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildElementalEffect(VisualEffect effect) {
    return AnimatedBuilder(
      animation: _elementalAnimation,
      builder: (context, child) {
        final progress = _elementalAnimation.value;
        
        return Positioned(
          left: effect.position.dx - 25,
          top: effect.position.dy - 25,
          child: Opacity(
            opacity: 1.0 - progress,
            child: Transform.scale(
              scale: 1.0 + progress * 2.0,
              child: _getElementalIcon(effect.data['element']),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScreenShake(VisualEffect effect) {
    return AnimatedBuilder(
      animation: _screenShakeAnimation,
      builder: (context, child) {
        final progress = _screenShakeAnimation.value;
        final shake = math.sin(progress * math.pi * 10) * 5 * (1.0 - progress);
        
        return Transform.translate(
          offset: Offset(shake, 0),
          child: widget.child,
        );
      },
    );
  }

  Widget _buildCriticalHit(VisualEffect effect) {
    return AnimatedBuilder(
      animation: _elementalAnimation,
      builder: (context, child) {
        final progress = _elementalAnimation.value;
        
        return Positioned(
          left: effect.position.dx - 50,
          top: effect.position.dy - 50,
          child: Opacity(
            opacity: 1.0 - progress,
            child: Transform.scale(
              scale: 1.0 + progress * 1.5,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.red,
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.flash_on,
                  color: Colors.red,
                  size: 50,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _getElementalIcon(String? element) {
    switch (element?.toLowerCase()) {
      case 'fire':
        return const Icon(Icons.local_fire_department, color: Colors.orange, size: 50);
      case 'ice':
        return const Icon(Icons.ac_unit, color: Colors.cyan, size: 50);
      case 'lightning':
        return const Icon(Icons.electric_bolt, color: Colors.yellow, size: 50);
      case 'poison':
        return const Icon(Icons.water_drop, color: Colors.green, size: 50);
      default:
        return const Icon(Icons.star, color: Colors.white, size: 50);
    }
  }
}

enum VisualEffectType {
  damageNumber,
  elementalEffect,
  screenShake,
  criticalHit,
}

class VisualEffect {
  final VisualEffectType type;
  final Offset position;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  VisualEffect({
    required this.type,
    required this.position,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
} 