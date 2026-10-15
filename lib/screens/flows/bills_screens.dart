import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api.dart';
import '../../services/app_state.dart';
import '../../services/trustpay_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/debounce.dart';
import '../../utils/format.dart';
import '../../utils/nav.dart';
import '../../widgets/common.dart';
import '../../widgets/flow_widgets.dart';
import '../../widgets/step_scaffold.dart';
import 'generic_flow.dart';
import 'tv_internet_screens.dart';

/// Bills 1/4: category and provider.
class PayBillScreen extends StatefulWidget {
  const PayBillScreen({super.key, this.initialCategory = 0});

  /// 0 Electricity, 1 TV, 2 Internet.
  final int initialCategory;

  @override
  State<PayBillScreen> createState() => _PayBillScreenState();
}

class _PayBillScreenState extends State<PayBillScreen> {
  static const _categories = ['Electricity', 'TV', 'Internet'];
  static const _icons = [Icons.flash_on_outlined, Icons.tv_outlined, Icons.wifi];

  late int _category = widget.initialCategory;
  String _query = '';
  BillProvider? _selected;

  List<BillProvider> get _providers => switch (_category) {
        1 => appState.cat.tv,
        2 => appState.cat.internet,
        _ => appState.cat.electricity,
      };

  @override
  void initState() {
    super.initState();
    _selected = _providers.isEmpty ? null : _providers.first;
  }

  void _continue() {
    final selected = _selected;
    if (selected == null) return;
    if (_category != 0) {
      openScreen(context, TvInternetScreen(provider: selected, isTv: _category == 1));
      return;
    }
    openScreen(context, ElectricityScreen(providerName: selected.name));
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final list = _providers.where((p) => q.isEmpty || p.name.toLowerCase().contains(q)).toList();
    final categoryName = _categories[_category];
    final selected = _selected;

    return StepScaffold(
      eyebrow: 'BILLS · FROM HOME / SERVICES',
      counter: '01 / 04',
      title: 'Pay a bill',
      subtitle: 'Choose a category and your provider.',
      headerLabel: 'Cancel',
      onHeaderAction: () => goHome(context),
      primaryLabel: selected == null ? 'Continue' : 'Continue with ${selected.name}',
      onPrimary: selected == null ? null : _continue,
      secondaryLabel: 'Back to home',
      onSecondary: () => goHome(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < _categories.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(
                  child: ChoiceBox(
                    label: _categories[i],
                    icon: _icons[i],
                    selected: i == _category,
                    onTap: () => setState(() {
                      _category = i;
                      _selected = _providers.isEmpty ? null : _providers.first;
                      _query = '';
                    }),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Search ${categoryName.toLowerCase()} providers',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: tpDecoration(
              hint: 'Search by provider name',
              suffix: const Icon(Icons.search, color: TpColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          if (list.isEmpty)
            Text(
              _providers.isEmpty
                  ? 'No $categoryName providers are available right now.'
                  : 'No provider matches your search.',
              style: const TextStyle(fontSize: 14, color: TpColors.muted),
            ),
          for (final p in list) ...[
            SelectTile(
              icon: _icons[_category],
              title: p.name,
              subtitle: p.subtitle,
              selected: p.name == selected?.name,
              onTap: () => setState(() => _selected = p),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

/// Bills 2/4: meter details.
class ElectricityScreen extends StatefulWidget {
  const ElectricityScreen({super.key, required this.providerName});

  final String providerName;

  @override
  State<ElectricityScreen> createState() => _ElectricityScreenState();
}

class _ElectricityScreenState extends State<ElectricityScreen> {
  final _form = GlobalKey<FormState>();
  final _meter = TextEditingController();
  final _amount = TextEditingController();
  final _phone = TextEditingController(text: appState.me.phone);
  final _debounce = Debouncer();
  bool _prepaid = true;
  MeterInfo? _info;
  String? _lookupError;
  bool _verifying = false;
  int _lookupId = 0;

  @override
  void dispose() {
    _debounce.dispose();
    _meter.dispose();
    _amount.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _onMeterChanged() {
    _debounce.cancel();
    final id = ++_lookupId;
    setState(() {
      _info = null;
      _lookupError = null;
      _verifying = _meter.text.length == 11;
    });
    if (_meter.text.length != 11) return;
    _debounce.run(() => _validateMeter(id));
  }

  Future<void> _validateMeter(int id) async {
    try {
      final info = await api.lookupMeter(widget.providerName, _meter.text);
      if (!mounted || id != _lookupId) return;
      setState(() {
        _info = info;
        _lookupError = info == null ? 'We could not find this meter. Check the number.' : null;
        _verifying = false;
      });
    } on ApiException catch (e) {
      if (!mounted || id != _lookupId) return;
      setState(() {
        _lookupError = e.message;
        _verifying = false;
      });
    }
  }

  double get _amountValue => parseAmount(_amount.text);

  void _review() {
    if (!_form.currentState!.validate()) return;
    final info = _info;
    if (info == null) {
      showMessage(context, 'Enter a valid meter number first.');
      return;
    }
    openScreen(
      context,
      ConfirmBillScreen(
        draft: BillDraft(
          provider: widget.providerName,
          prepaid: _prepaid,
          meter: _meter.text,
          customer: info.name,
          amount: _amountValue,
          phone: _phone.text.trim(),
          fee: appState.cat.fees.bill,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fee = appState.cat.fees.bill;
    return StepScaffold(
      eyebrow: 'BILLS · ELECTRICITY',
      counter: '02 / 04',
      title: 'Electricity payment',
      subtitle: '${widget.providerName} · Enter your meter details.',
      headerLabel: 'Done',
      onHeaderAction: () => goHome(context),
      primaryLabel: 'Review payment',
      onPrimary: _review,
      secondaryLabel: 'Back to providers',
      onSecondary: () => Navigator.maybePop(context),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedTabs(
              labels: const ['Prepaid', 'Postpaid'],
              index: _prepaid ? 0 : 1,
              onChanged: (i) => setState(() => _prepaid = i == 0),
            ),
            const SizedBox(height: 16),
            TpField(
              label: 'Meter number',
              controller: _meter,
              hint: '11-digit meter number',
              keyboardType: TextInputType.number,
              digitsOnly: true,
              maxLength: 11,
              onChanged: (_) => _onMeterChanged(),
              validator: (v) => (v == null || v.length != 11) ? 'Enter all 11 digits' : null,
            ),
            const SizedBox(height: 10),
            if (_info != null)
              InfoBanner(
                icon: Icons.check_circle_outline,
                background: TpColors.greenTint,
                accent: TpColors.green,
                textColor: TpColors.green,
                text: _info!.address.isEmpty
                    ? 'Customer validated · ${_info!.name}'
                    : 'Customer validated · ${_info!.name}\n${_info!.address}',
              )
            else if (_lookupError != null)
              InfoBanner(
                icon: Icons.error_outline,
                background: const Color(0xFFFDECEC),
                accent: TpColors.danger,
                textColor: TpColors.danger,
                text: _lookupError!,
              )
            else if (_verifying)
              const Text(
                'Validating meter…',
                style: TextStyle(fontSize: 13, color: TpColors.muted),
              ),
            const SizedBox(height: 16),
            TpField(
              label: 'Payment amount',
              controller: _amount,
              hint: '0.00',
              prefixText: 'Le ',
              allowDecimal: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final a = parseAmount(v ?? '');
                if (a <= 0) return 'Enter an amount';
                if (a + fee > appState.balance) return 'Insufficient balance';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TpField(
              label: _prepaid ? 'Phone for token delivery' : 'Phone for the receipt',
              controller: _phone,
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            Text(
              'Fee ${formatLeone(fee)} · Total debit ${formatLeone(_amountValue + fee)}\n'
              '${balanceLine()}\n'
              '${_prepaid ? 'Your electricity token will appear on the receipt.' : 'Your payment will be applied to your account.'}',
              style: const TextStyle(fontSize: 13, height: 1.4, color: TpColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bills 3/4: review and PIN.
class ConfirmBillScreen extends StatelessWidget {
  const ConfirmBillScreen({super.key, required this.draft});

  final BillDraft draft;

  @override
  Widget build(BuildContext context) {
    final d = draft;
    return PayConfirmScreen(
      eyebrow: 'BILLS · ELECTRICITY',
      counter: '03 / 04',
      title: 'Confirm bill payment',
      bannerLabel: 'Total debit · includes ${formatLeone(d.fee)} fee',
      total: d.total,
      notice: 'Check the meter number. Tokens are only valid for the meter paid for.',
      rows: [
        ('Provider', '${d.provider} · ${d.typeLabel}'),
        ('Customer', _titleCase(d.customer)),
        ('Meter number', d.meter),
        ('Amount / fee', '${formatLeone(d.amount)} / ${formatLeone(d.fee)}'),
        ('Token delivery', d.phone),
        ('Balance after', formatLeone(appState.balance - d.total)),
      ],
      onPay: (pin, key) => api.payElectricity(
        provider: d.provider,
        prepaid: d.prepaid,
        meter: d.meter,
        customer: d.customer,
        amount: d.amount,
        phone: d.phone,
        pin: pin,
        idempotencyKey: key,
      ),
      successBuilder: (result) => BillSuccessScreen(draft: d, result: result),
    );
  }
}

String _titleCase(String s) => s
    .toLowerCase()
    .split(' ')
    .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');

/// Bills 4/4: result with the electricity token.
class BillSuccessScreen extends StatelessWidget {
  const BillSuccessScreen({super.key, required this.draft, required this.result});

  final BillDraft draft;
  final PaymentResult result;

  @override
  Widget build(BuildContext context) {
    final txn = result.transaction;
    final pending = isPending(txn);
    final token = txn.token;
    return StepScaffold(
      eyebrow: 'BILLS · ELECTRICITY',
      counter: '04 / 04',
      title: pending ? 'Payment pending' : 'Payment successful',
      headerLabel: 'Done',
      onBack: () => goHome(context),
      onHeaderAction: () => goHome(context),
      primaryLabel: 'Copy receipt',
      onPrimary: () => copyReceipt(context, txn),
      secondaryLabel: 'Back to home',
      onSecondary: () => goHome(context),
      child: Column(
        children: [
          ResultHeader(
            headline: pending ? '${formatLeone(draft.amount)} being processed' : '${formatLeone(draft.amount)} paid',
            detail: '${draft.provider} · ${draft.typeLabel} meter ${draft.meter}',
          ),
          if (token != null && token.isNotEmpty) ...[
            const SizedBox(height: 20),
            AmountBanner(
              label: 'Electricity token',
              value: token,
              background: TpColors.tint,
              labelColor: TpColors.muted,
              valueColor: TpColors.navy,
              valueSize: 22,
              center: true,
              child: TpWhiteButton(
                label: 'Copy token',
                icon: Icons.copy_outlined,
                onPressed: () => copyText(context, token.replaceAll(' ', ''), 'Token copied.'),
              ),
            ),
          ],
          const SizedBox(height: 12),
          DetailsCard(rows: receiptRows(txn)),
          const SizedBox(height: 12),
          InfoBanner(
            icon: pending ? Icons.schedule : Icons.check_circle_outline,
            background: TpColors.greenTint,
            accent: TpColors.green,
            textColor: TpColors.green,
            text: pending
                ? 'The provider has not confirmed yet. ${draft.prepaid ? 'Your token will show in Transactions once it is ready. ' : ''}Balance ${formatLeone(result.balance)}'
                : 'Balance ${formatLeone(result.balance)}',
          ),
        ],
      ),
    );
  }
}
