import 'package:flutter/material.dart';
import '../models/battle_model.dart';
import '../models/card_model.dart';

class PlayerPortraitWidget extends StatelessWidget {
  final BattlePlayer player;
  final bool isActive;
  final bool isHovered;
  final ActionCard? draggedCard;
  final String? draggedAction;
  final VoidCallback? onTap;
  final Function(String)? onAttackDropped;
  final Function(ActionCard, String)? onCardDropped;
  final Function(String)? onDragEnter;
  final Function(String)? onDragLeave;

  const PlayerPortraitWidget({
    super.key,
    required this.player,
    required this.isActive,
    this.isHovered = false,
    this.draggedCard,
    this.draggedAction,
    this.onTap,
    this.onAttackDropped,
    this.onCardDropped,
    this.onDragEnter,
    this.onDragLeave,
  });

  bool get isValidDragTarget {
    if (draggedCard != null) {
      return _canTargetWithCard(draggedCard!, player);
    }
    if (draggedAction != null) {
      return draggedAction == 'ATTACK' && !_isAlly(player);
    }
    return false;
  }

  bool _isAlly(BattlePlayer targetPlayer) {
    // For now, assume players with different IDs are enemies
    // In a real game, you'd check team affiliations
    return targetPlayer.id == player.id;
  }

  bool _canTargetWithCard(ActionCard card, BattlePlayer targetPlayer) {
    final cardName = card.name.toLowerCase();
    final isAlly = _isAlly(targetPlayer);
    
    // Check card targeting rules
    if (cardName.contains('heal') || cardName.contains('holy') || cardName.contains('divine')) {
      return isAlly; // Healing spells target allies
    }
    if (cardName.contains('curse') || cardName.contains('shadow') || cardName.contains('dark')) {
      return !isAlly; // Curses target enemies
    }
    if (cardName.contains('buff') || cardName.contains('shield')) {
      return isAlly; // Buffs target allies
    }
    if (cardName.contains('damage') || cardName.contains('fire') || cardName.contains('ice')) {
      return !isAlly; // Damage spells target enemies
    }
    
    // Default: can target anyone
    return true;
  }

  Color _getTargetHighlightColor() {
    if (draggedCard != null) {
      final cardName = draggedCard!.name.toLowerCase();
      final isAlly = _isAlly(player);
      
      if (cardName.contains('heal') || cardName.contains('holy') || cardName.contains('divine')) {
        return isAlly ? Colors.green : Colors.red;
      }
      if (cardName.contains('curse') || cardName.contains('shadow') || cardName.contains('dark')) {
        return !isAlly ? Colors.purple : Colors.red;
      }
      if (cardName.contains('buff') || cardName.contains('shield')) {
        return isAlly ? Colors.blue : Colors.red;
      }
      if (cardName.contains('damage') || cardName.contains('fire') || cardName.contains('ice')) {
        return !isAlly ? Colors.orange : Colors.red;
      }
    }
    
    if (draggedAction == 'ATTACK') {
      return !_isAlly(player) ? Colors.red : Colors.red;
    }
    
    return Colors.yellow; // Default highlight
  }

  @override
  Widget build(BuildContext context) {
    final isDead = player.currentHealth <= 0;
    final isHighlighted = isHovered && isValidDragTarget;
    final highlightColor = _getTargetHighlightColor();
    
    return DragTarget<String>(
      onAccept: (attack) {
        if (attack == 'ATTACK' && onAttackDropped != null) {
          onAttackDropped!(player.id);
        }
      },
      onWillAccept: (attack) => attack == 'ATTACK' && !isDead,
      onMove: (details) {
        if (onDragEnter != null && !isHovered) {
          onDragEnter!(player.id);
        }
      },
      onLeave: (data) {
        if (onDragLeave != null) {
          onDragLeave!(player.id);
        }
      },
      builder: (context, attackCandidates, attackRejected) {
        return DragTarget<ActionCard>(
          onAccept: (card) {
            if (onCardDropped != null) {
              onCardDropped!(card, player.id);
            }
          },
          onWillAccept: (card) => card != null && !isDead && _canTargetWithCard(card, player),
          onMove: (details) {
            if (onDragEnter != null && !isHovered) {
              onDragEnter!(player.id);
            }
          },
          onLeave: (data) {
            if (onDragLeave != null) {
              onDragLeave!(player.id);
            }
          },
          builder: (context, cardCandidates, cardRejected) {
            final hasDragCandidates = cardCandidates.isNotEmpty || attackCandidates.isNotEmpty;
            final shouldHighlight = isHighlighted || hasDragCandidates;
            
            return GestureDetector(
              onTap: onTap, // This will be null when not provided, allowing drag and drop to work
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDead 
                      ? Colors.grey.withOpacity(0.3)
                      : (shouldHighlight
                          ? highlightColor.withOpacity(0.8)
                          : (isActive 
                              ? const Color(0xFFe94560).withOpacity(0.8)
                              : const Color(0xFF16213e))),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDead 
                        ? Colors.grey
                        : (shouldHighlight
                            ? highlightColor
                            : (isActive 
                                ? Colors.white 
                                : const Color(0xFFe94560))),
                    width: shouldHighlight ? 4 : (isActive ? 3 : 2),
                  ),
                  boxShadow: (isActive || shouldHighlight)
                      ? [
                          BoxShadow(
                            color: shouldHighlight 
                                ? highlightColor.withOpacity(0.7)
                                : const Color(0xFFe94560).withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Stack(
                  children: [
                    // Main content
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Player Name
                          Text(
                            player.name,
                            style: TextStyle(
                              color: isDead ? Colors.grey : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Character Portrait/Avatar
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: isDead 
                                  ? Colors.grey.withOpacity(0.5)
                                  : _getClassColor(player.character.characterClass),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isDead ? Colors.grey : Colors.white,
                                width: 2,
                              ),
                              boxShadow: shouldHighlight ? [
                                BoxShadow(
                                  color: highlightColor.withOpacity(0.6),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ] : null,
                            ),
                            child: Icon(
                              _getClassIcon(player.character.characterClass),
                              color: isDead ? Colors.grey : Colors.white,
                              size: 32,
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Character Class
                          Text(
                            player.character.characterClass.name.toUpperCase(),
                            style: TextStyle(
                              color: isDead 
                                  ? Colors.grey 
                                  : Colors.white.withOpacity(0.8),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Health Bar
                          _buildStatBar('HP', player.currentHealth, player.maxHealth, Colors.red, isDead),
                          
                          const SizedBox(height: 4),
                          
                          // Mana Bar
                          _buildStatBar('MP', player.currentMana, player.maxMana, Colors.blue, isDead),
                          
                          const SizedBox(height: 8),
                          
                          // Cards in Hand
                          Text(
                            'Cards: ${player.hand.length}',
                            style: TextStyle(
                              color: isDead ? Colors.grey : Colors.white.withOpacity(0.7),
                              fontSize: 10,
                            ),
                          ),
                          
                          if (isActive) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFe94560),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Invalid target overlay
                    if (isHovered && !isValidDragTarget && !isDead)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.close,
                              color: Colors.red,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    
                    // Valid target indicator
                    if (shouldHighlight && isValidDragTarget)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: highlightColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getTargetIcon(),
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _getTargetIcon() {
    if (draggedCard != null) {
      final cardName = draggedCard!.name.toLowerCase();
      if (cardName.contains('heal') || cardName.contains('holy')) return Icons.healing;
      if (cardName.contains('curse') || cardName.contains('shadow')) return Icons.dark_mode;
      if (cardName.contains('buff') || cardName.contains('shield')) return Icons.shield;
      if (cardName.contains('damage') || cardName.contains('fire')) return Icons.local_fire_department;
    }
    if (draggedAction == 'ATTACK') return Icons.gps_fixed;
    return Icons.check;
  }

  Widget _buildStatBar(String label, int current, int max, Color color, bool isDead) {
    final percentage = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isDead ? Colors.grey : Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$current/$max',
              style: TextStyle(
                color: isDead ? Colors.grey : Colors.white,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: isDead 
                ? Colors.grey.withOpacity(0.3)
                : Colors.grey[800],
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getClassColor(CharacterClass characterClass) {
    switch (characterClass) {
      case CharacterClass.paladin:
        return Colors.yellow;
      case CharacterClass.barbarian:
        return Colors.red;
      case CharacterClass.necromancer:
        return Colors.purple;
      case CharacterClass.sorceress:
        return Colors.blue;
      case CharacterClass.amazon:
        return Colors.green;
      case CharacterClass.assassin:
        return Colors.grey;
      case CharacterClass.druid:
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  IconData _getClassIcon(CharacterClass characterClass) {
    switch (characterClass) {
      case CharacterClass.paladin:
        return Icons.shield;
      case CharacterClass.barbarian:
        return Icons.fitness_center;
      case CharacterClass.necromancer:
        return Icons.psychology;
      case CharacterClass.sorceress:
        return Icons.auto_awesome;
      case CharacterClass.amazon:
        return Icons.architecture;
      case CharacterClass.assassin:
        return Icons.visibility_off;
      case CharacterClass.druid:
        return Icons.nature;
      default:
        return Icons.person;
    }
  }
}