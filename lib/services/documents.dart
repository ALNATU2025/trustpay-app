import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/models.dart';
import '../utils/format.dart';

/// PDF receipts and statements, built on the phone and shared through the system share sheet.
/// The built-in PDF fonts only know Western characters, so anything else is simplified first.
String _clean(String s) => s
    .replaceAll('—', '-')
    .replaceAll('–', '-')
    .replaceAll('•', '*')
    .replaceAll('’', "'")
    .replaceAll('‘', "'")
    .replaceAll(RegExp(r'[^\x20-\x7E -ÿ]'), '');

const _navy = PdfColor.fromInt(0xFF14233F);
const _muted = PdfColor.fromInt(0xFF6B7690);
const _line = PdfColor.fromInt(0xFFE3E8F2);

pw.Widget _brand(String subtitle) => pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('TrustPay', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: _navy)),
        pw.Text(_clean(subtitle), style: const pw.TextStyle(fontSize: 10, color: _muted)),
      ],
    );

Future<Uint8List> buildReceiptPdf(ReceiptData d) async {
  final doc = pw.Document(title: 'TrustPay receipt');
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a5,
      margin: const pw.EdgeInsets.all(28),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _brand('Transaction receipt'),
          pw.SizedBox(height: 4),
          pw.Divider(color: _line),
          pw.SizedBox(height: 10),
          pw.Text(_clean(d.bannerLabel), style: const pw.TextStyle(fontSize: 12, color: _muted)),
          pw.SizedBox(height: 4),
          pw.Text(_clean(formatLeone(d.amount)), style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: _navy)),
          pw.SizedBox(height: 2),
          pw.Text(_clean(d.statusLine), style: const pw.TextStyle(fontSize: 11, color: _muted)),
          pw.SizedBox(height: 14),
          for (final r in d.rows)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 6),
              decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _line))),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(width: 110, child: pw.Text(_clean(r.$1), style: const pw.TextStyle(fontSize: 10, color: _muted))),
                  pw.Expanded(child: pw.Text(_clean(r.$2), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
                ],
              ),
            ),
          pw.Spacer(),
          pw.Text('Thank you for using TrustPay. Keep this receipt for your records.', style: const pw.TextStyle(fontSize: 9, color: _muted)),
        ],
      ),
    ),
  );
  return doc.save();
}

Future<void> shareReceipt(ReceiptData d) async {
  final ref = d.rows.where((r) => r.$1 == 'Reference').map((r) => r.$2).firstOrNull ?? 'receipt';
  await Printing.sharePdf(bytes: await buildReceiptPdf(d), filename: 'TrustPay-$ref.pdf');
}

String _day(String iso) => iso.length >= 10 ? iso.substring(0, 10) : iso;

Future<Uint8List> buildStatementPdf(Map<String, dynamic> s) async {
  final acct = asMap(s['account']);
  final period = asMap(s['period']);
  final items = asMapList(s['items']);
  String le(Object? v) => _clean(formatLeone(asDouble(v)));

  final doc = pw.Document(title: 'TrustPay statement');
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (_) => pw.Column(children: [
        _brand('Account statement'),
        pw.Divider(color: _line),
      ]),
      footer: (c) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Page ${c.pageNumber} of ${c.pagesCount}', style: const pw.TextStyle(fontSize: 9, color: _muted)),
      ),
      build: (_) => [
        pw.Text(_clean(asStr(acct['name'])), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.Text('Account ${asStr(acct['accountNumber'])}', style: const pw.TextStyle(fontSize: 10, color: _muted)),
        pw.Text('Period ${_day(asStr(period['from']))} to ${_day(asStr(period['to']))}', style: const pw.TextStyle(fontSize: 10, color: _muted)),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: _line), borderRadius: pw.BorderRadius.circular(6)),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              for (final e in [
                ('Opening balance', le(s['openingBalance'])),
                ('Money in', le(s['totalIn'])),
                ('Money out', le(s['totalOut'])),
                ('Fees paid', le(s['totalFees'])),
                ('Closing balance', le(s['closingBalance'])),
              ])
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(e.$1, style: const pw.TextStyle(fontSize: 8, color: _muted)),
                  pw.Text(e.$2, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ]),
            ],
          ),
        ),
        pw.SizedBox(height: 12),
        if (items.isEmpty)
          pw.Text('No transactions in this period.', style: const pw.TextStyle(fontSize: 11, color: _muted))
        else
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEEF2FB)),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
            },
            columnWidths: {
              0: const pw.FixedColumnWidth(54),
              1: const pw.FlexColumnWidth(2.4),
              2: const pw.FlexColumnWidth(1.7),
              3: const pw.FixedColumnWidth(58),
              4: const pw.FixedColumnWidth(58),
              5: const pw.FixedColumnWidth(66),
            },
            headers: ['Date', 'Description', 'Reference', 'Out', 'In', 'Balance'],
            data: [
              for (final i in items)
                [
                  _day(asStr(i['date'])),
                  _clean(asStr(i['description']) + (asStr(i['status']) == 'Successful' ? '' : ' (${asStr(i['status'])})')),
                  asStr(i['reference']),
                  asDouble(i['debit']) > 0 ? le(i['debit']) : '',
                  asDouble(i['credit']) > 0 ? le(i['credit']) : '',
                  le(i['balance']),
                ],
            ],
          ),
        if (asBool(s['truncated'])) pw.Padding(padding: const pw.EdgeInsets.only(top: 8), child: pw.Text('Only the first 3,000 entries are shown. Choose a shorter period for the rest.', style: const pw.TextStyle(fontSize: 9, color: _muted))),
      ],
    ),
  );
  return doc.save();
}

Future<void> shareStatement(Map<String, dynamic> s) async {
  final period = asMap(s['period']);
  await Printing.sharePdf(
    bytes: await buildStatementPdf(s),
    filename: 'TrustPay-statement-${_day(asStr(period['from']))}_to_${_day(asStr(period['to']))}.pdf',
  );
}
