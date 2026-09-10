import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/shopping_list.dart';
import '../services/shopping_list_repository.dart';
import '../theme/fresh_sprout_tokens.dart';
import '../utils/date_formatter.dart';
import 'create_list_screen.dart';
import 'list_detail_screen.dart';

enum _ListFilter { all, inProgress, completed }

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _monthlyBudget = 2000.0;

  final _repository = ShoppingListRepository.instance;
  List<ShoppingList> _lists = [];
  _ListFilter _filter = _ListFilter.all;

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  void _loadLists() {
    setState(() {
      _lists = _repository.getAllLists();
    });
  }

  Future<void> _createList() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const CreateListScreen()),
    );

    if (created != true || !mounted) return;
    _loadLists();
  }

  Future<void> _openList(ShoppingList list) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ListDetailScreen(
          listId: list.id,
          isDarkMode: widget.isDarkMode,
        ),
      ),
    );
    _loadLists();
  }

  Future<void> _deleteList(ShoppingList list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir lista'),
          content: Text('Deseja excluir "${list.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    await _repository.deleteList(list.id);
    _loadLists();
  }

  double get _totalSpent =>
      _lists.fold(0.0, (sum, list) => sum + list.totalValue);

  int get _totalItems =>
      _lists.fold(0, (sum, list) => sum + list.items.length);

  int get _purchasedItems =>
      _lists.fold(0, (sum, list) => sum + list.purchasedCount);

  double get _overallProgress =>
      _totalItems == 0 ? 0 : _purchasedItems / _totalItems;

  int get _activeListsCount =>
      _lists.where((list) => list.isInProgress).length;

  int get _completedListsCount =>
      _lists.where((list) => list.isCompleted).length;

  double get _budgetUsedRatio =>
      (_totalSpent / _monthlyBudget).clamp(0.0, 1.0);

  int get _budgetUsedPercent => (_budgetUsedRatio * 100).round();

  double get _remainingBudget =>
      (_monthlyBudget - _totalSpent).clamp(0.0, double.infinity);

  double get _estimatedSavings =>
      _lists.isEmpty ? 0 : (_totalSpent * 0.129).clamp(0, double.infinity);

  List<ShoppingList> get _filteredLists {
    return switch (_filter) {
      _ListFilter.all => _lists,
      _ListFilter.inProgress =>
        _lists.where((list) => list.isInProgress).toList(),
      _ListFilter.completed =>
        _lists.where((list) => list.isCompleted).toList(),
    };
  }

  Color _titleColor() {
    return widget.isDarkMode
        ? FreshSproutColors.darkAccent
        : FreshSproutColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filtered = _filteredLists;
    final isDark = widget.isDarkMode;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _HomeHeaderBar(
              isDarkMode: isDark,
              titleColor: _titleColor(),
              onToggleTheme: widget.onToggleTheme,
              onCreateList: _createList,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _loadLists(),
                color: FreshSproutColors.primaryContainer,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    FreshSproutSpacing.marginMobile,
                    FreshSproutSpacing.xs,
                    FreshSproutSpacing.marginMobile,
                    FreshSproutSpacing.lg,
                  ),
                  children: [
                    _SpendingSummaryCard(
                      isDarkMode: isDark,
                      totalSpent: _totalSpent,
                      progress: _overallProgress,
                      purchasedItems: _purchasedItems,
                      totalItems: _totalItems,
                      monthlyBudget: _monthlyBudget,
                      budgetUsedRatio: _budgetUsedRatio,
                      budgetUsedPercent: _budgetUsedPercent,
                      remainingBudget: _remainingBudget,
                      onCreateList: _createList,
                    ),
                    const SizedBox(height: FreshSproutSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniStatCard(
                            isDarkMode: isDark,
                            icon: Icons.shopping_cart_outlined,
                            label: 'Listas ativas',
                            value: '$_activeListsCount pendentes',
                            iconBackground: isDark
                                ? FreshSproutColors.darkAccent
                                    .withValues(alpha: 0.15)
                                : FreshSproutColors.secondaryContainer
                                    .withValues(alpha: 0.4),
                            iconColor: isDark
                                ? FreshSproutColors.darkAccent
                                : FreshSproutColors.primary,
                            valueColor: isDark
                                ? FreshSproutColors.darkTextPrimary
                                : FreshSproutColors.onSurface,
                          ),
                        ),
                        const SizedBox(width: FreshSproutSpacing.xs),
                        Expanded(
                          child: _MiniStatCard(
                            isDarkMode: isDark,
                            icon: Icons.savings_outlined,
                            label: 'Economia estimada',
                            value: 'R\$ ${formatPrice(_estimatedSavings)}',
                            iconBackground: isDark
                                ? FreshSproutColors.darkAccent
                                    .withValues(alpha: 0.2)
                                : FreshSproutColors.tertiaryFixed
                                    .withValues(alpha: 0.6),
                            iconColor: isDark
                                ? FreshSproutColors.darkAccent
                                : FreshSproutColors.tertiary,
                            valueColor: isDark
                                ? FreshSproutColors.darkAccent
                                : FreshSproutColors.tertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: FreshSproutSpacing.md),
                    _ListsSectionHeader(
                      isDarkMode: isDark,
                      listCount: _lists.length,
                      titleColor: _titleColor(),
                    ),
                    const SizedBox(height: FreshSproutSpacing.xs),
                    _FilterRow(
                      isDarkMode: isDark,
                      filter: _filter,
                      inProgressCount: _activeListsCount,
                      completedCount: _completedListsCount,
                      onChanged: (filter) => setState(() => _filter = filter),
                    ),
                    const SizedBox(height: FreshSproutSpacing.xs),
                    if (_lists.isEmpty)
                      _EmptyState(
                        onCreateList: _createList,
                        accent: _titleColor(),
                      )
                    else if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: FreshSproutSpacing.xl,
                        ),
                        child: Center(
                          child: Text(
                            'Nenhuma lista neste filtro',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      )
                    else
                      ...filtered.asMap().entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: FreshSproutSpacing.xs,
                              ),
                              child: _ShoppingListCard(
                                list: entry.value,
                                index: entry.key,
                                isDarkMode: isDark,
                                onTap: () => _openList(entry.value),
                                onDelete: () => _deleteList(entry.value),
                              ),
                            ),
                          ),
                    if (_lists.isNotEmpty) ...[
                      const SizedBox(height: FreshSproutSpacing.xs),
                      _EconomyTipCard(
                        isDarkMode: isDark,
                        progress: _overallProgress,
                        budgetUsedPercent: _budgetUsedPercent,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _ShoppingListStatus on ShoppingList {
  bool get isCompleted => items.isNotEmpty && pendingCount == 0;

  bool get isInProgress => items.isNotEmpty && pendingCount > 0;

  double get progress =>
      items.isEmpty ? 0 : purchasedCount / items.length;
}

class _HomeHeaderBar extends StatelessWidget {
  const _HomeHeaderBar({
    required this.isDarkMode,
    required this.titleColor,
    required this.onToggleTheme,
    required this.onCreateList,
  });

  final bool isDarkMode;
  final Color titleColor;
  final VoidCallback onToggleTheme;
  final VoidCallback onCreateList;

  @override
  Widget build(BuildContext context) {
    final header = _HomeHeader(
      isDarkMode: isDarkMode,
      titleColor: titleColor,
      onToggleTheme: onToggleTheme,
      onCreateList: onCreateList,
    );

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isDarkMode
                ? FreshSproutColors.darkBackground.withValues(alpha: 0.95)
                : FreshSproutColors.surface.withValues(alpha: 0.95),
            border: Border(
              bottom: BorderSide(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.06)
                    : FreshSproutColors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FreshSproutSpacing.marginMobile,
              vertical: FreshSproutSpacing.xs,
            ),
            child: header,
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.isDarkMode,
    required this.titleColor,
    required this.onToggleTheme,
    required this.onCreateList,
  });

  final bool isDarkMode;
  final Color titleColor;
  final VoidCallback onToggleTheme;
  final VoidCallback onCreateList;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDarkMode
                      ? FreshSproutColors.darkAccent.withValues(alpha: 0.4)
                      : FreshSproutColors.primary.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: isDarkMode
                    ? FreshSproutColors.darkCard
                    : FreshSproutColors.secondaryContainer
                        .withValues(alpha: 0.35),
                child: Icon(
                  Icons.person,
                  color: isDarkMode
                      ? FreshSproutColors.darkAccent
                      : FreshSproutColors.primary,
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? FreshSproutColors.darkAccent
                      : FreshSproutColors.primaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDarkMode
                        ? FreshSproutColors.darkBackground
                        : FreshSproutColors.surface,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: FreshSproutSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá 👋',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isDarkMode
                          ? FreshSproutColors.darkTextMuted
                          : null,
                    ),
              ),
              Text(
                'Minhas Compras',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        _ThemeToggle(
          isDarkMode: isDarkMode,
          onToggle: onToggleTheme,
        ),
        const SizedBox(width: FreshSproutSpacing.xxs),
        _NotificationButton(isDarkMode: isDarkMode),
        _CreateListHeaderButton(
          isDarkMode: isDarkMode,
          onPressed: onCreateList,
        ),
      ],
    );
  }
}

class _CreateListHeaderButton extends StatelessWidget {
  const _CreateListHeaderButton({
    required this.isDarkMode,
    required this.onPressed,
  });

  final bool isDarkMode;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final accent = isDarkMode
        ? FreshSproutColors.darkAccent
        : FreshSproutColors.primary;

    return IconButton(
      onPressed: onPressed,
      tooltip: 'Criar lista',
      style: IconButton.styleFrom(
        foregroundColor: accent,
        minimumSize: const Size(40, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: const Icon(Icons.add, size: 26),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.isDarkMode});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            onPressed: () {},
            style: IconButton.styleFrom(
              foregroundColor: isDarkMode
                  ? FreshSproutColors.darkTextSecondary
                  : FreshSproutColors.onSurfaceVariant,
              shape: const CircleBorder(),
            ),
            icon: Icon(
              isDarkMode
                  ? Icons.notifications_outlined
                  : Icons.notifications_outlined,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? FreshSproutColors.darkAccent
                    : FreshSproutColors.tertiary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDarkMode
                      ? FreshSproutColors.darkBackground
                      : FreshSproutColors.surface,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({
    required this.isDarkMode,
    required this.onToggle,
  });

  final bool isDarkMode;
  final VoidCallback onToggle;

  static const _trackWidth = 70.0;
  static const _trackHeight = 36.0;
  static const _thumbSize = 28.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Alternar tema claro e escuro',
      child: GestureDetector(
        onTap: onToggle,
        child: Container(
          width: _trackWidth,
          height: _trackHeight,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDarkMode
                ? FreshSproutColors.darkCard
                : FreshSproutColors.surfaceContainer,
            borderRadius: BorderRadius.circular(_trackHeight / 2),
            border: Border.all(
              color: isDarkMode
                  ? FreshSproutColors.darkBorder.withValues(alpha: 0.3)
                  : FreshSproutColors.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: FreshSproutElevation.level1,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    Icons.light_mode,
                    size: 16,
                    color: Colors.amber.shade500.withValues(
                      alpha: isDarkMode ? 0.35 : 1,
                    ),
                  ),
                  Icon(
                    Icons.dark_mode,
                    size: 16,
                    color: isDarkMode
                        ? FreshSproutColors.darkAccent
                        : FreshSproutColors.darkAccent.withValues(alpha: 0.35),
                  ),
                ],
              ),
              AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                alignment: isDarkMode
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: _thumbSize,
                  height: _thumbSize,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? FreshSproutColors.darkAccent
                        : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isDarkMode ? Icons.dark_mode : Icons.wb_sunny,
                    size: 16,
                    color: isDarkMode
                        ? FreshSproutColors.darkBackground
                        : Colors.amber.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpendingSummaryCard extends StatelessWidget {
  const _SpendingSummaryCard({
    required this.isDarkMode,
    required this.totalSpent,
    required this.progress,
    required this.purchasedItems,
    required this.totalItems,
    required this.monthlyBudget,
    required this.budgetUsedRatio,
    required this.budgetUsedPercent,
    required this.remainingBudget,
    required this.onCreateList,
  });

  final bool isDarkMode;
  final double totalSpent;
  final double progress;
  final int purchasedItems;
  final int totalItems;
  final double monthlyBudget;
  final double budgetUsedRatio;
  final int budgetUsedPercent;
  final double remainingBudget;
  final VoidCallback onCreateList;

  @override
  Widget build(BuildContext context) {
    if (isDarkMode) {
      return _DarkHeroCard(
        totalSpent: totalSpent,
        monthlyBudget: monthlyBudget,
        budgetUsedRatio: budgetUsedRatio,
        budgetUsedPercent: budgetUsedPercent,
        remainingBudget: remainingBudget,
        onCreateList: onCreateList,
      );
    }

    return _LightHeroCard(
      totalSpent: totalSpent,
      monthlyBudget: monthlyBudget,
      budgetUsedRatio: budgetUsedRatio,
      budgetUsedPercent: budgetUsedPercent,
      remainingBudget: remainingBudget,
      onCreateList: onCreateList,
    );
  }
}

class _LightHeroCard extends StatelessWidget {
  const _LightHeroCard({
    required this.totalSpent,
    required this.monthlyBudget,
    required this.budgetUsedRatio,
    required this.budgetUsedPercent,
    required this.remainingBudget,
    required this.onCreateList,
  });

  final double totalSpent;
  final double monthlyBudget;
  final double budgetUsedRatio;
  final int budgetUsedPercent;
  final double remainingBudget;
  final VoidCallback onCreateList;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: FreshSproutDecorations.heroSummary(isDark: false),
      child: Stack(
        children: [
          Positioned(
            right: -48,
            top: -48,
            child: Container(
              width: 176,
              height: 176,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: FreshSproutColors.secondaryFixed.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -40,
            child: Container(
              width: 144,
              height: 144,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: FreshSproutColors.primaryFixedDim.withValues(alpha: 0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(FreshSproutSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'VOCÊ JÁ GASTOU ATÉ AGORA',
                        style: textTheme.labelMedium?.copyWith(
                          color: FreshSproutColors.onPrimaryContainer,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: FreshSproutColors.surfaceContainerLowest
                            .withValues(alpha: 0.15),
                        borderRadius: FreshSproutRadius.fullBorder,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: FreshSproutColors.secondaryFixed,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Dentro da meta',
                            style: textTheme.labelSmall?.copyWith(
                              color: FreshSproutColors.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: FreshSproutSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'R\$',
                      style: textTheme.headlineMedium?.copyWith(
                        color: FreshSproutColors.primaryFixed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: FreshSproutSpacing.xxs),
                    Text(
                      formatPrice(totalSpent),
                      style: textTheme.displayMedium?.copyWith(
                        color: FreshSproutColors.onPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.64,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: FreshSproutSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text.rich(
                      TextSpan(
                        style: textTheme.bodySmall?.copyWith(
                          color: FreshSproutColors.onPrimary.withValues(
                            alpha: 0.9,
                          ),
                        ),
                        children: [
                          const TextSpan(text: 'Meta mensal: '),
                          TextSpan(
                            text: 'R\$ ${formatPrice(monthlyBudget)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$budgetUsedPercent% utilizado',
                      style: textTheme.bodySmall?.copyWith(
                        color: FreshSproutColors.secondaryFixed,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                FreshSproutProgressBar(
                  value: budgetUsedRatio,
                  height: 8,
                  trackColor: Colors.black.withValues(alpha: 0.25),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 14,
                          color: FreshSproutColors.primaryFixedDim,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+4% em relação ao mês anterior',
                          style: textTheme.labelSmall?.copyWith(
                            color: FreshSproutColors.primaryFixedDim,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Resta R\$ ${formatPrice(remainingBudget)}',
                      style: textTheme.labelSmall?.copyWith(
                        color: FreshSproutColors.primaryFixedDim,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: FreshSproutSpacing.xs),
                Divider(
                  color: Colors.white.withValues(alpha: 0.1),
                  height: FreshSproutSpacing.md,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _HeroActionButton(
                        label: 'Nova Lista',
                        icon: Icons.add_circle_outline,
                        backgroundColor:
                            FreshSproutColors.surfaceContainerLowest,
                        foregroundColor: FreshSproutColors.primary,
                        onPressed: onCreateList,
                      ),
                    ),
                    const SizedBox(width: FreshSproutSpacing.xs),
                    Expanded(
                      child: _HeroActionButton(
                        label: 'Ver Histórico',
                        icon: Icons.receipt_long_outlined,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        foregroundColor: FreshSproutColors.onPrimary,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Em breve')),
                          );
                        },
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

class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: FreshSproutRadius.lgBorder,
      child: InkWell(
        onTap: onPressed,
        borderRadius: FreshSproutRadius.lgBorder,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: FreshSproutSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foregroundColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: foregroundColor,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DarkHeroCard extends StatelessWidget {
  const _DarkHeroCard({
    required this.totalSpent,
    required this.monthlyBudget,
    required this.budgetUsedRatio,
    required this.budgetUsedPercent,
    required this.remainingBudget,
    required this.onCreateList,
  });

  final double totalSpent;
  final double monthlyBudget;
  final double budgetUsedRatio;
  final int budgetUsedPercent;
  final double remainingBudget;
  final VoidCallback onCreateList;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: FreshSproutDecorations.heroSummary(isDark: true),
      child: Stack(
        children: [
          Positioned(
            right: -48,
            top: -48,
            child: Container(
              width: 176,
              height: 176,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: FreshSproutColors.darkAccent.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -40,
            child: Container(
              width: 144,
              height: 144,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: FreshSproutColors.darkAccent.withValues(alpha: 0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(FreshSproutSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'VOCÊ JÁ GASTOU ATÉ AGORA',
                        style: textTheme.labelMedium?.copyWith(
                          color: FreshSproutColors.darkTextSecondary,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: FreshSproutRadius.fullBorder,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: FreshSproutColors.darkAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Dentro da meta',
                            style: textTheme.labelSmall?.copyWith(
                              color: FreshSproutColors.darkTextPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: FreshSproutSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'R\$',
                      style: textTheme.headlineMedium?.copyWith(
                        color: FreshSproutColors.darkAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: FreshSproutSpacing.xxs),
                    Text(
                      formatPrice(totalSpent),
                      style: textTheme.displayMedium?.copyWith(
                        color: FreshSproutColors.darkTextPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.64,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: FreshSproutSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text.rich(
                      TextSpan(
                        style: textTheme.bodySmall?.copyWith(
                          color: FreshSproutColors.darkTextSecondary,
                        ),
                        children: [
                          const TextSpan(text: 'Meta mensal: '),
                          TextSpan(
                            text: 'R\$ ${formatPrice(monthlyBudget)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$budgetUsedPercent% utilizado',
                      style: textTheme.bodySmall?.copyWith(
                        color: FreshSproutColors.darkAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                FreshSproutProgressBar(
                  value: budgetUsedRatio,
                  height: 8,
                  isDark: true,
                  trackColor: Colors.black.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 14,
                          color: FreshSproutColors.darkTextMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+4% em relação ao mês anterior',
                          style: textTheme.labelSmall?.copyWith(
                            color: FreshSproutColors.darkTextMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Resta R\$ ${formatPrice(remainingBudget)}',
                      style: textTheme.labelSmall?.copyWith(
                        color: FreshSproutColors.darkTextSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: FreshSproutSpacing.xs),
                Divider(
                  color: Colors.white.withValues(alpha: 0.08),
                  height: FreshSproutSpacing.md,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _HeroActionButton(
                        label: 'Nova Lista',
                        icon: Icons.add_circle_outline,
                        backgroundColor: FreshSproutColors.darkAccent,
                        foregroundColor: FreshSproutColors.darkBackground,
                        onPressed: onCreateList,
                      ),
                    ),
                    const SizedBox(width: FreshSproutSpacing.xs),
                    Expanded(
                      child: _HeroActionButton(
                        label: 'Ver Histórico',
                        icon: Icons.receipt_long_outlined,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        foregroundColor: FreshSproutColors.darkTextPrimary,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Em breve')),
                          );
                        },
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

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.isDarkMode,
    required this.icon,
    required this.label,
    required this.value,
    required this.iconBackground,
    required this.iconColor,
    required this.valueColor,
  });

  final bool isDarkMode;
  final IconData icon;
  final String label;
  final String value;
  final Color iconBackground;
  final Color iconColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(FreshSproutSpacing.sm),
      decoration: BoxDecoration(
        color: isDarkMode
            ? FreshSproutColors.darkCard
            : FreshSproutColors.surfaceContainerLowest,
        borderRadius: FreshSproutRadius.lgBorder,
        border: Border.all(
          color: isDarkMode
              ? FreshSproutColors.darkBorder
              : FreshSproutColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: FreshSproutElevation.level1,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: FreshSproutRadius.mdBorder,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: FreshSproutSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDarkMode
                            ? FreshSproutColors.darkTextMuted
                            : null,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: valueColor,
                        fontWeight: FontWeight.w700,
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

class _ListsSectionHeader extends StatelessWidget {
  const _ListsSectionHeader({
    required this.isDarkMode,
    required this.listCount,
    required this.titleColor,
  });

  final bool isDarkMode;
  final int listCount;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Minhas Listas de Compras',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(width: FreshSproutSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? FreshSproutColors.darkCard
                    : FreshSproutColors.surfaceContainer,
                borderRadius: FreshSproutRadius.fullBorder,
                border: Border.all(
                  color: isDarkMode
                      ? FreshSproutColors.darkBorder
                      : FreshSproutColors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                '$listCount',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDarkMode
                          ? FreshSproutColors.darkTextSecondary
                          : null,
                    ),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: titleColor,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                children: [
                  Text(
                    'Ver todas',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Icon(Icons.chevron_right, size: 16, color: titleColor),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.isDarkMode,
    required this.filter,
    required this.inProgressCount,
    required this.completedCount,
    required this.onChanged,
  });

  final bool isDarkMode;
  final _ListFilter filter;
  final int inProgressCount;
  final int completedCount;
  final ValueChanged<_ListFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'Todas',
            selected: filter == _ListFilter.all,
            isDarkMode: isDarkMode,
            onTap: () => onChanged(_ListFilter.all),
          ),
          const SizedBox(width: FreshSproutSpacing.xs),
          _FilterChip(
            label: 'Em andamento ($inProgressCount)',
            selected: filter == _ListFilter.inProgress,
            isDarkMode: isDarkMode,
            onTap: () => onChanged(_ListFilter.inProgress),
          ),
          const SizedBox(width: FreshSproutSpacing.xs),
          _FilterChip(
            label: 'Concluídas ($completedCount)',
            selected: filter == _ListFilter.completed,
            isDarkMode: isDarkMode,
            onTap: () => onChanged(_ListFilter.completed),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.isDarkMode,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isDarkMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: FreshSproutSpacing.chipHeight,
        padding: const EdgeInsets.symmetric(horizontal: FreshSproutSpacing.md),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? (isDarkMode
                  ? FreshSproutColors.darkAccent
                  : FreshSproutColors.primary)
              : (isDarkMode
                  ? FreshSproutColors.darkCard
                  : FreshSproutColors.surfaceContainerLow),
          borderRadius: FreshSproutRadius.fullBorder,
          border: !selected && isDarkMode
              ? Border.all(color: FreshSproutColors.darkBorder)
              : null,
          boxShadow: selected ? FreshSproutElevation.level1 : null,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected
                    ? (isDarkMode
                        ? FreshSproutColors.darkBackground
                        : FreshSproutColors.onPrimary)
                    : (isDarkMode
                        ? FreshSproutColors.darkTextSecondary
                        : FreshSproutColors.onSurfaceVariant),
                fontWeight: selected && isDarkMode
                    ? FontWeight.w700
                    : FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class _ListCardStyle {
  const _ListCardStyle({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.progressColor,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final Color progressColor;
}

class _ShoppingListCard extends StatelessWidget {
  const _ShoppingListCard({
    required this.list,
    required this.index,
    required this.isDarkMode,
    required this.onTap,
    required this.onDelete,
  });

  final ShoppingList list;
  final int index;
  final bool isDarkMode;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  static const _activeStyles = [
    _ListCardStyle(
      icon: Icons.shopping_cart_outlined,
      iconBackground: Color(0x1A006745),
      iconColor: FreshSproutColors.primary,
      progressColor: FreshSproutColors.primary,
    ),
    _ListCardStyle(
      icon: Icons.eco_outlined,
      iconBackground: Color(0x4D7EFABC),
      iconColor: FreshSproutColors.secondary,
      progressColor: FreshSproutColors.secondary,
    ),
  ];

  _ListCardStyle _styleFor(bool completed) {
    if (completed) {
      return _ListCardStyle(
        icon: Icons.check_circle_outline,
        iconBackground: isDarkMode
            ? FreshSproutColors.darkBackground
            : FreshSproutColors.surfaceContainerHigh,
        iconColor: isDarkMode
            ? FreshSproutColors.darkTextMuted
            : FreshSproutColors.onSurfaceVariant,
        progressColor: isDarkMode
            ? FreshSproutColors.darkBorder
            : FreshSproutColors.outlineVariant,
      );
    }
    if (isDarkMode) {
      return _ListCardStyle(
        icon: index.isEven
            ? Icons.shopping_cart_outlined
            : Icons.eco_outlined,
        iconBackground:
            FreshSproutColors.darkAccent.withValues(alpha: 0.15),
        iconColor: FreshSproutColors.darkAccent,
        progressColor: FreshSproutColors.darkAccent,
      );
    }
    return _activeStyles[index % _activeStyles.length];
  }

  @override
  Widget build(BuildContext context) {
    final completed = list.isCompleted;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final totalItems = list.items.length;
    final style = _styleFor(completed);
    final surfaceColor = isDarkMode
        ? FreshSproutColors.darkCard.withValues(alpha: completed ? 0.8 : 1)
        : FreshSproutColors.surfaceContainerLowest
            .withValues(alpha: completed ? 0.8 : 1);

    return Opacity(
      opacity: completed ? 0.9 : 1,
      child: Material(
        color: surfaceColor,
        borderRadius: FreshSproutRadius.lgBorder,
        child: InkWell(
          onTap: onTap,
          borderRadius: FreshSproutRadius.lgBorder,
          child: Container(
            padding: const EdgeInsets.all(FreshSproutSpacing.md),
            decoration: BoxDecoration(
              borderRadius: FreshSproutRadius.lgBorder,
              border: Border.all(
                color: isDarkMode
                    ? FreshSproutColors.darkBorder.withValues(
                        alpha: completed ? 0.8 : 1,
                      )
                    : FreshSproutColors.outlineVariant.withValues(
                        alpha: completed ? 0.3 : 0.4,
                      ),
              ),
              boxShadow: FreshSproutElevation.level1,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: style.iconBackground,
                        borderRadius: FreshSproutRadius.lgBorder,
                      ),
                      child: Icon(style.icon, color: style.iconColor, size: 24),
                    ),
                    const SizedBox(width: FreshSproutSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            list.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  decoration: completed
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: completed
                                      ? (isDarkMode
                                          ? FreshSproutColors.darkTextMuted
                                          : muted.withValues(alpha: 0.8))
                                      : (isDarkMode
                                          ? FreshSproutColors.darkTextPrimary
                                          : FreshSproutColors.onSurface),
                                ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                completed
                                    ? Icons.check_circle_outline
                                    : Icons.schedule_outlined,
                                size: 14,
                                color: muted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  completed
                                      ? 'Finalizada em ${formatRelativeDate(list.updatedAt)}'
                                      : 'Atualizado ${formatRelativeDate(list.updatedAt)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: muted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(completed: completed, isDarkMode: isDarkMode),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: isDarkMode
                            ? FreshSproutColors.darkTextMuted
                            : FreshSproutColors.outline,
                        size: 20,
                      ),
                      onSelected: (value) {
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Excluir'),
                        ),
                      ],
                    ),
                  ],
                ),
                if (totalItems > 0) ...[
                  const SizedBox(height: FreshSproutSpacing.xs),
                  Row(
                    children: [
                      Text(
                        completed
                            ? '${list.purchasedCount}/$totalItems itens (100%)'
                            : '${list.purchasedCount} de $totalItems itens comprados',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: muted,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        'R\$ ${formatPrice(list.totalValue)}',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: completed
                                  ? (isDarkMode
                                      ? FreshSproutColors.darkTextPrimary
                                      : FreshSproutColors.onSurface)
                                  : (isDarkMode
                                      ? FreshSproutColors.darkAccent
                                      : FreshSproutColors.primary),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: FreshSproutSpacing.xs),
                  FreshSproutProgressBar(
                    value: list.progress,
                    height: 8,
                    isDark: isDarkMode,
                    fillColor: style.progressColor,
                    gradient: null,
                    trackColor: isDarkMode
                        ? FreshSproutColors.darkProgressTrack
                        : FreshSproutColors.surfaceContainer,
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(top: FreshSproutSpacing.sm),
                    child: Text(
                      'Nenhum item adicionado',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.completed,
    required this.isDarkMode,
  });

  final bool completed;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4, right: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: completed
            ? (isDarkMode
                ? FreshSproutColors.darkBackground
                : FreshSproutColors.surfaceContainer)
            : FreshSproutColors.secondaryContainer.withValues(
                alpha: isDarkMode ? 0.2 : 0.6,
              ),
        borderRadius: FreshSproutRadius.fullBorder,
        border: !completed && isDarkMode
            ? Border.all(
                color: FreshSproutColors.darkAccent.withValues(alpha: 0.3),
              )
            : completed && isDarkMode
                ? Border.all(color: FreshSproutColors.darkBorder)
                : null,
      ),
      child: Text(
        completed ? 'Concluída' : 'Em andamento',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: completed
                  ? (isDarkMode
                      ? FreshSproutColors.darkTextSecondary
                      : FreshSproutColors.onSurfaceVariant)
                  : (isDarkMode
                      ? FreshSproutColors.darkAccent
                      : FreshSproutColors.onSecondaryContainer),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _EconomyTipCard extends StatelessWidget {
  const _EconomyTipCard({
    required this.isDarkMode,
    required this.progress,
    required this.budgetUsedPercent,
  });

  final bool isDarkMode;
  final double progress;
  final int budgetUsedPercent;

  @override
  Widget build(BuildContext context) {
    final itemsPercent = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(FreshSproutSpacing.sm),
      decoration: BoxDecoration(
        color: isDarkMode
            ? FreshSproutColors.darkCard
            : FreshSproutColors.surfaceContainerLow,
        borderRadius: FreshSproutRadius.lgBorder,
        border: Border.all(
          color: isDarkMode
              ? FreshSproutColors.darkBorder
              : FreshSproutColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: FreshSproutElevation.level1,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? FreshSproutColors.darkAccent.withValues(alpha: 0.2)
                  : FreshSproutColors.secondaryFixed.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lightbulb_outline,
              size: 18,
              color: isDarkMode
                  ? FreshSproutColors.darkAccent
                  : FreshSproutColors.secondary,
            ),
          ),
          const SizedBox(width: FreshSproutSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dica de Economia',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDarkMode
                            ? FreshSproutColors.darkTextPrimary
                            : FreshSproutColors.onSurface,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Você já comprou $itemsPercent% dos itens essenciais '
                  'gastando $budgetUsedPercent% do orçamento estimado. '
                  'Bom trabalho mantendo o foco nas promoções!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDarkMode
                            ? FreshSproutColors.darkTextMuted
                            : FreshSproutColors.onSurfaceVariant,
                        height: 1.45,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.onCreateList,
    required this.accent,
  });

  final VoidCallback onCreateList;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: accent.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma lista ainda',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Crie sua primeira lista de compras.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onCreateList,
            icon: const Icon(Icons.add),
            label: const Text('Criar lista'),
          ),
        ],
      ),
    );
  }
}
