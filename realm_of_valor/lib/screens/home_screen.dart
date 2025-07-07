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
  const HomeScreen({super.key});

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

        return Stack(
          children: [
            SingleChildScrollView(
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
                  
                  // NEW: Character Power Rating
                  _buildPowerRatingCard(character),
                  
                  const SizedBox(height: 16),
                  
                  // NEW: Daily Challenges
                  _buildDailyChallengesCard(characterProvider),
                  
                  const SizedBox(height: 16),
                  
                  // Real Activity Feed
                  _buildRealActivityCard(characterProvider),
                  
                  const SizedBox(height: 16),
                  
                  // NEW: Character Achievements
                  _buildAchievementsCard(character),
                ],
              ),
            ),
            
            // Level Up Overlay
            if (characterProvider.hasLeveledUp)
              _buildLevelUpOverlay(character, characterProvider),
          ],
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

  Widget _buildQuickActionsCard(CharacterProvider characterProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: RealmOfValorTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickActionButton(
                  'Add Item',
                  Icons.add_box,
                  () => _showQuickAddItemDialog(characterProvider),
                ),
                _buildQuickActionButton(
                  'Add XP',
                  Icons.trending_up,
                  () => _addTestExperience(characterProvider),
                ),
                _buildQuickActionButton(
                  'Scan QR',
                  Icons.qr_code_scanner,
                  _scanQRCode,
                ),
                _buildQuickActionButton(
                  'Rest',
                  Icons.local_hotel,
                  () => _restAtInn(characterProvider),
                ),
                _buildQuickActionButton(
                  'Shop',
                  Icons.store,
                  () => _visitShop(characterProvider),
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

  void _addTestExperience(CharacterProvider provider) async {
    try {
      final character = provider.currentCharacter;
      if (character == null) return;
      
      print('Before XP: ${character.experience}/${character.experienceToNext}, Level: ${character.level}');
      
      final success = await provider.addExperience(100, source: 'Test');
      
      final updatedCharacter = provider.currentCharacter;
      if (updatedCharacter != null) {
        print('After XP: ${updatedCharacter.experience}/${updatedCharacter.experienceToNext}, Level: ${updatedCharacter.level}');
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Added 100 XP!' : 'Failed to add XP'),
          backgroundColor: success ? RealmOfValorTheme.experienceGreen : Colors.red,
        ),
      );
    } catch (e) {
      print('Error adding test XP: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  Widget _buildPowerRatingCard(GameCharacter character) {
    final powerRating = _calculatePowerRating(character);
    final powerTier = _getPowerTier(powerRating);
    
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
                  'Power Rating',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: RealmOfValorTheme.accentGold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: powerTier['color'],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    powerTier['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.flash_on, color: powerTier['color'], size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        powerRating.toString(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: powerTier['color'],
                        ),
                      ),
                      Text(
                        'Combat effectiveness rating',
                        style: const TextStyle(
                          color: RealmOfValorTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyChallengesCard(CharacterProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Challenges',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: RealmOfValorTheme.accentGold,
              ),
            ),
            const SizedBox(height: 12),
            _buildChallengeItem('Defeat 5 Enemies', '3/5', 0.6, Icons.sports_martial_arts),
            const SizedBox(height: 8),
            _buildChallengeItem('Find 3 Items', '1/3', 0.33, Icons.inventory),
            const SizedBox(height: 8),
            _buildChallengeItem('Gain 1000 XP', '750/1000', 0.75, Icons.trending_up),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeItem(String title, String progress, double progressValue, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: RealmOfValorTheme.accentGold, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: RealmOfValorTheme.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    progress,
                    style: const TextStyle(
                      color: RealmOfValorTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progressValue,
                backgroundColor: RealmOfValorTheme.surfaceLight,
                valueColor: const AlwaysStoppedAnimation(RealmOfValorTheme.accentGold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRealActivityCard(CharacterProvider provider) {
    final activities = provider.recentActivity;
    
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
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: RealmOfValorTheme.accentGold,
                  ),
                ),
                if (activities.isNotEmpty)
                  TextButton(
                    onPressed: () => _showFullActivityLog(activities),
                    child: const Text('View All'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (activities.isEmpty) ...[
              Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.history,
                      size: 48,
                      color: RealmOfValorTheme.textSecondary,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No recent activity',
                      style: TextStyle(
                        color: RealmOfValorTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Start playing to see your adventures here!',
                      style: TextStyle(
                        color: RealmOfValorTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ...activities.take(5).map((activity) => _buildRealActivityItem(activity)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRealActivityItem(ActivityEntry activity) {
    IconData iconData;
    switch (activity.icon) {
      case 'person_add':
        iconData = Icons.person_add;
        break;
      case 'check_circle':
        iconData = Icons.check_circle;
        break;
      case 'trending_up':
        iconData = Icons.trending_up;
        break;
      case 'star':
        iconData = Icons.star;
        break;
      case 'explore':
        iconData = Icons.explore;
        break;
      case 'add_box':
        iconData = Icons.add_box;
        break;
      case 'sports_martial_arts':
        iconData = Icons.sports_martial_arts;
        break;
      case 'qr_code_scanner':
        iconData = Icons.qr_code_scanner;
        break;
      default:
        iconData = Icons.info;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(iconData, size: 16, color: RealmOfValorTheme.accentGold),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.action,
                  style: const TextStyle(color: RealmOfValorTheme.textPrimary),
                ),
                if (activity.details != null)
                  Text(
                    activity.details!,
                    style: const TextStyle(
                      color: RealmOfValorTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            activity.timeAgo,
            style: const TextStyle(
              color: RealmOfValorTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsCard(GameCharacter character) {
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
                  'Achievements',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: RealmOfValorTheme.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showAllAchievements(character),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: RealmOfValorTheme.accentGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Recent Achievement Unlocks
            _buildRecentAchievements(character),
            const SizedBox(height: 8),
            // Achievement Progress Summary
            _buildAchievementProgress(character),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecentAchievements(GameCharacter character) {
    final recentAchievements = _getRecentAchievements(character);
    
    if (recentAchievements.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: RealmOfValorTheme.surfaceLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.emoji_events, color: RealmOfValorTheme.textSecondary),
            SizedBox(width: 8),
            Text(
              'Complete quests to unlock achievements!',
              style: TextStyle(color: RealmOfValorTheme.textSecondary),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: recentAchievements.take(3).map((achievement) =>
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: RealmOfValorTheme.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: RealmOfValorTheme.accentGold.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: RealmOfValorTheme.accentGold,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  achievement['icon'] as IconData,
                  color: RealmOfValorTheme.primaryDark,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement['title'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: RealmOfValorTheme.accentGold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      achievement['description'] as String,
                      style: const TextStyle(
                        color: RealmOfValorTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (achievement['unlocked'] as bool)
                const Icon(
                  Icons.check_circle,
                  color: RealmOfValorTheme.accentGold,
                  size: 20,
                ),
            ],
          ),
        ),
      ).toList(),
    );
  }
  
  Widget _buildAchievementProgress(GameCharacter character) {
    final stats = _getAchievementStats(character);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildProgressStat('Unlocked', '${stats['unlocked']}/${stats['total']}', Icons.emoji_events),
          _buildProgressStat('Collection', '${stats['collection']}%', Icons.library_books),
          _buildProgressStat('Combat', '${stats['combat']}%', Icons.sports_martial_arts),
          _buildProgressStat('Fitness', '${stats['fitness']}%', Icons.fitness_center),
        ],
      ),
    );
  }
  
  Widget _buildProgressStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: RealmOfValorTheme.accentGold, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: RealmOfValorTheme.textPrimary,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: RealmOfValorTheme.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
  
  void _showAllAchievements(GameCharacter character) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Achievements',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: RealmOfValorTheme.accentGold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildAchievementCategories(character),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAchievementCategories(GameCharacter character) {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Collection', icon: Icon(Icons.library_books)),
              Tab(text: 'Combat', icon: Icon(Icons.sports_martial_arts)),
              Tab(text: 'Fitness', icon: Icon(Icons.fitness_center)),
              Tab(text: 'Social', icon: Icon(Icons.people)),
              Tab(text: 'Secret', icon: Icon(Icons.help_outline)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildAchievementList(_getCollectionAchievements(character)),
                _buildAchievementList(_getCombatAchievements(character)),
                _buildAchievementList(_getFitnessAchievements(character)),
                _buildAchievementList(_getSocialAchievements(character)),
                _buildAchievementList(_getSecretAchievements(character)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAchievementList(List<Map<String, dynamic>> achievements) {
    return ListView.builder(
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        final isUnlocked = achievement['unlocked'] as bool;
        
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Card(
            color: isUnlocked ? RealmOfValorTheme.accentGold.withOpacity(0.1) : null,
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isUnlocked ? RealmOfValorTheme.accentGold : RealmOfValorTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  achievement['icon'] as IconData,
                  color: isUnlocked ? RealmOfValorTheme.primaryDark : RealmOfValorTheme.textSecondary,
                ),
              ),
              title: Text(
                achievement['title'] as String,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? RealmOfValorTheme.accentGold : RealmOfValorTheme.textPrimary,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(achievement['description'] as String),
                  if (achievement['progress'] != null)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      child: LinearProgressIndicator(
                        value: (achievement['progress'] as int) / 100.0,
                        backgroundColor: RealmOfValorTheme.surfaceLight,
                        valueColor: const AlwaysStoppedAnimation(RealmOfValorTheme.accentGold),
                      ),
                    ),
                ],
              ),
              trailing: isUnlocked 
                  ? const Icon(Icons.check_circle, color: RealmOfValorTheme.accentGold)
                  : Text('${achievement['points']} pts'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLevelUpOverlay(GameCharacter character, CharacterProvider provider) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1500),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.5 + (value * 0.5),
              child: Opacity(
                opacity: value,
                child: Card(
                  child: Container(
                    width: 300,
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: RealmOfValorTheme.accentGold,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: RealmOfValorTheme.accentGold.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.star,
                            color: RealmOfValorTheme.primaryDark,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'LEVEL UP!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: RealmOfValorTheme.accentGold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Level ${character.level}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: RealmOfValorTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '+${character.availableStatPoints} Stat Points',
                          style: const TextStyle(
                            fontSize: 16,
                            color: RealmOfValorTheme.experienceGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '+${character.availableSkillPoints} Skill Points',
                          style: const TextStyle(
                            fontSize: 16,
                            color: RealmOfValorTheme.manaBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => provider.clearLevelUpFlag(),
                          child: const Text('Continue'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardEditorTab() {
    return const CardEditorScreen();
  }

  Widget _buildMapTab() {
    return Consumer<CharacterProvider>(
      builder: (context, characterProvider, child) {
        final character = characterProvider.currentCharacter;
        
        if (character == null) {
          return const Center(
            child: Text(
              'Create a character to explore the world',
              style: TextStyle(color: RealmOfValorTheme.textSecondary),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location Header
              _buildLocationHeader(),
              
              const SizedBox(height: 16),
              
              // Active Quests
              _buildActiveQuestsSection(character, characterProvider),
              
              const SizedBox(height: 16),
              
              // Available Adventures
              _buildAvailableAdventuresSection(character),
              
              const SizedBox(height: 16),
              
              // Daily Challenges
              _buildDailyChallengesSection(character, characterProvider),
              
              const SizedBox(height: 16),
              
              // Special Events
              _buildSpecialEventsSection(character),
              
              const SizedBox(height: 16),
              
              // QR Code Adventure
              _buildQRAdventureSection(),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildLocationHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: RealmOfValorTheme.accentGold),
                const SizedBox(width: 8),
                const Text(
                  'Current Location',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: RealmOfValorTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _refreshLocation(),
                  icon: const Icon(Icons.refresh, color: RealmOfValorTheme.accentGold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Adventure Town Central Plaza',
              style: TextStyle(
                fontSize: 16,
                color: RealmOfValorTheme.textPrimary,
              ),
            ),
            const Text(
              'A bustling center of activity where adventurers gather',
              style: TextStyle(color: RealmOfValorTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildLocationButton('Explore Area', Icons.explore, () => _exploreCurrentArea()),
                const SizedBox(width: 8),
                _buildLocationButton('Find Nearby', Icons.search, () => _findNearbyLocations()),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLocationButton(String label, IconData icon, VoidCallback onPressed) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: RealmOfValorTheme.primaryLight,
          foregroundColor: RealmOfValorTheme.accentGold,
        ),
      ),
    );
  }
  
  Widget _buildActiveQuestsSection(GameCharacter character, CharacterProvider provider) {
    final activeQuests = _getActiveQuests(character);
    
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
                  'Active Quests',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: RealmOfValorTheme.textPrimary,
                  ),
                ),
                Text(
                  '${activeQuests.length}/5',
                  style: const TextStyle(color: RealmOfValorTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (activeQuests.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: RealmOfValorTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.assignment, color: RealmOfValorTheme.textSecondary),
                    SizedBox(width: 8),
                    Text(
                      'No active quests. Start an adventure below!',
                      style: TextStyle(color: RealmOfValorTheme.textSecondary),
                    ),
                  ],
                ),
              )
            else
              ...activeQuests.map((quest) => _buildQuestCard(quest, provider)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuestCard(Map<String, dynamic> quest, CharacterProvider provider) {
    final progress = quest['progress'] as int;
    final maxProgress = quest['maxProgress'] as int;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RealmOfValorTheme.accentGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                quest['icon'] as IconData,
                color: RealmOfValorTheme.accentGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  quest['title'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: RealmOfValorTheme.textPrimary,
                  ),
                ),
              ),
              Text(
                quest['difficulty'] as String,
                style: TextStyle(
                  color: _getDifficultyColor(quest['difficulty'] as String),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            quest['description'] as String,
            style: const TextStyle(color: RealmOfValorTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress / maxProgress,
                  backgroundColor: RealmOfValorTheme.surfaceMedium,
                  valueColor: const AlwaysStoppedAnimation(RealmOfValorTheme.accentGold),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$progress/$maxProgress',
                style: const TextStyle(
                  color: RealmOfValorTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.star, color: RealmOfValorTheme.accentGold, size: 16),
              const SizedBox(width: 4),
              Text(
                '+${quest['expReward']} XP',
                style: const TextStyle(color: RealmOfValorTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(width: 12),
              Icon(Icons.inventory, color: RealmOfValorTheme.accentGold, size: 16),
              const SizedBox(width: 4),
              Text(
                '${quest['itemRewards']} items',
                style: const TextStyle(color: RealmOfValorTheme.textSecondary, fontSize: 12),
              ),
              const Spacer(),
              if (progress >= maxProgress)
                ElevatedButton(
                  onPressed: () => _completeQuest(quest, provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RealmOfValorTheme.accentGold,
                    foregroundColor: RealmOfValorTheme.primaryDark,
                    minimumSize: const Size(60, 30),
                  ),
                  child: const Text('Complete'),
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildAvailableAdventuresSection(GameCharacter character) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Adventures',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: RealmOfValorTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.2,
              children: [
                _buildAdventureCard(
                  'Enchanted Forest',
                  'A magical forest filled with ancient secrets',
                  Icons.forest,
                  'Easy',
                  () => _startAdventure('Enchanted Forest', character),
                ),
                _buildAdventureCard(
                  'Crystal Caves',
                  'Mysterious caves with precious gems',
                  Icons.diamond,
                  'Medium',
                  () => _startAdventure('Crystal Caves', character),
                ),
                _buildAdventureCard(
                  'Sky Temple',
                  'Ancient temple floating in the clouds',
                  Icons.cloud,
                  'Hard',
                  () => _startAdventure('Sky Temple', character),
                ),
                _buildAdventureCard(
                  'Dragon\'s Lair',
                  'Face the legendary Ancient Dragon',
                  Icons.whatshot,
                  'Legendary',
                  () => _startAdventure('Dragon\'s Lair', character),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDailyChallengesSection(GameCharacter character, CharacterProvider provider) {
    final challenges = _getDailyChallenges(character);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Daily Challenges',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: RealmOfValorTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: RealmOfValorTheme.accentGold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Resets in 12h',
                    style: TextStyle(
                      color: RealmOfValorTheme.primaryDark,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...challenges.map((challenge) => _buildChallengeCard(challenge, provider)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildChallengeCard(Map<String, dynamic> challenge, CharacterProvider provider) {
    final isCompleted = challenge['completed'] as bool;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCompleted ? RealmOfValorTheme.accentGold.withOpacity(0.1) : RealmOfValorTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCompleted ? RealmOfValorTheme.accentGold : RealmOfValorTheme.surfaceLight,
        ),
      ),
      child: Row(
        children: [
          Icon(
            challenge['icon'] as IconData,
            color: isCompleted ? RealmOfValorTheme.accentGold : RealmOfValorTheme.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge['title'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? RealmOfValorTheme.accentGold : RealmOfValorTheme.textPrimary,
                  ),
                ),
                Text(
                  challenge['description'] as String,
                  style: const TextStyle(
                    color: RealmOfValorTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isCompleted)
            const Icon(Icons.check_circle, color: RealmOfValorTheme.accentGold)
          else
            Text(
              '+${challenge['reward']} XP',
              style: const TextStyle(
                color: RealmOfValorTheme.textSecondary,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildSpecialEventsSection(GameCharacter character) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.event, color: RealmOfValorTheme.accentGold),
                SizedBox(width: 8),
                Text(
                  'Special Events',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: RealmOfValorTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    RealmOfValorTheme.accentGold.withOpacity(0.2),
                    RealmOfValorTheme.primaryLight.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: RealmOfValorTheme.accentGold.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.celebration, color: RealmOfValorTheme.accentGold),
                      const SizedBox(width: 8),
                      const Text(
                        'Winter Solstice Festival',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: RealmOfValorTheme.accentGold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: RealmOfValorTheme.accentGold,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'LIMITED',
                          style: TextStyle(
                            color: RealmOfValorTheme.primaryDark,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Celebrate the longest night with magical winter adventures! Double XP and exclusive winter-themed rewards.',
                    style: TextStyle(color: RealmOfValorTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _joinSpecialEvent(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RealmOfValorTheme.accentGold,
                      foregroundColor: RealmOfValorTheme.primaryDark,
                    ),
                    child: const Text('Join Festival'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQRAdventureSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(
              Icons.qr_code_scanner,
              size: 48,
              color: RealmOfValorTheme.accentGold,
            ),
            const SizedBox(height: 12),
            const Text(
              'Scan for Adventure',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: RealmOfValorTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Scan QR codes in the real world to discover hidden adventures, unlock exclusive items, and find secret treasures!',
              style: TextStyle(color: RealmOfValorTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _scanQRCode,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Open Scanner'),
              style: ElevatedButton.styleFrom(
                backgroundColor: RealmOfValorTheme.accentGold,
                foregroundColor: RealmOfValorTheme.primaryDark,
              ),
            ),
          ],
        ),
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
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty) {
                  final character = GameCharacter(
                    name: nameController.text.trim(),
                    characterClass: selectedClass,
                    availableStatPoints: 5,
                    availableSkillPoints: 1,
                  );
                  await provider.createCharacter(character);
                  Navigator.pop(context);
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Character ${character.name} created successfully!'),
                      backgroundColor: RealmOfValorTheme.accentGold,
                    ),
                  );
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
      onPressed: () async {
        try {
          final cardService = context.read<CardService>();
          final randomCard = cardService.generateRandomCard();
          
          if (randomCard.name.isEmpty) {
            throw Exception('Invalid card generated');
          }
          
          final cardInstance = CardInstance(card: randomCard);
          final success = await provider.addToInventory(cardInstance);
          
          if (!mounted) return;
          Navigator.pop(context);
          
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added ${randomCard.name} to inventory!'),
                backgroundColor: RealmOfValorTheme.experienceGreen,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to add item - inventory may be full'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          print('Error adding item: $e');
          if (!mounted) return;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding item: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
              'Scan Physical Cards',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: RealmOfValorTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Point your camera at a physical card to add it to your collection',
              style: TextStyle(color: RealmOfValorTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
                         Row(
               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
               children: [
                                   _buildQRTypeButton('Item', Icons.inventory, () => _scanItemCard(context.read<CharacterProvider>())),
                  _buildQRTypeButton('Quest', Icons.assignment, () => _scanQuestCard(context.read<CharacterProvider>())),
                  _buildQRTypeButton('Enemy', Icons.sports_martial_arts, () => _scanEnemyCard(context.read<CharacterProvider>())),
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

  Widget _buildQRTypeButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pop(context);
        onPressed();
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _scanItemCard(CharacterProvider provider) async {
    try {
      final cardService = context.read<CardService>();
      final randomCard = cardService.generateRandomCard();
      
      if (randomCard.name.isEmpty) {
        throw Exception('Invalid card generated');
      }
      
      final cardInstance = CardInstance(card: randomCard);
      final success = await provider.addToInventory(cardInstance);
      await provider.scanQRCode('item_${randomCard.id}');
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Scanned item: ${randomCard.name}' : 'Failed to add scanned item'),
          backgroundColor: success ? RealmOfValorTheme.experienceGreen : Colors.red,
        ),
      );
    } catch (e) {
      print('Error scanning item: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error scanning item: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _scanQuestCard(CharacterProvider provider) {
    final questNames = ['Ancient Ruins', 'Dragon\'s Treasure', 'Lost Artifact', 'Mystic Portal'];
    final questName = questNames[DateTime.now().millisecond % questNames.length];
    
    provider.startQuest(questName, 'Enchanted Forest');
    provider.scanQRCode('quest_$questName');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quest Discovered: $questName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assignment, size: 64, color: RealmOfValorTheme.accentGold),
            const SizedBox(height: 16),
            Text('A new quest has been added to your map!'),
            const SizedBox(height: 8),
            const Text('Check the Map tab to start your adventure.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 3); // Switch to Map tab
            },
            child: const Text('Go to Map'),
          ),
        ],
      ),
    );
  }

  void _scanEnemyCard(CharacterProvider provider) {
    final enemyNames = ['Goblin Scout', 'Shadow Wolf', 'Fire Imp', 'Ice Troll'];
    final enemyName = enemyNames[DateTime.now().millisecond % enemyNames.length];
    
    provider.scanQRCode('enemy_$enemyName');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enemy Encountered: $enemyName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sports_martial_arts, size: 64, color: RealmOfValorTheme.healthRed),
            const SizedBox(height: 16),
            Text('A wild $enemyName appears!'),
            const SizedBox(height: 8),
            const Text('Prepare for battle!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Flee'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startDuel(provider, enemyName);
            },
            child: const Text('Fight!'),
          ),
        ],
      ),
    );
  }

  void _findRandomLoot(CharacterProvider provider) {
    final cardService = context.read<CardService>();
    final lootCard = cardService.generateRandomCard();
    final cardInstance = CardInstance(card: lootCard);
    
    provider.addToInventory(cardInstance);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Loot Found!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.card_giftcard,
              size: 64,
              color: RealmOfValorTheme.getRarityColor(lootCard.rarity),
            ),
            const SizedBox(height: 16),
            Text(
              lootCard.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: RealmOfValorTheme.getRarityColor(lootCard.rarity),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${lootCard.rarity.name.toUpperCase()} ${lootCard.type.name.toUpperCase()}',
              style: const TextStyle(color: RealmOfValorTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(lootCard.description),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Sweet!'),
          ),
        ],
      ),
    );
  }

  void _startQuickDuel(CharacterProvider provider) {
    final opponents = ['Flame Knight', 'Shadow Assassin', 'Frost Mage', 'Thunder Warrior'];
    final opponent = opponents[DateTime.now().millisecond % opponents.length];
    
    _startDuel(provider, opponent);
  }

  void _startDuel(CharacterProvider provider, String opponentName) {
    final character = provider.currentCharacter;
    if (character == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Duel: ${character.name} vs $opponentName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sports_martial_arts, size: 64, color: RealmOfValorTheme.accentGold),
            const SizedBox(height: 16),
            Text('Power Rating: ${_calculatePowerRating(character)}'),
            const SizedBox(height: 8),
            const Text('A turn-based duel system will be implemented here!'),
            const SizedBox(height: 16),
            const Text('For now, let\'s simulate the outcome...'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Retreat'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _simulateDuel(provider, opponentName);
            },
            child: const Text('Fight!'),
          ),
        ],
      ),
    );
  }

  void _simulateDuel(CharacterProvider provider, String opponentName) {
    final character = provider.currentCharacter!;
    final powerRating = _calculatePowerRating(character);
    final victory = powerRating > 50 + (DateTime.now().millisecond % 100);
    
    if (victory) {
      final expReward = 150 + (DateTime.now().millisecond % 100);
      provider.winDuel(opponentName, expReward);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Victory! Defeated $opponentName (+$expReward XP)'),
          backgroundColor: RealmOfValorTheme.experienceGreen,
        ),
      );
    } else {
      provider.loseDuel(opponentName);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Defeat! $opponentName was too strong this time.'),
          backgroundColor: RealmOfValorTheme.healthRed,
        ),
      );
    }
  }

  void _restAtInn(CharacterProvider provider) {
    provider.addExperience(50, source: 'Rest at Inn');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rest at Inn'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hotel, size: 64, color: RealmOfValorTheme.manaBlue),
            SizedBox(height: 16),
            Text('You rest at the cozy inn and share stories with fellow adventurers.'),
            SizedBox(height: 8),
            Text('Gained 50 XP from learning new techniques!'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Refreshed!'),
          ),
        ],
      ),
    );
  }

  void _trainSkills(CharacterProvider provider) {
    final character = provider.currentCharacter;
    if (character == null) return;
    
    if (character.availableSkillPoints > 0) {
      provider.addExperience(25, source: 'Skill Training');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Training complete! Check the Inventory tab to spend skill points.'),
          backgroundColor: RealmOfValorTheme.manaBlue,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No skill points available. Gain more experience to unlock training!'),
        ),
      );
    }
  }

  void _visitShop(CharacterProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Merchant\'s Shop'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.store, size: 64, color: RealmOfValorTheme.accentGold),
            const SizedBox(height: 16),
            const Text('Welcome to my shop, adventurer!'),
            const SizedBox(height: 8),
            const Text('Trading system coming soon...'),
            const SizedBox(height: 16),
            const Text('For now, have a free potion!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _giveFreePotion(provider);
            },
            child: const Text('Take Potion'),
          ),
        ],
      ),
    );
  }

  void _giveFreePotion(CharacterProvider provider) {
    final cardService = context.read<CardService>();
    final potion = cardService.createBasicConsumable(
      name: 'Health Potion',
      description: 'Restores health when consumed',
      effectType: 'heal',
      effectValue: 100,
    );
    final cardInstance = CardInstance(card: potion);
    
    provider.addToInventory(cardInstance);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Received Health Potion from the merchant!'),
        backgroundColor: RealmOfValorTheme.experienceGreen,
      ),
    );
  }

  int _calculatePowerRating(GameCharacter character) {
    return (character.totalStrength * 2) + 
           (character.totalDexterity * 2) + 
           (character.totalVitality * 1.5).round() + 
           (character.totalEnergy * 1.5).round() + 
           (character.level * 10) +
           (character.equipment.getAllEquippedItems().length * 5);
  }

  Map<String, dynamic> _getPowerTier(int powerRating) {
    if (powerRating < 50) {
      return {'name': 'Novice', 'color': RealmOfValorTheme.rarityCommon};
    } else if (powerRating < 100) {
      return {'name': 'Apprentice', 'color': RealmOfValorTheme.rarityUncommon};
    } else if (powerRating < 200) {
      return {'name': 'Warrior', 'color': RealmOfValorTheme.rarityRare};
    } else if (powerRating < 350) {
      return {'name': 'Champion', 'color': RealmOfValorTheme.rarityEpic};
    } else if (powerRating < 500) {
      return {'name': 'Hero', 'color': RealmOfValorTheme.rarityLegendary};
    } else {
      return {'name': 'Legend', 'color': RealmOfValorTheme.rarityMythic};
    }
  }

  List<Map<String, dynamic>> _getCharacterAchievements(GameCharacter character) {
    return [
      {
        'title': 'First Steps',
        'icon': Icons.directions_walk,
        'unlocked': character.level >= 1,
      },
      {
        'title': 'Equipped',
        'icon': Icons.shield,
        'unlocked': character.equipment.getAllEquippedItems().isNotEmpty,
      },
      {
        'title': 'Collector',
        'icon': Icons.inventory,
        'unlocked': character.inventory.length >= 5,
      },
      {
        'title': 'Veteran',
        'icon': Icons.star,
        'unlocked': character.level >= 10,
      },
    ];
  }

  void _showFullActivityLog(List<ActivityEntry> activities) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activity Log'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: activities.length,
            itemBuilder: (context, index) {
              return _buildRealActivityItem(activities[index]);
            },
          ),
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
              if (!context.mounted) return;
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
              
              if (!context.mounted) return;
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
              if (!context.mounted) return;
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

  List<Map<String, dynamic>> _getRecentAchievements(GameCharacter character) {
    // Generate achievements based on character progress
    final achievements = <Map<String, dynamic>>[];
    
    // Check character creation achievement
    achievements.add({
      'title': 'First Steps',
      'description': 'Create your first character',
      'icon': Icons.person_add,
      'unlocked': true,
      'points': 10,
    });
    
    // Check level achievements
    if (character.level >= 5) {
      achievements.add({
        'title': 'Apprentice',
        'description': 'Reach level 5',
        'icon': Icons.star,
        'unlocked': true,
        'points': 25,
      });
    }
    
    // Check inventory achievements
    if (character.inventory.length >= 5) {
      achievements.add({
        'title': 'Collector',
        'description': 'Collect 5 items',
        'icon': Icons.inventory,
        'unlocked': true,
        'points': 15,
      });
    }
    
    return achievements;
  }
  
  Map<String, int> _getAchievementStats(GameCharacter character) {
    final totalAchievements = 50; // Total possible achievements
    var unlockedCount = 1; // Started with character creation
    
    // Count unlocked achievements based on character progress
    if (character.level >= 5) unlockedCount++;
    if (character.level >= 10) unlockedCount++;
    if (character.inventory.length >= 5) unlockedCount++;
    if (character.inventory.length >= 10) unlockedCount++;
    
    return {
      'unlocked': unlockedCount,
      'total': totalAchievements,
      'collection': ((character.inventory.length / 20) * 100).clamp(0, 100).round(),
      'combat': (character.level * 10).clamp(0, 100),
      'fitness': 25, // Basic fitness progress
    };
  }
  
  List<Map<String, dynamic>> _getCollectionAchievements(GameCharacter character) {
    return [
      {
        'title': 'First Steps',
        'description': 'Collect your first item',
        'icon': Icons.inventory,
        'unlocked': character.inventory.isNotEmpty,
        'points': 10,
        'progress': character.inventory.isNotEmpty ? 100 : 0,
      },
      {
        'title': 'Growing Collection',
        'description': 'Collect 5 different items',
        'icon': Icons.collections,
        'unlocked': character.inventory.length >= 5,
        'points': 25,
        'progress': ((character.inventory.length / 5) * 100).clamp(0, 100).round(),
      },
      {
        'title': 'Serious Collector',
        'description': 'Collect 10 different items',
        'icon': Icons.library_books,
        'unlocked': character.inventory.length >= 10,
        'points': 50,
        'progress': ((character.inventory.length / 10) * 100).clamp(0, 100).round(),
      },
      {
        'title': 'Master Collector',
        'description': 'Collect 25 different items',
        'icon': Icons.diamond,
        'unlocked': character.inventory.length >= 25,
        'points': 100,
        'progress': ((character.inventory.length / 25) * 100).clamp(0, 100).round(),
      },
      {
        'title': 'Legendary Hoarder',
        'description': 'Fill your entire inventory (40 items)',
        'icon': Icons.star,
        'unlocked': character.inventory.length >= 40,
        'points': 200,
        'progress': ((character.inventory.length / 40) * 100).clamp(0, 100).round(),
      },
    ];
  }
  
  List<Map<String, dynamic>> _getCombatAchievements(GameCharacter character) {
    return [
      {
        'title': 'First Victory',
        'description': 'Win your first battle',
        'icon': Icons.sports_martial_arts,
        'unlocked': character.level > 1,
        'points': 15,
        'progress': character.level > 1 ? 100 : 0,
      },
      {
        'title': 'Apprentice Fighter',
        'description': 'Reach level 5',
        'icon': Icons.security,
        'unlocked': character.level >= 5,
        'points': 25,
        'progress': ((character.level / 5) * 100).clamp(0, 100).round(),
      },
      {
        'title': 'Skilled Warrior',
        'description': 'Reach level 10',
        'icon': Icons.shield,
        'unlocked': character.level >= 10,
        'points': 50,
        'progress': ((character.level / 10) * 100).clamp(0, 100).round(),
      },
      {
        'title': 'Champion',
        'description': 'Reach level 20',
        'icon': Icons.emoji_events,
        'unlocked': character.level >= 20,
        'points': 100,
        'progress': ((character.level / 20) * 100).clamp(0, 100).round(),
      },
      {
        'title': 'Legendary Hero',
        'description': 'Reach level 50',
        'icon': Icons.star,
        'unlocked': character.level >= 50,
        'points': 500,
        'progress': ((character.level / 50) * 100).clamp(0, 100).round(),
      },
    ];
  }
  
  List<Map<String, dynamic>> _getFitnessAchievements(GameCharacter character) {
    return [
      {
        'title': 'First Steps',
        'description': 'Take your first 1,000 steps',
        'icon': Icons.directions_walk,
        'unlocked': false, // Would connect to fitness tracking
        'points': 10,
        'progress': 0,
      },
      {
        'title': 'Daily Walker',
        'description': 'Walk 10,000 steps in one day',
        'icon': Icons.fitness_center,
        'unlocked': false,
        'points': 25,
        'progress': 0,
      },
      {
        'title': 'Marathon Master',
        'description': 'Walk 42.2km total distance',
        'icon': Icons.run_circle,
        'unlocked': false,
        'points': 100,
        'progress': 0,
      },
      {
        'title': 'Calorie Crusher',
        'description': 'Burn 1,000 calories',
        'icon': Icons.local_fire_department,
        'unlocked': false,
        'points': 50,
        'progress': 0,
      },
      {
        'title': 'Explorer Extraordinaire',
        'description': 'Visit 100 different locations',
        'icon': Icons.explore,
        'unlocked': false,
        'points': 200,
        'progress': 0,
      },
    ];
  }
  
  List<Map<String, dynamic>> _getSocialAchievements(GameCharacter character) {
    return [
      {
        'title': 'Social Butterfly',
        'description': 'Add your first friend',
        'icon': Icons.person_add,
        'unlocked': false,
        'points': 15,
        'progress': 0,
      },
      {
        'title': 'Guild Member',
        'description': 'Join your first guild',
        'icon': Icons.groups,
        'unlocked': false,
        'points': 25,
        'progress': 0,
      },
      {
        'title': 'Team Player',
        'description': 'Complete 5 guild quests',
        'icon': Icons.emoji_events,
        'unlocked': false,
        'points': 50,
        'progress': 0,
      },
      {
        'title': 'Guild Leader',
        'description': 'Create and lead your own guild',
        'icon': Icons.star,
        'unlocked': false,
        'points': 100,
        'progress': 0,
      },
      {
        'title': 'Master Trader',
        'description': 'Complete 50 trades with other players',
        'icon': Icons.swap_horiz,
        'unlocked': false,
        'points': 75,
        'progress': 0,
      },
    ];
  }
  
  List<Map<String, dynamic>> _getSecretAchievements(GameCharacter character) {
    return [
      {
        'title': 'Night Owl',
        'description': 'Play between midnight and 4 AM',
        'icon': Icons.nightlight_round,
        'unlocked': false,
        'points': 25,
        'progress': 0,
      },
      {
        'title': 'Early Bird',
        'description': 'Start playing before 6 AM',
        'icon': Icons.wb_sunny,
        'unlocked': false,
        'points': 25,
        'progress': 0,
      },
      {
        'title': 'Lucky Seven',
        'description': 'Find 7 legendary items in a row',
        'icon': Icons.casino,
        'unlocked': false,
        'points': 777,
        'progress': 0,
      },
      {
        'title': 'Speed Demon',
        'description': 'Complete a quest in under 5 minutes',
        'icon': Icons.speed,
        'unlocked': false,
        'points': 50,
        'progress': 0,
      },
      {
        'title': 'The Chosen One',
        'description': 'Discover this secret achievement',
        'icon': Icons.help_outline,
        'unlocked': true, // Easter egg - always unlocked
        'points': 1,
        'progress': 100,
      },
    ];
  }

  void _refreshLocation() {
    // TODO: Implement location refresh with GPS
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location refreshed!')),
    );
  }
  
  void _exploreCurrentArea() {
    // TODO: Implement area exploration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exploring the area... Found some interesting locations!')),
    );
  }
  
  void _findNearbyLocations() {
    // TODO: Implement nearby location finder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scanning for nearby adventure locations...')),
    );
  }
  
  List<Map<String, dynamic>> _getActiveQuests(GameCharacter character) {
    // Return sample active quests based on character level
    final quests = <Map<String, dynamic>>[];
    
    // Starter quest for new characters
    if (character.level < 5) {
      quests.add({
        'title': 'First Adventure',
        'description': 'Collect 3 items to prove yourself as an adventurer',
        'icon': Icons.star,
        'difficulty': 'Easy',
        'progress': character.inventory.length,
        'maxProgress': 3,
        'expReward': 100,
        'itemRewards': 1,
      });
    }
    
    // Add level-based quests
    if (character.level >= 3) {
      quests.add({
        'title': 'Equipment Master',
        'description': 'Equip 5 different weapons or armor pieces',
        'icon': Icons.shield,
        'difficulty': 'Medium',
        'progress': character.equipment.getAllEquippedItems().length,
        'maxProgress': 5,
        'expReward': 200,
        'itemRewards': 2,
      });
    }
    
    return quests;
  }
  
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return RealmOfValorTheme.experienceGreen;
      case 'medium':
        return RealmOfValorTheme.accentGold;
      case 'hard':
        return Colors.orange;
      case 'legendary':
        return RealmOfValorTheme.healthRed;
      default:
        return RealmOfValorTheme.textSecondary;
    }
  }
  
  void _completeQuest(Map<String, dynamic> quest, CharacterProvider provider) async {
    try {
      final character = provider.currentCharacter!;
      final expReward = quest['expReward'] as int;
      
      // Add experience first
      final expSuccess = await provider.addExperience(expReward);
      
      // Generate reward items
      final cardService = context.read<CardService>();
      final itemCount = quest['itemRewards'] as int;
      int itemsAdded = 0;
      
      for (int i = 0; i < itemCount; i++) {
        final randomCard = cardService.generateRandomCard();
        if (randomCard.name.isNotEmpty) {
          final success = await provider.addToInventory(CardInstance(card: randomCard));
          if (success) itemsAdded++;
        }
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quest completed! Gained $expReward XP and $itemsAdded items!'),
          backgroundColor: RealmOfValorTheme.experienceGreen,
        ),
      );
    } catch (e) {
      print('Error completing quest: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing quest: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Widget _buildAdventureCard(
    String name,
    String description,
    IconData icon,
    String difficulty,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: RealmOfValorTheme.accentGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  icon,
                  color: RealmOfValorTheme.accentGold,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: RealmOfValorTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: RealmOfValorTheme.textSecondary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getDifficultyColor(difficulty),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  difficulty,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
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
            const Icon(
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
            const SizedBox(height: 8),
            Text(
              'Character Level: ${character.level}',
              style: const TextStyle(
                color: RealmOfValorTheme.accentGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Complete the adventure to gain experience and find treasure!',
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
              Navigator.pop(context);
              _completeAdventure(adventureName, character);
            },
            child: const Text('Start Adventure'),
          ),
        ],
      ),
    );
  }
  
  void _completeAdventure(String adventureName, GameCharacter character) async {
    final characterProvider = context.read<CharacterProvider>();
    final cardService = context.read<CardService>();
    
    // Calculate rewards based on adventure and character level
    int expReward = 100;
    List<GameCard> itemRewards = [];
    
    switch (adventureName) {
      case 'Enchanted Forest':
        expReward = 100 + (character.level * 10);
        break;
      case 'Crystal Caves':
        expReward = 200 + (character.level * 15);
        if (DateTime.now().millisecond % 3 == 0) {
          final crystal = cardService.createBasicConsumable(
            name: 'Magic Crystal',
            description: 'A glowing crystal that boosts mana',
            effectType: 'mana_boost',
            effectValue: 50,
            rarity: CardRarity.rare,
          );
          itemRewards.add(crystal);
        }
        break;
      case 'Sky Temple':
        expReward = 350 + (character.level * 20);
        if (DateTime.now().millisecond % 2 == 0) {
          final artifact = cardService.generateRandomCard();
          itemRewards.add(artifact);
        }
        break;
      case 'Dragon\'s Lair':
        expReward = 500 + (character.level * 25);
        // Always get treasure from dragon
        final treasure1 = cardService.generateRandomCard();
        final treasure2 = cardService.generateRandomCard();
        itemRewards.addAll([treasure1, treasure2]);
        break;
    }
    
    // Give rewards
    await characterProvider.addExperience(expReward);
    for (final item in itemRewards) {
      if (item.name.isNotEmpty) {
        await characterProvider.addToInventory(CardInstance(card: item));
      }
    }
    
    // Show completion dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$adventureName Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.celebration,
              size: 64,
              color: RealmOfValorTheme.experienceGreen,
            ),
            const SizedBox(height: 16),
            const Text(
              'Adventure completed successfully!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: RealmOfValorTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gained $expReward XP!',
              style: const TextStyle(
                color: RealmOfValorTheme.experienceGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (itemRewards.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Found ${itemRewards.length} treasure${itemRewards.length > 1 ? 's' : ''}!',
                style: const TextStyle(
                  color: RealmOfValorTheme.accentGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ...itemRewards.map((item) => Text(
                '• ${item.name}',
                style: TextStyle(
                  color: RealmOfValorTheme.getRarityColor(item.rarity),
                  fontSize: 12,
                ),
              )),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }
  
  List<Map<String, dynamic>> _getDailyChallenges(GameCharacter character) {
    return [
      {
        'title': 'First Steps',
        'description': 'Add 3 items to your inventory',
        'icon': Icons.inventory,
        'completed': character.inventory.length >= 3,
        'reward': 50,
      },
      {
        'title': 'Power Up',
        'description': 'Gain 1 character level',
        'icon': Icons.trending_up,
        'completed': character.level >= 2,
        'reward': 100,
      },
      {
        'title': 'Explorer',
        'description': 'Complete your first adventure',
        'icon': Icons.explore,
        'completed': false, // Would track adventure completion
        'reward': 150,
      },
    ];
  }
  
  void _joinSpecialEvent() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Winter Solstice Festival'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.celebration,
              size: 64,
              color: RealmOfValorTheme.accentGold,
            ),
            SizedBox(height: 16),
            Text(
              'Welcome to the Winter Solstice Festival!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: RealmOfValorTheme.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'During this special event, you\'ll earn double XP from all activities and have access to exclusive winter-themed items and quests!',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Let\'s Celebrate!'),
          ),
        ],
      ),
    );
  }
  

}