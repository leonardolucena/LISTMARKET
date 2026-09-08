import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/list_item.dart';

class ItemFormResult {
  const ItemFormResult({
    required this.name,
    this.price,
    required this.quantity,
  });

  final String name;
  final double? price;
  final int quantity;
}

Future<ItemFormResult?> showItemFormDialog(
  BuildContext context, {
  ListItem? item,
  String initialName = '',
  String initialPrice = '',
  String? dialogTitle,
  String? helperText,
}) {
  final nameController = TextEditingController(text: item?.name ?? initialName);
  final priceController = TextEditingController(
    text: item?.price != null
        ? item!.price!.toStringAsFixed(2)
        : initialPrice,
  );
  final quantityController = TextEditingController(
    text: (item?.quantity ?? 1).toString(),
  );

  return showDialog<ItemFormResult>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(dialogTitle ?? (item == null ? 'Adicionar item' : 'Editar item')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (helperText != null) ...[
                Text(
                  helperText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  hintText: 'Ex.: Arroz 5kg',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Preço (opcional)',
                  hintText: 'Ex.: 12,99',
                  prefixText: 'R\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,\.]')),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantidade',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              final priceText = priceController.text.trim().replaceAll(',', '.');
              final price = priceText.isEmpty ? null : double.tryParse(priceText);
              final quantity = int.tryParse(quantityController.text.trim()) ?? 1;

              Navigator.of(context).pop(
                ItemFormResult(
                  name: name,
                  price: price,
                  quantity: quantity < 1 ? 1 : quantity,
                ),
              );
            },
            child: Text(item == null ? 'Adicionar' : 'Salvar'),
          ),
        ],
      );
    },
  );
}
