import 'package:flutter/material.dart';

/// Unified ParticleType enum that works for both effects and services
enum ParticleType {
  // Basic particle types
  fire,
  ice,
  lightning,
  healing,
  damage,
  explosion,
  sparkle,
  smoke,
  dust,
  magic,
  blood,
  shield,
  buff,
  debuff,
  
  // Energy and special effects
  energy,
  arcane,
  holy,
  shadow,
  poison,
  acid,
  earth,
  wind,
  water,
  
  // Battle-specific effects
  critical,
  superCritical,
  devastatingCritical,
  chainReaction,
  combo,
  counter,
  
  // Environmental effects
  weather,
  storm,
  blizzard,
  heatwave,
  earthquake,
  volcanic,
  
  // UI and feedback effects
  selection,
  hover,
  click,
  notification,
  success,
  warning,
  error,
  
  // Special effects
  portal,
  teleport,
  summon,
  banish,
  transform,
  morph,
  
  // Legacy support (for backward compatibility)
  heal, // Maps to healing
  damage_old, // Maps to damage
}

/// Particle behavior types
enum ParticleBehavior {
  fade,
  explode,
  spiral,
  wave,
  random,
  follow,
  gravity,
  wind,
  bounce,
  pulse,
  rotate,
  scale,
  morph,
  chain,
  trail,
}

/// Particle effect categories
enum ParticleCategory {
  damage,
  healing,
  buff,
  debuff,
  environmental,
  ui,
  special,
  legacy,
}

/// Extension methods for ParticleType
extension ParticleTypeExtension on ParticleType {
  /// Get the category of this particle type
  ParticleCategory get category {
    switch (this) {
      case ParticleType.fire:
      case ParticleType.ice:
      case ParticleType.lightning:
      case ParticleType.damage:
      case ParticleType.explosion:
      case ParticleType.blood:
      case ParticleType.poison:
      case ParticleType.acid:
      case ParticleType.critical:
      case ParticleType.superCritical:
      case ParticleType.devastatingCritical:
        return ParticleCategory.damage;
        
      case ParticleType.healing:
      case ParticleType.holy:
      case ParticleType.shield:
      case ParticleType.buff:
        return ParticleCategory.healing;
        
      case ParticleType.debuff:
      case ParticleType.shadow:
      case ParticleType.poison:
      case ParticleType.acid:
        return ParticleCategory.debuff;
        
      case ParticleType.weather:
      case ParticleType.storm:
      case ParticleType.blizzard:
      case ParticleType.heatwave:
      case ParticleType.earthquake:
      case ParticleType.volcanic:
      case ParticleType.earth:
      case ParticleType.wind:
      case ParticleType.water:
        return ParticleCategory.environmental;
        
      case ParticleType.selection:
      case ParticleType.hover:
      case ParticleType.click:
      case ParticleType.notification:
      case ParticleType.success:
      case ParticleType.warning:
      case ParticleType.error:
        return ParticleCategory.ui;
        
      case ParticleType.portal:
      case ParticleType.teleport:
      case ParticleType.summon:
      case ParticleType.banish:
      case ParticleType.transform:
      case ParticleType.morph:
      case ParticleType.chainReaction:
      case ParticleType.combo:
      case ParticleType.counter:
        return ParticleCategory.special;
        
      case ParticleType.heal:
      case ParticleType.damage_old:
        return ParticleCategory.legacy;
        
      default:
        return ParticleCategory.damage;
    }
  }
  
  /// Get the primary color for this particle type
  Color get primaryColor {
    switch (this) {
      case ParticleType.fire:
        return const Color(0xFFFF4500); // OrangeRed
      case ParticleType.ice:
        return const Color(0xFF00BFFF); // DeepSkyBlue
      case ParticleType.lightning:
        return const Color(0xFFFFD700); // Gold
      case ParticleType.healing:
      case ParticleType.heal:
        return const Color(0xFF32CD32); // LimeGreen
      case ParticleType.damage:
      case ParticleType.damage_old:
        return const Color(0xFFFF0000); // Red
      case ParticleType.explosion:
        return const Color(0xFFFF8C00); // DarkOrange
      case ParticleType.sparkle:
        return const Color(0xFFFFFF00); // Yellow
      case ParticleType.magic:
      case ParticleType.arcane:
        return const Color(0xFF9370DB); // MediumPurple
      case ParticleType.holy:
        return const Color(0xFFFFFFF0); // Ivory
      case ParticleType.shadow:
        return const Color(0xFF8B008B); // DarkMagenta
      case ParticleType.poison:
        return const Color(0xFF32CD32); // LimeGreen
      case ParticleType.acid:
        return const Color(0xFF00FF00); // Lime
      case ParticleType.earth:
        return const Color(0xFF8B4513); // SaddleBrown
      case ParticleType.wind:
        return const Color(0xFF87CEEB); // SkyBlue
      case ParticleType.water:
        return const Color(0xFF4169E1); // RoyalBlue
      case ParticleType.blood:
        return const Color(0xFFDC143C); // Crimson
      case ParticleType.shield:
        return const Color(0xFF4682B4); // SteelBlue
      case ParticleType.buff:
        return const Color(0xFF00CED1); // DarkTurquoise
      case ParticleType.debuff:
        return const Color(0xFF800080); // Purple
      case ParticleType.energy:
        return const Color(0xFF00FFFF); // Cyan
      case ParticleType.weather:
        return const Color(0xFFB0C4DE); // LightSteelBlue
      case ParticleType.storm:
        return const Color(0xFF483D8B); // DarkSlateBlue
      case ParticleType.blizzard:
        return const Color(0xFFF0F8FF); // AliceBlue
      case ParticleType.heatwave:
        return const Color(0xFFFF6347); // Tomato
      case ParticleType.earthquake:
        return const Color(0xFFD2691E); // Chocolate
      case ParticleType.volcanic:
        return const Color(0xFFFF4500); // OrangeRed
      case ParticleType.portal:
        return const Color(0xFF9932CC); // DarkOrchid
      case ParticleType.teleport:
        return const Color(0xFF00BFFF); // DeepSkyBlue
      case ParticleType.summon:
        return const Color(0xFFFFD700); // Gold
      case ParticleType.banish:
        return const Color(0xFF8B0000); // DarkRed
      case ParticleType.transform:
        return const Color(0xFF32CD32); // LimeGreen
      case ParticleType.morph:
        return const Color(0xFF9370DB); // MediumPurple
      case ParticleType.chainReaction:
        return const Color(0xFFFF1493); // DeepPink
      case ParticleType.combo:
        return const Color(0xFFFF69B4); // HotPink
      case ParticleType.counter:
        return const Color(0xFFFF4500); // OrangeRed
      case ParticleType.critical:
        return const Color(0xFFFFD700); // Gold
      case ParticleType.superCritical:
        return const Color(0xFFFF6347); // Tomato
      case ParticleType.devastatingCritical:
        return const Color(0xFFFF0000); // Red
      case ParticleType.selection:
        return const Color(0xFF00BFFF); // DeepSkyBlue
      case ParticleType.hover:
        return const Color(0xFF87CEEB); // SkyBlue
      case ParticleType.click:
        return const Color(0xFF4682B4); // SteelBlue
      case ParticleType.notification:
        return const Color(0xFFFFD700); // Gold
      case ParticleType.success:
        return const Color(0xFF32CD32); // LimeGreen
      case ParticleType.warning:
        return const Color(0xFFFFA500); // Orange
      case ParticleType.error:
        return const Color(0xFFFF0000); // Red
      case ParticleType.smoke:
        return const Color(0xFF696969); // DimGray
      case ParticleType.dust:
        return const Color(0xFFDEB887); // BurlyWood
      default:
        return const Color(0xFF808080); // Gray
    }
  }
  
  /// Get the secondary color for this particle type
  Color get secondaryColor {
    switch (this) {
      case ParticleType.fire:
        return const Color(0xFFFF8C00); // DarkOrange
      case ParticleType.ice:
        return const Color(0xFF87CEEB); // SkyBlue
      case ParticleType.lightning:
        return const Color(0xFFFFFF00); // Yellow
      case ParticleType.healing:
      case ParticleType.heal:
        return const Color(0xFF98FB98); // PaleGreen
      case ParticleType.damage:
      case ParticleType.damage_old:
        return const Color(0xFFDC143C); // Crimson
      case ParticleType.explosion:
        return const Color(0xFFFF6347); // Tomato
      case ParticleType.sparkle:
        return const Color(0xFFFFFFF0); // Ivory
      case ParticleType.magic:
      case ParticleType.arcane:
        return const Color(0xFFDDA0DD); // Plum
      case ParticleType.holy:
        return const Color(0xFFFFFFF0); // Ivory
      case ParticleType.shadow:
        return const Color(0xFF4B0082); // Indigo
      case ParticleType.poison:
        return const Color(0xFF00FF00); // Lime
      case ParticleType.acid:
        return const Color(0xFF32CD32); // LimeGreen
      case ParticleType.earth:
        return const Color(0xFFA0522D); // Sienna
      case ParticleType.wind:
        return const Color(0xFFB0E0E6); // PowderBlue
      case ParticleType.water:
        return const Color(0xFF1E90FF); // DodgerBlue
      case ParticleType.blood:
        return const Color(0xFFB22222); // FireBrick
      case ParticleType.shield:
        return const Color(0xFF5F9EA0); // CadetBlue
      case ParticleType.buff:
        return const Color(0xFF40E0D0); // Turquoise
      case ParticleType.debuff:
        return const Color(0xFF9370DB); // MediumPurple
      case ParticleType.energy:
        return const Color(0xFF00CED1); // DarkTurquoise
      case ParticleType.weather:
        return const Color(0xFFE6E6FA); // Lavender
      case ParticleType.storm:
        return const Color(0xFF6A5ACD); // SlateBlue
      case ParticleType.blizzard:
        return const Color(0xFFF0F8FF); // AliceBlue
      case ParticleType.heatwave:
        return const Color(0xFFFF4500); // OrangeRed
      case ParticleType.earthquake:
        return const Color(0xFFCD853F); // Peru
      case ParticleType.volcanic:
        return const Color(0xFFFF6347); // Tomato
      case ParticleType.portal:
        return const Color(0xFFBA55D3); // MediumOrchid
      case ParticleType.teleport:
        return const Color(0xFF87CEEB); // SkyBlue
      case ParticleType.summon:
        return const Color(0xFFFFFF00); // Yellow
      case ParticleType.banish:
        return const Color(0xFF8B0000); // DarkRed
      case ParticleType.transform:
        return const Color(0xFF98FB98); // PaleGreen
      case ParticleType.morph:
        return const Color(0xFFDDA0DD); // Plum
      case ParticleType.chainReaction:
        return const Color(0xFFFF69B4); // HotPink
      case ParticleType.combo:
        return const Color(0xFFFF1493); // DeepPink
      case ParticleType.counter:
        return const Color(0xFFFF6347); // Tomato
      case ParticleType.critical:
        return const Color(0xFFFFFF00); // Yellow
      case ParticleType.superCritical:
        return const Color(0xFFFF4500); // OrangeRed
      case ParticleType.devastatingCritical:
        return const Color(0xFFDC143C); // Crimson
      case ParticleType.selection:
        return const Color(0xFF87CEEB); // SkyBlue
      case ParticleType.hover:
        return const Color(0xFFB0C4DE); // LightSteelBlue
      case ParticleType.click:
        return const Color(0xFF5F9EA0); // CadetBlue
      case ParticleType.notification:
        return const Color(0xFFFFFF00); // Yellow
      case ParticleType.success:
        return const Color(0xFF98FB98); // PaleGreen
      case ParticleType.warning:
        return const Color(0xFFFFA500); // Orange
      case ParticleType.error:
        return const Color(0xFFDC143C); // Crimson
      case ParticleType.smoke:
        return const Color(0xFFA9A9A9); // DarkGray
      case ParticleType.dust:
        return const Color(0xFFF5DEB3); // Wheat
      default:
        return const Color(0xFFC0C0C0); // Silver
    }
  }
  
  /// Get the default behavior for this particle type
  ParticleBehavior get defaultBehavior {
    switch (this) {
      case ParticleType.fire:
      case ParticleType.explosion:
      case ParticleType.volcanic:
        return ParticleBehavior.explode;
      case ParticleType.ice:
      case ParticleType.blizzard:
        return ParticleBehavior.fade;
      case ParticleType.lightning:
      case ParticleType.energy:
        return ParticleBehavior.follow;
      case ParticleType.healing:
      case ParticleType.heal:
      case ParticleType.holy:
        return ParticleBehavior.pulse;
      case ParticleType.damage:
      case ParticleType.damage_old:
      case ParticleType.blood:
        return ParticleBehavior.fade;
      case ParticleType.sparkle:
      case ParticleType.magic:
      case ParticleType.arcane:
        return ParticleBehavior.spiral;
      case ParticleType.shadow:
      case ParticleType.poison:
      case ParticleType.acid:
        return ParticleBehavior.wave;
      case ParticleType.earth:
      case ParticleType.earthquake:
        return ParticleBehavior.gravity;
      case ParticleType.wind:
      case ParticleType.storm:
        return ParticleBehavior.wind;
      case ParticleType.water:
        return ParticleBehavior.wave;
      case ParticleType.portal:
      case ParticleType.teleport:
        return ParticleBehavior.morph;
      case ParticleType.summon:
      case ParticleType.banish:
        return ParticleBehavior.scale;
      case ParticleType.transform:
      case ParticleType.morph:
        return ParticleBehavior.morph;
      case ParticleType.chainReaction:
      case ParticleType.combo:
        return ParticleBehavior.chain;
      case ParticleType.counter:
        return ParticleBehavior.bounce;
      case ParticleType.critical:
      case ParticleType.superCritical:
      case ParticleType.devastatingCritical:
        return ParticleBehavior.explode;
      case ParticleType.selection:
      case ParticleType.hover:
      case ParticleType.click:
        return ParticleBehavior.pulse;
      case ParticleType.notification:
      case ParticleType.success:
      case ParticleType.warning:
      case ParticleType.error:
        return ParticleBehavior.fade;
      case ParticleType.smoke:
        return ParticleBehavior.fade;
      case ParticleType.dust:
        return ParticleBehavior.gravity;
      default:
        return ParticleBehavior.fade;
    }
  }
  
  /// Get the icon for this particle type
  IconData get icon {
    switch (this) {
      case ParticleType.fire:
        return Icons.local_fire_department;
      case ParticleType.ice:
        return Icons.ac_unit;
      case ParticleType.lightning:
        return Icons.electric_bolt;
      case ParticleType.healing:
      case ParticleType.heal:
        return Icons.healing;
      case ParticleType.damage:
      case ParticleType.damage_old:
        return Icons.flash_on;
      case ParticleType.explosion:
        return Icons.whatshot;
      case ParticleType.sparkle:
        return Icons.star;
      case ParticleType.magic:
      case ParticleType.arcane:
        return Icons.auto_fix_high;
      case ParticleType.holy:
        return Icons.church;
      case ParticleType.shadow:
        return Icons.dark_mode;
      case ParticleType.poison:
        return Icons.science;
      case ParticleType.acid:
        return Icons.science_outlined;
      case ParticleType.earth:
        return Icons.landscape;
      case ParticleType.wind:
        return Icons.air;
      case ParticleType.water:
        return Icons.water_drop;
      case ParticleType.blood:
        return Icons.favorite;
      case ParticleType.shield:
        return Icons.shield;
      case ParticleType.buff:
        return Icons.trending_up;
      case ParticleType.debuff:
        return Icons.trending_down;
      case ParticleType.energy:
        return Icons.bolt;
      case ParticleType.weather:
        return Icons.cloud;
      case ParticleType.storm:
        return Icons.thunderstorm;
      case ParticleType.blizzard:
        return Icons.ac_unit;
      case ParticleType.heatwave:
        return Icons.thermostat;
      case ParticleType.earthquake:
        return Icons.vibration;
      case ParticleType.volcanic:
        return Icons.local_fire_department;
      case ParticleType.portal:
        return Icons.door_front_door;
      case ParticleType.teleport:
        return Icons.telegram;
      case ParticleType.summon:
        return Icons.person_add;
      case ParticleType.banish:
        return Icons.person_remove;
      case ParticleType.transform:
        return Icons.transform;
      case ParticleType.morph:
        return Icons.auto_fix_normal;
      case ParticleType.chainReaction:
        return Icons.share;
      case ParticleType.combo:
        return Icons.link;
      case ParticleType.counter:
        return Icons.replay;
      case ParticleType.critical:
      case ParticleType.superCritical:
      case ParticleType.devastatingCritical:
        return Icons.flash_on;
      case ParticleType.selection:
        return Icons.touch_app;
      case ParticleType.hover:
        return Icons.mouse;
      case ParticleType.click:
        return Icons.touch_app;
      case ParticleType.notification:
        return Icons.notifications;
      case ParticleType.success:
        return Icons.check_circle;
      case ParticleType.warning:
        return Icons.warning;
      case ParticleType.error:
        return Icons.error;
      case ParticleType.smoke:
        return Icons.cloud;
      case ParticleType.dust:
        return Icons.grain;
      default:
        return Icons.star;
    }
  }
  
  /// Get the display name for this particle type
  String get displayName {
    switch (this) {
      case ParticleType.fire:
        return 'Fire';
      case ParticleType.ice:
        return 'Ice';
      case ParticleType.lightning:
        return 'Lightning';
      case ParticleType.healing:
        return 'Healing';
      case ParticleType.heal:
        return 'Heal';
      case ParticleType.damage:
        return 'Damage';
      case ParticleType.damage_old:
        return 'Damage';
      case ParticleType.explosion:
        return 'Explosion';
      case ParticleType.sparkle:
        return 'Sparkle';
      case ParticleType.magic:
        return 'Magic';
      case ParticleType.arcane:
        return 'Arcane';
      case ParticleType.holy:
        return 'Holy';
      case ParticleType.shadow:
        return 'Shadow';
      case ParticleType.poison:
        return 'Poison';
      case ParticleType.acid:
        return 'Acid';
      case ParticleType.earth:
        return 'Earth';
      case ParticleType.wind:
        return 'Wind';
      case ParticleType.water:
        return 'Water';
      case ParticleType.blood:
        return 'Blood';
      case ParticleType.shield:
        return 'Shield';
      case ParticleType.buff:
        return 'Buff';
      case ParticleType.debuff:
        return 'Debuff';
      case ParticleType.energy:
        return 'Energy';
      case ParticleType.weather:
        return 'Weather';
      case ParticleType.storm:
        return 'Storm';
      case ParticleType.blizzard:
        return 'Blizzard';
      case ParticleType.heatwave:
        return 'Heatwave';
      case ParticleType.earthquake:
        return 'Earthquake';
      case ParticleType.volcanic:
        return 'Volcanic';
      case ParticleType.portal:
        return 'Portal';
      case ParticleType.teleport:
        return 'Teleport';
      case ParticleType.summon:
        return 'Summon';
      case ParticleType.banish:
        return 'Banish';
      case ParticleType.transform:
        return 'Transform';
      case ParticleType.morph:
        return 'Morph';
      case ParticleType.chainReaction:
        return 'Chain Reaction';
      case ParticleType.combo:
        return 'Combo';
      case ParticleType.counter:
        return 'Counter';
      case ParticleType.critical:
        return 'Critical';
      case ParticleType.superCritical:
        return 'Super Critical';
      case ParticleType.devastatingCritical:
        return 'Devastating Critical';
      case ParticleType.selection:
        return 'Selection';
      case ParticleType.hover:
        return 'Hover';
      case ParticleType.click:
        return 'Click';
      case ParticleType.notification:
        return 'Notification';
      case ParticleType.success:
        return 'Success';
      case ParticleType.warning:
        return 'Warning';
      case ParticleType.error:
        return 'Error';
      case ParticleType.smoke:
        return 'Smoke';
      case ParticleType.dust:
        return 'Dust';
      default:
        return 'Unknown';
    }
  }
} 