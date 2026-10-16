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
import '../../widgets/menu_widgets.dart';
import '../../widgets/step_scaffold.dart';
import 'generic_flow.dart';

String _shareText(Map<String, dynamic> r) =>
    'Please pay me ${formatLeone(asDouble(r['amount']))} on TrustPay${asStr(r['note']).isNotEmpty ? ' (${asStr(r['note'])})' : ''}.\n'
    'Open TrustPay > Request money > Pay a request and enter code ${asStr(r['code'])}.\n'
    '${asStr(r['link'])}';

/// Ask for money, share a payment link, pay a request someone sent you.
class RequestHubScreen extends StatefulWidget {
  const RequestHubScreen({super.key});

  @override
  State<RequestHubScreen> createState() => _RequestHubScreenState();
}

class _RequestHubScreenState extends State<RequestHubScreen> {
  int _gen = 0;

  Future<void> _open(Widget screen) async {
    await openScreen(context, screen);
    if (mounted) setState(() => _gen++);
  }

  @override
  Widget build(BuildContext context) {
    return PlainScaffold(
      title: 'Money requests',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MenuGroup(children: [
            MenuTile(
              icon: Icons.person_add_alt_1_outlined,
              title: 'Ask someone for money',
              subtitle: 'Send a request to a TrustPay customer',
              onTap: () => _open(const NewRequestScreen(link: false)),
            ),
            MenuTile(
              icon: Icons.link,
              title: 'Create a payment link',
              subtitle: 'Anyone with TrustPay can pay it',
              onTap: () => _open(const NewRequestScreen(link: true)),
            ),
            MenuTile(
              icon: Icons.keyboard_outlined,
              title: 'Pay a request',
              subtitle: 'Enter a request code you were given',
              onTap: () => _open(const PayRequestScreen()),
            ),
          ]),
          const SizedBox(height: 22),
          const _Label('ASKED OF YOU'),
          ApiBuilder<List<Map<String, dynamic>>>(
            key: ValueKey('in$_gen'),
            load: () => api.requests('incoming'),
            builder: (context, rows, reload) => _list(rows, 'Nothing waiting. Requests sent to you appear here.'),
          ),
          const SizedBox(height: 22),
          const _Label('YOUR REQUESTS'),
          ApiBuilder<List<Map<String, dynamic>>>(
            key: ValueKey('out$_gen'),
            load: () => api.requests('outgoing'),
            builder: (context, rows, reload) => _list(rows, 'You have not asked anyone for money yet.'),
          ),
        ],
      ),
    );
  }

  Widget _list(List<Map<String, dynamic>> rows, String empty) {
    if (rows.isEmpty) return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(empty, style: const TextStyle(color: TpColors.muted)));
    return MenuGroup(children: [
      for (final r in rows)
        ListTile(
          key: ValueKey(asStr(r['id'])),
          title: Text(
            asStr(r['direction']) == 'incoming' ? asStr(r['requesterName']) : (r['open'] == true ? 'Payment link' : asStr(r['payerName'])),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text('${formatLeone(asDouble(r['amount']))} · ${_statusLabel(asStr(r['status']))}${asStr(r['note']).isNotEmpty ? ' · ${asStr(r['note'])}' : ''}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(RequestDetailScreen(request: r)),
        ),
    ]);
  }
}

String _statusLabel(String s) => switch (s) {
      'pending' => 'Waiting',
      'paid' => 'Paid',
      'declined' => 'Declined',
      'cancelled' => 'Cancelled',
      'expired' => 'Expired',
      _ => s,
    };

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: TpColors.muted)),
      );
}

/// Create a request for one customer, or an open payment link.
class NewRequestScreen extends StatefulWidget {
  const NewRequestScreen({super.key, required this.link});

  final bool link;

  @override
  State<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends State<NewRequestScreen> {
  final _form = GlobalKey<FormState>();
  final _who = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _who.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_form.currentState!.validate() || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final who = _who.text.trim().replaceAll(' ', '');
      final r = await api.createRequest(
        amount: parseAmount(_amount.text),
        note: _note.text.trim(),
        accountNumber: !widget.link && who.length == 10 ? who : null,
        phone: !widget.link && who.length != 10 ? who : null,
      );
      if (!mounted) return;
      replaceScreen(context, RequestCreatedScreen(request: r));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      eyebrow: 'REQUEST MONEY',
      title: widget.link ? 'Create a payment link' : 'Ask for money',
      subtitle: widget.link
          ? 'Share the link or code. Whoever pays it first sends you the money.'
          : 'They get a notification and can pay you in a few taps.',
      primaryLabel: widget.link ? 'Create link' : 'Send request',
      primaryLoading: _busy,
      onPrimary: _busy ? null : _create,
      secondaryLabel: 'Back',
      onSecondary: () => Navigator.maybePop(context),
      child: Form(
        key: _form,
        child: Column(
          children: [
            if (!widget.link) ...[
              TpField(
                label: 'Phone number or account number',
                controller: _who,
                hint: '076 123 456',
                keyboardType: TextInputType.phone,
                validator: (v) => (v ?? '').replaceAll(' ', '').length < 8 ? 'Enter their phone or 10-digit account number' : null,
              ),
              const SizedBox(height: 16),
            ],
            TpField(
              label: 'Amount',
              controller: _amount,
              hint: '0.00',
              prefixText: 'Le ',
              allowDecimal: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => parseAmount(v ?? '') < 1 ? 'Enter an amount' : null,
            ),
            const SizedBox(height: 16),
            TpField(label: 'What is it for? (optional)', controller: _note, hint: 'e.g. Lunch', maxLength: 100),
            if (_error != null) ...[const SizedBox(height: 16), ErrorBanner(_error!)],
          ],
        ),
      ),
    );
  }
}

class RequestCreatedScreen extends StatelessWidget {
  const RequestCreatedScreen({super.key, required this.request});

  final Map<String, dynamic> request;

  @override
  Widget build(BuildContext context) {
    final open = request['open'] == true;
    return StepScaffold(
      eyebrow: 'REQUEST MONEY',
      title: open ? 'Your payment link is ready' : 'Request sent',
      subtitle: open ? 'Copy the message and send it by WhatsApp, SMS or anywhere you like.' : '${asStr(request['payerName'])} has been notified. It stays open for 7 days.',
      headerLabel: 'Done',
      onHeaderAction: () => Navigator.maybePop(context),
      primaryLabel: 'Copy message to share',
      onPrimary: () => copyText(context, _shareText(request), 'Copied. Paste it into any chat.'),
      secondaryLabel: 'Done',
      onSecondary: () => Navigator.maybePop(context),
      child: Column(
        children: [
          WhiteCard(
            child: Column(
              children: [
                Text(formatLeone(asDouble(request['amount'])), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                if (asStr(request['note']).isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(asStr(request['note']), style: const TextStyle(color: TpColors.muted))),
                const SizedBox(height: 14),
                const Text('Request code', style: TextStyle(color: TpColors.muted)),
                Text(asStr(request['code']), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: 5)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => copyText(context, asStr(request['link']), 'Link copied.'),
            icon: const Icon(Icons.link, size: 18),
            label: const Text('Copy link only'),
          ),
        ],
      ),
    );
  }
}

/// Type a request code, then confirm and pay.
class PayRequestScreen extends StatefulWidget {
  const PayRequestScreen({super.key});

  @override
  State<PayRequestScreen> createState() => _PayRequestScreenState();
}

class _PayRequestScreenState extends State<PayRequestScreen> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final code = _code.text.trim().toUpperCase();
    if (code.length < 6) {
      setState(() => _error = 'Enter the request code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await api.requestByCode(code);
      if (!mounted) return;
      if (r == null) {
        setState(() => _error = 'We could not find a request with that code.');
        return;
      }
      replaceScreen(context, RequestDetailScreen(request: r));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      eyebrow: 'REQUEST MONEY',
      title: 'Pay a request',
      subtitle: 'Enter the 8-character code from the message you received.',
      primaryLabel: 'Find request',
      primaryLoading: _busy,
      onPrimary: _busy ? null : _next,
      secondaryLabel: 'Back',
      onSecondary: () => Navigator.maybePop(context),
      child: Column(
        children: [
          TpField(label: 'Request code', controller: _code, hint: 'ABCD2345', maxLength: 8),
          if (_error != null) ...[const SizedBox(height: 16), ErrorBanner(_error!)],
        ],
      ),
    );
  }
}

/// One request: pay or decline it (when it was asked of you), or share / cancel it (when it is yours).
class RequestDetailScreen extends StatefulWidget {
  const RequestDetailScreen({super.key, required this.request});

  final Map<String, dynamic> request;

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  bool _busy = false;
  String? _error;

  Map<String, dynamic> get r => widget.request;
  bool get _incoming => asStr(r['direction']) == 'incoming';
  bool get _pending => asStr(r['status']) == 'pending';

  Future<void> _pay() async {
    final amount = asDouble(r['amount']);
    final who = asStr(r['requesterName']);
    final id = asStr(r['id']);
    await openScreen(
      context,
      PayConfirmScreen(
        eyebrow: 'REQUEST MONEY',
        counter: '02 / 02',
        title: 'Confirm payment',
        bannerLabel: 'You are paying',
        total: amount,
        payLabel: 'Pay $who',
        rows: [
          ('To', who),
          if (asStr(r['note']).isNotEmpty) ('For', asStr(r['note'])),
          ('Balance after', formatLeone(appState.balance - amount)),
        ],
        onPay: (pin, key) => api.payRequest(id: id, pin: pin, idempotencyKey: key),
        successBuilder: (result) => PaySuccessScreen(
          eyebrow: 'REQUEST MONEY',
          counter: '02 / 02',
          headline: 'Request paid',
          detail: '${formatLeone(amount)} sent to $who.',
          rows: [('To', who), ('Amount', formatLeone(amount)), ('Reference', result.transaction.reference)],
        ),
      ),
    );
  }

  Future<void> _act(Future<void> Function() run, String done) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await run();
      if (!mounted) return;
      showMessage(context, done);
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = asStr(r['id']);
    return PlainScaffold(
      title: _incoming ? 'Payment request' : 'Your request',
      child: Column(
        children: [
          WhiteCard(
            child: Column(
              children: [
                Text(_incoming ? '${asStr(r['requesterName'])} is asking for' : (r['open'] == true ? 'Payment link for' : 'You asked ${asStr(r['payerName'])} for'),
                    textAlign: TextAlign.center, style: const TextStyle(color: TpColors.muted)),
                const SizedBox(height: 6),
                Text(formatLeone(asDouble(r['amount'])), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                if (asStr(r['note']).isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(asStr(r['note']))),
                const SizedBox(height: 10),
                Text(_statusLabel(asStr(r['status'])), style: TextStyle(fontWeight: FontWeight.w700, color: _pending ? TpColors.primary : TpColors.muted)),
                const SizedBox(height: 4),
                Text('Code ${asStr(r['code'])}', style: const TextStyle(color: TpColors.muted)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_error != null) ...[ErrorBanner(_error!), const SizedBox(height: 12)],
          if (_pending && _incoming) ...[
            PrimaryButton(label: 'Pay ${formatLeone(asDouble(r['amount']))}', onPressed: _busy ? () {} : _pay),
            const SizedBox(height: 8),
            if (r['open'] != true) SecondaryButton(label: 'Decline', onPressed: _busy ? null : () => _act(() => api.declineRequest(id), 'Request declined')),
          ],
          if (_pending && !_incoming) ...[
            PrimaryButton(label: 'Copy message to share', onPressed: () => copyText(context, _shareText(r), 'Copied. Paste it into any chat.')),
            const SizedBox(height: 8),
            SecondaryButton(label: 'Cancel request', onPressed: _busy ? null : () => _act(() => api.cancelRequest(id), 'Request cancelled')),
          ],
        ],
      ),
    );
  }
}
