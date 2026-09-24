import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'satur_colors.dart';

abstract final class SaturTypography {
  static TextTheme textTheme() {
    final base = GoogleFonts.arimoTextTheme();
    return base.copyWith(
      displayLarge: GoogleFonts.arimo(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 32 / 24,
        letterSpacing: -0.02 * 24,
        color: SaturColors.onSurface,
      ),
      headlineMedium: GoogleFonts.arimo(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 28 / 20,
        color: SaturColors.onSurface,
      ),
      headlineSmall: GoogleFonts.arimo(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 24 / 18,
        color: SaturColors.onSurface,
      ),
      bodyLarge: GoogleFonts.arimo(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: SaturColors.onSurface,
      ),
      bodyMedium: GoogleFonts.arimo(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: SaturColors.onSurface,
      ),
      labelMedium: GoogleFonts.arimo(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 16 / 12,
        letterSpacing: 0.05 * 12,
        color: SaturColors.onSurface,
      ),
    );
  }
}
