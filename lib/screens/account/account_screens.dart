import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api.dart';
import '../../services/app_state.dart';
import '../../services/session_guard.dart';
import '../../services/settings.dart';
import '../../services/trustpay_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/nav.dart';
import '../../widgets/api_builder.dart';
import '../../widgets/common.dart';
import '../../widgets/flow_widgets.dart';
import '../../widgets/menu_widgets.dart';
import '../support/support_screen.dart';

Widget _errorBanner(String message) => InfoBanner(
      icon: Icons.error_outline,
      background: const Color(0xFFFDECEC),
      accent: TpColors.danger,
      textColor: TpColors.danger,
      text: message,
    );

/// Personal details from the signed-in account. Contact details and the business can be edited.
class PersonalDetailsScreen extends StatelessWidget {
  const PersonalDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final me = appState.me;
        return PlainScaffold(
          title: 'Personal details',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Avatar(name: me.fullName, size: 84)),
              const SizedBox(height: 12),
              Center(
                child: Text(me.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(me.tier, style: const TextStyle(fontSize: 14, color: TpColors.green)),
              ),
              const SizedBox(height: 20),
              DetailsCard(
                rows: [
                  ('Full name', me.fullName),
                  ('Phone number', me.phone),
                  ('Email', me.email.isNotEmpty ? me.email : 'Not added'),
                  if (me.address.isNotEmpty) ('Address', me.address),
                  if (me.businessName.isNotEmpty) ('Business', me.businessName),
                  ('Identity check', me.statusLabel),
                ],
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Edit contact details',
                onPressed: () => openScreen(context, const EditProfileScreen()),
              ),
              const SizedBox(height: 12),
              const InfoBanner(
                text: 'Your name comes from your identity document, so it cannot be edited here.',
              ),
              const SizedBox(height: 16),
              SecondaryButton(
                label: 'Ask support to change my name',
                onPressed: () => openScreen(context, const SupportScreen()),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Edit email, address and business name.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _email = TextEditingController(text: appState.me.email);
  late final TextEditingController _address = TextEditingController(text: appState.me.address);
  late final TextEditingController _business = TextEditingController(text: appState.me.businessName);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _address.dispose();
    _business.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final me = appState.me;
    final email = _email.text.trim();
    final address = _address.text.trim();
    final business = _business.text.trim();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await api.updateProfile(
        email: email != me.email ? email : null,
        address: address != me.address ? address : null,
        businessName: business != me.businessName ? business : null,
      );
      if (!mounted) return;
      appState.setUser(updated);
      showMessage(context, 'Details updated');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = errorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlainScaffold(
      title: 'Edit details',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TpField(
              label: 'Email',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return 'Required';
                return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t) ? null : 'Enter a valid email';
              },
            ),
            const SizedBox(height: 14),
            TpField(label: 'Address', controller: _address),
            const SizedBox(height: 14),
            TpField(label: 'Business name (optional)', controller: _business),
            if (_error != null) ...[
              const SizedBox(height: 16),
              _errorBanner(_error!),
            ],
            const SizedBox(height: 20),
            PrimaryButton(label: 'Save', loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

enum _Secret { password, pin }

/// Password and PIN changes.
class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  Future<void> _toggleBiometric(bool on) async {
    if (!on) {
      await appSettings.setBiometric(false);
      return;
    }
    if (!await Biometrics.available()) {
      if (mounted) showMessage(context, 'No fingerprint or face is set up on this phone. Add one in your phone settings first.');
      return;
    }
    if (await Biometrics.confirm('Turn on biometric unlock for TrustPay')) {
      await appSettings.setBiometric(true);
    } else if (mounted) {
      showMessage(context, 'Could not verify you, so biometric unlock stays off.');
    }
  }

  Future<void> _change(BuildContext context, _Secret kind) async {
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ChangeSecretSheet(kind: kind),
    );
    if (done == true && context.mounted) {
      showMessage(context, kind == _Secret.pin ? 'Transaction PIN updated' : 'Password updated');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlainScaffold(
      title: 'Security & PIN',
      child: ListenableBuilder(
        listenable: appSettings,
        builder: (context, _) => Column(
        children: [
          MenuGroup(
            label: 'APPEARANCE',
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Dark mode', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(appSettings.dark ? 'Dark' : 'Normal'),
                value: appSettings.dark,
                onChanged: appSettings.setDark,
              ),
            ],
          ),
          const SizedBox(height: 20),
          MenuGroup(
            label: 'APP LOCK',
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.fingerprint),
                title: const Text('Unlock with fingerprint or face', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('After 2 minutes without use the app locks. With this on you can unlock it with your fingerprint or face instead of logging in again.'),
                value: appSettings.biometric,
                onChanged: _toggleBiometric,
              ),
            ],
          ),
          const SizedBox(height: 20),
          MenuGroup(
            label: 'SIGN IN',
            children: [
              MenuTile(
                icon: Icons.lock_outline,
                title: 'Change password',
                subtitle: 'Use at least 8 characters',
                onTap: () => _change(context, _Secret.password),
              ),
            ],
          ),
          const SizedBox(height: 20),
          MenuGroup(
            label: 'PAYMENTS',
            children: [
              MenuTile(
                icon: Icons.pin_outlined,
                title: 'Change transaction PIN',
                subtitle: '4 digits',
                onTap: () => _change(context, _Secret.pin),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const InfoBanner(
            text: 'TrustPay will never ask for your password, PIN or verification code.',
          ),
        ],
      ),
      ),
    );
  }
}

class _ChangeSecretSheet extends StatefulWidget {
  const _ChangeSecretSheet({required this.kind});

  final _Secret kind;

  @override
  State<_ChangeSecretSheet> createState() => _ChangeSecretSheetState();
}

class _ChangeSecretSheetState extends State<_ChangeSecretSheet> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _error;

  bool get _isPin => widget.kind == _Secret.pin;
  int get _minLength => _isPin ? 4 : 8;
  String get _what => _isPin ? 'transaction PIN' : 'password';

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_isPin) {
        await api.changePin(_current.text, _next.text);
      } else {
        await api.changePassword(_current.text, _next.text);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = errorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = _what;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Change $w', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              TpField(
                label: 'Current $w',
                controller: _current,
                isPassword: true,
                digitsOnly: _isPin,
                maxLength: _isPin ? _minLength : null,
                keyboardType: _isPin ? TextInputType.number : null,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TpField(
                label: 'New $w',
                controller: _next,
                isPassword: true,
                digitsOnly: _isPin,
                maxLength: _isPin ? _minLength : null,
                keyboardType: _isPin ? TextInputType.number : null,
                validator: (v) => (v == null || v.length < _minLength)
                    ? 'Use at least $_minLength ${_isPin ? 'digits' : 'characters'}'
                    : null,
              ),
              const SizedBox(height: 14),
              TpField(
                label: 'Confirm new $w',
                controller: _confirm,
                isPassword: true,
                digitsOnly: _isPin,
                maxLength: _isPin ? _minLength : null,
                keyboardType: _isPin ? TextInputType.number : null,
                validator: (v) => v == _next.text ? null : 'Does not match',
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                _errorBanner(_error!),
              ],
              const SizedBox(height: 20),
              PrimaryButton(label: 'Save', loading: _saving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opened from the bell on every tab: your latest account activity.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlainScaffold(
      title: 'Notifications',
      child: ListenableBuilder(
        listenable: appState,
        builder: (context, _) => ApiBuilder<PagedList<Txn>>(
          load: () => api.transactions(limit: 20),
          reloadKey: appState.txnVersion,
          builder: (context, page, reload) {
            if (page.items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: Text('No notifications yet.', style: TextStyle(color: TpColors.muted)),
                ),
              );
            }
            return MenuGroup(
              children: [
                for (final t in page.items)
                  MenuTile(
                    icon: t.isCredit ? Icons.south_west : Icons.north_east,
                    title: t.isCredit ? 'Money in · ${t.title}' : t.title,
                    subtitle: '${formatLeone(t.signedAmount, showSign: true)} · ${t.status}\n'
                        '${formatShortDateTime(t.createdAt)}',
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
