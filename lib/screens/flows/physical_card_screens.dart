import 'package:flutter/material.dart';

import '../../data/sample_data.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/nav.dart';
import '../../widgets/common.dart';
import '../../widgets/flow_widgets.dart';
import '../../widgets/step_scaffold.dart';
import 'generic_flow.dart';

const _states = ['Lagos', 'FCT Abuja', 'Rivers', 'Oyo', 'Kano', 'Enugu', 'Ogun', 'Kaduna'];

/// Sample fees. Replace with the amounts from your card issuer.
const double _cardFee = 1500;
const double _homeDeliveryFee = 1000;

/// Order a physical debit card: delivery details, review, PIN, confirmation.
class OrderPhysicalCardScreen extends StatefulWidget {
  const OrderPhysicalCardScreen({super.key});

  @override
  State<OrderPhysicalCardScreen> createState() => _OrderPhysicalCardScreenState();
}

class _OrderPhysicalCardScreenState extends State<OrderPhysicalCardScreen> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController(text: kPhone);
  final _address = TextEditingController();
  final _city = TextEditingController();
  String _state = _states.first;
  bool _home = true;

  @override
  void dispose() {
    _phone.dispose();
    _address.dispose();
    _city.dispose();
    super.dispose();
  }

  double get _delivery => _home ? _homeDeliveryFee : 0;

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  void _review() {
    if (!_form.currentState!.validate()) return;
    final total = _cardFee + _delivery;
    final where = _home ? '${_address.text.trim()}, ${_city.text.trim()}, $_state' : 'Pick up at a TrustPay branch ($_state)';
    final method = _home ? 'Home delivery' : 'Branch pickup';

    openScreen(
      context,
      PayConfirmScreen(
        eyebrow: 'CARDS · PHYSICAL CARD',
        counter: '02 / 03',
        title: 'Confirm card order',
        bannerLabel: 'Card ${formatNaira(_cardFee, decimals: 0)} + delivery ${formatNaira(_delivery, decimals: 0)}',
        total: total,
        referenceCode: 'PCD',
        payLabel: 'Order for',
        notice: 'Your card arrives inactive. You will activate it with your PIN.',
        rows: [
          ('Name on card', kAccountName.toUpperCase()),
          ('Method', method),
          ('Delivery to', where),
          ('Contact', _phone.text.trim()),
          ('Balance after', formatNaira(kAccountBalance - total)),
        ],
        successBuilder: (reference) => PaySuccessScreen(
          eyebrow: 'CARDS · PHYSICAL CARD',
          counter: '03 / 03',
          headline: 'Card ordered',
          detail: _home ? 'Expected in 3 to 5 working days' : 'We will text you when it is ready to collect',
          extra: const _PhysicalCardArt(),
          notice: 'Track your order with the reference below.',
          rows: [
            ('Method', method),
            ('Total paid', formatNaira(total)),
            ('Reference', reference),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      eyebrow: 'CARDS · PHYSICAL CARD',
      counter: '01 / 03',
      title: 'Order a physical card',
      subtitle: 'A TrustPay debit card for shops, ATMs and online.',
      headerLabel: 'Cancel',
      onHeaderAction: () => goHome(context),
      primaryLabel: 'Review order',
      onPrimary: _review,
      secondaryLabel: 'Back to cards',
      onSecondary: () => Navigator.maybePop(context),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PhysicalCardArt(),
            const SizedBox(height: 18),
            SegmentedTabs(
              labels: const ['Home delivery', 'Branch pickup'],
              index: _home ? 0 : 1,
              onChanged: (i) => setState(() => _home = i == 0),
            ),
            const SizedBox(height: 16),
            const Text('State', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _state,
              items: [for (final s in _states) DropdownMenuItem(value: s, child: Text(s))],
              onChanged: (v) => setState(() => _state = v ?? _state),
              decoration: tpDecoration(),
            ),
            if (_home) ...[
              const SizedBox(height: 16),
              TpField(label: 'Street address', controller: _address, hint: '24 Allen Avenue', validator: _required),
              const SizedBox(height: 16),
              TpField(label: 'City / town', controller: _city, hint: 'Ikeja', validator: _required),
            ],
            const SizedBox(height: 16),
            TpField(
              label: 'Phone for the courier',
              controller: _phone,
              keyboardType: TextInputType.phone,
              validator: _required,
            ),
            const SizedBox(height: 14),
            Text(
              'Card ${formatNaira(_cardFee)} · Delivery ${formatNaira(_delivery)} · Total ${formatNaira(_cardFee + _delivery)}',
              style: const TextStyle(fontSize: 13, color: TpColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// A drawn debit card. It carries no card scheme logo.
class _PhysicalCardArt extends StatelessWidget {
  const _PhysicalCardArt();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.586,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF14233F), Color(0xFF0560E4)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: TpShadows.glow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TrustPay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                Container(
                  width: 40,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFFD36B), Color(0xFFE0A93B)]),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Text(
              '••••  ••••  ••••  ••••',
              style: TextStyle(fontSize: 18, letterSpacing: 2, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              kAccountName.toUpperCase(),
              style: const TextStyle(fontSize: 13, letterSpacing: 1, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
