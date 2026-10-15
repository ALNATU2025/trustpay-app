import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/models.dart';
import '../../services/api.dart';
import '../../services/app_state.dart';
import '../../services/trustpay_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/nav.dart';
import '../../widgets/common.dart';
import '../../widgets/flow_widgets.dart';
import '../../widgets/step_scaffold.dart';
import 'generic_flow.dart';
import 'receipt_screen.dart';

/// Add money 1/2: choose mobile money or card.
class AddMoneyScreen extends StatefulWidget {
  const AddMoneyScreen({super.key});

  @override
  State<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends State<AddMoneyScreen> {
  /// 0 mobile money, 1 card.
  int _method = 0;

  void _continue() {
    openScreen(context, _method == 0 ? const MomoTopUpScreen() : const OnlineFundingScreen());
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) => StepScaffold(
        eyebrow: 'ADD MONEY · FROM HOME / SERVICES',
        counter: '01 / 02',
        title: 'Add money',
        subtitle: 'Pay with mobile money or a card.',
        headerLabel: 'Cancel',
        onHeaderAction: () => goHome(context),
        primaryLabel: _method == 0 ? 'Continue with mobile money' : 'Continue with card',
        onPrimary: _continue,
        secondaryLabel: 'Back to home',
        onSecondary: () => goHome(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AmountBanner(label: 'Current available balance', value: formatLeone(appState.balance)),
            const SizedBox(height: 16),
            SelectTile(
              icon: Icons.phone_android_outlined,
              title: 'Mobile money',
              subtitle: '${appState.cat.mobileMoney.join(', ')} · Approve with a USSD code',
              selected: _method == 0,
              onTap: () => setState(() => _method = 0),
            ),
            const SizedBox(height: 12),
            SelectTile(
              icon: Icons.credit_card_outlined,
              title: 'Card',
              subtitle: 'Pay on a secure card page',
              selected: _method == 1,
              onTap: () => setState(() => _method = 1),
            ),
            const SizedBox(height: 16),
            const InfoBanner(text: 'Your money is added as soon as the payment is confirmed.'),
          ],
        ),
      ),
    );
  }
}

/// Add money 3/3: funds arrived.
class MoneyReceivedScreen extends StatelessWidget {
  const MoneyReceivedScreen({super.key, required this.amount, this.txn});

  /// How much the balance went up.
  final double amount;

  /// The newest transaction, when it could be loaded.
  final Txn? txn;

  @override
  Widget build(BuildContext context) {
    final t = txn;
    final credited = t != null && t.amount != 0 ? t.amount.abs() : amount;
    final rows = t != null
        ? receiptRows(t)
        : <(String, String)>[
            ('To', 'TrustPay wallet'),
            ('Amount credited', formatLeone(credited)),
          ];
    return StepScaffold(
      eyebrow: 'ADD MONEY',
      counter: '03 / 03',
      title: 'Money received',
      headerLabel: 'Done',
      onBack: () => goHome(context),
      onHeaderAction: () => goHome(context),
      primaryLabel: t?.receipt != null ? 'View receipt' : 'Copy details',
      onPrimary: () => t?.receipt != null
          ? openScreen(context, ReceiptScreen(data: t!.receipt!))
          : copyText(context, rows.map((r) => '${r.$1}: ${r.$2}').join('\n'), 'Details copied.'),
      secondaryLabel: 'Back to home',
      onSecondary: () => goHome(context),
      child: ListenableBuilder(
        listenable: appState,
        builder: (context, _) => Column(
          children: [
            ResultHeader(
              headline: '${formatLeone(credited)} added',
              detail: 'Your payment has arrived and is ready to use.',
            ),
            const SizedBox(height: 20),
            DetailsCard(rows: rows),
            const SizedBox(height: 12),
            AmountBanner(
              label: 'Available balance',
              value: formatLeone(appState.balance),
              background: TpColors.greenTint,
              labelColor: TpColors.green,
              valueColor: TpColors.navy,
              valueSize: 34,
            ),
          ],
        ),
      ),
    );
  }
}


/// Add money 2/2 (live server): enter an amount, pay on the provider's secure page, then wait for the credit.
class OnlineFundingScreen extends StatefulWidget {
  const OnlineFundingScreen({super.key});

  @override
  State<OnlineFundingScreen> createState() => _OnlineFundingScreenState();
}

class _OnlineFundingScreenState extends State<OnlineFundingScreen> with WidgetsBindingObserver {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final String _key = newIdempotencyKey();
  Timer? _poll;
  bool _busy = false;
  bool _waiting = false;
  bool _timedOut = false;
  String? _error;
  String? _txnId;
  String? _url;
  double _requested = 0;
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _amount.dispose();
    super.dispose();
  }

  /// Checks again as soon as the customer comes back from the payment page.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waiting) _check();
  }

  Future<void> _start() async {
    if (!_form.currentState!.validate() || _busy) return;
    final amount = parseAmount(_amount.text);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final (result, url) = await api.startCheckout(amount: amount, idempotencyKey: _key);
      if (!mounted) return;
      appState.applyPayment(result);
      _txnId = result.transaction.id;
      _requested = amount;
      if (url == null) {
        // Test server: the money was added at once.
        _finish(result.transaction);
        return;
      }
      _url = url;
      setState(() {
        _waiting = true;
        _timedOut = false;
        _deadline = DateTime.now().add(const Duration(minutes: 10));
      });
      await _open();
      _poll = Timer.periodic(const Duration(seconds: 4), (_) => _check());
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open() async {
    final url = _url;
    if (url == null) return;
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) setState(() => _error = 'We could not open the payment page. Tap "Open payment page" to try again.');
  }

  Future<void> _check() async {
    final id = _txnId;
    if (id == null || !mounted) return;
    try {
      final t = await api.transaction(id);
      if (!mounted) return;
      if (t.status == 'Successful') {
        await appState.refreshUser();
        _finish(t);
      } else if (t.status == 'Failed') {
        _poll?.cancel();
        setState(() {
          _waiting = false;
          _error = 'The payment was not completed. No money was taken.';
        });
      } else if (_deadline != null && DateTime.now().isAfter(_deadline!)) {
        _poll?.cancel();
        setState(() => _timedOut = true);
      }
    } on ApiException {
      // Try again on the next tick.
    }
  }

  void _finish(Txn t) {
    _poll?.cancel();
    appState.refreshUser();
    replaceScreen(context, MoneyReceivedScreen(amount: _requested, txn: t));
  }

  @override
  Widget build(BuildContext context) {
    if (_waiting) {
      return StepScaffold(
        eyebrow: 'ADD MONEY',
        counter: '02 / 02',
        title: _timedOut ? 'Still waiting' : 'Complete your payment',
        subtitle: _timedOut
            ? 'We have not received the money yet. If you paid, it can take a few minutes to arrive.'
            : 'Finish paying on the secure page. This screen updates when the money arrives.',
        headerLabel: 'Done',
        onHeaderAction: () => goHome(context),
        primaryLabel: _timedOut ? 'Check again' : 'Open payment page',
        onPrimary: _timedOut
            ? () {
                setState(() {
                  _timedOut = false;
                  _deadline = DateTime.now().add(const Duration(minutes: 5));
                });
                _poll?.cancel();
                _poll = Timer.periodic(const Duration(seconds: 4), (_) => _check());
                _check();
              }
            : _open,
        secondaryLabel: 'Back to home',
        onSecondary: () => goHome(context),
        child: Column(
          children: [
            if (!_timedOut) const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: CircularProgressIndicator()),
            if (_error != null) ErrorBanner(_error!),
            const SizedBox(height: 12),
            InfoBanner(text: 'Adding ${formatLeone(_requested)} to your balance. Do not pay twice: if you already paid, just wait here.'),
          ],
        ),
      );
    }
    return StepScaffold(
      eyebrow: 'ADD MONEY',
      counter: '02 / 02',
      title: 'How much?',
      subtitle: 'You will enter your card on a secure payment page.',
      primaryLabel: 'Continue to card payment',
      primaryLoading: _busy,
      onPrimary: _busy ? null : _start,
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
              validator: (v) => parseAmount(v ?? '') < 5 ? 'Minimum is Le 5' : null,
            ),
            const SizedBox(height: 8),
            AmountChips(
              amounts: const [100, 500, 1000, 2000],
              onPick: (a) => setState(() => _amount.text = a.toStringAsFixed(0)),
            ),
            if (_error != null) ...[const SizedBox(height: 16), ErrorBanner(_error!)],
            const SizedBox(height: 16),
            const InfoBanner(text: 'TrustPay never sees your card details. The provider’s own fees, if any, are shown on its page.'),
          ],
        ),
      ),
    );
  }
}


/// Add money 2/2 (mobile money): pick the wallet, get a USSD code, dial it and approve, then wait for the credit.
class MomoTopUpScreen extends StatefulWidget {
  const MomoTopUpScreen({super.key});

  @override
  State<MomoTopUpScreen> createState() => _MomoTopUpScreenState();
}

class _MomoTopUpScreenState extends State<MomoTopUpScreen> with WidgetsBindingObserver {
  final _form = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _amount = TextEditingController();
  final String _key = newIdempotencyKey();
  Timer? _poll;
  String _wallet = '';
  bool _busy = false;
  bool _waiting = false;
  bool _timedOut = false;
  String? _error;
  String? _txnId;
  String? _code;
  double _requested = 0;
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final providers = appState.cat.mobileMoney;
    _wallet = providers.isEmpty ? '' : providers.first;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _number.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waiting) _check();
  }

  Future<void> _start() async {
    if (!_form.currentState!.validate() || _busy) return;
    final amount = parseAmount(_amount.text);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final (result, code, expires) = await api.startMomoTopUp(
        provider: _wallet,
        number: _number.text.replaceAll(' ', ''),
        amount: amount,
        idempotencyKey: _key,
      );
      if (!mounted) return;
      appState.applyPayment(result);
      _txnId = result.transaction.id;
      _requested = amount;
      if (code == null) {
        // Test server: the money was added at once.
        _finish(result.transaction);
        return;
      }
      _code = code;
      setState(() {
        _waiting = true;
        _timedOut = false;
        _deadline = expires ?? DateTime.now().add(const Duration(minutes: 15));
      });
      _poll = Timer.periodic(const Duration(seconds: 4), (_) => _check());
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _dial() async {
    final code = _code;
    if (code == null) return;
    final ok = await launchUrl(Uri(scheme: 'tel', path: code));
    if (!ok && mounted) showMessage(context, 'Open your phone app and dial $code');
  }

  Future<void> _check() async {
    final id = _txnId;
    if (id == null || !mounted) return;
    try {
      final t = await api.transaction(id);
      if (!mounted) return;
      if (t.status == 'Successful') {
        await appState.refreshUser();
        _finish(t);
      } else if (t.status == 'Failed') {
        _poll?.cancel();
        setState(() {
          _waiting = false;
          _error = 'The payment was not completed. No money was taken.';
        });
      } else if (_deadline != null && DateTime.now().isAfter(_deadline!)) {
        _poll?.cancel();
        setState(() => _timedOut = true);
      }
    } on ApiException {
      // Try again on the next tick.
    }
  }

  void _finish(Txn t) {
    _poll?.cancel();
    appState.refreshUser();
    replaceScreen(context, MoneyReceivedScreen(amount: _requested, txn: t));
  }

  @override
  Widget build(BuildContext context) {
    if (_waiting) {
      return StepScaffold(
        eyebrow: 'ADD MONEY',
        counter: '02 / 02',
        title: _timedOut ? 'Still waiting' : 'Dial to pay',
        subtitle: _timedOut
            ? 'We have not received the money yet. If you approved the payment, it can take a few minutes to arrive.'
            : 'Dial this code from $_wallet number ${_number.text} and approve the payment.',
        headerLabel: 'Done',
        onHeaderAction: () => goHome(context),
        primaryLabel: _timedOut ? 'Check again' : 'Dial now',
        onPrimary: _timedOut
            ? () {
                setState(() {
                  _timedOut = false;
                  _deadline = DateTime.now().add(const Duration(minutes: 5));
                });
                _poll?.cancel();
                _poll = Timer.periodic(const Duration(seconds: 4), (_) => _check());
                _check();
              }
            : _dial,
        secondaryLabel: 'Back to home',
        onSecondary: () => goHome(context),
        child: Column(
          children: [
            AmountBanner(label: 'Dial', value: _code ?? ''),
            const SizedBox(height: 12),
            if (_code != null)
              OutlinedButton.icon(
                onPressed: () => copyText(context, _code!, 'Code copied.'),
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy code'),
              ),
            if (!_timedOut) const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: CircularProgressIndicator()),
            if (_error != null) ErrorBanner(_error!),
            const SizedBox(height: 12),
            InfoBanner(text: 'Adding ${formatLeone(_requested)} to your balance. The code works once, only from your number, and expires soon. Do not pay twice.'),
          ],
        ),
      );
    }
    final providers = appState.cat.mobileMoney;
    return StepScaffold(
      eyebrow: 'ADD MONEY',
      counter: '02 / 02',
      title: 'Mobile money',
      subtitle: 'We give you a USSD code to dial and approve on your phone.',
      primaryLabel: 'Get payment code',
      primaryLoading: _busy,
      onPrimary: _busy ? null : _start,
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
                for (var i = 0; i < providers.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceBox(
                      label: providers[i],
                      selected: providers[i] == _wallet,
                      onTap: () => setState(() => _wallet = providers[i]),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 18),
            TpField(
              label: 'Your wallet number',
              controller: _number,
              hint: '076 123 456',
              keyboardType: TextInputType.phone,
              validator: (v) => (v ?? '').replaceAll(' ', '').length != 9 ? 'Enter a 9-digit number, like 076 123 456' : null,
            ),
            const SizedBox(height: 16),
            TpField(
              label: 'Amount',
              controller: _amount,
              hint: '0.00',
              prefixText: 'Le ',
              allowDecimal: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => parseAmount(v ?? '') < 5 ? 'Minimum is Le 5' : null,
            ),
            const SizedBox(height: 8),
            AmountChips(
              amounts: const [100, 500, 1000, 2000],
              onPick: (a) => setState(() => _amount.text = a.toStringAsFixed(0)),
            ),
            if (_error != null) ...[const SizedBox(height: 16), ErrorBanner(_error!)],
            const SizedBox(height: 16),
            const InfoBanner(text: 'No TrustPay fee. Your wallet provider may charge its own fee.'),
          ],
        ),
      ),
    );
  }
}
