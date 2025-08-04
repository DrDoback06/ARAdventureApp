import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../constants/theme.dart';
import '../services/loot_system_service.dart';

class LootMarkerWidget extends StatelessWidget {
  final LootCache cache;
  final VoidCallback? onTap;
  final bool isCollected;

  const LootMarkerWidget({
    super.key,
    required this.cache,
    this.onTap,
    this.isCollected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isCollected ? null : onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: _getLootColor().withOpacity(isCollected ? 0.3 : 0.9),
          shape: BoxShape.circle,
          border: Border.all(
            color: isCollected ? Colors.grey : _getLootColor(),
            width: 2,
          ),
          boxShadow: isCollected ? null : [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          _getLootIcon(),
          color: isCollected ? Colors.grey : Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Color _getLootColor() {
    switch (cache.rarity) {
      case LootRarity.common:
        return Colors.green;
      case LootRarity.uncommon:
        return Colors.blue;
      case LootRarity.rare:
        return Colors.purple;
      case LootRarity.epic:
        return Colors.orange;
      case LootRarity.legendary:
        return Colors.red;
    }
  }

  IconData _getLootIcon() {
    switch (cache.rarity) {
      case LootRarity.common:
        return Icons.inventory;
      case LootRarity.uncommon:
        return Icons.inventory_2;
      case LootRarity.rare:
        return Icons.inventory_2_outlined;
      case LootRarity.epic:
        return Icons.star;
      case LootRarity.legendary:
        return Icons.auto_awesome;
    }
  }
} 