import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';

import '../models/list_item.dart';
import '../models/product_lookup_result.dart';
import '../services/open_food_facts_service.dart';
import '../services/shopping_list_repository.dart';
import '../widgets/item_form_dialog.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key, required this.listId});

  final String listId;

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final _repository = ShoppingListRepository.instance;
  final _api = OpenFoodFactsService();
  final _uuid = const Uuid();

  late final MobileScannerController _controller;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (barcode == null || barcode.isEmpty) return;

    setState(() => _isProcessing = true);

    await _controller.stop();

    if (!mounted) return;

    final result = await _api.lookupBarcode(barcode);

    if (!mounted) return;

    switch (result) {
      case ProductLookupSuccess(:final product):
        await _showProductFoundDialog(product);
      case ProductLookupNotFound(:final barcode):
        await _showManualEntry(
          barcode: barcode,
          message: 'Produto não encontrado na base de dados.',
        );
      case ProductLookupConnectionError(:final barcode):
        await _showManualEntry(
          barcode: barcode,
          message: 'Sem conexão. Você pode adicionar o item manualmente.',
        );
    }

    if (!mounted) return;

    setState(() => _isProcessing = false);
    await _controller.start();
  }

  Future<void> _showProductFoundDialog(ProductInfo product) async {
    final add = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Produto encontrado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (product.imageUrl != null) ...[
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product.imageUrl!,
                      height: 120,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                product.displayName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text('Código: ${product.barcode}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Adicionar à lista'),
            ),
          ],
        );
      },
    );

    if (add != true || !mounted) return;

    await _saveItem(
      ListItem(
        id: _uuid.v4(),
        name: product.displayName,
        barcode: product.barcode,
        imageUrl: product.imageUrl,
      ),
    );
  }

  Future<void> _showManualEntry({
    required String barcode,
    required String message,
  }) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar manualmente'),
          content: Text('$message\n\nCódigo: $barcode'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openManualForm(barcode);
              },
              child: const Text('Digitar nome'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openManualForm(String barcode) async {
    final formResult = await showItemFormDialog(
      context,
      initialName: '',
      dialogTitle: 'Adicionar item',
      helperText: 'Código de barras: $barcode',
    );

    if (formResult == null || !mounted) return;

    await _saveItem(
      ListItem(
        id: _uuid.v4(),
        name: formResult.name,
        price: formResult.price,
        quantity: formResult.quantity,
        barcode: barcode,
      ),
    );
  }

  Future<void> _saveItem(ListItem item) async {
    await _repository.addItem(widget.listId, item);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${item.name}" adicionado à lista')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear código de barras'),
        actions: [
          IconButton(
            onPressed: () => _controller.toggleTorch(),
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, _) {
                final enabled = state.torchState == TorchState.on;
                return Icon(enabled ? Icons.flash_on : Icons.flash_off);
              },
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onBarcodeDetected,
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 280,
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Buscando produto...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
