import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api.dart';
import '../../services/trustpay_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/nav.dart';
import '../../widgets/api_builder.dart';
import '../../widgets/common.dart';
import '../../widgets/menu_widgets.dart';

/// Recent sign-ins and security changes on the account, so the owner can spot anything unusual.
class SecurityActivityScreen extends StatelessWidget {
  const SecurityActivityScreen({super.key});

  IconData _icon(String type) => switch (type) {
        'new_device' => Icons.devices_other_outlined,
        'pin_changed' || 'pin_reset' => Icons.pin_outlined,
        'password_changed' => Icons.lock_outline,
        'sessions_revoked' => Icons.logout,
        _ => Icons.login,
      };

  String _when(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return PlainScaffold(
      title: 'Account activity',
      child: ApiBuilder<Map<String, dynamic>>(
        load: api.securityOverview,
        builder: (context, d, reload) {
          final events = asMapList(d['events']);
          final locked = asStrOrNull(d['pinLockedUntil']);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (locked != null) ...[ErrorBanner('Your PIN is locked after too many wrong attempts until ${_when(locked)}. You can reset it from Security.'), const SizedBox(height: 12)],
              const InfoBanner(text: 'If you see a sign-in you do not recognise, change your password and PIN, then sign out of all devices.'),
              const SizedBox(height: 14),
              if (events.isEmpty)
                const Text('No activity yet.', style: TextStyle(color: TpColors.muted))
              else
                MenuGroup(children: [
                  for (final e in events)
                    ListTile(
                      key: ValueKey(asStr(e['id'])),
                      leading: Icon(_icon(asStr(e['type'])), color: asStr(e['type']) == 'new_device' ? TpColors.danger : TpColors.primary),
                      title: Text(asStr(e['title']), style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(_when(asStr(e['at']))),
                    ),
                ]),
            ],
          );
        },
      ),
    );
  }
}

/// "I forgot my PIN": set a new one by proving the account password.
Future<void> showResetPinSheet(BuildContext context) async {
  final done = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => const _ResetPinSheet(),
  );
  if (done == true && context.mounted) showMessage(context, 'Your PIN has been reset.');
}

class _ResetPinSheet extends StatefulWidget {
  const _ResetPinSheet();

  @override
  State<_ResetPinSheet> createState() => _ResetPinSheetState();
}

class _ResetPinSheetState extends State<_ResetPinSheet> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await api.resetPin(password: _password.text, newPin: _pin.text);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Reset transaction PIN', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Enter your account password to choose a new 4-digit PIN. This also unlocks a locked PIN.', style: TextStyle(color: TpColors.muted, height: 1.4)),
              const SizedBox(height: 16),
              TpField(label: 'Account password', controller: _password, isPassword: true, validator: (v) => (v ?? '').isEmpty ? 'Enter your password' : null),
              const SizedBox(height: 12),
              TpField(
                label: 'New PIN',
                controller: _pin,
                isPassword: true,
                maxLength: 4,
                digitsOnly: true,
                keyboardType: TextInputType.number,
                validator: (v) => (v ?? '').length != 4 ? 'PIN is 4 digits' : null,
              ),
              const SizedBox(height: 12),
              TpField(
                label: 'Confirm new PIN',
                controller: _confirm,
                isPassword: true,
                maxLength: 4,
                digitsOnly: true,
                keyboardType: TextInputType.number,
                validator: (v) => v != _pin.text ? 'PINs do not match' : null,
              ),
              if (_error != null) ...[const SizedBox(height: 12), ErrorBanner(_error!)],
              const SizedBox(height: 16),
              PrimaryButton(label: 'Reset PIN', loading: _busy, onPressed: _busy ? () {} : _save),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Lost my phone": signs out every other device after confirming the password.
Future<void> confirmRevokeSessions(BuildContext context) async {
  final c = TextEditingController();
  String? error;
  bool busy = false;
  final ok = await showDialog<bool>(
    context: context,
    builder: (d) => StatefulBuilder(
      builder: (d, set) => AlertDialog(
        title: const Text('Sign out of all devices?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Every other phone or browser signed in to your account will be logged out. This device stays signed in.'),
            const SizedBox(height: 12),
            TpField(label: 'Account password', controller: c, isPassword: true),
            if (error != null) ...[const SizedBox(height: 10), ErrorBanner(error!)],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          TextButton(
            onPressed: busy
                ? null
                : () async {
                    if (c.text.isEmpty) {
                      set(() => error = 'Enter your password.');
                      return;
                    }
                    set(() {
                      busy = true;
                      error = null;
                    });
                    try {
                      final token = await api.revokeAllSessions(c.text);
                      await apiClient.setToken(token);
                      if (d.mounted) Navigator.pop(d, true);
                    } on ApiException catch (e) {
                      set(() {
                        busy = false;
                        error = e.message;
                      });
                    }
                  },
            child: const Text('Sign out others'),
          ),
        ],
      ),
    ),
  );
  c.dispose();
  if (ok == true && context.mounted) showMessage(context, 'All other devices were signed out.');
}
