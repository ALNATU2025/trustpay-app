import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/app_state.dart';
import '../../services/trustpay_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/nav.dart';
import '../../widgets/common.dart';
import '../../widgets/flow_widgets.dart';
import '../../widgets/step_scaffold.dart';
import 'generic_flow.dart';

bool _isOwnNumber(String phone) => samePhone(phone, appState.me.phone);

/// Airtime & data 1/3: service, network and phone number.
class AirtimeDataScreen extends StatefulWidget {
  const AirtimeDataScreen({super.key});

  @override
  State<AirtimeDataScreen> createState() => _AirtimeDataScreenState();
}

class _AirtimeDataScreenState extends State<AirtimeDataScreen> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController(text: appState.me.phone);
  int _tab = 1; // 0 airtime, 1 data
  String _network = appState.cat.networks.isEmpty ? '' : appState.cat.networks.first;

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
    final networks = appState.cat.networks;
    return StepScaffold(
      eyebrow: 'AIRTIME & DATA · FROM SERVICES',
      counter: '01 / 03',
      title: 'Stay connected',
      subtitle: 'Choose a service, network and phone number.',
      headerLabel: 'Cancel',
      onHeaderAction: () => goHome(context),
      primaryLabel: 'Continue with ${_tab == 0 ? 'Airtime' : 'Data'}',
      onPrimary: _network.isEmpty ? null : _continue,
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
                for (var i = 0; i < networks.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceBox(
                      label: networks[i],
                      selected: networks[i] == _network,
                      onTap: () => setState(() => _network = networks[i]),
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
                final digits = digitsOf(v ?? '');
                return digits.length >= 8 && digits.length <= 12 ? null : 'Enter a valid phone number';
              },
            ),
            if (own) ...[
              const SizedBox(height: 8),
              Text(
                'Your number · $_network Sierra Leone',
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
    '$network · $phone${_isOwnNumber(phone) ? ' · Your number' : ''}';

/// Airtime 2/3: amount and PIN.
class BuyAirtimeScreen extends StatefulWidget {
  const BuyAirtimeScreen({super.key, required this.network, required this.phone});

  final String network;
  final String phone;

  @override
  State<BuyAirtimeScreen> createState() => _BuyAirtimeScreenState();
}

class _BuyAirtimeScreenState extends State<BuyAirtimeScreen> {
  static const _quick = [20, 50, 100, 200];

  final _amount = TextEditingController(text: '100');

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  double get _value => parseAmount(_amount.text);

  bool get _valid => _value > 0 && _value <= appState.balance;

  void _review() {
    final amount = _value;
    final network = widget.network;
    final phone = widget.phone;
    openScreen(
      context,
      PayConfirmScreen(
        eyebrow: 'AIRTIME & DATA · AIRTIME PATH',
        counter: '02 / 03',
        title: 'Confirm airtime',
        bannerLabel: '$network airtime',
        total: amount,
        notice: 'Confirm the number. Top-ups cannot be reversed once delivered.',
        rows: [
          ('Product', '$network airtime'),
          ('Recipient', phone),
          ('Amount', formatLeone(amount)),
          ('Balance after', formatLeone(appState.balance - amount)),
        ],
        onPay: (pin, key) => api.buyAirtime(
          network: network,
          phone: phone,
          amount: amount,
          pin: pin,
          idempotencyKey: key,
        ),
        successBuilder: (result) => PurchaseSuccessScreen(
          isData: false,
          network: network,
          phone: phone,
          amount: amount,
          result: result,
        ),
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
      primaryLabel: 'Review ${formatLeone(_value)}',
      onPrimary: _valid ? _review : null,
      secondaryLabel: 'Back to service selection',
      onSecondary: () => Navigator.maybePop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TpField(
            label: 'Airtime amount',
            controller: _amount,
            hint: '0.00',
            prefixText: 'Le ',
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
          Text(
            '${balanceLine()}${_value > appState.balance ? ' · Insufficient balance' : ''}',
            style: const TextStyle(fontSize: 13, color: TpColors.muted),
          ),
          const SizedBox(height: 16),
          const InfoBanner(
            text: 'You will review the details and enter your PIN on the next step.',
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
                formatLeone(amount, decimals: 0),
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
  int _plan = 0;

  List<DataPlan> get _plans => appState.cat.dataPlans;

  void _review() {
    if (_plans.isEmpty) return;
    final plan = _plans[_plan];
    if (plan.price > appState.balance) {
      showMessage(context, 'Insufficient balance for this bundle.');
      return;
    }
    final network = widget.network;
    final phone = widget.phone;
    openScreen(
      context,
      PayConfirmScreen(
        eyebrow: 'AIRTIME & DATA · DATA PATH',
        counter: '02 / 03',
        title: 'Confirm data bundle',
        bannerLabel: '$network ${plan.size}',
        total: plan.price,
        notice: 'Confirm the number. Bundles cannot be reversed once delivered.',
        rows: [
          ('Product', '$network Data · ${plan.size}'),
          ('Validity', plan.validity),
          ('Recipient', phone),
          ('Amount', formatLeone(plan.price)),
          ('Balance after', formatLeone(appState.balance - plan.price)),
        ],
        onPay: (pin, key) => api.buyData(
          network: network,
          phone: phone,
          planId: plan.id,
          pin: pin,
          idempotencyKey: key,
        ),
        successBuilder: (result) => PurchaseSuccessScreen(
          isData: true,
          network: network,
          phone: phone,
          amount: plan.price,
          plan: plan,
          result: result,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plans = _plans;
    final plan = plans.isEmpty ? null : plans[_plan];
    return StepScaffold(
      eyebrow: 'AIRTIME & DATA · DATA PATH',
      counter: '02 / 03',
      title: 'Choose your data plan',
      subtitle: _recipientLine(widget.network, widget.phone),
      headerLabel: 'Cancel',
      onHeaderAction: () => goHome(context),
      primaryLabel: plan == null ? 'Review' : 'Review ${formatLeone(plan.price)}',
      onPrimary: plan == null ? null : _review,
      secondaryLabel: 'Back to service selection',
      onSecondary: () => Navigator.maybePop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plans.isEmpty)
            const Text('No data bundles are available right now.', style: TextStyle(fontSize: 14, color: TpColors.muted)),
          for (var i = 0; i < plans.length; i++) ...[
            _PlanTile(
              plan: plans[i],
              selected: i == _plan,
              onTap: () => setState(() => _plan = i),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
          if (plan != null)
            Text(
              'Total ${formatLeone(plan.price)} · ${balanceLine()}',
              style: const TextStyle(fontSize: 14, height: 1.45, color: TpColors.muted),
            ),
          const SizedBox(height: 16),
          const InfoBanner(
            text: 'You will review the details and enter your PIN on the next step.',
          ),
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
                  formatLeone(plan.price),
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
    required this.result,
    this.plan,
  });

  final bool isData;
  final String network;
  final String phone;
  final double amount;
  final PaymentResult result;
  final DataPlan? plan;

  @override
  Widget build(BuildContext context) {
    final p = plan;
    final txn = result.transaction;
    final pending = isPending(txn);
    final what = isData && p != null ? p.size : formatLeone(amount);

    return StepScaffold(
      eyebrow: 'AIRTIME & DATA · SHARED CONFIRMATION',
      counter: '03 / 03',
      title: pending ? 'Purchase pending' : 'Purchase successful',
      headerLabel: 'Done',
      onBack: () => goHome(context),
      onHeaderAction: () => goHome(context),
      primaryLabel: 'Copy receipt',
      onPrimary: () => copyReceipt(context, txn),
      secondaryLabel: 'Back to home',
      onSecondary: () => goHome(context),
      child: Column(
        children: [
          SegmentedTabs(labels: const ['Airtime', 'Data'], index: isData ? 1 : 0),
          const SizedBox(height: 20),
          ResultHeader(
            headline: pending
                ? 'Your ${isData ? 'data' : 'airtime'} is being processed'
                : (isData ? 'Your data is ready' : 'Your airtime is ready'),
            detail: pending
                ? '$what for $phone is pending. We will update it in Transactions once $network confirms.'
                : '$what has been delivered to $phone.',
          ),
          const SizedBox(height: 20),
          DetailsCard(rows: receiptRows(txn)),
          const SizedBox(height: 12),
          InfoBanner(
            icon: pending ? Icons.schedule : Icons.check_circle_outline,
            background: TpColors.greenTint,
            accent: TpColors.green,
            textColor: TpColors.green,
            text: 'Available balance · ${formatLeone(result.balance)}',
          ),
        ],
      ),
    );
  }
}
