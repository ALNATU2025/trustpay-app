import 'package:flutter/material.dart';

import '../../services/app_state.dart';
import '../../services/trustpay_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/nav.dart';
import '../../widgets/common.dart';
import '../../widgets/flow_widgets.dart';
import '../../widgets/step_scaffold.dart';
import 'generic_flow.dart';

/// Order a physical debit card: delivery details, review, PIN, confirmation.
class OrderPhysicalCardScreen extends StatefulWidget {
  const OrderPhysicalCardScreen({super.key});

  @override
  State<OrderPhysicalCardScreen> createState() => _OrderPhysicalCardScreenState();
}

class _OrderPhysicalCardScreenState extends State<OrderPhysicalCardScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(text: appState.me.fullName.toUpperCase());
  final _phone = TextEditingController(text: appState.me.phone);
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _stateText = TextEditingController();
  late String _state = appState.cat.districts.isEmpty ? '' : appState.cat.districts.first;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _city.dispose();
    _stateText.dispose();
    super.dispose();
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  void _review() {
    if (!_form.currentState!.validate()) return;
    final fee = appState.cat.fees.physicalCard;
    if (fee > appState.balance) {
      showMessage(context, 'Insufficient balance for the card fee.');
      return;
    }
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    final address = _address.text.trim();
    final city = _city.text.trim();
    final state = appState.cat.districts.isEmpty ? _stateText.text.trim() : _state;

    openScreen(
      context,
      PayConfirmScreen(
        eyebrow: 'CARDS · PHYSICAL CARD',
        counter: '02 / 03',
        title: 'Confirm card order',
        bannerLabel: 'Physical card fee',
        total: fee,
        payLabel: 'Order for',
        notice: 'Your card arrives inactive. You will activate it with your PIN.',
        rows: [
          ('Name on card', name),
          ('Delivery to', '$address, $city, $state'),
          ('Contact', phone),
          ('Balance after', formatLeone(appState.balance - fee)),
        ],
        onPay: (pin, key) => api.orderPhysicalCard(
          name: name,
          phone: phone,
          address: address,
          city: city,
          state: state,
          pin: pin,
          idempotencyKey: key,
        ),
        successBuilder: (result) {
          final txn = result.transaction;
          final pending = isPending(txn);
          final reference = _requestReference(result.request) ?? txn.reference;
          final status = result.card?.status ?? '';
          return PaySuccessScreen(
            eyebrow: 'CARDS · PHYSICAL CARD',
            counter: '03 / 03',
            headline: pending ? 'Card order is being processed' : 'Card ordered',
            detail: 'We will contact you when it ships.',
            extra: _PhysicalCardArt(name: name),
            notice: 'Track your order with the reference below.',
            rows: [
              ('Name on card', name),
              ('Delivery to', '$address, $city, $state'),
              if (status.isNotEmpty) ('Card status', status),
              ('Total paid', formatLeone(fee)),
              if (reference.isNotEmpty) ('Reference', reference),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fee = appState.cat.fees.physicalCard;
    final districts = appState.cat.districts;
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
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _name,
              builder: (context, value, _) => _PhysicalCardArt(name: value.text.trim()),
            ),
            const SizedBox(height: 18),
            TpField(label: 'Name on card', controller: _name, validator: _required),
            const SizedBox(height: 16),
            if (districts.isEmpty)
              TpField(label: 'District or state', controller: _stateText, validator: _required)
            else
              TpDropdown(
                label: 'District or state',
                value: _state,
                items: districts,
                onChanged: (v) => setState(() => _state = v),
              ),
            const SizedBox(height: 16),
            TpField(label: 'Street address', controller: _address, hint: 'House number and street', validator: _required),
            const SizedBox(height: 16),
            TpField(label: 'City / town', controller: _city, validator: _required),
            const SizedBox(height: 16),
            TpField(
              label: 'Phone for the courier',
              controller: _phone,
              keyboardType: TextInputType.phone,
              validator: _required,
            ),
            const SizedBox(height: 14),
            Text(
              'Card fee ${formatLeone(fee)} · ${balanceLine()}',
              style: const TextStyle(fontSize: 13, color: TpColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Request reference from the order response, if the server sent one.
String? _requestReference(Map<String, dynamic> request) {
  final ref = request['reference'];
  return ref == null || '$ref'.isEmpty ? null : '$ref';
}

/// A drawn debit card. It carries no card scheme logo.
class _PhysicalCardArt extends StatelessWidget {
  const _PhysicalCardArt({required this.name});

  final String name;

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
              name.toUpperCase(),
              style: const TextStyle(fontSize: 13, letterSpacing: 1, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
