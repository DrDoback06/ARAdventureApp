import 'package:flutter/material.dart';
import '../models/battle_model.dart';
import '../providers/battle_controller.dart';
import 'dart:math' as math;

class SpellCounterOverlayWidget extends StatefulWidget {
  final BattleController controller;

  const SpellCounterOverlayWidget({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  State<SpellCounterOverlayWidget> createState() => _SpellCounterOverlayWidgetState();
}

class _SpellCounterOverlayWidgetState extends State<SpellCounterOverlayWidget>
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _shakeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2.0 * math.pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );
    
    _shakeAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticInOut),
    );
    
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _shakeController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        // Only show if there's a pending spell
        if (widget.controller.pendingSpell == null || 
            widget.controller.spellCounterTimeRemaining <= 0) {
          return const SizedBox.shrink();
        }
        
        return _buildCounterOverlay();
      },
    );
  }
  
  Widget _buildCounterOverlay() {
    final spell = widget.controller.pendingSpell!;
    final timeRemaining = widget.controller.spellCounterTimeRemaining;
    final progress = timeRemaining / 8.0; // 8 seconds total
    
    // Trigger shake animation when time is running low
    if (timeRemaining <= 3 && timeRemaining > 0) {
      _shakeController.repeat(reverse: true);
    } else {
      _shakeController.reset();
    }
    
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulseAnimation, _rotationAnimation, _shakeAnimation]),
          builder: (context, child) {
            return Transform.translate(
              offset: timeRemaining <= 3 ? Offset(_shakeAnimation.value, 0) : Offset.zero,
              child: Container(
                width: 500,
                height: 400,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Top section: Spell info and progress
                    Expanded(
                      flex: 2,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background glow
                          _buildBackgroundGlow(progress),
                          
                          // Circular progress indicator
                          _buildCircularProgress(progress),
                          
                          // Spell information
                          _buildSpellInfo(spell, timeRemaining),
                        ],
                      ),
                    ),
                    
                    // Bottom section: Counter actions (separated to prevent overlap)
                    Expanded(
                      flex: 1,
                      child: _buildCounterActions(),
                    ),
                    
                    // Urgency effects
                    if (timeRemaining <= 3)
                      _buildUrgencyEffects(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildBackgroundGlow(double progress) {
    final glowColor = _getSpellColor(widget.controller.pendingSpell!);
    
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            glowColor.withOpacity(0.1),
            glowColor.withOpacity(0.3 * progress),
            glowColor.withOpacity(0.1),
            Colors.transparent,
          ],
          stops: const [0.0, 0.4, 0.7, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.5 * progress),
            blurRadius: 50.0 * progress,
            spreadRadius: 20.0 * progress,
          ),
        ],
      ),
    );
  }
  
  Widget _buildCircularProgress(double progress) {
    final spell = widget.controller.pendingSpell!;
    final spellColor = _getSpellColor(spell);
    final timeRemaining = widget.controller.spellCounterTimeRemaining;
    
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        children: [
          // Background circle
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: spellColor.withOpacity(0.3),
                width: 8,
              ),
            ),
          ),
          
          // Progress circle
          Transform.rotate(
            angle: -math.pi / 2, // Start from top
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                timeRemaining <= 3 ? Colors.red : spellColor,
              ),
            ),
          ),
          
          // Rotating spell symbols
          Transform.rotate(
            angle: _rotationAnimation.value,
            child: _buildSpellSymbols(spellColor),
          ),
          
          // Center countdown
          Center(
            child: Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: timeRemaining <= 3 ? Colors.red : spellColor,
                  boxShadow: [
                    BoxShadow(
                      color: (timeRemaining <= 3 ? Colors.red : spellColor).withOpacity(0.6),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$timeRemaining',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.8),
                          offset: const Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSpellSymbols(Color spellColor) {
    final spell = widget.controller.pendingSpell!;
    final symbolIcon = _getSpellIcon(spell);
    
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        children: List.generate(6, (index) {
          final angle = (index * 2 * math.pi / 6);
          final radius = 90.0;
          
          return Positioned(
            left: 100 + radius * math.cos(angle) - 15,
            top: 100 + radius * math.sin(angle) - 15,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: spellColor.withOpacity(0.8),
                boxShadow: [
                  BoxShadow(
                    color: spellColor.withOpacity(0.6),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                symbolIcon,
                color: Colors.white,
                size: 16,
              ),
            ),
          );
        }),
      ),
    );
  }
  
  Widget _buildSpellInfo(ActionCard spell, int timeRemaining) {
    final caster = widget.controller.getPlayerById(widget.controller.pendingSpellCaster ?? '');
    final target = widget.controller.getPlayerById(widget.controller.pendingSpellTarget ?? '');
    
    return Positioned(
      top: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _getSpellColor(spell), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${caster?.name ?? "Unknown"} casts',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              spell.name,
              style: TextStyle(
                color: _getSpellColor(spell),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'on ${target?.name ?? "Unknown"}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              spell.description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCounterActions() {
    final currentPlayer = widget.controller.getCurrentPlayer();
    if (currentPlayer == null) return const SizedBox.shrink();
    
    // Find counter cards in hand
    final counterCards = currentPlayer.hand.where((card) =>
      card.type == ActionCardType.counter ||
      card.name.toLowerCase().contains('counter') ||
      card.name.toLowerCase().contains('dispel') ||
      card.name.toLowerCase().contains('block')
    ).toList();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Counter Options:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          if (counterCards.isEmpty)
            const Text(
              'No counter cards available',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: counterCards.map((card) => _buildCounterButton(card)).toList(),
            ),
          
          const SizedBox(height: 12),
          
          // Generic skip option
          ElevatedButton(
            onPressed: () => _skipCounter(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Let Spell Resolve'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCounterButton(ActionCard card) {
    final canAfford = (widget.controller.getCurrentPlayer()?.currentMana ?? 0) >= card.cost;
    
    return ElevatedButton(
      onPressed: canAfford ? () => _useCounterCard(card) : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: canAfford ? Colors.blue : Colors.grey,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            card.name,
            style: const TextStyle(fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${card.cost} mana',
            style: const TextStyle(fontSize: 8),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUrgencyEffects() {
    return Positioned.fill(
      child: CustomPaint(
        painter: UrgencyEffectsPainter(
          pulseProgress: _pulseAnimation.value,
          rotationProgress: _rotationAnimation.value,
        ),
      ),
    );
  }
  
  void _useCounterCard(ActionCard card) {
    // Use the counter card to block the spell
    widget.controller.attemptSpellCounter(card);
  }
  
  void _skipCounter() {
    // Stop the countdown and let the spell resolve immediately
    widget.controller.skipSpellCounter();
  }
  
  Color _getSpellColor(ActionCard spell) {
    final name = spell.name.toLowerCase();
    if (name.contains('fire') || name.contains('burn')) return Colors.red;
    if (name.contains('ice') || name.contains('frost')) return Colors.cyan;
    if (name.contains('lightning') || name.contains('shock')) return Colors.yellow;
    if (name.contains('shadow') || name.contains('curse')) return Colors.purple;
    if (name.contains('heal') || name.contains('holy')) return Colors.green;
    if (name.contains('arcane') || name.contains('dispel')) return Colors.blue;
    return Colors.white;
  }
  
  IconData _getSpellIcon(ActionCard spell) {
    final name = spell.name.toLowerCase();
    if (name.contains('fire') || name.contains('burn')) return Icons.local_fire_department;
    if (name.contains('ice') || name.contains('frost')) return Icons.ac_unit;
    if (name.contains('lightning') || name.contains('shock')) return Icons.flash_on;
    if (name.contains('shadow') || name.contains('curse')) return Icons.dark_mode;
    if (name.contains('heal') || name.contains('holy')) return Icons.healing;
    if (name.contains('arcane') || name.contains('dispel')) return Icons.auto_awesome;
    return Icons.circle;
  }
}

class UrgencyEffectsPainter extends CustomPainter {
  final double pulseProgress;
  final double rotationProgress;
  
  UrgencyEffectsPainter({
    required this.pulseProgress,
    required this.rotationProgress,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.3 * pulseProgress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    // Draw warning pulses
    for (int i = 1; i <= 3; i++) {
      final radius = (50.0 * i) * pulseProgress;
      canvas.drawCircle(center, radius, paint);
    }
    
    // Draw rotating warning lines
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) + (rotationProgress * 2 * math.pi);
      final start = center + Offset(
        math.cos(angle) * 120,
        math.sin(angle) * 120,
      );
      final end = center + Offset(
        math.cos(angle) * 140,
        math.sin(angle) * 140,
      );
      
      canvas.drawLine(start, end, paint);
    }
  }
  
  @override
  bool shouldRepaint(UrgencyEffectsPainter oldDelegate) {
    return oldDelegate.pulseProgress != pulseProgress ||
           oldDelegate.rotationProgress != rotationProgress;
  }
} 