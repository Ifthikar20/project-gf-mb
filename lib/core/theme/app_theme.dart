import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_bloc.dart';

/// Clean, minimal design system — Apple-inspired
/// Light mode: pure white, gray surfaces, black text
/// Dark mode: near-black, dark gray surfaces, white text
/// Font: Inter everywhere
class ThemeColors {
  // =============================================
  // LIGHT MODE — Clean white, minimal
  // =============================================
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF5F5F5);
  static const Color lightPrimary = Color(0xFF007AFF); // iOS blue
  static const Color lightSecondary = Color(0xFF5856D6); // iOS purple
  static const Color lightAccent = Color(0xFF22C55E); // Green
  static const Color lightTextPrimary = Color(0xFF000000);
  static const Color lightTextSecondary = Color(0xFF6B7280); // Gray-500
  static const Color lightBorder = Color(0xFFE5E7EB); // Gray-200
  static const Color lightError = Color(0xFFEF4444);

  // =============================================
  // DARK MODE — Near-black, subtle
  // =============================================
  static const Color darkBackground = Color(0xFF0A0A0A);
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color darkPrimary = Color(0xFF0A84FF); // iOS blue dark
  static const Color darkSecondary = Color(0xFF7C3AED);
  static const Color darkAccent = Color(0xFF22C55E);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF9CA3AF); // Gray-400
  static const Color darkBorder = Color(0xFF2C2C2E);
  static const Color darkError = Color(0xFFFF453A); // iOS red

  /// Get colors based on current theme mode
  static Color background(AppThemeMode mode) =>
      mode == AppThemeMode.light ? lightBackground : darkBackground;

  static Color surface(AppThemeMode mode) =>
      mode == AppThemeMode.light ? lightSurface : darkSurface;

  static Color primary(AppThemeMode mode) =>
      mode == AppThemeMode.light ? lightPrimary : darkPrimary;

  static Color secondary(AppThemeMode mode) =>
      mode == AppThemeMode.light ? lightSecondary : darkSecondary;

  static Color accent(AppThemeMode mode) =>
      mode == AppThemeMode.light ? lightAccent : darkAccent;

  static Color textPrimary(AppThemeMode mode) =>
      mode == AppThemeMode.light ? lightTextPrimary : darkTextPrimary;

  static Color textSecondary(AppThemeMode mode) =>
      mode == AppThemeMode.light ? lightTextSecondary : darkTextSecondary;

  static Color border(AppThemeMode mode) =>
      mode == AppThemeMode.light ? lightBorder : darkBorder;

  static Color error(AppThemeMode mode) =>
      mode == AppThemeMode.light ? lightError : darkError;
}

class AppTheme {
  // Shared constants
  static const double cardRadius = 16.0;
  static const double buttonRadius = 12.0;
  static const double inputRadius = 12.0;
  static const double chipRadius = 20.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: ThemeColors.lightPrimary,
      scaffoldBackgroundColor: ThemeColors.lightBackground,

      colorScheme: const ColorScheme.light(
        primary: ThemeColors.lightPrimary,
        secondary: ThemeColors.lightSecondary,
        tertiary: ThemeColors.lightAccent,
        surface: ThemeColors.lightSurface,
        error: ThemeColors.lightError,
        onPrimary: Colors.white,
        onSecondary: ThemeColors.lightTextPrimary,
        onSurface: ThemeColors.lightTextPrimary,
      ),

      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          fontSize: 32, fontWeight: FontWeight.w700, color: ThemeColors.lightTextPrimary,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28, fontWeight: FontWeight.w600, color: ThemeColors.lightTextPrimary,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 24, fontWeight: FontWeight.w600, color: ThemeColors.lightTextPrimary,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20, fontWeight: FontWeight.w600, color: ThemeColors.lightTextPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w600, color: ThemeColors.lightTextPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.normal, color: ThemeColors.lightTextPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.normal, color: ThemeColors.lightTextPrimary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.normal, color: ThemeColors.lightTextSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w500, color: ThemeColors.lightTextPrimary,
        ),
      ),

      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: ThemeColors.lightBackground,
        foregroundColor: ThemeColors.lightTextPrimary,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20, fontWeight: FontWeight.w700, color: ThemeColors.lightTextPrimary,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: ThemeColors.lightBorder, width: 1),
        ),
        color: ThemeColors.lightSurface,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ThemeColors.lightPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ThemeColors.lightTextPrimary,
          side: const BorderSide(color: ThemeColors.lightBorder),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ThemeColors.lightPrimary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: CircleBorder(),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: ThemeColors.lightBackground,
        selectedItemColor: ThemeColors.lightPrimary,
        unselectedItemColor: ThemeColors.lightTextSecondary,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.normal),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ThemeColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: ThemeColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: ThemeColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: ThemeColors.lightPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: ThemeColors.lightError),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: GoogleFonts.inter(color: ThemeColors.lightTextSecondary),
        hintStyle: GoogleFonts.inter(color: ThemeColors.lightTextSecondary),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: ThemeColors.lightSurface,
        selectedColor: ThemeColors.lightPrimary,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(chipRadius),
          side: const BorderSide(color: ThemeColors.lightBorder),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: ThemeColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: ThemeColors.darkPrimary,
      scaffoldBackgroundColor: ThemeColors.darkBackground,

      colorScheme: const ColorScheme.dark(
        primary: ThemeColors.darkPrimary,
        secondary: ThemeColors.darkSecondary,
        tertiary: ThemeColors.darkAccent,
        surface: ThemeColors.darkSurface,
        error: ThemeColors.darkError,
        onPrimary: Colors.white,
        onSecondary: ThemeColors.darkTextPrimary,
        onSurface: ThemeColors.darkTextPrimary,
      ),

      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          fontSize: 32, fontWeight: FontWeight.w700, color: ThemeColors.darkTextPrimary,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28, fontWeight: FontWeight.w600, color: ThemeColors.darkTextPrimary,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 24, fontWeight: FontWeight.w600, color: ThemeColors.darkTextPrimary,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20, fontWeight: FontWeight.w600, color: ThemeColors.darkTextPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w600, color: ThemeColors.darkTextPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.normal, color: ThemeColors.darkTextPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.normal, color: ThemeColors.darkTextPrimary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.normal, color: ThemeColors.darkTextSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w500, color: ThemeColors.darkTextPrimary,
        ),
      ),

      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: ThemeColors.darkBackground,
        foregroundColor: ThemeColors.darkTextPrimary,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20, fontWeight: FontWeight.w700, color: ThemeColors.darkTextPrimary,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: ThemeColors.darkBorder, width: 1),
        ),
        color: ThemeColors.darkSurface,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ThemeColors.darkPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ThemeColors.darkTextPrimary,
          side: const BorderSide(color: ThemeColors.darkBorder),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ThemeColors.darkPrimary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: CircleBorder(),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: ThemeColors.darkBackground,
        selectedItemColor: ThemeColors.darkPrimary,
        unselectedItemColor: ThemeColors.darkTextSecondary,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.normal),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ThemeColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: ThemeColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: ThemeColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: ThemeColors.darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: ThemeColors.darkError),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: GoogleFonts.inter(color: ThemeColors.darkTextSecondary),
        hintStyle: GoogleFonts.inter(color: ThemeColors.darkTextSecondary),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: ThemeColors.darkSurface,
        selectedColor: ThemeColors.darkPrimary,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: ThemeColors.darkTextPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(chipRadius),
          side: const BorderSide(color: ThemeColors.darkBorder),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: ThemeColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
