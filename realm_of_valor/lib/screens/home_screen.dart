import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/character_model.dart';
import '../models/card_model.dart';
import '../providers/character_provider.dart';
import '../services/card_service.dart';
import '../constants/theme.dart';
import '../widgets/inventory_widget.dart';
import 'card_editor_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: RealmOfValorTheme.experienceGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Points: ${character.availableStatPoints}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Primary Stats with allocation buttons
            if (character.availableStatPoints > 0) ...[
              _buildStatRowWithButton('Strength', character.allocatedStrength, character.totalStrength, 'strength'),
              const SizedBox(height: 8),
              _buildStatRowWithButton('Dexterity', character.allocatedDexterity, character.totalDexterity, 'dexterity'),
              const SizedBox(height: 8),
              _buildStatRowWithButton('Vitality', character.allocatedVitality, character.totalVitality, 'vitality'),
              const SizedBox(height: 8),
              _buildStatRowWithButton('Energy', character.allocatedEnergy, character.totalEnergy, 'energy'),
            ] else ...[
              Row(
                children: [
                  Expanded(child: _buildStatColumn('Strength', character.totalStrength)),
                  Expanded(child: _buildStatColumn('Dexterity', character.totalDexterity)),
                  Expanded(child: _buildStatColumn('Vitality', character.totalVitality)),
                  Expanded(child: _buildStatColumn('Energy', character.totalEnergy)),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Derived Stats
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

  Widget _buildStatRowWithButton(String statName, int baseValue, int totalValue, String statKey) {
    final equipmentBonus = totalValue - baseValue;
    
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            statName,
            style: const TextStyle(
              color: RealmOfValorTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Text(
                baseValue.toString(),
                style: const TextStyle(
                  color: RealmOfValorTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (equipmentBonus > 0) ...[
                const Text(
                  ' + ',
                  style: TextStyle(color: RealmOfValorTheme.experienceGreen),
                ),
                Text(
                  equipmentBonus.toString(),
                  style: const TextStyle(
                    color: RealmOfValorTheme.experienceGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            '= $totalValue',
            style: const TextStyle(
              color: RealmOfValorTheme.accentGold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: () => _allocateStatPoint(statKey),
          icon: const Icon(Icons.add_circle, color: RealmOfValorTheme.accentGold),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

  void _allocateStatPoint(String statName) {
    final characterProvider = context.read<CharacterProvider>();
    characterProvider.allocateStatPoint(statName).then((success) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Allocated 1 point to ${statName.toUpperCase()}!'),
            backgroundColor: RealmOfValorTheme.experienceGreen,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    });
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Adventure Map',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.accentGold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Map Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.explore, color: RealmOfValorTheme.accentGold, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Explore the Realm',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: RealmOfValorTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Consumer<CharacterProvider>(
                          builder: (context, provider, child) {
                            final character = provider.currentCharacter;
                            return Text(
                              character != null 
                                  ? 'Current Location: Adventure Town'
                                  : 'Select a character to explore',
                              style: const TextStyle(
                                color: RealmOfValorTheme.textSecondary,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Available Adventures
          Expanded(
            child: Consumer<CharacterProvider>(
              builder: (context, characterProvider, child) {
                final character = characterProvider.currentCharacter;
                
                if (character == null) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 64,
                          color: RealmOfValorTheme.textSecondary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Create a character to explore!',
                          style: TextStyle(
                            fontSize: 18,
                            color: RealmOfValorTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView(
                  children: [
                    const Text(
                      'Available Adventures',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: RealmOfValorTheme.accentGold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildAdventureCard(
                      'Enchanted Forest',
                      'A mystical forest filled with magical creatures and hidden treasures.',
                      Icons.forest,
                      character.level >= 1,
                      'Level 1+',
                      () => _startAdventure('Enchanted Forest', character),
                    ),
                    
                    _buildAdventureCard(
                      'Crystal Caves',
                      'Deep underground caverns with rare crystals and dangerous monsters.',
                      Icons.terrain,
                      character.level >= 5,
                      'Level 5+',
                      () => _startAdventure('Crystal Caves', character),
                    ),
                    
                    _buildAdventureCard(
                      'Sky Temple',
                      'An ancient temple floating in the clouds, home to powerful artifacts.',
                      Icons.temple_buddhist,
                      character.level >= 10,
                      'Level 10+',
                      () => _startAdventure('Sky Temple', character),
                    ),
                    
                    _buildAdventureCard(
                      'Dragon\'s Lair',
                      'The ultimate challenge - face the ancient dragon and claim its hoard.',
                      Icons.whatshot,
                      character.level >= 20,
                      'Level 20+',
                      () => _startAdventure('Dragon\'s Lair', character),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // QR Code Adventure
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.qr_code_scanner,
                              size: 48,
                              color: RealmOfValorTheme.accentGold,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Scan for Adventure',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: RealmOfValorTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Scan QR codes in the real world to discover hidden adventures!',
                              style: TextStyle(
                                color: RealmOfValorTheme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _scanQRCode(),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Scan QR Code'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdventureCard(
    String name,
    String description,
    IconData icon,
    bool isUnlocked,
    String requirement,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isUnlocked ? RealmOfValorTheme.accentGold : RealmOfValorTheme.surfaceLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isUnlocked ? RealmOfValorTheme.primaryDark : RealmOfValorTheme.textSecondary,
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            color: isUnlocked ? RealmOfValorTheme.textPrimary : RealmOfValorTheme.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: TextStyle(
                color: isUnlocked ? RealmOfValorTheme.textSecondary : RealmOfValorTheme.textSecondary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              requirement,
              style: TextStyle(
                color: isUnlocked ? RealmOfValorTheme.experienceGreen : RealmOfValorTheme.healthRed,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: isUnlocked 
            ? const Icon(Icons.play_arrow, color: RealmOfValorTheme.accentGold)
            : const Icon(Icons.lock, color: RealmOfValorTheme.textSecondary),
        onTap: isUnlocked ? onTap : null,
      ),
    );
  }

  void _startAdventure(String adventureName, GameCharacter character) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start Adventure: $adventureName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.explore,
              size: 64,
              color: RealmOfValorTheme.accentGold,
            ),
            const SizedBox(height: 16),
            Text(
              'Are you ready to embark on this adventure with ${character.name}?',
              textAlign: TextAlign.center,
              style: const TextStyle(color: RealmOfValorTheme.textPrimary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Adventure features coming soon! For now, enjoy some bonus experience.',
              style: TextStyle(
                color: RealmOfValorTheme.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
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
              // Give some bonus experience for now
              final characterProvider = context.read<CharacterProvider>();
              characterProvider.addExperience(100);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Adventure completed! Gained 100 XP!'),
                  backgroundColor: RealmOfValorTheme.experienceGreen,
                ),
              );
            },
            child: const Text('Start Adventure'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.accentGold,
            ),
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: ListView(
              children: [
                // Character Management Section
                _buildSettingsSection(
                  'Character Management',
                  [
                    _buildSettingsTile(
                      'Export Character Data',
                      'Backup your character progress',
                      Icons.upload,
                      () => _exportCharacterData(),
                    ),
                    _buildSettingsTile(
                      'Import Character Data',
                      'Restore character from backup',
                      Icons.download,
                      () => _importCharacterData(),
                    ),
                    _buildSettingsTile(
                      'Reset Character',
                      'Reset current character progress',
                      Icons.refresh,
                      () => _resetCharacter(),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Card Management Section
                _buildSettingsSection(
                  'Card Management',
                  [
                    _buildSettingsTile(
                      'Export Cards',
                      'Backup your card collection',
                      Icons.style,
                      () => _exportCards(),
                    ),
                    _buildSettingsTile(
                      'Import Cards',
                      'Import card collection',
                      Icons.library_add,
                      () => _importCards(),
                    ),
                    _buildSettingsTile(
                      'Generate Sample Cards',
                      'Add sample cards for testing',
                      Icons.auto_fix_high,
                      () => _generateSampleCards(),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // App Settings Section
                _buildSettingsSection(
                  'App Settings',
                  [
                    _buildSettingsTile(
                      'Clear All Data',
                      'Reset app to initial state',
                      Icons.delete_forever,
                      () => _clearAllData(),
                    ),
                    _buildSettingsTile(
                      'App Info',
                      'Version and build information',
                      Icons.info,
                      () => _showAppInfo(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: RealmOfValorTheme.accentGold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: RealmOfValorTheme.accentGold),
      title: Text(
        title,
        style: const TextStyle(color: RealmOfValorTheme.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: RealmOfValorTheme.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right, color: RealmOfValorTheme.textSecondary),
      onTap: onTap,
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Item'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Consumer<CardService>(
            builder: (context, cardService, child) {
              final availableCards = cardService.getAllCards();
              
              if (availableCards.isEmpty) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.inventory_2,
                      size: 64,
                      color: RealmOfValorTheme.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No cards available',
                      style: TextStyle(
                        fontSize: 16,
                        color: RealmOfValorTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create some cards in the Card Editor first',
                      style: TextStyle(
                        fontSize: 14,
                        color: RealmOfValorTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() => _selectedIndex = 2); // Switch to Card Editor
                      },
                      child: const Text('Go to Card Editor'),
                    ),
                  ],
                );
              }
              
              return ListView.builder(
                itemCount: availableCards.length,
                itemBuilder: (context, index) {
                  final card = availableCards[index];
                  return Card(
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: RealmOfValorTheme.getRarityColor(card.rarity),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getCardTypeIcon(card.type),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        card.name,
                        style: TextStyle(
                          color: RealmOfValorTheme.getRarityColor(card.rarity),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${card.type.name.toUpperCase()} • ${card.rarity.name.toUpperCase()}',
                        style: const TextStyle(
                          color: RealmOfValorTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.add, color: RealmOfValorTheme.accentGold),
                        onPressed: () {
                          final cardInstance = CardInstance(card: card);
                          provider.addToInventory(cardInstance);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Added ${card.name} to inventory!')),
                          );
                        },
                      ),
                    ),
                  );
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
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showQuickAddItemDialog(provider);
            },
            child: const Text('Quick Add'),
          ),
        ],
      ),
    );
  }

  void _showQuickAddItemDialog(CharacterProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Add Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add a random item to your inventory:'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickAddButton('Weapon', CardType.weapon, provider),
                _buildQuickAddButton('Armor', CardType.armor, provider),
                _buildQuickAddButton('Potion', CardType.consumable, provider),
              ],
            ),
          ],
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

  Widget _buildQuickAddButton(String label, CardType type, CharacterProvider provider) {
    return ElevatedButton(
      onPressed: () {
        final cardService = context.read<CardService>();
        final randomCard = cardService.generateRandomCard();
        final cardInstance = CardInstance(card: randomCard);
        provider.addToInventory(cardInstance);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${randomCard.name} to inventory!')),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getCardTypeIcon(type)),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }

  IconData _getCardTypeIcon(CardType type) {
    switch (type) {
      case CardType.weapon:
        return Icons.sports_martial_arts;
      case CardType.armor:
        return Icons.shield;
      case CardType.consumable:
        return Icons.local_drink;
      case CardType.spell:
        return Icons.auto_fix_high;
      case CardType.skill:
        return Icons.psychology;
      case CardType.quest:
        return Icons.assignment;
      case CardType.adventure:
        return Icons.explore;
      case CardType.accessory:
        return Icons.diamond;
      default:
        return Icons.category;
    }
  }

  void _scanQRCode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code Scanner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.qr_code_scanner,
              size: 64,
              color: RealmOfValorTheme.accentGold,
            ),
            const SizedBox(height: 16),
            const Text(
              'QR Code Scanner',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: RealmOfValorTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Scan physical cards to add them to your digital collection',
              style: TextStyle(
                color: RealmOfValorTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _simulateQRScan();
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Simulate Scan'),
            ),
          ],
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

  void _simulateQRScan() {
    // Simulate QR code scanning by adding a random card
    final cardService = context.read<CardService>();
    final characterProvider = context.read<CharacterProvider>();
    
    final randomCard = cardService.generateRandomCard();
    final cardInstance = CardInstance(card: randomCard);
    
    characterProvider.addToInventory(cardInstance);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Scanned and added: ${randomCard.name}'),
        backgroundColor: RealmOfValorTheme.experienceGreen,
      ),
    );
  }

  void _exportCharacterData() {
    final characterProvider = context.read<CharacterProvider>();
    final character = characterProvider.currentCharacter;
    
    if (character == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No character selected to export')),
      );
      return;
    }
    
    final jsonData = character.toJson();
    final jsonString = jsonEncode(jsonData);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Character Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Character data exported successfully!'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: RealmOfValorTheme.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                jsonString,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _importCharacterData() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Character Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Paste character JSON data:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Paste JSON data here...',
              ),
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
              try {
                final jsonData = jsonDecode(controller.text);
                final character = GameCharacter.fromJson(jsonData);
                context.read<CharacterProvider>().createCharacter(character);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Character imported successfully!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Import failed: ${e.toString()}')),
                );
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _resetCharacter() {
    final characterProvider = context.read<CharacterProvider>();
    final character = characterProvider.currentCharacter;
    
    if (character == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No character selected to reset')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Character'),
        content: Text('Are you sure you want to reset ${character.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: RealmOfValorTheme.healthRed),
            onPressed: () {
              final resetCharacter = GameCharacter(
                id: character.id,
                name: character.name,
                characterClass: character.characterClass,
                availableStatPoints: 5,
                availableSkillPoints: 1,
              );
              characterProvider.updateCharacter(resetCharacter);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Character reset successfully!')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _exportCards() {
    final cardService = context.read<CardService>();
    final exportData = cardService.exportCards();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Cards'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Card collection exported successfully!'),
            const SizedBox(height: 16),
            Container(
              height: 200,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: RealmOfValorTheme.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  exportData,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _importCards() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Cards'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Paste card collection JSON data:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Paste JSON data here...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final cardService = context.read<CardService>();
              final success = await cardService.importCards(controller.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Cards imported successfully!' : 'Import failed!'),
                ),
              );
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _generateSampleCards() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Sample Cards'),
        content: const Text('This will create sample cards for testing. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final cardService = context.read<CardService>();
              
              // Generate sample cards
              for (int i = 0; i < 10; i++) {
                final randomCard = cardService.generateRandomCard();
                await cardService.createCard(randomCard);
              }
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sample cards generated successfully!')),
              );
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  void _clearAllData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('This will delete ALL characters and cards. This action cannot be undone!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: RealmOfValorTheme.healthRed),
            onPressed: () async {
              final prefs = context.read<SharedPreferences>();
              await prefs.clear();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data cleared! Please restart the app.')),
              );
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showAppInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App Information'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Realm of Valor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Version: 1.0.0'),
            Text('Build: 1'),
            SizedBox(height: 16),
            Text('A hybrid card-based RPG combining Diablo II mechanics with Adventure Time aesthetics.'),
            SizedBox(height: 16),
            Text('Features:'),
            Text('• Character progression system'),
            Text('• Inventory management'),
            Text('• Card creation tools'),
            Text('• QR code integration'),
            Text('• Cross-platform support'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}