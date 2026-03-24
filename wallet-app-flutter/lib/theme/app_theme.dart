import 'package:flutter/material.dart';

import 'tokens/app_color_tokens.dart';
import 'tokens/app_radius_tokens.dart';
import 'tokens/app_spacing_tokens.dart';
import 'tokens/app_typography_tokens.dart';

final class AppTheme {
  const AppTheme._();

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColorTokens.background,
      fontFamily: AppTypographyTokens.fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: AppColorTokens.primary,
        secondary: AppColorTokens.accent,
        surface: AppColorTokens.surface,
        error: AppColorTokens.danger,
      ),
    );

    return base.copyWith(
      cardTheme: CardThemeData(
        color: AppColorTokens.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
          side: const BorderSide(color: AppColorTokens.border),
        ),
        margin: const EdgeInsets.all(0),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorTokens.surfaceSubtle,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadiusTokens.md),
          borderSide: const BorderSide(color: AppColorTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadiusTokens.md),
          borderSide: const BorderSide(color: AppColorTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadiusTokens.md),
          borderSide: const BorderSide(color: AppColorTokens.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacingTokens.lg, vertical: AppSpacingTokens.md),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColorTokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
          side: const BorderSide(color: AppColorTokens.border),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: AppTypographyTokens.titleLarge,
        titleMedium: AppTypographyTokens.titleMedium,
        bodyMedium: AppTypographyTokens.body,
        labelMedium: AppTypographyTokens.label,
      ),
    );
  }
}
