import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';

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
            Center(child: TpLogo(width: width * 0.5)),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Center(
                child: Text(
                  'Powered by Easy Trust Corporation',
                  style: TextStyle(fontSize: 14, color: TpColors.muted),
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
                TpLogo(width: width * 0.42),
                const SizedBox(height: 36),
                const Text(
                  'Banking you can count on.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Everyday money. More possibilities.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: TpColors.muted),
                ),
                const SizedBox(height: 24),
                const PageDots(count: 3, index: 0),
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
