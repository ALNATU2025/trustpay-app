import 'package:flutter/material.dart';

import '../services/api.dart';
import '../services/app_state.dart';
import '../services/trustpay_api.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/step_scaffold.dart';

String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

/// Screen 7: step 1 of 4, basic details.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, this.onSwitch});

  /// Called by "Log in". Inside [AuthPager] this swipes back to Login.
  final VoidCallback? onSwitch;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _agreed = false;
  bool _termsError = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _emailRule(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    return v.contains('@') && v.contains('.') ? null : 'Enter a valid email';
  }

  String? _passwordRule(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    final ok = v.length >= 8 &&
        RegExp(r'[0-9]').hasMatch(v) &&
        RegExp(r'[^A-Za-z0-9]').hasMatch(v);
    return ok ? null : 'At least 8 characters, a number and a symbol';
  }

  Future<void> _submit() async {
    final valid = _form.currentState!.validate();
    setState(() => _termsError = !_agreed);
    if (!valid || !_agreed || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await api.register(
        firstName: _first.text.trim(),
        lastName: _last.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        password: _password.text,
      );
      await appState.signIn(result);
      if (!mounted) return;
      appState.devOtp = result.devOtp;
      Navigator.pushNamed(context, '/otp', arguments: result.user.phone);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      counter: '01 / 04',
      title: 'Let’s get to know you',
      subtitle: 'Use the details on your identity document.',
      primaryLabel: 'Create account',
      primaryLoading: _busy,
      onPrimary: _busy ? null : _submit,
      secondaryLabel: 'Already have an account? Log in',
      onSecondary: widget.onSwitch ?? () => Navigator.pushReplacementNamed(context, '/login'),
      child: Form(
        key: _form,
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TpField(label: 'First name', controller: _first, hint: 'Aminata', validator: _required),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TpField(label: 'Last name', controller: _last, hint: 'Kamara', validator: _required),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TpField(
              label: 'Email address',
              controller: _email,
              hint: 'aminata.kamara@example.com',
              keyboardType: TextInputType.emailAddress,
              validator: _emailRule,
            ),
            const SizedBox(height: 16),
            TpField(
              label: 'Phone number',
              controller: _phone,
              hint: '076 123 456',
              keyboardType: TextInputType.phone,
              validator: _required,
            ),
            const SizedBox(height: 16),
            TpField(
              label: 'Password',
              controller: _password,
              isPassword: true,
              validator: _passwordRule,
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'At least 8 characters, a number and a symbol.',
                style: TextStyle(fontSize: 13, color: TpColors.muted),
              ),
            ),
            const SizedBox(height: 12),
            if (_error != null) ...[
              ErrorBanner(_error!),
              const SizedBox(height: 12),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: Checkbox(
                    value: _agreed,
                    activeColor: TpColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    onChanged: (v) => setState(() {
                      _agreed = v ?? false;
                      _termsError = false;
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'I agree to TrustPay’s Terms of Service and Privacy Policy.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: _termsError ? TpColors.danger : TpColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
