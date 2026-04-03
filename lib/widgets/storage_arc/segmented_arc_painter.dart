import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../constants/colors.dart';

class SegmentedArcPainter extends CustomPainter {
  final List<(double, Color)> segments;
  SegmentedArcPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 12;
    const strokeW = 16.0;
    const gap = 0.025; // radians between segments

    // Background track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = kBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );

    double startAngle = -math.pi / 2;
    for (final seg in segments) {
      final sweep = seg.$1 * 2 * math.pi - gap;
      if (sweep <= 0) continue;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + gap / 2,
        sweep,
        false,
        Paint()
          ..color = seg.$2
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );
      startAngle += seg.$1 * 2 * math.pi;
    }
  }

  @override
  bool shouldRepaint(SegmentedArcPainter old) => false;
}
