import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/list_item.dart';
import '../models/scan_mode.dart';
import '../models/shopping_list.dart';
import '../services/shopping_list_repository.dart';
import '../theme/fresh_sprout_tokens.dart';
import '../utils/date_formatter.dart';
import '../widgets/item_form_dialog.dart';
import 'scanner_screen.dart';

enum _ListItemFilter { pending, inCart, all }

abstract final class _ListDetailSpec {
  static final cardRadius = FreshSproutRadius.lgBorder;
  static final heroCardRadius = FreshSproutRadius.xlBorder;
  static final buttonRadius = FreshSproutRadius.mdBorder;
  static const iconBtnSize = 40.0;
  static const checkSize = 28.0;
  static const thumbSize = 48.0;
  static const thumbSizeChecked = 40.0;
  static const sectionGap = FreshSproutSpacing.lg;
  static const blockGap = FreshSproutSpacing.xs;
  static const tightGap = FreshSproutSpacing.xxs;
  static const cardPadding = FreshSproutSpacing.md;
  static const cardPaddingSm = FreshSproutSpacing.sm;
}

/// Dark mode v2 — mockup lista de compras (#222738 surface).
abstract final class _ListDetailDark {
  static const surface = Color(0xFF222738);
  static const surfacePurchased = Color(0xFF1F2434);
  static const surfaceElevated = Color(0xFF2A3045);
  static const surfaceHover = Color(0xFF262C3E);

  static const green = FreshSproutColors.darkAccentGreen;
  static const greenLight = FreshSproutColors.darkAccentGreenLight;
  static const greenDark = FreshSproutColors.darkAccentGreenDark;
  static const amber = FreshSproutColors.darkAccent;

  static const emerald950 = Color(0xFF022C22);
  static const emerald800 = Color(0xFF065F46);
  static const emerald300 = Color(0xFF6EE7B7);
  static const emerald200 = Color(0xFFA7F3D0);
  static const emerald400 = Color(0xFF34D399);

  static Color get emeraldChipBg => emerald950.withValues(alpha: 0.7);
  static Color get emeraldChipBorder => emerald800.withValues(alpha: 0.6);

  static const greenGradient = LinearGradient(
    colors: [greenDark, green],
  );

  static const greenGradientBright = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981), Color(0xFF34D399)],
  );

  static const checkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF059669), Color(0xFF10B981)],
  );
}

abstract final class _ListDetailTypography {
  static TextStyle headlineMd(
    BuildContext context, {
    Color? color,
    FontWeight fontWeight = FontWeight.w600,
  }) =>
      Theme.of(context).textTheme.headlineMedium!.copyWith(
            fontSize: 22,
            height: 28 / 22,
            fontWeight: fontWeight,
            letterSpacing: -0.22,
            color: color,
          );

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

String _locationForList(ShoppingList list) {
  final name = list.name.toLowerCase();
  if (name.contains('feira') || name.contains('domingo')) {
    return 'Feira Municipal Vila Madalena';
  }
  if (name.contains('carrefour')) return 'Carrefour Express';
  if (name.contains('açougue') || name.contains('acougue')) {
    return 'Açougue do Bairro';
  }
  return 'Local de compra';
}

String _categoryForItem(ListItem item) {
  final text = '${item.name} ${item.brand ?? ''}'.toLowerCase();
  if (RegExp(r'tomate|banana|alface|rúcula|rucula|maçã|maca|limão|limao|'
          r'horti|verdura|fruta|cebola|batata')
      .hasMatch(text)) {
    return 'Hortifruti';
  }
  if (RegExp(r'queijo|leite|iogurte|manteiga|latic').hasMatch(text)) {
    return 'Laticínios';
  }
  if (RegExp(r'pão|pao|baguete|padaria|fermentação|fermentacao')
      .hasMatch(text)) {
    return 'Padaria';
  }
  if (RegExp(r'café|cafe|azeite|arroz|feijão|feijao|merc').hasMatch(text)) {
    return 'Mercearia';
  }
  const fallback = ['Hortifruti', 'Laticínios', 'Mercearia', 'Padaria'];
  return fallback[item.id.hashCode.abs() % fallback.length];
}

String _quantityLabel(ListItem item) {
  final parts = <String>[];
  if (item.quantity > 1) {
    parts.add('${item.quantity} un.');
  } else {
    parts.add('1 un.');
  }
  if (item.brandText != null && item.brandText!.isNotEmpty) {
    parts.add(item.brandText!);
  }
  return parts.join(' • ');
}

IconData _placeholderIcon(ListItem item) {
  final text = item.name.toLowerCase();
  if (text.contains('café') || text.contains('cafe')) {
    return Icons.coffee_outlined;
  }
  if (text.contains('queijo') || text.contains('leite')) {
    return Icons.egg_outlined;
  }
  if (RegExp(r'tomate|banana|alface|fruta|verdura').hasMatch(text)) {
    return Icons.eco_outlined;
  }
  return Icons.shopping_bag_outlined;
}

class ListDetailScreen extends StatefulWidget {
  const ListDetailScreen({
    super.key,
    required this.listId,
    this.isDarkMode,
  });

  final String listId;
  final bool? isDarkMode;

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  final _repository = ShoppingListRepository.instance;
  final _uuid = const Uuid();
  ShoppingList? _list;
  _ListItemFilter _filter = _ListItemFilter.inCart;

  bool _isDark(BuildContext context) =>
      widget.isDarkMode ?? Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  void _loadList() {
    setState(() {
      _list = _repository.getListById(widget.listId);
    });
  }

  Future<void> _openScanner({ScanMode initialMode = ScanMode.barcode}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ScannerScreen(
          listId: widget.listId,
          initialMode: initialMode,
        ),
      ),
    );
    _loadList();
  }

  Future<void> _addItem() async {
    final result = await showItemFormDialog(context);
    if (result == null) return;

    final item = ListItem(
      id: _uuid.v4(),
      name: result.name,
      price: result.price,
      quantity: result.quantity,
    );

    await _repository.addItem(widget.listId, item);
    _loadList();
  }

  Future<void> _editItem(ListItem item) async {
    final result = await showItemFormDialog(context, item: item);
    if (result == null) return;

    await _repository.updateItem(
      widget.listId,
      item.copyWith(
        name: result.name,
        price: result.price,
        clearPrice: result.price == null,
        quantity: result.quantity,
      ),
    );
    _loadList();
  }

  Future<void> _togglePurchased(ListItem item) async {
    await _repository.updateItem(
      widget.listId,
      item.copyWith(isPurchased: !item.isPurchased),
    );
    _loadList();
  }

  Future<void> _deleteItem(ListItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir item'),
          content: Text('Deseja excluir "${item.name}" da lista?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    await _repository.deleteItem(widget.listId, item.id);
    _loadList();
  }

  void _showSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature — em breve')),
    );
  }

  void _showOptions(ShoppingList list) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Adicionar item'),
                onTap: () {
                  Navigator.pop(context);
                  _addItem();
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner_outlined),
                title: const Text('Escanear produto'),
                onTap: () {
                  Navigator.pop(context);
                  _openScanner();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Excluir lista'),
                onTap: () async {
                  Navigator.pop(context);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Excluir lista'),
                      content: Text('Deseja excluir "${list.name}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Excluir'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && mounted) {
                    await _repository.deleteList(list.id);
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  double _cartTotal(ShoppingList list) => list.items
      .where((item) => item.isPurchased && item.price != null)
      .fold(0.0, (sum, item) => sum + item.price! * item.quantity);

  double _budgetCeiling(ShoppingList list) {
    final priced = list.items.where((item) => item.price != null).toList();
    if (priced.isEmpty) return 220.0;

    final estimated = list.items.fold(
      0.0,
      (sum, item) => sum + (item.price ?? 0) * item.quantity,
    );
    if (estimated > 0) return estimated;

    final avg = priced.fold(0.0, (s, i) => s + i.price!) / priced.length;
    return avg * list.items.length;
  }

  double _estimatedSavings(double cartTotal) => cartTotal * 0.129;

  @override
  Widget build(BuildContext context) {
    final list = _list;
    final isDark = _isDark(context);

    if (list == null) {
      return Scaffold(
        backgroundColor: isDark
            ? FreshSproutColors.darkBackground
            : FreshSproutColors.background,
        body: const Center(child: Text('Lista não encontrada')),
      );
    }

    if (list.items.isEmpty) {
      return Scaffold(
        backgroundColor: isDark
            ? FreshSproutColors.darkBackground
            : FreshSproutColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _ListDetailAppBar(
                isDarkMode: isDark,
                list: list,
                onBack: () => Navigator.of(context).pop(),
                onOptions: () => _showOptions(list),
              ),
              Expanded(
                child: _EmptyItemsState(
                  isDarkMode: isDark,
                  onAddItem: _addItem,
                  onScan: () => _openScanner(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final pending = list.items.where((item) => !item.isPurchased).toList();
    final purchased = list.items.where((item) => item.isPurchased).toList();
    final totalItems = list.items.length;
    final inCartCount = purchased.length;
    final pendingCount = pending.length;
    final progressRatio =
        totalItems == 0 ? 0.0 : inCartCount / totalItems;
    final progressPercent = (progressRatio * 100).round();
    final cartTotal = _cartTotal(list);
    final budgetCeiling = _budgetCeiling(list);
    final remaining = (budgetCeiling - cartTotal).clamp(0.0, double.infinity);
    final savings = _estimatedSavings(cartTotal);
    final inProgress = pendingCount > 0;

    final showPending = _filter == _ListItemFilter.pending ||
        _filter == _ListItemFilter.all;
    final showPurchased = _filter == _ListItemFilter.inCart ||
        _filter == _ListItemFilter.all;

    return Scaffold(
      backgroundColor: isDark
          ? FreshSproutColors.darkBackground
          : FreshSproutColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _ListDetailHeader(
              isDarkMode: isDark,
              list: list,
              inProgress: inProgress,
              location: _locationForList(list),
              inCartCount: inCartCount,
              totalItems: totalItems,
              progressPercent: progressPercent,
              progressRatio: progressRatio,
              cartTotal: cartTotal,
              budgetCeiling: budgetCeiling,
              remaining: remaining,
              pendingCount: pendingCount,
              filter: _filter,
              onBack: () => Navigator.of(context).pop(),
              onOptions: () => _showOptions(list),
              onFilterChanged: (filter) => setState(() => _filter = filter),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  FreshSproutSpacing.marginMobile,
                  _ListDetailSpec.blockGap,
                  FreshSproutSpacing.marginMobile,
                  120,
                ),
                children: [
                  if (showPending && pending.isNotEmpty) ...[
                    _SectionHeader(
                      isDarkMode: isDark,
                      dotColor: isDark
                          ? _ListDetailDark.amber
                          : FreshSproutColors.tertiaryContainer,
                      title: 'A Comprar',
                      count: pendingCount,
                      trailing: 'Toque para coletar',
                      countLowercase: true,
                    ),
                    const SizedBox(height: _ListDetailSpec.blockGap),
                    ...pending.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: _ListDetailSpec.blockGap,
                        ),
                        child: _PendingItemCard(
                          isDarkMode: isDark,
                          item: item,
                          category: _categoryForItem(item),
                          quantityLabel: _quantityLabel(item),
                          onToggle: () => _togglePurchased(item),
                          onEdit: () => _editItem(item),
                          onDelete: () => _deleteItem(item),
                        ),
                      ),
                    ),
                    const SizedBox(height: _ListDetailSpec.tightGap),
                  ],
                  if (showPending || _filter == _ListItemFilter.all) ...[
                    _QuickAddButton(
                      isDarkMode: isDark,
                      onAdd: _addItem,
                      onScan: () => _openScanner(),
                    ),
                    const SizedBox(height: _ListDetailSpec.sectionGap),
                  ],
                  if (showPurchased && purchased.isNotEmpty) ...[
                    _SectionHeader(
                      isDarkMode: isDark,
                      dotColor: isDark
                          ? _ListDetailDark.green
                          : FreshSproutColors.primary,
                      title: 'Já no Carrinho',
                      count: inCartCount,
                      trailing: 'R\$ ${formatPrice(cartTotal)}',
                      trailingBold: true,
                      countHighlight: true,
                      countLowercase: true,
                    ),
                    const SizedBox(height: _ListDetailSpec.blockGap),
                    ...purchased.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: _ListDetailSpec.blockGap,
                        ),
                        child: _PurchasedItemCard(
                          isDarkMode: isDark,
                          item: item,
                          category: _categoryForItem(item),
                          quantityLabel: _quantityLabel(item),
                          onToggle: () => _togglePurchased(item),
                        ),
                      ),
                    ),
                  ],
                  if (!showPending && pending.isEmpty && showPurchased)
                    const SizedBox.shrink(),
                  if (_filter == _ListItemFilter.pending && pending.isEmpty)
                    _FilterEmptyHint(
                      isDarkMode: isDark,
                      message: 'Nenhum item pendente',
                    ),
                  if (_filter == _ListItemFilter.inCart && purchased.isEmpty)
                    _FilterEmptyHint(
                      isDarkMode: isDark,
                      message: 'Nenhum item no carrinho ainda',
                    ),
                ],
              ),
            ),
            _CheckoutFooter(
              isDarkMode: isDark,
              cartTotal: cartTotal,
              savings: savings,
              onPause: () => _showSoon('Pausar compras'),
              onCheckout: () => _showSoon('Finalizar compra'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListDetailAppBar extends StatelessWidget {
  const _ListDetailAppBar({
    required this.isDarkMode,
    required this.list,
    required this.onBack,
    required this.onOptions,
  });

  final bool isDarkMode;
  final ShoppingList list;
  final VoidCallback onBack;
  final VoidCallback onOptions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FreshSproutSpacing.marginMobile,
        _ListDetailSpec.cardPadding,
        FreshSproutSpacing.marginMobile,
        _ListDetailSpec.blockGap,
      ),
      child: Row(
        children: [
          _CircleIconButton(
            isDarkMode: isDarkMode,
            icon: Icons.arrow_back,
            onPressed: onBack,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _ListDetailSpec.blockGap,
              ),
              child: Text(
                list.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _ListDetailTypography.headlineSm(context),
              ),
            ),
          ),
          _CircleIconButton(
            isDarkMode: isDarkMode,
            icon: Icons.more_vert,
            onPressed: onOptions,
          ),
        ],
      ),
    );
  }
}

class _ListDetailHeader extends StatelessWidget {
  const _ListDetailHeader({
    required this.isDarkMode,
    required this.list,
    required this.inProgress,
    required this.location,
    required this.inCartCount,
    required this.totalItems,
    required this.progressPercent,
    required this.progressRatio,
    required this.cartTotal,
    required this.budgetCeiling,
    required this.remaining,
    required this.pendingCount,
    required this.filter,
    required this.onBack,
    required this.onOptions,
    required this.onFilterChanged,
  });

  final bool isDarkMode;
  final ShoppingList list;
  final bool inProgress;
  final String location;
  final int inCartCount;
  final int totalItems;
  final int progressPercent;
  final double progressRatio;
  final double cartTotal;
  final double budgetCeiling;
  final double remaining;
  final int pendingCount;
  final _ListItemFilter filter;
  final VoidCallback onBack;
  final VoidCallback onOptions;
  final ValueChanged<_ListItemFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final accent = isDarkMode
        ? _ListDetailDark.greenLight
        : FreshSproutColors.primary;
    final surface = isDarkMode
        ? FreshSproutColors.darkBackground
        : FreshSproutColors.surface;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: surface.withValues(alpha: isDarkMode ? 0.95 : 0.95),
            border: isDarkMode
                ? Border(
                    bottom: BorderSide(
                      color: FreshSproutColors.darkBorder.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              FreshSproutSpacing.marginMobile,
              _ListDetailSpec.cardPadding,
              FreshSproutSpacing.marginMobile,
              _ListDetailSpec.blockGap,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _CircleIconButton(
                      isDarkMode: isDarkMode,
                      icon: Icons.arrow_back,
                      onPressed: onBack,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: _ListDetailSpec.blockGap,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    list.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _ListDetailTypography.headlineSm(
                                      context,
                                      color: isDarkMode
                                          ? FreshSproutColors.darkTextPrimary
                                          : null,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: _ListDetailSpec.blockGap),
                                _StatusBadge(
                                  isDarkMode: isDarkMode,
                                  inProgress: inProgress,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: accent,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    location,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _ListDetailTypography.bodySm(
                                      context,
                                      color: isDarkMode
                                          ? FreshSproutColors.darkTextMuted
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    _CircleIconButton(
                      isDarkMode: isDarkMode,
                      icon: Icons.more_vert,
                      onPressed: onOptions,
                    ),
                  ],
                ),
                const SizedBox(height: _ListDetailSpec.cardPaddingSm),
                _ProgressCard(
                  isDarkMode: isDarkMode,
                  inCartCount: inCartCount,
                  totalItems: totalItems,
                  progressPercent: progressPercent,
                  progressRatio: progressRatio,
                  cartTotal: cartTotal,
                  budgetCeiling: budgetCeiling,
                  remaining: remaining,
                ),
                const SizedBox(height: _ListDetailSpec.cardPaddingSm),
                _FilterChips(
                  isDarkMode: isDarkMode,
                  filter: filter,
                  pendingCount: pendingCount,
                  inCartCount: inCartCount,
                  totalItems: totalItems,
                  onChanged: onFilterChanged,
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
    required this.isDarkMode,
    required this.inProgress,
  });

  final bool isDarkMode;
  final bool inProgress;

  @override
  Widget build(BuildContext context) {
    if (isDarkMode) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: _ListDetailDark.emeraldChipBg,
          borderRadius: FreshSproutRadius.fullBorder,
          border: Border.all(color: _ListDetailDark.emeraldChipBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _ListDetailDark.emerald400,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _ListDetailDark.emerald400.withValues(alpha: 0.8),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              inProgress ? 'Em andamento' : 'Concluída',
              style: _ListDetailTypography.labelSm(
                context,
                color: _ListDetailDark.emerald300,
              ).copyWith(
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: FreshSproutColors.secondaryContainer,
        borderRadius: FreshSproutRadius.fullBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: FreshSproutColors.primaryContainer,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            inProgress ? 'EM ANDAMENTO' : 'CONCLUÍDA',
            style: _ListDetailTypography.labelSm(
              context,
              color: FreshSproutColors.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.isDarkMode,
    required this.inCartCount,
    required this.totalItems,
    required this.progressPercent,
    required this.progressRatio,
    required this.cartTotal,
    required this.budgetCeiling,
    required this.remaining,
  });

  final bool isDarkMode;
  final int inCartCount;
  final int totalItems;
  final int progressPercent;
  final double progressRatio;
  final double cartTotal;
  final double budgetCeiling;
  final double remaining;

  @override
  Widget build(BuildContext context) {
    final accent = isDarkMode
        ? _ListDetailDark.greenLight
        : FreshSproutColors.primary;
    final muted = isDarkMode
        ? FreshSproutColors.darkTextMuted
        : FreshSproutColors.onSurfaceVariant;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDarkMode
            ? _ListDetailDark.surface
            : FreshSproutColors.surfaceContainerLowest,
        borderRadius: isDarkMode
            ? _ListDetailSpec.heroCardRadius
            : _ListDetailSpec.cardRadius,
        border: Border.all(
          color: isDarkMode
              ? FreshSproutColors.darkBorder
              : FreshSproutColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: isDarkMode
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (isDarkMode)
            Positioned(
              right: -32,
              top: -32,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _ListDetailDark.green.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(_ListDetailSpec.cardPadding),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Progresso no Carrinho',
                            style: _ListDetailTypography.labelMd(
                              context,
                              color: muted,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '$inCartCount ',
                                  style: _ListDetailTypography.headlineMd(
                                    context,
                                    color: accent,
                                  ),
                                ),
                                TextSpan(
                                  text: 'de $totalItems itens ',
                                  style: _ListDetailTypography.labelLg(
                                    context,
                                    color: muted,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? _ListDetailDark.emerald950
                                              .withValues(alpha: 0.6)
                                          : FreshSproutColors
                                              .surfaceContainerLow,
                                      borderRadius: FreshSproutRadius.mdBorder,
                                      border: isDarkMode
                                          ? Border.all(
                                              color: _ListDetailDark
                                                  .emeraldChipBorder,
                                            )
                                          : null,
                                    ),
                                    child: Text(
                                      '$progressPercent%',
                                      style: _ListDetailTypography.labelMd(
                                        context,
                                        color: isDarkMode
                                            ? _ListDetailDark.emerald300
                                            : accent,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total Carrinho',
                          style: _ListDetailTypography.labelMd(
                            context,
                            color: muted,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          'R\$ ${formatPrice(cartTotal)}',
                          style: _ListDetailTypography.headlineMd(
                            context,
                            color: isDarkMode
                                ? FreshSproutColors.darkTextPrimary
                                : null,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: _ListDetailSpec.blockGap),
                Container(
                  height: 10,
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? FreshSproutColors.darkBackground
                        : FreshSproutColors.surfaceContainer,
                    borderRadius: FreshSproutRadius.fullBorder,
                    border: isDarkMode
                        ? Border.all(color: FreshSproutColors.darkBorder)
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: FreshSproutRadius.fullBorder,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progressRatio.clamp(0, 1),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: isDarkMode
                                  ? _ListDetailDark.greenGradientBright
                                  : const LinearGradient(
                                      colors: [
                                        FreshSproutColors.secondary,
                                        FreshSproutColors.primaryContainer,
                                      ],
                                    ),
                              boxShadow: isDarkMode
                                  ? [
                                      BoxShadow(
                                        color: _ListDetailDark.green
                                            .withValues(alpha: 0.5),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: _ListDetailSpec.blockGap),
                Container(
                  padding: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDarkMode
                            ? FreshSproutColors.darkBorder
                                .withValues(alpha: 0.8)
                            : FreshSproutColors.surfaceContainer,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text.rich(
                        TextSpan(
                          style: _ListDetailTypography.bodySm(context),
                          children: [
                            TextSpan(
                              text: 'Teto previsto: ',
                              style: TextStyle(color: muted),
                            ),
                            TextSpan(
                              text: 'R\$ ${formatPrice(budgetCeiling)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDarkMode
                                    ? FreshSproutColors.darkTextPrimary
                                    : FreshSproutColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? _ListDetailDark.emeraldChipBg
                              : FreshSproutColors.secondaryContainer
                                  .withValues(alpha: 0.4),
                          borderRadius: FreshSproutRadius.fullBorder,
                          border: isDarkMode
                              ? Border.all(
                                  color: _ListDetailDark.emeraldChipBorder,
                                )
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 15,
                              color: isDarkMode
                                  ? _ListDetailDark.emerald400
                                  : accent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'R\$ ${formatPrice(remaining)} restantes',
                              style: _ListDetailTypography.labelMd(
                                context,
                                color: isDarkMode
                                    ? _ListDetailDark.emerald300
                                    : accent,
                                fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.isDarkMode,
    required this.filter,
    required this.pendingCount,
    required this.inCartCount,
    required this.totalItems,
    required this.onChanged,
  });

  final bool isDarkMode;
  final _ListItemFilter filter;
  final int pendingCount;
  final int inCartCount;
  final int totalItems;
  final ValueChanged<_ListItemFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            isDarkMode: isDarkMode,
            label: 'Pendentes',
            count: pendingCount,
            selected: filter == _ListItemFilter.pending,
            onTap: () => onChanged(_ListItemFilter.pending),
          ),
          const SizedBox(width: _ListDetailSpec.blockGap),
          _FilterChip(
            isDarkMode: isDarkMode,
            label: 'No Carrinho',
            count: inCartCount,
            selected: filter == _ListItemFilter.inCart,
            onTap: () => onChanged(_ListItemFilter.inCart),
          ),
          const SizedBox(width: _ListDetailSpec.blockGap),
          _FilterChip(
            isDarkMode: isDarkMode,
            label: 'Todos',
            count: totalItems,
            selected: filter == _ListItemFilter.all,
            showCountAsText: true,
            onTap: () => onChanged(_ListItemFilter.all),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.isDarkMode,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.showCountAsText = false,
  });

  final bool isDarkMode;
  final String label;
  final int count;
  final bool selected;
  final bool showCountAsText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final useActive = selected && !showCountAsText;

    if (isDarkMode) {
      final fg = useActive
          ? Colors.white
          : FreshSproutColors.darkTextSecondary;
      final countColor = useActive
          ? _ListDetailDark.emerald200
          : _ListDetailDark.amber;

      return Material(
        color: Colors.transparent,
        borderRadius: FreshSproutRadius.fullBorder,
        child: InkWell(
          onTap: onTap,
          borderRadius: FreshSproutRadius.fullBorder,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: FreshSproutRadius.fullBorder,
              gradient: useActive ? _ListDetailDark.greenGradient : null,
              color: useActive ? null : _ListDetailDark.surface,
              border: Border.all(
                color: useActive
                    ? _ListDetailDark.emerald400.withValues(alpha: 0.3)
                    : FreshSproutColors.darkBorder,
              ),
              boxShadow: useActive
                  ? [
                      BoxShadow(
                        color: _ListDetailDark.green.withValues(alpha: 0.3),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _ListDetailSpec.cardPadding,
                vertical: 6,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: _ListDetailTypography.labelMd(
                      context,
                      color: fg,
                      fontWeight:
                          useActive ? FontWeight.w600 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (showCountAsText)
                    Text(
                      '$count',
                      style: _ListDetailTypography.labelSm(
                        context,
                        color: FreshSproutColors.darkTextMuted,
                        fontWeight: FontWeight.w500,
                      ).copyWith(letterSpacing: 0),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: useActive
                            ? _ListDetailDark.emerald950.withValues(alpha: 0.8)
                            : FreshSproutColors.darkBackground,
                        borderRadius: FreshSproutRadius.fullBorder,
                        border: useActive
                            ? null
                            : Border.all(color: FreshSproutColors.darkBorder),
                      ),
                      child: Text(
                        '$count',
                        style: _ListDetailTypography.labelSm(
                          context,
                          color: countColor,
                        ).copyWith(letterSpacing: 0),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final bg = useActive
        ? FreshSproutColors.primaryContainer
        : FreshSproutColors.surfaceContainerHighest;
    final fg = useActive
        ? FreshSproutColors.onPrimaryContainer
        : FreshSproutColors.onSurface;

    return Material(
      color: bg,
      borderRadius: FreshSproutRadius.fullBorder,
      elevation: useActive ? 1 : 0,
      shadowColor: FreshSproutColors.shadowTint.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: FreshSproutRadius.fullBorder,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _ListDetailSpec.cardPadding,
            vertical: 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: _ListDetailTypography.labelMd(
                  context,
                  color: fg,
                  fontWeight: useActive ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              if (showCountAsText)
                Text(
                  '$count',
                  style: _ListDetailTypography.labelSm(
                    context,
                    color: FreshSproutColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ).copyWith(letterSpacing: 0),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: useActive
                        ? FreshSproutColors.onPrimaryContainer
                        : FreshSproutColors.surfaceContainerLowest,
                    borderRadius: FreshSproutRadius.fullBorder,
                  ),
                  child: Text(
                    '$count',
                    style: _ListDetailTypography.labelSm(
                      context,
                      color: useActive
                          ? FreshSproutColors.primaryContainer
                          : FreshSproutColors.primary,
                    ).copyWith(letterSpacing: 0),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.isDarkMode,
    required this.dotColor,
    required this.title,
    required this.count,
    required this.trailing,
    this.countLowercase = false,
    this.countHighlight = false,
    this.trailingBold = false,
  });

  final bool isDarkMode;
  final Color dotColor;
  final String title;
  final int count;
  final String trailing;
  final bool countLowercase;
  final bool countHighlight;
  final bool trailingBold;

  @override
  Widget build(BuildContext context) {
    final accent = isDarkMode
        ? _ListDetailDark.greenLight
        : FreshSproutColors.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: isDarkMode
                    ? [
                        BoxShadow(
                          color: dotColor.withValues(alpha: 0.9),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 6),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: title.toUpperCase(),
                    style: _ListDetailTypography.labelLg(
                      context,
                      color: isDarkMode
                          ? FreshSproutColors.darkTextPrimary
                          : null,
                    ).copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  TextSpan(
                    text: countLowercase
                        ? ' ($count itens)'
                        : ' ($count ITENS)',
                    style: _ListDetailTypography.labelLg(
                      context,
                      color: countHighlight
                          ? accent
                          : (isDarkMode
                              ? FreshSproutColors.darkTextMuted
                              : FreshSproutColors.onSurfaceVariant),
                      fontWeight: FontWeight.w400,
                    ).copyWith(
                      letterSpacing: 0,
                      fontSize: countLowercase ? 14 : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Text(
          trailing,
          style: trailingBold
              ? _ListDetailTypography.bodySm(
                  context,
                  color: accent,
                  fontWeight: FontWeight.w700,
                )
              : _ListDetailTypography.labelSm(
                  context,
                  color: isDarkMode
                      ? FreshSproutColors.darkTextMuted
                      : FreshSproutColors.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                ).copyWith(letterSpacing: 0),
        ),
      ],
    );
  }
}

class _PendingItemCard extends StatelessWidget {
  const _PendingItemCard({
    required this.isDarkMode,
    required this.item,
    required this.category,
    required this.quantityLabel,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final bool isDarkMode;
  final ListItem item;
  final String category;
  final String quantityLabel;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final accent = isDarkMode
        ? _ListDetailDark.greenLight
        : FreshSproutColors.primary;
    final editColor = isDarkMode
        ? _ListDetailDark.amber
        : FreshSproutColors.outline;

    return Material(
      color: isDarkMode
          ? _ListDetailDark.surface
          : FreshSproutColors.surfaceContainerLowest,
      borderRadius: _ListDetailSpec.cardRadius,
      elevation: 0,
      child: InkWell(
        onTap: onToggle,
        onLongPress: onDelete,
        borderRadius: _ListDetailSpec.cardRadius,
        hoverColor: isDarkMode
            ? _ListDetailDark.surfaceHover.withValues(alpha: 0.5)
            : null,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: _ListDetailSpec.cardRadius,
            border: Border.all(
              color: isDarkMode
                  ? FreshSproutColors.darkBorder
                  : FreshSproutColors.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: isDarkMode
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(_ListDetailSpec.cardPaddingSm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onToggle,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: _ListDetailSpec.checkSize,
                    height: _ListDetailSpec.checkSize,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      borderRadius: _ListDetailSpec.buttonRadius,
                      color: isDarkMode
                          ? FreshSproutColors.darkBackground
                          : null,
                      border: Border.all(
                        color: isDarkMode
                            ? FreshSproutColors.darkBorderLight
                            : FreshSproutColors.outlineVariant,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: _ListDetailSpec.cardPaddingSm),
                _ItemThumbnail(
                  isDarkMode: isDarkMode,
                  item: item,
                  size: _ListDetailSpec.thumbSize,
                ),
                const SizedBox(width: _ListDetailSpec.cardPaddingSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _ListDetailTypography.bodyMd(
                                context,
                                color: isDarkMode
                                    ? FreshSproutColors.darkTextPrimary
                                    : null,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          _CategoryTag(category: category, isDarkMode: isDarkMode),
                        ],
                      ),
                      Text(
                        quantityLabel,
                        style: _ListDetailTypography.bodySm(
                          context,
                          color: isDarkMode
                              ? FreshSproutColors.darkTextMuted
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.price != null
                                ? 'Est. R\$ ${formatPrice(item.price! * item.quantity)}'
                                : 'Sem preço',
                            style: _ListDetailTypography.labelMd(
                              context,
                              color: accent,
                            ),
                          ),
                          GestureDetector(
                            onTap: onEdit,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  size: 13,
                                  color: editColor,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Ajustar',
                                  style: _ListDetailTypography.labelSm(
                                    context,
                                    color: isDarkMode
                                        ? FreshSproutColors.darkTextSecondary
                                        : FreshSproutColors.outline,
                                    fontWeight: FontWeight.w400,
                                  ).copyWith(letterSpacing: 0),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _PurchasedItemCard extends StatelessWidget {
  const _PurchasedItemCard({
    required this.isDarkMode,
    required this.item,
    required this.category,
    required this.quantityLabel,
    required this.onToggle,
  });

  final bool isDarkMode;
  final ListItem item;
  final String category;
  final String quantityLabel;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final lineColor = isDarkMode
        ? FreshSproutColors.darkTextMuted
        : FreshSproutColors.outlineVariant;
    final price = item.price != null
        ? item.price! * item.quantity
        : null;

    return Opacity(
      opacity: isDarkMode ? 0.9 : 0.85,
      child: Material(
        color: isDarkMode
            ? _ListDetailDark.surfacePurchased.withValues(alpha: 0.8)
            : FreshSproutColors.surfaceContainerLow.withValues(alpha: 0.7),
        borderRadius: _ListDetailSpec.cardRadius,
        child: InkWell(
          onTap: onToggle,
          borderRadius: _ListDetailSpec.cardRadius,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: _ListDetailSpec.cardRadius,
              border: Border.all(
                color: isDarkMode
                    ? FreshSproutColors.darkBorder.withValues(alpha: 0.7)
                    : FreshSproutColors.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(_ListDetailSpec.cardPaddingSm),
              child: Row(
                children: [
                  Container(
                    width: _ListDetailSpec.checkSize,
                    height: _ListDetailSpec.checkSize,
                    decoration: BoxDecoration(
                      gradient: isDarkMode
                          ? _ListDetailDark.checkGradient
                          : null,
                      color: isDarkMode ? null : FreshSproutColors.primary,
                      borderRadius: _ListDetailSpec.buttonRadius,
                      border: isDarkMode
                          ? Border.all(
                              color: _ListDetailDark.emerald400
                                  .withValues(alpha: 0.4),
                            )
                          : null,
                      boxShadow: isDarkMode
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      Icons.check,
                      size: 18,
                      color: isDarkMode
                          ? Colors.white
                          : FreshSproutColors.onPrimary,
                    ),
                  ),
                  const SizedBox(width: _ListDetailSpec.cardPaddingSm),
                  _ItemThumbnail(
                    isDarkMode: isDarkMode,
                    item: item,
                    size: _ListDetailSpec.thumbSizeChecked,
                    desaturate: true,
                  ),
                  const SizedBox(width: _ListDetailSpec.cardPaddingSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _ListDetailTypography.bodyMd(
                                  context,
                                  color: isDarkMode
                                      ? FreshSproutColors.darkTextSecondary
                                      : null,
                                ).copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: lineColor,
                                ),
                              ),
                            ),
                            if (price != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                'R\$ ${formatPrice(price)}',
                                style: _ListDetailTypography.bodySm(
                                  context,
                                  color: isDarkMode
                                      ? FreshSproutColors.darkTextPrimary
                                      : null,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          '$quantityLabel • $category',
                          style: _ListDetailTypography.bodySm(
                            context,
                            color: isDarkMode
                                ? FreshSproutColors.darkTextMuted
                                : null,
                          ),
                        ),
                      ],
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

class _ItemThumbnail extends StatelessWidget {
  const _ItemThumbnail({
    required this.isDarkMode,
    required this.item,
    required this.size,
    this.desaturate = false,
  });

  final bool isDarkMode;
  final ListItem item;
  final double size;
  final bool desaturate;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDarkMode
            ? FreshSproutColors.darkBackground
            : FreshSproutColors.surfaceContainerLow,
        borderRadius: _ListDetailSpec.buttonRadius,
        border: Border.all(
          color: isDarkMode
              ? FreshSproutColors.darkBorder
              : FreshSproutColors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Icon(
        _placeholderIcon(item),
        size: size * 0.55,
        color: isDarkMode
            ? _ListDetailDark.amber
            : FreshSproutColors.tertiary,
      ),
    );

    if (item.imageUrl == null) return placeholder;

    Widget image = Image.network(
      item.imageUrl!,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );

    if (desaturate) {
      image = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.75, 0.20, 0.05, 0, 0,
          0.15, 0.70, 0.15, 0, 0,
          0.10, 0.15, 0.75, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: image,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: _ListDetailSpec.buttonRadius,
        border: Border.all(
          color: isDarkMode
              ? FreshSproutColors.darkBorder
              : FreshSproutColors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: _ListDetailSpec.buttonRadius,
        child: SizedBox(width: size, height: size, child: image),
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  const _CategoryTag({required this.category, required this.isDarkMode});

  final String category;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isDarkMode
            ? _ListDetailDark.surfaceElevated
            : FreshSproutColors.surfaceContainerHigh,
        borderRadius: FreshSproutRadius.fullBorder,
        border: isDarkMode
            ? Border.all(color: FreshSproutColors.darkBorder)
            : null,
      ),
      child: Text(
        category,
        style: _ListDetailTypography.labelSm(
          context,
          color: isDarkMode
              ? FreshSproutColors.darkTextSecondary
              : FreshSproutColors.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ).copyWith(letterSpacing: 0),
      ),
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  const _QuickAddButton({
    required this.isDarkMode,
    required this.onAdd,
    required this.onScan,
  });

  final bool isDarkMode;
  final VoidCallback onAdd;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final accent = isDarkMode
        ? _ListDetailDark.greenLight
        : FreshSproutColors.primary;

    return Material(
      color: isDarkMode
          ? _ListDetailDark.surface.withValues(alpha: 0.7)
          : FreshSproutColors.surfaceContainerLow,
      borderRadius: _ListDetailSpec.cardRadius,
      child: InkWell(
        onTap: onAdd,
        borderRadius: _ListDetailSpec.cardRadius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: _ListDetailSpec.cardRadius,
            border: Border.all(
              color: isDarkMode
                  ? _ListDetailDark.green.withValues(alpha: 0.5)
                  : accent.withValues(alpha: 0.4),
              style: BorderStyle.solid,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _ListDetailSpec.cardPadding,
              vertical: _ListDetailSpec.cardPaddingSm,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 20,
                  color: isDarkMode ? _ListDetailDark.emerald400 : accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '+ Adicionar item não planejado',
                    style: _ListDetailTypography.bodyMd(
                      context,
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onScan,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        size: 16,
                        color: (isDarkMode
                                ? FreshSproutColors.darkTextMuted
                                : FreshSproutColors.onSurfaceVariant)
                            .withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Bipar',
                        style: _ListDetailTypography.bodySm(
                          context,
                          color: (isDarkMode
                                  ? FreshSproutColors.darkTextMuted
                                  : FreshSproutColors.onSurfaceVariant)
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
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

class _CheckoutFooter extends StatelessWidget {
  const _CheckoutFooter({
    required this.isDarkMode,
    required this.cartTotal,
    required this.savings,
    required this.onPause,
    required this.onCheckout,
  });

  final bool isDarkMode;
  final double cartTotal;
  final double savings;
  final VoidCallback onPause;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final primary = isDarkMode
        ? _ListDetailDark.green
        : FreshSproutColors.primary;
    final onPrimary = isDarkMode
        ? Colors.white
        : FreshSproutColors.onPrimary;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: (isDarkMode
                    ? FreshSproutColors.darkBackground
                    : FreshSproutColors.surfaceContainerLowest)
                .withValues(alpha: 0.95),
            border: Border(
              top: BorderSide(
                color: isDarkMode
                    ? FreshSproutColors.darkBorder
                    : FreshSproutColors.surfaceContainer,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withValues(alpha: 0.5)
                    : FreshSproutColors.shadowTint.withValues(alpha: 0.08),
                blurRadius: 30,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                FreshSproutSpacing.marginMobile,
                _ListDetailSpec.cardPaddingSm,
                FreshSproutSpacing.marginMobile,
                _ListDetailSpec.blockGap,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL NO CARRINHO',
                            style: _ListDetailTypography.labelSm(
                              context,
                              color: isDarkMode
                                  ? FreshSproutColors.darkTextMuted
                                  : FreshSproutColors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            'R\$ ${formatPrice(cartTotal)}',
                            style: _ListDetailTypography.headlineMd(
                              context,
                              color: isDarkMode
                                  ? FreshSproutColors.darkTextPrimary
                                  : null,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Economia est.:',
                            style: _ListDetailTypography.bodySm(
                              context,
                              color: isDarkMode
                                  ? FreshSproutColors.darkTextMuted
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? _ListDetailDark.emeraldChipBg
                                  : FreshSproutColors.secondaryContainer
                                      .withValues(alpha: 0.5),
                              borderRadius: FreshSproutRadius.fullBorder,
                              border: isDarkMode
                                  ? Border.all(
                                      color: _ListDetailDark.emeraldChipBorder,
                                    )
                                  : null,
                            ),
                            child: Text(
                              'R\$ ${formatPrice(savings)}',
                              style: _ListDetailTypography.labelMd(
                                context,
                                color: isDarkMode
                                    ? _ListDetailDark.emerald300
                                    : FreshSproutColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: _ListDetailSpec.blockGap),
                  Row(
                    children: [
                      Material(
                        color: isDarkMode
                            ? _ListDetailDark.surface
                            : FreshSproutColors.surfaceContainer,
                        borderRadius: _ListDetailSpec.cardRadius,
                        child: InkWell(
                          onTap: onPause,
                          borderRadius: _ListDetailSpec.cardRadius,
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: _ListDetailSpec.cardRadius,
                              border: isDarkMode
                                  ? Border.all(
                                      color: FreshSproutColors.darkBorder,
                                    )
                                  : null,
                            ),
                            child: SizedBox(
                              height: 48,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: _ListDetailSpec.cardPadding,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.pause,
                                      size: 20,
                                      color: isDarkMode
                                          ? FreshSproutColors.darkTextSecondary
                                          : FreshSproutColors
                                              .onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Pausar',
                                      style: _ListDetailTypography.bodyMd(
                                        context,
                                        color: isDarkMode
                                            ? FreshSproutColors
                                                .darkTextSecondary
                                            : FreshSproutColors
                                                .onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: _ListDetailSpec.blockGap),
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: _ListDetailSpec.cardRadius,
                          child: InkWell(
                            onTap: onCheckout,
                            borderRadius: _ListDetailSpec.cardRadius,
                            child: Ink(
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: _ListDetailSpec.cardRadius,
                                gradient: isDarkMode
                                    ? _ListDetailDark.greenGradient
                                    : null,
                                color: isDarkMode ? null : primary,
                                border: isDarkMode
                                    ? Border.all(
                                        color: _ListDetailDark.emerald400
                                            .withValues(alpha: 0.3),
                                      )
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: primary.withValues(
                                      alpha: isDarkMode ? 0.35 : 0.3,
                                    ),
                                    blurRadius: isDarkMode ? 16 : 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shopping_cart_checkout_outlined,
                                    size: 22,
                                    color: onPrimary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Finalizar Compra',
                                    style: _ListDetailTypography.bodyMd(
                                      context,
                                      color: onPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.isDarkMode,
    required this.icon,
    required this.onPressed,
  });

  final bool isDarkMode;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _ListDetailSpec.iconBtnSize,
      height: _ListDetailSpec.iconBtnSize,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          hoverColor: isDarkMode
              ? _ListDetailDark.surface
              : FreshSproutColors.surfaceContainerLow,
          child: Icon(
            icon,
            size: 24,
            color: isDarkMode
                ? FreshSproutColors.darkTextSecondary
                : FreshSproutColors.onSurface,
          ),
        ),
      ),
    );
  }
}

class _FilterEmptyHint extends StatelessWidget {
  const _FilterEmptyHint({
    required this.isDarkMode,
    required this.message,
  });

  final bool isDarkMode;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          message,
          style: _ListDetailTypography.bodySm(
            context,
            color: isDarkMode
                ? FreshSproutColors.darkTextMuted
                : FreshSproutColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _EmptyItemsState extends StatelessWidget {
  const _EmptyItemsState({
    required this.isDarkMode,
    required this.onAddItem,
    required this.onScan,
  });

  final bool isDarkMode;
  final VoidCallback onAddItem;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final accent =
        isDarkMode ? FreshSproutColors.darkAccent : FreshSproutColors.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_basket_outlined,
              size: 64,
              color: accent.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Lista vazia',
              style: _ListDetailTypography.headlineSm(context),
            ),
            const SizedBox(height: 8),
            Text(
              'Escaneie códigos de barras ou adicione itens manualmente.',
              textAlign: TextAlign.center,
              style: _ListDetailTypography.bodyMd(
                context,
                color: isDarkMode
                    ? FreshSproutColors.darkTextMuted
                    : FreshSproutColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Escanear produto'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onAddItem,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar manualmente'),
            ),
          ],
        ),
      ),
    );
  }
}
