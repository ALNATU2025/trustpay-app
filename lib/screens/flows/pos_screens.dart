import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api.dart';
import '../../services/app_state.dart';
import '../../services/trustpay_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/nav.dart';
import '../../widgets/account_header.dart';
import '../../widgets/api_builder.dart';
import '../../widgets/common.dart';
import '../../widgets/flow_widgets.dart';
import '../../widgets/menu_widgets.dart';
import '../../widgets/step_scaffold.dart';
import '../support/support_screen.dart';
import 'generic_flow.dart';
import 'pos_charge_screen.dart';

/// "Mon 12 Oct" style window for the expected delivery of a terminal.
String _expectedWindow(DateTime? from, DateTime? to) {
  if (from == null && to == null) return 'To be confirmed';
  if (from == null) return 'By ${formatShortDate(to!)}';
  if (to == null) return 'From ${formatShortDate(from)}';
  return from.month == to.month && from.year == to.year
      ? '${from.day}–${formatShortDate(to)}'
      : '${formatShortDate(from)} – ${formatShortDate(to)}';
}

String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

IconData _recentIcon(String kind) => switch (kind) {
      'card' => Icons.credit_card_outlined,
      'momo' => Icons.phone_android,
      _ => Icons.account_balance_outlined,
    };

/// POS tab: the terminal, today's collections and the next settlement, or the status of a pending
/// terminal request.
class PosTab extends StatelessWidget {
  const PosTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) => ApiBuilder<PosOverview>(
        load: api.posOverview,
        reloadKey: appState.txnVersion,
        builder: (context, overview, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
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
              SelectTile(
                icon: Icons.phone_android,
                title: 'Charge a customer',
                subtitle: 'Collect by mobile money from your phone, no terminal needed',
                onTap: () async {
                  await openScreen(context, const ChargeCustomerScreen());
                  await reload();
                },
              ),
              const SizedBox(height: 16),
              ..._content(context, overview, reload),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, PosOverview o, Future<void> Function() reload) {
    final terminal = o.terminal;
    final request = o.request;
    final settlement = o.nextSettlement;

    if (terminal != null) {
      return [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () async {
              await openScreen(context, StoreTerminalScreen(overview: o));
              await reload();
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const TerminalIcon(width: 56, height: 80),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          o.businessName.isNotEmpty ? o.businessName : 'Your terminal',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Terminal ${terminal.code} · ${terminal.enabled ? 'Active' : 'Disabled'}',
                          style: const TextStyle(fontSize: 13, color: TpColors.muted),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${formatLeone(o.todayCollected)} collected today',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: TpColors.green),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: TpColors.primary),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (settlement != null)
          SelectTile(
            icon: Icons.payments_outlined,
            title: 'Next settlement',
            subtitle: settlement.scheduledFor != null
                ? '${formatLeone(settlement.net)} · ${formatShortDateTime(settlement.scheduledFor!)}'
                : formatLeone(settlement.net),
            onTap: () => openScreen(context, const SettlementScreen()),
          )
        else
          const InfoBanner(
            icon: Icons.payments_outlined,
            text: 'No settlement is scheduled yet. It appears here once your terminal collects payments.',
          ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Request another terminal',
          onPressed: () async {
            await openScreen(context, const RequestTerminalScreen());
            await reload();
          },
        ),
      ];
    }

    if (request != null) {
      return [
        WhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_shipping_outlined, color: TpColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Terminal request in progress',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DetailsCard(
                rows: [
                  ('Request ID', request.reference),
                  ('Status', _capitalize(request.status)),
                  if (request.expectedFrom != null || request.expectedTo != null)
                    ('Expected delivery', _expectedWindow(request.expectedFrom, request.expectedTo)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const InfoBanner(text: 'We will notify you when your terminal is approved and on its way.'),
        const SizedBox(height: 12),
        SecondaryButton(
          label: 'Contact POS support',
          onPressed: () => openScreen(context, const SupportScreen()),
        ),
      ];
    }

    return [
      WhiteCard(
        child: Column(
          children: [
            const TerminalIcon(width: 64, height: 92),
            const SizedBox(height: 16),
            const Text('No terminal yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text(
              'Request a TrustPay terminal to accept card and transfer payments in your shop.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.4, color: TpColors.muted),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      PrimaryButton(
        label: 'Request a terminal',
        onPressed: () async {
          await openScreen(context, const RequestTerminalScreen());
          await reload();
        },
      ),
    ];
  }
}

/// Details of the terminal, today's activity and the enable / disable switch.
class StoreTerminalScreen extends StatefulWidget {
  const StoreTerminalScreen({super.key, required this.overview});

  final PosOverview overview;

  @override
  State<StoreTerminalScreen> createState() => _StoreTerminalScreenState();
}

class _StoreTerminalScreenState extends State<StoreTerminalScreen> {
  late PosTerminal _terminal = widget.overview.terminal!;
  bool _busy = false;

  Future<void> _toggle() async {
    final enable = !_terminal.enabled;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(enable ? 'Enable terminal?' : 'Disable terminal?'),
        content: Text(enable
            ? '${_terminal.code} will start accepting payments again.'
            : '${_terminal.code} will stop accepting payments until you enable it again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(enable ? 'Cancel' : 'Keep it on'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(enable ? 'Enable' : 'Disable'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final updated = await api.setTerminalEnabled(enable);
      if (!mounted) return;
      setState(() {
        _terminal = updated;
        _busy = false;
      });
      showMessage(context, enable ? 'Terminal enabled' : 'Terminal disabled');
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
    final o = widget.overview;
    final t = _terminal;
    final settlement = o.nextSettlement;
    final battery = t.battery;
    final details = [
      if (t.serial.isNotEmpty) 'Serial ${t.serial}',
      if (battery != null && battery >= 0) 'Battery $battery%',
    ].join(' · ');
    final where = [
      if (t.connection.isNotEmpty) 'Connection: ${t.connection}',
      if (t.location.isNotEmpty) 'Location: ${t.location}',
    ].join(' · ');
    final sync = t.lastSync != null ? 'Last sync ${formatShortDateTime(t.lastSync!)}' : 'Not synced yet';

    return StepScaffold(
      eyebrow: 'POS · FROM STORE TERMINAL',
      title: 'Store terminal',
      subtitle: '${o.businessName.isNotEmpty ? '${o.businessName} · ' : ''}Terminal ${t.code}',
      headerLabel: 'Done',
      onHeaderAction: () => goHome(context),
      primaryLabel: settlement != null ? 'View settlement · ${formatLeone(settlement.net)}' : 'Back to POS dashboard',
      onPrimary: settlement != null
          ? () => openScreen(context, const SettlementScreen())
          : () => Navigator.maybePop(context),
      secondaryLabel: settlement != null ? 'Back to POS dashboard' : null,
      onSecondary: settlement != null ? () => Navigator.maybePop(context) : null,
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
                          Icon(Icons.circle, size: 12, color: t.enabled ? TpColors.green : TpColors.muted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t.enabled ? 'Active' : 'Disabled',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(sync, style: const TextStyle(fontSize: 13, color: TpColors.muted)),
                      if (details.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(details, style: const TextStyle(fontSize: 13, color: TpColors.muted)),
                      ],
                      if (where.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(where, style: const TextStyle(fontSize: 13, color: TpColors.primary)),
                      ],
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
            decoration: BoxDecoration(color: TpColors.tint, borderRadius: BorderRadius.circular(22)),
            child: Row(
              children: [
                Expanded(child: _Stat(label: 'Today’s collections', value: formatLeone(o.todayCollected))),
                const SizedBox(width: 12),
                Expanded(child: _Stat(label: 'Successful payments', value: '${o.todayCount}')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          WhiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Recent terminal activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                if (o.recent.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No payments on this terminal yet.', style: TextStyle(color: TpColors.muted)),
                  )
                else
                  for (var i = 0; i < o.recent.length; i++)
                    ActivityRow(
                      icon: _recentIcon(o.recent[i].kind),
                      title: o.recent[i].title,
                      subtitle: [
                        if (o.recent[i].subtitle.isNotEmpty) o.recent[i].subtitle,
                        if (o.recent[i].createdAt != null) formatTime(o.recent[i].createdAt!),
                      ].join(' · '),
                      trailing: formatLeone(o.recent[i].amount),
                      trailingColor: TpColors.green,
                      showDivider: i < o.recent.length - 1,
                    ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TpWhiteButton(
                  label: t.enabled ? 'Disable terminal' : 'Enable terminal',
                  icon: Icons.power_settings_new,
                  onPressed: _busy ? null : _toggle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TpWhiteButton(
                  label: 'POS support',
                  icon: Icons.headset_mic_outlined,
                  onPressed: () => openScreen(context, const SupportScreen()),
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
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}

/// Settlement details. Without [settlementId] it shows the next (not yet paid) settlement.
class SettlementScreen extends StatelessWidget {
  const SettlementScreen({super.key, this.settlementId});

  final String? settlementId;

  Future<SettlementData> _load() async {
    final id = settlementId;
    if (id == null) return api.nextSettlement();
    final s = await api.settlement(id);
    return SettlementData(settlement: s, rolledAmount: 0, rolledCount: 0);
  }

  @override
  Widget build(BuildContext context) {
    return PlainScaffold(
      title: 'Settlement details',
      child: ApiBuilder<SettlementData>(
        load: _load,
        builder: (context, data, reload) {
          final s = data.settlement;
          if (s == null) {
            return const InfoBanner(
              icon: Icons.info_outline,
              text: 'There is no settlement to show yet.',
            );
          }
          final paid = s.status.toLowerCase() == 'paid' || s.status.toLowerCase() == 'settled';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AmountBanner(
                label: 'Net settlement · ${paid ? 'Credited' : 'Not yet credited'}',
                value: formatLeone(s.net),
                background: TpColors.greenTint,
                labelColor: TpColors.green,
                valueColor: TpColors.navy,
              ),
              const SizedBox(height: 12),
              DetailsCard(
                rows: [
                  ('Settlement ID', s.reference),
                  ('Status', _capitalize(s.status)),
                  if (s.scheduledFor != null) ('Scheduled', formatDateTime(s.scheduledFor!)),
                  ('Eligible gross', '${formatLeone(s.gross)} · ${s.count} payments'),
                  ('Processing fees', '−${formatLeone(s.fees)}'),
                  if (s.destination.isNotEmpty) ('Destination', s.destination),
                ],
              ),
              const SizedBox(height: 12),
              WhiteCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Linked POS transactions',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    if (s.payments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('No payments are linked to this settlement.',
                            style: TextStyle(color: TpColors.muted)),
                      )
                    else
                      for (var i = 0; i < s.payments.length; i++)
                        ActivityRow(
                          icon: Icons.credit_card_outlined,
                          title: s.payments[i].title.isNotEmpty ? s.payments[i].title : s.payments[i].reference,
                          subtitle: [
                            if (s.payments[i].reference.isNotEmpty) s.payments[i].reference,
                            if (s.payments[i].subtitle.isNotEmpty) s.payments[i].subtitle,
                          ].join(' · '),
                          trailing: formatLeone(s.payments[i].amount),
                          trailingColor: TpColors.green,
                          showDivider: i < s.payments.length - 1,
                        ),
                  ],
                ),
              ),
              if (data.rolledCount > 0) ...[
                const SizedBox(height: 12),
                InfoBanner(
                  text: '${formatLeone(data.rolledAmount)} from ${data.rolledCount} later '
                      '${data.rolledCount == 1 ? 'payment' : 'payments'} rolls into the next batch.',
                ),
              ],
            ],
          );
        },
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
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(text: appState.me.businessName);
  late final TextEditingController _address = TextEditingController(text: appState.me.address);
  final _city = TextEditingController();
  late final TextEditingController _contact = TextEditingController(text: appState.me.phone);
  late String _category = appState.cat.terminalCategories.isNotEmpty ? appState.cat.terminalCategories.first : '';
  late String _state = appState.cat.districts.isNotEmpty ? appState.cat.districts.first : '';

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
    final fees = appState.cat.fees;
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
          deposit: fees.terminalDeposit,
          deliveryFee: fees.terminalDelivery,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cat = appState.cat;
    final available = cat.terminalCategories.isNotEmpty && cat.districts.isNotEmpty;
    return StepScaffold(
      eyebrow: 'POS · FROM POS DASHBOARD',
      counter: '01 / 03',
      title: 'Request a terminal',
      headerLabel: 'Cancel',
      onHeaderAction: () => goHome(context),
      primaryLabel: 'Review terminal request',
      onPrimary: available ? _review : null,
      secondaryLabel: 'Back to POS dashboard',
      onSecondary: () => Navigator.maybePop(context),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!available) ...[
              const InfoBanner(
                icon: Icons.info_outline,
                text: 'Terminal requests are not available right now. Please try again later.',
              ),
              const SizedBox(height: 14),
            ],
            TpField(label: 'Business name', controller: _name, validator: _required),
            const SizedBox(height: 14),
            if (cat.terminalCategories.isNotEmpty) ...[
              TpDropdown(
                label: 'Business category',
                value: _category,
                items: cat.terminalCategories,
                onChanged: (v) => setState(() => _category = v),
              ),
              const SizedBox(height: 14),
            ],
            TpField(label: 'Delivery address', controller: _address, validator: _required),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: TpField(label: 'City', controller: _city, validator: _required)),
                const SizedBox(width: 12),
                if (cat.districts.isNotEmpty)
                  Expanded(
                    child: TpDropdown(
                      label: 'District',
                      value: _state,
                      items: cat.districts,
                      onChanged: (v) => setState(() => _state = v),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            TpField(
              label: 'Delivery contact',
              controller: _contact,
              keyboardType: TextInputType.phone,
              validator: _required,
            ),
            const SizedBox(height: 16),
            const InfoBanner(
              text: 'The deposit and delivery fee are charged to your TrustPay balance when you confirm. '
                  'The request is then reviewed before the terminal is sent.',
            ),
          ],
        ),
      ),
    );
  }
}

/// Terminal request 2/3: fees, PIN and confirmation.
class ReviewTerminalScreen extends StatelessWidget {
  const ReviewTerminalScreen({super.key, required this.draft});

  final TerminalDraft draft;

  @override
  Widget build(BuildContext context) {
    final shortCategory = draft.category.split(' / ').first;
    return PayConfirmScreen(
      eyebrow: 'POS · TERMINAL REQUEST',
      counter: '02 / 03',
      title: 'Review your request',
      bannerLabel: 'Total payable now',
      total: draft.total,
      payLabel: 'Confirm request',
      rows: [
        ('Business', '${draft.businessName} · $shortCategory'),
        ('Deliver to', '${draft.address}, ${draft.city}, ${draft.state}'),
        ('Contact', draft.contact),
        ('Terminal deposit', '${formatLeone(draft.deposit)} · refundable'),
        ('Delivery fee', '${formatLeone(draft.deliveryFee)} · non-refundable'),
        ('Balance after', formatLeone(appState.balance - draft.total)),
      ],
      notice: 'Deposit refundable when the terminal is returned in good condition under the terminal '
          'agreement. By confirming, you accept the Terminal Agreement and the fees above. '
          'Request subject to approval.',
      onPay: (secret, key) => api.requestTerminal(draft, pin: secret, idempotencyKey: key),
      successBuilder: (result) => TerminalSubmittedScreen(draft: draft, result: result),
    );
  }
}

/// Terminal request 3/3: submitted and tracking.
class TerminalSubmittedScreen extends StatelessWidget {
  const TerminalSubmittedScreen({super.key, required this.draft, required this.result});

  final TerminalDraft draft;
  final PaymentResult result;

  @override
  Widget build(BuildContext context) {
    final request = PosRequest.fromJson(result.request);
    final received = request.createdAt ?? result.transaction.createdAt;

    return StepScaffold(
      eyebrow: 'POS · TERMINAL REQUEST',
      counter: '03 / 03',
      title: 'Request submitted',
      subtitle: 'We’ll notify you when your terminal is approved.',
      headerLabel: 'Done',
      onBack: () => goHome(context),
      onHeaderAction: () => goHome(context),
      primaryLabel: 'Copy request reference',
      onPrimary: () => copyText(context, request.reference, 'Reference copied.'),
      secondaryLabel: 'Back to home',
      onSecondary: () => goHome(context),
      child: Column(
        children: [
          DetailsCard(
            rows: [
              ('Request ID', request.reference),
              ('Business', draft.businessName),
              ('Status', _capitalize(request.status)),
              (
                'Deposit + delivery',
                '${formatLeone(draft.deposit, decimals: 0)} + ${formatLeone(draft.deliveryFee, decimals: 0)} paid',
              ),
              ('Expected delivery', '${_expectedWindow(request.expectedFrom, request.expectedTo)} · after approval'),
              ('Balance', formatLeone(result.balance)),
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
                  detail: '${formatShortDate(received)} · Payment confirmed',
                ),
                const _Step(
                  icon: Icons.schedule,
                  color: TpColors.primary,
                  title: 'Business review',
                  detail: 'In progress',
                ),
                const _Step(
                  icon: Icons.local_shipping_outlined,
                  color: TpColors.muted,
                  title: 'Dispatch & delivery',
                  detail: 'Next · You will be told when it is dispatched',
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
              onPressed: () => openScreen(context, const SupportScreen()),
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
