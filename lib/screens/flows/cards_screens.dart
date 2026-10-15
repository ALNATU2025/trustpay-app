import 'dart:async';

import 'package:flutter/material.dart';

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
import '../../widgets/otp_input.dart';
import '../../widgets/step_scaffold.dart';
import 'funding_screens.dart';
import 'generic_flow.dart';
import 'physical_card_screens.dart';

/// The blue virtual card artwork.
class VirtualCardView extends StatelessWidget {
  const VirtualCardView({super.key, required this.card, this.details});

  final CardInfo card;

  /// Full number and CVV while the customer is looking at them, otherwise null.
  final CardDetails? details;

  @override
  Widget build(BuildContext context) {
    final d = details;
    final number = d != null ? d.spacedNumber : '••••  ••••  ••••  ${card.last4}';
    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: card.frozen ? const Color(0xFF6B7690) : TpColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TrustPay',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              Icon(
                card.frozen ? Icons.ac_unit : Icons.wifi,
                color: Colors.white,
                size: 22,
              ),
            ],
          ),
          const Spacer(),
          Text(
            number,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                card.holder.toUpperCase(),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              Text(
                d != null ? '${d.expiry.isEmpty ? card.expiry : d.expiry} · CVV ${d.cvv}' : card.expiry,
                style: const TextStyle(fontSize: 13, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Cards 1/3: virtual and physical cards.
class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  late int _tab = widget.initialTab;
  CardsData? _data;
  String? _error;
  bool _loading = true;
  int _round = 0;
  int _seenVersion = appState.txnVersion;

  @override
  void initState() {
    super.initState();
    appState.addListener(_onAppState);
    _load();
  }

  @override
  void dispose() {
    appState.removeListener(_onAppState);
    super.dispose();
  }

  void _onAppState() {
    if (appState.txnVersion != _seenVersion) {
      _seenVersion = appState.txnVersion;
      _load();
    }
  }

  Future<void> _load() async {
    final round = ++_round;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await api.cards();
      if (!mounted || round != _round) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || round != _round) return;
      setState(() {
        _error = errorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _primary() async {
    final data = _data;
    if (data == null) return;
    final virtual = data.virtual;
    if (_tab == 1) {
      await openScreen(context, const OrderPhysicalCardScreen());
    } else if (virtual != null) {
      await openScreen(context, CardReadyScreen(card: virtual));
    } else {
      await openScreen(context, const CreateCardScreen());
    }
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final virtual = data?.virtual;
    final physical = data?.physical ?? const <CardInfo>[];
    return StepScaffold(
      eyebrow: 'CARDS · FROM SERVICES',
      counter: '01 / 03',
      title: 'Your cards',
      subtitle: 'A safer way to pay online and in store.',
      headerLabel: 'Done',
      onHeaderAction: () => goHome(context),
      primaryLabel: _tab == 0
          ? (virtual != null ? 'View virtual card' : 'Request virtual card')
          : 'Request physical card',
      onPrimary: data == null ? null : _primary,
      secondaryLabel: 'Back to home',
      onSecondary: () => goHome(context),
      child: Column(
        children: [
          SegmentedTabs(
            labels: const ['Virtual', 'Physical'],
            index: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: 16),
          if (data == null && _loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (data == null)
            ErrorRetry(message: _error ?? 'Could not load your cards.', onRetry: _load)
          else if (_tab == 0 && virtual != null)
            VirtualCardView(card: virtual)
          else if (_tab == 1 && physical.isNotEmpty)
            Column(
              children: [
                for (final c in physical) ...[
                  SelectTile(
                    icon: Icons.credit_card_outlined,
                    title: c.last4.isEmpty ? 'Physical card' : 'Physical card •• ${c.last4}',
                    subtitle: c.status.isEmpty ? 'Requested' : 'Status: ${c.status}',
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            )
          else
            _EmptyCards(virtual: _tab == 0),
          const SizedBox(height: 16),
          SelectTile(
            icon: Icons.credit_card_outlined,
            title: 'Virtual leone card',
            subtitle: 'Instant issuance · Fund and freeze in the app',
            onTap: () => setState(() => _tab = 0),
          ),
          const SizedBox(height: 12),
          SelectTile(
            icon: Icons.wallet_outlined,
            title: 'Physical cards',
            subtitle: 'Switch to Physical to view your in-store cards.',
            onTap: () => setState(() => _tab = 1),
          ),
          const SizedBox(height: 16),
          const InfoBanner(
            text: 'You will see all fees before you confirm your request.',
          ),
        ],
      ),
    );
  }
}

class _EmptyCards extends StatelessWidget {
  const _EmptyCards({required this.virtual});

  final bool virtual;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TpColors.tint,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.credit_card_outlined, color: TpColors.primary, size: 40),
          const SizedBox(height: 24),
          Text(
            virtual ? 'No virtual card yet' : 'No physical card yet',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            virtual
                ? 'Create a leone card for your online subscriptions and shopping.'
                : 'Request a physical card to pay in store and withdraw cash.',
            style: const TextStyle(fontSize: 15, height: 1.4, color: TpColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Cards 2/3: fund and confirm the new virtual card.
class CreateCardScreen extends StatefulWidget {
  const CreateCardScreen({super.key});

  @override
  State<CreateCardScreen> createState() => _CreateCardScreenState();
}

class _CreateCardScreenState extends State<CreateCardScreen> {
  final _funding = TextEditingController();
  bool _accepted = false;

  @override
  void dispose() {
    _funding.dispose();
    super.dispose();
  }

  double get _fee => appState.cat.fees.cardIssuance;
  double get _amount => parseAmount(_funding.text);
  double get _total => _amount + _fee;
  bool get _valid => _accepted && _amount >= 0 && _total <= appState.balance;

  void _review() {
    final amount = _amount;
    final fee = _fee;
    final total = amount + fee;
    openScreen(
      context,
      PayConfirmScreen(
        eyebrow: 'CARDS',
        counter: '02 / 03',
        title: 'Confirm your virtual card',
        bannerLabel: 'Issuance ${formatLeone(fee)} + funding ${formatLeone(amount)}',
        total: total,
        payLabel: 'Confirm & pay',
        pinLabel: 'Confirm with transaction PIN',
        rows: [
          ('Cardholder', appState.me.fullName),
          ('Issuance fee', '${formatLeone(fee)} · one-time'),
          ('Initial funding', formatLeone(amount)),
          ('Total debit now', formatLeone(total)),
          ('Account after', formatLeone(appState.balance - total)),
        ],
        onPay: (pin, key) => api.createVirtualCard(amount: amount, pin: pin, idempotencyKey: key),
        successBuilder: (result) {
          final card = result.card;
          if (card == null) {
            final txn = result.transaction;
            return PaySuccessScreen(
              eyebrow: 'CARDS',
              counter: '03 / 03',
              headline: isPending(txn) ? 'Card request is being processed' : 'Card created',
              detail: 'Open Cards to see your virtual card.',
              rows: receiptRows(txn),
            );
          }
          return CardReadyScreen(card: card, created: result);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fee = _fee;
    return StepScaffold(
      eyebrow: 'CARDS',
      counter: '02 / 03',
      title: 'Create your virtual card',
      subtitle: 'Leone card · Cardholder: ${appState.me.fullName}',
      headerLabel: 'Cancel',
      onHeaderAction: () => Navigator.maybePop(context),
      primaryLabel: 'Review ${formatLeone(_total)}',
      onPrimary: _valid ? _review : null,
      secondaryLabel: 'Back to cards',
      onSecondary: () => Navigator.maybePop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TpField(
            label: 'Initial card funding (optional)',
            controller: _funding,
            hint: '0.00',
            prefixText: 'Le ',
            allowDecimal: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          DetailsCard(
            rows: [
              ('Issuance fee', '${formatLeone(fee)} · one-time'),
              ('Initial funding', formatLeone(_amount)),
              ('Total debit now', formatLeone(_total)),
              ('Account after', formatLeone(appState.balance - _total)),
            ],
          ),
          if (_total > appState.balance) ...[
            const SizedBox(height: 8),
            const Text('Insufficient balance', style: TextStyle(fontSize: 13, color: TpColors.danger)),
          ],
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: Checkbox(
                  value: _accepted,
                  activeColor: TpColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  onChanged: (v) => setState(() => _accepted = v ?? false),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'I accept the Card Terms and the fees shown above.',
                  style: TextStyle(fontSize: 14, height: 1.4, color: TpColors.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const InfoBanner(
            text: 'You will enter your transaction PIN on the next step.',
          ),
        ],
      ),
    );
  }
}

/// Cards 3/3: the card with show details, freeze and fund.
class CardReadyScreen extends StatefulWidget {
  const CardReadyScreen({super.key, required this.card, this.created});

  final CardInfo card;

  /// Set right after the card was created, to confirm the payment on this screen.
  final PaymentResult? created;

  @override
  State<CardReadyScreen> createState() => _CardReadyScreenState();
}

class _CardReadyScreenState extends State<CardReadyScreen> {
  static const _revealSeconds = 30;

  late CardInfo _card = widget.card;
  int _seenVersion = appState.txnVersion;

  // Full number and CVV: only kept here while shown.
  CardDetails? _details;
  Timer? _hideTimer;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    appState.addListener(_onAppState);
  }

  @override
  void dispose() {
    appState.removeListener(_onAppState);
    _hideTimer?.cancel();
    _details = null;
    super.dispose();
  }

  void _onAppState() {
    if (appState.txnVersion != _seenVersion) {
      _seenVersion = appState.txnVersion;
      _refresh();
    }
  }

  Future<void> _refresh() async {
    try {
      final data = await api.cards();
      final v = data.virtual;
      if (!mounted || v == null) return;
      setState(() => _card = v);
    } catch (_) {
      // Keep showing the card we have.
    }
  }

  void _hide() {
    _hideTimer?.cancel();
    if (mounted) setState(() => _details = null);
  }

  Future<String?> _askPin() => showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enter your PIN'),
          content: SizedBox(
            width: 280,
            child: OtpInput(
              length: 4,
              obscure: true,
              autofocus: true,
              onChanged: (v) {
                if (v.length == 4) Navigator.of(context).pop(v);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

  Future<void> _toggleDetails() async {
    if (_busy) return;
    if (_details != null) {
      _hide();
      return;
    }
    final pin = await _askPin();
    if (pin == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final details = await api.revealVirtualCard(pin);
      if (!mounted) return;
      setState(() {
        _details = details;
        _busy = false;
      });
      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(seconds: _revealSeconds), _hide);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showMessage(context, e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showMessage(context, errorMessage(e));
    }
  }

  Future<void> _toggleFreeze() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final updated = await api.freezeVirtualCard(!_card.frozen);
      if (!mounted) return;
      setState(() {
        _card = updated;
        _busy = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showMessage(context, e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showMessage(context, errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = _card;
    final created = widget.created;
    final pending = created != null && isPending(created.transaction);
    final shown = _details != null;
    return StepScaffold(
      eyebrow: 'CARDS',
      counter: '03 / 03',
      title: created != null ? 'Your card is ready' : 'Your virtual card',
      subtitle: 'Virtual leone card · ${card.frozen ? 'Frozen' : 'Active'}',
      headerLabel: 'Done',
      onBack: () => goHome(context),
      onHeaderAction: () => goHome(context),
      primaryLabel: 'Fund card',
      onPrimary: () => openScreen(context, const FundCardScreen()),
      secondaryLabel: 'Back to home',
      onSecondary: () => goHome(context),
      child: Column(
        children: [
          VirtualCardView(card: card, details: _details),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TpWhiteButton(
                  label: shown ? 'Hide details' : 'Show details',
                  icon: shown ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  onPressed: _busy ? null : _toggleDetails,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TpWhiteButton(
                  label: card.frozen ? 'Unfreeze card' : 'Freeze card',
                  icon: Icons.ac_unit,
                  onPressed: _busy ? null : _toggleFreeze,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DetailsCard(
            rows: [
              ('Card balance', formatLeone(card.balance)),
              ('Card status', card.frozen ? 'Frozen' : 'Active · Ready to use'),
              ('Issuance paid', formatLeone(card.issuancePaid)),
              ('Account balance', formatLeone(appState.balance)),
              if (created != null && created.transaction.reference.isNotEmpty)
                ('Reference', created.transaction.reference),
            ],
          ),
          const SizedBox(height: 12),
          InfoBanner(
            icon: pending ? Icons.schedule : Icons.check_circle_outline,
            background: TpColors.greenTint,
            accent: TpColors.green,
            textColor: TpColors.green,
            text: pending
                ? 'Your card payment is being processed. Check Transactions for the final status.'
                : (shown
                    ? 'Details hide again after $_revealSeconds seconds. Never share your CVV.'
                    : 'Show details requires your PIN; never share your CVV.'),
          ),
        ],
      ),
    );
  }
}
