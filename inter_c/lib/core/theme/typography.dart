import 'package:flutter/material.dart';
import 'colors.dart';

class GoldCraftTypography {
  GoldCraftTypography._();

  static const String _fontFamily = 'Inter';

  static TextTheme get textTheme => const TextTheme(
        // Display — large headings
        displayLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: GoldCraftColors.charcoal,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: GoldCraftColors.charcoal,
          letterSpacing: -0.3,
        ),
        // Headlines
        headlineLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: GoldCraftColors.charcoal,
        ),
        headlineMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: GoldCraftColors.charcoal,
        ),
        headlineSmall: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: GoldCraftColors.charcoal,
        ),
        // Titles
        titleLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: GoldCraftColors.charcoal,
        ),
        titleMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: GoldCraftColors.charcoal,
        ),
        titleSmall: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: GoldCraftColors.charcoal,
        ),
        // Body
        bodyLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: GoldCraftColors.charcoal,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: GoldCraftColors.charcoal,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: GoldCraftColors.textSecondary,
          height: 1.4,
        ),
        // Labels
        labelLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        labelMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
        labelSmall: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: GoldCraftColors.textSecondary,
        ),
      );
}
