import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/sample_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/nav.dart';
import '../../widgets/common.dart';
import '../../widgets/step_scaffold.dart';
import 'generic_flow.dart';

/// Groups card digits as `1234 5678 9012 3456`.
class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final capped = digits.length > 16 ? digits.substring(0, 16) : digits;
    final text = [
      for (var i = 0; i < capped.length; i += 4)
        capped.substring(i, i + 4 > capped.length ? capped.length : i + 4),
    ].join(' ');
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

/// Turns `1228` into `12/28`.
class ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final capped = digits.length > 4 ? digits.substring(0, 4) : digits;
    final text = capped.length > 2 ? '${capped.substring(0, 2)}/${capped.substring(2)}' : capped;
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

bool _luhn(String number) {
  var sum = 0;
  var alt = false;
  for (var i = number.length - 1; i >= 0; i--) {
    var d = int.parse(number[i]);
    if (alt) {
      d *= 2;
      if (d > 9) d -= 9;
    }
    sum += d;
    alt = !alt;
  }
  return sum % 10 == 0;
}

/// Add money by debit card.
class FundByCardScreen extends StatefulWidget {
  const FundByCardScreen({super.key});

  @override
  State<FundByCardScreen> createState() => _FundByCardScreenState();
}

class _FundByCardScreenState extends State<FundByCardScreen> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _number = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();

  /// Sample fee: 1.5% of the amount. Replace with your provider's fee.
  static const double _feeRate = 0.015;

  @override
  void dispose() {
    _amount.dispose();
    _number.dispose();
    _expiry.dispose();
    _cvv.dispose();
    super.dispose();
  }

  double get _value => parseAmount(_amount.text);
  double get _fee => double.parse((_value * _feeRate).toStringAsFixed(2));

  String? _checkExpiry(String? v) {
    final parts = (v ?? '').split('/');
    if (parts.length != 2 || parts[1].length != 2) return 'MM/YY';
    final month = int.tryParse(parts[0]) ?? 0;
    final year = 2000 + (int.tryParse(parts[1]) ?? 0);
    if (month < 1 || month > 12) return 'Invalid month';
    final now = DateTime.now();
    if (year < now.year || (year == now.year && month < now.month)) return 'Card expired';
    return null;
  }

  void _review() {
    if (!_form.currentState!.validate()) return;
    final amount = _value;
    final fee = _fee;
    final total = amount + fee;
    final digits = _number.text.replaceAll(' ', '');
    final last4 = digits.substring(digits.length - 4);

    openScreen(
      context,
      PayConfirmScreen(
        eyebrow: 'ADD MONEY · DEBIT CARD',
        counter: '02 / 03',
        title: 'Confirm card payment',
        bannerLabel: 'Charged to card •• $last4',
        total: total,
        referenceCode: 'FND',
        payLabel: 'Pay',
        pinLabel: 'Enter the 6-digit code from your bank',
        pinLength: 6,
        obscure: false,
        notice: 'Never share this code with anyone, including TrustPay staff.',
        rows: [
          ('Funding amount', formatNaira(amount)),
          ('Card fee', formatNaira(fee)),
          ('Card', '•• $last4'),
          ('Balance after', formatNaira(kAccountBalance + amount)),
        ],
        successBuilder: (reference) => PaySuccessScreen(
          eyebrow: 'ADD MONEY · DEBIT CARD',
          counter: '03 / 03',
          headline: '${formatNaira(amount)} added',
          detail: 'From your debit card •• $last4',
          notice: 'New balance ${formatNaira(kAccountBalance + amount)}',
          rows: [
            ('Amount', formatNaira(amount)),
            ('Card fee', formatNaira(fee)),
            ('Total charged', formatNaira(total)),
            ('Reference', reference),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: for real payments use your payment provider's card sheet instead of
    // collecting the card number in your own form.
    return StepScaffold(
      eyebrow: 'ADD MONEY · DEBIT CARD',
      counter: '01 / 03',
      title: 'Fund with a card',
      subtitle: 'Enter the amount and your debit card details.',
      headerLabel: 'Cancel',
      onHeaderAction: () => goHome(context),
      primaryLabel: 'Review payment',
      onPrimary: _review,
      secondaryLabel: 'Back',
      onSecondary: () => Navigator.maybePop(context),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TpField(
              label: 'Amount',
              controller: _amount,
              hint: '0.00',
              prefixText: '₦',
              allowDecimal: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final a = parseAmount(v ?? '');
                if (a < 100) return 'Minimum is ₦100';
                if (a > 500000) return 'Maximum is ₦500,000 per payment';
                return null;
              },
            ),
            const SizedBox(height: 8),
            AmountChips(
              amounts: const [1000, 5000, 10000, 20000],
              onPick: (a) => setState(() => _amount.text = a.toStringAsFixed(0)),
            ),
            const SizedBox(height: 16),
            TpField(
              label: 'Card number',
              controller: _number,
              hint: '0000 0000 0000 0000',
              keyboardType: TextInputType.number,
              formatters: [CardNumberFormatter()],
              validator: (v) {
                final d = (v ?? '').replaceAll(' ', '');
                if (d.length < 16) return 'Enter all 16 digits';
                return _luhn(d) ? null : 'Check the card number';
              },
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TpField(
                    label: 'Expiry',
                    controller: _expiry,
                    hint: 'MM/YY',
                    keyboardType: TextInputType.number,
                    formatters: [ExpiryFormatter()],
                    validator: _checkExpiry,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TpField(
                    label: 'CVV',
                    controller: _cvv,
                    hint: '123',
                    isPassword: true,
                    keyboardType: TextInputType.number,
                    digitsOnly: true,
                    maxLength: 3,
                    validator: (v) => (v == null || v.length != 3) ? '3 digits' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _value > 0
                  ? 'Card fee ${formatNaira(_fee)} · You pay ${formatNaira(_value + _fee)}'
                  : 'A small card fee applies.',
              style: const TextStyle(fontSize: 13, color: TpColors.muted),
            ),
            const SizedBox(height: 14),
            const InfoBanner(text: 'Only enter your card on screens you trust. TrustPay never asks for your PIN.'),
          ],
        ),
      ),
    );
  }
}

/// Move money from the main balance onto the virtual card.
class FundCardScreen extends StatefulWidget {
  const FundCardScreen({super.key});

  @override
  State<FundCardScreen> createState() => _FundCardScreenState();
}

class _FundCardScreenState extends State<FundCardScreen> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  double get _value => parseAmount(_amount.text);

  void _review() {
    final card = virtualCardNotifier.value;
    if (card == null || !_form.currentState!.validate()) return;
    final amount = _value;
    final newCard = card.balance + amount;

    openScreen(
      context,
      PayConfirmScreen(
        eyebrow: 'CARDS · FUND CARD',
        counter: '02 / 03',
        title: 'Confirm card funding',
        bannerLabel: 'Moves to card •• ${card.last4} · no fee',
        total: amount,
        referenceCode: 'CRD',
        payLabel: 'Fund',
        rows: [
          ('From', 'TrustPay account'),
          ('To', 'Virtual card •• ${card.last4}'),
          ('Amount', formatNaira(amount)),
          ('Account balance after', formatNaira(kAccountBalance - amount)),
          ('Card balance after', formatNaira(newCard)),
        ],
        onConfirmed: () => virtualCardNotifier.value = card.copyWith(balance: newCard),
        successBuilder: (reference) => PaySuccessScreen(
          eyebrow: 'CARDS · FUND CARD',
          counter: '03 / 03',
          headline: '${formatNaira(amount)} added to card',
          detail: 'Virtual card •• ${card.last4}',
          notice: 'Card balance ${formatNaira(newCard)}',
          rows: [
            ('Amount', formatNaira(amount)),
            ('Card balance', formatNaira(newCard)),
            ('Account balance', formatNaira(kAccountBalance - amount)),
            ('Reference', reference),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = virtualCardNotifier.value;
    return StepScaffold(
      eyebrow: 'CARDS · FUND CARD',
      counter: '01 / 03',
      title: 'Fund your card',
      subtitle: card == null ? 'Create a virtual card first.' : 'Virtual card •• ${card.last4} · Balance ${formatNaira(card.balance)}',
      headerLabel: 'Cancel',
      onHeaderAction: () => goHome(context),
      primaryLabel: 'Review funding',
      onPrimary: card == null ? null : _review,
      secondaryLabel: 'Back',
      onSecondary: () => Navigator.maybePop(context),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TpField(
              label: 'Amount to add',
              controller: _amount,
              hint: '0.00',
              prefixText: '₦',
              allowDecimal: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final a = parseAmount(v ?? '');
                if (a < 100) return 'Minimum is ₦100';
                if (a > kAccountBalance) return 'Insufficient balance';
                return null;
              },
            ),
            const SizedBox(height: 8),
            AmountChips(
              amounts: const [1000, 5000, 10000, 20000],
              onPick: (a) => setState(() => _amount.text = a.toStringAsFixed(0)),
            ),
            const SizedBox(height: 14),
            Text(balanceLine(), style: const TextStyle(fontSize: 13, color: TpColors.muted)),
          ],
        ),
      ),
    );
  }
}
