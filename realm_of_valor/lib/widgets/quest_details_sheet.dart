import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

import '../constants/theme.dart';
import '../services/quest_generator_service.dart';
import '../services/location_service.dart';
import '../services/navigation_service.dart';

class QuestDetailsSheet extends StatefulWidget {
  final AdventureQuest quest;
  final VoidCallback? onStartQuest;
  final VoidCallback? onStopQuest;
  final VoidCallback? onShowPath;
  final bool isActive;

  const QuestDetailsSheet({
    super.key,
    required this.quest,
    this.onStartQuest,
    this.onStopQuest,
    this.onShowPath,
    this.isActive = false,
  });

  @override
  State<QuestDetailsSheet> createState() => _QuestDetailsSheetState();
}

class _QuestDetailsSheetState extends State<QuestDetailsSheet> {
  bool _isNavigating = false;
  double _distanceToQuest = 0.0;
  int _estimatedSteps = 0;
  int _estimatedTime = 0;
  List<String> _encounters = [];
  bool _isRouteOptimized = false;
  late LocationService _locationService;

  @override
  void initState() {
    super.initState();
    _locationService = LocationService.instance;
    _calculateRouteInfo();
    _generateEncounters();
    _startDistanceUpdates();
  }

  Future<void> _calculateRouteInfo() async {
    try {
      final currentLocation = await _locationService.getCurrentLocation();
      
      if (currentLocation != null) {
        final distance = Geolocator.distanceBetween(
          currentLocation.latitude,
          currentLocation.longitude,
          widget.quest.location.latitude,
          widget.quest.location.longitude,
        );
        
        if (mounted) {
          setState(() {
            _distanceToQuest = distance / 1000; // Convert to kilometers
            _estimatedSteps = (distance * 1200).round(); // Average steps per meter
            _estimatedTime = (distance / 1.4 / 60).round(); // Convert to minutes
          });
        }
      }
    } catch (e) {
      debugPrint('Error calculating route: $e');
    }
  }

  // Update distance periodically
  void _startDistanceUpdates() {
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _calculateRouteInfo();
      } else {
        timer.cancel();
      }
    });
  }

  void _generateEncounters() {
    final encounters = <String>[];
    final random = DateTime.now().millisecondsSinceEpoch;
    
    // Generate random encounters based on quest type and distance
    if (widget.quest.type == QuestType.exploration) {
      encounters.addAll([
        'Wild Pokémon encounter',
        'Hidden treasure chest',
        'Mysterious NPC',
        'Ancient ruins',
        'Secret passage',
      ]);
    } else if (widget.quest.type == QuestType.fitness) {
      encounters.addAll([
        'Fitness challenge',
        'Endurance test',
        'Strength training spot',
        'Agility course',
        'Meditation point',
      ]);
    } else if (widget.quest.type == QuestType.battle) {
      encounters.addAll([
        'Rival trainer',
        'Wild monster',
        'Boss encounter',
        'Arena challenge',
        'Legendary creature',
      ]);
    }
    
    // Shuffle and take 2-3 encounters
    encounters.shuffle();
    setState(() {
      _encounters = encounters.take(2 + (random % 2)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleUpdate: (_) {}, // Prevent map zooming when touching this widget
      child: Container(
        width: MediaQuery.of(context).size.width * 0.4, // 40% width on right side
        height: MediaQuery.of(context).size.height * 0.8,
        margin: const EdgeInsets.only(right: 16, top: 16, bottom: 16),
        decoration: BoxDecoration(
          color: RealmOfValorTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getQuestColor(widget.quest.type).withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _getQuestColor(widget.quest.type).withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getQuestColor(widget.quest.type).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getQuestColor(widget.quest.type).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getQuestIcon(widget.quest.type),
                      color: _getQuestColor(widget.quest.type),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.quest.title,
                          style: TextStyle(
                            color: RealmOfValorTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(widget.quest.difficulty).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.quest.difficulty.name.toUpperCase(),
                            style: TextStyle(
                              color: _getDifficultyColor(widget.quest.difficulty),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    Text(
                      widget.quest.description,
                      style: TextStyle(
                        color: RealmOfValorTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Location Information
                    _buildLocationInfo(),
                    const SizedBox(height: 16),
                    
                    // Route Information
                    _buildRouteInfo(),
                    const SizedBox(height: 16),
                    
                    // Quest Information
                    _buildQuestInfo(),
                    const SizedBox(height: 16),
                    
                    // Encounters on Route
                    _buildEncounters(),
                    const SizedBox(height: 16),
                    
                    // Rewards
                    _buildRewards(),
                    const SizedBox(height: 16),
                    
                    // Action Buttons
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getQuestColor(widget.quest.type).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
                              child: Icon(
                  _getQuestIcon(widget.quest.type),
                  color: _getQuestColor(widget.quest.type),
                  size: 24,
                ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.quest.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: RealmOfValorTheme.textPrimary,
                    ),
                  ),
                  Text(
                    widget.quest.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: RealmOfValorTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getDifficultyColor(widget.quest.difficulty).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.quest.difficulty.name.toUpperCase(),
            style: TextStyle(
              color: _getDifficultyColor(widget.quest.difficulty),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRouteInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RealmOfValorTheme.accentGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildRouteStat(
                  Icons.directions_walk,
                  'Distance',
                  '${_distanceToQuest.toStringAsFixed(1)} km',
                ),
              ),
              Expanded(
                child: _buildRouteStat(
                  Icons.timer,
                  'Time',
                  '${_estimatedTime} min',
                ),
              ),
              Expanded(
                child: _buildRouteStat(
                  Icons.fitness_center,
                  'Steps',
                  '$_estimatedSteps',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.route,
                color: RealmOfValorTheme.accentGold,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _isRouteOptimized ? 'Optimized Route' : 'Standard Route',
                style: TextStyle(
                  color: RealmOfValorTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteStat(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: RealmOfValorTheme.accentGold, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: RealmOfValorTheme.textSecondary,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: RealmOfValorTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quest Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: RealmOfValorTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        _buildInfoRow('Type', widget.quest.type.name.toUpperCase()),
        _buildInfoRow('Radius', '${widget.quest.radius.toStringAsFixed(0)}m'),
        if (widget.quest.expirationTime != null)
          _buildInfoRow('Expires', _formatDateTime(widget.quest.expirationTime!)),
        _buildInfoRow('Status', widget.isActive ? 'ACTIVE' : 'AVAILABLE'),
      ],
    );
  }

  Widget _buildEncounters() {
    if (_encounters.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Encounters on Route',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: RealmOfValorTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ..._encounters.map((encounter) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: RealmOfValorTheme.surfaceDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: RealmOfValorTheme.accentGold.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.sports_martial_arts,
                color: RealmOfValorTheme.accentGold,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  encounter,
                  style: TextStyle(
                    color: RealmOfValorTheme.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildRewards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rewards',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: RealmOfValorTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (widget.quest.rewards.isNotEmpty) ...[
          ...widget.quest.rewards.map((reward) => _buildRewardItem(
            _getRewardIcon(reward.type.toString()),
            '${reward.amount} ${reward.description}',
            _getRewardColor(reward.type.toString()),
          )),
        ] else ...[
          // Fallback to direct properties if no rewards list
          _buildRewardItem(Icons.star, '${widget.quest.rewardXP} XP', Colors.amber),
          const SizedBox(width: 16),
          _buildRewardItem(Icons.monetization_on, '${widget.quest.rewardGold} Gold', Colors.yellow),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (widget.onShowPath != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isNavigating = !_isNavigating;
                });
                widget.onShowPath?.call();
              },
              icon: Icon(_isNavigating ? Icons.stop : Icons.directions),
              label: Text(_isNavigating ? 'Stop Navigation' : 'Start Navigation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isNavigating ? Colors.red : RealmOfValorTheme.accentGold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (widget.onStartQuest != null && !widget.isActive)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.onStartQuest,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Quest'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RealmOfValorTheme.accentGold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            if (widget.onStopQuest != null && widget.isActive) ...[
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onStopQuest,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop Quest'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardItem(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getQuestColor(QuestType type) {
    switch (type) {
      case QuestType.exploration:
        return Colors.blue;
      case QuestType.social:
        return Colors.green;
      case QuestType.fitness:
        return Colors.orange;
      case QuestType.collection:
        return Colors.purple;
      case QuestType.battle:
        return Colors.red;
      case QuestType.walking:
        return Colors.cyan;
      case QuestType.running:
        return Colors.blue;
      case QuestType.climbing:
        return Colors.brown;
      case QuestType.location:
        return Colors.yellow;
      case QuestType.time:
        return Colors.indigo;
      case QuestType.weather:
        return Colors.lightBlue;
    }
  }

  IconData _getQuestIcon(QuestType type) {
    switch (type) {
      case QuestType.exploration:
        return Icons.explore;
      case QuestType.social:
        return Icons.people;
      case QuestType.fitness:
        return Icons.fitness_center;
      case QuestType.collection:
        return Icons.collections;
      case QuestType.battle:
        return Icons.sports_martial_arts;
      case QuestType.walking:
        return Icons.directions_walk;
      case QuestType.running:
        return Icons.directions_run;
      case QuestType.climbing:
        return Icons.terrain;
      case QuestType.location:
        return Icons.location_on;
      case QuestType.time:
        return Icons.access_time;
      case QuestType.weather:
        return Icons.cloud;
    }
  }

  Color _getDifficultyColor(QuestDifficulty difficulty) {
    switch (difficulty) {
      case QuestDifficulty.easy:
        return Colors.green;
      case QuestDifficulty.medium:
        return Colors.orange;
      case QuestDifficulty.hard:
        return Colors.red;
      case QuestDifficulty.epic:
        return Colors.purple;
    }
  }

  IconData _getRewardIcon(String type) {
    switch (type.toLowerCase()) {
      case 'item':
        return Icons.inventory;
      case 'skill':
        return Icons.psychology;
      case 'currency':
        return Icons.monetization_on;
      default:
        return Icons.star;
    }
  }

  Color _getRewardColor(String type) {
    switch (type.toLowerCase()) {
      case 'item':
        return Colors.blue;
      case 'skill':
        return Colors.purple;
      case 'currency':
        return Colors.yellow;
      default:
        return Colors.amber;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildLocationInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: _getQuestColor(widget.quest.type)),
              const SizedBox(width: 8),
              Text(
                'Destination',
                style: TextStyle(
                  color: RealmOfValorTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FutureBuilder<String>(
            future: _locationService.getAddressFromCoordinates(
              widget.quest.location.latitude,
              widget.quest.location.longitude,
            ),
            builder: (context, snapshot) {
              return Text(
                snapshot.data ?? 'Loading address...',
                style: TextStyle(
                  color: RealmOfValorTheme.textSecondary,
                  fontSize: 14,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
} 