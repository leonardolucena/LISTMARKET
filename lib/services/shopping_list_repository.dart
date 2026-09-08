import 'package:hive_flutter/hive_flutter.dart';

import '../models/list_item.dart';
import '../models/shopping_list.dart';

class ShoppingListRepository {
  ShoppingListRepository._();

  static final ShoppingListRepository instance = ShoppingListRepository._();

  static const _boxName = 'shopping_lists';

  Box<Map>? _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<Map>(_boxName);
  }

  List<ShoppingList> getAllLists() {
    final lists = _box!.values
        .map((value) => ShoppingList.fromJson(Map<String, dynamic>.from(value)))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return lists;
  }

  ShoppingList? getListById(String id) {
    final value = _box!.get(id);
    if (value == null) return null;
    return ShoppingList.fromJson(Map<String, dynamic>.from(value));
  }

  Future<ShoppingList> createList(String name) async {
    final now = DateTime.now();
    final list = ShoppingList(
      id: now.microsecondsSinceEpoch.toString(),
      name: name.trim(),
      createdAt: now,
      updatedAt: now,
    );
    await _save(list);
    return list;
  }

  Future<void> updateList(ShoppingList list) async {
    await _save(list.copyWith(updatedAt: DateTime.now()));
  }

  Future<void> deleteList(String id) async {
    await _box!.delete(id);
  }

  Future<void> addItem(String listId, ListItem item) async {
    final list = getListById(listId);
    if (list == null) return;

    await updateList(
      list.copyWith(items: [...list.items, item]),
    );
  }

  Future<void> updateItem(String listId, ListItem updatedItem) async {
    final list = getListById(listId);
    if (list == null) return;

    final items = list.items
        .map((item) => item.id == updatedItem.id ? updatedItem : item)
        .toList();

    await updateList(list.copyWith(items: items));
  }

  Future<void> deleteItem(String listId, String itemId) async {
    final list = getListById(listId);
    if (list == null) return;

    final items = list.items.where((item) => item.id != itemId).toList();
    await updateList(list.copyWith(items: items));
  }

  Future<void> _save(ShoppingList list) async {
    await _box!.put(list.id, list.toJson());
  }
}
