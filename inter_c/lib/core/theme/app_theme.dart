import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: GoldCraftColors.workshopGreen,
      onPrimary: GoldCraftColors.pureWhite,
      primaryContainer: GoldCraftColors.workshopGreenLight,
      onPrimaryContainer: GoldCraftColors.workshopGreenDark,
      secondary: GoldCraftColors.jewelryGold,
      onSecondary: GoldCraftColors.charcoal,
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
        backgroundColor: GoldCraftColors.background,
        foregroundColor: GoldCraftColors.charcoal,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: GoldCraftColors.shadowMedium,
        centerTitle: false,
        titleTextStyle: GoldCraftTypography.textTheme.headlineSmall,
        iconTheme:
            const IconThemeData(color: GoldCraftColors.workshopGreenDark),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: GoldCraftColors.pureWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: GoldCraftColors.divider),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GoldCraftColors.workshopGreen,
          foregroundColor: GoldCraftColors.pureWhite,
          minimumSize: const Size(double.infinity, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: GoldCraftTypography.textTheme.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: GoldCraftColors.workshopGreen,
          minimumSize: const Size(double.infinity, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          side: const BorderSide(
              color: GoldCraftColors.workshopGreen, width: 1.5),
          textStyle: GoldCraftTypography.textTheme.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: GoldCraftColors.workshopGreen,
          foregroundColor: GoldCraftColors.pureWhite,
          minimumSize: const Size(double.infinity, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: GoldCraftTypography.textTheme.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: GoldCraftColors.workshopGreenDark,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: GoldCraftColors.workshopGreen,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: GoldCraftColors.workshopGreen,
          textStyle: GoldCraftTypography.textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GoldCraftColors.warmIvory,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          borderSide:
              const BorderSide(color: GoldCraftColors.workshopGreen, width: 2),
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
        selectedColor: GoldCraftColors.workshopGreenLight,
        labelStyle: GoldCraftTypography.textTheme.labelMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: GoldCraftColors.border),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: GoldCraftColors.pureWhite,
        selectedItemColor: GoldCraftColors.workshopGreen,
        unselectedItemColor: GoldCraftColors.textHint,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: GoldCraftColors.pureWhite,
        selectedIconTheme: IconThemeData(color: GoldCraftColors.workshopGreen),
        unselectedIconTheme: IconThemeData(color: GoldCraftColors.textHint),
        indicatorColor: GoldCraftColors.workshopGreenLight,
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
