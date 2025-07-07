import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class EncounterDialog extends StatefulWidget {
  final String title;
  final String description;
  final List<String> rewards;
  final VoidCallback onClaim;

  const EncounterDialog({
    Key? key,
    required this.title,
    required this.description,
    required this.rewards,
    required this.onClaim,
  }) : super(key: key);

  @override
  State<EncounterDialog> createState() => _EncounterDialogState();
}

class _EncounterDialogState extends State<EncounterDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 350, maxHeight: 500),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: _getEncounterGradient(),
            boxShadow: [
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return BoxShadow(
                    color: _getEncounterColor().withOpacity(_glowAnimation.value * 0.6),
                    blurRadius: 30,
                    spreadRadius: 10,
                  );
                },
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  color: Colors.black.withOpacity(0.3),
                ),
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _getEncounterColor().withOpacity(_glowAnimation.value * 0.3),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _getEncounterColor().withOpacity(_glowAnimation.value),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            _getEncounterIcon(),
                            color: Colors.white,
                            size: 48,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            offset: Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Description
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          widget.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Rewards section
                      if (widget.rewards.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.card_giftcard,
                                    color: Colors.amber,
                                    size: 24,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Rewards',
                                    style: TextStyle(
                                      color: Colors.amber,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...AnimationConfiguration.toStaggeredList(
                                duration: const Duration(milliseconds: 375),
                                childAnimationBuilder: (widget) => SlideAnimation(
                                  horizontalOffset: 50.0,
                                  child: FadeInAnimation(child: widget),
                                ),
                                children: widget.rewards.map((reward) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.amber.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _getRewardIcon(reward),
                                          color: Colors.amber,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          reward,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      const Spacer(),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[600],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text(
                                'Ignore',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: AnimatedBuilder(
                              animation: _glowAnimation,
                              builder: (context, child) {
                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _getEncounterColor().withOpacity(_glowAnimation.value * 0.5),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: widget.onClaim,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _getEncounterColor(),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      elevation: 4,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(_getActionIcon(), size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          _getActionText(),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  LinearGradient _getEncounterGradient() {
    final color = _getEncounterColor();
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color.withOpacity(0.8),
        color.withOpacity(0.6),
        Colors.black.withOpacity(0.7),
      ],
    );
  }

  Color _getEncounterColor() {
    if (widget.title.toLowerCase().contains('treasure')) {
      return Colors.amber[600]!;
    } else if (widget.title.toLowerCase().contains('battle') || 
               widget.title.toLowerCase().contains('creature')) {
      return Colors.red[600]!;
    } else if (widget.title.toLowerCase().contains('merchant')) {
      return Colors.purple[600]!;
    } else if (widget.title.toLowerCase().contains('discovered')) {
      return Colors.blue[600]!;
    } else {
      return Colors.teal[600]!;
    }
  }

  IconData _getEncounterIcon() {
    if (widget.title.toLowerCase().contains('treasure')) {
      return Icons.diamond;
    } else if (widget.title.toLowerCase().contains('battle') || 
               widget.title.toLowerCase().contains('creature')) {
      return Icons.psychology;
    } else if (widget.title.toLowerCase().contains('merchant')) {
      return Icons.store;
    } else if (widget.title.toLowerCase().contains('discovered')) {
      return Icons.explore;
    } else {
      return Icons.auto_awesome;
    }
  }

  IconData _getRewardIcon(String reward) {
    final lowerReward = reward.toLowerCase();
    
    if (lowerReward.contains('xp') || lowerReward.contains('experience')) {
      return Icons.star;
    } else if (lowerReward.contains('gold') || lowerReward.contains('coin')) {
      return Icons.monetization_on;
    } else if (lowerReward.contains('card')) {
      return Icons.style;
    } else if (lowerReward.contains('gem')) {
      return Icons.diamond;
    } else if (lowerReward.contains('badge') || lowerReward.contains('achievement')) {
      return Icons.military_tech;
    } else if (lowerReward.contains('item') || lowerReward.contains('gear')) {
      return Icons.inventory;
    } else {
      return Icons.card_giftcard;
    }
  }

  String _getActionText() {
    if (widget.title.toLowerCase().contains('treasure')) {
      return 'Claim Treasure';
    } else if (widget.title.toLowerCase().contains('battle') || 
               widget.title.toLowerCase().contains('creature')) {
      return 'Enter Battle';
    } else if (widget.title.toLowerCase().contains('merchant')) {
      return 'Trade';
    } else if (widget.title.toLowerCase().contains('discovered')) {
      return 'Explore';
    } else {
      return 'Investigate';
    }
  }

  IconData _getActionIcon() {
    if (widget.title.toLowerCase().contains('treasure')) {
      return Icons.download;
    } else if (widget.title.toLowerCase().contains('battle') || 
               widget.title.toLowerCase().contains('creature')) {
      return Icons.flash_on;
    } else if (widget.title.toLowerCase().contains('merchant')) {
      return Icons.handshake;
    } else if (widget.title.toLowerCase().contains('discovered')) {
      return Icons.search;
    } else {
      return Icons.touch_app;
    }
  }
}