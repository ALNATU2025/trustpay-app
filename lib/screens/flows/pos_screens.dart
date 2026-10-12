import 'package:flutter/material.dart';

import '../../data/sample_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/nav.dart';
import '../../widgets/account_header.dart';
import '../../widgets/common.dart';
import '../../widgets/flow_widgets.dart';
import '../../widgets/step_scaffold.dart';

/// POS tab. This hub is not in the Figma export: it only links the POS screens.
class PosTab extends StatelessWidget {
  const PosTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const AccountHeader(),
        const SizedBox(height: 20),
        const Text('POS services', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text(
          'Collect payments and manage your terminals.',
          style: TextStyle(fontSize: 15, color: TpColors.muted),
        ),
        const SizedBox(height: 16),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => openScreen(context, const StoreTerminalScreen()),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  TerminalIcon(width: 56, height: 80),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(kBusinessName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        SizedBox(height: 2),
                        Text(
                          'Terminal TP-2048 · Online',
                          style: TextStyle(fontSize: 13, color: TpColors.muted),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '₦186,400 collected today',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: TpColors.green),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: TpColors.primary),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SelectTile(
          icon: Icons.payments_outlined,
          title: 'Next settlement',
          subtitle: '₦172,800.00 · Today at 4:00 PM',
          onTap: () => openScreen(context, const SettlementScreen()),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Request another terminal',
          onPressed: () => openScreen(context, const RequestTerminalScreen()),
        ),
        if (kShowIllustrativeNote)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Center(
              child: Text(
                'Illustrative data · All amounts in NGN',
                style: TextStyle(fontSize: 12, color: TpColors.muted),
              ),
            ),
          ),
      ],
    );
  }
}

/// Existing terminal TP-2048.
class StoreTerminalScreen extends StatefulWidget {
  const StoreTerminalScreen({super.key});

  @override
  State<StoreTerminalScreen> createState() => _StoreTerminalScreenState();
}

class _StoreTerminalScreenState extends State<StoreTerminalScreen> {
  bool _enabled = true;

  Future<void> _toggle() async {
    if (!_enabled) {
      // TODO: enable the terminal with your POS API.
      setState(() => _enabled = true);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable terminal?'),
        content: const Text('TP-2048 will stop accepting payments until you enable it again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep it on'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Disable'),
          ),
        ],
      ),
    );
    // TODO: disable the terminal with your POS API.
    if (ok == true && mounted) setState(() => _enabled = false);
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      eyebrow: 'POS · FROM STORE TERMINAL',
      title: 'Store terminal',
      subtitle: '$kBusinessName · Existing terminal TP-2048',
      headerLabel: 'Done',
      onHeaderAction: () => goHome(context),
      primaryLabel: 'View settlement · ${formatNaira(172800)}',
      onPrimary: () => openScreen(context, const SettlementScreen()),
      secondaryLabel: 'Back to POS dashboard',
      onSecondary: () => Navigator.maybePop(context),
      child: Column(
        children: [
          WhiteCard(
            child: Row(
              children: [
                const TerminalIcon(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 12,
                            color: _enabled ? TpColors.navy : TpColors.muted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _enabled ? 'Online · Last sync 12:44' : 'Disabled',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Serial TP2048-106 · Battery 86%',
                        style: TextStyle(fontSize: 13, color: TpColors.muted),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Connection: 4G · Location: Ikeja',
                        style: TextStyle(fontSize: 13, color: TpColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TpColors.tint,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: _Stat(label: 'Today’s collections', value: '₦186,400'),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: _Stat(label: 'Successful payments', value: '24'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const WhiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent terminal activity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 8),
                ActivityRow(
                  icon: Icons.credit_card_outlined,
                  title: 'Card payment',
                  subtitle: '•• 4821 · 12:42 · Successful',
                  trailing: '₦18,500.00',
                  trailingColor: TpColors.green,
                ),
                ActivityRow(
                  icon: Icons.credit_card_outlined,
                  title: 'Card payment',
                  subtitle: '•• 0934 · 12:36 · Successful',
                  trailing: '₦7,200.00',
                  trailingColor: TpColors.green,
                ),
                ActivityRow(
                  icon: Icons.account_balance_outlined,
                  title: 'Bank transfer',
                  subtitle: 'Chidi O. · 12:30 · Successful',
                  trailing: '₦25,000.00',
                  trailingColor: TpColors.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TpWhiteButton(
                  label: _enabled ? 'Disable terminal' : 'Enable terminal',
                  icon: Icons.power_settings_new,
                  onPressed: _toggle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TpWhiteButton(
                  label: 'POS support',
                  icon: Icons.headset_mic_outlined,
                  onPressed: () => showMessage(context, 'POS support is not connected yet.'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: TpColors.muted)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

/// Next settlement details (sample figures from the design).
class SettlementScreen extends StatelessWidget {
  const SettlementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      eyebrow: 'POS · FROM NEXT SETTLEMENT',
      title: 'Settlement details',
      subtitle: 'Scheduled · Today, 11 October at 4:00 PM',
      headerLabel: 'Done',
      onHeaderAction: () => goHome(context),
      primaryLabel: 'View all 21 linked payments',
      // TODO: open the full list of payments in this settlement.
      onPrimary: () => showMessage(context, 'The full list is not connected yet.'),
      secondaryLabel: 'Back to POS dashboard',
      onSecondary: () => Navigator.maybePop(context),
      child: Column(
        children: [
          AmountBanner(
            label: 'Net settlement · Not yet credited',
            value: formatNaira(172800),
            background: TpColors.greenTint,
            labelColor: TpColors.green,
            valueColor: TpColors.navy,
          ),
          const SizedBox(height: 12),
          DetailsCard(
            rows: [
              ('Settlement ID', 'TP-SET-111026-4821'),
              ('Eligible gross', '${formatNaira(173500)} · 21 payments'),
              ('Processing fees', '−${formatNaira(700)}'),
              ('Destination', '$kAccountName · TrustPay •• ${kAccountNumber.substring(6)}'),
            ],
          ),
          const SizedBox(height: 12),
          const WhiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Linked POS transactions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 8),
                ActivityRow(
                  icon: Icons.credit_card_outlined,
                  title: 'Card · POS-2048-1242',
                  subtitle: '12:42 · Eligible',
                  trailing: '₦18,500.00',
                  trailingColor: TpColors.green,
                ),
                ActivityRow(
                  icon: Icons.credit_card_outlined,
                  title: 'Card · POS-2048-1236',
                  subtitle: '12:36 · Eligible',
                  trailing: '₦7,200.00',
                  trailingColor: TpColors.green,
                ),
                ActivityRow(
                  icon: Icons.account_balance_outlined,
                  title: 'Transfer · POS-2048-1230',
                  subtitle: 'Chidi O. · 12:30 · Eligible',
                  trailing: '₦25,000.00',
                  trailingColor: TpColors.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const InfoBanner(
            text: '₦12,900 from 3 later payments rolls into the next batch. '
                '₦173,500 + ₦12,900 = ₦186,400 collected today.',
          ),
        ],
      ),
    );
  }
}

/// Terminal request 1/3: business and delivery details.
class RequestTerminalScreen extends StatefulWidget {
  const RequestTerminalScreen({super.key});

  @override
  State<RequestTerminalScreen> createState() => _RequestTerminalScreenState();
}

class _RequestTerminalScreenState extends State<RequestTerminalScreen> {
  static const _categories = [
    'Retail / General merchandise',
    'Food & beverage',
    'Services',
    'Other',
  ];
  static const _states = ['Lagos', 'Abuja (FCT)', 'Ogun', 'Oyo', 'Rivers', 'Kano'];

  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(text: kBusinessName);
  final _address = TextEditingController(text: '24 Allen Avenue, Ikeja');
  final _city = TextEditingController(text: 'Ikeja');
  final _contact = TextEditingController(text: '$kAccountName · $kPhone');
  String _category = _categories.first;
  String _state = _states.first;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _city.dispose();
    _contact.dispose();
    super.dispose();
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  void _review() {
    if (!_form.currentState!.validate()) return;
    openScreen(
      context,
      ReviewTerminalScreen(
        draft: TerminalDraft(
          businessName: _name.text.trim(),
          category: _category,
          address: _address.text.trim(),
          city: _city.text.trim(),
          state: _state,
          contact: _contact.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      eyebrow: 'POS · FROM POS DASHBOARD',
      counter: '01 / 03',
      title: 'Request a terminal',
      headerLabel: 'Cancel',
      onHeaderAction: () => goHome(context),
      primaryLabel: 'Review terminal request',
      onPrimary: _review,
      secondaryLabel: 'Back to POS dashboard',
      onSecondary: () => Navigator.maybePop(context),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TpField(label: 'Business name', controller: _name, validator: _required),
            const SizedBox(height: 14),
            TpDropdown(
              label: 'Business category',
              value: _category,
              items: _categories,
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 14),
            TpField(label: 'Delivery address', controller: _address, validator: _required),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: TpField(label: 'City', controller: _city, validator: _required)),
                const SizedBox(width: 12),
                Expanded(
                  child: TpDropdown(
                    label: 'State',
                    value: _state,
                    items: _states,
                    onChanged: (v) => setState(() => _state = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TpField(label: 'Delivery contact', controller: _contact, validator: _required),
            const SizedBox(height: 16),
            const InfoBanner(
              text: 'Additional terminal request. Your existing TP-2048 keeps working. '
                  'Delivery in 3–5 business days after approval.',
            ),
          ],
        ),
      ),
    );
  }
}

/// Terminal request 2/3: fees and confirmation.
class ReviewTerminalScreen extends StatelessWidget {
  const ReviewTerminalScreen({super.key, required this.draft});

  final TerminalDraft draft;

  @override
  Widget build(BuildContext context) {
    final shortCategory = draft.category.split(' / ').first;
    return StepScaffold(
      eyebrow: 'POS · TERMINAL REQUEST',
      counter: '02 / 03',
      title: 'Review your request',
      headerLabel: 'Cancel',
      onHeaderAction: () => goHome(context),
      primaryLabel: 'Confirm request · ${formatNaira(draft.total)}',
      // TODO: submit the request and charge the account with your POS API.
      onPrimary: () => replaceScreen(
        context,
        TerminalSubmittedScreen(draft: draft, requestId: makeReference('POS')),
      ),
      secondaryLabel: 'Edit business details',
      onSecondary: () => Navigator.maybePop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AmountBanner(
            label: 'Total payable now · illustrative fees',
            value: formatNaira(draft.total),
          ),
          const SizedBox(height: 12),
          DetailsCard(
            rows: [
              ('Business', '${draft.businessName} · $shortCategory'),
              ('Deliver to', '${draft.address}, ${draft.state}'),
              ('Contact', draft.contact),
              ('Terminal deposit', '${formatNaira(TerminalDraft.deposit)} · refundable'),
              ('Delivery fee', '${formatNaira(TerminalDraft.deliveryFee)} · non-refundable'),
              ('Account after', formatNaira(kAccountBalance - draft.total)),
            ],
          ),
          const SizedBox(height: 16),
          const InfoBanner(
            text: 'Deposit refundable when the terminal is returned in good condition '
                'under the terminal agreement. Fees are examples.',
          ),
          const SizedBox(height: 16),
          const Text(
            'By confirming, you accept the Terminal Agreement and the fees above. '
            'Request subject to approval.',
            style: TextStyle(fontSize: 15, height: 1.4, color: TpColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Terminal request 3/3: submitted and tracking.
class TerminalSubmittedScreen extends StatelessWidget {
  const TerminalSubmittedScreen({super.key, required this.draft, required this.requestId});

  final TerminalDraft draft;
  final String requestId;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final from = now.add(const Duration(days: 4));
    final to = now.add(const Duration(days: 8));
    final expected = from.month == to.month
        ? '${from.day}–${formatShortDate(to)}'
        : '${formatShortDate(from)} – ${formatShortDate(to)}';

    return StepScaffold(
      eyebrow: 'POS · TERMINAL REQUEST',
      counter: '03 / 03',
      title: 'Request submitted',
      subtitle: 'We’ll notify you when your terminal is approved.',
      headerLabel: 'Done',
      onBack: () => goHome(context),
      onHeaderAction: () => goHome(context),
      primaryLabel: 'View request receipt',
      // TODO: show the request receipt from your POS API.
      onPrimary: () => showMessage(context, 'The request receipt is not connected yet.'),
      secondaryLabel: 'Back to home',
      onSecondary: () => goHome(context),
      child: Column(
        children: [
          DetailsCard(
            rows: [
              ('Request ID', requestId),
              ('Business', draft.businessName),
              ('Status', 'Under review'),
              (
                'Deposit + delivery',
                '${formatNaira(TerminalDraft.deposit, decimals: 0)} + '
                    '${formatNaira(TerminalDraft.deliveryFee, decimals: 0)} paid',
              ),
              ('Expected delivery', '$expected · after approval'),
            ],
          ),
          const SizedBox(height: 12),
          WhiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Track your terminal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                _Step(
                  icon: Icons.check_circle_outline,
                  color: TpColors.green,
                  title: 'Request received',
                  detail: '${formatShortDate(now)} · Payment confirmed',
                ),
                const _Step(
                  icon: Icons.schedule,
                  color: TpColors.primary,
                  title: 'Business review',
                  detail: 'In progress · Up to 1 business day',
                ),
                const _Step(
                  icon: Icons.local_shipping_outlined,
                  color: TpColors.muted,
                  title: 'Dispatch & delivery',
                  detail: 'Next · Tracking sent when dispatched',
                ),
                const _Step(
                  icon: Icons.desktop_windows_outlined,
                  color: TpColors.muted,
                  title: 'Activate terminal',
                  detail: 'After delivery · Follow in-app steps',
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => showMessage(context, 'POS support is not connected yet.'),
              child: const Text('Need an update? Contact POS support', style: TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
    this.last = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(detail, style: const TextStyle(fontSize: 13, color: TpColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
