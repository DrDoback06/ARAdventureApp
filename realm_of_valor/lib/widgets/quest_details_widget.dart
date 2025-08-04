import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../constants/theme.dart';
import '../models/adventure_map_model.dart';
import '../models/quest_model.dart';

class QuestDetailsWidget extends StatefulWidget {
  final AdventureQuest quest;
  final Function(AdventureQuest) onStartQuest;
  final Function(AdventureQuest) onStopQuest;
  final Function(AdventureQuest) onShowPath;
  final bool isActive;

  const QuestDetailsWidget({
    super.key,
    required this.quest,
    required this.onStartQuest,
    required this.onStopQuest,
    required this.onShowPath,
    this.isActive = false,
  });

  @override
  State<QuestDetailsWidget> createState() => _QuestDetailsWidgetState();
}

class _QuestDetailsWidgetState extends State<QuestDetailsWidget>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          height: _isExpanded ? MediaQuery.of(context).size.height * 0.8 : 350,
          decoration: BoxDecoration(
            color: RealmOfValorTheme.surfaceMedium,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar with glow effect
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: RealmOfValorTheme.accentGold,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: RealmOfValorTheme.accentGold.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              
              // Header with quest info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.quest.name,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: RealmOfValorTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildDifficultyChip(widget.quest.difficulty),
                              const SizedBox(width: 8),
                              _buildTypeChip(widget.quest.type),
                              const SizedBox(width: 8),
                              _buildStatusChip(),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() => _isExpanded = !_isExpanded);
                      },
                      icon: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: RealmOfValorTheme.accentGold,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quest description with enhanced styling
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              RealmOfValorTheme.surfaceDark.withOpacity(0.3),
                              RealmOfValorTheme.surfaceDark.withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: RealmOfValorTheme.accentGold.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          widget.quest.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: RealmOfValorTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Quest details
                      _buildQuestDetails(),
                      const SizedBox(height: 16),
                      
                      // Objectives
                      _buildObjectives(),
                      const SizedBox(height: 16),
                      
                      // Rewards
                      _buildRewards(),
                      const SizedBox(height: 16),
                      
                      // Location info
                      _buildLocationInfo(),
                    ],
                  ),
                ),
              ),
              
              // Action buttons with enhanced styling
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      RealmOfValorTheme.surfaceDark.withOpacity(0.1),
                      RealmOfValorTheme.surfaceDark.withOpacity(0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          widget.onShowPath(widget.quest);
                        },
                        icon: const Icon(Icons.directions, size: 20),
                        label: const Text('Show Path'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RealmOfValorTheme.surfaceDark,
                          foregroundColor: RealmOfValorTheme.accentGold,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          if (widget.isActive) {
                            widget.onStopQuest(widget.quest);
                          } else {
                            widget.onStartQuest(widget.quest);
                          }
                        },
                        icon: Icon(
                          widget.isActive ? Icons.stop : Icons.play_arrow,
                          size: 20,
                        ),
                        label: Text(
                          widget.isActive ? 'Stop Quest' : 'Start Quest',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.isActive 
                              ? Colors.red.shade600
                              : RealmOfValorTheme.accentGold,
                          foregroundColor: widget.isActive 
                              ? Colors.white
                              : RealmOfValorTheme.surfaceDark,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: widget.isActive ? 4 : 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(QuestDifficulty difficulty) {
    Color color;
    String text;
    
    switch (difficulty) {
      case QuestDifficulty.easy:
        color = Colors.green;
        text = 'Easy';
        break;
      case QuestDifficulty.medium:
        color = Colors.orange;
        text = 'Medium';
        break;
      case QuestDifficulty.hard:
        color = Colors.red;
        text = 'Hard';
        break;
      case QuestDifficulty.expert:
        color = Colors.purple;
        text = 'Expert';
        break;
      case QuestDifficulty.legendary:
        color = Colors.amber;
        text = 'Legendary';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTypeChip(QuestType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.accentGold.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RealmOfValorTheme.accentGold),
      ),
      child: Text(
        type.name.toUpperCase(),
        style: TextStyle(
          color: RealmOfValorTheme.accentGold,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.isActive 
            ? Colors.green.withOpacity(0.2)
            : Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isActive ? Colors.green : Colors.orange,
        ),
      ),
      child: Text(
        widget.isActive ? 'ACTIVE' : 'AVAILABLE',
        style: TextStyle(
          color: widget.isActive ? Colors.green : Colors.orange,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildQuestDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quest Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: RealmOfValorTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: RealmOfValorTheme.surfaceDark.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildDetailRow('Type', widget.quest.type.name.toUpperCase()),
              _buildDetailRow('Difficulty', widget.quest.difficulty.name.toUpperCase()),
              _buildDetailRow('XP Reward', '${widget.quest.experienceReward}'),
              _buildDetailRow('Gold Reward', '${widget.quest.goldReward}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildObjectives() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Objectives',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: RealmOfValorTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...widget.quest.objectives.map((objective) => _buildObjectiveTile(objective)),
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: RealmOfValorTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...widget.quest.rewards.map((reward) => _buildRewardTile(reward)),
      ],
    );
  }

  Widget _buildObjectiveTile(QuestObjective objective) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: objective.isCompleted 
              ? Colors.green 
              : RealmOfValorTheme.accentGold.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            objective.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: objective.isCompleted 
                ? Colors.green 
                : RealmOfValorTheme.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              objective.description,
              style: TextStyle(
                color: RealmOfValorTheme.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            '${objective.currentValue}/${objective.targetValue}',
            style: TextStyle(
              color: RealmOfValorTheme.accentGold,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardTile(QuestReward reward) {
    IconData icon;
    switch (reward.type) {
      case 'experience':
        icon = Icons.star;
        break;
      case 'gold':
        icon = Icons.monetization_on;
        break;
      case 'item':
        icon = Icons.inventory;
        break;
      default:
        icon = Icons.card_giftcard;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RealmOfValorTheme.accentGold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: RealmOfValorTheme.accentGold,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              reward.name,
              style: TextStyle(
                color: RealmOfValorTheme.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            '${reward.value}',
            style: TextStyle(
              color: RealmOfValorTheme.accentGold,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherInfo() {
    final bonuses = widget.quest.weatherBonuses;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RealmOfValorTheme.accentGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bonuses['description'] ?? 'Weather effects active',
            style: TextStyle(
              color: RealmOfValorTheme.textPrimary,
              fontSize: 14,
            ),
          ),
          if (bonuses['xpMultiplier'] != null) ...[
            const SizedBox(height: 8),
            Text(
              'XP Multiplier: ${bonuses['xpMultiplier']}x',
              style: TextStyle(
                color: RealmOfValorTheme.accentGold,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationInfo() {
    final location = widget.quest.mapLocation;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RealmOfValorTheme.accentGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            location.name,
            style: TextStyle(
              color: RealmOfValorTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            location.description,
            style: TextStyle(
              color: RealmOfValorTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            location.address,
            style: TextStyle(
              color: RealmOfValorTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          if (location.rating != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: RealmOfValorTheme.accentGold,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${location.rating}/5',
                  style: TextStyle(
                    color: RealmOfValorTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeadlineInfo() {
    final deadline = widget.quest.deadline!;
    final now = DateTime.now();
    final timeLeft = deadline.difference(now);
    
    String timeText;
    Color color;
    
    if (timeLeft.isNegative) {
      timeText = 'Expired';
      color = Colors.red;
    } else if (timeLeft.inDays > 0) {
      timeText = '${timeLeft.inDays} days left';
      color = Colors.green;
    } else if (timeLeft.inHours > 0) {
      timeText = '${timeLeft.inHours} hours left';
      color = Colors.orange;
    } else {
      timeText = '${timeLeft.inMinutes} minutes left';
      color = Colors.red;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            timeText,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: RealmOfValorTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
} 