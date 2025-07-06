import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card_model.dart';
import '../services/card_service.dart';
import '../constants/theme.dart';
import '../widgets/card_widget.dart';

class CardEditorScreen extends StatefulWidget {
  final GameCard? editingCard;

  const CardEditorScreen({Key? key, this.editingCard}) : super(key: key);

  @override
  State<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends State<CardEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late CardService _cardService;
  
  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageUrlController;
  late TextEditingController _costController;
  late TextEditingController _levelRequirementController;
  late TextEditingController _durabilityController;
  late TextEditingController _maxStackController;
  
  // Form state
  CardType _selectedType = CardType.item;
  CardRarity _selectedRarity = CardRarity.common;
  EquipmentSlot _selectedEquipmentSlot = EquipmentSlot.none;
  Set<CharacterClass> _selectedClasses = <CharacterClass>{};
  bool _isConsumable = false;
  bool _isTradeable = true;
  
  // Lists for modifiers, conditions, effects
  List<StatModifier> _statModifiers = [];
  List<CardCondition> _conditions = [];
  List<CardEffect> _effects = [];
  
  // Validation errors
  List<String> _validationErrors = [];
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadExistingCard();
  }
  
  void _initializeControllers() {
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _imageUrlController = TextEditingController();
    _costController = TextEditingController(text: '0');
    _levelRequirementController = TextEditingController(text: '1');
    _durabilityController = TextEditingController(text: '100');
    _maxStackController = TextEditingController(text: '1');
  }
  
  void _loadExistingCard() {
    if (widget.editingCard != null) {
      final card = widget.editingCard!;
      _nameController.text = card.name;
      _descriptionController.text = card.description;
      _imageUrlController.text = card.imageUrl;
      _costController.text = card.cost.toString();
      _levelRequirementController.text = card.levelRequirement.toString();
      _durabilityController.text = card.durability.toString();
      _maxStackController.text = card.maxStack.toString();
      
      _selectedType = card.type;
      _selectedRarity = card.rarity;
      _selectedEquipmentSlot = card.equipmentSlot;
      _selectedClasses = Set.from(card.allowedClasses);
      _isConsumable = card.isConsumable;
      _isTradeable = card.isTradeable;
      
      _statModifiers = List.from(card.statModifiers);
      _conditions = List.from(card.conditions);
      _effects = List.from(card.effects);
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _costController.dispose();
    _levelRequirementController.dispose();
    _durabilityController.dispose();
    _maxStackController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editingCard != null ? 'Edit Card' : 'Create Card'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveCard,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'template', child: Text('Save as Template')),
              const PopupMenuItem(value: 'load_template', child: Text('Load Template')),
              const PopupMenuItem(value: 'random', child: Text('Generate Random')),
              const PopupMenuItem(value: 'clear', child: Text('Clear All')),
            ],
          ),
        ],
      ),
      body: Row(
        children: [
          // Editor Panel
          Expanded(
            flex: 2,
            child: _buildEditorPanel(),
          ),
          
          // Preview Panel
          Container(
            width: 300,
            decoration: const BoxDecoration(
              color: RealmOfValorTheme.surfaceDark,
              border: Border(
                left: BorderSide(color: RealmOfValorTheme.primaryLight),
              ),
            ),
            child: _buildPreviewPanel(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEditorPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Validation Errors
            if (_validationErrors.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: RealmOfValorTheme.healthRed.withOpacity(0.2),
                  border: Border.all(color: RealmOfValorTheme.healthRed),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Validation Errors:',
                      style: TextStyle(
                        color: RealmOfValorTheme.healthRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...(_validationErrors.map((error) => Text(
                      '• $error',
                      style: const TextStyle(color: RealmOfValorTheme.healthRed),
                    ))),
                  ],
                ),
              ),
            
            // Basic Information
            _buildSection('Basic Information', [
              _buildTextField('Name', _nameController, required: true),
              _buildTextField('Description', _descriptionController, 
                  maxLines: 3, required: true),
              _buildTextField('Image URL', _imageUrlController),
            ]),
            
            // Card Properties
            _buildSection('Card Properties', [
              _buildDropdown<CardType>(
                'Type',
                _selectedType,
                CardType.values,
                (value) => setState(() => _selectedType = value!),
                (type) => type.name.toUpperCase(),
              ),
              _buildDropdown<CardRarity>(
                'Rarity',
                _selectedRarity,
                CardRarity.values,
                (value) => setState(() => _selectedRarity = value!),
                (rarity) => rarity.name.toUpperCase(),
              ),
              if (_selectedType == CardType.weapon || 
                  _selectedType == CardType.armor ||
                  _selectedType == CardType.accessory)
                _buildDropdown<EquipmentSlot>(
                  'Equipment Slot',
                  _selectedEquipmentSlot,
                  EquipmentSlot.values,
                  (value) => setState(() => _selectedEquipmentSlot = value!),
                  (slot) => slot.name.toUpperCase(),
                ),
            ]),
            
            // Numeric Properties
            _buildSection('Numeric Properties', [
              _buildNumberField('Cost', _costController),
              _buildNumberField('Level Requirement', _levelRequirementController),
              _buildNumberField('Durability', _durabilityController),
              _buildNumberField('Max Stack', _maxStackController),
            ]),
            
            // Flags
            _buildSection('Properties', [
              CheckboxListTile(
                title: const Text('Consumable'),
                value: _isConsumable,
                onChanged: (value) => setState(() => _isConsumable = value!),
                activeColor: RealmOfValorTheme.accentGold,
              ),
              CheckboxListTile(
                title: const Text('Tradeable'),
                value: _isTradeable,
                onChanged: (value) => setState(() => _isTradeable = value!),
                activeColor: RealmOfValorTheme.accentGold,
              ),
            ]),
            
            // Character Classes
            _buildSection('Allowed Classes', [
              _buildClassSelector(),
            ]),
            
            // Stat Modifiers
            _buildSection('Stat Modifiers', [
              _buildStatModifiersList(),
              ElevatedButton.icon(
                onPressed: _addStatModifier,
                icon: const Icon(Icons.add),
                label: const Text('Add Stat Modifier'),
              ),
            ]),
            
            // Conditions
            _buildSection('Conditions', [
              _buildConditionsList(),
              ElevatedButton.icon(
                onPressed: _addCondition,
                icon: const Icon(Icons.add),
                label: const Text('Add Condition'),
              ),
            ]),
            
            // Effects
            _buildSection('Effects', [
              _buildEffectsList(),
              ElevatedButton.icon(
                onPressed: _addEffect,
                icon: const Icon(Icons.add),
                label: const Text('Add Effect'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPreviewPanel() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preview',
            style: TextStyle(
              color: RealmOfValorTheme.accentGold,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Card Preview
          Center(
            child: CardWidget(
              cardInstance: CardInstance(card: _buildPreviewCard()),
              width: 200,
              height: 280,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Quick Stats
          _buildQuickStats(),
        ],
      ),
    );
  }
  
  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            title,
            style: const TextStyle(
              color: RealmOfValorTheme.accentGold,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
  
  Widget _buildTextField(String label, TextEditingController controller, 
      {int maxLines = 1, bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: required ? (value) {
          if (value == null || value.trim().isEmpty) {
            return '$label is required';
          }
          return null;
        } : null,
        onChanged: (_) => setState(() {}), // Trigger preview update
      ),
    );
  }
  
  Widget _buildNumberField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return '$label is required';
          if (int.tryParse(value) == null) return '$label must be a number';
          return null;
        },
        onChanged: (_) => setState(() {}),
      ),
    );
  }
  
  Widget _buildDropdown<T>(
    String label,
    T value,
    List<T> items,
    ValueChanged<T?> onChanged,
    String Function(T) itemToString,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items.map((item) => DropdownMenuItem(
          value: item,
          child: Text(itemToString(item)),
        )).toList(),
        onChanged: (newValue) {
          onChanged(newValue);
          setState(() {});
        },
      ),
    );
  }
  
  Widget _buildClassSelector() {
    return Column(
      children: CharacterClass.values.map((characterClass) {
        return CheckboxListTile(
          title: Text(characterClass.name.toUpperCase()),
          value: _selectedClasses.contains(characterClass),
          onChanged: (value) {
            setState(() {
              if (value!) {
                _selectedClasses.add(characterClass);
              } else {
                _selectedClasses.remove(characterClass);
              }
            });
          },
          activeColor: RealmOfValorTheme.accentGold,
        );
      }).toList(),
    );
  }
  
  Widget _buildStatModifiersList() {
    return Column(
      children: _statModifiers.asMap().entries.map((entry) {
        final index = entry.key;
        final modifier = entry.value;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        modifier.statName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${modifier.isPercentage ? '+' : ''}${modifier.value}${modifier.isPercentage ? '%' : ''}',
                        style: const TextStyle(color: RealmOfValorTheme.experienceGreen),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: RealmOfValorTheme.accentGold),
                  onPressed: () => _editStatModifier(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: RealmOfValorTheme.healthRed),
                  onPressed: () => _removeStatModifier(index),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildConditionsList() {
    return Column(
      children: _conditions.asMap().entries.map((entry) {
        final index = entry.key;
        final condition = entry.value;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        condition.type,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(condition.description),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: RealmOfValorTheme.accentGold),
                  onPressed: () => _editCondition(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: RealmOfValorTheme.healthRed),
                  onPressed: () => _removeCondition(index),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildEffectsList() {
    return Column(
      children: _effects.asMap().entries.map((entry) {
        final index = entry.key;
        final effect = entry.value;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        effect.type,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(effect.description),
                      if (effect.duration > 0)
                        Text(
                          'Duration: ${effect.duration}',
                          style: const TextStyle(color: RealmOfValorTheme.textSecondary),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: RealmOfValorTheme.accentGold),
                  onPressed: () => _editEffect(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: RealmOfValorTheme.healthRed),
                  onPressed: () => _removeEffect(index),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildQuickStats() {
    final card = _buildPreviewCard();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Stats',
          style: TextStyle(
            color: RealmOfValorTheme.accentGold,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildStatRow('Type', card.type.name.toUpperCase()),
        _buildStatRow('Rarity', card.rarity.name.toUpperCase()),
        _buildStatRow('Level Req', card.levelRequirement.toString()),
        _buildStatRow('Cost', card.cost.toString()),
        _buildStatRow('Durability', card.durability.toString()),
        if (card.statModifiers.isNotEmpty)
          _buildStatRow('Modifiers', card.statModifiers.length.toString()),
        if (card.effects.isNotEmpty)
          _buildStatRow('Effects', card.effects.length.toString()),
        if (card.conditions.isNotEmpty)
          _buildStatRow('Conditions', card.conditions.length.toString()),
      ],
    );
  }
  
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: RealmOfValorTheme.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(color: RealmOfValorTheme.textPrimary),
          ),
        ],
      ),
    );
  }
  
  GameCard _buildPreviewCard() {
    return GameCard(
      id: widget.editingCard?.id,
      name: _nameController.text.isEmpty ? 'Unnamed Card' : _nameController.text,
      description: _descriptionController.text,
      type: _selectedType,
      rarity: _selectedRarity,
      equipmentSlot: _selectedEquipmentSlot,
      allowedClasses: _selectedClasses,
      statModifiers: _statModifiers,
      conditions: _conditions,
      effects: _effects,
      imageUrl: _imageUrlController.text,
      cost: int.tryParse(_costController.text) ?? 0,
      levelRequirement: int.tryParse(_levelRequirementController.text) ?? 1,
      durability: int.tryParse(_durabilityController.text) ?? 100,
      maxStack: int.tryParse(_maxStackController.text) ?? 1,
      isConsumable: _isConsumable,
      isTradeable: _isTradeable,
    );
  }
  
  void _saveCard() async {
    if (!_formKey.currentState!.validate()) return;
    
    final card = _buildPreviewCard();
    _cardService = CardService(await SharedPreferences.getInstance());
    
    final errors = _cardService.validateCard(card);
    if (errors.isNotEmpty) {
      setState(() {
        _validationErrors = errors;
      });
      return;
    }
    
    setState(() {
      _validationErrors = [];
    });
    
    try {
      if (widget.editingCard != null) {
        await _cardService.updateCard(card);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Card updated successfully!')),
          );
        }
      } else {
        await _cardService.createCard(card);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Card created successfully!')),
          );
        }
      }
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving card: $e')),
        );
      }
    }
  }
  
  void _handleMenuAction(String action) async {
    _cardService = CardService(await SharedPreferences.getInstance());
    
    switch (action) {
      case 'template':
        await _cardService.saveAsTemplate(_buildPreviewCard());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Card saved as template!')),
          );
        }
        break;
      case 'load_template':
        _showTemplateSelector();
        break;
      case 'random':
        _loadRandomCard();
        break;
      case 'clear':
        _clearForm();
        break;
    }
  }
  
  void _showTemplateSelector() {
    // Implementation for template selector dialog
  }
  
  void _loadRandomCard() {
    // Implementation for loading random card
  }
  
  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _imageUrlController.clear();
    _costController.text = '0';
    _levelRequirementController.text = '1';
    _durabilityController.text = '100';
    _maxStackController.text = '1';
    
    setState(() {
      _selectedType = CardType.item;
      _selectedRarity = CardRarity.common;
      _selectedEquipmentSlot = EquipmentSlot.none;
      _selectedClasses.clear();
      _isConsumable = false;
      _isTradeable = true;
      _statModifiers.clear();
      _conditions.clear();
      _effects.clear();
      _validationErrors.clear();
    });
  }
  
  void _addStatModifier() {
    // Implementation for adding stat modifier dialog
  }
  
  void _editStatModifier(int index) {
    // Implementation for editing stat modifier dialog
  }
  
  void _removeStatModifier(int index) {
    setState(() {
      _statModifiers.removeAt(index);
    });
  }
  
  void _addCondition() {
    // Implementation for adding condition dialog
  }
  
  void _editCondition(int index) {
    // Implementation for editing condition dialog
  }
  
  void _removeCondition(int index) {
    setState(() {
      _conditions.removeAt(index);
    });
  }
  
  void _addEffect() {
    // Implementation for adding effect dialog
  }
  
  void _editEffect(int index) {
    // Implementation for editing effect dialog
  }
  
  void _removeEffect(int index) {
    setState(() {
      _effects.removeAt(index);
    });
  }
}