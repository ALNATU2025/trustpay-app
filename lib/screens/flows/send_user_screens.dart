import 'package:flutter/material.dart';

import '../../data/sample_data.dart';
import '../../theme/app_theme.dart';
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
              subtitle: 'Orange Money, Afrimoney, Qmoney',
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

/// Send to another TrustPay customer by phone or account number. No fee.
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
  String? _name;
  bool _verifying = false;
  int _lookupId = 0;

  @override
  void dispose() {
    _to.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  /// Sample lookup. Replace with your "find a TrustPay user" API.
  Future<void> _lookup() async {
    setState(() => _name = null);
    final digits = _to.text;
    if (digits.length < 10) {
      setState(() => _verifying = false);
      return;
    }
    final id = ++_lookupId;
    setState(() => _verifying = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted || id != _lookupId) return;
    setState(() {
      _name = 'Mohamed Sesay';
      _verifying = false;
    });
  }

  void _review() {
    if (!_form.currentState!.validate()) return;
    final name = _name;
    if (name == null) {
      showMessage(context, 'Enter a valid TrustPay number first.');
      return;
    }
    final amount = parseAmount(_amount.text);
    final note = _note.text.trim();
    final to = _to.text;

    openScreen(
      context,
      PayConfirmScreen(
        eyebrow: 'SEND MONEY · TRUSTPAY USER',
        counter: '02 / 03',
        title: 'Confirm transfer',
        bannerLabel: 'Sending to $name · no fee',
        total: amount,
        referenceCode: 'TPU',
        payLabel: 'Send',
        notice: 'Only send to people you know. Transfers between TrustPay users cannot be reversed.',
        rows: [
          ('To', name),
          ('TrustPay number', to),
          ('Amount', formatLeone(amount)),
          if (note.isNotEmpty) ('Note', note),
          ('Balance after', formatLeone(kAccountBalance - amount)),
        ],
        successBuilder: (reference) => PaySuccessScreen(
          eyebrow: 'SEND MONEY · TRUSTPAY USER',
          counter: '03 / 03',
          headline: '${formatLeone(amount)} sent',
          detail: 'To $name',
          notice: 'Balance ${formatLeone(kAccountBalance - amount)}',
          rows: [
            ('To', name),
            ('Amount', formatLeone(amount)),
            ('Fee', formatLeone(0)),
            ('Reference', reference),
          ],
        ),
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
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TpField(
              label: 'Phone or account number',
              controller: _to,
              hint: '10 or 11 digits',
              keyboardType: TextInputType.number,
              digitsOnly: true,
              maxLength: 11,
              onChanged: (_) => _lookup(),
              validator: (v) {
                if (v == null || v.length < 10) return 'Enter at least 10 digits';
                if (v == kAccountNumber) return 'That is your own account';
                return null;
              },
            ),
            const SizedBox(height: 10),
            if (_name != null)
              InfoBanner(
                icon: Icons.check_circle_outline,
                background: TpColors.greenTint,
                accent: TpColors.green,
                textColor: TpColors.green,
                text: 'TrustPay user found · $_name',
              )
            else if (_verifying)
              const Text('Looking up…', style: TextStyle(fontSize: 13, color: TpColors.muted)),
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
                if (a > kAccountBalance) return 'Insufficient balance';
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
    );
  }
}
