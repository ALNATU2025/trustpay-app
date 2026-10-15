import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api.dart';
import '../../services/app_state.dart';
import '../../services/trustpay_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/debounce.dart';
import '../../utils/format.dart';
import '../../utils/nav.dart';
import '../../widgets/common.dart';
import '../../widgets/menu_widgets.dart';
import '../../widgets/step_scaffold.dart';
import 'generic_flow.dart';
import 'mobile_money_screens.dart';
import 'transfer_screens.dart';

/// Bottom sheet that asks where the money is going.
void showSendOptions(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 6, bottom: 12),
              child: Text('Send money', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            ),
            MenuTile(
              icon: Icons.person_outline,
              title: 'To a TrustPay user',
              subtitle: 'Free and instant',
              onTap: () {
                Navigator.pop(sheetContext);
                openScreen(context, const SendToUserScreen());
              },
            ),
            MenuTile(
              icon: Icons.phone_android_outlined,
              title: 'To mobile money',
              subtitle: appState.cat.mobileMoney.join(', '),
              onTap: () {
                Navigator.pop(sheetContext);
                openScreen(context, const MobileMoneyScreen(send: true));
              },
            ),
            MenuTile(
              icon: Icons.account_balance_outlined,
              title: 'To a bank account',
              subtitle: 'Any Sierra Leone bank',
              onTap: () {
                Navigator.pop(sheetContext);
                openScreen(context, const SendBankScreen());
              },
            ),
          ],
        ),
      ),
    ),
  );
}

/// Send to another TrustPay customer by account number or phone. No fee.
class SendToUserScreen extends StatefulWidget {
  const SendToUserScreen({super.key});

  @override
  State<SendToUserScreen> createState() => _SendToUserScreenState();
}

class _SendToUserScreenState extends State<SendToUserScreen> {
  final _form = GlobalKey<FormState>();
  final _to = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _debounce = Debouncer();
  TrustPayUser? _user;
  bool _verifying = false;
  bool _notFound = false;
  String? _lookupError;
  int _lookupId = 0;

  @override
  void dispose() {
    _debounce.dispose();
    _to.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  /// A 10-digit number is an account number; 8, 9, 11 or 12 digits is a phone number.
  bool _isAccount(String d) => d.length == 10;
  bool _isPhone(String d) => d.length == 8 || d.length == 9 || d.length == 11 || d.length == 12;

  bool _isOwn(String d) {
    final me = appState.me;
    return d == me.accountNumber || (_isPhone(d) && samePhone(d, me.phone));
  }

  void _onChanged() {
    _lookupId++;
    _debounce.cancel();
    final d = _to.text;
    final ready = (_isAccount(d) || _isPhone(d)) && !_isOwn(d);
    setState(() {
      _user = null;
      _notFound = false;
      _lookupError = null;
      _verifying = ready;
    });
    if (ready) _debounce.run(_lookup);
  }

  Future<void> _lookup() async {
    final d = _to.text;
    final id = ++_lookupId;
    try {
      final user = _isAccount(d) ? await api.lookupUser(accountNumber: d) : await api.lookupUser(phone: d);
      if (!mounted || id != _lookupId) return;
      setState(() {
        _user = user;
        _notFound = user == null;
        _verifying = false;
      });
    } on ApiException catch (e) {
      if (!mounted || id != _lookupId) return;
      setState(() {
        _verifying = false;
        _lookupError = e.message;
      });
    }
  }

  void _review() {
    if (!_form.currentState!.validate()) return;
    final user = _user;
    if (user == null) {
      showMessage(context, 'Enter a valid TrustPay account number or phone first.');
      return;
    }
    if (user.accountNumber == appState.me.accountNumber) {
      showMessage(context, 'That is your own account.');
      return;
    }
    final amount = parseAmount(_amount.text);
    final note = _note.text.trim();
    final name = user.fullName;

    openScreen(
      context,
      PayConfirmScreen(
        eyebrow: 'SEND MONEY · TRUSTPAY USER',
        counter: '02 / 03',
        title: 'Confirm transfer',
        bannerLabel: 'Sending to $name · no fee',
        total: amount,
        payLabel: 'Send',
        notice: 'Only send to people you know. Transfers between TrustPay users cannot be reversed.',
        rows: [
          ('To', name),
          ('TrustPay number', user.accountNumber),
          ('Amount', formatLeone(amount)),
          if (note.isNotEmpty) ('Note', note),
          ('Balance after', formatLeone(appState.balance - amount)),
        ],
        onPay: (pin, key) => api.transferUser(
          accountNumber: user.accountNumber,
          amount: amount,
          note: note,
          pin: pin,
          idempotencyKey: key,
        ),
        successBuilder: (result) {
          final txn = result.transaction;
          final pending = isPending(txn);
          return PaySuccessScreen(
            eyebrow: 'SEND MONEY · TRUSTPAY USER',
            counter: '03 / 03',
            headline: pending ? '${formatLeone(amount)} is being processed' : '${formatLeone(amount)} sent',
            detail: 'To $name',
            notice: 'Balance ${formatLeone(result.balance)}',
            rows: receiptRows(txn),
            onPrimary: () => copyReceipt(context, txn),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      eyebrow: 'SEND MONEY · TRUSTPAY USER',
      counter: '01 / 03',
      title: 'Send to a TrustPay user',
      subtitle: 'Free and instant between TrustPay accounts.',
      headerLabel: 'Cancel',
      onHeaderAction: () => goHome(context),
      primaryLabel: 'Review transfer',
      onPrimary: _review,
      secondaryLabel: 'Back',
      onSecondary: () => Navigator.maybePop(context),
      child: ListenableBuilder(
        listenable: appState,
        builder: (context, _) => Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TpField(
                label: 'Account number or phone',
                controller: _to,
                hint: '10-digit account number or phone',
                keyboardType: TextInputType.number,
                digitsOnly: true,
                maxLength: 12,
                onChanged: (_) => _onChanged(),
                validator: (v) {
                  final d = v ?? '';
                  if (!_isAccount(d) && !_isPhone(d)) return 'Enter a 10-digit account number or a phone number';
                  if (_isOwn(d)) return 'That is your own account';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              if (_user != null)
                InfoBanner(
                  icon: Icons.check_circle_outline,
                  background: TpColors.greenTint,
                  accent: TpColors.green,
                  textColor: TpColors.green,
                  text: 'TrustPay user found · ${_user!.fullName}',
                )
              else if (_verifying)
                const Text('Looking up…', style: TextStyle(fontSize: 13, color: TpColors.muted))
              else if (_notFound)
                const Text(
                  'No TrustPay account found for this number.',
                  style: TextStyle(fontSize: 13, color: TpColors.danger),
                )
              else if (_lookupError != null)
                Text(_lookupError!, style: const TextStyle(fontSize: 13, color: TpColors.danger)),
              const SizedBox(height: 16),
              TpField(
                label: 'Amount',
                controller: _amount,
                hint: '0.00',
                prefixText: 'Le ',
                allowDecimal: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final a = parseAmount(v ?? '');
                  if (a <= 0) return 'Enter an amount';
                  if (a > appState.balance) return 'Insufficient balance';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              AmountChips(
                amounts: const [100, 500, 1000, 2000],
                onPick: (a) => setState(() => _amount.text = a.toStringAsFixed(0)),
              ),
              const SizedBox(height: 16),
              TpField(label: 'Note (optional)', controller: _note, hint: 'What is it for?', maxLength: 60),
              const SizedBox(height: 6),
              Text(balanceLine(), style: const TextStyle(fontSize: 13, color: TpColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}
