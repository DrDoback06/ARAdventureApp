import '../models/card_model.dart';
import '../models/character_model.dart';

class BasicSkillService {
  static final BasicSkillService _instance = BasicSkillService._internal();
  factory BasicSkillService() => _instance;
  BasicSkillService._internal();

  // Generate basic attack skills for a character
  List<GameCard> getBasicAttackSkills(GameCharacter character) {
    List<GameCard> basicSkills = [];
    
    // Add basic attack based on character class
    switch (character.characterClass) {
      case CharacterClass.barbarian:
        basicSkills.addAll(_getBarbarianBasicSkills());
        break;
      case CharacterClass.paladin:
        basicSkills.addAll(_getPaladinBasicSkills());
        break;
      case CharacterClass.sorceress:
        basicSkills.addAll(_getSorcererBasicSkills());
        break;
      case CharacterClass.assassin:
        basicSkills.addAll(_getAssassinBasicSkills());
        break;
      case CharacterClass.druid:
        basicSkills.addAll(_getDruidBasicSkills());
        break;
      case CharacterClass.necromancer:
        basicSkills.addAll(_getNecromancerBasicSkills());
        break;
      case CharacterClass.amazon:
        basicSkills.addAll(_getAmazonBasicSkills());
        break;
      case CharacterClass.monk:
        basicSkills.addAll(_getMonkBasicSkills());
        break;
      case CharacterClass.crusader:
        basicSkills.addAll(_getPaladinBasicSkills()); // Crusader uses paladin skills
        break;
      case CharacterClass.witchDoctor:
        basicSkills.addAll(_getNecromancerBasicSkills()); // Witch Doctor uses necromancer skills
        break;
      case CharacterClass.wizard:
        basicSkills.addAll(_getSorcererBasicSkills()); // Wizard uses sorcerer skills
        break;
      case CharacterClass.demonHunter:
        basicSkills.addAll(_getAssassinBasicSkills()); // Demon Hunter uses assassin skills
        break;
    }
    
    // Add universal basic attack
    basicSkills.add(_getUniversalBasicAttack());
    
    return basicSkills;
  }

  GameCard _getUniversalBasicAttack() {
    return GameCard(
      id: 'basic_attack',
      name: 'Basic Attack',
      description: 'A simple physical attack',
      type: CardType.skill,
      rarity: CardRarity.common,
      cost: 0,
      customProperties: {
        'damage': 10,
        'accuracy': 90,
        'effect': 'physical_attack',
        'can_counter': false,
      },
      attack: 10,
      defense: 0,
      health: 0,
      mana: 0,
    );
  }

  List<GameCard> _getBarbarianBasicSkills() {
    return [
      GameCard(
        id: 'berserker_strike',
        name: 'Berserker Strike',
        description: 'A powerful melee attack with increased damage',
        type: CardType.skill,
        rarity: CardRarity.common,
        cost: 5,
        customProperties: {
          'damage': 25,
          'accuracy': 85,
          'effect': 'physical_attack',
          'can_counter': false,
          'rage_bonus': 5,
        },
        attack: 25,
        defense: 0,
        health: 0,
        mana: 0,
      ),
      GameCard(
        id: 'battle_cry',
        name: 'Battle Cry',
        description: 'Intimidate enemies and boost your attack',
        type: CardType.spell,
        rarity: CardRarity.common,
        cost: 10,
        customProperties: {
          'effect': 'buff',
          'buff_type': 'attack_bonus',
          'buff_value': 15,
          'duration': 3,
          'can_counter': true,
        },
        attack: 0,
        defense: 0,
        health: 0,
        mana: 0,
      ),
    ];
  }

  List<GameCard> _getPaladinBasicSkills() {
    return [
      GameCard(
        id: 'holy_strike',
        name: 'Holy Strike',
        description: 'A divine attack that deals holy damage',
        type: CardType.skill,
        rarity: CardRarity.common,
        cost: 8,
        customProperties: {
          'damage': 20,
          'accuracy': 90,
          'effect': 'holy_attack',
          'can_counter': false,
          'heal_bonus': 5,
        },
        attack: 20,
        defense: 0,
        health: 0,
        mana: 0,
      ),
      GameCard(
        id: 'divine_protection',
        name: 'Divine Protection',
        description: 'Create a protective barrier',
        type: CardType.spell,
        rarity: CardRarity.common,
        cost: 12,
        customProperties: {
          'effect': 'buff',
          'buff_type': 'defense_bonus',
          'buff_value': 20,
          'duration': 2,
          'can_counter': true,
        },
        attack: 0,
        defense: 0,
        health: 0,
        mana: 0,
      ),
    ];
  }

  List<GameCard> _getSorcererBasicSkills() {
    return [
      GameCard(
        id: 'fire_bolt',
        name: 'Fire Bolt',
        description: 'Launch a bolt of fire at your enemy',
        type: CardType.spell,
        rarity: CardRarity.common,
        cost: 15,
        customProperties: {
          'damage': 30,
          'accuracy': 85,
          'effect': 'fire_attack',
          'can_counter': true,
          'burn_chance': 25,
        },
        attack: 30,
        defense: 0,
        health: 0,
        mana: 0,
      ),
      GameCard(
        id: 'ice_shard',
        name: 'Ice Shard',
        description: 'Conjure a sharp ice shard',
        type: CardType.spell,
        rarity: CardRarity.common,
        cost: 12,
        customProperties: {
          'damage': 25,
          'accuracy': 90,
          'effect': 'ice_attack',
          'can_counter': true,
          'freeze_chance': 20,
        },
        attack: 25,
        defense: 0,
        health: 0,
        mana: 0,
      ),
    ];
  }

  List<GameCard> _getAssassinBasicSkills() {
    return [
      GameCard(
        id: 'backstab',
        name: 'Backstab',
        description: 'A stealthy attack with high critical chance',
        type: CardType.skill,
        rarity: CardRarity.common,
        cost: 10,
        customProperties: {
          'damage': 35,
          'accuracy': 75,
          'effect': 'stealth_attack',
          'can_counter': false,
          'crit_chance': 40,
        },
        attack: 35,
        defense: 0,
        health: 0,
        mana: 0,
      ),
      GameCard(
        id: 'shadow_step',
        name: 'Shadow Step',
        description: 'Teleport behind your enemy',
        type: CardType.spell,
        rarity: CardRarity.common,
        cost: 8,
        customProperties: {
          'effect': 'movement',
          'movement_type': 'teleport',
          'can_counter': true,
        },
        attack: 0,
        defense: 0,
        health: 0,
        mana: 0,
      ),
    ];
  }

  List<GameCard> _getDruidBasicSkills() {
    return [
      GameCard(
        id: 'nature_strike',
        name: 'Nature Strike',
        description: 'Channel nature\'s power into your attack',
        type: CardType.skill,
        rarity: CardRarity.common,
        cost: 6,
        customProperties: {
          'damage': 18,
          'accuracy': 88,
          'effect': 'nature_attack',
          'can_counter': false,
          'heal_self': 3,
        },
        attack: 18,
        defense: 0,
        health: 0,
        mana: 0,
      ),
      GameCard(
        id: 'healing_touch',
        name: 'Healing Touch',
        description: 'Restore health with nature magic',
        type: CardType.spell,
        rarity: CardRarity.common,
        cost: 15,
        customProperties: {
          'effect': 'heal',
          'heal_amount': 25,
          'can_counter': true,
        },
        attack: 0,
        defense: 0,
        health: 0,
        mana: 0,
      ),
    ];
  }

  List<GameCard> _getNecromancerBasicSkills() {
    return [
      GameCard(
        id: 'death_touch',
        name: 'Death Touch',
        description: 'Drain life from your enemy',
        type: CardType.spell,
        rarity: CardRarity.common,
        cost: 12,
        customProperties: {
          'damage': 20,
          'accuracy': 80,
          'effect': 'life_drain',
          'can_counter': true,
          'heal_amount': 10,
        },
        attack: 20,
        defense: 0,
        health: 0,
        mana: 0,
      ),
      GameCard(
        id: 'bone_armor',
        name: 'Bone Armor',
        description: 'Create armor from bones',
        type: CardType.spell,
        rarity: CardRarity.common,
        cost: 10,
        customProperties: {
          'effect': 'buff',
          'buff_type': 'defense_bonus',
          'buff_value': 15,
          'duration': 3,
          'can_counter': true,
        },
        attack: 0,
        defense: 0,
        health: 0,
        mana: 0,
      ),
    ];
  }

  List<GameCard> _getAmazonBasicSkills() {
    return [
      GameCard(
        id: 'precise_shot',
        name: 'Precise Shot',
        description: 'A carefully aimed ranged attack',
        type: CardType.attack,
        rarity: CardRarity.common,
        cost: 8,
        customProperties: {
          'damage': 22,
          'accuracy': 95,
          'effect': 'ranged_attack',
          'can_counter': false,
          'range_bonus': 2,
        },
        attack: 22,
        defense: 0,
        health: 0,
        mana: 0,
      ),
      GameCard(
        id: 'evasion',
        name: 'Evasion',
        description: 'Increase your dodge chance',
        type: CardType.spell,
        rarity: CardRarity.common,
        cost: 6,
        customProperties: {
          'effect': 'buff',
          'buff_type': 'dodge_chance',
          'buff_value': 25,
          'duration': 2,
          'can_counter': true,
        },
        attack: 0,
        defense: 0,
        health: 0,
        mana: 0,
      ),
    ];
  }

  List<GameCard> _getMonkBasicSkills() {
    return [
      GameCard(
        id: 'flying_kick',
        name: 'Flying Kick',
        description: 'A powerful martial arts attack',
        type: CardType.attack,
        rarity: CardRarity.common,
        cost: 7,
        customProperties: {
          'damage': 28,
          'accuracy': 82,
          'effect': 'martial_attack',
          'can_counter': false,
          'stun_chance': 15,
        },
        attack: 28,
        defense: 0,
        health: 0,
        mana: 0,
      ),
      GameCard(
        id: 'meditation',
        name: 'Meditation',
        description: 'Focus your mind and restore mana',
        type: CardType.spell,
        rarity: CardRarity.common,
        cost: 0,
        customProperties: {
          'effect': 'mana_restore',
          'mana_amount': 20,
          'can_counter': true,
        },
        attack: 0,
        defense: 0,
        health: 0,
        mana: 0,
      ),
    ];
  }
} 