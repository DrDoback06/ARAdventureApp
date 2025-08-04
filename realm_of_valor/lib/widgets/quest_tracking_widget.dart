import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

import '../constants/theme.dart';
import '../services/quest_generator_service.dart';
import '../services/location_service.dart';

class QuestTrackingWidget extends StatefulWidget {
  final AdventureQuest quest;
  final VoidCallback? onStopQuest;
  final VoidCallback? onShowFullDetails;

  const QuestTrackingWidget({
    super.key,
    required this.quest,
    this.onStopQuest,
    this.onShowFullDetails,
  });

  @override
  State<QuestTrackingWidget> createState() => _QuestTrackingWidgetState();
}

class _QuestTrackingWidgetState extends State<QuestTrackingWidget> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  double _distanceToQuest = 0.0;
  int _estimatedTime = 0;
  List<bool> _todoItems = [];
  List<String> _todoList = [];
  late LocationService _locationService;

  @override
  void initState() {
    super.initState();
    _locationService = LocationService.instance;
    _generateTodoList();
    _startTimer();
    _updateDistance();
  }

  void _generateTodoList() {
    // Generate todo items based on quest type
    switch (widget.quest.type) {
      case QuestType.exploration:
        _todoList = [
          'Reach the destination',
          'Explore the area',
          'Find hidden items',
          'Complete exploration',
        ];
        break;
      case QuestType.fitness:
        _todoList = [
          'Reach the location',
          'Complete fitness challenge',
          'Record your activity',
          'Return to start point',
        ];
        break;
      case QuestType.battle:
        _todoList = [
          'Reach the battle location',
          'Defeat the enemies',
          'Collect rewards',
          'Report victory',
        ];
        break;
      case QuestType.collection:
        _todoList = [
          'Reach collection point',
          'Gather required items',
          'Check inventory',
          'Return items',
        ];
        break;
      default:
        _todoList = [
          'Reach the destination',
          'Complete the objective',
          'Return to start',
        ];
    }
    _todoItems = List.generate(_todoList.length, (index) => false);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _updateDistance() {
    Timer.periodic(const Duration(seconds: 2), (timer) async {
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
              _estimatedTime = (distance / 1.4 / 60).round(); // Convert to minutes
            });
          }
        }
      } catch (e) {
        debugPrint('Error updating distance: $e');
      }
    });
  }

  void _checkQuestProgress() {
    // Check if player is within quest radius
    if (_distanceToQuest <= widget.quest.radius / 1000) {
      // Mark first todo as complete
      if (_todoItems.isNotEmpty && !_todoItems[0]) {
        setState(() {
          _todoItems[0] = true;
        });
      }
    }
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleUpdate: (_) {}, // Prevent map zooming when touching this widget
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: RealmOfValorTheme.surfaceDark.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getQuestColor(widget.quest.type).withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                    size: 20,
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Active Quest',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onShowFullDetails,
                  icon: const Icon(Icons.expand_more, color: Colors.grey),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Timer and Distance
            Row(
              children: [
                Expanded(
                  child: _buildStat(
                    Icons.timer,
                    'Time',
                    _formatTime(_elapsedSeconds),
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStat(
                    Icons.directions_walk,
                    'Distance',
                    '${_distanceToQuest.toStringAsFixed(1)} km',
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStat(
                    Icons.access_time,
                    'ETA',
                    '${_estimatedTime} min',
                    Colors.orange,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Todo List
            Text(
              'Objectives',
              style: TextStyle(
                color: RealmOfValorTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(_todoList.length, (index) => _buildTodoItem(index)),
            
            const SizedBox(height: 12),
            
            // Stop Quest Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onStopQuest,
                icon: const Icon(Icons.stop),
                label: const Text('Stop Quest'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: RealmOfValorTheme.textSecondary,
            fontSize: 10,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: RealmOfValorTheme.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTodoItem(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Checkbox(
            value: _todoItems[index],
            onChanged: (value) {
              setState(() {
                _todoItems[index] = value ?? false;
              });
            },
            activeColor: _getQuestColor(widget.quest.type),
            checkColor: Colors.white,
          ),
          Expanded(
            child: Text(
              _todoList[index],
              style: TextStyle(
                color: _todoItems[index] 
                  ? RealmOfValorTheme.textSecondary 
                  : RealmOfValorTheme.textPrimary,
                fontSize: 12,
                decoration: _todoItems[index] 
                  ? TextDecoration.lineThrough 
                  : null,
              ),
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
} 