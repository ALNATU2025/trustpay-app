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
import '../../widgets/step_scaffold.dart';
import 'generic_flow.dart';
import 'receipt_screen.dart';

/// Transaction history, loaded page by page from the server.
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  static const _anyMonth = 'All time';
  static const _anyStatus = 'Any status';
  static const _services = {
    'All services': 'all',
    'Transfers': 'transfer',
    'Bills': 'bill',
    'Airtime': 'airtime',
    'Account funding': 'funding',
  };
  static const _statuses = [_anyStatus, 'Successful', 'Pending', 'Failed'];

  final _search = TextEditingController();
  final _debounce = Debouncer();

  final List<Txn> _items = [];
  int _page = 0;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _requestId = 0;
  int _seenVersion = appState.txnVersion;

  int _tab = 0; // 0 all, 1 money in, 2 money out (applied to the loaded list)
  String _month = _anyMonth;
  String _service = _services.keys.first;
  String _status = _anyStatus;

  /// "All time" and the last six months, newest first.
  late final List<({String label, DateTime from, DateTime to})> _monthRanges = () {
    final now = DateTime.now();
    return [
      for (var i = 0; i < 6; i++)
        (
          label: '${kMonthsFull[DateTime(now.year, now.month - i, 1).month - 1]} ${DateTime(now.year, now.month - i, 1).year}',
          from: DateTime(now.year, now.month - i, 1),
          to: DateTime(now.year, now.month - i + 1, 1).subtract(const Duration(seconds: 1)),
        ),
    ];
  }();

  @override
  void initState() {
    super.initState();
    appState.addListener(_onAppState);
    _reload();
  }

  @override
  void dispose() {
    appState.removeListener(_onAppState);
    _debounce.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onAppState() {
    if (appState.txnVersion != _seenVersion) {
      _seenVersion = appState.txnVersion;
      if (appState.signedIn) _reload();
    }
  }

  ({String label, DateTime from, DateTime to})? get _range {
    for (final r in _monthRanges) {
      if (r.label == _month) return r;
    }
    return null;
  }

  Future<PagedList<Txn>> _fetch(int page) {
    final q = _search.text.trim();
    final range = _range;
    return api.transactions(
      page: page,
      service: _services[_service] ?? 'all',
      status: _status == _anyStatus ? null : _status,
      q: q.isEmpty ? null : q,
      from: range?.from,
      to: range?.to,
    );
  }

  /// Starts again from page 1 with the current filters. Keeps the old list visible while loading.
  Future<void> _reload() async {
    final id = ++_requestId;
    if (mounted) {
      setState(() {
        _loading = _items.isEmpty;
        _loadingMore = false;
        _error = null;
      });
    }
    try {
      final result = await _fetch(1);
      if (!mounted || id != _requestId) return;
      setState(() {
        _items
          ..clear()
          ..addAll(result.items);
        _page = result.page;
        _hasMore = result.hasMore;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _error = errorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _loading || !_hasMore) return;
    final id = _requestId;
    setState(() => _loadingMore = true);
    try {
      final result = await _fetch(_page + 1);
      if (!mounted || id != _requestId) return;
      setState(() {
        _items.addAll(result.items);
        _page = result.page;
        _hasMore = result.hasMore;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() => _loadingMore = false);
      showMessage(context, errorMessage(e));
    }
  }

  List<Txn> get _visible => [
        for (final t in _items)
          if (_tab == 0 || (_tab == 1 && t.isCredit) || (_tab == 2 && !t.isCredit)) t,
      ];

  bool get _filtering =>
      _search.text.trim().isNotEmpty || _month != _anyMonth || _service != _services.keys.first || _status != _anyStatus;

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    final base = '${two(d.day)} ${kMonthsFull[d.month - 1].toUpperCase()}';
    if (diff == 0) return 'TODAY · $base';
    if (diff == 1) return 'YESTERDAY · $base';
    return base;
  }

  IconData _icon(Txn t) => switch (t.kind) {
        TxnKind.transfer => t.isCredit ? Icons.south_west : Icons.north_east,
        TxnKind.funding => Icons.south_west,
        TxnKind.bill => Icons.flash_on_outlined,
        TxnKind.airtime => Icons.smartphone_outlined,
        TxnKind.data => Icons.data_usage_outlined,
        TxnKind.tv => Icons.tv_outlined,
        TxnKind.internet => Icons.wifi,
        TxnKind.card => Icons.credit_card_outlined,
        TxnKind.pos => Icons.point_of_sale_outlined,
        TxnKind.mobileMoney => Icons.phone_android_outlined,
        TxnKind.other => Icons.receipt_long_outlined,
      };

  Color _amountColor(Txn t) {
    if (t.status == 'Failed') return TpColors.muted;
    return t.isCredit ? TpColors.green : TpColors.navy;
  }

  void _open(Txn t) {
    final receipt = t.receipt;
    if (receipt != null) {
      openScreen(context, ReceiptScreen(data: receipt));
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: TpColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              DetailsCard(
                rows: [
                  ('Amount', formatLeone(t.signedAmount, showSign: true)),
                  ('Status', t.status),
                  if (t.meta.isNotEmpty) ('Details', t.meta),
                  ...t.summaryRows,
                ],
              ),
              const SizedBox(height: 12),
              TpWhiteButton(
                label: 'Close',
                onPressed: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Plain-text list of the loaded transactions, copied to the clipboard.
  void _copyStatement() {
    final b = StringBuffer('TrustPay statement · ${appState.me.fullName}\n');
    for (final t in _items) {
      b.writeln(
        '${formatDateTime(t.date)} | ${t.title} | ${formatLeone(t.signedAmount, showSign: true)} | ${t.status}'
        '${t.reference.isEmpty ? '' : ' | ${t.reference}'}',
      );
    }
    copyText(context, b.toString().trim(), 'Statement copied.');
  }

  Widget _content(List<Txn> items) {
    if (_loading) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Center(child: CircularProgressIndicator()));
    }
    if (_error != null && _items.isEmpty) {
      return ErrorRetry(message: _error!, onRetry: _reload);
    }
    if (items.isEmpty) {
      final text = _items.isEmpty && !_filtering ? 'No transactions yet' : 'No transactions match these filters.';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text(text, style: const TextStyle(color: TpColors.muted))),
      );
    }
    final rows = <Widget>[];
    String? lastLabel;
    for (final t in items) {
      final label = _dayLabel(t.date);
      if (label != lastLabel) {
        rows.add(
          Padding(
            padding: EdgeInsets.only(top: lastLabel == null ? 0 : 12, bottom: 4),
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, letterSpacing: 0.4, color: TpColors.muted),
            ),
          ),
        );
        lastLabel = label;
      }
      rows.add(
        ActivityRow(
          icon: _icon(t),
          title: t.title,
          subtitle: t.status == 'Successful' || t.status.isEmpty ? t.meta : '${t.meta} · ${t.status}',
          trailing: formatLeone(t.signedAmount, showSign: true),
          trailingColor: _amountColor(t),
          onTap: () => _open(t),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  @override
  Widget build(BuildContext context) {
    final items = _visible;
    return RefreshIndicator(
      onRefresh: _reload,
      child: StepScaffold(
        eyebrow: 'TRANSACTIONS · FROM HOME / SEE ALL',
        title: 'Transaction history',
        subtitle: 'Your personal account · ${appState.me.fullName}',
        headerLabel: 'Done',
        onHeaderAction: () => goHome(context),
        primaryLabel: 'Copy statement',
        onPrimary: _items.isEmpty ? null : _copyStatement,
        secondaryLabel: 'Back to home',
        onSecondary: () => goHome(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Search transactions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _search,
              onChanged: (_) {
                setState(() {});
                _debounce.run(_reload);
              },
              decoration: tpDecoration(
                hint: 'Name, reference or amount',
                suffix: const Icon(Icons.search, color: TpColors.primary),
              ),
            ),
            const SizedBox(height: 16),
            SegmentedTabs(
              labels: const ['All', 'Money in', 'Money out'],
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterPill(
                    label: _month,
                    options: [_anyMonth, for (final r in _monthRanges) r.label],
                    onSelected: (v) {
                      setState(() => _month = v);
                      _reload();
                    },
                  ),
                  const SizedBox(width: 10),
                  _FilterPill(
                    label: _service,
                    options: _services.keys.toList(),
                    onSelected: (v) {
                      setState(() => _service = v);
                      _reload();
                    },
                  ),
                  const SizedBox(width: 10),
                  _FilterPill(
                    label: _status,
                    options: _statuses,
                    onSelected: (v) {
                      setState(() => _status = v);
                      _reload();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            WhiteCard(child: _content(items)),
            if (_hasMore && !_loading)
              Center(
                child: _loadingMore
                    ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())
                    : TextButton(
                        onPressed: _loadMore,
                        child: const Text('Load more', style: TextStyle(fontSize: 15)),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.options, required this.onSelected});

  final String label;
  final List<String> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: label,
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final o in options) PopupMenuItem(value: o, child: Text(o)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: TpColors.primary),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: TpColors.primary),
          ],
        ),
      ),
    );
  }
}
