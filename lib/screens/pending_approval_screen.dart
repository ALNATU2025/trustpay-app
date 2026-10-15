import 'package:flutter/material.dart';

import '../services/api.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/nav.dart';
import '../widgets/common.dart';
import '../widgets/step_scaffold.dart';

/// Shown after sign up until an admin approves the account (Tier 1).
class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  bool _busy = false;

  Future<void> _check() async {
    setState(() => _busy = true);
    try {
      await appState.refreshUser();
      if (!mounted) return;
      final u = appState.user;
      if (u != null && u.status == 'active') {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      } else {
        showMessage(context, 'Still waiting for approval.');
      }
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    await appState.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final u = appState.user;
    final rejected = u != null && u.kycStatus == 'rejected';
    return StepScaffold(
      eyebrow: 'ACCOUNT REVIEW',
      title: rejected ? 'Account not approved' : 'Waiting for approval',
      subtitle: rejected
          ? 'We could not approve your details. ${u.kycReason.isEmpty ? 'Please contact support.' : u.kycReason}'
          : 'Thanks for signing up. A TrustPay admin is checking your details. You can use your account as soon as it is approved.',
      primaryLabel: 'Check status',
      primaryLoading: _busy,
      onPrimary: _busy ? null : _check,
      secondaryLabel: 'Log out',
      onSecondary: _logout,
      child: Column(
        children: [
          Icon(rejected ? Icons.error_outline : Icons.hourglass_top_rounded, size: 72, color: rejected ? TpColors.danger : TpColors.primary),
          const SizedBox(height: 16),
          const InfoBanner(text: 'New accounts start on Tier 1 (Le 100 a day, Le 500 balance). You can upgrade later from your profile.'),
        ],
      ),
    );
  }
}
