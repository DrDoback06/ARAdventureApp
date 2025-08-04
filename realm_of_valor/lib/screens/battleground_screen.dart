import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../models/character_model.dart';
import '../models/battle_model.dart';
import '../models/card_model.dart';
import '../providers/character_provider.dart';
import '../providers/battle_controller.dart';
import '../services/ai_battle_service.dart';
import '../services/advanced_battle_service.dart';
import '../services/battle_service.dart';
import '../services/character_progression_service.dart' as progression;
import '../services/audio_service.dart';
import '../widgets/ai_opponent_widget.dart';
import '../widgets/lobby_widget.dart';
import '../widgets/matchmaking_widget.dart';
import 'battle_screen.dart';
import 'enhanced_battle_screen.dart'; // Changed from advanced_battle_screen.dart

class BattlegroundScreen extends StatefulWidget {
  const BattlegroundScreen({super.key});

  @override
  State<BattlegroundScreen> createState() => _BattlegroundScreenState();
}

class _BattlegroundScreenState extends State<BattlegroundScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final BattleService _battleService = BattleService();
  final AdvancedBattleService _advancedBattleService = AdvancedBattleService.instance;
  final AIBattleService _aiBattleService = AIBattleService.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RealmOfValorTheme.surfaceDark,
      appBar: AppBar(
        title: const Text('Battleground'),
        backgroundColor: RealmOfValorTheme.surfaceDark,
        foregroundColor: RealmOfValorTheme.textPrimary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: RealmOfValorTheme.accentGold,
          labelColor: RealmOfValorTheme.accentGold,
          unselectedLabelColor: RealmOfValorTheme.textSecondary,
          tabs: const [
            Tab(text: 'AI Battle'),
            Tab(text: 'Arena'),
            Tab(text: 'Friends'),
            Tab(text: 'Matchmaking'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAIBattleTab(),
          _buildArenaTab(),
          _buildFriendsTab(),
          _buildMatchmakingTab(),
        ],
      ),
    );
  }

  Widget _buildAIBattleTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBattleHeader('AI Opponents', 'Challenge computer-controlled enemies with advanced AI'),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                AIOpponentWidget(
                  name: 'Goblin Scout',
                  description: 'Fast and agile, uses stealth tactics',
                  difficulty: AIDifficulty.easy,
                  strategy: AIStrategy.aggressive,
                  onTap: () => _startAdvancedAIBattle('Goblin Scout', AIDifficulty.easy),
                ),
                AIOpponentWidget(
                  name: 'Orc Warrior',
                  description: 'Strong and brutal, charges head-on',
                  difficulty: AIDifficulty.medium,
                  strategy: AIStrategy.aggressive,
                  onTap: () => _startAdvancedAIBattle('Orc Warrior', AIDifficulty.medium),
                ),
                AIOpponentWidget(
                  name: 'Dark Mage',
                  description: 'Wields powerful elemental spells',
                  difficulty: AIDifficulty.hard,
                  strategy: AIStrategy.defensive,
                  onTap: () => _startAdvancedAIBattle('Dark Mage', AIDifficulty.hard),
                ),
                AIOpponentWidget(
                  name: 'Dragon Knight',
                  description: 'Legendary warrior with dragon powers',
                  difficulty: AIDifficulty.legendary,
                  strategy: AIStrategy.balanced,
                  onTap: () => _startAdvancedAIBattle('Dragon Knight', AIDifficulty.legendary),
                ),
                AIOpponentWidget(
                  name: 'Shadow Assassin',
                  description: 'Deadly stealth and poison attacks',
                  difficulty: AIDifficulty.expert,
                  strategy: AIStrategy.aggressive,
                  onTap: () => _startAdvancedAIBattle('Shadow Assassin', AIDifficulty.expert),
                ),
                AIOpponentWidget(
                  name: 'Ancient Guardian',
                  description: 'Immortal protector with divine powers',
                  difficulty: AIDifficulty.legendary,
                  strategy: AIStrategy.defensive,
                  onTap: () => _startAdvancedAIBattle('Ancient Guardian', AIDifficulty.legendary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArenaTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBattleHeader('Arena Challenges', 'Special battle scenarios and tournaments'),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildArenaChallenge(
                  'Daily Arena',
                  'Complete daily challenges for rewards',
                  Icons.calendar_today,
                  Colors.green,
                  () => _startArenaBattle('Daily Arena'),
                ),
                const SizedBox(height: 12),
                _buildArenaChallenge(
                  'Weekly Tournament',
                  'Compete against other players',
                  Icons.emoji_events,
                  Colors.orange,
                  () => _startArenaBattle('Weekly Tournament'),
                ),
                const SizedBox(height: 12),
                _buildArenaChallenge(
                  'Boss Rush',
                  'Face multiple bosses in sequence',
                  Icons.whatshot,
                  Colors.red,
                  () => _startArenaBattle('Boss Rush'),
                ),
                const SizedBox(height: 12),
                _buildArenaChallenge(
                  'Survival Mode',
                  'Endless waves of enemies',
                  Icons.all_inclusive,
                  Colors.purple,
                  () => _startArenaBattle('Survival Mode'),
                ),
                const SizedBox(height: 12),
                _buildArenaChallenge(
                  'Elite Challenge',
                  'High-level enemies with special rewards',
                  Icons.star,
                  Colors.yellow,
                  () => _startArenaBattle('Elite Challenge'),
                ),
                const SizedBox(height: 12),
                _buildArenaChallenge(
                  'Advanced Combat',
                  'Use advanced battle mechanics and combos',
                  Icons.sports_martial_arts,
                  Colors.blue,
                  () => _startAdvancedCombat(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBattleHeader('Friend Battles', 'Challenge your friends to duels'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _createLobby,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Lobby'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RealmOfValorTheme.accentGold,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _joinLobby,
                  icon: const Icon(Icons.group),
                  label: const Text('Join Lobby'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RealmOfValorTheme.surfaceMedium,
                    foregroundColor: RealmOfValorTheme.accentGold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              children: [
                _buildFriendSection('Online Friends', [
                  _buildFriendItem('Alex', 'Level 15 Paladin', true),
                  _buildFriendItem('Sarah', 'Level 12 Sorceress', true),
                  _buildFriendItem('Mike', 'Level 18 Barbarian', false),
                ]),
                const SizedBox(height: 16),
                _buildFriendSection('Recent Battles', [
                  _buildBattleHistoryItem('Victory vs Alex', '2 hours ago', true),
                  _buildBattleHistoryItem('Defeat vs Sarah', '1 day ago', false),
                  _buildBattleHistoryItem('Victory vs Mike', '3 days ago', true),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchmakingTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBattleHeader('Quick Match', 'Find opponents for instant battles'),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              children: [
                _buildMatchmakingOption(
                  'Quick Duel',
                  'Find a random opponent',
                  Icons.flash_on,
                  () => _startQuickMatch(),
                ),
                const SizedBox(height: 12),
                _buildMatchmakingOption(
                  'Ranked Battle',
                  'Compete for ranking points',
                  Icons.trending_up,
                  () => _startRankedMatch(),
                ),
                const SizedBox(height: 12),
                _buildMatchmakingOption(
                  'Team Battle',
                  '2v2 or 3v3 team matches',
                  Icons.group,
                  () => _startTeamMatch(),
                ),
                const SizedBox(height: 12),
                _buildMatchmakingOption(
                  'Custom Game',
                  'Create or join custom matches',
                  Icons.settings,
                  () => _startCustomGame(),
                ),
                const SizedBox(height: 12),
                _buildMatchmakingOption(
                  'Advanced Matchmaking',
                  'Use advanced battle mechanics',
                  Icons.sports_martial_arts,
                  () => _startAdvancedMatchmaking(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBattleHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: RealmOfValorTheme.textPrimary,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: RealmOfValorTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildArenaChallenge(String title, String description, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        AudioService.instance.playSound(AudioType.buttonClick);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: RealmOfValorTheme.surfaceMedium,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: RealmOfValorTheme.textPrimary,
                    ),
                  ),
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

  Widget _buildFriendSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: RealmOfValorTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildFriendItem(String name, String details, bool isOnline) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOnline ? Colors.green : RealmOfValorTheme.accentGold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: RealmOfValorTheme.accentGold,
            child: Text(
              name.substring(0, 1),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: RealmOfValorTheme.textPrimary,
                  ),
                ),
                Text(
                  details,
                  style: TextStyle(
                    fontSize: 12,
                    color: RealmOfValorTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOnline ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBattleHistoryItem(String title, String time, bool isVictory) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isVictory ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isVictory ? Icons.check_circle : Icons.cancel,
            color: isVictory ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: RealmOfValorTheme.textPrimary,
                  ),
                ),
                Text(
                  time,
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
    );
  }

  Widget _buildMatchmakingOption(String title, String description, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        AudioService.instance.playSound(AudioType.buttonClick);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: RealmOfValorTheme.surfaceMedium,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: RealmOfValorTheme.accentGold.withOpacity(0.5), width: 1),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: RealmOfValorTheme.accentGold,
              size: 24,
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

  // Advanced AI Battle Methods
  void _startAdvancedAIBattle(String opponentName, AIDifficulty difficulty) {
    AudioService.instance.playSound(AudioType.buttonClick);
    
    final characterProvider = context.read<CharacterProvider>();
    final playerCharacter = characterProvider.currentCharacter;
    
    if (playerCharacter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a character first')),
      );
      return;
    }

    // Create AI opponent with advanced stats
    final aiCharacter = _createAdvancedAICharacter(opponentName, difficulty);
    
    // Create battle using the main battle system
    final battle = Battle(
      id: 'battle_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Battle against $opponentName',
      type: BattleType.pve,
      status: BattleStatus.active,
      players: [
        BattlePlayer(
          id: playerCharacter.id,
          name: playerCharacter.name,
          character: playerCharacter,
          currentHealth: playerCharacter.maxHealth,
          currentMana: playerCharacter.maxMana,
          maxHealth: playerCharacter.maxHealth,
          maxMana: playerCharacter.maxMana,
          isActive: true,
        ),
        BattlePlayer(
          id: 'ai_${opponentName.toLowerCase().replaceAll(' ', '_')}',
          name: opponentName,
          character: aiCharacter,
          currentHealth: aiCharacter.maxHealth,
          currentMana: aiCharacter.maxMana,
          maxHealth: aiCharacter.maxHealth,
          maxMana: aiCharacter.maxMana,
          isActive: false,
        ),
      ],
      currentTurn: 0,
      currentPlayerId: playerCharacter.id,
      battleLog: [],
    );

    // Navigate to the enhanced battle screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedBattleScreen(battle: battle),
      ),
    );
  }

  GameCharacter _createAdvancedAICharacter(String name, AIDifficulty difficulty) {
    final baseStats = _getDifficultyBaseStats(difficulty);
    final level = _getDifficultyLevel(difficulty);
    
    return GameCharacter(
      name: name,
      characterClass: _getRandomCharacterClass(),
      level: level,
      experience: level * 1000,
      availableStatPoints: 0,
      availableSkillPoints: 0,
    );
  }

  Map<String, int> _getDifficultyBaseStats(AIDifficulty difficulty) {
    switch (difficulty) {
      case AIDifficulty.easy:
        return {'strength': 8, 'dexterity': 10, 'vitality': 12, 'energy': 6};
      case AIDifficulty.medium:
        return {'strength': 12, 'dexterity': 14, 'vitality': 16, 'energy': 10};
      case AIDifficulty.hard:
        return {'strength': 16, 'dexterity': 18, 'vitality': 20, 'energy': 14};
      case AIDifficulty.expert:
        return {'strength': 20, 'dexterity': 22, 'vitality': 24, 'energy': 18};
      case AIDifficulty.legendary:
        return {'strength': 25, 'dexterity': 27, 'vitality': 30, 'energy': 25};
    }
  }

  int _getDifficultyLevel(AIDifficulty difficulty) {
    switch (difficulty) {
      case AIDifficulty.easy:
        return 5;
      case AIDifficulty.medium:
        return 10;
      case AIDifficulty.hard:
        return 15;
      case AIDifficulty.expert:
        return 20;
      case AIDifficulty.legendary:
        return 25;
    }
  }

  CharacterClass _getRandomCharacterClass() {
    final classes = CharacterClass.values;
    return classes[DateTime.now().millisecond % classes.length];
  }

  // Arena Battle Methods
  void _startArenaBattle(String arenaType) {
    AudioService.instance.playSound(AudioType.buttonClick);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting $arenaType with advanced battle mechanics...'),
        backgroundColor: RealmOfValorTheme.accentGold,
      ),
    );
    
    // TODO: Implement arena battle with advanced mechanics
  }

  void _startAdvancedCombat() {
    AudioService.instance.playSound(AudioType.buttonClick);
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdvancedCombatScreen(),
      ),
    );
  }

  // Lobby Methods
  void _createLobby() {
    AudioService.instance.playSound(AudioType.buttonClick);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Creating lobby with advanced battle options...'),
        backgroundColor: RealmOfValorTheme.accentGold,
      ),
    );
    
    // TODO: Implement lobby creation with advanced options
  }

  void _joinLobby() {
    AudioService.instance.playSound(AudioType.buttonClick);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Joining lobby...'),
        backgroundColor: RealmOfValorTheme.accentGold,
      ),
    );
    
    // TODO: Implement lobby joining
  }

  // Matchmaking Methods
  void _startQuickMatch() {
    AudioService.instance.playSound(AudioType.buttonClick);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Searching for opponents with advanced matchmaking...'),
        backgroundColor: RealmOfValorTheme.accentGold,
      ),
    );
    
    // TODO: Implement quick match with advanced features
  }

  void _startRankedMatch() {
    AudioService.instance.playSound(AudioType.buttonClick);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Finding ranked opponent with advanced battle system...'),
        backgroundColor: RealmOfValorTheme.accentGold,
      ),
    );
    
    // TODO: Implement ranked match with advanced features
  }

  void _startTeamMatch() {
    AudioService.instance.playSound(AudioType.buttonClick);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Creating team battle with advanced mechanics...'),
        backgroundColor: RealmOfValorTheme.accentGold,
      ),
    );
    
    // TODO: Implement team match with advanced features
  }

  void _startCustomGame() {
    AudioService.instance.playSound(AudioType.buttonClick);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening custom game with advanced options...'),
        backgroundColor: RealmOfValorTheme.accentGold,
      ),
    );
    
    // TODO: Implement custom game with advanced features
  }

  void _startAdvancedMatchmaking() {
    AudioService.instance.playSound(AudioType.buttonClick);
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdvancedMatchmakingScreen(),
      ),
    );
  }
}

// Placeholder screens for advanced features

class AdvancedCombatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RealmOfValorTheme.surfaceDark,
      appBar: AppBar(
        title: const Text('Advanced Combat'),
        backgroundColor: RealmOfValorTheme.surfaceDark,
        foregroundColor: RealmOfValorTheme.textPrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_martial_arts,
              size: 64,
              color: RealmOfValorTheme.accentGold,
            ),
            const SizedBox(height: 16),
            Text(
              'Advanced Combat System',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: RealmOfValorTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming Soon!',
              style: TextStyle(
                fontSize: 16,
                color: RealmOfValorTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdvancedMatchmakingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RealmOfValorTheme.surfaceDark,
      appBar: AppBar(
        title: const Text('Advanced Matchmaking'),
        backgroundColor: RealmOfValorTheme.surfaceDark,
        foregroundColor: RealmOfValorTheme.textPrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people,
              size: 64,
              color: RealmOfValorTheme.accentGold,
            ),
            const SizedBox(height: 16),
            Text(
              'Advanced Matchmaking',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: RealmOfValorTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming Soon!',
              style: TextStyle(
                fontSize: 16,
                color: RealmOfValorTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 