import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// TerraTrack Agriculture Theme
/// Earthy greens, warm ambers, soil browns — evoking fields, crops and land.
class AppColors {
  AppColors._();

  // --- Primary palette: deep field green ---
  static const Color primaryDark = Color(0xFF1B4332);
  static const Color primary = Color(0xFF2D6A4F);
  static const Color primaryLight = Color(0xFF40916C);
  static const Color primaryLighter = Color(0xFF74C69D);
  static const Color primarySurface = Color(0xFFD8F3DC);

  // --- Secondary: harvest amber ---
  static const Color secondaryDark = Color(0xFF7B4B00);
  static const Color secondary = Color(0xFFB37400);
  static const Color secondaryLight = Color(0xFFE09B2D);
  static const Color secondarySurface = Color(0xFFFFF3CD);

  // --- Accent: terracotta / soil ---
  static const Color accentDark = Color(0xFF7C3F2A);
  static const Color accent = Color(0xFFBC6C42);
  static const Color accentLight = Color(0xFFD4956A);
  static const Color accentSurface = Color(0xFFF5E6DA);

  // --- Semantic ---
  static const Color success = Color(0xFF2D6A4F);
  static const Color successSurface = Color(0xFFD8F3DC);
  static const Color warning = Color(0xFFB37400);
  static const Color warningSurface = Color(0xFFFFF3CD);
  static const Color error = Color(0xFFC0392B);
  static const Color errorSurface = Color(0xFFFDEDED);
  static const Color info = Color(0xFF1A6B8A);
  static const Color infoSurface = Color(0xFFD4EEF7);

  // --- Neutrals ---
  static const Color black = Color(0xFF1A1A1A);
  static const Color grey900 = Color(0xFF2C2C2C);
  static const Color grey700 = Color(0xFF4A4A4A);
  static const Color grey500 = Color(0xFF7A7A7A);
  static const Color grey300 = Color(0xFFB0B0B0);
  static const Color grey200 = Color(0xFFD8D8D8);
  static const Color grey100 = Color(0xFFF4F4F0);
  static const Color white = Color(0xFFFFFFFF);

  // --- Surface tones (parchment-like for agriculture) ---
  static const Color surface = Color(0xFFF8F5EE);
  static const Color surfaceVariant = Color(0xFFF0EAD6);
  static const Color background = Color(0xFFF5F0E8);

  // --- Dark theme ---
  static const Color darkBackground = Color(0xFF0F1F16);
  static const Color darkSurface = Color(0xFF1A3024);
  static const Color darkSurfaceVariant = Color(0xFF22402F);
  static const Color darkBorder = Color(0xFF2D5038);
}

class AppTheme {
  AppTheme._();

  static TextTheme _buildTextTheme(double fontScale) {
    final base = GoogleFonts.poppinsTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontSize: 57 * fontScale),
      displayMedium: base.displayMedium?.copyWith(fontSize: 45 * fontScale),
      displaySmall: base.displaySmall?.copyWith(fontSize: 36 * fontScale),
      headlineLarge: base.headlineLarge?.copyWith(fontSize: 32 * fontScale, fontWeight: FontWeight.w600),
      headlineMedium: base.headlineMedium?.copyWith(fontSize: 28 * fontScale, fontWeight: FontWeight.w600),
      headlineSmall: base.headlineSmall?.copyWith(fontSize: 24 * fontScale, fontWeight: FontWeight.w600),
      titleLarge: base.titleLarge?.copyWith(fontSize: 22 * fontScale, fontWeight: FontWeight.w600),
      titleMedium: base.titleMedium?.copyWith(fontSize: 16 * fontScale, fontWeight: FontWeight.w500),
      titleSmall: base.titleSmall?.copyWith(fontSize: 14 * fontScale, fontWeight: FontWeight.w500),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 16 * fontScale),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 14 * fontScale),
      bodySmall: base.bodySmall?.copyWith(fontSize: 12 * fontScale),
      labelLarge: base.labelLarge?.copyWith(fontSize: 14 * fontScale, fontWeight: FontWeight.w600),
      labelMedium: base.labelMedium?.copyWith(fontSize: 12 * fontScale, fontWeight: FontWeight.w500),
      labelSmall: base.labelSmall?.copyWith(fontSize: 11 * fontScale),
    );
  }

  static ThemeData lightTheme(double fontScale) {
    final textTheme = _buildTextTheme(fontScale);
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.primarySurface,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.secondary,
      onSecondary: AppColors.white,
      secondaryContainer: AppColors.secondarySurface,
      onSecondaryContainer: AppColors.secondaryDark,
      tertiary: AppColors.accent,
      onTertiary: AppColors.white,
      tertiaryContainer: AppColors.accentSurface,
      onTertiaryContainer: AppColors.accentDark,
      error: AppColors.error,
      onError: AppColors.white,
      errorContainer: AppColors.errorSurface,
      onErrorContainer: AppColors.error,
      surface: AppColors.surface,
      onSurface: AppColors.black,
      surfaceContainerHighest: AppColors.surfaceVariant,
      onSurfaceVariant: AppColors.grey700,
      outline: AppColors.grey300,
      outlineVariant: AppColors.grey200,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.background,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: AppColors.white),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),

      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.grey200, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.grey300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.grey200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.grey500),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.grey300),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: textTheme.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: textTheme.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey300,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.grey100,
        labelStyle: textTheme.labelSmall,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.grey200,
        thickness: 0.5,
        space: 0,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 4,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.grey900,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData darkTheme(double fontScale) {
    final textTheme = _buildTextTheme(fontScale);
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryLighter,
      onPrimary: AppColors.primaryDark,
      primaryContainer: AppColors.primaryDark,
      onPrimaryContainer: AppColors.primarySurface,
      secondary: AppColors.secondaryLight,
      onSecondary: AppColors.secondaryDark,
      secondaryContainer: AppColors.secondaryDark,
      onSecondaryContainer: AppColors.secondarySurface,
      tertiary: AppColors.accentLight,
      onTertiary: AppColors.accentDark,
      tertiaryContainer: AppColors.accentDark,
      onTertiaryContainer: AppColors.accentSurface,
      error: Color(0xFFFF6B6B),
      onError: AppColors.black,
      errorContainer: AppColors.error,
      onErrorContainer: AppColors.white,
      surface: AppColors.darkSurface,
      onSurface: AppColors.white,
      surfaceContainerHighest: AppColors.darkSurfaceVariant,
      onSurfaceVariant: AppColors.grey200,
      outline: AppColors.darkBorder,
      outlineVariant: AppColors.darkSurfaceVariant,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme.apply(
        bodyColor: AppColors.white,
        displayColor: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.white,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: AppColors.white),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder, width: 0.5),
        ),
      ),
    );
  }
}
