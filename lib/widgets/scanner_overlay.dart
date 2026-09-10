import 'package:flutter/material.dart';

import '../theme/fresh_sprout_tokens.dart';

class ScannerOverlay extends StatelessWidget {
  const ScannerOverlay({
    super.key,
    required this.guideWidth,
    required this.guideHeight,
    this.hint,
    this.cornerBracketsOnly = false,
    this.bracketColor = const Color(0xFF10B981),
    this.showLaser = true,
    this.animatedLaser = false,
    this.showCrosshair = true,
  });

  final double guideWidth;
  final double guideHeight;
  final String? hint;
  final bool cornerBracketsOnly;
  final Color bracketColor;
  final bool showLaser;
  final bool animatedLaser;
  final bool showCrosshair;

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
                  painter: _CornerBracketPainter(
                    guideRect: guideRect,
                    color: bracketColor,
                  ),
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
              if (showLaser && cornerBracketsOnly)
                Positioned.fromRect(
                  rect: guideRect,
                  child: animatedLaser
                      ? const _ScanLaserLine()
                      : _StaticScanLaserLine(color: bracketColor),
                ),
              if (showCrosshair && cornerBracketsOnly)
                Positioned.fromRect(
                  rect: guideRect,
                  child: Center(
                    child: Icon(
                      Icons.qr_code_scanner,
                      size: 32,
                      color: Colors.white.withValues(alpha: 0.3),
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

class _StaticScanLaserLine extends StatelessWidget {
  const _StaticScanLaserLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                color.withValues(alpha: 0.85),
                Colors.transparent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.7),
                blurRadius: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanLaserLine extends StatefulWidget {
  const _ScanLaserLine();

  @override
  State<_ScanLaserLine> createState() => _ScanLaserLineState();
}

class _ScanLaserLineState extends State<_ScanLaserLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Align(
          alignment: Alignment(0, -1 + (_controller.value * 2)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    FreshSproutColors.primaryFixed.withValues(
                      alpha: 0.4 + (_controller.value * 0.5),
                    ),
                    Colors.transparent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: FreshSproutColors.secondaryFixed.withValues(
                      alpha: 0.6,
                    ),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CornerBracketPainter extends CustomPainter {
  const _CornerBracketPainter({
    required this.guideRect,
    required this.color,
  });

  final Rect guideRect;
  final Color color;

  static const _armLength = 24.0;
  static const _strokeWidth = 3.5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glow = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = _strokeWidth + 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    for (final corner in [
      (Offset(guideRect.left, guideRect.top), 1, 1),
      (Offset(guideRect.right, guideRect.top), -1, 1),
      (Offset(guideRect.left, guideRect.bottom), 1, -1),
      (Offset(guideRect.right, guideRect.bottom), -1, -1),
    ]) {
      _drawCorner(canvas, glow, corner.$1, corner.$2, corner.$3);
      _drawCorner(canvas, paint, corner.$1, corner.$2, corner.$3);
    }
  }

  void _drawCorner(
    Canvas canvas,
    Paint paint,
    Offset corner,
    int horizontal,
    int vertical,
  ) {
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
    return oldDelegate.guideRect != guideRect || oldDelegate.color != color;
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
