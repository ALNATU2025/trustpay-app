import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/nav.dart';
import '../../widgets/flow_widgets.dart';
import '../../widgets/step_scaffold.dart';

/// Generic transaction receipt. Build the [ReceiptData] for each kind of payment.
class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key, required this.data});

  final ReceiptData data;

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      eyebrow: data.eyebrow,
      title: 'Transaction receipt',
      subtitle: data.statusLine,
      headerLabel: 'Done',
      onHeaderAction: () => goHome(context),
      primaryLabel: 'Download receipt',
      // TODO: generate a PDF or image of the receipt.
      onPrimary: () => showMessage(context, 'Downloading is not connected yet.'),
      secondaryLabel: 'Back to home',
      onSecondary: () => goHome(context),
      child: Column(
        children: [
          AmountBanner(
            label: data.bannerLabel,
            value: formatNaira(data.amount),
            background: TpColors.greenTint,
            labelColor: TpColors.green,
            valueColor: TpColors.navy,
          ),
          const SizedBox(height: 12),
          DetailsCard(rows: data.rows),
          const SizedBox(height: 12),
          TpWhiteButton(
            label: 'Share receipt',
            icon: Icons.share_outlined,
            onPressed: () => showMessage(context, 'Sharing is not connected yet.'),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => showMessage(context, 'Reporting is not connected yet.'),
              child: const Text(
                'Need help with this transaction? Report an issue',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
