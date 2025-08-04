import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../constants/theme.dart';
import '../services/loot_system_service.dart';

class LootCacheWidget extends StatefulWidget {
  final LootCache cache;
  final VoidCallback onCollect;
  final bool isNearby;

  const LootCacheWidget({
    super.key,
    required this.cache,
    required this.onCollect,
    this.isNearby = false,
  });

  @override
  State<LootCacheWidget> createState() => _LootCacheWidgetState();
}

class _LootCacheWidgetState extends State<LootCacheWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _glowController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.cache.rarityColor.withOpacity(_glowAnimation.value * 0.6),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                _showLootDetails();
              },
              onLongPress: () {
                HapticFeedback.heavyImpact();
                widget.onCollect();
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.cache.rarityColor,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: Icon(
                  _getLootIcon(),
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getLootIcon() {
    switch (widget.cache.rarity) {
      case LootRarity.common:
        return Icons.inventory;
      case LootRarity.uncommon:
        return Icons.inventory_2;
      case LootRarity.rare:
        return Icons.diamond;
      case LootRarity.epic:
        return Icons.star;
      case LootRarity.legendary:
        return Icons.auto_awesome;
    }
  }

  void _showLootDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LootDetailsSheet(cache: widget.cache),
    );
  }
}

class LootDetailsSheet extends StatelessWidget {
  final LootCache cache;

  const LootDetailsSheet({super.key, required this.cache});

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
          // Handle bar
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
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: cache.rarityColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: cache.rarityColor.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          _getLootIcon(),
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cache.name,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: RealmOfValorTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: cache.rarityColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: cache.rarityColor),
                              ),
                              child: Text(
                                cache.rarityName,
                                style: TextStyle(
                                  color: cache.rarityColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: RealmOfValorTheme.surfaceDark.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      cache.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: RealmOfValorTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Loot items
                  Text(
                    'Contents',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: RealmOfValorTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  ...cache.items.map((item) => _buildLootItemTile(item)),
                  
                  const SizedBox(height: 16),
                  
                  // Collection info
                  _buildCollectionInfo(),
                ],
              ),
            ),
          ),
          
          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: RealmOfValorTheme.surfaceDark.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      Navigator.pop(context);
                      // Trigger collection
                    },
                    icon: const Icon(Icons.collections),
                    label: const Text('Collect Loot'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cache.rarityColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLootItemTile(LootItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: item.rarityColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.rarityColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getItemIcon(item.type),
              color: item.rarityColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    color: RealmOfValorTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  item.description,
                  style: TextStyle(
                    color: RealmOfValorTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.value}',
                style: TextStyle(
                  color: item.rarityColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: item.rarityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.rarityName,
                  style: TextStyle(
                    color: item.rarityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Get close to this cache to collect the loot!',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getLootIcon() {
    switch (cache.rarity) {
      case LootRarity.common:
        return Icons.inventory;
      case LootRarity.uncommon:
        return Icons.inventory_2;
      case LootRarity.rare:
        return Icons.diamond;
      case LootRarity.epic:
        return Icons.star;
      case LootRarity.legendary:
        return Icons.auto_awesome;
    }
  }

  IconData _getItemIcon(LootType type) {
    switch (type) {
      case LootType.gold:
        return Icons.monetization_on;
      case LootType.experience:
        return Icons.star;
      case LootType.item:
        return Icons.inventory;
      case LootType.weapon:
        return Icons.gps_fixed;
      case LootType.armor:
        return Icons.shield;
      case LootType.potion:
        return Icons.local_drink;
      case LootType.scroll:
        return Icons.description;
      case LootType.gem:
        return Icons.diamond;
      case LootType.artifact:
        return Icons.auto_awesome;
    }
  }
} 