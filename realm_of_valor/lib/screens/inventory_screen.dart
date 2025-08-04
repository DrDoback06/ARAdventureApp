import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../providers/character_provider.dart';
import '../services/audio_service.dart';
import '../models/character_model.dart';
import '../models/card_model.dart';
import '../widgets/card_widget.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  CardInstance? _draggedItem;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Start with Equipment tab open by default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tabController.animateTo(0); // Equipment tab
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RealmOfValorTheme.surfaceDark,
      appBar: AppBar(
        title: const Text('Inventory'),
        backgroundColor: RealmOfValorTheme.surfaceDark,
        foregroundColor: RealmOfValorTheme.textPrimary,
        bottom: TabBar(
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
      body: Consumer<CharacterProvider>(
        builder: (context, characterProvider, child) {
          final character = characterProvider.currentCharacter;
          if (character == null) {
            return const Center(
              child: Text(
                'No character selected',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildEquipmentTab(character, characterProvider),
              _buildInventoryTab(character, characterProvider),
              _buildStashTab(character, characterProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEquipmentTab(GameCharacter character, CharacterProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Equipment',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildEquipmentSection('Weapons', [
                    _buildEquipmentSlot(EquipmentSlot.weapon1, character, provider, 'Weapon 1'),
                    _buildEquipmentSlot(EquipmentSlot.weapon2, character, provider, 'Weapon 2'),
                  ]),
                  const SizedBox(height: 16),
                  _buildEquipmentSection('Armor', [
                    _buildEquipmentSlot(EquipmentSlot.helmet, character, provider, 'Helmet'),
                    _buildEquipmentSlot(EquipmentSlot.armor, character, provider, 'Armor'),
                    _buildEquipmentSlot(EquipmentSlot.gloves, character, provider, 'Gloves'),
                    _buildEquipmentSlot(EquipmentSlot.boots, character, provider, 'Boots'),
                  ]),
                  const SizedBox(height: 16),
                  _buildEquipmentSection('Accessories', [
                    _buildEquipmentSlot(EquipmentSlot.amulet, character, provider, 'Amulet'),
                    _buildEquipmentSlot(EquipmentSlot.ring1, character, provider, 'Ring 1'),
                    _buildEquipmentSlot(EquipmentSlot.ring2, character, provider, 'Ring 2'),
                    _buildEquipmentSlot(EquipmentSlot.belt, character, provider, 'Belt'),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentSection(String title, List<Widget> slots) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RealmOfValorTheme.accentGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.accentGold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: slots,
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentSlot(EquipmentSlot slot, GameCharacter character, CharacterProvider provider, String label) {
    final equippedItem = character.equipment.getItemInSlot(slot);
    
    return DragTarget<CardInstance>(
      onAccept: (item) {
        AudioService.instance.playSound(AudioType.buttonClick);
        _equipItem(item, slot);
      },
      onWillAccept: (item) => _canEquipItem(item, slot),
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 80,
          height: 100,
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty 
                ? RealmOfValorTheme.accentGold.withOpacity(0.3)
                : RealmOfValorTheme.surfaceDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: candidateData.isNotEmpty 
                  ? RealmOfValorTheme.accentGold
                  : RealmOfValorTheme.accentGold.withOpacity(0.5),
              width: candidateData.isNotEmpty ? 2 : 1,
            ),
          ),
          child: equippedItem != null
              ? Draggable<CardInstance>(
                  data: equippedItem,
                  feedback: Material(
                    color: Colors.transparent,
                    child: CardWidget(
                      cardInstance: equippedItem,
                      width: 80,
                      height: 100,
                      showTooltip: false,
                    ),
                  ),
                  childWhenDragging: Container(
                    decoration: BoxDecoration(
                      color: RealmOfValorTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: RealmOfValorTheme.accentGold.withOpacity(0.5)),
                    ),
                    child: const Icon(
                      Icons.drag_indicator,
                      color: RealmOfValorTheme.textSecondary,
                    ),
                  ),
                  child: CardWidget(
                    cardInstance: equippedItem,
                    width: 80,
                    height: 100,
                    onTap: () => _showItemActions(context, equippedItem, provider),
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getSlotIcon(slot),
                      color: RealmOfValorTheme.textSecondary,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        color: RealmOfValorTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildInventoryTab(GameCharacter character, CharacterProvider provider) {
    final inventory = character.inventory;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Inventory',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: RealmOfValorTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${inventory.length}/40',
                style: TextStyle(
                  fontSize: 14,
                  color: RealmOfValorTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                childAspectRatio: 0.75,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: 40,
              itemBuilder: (context, index) {
                if (index < inventory.length) {
                  final item = inventory[index];
                  return Draggable<CardInstance>(
                    data: item,
                    feedback: Material(
                      color: Colors.transparent,
                      child: CardWidget(
                        cardInstance: item,
                        width: 80,
                        height: 100,
                        showTooltip: false,
                      ),
                    ),
                    childWhenDragging: Container(
                      decoration: BoxDecoration(
                        color: RealmOfValorTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: RealmOfValorTheme.accentGold.withOpacity(0.5)),
                      ),
                      child: const Icon(
                        Icons.drag_indicator,
                        color: RealmOfValorTheme.textSecondary,
                      ),
                    ),
                    child: CardWidget(
                      cardInstance: item,
                      width: 80,
                      height: 100,
                      onTap: () => _showItemActions(context, item, provider),
                    ),
                  );
                } else {
                  return DragTarget<CardInstance>(
                    onAccept: (item) {
                      _addToStash(item);
                    },
                    builder: (context, candidateData, rejectedData) {
                      return Container(
                        decoration: BoxDecoration(
                          color: candidateData.isNotEmpty 
                              ? RealmOfValorTheme.accentGold.withOpacity(0.3)
                              : RealmOfValorTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: candidateData.isNotEmpty 
                                ? RealmOfValorTheme.accentGold
                                : RealmOfValorTheme.accentGold.withOpacity(0.3),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStashTab(GameCharacter character, CharacterProvider provider) {
    final stash = character.characterData['stash'] as List<dynamic>? ?? [];
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Stash',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: RealmOfValorTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${stash.length}/100',
                style: TextStyle(
                  fontSize: 14,
                  color: RealmOfValorTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 10,
                childAspectRatio: 0.75,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: 100,
              itemBuilder: (context, index) {
                if (index < stash.length) {
                  final item = CardInstance.fromJson(stash[index]);
                  return Draggable<CardInstance>(
                    data: item,
                    feedback: Material(
                      color: Colors.transparent,
                      child: CardWidget(
                        cardInstance: item,
                        width: 80,
                        height: 100,
                        showTooltip: false,
                      ),
                    ),
                    childWhenDragging: Container(
                      decoration: BoxDecoration(
                        color: RealmOfValorTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: RealmOfValorTheme.accentGold.withOpacity(0.5)),
                      ),
                      child: const Icon(
                        Icons.drag_indicator,
                        color: RealmOfValorTheme.textSecondary,
                      ),
                    ),
                    child: CardWidget(
                      cardInstance: item,
                      width: 80,
                      height: 100,
                      onTap: () => _showItemActions(context, item, provider),
                    ),
                  );
                } else {
                  return DragTarget<CardInstance>(
                    onAccept: (item) {
                      _addToStash(item);
                    },
                    builder: (context, candidateData, rejectedData) {
                      return Container(
                        decoration: BoxDecoration(
                          color: candidateData.isNotEmpty 
                              ? RealmOfValorTheme.accentGold.withOpacity(0.3)
                              : RealmOfValorTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: candidateData.isNotEmpty 
                                ? RealmOfValorTheme.accentGold
                                : RealmOfValorTheme.accentGold.withOpacity(0.3),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

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
      } else {
        return false;
      }
    }
    
    return true;
  }

  void _showItemActions(BuildContext context, CardInstance item, CharacterProvider provider) {
    AudioService.instance.playSound(AudioType.buttonClick);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RealmOfValorTheme.surfaceMedium,
        title: Text(
          item.card.name,
          style: TextStyle(
            color: RealmOfValorTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Type: ${item.card.type.name}',
              style: TextStyle(color: RealmOfValorTheme.textSecondary),
            ),
            if (item.card.equipmentSlot != EquipmentSlot.none)
              Text(
                'Slot: ${item.card.equipmentSlot.name}',
                style: TextStyle(color: RealmOfValorTheme.textSecondary),
              ),
            if (item.card.attack > 0)
              Text(
                'Attack: ${item.card.attack}',
                style: TextStyle(color: RealmOfValorTheme.textSecondary),
              ),
            if (item.card.defense > 0)
              Text(
                'Defense: ${item.card.defense}',
                style: TextStyle(color: RealmOfValorTheme.textSecondary),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: RealmOfValorTheme.accentGold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement item use/equip logic
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Item action coming soon!'),
                  backgroundColor: RealmOfValorTheme.accentGold,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RealmOfValorTheme.accentGold,
              foregroundColor: Colors.white,
            ),
            child: const Text('Use'),
          ),
        ],
      ),
    );
  }

  void _equipItem(CardInstance item, EquipmentSlot slot) {
    AudioService.instance.playSound(AudioType.buttonClick);
    
    final characterProvider = context.read<CharacterProvider>();
    final character = characterProvider.currentCharacter;
    
    if (character == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a character first')),
      );
      return;
    }

    // Check if item can be equipped in this slot
    if (item.card.equipmentSlot != slot) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('This item cannot be equipped in the ${slot.name} slot'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check character level requirement
    if (character.level < (item.card.levelRequirement ?? 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Character level ${character.level} is too low. Requires level ${item.card.levelRequirement ?? 0}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Equip the item
    characterProvider.equipItem(item).then((success) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Equipped ${item.card.name} in ${slot.name} slot'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to equip ${item.card.name}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        // Refresh the UI
      });
    });
  }

  void _unequipItem(EquipmentSlot slot) {
    AudioService.instance.playSound(AudioType.buttonClick);
    
    final characterProvider = context.read<CharacterProvider>();
    final character = characterProvider.currentCharacter;
    
    if (character == null) return;

    characterProvider.unequipItem(slot).then((success) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unequipped item from ${slot.name} slot'),
            backgroundColor: Colors.blue,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unequip item from ${slot.name} slot'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        // Refresh the UI
      });
    });
  }

  void _moveInventoryItem(CardInstance item, int newIndex) {
    AudioService.instance.playSound(AudioType.buttonClick);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Moved ${item.card.name} to position ${newIndex + 1}'),
        backgroundColor: RealmOfValorTheme.accentGold,
      ),
    );
    
    setState(() {
      // Refresh the UI
    });
  }

  void _addToStash(CardInstance item) {
    AudioService.instance.playSound(AudioType.buttonClick);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${item.card.name} to stash'),
        backgroundColor: Colors.green,
      ),
    );
    
    setState(() {
      // Refresh the UI
    });
  }

  void _removeFromStash(CardInstance item) {
    AudioService.instance.playSound(AudioType.buttonClick);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${item.card.name} from stash'),
        backgroundColor: Colors.orange,
      ),
    );
    
    setState(() {
      // Refresh the UI
    });
  }

  IconData _getSlotIcon(EquipmentSlot slot) {
    switch (slot) {
      case EquipmentSlot.weapon1:
      case EquipmentSlot.weapon2:
        return Icons.sports_martial_arts;
      case EquipmentSlot.helmet:
        return Icons.face;
      case EquipmentSlot.armor:
        return Icons.person;
      case EquipmentSlot.gloves:
        return Icons.accessibility;
      case EquipmentSlot.boots:
        return Icons.directions_walk;
      case EquipmentSlot.amulet:
        return Icons.diamond;
      case EquipmentSlot.ring1:
      case EquipmentSlot.ring2:
        return Icons.circle;
      case EquipmentSlot.belt:
        return Icons.straighten;
      default:
        return Icons.inventory;
    }
  }
} 