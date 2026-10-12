import 'dart:async';

import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _beginCountdown();
  }

  void _resend() {
    // TODO: ask your API to send a new code.
    setState(() => _seconds = 30);
    _beginCountdown();
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
    final phone = (ModalRoute.of(context)?.settings.arguments as String?) ?? 'your phone';
    final canResend = _seconds == 0;

    return StepScaffold(
      counter: '02 / 04',
      title: 'Verify your phone',
      subtitle: 'Enter the 6-digit code sent to $phone.',
      primaryLabel: 'Verify phone',
      // TODO: verify the code with your API before moving on.
      onPrimary: _code.length == _length ? () => Navigator.pushNamed(context, '/identity') : null,
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
          const SizedBox(height: 8),
          const InfoBanner(text: 'Never share your verification code. TrustPay will never ask for it.'),
        ],
      ),
    );
  }
}
