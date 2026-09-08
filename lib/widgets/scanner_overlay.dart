import 'package:flutter/material.dart';

class ScannerOverlay extends StatelessWidget {
  const ScannerOverlay({
    super.key,
    required this.guideWidth,
    required this.guideHeight,
    this.hint,
  });

  final double guideWidth;
  final double guideHeight;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final guideRect = Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: guideWidth,
            height: guideHeight,
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                size: size,
                painter: _ScannerMaskPainter(guideRect: guideRect),
              ),
              Positioned.fromRect(
                rect: guideRect,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (hint != null)
                Positioned(
                  left: 24,
                  right: 24,
                  top: guideRect.bottom + 16,
                  child: Text(
                    hint!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ScannerMaskPainter extends CustomPainter {
  const _ScannerMaskPainter({required this.guideRect});

  final Rect guideRect;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()
      ..addRRect(
        RRect.fromRectAndRadius(guideRect, const Radius.circular(12)),
      );

    final mask = Path.combine(PathOperation.difference, background, hole);
    canvas.drawPath(mask, Paint()..color = Colors.black.withValues(alpha: 0.55));
  }

  @override
  bool shouldRepaint(covariant _ScannerMaskPainter oldDelegate) {
    return oldDelegate.guideRect != guideRect;
  }
}
