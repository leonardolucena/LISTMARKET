import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'fresh_sprout_tokens.dart';

/// Backward-compatible aliases used across screens.
class AppColors {
  AppColors._();

  static const lightPrimary = FreshSproutColors.primaryContainer;
  static const lightSecondary = FreshSproutColors.brandMint;
  static const lightAccent = FreshSproutColors.brandTangerine;
  static const lightOnSurface = FreshSproutColors.onSurface;
  static const lightBackground = FreshSproutColors.background;

  static const darkBackground = FreshSproutColors.darkBackground;
  static const darkSurface = FreshSproutColors.darkCard;
  static const darkAccent = FreshSproutColors.darkAccent;
  static const darkOnHigh = FreshSproutColors.darkTextPrimary;
  static const darkOnMuted = FreshSproutColors.darkTextMuted;
}

class AppTheme {
  AppTheme._();

  static const _tabularNums = [FontFeature.tabularFigures()];

  static ThemeData get light => _buildTheme(
        brightness: Brightness.light,
        scheme: _lightScheme,
      );

  static ThemeData get dark => _buildTheme(
        brightness: Brightness.dark,
        scheme: _darkScheme,
      );

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: FreshSproutColors.primary,
    onPrimary: FreshSproutColors.onPrimary,
    primaryContainer: FreshSproutColors.primaryContainer,
    onPrimaryContainer: FreshSproutColors.onPrimaryContainer,
    secondary: FreshSproutColors.secondary,
    onSecondary: FreshSproutColors.onSecondary,
    secondaryContainer: FreshSproutColors.secondaryContainer,
    onSecondaryContainer: FreshSproutColors.onSecondaryContainer,
    tertiary: FreshSproutColors.tertiary,
    onTertiary: FreshSproutColors.onTertiary,
    tertiaryContainer: FreshSproutColors.tertiaryContainer,
    onTertiaryContainer: FreshSproutColors.onTertiaryContainer,
    error: FreshSproutColors.error,
    onError: FreshSproutColors.onError,
    errorContainer: FreshSproutColors.errorContainer,
    onErrorContainer: FreshSproutColors.onErrorContainer,
    surface: FreshSproutColors.surface,
    onSurface: FreshSproutColors.onSurface,
    onSurfaceVariant: FreshSproutColors.onSurfaceVariant,
    outline: FreshSproutColors.outline,
    outlineVariant: FreshSproutColors.outlineVariant,
    shadow: FreshSproutColors.shadowTint,
    scrim: FreshSproutColors.brandObsidian,
    inverseSurface: FreshSproutColors.inverseSurface,
    onInverseSurface: FreshSproutColors.inverseOnSurface,
    inversePrimary: FreshSproutColors.inversePrimary,
    surfaceTint: FreshSproutColors.surfaceTint,
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: FreshSproutColors.darkAccent,
    onPrimary: FreshSproutColors.darkOnPrimary,
    primaryContainer: FreshSproutColors.darkAccent,
    onPrimaryContainer: FreshSproutColors.darkOnPrimary,
    secondary: FreshSproutColors.darkAccent,
    onSecondary: FreshSproutColors.darkOnPrimary,
    secondaryContainer: FreshSproutColors.darkCard,
    onSecondaryContainer: FreshSproutColors.darkAccent,
    tertiary: FreshSproutColors.darkAccent,
    onTertiary: FreshSproutColors.darkOnPrimary,
    tertiaryContainer: FreshSproutColors.darkCard,
    onTertiaryContainer: FreshSproutColors.darkTextSecondary,
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    surface: FreshSproutColors.darkBackground,
    onSurface: FreshSproutColors.darkTextPrimary,
    onSurfaceVariant: FreshSproutColors.darkTextMuted,
    outline: FreshSproutColors.darkBorder,
    outlineVariant: FreshSproutColors.darkBorder,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: FreshSproutColors.darkTextPrimary,
    onInverseSurface: FreshSproutColors.darkBackground,
    inversePrimary: FreshSproutColors.primaryContainer,
    surfaceTint: FreshSproutColors.darkAccent,
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required ColorScheme scheme,
  }) {
    final isDark = brightness == Brightness.dark;
    final textTheme = _textTheme(scheme);
    final buttonShape = RoundedRectangleBorder(
      borderRadius: FreshSproutRadius.xlBorder,
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        titleTextStyle: textTheme.headlineMedium,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark
            ? FreshSproutColors.darkAccent
            : FreshSproutColors.primaryContainer,
        foregroundColor: isDark
            ? FreshSproutColors.darkBackground
            : FreshSproutColors.onPrimary,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: FreshSproutRadius.xlBorder),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: isDark
              ? FreshSproutColors.darkAccent
              : FreshSproutColors.primaryContainer,
          foregroundColor: isDark
              ? FreshSproutColors.darkBackground
              : FreshSproutColors.onPrimary,
          minimumSize: const Size(0, FreshSproutSpacing.touchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: FreshSproutSpacing.md,
            vertical: 14,
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark
              ? FreshSproutColors.darkAccent
              : FreshSproutColors.primaryContainer,
          minimumSize: const Size(0, FreshSproutSpacing.touchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: FreshSproutSpacing.md,
            vertical: 14,
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: buttonShape,
          side: BorderSide(
            color: isDark
                ? FreshSproutColors.darkAccent
                : FreshSproutColors.primaryContainer,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark
              ? FreshSproutColors.darkAccent
              : FreshSproutColors.primaryContainer,
          textStyle: textTheme.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? FreshSproutColors.darkSurfaceHigh
            : FreshSproutColors.surfaceContainerLow,
        selectedColor: FreshSproutColors.primaryContainer,
        checkmarkColor: FreshSproutColors.onPrimary,
        labelStyle: textTheme.labelMedium!.copyWith(
          color: scheme.onSurface,
        ),
        secondaryLabelStyle: textTheme.labelMedium!.copyWith(
          color: FreshSproutColors.onPrimary,
        ),
        side: BorderSide(
          color: scheme.outline.withValues(alpha: isDark ? 0.35 : 0.25),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: FreshSproutRadius.fullBorder,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      cardTheme: CardThemeData(
        color: isDark
            ? FreshSproutColors.darkSurfaceHigh
            : FreshSproutColors.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: FreshSproutRadius.xlBorder,
          side: BorderSide(
            color: isDark
                ? FreshSproutColors.darkOutline.withValues(alpha: 0.2)
                : FreshSproutColors.borderSubtle,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? FreshSproutColors.darkSurfaceHigh
            : FreshSproutColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: FreshSproutSpacing.md,
          vertical: FreshSproutSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: FreshSproutRadius.lgBorder,
          borderSide: const BorderSide(color: FreshSproutColors.borderInput),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: FreshSproutRadius.lgBorder,
          borderSide: const BorderSide(color: FreshSproutColors.borderInput),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: FreshSproutRadius.lgBorder,
          borderSide: const BorderSide(
            color: FreshSproutColors.primaryContainer,
            width: 1.5,
          ),
        ),
        focusColor: FreshSproutColors.brandMint.withValues(alpha: 0.2),
        labelStyle: textTheme.bodyMedium,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return FreshSproutColors.brandMint;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(FreshSproutColors.onPrimary),
        side: const BorderSide(color: FreshSproutColors.checkboxBorder, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: FreshSproutRadius.mdBorder),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: FreshSproutColors.brandMint,
        linearTrackColor: FreshSproutColors.progressTrack,
        borderRadius: FreshSproutRadius.fullBorder,
        linearMinHeight: 8,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: FreshSproutRadius.lgBorder),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark
            ? FreshSproutColors.darkSurfaceHigh
            : FreshSproutColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: FreshSproutRadius.xxlBorder),
        elevation: 0,
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    final base = GoogleFonts.plusJakartaSansTextTheme().apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    TextStyle styled(
      TextStyle? style, {
      required double size,
      required FontWeight weight,
      required double height,
      double letterSpacing = 0,
      Color? color,
      List<FontFeature>? features,
    }) {
      return (style ?? const TextStyle()).copyWith(
        fontSize: size,
        fontWeight: weight,
        height: height / size,
        letterSpacing: letterSpacing,
        color: color ?? scheme.onSurface,
        fontFeatures: features,
      );
    }

    return TextTheme(
      displayLarge: styled(
        base.displayLarge,
        size: 32,
        weight: FontWeight.w700,
        height: 38,
        letterSpacing: -0.64,
      ),
      displayMedium: styled(
        base.displayMedium,
        size: 32,
        weight: FontWeight.w700,
        height: 38,
        letterSpacing: -0.64,
      ),
      headlineLarge: styled(
        base.headlineLarge,
        size: 28,
        weight: FontWeight.w600,
        height: 34,
        letterSpacing: -0.42,
        features: _tabularNums,
      ),
      headlineMedium: styled(
        base.headlineMedium,
        size: 22,
        weight: FontWeight.w600,
        height: 28,
        letterSpacing: -0.22,
        features: _tabularNums,
      ),
      headlineSmall: styled(
        base.headlineSmall,
        size: 18,
        weight: FontWeight.w600,
        height: 24,
      ),
      titleLarge: styled(
        base.titleLarge,
        size: 22,
        weight: FontWeight.w600,
        height: 28,
        letterSpacing: -0.22,
      ),
      titleMedium: styled(
        base.titleMedium,
        size: 18,
        weight: FontWeight.w600,
        height: 24,
      ),
      titleSmall: styled(
        base.titleSmall,
        size: 16,
        weight: FontWeight.w600,
        height: 24,
      ),
      bodyLarge: styled(
        base.bodyLarge,
        size: 16,
        weight: FontWeight.w400,
        height: 24,
      ),
      bodyMedium: styled(
        base.bodyMedium,
        size: 14,
        weight: FontWeight.w400,
        height: 20,
      ),
      bodySmall: styled(
        base.bodySmall,
        size: 12,
        weight: FontWeight.w400,
        height: 16,
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: styled(
        base.labelLarge,
        size: 14,
        weight: FontWeight.w600,
        height: 18,
        letterSpacing: 0.14,
      ),
      labelMedium: styled(
        base.labelMedium,
        size: 12,
        weight: FontWeight.w600,
        height: 16,
        letterSpacing: 0.24,
        color: scheme.onSurfaceVariant,
      ),
      labelSmall: styled(
        base.labelSmall,
        size: 10,
        weight: FontWeight.w700,
        height: 14,
        letterSpacing: 0.4,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
