import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/location_verification_service.dart';
import '../models/adventure_system.dart';
import '../constants/theme.dart';

class QuestProgressOverlay extends StatefulWidget {
  final List<Quest> activeQuests;
  final bool showCompact;

  const QuestProgressOverlay({
    Key? key,
    required this.activeQuests,
    this.showCompact = false,
  }) : super(key: key);

  @override
  _QuestProgressOverlayState createState() => _QuestProgressOverlayState();
}

class _QuestProgressOverlayState extends State<QuestProgressOverlay>
    with TickerProviderStateMixin {
  LocationVerificationService? _verificationService;
  List<LocationProgress> _locationProgress = [];
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _verificationService = Provider.of<LocationVerificationService>(context, listen: false);
    _setupStreams();
    _startTracking();
  }

  void _setupStreams() {
    _verificationService?.progressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _locationProgress = progress;
        });
      }
    });

    _verificationService?.completionStream.listen((completedProgress) {
      if (mounted) {
        _showCompletionDialog(completedProgress);
      }
    });
  }

  void _startTracking() async {
    await _verificationService?.startTracking(widget.activeQuests);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_locationProgress.isEmpty) {
      return const SizedBox.shrink();
    }

    if (widget.showCompact) {
      return _buildCompactView();
    }

    return _buildFullView();
  }

  Widget _buildCompactView() {
    final activeProgress = _locationProgress
        .where((p) => !p.isCompleted && p.proximityStatus != ProximityStatus.far)
        .toList();

    if (activeProgress.isEmpty) return const SizedBox.shrink();

    final closest = activeProgress.reduce((a, b) => 
        a.distanceToTarget < b.distanceToTarget ? a : b);

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getProximityColor(closest.proximityStatus).withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Icon(
                  _getProximityIcon(closest.proximityStatus),
                  color: Colors.white,
                  size: 20,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getShortStatusText(closest),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (closest.requiredTime > 0)
                  _buildTimeProgress(closest),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullView() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceDark.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RealmOfValorTheme.accentGold.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.gps_fixed,
                color: RealmOfValorTheme.accentGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Quest Progress',
                style: TextStyle(
                  color: RealmOfValorTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${_locationProgress.where((p) => p.isCompleted).length}/${_locationProgress.length}',
                style: const TextStyle(
                  color: RealmOfValorTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_locationProgress.take(3).map((progress) => _buildProgressCard(progress))),
          if (_locationProgress.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '... and ${_locationProgress.length - 3} more',
                style: const TextStyle(
                  color: RealmOfValorTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(LocationProgress progress) {
    final quest = widget.activeQuests.firstWhere((q) => q.id == progress.questId);
    final objective = quest.objectives.firstWhere((o) => o.id == progress.objectiveId);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getProximityColor(progress.proximityStatus).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getProximityColor(progress.proximityStatus).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getProximityIcon(progress.proximityStatus),
                color: _getProximityColor(progress.proximityStatus),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  objective.description,
                  style: const TextStyle(
                    color: RealmOfValorTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (progress.isCompleted)
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 16,
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Distance/proximity info
          Text(
            _verificationService?.getStatusMessage(progress) ?? '',
            style: TextStyle(
              color: _getProximityColor(progress.proximityStatus),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Progress bars
          _buildDistanceProgress(progress),
          
          if (progress.requiredTime > 0) ...[
            const SizedBox(height: 4),
            _buildTimeProgress(progress),
          ],
        ],
      ),
    );
  }

  Widget _buildDistanceProgress(LocationProgress progress) {
    final proximityPercentage = _verificationService?.getProximityPercentage(progress) ?? 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Distance',
              style: TextStyle(
                color: RealmOfValorTheme.textSecondary,
                fontSize: 10,
              ),
            ),
            Text(
              progress.distanceToTarget < 1000
                  ? '${progress.distanceToTarget.round()}m'
                  : '${(progress.distanceToTarget / 1000).toStringAsFixed(1)}km',
              style: const TextStyle(
                color: RealmOfValorTheme.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        LinearProgressIndicator(
          value: proximityPercentage,
          backgroundColor: Colors.grey.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(
            _getProximityColor(progress.proximityStatus),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeProgress(LocationProgress progress) {
    if (progress.requiredTime <= 0) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Time at Location',
              style: TextStyle(
                color: RealmOfValorTheme.textSecondary,
                fontSize: 10,
              ),
            ),
            Text(
              '${progress.timeSpentInRange}s / ${progress.requiredTime}s',
              style: const TextStyle(
                color: RealmOfValorTheme.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        LinearProgressIndicator(
          value: progress.completionProgress,
          backgroundColor: Colors.grey.withOpacity(0.3),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      ],
    );
  }

  void _showCompletionDialog(LocationProgress completedProgress) {
    final quest = widget.activeQuests.firstWhere((q) => q.id == completedProgress.questId);
    final objective = quest.objectives.firstWhere((o) => o.id == completedProgress.objectiveId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.celebration, color: RealmOfValorTheme.accentGold),
            const SizedBox(width: 8),
            const Text('Objective Complete!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              objective.description,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('🎉 Great job! You\'ve reached your destination!'),
            const SizedBox(height: 8),
            const Text(
              '+100 XP',
              style: TextStyle(
                color: RealmOfValorTheme.experienceGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }

  Color _getProximityColor(ProximityStatus status) {
    switch (status) {
      case ProximityStatus.atLocation:
        return Colors.green;
      case ProximityStatus.veryClose:
        return Colors.lightGreen;
      case ProximityStatus.close:
        return Colors.orange;
      case ProximityStatus.nearby:
        return Colors.amber;
      case ProximityStatus.far:
        return Colors.grey;
    }
  }

  IconData _getProximityIcon(ProximityStatus status) {
    switch (status) {
      case ProximityStatus.atLocation:
        return Icons.location_on;
      case ProximityStatus.veryClose:
        return Icons.my_location;
      case ProximityStatus.close:
        return Icons.near_me;
      case ProximityStatus.nearby:
        return Icons.navigation;
      case ProximityStatus.far:
        return Icons.explore;
    }
  }

  String _getShortStatusText(LocationProgress progress) {
    switch (progress.proximityStatus) {
      case ProximityStatus.atLocation:
        return progress.requiredTime > 0 ? 'Stay here!' : 'Arrived!';
      case ProximityStatus.veryClose:
        return 'Very close!';
      case ProximityStatus.close:
        return 'Getting close!';
      case ProximityStatus.nearby:
        return 'Head this way!';
      case ProximityStatus.far:
        return 'Navigate to quest';
    }
  }
} 