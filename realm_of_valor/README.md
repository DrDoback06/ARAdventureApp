# Realm of Valor

A hybrid card-based RPG Flutter app that combines Diablo II's gritty mechanics with Adventure Time's whimsical style. The app serves dual purposes: enhancing physical card gameplay through QR code integration and providing standalone digital gameplay.

## 🎮 Game Concept

**Setting**: Dark whimsical fantasy world  
**Classes**: 12 characters across Holy, Chaos, and Arcane classes with complementary synergies  
**Mechanics**: Turn-based combat, quests, PvP/PvM encounters, character progression  
**Integration**: Physical cards with QR codes update digital inventory and trigger events

## ✨ Features Implemented

### High Priority Features ✅

#### 1. **Card Creator/Editor**
- **Visual Editor**: Robust card creation without coding
- **Card Types**: Item, quest, adventure, skill, weapon, armor, accessory, consumable, spell
- **Stat Modifiers**: Complex stat bonuses with percentage and flat values
- **Conditions & Effects**: Configurable card conditions and effects
- **Visual Customization**: Rarity-based color coding and visual feedback
- **Real-time Preview**: Live card preview while editing
- **Templates**: Save and load card templates for quick creation
- **Validation**: Comprehensive form validation with error feedback

#### 2. **Character System**
- **Diablo II-inspired Stats**: Strength, Dexterity, Vitality, Energy
- **Skill Trees**: Character progression with skill points
- **Equipment Integration**: Real-time stat calculations with equipment bonuses
- **12 Character Classes**: Paladin, Barbarian, Necromancer, Sorceress, Amazon, Assassin, Druid, Monk, Crusader, Witch Doctor, Wizard, Demon Hunter
- **Leveling System**: Experience-based progression with stat/skill point allocation

#### 3. **Drag & Drop Inventory**
- **Diablo II-style Interface**: Familiar equipment layout
- **Equipment Slots**: Helmet, armor, weapons (1&2), gloves, boots, belt, rings (2), amulet
- **Inventory Grid**: 8x5 inventory with drag-and-drop functionality
- **Stash System**: 8x6 stash for item storage
- **Skill Slots**: Belt-based skill slot system
- **Real-time Updates**: Live stat calculations when equipment changes

### Technical Implementation ⚙️

#### **Project Architecture**
- **Framework**: Flutter with cross-platform support
- **State Management**: Provider pattern for reactive UI
- **Data Persistence**: SharedPreferences for local storage
- **JSON Serialization**: Automated with build_runner

#### **Core Models**
- **GameCard**: Comprehensive card model with stats, effects, conditions
- **CardInstance**: Player-owned card instances with durability and quantity
- **GameCharacter**: Complete character model with equipment and progression
- **Equipment**: Equipment management with all slot types
- **Skill**: Skill system with prerequisites and bonuses

#### **Services**
- **CardService**: Full CRUD operations, validation, templates, import/export
- **CharacterService**: Character management, equipment, inventory, progression

#### **UI Components**
- **CardWidget**: Visual card display with rarity colors and tooltips
- **InventoryWidget**: Drag-and-drop interface with equipment management
- **CardEditorScreen**: Comprehensive visual card editor
- **HomeScreen**: Multi-tab interface with dashboard and quick actions

#### **Theme System**
- **Dark Whimsical Theme**: Gothic elements with playful highlights
- **Color Scheme**: Dark backgrounds with amber/gold accents
- **Rarity System**: Color-coded rarity (Common to Mythic)
- **Professional UI**: Tooltips, validation feedback, visual indicators

### Current Features 🎯

#### **Dashboard**
- Character overview with stats and progression
- Quick actions (Add XP, Add Items, QR Scanner)
- Character switching and creation
- Recent activity tracking

#### **Inventory Management**
- Full drag-and-drop inventory system
- Equipment slots with visual feedback
- Stash management with item transfer
- Real-time stat calculations
- Item tooltips and detailed views

#### **Card Editor**
- Visual card creation with real-time preview
- All card types and properties supported
- Stat modifier system
- Template management
- Import/export functionality
- Comprehensive validation

#### **Character Progression**
- Experience and leveling system
- Stat point allocation
- Skill progression (framework ready)
- Equipment bonuses and calculations

### Low Priority Features (Future Development) 🚀

- **QR Code Integration**: Physical card scanning and recognition
- **Adventure Modes**: Deck-based adventure gameplay
- **Trading System**: Player-to-player card trading
- **Dueling System**: Real-time PvP combat
- **Geo-location Events**: Location-based gameplay using Google Maps
- **Firebase Integration**: Cloud save and multiplayer features

## 🛠️ Installation & Setup

### Prerequisites
- Flutter SDK (3.5.4+)
- Dart SDK
- Android Studio / VS Code
- Git

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd realm_of_valor
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Building for Production

#### Web
```bash
flutter build web
```

#### Android
```bash
flutter build apk --release
```

#### iOS
```bash
flutter build ios --release
```

## 📱 Usage Guide

### Creating Your First Character
1. Launch the app
2. Tap "Create Character" on the welcome screen
3. Enter character name and select class
4. Start your adventure!

### Managing Inventory
1. Navigate to the Inventory tab
2. Drag items between inventory slots
3. Equip items by dragging to equipment slots
4. View item details with long press or tap
5. Transfer items to stash for storage

### Creating Cards
1. Go to the Card Editor tab
2. Fill in basic card information
3. Add stat modifiers, effects, and conditions
4. Preview your card in real-time
5. Save or export your creation

### Character Progression
1. Gain experience through gameplay
2. Allocate stat points when leveling up
3. Learn and upgrade skills
4. Equip better gear for stat bonuses

## 🏗️ Technical Stack

### Core Dependencies
- **flutter**: Cross-platform UI framework
- **provider**: State management
- **shared_preferences**: Local data storage
- **json_annotation**: JSON serialization
- **uuid**: Unique ID generation

### Development Dependencies
- **build_runner**: Code generation
- **json_serializable**: JSON code generation
- **flutter_lints**: Code quality

### Future Integrations
- **firebase_core**: Backend services
- **qr_code_scanner**: QR code functionality
- **google_maps_flutter**: Location features
- **cached_network_image**: Image optimization

## 🎨 Design Philosophy

### Dark Whimsical Aesthetic
- **Color Palette**: Dark backgrounds with golden accents
- **Typography**: Clear, readable fonts with gothic influences
- **Icons**: Thematic icons that fit the fantasy setting
- **Animations**: Smooth transitions and visual feedback

### User Experience
- **Intuitive Navigation**: Bottom navigation with clear sections
- **Drag & Drop**: Natural item management
- **Real-time Feedback**: Immediate visual responses
- **Comprehensive Tooltips**: Helpful information throughout

## 🔧 Development Roadmap

### Phase 1: Core Functionality ✅ COMPLETE
- Basic character system
- Inventory management
- Card creation system
- Local data persistence

### Phase 2: Enhanced Features (Next)
- QR code scanning
- Advanced skill trees
- Combat system
- Achievement system

### Phase 3: Multiplayer Features (Future)
- Firebase integration
- Real-time trading
- PvP dueling
- Leaderboards

### Phase 4: Advanced Features (Future)
- Geo-location events
- Advanced quest system
- Guild system
- Tournament mode

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Inspired by Diablo II's character progression system
- UI/UX influenced by Adventure Time's whimsical aesthetic
- Flutter community for excellent documentation and packages

---

**Realm of Valor** - Where dark fantasy meets whimsical adventure! 🗡️✨
