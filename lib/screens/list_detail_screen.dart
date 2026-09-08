import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/list_item.dart';
import '../models/shopping_list.dart';
import '../services/shopping_list_repository.dart';
import '../utils/date_formatter.dart';
import '../widgets/item_form_dialog.dart';
import 'barcode_scanner_screen.dart';

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

  Future<void> _scanBarcode() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BarcodeScannerScreen(listId: widget.listId),
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
            onPressed: _scanBarcode,
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Escanear código de barras',
          ),
        ],
      ),
      body: list.items.isEmpty
          ? _EmptyItemsState(onAddItem: _addItem, onScanBarcode: _scanBarcode)
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'scan',
            onPressed: _scanBarcode,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Escanear'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'add',
            onPressed: _addItem,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar item'),
          ),
        ],
      ),
    );
  }
}

class _EmptyItemsState extends StatelessWidget {
  const _EmptyItemsState({
    required this.onAddItem,
    required this.onScanBarcode,
  });

  final VoidCallback onAddItem;
  final VoidCallback onScanBarcode;

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
              'Adicione itens manualmente ou escaneie o código de barras.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onScanBarcode,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Escanear código'),
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

  final ListItem item;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[];
    if (item.quantity > 1) {
      subtitleParts.add('Qtd: ${item.quantity}');
    }
    if (item.price != null) {
      subtitleParts.add(formatPrice(item.price!));
    }

    return Card(
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: item.isPurchased,
              onChanged: (_) => onToggle(),
            ),
            if (item.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.imageUrl!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(width: 40, height: 40),
                ),
              ),
          ],
        ),
        title: Text(
          item.name,
          style: item.isPurchased
              ? TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )
              : null,
        ),
        subtitle: subtitleParts.isEmpty
            ? null
            : Text(subtitleParts.join(' · ')),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
              case 'delete':
                onDelete();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Editar')),
            PopupMenuItem(value: 'delete', child: Text('Excluir')),
          ],
        ),
      ),
    );
  }
}
