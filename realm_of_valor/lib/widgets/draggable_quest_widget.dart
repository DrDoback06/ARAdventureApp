import 'package:flutter/material.dart';
import '../constants/theme.dart';

class QuestData {
  final String id;
  final String title;
  final String description;
  final int experience;
  final int gold;
  final String status; // 'active', 'completed', 'failed'
  final DateTime? deadline;
  final String? location;

  QuestData({
    required this.id,
    required this.title,
    required this.description,
    required this.experience,
    required this.gold,
    required this.status,
    this.deadline,
    this.location,
  });
}

class DraggableQuestWidget extends StatefulWidget {
  final QuestData quest;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onAbandon;
  final Function(Offset position)? onPositionChanged;

  const DraggableQuestWidget({
    super.key,
    required this.quest,
    this.onTap,
    this.onComplete,
    this.onAbandon,
    this.onPositionChanged,
  });

  @override
  State<DraggableQuestWidget> createState() => _DraggableQuestWidgetState();
}

class _DraggableQuestWidgetState extends State<DraggableQuestWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;
  
  Offset _position = const Offset(20, 100);
  bool _isDragging = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _shadowAnimation = Tween<double>(
      begin: 4.0,
      end: 12.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
    _animationController.forward();
    print('DEBUG: Quest widget drag started: ${widget.quest.title}');
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _position += details.delta;
    });
    widget.onPositionChanged?.call(_position);
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
    _animationController.reverse();
    print('DEBUG: Quest widget drag ended: ${widget.quest.title}');
  }

  void _onTap() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    widget.onTap?.call();
    print('DEBUG: Quest widget tapped: ${widget.quest.title}');
  }

  Color _getStatusColor() {
    switch (widget.quest.status.toLowerCase()) {
      case 'active':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.quest.status.toLowerCase()) {
      case 'active':
        return Icons.play_arrow;
      case 'completed':
        return Icons.check_circle;
      case 'failed':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: _isExpanded ? 280 : 200,
              decoration: BoxDecoration(
                color: RealmOfValorTheme.surfaceMedium,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getStatusColor(),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: _shadowAnimation.value,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Row(
                          children: [
                            Icon(
                              _getStatusIcon(),
                              color: _getStatusColor(),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.quest.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: RealmOfValorTheme.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _showQuestMenu(),
                              child: Icon(
                                Icons.more_vert,
                                color: RealmOfValorTheme.textSecondary,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                        
                        if (_isExpanded) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.quest.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: RealmOfValorTheme.textSecondary,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          
                          // Rewards
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: RealmOfValorTheme.accentGold,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.quest.experience} XP',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: RealmOfValorTheme.accentGold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.monetization_on,
                                color: RealmOfValorTheme.accentGold,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.quest.gold} Gold',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: RealmOfValorTheme.accentGold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          
                          if (widget.quest.deadline != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  color: RealmOfValorTheme.textSecondary,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Deadline: ${_formatDeadline(widget.quest.deadline!)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: RealmOfValorTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          
                          if (widget.quest.location != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: RealmOfValorTheme.textSecondary,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.quest.location!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: RealmOfValorTheme.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                          
                          const SizedBox(height: 8),
                          
                          // Action buttons
                          if (widget.quest.status == 'active') ...[
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      print('DEBUG: Quest complete button pressed: ${widget.quest.title}');
                                      widget.onComplete?.call();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      textStyle: const TextStyle(fontSize: 12),
                                    ),
                                    child: const Text('Complete'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      print('DEBUG: Quest abandon button pressed: ${widget.quest.title}');
                                      widget.onAbandon?.call();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      textStyle: const TextStyle(fontSize: 12),
                                    ),
                                    child: const Text('Abandon'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      return '${difference.inMinutes}m';
    }
  }

  void _showQuestMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: RealmOfValorTheme.surfaceMedium,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: RealmOfValorTheme.textSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.info, color: RealmOfValorTheme.accentGold),
              title: const Text('Quest Details'),
              onTap: () {
                Navigator.pop(context);
                _onTap();
              },
            ),
            if (widget.quest.status == 'active') ...[
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Mark Complete'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onComplete?.call();
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Abandon Quest'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onAbandon?.call();
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Remove Widget'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement widget removal
                print('DEBUG: Remove quest widget: ${widget.quest.title}');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class DraggableQuestManager {
  static final DraggableQuestManager _instance = DraggableQuestManager._internal();
  factory DraggableQuestManager() => _instance;
  DraggableQuestManager._internal();

  final List<DraggableQuestWidget> _questWidgets = [];
  final List<VoidCallback> _updateCallbacks = [];

  void addQuestWidget(DraggableQuestWidget widget) {
    _questWidgets.add(widget);
    _notifyListeners();
    print('DEBUG: Added quest widget: ${widget.quest.title}');
  }

  void removeQuestWidget(String questId) {
    _questWidgets.removeWhere((widget) => widget.quest.id == questId);
    _notifyListeners();
    print('DEBUG: Removed quest widget: $questId');
  }

  void addUpdateCallback(VoidCallback callback) {
    _updateCallbacks.add(callback);
  }

  void removeUpdateCallback(VoidCallback callback) {
    _updateCallbacks.remove(callback);
  }

  void _notifyListeners() {
    _updateCallbacks.forEach((callback) => callback());
  }

  List<DraggableQuestWidget> get questWidgets => List.unmodifiable(_questWidgets);
} 