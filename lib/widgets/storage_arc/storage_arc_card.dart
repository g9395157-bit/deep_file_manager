import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/gradients.dart';
import 'dot.dart';
import 'arc_painter.dart';

class StorageArcCard extends StatelessWidget {
  const StorageArcCard({super.key});

  @override
  Widget build(BuildContext context) {
    const usedGb = 36.1;
    const totalGb = 128.0;
    const usedFrac = usedGb / totalGb;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kCard, kCard.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: kAmber.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Arc donut
          SizedBox(
            width: 110,
            height: 110,
            child: CustomPaint(
              painter: ArcPainter(fraction: usedFrac),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(usedFrac * 100).round()}%',
                      style: TextStyle(
                        color: kBright,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text('used', style: TextStyle(color: kMuted, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Internal Storage',
                  style: TextStyle(
                    color: kMuted,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                ShaderMask(
                  shaderCallback: (b) => kEmberGradient.createShader(b),
                  child: Text(
                    '${usedGb.toStringAsFixed(1)} GB',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
                Text(
                  'of ${totalGb.toInt()} GB total',
                  style: TextStyle(color: kMuted, fontSize: 13),
                ),
                const SizedBox(height: 14),
                // Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: usedFrac,
                    minHeight: 6,
                    backgroundColor: kBorder,
                    valueColor: AlwaysStoppedAnimation(kAmber),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Dot(color: kAmber),
                    const SizedBox(width: 5),
                    Text(
                      'Used  ',
                      style: TextStyle(color: kMuted, fontSize: 11),
                    ),
                    Dot(color: kBorder),
                    const SizedBox(width: 5),
                    Text('Free', style: TextStyle(color: kMuted, fontSize: 11)),
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
