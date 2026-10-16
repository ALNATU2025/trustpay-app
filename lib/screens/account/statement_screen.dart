import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api.dart';
import '../../services/documents.dart';
import '../../services/trustpay_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/nav.dart';
import '../../widgets/common.dart';
import '../../widgets/flow_widgets.dart';
import '../../widgets/menu_widgets.dart';
import '../flows/generic_flow.dart';

/// Pick a period, then see the statement and share it as a PDF (or copy it as CSV for a spreadsheet).
class StatementScreen extends StatefulWidget {
  const StatementScreen({super.key});

  @override
  State<StatementScreen> createState() => _StatementScreenState();
}

class _StatementScreenState extends State<StatementScreen> {
  late DateTime _from;
  late DateTime _to;
  String _preset = '30';
  bool _busy = false;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _applyPreset('30');
  }

  void _applyPreset(String p) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _preset = p;
    switch (p) {
      case 'month':
        _from = DateTime(now.year, now.month, 1);
        _to = today;
      case 'last':
        _from = DateTime(now.year, now.month - 1, 1);
        _to = DateTime(now.year, now.month, 0);
      case '90':
        _from = today.subtract(const Duration(days: 89));
        _to = today;
      default:
        _from = today.subtract(const Duration(days: 29));
        _to = today;
    }
  }

  Future<void> _pick(bool start) async {
    final d = await showDatePicker(
      context: context,
      initialDate: start ? _from : _to,
      firstDate: DateTime.now().subtract(const Duration(days: 730)),
      lastDate: DateTime.now(),
    );
    if (d == null) return;
    setState(() {
      _preset = 'custom';
      if (start) {
        _from = d;
        if (_to.isBefore(d)) _to = d;
      } else {
        _to = d;
        if (_from.isAfter(d)) _from = d;
      }
    });
  }

  Future<void> _generate() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final d = await api.statement(from: _from, to: _to);
      if (mounted) setState(() => _data = d);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sharePdf() async {
    try {
      await shareStatement(_data!);
    } catch (_) {
      if (mounted) showMessage(context, 'Could not create the PDF.');
    }
  }

  Future<void> _copyCsv() async {
    try {
      final r = await api.statementCsv(from: _from, to: _to);
      if (mounted) await copyText(context, asStr(r['csv']), 'Statement copied. Paste it into a spreadsheet.');
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message);
    }
  }

  String _d(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Widget _chip(String label, String key) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(label: Text(label), selected: _preset == key, onSelected: (_) => setState(() => _applyPreset(key))),
      );

  @override
  Widget build(BuildContext context) {
    final s = _data;
    return PlainScaffold(
      title: 'Statements',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _chip('Last 30 days', '30'),
              _chip('This month', 'month'),
              _chip('Last month', 'last'),
              _chip('Last 90 days', '90'),
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => _pick(true), child: Text('From ${_d(_from)}'))),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton(onPressed: () => _pick(false), child: Text('To ${_d(_to)}'))),
          ]),
          const SizedBox(height: 14),
          PrimaryButton(label: 'Show statement', loading: _busy, onPressed: _busy ? () {} : _generate),
          if (_error != null) ...[const SizedBox(height: 12), ErrorBanner(_error!)],
          if (s != null) ...[
            const SizedBox(height: 18),
            WhiteCard(
              child: Column(
                children: [
                  _row('Opening balance', formatLeone(asDouble(s['openingBalance']))),
                  _row('Money in', formatLeone(asDouble(s['totalIn']))),
                  _row('Money out', formatLeone(asDouble(s['totalOut']))),
                  _row('Fees paid', formatLeone(asDouble(s['totalFees']))),
                  const Divider(),
                  _row('Closing balance', formatLeone(asDouble(s['closingBalance'])), bold: true),
                  _row('Transactions', '${asInt(s['count'])}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(label: 'Share statement (PDF)', onPressed: _sharePdf),
            const SizedBox(height: 8),
            SecondaryButton(label: 'Copy as spreadsheet (CSV)', onPressed: _copyCsv),
            const SizedBox(height: 14),
            for (final i in asMapList(s['items']).reversed.take(40))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(asStr(i['description']), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text('${asStr(i['date']).substring(0, 10)} · ${asStr(i['status'])}', style: const TextStyle(fontSize: 12, color: TpColors.muted)),
                      ]),
                    ),
                    Text(
                      asDouble(i['credit']) > 0 ? '+${formatLeone(asDouble(i['credit']))}' : (asDouble(i['debit']) > 0 ? '-${formatLeone(asDouble(i['debit']))}' : formatLeone(0)),
                      style: TextStyle(fontWeight: FontWeight.w700, color: asDouble(i['credit']) > 0 ? TpColors.green : TpColors.navy),
                    ),
                  ],
                ),
              ),
            if (asInt(s['count']) > 40) const Padding(padding: EdgeInsets.only(top: 6), child: Text('Showing the latest 40. The PDF has every entry.', style: TextStyle(color: TpColors.muted, fontSize: 12))),
          ],
        ],
      ),
    );
  }

  Widget _row(String a, String b, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(a, style: const TextStyle(color: TpColors.muted)),
          Text(b, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
        ]),
      );
}
