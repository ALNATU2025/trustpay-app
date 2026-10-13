import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/hero_art.dart';
import '../widgets/motion.dart';
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
          subtitle: 'Top up your phone, pay for power and TV, and shop online. All from one secure account.',
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
    return const Column(
      children: [
        OnboardingHero(photoAsset: 'assets/images/onboarding_1.jpg', scene: PhoneScene()),
        SizedBox(height: 16),
        InfoBanner(text: 'A clear balance, simple transfers and receipts you can always find.'),
        SizedBox(height: 24),
        PageDots(count: 3, index: 0),
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
        const OnboardingHero(photoAsset: 'assets/images/onboarding_2.jpg', scene: ServicesScene()),
        const SizedBox(height: 16),
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
                subtitle: 'EDSA Cash Power, TV and more',
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
        const OnboardingHero(photoAsset: 'assets/images/onboarding_3.jpg', scene: PosScene()),
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
