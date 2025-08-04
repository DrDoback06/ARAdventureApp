import 'package:flutter/material.dart';
import '../models/card_model.dart' show CardRarity;

class RealmOfValorTheme {
  // Primary Colors - Dark whimsical theme
  static const Color primaryDark = Color(0xFF1A1A1A);
  static const Color primaryMedium = Color(0xFF2D2D2D);
  static const Color primaryLight = Color(0xFF404040);
  
  // Accent Colors - Amber/Gold with magical touches
  static const Color accentGold = Color(0xFFFFB300);
  static const Color accentAmber = Color(0xFFFFC107);
  static const Color accentLightGold = Color(0xFFFFD54F);
  
  // Rarity Colors
  static const Color rarityCommon = Color(0xFFBDBDBD);
  static const Color rarityUncommon = Color(0xFF4CAF50);
  static const Color rarityRare = Color(0xFF2196F3);
  static const Color rarityEpic = Color(0xFF9C27B0);
  static const Color rarityLegendary = Color(0xFFFF9800);
  static const Color rarityMythic = Color(0xFFE91E63);
  
  // UI Colors
  static const Color surfaceDark = Color(0xFF121212);
  static const Color surfaceMedium = Color(0xFF1E1E1E);
  static const Color surfaceLight = Color(0xFF2C2C2C);
  
  // Text Colors
  static const Color textPrimary = Color(0xFFE0E0E0);
  static const Color textSecondary = Color(0xFFBDBDBD);
  static const Color textAccent = Color(0xFFFFB300);
  
  // Status Colors
  static const Color healthRed = Color(0xFFE53935);
  static const Color manaBlue = Color(0xFF1E88E5);
  static const Color experienceGreen = Color(0xFF43A047);
  
  // Gothic/Whimsical accents
  static const Color mysticPurple = Color(0xFF7B1FA2);
  static const Color shadowBlack = Color(0xFF000000);
  static const Color moonSilver = Color(0xFFCFD8DC);
  
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.amber,
      primaryColor: accentGold,
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: accentGold,
        secondary: accentAmber,
        surface: surfaceDark,
        onPrimary: primaryDark,
        onSecondary: primaryDark,
        onSurface: textPrimary,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: primaryDark,
      
      // App Bar
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryMedium,
        foregroundColor: textPrimary,
        elevation: 4,
        shadowColor: shadowBlack,
        titleTextStyle: TextStyle(
          color: accentGold,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      // Card Theme
      cardTheme: const CardTheme(
        color: surfaceMedium,
        elevation: 8,
        shadowColor: shadowBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      
      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGold,
          foregroundColor: primaryDark,
          elevation: 6,
          shadowColor: shadowBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentGold,
          side: const BorderSide(color: accentGold, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accentGold),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accentGold, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          color: accentGold,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: accentGold,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          color: accentGold,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: textPrimary,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: textSecondary,
          fontSize: 12,
        ),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: accentGold,
        size: 24,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: primaryLight,
        thickness: 1,
      ),
      
      // Tab Bar Theme
      tabBarTheme: const TabBarTheme(
        labelColor: accentGold,
        unselectedLabelColor: textSecondary,
        indicatorColor: accentGold,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      
      // Drawer Theme
      drawerTheme: const DrawerThemeData(
        backgroundColor: primaryMedium,
        elevation: 16,
        shadowColor: shadowBlack,
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: primaryMedium,
        selectedItemColor: accentGold,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentGold,
        foregroundColor: primaryDark,
        elevation: 8,
        highlightElevation: 12,
      ),
      
      // Dialog Theme
      dialogTheme: const DialogTheme(
        backgroundColor: surfaceMedium,
        elevation: 24,
        shadowColor: shadowBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      
      // Tooltip Theme
      tooltipTheme: const TooltipThemeData(
        decoration: BoxDecoration(
          color: surfaceLight,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        textStyle: TextStyle(
          color: textPrimary,
          fontSize: 12,
        ),
      ),
    );
  }
  
  // Helper methods for rarity colors
  static Color getRarityColor(dynamic rarity) {
    String rarityString;
    if (rarity is CardRarity) {
      rarityString = rarity.name;
    } else {
      rarityString = rarity.toString();
    }
    
    switch (rarityString.toLowerCase()) {
      case 'common':
        return rarityCommon;
      case 'uncommon':
        return rarityUncommon;
      case 'rare':
        return rarityRare;
      case 'epic':
        return rarityEpic;
      case 'legendary':
        return rarityLegendary;
      case 'mythic':
        return rarityMythic;
      default:
        return rarityCommon;
    }
  }
  
  // Custom decorations
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: surfaceMedium,
    borderRadius: BorderRadius.circular(12),
    boxShadow: const [
      BoxShadow(
        color: shadowBlack,
        blurRadius: 8,
        offset: Offset(0, 4),
      ),
    ],
  );
  
  static BoxDecoration get inventorySlotDecoration => BoxDecoration(
    color: surfaceLight,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: primaryLight, width: 1),
  );
  
  static BoxDecoration get equipmentSlotDecoration => BoxDecoration(
    color: surfaceDark,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: accentGold, width: 2),
  );
  
  static BoxDecoration rarityCardDecoration(dynamic rarity) => BoxDecoration(
    color: surfaceMedium,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: getRarityColor(rarity), width: 2),
    boxShadow: [
      BoxShadow(
        color: getRarityColor(rarity).withOpacity(0.3),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
  
  // Gradient decorations
  static const LinearGradient goldGradient = LinearGradient(
    colors: [accentGold, accentLightGold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient darkGradient = LinearGradient(
    colors: [primaryDark, primaryMedium],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient mysticGradient = LinearGradient(
    colors: [mysticPurple, accentGold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}