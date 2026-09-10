import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

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
import '../theme/fresh_sprout_tokens.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/date_formatter.dart';
import '../widgets/scanner_overlay.dart';

abstract final class _ScannerSpec {
  static const idleViewportFraction = 0.42;
  static const productSheetMinFraction = 0.74;
  static const productSheetContentEstimate = 580.0;
  static const minCameraHeight = 148.0;
  static const maxCameraWhenProduct = 0.30;
  static const productFoundViewportPaddingV = 15.0;
  static const layoutAnimationDuration = Duration(milliseconds: 320);
  static const sheetRadius = 28.0;
  static const sheetOverlap = 12.0;
  static const codePillToSheetGap = 4.0;
  static const codePillBottomInset = sheetOverlap + codePillToSheetGap;
  static const iconBtnSize = 40.0;
  static const thumbSize = 64.0;
  static const sheetGap = 14.0;
  static const fieldRadius = 12.0;
  static const stepperBtnSize = 32.0;
}

/// Tokens alinhados ao mock HTML (dark-bg / dark-surface / emerald-brand).
@immutable
class _ScannerTheme {
  const _ScannerTheme({
    required this.viewportBg,
    required this.sheetBg,
    required this.cardBg,
    required this.cardSoft,
    required this.border,
    required this.muted,
    required this.textPrimary,
    required this.textSecondary,
    required this.emerald,
    required this.emeraldDark,
    required this.pillBg,
    required this.pillText,
    required this.pillBorder,
    required this.amber,
    required this.amberBadgeBg,
    required this.amberBadgeBorder,
    required this.handle,
    required this.topBarBtnBg,
    required this.topBarBtnBorder,
    required this.footerBg,
    required this.cta,
    required this.ctaHover,
    required this.onCta,
    required this.ctaGlow,
    required this.cardShadow,
  });

  factory _ScannerTheme.of(bool isDark) {
    if (isDark) {
      return const _ScannerTheme(
        viewportBg: Color(0xFF0B0E17),
        sheetBg: Color(0xFF191D2D),
        cardBg: Color(0xFF222738),
        cardSoft: Color(0xFF1E2436),
        border: Color(0xFF34394B),
        muted: Color(0xFF94A3B8),
        textPrimary: Color(0xFFFFFFFF),
        textSecondary: Color(0xFFCBD5E1),
        emerald: Color(0xFF10B981),
        emeraldDark: Color(0xFF0D8259),
        pillBg: Color(0xFF0D3B28),
        pillText: Color(0xFF34D399),
        pillBorder: Color(0x4D10B981),
        amber: Color(0xFFF1A410),
        amberBadgeBg: Color(0xFF38260B),
        amberBadgeBorder: Color(0x4DF1A410),
        handle: Color(0xFF34394B),
        topBarBtnBg: Color(0xCC222738),
        topBarBtnBorder: Color(0xFF34394B),
        footerBg: Color(0xFF191D2D),
        cta: Color(0xFF0D8259),
        ctaHover: Color(0xFF10B981),
        onCta: Color(0xFFFFFFFF),
        ctaGlow: Color(0x4D10B981),
        cardShadow: Color(0x4D000000),
      );
    }
    return const _ScannerTheme(
      viewportBg: Color(0xFFE8F5EA),
      sheetBg: Color(0xFFF4FBF4),
      cardBg: Color(0xFFFFFFFF),
      cardSoft: Color(0xFFEEF8EF),
      border: Color(0xFFD9E8DA),
      muted: Color(0xFF617467),
      textPrimary: Color(0xFF1E293B),
      textSecondary: Color(0xFF475569),
      emerald: Color(0xFF10B981),
      emeraldDark: Color(0xFF0D8259),
      pillBg: Color(0xFFD1FAE5),
      pillText: Color(0xFF0D8259),
      pillBorder: Color(0x4D0D8259),
      amber: Color(0xFFD88E07),
      amberBadgeBg: Color(0xFFFFF3D6),
      amberBadgeBorder: Color(0x4DF1A410),
      handle: Color(0xFFD9E8DA),
      topBarBtnBg: Color(0xCCFFFFFF),
      topBarBtnBorder: Color(0xFFD9E8DA),
      footerBg: Color(0xFFF4FBF4),
      cta: Color(0xFF0D8259),
      ctaHover: Color(0xFF10B981),
      onCta: Color(0xFFFFFFFF),
      ctaGlow: Color(0x4D0D8259),
      cardShadow: Color(0x1A0D3B28),
    );
  }

  final Color viewportBg;
  final Color sheetBg;
  final Color cardBg;
  final Color cardSoft;
  final Color border;
  final Color muted;
  final Color textPrimary;
  final Color textSecondary;
  final Color emerald;
  final Color emeraldDark;
  final Color pillBg;
  final Color pillText;
  final Color pillBorder;
  final Color amber;
  final Color amberBadgeBg;
  final Color amberBadgeBorder;
  final Color handle;
  final Color topBarBtnBg;
  final Color topBarBtnBorder;
  final Color footerBg;
  final Color cta;
  final Color ctaHover;
  final Color onCta;
  final Color ctaGlow;
  final Color cardShadow;

  TextStyle sheetLabelSm(BuildContext context) =>
      Theme.of(context).textTheme.labelSmall!.copyWith(
            fontSize: 10,
            height: 14 / 10,
            letterSpacing: 0.4,
            fontWeight: FontWeight.w700,
            color: pillText,
          );

  TextStyle sheetHeadlineSm(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium!.copyWith(
            fontSize: 18,
            height: 24 / 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          );

  TextStyle sheetLabelMd(BuildContext context) =>
      Theme.of(context).textTheme.labelMedium!.copyWith(
            fontSize: 12,
            height: 16 / 12,
            letterSpacing: 0.24,
            fontWeight: FontWeight.w600,
          );

  TextStyle sheetBodySm(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall!.copyWith(
            fontSize: 12,
            height: 16 / 12,
            color: muted,
          );

  TextStyle sheetLabelLg(BuildContext context) =>
      Theme.of(context).textTheme.labelLarge!.copyWith(
            fontSize: 14,
            height: 18 / 14,
            letterSpacing: 0.14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          );

  /// Valor editável (nome do produto, preço) — mesma cor em ambos os campos.
  TextStyle sheetEditableName() => TextStyle(
        fontSize: 14,
        height: 18 / 14,
        letterSpacing: 0.14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  TextStyle sheetEditablePrice() => TextStyle(
        fontSize: 18,
        height: 24 / 18,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      );

  TextStyle sheetBtnLabel(BuildContext context) =>
      Theme.of(context).textTheme.labelLarge!.copyWith(
            fontSize: 14,
            height: 18 / 14,
            letterSpacing: 0.14,
            fontWeight: FontWeight.w700,
          );
}

const _measureUnits = ['Unidade', 'Kg', 'Gramas', 'Pacote'];

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({
    super.key,
    required this.listId,
    this.initialMode = ScanMode.barcode,
    this.isDarkMode,
  });

  final String listId;
  final ScanMode initialMode;
  final bool? isDarkMode;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _PendingProduct {
  _PendingProduct({
    this.name = '',
    this.brand,
    this.price,
    this.barcode,
    this.imageUrl,
  });

  final String name;
  final String? brand;
  final double? price;
  final int quantity = 1;
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
  String? _detectedBarcode;
  TextEditingController? _nameController;
  TextEditingController? _priceController;

  int _quantity = 1;
  String _measureUnit = 'Unidade';
  bool _markUnplanned = false;
  bool _updatePriceHistory = true;

  Timer? _inactivityTimer;
  bool _showingBatterySaver = false;
  int _cameraSession = 0;

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
    _nameController = null;
    _priceController = null;
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

  Future<void> _initCurrentMode({bool restart = false}) async {
    _pauseInactivityTimer();
    if (mounted) {
      setState(() => _isReady = false);
    }

    if (_mode == ScanMode.barcode) {
      await _initBarcodeScanner(restart: restart);
    } else {
      await _initShelfCamera(restart: restart);
    }
  }

  Future<void> _initBarcodeScanner({bool restart = false}) async {
    await _cameraController?.dispose();
    _cameraController = null;

    if (restart && _barcodeController != null) {
      await _barcodeController!.dispose();
      _barcodeController = null;
    }

    if (_barcodeController != null) {
      try {
        await _barcodeController!.start();
        if (mounted) {
          setState(() {
            _isReady = true;
            _torchEnabled = false;
          });
          _startInactivityTimer();
        }
        return;
      } on Object {
        await _barcodeController!.dispose();
        _barcodeController = null;
      }
    }

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

  Future<void> _initShelfCamera({bool restart = false}) async {
    if (restart && _cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null;
    }

    await _barcodeController?.dispose();
    _barcodeController = null;

    if (_cameraController != null &&
        _cameraController!.value.isInitialized) {
      if (mounted) {
        setState(() {
          _isReady = true;
          _torchEnabled = false;
        });
        _startInactivityTimer();
      }
      return;
    }

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

  Future<void> _switchMode(ScanMode mode) async {
    if (_mode == mode || _isProcessing) return;
    _resetInactivityTimer();

    if (_pendingProduct != null) {
      await _clearPendingProduct(notify: false);
    }

    if (mounted) {
      setState(() => _mode = mode);
    }
    await _initCurrentMode(restart: true);
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

  Future<void> _pauseActiveCamera() async {
    _pauseInactivityTimer();
    if (_mode == ScanMode.barcode) {
      await _barcodeController?.stop();
    }
  }

  Future<void> _setPendingProduct(_PendingProduct product) async {
    _disposeProductControllers();
    await _pauseActiveCamera();

    _nameController = TextEditingController(text: product.name);
    _priceController = TextEditingController(
      text: product.price != null
          ? CurrencyInputFormatter.formatDouble(product.price!)
          : '',
    );
    _quantity = product.quantity < 1 ? 1 : product.quantity;
    _detectedBarcode = product.barcode;
    _markUnplanned = false;
    _updatePriceHistory = true;
    _measureUnit = 'Unidade';

    if (mounted) {
      setState(() => _pendingProduct = product);
    }
  }

  Future<void> _scanAnotherProduct() async {
    await _clearPendingProduct();
  }

  Future<void> _clearPendingProduct({bool notify = true}) async {
    _disposeProductControllers();
    _detectedBarcode = null;
    _quantity = 1;
    _isProcessing = false;
    _cameraSession++;

    if (notify && mounted) {
      setState(() => _pendingProduct = null);
    } else {
      _pendingProduct = null;
    }

    await _initCurrentMode(restart: true);
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
    await _barcodeController?.stop();

    if (!mounted) return;

    final result = await _api.lookupBarcode(barcode);

    if (!mounted) return;

    switch (result) {
      case ProductLookupSuccess(:final product):
        await _setPendingProduct(
          _PendingProduct(
            name: product.name,
            brand: product.brand,
            barcode: product.barcode,
            imageUrl: product.imageUrl,
          ),
        );
      case ProductLookupNotFound(:final barcode):
        await _setPendingProduct(_PendingProduct(barcode: barcode));
      case ProductLookupConnectionError(:final barcode):
        await _setPendingProduct(_PendingProduct(barcode: barcode));
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

      await _setPendingProduct(
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

  Future<void> _openManualBarcode() async {
    _resetInactivityTimer();
    final controller = TextEditingController();
    final barcode = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Digitar código'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Código de barras (EAN)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Buscar'),
            ),
          ],
        );
      },
    );

    if (barcode == null || barcode.isEmpty || !mounted) return;

    setState(() => _isProcessing = true);
    final result = await _api.lookupBarcode(barcode);

    if (!mounted) return;

    switch (result) {
      case ProductLookupSuccess(:final product):
        await _setPendingProduct(
          _PendingProduct(
            name: product.name,
            brand: product.brand,
            barcode: product.barcode,
            imageUrl: product.imageUrl,
          ),
        );
      case ProductLookupNotFound(:final barcode):
        await _setPendingProduct(_PendingProduct(barcode: barcode));
      case ProductLookupConnectionError(:final barcode):
        await _setPendingProduct(_PendingProduct(barcode: barcode));
    }

    setState(() => _isProcessing = false);
  }

  Future<void> _openManualProduct() async {
    _resetInactivityTimer();
    await _setPendingProduct(_PendingProduct());
  }

  void _incrementQuantity() {
    setState(() => _quantity += 1);
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() => _quantity -= 1);
    }
  }

  double? get _unitPrice => CurrencyInputFormatter.parseFormattedPrice(
        _priceController?.text ?? '',
      );

  double get _subtotal {
    final price = _unitPrice ?? _pendingProduct?.price ?? 0;
    return price * _quantity;
  }

  double? get _habitualAverage {
    final price = _unitPrice ?? _pendingProduct?.price;
    if (price == null || price <= 0) return null;
    return price / 1.065;
  }

  Future<void> _confirmPendingProduct() async {
    final name = _nameController?.text.trim() ?? '';
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome do produto')),
      );
      return;
    }

    final price = _unitPrice;
    final quantity = _quantity < 1 ? 1 : _quantity;

    await _saveItem(
      ListItem(
        id: _uuid.v4(),
        name: name,
        brand: _pendingProduct?.brand,
        price: price,
        quantity: quantity,
        barcode: _pendingProduct?.barcode ?? _detectedBarcode,
        imageUrl: _pendingProduct?.imageUrl,
      ),
    );

    if (!mounted) return;

    Navigator.of(context).pop(true);
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
        key: ValueKey('barcode-scanner-$_cameraSession'),
        controller: _barcodeController,
        onDetect: _onBarcodeDetected,
      );
    }

    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return CameraPreview(
      controller,
      key: ValueKey('shelf-camera-$_cameraSession'),
    );
  }

  String _categoryForProduct(String name, String? brand) {
    final text = '$name ${brand ?? ''}'.toLowerCase();
    if (RegExp(r'café|cafe|matinal|torrado|moído|moido').hasMatch(text)) {
      return 'Mercearia / Matinais';
    }
    if (RegExp(r'leite|queijo|iogurte|latic').hasMatch(text)) {
      return 'Laticínios';
    }
    if (RegExp(r'tomate|banana|alface|horti|verdura|fruta').hasMatch(text)) {
      return 'Hortifruti';
    }
    if (RegExp(r'pão|pao|padaria').hasMatch(text)) {
      return 'Padaria';
    }
    return 'Mercearia';
  }

  String _storeLabel() {
    final list = _repository.getListById(widget.listId);
    if (list == null) return 'Local de compra';
    final name = list.name.toLowerCase();
    if (name.contains('feira')) return 'Feira Municipal Vila Madalena';
    if (name.contains('pão') || name.contains('pao')) {
      return 'Pão de Açúcar - Loja Jardins';
    }
    return list.name;
  }

  bool _isDark(BuildContext context) =>
      widget.isDarkMode ?? Theme.of(context).brightness == Brightness.dark;

  double _cameraViewportHeight(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    if (_pendingProduct == null) {
      return screenHeight * _ScannerSpec.idleViewportFraction;
    }

    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final targetSheetHeight = math.max(
      screenHeight * _ScannerSpec.productSheetMinFraction,
      _ScannerSpec.productSheetContentEstimate + bottomInset,
    );
    final cameraHeight = screenHeight -
        targetSheetHeight +
        _ScannerSpec.sheetOverlap;
    final maxCamera = screenHeight * _ScannerSpec.maxCameraWhenProduct;

    return cameraHeight.clamp(_ScannerSpec.minCameraHeight, maxCamera);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);
    final theme = _ScannerTheme.of(isDark);
    final viewportHeight = _cameraViewportHeight(context);

    return PopScope(
      canPop: _pendingProduct == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _pendingProduct != null) {
          _clearPendingProduct();
        }
      },
      child: Scaffold(
        backgroundColor: theme.viewportBg,
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              children: [
                AnimatedContainer(
                  duration: _ScannerSpec.layoutAnimationDuration,
                  curve: Curves.easeOutCubic,
                  height: viewportHeight,
                  child: _CameraViewport(
                    theme: theme,
                    mode: _mode,
                    isReady: _isReady,
                    isProcessing: _isProcessing,
                    zoomLevel: _zoomLevel,
                    detectedBarcode: _detectedBarcode,
                    productFound: _pendingProduct != null,
                    preview: _buildCameraPreview(),
                    onCaptureLabel: _captureAndScanLabel,
                    onSetZoom: _setZoom,
                    onResetTimer: _resetInactivityTimer,
                  ),
                ),
                Expanded(
                  child: Transform.translate(
                    offset: const Offset(0, -_ScannerSpec.sheetOverlap),
                    child: _ScannerBottomSheet(
                theme: theme,
                listId: widget.listId,
                mode: _mode,
                pendingProduct: _pendingProduct,
                isProcessing: _isProcessing,
                nameController: _nameController,
                priceController: _priceController,
                quantity: _quantity,
                measureUnit: _measureUnit,
                markUnplanned: _markUnplanned,
                updatePriceHistory: _updatePriceHistory,
                subtotal: _subtotal,
                unitPrice: _unitPrice ?? _pendingProduct?.price,
                habitualAverage: _habitualAverage,
                categoryLabel: _pendingProduct == null
                    ? null
                    : _categoryForProduct(
                        _nameController?.text ?? _pendingProduct!.name,
                        _pendingProduct!.brand,
                      ),
                storeLabel: _storeLabel(),
                onSwitchMode: _switchMode,
                onManualProduct: _openManualProduct,
                onIncrement: _incrementQuantity,
                onDecrement: _decrementQuantity,
                onUnitChanged: (unit) => setState(() => _measureUnit = unit),
                onMarkUnplannedChanged: (v) => setState(() => _markUnplanned = v),
                onUpdatePriceHistoryChanged: (v) =>
                    setState(() => _updatePriceHistory = v),
                onPriceChanged: () => setState(() {}),
                onConfirm: () => _confirmPendingProduct(),
                onScanAnother: _scanAnotherProduct,
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _ScannerTopBar(
                theme: theme,
                mode: _mode,
                isProcessing: _isProcessing,
                torchEnabled: _torchEnabled,
                onBack: _handleBack,
                onToggleTorch: _toggleTorch,
                onManualBarcode: _openManualBarcode,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerTopBar extends StatelessWidget {
  const _ScannerTopBar({
    required this.theme,
    required this.mode,
    required this.isProcessing,
    required this.torchEnabled,
    required this.onBack,
    required this.onToggleTorch,
    required this.onManualBarcode,
  });

  final _ScannerTheme theme;
  final ScanMode mode;
  final bool isProcessing;
  final bool torchEnabled;
  final VoidCallback onBack;
  final VoidCallback onToggleTorch;
  final VoidCallback onManualBarcode;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          FreshSproutSpacing.md,
          FreshSproutSpacing.sm,
          FreshSproutSpacing.md,
          FreshSproutSpacing.xs,
        ),
        child: Row(
          children: [
            _ScannerCircleButton(
              theme: theme,
              icon: Icons.arrow_back,
              onPressed: isProcessing ? null : onBack,
            ),
            Expanded(
              child: Center(
                child: ClipRRect(
                  borderRadius: FreshSproutRadius.fullBorder,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: FreshSproutSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.topBarBtnBg,
                        borderRadius: FreshSproutRadius.fullBorder,
                        border: Border.all(color: theme.topBarBtnBorder),
                      ),
                      child: Text(
                        mode == ScanMode.barcode
                            ? 'Leitor de Código'
                            : 'Etiqueta de Gôndola',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: theme.textPrimary.withValues(alpha: 0.85),
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _ScannerCircleButton(
              theme: theme,
              icon: torchEnabled
                  ? Icons.flashlight_on
                  : Icons.flashlight_on_outlined,
              onPressed: isProcessing ? null : onToggleTorch,
              active: torchEnabled,
            ),
            const SizedBox(width: FreshSproutSpacing.xs),
            _ScannerCircleButton(
              theme: theme,
              icon: Icons.keyboard_outlined,
              onPressed: isProcessing ? null : onManualBarcode,
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraViewport extends StatelessWidget {
  const _CameraViewport({
    required this.theme,
    required this.mode,
    required this.isReady,
    required this.isProcessing,
    required this.zoomLevel,
    required this.detectedBarcode,
    required this.productFound,
    required this.preview,
    required this.onCaptureLabel,
    required this.onSetZoom,
    required this.onResetTimer,
  });

  final _ScannerTheme theme;
  final ScanMode mode;
  final bool isReady;
  final bool isProcessing;
  final double zoomLevel;
  final String? detectedBarcode;
  final bool productFound;
  final Widget preview;
  final VoidCallback onCaptureLabel;
  final ValueChanged<double> onSetZoom;
  final VoidCallback onResetTimer;

  @override
  Widget build(BuildContext context) {
    final guide = mode.guideSize;

    return ColoredBox(
      color: theme.viewportBg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          preview,
          _CameraAmbientLayer(theme: theme),
          if (isReady)
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: productFound
                      ? _ScannerSpec.productFoundViewportPaddingV
                      : 0,
                ),
                child: Listener(
                  onPointerDown: (_) => onResetTimer(),
                  child: ScannerOverlay(
                    guideWidth: guide.width,
                    guideHeight: guide.height,
                    cornerBracketsOnly: true,
                    bracketColor: theme.emerald,
                  ),
                ),
              ),
            ),
          if (mode == ScanMode.shelfLabel && isReady)
            Positioned(
              left: FreshSproutSpacing.md,
              right: FreshSproutSpacing.md,
              bottom: FreshSproutSpacing.md,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _ZoomChip(
                          label: '1.0x',
                          selected: (zoomLevel - 1.0).abs() < 0.1,
                          onPressed: () => onSetZoom(1.0),
                        ),
                      ),
                      const SizedBox(width: FreshSproutSpacing.sm),
                      Expanded(
                        child: _ZoomChip(
                          label: '2.0x',
                          selected: (zoomLevel - 2.0).abs() < 0.1,
                          onPressed: () => onSetZoom(2.0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: FreshSproutSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: FilledButton.icon(
                      onPressed: isProcessing ? null : onCaptureLabel,
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: const Text('Capturar etiqueta'),
                    ),
                  ),
                ],
              ),
            ),
          if (detectedBarcode != null)
            Positioned(
              left: FreshSproutSpacing.md,
              right: FreshSproutSpacing.md,
              bottom: _ScannerSpec.codePillBottomInset +
                  (productFound ? _ScannerSpec.productFoundViewportPaddingV : 0),
              child: _DetectedCodePill(theme: theme, barcode: detectedBarcode!),
            ),
          if (isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class _CameraAmbientLayer extends StatelessWidget {
  const _CameraAmbientLayer({required this.theme});

  final _ScannerTheme theme;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.1,
                colors: [
                  const Color(0xFF13221B).withValues(alpha: 0.4),
                  const Color(0xFF0D141E).withValues(alpha: 0.4),
                  theme.viewportBg.withValues(alpha: 0.4),
                ],
              ),
            ),
          ),
          CustomPaint(painter: _GridTexturePainter()),
        ],
      ),
    );
  }
}

class _GridTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const step = 24.0;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScannerCircleButton extends StatelessWidget {
  const _ScannerCircleButton({
    required this.theme,
    required this.icon,
    required this.onPressed,
    this.active = false,
  });

  final _ScannerTheme theme;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _ScannerSpec.iconBtnSize,
      height: _ScannerSpec.iconBtnSize,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: active ? theme.emerald : theme.topBarBtnBg,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active ? theme.emerald : theme.topBarBtnBorder,
                  ),
                ),
                child: Icon(
                  icon,
                  size: active ? 20 : 20,
                  color: active ? theme.viewportBg : theme.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetectedCodePill extends StatelessWidget {
  const _DetectedCodePill({required this.theme, required this.barcode});

  final _ScannerTheme theme;
  final String barcode;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: FreshSproutRadius.fullBorder,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: theme.sheetBg,
            borderRadius: FreshSproutRadius.fullBorder,
            border: Border.all(color: theme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PulsingDot(color: theme.emerald),
              const SizedBox(width: 8),
              Icon(
                Icons.check_circle,
                size: 16,
                color: theme.emerald,
              ),
              const SizedBox(width: 6),
              Text(
                'Código lido:',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: theme.textPrimary.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  barcode,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: theme.textPrimary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});

  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 8,
      height: 8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ScaleTransition(
            scale: Tween(begin: 1.0, end: 2.0).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOut),
            ),
            child: FadeTransition(
              opacity: Tween(begin: 0.75, end: 0.0).animate(_controller),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerBottomSheet extends StatelessWidget {
  const _ScannerBottomSheet({
    required this.theme,
    required this.listId,
    required this.mode,
    required this.pendingProduct,
    required this.isProcessing,
    required this.nameController,
    required this.priceController,
    required this.quantity,
    required this.measureUnit,
    required this.markUnplanned,
    required this.updatePriceHistory,
    required this.subtotal,
    required this.unitPrice,
    required this.habitualAverage,
    required this.categoryLabel,
    required this.storeLabel,
    required this.onSwitchMode,
    required this.onManualProduct,
    required this.onIncrement,
    required this.onDecrement,
    required this.onUnitChanged,
    required this.onMarkUnplannedChanged,
    required this.onUpdatePriceHistoryChanged,
    required this.onPriceChanged,
    required this.onConfirm,
    required this.onScanAnother,
  });

  final _ScannerTheme theme;
  final String listId;
  final ScanMode mode;
  final _PendingProduct? pendingProduct;
  final bool isProcessing;
  final TextEditingController? nameController;
  final TextEditingController? priceController;
  final int quantity;
  final String measureUnit;
  final bool markUnplanned;
  final bool updatePriceHistory;
  final double subtotal;
  final double? unitPrice;
  final double? habitualAverage;
  final String? categoryLabel;
  final String storeLabel;
  final ValueChanged<ScanMode> onSwitchMode;
  final VoidCallback onManualProduct;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final ValueChanged<String> onUnitChanged;
  final ValueChanged<bool> onMarkUnplannedChanged;
  final ValueChanged<bool> onUpdatePriceHistoryChanged;
  final VoidCallback onPriceChanged;
  final VoidCallback onConfirm;
  final VoidCallback onScanAnother;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.sheetBg,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(_ScannerSpec.sheetRadius),
      ),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.sheetBg,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(_ScannerSpec.sheetRadius),
          ),
          border: Border(top: BorderSide(color: theme.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 25,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.handle,
              borderRadius: FreshSproutRadius.fullBorder,
            ),
          ),
          Expanded(
            child: pendingProduct == null
                ? _ScanIdleContent(
                    theme: theme,
                    mode: mode,
                    isProcessing: isProcessing,
                    onSwitchMode: onSwitchMode,
                    onManualProduct: onManualProduct,
                  )
                : _ProductSheetContent(
                    theme: theme,
                    product: pendingProduct!,
                    nameController: nameController!,
                    priceController: priceController!,
                    quantity: quantity,
                    measureUnit: measureUnit,
                    markUnplanned: markUnplanned,
                    updatePriceHistory: updatePriceHistory,
                    categoryLabel: categoryLabel ?? 'Mercearia',
                    storeLabel: storeLabel,
                    habitualAverage: habitualAverage,
                    onIncrement: onIncrement,
                    onDecrement: onDecrement,
                    onUnitChanged: onUnitChanged,
                    onMarkUnplannedChanged: onMarkUnplannedChanged,
                    onUpdatePriceHistoryChanged: onUpdatePriceHistoryChanged,
                    onPriceChanged: onPriceChanged,
                  ),
          ),
          if (pendingProduct != null)
            _ScannerActionFooter(
              theme: theme,
              subtotal: subtotal,
              quantity: quantity,
              onConfirm: onConfirm,
              onScanAnother: onScanAnother,
            ),
        ],
        ),
      ),
    );
  }
}

class _ScanModeSegmentLabel extends StatelessWidget {
  const _ScanModeSegmentLabel({
    required this.mode,
    required this.theme,
  });

  final ScanMode mode;
  final _ScannerTheme theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              mode == ScanMode.barcode
                  ? Icons.qr_code_scanner
                  : Icons.receipt_long,
              size: 22,
              color: IconTheme.of(context).color,
            ),
            const SizedBox(height: 6),
            Text(
              mode.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.sheetLabelMd(context).copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                    color: DefaultTextStyle.of(context).style.color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanIdleContent extends StatelessWidget {
  const _ScanIdleContent({
    required this.theme,
    required this.mode,
    required this.isProcessing,
    required this.onSwitchMode,
    required this.onManualProduct,
  });

  final _ScannerTheme theme;
  final ScanMode mode;
  final bool isProcessing;
  final ValueChanged<ScanMode> onSwitchMode;
  final VoidCallback onManualProduct;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(FreshSproutSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ESCANEIE UM PRODUTO',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: theme.pillText,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
          ),
          Text(
            mode == ScanMode.barcode
                ? 'Aponte para o código de barras'
                : 'Enquadre a etiqueta de preço',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary,
                ),
          ),
          const SizedBox(height: FreshSproutSpacing.md),
          Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: theme.emeraldDark,
                    onPrimary: theme.onCta,
                    outline: theme.border,
                    surfaceContainerHighest: theme.cardBg,
                  ),
            ),
            child: SegmentedButton<ScanMode>(
              style: SegmentedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                minimumSize: const Size(0, 76),
              ),
              segments: ScanMode.values
                  .map(
                    (m) => ButtonSegment<ScanMode>(
                      value: m,
                      label: _ScanModeSegmentLabel(mode: m, theme: theme),
                    ),
                  )
                  .toList(),
              selected: {mode},
              onSelectionChanged:
                  isProcessing ? null : (s) => onSwitchMode(s.first),
            ),
          ),
          const SizedBox(height: FreshSproutSpacing.lg),
          Text(
            mode.hint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: theme.muted,
                ),
          ),
          const SizedBox(height: FreshSproutSpacing.lg),
          OutlinedButton.icon(
            onPressed: isProcessing ? null : onManualProduct,
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.emeraldDark,
              side: BorderSide(color: theme.border),
              backgroundColor: theme.cardBg,
            ),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Novo produto manual'),
          ),
        ],
      ),
    );
  }
}

class _ProductSheetContent extends StatelessWidget {
  const _ProductSheetContent({
    required this.theme,
    required this.product,
    required this.nameController,
    required this.priceController,
    required this.quantity,
    required this.measureUnit,
    required this.markUnplanned,
    required this.updatePriceHistory,
    required this.categoryLabel,
    required this.storeLabel,
    required this.habitualAverage,
    required this.onIncrement,
    required this.onDecrement,
    required this.onUnitChanged,
    required this.onMarkUnplannedChanged,
    required this.onUpdatePriceHistoryChanged,
    required this.onPriceChanged,
  });

  final _ScannerTheme theme;
  final _PendingProduct product;
  final TextEditingController nameController;
  final TextEditingController priceController;
  final int quantity;
  final String measureUnit;
  final bool markUnplanned;
  final bool updatePriceHistory;
  final String categoryLabel;
  final String storeLabel;
  final double? habitualAverage;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final ValueChanged<String> onUnitChanged;
  final ValueChanged<bool> onMarkUnplannedChanged;
  final ValueChanged<bool> onUpdatePriceHistoryChanged;
  final VoidCallback onPriceChanged;

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ITEM IDENTIFICADO',
                      style: theme.sheetLabelSm(context),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Adicionar ao Carrinho',
                      style: theme.sheetHeadlineSm(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(maxWidth: 148),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.pillBg,
                  borderRadius: FreshSproutRadius.fullBorder,
                  border: Border.all(color: theme.pillBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_cafe_outlined,
                      size: 15,
                      color: theme.pillText,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        categoryLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.sheetLabelMd(context).copyWith(
                              color: theme.pillText,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: _ScannerSpec.sheetGap),
          _ProductCard(
            theme: theme,
            product: product,
            nameController: nameController,
            storeLabel: storeLabel,
          ),
          const SizedBox(height: _ScannerSpec.sheetGap),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: _QuantityStepper(
                  theme: theme,
                  quantity: quantity,
                  onIncrement: onIncrement,
                  onDecrement: onDecrement,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 7,
                child: _PriceField(
                  theme: theme,
                  controller: priceController,
                  suggested: product.price != null,
                  onChanged: onPriceChanged,
                ),
              ),
            ],
          ),
          if (habitualAverage != null) ...[
            const SizedBox(height: _ScannerSpec.sheetGap),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.cardSoft,
                borderRadius: FreshSproutRadius.lgBorder,
                border: Border.all(color: theme.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.history, size: 16, color: theme.pillText),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: theme.muted,
                            ),
                        children: [
                          const TextSpan(text: 'Média habitual: '),
                          TextSpan(
                            text: 'R\$ ${formatPrice(habitualAverage!)}',
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.amberBadgeBg,
                      borderRadius: FreshSproutRadius.smBorder,
                      border: Border.all(color: theme.amberBadgeBorder),
                    ),
                    child: Text(
                      '+6.5% vs. anterior',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: theme.amber,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: _ScannerSpec.sheetGap),
          Text(
            'Unidade de Medida',
            style: theme.sheetBodySm(context).copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 6),
          Row(
            children: _measureUnits.map((unit) {
              final selected = measureUnit == unit;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: unit == _measureUnits.last ? 0 : 8,
                  ),
                  child: Material(
                    color: selected ? theme.emeraldDark : theme.cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: FreshSproutRadius.fullBorder,
                      side: BorderSide(
                        color: selected ? Colors.transparent : theme.border,
                      ),
                    ),
                    child: InkWell(
                      onTap: () => onUnitChanged(unit),
                      borderRadius: FreshSproutRadius.fullBorder,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 4,
                        ),
                        child: Text(
                          unit,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.sheetLabelMd(context).copyWith(
                                color: selected ? theme.onCta : theme.muted,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          _ScannerCheckboxRow(
            theme: theme,
            value: markUnplanned,
            onChanged: onMarkUnplannedChanged,
            label: 'Marcar como item fora da lista prevista',
          ),
          const SizedBox(height: 8),
          _ScannerCheckboxRow(
            theme: theme,
            value: updatePriceHistory,
            onChanged: onUpdatePriceHistoryChanged,
            label: 'Atualizar histórico de preços deste mercado',
          ),
        ],
    );

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        FreshSproutSpacing.md,
        FreshSproutSpacing.xs,
        FreshSproutSpacing.md,
        FreshSproutSpacing.md + keyboardInset,
      ),
      child: content,
    );
  }
}

class _ScannerCheckboxRow extends StatelessWidget {
  const _ScannerCheckboxRow({
    required this.theme,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final _ScannerTheme theme;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: FreshSproutRadius.mdBorder,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                fillColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return theme.emerald;
                  }
                  return theme.cardBg;
                }),
                checkColor: theme.onCta,
                side: BorderSide(color: theme.border, width: 1.2),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: theme.sheetBodySm(context).copyWith(
                      color: theme.textSecondary,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.theme,
    required this.product,
    required this.nameController,
    required this.storeLabel,
  });

  final _ScannerTheme theme;
  final _PendingProduct product;
  final TextEditingController nameController;
  final String storeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(_ScannerSpec.fieldRadius),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: theme.cardShadow,
            blurRadius: 8,
            spreadRadius: -2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: FreshSproutRadius.lgBorder,
              border: Border.all(color: theme.border),
            ),
            child: ClipRRect(
              borderRadius: FreshSproutRadius.lgBorder,
              child: SizedBox(
                width: _ScannerSpec.thumbSize,
                height: _ScannerSpec.thumbSize,
                child: product.imageUrl != null
                  ? Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _ThumbPlaceholder(theme: theme),
                    )
                  : _ThumbPlaceholder(theme: theme),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (product.brand != null && product.brand!.isNotEmpty)
                      Expanded(
                        child: Text(
                          product.brand!.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.sheetLabelSm(context).copyWith(
                                color: theme.muted,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0,
                              ),
                        ),
                      ),
                    if (product.barcode != null)
                      Text(
                        'EAN: ${product.barcode}',
                        style: theme.sheetLabelSm(context).copyWith(
                              color: theme.muted,
                              letterSpacing: 0,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                _SheetPlainTextField(
                  theme: theme,
                  controller: nameController,
                  style: theme.sheetEditableName(),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.store_outlined,
                      size: 14,
                      color: theme.pillText,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        storeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.sheetBodySm(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetPlainTextField extends StatelessWidget {
  const _SheetPlainTextField({
    required this.theme,
    required this.controller,
    required this.style,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.textCapitalization = TextCapitalization.none,
  });

  final _ScannerTheme theme;
  final TextEditingController controller;
  final TextStyle style;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final fieldStyle = style.copyWith(color: theme.textPrimary);

    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: theme.emerald,
          selectionColor: theme.emerald.withValues(alpha: 0.25),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: false,
          isDense: true,
          isCollapsed: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
      child: TextField(
        controller: controller,
        style: fieldStyle,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        textCapitalization: textCapitalization,
        maxLines: 1,
        decoration: const InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  const _ThumbPlaceholder({required this.theme});

  final _ScannerTheme theme;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: theme.sheetBg,
      child: Icon(
        Icons.shopping_bag_outlined,
        color: theme.muted,
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.theme,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  final _ScannerTheme theme;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(_ScannerSpec.fieldRadius),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quantidade',
            style: theme.sheetBodySm(context).copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StepperButton(
                theme: theme,
                icon: Icons.remove,
                onPressed: onDecrement,
                filled: false,
              ),
              Text(
                '$quantity',
                style: theme.sheetHeadlineSm(context),
              ),
              _StepperButton(
                theme: theme,
                icon: Icons.add,
                onPressed: onIncrement,
                filled: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.theme,
    required this.icon,
    required this.onPressed,
    required this.filled,
  });

  final _ScannerTheme theme;
  final IconData icon;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? theme.emeraldDark : theme.sheetBg,
      shape: CircleBorder(
        side: filled
            ? BorderSide.none
            : BorderSide(color: theme.border),
      ),
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: _ScannerSpec.stepperBtnSize,
          height: _ScannerSpec.stepperBtnSize,
          child: Icon(
            icon,
            size: 18,
            color: filled ? theme.onCta : theme.pillText,
          ),
        ),
      ),
    );
  }
}

class _PriceField extends StatelessWidget {
  const _PriceField({
    required this.theme,
    required this.controller,
    required this.suggested,
    required this.onChanged,
  });

  final _ScannerTheme theme;
  final TextEditingController controller;
  final bool suggested;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(_ScannerSpec.fieldRadius),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Preço Unitário',
                style: theme.sheetBodySm(context).copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              if (suggested)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.pillBg,
                    borderRadius: FreshSproutRadius.fullBorder,
                    border: Border.all(color: theme.pillBorder),
                  ),
                  child: Text(
                    'Sugerido',
                    style: theme.sheetLabelSm(context).copyWith(
                          color: theme.pillText,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'R\$',
                style: theme.sheetLabelMd(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.muted,
                    ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _SheetPlainTextField(
                  theme: theme,
                  controller: controller,
                  style: theme.sheetEditablePrice(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  onChanged: (_) => onChanged(),
                ),
              ),
              Icon(
                Icons.edit_outlined,
                size: 18,
                color: theme.muted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScannerActionFooter extends StatelessWidget {
  const _ScannerActionFooter({
    required this.theme,
    required this.subtotal,
    required this.quantity,
    required this.onConfirm,
    required this.onScanAnother,
  });

  final _ScannerTheme theme;
  final double subtotal;
  final int quantity;
  final VoidCallback onConfirm;
  final VoidCallback onScanAnother;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        FreshSproutSpacing.md,
        10,
        FreshSproutSpacing.md,
        FreshSproutSpacing.md,
      ),
      decoration: BoxDecoration(
        color: theme.footerBg,
        border: Border(top: BorderSide(color: theme.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal deste item:',
                  style: theme.sheetBodySm(context),
                ),
                Text(
                  'R\$ ${formatPrice(subtotal)}',
                  style: theme.sheetHeadlineSm(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Material(
                    color: theme.cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(_ScannerSpec.fieldRadius),
                      side: BorderSide(color: theme.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: onScanAnother,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_scanner,
                              size: 20,
                              color: theme.textPrimary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Escanear Outro',
                              style: theme.sheetBtnLabel(context).copyWith(
                                    color: theme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Material(
                      color: theme.cta,
                      borderRadius:
                          BorderRadius.circular(_ScannerSpec.fieldRadius),
                      clipBehavior: Clip.antiAlias,
                      elevation: 0,
                      child: InkWell(
                        onTap: onConfirm,
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 14,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              _ScannerSpec.fieldRadius,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.ctaGlow,
                                blurRadius: 20,
                                spreadRadius: -4,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_basket_outlined,
                                size: 22,
                                color: theme.onCta,
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Adicionar ao Carrinho',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.sheetBtnLabel(context)
                                          .copyWith(
                                            color: theme.onCta,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${quantity}x · R\$ ${formatPrice(subtotal)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.sheetBodySm(context).copyWith(
                                            color: theme.onCta
                                                .withValues(alpha: 0.88),
                                            fontWeight: FontWeight.w600,
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

class _ZoomChip extends StatelessWidget {
  const _ZoomChip({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? FreshSproutColors.primaryContainer.withValues(alpha: 0.9)
          : Colors.black.withValues(alpha: 0.45),
      borderRadius: FreshSproutRadius.fullBorder,
      child: InkWell(
        onTap: onPressed,
        borderRadius: FreshSproutRadius.fullBorder,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
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
            Text(
              '$_secondsRemaining ${_secondsRemaining == 1 ? 'segundo' : 'segundos'}',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
