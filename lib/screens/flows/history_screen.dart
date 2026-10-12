import 'package:flutter/material.dart';

import '../../data/sample_data.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/nav.dart';
import '../../widgets/common.dart';
import '../../widgets/flow_widgets.dart';
import '../../widgets/step_scaffold.dart';
import 'receipt_screen.dart';

/// Transaction history with search, tabs and filters.
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  static const _services = ['All services', 'Transfers', 'Bills', 'Airtime', 'Account funding'];
  static const _statuses = ['Successful', 'Pending', 'Failed'];

  int _tab = 0;
  String _query = '';
  String _month = '${kMonthsFull[9]} 2026';
  String _service = _services.first;
  String _status = _statuses.first;

  List<String> get _months => ['${kMonthsFull[9]} 2026', '${kMonthsFull[8]} 2026'];

  TxnKind? get _kind => switch (_service) {
        'Transfers' => TxnKind.transfer,
        'Bills' => TxnKind.bill,
        'Airtime' => TxnKind.airtime,
        'Account funding' => TxnKind.funding,
        _ => null,
      };

  List<Txn> get _filtered {
    final q = _query.trim().toLowerCase();
    return kSampleTransactions.where((t) {
      if (_tab == 1 && !t.isCredit) return false;
      if (_tab == 2 && t.isCredit) return false;
      if (_kind != null && t.kind != _kind) return false;
      if (t.status != _status) return false;
      final month = '${kMonthsFull[t.date.month - 1]} ${t.date.year}';
      if (month != _month) return false;
      if (q.isEmpty) return true;
      return t.title.toLowerCase().contains(q) ||
          t.meta.toLowerCase().contains(q) ||
          formatNaira(t.amount.abs()).toLowerCase().contains(q);
    }).toList();
  }

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

  IconData _icon(Txn t) {
    switch (t.kind) {
      case TxnKind.bill:
        return Icons.flash_on_outlined;
      case TxnKind.airtime:
        return Icons.smartphone_outlined;
      case TxnKind.funding:
        return Icons.south_west;
      case TxnKind.transfer:
        return t.isCredit ? Icons.south_west : Icons.north_east;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final rows = <Widget>[];
    String? lastLabel;
    for (var i = 0; i < items.length; i++) {
      final t = items[i];
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
          subtitle: t.meta,
          trailing: formatNaira(t.amount, showSign: true),
          trailingColor: t.isCredit ? TpColors.green : TpColors.navy,
          onTap: t.receipt == null
              ? null
              : () => openScreen(context, ReceiptScreen(data: t.receipt!)),
        ),
      );
    }

    return StepScaffold(
      eyebrow: 'TRANSACTIONS · FROM HOME / SEE ALL',
      title: 'Transaction history',
      subtitle: 'Your personal account · Ada Okafor',
      headerLabel: 'Done',
      onHeaderAction: () => goHome(context),
      primaryLabel: 'Download statement',
      // TODO: generate the account statement.
      onPrimary: () => showMessage(context, 'Statements are not connected yet.'),
      secondaryLabel: 'Back to home',
      onSecondary: () => goHome(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Search transactions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            onChanged: (v) => setState(() => _query = v),
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
                  options: _months,
                  onSelected: (v) => setState(() => _month = v),
                ),
                const SizedBox(width: 10),
                _FilterPill(
                  label: _service,
                  options: _services,
                  onSelected: (v) => setState(() => _service = v),
                ),
                const SizedBox(width: 10),
                _FilterPill(
                  label: _status,
                  options: _statuses,
                  onSelected: (v) => setState(() => _status = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          WhiteCard(
            child: items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No transactions match these filters.',
                        style: TextStyle(color: TpColors.muted),
                      ),
                    ),
                  )
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows),
          ),
          Center(
            child: TextButton(
              // TODO: load the next page of transactions from your API.
              onPressed: () => showMessage(context, 'No older transactions in this sample data.'),
              child: const Text('Load older transactions', style: TextStyle(fontSize: 15)),
            ),
          ),
        ],
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
