import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api.dart';
import '../../services/app_state.dart';
import '../../services/trustpay_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/debounce.dart';
import '../../utils/nav.dart';
import '../../widgets/common.dart';
import '../../widgets/flow_widgets.dart';
import '../../widgets/step_scaffold.dart';

/// Card on the POS dashboard showing the merchant's linked bank account (the account a POS terminal
/// settles to) with a shortcut to link or change it.
class SettlementAccountCard extends StatelessWidget {
  const SettlementAccountCard({super.key, required this.account, required this.merchantCode, required this.onChanged});

  final Map<String, dynamic>? account;
  final String merchantCode;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final a = account;
    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.account_balance_outlined, color: TpColors.primary),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Settlement account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
            if (merchantCode.isNotEmpty)
              Text('Code $merchantCode', style: const TextStyle(fontSize: 12.5, color: TpColors.muted, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          if (a == null)
            const Text(
              'Link your bank account so your daily POS sales are paid straight to your bank. Until then they go to your TrustPay wallet.',
              style: TextStyle(fontSize: 14, height: 1.4, color: TpColors.muted),
            )
          else ...[
            Text(asStr(a['accountName']), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            Text('${asStr(a['bank'])} · ${asStr(a['accountNumber'])}', style: const TextStyle(fontSize: 13.5, color: TpColors.muted)),
            const SizedBox(height: 6),
            Text(
              a['payToBank'] == true ? 'Daily settlement is paid to this bank account.' : 'Daily settlement stays in your TrustPay wallet.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: a['payToBank'] == true ? TpColors.green : TpColors.muted),
            ),
          ],
          const SizedBox(height: 12),
          SecondaryButton(
            label: a == null ? 'Link bank account' : 'Manage bank account',
            onPressed: () async {
              await openScreen(context, SettlementAccountScreen(current: a));
              onChanged();
            },
          ),
        ],
      ),
    );
  }
}

/// Link a bank account (verified with the bank) and choose where the daily settlement goes.
class SettlementAccountScreen extends StatefulWidget {
  const SettlementAccountScreen({super.key, this.current});

  final Map<String, dynamic>? current;

  @override
  State<SettlementAccountScreen> createState() => _SettlementAccountScreenState();
}

class _SettlementAccountScreenState extends State<SettlementAccountScreen> {
  final _form = GlobalKey<FormState>();
  final _account = TextEditingController();
  final _pin = TextEditingController();
  final _debounce = Debouncer();
  late String _bank;
  String? _verifiedName;
  bool _verifying = false;
  bool _notFound = false;
  bool _payToBank = true;
  bool _busy = false;
  String? _error;
  int _lookupId = 0;

  @override
  void initState() {
    super.initState();
    final banks = appState.cat.banks;
    final cur = widget.current;
    _bank = cur != null && banks.contains(asStr(cur['bank'])) ? asStr(cur['bank']) : (banks.isEmpty ? '' : banks.first);
    _payToBank = cur == null ? true : cur['payToBank'] == true;
  }

  @override
  void dispose() {
    _debounce.dispose();
    _account.dispose();
    _pin.dispose();
    super.dispose();
  }

  void _startLookup() {
    _lookupId++;
    _debounce.cancel();
    final ready = _account.text.length >= 6 && _bank.isNotEmpty;
    setState(() {
      _verifiedName = null;
      _notFound = false;
      _verifying = ready;
    });
    if (ready) _debounce.run(_verify);
  }

  Future<void> _verify() async {
    final id = ++_lookupId;
    try {
      final name = await api.lookupBankAccount(_bank, _account.text);
      if (!mounted || id != _lookupId) return;
      final found = (name == null || name.isEmpty) ? null : name;
      setState(() {
        _verifiedName = found;
        _notFound = found == null;
        _verifying = false;
      });
    } on ApiException catch (e) {
      if (!mounted || id != _lookupId) return;
      setState(() {
        _verifying = false;
        _error = e.message;
      });
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _busy) return;
    if (_verifiedName == null) {
      showMessage(context, 'We could not verify this account yet.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await api.linkSettlementAccount(bank: _bank, accountNumber: _account.text, payToBank: _payToBank, pin: _pin.text);
      if (!mounted) return;
      showMessage(context, 'Bank account linked');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unlink() async {
    final pin = await showDialog<String>(
      context: context,
      builder: (d) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('Unlink bank account?'),
          content: TextField(
            controller: c,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: const InputDecoration(labelText: 'Transaction PIN'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(d, c.text), child: const Text('Unlink')),
          ],
        );
      },
    );
    if (pin == null || pin.length != 4 || !mounted) return;
    try {
      await api.unlinkSettlementAccount(pin);
      if (!mounted) return;
      showMessage(context, 'Bank account unlinked. Settlements now go to your wallet.');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cur = widget.current;
    return StepScaffold(
      eyebrow: 'POS · BANK ACCOUNT',
      title: cur == null ? 'Link your bank account' : 'Change bank account',
      subtitle: 'Your POS sales are settled here. We check the account name with the bank.',
      primaryLabel: 'Save bank account',
      primaryLoading: _busy,
      onPrimary: _busy ? null : _save,
      secondaryLabel: cur != null ? 'Unlink account' : 'Back',
      onSecondary: cur != null ? _unlink : () => Navigator.maybePop(context),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cur != null) ...[
              InfoBanner(text: 'Linked now: ${asStr(cur['bank'])} ${asStr(cur['accountNumber'])} · ${asStr(cur['accountName'])}'),
              const SizedBox(height: 16),
            ],
            TpDropdown(
              label: 'Bank',
              value: _bank,
              items: appState.cat.banks,
              onChanged: (v) {
                setState(() => _bank = v);
                _startLookup();
              },
            ),
            const SizedBox(height: 16),
            TpField(
              label: 'Account number',
              controller: _account,
              hint: 'Account number (up to 18 digits)',
              keyboardType: TextInputType.number,
              digitsOnly: true,
              maxLength: 18,
              onChanged: (_) => _startLookup(),
              validator: (v) => (v == null || v.length < 6) ? 'Enter a valid account number (6 to 18 digits)' : null,
            ),
            const SizedBox(height: 10),
            if (_verifiedName != null)
              InfoBanner(
                icon: Icons.check_circle_outline,
                background: TpColors.greenTint,
                accent: TpColors.green,
                textColor: TpColors.green,
                text: 'Account verified · $_verifiedName',
              )
            else if (_verifying)
              const Text('Verifying account…', style: TextStyle(fontSize: 13, color: TpColors.muted))
            else if (_notFound)
              const Text('Account not found. Check the bank and the number.', style: TextStyle(fontSize: 13, color: TpColors.danger)),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pay my daily settlement to this bank account', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Off: the money stays in your TrustPay wallet.'),
              value: _payToBank,
              onChanged: (v) => setState(() => _payToBank = v),
            ),
            const SizedBox(height: 8),
            TpField(
              label: 'Transaction PIN',
              controller: _pin,
              isPassword: true,
              keyboardType: TextInputType.number,
              digitsOnly: true,
              maxLength: 4,
              validator: (v) => (v == null || v.length != 4) ? 'Enter your 4-digit PIN' : null,
            ),
            if (_error != null) ...[const SizedBox(height: 12), ErrorBanner(_error!)],
            const SizedBox(height: 12),
            const InfoBanner(text: 'A normal bank transfer fee applies to each bank settlement.'),
          ],
        ),
      ),
    );
  }
}
