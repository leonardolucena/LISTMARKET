import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/list_item.dart';
import '../services/label_text_parser.dart';
import '../services/shopping_list_repository.dart';
import '../services/shelf_label_ocr_service.dart';
import '../widgets/item_form_dialog.dart';

class ShelfLabelScannerScreen extends StatefulWidget {
  const ShelfLabelScannerScreen({super.key, required this.listId});

  final String listId;

  @override
  State<ShelfLabelScannerScreen> createState() =>
      _ShelfLabelScannerScreenState();
}

class _ShelfLabelScannerScreenState extends State<ShelfLabelScannerScreen> {
  final _repository = ShoppingListRepository.instance;
  final _ocrService = ShelfLabelOcrService();
  final _uuid = const Uuid();

  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _torchEnabled = false;
  double _zoomLevel = 1.0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isInitialized = true;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível abrir a câmera: $error')),
      );
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _setZoom(double zoom) async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    final maxZoom = await controller.getMaxZoomLevel();
    final minZoom = await controller.getMinZoomLevel();
    final target = zoom.clamp(minZoom, maxZoom);

    await controller.setZoomLevel(target);

    if (!mounted) return;
    setState(() => _zoomLevel = target);
  }

  Future<void> _toggleTorch() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    final nextMode = _torchEnabled ? FlashMode.off : FlashMode.torch;
    await controller.setFlashMode(nextMode);

    if (!mounted) return;
    setState(() => _torchEnabled = !_torchEnabled);
  }

  Future<void> _captureAndScan() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || _isProcessing) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final photo = await controller.takePicture();
      final result = await _ocrService.scanImageFile(photo.path);

      if (!mounted) return;

      if (result == null || !result.hasData) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível ler a etiqueta. Tente de novo com mais luz.',
            ),
          ),
        );
        return;
      }

      await _confirmAndSave(result);
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

  Future<void> _confirmAndSave(ShelfLabelScanResult result) async {
    final initialPriceText = result.price?.toStringAsFixed(2) ?? '';

    final formResult = await showItemFormDialog(
      context,
      initialName: result.name ?? '',
      initialPrice: initialPriceText,
      dialogTitle: 'Item da etiqueta',
      helperText: 'Confira o nome e o preço antes de salvar.',
    );

    if (formResult == null || !mounted) return;

    await _repository.addItem(
      widget.listId,
      ListItem(
        id: _uuid.v4(),
        name: formResult.name,
        price: formResult.price,
        quantity: formResult.quantity,
      ),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${formResult.name}" adicionado à lista')),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _cameraController;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ler etiqueta da gôndola'),
        actions: [
          IconButton(
            onPressed: _isInitialized ? _toggleTorch : null,
            icon: Icon(_torchEnabled ? Icons.flash_on : Icons.flash_off),
            tooltip: 'Lanterna',
          ),
        ],
      ),
      body: !_isInitialized || controller == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(controller),
                IgnorePointer(
                  child: Center(
                    child: Container(
                      width: 300,
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 120,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ZoomButton(
                        label: '1.0x',
                        selected: (_zoomLevel - 1.0).abs() < 0.1,
                        onPressed: () => _setZoom(1.0),
                      ),
                      const SizedBox(width: 12),
                      _ZoomButton(
                        label: '2.0x',
                        selected: (_zoomLevel - 2.0).abs() < 0.1,
                        onPressed: () => _setZoom(2.0),
                      ),
                    ],
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
                            'Lendo etiqueta...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: _isInitialized
          ? FloatingActionButton.large(
              onPressed: _isProcessing ? null : _captureAndScan,
              child: const Icon(Icons.camera_alt),
            )
          : null,
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
    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: selected
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
      ),
      child: Text(label),
    );
  }
}
