import 'package:flutter/material.dart';
import '../models/battle_model.dart';
import '../models/character_model.dart';
import 'status_effect_overlay.dart';
import 'target_highlight_widget.dart';
import '../effects/particle_system.dart';
import 'dart:math' as math;

class PlayerPortraitWidget extends StatelessWidget {
  final BattlePlayer player;
  final bool isActive;
  final bool isOpponent;
  final VoidCallback? onTap;
  final Function(ActionCard, String)? onCardDropped;
  final Function(String)? onAttackDropped;
  
  // Drag Arrow Enhancement Properties
  final bool isValidDragTarget;
  final bool isHovered;
  final ActionCard? draggedCard;
  final String? draggedAction;
  final Function(String)? onDragEnter;
  final Function(String)? onDragLeave;

  const PlayerPortraitWidget({
    Key? key,
    required this.player,
    required this.isActive,
    required this.isOpponent,
    this.onTap,
    this.onCardDropped,
    this.onAttackDropped,
    this.isValidDragTarget = false,
    this.isHovered = false,
    this.draggedCard,
    this.draggedAction,
    this.onDragEnter,
    this.onDragLeave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDead = player.currentHealth <= 0;
    final statusEffects = _generateStatusEffectsFromPlayer();
    
    return TargetHighlightWidget(
      isValidTarget: isValidDragTarget,
      isHovered: isHovered,
      draggedCard: draggedCard,
      draggedAction: draggedAction,
      playerId: player.id,
      child: StatusEffectOverlay(
        statusEffects: statusEffects,
        size: 120.0,
        child: DragTarget<String>(
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
              onWillAccept: (card) => card != null && !isDead,
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
                final isHighlighted = cardCandidates.isNotEmpty || attackCandidates.isNotEmpty || isHovered;
        
        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
            color: isDead 
                ? Colors.grey.withOpacity(0.3)
                : (isHighlighted
                    ? Colors.yellow.withOpacity(0.8)
                    : (isActive 
                        ? const Color(0xFFe94560).withOpacity(0.8)
                        : const Color(0xFF16213e))),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDead 
                  ? Colors.grey
                  : (isHighlighted
                      ? Colors.yellow
                      : (isActive 
                          ? Colors.white 
                          : const Color(0xFFe94560))),
              width: isHighlighted ? 4 : (isActive ? 3 : 2),
            ),
            boxShadow: (isActive || isHighlighted)
                ? [
                    BoxShadow(
                      color: isHighlighted 
                          ? Colors.yellow.withOpacity(0.7)
                          : const Color(0xFFe94560).withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
        child: Stack(
          children: [
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
                  _buildStatBar(
                    'HP',
                    player.currentHealth,
                    player.maxHealth,
                    isDead ? Colors.grey : Colors.red,
                    isDead,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Mana Bar
                  _buildStatBar(
                    'MP',
                    player.currentMana,
                    player.maxMana,
                    isDead ? Colors.grey : Colors.blue,
                    isDead,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Combat Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatDisplay(
                        'ATK',
                        player.character.attack,
                        Icons.sports_martial_arts,
                        isDead ? Colors.grey : Colors.orange,
                        isDead,
                      ),
                      _buildStatDisplay(
                        'DEF',
                        player.character.defense,
                        Icons.shield,
                        isDead ? Colors.grey : Colors.green,
                        isDead,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Status Effects (if any)
                  if (player.statusEffects.isNotEmpty && !isDead)
                    _buildStatusEffects(),
                  
                  // Hand Size
                  if (!isOpponent || isDead)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDead 
                            ? Colors.grey.withOpacity(0.5)
                            : const Color(0xFF0f3460),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Cards: ${player.hand.length}',
                        style: TextStyle(
                          color: isDead ? Colors.grey : Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Turn Indicator
            if (isActive && !isDead)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.yellow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.black,
                    size: 16,
                  ),
                ),
              ),
            
            // Death Overlay
            if (isDead)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.close,
                          color: Colors.red,
                          size: 32,
                        ),
                        Text(
                          'DEFEATED',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
            },
          );
        },
      ),
    );
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

  Widget _buildStatDisplay(String label, int value, IconData icon, Color color, bool isDead) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 16,
        ),
        const SizedBox(height: 2),
        Text(
          '$value',
          style: TextStyle(
            color: isDead ? Colors.grey : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isDead ? Colors.grey : Colors.white.withOpacity(0.7),
            fontSize: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusEffects() {
    return Wrap(
      spacing: 2,
      children: player.statusEffects.keys.take(3).map((effect) {
        return Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: _getStatusEffectColor(effect),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            _getStatusEffectIcon(effect),
            size: 12,
            color: Colors.white,
          ),
        );
      }).toList(),
    );
  }

  Color _getClassColor(CharacterClass characterClass) {
    switch (characterClass) {
      case CharacterClass.paladin:
        return Colors.yellow.withOpacity(0.7);
      case CharacterClass.barbarian:
        return Colors.red.withOpacity(0.7);
      case CharacterClass.necromancer:
        return Colors.purple.withOpacity(0.7);
      case CharacterClass.sorceress:
        return Colors.blue.withOpacity(0.7);
      case CharacterClass.amazon:
        return Colors.green.withOpacity(0.7);
      case CharacterClass.assassin:
        return Colors.grey.withOpacity(0.7);
      case CharacterClass.druid:
        return Colors.brown.withOpacity(0.7);
      default:
        return Colors.grey.withOpacity(0.7);
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
        return Icons.auto_fix_high;
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

  Color _getStatusEffectColor(String effect) {
    switch (effect.toLowerCase()) {
      case 'poison':
        return Colors.green;
      case 'burn':
        return Colors.orange;
      case 'freeze':
        return Colors.lightBlue;
      case 'shield':
        return Colors.blue;
      case 'blessing':
        return Colors.yellow;
      case 'curse':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusEffectIcon(String effect) {
    switch (effect.toLowerCase()) {
      case 'poison':
        return Icons.science;
      case 'burn':
        return Icons.local_fire_department;
      case 'freeze':
        return Icons.ac_unit;
      case 'shield':
        return Icons.shield;
      case 'blessing':
        return Icons.star;
      case 'curse':
        return Icons.dangerous;
      default:
        return Icons.help;
    }
  }

  /// Generate enhanced status effects with particle animations
  List<StatusEffect> _generateStatusEffectsFromPlayer() {
    final effects = <StatusEffect>[];
    
    // Convert player status effects to enhanced status effects
    for (final entry in player.statusEffects.entries) {
      final effectName = entry.key.toLowerCase();
      final duration = entry.value;
      
      switch (effectName) {
        case 'burn':
        case 'burning':
          effects.add(StatusEffect.burning(duration: duration));
          break;
        case 'freeze':
        case 'frozen':
          effects.add(StatusEffect.frozen(duration: duration));
          break;
        case 'shock':
        case 'shocked':
          effects.add(StatusEffect.shocked(duration: duration));
          break;
        case 'strength':
        case 'strengthened':
          effects.add(StatusEffect.strengthened(duration: duration));
          break;
        case 'shield':
        case 'shielded':
          effects.add(StatusEffect.shielded(duration: duration));
          break;
        case 'regenerating':
        case 'heal':
          effects.add(StatusEffect.regenerating(duration: duration));
          break;
        case 'weakened':
        case 'weak':
          effects.add(StatusEffect.weakened(duration: duration));
          break;
        case 'silenced':
        case 'silence':
          effects.add(StatusEffect.silenced(duration: duration));
          break;
        case 'blessed':
        case 'blessing':
          effects.add(StatusEffect.blessed(duration: duration));
          break;
        default:
          // Create a generic effect for unknown status effects
          effects.add(StatusEffect(
            type: StatusEffectType.strengthened,
            name: effectName.toUpperCase(),
            description: 'Unknown effect',
            duration: duration,
            primaryColor: Colors.grey,
            secondaryColor: Colors.blueGrey,
            icon: Icons.help,
            isPositive: true,
          ));
      }
    }
    
    // Add dynamic effects based on player state
    if (player.currentHealth < player.maxHealth * 0.3) {
      // Player is critically wounded - add visual effect
      effects.add(StatusEffect(
        type: StatusEffectType.weakened,
        name: 'Critical',
        description: 'Critically wounded',
        duration: 1,
        primaryColor: Colors.red,
        secondaryColor: Colors.orange,
        icon: Icons.warning,
        isPositive: false,
        intensity: 1.5,
      ));
    }
    
    if (player.currentMana >= player.maxMana * 0.8) {
      // Player has high mana - add magical aura
      effects.add(StatusEffect(
        type: StatusEffectType.magicPowered,
        name: 'Energized',
        description: 'High magical energy',
        duration: 1,
        primaryColor: Colors.blue,
        secondaryColor: Colors.cyan,
        icon: Icons.auto_awesome,
        isPositive: true,
        intensity: 0.8,
      ));
    }
    
    if (isActive) {
      // Add active turn effect
      effects.add(StatusEffect(
        type: StatusEffectType.hastened,
        name: 'Active',
        description: 'Currently taking turn',
        duration: 1,
        primaryColor: Colors.yellow,
        secondaryColor: Colors.orange,
        icon: Icons.play_arrow,
        isPositive: true,
        intensity: 1.2,
      ));
    }
    
    return effects;
  }
}