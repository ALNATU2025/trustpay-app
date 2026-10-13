import 'package:flutter/material.dart';

import '../../data/sample_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/nav.dart';
import '../../widgets/common.dart';
import '../../widgets/flow_widgets.dart';
import '../../widgets/otp_input.dart';
import '../../widgets/step_scaffold.dart';
import 'funding_screens.dart';
import 'physical_card_screens.dart';

/// The blue virtual card artwork.
class VirtualCardView extends StatelessWidget {
  const VirtualCardView({super.key, required this.card, this.revealed = false});

  final VirtualCard card;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    // TODO: the full number is only a placeholder. Fetch it from your card issuer.
    final number = revealed ? '4000 0012 3456 ${card.last4}' : '••••  ••••  ••••  ${card.last4}';
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
                revealed ? '${card.expiry} · CVV 123' : card.expiry,
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VirtualCard?>(
      valueListenable: virtualCardNotifier,
      builder: (context, card, _) {
        final hasCard = card != null;
        return StepScaffold(
          eyebrow: 'CARDS · FROM SERVICES',
          counter: '01 / 03',
          title: 'Your cards',
          subtitle: 'A safer way to pay online and in store.',
          headerLabel: 'Done',
          onHeaderAction: () => goHome(context),
          primaryLabel: _tab == 0
              ? (hasCard ? 'View virtual card' : 'Request virtual card')
              : 'Request physical card',
          onPrimary: () {
            if (_tab == 1) {
              openScreen(context, const OrderPhysicalCardScreen());
            } else if (hasCard) {
              openScreen(context, const CardReadyScreen());
            } else {
              openScreen(context, const CreateCardScreen());
            }
          },
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
              if (_tab == 0 && card != null)
                VirtualCardView(card: card)
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
                text: 'You’ll see all illustrative fees before you confirm your request.',
              ),
            ],
          ),
        );
      },
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
  static const double _issuanceFee = 50;

  final _funding = TextEditingController(text: '250');
  bool _accepted = false;
  String _pin = '';

  @override
  void dispose() {
    _funding.dispose();
    super.dispose();
  }

  double get _amount => parseAmount(_funding.text);
  double get _total => _amount + _issuanceFee;
  bool get _valid => _accepted && _pin.length == 4 && _amount > 0 && _total <= kAccountBalance;

  void _confirm() {
    // TODO: verify the PIN and create the card with your card issuer.
    final now = DateTime.now();
    virtualCardNotifier.value = VirtualCard(
      last4: kAccountNumber.substring(6),
      expiry: '${two(now.month)}/${two((now.year + 3) % 100)}',
      holder: kAccountName,
      balance: _amount,
      issuancePaid: _issuanceFee,
    );
    replaceScreen(context, const CardReadyScreen());
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      eyebrow: 'CARDS',
      counter: '02 / 03',
      title: 'Create your virtual card',
      subtitle: 'Leone card · Cardholder: $kAccountName',
      headerLabel: 'Cancel',
      onHeaderAction: () => Navigator.maybePop(context),
      primaryLabel: 'Confirm & pay ${formatLeone(_total)}',
      onPrimary: _valid ? _confirm : null,
      secondaryLabel: 'Back to cards',
      onSecondary: () => Navigator.maybePop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TpField(
            label: 'Initial card funding',
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
              ('Issuance fee', '${formatLeone(_issuanceFee)} · one-time'),
              ('Initial funding', formatLeone(_amount)),
              ('Monthly fee', formatLeone(0)),
              ('Total debit now', formatLeone(_total)),
              ('Account after', formatLeone(kAccountBalance - _total)),
            ],
          ),
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
                  'I accept the Card Terms and the illustrative fees shown above.',
                  style: TextStyle(fontSize: 14, height: 1.4, color: TpColors.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Confirm with transaction PIN',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          OtpInput(length: 4, obscure: true, onChanged: (v) => setState(() => _pin = v)),
          const SizedBox(height: 16),
          InfoBanner(
            text: 'Fees are examples, not a live offer. ${formatLeone(_amount, decimals: 0)} '
                'will be available on your new card.',
          ),
        ],
      ),
    );
  }
}

/// Cards 3/3: the new card.
class CardReadyScreen extends StatefulWidget {
  const CardReadyScreen({super.key});

  @override
  State<CardReadyScreen> createState() => _CardReadyScreenState();
}

class _CardReadyScreenState extends State<CardReadyScreen> {
  bool _revealed = false;

  Future<void> _toggleDetails() async {
    if (_revealed) {
      setState(() => _revealed = false);
      return;
    }
    final pin = await showDialog<String>(
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
    // TODO: check the PIN with your API before showing card details.
    if (pin != null && mounted) setState(() => _revealed = true);
  }

  void _toggleFreeze(VirtualCard card) {
    // TODO: freeze or unfreeze the card with your card issuer.
    virtualCardNotifier.value = card.copyWith(frozen: !card.frozen);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VirtualCard?>(
      valueListenable: virtualCardNotifier,
      builder: (context, card, _) {
        if (card == null) {
          return StepScaffold(
            eyebrow: 'CARDS',
            title: 'No card yet',
            primaryLabel: 'Back to cards',
            onPrimary: () => Navigator.maybePop(context),
            child: const SizedBox.shrink(),
          );
        }
        return StepScaffold(
          eyebrow: 'CARDS',
          counter: '03 / 03',
          title: 'Your card is ready',
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
              VirtualCardView(card: card, revealed: _revealed),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TpWhiteButton(
                      label: _revealed ? 'Hide details' : 'Show details',
                      icon: _revealed ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      onPressed: _toggleDetails,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TpWhiteButton(
                      label: card.frozen ? 'Unfreeze card' : 'Freeze card',
                      icon: Icons.ac_unit,
                      onPressed: () => _toggleFreeze(card),
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
                  (
                    'Account balance',
                    formatLeone(kAccountBalance - card.issuancePaid - card.balance),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const InfoBanner(
                icon: Icons.check_circle_outline,
                background: TpColors.greenTint,
                accent: TpColors.green,
                textColor: TpColors.green,
                text: 'Card created successfully. Show details requires your PIN; never share your CVV.',
              ),
            ],
          ),
        );
      },
    );
  }
}
