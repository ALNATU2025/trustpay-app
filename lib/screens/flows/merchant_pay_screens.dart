import 'package:barcode/barcode.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/models.dart';
import '../../services/api.dart';
import '../../services/app_state.dart';
import '../../services/trustpay_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/nav.dart';
import '../../widgets/api_builder.dart';
import '../../widgets/common.dart';
import '../../widgets/flow_widgets.dart';
import '../../widgets/menu_widgets.dart';
import '../../widgets/step_scaffold.dart';
import 'generic_flow.dart';

/// Pulls the 6-digit merchant code out of scanned text (`trustpay://pay/123456`, or just `123456`).
String? merchantCodeFrom(String text) {
  final m = RegExp(r'(?<!\d)(\d{6})(?!\d)').firstMatch(text);
  return m?.group(1);
}

// ----------------------------------------------------------- merchant side

/// The merchant's permanent code and QR: show it, copy it or print it for the shop counter.
class MerchantCodeScreen extends StatelessWidget {
  const MerchantCodeScreen({super.key});

  Future<void> _print(BuildContext context, Map<String, dynamic> d) async {
    final name = asStr(d['businessName']);
    final code = asStr(d['code']);
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        build: (_) => pw.Center(
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text('Pay $name', style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text('with TrustPay', style: const pw.TextStyle(fontSize: 18)),
              pw.SizedBox(height: 28),
              pw.BarcodeWidget(barcode: Barcode.qrCode(), data: asStr(d['qr']), width: 300, height: 300),
              pw.SizedBox(height: 28),
              pw.Text('Merchant code', style: const pw.TextStyle(fontSize: 16)),
              pw.Text(code, style: pw.TextStyle(fontSize: 48, fontWeight: pw.FontWeight.bold, letterSpacing: 6)),
              pw.SizedBox(height: 16),
              pw.Text('Open TrustPay, choose Send money > To a merchant, then scan or enter the code.',
                  style: const pw.TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
    try {
      await Printing.layoutPdf(name: 'TrustPay-$code', onLayout: (_) => doc.save());
    } catch (e) {
      if (context.mounted) showMessage(context, 'Could not open the print dialog.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlainScaffold(
      title: 'My merchant code',
      child: ApiBuilder<Map<String, dynamic>>(
        load: api.posCode,
        builder: (context, d, reload) => Column(
          children: [
            WhiteCard(
              child: Column(
                children: [
                  Text(asStr(d['businessName']), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  QrImageView(data: asStr(d['qr']), size: 220, backgroundColor: Colors.white),
                  const SizedBox(height: 12),
                  const Text('Merchant code', style: TextStyle(color: TpColors.muted)),
                  Text(asStr(d['code']),
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: 6)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Print / save as PDF', onPressed: () => _print(context, d)),
            const SizedBox(height: 8),
            SecondaryButton(label: 'Copy code', onPressed: () => copyText(context, asStr(d['code']), 'Code copied.')),
            const SizedBox(height: 16),
            const InfoBanner(
              text: 'Customers scan this QR or type the code in TrustPay (Send money > To a merchant). '
                  'The money reaches your wallet instantly. Your code never changes, so you can print it once.',
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------- customer side

class _ScanScreen extends StatefulWidget {
  const _ScanScreen();

  @override
  State<_ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<_ScanScreen> {
  bool _done = false;

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final b in capture.barcodes) {
      final code = merchantCodeFrom(b.rawValue ?? '');
      if (code != null) {
        _done = true;
        Navigator.pop(context, code);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan merchant QR')),
      body: MobileScanner(
        onDetect: _onDetect,
        errorBuilder: (context, error, child) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Camera is not available. Go back and type the merchant code instead.', textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}

/// Pay a merchant: scan their QR or type their 6-digit code, enter the amount, confirm with your PIN.
class PayMerchantScreen extends StatefulWidget {
  const PayMerchantScreen({super.key});

  @override
  State<PayMerchantScreen> createState() => _PayMerchantScreenState();
}

class _PayMerchantScreenState extends State<PayMerchantScreen> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final code = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const _ScanScreen()));
    if (code != null && mounted) setState(() => _code.text = code);
  }

  Future<void> _next() async {
    if (!_form.currentState!.validate() || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final code = _code.text.trim();
      final merchant = await api.lookupMerchant(code);
      if (!mounted) return;
      if (merchant == null) {
        setState(() => _error = 'We could not find a merchant with that code.');
        return;
      }
      final amount = parseAmount(_amount.text);
      final note = _note.text.trim();
      await openScreen(
        context,
        PayConfirmScreen(
          eyebrow: 'PAY A MERCHANT',
          counter: '02 / 02',
          title: 'Confirm payment',
          bannerLabel: 'You are paying',
          total: amount,
          payLabel: 'Pay $merchant',
          rows: [
            ('Merchant', merchant),
            ('Code', code),
            if (note.isNotEmpty) ('Note', note),
            ('Balance after', formatLeone(appState.balance - amount)),
          ],
          onPay: (pin, key) => api.payMerchant(code: code, amount: amount, note: note, pin: pin, idempotencyKey: key),
          successBuilder: (result) => PaySuccessScreen(
            eyebrow: 'PAY A MERCHANT',
            counter: '02 / 02',
            headline: 'Payment sent',
            detail: '${formatLeone(amount)} paid to $merchant.',
            rows: [('Merchant', merchant), ('Amount', formatLeone(amount)), ('Reference', result.transaction.reference)],
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      eyebrow: 'PAY A MERCHANT',
      counter: '01 / 02',
      title: 'Pay a merchant',
      subtitle: 'Scan the merchant\'s QR code or type the 6-digit code shown at the counter.',
      primaryLabel: 'Continue',
      primaryLoading: _busy,
      onPrimary: _busy ? null : _next,
      secondaryLabel: 'Back',
      onSecondary: () => Navigator.maybePop(context),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutlinedButton.icon(
              onPressed: _scan,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR code'),
            ),
            const SizedBox(height: 16),
            TpField(
              label: 'Merchant code',
              controller: _code,
              hint: '123456',
              maxLength: 6,
              digitsOnly: true,
              keyboardType: TextInputType.number,
              validator: (v) => (v ?? '').trim().length != 6 ? 'Enter the 6-digit merchant code' : null,
            ),
            const SizedBox(height: 16),
            TpField(
              label: 'Amount',
              controller: _amount,
              hint: '0.00',
              prefixText: 'Le ',
              allowDecimal: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => parseAmount(v ?? '') < 1 ? 'Enter an amount' : null,
            ),
            const SizedBox(height: 16),
            TpField(label: 'Note (optional)', controller: _note, hint: 'e.g. Order 12', maxLength: 100),
            if (_error != null) ...[const SizedBox(height: 16), ErrorBanner(_error!)],
          ],
        ),
      ),
    );
  }
}
