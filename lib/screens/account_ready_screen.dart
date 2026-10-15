import 'package:flutter/material.dart';

import '../services/api.dart';
import '../services/app_state.dart';
import '../services/trustpay_api.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/otp_input.dart';
import '../widgets/step_scaffold.dart';

/// Screen 10: step 4 of 4, create a transaction PIN and see the new account.
class AccountReadyScreen extends StatefulWidget {
  const AccountReadyScreen({super.key});

  @override
  State<AccountReadyScreen> createState() => _AccountReadyScreenState();
}

class _AccountReadyScreenState extends State<AccountReadyScreen> {
  String _pin = '';
  String _confirm = '';
  bool _busy = false;
  String? _error;

  bool get _matched => _pin.length == 4 && _pin == _confirm;

  Future<void> _save() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = await api.setPin(_pin);
      appState.setUser(user);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      counter: '04 / 04',
      title: 'Your account is ready',
      subtitle: 'Choose a 4-digit PIN to authorise payments. Your account details are below.',
      primaryLabel: 'Save PIN and continue',
      primaryLoading: _busy,
      onPrimary: _matched && !_busy ? _save : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create transaction PIN · 4 digits',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          OtpInput(
            length: 4,
            obscure: true,
            boxHeight: 52,
            onChanged: (v) => setState(() => _pin = v),
          ),
          const SizedBox(height: 20),
          Text(
            _matched ? 'Confirm PIN · matched' : 'Confirm PIN',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          OtpInput(
            length: 4,
            obscure: true,
            boxHeight: 52,
            onChanged: (v) => setState(() => _confirm = v),
          ),
          const SizedBox(height: 16),
          if (_error != null)
            ErrorBanner(_error!)
          else if (_matched)
            const InfoBanner(
              icon: Icons.check_circle_outline,
              background: TpColors.greenTint,
              accent: TpColors.green,
              textColor: TpColors.green,
              text: 'PINs match. Use it to authorise payments and never share it.',
            ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: ListenableBuilder(
              listenable: appState,
              builder: (context, _) => Column(
                children: [
                  _Row('Account name', appState.me.fullName),
                  _Row('Account number', appState.me.accountNumber),
                  const _Row('Bank', 'TrustPay'),
                  _Row('Opening balance', formatLeone(appState.balance), last: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Add money from Home to start banking.',
            style: TextStyle(fontSize: 14, color: TpColors.muted),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.last = false});

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: TpColors.muted)),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
