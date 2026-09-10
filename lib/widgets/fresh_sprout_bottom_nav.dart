import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/fresh_sprout_tokens.dart';

class FreshSproutBottomNav extends StatelessWidget {
  const FreshSproutBottomNav({
    super.key,
    required this.isDarkMode,
    required this.currentIndex,
    required this.onChanged,
  });

  final bool isDarkMode;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  static const _items = [
    (Icons.format_list_bulleted, Icons.format_list_bulleted, 'Listas'),
    (Icons.receipt_long_outlined, Icons.receipt_long, 'Histórico'),
    (Icons.pie_chart_outline, Icons.pie_chart, 'Orçamento'),
    (Icons.person_outline, Icons.person, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? FreshSproutColors.darkBackground.withValues(alpha: 0.95)
                : FreshSproutColors.surfaceContainerLowest,
            border: Border(
              top: BorderSide(
                color: isDarkMode
                    ? FreshSproutColors.darkBorder.withValues(alpha: 0.8)
                    : FreshSproutColors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withValues(alpha: 0.4)
                    : FreshSproutColors.shadowTint.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FreshSproutSpacing.marginMobile,
                vertical: FreshSproutSpacing.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_items.length, (index) {
                  final item = _items[index];
                  final selected = currentIndex == index;
                  final icon = selected ? item.$2 : item.$1;

                  if (selected) {
                    return _ActiveNavItem(
                      icon: icon,
                      label: item.$3,
                      isDarkMode: isDarkMode,
                      onTap: () => onChanged(index),
                    );
                  }

                  return _NavItem(
                    icon: icon,
                    label: item.$3,
                    isDarkMode: isDarkMode,
                    onTap: () => onChanged(index),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveNavItem extends StatelessWidget {
  const _ActiveNavItem({
    required this.icon,
    required this.label,
    required this.isDarkMode,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isDarkMode;
  final VoidCallback onTap;

  static const _emeraldGradient = LinearGradient(
    colors: [
      Color(0xFF0D8259),
      Color(0xFF10A370),
    ],
  );

  static const _darkEmeraldGradient = LinearGradient(
    colors: [
      Color(0xFF059669),
      Color(0xFF10B981),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: FreshSproutRadius.fullBorder,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: FreshSproutRadius.fullBorder,
            gradient: isDarkMode ? _darkEmeraldGradient : _emeraldGradient,
            boxShadow: [
              BoxShadow(
                color: FreshSproutColors.brandEmerald.withValues(
                  alpha: isDarkMode ? 0.35 : 0.25,
                ),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: onTap,
            splashColor: Colors.white24,
            highlightColor: Colors.white12,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FreshSproutSpacing.md,
                vertical: FreshSproutSpacing.xxs,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: Colors.white,
                  ),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isDarkMode,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isDarkMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final inactive = isDarkMode
        ? const Color(0xFF94A3B8)
        : FreshSproutColors.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: FreshSproutRadius.fullBorder,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FreshSproutSpacing.md,
          vertical: FreshSproutSpacing.xxs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: inactive),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: inactive,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
