import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'premium.dart';

/// Picture area for the onboarding pages.
///
/// If a photo exists at [photoAsset] it is shown full width with a soft fade.
/// Otherwise the drawn [scene] is shown. To use real photos, add files such as
/// `assets/images/onboarding_1.jpg` (about 1000 x 700 px, landscape).
class OnboardingHero extends StatelessWidget {
  const OnboardingHero({super.key, required this.photoAsset, required this.scene, this.height = 250});

  final String photoAsset;
  final Widget scene;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: TpShadows.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Image.asset(
          photoAsset,
          fit: BoxFit.cover,
          width: double.infinity,
          height: height,
          errorBuilder: (context, error, stack) => scene,
          frameBuilder: (context, child, frame, sync) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: frame == null && !sync ? scene : child,
          ),
        ),
      ),
    );
  }
}

/// Gently bobs its child up and down.
class _Float extends StatefulWidget {
  const _Float({required this.child, this.amplitude = 6, this.phase = 0});

  final Widget child;
  final double amplitude;
  final double phase;

  @override
  State<_Float> createState() => _FloatState();
}

class _FloatState extends State<_Float> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, math.sin((_c.value + widget.phase) * 2 * math.pi) * widget.amplitude),
        child: child,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.title, required this.subtitle, this.tone = TpTone.green});

  final IconData icon;
  final String title;
  final String subtitle;
  final TpTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 22, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [tone.light, tone.dark]),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: tone.fg),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: TpColors.navy)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: TpColors.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dark blue backdrop with soft glows, used behind the scenes.
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.child, this.colors = const [Color(0xFF071B44), Color(0xFF0A3FB0), Color(0xFF1E6BFF)]});

  final Widget child;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: -60,
            top: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.07)),
            ),
          ),
          Positioned(
            left: -50,
            bottom: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Scene 1: a phone showing the balance, a TrustPay card behind it and a
/// "money received" notification.
class PhoneScene extends StatelessWidget {
  const PhoneScene({super.key});

  @override
  Widget build(BuildContext context) {
    return _Backdrop(
      child: Stack(
        children: [
          // Card behind the phone.
          Align(
            alignment: const Alignment(-0.78, 0.35),
            child: _Float(
              phase: 0.3,
              child: Transform.rotate(
                angle: -0.28,
                child: Container(
                  width: 150,
                  height: 94,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFD9A441)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 18, offset: const Offset(0, 8))],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TrustPay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF3B2A07))),
                      Spacer(),
                      Text('•••• 4821', style: TextStyle(fontSize: 13, letterSpacing: 1.5, color: Color(0xFF3B2A07))),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Phone.
          Align(
            alignment: const Alignment(0.05, 0.2),
            child: _Float(
              child: Container(
                width: 138,
                height: 232,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1220),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 28, offset: const Offset(0, 14))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    color: TpColors.background,
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 38,
                            height: 5,
                            decoration: BoxDecoration(color: const Color(0xFF0B1220), borderRadius: BorderRadius.circular(3)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text('Hello, Aminata', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: TpColors.navy)),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(gradient: TpGradients.premium, borderRadius: BorderRadius.circular(14)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Available balance', style: TextStyle(fontSize: 8, color: Colors.white70)),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  formatLeone(kAccountBalance),
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            for (final t in const [TpTone.blue, TpTone.amber, TpTone.teal]) ...[
                              Expanded(
                                child: Container(
                                  height: 30,
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [t.light, t.dark]),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Icon(Icons.circle, size: 8, color: t.fg),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        for (var i = 0; i < 3; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Row(
                              children: [
                                Container(width: 14, height: 14, decoration: BoxDecoration(color: TpColors.tint, borderRadius: BorderRadius.circular(5))),
                                const SizedBox(width: 6),
                                Expanded(child: Container(height: 5, decoration: BoxDecoration(color: TpColors.border, borderRadius: BorderRadius.circular(3)))),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Notification.
          Align(
            alignment: const Alignment(0.95, -0.55),
            child: _Float(
              phase: 0.6,
              child: _Chip(
                icon: Icons.south_west,
                title: 'Money received',
                subtitle: '+${formatLeone(1250, decimals: 0)} · Mohamed Sesay',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Scene 2: everyday services as floating tiles.
class ServicesScene extends StatelessWidget {
  const ServicesScene({super.key});

  Widget _tile(IconData icon, String label, String sub, TpTone tone) {
    return Container(
      width: 132,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.22), blurRadius: 22, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [tone.light, tone.dark]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: tone.fg, size: 20),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: TpColors.navy)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 11, color: TpColors.muted)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _Backdrop(
      child: Stack(
        children: [
          Align(
            alignment: const Alignment(-0.7, -0.62),
            child: _Float(child: _tile(Icons.flash_on_outlined, 'Cash Power', 'EDSA prepaid', TpTone.amber)),
          ),
          Align(
            alignment: const Alignment(0.78, -0.3),
            child: _Float(phase: 0.25, child: _tile(Icons.smartphone_outlined, 'Airtime', 'Orange · Africell', TpTone.purple)),
          ),
          Align(
            alignment: const Alignment(-0.62, 0.82),
            child: _Float(phase: 0.5, child: _tile(Icons.tv_outlined, 'TV & internet', 'DStv · StarTimes', TpTone.rose)),
          ),
          Align(
            alignment: const Alignment(0.86, 0.9),
            child: _Float(phase: 0.75, child: _tile(Icons.credit_card_outlined, 'Cards', 'Virtual & physical', TpTone.teal)),
          ),
        ],
      ),
    );
  }
}

/// Scene 3: a POS terminal with a receipt and a sales notification.
class PosScene extends StatelessWidget {
  const PosScene({super.key});

  @override
  Widget build(BuildContext context) {
    return _Backdrop(
      colors: const [Color(0xFF063B2B), Color(0xFF0E8F47), Color(0xFF2EC27E)],
      child: Stack(
        children: [
          // Receipt.
          Align(
            alignment: const Alignment(-0.62, 0.5),
            child: _Float(
              phase: 0.4,
              child: Transform.rotate(
                angle: -0.12,
                child: Container(
                  width: 92,
                  height: 128,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 18, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('RECEIPT', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1, color: TpColors.muted)),
                      const SizedBox(height: 6),
                      Text(formatLeone(185, decimals: 0), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: TpColors.navy)),
                      const SizedBox(height: 8),
                      for (var i = 0; i < 5; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Container(height: 4, width: i.isEven ? 66 : 48, decoration: BoxDecoration(color: TpColors.border, borderRadius: BorderRadius.circular(2))),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Terminal.
          Align(
            alignment: const Alignment(0.18, 0.3),
            child: _Float(
              child: Container(
                width: 124,
                height: 196,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1F3F),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 26, offset: const Offset(0, 14))],
                ),
                child: Column(
                  children: [
                    Container(
                      height: 78,
                      width: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: const Color(0xFFE9F0FE), borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Total', style: TextStyle(fontSize: 9, color: TpColors.muted)),
                          Text(formatLeone(925, decimals: 0), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: TpColors.primary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (var r = 0; r < 3; r++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            for (var c = 0; c < 3; c++) ...[
                              if (c > 0) const SizedBox(width: 6),
                              Expanded(
                                child: Container(
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: r == 2 && c == 2 ? const Color(0xFF6EE7B7) : const Color(0xFF1E3A6B),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0.95, -0.6),
            child: _Float(
              phase: 0.7,
              child: _Chip(
                icon: Icons.trending_up,
                title: '${formatLeone(9320, decimals: 0)} today',
                subtitle: '24 payments · Settles 4:00 PM',
              ),
            ),
          ),
          const Positioned(left: 16, top: 16, child: GoldChip(width: 30, height: 22)),
        ],
      ),
    );
  }
}
