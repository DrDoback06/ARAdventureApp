import 'package:flutter/material.dart';
import 'package:realm_of_valor/models/spell_counter_system.dart';
import 'package:realm_of_valor/models/battle_model.dart';
import 'package:realm_of_valor/widgets/battle_card_widget.dart';
import 'package:realm_of_valor/effects/particle_system.dart';
import 'dart:async';

class SpellCounterWidget extends StatefulWidget {
  final SpellCounterSystem spellCounterSystem;
  final List<ActionCard> availableCounters;
  final Function(ActionCard) onCounterSelected;
  final VoidCallback onSkipCounter;

  const SpellCounterWidget({
    Key? key,
    required this.spellCounterSystem,
    required this.availableCounters,
    required this.onCounterSelected,
    required this.onSkipCounter,
  }) : super(key: key);

  @override
  State<SpellCounterWidget> createState() => _SpellCounterWidgetState();
}

class _SpellCounterWidgetState extends State<SpellCounterWidget>
    with TickerProviderStateMixin {
  Timer? _countdownTimer;
  int _remainingSeconds = 8;
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _shakeAnimation = Tween<double>(
      begin: -5.0,
      end: 5.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
    
    _startCountdown();
    _pulseController.repeat(reverse: true);
  }

  void _startCountdown() {
    final pendingSpell = widget.spellCounterSystem.currentPendingSpell;
    if (pendingSpell == null) return;
    
    _remainingSeconds = (pendingSpell.remainingMs / 1000).ceil();
    
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        final remaining = widget.spellCounterSystem.currentPendingSpell?.remainingMs ?? 0;
        final newSeconds = (remaining / 1000).ceil();
        
        if (newSeconds != _remainingSeconds) {
          setState(() {
            _remainingSeconds = newSeconds;
          });
          
          // Shake animation when time is running low
          if (_remainingSeconds <= 3 && _remainingSeconds > 0) {
            _shakeController.forward().then((_) {
              _shakeController.reverse();
            });
          }
        }
        
        if (remaining <= 0) {
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingSpell = widget.spellCounterSystem.currentPendingSpell;
    if (pendingSpell == null || pendingSpell.isExpired) {
      return const SizedBox();
    }

    return Stack(
      children: [
        // Background overlay
        Container(
          color: Colors.black.withOpacity(0.8),
        ),
        
        // Epic lightning particle effects during countdown! ⚡
        ParticleSystem(
          type: ParticleType.lightning,
          center: Offset(MediaQuery.of(context).size.width * 0.5, MediaQuery.of(context).size.height * 0.3),
          continuous: true,
          intensity: _remainingSeconds <= 3 ? 2.0 : 1.2,
          child: Container(),
        ),
        
        // Additional particle effects based on spell type
        if (pendingSpell != null) _buildSpellTypeParticles(pendingSpell),
        
        // Main content
        Center(
          child: AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_shakeAnimation.value, 0),
                child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF1a1a2e),
                      const Color(0xFF16213e),
                      Color.lerp(const Color(0xFF0f3460), Colors.red, 
                               _remainingSeconds <= 3 ? 0.3 : 0.0)!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _remainingSeconds <= 3 ? Colors.red : const Color(0xFFe94560),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_remainingSeconds <= 3 ? Colors.red : const Color(0xFFe94560))
                          .withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with spell being cast
                    _buildSpellHeader(pendingSpell),
                    
                    const SizedBox(height: 20),
                    
                    // Countdown Timer
                    _buildCountdownTimer(),
                    
                    const SizedBox(height: 20),
                    
                    // Available Counter Spells
                    _buildCounterSpells(),
                    
                    const SizedBox(height: 20),
                    
                    // Action Buttons
                    _buildActionButtons(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSpellHeader(PendingSpell pendingSpell) {
    return Column(
      children: [
        // Lightning bolt effect
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: const Icon(
                Icons.flash_on,
                color: Colors.yellow,
                size: 48,
              ),
            );
          },
        ),
        
        const SizedBox(height: 12),
        
        const Text(
          'SPELL INTERRUPT!',
          style: TextStyle(
            color: Colors.yellow,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        
        const SizedBox(height: 8),
        
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            children: [
              const TextSpan(text: 'Enemy is casting '),
              TextSpan(
                text: pendingSpell.spell.name,
                style: const TextStyle(
                  color: Color(0xFFe94560),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(text: '!\nCounter now or it will resolve!'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownTimer() {
    final percentage = _remainingSeconds / 8.0;
    final isUrgent = _remainingSeconds <= 3;
    
    return Column(
      children: [
        // Circular countdown indicator
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            children: [
              // Background circle
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.3),
                    width: 4,
                  ),
                ),
              ),
              
              // Progress circle
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return CircularProgressIndicator(
                    value: percentage,
                    strokeWidth: 8,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isUrgent ? Colors.red : const Color(0xFFe94560),
                    ),
                  );
                },
              ),
              
              // Countdown number
              Center(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: isUrgent ? _pulseAnimation.value : 1.0,
                      child: Text(
                        '$_remainingSeconds',
                        style: TextStyle(
                          color: isUrgent ? Colors.red : Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        Text(
          isUrgent ? 'HURRY!' : 'seconds to counter',
          style: TextStyle(
            color: isUrgent ? Colors.red : Colors.white.withOpacity(0.8),
            fontSize: 14,
            fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildCounterSpells() {
    if (widget.availableCounters.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange),
        ),
        child: const Column(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 32),
            SizedBox(height: 8),
            Text(
              'No Counter Spells Available',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'You don\'t have any cards that can counter this spell.',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        const Text(
          'Available Counter Spells',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 12),
        
        Container(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.availableCounters.length,
            itemBuilder: (context, index) {
              final counter = widget.availableCounters[index];
              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => widget.onCounterSelected(counter),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: BattleCardWidget(
                      card: counter,
                      canPlay: true,
                      isSelected: false,
                      onTap: () => widget.onCounterSelected(counter),
                      onPlay: () => widget.onCounterSelected(counter),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Tap a counter spell to cast it!',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Skip Counter Button
        ElevatedButton.icon(
          onPressed: widget.onSkipCounter,
          icon: const Icon(Icons.skip_next),
          label: const Text('Skip'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        
        // Force Resolve Button (for testing)
        if (widget.spellCounterSystem.hasActiveInterrupt)
          ElevatedButton.icon(
            onPressed: () => widget.spellCounterSystem.forceResolve(),
            icon: const Icon(Icons.fast_forward),
            label: const Text('Resolve Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFe94560),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
      ],
    );
  }

  /// Build spell-specific particle effects for extra visual flair! ✨⚡🔥
  Widget _buildSpellTypeParticles(PendingSpell pendingSpell) {
    final spellName = pendingSpell.spell.name.toLowerCase();
    ParticleType particleType;
    
    if (spellName.contains('fire') || spellName.contains('flame')) {
      particleType = ParticleType.fire;
    } else if (spellName.contains('ice') || spellName.contains('frost')) {
      particleType = ParticleType.ice;
    } else if (spellName.contains('lightning') || spellName.contains('shock')) {
      particleType = ParticleType.lightning;
    } else if (spellName.contains('earth') || spellName.contains('stone')) {
      particleType = ParticleType.earth;
    } else if (spellName.contains('water') || spellName.contains('wave')) {
      particleType = ParticleType.water;
    } else if (spellName.contains('light') || spellName.contains('divine')) {
      particleType = ParticleType.light;
    } else if (spellName.contains('shadow') || spellName.contains('dark')) {
      particleType = ParticleType.shadow;
    } else {
      particleType = ParticleType.arcane; // Default magical effect
    }
    
    return ParticleSystem(
      type: particleType,
      center: Offset(MediaQuery.of(context).size.width * 0.7, MediaQuery.of(context).size.height * 0.6),
      continuous: true,
      intensity: 1.5,
      child: Container(),
    );
  }
}