import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/step_scaffold.dart';

/// Screen 11: returning user login.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _id.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  void _login() {
    if (_form.currentState!.validate()) {
      // TODO: authenticate with your API.
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      eyebrow: 'RETURNING USER · LOGIN',
      title: 'Welcome back, Ada',
      subtitle: 'Log in to your TrustPay account securely.',
      primaryLabel: 'Secure login',
      onPrimary: _login,
      secondaryLabel: 'New to TrustPay? Create account',
      onSecondary: () => Navigator.pushNamed(context, '/signup'),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TpField(
              label: 'Phone number or email',
              controller: _id,
              hint: 'ada.okafor@example.com',
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
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(48, 40),
                foregroundColor: TpColors.primary,
              ),
              child: const Text('Forgot password?', style: TextStyle(fontSize: 14)),
            ),
            const SizedBox(height: 8),
            const InfoBanner(
              text: 'Your password protects your account. Your transaction PIN protects payments.',
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  // TODO: wire up local_auth for Face ID / fingerprint.
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: TpColors.border),
                  ),
                  child: const Row(
                    children: [
                      IconBox(icon: Icons.face_outlined, size: 44),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Use Face ID next time',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Enable after a successful login on this device.',
                              style: TextStyle(fontSize: 13, color: TpColors.muted),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: TpColors.primary),
                    ],
                  ),
                ),
              ),
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
