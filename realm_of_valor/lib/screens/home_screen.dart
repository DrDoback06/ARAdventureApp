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
                    'Scan QR',
                    Icons.qr_code_scanner,
                    () => _scanQRCode(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionButton(
                    'Find Loot',
                    Icons.search,
                    () => _findRandomLoot(provider),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionButton(
                    'Quick Duel',
                    Icons.sports_martial_arts,
                    () => _startQuickDuel(provider),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    'Rest at Inn',
                    Icons.hotel,
                    () => _restAtInn(provider),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionButton(
                    'Train Skills',
                    Icons.fitness_center,
                    () => _trainSkills(provider),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionButton(
                    'Merchant',
                    Icons.store,
                    () => _visitMerchant(provider),
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
    final achievements = _getCharacterAchievements(character);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Achievements',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: RealmOfValorTheme.accentGold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: achievements.map((achievement) => 
                Expanded(
                  child: _buildAchievementBadge(
                    achievement['title'],
                    achievement['icon'],
                    achievement['unlocked'],
                  ),
                ),
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementBadge(String title, IconData icon, bool unlocked) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: unlocked ? RealmOfValorTheme.accentGold : RealmOfValorTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: unlocked ? RealmOfValorTheme.primaryDark : RealmOfValorTheme.textSecondary,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: unlocked ? RealmOfValorTheme.primaryDark : RealmOfValorTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
            const SizedBox(height: 8),
            Text(
              'Power Rating: ${_calculatePowerRating(character)}',
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

  void _completeAdventure(String adventureName, GameCharacter character) {
    final characterProvider = context.read<CharacterProvider>();
    final cardService = context.read<CardService>();
    
    // Calculate rewards based on adventure and character level
    int expReward = 100;
    List<CardInstance>? itemRewards;
    
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
          itemRewards = [CardInstance(card: crystal)];
        }
        break;
      case 'Sky Temple':
        expReward = 350 + (character.level * 20);
        if (DateTime.now().millisecond % 2 == 0) {
          final artifact = cardService.generateRandomCard();
          itemRewards = [CardInstance(card: artifact)];
        }
        break;
      case 'Dragon\'s Lair':
        expReward = 500 + (character.level * 25);
        // Always get treasure from dragon
        final treasure1 = cardService.generateRandomCard();
        final treasure2 = cardService.generateRandomCard();
        itemRewards = [CardInstance(card: treasure1), CardInstance(card: treasure2)];
        break;
    }
    
    // Complete the adventure with rewards
    characterProvider.completeAdventure(adventureName, expReward, itemRewards);
    
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
            Text(
              'Adventure completed successfully!',
              style: const TextStyle(
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
            if (itemRewards != null) ...[
              const SizedBox(height: 8),
              Text(
                'Found ${itemRewards.length} treasure${itemRewards.length > 1 ? 's' : ''}!',
                style: const TextStyle(
                  color: RealmOfValorTheme.accentGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ...itemRewards.map((item) => Text(
                '• ${item.card.name}',
                style: TextStyle(
                  color: RealmOfValorTheme.getRarityColor(item.card.rarity),
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

  void _scanItemCard(CharacterProvider provider) {
    final cardService = context.read<CardService>();
    final randomCard = cardService.generateRandomCard();
    final cardInstance = CardInstance(card: randomCard);
    
    provider.addToInventory(cardInstance);
    provider.scanQRCode('item_${randomCard.id}');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Scanned item: ${randomCard.name}'),
        backgroundColor: RealmOfValorTheme.experienceGreen,
      ),
    );
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

  void _visitMerchant(CharacterProvider provider) {
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