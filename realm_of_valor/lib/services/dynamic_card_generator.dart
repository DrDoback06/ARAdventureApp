import 'dart:math' as math;
import 'dart:convert';

import '../models/battle_system.dart';
import '../models/adventure_system.dart';

class DynamicCardGenerator {
  static final DynamicCardGenerator _instance = DynamicCardGenerator._internal();
  factory DynamicCardGenerator() => _instance;
  DynamicCardGenerator._internal();

  final Random _random = Random();
  
  // Card generation templates organized by class and type
  final Map<CharacterClass, List<CardTemplate>> _classTemplates = {};
  final List<CardTemplate> _universalTemplates = [];
  final List<CardEffect> _availableEffects = [];

  // Enhanced Idea 1: Procedural Ability Generation System
  // Enhanced Idea 2: Equipment-Based Card Creation System

  // Initialize the card generator with templates
  void initialize() {
    _initializeCardTemplates();
    _initializeCardEffects();
    print('Dynamic Card Generator initialized');
  }

  // CORE CARD GENERATION

  // Generate a deck for a character based on class, level, and equipment
  List<BattleCard> generateCharacterDeck({
    required CharacterClass characterClass,
    required int characterLevel,
    required CharacterStats stats,
    Map<String, dynamic>? equipment,
    List<String>? availableCards,
    int deckSize = 30,
  }) {
    final deck = <BattleCard>[];
    equipment ??= {};
    
    // Calculate card distribution based on character level
    final distribution = _calculateCardDistribution(characterLevel, deckSize);
    
    // Generate cards by rarity
    for (final entry in distribution.entries) {
      final rarity = entry.key;
      final count = entry.value;
      
      for (int i = 0; i < count; i++) {
        final card = generateCard(
          characterClass: characterClass,
          characterLevel: characterLevel,
          stats: stats,
          rarity: rarity,
          equipment: equipment,
        );
        deck.add(card);
      }
    }
    
    // Ensure deck has variety and synergy
    _optimizeDeckSynergy(deck, characterClass, stats);
    
    return deck;
  }

  // Generate a single card
  BattleCard generateCard({
    required CharacterClass characterClass,
    required int characterLevel,
    required CharacterStats stats,
    int rarity = 1,
    Map<String, dynamic>? equipment,
    CardType? forceType,
    String? theme,
  }) {
    equipment ??= {};
    
    // Select appropriate template
    final template = _selectCardTemplate(
      characterClass: characterClass,
      characterLevel: characterLevel,
      rarity: rarity,
      forceType: forceType,
      theme: theme,
    );
    
    // Generate card based on template and character stats
    return _generateCardFromTemplate(
      template: template,
      characterClass: characterClass,
      characterLevel: characterLevel,
      stats: stats,
      rarity: rarity,
      equipment: equipment,
    );
  }

  // Generate equipment-based card (Enhanced Idea 2)
  BattleCard generateEquipmentCard({
    required Map<String, dynamic> equipment,
    required CharacterClass characterClass,
    required CharacterStats stats,
    required int characterLevel,
  }) {
    final equipmentName = equipment['name'] as String? ?? 'Unknown Item';
    final equipmentType = equipment['type'] as String? ?? 'weapon';
    final equipmentRarity = equipment['rarity'] as int? ?? 1;
    
    // Create card based on equipment properties
    final template = _createEquipmentTemplate(equipment);
    
    return _generateCardFromTemplate(
      template: template,
      characterClass: characterClass,
      characterLevel: characterLevel,
      stats: stats,
      rarity: equipmentRarity,
      equipment: {equipmentName: equipment},
    );
  }

  // Generate skill tree card (Diablo II style)
  BattleCard generateSkillCard({
    required String skillName,
    required int skillLevel,
    required CharacterClass characterClass,
    required CharacterStats stats,
  }) {
    final template = _createSkillTemplate(skillName, skillLevel, characterClass);
    
    return _generateCardFromTemplate(
      template: template,
      characterClass: characterClass,
      characterLevel: skillLevel,
      stats: stats,
      rarity: _calculateSkillRarity(skillLevel),
      equipment: {},
    );
  }

  // TEMPLATE SYSTEM

  // Select appropriate template
  CardTemplate _selectCardTemplate({
    required CharacterClass characterClass,
    required int characterLevel,
    int rarity = 1,
    CardType? forceType,
    String? theme,
  }) {
    List<CardTemplate> candidates = [];
    
    // Add class-specific templates
    candidates.addAll(_classTemplates[characterClass] ?? []);
    
    // Add universal templates
    candidates.addAll(_universalTemplates);
    
    // Filter by requirements
    candidates = candidates.where((template) {
      return template.minLevel <= characterLevel &&
             template.maxLevel >= characterLevel &&
             (forceType == null || template.cardType == forceType) &&
             (theme == null || template.themes.contains(theme));
    }).toList();
    
    // Weight by rarity
    candidates = candidates.where((template) {
      return template.rarity == rarity || 
             (template.rarity - 1 <= rarity && template.rarity + 1 >= rarity);
    }).toList();
    
    if (candidates.isEmpty) {
      return _getDefaultTemplate(characterClass, forceType ?? CardType.spell);
    }
    
    // Select random template with weight preference
    return _selectWeightedTemplate(candidates, rarity);
  }

  // Generate card from template
  BattleCard _generateCardFromTemplate({
    required CardTemplate template,
    required CharacterClass characterClass,
    required int characterLevel,
    required CharacterStats stats,
    required int rarity,
    required Map<String, dynamic> equipment,
  }) {
    // Calculate base stats
    final manaCost = _calculateManaCost(template, characterLevel, stats);
    final attack = _calculateAttack(template, characterLevel, stats, equipment);
    final defense = _calculateDefense(template, characterLevel, stats, equipment);
    final health = _calculateHealth(template, characterLevel, stats, equipment);
    
    // Generate abilities (Enhanced Idea 1)
    final abilities = _generateAbilities(template, characterClass, stats, equipment);
    final keywords = _generateKeywords(template, characterClass, rarity);
    
    // Generate dynamic name and description
    final name = _generateCardName(template, characterClass, equipment);
    final description = _generateCardDescription(template, abilities, attack, defense, health);
    
    // Determine target type
    final targetType = _determineTargetType(template, abilities);
    
    // Generate effects
    final effects = _generateCardEffects(template, abilities, stats);
    
    // Create card
    return BattleCard(
      name: name,
      description: description,
      type: template.cardType,
      manaCost: manaCost,
      attack: attack,
      defense: defense,
      health: health,
      damageTypes: template.damageTypes,
      targetType: targetType,
      abilities: abilities,
      keywords: keywords,
      effects: effects,
      rarity: rarity,
      requiredClasses: template.requiredClasses.isNotEmpty 
          ? template.requiredClasses 
          : [characterClass],
      statRequirements: _generateStatRequirements(template, characterLevel),
      flavorText: _generateFlavorText(template, characterClass),
    );
  }

  // CALCULATION METHODS

  // Calculate mana cost based on template and stats
  int _calculateManaCost(CardTemplate template, int characterLevel, CharacterStats stats) {
    int baseCost = template.baseMana;
    
    // Adjust for character level
    baseCost = (baseCost * (1.0 + characterLevel * 0.05)).round();
    
    // Apply stat scaling
    if (template.scalingStats.contains('intelligence')) {
      baseCost = math.max(1, baseCost - (stats.intelligence ~/ 20));
    }
    
    if (template.scalingStats.contains('energy')) {
      baseCost = math.max(1, baseCost - (stats.energy ~/ 15));
    }
    
    return math.max(1, baseCost);
  }

  // Calculate attack value
  int? _calculateAttack(CardTemplate template, int characterLevel, CharacterStats stats, Map<String, dynamic> equipment) {
    if (template.baseAttack == null) return null;
    
    int attack = template.baseAttack!;
    
    // Level scaling
    attack += (characterLevel * template.levelScaling * 0.3).round();
    
    // Stat scaling
    if (template.scalingStats.contains('strength')) {
      attack += (stats.strength * 0.5).round();
    }
    
    if (template.scalingStats.contains('intelligence')) {
      attack += (stats.intelligence * 0.4).round();
    }
    
    if (template.scalingStats.contains('dexterity')) {
      attack += (stats.dexterity * 0.3).round();
    }
    
    // Equipment bonuses
    attack += _calculateEquipmentBonus(equipment, 'attack');
    
    return math.max(1, attack);
  }

  // Calculate defense value
  int? _calculateDefense(CardTemplate template, int characterLevel, CharacterStats stats, Map<String, dynamic> equipment) {
    if (template.baseDefense == null) return null;
    
    int defense = template.baseDefense!;
    
    // Level and stat scaling
    defense += (characterLevel * template.levelScaling * 0.2).round();
    defense += (stats.dexterity * 0.3).round();
    defense += (stats.vitality * 0.2).round();
    
    // Equipment bonuses
    defense += _calculateEquipmentBonus(equipment, 'defense');
    
    return math.max(0, defense);
  }

  // Calculate health value
  int? _calculateHealth(CardTemplate template, int characterLevel, CharacterStats stats, Map<String, dynamic> equipment) {
    if (template.baseHealth == null) return null;
    
    int health = template.baseHealth!;
    
    // Scaling
    health += (characterLevel * template.levelScaling * 0.5).round();
    health += (stats.vitality * 0.4).round();
    
    // Equipment bonuses
    health += _calculateEquipmentBonus(equipment, 'health');
    
    return math.max(1, health);
  }

  // Calculate equipment bonus
  int _calculateEquipmentBonus(Map<String, dynamic> equipment, String bonusType) {
    int bonus = 0;
    
    for (final item in equipment.values) {
      if (item is Map<String, dynamic>) {
        final itemBonus = item[bonusType] as int? ?? 0;
        bonus += itemBonus;
      }
    }
    
    return bonus;
  }

  // ABILITY GENERATION (Enhanced Idea 1)

  // Generate abilities based on template and character
  List<String> _generateAbilities(CardTemplate template, CharacterClass characterClass, CharacterStats stats, Map<String, dynamic> equipment) {
    final abilities = <String>[];
    
    // Add template abilities
    abilities.addAll(template.baseAbilities);
    
    // Generate procedural abilities based on stats
    abilities.addAll(_generateProceduralAbilities(characterClass, stats, equipment));
    
    // Add class-specific abilities
    abilities.addAll(_generateClassAbilities(characterClass, stats));
    
    // Remove duplicates and limit count
    final uniqueAbilities = abilities.toSet().toList();
    return uniqueAbilities.take(math.min(4, uniqueAbilities.length)).toList();
  }

  // Generate procedural abilities based on high stats
  List<String> _generateProceduralAbilities(CharacterClass characterClass, CharacterStats stats, Map<String, dynamic> equipment) {
    final abilities = <String>[];
    
    // Strength-based abilities
    if (stats.strength >= 20) {
      abilities.add('strength_scaling');
      if (stats.strength >= 30) {
        abilities.add('crushing_blow');
      }
    }
    
    // Intelligence-based abilities
    if (stats.intelligence >= 20) {
      abilities.add('intelligence_scaling');
      if (stats.intelligence >= 30) {
        abilities.add('spell_pierce');
      }
    }
    
    // Dexterity-based abilities
    if (stats.dexterity >= 20) {
      abilities.add('precision');
      if (stats.dexterity >= 30) {
        abilities.add('double_strike');
      }
    }
    
    // Vitality-based abilities
    if (stats.vitality >= 25) {
      abilities.add('regeneration');
      if (stats.vitality >= 35) {
        abilities.add('damage_reduction');
      }
    }
    
    // Luck-based abilities
    if (stats.luck >= 15) {
      abilities.add('critical_strike');
      if (stats.luck >= 25) {
        abilities.add('lucky_find');
      }
    }
    
    // Equipment-based abilities
    abilities.addAll(_generateEquipmentAbilities(equipment));
    
    return abilities;
  }

  // Generate class-specific abilities
  List<String> _generateClassAbilities(CharacterClass characterClass, CharacterStats stats) {
    switch (characterClass) {
      case CharacterClass.warrior:
        return ['weapon_mastery', 'battle_cry', 'armor_expertise'];
      case CharacterClass.mage:
        return ['spell_mastery', 'mana_shield', 'elemental_focus'];
      case CharacterClass.rogue:
        return ['stealth', 'backstab', 'trap_mastery'];
      case CharacterClass.paladin:
        return ['holy_power', 'divine_protection', 'aura_mastery'];
      case CharacterClass.necromancer:
        return ['summon_mastery', 'death_magic', 'corpse_explosion'];
      case CharacterClass.barbarian:
        return ['rage', 'intimidate', 'dual_wield'];
      case CharacterClass.sorceress:
        return ['elemental_mastery', 'teleport', 'time_magic'];
      case CharacterClass.amazon:
        return ['bow_mastery', 'javelin_skills', 'dodge'];
      case CharacterClass.druid:
        return ['shape_shift', 'nature_magic', 'summon_nature'];
      case CharacterClass.monk:
        return ['martial_arts', 'inner_power', 'meditation'];
    }
  }

  // Generate equipment-based abilities
  List<String> _generateEquipmentAbilities(Map<String, dynamic> equipment) {
    final abilities = <String>[];
    
    for (final item in equipment.values) {
      if (item is Map<String, dynamic>) {
        final itemAbilities = item['abilities'] as List<String>? ?? [];
        abilities.addAll(itemAbilities);
        
        // Generate abilities based on equipment type
        final itemType = item['type'] as String? ?? '';
        switch (itemType) {
          case 'weapon':
            abilities.add('weapon_strike');
            break;
          case 'armor':
            abilities.add('armor_ward');
            break;
          case 'accessory':
            abilities.add('magical_enhancement');
            break;
        }
      }
    }
    
    return abilities;
  }

  // NAME AND DESCRIPTION GENERATION

  // Generate dynamic card name
  String _generateCardName(CardTemplate template, CharacterClass characterClass, Map<String, dynamic> equipment) {
    final prefixes = template.namePrefixes;
    final suffixes = template.nameSuffixes;
    final roots = template.nameRoots;
    
    // Equipment-influenced names
    if (equipment.isNotEmpty) {
      final equipmentName = equipment.keys.first;
      return '${roots.isNotEmpty ? roots[_random.nextInt(roots.length)] : template.baseName} of ${equipmentName}';
    }
    
    // Class-influenced names
    final classPrefix = _getClassNamePrefix(characterClass);
    final prefix = prefixes.isNotEmpty ? prefixes[_random.nextInt(prefixes.length)] : classPrefix;
    final suffix = suffixes.isNotEmpty ? suffixes[_random.nextInt(suffixes.length)] : '';
    final root = roots.isNotEmpty ? roots[_random.nextInt(roots.length)] : template.baseName;
    
    return '$prefix $root $suffix'.trim();
  }

  // Generate card description
  String _generateCardDescription(CardTemplate template, List<String> abilities, int? attack, int? defense, int? health) {
    String description = template.baseDescription;
    
    // Add ability descriptions
    final abilityDescriptions = abilities.map((ability) => _getAbilityDescription(ability)).where((desc) => desc.isNotEmpty);
    if (abilityDescriptions.isNotEmpty) {
      description += '\n${abilityDescriptions.join('\n')}';
    }
    
    // Add stat information for creatures
    if (attack != null && defense != null && health != null) {
      description += '\n\nA ${template.creatureType ?? 'creature'} with balanced combat capabilities.';
    }
    
    return description.trim();
  }

  // Generate flavor text
  String _generateFlavorText(CardTemplate template, CharacterClass characterClass) {
    final flavorTexts = template.flavorTexts;
    if (flavorTexts.isEmpty) {
      return _getClassFlavorText(characterClass);
    }
    
    return flavorTexts[_random.nextInt(flavorTexts.length)];
  }

  // UTILITY METHODS

  // Calculate card distribution by rarity
  Map<int, int> _calculateCardDistribution(int characterLevel, int deckSize) {
    final distribution = <int, int>{};
    
    // Base distribution
    distribution[1] = (deckSize * 0.5).round(); // 50% common
    distribution[2] = (deckSize * 0.3).round(); // 30% uncommon
    distribution[3] = (deckSize * 0.15).round(); // 15% rare
    distribution[4] = (deckSize * 0.04).round(); // 4% epic
    distribution[5] = (deckSize * 0.01).round(); // 1% legendary
    
    // Adjust based on character level
    if (characterLevel >= 10) {
      distribution[2] = distribution[2]! + 2;
      distribution[1] = distribution[1]! - 2;
    }
    
    if (characterLevel >= 20) {
      distribution[3] = distribution[3]! + 2;
      distribution[2] = distribution[2]! - 2;
    }
    
    if (characterLevel >= 30) {
      distribution[4] = distribution[4]! + 1;
      distribution[3] = distribution[3]! - 1;
    }
    
    // Ensure total equals deck size
    final total = distribution.values.fold(0, (sum, count) => sum + count);
    if (total != deckSize) {
      distribution[1] = distribution[1]! + (deckSize - total);
    }
    
    return distribution;
  }

  // Optimize deck synergy
  void _optimizeDeckSynergy(List<BattleCard> deck, CharacterClass characterClass, CharacterStats stats) {
    // Group cards by synergy potential
    final synergyGroups = <String, List<BattleCard>>{};
    
    for (final card in deck) {
      for (final ability in card.abilities) {
        synergyGroups.putIfAbsent(ability, () => []).add(card);
      }
    }
    
    // Ensure minimum synergy cards
    for (final group in synergyGroups.values) {
      if (group.length == 1) {
        // Find and replace a similar card to create synergy
        _addSynergyCard(deck, group.first, characterClass, stats);
      }
    }
  }

  // Add synergy card
  void _addSynergyCard(List<BattleCard> deck, BattleCard referenceCard, CharacterClass characterClass, CharacterStats stats) {
    // Find a card to replace
    final candidates = deck.where((card) => 
      card.rarity == referenceCard.rarity && 
      card.type == referenceCard.type &&
      card.abilities.isEmpty
    ).toList();
    
    if (candidates.isNotEmpty) {
      final targetCard = candidates.first;
      final index = deck.indexOf(targetCard);
      
      // Generate synergy card
      final synergyCard = generateCard(
        characterClass: characterClass,
        characterLevel: 10, // Default level
        stats: stats,
        rarity: referenceCard.rarity,
        forceType: referenceCard.type,
        theme: referenceCard.abilities.first,
      );
      
      deck[index] = synergyCard;
    }
  }

  // INITIALIZATION METHODS

  // Initialize card templates
  void _initializeCardTemplates() {
    _initializeWarriorTemplates();
    _initializeMageTemplates();
    _initializeRogueTemplates();
    _initializePaladinTemplates();
    _initializeNecromancerTemplates();
    _initializeUniversalTemplates();
  }

  // Initialize warrior templates
  void _initializeWarriorTemplates() {
    _classTemplates[CharacterClass.warrior] = [
      CardTemplate(
        baseName: 'Strike',
        baseDescription: 'A powerful melee attack that scales with Strength.',
        cardType: CardType.spell,
        baseMana: 2,
        baseAttack: 3,
        rarity: 1,
        minLevel: 1,
        maxLevel: 50,
        levelScaling: 0.5,
        scalingStats: ['strength'],
        damageTypes: [DamageType.physical],
        baseAbilities: ['strength_scaling'],
        requiredClasses: [CharacterClass.warrior, CharacterClass.barbarian],
        namePrefixes: ['Mighty', 'Powerful', 'Devastating'],
        nameRoots: ['Strike', 'Blow', 'Slash'],
        nameSuffixes: ['of Power', 'of Strength', 'of Might'],
        themes: ['combat', 'melee', 'strength'],
        flavorTexts: ['The mark of a true warrior.', 'Strength conquers all.'],
      ),
    ];
  }

  // Initialize mage templates
  void _initializeMageTemplates() {
    _classTemplates[CharacterClass.mage] = [
      CardTemplate(
        baseName: 'Bolt',
        baseDescription: 'A magical projectile that scales with Intelligence.',
        cardType: CardType.spell,
        baseMana: 3,
        baseAttack: 4,
        rarity: 1,
        minLevel: 1,
        maxLevel: 50,
        levelScaling: 0.6,
        scalingStats: ['intelligence'],
        damageTypes: [DamageType.magical],
        baseAbilities: ['intelligence_scaling'],
        requiredClasses: [CharacterClass.mage, CharacterClass.sorceress],
        namePrefixes: ['Arcane', 'Mystic', 'Ethereal'],
        nameRoots: ['Bolt', 'Blast', 'Ray'],
        nameSuffixes: ['of Knowledge', 'of Power', 'of Wisdom'],
        themes: ['magic', 'intelligence', 'elemental'],
        flavorTexts: ['Knowledge is power.', 'Magic flows through all things.'],
      ),
    ];
  }

  // Placeholder initialization methods
  void _initializeRogueTemplates() {
    _classTemplates[CharacterClass.rogue] = [];
  }

  void _initializePaladinTemplates() {
    _classTemplates[CharacterClass.paladin] = [];
  }

  void _initializeNecromancerTemplates() {
    _classTemplates[CharacterClass.necromancer] = [];
  }

  void _initializeUniversalTemplates() {
    _universalTemplates.addAll([
      CardTemplate(
        baseName: 'Heal',
        baseDescription: 'Restore health to target.',
        cardType: CardType.spell,
        baseMana: 2,
        baseAttack: 3,
        rarity: 1,
        minLevel: 1,
        maxLevel: 50,
        levelScaling: 0.4,
        scalingStats: ['intelligence', 'vitality'],
        damageTypes: [DamageType.holy],
        baseAbilities: ['heal'],
        requiredClasses: [],
        namePrefixes: ['Minor', 'Greater', 'Divine'],
        nameRoots: ['Heal', 'Cure', 'Restore'],
        nameSuffixes: ['', 'ing', 'ation'],
        themes: ['healing', 'support', 'holy'],
        flavorTexts: ['Life finds a way.', 'Healing comes from within.'],
      ),
    ]);
  }

  void _initializeCardEffects() {
    _availableEffects.addAll([
      DamageEffect(damage: 3, damageType: DamageType.physical),
      HealEffect(amount: 3),
    ]);
  }

  // Helper methods with placeholder implementations
  CardTemplate _getDefaultTemplate(CharacterClass characterClass, CardType cardType) {
    return CardTemplate(
      baseName: 'Basic ${cardType.name}',
      baseDescription: 'A basic ${cardType.name} for ${characterClass.name}',
      cardType: cardType,
      baseMana: 2,
      baseAttack: cardType == CardType.spell ? 2 : null,
      rarity: 1,
      minLevel: 1,
      maxLevel: 50,
      levelScaling: 0.3,
      scalingStats: ['strength'],
      damageTypes: [DamageType.physical],
      baseAbilities: [],
      requiredClasses: [characterClass],
      namePrefixes: ['Basic'],
      nameRoots: [cardType.name],
      nameSuffixes: [''],
      themes: ['basic'],
      flavorTexts: ['A fundamental ability.'],
    );
  }

  CardTemplate _selectWeightedTemplate(List<CardTemplate> candidates, int rarity) {
    return candidates[_random.nextInt(candidates.length)];
  }

  CardTemplate _createEquipmentTemplate(Map<String, dynamic> equipment) {
    final name = equipment['name'] as String? ?? 'Equipment';
    return CardTemplate(
      baseName: name,
      baseDescription: 'A card based on equipped $name',
      cardType: CardType.artifact,
      baseMana: 3,
      baseAttack: equipment['attack'] as int? ?? 3,
      rarity: equipment['rarity'] as int? ?? 1,
      minLevel: 1,
      maxLevel: 50,
      levelScaling: 0.4,
      scalingStats: ['strength', 'dexterity'],
      damageTypes: [DamageType.physical],
      baseAbilities: equipment['abilities'] as List<String>? ?? [],
      requiredClasses: [],
      namePrefixes: ['Enchanted'],
      nameRoots: [name],
      nameSuffixes: ['Strike'],
      themes: ['equipment'],
      flavorTexts: ['The power of equipped gear.'],
    );
  }

  CardTemplate _createSkillTemplate(String skillName, int skillLevel, CharacterClass characterClass) {
    return CardTemplate(
      baseName: skillName,
      baseDescription: 'A skill-based ability from the $skillName tree',
      cardType: CardType.skill,
      baseMana: 2 + skillLevel,
      baseAttack: skillLevel * 2,
      rarity: _calculateSkillRarity(skillLevel),
      minLevel: skillLevel,
      maxLevel: 50,
      levelScaling: 0.5,
      scalingStats: _getSkillScalingStats(characterClass),
      damageTypes: _getSkillDamageTypes(characterClass),
      baseAbilities: [skillName.toLowerCase().replaceAll(' ', '_')],
      requiredClasses: [characterClass],
      namePrefixes: ['Advanced', 'Master'],
      nameRoots: [skillName],
      nameSuffixes: ['Technique', 'Mastery'],
      themes: ['skill', 'mastery'],
      flavorTexts: ['Mastery through practice.'],
    );
  }

  int _calculateSkillRarity(int skillLevel) {
    if (skillLevel >= 20) return 5;
    if (skillLevel >= 15) return 4;
    if (skillLevel >= 10) return 3;
    if (skillLevel >= 5) return 2;
    return 1;
  }

  List<String> _getSkillScalingStats(CharacterClass characterClass) {
    switch (characterClass) {
      case CharacterClass.warrior:
      case CharacterClass.barbarian:
        return ['strength', 'vitality'];
      case CharacterClass.mage:
      case CharacterClass.sorceress:
      case CharacterClass.necromancer:
        return ['intelligence', 'energy'];
      case CharacterClass.rogue:
      case CharacterClass.amazon:
        return ['dexterity', 'luck'];
      default:
        return ['strength', 'intelligence'];
    }
  }

  List<DamageType> _getSkillDamageTypes(CharacterClass characterClass) {
    switch (characterClass) {
      case CharacterClass.mage:
      case CharacterClass.sorceress:
        return [DamageType.fire, DamageType.ice, DamageType.lightning];
      case CharacterClass.necromancer:
        return [DamageType.shadow, DamageType.poison];
      case CharacterClass.paladin:
        return [DamageType.holy, DamageType.physical];
      default:
        return [DamageType.physical];
    }
  }

  TargetType _determineTargetType(CardTemplate template, List<String> abilities) {
    if (abilities.contains('heal')) return TargetType.self;
    if (template.cardType == CardType.creature) return TargetType.none;
    if (template.cardType == CardType.spell) return TargetType.opponent;
    return TargetType.none;
  }

  Map<String, dynamic> _generateCardEffects(CardTemplate template, List<String> abilities, CharacterStats stats) {
    return {};
  }

  Map<String, int> _generateStatRequirements(CardTemplate template, int characterLevel) {
    final requirements = <String, int>{};
    
    for (final stat in template.scalingStats) {
      requirements[stat] = math.max(1, (characterLevel * 0.5).round());
    }
    
    return requirements;
  }

  String _getClassNamePrefix(CharacterClass characterClass) {
    switch (characterClass) {
      case CharacterClass.warrior: return 'Warrior\'s';
      case CharacterClass.mage: return 'Arcane';
      case CharacterClass.rogue: return 'Shadow';
      case CharacterClass.paladin: return 'Divine';
      case CharacterClass.necromancer: return 'Dark';
      case CharacterClass.barbarian: return 'Savage';
      case CharacterClass.sorceress: return 'Elemental';
      case CharacterClass.amazon: return 'Huntress\'s';
      case CharacterClass.druid: return 'Natural';
      case CharacterClass.monk: return 'Inner';
    }
  }

  String _getAbilityDescription(String ability) {
    switch (ability) {
      case 'strength_scaling': return 'Damage scales with Strength.';
      case 'intelligence_scaling': return 'Damage scales with Intelligence.';
      case 'heal': return 'Restores health to target.';
      case 'critical_strike': return 'Has a chance to deal critical damage.';
      case 'stealth': return 'Cannot be targeted for 2 turns.';
      default: return '';
    }
  }

  String _getClassFlavorText(CharacterClass characterClass) {
    switch (characterClass) {
      case CharacterClass.warrior: return 'Honor through combat.';
      case CharacterClass.mage: return 'Knowledge is power.';
      case CharacterClass.rogue: return 'Strike from the shadows.';
      case CharacterClass.paladin: return 'Light guides the righteous.';
      case CharacterClass.necromancer: return 'Death is only the beginning.';
      default: return 'The path of adventure awaits.';
    }
  }
}

// Card template class
class CardTemplate {
  final String baseName;
  final String baseDescription;
  final CardType cardType;
  final int baseMana;
  final int? baseAttack;
  final int? baseDefense;
  final int? baseHealth;
  final int rarity;
  final int minLevel;
  final int maxLevel;
  final double levelScaling;
  final List<String> scalingStats;
  final List<DamageType> damageTypes;
  final List<String> baseAbilities;
  final List<CharacterClass> requiredClasses;
  final List<String> namePrefixes;
  final List<String> nameRoots;
  final List<String> nameSuffixes;
  final List<String> themes;
  final List<String> flavorTexts;
  final String? creatureType;

  CardTemplate({
    required this.baseName,
    required this.baseDescription,
    required this.cardType,
    required this.baseMana,
    this.baseAttack,
    this.baseDefense,
    this.baseHealth,
    required this.rarity,
    required this.minLevel,
    required this.maxLevel,
    required this.levelScaling,
    required this.scalingStats,
    required this.damageTypes,
    required this.baseAbilities,
    required this.requiredClasses,
    required this.namePrefixes,
    required this.nameRoots,
    required this.nameSuffixes,
    required this.themes,
    required this.flavorTexts,
    this.creatureType,
  });
}