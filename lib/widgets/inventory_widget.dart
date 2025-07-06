import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/character_model.dart';
import '../models/card_model.dart';
import '../providers/character_provider.dart';
import 'card_widget.dart';

/// Drag and drop inventory widget similar to Diablo II
class InventoryWidget extends StatefulWidget {
  final GameCharacter character;
  final VoidCallback? onStatsChanged;
  
  const InventoryWidget({
    Key? key,
    required this.character,
    this.onStatsChanged,
  }) : super(key: key);

  @override
  State<InventoryWidget> createState() => _InventoryWidgetState();
}

class _InventoryWidgetState extends State<InventoryWidget> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _showStash = false;
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
    return Container(
      width: double.infinity,
      height: 600,
      decoration: BoxDecoration(
        color: Colors.black87,
        border: Border.all(color: Colors.amber.shade700, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header with character stats
          _buildStatsHeader(),
          
          // Main inventory area
          Expanded(
            child: Row(
              children: [
                // Equipment slots (left side)
                _buildEquipmentSlots(),
                
                // Inventory grid (right side)
                Expanded(
                  child: Column(
                    children: [
                      // Tab bar for inventory/stash
                      _buildTabBar(),
                      
                      // Inventory/stash content
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildInventoryGrid(),
                            _buildStashGrid(),
                            _buildSkillsPanel(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Builds the stats header showing character information
  Widget _buildStatsHeader() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border: Border(bottom: BorderSide(color: Colors.amber.shade700)),
      ),
      child: Row(
        children: [
          // Character portrait
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.amber.shade700),
              borderRadius: BorderRadius.circular(4),
            ),
            child: widget.character.portraitUrl.isNotEmpty
                ? Image.network(widget.character.portraitUrl, fit: BoxFit.cover)
                : Icon(Icons.person, color: Colors.amber.shade700),
          ),
          
          const SizedBox(width: 12),
          
          // Character info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.character.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Level ${widget.character.level} ${widget.character.characterClass.name.toUpperCase()}',
                  style: TextStyle(
                    color: Colors.amber.shade700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Real-time stats
          _buildStatDisplay('ATK', widget.character.getTotalAttack()),
          const SizedBox(width: 8),
          _buildStatDisplay('DEF', widget.character.getTotalDefense()),
          const SizedBox(width: 8),
          _buildStatDisplay('HP', widget.character.currentHealth, widget.character.getActualMaxHealth()),
          const SizedBox(width: 8),
          _buildStatDisplay('MP', widget.character.currentMana, widget.character.getActualMaxMana()),
        ],
      ),
    );
  }
  
  /// Builds a stat display widget
  Widget _buildStatDisplay(String label, int current, [int? max]) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.amber.shade700,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          max != null ? '$current/$max' : '$current',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  /// Builds the tab bar for inventory/stash navigation
  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        border: Border(bottom: BorderSide(color: Colors.amber.shade700)),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Inventory'),
          Tab(text: 'Stash'),
          Tab(text: 'Skills'),
        ],
        labelColor: Colors.amber.shade700,
        unselectedLabelColor: Colors.grey.shade400,
        indicatorColor: Colors.amber.shade700,
      ),
    );
  }
  
  /// Builds the equipment slots panel
  Widget _buildEquipmentSlots() {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border: Border(right: BorderSide(color: Colors.amber.shade700)),
      ),
      child: Column(
        children: [
          // Top row: helmet
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildEquipmentSlot(EquipmentSlot.helmet, 'Helmet'),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Second row: weapon1, armor, weapon2
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildEquipmentSlot(EquipmentSlot.weapon1, 'Weapon 1'),
              _buildEquipmentSlot(EquipmentSlot.armor, 'Armor'),
              _buildEquipmentSlot(EquipmentSlot.weapon2, 'Weapon 2'),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Third row: gloves, belt, boots
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildEquipmentSlot(EquipmentSlot.gloves, 'Gloves'),
              _buildEquipmentSlot(EquipmentSlot.belt, 'Belt'),
              _buildEquipmentSlot(EquipmentSlot.boots, 'Boots'),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Fourth row: rings and amulet
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildEquipmentSlot(EquipmentSlot.ring1, 'Ring 1'),
              _buildEquipmentSlot(EquipmentSlot.amulet, 'Amulet'),
              _buildEquipmentSlot(EquipmentSlot.ring2, 'Ring 2'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Skill slots (belt skills)
          const Text(
            'Active Skills',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildEquipmentSlot(EquipmentSlot.skill1, 'Skill 1'),
              _buildEquipmentSlot(EquipmentSlot.skill2, 'Skill 2'),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Builds a single equipment slot
  Widget _buildEquipmentSlot(EquipmentSlot slot, String label) {
    final equippedItem = widget.character.equipment.getSlot(slot);
    
    return DragTarget<CardInstance>(
      onAccept: (item) => _equipItem(item, slot),
      onWillAccept: (item) => _canEquipItem(item, slot),
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty ? Colors.amber.shade700.withOpacity(0.3) : Colors.grey.shade800,
            border: Border.all(
              color: candidateData.isNotEmpty ? Colors.amber.shade700 : Colors.grey.shade600,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: equippedItem != null
              ? Draggable<CardInstance>(
                  data: equippedItem,
                  feedback: _buildDragFeedback(equippedItem),
                  childWhenDragging: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      border: Border.all(color: Colors.grey.shade600),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: CardWidget(
                    card: equippedItem.card,
                    size: const Size(44, 44),
                    showTooltip: true,
                  ),
                )
              : Center(
                  child: Icon(
                    _getSlotIcon(slot),
                    color: Colors.grey.shade600,
                    size: 24,
                  ),
                ),
        );
      },
    );
  }
  
  /// Builds the inventory grid
  Widget _buildInventoryGrid() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8, // 8 columns like Diablo II
          childAspectRatio: 1,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: widget.character.inventorySize,
        itemBuilder: (context, index) {
          final item = index < widget.character.inventory.length
              ? widget.character.inventory[index]
              : null;
          
          return _buildInventorySlot(item, index, false);
        },
      ),
    );
  }
  
  /// Builds the stash grid
  Widget _buildStashGrid() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8, // 8 columns
          childAspectRatio: 1,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: widget.character.stashSize,
        itemBuilder: (context, index) {
          final item = index < widget.character.stash.length
              ? widget.character.stash[index]
              : null;
          
          return _buildInventorySlot(item, index, true);
        },
      ),
    );
  }
  
  /// Builds the skills panel
  Widget _buildSkillsPanel() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Skill Trees',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // TODO: Implement skill tree UI
          Expanded(
            child: Center(
              child: Text(
                'Skill trees coming soon...',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Builds a single inventory slot
  Widget _buildInventorySlot(CardInstance? item, int index, bool isStash) {
    return DragTarget<CardInstance>(
      onAccept: (draggedItem) => _moveItemToSlot(draggedItem, index, isStash),
      onWillAccept: (draggedItem) => item == null, // Can only drop on empty slots
      builder: (context, candidateData, rejectedData) {
        return Container(
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty 
                ? Colors.amber.shade700.withOpacity(0.3) 
                : Colors.grey.shade800,
            border: Border.all(
              color: candidateData.isNotEmpty 
                  ? Colors.amber.shade700 
                  : Colors.grey.shade600,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          child: item != null
              ? Draggable<CardInstance>(
                  data: item,
                  feedback: _buildDragFeedback(item),
                  childWhenDragging: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      border: Border.all(color: Colors.grey.shade600),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  child: CardWidget(
                    card: item.card,
                    size: const Size(44, 44),
                    showTooltip: true,
                  ),
                )
              : null,
        );
      },
    );
  }
  
  /// Builds the drag feedback widget
  Widget _buildDragFeedback(CardInstance item) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.amber.shade700, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: CardWidget(
          card: item.card,
          size: const Size(44, 44),
        ),
      ),
    );
  }
  
  /// Gets the appropriate icon for an equipment slot
  IconData _getSlotIcon(EquipmentSlot slot) {
    switch (slot) {
      case EquipmentSlot.helmet:
        return Icons.sports_motorsports;
      case EquipmentSlot.armor:
        return Icons.shield;
      case EquipmentSlot.weapon1:
      case EquipmentSlot.weapon2:
        return Icons.sword;
      case EquipmentSlot.gloves:
        return Icons.back_hand;
      case EquipmentSlot.boots:
        return Icons.directions_run;
      case EquipmentSlot.belt:
        return Icons.belt;
      case EquipmentSlot.ring1:
      case EquipmentSlot.ring2:
        return Icons.circle;
      case EquipmentSlot.amulet:
        return Icons.diamond;
      case EquipmentSlot.skill1:
      case EquipmentSlot.skill2:
        return Icons.auto_awesome;
      case EquipmentSlot.none:
        return Icons.help_outline;
    }
  }
  
  /// Checks if an item can be equipped in a specific slot
  bool _canEquipItem(CardInstance? item, EquipmentSlot slot) {
    if (item == null) return false;
    
    // Check if the item's equipment slot matches the target slot
    if (item.card.equipmentSlot != slot) {
      // Special case: weapons can go in either weapon slot
      if (slot == EquipmentSlot.weapon1 || slot == EquipmentSlot.weapon2) {
        if (item.card.equipmentSlot != EquipmentSlot.weapon1 && 
            item.card.equipmentSlot != EquipmentSlot.weapon2) {
          return false;
        }
      }
      // Special case: skills can go in either skill slot
      else if (slot == EquipmentSlot.skill1 || slot == EquipmentSlot.skill2) {
        if (item.card.equipmentSlot != EquipmentSlot.skill1 && 
            item.card.equipmentSlot != EquipmentSlot.skill2) {
          return false;
        }
      } else {
        return false;
      }
    }
    
    // Check if character can equip this item
    return widget.character.canEquip(item);
  }
  
  /// Equips an item to a specific slot
  void _equipItem(CardInstance item, EquipmentSlot slot) {
    final characterProvider = Provider.of<CharacterProvider>(context, listen: false);
    characterProvider.equipItem(widget.character.id, item).then((_) {
      widget.onStatsChanged?.call();
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to equip item: $error')),
      );
    });
  }
  
  /// Moves an item to a specific inventory/stash slot
  void _moveItemToSlot(CardInstance item, int index, bool isStash) {
    final characterProvider = Provider.of<CharacterProvider>(context, listen: false);
    
    if (isStash) {
      characterProvider.moveItemToStash(widget.character.id, item.instanceId).then((_) {
        widget.onStatsChanged?.call();
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to move item to stash: $error')),
        );
      });
    } else {
      characterProvider.moveItemFromStash(widget.character.id, item.instanceId).then((_) {
        widget.onStatsChanged?.call();
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to move item from stash: $error')),
        );
      });
    }
  }
}