import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/list_item.dart';
import '../utils/currency_input_formatter.dart';

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
  String? imageUrl,
}) {
  final nameController = TextEditingController(text: item?.name ?? initialName);
  final priceController = TextEditingController(
    text: _initialPriceText(item, initialPrice),
  );
  final quantityController = TextEditingController(
    text: (item?.quantity ?? 1).toString(),
  );

  return showDialog<ItemFormResult>(
    context: context,
    builder: (context) {
      final dialogWidth = MediaQuery.sizeOf(context).width - 32;

      return AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        constraints: BoxConstraints(
          minWidth: dialogWidth,
          maxWidth: dialogWidth,
        ),
        title: Text(
          dialogTitle ?? (item == null ? 'Adicionar item' : 'Editar item'),
          textAlign: TextAlign.center,
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (imageUrl != null) ...[
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      height: 120,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
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
                  hintText: '0,00',
                  prefixText: 'R\$ ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
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

              final price = CurrencyInputFormatter.parseFormattedPrice(
                priceController.text,
              );
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

String _initialPriceText(ListItem? item, String initialPrice) {
  if (item?.price != null) {
    return CurrencyInputFormatter.formatDouble(item!.price!);
  }

  if (initialPrice.isEmpty) return '';

  final parsed = double.tryParse(initialPrice.replaceAll(',', '.'));
  if (parsed == null) return '';

  return CurrencyInputFormatter.formatDouble(parsed);
}
