import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../providers/character_provider.dart';
import '../providers/activity_provider.dart';
import '../services/audio_service.dart';
import '../screens/battleground_screen.dart';
import '../screens/character_creation_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/simple_adventure_map_screen.dart';
import '../models/character_model.dart';
import '../models/card_model.dart';
import '../widgets/fitness_tracker_widget.dart';
import '../widgets/daily_quests_widget.dart';
import '../widgets/achievements_widget.dart';
import '../widgets/social_features_widget.dart';
import '../widgets/analytics_dashboard_widget.dart';
import '../widgets/skill_tree_widget.dart';
import '../widgets/damage_calculator_widget.dart';
import '../widgets/qr_scanner_widget.dart';
import '../widgets/mobile_window_manager.dart';
import '../widgets/activity_tracking_widget.dart';
import '../widgets/achievement_notification_widget.dart';
import 'phase3_test_screen.dart';

import 'epic_adventure_map_screen.dart';
import 'battle_screen.dart';
import 'inventory_screen.dart';
import 'character_creation_screen.dart';
import 'achievements_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return AchievementNotificationOverlay(
      child: MobileWindowManager(
        child: Scaffold(
          backgroundColor: RealmOfValorTheme.surfaceDark,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  Consumer<CharacterProvider>(
                    builder: (context, characterProvider, child) {
                      return Column(
                        children: [
                          _buildCharacterCard(characterProvider),
                          const SizedBox(height: 16),
                          _buildActivityTrackingSection(),
                          const SizedBox(height: 16),
                          _buildQuickActions(),
                          const SizedBox(height: 16),
                          _buildFeatureCards(),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
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
                Text(
                  'Your Adventure Awaits',
                  style: TextStyle(
                    fontSize: 16,
                    color: RealmOfValorTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              print('DEBUG: Settings button pressed');
              AudioService.instance.playSound(AudioType.buttonClick);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            icon: Icon(
              Icons.settings,
              color: RealmOfValorTheme.accentGold,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterCard(CharacterProvider characterProvider) {
    final character = characterProvider.currentCharacter;
    if (character == null) {
      return _buildCreateCharacterCard();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RealmOfValorTheme.accentGold, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person,
                color: RealmOfValorTheme.accentGold,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Character',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: RealmOfValorTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      character.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: RealmOfValorTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Level ${character.level} ${_getClassName(character.characterClass)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: RealmOfValorTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: character.experience / (character.level * 1000),
                      backgroundColor: RealmOfValorTheme.surfaceDark,
                      valueColor: AlwaysStoppedAnimation<Color>(RealmOfValorTheme.accentGold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'XP: ${character.experience} / ${character.level * 1000}',
                      style: TextStyle(
                        fontSize: 12,
                        color: RealmOfValorTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailedStats(character),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(GameCharacter character) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard('Strength', '${character.baseStrength + character.allocatedStrength}', Icons.fitness_center),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard('Dexterity', '${character.baseDexterity + character.allocatedDexterity}', Icons.speed),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard('Vitality', '${character.baseVitality + character.allocatedVitality}', Icons.favorite),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard('Energy', '${character.baseEnergy + character.allocatedEnergy}', Icons.auto_awesome),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard('Health', '${character.maxHealth}', Icons.favorite_border),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard('Mana', '${character.maxMana}', Icons.auto_awesome_outlined),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard('Gold', '${character.characterData['gold'] ?? 0}', Icons.monetization_on),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard('Points', '${character.availableStatPoints + character.availableSkillPoints}', Icons.stars),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceDark,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: RealmOfValorTheme.accentGold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: RealmOfValorTheme.accentGold,
            size: 16,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.accentGold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateCharacterCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RealmOfValorTheme.accentGold, width: 1),
      ),
      child: Column(
        children: [
          Icon(
            Icons.person_add,
            color: RealmOfValorTheme.accentGold,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Create Your Character',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start your adventure by creating your first character',
            style: TextStyle(
              fontSize: 14,
              color: RealmOfValorTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              print('DEBUG: Create character button pressed');
              AudioService.instance.playSound(AudioType.buttonClick);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CharacterCreationScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Character'),
            style: ElevatedButton.styleFrom(
              backgroundColor: RealmOfValorTheme.accentGold,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTrackingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.fitness_center,
              color: RealmOfValorTheme.accentGold,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Activity Tracking',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: RealmOfValorTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const ActivityTrackingWidget(),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RealmOfValorTheme.accentGold, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flash_on,
                color: RealmOfValorTheme.accentGold,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: RealmOfValorTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.sports_esports,
                  label: 'Battleground',
                  onTap: _openBattleground,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.map,
                  label: 'Adventure Map',
                  onTap: _openAdventureMap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.qr_code_scanner,
                  label: 'Scan Cards',
                  onTap: _openQRScanner,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.calculate,
                  label: 'Calculator',
                  onTap: _openDamageCalculator,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        print('DEBUG: Quick action button pressed: $label');
        AudioService.instance.playSound(AudioType.buttonClick);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: RealmOfValorTheme.surfaceDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: RealmOfValorTheme.accentGold.withOpacity(0.5),
            width: 1,
          ),
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
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: RealmOfValorTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCards() {
    return Column(
      children: [
        _buildFeatureCard(
          icon: Icons.assignment,
          title: 'Daily Quests',
          description: 'Complete quests and earn rewards',
          onTap: _openDailyQuests,
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          icon: Icons.emoji_events,
          title: 'Achievements',
          description: 'Unlock achievements and track progress',
          onTap: _openAchievements,
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          icon: Icons.people,
          title: 'Social Features',
          description: 'Connect with friends and join guilds',
          onTap: _openSocialFeatures,
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          icon: Icons.analytics,
          title: 'Analytics',
          description: 'Track your performance and progress',
          onTap: _openAnalytics,
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          icon: Icons.science,
          title: 'Phase 3 Test',
          description: 'Test all Phase 3 features',
          onTap: _openPhase3Test,
        ),
        const SizedBox(height: 12),
        _buildProgressionCard(),
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
          border: Border.all(color: RealmOfValorTheme.accentGold, width: 1),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: RealmOfValorTheme.accentGold,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: RealmOfValorTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: RealmOfValorTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: RealmOfValorTheme.accentGold,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _openBattleground() {
    print('DEBUG: Opening battleground');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const BattlegroundScreen(),
      ),
    );
  }

  void _openQRScanner() {
    print('DEBUG: Opening QR scanner');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const QRScannerWidget(),
      ),
    );
  }

  void _openDamageCalculator() {
    print('DEBUG: Opening damage calculator');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DamageCalculatorWidget(),
      ),
    );
  }

  void _openSkillTree() {
    print('DEBUG: Opening skill tree');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SkillTreeWidget(),
      ),
    );
  }

  void _openFitnessTracker() {
    print('DEBUG: Opening fitness tracker');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FitnessTrackerWidget(),
      ),
    );
  }

  void _openDailyQuests() {
    print('DEBUG: Opening daily quests');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DailyQuestsWidget(),
      ),
    );
  }

  void _openAchievements() {
    print('DEBUG: Opening achievements');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AchievementsScreen(),
      ),
    );
  }

  void _openSocialFeatures() {
    print('DEBUG: Opening social features');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SocialFeaturesWidget(),
      ),
    );
  }

  void _openAnalytics() {
    print('DEBUG: Opening analytics');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AnalyticsDashboardWidget(),
      ),
    );
  }

  void _openPhase3Test() {
    print('DEBUG: Opening Phase 3 test screen');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const Phase3TestScreen(),
      ),
    );
  }

  void _openInventory() {
    print('DEBUG: Opening inventory');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const InventoryScreen(),
      ),
    );
  }

  void _openAdventureMap() {
    print('DEBUG: Opening adventure map');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EpicAdventureMapScreen(),
      ),
    );
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

  Widget _buildProgressionCard() {
    return Consumer<CharacterProvider>(
      builder: (context, characterProvider, child) {
        final character = characterProvider.currentCharacter;
        if (character == null) return const SizedBox.shrink();

        final progressToNextLevel = character.experience / (character.level * 1000);
        final nextLevelXP = character.level * 1000;
        final remainingXP = nextLevelXP - character.experience;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: RealmOfValorTheme.surfaceMedium,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: RealmOfValorTheme.accentGold, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    color: RealmOfValorTheme.accentGold,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Character Progression',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: RealmOfValorTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Level ${character.level}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: RealmOfValorTheme.accentGold,
                          ),
                        ),
                        Text(
                          'XP: ${character.experience} / $nextLevelXP',
                          style: TextStyle(
                            fontSize: 12,
                            color: RealmOfValorTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progressToNextLevel,
                          backgroundColor: RealmOfValorTheme.surfaceDark,
                          valueColor: AlwaysStoppedAnimation<Color>(RealmOfValorTheme.accentGold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    children: [
                      _buildProgressionStat('Stat Points', character.availableStatPoints, Icons.fitness_center),
                      const SizedBox(height: 8),
                      _buildProgressionStat('Skill Points', character.availableSkillPoints, Icons.stars),
                    ],
                  ),
                ],
              ),
              if (character.availableStatPoints > 0 || character.availableSkillPoints > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      if (character.availableStatPoints > 0)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showStatAllocation(character),
                            icon: const Icon(Icons.add),
                            label: const Text('Allocate Stats'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: RealmOfValorTheme.accentGold,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      if (character.availableStatPoints > 0 && character.availableSkillPoints > 0)
                        const SizedBox(width: 8),
                      if (character.availableSkillPoints > 0)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _openSkillTree(),
                            icon: const Icon(Icons.account_tree),
                            label: const Text('Skill Tree'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: RealmOfValorTheme.surfaceDark,
                              foregroundColor: RealmOfValorTheme.accentGold,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressionStat(String label, int value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceDark,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: RealmOfValorTheme.accentGold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: RealmOfValorTheme.accentGold,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.accentGold,
            ),
          ),
        ],
      ),
    );
  }

  void _showStatAllocation(GameCharacter character) {
    print('DEBUG: Showing stat allocation dialog');
    AudioService.instance.playSound(AudioType.buttonClick);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RealmOfValorTheme.surfaceMedium,
        title: Text(
          'Allocate Stat Points',
          style: TextStyle(
            color: RealmOfValorTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You have ${character.availableStatPoints} stat points to allocate.',
              style: TextStyle(
                color: RealmOfValorTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatAllocationRow('Strength', character.baseStrength + character.allocatedStrength, Icons.fitness_center),
            const SizedBox(height: 8),
            _buildStatAllocationRow('Dexterity', character.baseDexterity + character.allocatedDexterity, Icons.speed),
            const SizedBox(height: 8),
            _buildStatAllocationRow('Vitality', character.baseVitality + character.allocatedVitality, Icons.favorite),
            const SizedBox(height: 8),
            _buildStatAllocationRow('Energy', character.baseEnergy + character.allocatedEnergy, Icons.auto_awesome),
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Stat allocation coming soon!'),
                  backgroundColor: RealmOfValorTheme.accentGold,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RealmOfValorTheme.accentGold,
              foregroundColor: Colors.white,
            ),
            child: const Text('Allocate'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatAllocationRow(String statName, int currentValue, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: RealmOfValorTheme.accentGold,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            statName,
            style: TextStyle(
              color: RealmOfValorTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(
          '$currentValue',
          style: TextStyle(
            color: RealmOfValorTheme.accentGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            print('DEBUG: Add stat button pressed for $statName');
            AudioService.instance.playSound(AudioType.buttonClick);
            // TODO: Implement stat allocation
          },
          icon: Icon(
            Icons.add_circle_outline,
            color: RealmOfValorTheme.accentGold,
            size: 20,
          ),
        ),
      ],
    );
  }
}