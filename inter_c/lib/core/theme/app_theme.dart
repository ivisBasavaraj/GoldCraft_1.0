import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: GoldCraftColors.jewelryGold,
      onPrimary: GoldCraftColors.pureWhite,
      primaryContainer: GoldCraftColors.jewelryGoldLight,
      onPrimaryContainer: GoldCraftColors.jewelryGoldDark,
      secondary: GoldCraftColors.charcoal,
      onSecondary: GoldCraftColors.pureWhite,
      secondaryContainer: GoldCraftColors.divider,
      onSecondaryContainer: GoldCraftColors.charcoal,
      error: GoldCraftColors.softRedText,
      onError: GoldCraftColors.pureWhite,
      errorContainer: GoldCraftColors.softRed,
      onErrorContainer: GoldCraftColors.softRedText,
      surface: GoldCraftColors.surface,
      onSurface: GoldCraftColors.charcoal,
      surfaceContainerHighest: GoldCraftColors.warmIvory,
      onSurfaceVariant: GoldCraftColors.textSecondary,
      outline: GoldCraftColors.border,
      outlineVariant: GoldCraftColors.divider,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: GoldCraftColors.background,
      textTheme: GoldCraftTypography.textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: GoldCraftColors.pureWhite,
        foregroundColor: GoldCraftColors.charcoal,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: GoldCraftColors.shadowMedium,
        centerTitle: false,
        titleTextStyle: GoldCraftTypography.textTheme.headlineSmall,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: GoldCraftColors.pureWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: GoldCraftColors.divider),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GoldCraftColors.jewelryGold,
          foregroundColor: GoldCraftColors.pureWhite,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoldCraftTypography.textTheme.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: GoldCraftColors.jewelryGold,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: const BorderSide(color: GoldCraftColors.jewelryGold, width: 1.5),
          textStyle: GoldCraftTypography.textTheme.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: GoldCraftColors.jewelryGold,
          textStyle: GoldCraftTypography.textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GoldCraftColors.warmIvory,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GoldCraftColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GoldCraftColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GoldCraftColors.jewelryGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GoldCraftColors.softRedText),
        ),
        labelStyle: GoldCraftTypography.textTheme.bodyMedium?.copyWith(
          color: GoldCraftColors.textSecondary,
        ),
        hintStyle: GoldCraftTypography.textTheme.bodyMedium?.copyWith(
          color: GoldCraftColors.textHint,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: GoldCraftColors.divider,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: GoldCraftColors.warmIvory,
        selectedColor: GoldCraftColors.jewelryGoldLight,
        labelStyle: GoldCraftTypography.textTheme.labelMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: GoldCraftColors.border),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: GoldCraftColors.pureWhite,
        selectedItemColor: GoldCraftColors.jewelryGold,
        unselectedItemColor: GoldCraftColors.textHint,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: GoldCraftColors.pureWhite,
        selectedIconTheme: IconThemeData(color: GoldCraftColors.jewelryGold),
        unselectedIconTheme: IconThemeData(color: GoldCraftColors.textHint),
        indicatorColor: GoldCraftColors.jewelryGoldLight,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: GoldCraftColors.charcoal,
        contentTextStyle: GoldCraftTypography.textTheme.bodyMedium?.copyWith(
          color: GoldCraftColors.pureWhite,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: GoldCraftColors.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoldCraftTypography.textTheme.headlineSmall,
        contentTextStyle: GoldCraftTypography.textTheme.bodyMedium,
      ),
    );
  }
}
