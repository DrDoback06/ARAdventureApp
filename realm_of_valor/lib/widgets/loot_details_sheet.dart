import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../constants/theme.dart';
import '../services/loot_system_service.dart';

class LootDetailsSheet extends StatelessWidget {
  final LootCache cache;
  final VoidCallback? onCollect;
  final bool isCollected;

  const LootDetailsSheet({
    super.key,
    required this.cache,
    this.onCollect,
    this.isCollected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: RealmOfValorTheme.textSecondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildLootInfo(),
                  const SizedBox(height: 16),
                  _buildContents(),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getLootColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getLootIcon(),
                color: _getLootColor(),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cache.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: RealmOfValorTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '${cache.rarityName} Loot Cache',
                    style: TextStyle(
                      fontSize: 14,
                      color: RealmOfValorTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getLootColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            cache.rarity.name.toUpperCase(),
            style: TextStyle(
              color: _getLootColor(),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLootInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cache Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: RealmOfValorTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        _buildInfoRow('Rarity', cache.rarity.name.toUpperCase()),
        _buildInfoRow('Items', '${cache.items.length} items'),
        _buildInfoRow('Status', isCollected ? 'COLLECTED' : 'AVAILABLE'),
      ],
    );
  }

  Widget _buildContents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contents',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: RealmOfValorTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (cache.items.isEmpty)
          Text(
            'This cache appears to be empty.',
            style: TextStyle(
              color: RealmOfValorTheme.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          ...cache.items.map((item) => _buildItemRow(item)),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (onCollect != null && !isCollected)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCollect,
              icon: const Icon(Icons.collections),
              label: const Text('Collect Loot'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getLootColor(),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        if (isCollected)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Already Collected',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
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

  Widget _buildItemRow(LootItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            _getItemIcon(item.type),
            color: _getItemColor(item.type),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.name,
              style: TextStyle(
                color: RealmOfValorTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${item.value} Gold',
            style: TextStyle(
              color: RealmOfValorTheme.accentGold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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

  IconData _getItemIcon(LootType type) {
    switch (type) {
      case LootType.weapon:
        return Icons.sports_martial_arts;
      case LootType.armor:
        return Icons.shield;
      case LootType.potion:
        return Icons.local_drink;
      case LootType.gem:
        return Icons.construction;
      case LootType.gold:
        return Icons.monetization_on;
      case LootType.experience:
        return Icons.star;
      case LootType.item:
        return Icons.inventory;
      case LootType.scroll:
        return Icons.description;
      case LootType.artifact:
        return Icons.auto_awesome;
    }
  }

  Color _getItemColor(LootType type) {
    switch (type) {
      case LootType.weapon:
        return Colors.red;
      case LootType.armor:
        return Colors.blue;
      case LootType.potion:
        return Colors.green;
      case LootType.gem:
        return Colors.orange;
      case LootType.gold:
        return Colors.yellow;
      case LootType.experience:
        return Colors.amber;
      case LootType.item:
        return Colors.grey;
      case LootType.scroll:
        return Colors.purple;
      case LootType.artifact:
        return Colors.indigo;
    }
  }
} 