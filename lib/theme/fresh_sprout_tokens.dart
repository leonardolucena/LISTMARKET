import 'package:flutter/material.dart';

/// Fresh Sprout design system tokens.
class FreshSproutColors {
  FreshSproutColors._();

  // Surfaces
  static const surface = Color(0xFFF4FBF4);
  static const surfaceDim = Color(0xFFD4DCD5);
  static const surfaceBright = Color(0xFFF4FBF4);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFEEF5EF);
  static const surfaceContainer = Color(0xFFE8F0E9);
  static const surfaceContainerHigh = Color(0xFFE3EAE3);
  static const surfaceContainerHighest = Color(0xFFDDE4DE);
  static const surfaceVariant = Color(0xFFDDE4DE);

  // Content
  static const onSurface = Color(0xFF161D19);
  static const onSurfaceVariant = Color(0xFF3E4942);
  static const inverseSurface = Color(0xFF2B322E);
  static const inverseOnSurface = Color(0xFFEBF3EC);

  // Outline
  static const outline = Color(0xFF6E7A72);
  static const outlineVariant = Color(0xFFBDCAC0);
  static const borderSubtle = Color(0xFFEAEFE9);
  static const borderInput = Color(0xFFDCE6DF);
  static const checkboxBorder = Color(0xFFC8D7CE);

  // Primary
  static const primary = Color(0xFF006745);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF0D8259);
  static const onPrimaryContainer = Color(0xFFE3FFED);
  static const inversePrimary = Color(0xFF77DAAA);
  static const surfaceTint = Color(0xFF006C49);

  // Secondary
  static const secondary = Color(0xFF006C47);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFF7EFABC);
  static const onSecondaryContainer = Color(0xFF00734B);
  static const secondaryFixedDim = Color(0xFF60DDA2);

  // Tertiary
  static const tertiary = Color(0xFF914300);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFFB05A1C);
  static const onTertiaryContainer = Color(0xFFFFF6F3);

  // Error
  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  // Fixed roles
  static const primaryFixed = Color(0xFF93F6C4);
  static const primaryFixedDim = Color(0xFF77DAAA);
  static const secondaryFixed = Color(0xFF7EFABC);
  static const tertiaryFixed = Color(0xFFFFDBC8);
  static const tertiaryFixedDim = Color(0xFFFFB68B);

  // Background
  static const background = Color(0xFFF4FBF4);
  static const onBackground = Color(0xFF161D19);

  // Brand semantics (marketing / UI accents)
  static const brandEmerald = Color(0xFF0D8259);
  static const brandMint = Color(0xFF48C78E);
  static const brandTangerine = Color(0xFFF08C4A);
  static const brandObsidian = Color(0xFF1B221E);
  static const mutedText = Color(0xFF526058);
  static const progressTrack = Color(0xFFEBF2ED);
  static const shadowTint = Color(0xFF0D3B28);

  // Dark theme (Fresh Sprout profile v2)
  static const darkBackground = Color(0xFF191D2D);
  static const darkSurface = Color(0xFF23283A);
  static const darkSurfaceElevated = Color(0xFF2A3045);
  static const darkCard = darkSurface;
  static const darkBorder = Color(0xFF34394B);
  static const darkBorderLight = Color(0xFF42485E);
  static const darkAccent = Color(0xFFF1A410);
  static const darkAccentHover = Color(0xFFDF9407);
  static const darkAccentGreen = Color(0xFF10B981);
  static const darkAccentGreenLight = Color(0xFF34D399);
  static const darkAccentGreenDark = Color(0xFF059669);
  static const darkTextPrimary = Color(0xFFFFFFFF);
  static const darkTextMuted = Color(0xFF94A3B8);
  static const darkTextSecondary = Color(0xFFCBD5E1);
  static const darkSurfaceHover = Color(0xFF34394B);
  static const darkProgressTrack = Color(0xFF2A3045);

  // Aliases
  static const darkSurfaceHigh = darkSurfaceElevated;
  static const darkSurfaceHighest = darkBorder;
  static const darkOnSurface = darkTextPrimary;
  static const darkOnSurfaceVariant = darkTextMuted;
  static const darkOutline = darkBorder;
  static const darkPrimary = darkAccent;
  static const darkOnPrimary = Color(0xFF191D2D);
  static const darkPrimaryContainer = darkAccent;
  static const darkSecondary = darkAccent;
  static const darkTertiary = darkAccent;
}

class FreshSproutRadius {
  FreshSproutRadius._();

  static const sm = 4.0;
  static const md = 8.0;
  static const lg = 12.0;
  static const xl = 16.0;
  static const xxl = 24.0;
  static const full = 9999.0;

  static BorderRadius get smBorder => BorderRadius.circular(sm);
  static BorderRadius get mdBorder => BorderRadius.circular(md);
  static BorderRadius get lgBorder => BorderRadius.circular(lg);
  static BorderRadius get xlBorder => BorderRadius.circular(xl);
  static BorderRadius get xxlBorder => BorderRadius.circular(xxl);
  static BorderRadius get fullBorder => BorderRadius.circular(full);
}

class FreshSproutSpacing {
  FreshSproutSpacing._();

  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const marginMobile = 16.0;
  static const marginTablet = 24.0;
  static const gutter = 16.0;
  static const touchTarget = 48.0;
  static const chipHeight = 32.0;
}

class FreshSproutElevation {
  FreshSproutElevation._();

  static List<BoxShadow> get level1 => [
        BoxShadow(
          color: FreshSproutColors.shadowTint.withValues(alpha: 0.05),
          blurRadius: 8,
          spreadRadius: -2,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: FreshSproutColors.shadowTint.withValues(alpha: 0.03),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get level2 => [
        BoxShadow(
          color: FreshSproutColors.brandEmerald.withValues(alpha: 0.16),
          blurRadius: 20,
          spreadRadius: -4,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: FreshSproutColors.shadowTint.withValues(alpha: 0.06),
          blurRadius: 6,
          spreadRadius: -2,
          offset: const Offset(0, 3),
        ),
      ];

  /// HTML: shadow-ambient-emerald
  static List<BoxShadow> get ambientEmerald => [
        BoxShadow(
          color: FreshSproutColors.shadowTint.withValues(alpha: 0.07),
          blurRadius: 20,
          spreadRadius: -2,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: FreshSproutColors.shadowTint.withValues(alpha: 0.04),
          blurRadius: 6,
          spreadRadius: -1,
          offset: const Offset(0, 2),
        ),
      ];

  /// HTML: shadow-fab-emerald
  static List<BoxShadow> get fabEmerald => [
        BoxShadow(
          color: FreshSproutColors.primaryContainer.withValues(alpha: 0.28),
          blurRadius: 24,
          spreadRadius: -4,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: FreshSproutColors.shadowTint.withValues(alpha: 0.08),
          blurRadius: 8,
          spreadRadius: -2,
          offset: const Offset(0, 4),
        ),
      ];

  /// HTML: bottom nav top shadow (light)
  static List<BoxShadow> get bottomNav => [
        BoxShadow(
          color: FreshSproutColors.shadowTint.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, -2),
        ),
      ];

  /// HTML: dark bottom nav shadow
  static List<BoxShadow> get bottomNavDark => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 20,
          offset: const Offset(0, -4),
        ),
      ];

  /// HTML: dark .shadow-fab-emerald
  static List<BoxShadow> get fabAmber => [
        BoxShadow(
          color: FreshSproutColors.darkAccent.withValues(alpha: 0.35),
          blurRadius: 24,
          spreadRadius: -4,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 8,
          spreadRadius: -2,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get level3 => [
        BoxShadow(
          color: FreshSproutColors.brandObsidian.withValues(alpha: 0.14),
          blurRadius: 32,
          spreadRadius: -8,
          offset: const Offset(0, 20),
        ),
      ];
}

/// Card decoration following Fresh Sprout level-1 elevation.
class FreshSproutDecorations {
  FreshSproutDecorations._();

  static BoxDecoration card({Color? color, BorderRadius? borderRadius}) {
    return BoxDecoration(
      color: color ?? FreshSproutColors.surfaceContainerLowest,
      borderRadius: borderRadius ?? FreshSproutRadius.xlBorder,
      border: Border.all(color: FreshSproutColors.borderSubtle),
      boxShadow: FreshSproutElevation.level1,
    );
  }

  static BoxDecoration heroSummary({required bool isDark}) {
    if (isDark) {
      return BoxDecoration(
        borderRadius: FreshSproutRadius.xxlBorder,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A3045),
            Color(0xFF1E2336),
            Color(0xFF171B2B),
          ],
        ),
        border: Border.all(
          color: FreshSproutColors.darkBorder.withValues(alpha: 0.6),
        ),
        boxShadow: FreshSproutElevation.ambientEmerald,
      );
    }

    return BoxDecoration(
      borderRadius: FreshSproutRadius.xxlBorder,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          FreshSproutColors.primaryContainer,
          Color(0xFF0B6E4B),
          Color(0xFF064E35),
        ],
      ),
      border: Border.all(
        color: FreshSproutColors.outlineVariant.withValues(alpha: 0.5),
      ),
      boxShadow: FreshSproutElevation.ambientEmerald,
    );
  }
}

/// Gradient progress bar per Fresh Sprout spec.
class FreshSproutProgressBar extends StatelessWidget {
  const FreshSproutProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.trackColor,
    this.fillColor,
    this.gradient,
    this.isDark = false,
  });

  final double value;
  final double height;
  final Color? trackColor;
  final Color? fillColor;
  final Gradient? gradient;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final track = trackColor ??
        (isDark
            ? Colors.black.withValues(alpha: 0.4)
            : FreshSproutColors.surfaceContainer);
    final fill = fillColor ??
        (isDark ? FreshSproutColors.darkAccent : FreshSproutColors.primary);
    final fillGradient = gradient ??
        (fillColor != null
            ? null
            : isDark
                ? LinearGradient(
                    colors: [
                      FreshSproutColors.darkAccent.withValues(alpha: 0.8),
                      FreshSproutColors.darkAccent,
                    ],
                  )
                : const LinearGradient(
                    colors: [
                      FreshSproutColors.secondaryFixedDim,
                      FreshSproutColors.secondaryFixed,
                    ],
                  ));

    return ClipRRect(
      borderRadius: FreshSproutRadius.fullBorder,
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: track),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0, 1),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: fillGradient,
                  color: fillGradient == null ? fill : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
