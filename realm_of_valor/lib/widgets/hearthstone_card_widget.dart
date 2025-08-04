import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/battle_model.dart';
import '../models/card_model.dart';
import '../providers/battle_controller.dart';
import '../effects/particle_system.dart';
import '../models/unified_particle_system.dart';
import 'dart:math' as math;

class HearthstoneCardWidget extends StatefulWidget {
  final ActionCard card;
  final BattleController controller;
  final bool canPlay;
  final bool isGhost; // Card is used but not discarded yet
  final VoidCallback? onTap;

  const HearthstoneCardWidget({
    super.key,
    required this.card,
    required this.controller,
    required this.canPlay,
    this.isGhost = false,
    this.onTap,
  });

  @override
  State<HearthstoneCardWidget> createState() => _HearthstoneCardWidgetState();
}

class _HearthstoneCardWidgetState extends State<HearthstoneCardWidget>
    with TickerProviderStateMixin {
  
  late AnimationController _hoverController;
  late AnimationController _liftController;
  late AnimationController _pulseController;
  late Animation<double> _hoverAnimation;
  late Animation<double> _liftAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  
  bool _isHovering = false;
  bool _isDragging = false;
  bool _showParticles = false;
  
  @override
  void initState() {
    super.initState();
    
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _liftController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _hoverAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
    
    _liftAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _liftController, curve: Curves.elasticOut),
    );
    
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.05).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _hoverController.dispose();
    _liftController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHoverStart(),
      onExit: (_) => _onHoverEnd(),
      child: GestureDetector(
        onTap: widget.canPlay ? widget.onTap : null,
        onLongPressStart: widget.canPlay ? _onLongPressStart : null,
        onLongPressMoveUpdate: widget.canPlay ? _onLongPressMoveUpdate : null,
        onLongPressEnd: widget.canPlay ? _onLongPressEnd : null,
        child: AnimatedBuilder(
          animation: Listenable.merge([_hoverAnimation, _liftAnimation, _pulseAnimation]),
          builder: (context, child) {
            final isLifted = widget.controller.draggedCard?.id == widget.card.id;
            final liftProgress = isLifted ? 1.0 : _liftAnimation.value;
            final hoverProgress = _hoverAnimation.value;
            final pulseProgress = _isHovering ? _pulseAnimation.value : 1.0;
            
            return Transform.translate(
              offset: Offset(0, -15 * hoverProgress - 30 * liftProgress),
              child: Transform.scale(
                scale: (1.0 + 0.15 * hoverProgress + 0.25 * liftProgress) * pulseProgress,
                child: Transform.rotate(
                  angle: _rotationAnimation.value * (widget.card.name.hashCode % 2 == 0 ? 1 : -1),
                  child: Stack(
                    children: [
                      // Main card
                      _buildCardContent(hoverProgress, liftProgress),
                      
                      // Particle effects on hover
                      if (_showParticles && _isHovering)
                        _buildHoverParticles(),
                      
                      // Ghost overlay
                      if (widget.isGhost)
                        _buildGhostOverlay(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardContent(double hoverProgress, double liftProgress) {
    final elementColor = _getElementColor(widget.card);
    
    return Container(
      width: 120,
      height: 168,
      constraints: const BoxConstraints(
        maxWidth: 120,
        maxHeight: 168,
        minWidth: 80,
        minHeight: 112,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            elementColor.withOpacity(0.9),
            elementColor.withOpacity(0.7),
            elementColor.withOpacity(0.9),
          ],
        ),
        border: Border.all(
          color: widget.canPlay 
              ? elementColor.withOpacity(0.8 + 0.2 * hoverProgress)
              : Colors.grey.withOpacity(0.5),
          width: 2 + hoverProgress * 2,
        ),
        boxShadow: [
          BoxShadow(
            color: elementColor.withOpacity(0.3 + 0.4 * (hoverProgress + liftProgress)),
            blurRadius: 8 + 12 * (hoverProgress + liftProgress),
            spreadRadius: 2 + 4 * (hoverProgress + liftProgress),
            offset: Offset(0, 4 + 8 * liftProgress),
          ),
          // Rarity glow
          BoxShadow(
            color: _getRarityColor(widget.card.rarity).withOpacity(0.6),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Background pattern
            _buildBackgroundPattern(elementColor),
            
            // Card content with proper overflow handling
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card name with overflow protection
                    Flexible(
                      child: Text(
                        widget.card.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Cost with proper constraints
                    Container(
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        maxWidth: 40,
                      ),
                      child: Text(
                        '${widget.card.cost}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Description with overflow protection
                    Flexible(
                      child: Text(
                        widget.card.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 8,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoverParticles() {
    return Positioned.fill(
      child: ParticleSystem(
        type: _getParticleType(widget.card),
        center: const Offset(60, 84),
        continuous: true,
        intensity: 0.8,
        child: Container(),
      ),
    );
  }
  
  Widget _buildBackgroundPattern(Color elementColor) {
    return CustomPaint(
      size: const Size(120, 168),
      painter: ElementPatternPainter(elementColor: elementColor),
    );
  }
  
  Widget _buildGhostOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withOpacity(0.3),
        ),
        child: const Center(
          child: Icon(
            Icons.hourglass_empty,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
  
  void _onHoverStart() {
    setState(() {
      _isHovering = true;
      _showParticles = true;
    });
    _hoverController.forward();
    _pulseController.repeat(reverse: true);
  }
  
  void _onHoverEnd() {
    setState(() {
      _isHovering = false;
      _showParticles = false;
    });
    if (!_isDragging) {
      _hoverController.reverse();
      _pulseController.stop();
    }
  }

  void _onLongPressStart(LongPressStartDetails details) {
    if (!widget.canPlay) return;
    
    setState(() {
      _isDragging = true;
    });
    
    widget.controller.startCardDrag(widget.card, details.globalPosition);
    _liftController.forward();
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!widget.canPlay || !_isDragging) return;
    
    widget.controller.updateDragPosition(details.globalPosition);
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (!widget.canPlay || !_isDragging) return;
    
    setState(() {
      _isDragging = false;
    });
    
    widget.controller.endDrag();
    _liftController.reverse();
  }
  
  Color _getElementColor(ActionCard card) {
    final name = card.name.toLowerCase();
    if (name.contains('fire') || name.contains('burn') || name.contains('flame')) return Colors.red;
    if (name.contains('ice') || name.contains('frost') || name.contains('cold')) return Colors.cyan;
    if (name.contains('lightning') || name.contains('shock') || name.contains('thunder')) return Colors.yellow;
    if (name.contains('shadow') || name.contains('curse') || name.contains('dark')) return Colors.purple;
    if (name.contains('heal') || name.contains('holy') || name.contains('divine')) return Colors.green;
    if (name.contains('arcane') || name.contains('dispel') || name.contains('magic')) return Colors.blue;
    if (name.contains('nature') || name.contains('earth')) return Colors.brown;
    return Colors.grey;
  }
  
  IconData _getElementIcon(ActionCard card) {
    final name = card.name.toLowerCase();
    if (name.contains('fire') || name.contains('burn') || name.contains('flame')) return Icons.local_fire_department;
    if (name.contains('ice') || name.contains('frost') || name.contains('cold')) return Icons.ac_unit;
    if (name.contains('lightning') || name.contains('shock') || name.contains('thunder')) return Icons.flash_on;
    if (name.contains('shadow') || name.contains('curse') || name.contains('dark')) return Icons.dark_mode;
    if (name.contains('heal') || name.contains('holy') || name.contains('divine')) return Icons.healing;
    if (name.contains('arcane') || name.contains('dispel') || name.contains('magic')) return Icons.auto_awesome;
    if (name.contains('nature') || name.contains('earth')) return Icons.nature;
    return Icons.circle;
  }

  ParticleType _getParticleType(ActionCard card) {
    final name = card.name.toLowerCase();
    if (name.contains('fire') || name.contains('burn') || name.contains('flame')) return ParticleType.fire;
    if (name.contains('ice') || name.contains('frost') || name.contains('cold')) return ParticleType.ice;
    if (name.contains('lightning') || name.contains('shock') || name.contains('thunder')) return ParticleType.lightning;
    if (name.contains('shadow') || name.contains('curse') || name.contains('dark')) return ParticleType.shadow;
    if (name.contains('heal') || name.contains('holy') || name.contains('divine')) return ParticleType.heal;
    if (name.contains('arcane') || name.contains('dispel') || name.contains('magic')) return ParticleType.arcane;
    if (name.contains('nature') || name.contains('earth')) return ParticleType.earth;
    return ParticleType.sparkle;
  }

  Color _getCardTypeColor(ActionCardType type) {
    switch (type) {
      case ActionCardType.damage:
        return Colors.red;
      case ActionCardType.heal:
        return Colors.green;
      case ActionCardType.buff:
        return Colors.blue;
      case ActionCardType.debuff:
        return Colors.purple;
      case ActionCardType.physical:
        return Colors.orange;
      case ActionCardType.spell:
        return Colors.indigo;
      case ActionCardType.counter:
        return Colors.cyan;
      case ActionCardType.support:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
  
  Color _getRarityColor(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.common: return Colors.white;
      case CardRarity.uncommon: return Colors.green;
      case CardRarity.rare: return Colors.blue;
      case CardRarity.epic: return Colors.purple;
      case CardRarity.legendary: return Colors.orange;
      case CardRarity.mythic: return Colors.red;
      case CardRarity.holographic: return Colors.cyan;
      case CardRarity.firstEdition: return Colors.yellow;
      case CardRarity.limitedEdition: return Colors.pink;
      default: return Colors.grey;
    }
  }
}

class ElementPatternPainter extends CustomPainter {
  final Color elementColor;
  
  ElementPatternPainter({required this.elementColor});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = elementColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // Draw subtle pattern
    for (int i = 0; i < 5; i++) {
      final y = size.height * (i + 1) / 6;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
    
    for (int i = 0; i < 3; i++) {
      final x = size.width * (i + 1) / 4;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 