import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../constants/theme.dart';
import '../providers/character_provider.dart';
import 'package:provider/provider.dart';
import '../models/character_model.dart';
import '../services/quest_generator_service.dart';

class EquipmentInventoryWidget extends StatefulWidget {
  final VoidCallback? onClose;
  final Function(CardInstance)? onItemDropped;
  final bool showRewards;
  final AdventureQuest? rewardQuest;
  final Function(CardInstance)? onRewardCollected;
  final VoidCallback? onRewardsClosed;

  const EquipmentInventoryWidget({
    Key? key,
    this.onClose,
    this.onItemDropped,
    this.showRewards = false,
    this.rewardQuest,
    this.onRewardCollected,
    this.onRewardsClosed,
  }) : super(key: key);

  @override
  State<EquipmentInventoryWidget> createState() => _EquipmentInventoryWidgetState();
}

class _EquipmentInventoryWidgetState extends State<EquipmentInventoryWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  int _selectedTabIndex = 0;
  CardInstance? _selectedItem;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 100),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: RealmOfValorTheme.surfaceDark,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildHeader(),
                  _buildTabBar(),
                  Expanded(
                    child: _buildTabContent(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.accentGold.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.inventory,
            color: RealmOfValorTheme.accentGold,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            'Equipment & Inventory',
            style: TextStyle(
              color: RealmOfValorTheme.accentGold,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: widget.onClose,
            icon: Icon(
              Icons.close,
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildTabButton('Equipment', 0),
          const SizedBox(width: 8),
          _buildTabButton('Inventory', 1),
          const SizedBox(width: 8),
          _buildTabButton('Stash', 2),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? RealmOfValorTheme.accentGold 
                : RealmOfValorTheme.surfaceLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected 
                  ? Colors.black 
                  : RealmOfValorTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildEquipmentTab();
      case 1:
        return _buildInventoryTab();
      case 2:
        return _buildStashTab();
      default:
        return _buildInventoryTab();
    }
  }

  Widget _buildEquipmentTab() {
    return Consumer<CharacterProvider>(
      builder: (context, characterProvider, child) {
        final character = characterProvider.currentCharacter;
        
        return Column(
          children: [
            // Equipment slots with drag targets
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(16),
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildEquipmentSlotWithDragTarget('Weapon', Icons.gps_fixed, character?.equipment.getItemInSlot(EquipmentSlot.weapon1)),
                  _buildEquipmentSlotWithDragTarget('Shield', Icons.shield, character?.equipment.getItemInSlot(EquipmentSlot.weapon2)),
                  _buildEquipmentSlotWithDragTarget('Helmet', Icons.face, character?.equipment.getItemInSlot(EquipmentSlot.helmet)),
                  _buildEquipmentSlotWithDragTarget('Armor', Icons.security, character?.equipment.getItemInSlot(EquipmentSlot.armor)),
                  _buildEquipmentSlotWithDragTarget('Gloves', Icons.touch_app, character?.equipment.getItemInSlot(EquipmentSlot.gloves)),
                  _buildEquipmentSlotWithDragTarget('Boots', Icons.directions_walk, character?.equipment.getItemInSlot(EquipmentSlot.boots)),
                ],
              ),
            ),
            // Character stats with XP bar
            Container(
              padding: const EdgeInsets.all(16),
              child: _buildCharacterStats(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEquipmentSlotWithDragTarget(String slotName, IconData icon, CardInstance? equippedItem) {
    return DragTarget<CardInstance>(
      onWillAccept: (data) => true,
      onAccept: (item) async {
        // Equip the item
        final characterProvider = Provider.of<CharacterProvider>(context, listen: false);
        await characterProvider.equipItem(item);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.card.name} equipped to $slotName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty 
                ? RealmOfValorTheme.accentGold.withOpacity(0.1)
                : RealmOfValorTheme.surfaceLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: candidateData.isNotEmpty
                  ? RealmOfValorTheme.accentGold
                  : RealmOfValorTheme.accentGold.withOpacity(0.5),
              width: candidateData.isNotEmpty ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: RealmOfValorTheme.accentGold,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                slotName,
                style: TextStyle(
                  color: RealmOfValorTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (equippedItem != null) ...[
                const SizedBox(height: 4),
                Text(
                  equippedItem.card.name,
                  style: TextStyle(
                    color: RealmOfValorTheme.textSecondary,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ] else ...[
                const SizedBox(height: 4),
                Text(
                  candidateData.isNotEmpty ? 'Drop to equip' : 'Empty',
                  style: TextStyle(
                    color: candidateData.isNotEmpty 
                        ? RealmOfValorTheme.accentGold
                        : RealmOfValorTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: candidateData.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String name, int value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: RealmOfValorTheme.accentGold, size: 20),
        const SizedBox(height: 4),
        Text(
          name,
          style: TextStyle(
            color: RealmOfValorTheme.textSecondary,
            fontSize: 10,
          ),
        ),
        Text(
          value.toString(),
          style: TextStyle(
            color: RealmOfValorTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCharacterStats() {
    return Consumer<CharacterProvider>(
      builder: (context, characterProvider, child) {
        final character = characterProvider.currentCharacter;
        final currentXP = character?.experience ?? 0;
        final level = character?.level ?? 1;
        final xpForNextLevel = _calculateXPForNextLevel(level);
        final xpProgress = currentXP % xpForNextLevel;
        final xpPercentage = xpProgress / xpForNextLevel;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: RealmOfValorTheme.surfaceLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: RealmOfValorTheme.accentGold.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Character Stats',
                style: TextStyle(
                  color: RealmOfValorTheme.accentGold,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              // XP Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Level $level',
                        style: TextStyle(
                          color: RealmOfValorTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$currentXP XP',
                        style: TextStyle(
                          color: RealmOfValorTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: RealmOfValorTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: xpPercentage,
                      child: Container(
                        decoration: BoxDecoration(
                          color: RealmOfValorTheme.accentGold,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${xpProgress.toStringAsFixed(0)} / $xpForNextLevel XP to next level',
                    style: TextStyle(
                      color: RealmOfValorTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildStatItem('Strength', character?.baseStrength ?? 15, Icons.fitness_center)),
                  Expanded(child: _buildStatItem('Dexterity', character?.baseDexterity ?? 12, Icons.speed)),
                  Expanded(child: _buildStatItem('Vitality', character?.baseVitality ?? 18, Icons.favorite)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildStatItem('Energy', character?.baseEnergy ?? 10, Icons.bolt)),
                  Expanded(child: _buildStatItem('Level', level, Icons.trending_up)),
                  Expanded(child: _buildStatItem('Gold', character?.gold ?? 1250, Icons.monetization_on)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  int _calculateXPForNextLevel(int level) {
    // Simple XP calculation: 1000 XP per level
    return level * 1000;
  }

  Widget _buildInventoryTab() {
    return Consumer<CharacterProvider>(
      builder: (context, characterProvider, child) {
        final character = characterProvider.currentCharacter;
        final inventoryItems = character?.inventory ?? [];
        
        return Column(
          children: [
            // Search bar
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search inventory...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            
            // Rewards section (if showing rewards)
            if (widget.showRewards && widget.rewardQuest != null)
              _buildRewardsSection(),
            
            // Inventory items with slots
            Expanded(
              child: DragTarget<CardInstance>(
                onWillAccept: (data) => true,
                onAccept: (item) {
                  widget.onItemDropped?.call(item);
                },
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    decoration: BoxDecoration(
                      color: candidateData.isNotEmpty 
                          ? RealmOfValorTheme.accentGold.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: candidateData.isNotEmpty
                          ? Border.all(
                              color: RealmOfValorTheme.accentGold,
                              width: 2,
                            )
                          : null,
                    ),
                    child: inventoryItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2,
                                  color: RealmOfValorTheme.textSecondary,
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Inventory Empty',
                                  style: TextStyle(
                                    color: RealmOfValorTheme.textSecondary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  candidateData.isNotEmpty
                                      ? 'Drop item here to add to inventory'
                                      : 'Complete quests to find items!',
                                  style: TextStyle(
                                    color: candidateData.isNotEmpty
                                        ? RealmOfValorTheme.accentGold
                                        : RealmOfValorTheme.textSecondary,
                                    fontSize: 14,
                                    fontWeight: candidateData.isNotEmpty
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              childAspectRatio: 1.6,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: inventoryItems.length,
                            itemBuilder: (context, index) {
                              final item = inventoryItems[index];
                              return Draggable<CardInstance>(
                                data: item,
                                feedback: _buildItemCard(item, isDragging: true),
                                childWhenDragging: _buildItemCard(item, isDragging: true),
                                child: _buildItemCard(item),
                              );
                            },
                          ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRewardsSection() {
    if (widget.rewardQuest == null) return const SizedBox.shrink();
    
    final quest = widget.rewardQuest!;
    final itemRewards = quest.rewards.where((r) => r.type == RewardType.item).map((r) => CardInstance(
      card: GameCard(
        name: r.description,
        description: r.description,
        type: CardType.item,
        rarity: CardRarity.common,
      ),
    )).toList();
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.accentGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: RealmOfValorTheme.accentGold.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star,
                color: RealmOfValorTheme.accentGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Quest Rewards',
                style: TextStyle(
                  color: RealmOfValorTheme.accentGold,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: widget.onRewardsClosed,
                icon: const Icon(Icons.close),
                color: RealmOfValorTheme.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // XP and Gold rewards
          Row(
            children: [
              _buildRewardChip(Icons.star, '${quest.rewardXP} XP', Colors.amber),
              const SizedBox(width: 8),
              _buildRewardChip(Icons.monetization_on, '${quest.rewardGold} Gold', Colors.yellow),
            ],
          ),
          
          if (itemRewards.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Items:',
              style: TextStyle(
                color: RealmOfValorTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: itemRewards.map((item) => Draggable<CardInstance>(
                data: item,
                feedback: _buildRewardItemCard(item, isDragging: true),
                childWhenDragging: _buildRewardItemCard(item, isDragging: true),
                child: _buildRewardItemCard(item),
                onDragCompleted: () {
                  widget.onRewardCollected?.call(item);
                },
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRewardChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardItemCard(CardInstance item, {bool isDragging = false}) {
    return Container(
      width: 60,
      height: 80,
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceLight.withOpacity(isDragging ? 0.8 : 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getRarityColor(item.card.rarity).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getItemIcon(item.card.name),
            color: _getItemColor(item.card.name),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            item.card.name,
            style: TextStyle(
              color: RealmOfValorTheme.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryItem(CardInstance item) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedItem = item;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: _selectedItem == item 
              ? RealmOfValorTheme.accentGold.withOpacity(0.3)
              : RealmOfValorTheme.surfaceLight.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedItem == item 
                ? RealmOfValorTheme.accentGold
                : RealmOfValorTheme.accentGold.withOpacity(0.3),
            width: _selectedItem == item ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getItemIcon(item.card.name),
              color: _getItemColor(item.card.name),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              item.card.name,
              style: TextStyle(
                color: RealmOfValorTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              item.card.rarity.name.toUpperCase(),
              style: TextStyle(
                color: _getRarityColor(item.card.rarity),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStashTab() {
    return Consumer<CharacterProvider>(
      builder: (context, characterProvider, child) {
        final character = characterProvider.currentCharacter;
        final stashItems = character?.stash ?? [];
        
        return Column(
          children: [
            // Header with info
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.home,
                    color: RealmOfValorTheme.accentGold,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Stash (One-way transfer)',
                    style: TextStyle(
                      color: RealmOfValorTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Stash items (read-only with drag target for one-way transfer)
            Expanded(
              child: DragTarget<CardInstance>(
                onWillAccept: (data) => true,
                onAccept: (item) async {
                  // Move item from inventory to stash
                  final characterProvider = Provider.of<CharacterProvider>(context, listen: false);
                  await characterProvider.moveToStash(item.instanceId);
                  
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${item.card.name} moved to stash'),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    decoration: BoxDecoration(
                      color: candidateData.isNotEmpty 
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: candidateData.isNotEmpty
                          ? Border.all(
                              color: Colors.orange,
                              width: 2,
                            )
                          : null,
                    ),
                    child: stashItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.storage,
                                  color: RealmOfValorTheme.textSecondary,
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Stash Empty',
                                  style: TextStyle(
                                    color: RealmOfValorTheme.textSecondary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  candidateData.isNotEmpty
                                      ? 'Drop item here to move to stash'
                                      : 'Drag items from inventory to store them',
                                  style: TextStyle(
                                    color: candidateData.isNotEmpty
                                        ? Colors.orange
                                        : RealmOfValorTheme.textSecondary,
                                    fontSize: 14,
                                    fontWeight: candidateData.isNotEmpty
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              childAspectRatio: 1.6,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: stashItems.length,
                            itemBuilder: (context, index) {
                              final item = stashItems[index];
                              return _buildItemCard(item, isStash: true);
                            },
                          ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildItemCard(CardInstance item, {bool isDragging = false, bool isStash = false}) {
    return Container(
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceLight.withOpacity(isDragging ? 0.8 : 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getRarityColor(item.card.rarity).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getItemIcon(item.card.name),
            color: _getItemColor(item.card.name),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            item.card.name,
            style: TextStyle(
              color: RealmOfValorTheme.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (isStash)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'STASH',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getItemIcon(String itemName) {
    final lowerName = itemName.toLowerCase();
    if (lowerName.contains('sword') || lowerName.contains('weapon')) {
      return Icons.gps_fixed;
    } else if (lowerName.contains('armor') || lowerName.contains('shield')) {
      return Icons.shield;
    } else if (lowerName.contains('potion') || lowerName.contains('heal')) {
      return Icons.local_drink;
    } else if (lowerName.contains('scroll') || lowerName.contains('spell')) {
      return Icons.auto_stories;
    } else if (lowerName.contains('treasure') || lowerName.contains('gold')) {
      return Icons.workspace_premium;
    } else if (lowerName.contains('rare')) {
      return Icons.diamond;
    } else {
      return Icons.inventory;
    }
  }

  Color _getItemColor(String itemName) {
    final lowerName = itemName.toLowerCase();
    if (lowerName.contains('rare')) {
      return Colors.purple;
    } else if (lowerName.contains('epic')) {
      return Colors.deepPurple;
    } else if (lowerName.contains('legendary')) {
      return Colors.orange;
    } else if (lowerName.contains('potion')) {
      return Colors.green;
    } else if (lowerName.contains('weapon')) {
      return Colors.red;
    } else if (lowerName.contains('armor')) {
      return Colors.blue;
    } else {
      return RealmOfValorTheme.accentGold;
    }
  }

  Color _getRarityColor(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.common:
        return Colors.grey;
      case CardRarity.uncommon:
        return Colors.green;
      case CardRarity.rare:
        return Colors.blue;
      case CardRarity.epic:
        return Colors.purple;
      case CardRarity.legendary:
        return Colors.orange;
      case CardRarity.mythic:
        return Colors.red;
      case CardRarity.holographic:
        return Colors.cyan;
      case CardRarity.firstEdition:
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
} 