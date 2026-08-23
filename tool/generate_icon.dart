// Generates the app's launcher icon artwork - a mosque silhouette paired
// with a classic "10:10" watch face, on the app's own mehndiGreen/gold
// palette - and writes it to assets/icon/ as plain PNGs.
//
// This lives under tool/ (not test/) because it isn't a test: it's a
// one-off drawing script that happens to reuse flutter_test's ability to
// rasterize a widget tree via RenderRepaintBoundary.toImage(), which is
// otherwise only available with a running Flutter engine. Regenerate with:
//
//   flutter test tool/generate_icon.dart
//
// Then re-run `dart run flutter_launcher_icons` to rebuild the per-platform
// icon files from the new PNGs (see the flutter_launcher_icons: block in
// pubspec.yaml for the source paths/sizes it uses).
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// Same brand palette as lib/utils/constants.dart's AppColors - duplicated
// (rather than imported) so this tool has no dependency on app code and
// keeps working even if the app's widgets change.
const _mehndiGreen = Color(0xFF5E7A42);
const _mehndiGreenDark = Color(0xFF3C5828);
const _lightGold = Color(0xFFC9A94F);
const _richBlack = Color(0xFF1B1B1B);
const _cream = Color(0xFFF0EDE0);

const _canvasSize = 1024.0;
// The artwork is drawn inside a centered square smaller than the full
// canvas so it survives Android's adaptive-icon masking (circle, squircle,
// rounded-square launchers all crop roughly the outer 17% on each side).
const _contentSize = 720.0;

void main() {
  testWidgets('generate app icon PNGs', (tester) async {
    // The default test surface is a fixed 800x600 - without this, the
    // 1024x1024 SizedBox below gets constrained down to fit it instead of
    // rendering at its real size.
    tester.view.physicalSize = const Size(_canvasSize, _canvasSize);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.runAsync(() async {
      await _render(tester, includeBackground: true, fileName: 'app_icon.png');
      await _render(tester, includeBackground: false, fileName: 'app_icon_foreground.png');
    });
  });
}

Future<void> _render(
  WidgetTester tester, {
  required bool includeBackground,
  required String fileName,
}) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: key,
        child: SizedBox(
          width: _canvasSize,
          height: _canvasSize,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: includeBackground
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_mehndiGreen, _mehndiGreenDark],
                    )
                  : null,
            ),
            child: Center(
              child: SizedBox(
                width: _contentSize,
                height: _contentSize,
                child: CustomPaint(painter: _MosqueWatchPainter()),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 1.0);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

  final file = File('assets/icon/$fileName');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes!.buffer.asUint8List());
  // ignore: avoid_print
  print('Wrote ${file.path} (${image.width}x${image.height})');
}

/// Draws a mosque (base + two minarets + arched doorway) whose dome is
/// itself a watch face, rather than a separate watch badge stuck onto the
/// silhouette - one unified mark instead of two overlapping shapes, in
/// mehndiGreen (the app's own brand green) plus lightGold for the watch
/// bezel. Domes on real Ottoman-style mosques already read as close to
/// circular, which is what makes a literal clock face convincing here
/// instead of looking like a sticker.
class _MosqueWatchPainter extends CustomPainter {
  static const _domeCenter = Offset(360, 310);
  static const _domeRadius = 150.0;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = _cream;

    // Base building.
    final base = RRect.fromRectAndCorners(
      const Rect.fromLTRB(60, 430, 660, 620),
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
    );
    canvas.drawRRect(base, fill);

    // Minarets, symmetric either side of the dome.
    _drawMinaret(canvas, centerX: 110, fill: fill);
    _drawMinaret(canvas, centerX: 610, fill: fill);

    // The dome - its bottom edge overlaps the base's top edge, so the two
    // shapes read as one silhouette with no visible seam.
    canvas.drawCircle(_domeCenter, _domeRadius, fill);

    // Finial spire + ball above the dome.
    canvas.drawRect(const Rect.fromLTWH(357, 108, 6, 55), fill);
    canvas.drawCircle(const Offset(360, 103), 9, fill);

    // Arched doorway, cut into the base in the darker green so it reads as
    // a silhouette rather than a flat block.
    final archFill = Paint()..color = _mehndiGreenDark;
    final arch = Path()
      ..moveTo(290, 620)
      ..lineTo(290, 500)
      ..arcToPoint(const Offset(430, 500), radius: const Radius.circular(70))
      ..lineTo(430, 620)
      ..close();
    canvas.drawPath(arch, archFill);

    _drawWatchFace(canvas);
  }

  void _drawMinaret(Canvas canvas, {required double centerX, required Paint fill}) {
    canvas.drawRect(Rect.fromLTRB(centerX - 25, 300, centerX + 25, 620), fill);
    canvas.drawCircle(Offset(centerX, 300), 28, fill);
    canvas.drawRect(Rect.fromLTWH(centerX - 2, 265, 4, 35), fill);
    canvas.drawCircle(Offset(centerX, 260), 7, fill);
  }

  /// Ticks + hands drawn directly onto the dome from [paint] - the dome's
  /// own cream fill doubles as the watch face, so this only adds the gold
  /// bezel ring and the clock furniture on top of it.
  void _drawWatchFace(Canvas canvas) {
    const center = _domeCenter;
    const radius = _domeRadius;

    canvas.drawCircle(
      center,
      radius - 6,
      Paint()
        ..color = _lightGold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = _richBlack
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Hour ticks at 12/3/6/9.
    final tick = Paint()..color = _richBlack;
    const tickInset = radius - 32;
    canvas.drawRect(Rect.fromCenter(center: const Offset(360, 310 - tickInset), width: 9, height: 24), tick);
    canvas.drawRect(Rect.fromCenter(center: const Offset(360, 310 + tickInset), width: 9, height: 24), tick);
    canvas.drawRect(Rect.fromCenter(center: const Offset(360 - tickInset, 310), width: 24, height: 9), tick);
    canvas.drawRect(Rect.fromCenter(center: const Offset(360 + tickInset, 310), width: 24, height: 9), tick);

    // Hands set to the classic "10:10" display - symmetric and legible
    // even at small launcher-icon sizes.
    _drawHand(canvas, center: center, angleDeg: -60, length: 68, strokeWidth: 13);
    _drawHand(canvas, center: center, angleDeg: 60, length: 105, strokeWidth: 10);
    canvas.drawCircle(center, 12, Paint()..color = _richBlack);
  }

  void _drawHand(
    Canvas canvas, {
    required Offset center,
    required double angleDeg,
    required double length,
    required double strokeWidth,
  }) {
    final angle = angleDeg * math.pi / 180;
    final end = center + Offset(length * math.sin(angle), -length * math.cos(angle));
    canvas.drawLine(
      center,
      end,
      Paint()
        ..color = _richBlack
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MosqueWatchPainter oldDelegate) => false;
}
