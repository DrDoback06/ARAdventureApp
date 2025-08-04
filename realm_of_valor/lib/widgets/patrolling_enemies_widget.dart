import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// Patrolling Enemy Widget with AI logic and animated movement
class PatrollingEnemyWidget extends StatefulWidget {
  final EnemyData enemy;
  final double size;
  final VoidCallback? onEncounter;
  final bool isPlayerNearby;

  const PatrollingEnemyWidget({
    Key? key,
    required this.enemy,
    this.size = 50.0,
    this.onEncounter,
    this.isPlayerNearby = false,
  }) : super(key: key);

  @override
  State<PatrollingEnemyWidget> createState() => _PatrollingEnemyWidgetState();
}

class _PatrollingEnemyWidgetState extends State<PatrollingEnemyWidget>
    with TickerProviderStateMixin {
  late AnimationController _movementController;
  late AnimationController _alertController;
  late AnimationController _idleController;
  late AnimationController _combatController;

  late Animation<double> _movementAnimation;
  late Animation<double> _alertAnimation;
  late Animation<double> _idleAnimation;
  late Animation<double> _combatAnimation;

  Position? _currentPosition;
  Position? _targetPosition;
  Timer? _patrolTimer;
  Timer? _behaviorTimer;
  EnemyBehaviorState _currentBehavior = EnemyBehaviorState.patrolling;
  int _currentPatrolIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startPatrolling();
    _startBehaviorUpdates();
  }

  void _initializeAnimations() {
    // Movement animation for patrol routes
    _movementController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _movementAnimation = CurvedAnimation(
      parent: _movementController,
      curve: Curves.easeInOut,
    );

    // Alert animation when player is nearby
    _alertController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _alertAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _alertController,
      curve: Curves.elasticOut,
    ));

    // Idle animation for breathing/floating effect
    _idleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _idleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _idleController,
      curve: Curves.easeInOut,
    ));

    // Combat readiness animation
    _combatController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _combatAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_combatController);

    // Start idle animation
    _idleController.repeat(reverse: true);
  }

  void _startPatrolling() {
    if (widget.enemy.patrolRoute.isNotEmpty) {
      _currentPosition = widget.enemy.patrolRoute.first;
      _moveToNextPatrolPoint();
    }
  }

  void _startBehaviorUpdates() {
    _behaviorTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _updateBehavior();
    });
  }

  void _moveToNextPatrolPoint() {
    if (widget.enemy.patrolRoute.isEmpty) return;

    _currentPatrolIndex = (_currentPatrolIndex + 1) % widget.enemy.patrolRoute.length;
    _targetPosition = widget.enemy.patrolRoute[_currentPatrolIndex];

    _movementController.reset();
    _movementController.forward().then((_) {
      _currentPosition = _targetPosition;
      
      // Wait at patrol point before moving to next
      _patrolTimer = Timer(Duration(seconds: widget.enemy.pauseDuration), () {
        if (mounted && _currentBehavior == EnemyBehaviorState.patrolling) {
          _moveToNextPatrolPoint();
        }
      });
    });
  }

  void _updateBehavior() {
    final oldBehavior = _currentBehavior;
    
    if (widget.isPlayerNearby) {
      switch (widget.enemy.aggressionLevel) {
        case EnemyAggressionLevel.passive:
          _currentBehavior = EnemyBehaviorState.fleeing;
          break;
        case EnemyAggressionLevel.neutral:
          _currentBehavior = EnemyBehaviorState.alert;
          break;
        case EnemyAggressionLevel.aggressive:
        case EnemyAggressionLevel.hostile:
          _currentBehavior = EnemyBehaviorState.pursuing;
          break;
      }
    } else {
      _currentBehavior = EnemyBehaviorState.patrolling;
    }

    if (oldBehavior != _currentBehavior) {
      _onBehaviorChanged(oldBehavior, _currentBehavior);
    }
  }

  void _onBehaviorChanged(EnemyBehaviorState from, EnemyBehaviorState to) {
    switch (to) {
      case EnemyBehaviorState.alert:
        _alertController.forward().then((_) => _alertController.reverse());
        break;
      case EnemyBehaviorState.pursuing:
        _combatController.forward();
        break;
      case EnemyBehaviorState.fleeing:
        // Speed up movement and change direction
        _movementController.duration = const Duration(seconds: 2);
        break;
      case EnemyBehaviorState.patrolling:
        _combatController.reverse();
        _movementController.duration = const Duration(seconds: 4);
        if (from != EnemyBehaviorState.patrolling) {
          _moveToNextPatrolPoint();
        }
        break;
    }
  }

  @override
  void dispose() {
    _movementController.dispose();
    _alertController.dispose();
    _idleController.dispose();
    _combatController.dispose();
    _patrolTimer?.cancel();
    _behaviorTimer?.cancel();
    super.dispose();
  }

  EnemyStyle _getEnemyStyle() {
    switch (widget.enemy.type) {
      case EnemyType.shadow:
        return EnemyStyle(
          avatar: '👻',
          primaryColor: Colors.purple.shade800,
          secondaryColor: Colors.purple.shade600,
          glowColor: Colors.purple.withOpacity(0.6),
          trailColor: Colors.purple.withOpacity(0.3),
        );
      case EnemyType.beast:
        return EnemyStyle(
          avatar: '🐺',
          primaryColor: Colors.brown.shade700,
          secondaryColor: Colors.brown.shade500,
          glowColor: Colors.orange.withOpacity(0.6),
          trailColor: Colors.brown.withOpacity(0.3),
        );
      case EnemyType.elemental:
        return EnemyStyle(
          avatar: '🔥',
          primaryColor: Colors.red.shade700,
          secondaryColor: Colors.orange.shade500,
          glowColor: Colors.red.withOpacity(0.8),
          trailColor: Colors.orange.withOpacity(0.4),
        );
      case EnemyType.undead:
        return EnemyStyle(
          avatar: '💀',
          primaryColor: Colors.grey.shade800,
          secondaryColor: Colors.grey.shade600,
          glowColor: Colors.green.withOpacity(0.6),
          trailColor: Colors.grey.withOpacity(0.3),
        );
      case EnemyType.construct:
        return EnemyStyle(
          avatar: '🤖',
          primaryColor: Colors.blue.shade700,
          secondaryColor: Colors.blue.shade500,
          glowColor: Colors.cyan.withOpacity(0.8),
          trailColor: Colors.blue.withOpacity(0.3),
        );
      case EnemyType.dragon:
        return EnemyStyle(
          avatar: '🐉',
          primaryColor: Colors.red.shade900,
          secondaryColor: Colors.red.shade700,
          glowColor: Colors.yellow.withOpacity(0.9),
          trailColor: Colors.red.withOpacity(0.5),
        );
    }
  }

  Widget _buildBehaviorIndicator(EnemyStyle style) {
    Color indicatorColor;
    IconData indicatorIcon;
    
    switch (_currentBehavior) {
      case EnemyBehaviorState.patrolling:
        indicatorColor = Colors.blue;
        indicatorIcon = Icons.explore;
        break;
      case EnemyBehaviorState.alert:
        indicatorColor = Colors.yellow;
        indicatorIcon = Icons.warning;
        break;
      case EnemyBehaviorState.pursuing:
        indicatorColor = Colors.red;
        indicatorIcon = Icons.gps_fixed;
        break;
      case EnemyBehaviorState.fleeing:
        indicatorColor = Colors.green;
        indicatorIcon = Icons.directions_run;
        break;
    }

    return Positioned(
      top: -5,
      right: -5,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: indicatorColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Icon(
          indicatorIcon,
          size: 10,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStrengthIndicator() {
    final strengthColors = {
      EnemyStrength.weak: Colors.green,
      EnemyStrength.normal: Colors.yellow,
      EnemyStrength.strong: Colors.orange,
      EnemyStrength.elite: Colors.red,
      EnemyStrength.boss: Colors.purple,
    };

    final strengthStars = {
      EnemyStrength.weak: 1,
      EnemyStrength.normal: 2,
      EnemyStrength.strong: 3,
      EnemyStrength.elite: 4,
      EnemyStrength.boss: 5,
    };

    return Positioned(
      bottom: -5,
      left: -5,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: strengthColors[widget.enemy.strength],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            strengthStars[widget.enemy.strength] ?? 1,
            (index) => const Icon(
              Icons.star,
              size: 6,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMovementTrail(EnemyStyle style) {
    if (_currentPosition == null || _targetPosition == null) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      painter: MovementTrailPainter(
        start: _currentPosition!,
        end: _targetPosition!,
        progress: _movementAnimation.value,
        trailColor: style.trailColor,
      ),
    );
  }

  Widget _buildAggressionAura(EnemyStyle style) {
    if (widget.enemy.aggressionLevel == EnemyAggressionLevel.passive) {
      return const SizedBox.shrink();
    }

    final auraSize = widget.size * (1.5 + (widget.enemy.aggressionLevel.index * 0.3));
    final auraOpacity = 0.2 + (widget.enemy.aggressionLevel.index * 0.1);

    return Container(
      width: auraSize,
      height: auraSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: style.glowColor.withOpacity(auraOpacity),
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = _getEnemyStyle();

    return GestureDetector(
      onTap: () {
        if (_currentBehavior == EnemyBehaviorState.pursuing ||
            _currentBehavior == EnemyBehaviorState.alert) {
          widget.onEncounter?.call();
        }
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _movementAnimation,
          _alertAnimation,
          _idleAnimation,
          _combatAnimation,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _idleAnimation.value * _alertAnimation.value,
            child: SizedBox(
              width: widget.size * 2,
              height: widget.size * 2,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Movement trail
                  _buildMovementTrail(style),

                  // Aggression aura
                  _buildAggressionAura(style),

                  // Main enemy body
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          style.secondaryColor,
                          style.primaryColor,
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _currentBehavior == EnemyBehaviorState.pursuing
                            ? Colors.red
                            : style.primaryColor,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: style.glowColor,
                          blurRadius: 8 + (_combatAnimation.value * 8),
                          spreadRadius: 2 + (_combatAnimation.value * 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        style.avatar,
                        style: TextStyle(
                          fontSize: widget.size * 0.5,
                        ),
                      ),
                    ),
                  ),

                  // Behavior indicator
                  _buildBehaviorIndicator(style),

                  // Strength indicator
                  _buildStrengthIndicator(),

                  // Name label
                  Positioned(
                    bottom: -25,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: style.primaryColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Text(
                        widget.enemy.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Combat stance indicator
                  if (_currentBehavior == EnemyBehaviorState.pursuing)
                    Positioned(
                      top: -10,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.6),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.warning,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter for movement trails
class MovementTrailPainter extends CustomPainter {
  final Position start;
  final Position end;
  final double progress;
  final Color trailColor;

  MovementTrailPainter({
    required this.start,
    required this.end,
    required this.progress,
    required this.trailColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = trailColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Create dotted line effect
    final path = Path();
    final segments = 20;
    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      if (t <= progress) {
        final x = size.width * 0.5; // Simplified for demo
        final y = size.height * 0.5 + (t * 20 - 10);
        
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(MovementTrailPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Enemy Group Manager Widget
class EnemyGroupManagerWidget extends StatefulWidget {
  final List<EnemyData> enemies;
  final Position playerPosition;
  final double detectionRange;
  final Function(EnemyData enemy)? onEnemyEncounter;

  const EnemyGroupManagerWidget({
    Key? key,
    required this.enemies,
    required this.playerPosition,
    this.detectionRange = 100.0, // meters
    this.onEnemyEncounter,
  }) : super(key: key);

  @override
  State<EnemyGroupManagerWidget> createState() => _EnemyGroupManagerWidgetState();
}

class _EnemyGroupManagerWidgetState extends State<EnemyGroupManagerWidget> {
  late Timer _detectionTimer;
  final Map<String, bool> _enemyPlayerNearby = {};

  @override
  void initState() {
    super.initState();
    _startDetectionUpdates();
  }

  void _startDetectionUpdates() {
    _detectionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updatePlayerDetection();
    });
  }

  void _updatePlayerDetection() {
    for (final enemy in widget.enemies) {
      final distance = _calculateDistance(widget.playerPosition, enemy.currentPosition);
      final wasNearby = _enemyPlayerNearby[enemy.id] ?? false;
      final isNearby = distance <= widget.detectionRange;
      
      if (wasNearby != isNearby) {
        setState(() {
          _enemyPlayerNearby[enemy.id] = isNearby;
        });
      }
    }
  }

  double _calculateDistance(Position pos1, Position pos2) {
    return Geolocator.distanceBetween(
      pos1.latitude,
      pos1.longitude,
      pos2.latitude,
      pos2.longitude,
    );
  }

  @override
  void dispose() {
    _detectionTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: widget.enemies.map((enemy) {
        return Positioned(
          left: 50.0, // These would be calculated based on map coordinates
          top: 50.0,  // in a real implementation
          child: PatrollingEnemyWidget(
            enemy: enemy,
            isPlayerNearby: _enemyPlayerNearby[enemy.id] ?? false,
            onEncounter: () => widget.onEnemyEncounter?.call(enemy),
          ),
        );
      }).toList(),
    );
  }
}

// Supporting classes and enums
enum EnemyType {
  shadow,
  beast,
  elemental,
  undead,
  construct,
  dragon,
}

enum EnemyBehaviorState {
  patrolling,
  alert,
  pursuing,
  fleeing,
}

enum EnemyAggressionLevel {
  passive,
  neutral,
  aggressive,
  hostile,
}

enum EnemyStrength {
  weak,
  normal,
  strong,
  elite,
  boss,
}

class EnemyStyle {
  final String avatar;
  final Color primaryColor;
  final Color secondaryColor;
  final Color glowColor;
  final Color trailColor;

  const EnemyStyle({
    required this.avatar,
    required this.primaryColor,
    required this.secondaryColor,
    required this.glowColor,
    required this.trailColor,
  });
}

class EnemyData {
  final String id;
  final String name;
  final EnemyType type;
  final EnemyStrength strength;
  final EnemyAggressionLevel aggressionLevel;
  final List<Position> patrolRoute;
  final Position currentPosition;
  final int pauseDuration; // seconds
  final Map<String, dynamic> metadata;

  EnemyData({
    required this.id,
    required this.name,
    required this.type,
    required this.strength,
    required this.aggressionLevel,
    required this.patrolRoute,
    required this.currentPosition,
    this.pauseDuration = 3,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};

  static List<EnemyData> generateEnemiesForArea({
    required Position centerPosition,
    required double radiusMeters,
    int enemyCount = 5,
  }) {
    final random = math.Random();
    final enemies = <EnemyData>[];

    for (int i = 0; i < enemyCount; i++) {
      // Generate random position within radius
      final angle = random.nextDouble() * 2 * math.pi;
      final distance = random.nextDouble() * radiusMeters;
      
      final lat = centerPosition.latitude + (distance * math.cos(angle)) / 111111;
      final lng = centerPosition.longitude + (distance * math.sin(angle)) / (111111 * math.cos(centerPosition.latitude * math.pi / 180));
      
      final enemyPosition = Position(
        longitude: lng,
        latitude: lat,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0, 
        headingAccuracy: 0,
      );

      // Generate patrol route
      final patrolRoute = _generatePatrolRoute(enemyPosition, 50.0); // 50m patrol radius

      enemies.add(EnemyData(
        id: 'enemy_$i',
        name: _generateEnemyName(EnemyType.values[random.nextInt(EnemyType.values.length)]),
        type: EnemyType.values[random.nextInt(EnemyType.values.length)],
        strength: EnemyStrength.values[random.nextInt(EnemyStrength.values.length - 1)], // Exclude boss for now
        aggressionLevel: EnemyAggressionLevel.values[random.nextInt(EnemyAggressionLevel.values.length)],
        patrolRoute: patrolRoute,
        currentPosition: enemyPosition,
        pauseDuration: 2 + random.nextInt(5), // 2-6 seconds
      ));
    }

    return enemies;
  }

  static List<Position> _generatePatrolRoute(Position center, double radius) {
    final random = math.Random();
    final routePoints = <Position>[];
    final numPoints = 3 + random.nextInt(3); // 3-5 patrol points

    for (int i = 0; i < numPoints; i++) {
      final angle = (2 * math.pi * i) / numPoints + (random.nextDouble() - 0.5) * 0.5;
      final distance = radius * (0.5 + random.nextDouble() * 0.5); // 50-100% of radius
      
      final lat = center.latitude + (distance * math.cos(angle)) / 111111;
      final lng = center.longitude + (distance * math.sin(angle)) / (111111 * math.cos(center.latitude * math.pi / 180));
      
      routePoints.add(Position(
        longitude: lng,
        latitude: lat,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0, 
        headingAccuracy: 0,
      ));
    }

    return routePoints;
  }

  static String _generateEnemyName(EnemyType type) {
    final names = {
      EnemyType.shadow: ['Shadowmend', 'Darkwhisper', 'Voidcrawler', 'Gloomstalk'],
      EnemyType.beast: ['Ironmaw', 'Swiftclaw', 'Razorfang', 'Stormhowl'],
      EnemyType.elemental: ['Blazeheart', 'Frostcore', 'Stormcaller', 'Earthshaker'],
      EnemyType.undead: ['Bonechill', 'Soulreaper', 'Gravewarden', 'Lichwhisper'],
      EnemyType.construct: ['Ironguard', 'Gearwork', 'Steamwright', 'Cogbeast'],
      EnemyType.dragon: ['Pyrewing', 'Stormscale', 'Frostmaw', 'Shadowcrest'],
    };
    
    final typeNames = names[type] ?? ['Unknown'];
    final random = math.Random();
    return typeNames[random.nextInt(typeNames.length)];
  }
}