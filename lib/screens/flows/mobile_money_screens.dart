import 'package:flutter/material.dart';

import '../../services/api.dart';
import '../../services/app_state.dart';
import '../../services/trustpay_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/debounce.dart';
import '../../utils/format.dart';
import '../../utils/nav.dart';
import '../../widgets/common.dart';
import '../../widgets/flow_widgets.dart';
import '../../widgets/step_scaffold.dart';
import 'generic_flow.dart';

/// Mobile money in Sierra Leone (providers come from the server's catalog).
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
  final _number = TextEditingController();
  final _amount = TextEditingController();
  final _debounce = Debouncer();
  late String _wallet;
  String? _holder;
  bool _verifying = false;
  bool _notFound = false;
  String? _lookupError;
  int _lookupId = 0;

  @override
  void initState() {
    super.initState();
    final providers = appState.cat.mobileMoney;
    _wallet = providers.isEmpty ? '' : providers.first;
    if (!widget.send) {
      // Adding money: the wallet is usually the customer's own phone number.
      final d = digitsOf(appState.me.phone);
      if (d.length >= 8) {
        final n = '0${d.substring(d.length - 8)}';
        _number.text = '${n.substring(0, 3)} ${n.substring(3, 6)} ${n.substring(6)}';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _startLookup(immediate: true);
        });
      }
    }
  }

  @override
  void dispose() {
    _debounce.dispose();
    _number.dispose();
    _amount.dispose();
    super.dispose();
  }

  String get _eyebrow => widget.send ? 'SEND MONEY · MOBILE MONEY' : 'ADD MONEY · MOBILE MONEY';

  double get _value => parseAmount(_amount.text);

  String get _digits => _number.text.replaceAll(' ', '');

  /// Called when the provider or the number changes.
  void _startLookup({bool immediate = false}) {
    _lookupId++;
    _debounce.cancel();
    final ready = _digits.length == 9 && _wallet.isNotEmpty && !(widget.send && _isOwnNumber());
    setState(() {
      _holder = null;
      _notFound = false;
      _lookupError = null;
      _verifying = ready;
    });
    if (!ready) return;
    if (immediate) {
      _lookup();
    } else {
      _debounce.run(_lookup);
    }
  }

  bool _isOwnNumber() => samePhone(_digits, appState.me.phone);

  Future<void> _lookup() async {
    final provider = _wallet;
    final number = _digits;
    final id = ++_lookupId;
    try {
      final name = await api.lookupWallet(provider, number);
      if (!mounted || id != _lookupId) return;
      final found = (name == null || name.isEmpty) ? null : name;
      setState(() {
        _holder = found;
        _notFound = found == null;
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
    final holder = _holder;
    if (holder == null) {
      showMessage(context, 'Enter a valid $_wallet number first.');
      return;
    }
    final amount = _value;
    final number = _number.text.trim();
    final digits = _digits;
    final wallet = _wallet;
    final send = widget.send;
    final fee = send ? appState.cat.fees.mobileMoneySend : 0.0;
    final total = amount + fee;
    final after = send ? appState.balance - total : appState.balance + amount;

    openScreen(
      context,
      PayConfirmScreen(
        eyebrow: _eyebrow,
        counter: '02 / 03',
        title: send ? 'Confirm transfer' : 'Confirm wallet payment',
        bannerLabel: send ? 'Sending to $wallet · $holder' : 'Paid from your $wallet',
        total: total,
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
          if (send) ('Fee', formatLeone(fee)),
          ('Balance after', formatLeone(after)),
        ],
        onPay: (secret, key) => send
            ? api.mobileMoneySend(
                provider: wallet,
                number: digits,
                amount: amount,
                pin: secret,
                idempotencyKey: key,
              )
            : api.mobileMoneyAdd(
                provider: wallet,
                number: digits,
                amount: amount,
                code: secret,
                idempotencyKey: key,
              ),
        successBuilder: (result) {
          final txn = result.transaction;
          final pending = isPending(txn);
          final headline = pending
              ? '${formatLeone(amount)} is being processed'
              : (send ? '${formatLeone(amount)} sent' : '${formatLeone(amount)} added');
          return PaySuccessScreen(
            eyebrow: _eyebrow,
            counter: '03 / 03',
            headline: headline,
            detail: send ? 'To $holder · $wallet' : 'From your $wallet',
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
    final send = widget.send;
    final providers = appState.cat.mobileMoney;
    final providerNames = providers.join(', ');
    return StepScaffold(
      eyebrow: _eyebrow,
      counter: '01 / 03',
      title: send ? 'Send to mobile money' : 'Add from mobile money',
      subtitle: send
          ? 'Send to a $providerNames wallet.'
          : 'Pay from your wallet into your TrustPay account.',
      headerLabel: 'Cancel',
      onHeaderAction: () => goHome(context),
      primaryLabel: 'Review',
      onPrimary: _review,
      secondaryLabel: 'Back',
      onSecondary: () => Navigator.maybePop(context),
      child: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final fee = send ? appState.cat.fees.mobileMoneySend : 0.0;
          return Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mobile money provider', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (var i = 0; i < providers.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceBox(
                          label: providers[i],
                          selected: providers[i] == _wallet,
                          onTap: () {
                            setState(() => _wallet = providers[i]);
                            _startLookup();
                          },
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
                  onChanged: (_) => _startLookup(),
                  validator: (v) {
                    final d = (v ?? '').replaceAll(' ', '');
                    if (d.length != 9) return 'Enter a 9-digit number, like 076 123 456';
                    if (send && samePhone(d, appState.me.phone)) return 'That is your own number';
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
                  const Text('Looking up…', style: TextStyle(fontSize: 13, color: TpColors.muted))
                else if (_notFound)
                  Text(
                    'No $_wallet wallet found for this number.',
                    style: const TextStyle(fontSize: 13, color: TpColors.danger),
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
                    if (a < 5) return 'Minimum is Le 5';
                    if (send && a + appState.cat.fees.mobileMoneySend > appState.balance) {
                      return 'Insufficient balance';
                    }
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
                  send
                      ? '${balanceLine()} · Fee ${formatLeone(fee)}'
                      : 'No TrustPay fee · Your wallet provider may charge its own fee.',
                  style: const TextStyle(fontSize: 13, color: TpColors.muted),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
