import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/sample_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/nav.dart';
import '../../widgets/common.dart';
import '../../widgets/flow_widgets.dart';
import '../../widgets/otp_input.dart';
import '../../widgets/step_scaffold.dart';
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
  late BillProvider _selected = _providers.first;

  List<BillProvider> get _providers => switch (_category) {
        1 => kTvProviders,
        2 => kInternetProviders,
        _ => kElectricityProviders,
      };

  void _continue() {
    if (_category != 0) {
      openScreen(context, TvInternetScreen(provider: _selected, isTv: _category == 1));
      return;
    }
    openScreen(context, ElectricityScreen(providerName: _selected.name));
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final list = _providers.where((p) => q.isEmpty || p.name.toLowerCase().contains(q)).toList();
    final categoryName = _categories[_category];

    return StepScaffold(
      eyebrow: 'BILLS · FROM HOME / SERVICES',
      counter: '01 / 04',
      title: 'Pay a bill',
      subtitle: 'Choose a category and your provider.',
      headerLabel: 'Cancel',
      onHeaderAction: () => goHome(context),
      primaryLabel: 'Continue with ${_selected.name}',
      onPrimary: _continue,
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
                      _selected = _providers.first;
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
          for (final p in list) ...[
            SelectTile(
              icon: _icons[_category],
              title: p.name,
              subtitle: p.subtitle,
              selected: p.name == _selected.name,
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
  final _phone = TextEditingController(text: kPhone);
  bool _prepaid = true;
  MeterInfo? _info;
  bool _verifying = false;
  int _lookupId = 0;

  @override
  void dispose() {
    _meter.dispose();
    _amount.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _validateMeter() async {
    setState(() => _info = null);
    if (_meter.text.length != 11) {
      setState(() => _verifying = false);
      return;
    }
    final id = ++_lookupId;
    setState(() => _verifying = true);
    final info = await lookupMeter(widget.providerName, _meter.text);
    if (!mounted || id != _lookupId) return;
    setState(() {
      _info = info;
      _verifying = false;
    });
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              onChanged: (_) => _validateMeter(),
              validator: (v) => (v == null || v.length != 11) ? 'Enter all 11 digits' : null,
            ),
            const SizedBox(height: 10),
            if (_info != null)
              InfoBanner(
                icon: Icons.check_circle_outline,
                background: TpColors.greenTint,
                accent: TpColors.green,
                textColor: TpColors.green,
                text: 'Customer validated · ${_info!.name}\n${_info!.address}',
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
                if (a > kAccountBalance) return 'Insufficient balance';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TpField(
              label: 'Phone for token delivery',
              controller: _phone,
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            Text(
              'Fee ${formatLeone(BillDraft.fee)} · Total debit ${formatLeone(_amountValue + BillDraft.fee)}\n'
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
class ConfirmBillScreen extends StatefulWidget {
  const ConfirmBillScreen({super.key, required this.draft});

  final BillDraft draft;

  @override
  State<ConfirmBillScreen> createState() => _ConfirmBillScreenState();
}

class _ConfirmBillScreenState extends State<ConfirmBillScreen> {
  String _pin = '';

  void _pay() {
    // TODO: verify the PIN and submit the payment with your bills API.
    replaceScreen(
      context,
      BillSuccessScreen(
        draft: widget.draft,
        reference: makeReference('BIL'),
        token: makeToken(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    return StepScaffold(
      eyebrow: 'BILLS · ELECTRICITY',
      counter: '03 / 04',
      title: 'Confirm bill payment',
      headerLabel: 'Cancel',
      onHeaderAction: () => goHome(context),
      primaryLabel: 'Pay ${formatLeone(d.total)}',
      onPrimary: _pin.length == 4 ? _pay : null,
      secondaryLabel: 'Edit payment',
      onSecondary: () => Navigator.maybePop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AmountBanner(
            label: 'Total debit · includes ${formatLeone(BillDraft.fee)} fee',
            value: formatLeone(d.total),
          ),
          const SizedBox(height: 12),
          DetailsCard(
            rows: [
              ('Provider', '${d.provider} · ${d.typeLabel}'),
              ('Customer', _titleCase(d.customer)),
              ('Meter number', d.meter),
              ('Amount / fee', '${formatLeone(d.amount)} / ${formatLeone(BillDraft.fee)}'),
              ('Token delivery', d.phone),
              ('Balance after', formatLeone(kAccountBalance - d.total)),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Authorize with transaction PIN',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          OtpInput(
            length: 4,
            obscure: true,
            onChanged: (v) => setState(() => _pin = v),
          ),
          const SizedBox(height: 16),
          const InfoBanner(
            text: 'Check the meter number. Tokens are only valid for the meter paid for.',
          ),
        ],
      ),
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
  const BillSuccessScreen({
    super.key,
    required this.draft,
    required this.reference,
    required this.token,
  });

  final BillDraft draft;
  final String reference;
  final String token;

  /// Sample rate (leone per kWh) for the units line. Your vendor returns real units.
  static const double _rate = 4.2;

  @override
  Widget build(BuildContext context) {
    final units = (draft.amount / _rate).toStringAsFixed(1);
    return StepScaffold(
      eyebrow: 'BILLS · ELECTRICITY',
      counter: '04 / 04',
      title: 'Payment successful',
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
          ResultHeader(
            headline: '${formatLeone(draft.amount)} paid',
            detail: '${draft.provider} · ${draft.typeLabel} meter ${draft.meter}',
          ),
          const SizedBox(height: 20),
          AmountBanner(
            label: 'Electricity token · 20 digits',
            value: token,
            background: TpColors.tint,
            labelColor: TpColors.muted,
            valueColor: TpColors.navy,
            valueSize: 22,
            center: true,
            child: TpWhiteButton(
              label: 'Copy token',
              icon: Icons.copy_outlined,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: token.replaceAll(' ', '')));
                if (context.mounted) showMessage(context, 'Token copied.');
              },
            ),
          ),
          const SizedBox(height: 12),
          DetailsCard(
            rows: [
              ('Customer', _titleCase(draft.customer)),
              ('Units purchased', '$units kWh'),
              ('Total / fee', '${formatLeone(draft.total)} / ${formatLeone(BillDraft.fee)}'),
              ('Reference', reference),
            ],
          ),
          const SizedBox(height: 12),
          InfoBanner(
            icon: Icons.check_circle_outline,
            background: TpColors.greenTint,
            accent: TpColors.green,
            textColor: TpColors.green,
            text: 'Token sent by SMS · Balance ${formatLeone(kAccountBalance - draft.total)}',
          ),
        ],
      ),
    );
  }
}
