import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api.dart';
import '../../services/app_state.dart';
import '../../services/trustpay_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/debounce.dart';
import '../../utils/format.dart';
import '../../utils/nav.dart';
import '../../widgets/api_builder.dart';
import '../../widgets/common.dart';
import '../../widgets/flow_widgets.dart';
import '../../widgets/menu_widgets.dart';
import '../flows/generic_flow.dart';

typedef _Json = Map<String, dynamic>;

DateTime? _date(dynamic v) => v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
String _when(dynamic v) {
  final d = _date(v);
  return d == null ? '' : formatShortDateTime(d);
}

Color _statusTone(String s) => switch (s) {
      'Successful' || 'Paid' || 'active' => TpColors.primary,
      'Pending' || 'Processing' => const Color(0xFFB7791F),
      _ => const Color(0xFFC53030),
    };

Widget _pill(String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    );

Widget _searchBox(String hint, ValueChanged<String> onChanged) => TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: TpColors.muted),
        prefixIcon: const Icon(Icons.search, color: TpColors.muted),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
      ),
    );

Widget _kv(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(k, style: const TextStyle(color: TpColors.muted, fontSize: 13))),
          Expanded(child: Text(v.isEmpty ? '—' : v, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
        ],
      ),
    );

/// A reusable paged list: owns paging, search and errors. [fetch] returns one page.
class _PagedView extends StatefulWidget {
  const _PagedView({super.key, required this.fetch, required this.rowBuilder, this.empty = 'Nothing here yet.'});

  final Future<PagedList<_Json>> Function(int page) fetch;
  final Widget Function(BuildContext context, _Json item) rowBuilder;
  final String empty;

  @override
  State<_PagedView> createState() => _PagedViewState();
}

class _PagedViewState extends State<_PagedView> {
  final _items = <_Json>[];
  int _page = 1;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _round = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final round = ++_round;
    setState(() {
      _loading = true;
      _loadingMore = false;
      _error = null;
    });
    try {
      final res = await widget.fetch(1);
      if (!mounted || round != _round) return;
      setState(() {
        _items
          ..clear()
          ..addAll(res.items);
        _page = res.page;
        _hasMore = res.hasMore;
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

  Future<void> _more() async {
    if (_loadingMore || !_hasMore) return;
    final round = _round;
    setState(() => _loadingMore = true);
    try {
      final res = await widget.fetch(_page + 1);
      if (!mounted || round != _round) return;
      setState(() {
        _items.addAll(res.items);
        _page = res.page;
        _hasMore = res.hasMore;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted || round != _round) return;
      setState(() => _loadingMore = false);
      showMessage(context, errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: CircularProgressIndicator());
    }
    if (_error != null) return ErrorRetry(message: _error!, onRetry: _load);
    if (_items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Text(widget.empty, style: const TextStyle(color: TpColors.muted)),
      );
    }
    return Column(
      children: [
        MenuGroup(children: [for (final it in _items) widget.rowBuilder(context, it)]),
        if (_hasMore) ...[
          const SizedBox(height: 14),
          _loadingMore ? const CircularProgressIndicator() : SecondaryButton(label: 'Load more', onPressed: _more),
        ],
      ],
    );
  }
}

// ------------------------------------------------------- all transactions

Widget _txnRow(BuildContext context, _Json t, {bool showOwner = true}) {
  final amount = (t['amount'] as num?)?.toDouble() ?? 0;
  final status = asStr(t['status']);
  return InkWell(
    key: ValueKey(asStr(t['id'])),
    onTap: () => _showTxn(context, t),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(asStr(t['title']), maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  [if (showOwner) asStr(t['owner']), _when(t['createdAt'])].where((e) => e.isNotEmpty).join(' · '),
                  style: const TextStyle(fontSize: 12.5, color: TpColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatLeone(amount, showSign: true),
                  style: TextStyle(fontWeight: FontWeight.w800, color: amount >= 0 ? TpColors.primary : null)),
              const SizedBox(height: 4),
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (t['needsReview'] == true) ...[
                  const Icon(Icons.flag_outlined, size: 15, color: Color(0xFFC53030)),
                  const SizedBox(width: 4),
                ],
                _pill(status, _statusTone(status)),
              ]),
            ],
          ),
        ],
      ),
    ),
  );
}

void _showTxn(BuildContext context, _Json t) {
  final rawRows = t['receipt'] is Map ? (t['receipt'] as Map)['rows'] : null;
  final rows = rawRows is List ? rawRows : const [];
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (c) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(asStr(t['title']), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(formatLeone((t['amount'] as num?)?.toDouble() ?? 0, showSign: true),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            _kv('Status', asStr(t['status'])),
            _kv('Reference', asStr(t['reference'])),
            _kv('Customer', asStr(t['owner'])),
            _kv('Account', asStr(t['ownerAccount'])),
            _kv('Type', asStr(t['subtype'])),
            _kv('Date', _when(t['createdAt'])),
            if (asStr(t['provider']).isNotEmpty) _kv('Provider ref', asStr(t['provider'])),
            if (asStr(t['failureReason']).isNotEmpty) _kv('Failure', asStr(t['failureReason'])),
            if (t['needsReview'] == true) _kv('Flag', 'Needs review'),
            for (final r in rows)
              if (r is List && r.length >= 2) _kv(r[0].toString(), r[1].toString()),
            const SizedBox(height: 14),
            SecondaryButton(label: 'Close', onPressed: () => Navigator.pop(c)),
          ],
        ),
      ),
    ),
  );
}

/// Staff ledger of every transaction (or one customer's, when [userId] is set).
class AdminTransactionsScreen extends StatefulWidget {
  const AdminTransactionsScreen({super.key, this.userId, this.title = 'All transactions'});

  final String? userId;
  final String title;

  @override
  State<AdminTransactionsScreen> createState() => _AdminTransactionsScreenState();
}

class _AdminTransactionsScreenState extends State<AdminTransactionsScreen> {
  final _debounce = Debouncer();
  String _service = 'all';
  String? _status;
  bool _review = false;
  String _q = '';
  int _gen = 0;

  @override
  void dispose() {
    _debounce.dispose();
    super.dispose();
  }

  Widget _chip(String label, bool on, VoidCallback tap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(label: Text(label), selected: on, onSelected: (_) => tap()),
      );

  @override
  Widget build(BuildContext context) {
    return PlainScaffold(
      title: widget.title,
      child: Column(
        children: [
          _searchBox('Search reference, name or account', (v) {
            _q = v;
            _debounce.run(() => setState(() => _gen++));
          }),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final s in const ['all', 'transfer', 'bill', 'airtime', 'funding'])
                _chip(_capitalize(s), _service == s, () => setState(() {
                      _service = s;
                      _gen++;
                    })),
            ]),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _chip('Any status', _status == null && !_review, () => setState(() {
                    _status = null;
                    _review = false;
                    _gen++;
                  })),
              for (final s in const ['Successful', 'Pending', 'Failed'])
                _chip(s, _status == s, () => setState(() {
                      _status = s;
                      _review = false;
                      _gen++;
                    })),
              _chip('Needs review', _review, () => setState(() {
                    _review = true;
                    _status = null;
                    _gen++;
                  })),
            ]),
          ),
          const SizedBox(height: 10),
          _PagedView(
            key: ValueKey('$_gen'),
            empty: 'No transactions match.',
            fetch: (page) => api.adminTransactions(
              service: _service,
              status: _status,
              userId: widget.userId,
              q: _q.trim().isEmpty ? null : _q.trim(),
              review: _review,
              page: page,
            ),
            rowBuilder: (c, t) => _txnRow(c, t, showOwner: widget.userId == null),
          ),
        ],
      ),
    );
  }
}

String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

// ------------------------------------------------------------ user profile

/// One customer: balance, status, manual credit/debit, suspend and recent activity.
class AdminUserDetailScreen extends StatefulWidget {
  const AdminUserDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  int _gen = 0;

  Future<void> _toggleStatus(_Json u) async {
    final suspend = asStr(u['status']) != 'suspended';
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(suspend ? 'Suspend account?' : 'Reactivate account?'),
        content: Text(suspend
            ? '${asStr(u['name'])} will be signed out and cannot make payments until reactivated.'
            : '${asStr(u['name'])} will be able to sign in and pay again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(d, true), child: Text(suspend ? 'Suspend' : 'Reactivate')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await api.setUserStatus(widget.userId, suspend ? 'suspended' : 'active');
      if (!mounted) return;
      setState(() => _gen++);
    } catch (e) {
      if (mounted) showMessage(context, errorMessage(e));
    }
  }

  Future<void> _changeTier(_Json u) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 6, bottom: 8),
                child: Text('Set account tier', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ),
              for (final t in _tierNames)
                ListTile(
                  title: Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
                  trailing: t == asStr(u['tier']) ? const Icon(Icons.check, color: TpColors.primary) : null,
                  onTap: () => Navigator.pop(c, t),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || picked == asStr(u['tier']) || !mounted) return;
    try {
      await api.adminSetTier(widget.userId, picked);
      if (!mounted) return;
      showMessage(context, 'Tier changed to $picked');
      setState(() => _gen++);
    } catch (e) {
      if (mounted) showMessage(context, errorMessage(e));
    }
  }

  Future<void> _unlock() async {
    try {
      await api.adminUnlockUser(widget.userId);
      if (!mounted) return;
      showMessage(context, 'PIN lock cleared');
      setState(() => _gen++);
    } catch (e) {
      if (mounted) showMessage(context, errorMessage(e));
    }
  }

  Future<void> _adjust(_Json u) async {
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (c) => _AdjustSheet(userId: widget.userId, name: asStr(u['name']), balance: (u['balance'] as num?)?.toDouble() ?? 0),
    );
    if (done == true && mounted) setState(() => _gen++);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = appState.me.isAdmin;
    return PlainScaffold(
      title: 'Customer',
      child: ApiBuilder<_Json>(
        key: ValueKey(_gen),
        load: () => api.adminUserDetail(widget.userId),
        builder: (context, data, reload) {
          final u = asMap(data['user']);
          final recent = asMapList(data['recent']);
          final status = asStr(u['status']);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Avatar(name: asStr(u['name']), size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(asStr(u['name']), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    Text(asStr(u['phone']), style: const TextStyle(color: TpColors.muted)),
                  ]),
                ),
                _pill(status, _statusTone(status == 'suspended' ? 'Failed' : status == 'active' ? 'Paid' : 'Pending')),
              ]),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: TpColors.tint, borderRadius: BorderRadius.circular(18)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Wallet balance', style: TextStyle(color: TpColors.muted, fontSize: 13)),
                  Text(formatLeone((u['balance'] as num?)?.toDouble() ?? 0),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                ]),
              ),
              const SizedBox(height: 12),
              _kv('Tier', asStr(u['tier'])),
              _kv('Email', asStr(u['email'])),
              _kv('Account no.', asStr(u['accountNumber'])),
              _kv('Identity check', asStr(u['kycStatus'])),
              _kv('Last sign-in', _when(u['lastLoginAt'])),
              _kv('Joined', _when(u['createdAt'])),
              if (u['locked'] == true) _kv('PIN', 'Locked after failed attempts'),
              const SizedBox(height: 16),
              if (isAdmin) ...[
                PrimaryButton(label: 'Credit or debit balance', onPressed: () => _adjust(u)),
                const SizedBox(height: 8),
                SecondaryButton(label: 'Change tier (${asStr(u['tier'])})', onPressed: () => _changeTier(u)),
                const SizedBox(height: 8),
                SecondaryButton(
                  label: u['isAgent'] == true ? 'Remove agent (code ${asStr(u['agentCode'])})' : 'Make agent',
                  onPressed: () async {
                    try {
                      await api.adminSetAgent(widget.userId, u['isAgent'] != true);
                      if (mounted) setState(() => _gen++);
                    } catch (e) {
                      if (mounted) showMessage(context, errorMessage(e));
                    }
                  },
                ),
                const SizedBox(height: 8),
                SecondaryButton(
                  label: 'Send notification',
                  onPressed: () => openScreen(context, AdminNotifyScreen(userId: widget.userId, userName: asStr(u['name']))),
                ),
                const SizedBox(height: 8),
                if (status != 'pending_kyc')
                  SecondaryButton(
                    label: status == 'suspended' ? 'Reactivate account' : 'Suspend account',
                    onPressed: () => _toggleStatus(u),
                  ),
                if (u['locked'] == true) ...[
                  const SizedBox(height: 8),
                  SecondaryButton(label: 'Clear PIN lock', onPressed: _unlock),
                ],
                const SizedBox(height: 8),
              ],
              SecondaryButton(
                label: 'All transactions for ${asStr(u['name'])}',
                onPressed: () => openScreen(
                  context,
                  AdminTransactionsScreen(userId: widget.userId, title: asStr(u['name'])),
                ),
              ),
              if (data['hasTerminal'] == true) ...[
                const SizedBox(height: 8),
                SecondaryButton(
                  label: 'POS activity',
                  onPressed: () => openScreen(context, AdminPosScreen(ownerId: widget.userId, title: asStr(u['name']))),
                ),
              ],
              const SizedBox(height: 18),
              const Text('RECENT ACTIVITY',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: TpColors.muted)),
              const SizedBox(height: 8),
              if (recent.isEmpty)
                const Text('No transactions yet.', style: TextStyle(color: TpColors.muted))
              else
                MenuGroup(children: [for (final t in recent) _txnRow(context, t, showOwner: false)]),
            ],
          );
        },
      ),
    );
  }
}

class _AdjustSheet extends StatefulWidget {
  const _AdjustSheet({required this.userId, required this.name, required this.balance});

  final String userId;
  final String name;
  final double balance;

  @override
  State<_AdjustSheet> createState() => _AdjustSheetState();
}

class _AdjustSheetState extends State<_AdjustSheet> {
  final _amount = TextEditingController();
  final _reason = TextEditingController();
  // One key per sheet: a double tap or retry can never apply the adjustment twice.
  final String _key = newIdempotencyKey();
  String _type = 'credit';
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amount.text.replaceAll(',', '').trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter an amount greater than zero.');
      return;
    }
    if (_reason.text.trim().length < 5) {
      setState(() => _error = 'Give a reason of at least 5 characters (it is kept in the audit trail).');
      return;
    }
    if (_type == 'debit' && amount > widget.balance) {
      setState(() => _error = 'That is more than the customer\'s balance.');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(_type == 'credit' ? 'Credit account?' : 'Debit account?'),
        content: Text('${_type == 'credit' ? 'Add' : 'Remove'} ${formatLeone(amount)} '
            '${_type == 'credit' ? 'to' : 'from'} ${widget.name}\'s wallet.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await api.adminAdjustBalance(widget.userId, type: _type, amount: amount, reason: _reason.text.trim(), key: _key);
      if (!mounted) return;
      Navigator.pop(context, true);
      showMessage(context, _type == 'credit' ? 'Account credited' : 'Account debited');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = errorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Adjust ${widget.name}\'s balance', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Current balance ${formatLeone(widget.balance)}', style: const TextStyle(color: TpColors.muted)),
            const SizedBox(height: 14),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'credit', label: Text('Credit (add)')),
                ButtonSegment(value: 'debit', label: Text('Debit (remove)')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 14),
            TpField(label: 'Amount', controller: _amount, hint: '0.00', allowDecimal: true, prefixText: kCurrencySymbol),
            const SizedBox(height: 12),
            TpField(label: 'Reason (audit trail)', controller: _reason, hint: 'e.g. Refund for failed bank payout', maxLength: 200),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Color(0xFFC53030), fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 16),
            PrimaryButton(label: _type == 'credit' ? 'Credit account' : 'Debit account', loading: _busy, onPressed: _busy ? () {} : _submit),
            const SizedBox(height: 8),
            SecondaryButton(label: 'Cancel', onPressed: () => Navigator.pop(context, false)),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ merchants / POS

/// Merchants & POS: totals plus terminals, POS payments and payouts (settlements).
class AdminPosScreen extends StatefulWidget {
  const AdminPosScreen({super.key, this.ownerId, this.title = 'Merchants & POS'});

  final String? ownerId;
  final String title;

  @override
  State<AdminPosScreen> createState() => _AdminPosScreenState();
}

class _AdminPosScreenState extends State<AdminPosScreen> {
  String _tab = 'payments';

  Widget _kpi(String label, String value) => Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 11.5, color: TpColors.muted)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ]),
        ),
      );

  Widget _terminalRow(BuildContext c, _Json t) => Padding(
        key: ValueKey(asStr(t['id'])),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          const Icon(Icons.point_of_sale, color: TpColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${asStr(t['code'])} · ${asStr(t['businessName']).isEmpty ? asStr(t['owner']) : asStr(t['businessName'])}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              Text([asStr(t['owner']), asStr(t['location'])].where((e) => e.isNotEmpty).join(' · '),
                  style: const TextStyle(fontSize: 12.5, color: TpColors.muted)),
              if (_when(t['lastSync']).isNotEmpty)
                Text('Last sync ${_when(t['lastSync'])}', style: const TextStyle(fontSize: 12, color: TpColors.muted)),
            ]),
          ),
          _pill(asStr(t['status']), _statusTone(asStr(t['status']))),
        ]),
      );

  Widget _paymentRow(BuildContext c, _Json p) => Padding(
        key: ValueKey(asStr(p['id'])),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(asStr(p['owner']), style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(
                '${asStr(p['terminalCode'])} · ${_capitalize(asStr(p['kind']))} · ${_when(p['createdAt'])}\n${asStr(p['reference'])}',
                style: const TextStyle(fontSize: 12.5, color: TpColors.muted),
              ),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(formatLeone((p['amount'] as num?)?.toDouble() ?? 0), style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            _pill(p['settled'] == true ? 'Paid out' : 'Unsettled', p['settled'] == true ? TpColors.primary : const Color(0xFFB7791F)),
          ]),
        ]),
      );

  Widget _payoutRow(BuildContext c, _Json s) => Padding(
        key: ValueKey(asStr(s['id'])),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(asStr(s['owner']), style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(
                '${asStr(s['reference'])} · ${asInt(s['count'])} payments\n'
                'Gross ${formatLeone((s['gross'] as num?)?.toDouble() ?? 0)} · Fee ${formatLeone((s['fee'] as num?)?.toDouble() ?? 0)}\n'
                '${asStr(s['status']) == 'Paid' ? 'Paid ${_when(s['settledAt'])}' : 'Due ${_when(s['scheduledFor'])}'} → ${asStr(s['destination'])}',
                style: const TextStyle(fontSize: 12.5, color: TpColors.muted),
              ),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(formatLeone((s['net'] as num?)?.toDouble() ?? 0), style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            _pill(asStr(s['status']), _statusTone(asStr(s['status']))),
          ]),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final what = switch (_tab) {
      'terminals' => 'terminals',
      'payouts' => 'settlements',
      _ => 'payments',
    };
    return PlainScaffold(
      title: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.ownerId == null)
            ApiBuilder<_Json>(
              load: api.adminPosOverview,
              builder: (context, o, reload) => Column(children: [
                Row(children: [
                  _kpi('Active terminals', '${asInt(o['activeTerminals'])}'),
                  _kpi('POS volume', formatLeone((o['paymentsVolume'] as num?)?.toDouble() ?? 0, decimals: 0)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  _kpi('Payouts processing', formatLeone((o['payoutsProcessing'] as num?)?.toDouble() ?? 0, decimals: 0)),
                  _kpi('Paid out', formatLeone((o['payoutsPaid'] as num?)?.toDouble() ?? 0, decimals: 0)),
                ]),
                const SizedBox(height: 14),
              ]),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final t in const [('payments', 'POS transactions'), ('payouts', 'Payouts'), ('terminals', 'Terminals')])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(label: Text(t.$2), selected: _tab == t.$1, onSelected: (_) => setState(() => _tab = t.$1)),
                ),
            ]),
          ),
          const SizedBox(height: 10),
          _PagedView(
            key: ValueKey('$_tab${widget.ownerId}'),
            empty: 'Nothing here yet.',
            fetch: (page) => api.adminPosList(what, ownerId: widget.ownerId, page: page),
            rowBuilder: switch (_tab) {
              'terminals' => _terminalRow,
              'payouts' => _payoutRow,
              _ => _paymentRow,
            },
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- tiers & documents

const _tierNames = ['Tier 1 · Basic', 'Tier 2 · Verified', 'Tier 3 · Premium'];

/// Shows an uploaded proof document (utility bill, business registration) to staff.
class AdminDocumentScreen extends StatelessWidget {
  const AdminDocumentScreen({super.key, required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context) {
    return PlainScaffold(
      title: 'Document',
      child: ApiBuilder<_Json>(
        load: () => api.adminDocument(documentId),
        builder: (context, d, reload) {
          final mime = asStr(d['mime']);
          if (mime == 'application/pdf') {
            return const InfoBanner(text: 'This document is a PDF, which cannot be shown here.');
          }
          final bytes = base64Decode(asStr(d['data']));
          return Column(
            children: [
              ClipRRect(borderRadius: BorderRadius.circular(14), child: InteractiveViewer(child: Image.memory(bytes))),
              const SizedBox(height: 10),
              Text('Pinch to zoom · ${(bytes.length / 1024).round()} KB', style: const TextStyle(color: TpColors.muted, fontSize: 12.5)),
            ],
          );
        },
      ),
    );
  }
}

/// Admin: the limits for each tier (daily spending and maximum balance). Empty = unlimited.
class AdminTiersScreen extends StatefulWidget {
  const AdminTiersScreen({super.key});

  @override
  State<AdminTiersScreen> createState() => _AdminTiersScreenState();
}

class _AdminTiersScreenState extends State<AdminTiersScreen> {
  final _daily = {for (final t in _tierNames) t: TextEditingController()};
  final _balance = {for (final t in _tierNames) t: TextEditingController()};
  Map<String, dynamic> _counts = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [..._daily.values, ..._balance.values]) {
      c.dispose();
    }
    super.dispose();
  }

  String _fmt(dynamic v) => v == null ? '' : (v as num).toStringAsFixed(v == v.roundToDouble() ? 0 : 2);

  void _fill(Map<String, dynamic> r) {
    final limits = asMap(r['limits']);
    for (final t in _tierNames) {
      final l = asMap(limits[t]);
      _daily[t]!.text = _fmt(l['daily']);
      _balance[t]!.text = _fmt(l['balance']);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await api.adminTiers();
      if (!mounted) return;
      _fill(r);
      setState(() {
        _counts = asMap(r['counts']);
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = errorMessage(e);
          _loading = false;
        });
      }
    }
  }

  dynamic _num(String text) {
    final t = text.replaceAll(',', '').trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  Future<void> _save() async {
    final body = <String, dynamic>{};
    for (final t in _tierNames) {
      final d = _daily[t]!.text.trim();
      final b = _balance[t]!.text.trim();
      if ((d.isNotEmpty && _num(d) == null) || (b.isNotEmpty && _num(b) == null)) {
        setState(() => _error = 'Enter numbers only (leave empty for unlimited).');
        return;
      }
      body[t] = {'daily': _num(d), 'balance': _num(b)};
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final r = await api.adminSaveTiers(body);
      if (!mounted) return;
      _fill(r);
      showMessage(context, 'Tier limits saved');
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = appState.me.isAdmin;
    return PlainScaffold(
      title: 'Tiers & limits',
      child: _loading
          ? const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final t in _tierNames) ...[
                  WhiteCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                        Text('${asInt(_counts[t])} customers', style: const TextStyle(color: TpColors.muted, fontSize: 13)),
                        const SizedBox(height: 12),
                        TpField(
                          label: 'Daily spending limit (Le)',
                          controller: _daily[t],
                          hint: 'Empty = unlimited',
                          allowDecimal: true,
                          readOnly: !canEdit,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                        const SizedBox(height: 12),
                        TpField(
                          label: 'Maximum balance (Le)',
                          controller: _balance[t],
                          hint: 'Empty = unlimited',
                          allowDecimal: true,
                          readOnly: !canEdit,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_error != null) ...[ErrorBanner(_error!), const SizedBox(height: 12)],
                if (canEdit) PrimaryButton(label: 'Save limits', loading: _saving, onPressed: _saving ? () {} : _save),
                const SizedBox(height: 12),
                const InfoBanner(
                  text: 'Limits apply at once. Customers move up a tier by sending proof from Profile; you approve it under Approvals, or set a tier yourself on a customer\'s profile.',
                ),
              ],
            ),
    );
  }
}

// --------------------------------------------------------------- notifications

const _kinds = [
  ('update', 'Update'),
  ('maintenance', 'Maintenance'),
  ('feature', 'New feature'),
  ('approval', 'Approval'),
  ('message', 'Message'),
];

/// Admin: send a notification to everyone, one tier, merchants or one customer. Also lists what was sent
/// and lets each staff member choose which alerts they receive (signups, top-ups, payments...).
class AdminNotifyScreen extends StatefulWidget {
  const AdminNotifyScreen({super.key, this.userId, this.userName});

  /// Opens the form already aimed at one customer.
  final String? userId;
  final String? userName;

  @override
  State<AdminNotifyScreen> createState() => _AdminNotifyScreenState();
}

class _AdminNotifyScreenState extends State<AdminNotifyScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  late String _audience;
  String _tier = _tierNames.first;
  String _kind = 'update';
  bool _busy = false;
  String? _error;
  int _gen = 0;

  @override
  void initState() {
    super.initState();
    _audience = widget.userId != null ? 'user' : 'all';
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  String get _who => switch (_audience) {
        'all' => 'all customers',
        'tier' => 'everyone on $_tier',
        'merchants' => 'all merchants',
        _ => widget.userName ?? 'this customer',
      };

  Future<void> _send() async {
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'Add a title.');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Send notification?'),
        content: Text('"${_title.text.trim()}" will be sent to $_who.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Send')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final n = await api.adminSendNotification(
        audience: _audience,
        tier: _audience == 'tier' ? _tier : null,
        userId: _audience == 'user' ? widget.userId : null,
        kind: _kind,
        title: _title.text.trim(),
        body: _body.text.trim(),
      );
      if (!mounted) return;
      showMessage(context, 'Sent to $n ${n == 1 ? 'person' : 'people'}');
      _title.clear();
      _body.clear();
      setState(() => _gen++);
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _choice(String label, bool on, VoidCallback tap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(label: Text(label), selected: on, onSelected: (_) => tap()),
      );

  @override
  Widget build(BuildContext context) {
    final canSend = appState.me.isAdmin;
    return PlainScaffold(
      title: 'Notifications',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canSend) ...[
            const Text('SEND TO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: TpColors.muted)),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                if (widget.userId != null) _choice(widget.userName ?? 'This customer', _audience == 'user', () => setState(() => _audience = 'user')),
                _choice('Everyone', _audience == 'all', () => setState(() => _audience = 'all')),
                _choice('A tier', _audience == 'tier', () => setState(() => _audience = 'tier')),
                _choice('Merchants', _audience == 'merchants', () => setState(() => _audience = 'merchants')),
              ]),
            ),
            if (_audience == 'tier') ...[
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [for (final t in _tierNames) _choice(t, _tier == t, () => setState(() => _tier = t))]),
              ),
            ],
            const SizedBox(height: 14),
            const Text('TYPE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: TpColors.muted)),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [for (final k in _kinds) _choice(k.$2, _kind == k.$1, () => setState(() => _kind = k.$1))]),
            ),
            const SizedBox(height: 14),
            TpField(label: 'Title', controller: _title, hint: 'e.g. Scheduled maintenance tonight', maxLength: 100),
            const SizedBox(height: 12),
            TpField(label: 'Message (optional)', controller: _body, hint: 'Details customers should know', maxLength: 500),
            if (_error != null) ...[const SizedBox(height: 12), ErrorBanner(_error!)],
            const SizedBox(height: 14),
            PrimaryButton(label: 'Send to $_who', loading: _busy, onPressed: _busy ? () {} : _send),
            const SizedBox(height: 22),
          ] else
            const InfoBanner(text: 'Only admins can send notifications. You can still choose which alerts you receive below.'),
          const Text('YOUR ALERTS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: TpColors.muted)),
          const SizedBox(height: 6),
          ApiBuilder<Map<String, dynamic>>(
            load: api.notificationPrefs,
            builder: (context, prefs, reload) => _PrefsCard(prefs: prefs),
          ),
          const SizedBox(height: 22),
          const Text('RECENTLY SENT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: TpColors.muted)),
          const SizedBox(height: 6),
          ApiBuilder<List<Map<String, dynamic>>>(
            key: ValueKey(_gen),
            load: api.adminNotificationHistory,
            builder: (context, rows, reload) => rows.isEmpty
                ? const Text('Nothing sent yet.', style: TextStyle(color: TpColors.muted))
                : MenuGroup(children: [
                    for (final r in rows)
                      Padding(
                        key: ValueKey(asStr(r['id'])),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(asStr(r['title']), style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text('${_capitalize(asStr(r['kind']))} · to ${asStr(r['audience'])} · ${asInt(r['count'])} people · ${_when(r['createdAt'])}',
                              style: const TextStyle(fontSize: 12.5, color: TpColors.muted)),
                        ]),
                      ),
                  ]),
          ),
        ],
      ),
    );
  }
}

class _PrefsCard extends StatefulWidget {
  const _PrefsCard({required this.prefs});

  final Map<String, dynamic> prefs;

  @override
  State<_PrefsCard> createState() => _PrefsCardState();
}

class _PrefsCardState extends State<_PrefsCard> {
  late Map<String, dynamic> _prefs = Map.of(widget.prefs);

  static const _labels = {
    'signup': 'New signups',
    'approval': 'Things waiting for approval',
    'funding': 'Wallet top-ups',
    'payment': 'Payments and transfers',
    'alert': 'Failed payments',
  };

  Future<void> _set(String key, bool v) async {
    setState(() => _prefs[key] = v);
    try {
      final saved = await api.setNotificationPrefs({key: v});
      if (mounted) setState(() => _prefs = Map.of(saved));
    } catch (e) {
      if (mounted) {
        setState(() => _prefs[key] = !v);
        showMessage(context, errorMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) => MenuGroup(children: [
        for (final e in _labels.entries)
          SwitchListTile(
            title: Text(e.value, style: const TextStyle(fontWeight: FontWeight.w600)),
            value: _prefs[e.key] != false,
            onChanged: (v) => _set(e.key, v),
          ),
      ]);
}

// --------------------------------------------------------------------- reports

/// Admin reports: totals, daily trend, services, tiers and top customers for a period. CSV export of every transaction.
class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String _preset = '7';
  int _gen = 0;

  (DateTime, DateTime) get _range {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (_preset) {
      'today' => (today, today),
      'month' => (DateTime(now.year, now.month, 1), today),
      '30' => (today.subtract(const Duration(days: 29)), today),
      '90' => (today.subtract(const Duration(days: 89)), today),
      _ => (today.subtract(const Duration(days: 6)), today),
    };
  }

  Future<void> _export() async {
    final (from, to) = _range;
    try {
      final r = await api.adminReportCsv(from: from, to: to);
      if (!mounted) return;
      await copyText(context, asStr(r['csv']), 'Copied ${asInt(r['count'])} transactions. Paste into a spreadsheet.');
      if (mounted && r['truncated'] == true) showMessage(context, 'Only the first 20,000 rows were copied. Pick a shorter period.');
    } catch (e) {
      if (mounted) showMessage(context, errorMessage(e));
    }
  }

  Widget _chip(String label, String key) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(label: Text(label), selected: _preset == key, onSelected: (_) => setState(() {
              _preset = key;
              _gen++;
            })),
      );

  Widget _tile(String label, String value) => Expanded(
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 12, color: TpColors.muted)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final (from, to) = _range;
    return PlainScaffold(
      title: 'Reports',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [_chip('Today', 'today'), _chip('7 days', '7'), _chip('30 days', '30'), _chip('This month', 'month'), _chip('90 days', '90')]),
          ),
          const SizedBox(height: 12),
          ApiBuilder<_Json>(
            key: ValueKey('$_preset$_gen'),
            load: () => api.adminReport(from: from, to: to),
            builder: (context, d, reload) {
              final t = asMap(d['totals']);
              final daily = asMapList(d['daily']);
              final maxOut = daily.fold<double>(1, (m, r) => asDouble(r['moneyOut']) > m ? asDouble(r['moneyOut']) : m);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [_tile('Money out', formatLeone(asDouble(t['moneyOut']))), _tile('Money in (top-ups)', formatLeone(asDouble(t['funding'])))]),
                  Row(children: [_tile('Fees earned', formatLeone(asDouble(t['fees']))), _tile('Transactions', '${asInt(t['transactions'])}')]),
                  Row(children: [_tile('New customers', '${asInt(t['newUsers'])}'), _tile('Active customers', '${asInt(t['activeUsers'])}')]),
                  Row(children: [_tile('Failed', '${asInt(t['failed'])}'), _tile('Pending', '${asInt(t['pending'])}')]),
                  Row(children: [_tile('Total in wallets now', formatLeone(asDouble(t['walletBalances']))), const Expanded(child: SizedBox())]),
                  const SizedBox(height: 18),
                  const Text('DAILY MONEY OUT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: TpColors.muted)),
                  const SizedBox(height: 8),
                  if (daily.isEmpty)
                    const Text('No transactions in this period.', style: TextStyle(color: TpColors.muted))
                  else
                    WhiteCard(
                      child: Column(children: [
                        for (final r in daily.reversed.take(31))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(children: [
                              SizedBox(width: 78, child: Text(asStr(r['date']).substring(5), style: const TextStyle(fontSize: 12, color: TpColors.muted))),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(value: asDouble(r['moneyOut']) / maxOut, minHeight: 10, backgroundColor: const Color(0xFFEEF2FB), color: TpColors.primary),
                                ),
                              ),
                              SizedBox(width: 96, child: Text(formatLeone(asDouble(r['moneyOut'])), textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                            ]),
                          ),
                      ]),
                    ),
                  const SizedBox(height: 18),
                  const Text('BY SERVICE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: TpColors.muted)),
                  const SizedBox(height: 8),
                  MenuGroup(children: [
                    for (final k in asMapList(d['byKind']))
                      ListTile(
                        title: Text(_capitalize(asStr(k['kind']).replaceAll('_', ' ')), style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${asInt(k['count'])} payments · fees ${formatLeone(asDouble(k['fees']))}'),
                        trailing: Text(formatLeone(asDouble(k['volume'])), style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                  ]),
                  const SizedBox(height: 18),
                  const Text('TIERS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: TpColors.muted)),
                  const SizedBox(height: 8),
                  MenuGroup(children: [
                    for (final k in asMapList(d['tiers']))
                      ListTile(
                        title: Text(asStr(k['tier']), style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${asInt(k['users'])} customers'),
                        trailing: Text(formatLeone(asDouble(k['balance'])), style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                  ]),
                  const SizedBox(height: 18),
                  const Text('TOP CUSTOMERS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: TpColors.muted)),
                  const SizedBox(height: 8),
                  MenuGroup(children: [
                    for (final k in asMapList(d['topUsers']))
                      ListTile(
                        title: Text(asStr(k['name']), style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${asInt(k['count'])} payments'),
                        trailing: Text(formatLeone(asDouble(k['volume'])), style: const TextStyle(fontWeight: FontWeight.w800)),
                        onTap: () => openScreen(context, AdminUserDetailScreen(userId: asStr(k['id']))),
                      ),
                  ]),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          SecondaryButton(label: 'Copy all transactions as CSV', onPressed: appState.me.isAdmin ? _export : null),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------- agents

/// Admin: who the agents are, their float and today's work, and what a cash-out costs.
class AdminAgentsScreen extends StatefulWidget {
  const AdminAgentsScreen({super.key});

  @override
  State<AdminAgentsScreen> createState() => _AdminAgentsScreenState();
}

class _AdminAgentsScreenState extends State<AdminAgentsScreen> {
  int _gen = 0;

  Future<void> _editFees(_Json fees) async {
    final pct = TextEditingController(text: '${asDouble(fees['cashOutPercent'])}');
    final min = TextEditingController(text: '${asDouble(fees['minFee'])}');
    final share = TextEditingController(text: '${asDouble(fees['agentSharePercent'])}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Cash-out pricing'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TpField(label: 'Fee % charged to the customer', controller: pct, allowDecimal: true, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 10),
          TpField(label: 'Minimum fee (Le)', controller: min, allowDecimal: true, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 10),
          TpField(label: 'Agent keeps % of the fee', controller: share, allowDecimal: true, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Save')),
        ],
      ),
    );
    final p = double.tryParse(pct.text), m = double.tryParse(min.text), s = double.tryParse(share.text);
    pct.dispose();
    min.dispose();
    share.dispose();
    if (ok != true || !mounted) return;
    try {
      await api.adminSetAgentFees(cashOutPercent: p, minFee: m, agentSharePercent: s);
      if (mounted) setState(() => _gen++);
    } catch (e) {
      if (mounted) showMessage(context, errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlainScaffold(
      title: 'Agents',
      child: ApiBuilder<_Json>(
        key: ValueKey(_gen),
        load: api.adminAgents,
        builder: (context, d, reload) {
          final fees = asMap(d['fees']);
          final items = asMapList(d['items']);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WhiteCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Cash-out pricing', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text('Customer pays ${asDouble(fees['cashOutPercent'])}% (min ${formatLeone(asDouble(fees['minFee']))}). Agent keeps ${asDouble(fees['agentSharePercent'])}% of that fee. Cash in is free for customers.',
                      style: const TextStyle(color: TpColors.muted, height: 1.4)),
                  if (appState.me.isAdmin) TextButton(onPressed: () => _editFees(fees), child: const Text('Change pricing')),
                ]),
              ),
              const SizedBox(height: 14),
              const InfoBanner(text: 'To add an agent, open the customer in Users and tap "Make agent". Set them to Tier 3 so tier limits do not block their float.'),
              const SizedBox(height: 14),
              if (items.isEmpty)
                const Text('No agents yet.', style: TextStyle(color: TpColors.muted))
              else
                MenuGroup(children: [
                  for (final a in items)
                    ListTile(
                      key: ValueKey(asStr(a['id'])),
                      title: Text('${asStr(a['name'])} · ${asStr(a['code'])}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${asStr(a['phone'])} · ${asStr(a['tier'])}\nToday: in ${formatLeone(asDouble(a['todayCashIn']))}, out ${formatLeone(asDouble(a['todayCashOut']))}'),
                      isThreeLine: true,
                      trailing: Text(formatLeone(asDouble(a['float'])), style: const TextStyle(fontWeight: FontWeight.w800)),
                      onTap: () => openScreen(context, AdminUserDetailScreen(userId: asStr(a['id']))),
                    ),
                ]),
            ],
          );
        },
      ),
    );
  }
}
