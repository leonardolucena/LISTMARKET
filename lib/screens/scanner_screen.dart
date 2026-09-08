import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';

import '../models/list_item.dart';
import '../models/product_lookup_result.dart';
import '../models/scan_mode.dart';
import '../services/label_text_parser.dart';
import '../services/open_food_facts_service.dart';
import '../services/shopping_list_repository.dart';
import '../services/shelf_label_ocr_service.dart';
import '../widgets/item_form_dialog.dart';
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

  Timer? _inactivityTimer;
  bool _showingBatterySaver = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _initCurrentMode();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _barcodeController?.dispose();
    _cameraController?.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    if (!_isReady || _isProcessing || _showingBatterySaver) return;

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
    if (!mounted || _isProcessing || _showingBatterySaver) return;
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
    setState(() {
      _isReady = false;
      _torchEnabled = false;
    });

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

  Future<void> _switchMode(ScanMode mode) async {
    if (_mode == mode || _isProcessing) return;
    _resetInactivityTimer();
    setState(() => _mode = mode);
    await _initCurrentMode();
  }

  Future<void> _toggleTorch() async {
    if (!_isReady || _isProcessing) return;
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

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_mode != ScanMode.barcode || _isProcessing) return;

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
        await _showProductFoundDialog(product);
      case ProductLookupNotFound(:final barcode):
        await _showManualBarcodeEntry(
          barcode: barcode,
          message: 'Produto não encontrado na base de dados.',
        );
      case ProductLookupConnectionError(:final barcode):
        await _showManualBarcodeEntry(
          barcode: barcode,
          message: 'Sem conexão. Você pode adicionar o item manualmente.',
        );
    }

    if (!mounted) return;

    setState(() => _isProcessing = false);
    await _barcodeController?.start();
    _resetInactivityTimer();
  }

  Future<void> _captureAndScanLabel() async {
    final controller = _cameraController;
    if (_mode != ScanMode.shelfLabel ||
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

      await _confirmShelfLabel(result);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao ler etiqueta: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
        _resetInactivityTimer();
      }
    }
  }

  Future<void> _showProductFoundDialog(ProductInfo product) async {
    final brandLine = product.brand != null && product.brand!.isNotEmpty
        ? 'Marca: ${product.brand}\n'
        : '';

    final formResult = await showItemFormDialog(
      context,
      initialName: product.name,
      dialogTitle: 'Produto encontrado',
      helperText: '${brandLine}Código: ${product.barcode}',
      imageUrl: product.imageUrl,
    );

    if (formResult == null || !mounted) return;

    await _saveItem(
      ListItem(
        id: _uuid.v4(),
        name: formResult.name,
        brand: product.brand,
        price: formResult.price,
        quantity: formResult.quantity,
        barcode: product.barcode,
        imageUrl: product.imageUrl,
      ),
    );
  }

  Future<void> _showManualBarcodeEntry({
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
                _openManualForm(barcode: barcode);
              },
              child: const Text('Digitar nome'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openManualForm({String? barcode}) async {
    final formResult = await showItemFormDialog(
      context,
      initialName: '',
      dialogTitle: 'Adicionar item',
      helperText: barcode != null ? 'Código de barras: $barcode' : null,
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

  Future<void> _confirmShelfLabel(ShelfLabelScanResult result) async {
    final formResult = await showItemFormDialog(
      context,
      initialName: result.name ?? '',
      initialPrice: result.price?.toStringAsFixed(2) ?? '',
      dialogTitle: 'Item da etiqueta',
      helperText: 'Confira o nome e o preço antes de salvar.',
    );

    if (formResult == null || !mounted) return;

    await _saveItem(
      ListItem(
        id: _uuid.v4(),
        name: formResult.name,
        price: formResult.price,
        quantity: formResult.quantity,
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

  @override
  Widget build(BuildContext context) {
    final guide = _mode.guideSize;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Escanear produto'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (_isReady)
            IconButton(
              onPressed: _isProcessing ? null : _toggleTorch,
              icon: Icon(_torchEnabled ? Icons.flash_on : Icons.flash_off),
              tooltip: 'Lanterna',
            ),
        ],
      ),
      body: Listener(
        onPointerDown: (_) => _resetInactivityTimer(),
        child: Stack(
        fit: StackFit.expand,
        children: [
          _buildCameraPreview(),
          ScannerOverlay(
            guideWidth: guide.width,
            guideHeight: guide.height,
            hint: _mode.hint,
          ),
          if (_mode == ScanMode.shelfLabel && _isReady)
            Positioned(
              left: 16,
              right: 16,
              bottom: 88,
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
                      onPressed: _isProcessing ? null : _captureAndScanLabel,
                      child: const Icon(Icons.camera_alt),
                    ),
                  ),
                ],
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SegmentedButton<ScanMode>(
              style: SegmentedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                selectedBackgroundColor: Colors.white,
                selectedForegroundColor: colorScheme.primary,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
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
          if (_isProcessing)
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
                Text(
                  '$_secondsRemaining',
                  style: countdownStyle,
                ),
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
