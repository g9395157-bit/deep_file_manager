// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const DeepFileManagerApp());
}

class DeepFileManagerApp extends StatelessWidget {
  const DeepFileManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0F0D0C),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    return MaterialApp(
      title: 'Deep File Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
