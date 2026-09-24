import 'package:flutter/material.dart';

import 'satur_colors.dart';
import 'satur_typography.dart';

abstract final class SaturTheme {
  static ThemeData light() {
    final textTheme = SaturTypography.textTheme();
    final colorScheme = ColorScheme.light(
      primary: SaturColors.primary,
      onPrimary: SaturColors.onPrimary,
      primaryContainer: SaturColors.primaryContainer,
      secondary: SaturColors.secondary,
      onSecondary: SaturColors.onPrimary,
      secondaryContainer: SaturColors.secondaryContainer,
      surface: SaturColors.surface,
      onSurface: SaturColors.onSurface,
      onSurfaceVariant: SaturColors.onSurfaceVariant,
      error: SaturColors.error,
      outline: SaturColors.outline,
      outlineVariant: SaturColors.outlineVariant,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: SaturColors.surfaceContainerLowest,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: SaturColors.surfaceContainerLowest,
        foregroundColor: SaturColors.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.headlineSmall,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: SaturColors.primary,
          foregroundColor: SaturColors.onPrimary,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: textTheme.headlineSmall?.copyWith(
            color: SaturColors.onPrimary,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SaturColors.primary,
          minimumSize: const Size.fromHeight(48),
          side: BorderSide(color: SaturColors.primary.withValues(alpha: 0.2)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: textTheme.headlineSmall?.copyWith(
            color: SaturColors.primary,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SaturColors.surfaceGray,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SaturColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SaturColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SaturColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SaturColors.error),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: SaturColors.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
