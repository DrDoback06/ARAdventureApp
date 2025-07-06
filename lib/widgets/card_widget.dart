import 'package:flutter/material.dart';
import '../models/card_model.dart';

/// Widget for displaying game cards with proper styling and tooltips
class CardWidget extends StatelessWidget {
  final GameCard card;
  final Size size;
  final bool showTooltip;
  final VoidCallback? onTap;
  final bool isSelected;
  
  const CardWidget({
    Key? key,
    required this.card,
    this.size = const Size(120, 160),
    this.showTooltip = false,
    this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget cardWidget = GestureDetector(
      onTap: onTap,
      child: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          border: Border.all(
            color: isSelected 
                ? Colors.amber.shade700 
                : Color(int.parse('0xFF${card.getRarityColor().substring(1)}')),
            width: isSelected ? 3 : 2,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.amber.shade700.withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Column(
          children: [
            // Card header with name and type
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Color(int.parse('0xFF${card.getRarityColor().substring(1)}')).withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    card.type.name.toUpperCase(),
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),
            
            // Card image/icon
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                child: card.imageUrl != null && card.imageUrl!.isNotEmpty
                    ? Image.network(
                        card.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(),
                      )
                    : _buildDefaultIcon(),
              ),
            ),
            
            // Card stats
            if (size.height > 80)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                ),
                child: _buildCardStats(),
              ),
          ],
        ),
      ),
    );
    
    // Wrap with tooltip if requested
    if (showTooltip) {
      return Tooltip(
        message: _buildTooltipMessage(),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Color(int.parse('0xFF${card.getRarityColor().substring(1)}')), width: 1),
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
        child: cardWidget,
      );
    }
    
    return cardWidget;
  }
  
  /// Builds the default icon for cards without images
  Widget _buildDefaultIcon() {
    IconData iconData;
    Color iconColor = Colors.grey.shade400;
    
    switch (card.type) {
      case CardType.weapon:
        iconData = Icons.sword;
        iconColor = Colors.red.shade300;
        break;
      case CardType.armor:
        iconData = Icons.shield;
        iconColor = Colors.blue.shade300;
        break;
      case CardType.skill:
        iconData = Icons.auto_awesome;
        iconColor = Colors.purple.shade300;
        break;
      case CardType.quest:
        iconData = Icons.assignment;
        iconColor = Colors.yellow.shade300;
        break;
      case CardType.adventure:
        iconData = Icons.explore;
        iconColor = Colors.green.shade300;
        break;
      case CardType.consumable:
        iconData = Icons.local_drink;
        iconColor = Colors.orange.shade300;
        break;
      case CardType.accessory:
        iconData = Icons.diamond;
        iconColor = Colors.cyan.shade300;
        break;
      case CardType.spell:
        iconData = Icons.flash_on;
        iconColor = Colors.indigo.shade300;
        break;
      default:
        iconData = Icons.help_outline;
        break;
    }
    
    return Icon(
      iconData,
      color: iconColor,
      size: size.width * 0.4,
    );
  }
  
  /// Builds the card stats display
  Widget _buildCardStats() {
    List<Widget> statWidgets = [];
    
    // Attack
    if (card.attack > 0) {
      statWidgets.add(_buildStatWidget('ATK', card.attack, Colors.red.shade300));
    }
    
    // Defense
    if (card.defense > 0) {
      statWidgets.add(_buildStatWidget('DEF', card.defense, Colors.blue.shade300));
    }
    
    // Mana cost
    if (card.manaCost > 0) {
      statWidgets.add(_buildStatWidget('MP', card.manaCost, Colors.purple.shade300));
    }
    
    // Durability
    if (card.durability > 0) {
      statWidgets.add(_buildStatWidget('DUR', card.durability, Colors.yellow.shade300));
    }
    
    // If no stats, show rarity
    if (statWidgets.isEmpty) {
      statWidgets.add(
        Text(
          card.rarity.name.toUpperCase(),
          style: TextStyle(
            color: Color(int.parse('0xFF${card.getRarityColor().substring(1)}')),
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    
    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: statWidgets,
    );
  }
  
  /// Builds a single stat widget
  Widget _buildStatWidget(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  /// Builds the tooltip message
  String _buildTooltipMessage() {
    StringBuffer tooltip = StringBuffer();
    
    // Card name and type
    tooltip.writeln('${card.name} (${card.type.name})');
    tooltip.writeln('Rarity: ${card.rarity.name}');
    
    // Description
    if (card.description.isNotEmpty) {
      tooltip.writeln('\n${card.description}');
    }
    
    // Stats
    if (card.attack > 0 || card.defense > 0 || card.manaCost > 0 || card.durability > 0) {
      tooltip.writeln('\nStats:');
      if (card.attack > 0) tooltip.writeln('• Attack: ${card.attack}');
      if (card.defense > 0) tooltip.writeln('• Defense: ${card.defense}');
      if (card.manaCost > 0) tooltip.writeln('• Mana Cost: ${card.manaCost}');
      if (card.durability > 0) tooltip.writeln('• Durability: ${card.durability}');
    }
    
    // Stat modifiers
    if (card.statModifiers.isNotEmpty) {
      tooltip.writeln('\nModifiers:');
      for (var modifier in card.statModifiers) {
        String sign = modifier.value >= 0 ? '+' : '';
        String percent = modifier.isPercentage ? '%' : '';
        tooltip.writeln('• ${modifier.statName}: $sign${modifier.value}$percent');
      }
    }
    
    // Conditions
    if (card.conditions.isNotEmpty) {
      tooltip.writeln('\nRequirements:');
      for (var condition in card.conditions) {
        tooltip.writeln('• ${condition.conditionKey} ${condition.operator} ${condition.conditionValue}');
      }
    }
    
    // Effects
    if (card.effects.isNotEmpty) {
      tooltip.writeln('\nEffects:');
      for (var effect in card.effects) {
        tooltip.writeln('• ${effect.effectType} ${effect.value} on ${effect.target}');
        if (effect.duration > 0) {
          tooltip.write(' (${effect.duration} turns)');
        }
      }
    }
    
    // Quest info
    if (card.type == CardType.quest && card.questObjective != null) {
      tooltip.writeln('\nObjective: ${card.questObjective}');
    }
    
    // Usage limitations
    if (card.maxUsesPerTurn != -1 || card.maxUsesPerGame != -1 || card.cooldownTurns > 0) {
      tooltip.writeln('\nUsage:');
      if (card.maxUsesPerTurn != -1) {
        tooltip.writeln('• Max uses per turn: ${card.maxUsesPerTurn}');
      }
      if (card.maxUsesPerGame != -1) {
        tooltip.writeln('• Max uses per game: ${card.maxUsesPerGame}');
      }
      if (card.cooldownTurns > 0) {
        tooltip.writeln('• Cooldown: ${card.cooldownTurns} turns');
      }
    }
    
    // Gold value
    if (card.goldValue > 0) {
      tooltip.writeln('\nValue: ${card.goldValue} gold');
    }
    
    // Lore
    if (card.lore.isNotEmpty) {
      tooltip.writeln('\n"${card.lore}"');
    }
    
    return tooltip.toString().trim();
  }
}

/// Large card widget for detailed viewing
class LargeCardWidget extends StatelessWidget {
  final GameCard card;
  final VoidCallback? onClose;
  
  const LargeCardWidget({
    Key? key,
    required this.card,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 300,
        height: 450,
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          border: Border.all(
            color: Color(int.parse('0xFF${card.getRarityColor().substring(1)}')),
            width: 3,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Color(int.parse('0xFF${card.getRarityColor().substring(1)}')).withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with close button
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(int.parse('0xFF${card.getRarityColor().substring(1)}')).withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(9),
                  topRight: Radius.circular(9),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${card.type.name} • ${card.rarity.name}',
                          style: TextStyle(
                            color: Colors.grey.shade300,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onClose != null)
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                ],
              ),
            ),
            
            // Card image
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: card.imageUrl != null && card.imageUrl!.isNotEmpty
                    ? Image.network(
                        card.imageUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => _buildLargeIcon(),
                      )
                    : _buildLargeIcon(),
              ),
            ),
            
            // Card details
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      if (card.description.isNotEmpty) ...[
                        Text(
                          card.description,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      // Stats
                      _buildDetailedStats(),
                      
                      // Modifiers
                      if (card.statModifiers.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildModifiers(),
                      ],
                      
                      // Requirements
                      if (card.conditions.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildRequirements(),
                      ],
                      
                      // Lore
                      if (card.lore.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          '"${card.lore}"',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLargeIcon() {
    return CardWidget(card: card, size: const Size(120, 120));
  }
  
  Widget _buildDetailedStats() {
    List<Widget> statWidgets = [];
    
    if (card.attack > 0) {
      statWidgets.add(_buildDetailStat('Attack', card.attack, Colors.red.shade300));
    }
    if (card.defense > 0) {
      statWidgets.add(_buildDetailStat('Defense', card.defense, Colors.blue.shade300));
    }
    if (card.manaCost > 0) {
      statWidgets.add(_buildDetailStat('Mana Cost', card.manaCost, Colors.purple.shade300));
    }
    if (card.durability > 0) {
      statWidgets.add(_buildDetailStat('Durability', card.durability, Colors.yellow.shade300));
    }
    if (card.goldValue > 0) {
      statWidgets.add(_buildDetailStat('Value', card.goldValue, Colors.amber.shade300));
    }
    
    if (statWidgets.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stats',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        ...statWidgets,
      ],
    );
  }
  
  Widget _buildDetailStat(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 12,
            ),
          ),
          Text(
            '$value',
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
  
  Widget _buildModifiers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Modifiers',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        ...card.statModifiers.map((modifier) {
          String sign = modifier.value >= 0 ? '+' : '';
          String percent = modifier.isPercentage ? '%' : '';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Text(
              '• ${modifier.statName}: $sign${modifier.value}$percent',
              style: TextStyle(
                color: modifier.value >= 0 ? Colors.green.shade300 : Colors.red.shade300,
                fontSize: 12,
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
  
  Widget _buildRequirements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Requirements',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        ...card.conditions.map((condition) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Text(
              '• ${condition.conditionKey} ${condition.operator} ${condition.conditionValue}',
              style: TextStyle(
                color: Colors.orange.shade300,
                fontSize: 12,
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}