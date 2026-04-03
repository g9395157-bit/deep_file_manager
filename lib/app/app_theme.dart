import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: kBg,
      fontFamily: 'Zain',
      colorScheme: const ColorScheme.dark(
        primary: kAmber,
        secondary: kOrange,
        surface: kSurface,
      ),
      splashColor: kAmber.withAlpha((0.08 * 255).round()),
      highlightColor: kAmber.withAlpha((0.04 * 255).round()),
    );
  }
}
