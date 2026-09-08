import 'package:flutter/material.dart';

class ScannerOverlay extends StatelessWidget {
  const ScannerOverlay({
    super.key,
    required this.guideWidth,
    required this.guideHeight,
    this.hint,
    this.cornerBracketsOnly = false,
  });

  final double guideWidth;
  final double guideHeight;
  final String? hint;
  final bool cornerBracketsOnly;

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
              if (!cornerBracketsOnly)
                CustomPaint(
                  size: size,
                  painter: _ScannerMaskPainter(guideRect: guideRect),
                ),
              if (cornerBracketsOnly)
                CustomPaint(
                  size: size,
                  painter: _CornerBracketPainter(guideRect: guideRect),
                )
              else
                Positioned.fromRect(
                  rect: guideRect,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              if (hint != null && !cornerBracketsOnly)
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

class _CornerBracketPainter extends CustomPainter {
  const _CornerBracketPainter({required this.guideRect});

  final Rect guideRect;

  static const _armLength = 28.0;
  static const _strokeWidth = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _drawCorner(
      canvas,
      paint,
      Offset(guideRect.left, guideRect.top),
      horizontal: 1,
      vertical: 1,
    );
    _drawCorner(
      canvas,
      paint,
      Offset(guideRect.right, guideRect.top),
      horizontal: -1,
      vertical: 1,
    );
    _drawCorner(
      canvas,
      paint,
      Offset(guideRect.left, guideRect.bottom),
      horizontal: 1,
      vertical: -1,
    );
    _drawCorner(
      canvas,
      paint,
      Offset(guideRect.right, guideRect.bottom),
      horizontal: -1,
      vertical: -1,
    );
  }

  void _drawCorner(
    Canvas canvas,
    Paint paint,
    Offset corner, {
    required int horizontal,
    required int vertical,
  }) {
    canvas.drawLine(
      corner,
      corner + Offset(_armLength * horizontal, 0),
      paint,
    );
    canvas.drawLine(
      corner,
      corner + Offset(0, _armLength * vertical),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerBracketPainter oldDelegate) {
    return oldDelegate.guideRect != guideRect;
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
