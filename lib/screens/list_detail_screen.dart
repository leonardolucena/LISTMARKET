import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/list_item.dart';
import '../models/scan_mode.dart';
import '../models/shopping_list.dart';
import '../services/shopping_list_repository.dart';
import '../utils/date_formatter.dart';
import '../widgets/item_form_dialog.dart';
import 'scanner_screen.dart';

class ListDetailScreen extends StatefulWidget {
  const ListDetailScreen({super.key, required this.listId});

  final String listId;

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  final _repository = ShoppingListRepository.instance;
  final _uuid = const Uuid();
  ShoppingList? _list;

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
          content: Text(
            'Deseja excluir "${item.titleText}" da lista?',
          ),
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

  @override
  Widget build(BuildContext context) {
    final list = _list;

    if (list == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lista')),
        body: const Center(child: Text('Lista não encontrada')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(list.name),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
            tooltip: 'Adicionar item',
          ),
          IconButton(
            onPressed: () => _openScanner(),
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Escanear produto',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: list.items.isEmpty
                ? _EmptyItemsState(
                    onAddItem: _addItem,
                    onScan: () => _openScanner(),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.items.length,
                    separatorBuilder: (context, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = list.items[index];
                      return _ItemTile(
                        item: item,
                        onToggle: () => _togglePurchased(item),
                        onEdit: () => _editItem(item),
                        onDelete: () => _deleteItem(item),
                      );
                    },
                  ),
          ),
          if (list.items.isNotEmpty)
            _TotalFooter(total: list.totalValue),
        ],
      ),
    );
  }
}

class _TotalFooter extends StatelessWidget {
  const _TotalFooter({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Valor total',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
              ),
              Text(
                'R\$ ${formatPrice(total)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
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

class _EmptyItemsState extends StatelessWidget {
  const _EmptyItemsState({
    required this.onAddItem,
    required this.onScan,
  });

  final VoidCallback onAddItem;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.list_alt_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Lista vazia',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Escaneie códigos de barras ou etiquetas de preço, ou adicione itens manualmente.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  static const _imageSize = 80.0;
  static const _actionWidth = 36.0;
  static const _lineHeight = 18.0;
  static const _topTextBehavior = TextHeightBehavior(
    applyHeightToFirstAscent: false,
    applyHeightToLastDescent: false,
  );

  final ListItem item;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final detailParts = <String>[];
    if (item.quantity > 1) {
      detailParts.add('Quantidade: ${item.quantity}');
    }
    if (item.price != null) {
      detailParts.add('Preço: ${formatPrice(item.price!)}');
    }

    final purchasedStyle = item.isPurchased
        ? TextStyle(
            decoration: TextDecoration.lineThrough,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          )
        : null;

    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _imageSize,
                height: _imageSize,
                child: item.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.imageUrl!,
                          width: _imageSize,
                          height: _imageSize,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _ImagePlaceholder(colorScheme: colorScheme),
                        ),
                      )
                    : _ImagePlaceholder(colorScheme: colorScheme),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: _imageSize,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        item.titleText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textHeightBehavior: _topTextBehavior,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              height: 1.15,
                            ).merge(purchasedStyle),
                      ),
                      SizedBox(
                        height: _lineHeight,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: item.brandText != null
                              ? Text(
                                  '(${item.brandText})',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textHeightBehavior: _topTextBehavior,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        height: 1.1,
                                        color: colorScheme.onSurfaceVariant,
                                      )
                                      .merge(purchasedStyle),
                                )
                              : null,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        height: _lineHeight,
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: detailParts.isNotEmpty
                              ? Text(
                                  detailParts.join(' | '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      )
                                      .merge(purchasedStyle),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: _imageSize,
                width: _actionWidth + 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ActionButton(
                      colorScheme: colorScheme,
                      icon: Icons.edit_outlined,
                      tooltip: 'Editar',
                      backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                      iconColor: colorScheme.primary.withValues(alpha: 0.85),
                      onPressed: onEdit,
                    ),
                    const SizedBox(height: 6),
                    _ActionButton(
                      colorScheme: colorScheme,
                      icon: Icons.delete_outline,
                      tooltip: 'Excluir',
                      backgroundColor: colorScheme.error.withValues(alpha: 0.12),
                      iconColor: colorScheme.error.withValues(alpha: 0.75),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.colorScheme,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.backgroundColor,
    this.iconColor,
  });

  final ColorScheme colorScheme;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        width: _ItemTile._actionWidth + 4,
        height: 37,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 20, color: iconColor),
          tooltip: tooltip,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.shopping_bag_outlined,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
