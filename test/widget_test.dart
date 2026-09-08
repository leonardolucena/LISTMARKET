import 'package:flutter_test/flutter_test.dart';
import 'package:listmarket/models/list_item.dart';
import 'package:listmarket/models/shopping_list.dart';

void main() {
  test('ShoppingList serializa e desserializa corretamente', () {
    final list = ShoppingList(
      id: '1',
      name: 'Compras',
      createdAt: DateTime(2026, 3, 8),
      updatedAt: DateTime(2026, 3, 8, 12, 30),
      items: [
        ListItem(
          id: 'a',
          name: 'Arroz',
          price: 12.99,
          quantity: 2,
          isPurchased: false,
        ),
      ],
    );

    final restored = ShoppingList.fromJson(list.toJson());

    expect(restored.id, list.id);
    expect(restored.name, list.name);
    expect(restored.items.length, 1);
    expect(restored.items.first.name, 'Arroz');
    expect(restored.pendingCount, 1);
    expect(restored.purchasedCount, 0);
  });
}
