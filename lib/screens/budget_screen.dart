import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/shopping_list.dart';
import '../services/shopping_list_repository.dart';
import '../theme/fresh_sprout_tokens.dart';
import '../utils/date_formatter.dart';

const _monthLong = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

abstract final class _BudgetSpec {
  static final cardRadius = FreshSproutRadius.lgBorder;
  static final buttonRadius = FreshSproutRadius.mdBorder;
  static const iconBtnSize = 40.0;
  static const avatarSize = 40.0;
  static const monthNavSize = 36.0;
  static const categoryIconSize = 40.0;
  static const storeIconSize = 32.0;
  static const tipIconSize = 36.0;
  static const monthlyBudget = 2000.0;

  /// space-md — gap entre seções principais
  static const sectionGap = FreshSproutSpacing.md;
  /// space-xs — gap dentro de blocos (cards, listas)
  static const blockGap = FreshSproutSpacing.xs;
  /// space-xxs — gap mínimo (labels, chips)
  static const tightGap = FreshSproutSpacing.xxs;
  /// p-space-md — padding padrão de cards
  static const cardPadding = FreshSproutSpacing.md;
  /// p-space-sm — padding compacto de cards
  static const cardPaddingSm = FreshSproutSpacing.sm;
}

/// Tipografia alinhada ao HTML Fresh Sprout (Orçamento).
abstract final class _BudgetTypography {
  static TextStyle headlineSm(
    BuildContext context, {
    Color? color,
    FontWeight fontWeight = FontWeight.w600,
  }) =>
      Theme.of(context).textTheme.headlineSmall!.copyWith(
            fontSize: 18,
            height: 24 / 18,
            fontWeight: fontWeight,
            color: color,
          );

  static TextStyle headlineLg(
    BuildContext context, {
    Color? color,
    FontWeight fontWeight = FontWeight.w700,
  }) =>
      Theme.of(context).textTheme.headlineLarge!.copyWith(
            fontSize: 28,
            height: 34 / 28,
            fontWeight: fontWeight,
            letterSpacing: -0.56,
            color: color,
          );

  static TextStyle labelLg(
    BuildContext context, {
    Color? color,
    FontWeight fontWeight = FontWeight.w600,
  }) =>
      Theme.of(context).textTheme.labelLarge!.copyWith(
            fontSize: 14,
            height: 18 / 14,
            fontWeight: fontWeight,
            letterSpacing: 0.14,
            color: color,
          );

  static TextStyle labelMd(
    BuildContext context, {
    Color? color,
    FontWeight fontWeight = FontWeight.w600,
  }) =>
      Theme.of(context).textTheme.labelMedium!.copyWith(
            fontSize: 12,
            height: 16 / 12,
            fontWeight: fontWeight,
            letterSpacing: 0.24,
            color: color,
          );

  static TextStyle labelSm(
    BuildContext context, {
    Color? color,
    FontWeight fontWeight = FontWeight.w700,
  }) =>
      Theme.of(context).textTheme.labelSmall!.copyWith(
            fontSize: 10,
            height: 14 / 10,
            fontWeight: fontWeight,
            letterSpacing: 0.4,
            color: color,
          );

  static TextStyle bodyMd(
    BuildContext context, {
    Color? color,
    FontWeight fontWeight = FontWeight.w400,
  }) =>
      Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: fontWeight,
            color: color,
          );

  static TextStyle bodySm(
    BuildContext context, {
    Color? color,
    FontWeight fontWeight = FontWeight.w400,
  }) =>
      Theme.of(context).textTheme.bodySmall!.copyWith(
            fontSize: 12,
            height: 16 / 12,
            fontWeight: fontWeight,
            color: color,
          );
}

class _CategoryBudget {
  const _CategoryBudget({
    required this.name,
    required this.icon,
    required this.limit,
    required this.spent,
    required this.iconBackground,
    required this.iconColor,
    required this.barColor,
    this.badge,
  });

  final String name;
  final IconData icon;
  final double limit;
  final double spent;
  final Color iconBackground;
  final Color iconColor;
  final Color barColor;
  final String? badge;

  double get ratio => limit == 0 ? 0 : (spent / limit).clamp(0, 1);
  int get percent => (ratio * 100).round();
  double get remaining => (limit - spent).clamp(0, double.infinity);
}

class _StoreSummary {
  const _StoreSummary({
    required this.name,
    required this.icon,
    required this.purchases,
    required this.total,
    required this.share,
    required this.subtitle,
  });

  final String name;
  final IconData icon;
  final int purchases;
  final double total;
  final double share;
  final String subtitle;
}

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key, required this.isDarkMode});

  final bool isDarkMode;

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _repository = ShoppingListRepository.instance;
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  List<ShoppingList> get _allLists => _repository.getAllLists();

  List<ShoppingList> get _monthLists {
    return _allLists.where((list) {
      final date = list.updatedAt;
      return date.year == _selectedMonth.year &&
          date.month == _selectedMonth.month;
    }).toList();
  }

  double get _monthSpent =>
      _monthLists.fold(0.0, (sum, list) => sum + list.totalValue);

  double get _remainingCeiling =>
      (_BudgetSpec.monthlyBudget - _monthSpent).clamp(0, double.infinity);

  double get _consumedRatio =>
      (_monthSpent / _BudgetSpec.monthlyBudget).clamp(0.0, 1.0);

  int get _consumedPercent => (_consumedRatio * 100).round();

  int get _daysInMonth =>
      DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month);

  int get _currentDay {
    final now = DateTime.now();
    if (now.year == _selectedMonth.year && now.month == _selectedMonth.month) {
      return now.day;
    }
    return _daysInMonth;
  }

  int get _weekOfMonth => ((_currentDay - 1) / 7).floor() + 1;

  double get _dailyAverage =>
      _currentDay == 0 ? 0 : _monthSpent / _currentDay;

  double get _safeDaily =>
      _remainingCeiling / (_daysInMonth - _currentDay).clamp(1, 999);

  double get _projectedTotal {
    if (_currentDay == 0) return _monthSpent;
    return (_monthSpent / _currentDay) * _daysInMonth;
  }

  double get _projectedSavings =>
      _BudgetSpec.monthlyBudget - _projectedTotal;

  void _shiftMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
      );
    });
  }

  String _monthLabel(DateTime date) => _monthLong[date.month - 1];

  String _monthYearLabel(DateTime date) =>
      '${_monthLong[date.month - 1]} de ${date.year}';

  List<_CategoryBudget> _buildCategories(bool isDark) {
    final total = _monthSpent;
    const limits = [1000.0, 400.0, 350.0, 250.0];
    const shares = [0.52, 0.20, 0.16, 0.12];
    final spent = List.generate(4, (i) => total * shares[i]);

    if (total == 0) {
      return [
        _CategoryBudget(
          name: 'Supermercado & Despensa',
          icon: Icons.shopping_basket_outlined,
          limit: limits[0],
          spent: 742.30,
          iconBackground: FreshSproutColors.secondaryContainer.withValues(
            alpha: isDark ? 0.25 : 0.4,
          ),
          iconColor: FreshSproutColors.secondary,
          barColor: FreshSproutColors.primary,
        ),
        _CategoryBudget(
          name: 'Hortifruti & Feira',
          icon: Icons.eco_outlined,
          limit: limits[1],
          spent: 282.90,
          iconBackground: FreshSproutColors.primaryFixed.withValues(alpha: 0.4),
          iconColor: FreshSproutColors.primary,
          barColor: FreshSproutColors.primaryContainer,
        ),
        _CategoryBudget(
          name: 'Açougue & Peixaria',
          icon: Icons.restaurant_outlined,
          limit: limits[2],
          spent: 228.30,
          iconBackground: FreshSproutColors.tertiaryFixed.withValues(alpha: 0.4),
          iconColor: FreshSproutColors.tertiary,
          barColor: FreshSproutColors.secondary,
          badge: 'Seguro',
        ),
        _CategoryBudget(
          name: 'Farmácia & Cuidados',
          icon: Icons.medication_outlined,
          limit: limits[3],
          spent: 175.00,
          iconBackground: isDark
              ? FreshSproutColors.darkCard
              : FreshSproutColors.surfaceContainerHigh,
          iconColor: isDark
              ? FreshSproutColors.darkTextMuted
              : FreshSproutColors.onSurfaceVariant,
          barColor: FreshSproutColors.primaryContainer,
        ),
      ];
    }

    return [
      _CategoryBudget(
        name: 'Supermercado & Despensa',
        icon: Icons.shopping_basket_outlined,
        limit: limits[0],
        spent: spent[0],
        iconBackground: FreshSproutColors.secondaryContainer.withValues(
          alpha: isDark ? 0.25 : 0.4,
        ),
        iconColor: FreshSproutColors.secondary,
        barColor: FreshSproutColors.primary,
      ),
      _CategoryBudget(
        name: 'Hortifruti & Feira',
        icon: Icons.eco_outlined,
        limit: limits[1],
        spent: spent[1],
        iconBackground: FreshSproutColors.primaryFixed.withValues(alpha: 0.4),
        iconColor: FreshSproutColors.primary,
        barColor: FreshSproutColors.primaryContainer,
      ),
      _CategoryBudget(
        name: 'Açougue & Peixaria',
        icon: Icons.restaurant_outlined,
        limit: limits[2],
        spent: spent[2],
        iconBackground: FreshSproutColors.tertiaryFixed.withValues(alpha: 0.4),
        iconColor: FreshSproutColors.tertiary,
        barColor: FreshSproutColors.secondary,
        badge: spent[2] / limits[2] < 0.75 ? 'Seguro' : null,
      ),
      _CategoryBudget(
        name: 'Farmácia & Cuidados',
        icon: Icons.medication_outlined,
        limit: limits[3],
        spent: spent[3],
        iconBackground: isDark
            ? FreshSproutColors.darkCard
            : FreshSproutColors.surfaceContainerHigh,
        iconColor: isDark
            ? FreshSproutColors.darkTextMuted
            : FreshSproutColors.onSurfaceVariant,
        barColor: FreshSproutColors.primaryContainer,
      ),
    ];
  }

  List<_StoreSummary> _buildStores() {
    const storeNames = [
      'Carrefour Express',
      'Pão de Açúcar',
      'Feira Livre',
      'Drogasil',
    ];
    const storeIcons = [
      Icons.storefront_outlined,
      Icons.storefront_outlined,
      Icons.local_mall_outlined,
      Icons.health_and_safety_outlined,
    ];
    const subtitles = [
      'compras registradas',
      'compras registradas',
      'idas aos sábados',
      'compras registradas',
    ];

    final lists = _monthLists.isNotEmpty ? _monthLists : _allLists;
    if (lists.isEmpty) {
      return const [
        _StoreSummary(
          name: 'Carrefour Express',
          icon: Icons.storefront_outlined,
          purchases: 5,
          total: 558.80,
          share: 0.39,
          subtitle: '5 compras registradas',
        ),
        _StoreSummary(
          name: 'Pão de Açúcar',
          icon: Icons.storefront_outlined,
          purchases: 3,
          total: 412.80,
          share: 0.29,
          subtitle: '3 compras registradas',
        ),
        _StoreSummary(
          name: 'Feira Livre',
          icon: Icons.local_mall_outlined,
          purchases: 4,
          total: 184.20,
          share: 0.13,
          subtitle: '4 idas aos sábados',
        ),
        _StoreSummary(
          name: 'Drogasil',
          icon: Icons.health_and_safety_outlined,
          purchases: 2,
          total: 175.00,
          share: 0.12,
          subtitle: '2 compras registradas',
        ),
      ];
    }

    final totals = List<double>.filled(4, 0);
    final counts = List<int>.filled(4, 0);
    for (var i = 0; i < lists.length; i++) {
      final bucket = i % 4;
      totals[bucket] += lists[i].totalValue;
      counts[bucket]++;
    }
    final grandTotal = totals.fold(0.0, (a, b) => a + b);

    return List.generate(4, (i) {
      return _StoreSummary(
        name: storeNames[i],
        icon: storeIcons[i],
        purchases: counts[i],
        total: totals[i],
        share: grandTotal == 0 ? 0 : totals[i] / grandTotal,
        subtitle: '${counts[i]} ${subtitles[i]}',
      );
    });
  }

  double get _heroSpent =>
      _monthSpent == 0 ? 1428.50 : _monthSpent;

  double get _heroRemaining =>
      _monthSpent == 0 ? 571.50 : _remainingCeiling;

  double get _heroRatio =>
      _monthSpent == 0 ? 0.714 : _consumedRatio;

  int get _heroPercent =>
      _monthSpent == 0 ? 71 : _consumedPercent;

  void _showSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature — em breve')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final prevMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    final nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    final categories = _buildCategories(isDark);
    final stores = _buildStores();
    final projected = _monthSpent == 0 ? 1940.0 : _projectedTotal;
    final projectedSavings =
        _monthSpent == 0 ? 60.0 : _projectedSavings.abs();

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _BudgetHeader(
            isDarkMode: isDark,
            monthLabel: _monthYearLabel(_selectedMonth),
            weekLabel: 'Semana $_weekOfMonth',
            onTune: () => _showSoon('Ajustar parâmetros'),
            onNotifications: () => _showSoon('Notificações'),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                FreshSproutSpacing.marginMobile,
                FreshSproutSpacing.xs,
                FreshSproutSpacing.marginMobile,
                FreshSproutSpacing.lg,
              ),
              children: [
                _MonthSelectorBar(
                  isDarkMode: isDark,
                  prevLabel: _monthLabel(prevMonth),
                  currentLabel: _monthLabel(_selectedMonth),
                  nextLabel: _monthLabel(nextMonth),
                  onPrevious: () => _shiftMonth(-1),
                  onNext: () => _shiftMonth(1),
                ),
                const SizedBox(height: _BudgetSpec.sectionGap),
                _HeroBudgetCard(
                  isDarkMode: isDark,
                  spent: _heroSpent,
                  budget: _BudgetSpec.monthlyBudget,
                  consumedPercent: _heroPercent,
                  consumedRatio: _heroRatio,
                  currentDay: _currentDay,
                  daysInMonth: _daysInMonth,
                  remaining: _heroRemaining,
                  safeDaily: _monthSpent == 0 ? 57.15 : _safeDaily,
                  projected: projected,
                  projectedSavings: projectedSavings,
                  withinGoal: projected <= _BudgetSpec.monthlyBudget,
                  onAdjustGoal: () => _showSoon('Ajustar meta mensal'),
                ),
                const SizedBox(height: _BudgetSpec.sectionGap),
                _CategorySection(
                  isDarkMode: isDark,
                  categories: categories,
                  onAddLimit: () => _showSoon('Novo limite'),
                ),
                const SizedBox(height: _BudgetSpec.sectionGap),
                _EconomyTipsSection(
                  isDarkMode: isDark,
                  dailyAverage: _monthSpent == 0 ? 28.50 : _dailyAverage,
                  extraSavings: projectedSavings.clamp(0, double.infinity),
                ),
                const SizedBox(height: _BudgetSpec.sectionGap),
                _RecurringStoresSection(
                  isDarkMode: isDark,
                  stores: stores,
                ),
                const SizedBox(height: _BudgetSpec.blockGap),
                _RegisterExpenseButton(
                  isDarkMode: isDark,
                  onPressed: () => _showSoon('Registrar despesa manual'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetHeader extends StatelessWidget {
  const _BudgetHeader({
    required this.isDarkMode,
    required this.monthLabel,
    required this.weekLabel,
    required this.onTune,
    required this.onNotifications,
  });

  final bool isDarkMode;
  final String monthLabel;
  final String weekLabel;
  final VoidCallback onTune;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final accent =
        isDarkMode ? FreshSproutColors.inversePrimary : FreshSproutColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FreshSproutSpacing.marginMobile,
        vertical: FreshSproutSpacing.xs,
      ),
      color: isDarkMode
          ? FreshSproutColors.darkBackground
          : FreshSproutColors.surface,
      child: Row(
        children: [
          Container(
            width: _BudgetSpec.avatarSize,
            height: _BudgetSpec.avatarSize,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? FreshSproutColors.darkCard
                  : FreshSproutColors.surfaceContainerHigh,
              shape: BoxShape.circle,
              border: Border.all(
                color: FreshSproutColors.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(Icons.account_circle_outlined, size: 22, color: accent),
          ),
          const SizedBox(width: FreshSproutSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestão de Orçamento',
                  style: _BudgetTypography.headlineSm(context, color: accent),
                ),
                Row(
                  children: [
                    Text(
                      monthLabel,
                      style: _BudgetTypography.bodySm(context),
                    ),
                    const SizedBox(width: _BudgetSpec.tightGap),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: FreshSproutColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: _BudgetSpec.tightGap),
                    Text(
                      weekLabel,
                      style: _BudgetTypography.bodySm(
                        context,
                        color: isDarkMode
                            ? FreshSproutColors.darkAccent
                            : FreshSproutColors.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _BudgetIconButton(
            icon: Icons.tune,
            isDarkMode: isDarkMode,
            iconColor: accent,
            onPressed: onTune,
          ),
          const SizedBox(width: FreshSproutSpacing.xxs),
          _BudgetIconButton(
            icon: Icons.notifications_outlined,
            isDarkMode: isDarkMode,
            onPressed: onNotifications,
          ),
        ],
      ),
    );
  }
}

class _BudgetIconButton extends StatelessWidget {
  const _BudgetIconButton({
    required this.icon,
    required this.isDarkMode,
    required this.onPressed,
    this.iconColor,
  });

  final IconData icon;
  final bool isDarkMode;
  final VoidCallback onPressed;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _BudgetSpec.iconBtnSize,
      height: _BudgetSpec.iconBtnSize,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Icon(
            icon,
            size: 22,
            color: iconColor ??
                (isDarkMode
                    ? FreshSproutColors.darkTextSecondary
                    : FreshSproutColors.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

class _MonthSelectorBar extends StatelessWidget {
  const _MonthSelectorBar({
    required this.isDarkMode,
    required this.prevLabel,
    required this.currentLabel,
    required this.nextLabel,
    required this.onPrevious,
    required this.onNext,
  });

  final bool isDarkMode;
  final String prevLabel;
  final String currentLabel;
  final String nextLabel;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final inactiveColor = (isDarkMode
            ? FreshSproutColors.darkTextMuted
            : FreshSproutColors.onSurfaceVariant)
        .withValues(alpha: 0.7);
    final inactiveStyle =
        _BudgetTypography.bodySm(context, color: inactiveColor);

    final activePill = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _BudgetSpec.cardPadding,
        vertical: _BudgetSpec.tightGap,
      ),
      decoration: BoxDecoration(
        color: FreshSproutColors.primaryContainer,
        borderRadius: FreshSproutRadius.fullBorder,
        boxShadow: isDarkMode ? null : FreshSproutElevation.level1,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_month_outlined,
            size: 14,
            color: FreshSproutColors.onPrimaryContainer,
          ),
          const SizedBox(width: 6),
          Text(
            currentLabel,
            style: _BudgetTypography.labelMd(
              context,
              color: FreshSproutColors.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(_BudgetSpec.tightGap),
      decoration: BoxDecoration(
        color: isDarkMode
            ? FreshSproutColors.darkCard
            : FreshSproutColors.surfaceContainerLowest,
        borderRadius: _BudgetSpec.cardRadius,
        border: Border.all(
          color: FreshSproutColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: isDarkMode ? null : FreshSproutElevation.level1,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _MonthNavButton(icon: Icons.chevron_left, onTap: onPrevious),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _BudgetSpec.blockGap,
                      vertical: _BudgetSpec.tightGap,
                    ),
                    child: Text(prevLabel, style: inactiveStyle),
                  ),
                  const SizedBox(width: _BudgetSpec.blockGap),
                  activePill,
                  const SizedBox(width: _BudgetSpec.blockGap),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _BudgetSpec.blockGap,
                      vertical: _BudgetSpec.tightGap,
                    ),
                    child: Text(nextLabel, style: inactiveStyle),
                  ),
                ],
              ),
            ),
          ),
          _MonthNavButton(icon: Icons.chevron_right, onTap: onNext),
        ],
      ),
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  const _MonthNavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: _BudgetSpec.buttonRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: _BudgetSpec.buttonRadius,
        child: SizedBox(
          width: _BudgetSpec.monthNavSize,
          height: _BudgetSpec.monthNavSize,
          child: Icon(icon, size: 20, color: FreshSproutColors.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _BudgetGradientProgressBar extends StatelessWidget {
  const _BudgetGradientProgressBar({
    required this.value,
    required this.isDarkMode,
  });

  final double value;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final trackColor = isDarkMode
        ? FreshSproutColors.darkBorder
        : FreshSproutColors.surfaceContainerHighest;
    final fillColors = isDarkMode
        ? [
            FreshSproutColors.darkAccent,
            FreshSproutColors.darkAccent.withValues(alpha: 0.85),
            FreshSproutColors.darkAccentHover,
          ]
        : [
            FreshSproutColors.secondaryFixedDim,
            FreshSproutColors.primaryContainer,
            FreshSproutColors.primary,
          ];

    return Container(
      height: 10,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: FreshSproutRadius.fullBorder,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fillWidth = constraints.maxWidth * value.clamp(0.0, 1.0);
          return Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              width: fillWidth,
              decoration: BoxDecoration(
                borderRadius: FreshSproutRadius.fullBorder,
                gradient: LinearGradient(colors: fillColors),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeroBudgetCard extends StatelessWidget {
  const _HeroBudgetCard({
    required this.isDarkMode,
    required this.spent,
    required this.budget,
    required this.consumedPercent,
    required this.consumedRatio,
    required this.currentDay,
    required this.daysInMonth,
    required this.remaining,
    required this.safeDaily,
    required this.projected,
    required this.projectedSavings,
    required this.withinGoal,
    required this.onAdjustGoal,
  });

  final bool isDarkMode;
  final double spent;
  final double budget;
  final int consumedPercent;
  final double consumedRatio;
  final int currentDay;
  final int daysInMonth;
  final double remaining;
  final double safeDaily;
  final double projected;
  final double projectedSavings;
  final bool withinGoal;
  final VoidCallback onAdjustGoal;

  @override
  Widget build(BuildContext context) {
    final accent =
        isDarkMode ? FreshSproutColors.darkAccent : FreshSproutColors.primary;

    return Container(
      padding: const EdgeInsets.all(_BudgetSpec.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [FreshSproutColors.darkCard, FreshSproutColors.darkBackground]
              : [
                  FreshSproutColors.surfaceContainerLowest,
                  FreshSproutColors.surfaceContainerLow,
                ],
        ),
        borderRadius: _BudgetSpec.cardRadius,
        border: Border.all(
          color: FreshSproutColors.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: isDarkMode ? null : FreshSproutElevation.level2,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -48,
            top: -48,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: FreshSproutColors.primaryFixed.withValues(alpha: 0.2),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Teto Previsto para Compras',
                          style: _BudgetTypography.bodySm(
                            context,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: _BudgetSpec.tightGap),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'R\$ ${formatPrice(spent)}',
                                style: _BudgetTypography.headlineLg(context),
                              ),
                              TextSpan(
                                text: ' / R\$ ${formatPrice(budget)}',
                                style: _BudgetTypography.bodyMd(
                                  context,
                                  color: isDarkMode
                                      ? FreshSproutColors.darkTextMuted
                                      : FreshSproutColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _BudgetSpec.cardPaddingSm,
                      vertical: _BudgetSpec.tightGap,
                    ),
                    decoration: BoxDecoration(
                      color: FreshSproutColors.secondaryContainer,
                      borderRadius: FreshSproutRadius.fullBorder,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 14,
                          color: FreshSproutColors.onSecondaryContainer,
                        ),
                        const SizedBox(width: _BudgetSpec.tightGap),
                        Text(
                          withinGoal ? 'DENTRO DA META' : 'ATENÇÃO',
                          style: _BudgetTypography.labelSm(
                            context,
                            color: FreshSproutColors.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: _BudgetSpec.cardPaddingSm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$consumedPercent% consumido',
                    style: _BudgetTypography.labelMd(
                      context,
                      color: FreshSproutColors.secondary,
                    ),
                  ),
                  Text(
                    '$currentDay de $daysInMonth dias',
                    style: _BudgetTypography.labelMd(
                      context,
                      color: isDarkMode
                          ? FreshSproutColors.darkTextMuted
                          : FreshSproutColors.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: _BudgetSpec.tightGap),
              _BudgetGradientProgressBar(
                value: consumedRatio,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: _BudgetSpec.cardPadding),
              Container(
                padding: const EdgeInsets.only(top: _BudgetSpec.blockGap),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: FreshSproutColors.outlineVariant.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _HeroMetricTile(
                          isDarkMode: isDarkMode,
                          icon: Icons.savings_outlined,
                          iconColor: accent,
                          label: 'Restam no Teto',
                          value: 'R\$ ${formatPrice(remaining)}',
                          subtitle:
                              'Média segura: R\$ ${formatPrice(safeDaily)}/dia',
                        ),
                      ),
                      const SizedBox(width: _BudgetSpec.blockGap),
                      Expanded(
                        child: _HeroMetricTile(
                          isDarkMode: isDarkMode,
                          icon: Icons.trending_down,
                          iconColor: FreshSproutColors.secondary,
                          label: 'Projeção Final',
                          value: 'R\$ ${formatPrice(projected)}',
                          subtitle: withinGoal
                              ? 'Saldo positivo (+R\$ ${formatPrice(projectedSavings)})'
                              : 'Acima da meta',
                          subtitleColor: FreshSproutColors.secondary,
                          showCheck: withinGoal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: _BudgetSpec.cardPaddingSm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: onAdjustGoal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_calendar_outlined, size: 16, color: accent),
                        const SizedBox(width: _BudgetSpec.tightGap),
                        Text(
                          'Ajustar Meta Mensal',
                          style: _BudgetTypography.labelMd(context, color: accent),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Meta revista há 12 dias',
                    style: _BudgetTypography.bodySm(
                      context,
                      color: FreshSproutColors.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetricTile extends StatelessWidget {
  const _HeroMetricTile({
    required this.isDarkMode,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
    this.subtitleColor,
    this.showCheck = false,
  });

  final bool isDarkMode;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;
  final Color? subtitleColor;
  final bool showCheck;

  @override
  Widget build(BuildContext context) {
    final valueColor = iconColor == FreshSproutColors.secondary
        ? (isDarkMode
            ? FreshSproutColors.darkTextPrimary
            : FreshSproutColors.onSurface)
        : iconColor;

    final subtitleStyle = _BudgetTypography.bodySm(
      context,
      color: subtitleColor ?? FreshSproutColors.outline,
      fontWeight: showCheck ? FontWeight.w500 : FontWeight.w400,
    ).copyWith(fontSize: 11, height: 14 / 11);

    return Container(
      padding: const EdgeInsets.all(_BudgetSpec.blockGap),
      decoration: BoxDecoration(
        color: (isDarkMode
                ? FreshSproutColors.darkBackground
                : FreshSproutColors.surfaceContainerLowest)
            .withValues(alpha: 0.8),
        borderRadius: _BudgetSpec.buttonRadius,
        border: Border.all(
          color: FreshSproutColors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: _BudgetSpec.tightGap),
              Expanded(
                child: Text(
                  label,
                  style: _BudgetTypography.labelSm(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: _BudgetTypography.headlineSm(
              context,
              color: valueColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: _BudgetSpec.tightGap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showCheck) ...[
                Icon(
                  Icons.task_alt_outlined,
                  size: 12,
                  color: subtitleColor ?? FreshSproutColors.outline,
                ),
                const SizedBox(width: 2),
              ],
              Expanded(
                child: Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: subtitleStyle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.isDarkMode,
    required this.categories,
    required this.onAddLimit,
  });

  final bool isDarkMode;
  final List<_CategoryBudget> categories;
  final VoidCallback onAddLimit;

  @override
  Widget build(BuildContext context) {
    final accent =
        isDarkMode ? FreshSproutColors.darkAccent : FreshSproutColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _BudgetSpec.tightGap),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sub-orçamentos',
                    style: _BudgetTypography.headlineSm(context),
                  ),
                  Text(
                    'por Categoria',
                    style: _BudgetTypography.headlineSm(context),
                  ),
                  Text(
                    '${categories.length} divisões orçamentárias ativas',
                    style: _BudgetTypography.bodySm(context),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onAddLimit,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_circle_outline, size: 16, color: accent),
                    const SizedBox(width: _BudgetSpec.tightGap),
                    Text(
                      'Novo Limite',
                      style: _BudgetTypography.labelMd(context, color: accent),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: _BudgetSpec.blockGap),
        ...categories.map(
          (category) => Padding(
            padding: const EdgeInsets.only(bottom: _BudgetSpec.blockGap),
            child: _CategoryCard(isDarkMode: isDarkMode, category: category),
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.isDarkMode,
    required this.category,
  });

  final bool isDarkMode;
  final _CategoryBudget category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_BudgetSpec.cardPaddingSm),
      decoration: BoxDecoration(
        color: isDarkMode
            ? FreshSproutColors.darkCard
            : FreshSproutColors.surfaceContainerLowest,
        borderRadius: _BudgetSpec.cardRadius,
        border: Border.all(
          color: FreshSproutColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: isDarkMode ? null : FreshSproutElevation.level1,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: _BudgetSpec.categoryIconSize,
                height: _BudgetSpec.categoryIconSize,
                decoration: BoxDecoration(
                  color: category.iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(category.icon, size: 22, color: category.iconColor),
              ),
              const SizedBox(width: _BudgetSpec.blockGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: _BudgetTypography.labelLg(context),
                    ),
                    Text(
                      'R\$ ${formatPrice(category.spent)} de R\$ ${formatPrice(category.limit)}',
                      style: _BudgetTypography.bodySm(context),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${category.percent}%',
                        style: _BudgetTypography.labelMd(
                          context,
                          color: category.badge != null
                              ? FreshSproutColors.secondary
                              : null,
                        ),
                      ),
                      if (category.badge != null)
                        Container(
                          margin: const EdgeInsets.only(left: _BudgetSpec.tightGap),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: FreshSproutColors.secondaryContainer,
                            borderRadius: FreshSproutRadius.smBorder,
                          ),
                          child: Text(
                            category.badge!,
                            style: _BudgetTypography.labelSm(
                              context,
                              color: FreshSproutColors.onSecondaryContainer,
                              fontWeight: FontWeight.w700,
                            ).copyWith(letterSpacing: 0),
                          ),
                        )
                      else
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: _BudgetSpec.tightGap),
                          decoration: BoxDecoration(
                            color: category.barColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  Text(
                    'Resta R\$ ${formatPrice(category.remaining)}',
                    style: _BudgetTypography.bodySm(
                      context,
                      color: FreshSproutColors.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: _BudgetSpec.blockGap),
          ClipRRect(
            borderRadius: FreshSproutRadius.fullBorder,
            child: LinearProgressIndicator(
              value: category.ratio,
              minHeight: 8,
              backgroundColor: isDarkMode
                  ? FreshSproutColors.darkBackground
                  : FreshSproutColors.surfaceContainer,
              valueColor: AlwaysStoppedAnimation<Color>(category.barColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _EconomyTipsSection extends StatelessWidget {
  const _EconomyTipsSection({
    required this.isDarkMode,
    required this.dailyAverage,
    required this.extraSavings,
  });

  final bool isDarkMode;
  final double dailyAverage;
  final double extraSavings;

  @override
  Widget build(BuildContext context) {
    final accent =
        isDarkMode ? FreshSproutColors.darkAccent : FreshSproutColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _BudgetSpec.tightGap),
          child: Row(
            children: [
              Icon(Icons.tips_and_updates_outlined, size: 20, color: accent),
              const SizedBox(width: 6),
              Text(
                'Dicas de Economia Consciente',
                style: _BudgetTypography.headlineSm(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: _BudgetSpec.blockGap),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(_BudgetSpec.cardPadding),
          decoration: BoxDecoration(
            color: isDarkMode
                ? FreshSproutColors.darkCard
                : FreshSproutColors.surfaceContainerLow,
            borderRadius: _BudgetSpec.cardRadius,
            border: Border.all(
              color: FreshSproutColors.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: isDarkMode ? null : FreshSproutElevation.level1,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: _BudgetSpec.tipIconSize,
                height: _BudgetSpec.tipIconSize,
                decoration: const BoxDecoration(
                  color: FreshSproutColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.insights_outlined,
                  size: 18,
                  color: FreshSproutColors.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: _BudgetSpec.blockGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ritmo Saudável de Compras',
                      style: _BudgetTypography.labelLg(context),
                    ),
                    const SizedBox(height: _BudgetSpec.tightGap),
                    Text.rich(
                      TextSpan(
                        style: _BudgetTypography.bodyMd(context).copyWith(
                              height: 1.45,
                            ),
                        children: [
                          const TextSpan(
                            text:
                                'Você costuma concentrar 40% das compras na 1ª semana. Mantendo a média diária de ',
                          ),
                          TextSpan(
                            text: 'R\$ ${formatPrice(dailyAverage)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: accent,
                            ),
                          ),
                          const TextSpan(text: ', você fechará o mês com '),
                          TextSpan(
                            text:
                                'R\$ ${formatPrice(extraSavings)} de economia extra!',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: FreshSproutColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: _BudgetSpec.blockGap),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(_BudgetSpec.cardPadding),
          decoration: BoxDecoration(
            color: isDarkMode
                ? FreshSproutColors.darkCard
                : FreshSproutColors.surfaceContainerLowest,
            borderRadius: _BudgetSpec.cardRadius,
            border: Border.all(
              color: FreshSproutColors.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: isDarkMode ? null : FreshSproutElevation.level1,
          ),
          child: Row(
            children: [
              Container(
                width: _BudgetSpec.categoryIconSize,
                height: _BudgetSpec.categoryIconSize,
                decoration: BoxDecoration(
                  color: FreshSproutColors.secondaryContainer.withValues(
                    alpha: 0.5,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.trending_down,
                  size: 20,
                  color: FreshSproutColors.secondary,
                ),
              ),
              const SizedBox(width: _BudgetSpec.cardPaddingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: _BudgetSpec.tightGap,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: FreshSproutColors.primaryFixed
                                .withValues(alpha: 0.4),
                            borderRadius: FreshSproutRadius.smBorder,
                          ),
                          child: Text(
                            'Hortifruti',
                            style: _BudgetTypography.labelSm(
                              context,
                              color: const Color(0xFF005236),
                            ).copyWith(letterSpacing: 0),
                          ),
                        ),
                        Text(
                          '-8% vs mês anterior',
                          style: _BudgetTypography.labelMd(
                            context,
                            color: FreshSproutColors.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Excelente controle de feira livre neste ciclo quinzenal.',
                      style: _BudgetTypography.bodySm(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecurringStoresSection extends StatelessWidget {
  const _RecurringStoresSection({
    required this.isDarkMode,
    required this.stores,
  });

  final bool isDarkMode;
  final List<_StoreSummary> stores;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _BudgetSpec.tightGap),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mercados & Locais Recorrentes',
                style: _BudgetTypography.headlineSm(context),
              ),
              Text(
                '${stores.length} locais',
                style: _BudgetTypography.bodySm(
                  context,
                  color: FreshSproutColors.outline,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: _BudgetSpec.blockGap),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? FreshSproutColors.darkCard
                : FreshSproutColors.surfaceContainerLowest,
            borderRadius: _BudgetSpec.cardRadius,
            border: Border.all(
              color: FreshSproutColors.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: isDarkMode ? null : FreshSproutElevation.level1,
          ),
          padding: const EdgeInsets.all(_BudgetSpec.cardPaddingSm),
          child: Column(
            children: [
              for (var i = 0; i < stores.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    color: isDarkMode
                        ? FreshSproutColors.darkBorder
                        : FreshSproutColors.surfaceContainer,
                  ),
                _StoreRow(isDarkMode: isDarkMode, store: stores[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StoreRow extends StatelessWidget {
  const _StoreRow({required this.isDarkMode, required this.store});

  final bool isDarkMode;
  final _StoreSummary store;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _BudgetSpec.blockGap),
      child: Row(
        children: [
          Container(
            width: _BudgetSpec.storeIconSize,
            height: _BudgetSpec.storeIconSize,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? FreshSproutColors.darkBackground
                  : FreshSproutColors.surfaceContainerHigh,
              borderRadius: _BudgetSpec.buttonRadius,
            ),
            child: Icon(
              store.icon,
              size: 18,
              color: isDarkMode
                  ? FreshSproutColors.darkTextMuted
                  : FreshSproutColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: _BudgetSpec.blockGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.name,
                  style: _BudgetTypography.labelLg(
                    context,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  store.subtitle,
                  style: _BudgetTypography.bodySm(
                    context,
                    color: FreshSproutColors.outline,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'R\$ ${formatPrice(store.total)}',
                style: _BudgetTypography.labelLg(context),
              ),
              Text(
                '${(store.share * 100).round()}% do total',
                style: _BudgetTypography.bodySm(
                  context,
                  color: isDarkMode
                      ? FreshSproutColors.darkTextMuted
                      : FreshSproutColors.onSurfaceVariant,
                ).copyWith(fontSize: 11, height: 14 / 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RegisterExpenseButton extends StatelessWidget {
  const _RegisterExpenseButton({
    required this.isDarkMode,
    required this.onPressed,
  });

  final bool isDarkMode;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDarkMode
          ? FreshSproutColors.darkAccent
          : FreshSproutColors.primaryContainer,
      borderRadius: _BudgetSpec.cardRadius,
      elevation: 0,
      shadowColor: FreshSproutColors.shadowTint.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onPressed,
        borderRadius: _BudgetSpec.cardRadius,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                size: 20,
                color: isDarkMode
                    ? FreshSproutColors.darkBackground
                    : FreshSproutColors.onPrimary,
              ),
              const SizedBox(width: _BudgetSpec.blockGap),
              Text(
                'Registrar Nova Despesa Manual',
                style: _BudgetTypography.labelLg(
                  context,
                  color: isDarkMode
                      ? FreshSproutColors.darkBackground
                      : FreshSproutColors.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
