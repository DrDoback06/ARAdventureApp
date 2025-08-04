import 'package:flutter/material.dart';
import '../constants/theme.dart';
import 'simple_adventure_map_screen.dart';

class SimpleHomeScreen extends StatefulWidget {
  const SimpleHomeScreen({super.key});

  @override
  State<SimpleHomeScreen> createState() => _SimpleHomeScreenState();
}

class _SimpleHomeScreenState extends State<SimpleHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RealmOfValorTheme.surfaceDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildQuickActions(),
              const SizedBox(height: 16),
              _buildFeatureCards(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            RealmOfValorTheme.surfaceMedium,
            RealmOfValorTheme.surfaceDark,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RealmOfValorTheme.accentGold, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: RealmOfValorTheme.accentGold,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.sports_esports,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Realm of Valor',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: RealmOfValorTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Adventure Awaits',
                  style: TextStyle(
                    fontSize: 16,
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

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: RealmOfValorTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.map,
                label: 'Adventure Map',
                onTap: _openAdventureMap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.sports_martial_arts,
                label: 'Battle',
                onTap: _openBattle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.person,
                label: 'Character',
                onTap: _openCharacter,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.inventory,
                label: 'Inventory',
                onTap: _openInventory,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: RealmOfValorTheme.surfaceMedium,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: RealmOfValorTheme.accentGold.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: RealmOfValorTheme.accentGold,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Features',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: RealmOfValorTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          icon: Icons.fitness_center,
          title: 'Fitness Tracking',
          description: 'Track your workouts and earn rewards',
          onTap: _openFitness,
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          icon: Icons.emoji_events,
          title: 'Achievements',
          description: 'Complete challenges and unlock achievements',
          onTap: _openAchievements,
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          icon: Icons.people,
          title: 'Social Features',
          description: 'Connect with other adventurers',
          onTap: _openSocial,
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: RealmOfValorTheme.surfaceMedium,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: RealmOfValorTheme.accentGold.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: RealmOfValorTheme.accentGold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                icon,
                color: RealmOfValorTheme.accentGold,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: RealmOfValorTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: RealmOfValorTheme.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _openAdventureMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SimpleAdventureMapScreen(),
      ),
    );
  }

  void _openBattle() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Battle system coming soon!'),
        backgroundColor: RealmOfValorTheme.accentGold,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openCharacter() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Character system coming soon!'),
        backgroundColor: RealmOfValorTheme.accentGold,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openInventory() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Inventory system coming soon!'),
        backgroundColor: RealmOfValorTheme.accentGold,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openFitness() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Fitness tracking coming soon!'),
        backgroundColor: RealmOfValorTheme.accentGold,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openAchievements() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Achievements coming soon!'),
        backgroundColor: RealmOfValorTheme.accentGold,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openSocial() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Social features coming soon!'),
        backgroundColor: RealmOfValorTheme.accentGold,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
} 