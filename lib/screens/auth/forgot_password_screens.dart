import 'package:flutter/material.dart';

import '../../services/api.dart';
import '../../services/trustpay_api.dart';
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
  String? _error;

  @override
  void dispose() {
    _id.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final devCode = await api.forgotPassword(_id.text.trim());
      if (!mounted) return;
      openScreen(context, ResetCodeScreen(contact: _id.text.trim(), devCode: devCode));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
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
              hint: 'you@example.com or 076 123 456',
              keyboardType: TextInputType.emailAddress,
              validator: _required,
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[ErrorBanner(_error!), const SizedBox(height: 16)],
            const InfoBanner(text: 'We will only send the code to the contact saved on your account.'),
          ],
        ),
      ),
    );
  }
}

/// Reset 2/4: enter the 6-digit code.
class ResetCodeScreen extends StatefulWidget {
  const ResetCodeScreen({super.key, required this.contact, this.devCode});

  final String contact;

  /// Only set by a sandbox server (OTP_DEBUG), so the app can be tested without SMS.
  final String? devCode;

  @override
  State<ResetCodeScreen> createState() => _ResetCodeScreenState();
}

class _ResetCodeScreenState extends State<ResetCodeScreen> {
  String _code = '';
  bool _busy = false;
  String? _error;
  String? _devCode;

  @override
  void initState() {
    super.initState();
    _devCode = widget.devCode;
  }

  Future<void> _verify() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final token = await api.verifyResetCode(widget.contact, _code);
      if (!mounted) return;
      openScreen(context, NewPasswordScreen(resetToken: token));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    try {
      final devCode = await api.forgotPassword(widget.contact);
      if (!mounted) return;
      setState(() {
        _devCode = devCode;
        _error = null;
      });
      showMessage(context, 'A new code is on its way.');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      eyebrow: 'RESET PASSWORD',
      counter: '02 / 04',
      title: 'Enter the code',
      subtitle: 'If an account matches ${widget.contact}, we sent a 6-digit code to its WhatsApp.',
      primaryLabel: 'Verify code',
      primaryLoading: _busy,
      onPrimary: _code.length == 6 && !_busy ? _verify : null,
      secondaryLabel: 'Change contact',
      onSecondary: () => Navigator.maybePop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_devCode != null) ...[
            InfoBanner(
              text: 'Test server: your code is $_devCode. Real SMS is not connected yet.',
              icon: Icons.science_outlined,
            ),
            const SizedBox(height: 16),
          ],
          OtpInput(length: 6, autofocus: true, boxHeight: 54, onChanged: (v) => setState(() => _code = v)),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _resend,
              child: const Text('Resend code', style: TextStyle(fontSize: 14)),
            ),
          ),
          if (_error != null) ...[const SizedBox(height: 8), ErrorBanner(_error!)],
          const SizedBox(height: 8),
          const InfoBanner(text: 'Never share this code. TrustPay will never ask for it.'),
        ],
      ),
    );
  }
}

/// Reset 3/4: choose a new password.
class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key, required this.resetToken});

  final String resetToken;

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await api.resetPassword(widget.resetToken, _password.text);
      if (!mounted) return;
      replaceScreen(context, const ResetDoneScreen());
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      eyebrow: 'RESET PASSWORD',
      counter: '03 / 04',
      title: 'Choose a new password',
      subtitle: 'At least 8 characters, a number and a symbol.',
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
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                final ok = v.length >= 8 && RegExp(r'[0-9]').hasMatch(v) && RegExp(r'[^A-Za-z0-9]').hasMatch(v);
                return ok ? null : 'At least 8 characters, a number and a symbol';
              },
            ),
            const SizedBox(height: 16),
            TpField(
              label: 'Confirm new password',
              controller: _confirm,
              isPassword: true,
              validator: (v) => v == _password.text ? null : 'Passwords do not match',
            ),
            if (_error != null) ...[const SizedBox(height: 16), ErrorBanner(_error!)],
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
