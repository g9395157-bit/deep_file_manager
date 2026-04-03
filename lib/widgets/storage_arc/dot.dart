import 'package:flutter/material.dart';

class Dot extends StatelessWidget {
  final Color color;
  const Dot({super.key, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
