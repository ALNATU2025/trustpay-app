import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/models.dart';
import '../../services/api.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/nav.dart';
import '../../widgets/common.dart';
import '../../widgets/flow_widgets.dart';
import '../../widgets/otp_input.dart';
import '../../widgets/step_scaffold.dart';

/// Review-and-authorize step shared by every payment flow. Shows the total, the details and a PIN
/// (or code) box. On "Pay" it calls [onPay] with the PIN and an idempotency key, updates the
/// balance, and replaces itself with the screen from [successBuilder].
///
/// The idempotency key is created once per screen, so tapping Pay again after a dropped connection
/// can never charge the customer twice.
class PayConfirmScreen extends StatefulWidget {
  const PayConfirmScreen({
    super.key,
    required this.eyebrow,
    required this.counter,
    required this.title,
    required this.bannerLabel,
    required this.total,
    required this.rows,
    required this.onPay,
    required this.successBuilder,
    this.payLabel = 'Pay',
    this.notice,
    this.pinLabel = 'Authorize with transaction PIN',
    this.pinLength = 4,
    this.obscure = true,
  });

  final String eyebrow;
  final String counter;
  final String title;
  final String bannerLabel;
  final double total;
  final List<(String, String)> rows;

  /// Sends the payment. [secret] is the PIN (or the approval code when [pinLength] is 6).
  final Future<PaymentResult> Function(String secret, String idempotencyKey) onPay;
  final Widget Function(PaymentResult result) successBuilder;
  final String payLabel;
  final String? notice;
  final String pinLabel;
  final int pinLength;
  final bool obscure;

  @override
  State<PayConfirmScreen> createState() => _PayConfirmScreenState();
}

class _PayConfirmScreenState extends State<PayConfirmScreen> {
  final String _key = newIdempotencyKey();
  String _pin = '';
  bool _loading = false;
  String? _error;
  int _round = 0; // changes to clear the PIN boxes after a wrong PIN

  Future<void> _pay() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.onPay(_pin, _key);
      if (!mounted) return;
      appState.applyPayment(result);
      replaceScreen(context, widget.successBuilder(result));
    } on ApiException catch (e) {
      if (!mounted) return;
      var message = e.message;
      if (e.status == 0) {
        message = '$message If you already tried to pay, check Transactions before paying again.';
      }
      setState(() {
        _loading = false;
        _error = message;
        if (e.isBadPin || e.status == 422 || e.status == 402 || e.status == 502) {
          _pin = '';
          _round++;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Something went wrong. Check Transactions before paying again.';
      });
    }
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
            key: ValueKey(_round),
            length: widget.pinLength,
            obscure: widget.obscure,
            onChanged: (v) => setState(() => _pin = v),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            InfoBanner(
              icon: Icons.error_outline,
              background: const Color(0xFFFDECEC),
              accent: TpColors.danger,
              textColor: TpColors.danger,
              text: _error!,
            ),
          ],
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
    this.primaryLabel = 'Copy receipt',
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

  /// Defaults to copying the details to the clipboard.
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
      onPrimary: onPrimary ?? () => copyText(context, rows.map((r) => '${r.$1}: ${r.$2}').join('\n'), 'Receipt copied.'),
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
String balanceLine() => 'Available balance ${formatLeone(appState.balance)}';

/// Copies [text] and confirms with a snackbar.
Future<void> copyText(BuildContext context, String text, String message) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) showMessage(context, message);
}

/// Copies the receipt of a transaction (falls back to its reference).
Future<void> copyReceipt(BuildContext context, Txn t) =>
    copyText(context, t.receipt?.toPlainText() ?? 'TrustPay reference: ${t.reference}', 'Receipt copied.');

/// Detail rows for a result screen: the server's receipt rows, or reference and time as a fallback.
List<(String, String)> receiptRows(Txn t) => t.receipt != null && t.receipt!.rows.isNotEmpty ? t.receipt!.rows : t.summaryRows;

/// "Successful" or "Pending" wording for result headlines.
bool isPending(Txn t) => t.status == 'Pending';
