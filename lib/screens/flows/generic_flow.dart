import 'package:flutter/material.dart';

import '../../data/sample_data.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/nav.dart';
import '../../widgets/common.dart';
import '../../widgets/flow_widgets.dart';
import '../../widgets/otp_input.dart';
import '../../widgets/step_scaffold.dart';

/// Review-and-authorize step shared by the newer flows (TV, internet, cards,
/// send to a TrustPay user). Shows the total, the details, a PIN or code box,
/// then replaces itself with the screen from [successBuilder].
class PayConfirmScreen extends StatefulWidget {
  const PayConfirmScreen({
    super.key,
    required this.eyebrow,
    required this.counter,
    required this.title,
    required this.bannerLabel,
    required this.total,
    required this.rows,
    required this.referenceCode,
    required this.successBuilder,
    this.payLabel = 'Pay',
    this.notice,
    this.pinLabel = 'Authorize with transaction PIN',
    this.pinLength = 4,
    this.obscure = true,
    this.onConfirmed,
  });

  final String eyebrow;
  final String counter;
  final String title;
  final String bannerLabel;
  final double total;
  final List<(String, String)> rows;

  /// Short code for the receipt reference, such as `TVB` giving `TP-TVB-...`.
  final String referenceCode;
  final Widget Function(String reference) successBuilder;
  final String payLabel;
  final String? notice;
  final String pinLabel;
  final int pinLength;
  final bool obscure;

  /// Runs once the payment goes through, for example to update a balance.
  final VoidCallback? onConfirmed;

  @override
  State<PayConfirmScreen> createState() => _PayConfirmScreenState();
}

class _PayConfirmScreenState extends State<PayConfirmScreen> {
  String _pin = '';
  bool _loading = false;

  Future<void> _pay() async {
    setState(() => _loading = true);
    // TODO: verify the PIN or code and submit the payment with your API.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    widget.onConfirmed?.call();
    replaceScreen(context, widget.successBuilder(makeReference(widget.referenceCode)));
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      eyebrow: widget.eyebrow,
      counter: widget.counter,
      title: widget.title,
      headerLabel: 'Cancel',
      onHeaderAction: () => goHome(context),
      primaryLabel: '${widget.payLabel} ${formatLeone(widget.total)}',
      primaryLoading: _loading,
      onPrimary: _pin.length == widget.pinLength && !_loading ? _pay : null,
      secondaryLabel: 'Edit details',
      onSecondary: _loading ? null : () => Navigator.maybePop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AmountBanner(label: widget.bannerLabel, value: formatLeone(widget.total)),
          const SizedBox(height: 12),
          DetailsCard(rows: widget.rows),
          const SizedBox(height: 20),
          Text(widget.pinLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          OtpInput(
            length: widget.pinLength,
            obscure: widget.obscure,
            onChanged: (v) => setState(() => _pin = v),
          ),
          if (widget.notice != null) ...[
            const SizedBox(height: 16),
            InfoBanner(text: widget.notice!),
          ],
        ],
      ),
    );
  }
}

/// Result step shared by the newer flows: animated tick, headline, details.
class PaySuccessScreen extends StatelessWidget {
  const PaySuccessScreen({
    super.key,
    required this.eyebrow,
    required this.counter,
    required this.headline,
    required this.detail,
    required this.rows,
    this.extra,
    this.notice,
    this.primaryLabel = 'Share receipt',
    this.onPrimary,
  });

  final String eyebrow;
  final String counter;
  final String headline;
  final String detail;
  final List<(String, String)> rows;

  /// Optional block between the headline and the details (a card picture, a token).
  final Widget? extra;
  final String? notice;
  final String primaryLabel;

  /// Defaults to a "sharing is not connected" message.
  final VoidCallback? onPrimary;

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      eyebrow: eyebrow,
      counter: counter,
      title: 'All done',
      headerLabel: 'Done',
      onBack: () => goHome(context),
      onHeaderAction: () => goHome(context),
      primaryLabel: primaryLabel,
      // TODO: share the receipt (for example with the share_plus package).
      onPrimary: onPrimary ?? () => showMessage(context, 'Sharing is not connected yet.'),
      secondaryLabel: 'Back to home',
      onSecondary: () => goHome(context),
      child: Column(
        children: [
          ResultHeader(headline: headline, detail: detail),
          if (extra != null) ...[
            const SizedBox(height: 20),
            extra!,
          ],
          const SizedBox(height: 20),
          DetailsCard(rows: rows),
          if (notice != null) ...[
            const SizedBox(height: 12),
            InfoBanner(
              icon: Icons.check_circle_outline,
              background: TpColors.greenTint,
              accent: TpColors.green,
              textColor: TpColors.green,
              text: notice!,
            ),
          ],
        ],
      ),
    );
  }
}

/// Quick amount chips under an amount field.
class AmountChips extends StatelessWidget {
  const AmountChips({super.key, required this.amounts, required this.onPick});

  final List<double> amounts;
  final ValueChanged<double> onPick;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final a in amounts)
          ActionChip(
            label: Text(formatLeone(a, decimals: 0)),
            onPressed: () => onPick(a),
            backgroundColor: TpColors.tint,
            side: BorderSide.none,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, color: TpColors.primary),
          ),
      ],
    );
  }
}

/// Balance line used under amount fields.
String balanceLine() => 'Available balance ${formatLeone(kAccountBalance)}';
