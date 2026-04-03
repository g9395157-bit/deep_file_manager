import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class SectionLabel extends StatelessWidget {
  final String label;
  const SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      label,
      style: TextStyle(
        color: kAmber,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    ),
  );
}
