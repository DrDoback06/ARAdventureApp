/// Particle Type definitions for visual effects system
enum ParticleType {
  fire,
  ice,
  lightning,
  healing,
  explosion,
  magic,
  combat,
  sparkle,
  smoke,
  blood,
  energy,
  wind,
  earth,
  water,
  light,
  dark,
  poison,
  stun,
  boost,
  debuff,
  critical,
  miss,
  dodge,
  block,
  absorb,
  reflect,
  enchant,
  curse,
  blessing,
  teleport
}

class ParticleTypeUtils {
  static const Map<ParticleType, String> _particleNames = {
    ParticleType.fire: 'Fire',
    ParticleType.ice: 'Ice',
    ParticleType.lightning: 'Lightning',
    ParticleType.healing: 'Healing',
    ParticleType.explosion: 'Explosion',
    ParticleType.magic: 'Magic',
    ParticleType.combat: 'Combat',
    ParticleType.sparkle: 'Sparkle',
    ParticleType.smoke: 'Smoke',
    ParticleType.blood: 'Blood',
    ParticleType.energy: 'Energy',
    ParticleType.wind: 'Wind',
    ParticleType.earth: 'Earth',
    ParticleType.water: 'Water',
    ParticleType.light: 'Light',
    ParticleType.dark: 'Dark',
    ParticleType.poison: 'Poison',
    ParticleType.stun: 'Stun',
    ParticleType.boost: 'Boost',
    ParticleType.debuff: 'Debuff',
    ParticleType.critical: 'Critical',
    ParticleType.miss: 'Miss',
    ParticleType.dodge: 'Dodge',
    ParticleType.block: 'Block',
    ParticleType.absorb: 'Absorb',
    ParticleType.reflect: 'Reflect',
    ParticleType.enchant: 'Enchant',
    ParticleType.curse: 'Curse',
    ParticleType.blessing: 'Blessing',
    ParticleType.teleport: 'Teleport',
  };

  static String getName(ParticleType type) {
    return _particleNames[type] ?? 'Unknown';
  }

  static ParticleType? fromString(String name) {
    for (final entry in _particleNames.entries) {
      if (entry.value.toLowerCase() == name.toLowerCase()) {
        return entry.key;
      }
    }
    return null;
  }
}