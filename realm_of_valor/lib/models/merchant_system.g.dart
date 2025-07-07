// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merchant_system.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MerchantInventoryItem _$MerchantInventoryItemFromJson(
        Map<String, dynamic> json) =>
    MerchantInventoryItem(
      cardId: json['cardId'] as String,
      price: (json['price'] as num).toInt(),
      stock: (json['stock'] as num?)?.toInt() ?? 1,
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0.0,
      requirements: json['requirements'] as Map<String, dynamic>?,
      isLimitedTime: json['isLimitedTime'] as bool? ?? false,
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
    );

Map<String, dynamic> _$MerchantInventoryItemToJson(
        MerchantInventoryItem instance) =>
    <String, dynamic>{
      'cardId': instance.cardId,
      'price': instance.price,
      'stock': instance.stock,
      'discountPercent': instance.discountPercent,
      'requirements': instance.requirements,
      'isLimitedTime': instance.isLimitedTime,
      'expiresAt': instance.expiresAt?.toIso8601String(),
    };

Merchant _$MerchantFromJson(Map<String, dynamic> json) => Merchant(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$MerchantTypeEnumMap, json['type']),
      rarity: $enumDecodeNullable(_$MerchantRarityEnumMap, json['rarity']) ??
          MerchantRarity.common,
      location: json['location'] == null
          ? null
          : GeoLocation.fromJson(json['location'] as Map<String, dynamic>),
      radius: (json['radius'] as num?)?.toDouble() ?? 100.0,
      inventory: (json['inventory'] as List<dynamic>?)
          ?.map(
              (e) => MerchantInventoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      spawnTime: json['spawnTime'] == null
          ? null
          : DateTime.parse(json['spawnTime'] as String),
      despawnTime: json['despawnTime'] == null
          ? null
          : DateTime.parse(json['despawnTime'] as String),
      isActive: json['isActive'] as bool? ?? true,
      specialOffers: json['specialOffers'] as Map<String, dynamic>?,
      dialogues: (json['dialogues'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      avatarUrl: json['avatarUrl'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$MerchantToJson(Merchant instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'type': _$MerchantTypeEnumMap[instance.type]!,
      'rarity': _$MerchantRarityEnumMap[instance.rarity]!,
      'location': instance.location,
      'radius': instance.radius,
      'inventory': instance.inventory,
      'spawnTime': instance.spawnTime.toIso8601String(),
      'despawnTime': instance.despawnTime?.toIso8601String(),
      'isActive': instance.isActive,
      'specialOffers': instance.specialOffers,
      'dialogues': instance.dialogues,
      'avatarUrl': instance.avatarUrl,
      'metadata': instance.metadata,
    };

const _$MerchantTypeEnumMap = {
  MerchantType.wandering: 'wandering',
  MerchantType.fitness: 'fitness',
  MerchantType.guild: 'guild',
  MerchantType.legendary: 'legendary',
  MerchantType.seasonal: 'seasonal',
  MerchantType.physical: 'physical',
};

const _$MerchantRarityEnumMap = {
  MerchantRarity.common: 'common',
  MerchantRarity.rare: 'rare',
  MerchantRarity.epic: 'epic',
  MerchantRarity.legendary: 'legendary',
};
