import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../providers/character_provider.dart';
import '../models/character_model.dart';
import '../models/card_model.dart';

class CharacterSheetContent extends StatefulWidget {
  const CharacterSheetContent({super.key});

  @override
  State<CharacterSheetContent> createState() => _CharacterSheetContentState();
}

class _CharacterSheetContentState extends State<CharacterSheetContent>
    with TickerProviderStateMixin {
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
    print('DEBUG: Building Character Sheet Content');
    return Consumer<CharacterProvider>(
      builder: (context, characterProvider, child) {
        final character = characterProvider.currentCharacter;
        
        if (character == null) {
          print('DEBUG: No character selected in Character Sheet');
          return const Center(
            child: Text(
              'No character selected',
              style: TextStyle(color: RealmOfValorTheme.textSecondary),
            ),
          );
        }

        print('DEBUG: Character Sheet loaded for: ${character.name}');
        return Column(
          children: [
            // Character Header
            _buildCharacterHeader(character),
            
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
                  Tab(text: 'Stats'),
                  Tab(text: 'Equipment'),
                  Tab(text: 'Skills'),
                ],
              ),
            ),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildStatsTab(character),
                  _buildEquipmentTab(character),
                  _buildSkillsTab(character),
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
        color: RealmOfValorTheme.surfaceDark,
        border: Border(
          bottom: BorderSide(color: RealmOfValorTheme.primaryLight),
        ),
      ),
      child: Row(
        children: [
          // Character Avatar
          CircleAvatar(
            radius: 30,
            backgroundColor: RealmOfValorTheme.accentGold,
            child: Text(
              character.name.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Character Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  character.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: RealmOfValorTheme.textPrimary,
                  ),
                ),
                Text(
                  'Level ${character.level} ${_getClassName(character.characterClass)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: RealmOfValorTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: character.experience / (character.level * 1000),
                  backgroundColor: RealmOfValorTheme.surfaceMedium,
                  valueColor: const AlwaysStoppedAnimation<Color>(RealmOfValorTheme.accentGold),
                ),
                const SizedBox(height: 4),
                Text(
                  'XP: ${character.experience} / ${character.level * 1000}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: RealmOfValorTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab(GameCharacter character) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Core Stats
          _buildStatSection('Core Stats', [
            _buildStatRow('Strength', '${character.baseStrength + character.allocatedStrength}', Icons.fitness_center),
            _buildStatRow('Dexterity', '${character.baseDexterity + character.allocatedDexterity}', Icons.speed),
            _buildStatRow('Vitality', '${character.baseVitality + character.allocatedVitality}', Icons.favorite),
            _buildStatRow('Energy', '${character.baseEnergy + character.allocatedEnergy}', Icons.auto_awesome),
          ]),
          
          const SizedBox(height: 24),
          
          // Combat Stats
          _buildStatSection('Combat Stats', [
            _buildStatRow('Health', '${character.maxHealth}', Icons.favorite_border),
            _buildStatRow('Mana', '${character.maxMana}', Icons.auto_awesome_outlined),
            _buildStatRow('Attack', '${character.attack}', Icons.flash_on),
            _buildStatRow('Defense', '${character.defense}', Icons.shield),
          ]),
          
          const SizedBox(height: 24),
          
          // Resources
          _buildStatSection('Resources', [
            _buildStatRow('Gold', '${character.characterData['gold'] ?? 0}', Icons.monetization_on),
            _buildStatRow('Stat Points', '${character.availableStatPoints}', Icons.fitness_center),
            _buildStatRow('Skill Points', '${character.availableSkillPoints}', Icons.stars),
          ]),
        ],
      ),
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

  Widget _buildSkillsTab(GameCharacter character) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Skills',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Available Skill Points
          if (character.availableSkillPoints > 0)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RealmOfValorTheme.accentGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: RealmOfValorTheme.accentGold),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.stars,
                    color: RealmOfValorTheme.accentGold,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${character.availableSkillPoints} skill points available',
                    style: const TextStyle(
                      color: RealmOfValorTheme.accentGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Skills List (placeholder)
          const Center(
            child: Text(
              'Skills will be implemented here',
              style: TextStyle(color: RealmOfValorTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatSection(String title, List<Widget> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: RealmOfValorTheme.accentGold,
          ),
        ),
        const SizedBox(height: 12),
        ...stats,
      ],
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: RealmOfValorTheme.primaryLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: RealmOfValorTheme.accentGold,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: RealmOfValorTheme.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: RealmOfValorTheme.accentGold,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
            style: TextStyle(
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
        return RealmOfValorTheme.rarityMythic; // Use mythic color for holographic
      case CardRarity.firstEdition:
        return RealmOfValorTheme.rarityLegendary; // Use legendary color for first edition
      case CardRarity.limitedEdition:
        return RealmOfValorTheme.rarityEpic; // Use epic color for limited edition
    }
  }

  String _getClassName(CharacterClass characterClass) {
    switch (characterClass) {
      case CharacterClass.paladin:
        return 'Paladin';
      case CharacterClass.barbarian:
        return 'Barbarian';
      case CharacterClass.necromancer:
        return 'Necromancer';
      case CharacterClass.sorceress:
        return 'Sorceress';
      case CharacterClass.amazon:
        return 'Amazon';
      case CharacterClass.assassin:
        return 'Assassin';
      case CharacterClass.druid:
        return 'Druid';
      case CharacterClass.monk:
        return 'Monk';
      case CharacterClass.crusader:
        return 'Crusader';
      case CharacterClass.witchDoctor:
        return 'Witch Doctor';
      case CharacterClass.wizard:
        return 'Wizard';
      case CharacterClass.demonHunter:
        return 'Demon Hunter';
    }
  }
} 