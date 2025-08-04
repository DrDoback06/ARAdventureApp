import 'package:realm_of_valor/models/battle_model.dart';
import 'package:realm_of_valor/models/character_model.dart';
import 'package:realm_of_valor/models/card_model.dart';
import 'package:realm_of_valor/models/card_database.dart';

class BattleTestUtils {
  /// Creates a test battle with the specified number of players
  static Battle createTestBattle({
    int playerCount = 2,
    String battleName = 'Test Battle',
    BattleType type = BattleType.pvp,
  }) {
    final players = <BattlePlayer>[];
    
    for (int i = 0; i < playerCount; i++) {
      players.add(createTestPlayer(
        name: 'Player ${i + 1}',
        characterClass: _getTestCharacterClass(i),
        isAI: i > 0, // Make other players AI for testing
      ));
    }
    
    return Battle(
      name: battleName,
      type: type,
      players: players,
      status: BattleStatus.waiting,
    );
  }
  
  /// Creates a test player with a character and initial setup
  static BattlePlayer createTestPlayer({
    required String name,
    CharacterClass characterClass = CharacterClass.paladin,
    bool isAI = false,
  }) {
    final character = createTestCharacter(
      name: '$name\'s Character',
      characterClass: characterClass,
    );
    
    return BattlePlayer(
      name: name,
      character: character,
      actionDeck: _createTestActionDeck(),
      activeSkills: _createTestSkills(characterClass),
      isReady: true,
    );
  }
  
  /// Creates a test character with balanced stats
  static GameCharacter createTestCharacter({
    required String name,
    CharacterClass characterClass = CharacterClass.paladin,
    int level = 5,
  }) {
    final baseStats = _getClassBaseStats(characterClass);
    
    return GameCharacter(
      name: name,
      characterClass: characterClass,
      level: level,
      experience: level * 100,
      baseStrength: baseStats['strength']!,
      baseDexterity: baseStats['agility']!,
      baseVitality: baseStats['health']! ~/ 10, // Convert health to vitality
      baseEnergy: baseStats['mana']! ~/ 5, // Convert mana to energy
      allocatedStrength: baseStats['strength']! - 10,
      allocatedDexterity: baseStats['agility']! - 10,
      allocatedVitality: 0,
      allocatedEnergy: 0,
      availableStatPoints: 0,
      availableSkillPoints: 10,
      equipment: Equipment(),
    );
  }
  
  /// Creates a balanced action deck for testing (Enhanced with Elemental Spell Counter System!)
  static List<ActionCard> _createTestActionDeck() {
    return [
      // ⚡ LIGHTNING SPELLS - Can be countered by Earth magic
      ActionCard(
        name: 'Lightning Bolt',
        description: 'Strike with pure lightning energy',
        type: ActionCardType.spell,
        effect: 'damage:25',
        cost: 4,
        rarity: CardRarity.uncommon,
      ),
      ActionCard(
        name: 'Thunder Storm',
        description: 'Area lightning damage to all enemies',
        type: ActionCardType.special,
        effect: 'damage:18,all_enemies',
        cost: 6,
        rarity: CardRarity.epic,
      ),
      ActionCard(
        name: 'Lightning Shock',
        description: 'Quick lightning strike',
        type: ActionCardType.spell,
        effect: 'damage:15,shock',
        cost: 3,
        rarity: CardRarity.common,
      ),
      
      // 🔥 FIRE SPELLS - Can be countered by Water/Ice magic
      ActionCard(
        name: 'Fireball',
        description: 'Launch a burning projectile',
        type: ActionCardType.spell,
        effect: 'damage:30,burn:5',
        cost: 5,
        rarity: CardRarity.rare,
      ),
      ActionCard(
        name: 'Flame Burst',
        description: 'Explosive fire damage',
        type: ActionCardType.spell,
        effect: 'damage:22',
        cost: 4,
        rarity: CardRarity.uncommon,
      ),
      ActionCard(
        name: 'Fire Wave',
        description: 'Burning wave of destruction',
        type: ActionCardType.special,
        effect: 'damage:16,burn:3,all_enemies',
        cost: 7,
        rarity: CardRarity.epic,
      ),
      
      // ❄️ ICE/WATER COUNTERS - Can counter Fire spells perfectly
      ActionCard(
        name: 'Ice Shield',
        description: 'Freeze incoming fire attacks',
        type: ActionCardType.support,
        effect: 'ice_barrier:50',
        cost: 3,
        rarity: CardRarity.rare,
      ),
      ActionCard(
        name: 'Water Wave',
        description: 'Extinguish fire and heal allies',
        type: ActionCardType.spell,
        effect: 'heal:25,extinguish',
        cost: 4,
        rarity: CardRarity.uncommon,
      ),
      ActionCard(
        name: 'Frost Armor',
        description: 'Ice protection that counters fire',
        type: ActionCardType.support,
        effect: 'frost_shield:40,fire_immunity:2',
        cost: 5,
        rarity: CardRarity.rare,
      ),
      
      // 🌍 EARTH COUNTERS - Can ground Lightning perfectly
      ActionCard(
        name: 'Earth Wall',
        description: 'Ground electrical attacks',
        type: ActionCardType.support,
        effect: 'earth_shield:40',
        cost: 3,
        rarity: CardRarity.common,
      ),
      ActionCard(
        name: 'Stone Skin',
        description: 'Become one with the earth',
        type: ActionCardType.support,
        effect: 'lightning_immunity:3',
        cost: 4,
        rarity: CardRarity.uncommon,
      ),
      
      // ✨ ARCANE - Universal spell counters
      ActionCard(
        name: 'Arcane Dispel',
        description: 'Cancel any magical effect',
        type: ActionCardType.special,
        effect: 'dispel,cancel_action',
        cost: 3,
        rarity: CardRarity.rare,
      ),
      ActionCard(
        name: 'Magic Nullify',
        description: 'Completely negate next spell',
        type: ActionCardType.counter,
        effect: 'magic_immunity:1',
        cost: 4,
        rarity: CardRarity.epic,
      ),
      
      // ☀️ LIGHT SPELLS - Counter Shadow, vulnerable to Shadow
      ActionCard(
        name: 'Divine Light',
        description: 'Banish shadow magic',
        type: ActionCardType.spell,
        effect: 'holy_damage:35',
        cost: 5,
        rarity: CardRarity.epic,
      ),
      ActionCard(
        name: 'Holy Beam',
        description: 'Pierce through darkness',
        type: ActionCardType.spell,
        effect: 'light_damage:28',
        cost: 4,
        rarity: CardRarity.rare,
      ),
      
      // 🌑 SHADOW SPELLS - Counter Light, vulnerable to Light
      ActionCard(
        name: 'Shadow Curse',
        description: 'Dark magic corruption',
        type: ActionCardType.spell,
        effect: 'curse:15,damage:20',
        cost: 4,
        rarity: CardRarity.rare,
      ),
      ActionCard(
        name: 'Dark Bolt',
        description: 'Projectile of pure darkness',
        type: ActionCardType.spell,
        effect: 'shadow_damage:25',
        cost: 4,
        rarity: CardRarity.uncommon,
      ),
      
      // 💨 AIR SPELLS - Counter Earth magic
      ActionCard(
        name: 'Wind Gust',
        description: 'Scatter earth magic',
        type: ActionCardType.spell,
        effect: 'air_damage:20,dispel_earth',
        cost: 3,
        rarity: CardRarity.common,
      ),
      
      // 🌿 NATURE SPELLS - Healing and growth
      ActionCard(
        name: 'Nature\'s Blessing',
        description: 'Restore health with natural magic',
        type: ActionCardType.heal,
        effect: 'heal:30,nature_boost',
        cost: 4,
        rarity: CardRarity.uncommon,
      ),
      
      // 💪 PHYSICAL CARDS - Non-magical, can't be countered by spell counters
      ActionCard(
        name: 'Power Strike',
        description: 'Physical attack that ignores spell counters',
        type: ActionCardType.physical,
        effect: 'damage_bonus:20',
        cost: 3,
        rarity: CardRarity.common,
      ),
      ActionCard(
        name: 'Shield Bash',
        description: 'Pure physical impact',
        type: ActionCardType.physical,
        effect: 'damage:18,stun',
        cost: 2,
        rarity: CardRarity.common,
      ),
    ];
  }
  
  /// Creates test skills based on character class
  static List<GameCard> _createTestSkills(CharacterClass characterClass) {
    final skills = <GameCard>[];
    
    switch (characterClass) {
      case CharacterClass.paladin:
        skills.addAll([
          GameCard(
            name: 'Holy Light',
            description: 'Heal self for 30 HP',
            type: CardType.spell,
            cost: 4,
            effects: [CardEffect(type: 'heal', value: '30')],
          ),
          GameCard(
            name: 'Divine Strike',
            description: 'Deal 35 holy damage',
            type: CardType.spell,
            cost: 5,
            effects: [CardEffect(type: 'damage', value: '35')],
          ),
        ]);
        break;
        
      case CharacterClass.barbarian:
        skills.addAll([
          GameCard(
            name: 'Berserker Rage',
            description: 'Gain +20 attack for 3 turns',
            type: CardType.spell,
            cost: 6,
            effects: [CardEffect(type: 'attack_buff', value: '20', duration: 3)],
          ),
          GameCard(
            name: 'Whirlwind',
            description: 'Deal 25 damage to all enemies',
            type: CardType.spell,
            cost: 7,
            effects: [CardEffect(type: 'area_damage', value: '25')],
          ),
        ]);
        break;
        
      case CharacterClass.sorceress:
        skills.addAll([
          GameCard(
            name: 'Fireball',
            description: 'Deal 40 fire damage',
            type: CardType.spell,
            cost: 5,
            effects: [CardEffect(type: 'damage', value: '40')],
          ),
          GameCard(
            name: 'Mana Shield',
            description: 'Absorb next 50 damage with mana',
            type: CardType.spell,
            cost: 4,
            effects: [CardEffect(type: 'mana_shield', value: '50')],
          ),
        ]);
        break;
        
      default:
        skills.addAll([
          GameCard(
            name: 'Basic Strike',
            description: 'Deal 20 damage',
            type: CardType.spell,
            cost: 3,
            effects: [CardEffect(type: 'damage', value: '20')],
          ),
        ]);
    }
    
    return skills;
  }
  
  /// Creates test equipment for a character class
  static List<GameCard> _createTestEquipment(CharacterClass characterClass) {
    final equipment = <GameCard>[];
    
    switch (characterClass) {
      case CharacterClass.paladin:
        equipment.addAll([
          GameCard(
            name: 'Iron Sword',
            description: 'A basic sword',
            type: CardType.weapon,
            attack: 15,
            equipmentSlot: EquipmentSlot.weapon1,
          ),
          GameCard(
            name: 'Chain Mail',
            description: 'Basic armor',
            type: CardType.armor,
            defense: 12,
            equipmentSlot: EquipmentSlot.armor,
          ),
        ]);
        break;
        
      case CharacterClass.barbarian:
        equipment.addAll([
          GameCard(
            name: 'Battle Axe',
            description: 'Heavy two-handed axe',
            type: CardType.weapon,
            attack: 20,
            equipmentSlot: EquipmentSlot.weapon1,
          ),
          GameCard(
            name: 'Leather Armor',
            description: 'Light but flexible',
            type: CardType.armor,
            defense: 8,
            agility: 3,
            equipmentSlot: EquipmentSlot.armor,
          ),
        ]);
        break;
        
      case CharacterClass.sorceress:
        equipment.addAll([
          GameCard(
            name: 'Magic Staff',
            description: 'Enhances spell power',
            type: CardType.weapon,
            attack: 8,
            intelligence: 5,
            equipmentSlot: EquipmentSlot.weapon1,
          ),
          GameCard(
            name: 'Wizard Robes',
            description: 'Increases mana capacity',
            type: CardType.armor,
            defense: 5,
            mana: 15,
            equipmentSlot: EquipmentSlot.armor,
          ),
        ]);
        break;
        
      default:
        equipment.addAll([
          GameCard(
            name: 'Basic Weapon',
            description: 'Simple weapon',
            type: CardType.weapon,
            attack: 10,
            equipmentSlot: EquipmentSlot.weapon1,
          ),
        ]);
    }
    
    return equipment;
  }
  
  /// Gets character class for testing based on index
  static CharacterClass _getTestCharacterClass(int index) {
    final classes = [
      CharacterClass.paladin,
      CharacterClass.barbarian,
      CharacterClass.sorceress,
      CharacterClass.amazon,
      CharacterClass.necromancer,
      CharacterClass.assassin,
    ];
    
    return classes[index % classes.length];
  }
  
  /// Gets base stats for different character classes
  static Map<String, int> _getClassBaseStats(CharacterClass characterClass) {
    switch (characterClass) {
      case CharacterClass.paladin:
        return {
          'health': 100,
          'mana': 40,
          'attack': 25,
          'defense': 20,
          'strength': 18,
          'agility': 12,
          'intelligence': 14,
        };
        
      case CharacterClass.barbarian:
        return {
          'health': 120,
          'mana': 20,
          'attack': 30,
          'defense': 15,
          'strength': 25,
          'agility': 15,
          'intelligence': 8,
        };
        
      case CharacterClass.sorceress:
        return {
          'health': 70,
          'mana': 80,
          'attack': 15,
          'defense': 8,
          'strength': 8,
          'agility': 14,
          'intelligence': 25,
        };
        
      case CharacterClass.amazon:
        return {
          'health': 85,
          'mana': 50,
          'attack': 22,
          'defense': 12,
          'strength': 15,
          'agility': 20,
          'intelligence': 16,
        };
        
      case CharacterClass.necromancer:
        return {
          'health': 75,
          'mana': 70,
          'attack': 18,
          'defense': 10,
          'strength': 10,
          'agility': 12,
          'intelligence': 22,
        };
        
      case CharacterClass.assassin:
        return {
          'health': 80,
          'mana': 45,
          'attack': 28,
          'defense': 10,
          'strength': 16,
          'agility': 25,
          'intelligence': 14,
        };
        
      default:
        return {
          'health': 90,
          'mana': 45,
          'attack': 20,
          'defense': 15,
          'strength': 15,
          'agility': 15,
          'intelligence': 15,
        };
    }
  }
  
  /// Creates a quick 1v1 test battle
  static Battle createQuickTestBattle() {
    return createTestBattle(
      playerCount: 2,
      battleName: 'Quick Test Battle',
    );
  }
  
  /// Creates a multi-player test battle
  static Battle createMultiPlayerTestBattle() {
    return createTestBattle(
      playerCount: 4,
      battleName: 'Multi-Player Test Battle',
    );
  }
  
  /// Creates a boss battle scenario
  static Battle createBossTestBattle() {
    final battle = createTestBattle(
      playerCount: 2,
      battleName: 'Boss Battle Test',
      type: BattleType.pve,
    );
    
    // Make the second player a boss with enhanced stats
    final bossPlayer = battle.players[1];
    final bossCharacter = bossPlayer.character.copyWith(
      name: 'Ancient Dragon',
      baseStrength: 30,
      baseDexterity: 20,
      baseVitality: 35,
      baseEnergy: 25,
      allocatedStrength: 10,
      allocatedDexterity: 5,
      allocatedVitality: 10,
      allocatedEnergy: 5,
    );
    
    final enhancedBoss = bossPlayer.copyWith(
      name: 'Ancient Dragon',
      character: bossCharacter,
      currentHealth: bossCharacter.maxHealth,
      maxHealth: bossCharacter.maxHealth,
    );
    
    final updatedPlayers = [battle.players[0], enhancedBoss];
    return battle.copyWith(players: updatedPlayers);
  }
}