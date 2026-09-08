import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';

import '../models/list_item.dart';
import '../models/product_lookup_result.dart';
import '../models/scan_mode.dart';
import '../services/open_food_facts_service.dart';
import '../services/shopping_list_repository.dart';
import '../services/shelf_label_ocr_service.dart';
import '../utils/currency_input_formatter.dart';
import '../widgets/scanner_overlay.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({
    super.key,
    required this.listId,
    this.initialMode = ScanMode.barcode,
  });

  final String listId;
  final ScanMode initialMode;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _PendingProduct {
  _PendingProduct({
    this.name = '',
    this.brand,
    this.price,
    this.quantity = 1,
    this.barcode,
    this.imageUrl,
  });

  final String name;
  final String? brand;
  final double? price;
  final int quantity;
  final String? barcode;
  final String? imageUrl;
}

class _ScannerScreenState extends State<ScannerScreen> {
  static const _inactivityDuration = Duration(seconds: 20);
  static const _redirectCountdownSeconds = 5;

  final _repository = ShoppingListRepository.instance;
  final _api = OpenFoodFactsService();
  final _ocrService = ShelfLabelOcrService();
  final _uuid = const Uuid();

  late ScanMode _mode;

  MobileScannerController? _barcodeController;
  CameraController? _cameraController;

  bool _isReady = false;
  bool _isProcessing = false;
  bool _torchEnabled = false;
  double _zoomLevel = 1.0;

  _PendingProduct? _pendingProduct;
  TextEditingController? _nameController;
  TextEditingController? _priceController;
  TextEditingController? _quantityController;

  Timer? _inactivityTimer;
  bool _showingBatterySaver = false;

  bool get _isScanning => _pendingProduct == null;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _initCurrentMode();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _disposeProductControllers();
    _barcodeController?.dispose();
    _cameraController?.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  void _disposeProductControllers() {
    _nameController?.dispose();
    _priceController?.dispose();
    _quantityController?.dispose();
    _nameController = null;
    _priceController = null;
    _quantityController = null;
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    if (!_isScanning || !_isReady || _isProcessing || _showingBatterySaver) {
      return;
    }

    _inactivityTimer = Timer(_inactivityDuration, _onInactivityTimeout);
  }

  void _resetInactivityTimer() {
    if (_showingBatterySaver) return;
    _startInactivityTimer();
  }

  void _pauseInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  Future<void> _onInactivityTimeout() async {
    if (!mounted || !_isScanning || _isProcessing || _showingBatterySaver) {
      return;
    }
    await _showBatterySaverDialog();
  }

  Future<void> _showBatterySaverDialog() async {
    _showingBatterySaver = true;
    _pauseInactivityTimer();

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _BatterySaverCountdownDialog(
          initialSeconds: _redirectCountdownSeconds,
          onRedirect: () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
        );
      },
    );

    _showingBatterySaver = false;
    if (mounted) {
      _startInactivityTimer();
    }
  }

  Future<void> _initCurrentMode() async {
    _pauseInactivityTimer();
    setState(() => _isReady = false);

    if (_mode == ScanMode.barcode) {
      await _initBarcodeScanner();
    } else {
      await _initShelfCamera();
    }
  }

  Future<void> _initBarcodeScanner() async {
    await _cameraController?.dispose();
    _cameraController = null;

    final controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );

    if (!mounted) {
      await controller.dispose();
      return;
    }

    setState(() {
      _barcodeController = controller;
      _isReady = true;
      _torchEnabled = false;
    });
    _startInactivityTimer();
  }

  Future<void> _initShelfCamera() async {
    await _barcodeController?.dispose();
    _barcodeController = null;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isReady = true;
        _torchEnabled = false;
        _zoomLevel = 1.0;
      });
      _startInactivityTimer();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível abrir a câmera: $error')),
      );
    }
  }

  Future<void> _stopCameras() async {
    await _barcodeController?.stop();
    if (mounted) {
      setState(() => _isReady = false);
    }
  }

  Future<void> _switchMode(ScanMode mode) async {
    if (_mode == mode || _isProcessing) return;
    _resetInactivityTimer();

    if (_pendingProduct != null) {
      _clearPendingProduct(notify: false);
    }

    setState(() => _mode = mode);
    await _initCurrentMode();
  }

  Future<void> _toggleTorch() async {
    if (!_isScanning || !_isReady || _isProcessing) return;
    _resetInactivityTimer();

    if (_mode == ScanMode.barcode) {
      await _barcodeController?.toggleTorch();
      if (!mounted) return;
      setState(() => _torchEnabled = !_torchEnabled);
      return;
    }

    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    final nextMode = _torchEnabled ? FlashMode.off : FlashMode.torch;
    await controller.setFlashMode(nextMode);

    if (!mounted) return;
    setState(() => _torchEnabled = !_torchEnabled);
  }

  Future<void> _setZoom(double zoom) async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    _resetInactivityTimer();

    final maxZoom = await controller.getMaxZoomLevel();
    final minZoom = await controller.getMinZoomLevel();
    final target = zoom.clamp(minZoom, maxZoom);

    await controller.setZoomLevel(target);

    if (!mounted) return;
    setState(() => _zoomLevel = target);
  }

  void _setPendingProduct(_PendingProduct product) {
    _disposeProductControllers();
    _pauseInactivityTimer();
    _stopCameras();

    _nameController = TextEditingController(text: product.name);
    _priceController = TextEditingController(
      text: product.price != null
          ? CurrencyInputFormatter.formatDouble(product.price!)
          : '',
    );
    _quantityController = TextEditingController(
      text: product.quantity.toString(),
    );

    setState(() => _pendingProduct = product);
  }

  Future<void> _clearPendingProduct({bool notify = true}) async {
    _disposeProductControllers();
    if (notify && mounted) {
      setState(() => _pendingProduct = null);
    } else {
      _pendingProduct = null;
    }
    await _initCurrentMode();
  }

  Future<void> _handleBack() async {
    if (_pendingProduct != null) {
      await _clearPendingProduct();
      return;
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (!_isScanning || _mode != ScanMode.barcode || _isProcessing) return;

    final barcode = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (barcode == null || barcode.isEmpty) return;

    _resetInactivityTimer();
    setState(() => _isProcessing = true);
    _pauseInactivityTimer();
    await _barcodeController?.stop();

    if (!mounted) return;

    final result = await _api.lookupBarcode(barcode);

    if (!mounted) return;

    switch (result) {
      case ProductLookupSuccess(:final product):
        _setPendingProduct(
          _PendingProduct(
            name: product.name,
            brand: product.brand,
            barcode: product.barcode,
            imageUrl: product.imageUrl,
          ),
        );
      case ProductLookupNotFound(:final barcode):
        _setPendingProduct(
          _PendingProduct(barcode: barcode),
        );
      case ProductLookupConnectionError(:final barcode):
        _setPendingProduct(
          _PendingProduct(barcode: barcode),
        );
    }

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _captureAndScanLabel() async {
    final controller = _cameraController;
    if (!_isScanning ||
        _mode != ScanMode.shelfLabel ||
        controller == null ||
        !controller.value.isInitialized ||
        _isProcessing) {
      return;
    }

    setState(() => _isProcessing = true);
    _pauseInactivityTimer();

    try {
      await controller.setFocusMode(FocusMode.auto);
      if (controller.value.focusPointSupported) {
        await controller.setFocusPoint(const Offset(0.5, 0.5));
      }
      if (controller.value.exposurePointSupported) {
        await controller.setExposurePoint(const Offset(0.5, 0.5));
      }
      await Future.delayed(const Duration(milliseconds: 650));

      final photo = await controller.takePicture();
      final result = await _ocrService.scanImageFile(photo.path);

      if (!mounted) return;

      if (result == null || !result.hasData) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível ler a etiqueta. Enquadre só a etiqueta, '
              'use o zoom 2x e ligue o flash.',
            ),
          ),
        );
        return;
      }

      _setPendingProduct(
        _PendingProduct(
          name: result.name ?? '',
          price: result.price,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao ler etiqueta: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _openManualProduct() {
    _resetInactivityTimer();
    _setPendingProduct(_PendingProduct());
  }

  Future<void> _confirmPendingProduct() async {
    final name = _nameController?.text.trim() ?? '';
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome do produto')),
      );
      return;
    }

    final price = CurrencyInputFormatter.parseFormattedPrice(
      _priceController?.text ?? '',
    );
    final quantity =
        int.tryParse(_quantityController?.text.trim() ?? '') ?? 1;

    await _saveItem(
      ListItem(
        id: _uuid.v4(),
        name: name,
        brand: _pendingProduct?.brand,
        price: price,
        quantity: quantity < 1 ? 1 : quantity,
        barcode: _pendingProduct?.barcode,
        imageUrl: _pendingProduct?.imageUrl,
      ),
    );

    if (!mounted) return;

    await _clearPendingProduct();
  }

  Future<void> _saveItem(ListItem item) async {
    await _repository.addItem(widget.listId, item);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${item.name}" adicionado à lista')),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isReady) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (_mode == ScanMode.barcode) {
      return MobileScanner(
        controller: _barcodeController,
        onDetect: _onBarcodeDetected,
      );
    }

    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return CameraPreview(controller);
  }

  Widget _buildTopBar(ColorScheme colorScheme) {
    return Material(
      color: _isScanning ? Colors.black : colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 16, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: _isProcessing ? null : _handleBack,
                icon: Icon(
                  Icons.arrow_back,
                  color: _isScanning ? Colors.white : colorScheme.onSurface,
                ),
              ),
              Expanded(
                child: SegmentedButton<ScanMode>(
                  style: SegmentedButton.styleFrom(
                    backgroundColor: _isScanning
                        ? colorScheme.primary
                        : colorScheme.primaryContainer,
                    foregroundColor:
                        _isScanning ? Colors.white : colorScheme.onPrimaryContainer,
                    selectedBackgroundColor: Colors.white,
                    selectedForegroundColor: colorScheme.primary,
                    side: BorderSide(
                      color: _isScanning
                          ? Colors.white.withValues(alpha: 0.4)
                          : colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  segments: ScanMode.values
                      .map(
                        (mode) => ButtonSegment(
                          value: mode,
                          label: Text(mode.label),
                          icon: Icon(
                            mode == ScanMode.barcode
                                ? Icons.qr_code_scanner
                                : Icons.receipt_long,
                          ),
                        ),
                      )
                      .toList(),
                  selected: {_mode},
                  onSelectionChanged: _isProcessing
                      ? null
                      : (selection) => _switchMode(selection.first),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanLayout(ColorScheme colorScheme) {
    final guide = _mode.guideSize;

    return Column(
      children: [
        Expanded(
          flex: 1,
          child: Listener(
            onPointerDown: (_) => _resetInactivityTimer(),
            child: ColoredBox(
              color: Colors.black,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildCameraPreview(),
                  if (_isReady)
                    ScannerOverlay(
                      guideWidth: guide.width,
                      guideHeight: guide.height,
                      cornerBracketsOnly: true,
                    ),
                  if (_isReady)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        onPressed: _isProcessing ? null : _toggleTorch,
                        icon: Icon(
                          _torchEnabled ? Icons.flash_on : Icons.flash_off,
                          color: Colors.white,
                        ),
                        tooltip: 'Lanterna',
                      ),
                    ),
                  if (_mode == ScanMode.shelfLabel && _isReady)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _ZoomButton(
                                  label: '1.0x',
                                  selected: (_zoomLevel - 1.0).abs() < 0.1,
                                  onPressed: () => _setZoom(1.0),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ZoomButton(
                                  label: '2.0x',
                                  selected: (_zoomLevel - 2.0).abs() < 0.1,
                                  onPressed: () => _setZoom(2.0),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: FilledButton(
                              onPressed:
                                  _isProcessing ? null : _captureAndScanLabel,
                              child: const Icon(Icons.camera_alt),
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
        Expanded(
          flex: 1,
          child: ColoredBox(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        _mode == ScanMode.barcode
                            ? 'Leia um código de barras para identificar o produto'
                            : 'Enquadre a etiqueta de preço para ler nome e valor',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              height: 1.35,
                            ),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _isProcessing ? null : _openManualProduct,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.outline,
                              ),
                            ),
                            child: Icon(
                              Icons.add,
                              size: 18,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Novo produto',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductPreview(ColorScheme colorScheme) {
    final product = _pendingProduct!;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (product.imageUrl != null)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        product.imageUrl!,
                        height: 240,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            _ProductImagePlaceholder(colorScheme: colorScheme),
                      ),
                    ),
                  )
                else
                  _ProductImagePlaceholder(colorScheme: colorScheme),
                if (product.brand != null && product.brand!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Marca: ${product.brand}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
                if (product.barcode != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Código: ${product.barcode}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
                const SizedBox(height: 10),
                _LabeledInput(
                  label: 'Nome',
                  child: TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _LabeledInput(
                  label: 'Quantidade',
                  child: TextField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(height: 12),
                _LabeledInput(
                  label: 'Preço',
                  child: TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      prefixText: 'R\$ ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: _confirmPendingProduct,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Icon(Icons.arrow_forward, size: 28),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: _pendingProduct == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _pendingProduct != null) {
          _clearPendingProduct();
        }
      },
      child: Scaffold(
        backgroundColor: _isScanning ? Colors.black : colorScheme.surface,
        body: Column(
          children: [
            _buildTopBar(colorScheme),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _isScanning
                      ? _buildScanLayout(colorScheme)
                      : _buildProductPreview(colorScheme),
                  if (_isProcessing && _isScanning)
                    Container(
                      color: Colors.black54,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: Colors.white),
                            const SizedBox(height: 16),
                            Text(
                              _mode == ScanMode.barcode
                                  ? 'Buscando produto...'
                                  : 'Lendo etiqueta...',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledInput extends StatelessWidget {
  const _LabeledInput({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize:
                    (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) -
                        1,
              ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class _ProductImagePlaceholder extends StatelessWidget {
  const _ProductImagePlaceholder({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.shopping_bag_outlined,
          size: 72,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _BatterySaverCountdownDialog extends StatefulWidget {
  const _BatterySaverCountdownDialog({
    required this.initialSeconds,
    required this.onRedirect,
  });

  final int initialSeconds;
  final VoidCallback onRedirect;

  @override
  State<_BatterySaverCountdownDialog> createState() =>
      _BatterySaverCountdownDialogState();
}

class _BatterySaverCountdownDialogState
    extends State<_BatterySaverCountdownDialog> {
  late int _secondsRemaining;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.initialSeconds;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsRemaining <= 1) {
        timer.cancel();
        Navigator.of(context).pop();
        widget.onRedirect();
        return;
      }

      setState(() => _secondsRemaining--);
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final countdownStyle = Theme.of(context).textTheme.displayMedium?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize:
              (Theme.of(context).textTheme.displayMedium?.fontSize ?? 45) - 1,
        );

    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('Economia de bateria'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Para economia de bateria, você será redirecionado '
              'para a listagem em',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('$_secondsRemaining', style: countdownStyle),
                Text(
                  ' ${_secondsRemaining == 1 ? 'segundo' : 'segundos'}',
                  style: countdownStyle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: FilledButton.tonal(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        ),
        child: Text(label),
      ),
    );
  }
}
