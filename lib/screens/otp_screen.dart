import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api.dart';
import '../services/app_state.dart';
import '../services/trustpay_api.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/otp_input.dart';
import '../widgets/step_scaffold.dart';

/// Screen 8: step 2 of 4, phone verification.
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const _length = 6;
  String _code = '';
  int _seconds = 30;
  Timer? _timer;
  bool _busy = false;
  String? _error;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _beginCountdown();
  }

  Future<void> _resend() async {
    setState(() {
      _error = null;
      _notice = null;
    });
    try {
      appState.devOtp = await api.sendOtp();
      if (!mounted) return;
      setState(() {
        _seconds = 30;
        _notice = 'A new code is on its way.';
      });
      _beginCountdown();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _verify() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = await api.verifyOtp(_code);
      appState.setUser(user);
      appState.devOtp = null;
      if (!mounted) return;
      Navigator.pushNamed(context, '/identity');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _beginCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_seconds <= 1) {
        t.cancel();
      }
      setState(() => _seconds = _seconds - 1 < 0 ? 0 : _seconds - 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phone = (ModalRoute.of(context)?.settings.arguments as String?) ?? appState.user?.phone ?? 'your phone';
    final canResend = _seconds == 0;

    return StepScaffold(
      counter: '02 / 04',
      title: 'Verify your phone',
      subtitle: 'Enter the 6-digit code sent to $phone.',
      primaryLabel: 'Verify phone',
      primaryLoading: _busy,
      onPrimary: _code.length == _length && !_busy ? _verify : null,
      secondaryLabel: 'Change phone number',
      onSecondary: () => Navigator.maybePop(context),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.sms_outlined, color: TpColors.primary, size: 34),
                SizedBox(height: 12),
                Text(
                  'One quick security check',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 6),
                Text(
                  'This helps us confirm that this number belongs to you.',
                  style: TextStyle(fontSize: 14, height: 1.4, color: TpColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (appState.devOtp != null) ...[
            InfoBanner(
              text: 'Test server: your code is ${appState.devOtp}. Real SMS is not connected yet.',
              icon: Icons.science_outlined,
            ),
            const SizedBox(height: 16),
          ],
          OtpInput(
            length: _length,
            autofocus: true,
            boxHeight: 54,
            onChanged: (v) => setState(() => _code = v),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: canResend ? _resend : null,
              child: Text(
                canResend
                    ? 'Resend code'
                    : 'Resend code in 00:${_seconds.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 14,
                  color: canResend ? TpColors.primary : TpColors.primary.withOpacity(0.8),
                ),
              ),
            ),
          ),
          if (_error != null) ...[const SizedBox(height: 8), ErrorBanner(_error!)],
          if (_notice != null && _error == null) ...[const SizedBox(height: 8), InfoBanner(text: _notice!, icon: Icons.check_circle_outline)],
          const SizedBox(height: 8),
          const InfoBanner(text: 'Never share your verification code. TrustPay will never ask for it.'),
        ],
      ),
    );
  }
}
