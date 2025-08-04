import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../constants/theme.dart';
import 'dart:async';

class SpellCastTimerWidget extends StatefulWidget {
  final String spellName;
  final Duration castTime;
  final VoidCallback? onCastComplete;
  final VoidCallback? onCastCancelled;

  const SpellCastTimerWidget({
    super.key,
    required this.spellName,
    required this.castTime,
    this.onCastComplete,
    this.onCastCancelled,
  });

  @override
  State<SpellCastTimerWidget> createState() => _SpellCastTimerWidgetState();
}

class _SpellCastTimerWidgetState extends State<SpellCastTimerWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  late Timer _timer;
  
  bool _isCasting = false;
  bool _isPaused = false;
  Duration _remainingTime = Duration.zero;
  double _progress = 0.0;
  int _castProgress = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _remainingTime = widget.castTime;
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: widget.castTime,
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void _startCasting() {
    if (_isCasting) return;
    
    setState(() {
      _isCasting = true;
      _isPaused = false;
      _progress = 0.0;
      _castProgress = 0;
    });
    
    final audioService = context.read<AudioService>();
    audioService.playSpellCast();
    
    _animationController.forward();
    _startTimer();
  }

  void _pauseCasting() {
    if (!_isCasting || _isPaused) return;
    
    setState(() {
      _isPaused = true;
    });
    
    _animationController.stop();
    _timer.cancel();
    
    final audioService = context.read<AudioService>();
    audioService.playError();
  }

  void _resumeCasting() {
    if (!_isCasting || !_isPaused) return;
    
    setState(() {
      _isPaused = false;
    });
    
    _animationController.forward();
    _startTimer();
    
    final audioService = context.read<AudioService>();
    audioService.playSpellCast();
  }

  void _cancelCasting() {
    if (!_isCasting) return;
    
    _animationController.stop();
    _timer.cancel();
    
    setState(() {
      _isCasting = false;
      _isPaused = false;
      _progress = 0.0;
      _castProgress = 0;
    });
    
    final audioService = context.read<AudioService>();
    audioService.playError();
    
    widget.onCastCancelled?.call();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isCasting || _isPaused) {
        timer.cancel();
        return;
      }
      
      final progress = _animationController.value;
      final remaining = widget.castTime * (1 - progress);
      
      setState(() {
        _progress = progress;
        _remainingTime = remaining;
        _castProgress = (progress * 100).round();
      });
      
      // Play progress sounds
      if (_castProgress % 25 == 0 && _castProgress > 0 && _castProgress < 100) {
        final audioService = context.read<AudioService>();
        audioService.playSpellResolve();
      }
      
      if (progress >= 1.0) {
        _completeCasting();
        timer.cancel();
      }
    });
  }

  void _completeCasting() {
    setState(() {
      _isCasting = false;
      _isPaused = false;
      _progress = 1.0;
      _castProgress = 100;
      _remainingTime = Duration.zero;
    });
    
    final audioService = context.read<AudioService>();
    audioService.playSpellResolve();
    
    widget.onCastComplete?.call();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isCasting ? _pulseAnimation.value : 1.0,
                      child: Icon(
                        _isCasting ? Icons.auto_fix_high : Icons.psychology,
                        color: RealmOfValorTheme.manaBlue,
                        size: 24,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.spellName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: RealmOfValorTheme.textPrimary,
                        ),
                      ),
                      Text(
                        _getStatusText(),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Progress bar
            _buildProgressBar(),
            const SizedBox(height: 12),
            
            // Time remaining
            _buildTimeRemaining(),
            const SizedBox(height: 16),
            
            // Cast controls
            _buildCastControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cast Progress',
              style: const TextStyle(
                fontSize: 12,
                color: RealmOfValorTheme.textSecondary,
              ),
            ),
            Text(
              '$_castProgress%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: RealmOfValorTheme.manaBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: _progress,
          backgroundColor: RealmOfValorTheme.surfaceLight,
          valueColor: AlwaysStoppedAnimation<Color>(
            _getProgressColor(),
          ),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildTimeRemaining() {
    final minutes = _remainingTime.inMinutes;
    final seconds = _remainingTime.inSeconds % 60;
    final timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            color: RealmOfValorTheme.manaBlue,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Time Remaining: $timeString',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCastControls() {
    if (!_isCasting) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _startCasting,
          style: ElevatedButton.styleFrom(
            backgroundColor: RealmOfValorTheme.manaBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text('Start Casting'),
        ),
      );
    }
    
    return Row(
      children: [
        if (_isPaused)
          Expanded(
            child: ElevatedButton(
              onPressed: _resumeCasting,
              style: ElevatedButton.styleFrom(
                backgroundColor: RealmOfValorTheme.experienceGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Resume'),
            ),
          )
        else
          Expanded(
            child: ElevatedButton(
              onPressed: _pauseCasting,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Pause'),
            ),
          ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: _cancelCasting,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }

  String _getStatusText() {
    if (!_isCasting) return 'Ready to cast';
    if (_isPaused) return 'Casting paused';
    return 'Casting in progress...';
  }

  Color _getStatusColor() {
    if (!_isCasting) return RealmOfValorTheme.textSecondary;
    if (_isPaused) return Colors.orange;
    return RealmOfValorTheme.manaBlue;
  }

  Color _getProgressColor() {
    if (_progress < 0.3) return Colors.red;
    if (_progress < 0.7) return Colors.orange;
    return RealmOfValorTheme.manaBlue;
  }
} 