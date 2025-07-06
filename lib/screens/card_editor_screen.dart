import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/card_model.dart';
import '../services/card_editor_service.dart';
import '../widgets/card_widget.dart';

/// Screen for creating and editing cards with visual interface
class CardEditorScreen extends StatefulWidget {
  final GameCard? existingCard;
  
  const CardEditorScreen({
    Key? key,
    this.existingCard,
  }) : super(key: key);

  @override
  State<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends State<CardEditorScreen> {
  final CardEditorService _cardEditorService = CardEditorService();
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _loreController;
  late TextEditingController _attackController;
  late TextEditingController _defenseController;
  late TextEditingController _manaCostController;
  late TextEditingController _durabilityController;
  late TextEditingController _goldValueController;
  late TextEditingController _questObjectiveController;
  
  // Current card properties
  CardType _selectedType = CardType.item;
  CardRarity _selectedRarity = CardRarity.common;
  EquipmentSlot _selectedSlot = EquipmentSlot.none;
  List<CharacterClass> _allowedClasses = [CharacterClass.all];
  List<StatModifier> _statModifiers = [];
  List<CardCondition> _conditions = [];
  List<CardEffect> _effects = [];
  Map<String, dynamic> _questRewards = {};
  
  bool _isConsumable = false;
  bool _isUnique = false;
  bool _isTradeable = true;
  bool _isCraftable = false;
  int _maxUsesPerTurn = 1;
  int _maxUsesPerGame = -1;
  int _cooldownTurns = 0;
  
  bool _isLoading = false;
  String? _imageUrl;
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    if (widget.existingCard != null) {
      _loadExistingCard();
    }
  }
  
  void _initializeControllers() {
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _loreController = TextEditingController();
    _attackController = TextEditingController(text: '0');
    _defenseController = TextEditingController(text: '0');
    _manaCostController = TextEditingController(text: '0');
    _durabilityController = TextEditingController(text: '0');
    _goldValueController = TextEditingController(text: '0');
    _questObjectiveController = TextEditingController();
  }
  
  void _loadExistingCard() {
    final card = widget.existingCard!;
    _nameController.text = card.name;
    _descriptionController.text = card.description;
    _loreController.text = card.lore;
    _attackController.text = card.attack.toString();
    _defenseController.text = card.defense.toString();
    _manaCostController.text = card.manaCost.toString();
    _durabilityController.text = card.durability.toString();
    _goldValueController.text = card.goldValue.toString();
    _questObjectiveController.text = card.questObjective ?? '';
    
    _selectedType = card.type;
    _selectedRarity = card.rarity;
    _selectedSlot = card.equipmentSlot;
    _allowedClasses = List.from(card.allowedClasses);
    _statModifiers = List.from(card.statModifiers);
    _conditions = List.from(card.conditions);
    _effects = List.from(card.effects);
    _questRewards = Map.from(card.questRewards ?? {});
    
    _isConsumable = card.isConsumable;
    _isUnique = card.isUnique;
    _isTradeable = card.isTradeable;
    _isCraftable = card.isCraftable;
    _maxUsesPerTurn = card.maxUsesPerTurn;
    _maxUsesPerGame = card.maxUsesPerGame;
    _cooldownTurns = card.cooldownTurns;
    _imageUrl = card.imageUrl;
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _loreController.dispose();
    _attackController.dispose();
    _defenseController.dispose();
    _manaCostController.dispose();
    _durabilityController.dispose();
    _goldValueController.dispose();
    _questObjectiveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        title: Text(widget.existingCard != null ? 'Edit Card' : 'Create Card'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          // Preview button
          IconButton(
            onPressed: _previewCard,
            icon: const Icon(Icons.visibility),
            tooltip: 'Preview Card',
          ),
          // Save button
          IconButton(
            onPressed: _isLoading ? null : _saveCard,
            icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            tooltip: 'Save Card',
          ),
        ],
      ),
      body: Row(
        children: [
          // Main editor panel
          Expanded(
            flex: 2,
            child: _buildEditorPanel(),
          ),
          
          // Card preview panel
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: Colors.black87,
              border: Border(left: BorderSide(color: Colors.amber.shade700)),
            ),
            child: _buildPreviewPanel(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEditorPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information Section
              _buildSection(
                'Basic Information',
                [
                  _buildTextField('Name', _nameController, required: true),
                  const SizedBox(height: 12),
                  _buildTextField('Description', _descriptionController, 
                      maxLines: 3, required: true),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTypeDropdown()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildRarityDropdown()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildEquipmentSlotDropdown(),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Stats Section
              _buildSection(
                'Stats',
                [
                  Row(
                    children: [
                      Expanded(child: _buildNumberField('Attack', _attackController)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildNumberField('Defense', _defenseController)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildNumberField('Mana Cost', _manaCostController)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildNumberField('Durability', _durabilityController)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildNumberField('Gold Value', _goldValueController),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Classes Section
              _buildSection(
                'Allowed Classes',
                [_buildClassSelection()],
              ),
              
              const SizedBox(height: 24),
              
              // Stat Modifiers Section
              _buildSection(
                'Stat Modifiers',
                [_buildStatModifiers()],
              ),
              
              const SizedBox(height: 24),
              
              // Conditions Section
              _buildSection(
                'Requirements',
                [_buildConditions()],
              ),
              
              const SizedBox(height: 24),
              
              // Effects Section
              _buildSection(
                'Effects',
                [_buildEffects()],
              ),
              
              const SizedBox(height: 24),
              
              // Usage Limitations Section
              _buildSection(
                'Usage Limitations',
                [_buildUsageLimitations()],
              ),
              
              const SizedBox(height: 24),
              
              // Quest Section (if quest card)
              if (_selectedType == CardType.quest) ...[
                _buildSection(
                  'Quest Information',
                  [_buildQuestSection()],
                ),
                const SizedBox(height: 24),
              ],
              
              // Additional Properties Section
              _buildSection(
                'Additional Properties',
                [_buildAdditionalProperties()],
              ),
              
              const SizedBox(height: 24),
              
              // Lore Section
              _buildSection(
                'Lore',
                [_buildTextField('Lore', _loreController, maxLines: 4)],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPreviewPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Card Preview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Card preview
          Center(
            child: CardWidget(
              card: _buildPreviewCard(),
              size: const Size(200, 280),
              showTooltip: true,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Card validation
          _buildValidationInfo(),
          
          const SizedBox(height: 24),
          
          // Quick actions
          _buildQuickActions(),
        ],
      ),
    );
  }
  
  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade700.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.amber.shade700,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
  
  Widget _buildTextField(String label, TextEditingController controller, 
      {int maxLines = 1, bool required = false}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade400),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.amber.shade700),
        ),
      ),
      validator: required ? (value) {
        if (value == null || value.isEmpty) {
          return '$label is required';
        }
        return null;
      } : null,
    );
  }
  
  Widget _buildNumberField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade400),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.amber.shade700),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label is required';
        }
        if (int.tryParse(value) == null) {
          return '$label must be a number';
        }
        return null;
      },
    );
  }
  
  Widget _buildTypeDropdown() {
    return DropdownButtonFormField<CardType>(
      value: _selectedType,
      style: const TextStyle(color: Colors.white),
      dropdownColor: Colors.grey.shade800,
      decoration: InputDecoration(
        labelText: 'Type',
        labelStyle: TextStyle(color: Colors.grey.shade400),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.amber.shade700),
        ),
      ),
      items: CardType.values.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(type.name.toUpperCase()),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedType = value!;
          // Auto-set equipment slot based on type
          if (value == CardType.weapon) {
            _selectedSlot = EquipmentSlot.weapon1;
          } else if (value == CardType.armor) {
            _selectedSlot = EquipmentSlot.armor;
          } else if (value == CardType.skill) {
            _selectedSlot = EquipmentSlot.skill1;
          } else {
            _selectedSlot = EquipmentSlot.none;
          }
        });
      },
    );
  }
  
  Widget _buildRarityDropdown() {
    return DropdownButtonFormField<CardRarity>(
      value: _selectedRarity,
      style: const TextStyle(color: Colors.white),
      dropdownColor: Colors.grey.shade800,
      decoration: InputDecoration(
        labelText: 'Rarity',
        labelStyle: TextStyle(color: Colors.grey.shade400),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.amber.shade700),
        ),
      ),
      items: CardRarity.values.map((rarity) {
        return DropdownMenuItem(
          value: rarity,
          child: Text(rarity.name.toUpperCase()),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedRarity = value!;
        });
      },
    );
  }
  
  Widget _buildEquipmentSlotDropdown() {
    return DropdownButtonFormField<EquipmentSlot>(
      value: _selectedSlot,
      style: const TextStyle(color: Colors.white),
      dropdownColor: Colors.grey.shade800,
      decoration: InputDecoration(
        labelText: 'Equipment Slot',
        labelStyle: TextStyle(color: Colors.grey.shade400),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.amber.shade700),
        ),
      ),
      items: EquipmentSlot.values.map((slot) {
        return DropdownMenuItem(
          value: slot,
          child: Text(slot.name.toUpperCase()),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedSlot = value!;
        });
      },
    );
  }
  
  Widget _buildClassSelection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: CharacterClass.values.map((characterClass) {
        final isSelected = _allowedClasses.contains(characterClass);
        return FilterChip(
          label: Text(characterClass.name.toUpperCase()),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                if (characterClass == CharacterClass.all) {
                  _allowedClasses = [CharacterClass.all];
                } else {
                  _allowedClasses.remove(CharacterClass.all);
                  _allowedClasses.add(characterClass);
                }
              } else {
                _allowedClasses.remove(characterClass);
                if (_allowedClasses.isEmpty) {
                  _allowedClasses.add(CharacterClass.all);
                }
              }
            });
          },
          backgroundColor: Colors.grey.shade700,
          selectedColor: Colors.amber.shade700.withOpacity(0.3),
          checkmarkColor: Colors.amber.shade700,
          labelStyle: TextStyle(
            color: isSelected ? Colors.amber.shade700 : Colors.white,
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildStatModifiers() {
    return Column(
      children: [
        ..._statModifiers.asMap().entries.map((entry) {
          final index = entry.key;
          final modifier = entry.value;
          return Card(
            color: Colors.grey.shade700,
            child: ListTile(
              title: Text(
                '${modifier.statName}: ${modifier.value}${modifier.isPercentage ? '%' : ''}',
                style: const TextStyle(color: Colors.white),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _statModifiers.removeAt(index);
                  });
                },
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _addStatModifier,
          icon: const Icon(Icons.add),
          label: const Text('Add Stat Modifier'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade700,
            foregroundColor: Colors.black,
          ),
        ),
      ],
    );
  }
  
  Widget _buildConditions() {
    return Column(
      children: [
        ..._conditions.asMap().entries.map((entry) {
          final index = entry.key;
          final condition = entry.value;
          return Card(
            color: Colors.grey.shade700,
            child: ListTile(
              title: Text(
                '${condition.conditionKey} ${condition.operator} ${condition.conditionValue}',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'Type: ${condition.conditionType}',
                style: TextStyle(color: Colors.grey.shade400),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _conditions.removeAt(index);
                  });
                },
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _addCondition,
          icon: const Icon(Icons.add),
          label: const Text('Add Requirement'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade700,
            foregroundColor: Colors.black,
          ),
        ),
      ],
    );
  }
  
  Widget _buildEffects() {
    return Column(
      children: [
        ..._effects.asMap().entries.map((entry) {
          final index = entry.key;
          final effect = entry.value;
          return Card(
            color: Colors.grey.shade700,
            child: ListTile(
              title: Text(
                '${effect.effectType}: ${effect.value} on ${effect.target}',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: effect.duration > 0 
                  ? Text(
                      'Duration: ${effect.duration} turns',
                      style: TextStyle(color: Colors.grey.shade400),
                    )
                  : null,
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _effects.removeAt(index);
                  });
                },
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _addEffect,
          icon: const Icon(Icons.add),
          label: const Text('Add Effect'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade700,
            foregroundColor: Colors.black,
          ),
        ),
      ],
    );
  }
  
  Widget _buildUsageLimitations() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildNumberField('Max Uses Per Turn', 
                  TextEditingController(text: _maxUsesPerTurn.toString())),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNumberField('Max Uses Per Game', 
                  TextEditingController(text: _maxUsesPerGame.toString())),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildNumberField('Cooldown Turns', 
            TextEditingController(text: _cooldownTurns.toString())),
      ],
    );
  }
  
  Widget _buildQuestSection() {
    return Column(
      children: [
        _buildTextField('Quest Objective', _questObjectiveController, 
            maxLines: 2, required: true),
        const SizedBox(height: 12),
        // TODO: Add quest rewards editor
        const Text(
          'Quest rewards editor coming soon...',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
  
  Widget _buildAdditionalProperties() {
    return Column(
      children: [
        CheckboxListTile(
          title: const Text('Consumable', style: TextStyle(color: Colors.white)),
          value: _isConsumable,
          onChanged: (value) {
            setState(() {
              _isConsumable = value!;
            });
          },
          activeColor: Colors.amber.shade700,
        ),
        CheckboxListTile(
          title: const Text('Unique', style: TextStyle(color: Colors.white)),
          value: _isUnique,
          onChanged: (value) {
            setState(() {
              _isUnique = value!;
            });
          },
          activeColor: Colors.amber.shade700,
        ),
        CheckboxListTile(
          title: const Text('Tradeable', style: TextStyle(color: Colors.white)),
          value: _isTradeable,
          onChanged: (value) {
            setState(() {
              _isTradeable = value!;
            });
          },
          activeColor: Colors.amber.shade700,
        ),
        CheckboxListTile(
          title: const Text('Craftable', style: TextStyle(color: Colors.white)),
          value: _isCraftable,
          onChanged: (value) {
            setState(() {
              _isCraftable = value!;
            });
          },
          activeColor: Colors.amber.shade700,
        ),
      ],
    );
  }
  
  Widget _buildValidationInfo() {
    final card = _buildPreviewCard();
    final isValid = _cardEditorService.validateCard(card);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isValid ? Colors.green.shade900 : Colors.red.shade900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isValid ? Colors.green.shade700 : Colors.red.shade700,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.error,
            color: isValid ? Colors.green.shade300 : Colors.red.shade300,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isValid ? 'Card is valid' : 'Card has validation errors',
              style: TextStyle(
                color: isValid ? Colors.green.shade300 : Colors.red.shade300,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _createWeaponTemplate,
          icon: const Icon(Icons.sword),
          label: const Text('Weapon Template'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _createArmorTemplate,
          icon: const Icon(Icons.shield),
          label: const Text('Armor Template'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _createSkillTemplate,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Skill Template'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple.shade700,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
  
  GameCard _buildPreviewCard() {
    return GameCard(
      id: widget.existingCard?.id,
      name: _nameController.text.isEmpty ? 'Unnamed Card' : _nameController.text,
      description: _descriptionController.text,
      type: _selectedType,
      rarity: _selectedRarity,
      allowedClasses: _allowedClasses,
      equipmentSlot: _selectedSlot,
      imageUrl: _imageUrl,
      attack: int.tryParse(_attackController.text) ?? 0,
      defense: int.tryParse(_defenseController.text) ?? 0,
      manaCost: int.tryParse(_manaCostController.text) ?? 0,
      durability: int.tryParse(_durabilityController.text) ?? 0,
      statModifiers: _statModifiers,
      conditions: _conditions,
      effects: _effects,
      maxUsesPerGame: _maxUsesPerGame,
      maxUsesPerTurn: _maxUsesPerTurn,
      cooldownTurns: _cooldownTurns,
      isConsumable: _isConsumable,
      isUnique: _isUnique,
      questObjective: _questObjectiveController.text.isEmpty ? null : _questObjectiveController.text,
      questRewards: _questRewards.isEmpty ? null : _questRewards,
      goldValue: int.tryParse(_goldValueController.text) ?? 0,
      isTradeable: _isTradeable,
      isCraftable: _isCraftable,
      lore: _loreController.text,
      createdBy: 'card_editor',
    );
  }
  
  void _previewCard() {
    showDialog(
      context: context,
      builder: (context) => LargeCardWidget(
        card: _buildPreviewCard(),
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }
  
  void _saveCard() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final card = _buildPreviewCard();
      
      if (!_cardEditorService.validateCard(card)) {
        throw Exception('Card validation failed');
      }
      
      if (widget.existingCard != null) {
        await _cardEditorService.updateCard(card);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card updated successfully!')),
        );
      } else {
        await _cardEditorService.createCard(card);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card created successfully!')),
        );
      }
      
      Navigator.of(context).pop(card);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save card: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _addStatModifier() {
    // TODO: Show dialog to add stat modifier
    setState(() {
      _statModifiers.add(const StatModifier(
        statName: 'strength',
        value: 1,
      ));
    });
  }
  
  void _addCondition() {
    // TODO: Show dialog to add condition
    setState(() {
      _conditions.add(const CardCondition(
        conditionType: 'stat',
        conditionKey: 'level',
        conditionValue: 1,
      ));
    });
  }
  
  void _addEffect() {
    // TODO: Show dialog to add effect
    setState(() {
      _effects.add(const CardEffect(
        effectType: 'damage',
        target: 'enemy',
        value: 1,
      ));
    });
  }
  
  void _createWeaponTemplate() {
    final weapon = _cardEditorService.createBasicWeapon(
      name: 'Iron Sword',
      description: 'A basic iron sword.',
      attack: 10,
      durability: 50,
    );
    _loadCardTemplate(weapon);
  }
  
  void _createArmorTemplate() {
    final armor = _cardEditorService.createBasicArmor(
      name: 'Leather Armor',
      description: 'Basic leather armor for protection.',
      defense: 5,
      durability: 40,
    );
    _loadCardTemplate(armor);
  }
  
  void _createSkillTemplate() {
    final skill = _cardEditorService.createBasicSkill(
      name: 'Fireball',
      description: 'Launches a fireball at the enemy.',
      manaCost: 10,
      effects: [
        const CardEffect(
          effectType: 'damage',
          target: 'enemy',
          value: 15,
        ),
      ],
    );
    _loadCardTemplate(skill);
  }
  
  void _loadCardTemplate(GameCard template) {
    setState(() {
      _nameController.text = template.name;
      _descriptionController.text = template.description;
      _selectedType = template.type;
      _selectedSlot = template.equipmentSlot;
      _attackController.text = template.attack.toString();
      _defenseController.text = template.defense.toString();
      _manaCostController.text = template.manaCost.toString();
      _durabilityController.text = template.durability.toString();
      _goldValueController.text = template.goldValue.toString();
      _effects = List.from(template.effects);
    });
  }
}