import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/models.dart';
import '../../services/api.dart';
import '../../services/app_state.dart';
import '../../services/trustpay_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/nav.dart';
import '../../widgets/api_builder.dart';
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

/// Guesses the card brand from the first digits. Only the brand and last 4 digits ever leave the app.
String cardBrandOf(String digits) {
  if (digits.startsWith('4')) return 'Visa';
  final two = digits.length >= 2 ? int.tryParse(digits.substring(0, 2)) : null;
  final four = digits.length >= 4 ? int.tryParse(digits.substring(0, 4)) : null;
  if ((two != null && two >= 51 && two <= 55) || (four != null && four >= 2221 && four <= 2720)) {
    return 'Mastercard';
  }
  return 'Card';
}

/// Add money by debit card.
///
/// The card number, expiry and CVV are collected here for the form only. The app sends just the
/// last 4 digits and the brand to the server, and clears the fields as soon as they are read.
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

  @override
  void dispose() {
    _clearCard();
    _amount.dispose();
    _number.dispose();
    _expiry.dispose();
    _cvv.dispose();
    super.dispose();
  }

  void _clearCard() {
    _number.clear();
    _expiry.clear();
    _cvv.clear();
  }

  double get _value => parseAmount(_amount.text);
  double get _fee => appState.cat.fees.cardFundingFee(_value);

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
    final brand = cardBrandOf(digits);
    // Keep only what the server needs. The full number, expiry and CVV are wiped now.
    setState(_clearCard);

    openScreen(
      context,
      PayConfirmScreen(
        eyebrow: 'ADD MONEY · DEBIT CARD',
        counter: '02 / 03',
        title: 'Confirm card payment',
        bannerLabel: 'Charged to $brand •• $last4',
        total: total,
        payLabel: 'Pay',
        notice: 'Never share your PIN or card codes with anyone, including TrustPay staff. '
            'You will need to enter your card again if you go back.',
        rows: [
          ('Funding amount', formatLeone(amount)),
          ('Card fee', formatLeone(fee)),
          ('Total charged to card', formatLeone(total)),
          ('Card', '$brand •• $last4'),
          ('Balance after', formatLeone(appState.balance + amount)),
        ],
        onPay: (pin, key) async {
          await api.verifyPin(pin);
          return api.fundByCard(amount: amount, cardLast4: last4, brand: brand, idempotencyKey: key);
        },
        successBuilder: (result) {
          final txn = result.transaction;
          final pending = isPending(txn);
          return PaySuccessScreen(
            eyebrow: 'ADD MONEY · DEBIT CARD',
            counter: '03 / 03',
            headline: pending ? '${formatLeone(amount)} is being processed' : '${formatLeone(amount)} added',
            detail: 'From your $brand card •• $last4',
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
              prefixText: 'Le ',
              allowDecimal: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final a = parseAmount(v ?? '');
                if (a < 5) return 'Minimum is Le 5';
                return null;
              },
            ),
            const SizedBox(height: 8),
            AmountChips(
              amounts: const [100, 500, 1000, 2000],
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
                  ? 'Card fee ${formatLeone(_fee)} · You pay ${formatLeone(_value + _fee)}'
                  : 'A small card fee applies.',
              style: const TextStyle(fontSize: 13, color: TpColors.muted),
            ),
            const SizedBox(height: 14),
            const InfoBanner(
              text: 'TrustPay keeps only the last 4 digits and the brand of your card. '
                  'Your full number, expiry and CVV are never stored or sent.',
            ),
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
  CardInfo? _card;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await api.cards();
      if (!mounted) return;
      setState(() {
        _card = data.virtual;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = errorMessage(e);
        _loading = false;
      });
    }
  }

  double get _value => parseAmount(_amount.text);

  void _review() {
    final card = _card;
    if (card == null || !_form.currentState!.validate()) return;
    final amount = _value;

    openScreen(
      context,
      PayConfirmScreen(
        eyebrow: 'CARDS · FUND CARD',
        counter: '02 / 03',
        title: 'Confirm card funding',
        bannerLabel: 'Moves to card •• ${card.last4}',
        total: amount,
        payLabel: 'Fund',
        rows: [
          ('From', 'TrustPay account'),
          ('To', 'Virtual card •• ${card.last4}'),
          ('Amount', formatLeone(amount)),
          ('Account balance after', formatLeone(appState.balance - amount)),
          ('Card balance after', formatLeone(card.balance + amount)),
        ],
        onPay: (pin, key) => api.fundVirtualCard(amount: amount, pin: pin, idempotencyKey: key),
        successBuilder: (result) {
          final txn = result.transaction;
          final pending = isPending(txn);
          final newCard = result.card;
          return PaySuccessScreen(
            eyebrow: 'CARDS · FUND CARD',
            counter: '03 / 03',
            headline: pending ? '${formatLeone(amount)} is being processed' : '${formatLeone(amount)} added to card',
            detail: 'Virtual card •• ${card.last4}',
            notice: newCard != null
                ? 'Card balance ${formatLeone(newCard.balance)}'
                : 'Account balance ${formatLeone(result.balance)}',
            rows: receiptRows(txn),
            onPrimary: () => copyReceipt(context, txn),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = _card;
    final String subtitle;
    if (_loading) {
      subtitle = 'Loading your card…';
    } else if (card == null) {
      subtitle = _error ?? 'Create a virtual card first.';
    } else {
      subtitle = 'Virtual card •• ${card.last4} · Balance ${formatLeone(card.balance)}';
    }
    return StepScaffold(
      eyebrow: 'CARDS · FUND CARD',
      counter: '01 / 03',
      title: 'Fund your card',
      subtitle: subtitle,
      headerLabel: 'Cancel',
      onHeaderAction: () => goHome(context),
      primaryLabel: 'Review funding',
      onPrimary: card == null ? null : _review,
      secondaryLabel: 'Back',
      onSecondary: () => Navigator.maybePop(context),
      child: _loading
          ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
          : _error != null
              ? ErrorRetry(message: _error!, onRetry: _load)
              : ListenableBuilder(
                  listenable: appState,
                  builder: (context, _) => Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TpField(
                          label: 'Amount to add',
                          controller: _amount,
                          hint: '0.00',
                          prefixText: 'Le ',
                          allowDecimal: true,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            final a = parseAmount(v ?? '');
                            if (a < 5) return 'Minimum is Le 5';
                            if (a > appState.balance) return 'Insufficient balance';
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        AmountChips(
                          amounts: const [100, 500, 1000, 2000],
                          onPick: (a) => setState(() => _amount.text = a.toStringAsFixed(0)),
                        ),
                        const SizedBox(height: 14),
                        Text(balanceLine(), style: const TextStyle(fontSize: 13, color: TpColors.muted)),
                      ],
                    ),
                  ),
                ),
    );
  }
}
