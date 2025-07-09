import 'package:flutter/material.dart';
import '../models/battle_model.dart';

class BattleCardWidget extends StatelessWidget {
  final ActionCard card;
  final bool canPlay;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onPlay;

  const BattleCardWidget({
    Key? key,
    required this.card,
    required this.canPlay,
    required this.isSelected,
    required this.onTap,
    required this.onPlay,
  }) : super(key: key);

  Color get _typeColor {
    switch (card.type) {
      case ActionCardType.buff:
        return Colors.green;
      case ActionCardType.debuff:
        return Colors.red;
      case ActionCardType.damage:
        return Colors.orange;
      case ActionCardType.heal:
        return Colors.lightBlue;
      case ActionCardType.skip:
        return Colors.grey;
      case ActionCardType.counter:
        return Colors.purple;
      case ActionCardType.special:
        return Colors.yellow;
      case ActionCardType.physical:
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  IconData get _typeIcon {
    switch (card.type) {
      case ActionCardType.buff:
        return Icons.trending_up;
      case ActionCardType.debuff:
        return Icons.trending_down;
      case ActionCardType.damage:
        return Icons.flash_on;
      case ActionCardType.heal:
        return Icons.healing;
      case ActionCardType.skip:
        return Icons.skip_next;
      case ActionCardType.counter:
        return Icons.shield;
      case ActionCardType.special:
        return Icons.star;
      case ActionCardType.physical:
        return Icons.fitness_center;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canPlay ? onTap : null,
      onDoubleTap: canPlay ? onPlay : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: canPlay 
              ? (isSelected 
                  ? const Color(0xFFe94560) 
                  : const Color(0xFF16213e))
              : const Color(0xFF16213e).withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? Colors.white 
                : (canPlay 
                    ? _typeColor 
                    : Colors.grey.withOpacity(0.3)),
            width: isSelected ? 3 : 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Main Card Content
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with cost and type icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Mana Cost
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${card.cost}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      // Type Icon
                      Icon(
                        _typeIcon,
                        color: _typeColor,
                        size: 16,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Card Name
                  Text(
                    card.name,
                    style: TextStyle(
                      color: canPlay ? Colors.white : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Card Description
                  Expanded(
                    child: Text(
                      card.description,
                      style: TextStyle(
                        color: canPlay 
                            ? Colors.white.withOpacity(0.8) 
                            : Colors.grey.withOpacity(0.6),
                        fontSize: 9,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Physical Requirement (if any)
                  if (card.physicalRequirement.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.brown.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Physical: ${card.physicalRequirement}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Disabled Overlay
            if (!canPlay)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(
                    Icons.block,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}