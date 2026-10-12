import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/step_scaffold.dart';

/// Screens 3 to 5: the three swipeable onboarding pages.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _index = 0;

  static const _duration = Duration(milliseconds: 300);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < 2) {
      _pages.nextPage(duration: _duration, curve: Curves.easeOut);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_index > 0) {
      _pages.previousPage(duration: _duration, curve: Curves.easeOut);
    } else {
      Navigator.maybePop(context);
    }
  }

  void _finish() => Navigator.pushReplacementNamed(context, '/welcome');

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pages,
      onPageChanged: (i) => setState(() => _index = i),
      children: [
        StepScaffold(
          counter: '01 / 03',
          title: 'Your money, made simple.',
          subtitle: 'Send, receive and stay on top of your everyday money with TrustPay.',
          headerAtBottom: true,
          onBack: _back,
          primaryLabel: 'Next',
          onPrimary: _next,
          secondaryLabel: 'Skip',
          onSecondary: _finish,
          child: const _PageOne(),
        ),
        StepScaffold(
          counter: '02 / 03',
          title: 'Life’s essentials, sorted.',
          subtitle: 'Top up your phone, pay your bills and shop online. All from one secure account.',
          onBack: _back,
          primaryLabel: 'Next',
          onPrimary: _next,
          secondaryLabel: 'Skip',
          onSecondary: _finish,
          child: const _PageTwo(),
        ),
        StepScaffold(
          counter: '03 / 03',
          title: 'A little more for business.',
          subtitle: 'Collect payments, manage your terminal and follow every settlement with TrustPay POS.',
          onBack: _back,
          primaryLabel: 'Get started',
          onPrimary: _next,
          secondaryLabel: 'Skip',
          onSecondary: _finish,
          child: const _PageThree(),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.color = TpColors.tint});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(28)),
      child: child,
    );
  }
}

class _PageOne extends StatelessWidget {
  const _PageOne();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Panel(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: TpColors.primary,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your money. In one place.',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatNaira(248500),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hello, Ada 👋',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const IconBox(icon: Icons.south_west, size: 40),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Money received',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Instant account notification',
                                style: TextStyle(fontSize: 13, color: TpColors.muted),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatNaira(25000, showSign: true, decimals: 0),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: TpColors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: TpColors.border),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const InfoBanner(text: 'A clear balance, simple transfers and receipts you can always find.'),
        const SizedBox(height: 24),
        const PageDots(count: 3, index: 0),
      ],
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TpColors.border),
      ),
      child: Row(
        children: [
          IconBox(icon: icon, size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 13, color: TpColors.muted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: TpColors.primary),
        ],
      ),
    );
  }
}

class _PageTwo extends StatelessWidget {
  const _PageTwo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _Panel(
          child: Column(
            children: [
              _FeatureTile(
                icon: Icons.smartphone_outlined,
                title: 'Airtime & data',
                subtitle: 'Stay connected, wherever you are',
              ),
              SizedBox(height: 12),
              _FeatureTile(
                icon: Icons.flash_on_outlined,
                title: 'Bill payments',
                subtitle: 'Electricity, TV and more',
              ),
              SizedBox(height: 12),
              _FeatureTile(
                icon: Icons.credit_card_outlined,
                title: 'Virtual cards',
                subtitle: 'Your everyday online checkout',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const InfoBanner(text: 'Know the total before you pay. Get a receipt after every purchase.'),
        const SizedBox(height: 24),
        const PageDots(count: 3, index: 1),
      ],
    );
  }
}

class _PageThree extends StatelessWidget {
  const _PageThree();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Panel(
          color: TpColors.greenTint,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                const _MiniTerminal(),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Ada Stores', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      SizedBox(height: 12),
                      Text('24 payments', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                      SizedBox(height: 8),
                      Text(
                        'One easy way to get paid.',
                        style: TextStyle(fontSize: 14, color: TpColors.green),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Built for your next chapter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              SizedBox(height: 8),
              Text(
                'Request a terminal when you’re ready. See your sales, fees and settlement timing in one place.',
                style: TextStyle(fontSize: 14, height: 1.4, color: TpColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const InfoBanner(text: 'Start with personal banking. Add business tools whenever you need them.'),
        const SizedBox(height: 24),
        const PageDots(count: 3, index: 2),
      ],
    );
  }
}

class _MiniTerminal extends StatelessWidget {
  const _MiniTerminal();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      height: 154,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1F3F),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Container(
            height: 70,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE9F0FE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              formatNaira(18500, decimals: 0),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: TpColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6EE7B7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF6B7690),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
