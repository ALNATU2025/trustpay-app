import 'package:flutter/material.dart';

import '../../data/sample_data.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/nav.dart';
import '../../widgets/common.dart';
import '../../widgets/flow_widgets.dart';
import '../../widgets/step_scaffold.dart';
import 'generic_flow.dart';

/// Mobile money in Sierra Leone: Orange Money, Afrimoney and Qmoney.
/// [send] false adds money from a wallet to your TrustPay account; true sends
/// money from your account to someone's wallet.
class MobileMoneyScreen extends StatefulWidget {
  const MobileMoneyScreen({super.key, required this.send});

  final bool send;

  @override
  State<MobileMoneyScreen> createState() => _MobileMoneyScreenState();
}

class _MobileMoneyScreenState extends State<MobileMoneyScreen> {
  final _form = GlobalKey<FormState>();
  final _number = TextEditingController(text: kPhone);
  final _amount = TextEditingController();
  String _wallet = kMobileMoney.first;
  String? _holder;
  bool _verifying = false;
  int _lookupId = 0;

  @override
  void initState() {
    super.initState();
    if (widget.send) _number.clear();
  }

  @override
  void dispose() {
    _number.dispose();
    _amount.dispose();
    super.dispose();
  }

  String get _eyebrow => widget.send ? 'SEND MONEY · MOBILE MONEY' : 'ADD MONEY · MOBILE MONEY';

  double get _value => parseAmount(_amount.text);

  /// Sample wallet name lookup. Replace with your mobile money partner's API.
  Future<void> _lookup() async {
    setState(() => _holder = null);
    final digits = _number.text.replaceAll(' ', '');
    if (digits.length != 9) {
      setState(() => _verifying = false);
      return;
    }
    final id = ++_lookupId;
    setState(() => _verifying = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted || id != _lookupId) return;
    setState(() {
      _holder = widget.send ? 'Mohamed Sesay' : kAccountName;
      _verifying = false;
    });
  }

  void _review() {
    if (!_form.currentState!.validate()) return;
    final holder = _holder;
    if (holder == null) {
      showMessage(context, 'Enter a valid $_wallet number first.');
      return;
    }
    final amount = _value;
    final number = _number.text.trim();
    final wallet = _wallet;
    final send = widget.send;
    final after = send ? kAccountBalance - amount : kAccountBalance + amount;

    openScreen(
      context,
      PayConfirmScreen(
        eyebrow: _eyebrow,
        counter: '02 / 03',
        title: send ? 'Confirm transfer' : 'Confirm wallet payment',
        bannerLabel: send ? 'Sending to $wallet · $holder' : 'Paid from your $wallet',
        total: amount,
        referenceCode: send ? 'MMS' : 'MMA',
        payLabel: send ? 'Send' : 'Add',
        pinLabel: send ? 'Authorize with transaction PIN' : 'Enter the approval code sent to your phone',
        pinLength: send ? 4 : 6,
        obscure: send,
        notice: send
            ? 'Check the wallet number. Mobile money transfers cannot be reversed.'
            : 'You may also get a prompt on your phone to approve the payment.',
        rows: [
          ('Wallet', wallet),
          (send ? 'To' : 'Wallet holder', holder),
          ('Wallet number', number),
          ('Amount', formatLeone(amount)),
          ('Fee', formatLeone(0)),
          ('Balance after', formatLeone(after)),
        ],
        successBuilder: (reference) => PaySuccessScreen(
          eyebrow: _eyebrow,
          counter: '03 / 03',
          headline: send ? '${formatLeone(amount)} sent' : '${formatLeone(amount)} added',
          detail: send ? 'To $holder · $wallet' : 'From your $wallet',
          notice: 'Balance ${formatLeone(after)}',
          rows: [
            ('Wallet', wallet),
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
    final send = widget.send;
    return StepScaffold(
      eyebrow: _eyebrow,
      counter: '01 / 03',
      title: send ? 'Send to mobile money' : 'Add from mobile money',
      subtitle: send
          ? 'Send to an Orange Money, Afrimoney or Qmoney wallet.'
          : 'Pay from your wallet into your TrustPay account.',
      headerLabel: 'Cancel',
      onHeaderAction: () => goHome(context),
      primaryLabel: 'Review',
      onPrimary: _review,
      secondaryLabel: 'Back',
      onSecondary: () => Navigator.maybePop(context),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mobile money provider', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(
              children: [
                for (var i = 0; i < kMobileMoney.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceBox(
                      label: kMobileMoney[i],
                      selected: kMobileMoney[i] == _wallet,
                      onTap: () => setState(() => _wallet = kMobileMoney[i]),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 18),
            TpField(
              label: send ? 'Recipient wallet number' : 'Your wallet number',
              controller: _number,
              hint: '076 123 456',
              keyboardType: TextInputType.phone,
              onChanged: (_) => _lookup(),
              validator: (v) {
                final d = (v ?? '').replaceAll(' ', '');
                if (d.length != 9) return 'Enter a 9-digit number, like 076 123 456';
                if (send && d == kPhone.replaceAll(' ', '')) return 'That is your own number';
                return null;
              },
            ),
            const SizedBox(height: 10),
            if (_holder != null)
              InfoBanner(
                icon: Icons.check_circle_outline,
                background: TpColors.greenTint,
                accent: TpColors.green,
                textColor: TpColors.green,
                text: '$_wallet found · $_holder',
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
                if (a < 5) return 'Minimum is Le 5';
                if (send && a > kAccountBalance) return 'Insufficient balance';
                return null;
              },
            ),
            const SizedBox(height: 8),
            AmountChips(
              amounts: const [100, 500, 1000, 2000],
              onPick: (a) => setState(() => _amount.text = a.toStringAsFixed(0)),
            ),
            const SizedBox(height: 14),
            Text(
              send ? balanceLine() : 'No TrustPay fee · Your wallet provider may charge its own fee.',
              style: const TextStyle(fontSize: 13, color: TpColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
