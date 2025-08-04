import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../providers/character_provider.dart';
import '../services/audio_service.dart';
import '../models/character_model.dart';
import '../models/card_model.dart';

class CharacterCreationScreen extends StatefulWidget {
  const CharacterCreationScreen({super.key});

  @override
  State<CharacterCreationScreen> createState() => _CharacterCreationScreenState();
}

class _CharacterCreationScreenState extends State<CharacterCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  CharacterClass _selectedClass = CharacterClass.paladin;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RealmOfValorTheme.surfaceDark,
      appBar: AppBar(
        title: Text(
          'Create Character',
          style: TextStyle(
            color: RealmOfValorTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: RealmOfValorTheme.surfaceMedium,
        iconTheme: IconThemeData(color: RealmOfValorTheme.accentGold),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildNameInput(),
                const SizedBox(height: 24),
                _buildClassSelection(),
                const SizedBox(height: 24),
                _buildClassInfo(),
                const SizedBox(height: 32),
                _buildCreateButton(),
              ],
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
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your class and begin your adventure',
            style: TextStyle(
              fontSize: 16,
              color: RealmOfValorTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNameInput() {
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
                Icons.edit,
                color: RealmOfValorTheme.accentGold,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Character Name',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: RealmOfValorTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameController,
            style: TextStyle(
              color: RealmOfValorTheme.textPrimary,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: 'Enter your character name',
              hintStyle: TextStyle(
                color: RealmOfValorTheme.textSecondary,
              ),
              filled: true,
              fillColor: RealmOfValorTheme.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: RealmOfValorTheme.accentGold.withOpacity(0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: RealmOfValorTheme.accentGold.withOpacity(0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: RealmOfValorTheme.accentGold,
                  width: 2,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a character name';
              }
              if (value.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }
              if (value.trim().length > 20) {
                return 'Name must be 20 characters or less';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClassSelection() {
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
                Icons.class_,
                color: RealmOfValorTheme.accentGold,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Choose Your Class',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: RealmOfValorTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: CharacterClass.values.length,
            itemBuilder: (context, index) {
              final characterClass = CharacterClass.values[index];
              final isSelected = characterClass == _selectedClass;
              
              return GestureDetector(
                onTap: () {
                  AudioService.instance.playSound(AudioType.buttonClick);
                  setState(() {
                    _selectedClass = characterClass;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? RealmOfValorTheme.accentGold.withOpacity(0.2)
                        : RealmOfValorTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected 
                          ? RealmOfValorTheme.accentGold
                          : RealmOfValorTheme.accentGold.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getClassIcon(characterClass),
                        color: isSelected 
                            ? RealmOfValorTheme.accentGold
                            : RealmOfValorTheme.textSecondary,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getClassName(characterClass),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected 
                              ? RealmOfValorTheme.accentGold
                              : RealmOfValorTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClassInfo() {
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
                Icons.info,
                color: RealmOfValorTheme.accentGold,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Class Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: RealmOfValorTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getClassDescription(_selectedClass),
            style: TextStyle(
              fontSize: 14,
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatInfo('Strength', _getClassStrength(_selectedClass)),
              const SizedBox(width: 16),
              _buildStatInfo('Dexterity', _getClassDexterity(_selectedClass)),
              const SizedBox(width: 16),
              _buildStatInfo('Vitality', _getClassVitality(_selectedClass)),
              const SizedBox(width: 16),
              _buildStatInfo('Energy', _getClassEnergy(_selectedClass)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatInfo(String statName, int value) {
    return Column(
      children: [
        Text(
          statName,
          style: TextStyle(
            fontSize: 12,
            color: RealmOfValorTheme.textSecondary,
          ),
        ),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: RealmOfValorTheme.accentGold,
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isCreating ? null : _createCharacter,
        style: ElevatedButton.styleFrom(
          backgroundColor: RealmOfValorTheme.accentGold,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isCreating
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Creating Character...'),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add),
                  const SizedBox(width: 8),
                  Text(
                    'Create Character',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _createCharacter() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final characterProvider = Provider.of<CharacterProvider>(context, listen: false);
      
      final newCharacter = GameCharacter(
        name: _nameController.text.trim(),
        characterClass: _selectedClass,
        baseStrength: _getClassStrength(_selectedClass),
        baseDexterity: _getClassDexterity(_selectedClass),
        baseVitality: _getClassVitality(_selectedClass),
        baseEnergy: _getClassEnergy(_selectedClass),
        level: 1,
        experience: 0,
        experienceToNext: 1000,
        availableStatPoints: 0,
        availableSkillPoints: 1,
        characterData: {
          'gold': 100,
          'playerId': 'player_${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      await characterProvider.createCharacter(newCharacter);
      
      AudioService.instance.playSound(AudioType.levelUp);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Character ${newCharacter.name} created successfully!'),
            backgroundColor: RealmOfValorTheme.accentGold,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create character: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  IconData _getClassIcon(CharacterClass characterClass) {
    switch (characterClass) {
      case CharacterClass.paladin:
        return Icons.shield;
      case CharacterClass.barbarian:
        return Icons.sports_martial_arts;
      case CharacterClass.necromancer:
        return Icons.auto_fix_high;
      case CharacterClass.sorceress:
        return Icons.auto_fix_high;
      case CharacterClass.amazon:
        return Icons.arrow_forward;
      case CharacterClass.assassin:
        return Icons.visibility_off;
      case CharacterClass.druid:
        return Icons.forest;
      case CharacterClass.monk:
        return Icons.self_improvement;
      case CharacterClass.crusader:
        return Icons.church;
      case CharacterClass.witchDoctor:
        return Icons.psychology;
      case CharacterClass.wizard:
        return Icons.auto_awesome;
      case CharacterClass.demonHunter:
        return Icons.flash_on;
    }
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

  String _getClassDescription(CharacterClass characterClass) {
    switch (characterClass) {
      case CharacterClass.paladin:
        return 'Holy warriors who fight for justice and righteousness. Masters of defensive combat and healing magic.';
      case CharacterClass.barbarian:
        return 'Fierce warriors who rely on brute strength and primal rage. Excellent at close combat and intimidation.';
      case CharacterClass.necromancer:
        return 'Dark spellcasters who command the dead and wield death magic. Masters of summoning and curses.';
      case CharacterClass.sorceress:
        return 'Powerful elemental mages who control fire, ice, and lightning. Masters of destructive magic.';
      case CharacterClass.amazon:
        return 'Skilled warriors who excel at ranged combat and spear fighting. Masters of agility and precision.';
      case CharacterClass.assassin:
        return 'Stealthy killers who specialize in poison and shadow magic. Masters of deception and assassination.';
      case CharacterClass.druid:
        return 'Nature-bound shapeshifters who command the elements and wild beasts. Masters of transformation.';
      case CharacterClass.monk:
        return 'Disciplined warriors who combine martial arts with spiritual power. Masters of balance and meditation.';
      case CharacterClass.crusader:
        return 'Holy knights who fight with divine weapons and protective magic. Masters of holy combat.';
      case CharacterClass.witchDoctor:
        return 'Tribal healers who use spirits and voodoo magic. Masters of healing and curses.';
      case CharacterClass.wizard:
        return 'Scholarly mages who study ancient arcane knowledge. Masters of powerful spells and enchantments.';
      case CharacterClass.demonHunter:
        return 'Vengeful warriors who hunt demons and use dark powers. Masters of demonic combat and tracking.';
    }
  }

  int _getClassStrength(CharacterClass characterClass) {
    switch (characterClass) {
      case CharacterClass.barbarian:
        return 25;
      case CharacterClass.paladin:
      case CharacterClass.crusader:
        return 20;
      case CharacterClass.amazon:
      case CharacterClass.assassin:
      case CharacterClass.demonHunter:
        return 15;
      default:
        return 10;
    }
  }

  int _getClassDexterity(CharacterClass characterClass) {
    switch (characterClass) {
      case CharacterClass.amazon:
      case CharacterClass.assassin:
        return 25;
      case CharacterClass.demonHunter:
        return 20;
      case CharacterClass.barbarian:
      case CharacterClass.druid:
        return 15;
      default:
        return 10;
    }
  }

  int _getClassVitality(CharacterClass characterClass) {
    switch (characterClass) {
      case CharacterClass.barbarian:
      case CharacterClass.paladin:
        return 25;
      case CharacterClass.crusader:
      case CharacterClass.druid:
        return 20;
      case CharacterClass.monk:
        return 15;
      default:
        return 10;
    }
  }

  int _getClassEnergy(CharacterClass characterClass) {
    switch (characterClass) {
      case CharacterClass.sorceress:
      case CharacterClass.wizard:
        return 25;
      case CharacterClass.necromancer:
      case CharacterClass.witchDoctor:
        return 20;
      case CharacterClass.druid:
        return 15;
      default:
        return 10;
    }
  }
} 