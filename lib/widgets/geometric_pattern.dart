import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Subtle repeating 8-point Islamic star motif, drawn as thin strokes.
/// Used as a low-opacity background decoration so hero surfaces don't read
/// as empty flat color blocks without needing any bundled image assets.
class GeometricPatternPainter extends CustomPainter {
  final Color color;
  final double tile;

  const GeometricPatternPainter({
    this.color = Colors.white,
    this.tile = 46,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final cols = (size.width / tile).ceil() + 1;
    final rows = (size.height / tile).ceil() + 1;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final center = Offset(col * tile, row * tile);
        _drawStar(canvas, center, tile * 0.34, paint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const points = 8;
    for (int i = 0; i <= points; i++) {
      final angle = i * math.pi / (points / 2);
      final r = i.isEven ? radius : radius * 0.45;
      final point = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant GeometricPatternPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.tile != tile;
}