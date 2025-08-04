import 'package:flutter/material.dart';

/// Character classes available in the game
enum CharacterClass {
  warrior,
  mage,
  rogue,
  ranger,
  paladin,
  necromancer,
  bard,
  monk,
  barbarian,
  druid,
  sorcerer,
  cleric,
}

/// Character class utilities and data
class CharacterClassUtils {
  static const Map<CharacterClass, String> _classNames = {
    CharacterClass.warrior: 'Warrior',
    CharacterClass.mage: 'Mage',
    CharacterClass.rogue: 'Rogue',
    CharacterClass.ranger: 'Ranger',
    CharacterClass.paladin: 'Paladin',
    CharacterClass.necromancer: 'Necromancer',
    CharacterClass.bard: 'Bard',
    CharacterClass.monk: 'Monk',
    CharacterClass.barbarian: 'Barbarian',
    CharacterClass.druid: 'Druid',
    CharacterClass.sorcerer: 'Sorcerer',
    CharacterClass.cleric: 'Cleric',
  };

  static const Map<CharacterClass, String> _classDescriptions = {
    CharacterClass.warrior: 'A mighty fighter skilled in combat and defense',
    CharacterClass.mage: 'A wielder of arcane magic and powerful spells',
    CharacterClass.rogue: 'A stealthy assassin skilled in stealth and critical strikes',
    CharacterClass.ranger: 'A master of nature and ranged combat',
    CharacterClass.paladin: 'A holy warrior combining faith and martial prowess',
    CharacterClass.necromancer: 'A dark mage who commands death and undeath',
    CharacterClass.bard: 'A versatile performer who inspires allies and confuses foes',
    CharacterClass.monk: 'A disciplined fighter who harnesses inner energy',
    CharacterClass.barbarian: 'A fierce warrior who enters devastating rages',
    CharacterClass.druid: 'A guardian of nature who can shapeshift and heal',
    CharacterClass.sorcerer: 'A natural spellcaster with innate magical power',
    CharacterClass.cleric: 'A divine healer who channels the power of the gods',
  };

  static const Map<CharacterClass, IconData> _classIcons = {
    CharacterClass.warrior: Icons.shield,
    CharacterClass.mage: Icons.auto_fix_high,
    CharacterClass.rogue: Icons.visibility_off,
    CharacterClass.ranger: Icons.nature,
    CharacterClass.paladin: Icons.local_hospital,
    CharacterClass.necromancer: Icons.dangerous,
    CharacterClass.bard: Icons.music_note,
    CharacterClass.monk: Icons.self_improvement,
    CharacterClass.barbarian: Icons.flash_on,
    CharacterClass.druid: Icons.eco,
    CharacterClass.sorcerer: Icons.bolt,
    CharacterClass.cleric: Icons.healing,
  };

  static const Map<CharacterClass, Color> _classColors = {
    CharacterClass.warrior: Colors.brown,
    CharacterClass.mage: Colors.blue,
    CharacterClass.rogue: Colors.grey,
    CharacterClass.ranger: Colors.green,
    CharacterClass.paladin: Colors.amber,
    CharacterClass.necromancer: Colors.purple,
    CharacterClass.bard: Colors.pink,
    CharacterClass.monk: Colors.orange,
    CharacterClass.barbarian: Colors.red,
    CharacterClass.druid: Colors.teal,
    CharacterClass.sorcerer: Colors.indigo,
    CharacterClass.cleric: Colors.cyan,
  };

  // Base stat modifiers for each class
  static const Map<CharacterClass, Map<String, int>> _baseStatModifiers = {
    CharacterClass.warrior: {
      'strength': 3,
      'dexterity': 1,
      'vitality': 3,
      'energy': 0,
    },
    CharacterClass.mage: {
      'strength': 0,
      'dexterity': 1,
      'vitality': 1,
      'energy': 5,
    },
    CharacterClass.rogue: {
      'strength': 1,
      'dexterity': 4,
      'vitality': 1,
      'energy': 1,
    },
    CharacterClass.ranger: {
      'strength': 1,
      'dexterity': 3,
      'vitality': 2,
      'energy': 1,
    },
    CharacterClass.paladin: {
      'strength': 2,
      'dexterity': 1,
      'vitality': 2,
      'energy': 2,
    },
    CharacterClass.necromancer: {
      'strength': 0,
      'dexterity': 1,
      'vitality': 2,
      'energy': 4,
    },
    CharacterClass.bard: {
      'strength': 1,
      'dexterity': 2,
      'vitality': 2,
      'energy': 2,
    },
    CharacterClass.monk: {
      'strength': 2,
      'dexterity': 3,
      'vitality': 2,
      'energy': 0,
    },
    CharacterClass.barbarian: {
      'strength': 4,
      'dexterity': 1,
      'vitality': 3,
      'energy': -1,
    },
    CharacterClass.druid: {
      'strength': 1,
      'dexterity': 2,
      'vitality': 2,
      'energy': 2,
    },
    CharacterClass.sorcerer: {
      'strength': 0,
      'dexterity': 2,
      'vitality': 1,
      'energy': 4,
    },
    CharacterClass.cleric: {
      'strength': 1,
      'dexterity': 1,
      'vitality': 3,
      'energy': 2,
    },
  };

  /// Get the name of a character class
  static String getName(CharacterClass characterClass) {
    return _classNames[characterClass] ?? 'Unknown';
  }

  /// Get the description of a character class
  static String getDescription(CharacterClass characterClass) {
    return _classDescriptions[characterClass] ?? 'No description available';
  }

  /// Get the icon for a character class
  static IconData getIcon(CharacterClass characterClass) {
    return _classIcons[characterClass] ?? Icons.person;
  }

  /// Get the color for a character class
  static Color getColor(CharacterClass characterClass) {
    return _classColors[characterClass] ?? Colors.grey;
  }

  /// Get the base stat modifiers for a character class
  static Map<String, int> getBaseStatModifiers(CharacterClass characterClass) {
    return Map<String, int>.from(_baseStatModifiers[characterClass] ?? {
      'strength': 0,
      'dexterity': 0,
      'vitality': 0,
      'energy': 0,
    });
  }

  /// Parse a character class from a string
  static CharacterClass? fromString(String? classStr) {
    if (classStr == null) return null;
    
    // Handle enum string format
    if (classStr.startsWith('CharacterClass.')) {
      classStr = classStr.substring('CharacterClass.'.length);
    }
    
    for (final characterClass in CharacterClass.values) {
      if (characterClass.toString().split('.').last.toLowerCase() == classStr.toLowerCase()) {
        return characterClass;
      }
      if (getName(characterClass).toLowerCase() == classStr.toLowerCase()) {
        return characterClass;
      }
    }
    return null;
  }

  /// Get all available character classes
  static List<CharacterClass> getAllClasses() {
    return CharacterClass.values;
  }

  /// Check if a character class is valid
  static bool isValidClass(CharacterClass? characterClass) {
    return characterClass != null && CharacterClass.values.contains(characterClass);
  }
}