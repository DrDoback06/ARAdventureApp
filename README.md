# Realm of Valor

A hybrid card-based and role-playing game with dark whimsical fantasy elements, combining the gritty mechanics of Diablo II with the playful style of Adventure Time.

## 🎮 Overview

Realm of Valor is a Flutter-based companion app that serves two primary functions:

1. **Enhancement of Physical Card Game**: Players can use physical cards with QR codes to update their digital inventory, trigger events, and manage progress.
2. **Standalone Digital Experience**: Full digital gameplay with turn-based combat, quests, character progression, and inventory management.

## ✨ Features

### 🎯 High Priority Features (Implemented)

#### Card Creator/Editor
- **Visual Card Editor**: Comprehensive interface for creating and editing cards
- **Real-time Preview**: Live preview of cards as you edit them
- **Card Validation**: Built-in validation system to ensure card integrity
- **Template System**: Quick templates for weapons, armor, skills, and more
- **Export/Import**: JSON-based card data management
- **Multiple Card Types**: Items, quests, adventures, skills, weapons, armor, consumables, spells
- **Stat Modifiers**: Add bonuses to character stats
- **Usage Conditions**: Set requirements for card usage (level, stats, class, etc.)
- **Visual Effects**: Rarity-based borders and color coding

#### Character System
- **Diablo II-inspired Stats**: Strength, Dexterity, Vitality, Energy
- **Character Classes**: Holy, Chaos, Arcane with distinct abilities
- **Level Progression**: Experience-based leveling with stat and skill points
- **Skill Trees**: Class-specific skill trees (Divine, Protection, Healing for Holy, etc.)
- **Real-time Stat Updates**: Live calculation of total stats including equipment bonuses
- **Equipment Integration**: Full compatibility with card system
- **Health/Mana System**: Dynamic health and mana based on stats

#### Drag & Drop Inventory
- **Diablo II-style Interface**: Grid-based inventory with equipment slots
- **Equipment Slots**: Helmet, Armor, Weapons (2), Gloves, Boots, Belt, Rings (2), Amulet
- **Active Skills**: 2 skill slots on the belt for quick access
- **Stash System**: Separate storage with tabs for different item types
- **Visual Feedback**: Hover effects and drag feedback
- **Stat Preview**: Real-time stat updates when equipping/unequipping items
- **Item Tooltips**: Detailed information on hover

### 🔮 Core Game Mechanics

#### Character Classes
- **Holy**: Divine magic, healing, protection
  - Skill Trees: Divine, Protection, Healing
  - Playstyle: Support and defensive abilities
  
- **Chaos**: Dark magic, destruction, corruption
  - Skill Trees: Destruction, Corruption, Summoning
  - Playstyle: High damage with risk/reward mechanics
  
- **Arcane**: Elemental magic, versatile abilities
  - Skill Trees: Elemental, Enchantment, Manipulation
  - Playstyle: Balanced magical combat

#### Card Types
- **Weapons**: Provide attack damage and stat bonuses
- **Armor**: Defensive equipment for various slots
- **Skills**: Active abilities that consume mana
- **Quests**: Objective-based cards with rewards
- **Adventures**: Story-driven content
- **Consumables**: Single-use items with effects
- **Accessories**: Rings, amulets, and special items

#### Rarity System
- **Common** (White): Basic items
- **Uncommon** (Green): Slightly enhanced
- **Rare** (Blue): Notable improvements
- **Epic** (Purple): Significant bonuses
- **Legendary** (Orange): Powerful unique items
- **Mythic** (Pink): Extremely rare artifacts

### 🎨 Visual Design

#### Dark Whimsical Theme
- **Color Palette**: Dark backgrounds with amber/gold accents
- **Gothic Elements**: Medieval fantasy aesthetics
- **Playful Highlights**: Cartoon-style character designs
- **Modern UI**: Clean, responsive interface design

#### Card Design
- **Rarity Borders**: Color-coded borders based on rarity
- **Type Icons**: Distinct icons for each card type
- **Stat Display**: Clear presentation of card statistics
- **Tooltips**: Comprehensive information on hover

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.24.5 or later)
- Dart SDK
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd realm_of_valor
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate JSON serialization files**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── card_model.dart      # Card and related models
│   └── character_model.dart  # Character and equipment models
├── services/                 # Business logic services
│   ├── card_editor_service.dart
│   └── character_service.dart
├── providers/               # State management
│   └── character_provider.dart
├── screens/                 # UI screens
│   ├── home_screen.dart
│   └── card_editor_screen.dart
├── widgets/                 # Reusable UI components
│   ├── card_widget.dart
│   └── inventory_widget.dart
├── constants/               # App constants
└── utils/                   # Utility functions
```

## 🛠️ Technical Stack

### Core Technologies
- **Flutter**: Cross-platform mobile development
- **Dart**: Programming language
- **Provider**: State management
- **Firebase**: Backend services (Firestore, Auth, Storage)

### Key Dependencies
- `provider`: State management
- `firebase_core`: Firebase integration
- `cloud_firestore`: Database
- `json_annotation`: JSON serialization
- `uuid`: Unique ID generation
- `cached_network_image`: Image caching
- `qr_code_scanner`: QR code functionality (future)
- `google_maps_flutter`: Map integration (future)

### Development Tools
- `build_runner`: Code generation
- `json_serializable`: JSON serialization
- `flutter_lints`: Code quality

## 📱 Usage Guide

### Creating Cards

1. **Navigate to Card Editor**: Use the bottom navigation or dashboard
2. **Choose Card Type**: Select from weapon, armor, skill, quest, etc.
3. **Set Basic Properties**: Name, description, rarity, equipment slot
4. **Configure Stats**: Attack, defense, mana cost, durability
5. **Add Modifiers**: Stat bonuses the card provides
6. **Set Conditions**: Requirements to use the card
7. **Add Effects**: What happens when the card is used
8. **Preview & Save**: Use the live preview to verify your card

### Managing Characters

1. **Character Overview**: View stats, level, and equipment on the dashboard
2. **Inventory Management**: Drag and drop items between inventory, stash, and equipment
3. **Stat Allocation**: Spend stat points when leveling up
4. **Equipment**: Drag items to equipment slots to equip them
5. **Real-time Updates**: Stats update immediately when equipment changes

### Inventory System

- **Equipment Slots**: 
  - Helmet, Armor, Weapons (2), Gloves, Boots, Belt
  - Rings (2), Amulet, Active Skills (2)
- **Inventory Grid**: 8x5 grid (40 slots) like Diablo II
- **Stash**: 8x6 grid (48 slots) for storage
- **Drag & Drop**: Move items between all areas
- **Tooltips**: Hover for detailed item information

## 🔧 Configuration

### Firebase Setup (Optional)
1. Create a Firebase project
2. Add your app to the project
3. Download configuration files
4. Uncomment Firebase initialization in `main.dart`

### Customization
- **Themes**: Modify colors in `main.dart`
- **Card Templates**: Add new templates in `CardEditorService`
- **Character Classes**: Extend classes in `character_model.dart`

## 🚧 Future Features

### Low Priority (Planned)
- **QR Code Integration**: Scan physical cards to update digital inventory
- **Adventure Mode**: Story-driven quest system
- **Trading System**: Exchange cards with other players
- **Dueling System**: Player vs Player combat
- **Geo-location Events**: Real-world location-based activities
- **Skill Trees**: Visual skill tree interface
- **Crafting System**: Create new cards from materials

### Advanced Features
- **Real-time Multiplayer**: Live dueling and trading
- **Tournament Mode**: Organized competitions
- **Card Market**: Buy and sell cards with other players
- **Achievement System**: Unlock rewards for milestones
- **Social Features**: Friends, guilds, chat

## 🎯 Development Roadmap

### Phase 1: Core Foundation ✅
- [x] Basic app structure
- [x] Card model and editor
- [x] Character system
- [x] Inventory interface
- [x] Visual theming

### Phase 2: Enhanced Features
- [ ] QR code scanning
- [ ] Firebase integration
- [ ] Adventure mode framework
- [ ] Skill tree visualization

### Phase 3: Multiplayer
- [ ] Trading system
- [ ] Dueling mechanics
- [ ] Real-time synchronization

### Phase 4: Advanced Features
- [ ] Geo-location events
- [ ] Tournament system
- [ ] Social features

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Flutter best practices
- Use Provider for state management
- Write comprehensive comments
- Test on multiple devices
- Maintain the dark whimsical theme

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **Diablo II**: Inspiration for character progression and inventory system
- **Adventure Time**: Inspiration for visual style and whimsical elements
- **Flutter Community**: Excellent documentation and packages
- **Firebase**: Robust backend services

## 📞 Support

For questions, suggestions, or issues:
- Create an issue on GitHub
- Check the documentation
- Review existing issues and discussions

---

**Realm of Valor** - Where dark fantasy meets whimsical adventure! 🎮⚔️✨ 