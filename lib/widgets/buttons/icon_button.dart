import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const IconBtn({Key? key, required this.icon, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Icon(icon, color: kBright, size: 20),
      ),
    );
  }
}
