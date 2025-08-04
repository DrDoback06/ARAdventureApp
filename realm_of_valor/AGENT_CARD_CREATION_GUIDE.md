# 🤖 Agent Card Creation Guide

## 📋 Overview

This guide provides detailed instructions for AI agents to create cards for the AR Adventure Game using the JSON-based card system. The system allows for easy creation, validation, and import of cards into the game.

## 🎯 Quick Start

### 1. Basic Card Creation
To create a card, generate a JSON object with the following structure:

```json
{
  "id": "unique_card_id",
  "name": "Card Name",
  "description": "Card description",
  "type": "weapon|armor|spell|enemy|action|consumable|quest|adventure|skill|accessory",
  "rarity": "common|uncommon|rare|epic|legendary|mythic",
  "set": "core|ancients|shadows|elements|mystics|champions",
  "cost": 0,
  "attack": 0,
  "defense": 0,
  "health": 0,
  "mana": 0,
  "strength": 0,
  "agility": 0,
  "intelligence": 0,
  "durability": 100,
  "maxStack": 1,
  "isConsumable": false,
  "isTradeable": true,
  "equipmentSlot": "none|helmet|armor|weapon1|weapon2|gloves|boots|belt|ring1|ring2|amulet|skill1|skill2",
  "allowedClasses": ["holy", "chaos", "arcane", "all"],
  "statModifiers": [],
  "conditions": [],
  "effects": [],
  "imageUrl": "assets/cards/card_name.png",
  "physicalCardId": "PHYS_CARD_001",
  "lore": "Card lore text",
  "tags": ["weapon", "sword", "melee"],
  "customProperties": {}
}
```

### 2. Required Fields
- **id**: Unique identifier (use descriptive names like "iron_sword", "fireball_spell")
- **name**: Display name of the card
- **description**: Brief description of what the card does
- **type**: One of the card types listed above
- **rarity**: One of the rarity levels listed above

### 3. Optional Fields
- **set**: Card set for organization
- **cost**: Mana/energy cost to use the card
- **attack/defense/health/mana**: Base stats
- **strength/agility/intelligence**: Character stats
- **equipmentSlot**: Where the item can be equipped
- **allowedClasses**: Which character classes can use this card
- **statModifiers**: List of stat bonuses the card provides
- **conditions**: Requirements to use the card
- **effects**: Special effects when the card is used
- **imageUrl**: Path to card artwork
- **physicalCardId**: ID for physical card integration
- **lore**: Story text for the card
- **tags**: Keywords for searching/filtering
- **customProperties**: Additional game-specific properties

## 🗡️ Weapon Cards

### Weapon Card Template
```json
{
  "id": "weapon_name",
  "name": "Weapon Name",
  "description": "Weapon description with stats and effects",
  "type": "weapon",
  "rarity": "common",
  "set": "core",
  "cost": 3,
  "attack": 15,
  "defense": 0,
  "equipmentSlot": "weapon1",
  "allowedClasses": ["all"],
  "statModifiers": [
    {
      "statName": "attack",
      "value": 15,
      "isPercentage": false
    }
  ],
  "effects": [],
  "imageUrl": "assets/cards/weapon_name.png",
  "physicalCardId": "PHYS_WEAPON_001",
  "lore": "Weapon lore text",
  "tags": ["weapon", "sword", "melee"]
}
```

### Weapon Examples by Rarity

#### Common Weapons
- **Wooden Sword**: Basic training weapon (+10 ATK)
- **Short Bow**: Simple ranged weapon (+12 ATK, +5 AGI)
- **Stone Axe**: Primitive heavy weapon (+15 ATK, -5 AGI)
- **Apprentice Staff**: Basic magic staff (+8 ATK, +10 INT)

#### Uncommon Weapons
- **Iron Sword**: Reliable blade (+15 ATK)
- **Elvish Longbow**: Precise ranged weapon (+20 ATK, +10 AGI)
- **Steel Battle Axe**: Heavy damage weapon (+25 ATK, -10 AGI)
- **Mage Staff**: Magic-enhancing staff (+12 ATK, +15 INT)

#### Rare Weapons
- **Fire Sword**: Flame-infused blade (+20 ATK, fire damage)
- **Ice Bow**: Frost-infused ranged weapon (+18 ATK, +8 AGI, ice damage)
- **Lightning Spear**: Electric polearm (+22 ATK, lightning damage)
- **Shadow Dagger**: Stealth weapon (+16 ATK, +12 AGI, stealth bonus)

#### Epic Weapons
- **Dragon's Breath Bow**: Fire-infused ranged weapon (+30 ATK, +15 AGI, fire damage)
- **Shadowstrike Crossbow**: Stealthy ranged weapon (+28 ATK, +20 AGI, stealth bonus)
- **Thunderclap Mace**: Lightning-infused blunt weapon (+35 ATK, lightning damage)
- **Frostbite Spear**: Ice-infused polearm (+32 ATK, ice damage)

#### Legendary Weapons
- **Excalibur**: Divine sword (+50 ATK, +20 DEF, fear immunity)
- **Shadowfang Dagger**: Stealth weapon (+35 ATK, +15 AGI, poison on crit)
- **Mjolnir**: Thunder hammer (+45 ATK, +25 STR, lightning damage)
- **Frostmourne**: Cursed blade (+40 ATK, life drain)

## 🛡️ Armor Cards

### Armor Card Template
```json
{
  "id": "armor_name",
  "name": "Armor Name",
  "description": "Armor description with defense and stat bonuses",
  "type": "armor",
  "rarity": "common",
  "set": "core",
  "cost": 4,
  "attack": 0,
  "defense": 20,
  "equipmentSlot": "armor",
  "allowedClasses": ["all"],
  "statModifiers": [
    {
      "statName": "defense",
      "value": 20,
      "isPercentage": false
    }
  ],
  "effects": [],
  "imageUrl": "assets/cards/armor_name.png",
  "physicalCardId": "PHYS_ARMOR_001",
  "lore": "Armor lore text",
  "tags": ["armor", "leather", "light"]
}
```

### Armor Examples by Rarity

#### Common Armor
- **Leather Armor**: Light protection (+20 DEF, +5 AGI)
- **Cloth Robes**: Basic magic robes (+15 DEF, +10 INT)
- **Chain Mail**: Medium protection (+25 DEF, -5 AGI)
- **Hide Armor**: Primitive light armor (+18 DEF, +3 AGI)

#### Uncommon Armor
- **Studded Leather**: Enhanced light armor (+25 DEF, +8 AGI)
- **Arcane Silk Robes**: Magic robes (+20 DEF, +15 INT)
- **Steel Chain Mail**: Medium protection (+30 DEF, -3 AGI)
- **Frostweave Cloth**: Ice magic robes (+18 DEF, +12 INT, ice resistance)

#### Rare Armor
- **Shadowhide Leather**: Stealth armor (+28 DEF, +12 AGI, stealth bonus)
- **Thunderweave Cloth**: Lightning robes (+22 DEF, +18 INT, lightning resistance)
- **Iron Plate Mail**: Heavy protection (+40 DEF, -8 AGI)
- **Flameweave Cloth**: Fire robes (+20 DEF, +15 INT, fire resistance)

#### Epic Armor
- **Dragonhide Leather**: Dragon scale light armor (+35 DEF, +15 AGI, fire immunity)
- **Shadowweave Robes**: Stealth magic robes (+25 DEF, +20 INT, stealth bonus)
- **Thunderhide Leather**: Lightning light armor (+32 DEF, +18 AGI, lightning immunity)
- **Frostweave Robes**: Ice magic robes (+28 DEF, +22 INT, ice immunity)

#### Legendary Armor
- **Ancient Dragon Scale Mail**: Dragon scale armor (+60 DEF, +30 HP, fire immunity)
- **Shadowplate Armor**: Stealth heavy armor (+50 DEF, +20 AGI, stealth bonus)
- **Thunderplate Mail**: Lightning heavy armor (+55 DEF, +25 STR, lightning immunity)
- **Frostplate Armor**: Ice heavy armor (+52 DEF, +28 HP, ice immunity)

## 🔮 Spell Cards

### Spell Card Template
```json
{
  "id": "spell_name",
  "name": "Spell Name",
  "description": "Spell description with damage and effects",
  "type": "spell",
  "rarity": "common",
  "set": "elements",
  "cost": 3,
  "attack": 30,
  "defense": 0,
  "equipmentSlot": "none",
  "allowedClasses": ["arcane", "chaos"],
  "statModifiers": [],
  "conditions": [],
  "effects": [
    {
      "type": "fire_damage",
      "value": "30",
      "duration": 0
    }
  ],
  "imageUrl": "assets/cards/spell_name.png",
  "physicalCardId": "PHYS_SPELL_001",
  "lore": "Spell lore text",
  "tags": ["spell", "fire", "damage"]
}
```

### Spell Examples by Rarity

#### Common Spells
- **Spark**: Basic lightning damage (+15 ATK, lightning damage)
- **Chill**: Basic ice damage (+12 ATK, ice damage)
- **Burn**: Basic fire damage (+18 ATK, fire damage)
- **Shadow Touch**: Basic shadow damage (+14 ATK, shadow damage)

#### Uncommon Spells
- **Lightning Bolt**: Single target lightning (+25 ATK, lightning damage)
- **Ice Bolt**: Single target ice (+22 ATK, ice damage)
- **Fireball**: Single target fire (+30 ATK, fire damage)
- **Shadow Bolt**: Single target shadow (+24 ATK, shadow damage)

#### Rare Spells
- **Thunder Clap**: Area lightning damage (+35 ATK, area lightning)
- **Frost Nova**: Area ice damage (+32 ATK, area ice)
- **Fire Nova**: Area fire damage (+40 ATK, area fire)
- **Shadow Nova**: Area shadow damage (+30 ATK, area shadow)

#### Epic Spells
- **Lightning Chain**: Chain lightning (+45 ATK, chain lightning)
- **Ice Chain**: Chain ice damage (+42 ATK, chain ice)
- **Fire Chain**: Chain fire damage (+50 ATK, chain fire)
- **Shadow Chain**: Chain shadow damage (+38 ATK, chain shadow)

#### Legendary Spells
- **Meteor Storm**: Massive area fire (+80 ATK, area fire, burn effect)
- **Thunder Storm**: Massive area lightning (+75 ATK, area lightning, shock effect)
- **Frost Storm**: Massive area ice (+70 ATK, area ice, freeze effect)
- **Shadow Storm**: Massive area shadow (+65 ATK, area shadow, curse effect)

## 👹 Enemy Cards

### Enemy Card Template
```json
{
  "id": "enemy_name",
  "name": "Enemy Name",
  "description": "Enemy description with stats and abilities",
  "type": "enemy",
  "rarity": "common",
  "set": "core",
  "cost": 0,
  "attack": 20,
  "defense": 15,
  "health": 35,
  "equipmentSlot": "none",
  "allowedClasses": ["all"],
  "statModifiers": [],
  "conditions": [],
  "effects": [],
  "imageUrl": "assets/cards/enemy_name.png",
  "physicalCardId": "PHYS_ENEMY_001",
  "lore": "Enemy lore text",
  "tags": ["enemy", "goblin", "warrior"]
}
```

### Enemy Examples by Rarity

#### Common Enemies
- **Goblin Warrior**: Basic enemy (+20 ATK, +15 DEF, 35 HP)
- **Orc Warrior**: Basic enemy (+25 ATK, +18 DEF, 40 HP)
- **Troll Warrior**: Basic enemy (+30 ATK, +20 DEF, 50 HP)
- **Goblin Archer**: Ranged enemy (+18 ATK, +12 DEF, 30 HP)

#### Uncommon Enemies
- **Shadow Wraith**: Stealth enemy (+30 ATK, +15 DEF, 45 HP, stealth)
- **Thunder Elemental**: Lightning enemy (+35 ATK, +20 DEF, 55 HP, lightning)
- **Frost Giant**: Ice enemy (+40 ATK, +25 DEF, 65 HP, ice)
- **Soul Reaper**: Life drain enemy (+32 ATK, +18 DEF, 50 HP, life drain)

#### Rare Enemies
- **Dragon Knight**: Elite dragon warrior (+50 ATK, +30 DEF, 80 HP, fire breath)
- **Shadow Assassin**: Elite shadow killer (+45 ATK, +25 DEF, 60 HP, stealth)
- **Thunder Knight**: Elite lightning warrior (+55 ATK, +35 DEF, 90 HP, lightning)
- **Frost Knight**: Elite ice warrior (+52 ATK, +32 DEF, 85 HP, ice)

#### Epic Enemies
- **Dragon Lord**: Dragon commander (+70 ATK, +45 DEF, 120 HP, fire breath, fear)
- **Shadow Lord**: Shadow master (+65 ATK, +40 DEF, 100 HP, stealth, curse)
- **Thunder Lord**: Lightning master (+75 ATK, +50 DEF, 130 HP, lightning, shock)
- **Frost Lord**: Ice master (+68 ATK, +42 DEF, 110 HP, ice, freeze)

#### Legendary Enemies
- **Bahamut**: Ancient dragon (+120 ATK, +80 DEF, 500 HP, breath weapon, fear aura)
- **Shadow Lord**: Master of darkness (+100 ATK, +60 DEF, 300 HP, stealth, curse)
- **Thunder Lord**: Master of lightning (+110 ATK, +70 DEF, 350 HP, lightning, shock)
- **Frost Lord**: Master of ice (+105 ATK, +65 DEF, 320 HP, ice, freeze)

## ⚔️ Action Cards

### Action Card Template
```json
{
  "id": "action_name",
  "name": "Action Name",
  "description": "Action description with effects and duration",
  "type": "action",
  "rarity": "common",
  "set": "core",
  "cost": 2,
  "attack": 10,
  "defense": 0,
  "equipmentSlot": "none",
  "allowedClasses": ["all"],
  "statModifiers": [],
  "conditions": [],
  "effects": [
    {
      "type": "damage",
      "value": "10",
      "duration": 0
    }
  ],
  "imageUrl": "assets/cards/action_name.png",
  "physicalCardId": "PHYS_ACTION_001",
  "lore": "Action lore text",
  "tags": ["action", "attack", "basic"]
}
```

### Action Examples by Rarity

#### Common Actions
- **Basic Attack**: Simple attack (+10 ATK)
- **Basic Block**: Simple defense (+10 DEF)
- **Quick Strike**: Fast attack (+8 ATK, +2 AGI)
- **Quick Block**: Fast defense (+8 DEF, +2 AGI)

#### Uncommon Actions
- **Power Strike**: Basic power attack (+15 ATK)
- **Power Block**: Basic defense (+15 DEF)
- **Shadow Strike**: Stealth attack (+12 ATK, stealth bonus)
- **Shadow Block**: Stealth defense (+12 DEF, stealth bonus)

#### Rare Actions
- **Stealth Strike**: Guaranteed critical hit (+20 ATK, guaranteed crit)
- **Thunder Strike**: Lightning critical hit (+18 ATK, lightning damage)
- **Frost Strike**: Ice critical hit (+17 ATK, ice damage)
- **Soul Strike**: Life drain critical hit (+16 ATK, life drain)

#### Epic Actions
- **Berserker Rage**: Double attack, increased damage (+40 ATK, double attack, +25% damage taken)
- **Shadow Form**: Complete invisibility (stealth, guaranteed crit)
- **Thunder Form**: Lightning transformation (lightning damage, lightning immunity)
- **Frost Form**: Ice transformation (ice damage, ice immunity)

#### Legendary Actions
- **Dragon Rage**: Dragon transformation (+60 ATK, fire breath, fear immunity)
- **Shadow Mastery**: Ultimate stealth (permanent stealth, guaranteed crit)
- **Thunder Mastery**: Ultimate lightning (massive lightning damage, lightning immunity)
- **Frost Mastery**: Ultimate ice (massive ice damage, ice immunity)

## 🧪 Consumable Cards

### Consumable Card Template
```json
{
  "id": "consumable_name",
  "name": "Consumable Name",
  "description": "Consumable description with healing or buff effects",
  "type": "consumable",
  "rarity": "common",
  "set": "core",
  "cost": 2,
  "attack": 0,
  "defense": 0,
  "equipmentSlot": "none",
  "allowedClasses": ["all"],
  "statModifiers": [],
  "conditions": [],
  "effects": [
    {
      "type": "heal",
      "value": "50",
      "duration": 0
    }
  ],
  "isConsumable": true,
  "imageUrl": "assets/cards/consumable_name.png",
  "physicalCardId": "PHYS_CONSUMABLE_001",
  "lore": "Consumable lore text",
  "tags": ["consumable", "heal", "potion"]
}
```

### Consumable Examples by Rarity

#### Common Consumables
- **Minor Health Potion**: Small heal (+30 HP)
- **Minor Mana Potion**: Small mana restore (+30 MP)
- **Bread**: Small heal (+20 HP)
- **Water**: Small mana restore (+25 MP)

#### Uncommon Consumables
- **Health Potion**: Medium heal (+50 HP)
- **Mana Potion**: Medium mana restore (+50 MP)
- **Potion of Strength**: Strength boost (+5 STR, 3 turns)
- **Potion of Speed**: Speed boost (+5 AGI, 3 turns)

#### Rare Consumables
- **Greater Health Potion**: Large heal (+100 HP)
- **Greater Mana Potion**: Large mana restore (+100 MP)
- **Potion of Invisibility**: Temporary invisibility (stealth, 3 turns)
- **Potion of Flight**: Temporary flight (movement bonus, 2 turns)

#### Epic Consumables
- **Elixir of Life**: Full heal and invulnerability (full heal, invulnerability 5 turns)
- **Potion of Ultimate Power**: Massive stat boost (+20 all stats, 3 turns)
- **Scroll of Resurrection**: Revive from death (revive, full heal)
- **Crystal of Time**: Reverse time effects (remove all debuffs)

#### Legendary Consumables
- **Elixir of Eternal Life**: Ultimate potion (full heal, permanent invulnerability)
- **Essence of the Void**: Ultimate transformation (all stats +50, permanent)
- **Potion of Immortality**: Death prevention (cannot die, 10 turns)
- **Crystal of Creation**: Ultimate creation (create any item)

## 🎒 Accessory Cards

### Accessory Card Template
```json
{
  "id": "accessory_name",
  "name": "Accessory Name",
  "description": "Accessory description with stat bonuses and effects",
  "type": "accessory",
  "rarity": "common",
  "set": "core",
  "cost": 3,
  "attack": 0,
  "defense": 0,
  "equipmentSlot": "ring1",
  "allowedClasses": ["all"],
  "statModifiers": [
    {
      "statName": "strength",
      "value": 5,
      "isPercentage": false
    }
  ],
  "conditions": [],
  "effects": [],
  "imageUrl": "assets/cards/accessory_name.png",
  "physicalCardId": "PHYS_ACCESSORY_001",
  "lore": "Accessory lore text",
  "tags": ["accessory", "ring", "strength"]
}
```

### Accessory Examples by Rarity

#### Common Accessories
- **Copper Ring**: Basic ring (+3 STR)
- **Iron Ring**: Basic ring (+3 DEF)
- **Copper Amulet**: Basic amulet (+3 INT)
- **Iron Amulet**: Basic amulet (+3 HP)

#### Uncommon Accessories
- **Ring of Strength**: Strength ring (+8 STR)
- **Ring of Agility**: Agility ring (+8 AGI)
- **Ring of Intelligence**: Intelligence ring (+8 INT)
- **Amulet of Protection**: Defense amulet (+8 DEF)

#### Rare Accessories
- **Ring of Fire**: Fire resistance ring (+5 STR, fire resistance)
- **Ring of Ice**: Ice resistance ring (+5 AGI, ice resistance)
- **Ring of Lightning**: Lightning resistance ring (+5 INT, lightning resistance)
- **Amulet of Fire**: Fire protection amulet (+8 DEF, fire resistance)

#### Epic Accessories
- **Ring of Power**: Power ring (+15 all stats)
- **Amulet of Immortality**: Death prevention amulet (cannot die)
- **Crown of Kings**: Royal authority crown (+20 all stats, leadership)
- **Cloak of Invisibility**: Permanent invisibility cloak (permanent stealth)

#### Legendary Accessories
- **Ring of Ultimate Power**: Ultimate power ring (+30 all stats, all immunities)
- **Amulet of Eternal Life**: Eternal life amulet (immortality, regeneration)
- **Crown of the Gods**: Divine crown (+50 all stats, divine authority)
- **Cloak of the Void**: Ultimate stealth cloak (permanent invisibility, teleport)

## 📜 Quest Cards

### Quest Card Template
```json
{
  "id": "quest_name",
  "name": "Quest Name",
  "description": "Quest description with objectives and rewards",
  "type": "quest",
  "rarity": "rare",
  "set": "core",
  "cost": 0,
  "attack": 0,
  "defense": 0,
  "equipmentSlot": "none",
  "allowedClasses": ["all"],
  "statModifiers": [],
  "conditions": [],
  "effects": [
    {
      "type": "quest_objective",
      "value": "slay_dragon",
      "duration": 0
    }
  ],
  "imageUrl": "assets/cards/quest_name.png",
  "physicalCardId": "PHYS_QUEST_001",
  "lore": "Quest lore text",
  "tags": ["quest", "dragon", "slayer"]
}
```

### Quest Examples by Rarity

#### Rare Quests
- **The Goblin Slayer**: Slay goblins (slay 10 goblins, reward: +5 ATK)
- **The Orc Hunter**: Hunt orcs (slay 8 orcs, reward: +5 DEF)
- **The Troll Fighter**: Fight trolls (slay 5 trolls, reward: +10 HP)
- **The Treasure Hunter**: Hunt treasure (find 3 treasures, reward: +100 gold)

#### Epic Quests
- **The Fire Walker**: Walk through fire (survive fire damage, reward: fire immunity)
- **The Ice Climber**: Climb ice mountains (reach mountain peak, reward: ice immunity)
- **The Lightning Runner**: Run with lightning (complete lightning course, reward: lightning immunity)
- **The Shadow Walker**: Walk in shadows (stealth mission, reward: stealth bonus)

#### Legendary Quests
- **The Dragon Slayer**: Slay the ancient dragon (defeat Bahamut, reward: Excalibur)
- **The Shadow Hunter**: Hunt the shadow lord (defeat shadow lord, reward: shadow mastery)
- **The Thunder Seeker**: Seek the thunder lord (defeat thunder lord, reward: thunder mastery)
- **The Frost Walker**: Walk the frost path (complete frost trials, reward: frost mastery)

## 🗺️ Adventure Cards

### Adventure Card Template
```json
{
  "id": "adventure_name",
  "name": "Adventure Name",
  "description": "Adventure description with location and challenges",
  "type": "adventure",
  "rarity": "rare",
  "set": "core",
  "cost": 0,
  "attack": 0,
  "defense": 0,
  "equipmentSlot": "none",
  "allowedClasses": ["all"],
  "statModifiers": [],
  "conditions": [],
  "effects": [
    {
      "type": "adventure_location",
      "value": "dark_forest",
      "duration": 0
    }
  ],
  "imageUrl": "assets/cards/adventure_name.png",
  "physicalCardId": "PHYS_ADVENTURE_001",
  "lore": "Adventure lore text",
  "tags": ["adventure", "forest", "exploration"]
}
```

### Adventure Examples by Rarity

#### Rare Adventures
- **The Goblin Cave**: Explore goblin cave (explore cave, reward: goblin loot)
- **The Orc Camp**: Raid orc camp (raid camp, reward: orc weapons)
- **The Troll Den**: Enter troll den (enter den, reward: troll armor)
- **The Treasure Island**: Find treasure island (find island, reward: treasure)

#### Epic Adventures
- **The Fire Cave**: Explore fire cave (survive fire cave, reward: fire resistance)
- **The Ice Cave**: Explore ice cave (survive ice cave, reward: ice resistance)
- **The Lightning Cave**: Explore lightning cave (survive lightning cave, reward: lightning resistance)
- **The Shadow Cave**: Explore shadow cave (survive shadow cave, reward: shadow resistance)

#### Legendary Adventures
- **The Lost City**: Find the lost city (discover city, reward: ancient knowledge)
- **The Dark Forest**: Navigate dark forest (navigate forest, reward: forest mastery)
- **The Frozen Peak**: Climb frozen peak (climb peak, reward: frost mastery)
- **The Thunder Mountain**: Climb thunder mountain (climb mountain, reward: thunder mastery)

## 🎯 Skill Cards

### Skill Card Template
```json
{
  "id": "skill_name",
  "name": "Skill Name",
  "description": "Skill description with mastery effects",
  "type": "skill",
  "rarity": "rare",
  "set": "core",
  "cost": 0,
  "attack": 0,
  "defense": 0,
  "equipmentSlot": "skill1",
  "allowedClasses": ["all"],
  "statModifiers": [
    {
      "statName": "attack",
      "value": 10,
      "isPercentage": false
    }
  ],
  "conditions": [],
  "effects": [
    {
      "type": "skill_mastery",
      "value": "weapon_mastery",
      "duration": 0
    }
  ],
  "imageUrl": "assets/cards/skill_name.png",
  "physicalCardId": "PHYS_SKILL_001",
  "lore": "Skill lore text",
  "tags": ["skill", "mastery", "weapon"]
}
```

### Skill Examples by Rarity

#### Rare Skills
- **Weapon Mastery**: Master weapons (+10 ATK, weapon damage bonus)
- **Armor Mastery**: Master armor (+10 DEF, armor protection bonus)
- **Magic Mastery**: Master magic (+10 INT, spell damage bonus)
- **Combat Mastery**: Master combat (+5 ATK, +5 DEF, combat bonus)

#### Epic Skills
- **Fire Mastery**: Master fire abilities (+15 ATK, fire damage bonus)
- **Ice Mastery**: Master ice abilities (+15 INT, ice damage bonus)
- **Lightning Mastery**: Master lightning abilities (+15 ATK, lightning damage bonus)
- **Shadow Mastery**: Master shadow abilities (+15 AGI, shadow damage bonus)

#### Legendary Skills
- **Dragon Mastery**: Master dragon abilities (+25 ATK, dragon transformation)
- **Shadow Mastery**: Master shadow abilities (+25 AGI, permanent stealth)
- **Thunder Mastery**: Master thunder abilities (+25 ATK, lightning immunity)
- **Frost Mastery**: Master frost abilities (+25 INT, ice immunity)

## 📊 Card Creation Guidelines

### 1. Balance Guidelines
- **Common cards**: Basic functionality, low stats
- **Uncommon cards**: Slight improvements, minor effects
- **Rare cards**: Notable improvements, special effects
- **Epic cards**: Significant bonuses, powerful effects
- **Legendary cards**: Game-changing abilities, unique effects

### 2. Stat Guidelines
- **Attack**: 10-120 (common to legendary)
- **Defense**: 10-80 (common to legendary)
- **Health**: 20-500 (enemies only)
- **Cost**: 0-20 (based on power level)
- **Stat bonuses**: 3-50 (based on rarity)

### 3. Effect Guidelines
- **Common effects**: Basic damage, healing, stat boosts
- **Uncommon effects**: Elemental damage, status effects
- **Rare effects**: Area effects, chain effects, transformations
- **Epic effects**: Immunity, permanent bonuses, unique abilities
- **Legendary effects**: Game-breaking abilities, ultimate powers

### 4. Theme Guidelines
- **Fire theme**: Red colors, fire damage, burn effects
- **Ice theme**: Blue colors, ice damage, freeze effects
- **Lightning theme**: Yellow colors, lightning damage, shock effects
- **Shadow theme**: Purple colors, shadow damage, stealth effects
- **Holy theme**: White colors, healing, protection effects
- **Chaos theme**: Black colors, destruction, corruption effects

### 5. Class Guidelines
- **Holy class**: Healing, protection, divine magic
- **Chaos class**: Destruction, corruption, dark magic
- **Arcane class**: Elemental magic, versatility, balance
- **All classes**: Universal items, basic functionality

## 🔧 Technical Implementation

### 1. JSON Validation
All cards must pass validation before import:
- Required fields present
- Valid enum values
- Positive stat values
- Unique IDs

### 2. Import Process
1. Agent creates JSON card data
2. Validate card data
3. Import into CardImportService
4. Add to game database
5. Test functionality
6. Deploy to production

### 3. File Organization
- **Sample cards**: `assets/cards/sample_cards.json`
- **Card images**: `assets/cards/` directory
- **Card service**: `lib/services/card_import_service.dart`
- **Card models**: `lib/models/card_model.dart`

### 4. Testing
- Validate JSON format
- Test card effects in game
- Balance check against existing cards
- Performance testing with large card sets

## 📝 Agent Instructions

### For Creating Cards:
1. **Choose card type** (weapon, armor, spell, etc.)
2. **Select rarity** (common to legendary)
3. **Design stats** (attack, defense, etc.)
4. **Add effects** (damage, healing, etc.)
5. **Write lore** (story and background)
6. **Add tags** (for searching/filtering)
7. **Generate JSON** (using template)
8. **Validate data** (check all fields)
9. **Export to file** (ready for import)

### For Batch Creation:
1. **Create multiple cards** of same type/rarity
2. **Maintain consistency** in naming and stats
3. **Balance power levels** across rarity tiers
4. **Add variety** in effects and themes
5. **Test combinations** for synergies
6. **Export as JSON array** for bulk import

### For Quality Control:
1. **Check for duplicates** (names, IDs, effects)
2. **Verify balance** (stats appropriate for rarity)
3. **Test functionality** (effects work as intended)
4. **Review lore** (consistent with game world)
5. **Validate JSON** (proper format and structure)

This comprehensive guide provides everything needed for agents to create high-quality cards for the AR Adventure Game using the JSON-based system. 