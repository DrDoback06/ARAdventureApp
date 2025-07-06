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
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Character overview card
                _buildCharacterOverview(character),
                
                const SizedBox(height: 24),
                
                // Quick stats
                _buildQuickStats(character),
                
                const SizedBox(height: 24),
                
                // Quick actions
                _buildQuickActions(context),
                
                const SizedBox(height: 24),
                
                // Recent activity
                _buildRecentActivity(),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildCharacterOverview(GameCharacter character) {
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
                          Text(
                            'Experience: ${character.experience}/${character.experienceToNext}',
                            style: const TextStyle(fontSize: 12),
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
  
  Widget _buildQuickStats(GameCharacter character) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stats Overview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatItem('ATK', character.getTotalAttack(), Colors.red.shade300)),
                Expanded(child: _buildStatItem('DEF', character.getTotalDefense(), Colors.blue.shade300)),
                Expanded(child: _buildStatItem('HP', character.currentHealth, Colors.green.shade300)),
                Expanded(child: _buildStatItem('MP', character.currentMana, Colors.purple.shade300)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatItem('STR', character.getTotalStrength(), Colors.orange.shade300)),
                Expanded(child: _buildStatItem('DEX', character.getTotalDexterity(), Colors.yellow.shade300)),
                Expanded(child: _buildStatItem('VIT', character.getTotalVitality(), Colors.pink.shade300)),
                Expanded(child: _buildStatItem('ENG', character.getTotalEnergy(), Colors.cyan.shade300)),
              ],
            ),
          ],
        ),
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
  
  Widget _buildQuickActions(BuildContext context) {
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
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _buildActionButton(
                  context,
                  'Create Card',
                  Icons.add_card,
                  Colors.green.shade700,
                  () => _navigateToCardEditor(context),
                ),
                _buildActionButton(
                  context,
                  'View Inventory',
                  Icons.inventory,
                  Colors.blue.shade700,
                  () => _navigateToInventory(context),
                ),
                _buildActionButton(
                  context,
                  'Level Up',
                  Icons.trending_up,
                  Colors.purple.shade700,
                  () => _showLevelUpDialog(context),
                ),
                _buildActionButton(
                  context,
                  'QR Scanner',
                  Icons.qr_code_scanner,
                  Colors.orange.shade700,
                  () => _showComingSoon(context, 'QR Scanner'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const ListTile(
              leading: Icon(Icons.add, color: Colors.green),
              title: Text('Character created'),
              subtitle: Text('Demo Hero was created'),
              trailing: Text('Just now'),
            ),
            const ListTile(
              leading: Icon(Icons.info, color: Colors.blue),
              title: Text('Welcome to Realm of Valor!'),
              subtitle: Text('Start by creating cards and managing your inventory'),
              trailing: Text('Now'),
            ),
          ],
        ),
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
            Text('• QR Code Integration (Coming Soon)'),
            Text('• Adventure Mode (Coming Soon)'),
            Text('• Trading & Duels (Coming Soon)'),
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