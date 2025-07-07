import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card_model.dart';
import '../models/character_model.dart';
import '../providers/character_provider.dart';
import '../constants/theme.dart';
import 'card_widget.dart';

class InventoryWidget extends StatefulWidget {
  const InventoryWidget({super.key});

  @override
  State<InventoryWidget> createState() => _InventoryWidgetState();
}

class _InventoryWidgetState extends State<InventoryWidget> with TickerProviderStateMixin {
  late TabController _tabController;

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
    return Consumer<CharacterProvider>(
      builder: (context, characterProvider, child) {
        final character = characterProvider.currentCharacter;
        
        if (character == null) {
          return const Center(
            child: Text(
              'No character selected',
              style: TextStyle(color: RealmOfValorTheme.textSecondary),
            ),
          );
        }

        return Column(
          children: [
            // Character Stats Header
            _buildCharacterHeader(character),
            
            // Tab Bar
            Container(
              decoration: const BoxDecoration(
                color: RealmOfValorTheme.surfaceMedium,
                border: Border(
                  bottom: BorderSide(color: RealmOfValorTheme.primaryLight),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Inventory', icon: Icon(Icons.inventory)),
                  Tab(text: 'Stash', icon: Icon(Icons.storage)),
                  Tab(text: 'Skills', icon: Icon(Icons.psychology)),
                ],
              ),
            ),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildInventoryTab(character, characterProvider),
                  _buildStashTab(character, characterProvider),
                  _buildSkillsTab(character, characterProvider),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCharacterHeader(GameCharacter character) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        border: Border(
          bottom: BorderSide(color: RealmOfValorTheme.primaryLight),
        ),
      ),
      child: Row(
        children: [
          // Character Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  character.name,
                  style: const TextStyle(
                    color: RealmOfValorTheme.accentGold,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Level ${character.level} ${character.characterClass.name.toUpperCase()}',
                  style: const TextStyle(
                    color: RealmOfValorTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Stats
          Row(
            children: [
              _buildStatColumn('STR', character.totalStrength),
              const SizedBox(width: 16),
              _buildStatColumn('DEX', character.totalDexterity),
              const SizedBox(width: 16),
              _buildStatColumn('VIT', character.totalVitality),
              const SizedBox(width: 16),
              _buildStatColumn('ENE', character.totalEnergy),
            ],
          ),
          
          const SizedBox(width: 16),
          
          // Health and Mana
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite, color: RealmOfValorTheme.healthRed, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    character.maxHealth.toString(),
                    style: const TextStyle(
                      color: RealmOfValorTheme.healthRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.water_drop, color: RealmOfValorTheme.manaBlue, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    character.maxMana.toString(),
                    style: const TextStyle(
                      color: RealmOfValorTheme.manaBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, int value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: RealmOfValorTheme.textSecondary,
            fontSize: 12,
          ),
        ),
        Text(
          value.toString(),
          style: const TextStyle(
            color: RealmOfValorTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryTab(GameCharacter character, CharacterProvider provider) {
    return Row(
      children: [
        // Equipment Panel
        Container(
          width: 300,
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: RealmOfValorTheme.surfaceDark,
            border: Border(
              right: BorderSide(color: RealmOfValorTheme.primaryLight),
            ),
          ),
          child: _buildEquipmentPanel(character, provider),
        ),
        
        // Inventory Panel
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inventory',
                  style: TextStyle(
                    color: RealmOfValorTheme.accentGold,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildInventoryGrid(character.inventory, provider),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentPanel(GameCharacter character, CharacterProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Equipment',
          style: TextStyle(
            color: RealmOfValorTheme.accentGold,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Equipment Layout
        Expanded(
          child: Column(
            children: [
              // Top Row - Helmet
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildEquipmentSlot(
                    EquipmentSlot.helmet,
                    character.equipment.helmet,
                    provider,
                    'Helmet',
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Middle Row - Weapon1, Armor, Weapon2
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildEquipmentSlot(
                    EquipmentSlot.weapon1,
                    character.equipment.weapon1,
                    provider,
                    'Weapon 1',
                  ),
                  _buildEquipmentSlot(
                    EquipmentSlot.armor,
                    character.equipment.armor,
                    provider,
                    'Armor',
                  ),
                  _buildEquipmentSlot(
                    EquipmentSlot.weapon2,
                    character.equipment.weapon2,
                    provider,
                    'Weapon 2',
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Bottom Row - Gloves, Belt, Boots
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildEquipmentSlot(
                    EquipmentSlot.gloves,
                    character.equipment.gloves,
                    provider,
                    'Gloves',
                  ),
                  _buildEquipmentSlot(
                    EquipmentSlot.belt,
                    character.equipment.belt,
                    provider,
                    'Belt',
                  ),
                  _buildEquipmentSlot(
                    EquipmentSlot.boots,
                    character.equipment.boots,
                    provider,
                    'Boots',
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Accessories Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildEquipmentSlot(
                    EquipmentSlot.ring1,
                    character.equipment.ring1,
                    provider,
                    'Ring 1',
                  ),
                  _buildEquipmentSlot(
                    EquipmentSlot.amulet,
                    character.equipment.amulet,
                    provider,
                    'Amulet',
                  ),
                  _buildEquipmentSlot(
                    EquipmentSlot.ring2,
                    character.equipment.ring2,
                    provider,
                    'Ring 2',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentSlot(
    EquipmentSlot slot,
    CardInstance? equippedItem,
    CharacterProvider provider,
    String label,
  ) {
    return DragTarget<CardInstance>(
      onAcceptWithDetails: (details) {
        final cardInstance = details.data;
        if (cardInstance.card.equipmentSlot == slot) {
          provider.equipItem(cardInstance);
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 80,
          height: 80,
          decoration: RealmOfValorTheme.equipmentSlotDecoration,
          child: equippedItem != null
              ? Draggable<CardInstance>(
                  data: equippedItem,
                  feedback: Material(
                    color: Colors.transparent,
                    child: CardWidget(
                      cardInstance: equippedItem,
                      width: 80,
                      height: 80,
                      showTooltip: false,
                    ),
                  ),
                  childWhenDragging: Container(
                    decoration: RealmOfValorTheme.equipmentSlotDecoration,
                    child: const Icon(
                      Icons.drag_indicator,
                      color: RealmOfValorTheme.textSecondary,
                    ),
                  ),
                  onDragCompleted: () {
                    // Handle drag completion if needed
                  },
                  child: CardWidget(
                    cardInstance: equippedItem,
                    width: 80,
                    height: 80,
                    onTap: () => provider.unequipItem(slot),
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
                      style: const TextStyle(
                        color: RealmOfValorTheme.textSecondary,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildInventoryGrid(List<CardInstance> items, CharacterProvider provider) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        childAspectRatio: 0.75,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: 40, // 8x5 grid
      itemBuilder: (context, index) {
        if (index < items.length) {
          final item = items[index];
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
              decoration: RealmOfValorTheme.inventorySlotDecoration,
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
            onAcceptWithDetails: (details) {
              // Handle inventory reordering if needed
            },
            builder: (context, candidateData, rejectedData) {
              return Container(
                decoration: RealmOfValorTheme.inventorySlotDecoration,
                child: candidateData.isNotEmpty
                    ? Container(
                        decoration: BoxDecoration(
                          color: RealmOfValorTheme.accentGold.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      )
                    : null,
              );
            },
          );
        }
      },
    );
  }

  Widget _buildStashTab(GameCharacter character, CharacterProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stash',
            style: TextStyle(
              color: RealmOfValorTheme.accentGold,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _buildStashGrid(character.stash, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildStashGrid(List<CardInstance> items, CharacterProvider provider) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        childAspectRatio: 0.75,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: 48, // 8x6 grid
      itemBuilder: (context, index) {
        if (index < items.length) {
          final item = items[index];
          return CardWidget(
            cardInstance: item,
            width: 80,
            height: 100,
            onTap: () => _showStashItemActions(context, item, provider),
          );
        } else {
          return Container(
            decoration: RealmOfValorTheme.inventorySlotDecoration,
          );
        }
      },
    );
  }

  Widget _buildSkillsTab(GameCharacter character, CharacterProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Skills',
                style: TextStyle(
                  color: RealmOfValorTheme.accentGold,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Available Points: ${character.availableSkillPoints}',
                style: const TextStyle(
                  color: RealmOfValorTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Skill Slots (Belt)
          Container(
            height: 80,
            padding: const EdgeInsets.all(8),
            decoration: RealmOfValorTheme.cardDecoration,
            child: Row(
              children: List.generate(8, (index) {
                final skillSlot = index < character.skillSlots.length
                    ? character.skillSlots[index]
                    : null;
                
                return Container(
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: RealmOfValorTheme.inventorySlotDecoration,
                  child: skillSlot != null
                      ? CardWidget(
                          cardInstance: skillSlot,
                          width: 60,
                          height: 60,
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.psychology,
                              color: RealmOfValorTheme.textSecondary,
                              size: 20,
                            ),
                            Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: RealmOfValorTheme.textSecondary,
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                );
              }),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Skills List
          Expanded(
            child: ListView.builder(
              itemCount: character.skills.length,
              itemBuilder: (context, index) {
                final skill = character.skills[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.psychology, color: RealmOfValorTheme.accentGold),
                    title: Text(
                      skill.name,
                      style: const TextStyle(color: RealmOfValorTheme.textPrimary),
                    ),
                    subtitle: Text(
                      skill.description,
                      style: const TextStyle(color: RealmOfValorTheme.textSecondary),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Lv.${skill.level}/${skill.maxLevel}',
                          style: const TextStyle(color: RealmOfValorTheme.textSecondary),
                        ),
                        const SizedBox(width: 8),
                        if (skill.level < skill.maxLevel && character.availableSkillPoints > 0)
                          IconButton(
                            icon: const Icon(Icons.add, color: RealmOfValorTheme.accentGold),
                            onPressed: () => provider.upgradeSkill(skill.id),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSlotIcon(EquipmentSlot slot) {
    switch (slot) {
      case EquipmentSlot.helmet:
        return Icons.sports_motorsports;
      case EquipmentSlot.armor:
        return Icons.shield;
      case EquipmentSlot.weapon1:
      case EquipmentSlot.weapon2:
        return Icons.sports_martial_arts;
      case EquipmentSlot.gloves:
        return Icons.back_hand;
      case EquipmentSlot.boots:
        return Icons.directions_walk;
      case EquipmentSlot.belt:
        return Icons.accessibility_new;
      case EquipmentSlot.ring1:
      case EquipmentSlot.ring2:
        return Icons.circle;
      case EquipmentSlot.amulet:
        return Icons.diamond;
      default:
        return Icons.category;
    }
  }

  void _showItemActions(BuildContext context, CardInstance item, CharacterProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info, color: RealmOfValorTheme.accentGold),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                // Show card details dialog
              },
            ),
            if (item.card.equipmentSlot != EquipmentSlot.none)
              ListTile(
                leading: const Icon(Icons.check_circle, color: RealmOfValorTheme.experienceGreen),
                title: const Text('Equip'),
                onTap: () {
                  Navigator.pop(context);
                  provider.equipItem(item);
                },
              ),
            ListTile(
              leading: const Icon(Icons.storage, color: RealmOfValorTheme.manaBlue),
              title: const Text('Move to Stash'),
              onTap: () {
                Navigator.pop(context);
                provider.moveToStash(item.instanceId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: RealmOfValorTheme.healthRed),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                provider.removeFromInventory(item.instanceId);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStashItemActions(BuildContext context, CardInstance item, CharacterProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info, color: RealmOfValorTheme.accentGold),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                // Show card details dialog
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory, color: RealmOfValorTheme.experienceGreen),
              title: const Text('Move to Inventory'),
              onTap: () {
                Navigator.pop(context);
                provider.moveFromStash(item.instanceId);
              },
            ),
          ],
        ),
      ),
    );
  }
}