import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/nav.dart';
import '../../widgets/common.dart';
import '../../widgets/flow_widgets.dart';
import '../../widgets/otp_input.dart';
import '../../widgets/step_scaffold.dart';

String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

/// Reset 1/4: ask for the phone number or email.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _id = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _id.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _sending = true);
    // TODO: ask your API to send a reset code.
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _sending = false);
    openScreen(context, ResetCodeScreen(contact: _id.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      eyebrow: 'RESET PASSWORD',
      counter: '01 / 04',
      title: 'Forgot your password?',
      subtitle: 'Enter the phone number or email on your account. We will send a code.',
      primaryLabel: 'Send code',
      primaryLoading: _sending,
      onPrimary: _sending ? null : _send,
      secondaryLabel: 'Back to login',
      onSecondary: () => Navigator.maybePop(context),
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
            const InfoBanner(text: 'We will only send the code to the contact saved on your account.'),
          ],
        ),
      ),
    );
  }
}

/// Reset 2/4: enter the 6-digit code.
class ResetCodeScreen extends StatefulWidget {
  const ResetCodeScreen({super.key, required this.contact});

  final String contact;

  @override
  State<ResetCodeScreen> createState() => _ResetCodeScreenState();
}

class _ResetCodeScreenState extends State<ResetCodeScreen> {
  String _code = '';

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      eyebrow: 'RESET PASSWORD',
      counter: '02 / 04',
      title: 'Enter the code',
      subtitle: 'We sent a 6-digit code to ${widget.contact}.',
      primaryLabel: 'Verify code',
      // TODO: check the code with your API.
      onPrimary: _code.length == 6 ? () => openScreen(context, const NewPasswordScreen()) : null,
      secondaryLabel: 'Change contact',
      onSecondary: () => Navigator.maybePop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OtpInput(length: 6, autofocus: true, boxHeight: 54, onChanged: (v) => setState(() => _code = v)),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => showMessage(context, 'A new code is on its way.'),
              child: const Text('Resend code', style: TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(height: 8),
          const InfoBanner(text: 'Never share this code. TrustPay will never ask for it.'),
        ],
      ),
    );
  }
}

/// Reset 3/4: choose a new password.
class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    // TODO: send the new password to your API.
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    replaceScreen(context, const ResetDoneScreen());
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      eyebrow: 'RESET PASSWORD',
      counter: '03 / 04',
      title: 'Choose a new password',
      subtitle: 'Use at least 8 characters.',
      primaryLabel: 'Reset password',
      primaryLoading: _saving,
      onPrimary: _saving ? null : _save,
      secondaryLabel: 'Cancel',
      onSecondary: () => Navigator.of(context).popUntil((r) => r.isFirst || r.settings.name == '/login'),
      child: Form(
        key: _form,
        child: Column(
          children: [
            TpField(
              label: 'New password',
              controller: _password,
              isPassword: true,
              validator: (v) => (v == null || v.length < 8) ? 'Use at least 8 characters' : null,
            ),
            const SizedBox(height: 16),
            TpField(
              label: 'Confirm new password',
              controller: _confirm,
              isPassword: true,
              validator: (v) => v == _password.text ? null : 'Passwords do not match',
            ),
          ],
        ),
      ),
    );
  }
}

/// Reset 4/4: done.
class ResetDoneScreen extends StatelessWidget {
  const ResetDoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void toLogin() => Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    return StepScaffold(
      eyebrow: 'RESET PASSWORD',
      counter: '04 / 04',
      title: 'Password updated',
      onBack: toLogin,
      headerLabel: 'Done',
      onHeaderAction: toLogin,
      primaryLabel: 'Back to login',
      onPrimary: toLogin,
      child: const Column(
        children: [
          ResultHeader(
            headline: 'You are all set',
            detail: 'Log in with your new password. Your transaction PIN has not changed.',
          ),
        ],
      ),
    );
  }
}
