import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'common.dart';
import 'motion.dart';

/// Shared layout for the "ENTRY & SETUP" style screens: header, eyebrow +
/// counter, title, subtitle, scrollable body, and the two bottom buttons.
class StepScaffold extends StatelessWidget {
  const StepScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    required this.primaryLabel,
    required this.onPrimary,
    this.eyebrow = 'ENTRY & SETUP',
    this.counter,
    this.secondaryLabel,
    this.onSecondary,
    this.headerAtBottom = false,
    this.onBack,
    this.headerLabel = 'Help',
    this.onHeaderAction,
    this.primaryLoading = false,
  });

  /// Shows a spinner on the main button while waiting for your API.
  final bool primaryLoading;

  final String eyebrow;
  final String? counter;
  final String title;
  final String? subtitle;
  final Widget child;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// The first onboarding page puts the back / logo / help row above the
  /// buttons instead of at the top.
  final bool headerAtBottom;
  final VoidCallback? onBack;

  /// Right-hand link in the header ('Help', 'Cancel' or 'Done').
  final String headerLabel;
  final VoidCallback? onHeaderAction;

  @override
  Widget build(BuildContext context) {
    final header = FlowHeader(
      onBack: onBack,
      rightLabel: headerLabel,
      onHelp: onHeaderAction,
    );

    return Scaffold(
      backgroundColor: TpColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            children: [
              if (!headerAtBottom) header,
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(top: headerAtBottom ? 12 : 16, bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeSlideIn(
                        offset: 10,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              eyebrow,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: TpColors.primary,
                              ),
                            ),
                            if (counter != null)
                              Text(
                                counter!,
                                style: const TextStyle(fontSize: 12, color: TpColors.muted),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 60),
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 8),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 120),
                          child: Text(
                            subtitle!,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.4,
                              color: TpColors.muted,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 180),
                        offset: 24,
                        child: child,
                      ),
                    ],
                  ),
                ),
              ),
              if (headerAtBottom) header,
              const SizedBox(height: 12),
              PrimaryButton(label: primaryLabel, onPressed: onPrimary, loading: primaryLoading),
              if (secondaryLabel != null) ...[
                const SizedBox(height: 8),
                SecondaryButton(label: secondaryLabel!, onPressed: onSecondary),
              ],
              if (kShowIllustrativeNote) const IllustrativeNote(),
            ],
          ),
        ),
      ),
    );
  }
}
