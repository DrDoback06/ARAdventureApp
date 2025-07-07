import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../constants/theme.dart';

class CardWidget extends StatelessWidget {
  const CardWidget({
    super.key,
    required this.cardInstance,
    this.width = 120,
    this.height = 160,
    this.onTap,
    this.onLongPress,
    this.showTooltip = true,
    this.isSelected = false,
  });

  final CardInstance cardInstance;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool showTooltip;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final card = cardInstance.card;
    final rarityColor = RealmOfValorTheme.getRarityColor(card.rarity.name);
    
    Widget cardWidget = GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress ?? () => _showCardDetails(context),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: RealmOfValorTheme.surfaceMedium,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? RealmOfValorTheme.accentGold : rarityColor,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: rarityColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: rarityColor.withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.name,
                    style: TextStyle(
                      color: rarityColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        _getCardTypeIcon(card.type),
                        size: 12,
                        color: RealmOfValorTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        card.type.name.toUpperCase(),
                        style: const TextStyle(
                          color: RealmOfValorTheme.textSecondary,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Card Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image placeholder
                    Container(
                      width: double.infinity,
                      height: 40,
                      decoration: BoxDecoration(
                        color: RealmOfValorTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: card.imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                card.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholderImage(),
                              ),
                            )
                          : _buildPlaceholderImage(),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Level requirement
                    if (card.levelRequirement > 1)
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 10,
                            color: RealmOfValorTheme.textSecondary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Lv.${card.levelRequirement}',
                            style: const TextStyle(
                              color: RealmOfValorTheme.textSecondary,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    
                    // Stat modifiers
                    if (card.statModifiers.isNotEmpty)
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: card.statModifiers.map((modifier) {
                              return Text(
                                '${modifier.isPercentage ? '+' : ''}${modifier.value}${modifier.isPercentage ? '%' : ''} ${modifier.statName}',
                                style: const TextStyle(
                                  color: RealmOfValorTheme.textPrimary,
                                  fontSize: 8,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Card Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: RealmOfValorTheme.surfaceLight,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Quantity
                  if (cardInstance.quantity > 1)
                    Text(
                      'x${cardInstance.quantity}',
                      style: const TextStyle(
                        color: RealmOfValorTheme.textPrimary,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  
                  // Durability
                  if (card.durability > 1)
                    Text(
                      '${cardInstance.currentDurability}/${card.durability}',
                      style: TextStyle(
                        color: _getDurabilityColor(cardInstance.currentDurability, card.durability),
                        fontSize: 8,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (showTooltip) {
      return Tooltip(
        message: _buildTooltipMessage(),
        child: cardWidget,
      );
    }

    return cardWidget;
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: RealmOfValorTheme.surfaceLight,
      child: Icon(
        _getCardTypeIcon(cardInstance.card.type),
        size: 20,
        color: RealmOfValorTheme.textSecondary,
      ),
    );
  }

  IconData _getCardTypeIcon(CardType type) {
    switch (type) {
      case CardType.weapon:
        return Icons.sports_martial_arts;
      case CardType.armor:
        return Icons.shield;
      case CardType.accessory:
        return Icons.diamond;
      case CardType.consumable:
        return Icons.local_drink;
      case CardType.spell:
        return Icons.auto_fix_high;
      case CardType.skill:
        return Icons.psychology;
      case CardType.quest:
        return Icons.assignment;
      case CardType.adventure:
        return Icons.explore;
      default:
        return Icons.category;
    }
  }

  Color _getDurabilityColor(int current, int max) {
    final percentage = current / max;
    if (percentage > 0.7) return RealmOfValorTheme.experienceGreen;
    if (percentage > 0.3) return RealmOfValorTheme.accentGold;
    return RealmOfValorTheme.healthRed;
  }

  String _buildTooltipMessage() {
    final card = cardInstance.card;
    final buffer = StringBuffer();
    
    buffer.writeln(card.name);
    buffer.writeln('${card.rarity.name.toUpperCase()} ${card.type.name.toUpperCase()}');
    
    if (card.levelRequirement > 1) {
      buffer.writeln('Level Requirement: ${card.levelRequirement}');
    }
    
    if (card.statModifiers.isNotEmpty) {
      buffer.writeln('');
      for (final modifier in card.statModifiers) {
        buffer.writeln('${modifier.isPercentage ? '+' : ''}${modifier.value}${modifier.isPercentage ? '%' : ''} ${modifier.statName}');
      }
    }
    
    if (card.description.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln(card.description);
    }
    
    return buffer.toString().trim();
  }

  void _showCardDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CardDetailsDialog(cardInstance: cardInstance),
    );
  }
}

class CardDetailsDialog extends StatelessWidget {
  final CardInstance cardInstance;

  const CardDetailsDialog({Key? key, required this.cardInstance}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final card = cardInstance.card;
    final rarityColor = RealmOfValorTheme.getRarityColor(card.rarity.name);

    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  _getCardTypeIcon(card.type),
                  color: rarityColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.name,
                        style: TextStyle(
                          color: rarityColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${card.rarity.name.toUpperCase()} ${card.type.name.toUpperCase()}',
                        style: const TextStyle(
                          color: RealmOfValorTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const Divider(),
            
            // Description
            if (card.description.isNotEmpty) ...[
              Text(
                card.description,
                style: const TextStyle(
                  color: RealmOfValorTheme.textPrimary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Stats
            if (card.statModifiers.isNotEmpty) ...[
              const Text(
                'Stats:',
                style: TextStyle(
                  color: RealmOfValorTheme.accentGold,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...card.statModifiers.map((modifier) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.add, size: 12, color: RealmOfValorTheme.experienceGreen),
                    const SizedBox(width: 4),
                    Text(
                      '${modifier.value}${modifier.isPercentage ? '%' : ''} ${modifier.statName}',
                      style: const TextStyle(
                        color: RealmOfValorTheme.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 16),
            ],
            
            // Properties
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPropertyRow('Level Req:', card.levelRequirement.toString()),
                      _buildPropertyRow('Cost:', card.cost.toString()),
                      _buildPropertyRow('Durability:', '${cardInstance.currentDurability}/${card.durability}'),
                      if (cardInstance.quantity > 1)
                        _buildPropertyRow('Quantity:', cardInstance.quantity.toString()),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPropertyRow('Tradeable:', card.isTradeable ? 'Yes' : 'No'),
                      _buildPropertyRow('Consumable:', card.isConsumable ? 'Yes' : 'No'),
                      _buildPropertyRow('Max Stack:', card.maxStack.toString()),
                      if (card.equipmentSlot != EquipmentSlot.none)
                        _buildPropertyRow('Slot:', card.equipmentSlot.name),
                    ],
                  ),
                ),
              ],
            ),
            
            // Effects
            if (card.effects.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Effects:',
                style: TextStyle(
                  color: RealmOfValorTheme.accentGold,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...card.effects.map((effect) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• ${effect.description}',
                  style: const TextStyle(
                    color: RealmOfValorTheme.textPrimary,
                    fontSize: 14,
                  ),
                ),
              )),
            ],
            
            // Conditions
            if (card.conditions.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Conditions:',
                style: TextStyle(
                  color: RealmOfValorTheme.accentGold,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...card.conditions.map((condition) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• ${condition.description}',
                  style: const TextStyle(
                    color: RealmOfValorTheme.textPrimary,
                    fontSize: 14,
                  ),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: RealmOfValorTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: RealmOfValorTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCardTypeIcon(CardType type) {
    switch (type) {
      case CardType.weapon:
        return Icons.sports_martial_arts;
      case CardType.armor:
        return Icons.shield;
      case CardType.accessory:
        return Icons.diamond;
      case CardType.consumable:
        return Icons.local_drink;
      case CardType.spell:
        return Icons.auto_fix_high;
      case CardType.skill:
        return Icons.psychology;
      case CardType.quest:
        return Icons.assignment;
      case CardType.adventure:
        return Icons.explore;
      default:
        return Icons.category;
    }
  }
}