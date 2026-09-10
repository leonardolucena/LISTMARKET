import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/shopping_list.dart';
import '../services/shopping_list_repository.dart';
import '../theme/fresh_sprout_tokens.dart';
import '../utils/date_formatter.dart';
import 'list_detail_screen.dart';

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

const _stores = [
  'Todos',
  'Pão de Açúcar',
  'Carrefour',
  'Feira da Vila',
];

abstract final class _HistorySpec {
  static final cardRadius = FreshSproutRadius.lgBorder;
  static final buttonRadius = FreshSproutRadius.mdBorder;
  static const iconBtnSize = 40.0;
  static const avatarSize = 40.0;
  static const savingsMint = Color(0xFFEBF9F2);
  static const monthlyBudget = 1500.0;
}

class _MonthBucket {
  const _MonthBucket({
    required this.year,
    required this.month,
    required this.lists,
  });

  final int year;
  final int month;
  final List<ShoppingList> lists;

  String get key => '$year-${month.toString().padLeft(2, '0')}';

  String get label => '${_monthLong[month - 1]} $year';

  String get chipLabel {
    final name = _monthLong[month - 1];
    return '$name (${lists.length})';
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.isDarkMode});

  final bool isDarkMode;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _repository = ShoppingListRepository.instance;

  String? _selectedMonthKey;
  String _selectedStore = _stores.first;

  bool _isCompleted(ShoppingList list) =>
      list.items.isNotEmpty && list.pendingCount == 0;

  List<ShoppingList> get _completedLists =>
      _repository.getAllLists().where(_isCompleted).toList();

  List<_MonthBucket> get _monthBuckets {
    final map = <String, List<ShoppingList>>{};
    for (final list in _completedLists) {
      final date = list.updatedAt;
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      map.putIfAbsent(key, () => []).add(list);
    }
    final buckets = map.entries.map((entry) {
      final parts = entry.key.split('-');
      final lists = entry.value
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return _MonthBucket(
        year: int.parse(parts[0]),
        month: int.parse(parts[1]),
        lists: lists,
      );
    }).toList()
      ..sort((a, b) {
        final aDate = DateTime(a.year, a.month);
        final bDate = DateTime(b.year, b.month);
        return bDate.compareTo(aDate);
      });
    return buckets;
  }

  _MonthBucket? get _activeBucket {
    final buckets = _monthBuckets;
    if (buckets.isEmpty) return null;
    if (_selectedMonthKey == null) return buckets.first;
    for (final bucket in buckets) {
      if (bucket.key == _selectedMonthKey) return bucket;
    }
    return buckets.first;
  }

  List<ShoppingList> get _filteredLists {
    final bucket = _activeBucket;
    if (bucket == null) return [];
    if (_selectedStore == 'Todos') return bucket.lists;
    return bucket.lists
        .where((list) => _storeForList(list, bucket.lists.indexOf(list)) ==
            _selectedStore)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _syncSelectedMonth();
  }

  void _syncSelectedMonth() {
    final buckets = _monthBuckets;
    if (buckets.isEmpty) {
      _selectedMonthKey = null;
      return;
    }
    if (_selectedMonthKey == null ||
        !buckets.any((b) => b.key == _selectedMonthKey)) {
      _selectedMonthKey = buckets.first.key;
    }
  }

  void _reload() {
    setState(_syncSelectedMonth);
  }

  String _storeForList(ShoppingList list, int index) {
    const names = ['Pão de Açúcar', 'Carrefour', 'Feira da Vila', 'Drogasil'];
    return names[index % names.length];
  }

  IconData _storeIcon(String store) {
    if (store.contains('Feira')) return Icons.agriculture_outlined;
    if (store.contains('Drog')) return Icons.local_pharmacy_outlined;
    if (store.contains('Carrefour')) return Icons.local_mall_outlined;
    return Icons.storefront_outlined;
  }

  double _estimatedSavings(double total) => total * 0.129;

  List<double> _weeklyTotals(_MonthBucket bucket) {
    final totals = List<double>.filled(4, 0);
    for (final list in bucket.lists) {
      final week = ((list.updatedAt.day - 1) / 7).floor().clamp(0, 3);
      totals[week] += list.totalValue;
    }
    return totals;
  }

  void _showSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature — em breve')),
    );
  }

  Future<void> _openList(ShoppingList list) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ListDetailScreen(listId: list.id),
      ),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final completedCount = _completedLists.length;
    final bucket = _activeBucket;
    final filtered = _filteredLists;
    final monthTotal =
        bucket?.lists.fold(0.0, (sum, list) => sum + list.totalValue) ?? 0;
    final monthSavings = _estimatedSavings(monthTotal);
    final monthAverage =
        bucket == null || bucket.lists.isEmpty ? 0.0 : monthTotal / bucket.lists.length;
    final budgetRatio =
        (monthTotal / _HistorySpec.monthlyBudget).clamp(0.0, 1.0);
    final budgetPercent = (budgetRatio * 100).toStringAsFixed(1).replaceAll('.', ',');

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _HistoryHeader(
            isDarkMode: isDark,
            completedCount: completedCount,
            onSearch: () => _showSoon('Pesquisar histórico'),
            onExport: () => _showSoon('Exportar relatório'),
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
                if (bucket != null)
                  _PeriodSummaryCard(
                    isDarkMode: isDark,
                    monthLabel: bucket.label,
                    purchaseCount: bucket.lists.length,
                    monthTotal: monthTotal,
                    monthSavings: monthSavings,
                    monthAverage: monthAverage,
                    budgetPercent: budgetPercent,
                    budgetRatio: budgetRatio,
                    weeklyTotals: _weeklyTotals(bucket),
                  )
                else
                  _EmptySummaryCard(isDarkMode: isDark),
                const SizedBox(height: FreshSproutSpacing.md),
                _MonthFilterRow(
                  isDarkMode: isDark,
                  buckets: _monthBuckets,
                  selectedKey: _selectedMonthKey,
                  onSelected: (key) => setState(() => _selectedMonthKey = key),
                ),
                const SizedBox(height: FreshSproutSpacing.xs),
                _StoreFilterRow(
                  isDarkMode: isDark,
                  selectedStore: _selectedStore,
                  onSelected: (store) => setState(() => _selectedStore = store),
                ),
                const SizedBox(height: FreshSproutSpacing.sm),
                _CompletedListsHeader(
                  isDarkMode: isDark,
                  periodLabel: bucket?.label ?? 'Sem registros',
                ),
                const SizedBox(height: FreshSproutSpacing.sm),
                if (filtered.isEmpty)
                  _HistoryEmptyLists(isDarkMode: isDark)
                else
                  ...filtered.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: FreshSproutSpacing.sm,
                          ),
                          child: _HistoryListCard(
                            isDarkMode: isDark,
                            list: entry.value,
                            store: _storeForList(entry.value, entry.key),
                            storeIcon: _storeIcon(
                              _storeForList(entry.value, entry.key),
                            ),
                            savings: _estimatedSavings(entry.value.totalValue),
                            hasReceipt: entry.key.isEven,
                            onViewItems: () => _openList(entry.value),
                            onRepeat: () => _showSoon('Repetir lista'),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({
    required this.isDarkMode,
    required this.completedCount,
    required this.onSearch,
    required this.onExport,
  });

  final bool isDarkMode;
  final int completedCount;
  final VoidCallback onSearch;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: (isDarkMode
                    ? FreshSproutColors.darkBackground
                    : FreshSproutColors.surface)
                .withValues(alpha: 0.95),
            boxShadow: isDarkMode
                ? null
                : [
                    BoxShadow(
                      color: FreshSproutColors.shadowTint.withValues(alpha: 0.03),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: FreshSproutSpacing.marginMobile,
            vertical: FreshSproutSpacing.xs,
          ),
          child: Row(
            children: [
              Container(
                width: _HistorySpec.avatarSize,
                height: _HistorySpec.avatarSize,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? FreshSproutColors.darkCard
                      : FreshSproutColors.secondaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: FreshSproutColors.outlineVariant.withValues(
                      alpha: isDarkMode ? 0.35 : 0.4,
                    ),
                  ),
                  boxShadow: FreshSproutElevation.level1,
                ),
                alignment: Alignment.center,
                child: Text(
                  'MC',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isDarkMode
                            ? FreshSproutColors.darkAccent
                            : FreshSproutColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                ),
              ),
              const SizedBox(width: FreshSproutSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Histórico de Compras',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: isDarkMode
                                ? FreshSproutColors.inversePrimary
                                : FreshSproutColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            height: 24 / 18,
                          ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? FreshSproutColors.darkAccent
                                : FreshSproutColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$completedCount listas concluídas',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isDarkMode
                                    ? FreshSproutColors.darkTextMuted
                                    : FreshSproutColors.onSurfaceVariant,
                                fontSize: 12,
                                height: 16 / 12,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _HistoryIconButton(
                icon: Icons.search,
                isDarkMode: isDarkMode,
                onPressed: onSearch,
              ),
              const SizedBox(width: 4),
              _HistoryIconButton(
                icon: Icons.download_outlined,
                isDarkMode: isDarkMode,
                onPressed: onExport,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryIconButton extends StatelessWidget {
  const _HistoryIconButton({
    required this.icon,
    required this.isDarkMode,
    required this.onPressed,
  });

  final IconData icon;
  final bool isDarkMode;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _HistorySpec.iconBtnSize,
      height: _HistorySpec.iconBtnSize,
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
            color: isDarkMode
                ? FreshSproutColors.darkTextSecondary
                : FreshSproutColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _PeriodSummaryCard extends StatelessWidget {
  const _PeriodSummaryCard({
    required this.isDarkMode,
    required this.monthLabel,
    required this.purchaseCount,
    required this.monthTotal,
    required this.monthSavings,
    required this.monthAverage,
    required this.budgetPercent,
    required this.budgetRatio,
    required this.weeklyTotals,
  });

  final bool isDarkMode;
  final String monthLabel;
  final int purchaseCount;
  final double monthTotal;
  final double monthSavings;
  final double monthAverage;
  final String budgetPercent;
  final double budgetRatio;
  final List<double> weeklyTotals;

  @override
  Widget build(BuildContext context) {
    final accent =
        isDarkMode ? FreshSproutColors.darkAccent : FreshSproutColors.primary;
    final maxWeek = weeklyTotals.fold(0.0, (a, b) => a > b ? a : b);

    return _HistorySurfaceCard(
      isDarkMode: isDarkMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_month_outlined, size: 20, color: accent),
                  const SizedBox(width: FreshSproutSpacing.xs),
                  Text(
                    monthLabel,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: isDarkMode
                              ? FreshSproutColors.darkTextPrimary
                              : FreshSproutColors.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          height: 24 / 18,
                        ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: FreshSproutSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? FreshSproutColors.darkCard
                      : FreshSproutColors.surfaceContainer,
                  borderRadius: FreshSproutRadius.fullBorder,
                ),
                child: Text(
                  '$purchaseCount compras',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isDarkMode
                            ? FreshSproutColors.darkTextMuted
                            : FreshSproutColors.onSurfaceVariant,
                        fontSize: 12,
                        height: 16 / 12,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: FreshSproutSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _SummaryMetricTile(
                  isDarkMode: isDarkMode,
                  label: 'Total no Mês',
                  value: monthTotal,
                  subtitle:
                      'Meta: R\$ ${formatPrice(_HistorySpec.monthlyBudget)}',
                  valueColor: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SavingsMetricTile(
                  isDarkMode: isDarkMode,
                  value: monthSavings,
                  savingsPercent: monthTotal == 0
                      ? '0,0%'
                      : ((monthSavings / monthTotal) * 100)
                          .toStringAsFixed(1)
                          .replaceAll('.', ','),
                ),
              ),
            ],
          ),
          const SizedBox(height: FreshSproutSpacing.md),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isDarkMode
                      ? FreshSproutColors.darkBackground
                      : FreshSproutColors.surfaceContainerLow)
                  .withValues(alpha: isDarkMode ? 1 : 0.7),
              borderRadius: _HistorySpec.buttonRadius,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shopping_basket_outlined,
                            size: 16, color: accent),
                        const SizedBox(width: 6),
                        Text(
                          'Média por ida ao mercado:',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDarkMode
                                        ? FreshSproutColors.darkTextMuted
                                        : FreshSproutColors.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                        ),
                      ],
                    ),
                    Text(
                      'R\$ ${formatPrice(monthAverage)}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: isDarkMode
                                ? FreshSproutColors.darkTextPrimary
                                : FreshSproutColors.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 56,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(4, (index) {
                      final total = weeklyTotals[index];
                      final heightFactor =
                          maxWeek == 0 ? 0.0 : total / maxWeek;
                      final barColor = index.isEven
                          ? FreshSproutColors.primaryContainer
                          : FreshSproutColors.primaryFixedDim;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: index == 0 ? 0 : 4,
                            right: index == 3 ? 0 : 4,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Flexible(
                                child: FractionallySizedBox(
                                  heightFactor:
                                      heightFactor.clamp(0.08, 1.0),
                                  widthFactor: 1,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? (index.isEven
                                              ? FreshSproutColors.darkAccent
                                              : FreshSproutColors.darkAccent
                                                  .withValues(alpha: 0.55))
                                          : barColor,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(2),
                                        topRight: Radius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'S${index + 1}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      fontSize: 10,
                                      letterSpacing: 0,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 8),
                Divider(
                  height: 1,
                  color: FreshSproutColors.outlineVariant.withValues(
                    alpha: isDarkMode ? 0.25 : 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Orçamento mensal: R\$ ${formatPrice(_HistorySpec.monthlyBudget)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            letterSpacing: 0,
                          ),
                    ),
                    Text(
                      budgetRatio <= 1
                          ? 'Dentro da meta ($budgetPercent%)'
                          : 'Acima da meta ($budgetPercent%)',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            letterSpacing: 0,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetricTile extends StatelessWidget {
  const _SummaryMetricTile({
    required this.isDarkMode,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.valueColor,
  });

  final bool isDarkMode;
  final String label;
  final double value;
  final String subtitle;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final parts = formatPrice(value).split(',');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  FreshSproutColors.darkCard,
                  FreshSproutColors.darkBackground,
                ]
              : [
                  FreshSproutColors.surfaceContainerLowest,
                  FreshSproutColors.surfaceContainerLow,
                ],
        ),
        borderRadius: _HistorySpec.buttonRadius,
        border: Border.all(
          color: isDarkMode
              ? FreshSproutColors.darkBorder
              : FreshSproutColors.borderSubtle.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 12,
                  height: 16 / 12,
                ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'R\$ ${parts.first}',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: valueColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 28,
                        height: 34 / 28,
                      ),
                ),
                if (parts.length > 1)
                  TextSpan(
                    text: ',${parts.last}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: valueColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          height: 24 / 18,
                        ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  height: 16 / 12,
                ),
          ),
        ],
      ),
    );
  }
}

class _SavingsMetricTile extends StatelessWidget {
  const _SavingsMetricTile({
    required this.isDarkMode,
    required this.value,
    required this.savingsPercent,
  });

  final bool isDarkMode;
  final double value;
  final String savingsPercent;

  @override
  Widget build(BuildContext context) {
    final parts = formatPrice(value).split(',');
    final accent =
        isDarkMode ? FreshSproutColors.darkAccent : FreshSproutColors.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  FreshSproutColors.darkCard,
                  FreshSproutColors.darkBackground,
                ]
              : [
                  _HistorySpec.savingsMint,
                  FreshSproutColors.surfaceContainerLow,
                ],
        ),
        borderRadius: _HistorySpec.buttonRadius,
        border: Border.all(
          color: FreshSproutColors.secondaryFixed.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Economia Total',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isDarkMode
                          ? FreshSproutColors.darkTextSecondary
                          : FreshSproutColors.onSecondaryContainer,
                      fontSize: 12,
                    ),
              ),
              Icon(Icons.savings_outlined, size: 18, color: accent),
            ],
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'R\$ ${parts.first}',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: isDarkMode
                            ? FreshSproutColors.darkTextPrimary
                            : FreshSproutColors.onSecondaryContainer,
                        fontWeight: FontWeight.w700,
                        fontSize: 28,
                        height: 34 / 28,
                      ),
                ),
                if (parts.length > 1)
                  TextSpan(
                    text: ',${parts.last}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: isDarkMode
                              ? FreshSproutColors.darkTextPrimary
                              : FreshSproutColors.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? FreshSproutColors.darkAccent.withValues(alpha: 0.15)
                  : FreshSproutColors.secondaryFixed,
              borderRadius: FreshSproutRadius.smBorder,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.trending_down, size: 12, color: accent),
                const SizedBox(width: 4),
                Text(
                  '$savingsPercent% poupado',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDarkMode
                            ? FreshSproutColors.darkAccent
                            : const Color(0xFF002112),
                        fontSize: 10,
                        letterSpacing: 0,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySummaryCard extends StatelessWidget {
  const _EmptySummaryCard({required this.isDarkMode});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return _HistorySurfaceCard(
      isDarkMode: isDarkMode,
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 40,
            color: isDarkMode
                ? FreshSproutColors.darkTextMuted
                : FreshSproutColors.onSurfaceVariant,
          ),
          const SizedBox(height: FreshSproutSpacing.xs),
          Text(
            'Nenhuma compra concluída ainda',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Finalize uma lista para ver o histórico aqui.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _MonthFilterRow extends StatelessWidget {
  const _MonthFilterRow({
    required this.isDarkMode,
    required this.buckets,
    required this.selectedKey,
    required this.onSelected,
  });

  final bool isDarkMode;
  final List<_MonthBucket> buckets;
  final String? selectedKey;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (buckets.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: buckets.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == buckets.length) {
            return _FilterChip(
              isDarkMode: isDarkMode,
              label: 'Todos os meses',
              selected: false,
              onTap: () {},
            );
          }
          final bucket = buckets[index];
          final selected = bucket.key == selectedKey;
          return _FilterChip(
            isDarkMode: isDarkMode,
            label: bucket.chipLabel,
            selected: selected,
            showCheck: selected,
            onTap: () => onSelected(bucket.key),
          );
        },
      ),
    );
  }
}

class _StoreFilterRow extends StatelessWidget {
  const _StoreFilterRow({
    required this.isDarkMode,
    required this.selectedStore,
    required this.onSelected,
  });

  final bool isDarkMode;
  final String selectedStore;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _stores.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(left: 4, right: 4),
                child: Text(
                  'LOJA:',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDarkMode
                            ? FreshSproutColors.darkTextMuted
                            : FreshSproutColors.outline,
                        letterSpacing: 0.04,
                      ),
                ),
              ),
            );
          }
          final store = _stores[index - 1];
          final selected = store == selectedStore;
          return _FilterChip(
            isDarkMode: isDarkMode,
            label: store,
            selected: selected,
            compact: true,
            onTap: () => onSelected(store),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.isDarkMode,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showCheck = false,
    this.compact = false,
  });

  final bool isDarkMode;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showCheck;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final background = switch ((compact, selected)) {
      (true, true) => isDarkMode
          ? FreshSproutColors.darkBorder
          : FreshSproutColors.surfaceContainerHighest,
      (true, false) => isDarkMode
          ? FreshSproutColors.darkCard
          : FreshSproutColors.surfaceContainer,
      (false, true) => isDarkMode
          ? FreshSproutColors.darkAccent
          : FreshSproutColors.primary,
      (false, false) => isDarkMode
          ? FreshSproutColors.darkCard
          : FreshSproutColors.surfaceContainer,
    };

    return Material(
      color: background,
      borderRadius: FreshSproutRadius.fullBorder,
      elevation: selected && !compact ? 1 : 0,
      shadowColor: FreshSproutColors.shadowTint.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: FreshSproutRadius.fullBorder,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 4 : 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showCheck) ...[
                Icon(
                  Icons.check,
                  size: 16,
                  color: FreshSproutColors.onPrimary,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: selected && !compact
                          ? FreshSproutColors.onPrimary
                          : (isDarkMode
                              ? FreshSproutColors.darkTextSecondary
                              : FreshSproutColors.onSurfaceVariant),
                      fontSize: compact ? 10 : 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: compact ? 0.04 : 0.24,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletedListsHeader extends StatelessWidget {
  const _CompletedListsHeader({
    required this.isDarkMode,
    required this.periodLabel,
  });

  final bool isDarkMode;
  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'COMPRAS FINALIZADAS',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isDarkMode
                      ? FreshSproutColors.darkTextMuted
                      : FreshSproutColors.outline,
                  fontSize: 14,
                  letterSpacing: 0.01,
                ),
          ),
          Text(
            periodLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }
}

class _HistoryEmptyLists extends StatelessWidget {
  const _HistoryEmptyLists({required this.isDarkMode});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return _HistorySurfaceCard(
      isDarkMode: isDarkMode,
      child: Text(
        'Nenhuma compra neste período ou filtro selecionado.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _HistoryListCard extends StatelessWidget {
  const _HistoryListCard({
    required this.isDarkMode,
    required this.list,
    required this.store,
    required this.storeIcon,
    required this.savings,
    required this.hasReceipt,
    required this.onViewItems,
    required this.onRepeat,
  });

  final bool isDarkMode;
  final ShoppingList list;
  final String store;
  final IconData storeIcon;
  final double savings;
  final bool hasReceipt;
  final VoidCallback onViewItems;
  final VoidCallback onRepeat;

  @override
  Widget build(BuildContext context) {
    final accent =
        isDarkMode ? FreshSproutColors.darkAccent : FreshSproutColors.primary;
    final date = list.updatedAt;
    final dateLabel =
        '${date.day} de ${_monthLong[date.month - 1]}, ${date.year} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return _HistorySurfaceCard(
      isDarkMode: isDarkMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          list.name,
                          style:
                              Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                    height: 24 / 18,
                                  ),
                        ),
                        _CompletedBadge(isDarkMode: isDarkMode),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.event_outlined,
                            size: 16,
                            color: isDarkMode
                                ? FreshSproutColors.darkTextMuted
                                : FreshSproutColors.outline),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            dateLabel,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 12,
                                      height: 16 / 12,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'R\$ ${formatPrice(list.totalValue)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          height: 24 / 18,
                        ),
                  ),
                  Text(
                    'Economia: R\$ ${formatPrice(savings)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          letterSpacing: 0,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            color: isDarkMode
                ? FreshSproutColors.darkBorder
                : FreshSproutColors.surfaceContainer,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MetaItem(
                icon: storeIcon,
                label: store,
                iconColor: accent,
                isDarkMode: isDarkMode,
              ),
              Text('•',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                      )),
              _MetaItem(
                icon: Icons.checklist_outlined,
                label: '${list.items.length} itens',
                isDarkMode: isDarkMode,
              ),
              if (hasReceipt) ...[
                Text('•',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                        )),
                _MetaItem(
                  icon: Icons.receipt_outlined,
                  label: 'Nota anexada',
                  iconColor: accent,
                  labelColor: accent,
                  isDarkMode: isDarkMode,
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Divider(
            height: 1,
            color: FreshSproutColors.outlineVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _HistoryTextButton(
                isDarkMode: isDarkMode,
                icon: Icons.visibility_outlined,
                label: 'Ver Itens',
                onPressed: onViewItems,
              ),
              _HistoryPrimaryButton(
                isDarkMode: isDarkMode,
                icon: Icons.replay,
                label: 'Repetir Lista',
                onPressed: onRepeat,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompletedBadge extends StatelessWidget {
  const _CompletedBadge({required this.isDarkMode});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final accent =
        isDarkMode ? FreshSproutColors.darkAccent : FreshSproutColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isDarkMode
            ? FreshSproutColors.darkAccent.withValues(alpha: 0.12)
            : _HistorySpec.savingsMint,
        borderRadius: FreshSproutRadius.fullBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            'Concluída',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: accent,
                  fontSize: 10,
                  letterSpacing: 0,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.icon,
    required this.label,
    required this.isDarkMode,
    this.iconColor,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final bool isDarkMode;
  final Color? iconColor;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final muted = isDarkMode
        ? FreshSproutColors.darkTextMuted
        : FreshSproutColors.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: iconColor ?? muted),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: labelColor ?? muted,
                fontSize: 12,
              ),
        ),
      ],
    );
  }
}

class _HistoryTextButton extends StatelessWidget {
  const _HistoryTextButton({
    required this.isDarkMode,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final bool isDarkMode;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: _HistorySpec.buttonRadius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: _HistorySpec.buttonRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isDarkMode
                    ? FreshSproutColors.darkTextMuted
                    : FreshSproutColors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isDarkMode
                          ? FreshSproutColors.darkTextMuted
                          : FreshSproutColors.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryPrimaryButton extends StatelessWidget {
  const _HistoryPrimaryButton({
    required this.isDarkMode,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final bool isDarkMode;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final accent =
        isDarkMode ? FreshSproutColors.darkAccent : FreshSproutColors.primary;

    return Material(
      color: isDarkMode
          ? FreshSproutColors.darkAccent.withValues(alpha: 0.12)
          : _HistorySpec.savingsMint,
      borderRadius: _HistorySpec.buttonRadius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: _HistorySpec.buttonRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistorySurfaceCard extends StatelessWidget {
  const _HistorySurfaceCard({
    required this.isDarkMode,
    required this.child,
  });

  final bool isDarkMode;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(FreshSproutSpacing.md),
      decoration: BoxDecoration(
        color: isDarkMode
            ? FreshSproutColors.darkCard
            : FreshSproutColors.surfaceContainerLowest,
        borderRadius: _HistorySpec.cardRadius,
        border: Border.all(
          color: isDarkMode
              ? FreshSproutColors.darkBorder.withValues(alpha: 0.6)
              : FreshSproutColors.borderSubtle,
        ),
        boxShadow: isDarkMode ? null : FreshSproutElevation.level1,
      ),
      child: child,
    );
  }
}
