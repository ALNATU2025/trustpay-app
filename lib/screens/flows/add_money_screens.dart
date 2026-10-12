import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/sample_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/nav.dart';
import '../../widgets/common.dart';
import '../../widgets/flow_widgets.dart';
import '../../widgets/step_scaffold.dart';
import 'receipt_screen.dart';

/// Add money 1/3: choose a funding method.
class AddMoneyScreen extends StatefulWidget {
  const AddMoneyScreen({super.key});

  @override
  State<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends State<AddMoneyScreen> {
  bool _bankTransfer = true;

  void _continue() {
    if (!_bankTransfer) {
      // Only the bank transfer path is in the designs so far.
      showMessage(context, 'Debit card funding is coming soon.');
      return;
    }
    openScreen(context, const TransferDetailsScreen());
  }

  @override
  Widget build(BuildContext context) {
    final method = _bankTransfer ? 'bank transfer' : 'debit card';
    return StepScaffold(
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
            value: formatNaira(kAccountBalance),
          ),
          const SizedBox(height: 16),
          SelectTile(
            icon: Icons.account_balance_outlined,
            title: 'Bank transfer',
            subtitle: 'Transfer from any Nigerian bank · No TrustPay fee',
            selected: _bankTransfer,
            onTap: () => setState(() => _bankTransfer = true),
          ),
          const SizedBox(height: 12),
          SelectTile(
            icon: Icons.credit_card_outlined,
            title: 'Debit card',
            subtitle: 'Fund with a Nigerian debit card · Fees shown before payment',
            selected: !_bankTransfer,
            onTap: () => setState(() => _bankTransfer = false),
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
    );
  }
}

/// Add money 2/3: show the account number to pay into.
class TransferDetailsScreen extends StatelessWidget {
  const TransferDetailsScreen({super.key});

  static const double _example = 50000;

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      eyebrow: 'ADD MONEY',
      counter: '02 / 03',
      title: 'Transfer to your account',
      subtitle: 'Use these details in your other banking app.',
      headerLabel: 'Done',
      onHeaderAction: () => goHome(context),
      primaryLabel: 'I’ve made the transfer',
      // TODO: wait for the credit notification from your backend instead.
      onPrimary: () => replaceScreen(
        context,
        MoneyReceivedScreen(
          amount: _example,
          reference: makeReference('ADD'),
          receivedAt: DateTime.now(),
        ),
      ),
      secondaryLabel: 'Back to home',
      onSecondary: () => goHome(context),
      child: Column(
        children: [
          AmountBanner(
            label: 'Your TrustPay account number',
            value: kAccountNumber,
            background: TpColors.tint,
            labelColor: TpColors.muted,
            valueColor: TpColors.navy,
            valueSize: 34,
            child: TpWhiteButton(
              label: 'Copy account number',
              icon: Icons.copy_outlined,
              onPressed: () async {
                await Clipboard.setData(const ClipboardData(text: kAccountNumber));
                if (context.mounted) showMessage(context, 'Account number copied.');
              },
            ),
          ),
          const SizedBox(height: 12),
          DetailsCard(
            rows: [
              ('Account name', kAccountName),
              ('Bank', 'TrustPay'),
              ('Example transfer', formatNaira(_example)),
              ('TrustPay fee', formatNaira(0)),
            ],
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
                  '3. Confirm Ada Okafor, enter ₦50,000 and send.',
                  style: TextStyle(fontSize: 14, height: 1.5, color: TpColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
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
  const MoneyReceivedScreen({
    super.key,
    required this.amount,
    required this.reference,
    required this.receivedAt,
  });

  final double amount;
  final String reference;
  final DateTime receivedAt;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('From', '$kAccountName · GTBank'),
      ('To', 'TrustPay · $kAccountNumber'),
      ('Amount credited', formatNaira(amount)),
      ('TrustPay fee', formatNaira(0)),
      ('Reference', reference),
      ('Received at', formatDateTime(receivedAt)),
    ];
    return StepScaffold(
      eyebrow: 'ADD MONEY',
      counter: '03 / 03',
      title: 'Money received',
      headerLabel: 'Done',
      onBack: () => goHome(context),
      onHeaderAction: () => goHome(context),
      primaryLabel: 'View receipt',
      onPrimary: () => openScreen(
        context,
        ReceiptScreen(
          data: ReceiptData(
            eyebrow: 'ADD MONEY · RECEIPT',
            statusLine: 'Successful · Account funding',
            bannerLabel: 'Received from $kAccountName',
            amount: amount,
            rows: rows,
          ),
        ),
      ),
      secondaryLabel: 'Back to home',
      onSecondary: () => goHome(context),
      child: Column(
        children: [
          ResultHeader(
            headline: '${formatNaira(amount)} added',
            detail: 'Your bank transfer has arrived and is ready to use.',
          ),
          const SizedBox(height: 20),
          DetailsCard(rows: rows),
          const SizedBox(height: 12),
          AmountBanner(
            label: 'Available balance after credit',
            value: formatNaira(kAccountBalance + amount),
            background: TpColors.greenTint,
            labelColor: TpColors.green,
            valueColor: TpColors.navy,
            valueSize: 34,
          ),
        ],
      ),
    );
  }
}
