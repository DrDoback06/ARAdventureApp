import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../services/character_progression_service.dart';
import '../services/audio_service.dart';

class SkillTreeWidget extends StatefulWidget {
  const SkillTreeWidget({super.key});

  @override
  State<SkillTreeWidget> createState() => _SkillTreeWidgetState();
}

class _SkillTreeWidgetState extends State<SkillTreeWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  SkillTreeType _selectedTree = SkillTreeType.combat;

  @override
  void initState() {
    super.initState();
    // Dynamic tab count based on available skill trees
    final availableTrees = _getAvailableSkillTrees();
    _tabController = TabController(length: availableTrees.length, vsync: this);
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
        title: const Text('Skill Tree'),
        backgroundColor: RealmOfValorTheme.surfaceDark,
        foregroundColor: RealmOfValorTheme.textPrimary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: RealmOfValorTheme.accentGold,
          labelColor: RealmOfValorTheme.accentGold,
          unselectedLabelColor: RealmOfValorTheme.textSecondary,
          isScrollable: true,
          tabs: _getAvailableSkillTrees().map((treeType) => 
            Tab(text: _getTreeName(treeType))
          ).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _getAvailableSkillTrees().map((treeType) => 
          _buildSkillTreeTab(treeType)
        ).toList(),
      ),
    );
  }

  List<SkillTreeType> _getAvailableSkillTrees() {
    return [
      SkillTreeType.combat,
      SkillTreeType.magic,
      SkillTreeType.survival,
      SkillTreeType.social,
      SkillTreeType.crafting,
      // Class-specific trees
      SkillTreeType.berserker,
      SkillTreeType.elemental,
      SkillTreeType.holy,
      SkillTreeType.protection,
      SkillTreeType.shadow,
      SkillTreeType.stealth,
      SkillTreeType.nature,
      SkillTreeType.shapeshifting,
      SkillTreeType.death,
      SkillTreeType.summoning,
      SkillTreeType.archery,
      SkillTreeType.javelin,
      SkillTreeType.martial,
      SkillTreeType.meditation,
    ];
  }

  Widget _buildSkillTreeTab(SkillTreeType treeType) {
    return Consumer<CharacterProgressionService>(
      builder: (context, progressionService, child) {
        final skillNodes = progressionService.getSkillNodesByTree(treeType);
        final stats = progressionService.getSkillTreeStatistics();
        final treeStats = stats[treeType.name] as Map<String, dynamic>?;
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTreeHeader(treeType, treeStats),
              const SizedBox(height: 16),
              _buildSkillPointsInfo(progressionService),
              const SizedBox(height: 16),
              Expanded(
                child: _buildSkillTree(treeType, skillNodes, progressionService),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTreeHeader(SkillTreeType treeType, Map<String, dynamic>? stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getTreeColor(treeType).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getTreeIcon(treeType),
                color: _getTreeColor(treeType),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                _getTreeName(treeType),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: RealmOfValorTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (stats != null) ...[
            Row(
              children: [
                _buildStatItem('Skills', '${stats['totalSkills']}', Icons.star),
                const SizedBox(width: 16),
                _buildStatItem('Unlocked', '${stats['unlockedSkills']}', Icons.check_circle),
                const SizedBox(width: 16),
                _buildStatItem('Maxed', '${stats['maxedSkills']}', Icons.emoji_events),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: stats['completionRate'] as double,
              backgroundColor: RealmOfValorTheme.surfaceDark,
              valueColor: AlwaysStoppedAnimation<Color>(_getTreeColor(treeType)),
            ),
            const SizedBox(height: 4),
            Text(
              '${(stats['completionRate'] * 100).round()}% Complete',
              style: TextStyle(
                fontSize: 12,
                color: RealmOfValorTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkillPointsInfo(CharacterProgressionService progressionService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.accentGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RealmOfValorTheme.accentGold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.psychology,
            color: RealmOfValorTheme.accentGold,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Skill Points',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: RealmOfValorTheme.textPrimary,
                  ),
                ),
                Text(
                  '${progressionService.availableSkillPoints} points',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: RealmOfValorTheme.accentGold,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              AudioService.instance.playSound(AudioType.buttonClick);
              _showAddSkillPointsDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RealmOfValorTheme.accentGold,
            ),
            child: const Text('Add Points'),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillTree(SkillTreeType treeType, List<SkillNode> skillNodes, CharacterProgressionService progressionService) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ...skillNodes.map((node) => _buildSkillNode(node, progressionService)),
          const SizedBox(height: 16),
          _buildTreeActions(treeType, progressionService),
        ],
      ),
    );
  }

  Widget _buildSkillNode(SkillNode node, CharacterProgressionService progressionService) {
    final canUpgrade = !node.isMaxed && 
                      progressionService.availableSkillPoints >= node.skill.skillPointCost &&
                      _checkPrerequisites(node, progressionService);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getSkillBorderColor(node, canUpgrade),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getSkillTierColor(node.skill.tier).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getSkillIcon(node.skill.treeType),
                  color: _getSkillTierColor(node.skill.tier),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.skill.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: RealmOfValorTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Tier: ${node.skill.tier.name.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _getSkillTierColor(node.skill.tier),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getSkillTierColor(node.skill.tier),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${node.currentLevel}/${node.skill.maxLevel}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            node.skill.description,
            style: TextStyle(
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          if (node.skill.prerequisites.isNotEmpty) ...[
            Text(
              'Prerequisites: ${node.skill.prerequisites.join(', ')}',
              style: TextStyle(
                fontSize: 12,
                color: RealmOfValorTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
          ],
          _buildSkillEffects(node.skill, node.currentLevel),
          const SizedBox(height: 12),
          if (!node.isMaxed) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: canUpgrade ? () {
                      AudioService.instance.playSound(AudioType.buttonClick);
                      _upgradeSkill(node, progressionService);
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canUpgrade ? RealmOfValorTheme.accentGold : Colors.grey,
                    ),
                    child: Text(
                      'Upgrade (${node.skill.skillPointCost} pts)',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    AudioService.instance.playSound(AudioType.buttonClick);
                    _showSkillDetails(node);
                  },
                  icon: Icon(
                    Icons.info_outline,
                    color: RealmOfValorTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'MAXED',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkillEffects(Skill skill, int currentLevel) {
    if (currentLevel == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Effects:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: RealmOfValorTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        ...skill.effects.entries.map((entry) {
          final effectName = entry.key;
          final baseValue = entry.value as num;
          final totalValue = baseValue * currentLevel;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              '• ${_formatEffectName(effectName)}: +$totalValue',
              style: TextStyle(
                fontSize: 12,
                color: RealmOfValorTheme.textSecondary,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTreeActions(SkillTreeType treeType, CharacterProgressionService progressionService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getTreeColor(treeType).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tree Actions',
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
                child: ElevatedButton(
                  onPressed: () {
                    AudioService.instance.playSound(AudioType.buttonClick);
                    _showTreeStatistics(treeType, progressionService);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getTreeColor(treeType),
                  ),
                  child: const Text('View Statistics'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    AudioService.instance.playSound(AudioType.buttonClick);
                    _showResetConfirmation(context, progressionService);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Reset Tree'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: RealmOfValorTheme.textSecondary, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTreeColor(SkillTreeType treeType) {
    switch (treeType) {
      case SkillTreeType.combat:
        return Colors.red;
      case SkillTreeType.magic:
        return Colors.blue;
      case SkillTreeType.survival:
        return Colors.green;
      case SkillTreeType.social:
        return Colors.purple;
      case SkillTreeType.crafting:
        return Colors.orange;
      // Class-specific trees
      case SkillTreeType.berserker:
        return Colors.red.shade700;
      case SkillTreeType.elemental:
        return Colors.orange.shade600;
      case SkillTreeType.holy:
        return Colors.yellow.shade600;
      case SkillTreeType.protection:
        return Colors.blue.shade700;
      case SkillTreeType.shadow:
        return Colors.grey.shade800;
      case SkillTreeType.stealth:
        return Colors.grey.shade600;
      case SkillTreeType.nature:
        return Colors.green.shade600;
      case SkillTreeType.shapeshifting:
        return Colors.brown.shade600;
      case SkillTreeType.death:
        return Colors.grey.shade900;
      case SkillTreeType.summoning:
        return Colors.purple.shade700;
      case SkillTreeType.archery:
        return Colors.orange.shade700;
      case SkillTreeType.javelin:
        return Colors.orange.shade800;
      case SkillTreeType.martial:
        return Colors.red.shade600;
      case SkillTreeType.meditation:
        return Colors.indigo.shade600;
      default:
        return RealmOfValorTheme.textSecondary;
    }
  }

  IconData _getTreeIcon(SkillTreeType treeType) {
    switch (treeType) {
      case SkillTreeType.combat:
        return Icons.sports_esports;
      case SkillTreeType.magic:
        return Icons.auto_fix_high;
      case SkillTreeType.survival:
        return Icons.favorite;
      case SkillTreeType.social:
        return Icons.people;
      case SkillTreeType.crafting:
        return Icons.build;
      // Class-specific trees
      case SkillTreeType.berserker:
        return Icons.whatshot;
      case SkillTreeType.elemental:
        return Icons.local_fire_department;
      case SkillTreeType.holy:
        return Icons.auto_awesome;
      case SkillTreeType.protection:
        return Icons.shield;
      case SkillTreeType.shadow:
        return Icons.visibility_off;
      case SkillTreeType.stealth:
        return Icons.visibility;
      case SkillTreeType.nature:
        return Icons.eco;
      case SkillTreeType.shapeshifting:
        return Icons.transform;
      case SkillTreeType.death:
        return Icons.help_outline;
      case SkillTreeType.summoning:
        return Icons.group_add;
      case SkillTreeType.archery:
        return Icons.arrow_forward;
      case SkillTreeType.javelin:
        return Icons.sports_martial_arts;
      case SkillTreeType.martial:
        return Icons.sports_martial_arts;
      case SkillTreeType.meditation:
        return Icons.self_improvement;
      default:
        return Icons.star;
    }
  }

  String _getTreeName(SkillTreeType treeType) {
    switch (treeType) {
      case SkillTreeType.combat:
        return 'Combat Skills';
      case SkillTreeType.magic:
        return 'Magic Skills';
      case SkillTreeType.survival:
        return 'Survival Skills';
      case SkillTreeType.social:
        return 'Social Skills';
      case SkillTreeType.crafting:
        return 'Crafting Skills';
      // Class-specific trees
      case SkillTreeType.berserker:
        return 'Berserker Skills';
      case SkillTreeType.elemental:
        return 'Elemental Skills';
      case SkillTreeType.holy:
        return 'Holy Skills';
      case SkillTreeType.protection:
        return 'Protection Skills';
      case SkillTreeType.shadow:
        return 'Shadow Skills';
      case SkillTreeType.stealth:
        return 'Stealth Skills';
      case SkillTreeType.nature:
        return 'Nature Skills';
      case SkillTreeType.shapeshifting:
        return 'Shapeshifting Skills';
      case SkillTreeType.death:
        return 'Death Skills';
      case SkillTreeType.summoning:
        return 'Summoning Skills';
      case SkillTreeType.archery:
        return 'Archery Skills';
      case SkillTreeType.javelin:
        return 'Javelin Skills';
      case SkillTreeType.martial:
        return 'Martial Arts';
      case SkillTreeType.meditation:
        return 'Meditation Skills';
      default:
        return 'Unknown Tree';
    }
  }

  Color _getSkillBorderColor(SkillNode node, bool canUpgrade) {
    if (node.isMaxed) return Colors.green;
    if (node.isUnlocked) return RealmOfValorTheme.accentGold;
    if (canUpgrade) return Colors.blue;
    return RealmOfValorTheme.textSecondary.withOpacity(0.3);
  }

  Color _getSkillTierColor(SkillTier tier) {
    switch (tier) {
      case SkillTier.basic:
        return Colors.grey;
      case SkillTier.intermediate:
        return Colors.green;
      case SkillTier.advanced:
        return Colors.blue;
      case SkillTier.master:
        return Colors.purple;
      case SkillTier.legendary:
        return Colors.orange;
    }
  }

  IconData _getSkillIcon(SkillTreeType treeType) {
    switch (treeType) {
      case SkillTreeType.combat:
        return Icons.gps_fixed;
      case SkillTreeType.magic:
        return Icons.auto_fix_high;
      case SkillTreeType.survival:
        return Icons.favorite;
      case SkillTreeType.social:
        return Icons.people;
      case SkillTreeType.crafting:
        return Icons.build;
      // Class-specific trees
      case SkillTreeType.berserker:
        return Icons.whatshot;
      case SkillTreeType.elemental:
        return Icons.local_fire_department;
      case SkillTreeType.holy:
        return Icons.auto_awesome;
      case SkillTreeType.protection:
        return Icons.shield;
      case SkillTreeType.shadow:
        return Icons.visibility_off;
      case SkillTreeType.stealth:
        return Icons.visibility;
      case SkillTreeType.nature:
        return Icons.eco;
      case SkillTreeType.shapeshifting:
        return Icons.transform;
      case SkillTreeType.death:
        return Icons.help_outline;
      case SkillTreeType.summoning:
        return Icons.group_add;
      case SkillTreeType.archery:
        return Icons.arrow_forward;
      case SkillTreeType.javelin:
        return Icons.sports_martial_arts;
      case SkillTreeType.martial:
        return Icons.sports_martial_arts;
      case SkillTreeType.meditation:
        return Icons.self_improvement;
      default:
        return Icons.star;
    }
  }

  String _formatEffectName(String effectName) {
    return effectName.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  bool _checkPrerequisites(SkillNode node, CharacterProgressionService progressionService) {
    for (final prerequisiteId in node.skill.prerequisites) {
      final prerequisiteLevel = progressionService.getSkillLevel(prerequisiteId);
      final prerequisiteSkill = progressionService.skills[prerequisiteId];
      
      if (prerequisiteSkill == null || prerequisiteLevel < prerequisiteSkill.maxLevel) {
        return false;
      }
    }
    return true;
  }

  void _upgradeSkill(SkillNode node, CharacterProgressionService progressionService) {
    final success = progressionService.upgradeSkill(node.id);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${node.skill.name} upgraded to level ${node.currentLevel + 1}!'),
          backgroundColor: RealmOfValorTheme.accentGold,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to upgrade skill. Check requirements.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSkillDetails(SkillNode node) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(node.skill.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              node.skill.description,
              style: TextStyle(color: RealmOfValorTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              'Tier: ${node.skill.tier.name.toUpperCase()}',
              style: TextStyle(
                color: _getSkillTierColor(node.skill.tier),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('Max Level: ${node.skill.maxLevel}'),
            Text('Required Level: ${node.skill.requiredLevel}'),
            Text('Skill Point Cost: ${node.skill.skillPointCost}'),
            if (node.skill.prerequisites.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Prerequisites:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...node.skill.prerequisites.map((prereq) => Text('• $prereq')),
            ],
            const SizedBox(height: 8),
            Text(
              'Effects:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...node.skill.effects.entries.map((entry) => 
              Text('• ${_formatEffectName(entry.key)}: +${entry.value} per level')
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

  void _showTreeStatistics(SkillTreeType treeType, CharacterProgressionService progressionService) {
    final stats = progressionService.getSkillTreeStatistics();
    final treeStats = stats[treeType.name] as Map<String, dynamic>?;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_getTreeName(treeType)} Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (treeStats != null) ...[
              _buildStatRow('Total Skills', '${treeStats['totalSkills']}'),
              _buildStatRow('Unlocked Skills', '${treeStats['unlockedSkills']}'),
              _buildStatRow('Maxed Skills', '${treeStats['maxedSkills']}'),
              _buildStatRow('Total Levels', '${treeStats['totalLevels']}'),
              _buildStatRow('Completion Rate', '${(treeStats['completionRate'] * 100).round()}%'),
            ],
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

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showAddSkillPointsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Skill Points'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How many skill points would you like to add?'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.read<CharacterProgressionService>().addSkillPoints(5);
                    },
                    child: const Text('+5'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.read<CharacterProgressionService>().addSkillPoints(10);
                    },
                    child: const Text('+10'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.read<CharacterProgressionService>().addSkillPoints(20);
                    },
                    child: const Text('+20'),
                  ),
                ),
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

  void _showResetConfirmation(BuildContext context, CharacterProgressionService progressionService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Skill Tree'),
        content: const Text(
          'Are you sure you want to reset your skill tree? This will refund your skill points but you will lose all skill progress.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              progressionService.resetSkillTree();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Skill tree reset! You have 20 skill points available.'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
} 