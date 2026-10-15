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

/// Phone POS: the merchant enters an amount and the customer's wallet number; the customer dials the
/// USSD code (or the merchant dials it for them) and approves. The payment is recorded as a POS payment
/// and paid out with the normal settlement.
class ChargeCustomerScreen extends StatefulWidget {
  const ChargeCustomerScreen({super.key});

  @override
  State<ChargeCustomerScreen> createState() => _ChargeCustomerScreenState();
}

class _ChargeCustomerScreenState extends State<ChargeCustomerScreen> with WidgetsBindingObserver {
  final _form = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String _key = newIdempotencyKey();
  Timer? _poll;
  String _wallet = '';
  bool _busy = false;
  String? _error;
  Map<String, dynamic>? _charge;

  String get _status => asStr(_charge?['status']);

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
    _note.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _status == 'Pending') _check();
  }

  Future<void> _start() async {
    if (!_form.currentState!.validate() || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final c = await api.createPosCharge(
        amount: parseAmount(_amount.text),
        number: _number.text.replaceAll(' ', ''),
        provider: _wallet,
        note: _note.text.trim(),
        idempotencyKey: _key,
      );
      if (!mounted) return;
      setState(() => _charge = c);
      if (_status == 'Pending') {
        _poll = Timer.periodic(const Duration(seconds: 4), (_) => _check());
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _check() async {
    final id = asStr(_charge?['id']);
    if (id.isEmpty || !mounted) return;
    try {
      final c = await api.posCharge(id);
      if (!mounted) return;
      setState(() => _charge = c);
      if (asStr(c['status']) != 'Pending') _poll?.cancel();
    } on ApiException {
      // Try again on the next tick.
    }
  }

  Future<void> _dial() async {
    final code = asStr(_charge?['ussdCode']);
    if (code.isEmpty) return;
    final ok = await launchUrl(Uri(scheme: 'tel', path: code));
    if (!ok && mounted) showMessage(context, 'Open your phone app and dial $code');
  }

  void _again() {
    _poll?.cancel();
    setState(() {
      _charge = null;
      _error = null;
      _amount.clear();
      _note.clear();
      _key = newIdempotencyKey(); // a new request, not a retry
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = _charge;
    if (c != null) {
      final amount = (c['amount'] as num?)?.toDouble() ?? 0;
      if (_status == 'Paid') {
        return StepScaffold(
          eyebrow: 'POS',
          title: 'Payment received',
          subtitle: '${formatLeone(amount)} from ${asStr(c['customerPhone'])}.',
          primaryLabel: 'New charge',
          onPrimary: _again,
          secondaryLabel: 'Done',
          onSecondary: () => Navigator.maybePop(context),
          child: Column(children: [
            AmountBanner(label: 'Received', value: formatLeone(amount)),
            const SizedBox(height: 12),
            DetailsCard(rows: [
              ('Reference', asStr(c['reference'])),
              ('Customer wallet', asStr(c['customerPhone'])),
              if (asStr(c['note']).isNotEmpty) ('Note', asStr(c['note'])),
            ]),
            const SizedBox(height: 12),
            const InfoBanner(text: 'This payment is added to your next settlement and paid into your TrustPay wallet.'),
          ]),
        );
      }
      if (_status == 'Pending') {
        return StepScaffold(
          eyebrow: 'POS',
          title: 'Waiting for payment',
          subtitle: 'The customer dials this code from ${asStr(c['customerPhone'])} and approves ${formatLeone(amount)}.',
          primaryLabel: 'Dial on this phone',
          onPrimary: _dial,
          secondaryLabel: 'Cancel',
          onSecondary: () {
            _poll?.cancel();
            Navigator.maybePop(context);
          },
          child: Column(children: [
            AmountBanner(label: 'Dial', value: asStr(c['ussdCode'])),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => copyText(context, asStr(c['ussdCode']), 'Code copied.'),
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copy code'),
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: CircularProgressIndicator()),
            const InfoBanner(text: 'The code works once, only from that number, and expires in about 15 minutes. This screen updates by itself when the payment arrives.'),
          ]),
        );
      }
      return StepScaffold(
        eyebrow: 'POS',
        title: _status == 'Expired' ? 'Code expired' : 'Payment not completed',
        subtitle: asStr(c['failureReason']).isEmpty ? 'No money was taken.' : asStr(c['failureReason']),
        primaryLabel: 'Try again',
        onPrimary: _again,
        secondaryLabel: 'Done',
        onSecondary: () => Navigator.maybePop(context),
        child: const SizedBox.shrink(),
      );
    }

    final providers = appState.cat.mobileMoney;
    return StepScaffold(
      eyebrow: 'POS',
      title: 'Charge a customer',
      subtitle: 'Ask your customer for their mobile money number. They approve the payment on their phone.',
      primaryLabel: 'Request payment',
      primaryLoading: _busy,
      onPrimary: _busy ? null : _start,
      secondaryLabel: 'Back',
      onSecondary: () => Navigator.maybePop(context),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Customer wallet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(children: [
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
            ]),
            const SizedBox(height: 18),
            TpField(
              label: 'Customer wallet number',
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
            const SizedBox(height: 16),
            TpField(label: 'Note (optional)', controller: _note, hint: 'e.g. 2 bags of rice', maxLength: 80),
            if (_error != null) ...[const SizedBox(height: 16), ErrorBanner(_error!)],
            const SizedBox(height: 16),
            const InfoBanner(text: 'Payments are added to your daily POS settlement. A settlement fee may apply.'),
          ],
        ),
      ),
    );
  }
}
