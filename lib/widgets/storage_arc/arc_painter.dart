import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../constants/colors.dart';

class ArcPainter extends CustomPainter {
  final double fraction;
  ArcPainter({required this.fraction});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 8;
    const strokeW = 10.0;

    // Background track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = kBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );
    // Amber arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = const SweepGradient(
        colors: [kAmber, kOrange],
        startAngle: 0,
        endAngle: math.pi * 2,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * fraction, false, paint);
  }

  @override
  bool shouldRepaint(ArcPainter old) => old.fraction != fraction;
}
