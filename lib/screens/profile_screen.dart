import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/shopping_list.dart';
import '../services/shopping_list_repository.dart';
import '../theme/fresh_sprout_tokens.dart';
import '../utils/date_formatter.dart';

const _avatarUrl =
    'https://lh3.googleusercontent.com/aida-public/AB6AXuCKMGCwpB9NizrcnzidmmDvJlJGNAhU6Yby03R3GoJOTJEQwR3KVcb-PfzOyVXLFewQoMwegYLKsqn6HIYjy_E8NImAQEdrHrGhhZSsvTNu9YYwB9qn3ptGM9EGf_EeXouJaSAotdZWg_nW7KjvzDqdT2jG_Os9Kw64h56Q7tBiskGcyFkPJsVR7EC7f8hxxrALijXMSpy_BRVhYWmlYDsBc2FEbXhnJGnxTUnRWSD6rJGQIbvGa7XJNQ';

const _monthShort = [
  'Jan',
  'Fev',
  'Mar',
  'Abr',
  'Mai',
  'Jun',
  'Jul',
  'Ago',
  'Set',
  'Out',
  'Nov',
  'Dez',
];

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

/// Medidas do mockup HTML (Tailwind: rounded-xl=12px, rounded-lg=8px).
abstract final class _ProfileSpec {
  static final cardRadius = FreshSproutRadius.lgBorder;
  static final buttonRadius = FreshSproutRadius.mdBorder;
  static const switchWidth = 44.0;
  static const switchHeight = 24.0;
  static const switchThumb = 20.0;
  static const btnHPad = 14.0;
  static const btnVPad = 6.0;
  static const iconBtnSize = 40.0;
  static const headerIconSize = 36.0;
  static const sectionIconSize = 32.0;
  static const rowIconSize = 36.0;
  static const metricIconSize = 28.0;
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _monthlyBudget = 2000.0;

  final _repository = ShoppingListRepository.instance;
  bool _promoAlertsEnabled = true;

  List<ShoppingList> get _lists => _repository.getAllLists();

  double get _totalSpent =>
      _lists.fold(0.0, (sum, list) => sum + list.totalValue);

  int get _completedListsCount =>
      _lists.where((list) => _isListCompleted(list)).length;

  double get _estimatedSavings =>
      _lists.isEmpty ? 0 : (_totalSpent * 0.129).clamp(0, double.infinity);

  double get _budgetUsedRatio =>
      (_totalSpent / _monthlyBudget).clamp(0.0, 1.0);

  int get _budgetUsedPercent => (_budgetUsedRatio * 100).round();

  double get _remainingBudget =>
      (_monthlyBudget - _totalSpent).clamp(0.0, double.infinity);

  String get _memberSince {
    if (_lists.isEmpty) return 'Desde Jan 2023';
    final earliest = _lists
        .map((list) => list.createdAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    return 'Desde ${_monthShort[earliest.month - 1]} ${earliest.year}';
  }

  String get _currentMonthLabel {
    final now = DateTime.now();
    return _monthLong[now.month - 1];
  }

  bool _isListCompleted(ShoppingList list) =>
      list.items.isNotEmpty && list.pendingCount == 0;

  bool get _allItemsChecked {
    if (_lists.isEmpty) return false;
    return _lists.every(
      (list) => list.items.isEmpty || list.purchasedCount == list.items.length,
    );
  }

  void _showSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature — em breve')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final monthlySpent = _totalSpent;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _ProfileHeader(isDarkMode: isDark),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                FreshSproutSpacing.marginMobile,
                FreshSproutSpacing.xs,
                FreshSproutSpacing.marginMobile,
                FreshSproutSpacing.lg,
              ),
              children: [
                _ProfileHeroCard(
                  isDarkMode: isDark,
                  memberSince: _memberSince,
                  onEdit: () => _showSoon('Editar perfil'),
                  onShare: () => _showSoon('Compartilhar perfil'),
                ),
                const SizedBox(height: FreshSproutSpacing.md),
                _PersonalMetricsSection(
                  isDarkMode: isDark,
                  totalSaved: _estimatedSavings,
                  completedLists: _completedListsCount,
                  allItemsChecked: _allItemsChecked,
                  monthlyAverage: monthlySpent,
                ),
                const SizedBox(height: FreshSproutSpacing.md),
                _BudgetPlanningSection(
                  isDarkMode: isDark,
                  monthLabel: _currentMonthLabel,
                  monthlySpent: monthlySpent,
                  monthlyBudget: _monthlyBudget,
                  budgetUsedRatio: _budgetUsedRatio,
                  budgetUsedPercent: _budgetUsedPercent,
                  remainingBudget: _remainingBudget,
                  onAdjust: () => _showSoon('Ajustar orçamento'),
                  onAddFavorite: () => _showSoon('Adicionar mercado'),
                ),
                const SizedBox(height: FreshSproutSpacing.md),
                _PreferencesSection(
                  isDarkMode: isDark,
                  promoAlertsEnabled: _promoAlertsEnabled,
                  onToggleTheme: widget.onToggleTheme,
                  onPromoAlertsChanged: (value) {
                    setState(() => _promoAlertsEnabled = value);
                  },
                ),
                const SizedBox(height: FreshSproutSpacing.md),
                _AccountSupportSection(
                  isDarkMode: isDark,
                  onExport: () => _showSoon('Exportar relatório'),
                  onHelp: () => _showSoon('Ajuda e suporte'),
                  onPrivacy: () => _showSoon('Termos e privacidade'),
                  onLogout: () => _showSoon('Sair da conta'),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    top: FreshSproutSpacing.xs,
                    bottom: FreshSproutSpacing.lg,
                  ),
                  child: Text(
                    'Versão 2.4.1 (Build 184) • Minhas Compras',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? FreshSproutColors.darkTextMuted
                              : FreshSproutColors.outline,
                          letterSpacing: 0.4,
                          fontSize: 10,
                          height: 14 / 10,
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.isDarkMode});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final titleColor =
        isDarkMode ? FreshSproutColors.inversePrimary : FreshSproutColors.primary;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: (isDarkMode
                  ? FreshSproutColors.darkBackground
                  : FreshSproutColors.surface)
              .withValues(alpha: 0.92),
          padding: const EdgeInsets.symmetric(
            horizontal: FreshSproutSpacing.marginMobile,
            vertical: FreshSproutSpacing.xs,
          ),
          child: Row(
            children: [
              Container(
                width: _ProfileSpec.headerIconSize,
                height: _ProfileSpec.headerIconSize,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? FreshSproutColors.darkCard
                      : FreshSproutColors.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: 20,
                  color: isDarkMode
                      ? FreshSproutColors.darkAccent
                      : FreshSproutColors.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: FreshSproutSpacing.xs),
              Text(
                'Meu Perfil',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      height: 24 / 18,
                    ),
              ),
              const Spacer(),
              _HeaderIconButton(
                icon: Icons.notifications_outlined,
                isDarkMode: isDarkMode,
                onPressed: () {},
              ),
              const SizedBox(width: FreshSproutSpacing.xxs),
              _HeaderIconButton(
                icon: Icons.settings_outlined,
                isDarkMode: isDarkMode,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
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
      width: _ProfileSpec.iconBtnSize,
      height: _ProfileSpec.iconBtnSize,
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

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.isDarkMode,
    required this.memberSince,
    required this.onEdit,
    required this.onShare,
  });

  final bool isDarkMode;
  final String memberSince;
  final VoidCallback onEdit;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final onSurface = isDarkMode
        ? FreshSproutColors.darkTextPrimary
        : FreshSproutColors.onSurface;
    final onSurfaceVariant = isDarkMode
        ? FreshSproutColors.darkTextMuted
        : FreshSproutColors.onSurfaceVariant;

    return _ProfileSurfaceCard(
      isDarkMode: isDarkMode,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 480;

          final identityDetails = Column(
            crossAxisAlignment:
                isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Matheus Silva',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 22,
                                  height: 28 / 22,
                                ),
                          ),
                          Text(
                            'matheus.silva@email.com',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: onSurfaceVariant,
                                  fontSize: 12,
                                  height: 16 / 12,
                                ),
                          ),
                        ],
                      ),
                    ),
                    _MemberSinceChip(
                      isDarkMode: isDarkMode,
                      label: memberSince,
                    ),
                  ],
                )
              else ...[
                Text(
                  'Matheus Silva',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 22,
                        height: 28 / 22,
                      ),
                ),
                Text(
                  'matheus.silva@email.com',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: onSurfaceVariant,
                        fontSize: 12,
                        height: 16 / 12,
                      ),
                ),
                const SizedBox(height: FreshSproutSpacing.xxs),
                _MemberSinceChip(
                  isDarkMode: isDarkMode,
                  label: memberSince,
                ),
              ],
              const SizedBox(height: FreshSproutSpacing.xs),
              Text(
                'Organizando compras conscientes, otimizando o orçamento de feira e controlando gastos domésticos.',
                textAlign: isWide ? TextAlign.start : TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: onSurfaceVariant,
                      fontSize: 12,
                      height: 16 / 12,
                    ),
              ),
              const SizedBox(height: FreshSproutSpacing.sm),
              Wrap(
                alignment:
                    isWide ? WrapAlignment.start : WrapAlignment.center,
                spacing: FreshSproutSpacing.xs,
                runSpacing: FreshSproutSpacing.xs,
                children: [
                  _ProfileCompactButton(
                    isDarkMode: isDarkMode,
                    icon: Icons.edit_outlined,
                    label: 'Editar Perfil',
                    filled: true,
                    onPressed: onEdit,
                  ),
                  _ProfileCompactButton(
                    isDarkMode: isDarkMode,
                    icon: Icons.share_outlined,
                    label: 'Compartilhar Perfil',
                    filled: false,
                    onPressed: onShare,
                  ),
                ],
              ),
            ],
          );

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -48,
                top: -48,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
                  child: Container(
                    width: 144,
                    height: 144,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (isDarkMode
                              ? FreshSproutColors.darkAccent
                              : FreshSproutColors.secondaryContainer)
                          .withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AvatarSection(isDarkMode: isDarkMode),
                    const SizedBox(width: FreshSproutSpacing.md),
                    Expanded(child: identityDetails),
                  ],
                )
              else
                Column(
                  children: [
                    _AvatarSection(isDarkMode: isDarkMode),
                    const SizedBox(height: FreshSproutSpacing.md),
                    identityDetails,
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({required this.isDarkMode});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          width: 96,
          height: 96,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [
                      FreshSproutColors.darkAccent,
                      FreshSproutColors.primaryContainer,
                    ]
                  : [
                      FreshSproutColors.primary,
                      FreshSproutColors.secondaryFixed,
                    ],
            ),
            border: Border.all(
              color: isDarkMode
                  ? FreshSproutColors.darkBackground
                  : FreshSproutColors.surfaceContainerLowest,
              width: 2,
            ),
            boxShadow: FreshSproutElevation.level1,
          ),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: FreshSproutColors.surfaceContainerHigh,
            ),
            child: ClipOval(
              child: Image.network(
                _avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Text(
                    'MS',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: FreshSproutColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? FreshSproutColors.primaryContainer
                  : FreshSproutColors.primaryContainer,
              borderRadius: FreshSproutRadius.fullBorder,
              border: Border.all(
                color: isDarkMode
                    ? FreshSproutColors.darkBackground
                    : FreshSproutColors.surfaceContainerLowest,
              ),
              boxShadow: FreshSproutElevation.level1,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified,
                  size: 12,
                  color: isDarkMode
                      ? FreshSproutColors.onPrimaryContainer
                      : FreshSproutColors.onPrimaryContainer,
                ),
                const SizedBox(width: 4),
                Text(
                  'Membro Pro',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: FreshSproutColors.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MemberSinceChip extends StatelessWidget {
  const _MemberSinceChip({
    required this.isDarkMode,
    required this.label,
  });

  final bool isDarkMode;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode
            ? FreshSproutColors.darkCard
            : FreshSproutColors.surfaceContainerLow,
        borderRadius: FreshSproutRadius.fullBorder,
        border: Border.all(
          color: isDarkMode
              ? FreshSproutColors.darkBorder
              : FreshSproutColors.surfaceContainer,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 13,
            color: isDarkMode
                ? FreshSproutColors.darkAccent
                : FreshSproutColors.secondary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDarkMode
                      ? FreshSproutColors.darkAccent
                      : FreshSproutColors.secondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: 0,
                ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCompactButton extends StatelessWidget {
  const _ProfileCompactButton({
    required this.isDarkMode,
    required this.icon,
    required this.label,
    required this.filled,
    required this.onPressed,
  });

  final bool isDarkMode;
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final accent =
        isDarkMode ? FreshSproutColors.darkAccent : FreshSproutColors.primary;
    final foreground = filled ? accent : FreshSproutColors.onSurfaceVariant;
    final background = filled
        ? (isDarkMode
            ? FreshSproutColors.darkCard
            : FreshSproutColors.surfaceContainerLow)
        : (isDarkMode
            ? FreshSproutColors.darkBackground
            : FreshSproutColors.surfaceBright);

    return Material(
      color: background,
      borderRadius: _ProfileSpec.buttonRadius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: _ProfileSpec.buttonRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: _ProfileSpec.btnHPad,
            vertical: _ProfileSpec.btnVPad,
          ),
          decoration: BoxDecoration(
            borderRadius: _ProfileSpec.buttonRadius,
            border: filled
                ? null
                : Border.all(
                    color: isDarkMode
                        ? FreshSproutColors.darkBorder
                        : FreshSproutColors.outlineVariant
                            .withValues(alpha: 0.4),
                  ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      height: 16 / 12,
                      letterSpacing: 0.24,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonalMetricsSection extends StatelessWidget {
  const _PersonalMetricsSection({
    required this.isDarkMode,
    required this.totalSaved,
    required this.completedLists,
    required this.allItemsChecked,
    required this.monthlyAverage,
  });

  final bool isDarkMode;
  final double totalSaved;
  final int completedLists;
  final bool allItemsChecked;
  final double monthlyAverage;

  @override
  Widget build(BuildContext context) {
    final accent =
        isDarkMode ? FreshSproutColors.darkAccent : FreshSproutColors.primary;

    final metrics = [
      _MetricCard(
        isDarkMode: isDarkMode,
        label: 'Total Economizado',
        value: 'R\$ ${formatPrice(totalSaved)}',
        icon: Icons.savings_outlined,
        iconBackground: FreshSproutColors.secondaryContainer.withValues(
          alpha: isDarkMode ? 0.3 : 0.4,
        ),
        valueColor: accent,
        footer: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.arrow_upward,
              size: 13,
              color: isDarkMode
                  ? FreshSproutColors.darkAccent
                  : FreshSproutColors.secondary,
            ),
            const SizedBox(width: 2),
            Text(
              '+14% vs. mês anterior',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDarkMode
                        ? FreshSproutColors.darkAccent
                        : FreshSproutColors.secondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    height: 1,
                    letterSpacing: 0,
                  ),
            ),
          ],
        ),
      ),
      _MetricCard(
        isDarkMode: isDarkMode,
        label: 'Listas Concluídas',
        value: '$completedLists listas',
        icon: Icons.task_alt_outlined,
        iconBackground: isDarkMode
            ? FreshSproutColors.darkCard
            : FreshSproutColors.surfaceContainer,
        footer: Text(
          allItemsChecked
              ? '100% de itens conferidos'
              : 'Itens em conferência',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDarkMode
                    ? FreshSproutColors.darkTextMuted
                    : FreshSproutColors.onSurfaceVariant,
                fontSize: 12,
                height: 16 / 12,
              ),
        ),
      ),
      _MetricCard(
        isDarkMode: isDarkMode,
        label: 'Média Mensal',
        value: 'R\$ ${formatPrice(monthlyAverage)}',
        icon: Icons.insights_outlined,
        iconBackground: isDarkMode
            ? FreshSproutColors.darkCard
            : FreshSproutColors.surfaceContainer,
        footer: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: FreshSproutColors.secondaryContainer.withValues(
              alpha: isDarkMode ? 0.2 : 0.3,
            ),
            borderRadius: FreshSproutRadius.smBorder,
          ),
          child: Text(
            'Sob controle',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  height: 1,
                  letterSpacing: 0,
                ),
          ),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Resumo Pessoal',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: isDarkMode
                        ? FreshSproutColors.darkTextPrimary
                        : FreshSproutColors.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    height: 24 / 18,
                  ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.trending_up, size: 15, color: accent),
                const SizedBox(width: 2),
                Text(
                  'Visão Geral',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isDarkMode
                            ? FreshSproutColors.darkAccent
                            : FreshSproutColors.secondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 16 / 12,
                      ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: FreshSproutSpacing.xs),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 640) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < metrics.length; i++) ...[
                    if (i > 0) const SizedBox(width: FreshSproutSpacing.xs),
                    Expanded(child: metrics[i]),
                  ],
                ],
              );
            }
            return Column(
              children: [
                for (var i = 0; i < metrics.length; i++) ...[
                  if (i > 0) const SizedBox(height: FreshSproutSpacing.xs),
                  metrics[i],
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.isDarkMode,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBackground,
    this.valueColor,
    this.footer,
  });

  final bool isDarkMode;
  final String label;
  final String value;
  final IconData icon;
  final Color iconBackground;
  final Color? valueColor;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return _ProfileSurfaceCard(
      isDarkMode: isDarkMode,
      padding: const EdgeInsets.all(FreshSproutSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDarkMode
                          ? FreshSproutColors.darkTextMuted
                          : FreshSproutColors.onSurfaceVariant,
                      letterSpacing: 0.04,
                    ),
              ),
              Container(
                width: _ProfileSpec.metricIconSize,
                height: _ProfileSpec.metricIconSize,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: isDarkMode
                      ? FreshSproutColors.darkAccent
                      : FreshSproutColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: valueColor ??
                      (isDarkMode
                          ? FreshSproutColors.darkTextPrimary
                          : FreshSproutColors.onSurface),
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  height: 28 / 22,
                ),
          ),
          if (footer != null) ...[
            const SizedBox(height: 4),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _BudgetPlanningSection extends StatelessWidget {
  const _BudgetPlanningSection({
    required this.isDarkMode,
    required this.monthLabel,
    required this.monthlySpent,
    required this.monthlyBudget,
    required this.budgetUsedRatio,
    required this.budgetUsedPercent,
    required this.remainingBudget,
    required this.onAdjust,
    required this.onAddFavorite,
  });

  final bool isDarkMode;
  final String monthLabel;
  final double monthlySpent;
  final double monthlyBudget;
  final double budgetUsedRatio;
  final int budgetUsedPercent;
  final double remainingBudget;
  final VoidCallback onAdjust;
  final VoidCallback onAddFavorite;

  static const _favorites = [
    (Icons.storefront_outlined, 'Carrefour'),
    (Icons.local_mall_outlined, 'Pão de Açúcar'),
    (Icons.agriculture_outlined, 'Feira da Vila'),
  ];

  @override
  Widget build(BuildContext context) {
    final accent =
        isDarkMode ? FreshSproutColors.darkAccent : FreshSproutColors.primary;

    return _ProfileSurfaceCard(
      isDarkMode: isDarkMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileSectionHeader(
            isDarkMode: isDarkMode,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: _ProfileSpec.sectionIconSize,
                  height: _ProfileSpec.sectionIconSize,
                  decoration: BoxDecoration(
                    color: FreshSproutColors.secondaryContainer.withValues(
                      alpha: isDarkMode ? 0.2 : 0.5,
                    ),
                    borderRadius: _ProfileSpec.buttonRadius,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 20,
                    color: accent,
                  ),
                ),
                const SizedBox(width: FreshSproutSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Planejamento & Orçamento',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              color: isDarkMode
                                  ? FreshSproutColors.darkTextPrimary
                                  : FreshSproutColors.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              height: 24 / 18,
                            ),
                      ),
                      Text(
                        'Metas e locais de compra habituais',
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
                ),
                GestureDetector(
                  onTap: onAdjust,
                  child: Text(
                    'Ajustar',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          height: 16 / 12,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: FreshSproutSpacing.md),
          Container(
            padding: const EdgeInsets.all(FreshSproutSpacing.sm),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? FreshSproutColors.darkBackground
                  : FreshSproutColors.surfaceContainerLow,
              borderRadius: _ProfileSpec.buttonRadius,
            ),
            child: Column(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meta de Gastos Mensal',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDarkMode
                                ? FreshSproutColors.darkTextPrimary
                                : FreshSproutColors.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            height: 16 / 13,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? FreshSproutColors.darkCard
                                : FreshSproutColors.surfaceContainerLowest,
                            borderRadius: FreshSproutRadius.fullBorder,
                            border: Border.all(
                              color: isDarkMode
                                  ? FreshSproutColors.darkBorder
                                  : FreshSproutColors.surfaceContainerHigh,
                            ),
                          ),
                          child: Text(
                            monthLabel,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: accent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                          ),
                        ),
                        const Spacer(),
                        Text.rich(
                          TextSpan(
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: isDarkMode
                                      ? FreshSproutColors.darkTextPrimary
                                      : FreshSproutColors.onSurface,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  height: 20 / 14,
                                ),
                            children: [
                              TextSpan(
                                text: 'R\$ ${formatPrice(monthlySpent)} ',
                              ),
                              TextSpan(
                                text: '/ R\$ ${formatPrice(monthlyBudget)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: isDarkMode
                                          ? FreshSproutColors.darkTextMuted
                                          : FreshSproutColors.onSurfaceVariant,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 12,
                                      height: 16 / 12,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FreshSproutProgressBar(
                  value: budgetUsedRatio,
                  isDark: isDarkMode,
                  gradient: isDarkMode
                      ? null
                      : const LinearGradient(
                          colors: [
                            FreshSproutColors.brandMint,
                            FreshSproutColors.primary,
                          ],
                        ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline, size: 13, color: accent),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Restam R\$ ${formatPrice(remainingBudget)} no teto planejado',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: accent,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                    letterSpacing: 0,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$budgetUsedPercent% consumido',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isDarkMode
                                ? FreshSproutColors.darkTextMuted
                                : FreshSproutColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            letterSpacing: 0,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: FreshSproutSpacing.md),
          Text(
            'Mercados Favoritos',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isDarkMode
                      ? FreshSproutColors.darkTextMuted
                      : FreshSproutColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: FreshSproutSpacing.xs),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._favorites.map(
                (favorite) => _FavoriteMarketChip(
                  isDarkMode: isDarkMode,
                  icon: favorite.$1,
                  label: favorite.$2,
                ),
              ),
              _AddFavoriteChip(
                isDarkMode: isDarkMode,
                onPressed: onAddFavorite,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FavoriteMarketChip extends StatelessWidget {
  const _FavoriteMarketChip({
    required this.isDarkMode,
    required this.icon,
    required this.label,
  });

  final bool isDarkMode;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final accent =
        isDarkMode ? FreshSproutColors.darkAccent : FreshSproutColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDarkMode
            ? FreshSproutColors.darkBackground
            : FreshSproutColors.surfaceContainerLow,
        borderRadius: FreshSproutRadius.fullBorder,
        border: Border.all(
          color: isDarkMode
              ? FreshSproutColors.darkBorder
              : FreshSproutColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDarkMode
                      ? FreshSproutColors.darkTextPrimary
                      : FreshSproutColors.onSurface,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

class _AddFavoriteChip extends StatelessWidget {
  const _AddFavoriteChip({
    required this.isDarkMode,
    required this.onPressed,
  });

  final bool isDarkMode;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final accent =
        isDarkMode ? FreshSproutColors.darkAccent : FreshSproutColors.primary;

    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: FreshSproutRadius.fullBorder,
        side: BorderSide(
          color: isDarkMode
              ? FreshSproutColors.darkBorder
              : FreshSproutColors.outline,
          style: BorderStyle.solid,
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: FreshSproutRadius.fullBorder,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 16, color: accent),
              const SizedBox(width: 4),
              Text(
                'Adicionar',
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
        ),
      ),
    );
  }
}

class _PreferencesSection extends StatelessWidget {
  const _PreferencesSection({
    required this.isDarkMode,
    required this.promoAlertsEnabled,
    required this.onToggleTheme,
    required this.onPromoAlertsChanged,
  });

  final bool isDarkMode;
  final bool promoAlertsEnabled;
  final VoidCallback onToggleTheme;
  final ValueChanged<bool> onPromoAlertsChanged;

  @override
  Widget build(BuildContext context) {
    return _ProfileSurfaceCard(
      isDarkMode: isDarkMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileSectionHeader(
            isDarkMode: isDarkMode,
            child: Row(
              children: [
                Container(
                  width: _ProfileSpec.sectionIconSize,
                  height: _ProfileSpec.sectionIconSize,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? FreshSproutColors.darkCard
                        : FreshSproutColors.surfaceContainer,
                    borderRadius: _ProfileSpec.buttonRadius,
                  ),
                  child: Icon(
                    Icons.tune,
                    size: 20,
                    color: isDarkMode
                        ? FreshSproutColors.darkTextSecondary
                        : FreshSproutColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: FreshSproutSpacing.xs),
                Text(
                  'Preferências & Aparência',
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
          ),
          _PreferenceToggleRow(
            isDarkMode: isDarkMode,
            icon: Icons.dark_mode_outlined,
            title: 'Tema Escuro',
            subtitle:
                'Alternar modo noturno com fundo profundo e destaques âmbar',
            value: isDarkMode,
            onChanged: (_) => onToggleTheme(),
            extra: Row(
              children: [
                _ColorDot(
                  color: FreshSproutColors.darkBackground,
                  border: true,
                ),
                const SizedBox(width: 6),
                Text(
                  'Fundo Noturno',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDarkMode
                            ? FreshSproutColors.darkTextMuted
                            : FreshSproutColors.onSurfaceVariant,
                        fontSize: 11,
                        letterSpacing: 0,
                      ),
                ),
                const SizedBox(width: 12),
                const _ColorDot(color: FreshSproutColors.darkAccent),
                const SizedBox(width: 6),
                Text(
                  'Acento Âmbar',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDarkMode
                            ? FreshSproutColors.darkTextMuted
                            : FreshSproutColors.onSurfaceVariant,
                        fontSize: 11,
                        letterSpacing: 0,
                      ),
                ),
              ],
            ),
          ),
          Divider(
            color: isDarkMode
                ? FreshSproutColors.darkBorder
                : FreshSproutColors.surfaceContainerHigh,
          ),
          _PreferenceToggleRow(
            isDarkMode: isDarkMode,
            icon: Icons.notifications_active_outlined,
            title: 'Alertas de Promoção e Gastos',
            subtitle:
                'Avisos ao atingir 80% da meta mensal e descontos nos favoritos',
            value: promoAlertsEnabled,
            onChanged: onPromoAlertsChanged,
          ),
          Divider(
            color: isDarkMode
                ? FreshSproutColors.darkBorder
                : FreshSproutColors.surfaceContainerHigh,
          ),
          _PreferenceActionRow(
            isDarkMode: isDarkMode,
            icon: Icons.payments_outlined,
            title: 'Moeda e Formato',
            subtitle: 'Padrão financeiro utilizado nos cálculos',
            actionLabel: 'BRL (R\$)',
          ),
        ],
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color, this.border = false});

  final Color color;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: border
            ? Border.all(color: FreshSproutColors.outlineVariant)
            : null,
      ),
    );
  }
}

class _PreferenceToggleRow extends StatelessWidget {
  const _PreferenceToggleRow({
    required this.isDarkMode,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.extra,
  });

  final bool isDarkMode;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FreshSproutSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RoundIcon(icon: icon, isDarkMode: isDarkMode),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDarkMode
                            ? FreshSproutColors.darkTextPrimary
                            : FreshSproutColors.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 20 / 14,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDarkMode
                            ? FreshSproutColors.darkTextMuted
                            : FreshSproutColors.onSurfaceVariant,
                        fontSize: 12,
                        height: 16 / 12,
                      ),
                ),
                if (extra != null) ...[
                  const SizedBox(height: 4),
                  extra!,
                ],
              ],
            ),
          ),
          _ProfileSwitch(
            isDarkMode: isDarkMode,
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _PreferenceActionRow extends StatelessWidget {
  const _PreferenceActionRow({
    required this.isDarkMode,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
  });

  final bool isDarkMode;
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FreshSproutSpacing.xs),
      child: Row(
        children: [
          _RoundIcon(icon: icon, isDarkMode: isDarkMode),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDarkMode
                            ? FreshSproutColors.darkTextPrimary
                            : FreshSproutColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDarkMode
                            ? FreshSproutColors.darkTextMuted
                            : FreshSproutColors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Material(
            color: isDarkMode
                ? FreshSproutColors.darkCard
                : FreshSproutColors.surfaceContainerLow,
            borderRadius: FreshSproutRadius.smBorder,
            child: InkWell(
              onTap: () {},
              borderRadius: FreshSproutRadius.smBorder,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: FreshSproutRadius.smBorder,
                  border: Border.all(
                    color: isDarkMode
                        ? FreshSproutColors.darkBorder
                        : FreshSproutColors.outlineVariant
                            .withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: isDarkMode
                                ? FreshSproutColors.darkTextPrimary
                                : FreshSproutColors.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            height: 16 / 12,
                          ),
                    ),
                    Icon(
                      Icons.expand_more,
                      size: 16,
                      color: isDarkMode
                          ? FreshSproutColors.darkTextMuted
                          : FreshSproutColors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountSupportSection extends StatelessWidget {
  const _AccountSupportSection({
    required this.isDarkMode,
    required this.onExport,
    required this.onHelp,
    required this.onPrivacy,
    required this.onLogout,
  });

  final bool isDarkMode;
  final VoidCallback onExport;
  final VoidCallback onHelp;
  final VoidCallback onPrivacy;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return _ProfileSurfaceCard(
      isDarkMode: isDarkMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileSectionHeader(
            isDarkMode: isDarkMode,
            child: Row(
              children: [
                Container(
                  width: _ProfileSpec.sectionIconSize,
                  height: _ProfileSpec.sectionIconSize,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? FreshSproutColors.darkCard
                        : FreshSproutColors.surfaceContainer,
                    borderRadius: _ProfileSpec.buttonRadius,
                  ),
                  child: Icon(
                    Icons.support_agent_outlined,
                    size: 20,
                    color: isDarkMode
                        ? FreshSproutColors.darkTextSecondary
                        : FreshSproutColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: FreshSproutSpacing.xs),
                Text(
                  'Conta & Suporte',
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
          ),
          _SupportLinkTile(
            isDarkMode: isDarkMode,
            icon: Icons.ios_share,
            title: 'Exportar Relatório',
            subtitle: 'Baixar histórico de compras em PDF ou planilha Excel',
            onTap: onExport,
          ),
          _SupportLinkTile(
            isDarkMode: isDarkMode,
            icon: Icons.help_outline,
            title: 'Ajuda e Suporte',
            subtitle: 'Dúvidas frequentes, guias e contato direto',
            onTap: onHelp,
          ),
          _SupportLinkTile(
            isDarkMode: isDarkMode,
            icon: Icons.verified_user_outlined,
            title: 'Termos e Privacidade',
            subtitle: 'Políticas de uso e proteção dos seus dados pessoais',
            onTap: onPrivacy,
          ),
          const SizedBox(height: FreshSproutSpacing.sm),
          Material(
            color: FreshSproutColors.errorContainer.withValues(
              alpha: isDarkMode ? 0.25 : 0.4,
            ),
            borderRadius: _ProfileSpec.buttonRadius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onLogout,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.logout,
                      size: 20,
                      color: FreshSproutColors.error,
                    ),
                    const SizedBox(width: FreshSproutSpacing.xs),
                    Text(
                      'Sair da Conta',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: FreshSproutColors.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            height: 18 / 14,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportLinkTile extends StatelessWidget {
  const _SupportLinkTile({
    required this.isDarkMode,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool isDarkMode;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isDarkMode
                  ? FreshSproutColors.darkTextMuted
                  : FreshSproutColors.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDarkMode
                              ? FreshSproutColors.darkTextMuted
                              : FreshSproutColors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: isDarkMode
                  ? FreshSproutColors.darkBorder
                  : FreshSproutColors.outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.isDarkMode});

  final IconData icon;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _ProfileSpec.rowIconSize,
      height: _ProfileSpec.rowIconSize,
      decoration: BoxDecoration(
        color: isDarkMode
            ? FreshSproutColors.darkCard
            : FreshSproutColors.surfaceContainerLow,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 20,
        color: isDarkMode
            ? FreshSproutColors.darkTextPrimary
            : FreshSproutColors.onSurface,
      ),
    );
  }
}

class _ProfileSwitch extends StatelessWidget {
  const _ProfileSwitch({
    required this.isDarkMode,
    required this.value,
    required this.onChanged,
  });

  final bool isDarkMode;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final activeColor = isDarkMode
        ? FreshSproutColors.darkAccent
        : FreshSproutColors.primary;
    final trackColor = value
        ? activeColor
        : (isDarkMode
            ? FreshSproutColors.darkBorder
            : FreshSproutColors.surfaceContainerHighest);

    return Semantics(
      button: true,
      toggled: value,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: _ProfileSpec.switchWidth,
          height: _ProfileSpec.switchHeight,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: FreshSproutRadius.fullBorder,
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: _ProfileSpec.switchThumb,
              height: _ProfileSpec.switchThumb,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFD1D5DB),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
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

class _ProfileSectionHeader extends StatelessWidget {
  const _ProfileSectionHeader({
    required this.isDarkMode,
    required this.child,
  });

  final bool isDarkMode;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: FreshSproutSpacing.xs),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDarkMode
                ? FreshSproutColors.darkBorder
                : FreshSproutColors.surfaceContainerHigh,
          ),
        ),
      ),
      child: child,
    );
  }
}

class _ProfileSurfaceCard extends StatelessWidget {
  const _ProfileSurfaceCard({
    required this.isDarkMode,
    required this.child,
    this.padding = const EdgeInsets.all(FreshSproutSpacing.md),
  });

  final bool isDarkMode;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: isDarkMode
            ? FreshSproutColors.darkCard
            : FreshSproutColors.surfaceContainerLowest,
        borderRadius: _ProfileSpec.cardRadius,
        border: Border.all(
          color: isDarkMode
              ? FreshSproutColors.darkBorder.withValues(alpha: 0.6)
              : FreshSproutColors.surfaceContainerHighest.withValues(
                  alpha: 0.6,
                ),
        ),
        boxShadow: isDarkMode ? null : FreshSproutElevation.level1,
      ),
      child: child,
    );
  }
}
