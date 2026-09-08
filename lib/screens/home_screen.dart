import 'package:flutter/material.dart';

import '../models/shopping_list.dart';
import '../services/shopping_list_repository.dart';
import '../utils/date_formatter.dart';
import 'create_list_screen.dart';
import 'list_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repository = ShoppingListRepository.instance;
  List<ShoppingList> _lists = [];
  String? _selectedListId;

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
      MaterialPageRoute(
        builder: (context) => const CreateListScreen(),
      ),
    );

    if (created != true || !mounted) return;

    _loadLists();
  }

  void _clearSelection() {
    setState(() => _selectedListId = null);
  }

  void _selectList(String listId) {
    setState(() => _selectedListId = listId);
  }

  void _onCardTap(ShoppingList list) {
    if (_selectedListId != null) {
      if (_selectedListId == list.id) {
        _clearSelection();
      } else {
        _selectList(list.id);
      }
      return;
    }

    _openList(list);
  }

  Future<void> _deleteSelectedList() async {
    final selectedId = _selectedListId;
    if (selectedId == null) return;

    final index = _lists.indexWhere((item) => item.id == selectedId);
    if (index == -1) {
      _clearSelection();
      return;
    }

    final list = _lists[index];

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
    _clearSelection();
    _loadLists();
  }

  Future<void> _openList(ShoppingList list) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ListDetailScreen(listId: list.id),
      ),
    );
    _loadLists();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedListId == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedListId != null) {
          _clearSelection();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ListMarket'),
          actions: [
            IconButton(
              onPressed: _createList,
              icon: const Icon(Icons.add),
              tooltip: 'Nova lista',
            ),
            if (_selectedListId != null)
              IconButton(
                onPressed: _deleteSelectedList,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Excluir lista',
              ),
          ],
        ),
        body: _lists.isEmpty
            ? _EmptyState(onCreateList: _createList)
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _lists.length,
                separatorBuilder: (context, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final list = _lists[index];
                  return _ListCard(
                    list: list,
                    isSelected: _selectedListId == list.id,
                    onTap: () => _onCardTap(list),
                    onLongPress: () => _selectList(list.id),
                  );
                },
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateList});

  final VoidCallback onCreateList;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma lista ainda',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Crie sua primeira lista de compras. Ela ficará salva no seu celular.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreateList,
              icon: const Icon(Icons.add),
              label: const Text('Criar lista'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.list,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  static const _cardBlue = Color(0xFF1976D2);
  static const _selectedBlue = Color(0xFF0D47A1);

  final ShoppingList list;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final totalItems = list.items.length;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: isSelected ? _selectedBlue : _cardBlue,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: Colors.white, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      list.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Atualizada em ${formatDate(list.updatedAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                    ),
                    if (totalItems > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${list.pendingCount} pendente(s) · ${list.purchasedCount} comprado(s)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                      ),
                    ] else
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Nenhum item adicionado',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                        ),
                      ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
