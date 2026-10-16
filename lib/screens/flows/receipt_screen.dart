import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/documents.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/nav.dart';
import '../../widgets/flow_widgets.dart';
import '../../widgets/step_scaffold.dart';
import '../support/support_screen.dart';
import 'generic_flow.dart';

/// Transaction receipt, shown from the server's [ReceiptData].
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
      primaryLabel: 'Share receipt (PDF)',
      onPrimary: () async {
        try {
          await shareReceipt(data);
        } catch (_) {
          if (context.mounted) showMessage(context, 'Could not create the PDF. You can copy the receipt instead.');
        }
      },
      secondaryLabel: 'Back to home',
      onSecondary: () => goHome(context),
      child: Column(
        children: [
          AmountBanner(
            label: data.bannerLabel,
            value: formatLeone(data.amount),
            background: TpColors.greenTint,
            labelColor: TpColors.green,
            valueColor: TpColors.navy,
          ),
          const SizedBox(height: 12),
          DetailsCard(rows: data.rows),
          const SizedBox(height: 4),
          Center(
            child: TextButton.icon(
              onPressed: () => copyText(context, data.toPlainText(), 'Receipt copied.'),
              icon: const Icon(Icons.copy_outlined, size: 18),
              label: const Text('Copy as text'),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: () => openScreen(context, const SupportScreen()),
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
