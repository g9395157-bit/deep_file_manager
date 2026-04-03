import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/gradients.dart';
import '../app/main_shell.dart';
import '../utils/permission_service.dart';

/// Fixed splash screen:
/// - Animations start on the very first frame (no delay before bg animation)
/// - Only does a lightweight permission request in the background
/// - No heavy filesystem scanning — categories load lazily on the home screen
/// - Navigates after 2.4 s or when permission check completes, whichever is later
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

  // Minimum visible duration for the splash (ms)
  static const int _minSplashMs = 2400;

  bool _permCheckDone = false;
  bool _minTimePassed = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _doLightweightInit();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Animations — start immediately, no blocking delays
  // ──────────────────────────────────────────────────────────────────────────
  void _setupAnimations() {
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _iconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _bgScale = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _bgCtrl, curve: Curves.easeOutExpo));
    _iconScale = Tween<double>(begin: 0.4, end: 1).animate(
        CurvedAnimation(parent: _iconCtrl, curve: Curves.elasticOut));
    _iconFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _iconCtrl, curve: Curves.easeOut));
    _textFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));

    // Staggered start — bg fires immediately, rest follow
    _bgCtrl.forward();

    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _iconCtrl.forward();
    });

    Future.delayed(const Duration(milliseconds: 750), () {
      if (mounted) _textCtrl.forward();
    });

    // Minimum display timer
    Future.delayed(const Duration(milliseconds: _minSplashMs), () {
      _minTimePassed = true;
      _maybeNavigate();
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Lightweight init: just request storage permission — no filesystem scan
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> _doLightweightInit() async {
    try {
      await PermissionService.requestStoragePermission();
    } catch (_) {
      // Continue even if permission is denied — Files screen handles it
    } finally {
      _permCheckDone = true;
      _maybeNavigate();
    }
  }

  void _maybeNavigate() {
    if (_permCheckDone && _minTimePassed) {
      _proceedToMain();
    }
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
          // Radial glow
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
                // App icon
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

                // App name
                FadeTransition(
                  opacity: _textFade,
                  child: SlideTransition(
                    position: _textSlide,
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (b) =>
                              kEmberGradient.createShader(b),
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

          // Version tag at bottom
          Positioned(
            bottom: 48,
            child: FadeTransition(
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
          ),
        ],
      ),
    );
  }
}