import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Brand Colors ────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // Navy palette
  static const Color navy900 = Color(0xFF0A1628);
  static const Color navy800 = Color(0xFF0F2040);
  static const Color navy700 = Color(0xFF162C55);
  static const Color navy600 = Color(0xFF1E3A6E);
  static const Color navy500 = Color(0xFF274D8F);
  static const Color navy400 = Color(0xFF3D6CB5);

  // Solar Gold palette
  static const Color gold500 = Color(0xFFF5A623);
  static const Color gold400 = Color(0xFFF7B84B);
  static const Color gold300 = Color(0xFFF9CA72);
  static const Color gold200 = Color(0xFFFBDC9A);
  static const Color gold100 = Color(0xFFFEF3DC);

  // Accent
  static const Color teal500    = Color(0xFF00C9B1);
  static const Color teal400    = Color(0xFF33D4BF);
  static const Color orange500  = Color(0xFFFF6B35);
  static const Color orange400  = Color(0xFFFF8555);
  static const Color green500   = Color(0xFF22C55E);
  static const Color green400   = Color(0xFF4ADE80);
  static const Color red500     = Color(0xFFEF4444);
  static const Color purple500  = Color(0xFF8B5CF6);

  // Neutral
  static const Color white      = Color(0xFFFFFFFF);
  static const Color grey50     = Color(0xFFF8FAFC);
  static const Color grey100    = Color(0xFFF1F5F9);
  static const Color grey200    = Color(0xFFE2E8F0);
  static const Color grey300    = Color(0xFFCBD5E1);
  static const Color grey400    = Color(0xFF94A3B8);
  static const Color grey500    = Color(0xFF64748B);
  static const Color grey600    = Color(0xFF475569);
  static const Color grey700    = Color(0xFF334155);
  static const Color grey800    = Color(0xFF1E293B);
  static const Color grey900    = Color(0xFF0F172A);

  // Semantic
  static const Color success    = Color(0xFF22C55E);
  static const Color warning    = Color(0xFFF5A623);
  static const Color error      = Color(0xFFEF4444);
  static const Color info       = Color(0xFF3B82F6);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [navy800, navy600],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF5A623), Color(0xFFFF8C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [navy900, navy700, Color(0xFF1A3A6E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A2E50), Color(0xFF162645)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x20FFFFFF), Color(0x08FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─── Text Styles ─────────────────────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get displayLarge => GoogleFonts.outfit(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    letterSpacing: -1.0,
    height: 1.1,
  );

  static TextStyle get displayMedium => GoogleFonts.outfit(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static TextStyle get displaySmall => GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    letterSpacing: -0.3,
  );

  static TextStyle get headlineLarge => GoogleFonts.outfit(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
  );

  static TextStyle get headlineMedium => GoogleFonts.outfit(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  static TextStyle get headlineSmall => GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  static TextStyle get bodyLarge => GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.grey300,
    height: 1.6,
  );

  static TextStyle get bodyMedium => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.grey300,
    height: 1.5,
  );

  static TextStyle get bodySmall => GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.grey400,
    height: 1.4,
  );

  static TextStyle get labelLarge => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    letterSpacing: 0.5,
  );

  static TextStyle get labelMedium => GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.grey300,
    letterSpacing: 0.3,
  );

  static TextStyle get caption => GoogleFonts.outfit(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.grey500,
    letterSpacing: 0.2,
  );
}

// ─── Spacing & Radius ────────────────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();
  static const double xs   = 4;
  static const double sm   = 8;
  static const double md   = 16;
  static const double lg   = 24;
  static const double xl   = 32;
  static const double xxl  = 48;
  static const double xxxl = 64;
}

class AppRadius {
  AppRadius._();
  static const double xs   = 4;
  static const double sm   = 8;
  static const double md   = 12;
  static const double lg   = 16;
  static const double xl   = 20;
  static const double xxl  = 24;
  static const double pill = 100;
}

// ─── App Theme ────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.navy900,
      primaryColor: AppColors.gold500,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold500,
        secondary: AppColors.teal500,
        surface: AppColors.navy800,
        error: AppColors.error,
        onPrimary: AppColors.navy900,
        onSecondary: AppColors.navy900,
        onSurface: AppColors.white,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.navy900,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        titleTextStyle: AppTextStyles.headlineMedium,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.navy800,
        selectedItemColor: AppColors.gold500,
        unselectedItemColor: AppColors.grey500,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.navy700.withValues(alpha: 0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.navy600, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.navy600, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.gold500, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: AppTextStyles.bodyMedium,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        prefixIconColor: AppColors.grey400,
        suffixIconColor: AppColors.grey400,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold500,
          foregroundColor: AppColors.navy900,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(fontSize: 16),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gold500,
          side: const BorderSide(color: AppColors.gold500, width: 1.5),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(fontSize: 16),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.navy800,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: const BorderSide(color: AppColors.navy600, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.navy600,
        thickness: 1,
        space: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.navy700,
        labelStyle: AppTextStyles.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        side: const BorderSide(color: AppColors.navy500),
      ),
    );
  }
}
