import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/gradients.dart';
import '../constants/mock_data.dart';
import '../app/main_shell.dart';
import '../models/file_type.dart';
import '../utils/file_service.dart';
import '../utils/storage_search_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late AnimationController _iconCtrl;
  late AnimationController _textCtrl;

  late Animation<double> _bgScale;
  late Animation<double> _iconScale;
  late Animation<double> _iconFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _preloadData();
    _setupAnimations();
  }

  void _setupAnimations() {
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _iconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _bgScale = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _bgCtrl, curve: Curves.easeOutExpo));
    _iconScale = Tween<double>(
      begin: 0.4,
      end: 1,
    ).animate(CurvedAnimation(parent: _iconCtrl, curve: Curves.elasticOut));
    _iconFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _iconCtrl, curve: Curves.easeOut));
    _textFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));

    // Sequence
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _bgCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _iconCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _textCtrl.forward();
    });

    // Proceed after animations finish or when data is loaded
    Future.delayed(const Duration(milliseconds: 3000), () {
      _proceedToMain();
    });
  }

  Future<void> _preloadData() async {
    try {
      final root = await FileService.getRootDirectory();

      // Pre-compute category data
      for (final category in kCategories) {
        final types = _getFileTypesForCategory(category.label);
        await StorageSearchService.searchFilesByType(
          root.path,
          types,
          maxDepth: 15,
        );
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      // Silently continue even if preload fails
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Set<FileType> _getFileTypesForCategory(String label) {
    return switch (label) {
      'Images' => {FileType.image},
      'Videos' => {FileType.video},
      'Audio' => {FileType.audio},
      'Documents' => {FileType.document},
      'Downloads' => {FileType.apk, FileType.archive, FileType.document},
      'Apps' => {FileType.apk},
      _ => {FileType.other},
    };
  }

  void _proceedToMain() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const MainShell(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _iconCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final glowSize = math.min(size.width, size.height) * 0.6;

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Radial glow behind icon — scales to screen size
          AnimatedBuilder(
            animation: _bgScale,
            builder: (_, __) => Transform.scale(
              scale: _bgScale.value,
              child: Container(
                width: glowSize,
                height: glowSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      kAmber.withAlpha((0.18 * 255).round()),
                      kOrange.withAlpha((0.08 * 255).round()),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                ScaleTransition(
                  scale: _iconScale,
                  child: FadeTransition(
                    opacity: _iconFade,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: kAmber.withAlpha((0.4 * 255).round()),
                            blurRadius: 48,
                            spreadRadius: 4,
                          ),
                          BoxShadow(
                            color: kOrange.withAlpha((0.2 * 255).round()),
                            blurRadius: 80,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.asset(
                          'assets/images/icon.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                // Text
                FadeTransition(
                  opacity: _textFade,
                  child: SlideTransition(
                    position: _textSlide,
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (b) => kEmberGradient.createShader(b),
                          child: const Text(
                            'DEEP FILE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 6,
                            ),
                          ),
                        ),
                        Text(
                          'MANAGER',
                          style: TextStyle(
                            color: kBright.withAlpha((0.6 * 255).round()),
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom version tag + loading indicator
          Positioned(
            bottom: 48,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoading)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          kAmber.withAlpha((0.6 * 255).round()),
                        ),
                      ),
                    ),
                  ),
                FadeTransition(
                  opacity: _textFade,
                  child: Text(
                    'v1.0.0',
                    style: TextStyle(
                      color: kMuted.withAlpha((0.5 * 255).round()),
                      fontSize: 12,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
