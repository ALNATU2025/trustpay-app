import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';

/// Screen 1: logo and "Powered by" line on a light grey background.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/intro');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      backgroundColor: TpColors.splash,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.8, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) => Opacity(
                  opacity: ((scale - 0.8) / 0.2).clamp(0.0, 1.0),
                  child: Transform.scale(scale: scale, child: child),
                ),
                child: TpLogo(width: width * 0.5),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: FadeSlideIn(
                delay: Duration(milliseconds: 700),
                offset: 8,
                child: Center(
                  child: Text(
                    'Powered by Easy Trust Corporation',
                    style: TextStyle(fontSize: 14, color: TpColors.muted),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Screen 2: tagline screen shown before onboarding. Tap to continue.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), _next);
  }

  void _next() {
    if (mounted) Navigator.pushReplacementNamed(context, '/onboarding');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      backgroundColor: TpColors.background,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _next,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              children: [
                const Spacer(flex: 5),
                FadeSlideIn(child: TpLogo(width: width * 0.42)),
                const SizedBox(height: 36),
                const FadeSlideIn(
                  delay: Duration(milliseconds: 150),
                  child: Text(
                    'Banking you can count on.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 14),
                const FadeSlideIn(
                  delay: Duration(milliseconds: 300),
                  child: Text(
                    'Everyday money. More possibilities.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: TpColors.muted),
                  ),
                ),
                const SizedBox(height: 24),
                const FadeSlideIn(
                  delay: Duration(milliseconds: 450),
                  child: PageDots(count: 3, index: 0),
                ),
                const Spacer(flex: 6),
                const Text(
                  'Secure by design. Built around you.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: TpColors.green,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'TRUSTPAY · ENTRY & SETUP',
                  style: TextStyle(fontSize: 12, letterSpacing: 0.6, color: TpColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
