import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// A live-updating analog clock face, styled with the app's brand colors.
class CircularClock extends StatefulWidget {
  final double size;
  const CircularClock({super.key, this.size = 84});

  @override
  State<CircularClock> createState() => _CircularClockState();
}

class _CircularClockState extends State<CircularClock> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(painter: _ClockPainter(_now)),
    );
  }
}

class _ClockPainter extends CustomPainter {
  final DateTime time;
  _ClockPainter(this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    canvas.drawCircle(center, radius - 2, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      radius - 2,
      Paint()
        ..color = AppColors.mehndiGreen
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    for (int i = 0; i < 12; i++) {
      final angle = i * 30 * math.pi / 180;
      final isMajorTick = i % 3 == 0;
      final tickLength = isMajorTick ? 12.0 : 7.0;
      final outer = Offset(
        center.dx + (radius - 6) * math.sin(angle),
        center.dy - (radius - 6) * math.cos(angle),
      );
      final inner = Offset(
        center.dx + (radius - 6 - tickLength) * math.sin(angle),
        center.dy - (radius - 6 - tickLength) * math.cos(angle),
      );
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = AppColors.richBlack
          ..strokeWidth = isMajorTick ? 2 : 1,
      );
    }

    final hourAngle =
        ((time.hour % 12) + time.minute / 60) * 30 * math.pi / 180;
    final minuteAngle = (time.minute + time.second / 60) * 6 * math.pi / 180;
    final secondAngle = time.second * 6 * math.pi / 180;

    _drawHand(canvas, center, hourAngle, radius * 0.45, AppColors.richBlack, 3);
    _drawHand(canvas, center, minuteAngle, radius * 0.65, AppColors.richBlack, 2);
    _drawHand(canvas, center, secondAngle, radius * 0.7, AppColors.lightGold, 1.5);

    canvas.drawCircle(center, 3, Paint()..color = AppColors.richBlack);
  }

  void _drawHand(
    Canvas canvas,
    Offset center,
    double angle,
    double length,
    Color color,
    double strokeWidth,
  ) {
    final end = Offset(
      center.dx + length * math.sin(angle),
      center.dy - length * math.cos(angle),
    );
    canvas.drawLine(
      center,
      end,
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ClockPainter oldDelegate) =>
      oldDelegate.time != time;
}