import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/models.dart';
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
    switch (_method) {
      case 1:
        openScreen(context, const MobileMoneyScreen(send: false));
      case 2:
        openScreen(context, const FundByCardScreen());
      default:
        openScreen(context, const TransferDetailsScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
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
