// lib/theme/app_theme.dart
// ─────────────────────────────────────────────
// Central theme file. All colors, text styles,
// and reusable decoration constants live here.
// Uses Flutter default font (no external fonts).
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const primary     = Color(0xFF1A56DB);
  static const primaryDark = Color(0xFF1240A8);

  // Status
  static const available = Color(0xFF22C55E);
  static const occupied  = Color(0xFFEF4444);
  static const reserved  = Color(0xFFF59E0B);

  // Backgrounds
  static const background = Color(0xFFF8FAFC);
  static const surface    = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFF1F5F9);

  // Text
  static const textPrimary   = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted     = Color(0xFF94A3B8);

  // Borders
  static const border = Color(0xFFE2E8F0);

  // Building colors
  static const buildingAnnex = Color(0xFF6366F1);
  static const buildingMain  = Color(0xFF0EA5E9);
  static const buildingTab   = Color(0xFF10B981);

  static Color getBuildingColor(String building) {
    switch (building) {
      case 'Annex': return buildingAnnex;
      case 'Main':  return buildingMain;
      case 'Tab':   return buildingTab;
      default:      return primary;
    }
  }
}

class AppDecorations {
  AppDecorations._();

  static const cardShadow = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 10,
      offset: Offset(0, 3),
    ),
  ];

  static const smallShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static BoxDecoration card({
    Color? borderColor,
    double borderRadius = 20,
  }) {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor ?? AppColors.border),
      boxShadow: cardShadow,
    );
  }

  static BoxDecoration smallCard({
    Color? borderColor,
    double borderRadius = 16,
  }) {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor ?? AppColors.border),
      boxShadow: smallShadow,
    );
  }

  static BoxDecoration statusBadge(Color color) {
    return BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.4)),
    );
  }

  static BoxDecoration coloredContainer(Color color, {double opacity = 0.08}) {
    return BoxDecoration(
      color: color.withOpacity(opacity),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(opacity * 3)),
    );
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.border,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDim,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.occupied),
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
      ),
    );
  }
}