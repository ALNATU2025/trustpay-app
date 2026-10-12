import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';

/// Screen 6: "Your money. More possibilities." with the hero photo.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Made for your everyday',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                          child: const Text(
                            'Skip',
                            style: TextStyle(fontWeight: FontWeight.w700, color: TpColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const TpLogo(height: 64),
                    const SizedBox(height: 16),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 100),
                      offset: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: TpShadows.card,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: AspectRatio(
                            aspectRatio: 708 / 400,
                            child: Image.asset(
                              'assets/images/welcome_hero.jpg',
                              fit: BoxFit.cover,
                              semanticLabel: 'A customer using TrustPay on her phone in a café',
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const FadeSlideIn(
                      delay: Duration(milliseconds: 250),
                      child: Text(
                        'Your money.\nMore possibilities.',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, height: 1.15),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Bank, pay your bills and grow your business. One place for the way you live.',
                      style: TextStyle(fontSize: 15, height: 1.45, color: TpColors.muted),
                    ),
                    const SizedBox(height: 20),
                    const Row(
                      children: [
                        Expanded(child: _Pillar(icon: Icons.account_balance_outlined, label: 'Banking')),
                        SizedBox(width: 12),
                        Expanded(child: _Pillar(icon: Icons.flash_on_outlined, label: 'Bills')),
                        SizedBox(width: 12),
                        Expanded(child: _Pillar(icon: Icons.contactless_outlined, label: 'POS')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                children: [
                  PrimaryButton(
                    label: 'Create an account',
                    trailingIcon: Icons.arrow_forward,
                    onPressed: () => Navigator.pushNamed(context, '/signup'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    child: const Text(
                      'Already with TrustPay? Sign in',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: TpColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pillar extends StatelessWidget {
  const _Pillar({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: TpColors.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: TpColors.primary, size: 26),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
