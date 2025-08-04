import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../services/analytics_service.dart';
import '../constants/theme.dart';
import 'dart:math' as math;

class RouteNavigationWidget extends StatefulWidget {
  final String destinationName;
  final double destinationLatitude;
  final double destinationLongitude;
  final double currentLatitude;
  final double currentLongitude;
  final VoidCallback? onRouteComplete;

  const RouteNavigationWidget({
    super.key,
    required this.destinationName,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.currentLatitude,
    required this.currentLongitude,
    this.onRouteComplete,
  });

  @override
  State<RouteNavigationWidget> createState() => _RouteNavigationWidgetState();
}

class _RouteNavigationWidgetState extends State<RouteNavigationWidget> {
  bool _isNavigating = false;
  bool _isPaused = false;
  double _distanceRemaining = 0.0;
  String _nextInstruction = '';
  int _estimatedTimeMinutes = 0;
  List<NavigationStep> _routeSteps = [];
  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeRoute();
  }

  void _initializeRoute() {
    // Calculate initial route
    _calculateRoute();
    _updateDistance();
  }

  void _calculateRoute() {
    // Simulate route calculation
    _routeSteps = [
      NavigationStep(
        instruction: 'Head north on Main Street',
        distance: 0.2,
        duration: 3,
        type: NavigationType.straight,
      ),
      NavigationStep(
        instruction: 'Turn right onto Oak Avenue',
        distance: 0.1,
        duration: 2,
        type: NavigationType.turnRight,
      ),
      NavigationStep(
        instruction: 'Continue for 0.3 km',
        distance: 0.3,
        duration: 4,
        type: NavigationType.straight,
      ),
      NavigationStep(
        instruction: 'Turn left onto Pine Street',
        distance: 0.1,
        duration: 2,
        type: NavigationType.turnLeft,
      ),
      NavigationStep(
        instruction: 'Destination on your right',
        distance: 0.05,
        duration: 1,
        type: NavigationType.destination,
      ),
    ];
    
    _updateCurrentStep();
  }

  void _updateDistance() {
    // Calculate distance using Haversine formula
    final distance = _calculateDistance(
      widget.currentLatitude,
      widget.currentLongitude,
      widget.destinationLatitude,
      widget.destinationLongitude,
    );
    
    setState(() {
      _distanceRemaining = distance;
      _estimatedTimeMinutes = (distance * 20).round(); // 20 min per km walking
    });
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
               math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
               math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  void _updateCurrentStep() {
    if (_currentStepIndex < _routeSteps.length) {
      setState(() {
        _nextInstruction = _routeSteps[_currentStepIndex].instruction;
      });
    }
  }

  void _startNavigation() {
    setState(() {
      _isNavigating = true;
      _isPaused = false;
    });
    
    final audioService = context.read<AudioService>();
    final analyticsService = context.read<AnalyticsService>();
    
    audioService.playQuestComplete();
    
    analyticsService.trackEvent(
      EventType.locationVisited,
      'Navigation Started',
      properties: {
        'destination': widget.destinationName,
        'distance': _distanceRemaining,
        'estimated_time': _estimatedTimeMinutes,
      },
    );
    
    // Start navigation updates
    _startNavigationUpdates();
  }

  void _pauseNavigation() {
    setState(() {
      _isPaused = true;
    });
    
    final audioService = context.read<AudioService>();
    audioService.playButtonClick();
  }

  void _resumeNavigation() {
    setState(() {
      _isPaused = false;
    });
    
    final audioService = context.read<AudioService>();
    audioService.playButtonClick();
    
    _startNavigationUpdates();
  }

  void _stopNavigation() {
    setState(() {
      _isNavigating = false;
      _isPaused = false;
    });
    
    final audioService = context.read<AudioService>();
    audioService.playError();
  }

  void _startNavigationUpdates() {
    if (!_isNavigating || _isPaused) return;
    
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isNavigating && !_isPaused) {
        _updateNavigationProgress();
        _startNavigationUpdates();
      }
    });
  }

  void _updateNavigationProgress() {
    if (_distanceRemaining > 0.1) {
      setState(() {
        _distanceRemaining -= 0.05; // Simulate progress
        _estimatedTimeMinutes = (_distanceRemaining * 20).round();
      });
      
      // Check if we should advance to next step
      if (_currentStepIndex < _routeSteps.length - 1) {
        final currentStep = _routeSteps[_currentStepIndex];
        if (_distanceRemaining < currentStep.distance) {
          _currentStepIndex++;
          _updateCurrentStep();
          
          final audioService = context.read<AudioService>();
          audioService.playQuestComplete();
        }
      }
    } else {
      _completeNavigation();
    }
  }

  void _completeNavigation() {
    setState(() {
      _isNavigating = false;
      _distanceRemaining = 0.0;
      _estimatedTimeMinutes = 0;
    });
    
    final audioService = context.read<AudioService>();
    final analyticsService = context.read<AnalyticsService>();
    
    audioService.playQuestComplete();
    
    analyticsService.trackEvent(
      EventType.locationVisited,
      'Navigation Completed',
      properties: {
        'destination': widget.destinationName,
        'total_distance': _calculateDistance(
          widget.currentLatitude,
          widget.currentLongitude,
          widget.destinationLatitude,
          widget.destinationLongitude,
        ),
      },
    );
    
    widget.onRouteComplete?.call();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Arrived at ${widget.destinationName}!'),
        backgroundColor: RealmOfValorTheme.experienceGreen,
      ),
    );
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
                Icon(
                  _isNavigating ? Icons.navigation : Icons.location_on,
                  color: RealmOfValorTheme.accentGold,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Navigation to ${widget.destinationName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: RealmOfValorTheme.textPrimary,
                        ),
                      ),
                      Text(
                        _isNavigating ? 'Active Navigation' : 'Ready to Start',
                        style: const TextStyle(
                          fontSize: 12,
                          color: RealmOfValorTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Distance and time info
            _buildNavigationInfo(),
            const SizedBox(height: 16),
            
            // Current instruction
            if (_isNavigating && _nextInstruction.isNotEmpty)
              _buildCurrentInstruction(),
            
            const SizedBox(height: 16),
            
            // Navigation controls
            _buildNavigationControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildInfoItem(
              'Distance',
              '${_distanceRemaining.toStringAsFixed(1)} km',
              Icons.straighten,
              RealmOfValorTheme.manaBlue,
            ),
          ),
          Expanded(
            child: _buildInfoItem(
              'Time',
              '${_estimatedTimeMinutes} min',
              Icons.access_time,
              RealmOfValorTheme.experienceGreen,
            ),
          ),
          Expanded(
            child: _buildInfoItem(
              'Steps',
              '${_routeSteps.length}',
              Icons.directions_walk,
              RealmOfValorTheme.accentGold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: RealmOfValorTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentInstruction() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.accentGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RealmOfValorTheme.accentGold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _getNavigationIcon(_routeSteps[_currentStepIndex].type),
            color: RealmOfValorTheme.accentGold,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _nextInstruction,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: RealmOfValorTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Row(
      children: [
        if (!_isNavigating)
          Expanded(
            child: ElevatedButton(
              onPressed: _startNavigation,
              style: ElevatedButton.styleFrom(
                backgroundColor: RealmOfValorTheme.experienceGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Start Navigation'),
            ),
          ),
        if (_isNavigating) ...[
          Expanded(
            child: ElevatedButton(
              onPressed: _isPaused ? _resumeNavigation : _pauseNavigation,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isPaused ? RealmOfValorTheme.experienceGreen : Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text(_isPaused ? 'Resume' : 'Pause'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: _stopNavigation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Stop'),
            ),
          ),
        ],
      ],
    );
  }

  IconData _getNavigationIcon(NavigationType type) {
    switch (type) {
      case NavigationType.straight:
        return Icons.straighten;
      case NavigationType.turnLeft:
        return Icons.turn_left;
      case NavigationType.turnRight:
        return Icons.turn_right;
      case NavigationType.uturn:
        return Icons.u_turn_left;
      case NavigationType.destination:
        return Icons.location_on;
    }
  }
}

enum NavigationType {
  straight,
  turnLeft,
  turnRight,
  uturn,
  destination,
}

class NavigationStep {
  final String instruction;
  final double distance;
  final int duration;
  final NavigationType type;

  NavigationStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.type,
  });
} 