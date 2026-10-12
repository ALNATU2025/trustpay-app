import 'package:flutter/material.dart';

import '../../data/sample_data.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/nav.dart';
import '../../widgets/common.dart';
import '../../widgets/flow_widgets.dart';
import '../../widgets/otp_input.dart';
import '../../widgets/step_scaffold.dart';

bool _isOwnNumber(String phone) =>
    phone.replaceAll(' ', '') == kPhone.replaceAll(' ', '');

/// Airtime & data 1/3: service, network and phone number.
class AirtimeDataScreen extends StatefulWidget {
  const AirtimeDataScreen({super.key});

  @override
  State<AirtimeDataScreen> createState() => _AirtimeDataScreenState();
}

class _AirtimeDataScreenState extends State<AirtimeDataScreen> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController(text: kPhone);
  int _tab = 1; // 0 airtime, 1 data
  String _network = kNetworks.first;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_form.currentState!.validate()) return;
    final phone = _phone.text.trim();
    openScreen(
      context,
      _tab == 0
          ? BuyAirtimeScreen(network: _network, phone: phone)
          : BuyDataScreen(network: _network, phone: phone),
    );
  }

  @override
  Widget build(BuildContext context) {
    final own = _isOwnNumber(_phone.text);
    return StepScaffold(
      eyebrow: 'AIRTIME & DATA · FROM SERVICES',
      counter: '01 / 03',
      title: 'Stay connected',
      subtitle: 'Choose a service, network and phone number.',
      headerLabel: 'Cancel',
      onHeaderAction: () => goHome(context),
      primaryLabel: 'Continue with ${_tab == 0 ? 'Airtime' : 'Data'}',
      onPrimary: _continue,
      secondaryLabel: 'Back to home',
      onSecondary: () => goHome(context),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedTabs(
              labels: const ['Airtime', 'Data'],
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: 20),
            const Text('Select network', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(
              children: [
                for (var i = 0; i < kNetworks.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceBox(
                      label: kNetworks[i],
                      selected: kNetworks[i] == _network,
                      onTap: () => setState(() => _network = kNetworks[i]),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            TpField(
              label: 'Phone number',
              controller: _phone,
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() {}),
              suffix: const Icon(Icons.contacts_outlined, color: TpColors.primary),
              validator: (v) {
                final digits = (v ?? '').replaceAll(' ', '');
                return digits.length == 11 ? null : 'Enter an 11-digit phone number';
              },
            ),
            if (own) ...[
              const SizedBox(height: 8),
              Text(
                'Ada’s number · $_network Nigeria',
                style: const TextStyle(fontSize: 13, color: TpColors.muted),
              ),
            ],
            const SizedBox(height: 16),
            const InfoBanner(
              text: 'Confirm the number before paying. Top-ups cannot be reversed once delivered.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Airtime: choose an amount · Data: choose a bundle',
              style: TextStyle(fontSize: 14, color: TpColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

String _recipientLine(String network, String phone) =>
    '$network · $phone${_isOwnNumber(phone) ? ' · Ada' : ''}';

/// Airtime 2/3: amount and PIN.
class BuyAirtimeScreen extends StatefulWidget {
  const BuyAirtimeScreen({super.key, required this.network, required this.phone});

  final String network;
  final String phone;

  @override
  State<BuyAirtimeScreen> createState() => _BuyAirtimeScreenState();
}

class _BuyAirtimeScreenState extends State<BuyAirtimeScreen> {
  static const _quick = [500, 1000, 2000, 5000];

  final _amount = TextEditingController(text: '2000');
  String _pin = '';

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  double get _value => parseAmount(_amount.text);

  bool get _valid => _value > 0 && _value <= kAccountBalance && _pin.length == 4;

  void _pay() {
    // TODO: verify the PIN and buy airtime with your API.
    replaceScreen(
      context,
      PurchaseSuccessScreen(
        isData: false,
        network: widget.network,
        phone: widget.phone,
        amount: _value,
        reference: makeReference('AIR'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      eyebrow: 'AIRTIME & DATA · AIRTIME PATH',
      counter: '02 / 03',
      title: 'Buy airtime',
      subtitle: _recipientLine(widget.network, widget.phone),
      headerLabel: 'Cancel',
      onHeaderAction: () => goHome(context),
      primaryLabel: 'Pay ${formatNaira(_value)}',
      onPrimary: _valid ? _pay : null,
      secondaryLabel: 'Back to service selection',
      onSecondary: () => Navigator.maybePop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TpField(
            label: 'Airtime amount',
            controller: _amount,
            hint: '0.00',
            prefixText: '₦',
            allowDecimal: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < _quick.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: _QuickAmount(
                    amount: _quick[i],
                    selected: _value == _quick[i],
                    onTap: () => setState(() => _amount.text = '${_quick[i]}'),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          DetailsCard(
            rows: [
              ('Product', '${widget.network} airtime'),
              ('Recipient', widget.phone),
              ('Amount / fee', '${formatNaira(_value)} / ${formatNaira(0)}'),
              ('Total debit', formatNaira(_value)),
              ('Balance after', formatNaira(kAccountBalance - _value)),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Authorize with transaction PIN',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          OtpInput(length: 4, obscure: true, onChanged: (v) => setState(() => _pin = v)),
          const SizedBox(height: 16),
          const InfoBanner(
            text: 'Review complete. Your airtime will be delivered immediately after payment.',
          ),
        ],
      ),
    );
  }
}

class _QuickAmount extends StatelessWidget {
  const _QuickAmount({required this.amount, required this.selected, required this.onTap});

  final int amount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? TpColors.tint : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(
            height: 44,
            child: Center(
              child: Text(
                formatNaira(amount, decimals: 0),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: selected ? TpColors.primary : TpColors.muted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Data 2/3: bundle and PIN.
class BuyDataScreen extends StatefulWidget {
  const BuyDataScreen({super.key, required this.network, required this.phone});

  final String network;
  final String phone;

  @override
  State<BuyDataScreen> createState() => _BuyDataScreenState();
}

class _BuyDataScreenState extends State<BuyDataScreen> {
  int _plan = 1;
  String _pin = '';

  DataPlan get _selected => kDataPlans[_plan];

  void _pay() {
    // TODO: verify the PIN and buy the bundle with your API.
    replaceScreen(
      context,
      PurchaseSuccessScreen(
        isData: true,
        network: widget.network,
        phone: widget.phone,
        amount: _selected.price,
        plan: _selected,
        reference: makeReference('DAT'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = _selected;
    return StepScaffold(
      eyebrow: 'AIRTIME & DATA · DATA PATH',
      counter: '02 / 03',
      title: 'Choose your data plan',
      subtitle: _recipientLine(widget.network, widget.phone),
      headerLabel: 'Cancel',
      onHeaderAction: () => goHome(context),
      primaryLabel: 'Pay ${formatNaira(plan.price)}',
      onPrimary: _pin.length == 4 ? _pay : null,
      secondaryLabel: 'Back to service selection',
      onSecondary: () => Navigator.maybePop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < kDataPlans.length; i++) ...[
            _PlanTile(
              plan: kDataPlans[i],
              selected: i == _plan,
              onTap: () => setState(() => _plan = i),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
          Text(
            'Fee ${formatNaira(0)} · Total ${formatNaira(plan.price)}\n'
            'Balance after purchase: ${formatNaira(kAccountBalance - plan.price)}',
            style: const TextStyle(fontSize: 14, height: 1.45, color: TpColors.muted),
          ),
          const SizedBox(height: 20),
          const Text(
            'Authorize with transaction PIN',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          OtpInput(length: 4, obscure: true, onChanged: (v) => setState(() => _pin = v)),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan, required this.selected, required this.onTap});

  final DataPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? TpColors.primary : TpColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.size, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(plan.validity, style: const TextStyle(fontSize: 13, color: TpColors.muted)),
                    ],
                  ),
                ),
                Text(
                  formatNaira(plan.price),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 10),
                Icon(
                  selected ? Icons.check_circle_outline : Icons.radio_button_unchecked,
                  color: selected ? TpColors.primary : TpColors.dot,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Step 3/3 for airtime and data.
class PurchaseSuccessScreen extends StatelessWidget {
  const PurchaseSuccessScreen({
    super.key,
    required this.isData,
    required this.network,
    required this.phone,
    required this.amount,
    required this.reference,
    this.plan,
  });

  final bool isData;
  final String network;
  final String phone;
  final double amount;
  final String reference;
  final DataPlan? plan;

  @override
  Widget build(BuildContext context) {
    final p = plan;
    final expiry = p == null ? null : DateTime.now().add(Duration(days: p.days));
    final rows = <(String, String)>[
      (
        'Selected product',
        isData && p != null ? '$network Data · ${p.size}' : '$network airtime',
      ),
      if (isData && expiry != null) ('Validity', '${p!.days} days · to ${formatShortDate(expiry)}'),
      ('Phone number', phone),
      ('Amount / fee', '${formatNaira(amount)} / ${formatNaira(0)}'),
      ('Total paid', formatNaira(amount)),
      ('Reference', reference),
    ];

    return StepScaffold(
      eyebrow: 'AIRTIME & DATA · SHARED CONFIRMATION',
      counter: '03 / 03',
      title: 'Purchase successful',
      headerLabel: 'Done',
      onBack: () => goHome(context),
      onHeaderAction: () => goHome(context),
      primaryLabel: 'Share receipt',
      // TODO: share the receipt (for example with the share_plus package).
      onPrimary: () => showMessage(context, 'Sharing is not connected yet.'),
      secondaryLabel: 'Back to home',
      onSecondary: () => goHome(context),
      child: Column(
        children: [
          SegmentedTabs(labels: const ['Airtime', 'Data'], index: isData ? 1 : 0),
          const SizedBox(height: 20),
          ResultHeader(
            headline: isData ? 'Your data is ready' : 'Your airtime is ready',
            detail: isData && p != null
                ? '${p.size} has been delivered to $phone.'
                : '${formatNaira(amount)} has been delivered to $phone.',
          ),
          const SizedBox(height: 20),
          DetailsCard(rows: rows),
          const SizedBox(height: 12),
          InfoBanner(
            icon: Icons.check_circle_outline,
            background: TpColors.greenTint,
            accent: TpColors.green,
            textColor: TpColors.green,
            text: 'Available balance · ${formatNaira(kAccountBalance - amount)}',
          ),
        ],
      ),
    );
  }
}
