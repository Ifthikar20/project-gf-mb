import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme_bloc.dart';

/// Color palettes for different theme modes
class ThemeColors {
  // =============================================
  // VINTAGE (RETRO) THEME COLORS - White & Brown
  // =============================================
  static const Color vintageBackground = Color(0xFFF5F0E8); // Warm off-white
  static const Color vintageSurface = Color(0xFFFAF8F3); // Lighter off-white
  static const Color vintageGold = Color(0xFF8B4513); // Saddle brown
  static const Color vintageBrass = Color(0xFFA0522D); // Sienna
  static const Color vintageCream = Color(0xFF1A1A1A); // Black text
  static const Color vintageTan = Color(0xFF4A4A4A); // Dark gray for secondary text
  static const Color dustyRose = Color(0xFFA67C52); // Warm brown
  static const Color sageGreen = Color(0xFF5D7D5D); // Muted green
  static const Color vintageRed = Color(0xFF8B3A3A); // Muted red
  static const Color vintageBorder = Color(0xFFD4C5B0); // Light tan border

  // =============================================
  // CLASSIC DARK THEME COLORS (Original)
  // =============================================
  static const Color classicBackground = Color(0xFF0A0A0A);
  static const Color classicSurface = Color(0xFF1A1A1A);
  static const Color classicPrimary = Color(0xFF1DB954); // Green
  static const Color classicSecondary = Color(0xFF7C3AED); // Purple
  static const Color classicAccent = Color(0xFFF4A261);
  static const Color classicTextPrimary = Color(0xFFFFFFFF);
  static const Color classicTextSecondary = Color(0xFFB3B3B3);
  static const Color classicBlue = Color(0xFF448AFF);
  static const Color classicRed = Color(0xFFFF2D55);
  static const Color classicOrange = Color(0xFFFF6B35);

  /// Get colors based on current theme mode
  static Color background(AppThemeMode mode) => 
      mode == AppThemeMode.vintage ? vintageBackground : classicBackground;
  
  static Color surface(AppThemeMode mode) => 
      mode == AppThemeMode.vintage ? vintageSurface : classicSurface;
  
  static Color primary(AppThemeMode mode) => 
      mode == AppThemeMode.vintage ? vintageGold : classicPrimary;
  
  static Color secondary(AppThemeMode mode) => 
      mode == AppThemeMode.vintage ? dustyRose : classicSecondary;
  
  static Color accent(AppThemeMode mode) => 
      mode == AppThemeMode.vintage ? sageGreen : classicAccent;
  
  static Color textPrimary(AppThemeMode mode) => 
      mode == AppThemeMode.vintage ? vintageCream : classicTextPrimary;
  
  static Color textSecondary(AppThemeMode mode) => 
      mode == AppThemeMode.vintage ? vintageTan : classicTextSecondary;
  
  static Color error(AppThemeMode mode) => 
      mode == AppThemeMode.vintage ? vintageRed : classicRed;
}

class AppTheme {
  // Wellness-focused color palette (for light theme if needed)
  static const Color primaryColor = Color(0xFFB8860B); // Antique gold
  static const Color secondaryColor = Color(0xFFC9A9A6); // Dusty rose
  static const Color accentColor = Color(0xFF9CAF88); // Sage green
  static const Color backgroundColor = Color(0xFFF8F4E8); // Warm cream/ivory
  static const Color surfaceColor = Color(0xFFFFFDF5); // Light ivory
  static const Color errorColor = Color(0xFFA65D57); // Muted vintage red
  
  // Dark theme colors (warm sepia)
  static const Color darkBackgroundColor = Color(0xFF2A1F15);
  static const Color darkSurfaceColor = Color(0xFF3D2914);
  
  // Text colors
  static const Color textPrimaryLight = Color(0xFF3D2914);
  static const Color textSecondaryLight = Color(0xFF6B5B4F);
  static const Color textPrimaryDark = Color(0xFFF8F4E8);
  static const Color textSecondaryDark = Color(0xFFD4C5B0);

  // Vintage accent colors
  static const Color vintageGold = Color(0xFFA67C52);
  static const Color vintageBorder = Color(0xFFD4C5B0);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: surfaceColor,
        background: backgroundColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: textPrimaryLight,
        onSurface: textPrimaryLight,
        onBackground: textPrimaryLight,
      ),
      
      textTheme: TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimaryLight,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textPrimaryLight,
        ),
        displaySmall: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimaryLight,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryLight,
        ),
        titleLarge: GoogleFonts.playfairDisplay(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: textPrimaryLight,
        ),
        bodyLarge: GoogleFonts.lora(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimaryLight,
        ),
        bodyMedium: GoogleFonts.lora(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textPrimaryLight,
        ),
        bodySmall: GoogleFonts.lora(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textSecondaryLight,
        ),
        labelLarge: GoogleFonts.lora(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimaryLight,
        ),
      ),
      
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: surfaceColor,
        foregroundColor: textPrimaryLight,
        centerTitle: true,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryLight,
        ),
      ),
      
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: vintageBorder, width: 1),
        ),
        color: surfaceColor,
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.lora(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondaryLight,
        selectedLabelStyle: GoogleFonts.lora(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.lora(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: vintageBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: vintageBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: GoogleFonts.lora(color: textSecondaryLight),
        hintStyle: GoogleFonts.lora(color: textSecondaryLight),
      ),
      
      chipTheme: ChipThemeData(
        backgroundColor: backgroundColor,
        selectedColor: primaryColor,
        labelStyle: GoogleFonts.lora(fontSize: 14),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: vintageBorder),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBackgroundColor,
      
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: darkSurfaceColor,
        background: darkBackgroundColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: textPrimaryDark,
        onSurface: textPrimaryDark,
        onBackground: textPrimaryDark,
      ),
      
      textTheme: TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimaryDark,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
        ),
        displaySmall: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
        ),
        titleLarge: GoogleFonts.playfairDisplay(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: textPrimaryDark,
        ),
        bodyLarge: GoogleFonts.lora(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimaryDark,
        ),
        bodyMedium: GoogleFonts.lora(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textPrimaryDark,
        ),
        bodySmall: GoogleFonts.lora(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textSecondaryDark,
        ),
        labelLarge: GoogleFonts.lora(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimaryDark,
        ),
      ),
      
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: darkSurfaceColor,
        foregroundColor: textPrimaryDark,
        centerTitle: true,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
        ),
      ),
      
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: vintageGold.withOpacity(0.3), width: 1),
        ),
        color: darkSurfaceColor,
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.lora(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondaryDark,
        selectedLabelStyle: GoogleFonts.lora(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.lora(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkBackgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: vintageGold.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: vintageGold.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: GoogleFonts.lora(color: textSecondaryDark),
        hintStyle: GoogleFonts.lora(color: textSecondaryDark),
      ),
      
      chipTheme: ChipThemeData(
        backgroundColor: darkBackgroundColor,
        selectedColor: primaryColor,
        labelStyle: GoogleFonts.lora(fontSize: 14, color: textPrimaryDark),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: vintageGold.withOpacity(0.3)),
        ),
      ),
    );
  }
}
