import 'package:flutter/material.dart';
import '../models/spell_counter_system.dart';
import '../models/battle_model.dart';
import 'battle_card_widget.dart';

class SpellCounterWidget extends StatefulWidget {
  final SpellCounterSystem spellCounterSystem;
  final Function(ActionCard) onCounterSelected;
  final VoidCallback onSkipCounter;

  const SpellCounterWidget({
    super.key,
    required this.spellCounterSystem,
    required this.onCounterSelected,
    required this.onSkipCounter,
  });

  @override
  State<SpellCounterWidget> createState() => _SpellCounterWidgetState();
}

class _SpellCounterWidgetState extends State<SpellCounterWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;
  int _remainingSeconds = 8;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _shakeAnimation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
    _startCountdown();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });
        if (_remainingSeconds <= 3) {
          _shakeController.repeat(reverse: true);
        }
        return _remainingSeconds > 0;
      }
      return false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pendingSpell = widget.spellCounterSystem.currentPendingSpell;
    
    if (pendingSpell == null) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1a1a2e),
                Color(0xFF16213e),
                Color(0xFF0f3460),
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
              // Header
              const Text(
                'SPELL INTERRUPT!',
                style: TextStyle(
                  color: Colors.yellow,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Enemy is casting ${pendingSpell.spell.name}!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 20),
              
              // Countdown
              Text(
                '$_remainingSeconds seconds remaining',
                style: TextStyle(
                  color: _remainingSeconds <= 3 ? Colors.red : Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Counter spells
              const Text(
                'Available Counter Spells:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Placeholder for counter spells
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'No counter spells available',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: widget.onSkipCounter,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Skip Counter'),
                  ),
                  if (widget.spellCounterSystem.hasActiveInterrupt)
                    ElevatedButton(
                      onPressed: () => widget.spellCounterSystem.forceResolve(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFe94560),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Force Resolve'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}