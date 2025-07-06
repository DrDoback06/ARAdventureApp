import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/character_provider.dart';
import '../screens/card_editor_screen.dart';
import '../widgets/inventory_widget.dart';
import '../models/character_model.dart';
import '../models/card_model.dart';

/// Main home screen with navigation to different app features
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [];
  
  @override
  void initState() {
    super.initState();
    _initializeScreens();
    _loadDemoData();
  }
  
  void _initializeScreens() {
    _screens.addAll([
      const DashboardTab(),
      const InventoryTab(),
      const CardEditorTab(),
      const MapTab(),
      const SettingsTab(),
    ]);
  }
  
  /// Loads demo data for testing
  void _loadDemoData() {
    final characterProvider = Provider.of<CharacterProvider>(context, listen: false);
    
    // Create demo character
    final demoCharacter = GameCharacter(
      name: 'Demo Hero',
      characterClass: CharacterClass.holy,
      playerId: 'demo_player',
      baseStrength: 15,
      baseDexterity: 12,
      baseVitality: 18,
      baseEnergy: 10,
      level: 5,
      experience: 450,
      experienceToNext: 550,
      statPoints: 3,
      skillPoints: 2,
      gold: 150,
    );
    
    characterProvider.createCharacter(demoCharacter);
    characterProvider.selectCharacter(demoCharacter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
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
            icon: Icon(Icons.create),
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
}

/// Dashboard tab showing character overview and quick actions
class DashboardTab extends StatelessWidget {
  const DashboardTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Realm of Valor'),
        actions: [
          IconButton(
            onPressed: () => _showAboutDialog(context),
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: Consumer<CharacterProvider>(
        builder: (context, characterProvider, child) {
          final character = characterProvider.selectedCharacter;
          
          if (character == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No character selected',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create or select a character to get started',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Character overview card
                    _buildCharacterOverview(character, characterProvider),
                    
                    const SizedBox(height: 16),
                    
                    // Enhanced Quick Actions
                    _buildEnhancedQuickActions(context, characterProvider),
                    
                    const SizedBox(height: 16),
                    
                    // Enhanced Quick stats with stat allocation
                    _buildEnhancedQuickStats(character, characterProvider),
                    
                    const SizedBox(height: 16),
                    
                    // Power Rating Card
                    _buildPowerRatingCard(character),
                    
                    const SizedBox(height: 16),
                    
                    // Daily Challenges
                    _buildDailyChallengesCard(characterProvider),
                    
                    const SizedBox(height: 16),
                    
                    // Real Activity Feed
                    _buildRealActivityCard(characterProvider),
                    
                    const SizedBox(height: 16),
                    
                    // Character Achievements
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
      ),
    );
  }
  
  Widget _buildCharacterOverview(GameCharacter character, CharacterProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Character portrait
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.amber.shade700, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: character.portraitUrl.isNotEmpty
                      ? Image.network(character.portraitUrl, fit: BoxFit.cover)
                      : Icon(Icons.person, size: 40, color: Colors.amber.shade700),
                ),
                
                const SizedBox(width: 16),
                
                // Character info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        character.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Level ${character.level} ${character.characterClass.name.toUpperCase()}',
                        style: TextStyle(
                          color: Colors.amber.shade700,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Experience bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Experience: ${character.experience}/${character.experienceToNext}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              if (character.statPoints > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${character.statPoints} points',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: character.experience / character.experienceToNext,
                            backgroundColor: Colors.grey.shade600,
                            valueColor: AlwaysStoppedAnimation(Colors.amber.shade700),
                          ),
                        ],
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
  
  Widget _buildEnhancedQuickActions(BuildContext context, CharacterProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    'Scan QR',
                    Icons.qr_code_scanner,
                    () => _showEnhancedQRScanner(context, provider),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionButton(
                    'Find Loot',
                    Icons.search,
                    () => _findRandomLoot(context, provider),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionButton(
                    'Quick Duel',
                    Icons.sports_martial_arts,
                    () => _startQuickDuel(context, provider),
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
                    () => _restAtInn(context, provider),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionButton(
                    'Train Skills',
                    Icons.fitness_center,
                    () => _trainSkills(context, provider),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionButton(
                    'Merchant',
                    Icons.store,
                    () => _visitMerchant(context, provider),
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
  
  Widget _buildEnhancedQuickStats(GameCharacter character, CharacterProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Character Stats',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (character.statPoints > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Points: ${character.statPoints}',
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
            if (character.statPoints > 0) ...[
              _buildStatRowWithButton('Strength', character.baseStrength, character.getTotalStrength(), 'strength', provider),
              const SizedBox(height: 8),
              _buildStatRowWithButton('Dexterity', character.baseDexterity, character.getTotalDexterity(), 'dexterity', provider),
              const SizedBox(height: 8),
              _buildStatRowWithButton('Vitality', character.baseVitality, character.getTotalVitality(), 'vitality', provider),
              const SizedBox(height: 8),
              _buildStatRowWithButton('Energy', character.baseEnergy, character.getTotalEnergy(), 'energy', provider),
            ] else ...[
              Row(
                children: [
                  Expanded(child: _buildStatItem('STR', character.getTotalStrength(), Colors.orange.shade300)),
                  Expanded(child: _buildStatItem('DEX', character.getTotalDexterity(), Colors.yellow.shade300)),
                  Expanded(child: _buildStatItem('VIT', character.getTotalVitality(), Colors.pink.shade300)),
                  Expanded(child: _buildStatItem('ENG', character.getTotalEnergy(), Colors.cyan.shade300)),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Derived Stats
            Row(
              children: [
                Expanded(child: _buildStatItem('ATK', character.getTotalAttack(), Colors.red.shade300)),
                Expanded(child: _buildStatItem('DEF', character.getTotalDefense(), Colors.blue.shade300)),
                Expanded(child: _buildStatItem('HP', character.currentHealth, Colors.green.shade300)),
                Expanded(child: _buildStatItem('MP', character.currentMana, Colors.purple.shade300)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRowWithButton(String statName, int baseValue, int totalValue, String statKey, CharacterProvider provider) {
    final equipmentBonus = totalValue - baseValue;
    
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            statName,
            style: const TextStyle(
              color: Colors.white,
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
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (equipmentBonus > 0) ...[
                const Text(
                  ' + ',
                  style: TextStyle(color: Colors.green),
                ),
                Text(
                  equipmentBonus.toString(),
                  style: const TextStyle(
                    color: Colors.green,
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
              color: Colors.amber,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: () => _allocateStatPoint(statKey, provider),
          icon: const Icon(Icons.add_circle, color: Colors.amber),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

  void _allocateStatPoint(String statName, CharacterProvider provider) {
    // This would need to be implemented in your CharacterProvider
    // For now, show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Allocated 1 point to ${statName.toUpperCase()}!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }
  
  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
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
                Text(
                  'Power Rating',
                  style: Theme.of(context).textTheme.titleLarge,
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
                      const Text(
                        'Combat effectiveness rating',
                        style: TextStyle(
                          color: Colors.grey,
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
            Text(
              'Daily Challenges',
              style: Theme.of(context).textTheme.titleLarge,
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
        Icon(icon, color: Colors.amber, size: 20),
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
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    progress,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progressValue,
                backgroundColor: Colors.grey.shade700,
                valueColor: const AlwaysStoppedAnimation(Colors.amber),
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
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleLarge,
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
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No recent activity',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Start playing to see your adventures here!',
                      style: TextStyle(
                        color: Colors.grey,
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

  Widget _buildRealActivityItem(dynamic activity) {
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
          Icon(iconData, size: 16, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.action,
                  style: const TextStyle(color: Colors.white),
                ),
                if (activity.details != null)
                  Text(
                    activity.details!,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            activity.timeAgo,
            style: const TextStyle(
              color: Colors.grey,
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
            Text(
              'Achievements',
              style: Theme.of(context).textTheme.titleLarge,
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
        color: unlocked ? Colors.amber : Colors.grey.shade700,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: unlocked ? Colors.black : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: unlocked ? Colors.black : Colors.grey,
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
                            color: Colors.amber,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.star,
                            color: Colors.black,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'LEVEL UP!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Level ${character.level}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '+${character.statPoints} Stat Points',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '+${character.skillPoints} Skill Points',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.blue,
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

  // Helper methods
  int _calculatePowerRating(GameCharacter character) {
    return (character.getTotalStrength() * 2) + 
           (character.getTotalDexterity() * 2) + 
           (character.getTotalVitality() * 1.5).round() + 
           (character.getTotalEnergy() * 1.5).round() + 
           (character.level * 10) +
           (character.equipment.getAllEquipped().length * 5);
  }

  Map<String, dynamic> _getPowerTier(int powerRating) {
    if (powerRating < 50) {
      return {'name': 'Novice', 'color': Colors.grey};
    } else if (powerRating < 100) {
      return {'name': 'Apprentice', 'color': Colors.green};
    } else if (powerRating < 200) {
      return {'name': 'Warrior', 'color': Colors.blue};
    } else if (powerRating < 350) {
      return {'name': 'Champion', 'color': Colors.purple};
    } else if (powerRating < 500) {
      return {'name': 'Hero', 'color': Colors.orange};
    } else {
      return {'name': 'Legend', 'color': Colors.red};
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
        'unlocked': character.equipment.getAllEquipped().isNotEmpty,
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

  // Enhanced Quick Action Methods
  void _showEnhancedQRScanner(BuildContext context, CharacterProvider provider) {
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
              color: Colors.amber,
            ),
            const SizedBox(height: 16),
            const Text(
              'Scan Physical Cards',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Point your camera at a physical card to add it to your collection',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQRTypeButton('Item', Icons.inventory, () => _scanItemCard(context, provider)),
                _buildQRTypeButton('Quest', Icons.assignment, () => _scanQuestCard(context, provider)),
                _buildQRTypeButton('Enemy', Icons.sports_martial_arts, () => _scanEnemyCard(context, provider)),
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

  void _scanItemCard(BuildContext context, CharacterProvider provider) {
    provider.scanQRCode('item_simulation');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scanned item card! (Simulation)'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _scanQuestCard(BuildContext context, CharacterProvider provider) {
    provider.scanQRCode('quest_simulation');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quest Discovered!'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment, size: 64, color: Colors.amber),
            SizedBox(height: 16),
            Text('A new quest has been added to your map!'),
            SizedBox(height: 8),
            Text('Check the Map tab to start your adventure.'),
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
              // Switch to Map tab (you'd need to implement this navigation)
            },
            child: const Text('Go to Map'),
          ),
        ],
      ),
    );
  }

  void _scanEnemyCard(BuildContext context, CharacterProvider provider) {
    provider.scanQRCode('enemy_simulation');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enemy Encountered!'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_martial_arts, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('A wild Goblin appears!'),
            SizedBox(height: 8),
            Text('Prepare for battle!'),
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
              _startQuickDuel(context, provider);
            },
            child: const Text('Fight!'),
          ),
        ],
      ),
    );
  }

  void _findRandomLoot(BuildContext context, CharacterProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Loot Found!'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.card_giftcard,
              size: 64,
              color: Colors.amber,
            ),
            SizedBox(height: 16),
            Text(
              'Magic Sword',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'RARE WEAPON',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text('A shimmering blade found in the depths of the dungeon.'),
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

  void _startQuickDuel(BuildContext context, CharacterProvider provider) {
    final character = provider.selectedCharacter;
    if (character == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Duel: ${character.name} vs Shadow Warrior'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sports_martial_arts, size: 64, color: Colors.amber),
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
              _simulateDuel(context, provider);
            },
            child: const Text('Fight!'),
          ),
        ],
      ),
    );
  }

  void _simulateDuel(BuildContext context, CharacterProvider provider) {
    final character = provider.selectedCharacter!;
    final powerRating = _calculatePowerRating(character);
    final victory = powerRating > 50 + (DateTime.now().millisecond % 100);
    
    if (victory) {
      final expReward = 150 + (DateTime.now().millisecond % 100);
      provider.winDuel('Shadow Warrior', expReward);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Victory! Defeated Shadow Warrior (+$expReward XP)'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      provider.loseDuel('Shadow Warrior');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Defeat! Shadow Warrior was too strong this time.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _restAtInn(BuildContext context, CharacterProvider provider) {
    if (provider.selectedCharacter != null) {
      provider.addExperience(provider.selectedCharacter!.id, 50, source: 'Rest at Inn');
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rest at Inn'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hotel, size: 64, color: Colors.blue),
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

  void _trainSkills(BuildContext context, CharacterProvider provider) {
    final character = provider.selectedCharacter;
    if (character == null) return;
    
    if (character.skillPoints > 0) {
      provider.addExperience(character.id, 25, source: 'Skill Training');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Training complete! Check the Inventory tab to spend skill points.'),
          backgroundColor: Colors.blue,
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

  void _visitMerchant(BuildContext context, CharacterProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Merchant\'s Shop'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.store, size: 64, color: Colors.amber),
            SizedBox(height: 16),
            Text('Welcome to my shop, adventurer!'),
            SizedBox(height: 8),
            Text('Trading system coming soon...'),
            SizedBox(height: 16),
            Text('For now, have a free potion!'),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Received Health Potion from the merchant!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Take Potion'),
          ),
        ],
      ),
    );
  }

  void _showFullActivityLog(List<dynamic> activities) {
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
  
  void _navigateToCardEditor(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CardEditorScreen(),
      ),
    );
  }
  
  void _navigateToInventory(BuildContext context) {
    // This would navigate to a full inventory screen
    // For now, we'll show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Use the Inventory tab at the bottom')),
    );
  }
  
  void _showLevelUpDialog(BuildContext context) {
    final characterProvider = Provider.of<CharacterProvider>(context, listen: false);
    final character = characterProvider.selectedCharacter;
    
    if (character == null) return;
    
    if (character.experience >= character.experienceToNext) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Level Up!'),
          content: Text('${character.name} can level up! This will grant stat and skill points.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                characterProvider.levelUpCharacter(character.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Character leveled up!')),
                );
              },
              child: const Text('Level Up'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough experience to level up')),
      );
    }
  }
  
  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon!')),
    );
  }
  
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Realm of Valor'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Realm of Valor is a hybrid card-based and role-playing game.'),
            SizedBox(height: 12),
            Text('Features:'),
            Text('• Card Creator/Editor'),
            Text('• Character Management'),
            Text('• Drag & Drop Inventory'),
            Text('• Real-time Stat Updates'),
            Text('• Activity Tracking'),
            Text('• Power Rating System'),
            Text('• Daily Challenges'),
            Text('• Achievement System'),
            Text('• Enhanced QR Integration'),
            Text('• Adventure Mode'),
            Text('• Duel System'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Inventory tab showing character inventory and equipment
class InventoryTab extends StatelessWidget {
  const InventoryTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
      ),
      body: Consumer<CharacterProvider>(
        builder: (context, characterProvider, child) {
          final character = characterProvider.selectedCharacter;
          
          if (character == null) {
            return const Center(
              child: Text('No character selected'),
            );
          }
          
          return InventoryWidget(
            character: character,
            onStatsChanged: () {
              // Refresh character data when stats change
              characterProvider.refreshCharacter(character.id);
            },
          );
        },
      ),
    );
  }
}

/// Card editor tab for creating and managing cards
class CardEditorTab extends StatelessWidget {
  const CardEditorTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Editor'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.create, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Card Editor',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Create and edit cards for your game',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CardEditorScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Card'),
      ),
    );
  }
}

/// Map tab for geo-location features
class MapTab extends StatelessWidget {
  const MapTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Map & Events',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Geo-location events and adventures',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 16),
            Text(
              'Coming Soon!',
              style: TextStyle(color: Colors.amber, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

/// Settings tab for app configuration
class SettingsTab extends StatelessWidget {
  const SettingsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'App configuration and preferences',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 16),
            Text(
              'Coming Soon!',
              style: TextStyle(color: Colors.amber, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}