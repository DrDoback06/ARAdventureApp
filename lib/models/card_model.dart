import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'card_model.g.dart';

/// Enum for different card types in the game
enum CardType {
  item,
  quest,
  adventure,
  skill,
  weapon,
  armor,
  accessory,
  consumable,
  spell,
  other
}

/// Enum for equipment slots
enum EquipmentSlot {
  helmet,
  armor,
  weapon1,
  weapon2,
  gloves,
  boots,
  belt,
  ring1,
  ring2,
  amulet,
  skill1,
  skill2,
  none
}

/// Enum for character classes
enum CharacterClass {
  holy,
  chaos,
  arcane,
  all // For cards that can be used by any class
}

/// Enum for rarity levels
enum CardRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  mythic
}

/// Represents stat modifiers that a card can provide
@JsonSerializable()
class StatModifier {
  final String statName;
  final int value;
  final bool isPercentage; // true for percentage modifiers, false for flat values
  
  const StatModifier({
    required this.statName,
    required this.value,
    this.isPercentage = false,
  });
  
  factory StatModifier.fromJson(Map<String, dynamic> json) => _$StatModifierFromJson(json);
  Map<String, dynamic> toJson() => _$StatModifierToJson(this);
}

/// Represents conditions that must be met to use a card
@JsonSerializable()
class CardCondition {
  final String conditionType; // 'stat', 'class', 'quest', 'level', etc.
  final String conditionKey; // The specific requirement (e.g., 'strength', 'holy')
  final dynamic conditionValue; // The value required (e.g., 20, true)
  final String operator; // '>=', '==', '>', '<', etc.
  
  const CardCondition({
    required this.conditionType,
    required this.conditionKey,
    required this.conditionValue,
    this.operator = '>=',
  });
  
  factory CardCondition.fromJson(Map<String, dynamic> json) => _$CardConditionFromJson(json);
  Map<String, dynamic> toJson() => _$CardConditionToJson(this);
}

/// Represents effects that occur when a card is used or triggered
@JsonSerializable()
class CardEffect {
  final String effectType; // 'damage', 'heal', 'buff', 'debuff', 'quest_complete', etc.
  final String target; // 'self', 'enemy', 'all', 'party', etc.
  final int value;
  final int duration; // For temporary effects, in turns
  final Map<String, dynamic> additionalData; // For complex effects
  
  const CardEffect({
    required this.effectType,
    required this.target,
    required this.value,
    this.duration = 0,
    this.additionalData = const {},
  });
  
  factory CardEffect.fromJson(Map<String, dynamic> json) => _$CardEffectFromJson(json);
  Map<String, dynamic> toJson() => _$CardEffectToJson(this);
}

/// Main Card model - represents all types of cards in the game
@JsonSerializable()
class GameCard {
  final String id;
  final String name;
  final String description;
  final CardType type;
  final CardRarity rarity;
  final List<CharacterClass> allowedClasses;
  final EquipmentSlot equipmentSlot;
  
  // Visual properties
  final String? imageUrl;
  final String? iconUrl;
  final Map<String, String> visualProperties; // Colors, effects, etc.
  
  // Core stats for combat
  final int attack;
  final int defense;
  final int manaCost;
  final int durability; // For equipment that can break
  
  // Stat modifiers this card provides
  final List<StatModifier> statModifiers;
  
  // Conditions required to use this card
  final List<CardCondition> conditions;
  
  // Effects this card triggers
  final List<CardEffect> effects;
  
  // Usage limitations
  final int maxUsesPerGame;
  final int maxUsesPerTurn;
  final int cooldownTurns;
  final bool isConsumable;
  final bool isUnique; // Only one can be equipped at a time
  
  // Quest-specific properties
  final String? questObjective;
  final Map<String, dynamic>? questRewards;
  final bool isQuestCompleted;
  
  // Trading and economy
  final int goldValue;
  final bool isTradeable;
  final bool isCraftable;
  final List<String> craftingMaterials;
  
  // Metadata
  final String lore;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdBy; // For developer tracking
  
  GameCard({
    String? id,
    required this.name,
    required this.description,
    required this.type,
    this.rarity = CardRarity.common,
    this.allowedClasses = const [CharacterClass.all],
    this.equipmentSlot = EquipmentSlot.none,
    this.imageUrl,
    this.iconUrl,
    this.visualProperties = const {},
    this.attack = 0,
    this.defense = 0,
    this.manaCost = 0,
    this.durability = 0,
    this.statModifiers = const [],
    this.conditions = const [],
    this.effects = const [],
    this.maxUsesPerGame = -1, // -1 means unlimited
    this.maxUsesPerTurn = 1,
    this.cooldownTurns = 0,
    this.isConsumable = false,
    this.isUnique = false,
    this.questObjective,
    this.questRewards,
    this.isQuestCompleted = false,
    this.goldValue = 0,
    this.isTradeable = true,
    this.isCraftable = false,
    this.craftingMaterials = const [],
    this.lore = '',
    this.tags = const [],
    DateTime? createdAt,
    this.updatedAt,
    this.createdBy = 'system',
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();
  
  factory GameCard.fromJson(Map<String, dynamic> json) => _$GameCardFromJson(json);
  Map<String, dynamic> toJson() => _$GameCardToJson(this);
  
  /// Creates a copy of this card with updated properties
  GameCard copyWith({
    String? name,
    String? description,
    CardType? type,
    CardRarity? rarity,
    List<CharacterClass>? allowedClasses,
    EquipmentSlot? equipmentSlot,
    String? imageUrl,
    String? iconUrl,
    Map<String, String>? visualProperties,
    int? attack,
    int? defense,
    int? manaCost,
    int? durability,
    List<StatModifier>? statModifiers,
    List<CardCondition>? conditions,
    List<CardEffect>? effects,
    int? maxUsesPerGame,
    int? maxUsesPerTurn,
    int? cooldownTurns,
    bool? isConsumable,
    bool? isUnique,
    String? questObjective,
    Map<String, dynamic>? questRewards,
    bool? isQuestCompleted,
    int? goldValue,
    bool? isTradeable,
    bool? isCraftable,
    List<String>? craftingMaterials,
    String? lore,
    List<String>? tags,
    String? createdBy,
  }) {
    return GameCard(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      allowedClasses: allowedClasses ?? this.allowedClasses,
      equipmentSlot: equipmentSlot ?? this.equipmentSlot,
      imageUrl: imageUrl ?? this.imageUrl,
      iconUrl: iconUrl ?? this.iconUrl,
      visualProperties: visualProperties ?? this.visualProperties,
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
      manaCost: manaCost ?? this.manaCost,
      durability: durability ?? this.durability,
      statModifiers: statModifiers ?? this.statModifiers,
      conditions: conditions ?? this.conditions,
      effects: effects ?? this.effects,
      maxUsesPerGame: maxUsesPerGame ?? this.maxUsesPerGame,
      maxUsesPerTurn: maxUsesPerTurn ?? this.maxUsesPerTurn,
      cooldownTurns: cooldownTurns ?? this.cooldownTurns,
      isConsumable: isConsumable ?? this.isConsumable,
      isUnique: isUnique ?? this.isUnique,
      questObjective: questObjective ?? this.questObjective,
      questRewards: questRewards ?? this.questRewards,
      isQuestCompleted: isQuestCompleted ?? this.isQuestCompleted,
      goldValue: goldValue ?? this.goldValue,
      isTradeable: isTradeable ?? this.isTradeable,
      isCraftable: isCraftable ?? this.isCraftable,
      craftingMaterials: craftingMaterials ?? this.craftingMaterials,
      lore: lore ?? this.lore,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      createdBy: createdBy ?? this.createdBy,
    );
  }
  
  /// Checks if this card can be used by the given character class
  bool canBeUsedByClass(CharacterClass characterClass) {
    return allowedClasses.contains(CharacterClass.all) || 
           allowedClasses.contains(characterClass);
  }
  
  /// Checks if all conditions are met for using this card
  bool canBeUsed(Map<String, dynamic> gameState) {
    // TODO: Implement condition checking logic
    // This will check character stats, quest completion, etc.
    return true;
  }
  
  /// Gets the total attack value including modifiers
  int getTotalAttack() {
    int totalAttack = attack;
    for (var modifier in statModifiers) {
      if (modifier.statName == 'attack') {
        totalAttack += modifier.value;
      }
    }
    return totalAttack;
  }
  
  /// Gets the total defense value including modifiers
  int getTotalDefense() {
    int totalDefense = defense;
    for (var modifier in statModifiers) {
      if (modifier.statName == 'defense') {
        totalDefense += modifier.value;
      }
    }
    return totalDefense;
  }
  
  /// Gets the rarity color for UI display
  String getRarityColor() {
    switch (rarity) {
      case CardRarity.common:
        return '#FFFFFF';
      case CardRarity.uncommon:
        return '#00FF00';
      case CardRarity.rare:
        return '#0080FF';
      case CardRarity.epic:
        return '#8000FF';
      case CardRarity.legendary:
        return '#FF8000';
      case CardRarity.mythic:
        return '#FF0080';
    }
  }
}

/// Represents a card instance in a player's collection
@JsonSerializable()
class CardInstance {
  final String instanceId;
  final String cardId;
  final GameCard card;
  final int currentDurability;
  final int usesThisGame;
  final int usesThisTurn;
  final int cooldownRemaining;
  final bool isEquipped;
  final DateTime acquiredAt;
  final String qrCode; // For physical card integration
  
  CardInstance({
    String? instanceId,
    required this.cardId,
    required this.card,
    int? currentDurability,
    this.usesThisGame = 0,
    this.usesThisTurn = 0,
    this.cooldownRemaining = 0,
    this.isEquipped = false,
    DateTime? acquiredAt,
    String? qrCode,
  }) : instanceId = instanceId ?? const Uuid().v4(),
       currentDurability = currentDurability ?? card.durability,
       acquiredAt = acquiredAt ?? DateTime.now(),
       qrCode = qrCode ?? const Uuid().v4();
  
  factory CardInstance.fromJson(Map<String, dynamic> json) => _$CardInstanceFromJson(json);
  Map<String, dynamic> toJson() => _$CardInstanceToJson(this);
  
  /// Checks if this card instance can be used right now
  bool canBeUsedNow() {
    return cooldownRemaining <= 0 && 
           (card.maxUsesPerTurn == -1 || usesThisTurn < card.maxUsesPerTurn) &&
           (card.maxUsesPerGame == -1 || usesThisGame < card.maxUsesPerGame) &&
           currentDurability > 0;
  }
  
  /// Creates a copy with updated usage stats
  CardInstance copyWithUsage({
    int? usesThisGame,
    int? usesThisTurn,
    int? cooldownRemaining,
    int? currentDurability,
    bool? isEquipped,
  }) {
    return CardInstance(
      instanceId: instanceId,
      cardId: cardId,
      card: card,
      currentDurability: currentDurability ?? this.currentDurability,
      usesThisGame: usesThisGame ?? this.usesThisGame,
      usesThisTurn: usesThisTurn ?? this.usesThisTurn,
      cooldownRemaining: cooldownRemaining ?? this.cooldownRemaining,
      isEquipped: isEquipped ?? this.isEquipped,
      acquiredAt: acquiredAt,
      qrCode: qrCode,
    );
  }
}