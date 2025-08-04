import 'package:flutter/material.dart';
import '../models/specialization_system.dart';
import '../models/character_model.dart';
import '../models/card_model.dart';
import '../services/specialization_service.dart';

class SpecializationTreeWidget extends StatefulWidget {
  final GameCharacter character;
  final SpecializationService specializationService;
  final VoidCallback? onSpecializationChanged;

  const SpecializationTreeWidget({
    super.key,
    required this.character,
    required this.specializationService,
    this.onSpecializationChanged,
  });

  @override
  State<SpecializationTreeWidget> createState() => _SpecializationTreeWidgetState();
}

class _SpecializationTreeWidgetState extends State<SpecializationTreeWidget> {
  SpecializationTree? _tree;
  List<SpecializationNode> _availableNodes = [];
  List<SpecializationNode> _unlockedNodes = [];
  Map<String, dynamic> _activeSpecializations = {};

  @override
  void initState() {
    super.initState();
    _loadSpecializationData();
  }

  void _loadSpecializationData() {
    _tree = widget.specializationService.getSpecializationTree(widget.character.characterClass);
    if (_tree != null) {
      _availableNodes = widget.specializationService.getAvailableSpecializations(widget.character);
      _unlockedNodes = widget.specializationService.getUnlockedSpecializations(
        widget.character.id, 
        widget.character.characterClass
      );
      _activeSpecializations = widget.specializationService.getCharacterSpecializations(widget.character.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_tree == null) {
      return const Center(
        child: Text(
          'No specialization tree available for this character class',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1a1a2e),
            Color(0xFF16213e),
            Color(0xFF0f3460),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFe94560)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                _getClassIcon(widget.character.characterClass),
                color: const Color(0xFFe94560),
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tree!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _tree!.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Progress Bar
          _buildProgressBar(),
          const SizedBox(height: 20),
          
          // Specialization Nodes
          Expanded(
            child: SingleChildScrollView(
              child: _buildSpecializationNodes(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = widget.specializationService.getSpecializationProgress(
      widget.character.id,
      widget.character.characterClass,
    );
    
    if (progress.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${progress['unlockedNodes']}/${progress['totalNodes']}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress['progress'] ?? 0.0,
          backgroundColor: Colors.grey.withOpacity(0.3),
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFe94560)),
        ),
        const SizedBox(height: 8),
        Text(
          'Active: ${progress['activeNodes']}/${progress['maxActiveNodes']}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSpecializationNodes() {
    return Column(
      children: [
        // Available Nodes
        if (_availableNodes.isNotEmpty) ...[
          _buildSectionHeader('Available Specializations'),
          const SizedBox(height: 12),
          ..._availableNodes.map((node) => _buildNodeCard(node, isAvailable: true)),
          const SizedBox(height: 20),
        ],
        
        // Unlocked Nodes
        if (_unlockedNodes.isNotEmpty) ...[
          _buildSectionHeader('Unlocked Specializations'),
          const SizedBox(height: 12),
          ..._unlockedNodes.map((node) => _buildNodeCard(node, isAvailable: false)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildNodeCard(SpecializationNode node, {required bool isAvailable}) {
    final isUnlocked = _unlockedNodes.any((n) => n.id == node.id);
    final isActive = _activeSpecializations[node.id]?['active'] == true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getNodeColor(node, isUnlocked, isActive),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? const Color(0xFFe94560) : Colors.grey.withOpacity(0.3),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getSpecializationIcon(node.type),
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_getTierName(node.tier)} • ${node.cost} skill points',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isUnlocked && !isActive)
                IconButton(
                  onPressed: () => _activateNode(node),
                  icon: const Icon(Icons.power_settings_new, color: Colors.green),
                  tooltip: 'Activate',
                ),
              if (isActive)
                IconButton(
                  onPressed: () => _deactivateNode(node),
                  icon: const Icon(Icons.power_off, color: Colors.red),
                  tooltip: 'Deactivate',
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            node.description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          if (isAvailable && !isUnlocked) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _unlockNode(node),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFe94560),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text('Unlock (${node.cost} SP)'),
            ),
          ],
        ],
      ),
    );
  }

  Color _getNodeColor(SpecializationNode node, bool isUnlocked, bool isActive) {
    if (isActive) return const Color(0xFFe94560).withOpacity(0.2);
    if (isUnlocked) return Colors.green.withOpacity(0.2);
    return Colors.grey.withOpacity(0.1);
  }

  IconData _getSpecializationIcon(SpecializationType type) {
    switch (type) {
      case SpecializationType.offensive:
        return Icons.local_fire_department;
      case SpecializationType.defensive:
        return Icons.shield;
      case SpecializationType.support:
        return Icons.healing;
      case SpecializationType.utility:
        return Icons.settings;
      case SpecializationType.hybrid:
        return Icons.auto_awesome;
    }
  }

  IconData _getClassIcon(CharacterClass characterClass) {
    switch (characterClass) {
      case CharacterClass.paladin:
        return Icons.shield;
      case CharacterClass.barbarian:
        return Icons.local_fire_department;
      case CharacterClass.sorceress:
        return Icons.auto_awesome;
      case CharacterClass.necromancer:
        return Icons.dark_mode;
      case CharacterClass.amazon:
        return Icons.sports_martial_arts;
      case CharacterClass.assassin:
        return Icons.visibility_off;
      case CharacterClass.druid:
        return Icons.eco;
      case CharacterClass.monk:
        return Icons.self_improvement;
      case CharacterClass.crusader:
        return Icons.church;
      case CharacterClass.witchDoctor:
        return Icons.psychology;
      case CharacterClass.wizard:
        return Icons.auto_awesome;
      case CharacterClass.demonHunter:
        return Icons.gps_fixed;
      default:
        return Icons.person;
    }
  }

  String _getTierName(SpecializationTier tier) {
    switch (tier) {
      case SpecializationTier.novice:
        return 'Novice';
      case SpecializationTier.adept:
        return 'Adept';
      case SpecializationTier.expert:
        return 'Expert';
      case SpecializationTier.master:
        return 'Master';
      case SpecializationTier.legendary:
        return 'Legendary';
    }
  }

  Future<void> _unlockNode(SpecializationNode node) async {
    final success = await widget.specializationService.unlockSpecialization(
      widget.character.id,
      node.id,
      widget.character,
    );
    
    if (success) {
      setState(() {
        _loadSpecializationData();
      });
      widget.onSpecializationChanged?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot unlock specialization. Check prerequisites and skill points.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _activateNode(SpecializationNode node) async {
    final success = await widget.specializationService.activateSpecialization(
      widget.character.id,
      node.id,
      widget.character.characterClass,
    );
    
    if (success) {
      setState(() {
        _loadSpecializationData();
      });
      widget.onSpecializationChanged?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot activate specialization. Check active limit.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deactivateNode(SpecializationNode node) async {
    final success = await widget.specializationService.deactivateSpecialization(
      widget.character.id,
      node.id,
    );
    
    if (success) {
      setState(() {
        _loadSpecializationData();
      });
      widget.onSpecializationChanged?.call();
    }
  }
} 