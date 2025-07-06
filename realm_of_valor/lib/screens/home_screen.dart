import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/character_model.dart';
import '../models/card_model.dart';
import '../providers/character_provider.dart';
import '../constants/theme.dart';
import '../widgets/inventory_widget.dart';
import 'card_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Realm of Valor'),
        actions: [
          Consumer<CharacterProvider>(
            builder: (context, characterProvider, child) {
              return PopupMenuButton<String>(
                onSelected: (value) => _handleAppBarAction(value, characterProvider),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'new_character', child: Text('New Character')),
                  const PopupMenuItem(value: 'switch_character', child: Text('Switch Character')),
                  const PopupMenuItem(value: 'settings', child: Text('Settings')),
                ],
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardTab(),
          const InventoryWidget(),
          _buildCardEditorTab(),
          _buildMapTab(),
          _buildSettingsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: 'Card Editor',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return Consumer<CharacterProvider>(
      builder: (context, characterProvider, child) {
        final character = characterProvider.currentCharacter;
        
        if (character == null) {
          return _buildNoCharacterView(characterProvider);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Character Overview Card
              _buildCharacterOverviewCard(character),
              
              const SizedBox(height: 16),
              
              // Quick Actions
              _buildQuickActionsCard(characterProvider),
              
              const SizedBox(height: 16),
              
              // Stats Overview
              _buildStatsOverviewCard(character),
              
              const SizedBox(height: 16),
              
              // Recent Activity
              _buildRecentActivityCard(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoCharacterView(CharacterProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person_add,
            size: 64,
            color: RealmOfValorTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Character Selected',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a new character to start your adventure',
            style: TextStyle(
              fontSize: 16,
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateCharacterDialog(provider),
            icon: const Icon(Icons.add),
            label: const Text('Create Character'),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterOverviewCard(GameCharacter character) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: RealmOfValorTheme.accentGold,
                  child: Text(
                    character.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: RealmOfValorTheme.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        character.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: RealmOfValorTheme.accentGold,
                        ),
                      ),
                      Text(
                        'Level ${character.level} ${character.characterClass.name.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: RealmOfValorTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Health: ${character.maxHealth}',
                      style: const TextStyle(
                        color: RealmOfValorTheme.healthRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Mana: ${character.maxMana}',
                      style: const TextStyle(
                        color: RealmOfValorTheme.manaBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Experience Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Experience',
                      style: TextStyle(
                        color: RealmOfValorTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${character.experience} / ${character.experienceToNext}',
                      style: const TextStyle(
                        color: RealmOfValorTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: character.experience / character.experienceToNext,
                  backgroundColor: RealmOfValorTheme.surfaceLight,
                  valueColor: const AlwaysStoppedAnimation(RealmOfValorTheme.experienceGreen),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(CharacterProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: RealmOfValorTheme.accentGold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    'Add Experience',
                    Icons.trending_up,
                    () => _showAddExperienceDialog(provider),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionButton(
                    'Add Item',
                    Icons.add_box,
                    () => _showAddItemDialog(provider),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionButton(
                    'Scan QR',
                    Icons.qr_code_scanner,
                    () => _scanQRCode(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverviewCard(GameCharacter character) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Character Stats',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: RealmOfValorTheme.accentGold,
                  ),
                ),
                if (character.availableStatPoints > 0)
                  Text(
                    'Available Points: ${character.availableStatPoints}',
                    style: const TextStyle(
                      color: RealmOfValorTheme.experienceGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatColumn('Strength', character.totalStrength)),
                Expanded(child: _buildStatColumn('Dexterity', character.totalDexterity)),
                Expanded(child: _buildStatColumn('Vitality', character.totalVitality)),
                Expanded(child: _buildStatColumn('Energy', character.totalEnergy)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatColumn('Attack', character.attackRating)),
                Expanded(child: _buildStatColumn('Defense', character.defense)),
                Expanded(child: _buildStatColumn('Inventory', '${character.inventory.length}/40')),
                Expanded(child: _buildStatColumn('Stash', '${character.stash.length}/48')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, dynamic value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: RealmOfValorTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: RealmOfValorTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: RealmOfValorTheme.accentGold,
              ),
            ),
            const SizedBox(height: 16),
            _buildActivityItem('Character created', Icons.person_add, '2 hours ago'),
            _buildActivityItem('Equipped Iron Sword', Icons.sports_martial_arts, '1 hour ago'),
            _buildActivityItem('Gained 500 XP', Icons.trending_up, '30 minutes ago'),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String activity, IconData icon, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: RealmOfValorTheme.accentGold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              activity,
              style: const TextStyle(color: RealmOfValorTheme.textPrimary),
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              color: RealmOfValorTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardEditorTab() {
    return const CardEditorScreen();
  }

  Widget _buildMapTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map,
            size: 64,
            color: RealmOfValorTheme.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'Map Feature',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Coming Soon!',
            style: TextStyle(
              fontSize: 16,
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.settings,
            size: 64,
            color: RealmOfValorTheme.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Coming Soon!',
            style: TextStyle(
              fontSize: 16,
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _handleAppBarAction(String action, CharacterProvider provider) {
    switch (action) {
      case 'new_character':
        _showCreateCharacterDialog(provider);
        break;
      case 'switch_character':
        _showCharacterSwitchDialog(provider);
        break;
      case 'settings':
        setState(() => _selectedIndex = 4);
        break;
    }
  }

  void _showCreateCharacterDialog(CharacterProvider provider) {
    final nameController = TextEditingController();
    CharacterClass selectedClass = CharacterClass.paladin;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New Character'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Character Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<CharacterClass>(
                value: selectedClass,
                decoration: const InputDecoration(
                  labelText: 'Class',
                  border: OutlineInputBorder(),
                ),
                items: CharacterClass.values.map((characterClass) {
                  return DropdownMenuItem(
                    value: characterClass,
                    child: Text(characterClass.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) => setState(() => selectedClass = value!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  final character = GameCharacter(
                    name: nameController.text.trim(),
                    characterClass: selectedClass,
                    availableStatPoints: 5,
                    availableSkillPoints: 1,
                  );
                  provider.createCharacter(character);
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCharacterSwitchDialog(CharacterProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch Character'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: provider.allCharacters.length,
            itemBuilder: (context, index) {
              final character = provider.allCharacters[index];
              final isSelected = character.id == provider.currentCharacter?.id;
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isSelected 
                      ? RealmOfValorTheme.accentGold 
                      : RealmOfValorTheme.surfaceLight,
                  child: Text(
                    character.name[0].toUpperCase(),
                    style: TextStyle(
                      color: isSelected 
                          ? RealmOfValorTheme.primaryDark 
                          : RealmOfValorTheme.textPrimary,
                    ),
                  ),
                ),
                title: Text(character.name),
                subtitle: Text('Level ${character.level} ${character.characterClass.name}'),
                trailing: isSelected ? const Icon(Icons.check, color: RealmOfValorTheme.accentGold) : null,
                onTap: () {
                  provider.setCurrentCharacter(character.id);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAddExperienceDialog(CharacterProvider provider) {
    final expController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Experience'),
        content: TextField(
          controller: expController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Experience Points',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final exp = int.tryParse(expController.text);
              if (exp != null && exp > 0) {
                provider.addExperience(exp);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added $exp experience points!')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(CharacterProvider provider) {
    // Implementation for adding items dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add Item feature coming soon!')),
    );
  }

  void _scanQRCode() {
    // Implementation for QR code scanning
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR Scanner feature coming soon!')),
    );
  }
}