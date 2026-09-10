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
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? FreshSproutColors.darkBackground
            : FreshSproutColors.surfaceContainerLowest,
        border: isDarkMode
            ? Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              )
            : null,
        boxShadow: isDarkMode
            ? FreshSproutElevation.bottomNavDark
            : FreshSproutElevation.bottomNav,
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

              if (selected && isDarkMode) {
                return _DarkActiveNavItem(
                  icon: icon,
                  label: item.$3,
                  onTap: () => onChanged(index),
                );
              }

              if (selected && !isDarkMode) {
                return _LightActiveNavItem(
                  icon: icon,
                  label: item.$3,
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
    );
  }
}

class _LightActiveNavItem extends StatelessWidget {
  const _LightActiveNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FreshSproutColors.secondaryContainer,
      borderRadius: FreshSproutRadius.fullBorder,
      child: InkWell(
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
              Icon(
                icon,
                size: 24,
                color: FreshSproutColors.onSecondaryContainer,
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: FreshSproutColors.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DarkActiveNavItem extends StatelessWidget {
  const _DarkActiveNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FreshSproutColors.primaryContainer,
      borderRadius: FreshSproutRadius.fullBorder,
      child: InkWell(
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
              Icon(
                icon,
                size: 24,
                color: FreshSproutColors.onPrimaryContainer,
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: FreshSproutColors.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
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
        ? FreshSproutColors.darkTextMuted
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
