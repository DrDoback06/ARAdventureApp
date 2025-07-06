import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'card_model.g.dart';

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
}

enum EquipmentSlot {
  none,
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
}

enum CharacterClass {
  paladin,
  barbarian,
  necromancer,
  sorceress,
  amazon,
  assassin,
  druid,
  monk,
  crusader,
  witchDoctor,
  wizard,
  demonHunter,
}

enum CardRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  mythic,
}

@JsonSerializable()
class StatModifier {
  final String statName;
  final int value;
  final bool isPercentage;

  StatModifier({
    required this.statName,
    required this.value,
    this.isPercentage = false,
  });

  factory StatModifier.fromJson(Map<String, dynamic> json) =>
      _$StatModifierFromJson(json);
  Map<String, dynamic> toJson() => _$StatModifierToJson(this);
}

@JsonSerializable()
class CardCondition {
  final String type;
  final String value;
  final String description;

  CardCondition({
    required this.type,
    required this.value,
    required this.description,
  });

  factory CardCondition.fromJson(Map<String, dynamic> json) =>
      _$CardConditionFromJson(json);
  Map<String, dynamic> toJson() => _$CardConditionToJson(this);
}

@JsonSerializable()
class CardEffect {
  final String type;
  final String value;
  final String description;
  final int duration;

  CardEffect({
    required this.type,
    required this.value,
    required this.description,
    this.duration = 0,
  });

  factory CardEffect.fromJson(Map<String, dynamic> json) =>
      _$CardEffectFromJson(json);
  Map<String, dynamic> toJson() => _$CardEffectToJson(this);
}

@JsonSerializable()
class GameCard {
  final String id;
  final String name;
  final String description;
  final CardType type;
  final CardRarity rarity;
  final EquipmentSlot equipmentSlot;
  final Set<CharacterClass> allowedClasses;
  final List<StatModifier> statModifiers;
  final List<CardCondition> conditions;
  final List<CardEffect> effects;
  final String imageUrl;
  final int cost;
  final int levelRequirement;
  final int durability;
  final int maxStack;
  final bool isConsumable;
  final bool isTradeable;
  final Map<String, dynamic> customProperties;

  GameCard({
    String? id,
    required this.name,
    required this.description,
    required this.type,
    this.rarity = CardRarity.common,
    this.equipmentSlot = EquipmentSlot.none,
    Set<CharacterClass>? allowedClasses,
    List<StatModifier>? statModifiers,
    List<CardCondition>? conditions,
    List<CardEffect>? effects,
    this.imageUrl = '',
    this.cost = 0,
    this.levelRequirement = 1,
    this.durability = 100,
    this.maxStack = 1,
    this.isConsumable = false,
    this.isTradeable = true,
    Map<String, dynamic>? customProperties,
  })  : id = id ?? const Uuid().v4(),
        allowedClasses = allowedClasses ?? <CharacterClass>{},
        statModifiers = statModifiers ?? <StatModifier>[],
        conditions = conditions ?? <CardCondition>[],
        effects = effects ?? <CardEffect>[],
        customProperties = customProperties ?? <String, dynamic>{};

  factory GameCard.fromJson(Map<String, dynamic> json) =>
      _$GameCardFromJson(json);
  Map<String, dynamic> toJson() => _$GameCardToJson(this);

  GameCard copyWith({
    String? id,
    String? name,
    String? description,
    CardType? type,
    CardRarity? rarity,
    EquipmentSlot? equipmentSlot,
    Set<CharacterClass>? allowedClasses,
    List<StatModifier>? statModifiers,
    List<CardCondition>? conditions,
    List<CardEffect>? effects,
    String? imageUrl,
    int? cost,
    int? levelRequirement,
    int? durability,
    int? maxStack,
    bool? isConsumable,
    bool? isTradeable,
    Map<String, dynamic>? customProperties,
  }) {
    return GameCard(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      equipmentSlot: equipmentSlot ?? this.equipmentSlot,
      allowedClasses: allowedClasses ?? this.allowedClasses,
      statModifiers: statModifiers ?? this.statModifiers,
      conditions: conditions ?? this.conditions,
      effects: effects ?? this.effects,
      imageUrl: imageUrl ?? this.imageUrl,
      cost: cost ?? this.cost,
      levelRequirement: levelRequirement ?? this.levelRequirement,
      durability: durability ?? this.durability,
      maxStack: maxStack ?? this.maxStack,
      isConsumable: isConsumable ?? this.isConsumable,
      isTradeable: isTradeable ?? this.isTradeable,
      customProperties: customProperties ?? this.customProperties,
    );
  }
}

@JsonSerializable()
class CardInstance {
  final String instanceId;
  final GameCard card;
  final int quantity;
  final int currentDurability;
  final DateTime acquiredAt;
  final Map<String, dynamic> instanceData;

  CardInstance({
    String? instanceId,
    required this.card,
    this.quantity = 1,
    int? currentDurability,
    DateTime? acquiredAt,
    Map<String, dynamic>? instanceData,
  })  : instanceId = instanceId ?? const Uuid().v4(),
        currentDurability = currentDurability ?? card.durability,
        acquiredAt = acquiredAt ?? DateTime.now(),
        instanceData = instanceData ?? <String, dynamic>{};

  factory CardInstance.fromJson(Map<String, dynamic> json) =>
      _$CardInstanceFromJson(json);
  Map<String, dynamic> toJson() => _$CardInstanceToJson(this);

  CardInstance copyWith({
    String? instanceId,
    GameCard? card,
    int? quantity,
    int? currentDurability,
    DateTime? acquiredAt,
    Map<String, dynamic>? instanceData,
  }) {
    return CardInstance(
      instanceId: instanceId ?? this.instanceId,
      card: card ?? this.card,
      quantity: quantity ?? this.quantity,
      currentDurability: currentDurability ?? this.currentDurability,
      acquiredAt: acquiredAt ?? this.acquiredAt,
      instanceData: instanceData ?? this.instanceData,
    );
  }
}