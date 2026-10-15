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
import 'funding_screens.dart';
import 'generic_flow.dart';
import 'mobile_money_screens.dart';
import 'receipt_screen.dart';

/// Add money 1/3: choose a funding method.
class AddMoneyScreen extends StatefulWidget {
  const AddMoneyScreen({super.key});

  @override
  State<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends State<AddMoneyScreen> {
  /// 0 bank transfer, 1 mobile money, 2 debit card.
  int _method = 0;

  void _continue() {
    if (appState.cat.onlineFunding) {
      openScreen(context, const OnlineFundingScreen());
      return;
    }
    switch (_method) {
      case 1:
        openScreen(context, const MobileMoneyScreen(send: false));
      case 2:
        openScreen(context, const FundByCardScreen());
      default:
        openScreen(context, const TransferDetailsScreen());
    }
  }

  Widget _onlineHub() {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) => StepScaffold(
        eyebrow: 'ADD MONEY · FROM HOME / SERVICES',
        counter: '01 / 02',
        title: 'Add money',
        subtitle: 'Pay securely with a card, a bank account or mobile money.',
        headerLabel: 'Cancel',
        onHeaderAction: () => goHome(context),
        primaryLabel: 'Continue',
        onPrimary: _continue,
        secondaryLabel: 'Back to home',
        onSecondary: () => goHome(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AmountBanner(label: 'Current available balance', value: formatLeone(appState.balance)),
            const SizedBox(height: 16),
            SelectTile(
              icon: Icons.lock_outline,
              title: 'Card, bank or mobile money',
              subtitle: 'You choose how to pay on the next secure page',
              selected: true,
              onTap: () {},
            ),
            const SizedBox(height: 16),
            const InfoBanner(text: 'Your card details are entered on the payment provider’s page. TrustPay never sees them.'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (appState.cat.onlineFunding) return _onlineHub();
    final method = const ['bank transfer', 'mobile money', 'debit card'][_method];
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) => StepScaffold(
        eyebrow: 'ADD MONEY · FROM HOME / SERVICES',
        counter: '01 / 03',
        title: 'Add money',
        subtitle: 'Choose how you’d like to fund your account.',
        headerLabel: 'Cancel',
        onHeaderAction: () => goHome(context),
        primaryLabel: 'Continue with $method',
        onPrimary: _continue,
        secondaryLabel: 'Back to home',
        onSecondary: () => goHome(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AmountBanner(
              label: 'Current available balance',
              value: formatLeone(appState.balance),
            ),
            const SizedBox(height: 16),
            SelectTile(
              icon: Icons.account_balance_outlined,
              title: 'Bank transfer',
              subtitle: 'From any Sierra Leone bank · No TrustPay fee',
              selected: _method == 0,
              onTap: () => setState(() => _method = 0),
            ),
            const SizedBox(height: 12),
            SelectTile(
              icon: Icons.phone_android_outlined,
              title: 'Mobile money',
              subtitle: appState.cat.mobileMoney.join(', '),
              selected: _method == 1,
              onTap: () => setState(() => _method = 1),
            ),
            const SizedBox(height: 12),
            SelectTile(
              icon: Icons.credit_card_outlined,
              title: 'Debit card',
              subtitle: 'Fund with a debit card · Fees shown before payment',
              selected: _method == 2,
              onTap: () => setState(() => _method = 2),
            ),
            const SizedBox(height: 16),
            const InfoBanner(
              text: 'Your personal TrustPay account number stays the same for future transfers.',
            ),
            const SizedBox(height: 16),
            Text(
              'Selected method: $method',
              style: const TextStyle(fontSize: 15, color: TpColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Add money 2/3: show the account number to pay into, then wait for the credit.
class TransferDetailsScreen extends StatefulWidget {
  const TransferDetailsScreen({super.key});

  @override
  State<TransferDetailsScreen> createState() => _TransferDetailsScreenState();
}

class _TransferDetailsScreenState extends State<TransferDetailsScreen> {
  static const _pollEvery = Duration(seconds: 5);
  static const _giveUpAfter = Duration(minutes: 3);

  /// Balance when the screen opened. A higher balance later means money arrived.
  late final double _startBalance;
  Timer? _timer;
  DateTime? _waitStarted;
  bool _waiting = false;
  bool _timedOut = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _startBalance = appState.balance;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startWaiting() {
    _timer?.cancel();
    setState(() {
      _waiting = true;
      _timedOut = false;
    });
    _waitStarted = DateTime.now();
    _timer = Timer.periodic(_pollEvery, (_) => _check());
    _check();
  }

  Future<void> _check() async {
    if (_checking || !mounted) return;
    _checking = true;
    try {
      await appState.refreshUser();
      if (!mounted) return;
      if (appState.balance > _startBalance) {
        _timer?.cancel();
        Txn? latest;
        try {
          final page = await api.transactions(limit: 1);
          if (page.items.isNotEmpty) latest = page.items.first;
        } catch (_) {
          // The credit is real; show it even if the receipt cannot be loaded.
        }
        if (!mounted) return;
        replaceScreen(context, MoneyReceivedScreen(amount: appState.balance - _startBalance, txn: latest));
        return;
      }
      final started = _waitStarted;
      if (started != null && DateTime.now().difference(started) >= _giveUpAfter) {
        _timer?.cancel();
        setState(() {
          _waiting = false;
          _timedOut = true;
        });
      }
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = appState.me;
    final String primaryLabel;
    final VoidCallback? onPrimary;
    if (_waiting) {
      primaryLabel = 'Waiting for your transfer…';
      onPrimary = null;
    } else if (_timedOut) {
      primaryLabel = 'Refresh';
      onPrimary = _startWaiting;
    } else {
      primaryLabel = 'I’ve made the transfer';
      onPrimary = _startWaiting;
    }
    return StepScaffold(
      eyebrow: 'ADD MONEY',
      counter: '02 / 03',
      title: 'Transfer to your account',
      subtitle: 'Use these details in your other banking app.',
      headerLabel: 'Done',
      onHeaderAction: () => goHome(context),
      primaryLabel: primaryLabel,
      primaryLoading: _waiting,
      onPrimary: onPrimary,
      secondaryLabel: 'Back to home',
      onSecondary: () => goHome(context),
      child: Column(
        children: [
          AmountBanner(
            label: 'Your TrustPay account number',
            value: me.accountNumber,
            background: TpColors.tint,
            labelColor: TpColors.muted,
            valueColor: TpColors.navy,
            valueSize: 34,
            child: TpWhiteButton(
              label: 'Copy account number',
              icon: Icons.copy_outlined,
              onPressed: () => copyText(context, me.accountNumber, 'Account number copied.'),
            ),
          ),
          const SizedBox(height: 12),
          DetailsCard(
            rows: [
              ('Account name', me.fullName),
              ('Bank', 'TrustPay'),
              ('TrustPay fee', formatLeone(0)),
            ],
          ),
          const SizedBox(height: 12),
          TpWhiteButton(
            label: 'Copy account name',
            icon: Icons.copy_outlined,
            onPressed: () => copyText(context, me.fullName, 'Account name copied.'),
          ),
          const SizedBox(height: 12),
          const WhiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How to add money', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                SizedBox(height: 10),
                Text(
                  '1. Open your other bank’s app.\n'
                  '2. Select TrustPay and enter this account number.\n'
                  '3. Check that the account name matches yours, then enter an amount and send.',
                  style: TextStyle(fontSize: 14, height: 1.5, color: TpColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_timedOut)
            const InfoBanner(
              icon: Icons.hourglass_empty,
              text: 'Still waiting. Your transfer has not arrived yet. Some banks take longer, so you can '
                  'close this screen and your balance will update once the money lands. Tap Refresh to check again.',
            )
          else if (_waiting)
            const InfoBanner(
              icon: Icons.hourglass_empty,
              text: 'Checking for your transfer. This usually takes a few minutes.',
            )
          else
            const InfoBanner(
              text: 'Your balance updates only when funds arrive. Most transfers take a few minutes.',
            ),
        ],
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
            ('To', 'TrustPay · ${appState.me.accountNumber}'),
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
              detail: 'Your bank transfer has arrived and is ready to use.',
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
      subtitle: 'You will pay on a secure page and choose card, bank or mobile money there.',
      primaryLabel: 'Continue to secure payment',
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
