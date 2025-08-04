import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../providers/character_provider.dart';
import '../models/character_model.dart';
import '../models/card_model.dart';
import 'card_widget.dart';

class InventoryContent extends StatefulWidget {
  const InventoryContent({super.key});

  @override
  State<InventoryContent> createState() => _InventoryContentState();
}

class _InventoryContentState extends State<InventoryContent>
    with TickerProviderStateMixin {
  late TabController _tabController;
  CardInstance? _draggedItem;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: Building Inventory Content');
    return Consumer<CharacterProvider>(
      builder: (context, characterProvider, child) {
        final character = characterProvider.currentCharacter;
        
        if (character == null) {
          print('DEBUG: No character selected in Inventory');
          return const Center(
            child: Text(
              'No character selected',
              style: TextStyle(color: RealmOfValorTheme.textSecondary),
            ),
          );
        }

        print('DEBUG: Inventory loaded for: ${character.name}');
        return Column(
          children: [
            // Tab Bar
            Container(
              decoration: const BoxDecoration(
                color: RealmOfValorTheme.surfaceDark,
                border: Border(
                  bottom: BorderSide(color: RealmOfValorTheme.primaryLight),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: RealmOfValorTheme.accentGold,
                labelColor: RealmOfValorTheme.accentGold,
                unselectedLabelColor: RealmOfValorTheme.textSecondary,
                tabs: const [
                  Tab(text: 'Equipment'),
                  Tab(text: 'Inventory'),
                  Tab(text: 'Stash'),
                ],
              ),
            ),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEquipmentTab(character),
                  _buildInventoryTab(character),
                  _buildStashTab(character),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEquipmentTab(GameCharacter character) {
    final equipment = character.equipment;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Equipment',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Equipment Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildEquipmentSlot('Helmet', equipment.helmet, Icons.face),
              _buildEquipmentSlot('Armor', equipment.armor, Icons.security),
              _buildEquipmentSlot('Weapon 1', equipment.weapon1, Icons.flash_on),
              _buildEquipmentSlot('Weapon 2', equipment.weapon2, Icons.flash_on),
              _buildEquipmentSlot('Gloves', equipment.gloves, Icons.pan_tool),
              _buildEquipmentSlot('Boots', equipment.boots, Icons.directions_walk),
              _buildEquipmentSlot('Belt', equipment.belt, Icons.circle),
              _buildEquipmentSlot('Ring 1', equipment.ring1, Icons.circle),
              _buildEquipmentSlot('Ring 2', equipment.ring2, Icons.circle),
              _buildEquipmentSlot('Amulet', equipment.amulet, Icons.diamond),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryTab(GameCharacter character) {
    final inventory = character.inventory;
    
    return Column(
      children: [
        // Inventory Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Inventory',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: RealmOfValorTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${inventory.length} items',
                style: const TextStyle(
                  fontSize: 14,
                  color: RealmOfValorTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        
        // Inventory Grid
        Expanded(
          child: inventory.isEmpty
              ? const Center(
                  child: Text(
                    'Inventory is empty',
                    style: TextStyle(color: RealmOfValorTheme.textSecondary),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: inventory.length,
                  itemBuilder: (context, index) {
                    final item = inventory[index];
                    return _buildInventoryItem(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStashTab(GameCharacter character) {
    final stash = character.stash;
    
    return Column(
      children: [
        // Stash Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Stash',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: RealmOfValorTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${stash.length} items',
                style: const TextStyle(
                  fontSize: 14,
                  color: RealmOfValorTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        
        // Stash Grid
        Expanded(
          child: stash.isEmpty
              ? const Center(
                  child: Text(
                    'Stash is empty',
                    style: TextStyle(color: RealmOfValorTheme.textSecondary),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: stash.length,
                  itemBuilder: (context, index) {
                    final item = stash[index];
                    return _buildInventoryItem(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEquipmentSlot(String slotName, CardInstance? item, IconData defaultIcon) {
    return Container(
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: item != null 
              ? _getRarityColor(item.card.rarity)
              : RealmOfValorTheme.primaryLight,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            item != null ? Icons.inventory : defaultIcon,
            color: item != null 
                ? _getRarityColor(item.card.rarity)
                : RealmOfValorTheme.textSecondary,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            slotName,
            style: const TextStyle(
              fontSize: 10,
              color: RealmOfValorTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (item != null) ...[
            const SizedBox(height: 4),
            Text(
              item.card.name,
              style: const TextStyle(
                fontSize: 8,
                color: RealmOfValorTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInventoryItem(CardInstance item) {
    return GestureDetector(
      onTap: () => _showItemDetails(item),
      child: Container(
        decoration: BoxDecoration(
          color: RealmOfValorTheme.surfaceDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _getRarityColor(item.card.rarity),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory,
              color: _getRarityColor(item.card.rarity),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              item.card.name,
              style: const TextStyle(
                fontSize: 8,
                color: RealmOfValorTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (item.quantity > 1) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: RealmOfValorTheme.accentGold,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${item.quantity}',
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showItemDetails(CardInstance item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: RealmOfValorTheme.surfaceMedium,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: RealmOfValorTheme.textSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Item details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.inventory,
                        color: _getRarityColor(item.card.rarity),
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.card.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: RealmOfValorTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Quantity: ${item.quantity}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: RealmOfValorTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.card.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: RealmOfValorTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // TODO: Implement equip functionality
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: RealmOfValorTheme.accentGold,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Equip'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // TODO: Implement drop functionality
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: RealmOfValorTheme.surfaceDark,
                            foregroundColor: RealmOfValorTheme.accentGold,
                          ),
                          child: const Text('Drop'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRarityColor(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.common:
        return RealmOfValorTheme.rarityCommon;
      case CardRarity.uncommon:
        return RealmOfValorTheme.rarityUncommon;
      case CardRarity.rare:
        return RealmOfValorTheme.rarityRare;
      case CardRarity.epic:
        return RealmOfValorTheme.rarityEpic;
      case CardRarity.legendary:
        return RealmOfValorTheme.rarityLegendary;
      case CardRarity.mythic:
        return RealmOfValorTheme.rarityMythic;
      case CardRarity.holographic:
        return RealmOfValorTheme.rarityMythic;
      case CardRarity.firstEdition:
        return RealmOfValorTheme.rarityLegendary;
      case CardRarity.limitedEdition:
        return RealmOfValorTheme.rarityEpic;
    }
  }
} 