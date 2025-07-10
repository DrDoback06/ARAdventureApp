import 'package:flutter/material.dart';
import 'package:realm_of_valor/effects/particle_system.dart';
import 'dart:math' as math;

enum StatusEffectType {
  // Elemental Effects
  burning,
  frozen,
  shocked,
  poisoned,
  blessed,
  cursed,
  
  // Buff Effects
  strengthened,
  hastened,
  magicPowered,
  shielded,
  regenerating,
  invulnerable,
  
  // Debuff Effects
  weakened,
  slowed,
  silenced,
  blinded,
  confused,
  drained,
  
  // Special Effects
  charging,
  channeling,
  absorbing,
  reflecting,
  transforming,
}

class StatusEffect {
  final StatusEffectType type;
  final String name;
  final String description;
  final int duration; // turns or seconds
  final double intensity;
  final Color primaryColor;
  final Color secondaryColor;
  final IconData icon;
  final bool isPositive;
  
  StatusEffect({
    required this.type,
    required this.name,
    required this.description,
    required this.duration,
    this.intensity = 1.0,
    required this.primaryColor,
    required this.secondaryColor,
    required this.icon,
    required this.isPositive,
  });
  
  static StatusEffect burning({int duration = 3}) => StatusEffect(
    type: StatusEffectType.burning,
    name: 'Burning',
    description: 'Taking fire damage over time',
    duration: duration,
    primaryColor: Colors.red,
    secondaryColor: Colors.orange,
    icon: Icons.local_fire_department,
    isPositive: false,
  );
  
  static StatusEffect frozen({int duration = 2}) => StatusEffect(
    type: StatusEffectType.frozen,
    name: 'Frozen',
    description: 'Movement and actions slowed',
    duration: duration,
    primaryColor: Colors.cyan,
    secondaryColor: Colors.lightBlue,
    icon: Icons.ac_unit,
    isPositive: false,
  );
  
  static StatusEffect shocked({int duration = 1}) => StatusEffect(
    type: StatusEffectType.shocked,
    name: 'Shocked',
    description: 'Stunned by electrical energy',
    duration: duration,
    primaryColor: Colors.yellow,
    secondaryColor: Colors.white,
    icon: Icons.flash_on,
    isPositive: false,
  );
  
  static StatusEffect strengthened({int duration = 3}) => StatusEffect(
    type: StatusEffectType.strengthened,
    name: 'Strengthened',
    description: 'Attack power increased',
    duration: duration,
    primaryColor: Colors.red,
    secondaryColor: Colors.orange,
    icon: Icons.fitness_center,
    isPositive: true,
  );
  
  static StatusEffect hastened({int duration = 2}) => StatusEffect(
    type: StatusEffectType.hastened,
    name: 'Hastened',
    description: 'Movement speed increased',
    duration: duration,
    primaryColor: Colors.green,
    secondaryColor: Colors.lightGreen,
    icon: Icons.speed,
    isPositive: true,
  );
  
  static StatusEffect shielded({int duration = 4}) => StatusEffect(
    type: StatusEffectType.shielded,
    name: 'Shielded',
    description: 'Protected by magical barrier',
    duration: duration,
    primaryColor: Colors.blue,
    secondaryColor: Colors.cyan,
    icon: Icons.shield,
    isPositive: true,
  );
  
  static StatusEffect regenerating({int duration = 5}) => StatusEffect(
    type: StatusEffectType.regenerating,
    name: 'Regenerating',
    description: 'Healing over time',
    duration: duration,
    primaryColor: Colors.green,
    secondaryColor: Colors.lightGreen,
    icon: Icons.healing,
    isPositive: true,
  );
  
  static StatusEffect weakened({int duration = 2}) => StatusEffect(
    type: StatusEffectType.weakened,
    name: 'Weakened',
    description: 'Attack power reduced',
    duration: duration,
    primaryColor: Colors.grey,
    secondaryColor: Colors.blueGrey,
    icon: Icons.trending_down,
    isPositive: false,
  );
  
  static StatusEffect silenced({int duration = 1}) => StatusEffect(
    type: StatusEffectType.silenced,
    name: 'Silenced',
    description: 'Cannot cast spells',
    duration: duration,
    primaryColor: Colors.purple,
    secondaryColor: Colors.deepPurple,
    icon: Icons.volume_off,
    isPositive: false,
  );
  
  static StatusEffect blessed({int duration = 3}) => StatusEffect(
    type: StatusEffectType.blessed,
    name: 'Blessed',
    description: 'Enhanced by divine power',
    duration: duration,
    primaryColor: Colors.yellow,
    secondaryColor: Colors.white,
    icon: Icons.auto_awesome,
    isPositive: true,
  );
}

class StatusEffectOverlay extends StatefulWidget {
  final List<StatusEffect> statusEffects;
  final Widget child;
  final double size;
  
  const StatusEffectOverlay({
    Key? key,
    required this.statusEffects,
    required this.child,
    this.size = 100.0,
  }) : super(key: key);

  @override
  State<StatusEffectOverlay> createState() => _StatusEffectOverlayState();
}

class _StatusEffectOverlayState extends State<StatusEffectOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 8000),
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
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
    
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Child widget (player portrait)
        widget.child,
        
        // Status effect particles
        ...widget.statusEffects.map((effect) => _buildStatusParticles(effect)),
        
        // Status effect border glow
        if (widget.statusEffects.isNotEmpty)
          _buildStatusBorder(),
        
        // Status effect icons
        if (widget.statusEffects.isNotEmpty)
          _buildStatusIcons(),
      ],
    );
  }
  
  Widget _buildStatusParticles(StatusEffect effect) {
    ParticleType particleType;
    
    switch (effect.type) {
      case StatusEffectType.burning:
        particleType = ParticleType.burn;
        break;
      case StatusEffectType.frozen:
        particleType = ParticleType.freeze;
        break;
      case StatusEffectType.shocked:
        particleType = ParticleType.shock;
        break;
      case StatusEffectType.strengthened:
        particleType = ParticleType.strengthBoost;
        break;
      case StatusEffectType.shielded:
        particleType = ParticleType.shield;
        break;
      case StatusEffectType.regenerating:
        particleType = ParticleType.heal;
        break;
      case StatusEffectType.blessed:
        particleType = ParticleType.light;
        break;
      case StatusEffectType.cursed:
        particleType = ParticleType.shadow;
        break;
      case StatusEffectType.poisoned:
        particleType = ParticleType.nature;
        break;
      default:
        particleType = ParticleType.sparkle;
    }
    
    return ParticleSystem(
      type: particleType,
      center: Offset(widget.size / 2, widget.size / 2),
      continuous: true,
      intensity: effect.intensity * 0.6,
      child: Container(),
    );
  }
  
  Widget _buildStatusBorder() {
    final dominantEffect = _getDominantEffect();
    if (dominantEffect == null) return Container();
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: dominantEffect.primaryColor.withOpacity(0.8),
              width: 3.0 * _pulseAnimation.value,
            ),
            boxShadow: [
              BoxShadow(
                color: dominantEffect.primaryColor.withOpacity(0.5),
                blurRadius: 15.0 * _pulseAnimation.value,
                spreadRadius: 3.0 * _pulseAnimation.value,
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildStatusIcons() {
    return Positioned(
      top: 0,
      right: 0,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: widget.size * 0.6,
          maxHeight: widget.size * 0.3,
        ),
        child: Wrap(
          children: widget.statusEffects.take(3).map((effect) => 
            _buildStatusIcon(effect)
          ).toList(),
        ),
      ),
    );
  }
  
  Widget _buildStatusIcon(StatusEffect effect) {
    return AnimatedBuilder(
      animation: effect.isPositive ? _pulseAnimation : _rotationAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: effect.isPositive ? _pulseAnimation.value * 0.3 + 0.7 : 1.0,
          child: Transform.rotate(
            angle: effect.isPositive ? 0.0 : _rotationAnimation.value,
            child: Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [effect.primaryColor, effect.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: effect.primaryColor.withOpacity(0.6),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                effect.icon,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
  
  StatusEffect? _getDominantEffect() {
    if (widget.statusEffects.isEmpty) return null;
    
    // Prioritize negative effects for more dramatic visuals
    final negativeEffects = widget.statusEffects.where((e) => !e.isPositive).toList();
    if (negativeEffects.isNotEmpty) {
      return negativeEffects.first;
    }
    
    return widget.statusEffects.first;
  }
}

// Status Effect Indicator Widget for Battle Log and UI
class StatusEffectIndicator extends StatelessWidget {
  final StatusEffect effect;
  final bool showDuration;
  final double size;
  
  const StatusEffectIndicator({
    Key? key,
    required this.effect,
    this.showDuration = true,
    this.size = 40.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${effect.name}: ${effect.description}${showDuration ? ' (${effect.duration} turns)' : ''}',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [effect.primaryColor, effect.secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: effect.isPositive ? Colors.green : Colors.red,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: effect.primaryColor.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                effect.icon,
                size: size * 0.5,
                color: Colors.white,
              ),
            ),
            if (showDuration)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.7),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Center(
                    child: Text(
                      '${effect.duration}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Animated Status Effect Banner for Major Effects
class StatusEffectBanner extends StatefulWidget {
  final StatusEffect effect;
  final VoidCallback? onComplete;
  
  const StatusEffectBanner({
    Key? key,
    required this.effect,
    this.onComplete,
  }) : super(key: key);

  @override
  State<StatusEffectBanner> createState() => _StatusEffectBannerState();
}

class _StatusEffectBannerState extends State<StatusEffectBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    ));
    
    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value * MediaQuery.of(context).size.width, 0),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.effect.primaryColor.withOpacity(0.9),
                    widget.effect.secondaryColor.withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: widget.effect.isPositive ? Colors.green : Colors.red,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.effect.primaryColor.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.effect.icon,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.effect.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        widget.effect.description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Helper class to manage status effects
class StatusEffectManager {
  static List<StatusEffect> getRandomStatusEffects() {
    final effects = [
      StatusEffect.burning(),
      StatusEffect.frozen(),
      StatusEffect.strengthened(),
      StatusEffect.shielded(),
      StatusEffect.regenerating(),
      StatusEffect.weakened(),
      StatusEffect.silenced(),
      StatusEffect.blessed(),
    ];
    
    final random = math.Random();
    final count = random.nextInt(3) + 1;
    effects.shuffle(random);
    return effects.take(count).toList();
  }
  
  static StatusEffect getEffectForSpell(String spellName) {
    final name = spellName.toLowerCase();
    
    if (name.contains('fire') || name.contains('burn')) {
      return StatusEffect.burning();
    } else if (name.contains('ice') || name.contains('freeze')) {
      return StatusEffect.frozen();
    } else if (name.contains('lightning') || name.contains('shock')) {
      return StatusEffect.shocked();
    } else if (name.contains('heal') || name.contains('regenerat')) {
      return StatusEffect.regenerating();
    } else if (name.contains('shield') || name.contains('protect')) {
      return StatusEffect.shielded();
    } else if (name.contains('strength') || name.contains('power')) {
      return StatusEffect.strengthened();
    } else if (name.contains('speed') || name.contains('haste')) {
      return StatusEffect.hastened();
    } else if (name.contains('weak') || name.contains('drain')) {
      return StatusEffect.weakened();
    } else if (name.contains('silence') || name.contains('mute')) {
      return StatusEffect.silenced();
    } else if (name.contains('bless') || name.contains('divine')) {
      return StatusEffect.blessed();
    }
    
    return StatusEffect.strengthened(); // Default
  }
}