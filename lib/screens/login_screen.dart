import 'package:flutter/material.dart';

import '../services/api.dart';
import '../services/app_state.dart';
import '../services/trustpay_api.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../utils/nav.dart';
import '../widgets/step_scaffold.dart';
import 'auth/forgot_password_screens.dart';

/// Screen 11: returning user login.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.onSwitch});

  /// Called by "Create account". Inside [AuthPager] this swipes to Sign up.
  final VoidCallback? onSwitch;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _id.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  Future<void> _login() async {
    if (!_form.currentState!.validate() || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await api.login(_id.text.trim(), _password.text);
      await appState.signIn(result);
      if (!mounted) return;
      final next = AppState.routeFor(result.user);
      if (next.route == '/otp') {
        // The code was not confirmed yet: send a fresh one.
        try {
          appState.devOtp = await api.sendOtp();
        } on ApiException {
          // The verification screen has a "Resend code" button.
        }
        if (!mounted) return;
      }
      Navigator.pushNamedAndRemoveUntil(context, next.route, (_) => false, arguments: next.arguments);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      eyebrow: 'RETURNING USER · LOGIN',
      title: 'Welcome back',
      subtitle: 'Log in to your TrustPay account securely.',
      primaryLabel: 'Secure login',
      primaryLoading: _busy,
      onPrimary: _busy ? null : _login,
      secondaryLabel: 'New to TrustPay? Create account',
      onSecondary: widget.onSwitch ?? () => Navigator.pushNamed(context, '/signup'),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TpField(
              label: 'Phone number or email',
              controller: _id,
              hint: 'you@example.com or 076 123 456',
              keyboardType: TextInputType.emailAddress,
              validator: _required,
            ),
            const SizedBox(height: 16),
            TpField(
              label: 'Password',
              controller: _password,
              isPassword: true,
              validator: _required,
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => openScreen(context, const ForgotPasswordScreen()),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(48, 40),
                foregroundColor: TpColors.primary,
              ),
              child: const Text('Forgot password?', style: TextStyle(fontSize: 14)),
            ),
            const SizedBox(height: 8),
            if (_error != null) ...[ErrorBanner(_error!), const SizedBox(height: 12)],
            const InfoBanner(
              text: 'Your password protects your account. Your transaction PIN protects payments.',
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Need help signing in? Contact support',
                style: TextStyle(fontSize: 14, color: TpColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
