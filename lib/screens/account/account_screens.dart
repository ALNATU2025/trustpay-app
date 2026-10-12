import 'package:flutter/material.dart';

import '../../data/sample_data.dart';
import '../../theme/app_theme.dart';
import '../../utils/nav.dart';
import '../../widgets/common.dart';
import '../../widgets/flow_widgets.dart';
import '../../widgets/menu_widgets.dart';
import '../support/support_screen.dart';

/// Read-only personal details. Changes go through support.
class PersonalDetailsScreen extends StatelessWidget {
  const PersonalDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlainScaffold(
      title: 'Personal details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: Avatar(name: kAccountName, size: 84)),
          const SizedBox(height: 12),
          const Center(
            child: Text(kAccountName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(kTier, style: TextStyle(fontSize: 14, color: TpColors.green)),
          ),
          const SizedBox(height: 20),
          const DetailsCard(
            rows: [
              ('Full name', kAccountName),
              ('Phone number', kPhone),
              ('Email', kEmail),
              ('Account number', kAccountNumber),
              ('Business', kBusinessName),
              ('Identity check', 'Verified'),
            ],
          ),
          const SizedBox(height: 16),
          const InfoBanner(
            text: 'Details come from your identity document, so they cannot be edited here.',
          ),
          const SizedBox(height: 16),
          SecondaryButton(
            label: 'Ask support to change my details',
            onPressed: () => openScreen(context, const SupportScreen()),
          ),
        ],
      ),
    );
  }
}

/// Security switches and password / PIN changes.
class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _faceId = true;
  bool _pinForTransfers = true;
  bool _alerts = true;

  Widget _switch(bool value, ValueChanged<bool> onChanged) =>
      Switch(value: value, activeColor: TpColors.primary, onChanged: onChanged);

  Future<void> _change(String what, {required int minLength, bool digitsOnly = false}) async {
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ChangeSecretSheet(what: what, minLength: minLength, digitsOnly: digitsOnly),
    );
    if (done == true && mounted) showMessage(context, '$what updated');
  }

  @override
  Widget build(BuildContext context) {
    return PlainScaffold(
      title: 'Security & PIN',
      child: Column(
        children: [
          MenuGroup(
            label: 'SIGN IN',
            children: [
              MenuTile(
                icon: Icons.lock_outline,
                title: 'Change password',
                subtitle: 'Use at least 8 characters',
                onTap: () => _change('Password', minLength: 8),
              ),
              MenuTile(
                icon: Icons.face_outlined,
                title: 'Face ID / fingerprint',
                subtitle: 'Sign in faster on this device',
                trailing: _switch(_faceId, (v) => setState(() => _faceId = v)),
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
                onTap: () => _change('Transaction PIN', minLength: 4, digitsOnly: true),
              ),
              MenuTile(
                icon: Icons.verified_user_outlined,
                title: 'Ask for PIN on transfers',
                trailing: _switch(_pinForTransfers, (v) => setState(() => _pinForTransfers = v)),
              ),
              MenuTile(
                icon: Icons.notifications_active_outlined,
                title: 'Login and payment alerts',
                trailing: _switch(_alerts, (v) => setState(() => _alerts = v)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const InfoBanner(
            text: 'TrustPay will never ask for your password, PIN or verification code.',
          ),
        ],
      ),
    );
  }
}

class _ChangeSecretSheet extends StatefulWidget {
  const _ChangeSecretSheet({required this.what, required this.minLength, required this.digitsOnly});

  final String what;
  final int minLength;
  final bool digitsOnly;

  @override
  State<_ChangeSecretSheet> createState() => _ChangeSecretSheetState();
}

class _ChangeSecretSheetState extends State<_ChangeSecretSheet> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    // TODO: send the change to your API.
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.what.toLowerCase();
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _form,
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
              digitsOnly: widget.digitsOnly,
              maxLength: widget.digitsOnly ? widget.minLength : null,
              keyboardType: widget.digitsOnly ? TextInputType.number : null,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            TpField(
              label: 'New $w',
              controller: _next,
              isPassword: true,
              digitsOnly: widget.digitsOnly,
              maxLength: widget.digitsOnly ? widget.minLength : null,
              keyboardType: widget.digitsOnly ? TextInputType.number : null,
              validator: (v) => (v == null || v.length < widget.minLength)
                  ? 'Use at least ${widget.minLength} ${widget.digitsOnly ? 'digits' : 'characters'}'
                  : null,
            ),
            const SizedBox(height: 14),
            TpField(
              label: 'Confirm new $w',
              controller: _confirm,
              isPassword: true,
              digitsOnly: widget.digitsOnly,
              maxLength: widget.digitsOnly ? widget.minLength : null,
              keyboardType: widget.digitsOnly ? TextInputType.number : null,
              validator: (v) => v == _next.text ? null : 'Does not match',
            ),
            const SizedBox(height: 20),
            PrimaryButton(label: 'Save', onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class _Note {
  _Note(this.icon, this.title, this.body, this.time, {this.unread = false});

  final IconData icon;
  final String title;
  final String body;
  final String time;
  bool unread;
}

/// Opened from the bell on every tab.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Sample notifications. Replace with data from your API.
  final _items = [
    _Note(Icons.south_west, 'Money received', '₦25,000 from Chidi Okafor.', '10:24', unread: true),
    _Note(Icons.flash_on_outlined, 'Bill paid', 'Ikeja Electric payment of ₦12,500 was successful.', '09:18', unread: true),
    _Note(Icons.verified_user_outlined, 'New login', 'Your account was opened on a new device.', 'Yesterday'),
    _Note(Icons.credit_card_outlined, 'Virtual card ready', 'Your virtual card is ready to use online.', 'Mon'),
  ];

  @override
  Widget build(BuildContext context) {
    final anyUnread = _items.any((n) => n.unread);
    return PlainScaffold(
      title: 'Notifications',
      trailing: TextButton(
        onPressed: anyUnread ? () => setState(() => _items.forEach((n) => n.unread = false)) : null,
        child: const Text('Mark all read', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      child: MenuGroup(
        children: [
          for (final n in _items)
            MenuTile(
              icon: n.icon,
              title: n.title,
              subtitle: '${n.body}\n${n.time}',
              trailing: n.unread
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(color: TpColors.primary, shape: BoxShape.circle),
                    )
                  : const SizedBox.shrink(),
              onTap: () => setState(() => n.unread = false),
            ),
        ],
      ),
    );
  }
}
