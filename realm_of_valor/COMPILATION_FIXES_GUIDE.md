# 🔧 Compilation Fixes Guide

The following compilation errors need to be fixed:

## 1. ✅ **Import Conflicts Fixed**
- ✅ Removed duplicate `Quest` import from `location_verification_service.dart`

## 2. ⚠️ **StatBoost Duration Parameter Issue**

**Problem**: `StatBoost` constructor doesn't have `duration` parameter, it uses `expiresAt`.

**Files to fix**: `lib/services/fitness_tracker_service.dart`

**Fix**: Replace all `duration: const Duration(...)` with `expiresAt: DateTime.now().add(const Duration(...))`

**Lines to fix**:
- Line 465: `duration: const Duration(minutes: 30)` → `expiresAt: DateTime.now().add(const Duration(minutes: 30))`
- Line 481: `duration: const Duration(hours: 1)` → `expiresAt: DateTime.now().add(const Duration(hours: 1))`  
- Line 491: `duration: const Duration(hours: 1)` → `expiresAt: DateTime.now().add(const Duration(hours: 1))`
- Line 504: `duration: const Duration(minutes: 45)` → `expiresAt: DateTime.now().add(const Duration(minutes: 45))`
- Line 572: `duration: const Duration(hours: 24)` → `expiresAt: DateTime.now().add(const Duration(hours: 24))`
- Line 581: `duration: const Duration(hours: 24)` → `expiresAt: DateTime.now().add(const Duration(hours: 24))`
- Line 593: `duration: const Duration(hours: 24)` → `expiresAt: DateTime.now().add(const Duration(hours: 24))`
- Line 605: `duration: const Duration(hours: 24)` → `expiresAt: DateTime.now().add(const Duration(hours: 24))`
- Line 661: `duration: const Duration(days: 7)` → `expiresAt: DateTime.now().add(const Duration(days: 7))`
- Line 670: `duration: const Duration(days: 7)` → `expiresAt: DateTime.now().add(const Duration(days: 7))`

## 3. ✅ **Character Properties Fixed**
- ✅ Fixed character stat access to use `allocatedStrength`, `allocatedDexterity`, etc.

## 4. ⚠️ **QuestProgressOverlay Fix Needed**

**Problem**: Using wrong Quest model and syntax error.

**File**: `lib/widgets/quest_progress_overlay.dart`

**Fix**: 
1. Remove `quest_model.dart` import
2. Use only `adventure_system.dart` Quest model
3. Fix the completion dialog syntax

**Required changes**:
```dart
// Remove this import:
// import '../models/quest_model.dart';

// Keep only:
import '../models/adventure_system.dart';

// Fix line ~392 - remove broken conditional
const Text('+100 XP', style: TextStyle(...))
```

## 5. ⚠️ **Quest Model Conflict**

**Problem**: Two different `Quest` classes cause conflicts.

**Solution**: Use only `adventure_system.dart` Quest model throughout the app.

**Files to update**:
- `lib/screens/home_screen.dart` - Update mock quest creation
- `lib/widgets/quest_progress_overlay.dart` - Remove quest_model import

## 🚀 **Quick Fix Commands**

### Fix StatBoost Duration Parameters:
```bash
# Replace all duration parameters (run in realm_of_valor directory)
find lib -name "*.dart" -exec sed -i 's/duration: const Duration(/expiresAt: DateTime.now().add(const Duration(/g' {} \;
```

### Fix Quest Model Imports:
```bash
# Remove quest_model imports where adventure_system is already imported
grep -l "adventure_system.dart" lib/**/*.dart | xargs sed -i '/quest_model.dart/d'
```

## 🎯 **Expected Result**

After these fixes:
- ✅ No compilation errors
- ✅ GPS quest tracking works
- ✅ Fitness tracker integration functional
- ✅ Real-time quest progress overlay displays correctly

## 🔧 **Manual Fix Priority**

1. **High Priority**: Fix StatBoost duration parameters (prevents compilation)
2. **High Priority**: Fix QuestProgressOverlay syntax error
3. **Medium Priority**: Standardize Quest model usage
4. **Low Priority**: Update mock data to match new models

Once these are fixed, the Adventure Mode will be fully functional with GPS tracking! 