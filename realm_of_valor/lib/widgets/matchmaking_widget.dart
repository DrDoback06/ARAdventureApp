import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../models/battle_model.dart';
import '../models/character_model.dart';
import '../models/card_model.dart'; // Add this import for CharacterClass
import '../providers/character_provider.dart';
import '../providers/battle_controller.dart';
import '../services/ai_battle_service.dart';
import '../services/character_progression_service.dart' as progression;

class MatchmakingWidget extends StatefulWidget {
  final Function(Battle) onMatchFound;

  const MatchmakingWidget({
    super.key,
    required this.onMatchFound,
  });

  @override
  State<MatchmakingWidget> createState() => _MatchmakingWidgetState();
}

class _MatchmakingWidgetState extends State<MatchmakingWidget> {
  bool _isSearching = false;
  String _searchStatus = 'Ready to search';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Matchmaking',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSearchStatus(),
          const SizedBox(height: 24),
          _buildSearchOptions(),
          const SizedBox(height: 24),
          _buildQuickMatchSection(),
        ],
      ),
    );
  }

  Widget _buildSearchStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isSearching ? RealmOfValorTheme.accentGold : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isSearching ? Icons.search : Icons.search_off,
            color: _isSearching ? RealmOfValorTheme.accentGold : RealmOfValorTheme.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSearching ? 'Searching for opponents...' : 'Not searching',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: RealmOfValorTheme.textPrimary,
                  ),
                ),
                Text(
                  _searchStatus,
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

  Widget _buildSearchOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search Options',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: RealmOfValorTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSearching ? _stopSearch : _startSearch,
                icon: Icon(_isSearching ? Icons.stop : Icons.play_arrow),
                label: Text(_isSearching ? 'Stop Search' : 'Start Search'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSearching ? Colors.red : RealmOfValorTheme.accentGold,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickMatchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Match',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: RealmOfValorTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Start a quick battle against AI opponents',
          style: TextStyle(
            fontSize: 12,
            color: RealmOfValorTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _createQuickBattle,
                icon: const Icon(Icons.flash_on),
                label: const Text('Quick Match'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: RealmOfValorTheme.surfaceMedium,
                  foregroundColor: RealmOfValorTheme.accentGold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
      _searchStatus = 'Searching for players...';
    });

    // Simulate search
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isSearching) {
        setState(() {
          _searchStatus = 'Found opponent!';
        });
        
        // Create a match
        _createMatchmakingBattle();
      }
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchStatus = 'Search stopped';
    });
  }

  void _createQuickBattle() {
    final characterProvider = context.read<CharacterProvider>();
    final playerCharacter = characterProvider.currentCharacter;
    
    if (playerCharacter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a character first')),
      );
      return;
    }

    // Create AI opponent
    final aiCharacter = GameCharacter(
      id: 'ai_quick',
      name: 'Quick Opponent',
      characterClass: CharacterClass.barbarian,
      level: 5,
      experience: 5000,
      baseStrength: 15,
      baseDexterity: 10,
      baseVitality: 12,
      baseEnergy: 8,
      equipment: Equipment(),
      skills: [],
      inventory: [],
      characterData: {},
    );

    // Create battle
    final battle = Battle(
      id: 'battle_quick_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Quick Battle',
      type: BattleType.pve,
      players: [
        BattlePlayer(
          id: playerCharacter.id,
          name: playerCharacter.name,
          character: playerCharacter,
          hand: [],
          actionDeck: ActionCard.getDefaultActionDeck(),
          activeSkills: [],
          currentHealth: playerCharacter.maxHealth,
          currentMana: playerCharacter.maxMana,
          maxHealth: playerCharacter.maxHealth,
          maxMana: playerCharacter.maxMana,
          isReady: true,
          isActive: true,
          statusEffects: {},
        ),
        BattlePlayer(
          id: aiCharacter.id,
          name: aiCharacter.name,
          character: aiCharacter,
          hand: [],
          actionDeck: ActionCard.getDefaultActionDeck(),
          activeSkills: [],
          currentHealth: aiCharacter.maxHealth,
          currentMana: aiCharacter.maxMana,
          maxHealth: aiCharacter.maxHealth,
          maxMana: aiCharacter.maxMana,
          isReady: true,
          isActive: true,
          statusEffects: {},
        ),
      ],
      currentPlayerId: playerCharacter.id,
      status: BattleStatus.active,
    );

    widget.onMatchFound(battle);
  }

  void _createMatchmakingBattle() {
    final characterProvider = context.read<CharacterProvider>();
    final playerCharacter = characterProvider.currentCharacter;
    
    if (playerCharacter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a character first')),
      );
      return;
    }

    // Create AI opponent
    final aiCharacter = GameCharacter(
      id: 'ai_matchmaking',
      name: 'Matched Opponent',
      characterClass: CharacterClass.sorceress,
      level: 7,
      experience: 7000,
      baseStrength: 8,
      baseDexterity: 12,
      baseVitality: 10,
      baseEnergy: 16,
      equipment: Equipment(),
      skills: [],
      inventory: [],
      characterData: {},
    );

    // Create battle
    final battle = Battle(
      id: 'battle_matchmaking_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Matchmaking Battle',
      type: BattleType.pve,
      players: [
        BattlePlayer(
          id: playerCharacter.id,
          name: playerCharacter.name,
          character: playerCharacter,
          hand: [],
          actionDeck: ActionCard.getDefaultActionDeck(),
          activeSkills: [],
          currentHealth: playerCharacter.maxHealth,
          currentMana: playerCharacter.maxMana,
          maxHealth: playerCharacter.maxHealth,
          maxMana: playerCharacter.maxMana,
          isReady: true,
          isActive: true,
          statusEffects: {},
        ),
        BattlePlayer(
          id: aiCharacter.id,
          name: aiCharacter.name,
          character: aiCharacter,
          hand: [],
          actionDeck: ActionCard.getDefaultActionDeck(),
          activeSkills: [],
          currentHealth: aiCharacter.maxHealth,
          currentMana: aiCharacter.maxMana,
          maxHealth: aiCharacter.maxHealth,
          maxMana: aiCharacter.maxMana,
          isReady: true,
          isActive: true,
          statusEffects: {},
        ),
      ],
      currentPlayerId: playerCharacter.id,
      status: BattleStatus.active,
    );

    widget.onMatchFound(battle);
  }
} 