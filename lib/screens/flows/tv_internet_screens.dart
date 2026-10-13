import 'package:flutter/material.dart';

import '../../data/sample_data.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/nav.dart';
import '../../widgets/common.dart';
import '../../widgets/flow_widgets.dart';
import '../../widgets/step_scaffold.dart';
import 'generic_flow.dart';

class _Package {
  const _Package(this.name, this.detail, this.price);

  final String name;
  final String detail;
  final double price;
}

// Sample packages and prices. Replace with the list from your bills provider.
const _tvPackages = [
  _Package('Basic', 'Essential channels · 1 month', 2500),
  _Package('Standard', 'More sport and movies · 1 month', 6000),
  _Package('Premium', 'Everything, in HD · 1 month', 12000),
];

const _internetPackages = [
  _Package('Starter', '20 GB · 30 days', 5000),
  _Package('Plus', '50 GB · 30 days', 10000),
  _Package('Max', '100 GB · 30 days', 18000),
];

/// Bills 2/4 for TV and internet: account number, package and phone.
class TvInternetScreen extends StatefulWidget {
  const TvInternetScreen({super.key, required this.provider, required this.isTv});

  final BillProvider provider;
  final bool isTv;

  @override
  State<TvInternetScreen> createState() => _TvInternetScreenState();
}

class _TvInternetScreenState extends State<TvInternetScreen> {
  final _form = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _phone = TextEditingController(text: kPhone);
  int _package = 0;
  String? _customer;
  bool _verifying = false;
  int _lookupId = 0;

  List<_Package> get _packages => widget.isTv ? _tvPackages : _internetPackages;
  String get _kind => widget.isTv ? 'TV' : 'Internet';
  String get _numberLabel => widget.isTv ? 'Smartcard / IUC number' : 'Account or device number';

  @override
  void dispose() {
    _number.dispose();
    _phone.dispose();
    super.dispose();
  }

  /// Sample customer lookup. Replace with your bills provider API.
  Future<void> _validate() async {
    setState(() => _customer = null);
    if (_number.text.length != 10) {
      setState(() => _verifying = false);
      return;
    }
    final id = ++_lookupId;
    setState(() => _verifying = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted || id != _lookupId) return;
    setState(() {
      _customer = 'Ada Okafor';
      _verifying = false;
    });
  }

  void _review() {
    if (!_form.currentState!.validate()) return;
    final customer = _customer;
    if (customer == null) {
      showMessage(context, 'Enter a valid $_numberLabel first.');
      return;
    }
    final pkg = _packages[_package];
    final provider = widget.provider.name;
    final number = _number.text;
    final phone = _phone.text.trim();

    openScreen(
      context,
      PayConfirmScreen(
        eyebrow: 'BILLS · ${_kind.toUpperCase()}',
        counter: '03 / 04',
        title: 'Confirm payment',
        bannerLabel: '$provider ${pkg.name} · no fee',
        total: pkg.price,
        referenceCode: widget.isTv ? 'TVB' : 'NET',
        payLabel: 'Pay',
        notice: 'Check the number. Payments cannot be reversed once the provider accepts them.',
        rows: [
          ('Provider', provider),
          ('Customer', customer),
          (_numberLabel, number),
          ('Package', '${pkg.name} · ${pkg.detail}'),
          ('Receipt SMS to', phone),
          ('Balance after', formatNaira(kAccountBalance - pkg.price)),
        ],
        successBuilder: (reference) => PaySuccessScreen(
          eyebrow: 'BILLS · ${_kind.toUpperCase()}',
          counter: '04 / 04',
          headline: '${formatNaira(pkg.price)} paid',
          detail: '$provider ${pkg.name} for $number',
          notice: 'Subscription active shortly · Balance ${formatNaira(kAccountBalance - pkg.price)}',
          rows: [
            ('Customer', customer),
            ('Package', pkg.name),
            ('Amount', formatNaira(pkg.price)),
            ('Reference', reference),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      eyebrow: 'BILLS · ${_kind.toUpperCase()}',
      counter: '02 / 04',
      title: widget.isTv ? 'TV subscription' : 'Internet plan',
      subtitle: '${widget.provider.name} · Enter your details and pick a package.',
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
            TpField(
              label: _numberLabel,
              controller: _number,
              hint: '10-digit number',
              keyboardType: TextInputType.number,
              digitsOnly: true,
              maxLength: 10,
              onChanged: (_) => _validate(),
              validator: (v) => (v == null || v.length != 10) ? 'Enter all 10 digits' : null,
            ),
            const SizedBox(height: 10),
            if (_customer != null)
              InfoBanner(
                icon: Icons.check_circle_outline,
                background: TpColors.greenTint,
                accent: TpColors.green,
                textColor: TpColors.green,
                text: 'Customer validated · $_customer',
              )
            else if (_verifying)
              const Text('Validating…', style: TextStyle(fontSize: 13, color: TpColors.muted)),
            const SizedBox(height: 16),
            const Text('Choose a package', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (var i = 0; i < _packages.length; i++) ...[
              SelectTile(
                icon: widget.isTv ? Icons.tv_outlined : Icons.wifi,
                title: '${_packages[i].name} · ${formatNaira(_packages[i].price, decimals: 0)}',
                subtitle: _packages[i].detail,
                selected: i == _package,
                onTap: () => setState(() => _package = i),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 6),
            TpField(
              label: 'Phone for the receipt',
              controller: _phone,
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            Text(
              'Total debit ${formatNaira(_packages[_package].price)} · Balance ${formatNaira(kAccountBalance)}',
              style: const TextStyle(fontSize: 13, color: TpColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
