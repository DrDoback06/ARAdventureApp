# Realm of Valor - Startup & Troubleshooting Guide

## Quick Start

### Option 1: Using Flutter Run (Recommended)
```bash
cd realm_of_valor
flutter run -d chrome --web-port 8080
```

### Option 2: Build and Serve
```bash
cd realm_of_valor
flutter build web
cd build/web
python3 -m http.server 8080
```

Then open your browser to: `http://localhost:8080`

## App Features Overview

### ✅ Fully Implemented Features

1. **Character System**
   - 12 character classes (Paladin, Barbarian, Necromancer, etc.)
   - Diablo II-style stats with equipment bonuses
   - Experience and leveling system
   - Stat/skill point allocation

2. **Inventory Management**
   - Drag-and-drop inventory (8x5 grid)
   - Equipment slots: helmet, armor, weapons, accessories
   - Stash system (8x6 grid)
   - Skill slots on belt (8 slots)

3. **Card Creation System**
   - Visual card editor with real-time preview
   - Support for all card types (weapon, armor, consumable, etc.)
   - Stat modifiers and effects
   - Template system for quick creation

4. **User Interface**
   - Dark whimsical theme
   - Multi-tab navigation (Dashboard, Inventory, Card Editor, Map, Settings)
   - Character creation and switching
   - Real-time stat displays

## Troubleshooting

### App Stuck Loading / Won't Load

**Most Common Causes:**

1. **Missing Dependencies**
   ```bash
   flutter pub get
   flutter pub run build_runner build
   ```

2. **Outdated Flutter**
   ```bash
   flutter upgrade
   flutter clean
   flutter pub get
   ```

3. **Web Build Issues**
   ```bash
   flutter clean
   flutter build web --release
   ```

4. **Browser Cache**
   - Clear browser cache and cookies
   - Try incognito/private browsing mode
   - Try a different browser

### Loading Screen Shows Error

If you see an error message, check:

1. **Console Errors**
   - Open browser DevTools (F12)
   - Check Console tab for errors
   - Look for red error messages

2. **Network Issues**
   - Check if all assets are loading
   - Look for 404 errors in Network tab

### App Loads But Features Don't Work

1. **SharedPreferences Issues**
   - The app uses local storage for data
   - Clear browser data if needed
   - Check if localStorage is enabled

2. **Service Initialization**
   - The app has error handling for service failures
   - Check console for service initialization errors

### Performance Issues

1. **Slow Loading**
   - Use `flutter build web --release` for better performance
   - Enable web renderer: `flutter run -d chrome --web-renderer canvaskit`

2. **Memory Issues**
   - Refresh the browser tab
   - Close other browser tabs
   - Check available system memory

## Development Mode vs Production

### Development Mode
```bash
flutter run -d chrome --web-port 8080
```
- Hot reload enabled
- Debug information available
- Larger bundle size
- Better error messages

### Production Mode
```bash
flutter build web --release
cd build/web
python3 -m http.server 8080
```
- Optimized for performance
- Smaller bundle size
- Better loading times
- Minified code

## Browser Compatibility

### Supported Browsers
- ✅ Chrome (Recommended)
- ✅ Firefox
- ✅ Safari
- ✅ Edge

### Browser Requirements
- JavaScript enabled
- Local storage enabled
- WebGL support (for better graphics)

## App Structure

### Current Implementation Status

```
📁 realm_of_valor/
├── 📁 lib/
│   ├── 📁 constants/
│   │   └── ✅ theme.dart (Dark whimsical theme)
│   ├── 📁 models/
│   │   ├── ✅ card_model.dart (Complete card system)
│   │   └── ✅ character_model.dart (Complete character system)
│   ├── 📁 services/
│   │   ├── ✅ card_service.dart (CRUD, templates, validation)
│   │   └── ✅ character_service.dart (Character management)
│   ├── 📁 providers/
│   │   └── ✅ character_provider.dart (State management)
│   ├── 📁 widgets/
│   │   ├── ✅ card_widget.dart (Card display)
│   │   └── ✅ inventory_widget.dart (Drag-and-drop inventory)
│   ├── 📁 screens/
│   │   ├── ✅ home_screen.dart (Main app interface)
│   │   └── ✅ card_editor_screen.dart (Card creation)
│   └── ✅ main.dart (App initialization with error handling)
```

### Key Components

1. **Models**: Data structures for cards and characters
2. **Services**: Business logic and data persistence
3. **Providers**: State management using Provider pattern
4. **Widgets**: Reusable UI components
5. **Screens**: Main application screens
6. **Constants**: Theme and styling definitions

## Testing the App

### Basic Functionality Test

1. **App Loads**: Should show loading screen then main interface
2. **Character Creation**: Click "Create Character" button
3. **Inventory**: Switch to Inventory tab, drag items around
4. **Card Editor**: Switch to Card Editor tab, create a card
5. **Stats**: View character stats and equipment bonuses

### Expected Behavior

- **Loading**: Shows "Realm of Valor" logo and loading spinner
- **Dashboard**: Character overview with stats and actions
- **Inventory**: Drag-and-drop interface with equipment slots
- **Card Editor**: Form-based editor with real-time preview
- **Theme**: Dark background with gold accents

## Common Issues & Solutions

### Issue: "Failed to load app" Error
**Solution**: Check browser console for specific error messages

### Issue: Cards/Characters Not Saving
**Solution**: Ensure localStorage is enabled in browser settings

### Issue: Drag-and-Drop Not Working
**Solution**: Try refreshing the page, ensure JavaScript is enabled

### Issue: Slow Performance
**Solution**: Use production build, close other browser tabs

### Issue: UI Elements Not Styled Correctly
**Solution**: Clear browser cache, try incognito mode

## Getting Help

### Debug Information
1. Open browser DevTools (F12)
2. Check Console tab for errors
3. Check Network tab for failed requests
4. Check Application tab for localStorage data

### Reporting Issues
Include:
- Browser name and version
- Operating system
- Console error messages
- Steps to reproduce the issue
- Screenshots if applicable

## Next Steps

The app is fully functional with all core features implemented. Future enhancements could include:

- QR code scanning integration
- Firebase backend integration
- Multiplayer features
- Advanced card effects
- Map-based adventures
- Trading system

The foundation is solid and ready for additional features!