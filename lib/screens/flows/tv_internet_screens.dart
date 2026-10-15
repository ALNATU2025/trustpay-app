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
  final _phone = TextEditingController(text: appState.me.phone);
  final _debounce = Debouncer();
  int _package = 0;
  String? _customer;
  String? _lookupError;
  bool _verifying = false;
  int _lookupId = 0;

  List<BillPackage> get _packages => widget.isTv ? appState.cat.tvPackages : appState.cat.internetPackages;
  String get _kind => widget.isTv ? 'TV' : 'Internet';
  String get _numberLabel => widget.isTv ? 'Smartcard / IUC number' : 'Account or device number';

  @override
  void dispose() {
    _debounce.dispose();
    _number.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _onNumberChanged() {
    _debounce.cancel();
    final id = ++_lookupId;
    setState(() {
      _customer = null;
      _lookupError = null;
      _verifying = _number.text.length == 10;
    });
    if (_number.text.length != 10) return;
    _debounce.run(() => _validate(id));
  }

  Future<void> _validate(int id) async {
    try {
      final name = await api.lookupCustomer(widget.isTv ? 'tv' : 'internet', widget.provider.name, _number.text);
      if (!mounted || id != _lookupId) return;
      setState(() {
        _customer = name;
        _lookupError = name == null ? 'We could not find this number. Check it and try again.' : null;
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

  void _review() {
    if (!_form.currentState!.validate()) return;
    final customer = _customer;
    if (customer == null) {
      showMessage(context, 'Enter a valid $_numberLabel first.');
      return;
    }
    if (_packages.isEmpty) return;
    final pkg = _packages[_package];
    final fee = appState.cat.fees.bill;
    final total = pkg.price + fee;
    if (total > appState.balance) {
      showMessage(context, 'Insufficient balance for this package.');
      return;
    }
    final provider = widget.provider.name;
    final number = _number.text;
    final phone = _phone.text.trim();
    final category = widget.isTv ? 'tv' : 'internet';

    openScreen(
      context,
      PayConfirmScreen(
        eyebrow: 'BILLS · ${_kind.toUpperCase()}',
        counter: '03 / 04',
        title: 'Confirm payment',
        bannerLabel: '$provider ${pkg.name} · ${fee > 0 ? 'includes ${formatLeone(fee)} fee' : 'no fee'}',
        total: total,
        payLabel: 'Pay',
        notice: 'Check the number. Payments cannot be reversed once the provider accepts them.',
        rows: [
          ('Provider', provider),
          ('Customer', customer),
          (_numberLabel, number),
          ('Package', '${pkg.name} · ${pkg.detail}'),
          ('Receipt SMS to', phone),
          ('Balance after', formatLeone(appState.balance - total)),
        ],
        onPay: (pin, key) => api.paySubscription(
          category: category,
          provider: provider,
          accountNumber: number,
          packageId: pkg.id,
          phone: phone,
          pin: pin,
          idempotencyKey: key,
        ),
        successBuilder: (result) {
          final txn = result.transaction;
          final pending = isPending(txn);
          return PaySuccessScreen(
            eyebrow: 'BILLS · ${_kind.toUpperCase()}',
            counter: '04 / 04',
            headline: pending ? '${formatLeone(pkg.price)} being processed' : '${formatLeone(pkg.price)} paid',
            detail: '$provider ${pkg.name} for $number',
            notice: pending
                ? 'Pending: the provider has not confirmed yet · Balance ${formatLeone(result.balance)}'
                : 'Subscription active shortly · Balance ${formatLeone(result.balance)}',
            rows: receiptRows(txn),
          );
        },
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
              onChanged: (_) => _onNumberChanged(),
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
            else if (_lookupError != null)
              InfoBanner(
                icon: Icons.error_outline,
                background: const Color(0xFFFDECEC),
                accent: TpColors.danger,
                textColor: TpColors.danger,
                text: _lookupError!,
              )
            else if (_verifying)
              const Text('Validating…', style: TextStyle(fontSize: 13, color: TpColors.muted)),
            const SizedBox(height: 16),
            const Text('Choose a package', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (_packages.isEmpty)
              const Text('No packages are available right now.', style: TextStyle(fontSize: 13, color: TpColors.muted)),
            for (var i = 0; i < _packages.length; i++) ...[
              SelectTile(
                icon: widget.isTv ? Icons.tv_outlined : Icons.wifi,
                title: '${_packages[i].name} · ${formatLeone(_packages[i].price, decimals: 0)}',
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
              _packages.isEmpty
                  ? balanceLine()
                  : 'Total debit ${formatLeone(_packages[_package].price + appState.cat.fees.bill)} · ${balanceLine()}',
              style: const TextStyle(fontSize: 13, color: TpColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
