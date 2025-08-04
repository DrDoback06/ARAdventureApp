import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../providers/character_provider.dart';
import '../models/character_model.dart';

class SkillsContent extends StatefulWidget {
  const SkillsContent({super.key});

  @override
  State<SkillsContent> createState() => _SkillsContentState();
}

class _SkillsContentState extends State<SkillsContent> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    print('DEBUG: SkillsContent initialized');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: Building SkillsContent');
    return Consumer<CharacterProvider>(
      builder: (context, characterProvider, child) {
        final character = characterProvider.currentCharacter;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: RealmOfValorTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: RealmOfValorTheme.primaryLight,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.account_tree,
                    color: RealmOfValorTheme.accentGold,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Skill Tree',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: RealmOfValorTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (character != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: RealmOfValorTheme.accentGold,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${character.availableSkillPoints} Points',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  color: RealmOfValorTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: RealmOfValorTheme.accentGold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: RealmOfValorTheme.textSecondary,
                  tabs: const [
                    Tab(text: 'Combat'),
                    Tab(text: 'Utility'),
                    Tab(text: 'Passive'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCombatSkillsTab(character),
                    _buildUtilitySkillsTab(character),
                    _buildPassiveSkillsTab(character),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCombatSkillsTab(GameCharacter? character) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Combat Skills',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSkillTree([
            _buildSkillNode('Fireball', 'Deal fire damage to enemies', 1, Icons.local_fire_department, character),
            _buildSkillNode('Lightning Bolt', 'Chain lightning attack', 2, Icons.electric_bolt, character),
            _buildSkillNode('Ice Nova', 'Freeze surrounding enemies', 3, Icons.ac_unit, character),
            _buildSkillNode('Meteor Strike', 'Massive area damage', 5, Icons.rocket_launch, character),
          ]),
        ],
      ),
    );
  }

  Widget _buildUtilitySkillsTab(GameCharacter? character) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Utility Skills',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSkillTree([
            _buildSkillNode('Teleport', 'Instant movement', 1, Icons.telegram, character),
            _buildSkillNode('Shield', 'Temporary protection', 2, Icons.shield, character),
            _buildSkillNode('Heal', 'Restore health', 3, Icons.healing, character),
            _buildSkillNode('Invisibility', 'Stealth mode', 4, Icons.visibility_off, character),
          ]),
        ],
      ),
    );
  }

  Widget _buildPassiveSkillsTab(GameCharacter? character) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Passive Skills',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSkillTree([
            _buildSkillNode('Strength Boost', 'Increase base strength', 1, Icons.fitness_center, character),
            _buildSkillNode('Agility Boost', 'Increase movement speed', 2, Icons.speed, character),
            _buildSkillNode('Vitality Boost', 'Increase health regeneration', 3, Icons.favorite, character),
            _buildSkillNode('Energy Boost', 'Increase mana regeneration', 4, Icons.auto_awesome, character),
          ]),
        ],
      ),
    );
  }

  Widget _buildSkillTree(List<Widget> skills) {
    return Column(
      children: skills.asMap().entries.map((entry) {
        final index = entry.key;
        final skill = entry.value;
        
        return Column(
          children: [
            skill,
            if (index < skills.length - 1)
              Container(
                width: 2,
                height: 20,
                color: RealmOfValorTheme.accentGold.withOpacity(0.5),
              ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSkillNode(String name, String description, int cost, IconData icon, GameCharacter? character) {
    final hasPoints = (character?.availableSkillPoints ?? 0) >= cost;
    final isUnlocked = character?.characterData['skills']?[name] != null ?? false;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnlocked 
            ? RealmOfValorTheme.accentGold.withOpacity(0.2)
            : RealmOfValorTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUnlocked 
              ? RealmOfValorTheme.accentGold
              : RealmOfValorTheme.accentGold.withOpacity(0.3),
          width: isUnlocked ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isUnlocked 
                  ? RealmOfValorTheme.accentGold
                  : RealmOfValorTheme.surfaceMedium,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: isUnlocked ? Colors.white : RealmOfValorTheme.textSecondary,
              size: 20,
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked 
                        ? RealmOfValorTheme.accentGold
                        : RealmOfValorTheme.textPrimary,
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
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hasPoints 
                      ? RealmOfValorTheme.accentGold
                      : RealmOfValorTheme.surfaceMedium,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$cost',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: hasPoints ? Colors.white : RealmOfValorTheme.textSecondary,
                  ),
                ),
              ),
              if (!isUnlocked && hasPoints)
                TextButton(
                  onPressed: () => _unlockSkill(name, cost),
                  child: Text(
                    'Unlock',
                    style: TextStyle(
                      fontSize: 12,
                      color: RealmOfValorTheme.accentGold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _unlockSkill(String skillName, int cost) {
    print('DEBUG: Attempting to unlock skill: $skillName');
    
    final characterProvider = Provider.of<CharacterProvider>(context, listen: false);
    final character = characterProvider.currentCharacter;
    
    if (character == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No character selected'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (character.availableSkillPoints < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not enough skill points'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // TODO: Implement actual skill unlocking logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Skill unlocking coming soon!'),
        backgroundColor: RealmOfValorTheme.accentGold,
      ),
    );
  }
} 